loadfile(lfs.writedir() .. 'Config/serverSettings.lua')()
dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBotConfig.lua')
DCSServerBotConfig = require('DCSServerBotConfig')
SERVER_SETTINGS = cfg -- cfg table is from the current DCS servers config/serverSettings.lua  

local mission_scripts_path =  "C:/NASGroup/NASGroupMissionScripts/CVW-17/Nellis/"
local common_scripts_path = "C:/NASGroup/NASGroupMissionScripts/Common/"
local moose_folder = "C:/NASGroup/MOOSE_INCLUDE/Moose_Include_Static/"
-- local user_folder = os.getenv('USERPROFILE'):gsub("\\","/") .. "/"
local user_folder = "C:/Users/naval/"


SERVER_LOCATION = user_folder .. "Saved Games/" .. DCSServerBotConfig.INSTANCE_NAME .. "/"
SRS_PATH = "C:/DCS-SimpleRadioStandalone/ExternalAudio"
SRS_PORT = DCSServerBotConfig.SRS_PORT
TTS_SERVICE_PORT = 8765

-- NASG ATC flight plan inputs.
-- Flight plans are loaded from:
--   NASG_ATC_FLIGHT_PLAN_ROOT_FOLDER / current date / callsign folder / *.json or *.dtc
-- Example:
--   E:/DCS Stuff/FlightPlans/2026-06-05/HOBO11/cftest.json
NASG_ATC_FLIGHT_PLAN_FILE = common_scripts_path .. "ATC/tmp/nasg_atc_flight_plans.json"
NASG_ATC_FLIGHT_PLAN_ROOT_FOLDER = "C:/Users/naval/Saved Games/DCS.Test/FlightPlans"
NASG_ATC_FLIGHT_PLAN_DAY_FORMAT = "%Y-%m-%d"
NASG_ATC_DTC_FLIGHT_PLAN_ENABLED = true


COMMONSOUNDSFOLDER = common_scripts_path .. "sound/"


-- AIRBOSS/RANGE Sound file locations within the miz file
AIRBOSSBASESOUNDFOLDER = "Airboss Soundfiles/" -- needed for the default pilot sound files used by ariboss
AIRBOSSLSORAYNOR = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack LSO Raynor/"
AIRBOSSMARSHALRAYNOR = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack Marshal Raynor/"
AIRBOSSMARSHALGABRIELLA = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack Marshal Gabriella/"
RANGESOUNDFOLDER = "Range Soundfiles/"

-- Target/Trap sheet save locations
TARGETSHEETSTRAFELOCATION = SERVER_LOCATION .. "Logs/strafesheets"
TARGETSHEETBOMBLOCATION = SERVER_LOCATION .. "Logs/bombsheets"
TRAPSHEETLOCATION = SERVER_LOCATION .. "Logs/trapsheets"

-- Default tanker altitudes
MISSION_TANKER_ALTS = {}
MISSION_TANKER_ALTS.Boom = 26000
MISSION_TANKER_ALTS.Probe = 24000
MISSION_TANKER_ALTS.Offgoing = 18000
MISSION_TANKER_ALTS.Recovery = 8000

NASG_PYWS_DEBUG = false


-- Moose/mist (really need to getrid of MIST one of these days!)
assert(loadfile(moose_folder .. "Moose.lua"))()
--assert(loadfile(common_scripts_path .. "Test/NASG_ReloadScriptsMenu.lua"))()
assert(loadfile(common_scripts_path .. "ATC\\lua\\SRS_PythonWebSocket.lua"))() -- the order of these two matter this one first
MSRS.LoadConfigFile(nil, mission_scripts_path, "Persian_Gulf_msrs_config.lua") -- Note the "." here
assert(loadfile(common_scripts_path .. "ATC\\lua\\tts_init.lua"))() -- the order of these two matter this one second
assert(loadfile(common_scripts_path .. "ATC\\lua\\NASG_ATC_Core.lua"))()
assert(loadfile(common_scripts_path .. "mist.lua"))()

-- Common for all missions
assert(loadfile(common_scripts_path .. "refueling_monitor_mp.lua"))() -- client refueling monitor for discord reporting
assert(loadfile(common_scripts_path .. "flightlog.lua"))() -- Flight logging to DCSServerBot
assert(loadfile(common_scripts_path .. "rolln.lua"))() -- Just some helper functions
--assert(loadfile(common_scripts_path .. "dynamic_crewchief.lua"))() -- adds crew cheif in front of client spawns. requires mod, read lua file.
--assert(loadfile(common_scripts_path .. "stopGaps standalone.lua"))()

assert(loadfile(mission_scripts_path .. "NATO\\Nellis_AFB.lua"))()
assert(loadfile(mission_scripts_path .. "NATO\\NellisChief.lua"))()
--assert(loadfile(mission_scripts_path .. "NellisMissiles.lua"))()
assert(loadfile(mission_scripts_path .. "NATO\\ATIS.lua"))() -- creates atisNellis/atisCreech, must run before ATCScriptLoader

-- NASG ATC.
assert(loadfile(mission_scripts_path .. "NATO\\Nellis_ATC_ScriptLoader.lua"))()

-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('SET_CLIENT')