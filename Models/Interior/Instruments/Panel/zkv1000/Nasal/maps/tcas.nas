# vim: set foldmethod=marker foldmarker={{{,}}} :

var TcasItemClass = {
# get data from AI and multiplayers {{{
    new : func(canvasGroup, index) {
        var m = {parents : [TcasItemClass]};
        m._group = canvasGroup.createChild("group", "TcasItem_" ~ index);

        canvas.parsesvg(m._group, data.zkv1000_reldir ~ "Models/tcas.svg");
        m._can = {
            Alt : m._group.getElementById("Alt_above").setVisible(0),
            Arrow : [
                m._group.getElementById("Arrow_climb").setVisible(0),
                m._group.getElementById("Arrow_descent").setVisible(0)
            ],
            Callsign: m._group.getElementById("Callsign").setVisible(0),
            ThreadLevel: [],
        };

        for (var i=0; i<4; i+=1)
            append(m._can.ThreadLevel,
                    m._group.getElementById("Thread_Level_" ~ i).setVisible(0));

        m._colors = [ '#00ffff', '#00ffff', '#ff7f2a', '#ff0000' ];

        return m;
    },

    setData : func(lat, lon, alt, vs, level, callsign) {
        me._group.setVisible(1);
        me._group.setGeoPosition(lat, lon);
        
        if (alt and level)
            me._can.Alt
                .setText(sprintf("%+i", alt))
                .set('fill', me._colors[level])
                .setVisible(1);
        else
            me._can.Alt.setVisible(0);
                
        if (abs(vs) > 50 and level > 1) {
            me._can.Arrow[vs < 0]
                .set('fill', me._colors[level])
                .set('stroke', me._colors[level])
                .setVisible(1);

            me._can.Arrow[vs > 0].setVisible(0);
        }
        else {
            me._can.Arrow[0].setVisible(0);
            me._can.Arrow[1].setVisible(0);
        }

        for (var i = 0; i < 4; i += 1)
            me._can.ThreadLevel[i].setVisible(level == i);

        me._can.Callsign
            .setText(callsign)
            .set('fill', me._colors[level])
            .setVisible(1);
    },
};
# }}} 

var MapTcas = {
# init TCAS layer and update {{{
    new : func(device, group) {
        var m = {parents:[MapTcas]}; 
        m.device = device;
        m.visibility = 0;
        m.group = group.createChild('map', 'tcas')
            .setTranslation(
                m.device.role == 'MFD' ? (m.device.data.mapview[0] + m.device.data.mapclip.left)/2 : 120,
                m.device.role == 'MFD' ? 400 : 600)
            .setVisible(m.visibility);
        m._item      = [];
        m._itemIndex = 0;
        m._itemCount = 0;
        return m;
    },

    off: func {
        me.setVisible(0);
    },

    update : func() {
        if (me.group.getVisible() == 0)
            return;
        me.group._node.getNode('ref-lat', 1).setDoubleValue(data.lat);
        me.group._node.getNode('ref-lon', 1).setDoubleValue(data.lon);
        me.group.setRange(me.device.data['range-nm']/2);
        me._itemIndex = 0;
        foreach (var ac; data.tcas) {
            if (me._itemIndex >= me._itemCount) {
                append(me._item, TcasItemClass.new(me.group, me._itemIndex));
                me._itemCount += 1;
            }
            me._item[me._itemIndex].setData(ac.lat, ac.lon, ac.alt, ac.vs, ac.level, ac.callsign);
            me._itemIndex += 1;
        }
                
        for (; me._itemIndex < me._itemCount; me._itemIndex += 1) {
            me._item[me._itemIndex]._group.setVisible(0);
        }
    },

    setVisible : func (v) {
        me.group.setVisible(v);
    },
};
# }}} 
