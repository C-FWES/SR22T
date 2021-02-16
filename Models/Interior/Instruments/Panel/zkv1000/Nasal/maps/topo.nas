var MapTopo = {
    new : func(device, group) {
        var m = { parents: [ MapTopo ] };
        m.device = device;
        m.visibility = 0;
        m.dist_scale = 10;
        m.radial_scale = 11;
        m.group = group.createChild('group', 'topo')
            .setTranslation((m.device.data.mapview[0] + m.device.data.mapclip.left)/2, 400)
            .setRotation(m.device.data.orientation.airplane * D2R)
            .setVisible(m.visibility);
        for (var dist = 0; dist < m.dist_scale; dist += 1) {
            for (var radial = 0; radial < 11; radial += 1) {
                if (radial + dist)
                    m.arc((radial * 10) - 50, (dist * 35) + 10);
                else
                    m.path = m.arc((radial * 10) - 50, (dist * 35) + 10).parents[1]._node.getPath();
            }
        }
        data.timers.topo_radar = maketimer(0, func {
            var (radial, dist) = [m.radial, m.dist];
            var geo = greatCircleMove(data.hdg + ((radial * 10) - 50),
                                      m.delta_radar_dist_nm * dist + m.delta_radar_dist_nm/2);
            var _geodinfo = geodinfo(geo.lat, geo.lon, 10000);
            if (_geodinfo != nil) {
                var diff = _geodinfo[0] * units.altitude.from_m - data.alt;

                var color = 'rgba(255, 127, 40, 1)';
                if (diff > 1000 * units.altitude.from_ft)
                    color = 'rgba(255, 0, 0, 1)';
                elsif (diff < 0 and diff > -300 * units.altitude.from_ft)
                    color = sprintf('rgba(255, 127, 40, %f)', 1 + 0.5 * (diff / (300 * units.altitude.from_ft)) );

                setprop(m.path, radial + m.radial_scale * dist, 'fill', color);
                setprop(m.path, radial + m.radial_scale * dist, 'visible', diff > -300 * units.altitude.from_ft);
            }
            if    (m.radial < m.radial_scale - 1)
                m.radial += 1;
            elsif (m.dist   <  m.dist_scale - 1) {
                m.dist   += 1;
                m.radial = 0;
            }
            else {
                m.dist = 0;
                m.radial = 0;
            }
        });
        m.device.data.orientation.radar = 0;
        m.dist = 0;
        m.radial = 0;
        m.delta_radar_dist_nm = m.device.data['range-nm'] / m.dist_scale;
        return m;
    },

    arc: func(radial, dist) {
        var from_deg = (radial - 5) * D2R;
        var to_deg = (radial + 5) * D2R;
        var (fs1, fc1) = [math.sin(from_deg), math.cos(from_deg)];
        var dx1 = (math.sin(to_deg) - fs1) * dist;
        var dy1 = (math.cos(to_deg) - fc1) * dist;
        var (fs2, fc2) = [math.sin(to_deg), math.cos(to_deg)];
        var dx2 = (math.sin(from_deg) - fs2) * (dist + 35);
        var dy2 = (math.cos(from_deg) - fc2) * (dist + 35);

        return me.group.createChild('path', sprintf('arc %-02i@%02i', radial, dist))
            .moveTo(dist*fs1, -dist*fc1)
            .arcSmallCW(dist, dist, 0, dx1, -dy1)
            .lineTo((dist + 35)*fs2, -(dist + 35)*fc2)
            .arcSmallCW(dist + 35, dist + 35, 0, dx2, -dy2)
            .close()
            .setColorFill(1,0,0,0.75)
            .setVisible(0);
    },

    setVisible : func (v) {
        if (me.visibility != v) {
            me.visibility = v;
            me.group
                .setRotation(me.device.data.orientation.airplane * D2R)
                .setVisible(v);
        }
        if (me.visibility)
            data.timers.topo_radar.start();
        else
            data.timers.topo_radar.stop();
    },

    off : func {
        me.setVisible(0);
        me.group.removeAllChildren();
    },

    update : func {
        if (me.visibility) {
            me.group.setRotation(me.device.data.orientation.airplane * D2R);
            me.delta_radar_dist_nm = me.device.data['range-nm'] / me.dist_scale;
        }
    },
};
