
-- Copied from the Falklands Island IADS Mission scripts


local IADSDebug = true
do
    --Island IADS
    islandIADS = SkynetIADS:create('Island System')
    islandIADS:addSAMSitesByPrefix('SAM1')
    islandIADS:addEarlyWarningRadarsByPrefix('EW1')
    islandIADS:addRadioMenu()
    islandIADS:activate()

end

--DEBUG (Comment out prior to final mission or there will be an overlay)
 if IADSDebug == true then  
    local islandIADSDebug = islandIADS:getDebugSettings()
    islandIADSDebug.IADSStatus = true
    islandIADSDebug.radarWentDark = true
    islandIADSDebug.contacts = true
    islandIADSDebug.radarWentLive = true
    islandIADSDebug.noWorkingCommmandCenter = true
    islandIADSDebug.samNoConnection = true
    islandIADSDebug.addedEWRadar = true
    islandIADSDebug.harmDefence = true
end