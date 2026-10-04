# Aircraft HUD Resource 3.1.23

Install this folder inside your FiveM server `resources` directory and add:

```cfg
ensure aircraft_hud
```

## Controls

- `F6`: open or close the controls-only menu (windows, seats, doors and auxiliary controls)
- `/toggledash`: toggle the road-vehicle dashboard
- `B`: toggle the built-in notification-free seatbelt status icon

## Configuration

Edit `config.lua` to add supported HUD aircraft, change units, warnings, or the
aircraft radar range. The default radar range is 40,000 metres (40 km).

`esx_status` is optional. If it is running, hunger and thirst are shown. The
resource starts normally without ESX.

## Main fixes in 2.1.0

- Hide the road-vehicle dashboard for boats; boats remain clear for a separate Boat HUD.
- Replace the previous helicopter panel with the supplied flight-status HUD design.
- Add a dedicated Boat HUD with knots, heading, fuel, engine and hull condition.
- Detect standard and add-on boats using class, ped, model-native and configurable model checks.
- Restore the supplied helicopter UI exactly without redesigning its layout or colours.
- Restore the supplied Boat HUD with its original speed, depth, fuel, heading and coordinates layout.
- Use the supplied compact five-panel helicopter UI and remove third-party attribution messages.
- Combine both supplied helicopter HUD layouts into one panel without duplicated readouts.
- Align all combined helicopter HUD cells inside one shared width and remove text overlap.
- Remove the combined helicopter panel and restore the supplied simple five-panel HUD only.
- Replace the simple helicopter panel with the supplied advanced flight-status UI.
- Show the helicopter HUD and its data only while the helicopter engine is running.
- Match Boat HUD behaviour: keep the empty helicopter panel visible with the engine off and show live values only after engine start.
- Use the supplied RGB 51/62/52 inactive colour for helicopter labels, borders and every status box while the engine is off.
- Add the supplied six SVG flight indicators to the Plane HUD only, with live aircraft data.
- Load flight indicators as classic NUI scripts and auto-show them from plane telemetry after resource restarts.
- Export the flight-indicator class into the NUI global scope before initializing Plane HUD instruments.
- Detect every standard and add-on plane instead of limiting Plane HUD loading to the configured model list.
- Bundle the indicator class and Plane HUD controller into one top-level NUI script to remove import/global/load-order failures.
- Use the original FIJS indicator markup and SVG gauges, remove the custom panel, and resolve SVGs through absolute FiveM NUI URLs.

- Correct resource directory structure and manifest paths.
- Load the actual aircraft radar script and use the configured 40 km range.
- Correct radar scaling, circular bounds, distance filtering, and idle waits.
- Detect aircraft when changing directly between vehicles.
- Validate lock-on targets and reset warning/HUD state on exit.
- Connect the separate dashboard page to the main NUI page.
- Keep speed/RPM/fuel/temperature details on the road dashboard only; the F6 menu now contains controls only.
- Correct indicator/hazard state reading and high-beam toggling.
- Remove random ABS warnings and fake heading-based odometer values.
- Validate door and seat indices and restore dynamic seat buttons.
- Remove duplicate engine-action callbacks and missing sound dependencies.
- Include the complete vehicle-menu and aircraft-warning sound pack.
- Move the compact speed meter and all vehicle data to the bottom-right.
- Replace raw status percentages with food, drink and armor cards at bottom-left.
- Add a bottom-left seatbelt ON/OFF icon without popup notifications.
- Remove the outer black status-HUD background and fix the seatbelt card layout.
- Polish the vehicle dashboard into one aligned glass panel with large digital gauge values.
- Remove the extra bottom-left seatbelt card and redesign gauges as modern 270-degree digital arcs.
- Remove the sound-system console message, fix compact temperature labels, and use the dashboard for helicopters while planes use Jet HUD only.
- Replace the global window up/down buttons with individual FL/FR/RL/RR open-close toggles.
- Integrate the supplied native helicopter HUD with engine, main rotor, tail rotor, altitude, airspeed, landing limiter and delayed engine shutdown.
- Improve helicopter HUD compatibility with class-based detection, original text natives and the supported rear-rotor health native.
- Make ESX status integration optional and support `val` fallback values.
