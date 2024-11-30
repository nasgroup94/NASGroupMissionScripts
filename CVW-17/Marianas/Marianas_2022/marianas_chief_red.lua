--#region Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('AIRWING')
-- BASE:TraceClass('SQUADRON')
-- BASE:TraceClass('AUFTRAG')
-- BASE:TraceClass('AIRBASE')

local function db(msg)
    log.write('ROLLN | airwings_red.lua', log.INFO, msg)
end
--#endregion Debugging

--#region AIRWING
--#region CV1143 Wing
AWCV1143 = AIRWING:New("CV1143", "CV-1143 Airwing")

--  Fighter Squadrons (J-11A)
CV1143_J11A = SQUADRON:New("SQDN_J11A", 10, "J-11A Fighter Sqdn")
    :AddMissionCapability({ AUFTRAG.Type.CAP,
        AUFTRAG.Type.ESCORT,
        AUFTRAG.Type.INTERCEPT,
        AUFTRAG.Type.PATROLZONE,
        AUFTRAG.Type.BOMBING}
    )
    :SetFuelLowRefuel(false)
    :SetDespawnAfterHolding(true)
AWCV1143:AddSquadron(CV1143_J11A)
AWCV1143:NewPayload(GROUP:FindByName("SQDN_J11A_L1"), 10, { AUFTRAG.Type.CAP,
    AUFTRAG.Type.ESCORT,
    AUFTRAG.Type.INTERCEPT,
    AUFTRAG.Type.PATROLZONE,
    AUFTRAG.Type.BOMBING}
)

CV1143_J11A_STRIKE = SQUADRON:New("CV1143_J11A_STRIKE", 10, "J-11A Strike Sqdn")
    :AddMissionCapability({ AUFTRAG.Type.STRIKE,
        AUFTRAG.Type.BOMBCARPET,
        AUFTRAG.Type.BOMBING,
        AUFTRAG.Type.BOMBRUNWAY,
        AUFTRAG.Type.PRECISIONBOMBING}
    )
    :SetFuelLowRefuel(false)
    :SetDespawnAfterHolding(true)
AWCV1143:AddSquadron(CV1143_J11A_STRIKE)
AWCV1143:NewPayload(GROUP:FindByName("CV1143_J11A_STRIKE_L1"), 10, { AUFTRAG.Type.STRIKE,
        AUFTRAG.Type.BOMBCARPET,
        AUFTRAG.Type.BOMBING,
        AUFTRAG.Type.BOMBRUNWAY,
        AUFTRAG.Type.PRECISIONBOMBING}
)

-- Awacs Squadrons (KJ2000)
CV1143_KJ2000 = SQUADRON:New("SQDN_KJ2000", 10, "KJ2000 Awacs Sqdn")
    :AddMissionCapability({ AUFTRAG.Type.AWACS })
    :SetTakeoffAir()
    :SetFuelLowRefuel(false)
    :SetDespawnAfterHolding(true)
AWCV1143:AddSquadron(CV1143_KJ2000)
AWCV1143:NewPayload(GROUP:FindByName("SQDN_KJ2000"), 4, { AUFTRAG.Type.AWACS })

-- Tanker Squadrions (IL-79M)
CV1143_IL78M = SQUADRON:New("SQDN_IL78M", 10, "IL-78M Tanker Sqdn")
    :AddMissionCapability({ AUFTRAG.Type.TANKER })
    :SetTakeoffAir()
    :SetFuelLowRefuel(false)
    :SetDespawnAfterHolding(true)
AWCV1143:AddSquadron(CV1143_IL78M)
AWCV1143:NewPayload(GROUP:FindByName("SQDN_IL78M"), 4, { AUFTRAG.Type.TANKER })
--#endregion CV1143 Wing

--#regionMissions
--#endregion Missions
--#endregion AIRWING

--#region OPS Zones
local opsZones = {
    {
        strategicZone = OPSZONE:New(ZONE_AIRBASE:New(AIRBASE.MarianaIslands.Saipan_Intl,6000),coalition.side.BLUE),
        conflictZone = ZONE_AIRBASE:New(AIRBASE.MarianaIslands.Saipan_Intl,6000)
    },
}
--#endregion OPS Zones

--#region FLEET
--#region Fleet zones
-- local fleetSpawnZones = {
--     ZONE:FindByName('Red Navy Spawn Zone 1'),
--     ZONE:FindByName('Red Navy Spawn Zone 2'),
--     ZONE:FindByName('Red Navy Spawn Zone 3'),
-- }
--#endregion Fleet zones
REDFLEET = FLEET:New('CV1143', 'Red Fleet')
-- REDFLEET:SetPortZone(UTILS.GetRandomTableElement(fleetSpawnZones, true))
REDFLEET:SetPortZone(ZONE:FindByName('Red Navy Spawn Zone 1'))

--#region Flotillas
FLT_SUB1 = FLOTILLA:New('PRC_SUB-1', 10, 'PRC Sub 1')
    :AddMissionCapability({AUFTRAG.Type.PATROLZONE})
REDFLEET:AddFlotilla(FLT_SUB1)

FLT_DEST1 = FLOTILLA:New('PRC_DESTROYER-1', 10, 'PRC Destroyer 1')
    :AddMissionCapability({AUFTRAG.Type.ARTY, AUFTRAG.Type.PATROLZONE, AUFTRAG.Type.BARRAGE})
REDFLEET:AddFlotilla(FLT_DEST1)

FLT_CORV1 = FLOTILLA:New('PRC_CORVETTE-1', 10, 'PRC Corvette 1')
    :AddMissionCapability({AUFTRAG.Type.ARTY, AUFTRAG.Type.PATROLZONE})
REDFLEET:AddFlotilla(FLT_CORV1)

FLT_FRIG1 = FLOTILLA:New('PRC_FRIGATE-1', 10, 'PRC Frigate 1')
    :AddMissionCapability({AUFTRAG.Type.ARTY, AUFTRAG.Type.PATROLZONE, AUFTRAG.Type.BARRAGE})
REDFLEET:AddFlotilla(FLT_FRIG1)

FLT_CRUS1 = FLOTILLA:New('PRC_CRUISER-1', 10, 'PRC Cruiser 1')
    :AddMissionCapability({AUFTRAG.Type.ARTY, AUFTRAG.Type.PATROLZONE, AUFTRAG.Type.BARRAGE})
REDFLEET:AddFlotilla(FLT_CRUS1)

--#endregion Flotillas
--#endregion FLEET

--#region Mission
local redNavyPatrolZones = {
    ZONE:FindByName('Red Navy Patrol Zone 1'),
    ZONE:FindByName('Red Navy Patrol Zone 2')
}

local redNavyFlotillas = {
    FLT_CRUS1,
    FLT_DEST1,
    FLT_CORV1,
    FLT_FRIG1
}

-- Testing
local auftragNavalTest = AUFTRAG:NewARTY(STATIC:FindByName('Static TV tower-1'):GetCoordinate(),
                                            20,
                                            100)
                                :SetMissionWaypointCoord(ZONE:FindByName('Test Arty Zone 1'):GetRandomCoordinate(nil, nil, 3))
                                :SetMissionRange(500)
function auftragNavalTest:OnAfterQueued(From, Event, To)
    -- db('auftragNavalTest queued.')
end

-- Patrols
local auftragRedNavyPatrol1 = AUFTRAG:NewPATROLZONE(UTILS.GetRandomTableElement(redNavyPatrolZones, true), 27)
                                    :AssignCohort(UTILS.GetRandomTableElement(redNavyFlotillas, true))
                                    :SetMissionRange(500)
									:SetROE(ENUMS.ROE.ReturnFire)

function auftragRedNavyPatrol1:OnAfterQueued(From, Event, To)
    -- db("auftragRedNavyPatrol1 queued.")
end

local auftragRedNavyPatrol2 = AUFTRAG:NewPATROLZONE(UTILS.GetRandomTableElement(redNavyPatrolZones, true), 27)
                                    :AssignCohort(UTILS.GetRandomTableElement(redNavyFlotillas, true))
                                    :SetMissionRange(500)
									:SetROE(ENUMS.ROE.ReturnFire)

function auftragRedNavyPatrol2:OnAfterQueued(From, Event, To)
    -- db("auftragRedNavyPatrol2 queued.")
end
--#endregion Missions
--#region CHIEF

--#region Chief Zones
local chiefZones = {
    awacs = {
        {
            zone = ZONE:FindByName("Red Awacs Zone 1"),
            alt = 28000,
            hdg = 180,
            leg = 100
        },
        {
            zone = ZONE:FindByName("Red Awacs Zone 2"),
            alt = 28000,
            hdg = 180,
            leg = 100
        }
    },
    tanker = {
        {
            zone = ZONE:FindByName("Red Tanker Zone 1"),
            alt = 22000,
            hdg = 195,
            leg = 70
        },
        {
            zone = ZONE:FindByName("Red Tanker Zone 2"),
            alt = 26000,
            hdg = 195,
            leg = 70
        },
    },
    cap = {
        {
            zone = ZONE:FindByName("Red Cap Zone 1"),
            alt = 29000,
            hdg = 195,
            leg = 70
        },
        {
            zone = ZONE:FindByName("Red Cap Zone 2"),
            alt = 33000,
            hdg = 195,
            leg = 70
        },
        {
            zone = ZONE:FindByName("Red Cap Zone 3"),
            alt = 32000,
            hdg = 195,
            leg = 70
        }
    },
}
--#endregion Chief Zones

local detectionGroupNames = {
    "CV1143_J11A",
}
local detectionSetGroup = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes(detectionGroupNames):FilterStart()

REDFOR_CHIEF = CHIEF:New(coalition.side.RED, detectionSetGroup, "Red Chief")
REDFOR_CHIEF:SetStrategy(CHIEF.Strategy.PASSIVE)

REDFOR_CHIEF:AddAirwing(AWCV1143)
REDFOR_CHIEF:AddFleet(REDFLEET)

-- Setup default zones
for _zoneType, _zone in pairs(chiefZones) do
    -- db('Zone type: ' .. _zoneType .. '\n' .. ROLLN.pprintBasicTable(_zone, 2))
    for _, _zoneData in pairs(_zone) do
        -- db('Zone Data:\n' .. ROLLN.pprintBasicTable(_zoneData, 2))
        if _zoneType == 'awacs' then
            REDFOR_CHIEF:AddAwacsZone(_zoneData.zone, _zoneData.alt, nil, _zoneData.hdg, _zoneData.leg)
        elseif _zoneType == 'tanker' then
            REDFOR_CHIEF:AddTankerZone(_zoneData.zone, _zoneData.alt, nil, _zoneData.hdg, _zoneData.leg)
        elseif _zoneType == 'cap' then
            REDFOR_CHIEF:AddCapZone(_zoneData.zone, _zoneData.alt, nil, _zoneData.hdg, _zoneData.leg)
        end
    end
end

for _, zone in pairs(opsZones) do
    REDFOR_CHIEF:AddStrategicZone(zone.strategicZone)
    REDFOR_CHIEF:AddConflictZone(zone.conflictZone)
end

-- Start chief!
REDFOR_CHIEF:Start()


-- local ZoneRedBorder=ZONE:New("Red Border"):DrawZone()
-- NATO_CHIEF:AddBorderZone(ZoneRedBorder)

REDFOR_CHIEF:AddMission(auftragNavalTest)
REDFOR_CHIEF:AddMission(auftragRedNavyPatrol1)
REDFOR_CHIEF:AddMission(auftragRedNavyPatrol2)

--#endregion CHIEF

--#region Red Sub Recon
RED_SUB_RECON = RNT:New('PRCSubRecon', {'Red Recon'}, {'PRC_SUB'})
    :InitDelayBetweenSpawns(600)
    :InitSpawnInRandomZones()
    :SetMaxGroupCount(3)
    :SetPathfindingOn(2500)
    -- :DebugOn()
    :Start()
--#endregion Red Sub Recon

----------------------------- Red Wing ---------------------------------------
AWRED = AIRWING:New("Warehouse Red Wing-1", "Red Wing")
AWRED:SetTakeoffAir()
AWRED:SetAirbase(AIRBASE:FindByName(AIRBASE.MarianaIslands.Pagan_Airstrip))


-- AWACS Squadrons (KJ-2000)
SQDN_KJ2000 = SQUADRON:New("SQDN_KJ2000", 4, "KJ-2000 AWACS Sqdn")
    :AddMissionCapability({AUFTRAG.Type.AWACS})

AWRED:AddSquadron(SQDN_KJ2000)
AWRED:NewPayload(GROUP:FindByName("SQDN_KJ2000"), 4, {AUFTRAG.Type.AWACS})


-- Patrol Squadrons (WingLoong-I)
SQDN_WLI = SQUADRON:New("SQDN_WLI", 4, "WingLoong-I Patrol Sqdn")
    :AddMissionCapability({AUFTRAG.Type.RECON, AUFTRAG.Type.ORBIT})

AWRED:AddSquadron(SQDN_WLI)
AWRED:NewPayload(GROUP:FindByName("SQDN_WLI"), 4, {AUFTRAG.Type.RECON, AUFTRAG.Type.ORBIT})


-- Bomber Squadrons (TU-95, TU-22, TU-160, H-6J)
SQDN_TU95 = SQUADRON:New("SQDN_TU95", 4, "TU-95 Bomb Sqdn")
    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                            AUFTRAG.Type.BOMBCARPET,
                            AUFTRAG.Type.BOMBRUNWAY,
                            AUFTRAG.Type.STRIKE})

AWRED:AddSquadron(SQDN_TU95)
AWRED:NewPayload(GROUP:FindByName("SQDN_TU95_L1"), 4, {AUFTRAG.Type.BOMBING,
                                                    AUFTRAG.Type.BOMBCARPET,
                                                    AUFTRAG.Type.BOMBRUNWAY,
                                                    AUFTRAG.Type.STRIKE})
                                                    
SQDN_TU22 = SQUADRON:New("SQDN_TU22", 4, "TU-22 Bomb Sqdn")
    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                            AUFTRAG.Type.BOMBCARPET,
                            AUFTRAG.Type.BOMBRUNWAY,
                            AUFTRAG.Type.STRIKE})

AWRED:AddSquadron(SQDN_TU22)
AWRED:NewPayload(GROUP:FindByName("SQDN_TU22_L1"), 4, {AUFTRAG.Type.BOMBING,
                                                        AUFTRAG.Type.BOMBCARPET,
                                                        AUFTRAG.Type.BOMBRUNWAY,
                                                        AUFTRAG.Type.STRIKE})

SQDN_TU160 = SQUADRON:New("SQDN_TU160", 4, "TU-160 Bomb Sqdn")
    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                            AUFTRAG.Type.BOMBCARPET,
                            AUFTRAG.Type.BOMBRUNWAY,
                            AUFTRAG.Type.STRIKE})

AWRED:AddSquadron(SQDN_TU160)
AWRED:NewPayload(GROUP:FindByName("SQDN_TU160_L1"), 4, {AUFTRAG.Type.BOMBING,
                                                        AUFTRAG.Type.BOMBCARPET,
                                                        AUFTRAG.Type.BOMBRUNWAY,
                                                        AUFTRAG.Type.STRIKE})
--
SQDN_H6J = SQUADRON:New("SQDN_H6J", 4, "H-6J Bomb Sqdn")
    :AddMissionCapability({AUFTRAG.Type.BOMBING,
                            AUFTRAG.Type.BOMBCARPET,
                            AUFTRAG.Type.BOMBRUNWAY,
                            AUFTRAG.Type.STRIKE})

AWRED:AddSquadron(SQDN_H6J)
AWRED:NewPayload(GROUP:FindByName("SQDN_H6J_L1"), 4, {AUFTRAG.Type.BOMBING,
                                                        AUFTRAG.Type.BOMBCARPET,
                                                        AUFTRAG.Type.BOMBRUNWAY,
                                                        AUFTRAG.Type.STRIKE}) 
--
    
--  Fighter Squadrons (J-11A)
SQDN_J11A = SQUADRON:New("SQDN_J11A", 4, "J-11A Fighter Sqdn")
    :AddMissionCapability({AUFTRAG.Type.CAP,
                            AUFTRAG.Type.ESCORT,
                            AUFTRAG.Type.INTERCEPT,
                            AUFTRAG.Type.PATROLZONE})

AWRED:AddSquadron(SQDN_J11A)
AWRED:NewPayload(GROUP:FindByName("SQDN_J11A_L1-1"), 4, {AUFTRAG.Type.CAP,
                                                        AUFTRAG.Type.ESCORT,
                                                        AUFTRAG.Type.INTERCEPT,
                                                        AUFTRAG.Type.PATROLZONE})

-- Start the Airwing!
AWRED:Start()

-- Red Wing Mission

