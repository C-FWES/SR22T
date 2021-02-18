var setListeners = func {
    var prop = '/instrumentation/nav/nav-id';
    data.listeners[prop] = setlistener(prop,
            func (n) {
                var val = n.getValue();
                foreach (var c; keys(flightdeck))
                    flightdeck[c].display.updateNAV({'nav-id': 1, val: val});
            }, 1, 2);

    prop = '/instrumentation/nav[1]/nav-id';
    data.listeners[prop] = setlistener(prop,
            func (n) {
                var val = n.getValue();
                foreach (var c; keys(flightdeck))
                    flightdeck[c].display.updateNAV({'nav-id': 2, val: val});
            }, 1, 2);

    prop = '/instrumentation/nav/has-gs';
    data.listeners[prop] = setlistener(prop,
            func (n) {
                if (n.getValue()) {
                    foreach (var c; keys(flightdeck)) {
                        if (flightdeck[c].role == 'PFD') {
                            flightdeck[c].display.screenElements['VDI-scale'].show();
                            flightdeck[c].display.screenElements['GS-ILS'].show();
                            flightdeck[c].display.timers.updateGS.start();
                        }
                    }
                }
                else {
                    foreach (var c; keys(flightdeck)) {
                        if (flightdeck[c].role == 'PFD') {
                            flightdeck[c].display.screenElements['VDI-scale'].hide();
                            flightdeck[c].display.screenElements['GS-ILS'].hide();
                            flightdeck[c].display.timers.updateGS.stop();
                        }
                    }
                }
            }, 1, 0);

    # keep this listener as long as the code is to heavy to be modified in multiple places
    prop = afcs.getNode('selected-alt-ft').getPath();
    data.listeners[prop] = setlistener(prop,
            func (n) {
                var val = n.getValue();
                if (val != nil)
                    foreach (var c; keys(flightdeck))
                        if (flightdeck[c].role == 'PFD') {
                            if (! flightdeck[c].display.screenElements['SelectedALT'].getVisible()) {
                                flightdeck[c].display.screenElements['SelectedALT'].show();
                                flightdeck[c].display.screenElements['SelectedALT-text'].show();
                                flightdeck[c].display.screenElements['SelectedALT-symbol'].show();
                                flightdeck[c].display.screenElements['SelectedALT-bug'].show();
                                flightdeck[c].display.screenElements['SelectedALT-bg'].show();
                            }
                            flightdeck[c].display.updateSelectedALT();
                        }
            }, 0, 2);

    prop = '/gear/gear/wow';
    data.listeners[prop] = setlistener(prop,
            func foreach (var c; keys(flightdeck))
                if (flightdeck[c].role == 'PFD')
                    flightdeck[c].display.updateXPDR(),
            0, 0);

    prop = misc.getNode('alt-setting-inhg').getPath();
    data.listeners[prop] = setlistener(prop,
            func foreach (var c; keys(flightdeck))
                if (flightdeck[c].role == 'PFD')
                    flightdeck[c].display.updateBARO(), 0, 2);

    prop = '/autopilot/route-manager/signals/edited';
    data.listeners[prop] = setlistener(prop,
            func foreach (var c; keys(flightdeck))
                flightdeck[c].map.layers.route.onFlightPlanChange(),
                0, 1);

    prop = '/autopilot/route-manager/current-wp';
    data.listeners[prop] = setlistener(prop,
            func (n) {
                var wp_idx = n.getValue();
                if (wp_idx > 0) {
                    var wp_path = '/autopilot/route-manager/route/wp[' ~ wp_idx ~ ']/';
                    var wp = findNavaidsByID(getprop(wp_path ~ 'latitude-deg'),
                                             getprop(wp_path ~ 'longitude-deg'),
                                             getprop(wp_path ~ 'id'));
                    call(func {return wp[0].frequency}, [], nil, nil, var errors = []);
#                    if (!size(errors)) debuginfo ~ sprintf('; freq: %d', wp[0].frequency);
                    call(func {return wp[0].type}, [], nil, nil, var errors = []);
#                    if (!size(errors)) debuginfo ~ sprintf('; type: %s', wp[0].type);
                }
                var delay = maketimer(2, func {
                    foreach (var c; keys(flightdeck))
                        flightdeck[c].map.layers.route.onCurrentWaypointChange(
                                props.globals.getNode('/autopilot/route-manager/current-wp'));
                    });
                delay.singleShot = 1;
                delay.start();
            }, 0, 1);

    prop = '/autopilot/route-manager/active';
    data.listeners[prop] = setlistener(prop,
            func foreach (var c; keys(flightdeck))
                    flightdeck[c].map.layers.route.onCurrentWaypointChange(props.globals.getNode('/autopilot/route-manager/current-wp')),
                0, 1);

    if (zkv.getChild('serviceable') != nil) {
        prop = zkv.getPath() ~ '/serviceable';
        data.listeners[prop] = setlistener(prop,
                func (n) {
                    var type = n.getType();
                    if (type == 'BOOL') {
                        if (n.getBoolValue())
                            zkv1000.powerOn();
                        else
                            zkv1000.powerOff();
                    }
                    elsif (type == 'INT' or type == 'LONG' or type == 'FLOAT' or type == 'DOUBLE') {
                        if (n.getValue() > 12)
                            zkv1000.powerOn();
                        else
                            zkv1000.powerOff();
                    }
                }, 0, 0);
    }

    # the timer isn't necessary anymore
    data.timers.listeners.stop();
    delete(data.timers, 'listeners');
}

var deviceClass = {
    new: func (name) {
        var m = { parents: [ deviceClass ] };
        m.name = name;
        m.role = substr(name, 0, 3);
        m.node = zkv.getNode(name, 1);
        m.data = {};
        m.timers = {};
        foreach (var v; keys(data.Vspeeds))
            m.data[v ~ '-visible'] = 1;
        foreach (var v; ['screen-object', 'screen-view', 'screen-size'])
            m.data[v] = getprop(zkv.getPath() ~ '/' ~ name ~ '/' ~ v);

        m.display  = displayClass.new(m);
        m.softkeys = softkeysClass.new(m);
        m.buttons  = buttonsClass.new(m);
        m.knobs    = knobsClass.new(m);
        m.map      = mapClass.new(m);
        m.windows  = pageClass.new(m);

        if (! contains(data.timers, 'alt-setting-inhg')) {
            data.timers['alt-setting-inhg'] = maketimer(0.1, m, func {
                    var inhg = getprop('/instrumentation/altimeter/setting-inhg');
                    if (inhg != misc.getValue('alt-setting-inhg'))
                        misc.getNode('alt-setting-inhg').setValue(inhg);
                });
            data.timers['alt-setting-inhg'].start();
        }
        if (! contains(data.timers, 'map')) {
            data.timers.map = maketimer(1, m, func {
                    foreach (var d; keys(flightdeck))
                        flightdeck[d].map.update();
                    var gspd = getprop('/velocities/groundspeed-kt');
                    if (gspd != 0)
                        var next = (me.data['range-nm']/(gspd/3600))/(me.display.display.get('view[1]')/2);
                    else
                        var next = 10;
                    if (next > 10)
                        next = 10;
                    data.timers.map.restart(next);
                });
            data.timers.map.singleShot = 1;
            data.timers.map.start();
        }
        if (!contains(data.timers, 'tcas')) {
            data.timers.tcas = maketimer ( 5, func {
                var traffic_displayed = 0;
                foreach (var name; keys(flightdeck))
                    if (contains(flightdeck[name].map.layers, 'tcas'))
                        traffic_displayed += flightdeck[name].map.layers.tcas.group.getVisible();
                var tcas_dirty = [];
                var level_dirty = 0;
                foreach (var AItype; [ 'aircraft', 'multiplayer' ])
                    foreach (var ac; props.globals.getNode("/ai/models").getChildren(AItype)) {
                        if (ac.getValue("valid")) {
                            var lat = ac.getNode("position/latitude-deg").getValue();
                            var lon = ac.getNode("position/longitude-deg").getValue();
                            var alt = ac.getNode("position/altitude-ft").getValue();
                            var vs  = ac.getNode("velocities/vertical-speed-fps").getValue();
                            if (isnum(lat) and isnum(lon) and isnum(vs) and isnum(alt)) {
                                alt = math.floor(((alt - data.alt) / 100) + 0.5);
                                var (course, dist) = courseAndDistance(lat, lon,
                                                     geo.Coord.new().set_latlon(data.lat, data.lon));
                                if (dist < 50) {
                                    var dir = ac.getNode('orientation/true-heading-deg').getValue() - course;
                                    if (dist < 5 and abs(alt) < 10)
                                        level = 3;
                                    elsif (dist < 10 and alt * vs < 0 and abs(dir) < 10)
                                        level = 3;
                                    elsif (dist < 15 and abs(alt) < 5)
                                        level = 2;
                                    elsif (dist < 15 and abs(alt) < 50)
                                        level = 1;
                                    else
                                        level = 0;
                                    level_dirty = level > level_dirty ? level : level_dirty;
                                    if (traffic_displayed)
                                        append(tcas_dirty, {
                                            lat: lat,
                                            lon: lon,
                                            vs: vs,
                                            alt: alt,
                                            level: level,
                                            callsign: ac.getValue('callsign')
                                        });
                                }
                            }
                        }
                    }
                data.tcas = tcas_dirty;
                data.tcas_level = level_dirty;
            });
            data.timers.tcas.start();
        }
        m.display.showInitProgress();

        setprop(zkv.getPath() ~ '/' ~ m.name ~ '/status', 1);
        msg(m.name ~ ' switched on!');
        return m;
    },
    off: func {
        var name = me.name;
        foreach (var timer; keys(me.timers)) {
            me.timers[timer].stop();
            delete(me.timers, timer);
        }
        foreach (var member; keys(me)) {
            if (member == 'parents')
                continue;
            if (contains(me[member], 'parents')) {
                if (contains(me[member].parents[0], 'new')
                and typeof(me[member].parents[0].new) == 'func') {
                    if (contains(me[member].parents[0], 'removeAllChildren')
                    and !contains(me[member].parents[0], 'setVisible')) # this one is a props node, but not canvas
                        me[member].removeAllChildren();
                    elsif (contains(me[member].parents[0], 'off')
                    and typeof(me[member].parents[0].off) == 'func')
                        me[member].off();
                }
            }
        }
        foreach (var member; keys(me)) {
            if (member == 'parents')
                continue;
            delete(me, member);
        }
        zkv.getNode(name).setValue('status', 0);
        msg(name ~ ' switched off');
    },
};

var powerOff = func {
    foreach (var listener; keys(data.listeners)) {
        if (listener == '/instrumentation/zkv1000/serviceable')
            continue;
        removelistener(data.listeners[listener]);
        delete(data.listeners, listener);
    }

    foreach (var timer; keys(data.timers)) {
        data.timers[timer].stop();
        if (timer == '80Hz' or timer == '40Hz')
            continue;
        delete(data.timers, timer);
    }

    foreach (var k; keys(autopilot))
        delete(autopilot, k);

    foreach (var name; keys(flightdeck)) {
        flightdeck[name].off();
        flightdeck[name] = nil;
    }
}

var powerOn = func {
    if (!zkv.getValue('serviceable')) {
        msg('not yet serviceable (check power)!');
        return;
    }

    if (contains(data.listeners, '/instrumentation/zkv1000/serviceable')) {
        removelistener(data.listeners['/instrumentation/zkv1000/serviceable']);
        delete(data.listeners, '/instrumentation/zkv1000/serviceable');
    }

    foreach (var freq; keys(data.timers))
        data.timers[freq].start();

    foreach (var name; keys(flightdeck))
        if (zkv.getNode(name) != nil)
            if (zkv.getNode(name).getValue('status') == nil or zkv.getNode(name).getValue('status') == 0)
#            thread.newthread(func {
                flightdeck[name] = deviceClass.new(name);
#            });

    if (! contains(autopilot, 'parents'))
        autopilot = APClass.new();

    if (! contains(annunciations, 'parents'))
        annunciations = annunciationsClass.new();

    if (! contains(data.timers, 'listeners')) {
        data.timers.listeners = maketimer(1, setListeners);
        data.timers.listeners.singleShot = 1;
        data.timers.listeners.start();
    }
}
