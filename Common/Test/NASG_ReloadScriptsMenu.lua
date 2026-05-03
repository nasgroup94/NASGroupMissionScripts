--- NAS Reload Scripts Menu
-- Adds F10 Other menu commands to reload mission scripts from disk.
--
-- Load this file after MOOSE is loaded.
--
-- Requirements:
--   - MissionScripting.lua must allow file loading.
--   - Script paths must be real filesystem paths, not paths inside the .miz.
--   - Any scripts being reloaded should be safe to execute more than once.

NAS_SCRIPT_RELOADER = NAS_SCRIPT_RELOADER or {}

NAS_SCRIPT_RELOADER.MenuRootName = "NAS Admin"
NAS_SCRIPT_RELOADER.ReloadCommandName = "Reload Mission Scripts"
NAS_SCRIPT_RELOADER.ConfirmCommandName = "CONFIRM Reload Mission Scripts"

--- Scripts to reload, in load order.
-- Update these paths for your server / local machine.
NAS_SCRIPT_RELOADER.ScriptFiles = NAS_SCRIPT_RELOADER.ScriptFiles or {
    -- MOOSE first if you really want to reload the framework.
    -- Usually safer to leave Moose.lua alone and reload only your mission layer.
    -- "C:\\Path\\To\\Moose.lua",

    "C:\\Path\\To\\NASGroupMissionScripts\\SRS_PythonWebSocket.lua",
    "C:\\Path\\To\\NASGroupMissionScripts\\ATIS_PythonWebSocket.lua",
    "C:\\Path\\To\\NASGroupMissionScripts\\MissionMain.lua",
}

--- Optional cleanup hooks called before scripts are reloaded.
-- Add functions here from your mission code if they need explicit shutdown.
NAS_SCRIPT_RELOADER.CleanupHooks = NAS_SCRIPT_RELOADER.CleanupHooks or {}

function NAS_SCRIPT_RELOADER:AddCleanupHook(Name, Func)
    if type(Func) ~= "function" then
        env.info(string.format("[NAS_SCRIPT_RELOADER] Cleanup hook %s ignored: not a function", tostring(Name)))
        return
    end

    table.insert(self.CleanupHooks, {
        Name = Name or "UnnamedCleanupHook",
        Func = Func,
    })
end

function NAS_SCRIPT_RELOADER:_Log(Text)
    env.info("[NAS_SCRIPT_RELOADER] " .. tostring(Text))
end

function NAS_SCRIPT_RELOADER:_Message(Text, Duration)
    self:_Log(Text)

    if MESSAGE then
        MESSAGE:New(tostring(Text), Duration or 10, "NAS Reload", true):ToAll()
    else
        trigger.action.outText(tostring(Text), Duration or 10)
    end
end

function NAS_SCRIPT_RELOADER:_RunCleanupHooks()
    self:_Log("Running cleanup hooks.")

    for _, Hook in ipairs(self.CleanupHooks or {}) do
        self:_Log("Running cleanup hook: " .. tostring(Hook.Name))

        local ok, err = pcall(Hook.Func)

        if not ok then
            self:_Log("Cleanup hook failed: " .. tostring(Hook.Name) .. " | " .. tostring(err))
        end
    end
end

function NAS_SCRIPT_RELOADER:_StopKnownSchedulers()
    self:_Log("Attempting to stop known schedulers/timers.")

    -- Mission-specific objects can be stopped here if you expose them.
    -- Examples:
    --
    -- if atis and atis.Stop then
    --   pcall(function() atis:Stop() end)
    -- end
    --
    -- if airboss and airboss.Stop then
    --   pcall(function() airboss:Stop() end)
    -- end

    if _ATIS then
        for _, atisObject in pairs(_ATIS) do
            if atisObject and atisObject.Stop then
                pcall(function()
                    atisObject:Stop()
                end)
            end
        end
    end
end

function NAS_SCRIPT_RELOADER:_UnloadGlobals()
    self:_Log("Clearing selected mission globals.")

    -- Put your own mission globals here.
    -- Do NOT blindly nil MOOSE classes unless you fully reload MOOSE and know the side effects.
    --
    -- Example:
    -- MY_MISSION = nil
    -- MY_DISPATCHER = nil
    -- MY_ATIS = nil

    -- If your mission stores active objects in a namespace, clear that namespace:
    NAS_MISSION = nil
end

function NAS_SCRIPT_RELOADER:_GarbageCollect()
    self:_Log("Running Lua garbage collection.")

    collectgarbage("collect")
    collectgarbage("collect")
end

function NAS_SCRIPT_RELOADER:_LoadScript(FilePath)
    self:_Log("Loading script: " .. tostring(FilePath))

    local loader, loadErr = loadfile(FilePath)

    if not loader then
        error(string.format("loadfile failed for %s: %s", tostring(FilePath), tostring(loadErr)))
    end

    return loader()
end

function NAS_SCRIPT_RELOADER:ReloadScripts()
    self:_Message("Reloading mission scripts...", 10)

    self:_RunCleanupHooks()
    self:_StopKnownSchedulers()
    self:_UnloadGlobals()
    self:_GarbageCollect()

    local failures = {}

    for _, FilePath in ipairs(self.ScriptFiles or {}) do
        local ok, err = pcall(function()
            self:_LoadScript(FilePath)
        end)

        if ok then
            self:_Log("Reloaded: " .. tostring(FilePath))
        else
            local msg = string.format("FAILED: %s | %s", tostring(FilePath), tostring(err))
            self:_Log(msg)
            table.insert(failures, msg)
        end
    end

    self:_GarbageCollect()

    if #failures == 0 then
        self:_Message("Mission scripts reloaded successfully.", 10)
    else
        self:_Message("Mission script reload completed with errors. Check dcs.log.", 20)
        for _, failure in ipairs(failures) do
            self:_Log(failure)
        end
    end
end

function NAS_SCRIPT_RELOADER:_ConfirmReload()
    self:_Message("Reload confirmed.", 5)
    self:ReloadScripts()
end

function NAS_SCRIPT_RELOADER:_RequestReload()
    self:_Message("Reload requested. Use F10 > NAS Admin > CONFIRM Reload Mission Scripts.", 15)
end

function NAS_SCRIPT_RELOADER:CreateMenu()
    self:_Log("Creating reload menu.")

    if MENU_MISSION and MENU_MISSION_COMMAND then
        self.MenuRoot = MENU_MISSION:New(self.MenuRootName)

        MENU_MISSION_COMMAND:New(
                self.ReloadCommandName,
                self.MenuRoot,
                function()
                    NAS_SCRIPT_RELOADER:_RequestReload()
                end
        )

        MENU_MISSION_COMMAND:New(
                self.ConfirmCommandName,
                self.MenuRoot,
                function()
                    NAS_SCRIPT_RELOADER:_ConfirmReload()
                end
        )

        self:_Log("MOOSE mission menu created.")
        return
    end

    self.MenuRoot = missionCommands.addSubMenu(self.MenuRootName)

    missionCommands.addCommand(
            self.ReloadCommandName,
            self.MenuRoot,
            function()
                NAS_SCRIPT_RELOADER:_RequestReload()
            end
    )

    missionCommands.addCommand(
            self.ConfirmCommandName,
            self.MenuRoot,
            function()
                NAS_SCRIPT_RELOADER:_ConfirmReload()
            end
    )

    self:_Log("DCS missionCommands menu created.")
end

NAS_SCRIPT_RELOADER:CreateMenu()