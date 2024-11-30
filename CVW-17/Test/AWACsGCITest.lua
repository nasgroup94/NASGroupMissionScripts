-------e: May 2022
-------------------------------------------------------------------------

---- ------------------------------------------------------------------
-- AWC-100 Basic Demo
-------------------------------------------------------------------------
-- Documentation
-- 
-- Ops AWACS https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.AWACS.html
--
-------------------------------------------------------------------------
-- Basic demo of AWACS functionality. You can join one of the planes 
-- and switch to AM 255 to listen in. Also, check out the F10 menu.
-------------------------------------------------------------------------
-- DatThese are set in ME trigger
local hereSRSPath = mySRSPath or "D:\\DCS-SimpleRadioStandalone-2.0.8.5"
local hereSRSPort = mySRSPort or 5005
local hereSRSGoogle = mySRSGKey  or "VNAO\\cvw7-tracking-11c8a6927776.json"

--- SETTINGS
_SETTINGS:SetLocale("en")
_SETTINGS:SetImperial()
_SETTINGS:SetPlayerMenuOff()

-- We need an AirWing
local AwacsAW = AIRWING:New("AirForce WH-1","AirForce One")
--AwacsAW:SetReportOn()
AwacsAW:SetMarker(false)
AwacsAW:SetAirbase(AIRBASE:FindByName(AIRBASE.Caucasus.Kutaisi))
AwacsAW:SetRespawnAfterDestroyed(900)
AwacsAW:SetTakeoffAir()
AwacsAW:__Start(2)

-- And a couple of Squads
-- AWACS itself
local Squad_One = SQUADRON:New("Awacs One",2,"Awacs North")
Squad_One:AddMissionCapability({AUFTRAG.Type.ORBIT},100)
Squad_One:SetFuelLowRefuel(true)
Squad_One:SetFuelLowThreshold(0.2)
Squad_One:SetTurnoverTime(10,20)
AwacsAW:AddSquadron(Squad_One)
AwacsAW:NewPayload("Awacs One One",-1,{AUFTRAG.Type.ORBIT},100)


-- Get AWACS started
-- local testawacs = AWACS:New("AWACS North",AwacsAW,"blue",AIRBASE.MarianaIslands.Andersen_AFB,"Awacs Orbit",ZONE:FindByName("Rock"),"Fresno",255,radio.modulation.AM )
local testawacs = AWACS:New("Cope West GCI",AwacsAW,"blue",AIRBASE.MarianaIslands.Andersen_AFB,"Awacs Orbit",ZONE:FindByName("Rock"),"Blue Cap Zone",255,radio.modulation.AM )
testawacs.debug = false
-- testawacs:SetEscort(2)
testawacs:SetAwacsDetails(CALLSIGN.AWACS.Darkstar,1,30,280,88,25)

-- Set up SRS
if hereSRSGoogle then
  -- use Google
  testawacs:SetSRS(hereSRSPath,"female","en-GB",hereSRSPort,"en-GB-Wavenet-F",0.9,hereSRSGoogle)
else
  -- use Windows
  testawacs:SetSRS(hereSRSPath,"male","en-GB",hereSRSPort,nil,0.9)
end

-- Set details
testawacs:SetTOS(4,4)
testawacs:DrawFEZ()
testawacs:__Start(5)
