# Midcontinent Instruments MD302_alt by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var MD302_alt_only = nil;
var MD302_alt_start = nil;
var MD302_alt_display = nil;
var page = "only";
setprop("/systems/electrical/volts", 0);
setprop("/test", 1);

var ready = "/instrumentation/MD302/ready";


var instrument_path = "Aircraft/SR22T/Models/Interior/Instruments/MD302/";

#roundToNearest function used for alt tape, thanks @Soitanen (737-800)!
var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}



var canvas_MD302_alt_base = {
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

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (getprop("/systems/electrical/volts") > 15 and getprop(ready)==1) {
			MD302_alt_only.page.show();
			MD302_alt_only.update();
			MD302_alt_start.page.hide();
		} else	if (getprop("/systems/electrical/volts") > 15 and getprop(ready)!=1) {
			MD302_alt_start.page.show();
			MD302_alt_only.page.hide();
		} else {
			MD302_alt_only.page.hide();
			MD302_alt_start.page.hide();
		}
	},
};
	
	
var canvas_MD302_alt_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_MD302_alt_only , canvas_MD302_alt_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["asi.tape","asi.10","asi.rollingdigits","alt.1000","alt.100","alt.rollingdigits","qnh","alt.tape","altTextHigh1","altTextHigh2","altTextHigh3","altTextHigh4","altTextHigh5","altTextHigh6","altTextHigh7","altTextHigh8","altTextHigh9","altTextHigh10",
		"altTextLow1","altTextLow2","altTextLow3","altTextLow4","altTextLow5","altTextLow6","altTextLow7","altTextLow8","altTextLow9",
		"altTextHighSmall2","altTextHighSmall3","altTextHighSmall4","altTextHighSmall5","altTextHighSmall6","altTextHighSmall7","altTextHighSmall8","altTextHighSmall9","altTextHighSmall10",
		"altTextLowSmall1","altTextLowSmall2","altTextLowSmall3","altTextLowSmall4","altTextLowSmall5","altTextLowSmall6","altTextLowSmall7","altTextLowSmall8","altTextLowSmall9","alt.trend.up","alt.trend.down"];
	},
	update: func() {
		
		var airspeed = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
		
		me["asi.tape"].setTranslation(0,airspeed*13.95);
		me["asi.10"].setText(sprintf("%2d",math.floor(airspeed/10)));
		me["asi.rollingdigits"].setTranslation(0,math.round((10*math.mod(airspeed/10,1))*115, 0.1));
		
		
		var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft") or 0;
		
		me["alt.1000"].setText(sprintf("%1d",math.floor(altitude/1000)));
		me["alt.100"].setText(sprintf("%1d",math.round(10*math.mod(math.floor(altitude/100)/10,1))));
		me["alt.rollingdigits"].setTranslation(0,math.round((100*math.mod(altitude/100,1))*8.668, 0.1));
		
		
		var alt=altitude;
		me["alt.tape"].setTranslation(0,(alt - roundToNearest(alt, 1000))*1.76);
		
		if (roundToNearest(alt, 1000) == 0) {
			me["altTextLowSmall1"].setText(sprintf("%0.0f",100));
			me["altTextLowSmall2"].setText(sprintf("%0.0f",200));
			me["altTextLowSmall3"].setText(sprintf("%0.0f",300));
			me["altTextLowSmall4"].setText(sprintf("%0.0f",400));
			me["altTextLowSmall5"].setText(sprintf("%0.0f",500));
			me["altTextLowSmall6"].setText(sprintf("%0.0f",600));
			me["altTextLowSmall7"].setText(sprintf("%0.0f",700));
			#me["altTextLowSmall8"].setText(sprintf("%0.0f",800));
			#me["altTextLowSmall9"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",200));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",300));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",700));
			#me["altTextHighSmall9"].setText(sprintf("%0.0f",800));
			#me["altTextHighSmall10"].setText(sprintf("%0.0f",900));
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
			#me["altTextLowSmall8"].setText(sprintf("%0.0f",200));
			#me["altTextLowSmall9"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",100));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",200));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",300));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",700));
			#me["altTextHighSmall9"].setText(sprintf("%0.0f",800));
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
			#me["altTextLowSmall8"].setText(sprintf("%0.0f",800));
			#me["altTextLowSmall9"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall2"].setText(sprintf("%0.0f",900));
			me["altTextHighSmall3"].setText(sprintf("%0.0f",800));
			me["altTextHighSmall4"].setText(sprintf("%0.0f",700));
			me["altTextHighSmall5"].setText(sprintf("%0.0f",600));
			me["altTextHighSmall6"].setText(sprintf("%0.0f",500));
			me["altTextHighSmall7"].setText(sprintf("%0.0f",400));
			me["altTextHighSmall8"].setText(sprintf("%0.0f",300));
			#me["altTextHighSmall9"].setText(sprintf("%0.0f",200));
			#me["altTextHighSmall10"].setText(sprintf("%0.0f",100));
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
		#me["altTextLow8"].setText(sprintf("%s", altNumLow));
		#me["altTextLow9"].setText(sprintf("%s", altNumLow));
		me["altTextHigh1"].setText(sprintf("%s", altNumCenter));
		me["altTextHigh2"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh3"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh4"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh5"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh6"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh7"].setText(sprintf("%s", altNumHigh));
		me["altTextHigh8"].setText(sprintf("%s", altNumHigh));
		#me["altTextHigh9"].setText(sprintf("%s", altNumHigh));
		#me["altTextHigh10"].setText(sprintf("%s", altNumHigh));
		
		#Altitude trend
		var predict_alt = getprop("/instrumentation/pfd/alt-lookahead-6s") or 0;
		var alt_diff=predict_alt-altitude;
		if(alt_diff>0 and alt_diff<=225){
			me["alt.trend.down"].setTranslation(0,0);
			me["alt.trend.up"].setTranslation(0,alt_diff*-1.71);
		}else if(alt_diff>225){
			me["alt.trend.down"].setTranslation(0,0);
			me["alt.trend.up"].setTranslation(0,225*-1.71);
		}else if(alt_diff<0 and alt_diff>=-225){
			me["alt.trend.up"].setTranslation(0,0);
			me["alt.trend.down"].setTranslation(0,alt_diff*-1.71);
		}else if(alt_diff<225){
			me["alt.trend.up"].setTranslation(0,0);
			me["alt.trend.down"].setTranslation(0,-225*-1.71);
		}
		
		var qnh_inhg = getprop("/instrumentation/altimeter/setting-inhg") or 0;
		me["qnh"].setText(sprintf("%2.2f", qnh_inhg));
		
	},
};


var canvas_MD302_alt_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_MD302_alt_start , canvas_MD302_alt_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	},
};


var update_timer_alt = maketimer(0.02, func {
	canvas_MD302_alt_base.update();
});


setlistener("sim/signals/fdm-initialized", func {
	MD302_alt_display = canvas.new({
		"name": "MD302_alt",
		"size": [1024, 783],
		"view": [1024, 783],
		"mipmapping": 1
	});
	MD302_alt_display.addPlacement({"node": "alt.screen"});
	var groupOnly = MD302_alt_display.createGroup();
	var groupStart = MD302_alt_display.createGroup();

	MD302_alt_only = canvas_MD302_alt_only.new(groupOnly, instrument_path~"MD302_alt.svg");
	MD302_alt_start = canvas_MD302_alt_start.new(groupStart, instrument_path~"MD302_start.svg");
	
	update_timer_alt.start();
});

var showALT = func {
	var dlg = canvas.Window.new([256, 196], "dialog").set("resize", 1);
	dlg.setCanvas(MD302_alt_display);
}
