# The following is largely inspired from the Extra500 Avidyne Entegra 9 
# https://gitlab.com/extra500/extra500.git
# Many thanks to authors: Dirk Dittmann and Eric van den Berg
var RouteItemClass = {
    new : func (canvasGroup, index) {
        var m = {parents:[RouteItemClass]};
        m.index = index;
        m.group = canvasGroup.createChild('group', 'Waypoint-' ~ index).setVisible(0);
        
        m.can = {
            Waypoint : m.group.createChild('path','icon-' ~ index)
                .setStrokeLineWidth(3)
                .setScale(1)
                .setColor(1,1,1)
                .setColorFill(1,1,1)
                .moveTo(-20, 0)
                .lineTo(-5, 5)
                .lineTo(0, 20)
                .lineTo(5, 5)
                .lineTo(20, 0)
                .lineTo(5, -5)
                .lineTo(0, -20)
                .lineTo(-5, -5)
                .close(),
            Label : m.group.createChild('text', 'wptLabel-' ~ index)
                .setFont('LiberationFonts/LiberationMono-Bold.ttf')
                .setTranslation(25,-25)
                .setFontSize(20, 1)
                .setColor(1,1,1)
                .setColorFill(1,1,1),
            track : canvasGroup.createChild('path','track-' ~ index)
                .setStrokeLineWidth(3)
                .setScale(1)
                .setColor(1,1,1)
                .setVisible(1),
        };
        return m;
    },
    setVisible : func (v) {
        me.group.setVisible(v);
        me.can.track.setVisible(v);
    },
    draw : func (wpt) {
        me.can.Label.setText(wpt[0].name);
        me.setColor(1,1,1);
        me.group.setGeoPosition(wpt[0].lat, wpt[0].lon);
        me.group.setVisible(1);
    },
    drawTrack : func (wpt) {
        var cmds = [];
        var coords = [];
        var cmd = canvas.Path.VG_MOVE_TO;
        me.can.track.setVisible(1);
        
        foreach (var pt; wpt) {
            append(coords, 'N' ~ pt.lat);
            append(coords, 'E' ~ pt.lon);
            append(cmds, cmd);
            cmd = canvas.Path.VG_LINE_TO;
        }
        me.can.track.setDataGeo(cmds, coords);
    },
    setColor : func (color) {
        me.can.Label.setColor(color).setColorFill(color);
        me.can.Waypoint.setColor(color).setColorFill(color);
    },
    del : func {
        me.can.track.del();
        me.group.del();
        me = nil;
    },
};

var FMSIcon = {
    new : func (canvasGroup, text) {
        var m = {parents:[ FMSIcon ]};
        m.group = canvasGroup.createChild('group', 'FMS-' ~ text).setVisible(0);   
        m.can = {
            icon : m.group.createChild('path','FMS-icon' ~ text)
                .setStrokeLineWidth(3)
                .setScale(1)
                .setColor(0,1,0)
                .setColorFill(0,1,0)
                .moveTo(-15, 0)
                .lineTo(0, 15)
                .lineTo(15, 0)
                .lineTo(0, -15)
                .close(),
            label : m.group.createChild('text', 'FMS-label-' ~ text)
                .setFont('LiberationFonts/LiberationMono-Bold.ttf')
                .setTranslation(20,12)
                .setFontSize(32, 1)
                .setColor(0,1,0)
                .setColorFill(0,1,0)
                .setText(text),
        };
        return m;
    },
    setVisible : func (v)
        me.group.setVisible(v),
    setGeoPosition : func (lat, lon)
        me.group.setGeoPosition(lat, lon),
};

var FMSIconRTA = {
    new : func (canvasGroup, text) {
        var m = {parents:[FMSIconRTA]};
        m.group = canvasGroup.createChild('group', 'FMS-' ~ text).setVisible(0);   
        m.can = {
            icon : m.group.createChild('path','FMS-icon' ~ text)
                .setStrokeLineWidth(3)
                .setScale(1)
                .setColor(0,1,0)
                .setColorFill(0,1,0)
                .moveTo(-15, 0)
                .lineTo(0, 15)
                .lineTo(15, 0)
                .lineTo(0, -15)
                .close(),
            label : m.group.createChild('text', 'FMS-label-' ~ text)
                .setFont('LiberationFonts/LiberationMono-Bold.ttf')
                .setTranslation(-80,12)
                .setFontSize(32, 1)
                .setColor(0,1,0)
                .setColorFill(0,1,0)
                .setText(text),
        };
        return m;
    },
    setVisible : func (v)
        me.group.setVisible(v),
    setGeoPosition : func (lat, lon)
        me.group.setGeoPosition(lat, lon),
};

var MapRoute = {
    new : func (device, group) {
        var m = {parents:[ MapRoute ]}; 
        m.item       = [];
        m.itemIndex  = 0;
        m.visibility = 0;
        m.device = device;
        m.group = group.createChild('map', 'route map')
            .setTranslation(
                m.device.role == 'MFD' ? (m.device.data.mapview[0] + m.device.data.mapclip.left)/2 : 120,
                m.device.role == 'MFD' ? 400 : 600)
            .setVisible(m.visibility);
        m.group.setRange(m.device.data['range-nm']/2);
        m.group._node
            .getNode('ref-lat', 1).setDoubleValue(data.lat);
        m.group._node
            .getNode('ref-lon', 1).setDoubleValue(data.lon);

        m.groupTrack = m.group.createChild('group', 'Track')
            .setVisible(1);
        m.groupOBS   = m.group.createChild('group', 'OBS')
            .setVisible(0);
        m.groupFMS   = m.group.createChild('group', 'FMS')
            .setVisible(1);
        
        m.can = {
            track : m.group.createChild('path', 'track')
                .setStrokeLineWidth(3)
                .setScale(1)
                .setColor(1,1,1),
            currentLeg : m.groupFMS.createChild('path', 'currentLeg')
                .setStrokeLineWidth(5)
                .setScale(1)
                .setColor(1,0,1),
            nextLeg : m.groupFMS.createChild('path', 'nextLeg')
                .setStrokeLineWidth(5)
                .setScale(1)
                .setStrokeDashArray([25,25])
                .setColor(1,0,1),
            obsCourse : m.groupOBS.createChild('path', 'obsCourse')
                .setStrokeLineWidth(5)
                .setScale(1)
                .setColor(1,0,1),
        };
        
        m.TOD = FMSIcon.new(m.groupFMS, 'TOD');
        m.TOC = FMSIcon.new(m.groupFMS, 'TOC');
        m.RTA = FMSIconRTA.new(m.groupFMS, 'RTA');
        
        m.track = {
            cmds  : [],
            coords: [],
        };
        m.currentLeg = {
            cmds: [ canvas.Path.VG_MOVE_TO, canvas.Path.VG_LINE_TO ],
            coords: [0, 0, 0, 0],
            index : -1,
        };
        m.nextLeg = {
            cmds: [ canvas.Path.VG_MOVE_TO, canvas.Path.VG_LINE_TO ],
            coords: [0, 0, 0, 0],
            index : -1,
        };
        
        m.mapOptions = {
            orientation : 0,
        };
        
        m.obsMode = 0;
        m.obsCourse = 0;
        m.obsWaypoint = RouteItemClass.new(m.groupOBS, 'obs_wp');
        m.obsCourseData = {
            cmds: [ canvas.Path.VG_MOVE_TO, canvas.Path.VG_LINE_TO ],
            coords: [0, 0, 0, 0]};

        m.flightPlan = [];
        m.currentWpIndex = getprop('/autopilot/route-manager/current-wp');
        
        if (m.device.role == 'PFD')
            m.device.softkeys.colored.INSETROUTE = 1;
        if (m.device.role == 'MFD')
            m.device.softkeys.colored.MAPROUTE = 1;

        return m;
    },
    off: func {
        me.setVisible(0);
        me.group.setVisible(0);
        me.group.removeAllChildren();
    },
    update: func {
        me.visibility != 0 or return;
        me.group.setRange(me.device.data['range-nm']/2);
        me.group._node.getNode('ref-lat', 1).setDoubleValue(data.lat);
        me.group._node.getNode('ref-lon', 1).setDoubleValue(data.lon);
    },
    setVisible : func (v) {
        if (me.visibility != v) {
            me.visibility = v;
            me.group.setVisible(v);
        }
    },
    updateOrientation : func (value) {
        me.mapOptions.orientation = value;
        me.can.obsCourse.setRotation((me.obsCourse - me.mapOptions.orientation) * D2R);
    },
    onFlightPlanChange : func {
        for (var i = size(me.item) - 1; i >= 0; i -= 1) {
            me.item[i].del();
            pop(me.item);
        }
        me.itemIndex = 0;
        me.flightPlan = [];
        var route = props.globals.getNode('/autopilot/route-manager/route');
        var planSize = getprop('/autopilot/route-manager/route/num');
        for (var i=0; i < planSize - 1; i+=1) {
            var wp0  = route.getNode('wp[' ~   i   ~ ']');
            var wp1  = route.getNode('wp[' ~ (i+1) ~ ']');
            append(me.flightPlan, [
                {
                    lat : wp0.getNode('latitude-deg').getValue(),
                    lon : wp0.getNode('longitude-deg').getValue(),
                    name: wp0.getNode('id').getValue(),
                },
                {
                    lat : wp1.getNode('latitude-deg').getValue(),
                    lon : wp1.getNode('longitude-deg').getValue(),
                    name: wp1.getNode('id').getValue(),
                }
            ]);
            append(me.item, RouteItemClass.new(me.groupTrack, i));
        }
        me.setVisible(me.device.map.visibility);
        me.drawWaypoints();
    },
    onCurrentWaypointChange : func (n) {
        me.currentWpIndex = n.getValue();
        me.currentLeg.index = me.currentWpIndex - 1;
        me.nextLeg.index = me.currentWpIndex;
        if (me.currentWpIndex == 0) {
            n.setIntValue(1);
            me.currentWpIndex = 1;
        }
        me.drawLegs();
    },
    drawWaypoints : func {
        me.visibility != 0 or return;
        var cmd = canvas.Path.VG_MOVE_TO;

        for (var i=0; i < size(me.flightPlan); i+=1) {
#            me.item[me.itemIndex].draw(me.flightPlan[i]);
            me.item[me.itemIndex].drawTrack(me.flightPlan[i]);
            me.itemIndex +=1;
        }
        me.groupTrack.setVisible(me.visibility and (me.obsMode == 0));
    },
    drawLegs : func {
        me.visibility != 0 or return;
        if (me.currentLeg.index >= 0 and me.currentLeg.index < size(me.flightPlan)) {
            var cmd = canvas.Path.VG_MOVE_TO;
            me.currentLeg.coords = [];
            me.currentLeg.cmds = [];
            foreach (var pt; me.flightPlan[me.currentLeg.index]) {
                append(me.currentLeg.coords, 'N' ~ pt.lat);
                append(me.currentLeg.coords, 'E' ~ pt.lon);
                append(me.currentLeg.cmds, cmd);
                cmd = canvas.Path.VG_LINE_TO;
            }
            me.can.currentLeg.setDataGeo(me.currentLeg.cmds, me.currentLeg.coords);
            me.can.currentLeg.setVisible(1);
        }
        else
            me.can.currentLeg.setVisible(0);
        
        if (me.nextLeg.index >= 1 and me.nextLeg.index < size(me.flightPlan)) {
            var cmd = canvas.Path.VG_MOVE_TO;
            me.nextLeg.coords = [];
            me.nextLeg.cmds = [];
            foreach (var pt; me.flightPlan[me.nextLeg.index]) {
                append(me.nextLeg.coords,'N' ~ pt.lat);
                append(me.nextLeg.coords,'E' ~ pt.lon);
                append(me.nextLeg.cmds,cmd);
                cmd = canvas.Path.VG_LINE_TO;
            }
            me.can.nextLeg.setDataGeo(me.nextLeg.cmds, me.nextLeg.coords);
            me.can.nextLeg.setVisible(1);
        }
        else
            me.can.nextLeg.setVisible(0);
    },
#    _onVisibilityChange : func {
#        me.group.setVisible(me.visibility and (me.obsMode == 0));
#        me.groupTrack.setVisible(me.visibility and (me.obsMode == 0));
#        me.groupFMS.setVisible(me.visibility and (me.obsMode == 0));
#        me.groupOBS.setVisible(me.visibility and (me.obsMode == 1));
#        me.TOD.setVisible(fms._dynamicPoint.TOD.visible and me.visibility);
#        me.TOC.setVisible(fms._dynamicPoint.TOC.visible and me.visibility);
#        me.RTA.setVisible(fms._dynamicPoint.RTA.visible and me.visibility);
#    },
#    _onFplReadyChange : func (n) {
#        me.TOD.setVisible(fms._dynamicPoint.TOD.visible and me.visibility);
#        me.TOC.setVisible(fms._dynamicPoint.TOC.visible and me.visibility);
#        me.RTA.setVisible(fms._dynamicPoint.RTA.visible and me.visibility);
#    },
#    _onFplUpdatedChange : func (n) {
#        if (fms._dynamicPoint.TOD.visible)
#            me.TOD.setGeoPosition(fms._dynamicPoint.TOD.position.lat, fms._dynamicPoint.TOD.position.lon);
#        if (fms._dynamicPoint.TOC.visible)
#            me.TOC.setGeoPosition(fms._dynamicPoint.TOC.position.lat, fms._dynamicPoint.TOC.position.lon);
#        if (fms._dynamicPoint.RTA.visible)
#            me.RTA.setGeoPosition(fms._dynamicPoint.RTA.position.lat, fms._dynamicPoint.RTA.position.lon);  
#        
#        me.TOD.setVisible(fms._dynamicPoint.TOD.visible and me.visibility);
#        me.TOC.setVisible(fms._dynamicPoint.TOC.visible and me.visibility);
#        me.RTA.setVisible(fms._dynamicPoint.RTA.visible and me.visibility);
#    },
#    _onObsModeChange : func (n) {
#        me.obsMode = n.getValue();
#        
#        if (me.obsMode==1) {
#            var wp = {
#                wp_lat : getprop('/instrumentation/gps[0]/scratch/latitude-deg'),
#                wp_lon : getprop('/instrumentation/gps[0]/scratch/longitude-deg'),
#                wp_name : getprop('/instrumentation/gps[0]/scratch/ident'),
#            };
#            var acLat = getprop('/position/latitude-deg');
#            var acLon = getprop('/position/longitude-deg');
#            
#            me.groupOBS.setGeoPosition(wp.wp_lat, wp.wp_lon);
#            
#            me.obsCourseData.coords = [
#                0,
#                0,
#                0,
#                5000,
#            ];
#            
#            me.obsWaypoint._can.Label.setText(wp.wp_name);
#            me.obsWaypoint.setColor(1,0,1);
#            me.obsWaypoint._group.setVisible(1);
#            
#            me.can.obsCourse.setData(me.obsCourseData.cmds,me.obsCourseData.coords);
#        }
#        
#        me.groupTrack.setVisible(me.visibility and (me.obsMode == 0));
#        me.groupFMS.setVisible(me.visibility and (me.obsMode == 0));
#        me.groupOBS.setVisible(me.visibility and (me.obsMode == 1));
#    },
#    _onObsCourseChange : func (n) {
#        me.obsCourse = n.getValue();
#        me.can.obsCourse.setRotation((me.obsCourse - me.mapOptions.orientation) * global.CONST.DEG2RAD);
#    },
};

