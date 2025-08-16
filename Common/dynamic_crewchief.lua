-- dynamic_crewchief.lua
-- version: 3.0

-- 4 late activated units from the MASSUN92´s ASSET PACK to be added to the miz. 
-- These unit should be in their own group, in other words, one unit per group with the following
-- group names (unit names do not matter)
    -- 1 x M92_personnel_salute with group name "Crewchief"
    -- 2 x M92_personnel_giving directives with group names "Crewchief-support-1" and "Crewchief-support-3"
    -- 1 x M92_personnel_crouch worker with group name "Crewchief-support-2"



-- The height range difference (in meters) that a crew member can spawn in and still be considered at the same level
-- of the client unit.  
-- If the crew member spawns within this height range, then it is ok.
-- If the crew member spawns outside this height range, it will be immediately destroyed.
-- There is issues where if a client unit is spawned in a shelter, the crew members get spawned
-- on top of the shelter. If this is the case, just destroy the crew member and it won't be shown at all.
-- Change this value as needed if you are not seeing correct results.
local good_height_range = 0.1

local newClient = EVENTHANDLER:New()
newClient:HandleEvent(EVENTS.PlayerEnterAircraft)

BASE:I("Dynamic Crewchief loading.")

-- Run every time a new client spawns at an airbase
function newClient:OnEventPlayerEnterAircraft(EventData)
    BASE:I("------------ newClient:OnEventPlayerEnterAircraft() called for " .. EventData.IniPlayerName)
    -- BASE:I("Client spawned at airbase: " .. newClient:Name())
    -- You can add additional logic here if needed
    local set_client = SET_CLIENT:New():FilterCategories({"plane","helicopter"}):FilterStart()
    set_client:ForEachClient(function(_client)
        set_client:I("------------ _client:ForEachClient() called for " .. _client:Name())

        _client:Alive(function()
            set_client:I("------------ _client:Alive()")

            local client_unit = _client:GetClientGroupUnit()
            local client_is_airborne = client_unit:InAir() or false
            local client_category =  client_unit:GetCategoryName()

            set_client:I("------------ client airborne:" .. tostring(client_is_airborne) .. " client_category:" .. client_category)

            -- Only draw the crew if client is in an aircraft/helicopter and on the ground.
            if client_is_airborne == false and (client_category == "Airplane" or client_category == "Helicopter") then

                -- CALCULATE SPAWNED AIRCRAFTS POSITION AND CALCULATE NEW POSITIONS AND HEADINGS    
                local client_name = _client:Name()
                local client_heading = _client:GetHeading()
                local client_coalition = _client:GetCountry()
                local client_coordinate = _client:GetCoordinate()
                local client_airbase = client_coordinate:GetClosestAirbase()
                local client_airbase_type = client_airbase:GetAirbaseCategory()

                if client_airbase_type == 0 then
                    set_client:I("------------ client_airbase = 0")


                    client_unit:HandleEvent(EVENTS.PlayerLeaveUnit)
                    client_unit:HandleEvent(EVENTS.Crash)
                    client_unit:HandleEvent(EVENTS.PilotDead)

                    local crewchief_livery = {"variation 1", "variation 2", "variation 3", "variation 4", "variation 5"}

                    local the_crew = {
                        chief = {
                            --crewchief located front left (will salute)
                            spawn_group_name = "Crewchief", -- mission editor group name
                            crew_group = nil,
                            radial_from_aircraft = 335, -- the angle from center of aircraft to place the crew member
                            distance_from_aircraft = 17, -- the distance from center of aircraft to place the crew member
                            look_heading = 90, -- which direction the crew member should be looking
                            state_motion = "Red",
                            state_normal = "Green"

                        },
                        support1 = {
                            -- crew member left rear (will point)
                            spawn_group_name = "Crewchief-support-1", -- mission editor group name
                            crew_group = nil,
                            radial_from_aircraft = 210, -- the angle from center of aircraft to place the crew member
                            distance_from_aircraft = 12, -- the distance from center of aircraft to place the crew member
                            look_heading = 20, -- which direction the crew member should be looking
                            state_motion = "Green",
                            state_normal = "Green"
                        },
                        support2 = {
                            -- crew member right rear (crouched)
                            spawn_group_name = "Crewchief-support-2", -- mission editor group name
                            crew_group = nil,
                            radial_from_aircraft = 150, -- the angle from center of aircraft to place the crew member
                            distance_from_aircraft = 10, -- the distance from center of aircraft to place the crew member
                            look_heading = 310, -- which direction the crew member should be looking
                            state_motion = "Auto",
                            state_normal = "Red"
                        },
                        support3 = {
                            -- crew member right side (will point)
                            spawn_group_name = "Crewchief-support-3", -- mission editor group name
                            crew_group = nil,
                            radial_from_aircraft = 75, -- the angle from center of aircraft to place the crew member
                            distance_from_aircraft = 10, -- the distance from center of aircraft to place the crew member
                            look_heading = 275, -- which direction the crew member should be looking
                            state_motion = "Red",
                            state_normal = "Auto"
                        }
                    }

                    local function destroy_crew()
                        for _, crew_member in pairs(the_crew) do
                            -- set_client:I("------------ destroying " .. crew_member.spawn_group_name)
                            crew_member.crew_group:Destroy(nil, 0)
                        end
                        
                        client_unit:UnHandleEvent(EVENTS.PlayerLeaveUnit)
                        client_unit:UnHandleEvent(EVENTS.Crash)
                        client_unit:UnHandleEvent(EVENTS.PilotDead)
                    end

                    local function destroy_crew_member(member)
                        member:Destroy(nil, 0)
                    end

                    -- grab a random livery
                    local random_livery = math.random(#crewchief_livery)

                    local height_max_range = client_coordinate.y + good_height_range
                    local height_min_range = client_coordinate.y - good_height_range
                    -- set_client:I("------------ Client height:" .. client_coordinate.y)
                    -- set_client:I("------------ Crew height min:" .. height_min_range .. " max:" .. height_max_range)

                    -- spawn all the crew members
                    for _, crew_member in pairs(the_crew) do
                        -- set_client:I("------------ trying to spawn " .. crew_member.spawn_group_name)

                        local crew_member_spawn_alias = crew_member.spawn_group_name .. "_" .. client_name
                        local crew_member_spawn_heading = math.fmod(client_heading + crew_member.look_heading, 360)
                        -- local crew_member_spawn_livery = crewchief_livery[random_livery]
                        local crew_member_spawn_coordinate = client_coordinate:Translate(crew_member.distance_from_aircraft, client_heading + crew_member.radial_from_aircraft)

                        SPAWN:NewWithAlias(crew_member.spawn_group_name, crew_member_spawn_alias)
                            :OnSpawnGroup(function(spawnGroup)
                                crew_member.crew_group = spawnGroup

                                set_client:I("------------ " .. crew_member.spawn_group_name .. " height:" .. spawnGroup:GetCoordinate().y)

                                -- Check if crew member is spawned within the good_height_range of the client, if not, destroy it.
                                if (height_max_range < spawnGroup:GetCoordinate().y) then
                                        -- set_client:I("------------ Crew member not on ground, removing " .. crew_member.spawn_group_name)
                                        destroy_crew_member(spawnGroup)
                                end
                            end)
                            :InitHeading(crew_member_spawn_heading)
                            :InitLivery(crew_member_spawn_livery)
                            :InitCountry(client_coalition)
                            :SpawnFromCoordinate(crew_member_spawn_coordinate)
                    end

                    local function check_moving()
                        -- set_client:I("------------ scheduler tick")
                        
                        -- Make sure Client is still valid. Had issues when choosing a new role that "PlayerLeaveUnit" event didn't fire yet.
                        if client_unit:IsAlive() then
                            local clientcoordinate = client_unit:GetCoordinate()
                            local distance = clientcoordinate:Get3DDistance(client_coordinate)
                            local airspeed = client_unit:GetVelocityKNOTS()
                            if distance < 15 and airspeed >= 2  then
                                -- set_client:I("------------ check_moving: distance < 15")
                                for _, crew_member in pairs(the_crew) do
                                    if crew_member.state_motion == "Auto" then
                                        crew_member.crew_group:OptionAlarmStateAuto()
                                    elseif crew_member.state_motion == "Green" then
                                        crew_member.crew_group:OptionAlarmStateGreen()
                                    elseif crew_member.state_motion == "Red" then
                                        crew_member.crew_group:OptionAlarmStateRed()
                                    end
                                end
                                client_given_salute = true
                                SCHEDULER:New(nil, check_moving, {}, 1)
                            elseif distance > 15 then
                                -- set_client:I("------------ check_moving: distance > 15")
                                for _, crew_member in pairs(the_crew) do
                                    if crew_member.state_normal == "Auto" then
                                        crew_member.crew_group:OptionAlarmStateAuto()
                                    elseif crew_member.state_normal == "Green" then
                                        crew_member.crew_group:OptionAlarmStateGreen()
                                    elseif crew_member.state_normal == "Red" then
                                        crew_member.crew_group:OptionAlarmStateRed()
                                    end
                                end
                                SCHEDULER:New(nil, destroy_crew, {}, 60)
                            else
                                -- set_client:I("------------ check_moving: waiting")
                                for _, crew_member in pairs(the_crew) do
                                    if crew_member.state_normal == "Auto" then
                                        crew_member.crew_group:OptionAlarmStateAuto()
                                    elseif crew_member.state_normal == "Green" then
                                        crew_member.crew_group:OptionAlarmStateGreen()
                                    elseif crew_member.state_normal == "Red" then
                                        crew_member.crew_group:OptionAlarmStateRed()
                                    end
                                end
                                SCHEDULER:New(nil, check_moving, {}, 1)
                            end
                        end
                    end

                    SCHEDULER:New(nil, check_moving, {}, 1)

                    function client_unit:OnEventPlayerLeaveUnit(EventData)
                        destroy_crew()
                    end

                    function client_unit:OnEventCrash(EventData)
                        destroy_crew()
                    end

                    function client_unit:OnEventPilotDead(EventData)
                        destroy_crew()
                    end
                end
            end
        end)
    end)
end



BASE:I("Dynamic Crewchief loaded.")
