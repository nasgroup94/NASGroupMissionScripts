TTSPython = {}
TTSPython.__index = TTSPython

function TTSPython:New(config)
    config = config or {}

    local self = setmetatable({}, TTSPython)

    self.PythonExe = config.PythonExe or "py"
    self.ScriptPath = config.ScriptPath or [[C:\Users\fpere\IdeaProjects\NASGroupMissionScripts\Common\TTS Test\tts_client.py]]
    self.OutputDir = config.OutputDir or [[C:\Users\fpere\IdeaProjects\NASGroupMissionScripts\Common\TTS Test]]
    self.OutputFile = config.OutputFile or "output.ogg"

    return self
end

local function quote(value)
    value = tostring(value or "")
    value = value:gsub('"', '\\"')
    return '"' .. value .. '"'
end

local function ensureTrailingSlash(path)
    if path:sub(-1) == "\\" or path:sub(-1) == "/" then
        return path
    end

    return path .. "\\"
end

function TTSPython:Generate(text)
    if text == nil or text == "" then
        return nil, nil, "No TTS text provided"
    end

    local command = table.concat({
        self.PythonExe,
        quote(self.ScriptPath),
        quote(text),
        quote(self.OutputDir)
    }, " ")

    local ok = os.execute(command)

    if not ok then
        return nil, nil, "Python TTS command failed: " .. command
    end

    local folder = ensureTrailingSlash(self.OutputDir)
    local filename = self.OutputFile

    return filename, folder
end

function TTSPython:GenerateOgg(text)
    local filename, folder, err = self:Generate(text)

    if not filename then
        return nil, nil, err
    end

    if not filename:lower():match("%.ogg$") then
        return nil, nil, "Generated file was not an .ogg file: " .. tostring(filename)
    end

    return filename, folder
end

return TTSPython