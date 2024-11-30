local US={}
US.squad={}
US.airwing={}
US.commander=nil

local captureKutaisi=OPSZONE:New("capture")
local captureSenaki=OPSZONE:New("red Zone")

US.squad.fighter=SQUADRON:New("Fighter Group", 10,"Fighter Jets")
US.squad.fighter:AddMissionCapability({AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.ESCORT},10)

US.squad.attack=SQUADRON:New("Fighter Group",10,"attack Jets")
US.squad.attack:AddMissionCapability({AUFTRAG.Type.CAS,AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.STRIKE,AUFTRAG.Type.BAI,AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON},80)


-- Create airwing at kobuleti
US.airwing.kbl=AIRWING:New("Warehouse Kobuleti","Airforce")
US.airwing.kbl:NewPayload(GROUP:FindByName("F-16 AA"),10,{AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.ESCORT},80)
US.airwing.kbl:NewPayload(GROUP:FindByName("F-16 AG"),10,{AUFTRAG.Type.CAS,AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.STRIKE,AUFTRAG.Type.BAI,AUFTRAG.Type.BOMBING})
US.airwing.kbl:AddSquadron(US.squad.fighter)
US.airwing.kbl:AddSquadron(US.squad.fighter)
US.airwing.kbl:Start()

-- create platoons
platoon = PLATOON:New("Ground-1",20,"yes")
platoon:AddMissionCapability({AUFTRAG.Type.ARTY})

infantry = PLATOON:New("m4",20,"infantry")
-- infantry:SetGrouping(2)
infantry:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK,AUFTRAG.Type.ONGUARD,AUFTRAG.Type.CAPTUREZONE},80)


transport=PLATOON:New("blue apc",10,"transport")
transport:AddMissionCapability({AUFTRAG.Type.OPSTRANSPORT,AUFTRAG.Type.TROOPSTRANSPORT,AUFTRAG.Type.ONGUARD,AUFTRAG.Type.GROUNDATTACK},90)

tank=PLATOON:New("abrams",20,"tank")
tank:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK})

-- create brigade
brigade = BRIGADE:New("Warehouse Kobuleti","brigy")
brigade:AddPlatoon(platoon)
brigade:AddPlatoon(infantry)
brigade:AddPlatoon(transport)
brigade:AddPlatoon(tank)
brigade:SetSpawnZone(ZONE:New("blue spawn"))
brigade:Start()

-- create flotilla
flotilla = FLOTILLA:New("Naval-1",4,"Float")
flotilla:AddMissionCapability({AUFTRAG.Type.ARTY},50)
flotilla:AddMissionCapability({AUFTRAG.Type.PATROLZONE},90)
flotilla:AddWeaponRange(1, 13, ENUMS.WeaponFlag.Cannons)

-- create fleet
fleet = FLEET:New("Warehouse Kobuleti","simple fleet")
fleet:SetSpawnZone(ZONE:New("navy spawn"))
fleet:SetPortZone(ZONE:New("navy port"))
fleet:AddFlotilla(flotilla)
fleet:Start()

-- create chief
local borderZone = ZONE:New("Blue Border")
local Agents=SET_GROUP:New():FilterPrefixes("ewr"):FilterOnce()
local chief = CHIEF:New(coalition.side.BLUE,Agents,"chief")
chief:AddBorderZone(borderZone)
chief:AddAirwing(US.airwing.kbl)
chief:AddFleet(fleet)
chief:AddBrigade(brigade)
chief:SetTacticalOverviewOn()
chief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
chief:__Start(1)



local ResourceOccupied, resourceCAS=chief:CreateResource(AUFTRAG.Type.CASENHANCED,1,2)
chief:AddToResource(ResourceOccupied, AUFTRAG.Type.ARTY, 1,2,nil,"Ground-1")
chief:AddToResource(ResourceOccupied,AUFTRAG.Type.BOMBING,1,2)

local recon=AUFTRAG:NewRECON(captureKutaisi,250,20000)

chief:AddMission(recon)

-- chief:AddMission(CapMission)
chief:AddStrategicZone(captureKutaisi,nil,2,ResourceOccupied)
chief:AddStrategicZone(captureSenaki,nil,3)
-- chief:AddAttackZone(captureKutaisi,20,2)

--- Function called each time Chief Agents detect a new contact.
function chief:OnAfterNewContact(From, Event, To, Contact)

    -- Gather info of contact.
    local ContactName=chief:GetContactName(Contact)
    local ContactType=chief:GetContactTypeName(Contact)
    local ContactThreat=chief:GetContactThreatlevel(Contact)
    
    -- Text message.
    local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)
    
    -- Show message in log file.
    env.info(text)
    
  end
  



-- RED side
local RUS={}
RUS.squad={}
RUS.airwing={}
RUS.float={}
RUS.fleet={}
RUS.plat={}
RUS.brig={}

RUS.squad.fighter=SQUADRON:New("Mig19",10,"Russian Fighter")
RUS.squad.fighter:AddMissionCapability({AUFTRAG.Type.CAP,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.ESCORT},60)

RUS.squad.attack=SQUADRON:New("Mig19",10,"Russian Attack")
RUS.squad.attack:AddMissionCapability({AUFTRAG.Type.STRIKE,AUFTRAG.Type.BOMBING},70)

RUS.airwing.senaki=AIRWING:New("Warehouse Senaki","Russian airforce")
RUS.airwing.senaki:NewPayload(GROUP:FindByName("Mig19 AA"),10,{AUFTRAG.Type.CAP,                                                            
                                                            AUFTRAG.Type.ESCORT},70)
RUS.airwing.senaki:NewPayload(GROUP:FindByName("Mig19 AG"),10,{AUFTRAG.Type.STRIKE,                                                             
                                                            AUFTRAG.Type.BOMBING},40)

RUS.plat.infantry=PLATOON:New("infantry10",20,"russian infantry")
-- RUS.plat.infantry:SetGrouping(2)
RUS.plat.infantry:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK,                              
                                        AUFTRAG.Type.ONGUARD,                                  
                                        AUFTRAG.Type.CAPTUREZONE},80)

RUS.plat.transport=PLATOON:New("APC",10,"russian transport")
RUS.plat.transport:AddMissionCapability({AUFTRAG.Type.OPSTRANSPORT,AUFTRAG.Type.GROUNDATTACK,AUFTRAG.Type.ONGUARD},90)

RUS.brig.senaki=BRIGADE:New("Warehouse Senaki","russian brigade")
RUS.brig.senaki:AddPlatoon(RUS.plat.infantry)
RUS.brig.senaki:AddPlatoon(RUS.plat.transport)
RUS.brig.senaki:SetSpawnZone(ZONE:New("red spawn"))


local RedAgents=SET_GROUP:New():FilterPrefixes("red ewr"):FilterOnce()
local RedBorder=ZONE:New("red Zone")


redChief=CHIEF:New(coalition.side.RED,RedAgents,"russian chief")
redChief:AddBorderZone(RedBorder)
redChief:AddAirwing(RUS.airwing.senaki)
redChief:AddBrigade(RUS.brig.senaki)
redChief:SetTacticalOverviewOn()
redChief:SetStrategy(CHIEF.Strategy.OFFENSIVE)
redChief:__Start(1)

redChief:AddStrategicZone(captureKutaisi,20,2)

