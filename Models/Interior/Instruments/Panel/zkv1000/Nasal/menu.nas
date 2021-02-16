var pageClass = {
    new : func (d) {
        var m = { parents : [pageClass] };
        m.page = d.display.display.createGroup().set('z-index', 100);
        m.window = {};
        m.state = {};
        m.selected = '';
        return m;
    },

    off: func {
        me.del();
        me.page.removeAllChildren();
    },

    del : func (id = nil) {
        if (id != nil and typeof(id) == 'scalar') {
            delete(me.state, id);
            var _id = id ~ '-';
            id = [];
            foreach (var w; keys(me.window))
                if (find(_id, w) == 0)
                    append(id, w);
        }
        else {
            foreach (var s; keys(me.state))
                delete(me.state, s);
            id = keys(me.window);
        }
        foreach (var w; id) {
            me.window[w]
                .hide()
                .del();
            delete(me.window, w);
        }
        me.selected = '';
    },

    _selected_text : func (id, text, x, y) {
        me.selected = id;
        me.window[id]
            .setFontSize(16)
            .setFont('LiberationFonts/LiberationMono-Regular.ttf')
            .setTranslation(x, y)
            .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
            .setText(text)
            .setColorFill(0,1,1)
            .setColor(0,0,0);
    },

    _editable_text : func (id, text, x, y) {
        me.window[id]
            .setFontSize(16)
            .setFont('LiberationFonts/LiberationMono-Regular.ttf')
            .setTranslation(x, y)
            .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
            .setText(text)
            .setColorFill(0,0,0)
            .setColor(0,1,1);
    },

    _normal_text : func (id, text, x, y) {
        me.window[id]
            .setFontSize(16)
            .setFont('LiberationFonts/LiberationMono-Regular.ttf')
            .setTranslation(x, y)
            .setText(text)
            .setColorFill(0,0,0)
            .setColor(1,1,1);
    },

    _title_text : func (id, text, x, y) {
        me.window[id]
            .setFontSize(16)
            .setFont('LiberationFonts/LiberationMono-Regular.ttf')
            .setTranslation(x, y)
            .setAlignment('center-center')
            .setText(text)
            .setColorFill(0,0,0)
            .setColor(0,1,1);
    },

    fill : func (id, scroll = nil) {
        var state = me.state[id];
        state.scroll = {
            offset : 0,           # offset between canvas element and state element
            last : 9999,          # last scrollgroup
            begin: -9999,         # first canvas element of the scrolling area
            end: 9999,            # last canvas element of the scrolling area
            upper: -9999,         # group printed on the top of the scrolling area
            lower: 9999,          # group printed at the bottom of the scrolling area
            lines : scroll != nil ? scroll.lines : 0, # number of lines for the scrolling area
            columns : scroll != nil ? scroll.columns : 0, # number of objects on each scrolling lines
            rows : scroll != nil and contains(scroll, 'rows') ? scroll.rows : 1,
        };
        var scrollgroup = {};
        forindex (var line; state.objects) {
            if (find('separator', state.objects[line].type) > -1) {
                me.window[id ~ '-' ~ (line - state.scroll.offset)] = me.page.createChild('path')
                    .setStrokeLineWidth(1)
                    .moveTo(state.x_base, state.geometry.y - 12)
                    .horiz(state.geometry.w - 20)
                    .setColor(1,1,1);
                state.geometry.x = state.x_base;
                state.geometry.y += 8;
            }
            else {
                if (contains(state.objects[line], 'scrollgroup')) {
                    state.scroll.last = state.objects[line].scrollgroup;
                    scrollgroup[state.objects[line].scrollgroup] = 1;
                    if (state.scroll.begin == -9999) {
                        state.scroll.begin = line;
                        state.scroll.upper = state.objects[line].scrollgroup;
                    }
                    if (size(keys(scrollgroup)) > state.scroll.lines) {
                        if (state.scroll.end == 9999) {
                            state.scroll.end = line - 1;
                            state.scroll.lower = state.objects[line - 1].scrollgroup;
                        }
                        else
                            state.scroll.last = state.objects[line].scrollgroup;
                        state.scroll.offset += 1;
                        continue;
                    }
                }
                me.window[id ~ '-' ~ (line - state.scroll.offset)] = me.page.createChild('text');
                if (find('selected', state.objects[line].type) > -1)
                    me._selected_text(
                            id ~ '-' ~ (line - state.scroll.offset),
                            state.objects[line].text,
                            state.geometry.x,
                            state.geometry.y,
                            );

                elsif (find('editable', state.objects[line].type) > -1
                   or  find('highlighted', state.objects[line].type) > -1)
                    me._editable_text(
                            id ~ '-' ~ (line - state.scroll.offset),
                            state.objects[line].text,
                            state.geometry.x,
                            state.geometry.y,
                            );

                elsif (find('title', state.objects[line].type) > -1)
                    me._title_text(
                            id ~ '-' ~ (line - state.scroll.offset),
                            state.objects[line].text,
                            state.x_base - 10 + state.geometry.w / 2,
                            state.geometry.y
                        );

                else
                    me._normal_text(
                            id ~ '-' ~ (line - state.scroll.offset),
                            state.objects[line].text,
                            state.geometry.x,
                            state.geometry.y,
                            );


                if (find('end-of-line', state.objects[line].type) > -1
                or  find('title', state.objects[line].type) > -1) {
                    state.geometry.x = state.x_base;
                    state.geometry.y += 24;
                }
                else
                    state.geometry.x += size(state.objects[line].text) * 10 + 8;
            }
        }
        # reset the scrolling offset before the first move
        state.scroll.offset = 0;
    },
    
    draw : func (id, geometry, objects = nil, scroll = nil) {
        if (typeof(geometry) == 'vector') {
            if (typeof(objects) == 'hash')
                scroll = objects;
            objects  = geometry;
            geometry = {autogeom: 1};
        }

        if (contains(me.window, id ~ '-bg')) {
            logprint(LOG_DEBUG, 'objet ' ~ id ~ ' already exists');
            return;
        }
        if (!contains(geometry, 'sep'))
            geometry.sep = 0;
        if (contains(geometry, 'autogeom') and geometry.autogeom) {
            # 1024x768 display
            # - let 10 from the border
            # - plus other 10 from the window border and the text
            # - font size tends to be 10x24
            # - let 8+8 around the separator
            var textWidth = 0;
            var lines = 0;
            var _textWidth = 0;
            forindex (var o; objects) {
                if (find('end-of-line', objects[o].type) > -1) {
                    if (scroll != nil and contains(scroll, 'lines')) {
                        if (contains(objects[o], 'scrollgroup')) {
                            if (objects[o].scrollgroup < scroll.lines)
                                lines += 1;
                            _textWidth += size(objects[o].text);
                            if (_textWidth > textWidth) textWidth = _textWidth;
                            _textWidth = 0;
                        }
                        else {
                            lines += 1;
                            _textWidth += size(objects[o].text);
                            if (_textWidth > textWidth) textWidth = _textWidth;
                            _textWidth = 0;
                        }
                    }
                    else {
                        lines += 1;
                        _textWidth += size(objects[o].text);
                        if (_textWidth > textWidth) textWidth = _textWidth;
                        _textWidth = 0;
                    }
                }
                elsif (objects[o].type == 'title') {
                    lines += 1;
                    _textWidth = size(objects[o].text);
                    if (_textWidth > textWidth) textWidth = _textWidth;
                    _textWidth = 0;
                }
                elsif (objects[o].type != 'separator') {
                    _textWidth += size(objects[o].text);
                }

                if (contains(objects[o], 'type') and objects[o].type == 'separator')
                    geometry.sep += 1;
            }
            textWidth += 1;
            textWidth *= 10;
            if (!contains(geometry, 'l')) geometry.l = lines;
            if (!contains(geometry, 'x')) geometry.x = 1014 - textWidth;
            if (!contains(geometry, 'y')) geometry.y = 758 - (lines * 24) - 72; # 72 = offset from bottom to let softkeys display and margin
            if (!contains(geometry, 'w')) geometry.w = textWidth;
        }
        if (!contains(geometry, 'h') and !contains(geometry, 'l')) {
            logprint(LOG_DEBUG, 'missing parameter l or h');
            return;
        }

        var save_x = geometry.x;
        var save_y = geometry.y;
        if (!geometry.sep)
            geometry.sep = 1;
        me.state[id] = {
            objects: objects,
            geometry: geometry,
            x_base : geometry.x + 10,
            h_max : contains(geometry, 'h') ? h : geometry.l * 24 + 8 + geometry.sep * 16,
        };

        logprint(LOG_DEBUG, sprintf('geom id: %s, x: %d, y: %d, w: %d, h: %d, l: %d, sep: %d',
                 id, geometry.x, geometry.y, geometry.w, me.state[id].h_max, geometry.l, geometry.sep));
        me.state[id].y_max = me.state[id].h_max + me.state[id].geometry.y;
        me.window[id ~ '-bg'] = me.page.createChild('path');
        me.window[id ~ '-bg']
            .rect(geometry.x, geometry.y,
                  geometry.w, me.state[id].h_max)
            .setColor(1,1,1)
            .setColorFill(0,0,0);
        me.state[id].geometry.x += 10;
        me.state[id].geometry.y += 16;
        me.fill(id, scroll);
        geometry.x = save_x;
        geometry.y = save_y;
    },
};
