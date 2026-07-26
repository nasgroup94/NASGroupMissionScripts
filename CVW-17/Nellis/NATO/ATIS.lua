-- Nellis ATIS on 134.6 AM. Bound to Nellis AFB so the wind-derived active
-- runway and Zulu-hour information letter reflect Nellis — NASG_ATC reads
-- these live for taxi/tower clearances (see NASG_ATC:AttachMooseATIS in
-- Nellis_ATC_Config.lua). Must load before Nellis_ATC_Config.lua.
atisNellis = ATIS:New(AIRBASE.Nevada.Nellis, 134.6, radio.modulation.AM)
atisNellis:SetRadioRelayUnitName("NellisRelay")
atisNellis:SetSRS("", "female", "en-US")
NASG_TTS:Use(atisNellis.msrs, "Nellis ATIS", "Zoe")
atisNellis:SetQueueUpdateTime(100)
atisNellis:__Start(20)

-- Creech ATIS on a separate frequency, same pattern.
atisCreech = ATIS:New(AIRBASE.Nevada.Creech, 121.1, radio.modulation.AM)
atisCreech:SetRadioRelayUnitName("CreechRelay")
atisCreech:SetSRS("", "male", "en-US")
NASG_TTS:Use(atisCreech.msrs, "Creech ATIS", "Nathan")
atisCreech:SetQueueUpdateTime(100)
atisCreech:__Start(25)

-- Groom Lake has no ATIS in this example — its minimal airport definition
-- in Nellis_ATC_Airports.lua doesn't need one; add one the same way above
-- if you build it out later.
