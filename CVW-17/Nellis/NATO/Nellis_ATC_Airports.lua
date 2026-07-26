NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Nevada (NTTR) example airport database.
--
-- Same config split as Persian Gulf: structural, map-specific data here
-- (parking, taxi graph, EOR, runway defaults); per-mission comms
-- (frequencies, voices, ATIS letter, wind, active runway) live in
-- Nellis_ATC_Config.lua, which calls NASG_ATC:ActivateAirport(id, comms).
--
-- This file demonstrates the pieces the Persian Gulf example doesn't need:
--   * Multiple airports on one map (Nellis, Creech, Groom Lake).
--   * A field with two physically distinct runways (Nellis), including a
--     taxi route that crosses one of them (see NASG_ATC_TaxiGraph.lua and
--     NASG_ATC_Ground.lua's runway-crossing logic).
--   * A minimal airport definition with no ground infrastructure at all
--     (Groom Lake) — DefineAirport only requires an Id; everything else,
--     including ParkingAreas/TaxiGraph/EOR/Runways, is optional.
--
-- DCS map / airbase names come from MOOSE's AIRBASE.Nevada enum
-- (Moose.lua): AIRBASE.Nevada.Nellis, AIRBASE.Nevada.Creech,
-- AIRBASE.Nevada.Groom_Lake, etc.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Nellis AFB — two parallel runway pairs (03L/21R and 03R/21L), so this is
-- the example to look at for multi-runway + runway-crossing configuration.
---------------------------------------------------------------------------
NASG_ATC:DefineAirport({
    Id = "nellis",
    Name = "Nellis",
    AirbaseName = AIRBASE.Nevada.Nellis,

    ActiveRunway = "21L",
    ArrivalRunway = "21L",
    MaintenanceRamp = "maintenance ramp",

    DefaultParkingAreaName = "Nellis Ramp",

    -- Ground -> Tower -> Center -> Tower -> Ground (false) vs AWACS (true).
    UseAWACSForDeparture = false,

    DepartureClimbAltitudeFt = 6000,

    Coalition = coalition.side.BLUE,

    -----------------------------------------------------------------------
    -- Two runway PAIRS, not just two ends of one strip: 03R/21L share a
    -- RunwayZone (one physical runway), and 03L/21R share a different
    -- RunwayZone (the second, physically distinct parallel runway). A jet
    -- taxiing from the west ramp to 21L has to cross 03L/21R first — that's
    -- what the TaxiGraph edge below (`CrossesRunway = "21R"`) models.
    --
    -- RunwayZone and CorridorZone are ME trigger-zone names, resolved with
    -- ZONE:FindByName:
    --   * RunwayZone covers just the physical pavement of one runway PAIR
    --     (both ends share it). A unit inside it and not airborne is a
    --     decisive "runway occupied" signal, used by both Ground's
    --     crossing check (NASG_ATC_Ground.lua:HandleRunwayCrossingRequest)
    --     and Tower's departure-clearance check
    --     (NASG_ATC_Tower.lua:AssessRunwayForDeparture).
    --   * CorridorZone covers the extended approach/departure corridor for
    --     one SIDE of the field. 21L/21R fly (nearly) the same corridor
    --     heading, as do 03L/03R, so each pair of ends shares one zone
    --     rather than needing four. A unit inside it, airborne, inbound and
    --     below the approach ceiling is a decisive "traffic on final"
    --     signal; airborne, outbound, and just off the ground is a decisive
    --     "just departed" signal (see NASG_ATC_Core.lua's
    --     AssessRunwayTraffic).
    -- Leave either nil and Ground/Tower fall back to the NM-radius/bearing
    -- traffic heuristic for that runway instead.
    -----------------------------------------------------------------------
    Runways = {
        ["21L"] = {
            Reciprocal = "03R",
            RunwayZone   = "03R_21L_RWY",
            CorridorZone = "21ARRDEP",
        },
        ["03R"] = {
            Reciprocal = "21L",
            RunwayZone   = "03R_21L_RWY",
            CorridorZone = "03ARRDEP",
        },
        ["21R"] = {
            Reciprocal = "03L",
            RunwayZone   = "03L_21R_RWY",
            CorridorZone = "21ARRDEP",
        },
        ["03L"] = {
            Reciprocal = "21R",
            RunwayZone   = "03L_21R_RWY",
            CorridorZone = "03ARRDEP",
        },
    },

    EOR = {
        Enabled = false,
        RequireZone = false,
        UnavailableFallbackToRunway = true,
        Runways = {
            ["21L"] = {
                Name = "North East EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Bravo" },
                },
            },
            ["03R"] = {
                Name = "South East EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Bravo" },
                },
            },
        },
    },

    ParkingAreas = {
        {
            Name = "Nellis Ramp",
            Node = "nellis_ramp",
            -- Zone-optional, same as Persian Gulf: replace with SpotIDs = {...}
            -- or Center + RadiusNM to go fully zone-free.
            Zone = "NELLIS_MAIN_RAMP",
            -- Static fallback routes (used if TaxiGraph is ever unavailable).
            -- Crossing 03L/21R is NOT expressible here — that's the whole
            -- reason the dynamic TaxiGraph below exists.
            TaxiRoutes = {
                ["21L"] = { "Bravo" },
                ["03R"] = { "Bravo" },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Dynamic taxi routing graph. From the ramp, Bravo reaches the near
    -- runway (03R/21L) directly. A second taxi lane, Charlie, continues
    -- past it to the west-side runway (03L/21R) and crosses 03L/21R to get
    -- there — that crossing is declared with CrossesRunway on the edge that
    -- spans the strip, not on the parking/junction nodes themselves.
    -----------------------------------------------------------------------
    TaxiGraph = {
        RunwayNodes = {
            ["21L"] = "rwy21L",
            ["03R"] = "rwy03R",
            ["21R"] = "rwy21R",
            ["03L"] = "rwy03L",
        },

        Nodes = {
            { Name = "nellis_ramp", Type = "parking", Zone = "NELLIS_MAIN_RAMP" },
            { Name = "j_bravo",     Type = "junction" },
            { Name = "rwy21L",      Type = "runway",  Runway = "21L" },
            { Name = "rwy03R",      Type = "runway",  Runway = "03R" },
            { Name = "j_charlie",   Type = "junction" },
            { Name = "rwy21R",      Type = "runway",  Runway = "21R" },
            { Name = "rwy03L",      Type = "runway",  Runway = "03L" },
        },

        Edges = {
            { From = "nellis_ramp", To = "j_bravo",   Taxiway = "Bravo" },
            { From = "j_bravo",     To = "rwy21L",     Taxiway = "Bravo" },
            { From = "j_bravo",     To = "rwy03R",     Taxiway = "Bravo" },
            -- Charlie continues past 03R/21L to the far runway, crossing it.
            { From = "j_bravo",     To = "j_charlie",  Taxiway = "Charlie", CrossesRunway = "21L" },
            { From = "j_charlie",   To = "rwy21R",      Taxiway = "Charlie" },
            { From = "j_charlie",   To = "rwy03L",      Taxiway = "Charlie" },
        },
    },
})

---------------------------------------------------------------------------
-- Creech AFB — a single strip, deliberately kept simple (no crossings) to
-- contrast with Nellis above: not every airport in a multi-airport map
-- needs the runway-crossing machinery.
---------------------------------------------------------------------------
NASG_ATC:DefineAirport({
    Id = "creech",
    Name = "Creech",
    AirbaseName = AIRBASE.Nevada.Creech,

    ActiveRunway = "08",
    ArrivalRunway = "08",

    DefaultParkingAreaName = "Creech Ramp",

    UseAWACSForDeparture = false,
    DepartureClimbAltitudeFt = 5000,

    Coalition = coalition.side.BLUE,

    Runways = {
        ["08"] = { Reciprocal = "26" },
        ["26"] = { Reciprocal = "08" },
    },

    EOR = {
        Enabled = false,
        RequireZone = false,
        UnavailableFallbackToRunway = true,
        Runways = {
            ["08"] = {
                Name = "EOR Runway 08",
                TaxiRoutes = { ["Creech Ramp"] = { "Alpha" } },
            },
            ["26"] = {
                Name = "EOR Runway 26",
                TaxiRoutes = { ["Creech Ramp"] = { "Alpha" } },
            },
        },
    },

    ParkingAreas = {
        {
            Name = "Creech Ramp",
            Node = "creech_ramp",
            Zone = "CREECH_MAIN_RAMP",
            TaxiRoutes = {
                ["08"] = { "Alpha" },
                ["26"] = { "Alpha" },
            },
        },
    },

    TaxiGraph = {
        RunwayNodes = {
            ["08"] = "rwy08",
            ["26"] = "rwy26",
        },

        Nodes = {
            { Name = "creech_ramp", Type = "parking", Zone = "CREECH_MAIN_RAMP" },
            { Name = "j_alpha",     Type = "junction" },
            { Name = "rwy08",       Type = "runway", Runway = "08" },
            { Name = "rwy26",       Type = "runway", Runway = "26" },
        },

        Edges = {
            { From = "creech_ramp", To = "j_alpha", Taxiway = "Alpha" },
            { From = "j_alpha",     To = "rwy08",    Taxiway = "Alpha" },
            { From = "j_alpha",     To = "rwy26",    Taxiway = "Alpha" },
        },
    },
})

---------------------------------------------------------------------------
-- Groom Lake — the minimal-viable airport definition. DefineAirport only
-- requires an Id, so a third (or fourth, fifth...) airbase can be added to
-- a map with nothing but this. Ground won't offer taxi clearances here
-- (no ParkingAreas/TaxiGraph), but Clearance/Tower/Center/AWACS all work
-- normally off ActiveRunway/ArrivalRunway. Fill in ParkingAreas/TaxiGraph/
-- EOR/Runways later exactly like Nellis/Creech above whenever this field
-- needs full ground handling.
---------------------------------------------------------------------------
NASG_ATC:DefineAirport({
    Id = "groom_lake",
    Name = "Groom Lake",
    AirbaseName = AIRBASE.Nevada.Groom_Lake,

    ActiveRunway = "14",
    ArrivalRunway = "14",

    Coalition = coalition.side.BLUE,
})

NASG_ATC:Log("Nevada ATC airport database loaded")
