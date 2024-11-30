-- Debuging
--[[
BASE:TraceOnOff(true)
BASE:TraceLevel(1)
BASE:TraceClass('RNT')
-- BASE:TraceClass('SET_ZONE')
-- BASE:TraceClass('SET_GROUP')
-- --]]

--#region Random Naval Traffic
RNT = {
    ClassName           = "RNT",
    lid                 = '',
    
    debug               = false,
    debugMarkID         = {},               -- Mark IDs for drawing debug cirlces on waypoint change
    
    zones               = nil,              -- SET_ZONE of all the zones used for spawn and waypoint locations
    zonePrefixes        = '',               -- Prefixes useed to build zones set
    zonesTable          = {},               -- Table of zones
    
    templates           = nil,              -- SET_GROUP of the templates used to create the traffic
    templatePrefixes    = '',               -- Prefixes used to build group set
    templatesTable      = {},               -- Table of templates
    
    navalTrafficGroups  = {},               -- table of NAVYGROUPs
    
    pathfindingOn       = false,            -- Path finding ooff by default
    pathfindingCorridor = 0,                -- Corridor width to use if pathfinding is turned on
    randomizeSpawnPoint = false,            -- Randomly pick a zone when spawning, otherwise spawn where template is in ME
    maxGroupCount       = 1,                -- Total number of groups to spawn
    delayBetweenSpawns  = 1,                -- Time between spawns
}

RNT.version = "0.0.1"


function RNT:New(Name, ZonePrefixes, TemplatePrefixes)
    local self = BASE:Inherit(self, FSM:New())
    
    if Name == nil or Name == '' then
        self:E('Must provide a name.')
        return nil
    end

    if type(ZonePrefixes) ~= "table" then
        ZonePrefixes = { ZonePrefixes }
    end
    
    if type(TemplatePrefixes) ~= "table" then
        TemplatePrefixes = { TemplatePrefixes }
    end

    if not ZonePrefixes or not TemplatePrefixes then
        self:E('Must provide a Name, ZonePrefixes and TemplatePrefixes')
        return nil
    end

    self.name = Name or "RNT"
    -- Set the string id for output to DCS.log file.
    self.lid=string.format("RNT %s | ", self.name)
    self.templatePrefixes = TemplatePrefixes
    self.zonePrefixes = ZonePrefixes

    -- Build the zone and template sets based on prefix and build the tables
    self.zones = SET_ZONE:New()
        :FilterPrefixes(self.zonePrefixes)
        :FilterOnce()
    
    self.zones:ForEachZone(function(zone)
        table.insert(self.zonesTable, zone)
    end)
    self:T(string.format("%sZone count:%d", self.lid, tostring(self.zones:Count())))

    self.templates = SET_GROUP:New()
        :FilterPrefixes(self.templatePrefixes)
        :FilterOnce()

    self.templates:ForEachGroup(function(group)
        table.insert(self.templatesTable, group:GetName())
    end)
    self:T(string.format("%sTemplates count:%d", self.lid, tostring(self.templates:Count())))

    self:AddTransition("*",     "PassWaypoint",        "*")
    self:AddTransition("*",     "UpdateRoute",         "*")

    self:I(self.name.." Random Naval Traffic | Starting RNT v"..self.version)

    return self
end

function RNT:Start()
    local zones = self.zones

    local navalSpawn = SPAWN:NewWithAlias(self.templatesTable[1], self.name)
        :OnSpawnGroup(function(group)
            local groupName = group:GetName()

            self:T('Spwan groupName: '..tostring(groupName))

            if groupName then
                self.navalTrafficGroups[groupName] = NAVYGROUP:New(groupName)
                                                :SetPathfinding(self.pathfindingOn, self.pathfindingCorridor)
                                                :SetPatrolAdInfinitum(false)
                                                :Activate()

                local navalGroup = self.navalTrafficGroups[groupName]
                local randomZoneCoord = zones:GetRandom():GetCoordinate()

                navalGroup:AddWaypoint(randomZoneCoord, 40)

                if self.debug == true then
                    navalGroup:SetVerbosity(1)
                    self.debugMarkID[groupName] = UTILS:GetMarkID()
                    self:_debugMarkWaypoint(groupName, randomZoneCoord)
                end

                function navalGroup:OnAfterUpdateRoute(From, Event, To, n, Speed, Depth)
                    self:T('OnAfterUpdateRoute')
                end

                function navalGroup:OnAfterPassingWaypoint(From, Event, To, Waypoint)
                    self:T('OnAfterPassingWaypoint')
                    local grpName = self:GetGroup():GetName()
                    local randomZone = zones:GetRandom()
                    
                    self:AddWaypoint(randomZone:GetCoordinate(), 39)

                    if self.debug == true then
                        self:_debugMarkWaypoint(grpName, randomZone:GetCoordinate())
                    end
                end

                function navalGroup:OnAfterCollisionWarning(From, Event, To, Distance)
                    self:T('OnAfterCollisionWarning')
                    self:T('Distance: '..Distance)
                end

                function navalGroup:OnAfterCruise(From, Event, To, Speed)
                    self:T('OnAfterCruise')
                    if Speed then
                        self:T('Cruise speed: '..Speed)
                    else
                        self:T('No Cruise speed avail.')
                    end
                end
            end
        end)
        :InitRandomizeTemplate(self.templatesTable)
        :InitLimit(self.maxGroupCount * 4, self.maxGroupCount)
        
    if self.randomizeSpawnPoint == true then
        navalSpawn:InitRandomizeZones(self.zonesTable)
    end

    navalSpawn:SpawnScheduled(self.delayBetweenSpawns, 0)

    return self
end

function RNT:_debugMarkWaypoint(groupName, coord)
    self:T(self.lid.."_debugMarkWaypoint")
    self:T(string.format('Group name:%s ', groupName))

    trigger.action.removeMark(self.debugMarkID[groupName])

    self.debugMarkID[groupName] = UTILS:GetMarkID()
    
    trigger.action.circleToAll(-1, self.debugMarkID[groupName], coord:GetVec3(), 2000, {0,1,0,1}, {0,1,0,.1}, 1) -- Green circle

    return self
end

function RNT:InitSpawnInRandomZones()
    self:T(self.lid.."InitSpawnInRandomZones")

    self.randomizeSpawnPoint = true

    return self
end

function RNT:InitDelayBetweenSpawns(Delay)
    self:T(self.lid.."InitDelayBetweenSpawns")

    if type(Delay) ~= 'number' then
        self:E('Delay must be a number')
    elseif Delay < 0 then
        self:E('Delay must be equal to or greater than 0')
    else
        self.delayBetweenSpawns = Delay
    end
    

    return self
end

function RNT:SetMaxGroupCount(MaxGroupCount)
    self:T(self.lid.."SetMaxGroup")

    if type(MaxGroupCount) ~= 'number' then
        self:E('MaxGroupCount must be a number')
    elseif MaxGroupCount < 1 then
        self:E('MaxGroupCount must be greater than 0')
    else
        self.maxGroupCount = MaxGroupCount
    end

    return self
end

function RNT:SetPathfindingOn(Distance)
    self:T(self.lid..'SetPathfindingOn')

    if type(Distance) ~= 'number' then
        self:E('Distance must be a number.')
    elseif Distance < 0 then
        self:E('Distance must be greater then 0.')
    else
        self.pathfindingOn = true
        self.pathfindingCorridor = Distance
    
        -- For each NAVYGROUP set pathfinding to the given distance.
        for _, navyGroup in pairs(self.navalTrafficGroups) do
            navyGroup:SetPathfindingOn(Distance)
        end
    end

    return self
end

function RNT:SetPathfindingOff()
    self:T(self.lid..'SetPathingfindingOff')

    self.pathfindingOn = false
    self.pathfindingCorridor = 0

    -- For each NAVYGROUP set pathfinding to the given distance.
    for _, navyGroup in pairs(self.navalTrafficGroups) do
        navyGroup:SetPathfindingOff()
    end

    return self
end

function RNT:DebugOn()
    self:T(self.lid.."DebugOn")
    self.debug = true

    return self
end

function RNT:DebugOff()
    self:T(self.lid.."DebugOff")
    self.debug = false

    return self
end
