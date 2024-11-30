-- RAT military traffic
local rat_a10 = RAT:New("rat-a10")
local rat_f15 = RAT:New("rat-f15")
local rat_f16 = RAT:New("rat-f16")
local rat_c17 = RAT:New("rat-c17")
local rat_c130 = RAT:New("rat-c130")
local rat_a400 = RAT:New("rat-a400")

rat_a10:ATC_Messages(false)
rat_f15:ATC_Messages(false)
rat_f16:ATC_Messages(false)
rat_c17:ATC_Messages(false)
rat_c130:ATC_Messages(false)
rat_a400:ATC_Messages(false)

rat_a10:EnableATC()
rat_f15:EnableATC()
rat_f16:EnableATC()
rat_c17:EnableATC()
rat_c130:EnableATC()
rat_a400:EnableATC()

rat_a10:RadioOFF()
rat_f15:RadioOFF()
rat_f16:RadioOFF()
rat_c17:RadioOFF()
rat_c130:RadioOFF()
rat_a400:RadioOFF()

rat_a10:SetCoalition("sameonly")
rat_f15:SetCoalition("sameonly")
rat_f16:SetCoalition("sameonly")
rat_c17:SetCoalition("same")
rat_c130:SetCoalition("same")
rat_c17:SetCoalition("same")
rat_a400:SetCoalition("same")

rat_a10:SetFL(120)
rat_f15:SetFL(250)
rat_f16:SetFL(280)
rat_c17:SetFL(300)
rat_c130:SetFL(150)
rat_a400:SetFL(250)

rat_a10:ContinueJourney()
rat_f15:ContinueJourney()
rat_f16:ContinueJourney()
rat_c17:ContinueJourney()
rat_c130:ContinueJourney()
rat_a400:ContinueJourney()

rat_a10:Spawn(1)
rat_f15:Spawn(1)
rat_f16:Spawn(1)
rat_c17:Spawn(2)
rat_c130:Spawn(2)
rat_a400:Spawn(2)





-- RAT 747 at Tbilisi
local transportB7472=RAT:New("Neutral RAT Commercial 2")
transportB7472:SetCoalitionAircraft("neutral")
transportB7472:SetDeparture("Tbilisi-Lochini")
transportB7472:SetDestination("Anapa-Vityazevo")
transportB7472:Commute()
transportB7472:ATC_Messages(false)
transportB7472:InitCleanUp( 600 )
transportB7472:Spawn(1)



-- RAT 747 at Anapa
local transportB7471=RAT:New("Neutral RAT Commercial 1")
transportB7471:SetCoalitionAircraft("neutral")
transportB7471:SetCoalition("sameonly")
transportB7471:SetDeparture("Anapa-Vityazevo")
transportB7471:SetDestination("Tbilisi-Lochini")
transportB7471:Commute()
transportB7471:ATC_Messages(false)
transportB7471:InitCleanUp( 600 )
transportB7471:Spawn(1)



BASE:E("-----------------------------------")
BASE:E("------  Loading CAT script  -------")
BASE:E("-----------------------------------")

-- RAT C-130 at Batumi
local transportBTM=RAT:New("RAT_C130_BTM")
transportBTM:SetCoalitionAircraft("blue")
transportBTM:SetCoalition("sameonly")
transportBTM:SetDeparture("Batumi")
transportBTM:ExcludedAirports({"Gudauta", "Sukhumi-Babushara"})
transportBTM:ATC_Messages(false)
transportBTM:Spawn(1)

-- RAT T-45s at Kobuleti
local trainerKBL=RAT:New("RAT_T45_KBL")
trainerKBL:SetCoalitionAircraft("blue")
trainerKBL:SetCoalition("sameonly")
trainerKBL:SetDeparture("Kobuleti")
trainerKBL:ExcludedAirports({"Gudauta", "Sukhumi-Babushara"})
trainerKBL:ATC_Messages(false)
trainerKBL:Spawn(1)

-- RAT C-17 at Tbilisi-Lochini
local transport17TB=RAT:New("RAT_C17")
transport17TB:SetCoalitionAircraft("blue")
transport17TB:SetCoalition("sameonly")
transport17TB:SetDeparture("Tbilisi-Lochini")
transport17TB:SetDestination("Kobuleti")
transport17TB:Commute()
transport17TB:ATC_Messages(false)
transport17TB:Spawn(1)

-- RAT F/A-18C at Kobuleti
local practiceF181=RAT:New("RAT_F/A-18C_KBL")
practiceF181:
SetCoalitionAircraft("blue")
practiceF181:
SetCoalition("sameonly")
practiceF181:SetDeparture("Kobuleti")
practiceF181:ExcludedAirports({"Gudauta", "Sukhumi-Babushara"})
practiceF181:ATC_Messages(false)
practiceF181:Spawn(1)

-- RAT F/A-18C at Kutaisi
local practiceF182=RAT:New("RAT_F/A-18C_KTS")
practiceF182:
SetCoalitionAircraft("blue")
practiceF182:
SetCoalition("sameonly")
practiceF182:SetDeparture("Kutaisi")
practiceF182:ExcludedAirports({"Gudauta", "Sukhumi-Babushara"})
practiceF182:ATC_Messages(false)
practiceF182:Spawn(1)

-- RAT AV-8B NA at Batumi
local marine=RAT:New("RAT_AV-8B_BAT")
marine:SetCoalitionAircraft("blue")
marine:SetCoalition("sameonly")
marine:SetDeparture("Batumi")
marine:SetDestination({"BlueMASH #1"})
marine:Commute()
marine:ATC_Messages(false)
marine:Spawn(1)

Form_Hornets = SPAWN:New("RAT_Form_F/A-18C")
  :InitLimit( 2, 2 )
  :InitRepeatOnLanding()
  :InitDelayOff()
  :InitCleanUp( 600 )
  :SpawnScheduled(3600,2)