NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Named navigation procedures (SID/STAR-style): an ordered sequence of
-- points a pilot can request as a unit from Clearance Delivery ("Dream
-- departure", "Strike recovery"). Each point in a procedure is either a
-- string reference into NASG_ATC_TrackedPoints.lua's registry or an inline
-- point table (same flat x/z-or-lat/lon schema tracked points use).
-- Registered by mission data (CVW-17/.../NATO/Persian_Gulf_ATC_Procedures.lua)
-- via NASG_ATC:RegisterProcedure. Loaded after NASG_ATC_TrackedPoints.lua.
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

-- Resolves one procedure leg reference: a string looks up a registered
-- tracked point; a table is already point-shaped (inline coordinate) and
-- is returned as-is, matching how NASG_ATC_TrackedPoints.lua's point defs
-- are structured.
function NASG_ATC:ResolveProcedurePoint(pointRef)
    if type(pointRef) == "string" then
        return self:FindTrackedPoint(pointRef)
    end

    return pointRef
end

-- Returns the procedure's ordered legs as resolved point refs (not baked
-- coordinates) so a tanker-based leg keeps tracking the tanker's live
-- position rather than a coordinate captured once at request time. Each
-- leg carries whatever Name/AltitudeFt the point/inline table defines.
function NASG_ATC:GetProcedureLegs(procedure)
    local legs = {}

    if not procedure then
        return legs
    end

    for _, pointRef in ipairs(procedure.Points or {}) do
        local point = self:ResolveProcedurePoint(pointRef)

        if point then
            table.insert(legs, point)
        end
    end

    return legs
end

-- Builds and attaches the requested-route object to a client's session so
-- every facility sharing that session (Center in particular) can read it.
-- destinationText is the pilot-stated destination, logged for the clearance
-- readout only — not structurally validated against a gazetteer, same
-- precedent as free-text position reports.
function NASG_ATC:AttachRequestedRoute(session, procedure, destinationText)
    if not session or not procedure then
        return nil
    end

    session.Route = {
        ProcedureId = procedure.Id,
        ProcedureName = procedure.Name,
        ProcedureType = procedure.Type,
        DestinationText = destinationText,
        Legs = self:GetProcedureLegs(procedure),
        ActiveLegIndex = 1,
        AssignedAt = timer.getTime(),
    }

    return session.Route
end

NASG_ATC:Log("NASG_ATC_Procedures loaded")
