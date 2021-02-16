# This is most an example than a really efficient EIS
# power % is throttle %
# assumes that there are two tanks with equals quantity...
displayClass.showEIS = func (groups) {
    canvas.parsesvg(me.screen, data.zkv1000_reldir ~ 'Models/EIS/single-prop.svg');
    append(groups.show, 'EIS', 'POWER-pointer', 'FUEL-RIGHT-pointer', 'FUEL-LEFT-pointer');
    append(groups.text,
            'RPM-text', 'EGT-text', 'CHT-text', 'FUEL-USED-text',
            'FUEL-FLOW-text', 'MAN-Hg-text', 'POWER-PERCENT-text',
            'RPM-text', 'BUS-V-text', 'BATT-text', 'PSI-text',
            'OIL-TEMP-text'
        );
};

displayClass.updateEIS = func {
# displays Engine Informations System
    var running = getprop('/engines/engine/running');
    if (running != nil) {
        var power = getprop('/controls/engines/engine/throttle') * running;
        me.screenElements['POWER-pointer']
            .setRotation(D2R * 140 * power);
        me.screenElements['POWER-PERCENT-text']
            .setText(sprintf('% 3u', power * 100));
        me.screenElements['RPM-text']
            .setText(sprintf(math.round(getprop('/engines/engine/rpm'), 50)));
        me.screenElements['MAN-Hg-text']
            .setText(sprintf('%.1d', getprop('/engines/engine/mp-inhg')));
        me.screenElements['FUEL-FLOW-text']
            .setText(sprintf('%.1f', getprop('/engines/engine/fuel-flow-gph')));
        if (math.mod(me._eis_count, 10) == 0) {
            var psi = getprop('/engines/engine/oil-pressure-psi');
            me.screenElements['PSI-text']
                .setText(psi == nil ? '--' : sprintf('%u', psi));
            me.screenElements['OIL-TEMP-text']
                .setText(sprintf('%i', getprop('/engines/engine/oil-temperature-degf')));
            var full = eis.getValue('fuel-qty-at-start');
            var right = getprop('/consumables/fuel/tank/level-gal_us');
            var left = getprop('/consumables/fuel/tank[1]/level-gal_us');
            var used_fuel = full - (right + left);
            me.screenElements['FUEL-USED-text']
                .setText(sprintf('%.1d', used_fuel > 0 ? used_fuel : 0));
            me.screenElements['FUEL-RIGHT-pointer']
                .setTranslation(
                        0,
                        (1 - right / (full/2)) * 80
                    );
            me.screenElements['FUEL-LEFT-pointer']
                .setTranslation(
                        0,
                        (1 - left / (full/2)) * 80
                    );
            me.screenElements['BUS-V-text']
                .setText(sprintf('%.1i', getprop('/systems/electrical/outputs/bus')));
            me.screenElements['BATT-text']
                .setText(sprintf('%+i', getprop('/systems/electrical/amps')));
            var cht = getprop('/engines/engine/cht-degf');
            me.screenElements['CHT-text']
                .setText(cht == nil ? '--' : sprintf('%i', cht));
            me.screenElements['EGT-text']
                .setText(sprintf('%i', getprop('/engines/engine/egt-degf')));
        }
    }
    settimer(func me.updateEIS(), 0.2);
    me._eis_count += 1;
};

displayClass._eis_count = 0;
