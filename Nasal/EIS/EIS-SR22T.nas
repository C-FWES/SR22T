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
# SR22T EIS - Copyright 2020 Julio Santa Cruz (Barta)

var EIS =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        EIS,
        MFDPage.new(mfd, myCanvas, device, svg, "EIS", "")
      ],
    };

    obj.setController(fg1000.EISController.new(obj, svg));

    obj.addTextElements(["PowerDisplay", "RPMDisplay", "ManDisplay", "FuelFlowDisplay", "OilTempDisplay", "OilPressureDisplay", "Batt1Display", "ESSDisplay","CHTDisplay","EGTDisplay" ]);

    obj._PowerPointer = PFD.RotatingElement.new(obj.pageName, svg, "PowerPointer", 0, 1.15, 160, [300,100]);
    
    obj._fuelFlowPointer    = PFD.PointerElement.new(obj.pageName, svg, "FuelFlowPointer", 0.0, 38.0, 135);
    obj._oilPressurePointer = PFD.PointerElement.new(obj.pageName, svg, "OilPressurePointer", 0.0, 115.0, 135);
    obj._oilTempPointer     = PFD.PointerElement.new(obj.pageName, svg, "OilTempPointer", 0.0, 245.0, 135);
    
    obj._ampBattAPointer     = PFD.PointerElement.new(obj.pageName, svg, "Batt1Pointer", 0.0, 6, 135);
    obj._EssBusPointer     = PFD.PointerElement.new(obj.pageName, svg, "ESSPointer", 0.0, 30, 135);
    
    #obj._EGTPointer         = PFD.PointerElement.new(obj.pageName, svg, "EGTPointer", 0.0, 1.0, 135);
    #obj._EGTCylinder        = PFD.PointerElement.new(obj.pageName, svg, "EGTCylinder", 0.0, 1.0, 135);
    #obj._leftFuelPointer    = PFD.PointerElement.new(obj.pageName, svg, "LeftFuelPointer", 0.0, 40.0, 135);
    #obj._rightFuelPointer   = PFD.PointerElement.new(obj.pageName, svg, "RightFuelPointer", 0.0, 40.0, 135);
    
    

    return obj;
  },

  updateEngineData : func(engineData) {
    #var power = math.max(math.min(math.round((engineData.Man -8) / 0.205),100), 0);
    #var power = math.max(math.min(math.round((engineData.Man -8) / 0.28),115), 0);
    me.setTextElement("RPMDisplay", sprintf("%i", engineData.RPM));
    me.setTextElement("ManDisplay", sprintf("%.1f", engineData.Man));
    me.setTextElement("FuelFlowDisplay", sprintf("%.1f", engineData.FuelFlowGPH));
    me.setTextElement("OilTempDisplay", sprintf("%.1f", engineData.OilTemperatureF));
    me.setTextElement("OilPressureDisplay", sprintf("%.1f", engineData.OilPressurePSI));
    me.setTextElement("EGTDisplay", sprintf("%.1f", engineData.EGTDegF));
    me.setTextElement("CHTDisplay", sprintf("%.1f", engineData.CHTDegF));
#    me.setTextElement("MBusVolts", sprintf("%.01f", engineData.MBusVolts));
    me.setTextElement("ESSDisplay", sprintf("%.01f", engineData.MBusVolts)); # TODO: Include Emergency Bus
    
    me._fuelFlowPointer.setValue(engineData.FuelFlowGPH);
    me._oilPressurePointer.setValue(engineData.OilPressurePSI);
    me._oilTempPointer.setValue(engineData.OilTemperatureF);
    me._ampBattAPointer.setValue(0);
    me._EssBusPointer.setValue(engineData.MBusVolts); # TODO: use ESS 
    
    # From http://www.kineticlearning.com/pilots_world/cmpp/03_06/displayarticle.aspx
    # Percent Power – The MFD uses the RPM, fuel flow, manifold pressure, and 
    # outside air temperature to determine the percentage of rated power 
    # being produced.
    # 
    # From the POH
    # The digital percent power value is displayed in white numerals below the gage. 
    # The display units calculate the percentage of maximum engine power 
    # produced by the engine based on an algorithm employing manifold pressure, 
    # indicated air speed, outside air temperature, pressure altitude, engine 
    # speed, and fuel flow.
    me.setTextElement("PowerDisplay", sprintf("%i", engineData.PowerPCT * 100));
    me._PowerPointer.setValue(engineData.PowerPCT);
  },

  updateFuelData : func(fuelData) {
    #me._leftFuelPointer.setValue(fuelData.LeftFuelUSGal);
    #me._rightFuelPointer.setValue(fuelData.RightFuelUSGal);
  },

  # Menu tree .  engineMenu is referenced from most pages as softkey 0:
  # pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EISPage.engineMenu);
  engineMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(1, "LEAN", pg, pg.mfd.EIS.leanMenu);
    pg.addMenuItem(2, "SYSTEM", pg, pg.mfd.EIS.systemMenu);
    pg.addMenuItem(8, "BACK", pg, pg.topMenu);
    device.updateMenus();
  },

  leanMenu : func(device, pg, menuitem) {
      pg.clearMenu();
      pg.resetMenuColors();
      pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
      pg.addMenuItem(1, "LEAN", pg, pg.mfd.EIS.leanMenu);
      pg.addMenuItem(2, "SYSTEM", pg, pg.mfd.EIS.systemMenu);
      pg.addMenuItem(3, "CYL SELECT", pg);
      pg.addMenuItem(4, "ASSIST", pg);
      pg.addMenuItem(9, "BACK", pg, pg.mfd.EIS.engineMenu);
      device.updateMenus();
  },

  systemMenu : func(device, pg, menuitem) {
      pg.clearMenu();
      pg.resetMenuColors();
      pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
      pg.addMenuItem(1, "LEAN", pg, pg.mfd.EIS.leanMenu);
      pg.addMenuItem(2, "SYSTEM", pg, pg.mfd.EIS.systemMenu);
      pg.addMenuItem(3, "RST FUEL", pg, func(dev, pg, mi) { pg.mfd.EIS.getController().setFuelQuantity(0); });
      pg.addMenuItem(4, "GAL REM", pg, pg.mfd.EIS.galRemMenu);
      pg.addMenuItem(5, "BACK", pg, pg.mfd.EIS.engineMenu);
      device.updateMenus();
  },

  galRemMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(1, "LEAN", pg, pg.mfd.EIS.leanMenu);
    pg.addMenuItem(2, "SYSTEM", pg, pg.mfd.EIS.systemMenu);
    pg.addMenuItem(3, "-10 GAL", pg, func(dev, pg, mi) { pg.mfd.EIS.getController().updateFuelQuantity(-10); } );
    pg.addMenuItem(4, "-1 GAL",  pg, func(dev, pg, mi) { pg.mfd.EIS.getController().updateFuelQuantity(-1); });
    pg.addMenuItem(5, "+1 GAL",  pg, func(dev, pg, mi) { pg.mfd.EIS.getController().updateFuelQuantity(1); });
    pg.addMenuItem(6, "+10 GAL", pg, func(dev, pg, mi) { pg.mfd.EIS.getController().updateFuelQuantity(10); });
    pg.addMenuItem(7, "44 GAL",  pg, func(dev, pg, mi) { pg.mfd.EIS.getController().setFuelQuantity(44); });
    pg.addMenuItem(8, "BACK", pg, pg.mfd.EIS.engineMenu);
    device.updateMenus();
  },

  offdisplay : func() {
    me._group.setVisible(0);

    # Reset the menu colours.  Shouldn't have to do this here, but
    # there's not currently an obvious other location to do so.
    for(var i = 0; i < 12; i +=1) {
      var name = sprintf("SoftKey%d",i);
      me.device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
      me.device.svg.getElementById(name).setColor(1.0,1.0,1.0);
    }
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._group.setVisible(1);
    me.getController().ondisplay();
  },


};
