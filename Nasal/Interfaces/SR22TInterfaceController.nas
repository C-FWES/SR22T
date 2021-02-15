# Copyright 2018 Stuart Buchanan
# Copyright 2020 Julio Santa Cruz
# This file is part of FlightGear.
#
# FlightGear is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# FlightGear is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.
#
# SR22T Interface controller.

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
var aircraft_dir = getprop("/sim/aircraft-dir");
io.load_nasal(nasal_dir ~ 'Interfaces/PropertyPublisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/PropertyUpdater.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/NavDataInterface.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/Interfaces/SR22TEISPublisher.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/Interfaces/SR22TNavComPublisher.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/Interfaces/SR22TNavComUpdater.nas', "fg1000");
#io.load_nasal(nasal_dir ~ 'Interfaces/GenericNavComUpdater.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GenericFMSPublisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GenericFMSUpdater.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GenericADCPublisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GenericFuelInterface.nas', "fg1000");
io.load_nasal(aircraft_dir ~ '/Nasal/Interfaces/SR22TFuelPublisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GFC700Publisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/GFC700Interface.nas', "fg1000");
print("All intefaces loaded");
var SR22TInterfaceController = {

  _instance : nil,

  INTERFACE_LIST : [
    "NavDataInterface",
    "SR22TEISPublisher",
    "SR22TNavComPublisher",
    "SR22TNavComUpdater",
    "GenericFMSPublisher",
    "GenericFMSUpdater",
    "GenericADCPublisher",
    "GenericFuelInterface",
    "SR22TFuelPublisher",
    "GFC700Publisher",
    "GFC700Interface",
  ],

  # Factory method
  getOrCreateInstance : func() {
    if (SR22TInterfaceController._instance == nil) {
      SR22TInterfaceController._instance = SR22TInterfaceController.new();
    }

    return SR22TInterfaceController._instance;
  },

  new : func() {
    var obj = {
      parents : [SR22TInterfaceController],
      running : 0,
    };

    return obj;
  },

  start : func() {
    if (me.running) return;

    foreach (var interface; SR22TInterfaceController.INTERFACE_LIST) {
      var code = sprintf("me.%sInstance = fg1000.%s.new();", interface, interface);
      var instantiate = compile(code);
      instantiate();
      print("InterfaceController: loaded " ~ interface);
    }

    foreach (var interface; SR22TInterfaceController.INTERFACE_LIST) {
      var code = 'me.' ~ interface ~ 'Instance.start();';
      var start_interface = compile(code);
      start_interface();
      print("InterfaceController: started " ~ interface);
    }

    me.running = 1;
  },

  stop : func() {
    if (me.running == 0) return;

    foreach (var interface; SR22TInterfaceController.INTERFACE_LIST) {
      var code = 'me.' ~ interface ~ 'Instance.stop();';
      var stop_interface = compile(code);
      stop_interface();
      print("InterfaceController: stopped " ~ interface);
    }
  },

  restart : func() {
    me.stop();
    me.start();
  }
};
