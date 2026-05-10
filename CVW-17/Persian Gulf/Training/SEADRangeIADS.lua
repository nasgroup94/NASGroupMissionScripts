SEADRangeIADS = SkynetIADS:create('SEAD RANGE IADS')
SEADRangeIADS:addSAMSitesByPrefix("srsa")
SEADRangeIADS:addEarlyWarningRadarsByPrefix("ewsr")
SEADRangeIADS.IADSStatus = true


local sa2Group = SPAWN:New("srsa2")
local sa5Group = SPAWN:New("srsa5")
local sa6Group = SPAWN:New("srsa6")
local sa10Group = SPAWN:New("srsa10")
local sa11Group = SPAWN:New("srsa11")

local RangeMenu = MENU_COALITION:New(coalition.side.BLUE, "SEAD Range")

local theGroup = nil
local RangeCommands = {}
local ClearRangeCommand = nil

local ActivateGroup
local clearRange
local buildRangeCommands
local removeRangeCommands

removeRangeCommands = function()
    for _, command in pairs(RangeCommands) do
        if command then
            command:Remove()
        end
    end

    RangeCommands = {}
end

buildRangeCommands = function()
    RangeCommands = {}

    RangeCommands[#RangeCommands + 1] = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-2", RangeMenu, ActivateGroup, sa2Group)
    RangeCommands[#RangeCommands + 1] = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-5", RangeMenu, ActivateGroup, sa5Group)
    RangeCommands[#RangeCommands + 1] = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-6", RangeMenu, ActivateGroup, sa6Group)
    RangeCommands[#RangeCommands + 1] = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-10", RangeMenu, ActivateGroup, sa10Group)
    RangeCommands[#RangeCommands + 1] = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-11", RangeMenu, ActivateGroup, sa11Group)
end

clearRange = function(group)
    SEADRangeIADS:deactivate()
    if group then
        group:Destroy()
    end

    if ClearRangeCommand then
        ClearRangeCommand:Remove()
        ClearRangeCommand = nil
    end

    theGroup = nil

    buildRangeCommands()

    MESSAGE:New("SEAD Range Cleared", 10):ToAll()
end

ActivateGroup = function(spawnObject)
    local spawnedGroup = spawnObject:Spawn()
    SEADRangeIADS:activate()

    MESSAGE:New(spawnedGroup:GetName() .. " Activated", 10):ToAll()

    removeRangeCommands()

    theGroup = spawnedGroup

    ClearRangeCommand = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Clear Range", RangeMenu, clearRange, theGroup)
end

buildRangeCommands()
