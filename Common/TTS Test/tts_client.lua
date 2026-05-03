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

local websocket = require("websocket.client")
local mime = require("mime")
local json = require("dkjson")

local url = "ws://96.32.24.78:8080"

local ws = websocket()

local ok, err = ws:connect(url)
if not ok then
  error("WebSocket connect failed: " .. tostring(err))
end

ws:send("hello from lua")

local response_body = ws:receive()
ws:close()

if not response_body then
  error("No response from server")
end

local data = json.decode(response_body)

if not data then
  error("Failed to parse JSON response: " .. tostring(response_body))
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