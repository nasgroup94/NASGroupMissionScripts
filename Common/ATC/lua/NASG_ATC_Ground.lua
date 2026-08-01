NASG_ATC = NASG_ATC or {}
NASG_ATC_GROUND = NASG_ATC_GROUND or {}

NASG_ATC_GROUND.States = {
    WAITING_FOR_STARTUP_REQUEST = "WAITING_FOR_STARTUP_REQUEST",
    STARTUP_APPROVED = "STARTUP_APPROVED",
    WAITING_FOR_PUSHBACK_REQUEST = "WAITING_FOR_PUSHBACK_REQUEST",
    PUSHBACK_APPROVED = "PUSHBACK_APPROVED",
    WAITING_FOR_TAXI_REQUEST = "WAITING_FOR_TAXI_REQUEST",
    TAXI_CLEARANCE_ISSUED = "TAXI_CLEARANCE_ISSUED",
    TAXIING = "TAXIING",
    TAXIING_TO_EOR = "TAXIING_TO_EOR",
    HOLDING_AT_EOR = "HOLDING_AT_EOR",
    EOR_COMPLETE = "EOR_COMPLETE",
    HOLDING_POSITION = "HOLDING_POSITION",
    HOLDING_SHORT = "HOLDING_SHORT",
    HOLDING_SHORT_FOR_CROSSING = "HOLDING_SHORT_FOR_CROSSING",
    GROUND_COMPLETE = "GROUND_COMPLETE",
    GROUND_EMERGENCY = "GROUND_EMERGENCY",
}

NASG_ATC_GROUND.Requests = {
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
        Handler = "HandleSayAgain"
    },

    readback = {
        Patterns = {
            "taxi runway",
            "taxi to runway",
            "taxi to eor",
            "taxi eor",
            "via",
            "hold short",
            "contact tower",
        },
        Handler = "HandleReadback",
    },

    request_startup = {
        Patterns = {
            "request startup",
            "request start up",
            "startup",
            "start up",
            "request engine start",
        },
        Handler = "HandleStartupRequest",
    },

    request_pushback = {
        Patterns = {
            "request pushback",
            "request push back",
            "pushback request",
            "push back request",
        },
        Handler = "HandlePushbackRequest",
    },

    pushback_complete = {
        Patterns = {
            "pushback complete",
            "push back complete",
            "pushback completed",
            "push back completed",
        },
        Handler = "HandlePushbackComplete",
    },

    request_taxi = {
        Patterns = {
            "request taxi",
            "ready to taxi",
            "taxi request",
            "ready for taxi",
        },
        Handler = "HandleTaxiRequest",
    },

    request_taxi_eor = {
        Patterns = {
            "request taxi to eor",
            "taxi to eor",
            "request eor",
            "request taxi eor",
            "taxi eor",
            "ready to taxi to eor",
            "ready for eor",
            "end of runway",
            "taxi to end of runway",
        },
        Handler = "HandleTaxiEORRequest",
    },

    eor_complete = {
        Patterns = {
            "eor complete",
            "eor checks complete",
            "end of runway complete",
            "arming complete",
            "checks complete",
            "ready at eor",
            "ready from eor",
        },
        Handler = "HandleEORComplete",
    },

    request_progressive_taxi = {
        Patterns = {
            "progressive taxi",
            "request progressive",
            "request progressive taxi",
        },
        Handler = "HandleProgressiveTaxiRequest",
    },

    holding_short_ready = {
        Patterns = {
            "holding short",
            "ready for departure",
            "ready at the hold short",
            "holding short ready",
        },
        Handler = "HandleHoldingShortReady",
    },

    request_taxi_back = {
        Patterns = {
            "taxi back",
            "return to ramp",
            "return to parking",
            "taxi to parking",
            "taxi to line",
        },
        Handler = "HandleTaxiBackRequest",
    },

    request_parking = {
        Patterns = {
            "request parking",
            "taxi to parking",
            "parking",
        },
        Handler = "HandleTaxiBackRequest",
    },

    request_rearm_refuel = {
        Patterns = {
            "rearm",
            "refuel",
            "rearm and refuel",
            "taxi to rearm",
            "taxi to refuel",
            "hot refuel",
        },
        Handler = "HandleRearmRefuelRequest",
    },

    request_shutdown = {
        Patterns = {
            "request shutdown",
            "shutdown",
            "request engine shutdown",
        },
        Handler = "HandleShutdownRequest",
    },

    abort_taxi = {
        Patterns = {
            "abort taxi",
            "aborting taxi",
            "return to ramp",
        },
        Handler = "HandleTaxiBackRequest",
    },

    emergency_ground = {
        Patterns = {
            "emergency",
            "brake failure",
            "engine fire",
            "ground emergency",
        },
        Handler = "HandleEmergency",
    },

    crossing_ready = {
        Patterns = {
            "ready to cross",
            "ready for the crossing",
            "ready for crossing",
        },
        Handler = "HandleCrossingReadyCheckIn",
    },
}


function NASG_ATC_GROUND:RegisterRequestPatterns(atc)
    local patternMap = {}

    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end

    atc:RegisterIntentPatterns(atc.Facilities.GROUND, patternMap)
end

function NASG_ATC_GROUND:Send(atc, airport, message)
    -- Remember the last instruction transmitted so the pilot can request
    -- "say again". _activeSession is set for the current speech event in
    -- HandleSpeechEvent; events are handled one at a time so it always
    -- points at the session that triggered this transmission.
    if self._activeSession and message and message ~= "" then
        self._activeSession.LastGroundInstruction = message
    end

    atc:SendFacilityTTS(airport, atc.Facilities.GROUND, message)
end

function NASG_ATC_GROUND:HandleTemplateRequest(atc, client, airport, session, event, request)
    if request.NewState and atc.States[request.NewState] then
        session.State = atc.States[request.NewState]
    end

    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    local args = {}

    if request.Args then
        args = request.Args(atc, self, client, airport, session, event) or {}
    end

    local message = string.format(request.Response, table.unpack(args))

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_GROUND:BuildStartupApprovedMessage(atc, airport, callsign)
    local currentInformationRaw = atc:GetCurrentATISLetter(airport)
    local currentInformation = atc:GetATISLetterForSpeech(currentInformationRaw)

    if currentInformationRaw then
        return string.format(
                "%s, %s, Information %s current, startup approved. Advise ready to taxi.",
                callsign,
                atc:GetFacilityCallsign(airport, atc.Facilities.GROUND),
                currentInformation
        )
    end

    return string.format(
            "%s, %s, startup approved. Advise ready to taxi.",
            callsign,
            atc:GetFacilityCallsign(airport, atc.Facilities.GROUND)
    )
end

function NASG_ATC_GROUND:BuildWrongATISMessage(atc, airport, callsign)
    local currentInformationRaw = atc:GetCurrentATISLetter(airport)
    local currentInformation = atc:GetATISLetterForSpeech(currentInformationRaw)

    if currentInformationRaw then
        return string.format(
                "%s, %s, Information %s is current. Advise when ready with %s.",
                callsign,
                atc:GetFacilityCallsign(airport, atc.Facilities.GROUND),
                currentInformation,
                currentInformation
        )
    end

    return string.format(
            "%s, %s, verify you have current airport information.",
            callsign,
            atc:GetFacilityCallsign(airport, atc.Facilities.GROUND)
    )
end

function NASG_ATC_GROUND:GetEORConfig(atc, airport, runway)
    if not airport or not airport.EOR or airport.EOR.Enabled ~= true then
        return nil
    end

    if not airport.EOR.Runways then
        return nil
    end

    local runwayKey = tostring(runway or atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "")
    local runwayWithoutLR = runwayKey:gsub("[LRC]$", "")

    return airport.EOR.Runways[runwayKey] or airport.EOR.Runways[runwayWithoutLR]
end

function NASG_ATC_GROUND:GetEORRoute(atc, airport, parkingAreaName, runway)
    local eorConfig = self:GetEORConfig(atc, airport, runway)

    if not eorConfig then
        return nil
    end

    -- Prefer dynamic graph routing when the airport defines a taxi graph.
    if airport.TaxiGraph and NASG_ATC_TAXIGRAPH then
        local parkingArea = atc:GetParkingAreaByName(airport, parkingAreaName)
        local route, routeDetail = NASG_ATC_TAXIGRAPH:RouteParkingToEOR(airport, parkingArea, runway)

        if route and #route > 0 then
            return route, routeDetail
        end
    end

    if eorConfig.TaxiRoutes and parkingAreaName then
        return eorConfig.TaxiRoutes[parkingAreaName]
    end

    return eorConfig.TaxiRoute
end

function NASG_ATC_GROUND:IsClientInEORZone(atc, client, airport, runway)
    local eorConfig = self:GetEORConfig(atc, airport, runway)

    if not eorConfig then
        return false
    end

    if not eorConfig.Zone then
        return true
    end

    local coordinate = nil

    pcall(function()
        coordinate = client:GetCoordinate()
    end)

    if not coordinate then
        return false
    end

    local zone = ZONE:FindByName(eorConfig.Zone)

    if not zone then
        atc:Log("EOR zone not found: " .. tostring(eorConfig.Zone))
        return false
    end

    return zone:IsCoordinateInZone(coordinate)
end

function NASG_ATC_GROUND:BuildEORTaxiClearanceMessage(atc, client, airport, session, callsign)
    local runway = tostring(atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local runwaySpeech = atc:NormalizeRunway(runway)
    local eorConfig = self:GetEORConfig(atc, airport, runway)

    if not eorConfig then
        return nil
    end

    local eorName = eorConfig.Name or ("EOR Runway " .. runwaySpeech)
    local route, routeDetail = self:GetEORRoute(atc, airport, session.ParkingAreaName, runway)
    local routeText = atc:JoinTaxiRoute(route)
    -- Some EORs (e.g. the shared South/North EOR) sit on the far side of a
    -- runway from the ramp, so the taxi-to-EOR leg itself can cross a
    -- runway before the pilot ever reaches the hold-short point.
    local crossingText, crossRunways = self:BuildCrossingInstructions(atc, client, airport, routeDetail, runway)

    -- The clearance names the departure runway explicitly (not just the EOR
    -- name) so the readback has something to check against -- see
    -- IsTaxiReadbackCorrect's unconditional ContainsRunway(pending.Runway).
    local message

    if routeText then
        message = string.format(
                "%s, taxi to %s for Runway %s via the following taxiways: %s.",
                callsign,
                eorName,
                runwaySpeech,
                routeText
        )
    else
        message = string.format("%s, taxi to %s for Runway %s.", callsign, eorName, runwaySpeech)
    end

    if crossingText then
        message = message .. " " .. crossingText
    end

    message = message .. " Remain this frequency. Advise EOR complete."

    return message, crossRunways
end

-- Decides whether Ground may clear a crossing of `crossingRunwayEndId` (an
-- end-id reported by NASG_ATC:GetRouteCrossedRunways). Returns nil when the
-- airport has no Runways config for that end — callers treat nil as "no
-- crossing concept here," the backward-compat gate for airports that haven't
-- declared the new config yet.
--   { Decision = "DEFER" } - the crossed strip is the active runway; Ground
--                            is not authorized to clear it, Tower must.
--   { Decision = "CROSS" } - inactive strip, traffic clear.
--   { Decision = "HOLD" }  - inactive strip, traffic requires holding short.
function NASG_ATC_GROUND:AssessRunwayCrossing(atc, client, airport, crossingRunwayEndId)
    if not airport or not airport.Runways then
        return nil
    end

    local cfg = airport.Runways[tostring(crossingRunwayEndId or "")]

    if not cfg then
        return nil
    end

    local activeDeparture = tostring(atc:GetActiveRunway(airport, true) or "")
    local activeArrival = tostring(atc:GetActiveRunway(airport, false) or "")
    local reciprocal = cfg.Reciprocal and tostring(cfg.Reciprocal) or nil
    local endId = tostring(crossingRunwayEndId)

    local isActive = (endId == activeDeparture or endId == activeArrival)
            or (reciprocal and (reciprocal == activeDeparture or reciprocal == activeArrival))

    if isActive then
        return { Decision = "DEFER", Runway = endId }
    end

    if not cfg.RunwayZone then
        -- No zone declared yet — nothing to scan against; default to
        -- crossable rather than stranding the pilot on an unconfigured
        -- inactive runway.
        return { Decision = "CROSS", Runway = endId }
    end

    local referenceCoord = nil

    pcall(function()
        local zone = ZONE:FindByName(cfg.RunwayZone)
        if zone then
            referenceCoord = zone:GetCoordinate()
        end
    end)

    if not referenceCoord then
        atc:Log("Runway crossing zone not found: " .. tostring(cfg.RunwayZone))
        return { Decision = "CROSS", Runway = endId }
    end

    local myUnitName = nil
    pcall(function() myUnitName = client:GetName() end)

    local runwayCheckCfg = NASG_ATC_TOWER and NASG_ATC_TOWER.RunwayCheck

    local status = atc:AssessRunwayTraffic(
            referenceCoord,
            runwayCheckCfg,
            { ExcludeUnitName = myUnitName, ZoneName = cfg.RunwayZone }
    )

    if status == "CLEAR" then
        return { Decision = "CROSS", Runway = endId }
    end

    return { Decision = "HOLD", Runway = endId }
end

-- Builds the spoken clause(s) for any runways a taxi route crosses en route
-- to `destinationRunway`, plus the structured {Runway=, Decision=} list the
-- pending readback needs to validate the pilot's readback and to resolve a
-- HOLD later via the crossing_ready check-in. Returns nil, nil when the
-- route crosses nothing (or the airport has no Runways config) — the common
-- case today, leaving callers' messages unchanged.
function NASG_ATC_GROUND:BuildCrossingInstructions(atc, client, airport, routeDetail, destinationRunway)
    local crossed = routeDetail and atc:GetRouteCrossedRunways(airport, routeDetail, destinationRunway)

    if not crossed or #crossed == 0 then
        return nil, nil
    end

    local clauses = {}
    local crossRunways = {}

    for _, runwayEndId in ipairs(crossed) do
        local assessment = self:AssessRunwayCrossing(atc, client, airport, runwayEndId)

        if assessment then
            local runwaySpeech = atc:NormalizeRunway(runwayEndId)

            if assessment.Decision == "CROSS" then
                table.insert(clauses, string.format("Cross Runway %s.", runwaySpeech))
            elseif assessment.Decision == "HOLD" then
                table.insert(clauses, string.format("Hold short Runway %s for crossing traffic.", runwaySpeech))
            elseif assessment.Decision == "DEFER" then
                local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)

                if towerFrequency then
                    table.insert(clauses, string.format(
                            "Hold short Runway %s. Contact Tower %s before crossing.",
                            runwaySpeech, atc:FormatFrequency(towerFrequency)
                    ))
                else
                    table.insert(clauses, string.format("Hold short Runway %s. Contact Tower before crossing.", runwaySpeech))
                end
            end

            table.insert(crossRunways, { Runway = runwayEndId, Decision = assessment.Decision })
        end
    end

    if #clauses == 0 then
        return nil, nil
    end

    return table.concat(clauses, " "), crossRunways
end

function NASG_ATC_GROUND:BuildTaxiClearanceMessage(atc, client, airport, session, callsign)
    local runway = tostring(atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local runwaySpeech = atc:NormalizeRunway(runway)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)
    local parkingArea = atc:GetParkingAreaByName(airport, session.ParkingAreaName)
    local route, routeDetail = atc:GetTaxiRoute(airport, parkingArea, runway)
    local routeText = atc:JoinTaxiRoute(route)
    local crossingText, crossRunways = self:BuildCrossingInstructions(atc, client, airport, routeDetail, runway)

    local message

    if routeText then
        message = string.format(
                "%s, taxi to Runway %s via, %s.",
                callsign,
                runwaySpeech,
                routeText
        )
    else
        message = string.format(
                "%s, taxi to Runway %s.",
                callsign,
                runwaySpeech
        )
    end

    if crossingText then
        message = message .. " " .. crossingText
    end

    message = message .. string.format(" Hold short Runway %s.", runwaySpeech)

    -- Always hand the pilot off to Tower when a frequency is configured, even
    -- if no taxiway route resolved (e.g. parking area undetected). Coupling the
    -- handoff to the route would otherwise strand the pilot on Ground.
    if towerFrequency then
        message = message .. string.format(" Contact Tower %s.", atc:FormatFrequency(towerFrequency))
    end

    return message, crossRunways
end

function NASG_ATC_GROUND:BuildEORCompleteTaxiToRunwayMessage(atc, client, airport, session, callsign)
    local runway = tostring(session.EORRunway or atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local runwaySpeech = atc:NormalizeRunway(runway)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)

    local crossingText, crossRunways = nil, nil

    if airport.TaxiGraph and NASG_ATC_TAXIGRAPH then
        local eorNode = NASG_ATC_TAXIGRAPH:GetEORNode(airport, runway)
        local runwayNode = NASG_ATC_TAXIGRAPH:GetRunwayNode(airport, runway)
        local routeDetail = eorNode and runwayNode and NASG_ATC_TAXIGRAPH:ComputeRoute(airport, eorNode, runwayNode)

        crossingText, crossRunways = self:BuildCrossingInstructions(atc, client, airport, routeDetail, runway)
    end

    local message

    if towerFrequency then
        message = string.format(
                "%s, taxi to Runway %s. Hold short Runway %s. Contact Tower %s when holding short.",
                callsign,
                runwaySpeech,
                runwaySpeech,
                atc:FormatFrequency(towerFrequency)
        )
    else
        message = string.format(
                "%s, taxi to Runway %s. Hold short Runway %s.",
                callsign,
                runwaySpeech,
                runwaySpeech
        )
    end

    if crossingText then
        message = message .. " " .. crossingText
    end

    return message, crossRunways
end

function NASG_ATC_GROUND:HandleSayAgain(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local last = session and session.LastGroundInstruction

    if not last or last == "" then
        -- Nothing has been transmitted to this pilot yet. Reply directly
        -- (bypassing Send) so this notice is not itself recorded as the
        -- instruction to repeat on the next "say again".
        atc:SendFacilityTTS(
                airport,
                atc.Facilities.GROUND,
                string.format(
                        "%s, %s, no previous transmission to repeat.",
                        callsign,
                        atc:GetFacilityCallsign(airport, atc.Facilities.GROUND)
                )
        )
        return true
    end

    -- Repeat the last instruction verbatim.
    self:Send(atc, airport, last)
    return true
end

function NASG_ATC_GROUND:HandleRadioCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    self:Send(
            atc,
            airport,
            string.format("%s, %s, loud and clear.", callsign, atc:GetFacilityCallsign(airport, atc.Facilities.GROUND))
    )

    return true
end

function NASG_ATC_GROUND:BuildTaxiReadbackCorrectionMessage(atc, callsign, pending, missing)
    local runway = tostring(pending and pending.Runway or "")
    local runwaySpeech = atc:NormalizeRunway(runway)
    local routeText = atc:JoinTaxiRoute(pending and pending.Route)
    local towerFrequency = pending and pending.TowerFrequency

    if missing == "runway" then
        if routeText then
            return string.format(
                    "%s, negative. Taxi Runway %s via %s.",
                    callsign,
                    runwaySpeech,
                    routeText
            )
        end

        return string.format(
                "%s, negative. Taxi Runway %s.",
                callsign,
                runwaySpeech
        )
    end

    if missing == "route" or self:NormalizeTaxiwayLetter(missing) then
        if routeText then
            return string.format(
                    "%s, negative. Taxi Runway %s via %s.",
                    callsign,
                    runwaySpeech,
                    routeText
            )
        end

        return string.format(
                "%s, negative. Taxi Runway %s.",
                callsign,
                runwaySpeech
        )
    end

    if missing == "hold short" then
        return string.format(
                "%s, negative. Hold short Runway %s.",
                callsign,
                runwaySpeech
        )
    end

    if missing == "tower frequency" then
        if towerFrequency then
            return string.format(
                    "%s, negative. Contact Tower %s.",
                    callsign,
                    atc:FormatFrequency(towerFrequency)
            )
        end

        return string.format(
                "%s, negative. Contact Tower.",
                callsign
        )
    end

    if missing == "taxi" then
        if routeText then
            return string.format(
                    "%s, negative. Taxi Runway %s via %s.",
                    callsign,
                    runwaySpeech,
                    routeText
            )
        end

        return string.format(
                "%s, negative. Taxi Runway %s.",
                callsign,
                runwaySpeech
        )
    end

    return string.format("%s, negative. %s", callsign, pending.InstructionText)
end

function NASG_ATC_GROUND:HandleStartupRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local requireCorrectATIS = airport.RequireCorrectATIS

    if requireCorrectATIS == nil then
        requireCorrectATIS = atc.Defaults.RequireCorrectATIS
    end

    if requireCorrectATIS and not atc:IsATISCorrect(airport, event and event.atis_letter) then
        self:Send(atc, airport, self:BuildWrongATISMessage(atc, airport, callsign))
        return true
    end

    session.StartupApproved = true
    session.ATISVerified = true
    session.State = atc.States.WAITING_FOR_TAXI_REQUEST
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, self:BuildStartupApprovedMessage(atc, airport, callsign))
    return true
end

function NASG_ATC_GROUND:HandleShutdownRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.GROUND_COMPLETE
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, shutdown approved. Good day.", callsign))
    return true
end

function NASG_ATC_GROUND:HandlePushbackRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local direction = event and (event.pushback_direction or event.direction) or nil

    session.State = atc.States.PUSHBACK_APPROVED
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    if direction and direction ~= "" then
        self:Send(atc, airport, string.format("%s, pushback approved, %s. Advise ready to taxi.", callsign, tostring(direction)))
    else
        self:Send(atc, airport, string.format("%s, pushback approved. Advise ready to taxi.", callsign))
    end

    return true
end

function NASG_ATC_GROUND:HandlePushbackComplete(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.WAITING_FOR_TAXI_REQUEST
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, roger. Advise ready to taxi.", callsign))
    return true
end

function NASG_ATC_GROUND:HandleTaxiRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local requireCorrectATIS = airport.RequireCorrectATIS

    atc:Log(
            string.format(
                    "Ground taxi request received client=%s callsign=%s airport=%s state=%s receivedATIS=%s currentATIS=%s raw=%s",
                    tostring(session and session.ClientKey),
                    tostring(callsign),
                    tostring(airport and airport.Id),
                    tostring(session and session.State),
                    tostring(event and event.atis_letter),
                    tostring(atc:GetCurrentATISLetter(airport)),
                    tostring(event and event.raw_text)
            )
    )

    if requireCorrectATIS == nil then
        requireCorrectATIS = atc.Defaults.RequireCorrectATIS
    end

    if requireCorrectATIS and not session.ATISVerified then
        if not atc:IsATISCorrect(airport, event and event.atis_letter) then
            atc:Log(
                    string.format(
                            "Ground taxi request rejected wrong ATIS client=%s received=%s current=%s",
                            tostring(session.ClientKey),
                            tostring(event and event.atis_letter),
                            tostring(atc:GetCurrentATISLetter(airport))
                    )
            )

            self:Send(atc, airport, self:BuildWrongATISMessage(atc, airport, callsign))
            return true
        end

        session.ATISVerified = true
        atc:Log("Ground taxi request ATIS verified client=" .. tostring(session.ClientKey))
    end

    if not session.ParkingAreaName then
        local parkingArea = atc:GetParkingAreaForClient(client, airport)

        if parkingArea then
            session.ParkingAreaName = parkingArea.Name
            atc:Log(
                    string.format(
                            "Ground taxi request detected parking area client=%s parking=%s",
                            tostring(session.ClientKey),
                            tostring(session.ParkingAreaName)
                    )
            )
        else
            atc:Log("Ground taxi request no parking area detected client=" .. tostring(session.ClientKey))
        end
    end

    local runway = tostring(atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local parkingArea = atc:GetParkingAreaByName(airport, session.ParkingAreaName)
    local route = atc:GetTaxiRoute(airport, parkingArea, runway)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)
    local message, crossRunways = self:BuildTaxiClearanceMessage(atc, client, airport, session, callsign)

    atc:Log(
            string.format(
                    "Ground taxi clearance built client=%s runway=%s parking=%s route=%s towerFrequency=%s message=%s",
                    tostring(session.ClientKey),
                    tostring(runway),
                    tostring(session.ParkingAreaName),
                    tostring(route and table.concat(route, ", ") or "nil"),
                    tostring(towerFrequency),
                    tostring(message)
            )
    )

    session.TaxiClearanceIssued = true
    session.State = atc.States.TAXI_CLEARANCE_ISSUED
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Facility = atc.Facilities.GROUND,
        Type = "taxi",
        InstructionText = message,
        Runway = runway,
        Route = route,
        TowerFrequency = towerFrequency,
        CrossRunways = crossRunways,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_GROUND:HandleTaxiEORRequest(atc, client, airport, session, event)    local callsign = atc:GetClientCallsign(client, event)
    local runway = tostring(atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local eorConfig = self:GetEORConfig(atc, airport, runway)

    if not eorConfig then
        if airport.EOR and airport.EOR.UnavailableFallbackToRunway == true then
            self:Send(atc, airport, string.format("%s, EOR unavailable. Taxi runway request approved instead.", callsign))
            return self:HandleTaxiRequest(atc, client, airport, session, event)
        end

        self:Send(atc, airport, string.format("%s, EOR unavailable at this airport. Say request taxi when ready.", callsign))
        return true
    end

    if not session.ParkingAreaName then
        local parkingArea = atc:GetParkingAreaForClient(client, airport)

        if parkingArea then
            session.ParkingAreaName = parkingArea.Name
        end
    end

    local route = self:GetEORRoute(atc, airport, session.ParkingAreaName, runway)
    local message, crossRunways = self:BuildEORTaxiClearanceMessage(atc, client, airport, session, callsign)

    session.State = atc.States.TAXIING_TO_EOR
    session.Facility = atc.Facilities.GROUND
    session.EORRunway = runway
    session.EORClearanceIssued = true
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Facility = atc.Facilities.GROUND,
        Type = "taxi_eor",
        InstructionText = message,
        Runway = runway,
        Route = route,
        CrossRunways = crossRunways,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_GROUND:HandleEORComplete(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = tostring(session.EORRunway or atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local eorConfig = self:GetEORConfig(atc, airport, runway)

    if not eorConfig then
        self:Send(atc, airport, string.format("%s, EOR is not configured for this runway. Say request taxi when ready.", callsign))
        return true
    end

    if airport.EOR and airport.EOR.RequireZone == true and not self:IsClientInEORZone(atc, client, airport, runway) then
        self:Send(
                atc,
                airport,
                string.format("%s, negative, continue taxi to %s. Advise EOR complete.", callsign, eorConfig.Name or "EOR")
        )
        return true
    end

    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)
    local message, crossRunways = self:BuildEORCompleteTaxiToRunwayMessage(atc, client, airport, session, callsign)

    session.State = atc.States.EOR_COMPLETE
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    atc:SetPendingReadback(session, {
        Facility = atc.Facilities.GROUND,
        Type = "taxi_from_eor",
        InstructionText = message,
        Runway = runway,
        Route = nil,
        TowerFrequency = towerFrequency,
        CrossRunways = crossRunways,
    })

    self:Send(atc, airport, message)
    return true
end

function NASG_ATC_GROUND:HandleProgressiveTaxiRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local runway = tostring(atc:GetActiveRunway(airport, true) or airport.ActiveRunway or "active")
    local parkingArea = atc:GetParkingAreaByName(airport, session.ParkingAreaName)
    local route = atc:GetTaxiRoute(airport, parkingArea, runway)

    session.ProgressiveTaxiIndex = session.ProgressiveTaxiIndex or 1
    session.State = atc.States.TAXIING
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    if route and route[session.ProgressiveTaxiIndex] then
        local taxiway = route[session.ProgressiveTaxiIndex]
        session.ProgressiveTaxiIndex = session.ProgressiveTaxiIndex + 1

        self:Send(atc, airport, string.format("%s, progressive taxi approved. Proceed via %s.", callsign, tostring(taxiway)))
        return true
    end

    self:Send(
            atc,
            airport,
            string.format("%s, continue taxi to Runway %s. Hold short Runway %s.", callsign, atc:NormalizeRunway(runway), atc:NormalizeRunway(runway))
    )

    return true
end

function NASG_ATC_GROUND:HandleHoldingShortReady(atc, client, airport, session, event)
    -- A pilot holding short for runway-crossing traffic (not for a Tower
    -- handoff) can also phrase their check-in as a generic "holding short"
    -- call, which resolves to this same intent. Route those to the crossing
    -- check instead of handing them to Tower.
    if session.State == atc.States.HOLDING_SHORT_FOR_CROSSING then
        return self:HandleCrossingReadyCheckIn(atc, client, airport, session, event)
    end

    local callsign = atc:GetClientCallsign(client, event)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)

    session.State = atc.States.TRANSFERRED_TO_TOWER
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    if towerFrequency then
        self:Send(atc, airport, string.format("%s, contact Tower %s.", callsign, atc:FormatFrequency(towerFrequency)))
    else
        self:Send(atc, airport, string.format("%s, contact Tower.", callsign))
    end

    return true
end

-- Re-assesses a pilot's pending runway crossing (see AssessRunwayCrossing)
-- and, if traffic is now clear, releases them to continue taxiing. Shared by
-- the manual check-in and the automatic periodic recheck; only speaks when
-- it actually releases the crossing, so it's safe to poll silently.
function NASG_ATC_GROUND:TryReleaseCrossing(atc, client, airport, session, callsign)
    local runway = session.PendingCrossingRunway

    if not runway or session.State ~= atc.States.HOLDING_SHORT_FOR_CROSSING then
        return false
    end

    local assessment = self:AssessRunwayCrossing(atc, client, airport, runway)

    if not assessment or assessment.Decision ~= "CROSS" then
        return false
    end

    local runwaySpeech = atc:NormalizeRunway(runway)

    session.State = ({
        taxi_eor = atc.States.TAXIING_TO_EOR,
        taxi_from_eor = atc.States.HOLDING_SHORT,
    })[session.PendingCrossingReturnType] or atc.States.TAXIING

    session.PendingCrossingRunway = nil
    session.PendingCrossingReturnType = nil
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, cross Runway %s, continue taxi.", callsign, runwaySpeech))
    return true
end

-- Check-in from a pilot holding short of an inactive runway for crossing
-- traffic. Re-assesses the same runway and either releases the pilot to
-- continue taxiing or repeats the hold.
function NASG_ATC_GROUND:HandleCrossingReadyCheckIn(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    if not session.PendingCrossingRunway or session.State ~= atc.States.HOLDING_SHORT_FOR_CROSSING then
        atc:SendSayAgain(airport, atc.Facilities.GROUND, client, event)
        return true
    end

    local runway = session.PendingCrossingRunway

    if self:TryReleaseCrossing(atc, client, airport, session, callsign) then
        return true
    end

    self:Send(atc, airport, string.format("%s, continue holding short Runway %s.", callsign, atc:NormalizeRunway(runway)))
    return true
end

-- Proactive recheck so a pilot holding short for crossing traffic doesn't
-- have to call back in once the runway goes clear. Mirrors the AWACS
-- picture-broadcast timer pattern: one recurring timer.scheduleFunction that
-- self-stops (returns nil) once nobody is left holding.
NASG_ATC_GROUND.CrossingRecheck = NASG_ATC_GROUND.CrossingRecheck or { Enabled = false, _timerId = nil }
NASG_ATC_GROUND.CrossingRecheckIntervalSecs = NASG_ATC_GROUND.CrossingRecheckIntervalSecs or 20

function NASG_ATC_GROUND:StartCrossingRecheck()
    local cr = self.CrossingRecheck

    if cr.Enabled then
        return
    end

    cr.Enabled = true

    local intervalSecs = self.CrossingRecheckIntervalSecs

    cr._timerId = timer.scheduleFunction(function()
        if not cr.Enabled then
            return nil
        end

        local stillWaiting = false

        pcall(function()
            stillWaiting = NASG_ATC_GROUND:CrossingRecheckTick()
        end)

        if not stillWaiting then
            cr.Enabled = false
            cr._timerId = nil
            return nil
        end

        return timer.getTime() + intervalSecs
    end, {}, timer.getTime() + intervalSecs)
end

function NASG_ATC_GROUND:StopCrossingRecheck()
    local cr = self.CrossingRecheck
    cr.Enabled = false

    if cr._timerId then
        pcall(function() timer.removeFunction(cr._timerId) end)
        cr._timerId = nil
    end
end

-- Re-assesses every session currently holding short for a runway crossing
-- and proactively releases any that have gone clear. Returns true if at
-- least one session is still waiting, so the caller knows whether to keep
-- rescheduling itself.
function NASG_ATC_GROUND:CrossingRecheckTick()
    local stillWaiting = false

    for clientKey, session in pairs(NASG_ATC.ClientSessions or {}) do
        if session.Facility == NASG_ATC.Facilities.GROUND
                and session.State == NASG_ATC.States.HOLDING_SHORT_FOR_CROSSING
                and session.PendingCrossingRunway then

            local airport = session.AirportId and NASG_ATC:GetAirport(session.AirportId) or nil
            local client = nil

            pcall(function() client = CLIENT:FindByName(clientKey) end)

            if airport and client then
                local callsign = NASG_ATC:GetClientCallsign(client, nil)
                local released = self:TryReleaseCrossing(NASG_ATC, client, airport, session, callsign)

                if not released then
                    stillWaiting = true
                end
            else
                stillWaiting = true
            end
        end
    end

    return stillWaiting
end

function NASG_ATC_GROUND:HandleTaxiBackRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local parkingAreaName = event and event.parking_area or session.ParkingAreaName or "parking"

    session.State = atc.States.TAXIING
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    -- Dynamic route from the aircraft's current position (typically the
    -- runway exit ramp it just vacated onto) to its parking area, when the
    -- airport defines a taxi graph.
    local routeText = nil

    if airport.TaxiGraph and NASG_ATC_TAXIGRAPH then
        local parkingArea = atc:GetParkingAreaByName(airport, parkingAreaName)

        if parkingArea then
            local route = NASG_ATC_TAXIGRAPH:RouteFromClientToParking(airport, client, parkingArea)
            routeText = route and atc:JoinTaxiRoute(route) or nil
        end
    end

    if routeText then
        self:Send(atc, airport, string.format("%s, taxi to %s via %s. Remain this frequency.", callsign, tostring(parkingAreaName), routeText))
    else
        self:Send(atc, airport, string.format("%s, taxi to %s. Remain this frequency.", callsign, tostring(parkingAreaName)))
    end

    return true
end

function NASG_ATC_GROUND:HandleRearmRefuelRequest(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local rampName = airport.MaintenanceRamp or "maintenance ramp"

    session.State = atc.States.TAXIING
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, taxi to %s. Remain this frequency.", callsign, rampName))
    return true
end

function NASG_ATC_GROUND:HandleEmergency(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.GROUND_EMERGENCY
    session.Facility = atc.Facilities.GROUND
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, roger emergency. Hold position if able. Emergency services notified.", callsign))
    return true
end

function NASG_ATC_GROUND:ContainsRunway(atc, text, runway)
    local runwayText = tostring(runway or "")

    if runwayText == "" or runwayText == "active" then
        return true
    end

    local normalized = atc:NormalizeReadbackText(text)
    local runwayNumeric = atc:NormalizeReadbackText(runwayText)
    local runwaySpeech = atc:NormalizeReadbackText(atc:NormalizeRunway(runwayText))

    if runwayNumeric ~= "" and string.find(normalized, runwayNumeric, 1, true) then
        return true
    end

    if runwaySpeech ~= "" and string.find(normalized, runwaySpeech, 1, true) then
        return true
    end

    return false
end

function NASG_ATC_GROUND:GetTaxiwayWordAliases()
    return {
        alpha = "A",
        alfa = "A",

        bravo = "B",

        charlie = "C",
        charley = "C",

        delta = "D",

        echo = "E",

        foxtrot = "F",
        fox = "F",

        golf = "G",
        gulf = "G",
        gold = "G",
        gall = "G",

        hotel = "H",

        india = "I",

        juliet = "J",
        juliett = "J",

        kilo = "K",

        lima = "L",

        mike = "M",

        november = "N",

        oscar = "O",

        papa = "P",

        quebec = "Q",

        romeo = "R",

        sierra = "S",

        tango = "T",

        uniform = "U",

        victor = "V",

        whiskey = "W",
        whisky = "W",

        xray = "X",
        ["x-ray"] = "X",
        exray = "X",

        yankee = "Y",

        zulu = "Z",
    }
end

function NASG_ATC_GROUND:NormalizeTaxiwayLetter(value)
    local text = tostring(value or "")

    text = string.lower(text)
    text = text:gsub("[,%./%-]", " ")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    if text == "" then
        return nil
    end

    if string.len(text) == 1 and string.match(text, "%a") then
        return string.upper(text)
    end

    local aliases = self:GetTaxiwayWordAliases()

    if aliases[text] then
        return aliases[text]
    end

    -- Accept values like "taxiway golf" or "taxiway g".
    local taxiwayWord = text:match("^taxiway%s+(.+)$")

    if taxiwayWord then
        return self:NormalizeTaxiwayLetter(taxiwayWord)
    end

    return nil
end

function NASG_ATC_GROUND:BuildTaxiwayLettersFromText(atc, rawText)
    local normalized = atc:NormalizeReadbackText(rawText)
    local taxiwayLetters = {}

    for word in string.gmatch(normalized, "%S+") do
        local letter = self:NormalizeTaxiwayLetter(word)

        if letter then
            taxiwayLetters[letter] = true
        end
    end

    return taxiwayLetters
end

function NASG_ATC_GROUND:ContainsRoute(atc, text, route)
    if not route or #route == 0 then
        return true
    end

    local normalized = atc:NormalizeReadbackText(text)
    local taxiwayLetters = self:BuildTaxiwayLettersFromText(atc, text)

    for _, taxiway in ipairs(route) do
        local expectedLetter = self:NormalizeTaxiwayLetter(taxiway)

        if expectedLetter then
            if not taxiwayLetters[expectedLetter] then
                return false, taxiway
            end
        else
            local taxiwayText = atc:NormalizeReadbackText(taxiway)

            if taxiwayText ~= "" and not string.find(normalized, taxiwayText, 1, true) then
                return false, taxiway
            end
        end
    end

    return true, nil
end

function NASG_ATC_GROUND:ContainsFrequency(atc, text, frequency)
    if not frequency then
        return true
    end

    local normalized = atc:NormalizeReadbackText(text)
    local formattedFrequency = atc:NormalizeReadbackText(atc:FormatFrequency(frequency))
    local numericFrequency = atc:NormalizeReadbackText(tostring(frequency))
    local value = tonumber(frequency)
    local shortFrequency = nil

    if value then
        shortFrequency = atc:NormalizeReadbackText(string.format("%.1f", value))
    end

    if formattedFrequency ~= "" and string.find(normalized, formattedFrequency, 1, true) then
        return true
    end

    if numericFrequency ~= "" and string.find(normalized, numericFrequency, 1, true) then
        return true
    end

    if shortFrequency and shortFrequency ~= "" and string.find(normalized, shortFrequency, 1, true) then
        return true
    end

    return false
end

-- Validates the pilot's readback against one crossing decision. "cross runway
-- X" for CROSS, "hold short runway X" for HOLD, "contact tower" for DEFER.
function NASG_ATC_GROUND:ContainsCrossingPhrase(atc, text, crossing)
    local normalized = atc:NormalizeReadbackText(text)
    local runwayNumeric = atc:NormalizeReadbackText(tostring(crossing.Runway or ""))
    local runwaySpeech = atc:NormalizeReadbackText(atc:NormalizeRunway(crossing.Runway))
    local mentionsRunway = (runwayNumeric ~= "" and string.find(normalized, runwayNumeric, 1, true))
            or (runwaySpeech ~= "" and string.find(normalized, runwaySpeech, 1, true))

    if crossing.Decision == "CROSS" then
        return string.find(normalized, "cross", 1, true) and mentionsRunway
    elseif crossing.Decision == "HOLD" then
        return string.find(normalized, "hold short", 1, true) and mentionsRunway
    elseif crossing.Decision == "DEFER" then
        return string.find(normalized, "contact tower", 1, true) ~= nil
    end

    return true
end

function NASG_ATC_GROUND:IsTaxiReadbackCorrect(atc, rawText, pending)
    local text = atc:NormalizeReadbackText(rawText)

    if not string.find(text, "taxi", 1, true) then
        return false, "taxi"
    end

    if not self:ContainsRunway(atc, rawText, pending.Runway) then
        return false, "runway"
    end

    local routeOk, missingTaxiway = self:ContainsRoute(atc, rawText, pending.Route)

    if not routeOk then
        return false, missingTaxiway or "route"
    end

    if pending.CrossRunways and #pending.CrossRunways > 0 then
        for _, crossing in ipairs(pending.CrossRunways) do
            if not self:ContainsCrossingPhrase(atc, rawText, crossing) then
                return false, "cross " .. tostring(crossing.Runway)
            end
        end
    end

    if pending.Type ~= "taxi_eor" then
        if not string.find(text, "hold short", 1, true) then
            return false, "hold short"
        end

        if not self:ContainsFrequency(atc, rawText, pending.TowerFrequency) then
            return false, "tower frequency"
        end
    end

    return true, nil
end

function NASG_ATC_GROUND:HandleReadback(atc, client, airport, session, event)
    local pending, reason = atc:GetPendingReadback(session, atc.Facilities.GROUND)

    if not pending then
        atc:Log(
                string.format(
                        "Ground readback ignored reason=%s client=%s text=%s",
                        tostring(reason),
                        tostring(session and session.ClientKey),
                        tostring(event and event.raw_text or "")
                )
        )

        atc:SendSayAgain(airport, atc.Facilities.GROUND, client, event)
        return true
    end

    local callsign = atc:GetClientCallsign(client, event)
    local rawText = event and event.raw_text or ""

    if pending.Type == "taxi" or pending.Type == "taxi_eor" or pending.Type == "taxi_from_eor" then
        local ok, missing = self:IsTaxiReadbackCorrect(atc, rawText, pending)

        if ok then
            local failedAttempts = tonumber(pending.FailedAttempts) or 0

            atc:ClearPendingReadback(session)

            local holdingCrossing = nil

            if pending.CrossRunways then
                for _, crossing in ipairs(pending.CrossRunways) do
                    -- DEFER isn't Ground-resolvable (the clause already sent
                    -- the pilot to Tower to sort out); only HOLD parks the
                    -- session waiting on Ground's own crossing_ready check-in.
                    if crossing.Decision == "HOLD" then
                        holdingCrossing = crossing.Runway
                        break
                    end
                end
            end

            if holdingCrossing then
                session.State = atc.States.HOLDING_SHORT_FOR_CROSSING
                session.PendingCrossingRunway = holdingCrossing
                session.PendingCrossingReturnType = pending.Type
                self:StartCrossingRecheck()
            elseif pending.Type == "taxi_eor" then
                session.State = atc.States.TAXIING_TO_EOR
            elseif pending.Type == "taxi_from_eor" then
                session.State = atc.States.HOLDING_SHORT
            else
                session.State = atc.States.TAXIING
            end

            session.UpdatedAt = timer.getTime()

            atc:Log(
                    string.format(
                            "Ground readback correct client=%s type=%s failedAttempts=%d text=%s",
                            tostring(session.ClientKey),
                            tostring(pending.Type),
                            failedAttempts,
                            tostring(rawText)
                    )
            )

            if failedAttempts > 0 then
                self:Send(atc, airport, string.format("%s, readback correct.", callsign))
            end

            return true
        end
        atc:Log(
                string.format(
                        "Ground readback incorrect client=%s type=%s missing=%s expectedRunway=%s expectedRoute=%s expectedTowerFrequency=%s text=%s",
                        tostring(session.ClientKey),
                        tostring(pending.Type),
                        tostring(missing),
                        tostring(pending.Runway),
                        tostring(pending.Route and table.concat(pending.Route, ", ") or "nil"),
                        tostring(pending.TowerFrequency),
                        tostring(rawText)
                )
        )

        pending.FailedAttempts = (tonumber(pending.FailedAttempts) or 0) + 1
        session.PendingReadback = pending
        session.LastPendingReadback = pending

        self:Send(atc, airport, string.format("%s, negative. %s", callsign, pending.InstructionText))
        return true
    end

    atc:Log(
            string.format(
                    "Ground readback ignored unsupported type client=%s type=%s text=%s",
                    tostring(session.ClientKey),
                    tostring(pending.Type),
                    tostring(rawText)
            )
    )

    return true
end


function NASG_ATC_GROUND:HandleSpeechEvent(atc, client, airport, session, event)
local intent = event and event.intent or nil
local request = self.Requests and self.Requests[intent] or nil

-- Track the session for the current transmission so Send() can record the
-- last instruction issued (used by HandleSayAgain).
self._activeSession = session

atc:Log(
string.format(
"Ground handling speech event client=%s intent=%s raw=%s",
tostring(session and session.ClientKey),
tostring(intent),
tostring(event and event.raw_text or "")
)
)

if request then
if request.Handler and self[request.Handler] then
return self[request.Handler](self, atc, client, airport, session, event)
end

if request.Response then
return self:HandleTemplateRequest(atc, client, airport, session, event, request)
end

atc:Log(
string.format(
"Ground request matched but no handler/response intent=%s",
tostring(intent)
)
)
else
atc:Log(
string.format(
"Ground request not matched intent=%s raw=%s",
tostring(intent),
tostring(event and event.raw_text or "")
)
)
end

atc:SendSayAgain(airport, atc.Facilities.GROUND, client, event)
return false
end

NASG_ATC:RegisterStates(NASG_ATC_GROUND.States)
NASG_ATC_GROUND:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.GROUND, NASG_ATC_GROUND)
NASG_ATC:Log("NASG_ATC_Ground loaded")