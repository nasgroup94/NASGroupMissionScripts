SEADRangeIADS = SkynetIADS:create('SEAD RANGE IADS')
SEADRangeIADS:addSAMSitesByPrefix("srsa")
SEADRangeIADS:addEarlyWarningRadarsByPrefix("ewsr")


local sa2Group = SPAWN:New("srsa2")
local sa5Group = SPAWN:New("srsa5")
local sa6Group = SPAWN:New("srsa6")
local sa10Group = SPAWN:New("srsa10")
local sa11Group = SPAWN:New("srsa11")

local RangeMenu = MENU_COALITION:New(coalition.side.BLUE, "SEAD Range")

local function clearRange(group)
    group:Destroy()
end

local function ActivateGroup(group)
    group:Spawn()

    MESSAGE:New("SA-2 Activated", 10):ToAll()

    RangeMenu:Remove()

    local deactivate = MENU_COALITION:New("SEAD Range",coalition.side.blue)
    MENU_COALITION_COMMAND:New(coalition.side.Blue,"Clear Range",clearRange(group))


end

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-2", RangeMenu, ActivateGroup(sa2Group))
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-5", RangeMenu, ActivateGroup(sa5Group))
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-6", RangeMenu, ActivateGroup(sa6Group))
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-10", RangeMenu, ActivateGroup(sa10Group))
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "SA-11", RangeMenu, ActivateGroup(sa11Group))
