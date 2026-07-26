NASG_ATC = NASG_ATC or {}
NASG_ATC_TACAN = NASG_ATC_TACAN or {}

---------------------------------------------------------------------------
-- TACAN/VORTAC radial checking.
--
-- Some real-world SIDs route a pilot to "intercept the R-346 radial of
-- BLD" rather than direct to a trackable fix (e.g. the DREAM FOUR
-- DEPARTURE's Boulder City leg). There's no coordinate to fly to -- the
-- radial is a bearing FROM the station -- so this resolves the station's
-- position from a MOOSE AIRBASE (the ground facility a VOR/TACAN/VORTAC is
-- co-located with) and compares the bearing from that station to the
-- client against the target radial.
--
-- A procedure Points entry becomes a radial leg with
-- { Radial = <outbound degrees>, Airbase = AIRBASE.<Theater>.<Name>,
-- ToleranceDeg = <degrees, default 2>, Name = "<display name>" } -- see
-- NASG_ATC_Procedures.lua's ResolveProcedurePoint and
-- NASG_ATC_Center.lua's HandleRouteCourseCheck.
---------------------------------------------------------------------------

NASG_ATC_TACAN.AirbaseCoordinates = NASG_ATC_TACAN.AirbaseCoordinates or {}

-- Resolves and caches a named MOOSE airbase's coordinate (pcall-wrapped so
-- a missing/misspelled airbase name degrades to nil rather than erroring).
function NASG_ATC_TACAN:GetAirbaseCoordinate(airbaseName)
    if not airbaseName then
        return nil
    end

    if self.AirbaseCoordinates[airbaseName] then
        return self.AirbaseCoordinates[airbaseName]
    end

    local coordinate = nil

    pcall(function()
        local airbase = AIRBASE:FindByName(airbaseName)

        if airbase then
            coordinate = airbase:GetCoordinate()
        end
    end)

    if coordinate then
        self.AirbaseCoordinates[airbaseName] = coordinate
    end

    return coordinate
end

-- Returns the client's current bearing/distance FROM the named station
-- (i.e. the radial it's currently on and how far out), or nil if either
-- coordinate is unavailable.
function NASG_ATC_TACAN:GetClientRadial(client, airbaseName)
    if not client or not airbaseName or not NASG_ATC_NAVIGATION then
        return nil
    end

    local stationCoord = self:GetAirbaseCoordinate(airbaseName)

    if not stationCoord then
        return nil
    end

    local aircraftCoord = nil

    pcall(function()
        aircraftCoord = client:GetCoordinate()
    end)

    if not aircraftCoord then
        return nil
    end

    return NASG_ATC_NAVIGATION:GetBearingDistance(stationCoord, aircraftCoord)
end

-- Checks whether a client is within toleranceDeg (default 2) of a target
-- outbound radial from a named station. Returns true/false, or nil if the
-- radial can't be determined (station/client coordinate unavailable).
function NASG_ATC_TACAN:IsOnRadial(client, airbaseName, radialDegrees, toleranceDeg)
    if not radialDegrees then
        return nil
    end

    local vector = self:GetClientRadial(client, airbaseName)

    if not vector then
        return nil
    end

    local tolerance = toleranceDeg or 2
    local diff = NASG_ATC_NAVIGATION:HeadingDifference(radialDegrees, vector.Bearing)

    return math.abs(diff) <= tolerance
end

NASG_ATC:Log("NASG_ATC_Tacan loaded")
