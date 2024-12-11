-----------------------------------------------------------
-- vv For use with DCSServerBot VNAO and Funkman Plugins vv --
--------------------------------------------------------------
-- Must have DCSServerBot and scripts loaded on server.
-- Must have flightlog.lua loaded in the mission.
-- Do not use SetFunkmanOn() in the airboss set up, a delay
-- is needed before the LSO grade is sent. This gives the 
-- flightlog entry time to be closed..
-- 
-------------------------------------------------------------
package.path  = package.path .. ';.\\LuaSocket\\?.lua;'
package.cpath = package.cpath .. ';.\\LuaSocket\\?.dll;'
local socket = require("socket")

package.path  = package.path ..  ";.\\Scripts\\?.lua"
local json = require("json")

local function getDCSUcidFromName(name_to_check)
    local flID = nil
    local player_list = net.get_player_list()

    for _, id in pairs(player_list) do
        local player = net.get_player_info(id)
        if player.name == name_to_check then
            flID = player.ucid
        end
    end

    return flID
end

local function sendLSOResultToFunkman(result)
    -- Host and Port of the listening DCSServerBot node.
    net.log("ROLLN", log.INFO, "Sending LSO grade to funkman.")
    net.log("ROLLN", log.INFO, "dcsbot host: "..DCSServerBotConfig.BOT_HOST.." port: "..DCSServerBotConfig.BOT_PORT)
    local dcsServerBotSocket = socket.udp()
    dcsServerBotSocket:settimeout(0)
    dcsServerBotSocket:sendto(json:encode(result), DCSServerBotConfig.BOT_HOST, DCSServerBotConfig.BOT_PORT)
end

-- This function is mainly copied from AIRBOSS:onafterLSOGrade
local function prepLSOResultForFunkman(airboss, playerData, grade)
    net.log("ROLLN", log.INFO, "Prepping LSO result to send to funkman")

    -- Extract used info for FunkMan. We need to be careful with the amount of data send via UDP socket.
    local trapsheet={} ; trapsheet.X={} ; trapsheet.Z={} ; trapsheet.AoA={} ; trapsheet.Alt={}

    -- Loop over trapsheet and extract used values.
    for i = 1, #playerData.trapsheet do
    local ts=playerData.trapsheet[i] --#AIRBOSS.GrooveData
    table.insert(trapsheet.X, UTILS.Round(ts.X, 1))
    table.insert(trapsheet.Z, UTILS.Round(ts.Z, 1))
    table.insert(trapsheet.AoA, UTILS.Round(ts.AoA, 2))
    table.insert(trapsheet.Alt, UTILS.Round(ts.Alt, 1))
    end

    local result={}
    result.command=SOCKET.DataType.LSOGRADE
    result.name=playerData.name
    result.trapsheet=trapsheet
    result.airframe=grade.airframe
    result.mitime=grade.mitime
    result.midate=grade.midate
    result.wind=grade.wind
    result.carriertype=grade.carriertype
    result.carriername=grade.carriername
    result.carrierrwy=grade.carrierrwy
    result.landingdist=airboss.carrierparam.landingdist
    result.theatre=grade.theatre
    result.case=playerData.case
    result.Tgroove=grade.Tgroove
    result.wire=grade.wire
    result.grade=grade.grade
    result.points=grade.points
    result.details=grade.details

    -- Add the server name and player's current flightlogid to the result table becuase this is 
    -- needed for VNAO and Funkman plugins to work correctly
    -- flightlog id comes from flightlog.lua's global PilotFlightRecord table
    local player_ucid = getDCSUcidFromName(result.name)

    result.server_name = cfg.name
    result.flightlogID = PilotFlightRecord[player_ucid].flightlog.id
    net.log("ROLLN", log.INFO, "Server name: ".. result.server_name.."  flightlogID: "..result.flightlogID)
    net.log("ROLLN", log.INFO, "Starting lsoSend timer.")

    -- Delay sending to funkman for 20s to allow flightlog.lua to close the flight log.
    TIMER:New(sendLSOResultToFunkman,result):Start(20)
    
end
--------------------------------------------------------------
-- ^^ For use with DCSServerBot VNAO and Funkman Plugins ^^ --
--------------------------------------------------------------



-------------------------
-- Refueling_Monitor --
-------------------------
-- Refueling_Monitor = REFUELING_MONITOR:New({"Shell", "Texaco", "Arco"})
-- Refueling_Monitor = REFUELING_MONITOR:New({ "Refueling", "Tanker", "Shell", "Texaco", "Arco", "ARCO", "ARCO3", "ARS909", "ARS909MPRS" })


-------------------------
-- AIRBOSS --
-------------------------

-- Set mission menu.
AIRBOSS.MenuF10Root = MENU_MISSION:New("Airboss").MenuPath

-- No MOOSE settings menu.
_SETTINGS:SetPlayerMenuOff()
_SETTINGS:SetA2G_MGRS()
_SETTINGS:SetA2A_BRAA()
_SETTINGS:SetImperial()

BLUE_CLIENT_SET = SET_CLIENT:New():FilterActive():FilterCoalitions("blue"):FilterStart()
BLUE_CLIENT_SET:HandleEvent(EVENTS.PlayerEnterAircraft)

RED_CLIENT_SET = SET_CLIENT:New():FilterActive():FilterCoalitions("red"):FilterStart()
RED_CLIENT_SET:HandleEvent(EVENTS.PlayerEnterAircraft)

--------------------------------------------- CVN73 -------------------------------------------------------
-- S3
RecoveryTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN-71 Rough Rider"), "CVN71_ARCO1")
RecoveryTanker:SetTakeoffAir()
RecoveryTanker:SetRadio(261)
RecoveryTanker:SetAltitude(MISSION_TANKER_ALTS.Recovery)
RecoveryTanker:SetModex(703)
RecoveryTanker:SetCallsign(CALLSIGN.Tanker.Arco, 1)
RecoveryTanker:SetTACAN(61, "AR1")
RecoveryTanker:__Start(60)

HighTanker = RECOVERYTANKER:New(UNIT:FindByName("CVN-71 Rough Rider"), "CVN71_ARCO2")
HighTanker:SetTakeoffAir()
HighTanker:SetRadio(262)
HighTanker:SetAltitude(MISSION_TANKER_ALTS.Offgoing)
HighTanker:SetRacetrackDistances(25, 8)
HighTanker:SetModex(611)
HighTanker:SetCallsign(CALLSIGN.Tanker.Arco, 2)
HighTanker:SetTACAN(62, "AR2")
HighTanker:SetSpeed(350)
HighTanker:Start()

RescueHelo = RESCUEHELO:New(UNIT:FindByName("CVN-71 Rough Rider"), "CVN71_RescueHelo")
RescueHelo:SetTakeoffCold()
RescueHelo:SetHomeBase("CVN-71 Rough Rider")
RescueHelo:SetRespawnInAir()
RescueHelo:SetRescueDuration(1)
RescueHelo:SetRescueHoverSpeed(5)
RescueHelo:SetRescueZone(15)
RescueHelo:SetModex(42)
RescueHelo:Start(30)


--[[ Using the new MSRS extended RESCUEHELO class.
-- rescuehelo=RESCUEHELOMSRS:New(UNIT:FindByName("CVN73"), "Rescue Helo", SRSSETTINGS.GoogleVoice.Female.en_AU_Wavenet_C, {265}, {243, 264, 265}, {0}, {0, 0, 0},2)
-- rescuehelo:SetHomeBase(AIRBASE:FindByName("USS Ticonderoga"))
-- rescuehelo:SetTakeoffAir()
rescuehelo:SetTakeoffCold()
rescuehelo:SetRespawnInAir()
rescuehelo:SetRescueDuration(1)
rescuehelo:SetRescueHoverSpeed(5)
rescuehelo:SetRescueZone(15)
rescuehelo:SetModex(42)
rescuehelo:Start(30)
--]]

Awacs = RECOVERYTANKER:New("CVN-71 Rough Rider", "CVN71_FOCUS")
Awacs:SetAWACS()
Awacs:SetTakeoffCold()
Awacs:SetRadio(269)
Awacs:SetAltitude(25000)
Awacs:SetCallsign(CALLSIGN.AWACS.Wizard, 6)
Awacs:SetRacetrackDistances(30, 15)
Awacs:SetModex(611)
Awacs:SetTACAN(69, "WZ6")
Awacs:__Start(150)

Teddy = AIRBOSS:New("CVN-71 Rough Rider", "CVN-71 Rough Rider")

function Teddy:OnAfterStart(From, Event, To)
    self:DeleteAllRecoveryWindows()

    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), 1)
end

function Teddy:OnAfterPassingWaypoint(From, Event, To, n)
    -- Recording waypoint to be used in the persistence script
    -- PassingWaypoint(self.carrier:GetName(), n)
end

function Teddy:OnAfterLSOGrade(From, Event, To, playerData, grade)
    -- Make sure to pass self
    prepLSOResultForFunkman(self, playerData, grade) -- Note: you must send the `self` parameter.
end


-- LoneWarrior:SetFunkManOn(10042, "127.0.0.1")
Teddy:SetMenuRecovery(60, 27, false, 0) --Curcuit changed to prevent boat from circling
Teddy:SetAutoSave(TRAPSHEETLOCATION)
Teddy:SetTrapSheet(TRAPSHEETLOCATION)
Teddy:Load()
Teddy:SetTACAN(71, "X", "TDR")
Teddy:SetICLS(11, "TDR")
Teddy:SetLSORadio(305)
Teddy:SetMarshalRadio(264)
Teddy:SetPatrolAdInfinitum()
Teddy:SetAirbossNiceGuy()
Teddy:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
Teddy:SetMaxSectionSize(4)
Teddy:SetMPWireCorrection(12)
Teddy:SetRadioRelayLSO("CVN71_LSORELAY")
Teddy:SetRadioRelayMarshal("CVN71_MARSHALRELAY")
Teddy:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
Teddy:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
Teddy:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
Teddy:SetDespawnOnEngineShutdown()
Teddy:SetRecoveryTanker(RecoveryTanker)
Teddy:SetMenuSingleCarrier()
Teddy:SetHandleAIOFF()
-- LoneWarrior:SetIntoWindLegacy( SwitchOn )  -- uncomment this to use old turn into wind calculation
-- LoneWarrior.trapsheet = false

function Teddy:OnAfterRecoveryStart(Event, From, To, Case, Offset)
    env.info(string.format("Starting Recovery Case %d ops.", Case))

    MSRS:New(SRS_PATH, 305, radio.modulation.AM, MSRS.Backend.SRSEXE)
        :SetCoordinate(self:GetCoord())
        :SetProvider(MSRS.Provider.WINDOWS)
        :PlaySoundFile(SOUNDFILE:New("BossRecoverAircraft.ogg", COMMONSOUNDSFOLDER, 9, true), 10)
end

-- Start airboss class.
Teddy:Start()

-- LoneWarrior lighting flag values
-- 0 - AUTO
-- 1 - NAVIGATION
-- 2 - LAUNCH
-- 3 - RECOVERY
TeddyLighting = USERFLAG:New("750")
-- TarawaLighting = USERFLAG:New("751")
ShipLightingHandler = EVENTHANDLER:New()
ShipLightingHandler:HandleEvent(EVENTS.Birth)
function ShipLightingHandler:OnEventBirth(EventData)
    -- Nil checks.
    if EventData == nil then
        self:E(self.lid .. "ERROR: EventData=nil in event BIRTH!")
        self:E(EventData)
        return
    end
    if EventData.IniUnit == nil then
        self:E(self.lid .. "ERROR: EventData.IniUnit=nil in event BIRTH!")
        self:E(EventData)
        return
    end

    if EventData.IniObjectCategory ~= Object.Category.UNIT then return end

    local _gid = EventData.IniGroup:GetID()
    local _playerUCID = EventData.IniPlayerUCID

    if _gid and _playerUCID then
        -- env.info("-------------Lone Warrior client birth group id: " .. _gid)
        if _gid then
            -- env.info("-------------Should be creating Carrier Lighting menu")
            -- local _shipLighting = missionCommands.addSubMenuForGroup(_gid, "Ship Lighting")
            -- local _menuCarrierLighting = missionCommands.addSubMenuForGroup(_gid, "Carrier Lighting", _shipLighting)
            local _menuCarrierLighting = missionCommands.addSubMenuForGroup(_gid, "Carrier Lighting")
            missionCommands.addCommandForGroup(_gid, "Auto", _menuCarrierLighting, function()
                TeddyLighting:Set("0")
            end)
            missionCommands.addCommandForGroup(_gid, "Navigation", _menuCarrierLighting, function()
                TeddyLighting:Set("1")
            end)
            missionCommands.addCommandForGroup(_gid, "Launch", _menuCarrierLighting, function()
                TeddyLighting:Set("2")
            end)
            missionCommands.addCommandForGroup(_gid, "Recovery", _menuCarrierLighting, function()
                TeddyLighting:Set("3")
            end)

            -- Tarawa: Cannot change lighting yet, as of DCS 2.9.1
            -- env.info("-------------Should be creating Tarawa Lighting menu", _shipLighting)
            -- local _menuCarrierLighting = missionCommands.addSubMenuForGroup(_gid, "Tarawa Lighting", _shipLighting)
            -- missionCommands.addCommandForGroup(_gid, "Auto", _menuCarrierLighting, function()
            --     TarawaLighting:Set("0")
            -- end)
            -- missionCommands.addCommandForGroup(_gid, "Navigation", _menuCarrierLighting, function()
            --     TarawaLighting:Set("1")
            -- end)
            -- missionCommands.addCommandForGroup(_gid, "Launch", _menuCarrierLighting, function()
            --     TarawaLighting:Set("2")
            -- end)
            -- missionCommands.addCommandForGroup(_gid, "Recovery", _menuCarrierLighting, function()
            --     TarawaLighting:Set("3")
            -- end)
        end
    end
end

-- ------------------------------------------------ TARAWA ----------------------------------------------
-- EXPD11_RESCUEHELO = RESCUEHELO:New(UNIT:FindByName("Tarawa"), "EXPD11_RESCUEHELO")
-- EXPD11_RESCUEHELO:SetTakeoffCold()
-- EXPD11_RESCUEHELO:SetRespawnInAir()
-- EXPD11_RESCUEHELO:SetRescueDuration(1)
-- EXPD11_RESCUEHELO:SetRescueHoverSpeed(5)
-- EXPD11_RESCUEHELO:SetRescueZone(15)
-- EXPD11_RESCUEHELO:SetModex(100)
-- EXPD11_RESCUEHELO:Start(30)

-- -- Create AIRBOSS object.
-- Tarawa = AIRBOSS:New("Tarawa", "LHA-1 Tarawa")

-- -- Delete auto recovery window.
-- function Tarawa:OnAfterStart(From, Event, To)
--     self:DeleteAllRecoveryWindows()

--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), 1)
-- end

-- function Tarawa:OnAfterPassingWaypoint(From, Event, To, n)
--     -- Recording waypoint to be used in the persistence script
--     -- PassingWaypoint(self.carrier:GetName(), n)
-- end

-- function Tarawa:OnAfterLSOGrade(From, Event, To, playerData, grade)
--     -- Make sure to pass self
--     prepLSOResultForFunkman(self, playerData, grade) -- Note: Must send `self` parameter
-- end

-- -- Tarawa:SetFunkManOn(10042, "127.0.0.1")
-- Tarawa:SetTACAN(108, "X", "LHA")
-- Tarawa:SetICLS(18)
-- Tarawa:SetAutoSave(TRAPSHEETLOCATION)
-- Tarawa:SetTrapSheet(TRAPSHEETLOCATION)
-- Tarawa:Load()
-- Tarawa:SetLineupErrorThresholds(.5, -.5, -1, -2, -4, 1, 2, 4)
-- Tarawa:SetStatusUpdateTime(1)
-- Tarawa:SetRadioUnitName("EXPD11_RADIORELAY")
-- Tarawa:SetMarshalRadio(306)
-- Tarawa:SetLSORadio(306)
-- Tarawa:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
-- Tarawa:SetSoundfilesFolder(AIRBOSSBASESOUNDFOLDER)
-- Tarawa:SetVoiceOversLSOByRaynor(AIRBOSSLSORAYNOR)
-- Tarawa:SetVoiceOversMarshalByGabriella(AIRBOSSMARSHALGABRIELLA)
-- Tarawa:SetDespawnOnEngineShutdown()
-- Tarawa:SetMenuSingleCarrier()
-- Tarawa:SetMenuRecovery(60, 20, false,0)
-- Tarawa:SetHandleAION()
-- Tarawa.trapsheet = false

-- Tarawa:Start()


-- HeliAirbossMenus = AIRBOSS_HELI:New({ LoneWarrior, Tarawa })


--#region Kuznetsov
-- KUZNETSOV = AIRBOSS:New("CV1143", "CV 1143 Kuznetsov")

-- function KUZNETSOV:OnAfterStart(From, Event, To)
-- 	self:DeleteAllRecoveryWindows()

-- 	-- Recording waypoint to be used in the persistence script
-- 	PassingWaypoint(self.carrier:GetName(), 1)
-- end

-- function KUZNETSOV:OnAfterPassingWaypoint(From, Event, To, n)
-- 	-- Recording waypoint to be used in the persistence script
--     PassingWaypoint(self.carrier:GetName(), n)
-- end

-- KUZNETSOV:SetMenuRecovery(60, 27, true, 0)
-- -- KUZNETSOV:Load()
-- -- KUZNETSOV:SetAutoSave()
-- KUZNETSOV:SetTACAN(34, "X", "KUZ")
-- KUZNETSOV:SetICLS(13, "KUZ")
-- KUZNETSOV:SetLSORadio(221, AM)
-- KUZNETSOV:SetMarshalRadio(222, AM)
-- KUZNETSOV:SetPatrolAdInfinitum()
-- KUZNETSOV:SetAirbossNiceGuy()
-- KUZNETSOV:SetDefaultPlayerSkill(AIRBOSS.Difficulty.NORMAL)
-- KUZNETSOV:SetMaxSectionSize(4)
-- -- KUZNETSOV:SetMPWireCorrection(12)
-- -- KUZNETSOV:SetRadioRelayLSO("CV1143_LSORELAY")
-- -- KUZNETSOV:SetRadioRelayMarshal("CV1143_MARSHALRELAY")
-- KUZNETSOV:SetSoundfilesFolder("Airboss Soundfiles/")
-- KUZNETSOV:SetDespawnOnEngineShutdown()
-- -- KUZNETSOV:SetRecoveryTanker(tanker)
-- KUZNETSOV:SetMenuSingleCarrier(False)
-- KUZNETSOV:SetHandleAION()
-- -- KUZNETSOV.trapsheet = false

-- KUZNETSOV:Start()
--#endregion
