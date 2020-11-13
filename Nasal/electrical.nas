##########################################################
####### Single Starter/Generator electrical system #######
####################    Syd Adams    #####################
###### Based on Curtis Olson's nasal electrical code #####
###### Modified by Clement DE L'HAMAIDE for DR400    #####
###### Modified by Benedikt Wolf for SR22T	     #####
##########################################################

var last_time = 0.0;
var OutPuts = props.globals.getNode("/systems/electrical/outputs",1);
var Volts = props.globals.getNode("/systems/electrical/volts",1);
var Amps = props.globals.getNode("/systems/electrical/amps",1);
var PWR = props.globals.getNode("systems/electrical/serviceable",1).getBoolValue();
var BATT1 = props.globals.getNode("/controls/electric/battery1-switch",1);
var BATT2 = props.globals.getNode("/controls/electric/battery1-switch",1);
var ALT_L = props.globals.getNode("/controls/engines/engine[0]/alt1",1);
var DIMMER = props.globals.getNode("/controls/lighting/instruments-norm",1);
var NORM = 0.0357;
var Battery={};
var Alternator={};
var load = 0.0;

setprop("/systems/electrical/outputs/flaps", 0);

############################################################################
##################### Définition de la batterie ############################
############################################################################
#var battery1 = Battery.new(volts,amps,amp_hours,charge_percent,charge_amps);

Battery = {
	new : func {
		m = { parents : [Battery] };
		m.ideal_volts = arg[0];
		m.ideal_amps = arg[1];
		m.amp_hours = arg[2];
		m.charge_percent = arg[3];
		m.charge_amps = arg[4];
		return m;
	},
	
	apply_load : func {
		var amphrs_used = arg[0] * arg[1] / 3600.0;
		var percent_used = amphrs_used / me.amp_hours;
		me.charge_percent -= percent_used;
		if ( me.charge_percent < 0.0 ) {
			me.charge_percent = 0.0;
		} elsif ( me.charge_percent > 1.0 ) {
			me.charge_percent = 1.0;
		}
		return me.amp_hours * me.charge_percent;
	},
	
	get_output_volts : func {
		var x = 1.0 - me.charge_percent;
		var tmp = -(3.0 * x - 1.0);
		var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
		return me.ideal_volts * factor;
	},
	
	get_output_amps : func {
		var x = 1.0 - me.charge_percent;
		var tmp = -(3.0 * x - 1.0);
		var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
		return me.ideal_amps * factor;
	}
};

############################################################################
##################### Définition de l'aternateur ###########################
############################################################################
# var alternator = Alternator.new("rpm-source",rpm_threshold,volts,amps);

Alternator = {
	new : func {
		m = { parents : [Alternator] };
		m.rpm_source =  props.globals.getNode(arg[0],1);
		m.rpm_threshold = arg[1];
		m.ideal_volts = arg[2];
		m.ideal_amps = arg[3];
		return m;
	},
	
	apply_load : func( amps, dt) {
		var factor = me.rpm_source.getValue() / me.rpm_threshold;
		if ( factor > 1.0 ){
			factor = 1.0;
		}
		var available_amps = me.ideal_amps * factor;
		return available_amps - amps;
	},
	
	get_output_volts : func {
		var factor = me.rpm_source.getValue() / me.rpm_threshold;
		if ( factor > 1.0 ) {
			factor = 1.0;
		}
		return me.ideal_volts * factor;
	},
	
	get_output_amps : func {
		var factor = me.rpm_source.getValue() / me.rpm_threshold;
		if ( factor > 1.0 ) {
			factor = 1.0;
		}
		return me.ideal_amps * factor;
	}
};

var battery1 = Battery.new(28.0, 90.0, 120.0, 1.0, 90.0);                            # Définition des caractéristiques de la batterie
var battery2 = Battery.new(28.0, 90.0, 120.0, 1.0, 90.0);                            # Définition des caractéristiques de la batterie
var alternator1 = Alternator.new("/engines/engine[0]/rpm", 350.0, 28.0, 120.0);    # Définition des caractéristiques de l'alternateur
var alternator2 = Alternator.new("/engines/engine[0]/rpm", 350.0, 28.0, 120.0);    # Définition des caractéristiques de l'alternateur

############################################################################
############# Définition des proppriétés à l'initialisation ################
############################################################################
var elecInit = setlistener("/sim/signals/fdm-initialized", func {
	foreach(var a; props.globals.getNode("/systems/electrical/outputs").getChildren()){
		a.setValue(0);
	}
	#    foreach(var a; props.globals.getNode("/controls/circuit-breakers").getChildren()){
	#       a.setBoolValue(1);
	#    }
	foreach(var a; props.globals.getNode("/controls/lighting").getChildren()){
		a.setValue(0);
	}
	props.globals.getNode("/controls/lighting/instrument-lights",1).setBoolValue(1);
	#    props.globals.getNode("/controls/fuel/tank[0]/boost-pump",1).setBoolValue(0);
	props.globals.getNode("/controls/anti-ice/prop-heat",1).setBoolValue(0);
	props.globals.getNode("/controls/anti-ice/pitot-heat",1).setBoolValue(0);
	props.globals.getNode("/controls/cabin/fan",1).setBoolValue(0);
	props.globals.getNode("/controls/cabin/heat",1).setBoolValue(0);
	props.globals.getNode("/controls/electric/external-power",1).setBoolValue(0);
	props.globals.getNode("/controls/electric/battery1-switch",1).setBoolValue(0);
	props.globals.getNode("/controls/electric/battery2-switch",1).setBoolValue(0);
	props.globals.getNode("/sim/failure-manager/instrumentation/comm/serviceable",1).setBoolValue(1);
	props.globals.getNode("/instrumentation/kt76a/mode",1).setValue("0");
	#### ENGINE[0] ####
	props.globals.getNode("/controls/electric/engine[0]/generator",1).setBoolValue(0);
	props.globals.getNode("/engines/engine[0]/amp-v",1).setDoubleValue(0);
	props.globals.getNode("/controls/engines/engine[0]/alt1",1).setBoolValue(0);
	props.globals.getNode("/controls/engines/engine[0]/alt2",1).setBoolValue(0);
	props.globals.getNode("/controls/engines/engine[0]/master-bat",1).setBoolValue(0);
	
	settimer(update_electrical,1);
	print("Electrical System ... OK");
	removelistener(elecInit);
});

############################################################################
#################### Simulation du bus électrique virtuel ##################
############################################################################
var bus_volts = 0.0;

var update_virtual_bus = func(dt) {
	var AltVolts_L = alternator1.get_output_volts();
	var AltAmps_L = alternator1.get_output_amps();
	var Bat1Volts = battery1.get_output_volts();
	var Bat1Amps = battery1.get_output_amps();
	var Bat2Volts = battery2.get_output_volts();
	var Bat2Amps = battery2.get_output_amps();
	var power_source = nil;
	var BatAmps = 0.0;
	var BatVolts = 0.0;
	load = 0.0;
	load += electrical_bus(bus_volts);                                        # On récupère l'ampérage utilisé par le Bus électrique
	load += avionics_bus(bus_volts);                                          # On récupère l'ampérage utilisé par le Bus Avionics
	
	#####################################################################
	################# Définition de la tension au moteur ################
	#####################################################################
	if(PWR){                                                                  # Si le système électrique n'est pas endommagé
		if(BATT1.getBoolValue() ) {
			BatAmps=Bat1Amps;
			BatVolts=Bat1Volts;
		}else if(BATT2.getBoolValue() ) {
			BatAmps=Bat2Amps;
			BatVolts=Bat2Volts;
		}
		if (ALT_L.getBoolValue() and (AltAmps_L > BatAmps)){        
			bus_volts = AltVolts_L;                                             # L'alternateur fournit la tension au Bus
			power_source = "alternator";                                        # L'alternateur est donc la source d'alimentation
			battery1.apply_load(-battery1.charge_amps, dt);                       # Et on recharge la batterie
		}                     
		elsif (ALT_L.getBoolValue() and (AltAmps_L < BatAmps)){                 # Sinon si le switch Alt Left ou Alt Right est à ON mais que le courant de l'alternateur est inférieur à ce lui de la batterie
			if (BATT1.getBoolValue()){                                             # Si le switch Batt est à ON 
				bus_volts = BatVolts;                                               # C'est la batterie qui fournie la tension au Bus
				power_source = "battery1";                                           # La batterie est donc la source d'alimentation
				battery1.apply_load(load, dt);                                       # Et on décharge la batterie
			}                   
			else {                                                                # Sinon
				bus_volts = 0.0;                                                    # La tension du Bus est 0V
			}                   
		}                   
		elsif (BATT1.getBoolValue()){                                            # Sinon si le switch de la batterie est à ON
			bus_volts = Bat1Volts;                                               # C'est la batterie qui fournie la tension au Bus
			power_source = "battery1";                                           # La batterie est donc la source d'alimentation
			battery1.apply_load(load, dt);                                       # Et on décharge la batterie
		}                    
		elsif (BATT2.getBoolValue()){                                            # Sinon si le switch de la batterie est à ON
			bus_volts = Bat2Volts;                                               # C'est la batterie qui fournie la tension au Bus
			power_source = "battery2";                                           # La batterie est donc la source d'alimentation
			battery1.apply_load(load, dt);                                       # Et on décharge la batterie
		}                   
		else {                                                                  # Sinon
			bus_volts = 0.0;                                                      # La tension du Bus est 0V
		}                     
	} else {                                                                  # Sinon c'est le système électrique est endommagé
		bus_volts = 0.0;                                                      # La tension du Bus est 0V
	}
	
	props.globals.getNode("/engines/engine[0]/amp-v",1).setValue(bus_volts);  # La tension au moteur est égale à celle du Bus
	props.globals.getNode("/engines/engine[1]/amp-v",1).setValue(bus_volts);  # La tension au moteur est égale à celle du Bus
	
	#####################################################################
	################### Définition de l'ampérage du Bus #################
	#####################################################################
	var bus_amps = 0.0;
	
	if (bus_volts > 1.0){                                                     # Si la tension du Bus est supérieur à 1V
		if (power_source == "battery1"){                                       # Si la source est la batterie
			bus_amps = BatAmps-load;                                          # L'intensité du Bus est l'intensité de la batterie moins l'intensité de tous les Bus
		} else {                  # Sinon
			bus_amps = battery1.charge_amps;                                   # Sinon l'intensité du Bus est l'intensité fourni par l'alternateur (limité par les caractéristiques de la batterie)
		}
	}
	
	#####################################################################
	###################### Affectation des valeurs ######################
	#####################################################################
	Amps.setValue(bus_amps);
	Volts.setValue(bus_volts);
	return load;
}

############################################################################
#################### Mesure des charge du bus électrique ###################
############################################################################

var electrical_bus = func(bus_volts){
	var load = 0.0;
	var starter_voltsL = 0.0;
	
	if(props.globals.getNode("/controls/lighting/landing-light",1).getBoolValue()){
		OutPuts.getNode("landing-light",1).setValue(bus_volts);
		load += 0.0004;
	} else {
		OutPuts.getNode("landing-light",1).setValue(0.0);
	}
	
	if(props.globals.getNode("/controls/lighting/strobe-lights",1).getBoolValue()){
		OutPuts.getNode("strobe-lights",1).setValue(bus_volts);
		load += 0.000002;
	} else {
		OutPuts.getNode("strobe-lights",1).setValue(0.0);
	}
	
	if(props.globals.getNode("/controls/lighting/nav-lights",1).getBoolValue()){
		OutPuts.getNode("nav-lights",1).setValue(bus_volts);
		load += 0.000002;
	} else {
		OutPuts.getNode("nav-lights",1).setValue(0.0);
	}
	
	if(props.globals.getNode("/controls/lighting/taxi-lights",1).getBoolValue()){
		OutPuts.getNode("taxi-lights",1).setValue(bus_volts);
		load += 0.000002;
	} else {
		OutPuts.getNode("taxi-lights",1).setValue(0.0);
	}
	
	if(props.globals.getNode("/controls/anti-ice/engine/carb-heat",1).getBoolValue()){
		OutPuts.getNode("carb-heat",1).setValue(bus_volts);
		load += 0.00002;
	} else {
		OutPuts.getNode("carb-heat",1).setValue(0.0);
	}
	
	if(props.globals.getNode("/controls/fuel/tank/boost-pump",1).getBoolValue()){
		OutPuts.getNode("fuel-pump",1).setValue(bus_volts);
		load += 0.000006;
	} else {
		OutPuts.getNode("fuel-pump",1).setValue(0.0);
	}
	
	if (props.globals.getNode("/controls/engines/engine[0]/starter_cmd",1).getBoolValue() and props.globals.getNode("/controls/fuel/tank/to_engine",1).getBoolValue()){
		starter_voltsL = bus_volts;
		load += 0.01;
	}
	
	OutPuts.getNode("starter",1).setValue(starter_voltsL);
	
	return load;
}

############################################################################
############# Mesure des charges du bus avionique (Instruments) ############
############################################################################
var avionics_bus = func(bus_volts) {
	#load = 0.0;
	
	if (props.globals.getNode("/controls/lighting/instrument-lights").getBoolValue()){
		var instr_norm = props.globals.getNode("/controls/lighting/instruments-norm").getValue();
		var v = instr_norm * bus_volts;
		OutPuts.getNode("instrument-lights",1).setValue(v);
		load += 0.000025;
	} else {
		OutPuts.getNode("instrument-lights",1).setValue(0.0);
	}
	
	if (props.globals.getNode("/controls/lighting/panel-norm").getValue() > 0){
		var panel_norm = props.globals.getNode("/controls/lighting/panel-norm").getValue();
		var v = panel_norm * bus_volts;
		OutPuts.getNode("panel-lights",1).setValue(v);
		load += 0.000025;
	} else {
		OutPuts.getNode("panel-lights",1).setValue(0.0);
	}
	
	if (props.globals.getNode("/instrumentation/comm/serviceable").getBoolValue() and props.globals.getNode("/sim/failure-manager/instrumentation/comm/serviceable").getBoolValue()){
		OutPuts.getNode("comm",1).setValue(bus_volts);
		load += 0.00015;
	} else {
		OutPuts.getNode("comm",1).setValue(0.0);
	}
	#
	#    if (props.globals.getNode("/instrumentation/kt76a/mode").getValue() > 0 and props.globals.getNode("/controls/switches/transponder").getBoolValue()){
	#        OutPuts.getNode("transponder",1).setValue(bus_volts);
	#        load += 0.00015;
	#    } else {
	#        OutPuts.getNode("transponder",1).setValue(0.0);
	#    }
	
	if (props.globals.getNode("/instrumentation/nav/serviceable").getBoolValue() ){
		OutPuts.getNode("nav",1).setValue(bus_volts);
		load += 0.00015;
	} else {
		OutPuts.getNode("nav",1).setValue(0.0);
	}
	
	if (props.globals.getNode("/instrumentation/nav[1]/serviceable").getBoolValue() ){
		OutPuts.getNode("nav[1]",1).setValue(bus_volts);
		load += 0.000015;
	} else {
		OutPuts.getNode("nav[1]",1).setValue(0.0);
	}   
	
	if (props.globals.getNode("/instrumentation/adf/serviceable").getBoolValue() ){
		OutPuts.getNode("adf",1).setValue(bus_volts);
		load += 0.000015;
	} else {
		OutPuts.getNode("adf",1).setValue(0.0);
	}
	
	if (props.globals.getNode("/instrumentation/turn-indicator/serviceable").getBoolValue() ){
		OutPuts.getNode("turn-coordinator",1).setValue(bus_volts);
		load += 0.000015;
	} else {
		OutPuts.getNode("turn-coordinator",1).setValue(0.0);
	}
	
	return load;
}

var update_electrical = func {
	
	#Pilots/Passengers
	if(getprop("/sim/weight[0]/weight-lb") or 0 >= 80){
		setprop("/sim/model/pilot-present", 1);
	}else{
		setprop("/sim/model/pilot-present", 0);
	}
	if(getprop("/sim/weight[1]/weight-lb") or 0 >= 80){
		setprop("/sim/model/copilot-present", 1);
	}else{
		setprop("/sim/model/copilot-present", 0);
	}
	if(getprop("/sim/weight[2]/weight-lb") or 0 >= 80){
		setprop("/sim/model/passengerL-present", 1);
	}else{
		setprop("/sim/model/passengerL-present", 0);
	}
	if(getprop("/sim/weight[3]/weight-lb") or 0 >= 80){
		setprop("/sim/model/passengerR-present", 1);
	}else{
		setprop("/sim/model/passengerR-present", 0);
	}
	
	#Lights
	if(getprop("/systems/electrical/outputs/nav-lights") or 0 >= 15){
		setprop("/sim/model/lights/nav-light", 1);
	}else{
		setprop("/sim/model/lights/nav-light", 0);
	}
	if(getprop("/systems/electrical/outputs/strobe-lights") or 0 >= 15){
		setprop("/sim/model/lights/strobe/enabled", 1);
	}else{
		setprop("/sim/model/lights/strobe/enabled", 0);
	}
	
	
	if(getprop("/systems/electrical/volts") or 0>=15){
		setprop("/systems/electrical/outputs/flaps", 1);
	}else{
		setprop("/systems/electrical/outputs/flaps", 0);
	}
	var time = getprop("/sim/time/elapsed-sec");
	var dt = time - last_time;
	var last_time = time;
	update_virtual_bus(dt);
	settimer(update_electrical, 0);
}


var flaps_cmd = "/controls/flight/flaps-cmd";
setprop(flaps_cmd, 0);

setlistener(flaps_cmd, func(i) {
	if(getprop("/systems/electrical/outputs/flaps")==1){
		setprop("/controls/flight/flaps", i.getValue());
	}
});

setlistener("/systems/electrical/outputs/flaps", func(i) {
	if(i.getValue()==1){
		setprop("/controls/flight/flaps", getprop(flaps_cmd));
	}
});
