local websocket = require("websocket.client")
local cjson = require("cjson.safe")
local mime = require("mime")

TTSWebSocket = {}

TTSWebSocket.Uri = "ws://96.32.24.78:8080"
TTSWebSocket.OutputFolder = lfs.writedir() .. "Sounds/"

function TTSWebSocket.Play(text, frequency, modulation)
    frequency = frequency or 251
    modulation = modulation or radio.modulation.AM

    local ws = websocket()

    local ok, err = ws:connect(TTSWebSocket.Uri)
    if not ok then
        env.info("Failed to connect: " .. err)
    end

    ws:send(text)

    local message = ws:receive()
    ws:close()

    if not message then
        env.info("No response from server")
    end

    local data = cjson.decode(message)
    if not data then
        env.info("Failed to parse JSON response: " .. message)
    end

    if not data.success or not data.audio then
        env.info("Server error: " .. data.error )
    end

    local ext = data.format or "ogg"
    local audio_data = mime.unb64(data.audio)

    local filename = "tts_" .. tostring(timer.getAbsTime()):gsub("%.", "_") .. "." .. ext
    local filepath = TTSWebSocket.OutputFolder .. filename

    local f = assert(io.open(filepath, "wb"))
    f:write(audio_data)
    f:close()

    local soundfile = SOUNDFILE:New(filename, TTSWebSocket.OutputFolder)
    local msrs = MSRS:New(SRS_PATH, frequency, modulation, MSRS.Backend.SRSEXE)

    msrs:PlaySoundFile(soundfile)

    return filepath
end