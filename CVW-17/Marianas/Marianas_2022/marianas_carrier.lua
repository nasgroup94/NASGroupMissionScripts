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
RecoveryTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN73"), "CVN73_ARCO1")
RecoveryTanker:SetTakeoffCold()
RecoveryTanker:SetRadio(260)
RecoveryTanker:SetAltitude(MISSION_TANKER_ALTS.Recovery)
RecoveryTanker:SetModex(703)
RecoveryTanker:SetCallsign(CALLSIGN.Tanker.Arco, 9)
RecoveryTanker:SetTACAN(60, "AR9")
RecoveryTanker:__Start(60)

HighTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN73"), "CVN73_ARCO2")
HighTanker:SetTakeoffAir()
HighTanker:SetRadio(268)
HighTanker:SetAltitude(MISSION_TANKER_ALTS.Offgoing)
HighTanker:SetRacetrackDistances(25, 8)
HighTanker:SetModex(611)
HighTanker:SetCallsign(CALLSIGN.Tanker.Arco, 8)
HighTanker:SetTACAN(68, "AR8")
HighTanker:SetSpeed(350)
HighTanker:Start()

RescueHelo = RESCUEHELO:New(UNIT:FindByName("CVN73"), "CVN73_RESCUEHELO")
RescueHelo:SetTakeoffCold()
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

Awacs = RECOVERYTANKER:New("CVN73", "CVN73_WIZARD")
Awacs:SetAWACS()
Awacs:SetTakeoffCold()
Awacs:SetRadio(269)
Awacs:SetAltitude(25000)
Awacs:SetCallsign(CALLSIGN.AWACS.Wizard, 6)
Awacs:SetRacetrackDistances(30, 15)
Awacs:SetModex(611)
Awacs:SetTACAN(69, "WZ6")
Awacs:__Start(150)

Washington = AIRBOSS:New("CVN73", "CVN-73 Warfighter")

function Washington:OnAfterStart(From, Event, To)
    self:DeleteAllRecoveryWindows()

    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), 1)
end

function Washington:OnAfterPassingWaypoint(From, Event, To, n)
    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), n)
end

Washington:SetFunkManOn(10042, "127.0.0.1")
-- Washington:SetDebugModeON()
Washington:SetMenuRecovery(60, 27, false, 0) --Curcuit changed to prevent boat from circling
Washington:SetAutoSave(TRAPSHEETLOCATION)
Washington:SetTrapSheet(TRAPSHEETLOCATION)
Washington:Load()
Washington:SetTACAN(73, "X", "WFR")
Washington:SetICLS(13, "GWW")
Washington:SetLSORadio(265, AM)
Washington:SetMarshalRadio(264, AM)
Washington:SetPatrolAdInfinitum()
Washington:SetAirbossNiceGuy()
Washington:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
Washington:SetMaxSectionSize(4)
Washington:SetMPWireCorrection(12)
Washington:SetRadioRelayLSO("CVN73_LSORELAY")
Washington:SetRadioRelayMarshal("CVN73_MARSHALRELAY")
Washington:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Washington:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
Washington:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
Washington:SetDespawnOnEngineShutdown()
Washington:SetRecoveryTanker(RecoveryTanker)
Washington:SetMenuSingleCarrier()
Washington:SetHandleAIOFF()
Washington.trapsheet = false
-- Washington:SetDebugModeON()
-- Washington.Debug = True

-- local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes("Arco"):FilterStart()
-- Washington:SetExcludeAI(CarrierExcludeSet)

function Washington:OnAfterRecoveryStart(Event, From, To, Case, Offset)
    env.info(string.format("Starting Recovery Case %d ops.", Case))
end

-- Start airboss class.
Washington:Start()


------------------------------------------------ TARAWA ----------------------------------------------
EXPD11_RESCUEHELO = RESCUEHELO:New(UNIT:FindByName("Tarawa"), "EXPD11_RESCUEHELO")
EXPD11_RESCUEHELO:SetTakeoffCold()
EXPD11_RESCUEHELO:SetRespawnInAir()
EXPD11_RESCUEHELO:SetRescueDuration(1)
EXPD11_RESCUEHELO:SetRescueHoverSpeed(5)
EXPD11_RESCUEHELO:SetRescueZone(15)
EXPD11_RESCUEHELO:SetModex(100)
EXPD11_RESCUEHELO:Start(30)

-- Create AIRBOSS object.
Tarawa = AIRBOSS:New("Tarawa", "LHA-1 Tarawa")

-- Delete auto recovery window.
function Tarawa:OnAfterStart(From, Event, To)
    self:DeleteAllRecoveryWindows()

    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), 1)
end

function Tarawa:OnAfterPassingWaypoint(From, Event, To, n)
    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), n)
end

Tarawa:SetFunkManOn(10042, "127.0.0.1")
Tarawa:SetTACAN(108, "X", "LHA")
Tarawa:SetICLS(18)
Tarawa:SetTrapSheet(TRAPSHEETLOCATION)
Tarawa:SetAutoSave(TRAPSHEETLOCATION)
Tarawa:Load()
Tarawa:SetLineupErrorThresholds(.5, -.5, -1, -2, -4, 1, 2, 4)
Tarawa:SetStatusUpdateTime(1)
Tarawa:SetRadioUnitName("EXPD11_RADIORELAY")
Tarawa:SetMarshalRadio(306)
Tarawa:SetLSORadio(306)
Tarawa:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
Tarawa:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Tarawa:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
Tarawa:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
Tarawa:SetDespawnOnEngineShutdown()
Tarawa:SetMenuSingleCarrier()
Tarawa:SetMenuRecovery(60, 20, false,0)
Tarawa:SetHandleAION()
Tarawa.trapsheet = false

Tarawa:Start()


HeliAirbossMenus = AIRBOSS_HELI:New({ Washington, Tarawa })


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
