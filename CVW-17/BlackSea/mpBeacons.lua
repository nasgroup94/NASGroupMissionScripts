----------------------------------------------------------------
--MPBeacons
--By: Element
--Version 1.0
--Date: 5.29.2020
--info: element@thefraternitysim.com
--
--MOOSE IS KING!
--
----------------------------------------------------------------
MPBeacons = {}
MPBeacons.Beacons = {} --store beacons

function MPBeacons.CreateBeacon(zone,radiofreq,ID)--return beacon id
  local beaconID
  if ID == nil then
     beaconID = zone:GetName().."_"..MPBeacons.RandomVariable(4)
  else
    beaconID = ID
  end
  local radioFreq = radiofreq
  local _newBeacon = {
      beaconID = beaconID,
      zone = zone,
      radioFreq = radioFreq,
    }
    
  --add beacon to tbl
  table.insert(MPBeacons.Beacons, _newBeacon)
  BASE:E( "Beacon Created - ID: "..beaconID..", Freq: "..radiofreq.." Mhz, Zone: "..zone:GetName())
  
  --Update
  MPBeacons.RefreshBeacons()
  
  return beaconID
end

function MPBeacons.RefreshBeacons()--table of beacons
  local audio = "l10n/DEFAULT/".."beacon.ogg"
  --will reboardcast all beacons
  for _, beacon in pairs(MPBeacons.Beacons) do
    local Frequency = beacon.radioFreq * 1000000 -- Conversion to Hz
    trigger.action.radioTransmission(audio, beacon.zone:GetVec3(), radio.modulation.FM, false,Frequency, 1000,beacon.beaconID)
  end

end

function MPBeacons.StopBeacon(beaconId,Freq)
  --remove beacon from table
  MPBeacons.removeTableEntry(MPBeacons.Beacons,beaconId)
  --stop beacon
  trigger.action.stopRadioTransmission(beaconId)
  BASE:E( "Beacon Stopped - ID: "..beaconId..", Freq: "..Freq.." Mhz")
  MPBeacons.RefreshBeacons()
end

function MPBeacons.RandomVariable(length)
  local res = ""
  for i = 1, length do
    res = res .. string.char(math.random(97, 122))
  end
  return res
end

function MPBeacons.tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function MPBeacons.removeTableEntry(tabel,val)
  table.remove( tabel, MPBeacons.tablefind(tabel, val) )
end

function MPBeacons.BeaconScheduler()
    --MESSAGE:New("BeaconScheduler",5):ToAll()
    timer.scheduleFunction(MPBeacons.BeaconScheduler, nil, timer.getTime() + 5)
    MPBeacons.RefreshBeacons()
end
----------------------------------------------------------------
--Create Beacons ------------------------------------------------
----------------------------------------------------------------
Zone1 = ZONE:New("dropzone1")
Zone2 = ZONE:New("pickupzone1")


Zone1Beacon = MPBeacons.CreateBeacon(Zone1,"45.0","Dallas FOB") --<---using custom ID, returns custome id
Zone2Beacon = MPBeacons.CreateBeacon(Zone2,"50.0", "London FOB") --<---no custom id use, so one will be generated returns custome id

MPBeacons.BeaconScheduler() --<-- be sure to place this function somewhere in  your code so the scheduler can run