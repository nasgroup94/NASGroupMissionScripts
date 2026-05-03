--- **Sound** - MSRS Python WebSocket backend override.
--
-- Load this file after Sound/SRS.lua.
--
-- This adds a third MSRS backend:
--
--   MSRS.Backend.PYWS
--
-- It routes MSRS text-to-speech calls through the local NASGroupMissionScripts
-- Python TTS HTTP service instead of launching DCS-SR-ExternalAudio.exe directly.
--
-- Required mission load order:
--
--   1. Moose.lua / SRS.lua
--   2. TTSPython.lua must be available in package.path
--   3. SRS_PythonWebSocket.lua
--   4. Your mission code

local TTSPython = require("TTSPython")

if not MSRS then
    env.info("[MSRS_PythonWebSocket] ERROR: MSRS is not loaded. Load SRS.lua before SRS_PythonWebSocket.lua.")
    return
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

    self.pythonTTS = TTSPython:New({
        Url = self.pythonTTSUrl
    })

    return self
end

--- Set NASGroupMissionScripts Python TTS HTTP service as backend to communicate with SRS.
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

    local job_id, err = self.pythonTTS:Request(Text or "", {
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

    if not job_id then
        self:E("ERROR: MSRS Python TTS HTTP request failed: " .. tostring(err))
        return nil
    end

    self:T("MSRS Python TTS HTTP job queued: " .. tostring(job_id))
    return job_id
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