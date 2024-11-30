-- We need an AirWing
local AwacsAW = AIRWING:New("AirForce WH-1","AirForce One")
-- AwacsAW:SetReportOn()
AwacsAW:SetMarker(false)
AwacsAW:SetAirbase(AIRBASE:FindByName(AIRBASE.MarianaIslands.Andersen_AFB))
AwacsAW:SetRespawnAfterDestroyed(900)
AwacsAW:SetTakeoffAir()
AwacsAW:__Start(2)

-- And a couple of Squads
-- AWACS itself
local Squad_One = SQUADRON:New("Awacs One",2,"Awacs North")
-- Squad_One:AddMissionCapability({AUFTRAG.Type.ORBIT},100)
Squad_One:SetFuelLowRefuel(true)
Squad_One:SetFuelLowThreshold(0.2)
Squad_One:SetTurnoverTime(10,20)
AwacsAW:AddSquadron(Squad_One)
AwacsAW:NewPayload("Awacs One",-1,{AUFTRAG.Type.ORBIT},100)

-- Get AWACS started
local testawacs = AWACS:New("Cope West GCI",AwacsAW,"blue",AIRBASE.MarianaIslands.Andersen_AFB,"Awacs Orbit",ZONE:FindByName("Rock"),"Blue Cap Zone",255,radio.modulation.AM )
testawacs:SuppressScreenMessages(true)
testawacs.debug = false
testawacs:SetAwacsDetails(CALLSIGN.AWACS.Focus,1,30,280,88,25)
testawacs:SetSRS(SRS_PATH,"female","en-GB",SRS_PORT,"en-GB-Wavenet-F",0.9,GOOGLE_CREDS)

-- Set details
testawacs:SetTOS(4,4)
testawacs:DrawFEZ()
testawacs:__Start(5)
