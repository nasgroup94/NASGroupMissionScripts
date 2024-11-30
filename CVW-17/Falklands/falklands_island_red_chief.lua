
-------------------- Red air wings ---------------------

--------------------------Island--------------------------
---- create CAP Zone just made it the entire airspace above the island
local islandCAPZone=ZONE_POLYGON:New("Island Border", GROUP:FindByName("islandCAPZone"))
local islandRejectZone=ZONE_POLYGON:New("Blue Zone",GROUP:FindByName("Blue Zone"))

--------------Island Cap squadrons----------------------------
-- local RedIslandMig = SQUADRON:New("Mig Island CAP",2,"Mig CAP Flight") -- need a squadron name
-- RedIslandMig:AddMissionCapability({AUFTRAG.Type.CAP},90)
-- RedIslandMig:SetTakeoffAir()
-- RedIslandMig:SetGrouping(1)
-- RedIslandMig:SetMissionRange(150)

local RedIslandMirage = SQUADRON:New("Mirage CAP Flight",2,"Mirage CAP Flight") -- need a squadron name
RedIslandMirage:AddMissionCapability({AUFTRAG.Type.CAP},90)
RedIslandMirage:AddMissionCapability({AUFTRAG.Type.INTERCEPT},90)
RedIslandMirage:SetTakeoffAir()
RedIslandMirage:SetGrouping(1)
RedIslandMirage:SetMissionRange(150)

local RedIslandAWACS = SQUADRON:New("A50 Island",2,"Island AWACS") -- need a squadron name
RedIslandAWACS:AddMissionCapability({AUFTRAG.Type.AWACS},90)
RedIslandAWACS:SetTakeoffAir()
RedIslandAWACS:SetGrouping(1)
RedIslandAWACS:SetMissionRange(100)



-----------------Island air wing ---------------
RedIslandAW = AIRWING:New("Red Island Warehouse", "Red Island Wing")
RedIslandAW:SetAirbase(AIRBASE:FindByName(AIRBASE.SouthAtlantic.Mount_Pleasant))
-- RedIslandAW:AddSquadron(RedIslandMig)
RedIslandAW:AddSquadron(RedIslandMirage)
RedIslandAW:AddSquadron(RedIslandAWACS)
-- RedIslandAW:NewPayload("Mig Island CAP",2,{AUFTRAG.Type.CAP})
RedIslandAW:NewPayload("Mirage CAP Flight",2,{AUFTRAG.Type.CAP})
-- RedIslandAW:NewPayload("Mirage CAP Flight",2,{AUFTRAG.Type.INTERCEPT})

-- RedIslandAW:SetDespawnAfterLanding(true)


-----------------------Island Intel-----------------------------------

local red_detection_group = SET_GROUP:New()
red_detection_group:FilterPrefixes({ "EWIsland" })
red_detection_group:FilterOnce()


----------------------Island Chief------------------------------------
RedIslandChief = CHIEF:New(coalition.side.RED,red_detection_group)
RedIslandChief:SetClusterAnalysis(false,false,false)
RedIslandChief:AddAcceptZone(islandCAPZone)
RedIslandChief:AddRejectZone(islandRejectZone)
RedIslandChief:AddBorderZone(islandCAPZone)
RedIslandChief:SetTacticalOverviewOn()
RedIslandChief:SetResponseOnTarget(2,2,0,TARGET.Category.AIRCRAFT)
RedIslandChief:AddAirwing(RedIslandAW)
RedIslandChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
RedIslandChief:__Start(2)


---------------------Island Missions ----------------------------------
----Create a CAP Mission altitude 10k meters and 300 kts Migs
-- local CAPUnit = GROUP:FindByName("Mig CAP Position")
-- local CAPCoordinate = CAPUnit:GetCoordinate()
-- local missionCAPMig = AUFTRAG:NewCAP(islandCAPZone,10000,300,CAPCoordinate,090,100,{"Air"})
-- missionCAPMig:SetRepeat(20)
-- missionCAPMig:SetRequiredAssets(1,2)
-- RedIslandChief:AddMission(missionCAPMig)

----Create a CAP Mission altitude 14k meters and 300 kts Mirage
local CAPUnit = GROUP:FindByName("Mirage CAP Position")
local CAPCoordinate = CAPUnit:GetCoordinate()
local missionCAPMirage = AUFTRAG:NewCAP(islandCAPZone,14000,300,CAPCoordinate,180,100,{"Air"})
missionCAPMirage:SetRepeat(20)
missionCAPMirage:SetRequiredAssets(1,2)
RedIslandChief:AddMission(missionCAPMirage)

----Create an ALERT Mission to support CAP flights
-- local CAPUnit = GROUP:FindByName("Mirage CAP Position")
-- local CAPCoordinate = CAPUnit:GetCoordinate()
-- local missionALERTMirage = AUFTRAG:NewALERT5(AUFTRAG.Type.INTERCEPT)
-- missionALERTMirage:SetRequiredAssets(1,2)
-- RedIslandChief:AddMission(missionALERTMirage)

----Create a AWACS Mission altitude 20k meters and 250 kts A50
local CAPUnit = GROUP:FindByName("AWACS Position")
local CAPCoordinate = CAPUnit:GetCoordinate()
local missionAWACS = AUFTRAG:NewAWACS(CAPCoordinate,20000,250,270,75)
missionAWACS:SetRepeat(20)
missionAWACS:SetRequiredAssets(1,1)
RedIslandChief:AddMission(missionAWACS)



------------------Island Aux Functions--------------------------------------

function RedIslandChief:OnAfterOpsOnMission(From,Event,To,OpsGroup,Mission)
    local group = OpsGroup
    local name = group:GetUnit():GetName()
    local test = string.find(name,'AWACS')
    if(test ~= nil)
    then
        islandIADS:addEarlyWarningRadar(group:GetUnit():GetName())
    end
end

-- Function called each time Chief Agents detect a new contact.
-- function RedIslandChief:OnAfterNewContact(From, Event, To, Contact)
--   -- Gather info of contact.
--   local ContactName=RedIslandChief:GetContactName(Contact)
--   local ContactType=RedIslandChief:GetContactTypeName(Contact)
--   local ContactThreat=RedIslandChief:GetContactThreatlevel(Contact)
--   -- Text message.
--   local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)   
--   -- Show message in log file.
--   MESSAGE:New(text,200,"Chief Intel"):ToAll():ToLog()
-- end





-- assert(loadfile("C:/VNAO/mission_scripts/CVW-7/Falklands/falklands_red_auftrag.lua"))()--- make sure this is always the last line



-- function RedIntel:OnAfterNewCluster(From,Event,To,Cluster)
--   -- Aircraft?
--   if Cluster.ctype ~= INTEL.Ctype.AIRCRAFT then return end
--   -- Threatlevel 0..10
--   local contact = self:GetHighestThreatContact(Cluster)
--   local name = contact.groupname --#string
--   local threat = contact.threatlevel --#number
--   local position = self:CalcClusterFuturePosition(Cluster,300)
--   -- calculate closest zone
--   local bestdistance = 2000*1000 -- 2000km
--   local targetairwing = nil -- Ops.AirWing#AIRWING
--   local targetawname = "" -- #string
--   local clustersize = self:ClusterCountUnits(Cluster) or 1
--   local wingsize = math.abs(1 * (clustersize+1))
--   if (not Cluster.mission) and (wingsize > 0) then
--    MESSAGE:New(string.format("**** Blue Interceptors need wingsize %d", wingsize),15,"CAPGCI"):ToAll():ToLog()
--     for _,_data in pairs (BlueCapZoneSet) do
--       local airwing = _data[1] -- Ops.AirWing#AIRWING
--       local zone = _data[2] -- Core.Zone#ZONE
--       local zonecoord = zone:GetCoordinate()
--       local name = _data[3] -- #string
--       local distance = position:DistanceFromPointVec2(zonecoord)
--       local airframes = airwing:CountAssets(true)
--       if distance < bestdistance and airframes >= wingsize then
--         bestdistance = distance
--         targetairwing = airwing
--         targetawname = name
--       end
--     end
--     local text = string.format("Closest Airwing is %s", targetawname)
--     local m = MESSAGE:New(text,10,"CAPGCI"):ToAll():ToLog()
--     -- Do we have a matching airwing?
--     if targetairwing then
--       local AssetCount = targetairwing:GetAssetsOnMission({AUFTRAG.Type.INTERCEPT})
--       -- Enough airframes on mission already?
--       if #AssetCount <= 3 then
--         local repeats = math.random(1,2)
--         local InterceptAuftrag = AUFTRAG:NewINTERCEPT(contact.group)
--           :SetMissionRange(150)
--           :SetPriority(1,true,1)
--           :SetRequiredAssets(wingsize)
--           :SetRepeatOnFailure(repeats)
--           :SetMissionSpeed(UTILS.KnotsToAltKIAS(450,25000))
--           :SetMissionAltitude(25000)
--         targetairwing:AddMission(InterceptAuftrag)
--         Cluster.mission = InterceptAuftrag
--       end
--     else
--       MESSAGE:New("**** Not enough airframes available!",15,"CAPGCI"):ToAll():ToLog()
--     end
--  end
-- end

































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



