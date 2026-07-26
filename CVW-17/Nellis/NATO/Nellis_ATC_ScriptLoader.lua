---------------------------------------------------------------------------
-- Nellis (NTTR) theater ATC script loader.
--
-- Sets the map-specific paths NASG_ATC_SCRIPT_LOADER needs (airport
-- database, comms config, tracked points, procedures), then loads the
-- shared Common/ATC/scripts/ATCScriptLoader.lua. A mission's top-level
-- script loader should call this file instead of loading
-- Common/ATC/scripts/ATCScriptLoader.lua directly -- that file has no
-- theater defaults of its own.
--
-- NATO/ATIS.lua (creates atisNellis/atisCreech) must be loaded before
-- this file, so Nellis_ATC_Config.lua's AttachMooseATIS calls have
-- something to attach.
---------------------------------------------------------------------------

NASG_ATC_SCRIPT_LOADER = NASG_ATC_SCRIPT_LOADER or {}

NASG_ATC_SCRIPT_LOADER.CommonScriptsPath = NASG_ATC_SCRIPT_LOADER.CommonScriptsPath
        or "C:/NASGroup/NASGroupMissionScripts/Common/"

NASG_ATC_SCRIPT_LOADER.MissionScriptsPath = "C:/NASGroup/NASGroupMissionScripts/CVW-17/Nellis/"

NASG_ATC_SCRIPT_LOADER.MissionATCAirports =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Nellis_ATC_Airports.lua"

NASG_ATC_SCRIPT_LOADER.MissionATCConfig =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Nellis_ATC_Config.lua"

NASG_ATC_SCRIPT_LOADER.MissionATCTrackedPoints =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Nellis_ATC_TrackedPoints.lua"

NASG_ATC_SCRIPT_LOADER.MissionATCProcedures =
        NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Nellis_ATC_Procedures.lua"

assert(loadfile(NASG_ATC_SCRIPT_LOADER.CommonScriptsPath .. "ATC/scripts/ATCScriptLoader.lua"))()
