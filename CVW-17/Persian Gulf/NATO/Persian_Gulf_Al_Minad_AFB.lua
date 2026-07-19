--local range = require("../../../../DCSServerBot/plugins/funkman/samples/range")
-- Create AirWing at Al Minad AFB
AMAW = AIRWING:New("Warehouse Al Minad AFB", "Al Minad Air Wing")
         :SetAirbase(AIRBASE:FindByName(AIRBASE.PersianGulf.Al_Minhad_AFB))
         :SetRespawnAfterDestroyed(900)
AMAW:__Start(2)


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

 southAAR = AUFTRAG:NewTANKER(aarSouth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarSouth.speed,aarSouth.hdg,aarSouth.leg,1)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("South AAR")
    :SetTACAN(29,"Y","STK")
    :SetRadio(369.5)

southAAR:AssignSquadrons({Tank})

 northAAR = AUFTRAG:NewTANKER(aarNorth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe, aarNorth.speed,aarNorth.hdg,aarNorth.leg,1)
    :SetTime(1)
    :SetRepeat(10)
    :SetMissionRange(500)
    :AssignSquadrons({Tank})
    :SetName("North AAR")
    :SetTACAN(28,"Y","NTK")
    :SetRadio(368.5)

northAAR:AssignSquadrons({Tank})



-- AWACS Setup
awacsZones = {
    North = {
        zone = ZONE:FindByName("AWACS North"),
        alt = 30000,
        spd = 300,
        hdg = 90,
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
AWACSsquad = SQUADRON:New("AWACS", 4, "Al Minad AWACS")
                :AddMissionCapability({ AUFTRAG.Type.ORBIT })
                :SetCallsign(CALLSIGN.Aircraft.Magic, 5)
                :SetFuelLowThreshold(0.3)
                :SetRadio(305, radio.modulation.AM)

AWACSsquad:SetParkingIDs(AlMinadSquadronParkingIDs.AWACS)

AMAW:AddSquadron(AWACSsquad)
AMAW:NewPayload(GROUP:FindByName("AWACS"), 4, { AUFTRAG.Type.ORBIT })

northAWACS = AUFTRAG:NewAWACS(
        awacsZones.North.zone:GetCoordinate(),
        awacsZones.North.alt,
        awacsZones.North.spd,
        awacsZones.North.hdg,
        awacsZones.North.leg
)
                    :SetTime(1)
                    :SetRepeat(10)
                    :SetMissionRange(500)
                    :SetName("North AWACS")
                    :AssignSquadrons({ AWACSsquad })

southAWACS = AUFTRAG:NewAWACS(
        awacsZones.South.zone:GetCoordinate(),
        awacsZones.South.alt,
        awacsZones.South.spd,
        awacsZones.South.hdg,
        awacsZones.South.leg
)
                    :SetTime(1)
                    :SetRepeat(10)
                    :SetMissionRange(500)
                    :SetName("South AWACS")
                    :AssignSquadrons({ AWACSsquad })


NASG_ATC:AddAssets(AMAW)

local rangeAwacs = AWACS:New("South AWACS", AMAW,"blue",AIRBASE.PersianGulf.Al_Minhad_AFB,"AAR South",ZONE:FindByName("Dart"),"Cap Zone",251.5, radio.modulation.AM)
rangeAwacs:SetAwacsDetails(CALLSIGN.AWACS.Focus,1,30,300,88,25)


-- use Windows voices via the NASG TTS bridge
rangeAwacs:SetSRS(SRS_PATH, "male", "en-US", SRS_PORT, "Nathan", 0.9)
NASG_TTS:Use(rangeAwacs.AwacsSRS, "Focus", "Nathan", 200, 0.9)

rangeAwacs:__Start(5)