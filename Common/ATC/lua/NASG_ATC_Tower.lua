NASG_ATC = NASG_ATC or {}
NASG_ATC_TOWER = NASG_ATC_TOWER or {}

NASG_ATC_TOWER.States = {
    WAITING_FOR_TOWER_CHECKIN = "WAITING_FOR_TOWER_CHECKIN",
    HOLDING_SHORT = "HOLDING_SHORT",
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

---------------------------------------------------------------------------
-- Runway / departure clearance thresholds.
--
-- When a client calls holding short (or requests takeoff), Tower scans the
-- runway environment and issues one of three instructions:
--   * Continue holding short  - an arrival is on final about to land.
--   * Line up and wait        - traffic is still on the runway departing,
--                               or just airborne within 0.5 NM.
--   * Cleared for takeoff      - runway and departure corridor are clear.
-- Distances are measured from the airbase reference point; tune per field.
---------------------------------------------------------------------------
NASG_ATC_TOWER.RunwayCheck = {
    RunwayProximityNM   = 1.5,   -- on-ground traffic within this of the field = on the runway
    DepartureClearNM    = 0.5,   -- airborne outbound traffic within this = just departed
    FinalApproachNM     = 5.0,   -- airborne inbound traffic within this may be landing
    ApproachCeilingFt   = 2500,  -- AGL ceiling below which inbound traffic counts as landing
    RollingSpeedKts     = 8,     -- min groundspeed to treat a unit as rolling (not parked)
    InboundToleranceDeg = 70,    -- heading vs bearing-to-field tolerance to call a unit "inbound"
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
                " Contact %s, %s, when airborne.",
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

function NASG_ATC_TOWER:GetAirbaseCoordinate(airport)
    if not airport or not airport.AirbaseName then
        return nil
    end

    local coordinate = nil

    pcall(function()
        local airbase = AIRBASE:FindByName(airport.AirbaseName)

        if airbase then
            coordinate = airbase:GetCoordinate()
        end
    end)

    return coordinate
end

-- Assess the runway environment for a departing client.
-- Returns a status string plus the most relevant conflicting traffic:
--   "HOLD"   - an arrival is on final about to land (keep holding short).
--   "LINEUP" - traffic is rolling on the runway, or airborne within 0.5 NM
--              of the departure end (line up and wait).
--   "CLEAR"  - runway and departure corridor are clear (cleared for takeoff).
-- The requesting client's own aircraft is excluded from the scan.
function NASG_ATC_TOWER:AssessRunwayForDeparture(atc, client, airport)
    local fieldCoord = self:GetAirbaseCoordinate(airport)

    if not fieldCoord then
        -- Cannot locate the field; fail safe to line up and wait.
        atc:Log("Runway assessment unavailable (no airbase coordinate). Defaulting to line up and wait.")
        return "LINEUP", nil
    end

    local cfg = self.RunwayCheck

    local myUnitName = nil
    pcall(function() myUnitName = client:GetName() end)

    local status = "CLEAR"
    local info = nil

    local trafficSet = SET_UNIT:New()
                               :FilterCategories({ "plane", "helicopter" })
                               :FilterOnce()

    trafficSet:ForEachUnit(function(unit)
        if not unit then
            return
        end

        local alive = false
        pcall(function() alive = unit:IsAlive() end)
        if not alive then
            return
        end

        local unitName = nil
        pcall(function() unitName = unit:GetName() end)
        if unitName and myUnitName and unitName == myUnitName then
            return  -- skip the requesting aircraft
        end

        local coord = nil
        pcall(function() coord = unit:GetCoordinate() end)
        if not coord then
            return
        end

        local distanceMeters = atc:GetCoordinateDistanceMeters(fieldCoord, coord)
        if not distanceMeters then
            return
        end

        local distanceNM = distanceMeters / 1852

        -- Ignore anything well clear of the runway environment.
        if distanceNM > cfg.FinalApproachNM then
            return
        end

        local inAir = true
        pcall(function() inAir = unit:InAir() end)

        local speedKts = 0
        pcall(function() speedKts = (unit:GetVelocityKMH() or 0) / 1.852 end)

        local aglFt = 0
        pcall(function()
            local vec3 = coord:GetVec3()
            aglFt = ((vec3 and vec3.y or 0) - coord:GetLandHeight()) / 0.3048
        end)

        -- Is the unit tracking toward the field (inbound) or away (outbound)?
        local inbound = false
        local heading = nil
        pcall(function() heading = unit:GetHeading() end)
        local bearingToField = atc:GetCoordinateBearingDegrees(coord, fieldCoord)

        if heading and bearingToField then
            local diff = math.abs(heading - bearingToField)
            if diff > 180 then
                diff = 360 - diff
            end
            inbound = diff <= cfg.InboundToleranceDeg
        end

        local unitStatus = nil

        if inAir and inbound and distanceNM <= cfg.FinalApproachNM and aglFt <= cfg.ApproachCeilingFt then
            -- Airborne, low, and tracking toward the field: arrival about to land.
            unitStatus = "HOLD"
        elseif inAir and (not inbound) and distanceNM <= cfg.DepartureClearNM then
            -- Airborne, tracking away, still within half a mile: just departed.
            unitStatus = "LINEUP"
        elseif (not inAir) and distanceNM <= cfg.RunwayProximityNM and speedKts >= cfg.RollingSpeedKts then
            -- On the ground and moving within the runway environment: rolling.
            unitStatus = "LINEUP"
        end

        if not unitStatus then
            return
        end

        local candidate = {
            Name       = unitName,
            DistanceNM = distanceNM,
            AltitudeFt = aglFt,
            Status     = unitStatus,
        }

        -- HOLD outranks LINEUP; within a status keep the nearest conflict.
        if unitStatus == "HOLD" then
            if status ~= "HOLD" or (info and candidate.DistanceNM < info.DistanceNM) then
                info = candidate
            end
            status = "HOLD"
        elseif unitStatus == "LINEUP" and status ~= "HOLD" then
            if status ~= "LINEUP" or (info and candidate.DistanceNM < info.DistanceNM) then
                info = candidate
            end
            status = "LINEUP"
        end
    end)

    return status, info
end

-- Shared departure-clearance logic used by both the holding-short check-in
-- and the explicit takeoff request. Issues hold short / line up and wait /
-- cleared for takeoff based on the current runway assessment.
function NASG_ATC_TOWER:IssueDepartureClearance(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = self:GetRunwayForDeparture(atc, airport, session, event)
    local runwaySpeech = atc:NormalizeRunway(runway)
    local status, info = self:AssessRunwayForDeparture(atc, client, airport)

    session.Facility = atc.Facilities.TOWER
    session.LineupRunway = runway
    session.UpdatedAt = timer.getTime()

    atc:Log(
            string.format(
                    "Tower departure assessment client=%s runway=%s status=%s conflict=%s",
                    tostring(session.ClientKey),
                    tostring(runway),
                    tostring(status),
                    info and string.format("%s %.1fNM %.0fftAGL", tostring(info.Name), info.DistanceNM, info.AltitudeFt) or "none"
            )
    )

    if status == "HOLD" then
        session.State = atc.States.HOLDING_SHORT
        session.PendingReadback = nil

        local trafficText = "landing traffic"

        if info and info.DistanceNM then
            trafficText = string.format("landing traffic, %.1f mile final", info.DistanceNM)
        end

        self:Send(
                atc,
                airport,
                string.format("%s, continue holding short Runway %s, %s.", callsign, runwaySpeech, trafficText)
        )

        return true
    end

    if status == "LINEUP" then
        session.State = atc.States.LINEUP_AND_WAIT
        session.PendingReadback = nil

        self:Send(
                atc,
                airport,
                string.format("%s, line up and wait Runway %s.", callsign, runwaySpeech)
        )

        return true
    end

    -- Runway and departure corridor clear: issue takeoff clearance.
    local message, departureFacility, departureFrequency = self:BuildTakeoffClearanceMessage(atc, airport, callsign, runway)

    session.State = atc.States.TAKEOFF_CLEARED
    session.NextFacility = departureFacility

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

function NASG_ATC_TOWER:HandleDepartureCheckIn(atc, client, airport, session, event)
    return self:IssueDepartureClearance(atc, client, airport, session, event)
end

function NASG_ATC_TOWER:HandleTakeoffRequest(atc, client, airport, session, event)
    return self:IssueDepartureClearance(atc, client, airport, session, event)
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
                        "%s, roger abort. Exit runway when able. Contact Ground, %s.",
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
                        "%s, Contact Ground, %s.",
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