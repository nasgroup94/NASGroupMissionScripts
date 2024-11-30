do

    SUPPLY={
        ClassName = "SUPPLY",
        verbosity = 0,
        factories = {},
        dropZone = nil,
        supply = {},
        stores = {},
        storage = {},
        DeliveryQueue = {},
        MaxQueue = 2,
        QueueCount = 0,
    }

    function SUPPLY:New(supply,Alias,dropZone)
        local self = BASE:Inherit(self,WAREHOUSE:New(STATIC:FindByName(supply),Alias))
        self.storage = STORAGE:New(supply)
        self:SetSpawnZone(dropZone)
        self.supply = self
        return self
    end

    function SUPPLY:AddFactory(factory)
        table.insert(self.factories,factory)
        factory:AddSupplier(self,self.stores)
        return self
    end

    function SUPPLY:OnAfterNewAsset(From,Event,To,request)
        Message:New("Recived New Asset")
    end

    function SUPPLY:AddStores(Type,MinQuantity,MaxQuantity,quantity)
        local store = {}
        store.Type = Type
        store.MinQuantity = MinQuantity
        store.MaxQuantity = MaxQuantity
        store.quantity = quantity

        table.insert(self.stores, store)
        
        self.storage:SetLiquid(Type,quantity)
    end

    function SUPPLY:AddDelivery(queueId)
    
        local delivery = {}
        delivery.Id = queueId

        table.insert(self.DeliveryQueue,delivery)

    end

end