AWCVN71 = AIRWING:New("CVN-71 Teddy","CVW-17 Airwing")

CVN71_ARCO = SQUADRON:New("CVN71_ARCO1",6,"CVW-17 Tanker")
    :AddMissionCapability({AUFTRAG.Type.TANKER, AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Tanker.Arco, 1)
    :SetFuelLowRefuel(true)
    :SetFuelLowThreshold(0.3)
    :SetTakeoffAir()

AWCVN71:AddSquadron(CVN71_ARCO)
AWCVN71:NewPayload(GROUP:FindByName("CVN71_ARCO1"),6,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})


local carrier = STATIC:FindByName("CVN-71 Teddy")
local zone = ZONE_UNIT:New("CVN71_Zone", carrier, 100)
local flotillaCSG1 = FLOTILLA:New("CSG1-1",1, "Carrier Strike Group 1")