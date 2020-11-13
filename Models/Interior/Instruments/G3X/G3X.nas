# Garmin G3X Simulation
# reference: https://support.garmin.com/en-US/?partNumber=G3X-TCERT-05&tab=manuals

var G3X_only = nil;
var G3X_display = nil;
var page = "only";
var G3X_flight_counter = 0;
var G3X_flight_counter_stop = 0;
var G3X_up_counter = 0;
var G3X_down_counter = 0;
var alt_scale_factor = 0.472; #constant
setprop("/engines/engine[0]/rpm", 0);
setprop("/instrumentation/transponder/inputs/digitnbr", 1);
setprop("/instrumentation/transponder/inputs/ident-btn", 0);
setprop("/instrumentation/transponder/inputs/ident-btn-2", 0);
setprop("/instrumentation/G3X/start", 0);
setprop("/instrumentation/G3X/stop", 0);
setprop("/instrumentation/G3X/func", 1);
setprop("/systems/electrical/volts", 0);
setprop("/test", 0);

var volts = props.globals.getNode("/systems/electrical/volts", 1);

var comm1_act = props.globals.getNode("/instrumentation/comm/frequencies/selected-mhz", 1);
var comm1_sby = props.globals.getNode("/instrumentation/comm/frequencies/standby-mhz", 1);

var engine  = props.globals.getNode("/engines/engine[0]", 1);
var eng_rpm = engine.getNode("rpm", 1);
var eng_mp  = engine.getNode("mp-inhg", 1);
var eng_ff  = engine.getNode("fuel-flow-gph", 1);
var eng_ot  = engine.getNode("oil-temperature-degf", 1);
var eng_op  = engine.getNode("oil-pressure-psi", 1);
var eng_egt = engine.getNode("egt-degf", 1);

var hdg_bug = props.globals.getNode("/instrumentation/heading-indicator/heading-bug-deg", 1);
var hdg_ind = props.globals.getNode("/instrumentation/heading-indicator/indicated-heading-deg", 1);

var xpdr_code = props.globals.getNode("/instrumentation/transponder/id-code", 1);
var xpdr_mode = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode", 1);
var xpdr_ident = props.globals.getNode("/instrumentation/transponder/ident", 1);

var fuel_l = props.globals.getNode("/consumables/fuel/tank[0]/level-norm", 1);
var fuel_r = props.globals.getNode("/consumables/fuel/tank[1]/level-norm", 1);

var oat_c = props.globals.getNode("/environment/temperature-degc", 1);

var ias = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt", 1);
var ias10 = props.globals.getNode("/instrumentation/pfd/asi-10", 1);
var ias100 = props.globals.getNode("/instrumentation/pfd/asi-100", 1);
var tas = props.globals.getNode("/instrumentation/airspeed-indicator/true-speed-kt", 1);
var gs  = props.globals.getNode("/velocities/groundspeed-kt", 1);

var ai_roll = props.globals.getNode("orientation/roll-deg",1);
var ai_pitch = props.globals.getNode("orientation/pitch-deg",1);
var ai_ss = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid", 1);

var alt_ft = props.globals.getNode("instrumentation/altimeter/indicated-altitude-ft", 1);
var alt10000 = props.globals.getNode("/instrumentation/PFD/alt-10000", 1);
var alt1000  = props.globals.getNode("/instrumentation/PFD/alt-1000", 1);
var alt100   = props.globals.getNode("/instrumentation/PFD/alt-100", 1);
var alt_bug  = props.globals.getNode("/instrumentation/PFD/altitude-bug", 1);
var alt_qnh  = props.globals.getNode("/instrumentation/altimeter/setting-hpa", 1);

var vs_fpm = props.globals.getNode("/instrumentation/vertical-speed-indicator/indicated-speed-fpm", 1);

var wind_deg = props.globals.getNode("/environment/wind-from-heading-deg", 1);
var wind_kt  = props.globals.getNode("/environment/wind-speed-kt", 1);

var nav_in_range = props.globals.getNode("/instrumentation/nav[0]/in-range", 1);
var loc_deflection = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm", 1);
var nav_rad = props.globals.getNode("/instrumentation/nav/radials/target-radial-deg", 1);
var gs_in_range  = props.globals.getNode("/instrumentation/nav[0]/gs-in-range", 1);
var gs_deflection = props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm", 1);

var clock=[
	props.globals.getNode("/instrumentation/clock/local-hour", 1),
	props.globals.getNode("/instrumentation/clock/indicated-hour", 1),
	props.globals.getNode("/instrumentation/clock/indicated-min", 1),
	props.globals.getNode("/instrumentation/clock/indicated-sec", 1),];

#roundToNearest function used for alt tape, thanks @Soitanen (737-800)!
var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}


var canvas_G3X_base = {
	init: func(canvas_group, file) {
		
		var font_mapper = func(family, weight) {
			#return "LiberationFonts/LiberationMono-Bold.ttf";
		};

		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		
		 var svg_keys = me.getKeys();
		 
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}
		
		me.h_trans = me["horizon"].createTransform();
		me.h_rot = me["horizon"].createTransform();


		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (volts.getValue() > 15 ) {
			G3X_only.page.show();
			G3X_only.update();
		} else {
			G3X_only.page.hide();
		}
	},
};
	
	
var canvas_G3X_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_G3X_only , canvas_G3X_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["COM1Act","COM1Sby","RPM","compass","compass.text","compass.text.1","compass.text.2","compass.text.3","compass.text.4","compass.text.5","compass.text.6","compass.text.7","compass.text.8","compass.text.9","compass.text.10","compass.text.11","compass.text.12","heading","XPDR.code","XPDR.mode","XPDR.ident","fuelL","fuelR","oil.F","oil.PSI","ff.GPH","radial","OAT","GS","TAS","asi.10","asi.100","asi.rollingdigits","asi.tape","horizon","fd","ball","altTapeScale","altTextHigh1","altTextHigh2","altTextHigh3","altTextHigh4","altTextHigh5","altTextHigh6","altTextHigh7","altTextHigh8","altTextHigh9","altTextHigh10","altTextLow1", "altTextLow2", "altTextLow3","altTextLow4","altTextLow5","altTextLow6","altTextLow7","altTextLow8","altTextLow9",
		"altTextHighSmall2","altTextHighSmall3","altTextHighSmall4","altTextHighSmall5","altTextHighSmall6","altTextHighSmall7","altTextHighSmall8","altTextHighSmall9","altTextHighSmall10",
	"altTextLowSmall1","altTextLowSmall2","altTextLowSmall3","altTextLowSmall4","altTextLowSmall5","altTextLowSmall6","altTextLowSmall7","altTextLowSmall8","altTextLowSmall9","alt.rollingdigits","alt.10000","alt.1000","alt.100", "hdg.bug", "hdg.bug.deg", "alt.bug", "alt.bug_small", "RPM.needle", "manin", "manin.needle", "alt.bug_scale", "alt.setting", "lcl_time", "VS.pointer", "VS.value", "wind.speed", "wind.dir", "wind.pointer", "loc.scale", "loc.pointer", "gs.scale", "gs.pointer","egt.degf"];
	},
	update: func() {
		me["COM1Act"].setText(sprintf(comm1_act.getValue()));
		me["COM1Sby"].setText(sprintf(comm1_sby.getValue()));
	
		
		var hdg_bug_v = hdg_bug.getValue();
		var hdg = hdg_ind.getValue();
		var hdg_bug_diff = hdg - hdg_bug_v;
		me["compass"].setRotation(hdg*-0.01744);
		me["compass.text"].setRotation(hdg*-D2R);
		me["compass.text.1"].setRotation(hdg*(D2R));
		me["compass.text.2"].setRotation(hdg*(D2R));
		me["compass.text.3"].setRotation(hdg*(D2R));
		me["compass.text.4"].setRotation(hdg*(D2R));
		me["compass.text.5"].setRotation(hdg*(D2R));
		me["compass.text.6"].setRotation(hdg*(D2R));
		me["compass.text.7"].setRotation(hdg*(D2R));
		me["compass.text.8"].setRotation(hdg*(D2R));
		me["compass.text.9"].setRotation(hdg*(D2R));
		me["compass.text.10"].setRotation(hdg*(D2R));
		me["compass.text.11"].setRotation(hdg*(D2R));
		me["compass.text.12"].setRotation(hdg*(D2R));
		me["hdg.bug"].setRotation(hdg_bug_diff*(-D2R));
		me["heading"].setText(sprintf("%3d", math.round(hdg)));
		me["radial"].setText(sprintf("%3d", math.round(nav_rad.getValue())));
		me["hdg.bug.deg"].setText(sprintf("%3d", math.round(hdg_bug_v)));
		

		me["XPDR.code"].setText(sprintf("%4d",xpdr_code.getValue()));
		var XPDRmode=xpdr_mode.getValue();
		if(XPDRmode==0){
			me["XPDR.mode"].setText("OFF");
		}else if(XPDRmode==1){
			me["XPDR.mode"].setText("SBY");
		}else if(XPDRmode==2){
			me["XPDR.mode"].setText("TST");
		}else if(XPDRmode==3){
			me["XPDR.mode"].setText("GND");
		}else if(XPDRmode==4){
			me["XPDR.mode"].setText("ON");
		}else if(XPDRmode==5){
			me["XPDR.mode"].setText("ALT");
		}
		
		if(xpdr_ident.getBoolValue()){
			me["XPDR.ident"].setColor(0,1,0);
		}else{
			me["XPDR.ident"].setColor(0.5,0.5,0.5);
		}
		
		#Engine Indicating
		var rpm = eng_rpm.getValue();
		me["RPM"].setText(sprintf("%4d", math.round(rpm)));
		me["RPM.needle"].setRotation(rpm/2550*D2R*215.8);
		var mp = eng_mp.getValue();
		me["manin"].setText(sprintf("%3.1f", mp));
		me["manin.needle"].setRotation(mp/40.0*D2R*190);
		me["ff.GPH"].setText(sprintf("%4d", math.round(eng_ff.getValue())));
		me["oil.F"].setText(sprintf("%3d", math.round(eng_ot.getValue())));
		me["oil.PSI"].setText(sprintf("%3d", math.round(eng_op.getValue())));
		me["fuelL"].setTranslation(fuel_l.getValue()*102.3, 0);
		me["fuelR"].setTranslation(fuel_r.getValue()*102.3, 0);
		me["egt.degf"].setText(sprintf("%4d", math.round(eng_egt.getValue())));
		
		#Small info at the bottom of the screen
		me["OAT"].setText(sprintf("%3d", math.round(oat_c.getValue())));
		#Local time (LCL)
		var local_hr=clock[0].getValue();
		var ind_hr=clock[1].getValue();
		var ind_min=clock[2].getValue();
		var ind_sec=clock[3].getValue();
		ind_sec=ind_sec-(ind_min*60)-(ind_hr*3600);
		if(local_hr>12){
			local_hr=local_hr-12;
			var pod="pm";
		}else{
			var pod="am";
		}
		var local_time_string=local_hr~":"~ind_min~":"~ind_sec~pod;
		me["lcl_time"].setText(local_time_string);
		
		#Airspeed Indicator
		me["TAS"].setText(sprintf("%3d", math.round(tas.getValue())));
		me["GS"].setText(sprintf("%3d", math.round(gs.getValue())));
		
		var airspeed=ias.getValue();
		var asi10=ias10.getValue();
		if(asi10!=0){
			me["asi.10"].show();
			me["asi.10"].setText(sprintf("%s", math.round((10*math.mod(asi10/10,1)))));
		}else{
			me["asi.10"].hide();
		}
		var asi100=ias100.getValue();
		if(asi100!=0){
			me["asi.100"].show();
			me["asi.100"].setText(sprintf("%s", math.round(asi100)));
		}else{
			me["asi.100"].hide();
		}
		#me["asi.10"].setText(sprintf("%s", math.round((10*math.mod(asi10/10,1)))));
		me["asi.rollingdigits"].setTranslation(0,math.round((10*math.mod(airspeed/10,1))*27.8, 0.1));
		
		me["asi.tape"].setTranslation(0,math.round(airspeed*3.09));
		
	
		#Attitude Indicator
		me.h_trans.setTranslation(0,ai_pitch.getValue()*11.2);
		me.h_rot.setRotation(-ai_roll.getValue()*D2R,me["horizon"].getCenter());
		
		me["ball"].setTranslation(ai_ss.getValue()*(-20),0);
		
		#Altitude Indicator
		var alt = alt_ft.getValue();
		
		me["altTapeScale"].setTranslation(0,(alt - roundToNearest(alt, 1000))*0.445);
		
		if (roundToNearest(alt, 1000) == 0) {
			me["altTextLowSmall1"].setText(sprintf("%0.0f",100));
			me["altTextLowSmall2"].setText(sprintf("%0.0f",200));
			me["altTextLowSmall3"].setText(sprintf("%0.0f",300));
			me["altTextLowSmall4"].setText(sprintf("%0.0f",400));
			me["altTextLowSmall5"].setText(sprintf("%0.0f",500));
			me["altTextLowSmall6"].setText(sprintf("%0.0f",600));
			me["altTextLowSmall7"].setText(sprintf("%0.0f",700));
			me["altTextLowSmall8"].setText(sprintf("%0.0f",800));
			me["altTextLowSmall9"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",200));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",300));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",700));
			me["altTextHighSmall9"].setText(sprintf("%0.0f",800));
			me["altTextHighSmall10"].setText(sprintf("%0.0f",900));
			var altNumLow = "-";
			var altNumHigh = "";
			var altNumCenter = altNumHigh;
		} elsif (roundToNearest(alt, 1000) > 0) {
			me["altTextLowSmall1"].setText(sprintf("%0.0f",900));
			me["altTextLowSmall2"].setText(sprintf("%0.0f",800));
			me["altTextLowSmall3"].setText(sprintf("%0.0f",700));
			me["altTextLowSmall4"].setText(sprintf("%0.0f",600));
			me["altTextLowSmall5"].setText(sprintf("%0.0f",500));
			me["altTextLowSmall6"].setText(sprintf("%0.0f",400));
			me["altTextLowSmall7"].setText(sprintf("%0.0f",300));
			me["altTextLowSmall8"].setText(sprintf("%0.0f",200));
			me["altTextLowSmall9"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",200));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",300));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",700));
			me["altTextHighSmall9"].setText(sprintf("%0.0f",800));
			var altNumLow = roundToNearest(alt, 1000)/1000 - 1;
			var altNumHigh = roundToNearest(alt, 1000)/1000;
			var altNumCenter = altNumHigh;
		} elsif (roundToNearest(alt, 1000) < 0) {
			me["altTextLowSmall1"].setText(sprintf("%0.0f",100));
			me["altTextLowSmall2"].setText(sprintf("%0.0f",200));
			me["altTextLowSmall3"].setText(sprintf("%0.0f",300));
			me["altTextLowSmall4"].setText(sprintf("%0.0f",400));
			me["altTextLowSmall5"].setText(sprintf("%0.0f",500));
			me["altTextLowSmall6"].setText(sprintf("%0.0f",600));
			me["altTextLowSmall7"].setText(sprintf("%0.0f",700));
			me["altTextLowSmall8"].setText(sprintf("%0.0f",800));
			me["altTextLowSmall9"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",800));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",700));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",300));
			me["altTextHighSmall9"].setText(sprintf("%0.0f",200));
			me["altTextHighSmall10"].setText(sprintf("%0.0f",100));
			var altNumLow = roundToNearest(alt, 1000)/1000;
			var altNumHigh = roundToNearest(alt, 1000)/1000 + 1;
			var altNumCenter = altNumLow;
		}
		if ( altNumLow == 0 ) {
			altNumLow = "";
		}
		if ( altNumHigh == 0 and alt < 0) {
			altNumHigh = "-";
		}
		me["altTextLow1"].setText(sprintf("%s", altNumLow));
		me["altTextLow2"].setText(sprintf("%s", altNumLow));
		me["altTextLow3"].setText(sprintf("%s", altNumLow));
		me["altTextLow4"].setText(sprintf("%s", altNumLow));
		me["altTextLow5"].setText(sprintf("%s", altNumLow));
		me["altTextLow6"].setText(sprintf("%s", altNumLow));
		me["altTextLow7"].setText(sprintf("%s", altNumLow));
		me["altTextLow8"].setText(sprintf("%s", altNumLow));
		me["altTextLow9"].setText(sprintf("%s", altNumLow));
		me["altTextHigh1"].setText(sprintf("%s", altNumCenter));
		me["altTextHigh2"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh3"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh4"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh5"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh6"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh7"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh8"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh9"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh10"].setText(sprintf("%s", altNumHigh));
		
		me["alt.rollingdigits"].setTranslation(0,math.round((10*math.mod(alt/100,1))*19.58, 0.1));		
		
		if(alt>=10000){
			me["alt.10000"].show();
			me["alt.10000"].setText(sprintf("%2d", alt10000.getValue()));
		}else{
			me["alt.10000"].hide();
		}
		me["alt.1000"].setText(sprintf("%1d", int(10*math.mod(alt1000.getValue()/10,1))));
		me["alt.100"].setText(sprintf("%1d", int(10*math.mod(alt100.getValue()/10,1))));
		
		var alt_bug_v=alt_bug.getValue();
		var alt_bug_1000=math.floor(alt_bug_v/1000);
		if(alt_bug_1000!=0){
			me["alt.bug"].show();
			me["alt.bug"].setText(sprintf("%s", alt_bug_1000));
		}else{
			me["alt.bug"].hide();
		}
		me["alt.bug_small"].setText(sprintf("%s", int(1000*math.mod(alt_bug_v/1000,1))));
		
		#Alt bug on the scale
		var alt_bug_diff = alt_bug_v - alt;
		if(alt_bug_diff>230){
			me["alt.bug_scale"].setTranslation(0,230*-alt_scale_factor);
		}else if(alt_bug_diff<-230){
			me["alt.bug_scale"].setTranslation(0,230*alt_scale_factor);
		}else{
			me["alt.bug_scale"].setTranslation(0,alt_bug_diff*-alt_scale_factor);
		}
		
		me["alt.setting"].setText(sprintf("%4d", math.round(alt_qnh.getValue())));
		
		
		#Vertical Speed Indicator
		var vs=vs_fpm.getValue();
		if(math.round(vs,10)==0){
			me["VS.value"].hide();
		}else{
			me["VS.value"].show();
			me["VS.value"].setText(sprintf("%+5d", math.round(vs,10)));
		}
		
		if(vs<=1000 and vs>=-1000){
			me["VS.pointer"].setTranslation(0,-vs*0.069);
		}else if(vs<=2000 and vs>1000){
			me["VS.pointer"].setTranslation(0,-69-(vs-1000)*0.024);
		}else if(vs>=-2000 and vs<-1000){
			me["VS.pointer"].setTranslation(0,69-(vs+1000)*0.024);
		}else if(vs>2000){
			me["VS.pointer"].setTranslation(0,-93);
		}else if(vs<-2000){
			me["VS.pointer"].setTranslation(0,93);
		}
		
		#Wind indicator
		var wind_dir = wind_deg.getValue();
		var wind_spd = wind_kt.getValue();
		var wind_rel = wind_dir - hdg;
		me["wind.pointer"].setRotation(wind_rel*D2R);
		me["wind.dir"].setText(sprintf("%03d", math.round(wind_dir)));
		me["wind.speed"].setText(sprintf("%3d", math.round(wind_spd)));
		
		#ILS
		if(nav_in_range.getBoolValue()){
			me["loc.scale"].show();
			me["loc.pointer"].setTranslation(loc_deflection.getValue()*63, 0);
			if(gs_in_range.getBoolValue()){
				me["gs.scale"].show();
				me["gs.pointer"].setTranslation(0, gs_deflection.getValue()*-63);
			}else{
				me["gs.scale"].hide();
			}
		}else{
			me["loc.scale"].hide();
			me["gs.scale"].hide();
		}
	},
};


var identoff = func {
	setprop("/instrumentation/transponder/inputs/ident-btn", 0);
}

setlistener("/instrumentation/transponder/inputs/ident-btn-2", func{
	setprop("/instrumentation/transponder/inputs/ident-btn", 1);
	settimer(identoff, 18);
});

var update_G3X = maketimer(0.02, func() {
	canvas_G3X_base.update();
	} );

setlistener("sim/signals/fdm-initialized", func {
	G3X_display = canvas.new({
		"name": "G3X",
		"size": [2048, 1226],
		"view": [1024, 613],
		"mipmapping": 1
	});
	G3X_display.addPlacement({"node": "G3X.screen"});
	var groupOnly = G3X_display.createGroup();

	G3X_only = canvas_G3X_only.new(groupOnly, "Aircraft/SR22T/Models/Interior/Instruments/G3X/G3X.svg");

	update_G3X.start();
});

var showG3X = func {
	var dlg = canvas.Window.new([512, 307], "dialog").set("resize", 1);
	dlg.setCanvas(G3X_display);
}
