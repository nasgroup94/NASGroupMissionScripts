local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")

TTSPython = {}
TTSPython.__index = TTSPython

function TTSPython:New(config)
    config = config or {}

    local self = setmetatable({}, TTSPython)

    self.Url = config.Url or "http://127.0.0.1:8765/tts"

    return self
end

local function httpJson(method, url, bodyTable)
    local response_chunks = {}
    local request_body = nil

    local request = {
        url = url,
        method = method,
        sink = ltn12.sink.table(response_chunks),
    }

    if bodyTable then
        request_body = json.encode(bodyTable)

        request.headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#request_body),
        }

        request.source = ltn12.source.string(request_body)
    end

    local ok, status_code = http.request(request)
    local response_body = table.concat(response_chunks)

    if not ok then
        return nil, "HTTP request failed: " .. tostring(status_code)
    end

    local data = json.decode(response_body)

    if not data then
        return nil, "Failed to parse JSON response: " .. tostring(response_body)
    end

    return data, nil, status_code
end

-- ... existing code ...

function TTSPython:Request(text, options)
    if text == nil or text == "" then
        return nil, "No TTS text provided"
    end

    options = options or {}

    local payload = {
        text = text,

        -- Duplicate suppression/cache grouping.
        initiator = options.initiator,
        label = options.label,

        -- TTS voice options passed to the upstream TTS server
        voice = options.voice,
        rate = options.rate,
        pitch = options.pitch,

        -- SRS ExternalAudio options
        freqs = options.freqs,
        modulations = options.modulations,
        coalition = options.coalition,
        port = options.port,
        gender = options.gender,
        volume = options.volume,
    }

    local data, err = httpJson("POST", self.Url, payload)

    if not data then
        return nil, err
    end

    if not data.success then
        return nil, data.error or "Unknown TTS request error"
    end

    return data.job_id
end

-- ... existing code ...

function TTSPython:Check(job_id)
    if not job_id or job_id == "" then
        return nil, "No job_id provided"
    end

    local data, err = httpJson("GET", self.Url .. "/" .. job_id)

    if not data then
        return nil, nil, err
    end

    if data.status == "done" then
        return data.filename, data.folder, nil, data.status
    end

    if data.status == "error" then
        return nil, nil, data.error or "TTS job failed", data.status
    end

    return nil, nil, nil, data.status
end

return TTSPython