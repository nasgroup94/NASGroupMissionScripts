local websocket = require("websocket.client")
local cjson = require("cjson.safe")
local mime = require("mime")

local uri = "ws://96.32.24.78:8080"
local ws = websocket()

local ok, err = ws:connect(uri)
if not ok then
  error("Failed to connect: " .. tostring(err))
end

-- Send plain text or JSON
local text = "hello from lua"
ws:send(text)
-- Or json: ws:send(cjson.encode({ text = text }))

local message = ws:receive()
if not message then
  error("No response from server")
end

local data = cjson.decode(message)
if not data then
  error("Failed to parse JSON response: " .. tostring(message))
end

if data.success and data.audio then
  local ext = data.format or "ogg"
  local audio_data = mime.unb64(data.audio)
  local filename = "output." .. ext

  local f = assert(io.open(filename, "wb"))
  f:write(audio_data)
  f:close()

  print("Saved audio to", filename)
else
  print("Server error:", data.error or "unknown")
end

ws:close()