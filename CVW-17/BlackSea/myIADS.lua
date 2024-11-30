redIADS = SkynetIADS:create('Enemy IADS')
redIADS:addSAMSitesByPrefix('Skynet-SAM')
redIADS:addEarlyWarningRadarsByPrefix('EW')
redIADS:setupSAMSitesAndThenActivate()


