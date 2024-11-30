-- --[[
--     General missions ops
-- --]]

-- Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('AIRWING')

-- Create the AirWing
CVW7_Airwing = AIRWING:New("CVN75", "CVW 7 Airwing")
CVW7_Airwing:Start()
VF103=SQUADRON:New("Victory-3", 8, "VF-103 (Jolly Rogers)")
VF103:AddMissionCapability({AUFTRAG.Type.ESCORT, AUFTRAG.Type.INTERCEPT})
CVW7_Airwing:AddSquadron(VF103)
CVW7_Airwing:NewPayload(UNIT:FindByName('Victory-3-1'), 4, {AUFTRAG.Type.INTERCEPT}, 100)
CVW7_Airwing:NewPayload(UNIT:FindByName('Victory-2-1'), 4, {AUFTRAG.Type.ESCORT}, 100)


--[[
    Ops Alert 5 Intercept
--]]
Auftrag_Alert5_Intercept = nil

-- Launches the Alert 5 to intercept anything in the CSG Defensive xone
function Ops_Alert5()
    local found_bogeys = false
    local home_airbase = AIRBASE:FindByName('CVN75')

    -- Find all the RED aircraft in zone
    local csg_defensive_zone = ZONE_UNIT:New('CSG Defensive Zone', UNIT:FindByName('CVN75'), 121920) -- 121920
    local bogeys = SET_GROUP:New():FilterCoalitions("red"):FilterCategories("plane"):FilterActive():FilterOnce()
    if bogeys:CountAlive() > 0 then
        found_bogeys = true
        bogeys:ForEachGroupPartlyInZone( csg_defensive_zone,
            function( GroupObject )
                GroupObject:E( { GroupObject:GetName(), "I am partially in Zone" } )
                Auftrag_Alert5_Intercept = AUFTRAG:NewINTERCEPT(GroupObject):SetMissionRange(300)
                CVW7_Airwing:AddMission(Auftrag_Alert5_Intercept)
            end )
    end
    if not found_bogeys then
        MESSAGE:New('No enemy threats in the CSG area.', 10, 'Alert', true):ToCoalition(coalition.side.BLUE)
    end
end


--[[
    Prowler Ops
--]]
Prowler_1 = FLIGHTGROUP:New('Prowler-1')  -- Prowler cruise


-- -- Launches the Prowler from the deck with 2 x F14s as escort.
function Ops_Prowler()
    Prowler_1 = FLIGHTGROUP:New('Prowler-1')  -- Prowler cruise

    -- Set the carrier for home base of both flights.
    local home_airbase = AIRBASE:FindByName('CVN75')

    -- Set up the Prowler flight group and activate it.
    Prowler_1:SetHomebase(home_airbase)
    Prowler_1:SetAirboss(Truman)
    Prowler_1:Activate()

    -- Assign the F14s to escort the prowler and submit mission.
    Auftrag_Escort_Prowler = AUFTRAG:NewESCORT(Prowler_1:GetGroup(), {x=-100, y=1828, z=200}, 5, {'Air'})
    CVW7_Airwing:AddMission(Auftrag_Escort_Prowler)
end

-- After the Prowler is back to the ship, cancel the mission and assign both flights as clear to land.
function Prowler_1:onafterHolding(From, Event, To)
    env.info('VNAO: BlackSea_Ops: Prowler_1:onafterHolding: Prowler_1 is now in holding.')
    Auftrag_Escort_Prowler:Cancel()
    -- Nickel_2:ClearToLand()
    Prowler_1:ClearToLand()
end

function Prowler_1:onafterStop(From, Event, To)
    Prowler_1 = FLIGHTGROUP:New('Prowler-1')
end


--[[ COD Ops
cod_1 = RAT:New('Cod-1', 'COD')
cod_1:SetDeparture('Kobuleti')
cod_1:SetDestination('CVN75')
cod_1:SetMaxCruiseSpeed(240)
cod_1:SetTakeoffCold()
cod_1:SetFLmax(120)
cod_1:SetFLmin(80)
cod_1:SetFLcruise(110)
cod_1:Commute()
cod_1:SetSpawnDelay(90)
cod_1:Spawn(1)
--]]

-- Create menu items 
Launch_Event_Menu = MENU_MISSION:New('Launch events', mainMenu)
Launch_Prowler_Menu = MENU_MISSION_COMMAND:New('Launch the Prowler...', Launch_Event_Menu, Ops_Prowler)
Launch_Alert5_Menu = MENU_MISSION_COMMAND:New('Launch the Alert 5...', Launch_Event_Menu, Ops_Alert5)

