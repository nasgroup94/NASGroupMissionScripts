NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Center-tracked points: named locations pilots can request vectors to
-- that aren't flight-plan waypoints (tankers, bullseye, objectives,
-- range entry points, etc.). Registered by mission data
-- (CVW-17/.../NATO/Persian_Gulf_ATC_TrackedPoints.lua) via
-- NASG_ATC:RegisterTrackedPoint. A point resolves to a live DCS
-- unit/group/static's current position when given, else a fixed
-- coordinate.
---------------------------------------------------------------------------

NASG_ATC.TrackedPoints = NASG_ATC.TrackedPoints or {}
NASG_ATC.TrackedPointsByLookup = NASG_ATC.TrackedPointsByLookup or {}

function NASG_ATC:RegisterTrackedPointLookup(value, point)
    local key = self:NormalizeFlightPlanLookup(value)

    if key and key ~= "" then
        self.TrackedPointsByLookup[key] = point
    end
end

function NASG_ATC:RegisterTrackedPoint(def)
    if not def or not def.Id then
        error("RegisterTrackedPoint requires a definition with an Id")
    end

    self.TrackedPoints[def.Id] = def

    self:RegisterTrackedPointLookup(def.Id, def)
    self:RegisterTrackedPointLookup(def.Name, def)

    for _, alias in ipairs(def.Aliases or {}) do
        self:RegisterTrackedPointLookup(alias, def)
    end

    self:Log("Registered tracked point: " .. tostring(def.Id))

    return def
end

function NASG_ATC:FindTrackedPoint(value, airportId)
    local key = self:NormalizeFlightPlanLookup(value)

    if key == "" then
        return nil
    end

    local point = self.TrackedPointsByLookup[key]

    if not point then
        local keys = {}

        for lookupKey in pairs(self.TrackedPointsByLookup) do
            keys[#keys + 1] = lookupKey
        end

        local fuzzyKey = self:FuzzyMatchLookupKey(key, keys)

        if fuzzyKey then
            self:Log(string.format("Fuzzy-matched tracked point request '%s' to '%s'", key, fuzzyKey))
            point = self.TrackedPointsByLookup[fuzzyKey]
        end
    end

    if not point then
        return nil
    end

    if airportId and point.AirportId and point.AirportId ~= airportId then
        return nil
    end

    return point
end

-- Resolves a tracked point's current coordinate: a live unit/group/static
-- takes priority (pcall-wrapped so a dead/missing object degrades to nil
-- rather than erroring); a fixed x/z or lat/lon coordinate is the fallback.
function NASG_ATC:GetTrackedPointCoordinate(point)
    if not point then
        return nil
    end

    if point.UnitName and UNIT then
        local ok, unit = pcall(function() return UNIT:FindByName(point.UnitName) end)

        if ok and unit then
            local coordOk, coordinate = pcall(function() return unit:GetCoordinate() end)

            if coordOk and coordinate then
                return coordinate
            end
        end
    end

    if point.GroupName and GROUP then
        local ok, group = pcall(function() return GROUP:FindByName(point.GroupName) end)

        if ok and group then
            local coordOk, coordinate = pcall(function() return group:GetCoordinate() end)

            if coordOk and coordinate then
                return coordinate
            end
        end
    end

    if point.StaticName and STATIC then
        local ok, static = pcall(function() return STATIC:FindByName(point.StaticName) end)

        if ok and static then
            local coordOk, coordinate = pcall(function() return static:GetCoordinate() end)

            if coordOk and coordinate then
                return coordinate
            end
        end
    end

    if NASG_ATC_NAVIGATION then
        return NASG_ATC_NAVIGATION:GetWaypointCoordinate(point)
    end

    return nil
end

NASG_ATC:Log("NASG_ATC_TrackedPoints loaded")
