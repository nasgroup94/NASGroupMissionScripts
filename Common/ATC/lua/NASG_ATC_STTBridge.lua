NASG_ATC = NASG_ATC or {}

NASG_ATC.SpeechEventFile = NASG_ATC.SpeechEventFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_atc_events.jsonl"

NASG_ATC.STTConfigFile = NASG_ATC.STTConfigFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_atc_stt_config.json"

NASG_ATC.STTBridgeStopFile = NASG_ATC.STTBridgeStopFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_stt_bridge.stop"

NASG_ATC.STTBridgeLockFile = NASG_ATC.STTBridgeLockFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_stt_bridge.lock"

NASG_ATC.STTBridgeLockStaleSeconds = NASG_ATC.STTBridgeLockStaleSeconds or 30

NASG_ATC.STTBridgeBatchFile = NASG_ATC.STTBridgeBatchFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/scripts/start_stt_bridge.bat"

NASG_ATC.STTBridgeAutoStart = NASG_ATC.STTBridgeAutoStart
if NASG_ATC.STTBridgeAutoStart == nil then
    NASG_ATC.STTBridgeAutoStart = true
end

NASG_ATC.STTBridgeStartRequested = false
NASG_ATC.STTBridgeStartedByLua = false
NASG_ATC.SpeechEventScheduler = NASG_ATC.SpeechEventScheduler or nil
NASG_ATC.STTBridgeMissionEndHandler = NASG_ATC.STTBridgeMissionEndHandler or nil

--function NASG_ATC:JsonEscape(value)
--    local text = tostring(value or "")
--
--    text = text:gsub("\\", "\\\\")
--    text = text:gsub("\"", "\\\"")
--    text = text:gsub("\n", "\\n")
--    text = text:gsub("\r", "\\r")
--    text = text:gsub("\t", "\\t")
--
--    return text
--end

function NASG_ATC:FileExists(path)
    if not path or path == "" then
        return false
    end

    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    return false
end

function NASG_ATC:ReadNumberFromFile(path)
    if not path or path == "" then
        return nil
    end

    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local text = file:read("*all")
    file:close()

    return tonumber(text)
end

function NASG_ATC:IsSTTBridgeLockStale()
    if not self:FileExists(self.STTBridgeLockFile) then
        return false
    end

    local lockTime = self:ReadNumberFromFile(self.STTBridgeLockFile)

    if not lockTime then
        self:Log("ATC STT bridge lock has no valid timestamp; treating as stale")
        return true
    end

    local age = timer.getAbsTime() - lockTime

    if age > self.STTBridgeLockStaleSeconds then
        self:Log(
                string.format(
                        "ATC STT bridge lock is stale age=%.1fs threshold=%.1fs",
                        age,
                        self.STTBridgeLockStaleSeconds
                )
        )
        return true
    end

    self:Log(
            string.format(
                    "ATC STT bridge lock exists and is not stale age=%.1fs threshold=%.1fs",
                    age,
                    self.STTBridgeLockStaleSeconds
            )
    )

    return false
end

function NASG_ATC:CreateLockFile()
    if not self.STTBridgeLockFile or self.STTBridgeLockFile == "" then
        return
    end

    local file = io.open(self.STTBridgeLockFile, "w")

    if file then
        file:write(tostring(timer.getAbsTime()))
        file:close()
        self:Log("Created ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    else
        self:Log("Unable to create ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    end
end

function NASG_ATC:RemoveLockFile()
    if self.STTBridgeLockFile and self:FileExists(self.STTBridgeLockFile) then
        os.remove(self.STTBridgeLockFile)
        self:Log("Removed ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    end
end

function NASG_ATC:FileExists(path)
    if not path or path == "" then
        return false
    end

    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    return false
end

function NASG_ATC:CreateLockFile()
    if not self.STTBridgeLockFile or self.STTBridgeLockFile == "" then
        return
    end

    local file = io.open(self.STTBridgeLockFile, "w")

    if file then
        file:write(tostring(timer.getAbsTime()))
        file:close()
        self:Log("Created ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    else
        self:Log("Unable to create ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    end
end

function NASG_ATC:RemoveLockFile()
    if self.STTBridgeLockFile and self:FileExists(self.STTBridgeLockFile) then
        os.remove(self.STTBridgeLockFile)
        self:Log("Removed ATC STT bridge lock file: " .. tostring(self.STTBridgeLockFile))
    end
end

function NASG_ATC:GetModulationName(modulation)
    if modulation == radio.modulation.FM then
        return "FM"
    end

    return "AM"
end

function NASG_ATC:AddSTTChannel(channels, airport, facility, config)
    if not airport or not facility or not config or not config.Frequency then
        return
    end

    channels[#channels + 1] = {
        id = tostring(airport.Id) .. "_" .. tostring(facility),
        airport_id = tostring(airport.Id),
        service = tostring(facility),
        facility = tostring(facility),
        client_name = string.format(
                "NASGroup %s Listener - %s",
                tostring(config.Callsign or facility),
                tostring(airport.Name or airport.Id)
        ),
        frequency = tonumber(config.Frequency) or 0,
        modulation = self:GetModulationName(config.Modulation),
        coalition = tonumber(airport.Coalition or self.Defaults.Coalition or coalition.side.BLUE) or coalition.side.BLUE,
    }
end

function NASG_ATC:BuildSTTBridgeConfigTable()
    local channels = {}

    for _, airport in pairs(self.Airports or {}) do
        self:AddSTTChannel(channels, airport, self.Facilities.GROUND, airport.Ground)
        self:AddSTTChannel(channels, airport, self.Facilities.TOWER, airport.Tower)
        self:AddSTTChannel(channels, airport, self.Facilities.CENTER, airport.Center)
        self:AddSTTChannel(channels, airport, self.Facilities.AWACS, airport.AWACS)
    end

    return {
        version = 3,
        srs_address = string.format("127.0.0.1:%d", tonumber(SRS_PORT or 5002) or 5002),
        event_file = tostring(self.SpeechEventFile),
        intent_patterns = self.IntentPatterns or {},
        channels = channels,
    }
end

function NASG_ATC:BuildSTTBridgeConfigJson()
    local config = self:BuildSTTBridgeConfigTable()

    if net and net.lua2json then
        local ok, encoded = pcall(function()
            return net.lua2json(config)
        end)

        if ok and encoded then
            return encoded
        end
    end

    self:Log("net.lua2json unavailable; falling back to minimal STT JSON without intent patterns")

    local channels = {}

    for _, channel in ipairs(config.channels or {}) do
        channels[#channels + 1] = string.format(
                [[{"id":"%s","airport_id":"%s","service":"%s","facility":"%s","client_name":"%s","frequency":%.3f,"modulation":"%s","coalition":%d}]],
                self:JsonEscape(channel.id),
                self:JsonEscape(channel.airport_id),
                self:JsonEscape(channel.service),
                self:JsonEscape(channel.facility),
                self:JsonEscape(channel.client_name),
                tonumber(channel.frequency) or 0,
                self:JsonEscape(channel.modulation),
                tonumber(channel.coalition) or coalition.side.BLUE
        )
    end

    return string.format(
            [[{"version":3,"srs_address":"%s","event_file":"%s","intent_patterns":{},"channels":[%s]}]],
            self:JsonEscape(config.srs_address),
            self:JsonEscape(config.event_file),
            table.concat(channels, ",")
    )
end

function NASG_ATC:WriteSTTBridgeConfig()
    if not self.STTConfigFile or self.STTConfigFile == "" then
        return
    end

    local file = io.open(self.STTConfigFile, "w")

    if not file then
        self:Log("Unable to write STT bridge config: " .. tostring(self.STTConfigFile))
        return
    end

    file:write(self:BuildSTTBridgeConfigJson())
    file:close()

    self:Log("Wrote STT bridge config: " .. tostring(self.STTConfigFile))
end

function NASG_ATC:DecodeSpeechEventJson(line)
    if not line or line == "" then
        return nil
    end

    if net and net.json2lua then
        local ok, result = pcall(function()
            return net.json2lua(line)
        end)

        if ok and result then
            return result
        end
    end

    if json and json.decode then
        local ok, result = pcall(function()
            return json.decode(line)
        end)

        if ok and result then
            return result
        end
    end

    self:Log("Could not decode speech event JSON.")
    return nil
end

function NASG_ATC:ReadSpeechEventLines()
    local filePath = self.SpeechEventFile

    if not filePath or filePath == "" then
        return {}
    end

    local file = io.open(filePath, "r")

    if not file then
        return {}
    end

    local lines = {}

    for line in file:lines() do
        if line and line ~= "" then
            lines[#lines + 1] = line
        end
    end

    file:close()

    local clearFile = io.open(filePath, "w")

    if clearFile then
        clearFile:write("")
        clearFile:close()
    end

    return lines
end

function NASG_ATC:PollSpeechEvents()
    local lines = self:ReadSpeechEventLines()

    for _, line in ipairs(lines) do
        local event = self:DecodeSpeechEventJson(line)

        if event then
            self:Log(
                    string.format(
                            "Received ATC speech event facility=%s airport=%s client=%s intent=%s text=%s",
                            tostring(event.facility or event.service),
                            tostring(event.airport_id),
                            tostring(event.client_name),
                            tostring(event.intent),
                            tostring(event.raw_text)
                    )
            )

            self:HandleSpeechEvent(event)
        end
    end
end

function NASG_ATC:StartSpeechEventPoller()
    if self.SpeechEventScheduler then
        return
    end

    self.SpeechEventScheduler = SCHEDULER:New(nil, function()
        NASG_ATC:PollSpeechEvents()
    end, {}, 1, 1)

    self:Log("Started ATC speech event poller")
end

function NASG_ATC:StopSpeechEventPoller()
    if self.SpeechEventScheduler then
        pcall(function()
            self.SpeechEventScheduler:Stop()
        end)

        self.SpeechEventScheduler = nil
    end

    self:Log("Stopped ATC speech event poller")
end

function NASG_ATC:DeleteFileIfExists(path)
    if not path or path == "" then
        return
    end

    local file = io.open(path, "r")

    if file then
        file:close()
        os.remove(path)
    end
end

function NASG_ATC:CreateStopFile()
    if not self.STTBridgeStopFile or self.STTBridgeStopFile == "" then
        return
    end

    local file = io.open(self.STTBridgeStopFile, "w")

    if file then
        file:write("stop")
        file:close()
        self:Log("Created STT bridge stop file")
    end
end

function NASG_ATC:StartSTTBridgeProcess()
    self:Log("StartSTTBridgeProcess called")

    if self.STTBridgeStartRequested then
        self:Log("ATC STT bridge start already requested")
        return
    end

    if self.STTBridgeLockFile and self:FileExists(self.STTBridgeLockFile) then
        if self:IsSTTBridgeLockStale() then
            self:Log("Removing stale ATC STT bridge lock file")
            self:RemoveLockFile()
        else
            self:Log("ATC STT bridge lock file exists; not starting another bridge: " .. tostring(self.STTBridgeLockFile))
            self.STTBridgeStartRequested = false
            return
        end
    end

    if not self.STTBridgeAutoStart then
        self:Log("ATC STT bridge auto-start disabled")
        return
    end

    if not os or not os.execute then
        self:Log("Cannot start ATC STT bridge: os.execute unavailable")
        return
    end

    self.STTBridgeStartRequested = true

    self:DeleteFileIfExists(self.STTBridgeStopFile)
    self:WriteSTTBridgeConfig()
    --self:CreateLockFile()

    local command = string.format(
            'cmd.exe /c start "NASG ATC STT Bridge" /min "%s"',
            tostring(self.STTBridgeBatchFile):gsub("/", "\\")
    )

    self:Log("Starting ATC STT bridge process")
    self:Log("ATC STT bridge batch file: " .. tostring(self.STTBridgeBatchFile))
    self:Log("ATC STT bridge command: " .. tostring(command))

    local ok, result1, result2, result3 = pcall(function()
        return os.execute(command)
    end)

    self:Log(
            string.format(
                    "ATC STT bridge os.execute result ok=%s r1=%s r2=%s r3=%s",
                    tostring(ok),
                    tostring(result1),
                    tostring(result2),
                    tostring(result3)
            )
    )

    if ok then
        self.STTBridgeStartedByLua = true
        self:Log("ATC STT bridge start command issued")
    else
        self.STTBridgeStartRequested = false
        self:RemoveLockFile()
        self:Log("Failed to start ATC STT bridge: " .. tostring(result1))
    end
end

function NASG_ATC:StopSTTBridgeProcess()
    self.STTBridgeStartRequested = false
    self:CreateStopFile()

    if self.RemoveLockFile then
        self:RemoveLockFile()
    end

    self.STTBridgeStartedByLua = false
end

function NASG_ATC:StartSTTBridgeMissionEndHandler()
    if self.STTBridgeMissionEndHandler then
        self:Log("ATC STT bridge mission.json-end handler already started")
        return
    end

    if not EVENTHANDLER or not EVENTS or not EVENTS.MissionEnd then
        self:Log("Cannot start ATC STT bridge mission.json-end handler: EVENTHANDLER or EVENTS.MissionEnd unavailable")
        return
    end

    self.STTBridgeMissionEndHandler = EVENTHANDLER:New()
    self.STTBridgeMissionEndHandler:HandleEvent(EVENTS.MissionEnd)

    function self.STTBridgeMissionEndHandler:OnEventMissionEnd(eventData)
        NASG_ATC:Log("MissionEnd detected; stopping ATC STT bridge")
        NASG_ATC:StopSTTBridgeProcess()
    end

    self:Log("Started ATC STT bridge mission.json-end handler")
end

function NASG_ATC:StopSTTBridgeMissionEndHandler()
    if not self.STTBridgeMissionEndHandler then
        return
    end

    pcall(function()
        self.STTBridgeMissionEndHandler:UnHandleEvent(EVENTS.MissionEnd)
    end)

    self.STTBridgeMissionEndHandler = nil
    self:Log("Stopped ATC STT bridge mission.json-end handler")
end

NASG_ATC.OriginalStartForSTTBridge = NASG_ATC.OriginalStartForSTTBridge or NASG_ATC.Start

if not NASG_ATC.STTBridgeStartWrapperInstalled then
    NASG_ATC.STTBridgeStartWrapperInstalled = true

    NASG_ATC.OriginalStartForSTTBridge = NASG_ATC.Start

    function NASG_ATC:Start()
        self:Log("NASG_ATC_STTBridge Start wrapper entered")

        if self.OriginalStartForSTTBridge then
            self:OriginalStartForSTTBridge()
        end

        self:Log("NASG_ATC_STTBridge writing config")
        self:WriteSTTBridgeConfig()

        self:Log("NASG_ATC_STTBridge starting speech poller")
        self:StartSpeechEventPoller()

        self:Log("NASG_ATC_STTBridge starting mission.json-end handler")
        self:StartSTTBridgeMissionEndHandler()

        self:Log("NASG_ATC_STTBridge starting STT bridge process")
        self:StartSTTBridgeProcess()
    end
end

if not NASG_ATC.STTBridgeStopWrapperInstalled then
    NASG_ATC.STTBridgeStopWrapperInstalled = true

    NASG_ATC.OriginalStopForSTTBridge = NASG_ATC.Stop

    function NASG_ATC:Stop()
        self:StopSpeechEventPoller()
        self:StopSTTBridgeMissionEndHandler()
        self:StopSTTBridgeProcess()

        if self.OriginalStopForSTTBridge then
            self:OriginalStopForSTTBridge()
        end
    end
end

NASG_ATC:Log("NASG_ATC_STTBridge loaded")

-- Do not call StartSTTBridgeProcess() here.
-- The script loader calls NASG_ATC:Start(), and this wrapper starts the bridge.