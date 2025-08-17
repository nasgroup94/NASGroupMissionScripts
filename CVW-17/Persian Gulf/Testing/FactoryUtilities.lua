----------------------Fuel FACTORY-------------------
do
--@field #FACTORY
FACTORY ={
    ClassName = "FACTORY",
    verbosity = 0,
    lid = nil,
    Report = true,
    factory = nil,
    alias = nil,
    fuelQuantity = nil,
    Rate = 1, --pounds per hour
    Time = 10, -- poll the amount after this many seconds
    Type = 1, --type of factory 
    Coalition = nil,
    TransportThresh = nil,
    OpsGroup = nil,
    PickupZone = nil,
    DropOffZone = nil,
    Debug = false,
    offroadpaths = {},
    spawnzone = nil,
    fuelType = nil,
    equipmentType = nil,
    equipmentQuantity = nil,
    coalitionCheck = nil,
    suppliers = {},
   

}

FACTORY.version = "0.0.1"

--Creates a new factory from a static object and sets coalition from the static object
--@param #FACTORY self
--@param Wrapper.Static#STATIC factory The object used to represent the factory 
--@param #string Alias (Optional) The Alias of the factory
--@param CORE.Zone#ZONE pickUpZone the zone where ground assests are spawned for deliveries
--@return #FACTORY self
function FACTORY:New(factory,Alias,pickUpZone)
  local self = BASE:Inherit(self,WAREHOUSE:New(STATIC:FindByName(factory), Alias))
    self.PickupZone = pickUpZone
   -- if a string was given instead of a static then convert to static
    if type(factory)=="string" then
        local name = factory
        factory = UNIT:FindByName(name)
        if factory==nil then
            factory=STATIC:FindByName(name)
        end
    end

    --check if factory is static or UNIT
    if factory:IsInstanceOf("STATIC") then
      self.isUnit= false
    elseif factory:IsInstanceOf("UNIT") then
      self.isUnit = true
    else
      env.error("ERROR: Factory is not a STATIC or UNIT Object!")
      return nil
    end

    -- Nil check
    if factory == nil then
        env.error("ERROR:The FACTORY does not exist!")
        return nil
    else
      self.factory=factory
    end
  
    --Set alias
    self.alias=Alias or self.factory:GetName()

    self.coalition = self.factory:GetCoalition()

    --Set id for log file output
    self.lid = string.format("FACTORY %s | ", self.alias)

    self.spawnzone = ZONE_RADIUS:New(string.format("Factory %s spawn zone", self.factory:GetName()),factory:GetVec2(),250)
   



    return self
end
--Set debug mode on. Reports and message will be displayed as well as waypoint markings
--@param #FACTORY self
--@return #FACTORY self
function FACTORY:SetDebugOn()
  self.Debug=true
  return self
end

--Set debug mode off. This is the default
--@param #FACTORY self
--@return #FACTORY self
function FACTORY:SetDebugOff()
  self.Debug=false
  return self
end

--- Check if the factory is running.
-- @param #FACTORY self
-- @return #boolean If true, the factory is running and requests are processed.
function FACTORY:IsRunning()
  return self:is("Running")
end

function FACTORY:SetRate(Rate)
  self.Rate = Rate
  return self
end

function FACTORY:SetTime(Time)
  self.Time = Time
  return self
end

function FACTORY:SetFuelType(Type)
  self.Type = Type
  return self
end

function FACTORY:AddSupplier(Name,Supplier)
  table.insert(self.suppliers[Name],Supplier)
  return self
end


-- function FACTORY:Stop()
--    return self.fuelTimer:Stop()
-- end

-- function FACTORY:Start()
--     return self.fuelTimer:Start()
-- end

function FACTORY:SetTransportThresh(Thresh)
    self.TransportThresh = Thresh
end

-- function FACTORY:AddOffRoadPath(remotewarehouse, group, oneway)

--     -- Initial and final points are random points within the spawn zone.
--     local startcoord=self.spawnzone:GetRandomCoordinate()
--     local finalcoord=self.DropOffZone:GetRandomCoordinate()
  
--     -- Create new path from template group waypoints.
--     local path=self:_NewLane(group, startcoord, finalcoord)
  
--     if path==nil then
--       self:E(self.lid.."ERROR: Offroad path could not be added. Group present in ME?")
--       return
--     end
  
--     -- Debug info. Marks along path.
--     if path and self.Debug then
--       for i=1,#path do
--         local coord=path[i] --Core.Point#COORDINATE
--         local text=string.format("Off road path from %s to %s. Point %d.", self.alias, remotewarehouse.alias, i)
--         coord:MarkToCoalition(text, self:GetCoalition())
--       end
--     end
  
--     -- Name of the remote warehouse.
--     -- local remotename=remotewarehouse.warehouse:GetName()
--     local remotename = "test"
  
--     -- Create new table if no shipping lane exists yet.
--     if self.offroadpaths[remotename]==nil then
--       self.offroadpaths[remotename]={}
--     end
  
--     -- Add off road path.
--     table.insert(self.offroadpaths[remotename], path)
  
--     -- Add off road path in the opposite direction (if not forbidden).
--     if not oneway then
--       remotewarehouse:AddOffRoadPath(self, group, true)
--     end
  
--     return self
--   end


  -- function FACTORY:_NewLane(group, startcoord, finalcoord)

  --   local lane=nil
  
  --   if group then
  
  --     -- Get route from template.
  --     local lanepoints=group:GetTemplateRoutePoints()
  
  --     -- First and last waypoints
  --     local laneF=lanepoints[1]
  --     local laneL=lanepoints[#lanepoints]
  
  --     -- Get corresponding coordinates.
  --     local coordF=COORDINATE:New(laneF.x, 0, laneF.y)
  --     local coordL=COORDINATE:New(laneL.x, 0, laneL.y)
  
  --     -- Figure out which point is closer to the port of this warehouse.
  --     local distF=startcoord:Get2DDistance(coordF)
  --     local distL=startcoord:Get2DDistance(coordL)
  
  --     -- Add the lane. Need to take care of the wrong "direction".
  --     lane={}
  --     if distF<distL then
  --       for i=1,#lanepoints do
  --         local point=lanepoints[i]
  --         local coord=COORDINATE:New(point.x,0, point.y)
  --         table.insert(lane, coord)
  --       end
  --     else
  --       for i=#lanepoints,1,-1 do
  --         local point=lanepoints[i]
  --         local coord=COORDINATE:New(point.x,0, point.y)
  --         table.insert(lane, coord)
  --       end
  --     end
  
  --     -- Automatically add end point which is a random point inside the final port zone.
  --     table.insert(lane, #lane, finalcoord)
  
  --   end
  
  --   return lane
  -- end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- --On after the factory startswith
-- -- @param #FACTORY self
-- -- @param #string From From state
-- -- @param #string Event Event
-- -- @param #string To To state
-- function FACTORY:onAfterStart(From, Event,To)

--     -- Short info.
--     local text=string.format("Starting factory %s alias %s:\n",self.factory:GetName(), self.alias)
--     text=text..string.format("Coalition = %s\n", self:GetCoalitionName())
--     -- text=text..string.format("Country  = %s\n", self.factory:GetCountryName())
--     -- text=text..string.format("Airbase  = %s (category=%d)\n", self:GetAirbaseName(), self:GetAirbaseCategory())
--     self:E(text)



--       -- Handle events:
--   self:HandleEvent(EVENTS.Birth,          self._OnEventBirth)
--   self:HandleEvent(EVENTS.EngineStartup,  self._OnEventEngineStartup)
--   self:HandleEvent(EVENTS.Takeoff,        self._OnEventTakeOff)
--   self:HandleEvent(EVENTS.Land,           self._OnEventLanding)
--   self:HandleEvent(EVENTS.EngineShutdown, self._OnEventEngineShutdown)
--   self:HandleEvent(EVENTS.Crash,          self._OnEventCrashOrDead)
--   self:HandleEvent(EVENTS.Dead,           self._OnEventCrashOrDead)
--   self:HandleEvent(EVENTS.BaseCaptured,   self._OnEventBaseCaptured)
--   self:HandleEvent(EVENTS.MissionEnd,     self._OnEventMissionEnd)

--   self:__Status(-1)
-- end


-------------end FACTORY ---------------------
end
   
    -- self.spawnzone=ZONE_RADIUS:New(string.format("Warehouse %s spawn zone", self.FACTORY:GetName()), self.FACTORY:GetVec2(), 250)


    function fuelProduction()
        self.fuelQuantity = self.fuelQuantity + self.Rate
        self:E(self.Alias .. " currently has: " .. self.fuelQuantity .. "lbs of " .. self.Type)
        if(self.fuelQuantity >= self.TransportThresh)
        then
            self:E(self.Alias .. "Starting Delivery")
            local deliverFuel = OPSTRANSPORT:New(nil,self.PickupZone,self.DropOffZone)
            OpsGroup:AddOpsTransport(deliverFuel)
            self:E("Transport requested")
            self.fuelQuantity = self.fuelQuantity - self.TransportThresh
            self:E(self.Alias .. " now has: " .. self.fuelQuantity .. "lbs of " .. self.Type)
        end
    end


