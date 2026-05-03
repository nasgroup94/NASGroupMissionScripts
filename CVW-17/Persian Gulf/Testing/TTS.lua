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

local landingJob = TTSJob:New({
    Name = "LandingClearance",
    TTS = tts,
    Text = "Clear to land runway two three",

    Voice = "Victoria",
    Rate = 150,
    Pitch = 0,

    Freqs = "250.0",
    Modulations = "AM",
    Coalition = 2,
    Port = 5002,

    OnComplete = function(job, filename, folder)
        env.info("Completed TTS file: " .. tostring(folder .. filename))
    end,

    OnError = function(job, err)
        env.info("TTS error: " .. tostring(err))
    end,
})

landingJob:Start()

local towerJob = TTSJob:New({
    Name = "TowerCall",
    TTS = tts,
    Text = "Wind zero niner zero at eight knots",
    Freqs = "251.0",
    Modulations = "AM",
    Coalition = 2,
    Port = 5002,
    Gender = "male",
    RequestDelay = 10,
})

towerJob:Start()

local minhadAtis = TTSJob:New({
    Name = "Al Minhad ATIS",
    TTS = tts,
    Freqs = "248.0",
    Modulations = "AM",
    Coalition = 2,
    Port = 5002,

})




