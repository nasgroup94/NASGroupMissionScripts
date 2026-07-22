NASG_ATC = NASG_ATC or {}
NASG_ATC_TAXIGRAPH = NASG_ATC_TAXIGRAPH or {}

---------------------------------------------------------------------------
-- NASG_ATC dynamic taxi routing.
--
-- DCS does NOT expose the airport taxiway network to scripting, so the
-- taxiway topology and names must be authored per airport. This module
-- takes a small node/edge graph and computes taxi routes (ordered lists of
-- taxiway names) between any two points with a shortest-path search. That
-- replaces hand-listing one route per (parking area, runway) pair: author
-- the graph once, and every pairing — plus "nearest exit ramp to the jet's
-- live position, then to parking" — is computed on demand.
--
-- Graph schema (airport.TaxiGraph):
--
--   TaxiGraph = {
--       -- Optional map from runway id to the node representing that
--       -- runway's departure/hold-short point.
--       RunwayNodes = { ["27"] = "rwy27", ["09"] = "rwy09" },
--       -- Optional map from runway id to the EOR node for that runway.
--       EORNodes    = { ["27"] = "eor27" },
--
--       Nodes = {
--           -- Every node needs a unique Name. Type is optional and only
--           -- used for filtered nearest-node lookups:
--           --   "parking" | "exit" | "junction" | "runway"  (default "junction")
--           --
--           -- A node MAY carry a coordinate source (used for edge distance
--           -- costs and nearest-node selection). Topology/route names work
--           -- WITHOUT coordinates; costs then default to 1 per edge. Provide
--           -- exactly one of:
--           --   Zone        = "ME_ZONE_NAME"   -- zone centre
--           --   Vec2        = { x = <north>, y = <east> }  -- DCS map coords
--           --   Runway      = "27"             -- resolved from airbase data
--           --   ParkingSpot = 12               -- terminal id, from airbase data
--           { Name = "west_ramp", Type = "parking", Zone = "AL_MINHAD_WEST_RAMP" },
--           { Name = "rwy27",     Type = "runway",  Runway = "27" },
--           ...
--       },
--
--       Edges = {
--           -- Taxiway is the spoken name for this segment (omit for
--           -- unnamed connectors). OneWay defaults to false (bidirectional).
--           -- Cost defaults to the geometric distance between the two node
--           -- coordinates, or 1 when a coordinate is unavailable.
--           { From = "west_ramp", To = "j_hotel", Taxiway = "Hotel" },
--           { From = "j_hotel",   To = "rwy27",   Taxiway = "Golf"  },
--           ...
--       },
--   }
--
-- A parking area may also carry `Node = "<node name>"` to bind it to its
-- graph node; otherwise the nearest "parking" node to the parking zone is
-- used. Airports without a TaxiGraph are unaffected — callers fall back to
-- the static TaxiRoutes tables.
---------------------------------------------------------------------------

-- Edge cost used when a node coordinate cannot be resolved (topology-only).
NASG_ATC_TAXIGRAPH.DefaultEdgeCost = 1

function NASG_ATC_TAXIGRAPH:Log(msg)
    NASG_ATC:Log("[TaxiGraph] " .. tostring(msg))
end

-- Resolve (and cache) a node's world coordinate from its declared source.
-- Only successful lookups are cached so transient failures can retry.
function NASG_ATC_TAXIGRAPH:ResolveNodeCoordinate(airport, node)
    if not node then
        return nil
    end

    if node._coord then
        return node._coord
    end

    local coord = nil

    pcall(function()
        if node.Vec2 and node.Vec2.x and node.Vec2.y then
            coord = COORDINATE:NewFromVec2(node.Vec2)
        elseif node.Zone then
            local zone = ZONE:FindByName(node.Zone)

            if zone then
                coord = zone:GetCoordinate()
            end
        elseif node.Runway and airport and airport.AirbaseName then
            local airbase = AIRBASE:FindByName(airport.AirbaseName)

            if airbase then
                local runway = airbase:GetRunwayByName(tostring(node.Runway))

                if runway and runway.position then
                    coord = runway.position
                end
            end
        elseif node.ParkingSpot and airport and airport.AirbaseName then
            local airbase = AIRBASE:FindByName(airport.AirbaseName)

            if airbase then
                local spot = airbase:GetParkingSpotData(node.ParkingSpot)

                if spot then
                    coord = spot.Coordinate
                end
            end
        end
    end)

    if coord then
        node._coord = coord
    end

    return coord
end

-- Build (and cache) the adjacency list for an airport's taxi graph.
function NASG_ATC_TAXIGRAPH:Build(airport)
    if not airport or not airport.TaxiGraph then
        return nil
    end

    if airport._TaxiRuntime then
        return airport._TaxiRuntime
    end

    local graph = airport.TaxiGraph
    local nodesByName = {}

    for _, node in ipairs(graph.Nodes or {}) do
        if node.Name then
            nodesByName[node.Name] = node
        end
    end

    local adjacency = {}

    local function addEdge(from, to, taxiway, cost)
        adjacency[from] = adjacency[from] or {}
        table.insert(adjacency[from], { to = to, taxiway = taxiway, cost = cost })
    end

    for _, edge in ipairs(graph.Edges or {}) do
        local fromNode = nodesByName[edge.From]
        local toNode = nodesByName[edge.To]

        if not fromNode or not toNode then
            self:Log(string.format(
                    "Edge references unknown node: %s -> %s (airport %s)",
                    tostring(edge.From),
                    tostring(edge.To),
                    tostring(airport.Id)
            ))
        else
            local cost = edge.Cost

            if not cost then
                local a = self:ResolveNodeCoordinate(airport, fromNode)
                local b = self:ResolveNodeCoordinate(airport, toNode)

                if a and b then
                    cost = NASG_ATC:GetCoordinateDistanceMeters(a, b) or self.DefaultEdgeCost
                else
                    cost = self.DefaultEdgeCost
                end
            end

            addEdge(edge.From, edge.To, edge.Taxiway, cost)

            if not edge.OneWay then
                addEdge(edge.To, edge.From, edge.Taxiway, cost)
            end
        end
    end

    airport._TaxiRuntime = {
        NodesByName = nodesByName,
        Adjacency = adjacency,
    }

    return airport._TaxiRuntime
end

-- Shortest path between two named nodes.
-- Returns { Nodes = {...}, Taxiways = {...}, DistanceMeters = n } or nil.
-- Taxiways collapses consecutive duplicate segment names.
function NASG_ATC_TAXIGRAPH:ComputeRoute(airport, fromName, toName)
    local runtime = self:Build(airport)

    if not runtime or not fromName or not toName then
        return nil
    end

    if not runtime.NodesByName[fromName] or not runtime.NodesByName[toName] then
        self:Log(string.format(
                "Route endpoints missing: from=%s to=%s (airport %s)",
                tostring(fromName),
                tostring(toName),
                tostring(airport.Id)
        ))
        return nil
    end

    if fromName == toName then
        return { Nodes = { fromName }, Taxiways = {}, DistanceMeters = 0 }
    end

    local adjacency = runtime.Adjacency
    local dist = {}
    local prev = {}
    local prevEdge = {}
    local visited = {}

    dist[fromName] = 0

    -- O(V^2) Dijkstra; airport graphs are tiny so a heap is unnecessary.
    local function pickClosest()
        local bestName, bestDist = nil, nil

        for name, d in pairs(dist) do
            if not visited[name] and (bestDist == nil or d < bestDist) then
                bestName, bestDist = name, d
            end
        end

        return bestName
    end

    while true do
        local u = pickClosest()

        if not u then
            break
        end

        if u == toName then
            break
        end

        visited[u] = true

        for _, edge in ipairs(adjacency[u] or {}) do
            if not visited[edge.to] then
                local nd = dist[u] + (edge.cost or self.DefaultEdgeCost)

                if dist[edge.to] == nil or nd < dist[edge.to] then
                    dist[edge.to] = nd
                    prev[edge.to] = u
                    prevEdge[edge.to] = edge
                end
            end
        end
    end

    if dist[toName] == nil then
        self:Log(string.format(
                "No taxi path from %s to %s (airport %s)",
                tostring(fromName),
                tostring(toName),
                tostring(airport.Id)
        ))
        return nil
    end

    -- Reconstruct the node path and the edges traversed.
    local nodes = {}
    local edgesInOrder = {}
    local cur = toName

    while cur do
        table.insert(nodes, 1, cur)

        if prevEdge[cur] then
            table.insert(edgesInOrder, 1, prevEdge[cur])
        end

        cur = prev[cur]
    end

    -- Collapse consecutive duplicate taxiway names, drop unnamed connectors.
    local taxiways = {}
    local last = nil

    for _, edge in ipairs(edgesInOrder) do
        local taxiway = edge.taxiway

        if taxiway and taxiway ~= "" and taxiway ~= last then
            table.insert(taxiways, taxiway)
            last = taxiway
        end
    end

    return { Nodes = nodes, Taxiways = taxiways, DistanceMeters = dist[toName] }
end

-- Nearest node to a coordinate, optionally restricted to a node Type.
-- Returns nodeName, distanceMeters.
function NASG_ATC_TAXIGRAPH:FindNearestNode(airport, coordinate, typeFilter)
    local runtime = self:Build(airport)

    if not runtime or not coordinate then
        return nil
    end

    local bestName, bestDist = nil, nil

    for name, node in pairs(runtime.NodesByName) do
        if not typeFilter or node.Type == typeFilter then
            local c = self:ResolveNodeCoordinate(airport, node)

            if c then
                local d = NASG_ATC:GetCoordinateDistanceMeters(coordinate, c)

                if d and (bestDist == nil or d < bestDist) then
                    bestName, bestDist = name, d
                end
            end
        end
    end

    return bestName, bestDist
end

-- Resolve the graph node for a parking area.
function NASG_ATC_TAXIGRAPH:GetParkingNode(airport, parkingArea)
    if not parkingArea then
        return nil
    end

    if parkingArea.Node then
        return parkingArea.Node
    end

    -- Fallback: nearest graph node to the parking area's coordinate, resolved
    -- from whichever definition method the area uses (SpotIDs/Center/Zone).
    local coord = NASG_ATC:GetParkingAreaCoordinate(airport, parkingArea)

    if coord then
        local parkingNode = self:FindNearestNode(airport, coord, "parking")

        if parkingNode then
            return parkingNode
        end

        return (self:FindNearestNode(airport, coord))
    end

    return nil
end

-- Resolve the graph node for a runway (departure / hold-short point).
function NASG_ATC_TAXIGRAPH:GetRunwayNode(airport, runway)
    local runtime = self:Build(airport)

    if not runtime then
        return nil
    end

    local graph = airport.TaxiGraph
    local key = tostring(runway or "")
    local keyNoLR = key:gsub("[LRC]$", "")

    if graph.RunwayNodes then
        if graph.RunwayNodes[key] then
            return graph.RunwayNodes[key]
        end

        if graph.RunwayNodes[keyNoLR] then
            return graph.RunwayNodes[keyNoLR]
        end
    end

    for name, node in pairs(runtime.NodesByName) do
        if node.Type == "runway" then
            local nodeRunway = tostring(node.Runway or "")

            if nodeRunway == key or nodeRunway:gsub("[LRC]$", "") == keyNoLR then
                return name
            end
        end
    end

    return nil
end

-- Resolve the EOR node for a runway.
function NASG_ATC_TAXIGRAPH:GetEORNode(airport, runway)
    local runtime = self:Build(airport)

    if not runtime or not airport.TaxiGraph.EORNodes then
        return nil
    end

    local key = tostring(runway or "")
    local keyNoLR = key:gsub("[LRC]$", "")

    return airport.TaxiGraph.EORNodes[key] or airport.TaxiGraph.EORNodes[keyNoLR]
end

---------------------------------------------------------------------------
-- Public route builders. Each returns (taxiwayList, routeDetail) or nil to
-- signal the caller should fall back to static routes.
---------------------------------------------------------------------------

-- Departure: parking area -> runway hold-short.
function NASG_ATC_TAXIGRAPH:RouteParkingToRunway(airport, parkingArea, runway)
    local fromNode = self:GetParkingNode(airport, parkingArea)
    local toNode = self:GetRunwayNode(airport, runway)
    local result = fromNode and toNode and self:ComputeRoute(airport, fromNode, toNode)

    if result and #result.Taxiways > 0 then
        return result.Taxiways, result
    end

    return nil
end

-- Departure via EOR: parking area -> EOR point.
function NASG_ATC_TAXIGRAPH:RouteParkingToEOR(airport, parkingArea, runway)
    local fromNode = self:GetParkingNode(airport, parkingArea)
    local toNode = self:GetEORNode(airport, runway)
    local result = fromNode and toNode and self:ComputeRoute(airport, fromNode, toNode)

    if result and #result.Taxiways > 0 then
        return result.Taxiways, result
    end

    return nil
end

-- Arrival / taxi-back: from the aircraft's CURRENT position (nearest node,
-- typically the runway exit ramp it vacated onto) to its parking area.
function NASG_ATC_TAXIGRAPH:RouteFromClientToParking(airport, client, parkingArea)
    if not client then
        return nil
    end

    local coord = nil

    pcall(function()
        coord = client:GetCoordinate()
    end)

    if not coord then
        return nil
    end

    local fromNode = self:FindNearestNode(airport, coord)
    local toNode = self:GetParkingNode(airport, parkingArea)
    local result = fromNode and toNode and self:ComputeRoute(airport, fromNode, toNode)

    if result and #result.Taxiways > 0 then
        return result.Taxiways, result
    end

    return nil
end

NASG_ATC:Log("NASG_ATC_TaxiGraph loaded")
