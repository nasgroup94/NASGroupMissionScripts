package.path = [[C:\Users\fpere\IdeaProjects\NASGroupMissionScripts\Common\TTS Test\?.lua;]] .. package.path

local lua_modules = [[C:\Users\fpere\IdeaProjects\NASGroupMissionScripts\Common\TTS Test\lua_modules]]

package.path =
lua_modules .. [[\?.lua;]] ..
        lua_modules .. [[\?\init.lua;]] ..
        lua_modules .. [[\share\lua\5.1\?.lua;]] ..
        lua_modules .. [[\share\lua\5.1\?\init.lua;]] ..
        package.path

package.cpath =
lua_modules .. [[\?.dll;]] ..
        lua_modules .. [[\lib\lua\5.1\?.dll;]] ..
        package.cpath

local socket = require("socket")
local TTSPython = require("TTSPython")
local tts = TTSPython:New()

local text = arg[1] or "Help"
local timeout_seconds = tonumber(arg[2]) or 30
local poll_interval_seconds = tonumber(arg[3]) or 1

local job_id, request_err = tts:Request(text)

if not job_id then
    print("ERROR:", request_err)
    os.exit(1)
end

print("job_id:", job_id)
print("status: queued")

local start_time = socket.gettime()

while true do
    local filename, folder, err, status = tts:Check(job_id)

    if err then
        print("ERROR:", err)
        os.exit(1)
    end

    if filename then
        print("status:", status)
        print("filename:", filename)
        print("folder:", folder)
        print("full path:", folder .. filename)
        os.exit(0)
    end

    print("status:", status or "unknown")

    if socket.gettime() - start_time >= timeout_seconds then
        print("ERROR: timed out waiting for TTS job:", job_id)
        os.exit(1)
    end

    socket.sleep(poll_interval_seconds)
end