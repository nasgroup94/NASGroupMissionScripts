
VS21 = SQUADRON:New("VS-21", 6, "VS-21 Fighting Redtails")
    :AddMissionCapability({AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Tanker.Arco, 1)
    :SetFuelLowRefuel(true)
    :SetFuelLowThreshold(0.3)
    :SetTakeoffAir()

CVW7 = AIRWING:New("CVN73", "CVW-7 Airwing")
CVW7:AddSquadron(VS21)
CVW7:NewPayload(GROUP:FindByName("VS-21"), 6, {AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})


NATO_CHIEF = CHIEF:New(coalition.side.BLUE, nil, "NATO Chief")
NATO_CHIEF:AddAirwing(CVW7)
NATO_CHIEF:Start()