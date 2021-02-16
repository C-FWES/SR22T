###
# Not Yet Implemented: just draw a warnig box during 3 seconds
var nyi = func (x) { gui.popupTip(x ~ ': not yet implemented', 3) }

###
# print message in terminal
var msg = func (str) { print('ZKV1000 >> ', str) }

###
# print message in popup
var msg_popup = func (str...) { gui.popupTip("ZKV1000\n" ~ str, 3) }

###
# just do nothing
var void = func { }

var alt = vs = vs_abs = ias = tas = pitch = roll = agl = stall = rpm = 0;
var getData = func {
    alt = math.abs(getprop('/instrumentation/altimeter/indicated-altitude-ft'));
    vs = getprop('/velocities/vertical-speed-fps') * 60; 
    ias = getprop('/instrumentation/airspeed-indicator/indicated-speed-kt');
    pitch = getprop('/orientation/pitch-deg');
    roll = getprop('/orientation/pitch-deg');
    agl = getprop('/position/altitude-agl-ft');
    stall = getprop('/sim/alarms/stall-warning');
    gear = getprop('/controls/gears/gear');
}

###
# returns DMS coordinates
# d is decimal longitude or latitude
# c should be one of E, W, S or N
# inspired from FG source: $FGSRC/src/Main/fg_props.cxx 
var DMS = func (d, c) {
    var deg = min = sec = 0.0;
    d = abs(d);
    deg = d + 0.05 / 3600;
    min = (deg - int(deg)) * 60;
    sec = (min - int(min)) * 60 - 0.049;
    return sprintf('%d %02d %04.1f %s', int(deg), int(min), abs(sec), c);
}

var time = {
    GMT : func {
        data.time = getprop('/sim/time/gmt-string');
    },

    UTC : func {
        data.time = sprintf('%02i:%02i:%02i',
                    getprop('/sim/time/utc/hour'),
                    getprop('/sim/time/utc/minute'),
                    getprop('/sim/time/utc/second'));
    },

    LCL : func {
        var utc_hour = getprop('/sim/time/utc/hour') + (getprop('/sim/time/local-offset') / 3600);
        if (utc_hour > 23) utc_hour -= 24;
        if (utc_hour < 0)  utc_hour += 24;
        data.time = sprintf('%02i:%02i:%02i',
                    utc_hour,
                    getprop('/sim/time/utc/minute'),
                    getprop('/sim/time/utc/second'));
    },

    RL : func {
        data.time = sprintf('%02i:%02i:%02i',
                    getprop('/sim/time/real/hour'),
                    getprop('/sim/time/real/minute'),
                    getprop('/sim/time/real/second'));
    },
};

# returns time + d (is seconds) formated HH:MM:SS
var HMS = func (hh, mm, ss, d = 0) {
    ss += d;

    if (ss > 59) {
        ss -= 60;
        mm += 1;
        if (mm > 59) {
            mm = 0;
            hh += 1;
        }
    }
    elsif (ss < 0) {
        if (mm > 0) {
            ss += 60;
            mm -= 1;
        }
        elsif (mm == 0 and hh > 0) {
            ss += 60;
            mm = 59;
            hh -= 1;
        }
        elsif (mm == 0 and hh == 0)
            ss = 0;
    }
    return sprintf('%02i:%02i:%02i', hh, mm, ss);
}
