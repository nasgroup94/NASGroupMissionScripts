

-- Tanker Zones
local aarSouth = {
    zone = ZONE:New("AAR South"),
    speed = 260,
    hdg = 290,
    leg = 60,
}

local aarNorth = {
    zone = ZONE:New("AAR North"),
    speed = 260,
    hdg = 120,
    leg = 60,
}

local AlMinadSquadronParkingIDs = {
    Tanker = {1,2,3,4},
}

-- Create AirWing at Al Minad AFB
AMAW = AIRWING:New("Warehouse Al Minad AFB", "Al Minad Air Wing")

-- Tanker Squadron
Tank = SQUADRON:New("CVN71_ARCO2",4,"Al Minad Tanker Squadron")
    :AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
    :SetParkingIDs(AlMinadSquadronParkingIDs.Tanker)
    :SetFuelLowThreshold(0.5)

AMAW:AddSquadron(Tank)
AMAW:NewPayload(GROUP:FindByName("CVN71_ARCO2"),4,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})




-- add tasks to airWing

local southAAR = AUFTRAG:NewORBIT(aarSouth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarSouth.speed,aarSouth.hdg,aarSouth.leg)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("South AAR")
    :SetTACAN(29,"STK")
    :SetRadio(369.5)

-- function southAAR:OnAfterScheduled(From,Event,To)
--     tankerSetup(self, CALLSIGN.Tanker.Texaco, 1, 29,)

local northAAR = AUFTRAG:NewORBIT(aarNorth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarNorth.speed,aarNorth.hdg,aarNorth.leg)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("North AAR")
    :SetTACAN(28,"NTK")
    :SetRadio(368.5)

southAAR:AssignSquadrons({Tank})
northAAR:AssignSquadrons({Tank})

local DetectionGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes("EW"):FilterStart()

Blue_Chief = CHIEF:New(coalition.side.BLUE, DetectionGroup,"Blue Chief")
Blue_Chief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

local ZoneBlueBorder=ZONE:New("Blue Border")
Blue_Chief:AddBorderZone(ZoneBlueBorder)
Blue_Chief:AddAirwing(AMAW)

Blue_Chief:Start()

Blue_Chief:AddMission(southAAR)
Blue_Chief:AddMission(northAAR)