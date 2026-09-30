-- Range 64B

local BombTargetGoodHitDistance = 25

Range64B = RANGE:New("Range 64B", coalition.side.BLUE)

Range64B:SetSRS(SRS_PATH, SRS_PORT, coalition.side.BLUE, 255, radio.modulation.AM, 1.0, nil)
Range64B:SetSRSRangeControl(255, radio.modulation.AM, "Zoe", "en-US", "female", "AZRadioRelay")
Range64B:SetSRSRangeInstructor(255.5, radio.modulation.AM, "Nathan", "en-US", "male", "AZRadioRelay")

NASG_TTS:Use(Range64B.controlmsrs, " Range 64B Control", "Zoe", 200, 1.0)
NASG_TTS:Use(Range64B.instructmsrs, "Range 64B Instructor", "Nathan", 200, 1.0)

Range64B:SetFunkManOn(10042, "127.0.0.1")

--local fouldist = Range64B:GetFoullineDistance("strafe1", "foulline1")

--Range64B:AddStrafePit("strafe1", 3000, 300, 180, true, 20, fouldist)

local AzZafrahBombTargets = {
    "circle 1",
    --"container 1",
    --"container 2"
}

Range64B:AddBombingTargets(AzZafrahBombTargets, BombTargetGoodHitDistance)

local range_64b_zone = ZONE:FindByName("Range 64B")
Range64B:SetRangeZone(range_64b_zone)

function Range64B:OnAfterEnterRange(From, Event, To, player)
    BASE:I("Entering Range")
    local text = string.format("fix\n%s has entered the %s.\n", player.playername, self.rangename)
    dcsbot.sendBotMessage(text)
end

function Range64B:OnAfterExitRange(From, Event, To, player)
    BASE:I("Exiting Range")
    local text = string.format("fix\n%s has exited %s.\n", player.playername, self.rangename)
    dcsbot.sendBotMessage(text)
end

function Range64B:OnAfterImpact(From, Event, To, result, player)
    self:T("OnAfterImpact")
end

function Range64B:OnAfterStrafeResult(From, Event, To, player, result)
    self:T("OnAfterStrafeResult")
end

Range64B:SetSoundfilesPath(RANGESOUNDFOLDER)
Range64B:SetTargetSheet(TARGETSHEETSTRAFELOCATION)
Range64B:TrackRocketsOFF()
Range64B:SetMessagesOFF()
Range64B:SetAutosaveOn()
Range64B:SetBombtrackThreshold(UTILS.NMToKiloMeters(100))

-- Start range.
Range64B:Start()




