--[[ Refueling_Monitor]]
Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco", "Arco"})

-------------------------
-- AIRBOSS --
-------------------------

-- Set mission menu.
AIRBOSS.MenuF10Root=MENU_MISSION:New("Airboss").MenuPath

-- No MOOSE settings menu.
_SETTINGS:SetPlayerMenuOff()

 local tanker=RECOVERYTANKER:New(UNIT:FindByName("CVN-73"), "Texaco")
-- tanker:SetTakeoffAir()
-- tanker:SetRecoveryAirboss(true)
tanker:SetTakeoffCold()
tanker:SetRadio(260)
tanker:SetAltitude(8000)
tanker:SetModex(703)
tanker:SetTACAN(60, "TKR")
tanker:__Start(120)

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
--   :New( "RecoveryTankerHigh" )
--   :InitLimit( 1, 10 )
--   :SpawnScheduled(1,1)

rescuehelo=RESCUEHELO:New(UNIT:FindByName("CVN-73"), "Rescue Helo")
rescuehelo:SetTakeoffCold()
rescuehelo:SetRespawnInAir()
rescuehelo:SetRescueDuration(1)
rescuehelo:SetRescueHoverSpeed(5)
rescuehelo:SetRescueZone(15)
rescuehelo:SetModex(43)
rescuehelo:Start(30)

-- rescuehelo2=RESCUEHELO:New(UNIT:FindByName("CVN-72"), "Rescue Helo")
-- rescuehelo2:SetTakeoffCold()
-- rescuehelo2:SetRespawnInAir()
-- rescuehelo2:SetRescueDuration(1)
-- rescuehelo2:SetRescueHoverSpeed(5)
-- rescuehelo2:SetRescueZone(15)
-- rescuehelo2:SetModex(42)
-- rescuehelo2:Start(30)

awacs=RECOVERYTANKER:New("CVN-73", "Wizard")
awacs:SetAWACS()
awacs:SetTakeoffCold()
awacs:SetRadio(269)
awacs:SetAltitude(25000)
awacs:SetCallsign(CALLSIGN.AWACS.Wizard)
awacs:SetRacetrackDistances(30, 15)
awacs:SetModex(611)
awacs:SetTACAN(52, "WIZ")
awacs:__Start(150)

Warfighter=AIRBOSS:New("CVN-73", "CVN-73 George Washington")
-- Delete auto recovery window.
function Warfighter:OnAfterStart(From,Event,To)
  self:DeleteAllRecoveryWindows()
end

-- function Warfighter:OnBeforeLSOGrade(From, Event, To)

Warfighter:SetFunkManOn(10042, "127.0.0.1")
Warfighter:SetMenuRecovery(60, 27, true, 0)
Warfighter:Load()
Warfighter:SetAutoSave(TRAPSHEETLOCATION)
Warfighter:SetTrapSheet(TRAPSHEETLOCATION)
Warfighter:SetTACAN(73, "X", "WFR")
Warfighter:SetICLS(13,"WFR")
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
-- Warfighter:SetMenuSingleCarrier(True)
Warfighter.trapsheet = false
local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes({"Recovery", "Wizard"}):FilterStart()
Warfighter:SetExcludeAI(CarrierExcludeSet)
Warfighter:Start()


-- Lincoln=AIRBOSS:New("CVN-72", "CVN-72 Abraham Lincoln")
-- -- Delete auto recovery window.
-- function Lincoln:OnAfterStart(From,Event,To)
--   self:DeleteAllRecoveryWindows()
-- end

-- Lincoln:SetFunkManOn(10042, "127.0.0.1")
-- -- Lincoln:SetMenuRecovery(60, 27, true, 0)
-- Lincoln:Load()
-- Lincoln:SetAutoSave("C:/Users/dcs/Saved Games/DCS.Liberation/Logs/trapsheets")
-- Lincoln:SetTrapSheet(TRAPSHEETLOCATION)
-- Lincoln:SetTACAN(72, "X", "LCN")
-- Lincoln:SetICLS(12,"LCN")
-- Lincoln:SetLSORadio(267,AM)
-- Lincoln:SetMarshalRadio(266, AM)
-- Lincoln:SetPatrolAdInfinitum()
-- Lincoln:SetAirbossNiceGuy()
-- Lincoln:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
-- Lincoln:SetMaxSectionSize(4)
-- Lincoln:SetMPWireCorrection(12)
-- Lincoln:SetRadioRelayLSO("LSO Huey")
-- Lincoln:SetRadioRelayMarshal("Marshal Huey")
-- Lincoln:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
-- Lincoln:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
-- -- Warfighter:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
-- Lincoln:SetDespawnOnEngineShutdown()
-- -- Lincoln:SetRecoveryTanker(tanker)
-- -- Lincoln:SetMenuSingleCarrier(True)
-- Lincoln.trapsheet = false
-- local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes({"Recovery", "Wizard"}):FilterStart()
-- Lincoln:SetExcludeAI(CarrierExcludeSet)
-- Lincoln:Start()

-- local cvnGroup = GROUP:FindByName( "CVN75" )
-- local CVN_GROUPZone = ZONE_GROUP:New('cvnGroupZone', cvnGroup, 1111)

BLUE_CLIENT_SET = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive():FilterStart()