-- NASG_ATC_Hook.lua
-- DCS hook script that auto-starts the NASG TTS and STT services when a
-- mission finishes loading and stops them cleanly when the simulation ends.
--
-- DEPLOYMENT — copy or symlink this file to:
--   %USERPROFILE%\Saved Games\DCS.openbeta\Scripts\Hooks\NASG_ATC_Hook.lua
--   (or DCS.release / DCS.server depending on your installation)
--
-- The hook calls the existing bat launchers which already handle:
--   • Port / lock-file guard so a second instance is never started.
--   • CPU affinity pinning to avoid fighting DCS for cores.
--   • Stop-file polling so os.remove() is all that is needed to stop.

local io  = require('io')
local lfs = require('lfs')
local net = require('net')

local NASG_ATC_Hook = {}

---------------------------------------------------------------------------
-- Configuration — adjust paths to match the server layout.
---------------------------------------------------------------------------

local SCRIPTS_DIR = "C:\\NASGroup\\NASGroupMissionScripts\\Common\\ATC\\scripts\\"
local TMP_DIR     = "C:\\NASGroup\\NASGroupMissionScripts\\Common\\ATC\\tmp\\"

local TTS_BAT  = SCRIPTS_DIR .. "start_tts_service.bat"
local STT_BAT  = SCRIPTS_DIR .. "start_stt_bridge.bat"
local TTS_STOP = TMP_DIR .. "nasg_tts_service.stop"
local STT_STOP = TMP_DIR .. "nasg_stt_bridge.stop"

---------------------------------------------------------------------------
-- Helpers.
---------------------------------------------------------------------------

local function log(msg)
    net.log("[NASG_ATC_Hook] " .. tostring(msg))
end

-- Write a stop-file that each service polls to trigger a clean exit.
local function writeStopFile(path, label)
    local f = io.open(path, "w")
    if f then
        f:write("stop\n")
        f:close()
        log(label .. " stop file written: " .. path)
    else
        log("WARNING: could not write stop file for " .. label .. ": " .. path)
    end
end

-- Launch a bat file completely hidden (no terminal window).
-- PowerShell's -WindowStyle Hidden suppresses the cmd window that
-- 'start /b' still shows for .bat files.  CreateNoWindow is set on the
-- inner process as well so nothing appears even briefly.
local function launchBat(batPath, label)
    if not lfs.attributes(batPath) then
        log("WARNING: bat not found, skipping " .. label .. ": " .. batPath)
        return
    end
    -- Use PowerShell to launch cmd /c <bat> with no visible window.
    -- -NonInteractive -NoProfile keeps startup fast.
    local cmd = string.format(
        'powershell -NonInteractive -NoProfile -WindowStyle Hidden'
        .. ' -Command "Start-Process cmd -ArgumentList \'/c\',\'%s\''
        .. ' -WindowStyle Hidden -PassThru | Out-Null"',
        batPath)
    log("Starting " .. label .. " (hidden): " .. batPath)
    os.execute(cmd)
end

---------------------------------------------------------------------------
-- DCS hook callbacks.
---------------------------------------------------------------------------

-- Called after the mission has finished loading (scripts, triggers, etc.
-- are all initialised at this point).
function NASG_ATC_Hook.onMissionLoadEnd()
    log("onMissionLoadEnd — launching NASG ATC services.")

    -- Ensure the tmp directory exists.
    if not lfs.attributes(TMP_DIR) then
        lfs.mkdir(TMP_DIR)
        log("Created tmp dir: " .. TMP_DIR)
    end

    -- Remove any leftover stop files from the previous session so the
    -- services don't exit immediately after starting.
    os.remove(TTS_STOP)
    os.remove(STT_STOP)

    -- Launch both services.  The bat files are idempotent — they check
    -- for an already-running instance (port / lock file) and exit cleanly
    -- without starting a second copy.
    launchBat(TTS_BAT, "TTS service")
    launchBat(STT_BAT, "STT bridge")
end

-- Called when the simulation stops (mission end, server restart, or the
-- operator loads a different mission).  Writing the stop files causes
-- both Python services to exit their main loop and terminate cleanly.
function NASG_ATC_Hook.onSimulationStop()
    log("onSimulationStop — sending stop signal to NASG ATC services.")
    writeStopFile(TTS_STOP, "TTS service")
    writeStopFile(STT_STOP, "STT bridge")
end

---------------------------------------------------------------------------
-- Register callbacks with DCS.
---------------------------------------------------------------------------

DCS.setUserCallbacks(NASG_ATC_Hook)
log("NASG_ATC_Hook loaded — services will start on next mission load.")
