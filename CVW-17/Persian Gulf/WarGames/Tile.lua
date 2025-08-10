do 

    local Production = {}
    Production.Oil = 0
    Production.Vehicle = 0
    Production.Equipment= 0
    Production.weapons = 0
    --@field #TILE
    TILE = {
        --@field #string alias
        alias = "TILE",
        --@field #string coalition
        coalition = nil,
        --@field #table warehouse
        warehouse = {},
        ClassName = "TILE",
        verbosity = 0,
        --@field #number Profit
        Profit = 0,
        --@feld #table Production
        Production = Production,

    }

    TILE.version = "0.0.1"
    
    function TILE:New(alias, coalition,zoneName)
        local self = BASE:Inherit(self, ZONE:New(zoneName))

        self.coalition = coalition or coalition.side.BLUE
        self.alias = alias

        self:DrawZone(-1,{1,0,0},1,{1,0,0},.1,1,false)

        local theZone = ZONE_POLYGON:FindByName(zoneName)

        local randomPoint = theZone:GetRandomPointVec2();
        env.info("Random Point: " .. randomPoint.x .. ", " .. randomPoint.z)

        local spawnwarehouse = SPAWNSTATIC:NewFromStatic("EQ Warehouse", country.id.cjtf_red)
        local spawnedwarehouse = spawnwarehouse:SpawnFromPointVec2(randomPoint,360,self.alias .. "_Warehouse")

        local circularZone = ZONE_RADIUS:New(self.alias .. "_Zone", randomPoint, 500)
        circularZone:DrawZone(-1, {0, 1, 0}, 1, {0, 1, 0}, 0.2, 1, false)
        self.pickUpZone = circularZone


        local self = BASE:Inherit(self,FACTORY:New(spawnedwarehouse, self.alias .. " factory", self.pickUpZone))

        env.info("Tile created: " .. self.alias .. " calition: " .. coalition)

        return self
    end


end

