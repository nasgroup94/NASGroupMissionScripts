---------------------------------------------------------------------------
-- Persian Gulf theater ATC script loader.
--
-- Sets the map-specific paths NASG_ATC_SCRIPT_LOADER needs (airport
-- database, comms config, tracked points, procedures), then loads the
-- shared Common/ATC/scripts/ATCScriptLoader.lua. A mission's top-level
-- script loader should call this file instead of loading
-- Common/ATC/scripts/ATCScriptLoader.lua directly -- that file has no
-- theater defaults of its own.
---------------------------------------------------------------------------

NASG_ATC_SCRIPT_LOADER = NASG_ATC_SCRIPT_LOADER or {}

NASG_ATC_SCRIPT_LOADER.CommonScriptsPath = NASG_ATC_SCRIPT_LOADER.CommonScriptsPath
        or "C:/NASGroup/NASGroupMissionScripts/Common/"

NASG_ATC_SCRIPT_LOADER.MissionScriptsPath = "C:/NASGroup/NASGroupMissionScripts/CVW-17/Persian Gulf/"

-- Structural airport database (all map airports). Loaded before the comms
-- config so ActivateAirport can find each airport's definition.
NASG_ATC_SCRIPT_LOADER.MissionATCAirports =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_Airports.lua"

NASG_ATC_SCRIPT_LOADER.MissionATCConfig =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_Config.lua"

-- Center-tracked points (tankers, bullseye, objectives, etc.). Loaded
-- after the comms config so its RegisterTrackedPoint calls run last.
NASG_ATC_SCRIPT_LOADER.MissionATCTrackedPoints =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_TrackedPoints.lua"

-- Named navigation procedures (SID/STAR-style routes built from tracked
-- points). Loaded after tracked points so its RegisterProcedure calls can
-- reference them.
NASG_ATC_SCRIPT_LOADER.MissionATCProcedures =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_Procedures.lua"

assert(loadfile(NASG_ATC_SCRIPT_LOADER.CommonScriptsPath .. "ATC/scripts/ATCScriptLoader.lua"))()
