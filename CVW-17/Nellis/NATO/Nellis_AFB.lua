--local range = require("../../../../DCSServerBot/plugins/funkman/samples/range")
-- Create AirWing at Al Minad AFB
NellisAW = AIRWING:New("Warehouse Nellis AFB", "Nellis Air Wing")
:SetAirbase(AIRBASE:FindByName(AIRBASE.Nevada.Nellis))
:SetRespawnAfterDestroyed(900)
NellisAW:__Start(2)


--Al Minad AFB Parking
local NellisParkingIDs = {
	Tanker = {40,42,56,58,182,153},
	S3Tanker={16,17,18,19},

}


-- Tanker setup
-- Tanker Zones

local coral = {
	zone = ZONE:New("Coral"),
	speed = 260,
	hdg = 252,
	leg = 25,
}
local jade = {
	zone = ZONE:New("Jade"),
	speed = 270,
	hdg = 220,
	leg = 25,
}

local pearl = {
	zone = ZONE:New("Pearl"),
	speed = 250,
	hdg = 138,
	leg = 25,
}

local amber = {
	zone = ZONE:New("Amber"),
	speed = 300,
	hdg = 268,
	leg = 35,
}

local topaz = {
	zone = ZONE:New("Topaz"),
	speed = 270,
	hdg = 180,
	leg = 35
}

local onyx = {
	zone = ZONE:New("Onyx"),
	speed = 270,
	hdg = 1,
	leg = 35
}


--local AirbaseObj = AIRBASE:FindByName(AIRBASE.Nevada.Nellis):MarkParkingSpots()





--A6

A6Tank = SQUADRON:New("Jade",4,"Nellis A6 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.S3Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(A6Tank)
NellisAW:NewPayload(GROUP:FindByName("Jade"),6,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartA6Tank = SQUADRON:New("JadeAir",1,"Air Start Nellis A6 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetTakeoffType("Air")
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartA6Tank)







--S3
S3Tank = SQUADRON:New("Coral",4,"Nellis S3 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.S3Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(S3Tank)
NellisAW:NewPayload(GROUP:FindByName("Coral"),4,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartS3Tank = SQUADRON:New("CoralAir",1,"Air Start Nellis S3 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetTakeoffType("Air")
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartA6Tank)







--C130
C130Tank = SQUADRON:New("Pearl",4,"Nellis C-130 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(C130Tank)
NellisAW:NewPayload(GROUP:FindByName("Pearl"),4,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartC130Tank = SQUADRON:New("PearlAir",1,"Air Start Nellis C-130 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetTakeoffType("Air")
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartC130Tank)







--KC130
KC130Tank = SQUADRON:New("Topaz",4,"Nellis KC-130 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(KC130Tank)
NellisAW:NewPayload(GROUP:FindByName("Topaz"),10,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartKC130Tank = SQUADRON:New("TopazAir",2,"Air Start Nellis KC-130 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetTakeoffType("Air")
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartKC130Tank)



--KC135
KC135Tank = SQUADRON:New("Onyx",4,"Nellis KC-135 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(KC135Tank)
NellisAW:NewPayload(GROUP:FindByName("Onyx"),10,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartKC135Tank = SQUADRON:New("OnyxAir",2,"Air Start Nellis KC-135 tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetTakeoffType("Air")
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartKC135Tank)



--KC135MPRS
KC135MPRSTank = SQUADRON:New("Amber",4,"Nellis KC-135 MPRS tankers")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetParkingIDs(NellisParkingIDs.Tanker)
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(KC135MPRSTank)
NellisAW:NewPayload(GROUP:FindByName("Amber"),6,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

AirStartKC135MPRSTank = SQUADRON:New("AmberAir",1,"Nellis Air Start KC135MPRS")
:SetTakeoffType("Air")
:AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
:SetFuelLowThreshold(0.5)

NellisAW:AddSquadron(AirStartKC135MPRSTank)


-- add tasks to airWing

Jade = AUFTRAG:NewTANKER(jade.zone:GetCoordinate(),20000, jade.speed,jade.hdg,jade.leg,1)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(500)
:AssignSquadrons({AirStartA6Tank,A6Tank})
:SetName("Jade")
:SetTACAN(14,"Y","JAD")
:SetRadio(323)



Coral = AUFTRAG:NewTANKER(coral.zone:GetCoordinate(),20000, coral.speed,coral.hdg,coral.leg,1)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(500)
:AssignSquadrons({AirStartS3Tank, S3Tank})
:SetName("Coral")
:SetTACAN(64,"Y","COR")
:SetRadio(364.1)



Pearl = AUFTRAG:NewTANKER(pearl.zone:GetCoordinate(),15000, pearl.speed,pearl.hdg,pearl.leg,1)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(700)
:AssignSquadrons({AirStartC130Tank,C130Tank})
:SetName("Pearl")
:SetTACAN(52,"Y","PEA")
:SetRadio(323.1)



Topaz = AUFTRAG:NewTANKER(topaz.zone:GetCoordinate(),15000,topaz.speed,topaz.hdg,topaz.leg,0)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(700)
:AssignSquadrons({AirStartKC130Tank,KC130Tank})
:SetName("Topaz")
:SetTACAN(30,"Y","TOP")
:SetRadio(324.6)



Onyx = AUFTRAG:NewTANKER(onyx.zone:GetCoordinate(),25000,onyx.speed,onyx.hdg,onyx.leg,0)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(700)
:AssignSquadrons({AirStartKC135Tank,KC135Tank})
:SetName("Onyx")
:SetTACAN(24,"Y","ONY")
:SetRadio(325.6)



Amber = AUFTRAG:NewTANKER(amber.zone:GetCoordinate(),25000, amber.speed,amber.hdg,amber.leg,1)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(700)
:AssignSquadrons({AirStartKC135MPRSTank,KC135MPRSTank})
:SetName("Amber")
:SetTACAN(35,"Y","AMB")
:SetRadio(335.6)




-- AWACS Setup
awacsZones = {
	North = {
		zone = ZONE:FindByName("AWACS North"),
		alt = 30000,
		spd = 300,
		hdg = 250,
		leg = 60,
	},
	South = {
		zone = ZONE:FindByName("AWACS South"),
		alt = 30000,
		spd = 300,
		hdg = 180,
		leg = 30,
	},
}




-- NOTE: do NOT name this variable "AWACS" — that is the MOOSE Ops.AWACS class,
-- and shadowing it turns AWACS:New(...) below into SQUADRON:New(...).
AWACSsquad = SQUADRON:New("AWACS", 4, "Nellis AWACS")
:AddMissionCapability({ AUFTRAG.Type.ORBIT })
:SetCallsign(CALLSIGN.Aircraft.Wizard, 6)
:SetFuelLowThreshold(0.3)
:SetRadio(262, radio.modulation.AM)

AWACSsquad:SetParkingIDs(NellisParkingIDs.Tanker)

NellisAW:AddSquadron(AWACSsquad)
NellisAW:NewPayload(GROUP:FindByName("AWACS"), 4, { AUFTRAG.Type.ORBIT })

northAWACS = AUFTRAG:NewAWACS(
	awacsZones.North.zone:GetCoordinate(),
	awacsZones.North.alt,
	awacsZones.North.spd,
	awacsZones.North.hdg,
	awacsZones.North.leg
)
:SetTime(1)
:SetRepeat(10)
:SetMissionRange(700)
:SetName("North AWACS")
:AssignSquadrons({ AWACSsquad })

--southAWACS = AUFTRAG:NewAWACS(
--	awacsZones.South.zone:GetCoordinate(),
--	awacsZones.South.alt,
--	awacsZones.South.spd,
--	awacsZones.South.hdg,
--	awacsZones.South.leg
--)
--:SetTime(1)
--:SetRepeat(10)
--:SetMissionRange(500)
--:SetName("South AWACS")
--:AssignSquadrons({ AWACSsquad })


NASG_ATC:AddAssets(NellisAW)

--local rangeAwacs = AWACS:New("South AWACS", NellisAW,"blue",AIRBASE.PersianGulf.Al_Minhad_AFB,"AAR South",ZONE:FindByName("Dart"),"Cap Zone",251.5, radio.modulation.AM)
--rangeAwacs:SetAwacsDetails(CALLSIGN.AWACS.Focus,1,30,300,88,25)
--
--
---- use Windows voices via the NASG TTS bridge
--rangeAwacs:SetSRS(SRS_PATH, "male", "en-US", SRS_PORT, "Nathan", 0.9)
--NASG_TTS:Use(rangeAwacs.AwacsSRS, "Focus", "Nathan", 200, 0.9)
--
--rangeAwacs:__Start(5)