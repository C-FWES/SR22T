[0%]:   https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Progress_00.svg/80px-Progress_00.svg.png "00%"
[10%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Progress_10.svg/80px-Progress_10.svg.png "10%"
[20%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Progress_20.svg/80px-Progress_20.svg.png "20%"
[30%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Progress_30.svg/80px-Progress_30.svg.png "30%"
[40%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Progress_40.svg/80px-Progress_40.svg.png "40%"
[50%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Progress_50.svg/80px-Progress_50.svg.png "50%"
[60%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Progress_60.svg/80px-Progress_60.svg.png "60%"
[70%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Progress_70.svg/80px-Progress_70.svg.png "70%"
[80%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Progress_80.svg/80px-Progress_80.svg.png "80%"
[90%]:  https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Progress_90.svg/80px-Progress_90.svg.png "90%"
[100%]: https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Progress_100.svg/80px-Progress_100.svg.png "100%"
[abandonned]: http://wiki.flightgear.org/images/thumb/3/30/Cross_32px.png/16px-Cross_32px.png         "abandonné"
[done]:       http://wiki.flightgear.org/images/thumb/7/75/Tick_32px.png/16px-Tick_32px.png           "fait"
[ongoing]:    http://wiki.flightgear.org/images/thumb/3/37/Ongoing.png/16px-Ongoing.png               "en cours"
[pending]:    http://wiki.flightgear.org/images/thumb/8/8d/Hourglass_32px.png/16px-Hourglass_32px.png "en attente"
[fixed]:      http://wiki.flightgear.org/images/thumb/8/85/WIP.png/26px-WIP.png                       "réparé"
[paused]:     http://wiki.flightgear.org/images/thumb/d/dc/Paused.png/16px-Paused.png                 "en pause"
[green-bug]:  https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Green_bug.svg/32px-Green_bug.svg.png "non blocking bug"
[red-bug]:    https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Red_bug.svg/32px-Red_bug.svg.png "blocking bug"
[warning]:    https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Achtung-orange.svg/32px-Achtung-orange.svg.png "warning symbol"

![ZKV1000 in Diamond DA42, in flight from LFLG to LFBD](https://seb.lautre.net/bozon/index.php?f=15eb94e0c0e1d1)ZKV1000 in Diamond DA42, in flight from LFLG to LFBD, running STEC55X autopilot HDG roll mode.
[other pictures available here](https://seb.lautre.net/bozon/index.php?f=158cf95340742d)

# Thanks
Thanks to [www2](https://forum.flightgear.org/viewtopic.php?f=14&t=25291) the modeller of the [GDU104X project "Farmin/G1000"](http://wiki.flightgear.org/Project_Farmin/FG1000) I can continue the work began many years ago with a nicer (and working) 3D model instrument. Thanks to him/her for the SVG basis file too.  
Thanks to Hooray's nice efforts, and some examples ans snipsets of code here and there from the Canvas team.  
Thanks to all FlightGear community for the funny project I let too many years off side... Especially to authors of Avidyne Entegra 9 on extra500, from which the map is largely inspired (and many lines of code copied and adapted): Dirk Dittmann and Eric van den Berg 

# Origin
The first ZKV1000, which was completly XML animated, was completly abandonned. Moreover the Nasal code became unmaintanable from my point of view. Not sure this one is better, but I think
it is at least more modulable.

The origin is to simulate a Garmin Primus 1000, as near as possible of the [documentation found](# documentation).

But as we are in a simulation, the zkv1000 is **definitly not** a replica of the well-known G1000, as it takes the liberty to be integrated with some features that doesn't exit in
the real device, as well as some real features aren't scheduled to be implemented. But, it should be easy to add or remove features in order to get the real device. 
This is GPL-2 license though :)

# Objectives
There is no intention to provide a fully qualified G1000 in order to train or so, but this should be possible to be done from the zkv1000.

I'm particulary looking at these points:

1.  easy to implement new features
1.  optimized code (from my non-dev point of view...)
1.  easy to integrate in every cockpit with only few lines, and with easy use for the pilot
1.  near from the G1000 documentation but with some neat features added, and some unrelevant features in a sim removed

# Progress
Note: this is not because the progress bar show 100% that it means it is 100% bug free :)
Please report bug at <zkv1000@seb.lautre.net>.

* ![][100%]
  * The whole 3D model is animated, with necessary popups (in order to separate nested knobs for example), and adaptable to the size of the panel.
  * The basic fligth instrumentation is here (AI, speeds, altitude and vertical speed, etc.), plus many other helpers and information (often displayed in widgets or alerts). Also the radio stack (NAV and COMM) tools are implemented. ADF is available for bearing.
  * The official autopilot [GFC700 from the official Stuart Buchanan's FG1000](http://wiki.flightgear.org/FG1000#GFC700_Autopilot) is available and usable.
  * Screens are fully animated, with softkeys and menus, on map (PFD inset and MFD) background is configurable with the preferred one, navaids and [route](https://seb.lautre.net/git/seb/zkv1000/issues/6) are displayed. Traffic and topography layers are available for display only on MFD screen (not in PFD inset as the window is too small).
  * There is also per-aircraft settings storage for preferred units (speed, distance, etc.).
  * Flightplan management is delegated to the more usable FG interface lauched from inside the zkv100, but it is possible to use DirectTo on selected navaid, and OBS mode with GPS.
  * Checklists are managed, including separation between emergency and normal checklists (and aircraft agnostic, should be compatible with most systems). Moreover a alerting system allow to show specific alerts for your aircraft, just register a new alert check and PFDs will warn the pilot about.
  * ... and many more ! :)
* ![][90%]
  * route displayed on map: legs ![][done], current and next leg ![][done], OBS ![][done], TOC/TOD ![][ongoing]
  * XPDR: emergency code depending of the country (eg.: 1200 for US, 7700 for Europe), should be set in settings
* ![][80%]
  * Flight plans catalog (display on map doesn't work each time...)
  * Alerts: voice description of the alert ![][ongoing]
* ![][60%]
  * NOT TESTED: add the posssibility to only use Nasal part of the instrument. This in case of a cockpit which already includes needed objects and animations for screens, knobs and buttons in its config files
* ![][50%]
  * integration of Octal450's [S-TEC 55X](http://wiki.flightgear.org/S-TEC_55X) autopilot system ![][ongoing]
  * EIS: animations for temperature for YaSim and JSBSim with provided default single-prop EIS
  * make the switch back on working for MFD display and radios ![][ongoing]
* ![][10%]
  * multikey for every part of the device (actually only power on)
  * Aircraft Maintainer's Guide ![][ongoing]
  * User's Guide ![][ongoing]
* ![][0%] (TODO list, unsorted)
  * make possible to integrate other autopilot systems than the one integrated
  * make booting animation visible
  * CDI/GPS: scale depending of the flight phase
  * Weather map
  * replace the use of `clip` by a better system in map display (think also about INSET)
  * VS guidance
  * VNAV
  * scrolling lift in menus
  * tutorials
  * [touchable screen](http://wiki.flightgear.org/Canvas_Event_Handling) ([other interesting link](http://wiki.flightgear.org/Touch_Animation))
  * many more...

# Installation
Just `git clone https://seb.lautre.net/git/seb/zkv1000.git` in your favorite `Instrumentation-3d` dir or directly in your aircraft files structure.  
Please note that the `Instruments-3d` dir is recommended as the zkv1000 wants to integrate the official `$FGDATA/Aircraft/Instruments-3d` some days  
Then somewhere in the XML configuration of your aircraft, put only few lines as described below
## Create the `zkv1000` Nasal namespace
In the `<nasal>` place of your aircraft configuration, tell FlightGear where to find the `zkv1000.nas` file

        <zkv1000>
            <file>Aircraft/Instruments-3d/zkv1000/zkv1000.nas</file>
        </zkv1000>

or

        <zkv1000>
            <file>Aircraft/My-Nice-Aircraft/arbitrary/dirs/zkv1000-or-not/zkv1000.nas</file>
        </zkv1000>

Actually `zkv1000.nas` is where everything begins, please have a look at this code, it would help you to follow the script.

## Set specific values for your aircraft
Specifics values for aircraft can be set via the aircraft configuration, in the `<instrumentation>` section, just add a section `<zkv1000>` and set here the needed values.

### Adjust size to  the panel of your aircraft
To increase or decrease the size of all the devices (PFDs and MFDs) you can use a factor property, eg. in the DA42:

        <size-factor type="double">1.19</size-factor>

Defaults to 1 if you don't provide this information. Values lower than 1 decreaase size, and higher than 1 increase the size.

### Make your instrument auto powered on
Let say you want your PFD and MFD switched on as soon as the electrical system allows it. Set your device with the following

        <auto-power type="bool">1</auto-power>

Then you need to set the property `/instrumentation/zkv1000/serviceable` by the mean you want, as soon as it property is `true` the zkv1000 will automagically switch on.

### Vspeeds
To see the Vspeeds bugs or the IAS background color change (Vne), set the corresponding V-speeds <b>in knots</b> by adding them in your `<instrumentation><zkv1000><alerts>` section the following lines (here an example ![][warning] values are not to be used in real life).
If not set, Vne defaults to 999 knots

        <alerts>
          <Vx>99</Vx>
          <Vy>110</Vy>
          <Vr>65</Vr>
          <Vglide>80</Vglide>
          <Vne>170</Vne>
        </alerts>

You can define as many Vspeed you need, with arbitrary names, they only need to be named `Vfoo` (name must begin by a uppercase V) to be recognize as a Vspeed.

All defined Vspeeds (except Vne) can be adjusted from inside the zkv1000.

### EIS
This parameter tells the zkv1000 which kind of engines equips your aircraft, and the associated EIS.  
The Nasal script should include at least three things:

* a method called `displayClass.showEIS` in which you initialize the EIS, especially by selecting the shown, hide, clipped and texts elements
* a method called `displayClass.updateEIS` which is used to update the EIS display, it includes its own timer to refresh itself
* a SVG object with ID `EIS` (generally the background of the EIS display).  
  It should appears in the lists in `displayClass.showEIS`.  
  ![][warning] This object is used to compute the map width, so it is important to set it on the left of the screen

There are three ways too put an EIS in MFD:

#### use one of the included simple EIS provided with the zkv1000

        <eis>
          <type>single-prop</type>
        </eis>

Defaults to `none`, available entries are the `.nas` files located in `Nasal/EIS/` directory.

#### or use the one you specially have created for your aircraft

        <eis>
          <file>Aircraft/My-Nice-Aircraft/Nasal/EIS.nas</file>
        </eis>

or the one from another aircraft. Anyway if the EIS nasal file targeted doesn't exist, the fallback is the type `none`.

#### or you can give the absolute path (![][warning] not supported)

        </eis>
          <file>/home/foobar/fgfs-data/Nasal/testing-jet-jsbsim-EIS.nas</file>
        </eis>

Be aware that `canvas.parsesvg` uses only relative path and should not work properly if your .nas is outside of the FG tree.  
If you want to add your own EIS, just copy the `Models/EIS/single-prop.svg`, modify it to fit your needs, and refer to it in a function named `displayClass.showEIS`, another very important function is `displayClass.updateEIS` (example in [Nasal/EIS/single-prop.nas](zkv1000/blob/master/Nasal/EIS/single-prop.nas))  
You are even free to modify the softkeys map in order to get according menus, but this has to be described on another document (check [Nasal/softkeys.nas](zkv1000/master/blob/Nasal/softkeys.nas)).

No matter of the EIS width, as the map size and center are computed relative to the EIS width automatically.  

_Notes:_

  1. you can use `<file>` or `<type>` indifferently, they are actually identical.
  1. later on the MFD Engine pages will be managed by the file specified in this section

### Angle Of Attack (AOA)
You can specify the stall AoA in order to display it in the dedicated display.

        <alerts>
          <stall-aoa>15</stall-aoa>
          <approach-aoa>4</approach-aoa>
        </alerts>

* Values are in degrees.
* If `<stall-aoa>` is not specified or equals to `0` (zero) the AOA display won't be accessible.
* The `<approach-aoa>` is optionnal, if present a blue marker is visible on AOA display (not in real GarminP1000)

### Flight plans catalog
You can specify a directory where to find the flightplans you save. Defaults to `$FG_HOME/Export`

        <flightplans type="string">/absolute/path/to/your/flightplans/location</flightplans>

Only the flightplans set for a departure from your position will be shown, no matter of the name of the file (even extension), each will be parsed to find the ones corresponding to your departure location.
The list will show only 6 flightplans, but it's scrollable so you can handle much more.

### Alerting system
You can set some alerts of your choice. Note that there are 3 levels:

* `0`: INFO
* `1`: WARNING
* `2`: ALERT

Alerts are identified by the displayed message, so you can't provide two alerts with the same alert message. The higher level is shown first in list displayed on PFD (press `ALERT` softkey), all levels should be integers at least if less than 2. The tests are executed each second.

To come: a voice alert if needed and configured (but I'm facing issue of multiple alerts at the same time, temporisation is ongoing).

To register your alerts you have two ways:
#### set the alerts in `/instrumentation/zkv1000/alerts/warnings`
This way they are registered at start

        <warnings>
          <warning>
            <_script><![CDATA[
              getprop('/foo/bar/baz/value') and getprop('/foo/bar/baz/value[1]') > 5;
            ]]></_script>
            <message>TEST 1</message>
            <!-- <speaker/> TO USE THE MESSAGE AS VOICE -->
            <level>0</level>
          </warning>
          <warning>
            <_script><![CDATA[
              getprop('/foo/bar/baz/value[3]') == 'foobar' or getprop('/foo/bar/baz/value[2]') < 10;
            ]]></_script>
            <message>TEST 2</message>
            <level>1</level>
            <!-- <speaker>this is only for testing</speaker> TO USE A SPECIFIC VOICE MESSAGE -->
          </warning>
          <warning>
            <_script><![CDATA[
              return getprop('/foo/bar/baz/value[4]') == 5 or getprop('/foo/bar/baz/value[5]');
            ]]></_script>
            <message>TEST 3</message>
            <level>2</level>
          </warning>
        </warnings>
        
Please note that I intentionnaly broke the `script` XML element because of my Markdown Heodown limitations

#### or use the integrated API
Actually not yet tested, but you can register new alerts somewhere in your Nasal code with the following:

        zkv1000.annunciations.register(props.globals.new({
            message: "a message",
            level: 20,
            script: "if (something) return 1; else return 0;"
        }));

It also exists a `zkv1000.annunciations.del(message)` to delete a warning from the register list, so it won't be tested anymore.

## 3D models
In the definition of your flightdeck (here are the values for the installation in the Lancair 235 in which I develop the device)
put it everywhere you want to. Note that the path `Aircraft/Instruments-3d/zkv1000` is dependant on the path where the zkv1000 is installed, this can be somewhere like `Aircraft/My-Nice-Aircraft/arbitrary/dirs/zkv1000-or-not`as mentionned earlier in this section.

        <model>
            <path>Aircraft/Instruments-3d/zkv1000/pfd-pilot.xml</path>
            <offsets>
                <x-m> -0.023 </x-m>
                <y-m> -0.235 </y-m>
                <z-m> -0.028 </z-m>
            </offsets>
        </model>
        <model>
            <path>Aircraft/Instruments-3d/zkv1000/mfd.xml</path>
            <offsets>
                <x-m>  0.03  </x-m>
                <y-m>  0.06  </y-m>
                <z-m> -0.028 </z-m>
                <heading-deg> -15 </heading-deg>
            </offsets>
        </model>

You can put as many devices as wanted, but generally they are two (PFD+MFD) or three (2 PFD+ 1 PFD), can be only one which is useful when you just want the PFD or the MFD in your cockpit.
The device are identified by a name, which should be unique unless they won't be independant.
This name is set by one of the property in the XML model file (`instrumentation/zkv1000/<NAME>/status`), which is a property telling if the device is switched off or not (or in reversionnary mode, later).
Actually there are only two "types of display": MFD or PFD, which is known by the first 3 letters of the name (case sensitive!)
Other devices as keyboard or non-display can also exists, as long as they don't have a `status` property...
Not sur I'm clear on this point though :)

## Autopilot
There are two systems supported: the GFC700 shipped with the official Stuart Buchanan's FG1000 and the Octal450's STEC 55X (and at time of writing only HDG and buggy NAV/GPS modes are available).

### GFC700
To make the magic operate, you just need to insert these lines into the `sim/systems` section. Be aware that this autopilot [has been tuned for the Cessna 182, so may not be correct for light jets](http://wiki.flightgear.org/FG1000#Include_the_GFC700_autopilot_.28optional.29).

        <autopilot>
          <path>Aircraft/Instruments-3d/FG1000/GFC700.xml</path>
        </autopilot>

### S-TEC 55X
To make it available you have to follow the installation rules of the device [on its own page](http://wiki.flightgear.org/S-TEC_55X). The zkv1000 will find it by its own and make it available.

This STEC55X autopilot system would remain shipped in the zkv1000 as it is described in the documentation of Cirrus Perspective SR2x, but the zkv1000 will in near future let you create your own and make its choice depending of the availibilities or property set.

## Map tiles origin
By defaults the maps tiles come from `https://maps.wikimedia.org`, type `osm-intl` (please read [https://www.wikimedia.org/wiki/Maps]()), but you can choose your favorite one if you've got one. I've tested `opentopomap.org` and `thunderforest.com` (my favourite).
You can tell the zkv1000 the tile server, type and eventually apikey by using `--prop:` option while starting FlightGear session:

In case of apikey (or whatever added at the en of the URL):

        --prop:/sim/online-tiles-server=tile.thunderforest.com
        --prop:/sim/online-tiles-type=landscape
        --prop:/sim/online-tiles-apikey=?apikey=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

or if there is no type, just use type `/`:

        --prop:/sim/online-tiles-server=a.tile.opentopomap.org
        --prop:/sim/online-tiles-type=/

The only used protocol is `https` but you can provide your own template with option

        --prop:/sim/online-tiles-template=http://{server}/{type}/{z}/{x}/{y}.jpeg

An option is also available to tell the format of the tile image which can be used in template with the `{format}` anchor

        --prop:/sim/online-tiles-format=jpeg

## Switch it up
### Autopower on/off
You can set an electrical system to make the property `/instrumentation/zkv1000/serviceable` reflect the alimentation of the ZKV1000 (boolean or volts > 12). Then configure the zkv1000 to auto power on as soon as it is known as serviceable withe the following

        <instrumentation>
          <zkv1000>
            <auto-power type="bool">1</auto-power>
          <zkv1000>
        </instrumentation>

Note that will also switch off the zkv1000 if it becomes non-serviceable.

The re-switching on is buggy (the MFD doesn't re-display the contents and the NAV/COMM utils aren't available anymore... working on it)
### Manually
If you haven't set a electrical system to make the property `/instrumentation/zkv1000/serviceable` to reflect the availibity of the ZKV1000, and you haven't set the auto-power, then you can use the multikey (souvenirs, thanks to Melchior having that much expended this feature years ago :)) service by typing:
`:zo`

The `:z` will be the multikey entry for all multikeys of the zkv1000.

1. If you see a single red dot under the `ZKV100O xxx init` message (xxx = MFD or PFD), this is likely the sim is paused (press `p` by default to stop the pause).
1. If you see multiple dots under the `ZKV1000 xxx init` message, something wrong happened, time to check console
1. If you see only black screen on one of the screen, something really wrong happened, time to check console

# Known issues
Please send issues to <zkv1000@seb.lautre.net>  
[issues are listed here](https://seb.lautre.net/git/seb/zkv1000/issues)

# Documentation
Documentation is being actively written. There are two differents guides:

* [Aircraft Maintainer's Guide](http://wiki.flightgear.org/User:Zakharov/zkv1000_installation_guide)
* [User's Guide](http://wiki.flightgear.org/User:Zakharov/zkv1000_user_guide)

Here is a list of useful links:

* [Canvas in FG](http://wiki.flightgear.org/Category:Canvas)
* [Nasal](http://wiki.flightgear.org/Category:Nasal)
* the guides used to create the scenario from [Garmin website](http://support.garmin.com/support/manuals/searchManuals.faces)
    * [G1000 Pilot’s Guide for the Diamond DA42 (v0370.22)](http://static.garmin.com/pumac/190-00406-07_0B_Web.pdf) *(94 pages)*
    * [Pilot's Guide, Cirrus Perspective, SR2x (v0764.30)](http://static.garmin.com/pumac/190-00820-11_A.pdf) *(752 pages)*

# FG1000
There is an implementation of the Primus Garmin 1000 by Stuart Buchanan which is much more respectful of the Canvas principles, using new technology Emesary, with far better coding style, and with the intent to stay close as possible with the Garmin 1000 real device.  
The device is avaiblable in [FGData repo](https://sourceforge.net/p/flightgear/fgdata/ci/next/tree/Aircraft/Instruments-3d/FG1000) and has a [specific wiki page](http://wiki.flightgear.org/FG1000).
