
--**********************************************Pagan Range************************************************

-- Local variables for easy tweaking
local bombTargetGoodHitDistance = 25

-- Create a range object.
-- PaganRange = RANGE:New("Pagan Test Range")
-- PaganRange = RANGEMSRS:New("Pagan Test Range", SRSSETTINGS.GoogleVoice.Female.en_US_Wavenet_G, 251, 0, 2)
PaganRange = RANGE:New("Pagan Test Range")
PaganRange:SetSRS(SRS_PATH, SRS_PORT, coalition.side.BLUE, 251, radio.modulation.AM, 1.0, GOOGLE_CREDS)
PaganRange:SetSRSRangeControl(251.5, radio.modulation.AM, SRS_VOICES.Female.en_US_Wavenet_G, "en-US", "female", "Pagan Radio Relay")
PaganRange:SetSRSRangeInstructor(251, radio.modulation.AM, SRS_VOICES.Male.en_US_Wavenet_J, "en-US", "male", "Pagan Radio Relay")
PaganRange:SetFunkManOn(10042, "127.0.0.1")

-- Define all range items.
-- Range strafe pits.
-- local PaganStrafePit = { "Pagan StrafePit" } --THE NAME OF YOUR STRAFE PIT OBJECT IN DCS

-- Distance between strafe target and foul line. You have to specify the names of the unit or static objects.
-- Note that this could also be done manually by simply measuring the distance between the target and the foul line in the ME.
-- local fouldist = PaganRange:GetFoullineDistance("Pagan StrafePit", "Pagan Foul Line") --NAME OF STRAFE PIT AND YOUR FOUL LINE IF USING ONE

--RANGE.AddStrafePit(targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)
-- PaganRange:AddStrafePit(PaganStrafePit, 3000, 300, 111, true, 20, fouldist)

-- Table of bombing target names. Again these are the names of the corresponding units as defined in the ME.
local BombTargets = {
    --  "Pagan DMPI North",
    -- "Pagan DMPI South",
    "Pagan Sherman 1",
    "Pagan Sherman 2",
    "Pagan Sherman 3",
    "Pagan Sherman 4",
    "Pagan Halftrack 1",
    "Pagan Halftrack 2",
    "Pagan Halftrack 3",
    "Pagan Halftrack 4",
    -- "Pagan Building 1",
    -- "Pagan Building 2",
    "Pagan APC 1",
    "Pagan APC 2",
    "Pagan APC 3",
    "Pagan APC 4",
}

-- Add bombing targets. A good hit is if the bomb falls less then 25 m from the target.
PaganRange:AddBombingTargets(BombTargets, bombTargetGoodHitDistance)

local pagan_range_zone = ZONE:FindByName("Pagan Test Range")
PaganRange:SetRangeZone(pagan_range_zone)

function PaganRange:OnAfterEnterRange(From, Event, To, player)
    BASE:I("Entering Range")
    local text = string.format("fix\n%s has entered the %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
    dcsbot.sendBotMessage(text)
end

function PaganRange:OnAfterExitRange(From, Event, To, player)
    BASE:I("Exting Range")
    local text = string.format("fix\n%s has exited %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
    dcsbot.sendBotMessage(text)
end

function PaganRange:OnAfterImpact(From, Event, To, result, player)
    self:T("OnAfterImpact")
end

function PaganRange:OnAfterStrafeResult(From, Event, To, player, result)
    self:T("OnAfterStrafeResult")
end

PaganRange:SetSoundfilesPath(RANGESOUNDFOLDER)
PaganRange:SetTargetSheet(TARGETSHEETSTRAFELOCATION)
PaganRange:TrackRocketsOFF()
PaganRange:SetMessagesOFF()
PaganRange:SetAutosaveOn()
-- PaganRange:SetBombtrackThreshold(55)
PaganRange:SetBombtrackThreshold(UTILS.NMToKiloMeters(100))

-- Start range.
PaganRange:Start()


--create Faralon Test Range instance
FaralonRange = RANGE:New("Faralon Test Range")
FaralonRange:SetSRS(SRS_PATH, SRS_PORT, coalition.side.BLUE, 255, radio.modulation.AM, 1.0, GOOGLE_CREDS)
FaralonRange:SetSRSRangeControl(255.5, radio.modulation.AM, SRS_VOICES.Female.en_US_Wavenet_G, "en-US", "female", "Faralon Radio Relay")
FaralonRange:SetSRSRangeInstructor(255, radio.modulation.AM, SRS_VOICES.Male.en_US_Wavenet_J, "en-us", "male", "Faralon Radio Relay")
FaralonRange:SetFunkManOn(10042, "127.0.0.1")

--make table of different bomb targets in range
local FaralonBombTargets = {
    "FDM TGT veh 1-1",
    "FDM TGT veh 2-1",
    "FDM TGT veh 3-1",
    "FDM TGT veh 4-1",
    -- "FDM TGT square 1-1",
    -- "FDM TGT square 2-1",
    -- "FDM TGT E-shaped 1-1",
    -- "FDM TGT L-Shaped 1-1",
    -- "FDM TGT T-shaped North 1-1",
    "FDM TGT T-shaped South 1-1",
    "FDM TGT X-shaped North 1-1",
    "FDM TGT X-shaped Mid 1-1",
    "FDM TGT X-shaped South 1-1"
}

--add in bombing targets
FaralonRange:AddBombingTargets(FaralonBombTargets,BombTargetsGoodHitDistance)

local faralon_range_zone = ZONE:FindByName("Faralon Test Range")
FaralonRange:SetRangeZone(faralon_range_zone)

function FaralonRange:OnAfterEnterRange(From, Event, To, player)
    BASE:I("Entering Range")
    local text = string.format("fix\n%s has entered the %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
    dcsbot.sendBotMessage(text)
end

function FaralonRange:OnAfterExitRange(From, Event, To, player)
    BASE:I("Exting Range")
    local text = string.format("fix\n%s has exited %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
    dcsbot.sendBotMessage(text)
end

function FaralonRange:OnAfterImpact(From, Event, To, result, player)
    self:T("OnAfterImpact")
end

function FaralonRange:OnAfterStrafeResult(From, Event, To, player, result)
    self:T("OnAfterStrafeResult")
end


FaralonRange:SetSoundfilesPath(RANGESOUNDFOLDER)
FaralonRange:SetTargetSheet(TARGETSHEETSTRAFELOCATION)
FaralonRange:TrackRocketsOFF()
FaralonRange:SetMessagesOFF()
FaralonRange:SetAutosaveOn()
-- PaganRange:SetBombtrackThreshold(55)
FaralonRange:SetBombtrackThreshold(UTILS.NMToKiloMeters(100))

-- Start range.
FaralonRange:Start()


-- TODO Get this Class into it's own file
-- TODO Documentation
-- TODO Make it more genaeric to use for any zone.
PITSMOKER = {
    ClassName            = "PITSMOKER",
    _timer               = nil,
    _startDelay          = 1, -- default 1 second
    _smokeRepeatDelay    = 300, -- default 5 minutes
    _clientCheckDelay    = 10, -- check for clients in zone every 10 sec
    _startSmokeTimeStamp = 0,
    _rangeZone           = nil,
    _clientSet           = BLUE_CLIENT_SET, -- this is a hack at the moment, this set is created in BlaskSeaAirboss_tanker.lua
    _smokeOn             = true -- clients in range zone
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
        self._clientSet:ForEachClientInZone(self._rangeZone,
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
        COORDINATE:NewFromVec2({ x = 00512521, y = 00107853 }), -- Strafe Pit Left Single only
        -- COORDINATE:NewFromVec2({x = 00512535, y = 00107225}), -- Foul Line 1 (At beach)
        -- COORDINATE:NewFromVec2({x = 00512396, y = 00107801}), -- Strafe Pit 1 Left
        -- COORDINATE:NewFromVec2({x = 00512263, y = 00107752}), -- Strafe Pit 1 Right
    }
    for _, coord in pairs(strafePitSmokeCoords) do
        coord:SmokeRed()
    end

    -- Restamp the timestamp
    self._startSmokeTimeStamp = timer.getTime()

    -- Reset the _smokeOn flag
    self._smokeOn = false
end

local pitSmoker = PITSMOKER:Start(PaganRange.rangezone, 1, 10)
