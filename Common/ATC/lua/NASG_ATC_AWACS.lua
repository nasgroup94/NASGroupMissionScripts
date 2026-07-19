NASG_ATC = NASG_ATC or {}
NASG_ATC_AWACS = NASG_ATC_AWACS or {}

---------------------------------------------------------------------------
-- Intercept Timeline Phases (ACC 2024, ATP 3-52.4)
--
-- Phase governs whether group positions are announced using BULLSEYE or
-- BRAA format:
--
--  PRE_COMMIT  Strategic awareness. All group positions → BULLSEYE.
--              Controller announces PICTURE and NEW PICTURE.
--
--  COMMITTED   Intercept in progress. PICTURE and additional groups
--              stay in BULLSEYE. Direct aircraft queries (BOGEY DOPE,
--              BRAA, SNAPLOCK) and THREAT calls → BRAA (ACC Line 744-745).
--
--  TARGETED    Weapons-employment phase. All direct-to-aircraft calls
--              → BRAA. New/additional groups still in BULLSEYE.
--              TAC RANGE and MELD calls may be issued.
--
--  MERGED      Visual/WVR engagement. BRAA only. Fighter comms have
--              priority. Controller provides THREAT calls for supporting
--              aircraft.
--
--  POST_MERGE  Post-engagement assessment. Reset toward BULLSEYE for
--              new PICTURE.
---------------------------------------------------------------------------

NASG_ATC_AWACS.InterceptPhase = {
    PRE_COMMIT  = "PRE_COMMIT",
    COMMITTED   = "COMMITTED",
    TARGETED    = "TARGETED",
    MERGED      = "MERGED",
    POST_MERGE  = "POST_MERGE",
}

---------------------------------------------------------------------------
-- States
---------------------------------------------------------------------------

NASG_ATC_AWACS.States = {
    AWACS_CONTROL = "AWACS_CONTROL",
}

---------------------------------------------------------------------------
-- Extension points.
--
-- The AWACS controller is generic: it owns the voice patterns, the call
-- formatting, and the periodic picture cadence. Scenario logic (e.g. the
-- A/A PVE training range) plugs in through these registration points so it
-- never has to replace ("monkeypatch") handler bodies:
--
--   GroupDataProvider  function(controller, client, session) -> groupData|nil
--       Supplies LIVE contact data (Bulls / Braa / AltFt / Aspect / Id /
--       Contacts) for the speaking client. Handlers that render a contact
--       call ResolveGroupData(), which prefers the provider then falls back
--       to session.ActiveGroup. Returning nil leaves any stored session data
--       intact (used by static VID / ghost calls).
--
--   Listeners  objects whose OnXxx(listener, controller, atc, client,
--       airport, session, event) methods are invoked by report handlers
--       (check-in, commit, fox, merge, splash, ...). A listener may return a
--       string to override the controller's default spoken reply, or true to
--       suppress the default reply entirely.
--
--   RangeController  single object backing the range-control voice intents
--       (start/stop modes, FOX trainer, difficulty, cadence, status). Its
--       methods return the spoken reply string.
--
--   PictureBroadcast  the periodic BULLSEYE picture cadence. The scenario
--       registers a source via ConfigurePictureBroadcast{}; the controller
--       owns the timer, the clean-call throttle, and the formatting.
---------------------------------------------------------------------------

NASG_ATC_AWACS.GroupDataProvider = NASG_ATC_AWACS.GroupDataProvider or nil
NASG_ATC_AWACS.Listeners         = NASG_ATC_AWACS.Listeners or {}
NASG_ATC_AWACS.RangeController   = NASG_ATC_AWACS.RangeController or nil

NASG_ATC_AWACS.PictureBroadcast = NASG_ATC_AWACS.PictureBroadcast or {
    Enabled           = false,
    AirportId         = nil,    -- airport whose AWACS facility transmits
    Source            = nil,    -- function(controller) -> { {Bulls=,AltFt=,Size=}, ... }
    IntervalSecs      = 90,
    CleanIntervalSecs = 300,
    _lastCleanTime    = 0,
    _timerId          = nil,
}

-- Register the live contact-data provider (see above).
function NASG_ATC_AWACS:SetGroupDataProvider(fn)
    self.GroupDataProvider = fn
end

-- Register a listener object. Its OnXxx methods are fired by Notify().
function NASG_ATC_AWACS:AddListener(listener)
    if not listener then return end
    self.Listeners = self.Listeners or {}
    self.Listeners[#self.Listeners + 1] = listener
end

-- Register the object backing range-control voice intents.
function NASG_ATC_AWACS:SetRangeController(obj)
    self.RangeController = obj
end

-- Prefer live provider data; otherwise fall back to stored session group.
-- On a provider hit the result is cached into session.ActiveGroup so
-- follow-on queries stay consistent within the exchange.
function NASG_ATC_AWACS:ResolveGroupData(client, session)
    if self.GroupDataProvider then
        local ok, gd = pcall(self.GroupDataProvider, self, client, session)
        if ok and gd then
            if session then session.ActiveGroup = gd end
            return gd
        end
    end
    return session and session.ActiveGroup or nil
end

-- Fire an event to every listener. Returns a string reply if any listener
-- supplied one (last non-nil string wins), true if a listener handled the
-- event without a spoken reply, or nil if no listener acted.
function NASG_ATC_AWACS:Notify(eventName, atc, client, airport, session, event)
    local reply
    for _, l in ipairs(self.Listeners or {}) do
        local fn = l[eventName]
        if fn then
            local ok, r = pcall(fn, l, self, atc, client, airport, session, event)
            if ok then
                if type(r) == "string" then
                    reply = r
                elseif r == true and reply == nil then
                    reply = true
                end
            end
        end
    end
    return reply
end

---------------------------------------------------------------------------
-- Request table.
-- Each entry maps an intent key to voice patterns and a handler method.
-- The STT bridge resolves speech to an intent key; HandleSpeechEvent
-- dispatches to the named handler.
---------------------------------------------------------------------------

NASG_ATC_AWACS.Requests = {

    -- ── Standard comms ──────────────────────────────────────────────────

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
            "say it again",
            "repeat",
        },
    },

    -- ── Check-in / check-out ─────────────────────────────────────────────

    awacs_check_in = {
        Patterns = {
            "checking in",
            "check in",
            "package check in",
            "on station",
            "checking in as fragged",
            "checking in for cap",
            "cap check in",
            "request alpha check",   -- common end-of-check-in call; triggers full check-in response
        },
        Handler = "HandleCheckIn",
    },

    -- ── Air picture (all → BULLSEYE per ACC Line 857) ────────────────────

    request_picture = {
        Patterns = {
            "picture",
            "request picture",
            "tactical picture",
            "new picture",
            "say picture",
        },
        Handler = "HandlePicture",
    },

    -- ── Direct aircraft position queries (BRAA format per ACC Line 744) ──

    request_bogey_dope = {
        Patterns = {
            "bogey dope",
            "bogey-dope",
            "request bogey dope",
            "nearest threat",
            "nearest bogey",
        },
        Handler = "HandleBogeyDope",
    },

    request_braa = {
        Patterns = {
            "braa",
            "bearing range",
            "braa north group",
            "braa south group",
            "braa east group",
            "braa west group",
            "braa lead group",
            "braa trail group",
        },
        Handler = "HandleBraa",
    },

    -- ── Position / navigation aids ───────────────────────────────────────

    request_alpha_check = {
        Patterns = {
            "alpha check",
            "alpha check bullseye",
            "alpha check depot",
            "confirm position",
            "position check",
            "say bullseye",
            "say position",
        },
        Handler = "HandleAlphaCheck",
    },

    request_vector_to_target = {
        Patterns = {
            "vector to target",
            "vectors to target",
            "target vector",
            "commit vector",
            "vector group",
        },
        Handler = "HandleVectorToTarget",
    },

    request_vector_to_home_plate = {
        Patterns = {
            "vector home",
            "vectors home",
            "home plate",
            "vector to home plate",
            "say home plate",
        },
        Handler = "HandleVectorToHomePlate",
    },

    -- ── IFF / declare ────────────────────────────────────────────────────

    request_declare = {
        Patterns = {
            "declare",
            "declare bullseye",
            "declare group",
            "declare that contact",
            "identify",
            "what is that group",
        },
        Handler = "HandleDeclare",
    },

    -- ── Threat and intel ─────────────────────────────────────────────────

    request_threat = {
        Patterns = {
            "say threat",
            "threat warning",
            "any threats",
            "threat check",
            "threats",
        },
        Handler = "HandleThreat",
    },

    request_words = {
        Patterns = {
            "words",
            "say words",
            "intel update",
            "threat axis",
            "words update",
        },
        Handler = "HandleWords",
    },

    -- ── Recovery and logistics ───────────────────────────────────────────

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

    request_playtime = {
        Patterns = {
            "playtime",
            "say playtime",
            "fuel state",
            "time on station",
            "how long do i have",
        },
        Handler = "HandlePlaytime",
    },

    request_tanker = {
        Patterns = {
            "request tanker",
            "say tanker",
            "nearest tanker",
            "need gas",
            "tanker",
            "fuel",
        },
        Handler = "HandleTanker",
    },

    -- ── Fighter reports (pilot-initiated status calls) ───────────────────

    report_commit = {
        -- Pilot declares commitment to intercept a group.
        -- AWACS acknowledges and may issue TARGETED call.
        Patterns = {
            "commit",
            "committing",
            "committing north",
            "committing south",
            "committing east",
            "committing west",
            "committing lead group",
            "committing trail group",
            "commit north group",
            "commit south group",
        },
        Handler = "HandleCommit",
    },

    report_targeted = {
        -- Pilot confirms weapons track (TARGETED per ACC Line 1207).
        -- Transitions session to TARGETED phase.
        Patterns = {
            "targeted",
            "targeted north group",
            "targeted south group",
            "targeted east group",
            "targeted west group",
            "targeted lead group",
            "sorted",
        },
        Handler = "HandleTargeted",
    },

    report_splash = {
        -- Pilot reports missile impact / kill.
        Patterns = {
            "splash",
            "splash north group",
            "splash south group",
            "splash lead group",
            "splash trail group",
            "good kill",
            "kill confirmed",
        },
        Handler = "HandleSplash",
    },

    report_spiked = {
        -- Pilot reports a radar spike from a bearing (SINGER/RWR).
        -- AWACS correlates with known groups (ACC Line 1374-1376).
        Patterns = {
            "spiked",
            "radar spike",
            "spiked north",
            "spiked south",
            "spiked east",
            "spiked west",
            "spiked two seven zero",
            "spiked zero nine zero",
            "singer",
        },
        Handler = "HandleSpiked",
    },

    report_defending = {
        -- Pilot reports a defensive maneuver (missile launch / SAM).
        -- AWACS acknowledges and provides threat data if available.
        Patterns = {
            "defending",
            "defending north",
            "defending south",
            "defending east",
            "defending west",
            "defensive",
            "missile launch",
            "missile in the air",
        },
        Handler = "HandleDefending",
    },

    report_merge = {
        -- Pilot reports visual merge with a group (ACC MERGE).
        -- Transitions session to MERGED phase; fighter comms take priority.
        Patterns = {
            "merge",
            "merged",
            "merged with group",
            "visual merge",
            "merging",
        },
        Handler = "HandleMerge",
    },

    report_tally = {
        -- Pilot reports visual contact on a group (TALLY).
        Patterns = {
            "tally",
            "tally bandit",
            "tally bogey",
            "visual",
            "got visual",
            "visual contact",
        },
        Handler = "HandleTally",
    },

    report_no_joy = {
        -- Pilot reports no visual (NO JOY).
        -- AWACS responds with updated BRAA (direct-aircraft query).
        Patterns = {
            "no joy",
            "no visual",
            "cannot identify",
            "no eyes on",
            "lost visual",
        },
        Handler = "HandleNoJoy",
    },

    report_clean = {
        -- Pilot reports no radar contact on a group (CLEAN).
        -- AWACS provides updated picture.
        Patterns = {
            "clean",
            "no radar contact",
            "no paint",
            "clean north",
            "clean south",
            "no contacts",
        },
        Handler = "HandleClean",
    },

    report_anchored = {
        -- Pilot reports established at CAP orbit (ANCHORED).
        Patterns = {
            "anchored",
            "anchored bullseye",
            "holding at station",
            "established at cap",
            "at the cap",
        },
        Handler = "HandleAnchored",
    },

    report_pushing = {
        -- Pilot reports departing the engagement area (PUSHING).
        Patterns = {
            "pushing",
            "pushing north",
            "pushing south",
            "pushing east",
            "pushing west",
            "departing area",
            "egressing",
            "egress",
        },
        Handler = "HandlePushing",
    },

    -- ── Readback (acknowledgement of AWACS direction) ────────────────────

    readback = {
        Patterns = {
            "wilco",
            "copy",
            "roger",
            "affirm",
            "proceeding",
            "proceeding home plate",
            "contact tower",
        },
        Handler = "HandleReadback",
    },

    -- ── JUDY — pilot has target acquired on radar ─────────────────────────
    report_judy = {
        Patterns = {
            "judy",
            "i have the target",
            "radar contact on target",
            "own",
        },
        Handler = "HandleJudy",
    },

    -- ── UNABLE — pilot cannot comply with tasking ─────────────────────────
    report_unable = {
        Patterns = {
            "unable",
            "unable to comply",
            "negative",
        },
        Handler = "HandleUnable",
    },

    -- ── ABORT — pilot terminates engagement ───────────────────────────────
    report_abort = {
        Patterns = {
            "abort",
            "knock it off",
            "aborting",
        },
        Handler = "HandleAbort",
    },

    -- ── VID — visual identification declaration ───────────────────────────
    report_vid = {
        Patterns = {
            "vid hostile",
            "vid friendly",
            "vid neutral",
            "declaring hostile",
            "declaring friendly",
            "visual id hostile",
        },
        Handler = "HandleVid",
    },

    -- ── FOX / GUNS — weapons employment report ────────────────────────────
    report_fox = {
        Patterns = {
            "fox one",
            "fox 1",
            "fox two",
            "fox 2",
            "fox three",
            "fox 3",
            "guns guns guns",
            "gun",
        },
        Handler = "HandleFox",
    },

    -- ── CHECKOUT — frequency departure ───────────────────────────────────
    awacs_checkout = {
        Patterns = {
            "good day",
            "checking out",
            "departing frequency",
            "off frequency",
        },
        Handler = "HandleCheckout",
    },

    -- ── PRACTICE READY — request next intercept run ───────────────────────
    report_practice_ready = {
        Patterns = {
            "ready",
            "ready for intercept",
            "request intercept",
            "next run",
        },
        Handler = "HandlePracticeReady",
    },
}

---------------------------------------------------------------------------
-- Training-range control intents.
--
-- Declared here (not in the range script) because STT recognition patterns
-- are frozen when NASG_ATC:Start() writes the bridge config — which happens
-- before any mission-loaded range script runs. The handlers delegate to the
-- registered RangeController; if none is registered they reply "range
-- offline". This lets a pilot drive range setup by voice while the range
-- keeps all its F10 controls too.
---------------------------------------------------------------------------

NASG_ATC_AWACS.Requests.range_start_blue_cap = {
    Patterns = {
        "range blue cap",
        "start blue cap",
        "start cap defense",
        "activate cap defense",
        "blue cap defense",
    },
    Handler = "HandleRangeStartBlueCap",
}

NASG_ATC_AWACS.Requests.range_start_red_cap = {
    Patterns = {
        "range red cap",
        "start red cap",
        "red cap practice",
        "target practice mode",
        "start target practice",
    },
    Handler = "HandleRangeStartRedCap",
}

NASG_ATC_AWACS.Requests.range_start_practice = {
    Patterns = {
        "range intercept practice",
        "start intercept practice",
        "intercept practice mode",
        "start practice",
    },
    Handler = "HandleRangeStartPractice",
}

NASG_ATC_AWACS.Requests.range_stop_mode = {
    Patterns = {
        "range stop",
        "stop range",
        "stop range mode",
        "stop current mode",
        "range idle",
    },
    Handler = "HandleRangeStopMode",
}

NASG_ATC_AWACS.Requests.range_fox_on = {
    Patterns = {
        "fox trainer on",
        "enable fox trainer",
        "missile trainer on",
    },
    Handler = "HandleRangeFoxOn",
}

NASG_ATC_AWACS.Requests.range_fox_off = {
    Patterns = {
        "fox trainer off",
        "disable fox trainer",
        "missile trainer off",
    },
    Handler = "HandleRangeFoxOff",
}

NASG_ATC_AWACS.Requests.range_status = {
    Patterns = {
        "range status",
        "say range status",
        "range report",
    },
    Handler = "HandleRangeStatus",
}

-- Difficulty presets use one intent per level so no free-text parsing is
-- needed (the STT event only carries the resolved intent reliably).
NASG_ATC_AWACS.Requests.range_diff_easy = {
    Patterns = { "range difficulty easy", "set difficulty easy", "difficulty easy" },
    Handler = "HandleRangeDiffEasy",
}
NASG_ATC_AWACS.Requests.range_diff_medium = {
    Patterns = { "range difficulty medium", "set difficulty medium", "difficulty medium" },
    Handler = "HandleRangeDiffMedium",
}
NASG_ATC_AWACS.Requests.range_diff_hard = {
    Patterns = { "range difficulty hard", "set difficulty hard", "difficulty hard" },
    Handler = "HandleRangeDiffHard",
}

NASG_ATC_AWACS.Requests.range_cadence_fast = {
    Patterns = { "picture cadence fast", "range cadence fast", "fast picture cadence" },
    Handler = "HandleRangeCadenceFast",
}
NASG_ATC_AWACS.Requests.range_cadence_normal = {
    Patterns = { "picture cadence normal", "range cadence normal", "normal picture cadence" },
    Handler = "HandleRangeCadenceNormal",
}
NASG_ATC_AWACS.Requests.range_cadence_slow = {
    Patterns = { "picture cadence slow", "range cadence slow", "slow picture cadence" },
    Handler = "HandleRangeCadenceSlow",
}

-- Timeline bandit spawns relative to the speaking pilot (one intent per
-- geometry so no free-text parsing is needed). The bandit self-announces.
NASG_ATC_AWACS.Requests.range_timeline_bvr = {
    Patterns = { "timeline bvr", "spawn bvr", "bvr setup", "bvr bandit", "bandit bvr" },
    Handler = "HandleRangeTimelineBVR",
}
NASG_ATC_AWACS.Requests.range_timeline_wvr = {
    Patterns = { "timeline wvr", "spawn wvr", "wvr setup", "wvr bandit", "bandit wvr" },
    Handler = "HandleRangeTimelineWVR",
}
NASG_ATC_AWACS.Requests.range_timeline_bfm = {
    Patterns = { "timeline bfm", "spawn bfm", "bfm setup", "bfm bandit", "bandit bfm", "dogfight setup" },
    Handler = "HandleRangeTimelineBFM",
}

---------------------------------------------------------------------------
-- Phase helpers.
---------------------------------------------------------------------------

-- Returns the canonical call format (BULLSEYE or BRAA) for a given
-- session phase and call type, per ACC 2024 Lines 744-745 and 857.
--
-- callType values:
--   "PICTURE"  → always BULLSEYE (general group position awareness)
--   "THREAT"   → always BRAA (closest aircraft, direct call)
--   "DIRECT"   → BRAA (responses to BOGEY DOPE, BRAA, SNAPLOCK requests)
--   "TARGETED" → BULLSEYE (group position at time of TARGETED call)
--   "DEFAULT"  → phase-dependent
function NASG_ATC_AWACS:GetCallFormat(session, callType)
    if callType == "PICTURE"  then return "BULLSEYE" end
    if callType == "THREAT"   then return "BRAA"     end
    if callType == "DIRECT"   then return "BRAA"     end
    if callType == "TARGETED" then return "BULLSEYE" end

    local phase = session and session.InterceptPhase or self.InterceptPhase.PRE_COMMIT
    if phase == self.InterceptPhase.MERGED     then return "BRAA"     end
    if phase == self.InterceptPhase.TARGETED   then return "BRAA"     end
    return "BULLSEYE"
end

-- Advance session intercept phase, ensuring only forward transitions.
function NASG_ATC_AWACS:AdvancePhase(session, newPhase)
    if not session then return end
    local order = {
        PRE_COMMIT = 1, COMMITTED = 2, TARGETED = 3, MERGED = 4, POST_MERGE = 5
    }
    local current = session.InterceptPhase or self.InterceptPhase.PRE_COMMIT
    if (order[newPhase] or 0) > (order[current] or 0) then
        session.InterceptPhase = newPhase
    end
end

-- Reset session to POST_MERGE (after splash/disengage) so next picture
-- starts fresh with BULLSEYE calls.
function NASG_ATC_AWACS:ResetPhase(session)
    if session then
        session.InterceptPhase = self.InterceptPhase.POST_MERGE
        session.ActiveGroup    = nil
    end
end

-- Format a bearing as a three-digit spoken string (e.g. 45 → "zero four five").
function NASG_ATC_AWACS:FormatBearing(bearing)
    if not bearing then return "unknown" end
    bearing = math.floor(bearing) % 360
    return string.format("%03d", bearing)
end

-- Format altitude (feet) as spoken thousands string (e.g. 25000 → "twenty-five thousand").
-- Uses the round-to-nearest-thousand rule from ACC Line 757.
local _altWords = {
    [1]="one",[2]="two",[3]="three",[4]="four",[5]="five",
    [6]="six",[7]="seven",[8]="eight",[9]="nine",[10]="ten",
    [11]="eleven",[12]="twelve",[13]="thirteen",[14]="fourteen",[15]="fifteen",
    [16]="sixteen",[17]="seventeen",[18]="eighteen",[19]="nineteen",[20]="twenty",
    [21]="twenty-one",[22]="twenty-two",[23]="twenty-three",[24]="twenty-four",[25]="twenty-five",
    [26]="twenty-six",[27]="twenty-seven",[28]="twenty-eight",[29]="twenty-nine",[30]="thirty",
    [31]="thirty-one",[32]="thirty-two",[33]="thirty-three",[34]="thirty-four",[35]="thirty-five",
    [36]="thirty-six",[37]="thirty-seven",[38]="thirty-eight",[39]="thirty-nine",[40]="forty",
    [41]="forty-one",[42]="forty-two",[43]="forty-three",[44]="forty-four",[45]="forty-five",
    [46]="forty-six",[47]="forty-seven",[48]="forty-eight",[49]="forty-nine",[50]="fifty",
    [55]="fifty-five",[60]="sixty",[65]="sixty-five",[70]="seventy",
}
function NASG_ATC_AWACS:FormatAltitude(altFt)
    if not altFt then return "altitude unknown" end
    local k = math.floor((altFt + 500) / 1000)
    if k <= 0 then return "low altitude" end
    return (_altWords[k] or tostring(k)) .. " thousand"
end

-- Aspect word from heading difference (target aspect angle, ACC Line 789).
-- HOT < 30°; FLANKING 30-60°; BEAMING 60-120°; DRAG > 120°.
-- Returns aspect with cardinal suffix for FLANK/BEAM/DRAG (e.g. "beam north").
function NASG_ATC_AWACS:AspectFromBearings(trackDeg, reciprocalBearing)
    if not trackDeg or not reciprocalBearing then return "aspect unknown" end
    local diff = math.abs(((trackDeg - reciprocalBearing) + 540) % 360 - 180)
    if diff < 30  then return "hot" end
    if diff < 60  then return "flanking" end
    if diff < 120 then return "beaming" end
    return "drag"
end

---------------------------------------------------------------------------
-- Session helper: update standard AWACS session fields.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:TouchSession(session)
    if not session then return end
    session.State    = self.States.AWACS_CONTROL
    session.Facility = NASG_ATC.Facilities.AWACS
    session.UpdatedAt = timer.getTime()
end

---------------------------------------------------------------------------
-- Send helper.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:Send(atc, airport, message)
    atc:SendFacilityTTS(airport, atc.Facilities.AWACS, message)
end

---------------------------------------------------------------------------
-- Registration.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:RegisterRequestPatterns(atc)
    local patternMap = {}
    for intent, request in pairs(self.Requests or {}) do
        patternMap[intent] = request.Patterns or {}
    end
    atc:RegisterIntentPatterns(atc.Facilities.AWACS, patternMap)
end

---------------------------------------------------------------------------
-- Handlers — existing (updated for phase awareness and bug fixes).
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleRadioCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:Send(atc, airport, string.format(
        "%s, %s, loud and clear.",
        callsign, atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)))
    return true
end

function NASG_ATC_AWACS:HandleCheckIn(atc, client, airport, session, event)
    local callsign   = atc:GetClientCallsign(client, event)
    local packageName = event.package or "package"

    self:TouchSession(session)

    -- A scenario listener (range) may own check-in: assign a CAP station or
    -- start a practice session, then supply the spoken reply.
    local reply = self:Notify("OnCheckIn", atc, client, airport, session, event)
    if type(reply) == "string" then self:Send(atc, airport, reply); return true end
    if reply == true then return true end

    session.PackageName    = packageName
    session.InterceptPhase = self.InterceptPhase.PRE_COMMIT

    self:Send(atc, airport, string.format(
        "%s, %s, radar contact. Check in complete for %s. Stand by picture.",
        callsign,
        atc:GetFacilityCallsign(airport, atc.Facilities.AWACS),
        tostring(packageName)))
    return true
end

-- PICTURE — always BULLSEYE (ACC Line 857).
-- If session carries a LastGroup from a hook (e.g. AAPVE_MOOSE), build a
-- full group call; otherwise fall back to "picture clean."
function NASG_ATC_AWACS:HandlePicture(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    -- A scenario listener (e.g. the range) may own the picture reply: it can
    -- report a live group, generate a fresh picture, or refuse if off-station.
    local reply = self:Notify("OnPictureRequest", atc, client, airport, session, event)
    if type(reply) == "string" then self:Send(atc, airport, reply); return true end
    if reply == true then return true end

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Bulls and grp.AltFt and grp.Id then
        -- Full picture call in BULLSEYE format.
        local altStr    = self:FormatAltitude(grp.AltFt)
        local trackStr  = grp.Track  and ("track " .. grp.Track) or ""
        local idStr     = grp.Id     or "bogey"
        local sizeStr   = (grp.Heavy and ", heavy") or (grp.Contacts and string.format(", %d contacts", grp.Contacts)) or ""
        self:Send(atc, airport, string.format(
            "%s, single group bullseye %s, %s%s%s%s%s.",
            callsign,
            grp.Bulls, altStr,
            trackStr ~= "" and ", " .. trackStr or "",
            ", " .. idStr,
            sizeStr,
            grp.Fast and ", fast" or ""))
    else
        self:Send(atc, airport, string.format(
            "%s, picture clean. No factor traffic.", callsign))
    end
    return true
end

-- BOGEY DOPE — always BRAA (ACC Line 744), direct to one aircraft.
function NASG_ATC_AWACS:HandleBogeyDope(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Braa and grp.AltFt then
        local altStr    = self:FormatAltitude(grp.AltFt)
        local aspectStr = grp.Aspect or "hot"
        local idStr     = grp.Id     or "bogey"
        self:Send(atc, airport, string.format(
            "%s, bogey dope. Group braa %s, %s, %s, %s.",
            callsign, grp.Braa, altStr, aspectStr, idStr))
    else
        self:Send(atc, airport, string.format(
            "%s, picture clean. No factor traffic.", callsign))
    end
    return true
end

-- BRAA — explicit BRAA request, always BRAA format (ACC Line 744).
function NASG_ATC_AWACS:HandleBraa(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Braa and grp.AltFt then
        local altStr    = self:FormatAltitude(grp.AltFt)
        local aspectStr = grp.Aspect or "hot"
        local idStr     = grp.Id     or "bogey"
        self:Send(atc, airport, string.format(
            "%s, group braa %s, %s, %s, %s.",
            callsign, grp.Braa, altStr, aspectStr, idStr))
    else
        self:Send(atc, airport, string.format(
            "%s, no correlating group. Picture clean.", callsign))
    end
    return true
end

-- ALPHA CHECK — pilot position vs bullseye.
function NASG_ATC_AWACS:HandleAlphaCheck(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    -- If a hook has stored the pilot's bullseye position, use it.
    local pos = session.PilotBulls
    if pos then
        self:Send(atc, airport, string.format(
            "%s, alpha check bullseye %s.", callsign, pos))
    else
        self:Send(atc, airport, string.format(
            "%s, unable alpha check. Position data unavailable.", callsign))
    end
    return true
end

-- VECTOR TO TARGET — provide BRAA or heading to active group.
-- Phase: COMMITTED/TARGETED → BRAA. Pre-commit → BULLSEYE.
function NASG_ATC_AWACS:HandleVectorToTarget(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp    = self:ResolveGroupData(client, session)
    local format = self:GetCallFormat(session, "DEFAULT")

    if grp then
        if format == "BRAA" and grp.Braa and grp.AltFt then
            self:Send(atc, airport, string.format(
                "%s, vector target. Braa %s, %s, %s.",
                callsign, grp.Braa,
                self:FormatAltitude(grp.AltFt), grp.Aspect or "hot"))
        elseif grp.Bulls and grp.AltFt then
            self:Send(atc, airport, string.format(
                "%s, vector target. Bullseye %s, %s.",
                callsign, grp.Bulls,
                self:FormatAltitude(grp.AltFt)))
        else
            self:Send(atc, airport, string.format(
                "%s, unable vector. No active target on your package.", callsign))
        end
    else
        self:Send(atc, airport, string.format(
            "%s, unable vector. No active target on your package.", callsign))
    end
    return true
end

function NASG_ATC_AWACS:HandleVectorToHomePlate(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:Send(atc, airport, string.format("%s, proceed home plate.", callsign))
    return true
end

function NASG_ATC_AWACS:HandleCombatRecovery(atc, client, airport, session, event)
    local callsign      = atc:GetClientCallsign(client, event)
    local towerFreq     = atc:GetFacilityFrequency(airport, atc.Facilities.TOWER)
    local towerCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.TOWER)

    -- Let a scenario listener react (e.g. disengage the package FSM) before
    -- we hand the flight off to tower for recovery.
    self:Notify("OnCombatRecovery", atc, client, airport, session, event)

    session.State    = atc.States.INBOUND
    session.Facility = atc.Facilities.TOWER
    session.UpdatedAt = timer.getTime()
    self:ResetPhase(session)

    if towerFreq then
        self:Send(atc, airport, string.format(
            "%s, proceed home plate. Contact %s %s for recovery.",
            callsign, towerCallsign, atc:FormatFrequency(towerFreq)))
    else
        self:Send(atc, airport, string.format(
            "%s, proceed home plate. Contact %s for recovery.",
            callsign, towerCallsign))
    end
    return true
end

function NASG_ATC_AWACS:HandleReadback(atc, client, airport, session, event)
    atc:Log(string.format(
        "AWACS readback received client=%s text=%s",
        tostring(session and session.ClientKey),
        tostring(event and event.raw_text)))
    return true
end

---------------------------------------------------------------------------
-- Handlers — new.
---------------------------------------------------------------------------

-- DECLARE — IFF request (ACC Line 1248). Response uses group name +
-- position in format matching current phase, then declaration word.
function NASG_ATC_AWACS:HandleDeclare(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp    = self:ResolveGroupData(client, session)
    local format = self:GetCallFormat(session, "DEFAULT")

    if grp and grp.Id then
        local posStr
        if format == "BRAA" and grp.Braa then
            posStr = "braa " .. grp.Braa
        elseif grp.Bulls then
            posStr = "bullseye " .. grp.Bulls
        else
            posStr = "position unknown"
        end
        local altStr = grp.AltFt and (", " .. self:FormatAltitude(grp.AltFt)) or ""
        self:Send(atc, airport, string.format(
            "%s, group %s%s, %s.",
            callsign, posStr, altStr, string.upper(grp.Id)))
    else
        -- No correlation: return UNABLE per ACC "FURBALL" / unable-declare rules.
        self:Send(atc, airport, string.format(
            "%s, unable declare. No correlating group. Provide bearing to contact.", callsign))
    end
    return true
end

-- THREAT — always BRAA to the closest aircraft (ACC Line 744-745).
-- Reports any threat group not already actioned by the session.
function NASG_ATC_AWACS:HandleThreat(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    -- Notify listeners (e.g. range scores a threat acknowledgment).
    self:Notify("OnThreat", atc, client, airport, session, event)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Braa and grp.AltFt and grp.Id then
        local aspectStr = grp.Aspect or "hot"
        local idStr     = string.upper(grp.Id)
        self:Send(atc, airport, string.format(
            "%s, threat group braa %s, %s, %s, %s.",
            callsign, grp.Braa,
            self:FormatAltitude(grp.AltFt), aspectStr, idStr))
    else
        self:Send(atc, airport, string.format(
            "%s, no threat group. Picture clean.", callsign))
    end
    return true
end

-- WORDS — current intel: threat axis, weapons control status (ACC Line 476).
-- Reads session.Words if a hook has populated it, otherwise generic response.
function NASG_ATC_AWACS:HandleWords(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    if session.Words then
        self:Send(atc, airport, string.format(
            "%s, words. %s.", callsign, session.Words))
    else
        self:Send(atc, airport, string.format(
            "%s, words current. No additional threat data at this time.", callsign))
    end
    return true
end

-- PLAYTIME — time on station / fuel advisory.
-- Reads session.Playtime if a hook has populated it.
function NASG_ATC_AWACS:HandlePlaytime(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    if session.Playtime then
        self:Send(atc, airport, string.format(
            "%s, playtime %s.", callsign, tostring(session.Playtime)))
    else
        self:Send(atc, airport, string.format(
            "%s, playtime unavailable. Contact your flight lead for fuel state.", callsign))
    end
    return true
end

-- TANKER — vector to nearest tanker.
-- Reads session.TankerData if a hook has populated it.
function NASG_ATC_AWACS:HandleTanker(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    -- A scenario listener may own tanker tasking (e.g. the range vectors to a
    -- live tanker and holds its picture loop) and supply the spoken reply.
    local reply = self:Notify("OnTanker", atc, client, airport, session, event)
    if type(reply) == "string" then self:Send(atc, airport, reply); return true end
    if reply == true then return true end

    local tanker = session.TankerData
    if tanker then
        local freqStr = tanker.Frequency and (" frequency " .. atc:FormatFrequency(tanker.Frequency)) or ""
        self:Send(atc, airport, string.format(
            "%s, %s bullseye %s%s.",
            callsign,
            tanker.Callsign or "tanker",
            tanker.Bulls    or "position unknown",
            freqStr))
    else
        self:Send(atc, airport, string.format(
            "%s, no tanker data available. Contact your controlling authority.", callsign))
    end
    return true
end

-- COMMIT — pilot declares intercept commitment (ACC Line 1193).
-- Position call uses BULLSEYE (pre-commit/committed phase).
-- Advances session phase to COMMITTED.
function NASG_ATC_AWACS:HandleCommit(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:AdvancePhase(session, self.InterceptPhase.COMMITTED)
    self:Notify("OnCommit", atc, client, airport, session, event)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Bulls and grp.AltFt then
        local idStr  = grp.Id    and (", " .. grp.Id)    or ""
        local sizeStr = grp.Heavy and ", heavy" or ""
        self:Send(atc, airport, string.format(
            "%s, commit. Group bullseye %s, %s%s%s.",
            callsign, grp.Bulls,
            self:FormatAltitude(grp.AltFt), idStr, sizeStr))
    else
        self:Send(atc, airport, string.format(
            "%s, commit acknowledged. No radar contact. Continue push.", callsign))
    end
    return true
end

-- TARGETED — pilot confirms weapons track (ACC Line 1207).
-- Advances session to TARGETED phase. Response includes group position
-- in BULLSEYE format (additional groups for SA).
function NASG_ATC_AWACS:HandleTargeted(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:AdvancePhase(session, self.InterceptPhase.TARGETED)
    self:Notify("OnTargeted", atc, client, airport, session, event)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Bulls then
        local altStr = grp.AltFt and (", " .. self:FormatAltitude(grp.AltFt)) or ""
        self:Send(atc, airport, string.format(
            "%s, targeted. Group bullseye %s%s.",
            callsign, grp.Bulls, altStr))
    else
        self:Send(atc, airport, string.format(
            "%s, targeted acknowledged. No additional groups. Continue.", callsign))
    end
    return true
end

-- SPLASH — pilot confirms kill (ACC SPLASH brevity).
-- AWACS acknowledges and provides NEW PICTURE in BULLSEYE if additional
-- contacts remain; resets phase to POST_MERGE if clean.
function NASG_ATC_AWACS:HandleSplash(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:ResetPhase(session)

    -- A scenario listener (range) confirms the kill, retasks, and scores,
    -- returning its own reply. Otherwise use the generic acknowledgment.
    local reply = self:Notify("OnSplash", atc, client, airport, session, event)
    if type(reply) == "string" then
        self:Send(atc, airport, reply)
    elseif reply ~= true then
        self:Send(atc, airport, string.format(
            "%s, splash. Good kill. Picture clean. Resume CAP.", callsign))
    end
    return true
end

-- SPIKED — pilot reports radar lock from a bearing.
-- AWACS correlates with a known group if available (ACC Line 1374).
-- Always responds with BRAA to that aircraft (closest aircraft call).
function NASG_ATC_AWACS:HandleSpiked(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local bearing = event.bearing or event.strobe_bearing
    local grp     = self:ResolveGroupData(client, session)

    if grp and grp.Braa and grp.AltFt then
        -- Provide correlation.
        self:Send(atc, airport, string.format(
            "%s, spike correlates. Group braa %s, %s, %s, %s.",
            callsign,
            grp.Braa,
            self:FormatAltitude(grp.AltFt),
            grp.Id or "bogey",
            grp.Aspect or "hot"))
    elseif bearing then
        -- No correlation but have bearing.
        self:Send(atc, airport, string.format(
            "%s, warrior clean bearing %s. Continue mission.",
            callsign, self:FormatBearing(tonumber(bearing))))
    else
        self:Send(atc, airport, string.format(
            "%s, warrior clean. Say strobe bearing.", callsign))
    end
    return true
end

-- DEFENDING — pilot reports defensive maneuver (ACC Line 1687).
-- AWACS acknowledges immediately; provides supporting threat call if
-- a correlated group exists (BRAA to closest aircraft).
function NASG_ATC_AWACS:HandleDefending(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    -- Notify listeners (e.g. range scores a threat acknowledgment).
    self:Notify("OnDefending", atc, client, airport, session, event)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Braa and grp.AltFt then
        self:Send(atc, airport, string.format(
            "%s, defensive. Threat braa %s, %s, %s, %s.",
            callsign, grp.Braa,
            self:FormatAltitude(grp.AltFt),
            grp.Aspect or "hot",
            string.upper(grp.Id or "HOSTILE")))
    else
        self:Send(atc, airport, string.format(
            "%s, defensive acknowledged. Picture clean supporting.", callsign))
    end
    return true
end

-- MERGE — pilot reports visual merge (ACC MERGE).
-- Advances session to MERGED phase. AWACS acknowledges and monitors for
-- additional groups; fighter comms take priority.
function NASG_ATC_AWACS:HandleMerge(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:AdvancePhase(session, self.InterceptPhase.MERGED)

    -- A scenario listener (range) may drive its FSM / scoring and reply.
    local reply = self:Notify("OnMerge", atc, client, airport, session, event)
    if type(reply) == "string" then
        self:Send(atc, airport, reply)
    elseif reply ~= true then
        self:Send(atc, airport, string.format(
            "%s, merged. Monitoring for additional groups. Continue.", callsign))
    end
    return true
end

-- TALLY — pilot reports visual contact on a group.
-- AWACS acknowledges; provides additional group SA if available.
function NASG_ATC_AWACS:HandleTally(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    self:Send(atc, airport, string.format(
        "%s, tally. Continue push.", callsign))
    return true
end

-- NO JOY — pilot reports no visual. AWACS responds with updated BRAA
-- (direct-to-aircraft call, always BRAA per ACC Line 744).
function NASG_ATC_AWACS:HandleNoJoy(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Braa and grp.AltFt then
        self:Send(atc, airport, string.format(
            "%s, no joy. Group braa %s, %s, %s, %s.",
            callsign, grp.Braa,
            self:FormatAltitude(grp.AltFt),
            grp.Aspect or "hot",
            grp.Id or "bogey"))
    else
        self:Send(atc, airport, string.format(
            "%s, no joy. Unable update. Picture clean at this time.", callsign))
    end
    return true
end

-- CLEAN — pilot reports no radar contact on a group.
-- AWACS provides updated picture (BULLSEYE per ACC Line 857) and
-- confirms group status if radar contact maintained.
function NASG_ATC_AWACS:HandleClean(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Bulls and grp.AltFt then
        self:Send(atc, airport, string.format(
            "%s, radar contact maintained. Group bullseye %s, %s, %s.",
            callsign, grp.Bulls,
            self:FormatAltitude(grp.AltFt),
            grp.Id or "bogey"))
    else
        self:Send(atc, airport, string.format(
            "%s, affirm clean. Picture clean at this time.", callsign))
    end
    return true
end

-- ANCHORED — pilot reports established at CAP orbit.
-- AWACS acknowledges; may issue immediate picture.
function NASG_ATC_AWACS:HandleAnchored(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)

    local grp = self:ResolveGroupData(client, session)
    if grp and grp.Bulls then
        -- Issue a picture immediately so the pilot has SA upon arrival.
        local altStr  = grp.AltFt  and (", " .. self:FormatAltitude(grp.AltFt)) or ""
        local trackStr = grp.Track and (", track " .. grp.Track) or ""
        local idStr   = grp.Id     and (", " .. grp.Id) or ""
        self:Send(atc, airport, string.format(
            "%s, anchored. Single group bullseye %s%s%s%s.",
            callsign, grp.Bulls, altStr, trackStr, idStr))
    else
        self:Send(atc, airport, string.format(
            "%s, anchored. Picture clean. Standby.", callsign))
    end
    return true
end

-- PUSHING — pilot reports departing engagement area.
-- AWACS acknowledges and provides a final picture update.
-- Resets intercept phase in case pilot returns to CAP.
function NASG_ATC_AWACS:HandlePushing(atc, client, airport, session, event)
    local callsign = atc:GetClientCallsign(client, event)
    self:TouchSession(session)
    self:ResetPhase(session)

    self:Send(atc, airport, string.format(
        "%s, pushing. Picture clean. Monitor home plate frequency.", callsign))
    return true
end

---------------------------------------------------------------------------
-- JUDY — pilot reports target on radar.  AWACS hands off the intercept
-- and monitors; pilot is responsible for BVR shot or VID call.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleJudy(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    self:TouchSession(session)
    self:AdvancePhase(session, self.InterceptPhase.TARGETED)
    self:Send(atc, airport, string.format(
        "%s, %s, copy JUDY. Your fight. Report SPLASH or NO JOY.",
        callsign, facCallsign))
    return true
end

---------------------------------------------------------------------------
-- UNABLE — pilot cannot comply with current tasking.
-- AWACS acknowledges, holds the picture, and will re-task shortly.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleUnable(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    self:TouchSession(session)
    self:Send(atc, airport, string.format(
        "%s, %s, copy unable. Maintain CAP. Stand by new tasking.",
        callsign, facCallsign))
    return true
end

---------------------------------------------------------------------------
-- ABORT / KNOCK IT OFF — pilot terminates the intercept.
-- Resets phase so the next picture starts clean.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleAbort(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    self:TouchSession(session)
    self:ResetPhase(session)
    self:Send(atc, airport, string.format(
        "%s, %s, copy abort. Reset CAP. Stand by new picture.",
        callsign, facCallsign))
    return true
end

---------------------------------------------------------------------------
-- VID — pilot declares visual identification of the target.
-- Parses declaration (HOSTILE / FRIENDLY / NEUTRAL) from the transcript
-- and records it on the active group; AWACS reads it back.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleVid(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    self:TouchSession(session)

    local t           = string.lower(event and event.Transcript or "")
    local declaration = "UNKNOWN"
    if     t:find("hostile")  then declaration = "HOSTILE"
    elseif t:find("friendly") then declaration = "FRIENDLY"
    elseif t:find("neutral")  then declaration = "NEUTRAL"
    end

    -- Record declaration on the active group so subsequent handlers can use it.
    local posStr = ""
    if session and session.ActiveGroup then
        local gd = session.ActiveGroup
        posStr = (gd.Braa  and "braa " .. gd.Braa)
              or (gd.Bulls and "bullseye " .. gd.Bulls)
              or ""
        if     declaration == "HOSTILE"  then gd.Id = "hostile"
        elseif declaration == "FRIENDLY" then gd.Id = "friendly"
        elseif declaration == "NEUTRAL"  then gd.Id = "neutral"
        end
    end

    self:Send(atc, airport, string.format(
        "%s, %s, copy VID. %s declared %s.",
        callsign, facCallsign,
        posStr ~= "" and posStr or "group",
        declaration))
    return true
end

---------------------------------------------------------------------------
-- FOX / GUNS — pilot reports weapons employment.
-- Parses missile type (Fox 1/2/3 or GUNS) from transcript and reads back.
-- Range validity commentary is handled by AAPVERange scoring hooks.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleFox(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    self:TouchSession(session)

    local t       = string.lower(event and event.Transcript or "")
    local foxWord = "fox three"
    if     t:find("fox.?one") or t:find("fox.?1")              then foxWord = "fox one"
    elseif t:find("fox.?two") or t:find("fox.?2")              then foxWord = "fox two"
    elseif t:find("gun")                                        then foxWord = "guns"
    end

    self:AdvancePhase(session, self.InterceptPhase.TARGETED)
    -- Notify listeners (range validates the shot and scores by missile type).
    self:Notify("OnFox", atc, client, airport, session, event)
    self:Send(atc, airport, string.format(
        "%s, %s, copy %s. Report SPLASH.",
        callsign, facCallsign, foxWord))
    return true
end

---------------------------------------------------------------------------
-- CHECKOUT — pilot departing frequency.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleCheckout(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)

    -- A scenario listener (range) may finalize a scorecard / end a practice
    -- session and supply its own reply.
    local reply = self:Notify("OnCheckout", atc, client, airport, session, event)
    if type(reply) == "string" then self:Send(atc, airport, reply); return true end
    if reply == true then return true end

    self:Send(atc, airport, string.format(
        "%s, %s, good day. Safe flight.",
        callsign, facCallsign))
    return true
end

---------------------------------------------------------------------------
-- PRACTICE READY — pilot requests next intercept practice run.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandlePracticeReady(atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)

    -- A scenario listener (range) spawns the next practice bogey (or, in CAP
    -- defense, treats this as a picture request) and supplies the reply.
    local reply = self:Notify("OnPracticeReady", atc, client, airport, session, event)
    if type(reply) == "string" then self:Send(atc, airport, reply); return true end
    if reply == true then return true end

    self:Send(atc, airport, string.format(
        "%s, %s, stand by intercept.",
        callsign, facCallsign))
    return true
end

---------------------------------------------------------------------------
-- Range-control handlers.
--
-- These delegate to the registered RangeController (the A/A PVE range). Each
-- controller method returns the spoken reply string. If no range is loaded
-- the pilot hears a short "range offline" acknowledgement.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:_RangeControl(method, atc, client, airport, session, event, offlineMsg)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    local rc = self.RangeController
    if not rc or not rc[method] then
        self:Send(atc, airport, string.format(
            "%s, %s, %s", callsign, facCallsign, offlineMsg or "training range is offline."))
        return true
    end
    local ok, reply = pcall(rc[method], rc, self, atc, client, airport, session, event)
    if ok and type(reply) == "string" then
        self:Send(atc, airport, reply)
    elseif not (ok and reply == true) then
        -- true = the controller method already spoke / acted; stay silent.
        self:Send(atc, airport, string.format("%s, %s, copy.", callsign, facCallsign))
    end
    return true
end

function NASG_ATC_AWACS:HandleRangeStartBlueCap(atc, client, airport, session, event)
    return self:_RangeControl("StartBlueCap", atc, client, airport, session, event,
        "unable, training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeStartRedCap(atc, client, airport, session, event)
    return self:_RangeControl("StartRedCap", atc, client, airport, session, event,
        "unable, training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeStartPractice(atc, client, airport, session, event)
    return self:_RangeControl("StartPractice", atc, client, airport, session, event,
        "unable, training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeStopMode(atc, client, airport, session, event)
    return self:_RangeControl("StopMode", atc, client, airport, session, event,
        "training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeFoxOn(atc, client, airport, session, event)
    return self:_RangeControl("FoxTrainerOn", atc, client, airport, session, event,
        "training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeFoxOff(atc, client, airport, session, event)
    return self:_RangeControl("FoxTrainerOff", atc, client, airport, session, event,
        "training range is offline.")
end

function NASG_ATC_AWACS:HandleRangeStatus(atc, client, airport, session, event)
    return self:_RangeControl("Status", atc, client, airport, session, event,
        "training range is offline.")
end

-- Setting handlers pass a fixed level/speed to the range controller.
function NASG_ATC_AWACS:_RangeSetting(method, arg, atc, client, airport, session, event)
    local callsign    = atc:GetClientCallsign(client, event)
    local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
    local rc = self.RangeController
    if not rc or not rc[method] then
        self:Send(atc, airport, string.format(
            "%s, %s, training range is offline.", callsign, facCallsign))
        return true
    end
    local ok, reply = pcall(rc[method], rc, self, arg, atc, client, airport, session, event)
    if ok and type(reply) == "string" then
        self:Send(atc, airport, reply)
    elseif not (ok and reply == true) then
        -- true = the controller method already spoke / acted; stay silent.
        self:Send(atc, airport, string.format("%s, %s, copy.", callsign, facCallsign))
    end
    return true
end

function NASG_ATC_AWACS:HandleRangeTimelineBVR(atc, client, airport, session, event)
    return self:_RangeSetting("SpawnTimeline", "BVR", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeTimelineWVR(atc, client, airport, session, event)
    return self:_RangeSetting("SpawnTimeline", "WVR", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeTimelineBFM(atc, client, airport, session, event)
    return self:_RangeSetting("SpawnTimeline", "BFM", atc, client, airport, session, event)
end

function NASG_ATC_AWACS:HandleRangeDiffEasy(atc, client, airport, session, event)
    return self:_RangeSetting("SetDifficulty", "easy", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeDiffMedium(atc, client, airport, session, event)
    return self:_RangeSetting("SetDifficulty", "medium", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeDiffHard(atc, client, airport, session, event)
    return self:_RangeSetting("SetDifficulty", "hard", atc, client, airport, session, event)
end

function NASG_ATC_AWACS:HandleRangeCadenceFast(atc, client, airport, session, event)
    return self:_RangeSetting("SetCadence", "fast", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeCadenceNormal(atc, client, airport, session, event)
    return self:_RangeSetting("SetCadence", "normal", atc, client, airport, session, event)
end
function NASG_ATC_AWACS:HandleRangeCadenceSlow(atc, client, airport, session, event)
    return self:_RangeSetting("SetCadence", "slow", atc, client, airport, session, event)
end

---------------------------------------------------------------------------
-- Periodic picture broadcast.
--
-- The controller owns the cadence, the "picture clean" throttle, and the
-- BULLSEYE formatting. A scenario registers the live contacts via
-- ConfigurePictureBroadcast{ AirportId=, Source= }, then starts/stops it.
-- Source returns an array of { Bulls=, AltFt=, Size= } (empty = clean).
---------------------------------------------------------------------------

-- "angels 25" (>=10k) / "cherubs 9" (<10k) for picture calls.
function NASG_ATC_AWACS:AngelsWord(altFt)
    altFt = altFt or 0
    if altFt < 10000 then
        return string.format("cherubs %d", math.floor(altFt / 1000))
    end
    return string.format("angels %d", math.floor(altFt / 1000))
end

function NASG_ATC_AWACS:ConfigurePictureBroadcast(opts)
    local pb = self.PictureBroadcast
    opts = opts or {}
    if opts.AirportId         ~= nil then pb.AirportId         = opts.AirportId end
    if opts.Source            ~= nil then pb.Source            = opts.Source end
    if opts.IntervalSecs      ~= nil then pb.IntervalSecs      = opts.IntervalSecs end
    if opts.CleanIntervalSecs ~= nil then pb.CleanIntervalSecs = opts.CleanIntervalSecs end
end

function NASG_ATC_AWACS:StartPictureBroadcast()
    local pb = self.PictureBroadcast
    if pb.Enabled then return end
    pb.Enabled        = true
    pb._lastCleanTime = 0
    -- First call after one interval so it doesn't overlap mode-start TTS.
    pb._timerId = timer.scheduleFunction(function()
        if not pb.Enabled then return nil end
        pcall(function() NASG_ATC_AWACS:BroadcastPictureTick() end)
        return timer.getTime() + (pb.IntervalSecs or 90)
    end, {}, timer.getTime() + (pb.IntervalSecs or 90))
end

function NASG_ATC_AWACS:StopPictureBroadcast()
    local pb = self.PictureBroadcast
    pb.Enabled = false
    if pb._timerId then
        pcall(function() timer.removeFunction(pb._timerId) end)
        pb._timerId = nil
    end
end

function NASG_ATC_AWACS:BroadcastPictureTick()
    local pb = self.PictureBroadcast
    if not pb.Enabled or not pb.Source then return end
    local airport = pb.AirportId and NASG_ATC:GetAirport(pb.AirportId) or nil
    if not airport then return end

    local groups = pb.Source(self) or {}
    local label  = NASG_ATC:GetFacilityCallsign(airport, NASG_ATC.Facilities.AWACS) or "Magic"

    if #groups == 0 then
        -- Quiet range: "picture clean" at the longer clean cadence only.
        local now = timer.getTime()
        if now - (pb._lastCleanTime or 0) >= (pb.CleanIntervalSecs or 300) then
            pb._lastCleanTime = now
            NASG_ATC:SendFacilityTTS(airport, NASG_ATC.Facilities.AWACS,
                string.format("%s. Picture. Clean.", label))
        end
        return
    end

    -- g.Bulls is already a complete bullseye phrase carrying the reference
    -- word (MOOSE's "BULLS, ..." or the scenario's configured bullseye name),
    -- so the format must NOT prepend its own "bullseye" or it doubles up.
    if #groups == 1 then
        local g     = groups[1]
        local szStr = (g.Size or 1) >= 3 and "heavy group"
                   or ((g.Size or 1) == 2 and "group" or "single group")
        NASG_ATC:SendFacilityTTS(airport, NASG_ATC.Facilities.AWACS, string.format(
            "%s. Picture. %s. %s. %s. Bogey.",
            label, szStr, g.Bulls or "unknown", self:AngelsWord(g.AltFt)))
    else
        local tags  = { "Alpha", "Bravo", "Charlie" }
        local parts = {}
        for i = 1, math.min(#groups, 3) do
            local g = groups[i]
            parts[#parts + 1] = string.format(
                "%s group, %s, %s, bogey.",
                tags[i], g.Bulls or "unknown", self:AngelsWord(g.AltFt))
        end
        NASG_ATC:SendFacilityTTS(airport, NASG_ATC.Facilities.AWACS,
            string.format("%s. Picture. %s", label, table.concat(parts, " ")))
    end
end

---------------------------------------------------------------------------
-- Main speech event dispatcher.
---------------------------------------------------------------------------

function NASG_ATC_AWACS:HandleSpeechEvent(atc, client, airport, session, event)
    local intent  = event.intent
    local request = self.Requests and self.Requests[intent] or nil

    if request then
        if request.Handler and self[request.Handler] then
            return self[request.Handler](self, atc, client, airport, session, event)
        end
    end

    atc:SendSayAgain(airport, atc.Facilities.AWACS, client, event)
    return false
end

---------------------------------------------------------------------------
-- Bootstrap.
---------------------------------------------------------------------------

NASG_ATC_AWACS:RegisterRequestPatterns(NASG_ATC)
NASG_ATC:RegisterController(NASG_ATC.Facilities.AWACS, NASG_ATC_AWACS)
NASG_ATC:Log("NASG_ATC_AWACS loaded")
