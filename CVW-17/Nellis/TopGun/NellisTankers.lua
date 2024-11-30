
--Tanker,AWAC and JTAC objects


Spawn_Awacs = SPAWN:New("Magic"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Texaco_North = SPAWN:New("Texaco North"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Texaco_West = SPAWN:New("Texaco West"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Texaco_East = SPAWN:New("Texaco East"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Arco_North = SPAWN:New("Arco North"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Arco_West = SPAWN:New("Arco West"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

Spawn_Arco_East = SPAWN:New("Arco East"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

-- Spawn_Texaco_RWest = SPAWN:New("Texaco Red West"):InitLimit(1,0)
-- :InitRepeatOnLanding()
-- :SpawnScheduled(60,0)

-- Spawn_Arco_RWest = SPAWN:New("Arco Red West"):InitLimit(1,0)
-- :InitRepeatOnLanding()
-- :SpawnScheduled(60,0)

Spawn_Awacs_Red = SPAWN:New("Darkstar"):InitLimit(1,0)
:InitRepeatOnLanding()
:SpawnScheduled(60,0)

-- Spawn_JTAC1 = SPAWN:New("JTAC1")
--     :InitKeepUnitNames(true)
--     :InitLimit(1,0)
--     :OnSpawnGroup(
--      function( SpawnGroup )
--         ctld.JTACAutoLase(SpawnGroup.GroupName, 1388, false, "all")        
--      end 
--      )
--     :SpawnScheduled( 60,0 )
    
-- Spawn_JTAC2 = SPAWN:New("JTAC2")
--     :InitKeepUnitNames(true)
--     :InitLimit(1,0)
--     :OnSpawnGroup(
--      function( SpawnGroup )
--         ctld.JTACAutoLase(SpawnGroup.GroupName, 1488, false, "all")        
--      end 
--      )
--     :SpawnScheduled( 60,0 )

-- Spawn_JTAC3 = SPAWN:New("JTAC3")
--     :InitKeepUnitNames(true)
--     :InitLimit(1,0)
--     :OnSpawnGroup(
--      function( SpawnGroup )
--         ctld.JTACAutoLase(SpawnGroup.GroupName, 1588, false, "all")        
--      end 
--      )
--     :SpawnScheduled( 60,0 )
	
	
	--assert(loadfile("C:/HypeMan/mission_script_loader.lua"))()
	--HypeMan.sendBotMessage('HypeMan standing by in the Persian Gulf.......with Vipers.')



