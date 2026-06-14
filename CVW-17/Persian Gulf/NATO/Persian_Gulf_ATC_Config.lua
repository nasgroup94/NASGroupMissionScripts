NASG_ATC = NASG_ATC or {}

NASG_ATC:RegisterAirport({
    Id = "al_minhad",
    Name = "Al Minhad",
    AirbaseName = AIRBASE.PersianGulf.Al_Minhad_AFB,

    RequireCorrectATIS = true,
    ActiveRunway = "27",
    ArrivalRunway = "27",
    WindText = "two six zero at eight",
    MaintenanceRamp = "maintenance ramp",

    EOR = {
        Enabled = false,
        RequireZone = false,
        UnavailableFallbackToRunway = true,
        Runways = {
            ["27"] = {
                Name = "EOR Runway 27",
                --Zone = "AL_MINHAD_EOR_27",
                TaxiRoutes = {
                    ["West Ramp"] = { "Hotel", "Golf" },
                    ["East Ramp"] = { "Hotel", "Golf" },
                },
            },
            ["09"] = {
                Name = "EOR Runway 09",
                --Zone = "AL_MINHAD_EOR_09",
                TaxiRoutes = {
                    ["West Ramp"] = { "Hotel", "Alpha" },
                    ["East Ramp"] = { "Hotel", "Alpha" },
                },
            },
        },
    },

    -- false: Ground -> Tower -> Center -> Tower -> Ground
    -- true:  Ground -> Tower -> AWACS  -> Tower -> Ground
    UseAWACSForDeparture = false,

    TTSEndpoint = "http://127.0.0.1:8765/tts",
    Coalition = coalition.side.BLUE,

    Ground = {
        Callsign = "Al Minhad Ground",
        Frequency = 250.100,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },

    Tower = {
        Callsign = "Al Minhad Tower",
        Frequency = 310.500,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 205,
        Pitch = 0,
        Volume = 1.0,
    },

    Center = {
        Callsign = "Emirates Center",
        Frequency = 251.000,
        Modulation = radio.modulation.AM,
        Voice = "Daniel",
        Speed = 190,
        Pitch = -1,
        Volume = 1.0,
    },

    AWACS = {
        Callsign = "Overlord",
        Frequency = 251.500,
        Modulation = radio.modulation.AM,
        Voice = "Daniel",
        Speed = 180,
        Pitch = -2,
        Volume = 1.0,
    },

    ATIS = {
        Callsign = "Al Minhad Information",
        Frequency = 131.700,
        Modulation = radio.modulation.AM,
        CurrentInformation = "Echo",
        Voice = "Nathan",
        Speed = 175,
        Pitch = 0,
        Volume = 1.0,
    },

    DetectionZone = "AL_MINHAD_AIRPORT_ZONE",

    ParkingAreas = {
        {
            Name = "West Ramp",
            Zone = "AL_MINHAD_WEST_RAMP",
            TaxiRoutes = {
                ["27"] = { "Hotel", "Golf" },
                ["09"] = { "Hotel", "Alpha" },
            },
        },
        {
            Name = "East Ramp",
            Zone = "AL_MINHAD_EAST_RAMP",
            TaxiRoutes = {
                ["27"] = { "Hotel", "Golf" },
                ["09"] = { "Hotel", "Alpha" },
            },
        },
    },
})

NASG_ATC:Log("Persian Gulf ATC config loaded")