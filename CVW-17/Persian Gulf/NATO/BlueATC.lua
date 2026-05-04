

local FC_Al_Minhad = FLIGHTCONTROL:New(AIRBASE.PersianGulf.Al_Minhad_AFB, 250.1,nil,'')
FC_Al_Minhad.msrs:SetBackendPythonWebSocket("http://127.0.0.1:8765/tts")
FC_Al_Minhad:SetSpeedLimitTaxi(25)
FC_Al_Minhad:SetLimitLanding(2,99)

