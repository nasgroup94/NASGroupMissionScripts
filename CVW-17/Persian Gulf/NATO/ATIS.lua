


-- Al Minhad ATIS on 125.1 AM
atisAlMinhad = ATIS:New(AIRBASE.PersianGulf.Al_Minhad_AFB, 125.1, radio.modulation.AM)
atisAlMinhad:SetRadioRelayUnitName("AMAFBRelay")
atisAlMinhad:SetSRS("", "female", "en-US")
atisAlMinhad.msrs:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
atisAlMinhad.msrs.voice = "Zoe"
atisAlMinhad.msrs.speed = 200
atisAlMinhad:SetQueueUpdateTime(100)
atisAlMinhad:__Start(20)

-- Abu Dhabi ATIS on another frequency, same Python service URL
atisAbuDhabi = ATIS:New(AIRBASE.PersianGulf.Abu_Dhabi_Intl, 126.2, radio.modulation.AM)
atisAbuDhabi:SetRadioRelayUnitName("AbuDhabiRelay")
atisAbuDhabi:SetSRS("", "male", "en-US")
atisAbuDhabi.msrs:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
atisAbuDhabi.msrs.voice = "Nathan"
atisAbuDhabi.msrs.speed = 200
atisAbuDhabi:SetQueueUpdateTime(100)
atisAbuDhabi:__Start(25)

--examples below

--NAS_TTS = {}
--
--NAS_TTS.BlueCommon = MSRS:New("", 250.1, radio.modulation.AM)
--NAS_TTS.BlueCommon:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
--NAS_TTS.BlueCommon:SetCoalition(coalition.side.BLUE)
--NAS_TTS.BlueCommon:SetLabel("Blue Common")
--NAS_TTS.BlueCommon:SetVolume(1.0)
--NAS_TTS.BlueCommon.voice = "Zoe"
--NAS_TTS.BlueCommon.speed = 200
--
--function NAS_TTS:Blue(text)
--    self.BlueCommon:PlayText(text, 0)
--end
--
--
--NAS_TTS:Blue("Package Saber one is cleared to push. Contact strike frequency two five zero decimal one.")
--
--
--
--local function SendBlueTTS(text, freq, modulation, voice, label)
--    local msrs = MSRS:New("", freq, modulation)
--    msrs:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
--    msrs:SetCoalition(coalition.side.BLUE)
--    msrs:SetLabel(label or ("TTS " .. tostring(freq)))
--    msrs:SetVolume(1.0)
--    msrs.voice = voice or "Zoe"
--    msrs.speed = 200
--
--    msrs:PlayText(text, 0)
--end
--
--SendBlueTTS(
--        "Magic, picture clean. No factor groups within one hundred miles.",
--        250.1,
--        radio.modulation.AM,
--        "Nathan",
--        "Magic"
--)
--
--
--local msrs = MSRS:New("", 250.1, radio.modulation.AM)
--msrs:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
--msrs:SetCoalition(coalition.side.BLUE)
--msrs:SetLabel("Mission TTS")
--msrs.voice = "Zoe"
--msrs.speed = 200
--
--msrs:PlayTextExt(
--        "Blue air tasking order update. Tanker Arco is available on two five one decimal zero.",
--        0,
--        {251.0},
--        {radio.modulation.AM},
--        "female",
--        "en-US",
--        "Zoe",
--        1.0,
--        "ATO Update",
--        nil
--)