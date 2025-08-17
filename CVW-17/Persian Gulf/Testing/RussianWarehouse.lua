-------------------Russian Logistics Infrastructure---------------------------------


local pickup = ZONE:New("pickup"):DrawZone()
local drop = ZONE:New("drop"):DrawZone()
local drop2 = ZONE:New("drop 2"):DrawZone()
local path = GROUP:FindByName("path")
local path2 = GROUP:FindByName("path2")


 
    local supplyhouse = SUPPLY:New("Russian HQ","Russian Supplier", drop)
    -- supplyhouse:SetSpawnZone(drop)
    supplyhouse:AddStores(STORAGE.Liquid.GASOLINE,2,5,1)
    -- supplyhouse:AddOffRoadPath(factory,path,true)
    supplyhouse:Start()


    local secondHouse = SUPPLY:New("second airbase","Second Supplier",drop2)
    -- secondHouse:SetSp
    secondHouse:AddStores(STORAGE.Liquid.DIESEL,20,50,10)
    -- secondHouse:AddOffRoadPath(factory,path2,true)
    secondHouse:Start()

    local factory = FACTORY:New("Fuel plant","Main Plant",pickup)
    factory:AddAsset("truck",5)
    factory:AddOffRoadPath(supplyhouse,path,true)
    factory:AddOffRoadPath(secondHouse,path2,true)
    factory:SetVerbosityLevel(5)
    factory:SetStatusUpdate(30)
    factory:AddProductionType(STORAGE.Liquid.DIESEL,10,30,100,10)
    factory:AddProductionType(STORAGE.Liquid.GASOLINE,1,2,5,1)
    factory:Start()

  
    secondHouse:AddFactory(factory)
    supplyhouse:AddFactory(factory)

    
    -- supplyhouse:AddOffRoadPath(factory,path)
   
    -- factory:AddRequest(supplyhouse,WAREHOUSE.Descriptor.GROUPNAME,"truck",2)



-- function factory:OnAfterDelivered(From,Event,To,request)
--     MESSAGE:New("Delivered",30):ToAll()
--     BASE:E(request)
-- end
-- local deliverFuel = OPSTRANSPORT:New(nil,pickup,drop)
-- deliverFuel:AddCargoStorage(fuel,RussianHQ,STORAGE.Liquid.JETFUEL,100)
-- ops:AddOpsTransport(deliverFuel)

-- local refinery = REFINERY:New("Fuel plant","Russian Fuel",1,ops,pickup,drop)
-- refinery:SetRate(100)
-- refinery:SetFuelType(STORAGE.Liquid.JETFUEL)
-- refinery:SetTime(10)
-- refinery:SetTransportThresh(200)
-- refinery:AddOffRoadPath(test,path,true)









-- RussianHQ:AddOffRoadPath(fuelPlant,GROUP:FindByName("fuel to HQ route"), false)
-- RussianHQ:SetSpawnZone(HQZone)
-- RussianHQ:Start()

-- fuelPlant:SetSpawnZone(fuelZone)
-- fuelPlant:Start()

-- local transport=OPSTRANSPORT:New(nil,fuelZone,HQZone)
-- transport:AddCargoStorage(fuelPlant,RussianHQ, STORAGE.Liquid.JETFUEL,1000)

-- local truck=ARMYGROUP:New("truck")
-- truck:AddOpsTransport(transport)

-- RussianHQ:Add






--- Function to report the current amount of fuel at Berlin and Batumi
-- local function reportStorage()
--     local text=string.format("Current storage amount:\n")
--     local text=string.format("Berlin has %d kg of jet fuel and %d kg of Diesel\n", fuelPlant:GetLiquidAmount(STORAGE.Liquid.JETFUEL), fuelPlant:GetLiquidAmount(STORAGE.Liquid.DIESEL))
--     text=text..string.format("Batumi has %d kg of jet fuel and %d kg of Diesel",   RussianHQ:GetLiquidAmount(STORAGE.Liquid.JETFUEL), RussianHQ:GetLiquidAmount(STORAGE.Liquid.DIESEL))
--     MESSAGE:New(text, 300):ToAll():ToLog()
--   end
  
--   -- Report initial storage.
--   reportStorage()
  
--   --- Function called after truck has loaded a batch of cargo.
--   function truck:OnAfterLoadingDone(From, Event, To)
--     -- Report storage after truck has loaded all its current cargo.
--     reportStorage()
--   end
  
--   --- Function called after truck has unloaded a batch of cargo.
--   function truck:OnAfterUnloadingDone(From,Event,To)
--     -- Report storage after truck has delivered all its current cargo.
--     reportStorage()
--   end
  
--   --- Function called when transport was delivered or everyone (remaining) is dead.
--   function transport:OnAfterDelivered(From, Event, To)
  
--     -- Report that everything was delivered
--     local text=string.format("Transport UID=%d was delivered. Ncargo=%d Ndelivered=%d", transport:GetUID(), transport:GetNcargoTotal(), transport:GetNcargoDelivered())
--     MESSAGE:New(text, 300):ToAll():ToLog()
    
--     -- Report storage after everything was delivered.
--     reportStorage()
--   end