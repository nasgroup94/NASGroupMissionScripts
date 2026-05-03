--- **Sound** - MSRS Python WebSocket backend override.
--
-- Load this file after Sound/SRS.lua.
--
-- This adds a third MSRS backend:
--
--   MSRS.Backend.PYWS
--
-- It routes MSRS text-to-speech calls through the local NASGroupMissionScripts
-- Python TTS HTTP service.
--
-- This version intentionally does not use LuaSocket, because DCS often cannot
-- load socket.core.dll reliably.

if not MSRS then
    env.info("[MSRS_PythonWebSocket] ERROR: MSRS is not loaded. Load SRS.lua before SRS_PythonWebSocket.lua.")
    return
end

--- Escape a Lua value as a JSON string value.
-- @param #string value Value to escape.
-- @return #string Escaped JSON string.
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
-- @param value Value.
-- @return #string JSON value.
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

    return self:_PythonWebSocketJsonString(value)
end

--- Write request JSON to a temp file and POST it to the TTS service with curl.exe.
-- @param #table Payload Payload table.
-- @return #boolean Success.
function MSRS:_PythonWebSocketPost(Payload)
    local tempFolder = nil

    if lfs and lfs.writedir then
        tempFolder = lfs.writedir() .. "Logs\\"
    else
        tempFolder = "C:\\Windows\\Temp\\"
    end

    local filename = tempFolder .. "nas_tts_" .. tostring(timer.getTime()):gsub("%.", "_") .. ".json"

    local fields = {}

    for key, value in pairs(Payload or {}) do
        table.insert(fields, self:_PythonWebSocketJsonString(key) .. ":" .. self:_PythonWebSocketJsonValue(value))
    end

    local jsonPayload = "{" .. table.concat(fields, ",") .. "}"

    local file, err = io.open(filename, "w")
    if not file then
        self:E("ERROR: Could not write TTS request file: " .. tostring(err))
        return false
    end

    file:write(jsonPayload)
    file:close()

    local command = string.format(
            'cmd.exe /C curl.exe -s -X POST -H "Content-Type: application/json" --data-binary "@%s" "%s" >NUL 2>NUL & del "%s" >NUL 2>NUL',
            filename,
            self.pythonTTSUrl or "http://127.0.0.1:8765/tts",
            filename
    )

    self:T("MSRS Python TTS HTTP command=" .. command)

    local result = self:_ExecCommand(command)

    return result ~= nil
end

MSRS.Backend = MSRS.Backend or {}
MSRS.Backend.PYWS = "pyws"

--- Set NASGroupMissionScripts Python TTS HTTP service details.
-- Kept under the old name for compatibility with existing mission scripts.
-- @param #MSRS self
-- @param #string ServiceUrl Optional HTTP service URL. Defaults to http://127.0.0.1:8765/tts.
-- @param #string PythonExe Ignored. Kept for backwards compatibility.
-- @return #MSRS self
function MSRS:SetPythonWebSocket(ServiceUrl, PythonExe)
    self:F({ ServiceUrl = ServiceUrl, PythonExe = PythonExe })

    if ServiceUrl and tostring(ServiceUrl):match("^https?://") then
        self.pythonTTSUrl = ServiceUrl
    else
        self.pythonTTSUrl = "http://127.0.0.1:8765/tts"
    end

    return self
end

--- Set NASGroupMissionScripts Python TTS HTTP service as backend.
-- Kept under the old name for compatibility with existing mission scripts.
-- @param #MSRS self
-- @param #string ServiceUrl Optional HTTP service URL. Defaults to http://127.0.0.1:8765/tts.
-- @param #string PythonExe Ignored. Kept for backwards compatibility.
-- @return #MSRS self
function MSRS:SetBackendPythonWebSocket(ServiceUrl, PythonExe)
    self:F({ ServiceUrl = ServiceUrl, PythonExe = PythonExe })

    self:SetBackend(MSRS.Backend.PYWS)
    self:SetPythonWebSocket(ServiceUrl, PythonExe)

    return self
end

--- Set Python TTS HTTP service as default backend for future MSRS instances.
function MSRS.SetDefaultBackendPythonWebSocket()
    MSRS.backend = MSRS.Backend.PYWS
end

--- Convert an MSRS modulation table into SRS-style strings.
-- @param #MSRS self
-- @param #table Modulations Modulations.
-- @return #string Modulations string.
function MSRS:_PythonWebSocketModulations(Modulations)
    local modus = table.concat(Modulations or self:GetModulations(), ",")

    modus = modus:gsub("0", "AM")
    modus = modus:gsub("1", "FM")

    return modus
end

--- Queue text-to-speech through NASGroupMissionScripts Python TTS HTTP service.
-- @param #MSRS self
-- @param #string Text Text of message to transmit.
-- @param #table Frequencies Radio frequencies to transmit on. Can also accept a number in MHz.
-- @param #table Modulations Radio modulations.
-- @param #string Gender Gender.
-- @param #string Culture Culture.
-- @param #string Voice Voice.
-- @param #number Volume Volume.
-- @param #string Label Label.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @param #number Speed Speech speed.
-- @return #string Job ID, or nil on failure.
function MSRS:_PythonWebSocketTTS(Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate, Speed)
    self:F({ Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate, Speed })

    if not self.pythonTTS then
        self:SetPythonWebSocket()
    end

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

        freqs = freqs,
        modulations = modus,
        coalition = self.coalition or 0,
        port = self.port or 5002,
        gender = Gender or self.gender,
        volume = Volume or self.volume,
    })

    if not ok then
        self:E("ERROR: MSRS Python TTS HTTP request failed.")
        return nil
    end

    self:T("MSRS Python TTS HTTP request queued.")
    return true
end

local _MSRS_SetBackend = MSRS.SetBackend

--- Override backend validation so PYWS is accepted.
-- @param #MSRS self
-- @param #string Backend Backend used.
-- @return #MSRS self
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

--- Override PlaySoundText to route PYWS backend to Python websocket.
-- @param #MSRS self
-- @param Sound.SoundOutput#SOUNDTEXT SoundText Sound text.
-- @param #number Delay Delay in seconds.
-- @return #MSRS self
function MSRS:PlaySoundText(SoundText, Delay)
    self:F({ SoundText, Delay })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlaySoundText(self, SoundText, Delay)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlaySoundText, self, SoundText, 0)
    else
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
    end

    return self
end

local _MSRS_PlayText = MSRS.PlayText

--- Override PlayText to route PYWS backend to Python websocket.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:PlayText(Text, Delay, Coordinate)
    self:F({ Text, Delay, Coordinate })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlayText(self, Text, Delay, Coordinate)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, nil, Coordinate)
    else
        self:T(self.lid .. "Transmitting via Python websocket")
        self:_PythonWebSocketTTS(Text, nil, nil, nil, nil, nil, nil, nil, Coordinate)
    end

    return self
end

local _MSRS_PlayTextExt = MSRS.PlayTextExt

--- Override PlayTextExt to route PYWS backend to Python websocket.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds.
-- @param #table Frequencies Radio frequencies.
-- @param #table Modulations Radio modulations.
-- @param #string Gender Gender.
-- @param #string Culture Culture.
-- @param #string Voice Voice.
-- @param #number Volume Volume.
-- @param #string Label Label.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:PlayTextExt(Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    self:T({ Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate })

    if self.backend ~= MSRS.Backend.PYWS then
        return _MSRS_PlayTextExt(self, Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    end

    if Delay and Delay > 0 then
        self:ScheduleOnce(Delay, MSRS.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    else
        Frequencies = Frequencies or self:GetFrequencies()
        Modulations = Modulations or self:GetModulations()

        self:_PythonWebSocketTTS(Text, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
    end

    return self
end

env.info("[MSRS_PythonWebSocket] Loaded MSRS Python TTS HTTP backend override.")