# Midcontinent Instruments MD302_ai by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var MD302_ai_only = nil;
var MD302_ai_start = nil;
var MD302_ai_display = nil;
var page = "start";
setprop("/systems/electrical/volts", 0);

var ready = "/instrumentation/MD302/ready";
setprop(ready, 0);

var brightness_adjst = "/instrumentation/MD302/set-brightness";
setprop(brightness_adjst, 0);

var brightness = "/instrumentation/MD302/brightness";
setprop(brightness, 0.8);

var instrument_path = "Aircraft/SR22T/Models/Interior/Instruments/MD302/";

var canvas_MD302_ai_base = {
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
		
		if(file==instrument_path~"MD302_ai.svg"){
			me.h_trans = me["horizon"].createTransform();
			me.h_rot = me["horizon"].createTransform();
			me.h2_trans = me["pitch.scale"].createTransform();
			me.h2_rot = me["pitch.scale"].createTransform();
		}


		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (getprop("/systems/electrical/volts") > 15 and getprop(ready)==1) {
			MD302_ai_only.page.show();
			MD302_ai_only.update();
			MD302_ai_start.page.hide();
		} else	if (getprop("/systems/electrical/volts") > 15 and getprop(ready)!=1) {
			MD302_ai_start.page.show();
			MD302_ai_only.page.hide();
		} else {
			MD302_ai_only.page.hide();
			MD302_ai_start.page.hide();
		}
	},
};
	
	
var canvas_MD302_ai_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_MD302_ai_only , canvas_MD302_ai_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["pitch.scale","horizon","ball","compass","heading","roll.pointer","brightness","brightness.bar"];
	},
	update: func() {
		#Attitude Indicator
		var pitch = getprop("orientation/pitch-deg") or 0;
		var roll =  getprop("orientation/roll-deg") or 0;
		
		me.h_trans.setTranslation(0,pitch*10.23);
		me.h_rot.setRotation(-roll*D2R,me["horizon"].getCenter());
		me.h2_trans.setTranslation(0,pitch*10.23);
		me.h2_rot.setRotation(-roll*D2R,me["horizon"].getCenter());
		
		me["roll.pointer"].setRotation(roll*D2R);
		
		me["ball"].setTranslation(getprop("/instrumentation/slip-skid-ball/indicated-slip-skid")*7,0);
		
		var headingv = getprop("/orientation/heading-deg") or 0;
		me["compass"].setTranslation(math.round((360*math.mod(headingv/360,1))*-7.69, 0.1),0);
		me["heading"].setText(sprintf("%3d", math.round(headingv)));
		
		
		if(getprop(brightness_adjst)==1){
			me["brightness"].show();
			me["brightness.bar"].setTranslation(0,-592*getprop(brightness));
		}else{
			me["brightness"].hide();
		}
	},
};
	
	
var canvas_MD302_ai_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_MD302_ai_start , canvas_MD302_ai_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	},
};



var update_timer_ai = maketimer(0.02, func {
	canvas_MD302_ai_base.update();
});

setlistener("sim/signals/fdm-initialized", func {
	MD302_ai_display = canvas.new({
		"name": "MD302_ai",
		"size": [1024, 783],
		"view": [1024, 783],
		"mipmapping": 1
	});
	MD302_ai_display.addPlacement({"node": "ai.screen"});
	var groupOnly = MD302_ai_display.createGroup();
	var groupStart = MD302_ai_display.createGroup();

	MD302_ai_only = canvas_MD302_ai_only.new(groupOnly, instrument_path~"MD302_ai.svg");
	MD302_ai_start = canvas_MD302_ai_start.new(groupStart, instrument_path~"MD302_start.svg");
	
	update_timer_ai.start();
});

var showAI = func {
	var dlg = canvas.Window.new([256, 196], "dialog").set("resize", 1);
	dlg.setCanvas(MD302_ai_display);
}

setlistener("/systems/electrical/volts", func (i)  {
	if(getprop(ready)==0 and i.getValue()>15 ){
		interpolate(ready, 1, 5);
	}else if(getprop(ready)>0 and i.getValue()<15 ) {
		setprop(ready, 0);
	}
});
