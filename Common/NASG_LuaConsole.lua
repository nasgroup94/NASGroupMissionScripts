NASG_LUA_CONSOLE = NASG_LUA_CONSOLE or {}

NASG_LUA_CONSOLE.FilePath = NASG_LUA_CONSOLE.FilePath
        or lfs.writedir() .. "Logs/nasg_lua_console.lua"

function NASG_LUA_CONSOLE:Log(message)
    env.info("[NASG_LUA_CONSOLE] " .. tostring(message))
end

function NASG_LUA_CONSOLE:ValueToString(value, depth)
    depth = depth or 0

    if depth > 3 then
        return "<max depth>"
    end

    local valueType = type(value)

    if valueType ~= "table" then
        return tostring(value)
    end

    local parts = {}
    local count = 0

    for key, item in pairs(value) do
        count = count + 1

        if count > 30 then
            parts[#parts + 1] = "... more ..."
            break
        end

        parts[#parts + 1] = tostring(key) .. "=" .. self:ValueToString(item, depth + 1)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

function NASG_LUA_CONSOLE:RunFile()
    self:Log("Running Lua console file: " .. tostring(self.FilePath))

    local chunk, loadErr = loadfile(self.FilePath)

    if not chunk then
        self:Log("loadfile failed: " .. tostring(loadErr))
        return
    end

    local ok, result = xpcall(chunk, function(err)
        return tostring(err) .. "\n" .. debug.traceback()
    end)

    if not ok then
        self:Log("runtime error: " .. tostring(result))
        return
    end

    self:Log("result: " .. self:ValueToString(result))
end

function NASG_LUA_CONSOLE:InstallMenu()
    if self.Menu then
        return
    end

    if not missionCommands then
        self:Log("missionCommands unavailable")
        return
    end

    self.Menu = missionCommands.addSubMenu("NASG Lua Console")

    missionCommands.addCommand(
            "Run Lua Console File",
            self.Menu,
            function()
                NASG_LUA_CONSOLE:RunFile()
            end
    )

    self:Log("Installed F10 Lua console menu")
end

NASG_LUA_CONSOLE:InstallMenu()