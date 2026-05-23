----------------------------------------------------------------------------
---- A/A PVE Range - MOOSE FSM / CAP Package Version
----
---- Requires:
----   MOOSE loaded before this file.
----
---- Major features:
----   1. RED CAP Target Practice mode.
----   2. BLUE CAP Defense mode with randomized air picture.
----   3. Flight-lead CAP Check-in.
----   4. Script-defined flight packages using clients within 0.5 NM of lead.
----   5. Multiple simultaneous CAP packages.
----   6. Large sandbox zone for cleanup logic.
----   7. Multiple RED / picture spawn zones.
----   8. Commit detection when package leaves CAP toward hostile.
----   9. Retask back to CAP after hostile neutralized.
----   10. Picture resumes only after package returns to CAP.
----   11. FOX Missile Trainer toggle.
-----------------------------------------------------------------------------
--
--if AAPVE_MOOSE and AAPVE_MOOSE.Stop then
--pcall(function()
--AAPVE_MOOSE:Stop()
--end)
--end
--
--AAPVE_MOOSE = {}
--
-----------------------------------------------------------------------------
---- Basic configuration.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.Debug = true
--
--AAPVE_MOOSE.MenuRoot = MENU_COALITION:New(coalition.side.BLUE, "A/A RANGE SETUP")
--AAPVE_MOOSE.MenuCommands = {}
--
--AAPVE_MOOSE.CurrentMode = "Idle"
--
-----------------------------------------------------------------------------
---- Mission zones.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.BlueCapZones = {
--{
--Name = "CAP HOLD 1",
--Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_1")
--},
--{
--Name = "CAP HOLD 2",
--Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_2")
--},
--{
--Name = "CAP HOLD 3",
--Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_3")
--}
--}
--
--AAPVE_MOOSE.RedCapZone = ZONE:New("AAPVE_RED_CAP_ZONE")
--AAPVE_MOOSE.ProtectedZone = ZONE:New("AAPVE_PROTECTED_ZONE")
--AAPVE_MOOSE.SandboxZone = ZONE:New("AAPVE_SANDBOX_ZONE")
--
---- Multiple RED / picture spawn zones.
--AAPVE_MOOSE.RedSpawnZones = {
--ZONE:New("AAPVE_RED_SPAWN_ZONE_1"),
--ZONE:New("AAPVE_RED_SPAWN_ZONE_2"),
--ZONE:New("AAPVE_RED_SPAWN_ZONE_3")
--}
--
--AAPVE_MOOSE.RecoveryZones = {
--ZONE:New("AAPVE_RECOVERY_ZONE_1"),
--ZONE:New("AAPVE_RECOVERY_ZONE_2"),
--ZONE:New("AAPVE_RECOVERY_ZONE_3")
--}
--
-----------------------------------------------------------------------------
---- Sets.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.BlueClientSet = SET_CLIENT:New()
--:FilterCoalitions("blue")
--:FilterActive()
--:FilterStart()
--
--AAPVE_MOOSE.BlueDetectionSet = SET_GROUP:New()
--:FilterCoalitions("blue")
--:FilterPrefixes({ "EW", "AWACS", "EWR" })
--:FilterStart()
--
--AAPVE_MOOSE.RedDetectionSet = SET_GROUP:New()
--:FilterCoalitions("red")
--:FilterPrefixes({ "REDAWACS", "REDEWR" })
--:FilterStart()
--
-----------------------------------------------------------------------------
---- Runtime state.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.ActiveGroups = {}
--
--AAPVE_MOOSE.CapPackages = {}
--AAPVE_MOOSE.NextCapPackageId = 1
--
--AAPVE_MOOSE.ClientGroupMenus = {}
--
--AAPVE_MOOSE.BlueChief = nil
--AAPVE_MOOSE.RedDispatcher = nil
--
--AAPVE_MOOSE.CapPackageMonitorScheduler = nil
--AAPVE_MOOSE.CapPackagePictureScheduler = nil
--
--AAPVE_MOOSE.FoxTrainer = nil
--AAPVE_MOOSE.FoxTrainerEnabled = false
--
-----------------------------------------------------------------------------
---- CAP package / picture configuration.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.CapCheckInRadiusNm = 0.5
--AAPVE_MOOSE.MaxCapPackages = 3
--
--AAPVE_MOOSE.CapPackageMonitorSeconds = 10
--AAPVE_MOOSE.CapPackagePictureIntervalSeconds = 120
--AAPVE_MOOSE.CapPackageEmptyCleanupSeconds = 300
--
---- If true, no package can spawn a hostile if global active hostile count
---- is already at MaxGlobalHostileGroups.
--AAPVE_MOOSE.UseGlobalHostileLimit = false
--AAPVE_MOOSE.MaxGlobalHostileGroups = 2
--
--AAPVE_MOOSE.PictureHostileChance = 55
--AAPVE_MOOSE.PictureNeutralChance = 25
--AAPVE_MOOSE.PictureFriendlyChance = 20
--
--AAPVE_MOOSE.NonHostileMinLifetimeSeconds = 300
--AAPVE_MOOSE.NonHostileMaxLifetimeSeconds = 900
--
--AAPVE_MOOSE.PictureMinAltitude = 12000
--AAPVE_MOOSE.PictureMaxAltitude = 32000
--AAPVE_MOOSE.PictureMinSpeed = 320
--AAPVE_MOOSE.PictureMaxSpeed = 500
--
---- Commit logic.
--AAPVE_MOOSE.CommitCheckDistanceFromCapNm = 5
--AAPVE_MOOSE.CommitHeadingToleranceDegrees = 70
--
-----------------------------------------------------------------------------
---- Timeline spawn configuration.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.TimelineSpawnOptions = {
--    BVR = {
--        Label = "BVR",
--        DistanceNm = 80,
--        AltitudeOffsetFeet = 0,
--        Speed = 500,
--        RoeAtSpawn = "OpenFire",
--        OpenFireAfterMerge = false
--    },
--    WVR = {
--        Label = "WVR",
--        DistanceNm = 20,
--        AltitudeOffsetFeet = 0,
--        Speed = 450,
--        RoeAtSpawn = "OpenFire",
--        OpenFireAfterMerge = false
--    },
--    BFM = {
--        Label = "BFM",
--        DistanceNm = 5,
--        AltitudeOffsetFeet = 0,
--        Speed = 420,
--        RoeAtSpawn = "HoldFire",
--        OpenFireAfterMerge = true,
--        MergeDistanceNm = 1.0
--    }
--}
--
--AAPVE_MOOSE.TimelineDefaultTemplate = "AAPVE_RED_MIG29"
--AAPVE_MOOSE.TimelineDefaultGroupSize = 1
--
-----------------------------------------------------------------------------
---- TTS configuration.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.TTSFrequency = 262
--AAPVE_MOOSE.TTSModulation = radio.modulation.AM
--AAPVE_MOOSE.TTSLabel = "Magic"
--AAPVE_MOOSE.TTSVoice = "Nathan"
--AAPVE_MOOSE.TTSSpeed = 200
--AAPVE_MOOSE.TTSVolume = 0.6
--
-----------------------------------------------------------------------------
---- Aircraft templates.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.RedCapTemplates = {
--{
--Name = "MiG-29",
--Template = "AAPVE_RED_MIG29"
--},
--{
--Name = "Su-27",
--Template = "AAPVE_RED_SU27"
--},
--{
--Name = "F-16",
--Template = "AAPVE_RED_F16"
--},
--{
--Name = "F-14",
--Template = "AAPVE_RED_F14"
--},
--{
--Name = "F-5",
--Template = "AAPVE_RED_F5"
--}
--}
--
--AAPVE_MOOSE.PictureHostileTemplates = {
--{
--Name = "MiG-29",
--Template = "AAPVE_RED_MIG29"
--},
--{
--Name = "Su-27",
--Template = "AAPVE_RED_SU27"
--},
--{
--Name = "F-16",
--Template = "AAPVE_RED_F16"
--},
--{
--Name = "F-14",
--Template = "AAPVE_RED_F14"
--},
--{
--Name = "F-5",
--Template = "AAPVE_RED_F5"
--}
--}
--
--AAPVE_MOOSE.PictureFriendlyTemplates = {
--{
--Name = "Friendly F/A-18",
--Template = "AAPVE_FRIENDLY_F18"
--},
--{
--Name = "Friendly F-16",
--Template = "AAPVE_FRIENDLY_F16"
--},
--{
--Name = "Friendly F-14",
--Template = "AAPVE_FRIENDLY_F14"
--}
--}
--
--AAPVE_MOOSE.PictureNeutralTemplates = {
--{
--Name = "Neutral L-39",
--Template = "AAPVE_NEUTRAL_L39"
--},
--{
--Name = "Neutral C-101",
--Template = "AAPVE_NEUTRAL_C101"
--},
--{
--Name = "Neutral FW-190",
--Template = "AAPVE_NEUTRAL_FW190"
--}
--}
--
-----------------------------------------------------------------------------
---- Basic helpers.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:Log(message)
--if self.Debug then
--env.info("[AAPVE_MOOSE] " .. tostring(message))
--end
--end
--
--function AAPVE_MOOSE:BlueMessage(message, seconds)
--MESSAGE:New(message, seconds or 10):ToCoalition(coalition.side.BLUE)
--end
--
--function AAPVE_MOOSE:AddMenuItem(menuItem)
--if menuItem then
--self.MenuCommands[#self.MenuCommands + 1] = menuItem
--end
--
--return menuItem
--end
--
--function AAPVE_MOOSE:GetRandomOption(options)
--if not options or #options == 0 then
--return nil
--end
--
--return options[math.random(1, #options)]
--end
--
--function AAPVE_MOOSE:GetRandomRedSpawnZone()
--return self:GetRandomOption(self.RedSpawnZones)
--end
--
--function AAPVE_MOOSE:GetRandomRecoveryZone()
--return self:GetRandomOption(self.RecoveryZones)
--end
--
--function AAPVE_MOOSE:AddActiveGroup(group)
--if group then
--self.ActiveGroups[#self.ActiveGroups + 1] = group
--end
--end
--
--function AAPVE_MOOSE:DestroyGroup(group)
--if group and group:IsAlive() then
--pcall(function()
--group:Destroy()
--end)
--end
--end
--
--function AAPVE_MOOSE:GetSanitizedName(name)
--if not name then
--return "Unknown"
--end
--
--return tostring(name):gsub("[^%w]", "")
--end
--
--function AAPVE_MOOSE:GetClientUnitName(client)
--if not client then
--return nil
--end
--
--return client:GetName()
--end
--
--function AAPVE_MOOSE:GetClientDisplayName(client)
--if not client then
--return "Unknown"
--end
--
--return client:GetPlayerName() or client:GetName() or "Unknown"
--end
--
--function AAPVE_MOOSE:GetBullseyeText(coordinate)
--if not coordinate then
--return "bullseye unavailable"
--end
--
--local text = nil
--
--pcall(function()
--text = coordinate:ToStringBULLS(coalition.side.BLUE)
--end)
--
--if text then
--return text
--end
--
--pcall(function()
--text = coordinate:ToStringBULLS()
--end)
--
--return text or "bullseye unavailable"
--end
--
--function AAPVE_MOOSE:SendTTS(messageText)
--if not messageText or messageText == "" then
--return
--end
--
--if not MSRS then
--self:Log("MSRS unavailable. TTS skipped: " .. tostring(messageText))
--return
--end
--
--local msrs = nil
--
--pcall(function()
--msrs = MSRS:New(
--SRS_PATH or "",
--self.TTSFrequency,
--self.TTSModulation
--)
--end)
--
--if not msrs then
--self:Log("Failed to create MSRS object.")
--return
--end
--
--pcall(function()
--msrs:SetCoalition(coalition.side.BLUE)
--end)
--
--pcall(function()
--msrs:SetLabel(self.TTSLabel or "Magic")
--end)
--
--pcall(function()
--msrs:SetVolume(self.TTSVolume or 0.6)
--end)
--
--msrs.voice = self.TTSVoice or "Nathan"
--msrs.speed = self.TTSSpeed or 200
--
--pcall(function()
--msrs:PlayText(messageText, 0)
--end)
--end
--
-----------------------------------------------------------------------------
---- Geometry helpers.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:GetBearingDegrees(fromCoordinate, toCoordinate)
--if not fromCoordinate or not toCoordinate then
--return nil
--end
--
--local fromVec2 = fromCoordinate:GetVec2()
--local toVec2 = toCoordinate:GetVec2()
--
--if not fromVec2 or not toVec2 then
--return nil
--end
--
--local dx = toVec2.x - fromVec2.x
--local dy = toVec2.y - fromVec2.y
--
--local bearing = math.deg(math.atan2(dx, dy))
--
--if bearing < 0 then
--bearing = bearing + 360
--end
--
--return bearing
--end
--
--function AAPVE_MOOSE:GetHeadingDifferenceDegrees(headingA, headingB)
--if not headingA or not headingB then
--return 180
--end
--
--local diff = math.abs(headingA - headingB)
--
--if diff > 180 then
--diff = 360 - diff
--end
--
--return diff
--end
--
--function AAPVE_MOOSE:GetClientHeadingDegrees(client)
--    if not client then
--        return 0
--    end
--
--    local heading = nil
--
--    pcall(function()
--        heading = client:GetHeading()
--    end)
--
--    if heading then
--        return heading
--    end
--
--    local unit = client:GetDCSObject()
--
--    if unit and unit.getPosition then
--        local position = unit:getPosition()
--
--        if position and position.x then
--            local rawHeading = math.deg(math.atan2(position.x.z, position.x.x))
--
--            if rawHeading < 0 then
--                rawHeading = rawHeading + 360
--            end
--
--            return rawHeading
--        end
--    end
--
--    return 0
--end
--
--function AAPVE_MOOSE:GetTimelineBanditTemplate()
--    local option = self:GetRandomOption(self.RedCapTemplates)
--
--    if option and option.Template then
--        return option.Template, option.Name
--    end
--
--    return self.TimelineDefaultTemplate, self.TimelineDefaultTemplate
--end
--
--function AAPVE_MOOSE:SpawnTimelineBanditForClient(client, timelineName)
--    if not client or not client:IsAlive() then
--        self:BlueMessage("A/A PVE Range: timeline spawn failed. Client is not alive.", 10)
--        return
--    end
--
--    local timeline = self.TimelineSpawnOptions[timelineName]
--
--    if not timeline then
--        self:BlueMessage("A/A PVE Range: invalid timeline selection.", 10)
--        return
--    end
--
--    local clientCoord = client:GetCoordinate()
--
--    if not clientCoord then
--        self:BlueMessage("A/A PVE Range: timeline spawn failed. No client coordinate.", 10)
--        return
--    end
--
--    local clientHeading = self:GetClientHeadingDegrees(client)
--    local spawnBearingFromClient = clientHeading
--    local distanceMeters = UTILS.NMToMeters(timeline.DistanceNm)
--
--    -- Spawn bandit in front of the client, so it is hot nose-to-nose.
--    local spawnCoord = clientCoord:Translate(distanceMeters, spawnBearingFromClient)
--
--    if timeline.AltitudeOffsetFeet and timeline.AltitudeOffsetFeet ~= 0 then
--        local clientAltitude = clientCoord.y or 0
--        spawnCoord.y = clientAltitude + UTILS.FeetToMeters(timeline.AltitudeOffsetFeet)
--    end
--
--    local templateName, aircraftName = self:GetTimelineBanditTemplate()
--
--    local alias = string.format(
--            "AAPVE_TIMELINE_%s_%s",
--            timelineName,
--            self:GetSanitizedName(aircraftName)
--    )
--
--    local spawn = SPAWN:NewWithAlias(templateName, alias)
--                       :InitGrouping(self.TimelineDefaultGroupSize)
--                       :InitSkill("Random")
--
--    -- Face the bandit toward the client if this MOOSE build supports InitHeading.
--    pcall(function()
--        spawn:InitHeading((clientHeading + 180) % 360)
--    end)
--
--    local group = nil
--
--    pcall(function()
--        group = spawn:SpawnFromCoordinate(spawnCoord)
--    end)
--
--    if not group then
--        self:BlueMessage(
--                string.format(
--                        "A/A PVE Range: %s timeline spawn failed. Check template %s.",
--                        timeline.Label,
--                        templateName
--                ),
--                10
--        )
--        return
--    end
--
--    self:AddActiveGroup(group)
--
--    group.AAPVETimelineMode = timelineName
--    group.AAPVEAssignedClientName = client:GetName()
--
--    pcall(function()
--        group:OptionAlarmStateRed()
--    end)
--
--    if timeline.RoeAtSpawn == "HoldFire" then
--        pcall(function()
--            group:OptionROEHoldFire()
--        end)
--    else
--        pcall(function()
--            group:OptionROEOpenFire()
--        end)
--    end
--
--    -- Delay tasking slightly because the spawned group may not be fully alive
--    -- at the exact same tick SpawnFromCoordinate returns.
--    SCHEDULER:New(nil, function()
--        if not group or not group:IsAlive() then
--            return
--        end
--
--        local freshClient = CLIENT:FindByName(client:GetName())
--
--        if not freshClient or not freshClient:IsAlive() then
--            return
--        end
--
--        local targetGroup = freshClient:GetGroup()
--
--        if targetGroup then
--            local attackTask = group:TaskAttackGroup(targetGroup)
--
--            if attackTask then
--                group:SetTask(attackTask)
--            end
--        end
--    end, {}, 2)
--
--    if timeline.OpenFireAfterMerge then
--        self:StartBFMMergeMonitor(group, client:GetName(), timeline.MergeDistanceNm or 1.0)
--    end
--
--    self:BlueMessage(
--            string.format(
--                    "A/A PVE Range: %s timeline spawned %s at %d NM, hot.",
--                    timeline.Label,
--                    aircraftName,
--                    timeline.DistanceNm
--            ),
--            10
--    )
--
--    self:SendTTS(
--            string.format(
--                    "Magic, %s timeline set. Bandit spawned %d miles hot.",
--                    timeline.Label,
--                    timeline.DistanceNm
--            )
--    )
--end
--
--function AAPVE_MOOSE:StartBFMMergeMonitor(group, clientUnitName, mergeDistanceNm)
--    if not group or not clientUnitName then
--        return
--    end
--
--    local scheduler = nil
--
--    scheduler = SCHEDULER:New(nil, function()
--        if not group or not group:IsAlive() then
--            if scheduler then
--                scheduler:Stop()
--            end
--            return
--        end
--
--        local client = CLIENT:FindByName(clientUnitName)
--
--        if not client or not client:IsAlive() then
--            if scheduler then
--                scheduler:Stop()
--            end
--            return
--        end
--
--        local groupCoord = group:GetCoordinate()
--        local clientCoord = client:GetCoordinate()
--
--        if not groupCoord or not clientCoord then
--            return
--        end
--
--        local distanceNm = UTILS.MetersToNM(groupCoord:Get2DDistance(clientCoord))
--
--        if distanceNm <= mergeDistanceNm then
--            pcall(function()
--                group:OptionROEOpenFire()
--            end)
--
--            self:BlueMessage("A/A PVE Range: BFM merge detected. RED weapons free.", 10)
--            self:SendTTS("Fight's on. Red weapons free.")
--
--            if scheduler then
--                scheduler:Stop()
--            end
--        end
--    end, {}, 2, 2)
--end
--
-----------------------------------------------------------------------------
---- FSM.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.FSM = FSM:New()
--AAPVE_MOOSE.FSM:SetStartState("Stopped")
--
--AAPVE_MOOSE.FSM:AddTransition("Stopped", "Start", "Idle")
--AAPVE_MOOSE.FSM:AddTransition("Idle", "StartRedCap", "RedCapPractice")
--AAPVE_MOOSE.FSM:AddTransition("Idle", "StartBlueCap", "BlueCapDefense")
--AAPVE_MOOSE.FSM:AddTransition("RedCapPractice", "StopMode", "Idle")
--AAPVE_MOOSE.FSM:AddTransition("BlueCapDefense", "StopMode", "Idle")
--AAPVE_MOOSE.FSM:AddTransition("*", "Shutdown", "Stopped")
--
--function AAPVE_MOOSE.FSM:OnAfterStart(From, Event, To)
--AAPVE_MOOSE.CurrentMode = "Idle"
--AAPVE_MOOSE:BlueMessage("A/A PVE Range is online.", 10)
--end
--
--function AAPVE_MOOSE.FSM:OnAfterStartRedCap(From, Event, To)
--AAPVE_MOOSE.CurrentMode = "RedCapPractice"
--AAPVE_MOOSE:StartRedCapPracticeMode()
--end
--
--function AAPVE_MOOSE.FSM:OnAfterStartBlueCap(From, Event, To)
--AAPVE_MOOSE.CurrentMode = "BlueCapDefense"
--AAPVE_MOOSE:StartBlueCapDefenseMode()
--end
--
--function AAPVE_MOOSE.FSM:OnAfterStopMode(From, Event, To)
--AAPVE_MOOSE.CurrentMode = "Idle"
--AAPVE_MOOSE:ClearRange()
--AAPVE_MOOSE:BlueMessage("A/A PVE Range returned to idle.", 10)
--end
--
--function AAPVE_MOOSE.FSM:OnAfterShutdown(From, Event, To)
--AAPVE_MOOSE.CurrentMode = "Stopped"
--AAPVE_MOOSE:ClearRange(false)
--end
--
-----------------------------------------------------------------------------
---- CHIEF / Dispatcher.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:StartBlueChief()
--if self.BlueChief then
--return
--end
--
--self.BlueChief = CHIEF:New(coalition.side.BLUE, self.BlueDetectionSet, "AAPVE Blue Chief")
--self.BlueChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)
--
--if self.ProtectedZone then
--self.BlueChief:AddBorderZone(self.ProtectedZone)
--end
--
--self.BlueChief:Start()
--self:BlueMessage("A/A PVE Range: BLUE CHIEF active.", 10)
--end
--
--function AAPVE_MOOSE:StopBlueChief()
--if self.BlueChief then
--pcall(function()
--self.BlueChief:Stop()
--end)
--
--self.BlueChief = nil
--end
--end
--
--function AAPVE_MOOSE:StartRedDispatcher()
--    -- Removed. RED CAP is handled by manual RED CAP spawn and timeline spawns.
--    self:Log("RED dispatcher disabled. Using manual RED CAP / timeline spawns only.")
--end
--
--function AAPVE_MOOSE:StopRedDispatcher()
--    self.RedDispatcher = nil
--end
--
-----------------------------------------------------------------------------
---- FOX Missile Trainer.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:SetFoxTrainerEnabled(enabled)
--self.FoxTrainerEnabled = enabled == true
--
--if self.FoxTrainerEnabled then
--self:StartFoxTrainer()
--self:BlueMessage("A/A PVE Range: FOX Missile Trainer enabled.", 10)
--else
--self:StopFoxTrainer()
--self:BlueMessage("A/A PVE Range: FOX Missile Trainer disabled.", 10)
--end
--end
--
--function AAPVE_MOOSE:ToggleFoxTrainer()
--self:SetFoxTrainerEnabled(not self.FoxTrainerEnabled)
--end
--
--function AAPVE_MOOSE:StartFoxTrainer()
--if self.FoxTrainer then
--return
--end
--
--if not FOX then
--self:BlueMessage("A/A PVE Range: FOX class unavailable in this MOOSE build.", 10)
--self.FoxTrainerEnabled = false
--return
--end
--
--self.FoxTrainer = FOX:New()
--
--pcall(function()
--self.FoxTrainer:SetExplosionDistance(500)
--end)
--
--pcall(function()
--self.FoxTrainer:SetDisableF10Menu()
--end)
--
--pcall(function()
--self.FoxTrainer:SetDefaultLaunchAlerts(true)
--end)
--
--pcall(function()
--self.FoxTrainer:SetDefaultLaunchMarks(false)
--end)
--
--pcall(function()
--self.FoxTrainer:Start()
--end)
--end
--
--function AAPVE_MOOSE:StopFoxTrainer()
--if self.FoxTrainer then
--pcall(function()
--self.FoxTrainer:Stop()
--end)
--
--self.FoxTrainer = nil
--end
--end
--
-----------------------------------------------------------------------------
---- CAP package zone helpers.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:IsCapZoneAlreadyAssigned(capZone)
--if not capZone then
--return false
--end
--
--for _, package in pairs(self.CapPackages) do
--if package
--and package.Status ~= "Closed"
--and package.AssignedZone
--and package.AssignedZone.Name == capZone.Name then
--return true
--end
--end
--
--return false
--end
--
--function AAPVE_MOOSE:GetAvailableCapZone()
--local availableZones = {}
--
--for _, capZone in ipairs(self.BlueCapZones) do
--if capZone and capZone.Zone and not self:IsCapZoneAlreadyAssigned(capZone) then
--availableZones[#availableZones + 1] = capZone
--end
--end
--
--if #availableZones == 0 then
--return nil
--end
--
--return availableZones[math.random(1, #availableZones)]
--end
--
--function AAPVE_MOOSE:GetCapPackageCount()
--local count = 0
--
--for _, package in pairs(self.CapPackages) do
--if package and package.Status ~= "Closed" then
--count = count + 1
--end
--end
--
--return count
--end
--
--function AAPVE_MOOSE:ClearClientGroupMenus()
--    for groupId, menuPath in pairs(self.ClientGroupMenus or {}) do
--        if groupId and menuPath then
--            pcall(function()
--                missionCommands.removeItemForGroup(groupId, menuPath)
--            end)
--        end
--    end
--
--    self.ClientGroupMenus = {}
--end
--
-----------------------------------------------------------------------------
---- CAP package membership.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:GetClientsNearLead(leadClient, radiusNm)
--local members = {}
--local memberNames = {}
--
--if not leadClient or not leadClient:IsAlive() then
--return members, memberNames
--end
--
--local leadCoord = leadClient:GetCoordinate()
--
--if not leadCoord then
--return members, memberNames
--end
--
--local radiusMeters = UTILS.NMToMeters(radiusNm or self.CapCheckInRadiusNm or 0.5)
--
--self.BlueClientSet:ForEachClient(function(client)
--if client and client:IsAlive() then
--local clientCoord = client:GetCoordinate()
--
--if clientCoord then
--local distanceMeters = leadCoord:Get2DDistance(clientCoord)
--
--if distanceMeters <= radiusMeters then
--local unitName = self:GetClientUnitName(client)
--
--if unitName then
--members[unitName] = true
--memberNames[#memberNames + 1] = self:GetClientDisplayName(client)
--end
--end
--end
--end
--end)
--
--return members, memberNames
--end
--
--function AAPVE_MOOSE:GetCapPackageByMemberUnit(unitName)
--if not unitName then
--return nil
--end
--
--for _, package in pairs(self.CapPackages) do
--if package
--and package.Status ~= "Closed"
--and package.MemberUnits
--and package.MemberUnits[unitName] then
--return package
--end
--end
--
--return nil
--end
--
--function AAPVE_MOOSE:GetCapPackageByLeadUnit(unitName)
--if not unitName then
--return nil
--end
--
--for _, package in pairs(self.CapPackages) do
--if package
--and package.Status ~= "Closed"
--and package.LeadUnitName == unitName then
--return package
--end
--end
--
--return nil
--end
--
--function AAPVE_MOOSE:IsClientInAnyActiveCapPackage(unitName)
--return self:GetCapPackageByMemberUnit(unitName) ~= nil
--end
--
--function AAPVE_MOOSE:GetCapPackageByHostileGroupName(groupName)
--if not groupName then
--return nil
--end
--
--for _, package in pairs(self.CapPackages) do
--if package
--and package.Status ~= "Closed"
--and package.ActiveHostileGroup
--and package.ActiveHostileGroup:GetName() == groupName then
--return package
--end
--end
--
--return nil
--end
--
--function AAPVE_MOOSE:GetGlobalActiveHostileCount()
--local count = 0
--
--for _, package in pairs(self.CapPackages) do
--if package
--and package.Status ~= "Closed"
--and package.ActiveHostileGroup
--and package.ActiveHostileGroup:IsAlive() then
--count = count + 1
--end
--end
--
--return count
--end
--
-----------------------------------------------------------------------------
---- CAP package marker / tasking.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:RemoveCapPackageMarker(package)
--if package and package.MarkerId then
--pcall(function()
--COORDINATE:RemoveMark(package.MarkerId)
--end)
--
--package.MarkerId = nil
--end
--end
--
--function AAPVE_MOOSE:MarkCapPackage(package)
--if not package or not package.AssignedZone or not package.AssignedZone.Zone then
--return
--end
--
--local coord = package.AssignedZone.Zone:GetCoordinate()
--
--if not coord then
--return
--end
--
--local bullseye = self:GetBullseyeText(coord)
--local memberText = table.concat(package.MemberNames or {}, ", ")
--
--if memberText == "" then
--memberText = "Unknown"
--end
--
--self:RemoveCapPackageMarker(package)
--
--package.MarkerId = coord:MarkToCoalition(
--string.format(
--"A/A PVE CAP PACKAGE %d\nLead: %s\nHold: %s\n%s\nStatus: %s\nMembers: %s",
--package.Id,
--package.LeadClientName or "Unknown",
--package.AssignedZone.Name or "Unknown CAP",
--bullseye,
--package.Status or "Unknown",
--memberText
--),
--coalition.side.BLUE,
--true
--)
--end
--
--function AAPVE_MOOSE:SendCapPackageTasking(package, reminder)
--if not package or not package.AssignedZone or not package.AssignedZone.Zone then
--return
--end
--
--local coord = package.AssignedZone.Zone:GetCoordinate()
--local bullseye = self:GetBullseyeText(coord)
--local prefix = "CAP check-in accepted"
--
--if reminder then
--prefix = "CAP tasking reminder"
--end
--
--local memberText = table.concat(package.MemberNames or {}, ", ")
--
--if memberText == "" then
--memberText = "Unknown"
--end
--
--self:BlueMessage(
--string.format(
--"A/A PVE %s\nPackage: %d\nLead: %s\nHold: %s\nPosition: %s\nMembers: %s\nProceed as a flight and hold CAP.",
--prefix,
--package.Id,
--package.LeadClientName or "Unknown",
--package.AssignedZone.Name or "Unknown",
--bullseye,
--memberText
--),
--30
--)
--
--self:MarkCapPackage(package)
--
--self:SendTTS(
--string.format(
--"Magic, CAP package %d, proceed to %s, %s. Hold CAP and sanitize.",
--package.Id,
--package.AssignedZone.Name or "assigned CAP",
--bullseye
--)
--)
--end
--
--function AAPVE_MOOSE:RetaskPackageToCap(package, reason)
--if not package or not package.AssignedZone or not package.AssignedZone.Zone then
--return
--end
--
--local coord = package.AssignedZone.Zone:GetCoordinate()
--local bullseye = self:GetBullseyeText(coord)
--
--package.Status = "Retasking"
--package.CommitAnnounced = false
--package.ActiveHostileGroup = nil
--package.LastPictureSpawnTime = nil
--
--self:MarkCapPackage(package)
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range\nPackage %d: %s\nResume assigned CAP: %s\nPosition: %s\nPicture will resume once package is back on station.",
--package.Id,
--reason or "Threat neutralized.",
--package.AssignedZone.Name or "Assigned CAP",
--bullseye
--),
--30
--)
--
--self:SendTTS(
--string.format(
--"Magic, CAP package %d, %s Resume %s, %s. Picture will resume when back on station.",
--package.Id,
--reason or "threat neutralized.",
--package.AssignedZone.Name or "assigned CAP",
--bullseye
--)
--)
--end
--
-----------------------------------------------------------------------------
---- CAP check-in.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:RequestCapCheckIn(leadClient)
--if not leadClient or not leadClient:IsAlive() then
--self:BlueMessage("A/A PVE Range: unable to check in. Client is not active.", 10)
--return nil
--end
--
--if self.CurrentMode ~= "BlueCapDefense" then
--self:BlueMessage("A/A PVE Range: BLUE CAP Defense mode is not active.", 10)
--return nil
--end
--
--local leadUnitName = self:GetClientUnitName(leadClient)
--
--if not leadUnitName then
--self:BlueMessage("A/A PVE Range: unable to determine flight lead unit.", 10)
--return nil
--end
--
--local existingLeadPackage = self:GetCapPackageByLeadUnit(leadUnitName)
--
--if existingLeadPackage then
--self:SendCapPackageTasking(existingLeadPackage, true)
--return existingLeadPackage
--end
--
--if self:IsClientInAnyActiveCapPackage(leadUnitName) then
--local existingPackage = self:GetCapPackageByMemberUnit(leadUnitName)
--
--if existingPackage then
--self:BlueMessage(
--string.format(
--"A/A PVE Range: you are already assigned to CAP Package %d.",
--existingPackage.Id
--),
--10
--)
--
--self:SendCapPackageTasking(existingPackage, true)
--end
--
--return existingPackage
--end
--
--if self:GetCapPackageCount() >= self.MaxCapPackages then
--self:BlueMessage("A/A PVE Range: no additional CAP packages are available.", 10)
--return nil
--end
--
--local capZone = self:GetAvailableCapZone()
--
--if not capZone then
--self:BlueMessage("A/A PVE Range: all CAP zones are currently assigned.", 10)
--return nil
--end
--
--local memberUnits, memberNames = self:GetClientsNearLead(leadClient, self.CapCheckInRadiusNm)
--
--if not memberUnits[leadUnitName] then
--memberUnits[leadUnitName] = true
--memberNames[#memberNames + 1] = self:GetClientDisplayName(leadClient)
--end
--
--local package = {
--Id = self.NextCapPackageId,
--LeadClientName = self:GetClientDisplayName(leadClient),
--LeadUnitName = leadUnitName,
--AssignedZone = capZone,
--MemberUnits = memberUnits,
--MemberNames = memberNames,
--MarkerId = nil,
--Status = "Assigned",
--EmptySince = nil,
--ActiveHostileGroup = nil,
--LastKnownHostileCoordinate = nil,
--LastKnownHostileName = nil,
--CommitAnnounced = false,
--LastPictureSpawnTime = nil
--}
--
--self.NextCapPackageId = self.NextCapPackageId + 1
--self.CapPackages[#self.CapPackages + 1] = package
--
--self:SendCapPackageTasking(package, false)
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: CAP Package %d checked in by %s. Members: %s.",
--package.Id,
--package.LeadClientName,
--table.concat(package.MemberNames or {}, ", ")
--),
--20
--)
--
--return package
--end
--
-----------------------------------------------------------------------------
---- Client counting.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:GetCapPackageAssignedClientCount(package)
--local count = 0
--
--if not package or not package.MemberUnits then
--return 0
--end
--
--self.BlueClientSet:ForEachClient(function(client)
--if client and client:IsAlive() then
--local unitName = self:GetClientUnitName(client)
--local coord = client:GetCoordinate()
--
--if unitName
--and package.MemberUnits[unitName]
--and coord
--and package.AssignedZone
--and package.AssignedZone.Zone
--and package.AssignedZone.Zone:IsCoordinateInZone(coord) then
--count = count + 1
--end
--end
--end)
--
--return count
--end
--
--function AAPVE_MOOSE:GetCapPackageSandboxClientCount(package)
--local count = 0
--
--if not package or not package.MemberUnits or not self.SandboxZone then
--return 0
--end
--
--self.BlueClientSet:ForEachClient(function(client)
--if client and client:IsAlive() then
--local unitName = self:GetClientUnitName(client)
--local coord = client:GetCoordinate()
--
--if unitName
--and package.MemberUnits[unitName]
--and coord
--and self.SandboxZone:IsCoordinateInZone(coord) then
--count = count + 1
--end
--end
--end)
--
--return count
--end
--
--function AAPVE_MOOSE:GetCapPackageRepresentativeClientCoordinate(package)
--if not package or not package.MemberUnits then
--return nil
--end
--
--local bestCoord = nil
--
--self.BlueClientSet:ForEachClient(function(client)
--if bestCoord then
--return
--end
--
--if client and client:IsAlive() then
--local unitName = self:GetClientUnitName(client)
--
--if unitName and package.MemberUnits[unitName] then
--bestCoord = client:GetCoordinate()
--end
--end
--end)
--
--return bestCoord
--end
--
--function AAPVE_MOOSE:GetHostileGroupSizeForCapPackage(package)
--local playerCount = self:GetCapPackageSandboxClientCount(package)
--
--if playerCount <= 1 then
--return 1
--end
--
--if playerCount == 2 then
--return 2
--end
--
--if playerCount == 3 then
--return 2
--end
--
--return 4
--end
--
-----------------------------------------------------------------------------
---- Package monitor / commit logic.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:StartCapPackageMonitor()
--if self.CapPackageMonitorScheduler then
--self.CapPackageMonitorScheduler:Stop()
--self.CapPackageMonitorScheduler = nil
--end
--
--self.CapPackageMonitorScheduler = SCHEDULER:New(nil, function()
--AAPVE_MOOSE:MonitorCapPackages()
--end, {}, 5, self.CapPackageMonitorSeconds)
--end
--
--function AAPVE_MOOSE:MonitorCapPackages()
--if self.CurrentMode ~= "BlueCapDefense" then
--return
--end
--
--for _, package in pairs(self.CapPackages) do
--if package and package.Status ~= "Closed" then
--self:MonitorSingleCapPackage(package)
--self:MonitorPackageCommit(package)
--end
--end
--end
--
--function AAPVE_MOOSE:MonitorSingleCapPackage(package)
--if not package or not package.AssignedZone or not package.AssignedZone.Zone then
--return
--end
--
--local onStationCount = self:GetCapPackageAssignedClientCount(package)
--local sandboxCount = self:GetCapPackageSandboxClientCount(package)
--
--if onStationCount > 0 then
--if package.Status == "Assigned" or package.Status == "Retasking" then
--self:BlueMessage(
--string.format(
--"A/A PVE Range: CAP Package %d is on station.",
--package.Id
--),
--10
--)
--
--self:SendTTS(
--string.format(
--"Magic, CAP package %d is on station. Picture generation active.",
--package.Id
--)
--)
--end
--
--if package.Status ~= "Committed" then
--package.Status = "OnStation"
--end
--
--package.EmptySince = nil
--self:MarkCapPackage(package)
--return
--end
--
--if sandboxCount > 0 then
--package.EmptySince = nil
--return
--end
--
--if package.Status == "Assigned"
--or package.Status == "OnStation"
--or package.Status == "Committed"
--or package.Status == "Retasking" then
--
--if not package.EmptySince then
--package.EmptySince = timer.getTime()
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: CAP Package %d has no assigned clients inside the sandbox. Package will close in 5 minutes if empty.",
--package.Id
--),
--15
--)
--
--return
--end
--
--local emptyFor = timer.getTime() - package.EmptySince
--
--if emptyFor >= self.CapPackageEmptyCleanupSeconds then
--self:CloseCapPackage(package, "Sandbox empty for assigned package clients for 5 minutes.")
--end
--end
--end
--
--function AAPVE_MOOSE:MonitorPackageCommit(package)
--if not package
--or package.Status ~= "OnStation"
--or package.CommitAnnounced
--or not package.ActiveHostileGroup
--or not package.ActiveHostileGroup:IsAlive()
--or not package.AssignedZone
--or not package.AssignedZone.Zone then
--return
--end
--
--local capCoord = package.AssignedZone.Zone:GetCoordinate()
--local clientCoord = self:GetCapPackageRepresentativeClientCoordinate(package)
--local hostileCoord = package.ActiveHostileGroup:GetCoordinate()
--
--if not capCoord or not clientCoord or not hostileCoord then
--return
--end
--
--local distanceFromCapNm = UTILS.MetersToNM(clientCoord:Get2DDistance(capCoord))
--
--if distanceFromCapNm < self.CommitCheckDistanceFromCapNm then
--return
--end
--
--local capToClient = self:GetBearingDegrees(capCoord, clientCoord)
--local capToHostile = self:GetBearingDegrees(capCoord, hostileCoord)
--local headingDiff = self:GetHeadingDifferenceDegrees(capToClient, capToHostile)
--
--if headingDiff <= self.CommitHeadingToleranceDegrees then
--package.Status = "Committed"
--package.CommitAnnounced = true
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: CAP Package %d is committed to the hostile picture.",
--package.Id
--),
--10
--)
--
--self:SendTTS(
--string.format(
--"Magic, CAP package %d committed.",
--package.Id
--)
--)
--
--self:MarkCapPackage(package)
--end
--end
--
-----------------------------------------------------------------------------
---- Picture generation.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:StartCapPackagePictureScheduler()
--if self.CapPackagePictureScheduler then
--self.CapPackagePictureScheduler:Stop()
--self.CapPackagePictureScheduler = nil
--end
--
--self.CapPackagePictureScheduler = SCHEDULER:New(nil, function()
--AAPVE_MOOSE:GeneratePicturesForCapPackages()
--end, {}, 30, self.CapPackagePictureIntervalSeconds)
--end
--
--function AAPVE_MOOSE:GeneratePicturesForCapPackages()
--if self.CurrentMode ~= "BlueCapDefense" then
--return
--end
--
--for _, package in pairs(self.CapPackages) do
--if package and package.Status == "OnStation" then
--self:GeneratePictureForCapPackage(package)
--end
--end
--end
--
--function AAPVE_MOOSE:GeneratePictureForCapPackage(package)
--if not package or package.Status ~= "OnStation" then
--return
--end
--
--if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
--return
--end
--
--if self.UseGlobalHostileLimit and self:GetGlobalActiveHostileCount() >= self.MaxGlobalHostileGroups then
--return
--end
--
--local playerCount = self:GetCapPackageSandboxClientCount(package)
--
--if playerCount <= 0 then
--return
--end
--
--local roll = math.random(1, 100)
--local hostileLimit = self.PictureHostileChance
--local neutralLimit = self.PictureHostileChance + self.PictureNeutralChance
--
--if roll <= hostileLimit then
--self:SpawnHostileForCapPackage(package)
--elseif roll <= neutralLimit then
--self:SpawnNeutralForCapPackage(package)
--else
--self:SpawnFriendlyForCapPackage(package)
--end
--end
--
--function AAPVE_MOOSE:SpawnHostileForCapPackage(package)
--local option = self:GetRandomOption(self.PictureHostileTemplates)
--local spawnZone = self:GetRandomRedSpawnZone()
--
--if not option or not spawnZone then
--self:BlueMessage("A/A PVE Range: hostile spawn failed. Missing template or RED spawn zone.", 10)
--return
--end
--
--local groupSize = self:GetHostileGroupSizeForCapPackage(package)
--
--local spawn = SPAWN:NewWithAlias(
--option.Template,
--string.format(
--"AAPVE_PKG%d_HOSTILE_%s",
--package.Id,
--self:GetSanitizedName(option.Name)
--)
--)
--:InitRandomizeZones({ spawnZone })
--:InitGrouping(groupSize)
--:InitSkill("Random")
--
--local group = spawn:Spawn()
--
--if not group then
--self:BlueMessage(
--string.format("A/A PVE Range: hostile spawn failed for CAP Package %d.", package.Id),
--10
--)
--return
--end
--
--group:OptionAlarmStateRed()
--group:OptionROEOpenFire()
--
--local destination = package.AssignedZone.Zone:GetCoordinate()
--
--if destination then
--local task = group:TaskRouteToVec2(
--destination:GetVec2(),
--math.random(self.PictureMinSpeed, self.PictureMaxSpeed),
--math.random(self.PictureMinAltitude, self.PictureMaxAltitude),
--"BARO"
--)
--
--group:SetTask(task)
--end
--
--package.ActiveHostileGroup = group
--package.LastKnownHostileCoordinate = group:GetCoordinate()
--package.LastKnownHostileName = group:GetName()
--package.CommitAnnounced = false
--package.LastPictureSpawnTime = timer.getTime()
--
--self:AddActiveGroup(group)
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: hostile picture generated for CAP Package %d. %s x%d.",
--package.Id,
--option.Name,
--groupSize
--),
--10
--)
--
--self:SendTTS(
--string.format(
--"Magic, CAP package %d, picture update. Hostile group inbound.",
--package.Id
--)
--)
--end
--
--function AAPVE_MOOSE:SpawnNeutralForCapPackage(package)
--local option = self:GetRandomOption(self.PictureNeutralTemplates)
--
--if option then
--self:SpawnNonHostileForCapPackage(package, option, "NEUTRAL")
--end
--end
--
--function AAPVE_MOOSE:SpawnFriendlyForCapPackage(package)
--local option = self:GetRandomOption(self.PictureFriendlyTemplates)
--
--if option then
--self:SpawnNonHostileForCapPackage(package, option, "FRIENDLY")
--end
--end
--
--function AAPVE_MOOSE:SpawnNonHostileForCapPackage(package, option, role)
--local spawnZone = self:GetRandomRedSpawnZone()
--
--if not spawnZone then
--self:BlueMessage("A/A PVE Range: non-hostile spawn failed. No RED spawn zone.", 10)
--return
--end
--
--local spawn = SPAWN:NewWithAlias(
--option.Template,
--string.format(
--"AAPVE_PKG%d_%s_%s",
--package.Id,
--role,
--self:GetSanitizedName(option.Name)
--)
--)
--:InitRandomizeZones({ spawnZone })
--:InitGrouping(1)
--:InitSkill("Random")
--
--local group = spawn:Spawn()
--
--if not group then
--self:BlueMessage(
--string.format("A/A PVE Range: %s spawn failed for CAP Package %d.", role, package.Id),
--10
--)
--return
--end
--
--group:OptionAlarmStateRed()
--group:OptionROEHoldFire()
--group:OptionROTPassiveDefense()
--
--local destination = nil
--local recoveryZone = self:GetRandomRecoveryZone()
--
--if recoveryZone then
--destination = recoveryZone:GetCoordinate()
--elseif self.ProtectedZone then
--destination = self.ProtectedZone:GetCoordinate()
--end
--
--if destination then
--local task = group:TaskRouteToVec2(
--destination:GetVec2(),
--math.random(self.PictureMinSpeed, self.PictureMaxSpeed),
--math.random(self.PictureMinAltitude, self.PictureMaxAltitude),
--"BARO"
--)
--
--group:SetTask(task)
--end
--
--self:AddActiveGroup(group)
--
--local lifetime = math.random(
--self.NonHostileMinLifetimeSeconds,
--self.NonHostileMaxLifetimeSeconds
--)
--
--SCHEDULER:New(nil, function()
--if group and group:IsAlive() then
--group:Destroy()
--end
--end, {}, lifetime)
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: %s track generated for CAP Package %d.",
--role,
--package.Id
--),
--10
--)
--end
--
-----------------------------------------------------------------------------
---- Close / cleanup.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:CloseCapPackage(package, reason)
--if not package or package.Status == "Closed" then
--return
--end
--
--package.Status = "Closed"
--
--if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
--self:DestroyGroup(package.ActiveHostileGroup)
--end
--
--package.ActiveHostileGroup = nil
--package.LastKnownHostileCoordinate = nil
--package.MemberUnits = {}
--package.MemberNames = {}
--package.EmptySince = nil
--
--self:RemoveCapPackageMarker(package)
--
--self:BlueMessage(
--string.format(
--"A/A PVE Range: CAP Package %d closed. %s",
--package.Id,
--reason or ""
--),
--15
--)
--end
--
--function AAPVE_MOOSE:CloseMyCapPackage(client)
--if not client or not client:IsAlive() then
--return
--end
--
--local unitName = self:GetClientUnitName(client)
--local package = self:GetCapPackageByLeadUnit(unitName)
--
--if not package then
--package = self:GetCapPackageByMemberUnit(unitName)
--end
--
--if not package then
--self:BlueMessage("A/A PVE Range: you are not assigned to an active CAP package.", 10)
--return
--end
--
--self:CloseCapPackage(package, "Closed by package member request.")
--end
--
--function AAPVE_MOOSE:ClearCapPackages()
--for _, package in pairs(self.CapPackages) do
--if package and package.Status ~= "Closed" then
--self:CloseCapPackage(package, "Range cleared.")
--end
--end
--
--self.CapPackages = {}
--self.NextCapPackageId = 1
--end
--
-----------------------------------------------------------------------------
---- Modes.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:StartRedCapPracticeMode()
--self:ClearRange(false)
--
--self:BlueMessage(
--"A/A PVE Range: RED CAP Target Practice mode active.",
--15
--)
--
--self:SendTTS("Magic, A/A PVE Range RED CAP target practice mode is active.")
--end
--
--function AAPVE_MOOSE:StartBlueCapDefenseMode()
--self:ClearRange(false)
--self:StartBlueChief()
--self:StartCapPackageMonitor()
--self:StartCapPackagePictureScheduler()
--
--self:BlueMessage(
--"A/A PVE Range: BLUE CAP Defense mode active. Flight leads use CAP Check-in from the F10 menu.",
--20
--)
--
--self:SendTTS("Magic, A/A PVE Range BLUE CAP defense mode is active. Flight leads may check in for CAP tasking.")
--end
--
--function AAPVE_MOOSE:SpawnManualRedCap(templateOption, count, skill)
--    if not templateOption then
--        return
--    end
--
--    local spawnZone = self:GetRandomRedSpawnZone()
--
--    if not spawnZone then
--        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed. No RED spawn zone.", 10)
--        return
--    end
--
--    local groupSize = count or 2
--    local groupSkill = skill or "Random"
--
--    local spawn = SPAWN:NewWithAlias(
--            templateOption.Template,
--            "AAPVE_REDCAP_" .. self:GetSanitizedName(templateOption.Name)
--    )
--                       :InitRandomizeZones({ spawnZone })
--                       :InitGrouping(groupSize)
--                       :InitSkill(groupSkill)
--
--    local group = spawn:Spawn()
--
--    if not group then
--        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed.", 10)
--        return
--    end
--
--    self:AddActiveGroup(group)
--
--    SCHEDULER:New(nil, function()
--        if not group or not group:IsAlive() then
--            return
--        end
--
--        pcall(function()
--            group:OptionAlarmStateRed()
--        end)
--
--        pcall(function()
--            group:OptionROEOpenFire()
--        end)
--
--        local capCoord = self.RedCapZone:GetCoordinate()
--
--        if capCoord then
--            local task = group:TaskOrbitCircleAtVec2(
--                    capCoord:GetVec2(),
--                    24000,
--                    450
--            )
--
--            if task then
--                group:SetTask(task)
--            end
--        end
--    end, {}, 2)
--
--    self:BlueMessage(
--            string.format(
--                    "A/A PVE Range: spawned RED CAP %s x%d.",
--                    templateOption.Name,
--                    groupSize
--            ),
--            10
--    )
--end
--
-----------------------------------------------------------------------------
---- Events.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.EventHandler = EVENTHANDLER:New()
--AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Dead)
--AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Crash)
--AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.PilotDead)
--AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Kill)
--
--function AAPVE_MOOSE.EventHandler:OnEventDead(EventData)
--AAPVE_MOOSE:HandleDeathEvent(EventData)
--end
--
--function AAPVE_MOOSE.EventHandler:OnEventCrash(EventData)
--AAPVE_MOOSE:HandleDeathEvent(EventData)
--end
--
--function AAPVE_MOOSE.EventHandler:OnEventPilotDead(EventData)
--AAPVE_MOOSE:HandleDeathEvent(EventData)
--end
--
--function AAPVE_MOOSE.EventHandler:OnEventKill(EventData)
--AAPVE_MOOSE:HandleKillEvent(EventData)
--end
--
--function AAPVE_MOOSE:HandleDeathEvent(EventData)
--if not EventData or not EventData.IniUnit then
--return
--end
--
--local deadGroup = EventData.IniUnit:GetGroup()
--
--if not deadGroup then
--return
--end
--
--local package = self:GetCapPackageByHostileGroupName(deadGroup:GetName())
--
--if not package then
--return
--end
--
--SCHEDULER:New(nil, function()
--if package.ActiveHostileGroup and not package.ActiveHostileGroup:IsAlive() then
--local packageId = package.Id
--package.ActiveHostileGroup = nil
--
--self:RetaskPackageToCap(
--package,
--"Hostile group neutralized."
--)
--
--self:Log("Package " .. tostring(packageId) .. " hostile neutralized and retasked.")
--end
--end, {}, 2)
--end
--
--function AAPVE_MOOSE:HandleKillEvent(EventData)
--if not EventData then
--return
--end
--
--local killer = EventData.IniUnit
--local victim = EventData.TgtUnit
--
--if not killer or not victim then
--return
--end
--
--local killerGroup = killer:GetGroup()
--
--if not killerGroup then
--return
--end
--
--local package = self:GetCapPackageByHostileGroupName(killerGroup:GetName())
--
--if not package then
--return
--end
--
--if victim:GetCoalition() == coalition.side.BLUE then
--self:BlueMessage(
--string.format(
--"A/A PVE Range: RED AI killed a Blue client in CAP Package %d. Hostile group despawning.",
--package.Id
--),
--10
--)
--
--self:DestroyGroup(package.ActiveHostileGroup)
--package.ActiveHostileGroup = nil
--
--self:RetaskPackageToCap(
--package,
--"Blue aircraft down. Hostile removed."
--)
--end
--end
--
-----------------------------------------------------------------------------
---- Client F10 menus.
-----------------------------------------------------------------------------
--
--AAPVE_MOOSE.PlayerMenuHandler = EVENTHANDLER:New()
--AAPVE_MOOSE.PlayerMenuHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
--
--function AAPVE_MOOSE.PlayerMenuHandler:OnEventPlayerEnterAircraft(EventData)
--if not EventData or not EventData.IniUnit then
--return
--end
--
--if EventData.IniCoalition ~= coalition.side.BLUE then
--return
--end
--
--AAPVE_MOOSE:BuildClientGroupMenu(EventData.IniUnit)
--end
--
--function AAPVE_MOOSE:BuildClientGroupMenu(unit)
--    if not unit then
--        return
--    end
--
--    local group = unit:GetGroup()
--
--    if not group then
--        return
--    end
--
--    local groupId = group:GetID()
--
--    if not groupId then
--        return
--    end
--
--    -- Do not remove/recreate an existing menu.
--    -- Rebuilding F10 menus while players are using them can cause DCS WRADIO assertion errors.
--    if self.ClientGroupMenus[groupId] then
--        return
--    end
--
--    local rootMenu = missionCommands.addSubMenuForGroup(
--            groupId,
--            "A/A PVE Range"
--    )
--
--    self.ClientGroupMenus[groupId] = rootMenu
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "CAP Check-in / Request Tasking",
--            rootMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if client then
--                    AAPVE_MOOSE:RequestCapCheckIn(client)
--                end
--            end
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "Check My CAP Tasking",
--            rootMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if not client then
--                    return
--                end
--
--                local unitName = AAPVE_MOOSE:GetClientUnitName(client)
--                local package = AAPVE_MOOSE:GetCapPackageByMemberUnit(unitName)
--
--                if package then
--                    AAPVE_MOOSE:SendCapPackageTasking(package, true)
--                else
--                    MESSAGE:New("A/A PVE Range: you are not assigned to an active CAP package.", 10):ToGroup(group)
--                end
--            end
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "Close My CAP Tasking",
--            rootMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if client then
--                    AAPVE_MOOSE:CloseMyCapPackage(client)
--                end
--            end
--    )
--
--    local timelineMenu = missionCommands.addSubMenuForGroup(
--            groupId,
--            "Timeline Spawn",
--            rootMenu
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "BVR - 80 NM Hot",
--            timelineMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if client then
--                    AAPVE_MOOSE:SpawnTimelineBanditForClient(client, "BVR")
--                end
--            end
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "WVR - 20 NM Hot",
--            timelineMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if client then
--                    AAPVE_MOOSE:SpawnTimelineBanditForClient(client, "WVR")
--                end
--            end
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "BFM - 5 NM Cold Weapons Until Merge",
--            timelineMenu,
--            function()
--                local client = CLIENT:FindByName(unit:GetName())
--
--                if client then
--                    AAPVE_MOOSE:SpawnTimelineBanditForClient(client, "BFM")
--                end
--            end
--    )
--
--    missionCommands.addCommandForGroup(
--            groupId,
--            "Toggle FOX Missile Trainer",
--            rootMenu,
--            function()
--                AAPVE_MOOSE:ToggleFoxTrainer()
--            end
--    )
--end
-----------------------------------------------------------------------------
---- Coalition admin menus.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:BuildCoalitionMenus()
--local modeMenu = self:AddMenuItem(
--MENU_COALITION:New(
--coalition.side.BLUE,
--"Mode",
--self.MenuRoot
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Start RED CAP Target Practice",
--modeMenu,
--function()
--if AAPVE_MOOSE.CurrentMode ~= "Idle" then
--AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
--return
--end
--
--AAPVE_MOOSE.FSM:StartRedCap()
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Start BLUE CAP Defense",
--modeMenu,
--function()
--if AAPVE_MOOSE.CurrentMode ~= "Idle" then
--AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
--return
--end
--
--AAPVE_MOOSE.FSM:StartBlueCap()
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Stop Current Mode",
--modeMenu,
--function()
--if AAPVE_MOOSE.CurrentMode == "Idle" then
--AAPVE_MOOSE:BlueMessage("A/A PVE Range is already idle.", 10)
--return
--end
--
--AAPVE_MOOSE.FSM:StopMode()
--end
--)
--)
--
--local redCapMenu = self:AddMenuItem(
--MENU_COALITION:New(
--coalition.side.BLUE,
--"Manual RED CAP Spawn",
--self.MenuRoot
--)
--)
--
--for _, option in ipairs(self.RedCapTemplates) do
--local selectedOption = option
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Spawn " .. selectedOption.Name .. " x1",
--redCapMenu,
--function()
--AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 1, "Random")
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Spawn " .. selectedOption.Name .. " x2",
--redCapMenu,
--function()
--AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 2, "Random")
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Spawn " .. selectedOption.Name .. " x4",
--redCapMenu,
--function()
--AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 4, "Random")
--end
--)
--)
--end
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Toggle FOX Missile Trainer",
--self.MenuRoot,
--function()
--AAPVE_MOOSE:ToggleFoxTrainer()
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Clear Range",
--self.MenuRoot,
--function()
--AAPVE_MOOSE:ClearRange(true)
--AAPVE_MOOSE.CurrentMode = "Idle"
--end
--)
--)
--
--self:AddMenuItem(
--MENU_COALITION_COMMAND:New(
--coalition.side.BLUE,
--"Show Status",
--self.MenuRoot,
--function()
--AAPVE_MOOSE:ShowStatus()
--end
--)
--)
--end
--
-----------------------------------------------------------------------------
---- Status.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:ShowStatus()
--local activeGroups = 0
--
--for _, group in pairs(self.ActiveGroups) do
--if group and group:IsAlive() then
--activeGroups = activeGroups + 1
--end
--end
--
--local statusText = string.format(
--"A/A PVE Range Status\nMode: %s\nFOX Trainer: %s\nCAP Packages: %d\nActive Hostiles: %d\nSpawned Groups: %d",
--self.CurrentMode,
--tostring(self.FoxTrainerEnabled),
--self:GetCapPackageCount(),
--self:GetGlobalActiveHostileCount(),
--activeGroups
--)
--
--for _, package in pairs(self.CapPackages) do
--if package and package.Status ~= "Closed" then
--local onStationCount = self:GetCapPackageAssignedClientCount(package)
--local sandboxCount = self:GetCapPackageSandboxClientCount(package)
--local hostileActive = "No"
--
--if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
--hostileActive = "Yes"
--end
--
--statusText = statusText .. string.format(
--"\n\nPackage %d\nLead: %s\nHold: %s\nStatus: %s\nOn Station: %d\nIn Sandbox: %d\nHostile Active: %s",
--package.Id,
--package.LeadClientName or "Unknown",
--package.AssignedZone and package.AssignedZone.Name or "Unknown",
--package.Status or "Unknown",
--onStationCount,
--sandboxCount,
--hostileActive
--)
--end
--end
--
--self:BlueMessage(statusText, 25)
--end
--
-----------------------------------------------------------------------------
---- Cleanup.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:ClearRange(showMessage)
--    if self.CapPackageMonitorScheduler then
--        pcall(function()
--            self.CapPackageMonitorScheduler:Stop()
--        end)
--
--        self.CapPackageMonitorScheduler = nil
--    end
--
--    if self.CapPackagePictureScheduler then
--        pcall(function()
--            self.CapPackagePictureScheduler:Stop()
--        end)
--
--        self.CapPackagePictureScheduler = nil
--    end
--
--    self:ClearCapPackages()
--
--    for _, group in pairs(self.ActiveGroups) do
--        self:DestroyGroup(group)
--    end
--
--    self.ActiveGroups = {}
--
--    self:StopBlueChief()
--    self:StopRedDispatcher()
--
--    -- Do NOT clear client group menus here.
--    -- Removing F10 menu items while a player has the radio menu open can cause
--    -- DCS WRADIO StaticMenu assertion errors.
--
--    if showMessage ~= false then
--        self:BlueMessage("A/A PVE Range cleared.", 10)
--    end
--end
--function AAPVE_MOOSE:Stop()
--    self:ClearRange(false)
--    self:ClearClientGroupMenus()
--    self:StopFoxTrainer()
--
--    if self.FSM then
--        pcall(function()
--            self.FSM:Shutdown()
--        end)
--    end
--end
--
-----------------------------------------------------------------------------
---- Start.
-----------------------------------------------------------------------------
--
--function AAPVE_MOOSE:Start()
--    self:BuildCoalitionMenus()
--    self.FSM:Start()
--
--    self:BlueMessage("A/A PVE Range MOOSE version initialized.", 10)
--    self:Log("Initialized.")
--end
--
--AAPVE_MOOSE:Start()




---------------------------------------------------------------------------
-- A/A PVE Range - MOOSE FSM / CAP Package Version
--
-- Requires:
--   MOOSE loaded before this file.
--
-- Major features:
--   1. RED CAP Target Practice mode.
--   2. BLUE CAP Defense mode with randomized air picture.
--   3. Flight-lead CAP Check-in through coalition client selector menus.
--   4. Script-defined flight packages using clients within 0.5 NM of lead.
--   5. Multiple simultaneous CAP packages.
--   6. Large sandbox zone for cleanup logic.
--   7. Multiple RED / picture spawn zones.
--   8. Commit detection when package leaves CAP toward hostile.
--   9. Retask back to CAP after hostile neutralized.
--   10. Picture resumes only after package returns to CAP.
--   11. FOX Missile Trainer toggle.
--   12. Timeline spawns:
--       BVR - 80 NM hot
--       WVR - 20 NM hot
--       BFM - 5 NM hot, RED holds fire until merge
--
-- Important:
--   This script intentionally does NOT create per-group DCS F10 menus.
--   It uses only MOOSE coalition menus to avoid DCS WRADIO StaticMenu
--   assertion errors caused by dynamic group-menu rebuilds.
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

AAPVE_MOOSE.MenuRoot = MENU_COALITION:New(coalition.side.BLUE, "A/A RANGE SETUP")
AAPVE_MOOSE.MenuCommands = {}
AAPVE_MOOSE.TimelineClientMenus = {}

AAPVE_MOOSE.CurrentMode = "Idle"

---------------------------------------------------------------------------
-- Mission zones.
---------------------------------------------------------------------------

AAPVE_MOOSE.BlueCapZones = {
    {
        Name = "CAP HOLD 1",
        Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_1")
    },
    {
        Name = "CAP HOLD 2",
        Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_2")
    },
    {
        Name = "CAP HOLD 3",
        Zone = ZONE:New("AAPVE_BLUE_CAP_ZONE_3")
    }
}

AAPVE_MOOSE.RedCapZone = ZONE:New("AAPVE_RED_CAP_ZONE")
AAPVE_MOOSE.ProtectedZone = ZONE:New("AAPVE_PROTECTED_ZONE")
AAPVE_MOOSE.SandboxZone = ZONE:New("AAPVE_SANDBOX_ZONE")

AAPVE_MOOSE.RedSpawnZones = {
    ZONE:New("AAPVE_RED_SPAWN_ZONE_1"),
    ZONE:New("AAPVE_RED_SPAWN_ZONE_2"),
    ZONE:New("AAPVE_RED_SPAWN_ZONE_3")
}

AAPVE_MOOSE.RecoveryZones = {
    ZONE:New("AAPVE_RECOVERY_ZONE_1"),
    ZONE:New("AAPVE_RECOVERY_ZONE_2"),
    ZONE:New("AAPVE_RECOVERY_ZONE_3")
}

---------------------------------------------------------------------------
-- Sets.
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

AAPVE_MOOSE.ActiveGroups = {}

AAPVE_MOOSE.CapPackages = {}
AAPVE_MOOSE.NextCapPackageId = 1

AAPVE_MOOSE.BlueChief = nil

AAPVE_MOOSE.CapPackageMonitorScheduler = nil
AAPVE_MOOSE.CapPackagePictureScheduler = nil

AAPVE_MOOSE.FoxTrainer = nil
AAPVE_MOOSE.FoxTrainerEnabled = false

---------------------------------------------------------------------------
-- CAP package / picture configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.CapCheckInRadiusNm = 0.5
AAPVE_MOOSE.MaxCapPackages = 3

AAPVE_MOOSE.CapPackageMonitorSeconds = 10
AAPVE_MOOSE.CapPackagePictureIntervalSeconds = 120
AAPVE_MOOSE.CapPackageEmptyCleanupSeconds = 300

AAPVE_MOOSE.UseGlobalHostileLimit = false
AAPVE_MOOSE.MaxGlobalHostileGroups = 2

AAPVE_MOOSE.PictureHostileChance = 55
AAPVE_MOOSE.PictureNeutralChance = 25
AAPVE_MOOSE.PictureFriendlyChance = 20

AAPVE_MOOSE.NonHostileMinLifetimeSeconds = 300
AAPVE_MOOSE.NonHostileMaxLifetimeSeconds = 900

AAPVE_MOOSE.PictureMinAltitude = 12000
AAPVE_MOOSE.PictureMaxAltitude = 32000
AAPVE_MOOSE.PictureMinSpeed = 320
AAPVE_MOOSE.PictureMaxSpeed = 500

AAPVE_MOOSE.CommitCheckDistanceFromCapNm = 5
AAPVE_MOOSE.CommitHeadingToleranceDegrees = 70

---------------------------------------------------------------------------
-- Timeline spawn configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.TimelineSpawnOptions = {
    BVR = {
        Label = "BVR",
        DistanceNm = 80,
        Speed = 500,
        RoeAtSpawn = "OpenFire",
        OpenFireAfterMerge = false
    },
    WVR = {
        Label = "WVR",
        DistanceNm = 20,
        Speed = 450,
        RoeAtSpawn = "OpenFire",
        OpenFireAfterMerge = false
    },
    BFM = {
        Label = "BFM",
        DistanceNm = 5,
        Speed = 420,
        RoeAtSpawn = "HoldFire",
        OpenFireAfterMerge = true,
        MergeDistanceNm = 1.0
    }
}

AAPVE_MOOSE.TimelineDefaultTemplate = "AAPVE_RED_MIG29"
AAPVE_MOOSE.TimelineDefaultGroupSize = 1

---------------------------------------------------------------------------
-- TTS configuration.
---------------------------------------------------------------------------

AAPVE_MOOSE.TTSFrequency = 262
AAPVE_MOOSE.TTSModulation = radio.modulation.AM
AAPVE_MOOSE.TTSLabel = "Magic"
AAPVE_MOOSE.TTSVoice = "Nathan"
AAPVE_MOOSE.TTSSpeed = 200
AAPVE_MOOSE.TTSVolume = 0.6

---------------------------------------------------------------------------
-- Aircraft templates.
---------------------------------------------------------------------------

AAPVE_MOOSE.RedCapTemplates = {
    {
        Name = "MiG-29",
        Template = "AAPVE_RED_MIG29"
    },
    {
        Name = "Su-27",
        Template = "AAPVE_RED_SU27"
    },
    {
        Name = "F-16",
        Template = "AAPVE_RED_F16"
    },
    {
        Name = "F-14",
        Template = "AAPVE_RED_F14"
    },
    {
        Name = "F-5",
        Template = "AAPVE_RED_F5"
    }
}

AAPVE_MOOSE.PictureHostileTemplates = {
    {
        Name = "MiG-29",
        Template = "AAPVE_RED_MIG29"
    },
    {
        Name = "Su-27",
        Template = "AAPVE_RED_SU27"
    },
    {
        Name = "F-16",
        Template = "AAPVE_RED_F16"
    },
    {
        Name = "F-14",
        Template = "AAPVE_RED_F14"
    },
    {
        Name = "F-5",
        Template = "AAPVE_RED_F5"
    }
}

AAPVE_MOOSE.PictureFriendlyTemplates = {
    {
        Name = "Friendly F/A-18",
        Template = "AAPVE_FRIENDLY_F18"
    },
    {
        Name = "Friendly F-16",
        Template = "AAPVE_FRIENDLY_F16"
    },
    {
        Name = "Friendly F-14",
        Template = "AAPVE_FRIENDLY_F14"
    }
}

AAPVE_MOOSE.PictureNeutralTemplates = {
    {
        Name = "Neutral L-39",
        Template = "AAPVE_NEUTRAL_L39"
    },
    {
        Name = "Neutral C-101",
        Template = "AAPVE_NEUTRAL_C101"
    },
    {
        Name = "Neutral FW-190",
        Template = "AAPVE_NEUTRAL_FW190"
    }
}

---------------------------------------------------------------------------
-- Basic helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:Log(message)
    if self.Debug then
        env.info("[AAPVE_MOOSE] " .. tostring(message))
    end
end

function AAPVE_MOOSE:BlueMessage(message, seconds)
    MESSAGE:New(message, seconds or 10):ToCoalition(coalition.side.BLUE)
end

function AAPVE_MOOSE:AddMenuItem(menuItem)
    if menuItem then
        self.MenuCommands[#self.MenuCommands + 1] = menuItem
    end

    return menuItem
end

function AAPVE_MOOSE:GetRandomOption(options)
    if not options or #options == 0 then
        return nil
    end

    return options[math.random(1, #options)]
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
        pcall(function()
            group:Destroy()
        end)
    end
end

function AAPVE_MOOSE:GetSanitizedName(name)
    if not name then
        return "Unknown"
    end

    return tostring(name):gsub("[^%w]", "")
end

function AAPVE_MOOSE:GetClientUnitName(client)
    if not client then
        return nil
    end

    return client:GetName()
end

function AAPVE_MOOSE:GetClientDisplayName(client)
    if not client then
        return "Unknown"
    end

    return client:GetPlayerName() or client:GetName() or "Unknown"
end

function AAPVE_MOOSE:GetBullseyeText(coordinate)
    if not coordinate then
        return "bullseye unavailable"
    end

    local text = nil

    pcall(function()
        text = coordinate:ToStringBULLS(coalition.side.BLUE)
    end)

    if text then
        return text
    end

    pcall(function()
        text = coordinate:ToStringBULLS()
    end)

    return text or "bullseye unavailable"
end

function AAPVE_MOOSE:SendTTS(messageText)
    if not messageText or messageText == "" then
        return
    end

    if not MSRS then
        self:Log("MSRS unavailable. TTS skipped: " .. tostring(messageText))
        return
    end

    local msrs = nil

    pcall(function()
        msrs = MSRS:New(
                SRS_PATH or "",
                self.TTSFrequency,
                self.TTSModulation
        )
    end)

    if not msrs then
        self:Log("Failed to create MSRS object.")
        return
    end

    pcall(function()
        msrs:SetCoalition(coalition.side.BLUE)
    end)

    pcall(function()
        msrs:SetLabel(self.TTSLabel or "Magic")
    end)

    pcall(function()
        msrs:SetVolume(self.TTSVolume or 0.6)
    end)

    msrs.voice = self.TTSVoice or "Nathan"
    msrs.speed = self.TTSSpeed or 200

    pcall(function()
        msrs:PlayText(messageText, 0)
    end)
end

---------------------------------------------------------------------------
-- Geometry helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetBearingDegrees(fromCoordinate, toCoordinate)
    if not fromCoordinate or not toCoordinate then
        return nil
    end

    local fromVec2 = fromCoordinate:GetVec2()
    local toVec2 = toCoordinate:GetVec2()

    if not fromVec2 or not toVec2 then
        return nil
    end

    local dx = toVec2.x - fromVec2.x
    local dy = toVec2.y - fromVec2.y

    local bearing = math.deg(math.atan2(dx, dy))

    if bearing < 0 then
        bearing = bearing + 360
    end

    return bearing
end

function AAPVE_MOOSE:GetHeadingDifferenceDegrees(headingA, headingB)
    if not headingA or not headingB then
        return 180
    end

    local diff = math.abs(headingA - headingB)

    if diff > 180 then
        diff = 360 - diff
    end

    return diff
end

function AAPVE_MOOSE:GetClientHeadingDegrees(client)
    if not client then
        return 0
    end

    local heading = nil

    pcall(function()
        heading = client:GetHeading()
    end)

    if heading then
        return heading
    end

    return 0
end

---------------------------------------------------------------------------
-- FSM.
---------------------------------------------------------------------------

AAPVE_MOOSE.FSM = FSM:New()
AAPVE_MOOSE.FSM:SetStartState("Stopped")

AAPVE_MOOSE.FSM:AddTransition("Stopped", "Start", "Idle")
AAPVE_MOOSE.FSM:AddTransition("Idle", "StartRedCap", "RedCapPractice")
AAPVE_MOOSE.FSM:AddTransition("Idle", "StartBlueCap", "BlueCapDefense")
AAPVE_MOOSE.FSM:AddTransition("RedCapPractice", "StopMode", "Idle")
AAPVE_MOOSE.FSM:AddTransition("BlueCapDefense", "StopMode", "Idle")
AAPVE_MOOSE.FSM:AddTransition("*", "Shutdown", "Stopped")

function AAPVE_MOOSE.FSM:OnAfterStart(From, Event, To)
    AAPVE_MOOSE.CurrentMode = "Idle"
    AAPVE_MOOSE:BlueMessage("A/A PVE Range is online.", 10)
end

function AAPVE_MOOSE.FSM:OnAfterStartRedCap(From, Event, To)
    AAPVE_MOOSE.CurrentMode = "RedCapPractice"
    AAPVE_MOOSE:StartRedCapPracticeMode()
end

function AAPVE_MOOSE.FSM:OnAfterStartBlueCap(From, Event, To)
    AAPVE_MOOSE.CurrentMode = "BlueCapDefense"
    AAPVE_MOOSE:StartBlueCapDefenseMode()
end

function AAPVE_MOOSE.FSM:OnAfterStopMode(From, Event, To)
    AAPVE_MOOSE.CurrentMode = "Idle"
    AAPVE_MOOSE:ClearRange()
    AAPVE_MOOSE:BlueMessage("A/A PVE Range returned to idle.", 10)
end

function AAPVE_MOOSE.FSM:OnAfterShutdown(From, Event, To)
    AAPVE_MOOSE.CurrentMode = "Stopped"
    AAPVE_MOOSE:ClearRange(false)
end

---------------------------------------------------------------------------
-- CHIEF only. A2A Dispatcher intentionally removed.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartBlueChief()
    if self.BlueChief then
        return
    end

    if not CHIEF then
        self:Log("CHIEF unavailable. BLUE CHIEF skipped.")
        return
    end

    self.BlueChief = CHIEF:New(coalition.side.BLUE, self.BlueDetectionSet, "AAPVE Blue Chief")
    self.BlueChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

    if self.ProtectedZone then
        self.BlueChief:AddBorderZone(self.ProtectedZone)
    end

    self.BlueChief:Start()
    self:BlueMessage("A/A PVE Range: BLUE CHIEF active.", 10)
end

function AAPVE_MOOSE:StopBlueChief()
    if self.BlueChief then
        pcall(function()
            self.BlueChief:Stop()
        end)

        self.BlueChief = nil
    end
end

function AAPVE_MOOSE:StartRedDispatcher()
    -- Removed. RED aircraft are spawned by manual RED CAP or timeline spawns.
end

function AAPVE_MOOSE:StopRedDispatcher()
    -- Removed. Kept as no-op for cleanup compatibility.
end

---------------------------------------------------------------------------
-- FOX Missile Trainer.
---------------------------------------------------------------------------

function AAPVE_MOOSE:SetFoxTrainerEnabled(enabled)
    self.FoxTrainerEnabled = enabled == true

    if self.FoxTrainerEnabled then
        self:StartFoxTrainer()
        self:BlueMessage("A/A PVE Range: FOX Missile Trainer enabled.", 10)
    else
        self:StopFoxTrainer()
        self:BlueMessage("A/A PVE Range: FOX Missile Trainer disabled.", 10)
    end
end

function AAPVE_MOOSE:ToggleFoxTrainer()
    self:SetFoxTrainerEnabled(not self.FoxTrainerEnabled)
end

function AAPVE_MOOSE:StartFoxTrainer()
    if self.FoxTrainer then
        return
    end

    if not FOX then
        self:BlueMessage("A/A PVE Range: FOX class unavailable in this MOOSE build.", 10)
        self.FoxTrainerEnabled = false
        return
    end

    self.FoxTrainer = FOX:New()

    pcall(function()
        self.FoxTrainer:SetExplosionDistance(500)
    end)

    pcall(function()
        self.FoxTrainer:SetDisableF10Menu()
    end)

    pcall(function()
        self.FoxTrainer:SetDefaultLaunchAlerts(true)
    end)

    pcall(function()
        self.FoxTrainer:SetDefaultLaunchMarks(false)
    end)

    pcall(function()
        self.FoxTrainer:Start()
    end)
end

function AAPVE_MOOSE:StopFoxTrainer()
    if self.FoxTrainer then
        pcall(function()
            self.FoxTrainer:Stop()
        end)

        self.FoxTrainer = nil
    end
end

---------------------------------------------------------------------------
-- CAP package zone helpers.
---------------------------------------------------------------------------

function AAPVE_MOOSE:IsCapZoneAlreadyAssigned(capZone)
    if not capZone then
        return false
    end

    for _, package in pairs(self.CapPackages) do
        if package
                and package.Status ~= "Closed"
                and package.AssignedZone
                and package.AssignedZone.Name == capZone.Name then
            return true
        end
    end

    return false
end

function AAPVE_MOOSE:GetAvailableCapZone()
    local availableZones = {}

    for _, capZone in ipairs(self.BlueCapZones) do
        if capZone and capZone.Zone and not self:IsCapZoneAlreadyAssigned(capZone) then
            availableZones[#availableZones + 1] = capZone
        end
    end

    if #availableZones == 0 then
        return nil
    end

    return availableZones[math.random(1, #availableZones)]
end

function AAPVE_MOOSE:GetCapPackageCount()
    local count = 0

    for _, package in pairs(self.CapPackages) do
        if package and package.Status ~= "Closed" then
            count = count + 1
        end
    end

    return count
end

---------------------------------------------------------------------------
-- CAP package membership.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetClientsNearLead(leadClient, radiusNm)
    local members = {}
    local memberNames = {}

    if not leadClient or not leadClient:IsAlive() then
        return members, memberNames
    end

    local leadCoord = leadClient:GetCoordinate()

    if not leadCoord then
        return members, memberNames
    end

    local radiusMeters = UTILS.NMToMeters(radiusNm or self.CapCheckInRadiusNm or 0.5)

    self.BlueClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local clientCoord = client:GetCoordinate()

            if clientCoord then
                local distanceMeters = leadCoord:Get2DDistance(clientCoord)

                if distanceMeters <= radiusMeters then
                    local unitName = self:GetClientUnitName(client)

                    if unitName then
                        members[unitName] = true
                        memberNames[#memberNames + 1] = self:GetClientDisplayName(client)
                    end
                end
            end
        end
    end)

    return members, memberNames
end

function AAPVE_MOOSE:GetCapPackageByMemberUnit(unitName)
    if not unitName then
        return nil
    end

    for _, package in pairs(self.CapPackages) do
        if package
                and package.Status ~= "Closed"
                and package.MemberUnits
                and package.MemberUnits[unitName] then
            return package
        end
    end

    return nil
end

function AAPVE_MOOSE:GetCapPackageByLeadUnit(unitName)
    if not unitName then
        return nil
    end

    for _, package in pairs(self.CapPackages) do
        if package
                and package.Status ~= "Closed"
                and package.LeadUnitName == unitName then
            return package
        end
    end

    return nil
end

function AAPVE_MOOSE:IsClientInAnyActiveCapPackage(unitName)
    return self:GetCapPackageByMemberUnit(unitName) ~= nil
end

function AAPVE_MOOSE:GetCapPackageByHostileGroupName(groupName)
    if not groupName then
        return nil
    end

    for _, package in pairs(self.CapPackages) do
        if package
                and package.Status ~= "Closed"
                and package.ActiveHostileGroup
                and package.ActiveHostileGroup:GetName() == groupName then
            return package
        end
    end

    return nil
end

function AAPVE_MOOSE:GetGlobalActiveHostileCount()
    local count = 0

    for _, package in pairs(self.CapPackages) do
        if package
                and package.Status ~= "Closed"
                and package.ActiveHostileGroup
                and package.ActiveHostileGroup:IsAlive() then
            count = count + 1
        end
    end

    return count
end

---------------------------------------------------------------------------
-- CAP package marker / tasking.
---------------------------------------------------------------------------

function AAPVE_MOOSE:RemoveCapPackageMarker(package)
    if package and package.MarkerId then
        pcall(function()
            COORDINATE:RemoveMark(package.MarkerId)
        end)

        package.MarkerId = nil
    end
end

function AAPVE_MOOSE:MarkCapPackage(package)
    if not package or not package.AssignedZone or not package.AssignedZone.Zone then
        return
    end

    local coord = package.AssignedZone.Zone:GetCoordinate()

    if not coord then
        return
    end

    local bullseye = self:GetBullseyeText(coord)
    local memberText = table.concat(package.MemberNames or {}, ", ")

    if memberText == "" then
        memberText = "Unknown"
    end

    self:RemoveCapPackageMarker(package)

    package.MarkerId = coord:MarkToCoalition(
            string.format(
                    "A/A PVE CAP PACKAGE %d\nLead: %s\nHold: %s\n%s\nStatus: %s\nMembers: %s",
                    package.Id,
                    package.LeadClientName or "Unknown",
                    package.AssignedZone.Name or "Unknown CAP",
                    bullseye,
                    package.Status or "Unknown",
                    memberText
            ),
            coalition.side.BLUE,
            true
    )
end

function AAPVE_MOOSE:SendCapPackageTasking(package, reminder)
    if not package or not package.AssignedZone or not package.AssignedZone.Zone then
        return
    end

    local coord = package.AssignedZone.Zone:GetCoordinate()
    local bullseye = self:GetBullseyeText(coord)
    local prefix = "CAP check-in accepted"

    if reminder then
        prefix = "CAP tasking reminder"
    end

    local memberText = table.concat(package.MemberNames or {}, ", ")

    if memberText == "" then
        memberText = "Unknown"
    end

    self:BlueMessage(
            string.format(
                    "A/A PVE %s\nPackage: %d\nLead: %s\nHold: %s\nPosition: %s\nMembers: %s\nProceed as a flight and hold CAP.",
                    prefix,
                    package.Id,
                    package.LeadClientName or "Unknown",
                    package.AssignedZone.Name or "Unknown",
                    bullseye,
                    memberText
            ),
            30
    )

    self:MarkCapPackage(package)

    self:SendTTS(
            string.format(
                    "Magic, CAP package %d, proceed to %s, %s. Hold CAP and sanitize.",
                    package.Id,
                    package.AssignedZone.Name or "assigned CAP",
                    bullseye
            )
    )
end

function AAPVE_MOOSE:RetaskPackageToCap(package, reason)
    if not package or not package.AssignedZone or not package.AssignedZone.Zone then
        return
    end

    local coord = package.AssignedZone.Zone:GetCoordinate()
    local bullseye = self:GetBullseyeText(coord)

    package.Status = "Retasking"
    package.CommitAnnounced = false
    package.ActiveHostileGroup = nil
    package.LastPictureSpawnTime = nil

    self:MarkCapPackage(package)

    self:BlueMessage(
            string.format(
                    "A/A PVE Range\nPackage %d: %s\nResume assigned CAP: %s\nPosition: %s\nPicture will resume once package is back on station.",
                    package.Id,
                    reason or "Threat neutralized.",
                    package.AssignedZone.Name or "Assigned CAP",
                    bullseye
            ),
            30
    )

    self:SendTTS(
            string.format(
                    "Magic, CAP package %d, %s Resume %s, %s. Picture will resume when back on station.",
                    package.Id,
                    reason or "threat neutralized.",
                    package.AssignedZone.Name or "assigned CAP",
                    bullseye
            )
    )
end

---------------------------------------------------------------------------
-- CAP check-in.
---------------------------------------------------------------------------

function AAPVE_MOOSE:RequestCapCheckIn(leadClient)
    if not leadClient or not leadClient:IsAlive() then
        self:BlueMessage("A/A PVE Range: unable to check in. Client is not active.", 10)
        return nil
    end

    if self.CurrentMode ~= "BlueCapDefense" then
        self:BlueMessage("A/A PVE Range: BLUE CAP Defense mode is not active.", 10)
        return nil
    end

    local leadUnitName = self:GetClientUnitName(leadClient)

    if not leadUnitName then
        self:BlueMessage("A/A PVE Range: unable to determine flight lead unit.", 10)
        return nil
    end

    local existingLeadPackage = self:GetCapPackageByLeadUnit(leadUnitName)

    if existingLeadPackage then
        self:SendCapPackageTasking(existingLeadPackage, true)
        return existingLeadPackage
    end

    if self:IsClientInAnyActiveCapPackage(leadUnitName) then
        local existingPackage = self:GetCapPackageByMemberUnit(leadUnitName)

        if existingPackage then
            self:BlueMessage(
                    string.format(
                            "A/A PVE Range: you are already assigned to CAP Package %d.",
                            existingPackage.Id
                    ),
                    10
            )

            self:SendCapPackageTasking(existingPackage, true)
        end

        return existingPackage
    end

    if self:GetCapPackageCount() >= self.MaxCapPackages then
        self:BlueMessage("A/A PVE Range: no additional CAP packages are available.", 10)
        return nil
    end

    local capZone = self:GetAvailableCapZone()

    if not capZone then
        self:BlueMessage("A/A PVE Range: all CAP zones are currently assigned.", 10)
        return nil
    end

    local memberUnits, memberNames = self:GetClientsNearLead(leadClient, self.CapCheckInRadiusNm)

    if not memberUnits[leadUnitName] then
        memberUnits[leadUnitName] = true
        memberNames[#memberNames + 1] = self:GetClientDisplayName(leadClient)
    end

    local package = {
        Id = self.NextCapPackageId,
        LeadClientName = self:GetClientDisplayName(leadClient),
        LeadUnitName = leadUnitName,
        AssignedZone = capZone,
        MemberUnits = memberUnits,
        MemberNames = memberNames,
        MarkerId = nil,
        Status = "Assigned",
        EmptySince = nil,
        ActiveHostileGroup = nil,
        LastKnownHostileCoordinate = nil,
        LastKnownHostileName = nil,
        CommitAnnounced = false,
        LastPictureSpawnTime = nil
    }

    self.NextCapPackageId = self.NextCapPackageId + 1
    self.CapPackages[#self.CapPackages + 1] = package

    self:SendCapPackageTasking(package, false)

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: CAP Package %d checked in by %s. Members: %s.",
                    package.Id,
                    package.LeadClientName,
                    table.concat(package.MemberNames or {}, ", ")
            ),
            20
    )

    return package
end

---------------------------------------------------------------------------
-- Client counting.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetCapPackageAssignedClientCount(package)
    local count = 0

    if not package or not package.MemberUnits then
        return 0
    end

    self.BlueClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local unitName = self:GetClientUnitName(client)
            local coord = client:GetCoordinate()

            if unitName
                    and package.MemberUnits[unitName]
                    and coord
                    and package.AssignedZone
                    and package.AssignedZone.Zone
                    and package.AssignedZone.Zone:IsCoordinateInZone(coord) then
                count = count + 1
            end
        end
    end)

    return count
end

function AAPVE_MOOSE:GetCapPackageSandboxClientCount(package)
    local count = 0

    if not package or not package.MemberUnits or not self.SandboxZone then
        return 0
    end

    self.BlueClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            local unitName = self:GetClientUnitName(client)
            local coord = client:GetCoordinate()

            if unitName
                    and package.MemberUnits[unitName]
                    and coord
                    and self.SandboxZone:IsCoordinateInZone(coord) then
                count = count + 1
            end
        end
    end)

    return count
end

function AAPVE_MOOSE:GetCapPackageRepresentativeClientCoordinate(package)
    if not package or not package.MemberUnits then
        return nil
    end

    local bestCoord = nil

    self.BlueClientSet:ForEachClient(function(client)
        if bestCoord then
            return
        end

        if client and client:IsAlive() then
            local unitName = self:GetClientUnitName(client)

            if unitName and package.MemberUnits[unitName] then
                bestCoord = client:GetCoordinate()
            end
        end
    end)

    return bestCoord
end

function AAPVE_MOOSE:GetHostileGroupSizeForCapPackage(package)
    local playerCount = self:GetCapPackageSandboxClientCount(package)

    if playerCount <= 1 then
        return 1
    end

    if playerCount == 2 then
        return 2
    end

    if playerCount == 3 then
        return 2
    end

    return 4
end

---------------------------------------------------------------------------
-- Package monitor / commit logic.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartCapPackageMonitor()
    if self.CapPackageMonitorScheduler then
        self.CapPackageMonitorScheduler:Stop()
        self.CapPackageMonitorScheduler = nil
    end

    self.CapPackageMonitorScheduler = SCHEDULER:New(nil, function()
        AAPVE_MOOSE:MonitorCapPackages()
    end, {}, 5, self.CapPackageMonitorSeconds)
end

function AAPVE_MOOSE:MonitorCapPackages()
    if self.CurrentMode ~= "BlueCapDefense" then
        return
    end

    for _, package in pairs(self.CapPackages) do
        if package and package.Status ~= "Closed" then
            self:MonitorSingleCapPackage(package)
            self:MonitorPackageCommit(package)
        end
    end
end

function AAPVE_MOOSE:MonitorSingleCapPackage(package)
    if not package or not package.AssignedZone or not package.AssignedZone.Zone then
        return
    end

    local onStationCount = self:GetCapPackageAssignedClientCount(package)
    local sandboxCount = self:GetCapPackageSandboxClientCount(package)

    if onStationCount > 0 then
        if package.Status == "Assigned" or package.Status == "Retasking" then
            self:BlueMessage(
                    string.format(
                            "A/A PVE Range: CAP Package %d is on station.",
                            package.Id
                    ),
                    10
            )

            self:SendTTS(
                    string.format(
                            "Magic, CAP package %d is on station. Picture generation active.",
                            package.Id
                    )
            )
        end

        if package.Status ~= "Committed" then
            package.Status = "OnStation"
        end

        package.EmptySince = nil
        self:MarkCapPackage(package)
        return
    end

    if sandboxCount > 0 then
        package.EmptySince = nil
        return
    end

    if package.Status == "Assigned"
            or package.Status == "OnStation"
            or package.Status == "Committed"
            or package.Status == "Retasking" then

        if not package.EmptySince then
            package.EmptySince = timer.getTime()

            self:BlueMessage(
                    string.format(
                            "A/A PVE Range: CAP Package %d has no assigned clients inside the sandbox. Package will close in 5 minutes if empty.",
                            package.Id
                    ),
                    15
            )

            return
        end

        local emptyFor = timer.getTime() - package.EmptySince

        if emptyFor >= self.CapPackageEmptyCleanupSeconds then
            self:CloseCapPackage(package, "Sandbox empty for assigned package clients for 5 minutes.")
        end
    end
end

function AAPVE_MOOSE:MonitorPackageCommit(package)
    if not package
            or package.Status ~= "OnStation"
            or package.CommitAnnounced
            or not package.ActiveHostileGroup
            or not package.ActiveHostileGroup:IsAlive()
            or not package.AssignedZone
            or not package.AssignedZone.Zone then
        return
    end

    local capCoord = package.AssignedZone.Zone:GetCoordinate()
    local clientCoord = self:GetCapPackageRepresentativeClientCoordinate(package)
    local hostileCoord = package.ActiveHostileGroup:GetCoordinate()

    if not capCoord or not clientCoord or not hostileCoord then
        return
    end

    local distanceFromCapNm = UTILS.MetersToNM(clientCoord:Get2DDistance(capCoord))

    if distanceFromCapNm < self.CommitCheckDistanceFromCapNm then
        return
    end

    local capToClient = self:GetBearingDegrees(capCoord, clientCoord)
    local capToHostile = self:GetBearingDegrees(capCoord, hostileCoord)
    local headingDiff = self:GetHeadingDifferenceDegrees(capToClient, capToHostile)

    if headingDiff <= self.CommitHeadingToleranceDegrees then
        package.Status = "Committed"
        package.CommitAnnounced = true

        self:BlueMessage(
                string.format(
                        "A/A PVE Range: CAP Package %d is committed to the hostile picture.",
                        package.Id
                ),
                10
        )

        self:SendTTS(
                string.format(
                        "Magic, CAP package %d committed.",
                        package.Id
                )
        )

        self:MarkCapPackage(package)
    end
end

---------------------------------------------------------------------------
-- Picture generation.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartCapPackagePictureScheduler()
    if self.CapPackagePictureScheduler then
        self.CapPackagePictureScheduler:Stop()
        self.CapPackagePictureScheduler = nil
    end

    self.CapPackagePictureScheduler = SCHEDULER:New(nil, function()
        AAPVE_MOOSE:GeneratePicturesForCapPackages()
    end, {}, 30, self.CapPackagePictureIntervalSeconds)
end

function AAPVE_MOOSE:GeneratePicturesForCapPackages()
    if self.CurrentMode ~= "BlueCapDefense" then
        return
    end

    for _, package in pairs(self.CapPackages) do
        if package and package.Status == "OnStation" then
            self:GeneratePictureForCapPackage(package)
        end
    end
end

function AAPVE_MOOSE:GeneratePictureForCapPackage(package)
    if not package or package.Status ~= "OnStation" then
        return
    end

    if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
        return
    end

    if self.UseGlobalHostileLimit and self:GetGlobalActiveHostileCount() >= self.MaxGlobalHostileGroups then
        return
    end

    local playerCount = self:GetCapPackageSandboxClientCount(package)

    if playerCount <= 0 then
        return
    end

    local roll = math.random(1, 100)
    local hostileLimit = self.PictureHostileChance
    local neutralLimit = self.PictureHostileChance + self.PictureNeutralChance

    if roll <= hostileLimit then
        self:SpawnHostileForCapPackage(package)
    elseif roll <= neutralLimit then
        self:SpawnNeutralForCapPackage(package)
    else
        self:SpawnFriendlyForCapPackage(package)
    end
end

function AAPVE_MOOSE:SpawnHostileForCapPackage(package)
    local option = self:GetRandomOption(self.PictureHostileTemplates)
    local spawnZone = self:GetRandomRedSpawnZone()

    if not option or not spawnZone then
        self:BlueMessage("A/A PVE Range: hostile spawn failed. Missing template or RED spawn zone.", 10)
        return
    end

    local groupSize = self:GetHostileGroupSizeForCapPackage(package)

    local spawn = SPAWN:NewWithAlias(
            option.Template,
            string.format(
                    "AAPVE_PKG%d_HOSTILE_%s",
                    package.Id,
                    self:GetSanitizedName(option.Name)
            )
    )
                       :InitRandomizeZones({ spawnZone })
                       :InitGrouping(groupSize)
                       :InitSkill("Random")

    local group = spawn:Spawn()

    if not group then
        self:BlueMessage(
                string.format("A/A PVE Range: hostile spawn failed for CAP Package %d.", package.Id),
                10
        )
        return
    end

    self:AddActiveGroup(group)

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            return
        end

        pcall(function()
            group:OptionAlarmStateRed()
        end)

        pcall(function()
            group:OptionROEOpenFire()
        end)

        local destination = package.AssignedZone.Zone:GetCoordinate()

        if destination then
            local task = group:TaskRouteToVec2(
                    destination:GetVec2(),
                    math.random(self.PictureMinSpeed, self.PictureMaxSpeed),
                    math.random(self.PictureMinAltitude, self.PictureMaxAltitude),
                    "BARO"
            )

            if task then
                group:SetTask(task)
            end
        end
    end, {}, 2)

    package.ActiveHostileGroup = group
    package.LastKnownHostileCoordinate = group:GetCoordinate()
    package.LastKnownHostileName = group:GetName()
    package.CommitAnnounced = false
    package.LastPictureSpawnTime = timer.getTime()

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: hostile picture generated for CAP Package %d. %s x%d.",
                    package.Id,
                    option.Name,
                    groupSize
            ),
            10
    )

    self:SendTTS(
            string.format(
                    "Magic, CAP package %d, picture update. Hostile group inbound.",
                    package.Id
            )
    )
end

function AAPVE_MOOSE:SpawnNeutralForCapPackage(package)
    local option = self:GetRandomOption(self.PictureNeutralTemplates)

    if option then
        self:SpawnNonHostileForCapPackage(package, option, "NEUTRAL")
    end
end

function AAPVE_MOOSE:SpawnFriendlyForCapPackage(package)
    local option = self:GetRandomOption(self.PictureFriendlyTemplates)

    if option then
        self:SpawnNonHostileForCapPackage(package, option, "FRIENDLY")
    end
end

function AAPVE_MOOSE:SpawnNonHostileForCapPackage(package, option, role)
    local spawnZone = self:GetRandomRedSpawnZone()

    if not spawnZone then
        self:BlueMessage("A/A PVE Range: non-hostile spawn failed. No RED spawn zone.", 10)
        return
    end

    local spawn = SPAWN:NewWithAlias(
            option.Template,
            string.format(
                    "AAPVE_PKG%d_%s_%s",
                    package.Id,
                    role,
                    self:GetSanitizedName(option.Name)
            )
    )
                       :InitRandomizeZones({ spawnZone })
                       :InitGrouping(1)
                       :InitSkill("Random")

    local group = spawn:Spawn()

    if not group then
        self:BlueMessage(
                string.format("A/A PVE Range: %s spawn failed for CAP Package %d.", role, package.Id),
                10
        )
        return
    end

    self:AddActiveGroup(group)

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            return
        end

        pcall(function()
            group:OptionAlarmStateRed()
        end)

        pcall(function()
            group:OptionROEHoldFire()
        end)

        pcall(function()
            group:OptionROTPassiveDefense()
        end)

        local destination = nil
        local recoveryZone = self:GetRandomRecoveryZone()

        if recoveryZone then
            destination = recoveryZone:GetCoordinate()
        elseif self.ProtectedZone then
            destination = self.ProtectedZone:GetCoordinate()
        end

        if destination then
            local task = group:TaskRouteToVec2(
                    destination:GetVec2(),
                    math.random(self.PictureMinSpeed, self.PictureMaxSpeed),
                    math.random(self.PictureMinAltitude, self.PictureMaxAltitude),
                    "BARO"
            )

            if task then
                group:SetTask(task)
            end
        end
    end, {}, 2)

    local lifetime = math.random(
            self.NonHostileMinLifetimeSeconds,
            self.NonHostileMaxLifetimeSeconds
    )

    SCHEDULER:New(nil, function()
        if group and group:IsAlive() then
            group:Destroy()
        end
    end, {}, lifetime)

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: %s track generated for CAP Package %d.",
                    role,
                    package.Id
            ),
            10
    )
end

---------------------------------------------------------------------------
-- Timeline spawn functions.
---------------------------------------------------------------------------

function AAPVE_MOOSE:GetTimelineBanditTemplate()
    local option = self:GetRandomOption(self.RedCapTemplates)

    if option and option.Template then
        return option.Template, option.Name
    end

    return self.TimelineDefaultTemplate, self.TimelineDefaultTemplate
end

function AAPVE_MOOSE:SpawnTimelineBanditForClient(client, timelineName)
    if not client or not client:IsAlive() then
        self:BlueMessage("A/A PVE Range: timeline spawn failed. Client is not alive.", 10)
        return
    end

    local timeline = self.TimelineSpawnOptions[timelineName]

    if not timeline then
        self:BlueMessage("A/A PVE Range: invalid timeline selection.", 10)
        return
    end

    local clientCoord = client:GetCoordinate()

    if not clientCoord then
        self:BlueMessage("A/A PVE Range: timeline spawn failed. No client coordinate.", 10)
        return
    end

    local clientHeading = self:GetClientHeadingDegrees(client)
    local distanceMeters = UTILS.NMToMeters(timeline.DistanceNm)

    local spawnCoord = clientCoord:Translate(distanceMeters, clientHeading)

    local templateName, aircraftName = self:GetTimelineBanditTemplate()

    local alias = string.format(
            "AAPVE_TIMELINE_%s_%s",
            timelineName,
            self:GetSanitizedName(aircraftName)
    )

    local spawn = SPAWN:NewWithAlias(templateName, alias)
                       :InitGrouping(self.TimelineDefaultGroupSize)
                       :InitSkill("Random")

    pcall(function()
        spawn:InitHeading((clientHeading + 180) % 360)
    end)

    local group = nil

    pcall(function()
        group = spawn:SpawnFromCoordinate(spawnCoord)
    end)

    if not group then
        self:BlueMessage(
                string.format(
                        "A/A PVE Range: %s timeline spawn failed. Check template %s.",
                        timeline.Label,
                        templateName
                ),
                10
        )
        return
    end

    self:AddActiveGroup(group)

    group.AAPVETimelineMode = timelineName
    group.AAPVEAssignedClientName = client:GetName()

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            return
        end

        pcall(function()
            group:OptionAlarmStateRed()
        end)

        if timeline.RoeAtSpawn == "HoldFire" then
            pcall(function()
                group:OptionROEHoldFire()
            end)
        else
            pcall(function()
                group:OptionROEOpenFire()
            end)
        end

        local freshClient = CLIENT:FindByName(client:GetName())

        if not freshClient or not freshClient:IsAlive() then
            return
        end

        local targetGroup = freshClient:GetGroup()

        if targetGroup then
            local attackTask = group:TaskAttackGroup(targetGroup)

            if attackTask then
                group:SetTask(attackTask)
            end
        end
    end, {}, 2)

    if timeline.OpenFireAfterMerge then
        self:StartBFMMergeMonitor(group, client:GetName(), timeline.MergeDistanceNm or 1.0)
    end

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: %s timeline spawned %s at %d NM, hot.",
                    timeline.Label,
                    aircraftName,
                    timeline.DistanceNm
            ),
            10
    )

    self:SendTTS(
            string.format(
                    "Magic, %s timeline set. Bandit spawned %d miles hot.",
                    timeline.Label,
                    timeline.DistanceNm
            )
    )
end

function AAPVE_MOOSE:StartBFMMergeMonitor(group, clientUnitName, mergeDistanceNm)
    if not group or not clientUnitName then
        return
    end

    local scheduler = nil

    scheduler = SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            if scheduler then
                scheduler:Stop()
            end

            return
        end

        local client = CLIENT:FindByName(clientUnitName)

        if not client or not client:IsAlive() then
            if scheduler then
                scheduler:Stop()
            end

            return
        end

        local groupCoord = group:GetCoordinate()
        local clientCoord = client:GetCoordinate()

        if not groupCoord or not clientCoord then
            return
        end

        local distanceNm = UTILS.MetersToNM(groupCoord:Get2DDistance(clientCoord))

        if distanceNm <= mergeDistanceNm then
            pcall(function()
                group:OptionROEOpenFire()
            end)

            self:BlueMessage("A/A PVE Range: BFM merge detected. RED weapons free.", 10)
            self:SendTTS("Fight's on. Red weapons free.")

            if scheduler then
                scheduler:Stop()
            end
        end
    end, {}, 2, 2)
end

---------------------------------------------------------------------------
-- Close / cleanup.
---------------------------------------------------------------------------

function AAPVE_MOOSE:CloseCapPackage(package, reason)
    if not package or package.Status == "Closed" then
        return
    end

    package.Status = "Closed"

    if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
        self:DestroyGroup(package.ActiveHostileGroup)
    end

    package.ActiveHostileGroup = nil
    package.LastKnownHostileCoordinate = nil
    package.MemberUnits = {}
    package.MemberNames = {}
    package.EmptySince = nil

    self:RemoveCapPackageMarker(package)

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: CAP Package %d closed. %s",
                    package.Id,
                    reason or ""
            ),
            15
    )
end

function AAPVE_MOOSE:ClearCapPackages()
    for _, package in pairs(self.CapPackages) do
        if package and package.Status ~= "Closed" then
            self:CloseCapPackage(package, "Range cleared.")
        end
    end

    self.CapPackages = {}
    self.NextCapPackageId = 1
end

---------------------------------------------------------------------------
-- Modes.
---------------------------------------------------------------------------

function AAPVE_MOOSE:StartRedCapPracticeMode()
    self:ClearRange(false)

    self:BlueMessage(
            "A/A PVE Range: RED CAP Target Practice mode active. Use manual RED CAP spawn or timeline spawns.",
            15
    )

    self:SendTTS("Magic, A/A PVE Range RED CAP target practice mode is active.")
end

function AAPVE_MOOSE:StartBlueCapDefenseMode()
    self:ClearRange(false)
    self:StartBlueChief()
    self:StartCapPackageMonitor()
    self:StartCapPackagePictureScheduler()

    self:BlueMessage(
            "A/A PVE Range: BLUE CAP Defense mode active. Use CAP Check-in Client Selector from the range menu.",
            20
    )

    self:SendTTS("Magic, A/A PVE Range BLUE CAP defense mode is active. Flight leads may check in for CAP tasking.")
end

function AAPVE_MOOSE:SpawnManualRedCap(templateOption, count, skill)
    if not templateOption then
        return
    end

    local spawnZone = self:GetRandomRedSpawnZone()

    if not spawnZone then
        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed. No RED spawn zone.", 10)
        return
    end

    local groupSize = count or 2
    local groupSkill = skill or "Random"

    local spawn = SPAWN:NewWithAlias(
            templateOption.Template,
            "AAPVE_REDCAP_" .. self:GetSanitizedName(templateOption.Name)
    )
                       :InitRandomizeZones({ spawnZone })
                       :InitGrouping(groupSize)
                       :InitSkill(groupSkill)

    local group = spawn:Spawn()

    if not group then
        self:BlueMessage("A/A PVE Range: manual RED CAP spawn failed.", 10)
        return
    end

    self:AddActiveGroup(group)

    SCHEDULER:New(nil, function()
        if not group or not group:IsAlive() then
            return
        end

        pcall(function()
            group:OptionAlarmStateRed()
        end)

        pcall(function()
            group:OptionROEOpenFire()
        end)

        local capCoord = self.RedCapZone:GetCoordinate()

        if capCoord then
            local task = group:TaskOrbitCircleAtVec2(
                    capCoord:GetVec2(),
                    24000,
                    450
            )

            if task then
                group:SetTask(task)
            end
        end
    end, {}, 2)

    self:BlueMessage(
            string.format(
                    "A/A PVE Range: spawned RED CAP %s x%d.",
                    templateOption.Name,
                    groupSize
            ),
            10
    )
end

---------------------------------------------------------------------------
-- Events.
---------------------------------------------------------------------------

AAPVE_MOOSE.EventHandler = EVENTHANDLER:New()
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Dead)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Crash)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.PilotDead)
AAPVE_MOOSE.EventHandler:HandleEvent(EVENTS.Kill)

function AAPVE_MOOSE.EventHandler:OnEventDead(EventData)
    AAPVE_MOOSE:HandleDeathEvent(EventData)
end

function AAPVE_MOOSE.EventHandler:OnEventCrash(EventData)
    AAPVE_MOOSE:HandleDeathEvent(EventData)
end

function AAPVE_MOOSE.EventHandler:OnEventPilotDead(EventData)
    AAPVE_MOOSE:HandleDeathEvent(EventData)
end

function AAPVE_MOOSE.EventHandler:OnEventKill(EventData)
    AAPVE_MOOSE:HandleKillEvent(EventData)
end

function AAPVE_MOOSE:HandleDeathEvent(EventData)
    if not EventData or not EventData.IniUnit then
        return
    end

    local deadGroup = EventData.IniUnit:GetGroup()

    if not deadGroup then
        return
    end

    local package = self:GetCapPackageByHostileGroupName(deadGroup:GetName())

    if not package then
        return
    end

    SCHEDULER:New(nil, function()
        if package.ActiveHostileGroup and not package.ActiveHostileGroup:IsAlive() then
            local packageId = package.Id
            package.ActiveHostileGroup = nil

            self:RetaskPackageToCap(
                    package,
                    "Hostile group neutralized."
            )

            self:Log("Package " .. tostring(packageId) .. " hostile neutralized and retasked.")
        end
    end, {}, 2)
end

function AAPVE_MOOSE:HandleKillEvent(EventData)
    if not EventData then
        return
    end

    local killer = EventData.IniUnit
    local victim = EventData.TgtUnit

    if not killer or not victim then
        return
    end

    local killerGroup = killer:GetGroup()

    if not killerGroup then
        return
    end

    local package = self:GetCapPackageByHostileGroupName(killerGroup:GetName())

    if not package then
        return
    end

    if victim:GetCoalition() == coalition.side.BLUE then
        self:BlueMessage(
                string.format(
                        "A/A PVE Range: RED AI killed a Blue client in CAP Package %d. Hostile group despawning.",
                        package.Id
                ),
                10
        )

        self:DestroyGroup(package.ActiveHostileGroup)
        package.ActiveHostileGroup = nil

        self:RetaskPackageToCap(
                package,
                "Blue aircraft down. Hostile removed."
        )
    end
end

---------------------------------------------------------------------------
-- Coalition menus only.
---------------------------------------------------------------------------

function AAPVE_MOOSE:BuildTimelineClientMenus(parentMenu)
    if not parentMenu then
        return
    end

    self.TimelineClientMenus = self.TimelineClientMenus or {}

    for _, menuItem in pairs(self.TimelineClientMenus) do
        if menuItem and menuItem.Remove then
            pcall(function()
                menuItem:Remove()
            end)
        end
    end

    self.TimelineClientMenus = {}

    local bvrMenu = MENU_COALITION:New(coalition.side.BLUE, "BVR - 80 NM Hot", parentMenu)
    local wvrMenu = MENU_COALITION:New(coalition.side.BLUE, "WVR - 20 NM Hot", parentMenu)
    local bfmMenu = MENU_COALITION:New(coalition.side.BLUE, "BFM - 5 NM Hold Fire Until Merge", parentMenu)

    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = bvrMenu
    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = wvrMenu
    self.TimelineClientMenus[#self.TimelineClientMenus + 1] = bfmMenu

    local clientCount = 0

    self.BlueClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            clientCount = clientCount + 1

            local clientName = client:GetName()
            local displayName = self:GetClientDisplayName(client)

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    displayName,
                    bvrMenu,
                    function()
                        local selectedClient = CLIENT:FindByName(clientName)

                        if selectedClient then
                            AAPVE_MOOSE:SpawnTimelineBanditForClient(selectedClient, "BVR")
                        end
                    end
            )

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    displayName,
                    wvrMenu,
                    function()
                        local selectedClient = CLIENT:FindByName(clientName)

                        if selectedClient then
                            AAPVE_MOOSE:SpawnTimelineBanditForClient(selectedClient, "WVR")
                        end
                    end
            )

            self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    displayName,
                    bfmMenu,
                    function()
                        local selectedClient = CLIENT:FindByName(clientName)

                        if selectedClient then
                            AAPVE_MOOSE:SpawnTimelineBanditForClient(selectedClient, "BFM")
                        end
                    end
            )
        end
    end)

    if clientCount == 0 then
        self.TimelineClientMenus[#self.TimelineClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE,
                "No active BLUE clients found",
                parentMenu,
                function()
                    AAPVE_MOOSE:BlueMessage("A/A PVE Range: no active BLUE clients found. Try refresh after clients spawn.", 10)
                end
        )
    end

    self:BlueMessage("A/A PVE Range: timeline client list refreshed.", 10)
end

function AAPVE_MOOSE:BuildCapCheckInClientMenus(parentMenu)
    if not parentMenu then
        return
    end

    self.CapCheckInClientMenus = self.CapCheckInClientMenus or {}

    for _, menuItem in pairs(self.CapCheckInClientMenus) do
        if menuItem and menuItem.Remove then
            pcall(function()
                menuItem:Remove()
            end)
        end
    end

    self.CapCheckInClientMenus = {}

    local clientCount = 0

    self.BlueClientSet:ForEachClient(function(client)
        if client and client:IsAlive() then
            clientCount = clientCount + 1

            local clientName = client:GetName()
            local displayName = self:GetClientDisplayName(client)

            self.CapCheckInClientMenus[#self.CapCheckInClientMenus + 1] = MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    displayName,
                    parentMenu,
                    function()
                        local selectedClient = CLIENT:FindByName(clientName)

                        if selectedClient then
                            AAPVE_MOOSE:RequestCapCheckIn(selectedClient)
                        end
                    end
            )
        end
    end)

    if clientCount == 0 then
        self.CapCheckInClientMenus[#self.CapCheckInClientMenus + 1] = MENU_COALITION_COMMAND:New(
                coalition.side.BLUE,
                "No active BLUE clients found",
                parentMenu,
                function()
                    AAPVE_MOOSE:BlueMessage("A/A PVE Range: no active BLUE clients found. Try refresh after clients spawn.", 10)
                end
        )
    end

    self:BlueMessage("A/A PVE Range: CAP check-in client list refreshed.", 10)
end

function AAPVE_MOOSE:BuildCoalitionMenus()
    local modeMenu = self:AddMenuItem(MENU_COALITION:New(coalition.side.BLUE, "Mode", self.MenuRoot))

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Start RED CAP Target Practice",
                    modeMenu,
                    function()
                        if AAPVE_MOOSE.CurrentMode ~= "Idle" then
                            AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
                            return
                        end

                        AAPVE_MOOSE.FSM:StartRedCap()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Start BLUE CAP Defense",
                    modeMenu,
                    function()
                        if AAPVE_MOOSE.CurrentMode ~= "Idle" then
                            AAPVE_MOOSE:BlueMessage("A/A PVE Range: stop the current mode first.", 10)
                            return
                        end

                        AAPVE_MOOSE.FSM:StartBlueCap()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Stop Current Mode",
                    modeMenu,
                    function()
                        if AAPVE_MOOSE.CurrentMode == "Idle" then
                            AAPVE_MOOSE:BlueMessage("A/A PVE Range is already idle.", 10)
                            return
                        end

                        AAPVE_MOOSE.FSM:StopMode()
                    end
            )
    )

    local redCapMenu = self:AddMenuItem(MENU_COALITION:New(coalition.side.BLUE, "Manual RED CAP Spawn", self.MenuRoot))

    for _, option in ipairs(self.RedCapTemplates) do
        local selectedOption = option

        self:AddMenuItem(
                MENU_COALITION_COMMAND:New(
                        coalition.side.BLUE,
                        "Spawn " .. selectedOption.Name .. " x1",
                        redCapMenu,
                        function()
                            AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 1, "Random")
                        end
                )
        )

        self:AddMenuItem(
                MENU_COALITION_COMMAND:New(
                        coalition.side.BLUE,
                        "Spawn " .. selectedOption.Name .. " x2",
                        redCapMenu,
                        function()
                            AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 2, "Random")
                        end
                )
        )

        self:AddMenuItem(
                MENU_COALITION_COMMAND:New(
                        coalition.side.BLUE,
                        "Spawn " .. selectedOption.Name .. " x4",
                        redCapMenu,
                        function()
                            AAPVE_MOOSE:SpawnManualRedCap(selectedOption, 4, "Random")
                        end
                )
        )
    end

    local timelineMenu = self:AddMenuItem(MENU_COALITION:New(coalition.side.BLUE, "Timeline Spawn", self.MenuRoot))

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Refresh Timeline Client List",
                    timelineMenu,
                    function()
                        AAPVE_MOOSE:BuildTimelineClientMenus(timelineMenu)
                    end
            )
    )

    self:BuildTimelineClientMenus(timelineMenu)

    local capCheckInMenu = self:AddMenuItem(MENU_COALITION:New(coalition.side.BLUE, "CAP Check-in Client Selector", self.MenuRoot))

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Refresh CAP Check-in Client List",
                    capCheckInMenu,
                    function()
                        AAPVE_MOOSE:BuildCapCheckInClientMenus(capCheckInMenu)
                    end
            )
    )

    self:BuildCapCheckInClientMenus(capCheckInMenu)

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Toggle FOX Missile Trainer",
                    self.MenuRoot,
                    function()
                        AAPVE_MOOSE:ToggleFoxTrainer()
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Clear Range",
                    self.MenuRoot,
                    function()
                        AAPVE_MOOSE:ClearRange(true)
                        AAPVE_MOOSE.CurrentMode = "Idle"
                    end
            )
    )

    self:AddMenuItem(
            MENU_COALITION_COMMAND:New(
                    coalition.side.BLUE,
                    "Show Status",
                    self.MenuRoot,
                    function()
                        AAPVE_MOOSE:ShowStatus()
                    end
            )
    )
end

---------------------------------------------------------------------------
-- Status.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ShowStatus()
    local activeGroups = 0

    for _, group in pairs(self.ActiveGroups) do
        if group and group:IsAlive() then
            activeGroups = activeGroups + 1
        end
    end

    local statusText = string.format(
            "A/A PVE Range Status\nMode: %s\nFOX Trainer: %s\nCAP Packages: %d\nActive Hostiles: %d\nSpawned Groups: %d",
            self.CurrentMode,
            tostring(self.FoxTrainerEnabled),
            self:GetCapPackageCount(),
            self:GetGlobalActiveHostileCount(),
            activeGroups
    )

    for _, package in pairs(self.CapPackages) do
        if package and package.Status ~= "Closed" then
            local onStationCount = self:GetCapPackageAssignedClientCount(package)
            local sandboxCount = self:GetCapPackageSandboxClientCount(package)
            local hostileActive = "No"

            if package.ActiveHostileGroup and package.ActiveHostileGroup:IsAlive() then
                hostileActive = "Yes"
            end

            statusText = statusText .. string.format(
                    "\n\nPackage %d\nLead: %s\nHold: %s\nStatus: %s\nOn Station: %d\nIn Sandbox: %d\nHostile Active: %s",
                    package.Id,
                    package.LeadClientName or "Unknown",
                    package.AssignedZone and package.AssignedZone.Name or "Unknown",
                    package.Status or "Unknown",
                    onStationCount,
                    sandboxCount,
                    hostileActive
            )
        end
    end

    self:BlueMessage(statusText, 25)
end

---------------------------------------------------------------------------
-- Cleanup.
---------------------------------------------------------------------------

function AAPVE_MOOSE:ClearRange(showMessage)
    if self.CapPackageMonitorScheduler then
        pcall(function()
            self.CapPackageMonitorScheduler:Stop()
        end)

        self.CapPackageMonitorScheduler = nil
    end

    if self.CapPackagePictureScheduler then
        pcall(function()
            self.CapPackagePictureScheduler:Stop()
        end)

        self.CapPackagePictureScheduler = nil
    end

    self:ClearCapPackages()

    for _, group in pairs(self.ActiveGroups) do
        self:DestroyGroup(group)
    end

    self.ActiveGroups = {}

    self:StopBlueChief()
    self:StopRedDispatcher()

    if showMessage ~= false then
        self:BlueMessage("A/A PVE Range cleared.", 10)
    end
end

function AAPVE_MOOSE:Stop()
    self:ClearRange(false)
    self:StopFoxTrainer()

    if self.FSM then
        pcall(function()
            self.FSM:Shutdown()
        end)
    end
end

---------------------------------------------------------------------------
-- Start.
---------------------------------------------------------------------------

function AAPVE_MOOSE:Start()
    self:BuildCoalitionMenus()
    self.FSM:Start()

    self:BlueMessage("A/A PVE Range MOOSE version initialized.", 10)
    self:Log("Initialized.")
end

AAPVE_MOOSE:Start()