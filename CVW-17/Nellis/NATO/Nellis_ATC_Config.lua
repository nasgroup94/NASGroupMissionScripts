NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Nevada (NTTR) ATC comms / mission layer.
--
-- Activates the airports defined in Nellis_ATC_Airports.lua for this
-- mission and sets their radio frequencies, voices, callsigns, ATIS
-- letter, wind, and active runway. Structural data (parking, taxi graph,
-- EOR, Runways) lives in the database file and is merged in automatically
-- by ActivateAirport.
--
-- Unlike Al Minhad's single-airport Persian Gulf setup, this map activates
-- three airports, each independently tuned — every ActivateAirport call
-- below is self-contained and can be copy/pasted for a fourth field.
---------------------------------------------------------------------------

NASG_ATC:ActivateAirport("nellis", {
    RequireCorrectATIS = true,
    ActiveRunway = "21L",
    ArrivalRunway = "21L",
    WindText = "two one zero at six",

    TTSEndpoint = "http://127.0.0.1:8765/tts",

    Ground = {
        Callsign = "Nellis Ground",
        Frequency = 121.8,
        Modulation = radio.modulation.AM,
        Voice = "Evan",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },

    Tower = {
        Callsign = "Nellis Tower",
        Frequency = 327.1,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 205,
        Pitch = 0,
        Volume = 1.0,
    },

    Center = {
        Callsign = "Nellis Approach",
        Frequency = 239.400,
        Modulation = radio.modulation.AM,
        Voice = "Daniel",
        Speed = 190,
        Pitch = -1,
        Volume = 1.0,
        RecoveryDescentAltitudeFt = 8000,
    },

    AWACS = {
        Callsign = "Cowboy",
        Frequency = 262.000,
        Modulation = radio.modulation.AM,
        Voice = "Tom",
        Speed = 180,
        Pitch = -2,
        Volume = 1.0,
    },

    Clearance = {
        Callsign = "Nellis Clearance",
        Frequency = 120.9,
        Modulation = radio.modulation.AM,
        Voice = "Zoe",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },

    ATIS = {
        Callsign = "Nellis Information",
        Frequency = 270.1,
        Modulation = radio.modulation.AM,
        CurrentInformation = "Alpha",
        Voice = "Nathan",
        Speed = 175,
        Pitch = 0,
        Volume = 1.0,
    },
})

NASG_ATC:ActivateAirport("creech", {
    RequireCorrectATIS = false,
    ActiveRunway = "08",
    ArrivalRunway = "08",
    WindText = "zero eight zero at four",

    TTSEndpoint = "http://127.0.0.1:8765/tts",

    Ground = {
        Callsign = "Creech Ground",
        Frequency = 259.300,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },

    Tower = {
        Callsign = "Creech Tower",
        Frequency = 306.200,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 205,
        Pitch = 0,
        Volume = 1.0,
    },

    Clearance = {
        Callsign = "Creech Clearance",
        Frequency = 121.100,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },
})

-- Groom Lake: only what its minimal airport definition can use. There is
-- no Ground here (no ParkingAreas/TaxiGraph on this Id), so no Ground
-- block is set — pilots handling that field get Tower/Clearance/Center
-- only, same as the airport definition supports.
NASG_ATC:ActivateAirport("groom_lake", {
    ActiveRunway = "14",
    ArrivalRunway = "14",

    TTSEndpoint = "http://127.0.0.1:8765/tts",

    Tower = {
        Callsign = "Dreamland Tower",
        Frequency = 291.500,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 205,
        Pitch = 0,
        Volume = 1.0,
    },

    Clearance = {
        Callsign = "Dreamland Clearance",
        Frequency = 128.300,
        Modulation = radio.modulation.AM,
        Voice = "Nathan",
        Speed = 200,
        Pitch = 0,
        Volume = 1.0,
    },
})

-- Drive Nellis's/Creech's active runway and information letter from the
-- live MOOSE ATIS objects (created in NATO/ATIS.lua, which must load before
-- this file). The static ActiveRunway/ArrivalRunway/ATIS.CurrentInformation
-- above remain as fallbacks if a given ATIS is unavailable.
if atisNellis then
    NASG_ATC:AttachMooseATIS("nellis", atisNellis)
end

if atisCreech then
    NASG_ATC:AttachMooseATIS("creech", atisCreech)
end

NASG_ATC:Log("Nevada ATC config loaded")
