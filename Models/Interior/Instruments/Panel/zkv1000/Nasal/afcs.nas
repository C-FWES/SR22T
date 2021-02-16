var APClass = {
    new : func {
        var m = { parents: [ APClass ] };

        m.system = 'none';
        var ap_systems = { # described AP systems to search, if it returns true system is set
            STEC55X: func contains(stec55x, 'ITAF'),
            GFC700: func props.globals.getNode('/autopilot/GFC700/FSM/lateral').getPath(),
        };
        foreach (var s; sort(keys(ap_systems), func(a,b) cmp(a,b))) {
            call(ap_systems[s], [], nil, nil, var errors = []);
            if (!size(errors)) {
                msg('found autopilot system: ' ~ s);
                m.system = s;
                break;
            }
        }

        m.engaged = 0;

        if (! contains(data.timers, 'updateAP')) {
            data.timers.updateAP = maketimer(1, m, m.systems[m.system].updateDisplay);
            data.timers.updateAP.start();
        }

        var ap_annun = [
            'LATMOD-Armed-text',  'LATMOD-Active-text',
            'AP-Status-text',     'YD-Status-text',
            'VERMOD-Active-text', 'VERMOD-Reference-text', 'VERMOD-Armed-text'
        ];
        foreach (var elem; ap_annun) {
            var color = (elem == 'LATMOD-Armed-text' or elem == 'VERMOD-Armed-text') ? 'white' : 'green';
            flightdeck.PFD.display.screenElements[elem]
                .setColor(flightdeck.PFD.display.colors[color])
                .setVisible(0);
        }
        foreach (var ap; [ 'AP', 'YD' ])
            flightdeck.PFD.display.screenElements[ap ~ '-Status-text']
                .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                .setColorFill(flightdeck.PFD.display.colors.black)
                .setText(ap);

        ap_annun = nil;
        ap_systems = nil;
        # delete unused systems
        foreach (var e; keys(m.systems))
            if (e != m.system)
                delete(m.systems, e);

        if (contains(m.systems[m.system], 'hook') and typeof(m.systems[m.system].hook) == 'func')
                m.systems[m.system].hook();

        return m;
    },
    softkey: func (side, row, a) {
        if (a)
            return;
        call(me.systems[me.system][side][row], [], autopilot.parents[0].systems[me.system]);
    },
    systems : {
        # L: AP FD  NAV ALT VS FLC
        # R: YD HDG APR VNV UP DN
        none: {
            updateDisplay: func,
            hook: func,
            L: [ func, func, func, func, func, func ],
            R: [ func, func, func, func, func, func ],
        },
        GFC700: {
# Many thanks to the great work on the FG1000
            _blink_count: 0,
            updateDisplay: func {
                var se = flightdeck.PFD.display.screenElements;
                var annunciator = props.globals.getNode('/autopilot/annunciator');
                var ap_enabled  = annunciator.getValue('autopilot-enabled');

                var latmod         = annunciator.getValue('lateral-mode');
                var latmod_armed   = annunciator.getValue('lateral-mode-armed');
                var vertmod        = annunciator.getValue('vertical-mode');
                var vertmod_armed  = annunciator.getValue('vertical-mode-armed');
                var vertmod_target = annunciator.getValue('vertical-mode-target');
                if (vertmod_target != nil) {
                    vertmod_target = string.replace(vertmod_target, '+', utf8.chstr(9650));
                    vertmod_target = string.replace(vertmod_target, '-', utf8.chstr(9660));
                }

                se['LATMOD-Active-text'].setVisible(latmod != nil and ap_enabled).setText(latmod);
                se['LATMOD-Armed-text'].setVisible(latmod_armed != nil and ap_enabled).setText(latmod_armed);
                se['VERMOD-Active-text'].setVisible(vertmod != nil and ap_enabled).setText(vertmod);
                se['VERMOD-Reference-text'].setVisible(vertmod_target != nil and ap_enabled).setText(vertmod_target);
                se['VERMOD-Armed-text'].setVisible(vertmod_armed != nil and ap_enabled).setText(vertmod_armed);

                if (se['AP-Status-text'].getVisible() and !ap_enabled) {
                    if (math.mod(me._blink_count,2))
                        se['AP-Status-text']
                            .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                            .setColorFill(flightdeck.PFD.display.colors.yellow)
                            .setColor(flightdeck.PFD.display.colors.black);
                    else
                        se['AP-Status-text']
                            .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                            .setColorFill(flightdeck.PFD.display.colors.black)
                            .setColor(flightdeck.PFD.display.colors.yellow);
                    me._blink_count += 1;
                    if (me._blink_count == 5) {
                        se['AP-Status-text']
                            .setColor(flightdeck.PFD.display.colors.green)
                            .setVisible(0);
                        me._blink_count = 0;
                    }
                    return;
                }
                else {
                    se['AP-Status-text'].setVisible(ap_enabled);
                    me._blink_count = 0;
                }
            },
            hook: func {
                me._vertical_mode = globals.props.getNode("/autopilot/annunciator/vertical-mode", 1);
                me._pitch_setting = globals.props.getNode("/autopilot/settings/target-pitch-deg", 1);
                me._climb_setting = globals.props.getNode("/autopilot/settings/vertical-speed-fpm", 1);
                me._speed_setting = globals.props.getNode("/autopilot/settings/target-speed-kt", 1);
                me._vertical_mode_button = globals.props.getNode("/autopilot/vertical-mode-button", 1);
                me._lateral_mode_button = globals.props.getNode("/autopilot/lateral-mode-button", 1);
                me._ap_mode_button = globals.props.getNode("/autopilot/AP-mode-button", 1);
                me._ap_enabled = globals.props.getNode("/autopilot/annunciator/autopilot-enabled", 1);;
                me._fd_enabled = globals.props.getNode("/autopilot/annunciator/flight-director-enabled", 1);;

            },
            sendModeChange: func (value) {
                me._vertical_mode_button.setValue(value);
                me._lateral_mode_button.setValue(value);
                if (value == "AP") {
                    me._ap_mode_button.setValue(value);
                }
            },
            handleNoseUpDown : func(value) {
                var vertical_mode = me._vertical_mode.getValue();

                if (vertical_mode == "PIT")
                    me._pitch_setting.setValue(me._pitch_setting.getValue() + (value * 1));

                if (vertical_mode == "VS") {
                    me._climb_setting.setValue(me._climb_setting.getValue() + (value * 100));
                    setprop("/autopilot/annunciator/vertical-mode-target",
                        sprintf("%+ifpm", me._climb_setting.getValue())
                    );
                }

                if (vertical_mode == "FLC") {
                    me._speed_setting.setValue(me._speed_setting.getValue() - (value * 1));
                    setprop("/autopilot/annunciator/vertical-mode-target",
                        sprintf("%i kt", me._speed_setting.getValue())
                    );
                }
            },
            L: [
               func { me.sendModeChange('AP');  },
               func { me.sendModeChange('FD');  },
               func { setprop('/autopilot/settings/nav-mode-source', cdi.getValue('source')); me.sendModeChange('NAV'); },
               func { me.sendModeChange('ALT'); },
               func { me.sendModeChange('VS');  },
               func { me.sendModeChange('FLC'); },
            ],
            R: [
               func { me.sendModeChange('YD');  },
               func { me.sendModeChange('HDG'); },
               func { me.sendModeChange('APR'); },
               func { me.sendModeChange('VNV'); },
               func { me.handleNoseUpDown(1);   },
               func { me.handleNoseUpDown(-1);  },
            ],
        },
        STEC55X: {
            _aliases: {
                hdg:          afcs.getNode('heading-bug-deg'),
                alt:          afcs.getNode('selected-alt-ft'),
                NAVCourse:    cdi.getNode('course'),
                OBSNAVNeedle: cdi.getNode('course-deflection'),
            },
            hook : func {
                me.trimTarget = 0;
                foreach (var a; keys(me._aliases)) stec55x[a].alias(me._aliases[a]);
                setprop('/it-stec55x/input/ap-master-sw', 1);
            },
            updateDisplay: func {
                var se = flightdeck.PFD.display.screenElements;
                se['AP-Status-text'].setVisible(stec55x.rollMode  != -1 or stec55x.pitchMode != -1);
                se['YD-Status-text'].setVisible(stec55x.yaw.getValue() != -1);
                if (stec55x.rollMode  != -1) {
                    se['LATMOD-Active-text'].setVisible(1).setText('ROL');
                    var armed = '';
                    foreach (var m; [ 'NAV', 'CNAV', 'REV', 'CREV' ])
                        if (stec55x[m]) armed = m;
                    if (stec55x.roll.getValue() == 0) armed = 'HDG';
                    elsif (stec55x.roll.getValue() == 2) armed = 'GPS';
                    elsif (stec55x.APR_annun.getValue()) armed = 'APR';
                    se['LATMOD-Armed-text']
                        .setVisible(size(armed))
                        .setText(armed);
                }
                else {
                    se['LATMOD-Active-text'].setVisible(0);
                    se['LATMOD-Armed-text'].setVisible(0);
                }

                if (stec55x.pitchMode != 1) {
                    var armed     = '';
                    var active    = '';
                    var reference = '';
                    if (stec55x.ALT_annun.getBoolValue()) {
                        if (abs(data.alt - afcs.getValue('selected-alt-ft')) < 150) {
                            active    = 'ALT';
                            reference = sprintf('%5d ft', afcs.getValue('selected-alt-ft'));
                            armed     = 'ALTS'
                        }
                        else {
                            active    = 'ALT';
                            reference = sprintf('%5d ft', math.round(data.alt, 10));
                            armed     = 'ALT';
                        }
                    }
                    elsif (stec55x.VS_annun.getBoolValue()) {
                        active    = 'VS';
                        reference = sprintf('%s%4d fpm',
                                        utf8.chstr(stec55x.vs.getValue() > 0 ? 9650 : 9660),
                                        math.abs(math.round(stec55x.vs.getValue(), 10)));
                    }
                    elsif (stec55x.GSArmed.getBoolValue()) {
                        armed  = 'VPATH';
                        active = 'GS';
                    }
# TODO: ask Octal450 which prop or variable can be used here
#                    elsif (stec55x.???) {
#                        armed  = 'PIT';
#                        active = 'ALT';
#                        reference = sprintf("%d°", autopilot.systems.STEC55X.trim);
#                    }
                    se['VERMOD-Active-text'].setVisible(size(active)).setText(active);
                    se['VERMOD-Armed-text'].setVisible(size(armed)).setText(armed);
                    se['VERMOD-Reference-text'].setVisible(size(reference)).setText(reference);
                }
            },
            L: [
                func,
                func {
#                    var apfd_master_sw = '/it-stec55x/input/apfd-master-sw';
#                    setprop(apfd_master_sw, !getprop(apfd_master_sw));
                },
                func {
                    var _roll = stec55x.roll.getValue();
                    if (_roll == 1 or _roll == 2 or _roll == 4)
                        stec55x.roll.setValue(-1);
                    else {
                        stec55x.roll.setValue(1);
                        call(stec55x.button.NAV, [], nil, stec55x);
                    }
                },
                func {
#                    call(stec55x.button.ALT, [], nil, stec55x);
                },
                func {
#                    stec55x.vs.setValue(math.round(data.vsi, 100));
#                    call(stec55x.button.VS, [], nil, stec55x);
                },
                func,
            ],
            R: [
                func {
#                    var yaw_dumper_sw = '/it-stec55x/input/yaw-damper-sw';
#                    setprop(yaw_dumper_sw, !getprop(yaw_dumper_sw));
                },
                func {
                    if (stec55x.roll.getValue() == 0)
                        stec55x.roll.setValue(-1);
                    else
                        call(stec55x.button.HDG, [], nil, stec55x);
                },
                func {
#                    call(stec55x.button.APR, [], nil, stec55x);
                },
                func,
                func { # UP (trim)
#                    if (autopilot.systems.STEC55X.trimTarget > -15)
#                        autopilot.systems.STEC55X.trimTarget -= 1;
#                    fgcommand('property-assign', {property: '/it-stec55x/input/man-trim', value: -1});
#                    fgcommand('property-assign', {property: '/it-stec55x/input/man-trim', value:  0});
                },
                func { # DN (trim)
#                    if (autopilot.systems.STEC55X.trimTarget < 20)
#                        autopilot.systems.STEC55X.trimTarget += 1;
#                    fgcommand('property-assign', {property: '/it-stec55x/input/man-trim', value: 1});
#                    fgcommand('property-assign', {property: '/it-stec55x/input/man-trim', value: 0});
                },
            ],
        }
    }
};
