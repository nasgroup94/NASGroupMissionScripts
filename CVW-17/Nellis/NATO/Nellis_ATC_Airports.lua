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

    -----------------------------------------------------------------------
    -- Real NTTR taxiway layout. Alpha bridges both strips at the south (03)
    -- end and is the only way onto 03L/03R; Echo bridges both strips at the
    -- north (21) end and is the only way onto 21L/21R. Bravo and Delta also
    -- bridge both strips (further out along their length) but are exit-only
    -- -- nothing hangs a hold-short/EOR off them, they just get a landing
    -- jet off the runway and onto Foxtrot/Golf. Foxtrot (west) and Golf
    -- (east) are the two north-south taxiways every bridge touches; Golf
    -- also spurs via Charlie to the LOLA (Live Ordnance Loading Area) pad.
    -- One EOR per runway end: South West (03L, on Foxtrot), South East
    -- (03R, on Alpha), North West (21R, on Echo), North East (21L, on Echo)
    -- -- see the TaxiGraph below for the actual node layout.
    -----------------------------------------------------------------------
    EOR = {
        Enabled = false,
        RequireZone = false,
        UnavailableFallbackToRunway = true,
        Runways = {
            ["03L"] = {
                Name = "South West EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Golf", "Alpha" },
                },
            },
            ["03R"] = {
                Name = "South East EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Golf", "Alpha" },
                },
            },
            ["21R"] = {
                Name = "North West EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Golf", "Echo" },
                },
            },
            ["21L"] = {
                Name = "North East EOR",
                TaxiRoutes = {
                    ["Nellis Ramp"] = { "Golf", "Echo" },
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
            -- Crossings are NOT expressible here — that's the whole reason
            -- the dynamic TaxiGraph below exists. Assumes the ramp accesses
            -- the field via Golf (see the nellis_ramp edge below) — adjust
            -- both together if the real ramp access point differs.
            TaxiRoutes = {
                ["03L"] = { "Golf", "Alpha" },
                ["03R"] = { "Golf", "Alpha" },
                ["21R"] = { "Golf", "Echo" },
                ["21L"] = { "Golf", "Echo" },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Dynamic taxi routing graph.
    --
    -- Layout, west to east across each runway pair:
    --   Foxtrot (F) -- Alpha/Bravo/Delta/Echo bridges -- Golf (G) -- Charlie -> LOLA
    --
    -- Alpha and Echo each cross BOTH strips and carry a hold-short point
    -- (RunwayNodes) plus the EORs that sit on/near them. Bravo and Delta
    -- also cross both strips (assumed order south to north: Alpha, Bravo,
    -- Delta, Echo) but are exit-only, so their crossing nodes are typed
    -- "exit" rather than "runway" and aren't in RunwayNodes.
    --
    -- ASSUMPTIONS (not in the original brief — trivial to move if wrong):
    --   * Charlie branches off Golf at the Delta junction (d_east).
    --   * The main ramp reaches the field via Golf at the Bravo junction
    --     (b_east).
    --
    -- This graph is topology-only (no Zone/Vec2 on the junction/EOR/exit
    -- nodes), so edge costs default to 1 and DEPARTURE routing (parking/EOR
    -- -> runway, including which runway(s) get crossed) is fully accurate.
    -- ARRIVAL taxi-back (RouteFromClientToParking, which snaps the jet's
    -- live position to the nearest node) can only snap to nodes with a
    -- resolvable coordinate -- currently just the 4 runway nodes (via
    -- Runway=) and nellis_ramp (via Zone=). Add Zone/Vec2 to the exit/
    -- junction nodes below if precise taxi-back-from-exit callouts matter
    -- later; it isn't needed for the departure/EOR scenario this was built
    -- for.
    -----------------------------------------------------------------------
    TaxiGraph = {
        RunwayNodes = {
            ["03L"] = "rwy03L",
            ["03R"] = "rwy03R",
            ["21L"] = "rwy21L",
            ["21R"] = "rwy21R",
        },

        EORNodes = {
            ["03L"] = "eor_sw",
            ["03R"] = "eor_se",
            ["21R"] = "eor_nw",
            ["21L"] = "eor_ne",
        },

        Nodes = {
            { Name = "nellis_ramp", Type = "parking", Zone = "NELLIS_MAIN_RAMP" },

            { Name = "eor_sw", Type = "junction" },
            { Name = "eor_se", Type = "junction" },
            { Name = "eor_nw", Type = "junction" },
            { Name = "eor_ne", Type = "junction" },

            { Name = "rwy03L", Type = "runway", Runway = "03L" },
            { Name = "rwy03R", Type = "runway", Runway = "03R" },
            { Name = "rwy21L", Type = "runway", Runway = "21L" },
            { Name = "rwy21R", Type = "runway", Runway = "21R" },

            { Name = "a_west", Type = "junction" },
            { Name = "a_east", Type = "junction" },
            { Name = "b_west", Type = "junction" },
            { Name = "b_east", Type = "junction" },
            { Name = "d_west", Type = "junction" },
            { Name = "d_east", Type = "junction" },
            { Name = "e_west", Type = "junction" },
            { Name = "e_east", Type = "junction" },

            { Name = "b_x03L", Type = "exit" },
            { Name = "b_x03R", Type = "exit" },
            { Name = "d_x03L", Type = "exit" },
            { Name = "d_x03R", Type = "exit" },

            { Name = "lola", Type = "junction" },
        },

        Edges = {
            -- Foxtrot: west perimeter, south to north, touching every
            -- bridging taxiway's west end. South West EOR sits at its
            -- southern end, before the Alpha junction.
            { From = "eor_sw", To = "a_west", Taxiway = "Foxtrot" },
            { From = "a_west", To = "b_west", Taxiway = "Foxtrot" },
            { From = "b_west", To = "d_west", Taxiway = "Foxtrot" },
            { From = "d_west", To = "e_west", Taxiway = "Foxtrot" },

            -- Golf: east perimeter, south to north, touching every
            -- bridging taxiway's east end, plus the Charlie spur to LOLA
            -- and the main ramp's access point.
            { From = "a_east", To = "b_east", Taxiway = "Golf" },
            { From = "b_east", To = "d_east", Taxiway = "Golf" },
            { From = "d_east", To = "e_east", Taxiway = "Golf" },
            { From = "d_east", To = "lola",   Taxiway = "Charlie" },
            { From = "nellis_ramp", To = "b_east", Taxiway = "Golf" },

            -- Alpha: bridges both strips at the south end -- the only way
            -- onto 03L/03R. South West EOR crosses 03L to reach 03R (and
            -- vice versa); South East EOR sits past 03R with no crossing
            -- needed for a 03R departure.
            { From = "a_west", To = "rwy03L", Taxiway = "Alpha" },
            { From = "rwy03L", To = "rwy03R", Taxiway = "Alpha", CrossesRunway = "03L" },
            { From = "rwy03R", To = "eor_se", Taxiway = "Alpha" },
            { From = "eor_se", To = "a_east", Taxiway = "Alpha", CrossesRunway = "03R" },

            -- Echo: bridges both strips at the north end -- the only way
            -- onto 21L/21R. Mirrors Alpha: North West EOR crosses 21R to
            -- reach 21L (and vice versa); North East EOR sits past 21L with
            -- no crossing needed for a 21L departure.
            { From = "e_west",  To = "eor_nw", Taxiway = "Echo" },
            { From = "eor_nw",  To = "rwy21R", Taxiway = "Echo" },
            { From = "rwy21R",  To = "rwy21L", Taxiway = "Echo", CrossesRunway = "21R" },
            { From = "rwy21L",  To = "eor_ne", Taxiway = "Echo" },
            { From = "eor_ne",  To = "e_east", Taxiway = "Echo", CrossesRunway = "21L" },

            -- Bravo: mid-field bridge, exit-only (no EOR/hold-short here).
            { From = "b_west", To = "b_x03L", Taxiway = "Bravo" },
            { From = "b_x03L", To = "b_x03R", Taxiway = "Bravo", CrossesRunway = "03L" },
            { From = "b_x03R", To = "b_east", Taxiway = "Bravo", CrossesRunway = "03R" },

            -- Delta: mid-field bridge, exit-only, further north than Bravo.
            { From = "d_west", To = "d_x03L", Taxiway = "Delta" },
            { From = "d_x03L", To = "d_x03R", Taxiway = "Delta", CrossesRunway = "03L" },
            { From = "d_x03R", To = "d_east", Taxiway = "Delta", CrossesRunway = "03R" },
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
