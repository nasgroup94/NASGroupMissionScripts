-- Create AirWing at Al Minad AFB
AMAW = AIRWING:New("Warehouse Al Minad AFB", "Al Minad Air Wing")


--Al Minad AFB Parking
local AlMinadSquadronParkingIDs = {
    Tanker = {1,2,3,4},
    AWACS = {45,46,47,48},
}


-- Tanker setup
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

-- Tanker Squadron
Tank = SQUADRON:New("CVN71_ARCO2",4,"Al Minad Tanker Squadron")
    :AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
    :SetParkingIDs(AlMinadSquadronParkingIDs.Tanker)
    :SetFuelLowThreshold(0.5)

AMAW:AddSquadron(Tank)
AMAW:NewPayload(GROUP:FindByName("CVN71_ARCO2"),4,{AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})

-- add tasks to airWing

 southAAR = AUFTRAG:NewORBIT(aarSouth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarSouth.speed,aarSouth.hdg,aarSouth.leg)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("South AAR")
    :SetTACAN(29,"STK")
    :SetRadio(369.5)

southAAR:AssignSquadrons({Tank})

 northAAR = AUFTRAG:NewORBIT(aarNorth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarNorth.speed,aarNorth.hdg,aarNorth.leg)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("North AAR")
    :SetTACAN(28,"NTK")
    :SetRadio(368.5)

northAAR:AssignSquadrons({Tank})



-- AWACS Setup
 awacsZones= {
    {
        zone = ZONE:FindByName("AWACS North"),
        alt = 3000,
        spd = 300,
        hdg = 90,
        leg = 60,
    },
}

AWACS = SQUADRON:New("AWACS",4,"Al Minad AWACS")
    :AddMissionCapability({AUFTRAG.Type.AWACS})
    :SetCallsign(CALLSIGN.Aircraft.Overlord,5)
    :SetFuelLowThreshold(0.3)
    :SetRadio(262, radio.modulation.AM)

AWACS:SetParkingIDs(AlMinadSquadronParkingIDs.AWACS)

AMAW:AddSquadron(AWACS)
AMAW:NewPayload(GROUP:FindByName("AWACS"),4,{AUFTRAG.Type.AWACS})
