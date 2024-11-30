-- Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('RATMANAGER')

-- Common functions
local function randomchoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    
    -- math.randomseed( os.time() )
    math.random(); math.random(); math.random()
    index = keys[math.random(1, #keys)]
    return t[index]
end

--  Aircraft from the Civil Aircraft Mod
local ratAircraftCivil = {
    "RAT-CIV-A320",
    "RAT-CIV-A330",
    "RAT-CIV-A380",
    "RAT-CIV-B757",
    "RAT-CIV-B747",
    "RAT-CIV-B737"
}

-- Aircraft liveries (Civil Aircraft Mod)
local aircraftLiveriesCivil = {
    ["RAT-CIV-A320"] = {
        "AIRFRANCE F-HEPH",
        "Air Asia HS-BBW",
        "Air Berlin D-ABNX",
        "Iberia D-AVVZ",
        "QATAR A7-LAD",
        "United N497UA"
    },
    ["RAT-CIV-A330"] = {
        "Air Canada",
        "Garude Indunesia",
        "RAF Voyager",
        "Air China",
        "AirAsia",
        "Philipines"
    },
    ["RAT-CIV-A380"] = {
        "China Southern",
        "Korean Air",
        "Qantas Airways",
        "Singapore Airlines",
        "Thai Airways"
    },
    ["RAT-CIV-B757"] = {
        "United Airlines Retro",
        "DHL Cargo",
        "FedEx Modern",
        "Swiss"
    },
    ["RAT-CIV-B747"] = {
        "Iron Maiden World Tour 2016",
        "Cathay Pacific Hong Kong",
        "Lufthansa",
        "Virgin Atlantic - Modern",
        "Air France"
    },
    ["RAT-CIV-B737"] = {
        "UPS",
        "P8 USN",
        "WestJet Retro",
        "Air France"
    }
}

-- Valid airports for RAT flights
local airports = {
    "Antonio B. Won Pat Intl",
    "Saipan Intl"
}

--  
local airwayZones = {
    ["Antonio B. Won Pat Intl"] = {
        "AIRWAY-A222",
        "AIRWAY-A450N",
        "AIRWAY-A450S",
        "AIRWAY-A597",
        "AIRWAY-B586N",
        "AIRWAY-B586S",
        "AIRWAY-G339",
        "AIRWAY-G467",
        "AIRWAY-M501",
        "AIRWAY-R584",
        "AIRWAY-R595"
    },
    ["Saipan Intl"] = {
        "AIRWAY-A597",
        "AIRWAY-G339",
        "AIRWAY-G467",
        "AIRWAY-M501",
        "AIRWAY-R595"
    }
}

local flightLevels = {
   250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370, 380, 400, 410, 420, 430, 440, 450
}
math.random(); math.random(); math.random()

-- Total number of Civilian RAT aircraft in the air at one time.
local maxNumRatAircraft = math.random(6, 16)

if (maxNumRatAircraft % 2 ~= 0) then
    maxNumRatAircraft = maxNumRatAircraft + 1
end

BASE:I("Random Num of aircraft:::::::::: " .. tostring(maxNumRatAircraft) )
RatManagerCivilDepts1 = RATMANAGER:New(maxNumRatAircraft/2)
RatManagerCivilDepts2 = RATMANAGER:New(maxNumRatAircraft/2)
RatManagerCivilArivals1 = RATMANAGER:New(maxNumRatAircraft/2)
RatManagerCivilArivals2 = RATMANAGER:New(maxNumRatAircraft/2)

for i = 1, (maxNumRatAircraft/2), 1 do
    -- math.random(); math.random(); math.random()

    -- Pick random aircraft
    local choiceAcfDept = math.random(1, #ratAircraftCivil)
    local choiceAcfArival = math.random(1, #ratAircraftCivil)
    local acfNameDept = ratAircraftCivil[choiceAcfDept]
    local acfNameArival = ratAircraftCivil[choiceAcfArival]

    -- Pick random liveries
    local liveriesDept = aircraftLiveriesCivil[acfNameDept]
    local liveriesArival = aircraftLiveriesCivil[acfNameArival]
    local choiceLivDept = math.random(1, #liveriesDept)
    local choiceLivArival = math.random(1, #liveriesArival)
    local livNameDept = liveriesDept[choiceLivDept]
    local livNameArival = liveriesArival[choiceLivArival]

    -- Pick random flight levels
    local choiceFlDept = math.random(1, #flightLevels)
    local choiceFlArival = math.random(1, #flightLevels)
    local flDept = flightLevels[choiceFlDept]
    local flArival = flightLevels[choiceFlArival]

    -- Pick random departures
    -- local choiceDeptAirport = math.random(1, #airports)
    -- local airportDept = airports[choiceDeptAirport]
    local airportDept = UTILS.GetRandomTableElement(airports, true)

    -- Pick random arivals
    -- local choiceArivAirport = math.random(1, #airports)
    -- local airportAriv = airports[choiceArivAirport]
    -- local choiceArivalAirways = math.random(1, #)
    local airportAriv = UTILS.GetRandomTableElement(airports, true)

    local debugData = {
        DeptAirport = airportDept,
        DeptAircraft = acfNameDept,
        DeptLiv = livNameDept,
        DeptFL = flDept,
        ArivAirport = airportAriv,
        ArvlAircraft = acfNameArival,
        ArvlLiv = livNameArival,
        ArvlFL = flArival
    }
    BASE:I({DebugData = debugData})

    RatManagerCivilDepts1:Add(RAT:New(acfNameDept, acfNameDept .. tostring(i))
        :SetDeparture(airportDept)
        :SetTerminalType(AIRBASE.TerminalType.OpenBig)
        :SetParkingSpotSafeON()
        :SetDestination(airwayZones[airportDept])
        :Livery(livNameDept)
        :DestinationZone()
        :Commute(true)
        :ATC_Messages(false)
        :SetCoalition("blue")
        :SetFL(flDept)
    )

    RatManagerCivilDepts2:Add(RAT:New(acfNameDept, acfNameDept .. tostring(i + 100))
        :SetDeparture(airportDept)
        :SetTerminalType(AIRBASE.TerminalType.OpenBig)
        :SetParkingSpotSafeON()
        :SetDestination(airwayZones[airportDept])
        :Livery(livNameDept)
        :DestinationZone()
        :Commute(true)
        :ATC_Messages(false)
        :SetCoalition("blue")
        :SetFL(flDept)
    )

    RatManagerCivilArivals1:Add(RAT:New(acfNameArival, acfNameArival .. tostring(i + 200))
        :SetDeparture(airwayZones[airportAriv])
        :SetDestination(airportAriv)
        :Livery(livNameArival)
        :SetCoalition("blue")
        :SetTakeoffAir()
        :ATC_Messages(false)
        :SetFL(flArival)
    )

    RatManagerCivilArivals2:Add(RAT:New(acfNameArival, acfNameArival .. tostring(i + 300))
        :SetDeparture(airwayZones[airportAriv])
        :SetDestination(airportAriv)
        :Livery(livNameArival)
        :SetCoalition("blue")
        :SetTakeoffAir()
        :ATC_Messages(false)
        :SetFL(flArival)
    )

end

RatManagerCivilDepts1:SetTspawn(math.random(500, 1000))
RatManagerCivilDepts2:SetTspawn(math.random(500, 1000))
RatManagerCivilArivals1:SetTspawn(math.random(500, 1000))
RatManagerCivilArivals2:SetTspawn(math.random(500, 1000))

function StartRatManagersWave1()
    RatManagerCivilDepts1:Start(math.random(120, 600))
    RatManagerCivilDepts1:Stop(4000)

    RatManagerCivilArivals1:Start(math.random(120, 600))
    RatManagerCivilArivals1:Stop(4000)
end

function StartRatManagersWave2()
    RatManagerCivilDepts2:Start(math.random(120, 600))
    RatManagerCivilDepts2:Stop(4000)

    RatManagerCivilArivals2:Start(math.random(120, 600))
    RatManagerCivilArivals2:Stop(4000)
end

function StartRatManagersWave3()
    RatManagerCivilDepts2:Start(math.random(120, 600))
    RatManagerCivilDepts2:Stop(4000)

    RatManagerCivilArivals2:Start(math.random(120, 600))
    RatManagerCivilArivals2:Stop(4000)
end

function StartRatManagersWave4()
    RatManagerCivilDepts2:Start(math.random(120, 600))
    RatManagerCivilDepts2:Stop(4000)

    RatManagerCivilArivals2:Start(math.random(120, 600))
    RatManagerCivilArivals2:Stop(4000)
end

TIMER:New(StartRatManagersWave1):Start(1)
TIMER:New(StartRatManagersWave2):Start(7200)
TIMER:New(StartRatManagersWave3):Start(14400)
TIMER:New(StartRatManagersWave4):Start(21600)

-- math.random(); math.random(); math.random()

-- Start the RatManagers and randomize interval and start times
-- RatManagerCivilDepts1:SetTspawn(math.random(500, 1000))
-- RatManagerCivilDepts1:Start(math.random(120, 600))
-- RatManagerCivilDepts1:Stop(2000)

-- RatManagerCivilDepts2:SetTspawn(math.random(500, 1000))
-- RatManagerCivilDepts2:Start(math.random(120, 600) + 7000)
-- RatManagerCivilDepts2:Stop(7000)

-- RatManagerCivilArivals1:SetTspawn(math.random(500, 1000))
-- RatManagerCivilArivals1:Start(math.random(120, 600) + 7000)
-- RatManagerCivilArivals1:Stop(2000)

-- RatManagerCivilArivals2:SetTspawn(math.random(500, 1000))
-- RatManagerCivilArivals2:Start(math.random(120, 600) + 7000)
-- RatManagerCivilArivals2:Stop(7000)

BLUE_NAVAL_CARGO = RNT:New('NavalCargoTraffic', {'SEALANE', 'PORT'}, {'RNTCARGO'})
    :InitDelayBetweenSpawns(900)
    :InitSpawnInRandomZones()
    :SetMaxGroupCount(10)
    :SetPathfindingOn(2500)
    -- :DebugOn()
    :Start()

BLUE_NAVAL_COASTAL = RNT:New('NavalCoastalTraffic', {'PORT'}, {'RNTCARGO', 'RNTFISHING', 'RNTCIVILIAN'})
    :InitDelayBetweenSpawns(600)
    :InitSpawnInRandomZones()
    :SetMaxGroupCount(10)
    :SetPathfindingOn(2500)
    -- :DebugOn()
    :Start()
