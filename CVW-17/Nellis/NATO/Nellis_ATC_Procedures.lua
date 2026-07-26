NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Nevada (NTTR) named navigation procedures (SID/STAR-style).
--
-- An ordered list of points (referencing Nellis_ATC_TrackedPoints.lua
-- entries by name, or inline point tables) a pilot can request as a unit
-- from Clearance Delivery, e.g. "request Vegas departure". Loaded after
-- Nellis_ATC_TrackedPoints.lua so these Points references resolve.
--
-- Type is "departure" or "recovery". AirportId scopes a procedure to one
-- airport's Clearance/Center; omit it (see "Range Recovery" below) for a
-- procedure that applies to every airport on the map.
--
-- A point in Points may be a plain string (tracked-point lookup, no
-- restriction), an inline point table, or { Point = "<id>", AltitudeFt =
-- <feet>, AltitudeConstraint = "at"|"above"|"below" } to pin a crossing
-- restriction to a shared tracked point without editing the point itself.
-- A RegisterProcedure def can also carry its own top-level AltitudeFt/
-- AltitudeConstraint for a whole-route restriction Clearance Delivery reads
-- back at clearance time (e.g. "climb and maintain at or below 10,000").
---------------------------------------------------------------------------

-- Departure procedure scoped to Nellis only. Climbs at or below 10,000
-- until past RENO GATE.
NASG_ATC:RegisterProcedure({
    Id = "vegas_departure",
    Name = "Vegas",
    Type = "departure",
    AirportId = "nellis",
    AltitudeFt = 10000,
    AltitudeConstraint = "below",
    Points = {
        { Point = "reno_gate", AltitudeFt = 5000, AltitudeConstraint = "above" },
        "bullseye",
    },
})

-- Recovery procedure scoped to Nellis, with an alias. Crosses DREAMLAND
-- ENTRY at or below 10,000.
NASG_ATC:RegisterProcedure({
    Id = "strike_recovery",
    Name = "Strike",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = { "Strike One" },
    Points = {
        { Point = "dreamland_entry", AltitudeFt = 10000, AltitudeConstraint = "below" },
        "bullseye",
    },
})

-- Departure procedure scoped to Creech. Crosses SHELL 71 at exactly 8,000.
NASG_ATC:RegisterProcedure({
    Id = "reaper_departure",
    Name = "Reaper",
    Type = "departure",
    AirportId = "creech",
    Points = {
        { Point = "shell71", AltitudeFt = 8000, AltitudeConstraint = "at" },
    },
})

-- Nellis departure with only one real fix (FYTTR). Everything before it is
-- a runway-dependent vector/climb maneuver (see the FYTTR THREE plate's
-- route description) with no trackable coordinate, so it isn't represented
-- here at all -- only the FYTTR crossing restriction is checkable, via
-- "course check" (see NASG_ATC_Center.lua's HandleRouteCourseCheck).
NASG_ATC:RegisterProcedure({
    Id = "fyttr_three_departure",
    Name = "FYTTR Three",
    Type = "departure",
    AirportId = "nellis",
    Aliases = { "FYTTR3", "FYTTR", "Fighter" },
    Points = {
        { Point = "fyttr", AltitudeFt = 14000, AltitudeConstraint = "above" },
    },
})

-- Nellis departure with two runway-dependent route variants (see the
-- DREAM FOUR DEPARTURE plate's route description), selected by
-- RunwayPoints/GetRunwayGroupKey (Common/ATC/lua/NASG_ATC_Procedures.lua):
--   * RWY 3L/3R: vectors to intercept BLD VORTAC R-346 outbound, then
--     direct JUNNO, crossing at or above 17,000. The LSV R-027/R-030
--     vector to ATALF/HEREM that precedes the BLD intercept has no
--     trackable coordinate of its own (same as FYTTR THREE's pre-fix
--     maneuvering above), so only the BLD radial onward is modeled.
--   * RWY 21L/21R: turn to intercept LAS VORTAC (McCarran) R-350 outbound,
--     then direct MINTT, crossing above 17,000.
-- Both variants continue via assigned route to DREAM. Radial legs are
-- checked against the station's live position, not a fixed coordinate --
-- see NASG_ATC_Tacan.lua -- rather than a Points entry.
NASG_ATC:RegisterProcedure({
    Id = "dream_four_departure",
    Name = "Dream Four",
    Type = "departure",
    AirportId = "nellis",
    Aliases = { "Dream4", "Dream" },
    RunwayPoints = {
        ["3"] = {
            { Radial = 346, Airbase = AIRBASE.Nevada.Boulder_City, Name = "BLD R-346" },
            { Point = "junno", AltitudeFt = 17000, AltitudeConstraint = "above" },
            "dream",
        },
        ["21"] = {
            { Radial = 350, Airbase = AIRBASE.Nevada.McCarran_International, Name = "LAS R-350" },
            { Point = "mintt", AltitudeFt = 17000, AltitudeConstraint = "above" },
            "dream",
        },
    },
})

-- Nellis recovery, HI-TACAN Z RWY 21L: TACAN LSV Chan 12, final approach
-- course 209 inbound. Only the IAF (ARCOE, R-209/30 DME, cross at 15,000)
-- is modeled as a checkable leg -- the intermediate DME-arc transition
-- (RONKY/OLNIE/WISTO/KUTME/JENAR/JOGEV/WILIE) blends a curving arc with
-- radial changes this framework's straight-radial leg check can't
-- represent faithfully, same precedent as skipping FYTTR THREE's pre-fix
-- vectoring. The published missed approach is fully modeled: climb to
-- 15,000, intercept LSV R-209 to 2.5 DME (ROCKX), then (climbing right
-- turn heading 020 -- not independently checkable) join LSV R-357 to
-- ARCOE and hold, continuing the climb-in-hold to 15,000. Going missed
-- (see NASG_ATC_Tower.lua's HandleGoingAround) swaps the pilot's active
-- route legs over to this MissedApproach automatically.
NASG_ATC:RegisterProcedure({
    Id = "nellis_tacan_z_21l",
    Name = "Nellis TACAN Zulu",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = { "TACAN Z", "Hi TACAN Z", "TACAN Zulu" },
    Points = {
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 30, Name = "ARCOE", AltitudeFt = 15000, AltitudeConstraint = "at" },
    },
    MissedApproach = {
        Points = {
            { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 2.5, Name = "ROCKX" },
            { Radial = 357, Airbase = AIRBASE.Nevada.Nellis, Name = "LSV R-357" },
            {
                Radial = 357,
                Airbase = AIRBASE.Nevada.Nellis,
                DME = 30,
                Name = "ARCOE",
                AltitudeFt = 15000,
                AltitudeConstraint = "above",
            },
        },
    },
})

-- Nellis recovery, HI-TACAN RWY 3R: TACAN LSV Chan 12, final approach
-- course 028 inbound on LSV R-208, a clean straight-in course with no arc
-- or radial transition -- the full published fix sequence is modeled as
-- DME legs on R-208. LUCIL is also a course-reversal hold (IAF), but that
-- maneuver itself isn't independently checkable, same precedent as
-- FYTTR THREE's/DREAM FOUR's unmodeled pre-fix vectoring. The published
-- missed approach (climb to 9000 on LSV R-030 to VETT and hold) is fully
-- modeled.
NASG_ATC:RegisterProcedure({
    Id = "nellis_tacan_3r",
    Name = "Nellis TACAN Three Right",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = { "TACAN 3R", "Hi TACAN 3R", "TACAN Three Right" },
    Points = {
        { Radial = 208, Airbase = AIRBASE.Nevada.Nellis, DME = 21, Name = "LUCIL", AltitudeFt = 10000, AltitudeConstraint = "above" },
        { Radial = 208, Airbase = AIRBASE.Nevada.Nellis, DME = 15.6, Name = "HUSTS", AltitudeFt = 6300, AltitudeConstraint = "above" },
        { Radial = 208, Airbase = AIRBASE.Nevada.Nellis, DME = 8, Name = "ENGLA", AltitudeFt = 3900, AltitudeConstraint = "above" },
        { Radial = 208, Airbase = AIRBASE.Nevada.Nellis, DME = 5.6, Name = "WEBSO", AltitudeFt = 3200, AltitudeConstraint = "above" },
        { Radial = 208, Airbase = AIRBASE.Nevada.Nellis, DME = 2.9, Name = "CEDRU" },
    },
    MissedApproach = {
        Points = {
            { Radial = 30, Airbase = AIRBASE.Nevada.Nellis, DME = 31, Name = "VETT", AltitudeFt = 9000, AltitudeConstraint = "above" },
        },
    },
})

-- Nellis recovery, TACAN X RWY 21L: shares its final approach course (LSV
-- R-209 inbound) and published missed approach with nellis_tacan_z_21l
-- above. Its own IAF transition (KUTME/HULPU, flown on LSV R-029 before
-- joining R-209) is a different-radial join this framework's straight-leg
-- check can't verify, so -- same precedent as the Z approach's arc -- only
-- the clean R-209 stretch onward (JENAR/JOGEV/WILIE/KITCH) is modeled.
NASG_ATC:RegisterProcedure({
    Id = "nellis_tacan_x_21l",
    Name = "Nellis TACAN Xray",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = { "TACAN X", "TACAN X 21L", "TACAN Xray" },
    Points = {
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 7, Name = "JENAR", AltitudeFt = 4400, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 3.8, Name = "JOGEV", AltitudeFt = 3200, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 2.3, Name = "WILIE", AltitudeFt = 2540, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 0.7, Name = "KITCH" },
    },
    MissedApproach = {
        Points = {
            { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 2.5, Name = "ROCKX" },
            { Radial = 357, Airbase = AIRBASE.Nevada.Nellis, Name = "LSV R-357" },
            { Radial = 357, Airbase = AIRBASE.Nevada.Nellis, DME = 30, Name = "ARCOE", AltitudeFt = 15000, AltitudeConstraint = "above" },
        },
    },
})

-- Nellis recovery, HI-TACAN Y RWY 21L: same final approach course, final
-- fix sequence, and published missed approach as TACAN X above (cross-
-- checked -- both plates publish identical DME/altitude values for
-- JENAR/JOGEV/WILIE/KITCH). Its own IAF transition (DUDBE, via LSV R-283
-- onto a 13 DME arc through SECRT/HOKUM) is a curving arc this framework
-- can't represent, same precedent as skipping the Z approach's arc, so
-- only the clean R-209 stretch onward is modeled.
NASG_ATC:RegisterProcedure({
    Id = "nellis_tacan_y_21l",
    Name = "Nellis TACAN Yankee",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = { "TACAN Y", "Hi TACAN Y", "TACAN Yankee" },
    Points = {
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 7, Name = "JENAR", AltitudeFt = 4400, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 3.8, Name = "JOGEV", AltitudeFt = 3200, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 2.3, Name = "WILIE", AltitudeFt = 2540, AltitudeConstraint = "above" },
        { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 0.7, Name = "KITCH" },
    },
    MissedApproach = {
        Points = {
            { Radial = 209, Airbase = AIRBASE.Nevada.Nellis, DME = 2.5, Name = "ROCKX" },
            { Radial = 357, Airbase = AIRBASE.Nevada.Nellis, Name = "LSV R-357" },
            { Radial = 357, Airbase = AIRBASE.Nevada.Nellis, DME = 30, Name = "ARCOE", AltitudeFt = 15000, AltitudeConstraint = "above" },
        },
    },
})


-- borrowed from dream_four_departure's RunwayPoints["21"] variant) as a
-- placeholder. The plate's actual final leg is "cross LV BLVD at or above
-- 4,000, then 3,500 for initial, remain within 4 DME of LSV on the turn to
-- initial" -- there's no "lv_blvd" tracked point yet and no verified
-- coordinate or LSV radial/DME for it, so it hasn't been added. Once that
-- position is known (coordinate, or an LSV radial/DME pair like the other
-- legs here), add it to Nellis_ATC_TrackedPoints.lua and swap this leg to
-- { Point = "lv_blvd", AltitudeFt = 4000, AltitudeConstraint = "above" }.
NASG_ATC:RegisterProcedure({
    Id = "TIMBR",
    Name = "TIMBR",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = {"timber"},
    Points = {
        { Point = "timbr", AltitudeFt = 13000, AltitudeConstraint = "above" },
        { Point = "gass_pk", AltitudeFt = 9000, AltitudeConstraint = "above" },
        { Point = "simns", AltitudeFt = 5500, AltitudeConstraint = "at" },
        { Point = "craig", AltitudeFt = 5000, AltitudeConstraint = "at" },
        { Point = "lv blvd", AltitudeFt = 4000, AltitudeConstraint = "above" },
    }
})


NASG_ATC:RegisterProcedure({
    Id = "MINTT",
    Name = "MINTT",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = {"mint"},
    Points = {
        { Point = "mintt", AltitudeFt = 15000, AltitudeConstraint = "above" },
        { Point = "gass_pk", AltitudeFt = 9000, AltitudeConstraint = "above" },
        { Point = "simns", AltitudeFt = 5500, AltitudeConstraint = "at" },
        { Point = "craig", AltitudeFt = 5000, AltitudeConstraint = "at" },
        { Point = "lv blvd", AltitudeFt = 4000, AltitudeConstraint = "above" },
    }
})

NASG_ATC:RegisterProcedure({
    Id = "ARCOE",
    Name = "ARCOE",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = {"arco"},
    Points = {
        { Point = "arcoe", AltitudeFt = 15000, AltitudeConstraint = "above" },
        { Point = "apex", AltitudeFt = 4500, AltitudeConstraint = "above" },
        { Point = "phinn", AltitudeFt = 4000, AltitudeConstraint = "at" },
    }
})

NASG_ATC:RegisterProcedure({
    Id = "ACTON",
    Name = "ACTON",
    Type = "recovery",
    AirportId = "nellis",
    Aliases = {"acton"},
    Points = {
        { Point = "acton", AltitudeFt = 8000, AltitudeConstraint = 12000 },
        { Point = "apex", AltitudeFt = 4500, AltitudeConstraint = "above" },
        { Point = "phinn", AltitudeFt = 4000, AltitudeConstraint = "at" },

    }
})

NASG_ATC:Log("Nevada ATC procedures loaded")
