
-- --------------------------------------------- BEACONS --------------------------------------------------
BlueBeacons = { 
  Tarawa = {
    name = "Tarawa",
    sound_file = "beacon.ogg",
    freq = 0.20,
    mod = radio.modulation.AM,
    activated = false,
  },
  CVN73 = {
    name = "CVN-75 Lone Warrior",
    sound_file = "beacon.ogg",
    freq = 0.37,
    mod = radio.modulation.AM,
    activated = false,
  },
  Dallas = {
    name = "FARP-DALLAS-VEH-1",
    sound_file = "beacon.ogg",
    freq = 0.45,
    mod = radio.modulation.AM,
    activated = false,
  },
  -- Rome = {
  --   name = "FARP-ROME-VEH-1",
  --   sound_file = "beacon.ogg",
  --   freq = 0.41,
  --   mod = radio.modulation.AM,
  --   activated = false,
  -- },
  Dublin = {
    name = "FARP-DUBLIN-VEH-1-1",
    sound_file = "beacon.ogg",
    freq = 0.436,
    mod = radio.modulation.AM,
    activated = false,
  },
  Pagan = {
    name = "Pagan TACAN-1",
    sound_file = "beacon.ogg",
    freq = 0.283,
    mod = radio.modulation.AM,
    activated = false,
  },
  Faralon = {
    name = "Faralon TACAN-1",
    sound_file = "beacon.ogg",
    freq = 0.345,
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
      net.log("Marianas Beacons: Activated "..BeaconData.name)
    elseif not Unit:IsAlive() or Activate == false then
      trigger.action.stopRadioTransmission(BeaconData.name)
      BeaconData.activated = false
      net.log("Marianas Beacons: Deactivated "..BeaconData.name)
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

