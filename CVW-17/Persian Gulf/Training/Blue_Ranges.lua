-- AZ Zafrah Range

local BombTargetGoodHitDistance = 25

AzZafrahRange = RANGE:New("Az Zafrah Range", coalition.side.BLUE)

AzZafrahRange:SetSRS(SRS_PATH, SRS_PORT, coalition.side.BLUE, 255, radio.modulation.AM, 1.0, nil)
AzZafrahRange:SetSRSRangeControl(255, radio.modulation.AM, "Zoe", "en-US", "female", "AZRadioRelay")
AzZafrahRange:SetSRSRangeInstructor(255.5, radio.modulation.AM, "Nathan", "en-US", "male", "AZRadioRelay")

NASG_TTS:Use(AzZafrahRange.controlmsrs, "Az Zafrah Range Control", "Zoe", 200, 1.0)
NASG_TTS:Use(AzZafrahRange.instructmsrs, "Az Zafrah Range Instructor", "Nathan", 200, 1.0)

AzZafrahRange:SetFunkManOn(10042, "127.0.0.1")

local fouldist = AzZafrahRange:GetFoullineDistance("strafe1", "foulline1")

AzZafrahRange:AddStrafePit("strafe1", 3000, 300, 180, true, 20, fouldist)

local AzZafrahBombTargets = {
    "circle 1",
    "container 1",
    "container 2"
}

AzZafrahRange:AddBombingTargets(AzZafrahBombTargets, BombTargetGoodHitDistance)

local azzafrah_range_zone = ZONE:FindByName("AZ ZAFRAH Range")
AzZafrahRange:SetRangeZone(azzafrah_range_zone)

function AzZafrahRange:OnAfterEnterRange(From, Event, To, player)
    BASE:I("Entering Range")
    local text = string.format("fix\n%s has entered the %s.\n", player.playername, self.rangename)
    dcsbot.sendBotMessage(text)
end

function AzZafrahRange:OnAfterExitRange(From, Event, To, player)
    BASE:I("Exiting Range")
    local text = string.format("fix\n%s has exited %s.\n", player.playername, self.rangename)
    dcsbot.sendBotMessage(text)
end

function AzZafrahRange:OnAfterImpact(From, Event, To, result, player)
    self:T("OnAfterImpact")
end

function AzZafrahRange:OnAfterStrafeResult(From, Event, To, player, result)
    self:T("OnAfterStrafeResult")
end

AzZafrahRange:SetSoundfilesPath(RANGESOUNDFOLDER)
AzZafrahRange:SetTargetSheet(TARGETSHEETSTRAFELOCATION)
AzZafrahRange:TrackRocketsOFF()
AzZafrahRange:SetMessagesOFF()
AzZafrahRange:SetAutosaveOn()
AzZafrahRange:SetBombtrackThreshold(UTILS.NMToKiloMeters(100))

-- Start range.
AzZafrahRange:Start()




