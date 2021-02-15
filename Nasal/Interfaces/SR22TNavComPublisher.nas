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
#
# This maps properties to Emesary Messages that will be published using the
#
# notifications.PFDEventNotification.NavComData
#
var SR22TNavComPublisher =
{
  new : func (period=0.5) {
    var obj = {
      parents : [
        SR22TNavComPublisher,
      ],
    };

    # We have two publishers here:
    #
    # 1) a triggered publisher for properties that will change ocassionally, but which
    # we need to update immediately. These are typically settings.
    #
    # 2) a periodic publisher which triggers every 0.5s to update data values.

    obj._triggeredPublisher = TriggeredPropertyPublisher.new(notifications.PFDEventNotification.NavComData);
    obj._periodicPublisher = PeriodicPropertyPublisher.new(notifications.PFDEventNotification.NavComData, period);

    # Hack to handle cases where there is no selected Com or NAV frequency
    if (getprop("/instrumentation/com-selected") == nil) setprop("/instrumentation/com-selected", 1);
    if (getprop("/instrumentation/nav-selected") == nil) setprop("/instrumentation/nav-selected", 1);

    obj._triggeredPublisher.addPropMap("Comm1SelectedFreq", "/instrumentation/comm/frequencies/selected-mhz");
    obj._triggeredPublisher.addPropMap("Comm1StandbyFreq", "/instrumentation/comm/frequencies/standby-mhz");
    obj._triggeredPublisher.addPropMap("Comm1AirportID", "/instrumentation/comm/airport-id");
    obj._triggeredPublisher.addPropMap("Comm1StationName", "/instrumentation/comm/station-name");
    obj._triggeredPublisher.addPropMap("Comm1StationType", "/instrumentation/comm/station-type");
    obj._triggeredPublisher.addPropMap("Comm1Volume", "/instrumentation/comm/volume");
    obj._triggeredPublisher.addPropMap("Comm1Serviceable", "/instrumentation/comm/serviceable");

    obj._triggeredPublisher.addPropMap("Comm2SelectedFreq", "/instrumentation/comm[1]/frequencies/selected-mhz");
    obj._triggeredPublisher.addPropMap("Comm2StandbyFreq", "/instrumentation/comm[1]/frequencies/standby-mhz");
    obj._triggeredPublisher.addPropMap("Comm2AirportID", "/instrumentation/comm[1]/airport-id");
    obj._triggeredPublisher.addPropMap("Comm2StationName", "/instrumentation/comm[1]/station-name");
    obj._triggeredPublisher.addPropMap("Comm2StationType", "/instrumentation/comm[1]/station-type");
    obj._triggeredPublisher.addPropMap("Comm2Volume", "/instrumentation/comm[1]/volume");
    obj._triggeredPublisher.addPropMap("Comm2Serviceable", "/instrumentation/comm[1]/serviceable");

    obj._triggeredPublisher.addPropMap("CommSelected", "/instrumentation/com-selected");

    obj._triggeredPublisher.addPropMap("Nav1SelectedFreq", "/instrumentation/nav/frequencies/selected-mhz");
    obj._triggeredPublisher.addPropMap("Nav1StandbyFreq", "/instrumentation/nav/frequencies/standby-mhz");
    obj._periodicPublisher.addPropMap("Nav1ID", "/instrumentation/nav/nav-id");
    obj._periodicPublisher.addPropMap("Nav1InRange", "/instrumentation/nav/in-range");
    obj._periodicPublisher.addPropMap("Nav1HeadingDeg", "/instrumentation/nav/heading-deg");
    obj._periodicPublisher.addPropMap("Nav1RadialDeg", "/instrumentation/nav/radials/selected-deg");
    obj._periodicPublisher.addPropMap("Nav1DistanceMeters", "/instrumentation/nav/nav-distance");
    obj._periodicPublisher.addPropMap("Nav1CourseDeviationDeg", "/instrumentation/nav/crosstrack-heading-error-deg");
    obj._periodicPublisher.addPropMap("Nav1CrosstrackErrorM", "/instrumentation/nav/crosstrack-error-m");
    obj._periodicPublisher.addPropMap("Nav1Localizer", "/instrumentation/nav/nav-loc");
    obj._periodicPublisher.addPropMap("Nav1Deflection", "/instrumentation/nav/heading-needle-deflection-norm");
    obj._periodicPublisher.addPropMap("Nav1GSDeflection", "/instrumentation/nav/gs-needle-deflection-norm");
    obj._periodicPublisher.addPropMap("Nav1GSInRange", "/instrumentation/nav/gs-in-range");
    obj._periodicPublisher.addPropMap("Nav1From", "/instrumentation/nav/from-flag");

    obj._triggeredPublisher.addPropMap("Nav1Volume", "/instrumentation/nav/volume");
    obj._triggeredPublisher.addPropMap("Nav1AudioID", "/instrumentation/nav/audio-btn");
    obj._triggeredPublisher.addPropMap("Nav1Serviceable", "/instrumentation/nav/operable");

    obj._triggeredPublisher.addPropMap("Nav2SelectedFreq", "/instrumentation/nav[1]/frequencies/selected-mhz");
    obj._triggeredPublisher.addPropMap("Nav2StandbyFreq", "/instrumentation/nav[1]/frequencies/standby-mhz");
    obj._periodicPublisher.addPropMap("Nav2ID", "/instrumentation/nav[1]/nav-id");
    obj._periodicPublisher.addPropMap("Nav2InRange", "/instrumentation/nav[1]/in-range");
    obj._periodicPublisher.addPropMap("Nav2HeadingDeg", "/instrumentation/nav[1]/heading-deg");
    obj._periodicPublisher.addPropMap("Nav2RadialDeg", "/instrumentation/nav[1]/radials/selected-deg");
    obj._periodicPublisher.addPropMap("Nav2DistanceMeters", "/instrumentation/nav[1]/nav-distance");
    obj._periodicPublisher.addPropMap("Nav2CourseDeviationDeg", "/instrumentation/nav[1]/crosstrack-heading-error-deg");
    obj._periodicPublisher.addPropMap("Nav2CrosstrackErrorM", "/instrumentation/nav[1]/crosstrack-error-m");
    obj._periodicPublisher.addPropMap("Nav2Localizer", "/instrumentation/nav[1]/nav-loc");
    obj._periodicPublisher.addPropMap("Nav2Deflection", "/instrumentation/nav[1]/heading-needle-deflection-norm");
    obj._periodicPublisher.addPropMap("Nav2GSDeflection", "/instrumentation/nav[1]/gs-needle-deflection-norm");
    obj._periodicPublisher.addPropMap("Nav2GSInRange", "/instrumentation/nav[1]/gs-in-range");
    obj._periodicPublisher.addPropMap("Nav2From", "/instrumentation/nav/from-flag");

    obj._triggeredPublisher.addPropMap("Nav2Volume", "/instrumentation/nav[1]/volume");
    obj._triggeredPublisher.addPropMap("Nav2AudioID", "/instrumentation/nav[1]/audio-btn");
    obj._triggeredPublisher.addPropMap("Nav2Serviceable", "/instrumentation/nav[1]/operable");


    obj._triggeredPublisher.addPropMap("ADFSelectedFreq", "/instrumentation/adf/frequencies/selected-khz");
    obj._periodicPublisher.addPropMap("ADFInRange", "/instrumentation/adf/in-range");
    obj._periodicPublisher.addPropMap("ADFHeadingDeg", "/instrumentation/adf/indicated-bearing-deg");
    obj._triggeredPublisher.addPropMap("ADFVolume", "/instrumentation/adf/volume-norm");
    obj._triggeredPublisher.addPropMap("ADFServiceable", "/instrumentation/adf/operable");

    obj._triggeredPublisher.addPropMap("MarkerBeaconInner", "/instrumentation/marker-beacon/inner");
    obj._triggeredPublisher.addPropMap("MarkerBeaconMiddle", "/instrumentation/marker-beacon/middle");
    obj._triggeredPublisher.addPropMap("MarkerBeaconOuter", "/instrumentation/marker-beacon/outer");

    obj._triggeredPublisher.addPropMap("NavSelected", "/instrumentation/nav-selected");

    obj._triggeredPublisher.addPropMap("TransponderMode", "/instrumentation/transponder/inputs/knob-mode");
    obj._triggeredPublisher.addPropMap("TransponderIdent", "/instrumentation/transponder/inputs/ident-btn");
    obj._triggeredPublisher.addPropMap("TransponderCode", "/instrumentation/transponder/id-code");

    return obj;
  },

  start : func() {
    me._triggeredPublisher.start();
    me._periodicPublisher.start();
  },

  stop : func() {
    me._triggeredPublisher.stop();
    me._periodicPublisher.stop();
  },

};
