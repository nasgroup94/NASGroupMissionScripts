---------------------------------------------------------------------------
-- A/A PVE Range - MOOSE FSM / CAP Package Version
--
-- Requires:
--   MOOSE loaded before this file.
--
-- Major features:
--   1. RED CAP Target Practice mode.
--   2. BLUE CAP Defense mode with randomized air picture.
--   3. Per-package FSMs for clean lifecycle (Assigned->OnStation->Committed->Retasking->Closed).
--   4. Main range FSM with OnBefore guards (no duplicate mode checks in menus).
--   5. CHIEF integration: CAP zones, response tuning, DEFCON callbacks.
--   6. Multiple simultaneous CAP packages (up to MaxCapPackages).
--   7. Coalition selector menus for CAP check-in and timeline spawns.
--   8. Commit detection when package leaves CAP toward hostile.
--   9. Retask back to CAP after hostile neutralized.
--   10. Picture resumes only after package returns to CAP.
--   11. FOX Missile Trainer toggle.
--   12. Timeline spawns: BVR (80 NM), WVR (20 NM), BFM (5 NM, weapons free at merge).
--   13. TTS via MSRS (Magic callsign).
--   14. Bogie behavior: aggressors spawn weapons-hold (passive defense). On client
--       commit/proximity trigger, bogie either ENGAGES (weapons free, EvadeFire) or
--       EVADES (BypassAndEscape, despawn, package retasked for new picture).
--   15. Ghost Bullseye Calls: AWACS-only text+TTS picture calls for contacts
--       geometrically OUTSIDE the package's AOR (no spawn). Trains crews to hold
--       CAP and not commit to contacts that are not their responsibility.
--   16. VID Opportunities: spawned non-combative/civil-profile aircraft inside the
--       AOR with varying track (CROSSING/INBOUND/COLD), speed, and altitude. Client
--       assesses and decides whether to commit and VID or hold CAP.
---------------------------------------------------------------------------

if AAPVE_MOOSE and AAPVE_MOOSE.Stop then
    pcall(function()
        AAPVE_MOOSE:Stop()
    end)
end

AAPVE_MOOSE = {}

---------------------------------------------------------------------------
-- Basic configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.Debug = true

AAPVE_MOOSE.MenuRoot    = MENU_COALITION:New(coalition.side.BLUE, "A/A RANGE SETUP")
AAPVE_MOOSE.MenuItems   = {}

---------------------------------------------------------------------------
-- Mission zones.
---------------------------------------------------------------------------

-- Each CAP zone entry now carries its AOR zone.
-- AorZone defines the area of responsibility for that package:
--   - Hostile bogies route into this zone.
--   - VID contacts transit through this zone.
--   - Ghost calls are placed OUTSIDE this zone.
--   - Commits toward contacts outside this zone trigger a training warning.
AAPVE_MOOSE.BlueCapZones = {
    -- Altitude blocks provide vertical separation between simultaneous packages.
    -- Violation check uses AltMinFt/AltMaxFt; tasking TTS includes the block.
    { Name = "CAP HOLD 1", Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_1"), AorZone = ZONE:New("BLUE_CAP_1_AOR"), AltMinFt = 20000, AltMaxFt = 22000 },
    { Name = "CAP HOLD 2", Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_2"), AorZone = ZONE:New("BLUE_CAP_2_AOR"), AltMinFt = 23000, AltMaxFt = 25000 },
    { Name = "CAP HOLD 3", Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_3"), AorZone = ZONE:New("BLUE_CAP_3_AOR"), AltMinFt = 26000, AltMaxFt = 28000 },
}

AAPVE_MOOSE.RedCapZone    = ZONE:New("AAPVE_RED_CAP_ZONE")
AAPVE_MOOSE.ProtectedZone = ZONE:New("AAPVE_PROTECTED_ZONE")
AAPVE_MOOSE.SandboxZone   = ZONE:New("AAPVE_SANDBOX_ZONE")

AAPVE_MOOSE.RedSpawnZones = {
    ZONE:New("AAPVE_RED_SPAWN_ZONE_1"),
    ZONE:New("AAPVE_RED_SPAWN_ZONE_2"),
    ZONE:New("AAPVE_RED_SPAWN_ZONE_3"),
}

AAPVE_MOOSE.RecoveryZones = {
    ZONE:New("AAPVE_RECOVERY_ZONE_1"),
    ZONE:New("AAPVE_RECOVERY_ZONE_2"),
    ZONE:New("AAPVE_RECOVERY_ZONE_3"),
}

---------------------------------------------------------------------------
-- MOOSE Sets.
---------------------------------------------------------------------------

AAPVE_MOOSE.BlueClientSet = SET_CLIENT:New()
    :FilterCoalitions("blue")
    :FilterActive()
    :FilterStart()

AAPVE_MOOSE.BlueDetectionSet = SET_GROUP:New()
    :FilterCoalitions("blue")
    :FilterPrefixes({ "EW", "AWACS", "EWR" })
    :FilterStart()

---------------------------------------------------------------------------
-- Runtime state.
---------------------------------------------------------------------------

AAPVE_MOOSE.ActiveGroups      = {}
AAPVE_MOOSE.CapPackages        = {}
AAPVE_MOOSE.NextCapPackageId   = 1
AAPVE_MOOSE.BlueChief          = nil
AAPVE_MOOSE.MonitorScheduler   = nil
AAPVE_MOOSE.PictureScheduler   = nil
AAPVE_MOOSE.BroadcastScheduler = nil
AAPVE_MOOSE._lastCleanBroadcastTime = 0
AAPVE_MOOSE.FoxTrainer         = nil
AAPVE_MOOSE.FoxTrainerEnabled  = false

-- Practice mode and scoring runtime state.
AAPVE_MOOSE.PracticeSessions       = {}  -- [unitName] = practice session table
AAPVE_MOOSE.PracticeMonitor        = nil -- SCHEDULER for intercept proximity poll
AAPVE_MOOSE.ScoreDatabase          = {}  -- [session_id] = finalized scorecard row

-- Dynamic client selector menu state
AAPVE_MOOSE.TimelineClientMenus  = {}
AAPVE_MOOSE.CapCheckInClientMenus = {}

---------------------------------------------------------------------------
-- CAP package configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.CapCheckInRadiusNm           = 0.5
AAPVE_MOOSE.MaxCapPackages               = 3
AAPVE_MOOSE.MonitorIntervalSeconds       = 10
AAPVE_MOOSE.PictureIntervalSeconds       = 120  -- how often new pictures are GENERATED (bogey/ghost spawns)
AAPVE_MOOSE.BroadcastIntervalSecs        = 90   -- how often live contacts are RE-BROADCAST to all stations
AAPVE_MOOSE.BroadcastCleanIntervalSecs   = 300  -- minimum gap between "picture clean" broadcasts
AAPVE_MOOSE.PackageEmptyCloseSeconds     = 300

AAPVE_MOOSE.UseGlobalHostileLimit        = false
AAPVE_MOOSE.MaxGlobalHostileGroups       = 2

-- Picture type probabilities (must total <= 100; remainder = friendly transit).
AAPVE_MOOSE.PictureHostileChance         = 40   -- % spawned bogie (weapons hold → may engage/evade)
AAPVE_MOOSE.PictureGhostCallChance       = 25   -- % AWACS-only text+TTS bullseye call, no spawn, OUTSIDE AOR
AAPVE_MOOSE.PictureVIDChance             = 20   -- % spawned VID opportunity, inside AOR, ambiguous profile
-- remaining 15% = friendly/neutral non-combative transit through the area

-- Hostile / non-hostile spawn lifetime.
AAPVE_MOOSE.NonHostileMinLifetimeSeconds = 300
AAPVE_MOOSE.NonHostileMaxLifetimeSeconds = 900

-- Bogey / hostile picture altitudes and speeds.
AAPVE_MOOSE.PictureMinAltitudeFt        = 20000
AAPVE_MOOSE.PictureMaxAltitudeFt        = 32000
AAPVE_MOOSE.PictureMinSpeedKts          = 320
AAPVE_MOOSE.PictureMaxSpeedKts          = 500

---------------------------------------------------------------------------
-- Ghost Bullseye Call configuration.
--
-- Ghost calls are AWACS-only radio/text picture calls that describe a
-- contact OUTSIDE the package's AOR. No aircraft is spawned. The call
-- is generated from a coordinate that is offset ≥90° away from the
-- package's CAP direction so it clearly falls in another sector.
-- Purpose: train crews to hold CAP and not commit to traffic that is not
-- their responsibility.
---------------------------------------------------------------------------

-- Distance range (NM from sandbox reference) for the fictitious contact.
AAPVE_MOOSE.GhostCallMinDistNm           = 80
AAPVE_MOOSE.GhostCallMaxDistNm           = 160

-- Minimum angular separation (degrees) between the package CAP bearing and
-- the ghost contact bearing. Keeps the ghost clearly out of their sector.
AAPVE_MOOSE.GhostCallMinAngleOffsetDeg   = 90

---------------------------------------------------------------------------
-- VID Opportunity configuration.
--
-- VID contacts are spawned non-combative / civil-profile aircraft that fly
-- through the package's AOR. The client must assess track, speed, and
-- altitude to decide whether to commit and VID, or hold CAP.
-- All VID aircraft spawn weapons hold / passive defense.
---------------------------------------------------------------------------

-- Speed envelope for VID contacts (slower = more ambiguous / civilian-like).
AAPVE_MOOSE.VIDMinSpeedKts               = 180
AAPVE_MOOSE.VIDMaxSpeedKts               = 350

-- Altitude envelope for VID contacts.
AAPVE_MOOSE.VIDMinAltFt                  = 5000
AAPVE_MOOSE.VIDMaxAltFt                  = 28000

-- VID contact lifetime before despawn (seconds).
AAPVE_MOOSE.VIDLifetimeMinSecs           = 300
AAPVE_MOOSE.VIDLifetimeMaxSecs           = 600

-- Tracks available for VID contacts.
-- "CROSSING" routes through the AOR laterally (perpendicular to threat axis).
-- "INBOUND"  routes toward the protected zone (most suspicious).
-- "COLD"     routes away from the protected zone (egressing / departing).
AAPVE_MOOSE.VIDTracks                    = { "CROSSING", "INBOUND", "COLD" }

AAPVE_MOOSE.CommitDistanceFromCapNm     = 5
AAPVE_MOOSE.CommitHeadingToleranceDeg   = 70

---------------------------------------------------------------------------
-- Bogie / aggressor behavior configuration.
--
-- Bogies spawn with weapons hold (unidentified traffic). When a client
-- commits toward the bogie (heading + proximity trigger), the bogie reacts:
--   ENGAGE: goes weapons free and attacks the package.
--   EVADE:  runs away; package is retasked; bogie despawns.
---------------------------------------------------------------------------

-- Bogie initially flies toward the CAP zone in weapons-hold at this alarm state.
-- "Auto" means it will light up its radar but not shoot unprovoked.
AAPVE_MOOSE.BogieInitialAlarmState     = "Auto"   -- "Auto" | "Red" | "Green"

-- Range at which the bogie detects a closing client (heading check applies).
AAPVE_MOOSE.BogieReactionRangeNm       = 40

-- Heading tolerance: client heading vs. bearing to bogie (degrees). If the
-- client is heading within this many degrees of the bogie it counts as a
-- "commit" that the bogie can react to.
AAPVE_MOOSE.BogieReactionHeadingDeg    = 45

-- Hard inner range: bogie reacts regardless of client heading.
AAPVE_MOOSE.BogieInnerReactRangeNm     = 15

-- Poll interval (seconds) for the bogie reaction check.
AAPVE_MOOSE.BogieMonitorIntervalSecs   = 5

-- Chance (0-100) the bogie decides to engage rather than evade.
AAPVE_MOOSE.AggressorEngageChance      = 60

-- How long (seconds) an evading bogie survives before despawning.
AAPVE_MOOSE.BogieEvadeLifetimeSecs     = 120

-- Evading bogie routes away from the CAP zone at this speed (knots).
AAPVE_MOOSE.BogieEvadeSpeedKts         = 550

---------------------------------------------------------------------------
-- Timeline spawn configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.TimelineSpawnOptions = {
    BVR = {
        Label              = "BVR",
        DistanceNm         = 80,
        SpeedKts           = 500,
        RoeAtSpawn         = "OpenFire",
        OpenFireAfterMerge = false,
    },
    WVR = {
        Label              = "WVR",
        DistanceNm         = 20,
        SpeedKts           = 450,
        RoeAtSpawn         = "OpenFire",
        OpenFireAfterMerge = false,
    },
    BFM = {
        Label              = "BFM",
        DistanceNm         = 5,
        SpeedKts           = 420,
        RoeAtSpawn         = "HoldFire",
        OpenFireAfterMerge = true,
        MergeDistanceNm    = 1.0,
    },
}

AAPVE_MOOSE.TimelineDefaultTemplate  = "AAPVE_RED_MIG29"
AAPVE_MOOSE.TimelineDefaultGroupSize = 1

---------------------------------------------------------------------------
-- TTS / MSRS configuration.
--
-- When NASGATCEnabled = true (below), all AWACS TTS is routed through
-- NASG_ATC:SendFacilityTTS() and the voice/frequency are taken from the
-- airport's AWACS facility block — values here are only the standalone
-- fallback when NASG_ATC is not loaded.
--
-- SRSPath : path to SRS install dir (leave "" for MOOSE default).
-- TTSVoice: Windows voice name, e.g. "David", "Mark", "Zira".
-- TTSVolume: 0.0 (silent) → 1.0 (full).
---------------------------------------------------------------------------

-- Pull SRS path and defaults from the Persian Gulf MSRS config if loaded.
AAPVE_MOOSE.SRSPath        = (MSRS_Config and MSRS_Config.Path)   or ""
AAPVE_MOOSE.TTSFrequency   = 251.500      -- AWACS frequency (Persian_Gulf_ATC_Config AWACS block)
AAPVE_MOOSE.TTSModulation  = radio.modulation.AM
AAPVE_MOOSE.TTSLabel       = "Magic"
AAPVE_MOOSE.TTSVoice       = (MSRS_Config and MSRS_Config.Voice)  or "Microsoft Hazel Desktop"
AAPVE_MOOSE.TTSVolume      = (MSRS_Config and MSRS_Config.Volume) or 0.6
AAPVE_MOOSE.MSRSInstance   = nil          -- persistent singleton, created in Start()

---------------------------------------------------------------------------
-- Externally configurable AWACS callsign and bullseye reference name.
--
-- Change these WITHOUT editing this script, either by:
--   • defining an AAPVE_CONFIG global in a file loaded BEFORE this one, e.g.
--       AAPVE_CONFIG = { AwacsCallsign = "Overlord", BullseyeName = "WILDCARD" }
--   • or assigning AAPVE_MOOSE.AwacsCallsign / .BullseyeName after load.
--
-- AwacsCallsign = nil  → inherit the AWACS facility callsign from NASG_ATC
--                        (config.Callsign in the external ATC config) when
--                        integration is enabled; otherwise falls back to "Magic".
-- BullseyeName  = nil  → keep MOOSE's default "BULLS" bullseye reference word.
---------------------------------------------------------------------------
AAPVE_MOOSE.AwacsCallsign = (AAPVE_CONFIG and AAPVE_CONFIG.AwacsCallsign) or nil
AAPVE_MOOSE.BullseyeName  = (AAPVE_CONFIG and AAPVE_CONFIG.BullseyeName)  or nil

---------------------------------------------------------------------------
-- NASG_ATC integration.
--
-- When NASGATCEnabled = true:
--   • All AWACS TTS routes through NASG_ATC:SendFacilityTTS() so the
--     voice, frequency, and backend are controlled by the airport's
--     AWACS facility config in NASG_ATC.
--   • NASG_ATC_AWACS voice-command handlers (CheckIn, Picture,
--     BogeyDope, VectorToTarget, CombatRecovery) are wrapped at Start()
--     to drive AAPVE_MOOSE training-range logic from player voice calls.
--
-- NASGATCAirportId must match the Id used in NASG_ATC:RegisterAirport()
-- for the carrier/airbase that hosts this training package.
--
-- Set NASGATCEnabled = false to fall back to standalone MSRS and
-- F10-menu-only control.
---------------------------------------------------------------------------

AAPVE_MOOSE.NASGATCEnabled   = true
AAPVE_MOOSE.NASGATCAirportId = "al_minhad"   -- matches Id in Persian_Gulf_ATC_Config.lua

---------------------------------------------------------------------------
-- Intercept Practice mode configuration.
--
-- Ungraded single-cycle mode.  A bogie spawns at a red spawn zone and
-- flows toward the protected zone, weapons hold, no AI reaction.  When
-- the client closes to PracticeWVRRangeNm the bogie turns cold and
-- eventually despawns.  The client returns to CAP and says "ready" to
-- request the next run.
---------------------------------------------------------------------------

AAPVE_MOOSE.PracticeTemplates      = {
    { Name = "MiG-29", Template = "AAPVE_RED_MIG29" },
    { Name = "Su-27",  Template = "AAPVE_RED_SU27"  },
}
AAPVE_MOOSE.PracticeSpeedKts       = 350
AAPVE_MOOSE.PracticeMinAltitudeFt  = 20000
AAPVE_MOOSE.PracticeMaxAltitudeFt  = 25000
AAPVE_MOOSE.PracticeWVRRangeNm     = 5.0   -- within this range = intercept complete
AAPVE_MOOSE.PracticeBogieColdSecs  = 60    -- bogey lives this long after turning cold
AAPVE_MOOSE.PracticeMonitorSecs    = 5     -- proximity poll interval

---------------------------------------------------------------------------
-- Tanker / AAR configuration.
--
-- When a client requests TEXACO, AWACS provides a BULLSEYE vector to the
-- nearest active tanker group.  The picture loop pauses for that package
-- until the client returns to their CAP zone or the timeout expires.
---------------------------------------------------------------------------

AAPVE_MOOSE.TankerGroupPrefixes    = { "TEXACO", "ARCO", "TANKER", "KC135", "KC130" }
AAPVE_MOOSE.TankerReturnTimeoutSecs = 900  -- max hold before auto-resuming picture

---------------------------------------------------------------------------
-- Scoring configuration.
--
-- Each BlueCapDefense session produces a flat ScoreCard row suitable for
-- direct insertion into a database table.  Booleans are stored as 0/1
-- integers and unrecorded numerics default to -1.
--
-- Category maxima: CAP Discipline 20 | Geometry 30 | Brevity 25
--                  Timeline 15       | Threat Awareness 10   (total 100)
-- Grades: ≥90 Excellent | ≥75 Good | ≥60 Marginal | <60 Unsat
---------------------------------------------------------------------------

AAPVE_MOOSE.ScoringEnabled         = true
AAPVE_MOOSE.BriefedCapAltitudeFt   = 25000 -- altitude clients should hold at CAP
AAPVE_MOOSE.BriefedCapAltTolFt     = 2000  -- ±tolerance before altitude violation

-- Auto TAC/MELD call distances (NM), matching Ops.AWACS default thresholds.
AAPVE_MOOSE.TACDistanceNm          = 45    -- AWACS issues PICTURE in BULLSEYE at this range
AAPVE_MOOSE.MELDDistanceNm         = 35    -- AWACS issues BRAA MELD call at this range

-- ScoreCard DB persistence (matches flightlog.lua Funkman pattern).
AAPVE_MOOSE.ScoreCardFunkmanHost   = "127.0.0.1"
AAPVE_MOOSE.ScoreCardFunkmanPort   = 10042
AAPVE_MOOSE.ScoreCardSendDelay     = 5

---------------------------------------------------------------------------
-- Aircraft templates.
---------------------------------------------------------------------------

AAPVE_MOOSE.RedCapTemplates = {
    { Name = "MiG-29", Template = "AAPVE_RED_MIG29" },
    { Name = "Su-27",  Template = "AAPVE_RED_SU27"  },
    { Name = "F-16",   Template = "AAPVE_RED_F16"   },
    { Name = "F-14",   Template = "AAPVE_RED_F14"   },
    { Name = "F-5",    Template = "AAPVE_RED_F5"    },
}

AAPVE_MOOSE.PictureHostileTemplates = {
    { Name = "MiG-29", Template = "AAPVE_RED_MIG29" },
    { Name = "Su-27",  Template = "AAPVE_RED_SU27"  },
    { Name = "F-16",   Template = "AAPVE_RED_F16"   },
    { Name = "F-14",   Template = "AAPVE_RED_F14"   },
    { Name = "F-5",    Template = "AAPVE_RED_F5"    },
}

AAPVE_MOOSE.PictureFriendlyTemplates = {
    { Name = "Friendly F/A-18", Template = "AAPVE_FRIENDLY_F18" },
    { Name = "Friendly F-16",   Template = "AAPVE_FRIENDLY_F16" },
    { Name = "Friendly F-14",   Template = "AAPVE_FRIENDLY_F14" },
}

AAPVE_MOOSE.PictureNeutralTemplates = {
    { Name = "Neutral L-39",   Template = "AAPVE_NEUTRAL_L39"   },
    { Name = "Neutral C-101",  Template = "AAPVE_NEUTRAL_C101"  },
    { Name = "Neutral FW-190", Template = "AAPVE_NEUTRAL_FW190" },
}

-- VID templates: civilian / non-combative aircraft for identification training.
-- These should be unarmed or civil-type airframes placed in the mission editor.
-- Fall back to neutral templates if VID-specific ones are not in the mission.
AAPVE_MOOSE.VIDTemplates = {
    { Name = "Friendly F/A-18", Template = "AAPVE_FRIENDLY_F18" },
    { Name = "Friendly F-16",   Template = "AAPVE_FRIENDLY_F16" },
    { Name = "Friendly F-14",   Template = "AAPVE_FRIENDLY_F14" },
    { Name = "Neutral L-39",     Template = "AAPVE_NEUTRAL_L39" },
    { Name = "Neutral C-101",    Template = "AAPVE_NEUTRAL_C101"},
}

---------------------------------------------------------------------------
-- CHIEF configuration.
-- Tune these to match how aggressively the BLUE CHIEF should respond.
---------------------------------------------------------------------------

-- How many BLUE AI assets to commit per threat (min/max).
AAPVE_MOOSE.ChiefResponseMin       = 1
AAPVE_MOOSE.ChiefResponseMax       = 2

-- CAP orbit parameters for BLUE AI flights registered with the CHIEF.
-- Altitude feet MSL, speed knots, leg length NM, heading (nil = auto).
AAPVE_MOOSE.ChiefCapAltitudeFt     = 25000
AAPVE_MOOSE.ChiefCapSpeedKts       = 450
AAPVE_MOOSE.ChiefCapLegNm          = 30

---------------------------------------------------------------------------
-- Basic helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:Log(msg)
    if self.Debug then
        env.info("[AAPVE_MOOSE] " .. tostring(msg))
    end
end

function AAPVE_MOOSE:BlueMessage(msg, secs)
    MESSAGE:New(msg, secs or 10):ToCoalition(coalition.side.BLUE)
end

function AAPVE_MOOSE:AddMenuItem(item)
    if item then
        self.MenuItems[#self.MenuItems + 1] = item
    end
    return item
end

function AAPVE_MOOSE:GetRandomOption(tbl)
    if not tbl or #tbl == 0 then return nil end
    return tbl[math.random(1, #tbl)]
end

function AAPVE_MOOSE:GetRandomRedSpawnZone()
    return self:GetRandomOption(self.RedSpawnZones)
end

function AAPVE_MOOSE:GetRandomRecoveryZone()
    return self:GetRandomOption(self.RecoveryZones)
end

function AAPVE_MOOSE:AddActiveGroup(group)
    if group then
        self.ActiveGroups[#self.ActiveGroups + 1] = group
    end
end

function AAPVE_MOOSE:DestroyGroup(group)
    if group and group:IsAlive() then
        pcall(function() group:Destroy() end)
    end
end

function AAPVE_MOOSE:GetSanitizedName(name)
    return tostring(name or "Unknown"):gsub("[^%w]", "")
end

function AAPVE_MOOSE:GetClientDisplayName(client)
    if not client then return "Unknown" end
    return client:GetPlayerName() or client:GetName() or "Unknown"
end

function AAPVE_MOOSE:GetBullseyeText(coord)
    if not coord then return "bullseye unavailable" end
    local text
    pcall(function() text = coord:ToStringBULLS(coalition.side.BLUE) end)
    if not text then
        pcall(function() text = coord:ToStringBULLS() end)
    end
    if not text then return "bullseye unavailable" end
    -- MOOSE returns "BULLS, <bearing> for <range>". Swap the leading reference
    -- token for the externally configured bullseye name when one is set.
    local name = self.BullseyeName
    if name and name ~= "" then
        text = text:gsub("^BULLS", function() return name end)
    end
    return text
end

---------------------------------------------------------------------------
-- AWACS picture word helpers.
---------------------------------------------------------------------------

-- "Angels 25" for altitudes ≥10,000 ft; "Cherubs 9" for altitudes <10,000 ft.
function AAPVE_MOOSE:AltitudeToAngels(altFt)
    if altFt < 10000 then
        return string.format("cherubs %d", math.floor(altFt / 1000))
    else
        return string.format("angels %d", math.floor(altFt / 1000))
    end
end

-- Brevity speed classification.
function AAPVE_MOOSE:SpeedToWord(speedKts)
    if speedKts < 200 then return "very slow"
    elseif speedKts < 300 then return "slow"
    elseif speedKts < 450 then return "medium"
    else return "fast"
    end
end

-- Convert a degrees bearing to the nearest 16-point cardinal direction.
function AAPVE_MOOSE:BearingToCardinal(deg)
    local dirs = {
        "north","north-northeast","northeast","east-northeast",
        "east","east-southeast","southeast","south-southeast",
        "south","south-southwest","southwest","west-southwest",
        "west","west-northwest","northwest","north-northwest",
    }
    local idx = (math.floor((deg + 11.25) / 22.5) % 16) + 1
    return dirs[idx]
end

-- Aspect brevity word based on track relative to a reference bearing.
-- trackDeg = direction the contact is flying; refDeg = bearing TO the contact.
-- HOT  = contact nose-on toward reference  (diff < 30°)
-- DRAG = contact tail-on / cold            (diff > 150°)
-- FLANKING = lateral aspect
function AAPVE_MOOSE:AspectWord(trackDeg, refDeg)
    -- Aspect angle: difference between track and the reciprocal of ref bearing.
    local reciprocal = (refDeg + 180) % 360
    local diff = self:GetHeadingDiff(trackDeg, reciprocal)
    if diff < 30 then
        return "hot"
    elseif diff > 150 then
        return "drag"
    elseif diff < 80 then
        return "flanking"
    else
        return "beaming"
    end
end

---------------------------------------------------------------------------
-- TTS.
---------------------------------------------------------------------------

-- InitMSRS: creates a persistent MSRS singleton for standalone fallback.
-- Called once from Start(); safe to call if MSRS is unavailable.
function AAPVE_MOOSE:InitMSRS()
    if not MSRS then return end
    pcall(function()
        self.MSRSInstance = MSRS:New(self.SRSPath, self.TTSFrequency, self.TTSModulation)
        self.MSRSInstance:SetCoalition(coalition.side.BLUE)
        self.MSRSInstance:SetLabel(self.TTSLabel)
        self.MSRSInstance:SetVolume(self.TTSVolume)
        self.MSRSInstance:SetVoice(self.TTSVoice)
    end)
end

-- SendTTS: preferred path is NASG_ATC:SendFacilityTTS() on the AWACS
-- facility.  Falls back to the standalone MSRS singleton if NASG_ATC is
-- not loaded or NASGATCEnabled = false.
-- Resolve the AWACS callsign spoken in proactive range calls.
--   1. explicit override (AAPVE_MOOSE.AwacsCallsign / AAPVE_CONFIG)
--   2. the NASG_ATC AWACS facility callsign (external ATC config)
--   3. "Magic"
function AAPVE_MOOSE:GetAwacsCallsign()
    if self.AwacsCallsign and self.AwacsCallsign ~= "" then
        return self.AwacsCallsign
    end

    if self.NASGATCEnabled and NASG_ATC and NASG_ATC.GetAirport
            and NASG_ATC.GetFacilityCallsign then
        local airport = NASG_ATC:GetAirport(self.NASGATCAirportId)
        if airport then
            local cs = NASG_ATC:GetFacilityCallsign(airport, NASG_ATC.Facilities.AWACS)
            if cs and cs ~= "" and tostring(cs):lower() ~= "awacs" then
                return cs
            end
        end
    end

    return "Magic"
end

-- The proactive TTS strings are authored with the literal callsign "Magic".
-- Rewrite it to the resolved callsign so the spoken callsign is controlled
-- externally without editing every call site.
function AAPVE_MOOSE:ApplyCallsign(msg)
    local cs = self:GetAwacsCallsign()
    if not cs or cs == "Magic" then return msg end
    return (tostring(msg):gsub("Magic", function() return cs end))
end

function AAPVE_MOOSE:SendTTS(msg)
    if not msg or msg == "" then return end

    msg = self:ApplyCallsign(msg)

    -- Route through NASG_ATC when enabled and available.
    if self.NASGATCEnabled
            and NASG_ATC and NASG_ATC.GetAirport and NASG_ATC.SendFacilityTTS then
        local airport = NASG_ATC:GetAirport(self.NASGATCAirportId)
        if airport then
            pcall(function()
                NASG_ATC:SendFacilityTTS(airport, NASG_ATC.Facilities.AWACS, msg)
            end)
            return
        end
        self:Log("NASG_ATC airport '" .. tostring(self.NASGATCAirportId)
            .. "' not found — falling back to standalone MSRS.")
    end

    -- Standalone MSRS fallback.
    if not self.MSRSInstance then
        self:Log("MSRS unavailable. TTS skipped: " .. msg)
        return
    end
    pcall(function() self.MSRSInstance:PlayText(msg, 0) end)
end

---------------------------------------------------------------------------
-- Geometry helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetBearingDegrees(fromCoord, toCoord)
    if not fromCoord or not toCoord then return nil end
    local a = fromCoord:GetVec2()
    local b = toCoord:GetVec2()
    if not a or not b then return nil end
    local bearing = math.deg(math.atan2(b.x - a.x, b.y - a.y))
    if bearing < 0 then bearing = bearing + 360 end
    return bearing
end

function AAPVE_MOOSE:GetHeadingDiff(hdgA, hdgB)
    if not hdgA or not hdgB then return 180 end
    local diff = math.abs(hdgA - hdgB)
    if diff > 180 then diff = 360 - diff end
    return diff
end

function AAPVE_MOOSE:GetClientHeading(client)
    if not client then return 0 end
    local hdg
    pcall(function() hdg = client:GetHeading() end)
    return hdg or 0
end

---------------------------------------------------------------------------
-- NASG_ATC session helpers.
---------------------------------------------------------------------------

-- Returns the NASG_ATC session for a client, creating one if needed.
-- Returns nil if NASG_ATC is not loaded or the airport is not registered.
function AAPVE_MOOSE:GetNASGSession(client)
    if not client or not NASG_ATC or not NASG_ATC.GetAirport then return nil end
    local airport = NASG_ATC:GetAirport(self.NASGATCAirportId)
    if not airport then return nil end
    local session
    pcall(function()
        session = NASG_ATC:GetOrCreateSession(client, airport)
    end)
    return session
end

-- Populates session.ActiveGroup for every member of the package so that
-- NASG_ATC_AWACS handlers (Declare, NoJoy, Commit, etc.) have group data.
-- Pass groupData = nil to clear (e.g. after disengage / ghost call).
function AAPVE_MOOSE:UpdateSessionGroupData(pkg, groupData)
    if not pkg then return end
    -- If we already have the session cached, update it directly.
    if pkg.NASGSession then
        pkg.NASGSession.ActiveGroup = groupData
        return
    end
    -- Fallback: walk package members and find the first live session.
    for unitName, _ in pairs(pkg.MemberUnits or {}) do
        local client = CLIENT:FindByName(unitName)
        if client and client:IsAlive() then
            local session = self:GetNASGSession(client)
            if session then
                session.ActiveGroup = groupData
                pkg.NASGSession     = session  -- cache for future calls
            end
        end
    end
end

-- Builds a group-data table with live Bulls + BRAA computed from the
-- package's active hostile group and the given client's current position.
-- Returns nil if the group is not alive or positions are unavailable.
function AAPVE_MOOSE:GetLiveGroupData(pkg, client)
    if not pkg or not pkg.ActiveHostileGroup then return nil end
    if not pkg.ActiveHostileGroup:IsAlive()  then return nil end
    local grpCoord = pkg.ActiveHostileGroup:GetCoordinate()
    if not grpCoord then return nil end

    local altFt  = math.floor(grpCoord:GetAltitude() / 0.3048)
    local bulls  = self:GetBullseyeText(grpCoord)
    local braaStr, aspectStr

    local clientCoord = client and client:GetCoordinate()
    if clientCoord then
        local distNm  = UTILS.MetersToNM(clientCoord:Get2DDistance(grpCoord))
        local bearing = self:GetBearingDegrees(clientCoord, grpCoord) or 0
        local grpHdg  = pkg.ActiveHostileGroup:GetHeading() or 0
        -- Aspect angle: difference between group track and reciprocal bearing.
        local reciprocal = (bearing + 180) % 360
        local diff = math.abs(((grpHdg - reciprocal) + 540) % 360 - 180)
        if diff < 30  then aspectStr = "hot"
        elseif diff < 60  then aspectStr = "flanking"
        elseif diff < 120 then aspectStr = "beaming"
        else  aspectStr = "drag"
        end
        braaStr = string.format("%03d/%d", math.floor(bearing), math.floor(distNm))
    end

    local size = pkg.ActiveHostileGroup:GetSize() or 1
    return {
        Bulls    = bulls,
        Braa     = braaStr,
        AltFt    = altFt,
        Aspect   = aspectStr or "hot",
        Id       = "bogey",
        Heavy    = (size >= 3),
        Contacts = size,
        Fast     = false,
    }
end

---------------------------------------------------------------------------
-- ScoreCard system.
--
-- Produces a flat database row per BlueCapDefense session.  All booleans
-- are stored as 0/1 integers; unrecorded numerics default to -1.  Internal
-- tracking fields (_prefix) are nil'd before the row is committed.
--
-- Category maxima: CAP Discipline 20 | Geometry 30 | Brevity 25
--                  Timeline 15       | Threat Awareness 10
-- Grade thresholds: ≥90 Excellent | ≥75 Good | ≥60 Marginal | <60 Unsat
---------------------------------------------------------------------------

-- Phase ordinal map — used to detect forward/backward phase transitions.
AAPVE_MOOSE._PhaseOrd = {
    PRE_COMMIT = 1, COMMITTED = 2, TARGETED = 3, MERGED = 4, POST_MERGE = 5,
}

function AAPVE_MOOSE:InitScoreCard(pkg)
    if not self.ScoringEnabled then return end
    pkg.ScoreCard = {
        -- Identity (TEXT)
        session_id          = string.format("PKG%d-%d", pkg.Id, math.floor(timer.getAbsTime())),
        pkg_id              = pkg.Id,
        client_name         = pkg.LeadClientName or "Unknown",
        unit_name           = pkg.LeadUnitName   or "Unknown",
        zone_name           = pkg.AssignedZone and pkg.AssignedZone.Name or "Unknown",
        mode                = "BlueCapDefense",
        -- Timing (REAL)
        start_abs_time      = timer.getAbsTime(),
        end_abs_time        = 0,
        duration_secs       = 0,
        -- CAP Discipline  (INTEGER, base 20 — deductions applied)
        cap_score           = 20,
        cap_zone_exits      = 0,
        cap_alt_violations  = 0,
        ghost_commits       = 0,
        -- Geometry  (INTEGER, base 0 — additions applied)
        geo_score           = 0,
        commit_range_nm     = -1,
        shot_range_nm       = -1,
        shot_aspect         = "",
        merge_range_nm      = -1,
        intercept_time_secs = -1,
        _commit_time        = 0,     -- internal; not stored
        -- Brevity  (INTEGER, base 0 — additions applied)
        brev_score          = 0,
        commit_called       = 0,
        targeted_called     = 0,
        fox_called          = 0,
        fox_type            = -1,  -- 1=Fox1(SARH) 2=Fox2(IR) 3=Fox3(ARH); -1=not recorded
        merge_called        = 0,
        splash_called       = 0,
        threat_calls        = 0,
        threat_acks         = 0,
        -- Timeline  (INTEGER, base 0 — additions applied)
        timeline_score      = 0,
        phases_completed    = 0,
        phases_skipped      = 0,
        _last_phase_ord     = 0,     -- internal; not stored
        -- Threat Awareness  (INTEGER, base 10 — deductions applied)
        threat_score        = 10,
        vid_holds           = 0,
        vid_unnecessary     = 0,
        -- Final
        total_score         = 0,
        max_score           = 100,
        grade               = "",
        kill_confirmed      = 0,
        pilot_killed        = 0,   -- 1 = the Blue pilot was shot down / died
    }
end

function AAPVE_MOOSE:RecordScoreEvent(pkg, eventType, data)
    if not self.ScoringEnabled then return end
    local sc = pkg and pkg.ScoreCard
    if not sc then return end
    data = data or {}

    if eventType == "cap_zone_exit" then
        sc.cap_zone_exits  = sc.cap_zone_exits + 1
        sc.cap_score       = math.max(0, sc.cap_score - 5)

    elseif eventType == "cap_alt_violation" then
        sc.cap_alt_violations = sc.cap_alt_violations + 1
        sc.cap_score          = math.max(0, sc.cap_score - 5)

    elseif eventType == "ghost_commit" then
        sc.ghost_commits = sc.ghost_commits + 1
        sc.cap_score     = math.max(0, sc.cap_score - 15)

    elseif eventType == "commit" then
        local rNm = data.range_nm or -1
        sc.commit_range_nm = rNm
        sc._commit_time    = timer.getAbsTime()
        -- Score vs. TAC range window (ACC default 60 NM, Line 1199).
        if rNm >= 40 and rNm <= 70 then
            sc.geo_score = sc.geo_score + 10  -- optimal BVR window
        elseif rNm >= 20 then
            sc.geo_score = sc.geo_score + 5   -- late but BVR
        else
            sc.geo_score = math.max(0, sc.geo_score - 5) -- WVR or already merged
        end

    elseif eventType == "fox" then
        local rNm    = data.range_nm or -1
        local aspect = data.aspect   or ""
        local ftype  = data.fox_type or 3
        sc.shot_range_nm = rNm
        sc.shot_aspect   = aspect
        sc.fox_called    = 1
        sc.fox_type      = ftype
        sc.brev_score    = sc.brev_score + 5

        -- Aspect geometry bonus.
        if aspect == "hot" or aspect == "flanking" then
            sc.geo_score = sc.geo_score + 10  -- good shot geometry
        else
            sc.geo_score = math.max(0, sc.geo_score - 5) -- poor aspect
        end

        -- Per missile type range validity check.
        -- Fox 1 (SARH): requires continuous radar illumination; valid ≤25 NM.
        -- Fox 2 (IR):   heat-seeker; valid WVR ≤15 NM.
        -- Fox 3 (ARH):  active radar; valid BVR >5 NM.
        local validShot = false
        if ftype == 1 then
            validShot = rNm > 0 and rNm <= 25
        elseif ftype == 2 then
            validShot = rNm > 0 and rNm <= 15
        else  -- Fox 3 default
            validShot = rNm > (self.MergeRangeNm or 5)
        end

        if validShot then
            sc.geo_score = sc.geo_score + 5  -- in-envelope employment
        else
            sc.geo_score = math.max(0, sc.geo_score - 5)  -- out-of-envelope shot
        end

    elseif eventType == "merge" then
        local rNm = data.range_nm or -1
        sc.merge_range_nm = rNm
        sc.merge_called   = 1
        sc.brev_score     = sc.brev_score + 5
        -- Doctrine: merge within 3-5 NM (ACC Line 1382).
        if rNm >= 2 and rNm <= 6 then
            sc.geo_score = sc.geo_score + 5
        end
        if sc._commit_time > 0 then
            sc.intercept_time_secs = math.floor(timer.getAbsTime() - sc._commit_time)
            if sc.intercept_time_secs <= 240 then  -- ≤4 min = efficient intercept
                sc.geo_score = sc.geo_score + 5
            end
        end

    elseif eventType == "splash" then
        sc.splash_called  = 1
        sc.kill_confirmed = 1
        sc.brev_score     = sc.brev_score + 5

    elseif eventType == "targeted_called" then
        sc.targeted_called = 1
        sc.brev_score      = sc.brev_score + 5

    elseif eventType == "commit_called" then
        sc.commit_called = 1
        sc.brev_score    = sc.brev_score + 5

    elseif eventType == "threat_call" then
        sc.threat_calls = sc.threat_calls + 1

    elseif eventType == "threat_ack" then
        sc.threat_acks  = sc.threat_acks + 1
        sc.threat_score = math.min(10, sc.threat_score + 5)

    elseif eventType == "vid_hold" then
        sc.vid_holds    = sc.vid_holds + 1
        sc.threat_score = math.min(10, sc.threat_score + 10)

    elseif eventType == "vid_commit" then
        sc.vid_unnecessary = sc.vid_unnecessary + 1
        sc.threat_score    = math.max(0, sc.threat_score - 10)

    elseif eventType == "phase_advance" then
        local ord = self._PhaseOrd[data.phase or ""] or 0
        if ord > 0 then
            sc.phases_completed = sc.phases_completed + 1
            local skipped = math.max(0, ord - sc._last_phase_ord - 1)
            sc.phases_skipped = sc.phases_skipped + skipped
            sc._last_phase_ord = ord
            if ord >= 5 then  -- POST_MERGE completed — full timeline bonus
                sc.timeline_score = math.min(15, sc.timeline_score + 20)
            else
                sc.timeline_score = math.min(15, sc.timeline_score + 3)
            end
            sc.timeline_score = math.max(0, sc.timeline_score - skipped * 5)
        end

    elseif eventType == "pilot_dead" then
        -- Blue pilot was shot down or died. Record the loss once — Dead,
        -- Crash and PilotDead can all fire for a single death.
        if sc.pilot_killed == 1 then return end
        sc.pilot_killed = 1
        -- A shootdown is a training failure: forfeit any geometry earned and
        -- apply a threat-awareness penalty for losing situational awareness.
        sc.geo_score    = 0
        sc.threat_score = math.max(0, sc.threat_score - 10)
        self:Log(string.format("Package %d: Blue pilot %s down — scored as loss.",
            pkg.Id, tostring(data.unit_name or sc.unit_name)))
    end
end

function AAPVE_MOOSE:FinalizeScoreCard(pkg)
    if not self.ScoringEnabled then return end
    local sc = pkg and pkg.ScoreCard
    if not sc or sc.end_abs_time > 0 then return end  -- guard against double-finalize

    sc.end_abs_time  = timer.getAbsTime()
    sc.duration_secs = math.floor(sc.end_abs_time - sc.start_abs_time)

    -- Threat acknowledgment rate bonus.
    if sc.threat_calls > 0 and (sc.threat_acks / sc.threat_calls) >= 0.8 then
        sc.threat_score = math.min(10, sc.threat_score + 5)
    end

    -- Clamp categories to their maxima.
    sc.cap_score      = math.max(0, math.min(20, sc.cap_score))
    sc.geo_score      = math.max(0, math.min(30, sc.geo_score))
    sc.brev_score     = math.max(0, math.min(25, sc.brev_score))
    sc.timeline_score = math.max(0, math.min(15, sc.timeline_score))
    sc.threat_score   = math.max(0, math.min(10, sc.threat_score))

    -- Strip internal tracking fields before storing.
    sc._commit_time    = nil
    sc._last_phase_ord = nil

    sc.total_score = sc.cap_score + sc.geo_score + sc.brev_score
                   + sc.timeline_score + sc.threat_score

    if     sc.total_score >= 90 then sc.grade = "Excellent"
    elseif sc.total_score >= 75 then sc.grade = "Good"
    elseif sc.total_score >= 60 then sc.grade = "Marginal"
    else                              sc.grade = "Unsat"
    end

    self.ScoreDatabase[sc.session_id] = sc

    -- F10 debrief message.
    self:BlueMessage(string.format(
        "A/A PVE Range — Session Debrief\n"..
        "Pilot: %s  |  Package: %d  |  Duration: %d min\n"..
        "CAP Discipline : %d / 20\n"..
        "Geometry       : %d / 30\n"..
        "Brevity        : %d / 25\n"..
        "Timeline       : %d / 15\n"..
        "Threat Aware   : %d / 10\n"..
        "TOTAL: %d / 100  —  %s",
        sc.client_name, sc.pkg_id, math.floor(sc.duration_secs / 60),
        sc.cap_score, sc.geo_score, sc.brev_score,
        sc.timeline_score, sc.threat_score,
        sc.total_score, sc.grade), 60)

    self:SendTTS(string.format(
        "Magic, CAP package %d debrief. Total score %d of one hundred. Grade %s. "..
        "CAP discipline %d, geometry %d, brevity %d, timeline %d, threat awareness %d.",
        pkg.Id, sc.total_score, sc.grade,
        sc.cap_score, sc.geo_score, sc.brev_score,
        sc.timeline_score, sc.threat_score))

    self:Log(string.format("ScoreCard finalized: %s  score=%d  grade=%s",
        sc.session_id, sc.total_score, sc.grade))

    -- Persist to database (delayed to let the debrief TTS play first).
    -- SaveScoreCardToDB  → raw score card blob (onAAPVEScoreCard).
    -- SaveAWIScoreToDB   → clean PilotAWIScore row with UCID (onPilotAWIScore).
    timer.scheduleFunction(function()
        AAPVE_MOOSE:SaveScoreCardToDB(sc)
        AAPVE_MOOSE:SaveAWIScoreToDB(sc)
    end, nil, timer.getTime() + self.ScoreCardSendDelay)
end

---------------------------------------------------------------------------
-- ScoreCard DB persistence.
--
-- Mirrors the flightlog.lua pattern:
--   Primary  : dcsbot.sendBotTable() when the DCSBot webhook bridge is loaded.
--   Fallback : direct UDP socket to Funkman (same host:port as flightlog).
-- The `command` field tells the backend handler which table to write.
---------------------------------------------------------------------------

function AAPVE_MOOSE:SaveScoreCardToDB(sc)
    if not sc then return end
    sc.server_name = BASE.ServerName or "Unknown"
    sc.command     = "onAAPVEScoreCard"

    -- Primary: dcsbot webhook (matches flightlog.lua pattern).
    if dcsbot and dcsbot.sendBotTable then
        pcall(function() dcsbot.sendBotTable(sc) end)
        self:Log("ScoreCard sent via dcsbot: " .. tostring(sc.session_id))
        return
    end

    -- Fallback: direct UDP to Funkman.
    if json and socket then
        pcall(function()
            local s = socket.udp()
            s:settimeout(0)
            s:sendto(json:encode(sc), self.ScoreCardFunkmanHost, self.ScoreCardFunkmanPort)
            s:close()
        end)
        self:Log("ScoreCard sent via UDP: " .. tostring(sc.session_id))
        return
    end

    self:Log("ScoreCard save skipped: no dcsbot or socket available. session_id=" .. tostring(sc.session_id))
end

---------------------------------------------------------------------------
-- Save intercept score to the PilotAWIScore database table.
--
-- Follows the same dcsbot / Funkman pattern as flightlog.lua:
--   1. Look up the player UCID from net.get_player_list() by client_name.
--   2. Build a clean flat row (strip internal _prefix fields).
--   3. Primary path: dcsbot.sendBotTable with command = "onPilotAWIScore".
--   4. Fallback: JSON over UDP to Funkman if dcsbot is unavailable.
--
-- The DCSServerBot handler for "onPilotAWIScore" is expected to INSERT
-- (or UPSERT) the row into the PilotAWIScore table, keyed on session_id.
---------------------------------------------------------------------------

function AAPVE_MOOSE:SaveAWIScoreToDB(sc)
    if not sc then return end

    -- ── 1. UCID lookup (mirrors flightlog.lua ucid_from_name) ────────────
    local ucid = "Unknown"
    pcall(function()
        if net and net.get_player_list and sc.client_name then
            for _, id in pairs(net.get_player_list()) do
                local p = net.get_player_info(id)
                if p and p.name == sc.client_name then
                    ucid = p.ucid or ucid
                    break
                end
            end
        end
    end)

    -- ── 2. Build the clean DB row ─────────────────────────────────────────
    -- Copy all public fields (skip anything prefixed with _ which are
    -- internal-tracking-only and not suitable for DB storage).
    local row = {}
    for k, v in pairs(sc) do
        if type(k) == "string" and k:sub(1, 1) ~= "_" then
            row[k] = v
        end
    end

    -- Mandatory envelope fields (matches flightlog.lua sendToFunkman pattern).
    row.ucid        = ucid
    row.server_name = (BASE and BASE.ServerName) or "Unknown"
    row.command     = "onPilotAWIScore"

    -- ── 3. Primary path: dcsbot webhook ──────────────────────────────────
    if dcsbot and dcsbot.sendBotTable then
        pcall(function() dcsbot.sendBotTable(row) end)
        self:Log("AWI score sent via dcsbot: " .. tostring(row.session_id)
            .. "  ucid=" .. ucid .. "  score=" .. tostring(row.total_score))
        return
    end

    -- ── 4. Fallback: UDP to Funkman ───────────────────────────────────────
    if json and socket then
        pcall(function()
            local s = socket.udp()
            s:settimeout(0)
            s:sendto(json:encode(row), self.ScoreCardFunkmanHost, self.ScoreCardFunkmanPort)
            s:close()
        end)
        self:Log("AWI score sent via UDP: " .. tostring(row.session_id))
        return
    end

    self:Log("AWI score save skipped: no dcsbot or socket available. session_id="
        .. tostring(row.session_id))
end

---------------------------------------------------------------------------
-- Per-package FSM factory.
--
-- Each CAP package gets its own FSM:
--   Assigned -> OnStation -> Committed -> Retasking -> OnStation (loop)
--   Any state -> Closed
--
-- The monitor loop calls package.FSM:GetCurrentState() to check status
-- and fires transition events (ArriveStation, Commit, Disengage, Close).
---------------------------------------------------------------------------

function AAPVE_MOOSE:CreatePackageFSM(package)
    local fsm = FSM:New()
    fsm:SetStartState("Assigned")
    fsm:AddTransition("Assigned",   "ArriveStation", "OnStation")
    fsm:AddTransition("Retasking",  "ArriveStation", "OnStation")
    fsm:AddTransition("OnStation",  "Commit",        "Committed")
    fsm:AddTransition("Committed",  "Disengage",     "Retasking")
    fsm:AddTransition("*",          "Close",         "Closed")

    -- On arriving station: announce and mark.
    function fsm:OnAfterArriveStation(From, Event, To)
        AAPVE_MOOSE:BlueMessage(
            string.format("A/A PVE Range: CAP Package %d is on station.", package.Id), 10)
        AAPVE_MOOSE:SendTTS(
            string.format("Magic, CAP package %d on station. Picture generation active.", package.Id))
        package.EmptySince = nil
        AAPVE_MOOSE:MarkCapPackage(package)
    end

    -- On commit: announce package is hot; advance NASG_ATC session phase.
    function fsm:OnAfterCommit(From, Event, To)
        AAPVE_MOOSE:BlueMessage(
            string.format("A/A PVE Range: CAP Package %d committed.", package.Id), 10)
        if AAPVE_MOOSE.Debug then
            AAPVE_MOOSE:SendTTS(
                string.format("Magic, CAP package %d committed.", package.Id))
        end
        AAPVE_MOOSE:MarkCapPackage(package)
        -- Advance intercept phase so voice queries switch to BRAA format.
        if package.NASGSession and NASG_ATC_AWACS then
            NASG_ATC_AWACS:AdvancePhase(package.NASGSession,
                NASG_ATC_AWACS.InterceptPhase.COMMITTED)
        end
        AAPVE_MOOSE:RecordScoreEvent(package, "phase_advance", { phase = "COMMITTED" })
    end

    -- On disengage: retask to CAP; reset hostile and NASG_ATC session.
    function fsm:OnAfterDisengage(From, Event, To, reason)
        local coord = package.AssignedZone and package.AssignedZone.Zone:GetCoordinate()
        local bulls = coord and AAPVE_MOOSE:GetBullseyeText(coord) or "station"
        package.ActiveHostileGroup = nil
        package.CommitAnnounced    = false
        AAPVE_MOOSE:BlueMessage(
            string.format(
                "A/A PVE Range\nPackage %d: %s\nResume CAP: %s\nPosition: %s\nPicture resumes when back on station.",
                package.Id, reason or "Threat neutralized.",
                package.AssignedZone and package.AssignedZone.Name or "CAP", bulls),
            30)
        AAPVE_MOOSE:SendTTS(
            string.format("Magic, CAP package %d, %s Resume %s, %s.",
                package.Id, reason or "threat neutralized.",
                package.AssignedZone and package.AssignedZone.Name or "assigned CAP", bulls))
        AAPVE_MOOSE:MarkCapPackage(package)
        -- Clear group data and reset intercept phase to PRE_COMMIT so
        -- subsequent PICTURE calls revert to BULLSEYE format.
        if package.NASGSession and NASG_ATC_AWACS then
            NASG_ATC_AWACS:ResetPhase(package.NASGSession)
        end
        AAPVE_MOOSE:UpdateSessionGroupData(package, nil)
    end

    -- On close: destroy hostile, remove marker, clear NASG_ATC session data.
    function fsm:OnAfterClose(From, Event, To, reason)
        if package.ActiveHostileGroup then
            AAPVE_MOOSE:DestroyGroup(package.ActiveHostileGroup)
            package.ActiveHostileGroup = nil
        end
        package.MemberUnits = {}
        package.MemberNames = {}
        package.EmptySince  = nil
        AAPVE_MOOSE:RemoveCapPackageMarker(package)
        AAPVE_MOOSE:BlueMessage(
            string.format("A/A PVE Range: CAP Package %d closed. %s",
                package.Id, reason or ""), 15)
        -- Finalize scoring before detaching session.
        AAPVE_MOOSE:FinalizeScoreCard(package)
        -- Detach session so stale group data is not served after close.
        if package.NASGSession then
            package.NASGSession.ActiveGroup    = nil
            package.NASGSession.InterceptPhase = nil
            package.NASGSession = nil
        end
    end

    package.FSM = fsm
    return fsm
end

---------------------------------------------------------------------------
-- Main range FSM.
--
-- States: Stopped -> Idle -> RedCapPractice / BlueCapDefense
-- OnBefore* guards reject invalid transitions so menus need no extra logic.
---------------------------------------------------------------------------

AAPVE_MOOSE.RangeFSM = FSM:New()
AAPVE_MOOSE.RangeFSM:SetStartState("Stopped")
AAPVE_MOOSE.RangeFSM:AddTransition("Stopped",                         "Start",        "Idle")
AAPVE_MOOSE.RangeFSM:AddTransition("Idle",                            "StartRedCap",  "RedCapPractice")
AAPVE_MOOSE.RangeFSM:AddTransition("Idle",                            "StartBlueCap", "BlueCapDefense")
AAPVE_MOOSE.RangeFSM:AddTransition({"RedCapPractice","BlueCapDefense","InterceptPractice"}, "StopMode", "Idle")
AAPVE_MOOSE.RangeFSM:AddTransition("Idle",                            "StartPractice","InterceptPractice")
AAPVE_MOOSE.RangeFSM:AddTransition("*",                               "Shutdown",     "Stopped")

-- Guard: prevent starting a mode when not idle.
function AAPVE_MOOSE.RangeFSM:OnBeforeStartRedCap(From, Event, To)
    if From ~= "Idle" then
        AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
        return false
    end
end

function AAPVE_MOOSE.RangeFSM:OnBeforeStartBlueCap(From, Event, To)
    if From ~= "Idle" then
        AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
        return false
    end
end

function AAPVE_MOOSE.RangeFSM:OnBeforeStartPractice(From, Event, To)
    if From ~= "Idle" then
        AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
        return false
    end
end

function AAPVE_MOOSE.RangeFSM:OnAfterStartPractice(From, Event, To)
    AAPVE_MOOSE:StartInterceptPracticeMode()
end

function AAPVE_MOOSE.RangeFSM:OnAfterStart(From, Event, To)
    AAPVE_MOOSE:BlueMessage("A/A PVE Range is online.", 10)
end

function AAPVE_MOOSE.RangeFSM:OnAfterStartRedCap(From, Event, To)
    AAPVE_MOOSE:StartRedCapPracticeMode()
end

function AAPVE_MOOSE.RangeFSM:OnAfterStartBlueCap(From, Event, To)
    AAPVE_MOOSE:StartBlueCapDefenseMode()
end

function AAPVE_MOOSE.RangeFSM:OnAfterStopMode(From, Event, To)
    AAPVE_MOOSE:ClearRange()
    AAPVE_MOOSE:BlueMessage("A/A PVE Range returned to idle.", 10)
end

function AAPVE_MOOSE.RangeFSM:OnAfterShutdown(From, Event, To)
    AAPVE_MOOSE:ClearRange(false)
end

-- Convenience accessor used by guards/checks elsewhere.
function AAPVE_MOOSE:GetRangeMode()
    return self.RangeFSM:GetCurrentState()
end

---------------------------------------------------------------------------
-- CHIEF integration.
--
-- The BLUE CHIEF monitors the protected zone as a border, registers each
-- CAP hold zone as a CAP orbit, and responds to air threats automatically.
-- DEFCON changes are announced via TTS to give players situational awareness.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartBlueChief()
    if self.BlueChief then return end
    if not CHIEF then
        self:Log("CHIEF class unavailable. Skipping CHIEF setup.")
        return
    end

    self.BlueChief = CHIEF:New(coalition.side.BLUE, self.BlueDetectionSet, "AAPVE Blue Chief")

    -- Strategy: DEFENSIVE - respond to threats inside border, do not initiate.
    self.BlueChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

    -- Border zone: enemy presence here escalates DEFCON to RED.
    if self.ProtectedZone then
        self.BlueChief:AddBorderZone(self.ProtectedZone)
    end

    -- Register each BLUE CAP hold as a CAP orbit zone so the CHIEF can
    -- assign AI assets to patrol them (requires BLUE airwing set up in the mission).
    local capAltM  = UTILS.FeetToMeters(self.ChiefCapAltitudeFt)
    local capSpdMs = UTILS.KnotsToMps(self.ChiefCapSpeedKts)
    local capLegM  = UTILS.NMToMeters(self.ChiefCapLegNm)

    for _, capZone in ipairs(self.BlueCapZones) do
        if capZone and capZone.Zone then
            pcall(function()
                self.BlueChief:AddCapZone(capZone.Zone, capAltM, capSpdMs, nil, capLegM)
            end)
        end
    end

    -- Configure minimum assets committed per air threat.
    pcall(function()
        self.BlueChief:SetResponseOnTarget(
            self.ChiefResponseMin,
            self.ChiefResponseMax,
            0,
            TARGET.Category.AIRCRAFT
        )
    end)

    -- DEFCON change callback: TTS announcement so players know the threat level.
    function self.BlueChief:OnAfterDefconChange(From, Event, To, Defcon)
        local label = Defcon or To
        AAPVE_MOOSE:BlueMessage(
            string.format("A/A PVE Range: BLUE CHIEF DEFCON changed to %s.", tostring(label)), 15)
        AAPVE_MOOSE:SendTTS(
            string.format("Magic, BLUE defense condition is now %s.", tostring(label)))
        AAPVE_MOOSE:Log("CHIEF DEFCON -> " .. tostring(label))
    end

    -- Strategy change callback: log for situational awareness.
    function self.BlueChief:OnAfterStrategyChange(From, Event, To, Strategy)
        AAPVE_MOOSE:Log("CHIEF Strategy -> " .. tostring(Strategy))
    end

    self.BlueChief:Start()
    self:BlueMessage("A/A PVE Range: BLUE CHIEF active (DEFENSIVE).", 10)
    self:Log("BLUE CHIEF started.")
end

function AAPVE_MOOSE:StopBlueChief()
    if self.BlueChief then
        pcall(function() self.BlueChief:Stop() end)
        self.BlueChief = nil
        self:Log("BLUE CHIEF stopped.")
    end
end

---------------------------------------------------------------------------
-- FOX Missile Trainer.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ToggleFoxTrainer()
    self.FoxTrainerEnabled = not self.FoxTrainerEnabled
    if self.FoxTrainerEnabled then
        self:StartFoxTrainer()
        self:BlueMessage("A/A PVE Range: FOX Missile Trainer ENABLED.", 10)
    else
        self:StopFoxTrainer()
        self:BlueMessage("A/A PVE Range: FOX Missile Trainer DISABLED.", 10)
    end
end

function AAPVE_MOOSE:StartFoxTrainer()
    if self.FoxTrainer then return end
    if not FOX then
        self:BlueMessage("A/A PVE Range: FOX class unavailable in this MOOSE build.", 10)
        self.FoxTrainerEnabled = false
        return
    end
    self.FoxTrainer = FOX:New()
    pcall(function() self.FoxTrainer:SetExplosionDistance(500)      end)
    pcall(function() self.FoxTrainer:SetDisableF10Menu()            end)
    pcall(function() self.FoxTrainer:SetDefaultLaunchAlerts(true)   end)
    pcall(function() self.FoxTrainer:SetDefaultLaunchMarks(false)   end)
    pcall(function() self.FoxTrainer:Start()                        end)
end

function AAPVE_MOOSE:StopFoxTrainer()
    if self.FoxTrainer then
        pcall(function() self.FoxTrainer:Stop() end)
        self.FoxTrainer = nil
    end
end

---------------------------------------------------------------------------
-- CAP zone helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:IsCapZoneAssigned(capZone)
    if not capZone then return false end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and pkg.FSM:Is("Closed") == false
                and pkg.AssignedZone
                and pkg.AssignedZone.Name == capZone.Name then
            return true
        end
    end
    return false
end

function AAPVE_MOOSE:GetAvailableCapZone()
    local available = {}
    for _, capZone in ipairs(self.BlueCapZones) do
        if capZone and capZone.Zone and not self:IsCapZoneAssigned(capZone) then
            available[#available + 1] = capZone
        end
    end
    if #available == 0 then return nil end
    return available[math.random(1, #available)]
end

function AAPVE_MOOSE:GetActivePackageCount()
    local count = 0
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed") then
            count = count + 1
        end
    end
    return count
end

function AAPVE_MOOSE:GetGlobalActiveHostileCount()
    local count = 0
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed")
                and pkg.ActiveHostileGroup
                and pkg.ActiveHostileGroup:IsAlive() then
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- AOR zone helpers.
---------------------------------------------------------------------------

-- Returns true if coord falls inside the package's AOR zone.
-- If the package has no AOR zone defined, every coordinate is considered
-- in-AOR (graceful degradation for missions that omit the zones).
function AAPVE_MOOSE:IsInPackageAor(pkg, coord)
    if not coord then return false end
    local aorZone = pkg.AssignedZone and pkg.AssignedZone.AorZone
    if not aorZone then return true end
    return aorZone:IsCoordinateInZone(coord) == true
end

-- Returns the AOR zone object for a package, or nil.
function AAPVE_MOOSE:GetPackageAorZone(pkg)
    return pkg.AssignedZone and pkg.AssignedZone.AorZone or nil
end

-- Returns a coordinate that is clearly outside the package's AOR zone.
-- Tries to use the centre of another active package's AOR zone first (so the
-- ghost call lands in a real sector), then falls back to a computed offset.
function AAPVE_MOOSE:GetOutOfAorCoordinate(pkg, distNm)
    local dist = UTILS.NMToMeters(distNm or 120)

    -- Prefer another active package's AOR zone centre.
    for _, other in pairs(self.CapPackages) do
        if other ~= pkg and not other.FSM:Is("Closed") then
            local otherAor = self:GetPackageAorZone(other)
            if otherAor then
                return otherAor:GetCoordinate()
            end
        end
    end

    -- Prefer an unassigned CAP zone's AOR.
    for _, capEntry in ipairs(self.BlueCapZones) do
        if capEntry.AorZone and not self:IsCapZoneAssigned(capEntry) then
            return capEntry.AorZone:GetCoordinate()
        end
    end

    -- Fallback: angular offset from sandbox centre, ≥90° away from package CAP.
    local refCoord = self.SandboxZone and self.SandboxZone:GetCoordinate()
    if not refCoord then return nil end
    local capCoord = pkg.AssignedZone and pkg.AssignedZone.Zone:GetCoordinate()
    if not capCoord then return nil end
    local capBear  = self:GetBearingDegrees(refCoord, capCoord) or 0
    local offset   = (self.GhostCallMinAngleOffsetDeg or 90)
    local ghostBear = (capBear + offset + math.random(0, 180)) % 360
    return refCoord:Translate(dist, ghostBear)
end

-- Sends a training warning when a client commits to a contact outside their AOR.
function AAPVE_MOOSE:WarnOutOfAorCommit(pkg)
    local zoneName = pkg.AssignedZone and pkg.AssignedZone.Name or "your sector"
    self:BlueMessage(
        string.format(
            "A/A PVE Range: Package %d — TRAINING ALERT\n"..
            "You are committing to a contact OUTSIDE your AOR (%s).\n"..
            "Hold CAP. This contact belongs to another sector.\n"..
            "Return to your assigned CAP zone.",
            pkg.Id, zoneName),
        20)
    self:SendTTS(
        string.format(
            "Magic, CAP package %d, KNOCK IT OFF. Contact is outside your AOR. "..
            "Return to %s. Hold CAP.",
            pkg.Id, zoneName))
    self:RecordScoreEvent(pkg, "ghost_commit")
    self:Log(string.format("Package %d out-of-AOR commit warning issued.", pkg.Id))
end

---------------------------------------------------------------------------
-- CAP package lookup.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetPackageByLeadUnit(unitName)
    if not unitName then return nil end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed") and pkg.LeadUnitName == unitName then
            return pkg
        end
    end
    return nil
end

function AAPVE_MOOSE:GetPackageByMemberUnit(unitName)
    if not unitName then return nil end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed")
                and pkg.MemberUnits and pkg.MemberUnits[unitName] then
            return pkg
        end
    end
    return nil
end

function AAPVE_MOOSE:GetPackageByHostileGroup(groupName)
    if not groupName then return nil end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed")
                and pkg.ActiveHostileGroup
                and pkg.ActiveHostileGroup:GetName() == groupName then
            return pkg
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Package marking / tasking messages.
---------------------------------------------------------------------------

function AAPVE_MOOSE:RemoveCapPackageMarker(pkg)
    if pkg and pkg.MarkerId then
        pcall(function() COORDINATE:RemoveMark(pkg.MarkerId) end)
        pkg.MarkerId = nil
    end
end

function AAPVE_MOOSE:MarkCapPackage(pkg)
    if not pkg or not pkg.AssignedZone or not pkg.AssignedZone.Zone then return end
    local coord = pkg.AssignedZone.Zone:GetCoordinate()
    if not coord then return end

    local bulls  = self:GetBullseyeText(coord)
    local members = table.concat(pkg.MemberNames or {}, ", ")
    if members == "" then members = "Unknown" end

    self:RemoveCapPackageMarker(pkg)
    pkg.MarkerId = coord:MarkToCoalition(
        string.format(
            "A/A PVE CAP PACKAGE %d\nLead: %s\nHold: %s\n%s\nStatus: %s\nMembers: %s",
            pkg.Id,
            pkg.LeadClientName or "Unknown",
            pkg.AssignedZone.Name or "Unknown",
            bulls,
            pkg.FSM:GetCurrentState(),
            members),
        coalition.side.BLUE,
        true)
end

function AAPVE_MOOSE:SendPackageTasking(pkg, isReminder)
    if not pkg or not pkg.AssignedZone or not pkg.AssignedZone.Zone then return end
    local coord   = pkg.AssignedZone.Zone:GetCoordinate()
    local bulls   = self:GetBullseyeText(coord)
    local prefix  = isReminder and "CAP tasking reminder" or "CAP check-in accepted"
    local members = table.concat(pkg.MemberNames or {}, ", ")
    if members == "" then members = "Unknown" end

    -- Build altitude block string for display and TTS.
    local altBlock = ""
    local altTTS   = ""
    if pkg.AssignedZone.AltMinFt and pkg.AssignedZone.AltMaxFt then
        altBlock = string.format("Altitude Block: %d - %d ft",
            pkg.AssignedZone.AltMinFt, pkg.AssignedZone.AltMaxFt)
        altTTS   = string.format(", altitude block %s to %s",
            self:AltitudeToAngels(pkg.AssignedZone.AltMinFt),
            self:AltitudeToAngels(pkg.AssignedZone.AltMaxFt))
    end

    self:BlueMessage(
        string.format(
            "A/A PVE %s\nPackage: %d\nLead: %s\nHold: %s\nPosition: %s\n%s\nMembers: %s\nProceed as a flight and hold CAP.",
            prefix, pkg.Id,
            pkg.LeadClientName or "Unknown",
            pkg.AssignedZone.Name or "Unknown",
            bulls,
            altBlock ~= "" and altBlock or "Altitude: unrestricted",
            members),
        30)
    self:MarkCapPackage(pkg)
    self:SendTTS(
        string.format("Magic, CAP package %d, proceed to %s, %s%s. Hold CAP and sanitize.",
            pkg.Id, pkg.AssignedZone.Name or "assigned CAP", bulls, altTTS))
end

---------------------------------------------------------------------------
-- Clients near a lead.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetClientsNearLead(leadClient, radiusNm)
    local units = {}
    local names = {}
    if not leadClient or not leadClient:IsAlive() then return units, names end
    local leadCoord = leadClient:GetCoordinate()
    if not leadCoord then return units, names end
    local radM = UTILS.NMToMeters(radiusNm or self.CapCheckInRadiusNm)

    self.BlueClientSet:ForEachClient(function(c)
        if c and c:IsAlive() then
            local coord = c:GetCoordinate()
            if coord and leadCoord:Get2DDistance(coord) <= radM then
                local uname = c:GetName()
                if uname then
                    units[uname] = true
                    names[#names + 1] = self:GetClientDisplayName(c)
                end
            end
        end
    end)
    return units, names
end

---------------------------------------------------------------------------
-- Client counting within zones.
---------------------------------------------------------------------------

function AAPVE_MOOSE:CountPackageMembersOnStation(pkg)
    if not pkg or not pkg.MemberUnits or not pkg.AssignedZone then return 0 end
    local count = 0
    self.BlueClientSet:ForEachClient(function(c)
        if c and c:IsAlive() then
            local uname = c:GetName()
            local coord = c:GetCoordinate()
            if uname and pkg.MemberUnits[uname] and coord
                    and pkg.AssignedZone.Zone:IsCoordinateInZone(coord) then
                count = count + 1
            end
        end
    end)
    return count
end

function AAPVE_MOOSE:CountPackageMembersInSandbox(pkg)
    if not pkg or not pkg.MemberUnits or not self.SandboxZone then return 0 end
    local count = 0
    self.BlueClientSet:ForEachClient(function(c)
        if c and c:IsAlive() then
            local uname = c:GetName()
            local coord = c:GetCoordinate()
            if uname and pkg.MemberUnits[uname] and coord
                    and self.SandboxZone:IsCoordinateInZone(coord) then
                count = count + 1
            end
        end
    end)
    return count
end

function AAPVE_MOOSE:GetRepresentativeMemberCoord(pkg)
    if not pkg or not pkg.MemberUnits then return nil end
    local best
    self.BlueClientSet:ForEachClient(function(c)
        if not best and c and c:IsAlive() then
            local uname = c:GetName()
            if uname and pkg.MemberUnits[uname] then
                best = c:GetCoordinate()
            end
        end
    end)
    return best
end

function AAPVE_MOOSE:GetScaledHostileGroupSize(pkg)
    local n = self:CountPackageMembersInSandbox(pkg)
    if n <= 1 then return 1 end
    if n <= 3 then return 2 end
    return 4
end

---------------------------------------------------------------------------
-- CAP check-in.
---------------------------------------------------------------------------

function AAPVE_MOOSE:RequestCapCheckIn(leadClient)
    if not leadClient or not leadClient:IsAlive() then
        self:BlueMessage("A/A PVE Range: unable to check in. Client is not active.", 10)
        return nil
    end

    if self:GetRangeMode() ~= "BlueCapDefense" then
        self:BlueMessage("A/A PVE Range: BLUE CAP Defense mode is not active.", 10)
        return nil
    end

    local leadUnitName = leadClient:GetName()
    if not leadUnitName then
        self:BlueMessage("A/A PVE Range: unable to determine flight lead unit.", 10)
        return nil
    end

    -- Already the lead of a package? Re-send tasking.
    local existingAsLead = self:GetPackageByLeadUnit(leadUnitName)
    if existingAsLead then
        self:SendPackageTasking(existingAsLead, true)
        return existingAsLead
    end

    -- Already a member of another package?
    local existingAsMember = self:GetPackageByMemberUnit(leadUnitName)
    if existingAsMember then
        self:BlueMessage(
            string.format("A/A PVE Range: you are already in CAP Package %d.", existingAsMember.Id), 10)
        self:SendPackageTasking(existingAsMember, true)
        return existingAsMember
    end

    if self:GetActivePackageCount() >= self.MaxCapPackages then
        self:BlueMessage("A/A PVE Range: no additional CAP packages available.", 10)
        return nil
    end

    local capZone = self:GetAvailableCapZone()
    if not capZone then
        self:BlueMessage("A/A PVE Range: all CAP zones are assigned.", 10)
        return nil
    end

    local memberUnits, memberNames = self:GetClientsNearLead(leadClient)
    if not memberUnits[leadUnitName] then
        memberUnits[leadUnitName] = true
        memberNames[#memberNames + 1] = self:GetClientDisplayName(leadClient)
    end

    local pkg = {
        Id                = self.NextCapPackageId,
        LeadClientName    = self:GetClientDisplayName(leadClient),
        LeadUnitName      = leadUnitName,
        AssignedZone      = capZone,
        MemberUnits       = memberUnits,
        MemberNames       = memberNames,
        MarkerId          = nil,
        EmptySince        = nil,
        ActiveHostileGroup = nil,
        CommitAnnounced   = false,
        OutOfAorWarned    = false,
        NASGSession       = nil,   -- bound NASG_ATC session for this lead client
        ScoreCard         = nil,   -- flat DB row; set by InitScoreCard at check-in
        PictureHeld       = false, -- true while client is off-station (e.g. at tanker)
        TankerState       = nil,   -- nil / "EnRoute" / "Returning"
        TankerStartTime   = 0,
        _lastAltWarnTime  = 0,     -- internal; throttle altitude violation scoring
        FSM               = nil,   -- set by CreatePackageFSM below
    }

    self.NextCapPackageId = self.NextCapPackageId + 1
    self.CapPackages[#self.CapPackages + 1] = pkg

    -- Attach FSM and initialize scorecard.
    self:CreatePackageFSM(pkg)
    self:InitScoreCard(pkg)

    self:SendPackageTasking(pkg, false)
    self:BlueMessage(
        string.format(
            "A/A PVE Range: CAP Package %d checked in by %s. Members: %s.",
            pkg.Id, pkg.LeadClientName,
            table.concat(memberNames, ", ")),
        20)

    self:Log("Package " .. pkg.Id .. " created for " .. pkg.LeadClientName)
    return pkg
end

---------------------------------------------------------------------------
-- Package monitor.
--
-- Runs on a timer in BlueCapDefense mode. For each active package it:
--   1. Detects arrival on station -> fires FSM:ArriveStation()
--   2. Detects commit toward hostile -> fires FSM:Commit()
--   3. Counts empty time -> fires FSM:Close() after timeout.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartMonitor()
    if self.MonitorScheduler then
        pcall(function() self.MonitorScheduler:Stop() end)
    end
    self.MonitorScheduler = SCHEDULER:New(nil, function()
        AAPVE_MOOSE:TickMonitor()
    end, {}, 5, self.MonitorIntervalSeconds)
end

function AAPVE_MOOSE:TickMonitor()
    if self:GetRangeMode() ~= "BlueCapDefense" then return end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed") then
            self:MonitorPackage(pkg)
        end
    end
end

function AAPVE_MOOSE:MonitorPackage(pkg)
    local onStation = self:CountPackageMembersOnStation(pkg)
    local inSandbox = self:CountPackageMembersInSandbox(pkg)

    -- ---- Arrival on station ----
    if onStation > 0 then
        local state = pkg.FSM:GetCurrentState()
        if state == "Assigned" or state == "Retasking" then
            pkg.FSM:ArriveStation()
        end
        pkg.EmptySince = nil
        self:MarkCapPackage(pkg)

        -- If client has returned from tanker, resume picture loop.
        if pkg.TankerState then
            pkg.TankerState  = nil
            pkg.PictureHeld  = false
            local capName = pkg.AssignedZone and pkg.AssignedZone.Name or "CAP"
            self:SendTTS(string.format(
                "Magic, CAP package %d, back on station. Welcome back. Stand by picture.", pkg.Id))
            self:BlueMessage(string.format(
                "A/A PVE Range: Package %d back on station. Picture resuming.", pkg.Id), 10)
        end

        -- Altitude discipline check: score a violation if significantly off briefed altitude.
        if self.ScoringEnabled and state == "OnStation" then
            local now = timer.getTime()
            if now - (pkg._lastAltWarnTime or 0) > 60 then  -- max one score event per minute
                self.BlueClientSet:ForEachClient(function(c)
                    if not c or not c:IsAlive() then return end
                    local uname = c:GetName()
                    if not uname or not pkg.MemberUnits[uname] then return end
                    local coord = c:GetCoordinate()
                    if not coord then return end
                    -- GetAltitude may be nil if GetCoordinate returned a raw Vec3.
                    local altFt
                    if type(coord.GetAltitude) == "function" then
                        altFt = coord:GetAltitude() / 0.3048
                    elseif type(coord.y) == "number" then
                        altFt = coord.y / 0.3048   -- DCS Vec3: y = altitude (m)
                    end
                    if not altFt then return end
                    local minAlt  = pkg.AssignedZone and pkg.AssignedZone.AltMinFt or (self.BriefedCapAltitudeFt - self.BriefedCapAltTolFt)
                    local maxAlt  = pkg.AssignedZone and pkg.AssignedZone.AltMaxFt or (self.BriefedCapAltitudeFt + self.BriefedCapAltTolFt)
                    if altFt < minAlt or altFt > maxAlt then
                        pkg._lastAltWarnTime = now
                        self:RecordScoreEvent(pkg, "cap_alt_violation")
                    end
                end)
            end
        end

        -- Commit detection (only when OnStation with an active hostile).
        if state == "OnStation" and not pkg.CommitAnnounced
                and pkg.ActiveHostileGroup and pkg.ActiveHostileGroup:IsAlive() then
            self:CheckCommit(pkg)
        end
        return
    end

    -- ---- In sandbox but not on station ----
    if inSandbox > 0 then
        pkg.EmptySince = nil
        return
    end

    -- ---- No members present ----
    -- Do not close the package if the client is off-station at a tanker.
    if pkg.TankerState then return end

    local activeStates = { Assigned=true, OnStation=true, Committed=true, Retasking=true }
    if activeStates[pkg.FSM:GetCurrentState()] then
        if not pkg.EmptySince then
            pkg.EmptySince = timer.getTime()
            self:BlueMessage(
                string.format(
                    "A/A PVE Range: Package %d has no clients in sandbox. Closes in %d minutes if empty.",
                    pkg.Id, math.floor(self.PackageEmptyCloseSeconds / 60)),
                15)
        else
            local elapsed = timer.getTime() - pkg.EmptySince
            if elapsed >= self.PackageEmptyCloseSeconds then
                pkg.FSM:Close("Sandbox empty.")
            end
        end
    end
end

function AAPVE_MOOSE:CheckCommit(pkg)
    local capCoord    = pkg.AssignedZone.Zone:GetCoordinate()
    local clientCoord = self:GetRepresentativeMemberCoord(pkg)
    local hostCoord   = pkg.ActiveHostileGroup:GetCoordinate()
    if not capCoord or not clientCoord or not hostCoord then return end

    -- Client must have moved away from CAP before we check commit geometry.
    local distNm = UTILS.MetersToNM(clientCoord:Get2DDistance(capCoord))
    if distNm < self.CommitDistanceFromCapNm then return end

    -- Heading geometry: is the client moving toward the hostile?
    local bearCapToClient  = self:GetBearingDegrees(capCoord, clientCoord)
    local bearCapToHostile = self:GetBearingDegrees(capCoord, hostCoord)
    local diff = self:GetHeadingDiff(bearCapToClient, bearCapToHostile)

    if diff > self.CommitHeadingToleranceDeg then return end

    -- AOR gate: is the hostile actually inside this package's AOR zone?
    -- If the contact is OUTSIDE the AOR, the client is leaving their sector —
    -- issue a training warning instead of declaring a commit.
    if not self:IsInPackageAor(pkg, hostCoord) then
        -- Only warn once per bogie (use CommitAnnounced as the guard so we
        -- don't spam the warning every monitor tick).
        if not pkg.OutOfAorWarned then
            pkg.OutOfAorWarned = true
            self:WarnOutOfAorCommit(pkg)
        end
        return
    end

    -- Contact is in-AOR: legitimate commit.
    pkg.CommitAnnounced  = true
    pkg.OutOfAorWarned   = false  -- reset for the next bogie

    -- Record commit range for scoring.
    local hostDistNm = UTILS.MetersToNM(clientCoord:Get2DDistance(hostCoord))
    self:RecordScoreEvent(pkg, "commit", { range_nm = hostDistNm })

    pkg.FSM:Commit()
end

---------------------------------------------------------------------------
-- Picture generation scheduler.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartPictureScheduler()
    if self.PictureScheduler then
        pcall(function() self.PictureScheduler:Stop() end)
    end
    self.PictureScheduler = SCHEDULER:New(nil, function()
        AAPVE_MOOSE:GeneratePictures()
    end, {}, 30, self.PictureIntervalSeconds)
end

function AAPVE_MOOSE:GeneratePictures()
    if self:GetRangeMode() ~= "BlueCapDefense" then return end
    for _, pkg in pairs(self.CapPackages) do
        if pkg and pkg.FSM:Is("OnStation") then
            self:GeneratePictureForPackage(pkg)
        end
    end
end

---------------------------------------------------------------------------
-- Periodic picture broadcast (data source).
--
-- The AWACS controller (NASG_ATC_AWACS) owns the broadcast cadence, the
-- "picture clean" throttle, and the spoken formatting. This function only
-- supplies the live on-station hostile groups. It returns:
--   nil            when no package is on station (AWACS transmits nothing),
--   an empty table when packages are on station but the picture is clean,
--   a list of { Bulls=, AltFt=, Size= } for the live hostile groups.
---------------------------------------------------------------------------

function AAPVE_MOOSE:CollectBroadcastGroups()
    if self:GetRangeMode() ~= "BlueCapDefense" then return nil end

    -- The picture is painted regardless of whether any CAP is on station:
    -- report every live hostile group. An empty list means "picture clean",
    -- which the AWACS controller still broadcasts at its clean cadence.
    local groups = {}
    for _, pkg in pairs(self.CapPackages) do
        if pkg and pkg.ActiveHostileGroup and pkg.ActiveHostileGroup:IsAlive() then
            local coord
            pcall(function() coord = pkg.ActiveHostileGroup:GetCoordinate() end)
            if coord then
                local altFt = 0
                pcall(function()
                    if type(coord.GetAltitude) == "function" then
                        altFt = math.floor(coord:GetAltitude() / 0.3048)
                    elseif type(coord.y) == "number" then
                        altFt = math.floor(coord.y / 0.3048)
                    end
                end)
                groups[#groups + 1] = {
                    Bulls = self:GetBullseyeText(coord),
                    AltFt = altFt,
                    Size  = pkg.ActiveHostileGroup:GetSize() or 1,
                }
            end
        end
    end

    return groups
end

---------------------------------------------------------------------------
-- Difficulty and cadence presets (voice- and menu-settable).
---------------------------------------------------------------------------

-- Spoken form of the current range mode (used by the voice status call).
function AAPVE_MOOSE:GetRangeModeWord()
    local mode = self:GetRangeMode()
    if mode == "BlueCapDefense"    then return "blue cap defense"        end
    if mode == "RedCapPractice"    then return "red cap target practice" end
    if mode == "InterceptPractice" then return "intercept practice"      end
    if mode == "Idle"              then return "idle"                    end
    return "offline"
end

-- Difficulty presets tune aggressor behavior and the hostile picture mix.
function AAPVE_MOOSE:SetDifficulty(level)
    level = tostring(level or ""):lower()
    if level == "easy" then
        self.AggressorEngageChance = 40
        self.PictureHostileChance  = 30
        self.BogeyReactionRangeNm  = 30
    elseif level == "hard" then
        self.AggressorEngageChance = 80
        self.PictureHostileChance  = 55
        self.BogeyReactionRangeNm  = 50
    else  -- medium / default
        level = "medium"
        self.AggressorEngageChance = 60
        self.PictureHostileChance  = 40
        self.BogeyReactionRangeNm  = 40
    end
    self.Difficulty = level
    self:BlueMessage(string.format("A/A PVE Range: difficulty set to %s.", level), 10)
    self:Log("Difficulty set: " .. level)
    return level
end

-- Cadence presets tune how often new pictures are generated and how often
-- the AWACS re-broadcasts live contacts.
function AAPVE_MOOSE:SetPictureCadence(speed)
    speed = tostring(speed or ""):lower()
    if speed == "fast" then
        self.PictureIntervalSeconds = 60
        self.BroadcastIntervalSecs  = 60
    elseif speed == "slow" then
        self.PictureIntervalSeconds = 240
        self.BroadcastIntervalSecs  = 150
    else  -- normal / default
        speed = "normal"
        self.PictureIntervalSeconds = 120
        self.BroadcastIntervalSecs  = 90
    end
    self.PictureCadence = speed

    -- Push the new broadcast interval to the AWACS controller.
    if NASG_ATC_AWACS and NASG_ATC_AWACS.ConfigurePictureBroadcast then
        NASG_ATC_AWACS:ConfigurePictureBroadcast({ IntervalSecs = self.BroadcastIntervalSecs })
    end
    -- Restart picture generation so the new interval takes effect immediately.
    if self.PictureScheduler then
        self:StartPictureScheduler()
    end

    self:BlueMessage(string.format("A/A PVE Range: picture cadence set to %s.", speed), 10)
    self:Log("Picture cadence set: " .. speed)
    return speed
end

function AAPVE_MOOSE:GeneratePictureForPackage(pkg)
    -- Skip while picture is held (e.g. client is off-station at tanker).
    if pkg.PictureHeld then return end
    -- Skip if a hostile bogey is already active on this package.
    if pkg.ActiveHostileGroup and pkg.ActiveHostileGroup:IsAlive() then return end

    -- Skip if global hostile cap is hit.
    if self.UseGlobalHostileLimit
            and self:GetGlobalActiveHostileCount() >= self.MaxGlobalHostileGroups then
        return
    end

    -- Skip if no package members are inside the sandbox.
    if self:CountPackageMembersInSandbox(pkg) <= 0 then return end

    -- Four-way roll:
    --   1) Hostile bogey  (weapons hold → may engage or evade on react)
    --   2) Ghost call     (AWACS text+TTS only, contact OUTSIDE this AOR)
    --   3) VID contact    (spawned, in-AOR, civil profile requiring assessment)
    --   4) Friendly/neutral transit (existing non-hostile pass-through)
    local roll        = math.random(1, 100)
    local hostileLim  = self.PictureHostileChance
    local ghostLim    = hostileLim + self.PictureGhostCallChance
    local vidLim      = ghostLim  + self.PictureVIDChance

    if roll <= hostileLim then
        self:SpawnHostileForPackage(pkg)

    elseif roll <= ghostLim then
        -- Ghost call: out-of-AOR contact, text+TTS only, no spawn.
        self:GenerateGhostBullseyeCall(pkg)

    elseif roll <= vidLim then
        -- VID opportunity: spawned non-combative aircraft in-AOR.
        local opt = self:GetRandomOption(self.VIDTemplates)
            or self:GetRandomOption(self.PictureNeutralTemplates)
        if opt then self:SpawnVIDOpportunity(pkg, opt) end

    else
        -- Friendly/neutral transit (background non-combative traffic).
        local isFriendly = (math.random(1, 2) == 1)
        local opt = isFriendly
            and self:GetRandomOption(self.PictureFriendlyTemplates)
            or  self:GetRandomOption(self.PictureNeutralTemplates)
        if opt then
            self:SpawnNonHostile(pkg, opt, isFriendly and "FRIENDLY" or "NEUTRAL")
        end
    end
end

---------------------------------------------------------------------------
-- Ghost Bullseye Call.
--
-- Generates a realistic AWACS picture call for a fictitious contact that
-- is provably OUTSIDE the package's AOR zone. No aircraft is spawned.
--
-- Contact placement priority:
--   1. Centre of another active package's AOR zone (realistic cross-sector).
--   2. Centre of an unassigned CAP AOR zone (plausible sector).
--   3. Computed coordinate that fails IsCoordinateInZone for this package's
--      AOR (angular-offset fallback when only one package is active).
--
-- Training objective: crew must hold CAP and NOT commit.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GenerateGhostBullseyeCall(pkg)
    if not pkg.AssignedZone or not pkg.AssignedZone.Zone then return end

    -- Get a coordinate that is definitively outside this package's AOR zone.
    local altFt      = math.random(self.PictureMinAltitudeFt, self.PictureMaxAltitudeFt)
    local ghostDistNm = math.random(self.GhostCallMinDistNm, self.GhostCallMaxDistNm)
    local ghostCoord  = self:GetOutOfAorCoordinate(pkg, ghostDistNm)
    if not ghostCoord then
        self:Log("Ghost call skipped: could not find out-of-AOR coordinate.")
        return
    end

    -- Safety: confirm the coord really is outside this package's AOR.
    -- If somehow it ended up inside (e.g., AOR zones overlap), skip.
    local aorZone = self:GetPackageAorZone(pkg)
    if aorZone and aorZone:IsCoordinateInZone(ghostCoord) then
        self:Log("Ghost call skipped: computed coord still inside AOR — AOR zones may overlap.")
        return
    end

    ghostCoord.y = UTILS.FeetToMeters(altFt)

    -- Build a real bullseye string so the call sounds authentic.
    local bullsText = self:GetBullseyeText(ghostCoord)

    -- Bearing from the BLUE bullseye to the ghost coord (used for aspect word).
    local ghostBearing = 0
    pcall(function()
        local bullyVec3 = coalition.getMainRefPoint(coalition.side.BLUE)
        if bullyVec3 then
            local bullyCoord = COORDINATE:NewFromVec3(bullyVec3)
            ghostBearing = self:GetBearingDegrees(bullyCoord, ghostCoord) or 0
        end
    end)

    -- Random contact profile.
    local trackDeg  = math.random(0, 359)
    local trackWord = self:BearingToCardinal(trackDeg)
    local speedKts  = math.random(self.PictureMinSpeedKts, self.PictureMaxSpeedKts)
    local speedWord = self:SpeedToWord(speedKts)
    local angelsStr = self:AltitudeToAngels(altFt)

    -- Aspect relative to the ghost contact's bearing from reference.
    local aspectWord = self:AspectWord(trackDeg, ghostBearing)

    -- Group size (the "picture" may have multiple contacts).
    local groupSize = math.random(1, 4)
    local groupWord = (groupSize == 1) and "single" or
                      (groupSize == 2) and "pair"   or
                      (groupSize == 3) and "3-ship"  or "4-ship"

    -- ---- Text message (F10 / chat) ----
    local msg = string.format(
        "A/A PVE Range: [PICTURE] Package %d\n"..
        "Contact is OUTSIDE YOUR SECTOR — hold CAP.\n\n"..
        "Group: %s\n"..
        "Position: %s\n"..
        "Track: %s\n"..
        "Altitude: %s (%d ft)\n"..
        "Speed: %s (~%d kts)\n"..
        "Aspect: %s\n\n"..
        "This contact is not in your AOR. Maintain your CAP.",
        pkg.Id,
        groupWord,
        bullsText,
        trackWord,
        angelsStr, altFt,
        speedWord, speedKts,
        aspectWord)

    -- ---- TTS radio call (AWACS brevity format) ----
    local tts = string.format(
        "Magic, CAP package %d. Picture. %s group. %s. Track %s. %s. %s. %s. "..
        "Contact is outside your sector. Hold CAP.",
        pkg.Id,
        groupWord,
        bullsText,
        trackWord,
        angelsStr,
        speedWord,
        aspectWord)

    self:BlueMessage(msg, 30)
    self:SendTTS(tts)
    self:Log(string.format("Package %d ghost call: bull %03.0f/%d, track %s, %s, %s.",
        pkg.Id, ghostBearing, ghostDistNm, trackWord, angelsStr, aspectWord))

    -- Ghost calls have no physical contact; clear session group data so that
    -- voice queries (Bogey Dope, BRAA, Declare) return "picture clean" rather
    -- than serving stale data from the previous hostile spawn.
    self:UpdateSessionGroupData(pkg, nil)
end

---------------------------------------------------------------------------
-- VID Opportunity.
--
-- Spawns a non-combative / civil-profile aircraft within or near the
-- package's AOR with an ambiguous flight profile. The client must assess
-- track, speed, and altitude to decide whether to commit and conduct a
-- Visual IDentification (VID) or hold CAP.
--
-- Track types:
--   CROSSING — lateral track perpendicular to threat axis (least threatening).
--   INBOUND  — hot track toward the protected zone (most suspicious).
--   COLD     — egressing away from the protected zone.
--
-- All VID contacts: weapons hold, passive defense, despawn after lifetime.
-- If the client commits and closes to VID range, the bogie monitor will NOT
-- trigger on these (BogieReacted is never set — they are not hostile spawns).
---------------------------------------------------------------------------

function AAPVE_MOOSE:SpawnVIDOpportunity(pkg, opt)
    local spawnZone = self:GetRandomRedSpawnZone()
    if not spawnZone then
        self:BlueMessage("A/A PVE Range: VID spawn failed (no spawn zone).", 10)
        return
    end

    local track   = self:GetRandomOption(self.VIDTracks) or "CROSSING"
    local speedKts = math.random(self.VIDMinSpeedKts, self.VIDMaxSpeedKts)
    local altFt    = math.random(self.VIDMinAltFt, self.VIDMaxAltFt)
    local spdMs    = UTILS.KnotsToMps(speedKts)
    local altM     = UTILS.FeetToMeters(altFt)

    local alias = string.format("AAPVE_PKG%d_VID_%s_%s",
        pkg.Id, track, self:GetSanitizedName(opt.Name))

    local spawn = SPAWN:NewWithAlias(opt.Template, alias)
        :InitRandomizeZones({ spawnZone })
        :InitGrouping(1)
        :InitSkill("Average")

    local group = spawn:Spawn()
    if not group then
        self:BlueMessage(
            string.format("A/A PVE Range: VID spawn failed for Package %d.", pkg.Id), 10)
        return
    end

    self:AddActiveGroup(group)

    -- Delayed setup so the group is fully alive.
    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end

        -- Alarm state green: this is civil/non-combative traffic.
        -- The AI will not use its radar or react to a fighter closing.
        group:OptionAlarmStateGreen()
        group:OptionROEHoldFire()
        group:OptionROTPassiveDefense()

        -- Route according to track type.
        local dest
        local capCoord = pkg.AssignedZone and pkg.AssignedZone.Zone:GetCoordinate()

        if track == "INBOUND" then
            -- Route toward the protected zone (hot, suspicious).
            dest = self.ProtectedZone and self.ProtectedZone:GetCoordinate()
                or capCoord

        elseif track == "COLD" then
            -- Route away from the protected zone (cold, egressing).
            -- Translate in the opposite direction from the protected zone.
            local groupCoord = group:GetCoordinate()
            if groupCoord and capCoord then
                local bearAway = ((self:GetBearingDegrees(groupCoord, capCoord) or 0) + 180) % 360
                dest = groupCoord:Translate(UTILS.NMToMeters(200), bearAway)
            end

        else
            -- CROSSING: route through the package's AOR zone centre so the
            -- contact is unambiguously inside the assigned sector.  Fall back
            -- to the CAP hold zone centre if no AOR zone is defined.
            local aorZone = pkg.AssignedZone and pkg.AssignedZone.AorZone
            dest = aorZone and aorZone:GetCoordinate()
                or capCoord
        end

        if dest then
            local task = group:TaskRouteToVec2(dest:GetVec2(), spdMs, altM, "BARO")
            if task then group:SetTask(task) end
        end
    end, {}, 2)

    -- Populate session.ActiveGroup with VID contact data so that voice queries
    -- (Declare, Bogey Dope, BRAA) return appropriate "unknown/neutral" data
    -- rather than nil.  A separate SCHEDULER gives the group time to route
    -- before we read its coordinate.
    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end
        local vidCoord = group:GetCoordinate()
        if not vidCoord then return end
        local vidAltFt = math.floor(vidCoord:GetAltitude() / 0.3048)
        AAPVE_MOOSE:UpdateSessionGroupData(pkg, {
            Bulls    = AAPVE_MOOSE:GetBullseyeText(vidCoord),
            Braa     = nil,
            AltFt    = vidAltFt,
            Aspect   = aspectForCall,
            Id       = "unknown",
            Heavy    = false,
            Contacts = 1,
            Fast     = false,
        })
    end, {}, 4)

    -- When the VID contact despawns, clear the session data.
    local lifetime = math.random(self.VIDLifetimeMinSecs, self.VIDLifetimeMaxSecs)
    SCHEDULER:New(nil, function()
        if group and group:IsAlive() then group:Destroy() end
        AAPVE_MOOSE:UpdateSessionGroupData(pkg, nil)
    end, {}, lifetime)

    -- Build the announcement with realistic AWACS contact characteristics.
    local spawnCoord  = spawnZone:GetCoordinate()
    local bullsText   = spawnCoord and self:GetBullseyeText(spawnCoord) or "position unknown"
    local angelsStr   = self:AltitudeToAngels(altFt)
    local speedWord   = self:SpeedToWord(speedKts)

    -- Derive aspect from track type for the radio call.
    local aspectForCall = (track == "INBOUND")  and "hot"
                       or (track == "COLD")     and "drag"
                       or "beaming"

    -- ---- Text message ----
    local msg = string.format(
        "A/A PVE Range: [VID CONTACT] Package %d\n"..
        "Non-combative contact in your AOR.\n\n"..
        "Type: %s\n"..
        "Position: %s\n"..
        "Track: %s\n"..
        "Altitude: %s (%d ft)\n"..
        "Speed: %s (~%d kts)\n"..
        "Aspect: %s\n\n"..
        "Assess and decide: commit to VID or hold CAP.",
        pkg.Id,
        opt.Name,
        bullsText,
        track,
        angelsStr, altFt,
        speedWord, speedKts,
        aspectForCall)

    -- ---- TTS radio call ----
    local tts = string.format(
        "Magic, CAP package %d. Picture. Single group. %s. Track %s. %s. %s. %s. "..
        "Assess and identify if required.",
        pkg.Id,
        bullsText,
        string.lower(track),
        angelsStr,
        speedWord,
        aspectForCall)

    self:BlueMessage(msg, 30)
    self:SendTTS(tts)
    self:Log(string.format("Package %d VID spawned: %s, track %s, %s, %s.",
        pkg.Id, opt.Name, track, angelsStr, speedWord))
end

function AAPVE_MOOSE:SpawnHostileForPackage(pkg)
    local opt  = self:GetRandomOption(self.PictureHostileTemplates)
    local zone = self:GetRandomRedSpawnZone()
    if not opt or not zone then
        self:BlueMessage("A/A PVE Range: hostile spawn failed (no template or zone).", 10)
        return
    end

    local size  = self:GetScaledHostileGroupSize(pkg)
    local alias = string.format("AAPVE_PKG%d_HOSTILE_%s", pkg.Id, self:GetSanitizedName(opt.Name))

    -- Pre-compute altitude so both spawn and route use the same value.
    local spawnAltFt = math.random(self.PictureMinAltitudeFt, self.PictureMaxAltitudeFt)
    local spawnAltM  = UTILS.FeetToMeters(spawnAltFt)

    -- Get a random position inside the zone and set the desired altitude directly.
    -- InitAltitude() is not available in this MOOSE build; setting coord.y is the
    -- reliable cross-version method (DCS coordinate system: y = altitude MSL in metres).
    local spawnCoord = zone:GetRandomCoordinate() or zone:GetCoordinate()
    if spawnCoord then
        spawnCoord.y = spawnAltM
    end

    local spawn = SPAWN:NewWithAlias(opt.Template, alias)
        :InitGrouping(size)
        :InitSkill("Random")

    local group = spawnCoord and spawn:SpawnFromCoordinate(spawnCoord) or spawn:Spawn()
    if not group then
        self:BlueMessage(string.format("A/A PVE Range: hostile spawn failed for Package %d.", pkg.Id), 10)
        return
    end

    self:AddActiveGroup(group)

    -- Bogies enter as unidentified traffic: weapons hold, passive defense.
    -- Alarm state Auto so the AI radar is active (it can detect threats)
    -- but it will not shoot until the bogie monitor makes a decision.
    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end

        -- Alarm state: Auto lets the AI use its radar and react to locks
        -- without firing immediately.
        if self.BogieInitialAlarmState == "Red" then
            group:OptionAlarmStateRed()
        elseif self.BogieInitialAlarmState == "Green" then
            group:OptionAlarmStateGreen()
        else
            group:OptionAlarmStateAuto()
        end

        -- Hold fire: this bogie has not yet been identified as hostile.
        group:OptionROEHoldFire()

        -- Passive defense: the AI will maneuver to avoid threats but won't
        -- engage. This simulates an aircraft that knows it may be tracked.
        group:OptionROTPassiveDefense()

        -- Route into the package's AOR zone (preferred) or fall back to
        -- the CAP zone centre. Routing into the AOR ensures the bogie is
        -- clearly the responsibility of this package, not another sector.
        local aorZone = pkg.AssignedZone and pkg.AssignedZone.AorZone
        local dest    = aorZone and aorZone:GetCoordinate()
                     or pkg.AssignedZone.Zone:GetCoordinate()

        if dest then
            local spdMs = UTILS.KnotsToMps(math.random(self.PictureMinSpeedKts, self.PictureMaxSpeedKts))
            local task  = group:TaskRouteToVec2(dest:GetVec2(), spdMs, spawnAltM, "BARO")
            if task then group:SetTask(task) end
        end

        -- Populate NASG_ATC session.ActiveGroup so voice queries
        -- (declare, commit, no joy, clean, threat) have group data.
        local spawnCoord = group:GetCoordinate()
        if spawnCoord then
            local altFt = math.floor(spawnCoord:GetAltitude() / 0.3048)
            AAPVE_MOOSE:UpdateSessionGroupData(pkg, {
                Bulls    = AAPVE_MOOSE:GetBullseyeText(spawnCoord),
                Braa     = nil,      -- computed live in voice handlers
                AltFt    = altFt,
                Aspect   = nil,      -- computed live in voice handlers
                Id       = "bogey",
                Heavy    = (size >= 3),
                Contacts = size,
                Fast     = false,
            })
        end
    end, {}, 2)

    pkg.ActiveHostileGroup = group
    pkg.BogieReacted       = false   -- reaction not yet triggered
    pkg.CommitAnnounced    = false
    pkg.TacCallMade        = false   -- TAC (45 NM) auto-call guard
    pkg.MeldCallMade       = false   -- MELD (35 NM) auto-call guard

    -- Start the bogie reaction monitor for this package.
    self:StartBogieMonitor(pkg, group)

    self:BlueMessage(
        string.format(
            "A/A PVE Range: new picture for Package %d. %s x%d — BOGEY, IFF unknown.",
            pkg.Id, opt.Name, size),
        12)
    -- Actual picture call (BULLSEYE + track) is sent by GeneratePictureForPackage.
    -- Only log this internal spawn notification in debug mode.
    if self.Debug then
        self:SendTTS(
            string.format(
                "Magic, CAP package %d, picture update. Bogey group inbound, IFF unknown. Intercept and identify.",
                pkg.Id))
    end
end

---------------------------------------------------------------------------
-- Bogie reaction monitor.
--
-- Polls every BogieMonitorIntervalSecs. Fires when a package member is:
--   (a) within BogieReactionRangeNm AND heading within BogieReactionHeadingDeg
--       of the bogie (simulates radar commit / nose-hot), OR
--   (b) within BogieInnerReactRangeNm regardless of heading (unavoidable).
--
-- On trigger, rolls AggressorEngageChance:
--   >= chance -> EVADE (run, despawn, retask package)
--   <  chance -> ENGAGE (weapons free, attack)
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartBogieMonitor(pkg, group)
    local sched
    sched = SCHEDULER:New(nil, function()
        -- Stop if the package closed or the bogie already reacted.
        if not pkg or pkg.FSM:Is("Closed") or pkg.BogieReacted then
            if sched then sched:Stop() end
            return
        end

        -- Stop if the bogie is gone.
        if not group or not group:IsAlive() then
            if sched then sched:Stop() end
            return
        end

        local bogieCoord = group:GetCoordinate()
        if not bogieCoord then return end

        -- ── TAC / MELD auto-calls (mirrors Ops.AWACS 45 NM / 35 NM thresholds) ──
        -- Find the closest package member to the bogie and fire one-time TTS
        -- calls when crossing the TAC and MELD range thresholds.
        if not pkg.TacCallMade or not pkg.MeldCallMade then
            local closestDist   = math.huge
            local closestClient = nil
            self.BlueClientSet:ForEachClient(function(c)
                if not c or not c:IsAlive() then return end
                if not pkg.MemberUnits or not pkg.MemberUnits[c:GetName()] then return end
                local coord = c:GetCoordinate()
                if coord then
                    local d = coord:Get2DDistance(bogieCoord)
                    if d < closestDist then
                        closestDist   = d
                        closestClient = coord
                    end
                end
            end)

            if closestClient then
                local closestNm = UTILS.MetersToNM(closestDist)
                local altFt     = math.floor(bogieCoord:GetAltitude() / 0.3048)

                -- TAC call: BULLSEYE PICTURE at 45 NM (first threshold).
                if not pkg.TacCallMade and closestNm <= self.TACDistanceNm then
                    pkg.TacCallMade = true
                    self:SendTTS(string.format(
                        "Magic, CAP package %d. Single group. %s. %s.",
                        pkg.Id,
                        self:GetBullseyeText(bogieCoord),
                        self:AltitudeToAngels(altFt)))
                    self:RecordScoreEvent(pkg, "threat_call")
                end

                -- MELD call: BRAA at 35 NM (fires after TAC).
                if pkg.TacCallMade and not pkg.MeldCallMade and closestNm <= self.MELDDistanceNm then
                    pkg.MeldCallMade = true
                    local bearing = self:GetBearingDegrees(closestClient, bogieCoord) or 0
                    local rangeNm = math.floor(closestNm)
                    local grpHdg  = group:GetHeading() or 0
                    local recip   = (bearing + 180) % 360
                    local diff    = math.abs(((grpHdg - recip) + 540) % 360 - 180)
                    local aspect  = (diff < 30) and "hot"
                                 or (diff < 60) and "flanking"
                                 or (diff < 120) and "beaming"
                                 or "drag"
                    self:SendTTS(string.format(
                        "Magic, CAP package %d. Group braa %03d/%d. %s. %s. Bogey.",
                        pkg.Id,
                        math.floor(bearing), rangeNm,
                        self:AltitudeToAngels(altFt),
                        aspect))
                    self:RecordScoreEvent(pkg, "threat_call")
                end
            end
        end

        -- Check every member of this package.
        local triggered = false

        self.BlueClientSet:ForEachClient(function(c)
            if triggered then return end
            if not c or not c:IsAlive() then return end
            local uname = c:GetName()
            if not pkg.MemberUnits or not pkg.MemberUnits[uname] then return end

            local clientCoord = c:GetCoordinate()
            if not clientCoord then return end

            local distNm = UTILS.MetersToNM(clientCoord:Get2DDistance(bogieCoord))

            -- Inner hard range: react regardless of heading.
            if distNm <= self.BogieInnerReactRangeNm then
                triggered = true
                return
            end

            -- Outer range with heading check: client heading toward the bogie.
            if distNm <= self.BogieReactionRangeNm then
                local clientHdg    = self:GetClientHeading(c)
                local bearToBogie  = self:GetBearingDegrees(clientCoord, bogieCoord)
                if bearToBogie and self:GetHeadingDiff(clientHdg, bearToBogie) <= self.BogieReactionHeadingDeg then
                    triggered = true
                end
            end
        end)

        if not triggered then return end

        -- Bogie has detected a threat — react exactly once.
        pkg.BogieReacted = true
        if sched then sched:Stop() end

        -- Roll for engage vs. evade.
        if math.random(1, 100) <= self.AggressorEngageChance then
            self:AggressorEngage(pkg, group)
        else
            self:AggressorEvade(pkg, group)
        end

    end, {}, self.BogieMonitorIntervalSecs, self.BogieMonitorIntervalSecs)
end

---------------------------------------------------------------------------
-- Aggressor ENGAGE.
-- The bogie decides it is hostile and attacks.
---------------------------------------------------------------------------

function AAPVE_MOOSE:AggressorEngage(pkg, group)
    if not group or not group:IsAlive() then return end

    self:Log(string.format("Package %d bogie going HOSTILE - ENGAGE.", pkg.Id))

    -- Transition to full combat ROE.
    -- OptionROEOpenFireWeaponFree: the AI will engage any enemy it detects,
    -- including off-axis threats it acquires with its own radar.
    group:OptionAlarmStateRed()
    group:OptionROEOpenFireWeaponFree()

    -- EvadeFire: the AI will simultaneously maneuver defensively (notch,
    -- break, chaff) while pressing its attack — realistic aggressor behavior.
    group:OptionROTEvadeFire()

    -- Task the group to actively hunt the package lead's group.
    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end

        -- Find the best alive target group from package members.
        local targetGroup
        self.BlueClientSet:ForEachClient(function(c)
            if targetGroup then return end
            if c and c:IsAlive() and pkg.MemberUnits and pkg.MemberUnits[c:GetName()] then
                targetGroup = c:GetGroup()
            end
        end)

        if targetGroup and targetGroup:IsAlive() then
            local attackTask = group:TaskAttackGroup(
                targetGroup,
                ai.task.WeaponExpend.ALL,   -- expend all weapons
                nil,                         -- weapon type (nil = any)
                nil,                         -- altitude (nil = auto)
                nil,                         -- attack qty (nil = auto)
                nil,                         -- direction
                nil,                         -- altitude type
                true                         -- group attack (all units attack)
            )
            if attackTask then group:SetTask(attackTask) end
        end
    end, {}, 1)

    self:BlueMessage(
        string.format(
            "A/A PVE Range: BANDIT! Package %d — bogie is HOSTILE. Engage, engage, engage!",
            pkg.Id),
        15)
    self:SendTTS(
        string.format(
            "Magic, BANDIT! CAP package %d, bogie is hostile. Weapons free. Engage!",
            pkg.Id))
end

---------------------------------------------------------------------------
-- Aggressor EVADE.
-- The bogie decides to run. Package is retasked; bogie despawns after
-- BogieEvadeLifetimeSecs if not shot down first.
---------------------------------------------------------------------------

function AAPVE_MOOSE:AggressorEvade(pkg, group)
    if not group or not group:IsAlive() then return end

    self:Log(string.format("Package %d bogie EVADING.", pkg.Id))

    -- Hold fire and use bypass-and-escape: the AI will actively try to
    -- disengage, notch, and run without firing back.
    group:OptionAlarmStateRed()
    group:OptionROEHoldFire()
    group:OptionROTBypassAndEscape()

    -- Route the bogie directly away from the CAP zone at max speed.
    local bogieCoord = group:GetCoordinate()
    local capCoord   = pkg.AssignedZone and pkg.AssignedZone.Zone:GetCoordinate()

    if bogieCoord and capCoord then
        -- Bearing from bogie back toward CAP, then reverse it to flee.
        local bearTowardCap = self:GetBearingDegrees(bogieCoord, capCoord)
        local bearAway      = (bearTowardCap + 180) % 360

        -- Translate 250 NM away from the CAP zone along escape bearing.
        local escapeCoord = bogieCoord:Translate(UTILS.NMToMeters(250), bearAway)
        local altM        = UTILS.FeetToMeters(math.random(self.PictureMinAltitudeFt, self.PictureMaxAltitudeFt))
        local spdMs       = UTILS.KnotsToMps(self.BogieEvadeSpeedKts)

        local task = group:TaskRouteToVec2(escapeCoord:GetVec2(), spdMs, altM, "BARO")
        if task then group:SetTask(task) end
    end

    -- Despawn after evade lifetime (if not shot down).
    SCHEDULER:New(nil, function()
        if group and group:IsAlive() then
            group:Destroy()
        end
        -- Only retask if the hostile ref still points to this group.
        if pkg.ActiveHostileGroup == group then
            pkg.FSM:Disengage("Bogie egressed.")
        end
    end, {}, self.BogieEvadeLifetimeSecs)

    self:BlueMessage(
        string.format(
            "A/A PVE Range: Package %d — bogie is HOSTILE but EGRESSING. Return to CAP.\nNew picture on next cycle.",
            pkg.Id),
        20)
    self:SendTTS(
        string.format(
            "Magic, CAP package %d, bandit is egressing. Return to %s. Picture will resume on station.",
            pkg.Id,
            pkg.AssignedZone and pkg.AssignedZone.Name or "assigned CAP"))
end

function AAPVE_MOOSE:SpawnNonHostile(pkg, opt, role)
    local zone = self:GetRandomRedSpawnZone()
    if not zone then
        self:BlueMessage("A/A PVE Range: non-hostile spawn failed (no spawn zone).", 10)
        return
    end

    local alias = string.format("AAPVE_PKG%d_%s_%s", pkg.Id, role, self:GetSanitizedName(opt.Name))
    local spawn = SPAWN:NewWithAlias(opt.Template, alias)
        :InitRandomizeZones({ zone })
        :InitGrouping(1)
        :InitSkill("Random")

    local group = spawn:Spawn()
    if not group then
        self:BlueMessage(
            string.format("A/A PVE Range: %s spawn failed for Package %d.", role, pkg.Id), 10)
        return
    end

    self:AddActiveGroup(group)

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end
        group:OptionAlarmStateRed()
        group:OptionROEHoldFire()
        group:OptionROTPassiveDefense()

        local recovZone = self:GetRandomRecoveryZone()
        local dest = recovZone and recovZone:GetCoordinate()
                  or (self.ProtectedZone and self.ProtectedZone:GetCoordinate())
        if dest then
            local altM  = UTILS.FeetToMeters(math.random(self.PictureMinAltitudeFt, self.PictureMaxAltitudeFt))
            local spdMs = UTILS.KnotsToMps(math.random(self.PictureMinSpeedKts, self.PictureMaxSpeedKts))
            local task = group:TaskRouteToVec2(dest:GetVec2(), spdMs, altM, "BARO")
            if task then group:SetTask(task) end
        end
    end, {}, 2)

    local lifetime = math.random(self.NonHostileMinLifetimeSeconds, self.NonHostileMaxLifetimeSeconds)
    SCHEDULER:New(nil, function()
        if group and group:IsAlive() then group:Destroy() end
    end, {}, lifetime)

    self:BlueMessage(
        string.format("A/A PVE Range: %s track for Package %d.", role, pkg.Id), 10)
end

---------------------------------------------------------------------------
-- Manual RED CAP spawn.
---------------------------------------------------------------------------

function AAPVE_MOOSE:SpawnManualRedCap(opt, count, skill)
    if not opt then return end
    local zone = self:GetRandomRedSpawnZone()
    if not zone then
        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed (no spawn zone).", 10)
        return
    end

    local alias = "AAPVE_REDCAP_" .. self:GetSanitizedName(opt.Name)
    local spawn = SPAWN:NewWithAlias(opt.Template, alias)
        :InitRandomizeZones({ zone })
        :InitGrouping(count or 2)
        :InitSkill(skill or "Random")

    local group = spawn:Spawn()
    if not group then
        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed.", 10)
        return
    end

    self:AddActiveGroup(group)

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end
        group:OptionAlarmStateRed()
        group:OptionROEOpenFire()

        local capCoord = self.RedCapZone:GetCoordinate()
        if capCoord then
            local altM  = UTILS.FeetToMeters(24000)
            local spdMs = UTILS.KnotsToMps(450)
            local task  = group:TaskOrbitCircleAtVec2(capCoord:GetVec2(), altM, spdMs)
            if task then group:SetTask(task) end
        end
    end, {}, 2)

    self:BlueMessage(
        string.format("A/A PVE Range: spawned RED CAP %s x%d.", opt.Name, count or 2), 10)
end

---------------------------------------------------------------------------
-- Timeline bandit spawns.
---------------------------------------------------------------------------

function AAPVE_MOOSE:SpawnTimelineBanditForClient(client, timelineName)
    if not client or not client:IsAlive() then
        self:BlueMessage("A/A PVE Range: timeline spawn failed (client not alive).", 10)
        return
    end

    local tl = self.TimelineSpawnOptions[timelineName]
    if not tl then
        self:BlueMessage("A/A PVE Range: invalid timeline selection.", 10)
        return
    end

    local clientCoord = client:GetCoordinate()
    if not clientCoord then
        self:BlueMessage("A/A PVE Range: timeline spawn failed (no client coordinate).", 10)
        return
    end

    local clientHdg   = self:GetClientHeading(client)
    local distM       = UTILS.NMToMeters(tl.DistanceNm)
    local spawnCoord  = clientCoord:Translate(distM, clientHdg)

    local opt = self:GetRandomOption(self.RedCapTemplates)
    local templateName = opt and opt.Template or self.TimelineDefaultTemplate
    local aircraftName = opt and opt.Name     or self.TimelineDefaultTemplate

    local alias = string.format("AAPVE_TIMELINE_%s_%s", timelineName, self:GetSanitizedName(aircraftName))
    local spawn = SPAWN:NewWithAlias(templateName, alias)
        :InitGrouping(self.TimelineDefaultGroupSize)
        :InitSkill("Random")

    pcall(function() spawn:InitHeading((clientHdg + 180) % 360) end)

    local group
    pcall(function() group = spawn:SpawnFromCoordinate(spawnCoord) end)

    if not group then
        self:BlueMessage(
            string.format("A/A PVE Range: %s timeline spawn failed. Check template %s.",
                tl.Label, templateName), 10)
        return
    end

    self:AddActiveGroup(group)
    group.AAPVETimelineMode        = timelineName
    group.AAPVEAssignedClientName  = client:GetName()

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end
        group:OptionAlarmStateRed()
        if tl.RoeAtSpawn == "HoldFire" then
            group:OptionROEHoldFire()
        else
            group:OptionROEOpenFire()
        end
        local fc = CLIENT:FindByName(client:GetName())
        if fc and fc:IsAlive() then
            local tgt = fc:GetGroup()
            if tgt then
                local attackTask = group:TaskAttackGroup(tgt)
                if attackTask then group:SetTask(attackTask) end
            end
        end
    end, {}, 2)

    if tl.OpenFireAfterMerge then
        self:StartBFMMergeMonitor(group, client:GetName(), tl.MergeDistanceNm or 1.0)
    end

    self:BlueMessage(
        string.format("A/A PVE Range: %s timeline - %s at %d NM, hot.",
            tl.Label, aircraftName, tl.DistanceNm), 10)
    self:SendTTS(
        string.format("Magic, %s timeline set. Bandit spawned %d miles hot.", tl.Label, tl.DistanceNm))
end

function AAPVE_MOOSE:StartBFMMergeMonitor(group, clientUnitName, mergeNm)
    if not group or not clientUnitName then return end
    local sched
    sched = SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            if sched then sched:Stop() end
            return
        end
        local c = CLIENT:FindByName(clientUnitName)
        if not c or not c:IsAlive() then
            if sched then sched:Stop() end
            return
        end
        local gCoord = group:GetCoordinate()
        local cCoord = c:GetCoordinate()
        if not gCoord or not cCoord then return end
        if UTILS.MetersToNM(gCoord:Get2DDistance(cCoord)) <= mergeNm then
            group:OptionROEOpenFire()
            self:BlueMessage("A/A PVE Range: BFM merge! RED weapons free.", 10)
            self:SendTTS("Fight's on. Red weapons free.")
            if sched then sched:Stop() end
        end
    end, {}, 2, 2)
end

---------------------------------------------------------------------------
-- Event handling.
-- Dead/Crash/PilotDead -> retask the owning package.
-- Kill of a Blue client by hostile -> remove hostile, retask.
---------------------------------------------------------------------------

AAPVE_MOOSE.EventHandler = EVENTHANDLER:New()
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Dead)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Crash)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.PilotDead)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Kill)

function AAPVE_MOOSE.EventHandler:OnEventDead(evt)    AAPVE_MOOSE:OnGroupDeath(evt) end
function AAPVE_MOOSE.EventHandler:OnEventCrash(evt)   AAPVE_MOOSE:OnGroupDeath(evt) end
function AAPVE_MOOSE.EventHandler:OnEventPilotDead(evt) AAPVE_MOOSE:OnGroupDeath(evt) end
function AAPVE_MOOSE.EventHandler:OnEventKill(evt)    AAPVE_MOOSE:OnKill(evt)      end

function AAPVE_MOOSE:OnGroupDeath(evt)
    if not evt or not evt.IniUnit then return end
    local deadGroup = evt.IniUnit:GetGroup()
    if not deadGroup then return end

    -- A Blue package member was killed or died → record the loss on their
    -- scorecard. Covers both being shot down and self-inflicted crashes.
    local unitName = evt.IniUnitName or evt.IniUnit:GetName()
    local bluePkg  = unitName and self:GetPackageByMemberUnit(unitName)
    if bluePkg then
        self:RecordScoreEvent(bluePkg, "pilot_dead", { unit_name = unitName })
        -- If the flight lead is down, the graded session is over. Close the
        -- package so its scorecard is finalized and debriefed immediately
        -- (via OnAfterClose → FinalizeScoreCard) instead of waiting for the
        -- package to time out empty. Delay lets alive-status settle and
        -- de-dupes the Dead/Crash/PilotDead burst for a single death.
        if unitName == bluePkg.LeadUnitName and not bluePkg.FSM:Is("Closed") then
            SCHEDULER:New(nil, function()
                if not bluePkg.FSM:Is("Closed") then
                    self:Log(string.format("Package %d lead down — closing session.", bluePkg.Id))
                    bluePkg.FSM:Close("Flight lead down. Session ended.")
                end
            end, {}, 2)
        end
    end

    local pkg = self:GetPackageByHostileGroup(deadGroup:GetName())
    if not pkg then return end

    -- Delay so the group's alive status settles before we retask.
    SCHEDULER:New(nil, function()
        if pkg.ActiveHostileGroup and not pkg.ActiveHostileGroup:IsAlive() then
            self:Log("Package " .. pkg.Id .. " hostile neutralized.")
            pkg.FSM:Disengage("Hostile group neutralized.")
        end
    end, {}, 2)
end

function AAPVE_MOOSE:OnKill(evt)
    if not evt then return end
    local killer = evt.IniUnit
    local victim = evt.TgtUnit
    if not killer or not victim then return end
    local killerGroup = killer:GetGroup()
    if not killerGroup then return end
    local pkg = self:GetPackageByHostileGroup(killerGroup:GetName())
    if not pkg then return end

    if victim:GetCoalition() == coalition.side.BLUE then
        self:BlueMessage(
            string.format(
                "A/A PVE Range: RED AI killed a Blue pilot in Package %d. Hostile despawning.",
                pkg.Id), 10)
        self:DestroyGroup(pkg.ActiveHostileGroup)
        pkg.FSM:Disengage("Blue aircraft down. Hostile removed.")
    end
end

---------------------------------------------------------------------------
-- Mode launchers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartRedCapPracticeMode()
    self:ClearRange(false)
    self:BlueMessage(
        "A/A PVE Range: RED CAP Target Practice mode active.\nUse Manual RED CAP Spawn or Timeline Spawn from the menu.",
        15)
    self:SendTTS("Magic, A/A PVE Range RED CAP target practice mode is active.")
end

function AAPVE_MOOSE:StartBlueCapDefenseMode()
    self:ClearRange(false)
    self:StartBlueChief()
    self:StartMonitor()
    self:StartPictureScheduler()
    -- The AWACS controller owns the periodic picture broadcast cadence.
    if NASG_ATC_AWACS and NASG_ATC_AWACS.StartPictureBroadcast then
        NASG_ATC_AWACS:StartPictureBroadcast()
    end
    self:BlueMessage(
        "A/A PVE Range: BLUE CAP Defense mode active.\nUse CAP Check-in Client Selector from the range menu.",
        20)
    self:SendTTS("Magic, A/A PVE Range BLUE CAP defense mode active. Flight leads may check in.")
end

---------------------------------------------------------------------------
-- Intercept Practice mode.
--
-- Ungraded, single-cycle repeating mode.  One bogie at a time flows toward
-- the protected zone with weapons hold and no AI reaction, giving the client
-- clean geometry to practice intercept flow.
-- States per session: Idle → BogieActive → Recovering → Idle (repeat)
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartInterceptPracticeMode()
    self:ClearRange(false)
    self.PracticeSessions = {}
    self:StartPracticeMonitor()
    self:BlueMessage(
        "A/A PVE Range: Intercept Practice mode active.\n"..
        "Check in via voice command or F10 menu.\n"..
        "Say 'ready' when on station to request your first intercept.",
        25)
    self:SendTTS("Magic, A/A PVE Range intercept practice mode active. Flight leads may check in.")
end

-- Registers a practice session for a client (voice check-in or menu).
function AAPVE_MOOSE:StartPracticeSession(leadClient)
    if not leadClient or not leadClient:IsAlive() then return nil end
    if self:GetRangeMode() ~= "InterceptPractice" then
        self:BlueMessage("A/A PVE Range: Intercept Practice mode is not active.", 10)
        return nil
    end

    local uName = leadClient:GetName()
    if not uName then return nil end

    local existing = self.PracticeSessions[uName]
    if existing then
        local stateWord = existing.State == "Idle" and "on station — ready for next run."
                       or existing.State == "BogieActive" and "bogey active."
                       or "bogey turned cold, return to CAP."
        self:BlueMessage(string.format("A/A PVE Range: Practice session active for %s. %s",
            self:GetClientDisplayName(leadClient), stateWord), 10)
        return existing
    end

    local capZone = self:GetAvailableCapZone() or self.BlueCapZones[1]
    local coord   = capZone and capZone.Zone:GetCoordinate()
    local bulls   = coord and self:GetBullseyeText(coord) or "unknown"

    local session = {
        State      = "Idle",
        UnitName   = uName,
        ClientName = self:GetClientDisplayName(leadClient),
        CapZone    = capZone,
        TargetGroup= nil,
        SpawnCount = 0,
    }
    self.PracticeSessions[uName] = session

    self:BlueMessage(string.format(
        "A/A PVE Range: Practice session started for %s.\nProceed to %s (%s).\n"..
        "Say 'ready' when on station to request your first intercept.",
        session.ClientName, capZone and capZone.Name or "CAP zone", bulls), 30)
    self:SendTTS(string.format(
        "Magic, %s, practice session started. Proceed to %s, %s. Report ready when on station.",
        session.ClientName, capZone and capZone.Name or "CAP zone", bulls))

    self:Log("Practice session started for " .. uName)
    return session
end

-- Called when the client is ready and requests the next practice intercept.
function AAPVE_MOOSE:SpawnPracticeBogie(uName)
    if self:GetRangeMode() ~= "InterceptPractice" then return end
    local session = self.PracticeSessions[uName]
    if not session then
        self:BlueMessage("A/A PVE Range: no active practice session. Check in first.", 10)
        return
    end
    if session.State ~= "Idle" then
        self:BlueMessage("A/A PVE Range: bogey already active. Wait for the run to complete.", 10)
        return
    end

    local opt  = self:GetRandomOption(self.PracticeTemplates) or self:GetRandomOption(self.PictureHostileTemplates)
    local zone = self:GetRandomRedSpawnZone()
    if not opt or not zone then
        self:BlueMessage("A/A PVE Range: practice spawn failed (no template or zone).", 10)
        return
    end

    local altFt = math.random(self.PracticeMinAltitudeFt, self.PracticeMaxAltitudeFt)
    local altM  = UTILS.FeetToMeters(altFt)
    local spdMs = UTILS.KnotsToMps(self.PracticeSpeedKts)
    session.SpawnCount = session.SpawnCount + 1

    local alias = string.format("AAPVE_PRAC_%s_R%d",
        self:GetSanitizedName(uName), session.SpawnCount)

    local group = SPAWN:NewWithAlias(opt.Template, alias)
        :InitRandomizeZones({ zone })
        :InitGrouping(1)
        :InitSkill("Average")
        :Spawn()

    if not group then
        self:BlueMessage("A/A PVE Range: practice bogey spawn failed.", 10)
        return
    end

    self:AddActiveGroup(group)
    session.TargetGroup = group
    session.State       = "BogieActive"

    -- Fully passive setup: weapons hold, alarm green, no AI reaction whatsoever.
    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then return end
        group:OptionAlarmStateGreen()
        group:OptionROEHoldFire()
        group:OptionROTPassiveDefense()
        -- Route toward the protected zone.
        local dest = (self.ProtectedZone and self.ProtectedZone:GetCoordinate())
            or (session.CapZone and session.CapZone.Zone:GetCoordinate())
        if dest then
            local task = group:TaskRouteToVec2(dest:GetVec2(), spdMs, altM, "BARO")
            if task then group:SetTask(task) end
        end
    end, {}, 2)

    -- AWACS picture call.
    local spawnCoord = zone:GetCoordinate()
    local bulls      = spawnCoord and self:GetBullseyeText(spawnCoord) or "unknown"
    local angStr     = self:AltitudeToAngels(altFt)

    self:BlueMessage(string.format(
        "A/A PVE Range: [PRACTICE] Run %d — %s\n"..
        "Inbound bogey, weapons hold, no reaction.\n"..
        "Position: %s  |  Altitude: %s (%d ft)  |  Speed: %d kts\n"..
        "Flow intercept and close to within %.0f NM.",
        session.SpawnCount, session.ClientName,
        bulls, angStr, altFt, self.PracticeSpeedKts, self.PracticeWVRRangeNm), 30)
    self:SendTTS(string.format(
        "Magic, %s, practice run %d. Single group inbound, weapons hold. "..
        "%s, %s, hot. Flow intercept.",
        session.ClientName, session.SpawnCount, bulls, angStr))

    self:Log(string.format("Practice bogey spawned for %s (run %d).", uName, session.SpawnCount))
end

-- Polls for intercept completion (client within WVR range of practice bogey).
function AAPVE_MOOSE:TickPracticeMonitor()
    if self:GetRangeMode() ~= "InterceptPractice" then return end
    for uName, session in pairs(self.PracticeSessions) do
        if session.State == "BogieActive" then
            local group = session.TargetGroup
            if not group or not group:IsAlive() then
                session.State = "Idle"; session.TargetGroup = nil
            else
                local client = CLIENT:FindByName(uName)
                if client and client:IsAlive() then
                    local cCoord = client:GetCoordinate()
                    local gCoord = group:GetCoordinate()
                    if cCoord and gCoord then
                        local distNm = UTILS.MetersToNM(cCoord:Get2DDistance(gCoord))
                        if distNm <= self.PracticeWVRRangeNm then
                            self:PracticeBogieIntercepted(uName, session)
                        end
                    end
                end
            end
        end
    end
end

function AAPVE_MOOSE:PracticeBogieIntercepted(uName, session)
    local group = session.TargetGroup
    session.State = "Recovering"

    -- Turn the bogey cold — route away from the protected zone.
    if group and group:IsAlive() then
        local coldSpdMs  = UTILS.KnotsToMps(self.BogieEvadeSpeedKts or 550)
        local gCoord     = group:GetCoordinate()
        local protCoord  = self.ProtectedZone and self.ProtectedZone:GetCoordinate()
        if gCoord and protCoord then
            local bearAway = (self:GetBearingDegrees(protCoord, gCoord) or 0) % 360
            local coldDest = gCoord:Translate(UTILS.NMToMeters(200), bearAway)
            local task = group:TaskRouteToVec2(coldDest:GetVec2(), coldSpdMs,
                gCoord:GetAltitude(), "BARO")
            if task then group:SetTask(task) end
        end
        SCHEDULER:New(nil, function()
            if group and group:IsAlive() then group:Destroy() end
        end, {}, self.PracticeBogieColdSecs or 60)
    end
    session.TargetGroup = nil

    local capName  = session.CapZone and session.CapZone.Name or "CAP zone"
    local capCoord = session.CapZone and session.CapZone.Zone:GetCoordinate()
    local bulls    = capCoord and self:GetBullseyeText(capCoord) or "station"

    self:BlueMessage(string.format(
        "A/A PVE Range: [PRACTICE] %s — intercept complete!\n"..
        "Bogey is cold. Return to %s (%s).\n"..
        "Say 'ready' when on station for your next run.",
        session.ClientName, capName, bulls), 25)
    self:SendTTS(string.format(
        "Magic, %s, intercept complete. Bogey cold. Return to %s, %s. "..
        "Report ready for next run.",
        session.ClientName, capName, bulls))

    -- Poll for return to CAP zone every 30 s.
    SCHEDULER:New(nil, function()
        AAPVE_MOOSE:PracticeCheckReturn(uName, session)
    end, {}, 30)

    self:Log(string.format("Practice bogey intercepted for %s.", uName))
end

-- Repeatedly checks if the client has returned to their CAP zone.
function AAPVE_MOOSE:PracticeCheckReturn(uName, session)
    if session.State ~= "Recovering" then return end
    if self:GetRangeMode() ~= "InterceptPractice" then return end

    local client = CLIENT:FindByName(uName)
    if not client or not client:IsAlive() then return end

    local capZone = session.CapZone
    if not capZone then
        session.State = "Idle"; return
    end

    local cCoord = client:GetCoordinate()
    if cCoord and capZone.Zone:IsCoordinateInZone(cCoord) then
        session.State = "Idle"
        self:BlueMessage(string.format(
            "A/A PVE Range: %s is back on station. Say 'ready' for your next run.",
            session.ClientName), 15)
        self:SendTTS(string.format(
            "Magic, %s, on station. Report ready for next intercept.", session.ClientName))
    else
        SCHEDULER:New(nil, function()
            AAPVE_MOOSE:PracticeCheckReturn(uName, session)
        end, {}, 30)
    end
end

function AAPVE_MOOSE:StartPracticeMonitor()
    if self.PracticeMonitor then
        pcall(function() self.PracticeMonitor:Stop() end)
    end
    self.PracticeMonitor = SCHEDULER:New(nil, function()
        AAPVE_MOOSE:TickPracticeMonitor()
    end, {}, 5, self.PracticeMonitorSecs or 5)
end

---------------------------------------------------------------------------
-- Tanker / AAR helpers.
--
-- Finds the nearest active tanker group by group-name prefix, provides a
-- BULLSEYE vector, and pauses the picture loop until the client returns.
-- Uses the ACC-standard callsign TEXACO as the phraseology anchor.
---------------------------------------------------------------------------

-- Returns (group, coordinate) of the nearest alive tanker, or nil.
function AAPVE_MOOSE:FindNearestTanker(fromCoord)
    if not fromCoord then return nil, nil end
    local best, bestDist, bestCoord
    for _, prefix in ipairs(self.TankerGroupPrefixes) do
        local grpSet = SET_GROUP:New()
            :FilterPrefixes({ prefix })
            :FilterCoalitions("blue")
            :FilterOnce()
        grpSet:ForEachGroup(function(grp)
            if grp and grp:IsAlive() then
                local gCoord = grp:GetCoordinate()
                if gCoord then
                    local d = fromCoord:Get2DDistance(gCoord)
                    if not best or d < bestDist then
                        best = grp; bestDist = d; bestCoord = gCoord
                    end
                end
            end
        end)
    end
    return best, bestCoord
end

-- Provides a TEXACO vector to the client and pauses the picture loop.
function AAPVE_MOOSE:VectorClientToTanker(pkg, client)
    if not pkg or not client then return end

    local clientCoord        = client:GetCoordinate()
    local tanker, tankerCoord= self:FindNearestTanker(clientCoord)
    local callsign           = pkg.LeadClientName or "flight"

    if not tanker or not tankerCoord then
        self:BlueMessage("A/A PVE Range: no tanker available. Expedite recovery or remain on station.", 10)
        self:SendTTS(string.format(
            "Magic, %s, no tanker available at this time. Expedite recovery.", callsign))
        return
    end

    local bulls   = self:GetBullseyeText(tankerCoord)
    local distNm  = clientCoord
        and math.floor(UTILS.MetersToNM(clientCoord:Get2DDistance(tankerCoord))) or -1
    local bearing = clientCoord
        and math.floor(self:GetBearingDegrees(clientCoord, tankerCoord) or 0) or -1

    self:BlueMessage(string.format(
        "A/A PVE Range: TEXACO — Package %d\nTanker: %s\nBullseye: %s\n"..
        "Bearing: %03d°  Range: %d NM\nPicture held while off-station.",
        pkg.Id, tanker:GetName() or "Tanker", bulls, bearing, distNm), 30)
    self:SendTTS(string.format(
        "Magic, %s, TEXACO, bullseye %s, bearing %03d, range %d. Report off-station.",
        callsign, bulls, bearing, distNm))

    pkg.PictureHeld     = true
    pkg.TankerState     = "EnRoute"
    pkg.TankerStartTime = timer.getTime()

    -- Auto-resume picture after timeout regardless of return.
    SCHEDULER:New(nil, function()
        if pkg and pkg.PictureHeld then
            pkg.PictureHeld = false
            pkg.TankerState = nil
            self:SendTTS(string.format(
                "Magic, CAP package %d, tanker hold expired. Picture resuming. Return to %s.",
                pkg.Id, pkg.AssignedZone and pkg.AssignedZone.Name or "CAP"))
        end
    end, {}, self.TankerReturnTimeoutSecs or 900)

    self:Log(string.format("Package %d vectored to tanker %s.", pkg.Id, tanker:GetName() or "?"))
end

---------------------------------------------------------------------------
-- Client checkout.
--
-- Called when the pilot says "good day" / "checking out".
-- Finalizes the scorecard, announces the debrief, and closes the package.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ProcessClientCheckout(pkg, client, ctrl, atc, airport)
    if not pkg then return end

    local callsign = pkg.LeadClientName or "flight"
    self:FinalizeScoreCard(pkg)

    local homeMsg = ""
    if airport then
        homeMsg = string.format(" RTB %s.", airport.Name or self.NASGATCAirportId or "home plate")
    end

    if ctrl and atc and airport then
        local facCS = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)
        ctrl:Send(atc, airport, string.format(
            "%s, %s, good day. Package %d checked out. Debrief to follow.%s",
            callsign, facCS, pkg.Id, homeMsg))
    else
        self:SendTTS(string.format(
            "Magic, %s, good day. Package %d checked out.%s",
            callsign, pkg.Id, homeMsg))
    end

    if not pkg.FSM:Is("Closed") then
        pkg.FSM:Close("Client checked out.")
    end
end

---------------------------------------------------------------------------
-- Package close.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ClosePackage(pkg, reason)
    if not pkg or pkg.FSM:Is("Closed") then return end
    pkg.FSM:Close(reason)
end

function AAPVE_MOOSE:ClearAllPackages()
    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed") then
            pkg.FSM:Close("Range cleared.")
        end
    end
    self.CapPackages      = {}
    self.NextCapPackageId = 1
end

---------------------------------------------------------------------------
-- Coalition F10 menus.
---------------------------------------------------------------------------

function AAPVE_MOOSE:BuildTimelineClientMenus(parentMenu)
    -- Remove previous dynamic items.
    for _, item in pairs(self.TimelineClientMenus) do
        if item and item.Remove then pcall(function() item:Remove() end) end
    end
    self.TimelineClientMenus = {}

    local bvrMenu = MENU_COALITION:New(coalition.side.BLUE, "BVR - 80 NM Hot",                parentMenu)
    local wvrMenu = MENU_COALITION:New(coalition.side.BLUE, "WVR - 20 NM Hot",                parentMenu)
    local bfmMenu = MENU_COALITION:New(coalition.side.BLUE, "BFM - 5 NM Hold Until Merge",   parentMenu)

    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = bvrMenu
    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = wvrMenu
    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = bfmMenu

    local clientCount = 0
    self.BlueClientSet:ForEachClient(function(c)
        if c and c:IsAlive() then
            clientCount = clientCount + 1
            local cName = c:GetName()
            local dName = self:GetClientDisplayName(c)

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE, dName, bvrMenu,
                function()
                    local sel = CLIENT:FindByName(cName)
                    if sel then AAPVE_MOOSE:SpawnTimelineBanditForClient(sel, "BVR") end
                end)

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE, dName, wvrMenu,
                function()
                    local sel = CLIENT:FindByName(cName)
                    if sel then AAPVE_MOOSE:SpawnTimelineBanditForClient(sel, "WVR") end
                end)

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE, dName, bfmMenu,
                function()
                    local sel = CLIENT:FindByName(cName)
                    if sel then AAPVE_MOOSE:SpawnTimelineBanditForClient(sel, "BFM") end
                end)
        end
    end)

    if clientCount == 0 then
        self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
            coalition.side.BLUE, "No active BLUE clients found", parentMenu,
            function()
                AAPVE_MOOSE:BlueMessage("No active BLUE clients found. Refresh after clients spawn.", 10)
            end)
    end

    self:BlueMessage("A/A PVE Range: timeline client list refreshed.", 10)
end

function AAPVE_MOOSE:BuildCapCheckInClientMenus(parentMenu)
    for _, item in pairs(self.CapCheckInClientMenus) do
        if item and item.Remove then pcall(function() item:Remove() end) end
    end
    self.CapCheckInClientMenus = {}

    local clientCount = 0
    self.BlueClientSet:ForEachClient(function(c)
        if c and c:IsAlive() then
            clientCount = clientCount + 1
            local cName = c:GetName()
            local dName = self:GetClientDisplayName(c)

            self.CapCheckInClientMenus[#self.CapCheckInClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE, dName, parentMenu,
                function()
                    local sel = CLIENT:FindByName(cName)
                    if sel then AAPVE_MOOSE:RequestCapCheckIn(sel) end
                end)
        end
    end)

    if clientCount == 0 then
        self.CapCheckInClientMenus[#self.CapCheckInClientMenus + 1] = MENU_COALITION_COMMAND:New(
            coalition.side.BLUE, "No active BLUE clients found", parentMenu,
            function()
                AAPVE_MOOSE:BlueMessage("No active BLUE clients found. Refresh after clients spawn.", 10)
            end)
    end

    self:BlueMessage("A/A PVE Range: CAP check-in client list refreshed.", 10)
end

function AAPVE_MOOSE:BuildCoalitionMenus()
    -- ---- Mode control ----
    local modeMenu = self:AddMenuItem(
        MENU_COALITION:New(coalition.side.BLUE, "Mode", self.MenuRoot))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Start RED CAP Target Practice", modeMenu,
        function()
            AAPVE_MOOSE.RangeFSM:StartRedCap()  -- OnBefore guard handles invalid state
        end))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Start BLUE CAP Defense", modeMenu,
        function()
            AAPVE_MOOSE.RangeFSM:StartBlueCap()
        end))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Start Intercept Practice (Ungraded)", modeMenu,
        function()
            AAPVE_MOOSE.RangeFSM:StartPractice()
        end))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Stop Current Mode", modeMenu,
        function()
            local mode = AAPVE_MOOSE:GetRangeMode()
            if mode == "Idle" or mode == "Stopped" then
                AAPVE_MOOSE:BlueMessage("A/A PVE Range is already idle.", 10)
                return
            end
            AAPVE_MOOSE.RangeFSM:StopMode()
        end))

    -- ---- Manual RED CAP ----
    local redCapMenu = self:AddMenuItem(
        MENU_COALITION:New(coalition.side.BLUE, "Manual RED CAP Spawn", self.MenuRoot))

    for _, opt in ipairs(self.RedCapTemplates) do
        local o = opt
        self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
            "Spawn " .. o.Name .. " x1", redCapMenu,
            function() AAPVE_MOOSE:SpawnManualRedCap(o, 1, "Random") end))
        self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
            "Spawn " .. o.Name .. " x2", redCapMenu,
            function() AAPVE_MOOSE:SpawnManualRedCap(o, 2, "Random") end))
        self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
            "Spawn " .. o.Name .. " x4", redCapMenu,
            function() AAPVE_MOOSE:SpawnManualRedCap(o, 4, "Random") end))
    end

    -- ---- Timeline spawns ----
    local timelineMenu = self:AddMenuItem(
        MENU_COALITION:New(coalition.side.BLUE, "Timeline Spawn", self.MenuRoot))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Refresh Timeline Client List", timelineMenu,
        function() AAPVE_MOOSE:BuildTimelineClientMenus(timelineMenu) end))

    self:BuildTimelineClientMenus(timelineMenu)

    -- ---- CAP check-in ----
    local capCheckInMenu = self:AddMenuItem(
        MENU_COALITION:New(coalition.side.BLUE, "CAP Check-in Client Selector", self.MenuRoot))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Refresh CAP Check-in Client List", capCheckInMenu,
        function() AAPVE_MOOSE:BuildCapCheckInClientMenus(capCheckInMenu) end))

    self:BuildCapCheckInClientMenus(capCheckInMenu)

    -- ---- Range settings (F10 parity with the voice commands) ----
    local settingsMenu = self:AddMenuItem(
        MENU_COALITION:New(coalition.side.BLUE, "Range Settings", self.MenuRoot))

    local difficultyMenu = MENU_COALITION:New(coalition.side.BLUE, "Difficulty", settingsMenu)
    self:AddMenuItem(difficultyMenu)
    for _, lvl in ipairs({ "easy", "medium", "hard" }) do
        local level = lvl
        self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
            level:gsub("^%l", string.upper), difficultyMenu,
            function() AAPVE_MOOSE:SetDifficulty(level) end))
    end

    local cadenceMenu = MENU_COALITION:New(coalition.side.BLUE, "Picture Cadence", settingsMenu)
    self:AddMenuItem(cadenceMenu)
    for _, spd in ipairs({ "fast", "normal", "slow" }) do
        local speed = spd
        self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
            speed:gsub("^%l", string.upper), cadenceMenu,
            function() AAPVE_MOOSE:SetPictureCadence(speed) end))
    end

    -- ---- Utilities ----
    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Toggle FOX Missile Trainer", self.MenuRoot,
        function() AAPVE_MOOSE:ToggleFoxTrainer() end))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Clear Range", self.MenuRoot,
        function()
            AAPVE_MOOSE:ClearRange(true)
            -- Drive FSM back to Idle via StopMode if currently in a mode.
            local mode = AAPVE_MOOSE:GetRangeMode()
            if mode == "RedCapPractice" or mode == "BlueCapDefense"
                    or mode == "InterceptPractice" then
                AAPVE_MOOSE.RangeFSM:StopMode()
            end
        end))

    self:AddMenuItem(MENU_COALITION_COMMAND:New(coalition.side.BLUE,
        "Show Status", self.MenuRoot,
        function() AAPVE_MOOSE:ShowStatus() end))
end

---------------------------------------------------------------------------
-- Status display.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ShowStatus()
    local aliveCount = 0
    for _, g in pairs(self.ActiveGroups) do
        if g and g:IsAlive() then aliveCount = aliveCount + 1 end
    end

    local txt = string.format(
        "A/A PVE Range Status\nMode: %s\nFOX Trainer: %s\nCAP Packages: %d\nActive Hostiles: %d\nSpawned Groups: %d",
        self:GetRangeMode(),
        tostring(self.FoxTrainerEnabled),
        self:GetActivePackageCount(),
        self:GetGlobalActiveHostileCount(),
        aliveCount)

    for _, pkg in pairs(self.CapPackages) do
        if pkg and not pkg.FSM:Is("Closed") then
            local onStation = self:CountPackageMembersOnStation(pkg)
            local inSandbox = self:CountPackageMembersInSandbox(pkg)
            local hostile   = pkg.ActiveHostileGroup and pkg.ActiveHostileGroup:IsAlive() and "Yes" or "No"

            txt = txt .. string.format(
                "\n\nPackage %d\nLead: %s\nHold: %s\nState: %s\nOn Station: %d\nIn Sandbox: %d\nHostile: %s",
                pkg.Id,
                pkg.LeadClientName or "Unknown",
                pkg.AssignedZone and pkg.AssignedZone.Name or "Unknown",
                pkg.FSM:GetCurrentState(),
                onStation, inSandbox, hostile)
        end
    end

    self:BlueMessage(txt, 25)
end

---------------------------------------------------------------------------
-- Cleanup / stop.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ClearRange(showMessage)
    if self.MonitorScheduler then
        pcall(function() self.MonitorScheduler:Stop() end)
        self.MonitorScheduler = nil
    end

    if self.PictureScheduler then
        pcall(function() self.PictureScheduler:Stop() end)
        self.PictureScheduler = nil
    end

    -- The periodic picture broadcast now lives on the AWACS controller.
    if NASG_ATC_AWACS and NASG_ATC_AWACS.StopPictureBroadcast then
        pcall(function() NASG_ATC_AWACS:StopPictureBroadcast() end)
    end
    if self.BroadcastScheduler then
        pcall(function() self.BroadcastScheduler:Stop() end)
        self.BroadcastScheduler = nil
    end

    if self.PracticeMonitor then
        pcall(function() self.PracticeMonitor:Stop() end)
        self.PracticeMonitor = nil
    end
    self.PracticeSessions = {}

    self:ClearAllPackages()

    for _, g in pairs(self.ActiveGroups) do
        self:DestroyGroup(g)
    end
    self.ActiveGroups = {}

    self:StopBlueChief()

    if showMessage ~= false then
        self:BlueMessage("A/A PVE Range cleared.", 10)
    end
end

function AAPVE_MOOSE:Stop()
    self:ClearRange(false)
    self:StopFoxTrainer()
    pcall(function() self.RangeFSM:Shutdown() end)
end

---------------------------------------------------------------------------
-- AWACS integration.
--
-- The AWACS controller (NASG_ATC_AWACS) owns the voice patterns, the call
-- formatting, and the periodic picture cadence. The range plugs its scenario
-- behavior in through the controller's extension points instead of replacing
-- handler bodies:
--
--   1. a live contact-data provider (BRAA / BULLSEYE for the speaking pilot),
--   2. an event listener that drives the package FSMs and scoring off the
--      pilot's voice reports (check-in, commit, fox, merge, splash, ...),
--   3. a range controller backing the range-control voice intents
--      (start/stop modes, FOX trainer, difficulty, cadence, status), and
--   4. a picture-broadcast source (the live on-station hostile groups).
--
-- The range-control commands call the SAME functions as the F10 menus, so
-- voice and menu control stay in sync. This function is idempotent.
---------------------------------------------------------------------------

function AAPVE_MOOSE:RegisterAWACSIntegration()
    if not self.NASGATCEnabled then return end
    if not NASG_ATC_AWACS then
        self:Log("NASG_ATC_AWACS not loaded — AWACS integration skipped.")
        return
    end
    if self._NASGHooksInstalled then return end
    self._NASGHooksInstalled = true

    -- Resolve a MOOSE CLIENT to its active CAP package (lead or member).
    local function pkgForClient(client)
        if not client then return nil end
        local uName = client:GetName()
        return AAPVE_MOOSE:GetPackageByLeadUnit(uName)
            or AAPVE_MOOSE:GetPackageByMemberUnit(uName)
    end

    -- True when the range is in BlueCapDefense mode.
    local function rangeActive()
        return AAPVE_MOOSE:GetRangeMode() == "BlueCapDefense"
    end

    -- Build a BULLSEYE picture reply for a package's live group (or nil).
    -- Returns (replyString, groupData).
    local function livePictureReply(atc, client, event, pkg)
        local gd = AAPVE_MOOSE:GetLiveGroupData(pkg, client)
        if not gd then return nil, nil end
        local callsign = atc:GetClientCallsign(client, event)
        local contacts = gd.Contacts or 1
        local groupStr = contacts >= 3 and "heavy group"
                      or (contacts == 2 and "group" or "single group")
        return string.format(
            "%s, picture. %s. %s. %s. %s.",
            callsign, groupStr,
            gd.Bulls or "bullseye unknown",
            NASG_ATC_AWACS:FormatAltitude(gd.AltFt),
            gd.Id or "bogey"), gd
    end

    -----------------------------------------------------------------------
    -- 1) Live contact-data provider.
    -- Returns live data for the speaking client's package, or nil when there
    -- is no live hostile (so the controller falls back to any stored session
    -- group, e.g. a VID or ghost contact).
    -----------------------------------------------------------------------
    NASG_ATC_AWACS:SetGroupDataProvider(function(_, client, _session)
        if not rangeActive() then return nil end
        local pkg = pkgForClient(client)
        if not pkg then return nil end
        return AAPVE_MOOSE:GetLiveGroupData(pkg, client)
    end)

    -----------------------------------------------------------------------
    -- 2) Event listener. A method may return a string (custom spoken reply)
    -- or true (suppress the controller's default reply); returning nothing
    -- lets the controller speak its own reply after the side effects run.
    -----------------------------------------------------------------------
    local listener = {}

    function listener:OnCheckIn(ctrl, atc, client, airport, session, event)
        -- Intercept Practice: begin a practice session (self-announces).
        if AAPVE_MOOSE:GetRangeMode() == "InterceptPractice" then
            AAPVE_MOOSE:StartPracticeSession(client)
            return true
        end
        if not rangeActive() then return nil end

        local callsign    = atc:GetClientCallsign(client, event)
        local facCallsign = atc:GetFacilityCallsign(airport, atc.Facilities.AWACS)

        -- Pilot's current Bullseye for the Alpha Check (also stored so a
        -- follow-on "alpha check" query works).
        local pilotBulls
        pcall(function()
            local coord = client:GetCoordinate()
            if coord then
                pilotBulls = AAPVE_MOOSE:GetBullseyeText(coord)
                session.PilotBulls = pilotBulls
            end
        end)

        local pkg = AAPVE_MOOSE:RequestCapCheckIn(client)
        if pkg then
            pkg.NASGSession        = session
            session.InterceptPhase = NASG_ATC_AWACS.InterceptPhase.PRE_COMMIT
            session.ActiveGroup    = nil
            ctrl:TouchSession(session)

            local altTTS = ""
            if pkg.AssignedZone and pkg.AssignedZone.AltMinFt and pkg.AssignedZone.AltMaxFt then
                altTTS = string.format(", angels %s to %s",
                    AAPVE_MOOSE:AltitudeToAngels(pkg.AssignedZone.AltMinFt),
                    AAPVE_MOOSE:AltitudeToAngels(pkg.AssignedZone.AltMaxFt))
            end
            local alphaStr = pilotBulls
                and string.format(" Alpha check bullseye %s.", pilotBulls) or ""

            return string.format(
                "%s, %s, contact, %s, maintain %s",
                callsign, facCallsign, alphaStr, altTTS)
        end
        return string.format(
            "%s, %s, unable to assign a CAP station. All zones occupied or range not active.",
            callsign, facCallsign)
    end

    function listener:OnPictureRequest(ctrl, atc, client, airport, session, event)
        if not rangeActive() then return nil end
        local pkg      = pkgForClient(client)
        local callsign = atc:GetClientCallsign(client, event)
        if pkg and pkg.FSM:Is("OnStation") then
            local reply, gd = livePictureReply(atc, client, event, pkg)
            if reply then
                session.ActiveGroup = gd
                return reply
            end
            AAPVE_MOOSE:GeneratePictureForPackage(pkg)
            return string.format("%s, stand by picture.", callsign)
        elseif pkg then
            return string.format(
                "%s, picture unavailable. Disengage and return to CAP first.", callsign)
        end
        return nil
    end

    function listener:OnCommit(ctrl, atc, client, airport, session, event)
        if rangeActive() then
            local pkg = pkgForClient(client)
            if pkg then AAPVE_MOOSE:RecordScoreEvent(pkg, "commit_called") end
        end
    end

    function listener:OnTargeted(ctrl, atc, client, airport, session, event)
        if rangeActive() then
            local pkg = pkgForClient(client)
            if pkg then AAPVE_MOOSE:RecordScoreEvent(pkg, "targeted_called") end
        end
    end

    function listener:OnThreat(ctrl, atc, client, airport, session, event)
        if rangeActive() then
            local pkg = pkgForClient(client)
            if pkg then AAPVE_MOOSE:RecordScoreEvent(pkg, "threat_ack") end
        end
    end

    function listener:OnDefending(ctrl, atc, client, airport, session, event)
        if rangeActive() then
            local pkg = pkgForClient(client)
            if pkg then AAPVE_MOOSE:RecordScoreEvent(pkg, "threat_ack") end
        end
    end

    function listener:OnFox(ctrl, atc, client, airport, session, event)
        if not rangeActive() then return end
        local pkg = pkgForClient(client)
        local gd  = pkg and AAPVE_MOOSE:GetLiveGroupData(pkg, client)
        if not gd then return end
        -- Detect missile type from the transcript when available.
        local t       = string.lower(tostring(event and (event.Transcript or event.raw_text) or ""))
        local foxType = 3   -- default Fox 3 (active radar)
        if t:find("fox.?one") or t:find("fox.?1") then
            foxType = 1
        elseif t:find("fox.?two") or t:find("fox.?2") then
            foxType = 2
        end
        local rNm = gd.Braa and tonumber(string.match(gd.Braa, "/(%d+)")) or -1
        AAPVE_MOOSE:RecordScoreEvent(pkg, "fox",
            { range_nm = rNm, aspect = gd.Aspect or "", fox_type = foxType })
        AAPVE_MOOSE:RecordScoreEvent(pkg, "phase_advance", { phase = "TARGETED" })
    end

    function listener:OnMerge(ctrl, atc, client, airport, session, event)
        if not rangeActive() then return nil end
        local pkg = pkgForClient(client)
        if not pkg then return nil end
        if pkg.FSM:Is("OnStation") or pkg.FSM:Is("Assigned") then
            pkg.FSM:Commit()
        end
        AAPVE_MOOSE:RecordScoreEvent(pkg, "phase_advance", { phase = "MERGED" })
        local gd = AAPVE_MOOSE:GetLiveGroupData(pkg, client)
        if gd and gd.Braa then
            local rNm = tonumber(string.match(gd.Braa, "/(%d+)"))
            if rNm then AAPVE_MOOSE:RecordScoreEvent(pkg, "merge", { range_nm = rNm }) end
        end
        return string.format(
            "%s, %s, merged. Separate when able. Report splash or no joy.",
            atc:GetClientCallsign(client, event),
            atc:GetFacilityCallsign(airport, atc.Facilities.AWACS))
    end

    function listener:OnSplash(ctrl, atc, client, airport, session, event)
        if not rangeActive() then return nil end
        local pkg = pkgForClient(client)
        if not pkg then return nil end
        if not pkg.FSM:Is("Retasking") and not pkg.FSM:Is("Closed") then
            pkg.FSM:Disengage("Splash reported by pilot.")
        end
        AAPVE_MOOSE:UpdateSessionGroupData(pkg, nil)
        AAPVE_MOOSE:RecordScoreEvent(pkg, "splash")
        AAPVE_MOOSE:RecordScoreEvent(pkg, "phase_advance", { phase = "POST_MERGE" })
        return string.format(
            "%s, %s, splash confirmed. Well done. Return to CAP, stand by new picture.",
            atc:GetClientCallsign(client, event),
            atc:GetFacilityCallsign(airport, atc.Facilities.AWACS))
    end

    function listener:OnCombatRecovery(ctrl, atc, client, airport, session, event)
        if not rangeActive() then return end
        local pkg = pkgForClient(client)
        if pkg and not pkg.FSM:Is("Retasking") and not pkg.FSM:Is("Closed") then
            pkg.FSM:Disengage("Combat recovery requested.")
        end
        -- Return nil so the controller issues the tower / home-plate vector.
    end

    function listener:OnTanker(ctrl, atc, client, airport, session, event)
        local pkg = pkgForClient(client)
        if pkg and rangeActive() then
            AAPVE_MOOSE:VectorClientToTanker(pkg, client)
            return true   -- VectorClientToTanker sends its own radio call
        end
        return nil
    end

    function listener:OnCheckout(ctrl, atc, client, airport, session, event)
        local pkg = pkgForClient(client)
        if pkg and rangeActive() then
            AAPVE_MOOSE:ProcessClientCheckout(pkg, client, ctrl, atc, airport)
            return true   -- ProcessClientCheckout sends its own reply
        end
        if AAPVE_MOOSE:GetRangeMode() == "InterceptPractice" then
            local uName = client:GetName()
            if uName then AAPVE_MOOSE.PracticeSessions[uName] = nil end
            return string.format("%s, %s, good day. Practice session ended.",
                atc:GetClientCallsign(client, event),
                atc:GetFacilityCallsign(airport, atc.Facilities.AWACS))
        end
        return nil
    end

    function listener:OnPracticeReady(ctrl, atc, client, airport, session, event)
        if AAPVE_MOOSE:GetRangeMode() == "InterceptPractice" then
            local uName = client:GetName()
            if uName then AAPVE_MOOSE:SpawnPracticeBogie(uName) end
            return true   -- SpawnPracticeBogie self-announces
        end
        if rangeActive() then
            local pkg = pkgForClient(client)
            if pkg and pkg.FSM:Is("OnStation") then
                local reply, gd = livePictureReply(atc, client, event, pkg)
                if reply then
                    session.ActiveGroup = gd
                    return reply
                end
                AAPVE_MOOSE:GeneratePictureForPackage(pkg)
                return string.format("%s, stand by picture.",
                    atc:GetClientCallsign(client, event))
            end
        end
        return nil
    end

    NASG_ATC_AWACS:AddListener(listener)

    -----------------------------------------------------------------------
    -- 3) Range-control voice commands. Each method returns the spoken reply
    -- and calls the SAME range functions as the F10 menus.
    -----------------------------------------------------------------------
    local function cs(atc, client, event) return atc:GetClientCallsign(client, event) end
    local function fac(atc, airport) return atc:GetFacilityCallsign(airport, atc.Facilities.AWACS) end

    local rangeCtl = {}

    function rangeCtl:StartBlueCap(ctrl, atc, client, airport, session, event)
        if AAPVE_MOOSE:GetRangeMode() ~= "Idle" then
            return string.format("%s, %s, unable. Stop the current range mode first.",
                cs(atc, client, event), fac(atc, airport))
        end
        AAPVE_MOOSE.RangeFSM:StartBlueCap()
        return string.format("%s, %s, BLUE CAP defense active. Flight leads may check in.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:StartRedCap(ctrl, atc, client, airport, session, event)
        if AAPVE_MOOSE:GetRangeMode() ~= "Idle" then
            return string.format("%s, %s, unable. Stop the current range mode first.",
                cs(atc, client, event), fac(atc, airport))
        end
        AAPVE_MOOSE.RangeFSM:StartRedCap()
        return string.format("%s, %s, RED CAP target practice active.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:StartPractice(ctrl, atc, client, airport, session, event)
        if AAPVE_MOOSE:GetRangeMode() ~= "Idle" then
            return string.format("%s, %s, unable. Stop the current range mode first.",
                cs(atc, client, event), fac(atc, airport))
        end
        AAPVE_MOOSE.RangeFSM:StartPractice()
        return string.format("%s, %s, intercept practice active. Check in when ready.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:StopMode(ctrl, atc, client, airport, session, event)
        local mode = AAPVE_MOOSE:GetRangeMode()
        if mode == "Idle" or mode == "Stopped" then
            return string.format("%s, %s, range already idle.",
                cs(atc, client, event), fac(atc, airport))
        end
        AAPVE_MOOSE.RangeFSM:StopMode()
        return string.format("%s, %s, range mode stopped. Returning to idle.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:FoxTrainerOn(ctrl, atc, client, airport, session, event)
        if not AAPVE_MOOSE.FoxTrainerEnabled then AAPVE_MOOSE:ToggleFoxTrainer() end
        return string.format("%s, %s, FOX missile trainer enabled.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:FoxTrainerOff(ctrl, atc, client, airport, session, event)
        if AAPVE_MOOSE.FoxTrainerEnabled then AAPVE_MOOSE:ToggleFoxTrainer() end
        return string.format("%s, %s, FOX missile trainer disabled.",
            cs(atc, client, event), fac(atc, airport))
    end

    function rangeCtl:Status(ctrl, atc, client, airport, session, event)
        AAPVE_MOOSE:ShowStatus()   -- detailed F10 text
        local pkgs = AAPVE_MOOSE:GetActivePackageCount()
        local host = AAPVE_MOOSE:GetGlobalActiveHostileCount()
        return string.format(
            "%s, %s, range %s. %d package%s, %d hostile group%s. FOX trainer %s.",
            cs(atc, client, event), fac(atc, airport),
            AAPVE_MOOSE:GetRangeModeWord(),
            pkgs, pkgs == 1 and "" or "s",
            host, host == 1 and "" or "s",
            AAPVE_MOOSE.FoxTrainerEnabled and "enabled" or "disabled")
    end

    function rangeCtl:SetDifficulty(ctrl, level, atc, client, airport, session, event)
        AAPVE_MOOSE:SetDifficulty(level)
        return string.format("%s, %s, range difficulty %s.",
            cs(atc, client, event), fac(atc, airport), tostring(level))
    end

    function rangeCtl:SetCadence(ctrl, speed, atc, client, airport, session, event)
        AAPVE_MOOSE:SetPictureCadence(speed)
        return string.format("%s, %s, picture cadence %s.",
            cs(atc, client, event), fac(atc, airport), tostring(speed))
    end

    -- Timeline bandit against the speaking pilot (BVR / WVR / BFM). Returns
    -- true because SpawnTimelineBanditForClient issues its own radio call.
    function rangeCtl:SpawnTimeline(ctrl, mode, atc, client, airport, session, event)
        AAPVE_MOOSE:SpawnTimelineBanditForClient(client, mode)
        return true
    end

    NASG_ATC_AWACS:SetRangeController(rangeCtl)

    -----------------------------------------------------------------------
    -- 4) Periodic picture broadcast. The controller owns the cadence and
    -- formatting; the range supplies the live groups (on-station packages
    -- with an active hostile). Started/stopped with BlueCapDefense mode.
    -----------------------------------------------------------------------
    NASG_ATC_AWACS:ConfigurePictureBroadcast({
        AirportId         = self.NASGATCAirportId,
        IntervalSecs      = self.BroadcastIntervalSecs,
        CleanIntervalSecs = self.BroadcastCleanIntervalSecs,
        Source            = function(_) return AAPVE_MOOSE:CollectBroadcastGroups() end,
    })

    self:Log("AWACS integration registered (provider, listener, range control, broadcast).")
end

---------------------------------------------------------------------------
-- Start.
---------------------------------------------------------------------------

function AAPVE_MOOSE:Start()
    self:InitMSRS()
    self:RegisterAWACSIntegration()
    self:BuildCoalitionMenus()
    self.RangeFSM:Start()
    self:BlueMessage("A/A PVE Range initialized.", 10)
    self:Log("Initialized.")
end

AAPVE_MOOSE:Start()
