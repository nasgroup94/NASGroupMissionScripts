--#region Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(1)
-- BASE:TraceClass('AIRWING')
-- BASE:TraceClass('SQUADRON')
-- BASE:TraceClass('AIRBASE')
-- BASE:TraceClass('AUFTRAG')
-- BASE:TraceClass('MARKEROPS_BASE')
-- BASE:TraceClass('COMMANDER')

local function db(msg)
    log.write('ROLLN | airwings_blue.lua', log.INFO, msg)
end
--#endregion Debugging

--#region ZONES -------------------------------------------------------
-- Logistic Zones
local CodZone1 = {
    zone = ZONE:FindByName("Cod Zone 1"),
    hdg  = 360,
    leg  = 150
}

-- Patrol Zones
local P8PatrolZone1 = {
    zone = ZONE:FindByName("P8 Patrol Zone 1"),
    hdg  = 360,
    leg  = 150
}

local P8PatrolZone3 = {
    zone = ZONE:FindByName("P8 Patrol Zone 3"),
    hdg  = 360,
    leg  = 150
}

local ProwlerPatrolZone1 = {
    zone = ZONE:FindByName("Prowler Patrol Zone 1"),
    hdg  = 360,
    leg  = 150
}

local BlueCapZone1 = {
    zone = ZONE:FindByName("Blue Cap Zone 1"),
    hdg = 12,
    leg = 70,
}

local BlueCapZone2 = {
    zone = ZONE:FindByName("Blue Cap Zone 2"),
    hdg = 195,
    leg = 70,
}

local BlueCapZone3 = {
    zone = ZONE:FindByName("Blue Cap Zone 3"),
    hdg = 12,
    leg = 70,
}
-- Awacs Zones
local AwacsZones = {
    {
        zone = ZONE:FindByName("AWACS Blue Zone 1"),
        alt = 30000,
        spd = 300,
        hdg  = 01,
        leg  = 180
    },
}

-- Tanker Zones
local aarLuxor = {
    zone = ZONE:New("AAR Luxor"),
    hdg     = 237,
    leg     = 50,
}

local aarRio = {
    zone = ZONE:New("AAR Rio"),
    hdg     = 128,
    leg     = 50,
}

local aarMirage = {
    zone = ZONE:New("AAR Mirage"),
    hdg     = 0,
    leg     = 50,
}
--#endregion ZONES

--#region AIRWINGS -----------------------------------------------------------------

--#region AIRWING CVN73 -------------------------------------------------------------
AWCVN73 = AIRWING:New("CVN73", "CVW-7 Airwing")
-- AWCVN73:SetAirboss(Washington)

-- Fleet Logistics Support Squadron 40 (VRC-40)
CVN73_VRC40 = SQUADRON:New("CVN73_VRC40", 4, "Fleet Logistics Support Squadron 40")
    :AddMissionCapability({AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Aircraft.Enfield, 8)
    :SetFuelLowThreshold(0.3)

-- AWCVN73:AddSquadron(CVN73_VRC40)
-- AWCVN73:NewPayload(GROUP:FindByName("CVN73_VRC40"), 4, {AUFTRAG.Type.ORBIT})


CVN73_VAQ140 = SQUADRON:New("CVN73_VAQ140", 4, "VAQ-140 Patriots")
    :AddMissionCapability({AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Aircraft.Ascot, 1)
    :SetFuelLowThreshold(0.3)

-- AWCVN73:AddSquadron(CVN73_VAQ140)
-- AWCVN73:NewPayload(GROUP:FindByName("CVN73_VAQ140_L1"), 4, {AUFTRAG.Type.ORBIT})


CVN73_VFA103 = SQUADRON:New("CVN73_VFA103", 4, "VFA-103 Jolly Rogers")
    :AddMissionCapability({AUFTRAG.Type.CAP, AUFTRAG.Type.ESCORT, AUFTRAG.Type.INTERCEPT})
    :SetCallsign(CALLSIGN.Aircraft.Colt, 1)
    :SetFuelLowRefuel(true)
    :SetFuelLowThreshold(0.3)

-- AWCVN73:AddSquadron(CVN73_VFA103)
-- AWCVN73:NewPayload(GROUP:FindByName("CVN73_VFA103_L1"), 4, {AUFTRAG.Type.CAP, AUFTRAG.Type.ESCORT, AUFTRAG.Type.INTERCEPT})
-- AWCVN73:NewPayload(GROUP:FindByName("CVN73_VFA103_L2"), 4, {AUFTRAG.Type.ANTISHIP})
-- AWCVN73:NewPayload(GROUP:FindByName("CVN73_VFA103_L3"), 4, {AUFTRAG.Type.SEAD})

CVN73_ARCO3 = SQUADRON:New("CVN73_ARCO3", 6, "VS-21 Fighting Redtails")
    :AddMissionCapability({AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Tanker.Arco, 1)
    :SetFuelLowRefuel(true)
    :SetFuelLowThreshold(0.3)

AWCVN73:AddSquadron(CVN73_ARCO3)
AWCVN73:NewPayload(GROUP:FindByName("CVN73_ARCO3"), 6, {AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
--#endregion AIRWING CVN73

--#region AIRWING 36th Wing Andersen AFB ------------------------------------------
-- Squadron Parking IDs
local andersenSquadronParkingIDs = {
    Fighter = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,48,69,70,71,72,73,74,75,76,192,193,194},
    AirControl = {138,139,140,141,142,143,144,145,146,154,155,156},
    Patrol = {134,135,136,137,147,148,149,150,151,152,153},
    Tanker = {95,97,98,99,100,101,102,103,104,105,106,107,108,125,126,127,128,129,130,131,132,133},
    Airlift = {40,41,42,43,44,45,46,47,59,60,61,62,63,64,65,66,67,68},
    Bomber = {77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,96,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,195,196,197},
    Helo = {154,155,156,157,158,159,160,161,162,163,164,165,166},
}

AW36 = AIRWING:New("Warehouse Andersen AFB", "36th Wing")

-- AWACS Squadrons (961st)
SQDN_AACS961 = SQUADRON:New("SQDN_AACS961", 4, "961st Airborne Air Control Sqdn")
    :AddMissionCapability({AUFTRAG.Type.AWACS})
    :SetCallsign(CALLSIGN.Aircraft.Overlord, 5)
    :SetFuelLowThreshold(0.3)
    :SetRadio(262, radio.modulation.AM)

SQDN_AACS961:SetParkingIDs(andersenSquadronParkingIDs.AirControl)

AW36:AddSquadron(SQDN_AACS961)
AW36:NewPayload(GROUP:FindByName("SQDN_AACS961"), 4, {AUFTRAG.Type.AWACS})

-- Fleet Logistics Support Squadron 40 (VRC-40)
SQDN_VRC40 = SQUADRON:New("SQDN_VRC40", 4, "Fleet Logistics Support Squadron 40")
    :AddMissionCapability({AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Aircraft.Enfield, 9)
    :SetParkingIDs(andersenSquadronParkingIDs.Airlift)
    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_VRC40)
AW36:NewPayload(GROUP:FindByName("SQDN_VRC40"), 4, {AUFTRAG.Type.ORBIT})

-- [[
-- Patrol Squadrons (VP-8)
SQDN_PSVP8 = SQUADRON:New("SQDN_PSVP8", 4, "Patrol Sqdn 8")
    :AddMissionCapability({AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Aircraft.Chevy, 4)
    :SetParkingIDs(andersenSquadronParkingIDs.Patrol)
    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_PSVP8)
AW36:NewPayload(GROUP:FindByName("SQDN_PSVP8"), 4, {AUFTRAG.Type.ORBIT})


-- Tanker Squadrons (909th)
SQDN_ARS909MPRS = SQUADRON:New("SQDN_ARS909MPRS", 10, "909th Air Refueling Sqdn MPRS")
    :AddMissionCapability({AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
    :SetParkingIDs(andersenSquadronParkingIDs.Tanker)
    :SetFuelLowThreshold(0.5)

AW36:AddSquadron(SQDN_ARS909MPRS)
AW36:NewPayload(GROUP:FindByName("SQDN_ARS909MPRS"), 10, {AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})

SQDN_ARS909 = SQUADRON:New("SQDN_ARS909", 10, "909th Air Refueling Sqdn")
    :AddMissionCapability({AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
    :SetParkingIDs(andersenSquadronParkingIDs.Tanker)
    :SetFuelLowThreshold(0.5)

AW36:AddSquadron(SQDN_ARS909)
AW36:NewPayload(GROUP:FindByName("SQDN_ARS909"), 10, {AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})


-- Helo Squadrons (HSC-25)
-- SQDN_HCS25 = SQUADRON:New("SQDN_HCS25", 4, "HSC-25 Helicopter Sea Combat Sqdn")
--     :AddMissionCapability({AUFTRAG.Type.ORBIT,
--                             AUFTRAG.Type.RECON,
--                             AUFTRAG.Type.TROOPTRANSPORT,
--                             AUFTRAG.Type.PATROLZONE,
--                             AUFTRAG.Type.OPSTRANSPORT})
--     :SetParkingIDs(andersenSquadronParkingIDs.Helo)
--     :SetFuelLowThreshold(0.3)

-- AW36:AddSquadron(SQDN_HCS25)
-- AW36:NewPayload(GROUP:FindByName("SQDN_HCS25"), 4, {AUFTRAG.Type.ORBIT,
--                                                     AUFTRAG.Type.RECON,
--                                                     AUFTRAG.Type.TROOPTRANSPORT,
--                                                     AUFTRAG.Type.PATROLZONE,
--                                                     AUFTRAG.Type.OPSTRANSPORT})


-- Airlift Squadrons (36th, 22nd, 4th)
SQDN_AS36 = SQUADRON:New("SQDN_AS36", 3, "36th Airlift Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT,
                                            AUFTRAG.Type.OPSTRANSPORT,
                                            AUFTRAG.Type.AMMOSUPPLY,
                                            AUFTRAG.Type.FUELSUPPLY})
                    :SetCallsign(CALLSIGN.Aircraft.Cargo, 1)
                    :SetParkingIDs(andersenSquadronParkingIDs.Airlift)
                    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_AS36)
AW36:NewPayload(GROUP:FindByName("SQDN_AS36"), 3, {AUFTRAG.Type.TROOPTRANSPORT,
                                                    AUFTRAG.Type.OPSTRANSPORT,
                                                    AUFTRAG.Type.AMMOSUPPLY,
                                                    AUFTRAG.Type.FUELSUPPLY})

SQDN_AS22 = SQUADRON:New("SQDN_AS22", 2, "22nd Airlift Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT,
                                            AUFTRAG.Type.OPSTRANSPORT,
                                            AUFTRAG.Type.AMMOSUPPLY,
                                            AUFTRAG.Type.FUELSUPPLY})
                    :SetCallsign(CALLSIGN.Aircraft.Cargo, 2)
                    :SetParkingIDs(andersenSquadronParkingIDs.Airlift)
                    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_AS22)
AW36:NewPayload(GROUP:FindByName("SQDN_AS22"), 3, {AUFTRAG.Type.TROOPTRANSPORT,
                                                    AUFTRAG.Type.OPSTRANSPORT,
                                                    AUFTRAG.Type.AMMOSUPPLY,
                                                    AUFTRAG.Type.FUELSUPPLY})

SQDN_AS4 = SQUADRON:New("SQDN_AS4", 2, "4th Airlift Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT,
                                            AUFTRAG.Type.OPSTRANSPORT,
                                            AUFTRAG.Type.AMMOSUPPLY,
                                            AUFTRAG.Type.FUELSUPPLY})
                    :SetCallsign(CALLSIGN.Aircraft.Cargo, 3)
                    :SetParkingIDs(andersenSquadronParkingIDs.Airlift)
                    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_AS4)
AW36:NewPayload(GROUP:FindByName("SQDN_AS4"), 3, {AUFTRAG.Type.TROOPTRANSPORT,
                                                    AUFTRAG.Type.OPSTRANSPORT,
                                                    AUFTRAG.Type.AMMOSUPPLY,
                                                    AUFTRAG.Type.FUELSUPPLY})


-- Bomber Squadrons (28th, 13th)
SQDN_BS28 = SQUADRON:New("SQDN_BS28", 2, "28th Bomb Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                                            AUFTRAG.Type.BOMBCARPET,
                                            AUFTRAG.Type.BOMBRUNWAY,
                                            AUFTRAG.Type.STRIKE})
                    :SetCallsign(CALLSIGN.Aircraft.Bone, 1)
                    :SetParkingIDs(andersenSquadronParkingIDs.Bomber)
                    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_BS28)
AW36:NewPayload(GROUP:FindByName("SQDN_BS28"), 4, {AUFTRAG.Type.BOMBING,
                                                    AUFTRAG.Type.BOMBCARPET,
                                                    AUFTRAG.Type.BOMBRUNWAY,
                                                    AUFTRAG.Type.STRIKE})

SQDN_BS13 = SQUADRON:New("SQDN_BS13", 2, "13th Bomb Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                                            AUFTRAG.Type.BOMBCARPET,
                                            AUFTRAG.Type.BOMBRUNWAY,
                                            AUFTRAG.Type.STRIKE})
                    :SetCallsign(CALLSIGN.Aircraft.Colt, 1)
                    :SetParkingIDs(andersenSquadronParkingIDs.Bomber)
                    :SetFuelLowThreshold(0.3)

AW36:AddSquadron(SQDN_BS13)
AW36:NewPayload(GROUP:FindByName("SQDN_BS13"), 4, {AUFTRAG.Type.BOMBING,
                                                    AUFTRAG.Type.BOMBCARPET,
                                                    AUFTRAG.Type.BOMBRUNWAY,
                                                    AUFTRAG.Type.STRIKE})


-- Fighter Squadrons (44th, 13th, 14th)
SQDN_FS44 = SQUADRON:New("SQDN_FS44", 2, "44th Fighter Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.CAP,
                                            AUFTRAG.Type.ESCORT,
                                            AUFTRAG.Type.INTERCEPT,
                                            AUFTRAG.Type.ORBIT,
                                            AUFTRAG.Type.PATROLZONE,
                                            AUFTRAG.Type.PATROLZONE})
                    :SetCallsign(CALLSIGN.Aircraft.Dodge, 1)
                    :SetParkingIDs(andersenSquadronParkingIDs.Fighter)
                    :SetFuelLowRefuel(true)
                    :SetFuelLowThreshold(0.5)

-- AW36:AddSquadron(SQDN_FS44)
-- AW36:NewPayload(GROUP:FindByName("SQDN_FS44_L1"), 8, {AUFTRAG.Type.CAP,
--                                                     AUFTRAG.Type.ESCORT,
--                                                     AUFTRAG.Type.INTERCEPT,
--                                                     AUFTRAG.Type.ORBIT,
--                                                     AUFTRAG.Type.PATROLZONE})

SQDN_FS13 = SQUADRON:New("SQDN_FS13", 2, "13th Fighter Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.CAP,
                                            AUFTRAG.Type.ESCORT,
                                            AUFTRAG.Type.INTERCEPT,
                                            AUFTRAG.Type.ORBIT,
                                            AUFTRAG.Type.PATROLZONE})
                    :SetCallsign(CALLSIGN.Aircraft.Dodge, 2)
                    :SetParkingIDs(andersenSquadronParkingIDs.Fighter)
                    :SetFuelLowRefuel(true)
                    :SetFuelLowThreshold(0.5)

-- AW36:AddSquadron(SQDN_FS13)
-- AW36:NewPayload(GROUP:FindByName("SQDN_FS13_L1"), 8, {AUFTRAG.Type.CAP,
--                                                     AUFTRAG.Type.ESCORT,
--                                                     AUFTRAG.Type.INTERCEPT,
--                                                     AUFTRAG.Type.ORBIT,
--                                                     AUFTRAG.Type.PATROLZONE})

SQDN_FS14 = SQUADRON:New("SQDN_FS14", 2, "14th Fighter Sqdn")
                    :AddMissionCapability({AUFTRAG.Type.CAP,
                                            AUFTRAG.Type.ESCORT,
                                            AUFTRAG.Type.INTERCEPT,
                                            AUFTRAG.Type.ORBIT,
                                            AUFTRAG.Type.PATROLZONE})
                    :SetCallsign(CALLSIGN.Aircraft.Dodge, 3)
                    :SetParkingIDs(andersenSquadronParkingIDs.Fighter)
                    :SetFuelLowRefuel(true)
                    :SetFuelLowThreshold(0.5)

-- AW36:AddSquadron(SQDN_FS14)
-- AW36:NewPayload(GROUP:FindByName("SQDN_FS14_L1"), 8, {AUFTRAG.Type.CAP,
--                                                     AUFTRAG.Type.ESCORT,
--                                                     AUFTRAG.Type.INTERCEPT,
--                                                     AUFTRAG.Type.ORBIT,
--                                                     AUFTRAG.Type.PATROLZONE})


-- Rescue Squadrons (33rd)
-- SQDN_RS33 = SQUADRON:New("SQDN_RS33", 2, "33rd Rescue Sqdn")
--                     :AddMissionCapability({})
--                     :SetCallsign(CALLSIGN.Aircraft.Enfield, 1)
--                     :SetParkingIDs(andersenSquadronParkingIDs.Helo)
--                     :SetFuelLowRefuel(true)
--                     :SetFuelLowThreshold(0.3)

-- AW36:AddSquadron(SQDN_RS33)
-- AW36:NewPayload(GROUP:FindByName("SQDN_RS33"), 1, {})
--#endregion AIRWING 36th Wing Andersen AFB



--#region DEFAULT MISSIONS ----------------------------------------------------

--#region Logistics
local auftragCodSea = AUFTRAG:NewORBIT(CodZone1.zone:GetCoordinate(), 12000, 240)
    :SetTime(300)
    :SetRepeat(99)
    :SetMissionRange(500)
    :AssignSquadrons({CVN73_VRC40})

function auftragCodSea:OnBeforeStarted(From, Event, To)
    local _opsGroup = self:GetOpsGroups()[1]

    if _opsGroup then
        _opsGroup:SwitchCallsign(CALLSIGN.Aircraft.Enfield, 9)
    end
end

function auftragCodSea:OnAfterExecuting(FROM, Event, TO)
    self:Cancel()
end

function auftragCodSea:OnAfterDone(FROM, Event, TO)
    local _opsGroup = self:GetOpsGroups()[1]

    if _opsGroup then
        _opsGroup:RTB()
    end
end

local auftragCodLand = AUFTRAG:NewORBIT(CodZone1.zone:GetCoordinate(), 12000, 240)
    :SetTime(300)
    :SetRepeat(99)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_VRC40})

function auftragCodLand:OnBeforeStarted(From, Event, To)
    local _opsGroup = self:GetOpsGroups()[1]

    if _opsGroup then
        _opsGroup:SwitchCallsign(CALLSIGN.Aircraft.Enfield, 8)
    end
end

function auftragCodLand:OnAfterExecuting(FROM, Event, TO)
    self:Cancel()
end

function auftragCodLand:OnAfterDone(FROM, Event, TO)
    local _opsGroup = self:GetOpsGroups()[1]

    if _opsGroup then
        _opsGroup:RTB()
    end
end
--#endregion Logistics

--#region Patrols
local auftragProwlerEscort = {}
local auftragProwler = AUFTRAG:NewORBIT(ProwlerPatrolZone1.zone:GetCoordinate(), 12000, 300, 360, 140)
    :SetTime(5400) -- starts in 1.5hrs
    :SetRepeat(99)
    :SetMissionRange(500)
    :AssignSquadrons({CVN73_VAQ140})
    :SetRequiredEscorts(1, 1, AUFTRAG.Type.ESCORT)

-- function auftragProwler:OnAfterStarted(From,Event,To)
--     auftragProwlerEscort = AUFTRAG:NewESCORT(self:GetOpsGroups()[1],{x=-1000, y=UTILS.FeetToMeters(5000), z=-2000}, 75, {"Air"})
--                         :SetMissionRange(500)
--                         :SetTime(240)

--    NATO_CHIEF:AddMission(auftragProwlerEscort)
-- end

local auftragP8Patrol1 = AUFTRAG:NewORBIT(P8PatrolZone1.zone:GetCoordinate(), 2500, 360, P8PatrolZone1.hdg, P8PatrolZone1.leg)
    :SetTime(1)
    :SetRepeat(99)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_PSVP8})
    -- :SetRequiredEscorts(1, 1, AUFTRAG.Type.ESCORT)

local auftragP8Patrol3 = AUFTRAG:NewORBIT(P8PatrolZone3.zone:GetCoordinate(), 2500, 360, P8PatrolZone1.hdg, P8PatrolZone1.leg)
    :SetTime(1)
    :SetRepeat(99)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_PSVP8})
    -- :SetRequiredEscorts(1, 1, AUFTRAG.Type.ESCORT)

-- local auftragPatrolEagle1 = AUFTRAG:NewCAP(BlueCapZone1.zone, 28000, 350, BlueCapZone1.zone:GetCoordinate(), BlueCapZone1.hdg, BlueCapZone1.leg, {"Air"})
--     :SetTime(1)
--     :SetRepeat(99)
--     :AssignSquadrons({SQDN_FS44})
--     :SetMissionRange(500)

-- local auftragPatrolEagle2 = AUFTRAG:NewCAP(BlueCapZone2.zone, 28000, 350, BlueCapZone2.zone:GetCoordinate(), BlueCapZone2.hdg, BlueCapZone2.leg, {"Air"})
--     :SetTime(10800) -- starts in 3 hrs
--     :SetRepeat(99)
--     :AssignSquadrons({SQDN_FS44})
--     :SetMissionRange(500)
--#endregion Patrols

--#region AWACS
-- local auftragAwacsWest = AUFTRAG:NewAWACS(AwacsBlueZone1.zone:GetCoordinate(), 31000, 360, AwacsBlueZone1.hdg, AwacsBlueZone1.leg)
--     :SetTime(1)
--     :SetRepeat(99)
--     :SetMissionRange(500)
--     :SetTACAN(62, "OL5")
--     :SetRadio(262)
--#endregion AWACS

--#region Tanking

-- function AW36:OnAfterFlightOnMission(From, Event, To, Flightgroup, Mission)
--     if Mission:GetType() == AUFTRAG.Type.TANKER and Flightgroup:GetSquadron() == SQDN_ARS909MPRS then
--         db('OnAfterFlightOnMission')
--         local tanker = Flightgroup:GetGroup():GetUnit(1)
--         db(tanker:GetName())
--         tanker:CommandSetCallsign(2,6,5)
--     end
-- end

local function tankerSetup(auftrag, callSignName, callsignID, tacanChannel, tacanIdent, radioFreq)
    function auftrag:OnAfterStarted(From, Event, To)
		self:T(self.lid .. 'ROLLN | OnAfterStarted')

		local _opsGroup = self:GetOpsGroups()[1]
        
		if _opsGroup then
            local _group = _opsGroup:GetGroup()
            if _group then
                _group:SetTask({id='NoTask', params={}})
                _group:GetUnit(1):CommandSetCallsign(callSignName,callsignID,10)

                _opsGroup:TurnOffTACAN()
                _opsGroup:TurnOffRadio()
            end
		end
    end

	function auftrag:OnBeforeExecuting(From, Event, To)
		self:T(self.lid .. 'ROLLN | OnBeforeExecuting')
	
		local _opsGroup = self:GetOpsGroups()[1]
	
		if _opsGroup then
            local _group = _opsGroup:GetGroup()
            if _group then
                _opsGroup:PushTask({id = 'Tanker', params = {}})
                -- _group:GetUnit(1):CommandSetCallsign(callSignName,callsignID,10)
                _group:CommandSetFrequency(radioFreq,radio.modulation.AM,10)

                _opsGroup:SwitchTACAN(tacanChannel, tacanIdent)
            end
		end
	end
    
	function auftrag:OnAfterDone(From, Event, To)
		self:T(self.lid .. 'ROLLN | OnAfterDone')
	
		local _opsGroup = self:GetOpsGroups()[1]
	
		if _opsGroup then
            local _group = _opsGroup:GetGroup()
            if _group then
                _group:SetTask({id='NoTask', params={}})
                -- _group:GetUnit(1):CommandSetCallsign(callSignName,callsignID,10)

                _opsGroup:TurnOffTACAN()
                _opsGroup:TurnOffRadio()
                -- _opsGroup:RemoveMission()
                -- _opsGroup:RTB(AIRBASE:FindByName(AIRBASE.MarianaIslands.Andersen_AFB))
                -- self:Cancel()
            end
		end
	end
end


local auftragLuxorTkrMPRS = AUFTRAG:NewORBIT(aarLuxor.zone:GetCoordinate(), MISSION_TANKER_ALTS.Probe, 260, aarLuxor.hdg, aarLuxor.leg)
    :SetTime(1)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909MPRS})
    :SetName("Luxor MPRS")
    :SetTACAN(59, "TX1")
    :SetRadio(259)

function  auftragLuxorTkrMPRS:OnAfterScheduled(From, Event, To)
    db('OnAfterStarted()')
    tankerSetup(self, CALLSIGN.Tanker.Texaco, 1, 59, "TX1", 259)
end

auftragLuxorTkrMPRS:AssignSquadrons({SQDN_ARS909MPRS})

local auftragRioTkrMPRS = AUFTRAG:NewORBIT(aarRio.zone:GetCoordinate(), MISSION_TANKER_ALTS.Probe, 260, aarRio.hdg, aarRio.leg)
    :SetTime(20)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909MPRS})
    :SetName("Rio MPRS")
    :SetTACAN(63, "TX2")
    :SetRadio(263)

function  auftragRioTkrMPRS:OnAfterScheduled(From, Event, To)
    tankerSetup(self, CALLSIGN.Tanker.Texaco, 2, 63, "TX2", 263)
end

local auftragMirageTkrMPRS = AUFTRAG:NewORBIT(aarMirage.zone:GetCoordinate(), MISSION_TANKER_ALTS.Probe, 260, aarMirage.hdg, aarMirage.leg)
    :SetTime(40)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909MPRS})
    :SetName("Mirage MPRS")
    :SetTACAN(57, "TX3")
    :SetRadio(257)

function  auftragMirageTkrMPRS:OnAfterScheduled(From, Event, To)
    tankerSetup(self, CALLSIGN.Tanker.Texaco, 3, 57, "TX3", 257)
end

local auftragLuxorTkr = AUFTRAG:NewORBIT(aarLuxor.zone:GetCoordinate(), MISSION_TANKER_ALTS.Boom, 260, aarLuxor.hdg, aarLuxor.leg)
    :SetTime(600)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909})
    :SetName("Luxor")
    :SetTACAN(61, "SH1")
    :SetRadio(261)

function  auftragLuxorTkr:OnAfterScheduled(From, Event, To)
    tankerSetup(self, CALLSIGN.Tanker.Shell, 1, 61, "SH1", 261)
end

local auftragRioTkr = AUFTRAG:NewORBIT(aarRio.zone:GetCoordinate(), MISSION_TANKER_ALTS.Boom, 260, aarRio.hdg, aarRio.leg)
    :SetTime(20)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909})
    :SetName("Rio")
    :SetTACAN(67, "SH2")
    :SetRadio(267)

function  auftragRioTkr:OnAfterScheduled(From, Event, To)
    tankerSetup(self, CALLSIGN.Tanker.Shell, 2, 67, "SH2", 267)
end

local auftragMirageTkr = AUFTRAG:NewORBIT(aarMirage.zone:GetCoordinate(), MISSION_TANKER_ALTS.Boom, 260, aarMirage.hdg, aarMirage.leg, 0)
    :SetTime(640)
    :SetRepeat(5)
    :SetMissionRange(500)
    :AssignSquadrons({SQDN_ARS909})
    :SetName("Mirage")
    :SetTACAN(70, "SH3")
    :SetRadio(270)

function  auftragMirageTkr:OnAfterScheduled(From, Event, To)
    tankerSetup(self, CALLSIGN.Tanker.Shell, 3, 70, "SH3", 270)
end
--#endregion Tanking

--#endregion DEFAULT MISSIONS

--#endregion AIRWINGS

--#region FLEET


--#region Fleet missions
USNTrainingGroup = OPSGROUP:New("USN Training")

function USNTrainingGroup:OnAfterStart(From, Event, To)
    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint('USN Training-1', 1)
end

function USNTrainingGroup:OnAfterPassingWaypoint(From, Event, To, n)
    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint('USN Training-1', n)
end

-- USNSacramentoGroup = OPSGROUP:New("SACRAMENTO-1")

-- function USNSacramentoGroup:OnAfterStart(From, Event, To)
--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint('SACRAMENTO-1-1', 1)
-- end

-- function USNSacramentoGroup:OnAfterPassingWaypoint(From, Event, To, n)
--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint('SACRAMENTO-1-1', n)
-- end
--#endregion FLEET

--#region CHIEF ----------------------------------------------------------------
local detectionSquadronNames = {
    -- "961st Airborne Air Control Sqdn",
    -- "VP-8 Patrol Squadron",
    -- "VAQ-140 Patriots",
    -- "HSC-25 Helicopter Sea Combat Sqdn",
    -- "Wizard",
    -- "Overlord",
}
local BlueDetectionSetGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes(detectionSquadronNames):FilterStart()

NATO_CHIEF = CHIEF:New(coalition.side.BLUE, BlueDetectionSetGroup, "Blue Chief")
NATO_CHIEF:SetStrategy(CHIEF.Strategy.DEFENSIVE)

local ZoneBlueBorder=ZONE:New("Blue Border")--:DrawZone()
NATO_CHIEF:AddBorderZone(ZoneBlueBorder)


NATO_CHIEF:AddAirwing(AWCVN73)
NATO_CHIEF:AddAirwing(AW36)


for _, zone in pairs(AwacsZones) do
    NATO_CHIEF:AddAwacsZone(zone.zone, zone.alt, zone.spd, zone.hdg, zone.leg)
end

-- Start chief!
NATO_CHIEF:Start()

-- Submit Missions
-- NATO_CHIEF:AddMission(auftragAwacsWest) -- Added a patrol zone to chief
NATO_CHIEF:AddMission(auftragCodSea)
NATO_CHIEF:AddMission(auftragCodLand)

-- NATO_CHIEF:AddMission(auftragPatrolEagle1)
-- NATO_CHIEF:AddMission(auftragPatrolEagle2)
-- NATO_CHIEF:AddMission(auftragProwler)
NATO_CHIEF:AddMission(auftragP8Patrol1)
NATO_CHIEF:AddMission(auftragP8Patrol3)

NATO_CHIEF:AddMission(auftragLuxorTkrMPRS)
NATO_CHIEF:AddMission(auftragRioTkrMPRS)
NATO_CHIEF:AddMission(auftragMirageTkrMPRS)
NATO_CHIEF:AddMission(auftragLuxorTkr)
NATO_CHIEF:AddMission(auftragRioTkr)
NATO_CHIEF:AddMission(auftragMirageTkr)
--#endregion CHIEF

