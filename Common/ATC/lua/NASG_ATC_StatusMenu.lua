NASG_ATC = NASG_ATC or {}
NASG_ATC_STATUS_MENU = NASG_ATC_STATUS_MENU or {}

---------------------------------------------------------------------------
-- Generic, theater-agnostic F10 "ATC Status" display. Adds one coalition
-- menu entry per active BLUE client under "ATC Status"; the pilot can
-- trigger it any time to see what NASG_ATC currently has on file for their
-- aircraft -- facility/session state, the exact pending-readback
-- instruction (if any), assigned route/procedure legs, and an attached
-- flight plan summary. Read-only: this module never mutates session state,
-- only reads it.
--
-- Per-client entries use MENU_COALITION_COMMAND rather than
-- MENU_GROUP_COMMAND: DCS has a long-standing multiplayer bug where
-- group-scoped menus added dynamically after mission start don't reliably
-- display for client slots (MOOSE's own MENU_GROUP doc comment notes this).
-- The AAPVE range menus avoid it the same way -- one coalition-scoped entry
-- per client, rebuilt whenever the client roster changes.
---------------------------------------------------------------------------

NASG_ATC_STATUS_MENU.MenuText = "ATC Status"
NASG_ATC_STATUS_MENU.MessageDurationSeconds = 30
NASG_ATC_STATUS_MENU.RefreshIntervalSeconds = 60
NASG_ATC_STATUS_MENU.ClientMenus = {}

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

-- F10 fallback for Feature 1 (callsign alias): menus can't accept free-text
-- input, so this can only ever clear an alias, never set one -- setting an
-- arbitrary alias remains voice-only ("set callsign as ...").
function NASG_ATC_STATUS_MENU:ClearCallsignAlias(client)
    if not client or not client:IsAlive() then
        return
    end

    local atc = NASG_ATC
    local clientKey = atc:GetClientKey(client)
    local session = clientKey and atc.ClientSessions[clientKey]

    if not session or not session.CallsignAlias then
        MESSAGE:New("ATC Status: no callsign alias is currently set.", self.MessageDurationSeconds):ToClient(client)
        return
    end

    session.CallsignAlias = nil
    session.FlightPlanId = nil
    session.ActiveSequenceName = nil
    session.ActiveLegIndex = nil

    atc:RefreshPackageMembership(session, client)

    MESSAGE:New("ATC Status: callsign alias cleared.", self.MessageDurationSeconds):ToClient(client)
end

-- Rebuilds the coalition-scoped "ATC Status" submenu from the current
-- active-client roster: removes every previously-built entry, then adds
-- one fresh MENU_COALITION_COMMAND per active BLUE client. Safe to call
-- repeatedly (on Birth/leave/death events and on a timer) since it always
-- starts from a clean slate.
function NASG_ATC_STATUS_MENU:RebuildMenu()
    for _, item in pairs(self.ClientMenus) do
        if item and item.Remove then
            pcall(function() item:Remove() end)
        end
    end

    self.ClientMenus = {}

    local clientSet = SET_CLIENT:New()
                                :FilterCoalitions("blue")
                                :FilterActive()
                                :FilterStart()

    local clientNames = {}

    clientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local clientName = client:GetName()
            local displayName = client:GetPlayerName() or clientName or "unknown"

            table.insert(clientNames, displayName)

            local clientMenu = MENU_COALITION:New(coalition.side.BLUE, displayName, self.RootMenu)

            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE, "Show Status", clientMenu,
                    function()
                        local selected = CLIENT:FindByName(clientName)

                        if selected then
                            NASG_ATC_STATUS_MENU:ShowStatus(selected)
                        end
                    end)

            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE, "Clear Callsign Alias", clientMenu,
                    function()
                        local selected = CLIENT:FindByName(clientName)

                        if selected then
                            NASG_ATC_STATUS_MENU:ClearCallsignAlias(selected)
                        end
                    end)

            self.ClientMenus[#self.ClientMenus + 1] = clientMenu
        end
    end)

    NASG_ATC:Log(string.format(
            "[NASG_ATC_StatusMenu] RebuildMenu: RootMenu=%s clients=%d (%s)",
            tostring(self.RootMenu), #clientNames, table.concat(clientNames, ", ")
    ))
end

function NASG_ATC_STATUS_MENU:Start()
    if self._EventHandler then
        return
    end

    self.RootMenu = MENU_COALITION:New(coalition.side.BLUE, self.MenuText)

    self._EventHandler = EVENTHANDLER:New()
    self._EventHandler:HandleEvent(EVENTS.Birth)
    self._EventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)
    self._EventHandler:HandleEvent(EVENTS.Dead)
    self._EventHandler:HandleEvent(EVENTS.Crash)

    function self._EventHandler:OnEventBirth(eventData)
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventPlayerLeaveUnit(eventData)
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventDead(eventData)
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventCrash(eventData)
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end

    -- Catches clients already alive before this handler existed.
    self._Scanner = SCHEDULER:New(nil, function()
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end, {}, NASG_ATC.Defaults.StartupClientScanDelaySeconds or 5)

    -- Periodic rebuild as a safety net for any roster change this module
    -- doesn't explicitly listen for.
    self._RefreshScheduler = SCHEDULER:New(nil, function()
        NASG_ATC_STATUS_MENU:RebuildMenu()
    end, {}, self.RefreshIntervalSeconds, self.RefreshIntervalSeconds)

    NASG_ATC:Log("NASG_ATC_StatusMenu started")
end

NASG_ATC_STATUS_MENU:Start()
NASG_ATC:Log("NASG_ATC_StatusMenu loaded")
