Config = {
    Speed = "knots", -- knots/kilometers/miles
    Altitude = "feet", -- feet/meters
    Vehicles = { -- add vehicles that you want
        {
            model = "besra", -- plane model
            color = "orange", -- green/orange/red/blue
            retractableGear = true, -- defines if plane has a retractable or not
            vtol = false -- defines if plane has a vtol or not
        },
        {
            model = "lazer",
            color = "green",
            retractableGear = true,
            vtol = false
        },
        {
            model = "hydra",
            color = "red",
            retractableGear = true,
            vtol = true
        },
        {
            model = "stunt",
            color = "blue",
            retractableGear = false,
            vtol = false
        },
    },
    AllPlanes = true, -- show Jet HUD + flight indicators on every plane model
    DefaultPlaneColor = "green", -- fallback colour for planes not listed above
    AllHelicopters = true, -- use the same flight HUD on every helicopter model
    DefaultHelicopterColor = "green",
    OnlyFirstPerson = false, -- displays HUD only in first person mode
    DisableMinimap = true, -- Set to true to hide the default GTA bottom-left minimap inside vehicles
    EnableAircraftRadar = true, -- Set to false to disable the custom green aircraft tracking radar
    StallWarning = true, -- enables stall warning (text and sound)
    AltitudeWarning = true, -- enables altitude warning (text and sound)
    AltitudeWarningHeigth = 50, -- sets the altitude under the altitude warning will turn on
    RadarRange = 1000.0, -- aircraft radar range in meters
    HelicopterHud = {
        Enabled = true, -- separate aircraft status HUD for helicopters and planes
        X = 0.3735,
        Y = 0.46
    },
    BoatHud = {
        Enabled = true,
        X = 0.865,
        Y = 0.925,
        -- Add-on boats with an incorrect vehicle class can be listed here.
        Models = { 'toro', 'toro2' }
    },
    VehicleCrosshair = {
        Enabled = true, -- GTA crosshair is enabled only while using a vehicle weapon
        HideOnFoot = true, -- hide every other on-foot crosshair
        AllVehicleWeapons = true, -- false = only the AllowedWeapons list below can show it
        AllowedWeapons = {
            -- Weapon names or numeric hashes are accepted.
            -- Examples (used only when AllVehicleWeapons = false):
            'VEHICLE_WEAPON_PLAYER_LAZER',
            'VEHICLE_WEAPON_PLAYER_HYDRA',
            'VEHICLE_WEAPON_SPACE_ROCKET',
            'VEHICLE_WEAPON_TANK'
        },
        OnFootWeapons = {
            -- Only these weapons can show the native crosshair while on foot.
            'WEAPON_SNIPERRIFLE'
        }
    },
    MovementStance = {
        CrouchKey = 'LCONTROL',
        CrawlKey = 'Z'
    },
    FireModes = {
        Enabled = true,
        DefaultMode = 'SAFE', -- SAFE / SEMI / BURST / AUTO
        BurstSize = 3,
        CycleKey = 'X'
    },
    Weapons = { -- don't touch unless you know what you're doing
        [-494786007] = "machinegun",
        [-821520672] = "missiles",
    },
}
