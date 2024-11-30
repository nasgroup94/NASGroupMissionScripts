-- --------------------------------------------- BEACONS --------------------------------------------------
-- -- Tarawa beacon for helis
-- TarawaBeacon, TarawaBeaconID = SCHEDULER:New(nil,function()
--     local tarawaUnit = GROUP:FindByName("Tarawa")
--     tarawaRadio = tarawaUnit:GetBeacon()
--     tarawaRadio:RadioBeacon("beacon.ogg",54.00,radio.modulation.FM,5*60)
--     env.info('Tarawa beacon refreshed')
--     end,{},3,60)

BlueBeacons = { 
  Tarawa = {
    name = "Tarawa",
    sound_file = "beacon.ogg",
    freq = 0.20,
    mod = radio.modulation.AM,
    activated = false,
  },
  CVN75 = {
    name = "CVN75",
    sound_file = "beacon.ogg",
    freq = 0.37,
    mod = radio.modulation.AM,
    activated = false,
  }
}

function SetBlueRadioBeacons(BeaconData, Activate)
    local Unit = UNIT:FindByName(BeaconData.name)
    if Unit:IsAlive() and Activate == true then
      local Frequency = BeaconData.freq * 1000000 -- Freq in Hertz
      local Sound =  "l10n/DEFAULT/"..BeaconData.sound_file
      trigger.action.radioTransmission(Sound, Unit:GetPositionVec3(), BeaconData.mod, true, Frequency, 1000, BeaconData.name)
      BeaconData.activated = true
      net.log("BlackSeaBeacons: Activated "..BeaconData.name)
    elseif not Unit:IsAlive() or Activate == false then
      trigger.action.stopRadioTransmission(BeaconData.name)
      BeaconData.activated = false
      net.log("BlackSeaBeacons: Deactivated "..BeaconData.name)
    end
  end


function CheckForBlueClients()
  local PilotCount = BLUE_CLIENT_SET:Count()
  --BASE:I(string.format("BlueSetBeacons: %s pilots on the server!",PilotCount))
  if  PilotCount > 0 then 
    -- Pilots on the server, activate any beacons that are currently not activated.
      for _,_BeaconData in pairs (BlueBeacons) do
        if _BeaconData.activated == false then
          -- Beacon isn't activated so activate it.
          SetBlueRadioBeacons(_BeaconData, true)
        end
      end
    else
      -- No pilots on the server, deactivate any activated beacons.
      for _, _BeaconData in pairs(BlueBeacons) do
          if _BeaconData.activated == true then
            -- Beacon is active so deactivate it.
            SetBlueRadioBeacons(_BeaconData, false)
          end
      end
  end
end

BlueBCNTimer = TIMER:New(CheckForBlueClients)
BlueBCNTimer:Start(1,30,nil)
