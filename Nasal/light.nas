var sbc1 = aircraft.light.new( "/sim/model/lights/sbc1", [0.5, 0.3] );
sbc1.interval = 0.1;
sbc1.switch( 1 );

var sbc2 = aircraft.light.new( "/sim/model/lights/sbc2", [0.2, 0.3], "/sim/model/lights/sbc1/state" );
sbc2.interval = 0;
sbc2.switch( 1 );

setlistener( "/sim/model/lights/sbc2/state", func(n) {
  var bsbc1 = sbc1.stateN.getValue();
  var bsbc2 = n.getBoolValue();
  var b = 0;
  if( bsbc1 and bsbc2 and getprop( "/controls/lighting/beacon") ) {
    b = 1;
  } else {
    b = 0;
  }
  setprop( "/sim/model/lights/beacon/enabled", b );

  #if( bsbc1 and !bsbc2 and getprop( "/controls/lighting/strobe" ) ) {
  #  b = 1;
  #} else {
  #  b = 0;
  #}
  #setprop( "/sim/model/lights/strobe/enabled", b );
});

var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0.05, 0.05] );
beacon.interval = 0;

var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0.05, 0.05, 0.05, 1] );
strobe.interval = 0;

var elt = aircraft.light.new( "/sim/model/lights/elt", [0.05 , 0.05] );
setprop( "/sim/model/lights/elt/enabled",1);
elt.interval = 0;

var calc_instrument_norm = func(){
	var instrument_norm = getprop("/controls/switches/instrument-lights-norm");
	var flood_norm = getprop("/controls/switches/flood-lights-norm");
	var instrument_ctrl = getprop("/controls/lighting/instr-lights");
	var flood_ctrl = getprop("/controls/lighting/flood-lights");
	
	var instrument_norm_bis = 0;
	if(instrument_norm!=nil and instrument_ctrl!=nil and instrument_norm_bis<instrument_norm and instrument_ctrl>0){
		instrument_norm_bis = instrument_norm;
	}
	if(flood_norm!=nil and flood_ctrl!=nil and instrument_norm_bis<flood_norm and flood_ctrl>0){
		instrument_norm_bis = flood_norm;
	}
	setprop("/controls/switches/instrument-lights-norm-bis",instrument_norm_bis);
}


setlistener( "/controls/switches/flood-lights-norm", calc_instrument_norm);
setlistener( "/controls/switches/instrument-lights-norm", calc_instrument_norm);
setlistener( "/controls/lighting/instr-lights", calc_instrument_norm);
setlistener( "/controls/lighting/flood-lights", calc_instrument_norm);


setlistener("/systems/electrical/outputs/landing-lights", func(v) {
	if(v.getValue() > 15 and getprop("/sim/current-view/internal") == 1){
		setprop("/sim/rendering/als-secondary-lights/use-landing-light", 1);
		setprop("/sim/rendering/als-secondary-lights/use-alt-landing-light", 1); #LED Power :)
	}else{
		setprop("/sim/rendering/als-secondary-lights/use-landing-light", 0);
		setprop("/sim/rendering/als-secondary-lights/use-alt-landing-light", 0); 
	}
});

setlistener("/sim/current-view/internal", func(v) {
	if(v.getValue() == 1 and getprop("/systems/electrical/outputs/landing-lights") > 15 ){
		setprop("/sim/rendering/als-secondary-lights/use-landing-light", 1);
		setprop("/sim/rendering/als-secondary-lights/use-alt-landing-light", 1); #LED Power :)
	}else{
		setprop("/sim/rendering/als-secondary-lights/use-landing-light", 0);
		setprop("/sim/rendering/als-secondary-lights/use-alt-landing-light", 0); 
	}
});
		
