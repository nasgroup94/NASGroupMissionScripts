--[[
	BASE:TraceOnOff(true)
	BASE:TraceLevel(3)
	BASE:TraceClass('AIRBOSS')
    -- BASE:TraceClass('MARKEROPS_BASE')
    -- BASE:TraceClass('MARKEROPS')
    -- BASE:TraceClass('AUFTRAG')
    -- BASE:TraceClass('BASE')
	--]]

-------------------------
-- Refueling_Monitor --
-------------------------
-- Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco", "Arco"})
Refueling_Monitor = REFUELING_MONITOR:New({ "Refueling", "Tanker", "Shell", "Texaco", "Arco", "ARCO", "ARCO3", "ARS909", "ARS909MPRS" })


-------------------------
-- AIRBOSS --
-------------------------

-- Set mission menu.
AIRBOSS.MenuF10Root = MENU_MISSION:New("Airboss").MenuPath

-- No MOOSE settings menu.
_SETTINGS:SetPlayerMenuOff()
_SETTINGS:SetA2G_MGRS()
_SETTINGS:SetA2A_BRAA()
_SETTINGS:SetImperial()

BLUE_CLIENT_SET = SET_CLIENT:New():FilterActive():FilterCoalitions("blue"):FilterStart()
BLUE_CLIENT_SET:HandleEvent(EVENTS.PlayerEnterAircraft)

RED_CLIENT_SET = SET_CLIENT:New():FilterActive():FilterCoalitions("red"):FilterStart()
RED_CLIENT_SET:HandleEvent(EVENTS.PlayerEnterAircraft)

--------------------------------------------- CVN73 -------------------------------------------------------
-- S3
RecoveryTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN-65"), "CVN65_ARCO1")
RecoveryTanker:SetTakeoffAir()
RecoveryTanker:SetRespawnInAir()
RecoveryTanker:SetRadio(260)
RecoveryTanker:SetAltitude(MISSION_TANKER_ALTS.Recovery)
RecoveryTanker:SetModex(703)
RecoveryTanker:SetCallsign(CALLSIGN.Tanker.Arco, 9)
RecoveryTanker:SetTACAN(60, "AR1")
RecoveryTanker:__Start(60)

-- HighTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN-75 Lone Warrior"), "CVN75_ARCO2")
-- HighTanker:SetTakeoffAir()
-- HighTanker:SetRadio(268)
-- HighTanker:SetAltitude(MISSION_TANKER_ALTS.Offgoing)
-- HighTanker:SetRacetrackDistances(25, 8)
-- HighTanker:SetModex(611)
-- HighTanker:SetCallsign(CALLSIGN.Tanker.Arco, 8)
-- HighTanker:SetTACAN(68, "AR8")
-- HighTanker:SetSpeed(350)
-- HighTanker:Start()

RescueHelo = RESCUEHELO:New(UNIT:FindByName("CVN-65"), "CVN65_RESCUEHELO")
RescueHelo:SetTakeoffCold()
RescueHelo:SetHomeBase("CVN65")
RescueHelo:SetRespawnInAir()
RescueHelo:SetRescueDuration(1)
RescueHelo:SetRescueHoverSpeed(5)
RescueHelo:SetRescueZone(15)
RescueHelo:SetModex(42)
RescueHelo:Start(30)

--[[ Using the new MSRS extended RESCUEHELO class.
-- rescuehelo=RESCUEHELOMSRS:New(UNIT:FindByName("CVN73"), "Rescue Helo", SRSSETTINGS.GoogleVoice.Female.en_AU_Wavenet_C, {265}, {243, 264, 265}, {0}, {0, 0, 0},2)
-- rescuehelo:SetHomeBase(AIRBASE:FindByName("USS Ticonderoga"))
-- rescuehelo:SetTakeoffAir()
rescuehelo:SetTakeoffCold()
rescuehelo:SetRespawnInAir()
rescuehelo:SetRescueDuration(1)
rescuehelo:SetRescueHoverSpeed(5)
rescuehelo:SetRescueZone(15)
rescuehelo:SetModex(42)
rescuehelo:Start(30)
--]]

Awacs = RECOVERYTANKER:New("CVN-65", "CVN65_FOCUS")
Awacs:SetAWACS()
Awacs:SetTakeoffAir()
Awacs:SetRespawnInAir()
Awacs:SetRadio(269)
Awacs:SetAltitude(25000)
Awacs:SetCallsign(CALLSIGN.AWACS.Wizard, 6)
Awacs:SetRacetrackDistances(30, 15)
Awacs:SetModex(611)
Awacs:SetTACAN(69, "WZ6")
Awacs:__Start(150)

LoneWarrior = AIRBOSS:New("CVN-65", "CVN-65")

-- function LoneWarrior:OnAfterStart(From, Event, To)
--     self:DeleteAllRecoveryWindows()

--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), 1)
-- end

-- function LoneWarrior:OnAfterPassingWaypoint(From, Event, To, n)
--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), n)
-- end

LoneWarrior:SetFunkManOn(10042, "127.0.0.1")
-- LoneWarrior:SetDebugModeON()
LoneWarrior:SetMenuRecovery(60, 27, false, 0) --Curcuit changed to prevent boat from circling
LoneWarrior:SetAutoSave(TRAPSHEETLOCATION)
LoneWarrior:SetTrapSheet(TRAPSHEETLOCATION)
LoneWarrior:Load()
LoneWarrior:SetTACAN(65, "X", "CLM")
LoneWarrior:SetICLS(5, "CLM")
LoneWarrior:SetLSORadio(265)
LoneWarrior:SetMarshalRadio(264)
LoneWarrior:SetPatrolAdInfinitum()
LoneWarrior:SetAirbossNiceGuy()
LoneWarrior:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
LoneWarrior:SetMaxSectionSize(4)
LoneWarrior:SetMPWireCorrection(12)
LoneWarrior:SetRadioRelayLSO("CVN65_LSORELAY")
LoneWarrior:SetRadioRelayMarshal("CVN65_MARSHALRELAY")
LoneWarrior:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
LoneWarrior:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
LoneWarrior:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
LoneWarrior:SetDespawnOnEngineShutdown()
LoneWarrior:SetRecoveryTanker(RecoveryTanker)
LoneWarrior:SetMenuSingleCarrier()
LoneWarrior:SetHandleAIOFF()

LoneWarrior.trapsheet = false
-- LoneWarrior:SetDebugModeON()
-- LoneWarrior.Debug = True

-- local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes("Arco"):FilterStart()
-- LoneWarrior:SetExcludeAI(CarrierExcludeSet)

function LoneWarrior:OnAfterRecoveryStart(Event, From, To, Case, Offset)
    env.info(string.format("Starting Recovery Case %d ops.", Case))
end

-- Start airboss class.
LoneWarrior:Start()
LoneWarrior:AddRecoveryWindow("8:10","12:00",1,0,true,27,false)

-- ------------------------------------------------ TARAWA ----------------------------------------------
-- EXPD11_RESCUEHELO = RESCUEHELO:New(UNIT:FindByName("Tarawa"), "EXPD11_RESCUEHELO")
-- EXPD11_RESCUEHELO:SetHomeBase("Tarawa-1")
-- EXPD11_RESCUEHELO:SetTakeoffCold()
-- EXPD11_RESCUEHELO:SetRespawnInAir()
-- EXPD11_RESCUEHELO:SetRescueDuration(1)
-- EXPD11_RESCUEHELO:SetRescueHoverSpeed(5)
-- EXPD11_RESCUEHELO:SetRescueZone(15)
-- EXPD11_RESCUEHELO:SetModex(100)
-- EXPD11_RESCUEHELO:Start(30)

-- -- Create AIRBOSS object.
-- Tarawa = AIRBOSS:New("Tarawa", "LHA-1 Tarawa")

-- -- Delete auto recovery window.
-- function Tarawa:OnAfterStart(From, Event, To)
--     self:DeleteAllRecoveryWindows()

--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), 1)
-- end

-- function Tarawa:OnAfterPassingWaypoint(From, Event, To, n)
--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), n)
-- end

-- Tarawa:SetFunkManOn(10042, "127.0.0.1")
-- Tarawa:SetTACAN(108, "X", "LHA")
-- Tarawa:SetICLS(18)
-- Tarawa:SetTrapSheet(TRAPSHEETLOCATION)
-- Tarawa:SetAutoSave(TRAPSHEETLOCATION)
-- Tarawa:Load()
-- Tarawa:SetLineupErrorThresholds(.5, -.5, -1, -2, -4, 1, 2, 4)
-- Tarawa:SetStatusUpdateTime(1)
-- Tarawa:SetRadioUnitName("EXPD11_RADIORELAY")
-- Tarawa:SetMarshalRadio(306)
-- Tarawa:SetLSORadio(306)
-- Tarawa:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
-- Tarawa:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
-- Tarawa:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
-- Tarawa:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
-- Tarawa:SetDespawnOnEngineShutdown()
-- Tarawa:SetMenuSingleCarrier()
-- Tarawa:SetMenuRecovery(60, 20, false,0)
-- Tarawa:SetHandleAION()
-- Tarawa.trapsheet = false

-- Tarawa:Start()


-- HeliAirbossMenus = AIRBOSS_HELI:New({ LoneWarrior, Tarawa })


--#region Kuznetsov
-- KUZNETSOV = AIRBOSS:New("CV1143", "CV 1143 Kuznetsov")

-- function KUZNETSOV:OnAfterStart(From, Event, To)
-- 	self:DeleteAllRecoveryWindows()

-- 	-- Recording waypoint to be used in the persistence script
-- 	PassingWaypoint(self.carrier:GetName(), 1)
-- end

-- function KUZNETSOV:OnAfterPassingWaypoint(From, Event, To, n)
-- 	-- Recording waypoint to be used in the persistence script
--     PassingWaypoint(self.carrier:GetName(), n)
-- end

-- KUZNETSOV:SetMenuRecovery(60, 27, true, 0)
-- -- KUZNETSOV:Load()
-- -- KUZNETSOV:SetAutoSave()
-- KUZNETSOV:SetTACAN(34, "X", "KUZ")
-- KUZNETSOV:SetICLS(13, "KUZ")
-- KUZNETSOV:SetLSORadio(221, AM)
-- KUZNETSOV:SetMarshalRadio(222, AM)
-- KUZNETSOV:SetPatrolAdInfinitum()
-- KUZNETSOV:SetAirbossNiceGuy()
-- KUZNETSOV:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
-- KUZNETSOV:SetMaxSectionSize(4)
-- -- KUZNETSOV:SetMPWireCorrection(12)
-- -- KUZNETSOV:SetRadioRelayLSO("CV1143_LSORELAY")
-- -- KUZNETSOV:SetRadioRelayMarshal("CV1143_MARSHALRELAY")
-- KUZNETSOV:SetSoundfilesFolder("Airboss Soundfiles/")
-- KUZNETSOV:SetDespawnOnEngineShutdown()
-- -- KUZNETSOV:SetRecoveryTanker(tanker)
-- KUZNETSOV:SetMenuSingleCarrier(False)
-- KUZNETSOV:SetHandleAION()
-- -- KUZNETSOV.trapsheet = false

-- KUZNETSOV:Start()
--#endregion
