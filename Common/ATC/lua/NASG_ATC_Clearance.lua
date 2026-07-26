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

function NASG_ATC_CLEARANCE:HandleClearanceRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
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

    local squawkSpoken = pending.SquawkCode and string.find(text, pending.SquawkCode, 1, true)
    local squawkLive = pending.SquawkCode and session.LiveSquawkCode and session.LiveSquawkCode == pending.SquawkCode
    local squawkOk = not pending.SquawkCode or squawkSpoken or squawkLive
    local procedureOk = true

    if pending.RouteSegmentNames then
        for _, segmentName in ipairs(pending.RouteSegmentNames) do
            if not string.find(text, string.lower(segmentName), 1, true) then
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
        self:Send(atc, airport, string.format("%s, readback correct.", callsign))

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
