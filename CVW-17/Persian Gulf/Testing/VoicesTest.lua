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

local TTSPython = require("TTSPython")
local TTSJob = require("TTSJob")

local tts = TTSPython:New()

local tests = {
    {
        text = "Test one. Voice Victoria. Frequency two five zero.",
        voice = "Victoria",
        rate = 150,
        pitch = 0,
        freqs = "250.0",
        modulations = "AM",
        coalition = 2,
        port = 5002,
    },
    {
        text = "Test two. Voice Daniel. Frequency two five one.",
        voice = "Alex",
        rate = 145,
        pitch = 0,
        freqs = "251.0",
        modulations = "AM",
        coalition = 2,
        port = 5002,
    },
    {
        text = "Test three. United States standard alpha voice.",
        voice = "Ralph",
        rate = 150,
        pitch = 0,
        freqs = "252.0",
        modulations = "AM",
        coalition = 2,
        port = 5002,
    },
    {
        text = "Test four. United Kingdom standard female voice.",
        voice = "Junior",
        rate = 150,
        pitch = 0,
        freqs = "253.0",
        modulations = "AM",
        coalition = 2,
        port = 5002,
    },
}

for _, test in ipairs(tests) do
    local job_id, err = tts:Request(test.text, {
        voice = test.voice,
        rate = test.rate,
        pitch = test.pitch,
        freqs = test.freqs,
        modulations = test.modulations,
        coalition = test.coalition,
        port = test.port,

    })

    if job_id then
        print("Queued voice test:", test.voice, job_id)
    else
        print("Failed voice test:", test.voice, err)
    end
end