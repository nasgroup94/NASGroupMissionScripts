local DetectionGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes("EW"):FilterStart()

Blue_Chief = CHIEF:New(coalition.side.BLUE, DetectionGroup,"Blue Chief")
Blue_Chief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

local ZoneBlueBorder=ZONE:New("Blue Border")
Blue_Chief:AddBorderZone(ZoneBlueBorder)
Blue_Chief:AddAirwing(AMAW)

if awacsZones then
    for _, zone in pairs(awacsZones) do
        if zone and zone.zone then
            Blue_Chief:AddAwacsZone(zone.zone, zone.alt, zone.spd, zone.hdg, zone.leg)
        end
    end
else
    env.info("[Blue_Chief] WARNING: awacsZones is nil. No CHIEF AWACS zones added.")
end

Blue_Chief:Start()

Blue_Chief:AddMission(southAAR)
Blue_Chief:AddMission(northAAR)

NASG_ATC:AddAssets(Blue_Chief)

--if northAWACS then
--    Blue_Chief:AddMission(northAWACS)
--end
--
--if southAWACS then
--    Blue_Chief:AddMission(southAWACS)
--end
