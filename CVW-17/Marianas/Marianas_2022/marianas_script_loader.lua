-- Mission specific scripts folder
local scripts_mission = "C:/VNAO/VNAO-Mission_Scripts/CVW-7/Marianas/Marianas_2022"

-- Load in DCSServerBot instance settings, values available:
-- VERSION = '{node.bot_version}'
--
-- General Values
-- BOT_HOST = '127.0.0.1'
-- BOT_PORT = {node.listen_port}
-- CHAT_COMMAND_PREFIX = '{node.config[chat_command_prefix]}'
-- MESSAGE_PLAYER_USERNAME = '{node.config[messages][player_username]}'
-- MESSAGE_PLAYER_DEFAULT_USERNAME = '{node.config[messages][player_default_username]}'
--
-- Instance Values
-- INSTANCE_NAME = {instance.name}
-- SERVER_USER = '{server.locals[server_user]}'
-- DCS_HOST = '127.0.0.1'
-- DCS_PORT = {instance.bot_port}
-- COALITIONS = {server.coalitions}                     -- true = enable coalitions
-- CHAT_CHANNEL = '{server.locals[channels][chat]}'   -- In-game chat will be replicated here
-- STATUS_CHANNEL = '{server.locals[channels][status]}' -- a persistent server and players status will be presented here
-- ADMIN_CHANNEL = '{server.locals[channels][admin]}' -- channel for admin messages and commands
-- MESSAGE_SERVER_FULL = '{server.locals[message_server_full]}'
-- MESSAGE_BAN = '{server.locals[message_ban]}'
--
-- Specific Values from Extensions
-- SRS_PORT = {instance.extensions[SRS][port]}
dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBotConfig.lua')
DCSServerBotConfig = require('DCSServerBotConfig')


local scripts_common = "C:/VNAO/VNAO-Mission_Scripts/Common"
local moose_folder = "C:/VNAO/VNAO-MOOSE_INCLUDE/Moose_Include_Static"
local user_folder = os.getenv('USERPROFILE'):gsub("\\","/")


-- GLOBALS
SERVER_LOCATION = user_folder .. "/Saved Games/" .. DCSServerBotConfig.INSTANCE_NAME
GOOGLE_CREDS = "C:/VNAO/API-Keys/cvw7-tracking-11c8a6927776.json"
SRS_PATH = "C:/Program Files/DCS-SimpleRadio-Standalone"
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
COMMONSOUNDSFOLDER = scripts_common .. "/sound"

-- Default tanker altitudes
MISSION_TANKER_ALTS = {}
MISSION_TANKER_ALTS.Boom = 26000
MISSION_TANKER_ALTS.Probe = 24000
MISSION_TANKER_ALTS.Offgoing = 18000
MISSION_TANKER_ALTS.Recovery = 8000

-- Sound files 
AIRBOSSBASESOUNDFOLDER = "Airboss Soundfiles/" -- needed for the default pilot sound files used by ariboss
AIRBOSSLSORAYNOR = "Airboss Soundfiles/Airboss Soundpack LSO Raynor"
AIRBOSSMARSHALRAYNOR = "Airboss Soundfiles/Airboss Soundpack Marshal Raynor/"
AIRBOSSMARSHALGABRIELLA = "Airboss Soundfiles/Airboss Soundpack Marshal Gabriella/"
RANGESOUNDFOLDER = "Range Soundfiles/"


-- Target/Trap sheet locations
TARGETSHEETSTRAFELOCATION = SERVER_LOCATION .. "/Logs/strafesheets"
TARGETSHEETBOMBLOCATION = SERVER_LOCATION .. "/Logs/bombsheets"
TRAPSHEETLOCATION = SERVER_LOCATION .. "/Logs/trapsheets"


-- Moose/mist (really need to getrid of MIST one of these days!)
assert(loadfile(moose_folder .. "/Moose.lua"))()
assert(loadfile(scripts_common .. "/mist.lua"))()

-- Common for all missions
assert(loadfile(scripts_common .. "/refueling_monitor_mp.lua"))() -- client refueling monitor for discord reporting
assert(loadfile(scripts_common .. "/srs_msg.lua"))() -- Custom radio calls for things like the range, rescue helo, etc.
assert(loadfile(scripts_common .. "/flightlog.lua"))() -- Flight logging to DCSServerBot
assert(loadfile(scripts_common .. "/rnt.lua"))() -- Random navy traffic
assert(loadfile(scripts_common .. "/rolln.lua"))() -- Just some helper functions

-- Marianas specific
assert(loadfile(scripts_mission .. "/marianas_airboss_heli.lua"))() -- Moded airboss for helis, ** must be loaded before the carrier AIRBOSS **
assert(loadfile(scripts_mission .. "/marianas_carrier.lua"))() -- carrier/tarawa AIRBOSS
assert(loadfile(scripts_mission .. "/marianas_chief_blue.lua"))() -- blue chief, squadrons, airwings
assert(loadfile(scripts_mission .. "/marianas_chief_red.lua"))()  -- red chief, squadrons, airwings
assert(loadfile(scripts_mission .. "/marianas_civilian_traffic.lua"))() -- random civilian traffic
assert(loadfile(scripts_mission .. "/marianas_ranges.lua"))() -- Bombing range and strafe pit
assert(loadfile(scripts_mission .. "/marianas_beacons.lua"))() -- Mission beacons
assert(loadfile(scripts_mission .. "/marianas_tactical_menu.lua"))() -- menu for spawning missons
assert(loadfile(scripts_mission .. "/marianas_csar_ctld.lua"))() -- Must be loaded after tactical menu
-- assert(loadfile(scripts_mission .. "/marianas_map_markers.lua"))() -- Draws markup for unit locations on F10 map.
assert(loadfile(scripts_mission .. "/marianas_markerops_tanker.lua"))() -- Allows tanker missions to launch via F10 map
assert(loadfile(scripts_mission .. "/scoring.lua"))()
--Dev
-- AIRBASE:FindByName("Andersen AFB"):MarkParkingSpots() -- For development, marks parkiong spots on F10 map with IDs used for scripting

--[[
	BASE:TraceOnOff(true)
	BASE:TraceLevel(3)
	BASE:TraceClass('SOCKET')
    -- BASE:TraceClass('MARKEROPS_BASE')
    -- BASE:TraceClass('MARKEROPS')
    -- BASE:TraceClass('AUFTRAG')
    -- BASE:TraceClass('BASE')
	--]]