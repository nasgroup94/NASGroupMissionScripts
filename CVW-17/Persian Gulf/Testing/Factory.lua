do
    -- @field #FACTORY
    FACTORY = {
        ClassName = "FACTORY",
        verbosity = 0,
        lid = nil,
        Report = true,
        factory = nil,
        fuelQuantity = 0,
        Rate = 1, --pounds per hour
        Type = {}, --type of factory
        coalition = nil,
        TransportThresh = 3,
        OpsGroup = nil,
        PickupZone = nil,
        DropOffZone = nil,
        Debug = false,
        offroadpaths = {},
        spawnzone = nil,
        fuelType = nil,
        equipmentType = nil,
        equipmentQuantity = nil,
        suppliers = {},
    }

    FACTORY.version = "0.0.1"

 


    -- creates a new factory object from a static unit placed in the mission editor.
    -- Sets coalition from the static object
    -- @param #FACTORY self
    -- @param Wrapper.Static#STATIC factory The object used to represent the factory
    --@param #string alias (Optional) The alias of the factory
    --@param CORE.Zone#ZONE pickUpZone the zone where ground assests are spawned for deliveries
    --@return #FACTORY self
    function FACTORY:New(factory, alias, pickUpZone)
        local self = BASE:Inherit(self, WAREHOUSE:New(factory, alias))

        -- self.PickUpZone = pickUpZone
        self.coalition = self:GetCoalition()

        self:SetSpawnZone(pickUpZone)

        self:SetStartState("Shutdown")

        -- Add FSM transitions
        self:AddTransition("Shutdown", "Start", "Running")
        self:AddTransition("*", "Status", "*")
        self:AddTransition("*", "AddSupplier", "*")
        self:AddTransition("*", "AddProductionType", "*")
        self:AddTransition("Running", "ProductionReady", "*")

        return self
    end


    --- FSM Function OnAfterStatus.field
    -- @function [parent=#FACTORY] OnAfterStatus
    -- @param #FACTORY self
    -- @param #string From State.
    -- @param #string Event Trigger.
    -- @param #string To State. 
    -- @return #FACTORY self


    function FACTORY:OnAfterStatus(From, Event, To)
        if self:GetCoalition() == self.coalition then
            self:_updateProduction()
        end
    end

    function FACTORY:OnAfterProductionReady(From, Event, To,type)
        self:E(self.alias .. " " .. type.Type .. " Production is Ready")
        for _, supplier in pairs(self.suppliers) do
            for i,store in pairs(supplier.stores) do
                if (store.Type == type.Type and supplier.supplyHouse.storage:GetLiquidAmount(type.Type) <= store.MinQuantity) then

                    local id = self.warehouse.queueid

                    if(supplier.supplyHouse.MaxQueue < supplier.supplyHouse.QueueCount) then
                        supplier.AddDelivery(id)
                        self:E("the id is : " .. id)
                        supplier.QueueCount = supplier.QueueCount + 1
                        -- self:E(supplier.supplyHouse.storage:GetLiquidAmount(type.Type))
                        self:AddRequest(supplier.supplyHouse,WAREHOUSE.Descriptor.GROUPNAME,"truck",2)
                        self:E("Transport requested") 
                    end          
                end
            end
        end
    end

    function FACTORY:OnAfterDelivered(From, Event, To, request)
        MESSAGE:New("Delivered", 30):ToAll()
        self:E(request)
    end

    function FACTORY:_updateProduction()

        for _,type in pairs(self.Type) do
            type.quantity = type.quantity + type.Rate
            self:E(self.alias .. " Currenty has: " .. type.quantity .. " of " .. type.Type)
            if (type.quantity >= type.Threshold) then
                self:ProductionReady(type)
            end
        end

    end


    --@param #FACTORY self
    --@param #FACTORY supplyHouse The remote supply house.
    function FACTORY:AddSupplier(supplyHouse,stores)
        local supplier = {}
        supplier.supplyHouse = supplyHouse
        supplier.stores = stores
    
        table.insert(self.suppliers, supplier)
        return self
    end

    function FACTORY:AddProductionType(Type,Rate,Threshold,MaxStorage,quantity)
        local type = {}
        type.Type = Type
        type.Rate = Rate
        type.Threshold = Threshold
        type.MaxStorage = MaxStorage
        type.quantity = quantity
        
        table.insert(self.Type,type)
    end
end
