    --TO DO 

        --Finish Sa-10 Template (add Sam defences and other support items) {Done}
        --Move SA-10 to key locations {South, Mid placed}
        --Complete South IADS {Done unless changes are needed}
        --Complete Middle IADS {Done unless changes are needed}
        --Complete North IADS {SWITCH SA-23 AND SA-2}
        --Complete Island IADS {Need to wait for hardpoints from Huevo}
        --AWACS - 3 ADDED Waiting for hookup to dispatcher // MOOSE
        --Test Harm saturation and TALD effectiveness {Talds work well, Harms are effective but due to site turning off can cause misses.}
        --Make weakpoints for Blue to exploit {Work in progress}
        --Spread out random IR Sams {TBD place old US systems near hardpoints }
        --Work with Circuit to see if Skynet can Auto spawn aircraft {On list}
do
    --Island IADS
     redIADS = SkynetIADS:create('Island System')
     redIADS:addSAMSitesByPrefix('SAM1')
     redIADS:addEarlyWarningRadarsByPrefix('EW1')
     redIADS:addRadioMenu()
     redIADS:getSAMSiteByGroupName('SAM1-SA-10-1'):setActAsEW(false):setHARMDetectionChance(62)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
    
    --South Mainland IADS
    redIADS = SkynetIADS:create('South Mainland')
    redIADS:addSAMSitesByPrefix('SAM2')
    redIADS:addEarlyWarningRadarsByPrefix('EW2')
    redIADS:addRadioMenu()
        --TO NOTE Everything between this note and the one corresponding below must be placed under the IADS that it is to be calling for or it breaks the script
    --Settings for S-300//SA-10
    local sa15 = redIADS:getSAMSiteByGroupName('SAM2-SA-15 PD')
    redIADS:getSAMSiteByGroupName('SAM2-SA-10'):setActAsEW(false):setHARMDetectionChance(62):addPointDefence(sa15)
        --Commented out SA-10 as EW to False due Island SA-10 being EW... IF need to be changed back coment in, and flip the flag on the SA-10 lines.   
        -- redIADS:getSAMSitesByNatoName('SA-10'):setActAsEW(false)
    --ActasEW is false due to SA-10 turning off if attacked by harms blinding the SA-15s (Do not turn on without adding addtional EW to prevent SA-15s from going blind) 
        --TO NOTE - corresponding note referenced above
 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
    -- Creating Middle Zone Mainland IADS system
    redIADS = SkynetIADS:create('Middle Mainland')
    redIADS:addSAMSitesByPrefix('SAM3')
    redIADS:addEarlyWarningRadarsByPrefix('EW3')
    redIADS:addRadioMenu()
    local sa15 = redIADS:getSAMSiteByGroupName('SAM3-SA-15 PD-1')
    redIADS:getSAMSiteByGroupName('SAM3-SA-10-1'):setActAsEW(false):setHARMDetectionChance(62):addPointDefence(sa15)
    --ActasEW is false due to SA-10 turning off if attacked by harms blinding the SA-15s (Do not turn on without adding addtional EW to prevent SA-15s from going blind) 
 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   

    redIADS = SkynetIADS:create('North Mainland')
    redIADS:addSAMSitesByPrefix('SAM4')
    redIADS:addEarlyWarningRadarsByPrefix('EW4')
    redIADS:addRadioMenu()
    redIADS:getSAMSiteByGroupName('SAM4-SA-23-1'):setActAsEW(true)
--For now I have left the SA-23 as an EW, but if there are other sites placed in the north then it would be smart to disable the EW setting and add a designated EW site. As about this prior to doing it please.

    redIADS:activate()
    

--DEBUG (Comment out prior to final mission or there will be an overlay)
    --Seems that the last IADS made is the only overlay that shows up. Comment out the others to debug if nessasary.
    local iadsDebug = redIADS:getDebugSettings()
    iadsDebug.IADSStatus = true
    iadsDebug.radarWentDark = true
    iadsDebug.contacts = true
    iadsDebug.radarWentLive = true
    iadsDebug.noWorkingCommmandCenter = true
    iadsDebug.samNoConnection = true
    iadsDebug.addedEWRadar = true
    iadsDebug.harmDefence = true
    
    end