local function randomchoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    
    -- math.randomseed( os.time() )
    math.random(); math.random(); math.random()
    index = keys[math.random(1, #keys)]
    return t[index]
end

-- Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(1)
-- BASE:TraceClass('TIMER')
-- BASE:TraceClass('AIRWING')

Bombing_missions = {}

local dmz_zones = {
    ZONE:FindByName("dmz zone 1"),
    ZONE:FindByName("dmz zone 2"),
    ZONE:FindByName("dmz zone 3"),
    ZONE:FindByName("dmz zone 4"),
    ZONE:FindByName("dmz zone 5"),
    ZONE:FindByName("dmz zone 6")
}

-- Create the AirWing
Red_Bomber_Airwing = AIRWING:New("Anapa Warehouse", "Red Bomber Airwing")
TU95_Bombers=SQUADRON:New("bomber-tu95", 1, "TU95 Bombers")
TU142_Bombers=SQUADRON:New("bomber-tu142", 1, "TU142 Bombers")
TU160_Bombers=SQUADRON:New("bomber-tu160", 1, "TU160 Bombers")
TU22_Bombers=SQUADRON:New("bomber-tu22", 1, "TU22 Bombers")
TU95_Bombers:AddMissionCapability({AUFTRAG.Type.ORBIT})
TU142_Bombers:AddMissionCapability({AUFTRAG.Type.ORBIT})
TU160_Bombers:AddMissionCapability({AUFTRAG.Type.ORBIT})
TU22_Bombers:AddMissionCapability({AUFTRAG.Type.ORBIT})
TU95_Bombers:SetTakeoffHot()
TU142_Bombers:SetTakeoffHot()
TU160_Bombers:SetTakeoffHot()
TU22_Bombers:SetTakeoffHot()
Red_Bomber_Airwing:AddSquadron(TU95_Bombers)
Red_Bomber_Airwing:AddSquadron(TU142_Bombers)
Red_Bomber_Airwing:AddSquadron(TU160_Bombers)
Red_Bomber_Airwing:AddSquadron(TU22_Bombers)
Red_Bomber_Airwing:NewPayload(UNIT:FindByName('bomber-tu95-1'), 4, {AUFTRAG.Type.ORBIT}, 100)
Red_Bomber_Airwing:NewPayload(UNIT:FindByName('bomber-tu142-1'), 4, {AUFTRAG.Type.ORBIT}, 100)
Red_Bomber_Airwing:NewPayload(UNIT:FindByName('bomber-tu160-1'), 4, {AUFTRAG.Type.ORBIT}, 100)
Red_Bomber_Airwing:NewPayload(UNIT:FindByName('bomber-tu22-1'), 4, {AUFTRAG.Type.ORBIT}, 100)
Red_Bomber_Airwing:Start()

function Check_In_DMZ(mission)
    for _, missionObj in pairs(Bombing_missions) do
        if missionObj ~= nil then
            -- trigger.action.outText(missionObj.mission.name .. " - Checking DMZ...", 5)
            local mission_group = missionObj.mission:GetOpsGroups()
            if mission_group[1] ~= nil then
                -- trigger.action.outText("Checking group: " .. mission_group[1].groupname, 5)
                local mission_unit = mission_group[1]:GetUnit()
                local mission_group_coord = mission_unit:GetCoordinate()

                for _, dmz_zone in pairs(dmz_zones) do
                    if dmz_zone:IsCoordinateInZone(mission_group_coord) then
                        math.random(); math.random(); math.random()
                        local choice = math.random(1, 4)
                        -- trigger.action.outText(missionObj.mission.name .. " - Choice was: " .. tostring(choice), 240)
                        if choice <= 3 then
                            missionObj.mission:Cancel()
                            missionObj.mission_timer:Stop()
                            TIMER:New(RemoveMission, missionObj):Start(60)
                        else
                            -- Set mil RAT traffic to FIRE
                        end
                    end
                end
            end
        end
    end
end

function BomberIntercept()
    local target_vec3 = ZONE:FindByName("DMZ Bomber Dest Zone"):GetRandomPointVec3()
    local target_coord = COORDINATE:NewFromVec3(target_vec3):SetAltitude(30000)
    local bombing_mission = AUFTRAG:NewORBIT(target_coord)
    bombing_mission:SetVerbosity(10)
    bombing_mission:SetMissionRange(400)
    bombing_mission:SetMissionSpeed(550)
    Bombing_missions[bombing_mission.name] = {
        mission = bombing_mission,
        mission_timer = TIMER:New(Check_In_DMZ, bombing_mission):Start(240, 30)
    }
    Red_Bomber_Airwing:AddMission(bombing_mission)
    MESSAGE:New("Spawning 1 red bomber.", 15, Info):ToAll()
end

MENU_MISSION_COMMAND:New("Red / Unknown Intercept", Bombers, BomberIntercept)

function RemoveMission(missionObj)
    Bombing_missions[missionObj.mission.name] = nil
end
