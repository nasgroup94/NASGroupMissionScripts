
local aarNorth = {
    zone = ZONE:New("aarNorth"),
    hdg = 270,
    leg = 60,
}

fighterSquadron = SQUADRON:New("fighter",8,"cool name")
    :AddMissionCapability({AUFTRAG.Type.INTERCEPT}, 90) -- Squad can do intercept missions.
    :AddMissionCapability({AUFTRAG.Type.ALERT5})        -- Squad can be spawned at the airfield in uncontrolled state.
    

TankerSquadron = SQUADRON:New("heavyTanker", 4, "base tankers")
    :AddMissionCapability({AUFTRAG.Type.TANKER,AUFTRAG.Type.ORBIT})
    :SetCallsign(CALLSIGN.Tanker.Arco,3)
    :SetFuelLowRefuel()
    :SetFuelLowThreshold(0.5)
    :SetTakeoffCold()


local northTanker = AUFTRAG:NewORBIT(aarNorth.zone:GetCoordinate(),MISSION_TANKER_ALTS.Probe,260,aarNorth.hdg,aarNorth.leg)
        :SetTime(40)
        :SetRepeat(5)
        :SetMissionRange(500)
        :AssignSquadrons({TankerSquadron})
        :SetName("North AAR")
        :SetTACAN(65,"TST")
        :SetRadio(271.525)

-- function northTanker:OnAfterScheduled(From, Event, To)
--     tankerSetup(self,CALLSIGN.Tanker.Texaco, 3, 65,"TST",271.525)
-- end

BaghdadAW = AIRWING:New("Baghdad warehouse","Tankers")
BaghdadAW:AddSquadron(TankerSquadron)
BaghdadAW:AddSquadron(fighterSquadron)
BaghdadAW:NewPayload("fighter", 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.CAP}, 80)
BaghdadAW:Start()

local Agents = SET_GROUP:New():FilterPrefixes("EWR"):FilterOnce()

IraqChief = CHIEF:New(coalition.side.BLUE,Agents, "Iraq Chief")
IraqChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)

local border = ZONE:New("border")
IraqChief:AddBorderZone(border)

IraqChief:AddAirwing(BaghdadAW)

IraqChief:AddMission(northTanker)

IraqChief:SetTacticalOverviewOn()

-- Launch at least one but at most four asset groups for INTERCEPT missions if the threat level of the target is great or equal to six.
IraqChief:SetResponseOnTarget(1, 4, 6, nil, AUFTRAG.Type.INTERCEPT)

IraqChief:__Start(1)

function IraqChief:OnAfterNewContact(From, Event, To, Contact)

    -- Gather info of contact.
    local ContactName=IraqChief:GetContactName(Contact)
    local ContactType=IraqChief:GetContactTypeName(Contact)
    local ContactThreat=IraqChief:GetContactThreatlevel(Contact)
    
    -- Text message.
    local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)
    
    -- Show message in log file.
    env.info(text)
    
  end