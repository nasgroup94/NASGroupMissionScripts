
local redZoneUnits = SET_UNIT:New():FilterPrefixes("ZONE"):FilterOnce()

local EQTiles = {}




redZoneUnits:ForEachUnit(
    function(unit)
        local subName = string.match(unit:GetName(),   "^(.-)#") -- Extracts the part before the first "#"
        env.info("creating tile for unit: " .. subName .. " full name: " .. unit:GetName())
        table.insert(EQTiles, TILE:New(subName .. " Tile", coalition.side.RED, subName))
    end
)



local Agents=SET_GROUP:New():FilterPrefixes("EQ IADs"):FilterOnce()

redChief = CHIEF:New(coalition.side.RED, Agents ,"red Chief")
-- redChief:AddBorderZone(EQTile)
-- redZones:ForEachZone(function(zone)
--     redChief:AddBorderZone(TILE:New(zone, coalition.side.RED, nil, zone:GetName()))
-- end)

for _, tile in ipairs(EQTiles) do
    redChief:AddBorderZone(tile.zone)
end

-- Enable tactical overview.
redChief:SetTacticalOverviewOn()



-- Set strategy to DEFENSIVE: Only targets within the border of the chief's territory are attacked.
redChief:SetStrategy(CHIEF.Strategy.DEFENSIVE)
  
-- Start Chief after one second.
redChief:__Start(1)




redZoneUnits:ForEachUnit(
    function(unit)
        env.info("Unit Name: " .. unit:GetName())
    end
)


local function findNearestZoneFromOtherCoalition(unit, coalitionSide)
    local nearestZone = nil
    local shortestDistance = math.huge

    local allZones = SET_ZONE:New():FilterOnce() -- Get all zones
    allZones:ForEachZone(function(zone)
        if zone:GetCoalition() ~= coalitionSide then
            local distance = unit:GetCoordinate():Get2DDistance(zone:GetCoordinate())
            if distance < shortestDistance then
                shortestDistance = distance
                nearestZone = zone
            end
        end
    end)

    return nearestZone, shortestDistance
end

redZoneUnits:ForEachUnit(function(unit)
    local nearestZone, distance = findNearestZoneFromOtherCoalition(unit, coalition.side.RED)
    if nearestZone then
        env.info("Nearest zone to unit " .. unit:GetName() .. " is " .. nearestZone:GetName() .. " at distance " .. distance)
    else
        env.info("No zone found for unit " .. unit:GetName())
    end
end)

