---------------------------------------------------------------------------
-- Shared ATC bootstrapper. This file is theater/map-agnostic by design —
-- it must be able to run unmodified for any mission. It contains NO
-- theater-specific defaults for MissionScriptsPath/MissionATCAirports/
-- MissionATCConfig/MissionATCTrackedPoints/MissionATCProcedures; those are
-- required to already be set (by a theater's own ATC script loader, e.g.
-- CVW-17/Persian Gulf/NATO/Persian_Gulf_ATC_ScriptLoader.lua or CVW-17/
-- Nellis/NATO/Nellis_ATC_ScriptLoader.lua) before this file loads. A
-- mission's top-level script loader should call its theater's ATC script
-- loader instead of this file directly.
---------------------------------------------------------------------------

NASG_ATC_SCRIPT_LOADER = NASG_ATC_SCRIPT_LOADER or {}

NASG_ATC_SCRIPT_LOADER.CommonScriptsPath = NASG_ATC_SCRIPT_LOADER.CommonScriptsPath
        or "C:/NASGroup/NASGroupMissionScripts/Common/"

NASG_ATC_SCRIPT_LOADER.ATCPath = NASG_ATC_SCRIPT_LOADER.ATCPath
        or NASG_ATC_SCRIPT_LOADER.CommonScriptsPath .. "ATC/"

NASG_ATC_SCRIPT_LOADER.ATCLuaPath = NASG_ATC_SCRIPT_LOADER.ATCPath .. "lua/"

function NASG_ATC_SCRIPT_LOADER:LoadScript(path)
    assert(loadfile(path))()
end

function NASG_ATC_SCRIPT_LOADER:Load()
    assert(self.MissionScriptsPath, "NASG_ATC_SCRIPT_LOADER.MissionScriptsPath not set -- load a theater ATC script loader (e.g. Persian_Gulf_ATC_ScriptLoader.lua or Nellis_ATC_ScriptLoader.lua) before Common/ATC/scripts/ATCScriptLoader.lua")
    assert(self.MissionATCAirports, "NASG_ATC_SCRIPT_LOADER.MissionATCAirports not set -- see MissionScriptsPath note above")
    assert(self.MissionATCConfig, "NASG_ATC_SCRIPT_LOADER.MissionATCConfig not set -- see MissionScriptsPath note above")
    assert(self.MissionATCTrackedPoints, "NASG_ATC_SCRIPT_LOADER.MissionATCTrackedPoints not set -- see MissionScriptsPath note above")
    assert(self.MissionATCProcedures, "NASG_ATC_SCRIPT_LOADER.MissionATCProcedures not set -- see MissionScriptsPath note above")

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
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Tacan.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_TrackedPoints.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Procedures.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Ground.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Tower.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Center.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_AWACS.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_Clearance.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_StatusMenu.lua")

    -- Mission-specific airport/controller configuration.
    -- Database (structural defs) first, then the comms/mission layer that
    -- activates and tunes them.
    self:LoadScript(self.MissionATCAirports)
    self:LoadScript(self.MissionATCConfig)
    self:LoadScript(self.MissionATCTrackedPoints)
    self:LoadScript(self.MissionATCProcedures)

    -- Bridges after config so they can discover registered airports/frequencies.
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_TTSBridge.lua")
    self:LoadScript(self.ATCLuaPath .. "NASG_ATC_STTBridge.lua")

    NASG_ATC:Start()
end
NASG_ATC_SCRIPT_LOADER:Load()