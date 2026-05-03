


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