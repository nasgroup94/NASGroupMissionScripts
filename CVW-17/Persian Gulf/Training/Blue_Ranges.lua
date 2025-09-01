-- AZ Zafrah Range

local BombTargetGoodHitDistance = 25

AzZafrahRange = RANGE:New("Az Zafrah Range" , coalition.side.BLUE)
AzZafrahRange:SetSRS(SRS_PATH,SRS_PORT,coalition.side.BLUE,251, radio.modulation.AM,1.0,GOOGLE_CREDS)
AzZafrahRange:SetSRSRangeControl(251.5, radio.modulation.AM, SRS_VOICES.Female.en_US_Wavenet_G, "en-US", "female", "Pagan Radio Relay")
AzZafrahRange:SetSRSRangeInstructor(251, radio.modulation.AM, SRS_VOICES.Male.en_US_Wavenet_J, "en-US", "male", "Pagan Radio Relay")
AzZafrahRange:SetFunkManOn(10042, "127.0.0.1")

local fouldist = AzZafrahRange:GetFoullineDistance("strafe 1","foul line 1")

AzZafrahRange:AddStrafePit("strafe 1",3000,300,180,360,true,20,fouldist)

local AzZafrahBombTargets ={
"circle 1",
}


AzZafrahRange:AddBombingTargets(AzZafrahBombTargets,BombTargetsGoodHitDistance)

local azzafrah_range_zone = ZONE:FindByName("Faralon Test Range")
AzZafrahRange:SetRangeZone(azzafrah_range_zone)

function AzZafrahRange:OnAfterEnterRange(From, Event, To, player)
    BASE:I("Entering Range")
    local text = string.format("fix\n%s has entered the %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
    dcsbot.sendBotMessage(text)
end

function AzZafrahRange:OnAfterExitRange(From, Event, To, player)
    BASE:I("Exting Range")
    local text = string.format("fix\n%s has exited %s.\n", player.playername, self.rangename)
    -- HypeMan.sendBotMessage(text)
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
-- PaganRange:SetBombtrackThreshold(55)
AzZafrahRange:SetBombtrackThreshold(UTILS.NMToKiloMeters(100))

-- Start range.
AzZafrahRange:Start()