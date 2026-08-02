NASG_ATC = NASG_ATC or {}
NASG_ATC_MISSION_MENU = NASG_ATC_MISSION_MENU or {}

---------------------------------------------------------------------------
-- F10 fallback for mission-number flight plan check-in (see
-- NASG_ATC_FlightPlans.lua's CheckInToMission/GetMissionFlightPlan and
-- NASG_ATC_Clearance.lua's check_in_mission voice intent for the primary
-- voice path). Mission numbers are just folder names under
-- Root/<today>/<mission number>/, so the menu lists whatever
-- LoadMissionFlightPlans found at mission start -- one command per mission,
-- no free text needed.
--
-- Per-client entries use MENU_COALITION_COMMAND rather than
-- MENU_GROUP_COMMAND, same reasoning as NASG_ATC_StatusMenu.lua: DCS
-- doesn't reliably show group-scoped menus added dynamically after mission
-- start in multiplayer.
---------------------------------------------------------------------------

NASG_ATC_MISSION_MENU.MenuText = "Select Mission"
NASG_ATC_MISSION_MENU.MessageDurationSeconds = 15
NASG_ATC_MISSION_MENU.RefreshIntervalSeconds = 60
NASG_ATC_MISSION_MENU.ClientMenus = {}

-- Sorted list of mission numbers LoadMissionFlightPlans found under today's
-- folder. Fixed for the life of the mission (flight plans load once at
-- mission start), so this only needs to be computed once, not per rebuild.
function NASG_ATC_MISSION_MENU:GetAvailableMissionNumbers()
    local numbers = {}

    for missionNumber, _ in pairs(NASG_ATC.MissionFlightPlansByNumber or {}) do
        numbers[#numbers + 1] = missionNumber
    end

    table.sort(numbers)
    return numbers
end

function NASG_ATC_MISSION_MENU:SelectMission(client, missionNumber)
    if not client or not client:IsAlive() then
        return
    end

    local atc = NASG_ATC
    local clientKey = atc:GetClientKey(client)
    local session = clientKey and atc.ClientSessions[clientKey]

    if not session then
        MESSAGE:New(
                "Select Mission: contact Ground or Clearance first to start an ATC session, then select your mission.",
                self.MessageDurationSeconds
        ):ToClient(client)
        return
    end

    local ok, missionKey, flightPlan, reason = atc:CheckInToMission(session, client, missionNumber)

    if not ok then
        local text = (reason == "unknown_mission")
                and ("Select Mission: no flight plans on file for mission " .. tostring(missionKey) .. ".")
                or "Select Mission: unable to check in to that mission."

        MESSAGE:New(text, self.MessageDurationSeconds):ToClient(client)
        return
    end

    local text = flightPlan
            and ("Select Mission: checked in to mission " .. tostring(missionKey) .. ", flight plan loaded.")
            or ("Select Mission: checked in to mission " .. tostring(missionKey) .. ", no flight plan on file for your aircraft.")

    MESSAGE:New(text, self.MessageDurationSeconds):ToClient(client)
end

-- Rebuilds the coalition-scoped "Select Mission" submenu from the current
-- active-client roster: removes every previously-built entry, then adds one
-- fresh MENU_COALITION per active BLUE client, with one command per known
-- mission number. Safe to call repeatedly since it always starts clean.
function NASG_ATC_MISSION_MENU:RebuildMenu()
    for _, item in pairs(self.ClientMenus) do
        if item and item.Remove then
            pcall(function() item:Remove() end)
        end
    end

    self.ClientMenus = {}

    local missionNumbers = self:GetAvailableMissionNumbers()

    if #missionNumbers == 0 then
        return
    end

    local clientSet = SET_CLIENT:New()
                                :FilterCoalitions("blue")
                                :FilterActive()
                                :FilterStart()

    clientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local clientName = client:GetName()
            local displayName = client:GetPlayerName() or clientName or "unknown"

            local clientMenu = MENU_COALITION:New(coalition.side.BLUE, displayName, self.RootMenu)

            for _, missionNumber in ipairs(missionNumbers) do
                MENU_COALITION_COMMAND:New(
                        coalition.side.BLUE, "Mission " .. tostring(missionNumber), clientMenu,
                        function()
                            local selected = CLIENT:FindByName(clientName)

                            if selected then
                                NASG_ATC_MISSION_MENU:SelectMission(selected, missionNumber)
                            end
                        end)
            end

            self.ClientMenus[#self.ClientMenus + 1] = clientMenu
        end
    end)

    NASG_ATC:Log(string.format(
            "[NASG_ATC_MissionMenu] RebuildMenu: RootMenu=%s missions=%d",
            tostring(self.RootMenu), #missionNumbers
    ))
end

function NASG_ATC_MISSION_MENU:Start()
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
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventPlayerLeaveUnit(eventData)
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventDead(eventData)
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end

    function self._EventHandler:OnEventCrash(eventData)
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end

    -- Catches clients already alive before this handler existed.
    self._Scanner = SCHEDULER:New(nil, function()
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end, {}, NASG_ATC.Defaults.StartupClientScanDelaySeconds or 5)

    -- Periodic rebuild as a safety net for any roster change this module
    -- doesn't explicitly listen for.
    self._RefreshScheduler = SCHEDULER:New(nil, function()
        NASG_ATC_MISSION_MENU:RebuildMenu()
    end, {}, self.RefreshIntervalSeconds, self.RefreshIntervalSeconds)

    NASG_ATC:Log("NASG_ATC_MissionMenu started")
end

NASG_ATC_MISSION_MENU:Start()
NASG_ATC:Log("NASG_ATC_MissionMenu loaded")
