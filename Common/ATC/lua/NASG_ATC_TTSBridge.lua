NASG_ATC = NASG_ATC or {}

NASG_ATC.TTSConfigFile = NASG_ATC.TTSConfigFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_tts_config.json"

NASG_ATC.TTSServiceBatchFile = NASG_ATC.TTSServiceBatchFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/scripts/start_tts_service.bat"

NASG_ATC.TTSServiceStopFile = NASG_ATC.TTSServiceStopFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_tts_service.stop"

-- Service launch is handled by NASG_ATC_Hook.lua (DCS hook); keep auto-start disabled.
NASG_ATC.TTSServiceAutoStart = NASG_ATC.TTSServiceAutoStart
if NASG_ATC.TTSServiceAutoStart == nil then
    NASG_ATC.TTSServiceAutoStart = false
end

NASG_ATC.TTSServiceStartRequested = false
NASG_ATC.TTSServiceMissionEndHandler = NASG_ATC.TTSServiceMissionEndHandler or nil


function NASG_ATC:BuildTTSFacilityJson(airport, facility, config)
    if not airport or not facility or not config then
        return nil
    end

    return string.format(
            [["%s_%s":{"airport_id":"%s","facility":"%s","callsign":"%s","voice":"%s","rate":%d,"pitch":%d,"volume":%.2f}]],
            self:JsonEscape(airport.Id),
            self:JsonEscape(facility),
            self:JsonEscape(airport.Id),
            self:JsonEscape(facility),
            self:JsonEscape(config.Callsign or facility),
            self:JsonEscape(config.Voice or self.Defaults.TTSVoice),
            tonumber(config.Speed or self.Defaults.TTSRate) or self.Defaults.TTSRate,
            tonumber(config.Pitch or 0) or 0,
            tonumber(config.Volume or self.Defaults.TTSVolume) or self.Defaults.TTSVolume
    )
end

function NASG_ATC:BuildTTSConfigJson()
    local facilities = {}

    for _, airport in pairs(self.Airports or {}) do
        local ground = self:BuildTTSFacilityJson(airport, self.Facilities.GROUND, airport.Ground)
        local tower = self:BuildTTSFacilityJson(airport, self.Facilities.TOWER, airport.Tower)
        local center = self:BuildTTSFacilityJson(airport, self.Facilities.CENTER, airport.Center)
        local awacs = self:BuildTTSFacilityJson(airport, self.Facilities.AWACS, airport.AWACS)
        local atis = self:BuildTTSFacilityJson(airport, self.Facilities.ATIS, airport.ATIS)

        if ground then facilities[#facilities + 1] = ground end
        if tower then facilities[#facilities + 1] = tower end
        if center then facilities[#facilities + 1] = center end
        if awacs then facilities[#facilities + 1] = awacs end
        if atis then facilities[#facilities + 1] = atis end
    end

    return string.format(
            [[{"version":1,"default_voice":"%s","default_rate":%d,"default_pitch":0,"default_volume":%.2f,"facilities":{%s}}]],
            self:JsonEscape(self.Defaults.TTSVoice),
            tonumber(self.Defaults.TTSRate) or 200,
            tonumber(self.Defaults.TTSVolume) or 1.0,
            table.concat(facilities, ",")
    )
end

function NASG_ATC:WriteTTSConfig()
    if not self.TTSConfigFile or self.TTSConfigFile == "" then
        return
    end

    local file = io.open(self.TTSConfigFile, "w")

    if not file then
        self:Log("Unable to write TTS config: " .. tostring(self.TTSConfigFile))
        return
    end

    file:write(self:BuildTTSConfigJson())
    file:close()

    self:Log("Wrote TTS config: " .. tostring(self.TTSConfigFile))
end

function NASG_ATC:NormalizeWindowsPath(path)
    return tostring(path or ""):gsub("/", "\\")
end

function NASG_ATC:StartTTSServiceProcess()
    self:Log("StartTTSServiceProcess called")

    if self.TTSServiceStartRequested then
        self:Log("TTS service start already requested")
        return
    end

    if not self.TTSServiceAutoStart then
        self:Log("TTS service auto-start disabled")
        return
    end

    if not os or not os.execute then
        self:Log("Cannot start TTS service: os.execute unavailable")
        return
    end

    self.TTSServiceStartRequested = true

    local batchPath = self:NormalizeWindowsPath(self.TTSServiceBatchFile)

    local command = string.format(
            'cmd.exe /c start "NASG ATC TTS Service" /min "%s"',
            batchPath
    )

    self:Log("Starting TTS service process")
    self:Log("TTS service batch file: " .. tostring(batchPath))
    self:Log("TTS service command: " .. tostring(command))

    local ok, result1, result2, result3 = pcall(function()
        return os.execute(command)
    end)

    self:Log(
            string.format(
                    "TTS service os.execute result ok=%s r1=%s r2=%s r3=%s",
                    tostring(ok),
                    tostring(result1),
                    tostring(result2),
                    tostring(result3)
            )
    )

    if ok then
        self:Log("TTS service start command issued")
    else
        self.TTSServiceStartRequested = false
        self:Log("Failed to start TTS service: " .. tostring(result1))
    end
end

function NASG_ATC:CreateTTSServiceStopFile()
    if not self.TTSServiceStopFile or self.TTSServiceStopFile == "" then
        return
    end

    local file = io.open(self.TTSServiceStopFile, "w")

    if file then
        file:write("stop")
        file:close()
        self:Log("Created TTS service stop file: " .. tostring(self.TTSServiceStopFile))
    else
        self:Log("Unable to create TTS service stop file: " .. tostring(self.TTSServiceStopFile))
    end
end

function NASG_ATC:StopTTSServiceProcess()
    self.TTSServiceStartRequested = false
    self:CreateTTSServiceStopFile()
end

function NASG_ATC:StartTTSServiceMissionEndHandler()
    if self.TTSServiceMissionEndHandler then
        self:Log("TTS service mission.json-end handler already started")
        return
    end

    if not EVENTHANDLER or not EVENTS or not EVENTS.MissionEnd then
        self:Log("Cannot start TTS service mission.json-end handler: EVENTHANDLER or EVENTS.MissionEnd unavailable")
        return
    end

    self.TTSServiceMissionEndHandler = EVENTHANDLER:New()
    self.TTSServiceMissionEndHandler:HandleEvent(EVENTS.MissionEnd)

    function self.TTSServiceMissionEndHandler:OnEventMissionEnd(eventData)
        NASG_ATC:Log("MissionEnd detected; stopping TTS service")
        NASG_ATC:StopTTSServiceProcess()
    end

    self:Log("Started TTS service mission.json-end handler")
end

function NASG_ATC:StopTTSServiceMissionEndHandler()
    if not self.TTSServiceMissionEndHandler then
        return
    end

    pcall(function()
        self.TTSServiceMissionEndHandler:UnHandleEvent(EVENTS.MissionEnd)
    end)

    self.TTSServiceMissionEndHandler = nil
    self:Log("Stopped TTS service mission.json-end handler")
end

NASG_ATC.OriginalStartForTTSBridge = NASG_ATC.OriginalStartForTTSBridge or NASG_ATC.Start

function NASG_ATC:Start()
    self:OriginalStartForTTSBridge()
    self:WriteTTSConfig()
    -- Service start/stop managed by NASG_ATC_Hook.lua; do not launch here.
end

NASG_ATC.OriginalStopForTTSBridge = NASG_ATC.OriginalStopForTTSBridge or NASG_ATC.Stop

function NASG_ATC:Stop()
    -- Service stop managed by NASG_ATC_Hook.lua; do not write stop file here.
    if self.OriginalStopForTTSBridge then
        self:OriginalStopForTTSBridge()
    end
end

NASG_ATC:Log("NASG_ATC_TTSBridge loaded")
NASG_ATC:WriteTTSConfig()