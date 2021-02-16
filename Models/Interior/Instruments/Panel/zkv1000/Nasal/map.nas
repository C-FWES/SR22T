var mapClass = {
    new : func (device) {
        var m = { parents : [ mapClass ] };
        m.device = device;

        m.device.data.mapview = [
            m.device.display.display.get('view[0]'),
            m.device.display.display.get('view[1]')
        ];
        m.device.data.mapsize = [
            m.device.display.display.get('size[0]'),
            m.device.display.display.get('size[1]')
        ];
        m.device.data.zoom = 10;
        m.device.data.orientation = {
            text: 'NORTH UP',
            map: 0,
            airplane: data.hdg,
            fontsize: m.device.role == 'MFD' ? 16 : 12,
        };
        m.changeZoom();

        m.visibility = m.device.role == 'MFD';
        
        m.group = m.device.display.display.createGroup()
            .set('clip',
                    'rect('
                        ~ m.device.data.mapclip.top ~','
                        ~ m.device.data.mapclip.right ~','
                        ~ m.device.data.mapclip.bottom ~','
                        ~ m.device.data.mapclip.left ~')')
            .setCenter(
                (m.device.data.mapclip.right + m.device.data.mapclip.left) / 2,
                (m.device.data.mapclip.bottom + m.device.data.mapclip.top) / 2);

        m.layers = {};
        m.layers.tiles = MapTiles.new(m.device, m.group);
        if (m.device.role == 'MFD')
            m.layers.topo = MapTopo.new(m.device, m.group);
        m.layers.route = MapRoute.new(m.device, m.group);
        m.layers.navaids = MapNavaids.new(m.device, m.group);
        if (m.device.role == 'MFD')
            m.layers.tcas = MapTcas.new(m.device, m.group);

        m.mapOrientation = m.device.display.display.createGroup('MapOrientation')
            .setVisible(m.visibility);
        m.mapOrientation.createChild('path', 'MapOrientation-bg')
            .rect(
                m.device.data.mapclip.right - size(m.device.data.orientation) * (m.device.data.orientation.fontsize + 2),
                m.device.data.mapclip.top + 2,
                size(m.device.data.orientation) * (m.device.data.orientation.fontsize + 2),
                m.device.data.orientation.fontsize + 2)
            .setColor(1,1,1)
            .setColorFill(0,0,0);
        m.mapOrientation_text = m.mapOrientation.createChild('text', 'MapOrientation-text')
            .setFontSize(m.device.data.orientation.fontsize)
            .setFont('LiberationFonts/LiberationMono-Regular.ttf')
            .setTranslation(
                m.device.data.mapclip.right - size(m.device.data.orientation) * (m.device.data.orientation.fontsize + 2),
                m.device.data.mapclip.top + m.device.data.orientation.fontsize + 2)
            .setColor(1,1,1)
            .setColorFill(1,1,1)
            .setText(m.device.data.orientation.text);

        data.lat = getprop('/position/latitude-deg');
        m.changeZoom();

#        m.device.display.display.createGroup().createChild('path')
#            .setColor(1,0,0)
#            .setColorFill(1,0,0)
#            .setStrokeLineWidth(2)
#            .moveTo(
#                m.device.data.mapclip.left + (m.device.data.mapclip.right-m.device.data.mapclip.left)/2,
#                m.device.data.mapclip.top +50)
#            .vertTo(
#                m.device.data.mapclip.bottom -50)
#            .close()
#            .moveTo(
#                m.device.data.mapclip.left +50,
#                m.device.data.mapclip.top + (m.device.data.mapclip.bottom-m.device.data.mapclip.top)/2)
#            .horizTo(
#                m.device.data.mapclip.right-50)
#            .close();

        return m;
    },
    off: func {
        me.mapOrientation.setVisible(0);
        foreach (var layer; keys(me.layers)) {
            me.layers[layer].off();
            delete(me.layers, layer);
        }
    },
    changeZoom : func (d = 0) {
        me.device.data.zoom = math.max(2, math.min(19, me.device.data.zoom + d));
        me.device.data['range-nm'] = me.device.display.display.get('view[1]') / 2 * 84.53 * math.cos(data.lat * D2R) / math.pow(2, me.device.data.zoom);
    },
    update : func {
        if (me.device.data.orientation.text == 'NORTH UP') {
            me.device.data.orientation.map = 0;
            me.device.data.orientation.airplane = data.hdg;
        }
        elsif (me.device.data.orientation.text == 'TRK UP') {
            if (data.wow) {
                me.device.data.orientation.map = -data.hdg;
                me.device.data.orientation.airplane = data.hdg;
            }
            else {
                var track = getprop('/orientation/track-deg');
                me.device.data.orientation.map = -track;
                me.device.data.orientation.airplane = data.hdg;
            }
        }
        elsif (me.device.data.orientation.text == 'DTK UP') {
            var desired = getprop('/instrumentation/gps/wp/wp[1]/desired-course-deg');
            me.device.data.orientation.map = -desired;
            me.device.data.orientation.airplane = data.hdg;
        }
        elsif (me.device.data.orientation.text == 'HDG UP') {
            me.device.data.orientation.map = -data.hdg;
            me.device.data.orientation.airplane = data.hdg;
        }

        me.group.setRotation(me.device.data.orientation.map * D2R);

        me.mapOrientation_text
            .setText(me.device.data.orientation.text);

        foreach (var l; keys(me.layers))
            me.layers[l].update();
    },
    setVisible : func (v) {
        me.visibility = v;
        foreach (var l; keys(me.layers))
            me.layers[l].setVisible(v);
        me.mapOrientation.setVisible(v);
    },
};
