--[[ -- SSML info
    SSML Specification
    https://www.w3.org/TR/speech-synthesis11/#S3.2.4

    Google's SSML API
    https://cloud.google.com/text-to-speech/docs/ssml#support-for-ssml-elements

    Google Voices
    https://cloud.google.com/text-to-speech/docs/voices
]]

-- -- Debuging
-- BASE:TraceLevel(1)
-- BASE:TraceClass('RANGE')
-- BASE:TraceClass('RANGEMSRS')
-- BASE:TraceOn()
--]]

-- TODO Rebuild this differently. It's not very flexable and should not require the end mission developer to use different
-- event functions than the original MOOSE ones.

SRSSETTINGS = {
    MSRSExec                = "C:\\progra~1\\DCS-SimpleRadio-Standalone",
    MRSRSGoogleCredsFile    = "C:/VNAO/API-Keys/cvw7-tracking-11c8a6927776.json",
}


--[[ -- List of Google voices
    Google Voices
    https://cloud.google.com/text-to-speech/docs/voices
]]
SRSSETTINGS.GoogleVoice = {
    Female = {
        en_AU_Standard_A = "en-AU-Standard-A",
        en_AU_Standard_C = "en-AU-Standard-C",
        en_AU_Wavenet_A = "en-AU-Wavenet-A",
        en_AU_Wavenet_C = "en-AU-Wavenet-C",
        en_IN_Standard_A = "en-IN-Standard-A",
        en_IN_Standard_D = "en-IN-Standard-D",
        en_IN_Wavenet_A = "en-IN-Wavenet-A",
        en_IN_Wavenet_D = "en-IN-Wavenet-D",
        en_GB_Standard_A = "en-GB-Standard-A",
        en_GB_Standard_C = "en-GB-Standard-C",
        en_GB_Standard_F = "en-GB-Standard-F",
        en_GB_Wavenet_A = "en-GB-Wavenet-A",
        en_GB_Wavenet_C = "en-GB-Wavenet-C",
        en_GB_Wavenet_F = "en-GB-Wavenet-F",
        en_US_Standard_C = "en-US-Standard-C",
        en_US_Standard_E = "en-US-Standard-E",
        en_US_Standard_F = "en-US-Standard-F",
        en_US_Standard_G = "en-US-Standard-G",
        en_US_Standard_H = "en-US-Standard-H",
        en_US_Wavenet_C = "en-US-Wavenet-C",
        en_US_Wavenet_E = "en-US-Wavenet-E",
        en_US_Wavenet_F = "en-US-Wavenet-F",
        en_US_Wavenet_G = "en-US-Wavenet-G",
        en_US_Wavenet_H = "en-US-Wavenet-H"
    },
    Male = {
        en_AU_Standard_B = "en-AU-Standard-B",
        en_AU_Standard_D = "en-AU-Standard-D",
        en_AU_Wavenet_B = "en-AU-Wavenet-B",
        en_AU_Wavenet_D = "en-AU-Wavenet-D",
        en_IN_Standard_B = "en-IN-Standard-B",
        en_IN_Standard_C = "en-IN-Standard-C",
        en_IN_Wavenet_B = "en-IN-Wavenet-B",
        en_IN_Wavenet_C = "en-IN-Wavenet-C",
        en_GB_Standard_B = "en-GB-Standard-B",
        en_GB_Standard_D = "en-GB-Standard-D",
        en_GB_Wavenet_B = "en-GB-Wavenet-B",
        en_GB_Wavenet_D = "en-GB-Wavenet-D",
        en_US_Standard_A = "en-US-Standard-A",
        en_US_Standard_B = "en-US-Standard-B",
        en_US_Standard_D = "en-US-Standard-D",
        en_US_Standard_I = "en-US-Standard-I",
        en_US_Standard_J = "en-US-Standard-J",
        en_US_Wavenet_A = "en-US-Wavenet-A",
        en_US_Wavenet_B = "en-US-Wavenet-B",
        en_US_Wavenet_D = "en-US-Wavenet-D",
        en_US_Wavenet_I = "en-US-Wavenet-I",
        en_US_Wavenet_J = "en-US-Wavenet-J"
    }
}

SRSSETTINGS.version = "0.0.1"

function SRSSETTINGS:_GetCurrentWeather(point)
    BASE:I(point)

    -- Get weather data from coordinate
    local tmp = point:GetTemperature()
    local press = point:GetPressure()
    local wD, wS = point:GetWind()
    -- BASE:I(string.format("Raw Data : %s, %s, %s, %s", tmp, press, wD, wS))

    -- convert values to imperial and then to strings
    tmp = string.format("%d", tmp)

    press = press * 0.0295299830714
    press = string.format("%.2f", press)
    press = string.gsub(press, "%p", "")

    wD = string.format("%03d", wD)
    wS = string.format("%02d", UTILS.MpsToKnots(wS))
    -- BASE:I(string.format("After stringify : %s, %s, %s, %s", tmp, press, wD, wS))

    -- replace 0 and 9 with zero and niner for speech
    tmp = self:_ConvertZeroNiner(tmp)
    press = self:_ConvertZeroNiner(press)
    wD = self:_ConvertZeroNiner(wD)
    wS = self:_ConvertZeroNiner(wS)
    -- BASE:I(string.format("After ZeroNiner : %s, %s, %s, %s", tmp, press, wD, wS))

    -- Build and return the table.
    local weatherTable = {
        Temp = tmp,
        Baro = press,
        WindDir = wD,
        WindSpd = wS
    }

    return weatherTable
end

function SRSSETTINGS:_ConvertZeroNiner(number)
    BASE:I(number)
    local ssmlText = tostring(number)
    ssmlText = string.gsub(ssmlText, "0", " zero ")
    ssmlText = string.gsub(ssmlText, "9", " niner ")
    return ssmlText
end

RESCUEHELOMSRS = {
    ClassName           = "RESCUEHELOMSRS",
    SRS                 = {},
    _commsEnabled       = true,
    _rescuing           = false,
    _rescueFreqs        = {},
    _rescueMods         = {},
    _rescueFreqsEmerg   = {},
    _rescueModsEmerg    = {}
}

RESCUEHELOMSRS.version = "0.0.1"

function RESCUEHELOMSRS:New(carrierUnit, heloGroupName, googleVoice, freqs, freqsEmerg, mods, modsEmerg, coal)
    -- Inherit all functionality of RESCUEHELO
    local self = BASE:Inherit(self, RESCUEHELO:New(carrierUnit, heloGroupName))

    -- Set up the frequencies used in both regular and rescue ops
    self._rescueFreqs = freqs
    self._rescueMods = mods
    self._rescueFreqsEmerg = freqsEmerg
    self._rescueModsEmerg = modsEmerg

    -- Add the MSRS functionality to this class.
    self.SRS = MSRS:New(SRSSETTINGS.MSRSExec, self._rescueFreqs, self._rescueMods)

    -- Create the extended version of the RESCUEHELOs current FSM events.
    self:AddTransition("*", "StartMSRS",     "*")
    self:AddTransition("*", "RunMSRS",       "*")
    self:AddTransition("*", "RTBMSRS",       "*")
    self:AddTransition("*", "RescueMSRS",    "*")
    self:AddTransition("*", "ReturnedMSRS",  "*")

    -- Finsh setting up MSRS
    self.SRS:SetGoogle(SRSSETTINGS.MRSRSGoogleCredsFile)
    self.SRS:SetVoice(googleVoice)
    self.SRS:SetCoalition(coal)

    return self
end

function RESCUEHELOMSRS:TurnCommsON()
    self._commsEnabled= true
    return self
end

function RESCUEHELOMSRS:TurnCommsOFF()
    self._commsEnabled= false
    return self
end

function RESCUEHELOMSRS:OnAfterRescue(From, Event, To, RescueCoord)
    self:T(From, Event, To)

    -- local msg = 
    --     "<speak>" ..
    --     "<emphasis level='high'>" ..
    --     "<break time='700ms'/>" ..
    --     "<s>Rescue 1</s> <s>On route to downed pilot.</s>" ..
    --     "<break time='700ms'/>" ..
    --     "<say-as interpret-as='expletive'>Jesus christ</say-as>" ..
    --     "<s>What's going on!</s>" ..
    --     "</emphsis>" ..
    --     "</speak>"

    -- Rescue helo is being sent to rescue a downed pilot.  Set the _rescuing flag
    -- and send the SRS msg.
    self._rescuing = true

    local msg = 
        "<speak>" ..
        "<emphasis level='high'>" ..
        "<break time='700ms'/>" ..
        "<s>Rescue 1</s> <s>99 all aircraft, signal delta.</s>" ..
        "</emphsis>" ..
        "</speak>"

    self:_SendComms(msg)

    -- Trigger the extended event to be used by mission devs.
    self:__RescueMSRS(10)
end

function RESCUEHELOMSRS:OnAfterReturned(From, Event, To, airbase)
    self:T(From, Event, To)

    local msg = 
        "<speak>" ..
        "<emphasis level='low'>" ..
        "<break time='700ms'/>" ..
        "<s>Rescue 1</s> <s>is down and out.</s>" ..
        "</emphsis>" ..
        "</speak>"

    self:_SendComms(msg)

    -- Trigger the extended event to be used by mission devs.
    self:__ReturnedMSRS(10)
end

function RESCUEHELOMSRS:OnAfterRTB(From, Event, To, airbase)
    self:T(From, Event, To)

    local msg = 
        "<speak>" ..
        "<emphasis level='low'>" ..
        "<break time='700ms'/>" ..
        "<s>Rescue 1</s> <s>is low on fuel and requesting RTB.</s>" ..
        "</emphsis>" ..
        "</speak>"

    -- Delay the radio call to time it with the sim.
    self:_SendComms(msg)
    -- TIMER:New(RESCUEHELOMSRS._SendComms, self, msg):Start(120)

    -- Trigger the extended event to be used by mission devs.
    self:__RTBMSRS(10)
end

function RESCUEHELOMSRS:OnAfterStart(From, Event, To)
    self:T(From, Event, To)


    local msg = 
        "<speak>" ..
        "<emphasis level='low'>" ..
        "<break time='700ms'/>" ..
        "<s>Recsue 1.</s> <s>Running up.</s>" ..
        "</emphsis>" ..
        "</speak>"

    -- Delay the radio call to time it with the sim.
    TIMER:New(RESCUEHELOMSRS._SendComms, self, msg):Start(60)

    local msg2 = 
        "<speak>" ..
        "<emphasis level='high'>" ..
        "<break time='700ms'/>" ..
        "<s>Recsue 1</s> <s>lifting off.</s>" ..
        "</emphsis>" ..
    "</speak>"

    -- Delay the radio call to time it with the sim.
    TIMER:New(RESCUEHELOMSRS._SendComms, self, msg2):Start(200)

    local msg3 = 
        "<speak>" ..
        "<emphasis level='high'>" ..
        "<break time='700ms'/>" ..
        "<s>Recsue 1</s> <s>On station</s>" ..
        "</emphsis>" ..
    "</speak>"

    -- Delay the radio call to time it with the sim.
    TIMER:New(RESCUEHELOMSRS._SendComms, self, msg3):Start(330)

    -- Trigger the extended event to be used by mission devs.
    self:__StartMSRS(10)
end

function RESCUEHELOMSRS:OnAfterRun(From, Event, To)
    self:T(From, Event, To)

    local msg = 
        "<speak>" ..
        "<emphasis level='low'>" ..
        "<break time='700ms'/>" ..
        "<s>Rescue 1</s> <s>is down and out.</s>" ..
        "</emphsis>" ..
        "</speak>"

    self:_SendComms(msg)

    -- Trigger the extended event to be used by mission devs.
    self:__RunMSRS(10)
end

function RESCUEHELOMSRS:_SendComms(msg)
    self:F()
    -- If cooms are enabled for RESCUEHELOMSRS then check if the helo was sent to rescue.
    -- If so, change the freqs and modulations to the simulcast freqs and mods.
    -- Send the msg.
    -- Then reset the _rescuing flag to false so that subsequent comms are sent normally
    -- and not simulcast.
    if self._commsEnabled then
        if self._rescuing then
            self.SRS:SetFrequencies(self._rescueFreqsEmerg)
            self.SRS:SetModulations(self._rescueModsEmerg)
        else
            self.SRS:SetFrequencies(self._rescueFreqs)
            self.SRS:SetModulations(self._rescueMods)
        end
        self.SRS:PlayText(msg)
        self._rescuing = false
    else
        self:E("Comms are disabled. RANGEMSRS._commsEnabled= false.")
    end
end



RANGEMSRS = {
    ClassName       = "RANGEMSRS",
    SRS             = {},
    _commsEnabled   = true,
    EnterRangeFlag  = false,
    ExitRangeFlag   = false,
    
    CurrentWX       = {
                        WindSpd = nil,
                        WindDir = nil,
                        Temp = nil,
                        Baro = nil
    },
}

RANGEMSRS.version = "0.0.1"

function RANGEMSRS:New(rangeName, googleVoice, freq, mod, coal)
    -- Inherit all funtionality of RANGE
    local self = BASE:Inherit(self, RANGE:New(rangeName))

    self.SRS = MSRS:New(SRSSETTINGS.MSRSExec, freq, mod)

    self:AddTransition("*", "EnterRangeMSRS", "*")
    self:AddTransition("*", "ExitRangeMSRS", "*")

    self.SRS:SetGoogle(SRSSETTINGS.MRSRSGoogleCredsFile)
    self.SRS:SetVoice(googleVoice)
    self.SRS:SetCoalition(coal)

    return self
end

function RANGEMSRS:TurnCommsON()
    self._commsEnabled= true
    return self
end

function RANGEMSRS:TurnCommsOFF()
    self._commsEnabled= false
    return self
end

function RANGEMSRS:SendCurrentWX()
    -- Make sure we have valid weather data. DCS weather never changes in the mission,
    -- so this only needs to be called once the first time it's needed.
    if self.CurrentWX.WindSpd == nil then
        local zonePoint = self.rangezone:GetCoordinate()
        -- BASE:I("Zone Point : " .. zonePoint)
        self.CurrentWX = SRSSETTINGS:_GetCurrentWeather(zonePoint)
        BASE:I(self.CurrentWX.WindSpd)
    end

    local msg1 = 
        "<speak>" ..
        "<s><break time='700ms'/>Standby for range weather conditions.</s>" ..
        "<speak>"

    local msg2 = string.format(
        "<speak>" ..
        "<emphasis level='medium'>" ..
        "<break time='700ms'/><s>Current weather:</s> " ..
        "<break time='700ms'/> <s>Winds are %s knots,</s> <s>at %s.</s> " ..
        "<break time='500ms'/> <s>Temperature %s.</s> " ..
        "<break time='500ms'/> <s>Altimeter %s.</s> " ..
        "<break time='1000ms'/> <s>Contact the range boss on 2 5 1 decimal 5</s> " ..
        "</emphsis>" ..
        "</speak>",
        self.CurrentWX.WindSpd, self.CurrentWX.WindDir, self.CurrentWX.Temp, self.CurrentWX.Baro)

    -- Send first msg immediately to notify pilots of a weather report. Then  delay the second one for a short period of time.
    self:_SendComms(msg1)
    TIMER:New(RANGEMSRS._SendComms, self, msg2):Start(10)
    
end

function RANGEMSRS:OnAfterEnterRange(From, Event, To, player)
    self:F()

    -- In order to not get multiple audio calls when a group flight enters the range,
    -- we set a flag to signal a flight is has entered which will stop any further
    -- radio calls. Then a timer is created to fire 60secs later to reset this flag
    -- and allow the enter range radio call for the next flight that enters.
    if self.EnterRangeFlag then
        
        -- Trigger the event that is called by the missions builders
        self:__EnterRangeMSRS(2, player)
    
    else
        self.EnterRangeFlag = true
        EnterTimer = TIMER:New(RANGEMSRS._ResetEnterRangeFlag, self)
        EnterTimer:Start(240)

        local msg = 
            "<speak>" ..
            "<emphasis level='medium'>" ..
            "<break time='700ms'/>" ..
            "<s>Attention all flights, another aircraft has entered the range airspace.</s>" ..
            "</emphsis>" ..
            "</speak>"

        -- Acknowledge someone has entered the range and send out a delayed
        -- weather report.
        self:_SendComms(msg)
        TIMER:New(RANGEMSRS.SendCurrentWX, self):Start(10)

        -- Trigger the event that is called by the missions builders
        self:__EnterRangeMSRS(2, player)
    end
end

function RANGEMSRS:OnAfterExitRange(From, Event, To, player)
    self:F()
    
    if self.ExitRangeFlag then
        
        BASE:I("TRUE - falling through")
        self:__ExitRangeMSRS(2, player)

    else
        BASE:I("FALSE - setting flag.")
        self.ExitRangeFlag = true
        ExitTimer = TIMER:New(RANGEMSRS._ResetExitRangeFlag, self)
        ExitTimer:Start(120)

        local msg = 
            "<speak>" ..
            "<emphasis level='medium'>" ..
            "<s><break time='500ms'/>You are leaving my airspace.</s> <s>Have a safe flight.</s>" ..
            "</speak>"

        self:_SendComms(msg)

        self:__ExitRangeMSRS(2, player)
    end
end

function RANGEMSRS:_SendComms(msg)
    self:F()
    if self._commsEnabled then
        self.SRS:PlayText(msg)
    else
        self:E("Comms are disabled. RANGEMSRS._commsEnabled= false.")
    end
end

function RANGEMSRS:_ResetEnterRangeFlag()
    self.EnterRangeFlag = false
end

function RANGEMSRS:_ResetExitRangeFlag()
    self.ExitRangeFlag = false
end

