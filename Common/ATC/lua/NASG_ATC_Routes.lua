NASG_ATC = NASG_ATC or {}

NASG_ATC.Routes = NASG_ATC.Routes or {}
NASG_ATC.RouteAliases = NASG_ATC.RouteAliases or {}

function NASG_ATC:NormalizeRouteText(text)
    local value = tostring(text or "")

    value = string.lower(value)
    value = value:gsub("[,%./%-]", " ")
    value = value:gsub("%s+", " ")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")

    return value
end

function NASG_ATC:RegisterRoute(route)
    if not route or not route.Id then
        self:Log("RegisterRoute ignored route without Id")
        return nil
    end

    route.Aliases = route.Aliases or {}
    route.Name = route.Name or route.Id
    route.Type = route.Type or route.ProcedureType or "route"

    self.Routes[route.Id] = route

    local aliases = {}

    aliases[#aliases + 1] = route.Id
    aliases[#aliases + 1] = route.Name

    if route.ShortName then
        aliases[#aliases + 1] = route.ShortName
    end

    if route.ProcedureCode then
        aliases[#aliases + 1] = route.ProcedureCode
    end

    for _, alias in ipairs(route.Aliases or {}) do
        aliases[#aliases + 1] = alias
    end

    for _, alias in ipairs(aliases) do
        local normalizedAlias = self:NormalizeRouteText(alias)

        if normalizedAlias ~= "" then
            self.RouteAliases[normalizedAlias] = route.Id
        end
    end

    self:Log("Registered ATC route: " .. tostring(route.Id) .. " name=" .. tostring(route.Name))
    return route
end

function NASG_ATC:RegisterRoutes(routes)
    for _, route in ipairs(routes or {}) do
        self:RegisterRoute(route)
    end
end

function NASG_ATC:GetRoute(routeId)
    if not routeId then
        return nil
    end

    return self.Routes[tostring(routeId)]
end

function NASG_ATC:FindRequestedRoute(rawText, airport)
    local text = self:NormalizeRouteText(rawText)

    if text == "" then
        return nil
    end

    local bestRoute = nil
    local bestLength = -1

    for alias, routeId in pairs(self.RouteAliases or {}) do
        if alias ~= "" and string.find(text, alias, 1, true) then
            if string.len(alias) > bestLength then
                local route = self:GetRoute(routeId)

                if route and self:IsRouteAvailableAtAirport(route, airport) then
                    bestRoute = route
                    bestLength = string.len(alias)
                end
            end
        end
    end

    return bestRoute
end

function NASG_ATC:IsRouteAvailableAtAirport(route, airport)
    if not route then
        return false
    end

    if not airport then
        return true
    end

    local airportId = self:NormalizeRouteText(airport.Id or airport.ICAO or airport.Name)
    local airportIcao = self:NormalizeRouteText(airport.ICAO or airport.Id or airport.Name)

    for _, value in ipairs(route.AssociatedAirports or route.Airports or {}) do
        local normalizedValue = self:NormalizeRouteText(value)

        if normalizedValue == airportId or normalizedValue == airportIcao then
            return true
        end
    end

    if route.AirportId then
        local routeAirportId = self:NormalizeRouteText(route.AirportId)

        if routeAirportId == airportId or routeAirportId == airportIcao then
            return true
        end
    end

    -- If no airport restriction is defined, make it globally available.
    if not route.AirportId and not route.AssociatedAirports and not route.Airports then
        return true
    end

    return false
end

function NASG_ATC:IsDepartureRoute(route)
    return route and (
            route.Type == "sid"
                    or route.Type == "stereo_departure"
                    or route.Type == "departure"
                    or route.ProcedureType == "sid"
                    or route.ProcedureType == "stereo_departure"
                    or route.ProcedureType == "departure"
    )
end

function NASG_ATC:IsRecoveryRoute(route)
    return route and (
            route.Type == "star"
                    or route.Type == "stereo_recovery"
                    or route.Type == "recovery"
                    or route.ProcedureType == "star"
                    or route.ProcedureType == "stereo_recovery"
                    or route.ProcedureType == "recovery"
    )
end

function NASG_ATC:BuildClearedRoute(route, facility, source)
    if not route then
        return nil
    end

    return {
        Id = route.Id,
        Name = route.Name,
        Type = route.Type or route.ProcedureType,
        ProcedureCode = route.ProcedureCode,
        ShortName = route.ShortName,
        ClearedBy = facility,
        ClearedAt = timer.getTime(),
        Source = source or "voice",
    }
end

NASG_ATC:Log("NASG_ATC_Routes loaded")