NASG_TTS = NASG_TTS or {}

NASG_TTS.ServiceUrl = "http://127.0.0.1:" .. TTS_SERVICE_PORT .. "/tts"
NASG_TTS.InboxDir = SERVER_LOCATION .. "Logs\\tts_inbox\\main\\"
NASG_TTS.DefaultCoalition = coalition.side.BLUE
NASG_TTS.DefaultVolume = (MSRS_Config and MSRS_Config.Volume) or 0.3
NASG_TTS.DefaultSpeed = (MSRS_Config and MSRS_Config.Speed) or 200

function NASG_TTS:Use(msrs, label, voice, speed, volume, coalitionSide)
    if not msrs then
        return nil
    end

    msrs:SetBackendPythonWebSocket(self.ServiceUrl, self.InboxDir)

    if msrs.SetCoalition then
        msrs:SetCoalition(coalitionSide or self.DefaultCoalition or coalition.side.BLUE)
    end

    if label then
        msrs:SetLabel(label)
        msrs.label = label
        msrs.Label = label
    end

    if voice then
        msrs.voice = voice
    end

    msrs.speed = speed or self.DefaultSpeed or 200

    if msrs.SetVolume then
        msrs:SetVolume(volume or self.DefaultVolume or 0.3)
    end

    return msrs
end