NASG_ATC_SCRIPT_LOADER = NASG_ATC_SCRIPT_LOADER or {}

NASG_ATC_SCRIPT_LOADER.CommonScriptsPath = NASG_ATC_SCRIPT_LOADER.CommonScriptsPath
        or "C:/NASGroup/NASGroupMissionScripts/Common/"

NASG_ATC_SCRIPT_LOADER.ATCPath = NASG_ATC_SCRIPT_LOADER.ATCPath
        or NASG_ATC_SCRIPT_LOADER.CommonScriptsPath .. "ATC/"

NASG_ATC_SCRIPT_LOADER.ATCLuaPath = NASG_ATC_SCRIPT_LOADER.ATCPath .. "lua/"
NASG_ATC_SCRIPT_LOADER.MissionScriptsPath = NASG_ATC_SCRIPT_LOADER.MissionScriptsPath
        or "C:/NASGroup/NASGroupMissionScripts/CVW-17/Persian Gulf/"

-- Structural airport database (all map airports). Loaded before the comms
-- config so ActivateAirport can find each airport's definition.
NASG_ATC_SCRIPT_LOADER.MissionATCAirports = NASG_ATC_SCRIPT_LOADER.MissionATCAirports
        or NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_Airports.lua"

NASG_ATC_SCRIPT_LOADER.MissionATCConfig = NASG_ATC_SCRIPT_LOADER.MissionATCConfig
        or NASG_ATC_SCRIPT_LOADER.MissionScriptsPath .. "NATO/Persian_Gulf_ATC_Config.lua"

function NASG_ATC_SCRIPT_LOADER:LoadScript(path)
    assert(loadfile(path))()
end

function NASG_ATC_SCRIPT_LOADER:Load()
    package.path = self.ATCLuaPath .. "?.lua;" .. package.path

    -- SRS/TTS support used by ATC voice output.
    if not SRS_PYTHON_WEBSOCKET_LOADED then
        self:LoadScript(self.ATCLuaPath .. "SRS_PythonWebSocket.lua")
    end

    if not NASG_TTS then
        self:LoadScript(self.ATCLuaPath .. "tts_init.lua")
    end

    self:LoadScript(self.ATCLuaPath .. "NASG_RadioSpeech.lua")

    -- NASG ATC core/controllers.
    if not NASG_ATC or not NASG_ATC.CoreLoaded then
        self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Core.lua")
    end

    -- Dynamic taxi routing engine (used by Core/Ground when an airport
    -- defines a TaxiGraph; otherwise inert).
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_TaxiGraph.lua")

    NASG_ATC.FlightPlanFile = NASG_ATC_FLIGHT_PLAN_FILE or NASG_ATC.FlightPlanFile
    NASG_ATC.FlightPlanRootFolder = NASG_ATC_FLIGHT_PLAN_ROOT_FOLDER or NASG_ATC.FlightPlanRootFolder
    NASG_ATC.FlightPlanDayFormat = NASG_ATC_FLIGHT_PLAN_DAY_FORMAT or NASG_ATC.FlightPlanDayFormat
    NASG_ATC.DTCFlightPlanEnabled = NASG_ATC_DTC_FLIGHT_PLAN_ENABLED
    if NASG_ATC.DTCFlightPlanEnabled == nil then
        NASG_ATC.DTCFlightPlanEnabled = true
    end

    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_FlightPlans.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Navigation.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Ground.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Tower.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Center.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_AWACS.lua")

    -- Mission-specific airport/controller configuration.
    -- Database (structural defs) first, then the comms/mission layer that
    -- activates and tunes them.
    self:LoadScript(self.MissionATCAirports)
    self:LoadScript(self.MissionATCConfig)

    -- Bridges after config so they can discover registered airports/frequencies.
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_TTSBridge.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_STTBridge.lua")

    NASG_ATC:Start()
end
NASG_ATC_SCRIPT_LOADER:Load()