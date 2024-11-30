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
RecoveryTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN-72"), "ARCO")
RecoveryTanker:SetTakeoffCold()
RecoveryTanker:SetRadio(266)
RecoveryTanker:SetAltitude(MISSION_TANKER_ALTS.Recovery)
RecoveryTanker:SetModex(012)
RecoveryTanker:SetCallsign(CALLSIGN.Tanker.Arco, 9)
RecoveryTanker:SetTACAN(16, "ARCO")
RecoveryTanker:__Start(60)


RescueHelo = RESCUEHELO:New(UNIT:FindByName("CVN-72"), "Rescue Helo")
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

-- Awacs = RECOVERYTANKER:New("CVN-72", "Wizard")
-- Awacs:SetAWACS()
-- Awacs:SetTakeoffCold()
-- Awacs:SetRadio(269)
-- Awacs:SetAltitude(25000)
-- Awacs:SetCallsign(CALLSIGN.AWACS.Wizard, 6)
-- Awacs:SetRacetrackDistances(30, 15)
-- Awacs:SetModex(611)
-- Awacs:SetTACAN(69, "WZ6")
-- Awacs:__Start(150)

Washington = AIRBOSS:New("CVN-72", "CVN-72 Abraham Lincoln")

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
Washington:Load()
Washington:SetAutoSave("C:/VNAO/Logs/trapsheets")
Washington:SetTrapSheet(TRAPSHEETLOCATION)
Washington:SetTACAN(72, "X", "LCN")
Washington:SetICLS(12, "LCN")
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





-- HeliAirbossMenus = AIRBOSS_HELI:New({ Washington})


