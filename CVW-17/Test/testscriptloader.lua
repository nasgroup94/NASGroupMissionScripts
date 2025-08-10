loadfile(lfs.writedir() .. 'Config/serverSettings.lua')()
dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBotConfig.lua')
DCSServerBotConfig = require('DCSServerBotConfig')
SERVER_SETTINGS = cfg -- cfg table is from the current DCS servers config/serverSettings.lua  

local mission_scripts_path = debug.getinfo(1).source:match("@?(.*/)")
local common_scripts_path = "C:/NASGroup/NASGroupMissionScripts/Common/"
local moose_folder = "C:/NASGroup/MOOSE_INCLUDE/Moose_Include_Static/"
local user_folder = os.getenv('USERPROFILE'):gsub("\\","/") .. "/"


-- GLOBALS
SERVER_LOCATION = user_folder .. "Saved Games/" .. DCSServerBotConfig.INSTANCE_NAME .. "/"
-- GOOGLE_CREDS = "C:/VNAO/API-Keys/cvw7-tracking-11c8a6927776.json"
SRS_PATH = "C:/DCS-SimpleRadioStandalone/ExternalAudio"
SRS_PORT = DCSServerBotConfig.SRS_PORT
SRS_VOICES = {
    Female = {
        en_AU_Standard_A = "en-AU-Standard-A",
        en_AU_Standard_C = "en-AU-Standard-C",
        en_AU_Wavenet_A = "en-AU-Wavenet-A",
        en_AU_Wavenet_C = "en-AU-Wavenet-C",
        en_IN_Standard_A = "en-IN-Standard-A",
        en_IN_Standard_D = "en-IN-Standard-D",
        en_IN_Wavenet_A = "en-IN-Wavenet-A",
        en_IN_Wavenet_D = "en-IN-Wavenet-D",
        en_GB_Standard_A = "en-GB-Standard-A",
        en_GB_Standard_C = "en-GB-Standard-C",
        en_GB_Standard_F = "en-GB-Standard-F",
        en_GB_Wavenet_A = "en-GB-Wavenet-A",
        en_GB_Wavenet_C = "en-GB-Wavenet-C",
        en_GB_Wavenet_F = "en-GB-Wavenet-F",
        en_US_Standard_C = "en-US-Standard-C",
        en_US_Standard_E = "en-US-Standard-E",
        en_US_Standard_F = "en-US-Standard-F",
        en_US_Standard_G = "en-US-Standard-G",
        en_US_Standard_H = "en-US-Standard-H",
        en_US_Wavenet_C = "en-US-Wavenet-C",
        en_US_Wavenet_E = "en-US-Wavenet-E",
        en_US_Wavenet_F = "en-US-Wavenet-F",
        en_US_Wavenet_G = "en-US-Wavenet-G",
        en_US_Wavenet_H = "en-US-Wavenet-H"
    },
    Male = {
        en_AU_Standard_B = "en-AU-Standard-B",
        en_AU_Standard_D = "en-AU-Standard-D",
        en_AU_Wavenet_B = "en-AU-Wavenet-B",
        en_AU_Wavenet_D = "en-AU-Wavenet-D",
        en_IN_Standard_B = "en-IN-Standard-B",
        en_IN_Standard_C = "en-IN-Standard-C",
        en_IN_Wavenet_B = "en-IN-Wavenet-B",
        en_IN_Wavenet_C = "en-IN-Wavenet-C",
        en_GB_Standard_B = "en-GB-Standard-B",
        en_GB_Standard_D = "en-GB-Standard-D",
        en_GB_Wavenet_B = "en-GB-Wavenet-B",
        en_GB_Wavenet_D = "en-GB-Wavenet-D",
        en_US_Standard_A = "en-US-Standard-A",
        en_US_Standard_B = "en-US-Standard-B",
        en_US_Standard_D = "en-US-Standard-D",
        en_US_Standard_I = "en-US-Standard-I",
        en_US_Standard_J = "en-US-Standard-J",
        en_US_Wavenet_A = "en-US-Wavenet-A",
        en_US_Wavenet_B = "en-US-Wavenet-B",
        en_US_Wavenet_D = "en-US-Wavenet-D",
        en_US_Wavenet_I = "en-US-Wavenet-I",
        en_US_Wavenet_J = "en-US-Wavenet-J"
    }
}
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

-- Moose/mist (really need to getrid of MIST one of these days!)
assert(loadfile(moose_folder .. "Moose.lua"))()
assert(loadfile(common_scripts_path .. "mist.lua"))()

-- Common for all missions
-- assert(loadfile(common_scripts_path .. "refueling_monitor_mp.lua"))() -- client refueling monitor for discord reporting
-- assert(loadfile(common_scripts_path .. "flightlog.lua"))() -- Flight logging to DCSServerBot
-- assert(loadfile(common_scripts_path .. "rnt.lua"))() -- Random navy traffic
-- assert(loadfile(common_scripts_path .. "rolln.lua"))() -- Just some helper functions
-- assert(loadfile(common_scripts_path .. "dynamic_crewchief.lua"))() -- adds crew cheif in front of client spawns. requires mod, read lua file.

-- marianas specific
-- assert(loadfile(mission_scripts_path .. "marianas_airboss_heli.lua"))() -- Moded airboss for helis, ** must be loaded before the carrier AIRBOSS **
-- assert(loadfile(mission_scripts_path .. "marianas_carrier.lua"))() -- carrier/tarawa AIRBOSS
-- assert(loadfile(mission_scripts_path .. "marianas_chief_blue.lua"))() -- blue chief, squadrons, airwings
-- assert(loadfile(mission_scripts_path .. "marianas_chief_red.lua"))()  -- red chief, squadrons, airwings
-- assert(loadfile(mission_scripts_path .. "marianas_civilian_traffic.lua"))() -- random civilian traffic
-- assert(loadfile(mission_scripts_path .. "marianas_ranges.lua"))() -- Bombing range and strafe pit
-- assert(loadfile(mission_scripts_path .. "marianas_beacons.lua"))() -- Mission beacons
-- assert(loadfile(mission_scripts_path .. "marianas_tactical_menu.lua"))() -- menu for spawning missons
-- assert(loadfile(mission_scripts_path .. "marianas_csar_ctld.lua"))() -- Must be loaded after tactical menu
-- assert(loadfile(mission_scripts_path .. "marianas_map_markers.lua"))() -- Draws markup for unit locations on F10 map.
-- assert(loadfile(mission_scripts_path .. "marianas_markerops_tanker.lua"))() -- Allows tanker missions to launch via F10 map
-- assert(loadfile(mission_scripts_path .. "AWACsGCI.lua"))()
    assert(loadfile(mission_scripts_path .. "hooktest.lua"))() 

-- Set up MSRS (Moose SRS)
MSRS.LoadConfigFile(nil, mission_scripts_path, "marianas_msrs_config.lua") -- Note the "." here
MESSAGE.SetMSRS(MSRS.path,MSRS.port,nil,127,radio.modulation.AM,nil,nil,nil,nil,nil,"DCS Message") -- Note the "." here


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
