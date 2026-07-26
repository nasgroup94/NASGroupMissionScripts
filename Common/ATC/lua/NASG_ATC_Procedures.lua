NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Named navigation procedures (SID/STAR-style): an ordered sequence of
-- points a pilot can request as a unit from Clearance Delivery ("Dream
-- departure", "Strike recovery"). Each point in a procedure is a string
-- reference into NASG_ATC_TrackedPoints.lua's registry, an inline point
-- table (same flat x/z-or-lat/lon schema tracked points use), a
-- { Point = "<id>", AltitudeFt = 10000, AltitudeConstraint = "at"|"above"|
-- "below"|<feet> } table pinning a crossing restriction to a shared tracked
-- point (see ResolveProcedurePoint). AltitudeConstraint as a number instead
-- of a keyword means "between": AltitudeFt/AltitudeConstraint become the low/
-- high bounds of a range restriction (e.g. "cross ACTON between 8,000 and
-- 12,000" is AltitudeFt = 8000, AltitudeConstraint = 12000) -- see
-- NormalizeAltitudeConstraint below. Or a { Radial = 346, Airbase =
-- AIRBASE.<Theater>.<Name>, ToleranceDeg = 2, Name = "BLD R-346" } table for
-- a leg with no trackable fix at all -- "intercept the R-346 radial of
-- BLD" -- checked via NASG_ATC_Tacan.lua instead of a coordinate. A radial
-- leg may also carry DME = <nm> (and DMEToleranceNM, default 1) to pin it to
-- a specific distance from the station rather than just the outbound
-- radial -- a real fix like "ARCOE, LSV R-209 at 30 DME" rather than an
-- open-ended intercept. A RegisterProcedure def may itself carry
-- AltitudeFt/AltitudeConstraint for a whole-route restriction (e.g. "climb
-- and maintain at or below 10,000"), read by Clearance Delivery when it
-- reads the clearance back. These same AltitudeFt/AltitudeConstraint
-- fields are also what NASG_ATC_Center.lua's HandleCourseCheck checks a
-- pilot's live altitude against when they're flying a Clearance-assigned
-- route rather than a filed flight plan (see IsAltitudeConstraintSatisfied
-- below).
--
-- Some real-world plates fly an entirely different route depending on the
-- active runway (e.g. DREAM FOUR's RWY 3 route via BLD R-346 vs. its RWY 21
-- route via LAS R-350). A procedure def can carry RunwayPoints, a table
-- keyed by GetRunwayGroupKey (the runway's heading digits, no leading zero
-- or L/C/R side -- "03L" and "03R" both key to "3") whose value is a Points
-- list exactly like the top-level Points field. GetProcedureLegs picks the
-- entry matching the active runway (passed in from Clearance Delivery at
-- request time) and falls back to the top-level Points when there's no
-- RunwayPoints table, no active runway, or no matching entry.
--
-- A recovery procedure can also carry MissedApproach = { Points = {...} },
-- the published miss as a Points list in the same shapes as above (see
-- GetProcedureMissedApproachLegs). NASG_ATC_Tower.lua's HandleGoingAround
-- swaps a session's active session.Route.Legs over to these when a pilot
-- flying that procedure goes missed, so the existing course-check plumbing
-- (HandleRouteCourseCheck/HandleRadialCourseCheck) verifies the miss the
-- same way it verifies the inbound.
--
-- session.Route.ActiveLegIndex starts at 1 (set by AttachChainedRoute) and
-- is advanced lazily by AdvanceRouteLegIfReached/IsRouteLegReached below --
-- called from NASG_ATC_Center.lua at the points that read it (course check,
-- vector-request fallback) rather than on a standing poll, matching this
-- codebase's fully event/on-demand architecture (see NASG_ATC_Core.lua's
-- Start()). This is how a multi-leg procedure (e.g. a recovery with several
-- sequential fixes) reports against whichever fix the pilot is actually
-- approaching instead of being stuck checking leg 1 forever.
-- Registered by mission data (CVW-17/.../NATO/Persian_Gulf_ATC_Procedures.lua)
-- via NASG_ATC:RegisterProcedure. Loaded after NASG_ATC_TrackedPoints.lua.
--
-- A pilot can also chain a procedure and/or bare tracked points into one
-- route in a single request ("dream departure to student gap", "student
-- gap to mintt recovery") -- see ResolveRouteSegment/AttachChainedRoute
-- below, which build session.Route out of an ordered list of
-- { name = "...", type = "departure"|"recovery"|nil } segments (type nil
-- means "look up a tracked point, not a procedure").
---------------------------------------------------------------------------

NASG_ATC.Procedures = NASG_ATC.Procedures or {}
NASG_ATC.ProceduresByLookup = NASG_ATC.ProceduresByLookup or {}

function NASG_ATC:RegisterProcedureLookup(value, procedure)
    local key = self:NormalizeFlightPlanLookup(value)

    if key and key ~= "" then
        self.ProceduresByLookup[key] = procedure
    end
end

function NASG_ATC:RegisterProcedure(def)
    if not def or not def.Id then
        error("RegisterProcedure requires a definition with an Id")
    end

    self.Procedures[def.Id] = def

    self:RegisterProcedureLookup(def.Id, def)
    self:RegisterProcedureLookup(def.Name, def)

    for _, alias in ipairs(def.Aliases or {}) do
        self:RegisterProcedureLookup(alias, def)
    end

    self:Log("Registered procedure: " .. tostring(def.Id))

    return def
end

function NASG_ATC:FindProcedure(value, airportId, procedureType)
    local key = self:NormalizeFlightPlanLookup(value)

    if key == "" then
        return nil
    end

    local procedure = self.ProceduresByLookup[key]

    if not procedure then
        return nil
    end

    if airportId and procedure.AirportId and procedure.AirportId ~= airportId then
        return nil
    end

    if procedureType and procedure.Type and procedure.Type ~= procedureType then
        return nil
    end

    return procedure
end

-- Resolves one procedure leg reference. Three shapes are accepted:
--   * a string -- looks up a registered tracked point by Id/Name/Alias.
--   * a table with a Point field -- looks up that tracked point, then
--     overlays the rest of the table's fields onto it (e.g. AltitudeFt/
--     AltitudeConstraint), so a procedure can pin a crossing restriction to
--     a shared tracked point without editing the point itself.
--   * a plain table with no Point field -- either already point-shaped
--     (inline coordinate, matching how NASG_ATC_TrackedPoints.lua's point
--     defs are structured) or a radial leg ({ Radial =, Airbase = }, no
--     coordinate at all) -- returned as-is either way; NASG_ATC_TACAN and
--     NASG_ATC_Center.lua's HandleRouteCourseCheck tell the two apart by
--     the presence of Radial/Airbase.
function NASG_ATC:ResolveProcedurePoint(pointRef)
    if type(pointRef) == "string" then
        return self:FindTrackedPoint(pointRef)
    end

    if type(pointRef) == "table" and pointRef.Point then
        local basePoint = self:FindTrackedPoint(pointRef.Point)

        if not basePoint then
            return nil
        end

        local leg = {}

        for key, value in pairs(basePoint) do
            leg[key] = value
        end

        for key, value in pairs(pointRef) do
            if key ~= "Point" then
                leg[key] = value
            end
        end

        return leg
    end

    return pointRef
end

-- Normalizes an altitude-constraint value to one of "at", "above", "below"
-- (case/whitespace-insensitive keyword; "at or above"/"at or below" are
-- accepted as aliases for "above"/"below"), or a number -- a numeric
-- constraint means "between AltitudeFt and this value", not a keyword, so
-- callers must check type(result) == "number" before comparing it against
-- the string cases. Returns nil for anything unrecognized (including nil)
-- so a typo silently drops the constraint rather than erroring.
function NASG_ATC:NormalizeAltitudeConstraint(value)
    if value == nil then
        return nil
    end

    if type(value) == "number" then
        return value
    end

    local key = string.lower(tostring(value)):match("^%s*(.-)%s*$")

    if key == "at" then
        return "at"
    elseif key == "above" or key == "at or above" then
        return "above"
    elseif key == "below" or key == "at or below" then
        return "below"
    end

    return nil
end

-- Builds the spoken altitude-restriction clause for a leg or procedure def
-- ("at or above 10 thousand", or "between 8 thousand and 12 thousand" for a
-- numeric/between constraint), or nil if it carries no AltitudeFt. Missing/
-- unrecognized AltitudeConstraint defaults to "at" (an exact altitude).
function NASG_ATC:FormatAltitudeConstraintClause(entity)
    if not entity or not entity.AltitudeFt then
        return nil
    end

    local altitudeSpeech = self:FormatAltitudeSpeech(entity.AltitudeFt)

    if not altitudeSpeech then
        return nil
    end

    local constraint = self:NormalizeAltitudeConstraint(entity.AltitudeConstraint)

    if type(constraint) == "number" then
        local highSpeech = self:FormatAltitudeSpeech(constraint)

        if highSpeech then
            return "between " .. altitudeSpeech .. " and " .. highSpeech
        end
    end

    constraint = constraint or "at"

    if constraint == "above" then
        return "at or above " .. altitudeSpeech
    elseif constraint == "below" then
        return "at or below " .. altitudeSpeech
    end

    return "at " .. altitudeSpeech
end

-- Checks a live altitude against an entity's (leg or procedure def)
-- AltitudeFt/AltitudeConstraint, within toleranceFt (default 250, matching
-- the tolerance NASG_ATC_Center.lua already uses for climb/descend
-- comparisons). A numeric AltitudeConstraint checks a between range instead
-- (AltitudeFt/AltitudeConstraint as the low/high bounds, in either order).
-- Returns true if compliant or the entity carries no restriction, false if
-- violated, or nil if either altitude is unknown.
function NASG_ATC:IsAltitudeConstraintSatisfied(liveAltitudeFt, entity, toleranceFt)
    if not entity or not entity.AltitudeFt then
        return true
    end

    local required = tonumber(entity.AltitudeFt)
    local live = tonumber(liveAltitudeFt)

    if not required or not live then
        return nil
    end

    local tolerance = toleranceFt or 250
    local constraint = self:NormalizeAltitudeConstraint(entity.AltitudeConstraint)

    if type(constraint) == "number" then
        local low, high = required, constraint

        if low > high then
            low, high = high, low
        end

        return live >= low - tolerance and live <= high + tolerance
    end

    constraint = constraint or "at"

    if constraint == "above" then
        return live >= required - tolerance
    elseif constraint == "below" then
        return live <= required + tolerance
    end

    return math.abs(live - required) <= tolerance
end

-- Normalizes a runway identifier down to its heading digits, with no
-- leading zero and no L/C/R side suffix -- the key two parallel runways
-- sharing one route variant (e.g. "03L"/"03R") both resolve to ("3"). nil
-- for anything with no digits (including nil).
function NASG_ATC:GetRunwayGroupKey(runway)
    if not runway then
        return nil
    end

    local digits = tostring(runway):match("(%d+)")

    if not digits then
        return nil
    end

    digits = digits:gsub("^0+", "")

    return digits ~= "" and digits or "0"
end

-- Picks a procedure's runway-specific Points list from its RunwayPoints
-- table (see the file header comment), or nil if the procedure defines no
-- RunwayPoints, no runway was supplied, or none of its keys match.
function NASG_ATC:GetProcedureRunwayPoints(procedure, runway)
    if not procedure or not procedure.RunwayPoints then
        return nil
    end

    local key = self:GetRunwayGroupKey(runway)

    return key and procedure.RunwayPoints[key]
end

-- Returns the procedure's ordered legs as resolved point refs (not baked
-- coordinates) so a tanker-based leg keeps tracking the tanker's live
-- position rather than a coordinate captured once at request time. Each
-- leg carries whatever Name/AltitudeFt/AltitudeConstraint the point/inline
-- table defines (see ResolveProcedurePoint above). runway selects a
-- RunwayPoints variant when the procedure defines one (see
-- GetProcedureRunwayPoints); otherwise the top-level Points list is used.
function NASG_ATC:GetProcedureLegs(procedure, runway)
    local legs = {}

    if not procedure then
        return legs
    end

    local points = self:GetProcedureRunwayPoints(procedure, runway) or procedure.Points or {}

    for _, pointRef in ipairs(points) do
        local point = self:ResolveProcedurePoint(pointRef)

        if point then
            table.insert(legs, point)
        end
    end

    return legs
end

-- Returns a recovery procedure's published missed-approach legs, resolved
-- the same way as GetProcedureLegs, or an empty list if it defines no
-- MissedApproach (e.g. a departure, or a recovery whose miss isn't modeled).
function NASG_ATC:GetProcedureMissedApproachLegs(procedure)
    local legs = {}

    if not procedure or not procedure.MissedApproach then
        return legs
    end

    for _, pointRef in ipairs(procedure.MissedApproach.Points or {}) do
        local point = self:ResolveProcedurePoint(pointRef)

        if point then
            table.insert(legs, point)
        end
    end

    return legs
end

-- Resolves one route-chain segment ({ name = "...", type = "departure"|
-- "recovery"|nil }, as extracted by the Python speech bridge's
-- extract_route_request) to either a named procedure or a bare tracked
-- point. A tagged segment (type is "departure"/"recovery") is a procedure
-- lookup by name; an untagged segment is a tracked-point lookup only.
-- This is a deliberate rule, not just a convenience: some names (e.g.
-- "MINTT") are registered as both a tracked point and a same-named
-- procedure, so the pilot's own departure/recovery tag is what picks
-- which one they meant rather than guessing. Tracked points already
-- fuzzy-match misheard names (FindTrackedPoint); procedures don't
-- (FindProcedure), matching this codebase's existing asymmetry.
-- Returns "procedure", <procedure> or "point", <point> on success, or
-- nil, nil if the segment is missing a name or nothing matches it.
function NASG_ATC:ResolveRouteSegment(segmentSpec, airportId)
    if not segmentSpec or not segmentSpec.name or segmentSpec.name == "" then
        return nil, nil
    end

    if segmentSpec.type == "departure" or segmentSpec.type == "recovery" then
        local procedure = self:FindProcedure(segmentSpec.name, airportId, segmentSpec.type)

        if procedure then
            return "procedure", procedure
        end

        return nil, nil
    end

    local point = self:FindTrackedPoint(segmentSpec.name, airportId)

    if point then
        return "point", point
    end

    return nil, nil
end

-- Builds and attaches a (possibly multi-segment) requested-route object to
-- a client's session so every facility sharing that session (Center in
-- particular) can read it. segments is an ordered list of chain segments
-- (see ResolveRouteSegment) -- a plain single-procedure request like
-- "dream departure" is just a 1-element chain, so it needs no separate
-- code path. Each procedure segment contributes its full leg list
-- (GetProcedureLegs, runway variant only applied to non-recovery
-- procedures -- see below); each point segment contributes itself as a
-- single leg. ProcedureId/ProcedureType track the LAST procedure segment
-- that resolved, since that's the one that actually governs a missed
-- approach (NASG_ATC_Tower.lua's HandleGoingAround) or a runway-variant
-- departure -- a chain only ever ends in at most one such procedure.
-- destinationText is the pilot-stated destination (logged for the
-- clearance readout, same free-text precedent as before); when not
-- given, it falls back to the last recovery-procedure segment's
-- AirportId, so an inbound chain like "student gap to mintt recovery"
-- sets up NASG_ATC_Center.lua's HandleRecovery arrival airport without
-- the pilot separately stating one. runway (the active departure/arrival
-- runway at request time) selects a RunwayPoints variant on departure
-- procedure segments -- see GetProcedureLegs. A segment that fails to
-- resolve (misheard/unknown name) is skipped and logged rather than
-- failing the whole request; this returns nil only when nothing in the
-- chain resolved at all.
function NASG_ATC:AttachChainedRoute(session, segments, destinationText, runway, airportId)
    if not session or not segments or #segments == 0 then
        return nil
    end

    local legs = {}
    local spokenParts = {}
    local segmentNames = {}
    local lastProcedureId
    local lastProcedureType
    local inferredDestination

    for _, segmentSpec in ipairs(segments) do
        local kind, resolved = self:ResolveRouteSegment(segmentSpec, airportId)

        if kind == "procedure" then
            local procedureRunway = resolved.Type ~= "recovery" and runway or nil
            local procedureLegs = self:GetProcedureLegs(resolved, procedureRunway)

            for _, leg in ipairs(procedureLegs) do
                table.insert(legs, leg)
            end

            lastProcedureId = resolved.Id
            lastProcedureType = resolved.Type

            table.insert(spokenParts, string.format(
                    "%s %s",
                    resolved.Name,
                    resolved.Type == "recovery" and "recovery" or "departure"
            ))
            table.insert(segmentNames, resolved.Name)

            if resolved.Type == "recovery" and resolved.AirportId then
                inferredDestination = resolved.AirportId
            end
        elseif kind == "point" then
            table.insert(legs, resolved)
            table.insert(spokenParts, resolved.Name)
            table.insert(segmentNames, resolved.Name)
        else
            self:Log(string.format(
                    "Unresolved route segment '%s' (%s)",
                    tostring(segmentSpec and segmentSpec.name),
                    tostring(segmentSpec and segmentSpec.type)
            ))
        end
    end

    if #legs == 0 then
        return nil
    end

    session.Route = {
        ProcedureId = lastProcedureId,
        ProcedureType = lastProcedureType,
        DestinationText = (destinationText and destinationText ~= "") and destinationText or inferredDestination,
        Legs = legs,
        ActiveLegIndex = 1,
        AssignedAt = timer.getTime(),
        SpokenClause = table.concat(spokenParts, ", "),
        SegmentNames = segmentNames,
    }

    return session.Route
end

-- Checks whether the client has reached currentLeg, so ActiveLegIndex can
-- advance past it. Two leg shapes, two tests:
--   * Radial/DME leg -- reached once on the radial (within ToleranceDeg) and,
--     if the leg carries a DME, within DMEToleranceNM of it. A pure outbound
--     intercept (no DME, e.g. "BLD R-346") is reached as soon as it's
--     established on the radial -- that IS the whole leg, same criterion
--     HandleRadialCourseCheck already uses to report "on the radial" with
--     nothing left to check.
--   * Coordinate leg -- reached within toleranceNM (default 2) of its point,
--     OR already closer to nextLeg's coordinate than to this one. The
--     fallback covers an infrequent check-in landing well past the fix
--     rather than inside its tolerance ring; nextLeg with no coordinate of
--     its own (e.g. a radial leg) just skips the fallback.
-- Returns false (not nil) on anything unresolvable, so an unknown state
-- never advances the leg.
function NASG_ATC:IsRouteLegReached(client, currentLeg, nextLeg, toleranceNM)
    if not client or not currentLeg then
        return false
    end

    if currentLeg.Radial and currentLeg.Airbase then
        if not NASG_ATC_TACAN then
            return false
        end

        local vector = NASG_ATC_TACAN:GetClientRadial(client, currentLeg.Airbase)

        if not vector then
            return false
        end

        if not NASG_ATC_TACAN:IsOnRadial(client, currentLeg.Airbase, currentLeg.Radial, currentLeg.ToleranceDeg) then
            return false
        end

        if not currentLeg.DME then
            return true
        end

        return math.abs(vector.DistanceNM - currentLeg.DME) <= (currentLeg.DMEToleranceNM or 1)
    end

    if not NASG_ATC_NAVIGATION then
        return false
    end

    local coordinate = self:GetTrackedPointCoordinate(currentLeg)
    local vector = coordinate and NASG_ATC_NAVIGATION:GetVectorToCoordinate(client, coordinate)

    if not vector then
        return false
    end

    if vector.DistanceNM <= (toleranceNM or 2) then
        return true
    end

    local nextCoordinate = nextLeg and self:GetTrackedPointCoordinate(nextLeg)
    local nextVector = nextCoordinate and NASG_ATC_NAVIGATION:GetVectorToCoordinate(client, nextCoordinate)

    return nextVector ~= nil and nextVector.DistanceNM < vector.DistanceNM
end

-- Advances session.Route.ActiveLegIndex past every leg the client has
-- already reached (see IsRouteLegReached), so a course check or vector
-- request after an infrequent check-in reports against the CURRENT leg
-- instead of one flown past turns ago. Loops so a single call can skip
-- several legs at once; never moves backward and clamps at the last leg
-- (there's nothing beyond it to advance toward). No-op without a resolvable
-- route.
function NASG_ATC:AdvanceRouteLegIfReached(client, session)
    local route = session and session.Route

    if not route or not route.Legs or #route.Legs == 0 then
        return
    end

    local index = route.ActiveLegIndex or 1

    while index < #route.Legs and self:IsRouteLegReached(client, route.Legs[index], route.Legs[index + 1]) do
        index = index + 1
    end

    route.ActiveLegIndex = index
end

NASG_ATC:Log("NASG_ATC_Procedures loaded")
