-----------------Tactical Menu----------------
mainMenu = MENU_MISSION:New( "Tactical Menu" )

A2A = MENU_MISSION:New( "Air to Air Spawns", mainMenu)
BVR = MENU_MISSION:New( "BVR (Missles) ", A2A)
ACM = MENU_MISSION:New("ACM (Guns Only)", A2A)
Bombers = MENU_MISSION:New("Bomber Intercepts)", A2A)
BombersBlueEscort = MENU_MISSION:New("Blue Bomber Escort)", Bombers)


A2G = MENU_MISSION:New( "Air to Ground Spawns", mainMenu)
SAM = MENU_MISSION:New("SAM Range", A2G)
AR_menu_root = MENU_MISSION:New("Armed Recon",A2G)
RANGE.MenuF10Root=MENU_MISSION:New("Basic Ranges",A2G).MenuPath
menuJTAC = MENU_MISSION:New("JTAC Refresh", A2G)

naval_menu = MENU_MISSION:New("Naval Ops", mainMenu)

helo_menu = MENU_MISSION:New("Helo Ops", mainMenu)

--alertLaunch = MENU_MISSION_COMMAND:New ("Launch the Alert Aircraft", mainMenu, launchEvent )
menuFox=MENU_MISSION:New("Fox Trainer", mainMenu)

----------------spawn zones------------------
zoneTable= { ZONE:New("DogfightZone"), ZONE:New("BomberZone")}

-------------------BVR aircraft - with missiles -------------------------
menuTableBVR = {"F-4 BVR", "F-5 BVR","F-15 BVR", "F-16 BVR","Mig21 BVR","Mig29 BVR", "Mig23 BVR"}

redBVR = {}
redBVR[1] = SPAWN:New(menuTableBVR[1]):InitLimit(3,0)
redBVR[2] = SPAWN:New(menuTableBVR[2]):InitLimit(3,0)
redBVR[3] = SPAWN:New(menuTableBVR[3]):InitLimit(3,0)
redBVR[4] = SPAWN:New(menuTableBVR[4]):InitLimit(3,0)
redBVR[5] = SPAWN:New(menuTableBVR[5]):InitLimit(3,0)
redBVR[6] = SPAWN:New(menuTableBVR[6]):InitLimit(3,0)
redBVR[7] = SPAWN:New(menuTableBVR[7]):InitLimit(3,0)

function newAirBVR(grpname, grpspawn)
  grpspawn:SpawnInZone(zoneTable[1],true,3000, 6000 ,nil)
  text = grpname
  MESSAGE:New(text.." spawned.",15,Info):ToAll()
end

MENU_MISSION_COMMAND:New (menuTableBVR[1], BVR, newAirBVR, menuTableBVR[1], redBVR[1])
MENU_MISSION_COMMAND:New (menuTableBVR[2], BVR, newAirBVR, menuTableBVR[2], redBVR[2])
MENU_MISSION_COMMAND:New (menuTableBVR[3], BVR, newAirBVR, menuTableBVR[3], redBVR[3])
MENU_MISSION_COMMAND:New (menuTableBVR[4], BVR, newAirBVR, menuTableBVR[4], redBVR[4])
MENU_MISSION_COMMAND:New (menuTableBVR[5], BVR, newAirBVR, menuTableBVR[5], redBVR[5])
MENU_MISSION_COMMAND:New (menuTableBVR[6], BVR, newAirBVR, menuTableBVR[6], redBVR[6])
MENU_MISSION_COMMAND:New (menuTableBVR[7], BVR, newAirBVR, menuTableBVR[7], redBVR[7])

--------------------ACM Aircraft - no missiles -------------------
menuTableACM = {"F-4 ACM", "F-5 ACM", "F-15 ACM" , "F-16 ACM", "Mig21 ACM", "Mig29 ACM", "Mig23 ACM"}

redACM = {}
redACM[1] = SPAWN:New(menuTableACM[1]):InitLimit(3,0)
redACM[2] = SPAWN:New(menuTableACM[2]):InitLimit(3,0)
redACM[3] = SPAWN:New(menuTableACM[3]):InitLimit(3,0)
redACM[4] = SPAWN:New(menuTableACM[4]):InitLimit(3,0)
redACM[5] = SPAWN:New(menuTableACM[5]):InitLimit(3,0)
redACM[6] = SPAWN:New(menuTableACM[6]):InitLimit(3,0)
redACM[7] = SPAWN:New(menuTableACM[7]):InitLimit(3,0)

function newAirACM(grpname, grpspawn)
  grpspawn:SpawnInZone(zoneTable[1],true,3000, 6000 ,nil)
  text = grpname
  MESSAGE:New(text.." spawned.",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New (menuTableACM[1], ACM, newAirACM, menuTableACM[1], redACM[1])
MENU_MISSION_COMMAND:New (menuTableACM[2], ACM, newAirACM, menuTableACM[2], redACM[2])
MENU_MISSION_COMMAND:New (menuTableACM[3], ACM, newAirACM, menuTableACM[3], redACM[3])
MENU_MISSION_COMMAND:New (menuTableACM[4], ACM, newAirACM, menuTableACM[4], redACM[4])
MENU_MISSION_COMMAND:New (menuTableACM[5], ACM, newAirACM, menuTableACM[5], redACM[5])
MENU_MISSION_COMMAND:New (menuTableACM[6], ACM, newAirACM, menuTableACM[6], redACM[6])
MENU_MISSION_COMMAND:New (menuTableACM[7], ACM, newAirACM, menuTableACM[7], redACM[7])

----------------Bombers--------------------
menuTableBomb = {"B-1B", "B-52"}

BlueBombers = {}
BlueBombers[1] = SPAWN:New(menuTableBomb[1]):InitLimit(3,0)
BlueBombers[2] = SPAWN:New(menuTableBomb[2]):InitLimit(3,0)

function newAirBomb(grpname, grpspawn)
  grpspawn:SpawnInZone(ZONE:New("Bomber Escort Start Zone"),true)
  text = grpname
  MESSAGE:New(text .. " spawned.", 15, Info):ToAll()
end

MENU_MISSION_COMMAND:New (menuTableBomb[1], BombersBlueEscort, newAirBomb, menuTableBomb[1], BlueBombers[1])
MENU_MISSION_COMMAND:New (menuTableBomb[2], BombersBlueEscort, newAirBomb, menuTableBomb[2], BlueBombers[2])

------------------SAM Sites----------------------
menuTableSAM = { "SA-2", "SA-6", "SA-8", "SA-10", "SA-11", "SA-15"}
samZoneTable = {ZONE:New("Sam_Zone_1"),ZONE:New("Sam_Zone_2"), ZONE:New("Sam_Zone_3")}

redSAM = {}
redSAM[1] = SPAWN:New(menuTableSAM[1]):InitLimit(10,0):InitAIOn():InitRandomizeZones(samZoneTable)
redSAM[2] = SPAWN:New(menuTableSAM[2]):InitLimit(50,0):InitAIOn():InitRandomizeZones(samZoneTable)
redSAM[3] = SPAWN:New(menuTableSAM[3]):InitLimit(5,0):InitAIOn():InitRandomizeZones(samZoneTable)
redSAM[4] = SPAWN:New(menuTableSAM[4]):InitLimit(50,0):InitAIOn():InitRandomizeZones(samZoneTable)
redSAM[5] = SPAWN:New(menuTableSAM[5]):InitLimit(15,0):InitAIOn():InitRandomizeZones(samZoneTable)
redSAM[6] = SPAWN:New(menuTableSAM[6]):InitLimit(5,0):InitAIOn():InitRandomizeZones(samZoneTable)

function newSAMSite(grpname, grpspawn)
  grpspawn:Spawn():OptionAlarmStateRed()
  text = grpname
  MESSAGE:New(text.." Group Spawned",15,Info):ToAll()
end

MENU_MISSION_COMMAND:New (menuTableSAM[1], SAM, newSAMSite, menuTableSAM[1], redSAM[1] )
MENU_MISSION_COMMAND:New (menuTableSAM[2], SAM, newSAMSite, menuTableSAM[2], redSAM[2] )
MENU_MISSION_COMMAND:New (menuTableSAM[3], SAM, newSAMSite, menuTableSAM[3], redSAM[3] )
MENU_MISSION_COMMAND:New (menuTableSAM[4], SAM, newSAMSite, menuTableSAM[4], redSAM[4] )
MENU_MISSION_COMMAND:New (menuTableSAM[5], SAM, newSAMSite, menuTableSAM[5], redSAM[5] )
MENU_MISSION_COMMAND:New (menuTableSAM[6], SAM, newSAMSite, menuTableSAM[6], redSAM[6] )

--------------ACMI Pods-----------------
trainerRunning = false

function trainerOnOff()
  if not trainerRunning then
    local acmiTrainer = MISSILETRAINER
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
    acmiTrainer:InitAlertsToAll(true) -- Now alerts are also on
    podOn:Remove()
  end
end
podOn = MENU_MISSION_COMMAND:New ("Turn On ACMI", A2A, trainerOnOff )

-----Launch Event
--local alert5Flag = USERFLAG:New("20")
--function launchEvent()
--alert5Flag:Set(true)
--MESSAGE:New("99, Launch Aircraft",15,Info):ToAll()
--alertLaunch:Remove()
--end

------------JTAC------------
-- function launchJTACZestafoni()
--   Spawn_JTAC1 = SPAWN:New("JTAC1")
--     :InitKeepUnitNames(true)
--     :InitLimit(1,0)
--     :OnSpawnGroup(
--       function( SpawnGroup )
--         ctld.JTACAutoLase(SpawnGroup.GroupName, 1778, false, "all")
--       end
--     )
--     :SpawnScheduled( 60,0 )
-- end
-- MENU_MISSION_COMMAND:New ("JTAC - Zestafoni", menuJTAC, launchJTACZestafoni )

function launchJTAC1()
  Spawn_JTAC1 = SPAWN:New("JTAC1")
    :InitKeepUnitNames(true)
    :InitLimit(1,0)
    :OnSpawnGroup(
      function( SpawnGroup )
        ctld.JTACAutoLase(SpawnGroup.GroupName, 1778, false, "all")
      end
    )
    :SpawnScheduled( 60,0 )
end
MENU_MISSION_COMMAND:New ("JTAC1", menuJTAC, launchJTAC1 )

function launchJTAC2()
  Spawn_JTAC2 = SPAWN:New("JTAC2")
    :InitKeepUnitNames(true)
    :InitLimit(1,0)
    :OnSpawnGroup(
      function( SpawnGroup )
        ctld.JTACAutoLase(SpawnGroup.GroupName, 1778, false, "all")
      end
    )
    :SpawnScheduled( 60,0 )
end
MENU_MISSION_COMMAND:New ("JTAC2", menuJTAC, launchJTAC2 )

------------------Fox Missile Trainer-------------
-- Protect all blue AI.
local blueset=SET_GROUP:New():FilterCoalitions("blue"):FilterActive():FilterStart()
foxTrainer = FOX:New()
foxTrainer:SetProtectedGroupSet(blueset)
--foxTrainer:AddSafeZone(ZONE:New("Zone_1"))
--foxTrainer:AddSafeZone(ZONE:New("Zone_2"))
foxTrainer:SetExplosionDistance(500)
foxTrainer:SetExplosionPower(.1)

FoxRunning = false
function FoxOn()
  if not FoxRunning then
    foxTrainer:Start()
    MESSAGE:New("Fox Trainer On",15,Info):ToAll()
    FoxRunning = true
  end
end
MENU_MISSION_COMMAND:New("Fox On", menuFox,FoxOn)

function FoxOff()
  foxTrainer:__Stop(1)
  MESSAGE:New("Fox Trainer Off",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New("Fox Off", menuFox,FoxOff)

function SmokeOn()
  foxTrainer:SetDebugOn()
  foxTrainer:SetDefaultLaunchAlerts(true)
  foxTrainer:SetDefaultLaunchMarks(true)
  MESSAGE:New("Smoke and Launch Information On",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New("Smoke and Launch Alerts On", menuFox,SmokeOn)

function SmokeOff()
  foxTrainer:SetDebugOff()
  foxTrainer:SetDefaultLaunchAlerts(false)
  foxTrainer:SetDefaultLaunchMarks(false)
  MESSAGE:New("Smoke and Launch Information Off",15,Info):ToAll()
end
MENU_MISSION_COMMAND:New("Smoke and Launch Alerts Off", menuFox,SmokeOff)

-------------Ranges---------------------------------
--Range 5 Ships--
local function range_5_Ships()
  -- range_5_menu_Ships:Remove()
  trigger.action.setUserFlag(21500,true)
end

range_5_menu_Ships = MENU_MISSION_COMMAND:New("Activate Naval Targets North",naval_menu,range_5_Ships)

--Range 6 Ships--
local function range_6_Ships()
  -- range_6_menu_Ships:Remove()
  trigger.action.setUserFlag(21600,true)
end

range_6_menu_Ships = MENU_MISSION_COMMAND:New("Activate Naval Targets South",naval_menu,range_6_Ships)

------------Scud Range------------------------
--Flag is true 20053, then flag set random value --> flag equals 20050, 1, group activate
local function range_1_AR()
  range_1_menu_AR:Remove()
  trigger.action.setUserFlag(20053,true)
  MESSAGE:New("SCUD launchers sighted in the vicinity of Zugdidi",30,Info):ToAll()
  if range_1_menu_AR_Zugdidi_reattack then
  --AR_menu_root:Remove()
  end

end

range_1_menu_AR = MENU_MISSION_COMMAND:New("Activate AR (SCUD hunt Zugdidi)",AR_menu_root,range_1_AR)

local SPAWN_1_1 = SPAWN:New("R1_AR_Recce_1")
local SPAWN_1_2 = SPAWN:New("R1_AR_Recce_2")
local SPAWN_1_3 = SPAWN:New("R1_AR_MBT_PLT1")
local SPAWN_1_4 = SPAWN:New("R1_AR_IFV_PLT2")
local SPAWN_1_5 = SPAWN:New("R1_AR_IFV_PLT3")
local SPAWN_1_6 = SPAWN:New("R1_AR_IFV_PLT4")

local function range_1_AR_Zugdidi_reattack()
  range1_respawn_counter= range1_respawn_counter+1
  if range1_respawn_counter < 4 then
    SPAWN_1_1:Spawn()
    SPAWN_1_2:Spawn()
    SPAWN_1_3:Spawn()
    SPAWN_1_4:Spawn()
    SPAWN_1_5:Spawn()
    SPAWN_1_6:Spawn()
	MESSAGE:New("Armed reconnaissance sighted approaching Zugdidi from Senaki",30,Info):ToAll()
  else if range_1_menu_AR_Zugdidi_reattack  then 
	range_1_menu_AR_Zugdidi_reattack:Remove()
    end
  end
end

local function range_1_AR_Zugdidi()
  range_1_menu_AR_Zugdidi:Remove()
  range_1_menu_AR_Zugdidi_reattack = MENU_MISSION_COMMAND:New("Range 1 AR Attack on Zugdidi, spawn reinforcements",AR_menu_root,range_1_AR_Zugdidi_reattack)
  SPAWN_1_1:Spawn()
  SPAWN_1_2:Spawn()
  SPAWN_1_3:Spawn()
  SPAWN_1_4:Spawn()
  SPAWN_1_5:Spawn()
  SPAWN_1_6:Spawn()
  range1_respawn_counter = 1
  MESSAGE:New("Armed reconnaissance sighted approaching Zugdidi from Senaki",30,Info):ToAll()
end

range_1_menu_AR_Zugdidi = MENU_MISSION_COMMAND:New("Range 1 AR Attack on Zugdidi",AR_menu_root,range_1_AR_Zugdidi)

-----------Range 2 Il'skiy------------------------

local function range_2_AR()
  range_2_menu_AR:Remove()
  trigger.action.setUserFlag(20063,true)
  MESSAGE:New("SCUD launchers sighted in the vicinity of Il'skiy",30,Info):ToAll()
  if range_2_menu_AR_Ilskiy_reattack then
  --AR_menu_root:Remove()
  end

end

range_2_menu_AR = MENU_MISSION_COMMAND:New("Activate AR (SCUD hunt Il'skiy)",AR_menu_root,range_2_AR)

local SPAWN_2_1 = SPAWN:New("R2_AR_Recce_1")
local SPAWN_2_2 = SPAWN:New("R2_AR_Recce_2")
local SPAWN_2_3 = SPAWN:New("R2_AR_MBT_PLT1")
local SPAWN_2_4 = SPAWN:New("R2_AR_IFV_PLT2")
local SPAWN_2_5 = SPAWN:New("R2_AR_IFV_PLT3")
local SPAWN_2_6 = SPAWN:New("R2_AR_IFV_PLT4")

local function range_2_AR_Ilskiy_reattack()
  range2_respawn_counter = range2_respawn_counter+1
  if range2_respawn_counter < 4 then
    SPAWN_2_1:Spawn()
    SPAWN_2_2:Spawn()
    SPAWN_2_3:Spawn()
    SPAWN_2_4:Spawn()
    SPAWN_2_5:Spawn()
    SPAWN_2_6:Spawn()
	MESSAGE:New("Armed reconnaissance sighted approaching Il'skiy from the east",30,Info):ToAll()
  else if range_2_menu_AR_Ilskiy_reattack  then 
	range_2_menu_AR_Ilskiy_reattack:Remove()
    end
  end
end

local function range_2_AR_Ilskiy()
  range_2_menu_AR_Ilskiy:Remove()
  range_2_menu_AR_Ilskiy_reattack = MENU_MISSION_COMMAND:New("Range 2 AR Attack on Il'skiy, spawn reinforcements",AR_menu_root,range_2_AR_Ilskiy_reattack)
  SPAWN_2_1:Spawn()
  SPAWN_2_2:Spawn()
  SPAWN_2_3:Spawn()
  SPAWN_2_4:Spawn()
  SPAWN_2_5:Spawn()
  SPAWN_2_6:Spawn()
  MESSAGE:New("Armed reconnaissance sighted approaching of Ilskiy from the south",30,Info):ToAll()
  range2_respawn_counter = 1
end

range_2_menu_AR_Ilskiy = MENU_MISSION_COMMAND:New("Range 2 AR Attack on Ilskiy",AR_menu_root,range_2_AR_Ilskiy)

----------------Restart menu---------------------
-- ChangeFlag = USERFLAG:New("16000")
-- dayFlag = USERFLAG:New("16005")
-- lowIFRFlag = USERFLAG:New("16010")
-- lightIFRFlag = USERFLAG:New("16015")
-- nightFlag = USERFLAG:New("16020")
-- local menuRestart=MENU_MISSION:New("Change Mission")

-- function ChangeMap_mission()
--   ChangeFlag:Set(true)
-- end
-- restartMenu1 = MENU_MISSION_COMMAND:New("Load PG Day Misssion", menuRestart,ChangeMap_mission)

-- function load_Day_mission()
--   dayFlag:Set(true)
-- end
-- restartMenu2 = MENU_MISSION_COMMAND:New("Load Day Mission", menuRestart,load_Day_mission)

-- function load_HardIFR_mission()
--   lowIFRFlag:Set(true)
-- end
-- restartMenu3 = MENU_MISSION_COMMAND:New("Load Hard IFR Mission", menuRestart,load_HardIFR_mission)

-- function load_LightIFR_mission()
--   lightIFRFlag:Set(true)
-- end
-- restartMenu4 = MENU_MISSION_COMMAND:New("Load Light IFR Mission", menuRestart,load_LightIFR_mission)

-- function load_Night_mission()
--   nightFlag:Set(true)
-- end
-- restartMenu5 = MENU_MISSION_COMMAND:New("Load Night Mission", menuRestart,load_Night_mission)


