--- **Sound** - MSRS Python inbox backend override.
--
-- Load this file after Moose.lua.
--
-- Adds:
--   MSRS.Backend.PYWS
--
-- Routes MSRS TTS and AIRBOSS .ogg radio transmissions through the local
-- NASGroupMissionScripts Python TTS/SRS inbox service.
--
-- Optional debug:
--   NASG_PYWS_DEBUG = true

NASG_PYWS_DEBUG = NASG_PYWS_DEBUG or false
NASG_AIRBOSS_BATCH_SECONDS = NASG_AIRBOSS_BATCH_SECONDS or 0.20
NASG_AIRBOSS_AUDIO_BATCHES = NASG_AIRBOSS_AUDIO_BATCHES or {}

local function NASG_PYWS_Log(Message)
    if NASG_PYWS_DEBUG and env and env.info then
        env.info("[MSRS_PythonWebSocket] " .. tostring(Message))
    end
end

local function NASG_AIRBOSS_Log(Message)
    if NASG_PYWS_DEBUG and env and env.info then
        env.info("[NASG_AIRBOSS] " .. tostring(Message))
    end
end

if not MSRS then
    env.info("[MSRS_PythonWebSocket] ERROR: MSRS is not loaded. Load Moose.lua before SRS_PythonWebSocket.lua.")
    return
end

MSRS.Backend = MSRS.Backend or {}
MSRS.Backend.PYWS = "pyws"

--- Escape a Lua value as a JSON string value.
function MSRS:_PythonWebSocketJsonString(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub('"', '\\"')
    value = value:gsub("\r", "\\r")
    value = value:gsub("\n", "\\n")
    value = value:gsub("\t", "\\t")
    return '"' .. value .. '"'
end

--- Convert a Lua value to a JSON field value.
function MSRS:_PythonWebSocketJsonValue(value)
    if value == nil then
        return "null"
    end

    if type(value) == "number" then
        return tostring(value)
    end

    if type(value) == "boolean" then
        return value and "true" or "false"
    end

    if type(value) == "table" then
        local isArray = true
        local maxIndex = 0

        for key, _ in pairs(value) do
            if type(key) ~= "number" then
                isArray = false
                break
            end

            if key > maxIndex then
                maxIndex = key
            end
        end

        if isArray then
            local items = {}

            for index = 1, maxIndex do
                table.insert(items, self:_PythonWebSocketJsonValue(value[index]))
            end

            return "[" .. table.concat(items, ",") .. "]"
        end

        local fields = {}

        for key, itemValue in pairs(value) do
            table.insert(
                    fields,
                    self:_PythonWebSocketJsonString(key) .. ":" .. self:_PythonWebSocketJsonValue(itemValue)
            )
        end

        return "{" .. table.concat(fields, ",") .. "}"
    end

    return self:_PythonWebSocketJsonString(value)
end

--- Write request JSON to the TTS inbox.
function MSRS:_PythonWebSocketPost(Payload)
    local inboxFolder = nil

    if self.pythonTTSInbox then
        inboxFolder = self.pythonTTSInbox
    elseif NASG_TTS and NASG_TTS.InboxDir then
        inboxFolder = NASG_TTS.InboxDir
    elseif lfs and lfs.writedir then
        inboxFolder = lfs.writedir() .. "Logs\\tts_inbox\\main\\"
    else
        inboxFolder = "C:\\Windows\\Temp\\tts_inbox\\main\\"
    end

    NASG_PYWS_Log("Inbox folder: " .. tostring(inboxFolder))

    if lfs and lfs.mkdir then
        lfs.mkdir(inboxFolder)
    end

    local uniqueName = "nas_tts_" .. tostring(timer.getTime()):gsub("%.", "_")
    local tempFilename = inboxFolder .. uniqueName .. ".tmp"
    local finalFilename = inboxFolder .. uniqueName .. ".json"

    local fields = {}

    for key, value in pairs(Payload or {}) do
        table.insert(fields, self:_PythonWebSocketJsonString(key) .. ":" .. self:_PythonWebSocketJsonValue(value))
    end

    local jsonPayload = "{" .. table.concat(fields, ",") .. "}"

    local file, err = io.open(tempFilename, "w")
    if not file then
        self:E("ERROR: Could not write TTS request file: " .. tostring(err))
        env.info("[MSRS_PythonWebSocket] ERROR: Could not write inbox request file: " .. tostring(err))
        return false
    end

    file:write(jsonPayload)
    file:close()

    os.rename(tempFilename, finalFilename)

    NASG_PYWS_Log("Inbox request written: " .. tostring(finalFilename))

    return true
end

function MSRS:SetPythonWebSocket(ServiceUrl, InboxDir)
    self:F({ ServiceUrl = ServiceUrl, InboxDir = InboxDir })

    if ServiceUrl and tostring(ServiceUrl):match("^https?://") then
        self.pythonTTSUrl = ServiceUrl
    else
        self.pythonTTSUrl = "http://127.0.0.1:8765/tts"
    end

    if InboxDir then
        self.pythonTTSInbox = InboxDir
    end

    return self
end

function MSRS:SetBackendPythonWebSocket(ServiceUrl, InboxDir)
    self:F({ ServiceUrl = ServiceUrl, InboxDir = InboxDir })

    self:SetBackend(MSRS.Backend.PYWS)
    self:SetPythonWebSocket(ServiceUrl, InboxDir)

    return self
end

function MSRS:SetPythonWebSocketSrsHost(SrsHost)
    self.srsHost = SrsHost
    self.srs_host = SrsHost
    return self
end

function MSRS:_PythonWebSocketSrsHost()
    return self.srsHost
            or self.srs_host
            or self.host
            or self.Host
            or MSRS.SrsHost
            or MSRS.srsHost
            or MSRS.srs_host
            or (MSRS_Config and (MSRS_Config.SrsHost or MSRS_Config.srs_host or MSRS_Config.SRSHost))
            or nil
end

function MSRS:_PythonWebSocketCoalition()
    if self.GetCoalition then
        local ok, value = pcall(function()
            return self:GetCoalition()
        end)

        if ok and value ~= nil then
            return value
        end
    end

    return self.coalition
            or self.Coalition
            or self.coal
            or self.Coal
            or (MSRS_Config and MSRS_Config.Coalition)
            or 0
end

function MSRS:_PythonWebSocketPort()
    return self.port
            or self.Port
            or (MSRS_Config and MSRS_Config.Port)
            or 5002
end

function MSRS:_PythonWebSocketVolume()
    return self.volume
            or self.Volume
            or (MSRS_Config and MSRS_Config.Volume)
            or nil
end

function MSRS.SetDefaultBackendPythonWebSocket()
    MSRS.backend = MSRS.Backend.PYWS
end

function MSRS:_PythonWebSocketModulations(Modulations)
    local modus = table.concat(Modulations or self:GetModulations(), ",")

    modus = modus:gsub("0", "AM")
    modus = modus:gsub("1", "FM")

    return modus
end

function MSRS:_PythonWebSocketSoundFilePath(SoundFile)
    if type(SoundFile) == "string" then
        return SoundFile
    end

    if type(SoundFile) ~= "table" then
        return nil
    end

    local filename =
    SoundFile.filename
            or SoundFile.FileName
            or SoundFile.name
            or SoundFile.Name
            or SoundFile.soundfile
            or SoundFile.SoundFile
            or SoundFile.file
            or SoundFile.File

    local folder =
    SoundFile.folder
            or SoundFile.Folder
            or SoundFile.path
            or SoundFile.Path
            or SoundFile.soundpath
            or SoundFile.SoundPath

    if folder and filename then
        return tostring(folder) .. tostring(filename)
    end

    if filename then
        return tostring(filename)
    end

    return nil
end

function MSRS:_PythonWebSocketTTS(Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate, Speed)
    self:F({ Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate, Speed })

    Frequencies = UTILS.EnsureTable(Frequencies, true) or self:GetFrequencies()
    Modulations = UTILS.EnsureTable(Modulations, true) or self:GetModulations()

    local freqs = table.concat(Frequencies, ",")
    local modus = self:_PythonWebSocketModulations(Modulations)
    local provider = self.provider or MSRS.Provider.WINDOWS
    local voice = Voice or self:GetVoice(provider) or self.voice
    local label = Label or self.Label or self.label or self.lid or "MSRS"

    local ok = self:_PythonWebSocketPost({
        text = Text or "",

        initiator = label,
        label = label,

        voice = voice,
        rate = Speed or self.speed,
        pitch = nil,

        srs_host = self:_PythonWebSocketSrsHost(),

        freqs = freqs,
        modulations = modus,
        coalition = self:_PythonWebSocketCoalition(),
        port = self:_PythonWebSocketPort(),
        gender = Gender or self.gender,
        volume = Volume or self:_PythonWebSocketVolume(),
    })

    if not ok then
        self:E("ERROR: MSRS Python TTS inbox request failed.")
        return nil
    end

    NASG_PYWS_Log("TTS request queued. label=" .. tostring(label) .. " freqs=" .. tostring(freqs))

    return true
end

function MSRS:_PythonWebSocketAudioFile(FilePath, Frequencies, Modulations, Volume, Label)
    Frequencies = UTILS.EnsureTable(Frequencies, true) or self:GetFrequencies()
    Modulations = UTILS.EnsureTable(Modulations, true) or self:GetModulations()

    local freqs = table.concat(Frequencies, ",")
    local modus = self:_PythonWebSocketModulations(Modulations)
    local label = Label or self.Label or self.label or self.lid or "MSRS"

    local ok = self:_PythonWebSocketPost({
        file = FilePath,

        initiator = label,
        label = label,

        srs_host = self:_PythonWebSocketSrsHost(),

        freqs = freqs,
        modulations = modus,
        coalition = self:_PythonWebSocketCoalition(),
        port = self:_PythonWebSocketPort(),
        volume = Volume or self:_PythonWebSocketVolume(),
    })

    if not ok then
        self:E("ERROR: MSRS Python audio file inbox request failed.")
        return nil
    end

    NASG_PYWS_Log("Audio file request queued: " .. tostring(FilePath))

    return true
end

local _MSRS_SetBackend = MSRS.SetBackend

function MSRS:SetBackend(Backend)
    self:F({ Backend = Backend })

    Backend = Backend or MSRS.Backend.SRSEXE

    if Backend == MSRS.Backend.PYWS then
        self.backend = Backend
        return self
    end

    return _MSRS_SetBackend(self, Backend)
end

local _MSRS_PlaySoundText = MSRS.PlaySoundText

function MSRS:PlaySoundText(SoundText, Delay)
    self:F({ SoundText, Delay })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlaySoundText(self, SoundText, Delay)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlaySoundText, self, SoundText, 0)
        return self
    end

    self:_PythonWebSocketTTS(
            SoundText.text,
            nil,
            nil,
            SoundText.gender,
            SoundText.culture,
            SoundText.voice,
            SoundText.volume,
            SoundText.label,
            SoundText.coordinate,
            SoundText.speed
    )

    return self
end

local _MSRS_PlayText = MSRS.PlayText

function MSRS:PlayText(Text, Delay, Coordinate)
    self:F({ Text, Delay, Coordinate })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlayText(self, Text, Delay, Coordinate)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, nil, Coordinate)
        return self
    end

    self:_PythonWebSocketTTS(Text, nil, nil, nil, nil, nil, nil, nil, Coordinate)

    return self
end

local _MSRS_PlayTextExt = MSRS.PlayTextExt

function MSRS:PlayTextExt(Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    self:T({ Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlayTextExt(self, Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
        return self
    end

    Frequencies = Frequencies or self:GetFrequencies()
    Modulations = Modulations or self:GetModulations()

    self:_PythonWebSocketTTS(Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)

    return self
end

local _MSRS_PlaySoundFile = MSRS.PlaySoundFile

function MSRS:PlaySoundFile(SoundFile, Delay)
    self:F({ SoundFile, Delay })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlaySoundFile(self, SoundFile, Delay)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlaySoundFile, self, SoundFile, 0)
        return self
    end

    local filePath = self:_PythonWebSocketSoundFilePath(SoundFile)

    if not filePath then
        self:E("ERROR: Could not resolve SOUNDFILE path for Python audio playback.")
        env.info("[MSRS_PythonWebSocket] ERROR: Could not resolve SOUNDFILE path.")
        return self
    end

    self:_PythonWebSocketAudioFile(filePath, nil, nil, nil, nil)

    return self
end

local function NASG_AIRBOSS_GetRadioFrequency(radio)
    if type(radio) ~= "table" then
        return nil
    end

    return radio.frequency or radio.Frequency or radio.freq or radio.Freq
end

local function NASG_AIRBOSS_GetRadioModulation(radio)
    if type(radio) ~= "table" then
        return nil
    end

    return radio.modulation or radio.Modulation or radio.modu or radio.Modu or radio.mod or radio.Mod
end

local function NASG_AIRBOSS_GetRadioAlias(radio)
    if type(radio) ~= "table" then
        return nil
    end

    return radio.alias or radio.Alias or radio.name or radio.Name
end

local function NASG_AIRBOSS_GetCallFileName(call)
    if type(call) == "string" then
        return call
    end

    if type(call) ~= "table" then
        return nil
    end

    return call.filename
            or call.FileName
            or call.name
            or call.Name
            or call.soundfile
            or call.SoundFile
            or call.file
            or call.File
end

local function NASG_AIRBOSS_GetSoundFolder(airboss, radioAlias)
    if radioAlias == "LSO" then
        return airboss.AirbossLSOFolder
                or airboss.LSOFolder
                or airboss.lsofolder
                or airboss.soundfilesFolder
                or airboss.SoundfilesFolder
                or airboss.SoundFilesFolder
                or airboss.soundfolder
                or airboss.SoundFolder
    end

    if radioAlias == "Marshal" or radioAlias == "MARSHAL" then
        return airboss.AirbossMarshalFolder
                or airboss.MarshalFolder
                or airboss.marshalfolder
                or airboss.soundfilesFolder
                or airboss.SoundfilesFolder
                or airboss.SoundFilesFolder
                or airboss.soundfolder
                or airboss.SoundFolder
    end

    return airboss.soundfilesFolder
            or airboss.SoundfilesFolder
            or airboss.SoundFilesFolder
            or airboss.soundfolder
            or airboss.SoundFolder
end

local function NASG_AIRBOSS_EnsureOggExtension(filename)
    if not filename then
        return nil
    end

    local text = tostring(filename)

    if text:lower():match("%.ogg$") or text:lower():match("%.wav$") or text:lower():match("%.mp3$") then
        return text
    end

    return text .. ".ogg"
end

local function NASG_AIRBOSS_PathJoin(folder, filename)
    if not filename then
        return nil
    end

    local filenameText = NASG_AIRBOSS_EnsureOggExtension(filename)

    if tostring(filenameText):match("^%a:[/\\]") or tostring(filenameText):match("^/") then
        return tostring(filenameText)
    end

    if not folder then
        return tostring(filenameText)
    end

    local folderText = tostring(folder)

    if folderText:sub(-1) == "/" or folderText:sub(-1) == "\\" then
        return folderText .. tostring(filenameText)
    end

    return folderText .. "/" .. tostring(filenameText)
end

local function NASG_AIRBOSS_BatchKey(radioAlias, frequency, modulation, coalitionValue, portValue)
    return tostring(radioAlias or "AIRBOSS")
            .. "|freq=" .. tostring(frequency)
            .. "|mod=" .. tostring(modulation)
            .. "|coalition=" .. tostring(coalitionValue)
            .. "|port=" .. tostring(portValue)
end

local function NASG_AIRBOSS_FlushBatch(batchKey)
    local batch = NASG_AIRBOSS_AUDIO_BATCHES[batchKey]

    if not batch then
        return
    end

    NASG_AIRBOSS_AUDIO_BATCHES[batchKey] = nil

    if not batch.files or #batch.files == 0 then
        return
    end

    NASG_AIRBOSS_Log("Flushing combined audio batch key=" .. tostring(batchKey) .. " files=" .. tostring(#batch.files))

    local msrs = MSRS:New(SRS_PATH or MSRS.path or "", batch.frequency, batch.modulation, MSRS.Backend.PYWS)

    if NASG_TTS and NASG_TTS.Use then
        NASG_TTS:Use(msrs, batch.label, nil)
    else
        msrs:SetBackend(MSRS.Backend.PYWS)
    end

    msrs:_PythonWebSocketPost({
        files = batch.files,

        initiator = batch.label,
        label = batch.label,

        srs_host = msrs:_PythonWebSocketSrsHost(),

        freqs = tostring(batch.frequency),
        modulations = msrs:_PythonWebSocketModulations({ batch.modulation }),
        coalition = batch.coalition,
        port = batch.port,
        volume = batch.volume,
    })
end

local function NASG_AIRBOSS_QueueBatchFile(radioAlias, frequency, modulation, coalitionValue, portValue, volumeValue, filePath)
    local batchKey = NASG_AIRBOSS_BatchKey(radioAlias, frequency, modulation, coalitionValue, portValue)
    local batch = NASG_AIRBOSS_AUDIO_BATCHES[batchKey]

    if not batch then
        batch = {
            files = {},
            radioAlias = radioAlias,
            frequency = frequency,
            modulation = modulation,
            coalition = coalitionValue,
            port = portValue,
            volume = volumeValue,
            label = "AIRBOSS " .. tostring(radioAlias or "Radio"),
        }

        NASG_AIRBOSS_AUDIO_BATCHES[batchKey] = batch

        TIMER:New(function()
            NASG_AIRBOSS_FlushBatch(batchKey)
        end):Start(NASG_AIRBOSS_BATCH_SECONDS)
    end

    table.insert(batch.files, filePath)

    NASG_AIRBOSS_Log("Added file to batch key=" .. tostring(batchKey) .. " count=" .. tostring(#batch.files) .. " file=" .. tostring(filePath))
end

if AIRBOSS and AIRBOSS.RadioTransmission and not AIRBOSS._NASGOriginalRadioTransmission then
    AIRBOSS._NASGOriginalRadioTransmission = AIRBOSS.RadioTransmission

    function AIRBOSS:RadioTransmission(radio, call, loud, delay, interval, click, pilotcall)
        local radioAlias = NASG_AIRBOSS_GetRadioAlias(radio)
        local frequency = NASG_AIRBOSS_GetRadioFrequency(radio)
        local modulation = NASG_AIRBOSS_GetRadioModulation(radio)
        local filename = NASG_AIRBOSS_GetCallFileName(call)
        local folder = NASG_AIRBOSS_GetSoundFolder(self, radioAlias)
        local filePath = NASG_AIRBOSS_PathJoin(folder, filename)

        if filePath and frequency and modulation then
            local coalitionValue = self.coalition
                    or self.Coalition
                    or (MSRS_Config and MSRS_Config.Coalition)
                    or (coalition and coalition.side and coalition.side.BLUE)
                    or 2

            local portValue = self.port
                    or self.Port
                    or (MSRS_Config and MSRS_Config.Port)
                    or 5002

            local volumeValue = self.volume
                    or self.Volume
                    or (MSRS_Config and MSRS_Config.Volume)
                    or 0.3

            NASG_AIRBOSS_Log(
                    "RadioTransmission batched alias=" .. tostring(radioAlias)
                            .. " freq=" .. tostring(frequency)
                            .. " modulation=" .. tostring(modulation)
                            .. " file=" .. tostring(filePath)
            )

            NASG_AIRBOSS_QueueBatchFile(
                    radioAlias,
                    frequency,
                    modulation,
                    coalitionValue,
                    portValue,
                    volumeValue,
                    filePath
            )

            return self
        end

        return AIRBOSS._NASGOriginalRadioTransmission(self, radio, call, loud, delay, interval, click, pilotcall)
    end

    env.info("[NASG_AIRBOSS] AIRBOSS RadioTransmission override installed.")
elseif AIRBOSS and AIRBOSS._NASGOriginalRadioTransmission then
    NASG_AIRBOSS_Log("AIRBOSS RadioTransmission override already installed.")
else
    env.info("[NASG_AIRBOSS] AIRBOSS RadioTransmission override NOT installed. AIRBOSS not available yet.")
end

env.info("[MSRS_PythonWebSocket] Loaded MSRS Python inbox backend override.")