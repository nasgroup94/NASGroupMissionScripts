NASG_ATC = NASG_ATC or {}
NASG_ATC_CENTER = NASG_ATC_CENTER or {}

NASG_ATC_CENTER.States = {
    CENTER_CONTROL = "CENTER_CONTROL",
    CENTER_MARSA = "CENTER_MARSA",
    CENTER_OWN_NAVIGATION = "CENTER_OWN_NAVIGATION",
}

NASG_ATC_CENTER.Requests = {
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

    center_check_in = {
        Patterns = {
            "checking in",
            "check in",
            "with you",
            "passing",
            "level",
        },
        Handler = "HandleCheckIn",
    },

    request_flight_following = {
        Patterns = {
            "request flight following",
            "flight following",
            "request advisories",
        },
        Handler = "HandleCheckIn",
    },

    request_direct = {
        Patterns = {
            "request direct",
            "direct",
            "proceed direct",
        },
        Handler = "HandleDirect",
    },

    request_vector_to_waypoint = {
        Patterns = {
            "request vector",
            "vector to",
            "vectors to",
            "request vectors",
        },
        Handler = "HandleVectorToWaypoint",
    },

    request_range = {
        Patterns = {
            "request range",
            "vector to range",
            "direct range",
            "range work",
        },
        Handler = "HandleRangeRequest",
    },

    request_tanker = {
        Patterns = {
            "request tanker",
            "request aar",
            "request air refueling",
            "vector to tanker",
            "request vectors to tanker",
            "direct tanker",
        },
        Handler = "HandleTankerRequest",
    },

    request_recovery = {
        Patterns = {
            "request recovery",
            "request approach",
            "vectors home",
            "vectors for recovery",
            "request vectors home",
        },
        Handler = "HandleRecovery",
    },

    request_divert = {
        Patterns = {
            "request divert",
            "divert",
            "request alternate",
            "request alternate field",
        },
        Handler = "HandleDivert",
    },

    request_frequency_change = {
        Patterns = {
            "frequency change",
            "request frequency change",
            "request switch",
        },
        Handler = "HandleFrequencyChange",
    },

    request_marsa = {
        Patterns = {
            "request marsa",
            "marsa",
            "request military assumes responsibility",
            "military assumes responsibility",
            "request own separation",
            "own separation",
            "we have separation",
            "flight assumes separation",
        },
        Handler = "HandleMARSARequest",
    },

    cancel_marsa = {
        Patterns = {
            "cancel marsa",
            "terminate marsa",
            "cancel own separation",
            "resume atc separation",
            "request atc separation",
        },
        Handler = "HandleMARSACancel",
    },

    request_block_altitude = {
        Patterns = {
            "request block altitude",
            "block altitude",
            "request block",
            "request altitude block",
        },
        Handler = "HandleBlockAltitudeRequest",
    },

    request_vfr_on_top = {
        Patterns = {
            "request vfr on top",
            "vfr on top",
            "request vfr-on-top",
        },
        Handler = "HandleVFROnTopRequest",
    },

    request_course_check = {
        Patterns = {
            "course check",
            "off course check",
            "am i on course",
            "on course",
        },
        Handler = "HandleCourseCheck",
    },

    readback = {
        Patterns = {
            "radar contact",
            "proceed direct",
            "maintain",
            "climb",
            "descend",
            "contact tower",
            "contact awacs",
            "marsa approved",
            "block",
        },
        Handler = "HandleReadback",
    },
}

function NASG_ATC_CENTER:RegisterRequestPatterns(atc)
    local patternMap = {}

    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end

    atc:RegisterIntentPatterns(atc.Facilities.CENTER, patternMap)
end

function NASG_ATC_CENTER:Send(atc, airport, message)
    atc:SendFacilityTTS(airport, atc.Facilities.CENTER, message)
end

function NASG_ATC_CENTER:GetWaypointForEvent(atc, flightPlan, event, fallbackRole)
    if not flightPlan then
        return nil
    end

    local rawText = tostring(event and event.raw_text or "")
    local fix = event and (event.fix or event.destination or event.waypoint or event.vector_target) or nil

    if fix then
        local waypoint = atc:FindFlightPlanWaypoint(flightPlan, fix)

        if waypoint then
            return waypoint
        end
    end

    local waypointNumber = rawText:match("[Ww]aypoint%s+(%d+)")

    if waypointNumber then
        local waypoint = atc:FindWaypointByNumber(flightPlan, tonumber(waypointNumber))

        if waypoint then
            return waypoint
        end
    end

    if fallbackRole then
        local waypoint = atc:FindWaypointByRole(flightPlan, fallbackRole)

        if waypoint then
            return waypoint
        end
    end

    return nil
end

-- Resolves a Center navigation target for a speech event: a flight-plan
-- waypoint first (existing behavior), falling back to a registered tracked
-- point (tanker/bullseye/objective/etc., see NASG_ATC_TrackedPoints.lua),
-- falling back to the current leg of a Clearance-Delivery-assigned route
-- (see NASG_ATC_Procedures.lua) when the event named no explicit target —
-- so an unnamed "request direct"/"request vector" defaults to the next
-- assigned-route leg. Returns targetType ("waypoint"|"tracked_point"), target.
function NASG_ATC_CENTER:GetTargetForEvent(atc, airport, flightPlan, session, event, fallbackRole)
    local waypoint = self:GetWaypointForEvent(atc, flightPlan, event, fallbackRole)

    if waypoint then
        return "waypoint", waypoint
    end

    local rawValue = event and (event.vector_target or event.fix or event.destination or event.waypoint) or nil

    if rawValue then
        local point = atc:FindTrackedPoint(rawValue, airport and airport.Id)

        if point then
            return "tracked_point", point
        end
    end

    if not rawValue and session and session.Route and session.Route.Legs then
        local leg = session.Route.Legs[session.Route.ActiveLegIndex or 1]

        if leg then
            return "tracked_point", leg
        end
    end

    return nil, nil
end

function NASG_ATC_CENTER:SendVectorToTarget(atc, client, airport, event, targetType, target, prefix)
    local callsign = atc:GetClientCallsign(client, event)
    local targetName = targetType == "waypoint"
            and atc:GetWaypointDisplayName(target)
            or tostring(target.Name or target.Id or "point")

    if not NASG_ATC_NAVIGATION then
        self:Send(atc, airport, string.format("%s, unable vector. Navigation helper unavailable.", callsign))
        return true
    end

    local vector

    if targetType == "waypoint" then
        vector = NASG_ATC_NAVIGATION:GetVectorToWaypoint(client, target)
    else
        local coordinate = atc:GetTrackedPointCoordinate(target)
        vector = coordinate and NASG_ATC_NAVIGATION:GetVectorToCoordinate(client, coordinate)
    end

    if not vector then
        self:Send(atc, airport, string.format("%s, unable vector to %s.", callsign, targetName))
        return true
    end

    local messagePrefix = prefix or "proceed direct"

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, %s %s, bearing %s, distance %.0f miles.",
                    callsign,
                    messagePrefix,
                    targetName,
                    NASG_ATC_NAVIGATION:FormatHeading(vector.Bearing),
                    vector.DistanceNM
            )
    )

    return true
end

function NASG_ATC_CENTER:HandleRadioCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    self:Send(
            atc,
            airport,
            string.format("%s, %s, loud and clear.", callsign, atc:GetFacilityCallsign(airport, atc.Facilities.CENTER))
    )

    return true
end

-- Reads the client's CURRENT altitude, queried live at the moment of the
-- call (not cached or polled on a timer). Returns feet, or nil if the
-- aircraft position is unavailable.
function NASG_ATC_CENTER:GetClientAltitudeFeet(client)
    if not client then
        return nil
    end

    local altitudeFeet = nil

    pcall(function()
        local coord = client:GetCoordinate()

        if coord then
            local vec3 = coord:GetVec3()

            if vec3 and vec3.y then
                altitudeFeet = vec3.y / 0.3048
            end
        end
    end)

    return altitudeFeet
end

-- Resolves the pilot's goal altitude for a check-in: a stated goal altitude
-- wins; otherwise falls back to the flight plan's active-leg end-waypoint
-- altitude, if tagged. Returns nil (no reassignment) when neither is known.
function NASG_ATC_CENTER:GetCheckInGoalAltitudeFeet(atc, flightPlan, session, event)
    local stated = tonumber(event and event.goal_altitude_ft)

    if stated then
        return stated
    end

    if not flightPlan then
        return nil
    end

    local activeLeg = atc:GetActiveLeg(flightPlan, session)

    if not activeLeg or not activeLeg.EndWaypoint then
        return nil
    end

    return atc:GetWaypointAltitudeFeet(activeLeg.EndWaypoint)
end

-- Structural resolvability check for a Clearance-Delivery-assigned route:
-- NOT traffic deconfliction (this codebase has no multi-aircraft awareness
-- to compute that) — just confirms every remaining leg still resolves to a
-- coordinate (e.g. a tanker hasn't despawned/died). Returns a warning
-- clause to append to the outgoing message, or nil if everything resolves.
function NASG_ATC_CENTER:CheckRouteSafetyOfFlight(atc, session)
    if not session or not session.Route or not session.Route.Legs then
        return nil
    end

    for index = session.Route.ActiveLegIndex or 1, #session.Route.Legs do
        local leg = session.Route.Legs[index]
        local coordinate = atc:GetTrackedPointCoordinate(leg)

        if not coordinate then
            local legName = tostring(leg.Name or leg.Id or "route point")
            return string.format(" Advise, unable %s, resolve at own discretion.", legName)
        end
    end

    return nil
end

function NASG_ATC_CENTER:HandleCheckIn(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    -- Scan the client's live position on demand rather than relying on the
    -- speech event carrying an altitude (which STT does not provide).
    local liveAltitudeFt = self:GetClientAltitudeFeet(client)
    local altitude = (liveAltitudeFt and atc:FormatAltitudeSpeech(liveAltitudeFt)) or event.altitude or "altitude unknown"
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    session.Center = session.Center or {}

    if event.position_text then
        session.Center.ReportedPositionText = event.position_text
    end

    if event.current_altitude_ft then
        session.Center.ReportedCurrentAltitudeFt = tonumber(event.current_altitude_ft)
    end

    local goalAltitudeFt = self:GetCheckInGoalAltitudeFeet(atc, flightPlan, session, event)
    local altitudeSentence = nil

    if goalAltitudeFt then
        session.Center.RequestedAltitudeFt = goalAltitudeFt
        session.Center.AssignedAltitudeFt = goalAltitudeFt
        session.Center.AssignedAltitudeAt = timer.getTime()

        local verb = "maintain"

        if liveAltitudeFt then
            if goalAltitudeFt > liveAltitudeFt + 250 then
                verb = "climb and maintain"
            elseif goalAltitudeFt < liveAltitudeFt - 250 then
                verb = "descend and maintain"
            end
        end

        local clause = string.format("%s %s", verb, atc:FormatAltitudeSpeech(goalAltitudeFt))
        altitudeSentence = clause:sub(1, 1):upper() .. clause:sub(2) .. "."
    end

    local message

    if flightPlan then
        local activeLeg = atc:GetActiveLeg(flightPlan, session)

        if activeLeg and activeLeg.EndWaypoint then
            message = string.format(
                    "%s, %s, radar contact, %s. Flight plan on file. Proceed toward %s.",
                    callsign,
                    atc:GetFacilityCallsign(airport, atc.Facilities.CENTER),
                    tostring(altitude),
                    atc:GetWaypointDisplayName(activeLeg.EndWaypoint)
            )
        else
            message = string.format(
                    "%s, %s, radar contact, %s. Flight plan on file.",
                    callsign,
                    atc:GetFacilityCallsign(airport, atc.Facilities.CENTER),
                    tostring(altitude)
            )
        end
    else
        message = string.format(
                "%s, %s, radar contact, %s.",
                callsign,
                atc:GetFacilityCallsign(airport, atc.Facilities.CENTER),
                tostring(altitude)
        )
    end

    if altitudeSentence then
        message = message .. " " .. altitudeSentence

        atc:SetPendingReadback(session, {
            Type = "center_altitude",
            InstructionText = message,
            AltitudeFt = goalAltitudeFt,
        })
    end

    local routeWarning = self:CheckRouteSafetyOfFlight(atc, session)

    if routeWarning then
        message = message .. routeWarning
    end

    self:Send(atc, airport, message)

    return true
end

function NASG_ATC_CENTER:HandleDirect(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local targetType, target = self:GetTargetForEvent(atc, airport, flightPlan, session, event, nil)

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    if target then
        local targetName = targetType == "waypoint"
                and atc:GetWaypointDisplayName(target)
                or tostring(target.Name or target.Id)
        local message = string.format("%s, proceed direct %s.", callsign, targetName)

        atc:SetPendingReadback(session, {
            Type = "center_direct",
            InstructionText = message,
            Fix = targetName,
        })

        self:Send(atc, airport, message)
        return true
    end

    local fix = event.vector_target or event.fix or event.destination or event.waypoint or "requested point"
    local message = string.format("%s, proceed direct %s.", callsign, tostring(fix))

    atc:SetPendingReadback(session, {
        Type = "center_direct",
        InstructionText = message,
        Fix = fix,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_CENTER:HandleVectorToWaypoint(atc, client, airport, session, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local targetType, target = self:GetTargetForEvent(atc, airport, flightPlan, session, event, nil)

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    if not target then
        self:Send(atc, airport, string.format("%s, unable. Say requested waypoint.", atc:GetClientCallsign(client, event)))
        return true
    end

    return self:SendVectorToTarget(atc, client, airport, event, targetType, target, "vector for")
end

function NASG_ATC_CENTER:HandleRangeRequest(atc, client, airport, session, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local waypoint = self:GetWaypointForEvent(atc, flightPlan, event, "range")

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    if waypoint then
        return self:SendVectorToTarget(atc, client, airport, event, "waypoint", waypoint, "vector for")
    end

    self:Send(atc, airport, string.format("%s, unable range routing. No range waypoint on file.", atc:GetClientCallsign(client, event)))
    return true
end

function NASG_ATC_CENTER:HandleTankerRequest(atc, client, airport, session, event)
    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    local callsign = atc:GetClientCallsign(client, event)
    local clientCoord = nil

    --pcall(function()
    --    if client and type(client.GetCoordinate) == "function" then
    --        clientCoord = client:GetCoordinate()
    --    end
    --end)
    clientCoord = client:GetCoordinate()

    if not clientCoord then
        self:Send(atc, airport, string.format("%s, unable tanker routing. Aircraft position unavailable.", callsign))
        return true
    end

    if atc.RefreshWatchedAssets then
        local refreshOk, refreshErr = pcall(function()
            atc:RefreshWatchedAssets()
        end)

        if not refreshOk then
            atc:Log("Tanker request asset refresh failed: " .. tostring(refreshErr))
        end
    end

    local tankerMatch = nil

    if atc.FindNearestAsset then
        tankerMatch = atc:FindNearestAsset(client, {
            Role = "tanker",
            Enabled = true,
            Coalition = airport.Coalition or atc.Defaults.Coalition,
        })
    end

    if not tankerMatch or not tankerMatch.Asset or not tankerMatch.Coordinate then
        self:Send(atc, airport, string.format("%s, unable tanker routing. No active tanker found.", callsign))
        return true
    end

    local asset = tankerMatch.Asset
    local tankerName = asset.Name or asset.UnitName or asset.GroupName or asset.Id or "tanker"
    local tankerType = asset.TypeName or asset.Type or asset.Role or "tanker"
    -- Bearing and range from the client's CURRENT position to the tanker.
    local bearing = atc:GetCoordinateBearingDegrees(clientCoord, tankerMatch.Coordinate) or 0

    local distanceNm = tankerMatch.DistanceNM

    if not distanceNm and tankerMatch.DistanceMeters then
        distanceNm = tankerMatch.DistanceMeters / 1852
    end

    distanceNm = distanceNm or 0

    local tacan = "not set"
    local radioFreq = "not set"
    --
    --asset:GetTac

    if asset.Tacan then
        if type(asset.Tacan) == "table" then
            tacan = string.format(
                    "%s%s %s",
                    tostring(asset.Tacan.Channel or ""),
                    tostring(asset.Tacan.Band or ""),
                    tostring(asset.Tacan.Morse or "")
            )
        else
            tacan = tostring(asset.Tacan)
        end
    end

    if asset.Radio then
        radioFreq = atc:FormatFrequency(asset.Radio)
    end

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, closest tanker is %s, %s, vector heading %s, distance %.0f miles. TACAN %s. Radio frequency %s.",
                    callsign,
                    tostring(tankerName),
                    tostring(tankerType),
                    NASG_ATC_NAVIGATION:FormatHeading(bearing),
                    distanceNm,
                    tostring(tacan),
                    tostring(radioFreq)
            )
    )

    return true
end


function NASG_ATC_CENTER:GetRecoveryDescentAltitudeFeet(atc, flightPlan, recoveryAirport)
    if flightPlan then
        local recoveryWaypoint = atc:FindWaypointByRole(flightPlan, "recovery")
        local altitudeFeet = recoveryWaypoint and atc:GetWaypointAltitudeFeet(recoveryWaypoint)

        if altitudeFeet then
            return altitudeFeet
        end
    end

    local centerConfig = atc:GetFacilityConfig(recoveryAirport, atc.Facilities.CENTER)

    return (centerConfig and centerConfig.RecoveryDescentAltitudeFt) or atc.Defaults.RecoveryDescentAltitudeFt
end

function NASG_ATC_CENTER:HandleRecovery(atc, client, airport, session, event)
    --local callsign = atc:GetClientCallsign(client, event)
    local callsign = client:GetCallsign()
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    -- Flight-plan arrival stays authoritative; a Clearance-Delivery-assigned
    -- route's stated destination is only consulted when the flight plan has
    -- none on file.
    local arrivalAirportId = atc:GetFlightPlanArrivalAirportId(flightPlan)
            or (session.Route and session.Route.DestinationText)
    local recoveryAirport = arrivalAirportId and atc:GetAirport(arrivalAirportId) or airport
    local towerFrequency = atc:GetFacilityFrequency(recoveryAirport, atc.Facilities.TOWER)
    local towerCallsign = atc:GetFacilityCallsign(recoveryAirport, atc.Facilities.TOWER)
    local descentAltitudeFt = self:GetRecoveryDescentAltitudeFeet(atc, flightPlan, recoveryAirport)

    session.State = atc.States.INBOUND
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    local handoffText

    if towerFrequency then
        handoffText = string.format("Recovery approved. Contact %s %s.", towerCallsign, atc:FormatFrequency(towerFrequency))
    else
        handoffText = string.format("Recovery approved. Contact %s.", towerCallsign)
    end

    local message

    if descentAltitudeFt then
        message = string.format(
                "%s, descend and maintain %s. %s",
                callsign,
                atc:FormatAltitudeSpeech(descentAltitudeFt),
                handoffText
        )

        atc:SetPendingReadback(session, {
            Type = "center_altitude",
            InstructionText = message,
            AltitudeFt = descentAltitudeFt,
        })
    else
        message = string.format("%s, %s", callsign, handoffText)
    end

    local routeWarning = self:CheckRouteSafetyOfFlight(atc, session)

    if routeWarning then
        message = message .. routeWarning
    end

    self:Send(atc, airport, message)

    return true
end

function NASG_ATC_CENTER:HandleDivert(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local divert = atc:GetPrimaryDivert(flightPlan)

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    if not divert then
        self:Send(atc, airport, string.format("%s, unable divert. No divert field on file.", callsign))
        return true
    end

    local name = divert.name or divert.Name or divert.airport_id or divert.AirportId or "divert field"

    self:Send(atc, airport, string.format("%s, divert approved. Proceed direct %s.", callsign, tostring(name)))
    return true
end

function NASG_ATC_CENTER:HandleFrequencyChange(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)

    if towerFrequency then
        self:Send(
                atc,
                airport,
                string.format("%s, frequency change approved. Contact Tower %s.", callsign, atc:FormatFrequency(towerFrequency))
        )
    else
        self:Send(atc, airport, string.format("%s, frequency change approved.", callsign))
    end

    return true
end

function NASG_ATC_CENTER:HandleMARSARequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local marsa = flightPlan and (flightPlan.marsa or flightPlan.MARSA) or nil

    session.Center = session.Center or {}
    session.Center.MARSAActive = true
    session.Center.MARSAApprovedAt = timer.getTime()
    session.Center.MARSAScope = marsa and (marsa.default_scope or marsa.DefaultScope) or "assigned airspace"
    session.Center.OwnNavigation = true

    session.State = atc.States.CENTER_MARSA
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    local block = marsa and marsa.allowed_block_altitudes and marsa.allowed_block_altitudes[1] or nil

    if block then
        session.Center.BlockAltitudeMinFeet = tonumber(block.min_ft)
        session.Center.BlockAltitudeMaxFeet = tonumber(block.max_ft)

        self:Send(
                atc,
                airport,
                string.format(
                        "%s, MARSA approved within assigned airspace, block %d to %d. Maintain own navigation and separation. Advise cancel MARSA.",
                        callsign,
                        session.Center.BlockAltitudeMinFeet,
                        session.Center.BlockAltitudeMaxFeet
                )
        )
        return true
    end

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, MARSA approved within assigned airspace. Maintain own navigation and separation. Advise cancel MARSA.",
                    callsign
            )
    )

    return true
end

function NASG_ATC_CENTER:HandleMARSACancel(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.Center = session.Center or {}
    session.Center.MARSAActive = false
    session.Center.OwnNavigation = false
    session.Center.MARSACancelledAt = timer.getTime()

    session.State = atc.States.CENTER_CONTROL
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, MARSA cancelled. ATC separation resumed.", callsign))
    return true
end

function NASG_ATC_CENTER:HandleBlockAltitudeRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)
    local marsa = flightPlan and (flightPlan.marsa or flightPlan.MARSA) or nil
    local block = marsa and marsa.allowed_block_altitudes and marsa.allowed_block_altitudes[1] or nil

    session.Center = session.Center or {}

    if event.block_altitude and event.block_altitude.min_ft and event.block_altitude.max_ft then
        session.Center.BlockAltitudeMinFeet = tonumber(event.block_altitude.min_ft)
        session.Center.BlockAltitudeMaxFeet = tonumber(event.block_altitude.max_ft)
    elseif block then
        session.Center.BlockAltitudeMinFeet = tonumber(block.min_ft)
        session.Center.BlockAltitudeMaxFeet = tonumber(block.max_ft)
    end

    if session.Center.BlockAltitudeMinFeet and session.Center.BlockAltitudeMaxFeet then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, block altitude approved, %d to %d.",
                        callsign,
                        session.Center.BlockAltitudeMinFeet,
                        session.Center.BlockAltitudeMaxFeet
                )
        )
        return true
    end

    self:Send(atc, airport, string.format("%s, unable block altitude. Say requested block.", callsign))
    return true
end

function NASG_ATC_CENTER:HandleVFROnTopRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.Center = session.Center or {}
    session.Center.VFROnTop = true
    session.Center.OwnNavigation = true

    session.State = atc.States.CENTER_OWN_NAVIGATION
    session.Facility = atc.Facilities.CENTER
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, VFR on top approved. Maintain own terrain clearance and navigation.", callsign))
    return true
end

function NASG_ATC_CENTER:HandleCourseCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local flightPlan = atc:GetOrAttachFlightPlan(client, session, event)

    if not flightPlan or not NASG_ATC_NAVIGATION then
        self:Send(atc, airport, string.format("%s, unable course check. No flight plan available.", callsign))
        return true
    end

    local leg = atc:GetActiveLeg(flightPlan, session)

    if not leg then
        self:Send(atc, airport, string.format("%s, unable course check. No active route leg.", callsign))
        return true
    end

    local startCoord = NASG_ATC_NAVIGATION:GetWaypointCoordinate(leg.StartWaypoint)
    local endCoord = NASG_ATC_NAVIGATION:GetWaypointCoordinate(leg.EndWaypoint)
    local aircraftCoord = nil

    pcall(function()
        aircraftCoord = client:GetCoordinate()
    end)

    if not startCoord or not endCoord or not aircraftCoord then
        self:Send(atc, airport, string.format("%s, unable course check. Coordinates unavailable.", callsign))
        return true
    end

    local analysis = NASG_ATC_NAVIGATION:AnalyzeLeg(
            startCoord,
            endCoord,
            aircraftCoord,
            NASG_ATC_NAVIGATION:NMToMeters(leg.MaxLateralErrorNM)
    )

    if not analysis then
        self:Send(atc, airport, string.format("%s, unable course check.", callsign))
        return true
    end

    if analysis.OnTrack then
        self:Send(
                atc,
                airport,
                string.format(
                        "%s, on course to %s, distance remaining %.0f miles.",
                        callsign,
                        atc:GetWaypointDisplayName(leg.EndWaypoint),
                        analysis.DistanceRemainingNM
                )
        )
        return true
    end

    local side = analysis.LateralErrorMeters > 0 and "right" or "left"
    local interceptHeading = NASG_ATC_NAVIGATION:GetInterceptHeading(analysis, 30)

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, %.0f miles %s of course. Turn heading %s to rejoin.",
                    callsign,
                    analysis.LateralErrorNM,
                    side,
                    NASG_ATC_NAVIGATION:FormatHeading(interceptHeading)
            )
    )

    return true
end

function NASG_ATC_CENTER:HandleReadback(atc, client, airport, session, event)
    if not session or not session.PendingReadback then
        return true
    end

    local pending = session.PendingReadback

    if pending.ExpiresAt and timer.getTime() > pending.ExpiresAt then
        session.PendingReadback = nil
        return true
    end

    local rawText = event and event.raw_text or ""
    local text = atc:NormalizeReadbackText(rawText)

    if pending.Type == "center_direct" then
        local fix = tostring(pending.Fix or ""):lower()

        if fix == "" or string.find(text, fix, 1, true) then
            session.PendingReadback = nil
            atc:Log("Center direct readback correct for client=" .. tostring(session.ClientKey))
            return true
        end

        local callsign = atc:GetClientCallsign(client, event)
        self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
        return true
    end

    if pending.Type == "center_altitude" then
        if not pending.AltitudeFt or atc:IsAltitudeReadbackCorrect(rawText, pending.AltitudeFt) then
            session.PendingReadback = nil
            atc:Log("Center altitude readback correct for client=" .. tostring(session.ClientKey))
            return true
        end

        local callsign = atc:GetClientCallsign(client, event)
        self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
        return true
    end

    return true
end

function NASG_ATC_CENTER:HandleSpeechEvent(atc, client, airport, session, event)
    local intent = event.intent
    local request = self.Requests and self.Requests[intent] or nil

    if request then
        if request.Handler and self[request.Handler] then
            return self[request.Handler](self, atc, client, airport, session, event)
        end
    end

    atc:SendSayAgain(airport, atc.Facilities.CENTER, client, event)
    return false
end

NASG_ATC:RegisterStates(NASG_ATC_CENTER.States)
NASG_ATC_CENTER:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.CENTER, NASG_ATC_CENTER)
NASG_ATC:Log("NASG_ATC_Center loaded")