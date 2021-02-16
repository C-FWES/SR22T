# vim: set foldmethod=marker foldmarker={{{,}}} :
var softkeysClass = {
    new : func (device) {
        var m = { parents: [ softkeysClass ] };
        m.device = device;
        m.path = [];
        m.colored = {};
        return m;
    },

    SoftKey : func (n, a) {
        # released key not yet managed
        if (a == 1)
            return;

        var key = me.device.display.screenElements[sprintf("SoftKey%02i-text",n)].get('text');
        if (key == '' or key == nil)
            return;

        var path = keyMap[me.device.role];
        foreach(var p; me.path) {
            if (contains(path, p))
                path = path[p];
            else
                break;
        }

        var bindings = me.bindings[me.device.role];
        foreach(var p; me.path) {
            if (contains(bindings, p))
                bindings = bindings[p];
            else
                break;
        }

        if (contains(path, key)) {
            append(me.path, key);
            if (contains(bindings, key))
                if (contains(bindings[key], 'hook'))
                    call(bindings[key].hook, [], me);
            me.device.display.updateSoftKeys();
        }
        elsif (contains(bindings, key)) {
            call(bindings[key], [], me);
            me.device.display.updateSoftKeys();
        }
        elsif (key == 'BACK') {
            pop(me.path);
            me.device.display.updateSoftKeys();
        }
        else {
            var list_path = '';
            foreach(var p; me.path) list_path ~= p ~ '/';
            print(me.device.role ~ ':' ~ list_path ~ key ~ ' : not yet implemented');
        }
    },

    bindings : {
        PFD : {
            ALERTS: func {
                id = 'ALERTS';
                if (!contains(me.device.windows.state, id)) {
                    var obj_infos = [
                        { text: sprintf('%i ALERT%s', size(annunciations.active), size(annunciations.active) > 1 ? 'S' : ''), type: 'title' },
                        { type: 'separator' }
                    ];
                    var firstEntry = 1;
                    var levels = [ 'INFO', 'WARNING', 'ALERT' ];
                    forindex (var order; annunciations.active) {
                        var level = annunciations.registered[annunciations.active[order]].node.getValue('level');
                        if (level > 2) level = 2;
                        append(obj_infos, {
                            text: sprintf('%02i - %-7s ', order + 1, levels[level]),
                            type: firstEntry ? 'selected' : 'editable',
                            scrollgroup: order,
                        });
                        append(obj_infos, {
                            text: annunciations.registered[annunciations.active[order]].node.getValue('message'),
                            type: 'normal|end-of-line',
                            scrollgroup: order,
                        });
                        firstEntry = 0;
                    }
                    me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.windows.draw( id, obj_infos, {lines: 4, columns: 2, rows: 1} );
                }
                else {
                    me.device.knobs.FmsInner = func;
                    me.device.knobs.FmsOuter = func;
                    me.device.buttons.ClearTMRREF();
                }
            },
            INSET: {
                OFF: func {
                    me.device.map.setVisible(0);
                    me.device.display.screenElements['PFD-Map-bg'].hide();
                },
                ROUTE: func {
                    call(me.bindings.PFD.INSET.declutter, ['INSETROUTE', 'route', 3], me);
                },
                TERRAIN: func {
                    call(me.bindings.PFD.INSET.declutter, ['INSETTERRAIN', 'tiles', 5], me);
                },
                NAVAIDS: {
                    ALL: func (root_id = 'INSETNAVAIDS') {
                        if (contains(me.colored, root_id ~ 'ALL'))
                            foreach (var n; [ 'ALL', 'VOR', 'DME', 'NDB', 'TACAN', 'APT' ])
                                delete(me.colored, root_id ~ n);
                        else
                            foreach (var n; [ 'ALL', 'VOR', 'DME', 'NDB', 'TACAN', 'APT' ])
                                me.colored[root_id ~ n] = 1;
                        me.device.display.updateSoftKeys();
                        foreach (var n; [ 'VOR', 'TACAN', 'NDB', 'DME' ])
                            me.device.map.layers.navaids._can[n]
                                .setVisible(contains(me.colored, root_id ~ n));
                        me.device.map.layers.navaids._can.airport
                            .setVisible(contains(me.colored, root_id ~ 'APT'));
                    },
                    VOR: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['INSETNAVAIDSVOR', 'VOR', 2], me);
                    },
                    TACAN: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['INSETNAVAIDSTACAN', 'TACAN', 3], me);
                    },
                    NDB: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['INSETNAVAIDSNDB', 'NDB', 4], me);
                    },
                    DME: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['INSETNAVAIDSDME', 'DME', 5], me);
                    },
                    APT: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['INSETNAVAIDSAPT', 'airport', 6], me);
                    },
                    declutter: func (id, type) {
                        if (contains(me.colored, id)) {
                            delete(me.colored, id);
                            if (me.device.role == 'PFD')
                                delete(me.colored, 'INSETNAVAIDSALL');
                            if (me.device.role == 'MFD')
                                delete(me.colored, 'MAPNAVAIDSALL');
                        }
                        else
                            me.colored[id] = 1;
                        me.device.display.updateSoftKeys();
                        me.device.map.layers.navaids._can[type]
                            .setVisible(contains(me.colored, id));
                    },
                },
                declutter: func (id, layer) {
                    if (contains(me.colored, id))
                        delete(me.colored, id);
                    else
                        me.colored[id] = 1;
                    me.device.display.updateSoftKeys();
                    me.device.map.layers[layer]
                        .setVisible(contains(me.colored, id));
                },
                hook : func {
                    me.device.display.screenElements['PFD-Map-bg'].show();
                    me.device.map.setVisible(1);
                    me.device.map.update();
                },
            },
            PFD: {
                'AOA/WIND' : {
                    AOA : {
                        'AOA ON' : func {
                            if (me.device.data['aoa-auto'])
                                return;
                            me.device.data.aoa = ! me.device.data.aoa;
                            foreach (var e; ['AOA', 'AOA-needle', 'AOA-text'])
                                me.device.display.screenElements[e]
                                    .setVisible(me.device.data.aoa);
                            me.device.display.screenElements['AOA-approach']
                                .setVisible(me.device.data.aoa and contains(data, 'approach-aoa'));
                            me.device.display.updateAOA();
                            me.device.display.setSoftKeyColor(5 ,me.device.data.aoa);
                            if (me.device.data.aoa)
                                me.colored['PFDAOA/WINDAOAAOA ON'] = 1;
                            else
                                delete(me.colored, 'PFDAOA/WINDAOAAOA ON');
                        },
                        'AOA AUTO' : func {
                            if (me.device.data.aoa)
                                return;
                            me.device.data['aoa-auto'] = ! me.device.data['aoa-auto'];
                            me.device.display.setSoftKeyColor(6 ,me.device.data['aoa-auto']);
                            if (me.device.data['aoa-auto']) {
                                me.colored['PFDAOA/WINDAOAAOA AUTO'] = 1;
                                if (!contains(me.device.timers, 'aoa'))
                                    me.device.timers.aoa = maketimer(1,
                                            func {
                                                var v = getprop('/gear/gear/position-norm') == 1
                                                    and getprop('/surfaces-positions/flap-pos-norm') != 0;
                                                foreach (var e; ['AOA', 'AOA-needle', 'AOA-text'])
                                                    me.device.display.screenElements[e]
                                                        .setVisible(v);
                                                me.device.display.screenElements['AOA-approach']
                                                    .setVisible(v and contains(data, 'approach-aoa'));
                                                me.device.display.updateAOA();
                                            }, me);
                                me.device.timers.aoa.start();
                            }
                            else {
                                delete(me.colored, 'PFDAOA/WINDAOAAOA AUTO');
                                me.device.timers.aoa.stop();
                                me.device.data.aoa = 0;
                                me.device.display.screenElements['AOA']
                                    .hide();
                            }
                        },
                        hook : func {
                            if (contains(data,'approach-aoa'))
                                me.device.display.screenElements['AOA-approach']
                                    .setRotation(-data['approach-aoa']/data['stall-aoa']*math.pi);
                        },
                    },
                    WIND : {
                        OPTN1 : func {
                            me.device.display._winddata_optn = 1;
                            me.device.display.screenElements['WindData'].show();
                            me.device.display.screenElements['WindData-OPTN1'].show();
                            me.device.display.screenElements['WindData-OPTN1-HDG'].show();
                            me.device.display.screenElements['WindData-OPTN2'].hide();
                            me.device.display.updateWindData();
                            me.device.display.setSoftKeyColor(2, 1);
                            me.colored['PFDAOA/WINDWINDOPTN1'] = 1;
                            me.device.display.setSoftKeyColor(3, 0);
                            delete(me.colored, 'PFDAOA/WINDWINDOPTN2');
                        },
                        OPTN2 : func {
                            me.device.display._winddata_optn = 2;
                            me.device.display.screenElements['WindData'].show();
                            me.device.display.screenElements['WindData-OPTN1'].hide();
                            me.device.display.screenElements['WindData-OPTN2'].show();
                            me.device.display.screenElements['WindData-OPTN2-symbol'].show();
                            me.device.display.screenElements['WindData-OPTN2-headwind'].show();
                            me.device.display.screenElements['WindData-OPTN2-crosswind'].show();
                            me.device.display.updateWindData();
                            me.device.display.setSoftKeyColor(2, 0);
                            delete(me.colored, 'PFDAOA/WINDWINDOPTN1');
                            me.device.display.setSoftKeyColor(3, 1);
                            me.colored['PFDAOA/WINDWINDOPTN2'] = 1;
                        },
                        OFF : func {
                            me.device.display._winddata_optn = 0;
                            me.device.display.screenElements['WindData'].hide();
                            me.device.display.screenElements['WindData-OPTN1'].hide();
                            me.device.display.screenElements['WindData-OPTN2'].hide();
                            me.device.display.setSoftKeyColor(2, 0);
                            delete(me.colored, 'PFDAOA/WINDWINDOPTN1');
                            me.device.display.setSoftKeyColor(3, 0);
                            delete(me.colored, 'PFDAOA/WINDWINDOPTN2');
                        },
                    },
                },
                BRG1 : func (brg = 1){
                    var source = 'brg' ~ brg ~ '-source';
                    var list = ['NAV' ~ brg, 'GPS', 'ADF', 'OFF'];
                    var index = std.Vector
                                   .new(list)
                                   .index(radios.getNode(source).getValue());
                    var next = (index == size(list) -1) ?  0 : index + 1;
                    radios.getNode(source).setValue(list[next]);
                    if (list[next] != 'OFF') {
                        me.device.display.setSoftKeyColor(brg == 1 ? 4 : 6, 1);
                        me.colored['PFDBRG' ~ brg] = 1;
                    }
                    else {
                        me.device.display.setSoftKeyColor(brg == 1 ? 4 : 6, 0);
                        delete(me.colored, 'PFDBRG' ~ brg);
                    }
                },
                BRG2 : func {
                    call(me.bindings.PFD.PFD.BRG1, [ 2 ], me);
                },
                'STD BARO' : func {
                    setprop('/instrumentation/altimeter/setting-inhg', 29.92);
                    me.device.display.updateBARO();
                    pop(me.path);
                    me.device.display.updateSoftKeys();
                },
                'ALT UNIT' : {
                    IN :  func {
                        data.settings.units.pressure = 'inhg';
                        me.device.display.updateBARO();
                    },
                    HPA : func {
                        data.settings.units.pressure = 'hpa';
                        me.device.display.updateBARO();
                    },
                },
            },
            XPDR: {
                STBY : func {
                    setprop('/instrumentation/transponder/ident', 0);
                    setprop('/instrumentation/transponder/knob-mode', 1);
                    radios.setValue('xpdr-mode', 'STBY');
                    me.device.display.updateXPDR();
                },
                ON : func {
                    setprop('/instrumentation/transponder/ident', 1);
                    setprop('/instrumentation/transponder/knob-mode', 4);
                    radios.setValue('xpdr-mode', 'ON');
                    me.device.display.updateXPDR();
                },
                ALT : func {
                    setprop('/instrumentation/transponder/ident', 1);
                    setprop('/instrumentation/transponder/knob-mode', 5);
                    radios.setValue('xpdr-mode', 'ALT');
                    me.device.display.updateXPDR();
                },
                VFR : func {
                    setprop('/instrumentation/transponder/id-code', '1200');
                    me.device.display.updateXPDR();
                },
                IDENT : func {
                    call(me.bindings.PFD.IDENT, [], me);
                },
                CODE : {
                    '0' : func (n = 0) {
                        if (radios.getValue('xpdr-tuning-fms-method'))
                            return;
                        me.device.display.timers.softkeys_inactivity.stop();
                        me.bindings.PFD.XPDR.CODE.inactivity.restart(me.device.display.softkeys_inactivity_delay);
                        # disable FMS knob entering method
                        me.device.knobs.FmsInner = void;
                        # When entering the code, the next softkey in sequence
                        # must be pressed within 10 seconds, or the entry is cancelled
                        # and restored to the previous code
                        if (!contains(me.bindings.PFD.XPDR.CODE, 'on_change_inactivity')) {
                            me.bindings.PFD.XPDR.CODE.on_change_inactivity = maketimer(10,
                                func {
                                    radios.setValue('xpdr-tuning-digit', 3);
                                    me.device.knobs.FmsInner = me.device.knobs.XPDRCodeSetDigits;
                                    me.device.knobs.FmsOuter = me.device.knobs.XPDRCodeNextDigits;
                                    call(me.bindings.PFD.XPDR.CODE.restore, [], me);
                                });
                            me.bindings.PFD.XPDR.CODE.on_change_inactivity.singleShot = 1;
                            me.bindings.PFD.XPDR.CODE.on_change_inactivity.start();
                        }
                        else
                            me.bindings.PFD.XPDR.CODE.on_change_inactivity.restart(10);
                        var tuning = radios.getNode('xpdr-tuning-digit');
                        var d = tuning.getValue();
                        setprop('/instrumentation/transponder/inputs/digit[' ~ d ~ ']', n);
                        if (d == 0) {
                            if (!contains(me.bindings.PFD.XPDR.CODE, 'on_change_auto_validation'))
                                me.bindings.PFD.XPDR.CODE.on_change_auto_validation = maketimer(5,
                                    func call(me.bindings.PFD.IDENT, [], me));
                            me.bindings.PFD.XPDR.CODE.on_change_auto_validation.singleShot = 1;
                            me.bindings.PFD.XPDR.CODE.on_change_auto_validation.start();
                        }
                        else {
                            d -= 1;
                            tuning.setValue(d);
                        }
                        me.device.display.updateXPDR();
                    },
                    '1' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 1 ], me);
                    },
                    '2' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 2 ], me);
                    },
                    '3' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 3 ], me);
                    },
                    '4' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 4 ], me);
                    },
                    '5' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 5 ], me);
                    },
                    '6' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 6 ], me);
                    },
                    '7' : func {
                        call(me.bindings.PFD.XPDR.CODE['0'], [ 7 ], me);
                    },
                    IDENT: func {
                        me.bindings.PFD.XPDR.CODE.inactivity.restart(me.device.display.softkeys_inactivity_delay);
                        me.device.display.timers.softkeys_inactivity.restart(me.device.display.softkeys_inactivity_delay);
                        call(me.bindings.PFD.IDENT, [], me);
                    },
                    BKSP: func {
                        if (radios.getValue('xpdr-tuning-fms-method'))
                            return;
                        if (contains(me.bindings.PFD.XPDR.CODE, 'on_change_inactivity'))
                            me.bindings.PFD.XPDR.CODE.on_change_inactivity.restart(10);
                        if (contains(me.bindings.PFD.XPDR.CODE, 'on_change_auto_validation'))
                                me.bindings.PFD.XPDR.CODE.on_change_auto_validation.stop();
                        var tuning = radios.getNode('xpdr-tuning-digit');
                        var d = tuning.getValue();
                        if (d < 3) {
                            d += 1;
                            tuning.setValue(d);
                        }
                        me.device.display.updateXPDR();
                    },
                    BACK : func (inactive = 0) {
                        call(me.bindings.PFD.XPDR.CODE.restore, [], me);
                        pop(me.path);
                        call(me.bindings.PFD.XPDR.CODE.exit, [me.path], me);
                    },
                    restore : func {
                        setprop('/instrumentation/transponder/id-code',
                            sprintf('%s', radios.getValue('xpdr-backup-code')));
                        me.device.display.updateXPDR();
                    },
                    exit : func (p) {
                        if (contains(me.bindings.PFD.XPDR.CODE, 'inactivity')) # does not exists if IDENT pressed from top-level
                            me.bindings.PFD.XPDR.CODE.inactivity.stop();
                        radios.removeChild('xpdr-tuning-digit', 0);
                        radios.removeChild('xpdr-backup-code', 0);
                        radios.removeChild('xpdr-tuning-fms-method', 0);
                        me.path = p;
                        me.device.display.updateXPDR();
                        me.device.display.updateSoftKeys();
                        me.device.knobs.FmsInner = void;
                        me.device.knobs.FmsOuter = void;
                        me.device.display.timers.softkeys_inactivity.restart(me.device.display.softkeys_inactivity_delay);
                    },
                    hook : func {
                        # this level has its own timer as we may need to revert changes, and got different timers
                        me.device.display.timers.softkeys_inactivity.stop();
                        me.bindings.PFD.XPDR.CODE.inactivity = maketimer(
                            me.device.display.softkeys_inactivity_delay,
                            func call(me.bindings.PFD.XPDR.CODE.BACK, [], me));
                        me.bindings.PFD.XPDR.CODE.inactivity.singleShot = 1;
                        me.bindings.PFD.XPDR.CODE.inactivity.start();
                        var tuning = radios.getValue('xpdr-tuning-digit');
                        if (tuning == nil) {
                            radios.getNode('xpdr-tuning-digit', 1).setValue(3);
                            radios.getNode('xpdr-backup-code', 1).setValue(getprop('/instrumentation/transponder/id-code'));
                            radios.getNode('xpdr-tuning-fms-method', 1).setValue(0);
                            me.device.display.updateXPDR();
                        }
                        me.device.knobs.FmsInner = me.device.knobs.XPDRCodeSetDigits;
                        me.device.knobs.FmsOuter = me.device.knobs.XPDRCodeNextDigits;
                    },
                },
            },
            IDENT : func {
                if (radios.getValue('xpdr-mode') == 'STBY')
                    return;
                setprop('/instrumentation/transponder/ident', 1);
                me.bindings.PFD.XPDR.ident = maketimer(18,
                        func {
                            setprop('/instrumentation/transponder/ident', 0);
                            me.device.display.updateXPDR();
                        });
                me.bindings.PFD.XPDR.ident.singleShot = 1;
                me.bindings.PFD.XPDR.ident.start();
                call(me.bindings.PFD.XPDR.CODE.exit, [], me);
            },
            OBS : func {
                if (cdi.getValue('source') != 'GPS')
                    return;
                var cmd  = props.globals.getNode('/instrumentation/gps/command');
                var mode = getprop('/instrumentation/gps/mode');
                if (mode == 'dto') mode = 'direct';
                if (mode != 'obs') {
                    data._previous_gps_mode = mode;
                    cmd.setValue('obs');
                    aliases.GPS.course = 'selected-course-deg';
                    setprop('/instrumentation/gps/selected-course-deg', int(getprop('/instrumentation/gps/desired-course-deg')));
                    me.colored['OBS'] = 1;
                }
                else {
                    cmd.setValue(data._previous_gps_mode);
                    delete(data, '_previous_gps_mode');
                    aliases.GPS.course = 'desired-course-deg';
                    me.colored['OBS'] = 0;
                }
                me.device.display.setSoftKeyColor(4, me.colored['OBS'], 1);
            },
            CDI : func {
                var list = ['OFF'];
                if (getprop('/instrumentation/gps/route-distance-nm') != nil)
                    append(list, 'GPS');
                if (getprop('/instrumentation/nav/in-range') != nil)
                    append(list, 'NAV1');
                if (getprop('/instrumentation/nav[1]/in-range') != nil)
                    append(list, 'NAV2');
                var index = std.Vector
                               .new(list)
                               .index(cdi.getNode('source').getValue());
                var next = (index == size(list) -1) ?  0 : index + 1;
                cdi.getNode('source').setValue(list[next]);
                CDIfromSOURCE(list[next]);
                me.device.display.updateCDI();
            },
            'TMR/REF' : func {
                if (!contains(me.device.windows.state, 'TMR/REF')) {
                    var GenericTimer = func (id, selected) {
                        var action = me.device.windows.state[id].objects[selected].text;
                        if (action == 'START?') {
                            me.device.data.TMRrevert = 0;
                            me.device.data.TMRlast = getprop('/sim/time/elapsed-sec') - 1;
                            me.device.data.TMRreset = me.device.windows.state[id].objects[selected - 2].text;
                            me.device.data.TMRtimer = maketimer(1, func {
                                    var (hh, mm, ss) = split(':',
                                            me.device.windows.state[id].objects[selected - 2].text);
                                    var direction = -1;
                                    if ((me.device.windows.state[id].objects[selected - 1].text
                                            ==
                                        me.device.windows.state[id].objects[selected - 1].choices[0])
                                    or me.device.data.TMRrevert)
                                        direction = 1;
                                    var now = getprop('/sim/time/elapsed-sec');
                                    var dt = int(now - me.device.data.TMRlast) * direction;
                                    me.device.data.TMRlast = now;
                                    var val = HMS(hh, mm, ss, dt);
                                    me.device.windows.state[id].objects[selected - 2].text = val;
                                    me.device.windows.window[id ~ '-' ~ (selected -2)]
                                        .setText(val);
                                    if (val == '00:00:00' and direction == -1)
                                        me.device.data.TMRrevert = 1;
                                }, me);
                            me.device.data.TMRtimer.start();
                            action = 'STOP?';
                        }
                        elsif (action == 'STOP?') {
                            me.device.data.TMRtimer.stop();
                            action = 'RESET?';
                        }
                        elsif (action == 'RESET?') {
                            action = 'START?';
                            if ((me.device.windows.state[id].objects[selected - 1].text
                                        ==
                                me.device.windows.state[id].objects[selected - 1].choices[1])
                            and !me.device.data.TMRrevert)
                                var val = me.device.data.TMRreset;
                            else
                                var val = '00:00:00';
                            me.device.windows.state[id].objects[selected - 2].text = val;
                            me.device.windows.window[id ~ '-' ~ (selected -2)]
                                .setText(val);
                        }
                        me.device.windows.window[me.device.windows.selected]
                            .setText(action);
                        me.device.windows.state[id].objects[selected].text = action;
                    };
                    var obj_infos = [ # objects infos
                            {text: 'REFERENCES', type: 'title'},
                            {type: 'separator'},
                            {text: 'TIMER', type: 'normal'},
                            {text: '00:00:00', type: 'selected|time', },
                            {text: '  UP >', type: 'editable', choices: ['  UP >', '<DOWN ']},
                            {text: 'START?', type: 'editable|end-of-line', callback: func (id, selected) GenericTimer(id, selected)},
                            {type: 'separator'},
                    ];
                    var scrollgroup = 0;
                    if (size(keys(data.Vspeeds))) {
                        var sort_smallest_first = func (a, b) {
                            if   (data.Vspeeds[a] <  data.Vspeeds[b]) return -1;
                            elsif(data.Vspeeds[a] == data.Vspeeds[b]) return 0;
                            else return 1;
                        }
                        foreach (var V; sort(keys(data.Vspeeds), sort_smallest_first)) {
                            append(obj_infos, {
                                text: sprintf('%-7s', V),
                                type: 'normal',
                                scrollgroup: scrollgroup
                            });
                            append(obj_infos, {
                                text: sprintf('%3i%s', data.Vspeeds[V], units.speed.from_kt == 1 ? 'KT' : 'km/h'),
                                type: (V == 'Vne' ? 'normal' : 'editable') ~ '|immediate',
                                scrollgroup: scrollgroup,
                                range: {min: 0, max: 999},
                                format: '%3i' ~ (units.speed.from_kt == 1 ? 'KT' : 'km/h'),
                                _v: V,
                                callback: func (id, selected,) {
                                    string.scanf(string.trim(me.device.windows.state[id].objects[selected].text, -1),
                                                 '%3u' ~ (units.speed.from_kt == 1 ? 'KT' : 'km/h'), var r = []);
                                    data.Vspeeds[me.device.windows.state[id].objects[selected]._v] = r[0];
                                }

                            });
                            append(obj_infos, {
                                text: me.device.data[V ~ '-visible'] ? '   ON >' : '< OFF  ',
                                type: 'editable|immediate|end-of-line',
                                scrollgroup: scrollgroup,
                                _v: V,
                                choices: ['   ON >', '< OFF  '],
                                callback: func (id, selected) {
                                    var Vspeed = me.device.windows.state[id].objects[selected]._v;
                                    me.device.data[Vspeed ~ '-visible'] =
                                        me.device.windows.state[id].objects[selected].text
                                        ==
                                        me.device.windows.state[id].objects[selected].choices[0];
                                }
                            });
                            scrollgroup += 1;
                        }
                        append(obj_infos, {type: 'separator'});
                    }
                    append(obj_infos,
                            {text: 'MINIMUMS', type: 'normal'},
                            {text: '   OFF   >', type: 'editable', choices: ['   OFF   >', '<  BARO  >','<TEMP COMP'], callback: func},
                            {text: ' 1000FT', type: 'editable', format: '% 5iFT', factor: 100, callback: func}
                          );
                    me.device.windows.draw(
                        'TMR/REF',
                        {x: 720, y: 535, w: 300, l: 5, sep: scrollgroup ? 3 : 2},
                        obj_infos,
                        scrollgroup > 2 ? { lines : 3, columns : 3 } : nil
                    );
                    me.device.knobs.FmsInner = me.device.knobs.MenuSettings;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.buttons.ENT = me.device.buttons.ValidateTMRREF;
                    me.device.buttons.FMS = me.device.buttons.ValidateTMRREF;
                    me.device.buttons.CLR = me.device.buttons.ClearTMRREF;
                }
                else {
                    me.device.buttons.ClearTMRREF();
                }
            },
            NRST: {
                _displayNearest: func (type, where) {
                    var id = 'PFD NRST';
                    me.device.display.updateSoftKeys();
                    me.device.windows.del(id);
                    var results = [];
                    var list = [];
                    if (type == 'apt') {
                        results = findAirportsWithinRange(100);
                    }
                    else {
                        results = findNavaidsWithinRange(100, type);
                    }
                    var norm_360 = func (a) return math.periodic(0, 360, a);
                    if    (where == 'OMNI')  var side = -1;
                    elsif (where == 'FRONT') var side = norm_360(data.hdg);
                    elsif (where == 'RIGHT') var side = norm_360(data.hdg + 90);
                    elsif (where == 'LEFT')  var side = norm_360(data.hdg - 90);
                    elsif (where == 'REAR')  var side = norm_360(data.hdg + 180);
                    foreach (var n; results) {
                        var (course, dist) = courseAndDistance(n);
                        if (side > -1) {
                            var angle = 180 - abs(abs(course - side) - 180);
                            if (angle > 50)
                                continue;
                        }
                        append(list, [n, course, dist]);
                        if (size(list) == 5)
                            break;
                    }
                    var obj_infos = [
                        { text: sprintf('NEAREST %s (%s)', string.uc(type), where), type: 'title' },
                        { type: 'separator' }
                    ];
                    var firstEntry = 1;
                    foreach (var n; list) {
                        append(obj_infos, {
                            text: sprintf('%s (%s)', n[0].id, n[0].name),
                            type: (firstEntry ? 'selected' : 'editable') ~ '|end-of-line',
                            dto: n[0],
                        });
                        if (type == 'vor') {
                            var idx = size(obj_infos) - 1;
                            obj_infos[idx]._freq = n[0].frequency;
                            obj_infos[idx].callback = func (id, selected) radios.getNode('nav-freq-mhz').setValue(me.device.windows.state[id].objects[selected]._freq / 100);
                        }
                        append(obj_infos, {
                            text: sprintf('%s %03i° %3iNM', utf8.chstr(9658), n[1], n[2]),
                            type: 'normal|end-of-line'
                        });
                        firstEntry = 0;
                    }
                    me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                    me.device.buttons.CLR = func {
                        me.device.windows.del(id);
                        me.device.knobs.FmsOuter = func;
                        me.device.knobs.FmsInner = func;
                        me.device.buttons.MENU = me.device.buttons.GlobalParams;
                        foreach (var b; ['ENT', 'CLR'])
                            me.device.buttons[b] = func;
                    }
                    me.device.buttons.MENU = func;
                    me.device.windows.draw( id, {autogeom: 1}, obj_infos );
                },
                _displayNearestCOMM: func (where) {
                    var id = 'PFD NRST';
                    me.device.display.updateSoftKeys();
                    me.device.windows.del(id);
                    var results = [];
                    var ATIS_list = [];
                    var TRAFFIC_list = [];
                    var TWR_list = [];
                    results = findAirportsWithinRange(100);
                    var norm_360 = func (a) return math.periodic(0, 360, a);
                    if    (where == 'OMNI')  var side = -1;
                    elsif (where == 'FRONT') var side = norm_360(data.hdg);
                    elsif (where == 'RIGHT') var side = norm_360(data.hdg + 90);
                    elsif (where == 'LEFT')  var side = norm_360(data.hdg - 90);
                    elsif (where == 'REAR')  var side = norm_360(data.hdg + 180);
                    foreach (var r; results) {
                        var (course, dist) = courseAndDistance(r);
                        if (side > -1) {
                            var bearing = 180 - abs(abs(course - side) - 180);
                            if (bearing > 50)
                                continue;
                        }
                        foreach (var c; r.comms()) {
                            if (size(ATIS_list) < 4
                            and (string.match(c.ident, '*ATIS*') or string.match(c.ident, '*A[SW]OS*')))
                                append(ATIS_list, [r.id, c.frequency, course, dist]);

                            if (size(TWR_list) < 4
                            and string.match(c.ident, '*TWR*'))
                                append(TWR_list, [r.id, c.frequency, course, dist]);

                            if (size(TRAFFIC_list) < 4
                            and (string.match(c.ident, '*CTAF*') or string.match(c.ident, '*UNICOM*') or string.match(c.ident, '*MULTICOM*')))
                                append(TRAFFIC_list, [r.id, c.frequency, course, dist]);
                        }
                    }
                    var obj_infos = [];
                    firstEntry = 1;
                    if (size(ATIS_list) > 0) {
                        append(obj_infos, {text: 'ATIS', type: 'title'});
                        append(obj_infos, {type: 'separator'});
                        foreach (var atis; ATIS_list) {
                            append(obj_infos, {
                                text: atis[0],
                                _freq: atis[1],
                                type: firstEntry ? 'selected' : 'editable',
                                callback: func (id, selected) radios.getNode('comm-freq-mhz').setValue(me.device.windows.state[id].objects[selected]._freq),
                            });
                            append(obj_infos, {
                                text: sprintf(' (%.3fMHz) %3i° %2iNM', atis[1], atis[2], atis[3]),
                                type: 'normal|end-of-line'
                            });
                            firstEntry = 0;
                        }
                    }
                    if (size(TRAFFIC_list) > 0) {
                        append(obj_infos, {text: 'TRAFFIC', type: 'title'});
                        append(obj_infos, {type: 'separator'});
                        foreach (var traffic; TRAFFIC_list) {
                            append(obj_infos, {
                                text: traffic[0],
                                _freq: traffic[1],
                                type: firstEntry ? 'selected' : 'editable',
                                callback: func (id, selected) radios.getNode('comm-freq-mhz').setValue(me.device.windows.state[id].objects[selected]._freq),
                            });
                            append(obj_infos, {
                                text: sprintf(' (%.3fMHz) %3i° %2iNM', traffic[1], traffic[2], traffic[3]),
                                type: 'normal|end-of-line'
                            });
                            firstEntry = 0;
                        }
                    }
                    if (size(TWR_list) > 0) {
                        append(obj_infos, {text: 'TOWER', type: 'title'});
                        append(obj_infos, {type: 'separator'});
                        foreach (var tower; TWR_list) {
                            append(obj_infos, {
                                text: tower[0],
                                _freq: tower[1],
                                type: firstEntry ? 'selected' : 'editable',
                                callback: func (id, selected) radios.getNode('comm-freq-mhz').setValue(me.device.windows.state[id].objects[selected]._freq),
                            });
                            append(obj_infos, {
                                text: sprintf(' (%.3fMHz) %3i° %2iNM', tower[1], tower[2], tower[3]),
                                type: 'normal|end-of-line'
                            });
                            firstEntry = 0;
                        }
                    }
                    me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.buttons.MENU = func;
                    me.device.buttons.CLR = func {
                        me.device.windows.del(id);
                        me.device.knobs.FmsOuter = func;
                        me.device.knobs.FmsInner = func;
                        me.device.buttons.MENU = me.device.buttons.GlobalParams;
                        foreach (var b; ['ENT', 'CLR'])
                            me.device.buttons[b] = func;
                    }
                    me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                    me.device.windows.draw( id, {autogeom: 1}, obj_infos );
                },
############################################################################################################
# THIS CODE SHOULD REPLACE THE LINES BELOW (in new()), but it makes all call with the same args (apt, RIGHT)
############################################################################################################
#        if (m.device.role == 'PFD')
#            foreach (var dir; keyMap.PFD.NRST.texts) {
#                m.bindings.PFD.NRST[dir] = {};
#                foreach (var type; keyMap.PFD.NRST.OMNI.texts) {
#                    m.bindings.PFD.NRST[dir][type] = func {
#                        call(m.bindings.PFD.NRST._displayNearest, [string.lc(type), dir], m)
#                    };
#                }
#            }
############################################################################################################
                OMNI: {
                    APT: func { call(me.bindings.PFD.NRST._displayNearest, ['apt', 'OMNI'], me) },
                    VOR: func { call(me.bindings.PFD.NRST._displayNearest, ['vor', 'OMNI'], me) },
                    NDB: func { call(me.bindings.PFD.NRST._displayNearest, ['ndb', 'OMNI'], me) },
                    FIX: func { call(me.bindings.PFD.NRST._displayNearest, ['fix', 'OMNI'], me) },
                    COMM:func { call(me.bindings.PFD.NRST._displayNearestCOMM,    ['OMNI'], me) },
                },
                FRONT: {
                    APT: func { call(me.bindings.PFD.NRST._displayNearest, ['apt', 'FRONT'], me) },
                    VOR: func { call(me.bindings.PFD.NRST._displayNearest, ['vor', 'FRONT'], me) },
                    NDB: func { call(me.bindings.PFD.NRST._displayNearest, ['ndb', 'FRONT'], me) },
                    FIX: func { call(me.bindings.PFD.NRST._displayNearest, ['fix', 'FRONT'], me) },
                    COMM:func { call(me.bindings.PFD.NRST._displayNearestCOMM,    ['FRONT'], me) },
                },
                RIGHT: {
                    APT: func { call(me.bindings.PFD.NRST._displayNearest, ['apt', 'RIGHT'], me) },
                    VOR: func { call(me.bindings.PFD.NRST._displayNearest, ['vor', 'RIGHT'], me) },
                    NDB: func { call(me.bindings.PFD.NRST._displayNearest, ['ndb', 'RIGHT'], me) },
                    FIX: func { call(me.bindings.PFD.NRST._displayNearest, ['fix', 'RIGHT'], me) },
                    COMM:func { call(me.bindings.PFD.NRST._displayNearestCOMM,    ['RIGHT'], me) },
                },
                REAR: {
                    APT: func { call(me.bindings.PFD.NRST._displayNearest, ['apt', 'REAR'], me) },
                    VOR: func { call(me.bindings.PFD.NRST._displayNearest, ['vor', 'REAR'], me) },
                    NDB: func { call(me.bindings.PFD.NRST._displayNearest, ['ndb', 'REAR'], me) },
                    FIX: func { call(me.bindings.PFD.NRST._displayNearest, ['fix', 'REAR'], me) },
                    COMM:func { call(me.bindings.PFD.NRST._displayNearestCOMM,    ['REAR'], me) },
                },
                LEFT: {
                    APT: func { call(me.bindings.PFD.NRST._displayNearest, ['apt', 'LEFT'], me) },
                    VOR: func { call(me.bindings.PFD.NRST._displayNearest, ['vor', 'LEFT'], me) },
                    NDB: func { call(me.bindings.PFD.NRST._displayNearest, ['ndb', 'LEFT'], me) },
                    FIX: func { call(me.bindings.PFD.NRST._displayNearest, ['fix', 'LEFT'], me) },
                    COMM:func { call(me.bindings.PFD.NRST._displayNearestCOMM,    ['LEFT'], me) },
                },
            },
        },
        MFD : {
            ENGINE: {
                FUEL: {
                    UNDO: func {
                        pop(me.path);
                        me.device.display.updateSoftKeys();
                    },
                    ENTER: func {
                        pop(me.path);
                        me.device.display.updateSoftKeys();
                    },
                },
                ENGINE: func {
                    me.path = [];
                    me.device.display.updateSoftKeys();
                },
            },
            CHKLIST : {
                _showCheckList: func (id, selected) {
                    var tabulate = func (l, r, t = 3, c = '.') {
                        var s = '';
                        for (var i = 0; i < (l - r) + t; i += 1) s ~= c;
                        return s;
                    }

                    var groupIndex     = me.device.windows.state[id].objects[selected].groupIndex;
                    var checklistIndex = me.device.windows.state[id].objects[selected].checklistIndex;

                    if (contains(me.device.windows.state[id].objects[selected], 'pageIndex'))
                        var pageIndex = me.device.windows.state[id].objects[selected].pageIndex;
                    else
                        var pageIndex = -1;

                    var title = '';
                    if (contains(me.device.windows.state[id].objects[selected], 'checklistTitle'))
                        var title = me.device.windows.state[id].objects[selected].checklistTitle;
                    else
                        var title = me.device.windows.state[id].objects[selected].text;

                    me.device.windows.del(id);

                    if (groupIndex < 0)
                         checklistNode = props.globals.getNode("/sim/checklists")
                                    .getChild('checklist', checklistIndex);
                    else
                         checklistNode = props.globals.getNode("/sim/checklists")
                                    .getChild("group", groupIndex)
                                    .getChild('checklist', checklistIndex);

                    var pages = checklistNode.getChildren('page');
                    if (size(pages) == 0)
                        append(pages, checklistNode);

                    if (size(pages) and pageIndex == -1)
                        pageIndex = 0;

                    _previous_text = ' < PREVIOUS ';
                    _next_text     = ' NEXT > ';

                    var obj_infos = [];
                    var length = size(_previous_text ~ _next_text);
                    var length_cache = [];
                    if (size(pages))
                        checklistNode = pages[pageIndex];

                    append(obj_infos, {
                        text: sprintf('%s%s',
                                      title,
                                      size(pages) > 1 ? sprintf(' %d / %d',
                                                                pageIndex + 1,
                                                                size(pages)) : ''),
                        type: 'title'
                    });

                    append(obj_infos, {type: 'separator'});

                    forindex (var i; checklistNode.getChildren('item')) {
                        var l = size(checklistNode.getChild('item', i).getValue('name'));
                        if (checklistNode.getChild('item', i).getChild('value') != nil)
                            l += size(checklistNode.getChild('item', i).getValue('value'));
                        append(length_cache, l);
                        if (l > length)
                            length = l;
                    }

                    forindex (var i; checklistNode.getChildren('item')) {
                        var text = pages[pageIndex].getChild('item', i).getValue('name');
                        var item_val = '';
                        if (pages[pageIndex].getChild('item', i).getChild('value') != nil)
                            item_val = pages[pageIndex].getChild('item', i).getValue('value');
                        if (item_val != '')
                            text ~= tabulate(length, length_cache[i]);
                        text ~= item_val;

                        append(obj_infos, {
                            text: text,
                            groupIndex: groupIndex,
                            checklistIndex: checklistIndex,
                            pageIndex: pageIndex,
                            type: 'normal|end-of-line'
                        });
                    }

                    append(obj_infos, {type: 'separator'});

                    if (pageIndex and size(pages))
                        append(obj_infos, {
                                text: _previous_text,
                                groupIndex: groupIndex,
                                checklistIndex: checklistIndex,
                                pageIndex: pageIndex - 1,
                                checklistTitle: title,
                                type: (pageIndex + 1 < size(pages)) ? 'editable' : 'selected',
                                callback: func (id, selected) call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [id, selected], me)
                        });
                    else
                        append(obj_infos, {
                            text: tabulate(length, size(_next_text), 0, ' '),
                            type: 'normal'
                        });

                    if (pageIndex + 1 < size(pages)) {
                        if (pageIndex and size(pages))
                            append(obj_infos, {
                                text: tabulate(length, size(_previous_text ~ _next_text), 0, ' '),
                                type: 'normal',
                            });
                        append(obj_infos, {
                                text: _next_text,
                                groupIndex: groupIndex,
                                checklistIndex: checklistIndex,
                                pageIndex: pageIndex + 1,
                                checklistTitle: title,
                                type: 'selected|end-of-line',
                                callback: func (id, selected) call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [id, selected], me)
                        });
                    }

                    me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                    me.device.buttons.CLR = func {
                        me.device.windows.del(id);
                        me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
                        me.device.knobs.FmsInner = func;
                        foreach (var b; ['ENT', 'CLR'])
                            me.device.buttons[b] = func;
                        me.device.buttons.MENU = func;
                    }
                    me.device.windows.draw( id, {autogeom: 1}, obj_infos );
                },
                LIST: func {
                    # nested function as checklist lists may be organized by group
                    var listChecklists = func (id, selected) {
                        var checklists = [];
                        var firstEntry = 1;
                        if (selected < 0) {
                            checklists = props.globals.getNode("/sim/checklists")
                                            .getChildren('checklist');
                            var groupIndex = -1;
                        }
                        else {
                            var groupIndex = me.device.windows.state[id].objects[selected].groupIndex;
                            me.device.windows.del(id);
                            checklists = props.globals.getNode("/sim/checklists")
                                            .getChild("group", groupIndex)
                                            .getChildren('checklist');
                        }
                        var checklistsQty = size(checklists);
                        var obj_infos = [];

                        if (checklistsQty) {
                            forindex (var c; checklists) {
                                if (string.uc(checklists[c].getValue('title')) == 'EMERGENCY') {
                                    checklistsQty -= 1;
                                    continue;
                                }
                                var title = checklists[c].getValue('title');
                                append(obj_infos, {
                                    text: title,
                                    groupIndex: groupIndex,
                                    checklistIndex: c,
                                    checklistTitle: title,
                                    type: (firstEntry ? 'selected' : 'editable') ~ '|end-of-line',
                                    callback: func (id, selected) call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [id, selected], me)
                                });
                                if (checklistsQty == 1) { # see comments below for groups
                                    call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [groupIndex, 0], me);
                                    return;
                                }
                                elsif (checklistsQty == 0)
                                    return;
                                firstEntry = 0;
                            }
                        }

                        id ~= ' CHECKLISTS';
                        me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                        me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                        me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                        me.device.buttons.CLR = func {
                            me.device.windows.del(id);
                            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
                            me.device.knobs.FmsInner = func;
                            foreach (var b; ['ENT', 'CLR'])
                                me.device.buttons[b] = func;
                            me.device.buttons.MENU = func;
                        }
                        me.device.windows.draw(id, {autogeom: 1}, obj_infos);
                    }

                    foreach(var windowId; keys(me.device.windows.state))
                        me.device.windows.del(windowId);

                    var windowId = 'CHKLIST LIST';
                    var obj_infos = [];
                    var firstEntry = 1;
                    var groups = props.globals.getNode("/sim/checklists").getChildren("group");
                    var groupsQty = size(groups);

                    if (groupsQty) {
                        forindex (var g; groups) {
                            # emergency checklists are listed in their own menu
                            if (string.uc(groups[g].getValue('name')) == 'EMERGENCY') {
                                groupsQty -= 1;
                                continue;
                            }
                            # the key groupIndex isn't used by the display system
                            # we use it to keep the information of group node's index
                            append(obj_infos, {
                                text: groups[g].getValue('name'),
                                groupIndex: g,
                                type: (firstEntry ? 'selected' : 'editable') ~ '|end-of-line',
                                callback: func (id, selected) listChecklists(id, selected) });
                            firstEntry = 0;
                            # if there are only one group left, let display it directly
                            if (groupsQty == 1) {
                                listChecklists(windowId, 0);
                                return;
                            }
                            elsif (groupsQty == 0) {
                                return;
                            }
                        }
                    }
                    else {
                        listChecklists(windowId, -1);
                        return;
                    }

                    me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                    me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                    me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                    me.device.buttons.CLR = func {
                        me.device.windows.del(windowId);
                        me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
                        me.device.knobs.FmsInner = func;
                        foreach (var b; ['ENT', 'CLR'])
                            me.device.buttons[b] = func;
                        me.device.buttons.MENU = func;
                    }
                    me.device.windows.draw(windowId, {autogeom: 1}, obj_infos);
                },
                EMERGCY: func {
                    # nested function as checklist lists may be organized by group
                    var listChecklists = func (groupIndex) {
                        var checklists = [];
                        var firstEntry = 1;
                        if (groupIndex == -1)
                            checklists = props.globals.getNode("/sim/checklists")
                                            .getChildren('checklist');
                        else
                            checklists = props.globals.getNode("/sim/checklists")
                                            .getChild("group", groupIndex)
                                            .getChildren('checklist');
                        var checklistsQty = size(checklists);
                        var obj_infos = [];
                        var firstEntry = 1;

                        if (checklistsQty) {
                            forindex (var c; checklists) {
                                if (groupIndex < 0 and string.uc(checklists[c].getValue('title')) != 'EMERGENCY') {
                                    checklistsQty -= 1;
                                    continue;
                                }
                                append(obj_infos, {
                                    text: checklists[c].getValue('title'),
                                    groupIndex: groupIndex,
                                    checklistIndex: c,
                                    type: (firstEntry ? 'selected' : 'editable') ~ '|end-of-line',
                                    callback: func (id, selected) call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [id, selected], me)
                                });
                                firstEntry = 0;
                            }
                        }
                        id = 'EMERGENCY CHECKLISTS';
                        me.device.knobs.FmsInner = me.device.knobs.NavigateMenu;
                        me.device.knobs.FmsOuter = me.device.knobs.NavigateMenu;
                        me.device.buttons.ENT    = me.device.buttons.ValidateTMRREF;
                        me.device.buttons.CLR = func {
                            me.device.windows.del(id);
                            me.device.knobs.FmsOuter = me.device.knobs.MFD_select_page_group;
                            me.device.knobs.FmsInner = func;
                            foreach (var b; ['ENT', 'CLR'])
                                me.device.buttons[b] = func;
                            me.device.buttons.MENU = func;
                        }
                        me.device.windows.draw(id, {autogeom: 1}, obj_infos);
                        if (checklistsQty == 1) { # see comments below for groups
                            call(me.device.softkeys.bindings.MFD.CHKLIST._showCheckList, [groupIndex, 0], me);
                            return;
                        }
                        elsif (checklistsQty == 0)
                            call(me.device.buttons.CLR, [0], me);
                            return;
                    }

                    var windowId = 'CHKLIST EMERGCY';
                    if (contains(me.device.windows.state, windowId))
                        me.device.windows.del(windowId);

                    var groups = props.globals.getNode("/sim/checklists").getChildren("group");

                    var emergency_group_found = 0;
                    if (size(groups)) {
                        forindex (var g; groups) {
                            # emergency checklists are listed in their own menu
                            # we support only one emergency checklists group named EMERGENCY (case insensitive)
                            if (string.uc(groups[g].getValue('name')) != 'EMERGENCY')
                                continue;
                            listChecklists(g);
                            emergency_group_found = !emergency_group_found;
                            break;
                        }
                    }

                    if (!emergency_group_found)
                        listChecklists(-1);
                },
                EXIT: func {
                    me.path = [];
                    me.device.display.updateSoftKeys();
                },
            },
            MAP: {
                TRAFFIC: func {
                    call(me.bindings.PFD.INSET.declutter, ['MAPTRAFFIC', 'tcas', 0], me);
                },
                ROUTE: func {
                    call(me.bindings.PFD.INSET.declutter, ['MAPROUTE', 'route', 1], me);
                },
                TERRAIN: func {
                    call(me.bindings.PFD.INSET.declutter, ['MAPTERRAIN', 'tiles', 3], me);
                },
                TOPO: func {
                    call(me.bindings.PFD.INSET.declutter, ['MAPTOPO', 'topo', 7], me);
                },
                NAVAIDS: {
                    ALL: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.ALL, [ 'MAPNAVAIDS' ], me);
                    },
                    VOR: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['MAPNAVAIDSVOR', 'VOR', 2], me);
                    },
                    TACAN: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['MAPNAVAIDSTACAN', 'TACAN', 3], me);
                    },
                    NDB: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['MAPNAVAIDSNDB', 'NDB', 4], me);
                    },
                    DME: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['MAPNAVAIDSDME', 'DME', 5], me);
                    },
                    APT: func {
                        call(me.bindings.PFD.INSET.NAVAIDS.declutter, ['MAPNAVAIDSAPT', 'airport', 6], me);
                    },
                },
            },
        },
    },
};

var keyMap = {
# softkeys map for PFD and MFD {{{1
# PFD {{{2
    PFD : {
        first : 1,
        texts : ['INSET', 'SENSOR', 'PFD', 'OBS', 'CDI', 'DME', 'XPDR', 'IDENT', 'TMR/REF', 'NRST' ],
        INSET : {
            texts : ['OFF', '', '', 'ROUTE', '', 'TERRAIN', 'NAVAIDS', 'METAR'],
            NAVAIDS : {
                first : 2,
                texts : ['VOR', 'TACAN', 'NDB', 'DME', 'APT', '', 'ALL'],
            },
        },
        SENSOR : {
            first : 2,
            texts : [ 'ADC1', 'ADC2', '', 'AHRS1', 'AHRS2'],
        },
        PFD : {
            texts : [ 'SYN VIS', 'DFLTS', 'AOA/WIND', 'DME', 'BRG1', 'HSI FMT', 'BRG2', '', 'ALT UNIT', 'STD BARO' ],
            'SYN VIS' : {
                texts : [ 'PATHWAY', 'SYN TERR', 'HR2NHDG', 'APTSIGNS', 'FPM'],
            },
            'AOA/WIND' : {
                first : 4,
                texts : ['AOA', 'WIND'],
                AOA : {
                    first : 5,
                    texts : ['AOA ON', 'AOA AUTO'],
                },
                WIND : {
                    first : 2,
                    texts : ['OPTN1', 'OPTN2', '', 'OFF'],
                },
            },
            'HSI FMT' : {
                first : 6,
                texts : ['360 HSI', 'ARC HSI'],
            },
            'ALT UNIT' : {
                first : 5,
                texts : ['METERS', '', 'IN', 'HPA'],
            },
        },
        XPDR : {
            first : 2,
            texts : ['STBY', 'ON', 'ALT', '', 'VFR', 'CODE', 'IDENT'],
            CODE : {
                texts : ['0', '1', '2', '3', '4', '5', '6', '7', 'IDENT', 'BKSP'],
            },
        },
        NRST : {
            first : 4,
            texts : ['OMNI', 'REAR', 'FRONT', 'LEFT', 'RIGHT', 'RANGE'],
            RANGE : {
                first : 7,
                texts : ['MIN', 'MAX' ],
                MIN : { first: 3, texts : ['0NM',   '10NM',  '30NM',  '50NM'] },
                MAX : { first: 3, texts : ['200NM', '150NM', '100NM', '50NM'] },
            },
            OMNI : { texts: ['NDB', 'FIX', 'VOR', 'APT', '', '', '', '', '', 'COMM'] }, # that will be mirrored later
        },
    },
#}}}2
# MFD {{{2
    MFD : {
        texts : ['ENGINE', '', 'MAP', '', '', '', '', '', '', 'DCLTR', 'SHW CHRT', 'CHKLIST'],
        MAP : {
            texts : ['TRAFFIC', 'ROUTE', 'TOPO', 'TERRAIN', 'NAVAIDS', '','', '', '', '', 'BACK'],
            NAVAIDS : {
                first : 2,
                texts : ['VOR', 'TACAN', 'NDB', 'DME', 'APT', '', 'ALL', '', '', 'BACK' ],
            },
        },
        CHKLIST : {
            texts : ['ENGINE', '', '', '', 'LIST', 'DONE', '', '', '', '', 'EXIT', 'EMERGCY'],
        },
        ENGINE : {
            texts : ['ENGINE', 'ANTI-ICE', '', 'DCLTR', '', 'ASSIST', '', '', '', '', 'FUEL'],
            'ANTI-ICE' : {
                texts : ['LEFT', 'AUTO', 'RIGHT', '', '', '', '', '', '', '', '', 'BACK'],
            },
            FUEL : {
                first : 1,
                texts : ['FULL', 'TABS', '', '', '', '', '', '', '', 'UNDO', 'ENTER'],
            },
        },
    },
#}}}2
};
if (data['stall-aoa'] == 9999)
    keyMap.PFD.PFD['AOA/WIND'].texts = ['', 'WIND'];
if (props.globals.getNode('/sim/checklists') == nil) {
    keyMap.MFD.texts[11] = '';
    delete(keyMap.MFD, 'CHKLIST');
}
foreach (var d; ['FRONT', 'REAR', 'LEFT', 'RIGHT']) {
    keyMap.PFD.NRST[d] = keyMap.PFD.NRST.OMNI;
}
#}}}1
