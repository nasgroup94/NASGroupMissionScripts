-- Debuging
--[[
BASE:TraceOnOff(true)
BASE:TraceLevel(3)
BASE:TraceClass('REFUELING_MONITOR')
--]]

local function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    return output_str
end
-- Debugging End

local function Round(num, dp)
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5)/mult
end

-- Total fuel each aircraft can hold internally.  This is used to calculate all fuel values as they we only get percentages of internal fuel
-- from DCS
AircraftData = {}
AircraftData["FA-18C_hornet"]   = { FuelMax = 4900 }
AircraftData["F-14B"]           = { FuelMax = 7300 }
AircraftData["F-14A-135-GR"]    = { FuelMax = 7300 }
AircraftData["AV8BNA"]          = { FuelMax = 3500 }
AircraftData["M-2000C"]         = { FuelMax = 3150 }
AircraftData["F-16C_50"]        = { FuelMax = 3250 }
AircraftData["F-15C"]           = { FuelMax = 6100 }
AircraftData["A-10C"]           = { FuelMax = 5000 }
AircraftData["A-10C_2"]         = { FuelMax = 5000 }


--[[ My attempt at capturing refueling events in MP
    The general outline is that when a client is with in a zone around a tanker, start monitoring the clients fuel amount to see if
    it is increasing or not and keep track of total fuel received and how many times the client connected while not leaving the zone. 
    After the client has left the zone then a function is called where mission designers can report the results.

    Tanker zones are created based on a unit set that is filtered based on a naming convention used in the tankers name .  For e.g. 
    using names that contain words like "Shell", "Texaco", "Arco" or "Tanker".

    Checking to see if any tanker zones contain any clients occurs at an interval of 15secs. Once one or more clients are found to be in
    one or more of the zones, the checking interval decreases to 3secs and is also checking the client's fuel level. 

    Starting the REFUELING_MONITOR using something like this will create a zone around any unit that has "Texaco" or "Shell" in the unit's
    name:
     Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco"}) 
--]]

REFUELING_MONITOR = {
    ClassName           = "REFUELING_MONITOR",
    _tankers            = SET_UNIT:New(),           -- Set of tanker units.
    _zones              = SET_ZONE:New(),           -- Set of zones created for each tanker.
    _clients            = SET_CLIENT:New(),         -- Set of active clients.
    _clientInZone       = false,                    -- Does any of the zones have a client within it.
    _clientsInZoneData  = {}                        -- See the _initClientData() function to see what data this table should contain.
}

REFUELING_MONITOR.version = "0.0.1"

function REFUELING_MONITOR:New(tankerPrefixes)

    if type(tankerPrefixes) ~= "table" then
        tankerPrefixes = {tankerPrefixes}
    end

    -- Inherit from the FSM class so we can trigger our own refueling events.
    local self = BASE:Inherit(self, FSM:New())

    self:I("Loading REFUELING_MONITOR")
    self:F(tankerPrefixes)

    -- Build a set of blue tankers based on the naming convention and start the filter.
    self._tankers:FilterPrefixes(tankerPrefixes)
                :FilterCategories({"plane"})
                :FilterCoalitions({"blue"})
                :FilterActive()
                :FilterStart()

    self._zones:FilterPrefixes("_refuel_zone")
                :FilterStart()

    self._clients:FilterCategories({"plane"})
                :FilterCoalitions({"blue"})
                :FilterActive()
                :FilterStart()

    -- Create a status trigger.
    self:SetStartState("CheckingZones")
    self:AddTransition("*",     "CheckingZones",        "*")
    self:AddTransition("*",     "ClientInZone",         "*")

    self:__CheckingZones(15)

    return self
end

-- When a client first enters a zone, initialize it's _clientData
function REFUELING_MONITOR:_initClientData(clientUnitObject, zone)
    self:T("_initClientData called.")
    self:F({client = clientUnitObject, zone = zone})

    local clientName = clientUnitObject:GetPlayer()
    local clientUnitType = clientUnitObject:GetClientGroupUnit():GetGroup():GetTypeName()
    local zoneUnit = zone.ZoneUNIT
    local zoneName = zoneUnit.ZoneName
    local unitName = zoneUnit:GetCallsign()

    self:T(string.format("clientUnitObject type is %s.", type(clientUnitObject)))
    self:T(string.format("Initialized client name is %s.", clientName))

    self._clientsInZoneData[clientName] = {
            AircraftType    = clientUnitType,                       -- Name of the aircraft type.  Used to get the TotalFuelAmt that the client's aircraft can hold
            ZoneName        = zoneName,                             -- Name of the zone this client is in.
            Checked         = true,                                 -- Has this client been checked for fuel amount?
            Refueling       = false,                                -- Is this client currently receiving fuel.
            RefuelingAttempts = 0,                                  -- How many times this client has refueled while they were in the refueling zone.
            TotalFuelAmt    = AircraftData[clientUnitType].FuelMax, -- How much total internal fuel can this client's aircraft hold (used to calculate fuel that DCS reports in percentages).
            InitialFuelAmt  = 0,                                    -- The amount of fuel this client has when they start refueling.
            PrevCheckedAmt  = 0,                                    -- The amount of fuel this client had when it was checked last iteration.
            CurrentFuelAmt  = 0,                                    -- The amount of fuel this client has in this iteration.
            ReceivedFuelAmt = 0,                                    -- The total amount of fuel this client received from all attempts.
            TankerName      = unitName,                             -- The name of the tanker supplying the fuel.
    }
    return self
end


-- A client (or multiple clients) have entered one of the tanker zones so we check more frequently.
--
-- CHECK ALL TANKER ZONES AND CLIENTS WITHIN ZONES
-- First, we iterate through each zone and then each client within that zone. If a client is found
-- and currently does not have a _clientsInZoneData entry yet, initialize the new clientData.
--
-- Second, now we check to see if the clients fuel amount is increasing (there is some provision for
-- counting the number of attempts before leaving the zone). The first time fuel is found increasing,
-- we increase the number of attempts by 1, we flag the _clientsInZoneData is now refueling and we stamp the intial
-- fuel amount so we can calculate the total amount received at a later time. Then we update the _clientsInZoneData
-- current fuel amount with the client's current fuel.
--
-- Third, if the client's fuel amount is not increasing we know he has disconnected. So we flag _clientsInZoneData
-- is not refueling and we update the final fuel amount
--
-- Forth, we flag this client as been checked. This lets us know that this _clientsInZoneData is actually from a client
-- that is currently in the zone. We check this later.
--
-- CHECK ALL _clientsInZoneData ENTRIES
-- We need to see if any of the _clientsInZoneData entries are not flagged as being checked.  If they are not flagged as
-- being checked then we know that this client was not in one of the zones and we can say that this client is now
-- left the zone and has completely finished refueling.
--
function REFUELING_MONITOR:OnAfterClientInZone(From, Event, To)
    self:T("OnAfterClientInZone called.")

    -- Check to see if any new clients have entered any of the zones.
    if self._clientInZone then

        -- Reset flag to false. If this flag is still false at then end of this function, then we no there are no longer any
        -- clients in any of the zones so we can set the state back to CheckingZones(). If we find a client in one of the zones,
        -- then this flag is set back to true.
        self._ClientInZone = false

        self._zones:ForEachZone(
            function(zone)
                local unitCategory = zone.ZoneUNIT:GetUnitCategory()
                if zone.ZoneUNIT:IsActive() and zone.ZoneUNIT:InAir() and unitCategory == Unit.Category.AIRPLANE then
                    self._clients:ForEachClientInZone(zone,
                        function(clientUnitObject)
                            if clientUnitObject ~= nil and clientUnitObject:GetClientGroupUnit():InAir() then

                                local clientName = clientUnitObject:GetPlayer()
                                self:T(string.format("Checking client: %s in zone: %s.", clientName, zone.ZoneName))

                                local clientCurrentFuel = clientUnitObject:GetClientGroupUnit():GetFuel()

                                -- If _clientsInZoneData for this client doesn't exist yet, initialize it.
                                if self._clientsInZoneData[clientName] == nil then
                                    self._initClientData(self, clientUnitObject, zone)
                                    self._clientsInZoneData[clientName].PrevCheckedAmt = clientCurrentFuel
                                end

                                self:T(string.format("clientCurrentFuel: %s\tprevCheckedAmt: %s", tostring(Round(clientCurrentFuel, 3)), tostring(Round(self._clientsInZoneData[clientName].PrevCheckedAmt, 3))))
                                self:T(string.format("Client is refueling = %s.", tostring(self._clientsInZoneData[clientName].Refueling)))
                                self:T(print_table(self._clientsInZoneData))

                                -- Check to see if the clients fuel is increasing.
                                -- If so, then we are refueling.  Flag this client as refueling, set _clientsInZoneData.InitialFuelAmt, increase the attempts by 1 and
                                -- update _clientsInZoneData.CurrentFuelAmt to check next iteration.
                                -- If not, then we are not refueling.  Flag the client as not refueling and update the _clientsInZoneData.ReceivedFuelAmt.
                                -- Rounding the fuel amount values to 3 decimal place seems to eliminate the slight fluctuation in amounts. Helps to eliminate false positives.
                                if Round(clientCurrentFuel, 3) > Round(self._clientsInZoneData[clientName].PrevCheckedAmt, 3) then
                                    if not self._clientsInZoneData[clientName].Refueling then
                                        self._clientsInZoneData[clientName].Refueling = true
                                        self._clientsInZoneData[clientName].InitialFuelAmt = clientCurrentFuel
                                        self._clientsInZoneData[clientName].RefuelingAttempts = self._clientsInZoneData[clientName].RefuelingAttempts + 1
                                        self:T(string.format("%s started refueling. Attempt %d.", clientName, self._clientsInZoneData[clientName].RefuelingAttempts))
                                        -- trigger.action.outText(string.format("%s started refueling. Attempt %d.", clientName, self._clientsInZoneData[clientName].RefuelingAttempts), 4)
                                    end
                                    self._clientsInZoneData[clientName].CurrentFuelAmt = clientCurrentFuel
                                else
                                    if self._clientsInZoneData[clientName].Refueling then
                                        self:T(clientName .. " stopped refueling.")
                                        -- trigger.action.outText(clientName .. " stopped refueling.", 4)
                                        self._clientsInZoneData[clientName].Refueling = false
                                        self._clientsInZoneData[clientName].ReceivedFuelAmt = self._clientsInZoneData[clientName].ReceivedFuelAmt + (clientCurrentFuel - self._clientsInZoneData[clientName].InitialFuelAmt)
                                    end
                                end

                                self._clientsInZoneData[clientName].PrevCheckedAmt = clientCurrentFuel

                                -- Flag this _clientsInZoneData as being checked which notifues us later that this client is current.
                                self._clientsInZoneData[clientName].Checked = true
                            end

                            -- We are in the client foreach loop so we know there is a client in one of the zones.
                            -- Flag _clientInZone as true.
                            if not self._ClientInZone then
                                self:T("We have found a client in a zone, flagging _clientInZone true.")
                                self._ClientInZone = true
                            end
                        end
                    )
                end
            end
        )

        -- Now that we have gone through all the current clients in the zones, check to see if someone has left
        -- the zone by looking at the _clientsInZoneData.Checked flag.  If Checked is equal to false, means client wasn't in
        -- the last check of all the zones so we can say he has left the zone.
        -- If a client has left a refuel zone, remove their _clientsInZoneData as it is no longer needed and trigger the RefuelingStopMP event
        -- We also need to reset all the _clientsInZoneData.Checked values to false so that when OnAfterClientInZone is called next
        -- time, only those clients that are found next time will set their _clientsInZoneData.Checked value back to true.
        for client, clientData in pairs(self._clientsInZoneData) do
            if not clientData.Checked then
                self:T(string.format("%s has left the refueling zone, calculating total amount received and then deleting their data.", client))
                
                -- Compute the total fuel received in kgs
                local receivedFuelLBS = clientData.TotalFuelAmt * clientData.ReceivedFuelAmt * 2.20462

                -- Send out a fuel report only if the client actually received any fuel.
                if receivedFuelLBS > 0 and clientData.RefuelingAttempts > 0 then
                    local reportingData = {
                        ClientName      = client,
                        AircraftType    = clientData.AircraftType,
                        TankerName      = clientData.TankerName,
                        RefuelingAttempts = clientData.RefuelingAttempts,
                        ReceivedFuelLBS = receivedFuelLBS,
                    }

                    self:Report(reportingData)

                end
                -- Client has left the refueling zone so delete it's _clientsInZoneData entry
                self._clientsInZoneData[client] = nil
            else
                clientData.Checked = false
            end
        end
    end

    -- If there are no more entries in the _clientsInZoneData table, then there are no longer any clients in any of the zones.
    if next(self._clientsInZoneData) == nil then
        self:T("There are no more entries in _clientsInZoneData table, setting _clientInZone false.")
        self._clientInZone = false
    end

    -- If there are still clients in any of the zones, check again in 1 sec. Otherwise, switch state back to CheckingZones.
    if self._clientInZone then
        self:T("The are still client in the zones, calling OnAfterClientInZone again in 3sec.")
        self:__ClientInZone(3)
    else
        self:T("There are no clients in any of the zones, setting state back to CheckingZones.")
        self:__CheckingZones(15)
    end

    return self
end

-- Currently the state is CheckingZones and this checks to see if a client was found in one of the zones.
-- If so, switch the current state to ClientInZone.
-- If not, check zones again in 15 seconds.
function REFUELING_MONITOR:OnAfterCheckingZones(From, Event, To)
    self:T("OnAfterCheckingZones called.")

    if not self._clientInZone then
        local clientFound = false
        self._zones:ForEachZone(
            function(zone)
                self:T(string.format("%s is InAir = %s", zone:GetName(), tostring(zone.ZoneUNIT:InAir())))
                if zone.ZoneUNIT:InAir() then
                    self:T(string.format("Checking zone %s", zone:GetName()))
                    self._clients:ForEachClientInZone(zone,
                        function(client)
                            if client ~= nil then
                                self:T(string.format("Found client %s in zone %s", client:GetPlayer(), zone:GetName()))
                                clientFound = true
                            end
                        end
                    )
                    if clientFound then
                        self:T(string.format("Found a client in %s zone.", zone:GetName()))
                        self._clientInZone = true
                    end
                end
            end
        )
    end

    if self._clientInZone then
        self:T("A client was found in a zone, calling OnAfterClientInZone in 3sec.")
        self:__ClientInZone(3)
    else
        self:T("Still no client found in any zone, calling OnAfterCheckingZones again in 15sec.")
        self:__CheckingZones(15)
    end

    self:T(string.format("Tanker Flush: %s", self._tankers:Flush()))
    self:T(string.format("Zone   Flush: %s", self._zones:Flush()))

    return self
end

-- When a new tanker is added to the _tankers SET_UNIT we need to create a new ZONE
-- and add it to the _zones SET_ZONE
function REFUELING_MONITOR._tankers:OnAfterAdded(From, Event, To, ObjectName, Object)
    self:T("OnAfterAdded called.")
    local zoneName = string.format("%s_refuel_zone", ObjectName)
    ZONE_UNIT:New(zoneName, Object, 1500)
    self:T(string.format("%s found and %s zone created: ", ObjectName, zoneName))

    return self
end

-- This is where we can send out the Hypeman message or trigger an event or ...
function REFUELING_MONITOR:Report(reportingData)
    local client = reportingData.ClientName
    local aircraftType = reportingData.AircraftType
    local tankerName = reportingData.TankerName
    local numberOfAttempts = reportingData.RefuelingAttempts
    local receivedFuelLBS = reportingData.ReceivedFuelLBS

    -- Send out the message to where ever we'd like.
    local msg = string.format("ini\n[%s (%s) received %dlbs of fuel from %s. Attempts: %d]\n", client, aircraftType, receivedFuelLBS, tankerName, numberOfAttempts)
    self:I(msg)
    -- trigger.action.outText(msg, 30)
    -- HypeMan.sendBotMessage(msg)
	dcsbot.sendBotMessage(msg)
end

-- trigger.action.outText("Loading REFUELING_MONITOR", 2)

-- TestRefuelEvent = REFUELING_MONITOR:New({"Shell", "Texaco"})
