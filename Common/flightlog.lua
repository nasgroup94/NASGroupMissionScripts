-- Instructions: include flightlog.lua in a mission either with a DO SCRIPT FILE, or a
-- DO SCRIPT containing the following:
-- assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/Common/flightlog.lua"))()


-- Configuration Options
local Debug = false
local FlightLogSendDelay = 10
local funkmanHost = "127.0.0.1"
local funkmanPort = 10042

package.path  = package.path .. ';c:\\NASG\\NASGroupMissionScripts\\Common\\?.lua;'
package.cpath = package.cpath .. ';c:\\NASG\\NASGroupMissionScripts\\Common\\?.dll;'
local uuid = require("uuid_generator")


-- Table to store the Flight Log information.  This is Global so that it can be used in
-- mission scipts
PilotFlightRecord = {}

local function sendToFunkman(result)
    local funkmanSocket = socket.udp()
    funkmanSocket:settimeout(0)

    result.server_name = BASE.ServerName
    net.log("ROLLN", log.INFO, "Sending LSO table to funkman.  From: ".. result.server_name)

    funkmanSocket:sendto(json:encode(result), funkmanHost, funkmanPort)
end


local function ucid_from_name(name_to_check)
    local flID = nil

    local player_list = net.get_player_list()

    for _, id in pairs(player_list) do
        local player = net.get_player_info(id)
        if Debug then
            dcsbot.sendBotMessage('Getting player ucid from player name: Player'..name_to_check..' '..net.lua2json(player))
        end
        if player.name == name_to_check then
            flID = player.ucid
        end
    end

    return flID
end

local function NewFlightLogEntry()
    if Debug then
        dcsbot.sendBotMessage('NewFlightLogEntry')
    end
    -- this function fills in an empty flight log entry with no details about the flight
    local elem = {}
    elem.id = uuid.gen() -- Use call to the uuid_generator.dll
    net.log("new UUID: "..tostring(elem.id))
    elem.logState = 'initial'
    -- elem.pending = false
    -- elem.submitted = false
    elem.airborne = false
    elem.departureField = ''
    elem.arrivalField = ''
    elem.touchDowns = 0
    elem.airStart = 0
    elem.ejected = 0
    elem.dead = 0
    elem.crash = 0
    elem.missionEnd = 0
    elem.deptTime = nil
    elem.traps = {}

    return elem
end

local function sendFlightLog(flID)
    if Debug then
        dcsbot.sendBotMessage('Sending flightlog')
        dcsbot.sendBotMessage('Trying to send: ' .. net.lua2json(PilotFlightRecord[flID]))
    end

    if PilotFlightRecord[flID].flightlog.logState == 'initial' and PilotFlightRecord[flID].flightlog.deptTime ~= nil then
        if Debug then
            dcsbot.sendBotMessage('Initialize flight log in DB')
        end
        PilotFlightRecord[flID].command = 'onFlightLogNew'
        dcsbot.sendBotTable(PilotFlightRecord[flID])

        PilotFlightRecord[flID].flightlog.logState = 'update'

    elseif PilotFlightRecord[flID].flightlog.logState == 'update' then
        if Debug then
            dcsbot.sendBotMessage('Updating flight log in DB')
        end

        -- First check to see if the flight is airborne or not.  If it's airborne, we want to
        -- udpate the DB record.  If the pilot is still on the ground, sendFlightLogs function is called 15secs
        -- after the landing event is triggered, so if he is still on the grond 15secs later, we consider this a landing
        -- and close the flightlog.
        if PilotFlightRecord[flID].flightlog.airborne == true then
            PilotFlightRecord[flID].command = 'onFlightLogUpdate'
            dcsbot.sendBotTable(PilotFlightRecord[flID])

        else
            -- Flightlog is not marked as airborne so close the flight log.
            net.log("ROLLN", log.INFO, "Sending close flight log")
            if Debug then
                dcsbot.sendBotMessage('Closing flight log in DB')
            end
            PilotFlightRecord[flID].command = 'onFlightLogClose'
            dcsbot.sendBotTable(PilotFlightRecord[flID])

            -- It's been submitted, reset flight log
            PilotFlightRecord[flID].flightlog = nil
            PilotFlightRecord[flID].flightlog = {}
            PilotFlightRecord[flID].flightlog = NewFlightLogEntry()
        end
    else
        if Debug then
            dcsbot.sendBotMessage('Why did I make it here? 👎')
        end
    end
end

local function NewPilotRecord(flID, flType, flAirStart, flCallsign, flCoalition)
    if Debug then
        dcsbot.sendBotMessage('Creating new pilot record.')
    end

    local logEntry = {}
    logEntry.callsign = flCallsign
    logEntry.acType = flType
    logEntry.coalition = flCoalition
    logEntry.flightlog = {}
    logEntry.flightlog = NewFlightLogEntry()

    PilotFlightRecord[flID] = {}
    PilotFlightRecord[flID] = logEntry

    if flAirStart then
        -- There is no takeoff event for air start, so send out initial flight log to db
        PilotFlightRecord[flID].flightlog.airStart = 1
        PilotFlightRecord[flID].flightlog.airborne = true
        PilotFlightRecord[flID].flightlog.departureField = 'Air'
        PilotFlightRecord[flID].flightlog.deptTime = os.date('%x %X') --Date Time from server
        timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + FlightLogSendDelay)
    end

    if Debug then
        dcsbot.sendBotMessage(net.lua2json(PilotFlightRecord[flID]))
    end
end

local function FlightLogDeparture(flID, flAirfield)
    if Debug then
        dcsbot.sendBotMessage('Flight Log Departure called.  ID: ' .. flID .. ' airfield: ' .. flAirfield)
    end
    
    if PilotFlightRecord[flID] == nil then
        return
    end

    -- only fill in the departure field if it was empty.  For air starts it should be Air.  If it's empty
    -- then they haven't taken off yet, or the log was submitted and it was reset
    if PilotFlightRecord[flID].flightlog.departureField == '' then
        PilotFlightRecord[flID].flightlog.departureField = flAirfield
    end

    -- reset the pending flag here to false to stop the flight log from being submitted in the case where someone just landed
    -- PilotFlightRecord[flID].flightlog.pending = false

    -- the departure handler here is the only place where a flight log can be opened by changing a submitted flight log back to false
    -- PilotFlightRecord[flID].flightlog.submitted = false

    -- pilot has taken off, mark the flight log as airborne.
    PilotFlightRecord[flID].flightlog.airborne = true

    if PilotFlightRecord[flID].flightlog.deptTime == nil then
        PilotFlightRecord[flID].flightlog.deptTime = os.date('%x %X') --Date Time from server
    end

    -- Added 5 sec delay in order for this to work correctly on departures...  DCSism stuff, won't work without it.
    timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + 5)
end

local function FlightLogArrival(flID, flAirfield)
    if Debug then
        dcsbot.sendBotMessage('Arrival')    
    end
    
    if PilotFlightRecord[flID] == nil then
        -- this is what happens when you have an AI air start plane land and you're tracking AI stats/messages
        return
    end

    -- the logic here is that the last airfield you touch down on goes into arrivalField
    PilotFlightRecord[flID].flightlog.arrivalField = flAirfield

    PilotFlightRecord[flID].flightlog.touchDowns = PilotFlightRecord[flID].flightlog.touchDowns + 1

    -- pilot has landed, mark the flight log as landed.
    PilotFlightRecord[flID].flightlog.airborne = false

    -- Landing triggers a flight log submission in FlightLogSendDelay seconds in the future
    -- the other ways that the flight log will be sent: dead, eject, crash
    -- PilotFlightRecord[flID].flightlog.pending = true

    net.log("ROLLN", log.INFO, "Arrival: "..PilotFlightRecord[flID].callsign)

    timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + FlightLogSendDelay)
end

local function FlightLoggingGetName(initiator)
    if initiator == nil then
        return false, nil;
    end

    -- need to be careful here because it seems like the player has a chance to die before we can query their name it seems
    local statusflag, name = pcall(Unit.getPlayerName, initiator)

    if statusflag == false then
        return false, nil;
    end

    return true, name;
end

local function FlightLoggingTakeOffHandler(event)

    if event.id == world.event.S_EVENT_TAKEOFF then

        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end

        -- local airfieldName = Airbase.getName(event.place)
        local statusflag2, airfieldName = pcall(Airbase.getName, event.place)

        if statusflag2 == false then
            airfieldName = 'Unknown'
        end

        if airfieldName == nil then
            airfieldName = 'Unknown'
        end

        if Debug then
            dcsbot.sendBotMessage('Takeoff Handler')
        end

        -- local flID = Unit.getID(event.initiator)
        local flID = ucid_from_name(name)

        FlightLogDeparture(flID, airfieldName)
    end
end

local function FlightLoggingLandingHandler(event)
    if event.id == world.event.S_EVENT_LAND then

        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end

        -- wrapping the airfield name in a pcall here because it seems helicopters or planes landing at different places, like not on a field
        -- won't trigger this.
        -- TODO : what happens with a field, roadside or farp landing?
        local statusflag2, airfieldName = pcall(Airbase.getName, event.place)

        if statusflag2 == false then
            airfieldName = 'Unknown'
        end

        if airfieldName == nil or airfieldName == '' then
            airfieldName = 'Unknown'
        end

        -- local flID = Unit.getID(event.initiator)
        local flID = ucid_from_name(name)

        if flID == nil then
            return
        end

        if Debug then
            dcsbot.sendBotMessage('Landing Handler')
        end

        FlightLogArrival(flID, airfieldName)
    end
end

local function FlightLoggingMissionEndHandler(event)
    if event.id == world.event.S_EVENT_MISSION_END then

        if Debug then
            dcsbot.sendBotMessage('Mission End Handler')
        end

        -- If the mission has ended loop through everything in the flight log and submit flight logs
        -- for any elements that haven't landed
        for flID, v in pairs(PilotFlightRecord) do
            if v.flightlog.airborne == true then
                PilotFlightRecord[flID].flightlog.airborne = false
                -- PilotFlightRecord[flID].flightlog.pending = true
                PilotFlightRecord[flID].flightlog.missionEnd = 1
                sendFlightLog(flID)
            end
        end
        -- end

    end

end

local function FlightLoggingBirthHandler(event)
    if event.id == world.event.S_EVENT_BIRTH then

        -- if Debug then
        --     dcsbot.sendBotMessage('event: '..net.lua2json(event))
        -- end
        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end


        -- local flID = ucid_from_name(name)
        local flID = ucid_from_name(name)


        if Debug then
            dcsbot.sendBotMessage('Birth Handler - ' .. tostring(flID))
        end


    --     local flID = Unit.getID(event.initiator)
        
    --     if Debug then
    --         dcsbot.sendBotMessage('Birth Handler - ' .. tostring(flID))
    --     end

        NewPilotRecord(flID, Unit.getTypeName(event.initiator), event.initiator:inAir(), name,
            event.initiator:getCoalition())
    end
end

local function FlightLoggingPilotDeadHandler(event)
    if event.id == world.event.S_EVENT_PILOT_DEAD then

        -- local name = Unit.getPlayerName(event.initiator)
        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end


        if Debug then
            dcsbot.sendBotMessage('Pilot Dead Handler')
        end

        -- local flID = Unit.getID(event.initiator)
        local flID = ucid_from_name(name)

        if PilotFlightRecord[flID] ~= nil then
            PilotFlightRecord[flID].flightlog.dead = 1
            PilotFlightRecord[flID].flightlog.airborne = false
            timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + 5)
            -- if PilotFlightRecord[flID].flightlog.pending == false then
            --     PilotFlightRecord[flID].flightlog.pending = true
            --     timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + FlightLogSendDelay)
            -- end
        end
    end
end

local function FlightLoggingCrashHandler(event)
    if event.id == world.event.S_EVENT_CRASH then
        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end

        -- local flID = Unit.getID(event.initiator)
        local flID = ucid_from_name(name)

        if Debug then
            dcsbot.sendBotMessage('Pilot Crash Handler')
        end

        if PilotFlightRecord[flID] ~= nil then
            PilotFlightRecord[flID].flightlog.crash = 1
            PilotFlightRecord[flID].flightlog.airborne = false
            timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + 5)
            -- if PilotFlightRecord[flID].flightlog.pending == false then
            --     PilotFlightRecord[flID].flightlog.pending = true
            --     timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + FlightLogSendDelay)
            -- end
        end
    end
end

local function FlightLoggingPilotEjectHandler(event)
    if event.id == world.event.S_EVENT_EJECTION then

        -- local name = Unit.getPlayerName(event.initiator)
        local statusflag, name = FlightLoggingGetName(event.initiator)

        if statusflag == false then
            return
        end

        if name == nil then
            return
        end

        if Debug then
            dcsbot.sendBotMessage('Pilot Eject Handler')
        end

        -- local flID = Unit.getID(event.initiator)
        local flID = ucid_from_name(name)

        if PilotFlightRecord[flID] ~= nil then
            PilotFlightRecord[flID].flightlog.ejected = 1
            PilotFlightRecord[flID].flightlog.airborne = false
            timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + 5)
            -- if PilotFlightRecord[flID].flightlog.pending == false then
            --     PilotFlightRecord[flID].flightlog.pending = true
            --     timer.scheduleFunction(sendFlightLog, flID, timer.getTime() + FlightLogSendDelay)
            -- end
        end
    end
end

-- Need to get rid of MIST and either use DCS scripting API or MOOSE scripting to add the event handlers.
-- Ideally, using DCS scripting API a this would remove any dependencies.
mist.addEventHandler(FlightLoggingBirthHandler)
mist.addEventHandler(FlightLoggingTakeOffHandler)
mist.addEventHandler(FlightLoggingLandingHandler)
mist.addEventHandler(FlightLoggingPilotEjectHandler)
mist.addEventHandler(FlightLoggingCrashHandler)
mist.addEventHandler(FlightLoggingPilotDeadHandler)
mist.addEventHandler(FlightLoggingMissionEndHandler)
-- end
