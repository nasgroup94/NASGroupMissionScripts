--[[ Refueling_Monitor]]
-- Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco", "Arco"})

-------------------------
-- AIRBOSS --
-------------------------

-- Set mission menu.
AIRBOSS.MenuF10Root=MENU_MISSION:New("Airboss").MenuPath

-- No MOOSE settings menu.
_SETTINGS:SetPlayerMenuOff()

--  local tanker=RECOVERYTANKER:New(UNIT:FindByName("CVN-71"), "Texaco")
-- -- tanker:SetTakeoffAir()
-- -- tanker:SetRecoveryAirboss(true)
-- tanker:SetTakeoffCold()
-- tanker:SetRadio(260)
-- tanker:SetAltitude(8000)
-- tanker:SetModex(703)
-- tanker:SetTACAN(60, "TKR")
-- tanker:__Start(120)

-- hightanker=RECOVERYTANKER:New(UNIT:FindByName("CVN75"), "Arco")
-- hightanker:SetTakeoffAir()
-- hightanker:SetRadio(268)
-- hightanker:SetAltitude(18000)
-- hightanker:SetRacetrackDistances(25, 8)
-- hightanker:SetModex(611)
-- hightanker:SetTACAN(55, "ARC")
-- hightanker:SetSpeed(350)
-- hightanker:Start()

-- RecoveryTankerLowSpawn = SPAWN
--   :New( "RecoveryTankerLow" )
--   :InitLimit( 1, 10 )
--   :SpawnScheduled(1,1)

-- RecoveryTankerHighSpawn = SPAWN
--   :New( "Arco" )
--   :InitLimit( 1, 10 )
--   :SpawnScheduled(1,1)

-- rescuehelo=RESCUEHELO:New(UNIT:FindByName("CVN-71"), "Rescue Helo")
-- rescuehelo:SetTakeoffCold()
-- rescuehelo:SetRespawnInAir()
-- rescuehelo:SetRescueDuration(1)
-- rescuehelo:SetRescueHoverSpeed(5)
-- rescuehelo:SetRescueZone(15)
-- rescuehelo:SetModex(43)
-- rescuehelo:Start(30)


-- awacs=RECOVERYTANKER:New("CVN-71", "Wizard")
-- awacs:SetAWACS()
-- awacs:SetTakeoffCold()
-- awacs:SetRadio(269)
-- awacs:SetAltitude(25000)
-- awacs:SetCallsign(CALLSIGN.AWACS.Wizard)
-- awacs:SetRacetrackDistances(30, 15)
-- awacs:SetModex(611)
-- awacs:SetTACAN(52, "WIZ")
-- awacs:__Start(150)

Warfighter=AIRBOSS:New("CVN-73", "CVN-73 George Washington")
-- Delete auto recovery window.
function Warfighter:OnAfterStart(From,Event,To)
  self:DeleteAllRecoveryWindows()
end

-- function Warfighter:OnBeforeLSOGrade(From, Event, To)

Warfighter:SetFunkManOn(10042, "127.0.0.1")
Warfighter:SetDebugModeON()
Warfighter:SetMenuRecovery(60, 27, true, 0)
Warfighter:Load()
Warfighter:SetAutoSave("C:/Users/dcs/Saved Games/DCS.Liberation/Logs/trapsheets")
Warfighter:SetTrapSheet(TRAPSHEETLOCATION)
Warfighter:SetTACAN(71, "X", "RSV")
Warfighter:SetICLS(11,"RSV")
Warfighter:SetLSORadio(265,AM)
Warfighter:SetMarshalRadio(264, AM)
Warfighter:SetPatrolAdInfinitum()
Warfighter:SetAirbossNiceGuy()
Warfighter:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
Warfighter:SetMaxSectionSize(4)
Warfighter:SetMPWireCorrection(12)
Warfighter:SetRadioRelayLSO("LSO Huey")
Warfighter:SetRadioRelayMarshal("Marshal Huey")
Warfighter:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Warfighter:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
-- Warfighter:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
Warfighter:SetDespawnOnEngineShutdown()
Warfighter:SetRecoveryTanker(tanker)
Warfighter:SetMenuSingleCarrier()
Warfighter.trapsheet = false
local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes({"Recovery", "Wizard"}):FilterStart()
Warfighter:SetExcludeAI(CarrierExcludeSet)
Warfighter:Start()



-- local cvnGroup = GROUP:FindByName( "CVN75" )
-- local CVN_GROUPZone = ZONE_GROUP:New('cvnGroupZone', cvnGroup, 1111)

BLUE_CLIENT_SET = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive():FilterStart()