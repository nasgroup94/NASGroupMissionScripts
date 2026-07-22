NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Persian Gulf airport database.
--
-- Structural, map-specific airport data: parking areas, taxi graph, EOR,
-- and runway/comms DEFAULTS. This is the reusable "database" half of the
-- config split — it rarely changes between missions.
--
-- The per-mission comms layer (frequencies, voices, ATIS letter, wind,
-- active runway) lives in Persian_Gulf_ATC_Config.lua, which calls
-- NASG_ATC:ActivateAirport(id, comms) to merge and register.
--
-- Portability notes:
--   * No mission-editor airport zone is required — airport-area detection
--     is derived from the MOOSE airbase (AirbaseName) automatically.
--   * Parking areas may be defined by an ME Zone (override), by AIRBASE
--     terminal SpotIDs, or by a Center + RadiusNM. All are zone-optional
--     except Zone itself.
---------------------------------------------------------------------------

NASG_ATC:DefineAirport({
    Id = "al_minhad",
    Name = "Al Minhad",
    AirbaseName = AIRBASE.PersianGulf.Al_Minhad_AFB,

    -- Structural defaults (comms layer may override).
    ActiveRunway = "27",
    ArrivalRunway = "27",
    MaintenanceRamp = "maintenance ramp",

    -- Fallback ramp for taxi routing when a jet's parking area cannot be
    -- resolved from a coordinate source (e.g. the ME parking zones below are
    -- absent). Both ramps share identical taxi routes, so defaulting here
    -- always yields a correct clearance.
    DefaultParkingAreaName = "West Ramp",

    -- Ground -> Tower -> Center -> Tower -> Ground (false) vs AWACS (true).
    UseAWACSForDeparture = false,

    Coalition = coalition.side.BLUE,

    EOR = {
        Enabled = false,
        RequireZone = false,
        UnavailableFallbackToRunway = true,
        Runways = {
            ["27"] = {
                Name = "EOR Runway 27",
                TaxiRoutes = {
                    ["West Ramp"] = { "Hotel", "Golf" },
                    ["East Ramp"] = { "Hotel", "Golf" },
                },
            },
            ["09"] = {
                Name = "EOR Runway 09",
                TaxiRoutes = {
                    ["West Ramp"] = { "Hotel", "Alpha" },
                    ["East Ramp"] = { "Hotel", "Alpha" },
                },
            },
        },
    },

    ParkingAreas = {
        {
            Name = "West Ramp",
            Node = "west_ramp",
            -- Zone-optional: keep the existing ME zone for now. To go fully
            -- zone-free, replace with SpotIDs = { ... } or Center + RadiusNM.
            Zone = "AL_MINHAD_WEST_RAMP",
            TaxiRoutes = {
                ["27"] = { "Hotel", "Golf" },
                ["09"] = { "Hotel", "Alpha" },
            },
        },
        {
            Name = "East Ramp",
            Node = "east_ramp",
            Zone = "AL_MINHAD_EAST_RAMP",
            TaxiRoutes = {
                ["27"] = { "Hotel", "Golf" },
                ["09"] = { "Hotel", "Alpha" },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Dynamic taxi routing graph (see NASG_ATC_TaxiGraph.lua for schema).
    -- Reproduces the static routes; junction j_hotel has no coordinate yet
    -- so its edges use unit cost (taxiway NAMES are still correct).
    -----------------------------------------------------------------------
    TaxiGraph = {
        RunwayNodes = {
            ["27"] = "rwy27",
            ["09"] = "rwy09",
        },

        Nodes = {
            { Name = "west_ramp", Type = "parking", Zone = "AL_MINHAD_WEST_RAMP" },
            { Name = "east_ramp", Type = "parking", Zone = "AL_MINHAD_EAST_RAMP" },
            { Name = "j_hotel",   Type = "junction" },
            { Name = "rwy27",     Type = "runway", Runway = "27" },
            { Name = "rwy09",     Type = "runway", Runway = "09" },
        },

        Edges = {
            { From = "west_ramp", To = "j_hotel", Taxiway = "Hotel" },
            { From = "east_ramp", To = "j_hotel", Taxiway = "Hotel" },
            { From = "j_hotel",   To = "rwy27",   Taxiway = "Golf"  },
            { From = "j_hotel",   To = "rwy09",   Taxiway = "Alpha" },
        },
    },
})

NASG_ATC:Log("Persian Gulf ATC airport database loaded")
