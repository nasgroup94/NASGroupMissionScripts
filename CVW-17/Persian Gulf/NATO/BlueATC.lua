

FC_Al_Minhad = FLIGHTCONTROL:New(AIRBASE.PersianGulf.Al_Minhad_AFB, 250.1, radio.modulation.AM, "")
FC_Al_Minhad:SetSRSPilot("", "male", "en-US")
FC_Al_Minhad:SetSRSTower("", "female", "en-US")
NASG_TTS:Use(FC_Al_Minhad.msrsPilot, "Al Minhad Pilot", "Nathan", 200, 1.0)
NASG_TTS:Use(FC_Al_Minhad.msrsTower, "Al Minhad Tower", "Zoe",200, 1.0)
FC_Al_Minhad:SetParkingGuardStatic("ALParkGuard")

FC_Al_Minhad:SetSpeedLimitTaxi(25)
FC_Al_Minhad:SetLimitLanding(2, 99)
FC_Al_Minhad:Start()
