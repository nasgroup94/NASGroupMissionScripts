

-- If Flakland Islands are Blue change BlueFalklands to True, and comment out all of the Island IADS script as it will error with no Red units
local BlueFalklands = false
local IADSDebug = false
--Making a constraint to force sites to ignore contacts below 500ft MSL
do
    local function goLiveConstraint(contact)
	return ( contact:getHeightInFeetMSL() > 200 )
    end

-- Section creates and assigns prefixes for all Red IADS

islandIADS = SkynetIADS:create('Island System')
    islandIADS:addSAMSitesByPrefix('SAM1')
    islandIADS:addEarlyWarningRadarsByPrefix('EW1')

southIADS = SkynetIADS:create('South Mainland')
    southIADS:addSAMSitesByPrefix('SAM2')
    southIADS:addEarlyWarningRadarsByPrefix('EW2')

middleIADS = SkynetIADS:create('Middle Mainland')
    middleIADS:addSAMSitesByPrefix('SAM3')
    middleIADS:addEarlyWarningRadarsByPrefix('EW3')

northIADS = SkynetIADS:create('North Mainland')
    northIADS:addSAMSitesByPrefix('SAM4')
    northIADS:addEarlyWarningRadarsByPrefix('EW4')

-- Section adds and changes SAM Site behaviors 
--Falkland Island IADS Settings



--South Mainland IADS Settings
        local southSa15A = southIADS:getSAMSiteByGroupName('SAM2-SA-15 PD')
        -- local southSa15B = southIADS:getSAMSiteByGroupName('SAM2-SA-15PD-2')
        southIADS:getSAMSiteByGroupName('SAM2-SA-10'):setHARMDetectionChance(50):addPointDefence(southSa15A):addGoLiveConstraint('ignore-low-flying-contacts', goLiveConstraint)
        -- southIADS:getSAMSiteByGroupName('SAM2-SA-10-2'):setHARMDetectionChance(65):addPointDefence(southSa15B):addGoLiveConstraint('ignore-low-flying-contacts', goLiveConstraint)

--Middle Mainland IADS Settings
        local middleSa15 = middleIADS:getSAMSiteByGroupName('SAM3-SA-15 PD-1')
        middleIADS:getSAMSiteByGroupName('SAM3-SA-10-1'):setHARMDetectionChance(50):addPointDefence(middleSa15)
        
--North Mainland IADS Settings

end

-- If statement to make the debug to one varible. 
if IADSDebug == true then
    islandIADS:addRadioMenu()
    southIADS:addRadioMenu()
    middleIADS:addRadioMenu()
    northIADS:addRadioMenu()    
end
-- Actives all RED IADS
do
    islandIADS:activate()
    southIADS:activate()
    middleIADS:activate()
    northIADS:activate()
end





-- All settings for Blue IADS
if BlueFalklands == true then
    BlueIslandIADs = SkynetIADS:create('Blue Island System')
    BlueIslandIADs:addSAMSitesByPrefix('Blue1')
    BlueIslandIADs:addEarlyWarningRadarsByPrefix('BEW1')
end
-- If and statement to allow for Blue IADS debug
if BlueFalklands == true and IADSDebug == true then
BlueIslandIADs:addRadioMenu()
end
--Activates Blue IADS
if BlueFalklands == true then
    BlueIslandIADs:activate()
end
















--DEBUG (Comment out prior to final mission or there will be an overlay) (Coment out all of the 'addRadioMenu' as they allow for the F-10 to turn on debug regardless of the IADSDebug varible.)
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
    
    local southIADSDebug = southIADS:getDebugSettings()
    southIADSDebug.IADSStatus = true
    southIADSDebug.radarWentDark = true
    southIADSDebug.contacts = true
    southIADSDebug.radarWentLive = true
    southIADSDebug.noWorkingCommmandCenter = true
    southIADSDebug.samNoConnection = true
    southIADSDebug.addedEWRadar = true
    southIADSDebug.harmDefence = true
    
    local middleIADSDebug = middleIADS:getDebugSettings()
    middleIADSDebug.IADSStatus = true
    middleIADSDebug.radarWentDark = true
    middleIADSDebug.contacts = true
    middleIADSDebug.radarWentLive = true
    middleIADSDebug.noWorkingCommmandCenter = true
    middleIADSDebug.samNoConnection = true
    middleIADSDebug.addedEWRadar = true
    middleIADSDebug.harmDefence = true
    
    local northIADSDebug = northIADS:getDebugSettings()
    northIADSDebug.IADSStatus = true
    northIADSDebug.radarWentDark = true
    northIADSDebug.contacts = true
    northIADSDebug.radarWentLive = true
    northIADSDebug.noWorkingCommmandCenter = true
    northIADSDebug.samNoConnection = true
    northIADSDebug.addedEWRadar = true
    northIADSDebug.harmDefence = true

    --      Commented out as until the Island is blue this code will cause issues. 
    -- local BlueFalklandsDebug = BlueFalklands:getDebugSettings()
    -- BlueFalklandsDebug.IADSStatus = true
    -- BlueFalklandsDebug.radarWentDark = true
    -- BlueFalklandsDebug.contacts = true
    -- BlueFalklandsDebug.radarWentLive = true
    -- BlueFalklandsDebug.noWorkingCommmandCenter = true
    -- BlueFalklandsDebug.samNoConnection = true
    -- BlueFalklandsDebug.addedEWRadar = true
    -- BlueFalklandsDebug.harmDefence = true
end