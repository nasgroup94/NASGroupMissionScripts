-- Default tanker altitudes
-- Comment this out if using the generated weather missions in line above.  These are tanker altitude variables that are set in the old generated
-- weather missions, so if not using the generated weather missions we used like in the BlackSea missions, we have to set it globally.
-- Any reference to these values really needs to be removed from any of the mission scripts going forward, vnaonServerBot takes care of setting
-- the weather now.
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
COMMONSOUNDFOLDER = "Common Soundfiles/"

-- Target/Trap sheet locations
TARGETSHEETSTRAFELOCATION = "C:/Users/vnaon/Saved Games/DCS.Liberation/Logs/strafesheets"
TARGETSHEETBOMBLOCATION = "C:/Users/vnaon/Saved Games/DCS.Liberation/Logs/bombsheets"
TRAPSHEETLOCATION = "c:/Users/vnaon/Saved Games/DCS.Liberation/Logs/trapsheets"

-- Moose/mist (really need to getrid of MIST one of these days!)
assert(loadfile("C:/VNAO/VNAO-MOOSE_INCLUDE/Moose_Include_Static/Moose.lua"))()
-- assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/Common/mist.lua"))()

-- Common for all missions
assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/Common/refueling_monitor_mp.lua"))() -- client refueling monitor for discord reporting
assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/Common/srs_msg.lua"))() -- Custom radio calls for things like the range, rescue helo, etc.
assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/Common/flightlog.lua"))() -- Flight logging to vnaonServerBot
assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/CVW-7/Liberation/LiberationAirboss_Tanker.lua"))() -- Flight logging to vnaonServerBot
-- shipID = 5463 --ABE
-- assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/CVW-7/Liberation/Flex 9 Spawn Cat 134 Cat 2 parking.lua"))() -- deck statics
-- shipID = 5469 --Washington
-- assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/CVW-7/Liberation/Flex 9 Spawn Cat 134 Cat 2 parking.lua"))() -- deck statics

-- assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/CVW-7/mission_timer.lua"))()