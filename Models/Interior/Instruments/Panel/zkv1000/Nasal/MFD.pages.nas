# vim: set foldmethod=marker foldmarker={{{,}}} :
displayClass.MFD = {
    AUX: {
        'TRIP PLANNING' : func {
            me.device.buttons.CLR = func {
                me.device.buttons.CLR = func;
                fgcommand('dialog-close', { 'dialog-name' : 'route-manager' });
                fgcommand('dialog-close', { 'dialog-name' : 'map' });
            };
            fgcommand('dialog-show', { 'dialog-name' : 'map' });
            fgcommand('dialog-show', { 'dialog-name' : 'route-manager' });
        },
        'NAVBOX ITEMS SELECTION' : func {
            var obj_infos = [
                {text: 'NAV BOX DATA FIELDS', type: 'title'},
                {type: 'separator'},
                {text: 'DATA FIELD NUMBER', type: 'normal'},
                {text: '  1 >', type: 'selected|end-of-line', choices: ['  1 >', '< 2 >', '< 3 >', '< 4  ']},
            ];
            foreach (var item; keys(me.device.display.navbox)) {
                if (item == 'LEG') # LEG only displayed on PFD navigation box
                    continue;
                append(obj_infos, {
                    text: sprintf('%-3s ', item),
                    type: 'editable',
                    callback: func (id, selected) {
                        var field = string.trim(me.device.windows.state[id].objects[3].text,
                                                0,
                                                func (c) c == `<` or c == `>` or c == ` `);
                        me.device.display.screenElements['DATA-FIELD' ~ field ~ '-ID-text']
                            .setText(string.trim(me.device.windows.state[id].objects[selected].text, 1));
                    }
                });
                append(obj_infos, {
                    text: sprintf('(%s)', me.device.display.navbox[item][1]),
                    type: 'normal|end-of-line',
                });
            }
            var windowId = 'SYSTEM SETUP';
            me.device.windows.draw( windowId, obj_infos );
            me.device.buttons.CLR = func {
                me.device.windows.del(windowId);
                me.device.buttons.ENT = func;
                me.device.buttons.CLR = func;
                me.device.knobs.FmsInner = func;
                me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
            }
            me.device.knobs.FmsInner = me.device.knobs.MenuSettings;
            me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
            me.device.buttons.ENT = me.device.buttons.ValidateTMRREF;
        },
    },
    FPL : {
        'ACTIVE FLIGHT PLAN' : func {
            me.device.windows.del(id);
            var flightplan = props.globals.getNode('/autopilot/route-manager');
            var route = flightplan.getNode('route');
            var obj_infos = [
                {text: 'ACTIVE FLIGTHPLAN', type: 'title'},
                {type: 'separator'},
            ];
            if (route.getValue('num')) {
                append(obj_infos, {text: sprintf('DEP: %s', flightplan.getNode('departure').getValue('airport')), type: 'normal|end-of-line'});
                append(obj_infos, {text: sprintf('ARR: %s', flightplan.getNode('destination').getValue('airport')), type: 'normal|end-of-line'});
                append(obj_infos, {text: sprintf('DIS: %dnm', flightplan.getValue('total-distance')), type: 'normal|end-of-line'});
                append(obj_infos, {type: 'separator'});
                var current_wp = flightplan.getValue('current-wp');
                var firstEntry = 1;
                for (var n = 1; n < route.getValue('num'); n += 1) {
                    var wp = route.getChild('wp', n);
                    append(obj_infos, {text: sprintf('%1s %-7s  %3d°  %3dnm %s',
                                                    n == current_wp ? utf8.chstr(9658) : ' ',
                                                    wp.getValue('id'),
                                                    math.round(wp.getValue('leg-bearing-true-deg')),
                                                    math.round(wp.getValue('leg-distance-nm')),
                                                    wp.getValue('altitude-ft') > -100 ? ' ' ~ wp.getValue('altitude-ft') ~ 'ft': ''
                                            ),
                                       type: (firstEntry ? 'selected' : 'editable') ~ '|end-of-line',
                                       scrollgroup: n - 1
                    });
                    firstEntry = 0;
                }
            }
            else {
                append(obj_infos, {text: 'NO FP LOADED', type: 'normal|end-of-line'});
            }
            var windowId = 'ACTIVE FLIGTH PLAN';
            me.device.windows.draw( windowId, obj_infos, {lines: 6, columns: 1} );
            me.device.buttons.CLR = func {
                me.device.windows.del(windowId);
                me.device.buttons.ENT = func;
                me.device.buttons.CLR = func;
                me.device.knobs.FmsInner = func;
                me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
            }
            me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
            me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
        },
        'FLIGHT PLAN CATALOG': func {
            var obj_infos = [];
            var departure = getprop('/sim/airport/closest-airport-id');
            append(obj_infos, {text: departure ~ ' STORED FLIGHT PLANS', type: 'title'});
            append(obj_infos, {type: 'separator'});
            var idx = 0;
            foreach (var file; directory(data.flightplans)) {
                var stat = io.stat(data.flightplans ~ '/' ~ file);
                if (stat[11] == 'reg' or stat[11] == 'lnk') {
                    var xml = call(func (path) io.readxml(path), [ data.flightplans ~ '/' ~ file ], me, {}, var errors = []);
                    if (size(errors))
                        continue;
                    if (xml.getNode('/PropertyList/flight-rules')        != nil
                    and xml.getNode('/PropertyList/flight-type')         != nil
                    and xml.getNode('/PropertyList/departure/airport')   != nil
                    and xml.getNode('/PropertyList/destination/airport') != nil
                    and xml.getNode('/PropertyList/departure').getValue('airport') == departure) {
                        append(obj_infos, {
                            text: sprintf('RWY %s to %s%s',
                                xml.getNode('/PropertyList/departure').getValue('runway'),
                                xml.getNode('/PropertyList/destination').getValue('airport'),
                                xml.getNode('/PropertyList/destination').getValue('runway') != nil ?
                                '-' ~ xml.getNode('/PropertyList/destination').getValue('runway') : ''),
                            type: (idx ? 'editable' : 'selected') ~ '|end-of-line',
                            scrollgroup: idx,
                            _file: data.flightplans ~ '/' ~ file
                        });
                        var first_wp = last_wp = 0;
                        forindex (var wp; xml.getNode('/PropertyList/route').getChildren('wp')) {
                            var ident = xml.getNode('/PropertyList/route').getChild('wp', wp).getValue('ident');
                            if (string.match(ident, 'DEP-[0-9]*')
                            or string.match(ident, sprintf('%s', xml.getNode('/PropertyList/departure').getValue('runway')))
                            or string.match(ident, sprintf('%s-[0-9]*', xml.getNode('/PropertyList/departure').getValue('runway')))) {
                                continue;
                            }
                            if (!first_wp) {
                                first_wp = wp;
                                continue;
                            }
                            if (string.match(ident, 'APP-[0-9]*')
                            or string.match(ident, sprintf('%s', xml.getNode('/PropertyList/destination').getValue('runway')))
                            or string.match(ident, sprintf('%s', xml.getNode('/PropertyList/destination').getValue('airport')))
                            or string.match(ident, sprintf('%s-[0-9]*', xml.getNode('/PropertyList/destination').getValue('runway')))) {
                                last_wp = wp - 1;
                                break;
                            }
                        }
                        if (last_wp - first_wp > 2)
                            append(obj_infos, {
                                text: sprintf(' %s via %s and %s',
                                    utf8.chstr(9658),
                                    xml.getNode('/PropertyList/route').getChild('wp', first_wp + int((last_wp - first_wp)/3)).getValue('ident'),
                                    xml.getNode('/PropertyList/route').getChild('wp', last_wp  - int((last_wp - first_wp)/3)).getValue('ident')),
                                type: 'normal|end-of-line',
                                scrollgroup: idx
                            });
                        else
                            append(obj_infos, {
                                text: sprintf(' %s direct', utf8.chstr(9658)),
                                type: 'normal|end-of-line',
                                scrollgroup: idx
                            });
                        idx += 1;
                    }
                }
            }
            if (!idx)
                append(obj_infos, { text: 'no flightplan found', type: 'normal|end-of-line'});

            var windowId = 'FLIGTH PLAN CATALOG';
            me.device.windows.draw( windowId, obj_infos, {lines: 6, columns: 1, rows: 2} );
            me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
            me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
            me.device.buttons.CLR = func {
                me.device.windows.del(windowId);
                me.device.buttons.ENT = func;
                me.device.buttons.CLR = func;
                me.device.knobs.FmsInner = func;
                me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
            }
            me.device.buttons.ENT = func (a = 0) {
                a or return;
                var (id, selected) = split('-', me.device.windows.selected);
                var file = me.device.windows.state[id].objects[selected]._file;
                me.device.buttons.CLR();
                data.flightplan = flightplan(file);
                data.flightplan.activate();
                fgcommand("activate-flightplan", props.Node.new({"activate": 1}));
            }
        },
    },
    NRST : {
        'NEAREST AIRPORTS': func {
            var airports = findAirportsWithinRange(99.99);
            var obj_infos = [
                {text: size(airports) ~ ' NEAREST AIRPORTS', type: 'title'},
                {type: 'separator'},
            ];
            var name_max_length = 0;
            forindex (var idx; airports) {
                var info = airportinfo(airports[idx].id);
                var (course, distance) = courseAndDistance(info);
                var name = sprintf('%s (%s)', airports[idx].id, airports[idx].name);
                if (size(name) > name_max_length)
                    name_max_length = size(name);

                append(obj_infos, {
                        text: name,
                        type: (idx ? 'editable' : 'selected') ~ '|immediate|end-of-line',
                        scrollgroup: idx,
                    }
                );
                append(obj_infos, {
                        text: sprintf(' %s DST %2dNM CRS %03d°', utf8.chstr(9658), distance, course),
                        type: 'normal|end-of-line',
                        scrollgroup: idx
                    }
                );
            }
            var windowId = 'NEAREST AIRPORTS';
            me.device.windows.draw( windowId, obj_infos, {lines: 4, columns: 1, rows: 2} );
            me.device.buttons.CLR = func {
                me.device.windows.del(windowId);
                me.device.buttons.ENT = func;
                me.device.buttons.CLR = func;
                me.device.knobs.FmsInner = func;
                me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
            }
            me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
            me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
            me.device.buttons.ENT = func (a = 0) {
                if (a) return;
                var (id, selected) = split('-', me.device.windows.selected);
                var state = me.device.windows.state[id];
                var (airport_id, _) = split(" ", obj_infos[selected + state.scroll.offset].text);
                me.device.windows.del(windowId);
                call(me.device.display.MFD._ShowAirportInfo, [airport_id], me);
            };
        },
        'NEAREST INTERSECTIONS': func {
            call(me.device.display.MFD._NearestNavaids, ['fix'], me);
        },
        'NEAREST NDB': func {
            call(me.device.display.MFD._NearestNavaids, ['ndb'], me);
        },
        'NEAREST VOR': func {
            call(me.device.display.MFD._NearestNavaids, ['vor'], me);
        },
    },
    _NearestNavaids: func (navaid_type) {
        var navaids = findNavaidsWithinRange(99.99, navaid_type);
        var obj_infos = [
            {text: size(navaids) ~ ' NEAREST ' ~ string.uc(navaid_type), type: 'title'},
            {type: 'separator'},
        ];
        var idx = 0;
        foreach (var navaid; navaids) {
            var (course, distance) = courseAndDistance(navaid);
            var name = navaid.id ~ ' (' ~ navaid.name ~ ')';

            append(obj_infos, {
                    text: navaid.id ~ ' (' ~ navaid.name ~ ')',
                    type: (idx ? 'editable' : 'selected') ~ '|immediate|end-of-line',
                    scrollgroup: idx,
                }
            );
            append(obj_infos, {
                    text: sprintf(' %s DST %2dNM CRS %03d°', utf8.chstr(9658), distance, course),
                    type: 'normal|end-of-line',
                    scrollgroup: idx
                }
            );
            idx += 1;
        }
        append(obj_infos, {type: 'separator'});
        var windowId = obj_infos[0].text;
        me.device.windows.draw( windowId, obj_infos, {lines: 4, columns: 1, rows: 2} );
        me.device.buttons.CLR = func {
            me.device.windows.del(windowId);
            me.device.buttons.ENT = func;
            me.device.buttons.CLR = func;
            me.device.knobs.FmsInner = func;
            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
        }
        me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
        me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
        me.device.buttons.ENT = func (a = 0) {
            if (a) return;
            var (id, selected) = split('-', me.device.windows.selected);
            var state = me.device.windows.state[id];
            var (navaid_id, _) = split(" ", obj_infos[selected + state.scroll.offset].text);
            me.device.windows.del(windowId);
            if (navaid_type == 'airport')
                call(me.device.display.MFD._ShowAirportInfo, [navaid_id], me);
            else
                call(me.device.display.MFD._ShowNavaidInfo, [navaid_id, navaid_type], me);
        };
    },
    _ShowNavaidInfo: func (navaid_id, navaid_type) {
        var info = findNavaidsByID(navaid_id, navaid_type);
        if (size(info) == 0) return;
        me.device.knobs.FmsInner = func;
        me.device.knobs.FmsOuter = func;
        me.device.buttons.ENT    = func;
        var obj_infos = [
            {text: info[0].id ~ ' INFORMATION', type: 'title'},
            {type: 'separator'},
            {text: 'ID    ' ~ info[0].id, type: 'normal|end-of-line'},
            {text: 'NAME  ' ~ info[0].name, type: 'normal|end-of-line'},
            {text: 'TYPE  ' ~ info[0].type, type: 'normal|end-of-line'},
            {text: sprintf('LON   %.3f %s', abs(info[0].lon), info[0].lon > 0 ? 'E' : 'W'), type: 'normal|end-of-line'},
            {text: sprintf('LAT   %.3f %s', abs(info[0].lat), info[0].lat > 0 ? 'N' : 'S'), type: 'normal|end-of-line'},
        ];
        call(func {return info[0].range }, [], nil, nil, var errors = []);
        if (!size(errors))
            append(obj_infos, {text: sprintf('RANGE %i NM', info[0].range * 1.852), type: 'normal|end-of-line'});
        call(func {return info[0].frequency }, [], nil, nil, var errors = []);
        if (!size(errors))
            append(obj_infos, {text: sprintf('FREQ  %.2f kHz', info[0].frequency / 100), type: 'normal|end-of-line'});
        var lines = size(obj_infos);
        var windowId = 'NAVAID INFORMATIONS';
        me.device.windows.draw( windowId, obj_infos );
        me.device.buttons.CLR = func {
            me.device.windows.del(windowId);
            me.device.buttons.ENT = func;
            me.device.buttons.CLR = func;
            me.device.knobs.FmsInner = func;
            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
        }
    },
    _ShowAirportInfo: func (airport_id) {
        me.device.knobs.FmsInner = func;
        me.device.knobs.FmsOuter = func;
        me.device.buttons.ENT    = func;
        var info = airportinfo(airport_id);
        var obj_infos = [
            {text: airport_id ~ ' INFORMATION', type: 'title'},
            {type: 'separator'},
            {text: sprintf('ELEVATION %.0d FT', info.elevation * 3.28), type: 'normal|end-of-line'},
            {text: sprintf('LON: %.3f %s', abs(info.lon), info.lon > 0 ? 'E' : 'W'), type: 'normal|end-of-line'},
            {text: sprintf('LAT: %.3f %s', abs(info.lat), info.lat > 0 ? 'N' : 'S'), type: 'normal|end-of-line'},
            {type: 'separator'},
            {text: 'RUNWAYS', type: 'title'},
        ];
        foreach (var rwy; sort(keys(info.runways), string.icmp)) {
            var rwyInfo = sprintf("%-3s %4.0dm %3.0d°",
                                  rwy,
                                  info.runways[rwy].length,
                                  info.runways[rwy].heading);
            if (info.runways[rwy].ils != nil) {
                rwyInfo = sprintf("%s %3.3f Mhz", rwyInfo, info.runways[rwy].ils.frequency / 100);
            }
            append(obj_infos, {text: rwyInfo, type: 'normal|end-of-line'});
        }
        var sep = 2; # to count separators, already two printed
        if (size(info.comms()) > 0) {
# TODO: find nearby freqs if none found for airport
            append(obj_infos, {type: 'separator'}); sep += 1;
            append(obj_infos, {text: 'COMMS FREQUENCIES', type: 'title'});
            var freqs = {};
            var comms = info.comms();
            foreach (var c; comms)
                freqs[c.ident] = sprintf("%.3f", c.frequency);

            foreach (var f; sort(keys(freqs), string.icmp))
                append(obj_infos, {text: sprintf('%-15s %.3f', f, freqs[f]), type: 'normal|end-of-line'});
        }
        var lines = size(obj_infos) - sep; # minus the separators
        var windowId = 'AIRPORT INFORMATIONS';
        me.device.windows.draw( windowId, obj_infos );
        me.device.buttons.CLR = func {
            me.device.windows.del(windowId);
            me.device.buttons.ENT = func;
            me.device.buttons.CLR = func;
            me.device.knobs.FmsInner = func;
            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
        }
    },
};

displayClass.setMFDPages = func {
    me.device.data['page selection'] = [
# list of pages, by group {{{
        {
            name: 'MAP',
            objects: [
                {text: 'NAVIGATION MAP'},
                {text: 'TRAFFIC MAP'},
                {text: 'STORMSCOPE'},
                {text: 'WEATHER DATA LINK'},
                {text: 'TAWS-B'},
            ],
        },
        {
            name: 'WPT',
            objects: [
                {text: 'AIRPORT INFORMATION'},
                {text: 'AIRPORT DIRECTORY'},
                {text: 'DEPARTURE INFORMATION'},
                {text: 'ARRIVAL INFORMATION'},
                {text: 'APPROACH INFORMATION'},
                {text: 'WEATHER INFORMATION'},
                {text: 'INTERSECTION INFORMATION'},
                {text: 'NDB INFORMATION'},
                {text: 'VOR INFORMATION'},
                {text: 'USER WAYPOINT INFORMATION'},
            ],
        },
        {
            name: 'AUX',
            objects: [
                {text: 'TRIP PLANNING'},
                {text: 'UTILITY'},
                {text: 'GPS STATUS'},
                {text: 'NAVBOX ITEMS SELECTION'},
            ],
        },
        {
            name: 'FPL',
            objects: [
                {text: 'ACTIVE FLIGHT PLAN'},
                {text: 'WIDE VIEW, NARROW VIEW'},
                {text: 'FLIGHT PLAN CATALOG'},
            ],
        },
        {
            name: 'PROC',
            objects: [
                {text: 'DEPARTURE LOADING'},
                {text: 'ARRIVAL LOADING'},
                {text: 'APPROACH LOADING'},
            ],
        },
        {
            name: 'NRST',
            objects: [
                {text: 'NEAREST AIRPORTS'},
                {text: 'NEAREST INTERSECTIONS'},
                {text: 'NEAREST NDB'},
                {text: 'NEAREST VOR'},
                {text: 'NEAREST USER WAYPOINTS'},
                {text: 'NEAREST FREQUENCIES'},
                {text: 'NEAREST AIRSPACES'},
            ],
        },
# }}}
    ];

    foreach (var g; me.device.data['page selection']) {
        var obj_s = size(g.objects);
        # build specific geometry per page, depending of number of sub-pages
        g.geometry = {x: 720, y: 758 - ((obj_s + 3) * 24), w: 300, l: obj_s + 1, sep: 1};
        # complete the hash with reccurrent elements type and callback
        var firstEntry = 1;
        foreach (var o; g.objects) {
            if (contains(me.MFD, g.name) and contains(me.MFD[g.name], o.text)) {
                o.type = firstEntry ? 'selected' : 'editable';
                o.type ~= '|end-of-line';
                o.callback = me.device.buttons.MFD_page_wrapper;
                firstEntry = 0;
            }
            else
                o.type = 'normal|end-of-line';
        }
    }
    # build the available groups line, at the bottom
    forindex (var g; me.device.data['page selection']) {
        append(me.device.data['page selection'][g].objects, {type: 'separator'});
        for (var i = 0; i < g; i+=1)
            append(me.device.data['page selection'][g].objects,
                {text: me.device.data['page selection'][i].name, type: 'normal'});
        append(me.device.data['page selection'][g].objects,
            {text: me.device.data['page selection'][i].name, type: 'highlighted'});
        for (var i = g+1; i < size(me.device.data['page selection']); i+=1)
            append(me.device.data['page selection'][g].objects,
                {text: me.device.data['page selection'][i].name, type: 'normal'});
    }
    me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
};
