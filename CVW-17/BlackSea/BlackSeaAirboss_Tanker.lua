--[[ Refueling_Monitor]]
Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco", "Arco"})

-------------------------
-- AIRBOSS --
-------------------------

-- Set mission menu.
AIRBOSS.MenuF10Root=MENU_MISSION:New("Airboss").MenuPath

-- No MOOSE settings menu.
_SETTINGS:SetPlayerMenuOff()

-- tanker=RECOVERYTANKER:New(UNIT:FindByName("CVN75"), "Texaco")
-- -- tanker:SetTakeoffAir()
-- -- tanker:SetRecoveryAirboss(true)
-- tanker:SetTakeoffCold()
-- tanker:SetRadio(260)
-- tanker:SetAltitude(8000)
-- tanker:SetModex(703)
-- tanker:SetTACAN(60, "TKR")
-- tanker:__Start(120)

-- hightanker=RECOVERYTANKER:New(UNIT:FindByName("CVN75"), "Arco")
-- hightanker:SetTakeoffAir()
-- hightanker:SetRadio(268)
-- hightanker:SetAltitude(18000)
-- hightanker:SetRacetrackDistances(25, 8)
-- hightanker:SetModex(611)
-- hightanker:SetTACAN(55, "ARC")
-- hightanker:SetSpeed(350)
-- hightanker:Start()

RecoveryTankerLowSpawn = SPAWN
  :New( "RecoveryTankerLow" )
  :InitLimit( 1, 10 )
  :SpawnScheduled(1,1)

RecoveryTankerHighSpawn = SPAWN
  :New( "RecoveryTankerHigh" )
  :InitLimit( 1, 10 )
  :SpawnScheduled(1,1)

rescuehelo=RESCUEHELO:New(UNIT:FindByName("CVN75"), "Rescue Helo")
rescuehelo:SetTakeoffCold()
rescuehelo:SetRespawnInAir()
rescuehelo:SetRescueDuration(1)
rescuehelo:SetRescueHoverSpeed(5)
rescuehelo:SetRescueZone(15)
rescuehelo:SetModex(42)
rescuehelo:Start(30)

awacs=RECOVERYTANKER:New("CVN75", "Wizard")
awacs:SetAWACS()
awacs:SetTakeoffCold()
awacs:SetRadio(269)
awacs:SetAltitude(25000)
awacs:SetCallsign(CALLSIGN.AWACS.Wizard)
awacs:SetRacetrackDistances(30, 15)
awacs:SetModex(611)
awacs:SetTACAN(52, "WIZ")
awacs:__Start(150)

Truman=AIRBOSS:New("CVN75", "CVN-75 Lone Warrior")
-- Delete auto recovery window.
function Truman:OnAfterStart(From,Event,To)
  self:DeleteAllRecoveryWindows()
end

-- function Truman:OnBeforeLSOGrade(From, Event, To)

Truman:SetFunkManOn(10042, "127.0.0.1")
Truman:SetMenuRecovery(60, 27, true, 0)
Truman:Load()
Truman:SetAutoSave("C:/Users/dcs/Saved Games/DCS.LoneWarrior/Logs/trapsheets")
Truman:SetTrapSheet(TRAPSHEETLOCATION)
Truman:SetTACAN(75, "X", "LNW")
Truman:SetICLS(15,"LNW")
Truman:SetLSORadio(265,AM)
Truman:SetMarshalRadio(264, AM)
Truman:SetPatrolAdInfinitum()
Truman:SetAirbossNiceGuy()
Truman:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
Truman:SetMaxSectionSize(4)
Truman:SetMPWireCorrection(12)
Truman:SetRadioRelayLSO("LSO Huey")
Truman:SetRadioRelayMarshal("Marshal Huey")
Truman:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Truman:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
-- Truman:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
Truman:SetDespawnOnEngineShutdown()
Truman:SetRecoveryTanker(tanker)
Truman:SetMenuSingleCarrier(False)
Truman.trapsheet = false
local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes({"Recovery", "Wizard"}):FilterStart()
Truman:SetExcludeAI(CarrierExcludeSet)
Truman:Start()

-- local cvnGroup = GROUP:FindByName( "CVN75" )
-- local CVN_GROUPZone = ZONE_GROUP:New('cvnGroupZone', cvnGroup, 1111)

BLUE_CLIENT_SET = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive():FilterStart()

-- Create TARAWA AIRBOSS object.
Tarawa=AIRBOSS:New("Tarawa")
Tarawa:SetFunkManOn(10042, "127.0.0.1")
Tarawa:SetTACAN(108, "X", "LHA")
Tarawa:SetTrapSheet(TRAPSHEETLOCATION)
Tarawa:SetAutoSave("C:/Users/dcs/Saved Games/DCS.LoneWarrior/Logs/trapsheets")
Tarawa:SetICLS(8)
Tarawa:Load()
Tarawa:SetStatusUpdateTime(1)
Tarawa:SetAutoSave()
Tarawa:SetRadioUnitName("Marshal Relay Tarawa")
Tarawa:SetMarshalRadio(306)
Tarawa:SetLSORadio(306)
Tarawa:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Tarawa:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
Tarawa:SetDespawnOnEngineShutdown()
Tarawa:SetMenuSingleCarrier()
Tarawa:SetMenuRecovery(60, 20, true)
Tarawa.trapsheet = false
Tarawa:Start()

HeliAirbossMenus = AIRBOSS_HELI:New({Truman, Tarawa})


--AWACS/big wing Tankers
overlordAWACS = SPAWN
  :New("Overlord")
  :InitLimit(1,0)
  :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (overlord_51)
      overlord_51:CommandSetCallsign(1,5)
      overlord_51:CommandSetFrequency(262)
    end
  )
  overlordAWACS:Spawn()

--KC-135 Shell (North) TCN 59X - 25,000' 259.0MHz (Hornet Ch.11)
shellNorth = SPAWN
  :New("Shell North")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (shell_41)
      shell_41:CommandSetCallsign(3,4)
      shell_41:CommandSetFrequency(259)
      local sh41Beacon = shell_41:GetBeacon()
     -- sh41Beacon:AATACAN(59, "SDN", true) --edited by Circuit to get tacan working 05/01/22
      sh41Beacon:ActivateTACAN(59,"Y", "S41", true)
    end
  )
  shellNorth:Spawn()

--KC-135 Shell (South) TCN 63X - 25,000' 263.0MHz (Hornet Ch.15)
shellSouth = SPAWN
  :New("Shell South")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (shell_21)
      shell_21:CommandSetCallsign(3,2)
      shell_21:CommandSetFrequency(263)
      local sh21Beacon = shell_21:GetBeacon()
      --sh21Beacon:AATACAN(63, "SDS", true) --edited by circuit to get tacan working 05/01/22
      sh21Beacon:ActivateTACAN(63,"Y", "S21", true)
    end
  )
  shellSouth:Spawn()

--KC-135 Texaco (North Boom) TCN 61X - 26,000' 261.0MHz
texacoNorth = SPAWN
  :New("Texaco North")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (texaco_31)
      texaco_31:CommandSetCallsign(1,3)
      texaco_31:CommandSetFrequency(261)
      local tx31Beacon = texaco_31:GetBeacon() 
      --x31Beacon:AATACAN(61, "TBN", true)  --edited by circuit to get tacan working 05/01/22
      tx31Beacon:ActivateTACAN(61,"Y", "T31", true)
    end
  )
  texacoNorth:Spawn()

--KC-135 Texaco (South Boom) TCN 67X - 26,000' 267.0MHz
texacoSouth = SPAWN
  :New("Texaco South")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (texaco_21)
      texaco_21:CommandSetCallsign(1,2)
      texaco_21:CommandSetFrequency(267)
      local tx21Beacon = texaco_21:GetBeacon()
      --tx21Beacon:AATACAN(67, "TBS", true) --edited by circuit to get tacan working 05/01/22
      tx21Beacon:ActivateTACAN(67,"Y", "T21", true)
    end
  )
  texacoSouth:Spawn()

--KC-135 Texaco (East Boom) TCN 57X -12,000' 257.0 MHz
texacoEast = SPAWN:
  New("Texaco East")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (texaco_51)
      texaco_51:CommandSetCallsign(1,5)
      texaco_51:CommandSetFrequency(257)
      local tx51Beacon = texaco_51:GetBeacon()
     -- tx51Beacon:AATACAN(57, "TBE", true) --edited by circuit to get tacan working 05/01/22
      tx51Beacon:ActivateTACAN(57,"Y", "T51", true)
    end
  )
  texacoEast:Spawn()

  -- A-4 tanker south of Sochi
  Shell61 = SPAWN:
  New("Shell61")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (shell_31)
      shell_31:CommandSetCallsign(3,6)
      shell_31:CommandSetFrequency(256)
      local shell_31Beacon = shell_31:GetBeacon()
      shell_31Beacon:ActivateTACAN(56,"Y","S31",true)
    end
  )
  Shell61:Spawn()

  -- A-4 tanker east of Batumi
  Shell71 = SPAWN:
  New("Shell71")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (shell_71)
      shell_71:CommandSetCallsign(3,7)
      shell_71:CommandSetFrequency(258)
      local shell_71Beacon = shell_71:GetBeacon()
      shell_71Beacon:ActivateTACAN(58,"Y","S71",true)
    end
  )
  Shell71:Spawn()

-- Heli tanker, between Kutasi and Tsblisi
  Texaco61 = SPAWN:
  New("Texaco 6")
  :InitLimit(1,0)
  :InitKeepUnitNames()
  -- :InitRepeatOnLanding()
  :OnSpawnGroup(
    function (texaco_61)
      texaco_61:CommandSetCallsign(1,6)
      texaco_61:CommandSetFrequency(236.5)
      local texaco_61Beacon = texaco_61:GetBeacon()
      texaco_61Beacon:ActivateTACAN(55,"Y","T61",true)
    end
  )
  :Spawn()

    -- Heli tanker at Batumi
    Texaco71 = SPAWN:
    New("Texaco71")
    :InitLimit(1,0)
    :InitKeepUnitNames()
    -- :InitRepeatOnLanding()
    :OnSpawnGroup(
      function (texaco_71)
        texaco_71:CommandSetCallsign(1,7)
        texaco_71:CommandSetFrequency(237.5)
        local texaco_71Beacon =  texaco_71:GetBeacon()
        texaco_71Beacon:ActivateTACAN(54,"Y","T71",true)
      end
    )
    Texaco71:Spawn()
--[[
-------JTAC Initial Spawn------------
do
  Spawn_JTAC1 = SPAWN:New("JTAC1")
    :InitKeepUnitNames(true)
    :InitLimit(1,0)
    :InitDelayOn()
    :OnSpawnGroup(
      function( SpawnGroup1 )
        ctld.JTACAutoLase(SpawnGroup1.GroupName, 1778, false, "all")
      end
    )
    :SpawnScheduled( 60,0 )

  Spawn_JTAC2 = SPAWN:New("JTAC2")
    :InitKeepUnitNames(true)
    :InitLimit(1,0)
    :InitDelayOn()
    :OnSpawnGroup(
      function( SpawnGroup2 )
        ctld.JTACAutoLase(SpawnGroup2.GroupName, 1778, false, "all")
      end
    )
    :SpawnScheduled( 60,0 )
end
--]]

--Range
  RangeCau1=RANGE:New("Tuapse Range")
  RangeCau1:AddBombingTargetGroup(GROUP:FindByName("Russian Forces"), 50, false)
  RangeCau1:Start()

  RangeCau2=RANGE:New("X-Airstrip Range")
  RangeCau2:AddBombingTargetGroup(GROUP:FindByName("Russian Forces-1"), 50, false)
  RangeCau2:Start()

  local clawrtargets={"CLAWR Range", "CLAWR Range-1", "CLAWR Range-2", "CLAWR Range-3", "CLAWR Range-4", "CLAWR Range-5", "CLAWR Range-6", "CLAWR Range-7", "CLAWR Range-8", "CLAWR Range-9", "CLAWR Range-10", "CLAWR Range-11", "CLAWR Range-11", "CLAWR Range-12", "CLAWR Range-13", "CLAWR Range-14"}
  local strafepit={"CLAWR Strafe Pit"}
  RangeCAU3=RANGE:New("CLAWR Range")
  RangeCAU3:AddBombingTargets(clawrtargets)
  RangeCAU3:AddStrafePit(strafepit,3000,300,nil,true,20,fouldist)
  RangeCAU3:Start()