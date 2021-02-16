var annunciationsClass = {
    new: func {
        var m = { parents : [ annunciationsClass ] };
        m.registered = {}; # triggers identified by message
        m.active  = [];    # currently active warnings and alerts, sorted by emergency level
        m.devices = [];    # PFD displays

        foreach (var d; keys(flightdeck))
            if (flightdeck[d].role == 'PFD')
                append(m.devices, d);

        foreach (var warnings; alerts.getChildren('warnings'))
            foreach (var warning; warnings.getChildren('warning'))
                m.register(warning);

        data.timers.annunciations = maketimer(1.0, func call(m.activate, [], m));
        data.timers.annunciations.start();

        return m;
    },

    register: func (node) {
        me.registered[node.getValue('message')] = {
            trigger: compile(node.getValue('script')),
            node: node,
        };
    },

    del: func (message) {
        if (contains(me.registered, message))
            delete(me.registered, message);
        if (contains(me.active, message))
            delete(me.active, message);
    },

    activate: func {
        size(me.registered) or return;

        var score = {};

        foreach (var a; keys(me.registered))
            if (me.registered[a].trigger())
                score[me.registered[a].node.getValue('message')] = me.registered[a].node.getValue('level');

        if (size(score) > 1) {
            var sorted_scores = sort(keys(score), func (a, b) {
                if (score[a] <= score[b])
                    return 1; # greatest first
                else
                    return -1;
            });
        }
        else
            var sorted_scores = keys(score);

        me.active = sorted_scores;

        var levels_bg = [ 'lightgrey', 'white', 'red'    ];
        var levels_fg = [ 'black'    , 'black', 'yellow' ];

        if (size(me.active)) {
            var level = score[sorted_scores[0]];
            if (level > 2) level = 2;

            foreach (var d; me.devices) {
                flightdeck[d].display.screenElements['SoftKey11-bg']
                    .setColorFill(flightdeck[d].display.colors[levels_bg[level]]);
                flightdeck[d].display.screenElements['SoftKey11-text']
                    .setColor(flightdeck[d].display.colors[levels_fg[level]]);
                flightdeck[d].display.updateSoftKeys();
            }
        }
        else {
            foreach (var d; me.devices) {
                flightdeck[d].display.screenElements['SoftKey11-bg']
                    .setColorFill(flightdeck[d].display.colors.black);
                flightdeck[d].display.screenElements['SoftKey11-text']
                    .setColor(flightdeck[d].display.colors.lightgrey);
                flightdeck[d].display.updateSoftKeys();
            }
        }
    },
};
