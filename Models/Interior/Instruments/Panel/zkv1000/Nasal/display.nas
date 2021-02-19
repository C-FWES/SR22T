# vim: set foldmethod=marker foldmarker={{{,}}} :
var displayClass = {
    new: func(device) {
# the contructor {{{
        var m = { parents: [ displayClass ] };

        m.display = canvas.new({
                "name"      : device.name,
                "size"      : [1280, 1280],
                "view"      : [1024, 768],
                "mipmapping": 1
        });
        m.display.addPlacement({
                "node": device.data['screen-object'] != nil ? device.data['screen-object'] : "Screen",
                "parent": device.name
            });
        m.display.setColorBackground(0,0,0);
        m.role = device.role;
        m.device = device;
        m.screenElements = {};
        m.screen = m.display
            .createGroup()
            .show();

        m.timers = {};
        # Softkeys revert to the previous level after 45 seconds of inactivity.
        m.softkeys_inactivity_delay = 45;

        var groups = {
            show : [
                'Header',
                'SoftKeysTexts',
                'COMM',
                'NAV',
                'nav-freq-switch',
                'comm-freq-switch',
            ],
            text: [
                'nav1-standby-freq', 'nav1-selected-freq', 'nav1-id',
                'nav2-standby-freq', 'nav2-selected-freq', 'nav2-id',
                'comm1-standby-freq', 'comm1-selected-freq',
                'comm2-standby-freq', 'comm2-selected-freq',
            ],
            hide : [ 'Failures', 'NAV-COMM-Failures' ],
            clip: [ ],
        };

        for (var k = 0; k < 12; k += 1) {
            append(groups.text, sprintf("SoftKey%02i-text", k));
            append(groups.show, sprintf("SoftKey%02i-bg", k));
        }

        if (m.device.role == 'PFD') {
            append(groups.show,
# {{{
                'XPDR-TIME',
                'FlightInstruments',
                'Horizon',
                'bankPointer',
                'VSI',
                'Rose',
                'Heading-bug',
                'PFD-Widgets',
                'Trends',
                'Airspeed-Trend-Indicator',
                'Altitude-Trend-Indicator',
                'OAT',
                'IAS-bg',
                'TAS',
                'GSPD',
                'BARO-bg',
                'SlipSkid',
                'VDI', 'GS-ILS', 'VDI-scale',
# }}}
            );
            append(groups.hide,
# {{{
                'EIS',
                'CDI',
                'OMI', 'MarkerBG', 'MarkerText',
                'NAV1-pointer', 'NAV1-CDI', 'NAV1-FROM', 'NAV1-TO',
                'NAV2-pointer', 'NAV2-CDI', 'NAV2-FROM', 'NAV2-TO',
                'GPS-pointer', 'GPS-CDI', 'GPS-CTI', 'GPS-CTI-diamond', 'GPS-FROM', 'GPS-TO',
                'BRG1-pointer',
                'BRG2-pointer',
                'SelectedHDG-bg',
                'SelectedHDG-bgtext',
                'SelectedHDG-text',
                'SelectedCRS-bg',
                'SelectedCRS-bgtext',
                'SelectedCRS-text',
                'SelectedALT', 'SelectedALT-bug', 'SelectedALT-bg', 'SelectedALT-symbol',
                'TAS',
                'GSPD',
                'WindData',
                'Reversionnary',
                'Annunciation',
                'Comparator',
                'BRG1',
                'BRG2',
                'DME1',
                'PFD-Map-bg',
                'PFD-Multilines',
                'MapOrientation',
                'WindData', 'WindData-OPTN1', 'WindData-OPTN2', 'WindData-OPTN1-HDG', 'WindData-OPTN2-symbol', 'WindData-OPTN2-headwind', 'WindData-OPTN2-crosswind', 'WindData-NODATA',
                'AOA', 'AOA-needle', 'AOA-text', 'AOA-approach',
                'MFD-navbox',
                'Traffic',
                'VDI-type-bg',
# }}}
            );
            append(groups.clip,
# {{{
                'SpeedLint1',
                'SpeedTape',
                'LintAlt',
                'AltLint00011',
                'PitchScale',
# }}}
            );
            append(groups.text,
# {{{
                'SelectedALT-text',
                'TAS-text',
                'GSPD-text',
                'TIME-text', 'TIME-REF-text',
                'OAT-text',
                'VSIText',
                'Speed110',
                'Alt11100',
                'HDG-text',
                'BARO-text',
                'CDI-SRC-text', 'CDI-GPS-ANN-text', 'CDI-GPS-XTK-text',
                'BRG1-pointer', 'BRG1-SRC-text', 'BRG1-DST-text', 'BRG1-WPID-text',
                'BRG2-pointer', 'BRG2-SRC-text', 'BRG2-DST-text', 'BRG2-WPID-text',
                'WindData-OPTN1-HDG-text', 'WindData-OPTN1-SPD-text',
                'WindData-OPTN2-crosswind-text', 'WindData-OPTN2-headwind-text',
                'XPDR-MODE-text', 'XPDR-DIGIT-3-text', 'XPDR-DIGIT-2-text', 'XPDR-DIGIT-1-text', 'XPDR-DIGIT-0-text',
                'ETE', 'ETE-text', 'DIS', 'DIS-text', 'LEG-text',
                'LATMOD-Armed-text', 'LATMOD-Active-text',
                'AP-Status-text', 'YD-Status-text',
                'VERMOD-Active-text', 'VERMOD-Armed-text', 'VERMOD-Reference-text',
                'AltBigC', 'AltSmallC'
# }}}
            );
            for (var place = 1; place <= 6; place +=1) {
                append(groups.text,
                    'AltBigU' ~ place,
                    'AltSmallU' ~ place,
                    'AltBigD' ~ place,
                    'AltSmallD' ~ place
                );
            }
            canvas.parsesvg(m.screen, data.zkv1000_reldir ~ 'Models/PFD.svg');
        }
        else {
            var eis_file = eis.getValue('type');
            if (eis_file == nil)
                eis_file = eis.getValue('file');

            if (eis_file != nil) {
                if (find('/', eis_file) == -1)
                    eis_file = data.zkv1000_dir ~ 'Nasal/EIS/' ~ eis_file ~ '.nas';
                elsif (split('/', eis_file)[0] == 'Aircraft') {
                    var path = split('/', eis_file);
                    if (getprop('/sim/fg-aircraft') != nil) {
                        foreach (var fg_aircraft; props.globals.getNode('/sim').getChildren('fg-aircraft')) {
                            eis_file = fg_aircraft.getValue();
                            for (var i = 1; i < size(path); i += 1)
                                eis_file ~= '/' ~ path[i];
                            if (io.stat(eis_file) != nil)
                                break;
                        }
                    }
                    else
                        eis_file = getprop('/sim/fg-root') ~ '/' ~ eis_file;
                }
            }
            else
                eis_file = data.zkv1000_dir ~ 'Nasal/EIS/none.nas';

            if (io.stat(eis_file) == nil
            and print(eis_file ~ ' not found'))
                eis_file = data.zkv1000_dir ~ 'Nasal/EIS/none.nas';
            io.load_nasal(eis_file, 'zkv1000');

            if (contains(m.parents[0], 'showEIS'))
                m.showEIS(groups);

            append(groups.hide, 'PFD-navbox');
            for (var i=1; i <= 4; i+=1)
                foreach (var t; ['ID', 'VAL'])
                    append(groups.text, 'DATA-FIELD' ~ i ~ '-' ~ t ~ '-text');
        }

        canvas.parsesvg(m.screen, data.zkv1000_reldir ~ 'Models/softkeys.svg');
        canvas.parsesvg(m.screen, data.zkv1000_reldir ~ 'Models/header-nav-comm.svg');

        m.loadGroup(groups);

        if (m.device.role == 'PFD') {
            m.device.data.aoa = 0;
            m.device.data['aoa-auto'] = 0;
            m.device.data.mapclip = {
                top: math.ceil(m.screenElements['PFD-Map-bg'].getTransformedBounds()[1]) - 1,
                right: math.ceil(m.screenElements['PFD-Map-bg'].getTransformedBounds()[2]) - 1,
                bottom: math.ceil(m.screenElements['PFD-Map-bg'].getTransformedBounds()[3]) - 1,
                left: math.ceil(m.screenElements['PFD-Map-bg'].getTransformedBounds()[0]) - 1,
            };
        }
        else {
            m.device.data.mapclip = {
                top: math.ceil(m.screenElements['Header'].getTransformedBounds()[3]),
                right: m.display.get('view[0]'),
                bottom: math.ceil(m.screenElements['SoftKeysTexts'].getTransformedBounds()[1]),
                left: contains(m.screenElements, 'EIS') ? math.ceil(m.screenElements['EIS'].getTransformedBounds()[2]) : 0,
            };
        }

        m.navbox = {
# {{{ the data to show info in navbox
            DTK: [func {
                var dtk = getprop('/instrumentation/gps/wp/wp[1]/desired-course-deg');
                if (dtk == nil)
                    return '---°';
                else
                    return sprintf('%03i°', dtk);
            }, 'Desired Track'],
            ETE: [func {
                if (data.fpSize == 0) return '--:--';
                var eta = getprop('/autopilot/route-manager/wp/eta');
                return sprintf('%5s', eta != nil ? eta : '--:--');
            }, 'Estimated Time Enroute'],
            TDR: [func {
                var unit = units.distance.from_nm == 1 ? 'NM' : 'km';
                if (data.fpSize == 0) return '---' ~ unit;
                var dist = getprop('/autopilot/route-manager/distance-remaining-nm') * units.distance.from_nm;
                if (dist != nil)
                    return sprintf(dist < 100 ? '%2.1f%s' : '%3i%s', dist, unit);
                else
                    return '---' ~ unit;
            }, 'Total Distance Remaining'],
            DIS: [func {
                var unit = units.distance.from_nm == 1 ? 'NM' : 'km';
                if (data.fpSize == 0) return '---' ~ unit;
                var dist = getprop('/autopilot/route-manager/wp/dist') * units.distance.from_nm;
                if (dist != nil)
                    return sprintf(dist < 100 ? '%2.1f%s' : '%3i%s', dist, unit);
                else
                    return '---' ~ unit;
            }, 'Distance remaining'],
            LEG: [func {
                if (data.fpSize == 0) return '';
                var route = m.device.map.layers.route;
                var wp = route.flightPlan[route.currentLeg.index];
                return sprintf(' %s %s %s', wp[0].name, utf8.chstr(9658), wp[1].name);
            }, ''], # not listed in MFD menu, on PFD only the leg is shown not the item
            LDG: [func {
                var eteSeconds = getprop('/autopilot/route-manager/ete');
                var eteHours = math.floor(eteSeconds / 3600);
                var eteMinutes = int((eteSeconds - (eteHours * 3600)) / 60);
                return sprintf(eteHours > 99 ? '--:--' : '%02i:%02i', eteHours, eteMinutes);
            }, 'ETA at Final Destination'],
            END: [func {
                var total_fuel = getprop('/consumables/fuel/total-fuel-gals');
                var gs = getprop('/velocities/groundspeed-kt');
                var consumption = 0;
                foreach(var engine; props.globals.getNode('/engines').getChildren('engine')) {
                    var ec = engine.getValue('fuel-flow-gph');
                    consumption += ec != nil ? ec : 0;
                }
                var unit = units.distance.from_nm == 1 ? 'NM' : 'km';
                if (consumption > 0 and gs > 0)
                    return sprintf('%3i%s', (total_fuel * gs) / consumption * units.distance.from_nm, unit);
                else
                    return '---' ~ unit;
            }, 'Endurance'],
            ETA: [func {
                var eteSeconds = getprop('/autopilot/route-manager/ete');
                string.scanf(data.time, '%02u:%02u:%02u', var eta = []);

                var eteHours = math.floor(eteSeconds / 3600);
                if (eteHours > 24)
                    return '--:--';
                eta[1] += int((eteSeconds - (eteHours * 3600)) / 60);
                if (eta[1] > 59) {
                    eta[1] -= 60;
                    eta[0] += 1;
                }
                eta[0] += eteHours;
                if (eta[0] > 23)
                    eta[0] -= 24;
                return sprintf('%02i:%02i', eta[0], eta[1]);
            }, 'Estimated Time of Arrival'],
            GS:  [func return sprintf('%3i%s', getprop('/velocities/groundspeed-kt') * units.speed.from_kt,
                                      units.speed.from_kt == 1 ? 'KT' : 'km/h'),
                 'Ground Speed'],
            TRK: [func return sprintf('%03i°', getprop('/orientation/track-deg')), 'Track'],
            TAS: [func return sprintf('%i%s', getprop('/instrumentation/airspeed-indicator/true-speed-kt') * units.speed.from_kt,
                                      units.speed.from_kt == 1 ? 'KT' : 'km/h' == 1),
                 'True Air Speed'],
            FOB: [func return sprintf('%3ilbs', getprop('/consumables/fuel/total-fuel-lbs')), 'Fuel on Board'],
            XTK: [func {
                var xtk = nil;
                var source = cdi.getValue('source');
                if (source == 'NAV1')
                    var xtk = abs(getprop('/instrumentation/nav[0]/crosstrack-error-m')) * units.distance.from_m;
                elsif (source == 'NAV2')
                    var xtk = abs(getprop('/instrumentation/nav[1]/crosstrack-error-m')) * units.distance.from_m;
                elsif (source == 'GPS')
                    var xtk = abs(getprop('/instrumentation/gps/wp/wp[1]/course-error-nm')) * units.distance.from_nm;

                var unit = units.distance.from_nm = 1 ? 'NM' : 'km';
                if (xtk == nil)
                    return ' ---' ~ unit;
                elsif (xtk > 99.9)
                    return ' ++.+' ~ unit;
                else
                    return sprintf('%2.1f%s', xtk, unit);
            }, 'Crosstrack Error'],
            MSA: [func {
                data._msa_spd        = getprop('/velocities/groundspeed-kt');
                data._msa_track      = getprop('/orientation/track-deg');
                if (! contains(data.timers, 'MSA_geodinfo')) {
                    data._msa_alt         = -1;
                    data._msa_point       = 1;
                    data._msa_alt_intern  = 0;
                    data.timers.MSA_geodinfo = maketimer(0, func {
                        var geo = greatCircleMove(
                                data._msa_track,
                                (data._msa_spd / 12) / 10 * data._msa_point);
                        var _geodinfo = geodinfo(geo.lat, geo.lon, 10000);
                        if (_geodinfo != nil)
                            if (data._msa_alt_intern < _geodinfo[0]) data._msa_alt_intern = _geodinfo[0];
                        data._msa_point += 1;
                        if (data._msa_point > 10) {
                            data._msa_alt         = math.round((1000 + data._msa_alt_intern * units.altitude.from_m) / 100) * 100;
                            data._msa_point       = 0;
                            data._msa_alt_intern  = 0;
                            data.timers.MSA_geodinfo.stop();
                        }
                    });
                }
                data.timers.MSA_geodinfo.start();
                return data._msa_alt == -1 ? '-----ft' : sprintf('%5i%s', data._msa_alt, units.altitude.from_m == 1 ? 'm' : 'ft');
            }, 'Minimum Safe Altitude'],
#            BRG: [func return '---°', 'Bearing'],
#            ESA: [func return '-----', 'Enroute Safe Altitude'],
#            ISA: [func return '-----', 'ISA Relative Temperature'],
#            TKE: [func return ' ---°', 'Track Angle Error'],
#            VSR: [func return ' ----', 'Vertical Speed Required'],
# }}}
        };
        if (m.device.role == 'PFD')
            foreach (var item; keys(m.navbox))
                if (item != 'LEG' and item != 'DIS' and item != 'ETE')
                    delete(m.navbox, item);
        return m;
    },
#}}}

    off: func {
        me.parents[0]._updateRadio = func; # because of the settimers...
        me.parents[0].updateEIS = func;
        foreach(var timer; keys(me.timers)) {
            me.timers[timer].stop();
            delete(me.timers, timer);
        }
        foreach (var e; keys(me.screenElements)) {
            if (typeof(me.screenElements[e]) != 'nil')
                me.screenElements[e].hide();
            delete(me.screenElements, e);
        }
        foreach (var e; keys(me.screenElements)) {
            if (typeof(me.screenElements[e]) != 'nil')
                me.screenElements[e].hide();
            delete(me.screenElements, e);
        }
        foreach (var e; keys(me.screenElements)) {
            if (typeof(me.screenElements[e]) != 'nil')
                me.screenElements[e].hide();
            delete(me.screenElements, e);
        }
        me.screen.setVisible(0);
        settimer(func {
                me.screen.removeAllChildren();
                me.screen.del();
                me.display.del();
        }, 0.1);
    },

# temporary Widget Display for HDG and CRS modification {{{

    temporaryWidgetDisplay : {},

    timerTrigger : func {
        var now = systime();
        foreach (var id; keys(me.temporaryWidgetDisplay)) {
            if (me.temporaryWidgetDisplay[id] < now) {
                me.screenElements[id].hide();
                delete(me.temporaryWidgetDisplay, id);
            }
        }
    },

    addTimer : func (duration, element) {
        if (typeof(element) == 'scalar')
            element = [ element ];
        var end = systime() + duration;
        foreach (var e; element)
            me.temporaryWidgetDisplay[e] = end;
    },
#}}}

    showInitProgress : func {
#{{{
        if (me.device.role == 'PFD') {
            me.timers.updateAI     = maketimer(0.025, me, me.updateAI     );
            me.timers.updateVSI    = maketimer(0.1, me, me.updateVSI    );
            me.timers.updateIAS    = maketimer(0.025, me, me.updateIAS    );
            me.timers.updateALT    = maketimer(0.025, me, me.updateALT    );
            me.timers.updateHSI    = maketimer(0.025, me, me.updateHSI    );
            me.timers.updateTIME   = maketimer(1.0, me, me.updateTIME   );
            me.timers.updateOAT    = maketimer(3.0, me, me.updateOAT    );
            me.timers.updateTAS    = maketimer(0.5, me, me.updateTAS    );
            me.timers.updateBRG    = maketimer(0.5, me, me.updateBRG    );
            me.timers.updateXPDR   = maketimer(0,   me, me.updateXPDR   ); me.timers.updateXPDR.singleShot=1;
            me.timers.updateBARO   = maketimer(0,   me, me.updateBARO   ); me.timers.updateBARO.singleShot=1;
            me.timers.updateOMI    = maketimer(1.0, me, me.updateOMI    );
            me.timers.timerTrigger = maketimer(1.0, me, me.timerTrigger );
            me.timers.updateAOA    = maketimer(0.1, me, me.updateAOA    );    me.timers.updateAOA.singleShot=1;
            me.timers.updateCDI    = maketimer(0.3, me, me.updateCDI    );    me.timers.updateCDI.singleShot=1;
            me.timers.updateWindData = maketimer(0.5, me, me.updateWindData); me.timers.updateWindData.singleShot=1;

            me.screenElements['Heading-bug'].setRotation(int(afcs.getValue('heading-bug-deg')) * D2R);

            me.screen.show();
            me.device.buttons.MENU = me.device.buttons.GlobalParams;
        }
        else {
            me.updateEIS();
            io.load_nasal(data.zkv1000_dir ~ 'Nasal/MFD.pages.nas', 'zkv1000');
            me['page selected'] = 0;
            me.setMFDPages();
            me.device.buttons.MENU = me.device.buttons.MapMenu;
        }

        me.updateNAV({auto:'nav', tune: radios.getNode('nav-tune').getValue()});
        me.updateCOMM({auto:'comm', tune: radios.getNode('comm-tune').getValue()});
        me.softkeys_inactivity();
        me.updateSoftKeys();
        me.timers.updateNavigationBox = maketimer(me.device.role == 'MFD' ? 0.6 : 0.3, me, me.updateNavigationBox);

        foreach (var timer; keys(me.timers))
            me.timers[timer].start();

        me.timers.updateGS = maketimer(0.2, me, me.updateGS);
    },
#}}}

    colors : {
# set of predefined colors {{{
        green : [0, 1, 0],
        white : [1, 1, 1],
        black : [0, 0, 0],
        lightblue : [0, 1, 1],
        darkblue : [0, 0, 1],
        red : [1, 0, 0],
        magenta : [1, 0, 1],
        yellow : [1, 1, 0],
        lightgrey : [0.5, 0.5, 0.5],
    },
#}}}

    loadGroup : func (h) {
#{{{
        if (typeof(h) != 'hash') {
            msg_dbg(sprintf("%s need a hash, but get a %s from %s",
                    caller(0)[0],
                    typeof(h),
                    caller(1)[0]));
            return;
        }
        var setMethod = func (e, t) {
            if (t == 'hide')
                me.screenElements[e].hide();
            elsif (t == 'show')
                me.screenElements[e].show();
            elsif (t == 'rot' or t == 'trans') {
                if (! contains(me.screenElements[e], t))
                    me.screenElements[e][t] = me.screenElements[e].createTransform();
            }
            elsif (t == 'clip') {
                if (contains(me.clips, e))
                    me.screenElements[e].set("clip", me.clips[e]);
                else
                    logprint(LOG_WARN, 'no defined clip for ' ~ e);
            }
            elsif (t == 'text') {
                if (contains(me.texts, e)) {
                    if (contains(me.texts[e], 'alignment'))
                        me.screenElements[e].setAlignment(me.texts[e].alignment);
                    if (contains(me.texts[e], 'default'))
                        me.screenElements[e].setText(me.texts[e].default);
                    if (contains(me.texts[e], 'color'))
                        me.screenElements[e].setColor(me.texts[e].color);
                    if (contains(me.texts[e], 'visible'))
                        me.screenElements[e].setVisible(me.texts[e].visible);
                }
                else
                    logprint(LOG_DEBUG, 'no text format for ' ~ e);
            }
            else
                logprint(LOG_WARN, 'unknown method ' ~ t);
        };
        foreach (var todo; keys(h)) {
            if (typeof(h[todo]) != 'vector') h[todo] = [ h[todo] ];
            foreach (var id; h[todo]) {
                if (! contains(me.screenElements, id)) {
                    me.screenElements[id] = me.screen.getElementById(id);
                    if (me.screenElements[id] != nil)
                        setMethod(id, todo);
                    else
                        logprint(LOG_WARN, 'SVG ID ' ~ id ~ ' not found');
                }
                else
                    setMethod(id, todo);
            }
        }
        if (me.device.role == 'PFD') {
            var Vsource = me.screen.getElementById('Vspeed');
            foreach (var V; keys(data.Vspeeds)) {
                me.screenElements[V] = me.screen.createChild('group', V);
                props.copy( Vsource.parents[1]._node, me.screenElements[V].parents[1]._node);
                me.screenElements[V].parents[1]._node.setValue('id', V);
                me.screenElements[V].parents[1]._node.setValue('text/id', V);
                me.screenElements[V].parents[1]._node.setValue('text/text', V);
            }
            Vsource.hide();
            Vsource.removeAllChildren();
            Vsource.del();
        }
    },
#}}}

    clips : {
#{{{
        PitchScale   : "rect(70,664,370,256)",
        SpeedLint1   : "rect(252,226,318,204)",
        SpeedTape    : "rect(115,239,455,156)",
        LintAlt      : "rect(115,808,455,704)",
        AltLint00011 : "rect(252,804,318,771)",
    },
#}}}

    texts : {
#{{{
        VSIText : {
            alignment: "right-bottom", default : num('0'),
        },
        Speed110 : {
            alignment : 'right-bottom'
        },
        Alt11100 : {
            alignment:'right-bottom'
        },
        "HDG-text" : {
            default: '---°'
        },
        'nav1-standby-freq' : {
            color: [0, 1, 1],
        },
        'nav1-id' : {
            default: ''
        },
        'nav2-id' : {
            default: ''
        },
        'CDI-GPS-ANN-text' : {
            visible : 0
        },
        'CDI-GPS-XTK-text' : {
            visible : 0
        },
        'CDI-SRC-text' : {
            visible : 0
        },
        'BARO-text' : {
            alignment : 'left-bottom',
        },
        'LEG-text' : {
            alignment : 'center-center',
        },
#        'TAS-text' : {
#            alignment : 'right-bottom',
#        },
#        'GSPD-text' : {
#            alignment : 'right-bottom',
#        },
    },
#}}}

    softkeys_inactivity : func {
# automagically back to previous level after some delay {{{
        me.timers.softkeys_inactivity = maketimer (
            me.softkeys_inactivity_delay,
            func {
                pop(me.device.softkeys.path);
                me.updateSoftKeys();
            }, me);
        me.timers.softkeys_inactivity.singleShot = 1;
    },
#}}}

    setSoftKeyColor : func (n, active, implemented = 1, alert = 0) {
# set colors for active softkeys {{{
        var sftk = sprintf('SoftKey%02i-', n);
        if (active) {
            var bg = alert ? 1 : 0.5;
            me.screenElements[sftk ~ 'bg']
                .setColorFill(bg,bg,bg);
            me.screenElements[sftk ~ 'text']
                .setColor(0,0,0);
        }
        else {
            var tc = implemented ? 1 : 0.5;
            me.screenElements[sftk ~ 'bg']
                .setColorFill(0,0,0);
            me.screenElements[sftk ~ 'text']
                .setColor(tc,tc,tc);
        }
    },
#}}}

    updateNavigationBox : func {
# update Navigation Box on MFD and PFD header {{{
        var route = me.device.map.layers.route;
        data.fpSize = size(route.flightPlan);
        if (me.device.role == 'MFD') {
            for (var i=1; i<=4; i+=1)
                me.screenElements['DATA-FIELD' ~ i ~ '-VAL-text']
                    .setText(
                        me.navbox[me.screenElements['DATA-FIELD' ~ i ~ '-ID-text'].get('text')][0]()
                    );
        }
        else { # PFD
            var enroute = getprop('/autopilot/route-manager/current-wp') > -1;
            me.screenElements['ETE'].setVisible(enroute);
            me.screenElements['DIS'].setVisible(enroute);
            me.screenElements['ETE-text'].setVisible(enroute).setText(me.navbox.ETE[0]());
            me.screenElements['DIS-text'].setVisible(enroute).setText(me.navbox.DIS[0]());
            me.screenElements['LEG-text'].setVisible(enroute).setText(me.navbox.LEG[0]());
        }
    },
#}}}

    updateSoftKeys : func {
# update SoftKeys boxes {{{
        # on PFD the last boxes are always BACK and ALERTS
        if (me.device.role == 'PFD') {
            me.screenElements[sprintf("SoftKey%02i-text", 11)]
                .setText('ALERTS');
            if (size(me.device.softkeys.path) != 0)
                me.screenElements[sprintf("SoftKey%02i-text", 10)]
                    .setText('BACK')
                    .setColor(1,1,1);
        }

        var path = keyMap[me.device.role];
        var bindings = me.device.softkeys.bindings[me.device.role];
        var pathid = '';
        foreach (var p; me.device.softkeys.path) {
            path = path[p];
            pathid ~= p;
            if (contains(bindings, p))
                bindings = bindings[p];
        }

        # feeding with empty menus the first boxes
        var start = (contains(path, 'first')) ? path.first : 0;
        for (var k = 0; k < start; k+=1) {
            var sftk = sprintf("SoftKey%02i-", k);
            me.screenElements[sftk ~ 'text']
                .setText('');
            me.screenElements[sftk ~ 'bg']
                .setColorFill(0,0,0);
        }
        # filling with the content the next boxes
        forindex (var k; path.texts) {
            var i = k + start;
            me.screenElements[sprintf("SoftKey%02i-text", i)]
                .setText(path.texts[k]);
            me.setSoftKeyColor(i,
                    contains(me.device.softkeys.colored, pathid ~ path.texts[k]),
                    contains(bindings, path.texts[k]) or (me.device.role == 'MFD' and path.texts[k] == 'BACK'));
        }
        # feeding the last boxes with empty string
        var end = (me.device.role == 'PFD') ? 10 : 12;
        if (size(path.texts) + start < end) {
            start = size(path.texts) + start;
            for (var k = start; k < end; k += 1) {
                var sftk = sprintf("SoftKey%02i-", k);
                me.screenElements[sftk ~ 'text']
                    .setText('');
                me.screenElements[sftk ~ 'bg']
                    .setColorFill(0,0,0);
            }
        }

        if (size(me.device.softkeys.path))
            me.timers.softkeys_inactivity.restart(me.softkeys_inactivity_delay);
        else
            me.timers.softkeys_inactivity.stop();
    },
#}}}

    updateAI: func(){
#{{{
        var pitch = data.pitch;
        var roll = data.roll;
        if (pitch > 80)
            pitch = 80;
        elsif (pitch < -80)
            pitch = -80;
        me.screenElements.Horizon
            .setCenter(459, 282.8 - 6.849 * pitch)
            .setRotation(-roll * D2R)
            .setTranslation(0, pitch * 6.849);
        me.screenElements.bankPointer
            .setRotation(-roll * D2R);
        me.screenElements['SlipSkid']
            .setTranslation(getprop("/instrumentation/slip-skid-ball/indicated-slip-skid") * 10, 0);
        me.screenElements['Traffic']
            .setVisible(data.tcas_level > 1);
    },
#}}}

    updateVSI: func () {
# animate VSI {{{
        var vsi = data.vsi;
        me.screenElements.VSIText
            .setText(num(math.round(vsi, 10)));
        var scale = units.vspeed.from_fpm == 1 ? 1 : 10;
        if (vsi > 4500 / scale)
            vsi = 4500 / scale;
        elsif (vsi < -4500 / scale)
            vsi = -4500 / scale;
        me.screenElements.VSI
            .setTranslation(0, vsi * -0.03465 * scale);
    },
#}}}

    updateIAS: func () {
# animates the IAS lint (PFD) {{{
        var ias = data.ias;
        if (ias >= 10)
            me.screenElements.Speed110
                .setText(sprintf("% 2u",num(math.floor(ias/10))));
        else
            me.screenElements.Speed110
                .setText('');
        me.screenElements.SpeedLint1
            .setTranslation(0,(math.mod(ias,10) + (ias >= 10)*10) * 36);
        me.screenElements.SpeedTape
            .setTranslation(0,ias * 5.711);
        if (ias > me._Vne and ! me._ias_already_exceeded) { # easier than .getColorFill
            me._ias_already_exceeded = 1;
            me.screenElements['IAS-bg']
                .setColorFill(1,0,0);
        }
        elsif (ias < me._Vne and me._ias_already_exceeded) { # easier than .getColorFill
            me._ias_already_exceeded = 0;
            me.screenElements['IAS-bg']
                .setColorFill(0,0,0);
        }
        foreach (var v; keys(data.Vspeeds)) {
            if (me.device.data[v ~ '-visible'] and abs(data.Vspeeds[v] - ias) < 30)
                me.screenElements[v]
                    .setTranslation(0, (ias - data.Vspeeds[v]) * 5.711)
                    .show();
            else
                me.screenElements[v]
                    .hide();
        }

        var Sy = 0;
        for (var i = 8; i >= 0; i -= 1)
            me._last_ias_Sy[i+1] = me._last_ias_Sy[i];
        var now = systime();
        # estimated speed in 6s
        me._last_ias_Sy[0] = 6 * (ias - me._last_ias) / (now - me._last_ias_s);
        foreach (var _Sy; me._last_ias_Sy)
            Sy += _Sy;
        Sy /= 10;
        if (abs(Sy) > 30)
            Sy = 30 * abs(Sy)/Sy; # = -30 or 30
        me.screenElements['Airspeed-Trend-Indicator']
            .setScale(1,Sy)
            .setTranslation(0, -284.5 * (Sy - 1));
        me._last_ias = ias;
        me._last_ias_s = now;
    },
    _Vne : contains(data.Vspeeds, 'Vne') ? data.Vspeeds.Vne : 999,
    _last_ias : 0,
    _last_ias_s : systime(),
    _last_ias_Sy : [0,0,0,0,0,0,0,0,0,0],
    _ias_already_exceeded : 0,
#}}}

    updateTAS: func {
# updates the True Airspeed and GroundSpeed indicators {{{
        var unit = units.speed.from_kt == 1 ? 'KT' : 'km/h';
        me.screenElements['TAS-text']
            .setText(sprintf('%i%s', getprop('/instrumentation/airspeed-indicator/true-speed-kt') * units.speed.from_kt, unit));
        me.screenElements['GSPD-text']
            .setText(sprintf('%i%s', getprop('/velocities/groundspeed-kt') * units.speed.from_kt, unit));
    },
#}}}

    updateALT: func () {
# animates the altitude lint (PFD) {{{
        var alt = data.alt;
        if (alt < 0)
            me.screenElements.Alt11100
                .setText(sprintf("%3d",math.ceil(alt/100)));
        elsif (alt < 100)
            me.screenElements.Alt11100
                .setText('');
        else
            me.screenElements.Alt11100
                .setText(sprintf("%3i",math.floor(alt/100)));
        me.screenElements.AltLint00011
            .setTranslation(0,math.fmod(alt,100) * 1.24);

        # From Farmin/G1000 http://wiki.flightgear.org/Project_Farmin/FG1000
        if (alt> -1000 and alt< 1000000) {
            var Offset10 = 0;
            var Offset100 = 0;
            var Offset1000 = 0;
            if (alt< 0) {
                var Ne = 1;
                var alt= -alt;
            }
            else
                var Ne = 0;

            var Alt10       = math.mod(alt,100);
            var Alt100      = int(math.mod(alt/100,10));
            var Alt1000     = int(math.mod(alt/1000,10));
            var Alt10000    = int(math.mod(alt/10000,10));
            var Alt20       = math.mod(Alt10,20)/20;
            if (Alt10 >= 80)
                var Alt100 += Alt20;

            if (Alt10 >= 80 and Alt100 >= 9)
                var Alt1000 += Alt20;

            if (Alt10 >= 80 and Alt100 >= 9 and Alt1000 >= 9)
                var Alt10000 += Alt20;

            if (alt> 100)
                var Offset10 = 100;

            if (alt> 1000)
                var Offset100 = 10;

            if (alt> 10000)
                var Offset1000 = 10;

            if (!Ne) {
                me.screenElements.LintAlt.setTranslation(0,(math.mod(alt,100))*0.57375);
                var altCentral = (int(alt/100)*100);
            }
            elsif (Ne) {
                me.screenElements.LintAlt.setTranslation(0,(math.mod(alt,100))*-0.57375);
                var altCentral = -(int(alt/100)*100);
            }
            me.screenElements["AltBigC"].setText("");
            me.screenElements["AltSmallC"].setText("");
            for (var place = 1; place <= 6; place += 1) {
                var altUP = altCentral + (place*100);
                var offset = -30.078;
                if (altUP < 0) {
                    var altUP = -altUP;
                    var prefix = "-";
                    var offset += 15.039;
                }
                else
                    var prefix = "";

                if (altUP == 0) {
                    var AltBigUP    = "";
                    var AltSmallUP  = "0";

                }
                elsif (math.mod(altUP,500) == 0 and altUP != 0) {
                    var AltBigUP    = sprintf(prefix~"%1d", altUP);
                    var AltSmallUP  = "";
                }
                elsif (altUP < 1000 and (math.mod(altUP,500))) {
                    var AltBigUP    = "";
                    var AltSmallUP  = sprintf(prefix~"%1d", int(math.mod(altUP,1000)));
                    var offset = -30.078;
                }
                elsif ((altUP < 10000) and (altUP >= 1000) and (math.mod(altUP,500))) {
                    var AltBigUP    = sprintf(prefix~"%1d", int(altUP/1000));
                    var AltSmallUP  = sprintf("%1d", int(math.mod(altUP,1000)));
                    var offset += 15.039;
                }
                else {
                    var AltBigUP    = sprintf(prefix~"%1d", int(altUP/1000));
                    var mod = int(math.mod(altUP,1000));
                    var AltSmallUP  = sprintf("%1d", mod);
                    var offset += 30.078;
                }

                me.screenElements["AltBigU"~place].setText(AltBigUP);
                me.screenElements["AltSmallU"~place].setText(AltSmallUP);
                me.screenElements["AltSmallU"~place].setTranslation(offset,0);
                var altDOWN = altCentral - (place*100);
                var offset = -30.078;
                if (altDOWN < 0) {
                    var altDOWN = -altDOWN;
                    var prefix = "-";
                    var offset += 15.039;
                }
                else
                    var prefix = "";

                if (altDOWN == 0) {
                    var AltBigDOWN  = "";
                    var AltSmallDOWN    = "0";
                }
                elsif (math.mod(altDOWN,500) == 0 and altDOWN != 0) {
                    var AltBigDOWN  = sprintf(prefix~"%1d", altDOWN);
                    var AltSmallDOWN    = "";
                }
                elsif (altDOWN < 1000 and (math.mod(altDOWN,500))) {
                    var AltBigDOWN  = "";
                    var AltSmallDOWN    = sprintf(prefix~"%1d", int(math.mod(altDOWN,1000)));
                    var offset = -30.078;
                }
                elsif ((altDOWN < 10000) and (altDOWN >= 1000) and (math.mod(altDOWN,500))) {
                    var AltBigDOWN  = sprintf(prefix~"%1d", int(altDOWN/1000));
                    var AltSmallDOWN    = sprintf("%1d", int(math.mod(altDOWN,1000)));
                    var offset += 15.039;
                }
                else {
                    var AltBigDOWN  = sprintf(prefix~"%1d", int(altDOWN/1000));
                    var mod = int(math.mod(altDOWN,1000));
                    var AltSmallDOWN    = sprintf("%1d", mod);
                    var offset += 30.078;
                }
                me.screenElements["AltBigD"~place].setText(AltBigDOWN);
                me.screenElements["AltSmallD"~place].setText(AltSmallDOWN);
                me.screenElements["AltSmallD"~place].setTranslation(offset,0);
            }
        }
        me.updateSelectedALT();
        var Sy = 0;
        for (var i = 8; i >= 0; i -= 1)
            me._last_alt_Sy[i+1] = me._last_alt_Sy[i];
        var now = systime();
        # altitude in 6s
        me._last_alt_Sy[0] = .3 * (alt - me._last_alt_ft) / (now - me._last_alt_s); # scale = 1/20ft
        foreach (var _Sy; me._last_alt_Sy)
            Sy += _Sy;
        Sy /= 10;
        if (abs(Sy) > 15)
            Sy = 15 * abs(Sy)/Sy; # = -15 or 15
        me.screenElements['Altitude-Trend-Indicator']
            .setScale(1,Sy)
            .setTranslation(0, -284.5 * (Sy - 1));
        me._last_alt_ft = alt;
        me._last_alt_s = now;
    },
    _last_alt_ft : 0,
    _last_alt_Sy : [0,0,0,0,0,0,0,0,0,0],
    _last_alt_s  : systime(),
#}}}

    updateBARO : func () {
# update BARO widget {{{
        var fmt = data.settings.units.pressure == 'inhg' ? '%.2f%s' : '%i%s';
        me.screenElements['BARO-text']
            .setText(sprintf(fmt,
                        getprop('/instrumentation/altimeter/setting-' ~ data.settings.units.pressure),
                        data.settings.units.pressure == 'inhg' ? 'in' : 'hPa')
                );
    },
#}}}

    updateHSI : func () {
# rotates the compass (PFD) {{{
        var hdg = data.hdg;
        me.screenElements.Rose
            .setRotation(-hdg * D2R);
        me.screenElements['HDG-text']
            .setText(sprintf("%03u°", hdg));
    },
#}}}

    updateHDG : func () {
# moves the heading bug and display heading-deg for 3 seconds (PFD) {{{
        if (me.device.role == 'MFD')
            return;
        var hdg = afcs.getValue('heading-bug-deg');
        me.screenElements['Heading-bug']
            .setRotation(hdg * D2R);
        me.screenElements['SelectedHDG-bg']
            .show();
        me.screenElements['SelectedHDG-bgtext']
            .show();
        me.screenElements['SelectedHDG-text']
            .setText(sprintf('%03d°%s', hdg, ''))
            .show();
        me.addTimer(3, ['SelectedHDG-text', 'SelectedHDG-bgtext', 'SelectedHDG-bg']);
    },
#}}}

    updateCRS : func () {
# TODO: update display for NAV/GPS/BRG courses {{{
        if (me.device.role == 'MFD')
            return;
        var source = cdi.getValue('source');
        if (source == 'OFF')
            return;
        var crs = cdi.getValue('course');
        if (crs == nil)
            return;
        me.screenElements['SelectedCRS-bg']
            .show();
        me.screenElements['SelectedCRS-bgtext']
            .show();
        me.screenElements['SelectedCRS-text']
            .setText(sprintf('%03d°%s', crs, ''))
            .setColor(source == 'GPS' ? me.colors.magenta : me.colors.green)
            .show();
        me.addTimer(3, ['SelectedCRS-text', 'SelectedCRS-bgtext', 'SelectedCRS-bg']);
    },
#}}}

    updateSelectedALT : func {
# animation for altitude section, called via updatedALT {{{
        if (! me.screenElements['SelectedALT'].getVisible())
            return;
        var selected_alt = afcs.getValue('selected-alt-ft');
        var delta_alt = data.alt - selected_alt;
        if (abs(delta_alt) > 300)
            delta_alt = 300 * abs(delta_alt)/delta_alt;
        me.screenElements['SelectedALT-symbol']
            .setVisible(abs(delta_alt) > 100);
        me.screenElements['SelectedALT-bg']
            .setVisible(abs(delta_alt) > 100);
        me.screenElements['SelectedALT-text']
            .setText(sprintf("%i", selected_alt))
            .setVisible(abs(delta_alt) > 100);
        me.screenElements['SelectedALT-bug']
            .setTranslation(0, delta_alt * 0.567); # 170/300 = 0.567
    },
#}}}

    updateCDI : func {
# animation for CDI {{{
        var source = cdi.getValue('source');
        if (source == 'OFF') {
            foreach (var s; ['GPS', 'NAV1', 'NAV2'])
                foreach (var t; ['pointer', 'CDI'])
                    me.screenElements[s ~ '-' ~ t].hide();
            me.screenElements['CDI-GPS-ANN-text'].hide();
            me.screenElements['CDI-GPS-XTK-text'].hide();
            me.screenElements['CDI-SRC-text'].hide();
            me.screenElements['CDI'].hide();
        }
        else {
            var course = cdi.getValue('course');
            var rot = (course - data.hdg) * D2R;
            me.screenElements['CDI']
                .setRotation(rot)
                .show();
            me.screenElements['GPS-CTI']
                .setVisible(getprop('/instrumentation/gps/wp/wp[1]/valid'))
                .setRotation(getprop('/instrumentation/gps/wp/wp[1]/course-deviation-deg') * D2R);
            me.screenElements['GPS-CTI-diamond']
                .setVisible(getprop('/instrumentation/gps/wp/wp[1]/valid'))
                .setRotation(getprop('/instrumentation/gps/wp/wp[1]/course-deviation-deg') * D2R);
            foreach (var s; ['GPS', 'NAV1', 'NAV2']) {
                me.screenElements[s ~ '-pointer']
                    .setRotation(rot)
                    .setVisible(source == s);
                me.screenElements[s ~ '-CDI']
                    .setVisible(source == s);
                foreach (var f; ['FROM', 'TO'])
                    me.screenElements[s ~ '-' ~ f]
                        .setVisible(s == source and cdi.getValue(f ~ '-flag'));
                me.screenElements['CDI-SRC-text']
                    .setText(source)
                    .setColor(source == 'GPS' ? me.colors.magenta : me.colors.green)
                    .show();
            }
            var deflection = cdi.getValue('course-deflection');
            if (left(source, 3) == 'NAV') {
                var scale = deflection / 4;
                if (cdi.getValue('in-range') == 0)
                    me.screenElements['CDI-GPS-XTK-text']
                        .setColor(me.colors.green)
                        .setText('RANGE')
                        .setVisible(!me.screenElements['CDI-GPS-XTK-text'].getVisible());
                else
                    me.screenElements['CDI-GPS-XTK-text']
                        .hide();
                if (source == 'NAV1' and getprop('/instrumentation/nav/nav-loc')) {
                    me.screenElements['CDI-GPS-ANN-text']
                        .setColor(me.colors.green)
                        .setText('LOC')
                        .show();
                    cdi.setValue('course', int(getprop('/instrumentation/nav/radials/target-radial-deg')));
                }
                else
                    me.screenElements['CDI-GPS-ANN-text'].hide();
            }
            else { # GPS
                # TODO: deviation depending of the flight phase
                # for now fixed 1 dot = 1 nm course error
                var abs_deflection_max = 2.4;
                if (me.screenElements['LATMOD-Armed-text'].getText() == 'GPS')
                    abs_deflection_max = 0.5;
                if (getprop('/instrumentation/gps/mode') == 'obs') {
                    abs_deflection_max = 0.1;
                    me.screenElements['CDI-GPS-ANN-text']
                        .setColor(me.colors.magenta)
                        .setText('OBS')
                        .show();
                }
                else
                    me.screenElements['CDI-GPS-ANN-text'].hide();
                var abs_deflection = abs(deflection);
                me.screenElements['CDI-GPS-XTK-text']
                    .setText(sprintf((abs_deflection < 1 ? 'XTK %.1fNM' : 'XTK %iNM'), abs_deflection))
                    .setColor(me.colors.magenta)
                    .setVisible(abs_deflection > abs_deflection_max);
                var scale = deflection / 2;
            }
            scale = (abs(scale) > 1.2) ? 1.2 * scale / abs(scale) : scale;
            me.screenElements[source ~ '-CDI']
                .setTranslation(65 * scale, 0);
            me.timers.updateCDI.start();
        }
    },
#}}}

    _updateRadio: func {
# common parts for NAV/LOC/COMM radios{{{
        # arg[0]._r = <comm|nav>
        if (contains(arg[0], "active")) {
            if (arg[0]['active'] == 'none') {
                me.screenElements[arg[0]._r ~ '1-selected-freq']
                    .setColor(1,1,1);
                me.screenElements[arg[0]._r ~ '2-selected-freq']
                    .setColor(1,1,1);
            }
            else {
                me.screenElements[arg[0]._r ~ arg[0]['active'] ~ '-selected-freq']
                    .setColor(0,1,0);
                me.screenElements[arg[0]._r ~ arg[0].inactive ~ '-selected-freq']
                    .setColor(1,1,1);
            }
        }
        if (contains(arg[0], 'tune')) {
            # n = 0 -> NAV1/COMM1
            # n = 1 -> NAV1/COMM2
            me.screenElements[arg[0]._r ~ '-freq-switch']
                .setTranslation(0, arg[0].tune * 25);
            me.screenElements[arg[0]._r ~ (arg[0].tune + 1) ~ '-standby-freq']
                .setColor(0,1,1);
            me.screenElements[arg[0]._r ~ ((arg[0].tune == 0) + 1) ~ '-standby-freq']
                .setColor(1,1,1);
        }
        if (contains(arg[0], 'refresh')) {
            # refresh only one line: NAV1/COMM1 or NAV2/COMM2
            var fmt = (arg[0]._r == 'nav') ? '%.2f' : '%.3f';
            me.screenElements[arg[0]._r ~ arg[0].refresh ~ '-selected-freq']
                .setText(sprintf(fmt, getprop('/instrumentation/'
                               ~ arg[0]._r ~ '[' ~ (arg[0].refresh - 1) ~ ']/frequencies/selected-mhz')));
            me.screenElements[arg[0]._r ~ arg[0].refresh ~ '-standby-freq']
                .setText(sprintf(fmt, getprop('/instrumentation/'
                               ~ arg[0]._r ~ '[' ~ (arg[0].refresh - 1) ~ ']/frequencies/standby-mhz')));
        }
        if (contains(arg[0], 'set')) {
            # positionne la valeur modifiée, les listeners "trigguent" en permanence ces propriétés, donc exit
            var n = radios.getValue(arg[0]._r ~ '-tune');
            var fmt = (arg[0]._r == 'nav') ? '%.2f' : '%.3f';
            me.screenElements[arg[0]._r ~ (n + 1) ~ '-standby-freq']
                .setText(sprintf(fmt, getprop('/instrumentation/' ~ arg[0]._r ~ '[' ~ n ~ ']/frequencies/standby-mhz')));
        }
        if (contains(arg[0], 'auto')) {
            # pour rafraichir automagiquement, toutes les deux secondes un refresh pour un NAV
            var radio = arg[0].auto;
            me._updateRadio({refresh: 1, _r: radio});
            settimer(func me._updateRadio({refresh: 2, _r: radio}), 1);
            settimer(func me._updateRadio({auto: radio}), 2);
        }
    },
#}}}

    updateNAV : func {
# update NAV/LOC rodios display upper left (PFD/MFD){{{
        # made active via menu
        if (contains(arg[0], "active")) {
            arg[0]._r = 'nav';
            if (arg[0]['active'] == 'none') {
                me._updateRadio(arg[0]);
                me.screenElements['nav1-id']
                    .setColor(1,1,1);
                me.screenElements['nav2-id']
                    .setColor(1,1,1);
                me.screenElements['NAV1-pointer']
                    .hide();
                me.screenElements['NAV2-pointer']
                    .hide();
            }
            else {
                arg[0].inactive = (arg[0]['active'] == 1) + 1;
                me._updateRadio(arg[0]);
                me.screenElements['nav' ~ arg[0]['active'] ~ '-id']
                    .setColor(0,1,0);
                me.screenElements['NAV' ~ arg[0]['active'] ~ '-pointer']
                    .show();
                me.screenElements['nav' ~ arg[0].inactive ~ '-id']
                    .setColor(1,1,1);
#                me.screenElements['HDI']
#                    .setRotation();
#                me.screenElements['NAV' ~ inactive ~ '-pointer']
#                    .hide();
#                foreach (var e; [ 'FROM', 'TO', 'CDI' ])
#                    me.screenElements['NAV' ~ inactive ~ '-' ~ e]
#                        .hide();
            }
        }
        elsif (contains(arg[0], 'nav-id')) {
            # TODO: récupérer la valeur via les paramètres transmis du listener
            if (arg[0].val == nil)
                arg[0].val = '';
            me.screenElements["nav" ~ arg[0]['nav-id'] ~ "-id"]
                    .setText(arg[0].val);
        }
        else {
            arg[0]._r = 'nav';
            me._updateRadio(arg[0]);
        }
    },
#}}}

    updateCOMM: func {
# update COMM radios display upper right (PFD/MFD){{{
        arg[0]._r = 'comm';
        me._updateRadio(arg[0]);
    },
#}}}

    updateTIME : func {
# updates the displayed time botoom left {{{
        time[data.settings.time.label]();
        me.screenElements['TIME-REF-text']
            .setText(data.settings.time.label);
        me.screenElements['TIME-text']
            .setText(data.time);
    },
#}}}

    updateXPDR : func {
# updates transponder display {{{
        for (var d = 0; d < 4; d+=1)
            me.screenElements['XPDR-DIGIT-' ~ d ~ '-text']
                .setText(sprintf('%i', getprop('/instrumentation/transponder/inputs/digit[' ~ d ~ ']')));
        var tuning = radios.getValue('xpdr-tuning-digit');
        var fms = radios.getValue('xpdr-tuning-fms-method');
        for (var d = 0; d < 4; d+=1)
            me.screenElements['XPDR-DIGIT-' ~ d ~ '-text']
                .setColor(1,1,1);
        if (tuning != nil) {
            me.screenElements['XPDR-DIGIT-' ~ tuning ~ '-text']
                .setColor(0,1,1);
            if (fms)
                me.screenElements['XPDR-DIGIT-' ~ (tuning - 1) ~ '-text']
                    .setColor(0,1,1);
        }
        else {
            if (getprop('/instrumentation/transponder/ident'))
                var mode = 'IDENT';
            else
                var mode = radios.getValue('xpdr-mode');
            var wow = getprop('/gear/gear/wow');
            if (! wow and mode != 'STBY')
                var color = [0, 1, 0];
            else
                var color = [1, 1, 1];
            for (var d = 0; d < 4; d+=1)
                me.screenElements['XPDR-DIGIT-' ~ d ~ '-text']
                    .setColor(color);
            me.screenElements['XPDR-MODE-text']
                .setColor(color)
                .setText(mode);
        }
    },
#}}}

    updateOAT : func {
# update OAT display on normal and reversionnary modes (every 3s) {{{
        var tmp = units.temperature.from_C(getprop('/environment/temperature-degc'));
        me.screenElements['OAT-text']
            .setText(sprintf((abs(tmp) < 10) ? "%.1f %s" : "%i %s", tmp, units.temperature.from_C(0) ? 'F' : '°C'));
    },
#}}}

    updateWindData : func {
# update the window text and arrows for OPTN1/2 {{{
        if (me._winddata_optn == 0)
            return;
        if (data.ias > 30) {
            me.screenElements['WindData-NODATA']
                .hide();
            var wind_hdg = getprop('/environment/wind-from-heading-deg');
            var wind_spd = getprop('/environment/wind-speed-kt');
            var alpha = wind_hdg - data.hdg;
            if (me._winddata_optn == 1) {
                me.screenElements['WindData-OPTN1-HDG']
                    .setRotation((alpha + 180) * D2R)
                    .show();
                me.screenElements['WindData-OPTN1-HDG-text']
                    .setText(sprintf("%03i°", wind_hdg))
                    .show();
                me.screenElements['WindData-OPTN1-SPD-text']
                    .setText(int(wind_spd) ~ 'KT')
                    .show();
            }
            else { # me._winddata_optn == 2
                alpha *= D2R;
                var Vt = wind_spd * math.sin(alpha);
                var Ve = wind_spd * math.cos(alpha);
                if (Vt != 0) {
                    me.screenElements['WindData-OPTN2-crosswind-text']
                        .setText(sprintf('%i', abs(Vt)))
                        .show();
                    me.screenElements['WindData-OPTN2-crosswind']
                        .setScale(-abs(Vt)/Vt, 1)
                        .setTranslation(-35 * (abs(Vt)/Vt + 1), 0)
                        .show();
                }
                if (Ve != 0) {
                    me.screenElements['WindData-OPTN2-headwind-text']
                        .setText(sprintf('%i', abs(Ve)))
                        .show();
                    me.screenElements['WindData-OPTN2-headwind']
                        .setScale(1, abs(Ve)/Ve)
                        .setTranslation(0, 515 * (1 - abs(Ve)/Ve))
                        .show();
                }
            }
        }
        else {
            foreach (var e; [
                    'WindData-OPTN1-HDG',
                    'WindData-OPTN1-HDG-text',
                    'WindData-OPTN1-SPD-text',
                    'WindData-OPTN2-crosswind-text',
                    'WindData-OPTN2-crosswind',
                    'WindData-OPTN2-headwind-text',
                    'WindData-OPTN2-headwind'
            ])
                me.screenElements[e].hide();
            me.screenElements['WindData-NODATA'].show();
        }
        me.timers.updateWindData.start();
    },
    _winddata_optn : 0,
#}}}

    updateAOA : func {
# update Angle Of Attack {{{
        if (me.device.data.aoa + me.device.data['aoa-auto'] == 0)
            return;
        var color = [1,1,1];
        var norm = data.aoa / data['stall-aoa'];
        me.screenElements['AOA-text']
            .setText(sprintf('% .1f', norm));
        if (norm > 1) norm = 1;
        if (norm > 0.9)
            color = [1,0,0];
        elsif (norm > 0.7)
            color = [1,1,0];
        elsif (norm < 0) {
            norm = 0;
            color = [1,0,0];
        }
        me.screenElements['AOA-needle']
            .setRotation(-norm * math.pi)
            .setColorFill(color);
        me.screenElements['AOA-text']
            .setColor(color);
        me.timers.updateAOA.start();
    },
# }}}

    updateBRG : func {
# displays and update BRG1/2 {{{
        foreach (var brg; [1, 2]) {
            var source = 'brg' ~ brg ~ '-source';

            var dev = radios.getNode(source).getValue();
            var el  = 'BRG' ~ brg;
            if (dev != 'OFF') {
                var info = {
                    pointer : nil,
                    id : 'NO DATA',
                    hdg : nil,
                    dst : '--.-NM'
                };
                if (left(dev, 3) == 'NAV') {
                    info.pointer = getprop('/instrumentation/nav[' ~ (brg - 1) ~ ']/in-range');
                    if (info.pointer) {
                        info.id  = getprop('/instrumentation/nav[' ~ (brg - 1) ~ ']/nav-id');
                        info.hdg = getprop('/instrumentation/nav[' ~ (brg - 1) ~ ']/heading-deg');
                        info.dst = sprintf('%.1d', getprop('/instrumentation/nav[' ~ (brg - 1) ~ ']/nav-distance') / 1852); # m -> /1852
                    }
                }
                elsif (dev == 'GPS') {
                    info.pointer = props.getNode('/instrumentation/gps/wp').getChild('wp[1])');
                    if (info.pointer) {
                        info.id  = getprop('/instrumentation/gps/wp/wp[1]/ID');
                        info.hdg = getprop('/instrumentation/gps/wp/wp[1]/bearing-mag-deg');
                        info.dst = sprintf('%.1d', getprop('/instrumentation/gps/wp/wp[1]/distance-nm'));
                    }
                }
                else { # there are 2 available ADF in FG, but instrument manage only 1
                    info.pointer = getprop('/instrumentation/adf/in-range');
                    if (info.pointer) {
                        info.id  = getprop('/instrumentation/adf/ident');
                        info.hdg = getprop('/instrumentation/adf/indicated-bearing-deg');
                    }
                }

                if (info.pointer)
                    me.screenElements[el ~ '-pointer']
                        .setRotation(-info.hdg - data.hdg * D2R)
                        .show();
                else
                    me.screenElements[el ~ '-pointer']
                        .hide();
                me.screenElements[el ~ '-SRC-text']
                    .setText(dev);
                me.screenElements[el ~ '-DST-text']
                    .setText(info.dst);
                me.screenElements[el ~ '-WPID-text']
                    .setText(info.id);
                me.screenElements['BRG' ~ brg]
                    .show();
            }
            else {
                me.screenElements['BRG' ~ brg]
                    .hide();
            }
        }
    },
#}}}

    updateOMI : func {
# display marker baecon Outer, Middle, Inner {{{
        var marker = nil;
        foreach (var m; ['outer', 'middle', 'inner'])
            if (getprop('/instrumentation/marker-beacon/' ~ m)) {
                marker = m;
                me.screenElements['OMI']
                    .show();
                break;
            }
        if (marker != nil) {
            me.screenElements['MarkerText']
                .setText(me._omi_data[marker].t)
                .show();
            me.screenElements['MarkerBG']
                .setColorFill(me._omi_data[marker].bg)
                .show();
        }
        else
            me.screenElements['OMI']
                .hide();
    },
    _omi_data : {
        'outer':  {t: 'O', bg: [0,1,1]},
        'middle': {t: 'M', bg: [1,1,1]},
        'inner':  {t: 'I', bg: [1,1,0]},
    },
#}}}

    updateGS : func {
# display glide-slope on ILS approach {{{
        var deflection = getprop('/instrumentation/nav/gs-needle-deflection-norm');
        me.screenElements['GS-ILS']
            .setTranslation(0, deflection * 100);
    },
#}}}
};
