--scoring setup cap menu      
BASE:E("-----------------------------------")
BASE:E("---  Loading Scoring script  ------")
BASE:E("-----------------------------------")

--Setup GCI
assert(loadfile("C:/VNAO/VNAO-Mission_Scripts/CVW-7/Marianas/AWACsGCI.lua"))()

--Find Zones in Mission
local redSpawnZone = ZONE:FindByName("Red Spawn Zone")
local RedEngageZone = ZONE:FindByName( "Rock" )
local BlueCapZone = ZONE:FindByName("Blue Cap Zone" )
local spawnMenuCAP = {"RED Su-27 Single","RED Su-27 Section","RED Su-27 Division"}
local redSpawn
local redAWACS = SPAWN:New("RedAWACS")
local BVRMaxTimer = TIMER:New(noScore,redSpawn) -- timer to change score to 0 if pilot does not kill threat in time
local TimeoutLength = 300 --in seconds 
local BlueCapBulls = COORDINATE:NewFromVec3(BlueCapZone:GetPointVec3()):ToStringBULLS(coalition.side.BLUE,settings,true)
local BlueCapClientList = SET_CLIENT:New()
local CAP = MENU_COALITION:New(coalition.side.BLUE,"Scoring Mission Menu")
local AICapZone = AI_CAP_ZONE:New(redSpawnZone,500,10000,200,400)

--Create List of active clients in server. Updates on every birth.
ClientList = SET_CLIENT:New():FilterActive():FilterCoalitions("blue"):FilterStart()
ClientList:ForEachClient(
    function(client)
        BASE:E(client.ClientName)
    end
)

--Initialize Scoring
local scoring = SCORING:New("Cope West")
scoring:SetScaleDestroyScore(10)
scoring:SetScaleDestroyPenalty(20)
scoring:SetMessagesDestroy(true)
scoring:SetMessagesHit(true)
scoring:SetMessagesToCoalition()

--Once red units are spawned add them to the scoring script value of 5 points
function addGroupToScoring(group)
    local units = group.SpawnTemplate.units
    for k,v in ipairs(units) do
        scoring:AddUnitScore(UNIT:FindByName(units[k].name),5)
    end
end

--if client takes too long to kill red group then the score will be 0 
function removeGroupFromScoring(group)
    local units = group.SpawnTemplate.units
    for k,v in ipairs(units) do
        scoring:RemoveUnitScore(UNIT:FindByName(units[k].name))
    end
end

--Set the score to 0 for spawned red units
function noScore(group)
    removeGroupFromScoring(group)
    MESSAGE:New("you have taken too long score now 0 "):ToAll()
    BASE:E("Too Long")
end

-- function to spawn a red group
function newAirBVR(grpname,timeout)
    redSpawn = SPAWN:New(grpname):InitLimit(4,3):InitCleanUp(60)
    redSpawn:SpawnInZone(redSpawnZone,true,3000, 6000 ,1)
    addGroupToScoring(redSpawn)
end

--check to see if client is still alive, if not then destroy spawned red group
CheckAlive,AliveID = SCHEDULER:New(nil,
    function()
        if BlueCapClientList:CountAlive() == 0 then
            local redGroup, Index = redSpawn:GetFirstAliveGroup()
            while redGroup ~= nil do
                redSpawn:GetGroupFromIndex(Index):Destroy()
                redGroup, Index = redSpawn:GetNextAliveGroup(Index)
            end
           redAWACS:GetFirstAliveGroup():Destroy()
           CheckAlive:Stop(AliveID)
        end
    end
,{},5,5)
CheckAlive:Stop(AliveID)

--when the client selects the cap mission in the f10 menu route them to the cap zone 
function CAPTasking()
    MESSAGE:New("Establish CAP at "..BlueCapBulls,30,Info):ToCoalition(coalition.side.BLUE)
    MESSAGE:New("Check in with Magic on 255.000MHz",30,Info):ToCoalition(coalition.side.BLUE)
    MESSAGE:New("Check in with Magic F10- Cope West GCI",30,Info):ToCoalition(coalition.side.BLUE)
    CheckZone:Start(ID)
end

function AICAPSpawn()
    AICapZone:SetControllable(GROUP:FindByName(redSpawn:SpawnGroupName()))
    AICapZone:SetEngageZone(RedEngageZone)
    AICapZone:__Start(3)
end

--check to see if clients are in the cap zone every 10 seconds
CheckZone,ID = SCHEDULER:New(nil,
    function()
        ClientList:ForEachClientInZone(BlueCapZone,(
            function(TheClient)
                InCap(TheClient)
            end
        ))
    end
,{},10,10)
CheckZone:Stop(ID)


--Start mission spawn in up to 3 red units depending on how many clients in cap list
function StartMission()
    local list = SET_CLIENT:New()
    ClientList:ForEachClientInZone(BlueCapZone,(
        function(client)
            BlueCapClientList:AddClientsByName(client.ClientName)
            list:AddClientsByName(client.ClientName)
            client:Message("A/A Mission Started")
        end
    ))
    local spawnSize = 0
    if list:Count() == 1 then
        spawnSize = 1
    end
    if list:Count() == 2 then
        spawnSize = 2
    end
    if list:Count() > 2 then
        spawnSize = 3
    end
    if list:Count() > 2 then
        spawnSize = 3
    end
    if redAWACS.SpawnCount == 0 then
        redAWACS:Spawn()
    end

    BlueCapClientList:Add(list)
    newAirBVR(spawnMenuCAP[spawnSize],TimeoutLength)  
    AICAPSpawn()    
    CheckZone:Stop(ID)
    CheckAlive:Start(AliveID)
end

--Build menus and messages
MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Start CAP Mission",CAP,CAPTasking)

--Send message to all clients in the cap zone
function InCap(client)
    local TheGroup = GROUP:FindByName(client:GetClientGroupName())
    client:Message("You Have arrived in the CAP Zone.")
    client:Message("Once everyone in your flight has recieved this message")
    client:Message("select \"Run A/A scoring\" in F10 Scoring Mission Menu")
    if client and client:IsAlive() then
        MENU_GROUP_COMMAND:New(TheGroup,"Run A/A Scoring",CAP,StartMission)
    end
end



-- {
--     [CountryID]=27,
--     [lateActivation]=true,
--     [tasks]={},
--     [radioSet]=false,
--     [CategoryID]=0,
--     [task]=CAP,
--     [uncontrolled]=false,
--     [route]={
--         [routeRelativeTOT]=true,
--         [points]={
--             [1]={
--                 [speed_locked]=true,
--                 [type]=Turning Point,
--                 [action]=Turning Point,
--                 [alt_type]=BARO,
--                 [y]=-770648.81371878,
--                 [x]=582684.79221752,
--                 [ETA]=0,
--                 [alt]=2000,
--                 [speed]=169.58333333333,
--                 [ETA_locked]=true,
--                 [task]={
--                     [id]=ComboTask,
--                     [params]={
--                         [tasks]={
--                             [1]={
--                                 [number]=1,
--                                 [auto]=true,
--                                 [id]=EngageTargets,
--                                 [enabled]=true,
--                                 [key]=CAP,
--                                 [params]={
--                                     [targetTypes]={
--                                         [1]=Air,
--                                     },
--                                     [priority]=0,
--                                 },
--                             },
--                         },
--                     },
--                 },
--                 [formation_template]=,
--             },
--             [2]={
--                 [speed_locked]=true,
--                 [type]=Turning Point,
--                 [action]=Turning Point,
--                 [alt_type]=BARO,
--                 [y]=-765649.14576373,
--                 [x]=581898.54583581,
--                 [ETA]=29.844399954403,
--                 [alt]=2000,
--                 [speed]=169.58333333333,
--                 [ETA_locked]=false,
--                 [task]={
--                     [id]=ComboTask,
--                     [params]={
--                         [tasks]={
--                             [1]={
--                                 [number]=1,
--                                 [auto]=false,
--                                 [id]=WrappedAction,
--                                 [enabled]=true,
--                                 [params]={
--                                     [action]={
--                                         [id]=Option,
--                                         [params]={
--                                             [value]=2
--                                             ,[name]=0,
--                                         },
--                                     },
--                                 },
--                             },
--                             [2]={
--                                 [number]=2,
--                                 [auto]=false,
--                                 [id]=WrappedAction,
--                                 [enabled]=true,
--                                 [params]={
--                                     [action]={
--                                         [id]=Option,
--                                         [params]={
--                                             [value]=1,
--                                             [name]=1,
--                                         },
--                                     },
--                                 },
--                             },
--                         },
--                     },
--                 },
--                 [formation_template]=,
--             },
--         },
--     },
--     [groupId]=3,
--     [hidden]=false,
--     [units]={
--         [1]={
--             [alt]=2000,
--             [type]=Su-27,
--             [hardpoint_racks]=true,
--             [alt_type]=BARO,
--             [psi]=-1.7267785725591,
--             [livery_id]=PLAAF K1S old,
--             [onboard_num]=010,
--             [unitId]=3,
--             [y]=-770648.81371878,
--             [x]=582684.79221752,
--             [name]=Aerial-2-1,
--             [payload]={
--                 [pylons]={
--                     [1]={[CLSID]={44EE8698-89F9-48EE-AF36-5FD31896A82F},},
--                     [2]={[CLSID]={FBC29BFE-3D24-4C64-B81D-941239D12249},},
--                     [3]={[CLSID]={B79C379A-9E87-4E50-A1EE-7F7E29C2E87A},},
--                     [4]={[CLSID]={E8069896-8435-4B90-95C0-01A03AE6E400},},
--                     [5]={[CLSID]={E8069896-8435-4B90-95C0-01A03AE6E400},},
--                     [6]={[CLSID]={E8069896-8435-4B90-95C0-01A03AE6E400},},
--                     [7]={[CLSID]={E8069896-8435-4B90-95C0-01A03AE6E400},},
--                     [8]={[CLSID]={B79C379A-9E87-4E50-A1EE-7F7E29C2E87A},},
--                     [9]={[CLSID]={FBC29BFE-3D24-4C64-B81D-941239D12249},},
--                     [10]={[CLSID]={44EE8698-89F9-48EE-AF36-5FD31896A82A},},
--                 },
--                 [fuel]=5590.18,
--                 [flare]=96,
--                 [chaff]=96,
--                 [gun]=100,
--             },
--             [speed]=169.58333333333,
--             [heading]=1.7267785725591,
--             [callsign]=109,
--             [skill]=High,
--         },
--     },
--     [y]=-770648.81371878,
--     [x]=582684.79221752,
--     [name]=RED Su-27 Single,
--     [communication]=true,
--     [modulation]=0,
--     [start_time]=0,
--     [CoalitionID]=1,
--     [frequency]=127.5,
-- } 