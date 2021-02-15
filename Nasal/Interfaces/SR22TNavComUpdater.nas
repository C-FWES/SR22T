# Copyright 2018 Stuart Buchanan
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
# NavCom Interface using Emesary for a simple dual Nav/Com system using standard properties
# This updates the properties from Emesary messages.

var SR22TNavComUpdater =
{
  new : func () {
    var obj = {
      parents : [
        SR22TNavComUpdater,
        PropertyUpdater.new(
          notifications.PFDEventNotification.DefaultType,
          notifications.PFDEventNotification.NavComData
        )
      ],
    };

    # Hack to handle cases where there is no selected COMM or NAV frequency
    if (getprop("/instrumentation/com-selected") == nil) setprop("/instrumentation/com-selected", 1);
    if (getprop("/instrumentation/nav-selected") == nil) setprop("/instrumentation/nav-selected", 1);

    obj.addPropMap("Comm1SelectedFreq", "/instrumentation/comm/frequencies/selected-mhz");
    obj.addPropMap("Comm1StandbyFreq", "/instrumentation/comm/frequencies/standby-mhz");
    obj.addPropMap("Comm1AirportID", "/instrumentation/comm/airport-id");
    obj.addPropMap("Comm1StationName", "/instrumentation/comm/station-name");
    obj.addPropMap("Comm1StationType", "/instrumentation/comm/station-type");
    obj.addPropMap("Comm1Volume", "/instrumentation/comm/volume");
    obj.addPropMap("Comm1Serviceable", "/instrumentation/comm/serviceable");

    obj.addPropMap("Comm2SelectedFreq", "/instrumentation/comm[1]/frequencies/selected-mhz");
    obj.addPropMap("Comm2StandbyFreq", "/instrumentation/comm[1]/frequencies/standby-mhz");
    obj.addPropMap("Comm2AirportID", "/instrumentation/comm[1]/airport-id");
    obj.addPropMap("Comm2StationName", "/instrumentation/comm[1]/station-name");
    obj.addPropMap("Comm2StationType", "/instrumentation/comm[1]/station-type");
    obj.addPropMap("Comm2Volume", "/instrumentation/comm[1]/volume");
    obj.addPropMap("Comm2Serviceable", "/instrumentation/comm[1]/serviceable");

    obj.addPropMap("CommSelected", "/instrumentation/com-selected");

    obj.addPropMap("Nav1SelectedFreq", "/instrumentation/nav/frequencies/selected-mhz");
    obj.addPropMap("Nav1StandbyFreq", "/instrumentation/nav/frequencies/standby-mhz");
    obj.addPropMap("Nav1ID", "/instrumentation/nav/nav-id");
    obj.addPropMap("Nav1RadialDeg", "/instrumentation/nav/radials/selected-deg");
    obj.addPropMap("Nav1Volume", "/instrumentation/nav/volume");
    obj.addPropMap("Nav1AudioID", "/instrumentation/nav/audio-btn");
    obj.addPropMap("Nav1Serviceable", "/instrumentation/nav/operable");

    obj.addPropMap("Nav2SelectedFreq", "/instrumentation/nav[1]/frequencies/selected-mhz");
    obj.addPropMap("Nav2StandbyFreq", "/instrumentation/nav[1]/frequencies/standby-mhz");
    obj.addPropMap("Nav2ID", "/instrumentation/nav[1]/nav-id");
    obj.addPropMap("Nav2RadialDeg", "/instrumentation/nav[1]/radials/selected-deg");
    obj.addPropMap("Nav2Volume", "/instrumentation/nav[1]/volume");
    obj.addPropMap("Nav2AudioID", "/instrumentation/nav[1]/audio-btn");
    obj.addPropMap("Nav2Serviceable", "/instrumentation/nav[1]/operable");

    obj.addPropMap("NavSelected", "/instrumentation/nav-selected");

    obj.addPropMap("TransponderMode", "/instrumentation/transponder/inputs/knob-mode");
    obj.addPropMap("TransponderIdent", "/instrumentation/transponder/inputs/ident-btn");
    obj.addPropMap("TransponderCode", "/instrumentation/transponder/id-code");

    return obj;
  },
};
