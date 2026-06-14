NASG_ATC = NASG_ATC or {}

if NASG_ATC.Stop then
    pcall(function()
        NASG_ATC:Stop()
    end)
end

NASG_ATC.Version = "0.4.0"
NASG_ATC.DebugEnabled = NASG_ATC.DebugEnabled or false

NASG_ATC.ClientSessions = NASG_ATC.ClientSessions or {}
NASG_ATC.Airports = NASG_ATC.Airports or {}
NASG_ATC.Controllers = NASG_ATC.Controllers or {}
NASG_ATC.IntentPatterns = NASG_ATC.IntentPatterns or {}
NASG_ATC.WatchedAssetSources = NASG_ATC.WatchedAssetSources or {}
NASG_ATC.AssetRegistry = NASG_ATC.AssetRegistry or {}
NASG_ATC.EventHandler = NASG_ATC.EventHandler or nil
NASG_ATC.Scanner = NASG_ATC.Scanner or nil

NASG_ATC.Defaults = {
    RequireCorrectATIS = true,
    EngineHotSpeedThresholdKnots = 1,
    ClientScanIntervalSeconds = 10,
    TTSRate = 200,
    TTSVolume = 1.0,
    TTSVoice = "Nathan",
    Coalition = coalition.side.BLUE,
    TTSEndpoint = "http://127.0.0.1:8765/tts",
}

NASG_ATC.Facilities = {
    GROUND = "ground",
    TOWER = "tower",
    CENTER = "center",
    AWACS = "awacs",
    ATIS = "atis",
}

NASG_ATC.Intents = {
    RADIO_CHECK = "radio_check",
    SAY_AGAIN = "say_again",
    READBACK = "readback",
}

NASG_ATC.States = {
    CLIENT_DETECTED = "CLIENT_DETECTED",

    TRANSFERRED_TO_GROUND = "TRANSFERRED_TO_GROUND",
    TRANSFERRED_TO_TOWER = "TRANSFERRED_TO_TOWER",
    DEPARTURE_TRANSFERRED = "DEPARTURE_TRANSFERRED",

    CENTER_CONTROL = "CENTER_CONTROL",
    AWACS_CONTROL = "AWACS_CONTROL",
    INBOUND = "INBOUND",
}

function NASG_ATC:AddAssets(source, options)
    if not source then
        self:Log("AddAssets ignored nil source")
        return nil
    end

    options = options or {}

    local sourceType = self:GetMooseAssetSourceType(source)
    local sourceName = options.Name or self:GetMooseObjectName(source) or sourceType or "unknown"

    local watchedSource = {
        Source = source,
        SourceType = sourceType,
        Name = sourceName,
        Coalition = options.Coalition or self.Defaults.Coalition,
        Options = options,
        AddedAt = timer and timer.getTime and timer.getTime() or 0,
    }

    self.WatchedAssetSources[#self.WatchedAssetSources + 1] = watchedSource

    self:Log(
            string.format(
                    "Added ATC asset source: %s type=%s",
                    tostring(sourceName),
                    tostring(sourceType)
            )
    )
    local refreshOk, refreshErr = pcall(function()
        self:RefreshAssetSource(watchedSource)
    end)

    if not refreshOk then
        self:Log("Initial asset source refresh failed: " .. tostring(refreshErr))
    end

    return watchedSource
end

function NASG_ATC:GetMooseAssetSourceType(source)
    if not source then
        return "UNKNOWN"
    end

    if AIRWING and source.ClassName == "AIRWING" then
        return "AIRWING"
    end

    if CHIEF and source.ClassName == "CHIEF" then
        return "CHIEF"
    end

    if AUFTRAG and source.ClassName == "AUFTRAG" then
        return "AUFTRAG"
    end

    if SQUADRON and source.ClassName == "SQUADRON" then
        return "SQUADRON"
    end

    if source.AddAirwing and source.AddMission and source.commander then
        return "CHIEF"
    end

    if source.AddSquadron and source.NewPayload then
        return "AIRWING"
    end

    if source.AssignSquadrons and source.GetName then
        return "AUFTRAG"
    end

    return "UNKNOWN"
end

function NASG_ATC:RefreshAssetSource(watchedSource)
    if not watchedSource or not watchedSource.Source then
        return
    end

    if watchedSource.SourceType == "AIRWING" then
        self:RefreshAirwingAssets(watchedSource)
        return
    end

    if watchedSource.SourceType == "CHIEF" then
        self:RefreshChiefAssets(watchedSource)
        return
    end

    if watchedSource.SourceType == "AUFTRAG" then
        self:RefreshAuftragAsset(watchedSource, watchedSource.Source, nil)
        return
    end

    if watchedSource.SourceType == "SQUADRON" then
        self:RefreshSquadronAsset(watchedSource, watchedSource.Source, nil)
        return
    end

    self:Log("No asset refresh handler for source type: " .. tostring(watchedSource.SourceType))
end

function NASG_ATC:RefreshWatchedAssets()
    for _, watchedSource in ipairs(self.WatchedAssetSources or {}) do
        self:RefreshAssetSource(watchedSource)
    end
end

function NASG_ATC:GetMooseObjectName(source)
    if not source then
        return nil
    end

    local name = nil

    pcall(function()
        if source.GetName then
            name = source:GetName()
        end
    end)

    if name then
        return name
    end

    return source.alias or source.name or source.Name or source.airwingname or source.chiefname
end

function NASG_ATC:RegisterStates(states)
    if not states then
        return
    end

    self.States = self.States or {}

    for key, value in pairs(states) do
        self.States[key] = value
    end
end

function NASG_ATC:Log(message)
    env.info("[NASG_ATC] " .. tostring(message))
end

function NASG_ATC:Debug(message)
    if self.DebugEnabled then
        self:Log(message)
    end
end

function NASG_ATC:Log(message)
    env.info("[NASG_ATC] " .. tostring(message))
end

function NASG_ATC:Debug(message)
    if self.DebugEnabled then
        self:Log(message)
    end
end

function NASG_ATC:JsonEscape(value)
    local text = tostring(value or "")

    text = text:gsub("\\", "\\\\")
    text = text:gsub("\"", "\\\"")
    text = text:gsub("\n", "\\n")
    text = text:gsub("\r", "\\r")
    text = text:gsub("\t", "\\t")

    return text
end

function NASG_ATC:RegisterController(facility, controller)
    if not facility or not controller then
        return
    end

    self.Controllers[tostring(facility):lower()] = controller
    self:Log("Registered controller: " .. tostring(facility))
end

function NASG_ATC:RegisterIntentPatterns(facility, patterns)
    if not facility or not patterns then
        return
    end

    facility = tostring(facility):lower()
    self.IntentPatterns[facility] = self.IntentPatterns[facility] or {}

    for intent, phrases in pairs(patterns) do
        self.IntentPatterns[facility][intent] = self.IntentPatterns[facility][intent] or {}

        for _, phrase in ipairs(phrases or {}) do
            self.IntentPatterns[facility][intent][#self.IntentPatterns[facility][intent] + 1] = tostring(phrase)
        end
    end

    self:Log("Registered intent patterns for controller: " .. tostring(facility))
end

function NASG_ATC:GetIntentPatterns(facility)
    return self.IntentPatterns[tostring(facility or ""):lower()] or {}
end

function NASG_ATC:RegisterAirport(config)
    if not config then
        error("RegisterAirport requires config")
    end

    if not config.Id then
        error("Airport config requires Id")
    end

    if not config.AirbaseName then
        error("Airport config requires AirbaseName")
    end

    self.Airports[config.Id] = config
    self:Log("Registered airport: " .. tostring(config.Id))
end

function NASG_ATC:GetAirport(airportId)
    return self.Airports[airportId]
end

function NASG_ATC:GetFacilityConfig(airport, facility)
    if not airport then
        return nil
    end

    facility = tostring(facility or self.Facilities.GROUND):lower()

    if facility == self.Facilities.GROUND then
        return airport.Ground
    end

    if facility == self.Facilities.TOWER then
        return airport.Tower
    end

    if facility == self.Facilities.CENTER then
        return airport.Center
    end

    if facility == self.Facilities.AWACS then
        return airport.AWACS
    end

    if facility == self.Facilities.ATIS then
        return airport.ATIS
    end

    return nil
end

function NASG_ATC:GetFacilityCallsign(airport, facility)
    local config = self:GetFacilityConfig(airport, facility)

    if config and config.Callsign then
        return config.Callsign
    end

    return tostring(facility or "ATC")
end

function NASG_ATC:GetFacilityFrequency(airport, facility)
    local config = self:GetFacilityConfig(airport, facility)

    if config then
        return config.Frequency
    end

    return nil
end

function NASG_ATC:GetSpeechFormatter()
    return NASG_RADIO_SPEECH
end

function NASG_ATC:NormalizeReadbackText(text)
    local value = tostring(text or "")

    value = string.lower(value)
    value = value:gsub("[,%./%-]", " ")
    value = value:gsub("%s+", " ")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")

    -- Common STT substitutions.
    value = value:gsub("%f[%a]gulf%f[%A]", "golf")
    value = value:gsub("%f[%a]gold%f[%A]", "golf")
    value = value:gsub("%f[%a]whole%f[%A]%s+%f[%a]short%f[%A]", "hold short")
    value = value:gsub("%f[%a]hold%f[%A]%s+%f[%a]sort%f[%A]", "hold short")
    value = value:gsub("%f[%a]lineup%f[%A]", "line up")
    value = value:gsub("%f[%a]take%f[%A]%s+%f[%a]off%f[%A]", "takeoff")
    value = value:gsub("%f[%a]tree%f[%A]", "three")
    value = value:gsub("%f[%a]to%f[%A]", "two")
    value = value:gsub("%f[%a]too%f[%A]", "two")
    value = value:gsub("%f[%a]for%f[%A]", "four")

    return value
end

function NASG_ATC:IsRouteReadbackCorrect(rawText, route)
    if not route or #route == 0 then
        return true
    end

    local text = self:NormalizeReadbackText(rawText)

    for _, taxiway in ipairs(route) do
        local taxiwayText = self:NormalizeReadbackText(taxiway)

        if not string.find(text, taxiwayText, 1, true) then
            return false, taxiway
        end
    end

    return true, nil
end

function NASG_ATC:IsRunwayReadbackCorrect(rawText, runway)
    local text = self:NormalizeReadbackText(rawText)
    local runway = tostring(runway or "")
    local runwaySpeechText = self:NormalizeReadbackText(self:NormalizeRunway(runway))
    local runwayNumericText = self:NormalizeReadbackText(runway)

    if runwaySpeechText ~= "" and string.find(text, runwaySpeechText, 1, true) then
        return true
    end

    if runwayNumericText ~= "" and string.find(text, runwayNumericText, 1, true) then
        return true
    end

    return runwaySpeechText == "" and runwayNumericText == ""
end

function NASG_ATC:IsFrequencyReadbackCorrect(rawText, frequency)
    if not frequency then
        return true
    end

    local text = self:NormalizeReadbackText(rawText)
    local frequencyText = self:NormalizeReadbackText(self:FormatFrequency(frequency))
    local numericFrequencyText = self:NormalizeReadbackText(tostring(frequency))

    if frequencyText ~= "" and string.find(text, frequencyText, 1, true) then
        return true
    end

    if numericFrequencyText ~= "" and string.find(text, numericFrequencyText, 1, true) then
        return true
    end

    return false
end

function NASG_ATC:FormatTextForSpeech(text)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.FormatText then
        return NASG_RADIO_SPEECH:FormatText(text)
    end

    return tostring(text or "")
end

function NASG_ATC:FormatCallsignForSpeech(callsign)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.FormatCallsign then
        return NASG_RADIO_SPEECH:FormatCallsign(callsign)
    end

    return tostring(callsign or "Aircraft")
end

function NASG_ATC:FormatFrequency(frequency)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.FormatFrequency then
        return NASG_RADIO_SPEECH:FormatFrequency(frequency)
    end

    return tostring(frequency or "")
end

function NASG_ATC:NormalizeRunway(runway)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.FormatRunway then
        return NASG_RADIO_SPEECH:FormatRunway(runway)
    end

    return tostring(runway or "")
end

function NASG_ATC:NormalizeATISLetter(value)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.NormalizeATISLetter then
        return NASG_RADIO_SPEECH:NormalizeATISLetter(value)
    end

    return tostring(value or "")
end

function NASG_ATC:GetATISLetterForSpeech(value)
    if NASG_RADIO_SPEECH and NASG_RADIO_SPEECH.FormatATISLetter then
        return NASG_RADIO_SPEECH:FormatATISLetter(value)
    end

    return tostring(value or "")
end

function NASG_ATC:NormalizeClientName(name)
    local text = tostring(name or "")

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    local pipeIndex = string.find(text, "|", 1, true)

    if pipeIndex then
        text = string.sub(text, 1, pipeIndex - 1)
        text = text:gsub("^%s+", "")
        text = text:gsub("%s+$", "")
    end

    return text
end

function NASG_ATC:NormalizeLookupText(value)
    local text = tostring(value or "")

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("|.*$", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = string.upper(text)

    return text
end

function NASG_ATC:NormalizeCallsignText(value)
    local text = self:NormalizeLookupText(value)

    text = text:gsub("%s+", "")
    text = text:gsub("%-", "")
    text = text:gsub("_", "")

    return text
end

function NASG_ATC:DoesTextStartWithPrefix(value, prefix)
    local normalizedValue = self:NormalizeCallsignText(value)
    local normalizedPrefix = self:NormalizeCallsignText(prefix)

    if normalizedValue == "" or normalizedPrefix == "" then
        return false
    end

    return string.sub(normalizedValue, 1, string.len(normalizedPrefix)) == normalizedPrefix
end

function NASG_ATC:GetClientNameSafe(client)
    if not client then
        return nil
    end

    local name = nil

    pcall(function()
        name = client:GetName()
    end)

    return name
end

function NASG_ATC:GetClientPlayerNameSafe(client)
    if not client then
        return nil
    end

    local playerName = nil

    pcall(function()
        playerName = client:GetPlayerName()
    end)

    return playerName
end

function NASG_ATC:GetClientKey(client)
    return self:GetClientNameSafe(client)
end

function NASG_ATC:GetClientCallsign(client, event)
    if event and event.callsign and event.callsign ~= "" then
        return self:FormatCallsignForSpeech(event.callsign)
    end

    if client then
        local playerName = self:GetClientPlayerNameSafe(client)

        if playerName and playerName ~= "" then
            return self:FormatCallsignForSpeech(self:NormalizeClientName(playerName))
        end

        local clientName = self:GetClientNameSafe(client)

        if clientName and clientName ~= "" then
            return self:FormatCallsignForSpeech(self:NormalizeClientName(clientName))
        end
    end

    if event and event.client_name then
        return self:FormatCallsignForSpeech(self:NormalizeClientName(event.client_name))
    end

    return "Aircraft"
end

function NASG_ATC:FindClientByMooseSetPrefix(clientNamePrefix)
    if not clientNamePrefix or clientNamePrefix == "" then
        return nil
    end

    local matchedClient = nil

    local clientSet = SET_CLIENT:New()
                                :FilterCoalitions("blue")
                                :FilterActive()
                                :FilterStart()

    clientSet:ForEachClient(function(client)
        if matchedClient then
            return
        end

        if client then
            local unitName = NASG_ATC:GetClientNameSafe(client)
            local playerName = NASG_ATC:GetClientPlayerNameSafe(client)

            if NASG_ATC:DoesTextStartWithPrefix(unitName, clientNamePrefix)
                    or NASG_ATC:DoesTextStartWithPrefix(playerName, clientNamePrefix) then
                matchedClient = client
            end
        end
    end)

    return matchedClient
end

function NASG_ATC:FindClientByDCSPlayerPrefix(clientNamePrefix)
    if not clientNamePrefix or clientNamePrefix == "" then
        return nil
    end

    local sides = {
        coalition.side.BLUE,
        coalition.side.RED,
    }

    for _, side in ipairs(sides) do
        local players = nil

        pcall(function()
            players = coalition.getPlayers(side)
        end)

        if players then
            for _, unit in ipairs(players) do
                local unitName = nil
                local playerName = nil

                pcall(function()
                    unitName = unit:getName()
                end)

                pcall(function()
                    playerName = unit:getPlayerName()
                end)

                if self:DoesTextStartWithPrefix(unitName, clientNamePrefix)
                        or self:DoesTextStartWithPrefix(playerName, clientNamePrefix) then
                    local client = nil

                    if unitName then
                        pcall(function()
                            client = CLIENT:FindByName(unitName)
                        end)
                    end

                    if client then
                        return client
                    end
                end
            end
        end
    end

    return nil
end

function NASG_ATC:FindClientForSpeechEvent(rawClientName)
    local clientName = self:NormalizeClientName(rawClientName)

    if not clientName or clientName == "" then
        return nil, clientName, "missing"
    end

    local client = nil

    local ok = pcall(function()
        client = CLIENT:FindByName(clientName)
    end)

    if ok and client then
        return client, clientName, "exact"
    end

    client = self:FindClientByMooseSetPrefix(clientName)

    if client then
        return client, clientName, "moose_prefix"
    end

    client = self:FindClientByDCSPlayerPrefix(clientName)

    if client then
        return client, clientName, "dcs_player_prefix"
    end

    return nil, clientName, "not_found"
end

function NASG_ATC:IsClientInAirportArea(client, airport)
    if not client or not airport then
        return false
    end

    local coordinate = nil

    pcall(function()
        coordinate = client:GetCoordinate()
    end)

    if not coordinate then
        return false
    end

    if airport.DetectionZone then
        local zone = ZONE:FindByName(airport.DetectionZone)

        if zone and zone:IsCoordinateInZone(coordinate) then
            return true
        end
    end

    if airport.ParkingAreas then
        for _, parkingArea in ipairs(airport.ParkingAreas) do
            if parkingArea.Zone then
                local zone = ZONE:FindByName(parkingArea.Zone)

                if zone and zone:IsCoordinateInZone(coordinate) then
                    return true
                end
            end
        end
    end

    return false
end

function NASG_ATC:GetParkingAreaForClient(client, airport)
    if not client or not airport or not airport.ParkingAreas then
        return nil
    end

    local coordinate = nil

    pcall(function()
        coordinate = client:GetCoordinate()
    end)

    if not coordinate then
        return nil
    end

    for _, parkingArea in ipairs(airport.ParkingAreas) do
        if parkingArea.Zone then
            local zone = ZONE:FindByName(parkingArea.Zone)

            if zone and zone:IsCoordinateInZone(coordinate) then
                return parkingArea
            end
        end
    end

    return nil
end

function NASG_ATC:GetParkingAreaByName(airport, parkingAreaName)
    if not airport or not airport.ParkingAreas or not parkingAreaName then
        return nil
    end

    for _, parkingArea in ipairs(airport.ParkingAreas) do
        if parkingArea.Name == parkingAreaName then
            return parkingArea
        end
    end

    return nil
end

function NASG_ATC:FindAirportForClient(client)
    if not client then
        return nil
    end

    for _, airport in pairs(self.Airports or {}) do
        if self:IsClientInAirportArea(client, airport) then
            return airport
        end
    end

    return nil
end

function NASG_ATC:IsClientHot(client)
    if not client then
        return false
    end

    local velocityMps = 0

    pcall(function()
        local velocity = client:GetVelocityMPS()

        if velocity then
            velocityMps = velocity
        end
    end)

    local knots = velocityMps * 1.94384

    return knots > self.Defaults.EngineHotSpeedThresholdKnots
end

function NASG_ATC:GetOrCreateSession(client, airport)
    local clientKey = self:GetClientKey(client)

    if not clientKey then
        return nil
    end

    local session = self.ClientSessions[clientKey]

    if not session then
        local parkingArea = self:GetParkingAreaForClient(client, airport)
        local isHot = self:IsClientHot(client)

        session = {
            ClientKey = clientKey,
            AirportId = airport.Id,
            State = isHot and self.States.WAITING_FOR_TAXI_REQUEST or self.States.WAITING_FOR_STARTUP_REQUEST,
            Facility = self.Facilities.GROUND,
            ParkingAreaName = parkingArea and parkingArea.Name or nil,
            StartupApproved = false,
            ATISVerified = false,
            TaxiClearanceIssued = false,
            CreatedAt = timer.getTime(),
            UpdatedAt = timer.getTime(),
        }

        self.ClientSessions[clientKey] = session

        self:Log(
                string.format(
                        "Created ATC session client=%s airport=%s state=%s parking=%s",
                        tostring(clientKey),
                        tostring(airport.Id),
                        tostring(session.State),
                        tostring(session.ParkingAreaName)
                )
        )
    end

    session.UpdatedAt = timer.getTime()
    return session
end


function NASG_ATC:GetPendingReadback(session, facility)
    if not session then
        return nil, "missing_session"
    end

    local pending = session.PendingReadback

    if pending and facility and pending.Facility and pending.Facility ~= facility then
        pending = nil
    end

    if pending and pending.ExpiresAt and timer.getTime() > pending.ExpiresAt then
        self:Log(
                string.format(
                        "Pending readback expired client=%s facility=%s type=%s",
                        tostring(session.ClientKey),
                        tostring(pending.Facility),
                        tostring(pending.Type)
                )
        )

        session.PendingReadback = nil
        pending = nil
    end

    if not pending and session.LastPendingReadback then
        local last = session.LastPendingReadback

        if not facility or not last.Facility or last.Facility == facility then
            pending = last

            self:Log(
                    string.format(
                            "Using last pending readback client=%s facility=%s type=%s",
                            tostring(session.ClientKey),
                            tostring(pending.Facility),
                            tostring(pending.Type)
                    )
            )
        end
    end

    if not pending then
        return nil, "missing_pending_readback"
    end

    return pending, nil
end

function NASG_ATC:ClearPendingReadback(session)
    if not session then
        return
    end

    session.PendingReadback = nil
    session.LastPendingReadback = nil
end

function NASG_ATC:SetPendingReadback(session, readback)
    if not session then
        return
    end

    readback = readback or {}
    readback.IssuedAt = timer.getTime()
    readback.ExpiresAt = timer.getTime() + 180
    readback.FailedAttempts = readback.FailedAttempts or 0

    session.PendingReadback = readback
    session.LastPendingReadback = readback

    self:Log(
            string.format(
                    "Set pending readback client=%s facility=%s type=%s",
                    tostring(session.ClientKey),
                    tostring(readback.Facility),
                    tostring(readback.Type)
            )
    )
end

function NASG_ATC:GetPendingReadback(session, facility)
    if not session then
        return nil, "missing_session"
    end

    local pending = session.PendingReadback

    if pending and facility and pending.Facility and pending.Facility ~= facility then
        pending = nil
    end

    if pending and pending.ExpiresAt and timer.getTime() > pending.ExpiresAt then
        self:Log(
                string.format(
                        "Pending readback expired client=%s facility=%s type=%s",
                        tostring(session.ClientKey),
                        tostring(pending.Facility),
                        tostring(pending.Type)
                )
        )

        session.PendingReadback = nil
        pending = nil
    end

    if not pending and session.LastPendingReadback then
        local last = session.LastPendingReadback

        if not facility or not last.Facility or last.Facility == facility then
            pending = last

            self:Log(
                    string.format(
                            "Using last pending readback client=%s facility=%s type=%s",
                            tostring(session.ClientKey),
                            tostring(pending.Facility),
                            tostring(pending.Type)
                    )
            )
        end
    end

    if not pending then
        return nil, "missing_pending_readback"
    end

    return pending, nil
end

function NASG_ATC:ClearPendingReadback(session)
    if not session then
        return
    end

    session.PendingReadback = nil
    session.LastPendingReadback = nil
end



function NASG_ATC:GetCurrentATISLetter(airport)
    if not airport then
        return nil
    end

    if airport.ATIS and airport.ATIS.CurrentInformation then
        return tostring(airport.ATIS.CurrentInformation)
    end

    return nil
end

function NASG_ATC:IsATISCorrect(airport, receivedLetter)
    local currentLetter = self:GetCurrentATISLetter(airport)

    if not currentLetter or currentLetter == "" then
        return true
    end

    if not receivedLetter or receivedLetter == "" then
        return false
    end

    return self:NormalizeATISLetter(currentLetter) == self:NormalizeATISLetter(receivedLetter)
end

function NASG_ATC:GetActiveRunway(airport, takeoff)
    if not airport then
        return nil
    end

    if takeoff == false and airport.ArrivalRunway then
        return tostring(airport.ArrivalRunway)
    end

    if airport.ActiveRunway then
        return tostring(airport.ActiveRunway)
    end

    return nil
end

function NASG_ATC:JoinTaxiRoute(route)
    if not route or #route == 0 then
        return nil
    end

    local parts = {}

    for _, taxiway in ipairs(route) do
        parts[#parts + 1] = tostring(taxiway)
    end

    return table.concat(parts, ", ")
end

function NASG_ATC:GetTaxiRoute(airport, parkingArea, runway)
    if not airport or not parkingArea or not parkingArea.TaxiRoutes then
        return nil
    end

    local runwayKey = tostring(runway or self:GetActiveRunway(airport, true) or airport.ActiveRunway or "")
    local runwayWithoutLR = runwayKey:gsub("[LRC]$", "")

    return parkingArea.TaxiRoutes[runwayKey] or parkingArea.TaxiRoutes[runwayWithoutLR]
end

function NASG_ATC:SendFacilityTTS(airport, facility, messageText)
    if not messageText or messageText == "" then
        return
    end

    local config = self:GetFacilityConfig(airport, facility)

    if not airport or not config then
        self:Log("Cannot send TTS: missing facility config " .. tostring(facility))
        return
    end

    if not MSRS then
        self:Log("Cannot send TTS: MSRS unavailable. Message: " .. tostring(messageText))
        return
    end

    messageText = self:FormatTextForSpeech(messageText)

    local msrs = nil

    pcall(function()
        msrs = MSRS:New(
                "",
                config.Frequency,
                config.Modulation or radio.modulation.AM
        )
    end)

    if not msrs then
        self:Log("Failed to create MSRS for facility: " .. tostring(facility))
        return
    end

    pcall(function()
        msrs:SetBackendPythonWebSocket(config.TTSEndpoint or airport.TTSEndpoint or self.Defaults.TTSEndpoint)
    end)

    pcall(function()
        msrs:SetCoalition(airport.Coalition or self.Defaults.Coalition)
    end)

    pcall(function()
        msrs:SetLabel(config.Callsign or self:GetFacilityCallsign(airport, facility))
    end)

    pcall(function()
        msrs:SetVolume(config.Volume or self.Defaults.TTSVolume)
    end)

    msrs.voice = config.Voice or self.Defaults.TTSVoice
    msrs.speed = config.Speed or self.Defaults.TTSRate
    msrs.pitch = config.Pitch or 0

    pcall(function()
        msrs:PlayText(messageText, 0)
    end)
end

function NASG_ATC:SendSayAgain(airport, facility, client, event)
    self:SendFacilityTTS(
            airport,
            facility,
            string.format(
                    "%s, %s, say again your request.",
                    self:GetClientCallsign(client, event),
                    self:GetFacilityCallsign(airport, facility)
            )
    )
end

function NASG_ATC:HandleSpeechEvent(event)
    if not event then
        return false
    end

    local airportId = event.airport_id or event.airport or "al_minhad"
    local airport = self:GetAirport(airportId)

    if not airport then
        self:Log("Speech event ignored. Unknown airport: " .. tostring(airportId))
        return false
    end

    local rawClientName = event.client_name or event.client or event.unit_name
    local client, clientName, matchType = self:FindClientForSpeechEvent(rawClientName)

    if not client then
        self:Log(
                string.format(
                        "Speech event ignored. Client not found raw=%s normalized=%s match=%s",
                        tostring(rawClientName),
                        tostring(clientName),
                        tostring(matchType)
                )
        )
        return false
    end

    local session = self:GetOrCreateSession(client, airport)

    if not session then
        self:Log("Speech event ignored. Could not create session for " .. tostring(clientName))
        return false
    end

    local facility = tostring(event.facility or event.service or self.Facilities.GROUND):lower()
    local controller = self.Controllers[facility]

    if not controller or not controller.HandleSpeechEvent then
        self:SendSayAgain(airport, facility, client, event)
        return false
    end

    return controller:HandleSpeechEvent(self, client, airport, session, event)
end

function NASG_ATC:HandleClientBirth(client, eventData)
    local airport = self:FindAirportForClient(client)

    if not airport then
        return
    end

    self:GetOrCreateSession(client, airport)
end

function NASG_ATC:HandleClientEngineStart(client, eventData)
    local airport = self:FindAirportForClient(client)

    if not airport then
        return
    end

    local session = self:GetOrCreateSession(client, airport)

    if not session then
        return
    end

    if session.State == self.States.WAITING_FOR_STARTUP_REQUEST then
        session.StartupApproved = true
        session.State = self.States.WAITING_FOR_TAXI_REQUEST
        session.UpdatedAt = timer.getTime()

        self:Log("Engine start detected; moved client to waiting for taxi: " .. tostring(session.ClientKey))
    end
end

function NASG_ATC:GetClientFromEvent(eventData)
    if not eventData then
        return nil
    end

    local unitName = nil

    if eventData.IniUnitName then
        unitName = eventData.IniUnitName
    elseif eventData.IniUnit then
        pcall(function()
            unitName = eventData.IniUnit:GetName()
        end)
    end

    if not unitName or unitName == "" then
        return nil
    end

    local playerName = nil

    if eventData.IniUnit then
        pcall(function()
            playerName = eventData.IniUnit:getPlayerName()
        end)
    end

    if not playerName or playerName == "" then
        return nil
    end

    local client = nil

    pcall(function()
        client = CLIENT:FindByName(unitName)
    end)

    return client
end

function NASG_ATC:StartEventHandler()
    if self.EventHandler then
        return
    end

    self.EventHandler = EVENTHANDLER:New()
    self.EventHandler:HandleEvent(EVENTS.Birth)
    self.EventHandler:HandleEvent(EVENTS.EngineStartup)

    function self.EventHandler:OnEventBirth(eventData)
        local client = NASG_ATC:GetClientFromEvent(eventData)

        if client then
            NASG_ATC:HandleClientBirth(client, eventData)
        end
    end

    function self.EventHandler:OnEventEngineStartup(eventData)
        local client = NASG_ATC:GetClientFromEvent(eventData)

        if client then
            NASG_ATC:HandleClientEngineStart(client, eventData)
        end
    end

    self:Log("Started ATC event handler")
end

function NASG_ATC:StopEventHandler()
    if not self.EventHandler then
        return
    end

    pcall(function()
        self.EventHandler:UnHandleEvent(EVENTS.Birth)
        self.EventHandler:UnHandleEvent(EVENTS.EngineStartup)
    end)

    self.EventHandler = nil
    self:Log("Stopped ATC event handler")
end

function NASG_ATC:ScanClientsForAirport(airport)
    if not airport then
        return
    end

    local clientSet = SET_CLIENT:New()
                                :FilterCoalitions("blue")
                                :FilterActive()
                                :FilterStart()

    clientSet:ForEachClient(function(client)
        if client and client:IsAlive() and NASG_ATC:IsClientInAirportArea(client, airport) then
            NASG_ATC:GetOrCreateSession(client, airport)
        end
    end)
end

function NASG_ATC:UpsertAsset(asset)
    if not asset then
        return nil
    end

    if not asset.Id then
        asset.Id = tostring(asset.SourceType or "asset") .. "_" .. tostring(#self.AssetRegistry + 1)
    end

    asset.Enabled = asset.Enabled ~= false
    asset.Role = asset.Role and tostring(asset.Role):lower() or self:GetRoleForMissionType(asset.MissionType)
    asset.UpdatedAt = timer and timer.getTime and timer.getTime() or 0

    self.AssetRegistry[asset.Id] = asset

    return asset
end

function NASG_ATC:GetRoleForMissionType(missionType)
    if not missionType then
        return nil
    end

    if AUFTRAG and AUFTRAG.Type then
        if missionType == AUFTRAG.Type.TANKER then
            return "tanker"
        end

        if missionType == AUFTRAG.Type.AWACS then
            return "awacs"
        end

        if missionType == AUFTRAG.Type.CAP then
            return "cap"
        end

        if missionType == AUFTRAG.Type.ORBIT then
            return "orbit"
        end
    end

    return tostring(missionType):lower()
end

function NASG_ATC:GetCoordinateDistanceMeters(fromCoord, toCoord)
    if not fromCoord or not toCoord then
        return nil
    end

    local distance = nil

    pcall(function()
        if type(fromCoord.Get2DDistance) == "function" then
            distance = fromCoord:Get2DDistance(toCoord)
        end
    end)

    if distance then
        return distance
    end

    pcall(function()
        if type(fromCoord.Get3DDistance) == "function" then
            distance = fromCoord:Get3DDistance(toCoord)
        end
    end)

    return distance
end

function NASG_ATC:GetCoordinateBearingDegrees(fromCoord, toCoord)
    if not fromCoord or not toCoord then
        return nil
    end

    local fromVec3 = nil
    local toVec3 = nil

    pcall(function()
        if type(fromCoord.GetVec3) == "function" then
            fromVec3 = fromCoord:GetVec3()
        end
    end)

    pcall(function()
        if type(toCoord.GetVec3) == "function" then
            toVec3 = toCoord:GetVec3()
        end
    end)

    if fromVec3 and toVec3 and fromVec3.x and fromVec3.z and toVec3.x and toVec3.z then
        local dx = toVec3.x - fromVec3.x
        local dz = toVec3.z - fromVec3.z
        local heading = math.deg(math.atan2(dx, dz))

        if heading < 0 then
            heading = heading + 360
        end

        if heading == 0 then
            heading = 360
        end

        return heading
    end

    return nil
end

function NASG_ATC:RefreshAirwingAssets(watchedSource)
    if not watchedSource or not watchedSource.Source then
        return
    end

    local tankerCount = self:RefreshAirwingOpsGroupsForRole(watchedSource, "tanker")
    local awacsCount = self:RefreshAirwingOpsGroupsForRole(watchedSource, "awacs")

    self:Log(
            string.format(
                    "Refreshed AIRWING assets source=%s tankerGroups=%d awacsGroups=%d",
                    tostring(watchedSource.Name or "unknown"),
                    tonumber(tankerCount) or 0,
                    tonumber(awacsCount) or 0
            )
    )

    local airwing = watchedSource.Source

    if airwing.cohorts then
        for _, squadron in pairs(airwing.cohorts) do
            self:RefreshSquadronAsset(watchedSource, squadron, airwing)
        end
    end
end

function NASG_ATC:RefreshSquadronAsset(watchedSource, squadron, airwing)
    if not squadron then
        return
    end

    local squadronName = self:GetMooseObjectName(squadron) or squadron.name or squadron.alias or "squadron"
    local capabilities = squadron.missiontypes or squadron.MissionTypes or squadron.capabilities or squadron.Capabilities

    if type(capabilities) ~= "table" then
        capabilities = { capabilities }
    end

    for _, missionType in ipairs(capabilities or {}) do
        self:UpsertAsset({
            Id = string.format(
                    "squadron_%s_%s",
                    tostring(squadronName),
                    tostring(missionType)
            ),
            SourceType = "SQUADRON",
            Source = squadron,
            Airwing = airwing,
            Squadron = squadron,
            Name = squadronName,
            Role = self:GetRoleForMissionType(missionType),
            MissionType = missionType,
            Coalition = watchedSource.Coalition,
        })
    end
end

function NASG_ATC:InstallMooseChiefHooks()
    if self.MooseChiefHooksInstalled then
        return
    end

    if not CHIEF or not CHIEF.AddMission then
        self:Log("CHIEF hook not installed; CHIEF:AddMission unavailable")
        return
    end

    self.MooseChiefHooksInstalled = true
    self.OriginalChiefAddMission = CHIEF.AddMission

    CHIEF.AddMission = function(chief, mission)
        local result = NASG_ATC.OriginalChiefAddMission(chief, mission)

        if NASG_ATC and NASG_ATC.OnChiefMissionAdded then
            NASG_ATC:OnChiefMissionAdded(chief, mission)
        end

        return result
    end

    self:Log("Installed MOOSE CHIEF:AddMission hook")
end

function NASG_ATC:OnChiefMissionAdded(chief, mission)
    if not chief or not mission then
        return
    end

    for _, watchedSource in ipairs(self.WatchedAssetSources or {}) do
        if watchedSource.Source == chief then
            self:RefreshAuftragAsset(watchedSource, mission, chief)
            return
        end
    end
end

function NASG_ATC:GetAssets(filter)
    local results = {}

    for _, asset in pairs(self.AssetRegistry or {}) do
        local include = true

        if filter then
            if filter.Enabled ~= nil and asset.Enabled ~= filter.Enabled then
                include = false
            end

            if filter.Role and tostring(asset.Role or ""):lower() ~= tostring(filter.Role):lower() then
                include = false
            end

            if filter.MissionType and asset.MissionType ~= filter.MissionType then
                include = false
            end

            if filter.Coalition and asset.Coalition ~= filter.Coalition then
                include = false
            end
        end

        if include then
            results[#results + 1] = asset
        end
    end

    return results
end

function NASG_ATC:RefreshChiefAssets(watchedSource)
    local chief = watchedSource.Source

    if not chief then
        return
    end

    if chief.airwings then
        for _, airwing in pairs(chief.airwings) do
            self:RefreshAirwingAssets({
                Source = airwing,
                SourceType = "AIRWING",
                Name = self:GetMooseObjectName(airwing),
                Coalition = watchedSource.Coalition,
                Options = watchedSource.Options,
            })
        end
    end

    if chief.commander and chief.commander.missions then
        for _, mission in pairs(chief.commander.missions) do
            self:RefreshAuftragAsset(watchedSource, mission, chief)
        end
    end
end

function NASG_ATC:RefreshAuftragAsset(watchedSource, mission, chief)
    if not mission then
        return
    end

    local missionName = self:GetMooseObjectName(mission) or mission.name or mission.Name or "mission.json"
    local missionType = mission.type or mission.Type or mission.missiontype or mission.MissionType
    local coordinate = self:GetAuftragCoordinate(mission)

    self:UpsertAsset({
        Id = string.format(
                "auftrag_%s_%s",
                tostring(missionName),
                tostring(mission.auftragsnummer or mission.uid or missionType or "")
        ),
        SourceType = "AUFTRAG",
        Source = mission,
        Chief = chief,
        Auftrag = mission,
        Name = missionName,
        Role = self:GetRoleForMissionType(missionType),
        MissionType = missionType,
        Coordinate = coordinate,
        Coalition = watchedSource.Coalition,
        Radio = mission.radio or mission.Radio or mission.frequency or mission.Frequency,
        Tacan = self:GetAuftragTacan(mission),
    })
end

function NASG_ATC:GetAuftragCoordinate(mission)
    if not mission then
        return nil
    end

    local coordinate = nil

    pcall(function()
        if mission.GetCoordinate then
            coordinate = mission:GetCoordinate()
        end
    end)

    if coordinate then
        return coordinate
    end

    return mission.coordinate or mission.Coordinate or mission.coord or mission.Coord
end

function NASG_ATC:GetAssetCoordinate(asset)
    if not asset then
        return nil
    end

    if asset.Unit then
        local coordinate = nil

        pcall(function()
            if type(asset.Unit.IsAlive) == "function" and not asset.Unit:IsAlive() then
                return
            end

            if type(asset.Unit.GetCoordinate) == "function" then
                coordinate = asset.Unit:GetCoordinate()
            end
        end)

        if coordinate then
            return coordinate
        end
    end

    if asset.UnitName and UNIT and UNIT.FindByName then
        local coordinate = nil

        pcall(function()
            local unit = UNIT:FindByName(asset.UnitName)

            if unit and type(unit.GetCoordinate) == "function" then
                coordinate = unit:GetCoordinate()
            end
        end)

        if coordinate then
            return coordinate
        end
    end

    if asset.Coordinate then
        return asset.Coordinate
    end

    return nil
end

function NASG_ATC:FindNearestAsset(client, filter)
    if not client then
        return nil
    end

    local clientCoord = nil

    pcall(function()
        clientCoord = client:GetCoordinate()
    end)

    if not clientCoord then
        self:Log("FindNearestAsset failed: client coordinate unavailable")
        return nil
    end

    local nearestAsset = nil
    local nearestCoordinate = nil
    local shortestDistance = math.huge
    local considered = 0
    local skippedNoCoordinate = 0
    local skippedNoDistance = 0

    for _, asset in ipairs(self:GetAssets(filter)) do
        considered = considered + 1

        local assetCoord = self:GetAssetCoordinate(asset)

        if not assetCoord then
            skippedNoCoordinate = skippedNoCoordinate + 1
        else
            local distance = nil

            pcall(function()
                if type(clientCoord.Get2DDistance) == "function" then
                    distance = clientCoord:Get2DDistance(assetCoord)
                end
            end)

            if not distance then
                pcall(function()
                    if type(clientCoord.Get3DDistance) == "function" then
                        distance = clientCoord:Get3DDistance(assetCoord)
                    end
                end)
            end

            if not distance then
                skippedNoDistance = skippedNoDistance + 1
            elseif distance < shortestDistance then
                shortestDistance = distance
                nearestAsset = asset
                nearestCoordinate = assetCoord
            end
        end
    end

    self:Log(
            string.format(
                    "FindNearestAsset filterRole=%s considered=%d skippedNoCoordinate=%d skippedNoDistance=%d found=%s",
                    tostring(filter and filter.Role or "nil"),
                    considered,
                    skippedNoCoordinate,
                    skippedNoDistance,
                    tostring(nearestAsset and (nearestAsset.Name or nearestAsset.Id) or "nil")
            )
    )

    if not nearestAsset then
        return nil
    end

    return {
        Asset = nearestAsset,
        Coordinate = nearestCoordinate,
        DistanceMeters = shortestDistance,
        DistanceNM = shortestDistance / 1852,
    }
end

function NASG_ATC:FormatDebugValue(value)
    if value == nil then
        return "nil"
    end

    if type(value) == "table" then
        local parts = {}

        for key, item in pairs(value) do
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(item)
        end

        return "{" .. table.concat(parts, ", ") .. "}"
    end

    return tostring(value)
end

function NASG_ATC:SafeToString(value)
    local ok, result = pcall(function()
        return tostring(value)
    end)

    if ok then
        return result
    end

    return "< tostring failed >"
end

function NASG_ATC:GetAssetDebugLine(asset, index)
    if not asset then
        return string.format("[%d] nil asset", tonumber(index) or 0)
    end

    local coordinateText = "none"
    local coordinate = nil

    if self.GetAssetCoordinate then
        local coordOk, coordResult = pcall(function()
            return self:GetAssetCoordinate(asset)
        end)

        if coordOk then
            coordinate = coordResult
        else
            coordinateText = "coordinate error: " .. tostring(coordResult)
        end
    end

    if coordinate then
        coordinateText = self:SafeToString(coordinate)

        local coordTextOk, coordTextResult = pcall(function()
            if coordinate.ToStringLLDMS then
                return coordinate:ToStringLLDMS()
            end

            if coordinate.ToStringLLDDM then
                return coordinate:ToStringLLDDM()
            end

            return tostring(coordinate)
        end)

        if coordTextOk and coordTextResult then
            coordinateText = coordTextResult
        end
    end

    local sourceType = asset.SourceType or "unknown"
    local name = asset.Name or asset.Id or "unnamed"
    local role = asset.Role or "unknown"
    local missionType = asset.MissionType or asset.Type or "unknown"
    local enabled = asset.Enabled ~= false
    local radio = asset.Radio or asset.Frequency or "not set"
    local tacan = "not set"

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

    local taskStatus = "unknown"

    local statusOk, statusResult = pcall(function()
        if asset.Auftrag then
            return asset.Auftrag.status or asset.Auftrag.Status or asset.Auftrag.statusChief or "unknown"
        end

        if asset.Source then
            return asset.Source.status or asset.Source.Status or "unknown"
        end

        return "unknown"
    end)

    if statusOk and statusResult then
        taskStatus = statusResult
    end

    return string.format(
            "[%d] id=%s name=%s source=%s role=%s missionType=%s enabled=%s taskStatus=%s radio=%s tacan=%s coord=%s",
            tonumber(index) or 0,
            self:SafeToString(asset.Id or "none"),
            self:SafeToString(name),
            self:SafeToString(sourceType),
            self:SafeToString(role),
            self:SafeToString(missionType),
            self:SafeToString(enabled),
            self:SafeToString(taskStatus),
            self:SafeToString(radio),
            self:SafeToString(tacan),
            self:SafeToString(coordinateText)
    )
end

function NASG_ATC:DumpWatchedAssetSourcesToLog()
    self:Log("========== NASG ATC WATCHED ASSET SOURCES ==========")

    local sources = self.WatchedAssetSources or {}

    if #sources == 0 then
        self:Log("No watched asset sources registered.")
        self:Log("====================================================")
        return
    end

    for index, watchedSource in ipairs(sources) do
        self:Log(
                string.format(
                        "[%d] name=%s type=%s coalition=%s source=%s",
                        index,
                        tostring(watchedSource.Name or "unnamed"),
                        tostring(watchedSource.SourceType or "unknown"),
                        tostring(watchedSource.Coalition or "unknown"),
                        tostring(watchedSource.Source or "nil")
                )
        )
    end

    self:Log("====================================================")
end

function NASG_ATC:DumpAssetRegistryToLog()
    self:Log("========== NASG ATC ASSET REGISTRY ==========")

    if self.RefreshWatchedAssets then
        local refreshOk, refreshErr = pcall(function()
            self:RefreshWatchedAssets()
        end)

        if not refreshOk then
            self:Log("RefreshWatchedAssets failed: " .. tostring(refreshErr))
        end
    end

    local assets = {}

    if self.GetAssets then
        local getOk, getResult = pcall(function()
            return self:GetAssets({})
        end)

        if getOk and getResult then
            assets = getResult
        else
            self:Log("GetAssets failed: " .. tostring(getResult))
        end
    else
        self:Log("GetAssets is not available")
    end

    local count = 0

    for _ in pairs(assets or {}) do
        count = count + 1
    end

    if count == 0 then
        self:Log("No ATC assets discovered.")
        self:Log("=============================================")
        return
    end

    local index = 0

    for _, asset in pairs(assets) do
        index = index + 1

        local lineOk, line = pcall(function()
            return self:GetAssetDebugLine(asset, index)
        end)

        if lineOk then
            self:Log(line)
        else
            self:Log("Failed to format ATC asset [" .. tostring(index) .. "]: " .. tostring(line))
        end
    end

    self:Log("Total ATC assets: " .. tostring(count))
    self:Log("=============================================")
end



function NASG_ATC:SafeDebugCall(name, callback)
    local ok, err = xpcall(callback, function(errorMessage)
        return tostring(errorMessage)
    end)

    if not ok then
        self:Log("ATC debug command failed: " .. tostring(name) .. " error=" .. tostring(err))
    end
end

function NASG_ATC:DumpAssetsToLog()
    local sourcesOk, sourcesErr = pcall(function()
        self:DumpWatchedAssetSourcesToLog()
    end)

    if not sourcesOk then
        self:Log("DumpWatchedAssetSourcesToLog failed: " .. tostring(sourcesErr))
    end

    local assetsOk, assetsErr = pcall(function()
        self:DumpAssetRegistryToLog()
    end)

    if not assetsOk then
        self:Log("DumpAssetRegistryToLog failed: " .. tostring(assetsErr))
    end
end

function NASG_ATC:GetMissionTypesForRole(role)
    role = tostring(role or ""):lower()

    if not AUFTRAG or not AUFTRAG.Type then
        return nil
    end

    if role == "tanker" then
        return { AUFTRAG.Type.TANKER }
    end

    if role == "awacs" then
        return { AUFTRAG.Type.AWACS }
    end

    if role == "orbit" then
        return { AUFTRAG.Type.ORBIT }
    end

    return nil
end

function NASG_ATC:IsMooseObjectLike(value)
    local valueType = type(value)

    return valueType == "table" or valueType == "userdata"
end

function NASG_ATC:GetGroupNameSafe(group)
    if not self:IsMooseObjectLike(group) then
        return nil
    end

    local name = nil

    pcall(function()
        if type(group.GetName) == "function" then
            name = group:GetName()
        end
    end)

    if name and name ~= "" then
        return name
    end

    pcall(function()
        if type(group.GetGroup) == "function" then
            local wrapperGroup = group:GetGroup()

            if wrapperGroup and type(wrapperGroup.GetName) == "function" then
                name = wrapperGroup:GetName()
            end
        end
    end)

    if name and name ~= "" then
        return name
    end

    return group.name or group.Name or group.GroupName or group.groupname
end

function NASG_ATC:GetGroupCoordinateSafe(group)
    if not self:IsMooseObjectLike(group) then
        return nil
    end

    local coordinate = nil

    pcall(function()
        if type(group.IsAlive) == "function" and not group:IsAlive() then
            return
        end

        if type(group.GetCoordinate) == "function" then
            coordinate = group:GetCoordinate()
        end
    end)

    if coordinate then
        return coordinate
    end

    pcall(function()
        if type(group.GetGroup) == "function" then
            local wrapperGroup = group:GetGroup()

            if wrapperGroup and type(wrapperGroup.IsAlive) == "function" and not wrapperGroup:IsAlive() then
                return
            end

            if wrapperGroup and type(wrapperGroup.GetCoordinate) == "function" then
                coordinate = wrapperGroup:GetCoordinate()
            end
        end
    end)

    if coordinate then
        return coordinate
    end

    pcall(function()
        if type(group.GetUnit) == "function" then
            local unit = group:GetUnit(1)

            if unit and type(unit.GetCoordinate) == "function" then
                coordinate = unit:GetCoordinate()
            end
        end
    end)

    return coordinate
end

function NASG_ATC:GetGroupTypeNameSafe(group)
    if not self:IsMooseObjectLike(group) then
        return nil
    end

    local typeName = nil

    pcall(function()
        if type(group.GetTypeName) == "function" then
            typeName = group:GetTypeName()
        end
    end)

    if typeName then
        return typeName
    end

    pcall(function()
        if type(group.GetGroup) == "function" then
            local wrapperGroup = group:GetGroup()

            if wrapperGroup and type(wrapperGroup.GetUnit) == "function" then
                local unit = wrapperGroup:GetUnit(1)

                if unit and type(unit.GetTypeName) == "function" then
                    typeName = unit:GetTypeName()
                end
            end
        end
    end)

    if typeName then
        return typeName
    end

    pcall(function()
        if type(group.GetUnit) == "function" then
            local unit = group:GetUnit(1)

            if unit and type(unit.GetTypeName) == "function" then
                typeName = unit:GetTypeName()
            end
        end
    end)

    return typeName
end

function NASG_ATC:IsMooseObjectLike(value)
    local valueType = type(value)

    return valueType == "table" or valueType == "userdata"
end

function NASG_ATC:IsMooseOpsGroupLike(value)
    if not self:IsMooseObjectLike(value) then
        return false
    end

    return type(value.GetCoordinate) == "function"
            or type(value.GetName) == "function"
            or type(value.GetGroup) == "function"
            or type(value.IsAlive) == "function"
end

function NASG_ATC:GetOpsGroupCandidate(key, value)
    if self:IsMooseOpsGroupLike(value) then
        return value
    end

    if self:IsMooseOpsGroupLike(key) then
        return key
    end

    return nil
end

function NASG_ATC:RefreshAirwingOpsGroupsForRole(watchedSource, role)
    if not watchedSource or not watchedSource.Source then
        return 0
    end

    local airwing = watchedSource.Source

    if type(airwing.GetOpsGroups) ~= "function" then
        return 0
    end

    local missionTypes = self:GetMissionTypesForRole(role)

    if not missionTypes then
        return 0
    end

    local opsGroupSet = nil
    local ok, err = pcall(function()
        opsGroupSet = airwing:GetOpsGroups(missionTypes, nil)
    end)

    if not ok then
        self:Log(
                string.format(
                        "AIRWING:GetOpsGroups failed source=%s role=%s error=%s",
                        tostring(watchedSource.Name or "unknown"),
                        tostring(role),
                        tostring(err)
                )
        )
        return 0
    end

    if not opsGroupSet or type(opsGroupSet.ForEachGroup) ~= "function" then
        self:Log(
                string.format(
                        "AIRWING:GetOpsGroups did not return SET_OPSGROUP source=%s role=%s resultType=%s",
                        tostring(watchedSource.Name or "unknown"),
                        tostring(role),
                        tostring(type(opsGroupSet))
                )
        )
        return 0
    end

    local count = 0
    local skippedGroups = 0
    local skippedUnits = 0

    local eachOk, eachErr = pcall(function()
        opsGroupSet:ForEachGroup(function(opsGroup)
            local mooseGroup = nil

            pcall(function()
                if type(opsGroup.GetGroup) == "function" then
                    mooseGroup = opsGroup:GetGroup()
                end
            end)

            if not mooseGroup then
                skippedGroups = skippedGroups + 1
                return
            end

            local groupName = NASG_ATC:GetGroupNameSafe(mooseGroup)
            local units = {}

            pcall(function()
                if type(mooseGroup.GetUnits) == "function" then
                    units = mooseGroup:GetUnits() or {}
                end
            end)

            for _, unit in pairs(units or {}) do
                local unitName = nil
                local typeName = nil
                local coordinate = nil

                pcall(function()
                    if type(unit.GetName) == "function" then
                        unitName = unit:GetName()
                    end
                end)

                pcall(function()
                    if type(unit.GetTypeName) == "function" then
                        typeName = unit:GetTypeName()
                    end
                end)

                pcall(function()
                    if type(unit.IsAlive) == "function" and not unit:IsAlive() then
                        return
                    end

                    if type(unit.GetCoordinate) == "function" then
                        coordinate = unit:GetCoordinate()
                    end
                end)

                if unitName and coordinate then
                    count = count + 1

                    NASG_ATC:UpsertAsset({
                        Id = string.format(
                                "airwing_%s_%s_%s",
                                tostring(watchedSource.Name or "airwing"),
                                tostring(role),
                                tostring(unitName)
                        ),
                        SourceType = "AIRWING_UNIT",
                        Source = unit,
                        Airwing = airwing,
                        OpsGroup = opsGroup,
                        Group = mooseGroup,
                        Unit = unit,
                        UnitName = unitName,
                        GroupName = groupName,
                        Name = unitName,
                        TypeName = typeName,
                        Role = role,
                        MissionType = missionTypes[1],
                        Coalition = watchedSource.Coalition or NASG_ATC.Defaults.Coalition,
                        Coordinate = coordinate,
                        Enabled = true,
                    })
                else
                    skippedUnits = skippedUnits + 1
                end
            end
        end)
    end)

    if not eachOk then
        self:Log(
                string.format(
                        "SET_OPSGROUP:ForEachGroup failed source=%s role=%s error=%s",
                        tostring(watchedSource.Name or "unknown"),
                        tostring(role),
                        tostring(eachErr)
                )
        )
        return count
    end

    self:Log(
            string.format(
                    "Refreshed AIRWING units source=%s role=%s units=%d skippedGroups=%d skippedUnits=%d",
                    tostring(watchedSource.Name or "unknown"),
                    tostring(role),
                    tonumber(count) or 0,
                    tonumber(skippedGroups) or 0,
                    tonumber(skippedUnits) or 0
            )
    )

    return count
end

function NASG_ATC:GetMooseUnitNameSafe(unit)
    if not self:IsMooseObjectLike(unit) then
        return nil
    end

    local name = nil

    pcall(function()
        if type(unit.GetName) == "function" then
            name = unit:GetName()
        end
    end)

    return name or unit.name or unit.Name
end

function NASG_ATC:GetMooseUnitTypeNameSafe(unit)
    if not self:IsMooseObjectLike(unit) then
        return nil
    end

    local typeName = nil

    pcall(function()
        if type(unit.GetTypeName) == "function" then
            typeName = unit:GetTypeName()
        end
    end)

    return typeName or unit.TypeName or unit.typeName
end

function NASG_ATC:GetMooseUnitCoordinateSafe(unit)
    if not self:IsMooseObjectLike(unit) then
        return nil
    end

    local coordinate = nil

    pcall(function()
        if type(unit.IsAlive) == "function" and not unit:IsAlive() then
            return
        end

        if type(unit.GetCoordinate) == "function" then
            coordinate = unit:GetCoordinate()
        end
    end)

    return coordinate
end

function NASG_ATC:GetMooseUnitPositionSafe(unit)
    if not self:IsMooseObjectLike(unit) then
        return nil
    end

    local position = nil

    pcall(function()
        if type(unit.IsAlive) == "function" and not unit:IsAlive() then
            return
        end

        if type(unit.GetPosition) == "function" then
            position = unit:GetPosition()
        end
    end)

    return position
end

function NASG_ATC:GetMooseGroupUnitsSafe(group)
    if not self:IsMooseObjectLike(group) then
        return {}
    end

    local units = {}

    pcall(function()
        if type(group.GetUnits) == "function" then
            units = group:GetUnits() or {}
        end
    end)

    return units or {}
end

function NASG_ATC:GetMooseGroupFromOpsGroupSafe(opsGroup)
    if not self:IsMooseObjectLike(opsGroup) then
        return nil
    end

    local group = nil

    pcall(function()
        if type(opsGroup.GetGroup) == "function" then
            group = opsGroup:GetGroup()
        end
    end)

    return group
end

function NASG_ATC:Start()
    self:Log("Starting NASG ATC version " .. tostring(self.Version))

    if self.InstallMooseChiefHooks then
        self:InstallMooseChiefHooks()
    end

    if self.InstallDebugMenu then
        self:InstallDebugMenu()
    end

    if self.Scanner then
        pcall(function()
            self.Scanner:Stop()
        end)

        self.Scanner = nil
    end

    self:StartEventHandler()

    self.Scanner = SCHEDULER:New(nil, function()
        if NASG_ATC.RefreshWatchedAssets then
            NASG_ATC:RefreshWatchedAssets()
        end

        for _, airport in pairs(NASG_ATC.Airports or {}) do
            NASG_ATC:ScanClientsForAirport(airport)
        end
    end, {}, 5, self.Defaults.ClientScanIntervalSeconds)
end

function NASG_ATC:Stop()
    if self.Scanner then
        pcall(function()
            self.Scanner:Stop()
        end)

        self.Scanner = nil
    end

    self:StopEventHandler()
    self:Log("Stopped")
end

NASG_ATC.CoreLoaded = true
NASG_ATC:Log("NASG_ATC_Core loaded")