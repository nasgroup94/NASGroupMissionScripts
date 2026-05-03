package.path = [[C:\Users\fpere\IdeaProjects\NASGroupMissionScripts\Common\TTS Test\?.lua;]] .. package.path

local TTSPython = require("TTSPython")
local tts = TTSPython:New()

local text = arg[1] or "Help"

local filename, folder, err = tts:GenerateOgg(text)

if not filename then
    print("ERROR:", err)
    os.exit(1)
end

print("filename:", filename)
print("folder:", folder)
print("full path:", folder .. filename)

