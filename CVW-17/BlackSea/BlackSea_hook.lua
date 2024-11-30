local io = require('io')
local lfs = require('lfs')
local net =require('net')

net.log('VNAO: Loading VNAO hooks.')

local vnao  = {}

function vnao.onNetMissionChanged(newMissionName)
    local missionName = DCS.getMissionName()

    local f = assert(io.open(lfs.writedir() .. '\\current_mission', "w"))
    f:write(missionName)
    f:close()

    net.log('VNAO: Current mission: ' .. missionName)
end

DCS.setUserCallbacks(vnao)