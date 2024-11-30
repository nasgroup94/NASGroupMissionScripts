
-------------------- Red air wings ---------------------

--------------------------Island--------------------------
---- create CAP Zone just made it the entire airspace above the island
local islandCAPZone=ZONE_POLYGON:New("Island Border", GROUP:FindByName("islandCAPZone"))
local islandRejectZone=ZONE_POLYGON:New("Blue Zone",GROUP:FindByName("Blue Zone"))

--------------Island Cap squadrons----------------------------
local RedIslandVFA1 = SQUADRON:New("Aerial-1",2,"Squadron Name 1") -- need a squadron name
RedIslandVFA1:AddMissionCapability({AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT},90)
RedIslandVFA1:SetTakeoffAir()
RedIslandVFA1:SetGrouping(1)
RedIslandVFA1:SetMissionRange(100)


-----------------Island air wing ---------------
RedIslandAW = AIRWING:New("Red Island Warehouse", "Red Island Wing")
RedIslandAW:SetAirbase(AIRBASE:FindByName(AIRBASE.SouthAtlantic.Mount_Pleasant))
RedIslandAW:AddSquadron(RedIslandVFA1)
RedIslandAW:NewPayload("Aerial-1",2,{AUFTRAG.Type.CAP})
-- RedIslandAW:SetDespawnAfterLanding(true)


-----------------------Island Intel-----------------------------------

local red_detection_group = SET_GROUP:New()
red_detection_group:FilterPrefixes({ "Red EWR" })
red_detection_group:FilterOnce()


----------------------Island Chief------------------------------------
RedIslandChief = CHIEF:New(coalition.side.RED,red_detection_group)
RedIslandChief:SetClusterAnalysis(false,false,false)
RedIslandChief:AddAcceptZone(islandCAPZone)
RedIslandChief:AddRejectZone(islandRejectZone)
RedIslandChief:AddBorderZone(islandCAPZone)
RedIslandChief:SetTacticalOverviewOff()
RedIslandChief:SetResponseOnTarget(2,2,0,TARGET.Category.AIRCRAFT)
RedIslandChief:AddAirwing(RedIslandAW)
RedIslandChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
RedIslandChief:__Start(2)


---------------------Island Missions ----------------------------------
----Create a CAP Mission altitude 8k meters and 300 kts
local CAPUnit = GROUP:FindByName("Aerial-3")
local CAPCoordinate = CAPUnit:GetCoordinate()
local missionCAP = AUFTRAG:NewCAP(islandCAPZone,10000,300,CAPCoordinate,090,50,{"Air"})
missionCAP:SetRepeat(20)
missionCAP:SetRequiredAssets(2,2)
RedIslandChief:AddMission(missionCAP)


------------------Island Aux Functions--------------------------------------

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



