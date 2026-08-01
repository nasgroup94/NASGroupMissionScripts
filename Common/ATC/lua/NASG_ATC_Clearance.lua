NASG_ATC = NASG_ATC or {}
NASG_ATC_CLEARANCE = NASG_ATC_CLEARANCE or {}

---------------------------------------------------------------------------
-- Clearance Delivery: assigns squawk codes and, optionally, a chained
-- route of one or more named procedures and/or tracked points ("Dream
-- departure", "Dream departure to Student Gap") to an end destination,
-- attaching the result to the pilot's session as session.Route for
-- Center to consume (see NASG_ATC_Procedures.lua's AttachChainedRoute).
--
-- Contacting Clearance Delivery is optional — a pilot who never calls it
-- gets exactly today's behavior; nothing downstream requires session.Route
-- or session.Clearance to be set.
--
-- Squawk codes are assigned and confirmed by verbal readback. DCS's
-- mission-scripting environment has no API to read a human player's live
-- transponder code (see reference_dcs_squawk_limitation notes), but our SRS
-- listener can independently observe a player's live Mode3/IFF value
-- (session.LiveSquawkCode, set by NASG_ATC:HandleLiveSquawkUpdate) and
-- accept a match there as an alternative to speaking the code back — see
-- HandleReadback below. Coverage is partial: only players who've set an
-- IFF/Mode3 value in SRS report one.
---------------------------------------------------------------------------

NASG_ATC_CLEARANCE.Requests = {
    radio_check = {
        Patterns = {
            "radio check",
            "comm check",
            "comms check",
        },
        Handler = "HandleRadioCheck",
    },

    say_again = {
        Patterns = {
            "say again",
            "repeat",
        },
        Handler = "HandleSayAgain",
    },

    request_clearance = {
        Patterns = {
            "request",
            "request clearance",
            "ready to copy",
            "request ifr clearance",
        },
        Handler = "HandleClearanceRequest",
    },

    readback = {
        Patterns = {
            "squawk",
            "cleared to",
        },
        Handler = "HandleReadback",
    },
}

function NASG_ATC_CLEARANCE:RegisterRequestPatterns(atc)
    local patternMap = {}

    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end

    atc:RegisterIntentPatterns(atc.Facilities.CLEARANCE, patternMap)
end

function NASG_ATC_CLEARANCE:Send(atc, airport, message)
    if self._activeSession and message and message ~= "" then
        self._activeSession.LastClearanceInstruction = message
    end

    atc:SendFacilityTTS(airport, atc.Facilities.CLEARANCE, message)
end

function NASG_ATC_CLEARANCE:HandleRadioCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    self:Send(
            atc,
            airport,
            string.format("%s, %s, loud and clear.", callsign, atc:GetFacilityCallsign(airport, atc.Facilities.CLEARANCE))
    )

    return true
end

function NASG_ATC_CLEARANCE:HandleSayAgain(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local last = session and session.LastClearanceInstruction

    if not last or last == "" then
        atc:SendFacilityTTS(
                airport,
                atc.Facilities.CLEARANCE,
                string.format("%s, %s, no previous transmission to repeat.", callsign, atc:GetFacilityCallsign(airport, atc.Facilities.CLEARANCE))
        )
        return true
    end

    self:Send(atc, airport, last)
    return true
end

-- Assigns a squawk code to a session (idempotent — a repeat request
-- returns the code already on file). Codes are 4 octal digits (0-7 each,
-- matching real transponder constraints), excluding reserved real-world
-- codes and anything already assigned this mission. Released back to the
-- pool by ReleaseSquawkCode/OnClientSessionEnded below on land/crash/dead/
-- disconnect, so a long-running server doesn't exhaust the pool.
function NASG_ATC_CLEARANCE:AssignSquawkCode(atc, session)
    if session.Clearance and session.Clearance.SquawkCode then
        return session.Clearance.SquawkCode
    end

    self.AssignedSquawkCodes = self.AssignedSquawkCodes or {}

    local reserved = {}

    for _, code in ipairs(atc.Defaults.ReservedSquawkCodes or {}) do
        reserved[code] = true
    end

    local code

    for _ = 1, 100 do
        local candidate = string.format(
                "%d%d%d%d",
                math.random(0, 7),
                math.random(0, 7),
                math.random(0, 7),
                math.random(0, 7)
        )

        if not reserved[candidate] and not self.AssignedSquawkCodes[candidate] then
            code = candidate
            break
        end
    end

    code = code or "0100"

    self.AssignedSquawkCodes[code] = session.ClientKey
    session.Clearance = session.Clearance or {}
    session.Clearance.SquawkCode = code

    return code
end

-- Returns a session's assigned squawk code to the pool. Safe to call on a
-- session with no code on file (no-op).
function NASG_ATC_CLEARANCE:ReleaseSquawkCode(atc, session)
    if not session or not session.Clearance or not session.Clearance.SquawkCode then
        return
    end

    local code = session.Clearance.SquawkCode

    self.AssignedSquawkCodes = self.AssignedSquawkCodes or {}
    self.AssignedSquawkCodes[code] = nil
    session.Clearance.SquawkCode = nil
    session.LiveSquawkCode = nil

    atc:Log("Released squawk " .. tostring(code) .. " for client=" .. tostring(session.ClientKey))
end

-- Generic hook called by NASG_ATC:HandleClientSessionEnded (land/crash/
-- dead/disconnect) for every registered facility. Clearance uses it to
-- free the squawk code back to the pool.
function NASG_ATC_CLEARANCE:OnClientSessionEnded(atc, session, reason)
    self:ReleaseSquawkCode(atc, session)
end

-- Returns another session in the same package that already has a full
-- clearance on file (session.Clearance.Issued), or nil. Package flights
-- (see NASG_ATC_Core.lua:RefreshPackageMembership) only need one member --
-- usually but not necessarily the numeric flight lead -- to get a clearance
-- for the whole group.
function NASG_ATC_CLEARANCE:FindPackageClearance(atc, session)
    if not session or not session.PackageKey then
        return nil
    end

    for _, memberSession in ipairs(atc:GetPackageMemberSessions(session)) do
        if memberSession ~= session and memberSession.Clearance and memberSession.Clearance.Issued then
            return memberSession
        end
    end

    return nil
end

function NASG_ATC_CLEARANCE:HandleClearanceRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    local packageClearance = self:FindPackageClearance(atc, session)

    if packageClearance then
        local leadCallsign = atc:FormatCallsignForSpeech(packageClearance.CallsignAlias or packageClearance.ClientKey)

        self:Send(
                atc,
                airport,
                string.format(
                        "%s, you're already covered under %s's clearance for your package. Contact Ground when ready.",
                        callsign,
                        leadCallsign
                )
        )

        return true
    end

    local routeSegments = event and event.route_segments

    if routeSegments and #routeSegments > 0 then
        local destinationText = event and event.destination
        local runway = atc:GetActiveRunway(airport, true)
        local route = atc:AttachChainedRoute(session, routeSegments, destinationText, runway, airport.Id)

        if not route then
            self:Send(atc, airport, string.format("%s, unable, say requested route.", callsign))
            return true
        end

        local code = self:AssignSquawkCode(atc, session)
        local message

        if destinationText and destinationText ~= "" then
            message = string.format("%s, cleared to %s, %s", callsign, destinationText, route.SpokenClause)
        else
            message = string.format("%s, %s", callsign, route.SpokenClause)
        end

        local procedure = route.ProcedureId and atc.Procedures[route.ProcedureId]
        local altitudeClause = procedure and atc:FormatAltitudeConstraintClause(procedure)

        if altitudeClause then
            message = message .. ", maintain " .. altitudeClause
        end

        message = message .. string.format(", squawk %s.", code)

        self:Send(atc, airport, message)

        session.Facility = atc.Facilities.CLEARANCE
        session.UpdatedAt = timer.getTime()

        atc:SetPendingReadback(session, {
            Facility = atc.Facilities.CLEARANCE,
            Type = "clearance",
            InstructionText = message,
            SquawkCode = code,
            RouteSegmentNames = route.SegmentNames,
        })

        return true
    end

    local code = self:AssignSquawkCode(atc, session)
    local message = string.format("%s, squawk %s. Remain this frequency for clearance.", callsign, code)

    self:Send(atc, airport, message)

    session.Facility = atc.Facilities.CLEARANCE
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Facility = atc.Facilities.CLEARANCE,
        Type = "clearance",
        InstructionText = message,
        SquawkCode = code,
    })

    return true
end

-- Full CRAFT-format clearance (Clearance limit, Route, Altitude, Frequency,
-- Transponder), issued once the pilot correctly reads back the squawk on
-- the plain "request clearance" path (no named departure/recovery
-- procedure -- that path already front-loads its own clearance message in
-- HandleClearanceRequest above, before readback). Reuses NASG_ATC_TOWER's
-- departure-facility/climb-altitude logic rather than duplicating it here.
function NASG_ATC_CLEARANCE:BuildFullClearanceMessage(atc, client, airport, session, event, callsign)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local arrivalAirportId = atc:GetFlightPlanArrivalAirportId(flightPlan)
    local arrivalAirport = arrivalAirportId and atc:GetAirport(arrivalAirportId)

    local clearanceLimitClause = arrivalAirport
            and string.format("cleared to %s, as filed", arrivalAirport.Name)
            or "cleared as filed"

    local climbAltitudeFt = NASG_ATC_TOWER:GetDepartureClimbAltitudeFeet(atc, client, airport, session, event)
    local altitudeClause = climbAltitudeFt and string.format("climb and maintain %s", atc:FormatAltitudeSpeech(climbAltitudeFt))

    local departureFacility = NASG_ATC_TOWER:GetDepartureFacility(atc, airport)
    local departureFrequency = atc:GetFacilityFrequency(airport, departureFacility)
    local frequencyClause = departureFrequency
            and string.format(
                    "departure frequency %s, %s",
                    atc:GetFacilityCallsign(airport, departureFacility),
                    atc:FormatFrequency(departureFrequency)
            )
            or nil

    local squawkCode = session.Clearance and session.Clearance.SquawkCode
    local squawkClause = squawkCode and string.format("squawk %s", squawkCode) or nil

    local parts = { callsign, clearanceLimitClause }

    if altitudeClause then
        parts[#parts + 1] = altitudeClause
    end

    if frequencyClause then
        parts[#parts + 1] = frequencyClause
    end

    if squawkClause then
        parts[#parts + 1] = squawkClause
    end

    session.Clearance = session.Clearance or {}
    session.Clearance.Issued = true
    session.Clearance.Destination = arrivalAirport and arrivalAirport.Name or nil
    session.Clearance.AltitudeFt = climbAltitudeFt
    session.Clearance.DepartureFacility = departureFacility
    session.Clearance.DepartureFrequency = departureFrequency

    return table.concat(parts, ", ") .. "."
end

function NASG_ATC_CLEARANCE:HandleReadback(atc, client, airport, session, event)
    if not session or not session.PendingReadback then
        return true
    end

    local pending = session.PendingReadback

    if pending.Type ~= "clearance" then
        return true
    end

    if pending.ExpiresAt and timer.getTime() > pending.ExpiresAt then
        session.PendingReadback = nil
        return true
    end

    local rawText = event and event.raw_text or ""
    local text = atc:NormalizeReadbackText(rawText)

    local squawkSpoken = pending.SquawkCode and atc:IsSquawkReadbackCorrect(rawText, pending.SquawkCode)
    local squawkLive = pending.SquawkCode and session.LiveSquawkCode and session.LiveSquawkCode == pending.SquawkCode
    local squawkOk = not pending.SquawkCode or squawkSpoken or squawkLive
    local procedureOk = true

    if pending.RouteSegmentNames then
        local numericText = atc:NormalizeNumberWords(text)

        for _, segmentName in ipairs(pending.RouteSegmentNames) do
            local loweredName = string.lower(segmentName)
            local numericName = atc:NormalizeNumberWords(loweredName)

            local found = string.find(text, loweredName, 1, true)
                    or string.find(text, numericName, 1, true)
                    or string.find(numericText, loweredName, 1, true)
                    or string.find(numericText, numericName, 1, true)

            if not found then
                procedureOk = false
                break
            end
        end
    end

    if squawkOk and procedureOk then
        session.PendingReadback = nil
        session.UpdatedAt = timer.getTime()

        if squawkLive and not squawkSpoken then
            atc:Log("Clearance readback correct (live squawk match) for client=" .. tostring(session.ClientKey))
        else
            atc:Log("Clearance readback correct for client=" .. tostring(session.ClientKey))
        end

        local callsign = atc:GetClientCallsign(client, event)
        local message

        if pending.RouteSegmentNames then
            message = string.format("%s, readback correct.", callsign)
        else
            message = self:BuildFullClearanceMessage(atc, client, airport, session, event, callsign)
        end

        local groundFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.GROUND)

        if groundFrequency then
            message = message .. string.format(" Contact Ground, %s.", atc:FormatFrequency(groundFrequency))
        else
            message = message .. " Contact Ground."
        end

        self:Send(atc, airport, message)

        session.State = atc.States.TRANSFERRED_TO_GROUND
        session.Facility = atc.Facilities.GROUND

        return true
    end

    local callsign = atc:GetClientCallsign(client, event)
    self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
    return true
end

function NASG_ATC_CLEARANCE:HandleSpeechEvent(atc, client, airport, session, event)
    local intent = event and event.intent or nil
    local request = self.Requests and self.Requests[intent] or nil

    self._activeSession = session

    if request then
        if request.Handler and self[request.Handler] then
            return self[request.Handler](self, atc, client, airport, session, event)
        end
    end

    -- A chained route request ("dream departure to student gap") doesn't
    -- always carry one of the fixed trigger phrases above (e.g. it may be
    -- spoken with no "request clearance" lead-in at all), but the speech
    -- bridge still extracts route_segments independently of intent
    -- matching -- so fall back to handling it as a clearance request
    -- rather than a flat "say again" when segments are present.
    if event and event.route_segments and #event.route_segments > 0 then
        return self:HandleClearanceRequest(atc, client, airport, session, event)
    end

    atc:SendSayAgain(airport, atc.Facilities.CLEARANCE, client, event)
    return false
end

NASG_ATC_CLEARANCE:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.CLEARANCE, NASG_ATC_CLEARANCE)
NASG_ATC:Log("NASG_ATC_Clearance loaded")
