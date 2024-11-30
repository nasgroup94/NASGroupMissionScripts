-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('CSAR')
-- BASE:TraceClass('POSITIONABLE')
-- BASE:TraceClass('SOUNDFILE')
-- BASE:TraceClass('SET_CLIENT')
BASE:I("Marianas-2022_csar_ctld.lua | Loading...")


-- Specific settings
CSAR_CLIENT_SET = SET_CLIENT
    :New()
    :FilterCoalitions("blue")
    :FilterCategories("helicopter")
    :FilterActive()
    :FilterStart()
CSAR_CLIENT_SET:HandleEvent(EVENTS.PlayerEnterAircraft)

    --[[ -- List of Google voices
    Google Voices
    https://cloud.google.com/text-to-speech/docs/voices
]]
local GoogleVoices = {
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

local SRSExec                = "C:\\Progra~1\\DCS-SimpleRadio-Standalone" -- path tot SRS
local SRSGoogleCredsFile     = "C:/VNAO/API-Keys/cvw7-tracking-11c8a6927776.json"

local rescueRadioSettings = {
    Freqs = {243},
    Mods  = {radio.modulation.AM}
}

-- Used for all the dynamic Google TTS audio calls that need to be created on the fly
local rescueSRS = MSRS:New(SRSExec, rescueRadioSettings.Freqs, rescueRadioSettings.Mods) -- Send on freq 243 AM
rescueSRS:SetGoogle(SRSGoogleCredsFile)
rescueSRS:SetCoalition(2) -- 0 = neutral, 1 = red, 2 = blue

-- Used for all the prerecorded Google TTS MP3 files
local rescueSRSFile = MSRS:New(SRSExec, rescueRadioSettings.Freqs, rescueRadioSettings.Mods)
rescueSRSFile:SetCoalition(2)

-- commCallFlags["rescueUnitOne"].CP_RTB.FLAG = false
-- commCallFlags["rescueUnitOne"].CP_RTB.TIME = now()
local commCallFlags = {
    -- NAVSAR
    NS_Mayday = {
        FLAG = false,
        TIME = nil
    },

    -- Copilot
    CP_RTB = {
        FLAG = false,
        TIME = nil
    },

    -- Downed Crewman
    DC_HearYou = {
        FLAG = false,
        TIME = nil
    },
    DC_Visual = {
        FLAG = false,
        TIME = nil
    },

    -- Stranded Sailor
    SS_Distress = {
        FLAG = false,
        TIME = nil,
    },
    SS_Flare = {
        FLAG = false,
        TIME = nil,
    },

    -- Flight Engineers
    FE_Tally = {
        FLAG = false,
        TIME = nil
    },
    FE_Swimmer = {
        FLAG = false,
        TIME = nil
    },
    FE_Basket = {
        FLAG = false,
        TIME = nil
    },
    FE_Clear = {
        FLAG = false,
        TIME = nil
    },
    FE_Rescued = {
        FLAG = false,
        TIME = nil
    },
    FE_Over = {
        FLAG = false,
        TIME = nil
    },
    FE_Off = {
        FLAG = false,
        TIME = nil
    }
}

local rescueSpawnRadius = 50 -- nautical miles
local rescueHoverHeight = UTILS.FeetToMeters(100) -- meters
local rescueHoverDistance = 10 -- meters
local rescudeLoadDistance = 10 -- meters
local rescueFARPRescueDistance = 500 -- meters
local rescueExtractDistance = 500 -- meters
local rescueAutoSmokeDistance = 5000 -- meters
local rescueMinDistUnit = 25000
local rescueApproachDistFar = 23000 -- switch to far interval approach mode, meters
local rescueApproachDistNear = 5000 -- switch to near interval approach mode, meters
local rescueApproachDistFarInt = 20
local rescueApproachDistNearInt = 5
local rescueSmokeColor = 3 -- orange
local rescueHoverTime = 30
local mashPrefixes = {"MASH", "Mash"}
local csarPrefixes = {"HSM", "WHIPLASH", "VERTREP", "PAGAN", "HUEY", "RESCUEHELO"}

-------------------------------------------- CSAR -------------------------------------------------------------

-- Helper functions
local function randomZoneCoord(zone, surfaceType)
    local correctSurfaceType = false
    local randomVec2 = nil
    local randomCoord = nil
    local rescueZone = nil
    
    local zoneType = type(zone)

    if zoneType == "table" then
        rescueZone = zone
    elseif zoneType == "string" then
        rescueZone = ZONE:FindByName(zone)
    else
        return nil
    end

    -- If a surface type is supplied, find a coordinate that is of the correct surface type,
    -- otherwise, just return the first coordinate found.
    if surfaceType ~= nil then
        while not correctSurfaceType do
            math.random()
            math.random()
            randomVec2 = rescueZone:GetRandomVec2()
            randomCoord = COORDINATE:NewFromVec2(randomVec2)

            if randomCoord:GetSurfaceType() == surfaceType then
            correctSurfaceType = true
            end
        end
    else
        math.random()
        math.random()
        randomVec2 = rescueZone:GetRandomVec2()
    end

    return randomVec2
end

-- supplied character A returns Alpha
-- supplied character 9 returns 9
local function getPhonetic(char)
    local _char = char
    local _returnVal = char

    -- local _phonetic = {
    --     A = "Alpha",
    --     B = "Bravo",
    --     C = "Charlie",
    --     D = "Delta",
    --     E = "Echo",
    --     F = "Foxtrot",
    --     G = "Gulf",
    --     H = "Hotel",
    --     I = "India",
    --     J = "Julliet",
    --     K = "Kilo",
    --     L = "Lima",
    --     M = "Mike",
    --     N = "November",
    --     O = "Oscar",
    --     P = "Papa",
    --     Q = "Quebec",
    --     R = "Romeo",
    --     S = "Sierra",
    --     T = "Tango",
    --     U = "Uniform",
    --     V = "Victor",
    --     W = "Whiskey",
    --     X = "X-ray",
    --     Y = "Yankee",
    --     Z = "Zulu",
    -- }

    for letter, phonetic in pairs(ENUMS.Phonetic) do
        if string.upper(letter) == string.upper(char) then
            _returnVal = string.upper(phonetic)
        end
    end

    return _returnVal
end

-- MGRS coord  - 37T GH 25202 42563
-- Result      - 3. 7. Tango. Golf. Hotel. 2, 5, 2, 0. 4, 2, 5, 6.
function MgrsTextForTTS(text)
    local _text = text

    -- remove 'MGRS' from the string
    _text = _text:sub(6)

    local _splitString = UTILS.Split(_text, " ")
    local _returnString = ""

    -- trim mgrs coords to 4 characters
    _splitString[3] = _splitString[3]:sub(1, -2)
    _splitString[4] = _splitString[4]:sub(1, -2)

    -- for each char in the mgrs coor, build up the return string
    for _, chars in pairs(_splitString) do
        for i = 1, #chars do
            local char = tostring(chars:sub(i,i))
            _returnString = _returnString .. getPhonetic(char) .. ". "
        end
    end

    return _returnString
end

function LatLonForTTS(unit)
    local unitCoord = unit:GetCoordinate()

    local lat, lon, alt = unitCoord:GetLLDDM()



end

local function generateCallSign()
    math.random()
    math.random()
    math.random()

    local callsigns = {
        "Enfield",
        "Springfield",
        "Uzi",
        "Colt",
        "Dodge",
        "Ford",
        "Chevy",
        "Pontiac",
        "Viper",
        "Venom",
        "Lobo",
        "Cowboy",
        "Python",
        "Rattler",
        "Panther",
        "Wolf",
        "Weasel",
        "Wild",
        "Ninja",
        "Jedi",
        "Hornet",
        "Squid",
        "Ragin",
        "Roman",
        "Sting",
        "Jury",
        "Jokey",
        "Ram",
        "Hawk",
        "Devil",
        "Check",
        "Snake",
        "Dude",
        "Thud",
        "Gunny",
        "Trek",
        "Sniper",
        "Sled",
        "Best",
        "Jazz",
        "Rage",
        "Tahoe"
    }

    local callsignNameIdx = math.random(#callsigns)
    local callSignIdx = tostring(math.random(4))
    local callsignNum = tostring(math.random(4))

    return string.format("%s %s %s", callsigns[callsignNameIdx], callSignIdx, callsignNum)

end

local function generateShipname()
    math.random()
    math.random()
    math.random()

    local shipnames = {
        "Arabella",
        "Dandy Charlotte",
        "Genesis Star",
        "Skyline Lift",
        "Borneo Prince",
        "Denali Tempest",
        "Liparus",
        "Misery Dawn",
        "Sea Tiger",
        "Tequila Sunrise",
        "Erebus Rising",
        "Mallard Trench",
        "Iron Hand",
        "Sparrowhawk",
        "Montezuma's Revenge",
    }

    local shipnameIdx = math.random(#shipnames)

    return string.format("%s", shipnames[shipnameIdx])
end

googleTTSSoundPath = "C:/vnao/sound/csar/"
googleTTSCSARMsgs = {
    Copilot = {
        Embark = SOUNDFILE:New("csar_copilot_embark.ogg", googleTTSSoundPath, 2),
        Return = SOUNDFILE:New("csar_copilot_rtb.ogg", googleTTSSoundPath, 4),
    },
    FlightEngineer = {
        Tally = SOUNDFILE:New("csar_flteng_tally.ogg", googleTTSSoundPath, 2),
        Swimmer = SOUNDFILE:New("csar_flteng_swimmer.ogg", googleTTSSoundPath, 2),
        Basket = SOUNDFILE:New("csar_flteng_basket.ogg", googleTTSSoundPath, 2),
        Medic = SOUNDFILE:New("csar_flteng_medic.ogg", googleTTSSoundPath, 2),
        Penetrator = SOUNDFILE:New("csar_flteng_penetrator.ogg", googleTTSSoundPath, 2),
        Off = SOUNDFILE:New("csar_flteng_off.ogg", googleTTSSoundPath, 2),
        Over = SOUNDFILE:New("csar_flteng_over.ogg", googleTTSSoundPath, 1),
        ClearMedic = SOUNDFILE:New("csar_flteng_clear_medic.ogg", googleTTSSoundPath, 4),
        ClearSwimmer = SOUNDFILE:New("csar_flteng_clear_swimmer.ogg", googleTTSSoundPath, 4),
        Rescued = SOUNDFILE:New("csar_flteng_rescued.ogg", googleTTSSoundPath, 3),
        ComeForward = SOUNDFILE:New("csar_flteng_come_fwd.ogg", googleTTSSoundPath, 1),
        ComeBackwards = SOUNDFILE:New("csar_flteng_come_aft.ogg", googleTTSSoundPath, 1),
        ComeLeft = SOUNDFILE:New("csar_flteng_come_left.ogg", googleTTSSoundPath, 1),
        ComeRight = SOUNDFILE:New("csar_flteng_come_right.ogg", googleTTSSoundPath, 1),
        Height05 = SOUNDFILE:New("csar_flteng_height_5.ogg", googleTTSSoundPath, 2),
        Height10 = SOUNDFILE:New("csar_flteng_height_10.ogg", googleTTSSoundPath, 2),
        Height20 = SOUNDFILE:New("csar_flteng_height_20.ogg", googleTTSSoundPath, 2),
        Height30 = SOUNDFILE:New("csar_flteng_height_30.ogg", googleTTSSoundPath, 2),
        Height40 = SOUNDFILE:New("csar_flteng_height_40.ogg", googleTTSSoundPath, 2),
        Height50 = SOUNDFILE:New("csar_flteng_height_50.ogg", googleTTSSoundPath, 2),
        Height60 = SOUNDFILE:New("csar_flteng_height_60.ogg", googleTTSSoundPath, 2),
        Height70 = SOUNDFILE:New("csar_flteng_height_70.ogg", googleTTSSoundPath, 2),
        Height80 = SOUNDFILE:New("csar_flteng_height_80.ogg", googleTTSSoundPath, 2),
    },
    DownedPilotNavsarMessages = {
        Voice = GoogleVoices.Female.en_US_Standard_F,
        Mayday = "<speak>" ..
                    "<emphasis level='moderate'>" ..
                    "<prosody rate='medium' pitch='+3st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='1200ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Nav-sar indicates downed aircrew requiring immediate assistance in the vicinity of the following nav grid coordinates.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='700ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Standby.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='1800ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>The following coordinates are.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='700ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='slow' pitch='+2st' volume='soft'>%s</prosody>" ..
                    "</emphasis>" ..
                    "<break time='1300ms'/>" ..
                    "<emphasis level='none'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Priority. Scramble rescue 1 is authorized!</prosody>" ..
                    "</emphasis>" ..
                    "</speak>",
    },
    DownedPilotMessages = {
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_A,
            HearYou =  "<speak>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='fast' pitch='+3st' volume='x-soft'>Rescue One, %s Alpha. I hear you!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1300ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>Authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='slow' pitch='+2st' volume='x-soft'>Whiskey. Tango. Foxtrot.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='medium'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>L Z is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='700ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>I'll pop smoke once I see you.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>Rescue One, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>Visual!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1800ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>I'm two meters south of the orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1100ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='+1st' volume='x-soft'>Land or hover by my marker.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_B,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='x-fast' pitch='-3st' volume='x-soft'>Rescue One, %s Alpha. I think I can hear you.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Juliet. India. Tango.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>Area is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='900ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>I'll be using my smoke marker once I have a visual on you.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='x-fast' pitch='-4st' volume='x-soft'>Rescue One, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-3st' volume='x-soft'>Okay. I see you now.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1800ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'm three meters east of my orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1100ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'm secure. Ready for pickup.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_I,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='slow' pitch='+3st' volume='x-soft'>Um. Rescue One.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1500ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='x-slow' pitch='+3st' volume='x-soft'>Um.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='700ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>%s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1200ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>I uh. I'm oh kay.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1400ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='x-slow' pitch='+3st' volume='x-soft'>But. Umm.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1200ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='medium' pitch='+5st' volume='x-soft'>Need you to hurry.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='900ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='medium' pitch='+4st' volume='x-soft'>There's. Um. There's a lot of sharks here.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='3900ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='+3st' volume='x-soft'>I um, don't remember my authentication.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>It's like. Romeo.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>Um. Something.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2800ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='+5st' volume='x-soft'>Please hurry.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='+4st' volume='x-soft'>Rescue One, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='slow' pitch='+5st' volume='x-soft'>Awesome! I got you in sight!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='+5st' volume='x-soft'>It's about time!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1800ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='+4st' volume='x-soft'>I've popped orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1100ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='fast' pitch='+5st' volume='x-soft'>Get me outta here already!</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_J,
            HearYou = "<speak>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>Rescue won, Rescue won.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='300ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>%s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1000ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>I hear you getting closer.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1500ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Once I have you in sight, I will activate my marker.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='500ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Stand-by for authentication.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='3000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='700ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='-5st' volume='x-soft'>Sierra. Hotel. Bravo.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2200ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>My zone is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'll be standing buy.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='soft'>Rescue won, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='650ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='slow' pitch='-2st' volume='medium'>Contact!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='soft'>I've activated orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1500ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-3st' volume='soft'>I'm secured and ready.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
    },
    DownedPilotWaterMessages = {
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_A,
            HearYou =  "<speak>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='fast' pitch='+3st' volume='x-soft'>Rescue One, %s Alpha. I hear you!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1300ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>Authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='slow' pitch='+2st' volume='x-soft'>Whiskey. Tango. Foxtrot.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='medium'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>L Z is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='700ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>I'll pop smoke once I see you.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>Rescue One, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='+3st' volume='x-soft'>Visual!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1800ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='+2st' volume='x-soft'>I'm two meters south of the orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1100ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='+1st' volume='x-soft'>Land or hover by my marker.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_B,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='x-fast' pitch='-3st' volume='x-soft'>Rescue One, %s Alpha. I think I can hear you.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Juliet. India. Tango.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>Area is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='900ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>I'll be using my smoke marker once I have a visual on you.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='x-fast' pitch='-4st' volume='x-soft'>Rescue One, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='430ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-3st' volume='x-soft'>Okay. I see you now.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1800ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'm three meters east of my orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1100ms'/>" ..
                        "<emphasis level='reduced'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'm secure. Ready for pickup.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
        {
            Voice = GoogleVoices.Male.en_US_Wavenet_J,
            HearYou = "<speak>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>Rescue won, Rescue won.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='300ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>%s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1000ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>I hear you getting closer.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1500ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Once I have you in sight, I will activate my marker.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='500ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='x-soft'>Stand-by for authentication.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='3000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I authenticate.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='700ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='-5st' volume='x-soft'>Sierra. Hotel. Bravo.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2200ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-4st' volume='x-soft'>My zone is clear.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='x-soft'>I'll be standing buy.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
            Visual = "<speak>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='fast' pitch='-5st' volume='soft'>Rescue won, %s Alpha.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='650ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='slow' pitch='-2st' volume='medium'>Contact!</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='-5st' volume='soft'>I've activated orange smoke.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1500ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='fast' pitch='-3st' volume='soft'>I'm secured and ready.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>",
        },
    },
    StrandedSailorNavsarMessages = {
        Voice = GoogleVoices.Male.en_US_Wavenet_J,
        Mayday = "<speak>" ..
                    "<emphasis level='moderate'>" ..
                    "<prosody rate='medium' pitch='+3st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='1200ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Nav-sar has received an emergency distress call from a civilian vessel in the vicinity of the following nav grid coordinates.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='700ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Standby.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='2200ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>The following coordinates are.</prosody>" ..
                    "</emphasis>" ..
                    "<break time='700ms'/>" ..
                    "<emphasis level='reduced'>" ..
                    "<prosody rate='slow' pitch='+2st' volume='soft'>%s</prosody>" ..
                    "</emphasis>" ..
                    "<break time='1300ms'/>" ..
                    "<emphasis level='none'>" ..
                    "<prosody rate='medium' pitch='+2st' volume='soft'>Authorization for priority scramble of rescue 1 has been granted.</prosody>" ..
                    "</emphasis>" ..
                    "</speak>",
    },
    StrandedSailorMessages = {
        {
            Voice = GoogleVoices.Male.en_IN_Wavenet_B,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>This is.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='200ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>%s. %s. %s.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Position.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='0st' volume='soft'>North. 2 6. 1 6. 3 1. 6 5. East. 8 0. 0 6. 1 9. 9 3.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>We are taking on water. and sinking.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>5 souls on board.  We are abandoning vessel.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>I will mark position with signal flare.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Request immediate assistance.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>"
        },
        {
            Voice = GoogleVoices.Male.en_GB_Wavenet_B,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>This is.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='200ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>%s. %s. %s.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Position.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='0st' volume='soft'>North. 2 6. 1 6. 3 1. 6 5. East. 8 0. 0 6. 1 9. 9 3.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>We are taking on water. and sinking.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>5 souls on board.  We are abandoning vessel.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>I will mark position with signal flare.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Request immediate assistance.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>"
        },
        {
            Voice = GoogleVoices.Male.en_AU_Wavenet_B,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>This is.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='200ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>%s. %s. %s.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Position.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='0st' volume='soft'>North. 2 6. 1 6. 3 1. 6 5. East. 8 0. 0 6. 1 9. 9 3.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>We are taking on water. and sinking.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>5 souls on board.  We are abandoning vessel.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>I will mark position with signal flare.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Request immediate assistance.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>"
        },
        {
            Voice = GoogleVoices.Female.en_US_Standard_E,
            HearYou = "<speak>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday mayday mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>This is.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='200ms'/>" ..
                        "<emphasis level='moderate'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>%s. %s. %s.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Mayday.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='2000ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Position.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='400ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='slow' pitch='0st' volume='soft'>North. 2 6. 1 6. 3 1. 6 5. East. 8 0. 0 6. 1 9. 9 3.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1600ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>We are taking on water. and sinking.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>5 souls on board.  We are abandoning vessel.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='1900ms'/>" ..
                        "<emphasis level='none'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>I will mark position with signal flare.</prosody>" ..
                        "</emphasis>" ..
                        "<break time='800ms'/>" ..
                        "<emphasis level='strong'>" ..
                        "<prosody rate='medium' pitch='0st' volume='soft'>Request immediate assistance.</prosody>" ..
                        "</emphasis>" ..
                        "</speak>"
        },
    }
}

local function getHeightCall(heightDiff)
    local heightSoundFile = nil
    local height = ""
    if heightDiff <= 8 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height05
        height = "5ft"
    elseif heightDiff < 15 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height10
        height = "10ft"
    elseif heightDiff < 25 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height20
        height = "20ft"
    elseif heightDiff < 35 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height30
        height = "30ft"
    elseif heightDiff < 45 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height40
        height = "40ft"
    elseif heightDiff < 55 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height50
        height = "50ft"
    elseif heightDiff < 65 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height60
        height = "60ft"
    elseif heightDiff < 75 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height70
        height = "70ft"
    elseif heightDiff < 85 then
        heightSoundFile = googleTTSCSARMsgs.FlightEngineer.Height80
        height = "80ft"
    end

    return height, heightSoundFile
end

local function getDirectionCall(relativeBearing)
    local directionSoundFile = nil
    local direction = ""
    if relativeBearing > 315 then
        directionSoundFile = googleTTSCSARMsgs.FlightEngineer.ComeForward
        direction = "forward"
    elseif relativeBearing > 225 then
        directionSoundFile = googleTTSCSARMsgs.FlightEngineer.ComeLeft
        direction = "left"
    elseif relativeBearing > 135 then
        directionSoundFile = googleTTSCSARMsgs.FlightEngineer.ComeBackwards
        direction = "back"
    elseif relativeBearing > 45 then
        directionSoundFile = googleTTSCSARMsgs.FlightEngineer.ComeRight
        direction = "right"
    -- if relativeBearing <= 45 then
    else
        directionSoundFile = googleTTSCSARMsgs.FlightEngineer.ComeForward
        direction = "forward"
    end

    return direction, directionSoundFile
end
-- PILOT RESCUE ------------------------------------------------------------------------------------------
CSAR.RescueUnitsList = {}
CSAR.MessageQueueTimer = 0
-- CSAR.PickDownedCrewmanCommsIndex = 1
CSAR.GoogleTTSCSARMsgs = {}

function CSAR:PickMessagesForNavsar(woundedgroupname, rescueType)
    self:T(self.lid .. " PickMessagesForNavsar")
    self:T({rescueType = rescueType})

    local comms = nil
    if rescueType == "pilot" then
        comms = googleTTSCSARMsgs.DownedPilotNavsarMessages
    elseif rescueType == "ship" then
        comms = googleTTSCSARMsgs.StrandedSailorNavsarMessages
    end

    self.RescueUnitsList[woundedgroupname].RescueNavsarSRS:SetVoice(comms.Voice)

    return comms
end

function CSAR:PickMessagesForRescueUnit(woundedgroupname, rescueType, overWater)
    self:T(self.lid .. " PickMessagesForRescueUnit | ")
    self:T({woundedgroupname = woundedgroupname, rescueType = rescueType})
    
    math.random(); math.random(); math.random()
    local commCount = nil
    local randomInt = nil
    local comms = nil

    if rescueType == "pilot" then
        if overWater then
            commCount = #googleTTSCSARMsgs.DownedPilotWaterMessages
            randomInt = math.random(commCount)
            comms = googleTTSCSARMsgs.DownedPilotWaterMessages[randomInt]
            self:T({messages = googleTTSCSARMsgs.DownedPilotWaterMessages[randomInt]})
        else
            commCount = #googleTTSCSARMsgs.DownedPilotMessages
            randomInt = math.random(commCount)
            comms = googleTTSCSARMsgs.DownedPilotMessages[randomInt]
            self:T({messages = googleTTSCSARMsgs.DownedPilotMessages[randomInt]})
        end
    elseif rescueType == "ship" then
        commCount = #googleTTSCSARMsgs.StrandedSailorMessages
        randomInt = math.random(commCount)
        comms = googleTTSCSARMsgs.StrandedSailorMessages[randomInt]
        self:T({messages = googleTTSCSARMsgs.StrandedSailorMessages[randomInt]})
    end

    self:T({commCount = commCount, randomInt = randomInt})

    -- set the voice for the SRS comms
    self.RescueUnitsList[woundedgroupname].RescueUnitSRS:SetVoice(comms.Voice)

    return comms
end

function CSAR:messageQueueUpdateTimer(messageTime)
    self.MessageQueueTimer = self.MessageQueueTimer - messageTime
end

function CSAR:messageQueueSend(messageTime, functionToCall, ...)
    functionToCall(unpack(arg))
    TIMER:New(CSAR_PILOT.messageQueueUpdateTimer, self, messageTime):Start(messageTime)
end

function CSAR:messageQueueAddMsg(messageTime, groupName, functionToCall, ...)
    self:T(self.lid .. " messageQueueAddMsg")
    self:T({messageTime = messageTime})
    self:T({groupName = groupName})
    self:T({functionToCall = functionToCall})
    self:T({arg = arg})
    self:T({messageQueueTimer = self.MessageQueueTimer})
    if self.MessageQueueTimer <= 0 then
        -- send message immediately
        functionToCall(unpack(arg))
        TIMER:New(CSAR_PILOT.messageQueueUpdateTimer, self, messageTime):Start(messageTime)
    else
        -- send in queueTimer seconds
            TIMER:New(CSAR_PILOT.messageQueueSend, self, messageTime, functionToCall, unpack(arg)):Start(self.MessageQueueTimer)
    end
    
    self.MessageQueueTimer = self.MessageQueueTimer + messageTime
end

CSAR_PILOT = CSAR:New(coalition.side.BLUE,"MEDEVAC-PILOT","Downed Pilot")

-- options
CSAR_PILOT.immortalcrew = true -- downed pilot spawn is immortal
CSAR_PILOT.invisiblecrew = false -- downed pilot spawn is visible
CSAR_PILOT.mashprefix = mashPrefixes
CSAR_PILOT.csarPrefix = csarPrefixes
CSAR_PILOT.csarOncrash = true
CSAR_PILOT.csarOnEject = true
CSAR_PILOT.enableForAI = false
CSAR_PILOT.csarUsePara = false -- If set to true, will use the LandingAfterEjection Event instead of Ejection
CSAR_PILOT.pilotRuntoExtractPoint = true
CSAR_PILOT.extractDistance = rescueExtractDistance
CSAR_PILOT.loadDistance = rescudeLoadDistance
CSAR_PILOT.FARPRescueDistance = rescueFARPRescueDistance
CSAR_PILOT.rescuehoverheight = rescueHoverHeight
CSAR_PILOT.rescuehoverdistance = rescueHoverDistance
CSAR_PILOT.approachdist_far = rescueApproachDistFar
CSAR_PILOT.approachdist_near = rescueApproachDistNear
CSAR_PILOT.autosmoke = true -- automatically smoke a downed pilot\'s location when a heli is near.
CSAR_PILOT.autosmokedistance = rescueAutoSmokeDistance -- distance for autosmoke
CSAR_PILOT.smokecolor = rescueSmokeColor
CSAR_PILOT.suppressmessages = true

CSAR_PILOT.hoverTime = rescueHoverTime -- +/- 5 seconds
CSAR_PILOT.approachdist_far_interval = rescueApproachDistFarInt -- ROLLN EDIT - added
CSAR_PILOT.approachdist_near_interval = rescueApproachDistNearInt -- ROLLN EDIT - added
CSAR_PILOT.topmenuname = "CSAR - " .. CSAR_PILOT.alias

-- start the FSM
CSAR_PILOT:__Start(3)


--[[ Use this if you want life rafts for pilots spawned in the water.
 local PilotLifeRaftSpawn = SPAWN:New("LIFERAFT")

function CSAR_PILOT:OnBeforeAddPilot(From, Event, To, _position)
    -- trigger.action.outText("Pilot Rescue - OnBeforeAddPilot", 20)
    local spawnCoord = _position

    if spawnCoord:IsSurfaceTypeWater() then
        PilotLifeRaftSpawn:SpawnFromCoordinate(_position)
    end
end
--]]


function CSAR_PILOT:OnAfterApproach(From, Event, To, Heliname, Woundedgroupname)
    self:T(self.lid .. " OnAfterApproach")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})

    local heliUnit = UNIT:FindByName(Heliname)

    if heliUnit then
        local heliHeading = heliUnit:GetHeading()
        local heliUnitCoord = heliUnit:GetCoordinate()

        local woundedUnit = GROUP:FindByName(Woundedgroupname):GetUnits()[1]
        local woundedUnitCoord = woundedUnit:GetCoordinate()

        local overWater = woundedUnitCoord:IsSurfaceTypeWater()

        local distBetween = woundedUnitCoord:Get2DDistance(heliUnitCoord)
        local heightDiff = UTILS.MetersToFeet(heliUnitCoord:GetVec3().y - woundedUnitCoord:GetVec3().y) - 11

        local vectorWoundedUnit = heliUnitCoord:GetDirectionVec3(woundedUnitCoord)
        local bearingWoundedUnit =  UTILS.Round(woundedUnitCoord:GetAngleDegrees( vectorWoundedUnit ), 0)
        local relativeBearing = 360 - heliHeading + bearingWoundedUnit

        if relativeBearing > 360 then
            relativeBearing = relativeBearing - 360
        end
        -- trigger.action.outText(string.format("Heli: %s   Group: %s", heliUnit:GetName(), Woundedgroupname), 10)
        -- trigger.action.outText(string.format("Heli HDG: %d   BRG: %d   RelBRG: %d    DIS: %d    HGT: %d", heliHeading, bearingWoundedUnit, relativeBearing, distBetween, heightDiff), 10)

        self:T({distBetween = distBetween})
        self:T({heightDiff = heightDiff})
        self:T({bearingWoundedUnit = bearingWoundedUnit})
        self:T({relativeBearing = relativeBearing})
        

        -- Don't bother checking anything if distance greater than 20km.
        if distBetween < 20000 and
            self.RescueUnitsList[Woundedgroupname].CallFlags.NS_Mayday.FLAG then

            -- within the 10 meter hover distance and haven't called 'over' yet, call over target
            if distBetween <= rescueHoverDistance and
                not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

                self:T("Calling over target")
                self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Over:GetDuration(),
                                        Woundedgroupname,
                                        rescueSRSFile.PlaySoundFile,
                                        rescueSRSFile,
                                        googleTTSCSARMsgs.FlightEngineer.Over)
                self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG = true
            end

            -- oustisde the 10 meter distance and have previously called 'over' (was inside radius previously) call off target
            if distBetween > rescueHoverDistance and
                self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

                self:T("Calling off target")
                self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Off:GetDuration(),
                                        Woundedgroupname,
                                        rescueSRSFile.PlaySoundFile,
                                        rescueSRSFile,
                                        googleTTSCSARMsgs.FlightEngineer.Off)
                self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG = false
            end

            -- within in 20 meters enable the height calls
            if distBetween <= rescueHoverDistance * 2 then
                -- Give height call outs
                local height, heightSoundFile = getHeightCall(heightDiff)

                self:T(string.format("Calling height : %s", height))
                self:messageQueueAddMsg(heightSoundFile:GetDuration(),
                                        Woundedgroupname,
                                        rescueSRSFile.PlaySoundFile,
                                        rescueSRSFile,
                                        heightSoundFile)
            end

            -- call basket in the water
            -- within 20 meters, between 30 and rescueHoverHeight and swimmer was deployed
            if distBetween <= rescueHoverDistance * 2 and
                heightDiff <= rescueHoverHeight and
                self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG and
                not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Basket.FLAG then

                self:T("Calling basket")

                if overWater then
                    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Basket:GetDuration(),
                                            Woundedgroupname,
                                            rescueSRSFile.PlaySoundFile,
                                            rescueSRSFile,
                                            googleTTSCSARMsgs.FlightEngineer.Basket)
                    self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Basket.FLAG = true
                else
                    self:T("calling Medic")
                    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Medic:GetDuration(),
                                            Woundedgroupname,
                                            rescueSRSFile.PlaySoundFile,
                                            rescueSRSFile,
                                            googleTTSCSARMsgs.FlightEngineer.Medic)
                    self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Basket.FLAG = true
                end
            end

            -- within 20 meters
            if distBetween <= rescueHoverDistance * 2 and
                not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG then

                -- only call the swimmer if over water and under 25 feet
                if overWater and heightDiff <= 25 then
                    self:T("Calling swimmer")
                    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Swimmer:GetDuration(),
                                            Woundedgroupname,
                                            rescueSRSFile.PlaySoundFile,
                                            rescueSRSFile,
                                            googleTTSCSARMsgs.FlightEngineer.Swimmer)
                    self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG = true
                -- over land and under rescue height
                elseif not overWater and heightDiff <= rescueHoverHeight then
                    -- over land
                    self:T("Calling penetrator")
                    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Penetrator:GetDuration(),
                                            Woundedgroupname,
                                            rescueSRSFile.PlaySoundFile,
                                            rescueSRSFile,
                                            googleTTSCSARMsgs.FlightEngineer.Penetrator)
                    self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG = true
                end
            end

            -- within 30 meters, start calling out directions until over targert
            if distBetween <= rescueHoverDistance * 3 and
                not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

                -- Come forward, come back, come left come right
                local direction, directionSoundFile = getDirectionCall(relativeBearing)
                self:T(string.format("Calling direction : %s", direction))
                self:messageQueueAddMsg(directionSoundFile:GetDuration(),
                                        Woundedgroupname,
                                        rescueSRSFile.PlaySoundFile,
                                        rescueSRSFile,
                                        directionSoundFile)
            end

            -- -- smoke popped at 5km so call tally smnoke at 4.8km??? instead of time delay.
            -- if distBetween < 4800 and
            --     not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Tally.FLAG then

            --     self:T("Calling tally")
            --     self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Tally:GetDuration(),
            --                             Woundedgroupname,
            --                             rescueSRSFile.PlaySoundFile,
            --                             rescueSRSFile,
            --                             googleTTSCSARMsgs.FlightEngineer.Tally)
            --     self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Tally.FLAG = true
            -- end

            -- at 5km to target downed crewman calls visual
            if distBetween < 5000 and
                not self.RescueUnitsList[Woundedgroupname].CallFlags.DC_Visual.FLAG then

                self:T("Calling tally")
                self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Tally:GetDuration(),
                                        Woundedgroupname,
                                        rescueSRSFile.PlaySoundFile,
                                        rescueSRSFile,
                                        googleTTSCSARMsgs.FlightEngineer.Tally)
                self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Tally.FLAG = true

                self:T("Calling visual")
                self:messageQueueAddMsg(11,
                                        Woundedgroupname,
                                        self.RescueUnitsList[Woundedgroupname].RescueUnitSRS.PlayText,
                                        self.RescueUnitsList[Woundedgroupname].RescueUnitSRS,
                                        string.format(self.RescueUnitsList[Woundedgroupname].RescueUnitMessages.Visual,
                                                        self.RescueUnitsList[Woundedgroupname].Callsign))
                self.RescueUnitsList[Woundedgroupname].CallFlags.DC_Visual.FLAG = true
            end

            -- at 15 KM to target downed crewman calls I hear you
            if distBetween < 15000 and 
                not self.RescueUnitsList[Woundedgroupname].CallFlags.DC_HearYou.FLAG then

                self:T("Calling I hear you")
                self:messageQueueAddMsg(16,
                                        Woundedgroupname,
                                        self.RescueUnitsList[Woundedgroupname].RescueUnitSRS.PlayText,
                                        self.RescueUnitsList[Woundedgroupname].RescueUnitSRS,
                                        string.format(self.RescueUnitsList[Woundedgroupname].RescueUnitMessages.HearYou,
                                                        self.RescueUnitsList[Woundedgroupname].Callsign))
                self.RescueUnitsList[Woundedgroupname].CallFlags.DC_HearYou.FLAG = true
            end
        end
    end
end

function CSAR_PILOT:OnAfterBoarded(From, Event, To, Heliname, Woundedgroupname)
    self:T(self.lid .. " OnAfterBoarded")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})

    local woundedUnit = UNIT:FindByName(Heliname)
    local woundedUnitCoord = woundedUnit:GetCoordinate()

    local overWater = woundedUnitCoord:IsSurfaceTypeWater()

    if overWater then
        self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.ClearSwimmer:GetDuration(),
        Woundedgroupname,
        rescueSRSFile.PlaySoundFile,
        rescueSRSFile,
        googleTTSCSARMsgs.FlightEngineer.ClearSwimmer) 
    else
        self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.ClearMedic:GetDuration(),
        Woundedgroupname,
        rescueSRSFile.PlaySoundFile,
        rescueSRSFile,
        googleTTSCSARMsgs.FlightEngineer.ClearMedic)
    end
end

function CSAR_PILOT:OnAfterReturning(From, Event, To, Heliname, Woundedgroupname, IsAirPort)
    self:T(self.lid .. " OnAfterReturning")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})
    if self.RescueUnitsList[Woundedgroupname] ~= nil then
        if not self.RescueUnitsList[Woundedgroupname].CallFlags.CP_RTB.FLAG then
            self:messageQueueAddMsg(googleTTSCSARMsgs.Copilot.Return:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.Copilot.Return)
            self.RescueUnitsList[Woundedgroupname] = nil
        end
    end
end

function CSAR_PILOT:OnAfterRescued(From, Event, To, HeliUnit, HeliName, PilotsSaved)
    self:T(self.lid .. " OnAfterRescued")
    self:T({heliunit = HeliUnit, neliname = HeliName, pilotssaved = PilotsSaved})
    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Rescued:GetDuration(),
                            nil,
                            rescueSRSFile.PlaySoundFile,
                            rescueSRSFile,
                            googleTTSCSARMsgs.FlightEngineer.Rescued)
end

function CSAR_PILOT:OnAfterPilotDown(From, Event, To, Group, Frequency, Leadername, CoordinatesText)
    self:T(self.lid .. " OnAfterPilotDown | ")
    self:T({group = Group, frequency = Frequency, leadername = Leadername, coordinatetext = CoordinatesText})
    local groupName = Group:GetName()

    local woundedUnit = Group:GetUnits()[1]
    local woundedUnitCoord = woundedUnit:GetCoordinate()
    local overWater = false
    overWater = woundedUnitCoord:IsSurfaceTypeWater()
    self:T(self.lid .. "overWater: " .. tostring(overWater))

    self.RescueUnitsList[groupName] = {
        CallFlags = UTILS.DeepCopy(commCallFlags),
        Callsign = generateCallSign(),
        RescueUnitSRS = UTILS.DeepCopy(rescueSRS),
        RescueUnitMessages = nil,
        RescueNavsarSRS = UTILS.DeepCopy(rescueSRS),
        RescueNavsarMessages = nil,
    }

    self.RescueUnitsList[groupName].RescueUnitMessages = self:PickMessagesForRescueUnit(groupName, "pilot", overWater)
    self.RescueUnitsList[groupName].RescueNavsarMessages = self:PickMessagesForNavsar(groupName, "pilot")
    self:T({RescueNavsarMessages = self.RescueUnitsList[groupName].RescueNavsarMessages, RescueUnitMessages = self.RescueUnitsList[groupName].RescueUnitMessages})

    self:messageQueueAddMsg(50,
                            groupName,
                            self.RescueUnitsList[groupName].RescueNavsarSRS.PlayText,
                            self.RescueUnitsList[groupName].RescueNavsarSRS,
                            string.format(self.RescueUnitsList[groupName].RescueNavsarMessages.Mayday, MgrsTextForTTS(CoordinatesText)))

    self:messageQueueAddMsg(googleTTSCSARMsgs.Copilot.Embark:GetDuration(),
                            groupName,
                            rescueSRSFile.PlaySoundFile,
                            rescueSRSFile,
                            googleTTSCSARMsgs.Copilot.Embark)                            
    self.RescueUnitsList[groupName].CallFlags.NS_Mayday.FLAG = true

    -- Send message to Discord
    -- HypeMan.sendBotMessage(string.format("CSAR: Pilot down | Coord: %s | Freq: %.2f", CoordinatesText, Frequency))
    -- MESSAGE:New(string.format("Pilot down | Coord: %s | Freq: %.2f", CoordinatesText, Frequency), 30, "CSAR", true):ToAll()
end

function PilotRescue(group, rescueCount)
    for i = 1, rescueCount do
        -- create a zone around the group
        local randomeCoordinate = ZONE_GROUP
            :New(group:GetName(), group, UTILS.NMToMeters(rescueSpawnRadius))
            :GetRandomCoordinate(rescueMinDistUnit)
        
        local groupZone = ZONE_RADIUS:New(group:GetName() .. tostring(timer.getTime()), randomeCoordinate:GetVec2(), 10)

        CSAR_PILOT:SpawnCSARAtZone(groupZone, coalition.side.BLUE, "Downed pilot", false, false, "Aviator", "Aircraft", true)
    end
end


-- SHIP RESCUE ------------------------------------------------------------------------------------------

CSAR_SHIP = CSAR:New(coalition.side.BLUE,"MEDEVAC-SAILOR","Stranded Ship")

-- options
CSAR_SHIP.immortalcrew = true -- downed pilot spawn is immortal
CSAR_SHIP.invisiblecrew = false -- downed pilot spawn is visible
CSAR_SHIP.mashprefix = mashPrefixes
CSAR_SHIP.csarPrefix = csarPrefixes
CSAR_SHIP.csarOncrash = false
CSAR_SHIP.csarOnEject = false
CSAR_SHIP.enableForAI = false
CSAR_SHIP.csarUsePara = false -- If set to true, will use the LandingAfterEjection Event instead of Ejection
CSAR_SHIP.pilotRuntoExtractPoint = true
-- CSAR_SHIP.extractDistance = rescueExtractDistanceCSAR_PILOT.extractDistance = rescueExtractDistance
CSAR_SHIP.loadDistance = rescudeLoadDistance
CSAR_SHIP.FARPRescueDistance = rescueFARPRescueDistance
CSAR_SHIP.rescuehoverheight = rescueHoverHeight
CSAR_SHIP.rescuehoverdistance = rescueHoverDistance
CSAR_SHIP.autosmoke = false -- automatically smoke a downed pilot\'s location when a heli is near.
CSAR_SHIP.autosmokedistance = rescueAutoSmokeDistance -- distance for autosmoke
CSAR_SHIP.smokecolor = rescueSmokeColor
CSAR_SHIP.suppressmessages = true

CSAR_SHIP.hoverTime = rescueHoverTime -- +/- 5 seconds
CSAR_SHIP.approachdist_far = rescueApproachDistFar
CSAR_SHIP.approachdist_near = rescueApproachDistNear
CSAR_SHIP.approachdist_far_interval = rescueApproachDistFarInt -- ROLLN EDIT - added
CSAR_SHIP.approachdist_near_interval = rescueApproachDistNearInt -- ROLLN EDIT - added
CSAR_SHIP.topmenuname = "CSAR - " .. CSAR_SHIP.alias

-- start the FSM
CSAR_SHIP:__Start(2)

local RESCUE_SHIP_GROUPS = {"SHIP-SINK-TRAWLER", "SHIP-SINK-FISHING", "SHIP-SINK-OLD", "SHIP-SINK-TANKER-1"}
local SailorRescueSpawn = SPAWN:New(RESCUE_SHIP_GROUPS[math.random(1, #RESCUE_SHIP_GROUPS)])
                            :InitRandomizeTemplatePrefixes(RESCUE_SHIP_GROUPS)


local function deleteSinkingShip(_unit)
    _unit:Destroy()
end

function CSAR_SHIP:OnBeforeAddPilot(From, Event, To, _position)
    -- trigger.action.outText("Ship Rescue - OnBeforeAddPilot", 20)
    local spawnGroup = SailorRescueSpawn:SpawnFromCoordinate(_position)

    -- Delete the sinking ship after 59 mins but leave the life raft
    TIMER:New(deleteSinkingShip, spawnGroup:GetUnits()[2]):Start(3540)
end

function CSAR_SHIP:OnAfterApproach(From, Event, To, Heliname, Woundedgroupname)
    self:T(self.lid .. " OnAfterApproach")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})

    local heliUnit = UNIT:FindByName(Heliname)
    local heliHeading = heliUnit:GetHeading()
    local heliUnitCoord = heliUnit:GetCoordinate()

    local woundedUnit = GROUP:FindByName(Woundedgroupname):GetUnits()[1]
    local woundedUnitCoord = woundedUnit:GetCoordinate()

    local overWater = woundedUnitCoord:IsSurfaceTypeWater()

    local distBetween = woundedUnitCoord:Get2DDistance(heliUnitCoord)
    local heightDiff = UTILS.MetersToFeet(heliUnitCoord:GetVec3().y - woundedUnitCoord:GetVec3().y) - 11

    local vectorWoundedUnit = heliUnitCoord:GetDirectionVec3(woundedUnitCoord)
    local bearingWoundedUnit =  UTILS.Round(woundedUnitCoord:GetAngleDegrees( vectorWoundedUnit ), 0)
    local relativeBearing = 360 - heliHeading + bearingWoundedUnit

    if relativeBearing > 360 then
        relativeBearing = relativeBearing - 360
    end
    -- trigger.action.outText(string.format("Heli: %s   Group: %s", heliUnit:GetName(), Woundedgroupname), 10)
    -- trigger.action.outText(string.format("Heli HDG: %d   BRG: %d   RelBRG: %d    DIS: %d    HGT: %d", heliHeading, bearingWoundedUnit, relativeBearing, distBetween, heightDiff), 10)

    self:T({distBetween = distBetween})
    self:T({heightDiff = heightDiff})
    self:T({bearingWoundedUnit = bearingWoundedUnit})
    self:T({relativeBearing = relativeBearing})

    -- Don't bother checking anything if distance greater than 20km.
    if distBetween < 20000 and
        self.RescueUnitsList[Woundedgroupname].CallFlags.NS_Mayday.FLAG then
        
             -- within the 10 meter hover distance and haven't called 'over' yet, call over target
        if distBetween <= rescueHoverDistance and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

            self:T("Calling over target")
            self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Over:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.FlightEngineer.Over)
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG = true
        end

        -- oustisde the 10 meter distance and have previously called 'over' (was inside radius previously) call off target
        if distBetween > rescueHoverDistance and
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

            self:T("Calling off target")
            self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Off:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.FlightEngineer.Off)
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG = false
        end

        -- calling heights
        -- within in 20 meters enable the height calls
        if distBetween <= rescueHoverDistance * 2 then
            -- Give height call outs
            local height, heightSoundFile = getHeightCall(heightDiff)

            self:T(string.format("Calling height : %s", height))
            self:messageQueueAddMsg(heightSoundFile:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    heightSoundFile)
        end

        -- call basket in the water
        -- within 20 meters, between 30 and rescueHoverHeight and swimmer was deployed
        if distBetween <= rescueHoverDistance * 2 and
            heightDiff <= rescueHoverHeight and
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Basket.FLAG then

            self:T("Calling basket")
            self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Basket:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.FlightEngineer.Basket)
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Basket.FLAG = true
        end

        -- call swimmer in the water
        -- within 20 meters and under 25 feet
        if distBetween <= rescueHoverDistance * 2 and
            heightDiff <= 25 and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG then

            self:T("Calling swimmer")
            self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Swimmer:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.FlightEngineer.Swimmer)
            self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Swimmer.FLAG = true
        end

        -- calling directions
        -- within 30 meters, start calling out directions until over targert
        if distBetween <= rescueHoverDistance * 3 and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.FE_Over.FLAG then

            -- Come forward, come back, come left come right
            local direction, directionSoundFile = getDirectionCall(relativeBearing)
            self:T(string.format("Calling direction : %s", direction))
            self:messageQueueAddMsg(directionSoundFile:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    directionSoundFile)
        end

        -- firing flare
        -- within 5km signal flare.
        if distBetween < 5000 and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.SS_Flare.FLAG then
            -- trigger.action.outText(string.format("Signaling flare at %d o'clock", self:_GetClockDirection(heliUnit, woundedUnit)),20)
            
            self:T("Firing Signal Flare")
            woundedUnit:GetCoordinate():FlareRed()

            self.RescueUnitsList[Woundedgroupname].CallFlags.SS_Flare.FLAG = true
        end

        -- call ship mayday
        -- 15km call 
        if distBetween < 20000 and
            not self.RescueUnitsList[Woundedgroupname].CallFlags.SS_Distress.FLAG then
            
            -- Message is 
            self:T("Calling ship distress")
            self:messageQueueAddMsg(30,
                                    Woundedgroupname,
                                    self.RescueUnitsList[Woundedgroupname].RescueUnitSRS.PlayText,
                                    self.RescueUnitsList[Woundedgroupname].RescueUnitSRS,
                                    string.format(self.RescueUnitsList[Woundedgroupname].RescueUnitMessages.HearYou,
                                                    self.RescueUnitsList[Woundedgroupname].ShipName,
                                                    self.RescueUnitsList[Woundedgroupname].ShipName,
                                                    self.RescueUnitsList[Woundedgroupname].ShipName))

            self.RescueUnitsList[Woundedgroupname].CallFlags.SS_Distress.FLAG = true
        end
    end
end

function CSAR_SHIP:OnAfterBoarded(From, Event, To, Heliname, Woundedgroupname)
    self:T(self.lid .. " OnAfterBoarded")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})
    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.ClearSwimmer:GetDuration(),
                            Woundedgroupname,
                            rescueSRSFile.PlaySoundFile,
                            rescueSRSFile,
                            googleTTSCSARMsgs.FlightEngineer.ClearSwimmer)
                            
end

function CSAR_SHIP:OnAfterReturning(From, Event, To, Heliname, Woundedgroupname, IsAirPort)
    self:T(self.lid .. " OnAfterReturning")
    self:T({heliname = Heliname, woundedgroupname = Woundedgroupname})
    if self.RescueUnitsList[Woundedgroupname] ~= nil then
        if not self.RescueUnitsList[Woundedgroupname].CallFlags.CP_RTB.FLAG then
            self:messageQueueAddMsg(googleTTSCSARMsgs.Copilot.Return:GetDuration(),
                                    Woundedgroupname,
                                    rescueSRSFile.PlaySoundFile,
                                    rescueSRSFile,
                                    googleTTSCSARMsgs.Copilot.Return)
            self.RescueUnitsList[Woundedgroupname] = nil
        end
    end
end

function CSAR_SHIP:OnAfterRescued(From, Event, To, HeliUnit, HeliName, PilotsSaved)
    self:T(self.lid .. " OnAfterRescued")
    self:T({heliunit = HeliUnit, neliname = HeliName, pilotssaved = PilotsSaved})
    self:messageQueueAddMsg(googleTTSCSARMsgs.FlightEngineer.Rescued:GetDuration(),
                            nil,
                            rescueSRSFile.PlaySoundFile,
                            rescueSRSFile,
                            googleTTSCSARMsgs.FlightEngineer.Rescued)
end

function CSAR_SHIP:OnAfterPilotDown(From, Event, To, Group, Frequency, Leadername, CoordinatesText)
    self:T(self.lid .. " OnAfterPilotDown")
    self:T({group = Group, frequency = Frequency, leadername = Leadername, coordinatetext = CoordinatesText})
    local groupName = Group:GetName()

    self.RescueUnitsList[groupName] = {
        CallFlags = UTILS.DeepCopy(commCallFlags),
        ShipName = generateShipname(),
        RescueUnitSRS = UTILS.DeepCopy(rescueSRS),
        RescueUnitMessages = nil,
        RescueNavsarSRS = UTILS.DeepCopy(rescueSRS),
        RescueNavsarMessages = nil,
    }
    self.RescueUnitsList[groupName].RescueUnitMessages = self:PickMessagesForRescueUnit(groupName, "ship")
    self.RescueUnitsList[groupName].RescueNavsarMessages = self:PickMessagesForNavsar(groupName, "ship")

    -- Message is 31 seconds long
    self:messageQueueAddMsg(40,
                            groupName,
                            self.RescueUnitsList[groupName].RescueNavsarSRS.PlayText,
                            self.RescueUnitsList[groupName].RescueNavsarSRS,
                            string.format(self.RescueUnitsList[groupName].RescueNavsarMessages.Mayday, MgrsTextForTTS(CoordinatesText)))

    self:messageQueueAddMsg(googleTTSCSARMsgs.Copilot.Embark:GetDuration(),
                            groupName,  
                            rescueSRSFile.PlaySoundFile,
                            rescueSRSFile,
                            googleTTSCSARMsgs.Copilot.Embark)
    self.RescueUnitsList[groupName].CallFlags.NS_Mayday.FLAG = true

     -- Send message to Discord
    --  HypeMan.sendBotMessage(string.format("CSAR: Ship in distress | Coord: %s | Freq: %.2f", CoordinatesText, Frequency))
    --  MESSAGE:New(string.format("Ship in distress | Coord: %s | Freq: %.2f", CoordinatesText, Frequency), 30, "CSAR", true):ToAll()
end


function SailorRescue(group, rescueCount)
    for i = 1, rescueCount do
        -- create a zone around the group
        local groupZone = ZONE_GROUP:New("SailorRescueGroup" .. tostring(os.time()), group, UTILS.NMToMeters(rescueSpawnRadius))

        local randomVec2 = randomZoneCoord(groupZone, land.SurfaceType.WATER)
        local zoneName = "SailorRescue" .. tostring(os.time())
        local randomZone = ZONE_RADIUS:New(zoneName, randomVec2, 30)

        CSAR_SHIP:SpawnCSARAtZone(randomZone, coalition.side.BLUE, "Sailor", false, false, "Mariner at sea", "Ship", true)
    end
end

-- Once a client enters a helicopter, build the spawn menus for this client.
function CSAR_CLIENT_SET:OnEventPlayerEnterAircraft(EventData)
    local eventData = EventData
    local unit = eventData.IniUnit
    local group = unit:GetGroup()

    -- Rescue Menus
    MENU_GROUP_COMMAND:New(group, "Spawn Downed Pilot ", TacticalHeloMenu, PilotRescue, group, 1):Refresh()
    MENU_GROUP_COMMAND:New(group, "Spawn Sinking Ship", TacticalHeloMenu, SailorRescue, group, 1):Refresh()
end


---------------------------------------------------- CTLD --------------------------------------------------------------

-- CTLD_FARPS_BUILT_SET = SET_STATIC:New():FilterPrefixes("BUILT"):FilterCoalitions("blue"):FilterStart()
CTLD_FARPS_BUILT = {}


-- Instantiate and start a CTLD for the blue side, using helicopter groups named "Helicargo" and alias "Lufttransportbrigade I"
local my_ctld = CTLD:New(coalition.side.BLUE, {"Rotary", "HSM", "Whiplash", "TEST-FARP"},"Lufttransportbrigade I")

my_ctld.dropcratesanywhere = true -- Option to allow crates to be dropped anywhere.
my_ctld.forcehoverload = false

my_ctld:AddCTLDZone("FARP-DALLAS-CTLD",CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
my_ctld:AddCTLDZone("FARP-ROME-CTLD",CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
my_ctld:AddCTLDZone("CVN73",CTLD.CargoZoneType.SHIP,SMOKECOLOR.Blue,true,false,330,60)
my_ctld:AddCTLDZone("Tarawa",CTLD.CargoZoneType.SHIP,SMOKECOLOR.Blue,true,false,240,20)
-- my_ctld:AddCTLDZone("CTLD-DROP-1",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
-- my_ctld:AddCTLDZone("CTLD-DROP-2",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
-- my_ctld:AddCTLDZone("CTLD-DROP-3",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)

-- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
-- my_ctld:AddCratesCargo("Forward Ops Base",{"CTLD-FOB"},CTLD_CARGO.Enum.FOB,1)
my_ctld:AddStaticsCargo("CTLD-FARP-DECOY")
my_ctld:AddCratesCargo("Farp Support Items", "CTLD-FARP-UNITS", CTLD_CARGO.Enum.VEHICLE, 1)

my_ctld.enableLoadSave = true -- allow auto-saving and loading of files
my_ctld.saveinterval = 120 -- save every 10 minutes
my_ctld.filename = "CTLD_objects.csv" -- example filename
my_ctld.filepath = "C:\\Users\\dcs\\Saved Games\\DCS.Warfighter\\Missions" -- example path
my_ctld.eventoninject = true -- fire OnAfterCratesBuild and OnAfterTroopsDeployed events when loading (uses Inject functions)

-- my_ctld:__Load(10)

-- my_ctld:__Start(5)

function my_ctld:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
    BASE:I("---------------------------------")
    BASE:I(Group)
    BASE:I(Unit)
    local table = Cargotable
    for _,_cargo in pairs (table) do
        BASE:I("----------- Looping cargo")
        -- count objects
        local cargo = _cargo -- Ops.CTLD#CTLD_CARGO
        local name = cargo:GetName()
        if string.find(name,"DECOY") then
            BASE:I("---------- Spawning FARP")
            local farpStatic = SPAWNSTATIC:NewFromStatic("CTLD-FARP-SINGLE")
                                        :InitFARP(1, 129.5, 0)
                                        :InitNamePrefix("CTLD-FARP-BUILT")
            local unitCoord = Unit:GetCoordinate()
            local unitHdg = Unit:GetHeading()
            local spawnCoord = unitCoord:Translate(50, unitHdg)
            farpStatic:SpawnFromCoordinate(spawnCoord, unitHdg)

            -- table.insert(CTLD_FARPS_BUILT,
        end
    end
    BASE:I("---------------------------------")
end

local function loadStatics()
    BASE:I("----------------------------------")
    BASE:I("Loading statics.")
    BASE:I("----------------------------------")
    local farpsToBuild = UTILS.LoadSetOfStatics("C:\\Users\\dcs\\Saved Games\\DCS.Warfighter\\Missions", "CTLD_built_farps.csv")
    BASE:I(mist.utils.tableShow(farpsToBuild))
end

function my_ctld:OnAfterLoad(From, Event, To, path, filename)
    TIMER:New(loadStatics):Start(60)
end

-- function CTLD_FARPS_BUILT_SET:OnAfterAdded(From, Event, To, staticName, staticObj)
--     BASE:I("----------------------OnAfterAdded  STATIC")
--     UTILS.SaveSetOfStatics(self, "C:\\Users\\dcs\\Saved Games\\DCS.openbeta\\Missions", "CTLD_built_farps.csv")
-- end

--    local testing = SPAWN:New("TestSpawn")
--                         :InitLimit(1,1)
--    testing:Spawn()
-- testing = nil
-- statics = SET_STATIC:New()
--                     :FilterPrefixes("MANPAD")
--                     :FilterOnce()



-- local function testSpawn()

--     for _, my_static in pairs(statics) do
--         -- local static_farp = STATIC:FindByName("MANPAD", true)
--         -- local spawn_coord = my_static:GetVec3()
--         BASE:I("-------------------------------------")
--         BASE:I(my_static)
--         BASE:I(my_static:GetVec3())
--         BASE:I(my_static.pointvec3)
--         BASE:I(my_static.coordinate)
--         BASE:I("-------------------------------------")
--         testing = SPAWN:New("FARPHELO")
--                         :InitLimit(1,1)
--         -- testing:SpawnFromPointVec3(spawn_coord)
--     end
-- end

-- TIMER:New(testSpawn):Start(5)

BASE:I("Marianas-2022_csar_ctld.lua | Loaded.")