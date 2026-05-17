loadfile(lfs.writedir() .. 'Config/serverSettings.lua')()
dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBotConfig.lua')
DCSServerBotConfig = require('DCSServerBotConfig')
SERVER_SETTINGS = cfg -- cfg table is from the current DCS servers config/serverSettings.lua  

package.path = [[C:\NASGroup\NASGroupMissionScripts\Common\TTS Test\?.lua;]] .. package.path

local mission_scripts_path =  "C:/NASGroup/NASGroupMissionScripts/CVW-17/Persian Gulf/"
local common_scripts_path = "C:/NASGroup/NASGroupMissionScripts/Common/"
local moose_folder = "C:/NASGroup/MOOSE_INCLUDE/Moose_Include_Static/"
-- local user_folder = os.getenv('USERPROFILE'):gsub("\\","/") .. "/"
local user_folder = "C:/Users/naval/"


-- GLOBALS

SERVER_LOCATION = user_folder .. "Saved Games/" .. DCSServerBotConfig.INSTANCE_NAME .. "/"
SRS_PATH = "C:/DCS-SimpleRadioStandalone/ExternalAudio"
SRS_PORT = DCSServerBotConfig.SRS_PORT
TTS_SERVICE_PORT = 8765


COMMONSOUNDSFOLDER = common_scripts_path .. "sound/"

-- AIRBOSS/RANGE Sound file locations within the miz file
AIRBOSSBASESOUNDFOLDER = COMMONSOUNDSFOLDER .. "AIRBOSS/" -- needed for the default pilot sound files used by airboss
AIRBOSSLSORAYNOR = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack LSO Raynor/"
AIRBOSSMARSHALRAYNOR = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack Marshal Raynor/"
AIRBOSSMARSHALGABRIELLA = AIRBOSSBASESOUNDFOLDER .. "Airboss Soundpack Marshal Gabriella/"
RANGESOUNDFOLDER = COMMONSOUNDSFOLDER .. "Range Soundfiles/"
ATISSOUNDFOLDER = COMMONSOUNDSFOLDER .. "/ATIS/"

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
assert(loadfile(common_scripts_path .. "Test/NASG_ReloadScriptsMenu.lua"))()
assert(loadfile(common_scripts_path .. "TTS Test\\SRS_PythonWebSocket.lua"))() -- the order of these two matter this one first
MSRS.LoadConfigFile(nil, mission_scripts_path, "Persian_Gulf_msrs_config.lua") -- Note the "." here
assert(loadfile(common_scripts_path .. "TTS Test\\tts_init.lua"))() -- the order of these two matter this one second
assert(loadfile(common_scripts_path .. "mist.lua"))()

-- Common for all missions
assert(loadfile(common_scripts_path .. "refueling_monitor_mp.lua"))() -- client refueling monitor for discord reporting
assert(loadfile(common_scripts_path .. "flightlog.lua"))() -- Flight logging to DCSServerBot
assert(loadfile(common_scripts_path .. "skynet-iads-compiled.lua"))() 
assert(loadfile(common_scripts_path .. "rolln.lua"))() -- Just some helper functions
-- assert(loadfile(common_scripts_path .. "dynamic_crewchief.lua"))() -- adds crew cheif in front of client spawns. requires mod, read lua file.

-- Persian Gulf specific
-- assert(loadfile(mission_scripts_path .. "marianas_airboss_heli.lua"))() -- Moded airboss for helis, ** must be loaded before the carrier AIRBOSS **
assert(loadfile(mission_scripts_path .. "NATO\\Persian_Gulf_carrier.lua"))() -- carrier/tarawa AIRBOSS
assert(loadfile(mission_scripts_path .. "NATO\\Persian_Gulf_Blue_CSG_Chief.lua"))() 
assert(loadfile(mission_scripts_path .. "NATO\\Persian_Gulf_Al_Minad_AFB.lua"))() 
assert(loadfile(mission_scripts_path .. "NATO\\Persian_Gulf_Chief_Blue.lua"))()
assert(loadfile(mission_scripts_path .. "NATO\\Blue_IADS.lua"))()
assert(loadfile(mission_scripts_path .. "NATO\\ATIS.lua"))()
assert(loadfile(mission_scripts_path .. "NATO\\BlueATC.lua"))()
assert(loadfile(mission_scripts_path .. "Training\\Blue_Ranges.lua"))()
assert(loadfile(mission_scripts_path .. "Training\\SEADRangeIADS.lua"))()
assert(loadfile(mission_scripts_path .. "Training\\AAPVERange.lua"))()







--Dev
-- AIRBASE:FindByName("Andersen AFB"):MarkParkingSpots() -- For development, marks parkiong spots on F10 map with IDs used for scripting
ROLLN.db("Path: " .. (debug.getinfo(1).source:match("@?(.*/)") or ''), true)

-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('MSRS')
-- BASE:TraceClass('MARKEROPS_BASE')
-- BASE:TraceClass('MARKEROPS')
-- BASE:TraceClass('AUFTRAG')
-- BASE:TraceClass('BASE')


--assert(loadfile(mission_scripts_path .. "NATO\\ATIS.lua"))()
