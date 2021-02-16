# Nasal files to be loaded at start
# the order could be important as some files need other one to be loaded first
files_to_load = [
    'lib.nas',     # some useful functions, should stay first loaded
    'radios.nas',  # all about radios COMM, NAV, XPDR
    'knobs.nas',   # handles knobs
    'buttons.nas', # handles knobs and buttons
    'softkeys.nas',# handles softkeys and menus items
    'maps/route.nas',
    'maps/navaids.nas',
    'maps/tiles.nas',
    'maps/tcas.nas',
    'maps/topo.nas',
    'map.nas',     # moves the maps
    'display.nas',
    'menu.nas',    # manage windows
    'core.nas',    # the scheduler and switch on button
    'afcs.nas',    # Automatic Flight Control System
    'annunciations.nas',  # in flight tests
];
#    'routes.nas',  # manages flightplans and routes
#    'display.nas', # display messages and popups
#    'infos.nas',   # get informations from environment
#    'mud.nas',     # displays simple embedded GUI (Multi-Use Display)

var flightdeck = {};

var autopilot = {};

var annunciations = {};

var units = {
    speed : {
        from_kt  : 1,
        from_kmh : MPS2KT * 3.6,
    },
    altitude : {
        from_ft : 1,
        from_m  : M2FT,
    },
    vspeed : {
        from_fpm : 1,
        from_mpm : M2FT,
    },
    distance : {
        from_m : M2NM / 1000,
        from_nm : 1,
    },
    temperature : {
        from_C : func (c) return c,
        from_F : func (f) return (f -32) / 1.8,
    },
    volume: {
        from_l: 1,
        from_gal: 3.78541178,
        from_m3: 1000,
    },
};

var data = { # set of data common to all devices
    roll : 0,
    pitch : 0,
    vsi : 0,
    ias : 0,
    alt : 0,
    hdg : 0,
    wow : 1,
    lat : 0,
    lon : 0,
    aoa : 0,
    time : '23:59:59',
    fpSize : 0,
    tcas: [],
    tcas_level: 0,
    Vspeeds : {},
    settings: {
        units: {
            pressure: 'inhg',
            altitude: 'ft',
            speed: 'knots',
            distance: 'nm',
            vertical: 'fpm',
        },
        time: {
            label: 'GMT',
            actual: '  GMT >',
        },
    },
    timers : {
        '20Hz': maketimer (
            0.05,
            func {
                data.roll = getprop('/orientation/roll-deg');
                data.pitch = getprop('orientation/pitch-deg');
                data.vsi = getprop('/instrumentation/vertical-speed-indicator/indicated-speed-fpm') * units.vspeed.from_fpm;
                data.ias = getprop('/velocities/airspeed-kt') * units.speed.from_kt;
                data.alt = getprop('/instrumentation/altimeter/indicated-altitude-ft') * units.altitude.from_ft;
                data.hdg = getprop('/orientation/heading-deg');
                data.aoa = getprop('/orientation/alpha-deg');
            }
        ),
        '1Hz': maketimer (
            1,
            func {
                data.wow = getprop('/gear/gear/wow');
                data.lat = getprop('/position/latitude-deg');
                data.lon = getprop('/position/longitude-deg');
            }
        ),
    },
    listeners : {},
};

var zkv = cdi = radios = alerts = infos = cursors = afcs = eis = misc = nil;

var init_props = func {
    zkv = props.globals.getNode('/instrumentation/zkv1000',1);
    foreach (var d; zkv.getChildren())
        if (d.getNode('status') != nil)
            flightdeck[d.getName()] = nil;
    zkv.getNode('emission',1).setDoubleValue(0.5);
    zkv.getNode('body-emission',1).setDoubleValue(0.0);
    zkv.getNode('body-texture',1).setValue('');
    zkv.getNode('display-brightness-norm',1).setDoubleValue(0.5);
    zkv.getNode('lightmap',1).setIntValue(0);
    if (zkv.getNode('size-factor').getValue() == nil)
        zkv.getNode('size-factor',1).setDoubleValue(1.0);
    if (zkv.getValue('flightplans') != nil and io.stat(zkv.getValue('flightplans')) == "dir")
        data.flightplans = zkv.getValue('flightplans');
    else
        data.flightplans = getprop('/sim/fg-home') ~ '/Export';

    radios = zkv.getNode('radios', 1);
    radios.getNode('nav1-selected',1).setIntValue(0);
    radios.getNode('nav1-standby',1).setIntValue(0);
    radios.getNode('nav2-selected',1).setIntValue(0);
    radios.getNode('nav2-standby',1).setIntValue(0);
    radios.getNode('nav-tune',1).setIntValue(0);
    radios.getNode('nav-freq-mhz',1).alias('/instrumentation/nav/frequencies/standby-mhz');
    radios.getNode('comm1-selected',1).setIntValue(1);
    radios.getNode('comm2-selected',1).setIntValue(0);
    radios.getNode('comm-tune',1).setIntValue(0);
    radios.getNode('comm-freq-mhz',1).alias('/instrumentation/comm/frequencies/standby-mhz');
    radios.getNode('xpdr-mode',1).setValue('GND');
    radios.getNode('brg1-source',1).setValue('OFF');
    radios.getNode('brg2-source',1).setValue('OFF');

    cdi = zkv.getNode('cdi', 1);
    cdi.getNode('source', 1).setValue('OFF');
    cdi.getNode('no-flag', 1).setBoolValue(0);
    cdi.getNode('FROM-flag', 1).alias('no-flag');
    cdi.getNode('TO-flag', 1).alias('no-flag');
    cdi.getNode('course', 1);
    cdi.getNode('course-deflection', 1);
    cdi.getNode('radial', 1);
    cdi.getNode('in-range', 1);

    alerts = zkv.getNode('alerts',1);
    alerts.getNode('traffic-proximity',1).setIntValue(0);
    alerts.getNode('marker-beacon', 1).setIntValue(0);
    alerts.getNode('warning', 1).setBoolValue(0);
    alerts.getNode('alert', 1).setBoolValue(0);
    alerts.getNode('message', 1).setValue('');
    foreach (var v; alerts.getChildren())
        if (string.match(v.getName(), 'V[a-z0-9]*'))
            data.Vspeeds[v.getName()] = v.getValue();

    var aoa = alerts.getValue('stall-aoa');
    data['stall-aoa'] = (aoa == nil or aoa == 0) ? 9999 : aoa;
    aoa = alerts.getValue('approach-aoa');
    if (aoa != nil)
        data['approach-aoa'] = aoa;

    afcs = zkv.getNode('afcs',1);
    afcs.getNode('fd-bars-visible',1).setBoolValue(0);
    afcs.getNode('alt-bug-visible',1).setBoolValue(0);
    afcs.getNode('heading-bug-deg',1).setDoubleValue(int(getprop('/orientation/heading-magnetic-deg')));
    afcs.getNode('target-pitch-deg',1).setDoubleValue(0.0);
    afcs.getNode('selected-alt-ft',1).setIntValue(2000);
    afcs.getNode('selected-alt-ft-diff',1).setDoubleValue(0.0);
    afcs.getNode('selected-ias-kt-diff',1).setDoubleValue(0.0);
    afcs.getNode('vertical-speed-fpm',1).setDoubleValue(0.0);
    afcs.getNode('roll-armed', 1).setBoolValue(0);
    afcs.getNode('pitch-armed', 1).setBoolValue(0);
    afcs.getNode('roll-armed-mode-text',1).setValue('');
    afcs.getNode('roll-active-mode-text',1).setValue('');
    afcs.getNode('roll-armed-mode',1).setIntValue(0);
    afcs.getNode('roll-active-mode',1).setIntValue(0);
    afcs.getNode('roll-active-mode-blink',1).setBoolValue(0);
    afcs.getNode('pit-armed-mode-text',1).setValue('');
    afcs.getNode('pit-active-mode-text',1).setValue('');
    afcs.getNode('pit-armed-mode',1).setIntValue(0);
    afcs.getNode('pit-active-mode',1).setIntValue(0);
    afcs.getNode('pit-active-mode-blink',1).setBoolValue(0);
    afcs.getNode('route',1);

    data.flightplans = getprop('/sim/fg-home') ~ '/Export';

    misc = zkv.getNode('misc',1);
    misc.getNode('alt-setting-inhg',1).setDoubleValue(getprop('/instrumentation/altimeter/setting-inhg'));

    eis = zkv.getNode('eis',1);
    eis.getNode('fuel-qty-at-start', 1).setValue(
        getprop('/consumables/fuel/tank/level-gal_us')
      + getprop('/consumables/fuel/tank/level-gal_us'));

    var tiles_defaults = {
        # see https://www.wikimedia.org/wiki/Maps
        server: 'maps.wikimedia.org',
        type:   'osm-intl',
        apikey: '',
        format: 'png',
        template: 'https://{server}/{type}/{z}/{x}/{y}.{format}{apikey}',
    };
    foreach (var v; keys(tiles_defaults)) {
        var val = getprop('/sim/online-tiles-' ~ v);
        data['tiles-' ~ v] = val != nil ? val : tiles_defaults[v];
    }

    props.globals.getNode('/instrumentation/transponder/id-code',1).setIntValue(1200);
    props.globals.getNode('/instrumentation/transponder/serviceable',1).setBoolValue(1);
    props.globals.getNode('/autopilot/settings/heading-bug-deg', 1).alias(afcs.getNode('heading-bug-deg').getPath());
    props.globals.getNode('/autopilot/settings/target-alt-ft',1).alias(afcs.getNode('selected-alt-ft').getPath());
    props.globals.getNode('/autopilot/settings/target-speed-kt',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/settings/vertical-speed-fpm',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/internal/target-pitch-deg',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/internal/flc-altitude-pitch-deg',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/internal/flc-airspeed-pitch-deg',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/internal/target-roll-deg',1).setDoubleValue(0.0);
    props.globals.getNode('/autopilot/locks/pitch',1).setValue('');
    props.globals.getNode('/autopilot/locks/roll',1).setValue('');
    props.globals.getNode('/autopilot/locks/passive-mode', 1).setIntValue(1);

    data.zkv1000_reldir = io.dirname(getprop('/nasal/zkv1000/file'));
    data.zkv1000_dir = string.normpath(
            io.dirname(getprop('/sim/aircraft-dir'))
            ~ '/'
            ~ string.replace(data.zkv1000_reldir, split('/', data.zkv1000_reldir)[0], '')
        ) ~ '/';
}

var load_nasal = func {
    var nasal_dir = data.zkv1000_dir ~ 'Nasal/';
    for (var i = 0; i < size(files_to_load); i += 1)
        io.load_nasal(nasal_dir ~ files_to_load[i], 'zkv1000');
    files_to_load = nil;
}

var load_multikey = func {
    fgcommand('loadxml', props.Node.new({
        'filename': data.zkv1000_dir ~ 'Systems/multikey.xml',
        'targetnode': '/input/keyboard/'
    }));
    multikey.init();
}

var load_settings = func {
    var settings_file = getprop('/sim/fg-home') ~ '/aircraft-data/zkv1000.xml';
    if (io.stat(settings_file) != nil) {
        fgcommand('loadxml', props.Node.new({ filename: settings_file, targetnode: zkv.getNode('save', 1).getPath() }));
        var xmlsettings = zkv.getNode('save/' ~ getprop('/sim/aircraft'));
        if (xmlsettings != nil) {
            foreach (var domain; keys(units))
                foreach (var from; keys(units[domain])) {
                    if (xmlsettings.getNode(domain) != nil) {
                        var unit_value = xmlsettings.getNode(domain).getValue(from);
                        if (unit_value != nil) {
                            if (typeof(units[domain][from]) == 'scalar')
                                units[domain][from] = unit_value;
                            if (typeof(units[domain][from]) == 'func') {
                                units[domain][from] = compile(unit_value);
                                units[domain][from](0);
                            }
                        }
                    }
                }
            data.settings.units.pressure = xmlsettings.getNode('pressure').getValue();
        }
        zkv.getNode('save').remove();
    }
    foreach (var V; keys(data.Vspeeds))
        data.Vspeeds[V] *= units.speed.from_kt;
}

var zkv1000_init = func {
    removelistener(init);
    init_props();
    load_settings();
    load_multikey();
    load_nasal();
    msg('loaded');
    if (zkv.getValue('auto-power')) {
        var prop = zkv.getNode('serviceable',1).getPath();
        data.listeners[prop] = setlistener(prop, zkv1000.powerOn, 0, 0);
    }
}

var init = setlistener('/sim/signals/fdm-initialized', zkv1000_init, 0, 0);
