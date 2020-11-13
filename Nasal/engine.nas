##engine

controls.startEngine = func(v = 1, which...) {
    if (!v and !size(which))
        return props.setAll("/controls/engines/engine", "starter", 0);
    if(size(which)) {
        foreach(var i; which)
            foreach(var e; engines)
                if(e.index == i and getprop("/controls/electric/alimentation/engines/engine["~e.index~"]/starter")==1){
                    e.controls.getNode("starter").setBoolValue(v);
				}
    } else {
        foreach(var e; engines)
            if(e.selected.getValue() and getprop("/controls/electric/alimentation/engines/engine["~e.index~"]/starter")==1){
                e.controls.getNode("starter").setBoolValue(v);
			}
    }
}

controls.stepMagnetos = func(change) {
	#do nothing now ...
}

##calcul si le moteur peut fonctionner en fonction des ecu (simulation via les magnetos)
var controlEngine = func(no_engine){
	var no_ecu = -1;
	var positionSwitchEcu = getprop("/controls/switches/ecu["~no_engine~"]/switch");
	var testEcu0 = getprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/test-ecu");
	var testEcu1 = getprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/test-ecu");
	if(positionSwitchEcu==0 or testEcu1==1){
		if(getprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/serviceable")==1){#ecu b selected
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/selected",1);
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/selected",0);
			no_ecu = 1;
		}
	}elsif(positionSwitchEcu==1 or testEcu0==1){
		if(getprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/serviceable")==1){#ecu a
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/selected",1);
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/selected",0);
			no_ecu = 0;
		}elsif(getprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/serviceable")==1){#ecu b
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/selected",1);
			setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/selected",0);
			no_ecu = 1;
		}
	}
	if(no_ecu!=-1){
		setprop("/controls/engines/engine["~no_engine~"]/magnetos",3);
	}else{
		setprop("/controls/engines/engine["~no_engine~"]/magnetos",0);
	}
}

var activateTestEcuAEngine0 = func{
	activateTestEcuA(0);
}

var activateTestEcuAEngine1 = func{
	activateTestEcuA(1);
}

var activateTestEcuBEngine0 = func{
	activateTestEcuB(0);
}

var activateTestEcuBEngine1 = func{
	activateTestEcuB(1);
}

var deActivateTestEcuAEngine0 = func{
	setprop("/controls/electric/alimentation/engines/engine[0]/ecus/ecu[0]/test-ecu",0);
}

var deActivateTestEcuAEngine1 = func{
	setprop("/controls/electric/alimentation/engines/engine[1]/ecus/ecu[0]/test-ecu",0);
}

var activateTestEcuAB = func(no_engine){
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/test-ecu",1);
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/test-ecu",1);
	if(no_engine==0){
		settimer(activateTestEcuBEngine0,5);
	}else{
		settimer(activateTestEcuBEngine1,5);
	}
}

var activateTestEcuA = func(no_engine){
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/test-ecu",1);
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/test-ecu",0);
	if(no_engine==0){
		settimer(deActivateTestEcuAEngine0,5);
	}else{
		settimer(deActivateTestEcuAEngine1,5);
	}
}

var activateTestEcuB = func(no_engine){
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[0]/test-ecu",0);
	setprop("/controls/electric/alimentation/engines/engine["~no_engine~"]/ecus/ecu[1]/test-ecu",1);
	if(no_engine==0){
		settimer(activateTestEcuAEngine0,5);
	}else{
		settimer(activateTestEcuAEngine1,5);
	}
}


var controlEngineEcu = func(m){
	var no_engine = m.getParent().getParent().getParent().getIndex();
	controlEngine(no_engine);
}

var controlEcu = func(m){
	var no_engine = m.getParent().getIndex();
	controlEngine(no_engine);
}

setlistener("/controls/electric/alimentation/engines/engine[0]/ecus/ecu[0]/serviceable",controlEngineEcu);
setlistener("/controls/electric/alimentation/engines/engine[0]/ecus/ecu[1]/serviceable",controlEngineEcu);
setlistener("/controls/switches/ecu[0]/switch",controlEcu);
setlistener("/controls/electric/alimentation/engines/engine[1]/ecus/ecu[0]/serviceable",controlEngineEcu);
setlistener("/controls/electric/alimentation/engines/engine[1]/ecus/ecu[1]/serviceable",controlEngineEcu);
setlistener("/controls/switches/ecu[1]/switch",controlEcu);

var update_engine_params = func(dt){
	for(var i=0;i<2;i=i+1){
		var oil_pres = 0.0;
		rpm = getprop("/engines/engine["~i~"]/rpm");
		if (rpm!=nil and rpm > 600.0){
		   oil_pres = 6.2-1260/rpm;
		}
		setprop("/engines/engine["~i~"]/oil-pressure-psi",oil_pres);
		
		var cooling = getprop("/environment/temperature-degc") - (getprop("velocities/airspeed-kt") * 0.1) * getprop("/environment/temperature-degc")/10;
		
		if(getprop("/engines/engine["~i~"]/running")==1 and getprop("/engines/engine["~i~"]/fuel-flow-gph")!=nil){
			var fgph = getprop("/engines/engine["~i~"]/fuel-flow-gph");
			cooling = cooling + (fgph * 5);
		}

		var coolant = getprop("/engines/engine["~i~"]/coolant-temperature-degc");
		coolant = coolant + (cooling-coolant)*0.1;
		setprop("/engines/engine["~i~"]/coolant-temperature-degc",coolant);
		
		##oil temp
		if(getprop("/engines/engine["~i~"]/oil-temperature-degf")!=nil){
			var oil_temp = (getprop("/engines/engine["~i~"]/oil-temperature-degf") - 32) * 5/9;;
			setprop("/engines/engine["~i~"]/oil-temperature-degc",oil_temp);
		}
		
		##fuel temperature
		var cooling_fuel = getprop("/environment/temperature-degc") - (getprop("velocities/airspeed-kt") * 0.1) * getprop("/environment/temperature-degc")/10;
		
		if(getprop("/engines/engine["~i~"]/running")==1 and getprop("/engines/engine["~i~"]/fuel-flow-gph")!=nil){
			var fgph = getprop("/engines/engine["~i~"]/fuel-flow-gph");
			cooling_fuel = cooling_fuel + (fgph * 0.5);
		}
		var fuel_temp = getprop("/engines/engine["~i~"]/fuel-temperature-degc");
		fuel_temp = fuel_temp + (cooling_fuel-fuel_temp)*0.1;
		if(fuel_temp<-30){
			fuel_temp=-30; ## the jet a1 fuel freeze !!!
		}
		setprop("/engines/engine["~i~"]/fuel-temperature-degc",fuel_temp);
		
		##gestion de la mise en drapeau des helices
		##pour l'instant, si le moteur est arrete, on met l'helice en drapeau, sinon, on mets plein pot
		if(getprop("/engines/engine["~i~"]/fuel-flow-gph")==0){
			setprop("/controls/engines/engine["~i~"]/propeller-pitch-fadec",0);
		}elsif(getprop("/controls/engines/engine["~i~"]/propeller-feather")==1){##pour des tests
			setprop("/controls/engines/engine["~i~"]/propeller-pitch-fadec",0);
		}else{
			var propeller_pitch = 1;#full power
			##icing
			propeller_pitch = propeller_pitch - getprop("/sim/icing/propellers");
			setprop("/controls/engines/engine["~i~"]/propeller-pitch-fadec",propeller_pitch);
		}
		
		##gestion de la mixture via les ecu
		var ecuA = getprop("/controls/electric/alimentation/engines/engine["~i~"]/ecus/ecu[0]/selected");
		var ecuB = getprop("/controls/electric/alimentation/engines/engine["~i~"]/ecus/ecu[1]/selected");
		var mixture_fadec = 0;
		if(ecuA==1){#ecu A , gestion de la mixture en fonction de l'altitude 
			if(getprop("/engines/engine["~i~"]/running")==0){
					setprop("/controls/engines/engine["~i~"]/mixture-fadec",1.0);##full rich
			#}elsif(getprop("/gear/gear[0]/position-norm")==1){##si le train est sorti, full rich (decollage ou atterrissage)
			#        setprop("/controls/engines/engine["~i~"]/mixture-fadec",1.0);##full rich
			}else{
					##calculs trouves de maniere empirique mais qui ont l'air de marcher ...
					var pressure = getprop("/environment/pressure-inhg");
					var temp = getprop("/environment/temperature-degc");
					var throttle = getprop("/controls/engines/engine["~i~"]/throttle");
					var param1 = pressure/(temp+273);
					var mixture_base = 0.5+(throttle-0.5)/1.8;
					var press_base = 0.10167235;
					var param2 = mixture_base/press_base;
					mixture_fadec = param1 * param2;
			}
		}elsif(ecuB==1){#gestion par l'ecu B, qui est moins precis ...
			if(getprop("/engines/engine["~i~"]/running")==0){
					mixture_fadec = 1.0;##full rich
			}else{#l'ecu B est moins precis
					##calculs trouves de maniere empirique mais qui ont l'air de marcher ...
					var pressure = getprop("/environment/pressure-inhg");
					var temp = getprop("/environment/temperature-degc");
					var throttle = getprop("/controls/engines/engine["~i~"]/throttle");
					var param1 = pressure/(temp+273);
					var mixture_base = 0.5+(throttle-0.5)/1.8;
					var press_base = 0.10167235;
					var param2 = mixture_base/press_base;
					var mixture_fadec = param1 * param2;
					mixture_fadec = int(mixture_fadec * 10)/10;
			}
		}else{##pas d'ecu, pas de mixture
			mixture_fadec = 0;
		}
		
		##icing and alternate air
		if(getprop("/controls/switches/alternateair")==1){
			#alternate air , +0.3 to mixture to simulate the loss of power due to warm air intake
			mixture_fadec = mixture_fadec + 0.3;
		}else{
			#application of the icing
			mixture_fadec = mixture_fadec - getprop("/sim/icing/engines");
		}
		
		##wing destroyed
		if(getprop("/controls/flight/wing_destroyed")==1 and i==1){
			mixture_fadec = 0;
		}
		setprop("/controls/engines/engine["~i~"]/mixture-fadec",mixture_fadec);
	}
	
	##ajout du temps de service de chaque moteur
	## repris du pa22
	for(var i=0;i<2;i=i+1){
		if(getprop("/engines/engine["~i~"]/hours-running")==nil){
			setprop("/engines/engine["~i~"]/hours-running",0);
		}
		var hours = props.globals.getNode("/engines/engine["~i~"]/hours-running", 1);
		var hours_display = props.globals.getNode("/engines/engine["~i~"]/hours-running-display", 1);
		var minutes_display = props.globals.getNode("/engines/engine["~i~"]/minutes-running-display", 1);
		var running = props.globals.getNode("/engines/engine["~i~"]/running", 1);
		if(running.getValue()){ 
			if(hours.getValue()==nil){
				hours.setDoubleValue(0);
			}
			hours.setDoubleValue(hours.getValue() + dt / 3600);
		}
		hours_display.setIntValue(hours.getValue());
		minutes_display.setIntValue(hours.getValue()*60 - hours_display.getValue()*60);
	}
}