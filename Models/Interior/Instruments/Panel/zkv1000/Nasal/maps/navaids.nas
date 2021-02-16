# vim: set foldmethod=marker foldmarker={{{,}}} :
# The following is largely inspired from the Extra500 Avidyne Entegra 9 
# https://gitlab.com/extra500/extra500.git
# Many thanks to authors: Dirk Dittmann and Eric van den Berg
var MapIconCache = {
# creates at init an icons cache for navaids, airports and airplane {{{
    new : func (svgFile) {
        var m = { parents:[MapIconCache] };

        m._canvas = canvas.new( {
            'name': 'MapIconCache',
            'size': [512, 512],
            'view': [512, 512],
            'mipmapping': 1
        });
        m._canvas.addPlacement( {'type': 'ref'} );
        m._canvas.setColorBackground(1,1,1,0);
        m._group = m._canvas.createGroup('MapIcons');

        canvas.parsesvg(m._group, data.zkv1000_reldir ~ svgFile);

        m._sourceRectMap = {};

        var icons = [ 'airplane' ];

        foreach (var near; [0, 1])
            foreach (var surface; [0, 1])
                foreach (var tower; [0, 1])
                    foreach (var center; tower ? [0, 1] : [ 0 ])
                        append(icons, 'Airport_' ~ near ~ surface ~ tower ~ center);

        foreach (var type; ['VOR', 'DME', 'TACAN', 'NDB'])
            append(icons, 'Navaid_' ~ type);

        foreach (var i; icons)
            m.registerIcon(i);

        return m;
    },
    registerIcon : func (id) {
        me._sourceRectMap[id] = {
            'bound' : [],
            'size'  : [],
        };
        var element = me._group.getElementById(id);
        if (element != nil) {
            me._sourceRectMap[id].bound = element.getTransformedBounds();
            # TODO ugly hack ? check for reason!
            var top     = 512 - me._sourceRectMap[id].bound[3];
            var bottom  = 512 - me._sourceRectMap[id].bound[1];
            me._sourceRectMap[id].bound[1] = top;
            me._sourceRectMap[id].bound[3] = bottom;

            me._sourceRectMap[id].size = [
                me._sourceRectMap[id].bound[2] - me._sourceRectMap[id].bound[0],
                me._sourceRectMap[id].bound[3] - me._sourceRectMap[id].bound[1]
            ];
        }
        else {
            print('MapIconCache.registerIcon(' ~ id ~ ') fail');
        }
    },
    getBounds : func (id) {
        return me._sourceRectMap[id].bound;
    },
    getSize : func (id) {
        return me._sourceRectMap[id].size;
    },
    boundIconToImage : func (id, image, center=1) {
        if (!contains(me._sourceRectMap, id)) {
            print('MapIconCache.boundIconToImage('~id~') ... no available.');
            id = 'Airport_0001';
        }
        image.setSourceRect(
                me._sourceRectMap[id].bound[0],
                me._sourceRectMap[id].bound[1],
                me._sourceRectMap[id].bound[2],
                me._sourceRectMap[id].bound[3],
                0);
        image.setSize(
                me._sourceRectMap[id].size[0],
                me._sourceRectMap[id].size[1]);
        if (center) {
            image.setTranslation(
                    -me._sourceRectMap[id].size[0]/2,
                    -me._sourceRectMap[id].size[1]/2);
        }
    },
};

var mapIconCache = MapIconCache.new('Models/MapIcons.svg');
# }}}

var MapAirportItem = {
# manage airports items by adding the ID and runways on associated icon {{{
    new : func (id) {
        var m = {parents:[MapAirportItem]};
        m._id = id;
        m._can = {
            'group' : nil,
            'label' : nil,
            'image' : nil,
            'layout': nil,
            'runway': [],
        };
        m._mapAirportIcon = {
            'near'      : 0,
            'surface'   : 0,
            'tower'     : 0,
            'center'    : 0,
            'displayed' : 0,
            'icon'      : '',
        };
        return m;
    },
    create : func (group) {
        me._can.group = group
            .createChild('group', 'airport_' ~ me._id);

        me._can.image = me._can.group.createChild('image', 'airport-image_' ~ me._id)
            .setFile(mapIconCache._canvas.getPath())
            .setSourceRect(0,0,0,0,0);

        me._can.label = me._can.group.createChild('text', 'airport-label_' ~ me._id)
            .setDrawMode( canvas.Text.TEXT )
            .setTranslation(0, 37)
            .setAlignment('center-bottom-baseline')
            .setFont('LiberationFonts/LiberationSans-Regular.ttf')
            .setFontSize(24);

        me._can.label.set('fill','#BACBFB');
        me._can.label.set('stroke','#000000');

        me._can.layout = group.createChild('group','airport_layout' ~ me._id);
        me._can.layoutIcon = group.createChild('group','airport_layout_Icon' ~ me._id);
        return me._can.group;
    },
    draw : func (apt, mapOptions) {
        me._mapAirportIcon.near = mapOptions.range > 32 ? 0 : 1;
        me._mapAirportIcon.surface  = 0;
        me._mapAirportIcon.tower    = 0;
        me._mapAirportIcon.center   = 0;
        me._mapAirportIcon.displayed    = 0;

        # TODO make departure and destination airports specific
        var aptInfo = airportinfo(apt.id);

        me._can.layout.removeAllChildren();
        me._can.layoutIcon.removeAllChildren();

        me._mapAirportIcon.tower = (size(aptInfo.comms('tower')) > 0);
        me._mapAirportIcon.center = me._mapAirportIcon.tower and (size(aptInfo.comms('approach')) > 0);

        foreach (var rwy; keys(aptInfo.runways)) {
            var runway = aptInfo.runways[rwy];
            me._mapAirportIcon.surface = MAP_RUNWAY_SURFACE[runway.surface] ? 1 : me._mapAirportIcon.surface;
            me._mapAirportIcon.displayed = runway.length > mapOptions.runwayLength ? 1 : me._mapAirportIcon.displayed;

            if (mapOptions.range <= 10) {    # drawing real runways
                me._can.layout.createChild('path', 'airport-runway-' ~ me._id ~ '-' ~ runway.id)
                    .setStrokeLineWidth(7)
                    .setColor(1,1,1)
                    .setColorFill(1,1,1)
                    .setDataGeo([
                        canvas.Path.VG_MOVE_TO,
                        canvas.Path.VG_LINE_TO,
                        canvas.Path.VG_CLOSE_PATH
                    ],[
                        'N' ~ runway.lat, 'E' ~ runway.lon,
                        'N' ~ runway.reciprocal.lat, 'E' ~ runway.reciprocal.lon,
                    ]);
            }
            elsif (mapOptions.range <= 32) {     #draw icon runways
                me._can.layoutIcon.setGeoPosition(apt.lat, apt.lon);
                me._can.layoutIcon.createChild('path', 'airport-runway-' ~ me._id ~ '-' ~ runway.id)
                    .setStrokeLineWidth(7)
                    .setColor(1,1,1)
                    .setColorFill(1,1,1)
                    .setData([
                        canvas.Path.VG_MOVE_TO,
                        canvas.Path.VG_LINE_TO,
                        canvas.Path.VG_CLOSE_PATH
                    ],[
                        0, -20,
                        0, 20,
                    ])
                    .setRotation((runway.heading)* D2R);
            }
        }
        me._mapAirportIcon.icon = 'Airport_'
            ~ me._mapAirportIcon.near
            ~ me._mapAirportIcon.surface
            ~ me._mapAirportIcon.tower
            ~ me._mapAirportIcon.center;

        if (me._mapAirportIcon.displayed) {
            me._can.label
                .setText(apt.id)
                .setRotation(-mapOptions.orientation * D2R);
            me._can.group.setGeoPosition(apt.lat, apt.lon);
            if (mapOptions.range <= 10) {
                me._can.image.setVisible(0);
                me._can.layout.setVisible(1);
            }
            elsif (mapOptions.range <= 32) {
                mapIconCache.boundIconToImage(me._mapAirportIcon.icon, me._can.image);
                me._can.image.setVisible(1);
                me._can.layout.setVisible(1);
            }
            else {
                mapIconCache.boundIconToImage(me._mapAirportIcon.icon, me._can.image);
                me._can.layout.setVisible(0);
                me._can.image.setVisible(1);
            }
            me._can.group.setVisible(1);
        }
        return me._mapAirportIcon.displayed;
    },
    update : func (mapOptions) {
        if (mapOptions.range <= 10) { }
        elsif (mapOptions.range <= 32)
            me._can.layoutIcon.setRotation(-mapOptions.orientation * D2R);
        else { }
    },
    setVisible : func (visibility) {
        me._can.group.setVisible(visibility);
        me._can.layout.setVisible(visibility);
        me._can.image.setVisible(visibility);
        me._can.layoutIcon.setVisible(visibility);
    },
};
# }}}

var MapNavaidItem = {
# manage navaids items by adding ID in the icon {{{
    new : func (id, type) {
        var m = {parents:[MapNavaidItem]};
        m._id = id;
        m._type = type;
        m._can = {
            'group' : nil,
            'label' : nil,
            'image' : nil,
        };
        return m;
    },
    create : func (group) {
        me._can.group = group
            .createChild('group', me._type ~ '_' ~ me._id);

        me._can.image = me._can.group.createChild('image', me._type ~ '-image_' ~ me._id)
            .setFile(mapIconCache._canvas.getPath())
            .setSourceRect(0,0,0,0,0);

        me._can.label = me._can.group.createChild('text', me._type ~ '-label_' ~ me._id)
            .setDrawMode( canvas.Text.TEXT )
            .setTranslation(0,42)
            .setAlignment('center-bottom-baseline')
            .setFont('LiberationFonts/LiberationSans-Regular.ttf')
            .setFontSize(16);

        me._can.label.set('fill','#BACBFB');
        me._can.label.set('stroke','#000000');

        return me._can.group;
    },
    setData : func (navaid, type, mapOptions) {
        mapIconCache.boundIconToImage('Navaid_' ~ type, me._can.image);
        me._can.label
            .setText(navaid.id)
            .setRotation(-mapOptions.orientation * D2R);
        me._can.group.setGeoPosition(navaid.lat, navaid.lon);
    },
    setVisible : func (visibility) {
        me._can.group.setVisible(visibility);
    },
};
# }}}

var MapAirplaneItem = {
# set airplane on ND {{{
    new : func {
        var m = {parents:[MapAirplaneItem]};
        m._can = {
            'group' : nil,
            'image' : nil,
        };
        return m;
    },
    create : func (group) {
        me._can.group = group
            .createChild('group', 'airplane');
        me._can.image = me._can.group.createChild('image', 'airplane-image')
            .setFile(mapIconCache._canvas.getPath())
            .setSourceRect(0,0,0,0,0);
        return me._can.group;
    },
    setData : func (orientation) {
        mapIconCache.boundIconToImage('airplane', me._can.image);
        me._can.group
            .setGeoPosition(data.lat, data.lon)
            .setRotation(orientation * D2R);
    },
    setVisible : func (visibility) {
        me._can.group.setVisible(visibility);
    },
};
# }}}

var MAP_RUNWAY_SURFACE =  {0:0, 1:1, 2:1, 3:0, 4:0, 5:0, 6:1, 7:1, 8:0, 9:0, 10:0, 11:0, 12:0};
var MAP_RUNWAY_AT_RANGE = func (range) {
    if (range < 40) return 0;
    if (range < 50) return 250;
    if (range < 80) return 500;
    if (range < 160) return 1000;
    if (range < 240) return 3000;
    return 3000;
}
var MAP_TXRANGE_VOR = func (range) {
    if (range < 40) return 0;
    if (range < 50) return 20;
    if (range < 80) return 25;
    if (range < 160) return 30;
    if (range < 240) return 50;
    return 100;
}
####
# Declutter
#   land
#       0 : 'Terrain'
#       1 : 'Political boundaries'
#       2 : 'River/Lakes/Oceans'
#       3 : 'Roads'
#   Nav
#       0 : 'Airspace'
#       1 : 'Victor/Jet airways'
#       2 : 'Obstacles'
#       3 : 'Navaids'

var MapNavaids = {
# the layer to show navaids, airports and airplane symbol {{{
    new : func (device, group) {
        var m = {parents : [MapNavaids]};

        m._model = nil;
        m.device = device;
        m._visibility = m.device.role == 'MFD';

        m._group = group.createChild('map', 'MFD map')
            .setTranslation(
                m.device.role == 'MFD' ? (m.device.data.mapview[0] + m.device.data.mapclip.left)/2 : 120,
                m.device.role == 'MFD' ? 400 : 600)
            .setRange(m.device.data['range-nm']/2)
            .setVisible(m._visibility);

        m._can = {};
        m._cache = {};
        foreach (var n; ['airport', 'VOR', 'TACAN', 'NDB', 'DME']) {
            m._can[n] = m._group.createChild('group', n);
            m._cache[n] = {
                'data' : [],
                'index' : 0,
                'max' : 100,
            };
        }
        m._can['airplane'] = m._group.createChild('group', 'airplane');
        m._cache['airplane'] = {
            displayed : 0,
            item : nil,
        };

        m._mapOptions = {
            declutterLand : 3,
            declutterNAV  : 3,
            lightning     : 0,
            reports       : 0,
            overlay       : 0,
            range         : m.device.data['range-nm'] / 2,
            runwayLength  : -1,
            orientation   : m.device.data.orientation.map,
        };

        m._results = nil;

        if (m.device.role == 'PFD') {
            m.device.softkeys.colored.INSETNAVAIDSALL = 1;
            m.device.softkeys.colored.INSETNAVAIDSTACAN = 1;
            m.device.softkeys.colored.INSETNAVAIDSVOR = 1;
            m.device.softkeys.colored.INSETNAVAIDSNDB = 1;
            m.device.softkeys.colored.INSETNAVAIDSDME = 1;
            m.device.softkeys.colored.INSETNAVAIDSAPT = 1;
        }
        if (m.device.role == 'MFD') {
            m.device.softkeys.colored.MAPNAVAIDSALL = 1;
            m.device.softkeys.colored.MAPNAVAIDSTACAN = 1;
            m.device.softkeys.colored.MAPNAVAIDSVOR = 1;
            m.device.softkeys.colored.MAPNAVAIDSNDB = 1;
            m.device.softkeys.colored.MAPNAVAIDSDME = 1;
            m.device.softkeys.colored.MAPNAVAIDSAPT = 1;
        }

        return m;
    },
    off: func {
        me._group.setVisible(0);
        me._group.removeAllChildren();
    },
    update : func {
        me._group._node.getNode('ref-lat', 1).setDoubleValue(data.lat);
        me._group._node.getNode('ref-lon', 1).setDoubleValue(data.lon);

        me._group.setRange(me.device.data['range-nm']/2);
        me._mapOptions.orientation = me.device.data.orientation.map;

        if (me._visibility == 1) {
            me.loadAirport();
            foreach (var n; ['VOR', 'TACAN', 'NDB', 'DME'])
                me.loadNavaid(n);
            me.loadAirplane();
        }
    },
    _onVisibilityChange : func {
        me._group.setVisible(me._visibility);
    },
    setMapOptions : func (mapOptions) {
        me._mapOptions = mapOptions;
        me.update();
    },
    updateOrientation : func (value) {
        me._mapOptions.orientation = value;
        for (var i = 0 ; i < me._cache.airport.index ; i +=1) {
            item = me._cache.airport.data[i];
            item.update(me._mapOptions);
        }
    },
    setRotation : func (deg) {
        me._group.setRotation(deg * D2R);
    },
    setVisible : func (v) {
        if (me._visibility != v) {
            me._visibility = v;
            me._onVisibilityChange();
        }
    },
    _onVisibilityChange : func {
        me._group.setVisible(me._visibility);
    },
    # positioned.findWithinRange : any, fix, vor, ndb, ils, dme, tacan

    loadAirport : func {
        me._cache.airport.index = 0;
        var results = positioned.findWithinRange(me._mapOptions.range * 2.5, 'airport');
        var item = nil;

        if (me._mapOptions.declutterNAV >= 2)
            me._mapOptions.runwayLength = MAP_RUNWAY_AT_RANGE(me._mapOptions.range);
        elsif (me._mapOptions.declutterNAV >= 1)
            me._mapOptions.runwayLength = 2000;
        else
            me._mapOptions.runwayLength = 3000;

        if (me._mapOptions.runwayLength >= 0) {
            foreach (var apt; results) {
                if (me._cache.airport.index >= me._cache.airport.max )
                    break;

                if (size(me._cache.airport.data) > me._cache.airport.index)
                    item = me._cache.airport.data[me._cache.airport.index];
                else {
                    item = MapAirportItem.new(me._cache.airport.index);
                    item.create(me._can.airport);
                    append(me._cache.airport.data, item);
                }

                if (item.draw(apt, me._mapOptions)) {
                    item.setVisible(1);
                    me._cache.airport.index += 1;
                }
            }
        }

        for (var i = me._cache.airport.index ; i < size(me._cache.airport.data) ; i +=1) {
            item = me._cache.airport.data[i];
            item.setVisible(0);
        }
    },
    loadNavaid : func (type) {
        me._cache[type].index = 0;
        if (me._mapOptions.declutterNAV >= 3) { # TODO test for DME and NDB range < 100nm
            var range = me._mapOptions.range * 2.5;
            var txRange = MAP_TXRANGE_VOR(me._mapOptions.range);
            var results = positioned.findWithinRange(range, type);
            var item = nil;
            foreach (var n; results) {
                if (n.range_nm < txRange)
                    break;

                if (me._cache[type].index >= me._cache[type].max )
                    break;

                if (size(me._cache[type].data) > me._cache[type].index) {
                    item = me._cache[type].data[me._cache[type].index];
                    item.setData(n, type, me._mapOptions);
                }
                else {
                    item = MapNavaidItem.new(me._cache[type].index, type);
                    item.create(me._can[type]);
                    item.setData(n, type, me._mapOptions);
                    append(me._cache[type].data, item);
                }
                item.setVisible(1);
                me._cache[type].index += 1;
            }
        }
        for (var i = me._cache[type].index ; i < size(me._cache[type].data) ; i +=1) {
            item = me._cache[type].data[i];
            item.setVisible(0);
        }
    },
    loadAirplane : func {
        if (!me._cache.airplane.displayed) {
            me._cache.airplane.item = MapAirplaneItem.new();
            me._cache.airplane.item.create(me._can['airplane']);
            me._cache.airplane.displayed = 1;
        }
        me._cache.airplane.item.setData(me.device.data.orientation.airplane);
        me._cache.airplane.item.setVisible(1);
    },
};
# }}}

