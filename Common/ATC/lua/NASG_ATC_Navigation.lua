NASG_ATC_NAVIGATION = NASG_ATC_NAVIGATION or {}

function NASG_ATC_NAVIGATION:NormalizeHeading(heading)
    local value = tonumber(heading or 0) or 0

    value = value % 360

    if value < 0 then
        value = value + 360
    end

    if value == 0 then
        return 360
    end

    return value
end

function NASG_ATC_NAVIGATION:HeadingDifference(fromHeading, toHeading)
    local diff = (tonumber(toHeading or 0) or 0) - (tonumber(fromHeading or 0) or 0)

    while diff > 180 do
        diff = diff - 360
    end

    while diff < -180 do
        diff = diff + 360
    end

    return diff
end

function NASG_ATC_NAVIGATION:MetersToNM(meters)
    return (tonumber(meters or 0) or 0) / 1852
end

function NASG_ATC_NAVIGATION:NMToMeters(nm)
    return (tonumber(nm or 0) or 0) * 1852
end

function NASG_ATC_NAVIGATION:FormatHeading(heading)
    local value = math.floor(self:NormalizeHeading(heading) + 0.5)

    if value >= 360 then
        value = 360
    end

    if value <= 0 then
        value = 360
    end

    return string.format("%03d", value)
end

function NASG_ATC_NAVIGATION:GetWaypointCoordinate(waypoint)
    if not waypoint then
        return nil
    end

    local x = waypoint.dcs_x or waypoint.DcsX or waypoint.x or waypoint.X
    local z = waypoint.dcs_z or waypoint.DcsZ or waypoint.z or waypoint.Z

    if x and z and COORDINATE and COORDINATE.NewFromVec2 then
        return COORDINATE:NewFromVec2({ x = tonumber(x), y = tonumber(z) })
    end

    local lat = waypoint.lat or waypoint.Lat or waypoint.latitude or waypoint.Latitude
    local lon = waypoint.lon or waypoint.Lon or waypoint.longitude or waypoint.Longitude

    if lat and lon and COORDINATE then
        if COORDINATE.NewFromLLDD then
            return COORDINATE:NewFromLLDD(tonumber(lat), tonumber(lon))
        end

        if COORDINATE.New then
            return COORDINATE:New(tonumber(lat), tonumber(lon))
        end
    end

    return nil
end

function NASG_ATC_NAVIGATION:GetBearingDistance(fromCoord, toCoord)
    if not fromCoord or not toCoord then
        return nil
    end

    return {
        Bearing = fromCoord:GetHeading(toCoord),
        DistanceMeters = fromCoord:Get2DDistance(toCoord),
        DistanceNM = self:MetersToNM(fromCoord:Get2DDistance(toCoord)),
    }
end

function NASG_ATC_NAVIGATION:AnalyzeLeg(startCoord, endCoord, aircraftCoord, maxLateralErrorMeters)
    if not startCoord or not endCoord or not aircraftCoord then
        return nil
    end

    local totalDistance = startCoord:Get2DDistance(endCoord)
    local distanceToAircraft = startCoord:Get2DDistance(aircraftCoord)

    local legBearing = startCoord:GetHeading(endCoord)
    local aircraftBearingFromStart = startCoord:GetHeading(aircraftCoord)

    local deltaHeading = self:HeadingDifference(legBearing, aircraftBearingFromStart)

    local angleRad = math.rad(deltaHeading)
    local lateralError = distanceToAircraft * math.sin(angleRad)
    local alongTrack = distanceToAircraft * math.cos(angleRad)

    local onSegment = alongTrack >= 0 and alongTrack <= totalDistance
    local withinLateralLimit = math.abs(lateralError) <= maxLateralErrorMeters

    return {
        OnSegment = onSegment,
        WithinLateralLimit = withinLateralLimit,
        OnTrack = onSegment and withinLateralLimit,
        LateralErrorMeters = lateralError,
        LateralErrorAbsMeters = math.abs(lateralError),
        LateralErrorNM = self:MetersToNM(math.abs(lateralError)),
        AlongTrackMeters = alongTrack,
        AlongTrackNM = self:MetersToNM(alongTrack),
        TotalDistanceMeters = totalDistance,
        TotalDistanceNM = self:MetersToNM(totalDistance),
        DistanceRemainingMeters = math.max(totalDistance - alongTrack, 0),
        DistanceRemainingNM = self:MetersToNM(math.max(totalDistance - alongTrack, 0)),
        LegBearing = legBearing,
        AircraftBearingFromStart = aircraftBearingFromStart,
        DeltaHeading = deltaHeading,
    }
end

function NASG_ATC_NAVIGATION:GetInterceptHeading(analysis, interceptDegrees)
    if not analysis then
        return nil
    end

    local intercept = tonumber(interceptDegrees or 30) or 30
    local heading = tonumber(analysis.LegBearing or 0) or 0

    if analysis.LateralErrorMeters > 0 then
        heading = heading - intercept
    elseif analysis.LateralErrorMeters < 0 then
        heading = heading + intercept
    end

    return self:NormalizeHeading(heading)
end

function NASG_ATC_NAVIGATION:GetVectorToWaypoint(client, waypoint)
    if not client or not waypoint then
        return nil
    end

    local aircraftCoord = nil

    pcall(function()
        aircraftCoord = client:GetCoordinate()
    end)

    if not aircraftCoord then
        return nil
    end

    local waypointCoord = self:GetWaypointCoordinate(waypoint)

    if not waypointCoord then
        return nil
    end

    return self:GetBearingDistance(aircraftCoord, waypointCoord)
end

NASG_ATC_NAVIGATION:NormalizeHeading(360)