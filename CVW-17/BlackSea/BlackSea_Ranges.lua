-- Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('RANGE')


--**********************************************Kemal'Pasha Range************************************************

-- Local variables for easy tweaking
local bombTargetGoodHitDistance = 25

-- Create a range object.
KemalPashaRange = RANGE:New("Kemal Pasha Test Range")
KemalPashaRange = RANGEMSRS:New("Kemal Pasha Test Range","en-US-Wavenet-C" , 251, 0, 2)
KemalPashaRange:SetFunkManOn(10042, "127.0.0.1")

-- Setup a Range control and Range instructor SRS messanger.
 --KemalPashaRangeControl = SRSMSGRANGECONTROL:New(KemalPashaRange, SRSMSGBASE.GoogleVoice.Male.en_US_Wavenet_I, rangeControlFreq, 0, 2)
 --KemalPashaRangeInstructor = SRSMSGRANGE:New(KemalPashaRange, SRSMSGBASE.GoogleVoice.Male.en_US_Wavenet_J, rangeInstructorFreq, 0, 2)

-- Define all range items.
-- Range strafe pits.
local StrafePitWest = {"Kemal Pasha Strafe Pit West"} --THE NAME OF YOUR STRAFE PIT OBJECT IN DCS
local StrafePitEast = {"Kemal Pasha Strafe Pit East"} --THE NAME OF YOUR STRAFE PIT OBJECT IN DCS

-- Distance between strafe target and foul line. You have to specify the names of the unit or static objects.
-- Note that this could also be done manually by simply measuring the distance between the target and the foul line in the ME.
local fouldist = KemalPashaRange:GetFoullineDistance("Kemal Pasha Strafe Pit West", "Kemal Pasha Foul Line West") --NAME OF STRAFE PIT AND YOUR FOUL LINE IF USING ONE
local fouldist = KemalPashaRange:GetFoullineDistance("Kemal Pasha Strafe Pit East", "Kemal Pasha Foul Line East") --NAME OF STRAFE PIT AND YOUR FOUL LINE IF USING ONE

--RANGE.AddStrafePit(targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)
KemalPashaRange:AddStrafePit(StrafePitWest, 3000, 300, 100, true, 20, fouldist)
KemalPashaRange:AddStrafePit(StrafePitEast, 3000, 300, 125, true, 20, fouldist)

-- Table of bombing target names. Again these are the names of the corresponding units as defined in the ME.
local BombTargets={"Kemal Pasha Bomb Circle East",
                    "Kemal Pasha Bomb Circle West" ,
                    "Kemal Pasha Bomb Target 1",
                    "Kemal Pasha Bomb Target 2",
                    "Kemal Pasha Bomb Target 3",
                    "Kemal Pasha Bomb Target 4",
                    "Kemal Pasha Hard Target 1",
                    "Kemal Pasha Hard Target 2",
                    "Kemal Pasha Hard Target 3",
                    "Kemal Pasha Hard Target 4",
                    "Kemal Pasha Hard Target 5",
                    "Kemal Pasha Hard Target 6",
                    "Kemal Pasha Hard Target 7",
                    "Kemal Pasha Hard Target 8",
                    "Kemal Pasha Hard Target 8-1",
                    "Kemal Pasha Hard Target 8-2",
                    "Kemal Pasha Hard Target 8-3",
                    "Kemal Pasha Hard Target 8-4",
                    "Kemal Pasha Hard Target 8-5",
                    "Kemal Pasha Hard Target 8-6",
                    "Kemal Pasha Hard Target 8-7"
                }

-- Add bombing targets. A good hit is if the bomb falls less then 25 m from the target.
KemalPashaRange:AddBombingTargets(BombTargets, bombTargetGoodHitDistance)

-- Set up range radios.
KemalPashaRange:SetRangeControl(251.500, "Kemal Pasha Range Relay")--added correct relay 9/4/21
KemalPashaRange:SetInstructorRadio(251.000, "Kemal Pasha Range Relay")--added correct relay 9/4/21

local range_zone = ZONE:FindByName("Kemal Pasha Test Range")
KemalPashaRange:SetRangeZone(range_zone)
-- KemalPashaRange.location = UNIT:FindByName("Kemal Pasha Range Relay"):GetCoordinate()

function KemalPashaRange:OnAfterEnterRangeMSRS(From, Event, To, player)
    BASE:I("Entering Range")
    local text=string.format("\n%s has entered the %s.\n", player.playername, self.rangename)  
    dcsbot.sendBotMessage(text)
end

function KemalPashaRange:OnAfterExitRangeMSRS(From, Event, To, player)
    BASE:I("Exting Range")
    local text=string.format("\n%s has exited %s.\n", player.playername, self.rangename)  
    dcsbot.sendBotMessage(text)
end

KemalPashaRange:TrackRocketsOFF()
KemalPashaRange:SetMessagesOFF()
KemalPashaRange:SetAutosaveOn()
KemalPashaRange:SetBombtrackThreshold(55)

-- Start range.
KemalPashaRange:Start()

-- TODO Get this Class into it's own file
-- TODO Documentation
-- TODO Make it more genaeric to use for any zone.
PITSMOKER = {
    ClassName               = "PITSMOKER",
    _timer                  = nil,
    _startDelay             = 1, -- default 1 second
    _smokeRepeatDelay       = 300, -- default 5 minutes
    _clientCheckDelay       = 10, -- check for clients in zone every 10 sec
    _startSmokeTimeStamp    = 0,
    _rangeZone              = nil,
    _clientSet              = BLUE_CLIENT_SET, -- this is a hack at the moment, this set is created in BlaskSeaAirboss_tanker.lua
    _smokeOn                = true -- clients in range zone
}
-- Smoke strafe pit locations
-- Create a function and schedule it to run every 5 mins (DCS smoke only lasts 5 mins).
-- Create a table of all the coordinates we'd like to smoke and then iterate through

function PITSMOKER:Start(rangeZone, startDelay, clientCheckDelay)
    -- BASE:I("pitsmoker started")

    self._rangeZone = rangeZone
    self._startDelay = (startDelay or self._startDelay)
    self._repeatDelay = (clientCheckDelay or self._clientCheckDelay)

    -- Start the timer
    self._timer = TIMER:New(PITSMOKER.CheckPitSmoker, self):Start(self._startDelay, self._clientCheckDelay)

    return self
end

function PITSMOKER:Stop()
    self._timer = nil

    return self
end

function PITSMOKER:CheckPitSmoker()
    -- BASE:I("pitsmoker timer fired")
    -- If the timer.GetTime()-_startSmokeTimeStamp is >= _repeatDelay and there are Clients in the zone, smoke the pits.
    -- Otherwise do nothing.

    -- BASE:I("pitsmoker client count:" .. self._clientSet:Count())
    if self._clientSet:Count() > 0 then
        self._clientSet:ForEachClientInZone( self._rangeZone,
            function(client)
                -- BASE:I("pitsmoker client in zone: " .. client:GetPlayer())
                
                local timeDiff = timer.getTime() - self._startSmokeTimeStamp
                -- BASE:I("pitsmoker time diff: " .. tostring(timeDiff))

                if timeDiff >= self._smokeRepeatDelay then
                    -- BASE:I("pitsmoker flaging _smokeOn:")
                    self._smokeOn = true
                end
                
            end
        )
    end

    if self._smokeOn then
        self:SmokeRangeStrafePits()
    end
end

-- them initiating the smoke.
function PITSMOKER:SmokeRangeStrafePits()
    -- BASE:I("pitsmoker smoking the pit!")
    local smokeHeight = 0
    local strafePitSmokeCoords = {
        COORDINATE:NewFromVec2({x = -00408447, y = 00561713}), -- Foul Line 1 (At beach)
        COORDINATE:NewFromVec2({x = -00408607, y = 00563162}), -- Strafe Pit 1 Left
        COORDINATE:NewFromVec2({x = -00408769, y = 00563135}), -- Strafe Pit 1 Right
        COORDINATE:NewFromVec2({x = -00412122, y = 00575325}), -- Foul Line 2
        COORDINATE:NewFromVec2({x = -00412856, y = 00576508}), -- Strafe Pit 2 Left
        COORDINATE:NewFromVec2({x = -00412991, y = 00576413}), -- Strafe Pit 2 Right
    }
    for _, coord in pairs(strafePitSmokeCoords) do
        coord:SmokeRed()
    end

    -- Restamp the timestamp
    self._startSmokeTimeStamp = timer.getTime()

    -- Reset the _smokeOn flag
    self._smokeOn = false
end

local pitSmoker = PITSMOKER:Start(KemalPashaRange.rangezone, 1, 10)
