NASG_ATC = NASG_ATC or {}
NASG_ATC_TOWER = NASG_ATC_TOWER or {}

NASG_ATC_TOWER.States = {
    WAITING_FOR_TOWER_CHECKIN = "WAITING_FOR_TOWER_CHECKIN",
    LINEUP_AND_WAIT = "LINEUP_AND_WAIT",
    TAKEOFF_CLEARED = "TAKEOFF_CLEARED",
    AIRBORNE = "AIRBORNE",
    PATTERN = "PATTERN",
    INITIAL = "INITIAL",
    DOWNWIND = "DOWNWIND",
    FINAL = "FINAL",
    LANDING_CLEARED = "LANDING_CLEARED",
    LANDED = "LANDED",
    GO_AROUND = "GO_AROUND",
    TOWER_EMERGENCY = "TOWER_EMERGENCY",
}

NASG_ATC_TOWER.Requests = {
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
    },

    request_route = {
        Patterns = {
            "request departure",
            "request recovery",
            "request route",
            "request dream",
            "request dream four",
            "request dream departure",
            "request fyttr",
            "request fyttr three",
            "request fyttr departure",
            "request mormon mesa",
            "request mormon mesa four",
            "request acton",
            "request acton recovery",
            "request arcoe",
            "request arcoe recovery",
            "request mintt",
            "request mintt recovery",
            "dream four departure",
            "fyttr three departure",
            "mormon mesa four departure",
            "acton recovery",
            "arcoe recovery",
            "mintt recovery",
        },
        Handler = "HandleRouteRequest",
    },

    readback = {
        Patterns = {
            "line up and wait",
            "lineup and wait",
            "lined up",
            "lining up",
            "line up",
            "cleared for takeoff",
            "cleared for take off",
            "cleared to land",
            "go around",
        },
        Handler = "HandleReadback",
    },
    tower_check_in_departure = {
        Patterns = {
            "holding short",
            "holding short runway",
            "ready for departure",
            "holding short ready for departure",
        },
        Handler = "HandleDepartureCheckIn",
    },

    request_takeoff = {
        Patterns = {
            "request takeoff",
            "request take off",
            "ready for takeoff",
            "ready for take off",
            "ready to depart",
            "ready for departure",
            "ready",
        },
        Handler = "HandleTakeoffRequest",
    },

    abort_takeoff = {
        Patterns = {
            "abort takeoff",
            "abort take off",
            "aborting takeoff",
            "aborting take off",
        },
        Handler = "HandleAbortTakeoff",
    },

    inbound_full_stop = {
        Patterns = {
            "inbound full stop",
            "inbound landing",
            "request landing",
            "full stop landing",
        },
        Handler = "HandleInbound",
    },

    inbound_touch_and_go = {
        Patterns = {
            "touch and go",
            "touch-and-go",
            "inbound touch and go",
        },
        Handler = "HandleInbound",
    },

    inbound_overhead = {
        Patterns = {
            "inbound overhead",
            "request overhead",
            "overhead recovery",
            "initial for overhead",
        },
        Handler = "HandleInbound",
    },

    report_initial = {
        Patterns = {
            "initial",
            "report initial",
            "at initial",
        },
        Handler = "HandleReportInitial",
    },

    report_downwind = {
        Patterns = {
            "downwind",
            "report downwind",
            "midfield downwind",
        },
        Handler = "HandleLandingClearance",
    },

    report_base = {
        Patterns = {
            "base",
            "report base",
            "turning base",
        },
        Handler = "HandleLandingClearance",
    },

    report_final = {
        Patterns = {
            "final",
            "on final",
            "report final",
            "five mile final",
        },
        Handler = "HandleLandingClearance",
    },

    report_clear_of_runway = {
        Patterns = {
            "clear of runway",
            "clear runway",
            "runway vacated",
            "off the runway",
        },
        Handler = "HandleClearOfRunway",
    },

    going_around = {
        Patterns = {
            "going around",
            "go around",
            "missed approach",
        },
        Handler = "HandleGoingAround",
    },

    request_closed_traffic = {
        Patterns = {
            "closed traffic",
            "request closed traffic",
            "stay in the pattern",
        },
        Handler = "HandleClosedTraffic",
    },
}



function NASG_ATC_TOWER:RegisterRequestPatterns(atc)
    local patternMap = {}

    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end

    atc:RegisterIntentPatterns(atc.Facilities.TOWER, patternMap)
end

function NASG_ATC_TOWER:Send(atc, airport, message)
    atc:SendFacilityTTS(airport, atc.Facilities.TOWER, message)
end

function NASG_ATC_TOWER:GetDepartureFacility(atc, airport)
    if airport.UseAWACSForDeparture then
        return atc.Facilities.AWACS
    end

    return atc.Facilities.CENTER
end

function NASG_ATC_TOWER:GetRunwayForDeparture(atc, airport, session, event)
    return tostring(
            event.runway
                    or session.LineupRunway
                    or atc:GetActiveRunway(airport, true)
                    or airport.ActiveRunway
                    or "active"
    )
end

function NASG_ATC_TOWER:GetRunwayForArrival(atc, airport, event)
    return tostring(
            event.runway
                    or atc:GetActiveRunway(airport, false)
                    or airport.ArrivalRunway
                    or airport.ActiveRunway
                    or "active"
    )
end

function NASG_ATC_TOWER:BuildTakeoffClearanceMessage(atc, airport, callsign, runway)
    local runwaySpeech = atc:NormalizeRunway(runway)
    local departureFacility = self:GetDepartureFacility(atc, airport)
    local departureFrequency = atc:GetFacilityFrequency(airport, departureFacility)
    local windText = airport.WindText

    local message = string.format(
            "%s, Runway %s, cleared for takeoff.",
            callsign,
            runwaySpeech
    )

    if windText then
        message = message .. " Wind " .. tostring(windText) .. "."
    end

    if departureFrequency then
        message = message .. string.format(
                " Contact %s %s airborne.",
                atc:GetFacilityCallsign(airport, departureFacility),
                atc:FormatFrequency(departureFrequency)
        )
    end

    return message, departureFacility, departureFrequency
end

function NASG_ATC_TOWER:BuildLandingClearanceMessage(atc, airport, callsign, runway)
    local runwaySpeech = atc:NormalizeRunway(runway)
    local windText = airport.WindText

    if windText then
        return string.format(
                "%s, Runway %s, cleared to land. Wind %s.",
                callsign,
                runwaySpeech,
                tostring(windText)
        )
    end

    return string.format(
            "%s, Runway %s, cleared to land.",
            callsign,
            runwaySpeech
    )
end

function NASG_ATC_TOWER:HandleInbound(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForArrival(atc, airport, event)

    session.State = atc.States.INBOUND
    session.Facility = atc.Facilities.TOWER
    session.ArrivalRunway = runway
    session.UpdatedAt = timer.getTime()

    if event.intent == "inbound_overhead" then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, enter initial Runway %s. Report initial.",
                        callsign,
                        atc:NormalizeRunway(runway)
                )
        )
        return true
    end

    if event.arrival_type == "straight_in" then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, make straight-in Runway %s. Report five miles final.",
                        callsign,
                        atc:NormalizeRunway(runway)
                )
        )
        return true
    end

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, enter left downwind Runway %s. Report midfield.",
                    callsign,
                    atc:NormalizeRunway(runway)
            )
    )

    return true
end

function NASG_ATC_TOWER:HandleDepartureCheckIn(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForDeparture(atc, airport, session, event)

    session.State = atc.States.LINEUP_AND_WAIT
    session.Facility = atc.Facilities.TOWER
    session.LineupRunway = runway
    session.UpdatedAt = timer.getTime()

    -- Line up and wait readback is accepted if received, but not required.
    if session.PendingReadback and session.PendingReadback.Type == "lineup" then
        session.PendingReadback = nil
    end

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, line up and wait Runway %s.",
                    callsign,
                    atc:NormalizeRunway(runway)
            )
    )

    return true
end

function NASG_ATC_TOWER:HandleTakeoffRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForDeparture(atc, airport, session, event)

    if atc.HasPotentialArrivalTraffic then
        local hasArrivalTraffic, traffic = atc:HasPotentialArrivalTraffic(airport, client)

        if hasArrivalTraffic then
            session.State = atc.States.LINEUP_AND_WAIT
            session.Facility = atc.Facilities.TOWER
            session.LineupRunway = runway
            session.UpdatedAt = timer.getTime()

            local trafficText = "arrival traffic"

            if traffic and traffic[1] then
                trafficText = string.format(
                        "arrival traffic, %.1f miles, altitude %.0f feet",
                        traffic[1].DistanceNM,
                        traffic[1].AltitudeFeet
                )
            end

            self:Send(
                    atc,
                    airport,
                    string.format(
                            "%s, continue holding Runway %s. %s.",
                            callsign,
                            atc:NormalizeRunway(runway),
                            trafficText
                    )
            )

            atc:Log(
                    string.format(
                            "Takeoff held client=%s runway=%s arrivalTrafficCount=%d",
                            tostring(session.ClientKey),
                            tostring(runway),
                            #(traffic or {})
                    )
            )

            return true
        end
    end

    local message, departureFacility, departureFrequency = self:BuildTakeoffClearanceMessage(atc, airport, callsign, runway)

    session.State = atc.States.TAKEOFF_CLEARED
    session.Facility = atc.Facilities.TOWER
    session.NextFacility = departureFacility
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Type = "takeoff",
        InstructionText = message,
        Runway = runway,
        DepartureFacility = departureFacility,
        DepartureFrequency = departureFrequency,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_TOWER:HandleAbortTakeoff(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local groundFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.GROUND)

    session.State = atc.States.HOLDING_POSITION
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    if groundFrequency then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, roger abort. Exit runway when able. Contact Ground %s.",
                        callsign,
                        atc:FormatFrequency(groundFrequency)
                )
        )
    else
        self:Send(atc, airport, string.format("%s, roger abort. Exit runway when able. Contact Ground.", callsign))
    end

    return true
end



function NASG_ATC_TOWER:HandleClosedTraffic(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForArrival(atc, airport, event)

    session.State = atc.States.PATTERN
    session.Facility = atc.Facilities.TOWER
    session.ArrivalRunway = runway
    session.UpdatedAt = timer.getTime()

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, closed traffic approved Runway %s. Report downwind.",
                    callsign,
                    atc:NormalizeRunway(runway)
            )
    )

    return true
end

function NASG_ATC_TOWER:HandleReportInitial(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.INITIAL
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, break approved. Report downwind.", callsign))
    return true
end

function NASG_ATC_TOWER:HandleLandingClearance(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForArrival(atc, airport, event)
    local message = self:BuildLandingClearanceMessage(atc, airport, callsign, runway)

    session.State = atc.States.LANDING_CLEARED
    session.Facility = atc.Facilities.TOWER
    session.ArrivalRunway = runway
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Type = "landing",
        InstructionText = message,
        Runway = runway,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_TOWER:HandleGoingAround(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.GO_AROUND
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, roger go around. Fly runway heading. Report upwind.", callsign))
    return true
end

function NASG_ATC_TOWER:HandleClearOfRunway(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local groundFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.GROUND)

    session.State = atc.States.TRANSFERRED_TO_GROUND
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    if groundFrequency then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, contact Ground %s.",
                        callsign,
                        atc:FormatFrequency(groundFrequency)
                )
        )
    else
        self:Send(atc, airport, string.format("%s, contact Ground.", callsign))
    end

    return true
end

function NASG_ATC_TOWER:NormalizeReadbackText(text)
    if NASG_ATC and NASG_ATC.NormalizeReadbackText then
        return NASG_ATC:NormalizeReadbackText(text)
    end

    local value = tostring(text or "")

    value = string.lower(value)
    value = value:gsub("[,%./%-]", " ")
    value = value:gsub("%s+", " ")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")

    return value
end

function NASG_ATC_TOWER:IsLineupReadbackCorrect(atc, rawText, runway)
    local text = self:NormalizeReadbackText(rawText)
    local runwayText = tostring(runway or "")
    local runwaySpeechText = self:NormalizeReadbackText(atc:NormalizeRunway(runwayText))
    local runwayNumericText = self:NormalizeReadbackText(runwayText)

    local hasLineupReadback =
    string.find(text, "line up and wait", 1, true)
            or string.find(text, "lineup and wait", 1, true)
            or string.find(text, "lined up", 1, true)
            or string.find(text, "lining up", 1, true)
            or string.find(text, "line up", 1, true)

    if not hasLineupReadback then
        return false
    end

    if runwaySpeechText ~= "" and string.find(text, runwaySpeechText, 1, true) then
        return true
    end

    if runwayNumericText ~= "" and string.find(text, runwayNumericText, 1, true) then
        return true
    end

    return runwaySpeechText == "" and runwayNumericText == ""
end

function NASG_ATC_TOWER:IsTakeoffReadbackCorrect(atc, rawText, pending)
    local text = self:NormalizeReadbackText(rawText)
    local runway = tostring(pending.Runway or "")
    local runwaySpeechText = self:NormalizeReadbackText(atc:NormalizeRunway(runway))
    local runwayNumericText = self:NormalizeReadbackText(runway)

    local hasTakeoff =
    string.find(text, "cleared for takeoff", 1, true)
            or string.find(text, "cleared for take off", 1, true)
            or string.find(text, "takeoff", 1, true)

    if not hasTakeoff then
        return false
    end

    if runwaySpeechText ~= "" and string.find(text, runwaySpeechText, 1, true) then
        return true
    end

    if runwayNumericText ~= "" and string.find(text, runwayNumericText, 1, true) then
        return true
    end

    return runwaySpeechText == "" and runwayNumericText == ""
end

function NASG_ATC_TOWER:IsLandingReadbackCorrect(atc, rawText, pending)
    local text = self:NormalizeReadbackText(rawText)
    local runway = tostring(pending.Runway or "")
    local runwaySpeechText = self:NormalizeReadbackText(atc:NormalizeRunway(runway))
    local runwayNumericText = self:NormalizeReadbackText(runway)

    if not string.find(text, "cleared to land", 1, true) then
        return false
    end

    if runwaySpeechText ~= "" and string.find(text, runwaySpeechText, 1, true) then
        return true
    end

    if runwayNumericText ~= "" and string.find(text, runwayNumericText, 1, true) then
        return true
    end

    return runwaySpeechText == "" and runwayNumericText == ""
end

function NASG_ATC_TOWER:HandleReadback(atc, client, airport, session, event)
    local rawText = event and event.raw_text or ""

    if not session then
        return true
    end

    -- Line-up readback is optional; do not block flow if no pending readback exists.
    if session.State == atc.States.LINEUP_AND_WAIT then
        atc:Log(
                string.format(
                        "Optional line up and wait readback received client=%s text=%s",
                        tostring(session.ClientKey),
                        tostring(rawText)
                )
        )
        return true
    end

    if not session.PendingReadback then
        return true
    end

    local pending = session.PendingReadback

    if pending.ExpiresAt and timer.getTime() > pending.ExpiresAt then
        session.PendingReadback = nil
        return true
    end

    local callsign = atc:GetClientCallsign(client, event)

    if pending.Type == "takeoff" then
        if self:IsTakeoffReadbackCorrect(atc, rawText, pending) then
            session.PendingReadback = nil
            atc:Log("Takeoff clearance readback correct for client=" .. tostring(session.ClientKey))
            return true
        end

        self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
        return true
    end

    if pending.Type == "landing" then
        if self:IsLandingReadbackCorrect(atc, rawText, pending) then
            session.PendingReadback = nil
            atc:Log("Landing clearance readback correct for client=" .. tostring(session.ClientKey))
            return true
        end

        self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
        return true
    end

    return true
end

function NASG_ATC_TOWER:HandleSpeechEvent(atc, client, airport, session, event)
    local intent = event.intent
    local request = self.Requests and self.Requests[intent] or nil

    if request then
        if request.Handler and self[request.Handler] then
            return self[request.Handler](self, atc, client, airport, session, event)
        end
    end

    atc:SendSayAgain(airport, atc.Facilities.TOWER, client, event)
    return false
end

NASG_ATC:RegisterStates(NASG_ATC_TOWER.States)
NASG_ATC_TOWER:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.TOWER, NASG_ATC_TOWER)
NASG_ATC:Log("NASG_ATC_Tower loaded")