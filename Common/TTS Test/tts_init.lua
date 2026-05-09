NASG_TTS = NASG_TTS or {}

NASG_TTS.ServiceUrl = "http://127.0.0.1:" .. TTS_SERVICE_PORT .. "/tts"
NASG_TTS.InboxDir = SERVER_LOCATION .. "Logs\\tts_inbox\\main\\"

function NASG_TTS:Use(msrs, label, voice, speed, volume)
    if not msrs then
        return nil
    end

    msrs:SetBackendPythonWebSocket(self.ServiceUrl, self.InboxDir)

    if label then
        msrs:SetLabel(label)
    end

    if voice then
        msrs.voice = voice
    end

    if speed then
        msrs.speed = speed
    end

    if volume then
        msrs:SetVolume(volume)
    end

    return msrs
end