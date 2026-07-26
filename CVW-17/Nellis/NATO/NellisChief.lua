local NellisDetection = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes("NellisEW"):FilterStart()
NellisChief = CHIEF:New(coalition.side.BLUE, NellisDetection,"Nellis Chief")
NellisChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

NellisChief:AddAirwing(NellisAW)

NellisChief:Start()



NellisChief:AddMission(Jade)
NellisChief:AddMission(Coral)
NellisChief:AddMission(Amber)
NellisChief:AddMission(Topaz)
NellisChief:AddMission(Onyx)
NellisChief:AddMission(northAWACS)
NellisChief:AddMission(Pearl)

NASG_ATC:AddAssets(NellisChief)