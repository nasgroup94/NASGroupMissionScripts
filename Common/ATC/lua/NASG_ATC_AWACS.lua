NASG_ATC = NASG_ATC or {}
NASG_ATC_AWACS = NASG_ATC_AWACS or {}

NASG_ATC_AWACS.States = {
    AWACS_CONTROL = "AWACS_CONTROL",
}

NASG_ATC_AWACS.Requests = {
    radio_check = {
        Patterns = {
            "radio check",
            "comm check",
            "comms check",
        },
        Handler = "HandleRadioCheck",
    },

    say_again = {
        Patterns = {
            "say again",
            "repeat",
        },
    },

    awacs_check_in = {
        Patterns = {
            "checking in",
            "check in",
            "package check in",
            "on station",
        },
        Handler = "HandleCheckIn",
    },

    request_picture = {
        Patterns = {
            "picture",
            "request picture",
            "tactical picture",
        },
        Handler = "HandlePicture",
    },

    request_bogey_dope = {
        Patterns = {
            "bogey dope",
            "bogey-dope",
            "request bogey dope",
            "nearest threat",
        },
        Handler = "HandleBogeyDope",
    },

    request_vector_to_target = {
        Patterns = {
            "vector to target",
            "vectors to target",
            "target vector",
            "commit vector",
        },
        Handler = "HandleVectorToTarget",
    },

    request_vector_to_home_plate = {
        Patterns = {
            "vector home",
            "vectors home",
            "home plate",
            "vector to home plate",
        },
        Handler = "HandleVectorToHomePlate",
    },

    request_combat_recovery = {
        Patterns = {
            "combat recovery",
            "request recovery",
            "returning to base",
            "rtb",
            "request rtb",
        },
        Handler = "HandleCombatRecovery",
    },

    readback = {
        Patterns = {
            "picture",
            "bogey dope",
            "vector",
            "home plate",
            "proceed",
            "contact tower",
        },
        Handler = "HandleReadback",
    },
}

function NASG_ATC_AWACS:RegisterRequestPatterns(atc)
    local patternMap = {}

    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end

    atc:RegisterIntentPatterns(atc.Facilities.AWACS, patternMap)
end

function NASG_ATC_AWACS:Send(atc, airport, message)
    atc:SendFacilityTTS(airport, atc.Facilities.AWACS, message)
end

function NASG_ATC_AWACS:HandleRadioCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    self:Send(
            atc,
            airport,
            string.format("%s, %s, loud and clear.", callsign, atc:GetFacilityCallsign(airport, atc.Facilities.AWACS))
    )

    return true
end

function NASG_ATC_AWACS:HandleCheckIn(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local packageName = event.package or "package"

    session.State = atc.States.AWACS_CONTROL
    session.Facility = atc.Facilities.AWACS
    session.PackageName = packageName
    session.UpdatedAt = timer.getTime()

    self:Send(
            atc,
            airport,
            string.format(
                    "%s, %s, radar contact. Check in complete for %s.",
                    callsign,
                    atc:GetFacilityCallsign(airport, atc.Facilities.AWACS),
                    tostring(packageName)
            )
    )

    return true
end

function NASG_ATC_AWACS:HandlePicture(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.AWACS_CONTROL
    session.Facility = atc.Facilities.AWACS
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, picture clean. No factor traffic reported.", callsign))
    return true
end

function NASG_ATC_AWACS:HandleBogeyDope(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.AWACS_CONTROL
    session.Facility = atc.Facilities.AWACS
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, nearest group unavailable. Continue mission.json, report established.", callsign))
    return true
end

function NASG_ATC_AWACS:HandleVectorToTarget(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local heading = event.heading
    local range = event.range

    session.State = atc.States.AWACS_CONTROL
    session.Facility = atc.Facilities.AWACS
    session.UpdatedAt = timer.getTime()

    if heading and range then
        self:Send(
                atc,
                airport,
                string.format("%s, vector target heading %s, range %s.", callsign, tostring(heading), tostring(range))
        )
    else
        self:Send(atc, airport, string.format("%s, unable target vector. Continue present mission.json.", callsign))
    end

    return true
end

function NASG_ATC_AWACS:HandleVectorToHomePlate(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)

    session.State = atc.States.AWACS_CONTROL
    session.Facility = atc.Facilities.AWACS
    session.UpdatedAt = timer.getTime()

    self:Send(atc, airport, string.format("%s, proceed home plate.", callsign))
    return true
end

function NASG_ATC_AWACS:HandleCombatRecovery(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    local towerFrequency = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)
    local towerCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.TOWER)

    session.State = atc.States.INBOUND
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()

    if towerFrequency then
        self:Send(
                atc,
                airport,
                string.format("%s, proceed home plate. Contact %s %s for recovery.", callsign, towerCallsign, atc:FormatFrequency(towerFrequency))
        )
    else
        self:Send(
                atc,
                airport,
                string.format("%s, proceed home plate. Contact %s for recovery.", callsign, towerCallsign)
        )
    end

    return true
end

function NASG_ATC_AWACS:HandleReadback(atc, client, airport, session, event)
    atc:Log(
            string.format(
                    "AWACS readback received client=%s text=%s",
                    tostring(session and session.ClientKey),
                    tostring(event and event.raw_text)
            )
    )

    return true
end

function NASG_ATC_AWACS:HandleSpeechEvent(atc, client, airport, session, event)
    local intent = event.intent
    local request = self.Requests and self.Requests[intent] or nil

    if request then
        if request.Handler and self[request.Handler] then
            return self[request.Handler](self, atc, client, airport, session, event)
        end
    end

    atc:SendSayAgain(airport, atc.Facilities.AWACS, client, event)
    return false
end

NASG_ATC_AWACS:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.AWACS, NASG_ATC_AWACS)
NASG_ATC:Log("NASG_ATC_AWACS loaded")