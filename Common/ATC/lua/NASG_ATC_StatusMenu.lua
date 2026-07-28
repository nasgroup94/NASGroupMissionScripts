NASG_ATC = NASG_ATC or {}
NASG_ATC_STATUS_MENU = NASG_ATC_STATUS_MENU or {}

---------------------------------------------------------------------------
-- Generic, theater-agnostic F10 "ATC Status" display. Adds a private F10
-- command to every blue client group; the pilot can trigger it any time to
-- see what NASG_ATC currently has on file for their aircraft -- facility/
-- session state, the exact pending-readback instruction (if any), assigned
-- route/procedure legs, and an attached flight plan summary. Read-only:
-- this module never mutates session state, only reads it.
---------------------------------------------------------------------------

NASG_ATC_STATUS_MENU.MenuText = "ATC Status"
NASG_ATC_STATUS_MENU.MessageDurationSeconds = 30

function NASG_ATC_STATUS_MENU:BuildStatusText(client)
    local atc = NASG_ATC
    local clientKey = atc:GetClientKey(client)
    local session = clientKey and atc.ClientSessions[clientKey]

    if not session then
        return "ATC Status: no ATC session on file yet -- contact Ground or Clearance to start one."
    end

    local lines = {}

    local squawkCode = session.Clearance and session.Clearance.SquawkCode
    table.insert(lines, string.format(
            "Facility: %s   State: %s   Squawk: %s",
            tostring(session.Facility or "none"),
            tostring(session.State or "unknown"),
            squawkCode or "not assigned"
    ))

    local pending = session.PendingReadback

    if pending then
        table.insert(lines, string.format(
                "Awaiting readback (%s/%s): %s",
                tostring(pending.Facility or "?"),
                tostring(pending.Type or "?"),
                tostring(pending.InstructionText or "")
        ))
    else
        table.insert(lines, "Awaiting readback: none")
    end

    local route = session.Route

    if route then
        local activeLegIndex = route.ActiveLegIndex or 1
        local legNames = {}

        for i, leg in ipairs(route.Legs or {}) do
            local name = leg.Name or leg.name or ("leg " .. tostring(i))

            if i == activeLegIndex then
                name = name .. " (active)"
            end

            table.insert(legNames, name)
        end

        table.insert(lines, string.format(
                "Route: %s%s",
                route.SpokenClause or "assigned",
                (route.DestinationText and route.DestinationText ~= "")
                        and (", destination " .. tostring(route.DestinationText))
                        or ""
        ))

        if #legNames > 0 then
            table.insert(lines, "  Legs: " .. table.concat(legNames, ", "))
        end
    else
        table.insert(lines, "Route: none assigned")
    end

    local flightPlan = atc:GetSessionFlightPlan(session)

    if flightPlan then
        local departureWaypoint = atc:FindWaypointByRole(flightPlan, "departure")
        local arrivalWaypoint = atc:FindWaypointByRole(flightPlan, "arrival")
        local arrivalAirportId = atc:GetFlightPlanArrivalAirportId(flightPlan)
        local arrivalAirport = arrivalAirportId and atc:GetAirport(arrivalAirportId)

        local departureText = departureWaypoint and atc:GetWaypointName(departureWaypoint) or "unknown"
        local arrivalText = (arrivalAirport and arrivalAirport.Name)
                or (arrivalWaypoint and atc:GetWaypointName(arrivalWaypoint))
                or "unknown"

        local departureAltitudeFt = departureWaypoint and atc:GetWaypointAltitudeFeet(departureWaypoint)
        local arrivalAltitudeFt = arrivalWaypoint and atc:GetWaypointAltitudeFeet(arrivalWaypoint)

        table.insert(lines, string.format("Flight Plan: %s -> %s", departureText, arrivalText))

        if departureAltitudeFt or arrivalAltitudeFt then
            table.insert(lines, string.format(
                    "  Filed altitude: departure %s ft, arrival %s ft",
                    departureAltitudeFt and tostring(math.floor(departureAltitudeFt + 0.5)) or "n/a",
                    arrivalAltitudeFt and tostring(math.floor(arrivalAltitudeFt + 0.5)) or "n/a"
            ))
        end
    else
        table.insert(lines, "Flight Plan: none attached")
    end

    return table.concat(lines, "\n")
end

function NASG_ATC_STATUS_MENU:ShowStatus(client)
    if not client or not client:IsAlive() then
        return
    end

    MESSAGE:New(self:BuildStatusText(client), self.MessageDurationSeconds):ToClient(client)
end

-- MENU_GROUP_COMMAND:New is idempotent per-group-per-path (Moose just
-- rebinds the command function if the path already exists), so this is
-- safe to call repeatedly for the same group without tracking state here.
function NASG_ATC_STATUS_MENU:AddMenuForClient(client)
    if not client then
        return
    end

    local group = client:GetGroup()

    if not group then
        return
    end

    MENU_GROUP_COMMAND:New(group, self.MenuText, nil, function()
        NASG_ATC_STATUS_MENU:ShowStatus(client)
    end)
end

function NASG_ATC_STATUS_MENU:ScanForClients()
    local clientSet = SET_CLIENT:New()
                                :FilterCoalitions("blue")
                                :FilterActive()
                                :FilterStart()

    clientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            NASG_ATC_STATUS_MENU:AddMenuForClient(client)
        end
    end)
end

function NASG_ATC_STATUS_MENU:Start()
    if self._EventHandler then
        return
    end

    self._EventHandler = EVENTHANDLER:New()
    self._EventHandler:HandleEvent(EVENTS.Birth)

    function self._EventHandler:OnEventBirth(eventData)
        local client = NASG_ATC:GetClientFromEvent(eventData)

        if client then
            NASG_ATC_STATUS_MENU:AddMenuForClient(client)
        end
    end

    -- Catches clients already alive before this handler existed, same
    -- one-shot-after-start pattern as NASG_ATC:Start's own Scanner.
    self._Scanner = SCHEDULER:New(nil, function()
        NASG_ATC_STATUS_MENU:ScanForClients()
    end, {}, NASG_ATC.Defaults.StartupClientScanDelaySeconds or 5)

    NASG_ATC:Log("NASG_ATC_StatusMenu started")
end

NASG_ATC_STATUS_MENU:Start()
NASG_ATC:Log("NASG_ATC_StatusMenu loaded")
