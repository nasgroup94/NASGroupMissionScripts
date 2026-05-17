-- Air-to-Air PVE Range
--
-- Requires:
--   MOOSE loaded before this file.
--
-- Mission editor requirements:
--   Trigger zones:
--     AAPVE_CAP_ZONE
--     AAPVE_PLAYER_ZONE
--     AAPVE_REDAWACS_ZONE
--     AAPVE_RED_CAP_ZONE
--     AAPVE_PROTECTED_ZONE
--     AAPVE_RECOVERY_ZONE_1
--     AAPVE_RECOVERY_ZONE_2
--     AAPVE_RECOVERY_ZONE_3
--
-- Late-activated aircraft template groups currently used:
--   m29
--   su25
--   su27
--   f14
--   f16
--   f5
--   redawacs
--
-- Optional late-activated BLUE/friendly aircraft template groups:
--   AAPVE_Friendly_F18
--   AAPVE_Friendly_F16
--   AAPVE_Friendly_F14
--
-- Notes:
--   Manual "Spawn CAP" functionality is preserved.
--   New "CAP Hold Scenario" functionality adds randomized air picture generation.
--   Hostiles are more likely than non-threats.
--   Hostiles are more likely to flow toward the protected area.
--   Non-threats either route randomly or toward recovery zones, then despawn.
---------------------------------------------------------------------------

if AAPVERange and AAPVERange.ClearRange then
    pcall(function()
        AAPVERange:ClearRange(false)
    end)
end

AAPVERange = {}

---------------------------------------------------------------------------
-- Basic configuration.
---------------------------------------------------------------------------

AAPVERange.MenuRoot = MENU_COALITION:New(coalition.side.BLUE, "Air-to-Air PVE Range")
AAPVERange.SpawnMenu = nil
AAPVERange.MenuCommands = {}

AAPVERange.CapZone = ZONE:New("AAPVE_CAP_ZONE")
AAPVERange.PlayerZone = ZONE:New("AAPVE_PLAYER_ZONE")
AAPVERange.RedCapZone = ZONE:New("AAPVE_RED_CAP_ZONE")
AAPVERange.ProtectedZone = ZONE:New("AAPVE_PROTECTED_ZONE")

AAPVERange.RecoveryZones = {
    ZONE:New("AAPVE_RECOVERY_ZONE_1"),
    ZONE:New("AAPVE_RECOVERY_ZONE_2"),
    ZONE:New("AAPVE_RECOVERY_ZONE_3")
}

AAPVERange.CapHoldZones = {
    {
        Name = "CAP HOLD 1",
        Zone = ZONE:New("AAPVE_CAP_HOLD_1")
    },
    {
        Name = "CAP HOLD 2",
        Zone = ZONE:New("AAPVE_CAP_HOLD_2")
    },
    {
        Name = "CAP HOLD 3",
        Zone = ZONE:New("AAPVE_CAP_HOLD_3")
    }
}

AAPVERange.AssignedCapHold = nil
AAPVERange.AssignedCapMarkerId = nil

AAPVERange.CapAssignmentFrequency = 262
AAPVERange.CapAssignmentModulation = radio.modulation.AM
AAPVERange.CapAssignmentVoice = "Nathan"
AAPVERange.CapAssignmentLabel = "Magic"

AAPVERange.RedAwacsTemplate = "redawacs"
AAPVERange.RedAwacsZone = ZONE:New("AAPVE_REDAWACS_ZONE")
AAPVERange.RedAwacsAltitude = 30000
AAPVERange.RedAwacsSpeed = 300
AAPVERange.RedAwacsHeading = 90
AAPVERange.RedAwacsLeg = 40
AAPVERange.RedAwacsGroup = nil
AAPVERange.RedAwacsController = nil

AAPVERange.ActiveGroups = {}
AAPVERange.ActiveCapControllers = {}
AAPVERange.ClientsInZone = {}
AAPVERange.DetectedGroups = {}

AAPVERange.SelectedAircraft = nil
AAPVERange.SelectedCount = nil
AAPVERange.SelectedSkill = nil

AAPVERange.DefaultEngageRangeNm = 60
AAPVERange.ClientZoneCheckSeconds = 5
AAPVERange.DetectionCheckSeconds = 10

---------------------------------------------------------------------------
-- CAP Hold Scenario configuration.
---------------------------------------------------------------------------

AAPVERange.CapScenarioActive = false
AAPVERange.CapScenarioScheduler = nil
AAPVERange.CapScenarioIntervalSeconds = 180
AAPVERange.CapScenarioInitialDelaySeconds = 20

AAPVERange.CapScenarioMaxActiveGroups = 6
AAPVERange.CapScenarioBaseGroupsPerPlayer = 1
AAPVERange.CapScenarioMaxGroupsPerWave = 4

AAPVERange.CapScenarioHostileChance = 70
AAPVERange.CapScenarioFriendlyChance = 20
AAPVERange.CapScenarioNeutralChance = 10

AAPVERange.CapScenarioHostileFlowToProtectedChance = 75

AAPVERange.CapScenarioMinAltitude = 10000
AAPVERange.CapScenarioMaxAltitude = 32000
AAPVERange.CapScenarioMinSpeed = 300
AAPVERange.CapScenarioMaxSpeed = 520

AAPVERange.CapScenarioNonThreatMinLifetimeSeconds = 420
AAPVERange.CapScenarioNonThreatMaxLifetimeSeconds = 1200
AAPVERange.CapScenarioNonThreatRecoverChance = 60
AAPVERange.CapScenarioNonThreatDespawnDistanceNm = 8

---------------------------------------------------------------------------
-- Aircraft options.
---------------------------------------------------------------------------

AAPVERange.AircraftOptions = {
    {
        MenuName = "MiG-29",
        Template = "m29",
        EngageRangeNm = 20
    },
    {
        MenuName = "Su-25",
        Template = "su25",
        EngageRangeNm = 35
    },
    {
        MenuName = "Su-27",
        Template = "su27",
        EngageRangeNm = 45
    },
    {
        MenuName = "F-14A",
        Template = "f14",
        EngageRangeNm = 60
    },
    {
        MenuName = "F-16C",
        Template = "f16",
        EngageRangeNm = 40
    },
    {
        MenuName = "F-5",
        Template = "f5",
        EngageRangeNm = 30
    }
}

AAPVERange.CapScenarioHostileOptions = {
    {
        MenuName = "MiG-29",
        Template = "m29",
        EngageRangeNm = 35
    },
    {
        MenuName = "Su-27",
        Template = "su27",
        EngageRangeNm = 45
    },
    {
        MenuName = "F-14A",
        Template = "f14",
        EngageRangeNm = 55
    },
    {
        MenuName = "F-16C",
        Template = "f16",
        EngageRangeNm = 40
    },
    {
        MenuName = "F-5",
        Template = "f5",
        EngageRangeNm = 25
    }
}

AAPVERange.CapScenarioFriendlyOptions = {
    {
        MenuName = "Friendly F/A-18",
        Template = "AAPVE_Friendly_F18"
    },
    {
        MenuName = "Friendly F-16",
        Template = "AAPVE_Friendly_F16"
    },
    {
        MenuName = "Friendly F-14",
        Template = "AAPVE_Friendly_F14"
    }
}

AAPVERange.CapScenarioNeutralOptions = {
    {
        MenuName = "Unknown MiG-29",
        Template = "m29"
    },
    {
        MenuName = "Unknown Su-27",
        Template = "su27"
    },
    {
        MenuName = "Unknown F-5",
        Template = "f5"
    },
    {
        MenuName = "Unknown FW-190",
        Template = "AAPVE_CIV_FW190"
    },
    {
        MenuName = "Unknown L-39",
        Template = "AAPVE_CIV_L39"
    },
    {
        MenuName = "Unknown BF-109",
        Template = "AAPVE_CIV_BF109"
    }
}

AAPVERange.CountOptions = {
    1,
    2,
    4
}

AAPVERange.SkillOptions = {
    "Average",
    "Good",
    "High",
    "Excellent",
    "Random"
}

AAPVERange.ClientSet = SET_CLIENT:New()
                                 :FilterCoalitions("blue")
                                 :FilterActive()
                                 :FilterStart()

AAPVERange.EventHandler = EVENTHANDLER:New()
AAPVERange.EventHandler:HandleEvent(EVENTS.Shot)
AAPVERange.EventHandler:HandleEvent(EVENTS.Dead)
AAPVERange.EventHandler:HandleEvent(EVENTS.Crash)
AAPVERange.EventHandler:HandleEvent(EVENTS.PilotDead)

---------------------------------------------------------------------------
-- Hook functions.
-- Put TTS calls in these functions.
---------------------------------------------------------------------------

function AAPVERange:OnAfterSpawned(spawnedGroup, aircraftName, count, skill, engageRangeNm)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: spawned %d x %s, skill %s, engage range %d NM.",
                    count,
                    aircraftName,
                    skill,
                    engageRangeNm
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- Create/play your TTS message here.
end

function AAPVERange:OnAfterClientInZone(client)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: %s entered the range.",
                    client:GetPlayerName() or client:GetName()
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Fight's on."
end

function AAPVERange:OnAfterClientOutOfZone(client)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: %s exited the range.",
                    client:GetPlayerName() or client:GetName()
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Knock it off."
end

function AAPVERange:OnAfterBanditDetected(banditGroup, client, distanceNm)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: %s engaging %s at %.0f NM.",
                    banditGroup:GetName(),
                    client:GetPlayerName() or client:GetName(),
                    distanceNm
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Bandits are committing."
end

function AAPVERange:OnAfterMissileFired(shooterUnit, weaponName, targetUnit)
    local shooterName = shooterUnit and shooterUnit:GetName() or "Unknown shooter"
    local targetName = targetUnit and targetUnit:GetName() or "unknown target"
    local missileName = weaponName or "missile"

    MESSAGE:New(
            string.format("A/A PVE Range: %s fired %s at %s.", shooterName, missileName, targetName),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Missile launch."
end

function AAPVERange:OnAfterBanditDead(groupName)
    MESSAGE:New(
            string.format("A/A PVE Range: bandit down from %s.", groupName),
            10
    ):ToCoalition(coalition.side.BLUE)

    self:RetaskToAssignedCap("Threat neutralized.")

    -- TTS hook example:
    -- "Splash one."
end

function AAPVERange:OnAfterRangeCleared()
    MESSAGE:New("A/A PVE Range cleared.", 10):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Range is cold."
end

function AAPVERange:OnAfterRedAwacsSpawned(redAwacsGroup)
    MESSAGE:New(
            string.format("A/A PVE Range: RED AWACS %s is on station.", redAwacsGroup:GetName()),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Red AWACS is active."
end

function AAPVERange:OnAfterCapScenarioStarted(playerCount)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: CAP hold task active. Hold the CAP and classify tracks with AWACS. Players in zone: %d.",
                    playerCount
            ),
            15
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "You are tasked to hold CAP. Use AWACS to classify contacts."
end

function AAPVERange:OnAfterCapScenarioStopped()
    MESSAGE:New("A/A PVE Range: CAP hold task stopped.", 10):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "CAP task complete. Range is cold."
end

function AAPVERange:OnAfterCapScenarioWaveSpawned(spawnedGroups, playerCount)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: new air picture generated. Groups spawned: %d. Players in zone: %d.",
                    #spawnedGroups,
                    playerCount
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- "Picture update. New groups airborne."
end

function AAPVERange:OnAfterCapScenarioGroupSpawned(spawnedGroup, roleName, aircraftName, flowDescription)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: %s spawned as %s, flow %s.",
                    aircraftName,
                    roleName,
                    flowDescription
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    -- TTS hook example:
    -- You may want to keep this vague for training.
end

function AAPVERange:OnAfterNonThreatRemoved(groupName, reason)
    MESSAGE:New(
            string.format(
                    "A/A PVE Range: non-threat track %s %s.",
                    groupName or "unknown",
                    reason or "left the picture"
            ),
            10
    ):ToCoalition(coalition.side.BLUE)

    self:RetaskToAssignedCap("Track no factor.")

    -- TTS hook example:
    -- "Track faded."
end

---------------------------------------------------------------------------
-- Helpers.
---------------------------------------------------------------------------

function AAPVERange:GetSkillConstant(skillName)
    if skillName == "Average" then
        return "Average"
    end

    if skillName == "Good" then
        return "Good"
    end

    if skillName == "Excellent" then
        return "Excellent"
    end

    if skillName == "Random" then
        return "Random"
    end

    return "High"
end

function AAPVERange:GetSelectedAircraftName()
    if self.SelectedAircraft and self.SelectedAircraft.MenuName then
        return self.SelectedAircraft.MenuName
    end

    return "None"
end

function AAPVERange:GetSelectedEngageRangeNm()
    if self.SelectedAircraft and self.SelectedAircraft.EngageRangeNm then
        return self.SelectedAircraft.EngageRangeNm
    end

    return self.DefaultEngageRangeNm
end

function AAPVERange:GetSelectionSummary()
    return string.format(
            "%s x %s, Skill %s, Engage %d NM",
            self:GetSelectedAircraftName(),
            tostring(self.SelectedCount or "None"),
            tostring(self.SelectedSkill or "None"),
            self:GetSelectedEngageRangeNm()
    )
end

function AAPVERange:HasActiveBandits()
    for _, group in pairs(self.ActiveGroups) do
        if group and group:IsAlive() then
            return true
        end
    end

    return false
end

function AAPVERange:AddActiveGroup(group)
    self.ActiveGroups[#self.ActiveGroups + 1] = group
end

function AAPVERange:AddActiveCapController(capController)
    self.ActiveCapControllers[#self.ActiveCapControllers + 1] = capController
end

function AAPVERange:IsRangeBanditGroup(group)
    if not group then
        return false
    end

    local groupName = group:GetName()

    if not groupName then
        return false
    end

    return string.find(groupName, "AAPVE_Active", 1, true) ~= nil
            or string.find(groupName, "AAPVE_CAPTASK_Hostile", 1, true) ~= nil
end

function AAPVERange:GetClosestClientToGroup(group)
    if not group or not group:IsAlive() then
        return nil, nil
    end

    local groupCoordinate = group:GetCoordinate()

    if not groupCoordinate then
        return nil, nil
    end

    local closestClient = nil
    local closestDistanceMeters = nil

    self.ClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local clientCoordinate = client:GetCoordinate()

            if clientCoordinate then
                local distanceMeters = groupCoordinate:Get2DDistance(clientCoordinate)

                if not closestDistanceMeters or distanceMeters < closestDistanceMeters then
                    closestDistanceMeters = distanceMeters
                    closestClient = client
                end
            end
        end
    end)

    return closestClient, closestDistanceMeters
end

function AAPVERange:ForceEngageClient(group, client)
    if not group or not group:IsAlive() then
        return
    end

    if not client or not client:IsAlive() then
        return
    end

    local targetGroup = client:GetGroup()

    if not targetGroup then
        return
    end

    local task = group:TaskAttackGroup(targetGroup)

    if task then
        group:SetTask(task)
    end
end

function AAPVERange:ResetSelection()
    self.SelectedAircraft = nil
    self.SelectedCount = nil
    self.SelectedSkill = nil
    self.MenuStage = "Aircraft"
    self:BuildMenus()
end

function AAPVERange:HasActiveRedAwacs()
    return self.RedAwacsGroup and self.RedAwacsGroup:IsAlive()
end

function AAPVERange:GetRandomOption(options)
    if not options or #options == 0 then
        return nil
    end

    return options[math.random(1, #options)]
end

function AAPVERange:GetRandomRecoveryZone()
    if not self.RecoveryZones or #self.RecoveryZones == 0 then
        return nil
    end

    return self.RecoveryZones[math.random(1, #self.RecoveryZones)]
end

function AAPVERange:DestroyGroupIfAlive(group)
    if group and group:IsAlive() then
        pcall(function()
            group:Destroy()
        end)
    end
end

function AAPVERange:GetClientsInPlayerZoneCount()
    local count = 0

    self.ClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local clientCoordinate = client:GetCoordinate()

            if clientCoordinate and self.PlayerZone:IsCoordinateInZone(clientCoordinate) then
                count = count + 1
            end
        end
    end)

    return count
end

function AAPVERange:GetActiveScenarioGroupCount()
    local count = 0

    for _, group in pairs(self.ActiveGroups) do
        if group and group:IsAlive() then
            local groupName = group:GetName()

            if groupName and string.find(groupName, "AAPVE_CAPTASK", 1, true) ~= nil then
                count = count + 1
            end
        end
    end

    return count
end

function AAPVERange:GetRandomCapScenarioRole()
    local roll = math.random(1, 100)

    if roll <= self.CapScenarioHostileChance then
        return "Hostile"
    end

    if roll <= self.CapScenarioHostileChance + self.CapScenarioFriendlyChance then
        return "Friendly"
    end

    return "Neutral"
end

function AAPVERange:GetCapScenarioOptionForRole(roleName)
    if roleName == "Hostile" then
        return self:GetRandomOption(self.CapScenarioHostileOptions)
    end

    if roleName == "Friendly" then
        return self:GetRandomOption(self.CapScenarioFriendlyOptions)
    end

    return self:GetRandomOption(self.CapScenarioNeutralOptions)
end

function AAPVERange:SetSafeAircraftOptions(group)
    if not group or not group:IsAlive() then
        return
    end

    pcall(function()
        group:OptionROEHoldFire()
    end)

    pcall(function()
        group:OptionAlarmStateRed()
    end)

    -- Do not use group:OptionReactionOnThreatEvadeFire() here.
    -- It errors in this MOOSE build for this spawned group.
    pcall(function()
        group:OptionROTPassiveDefense()
    end)
end

function AAPVERange:SetCapScenarioAircraftOptions(group, roleName)
    if not group or not group:IsAlive() then
        return
    end

    pcall(function()
        group:OptionAlarmStateRed()
    end)

    -- Start all CAP scenario tracks weapons safe.
    -- Hostiles will only be opened up by the detection monitor once close enough.
    pcall(function()
        group:OptionROEHoldFire()
    end)

    pcall(function()
        group:OptionROTPassiveDefense()
    end)
end

function AAPVERange:StartGroupOrbit(group, zone, altitude, speed)
    if not group or not group:IsAlive() then
        return nil
    end

    if not zone then
        return nil
    end

    local coordinate = zone:GetCoordinate()

    if not coordinate then
        return nil
    end

    local task = nil

    pcall(function()
        task = group:TaskOrbitCircleAtVec2(
                coordinate:GetVec2(),
                altitude,
                speed
        )
    end)

    if task then
        group:SetTask(task)
    end

    return task
end

function AAPVERange:TaskGroupRouteToCoordinate(group, coordinate, altitude, speed)
    if not group or not group:IsAlive() then
        return nil
    end

    if not coordinate then
        return nil
    end

    local task = nil

    pcall(function()
        task = group:TaskRouteToVec2(
                coordinate:GetVec2(),
                speed,
                altitude,
                "BARO"
        )
    end)

    if task then
        group:SetTask(task)
    end

    return task
end

function AAPVERange:GetRandomOffsetCoordinateFromZone(zone, minDistanceNm, maxDistanceNm)
    if not zone then
        return nil
    end

    local baseCoordinate = zone:GetCoordinate()

    if not baseCoordinate then
        return nil
    end

    local heading = math.random(1, 360)
    local distanceMeters = UTILS.NMToMeters(math.random(minDistanceNm, maxDistanceNm))

    return baseCoordinate:Translate(distanceMeters, heading)
end

function AAPVERange:GetCapScenarioDestination(roleName)
    if roleName == "Hostile" then
        local roll = math.random(1, 100)

        if roll <= self.CapScenarioHostileFlowToProtectedChance then
            return self.ProtectedZone:GetCoordinate(), "toward protected area", nil
        end

        local randomHostileDestination = self:GetRandomOffsetCoordinateFromZone(self.RedCapZone, 40, 120)

        return randomHostileDestination, "random hostile route", nil
    end

    local recoverRoll = math.random(1, 100)

    if recoverRoll <= self.CapScenarioNonThreatRecoverChance then
        local recoveryZone = self:GetRandomRecoveryZone()

        if recoveryZone then
            return recoveryZone:GetCoordinate(), "toward recovery", recoveryZone
        end
    end

    local randomDestination = self:GetRandomOffsetCoordinateFromZone(self.RedCapZone, 40, 120)

    return randomDestination, "random non-threat route", nil
end

function AAPVERange:ScheduleNonThreatCleanup(group, recoveryZone)
    if not group or not group:IsAlive() then
        return
    end

    local lifetimeSeconds = math.random(
            self.CapScenarioNonThreatMinLifetimeSeconds,
            self.CapScenarioNonThreatMaxLifetimeSeconds
    )

    local groupName = group:GetName()

    SCHEDULER:New(nil, function()
        if group and group:IsAlive() then
            self:DestroyGroupIfAlive(group)
            self:OnAfterNonThreatRemoved(groupName, "faded from picture")
        end
    end, {}, lifetimeSeconds)

    if not recoveryZone then
        return
    end

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            return
        end

        local groupCoordinate = group:GetCoordinate()
        local recoveryCoordinate = recoveryZone:GetCoordinate()

        if not groupCoordinate or not recoveryCoordinate then
            return
        end

        local distanceNm = UTILS.MetersToNM(groupCoordinate:Get2DDistance(recoveryCoordinate))

        if distanceNm <= self.CapScenarioNonThreatDespawnDistanceNm then
            self:DestroyGroupIfAlive(group)
            self:OnAfterNonThreatRemoved(groupName, "recovered and left the picture")
        end
    end, {}, 30, 30)
end

function AAPVERange:GetRandomCapHold()
    if not self.CapHoldZones or #self.CapHoldZones == 0 then
        return nil
    end

    return self.CapHoldZones[math.random(1, #self.CapHoldZones)]
end

function AAPVERange:GetBullseyeString(coordinate)
    if not coordinate then
        return "bullseye unavailable"
    end

    local bullseyeString = nil

    pcall(function()
        bullseyeString = coordinate:ToStringBULLS(coalition.side.BLUE)
    end)

    if bullseyeString then
        return bullseyeString
    end

    pcall(function()
        bullseyeString = coordinate:ToStringBULLS()
    end)

    if bullseyeString then
        return bullseyeString
    end

    return "bullseye unavailable"
end

function AAPVERange:RemoveAssignedCapMarker()
    if self.AssignedCapMarkerId then
        pcall(function()
            COORDINATE:RemoveMark(self.AssignedCapMarkerId)
        end)

        self.AssignedCapMarkerId = nil
    end
end

function AAPVERange:MarkAssignedCapHold(capHold, bullseyeString)
    if not capHold or not capHold.Zone then
        return
    end

    local coordinate = capHold.Zone:GetCoordinate()

    if not coordinate then
        return
    end

    self:RemoveAssignedCapMarker()

    local markerText = string.format(
            "A/A PVE CAP HOLD\n%s\n%s\nHold CAP here and classify tracks with AWACS.",
            capHold.Name or "Assigned CAP",
            bullseyeString or "Bullseye unavailable"
    )

    pcall(function()
        self.AssignedCapMarkerId = coordinate:MarkToCoalition(
                markerText,
                coalition.side.BLUE,
                true
        )
    end)
end

function AAPVERange:SendCapAssignmentRadio(messageText)
    if not messageText then
        return
    end

    if not MSRS then
        env.info("[AAPVERange] MSRS unavailable. CAP assignment radio call skipped.")
        return
    end

    local msrs = nil

    pcall(function()
        msrs = MSRS:New(
                "",
                self.CapAssignmentFrequency,
                self.CapAssignmentModulation
        )
    end)

    if not msrs then
        env.info("[AAPVERange] Failed to create MSRS object for CAP assignment.")
        return
    end

    pcall(function()
        msrs:SetCoalition(coalition.side.BLUE)
    end)

    pcall(function()
        msrs:SetLabel(self.CapAssignmentLabel or "Magic")
    end)

    pcall(function()
        msrs:SetVolume(1.0)
    end)

    if self.CapAssignmentVoice then
        msrs.voice = self.CapAssignmentVoice
    end

    pcall(function()
        msrs:PlayText(messageText, 0)
    end)
end

function AAPVERange:AssignCapHold()
    local capHold = self:GetRandomCapHold()

    if not capHold or not capHold.Zone then
        MESSAGE:New(
                "A/A PVE Range: no CAP hold zones are configured.",
                10
        ):ToCoalition(coalition.side.BLUE)

        return nil
    end

    local coordinate = capHold.Zone:GetCoordinate()

    if not coordinate then
        MESSAGE:New(
                "A/A PVE Range: selected CAP hold zone has no coordinate.",
                10
        ):ToCoalition(coalition.side.BLUE)

        return nil
    end

    self.AssignedCapHold = capHold

    local bullseyeString = self:GetBullseyeString(coordinate)

    local screenMessage = string.format(
            "A/A PVE CAP ASSIGNMENT\nHold: %s\nPosition: %s\nPush to assigned CAP, sanitize the airspace, and classify contacts with AWACS.",
            capHold.Name or "Assigned CAP",
            bullseyeString
    )

    local radioMessage = string.format(
            "Magic, CAP assignment. Proceed to %s, %s. Hold CAP, sanitize the airspace, and classify all tracks with AWACS.",
            capHold.Name or "assigned CAP",
            bullseyeString
    )

    MESSAGE:New(screenMessage, 30):ToCoalition(coalition.side.BLUE)

    self:MarkAssignedCapHold(capHold, bullseyeString)
    self:SendCapAssignmentRadio(radioMessage)

    return capHold
end

---------------------------------------------------------------------------
-- RED AWACS.
---------------------------------------------------------------------------

function AAPVERange:SpawnRedAwacs()
    if self:HasActiveRedAwacs() then
        return self.RedAwacsGroup
    end

    local redAwacsSpawn = SPAWN:NewWithAlias(self.RedAwacsTemplate, "AAPVE_RedAWACS_Active")
                               :InitSkill("High")
                               :InitRandomizeZones({ self.RedAwacsZone })

    local redAwacsGroup = redAwacsSpawn:Spawn()

    if not redAwacsGroup then
        MESSAGE:New("A/A PVE Range: RED AWACS spawn failed. Check template and zone names.", 10):ToCoalition(coalition.side.BLUE)
        return nil
    end

    self:SetSafeAircraftOptions(redAwacsGroup)

    self.RedAwacsGroup = redAwacsGroup

    local redAwacsOrbitTask = self:StartGroupOrbit(
            redAwacsGroup,
            self.RedAwacsZone,
            self.RedAwacsAltitude,
            self.RedAwacsSpeed
    )

    self.RedAwacsController = redAwacsOrbitTask

    self:OnAfterRedAwacsSpawned(redAwacsGroup)

    return redAwacsGroup
end

function AAPVERange:ClearRedAwacs()
    if self.RedAwacsGroup and self.RedAwacsGroup:IsAlive() then
        pcall(function()
            self.RedAwacsGroup:Destroy()
        end)
    end

    self.RedAwacsController = nil
    self.RedAwacsGroup = nil
end

---------------------------------------------------------------------------
-- Manual spawn / clear.
---------------------------------------------------------------------------

function AAPVERange:SpawnConfigured(aircraftOption, count, skill)
    if self:HasActiveBandits() then
        MESSAGE:New("A/A PVE Range already has active bandits. Clear the range first.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    if not aircraftOption then
        MESSAGE:New("A/A PVE Range: no aircraft option was passed to spawn.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    local aircraftName = aircraftOption.MenuName
    local templateName = aircraftOption.Template
    local skillConstant = self:GetSkillConstant(skill)
    local engageRangeNm = aircraftOption.EngageRangeNm or self.DefaultEngageRangeNm

    self.SelectedAircraft = aircraftOption
    self.SelectedCount = count
    self.SelectedSkill = skill

    local spawn = SPAWN:NewWithAlias(templateName, "AAPVE_Active_" .. aircraftName)
                       :InitLimit(count, 0)
                       :InitGrouping(count)
                       :InitSkill(skillConstant)
                       :InitRandomizeZones({ self.CapZone })

    local spawnedGroup = spawn:Spawn()

    if not spawnedGroup then
        MESSAGE:New("A/A PVE Range: spawn failed. Check template name and late activation setup.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    self:SpawnRedAwacs()

    self:SetSafeAircraftOptions(spawnedGroup)

    spawnedGroup.AAPVEEngageRangeNm = engageRangeNm

    self:AddActiveGroup(spawnedGroup)

    local capOrbitTask = self:StartGroupOrbit(
            spawnedGroup,
            self.CapZone,
            24000,
            450
    )

    self:AddActiveCapController(capOrbitTask)

    self:OnAfterSpawned(spawnedGroup, aircraftName, count, skill, engageRangeNm)
end

function AAPVERange:ClearRange(showMessage)
    -- Orbit and route tasks do not need to be stopped directly.
    -- Destroying the spawned groups clears their tasks.

    self.CapScenarioActive = false

    if self.CapScenarioScheduler then
        pcall(function()
            self.CapScenarioScheduler:Stop()
        end)

        self.CapScenarioScheduler = nil
    end

    self:RemoveAssignedCapMarker()
    self.AssignedCapHold = nil

    for _, group in pairs(self.ActiveGroups) do
        if group and group:IsAlive() then
            pcall(function()
                group:Destroy()
            end)
        end
    end

    self:ClearRedAwacs()

    self.ActiveGroups = {}
    self.ActiveCapControllers = {}
    self.ClientsInZone = {}
    self.DetectedGroups = {}

    self.SelectedAircraft = nil
    self.SelectedCount = nil
    self.SelectedSkill = nil

    if showMessage ~= false then
        self:OnAfterRangeCleared()
    end
end

function AAPVERange:ShowStatus()
    local activeStatus = "No"
    local redAwacsStatus = "No"
    local capScenarioStatus = "No"
    local playersInZone = self:GetClientsInPlayerZoneCount()
    local activeScenarioGroups = self:GetActiveScenarioGroupCount()

    if self:HasActiveBandits() then
        activeStatus = "Yes"
    end

    if self:HasActiveRedAwacs() then
        redAwacsStatus = "Yes"
    end

    if self.CapScenarioActive then
        capScenarioStatus = "Yes"
    end

    MESSAGE:New(
            string.format(
                    "A/A PVE Range Status\nAircraft: %s\nCount: %s\nSkill: %s\nEngage Range: %d NM\nActive Bandits: %s\nRED AWACS Active: %s\nCAP Hold Active: %s\nPlayers In Zone: %d\nScenario Groups: %d",
                    self:GetSelectedAircraftName(),
                    tostring(self.SelectedCount or "None"),
                    tostring(self.SelectedSkill or "None"),
                    self:GetSelectedEngageRangeNm(),
                    activeStatus,
                    redAwacsStatus,
                    capScenarioStatus,
                    playersInZone,
                    activeScenarioGroups
            ),
            15
    ):ToCoalition(coalition.side.BLUE)
end

---------------------------------------------------------------------------
-- CAP Hold Scenario.
---------------------------------------------------------------------------

function AAPVERange:SpawnCapScenarioGroup(roleName)
    local option = self:GetCapScenarioOptionForRole(roleName)

    if not option then
        MESSAGE:New(
                string.format("A/A PVE Range: no aircraft options configured for role %s.", roleName),
                10
        ):ToCoalition(coalition.side.BLUE)
        return nil
    end

    local alias = string.format(
            "AAPVE_CAPTASK_%s_%s",
            roleName,
            option.MenuName:gsub("[^%w]", "")
    )

    local groupSize = 1

    if roleName == "Hostile" then
        groupSize = math.random(1, 2)
    end

    local altitude = math.random(self.CapScenarioMinAltitude, self.CapScenarioMaxAltitude)
    local speed = math.random(self.CapScenarioMinSpeed, self.CapScenarioMaxSpeed)

    local spawn = SPAWN:NewWithAlias(option.Template, alias)
                       :InitLimit(groupSize, 0)
                       :InitGrouping(groupSize)
                       :InitSkill("Random")
                       :InitRandomizeZones({ self.RedCapZone })

    local spawnedGroup = spawn:Spawn()

    if not spawnedGroup then
        MESSAGE:New(
                string.format("A/A PVE Range: CAP scenario spawn failed for template %s.", option.Template),
                10
        ):ToCoalition(coalition.side.BLUE)
        return nil
    end

    self:SetCapScenarioAircraftOptions(spawnedGroup, roleName)

    if roleName == "Hostile" then
        spawnedGroup.AAPVEEngageRangeNm = option.EngageRangeNm or self.DefaultEngageRangeNm
    else
        spawnedGroup.AAPVEEngageRangeNm = 0
    end

    self:AddActiveGroup(spawnedGroup)

    local destinationCoordinate, flowDescription, recoveryZone = self:GetCapScenarioDestination(roleName)
    self:TaskGroupRouteToCoordinate(spawnedGroup, destinationCoordinate, altitude, speed)

    if roleName ~= "Hostile" then
        self:ScheduleNonThreatCleanup(spawnedGroup, recoveryZone)
    end

    self:OnAfterCapScenarioGroupSpawned(spawnedGroup, roleName, option.MenuName, flowDescription)

    return spawnedGroup
end

function AAPVERange:SpawnCapScenarioWave()
    if not self.CapScenarioActive then
        MESSAGE:New("A/A PVE Range: CAP hold task is not active.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    local playerCount = self:GetClientsInPlayerZoneCount()

    if playerCount <= 0 then
        MESSAGE:New(
                "A/A PVE Range: CAP task waiting for players in the CAP/player zone.",
                10
        ):ToCoalition(coalition.side.BLUE)
        return
    end

    local activeScenarioGroups = self:GetActiveScenarioGroupCount()

    if activeScenarioGroups >= self.CapScenarioMaxActiveGroups then
        return
    end

    local desiredGroups = playerCount * self.CapScenarioBaseGroupsPerPlayer

    if desiredGroups > self.CapScenarioMaxGroupsPerWave then
        desiredGroups = self.CapScenarioMaxGroupsPerWave
    end

    local availableSlots = self.CapScenarioMaxActiveGroups - activeScenarioGroups

    if desiredGroups > availableSlots then
        desiredGroups = availableSlots
    end

    local spawnedGroups = {}

    for _ = 1, desiredGroups do
        local roleName = self:GetRandomCapScenarioRole()
        local spawnedGroup = self:SpawnCapScenarioGroup(roleName)

        if spawnedGroup then
            spawnedGroups[#spawnedGroups + 1] = spawnedGroup
        end
    end

    if #spawnedGroups > 0 then
        self:SpawnRedAwacs()
        self:OnAfterCapScenarioWaveSpawned(spawnedGroups, playerCount)
    end
end

function AAPVERange:StartCapScenario()
    if self.CapScenarioActive then
        MESSAGE:New("A/A PVE Range: CAP hold task is already active.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    self.CapScenarioActive = true

    local playerCount = self:GetClientsInPlayerZoneCount()

    self:SpawnRedAwacs()
    self:AssignCapHold()
    self:OnAfterCapScenarioStarted(playerCount)

    self.CapScenarioScheduler = SCHEDULER:New(nil, function()
        AAPVERange:SpawnCapScenarioWave()
    end, {}, self.CapScenarioInitialDelaySeconds, self.CapScenarioIntervalSeconds)
end

function AAPVERange:StopCapScenario()
    if not self.CapScenarioActive then
        MESSAGE:New("A/A PVE Range: CAP hold task is not active.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    self.CapScenarioActive = false

    if self.CapScenarioScheduler then
        pcall(function()
            self.CapScenarioScheduler:Stop()
        end)

        self.CapScenarioScheduler = nil
    end

    self:OnAfterCapScenarioStopped()
end

function AAPVERange:RetaskToAssignedCap(reason)
    if not self.AssignedCapHold or not self.AssignedCapHold.Zone then
        return
    end

    local coordinate = self.AssignedCapHold.Zone:GetCoordinate()
    local bullseyeString = self:GetBullseyeString(coordinate)

    local screenMessage = string.format(
            "A/A PVE Range\n%s\nResume assigned CAP: %s\nPosition: %s",
            reason or "Contact resolved.",
            self.AssignedCapHold.Name or "Assigned CAP",
            bullseyeString
    )

    local radioMessage = string.format(
            "Magic, %s Resume %s, %s.",
            reason or "contact resolved.",
            self.AssignedCapHold.Name or "assigned CAP",
            bullseyeString
    )

    MESSAGE:New(screenMessage, 25):ToCoalition(coalition.side.BLUE)
    self:SendCapAssignmentRadio(radioMessage)
    self:MarkAssignedCapHold(self.AssignedCapHold, bullseyeString)
end

---------------------------------------------------------------------------
-- Menu helpers.
---------------------------------------------------------------------------

function AAPVERange:AddMenuItem(menuItem)
    if menuItem then
        self.MenuCommands[#self.MenuCommands + 1] = menuItem
    end

    return menuItem
end

function AAPVERange:BuildMenus()
    env.info("[AAPVERange] Building A/A PVE Range menus.")

    if not self.MenuRoot then
        env.info("[AAPVERange] ERROR: MenuRoot is nil. Cannot build menus.")
        return
    end

    if not self.AircraftOptions then
        env.info("[AAPVERange] ERROR: AircraftOptions is nil. Cannot build menus.")
        return
    end

    if not self.CountOptions then
        env.info("[AAPVERange] ERROR: CountOptions is nil. Cannot build menus.")
        return
    end

    if not self.SkillOptions then
        env.info("[AAPVERange] ERROR: SkillOptions is nil. Cannot build menus.")
        return
    end

    self.SpawnMenu = self:AddMenuItem(
            MENU_COALITION:New(
                    coalition.side.BLUE,
                    "Spawn RED CAP",
                    self.MenuRoot
            )
    )

    if not self.SpawnMenu then
        env.info("[AAPVERange] ERROR: SpawnMenu failed to create.")
        return
    end

    for _, aircraftOption in ipairs(self.AircraftOptions) do
        local selectedAircraftOption = aircraftOption

        if selectedAircraftOption and selectedAircraftOption.MenuName and selectedAircraftOption.Template then
            local aircraftMenuName = string.format(
                    "%s - %d NM",
                    selectedAircraftOption.MenuName,
                    selectedAircraftOption.EngageRangeNm or self.DefaultEngageRangeNm
            )

            env.info("[AAPVERange] Creating aircraft menu: " .. aircraftMenuName)

            local aircraftMenu = self:AddMenuItem(
                    MENU_COALITION:New(
                            coalition.side.BLUE,
                            aircraftMenuName,
                            self.SpawnMenu
                    )
            )

            for _, count in ipairs(self.CountOptions) do
                local selectedCount = count

                local countMenu = self:AddMenuItem(
                        MENU_COALITION:New(
                                coalition.side.BLUE,
                                tostring(selectedCount) .. " Aircraft",
                                aircraftMenu
                        )
                )

                for _, skill in ipairs(self.SkillOptions) do
                    local selectedSkill = skill

                    self:AddMenuItem(
                            MENU_COALITION_COMMAND:New(
                                    coalition.side.BLUE,
                                    string.format(
                                            "Spawn %s x%d %s",
                                            selectedAircraftOption.MenuName,
                                            selectedCount,
                                            selectedSkill
                                    ),
                                    countMenu,
                                    function()
                                        AAPVERange:SpawnConfigured(selectedAircraftOption, selectedCount, selectedSkill)
                                    end
                            )
                    )
                end
            end
        else
            env.info("[AAPVERange] WARNING: Skipped invalid aircraft option.")
        end
    end

    local capHoldMenu = self:AddMenuItem(
            MENU_COALITION:New(
                    coalition.side.BLUE,
                    "CAP Hold Scenario",
                    self.MenuRoot
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Start CAP Hold Task",
                    capHoldMenu,
                    function()
                        AAPVERange:StartCapScenario()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Spawn CAP Picture Now",
                    capHoldMenu,
                    function()
                        AAPVERange:SpawnCapScenarioWave()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Stop CAP Hold Task",
                    capHoldMenu,
                    function()
                        AAPVERange:StopCapScenario()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Clear Range",
                    self.MenuRoot,
                    function()
                        AAPVERange:ClearRange(true)
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Show Status",
                    self.MenuRoot,
                    function()
                        AAPVERange:ShowStatus()
                    end
            )
    )
    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Re-send CAP Assignment",
                    capHoldMenu,
                    function()
                        if AAPVERange.AssignedCapHold then
                            local coordinate = AAPVERange.AssignedCapHold.Zone:GetCoordinate()
                            local bullseyeString = AAPVERange:GetBullseyeString(coordinate)

                            local screenMessage = string.format(
                                    "A/A PVE CAP ASSIGNMENT\nHold: %s\nPosition: %s\nPush to assigned CAP, sanitize the airspace, and classify contacts with AWACS.",
                                    AAPVERange.AssignedCapHold.Name or "Assigned CAP",
                                    bullseyeString
                            )

                            local radioMessage = string.format(
                                    "Magic, CAP assignment reminder. Proceed to %s, %s. Hold CAP and classify all tracks with AWACS.",
                                    AAPVERange.AssignedCapHold.Name or "assigned CAP",
                                    bullseyeString
                            )

                            MESSAGE:New(screenMessage, 30):ToCoalition(coalition.side.BLUE)
                            AAPVERange:MarkAssignedCapHold(AAPVERange.AssignedCapHold, bullseyeString)
                            AAPVERange:SendCapAssignmentRadio(radioMessage)
                        else
                            AAPVERange:AssignCapHold()
                        end
                    end
            )
    )



    env.info("[AAPVERange] Finished building A/A PVE Range menus.")
end

---------------------------------------------------------------------------
-- Menu callbacks.
---------------------------------------------------------------------------

function AAPVERange:SetAircraft(aircraftOption)
    self.SelectedAircraft = aircraftOption
    self.SelectedCount = nil
    self.SelectedSkill = nil
    self.MenuStage = "Count"

    MESSAGE:New(
            string.format("A/A PVE Range aircraft selected: %s.", aircraftOption.MenuName),
            10
    ):ToCoalition(coalition.side.BLUE)

    self:BuildMenus()
end

function AAPVERange:SetCount(count)
    self.SelectedCount = count
    self.SelectedSkill = nil
    self.MenuStage = "Skill"

    MESSAGE:New(
            string.format("A/A PVE Range aircraft count selected: %d.", count),
            10
    ):ToCoalition(coalition.side.BLUE)

    self:BuildMenus()
end

function AAPVERange:SetSkill(skill)
    self.SelectedSkill = skill
    self.MenuStage = "Ready"

    MESSAGE:New(
            string.format("A/A PVE Range skill selected: %s.", skill),
            10
    ):ToCoalition(coalition.side.BLUE)

    self:BuildMenus()
end

function AAPVERange:SpawnSelected()
    if not self.SelectedAircraft then
        MESSAGE:New("A/A PVE Range: no aircraft selected.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    if not self.SelectedCount then
        MESSAGE:New("A/A PVE Range: no aircraft count selected.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    if not self.SelectedSkill then
        MESSAGE:New("A/A PVE Range: no skill selected.", 10):ToCoalition(coalition.side.BLUE)
        return
    end

    self:SpawnConfigured(self.SelectedAircraft, self.SelectedCount, self.SelectedSkill)
end

---------------------------------------------------------------------------
-- Schedulers.
---------------------------------------------------------------------------

function AAPVERange:StartClientZoneMonitor()
    self.ClientZoneScheduler = SCHEDULER:New(nil, function()
        self.ClientSet:ForEachClient(function(client)
            if client and client:IsAlive() then
                local clientName = client:GetName()
                local clientCoordinate = client:GetCoordinate()

                if clientName and clientCoordinate then
                    local isInZone = self.PlayerZone:IsCoordinateInZone(clientCoordinate)
                    local wasInZone = self.ClientsInZone[clientName] == true

                    if isInZone and not wasInZone then
                        self.ClientsInZone[clientName] = true
                        self:OnAfterClientInZone(client)
                    elseif not isInZone and wasInZone then
                        self.ClientsInZone[clientName] = nil
                        self:OnAfterClientOutOfZone(client)
                    end
                end
            end
        end)
    end, {}, 5, self.ClientZoneCheckSeconds)
end

function AAPVERange:StartDetectionMonitor()
    self.DetectionScheduler = SCHEDULER:New(nil, function()
        if not self:HasActiveRedAwacs() then
            return
        end

        for _, group in pairs(self.ActiveGroups) do
            if group and group:IsAlive() then
                local closestClient, distanceMeters = self:GetClosestClientToGroup(group)

                if closestClient and distanceMeters then
                    local distanceNm = UTILS.MetersToNM(distanceMeters)
                    local engageRangeNm = group.AAPVEEngageRangeNm or self.DefaultEngageRangeNm

                    if engageRangeNm > 0 and distanceNm <= engageRangeNm then
                        group:OptionROEOpenFire()
                        self:ForceEngageClient(group, closestClient)

                        local groupName = group:GetName()

                        if groupName and not self.DetectedGroups[groupName] then
                            self.DetectedGroups[groupName] = true
                            self:OnAfterBanditDetected(group, closestClient, distanceNm)
                        end
                    end
                end
            end
        end
    end, {}, 10, self.DetectionCheckSeconds)
end

---------------------------------------------------------------------------
-- Event handling.
---------------------------------------------------------------------------

function AAPVERange.EventHandler:OnEventShot(EventData)
    if not EventData then
        return
    end

    local shooterUnit = EventData.IniUnit
    local weapon = EventData.Weapon
    local targetUnit = EventData.TgtUnit

    if not shooterUnit then
        return
    end

    local shooterGroup = shooterUnit:GetGroup()

    if not AAPVERange:IsRangeBanditGroup(shooterGroup) then
        return
    end

    local weaponName = nil

    if weapon then
        weaponName = weapon:GetTypeName()
    end

    AAPVERange:OnAfterMissileFired(shooterUnit, weaponName, targetUnit)
end

function AAPVERange.EventHandler:OnEventDead(EventData)
    AAPVERange:HandlePossibleBanditDeath(EventData)
end

function AAPVERange.EventHandler:OnEventCrash(EventData)
    AAPVERange:HandlePossibleBanditDeath(EventData)
end

function AAPVERange.EventHandler:OnEventPilotDead(EventData)
    AAPVERange:HandlePossibleBanditDeath(EventData)
end

function AAPVERange:HandlePossibleBanditDeath(EventData)
    if not EventData then
        return
    end

    local unit = EventData.IniUnit

    if not unit then
        return
    end

    local group = unit:GetGroup()

    if not self:IsRangeBanditGroup(group) then
        return
    end

    self:OnAfterBanditDead(group:GetName())
end

---------------------------------------------------------------------------
-- Start.
---------------------------------------------------------------------------

function AAPVERange:Start()
    self.SelectedAircraft = nil
    self.SelectedCount = nil
    self.SelectedSkill = nil

    self:BuildMenus()
    self:StartClientZoneMonitor()
    self:StartDetectionMonitor()

    MESSAGE:New("A/A PVE Range initialized.", 10):ToCoalition(coalition.side.BLUE)
end

AAPVERange:Start()