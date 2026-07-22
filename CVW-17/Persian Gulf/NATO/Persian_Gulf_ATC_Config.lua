NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Persian Gulf ATC comms / mission layer.
--
-- Thin, volatile breakout: selects which airports (from the airport
-- database in Persian_Gulf_ATC_Airports.lua) are active this mission and
-- sets their radio frequencies, voices, callsigns, ATIS letter, wind, and
-- active runway. Structural data (parking, taxi graph, EOR) lives in the
-- database file and is merged in automatically by ActivateAirport.
---------------------------------------------------------------------------

NASG_ATC:ActivateAirport("al_minhad", {
    RequireCorrectATIS = true,
    ActiveRunway = "27",
    ArrivalRunway = "27",
    WindText = "two six zero at eight",

    TTSEndpoint = "http://127.0.0.1:8765/tts",

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
})

-- Drive Al Minhad's active runway and information letter from the live MOOSE
-- ATIS object (created in NATO/ATIS.lua, which loads before this file). The
-- static ActiveRunway/ArrivalRunway and ATIS.CurrentInformation above remain
-- as fallbacks if the ATIS is unavailable.
if atisAlMinhad then
    NASG_ATC:AttachMooseATIS("al_minhad", atisAlMinhad)
end

NASG_ATC:Log("Persian Gulf ATC config loaded")
