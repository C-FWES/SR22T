var knobsClass = {
    new : func (device) {
        var m = { parents: [ knobsClass ] };
        m.device = device;
        return m;
    },

    XPDRCodeSetDigits : func (d) {
        # disable SoftKey entering method
        radios.setValue('xpdr-tuning-fms-method', 1);
        if (!contains(me.device.softkeys.bindings.PFD.XPDR.CODE, 'on_change_inactivity')) {
            me.device.softkeys.bindings.PFD.XPDR.CODE.inactivity.stop();
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity = maketimer(10,
                func {
                    radios.setValue('xpdr-tuning-digit', 3);
                    call(me.device.softkeys.bindings.PFD.XPDR.CODE.restore, [], me);
                });
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.singleShot = 1;
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.start();
        }
        else
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.restart(10);
        var digit = radios.getValue('xpdr-tuning-digit');
        var code = getprop('/instrumentation/transponder/id-code');
        if (digit == 3)
            var val = int(code/100) + d;
        else
            var val = math.mod(code, 100) + d;
        if (math.mod(val, 10) == 8) {
            if (val > 77)
                val = 0;
            else
                val += 2;
        }
        elsif (val < 0)
            val = 77;
        elsif (math.mod(val, 10) == 9)
            val -= 2;
        if (digit == 3)
            setprop('/instrumentation/transponder/id-code',
                    sprintf('%i', val * 100 + math.mod(code, 100)));
        else
            setprop('/instrumentation/transponder/id-code',
                    sprintf('%i', int(code/100) * 100 + val));
        me.device.display.updateXPDR();
    },

    XPDRCodeNextDigits : func {
        radios.setValue('xpdr-tuning-fms-method', 1);
        if (!contains(me.device.softkeys.bindings.PFD.XPDR.CODE, 'on_change_inactivity')) {
            me.device.softkeys.bindings.PFD.XPDR.CODE.inactivity.stop();
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity = maketimer(10,
                func {
                    radios.setValue('xpdr-tuning-digit', 3);
                    call(me.device.softkeys.bindings.PFD.XPDR.CODE.restore, [], me);
                });
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.singleShot = 1;
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.start();
        }
        else
            me.device.softkeys.bindings.PFD.XPDR.CODE.on_change_inactivity.restart(10);
        radios.setValue('xpdr-tuning-digit', 1);
        me.device.display.updateXPDR();
    },

    MenuSettings : func (d) {
        var (id, selected) = split('-', me.device.windows.selected);
        var state = me.device.windows.state[id];
        var object = state.objects[selected + state.scroll.offset];
        var val = object.text;
        if (contains(object, 'choices')) {
            if ((d > 0 and val[size(val)-1] != `>`)
             or (d < 0 and val[0]           != `<`))
                return;
            forindex (var c; object.choices)
                if (object.choices[c] == val) {
                    val = object.choices[c + d];
                    me.device.windows.window[me.device.windows.selected]
                        .setText(val);
                    object.text = val;
                    break;
                }
        }
        elsif (contains(object, 'format')) {
            var v = substr(val, find('%', object.format));
            for (var c = 0; c < size(v); c +=1 )
                if ((v[c] < `0` or v[c] > `9`)
                        and v[c] != `.` and v[c] != ` `
                        and v[c] != `-` and v[c] != `+`) {
                    v = string.trim(substr(v, 0, c));
                    break;
                }
            v += d * (contains(object, 'factor') ? object.factor : 1);
            if (contains(object, 'range'))
                if ((contains(object.range, 'max') and v > object.range.max)
                or  (contains(object.range, 'min') and v < object.range.min))
                    return;
            val = sprintf(object.format, v);
            me.device.windows.window[me.device.windows.selected]
                .setText(val);
            object.text = val;
        }
        elsif (find('time', object.type) > -1) {
            var (hh, mm, ss) = split(':', val);
            var time = hh * 3600 + mm * 60 + ss;
            if (time >= 600) # 10 min
                d *= 60;
            elsif (time >= 300) # 5 minutes
                d *= 30;
            elsif (time >= 180) # 3 minutes
                d *= 10;

            val = HMS(hh, mm, ss, d);

            me.device.windows.window[me.device.windows.selected]
                .setText(val);
            object.text = val;
        }
        if (find('immediate', object.type) > -1) {
            if (contains(object, 'callback'))
                call(object.callback, [id, selected + state.scroll.offset], me);
            else
                me.device.buttons.ENT();
        }
    },

    NavigateMenu : func (d) {
        # d: direction for searching the next selection (-1 or +1)
        # i : index of the object (not the canvas object)
        # state.scroll.offset : offset between canvas object pointed by i
        #                       and object in state hash,
        # selected : the canvas object id selected
        # id: the id of the window
        var (id, selected) = split('-', me.device.windows.selected);
        var state = me.device.windows.state[id];
        d *= state.scroll.rows;
        selected += state.scroll.offset;
        # foreach object, beginning at the selected object, offset applied
        for (var i = selected + d; i >= 0 and i < size(state.objects); i += d) {
            if (i > state.scroll.end
                    and d > 0
                    and state.scroll.lower < state.scroll.last) {
                me._navigatemenu_scrolldown(state, id, i);
            }
            elsif (i - state.scroll.offset < state.scroll.begin
                    and d < 0
                    and state.scroll.upper > 0) {
                me._navigatemenu_scrollup(state, id, i);
            }
            if (find('editable', state.objects[i].type) > -1) {
                state.objects[selected].type = string.replace(state.objects[selected].type,
                        'selected', 'editable');
                me.device.windows.window[me.device.windows.selected]
                    .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                    .setColorFill(0,0,0)
                    .setColor(0,1,1);
                state.objects[i].type = string.replace(state.objects[i].type,
                        'editable', 'selected');
                me.device.windows.window[id ~ '-' ~ (i - state.scroll.offset)]
                    .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                    .setColorFill(0,1,1)
                    .setColor(0,0,0);
                me.device.windows.selected = id ~ '-' ~ (i - state.scroll.offset);
                break;
            }
        }
    },

    _navigatemenu_scrolldown : func (state, id, i) {
        state.scroll.upper = state.objects[i].scrollgroup - state.scroll.lines + state.scroll.rows;
        state.scroll.lower = state.objects[i].scrollgroup;
        state.scroll.offset = state.scroll.upper * state.scroll.columns;
        if (state.scroll.rows > 1 and i - state.scroll.offset > state.scroll.lines * state.scroll.columns * state.scroll.rows)
            state.scroll.offset = i - state.scroll.lines * state.scroll.columns * state.scroll.rows;

        # foreach canvas object in the scrolling area
        for (var l = state.scroll.begin; l <= state.scroll.end; l += 1) {
            var t = state.objects[l + state.scroll.offset].text;
            me.device.windows.window[id ~ '-' ~ l]
                .setText(t);
        }
    },

    _navigatemenu_scrollup : func (state, id, i) {
        state.scroll.upper = state.objects[i].scrollgroup;
        state.scroll.lower = state.objects[i].scrollgroup + state.scroll.lines - state.scroll.rows;
        state.scroll.offset = state.scroll.upper * state.scroll.columns * state.scroll.rows;
        if (state.scroll.rows > 1 and i == state.scroll.offset) {
            state.scroll.offset -= state.scroll.columns * state.scroll.rows;
            if (state.scroll.offset < state.scroll.begin) {
                state.scroll.offset = state.scroll.begin;
                return;
            }
        }

        # foreach canvas object in the scrolling area
        for (var l = state.scroll.begin; l <= state.scroll.end; l += 1) {
            var t = state.objects[l + state.scroll.offset].text;
            me.device.windows.window[id ~ '-' ~ l]
                .setText(t);
        }
    },

    MFD_select_page_group : func (d) {
        if (contains(me.device.windows.state, 'page selection')) {
            if (me.device.display['page selected'] + d < size(me.device.data['page selection'])
            and me.device.display['page selected'] + d >= 0) {
                me.device.windows.del('page selection');
                me.device.display['page selected'] += d;
            }
            else
                return;
        }
        me.device.windows.draw('page selection',
                me.device.data['page selection'][me.device.display['page selected']].geometry,
                me.device.data['page selection'][me.device.display['page selected']].objects,
            );
        me.FmsInner = me.NavigateMenu;
        me.device.buttons.ENT = me.device.buttons.ValidateTMRREF;
        me.device.buttons.CLR = func {
            me.device.display['page selected'] = 0;
            me.device.windows.del('page selection');
            me.device.buttons.CLR = func;
            me.device.buttons.ENT = func;
        };
    },

    FmsInner : void,
    FmsOuter : void,
    FmsInner_slowdown: 0,
    FmsOuter_slowdown: 0,
};
