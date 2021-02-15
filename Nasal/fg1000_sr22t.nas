# Copyright 2020 Julio Santa Cruz (Barta)
# SR22T Garmin Perspective implementation

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
var aircraft_dir = getprop("/sim/aircraft-dir");

io.load_nasal(nasal_dir ~ 'FG1000.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/Interfaces/SR22TInterfaceController.nas', "fg1000"); 

# Load the custom controller
var interfaceController = fg1000.SR22TInterfaceController.getOrCreateInstance();

interfaceController.start();

io.load_nasal(aircraft_dir ~ '/Nasal/EIS/EIS-SR22T.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/EIS/EISController.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/EIS/EISStyles.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/EIS/EISOptions.nas', "fg1000");

var EIS_Class = fg1000.EIS;

var fg1000system = fg1000.FG1000.getOrCreateInstance(EIS_Class:EIS_Class, EIS_SVG: "Nasal/EIS/MFDPages/EIS-SR22T.svg");

# Create a PFD as device 1, MFD as device 2
fg1000system.addPFD(index:1);
fg1000system.addMFD(index:2);

# Map the devices to placement objects Screen{i}, in this case Screen1 and Screen2
fg1000system.display(index:1);
fg1000system.display(index:2);


# Turn on/off the displays 
# TODO: Check bus voltage
var fg1000_power = func() {
    var batt = props.globals.getNode("controls/electric/battery2-switch").getBoolValue();
        if (batt) {
	        # Show the devices
	        fg1000system.show(index:1);
	        fg1000system.show(index:2);
	        
	        # Hack: Some nasal scripts and add-ons looks for this switch to
	        # detect if the radio is serviceable...
	        setprop("/instrumentation/comm/power-btn",1);
	        setprop("/instrumentation/comm[1]/power-btn",1);
        } else {
	        fg1000system.hide(index:1);
	        fg1000system.hide(index:2);
	        #interfaceController.restart();
	        
	        setprop("/instrumentation/comm/power-btn",0);
	        setprop("/instrumentation/comm[1]/power-btn",0);
    }
};
setlistener("/controls/electric/battery2-switch", fg1000_power);

