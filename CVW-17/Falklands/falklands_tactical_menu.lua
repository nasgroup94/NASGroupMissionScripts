
TacticalMainMenu = MENU_MISSION:New( "Tactical Menu" )


-- -------------------- SINKex -----------------
-- TacticalSFWTSINKexMenu = MENU_MISSION:New("SFWT - SINKex", TacticalMainMenu)
-- local SINKexSpawnZonePrefixes = {'NavalTrainingSpawn'}
-- local SINKexZonesTable = {ZONE:New( "NavalTrainingSpawn-1" ), ZONE:New( "NavalTrainingSpawn-2" )}
-- local SouthTrainingZone = {ZONE:New("NavalTrainingSpawn3"),ZONE:New("NavalTrainingSpawn4")}

-- function SFWTSINKexSingle()
--     -- local SINKexSingleGroup = RNT:New('SINKex Single', SINKexSpawnZonePrefixes, {"North SINKex single"})
--     --     :InitSpawnInRandomZones()
--     --     :SetMaxGroupCount(1)
--     --     :SetPathfindingOff()
--     --     :DebugOn()
--     --     :Start()

--     -- for _, navygroup in pairs(SINKexSingleGroup.navalTrafficGroups) do
        
--     --     TaskControllerA2G:AddTarget(GROUP:FindByName(navygroup:GetName()))
--     -- end
--     SINKexSingleGroup = SPAWN:New('North SINKex single')
--         :InitRandomizeZones(SINKexZonesTable)
--         :InitGroupHeading(0, 360)
--         :OnSpawnGroup(function(group)
--             local groupName = group:GetName()
--             TaskControllerA2G:AddTarget(GROUP:FindByName(groupName))
--         end)
--         :Spawn()

--     MESSAGE:New("SINKex - Single Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Single', TacticalSFWTSINKexMenu, SFWTSINKexSingle)

-- function SFWTSINKexFormation()
--     local SINKexFormationGroup = RNT:New('SINKex Formation', SINKexSpawnZonePrefixes, {'North SINKex formation'})
--         :InitSpawnInRandomZones()
--         :SetMaxGroupCount(1)
--         :Start()

--     for _, navygroup in pairs(SINKexFormationGroup.navalTrafficGroups) do
--         TaskControllerA2G:AddTarget(GROUP:FindByName(navygroup:GetName()))
--     end

--     MESSAGE:New("SINKex - Formation Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Formation', TacticalSFWTSINKexMenu, SFWTSINKexFormation)

-- function SFWTSINKexFormationSmall()
--     local SINKexFormationSmallGroup = RNT:New('SINKex Small Formation', SINKexSpawnZonePrefixes, {'North SINKex small formation'})
--         :InitSpawnInRandomZones()
--         :SetMaxGroupCount(1)
--         :Start()

--     for _, navygroup in pairs(SINKexFormationSmallGroup.navalTrafficGroups) do
--         TaskControllerA2G:AddTarget(GROUP:FindByName(navygroup:GetName()))
--     end
    

--     MESSAGE:New("SINKex - Formation Small Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Formaition Small', TacticalSFWTSINKexMenu, SFWTSINKexFormationSmall)

-- function SFWTSINKex52B()
--   SFWTSingle52B = SPAWN:New('SFWT52B')
--     :InitRandomizeZones(SouthTrainingZone)
--     :InitGroupHeading(0,360)
--     :OnSpawnGroup(function(group52B)
--       local groupName = group52B:GetName()
--       TaskControllerA2G:AddTarget(GROUP:FindByName(groupName))
--     end)
--     :Spawn()
--   MESSAGE:New("SINKex - Single 52B Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Single 52B',TacticalSFWTSINKexMenu,SFWTSINKex52B)

-- function SFWTSINKex54A()
--   SFWTSingle54A = SPAWN:New('SFWT54A')
--     :InitRandomizeZones(SouthTrainingZone)
--     :InitGroupHeading(0,360)
--     :OnSpawnGroup(function(group54A)
--       local groupName = group54A:GetName()
--       TaskControllerA2G:AddTarget(GROUP:FindByName(groupName))
--     end)
--     :Spawn()
--   MESSAGE:New("SINKex - Single 54A Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Single 54A',TacticalSFWTSINKexMenu,SFWTSINKex54A)

-- function SFWTSINKex52C()
--   SFWTSingle52C = SPAWN:New('SFWT52C')
--     :InitRandomizeZones(SouthTrainingZone)
--     :InitGroupHeading(0,360)
--     :OnSpawnGroup(function(group52C)
--       local groupName = group52C:GetName()
--       TaskControllerA2G:AddTarget(GROUP:FindByName(groupName))
--     end)
--     :Spawn()
--   MESSAGE:New("SINKex - Single 52C Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Single 52C',TacticalSFWTSINKexMenu,SFWTSINKex52C)

-- function SFWTSINKex52D()
--   SFWTSingle52D = SPAWN:New('SFWT52D')
--     :InitRandomizeZones(SouthTrainingZone)
--     :InitGroupHeading(0,360)
--     :OnSpawnGroup(function(group52D)
--       local groupName = group52D:GetName()
--       TaskControllerA2G:AddTarget(GROUP:FindByName(groupName))
--     end)
--     :Spawn()
--   MESSAGE:New("SINKex - Single 52D Activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('SINKex Single 52D',TacticalSFWTSINKexMenu,SFWTSINKex52D)


  

-- TacticalSFWTAAMenu = MENU_MISSION:New("SFWT - AA 2-Ship", TacticalMainMenu)

-- function SFWTAAEagleBVR()
--     local SFWTEagleBVR_fg = FLIGHTGROUP:New("Uzi1")
--     SFWTEagleBVR_fg:SetDefaultROE(ENUMS.ROE.OpenFireWeaponFree)
--     SFWTEagleBVR_fg:Activate()

--     MESSAGE:New("Eagle BVR 2 ship activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('Eagles BVR', TacticalSFWTAAMenu, SFWTAAEagleBVR)

-- function SFWTAAFalconBVR()
--     local SFWTFalconBVR_fg = FLIGHTGROUP:New("Lobo1")
--     SFWTFalconBVR_fg:SetDefaultROE(ENUMS.ROE.OpenFireWeaponFree)
--     SFWTFalconBVR_fg:Activate()

--     MESSAGE:New("Falcon BVR 2 ship activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('Falcons BVR', TacticalSFWTAAMenu, SFWTAAFalconBVR)

-- function SFWTAATomcatBVR()
--     local SFWTTomcatBVR_fg = FLIGHTGROUP:New("Springfield1")
--     SFWTTomcatBVR_fg:SetDefaultROE(ENUMS.ROE.OpenFireWeaponFree)
--     SFWTTomcatBVR_fg:Activate()

--     MESSAGE:New("Tomcat BVR 2 ship activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('Tomcats BVR', TacticalSFWTAAMenu, SFWTAATomcatBVR)

-- function SFWTAAEagleWVR()
--     local SFWTEagleWVR_fg = FLIGHTGROUP:New("Uzi2")
--     SFWTEagleWVR_fg:SetDefaultROE(ENUMS.ROE.OpenFireWeaponFree)
--     SFWTEagleWVR_fg:Activate()

--     MESSAGE:New("Eagle WVR 2 ship activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('Eagles WVR', TacticalSFWTAAMenu, SFWTAAEagleWVR)

-- function SFWTAAFalconWVR()
--     local SFWTFalconWVR_fg = FLIGHTGROUP:New("Lobo2")
--     SFWTFalconWVR_fg:SetDefaultROE(ENUMS.ROE.OpenFireWeaponFree)
--     SFWTFalconWVR_fg:Activate()

--     MESSAGE:New("Falcon WVR 2 ship activated",15,Info):ToAll()
-- end
-- MENU_MISSION_COMMAND:New('Falcons WVR', TacticalSFWTAAMenu, SFWTAAFalconWVR)



------------------- AIR ------------------
-- TacticalFixedWingMenu = MENU_MISSION:New("Fixed Wing", TacticalMainMenu)
-- TacticalA2AMenu =         MENU_MISSION:New("Air to Air", TacticalFixedWingMenu)
-- TacticalA2GMenu =         MENU_MISSION:New("Air to Ground", TacticalFixedWingMenu)
-- TacticalNavalMenu =       MENU_MISSION:New("Naval", TacticalFixedWingMenu)
TacticalTrainersMenu =    MENU_MISSION:New("Trainers", TacticalMainMenu)
TacticalTrainersFoxMenu =   MENU_MISSION:New("Fox Trainer", TacticalTrainersMenu)
TacticalTrainersACMIMenu =  MENU_MISSION:New("ACMI Trainer", TacticalTrainersMenu)

TacticalHeloMenu = MENU_MISSION:New("Helo", TacticalMainMenu)
-- TacticalBoatRescueMenu = MENU_MISSION:New("Sailor Rescue", TacticalHeloMenu)
-- TacticalPilotRescueMenu = MENU_MISSION:New("Pilot Rescue", TacticalHeloMenu)
-- TacticalRandomRescueMenu = MENU_MISSION:New("Random Rescue", TacticalHeloMenu)

------------------ HELO ------------------
-- -- Sailor Rescue
-- MENU_MISSION_COMMAND:New("1 Sailor", TacticalBoatRescueMenu, SailorRescue, 1)
-- MENU_MISSION_COMMAND:New("2 Sailors", TacticalBoatRescueMenu, SailorRescue, 2)
-- MENU_MISSION_COMMAND:New("3 Sailors", TacticalBoatRescueMenu, SailorRescue, 3)
-- MENU_MISSION_COMMAND:New("4 Sailors", TacticalBoatRescueMenu, SailorRescue, 4)


------------------Fox Missile Trainer-------------
-- Protect all blue AI.
local blueset=SET_GROUP:New():FilterCoalitions("blue"):FilterActive():FilterStart()
FoxTrainer = FOX:New()
FoxTrainer:SetProtectedGroupSet(blueset)
--FoxTrainer:AddSafeZone(ZONE:New("Zone_1"))
--FoxTrainer:AddSafeZone(ZONE:New("Zone_2"))
FoxTrainer:SetExplosionDistance(500)
FoxTrainer:SetExplosionPower(.1)

local foxRunning = false
function FoxOn()
  if not foxRunning then
    FoxTrainer:Start()
    MESSAGE:New("Fox Trainer Started",15,Info):ToAll()
    foxRunning = true
  end
end
MENU_MISSION_COMMAND:New("Fox On", TacticalTrainersFoxMenu,FoxOn)

function FoxOff()
  if foxRunning then
    FoxTrainer:__Stop(1)
    MESSAGE:New("Fox Trainer Stopped",15,Info):ToAll()
    foxRunning = false
  end
end
MENU_MISSION_COMMAND:New("Fox Off", TacticalTrainersFoxMenu,FoxOff)

function SmokeOn()
  FoxTrainer:SetDebugOn()
  FoxTrainer:SetDefaultLaunchAlerts(true)
  FoxTrainer:SetDefaultLaunchMarks(true)
  MESSAGE:New("Smoke and Launch Information On",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New("Smoke and Launch Alerts On", TacticalTrainersFoxMenu,SmokeOn)

function SmokeOff()
  FoxTrainer:SetDebugOff()
  FoxTrainer:SetDefaultLaunchAlerts(false)
  FoxTrainer:SetDefaultLaunchMarks(false)
  MESSAGE:New("Smoke and Launch Information Off",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New("Smoke and Launch Alerts Off", TacticalTrainersFoxMenu,SmokeOff)


--------------ACMI Pods-----------------
local trainerRunning = false
ACMITrainer = nil

function ACMITrainerOnOff()
  if not trainerRunning then
    ACMITrainer = MISSILETRAINER
      :New( 200, "ACMI pods now active" )
      :InitMessagesOnOff(true)
      :InitAlertsToAll(true)
      :InitAlertsHitsOnOff(true)
      :InitAlertsLaunchesOnOff(false) -- I'll put it on below ...
      :InitBearingOnOff(false)
      :InitRangeOnOff(false)
      :InitTrackingOnOff(false)
      :InitTrackingToAll(false)
      :InitMenusOnOff(false)
      ACMITrainer:InitAlertsToAll(true) -- Now alerts are also on
    -- podOn:Remove()
    trainerRunning = true
  else
    ACMITrainer = nil
    trigger.action.outText('ACMI pods are now disabled', 10)
    trainerRunning = false
  end
end
podOn = MENU_MISSION_COMMAND:New ("Toggle ACMI", TacticalTrainersACMIMenu, ACMITrainerOnOff )