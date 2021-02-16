var xpdr_digits = 1;
var xpdr_id_timer = 0;
var tofromflag = nil;

var radios_list = [
    '/instrumentation/nav/frequencies/standby-mhz',
    '/instrumentation/nav[1]/frequencies/standby-mhz',
    '/instrumentation/nav/frequencies/selected-mhz',
    '/instrumentation/nav[1]/frequencies/selected-mhz',
    '/instrumentation/comm/frequencies/standby-mhz',
    '/instrumentation/comm[1]/frequencies/standby-mhz',
    '/instrumentation/comm/frequencies/selected-mhz',
    '/instrumentation/comm[1]/frequencies/selected-mhz',
];

var setNavTune = func {
    var freq = radios.getNode('nav-freq-mhz', 1);
    freq.unalias();
    freq.alias(radios_list[radios.getValue('nav-tune')]);
}

var setCommTune = func {
    var freq = radios.getNode('comm-freq-mhz', 1);
    freq.unalias();
    freq.alias(radios_list[radios.getValue('comm-tune') + 4]);
}

var aliases = {
    NAV : {
        'in-range' : 'in-range',
        'course'   : 'radials/selected-deg',
        'course-deflection' : 'heading-needle-deflection',
        'FROM-flag' : 'from-flag',
        'TO-flag' : 'to-flag',
        'radial' : 'radials/reciprocal-radial-deg',
    },
    GPS : {
        'course' : 'desired-course-deg',
        'course-deflection' : 'wp/wp[1]/course-error-nm',
        'FROM-flag': 'wp/wp[1]/from-flag',
        'TO-flag': 'wp/wp[1]/to-flag',
    }
};

var CDIfromSOURCE = func (source) {
    if (source == 'OFF') {
# all the aliases of GPS are included in NAV too
        foreach (var a; keys(aliases['NAV']))
            cdi.getNode(a).unalias();
    }
    else {
        var s = (source == 'GPS') ? 'gps' : 'nav[' ~ (right(source, 1) - 1) ~ ']';
        foreach (var a; keys(aliases[left(source, 3)])) {
            cdi.getNode(a).unalias();
            cdi.getNode(a).alias('/instrumentation/' ~ s ~ '/' ~ aliases[left(source, 3)][a]);
        }
    }
}

foreach (var r; radios_list) props.globals.getNode(r ~ '-dec',1).setIntValue(0);
