local DetectionGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes("EW"):FilterStart()

Blue_Chief = CHIEF:New(coalition.side.BLUE, DetectionGroup,"Blue Chief")
Blue_Chief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

local ZoneBlueBorder=ZONE:New("Blue Border")
Blue_Chief:AddBorderZone(ZoneBlueBorder)
Blue_Chief:AddAirwing(AMAW)

for _, zone in pairs(awacsZones) do
    Blue_Chief:AddAwacsZone(zone.zone,zone.alt,zone.spd,zone.hdg,zone.leg)
end

Blue_Chief:Start()

Blue_Chief:AddMission(southAAR)
Blue_Chief:AddMission(northAAR)

