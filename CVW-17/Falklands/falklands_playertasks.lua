-- -- Debuging
--[[
BASE:TraceOnOff(true)
BASE:TraceLevel(1)
BASE:TraceClass('PLAYERTASKCONTROLLER')
--]]
local function db(msg)
    log.write('ROLLN', log.INFO, msg)
end

local function pprintBasicTable(tbl, indent, filename)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        else
            toprint = toprint .. "[\"" .. k .. "\"] = "
        end
        --   elseif (type(k) == "string") then
        --     toprint = toprint  .. k ..  "= "
        --   end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "boolean") then
            toprint = toprint .. "" .. tostring(v) .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. string.gsub(v,'"',"'") .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. '\n' .. pprintBasicTable(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

BASE:I("Marianas-2022_playertasks.lua | Loading...")

local detectionSquadronNames = {
    "CVN73",
    "Tarawa",
    "961st Airborne Air Control Sqdn",
    "VP-8 Patrol Squadron",
    "VAQ-140 Patriots",
    "HSC-25 Helicopter Sea Combat Sqdn",
    "Wizard",
    "Overlord",
}
local ATOMenu = MENU_MISSION:New('ATO')

TaskControllerA2A = PLAYERTASKCONTROLLER:New('Air', coalition.side.BLUE, PLAYERTASKCONTROLLER.Type.A2A)
TaskControllerA2A:SetParentMenu(ATOMenu)
TaskControllerA2A:SetMenuName('Air')
-- TaskControllerA2A:SetTargetRadius(1000)
TaskControllerA2A:SuppressScreenOutput(false)
TaskControllerA2A:SetMenuOptions(true)
-- TaskControllerA2A:SetupIntel(detectionSquadronNames)

TaskControllerA2G = PLAYERTASKCONTROLLER:New('Surface', coalition.side.BLUE, PLAYERTASKCONTROLLER.Type.A2GS)
TaskControllerA2G:SetParentMenu(ATOMenu)
TaskControllerA2G:SetMenuName('Surface')
-- TaskControllerA2G:SetTargetRadius(10000)
TaskControllerA2G:SuppressScreenOutput(false)
TaskControllerA2G:SetMenuOptions(true)
-- TaskControllerA2G:SetupIntel(detectionSquadronNames)
-- TaskControllerA2G:EnableMarkerOps("TASK")

function TaskControllerA2A:OnAfterTaskAdded(From, Event, To, Task)
    local targetCoord = Task.Target:GetCoordinate():ToStringMGRS()

    local targetName = nil
    local targetObject = Task.Target:GetObject()

    db('\n'.. targetObject:GetDCSObject():getCategory())
    
    if targetObject then
        targetName = Task.Target:GetName()
        -- targetName = targetObject:GetDCSObject():getTypeName()
    else
        targetName = Task.Target:GetName()
    end
    -- HypeMan.sendBotMessage('A2A task created.\nTarget: '..targetName..'\nCoord: '..targetCoord)


end

function TaskControllerA2G:OnAfterTaskAdded(From, Event, To, Task)
    local targetCoord = Task.Target:GetCoordinate():ToStringMGRS()

    local targetName = nil
    local targetObject = Task.Target:GetObject()

    db('\n'.. targetObject:GetDCSObject():getCategory())
    
    if targetObject then
        targetName = Task.Target:GetName()
        -- targetName = targetObject:GetDCSObject():getTypeName()
    else
        targetName = Task.Target:GetName()
    end
    -- HypeMan.sendBotMessage('A2GS task created.\nTarget: '..targetName..'\nCoord: '..targetCoord)

    local msg = {}
    msg.command = 'onTasking'
    msg.name = Task.Target:GetName()
    msg.clients = Task:GetClients()
    dcsbot.sendBotTable(msg)
end

-- local zonetarget = ZONE:FindByName('target zone 1')
-- local targetCoord = zonetarget:GetCoordinate()

-- TaskControllerA2G:AddTarget(GROUP:FindByName('Naval-1'))
-- TaskControllerA2G:AddTarget(GROUP:FindByName("Ground-1"):GetCoordinate())


BASE:I("Marianas-2022_playertasks.lua | Loaded.")