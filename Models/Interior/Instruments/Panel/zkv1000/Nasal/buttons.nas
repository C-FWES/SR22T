var buttonsClass = {
    new : func (device) {
        var m = { parents: [ buttonsClass ] };
        m.device = device;
        return m;
    },

    PAN : func (xdir = 0, ydir = 0) {
    },

    AsSwitchNAV : func {
        var n = radios.getValue('nav-tune');
        var tmp = getprop('/instrumentation/nav[' ~ n ~ ']/frequencies/selected-mhz');
        setprop('/instrumentation/nav[' ~ n ~ ']/frequencies/selected-mhz', getprop('/instrumentation/nav[' ~ n ~ ']/frequencies/standby-mhz'));
        setprop('/instrumentation/nav[' ~ n ~ ']/frequencies/standby-mhz', tmp);
        foreach (var c; keys(flightdeck))
            if (contains(flightdeck[c], 'display'))
                flightdeck[c].display.updateNAV({refresh: n+1});
    },

    AsSwitchCOM : func (x) {
        if (x) {
            me.AsSwitchCOM_pushed = getprop('/sim/time/elapsed-sec');
        }
        else {
            var pressed = getprop('/sim/time/elapsed-sec') - me.AsSwitchCOM_pushed;
            if (pressed > 2) {
                setprop('/instrumentation/comm/frequencies/selected-mhz', 121.500);
                radios.setValue('comm1-selected', 1);
                radios.setValue('comm2-selected', 0);
                foreach (var d; keys(flightdeck))
                    if (contains(flightdeck[d], 'display')) {
                        flightdeck[d].display.updateCOMM({refresh: 1});
                        flightdeck[d].display.updateCOMM({refresh: 2});
                    }
            }
            else {
                var c = radios.getValue('comm-tune');
                var tmp = getprop('/instrumentation/comm[' ~ c ~ ']/frequencies/selected-mhz');
                setprop('/instrumentation/comm[' ~ c ~ ']/frequencies/selected-mhz', getprop('/instrumentation/comm[' ~ c ~ ']/frequencies/standby-mhz'));
                setprop('/instrumentation/comm[' ~ c ~ ']/frequencies/standby-mhz', tmp);
                foreach (var d; keys(flightdeck))
                    if (contains(flightdeck[d], 'display'))
                        flightdeck[d].display.updateCOMM({refresh: c+1});
            }
        }
    },

    ALT : func () {
        var alt = getprop('instrumentation/altimeter/indicated-altitude-ft');
        afcs.setIntValue('selected-alt-ft', math.round(alt, 10));
    },

    ValidateTMRREF : func (a = 0) {
        if (a)
            return;
        var (id, selected) = split('-', me.device.windows.selected);
        var state = me.device.windows.state[id];
        selected += state.scroll.offset;
        if (contains(state.objects[selected], 'callback'))
            call(state.objects[selected].callback, [id, selected], me);
    },

    ClearTMRREF : func (a = 0) {
        if (a)
            return;
        me.device.windows.del();
        me.device.data.TMRtimer = nil;
        me.device.knobs.FmsInner = func;
        me.device.knobs.FmsOuter = func;
        me.device.buttons.ENT = func;
        me.device.buttons.FMS = func;
        me.device.buttons.CLR = func;
    },

    MFD_page_wrapper : func (id, selected) {
        var s = me.device.data[id][me.device.display['page selected']];
        var group = s.name;
        var subpage = s.objects[selected].text;

        foreach (var k; keys(me.device.windows.window))
            if (find(id, k) == 0) {
                me.device.windows.del(id);
                break;
            }
        call(me.device.display.MFD[group][subpage], [], me);
    },

    MapMenu : func (a = 0) {
        if (a == 1)
            return;
        var menu_label = 'MAP MENU';
        if (!contains(me.device.windows.window, menu_label ~ '-bg')) {
            var level_min = 13;
            var level_max = 7;
            var range_from_level = func (l) {
                var r = (me.device.display.display.get('view[1]') / 2 * 84.53 * math.cos(data.lat * D2R) / math.pow(2, l)) * units.distance.from_nm;
                return sprintf('% 3i%s', math.round(r, r > 10 ? 5 : 1), units.distance.from_nm == 1 ? 'NM' : 'km');
            }
            var ranges = [ sprintf('  %s >', range_from_level(level_max)) ];
            for (var i = level_max + 1; i <= level_min; i += 1)
                append(ranges, sprintf(i < level_min ? '< %s >' : '< %s  ', range_from_level(i)));
            var orientation = [ '  NORTH UP >', '<  TRK UP  >' ];
            if (getprop('/instrumentation/gps/route-distance-nm') != nil)
                append(orientation, '<  DTK UP  >');
            append(orientation, '<  HDG UP   ');
            me.device.windows.draw(
                    menu_label,
                    {x: 720, y: 100, w: 300, l:3, sep: 1},
                    [
                        {text: menu_label, type: 'title'},
                        {type: 'separator'},
                        {text: 'RANGE: ', type: 'normal'},
                        {text: ranges[me.device.data.zoom - level_max],
                         type: 'selected|end-of-line',
                         choices: ranges,
                         level_max: level_max,
                         callback: func (id, selected) {
                             me.device.data.zoom = vecindex(me.device.windows.state[id].objects[selected].choices,
                                                            me.device.windows.state[id].objects[selected].text)
                                                   + me.device.windows.state[id].objects[selected].level_max;
                             me.device.map.changeZoom();
                             me.device.map.update();
                         }
                        },
                        {text: 'ORIENTATION', type: 'normal'},
                        {text: (func foreach (var o; orientation) if (find(me.device.data.orientation.text, o) > -1) return o;)(),
                         type: 'editable|end-of-line',
                         choices: orientation,
                         callback: func (id, selected) {
                             var o = me.device.windows.state[id].objects[selected].text;
                             o = substr(o, 2);
                             o = substr(o, 0, size(o) - 2);
                             o = string.trim(o);
                             me.device.data.orientation.text = o;
                             me.device.map.update();
                         }
                        },
                    ]
                );
            me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
            me.device.knobs.FmsInner = me.device.knobs.MenuSettings;
            me.device.buttons.CLR = me.device.buttons.MapMenu;
            me.device.buttons.ENT = me.device.buttons.ValidateTMRREF;
        }
        else {
            me.device.buttons.ENT = func;
            me.device.buttons.CLR = func;
            me.device.knobs.FmsInner = func;
            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
            me.device.windows.del(menu_label);
        }
    },

    GlobalParams: func (a) {
        if (a == 1)
            return;
        var windowId = 'GLOBAL SETTINGS';
        var obj_infos = [
            {text: 'DISPLAY', type: 'title'},
            {type: 'separator'},
            {text: 'Brightness: ', type: 'normal'},
            {text: sprintf( '% 3u %%', zkv.getValue('display-brightness-norm') * 100 / 0.7),
                type: 'selected immediate end-of-line',
                format: ' % 3u %% ',
                range: {max: 100, min: 0},
                callback: func (id, selected) {
                    var b = num(string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == `%` or c == ` `));
                    zkv.setDoubleValue('display-brightness-norm', b * 0.7 / 100);
                },
            },
            {text: 'Light    : ', type: 'normal'},
            {text: '  0 >',
                type: 'editable|immediate|end-of-line',
                choices: ['  0 >', '< 1 >', '< 2 >', '< 3  '],
                callback: func (id, selected) {
                    var l = num(string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`));
                    zkv.setDoubleValue('lightmap', l * 3);
                }
            },
            {text: 'UNITS', type: 'title'},
            {type: 'separator'},
            {text: 'Pressure  :', type: 'normal', scrollgroup: 0},
            {text: data.settings.units.pressure == 'inhg' ? '  inHg >' : '<  hPa  ',
                type: 'editable|end-of-line',
                choices: [ '  inHg >', '<  hPa  '],
                scrollgroup: 0,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'inHg')
                        data.settings.units.pressure = 'inhg';
                    else
                        data.settings.units.pressure = 'hpa';
                    zkv.getNode('save/pressure', 1).setValue(data.settings.units.pressure);
                    me.device.display.updateBARO();
                }
            },
            {text: 'Altitude  :', type: 'normal', scrollgroup: 1},
            {text: units.altitude.from_ft == 1 ? '   feet  >' : '< meters  ',
                type: 'editable|end-of-line',
                choices: [ '   feet  >', '< meters  ' ],
                scrollgroup: 1,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'feet') {
                        data.settings.units.altitude = 'ft';
                        units.altitude.from_ft = 1;
                        units.altitude.from_m  = M2FT;
                    }
                    else {
                        data.settings.units.altitude = 'm';
                        units.altitude.from_ft = FT2M;
                        units.altitude.from_m  = 1;
                    }
                    foreach (var from; keys(units.altitude))
                        zkv.getNode('save/altitude', 1).setDoubleValue(from, units.altitude[from]);

                }
            },
            {text: 'Distance  :', type: 'normal', scrollgroup: 2},
            {text: units.distance.from_nm == 1 ? '  NM >' : '< km  ',
                type: 'editable|end-of-line',
                choices: ['  NM >', '< km  '],
                scrollgroup: 2,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'NM') {
                        data.settings.units.distance = 'nm';
                        units.distance.from_nm = 1;
                        units.distance.from_m  = M2NM * 1000;
                    }
                    else {
                        data.settings.units.distance = 'km';
                        units.distance.from_nm = NM2M / 1000;
                        units.distance.from_m  = 0.001;
                    }
                    foreach (var from; keys(units.distance))
                        zkv.getNode('save/distance', 1).setDoubleValue(from, units.distance[from]);
                }
            },
            {text: 'Speed     :', type: 'normal', scrollgroup: 3},
            {text: units.speed.from_kt == 1 ? '  knots  >' : '<  km/h   ',
                type: 'editable|end-of-line',
                choices: [ '  knots  >', '<  km/h   ' ],
                scrollgroup: 3,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'knots') {
                        data.settings.units.altitude = 'kt';
                        units.speed.from_kt  = 1;
                        units.speed.from_kmh = MPS2KT / 3.6;
                    }
                    else {
                        data.settings.units.altitude = 'kmh';
                        units.speed.from_kt  = KT2MPS * 3.6;
                        units.speed.from_kmh = 1;
                    }
                    foreach (var from; keys(units.speed))
                        zkv.getNode('save/speed', 1).setDoubleValue(from, units.speed[from]);
                    foreach (var v; keys(data.Vspeeds))
                        data.Vspeeds[v] *= units.speed.from_kt;
                }
            },
            {text: 'Vert. Spd :', type: 'normal', scrollgroup: 4},
            {text: units.vspeed.from_fpm == 1 ? '  ft/min >' : '<  m/min  ',
                type: 'editable|end-of-line',
                choices: [ '  ft/min >', '<  m/min  ' ],
                scrollgroup: 4,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'ft/min') {
                        data.settings.units.altitude = 'fpm';
                        units.vspeed.from_fpm = 1;
                        units.vspeed.from_mpm = M2FT;
                    }
                    else {
                        data.settings.units.altitude = 'mpm';
                        units.vspeed.from_fpm = FT2M;
                        units.vspeed.from_mpm = 1;
                    }
                    foreach (var from; keys(units.vspeed))
                        zkv.getNode('save/vspeed', 1).setDoubleValue(from, units.vspeed[from]);
                }
            },
            {text: 'Temperat. :', type: 'normal', scrollgroup: 5},
            {text: units.temperature.from_C(0) ? '  F >' : '< °C  ',
                type: 'editable|end-of-line',
                choices: [ '  F >', '< °C  ' ],
                scrollgroup: 5,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == '°C') {
                        units.temperature.from_C = func (c) return c;
                        units.temperature.from_F = func (f) return (f - 32) / 1.8;
                        zkv.getNode('save/temperature', 1).setValue('from_C', 'units.temperature.from_C = func (c) return c;');
                        zkv.getNode('save/temperature', 1).setValue('from_F', 'units.temperature.from_F = func (f) return (f - 32) / 1.8;');
                    }
                    else {
                        units.temperature.from_C = func (c) return c * 1.8 + 32;
                        units.temperature.from_F = func (f) return f;
                        zkv.getNode('save/temperature', 1).setValue('from_C', 'units.temperature.from_C = func (c) return c * 1.8 + 32;');
                        zkv.getNode('save/temperature', 1).setValue('from_F', 'units.temperature.from_F = func (f) return f;');
                    }
                }
            },
            {text: 'Volume    :', type: 'normal', scrollgroup: 6},
            {text: units.volume.from_l == 1 ? '   l  >' : (units.volume.from_gal == 1 ?  '< gal  ' : '<  m3 >'),
                type: 'editable|end-of-line',
                choices: ['   l  >', '<  m3 >', '< gal  '],
                scrollgroup: 6,
                callback: func (id, selected) {
                    var u = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                    if (u == 'l') {
                        units.volume.from_l   = 1;
                        units.volume.from_gal = 3.78541178;
                        units.volume.from_m3  = 1000;
                    }
                    elsif (u == 'm3') {
                        units.volume.from_l   = 0.001;
                        units.volume.from_gal = 1 / 0.26417 / 1000;
                        units.volume.from_m3  = 1;
                    }
                    else {
                        units.volume.from_l   = 0.26417;
                        units.volume.from_gal = 1;
                        units.volume.from_m3  = units.volume.from_l / 1000;
                    }
                    foreach (var from; keys(units.volume))
                        zkv.getNode('save/volume', 1).setDoubleValue(from, units.volume[from]);
                }
            },
            {type: 'separator'},
            {text: 'TIME REF: ', type: 'normal'},
            {text: data.settings.time.actual,
                type: 'editable|end-of-line',
                choices: [ '  GMT >', '< LCL >', '< UTC >', '< RL   ' ],
                callback: func (id, selected) {
                    data.settings.time.actual = me.device.windows.state[id].objects[selected].text;
                    data.settings.time.label = string.trim(me.device.windows.state[id].objects[selected].text, 0, func (c) c == ` ` or c == `<` or c == `>`);
                }
            },
        ];
        me.device.windows.draw( windowId, {autogeom: 1}, obj_infos, {lines: 3, columns: 2});
        me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
        me.device.knobs.FmsInner = me.device.knobs.MenuSettings;
        me.device.buttons.ENT = func (a = 0) {
            if (a) return;
            me.device.buttons.ValidateTMRREF();
        }
        me.device.buttons.CLR = func {
            me.device.windows.del(windowId);
            me.device.knobs.FmsOuter = func;
            me.device.knobs.FmsInner = func;
            foreach (var b; ['ENT', 'CLR'])
                me.device.buttons[b] = func;
            me.device.buttons.MENU = me.device.buttons.GlobalParams;
            if (zkv.getNode('save') != nil) {
                fgcommand('savexml', props.Node.new({ filename: getprop('/sim/fg-home') ~'/aircraft-data/zkv1000.xml',
                      sourcenode: zkv.getNode('_save').getPath() }));
                zkv.getNode('_save').remove();
                zkv.getNode('save').remove();
            }
        }
        me.device.buttons.MENU = me.device.buttons.CLR;
    },

    DirectTo : func (a) {
        if (a) return;
        if (me.device.windows.selected == nil) return;
        var (id, selected) = split('-', me.device.windows.selected);
        var state = me.device.windows.state[id];
        selected += state.scroll.offset;
        var scratch = props.globals.getNode('/instrumentation/gps/scratch');
        if (contains(state.objects[selected], 'dto')) {
            scratch.setValue('longitude-deg', state.objects[selected].dto.lon);
            scratch.setValue('latitude-deg', state.objects[selected].dto.lat);
            scratch.setValue('ident', state.objects[selected].dto.id);
            scratch.setValue('altitude-ft', data.alt);
            setprop('/instrumentation/gps/command', 'direct');
        }
    },

    FPL : func (a) {
        if (a or data.fpSize == 0 or me.device.windows.selected != '')
            return;
        var windowId = 'FLIGHTPLAN LIST';
        var flightplan = props.globals.getNode('/autopilot/route-manager');
        var route = flightplan.getNode('route');
        var obj_infos = [];
        var firstEntry = 1;
        var current = flightplan.getValue('current-wp');
        for (var i = current; i <= data.fpSize; i += 1) {
            var wp = route.getChild('wp', i);
            append(obj_infos, {
                type: (firstEntry ? 'selected' : 'editable'),
                text: sprintf('#%2d %-10s', data.fpSize - i, wp.getValue('id')),
                scrollgroup: i - current,
                dto: {
                    lon: wp.getValue('lon'),
                    lat: wp.getValue('lat'),
                    id:  wp.getValue('id')
                },
            });
            append(obj_infos, {
                type: 'normal|end-of-line',
                scrollgroup: i - current,
                text: sprintf(' %3dNM %3d°',
                              math.round(wp.getValue('leg-distance-nm')),
                              math.round(wp.getValue('leg-bearing-true-deg')))
            });
            firstEntry = 0;
        }
        me.device.windows.draw(windowId, obj_infos, {lines: 6, columns: 2});
        me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
        me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
        me.device.buttons.ENT = func;
        me.device.buttons.MENU = func;
        me.device.buttons.CLR = func {
            me.device.windows.del(windowId);
            if (me.device.role == 'PFD') {
                me.device.knobs.FmsOuter = func;
                me.device.knobs.FmsInner = func;
                me.device.buttons.MENU   = me.device.buttons.GlobalParams;
            }
            else {
                me.device.knobs.FmsInner = func;
                me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
                me.device.buttons.MENU   = me.device.buttons.MapMenu;
            }
            foreach (var b; ['ENT', 'CLR'])
                me.device.buttons[b] = func;
        }
        me.device.buttons.MENU = me.device.buttons.CLR;
    },

    MENU : void,
    PROC : void,
    CLR : void,
    ENT : void,
    FMS : void,
};
