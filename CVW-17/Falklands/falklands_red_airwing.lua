
------------------ Red air wings ---------------------

------------------------Island--------------------------
-- create CAP Zone just made it the entire airspace above the island
local islandCAPZone=ZONE_POLYGON:New("Island Border", GROUP:FindByName("Red Island Border"))
local agents = SET_GROUP:New():FilterPrefixes("SAM1"):FilterOnce()

------------Island Cap squadrons----------------------------
local RedIslandVFA1 = SQUADRON:New("Red Island M29s",8,"Squadron Name 1") -- need a squadron name
RedIslandVFA1:AddMissionCapability({AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT})
:SetTakeoffAir()

local RedIslandVFA2 = SQUADRON:New("Red Island A4",8,"Squadron Name 2") -- need a squadron name
RedIslandVFA2:AddMissionCapability({AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT})
:SetTakeoffAir() 

--Create a CAP Mission altitude 8k meters and 300 kts
local missionCAP = AUFTRAG:NewCAP(islandCAPZone,8000,300)
missionCAP:SetTime("11:02","12:00")

---------------Island air wing ---------------
RedIslandAW = AIRWING:New("Red Island Warehouse", "Red Island Wing")
RedIslandAW:SetAirbase(AIRBASE:FindByName(AIRBASE.SouthAtlantic.Mount_Pleasant))
RedIslandAW:AddSquadron(RedIslandVFA1)
RedIslandAW:AddSquadron(RedIslandVFA2)
RedIslandAW:NewPayload("Red Island M29s",8,{AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT})
RedIslandAW:NewPayload("Red Island A4",8,{AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT})
RedIslandAW:SetDespawnAfterLanding(true)
RedIslandAW:Start()

--------------------Island Chief------------------------------------
RedIslandChief = CHIEF:New(coalition.side.RED,agents)
RedIslandChief:AddBorderZone(islandCAPZone)
RedIslandChief:SetTacticalOverviewOn()
RedIslandChief:SetResponseOnTarget(2,4,6,nil,AUFTRAG.Type.INTERCEPT)
RedIslandChief:AddAirwing(RedIslandAW)
RedIslandChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)
RedIslandChief:__Start(2)

-------------------Island Missions ----------------------------------

--Create a CAP Mission altitude 8k meters and 300 kts
local missionCAP = AUFTRAG:NewCAP(islandCAPZone,8000,300)

--- add this mission to the island air wing
RedIslandAW:AddMission(missionCAP)
RedIslandAW:SetNumberCAP(2)



------------------Island Aux Functions--------------------------------------

--- Function called each time Chief Agents detect a new contact.
function RedIslandChief:OnAfterNewContact(From, Event, To, Contact)
    -- Gather info of contact.
    local ContactName=RedIslandChief:GetContactName(Contact)
    local ContactType=RedIslandChief:GetContactTypeName(Contact)
    local ContactThreat=RedIslandChief:GetContactThreatlevel(Contact)
    -- Text message.
    local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)   
    -- Show message in log file.
    env.info(text) 
  end





-- assert(loadfile("C:/VNAO/mission_scripts/CVW-7/Falklands/falklands_red_auftrag.lua"))()--- make sure this is always the last line




































---no longer used implemented red chief who uses the IADS to launch interceptors to intruders
-- -------------------A/A dispatcher ---------------------
-- local IslandDetectionSet = SET_GROUP:New():FilterPrefixes("EWIsland"):FilterStart()
-- local IslandDetection = DETECTION_AREAS:New(IslandDetectionSet,30000)
-- local IslandDispatcher = AI_A2A_DISPATCHER:New(IslandDetection)
-- IslandDispatcher:SetEngageRadius(100000)
-- IslandDispatcher:SetGciRadius(100000)
-- local IslandBorderZone = ZONE_POLYGON:New("Island Border", GROUP:FindByName("Red Island Border"))
-- IslandDispatcher:SetBorderZone(IslandBorderZone)
-- IslandDispatcher:SetSquadron("Mount Pleasant",AIRBASE.SouthAtlantic.Mount_Pleasant,{"Red Island M29s"},8)
-- IslandDispatcher:SetSquadronGrouping("Mount Pleasant",2)
-- IslandDispatcher:SetSquadronGci("Mount Pleasant",900,1200)
-- IslandDispatcher:SetTacticalDisplay(true)
-- IslandDispatcher:Start()

-- islandIADS:addMooseSetGroup(IslandDetectionSet)



