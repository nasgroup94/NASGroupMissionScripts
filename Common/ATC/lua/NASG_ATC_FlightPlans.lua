NASG_ATC = NASG_ATC or {}

NASG_ATC.FlightPlanFile = NASG_ATC.FlightPlanFile
        or "C:/NASGroup/NASGroupMissionScripts/Common/ATC/tmp/nasg_atc_flight_plans.json"

NASG_ATC.FlightPlanRootFolder = NASG_ATC.FlightPlanRootFolder
        or "E:/DCS Stuff/FlightPlans"

NASG_ATC.FlightPlanDayFormat = NASG_ATC.FlightPlanDayFormat
        or "%Y-%m-%d"

NASG_ATC.DTCFlightPlanEnabled = NASG_ATC.DTCFlightPlanEnabled
if NASG_ATC.DTCFlightPlanEnabled == nil then
    NASG_ATC.DTCFlightPlanEnabled = true
end

NASG_ATC.FlightPlans = NASG_ATC.FlightPlans or {}
NASG_ATC.FlightPlansById = NASG_ATC.FlightPlansById or {}
NASG_ATC.FlightPlansByLookup = NASG_ATC.FlightPlansByLookup or {}
NASG_ATC.FlightPlanFileMTime = NASG_ATC.FlightPlanFileMTime or nil

-- Mission check-in (see CheckInToMission/GetMissionFlightPlan below):
-- Root/<today>/<mission number>/<platform-specific plan>, indexed as
-- [normalized mission number][normalized aircraft_type] = flightPlan.
NASG_ATC.MissionFlightPlansByNumber = NASG_ATC.MissionFlightPlansByNumber or {}


function NASG_ATC:NormalizeFlightPlanLookup(value)
    local text = tostring(value or "")

    text = text:gsub("|.*$", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("%s+", "")
    text = text:gsub("%-", "")
    text = text:gsub("_", "")
    text = string.upper(text)

    return text
end

-- Classic edit distance between two already-normalized strings.
function NASG_ATC:LevenshteinDistance(a, b)
    local la, lb = #a, #b

    if la == 0 then
        return lb
    end

    if lb == 0 then
        return la
    end

    local prevRow = {}

    for j = 0, lb do
        prevRow[j] = j
    end

    for i = 1, la do
        local currRow = { [0] = i }
        local ca = a:byte(i)

        for j = 1, lb do
            local cost = (ca == b:byte(j)) and 0 or 1
            currRow[j] = math.min(
                    prevRow[j] + 1,
                    currRow[j - 1] + 1,
                    prevRow[j - 1] + cost
            )
        end

        prevRow = currRow
    end

    return prevRow[lb]
end

-- Recovers from an STT mishear of a fix/point/waypoint name (e.g. "bopeet"
-- heard for "BOPIT") by finding the closest of `keys` (a list of names
-- already run through NormalizeFlightPlanLookup) to `value` by edit
-- distance. Tolerance scales with word length so short names (3-4 letters)
-- still require a near-exact hit. A tie between two equally-close
-- candidates is treated as no match — guessing wrong sends a pilot to the
-- wrong place, so ambiguity should fall through to "say again" instead.
function NASG_ATC:FuzzyMatchLookupKey(value, keys)
    local query = self:NormalizeFlightPlanLookup(value)

    if query == "" or #query < 3 then
        return nil
    end

    local tolerance = math.max(1, math.floor(#query / 4))
    local bestKey, bestDistance, tie = nil, tolerance + 1, false

    for _, key in ipairs(keys) do
        if key ~= "" and key ~= query then
            local distance = self:LevenshteinDistance(query, key)

            if distance <= tolerance then
                if distance < bestDistance then
                    bestKey, bestDistance, tie = key, distance, false
                elseif distance == bestDistance then
                    tie = true
                end
            end
        end
    end

    if tie then
        return nil
    end

    return bestKey
end

function NASG_ATC:RegisterFlightPlanLookup(value, flightPlan)
    local key = self:NormalizeFlightPlanLookup(value)

    if key and key ~= "" then
        self.FlightPlansByLookup[key] = flightPlan
    end
end

function NASG_ATC:JoinPath(...)
    local parts = {...}
    local cleaned = {}

    for _, part in ipairs(parts) do
        local text = tostring(part or "")

        if text ~= "" then
            text = text:gsub("\\", "/")
            text = text:gsub("^/+", "")
            text = text:gsub("/+$", "")
            cleaned[#cleaned + 1] = text
        end
    end

    if #cleaned == 0 then
        return ""
    end

    local first = tostring(parts[1] or ""):gsub("\\", "/")
    local drivePrefix = first:match("^(%a:)[/\\]?")

    if drivePrefix then
        local output = drivePrefix

        for index, part in ipairs(cleaned) do
            if index == 1 then
                local withoutDrive = part:gsub("^%a:", "")
                withoutDrive = withoutDrive:gsub("^/+", "")

                if withoutDrive ~= "" then
                    output = output .. "/" .. withoutDrive
                end
            else
                output = output .. "/" .. part
            end
        end

        return output
    end

    return table.concat(cleaned, "/")
end

function NASG_ATC:GetTableValueByPath(data, path)
    local current = data

    for part in tostring(path or ""):gmatch("[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end

        if tonumber(part) then
            current = current[tonumber(part)]
        else
            current = current[part]
        end

        if current == nil then
            return nil
        end
    end

    return current
end

function NASG_ATC:FindFirstTableByPaths(data, paths)
    for _, path in ipairs(paths or {}) do
        local value = self:GetTableValueByPath(data, path)

        if type(value) == "table" then
            return value
        end
    end

    return nil
end

function NASG_ATC:DecodeJsonText(text)
    if not text or text == "" then
        return nil
    end

    local data = nil

    if net and net.json2lua then
        local ok, result = pcall(function()
            return net.json2lua(text)
        end)

        if ok and result then
            data = result
        end
    end

    if not data and json and json.decode then
        local ok, result = pcall(function()
            return json.decode(text)
        end)

        if ok and result then
            data = result
        end
    end

    return data
end

function NASG_ATC:ReadTextFile(path)
    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local text = file:read("*all")
    file:close()

    return text
end

function NASG_ATC:DecodeJsonFile(path)
    return self:DecodeJsonText(self:ReadTextFile(path))
end

function NASG_ATC:GetDTCValue(data, paths)
    for _, path in ipairs(paths or {}) do
        local value = self:GetTableValueByPath(data, path)

        if value ~= nil and value ~= "" then
            return value
        end
    end

    return nil
end

function NASG_ATC:GetFileStem(path)
    local filename = tostring(path or ""):gsub("\\", "/"):match("([^/]+)$") or tostring(path or "")
    return filename:gsub("%.[^%.]+$", "")
end

function NASG_ATC:GetParentFolderName(path)
    local normalized = tostring(path or ""):gsub("\\", "/")
    local folder = normalized:match("(.+)/[^/]+$")

    if not folder then
        return nil
    end

    return folder:match("([^/]+)$")
end

function NASG_ATC:GetCurrentFlightPlanDayFolder()
    local root = self.FlightPlanRootFolder

    if not root or root == "" then
        return nil
    end

    local dayFormat = self.FlightPlanDayFormat or "%Y-%m-%d"
    local dayName = os.date(dayFormat)

    return self:JoinPath(root, dayName)
end

function NASG_ATC:GetCallsignStemAndNumber(callsign)
    local compact = self:NormalizeFlightPlanLookup(callsign)
    local stem, number = compact:match("^([A-Z]+)(%d+)$")

    if not stem or not number then
        return nil, nil
    end

    return stem, tonumber(number)
end

function NASG_ATC:AddFlightPlanAliases(flightPlan, aliases)
    if not flightPlan then
        return
    end

    flightPlan.aliases = flightPlan.aliases or flightPlan.Aliases or {}

    local existing = {}

    for _, alias in ipairs(flightPlan.aliases or {}) do
        existing[self:NormalizeFlightPlanLookup(alias)] = true
    end

    for _, alias in ipairs(aliases or {}) do
        local key = self:NormalizeFlightPlanLookup(alias)

        if key ~= "" and not existing[key] then
            flightPlan.aliases[#flightPlan.aliases + 1] = alias
            existing[key] = true
        end
    end
end

function NASG_ATC:GetFlightPlanCallsignFolder(path)
    return self:GetParentFolderName(path)
end


function NASG_ATC:NormalizeDTCWaypoint(rawWaypoint, index)
    if type(rawWaypoint) ~= "table" then
        return nil
    end

    local number = tonumber(
            rawWaypoint.number
                    or rawWaypoint.Number
                    or rawWaypoint.sequence
                    or rawWaypoint.Sequence
                    or rawWaypoint.seq
                    or rawWaypoint.Seq
                    or rawWaypoint.id
                    or rawWaypoint.Id
                    or rawWaypoint.waypoint
                    or rawWaypoint.Waypoint
                    or index
    )

    local name = tostring(
            rawWaypoint.name
                    or rawWaypoint.Name
                    or rawWaypoint.label
                    or rawWaypoint.Label
                    or rawWaypoint.ident
                    or rawWaypoint.Ident
                    or rawWaypoint.wpName
                    or rawWaypoint.WpName
                    or ("WP" .. tostring(number or index))
    )

    local position = rawWaypoint.position or rawWaypoint.Position or rawWaypoint.coordinate or rawWaypoint.Coordinate or {}

    local lat = tonumber(
            rawWaypoint.lat
                    or rawWaypoint.Lat
                    or rawWaypoint.latitude
                    or rawWaypoint.Latitude
                    or position.lat
                    or position.Lat
                    or position.latitude
                    or position.Latitude
                    or rawWaypoint.y
                    or rawWaypoint.Y
    )

    local lon = tonumber(
            rawWaypoint.lon
                    or rawWaypoint.Lon
                    or rawWaypoint.lng
                    or rawWaypoint.Lng
                    or rawWaypoint.longitude
                    or rawWaypoint.Longitude
                    or position.lon
                    or position.Lon
                    or position.lng
                    or position.Lng
                    or position.longitude
                    or position.Longitude
                    or rawWaypoint.x
                    or rawWaypoint.X
    )

    local alt = tonumber(
            rawWaypoint.alt
                    or rawWaypoint.Alt
                    or rawWaypoint.altitude
                    or rawWaypoint.Altitude
                    or rawWaypoint.elevation
                    or rawWaypoint.Elevation
                    or rawWaypoint.altitudeFt
                    or rawWaypoint.AltitudeFt
    )

    local speed = tonumber(
            rawWaypoint.speed
                    or rawWaypoint.Speed
                    or rawWaypoint.groundSpeed
                    or rawWaypoint.GroundSpeed
                    or rawWaypoint.gs
                    or rawWaypoint.GS
                    or rawWaypoint.speedKts
                    or rawWaypoint.SpeedKts
    )

    local role = tostring(
            rawWaypoint.role
                    or rawWaypoint.Role
                    or rawWaypoint.type
                    or rawWaypoint.Type
                    or rawWaypoint.action
                    or rawWaypoint.Action
                    or ""
    )

    if not lat or not lon then
        return nil
    end

    return {
        waypoint = number or index,
        name = name,
        lat = lat,
        lon = lon,
        alt = alt,
        speed = speed,
        role = role,
        source = "dtc",
        raw = rawWaypoint,
    }
end

function NASG_ATC:ExtractDTCWaypoints(data)
    local waypointTables = {
        "waypoints",
        "Waypoints",
        "flightPlan.waypoints",
        "flightPlan.Waypoints",
        "flight_plan.waypoints",
        "flight_plan.Waypoints",
        "route.waypoints",
        "route.Waypoints",
        "mission.waypoints",
        "mission.Waypoints",
        "aircraft.waypoints",
        "aircraft.Waypoints",
        "data.waypoints",
        "data.Waypoints",
        "dtc.waypoints",
        "dtc.Waypoints",
    }

    local rawWaypoints = self:FindFirstTableByPaths(data, waypointTables)

    if not rawWaypoints then
        return {}
    end

    local waypoints = {}

    for index, rawWaypoint in ipairs(rawWaypoints) do
        local waypoint = self:NormalizeDTCWaypoint(rawWaypoint, index)

        if waypoint then
            waypoints[#waypoints + 1] = waypoint
        end
    end

    return waypoints
end

function NASG_ATC:BuildFlightPlanFromDTC(path, data)
    local waypoints = self:ExtractDTCWaypoints(data)

    if #waypoints == 0 then
        self:Log("DTC/JSON has no usable waypoints: " .. tostring(path))
        return nil
    end

    local stem = self:GetFileStem(path)

    local callsign = self:GetDTCValue(data, {
        "callsign",
        "Callsign",
        "callSign",
        "pilot.callsign",
        "pilot.Callsign",
        "aircraft.callsign",
        "aircraft.Callsign",
        "mission.callsign",
        "mission.Callsign",
        "flight.callsign",
        "flight.Callsign",
        "data.callsign",
        "data.Callsign",
    }) or stem

    local playerName = self:GetDTCValue(data, {
        "player_name",
        "playerName",
        "PlayerName",
        "pilot.name",
        "pilot.Name",
        "aircraft.playerName",
        "aircraft.PlayerName",
        "client_name",
        "clientName",
        "ClientName",
    })

    local aircraftType = self:GetDTCValue(data, {
        "aircraft.type",
        "aircraft.Type",
        "aircraftType",
        "AircraftType",
        "type",
        "Type",
    })

    local sequenceRefs = {}

    for _, waypoint in ipairs(waypoints) do
        sequenceRefs[#sequenceRefs + 1] = waypoint.waypoint
    end

    return {
        id = "dtc_" .. self:NormalizeFlightPlanLookup(stem),
        source = "dtc",
        source_file = path,
        callsign = tostring(callsign),
        player_name = playerName,
        aircraft_type = aircraftType,
        aliases = {
            stem,
            callsign,
            playerName,
        },
        waypoints = waypoints,
        sequences = {
            {
                name = "DTC",
                waypoints = sequenceRefs,
                max_lateral_error_nm = 5,
            },
        },
    }
end


-- DCS DTC exports (Hornet WYPT steerpoints) store position as a projected
-- {x, y} pair in the mission's world coordinate frame (x=north, y=east),
-- not lat/lon, so it can't be treated like the generic lat/lon DTC schema.
-- coord.LOtoLL is the same engine call MOOSE/mist/CTLD use for this
-- conversion elsewhere in this codebase, so we lean on it here too rather
-- than hand-rolling a per-terrain projection.
function NASG_ATC:ConvertDCSPointToLatLon(x, y)
    x = tonumber(x)
    y = tonumber(y)

    if not x or not y then
        return nil, nil
    end

    if not coord or not coord.LOtoLL then
        return nil, nil
    end

    local ok, lat, lon = pcall(coord.LOtoLL, { x = x, y = 0, z = y })

    if ok and lat and lon then
        return lat, lon
    end

    return nil, nil
end

function NASG_ATC:NormalizeHornetDTCWaypoint(rawPoint)
    if type(rawPoint) ~= "table" then
        return nil
    end

    local lat, lon = self:ConvertDCSPointToLatLon(rawPoint.x, rawPoint.y)

    if not lat or not lon then
        return nil
    end

    local number = tonumber(rawPoint.wypt_num)
    local id = tostring(rawPoint.id or ("STPT" .. tostring(number or "")))
    local note = tostring(rawPoint.note or "")

    return {
        waypoint = number,
        name = (note ~= "" and note) or id,
        stpt_id = id,
        lat = lat,
        lon = lon,
        alt = tonumber(rawPoint.alt),
        source = "dtc_hornet",
        raw = rawPoint,
    }
end

-- Hornet steerpoints tag their own route membership/order via R1/R2/R3 (+
-- R1_order/R2_order/R3_order) rather than a separate ordered list, so we
-- rebuild each named route straight from those flags instead of parsing
-- WYPT.NAV_ROUTE's parallel (and less complete) speed/ETA table.
function NASG_ATC:BuildHornetDTCRouteSequences(rawPoints, waypointsByStptId)
    local sequences = {}

    for _, flag in ipairs({ "R1", "R2", "R3" }) do
        local ordered = {}

        for _, rawPoint in ipairs(rawPoints or {}) do
            if type(rawPoint) == "table" and rawPoint[flag] then
                ordered[#ordered + 1] = {
                    order = tonumber(rawPoint[flag .. "_order"]) or 0,
                    id = tostring(rawPoint.id or ""),
                }
            end
        end

        if #ordered > 0 then
            table.sort(ordered, function(a, b) return a.order < b.order end)

            local waypointRefs = {}

            for _, entry in ipairs(ordered) do
                local waypoint = waypointsByStptId[entry.id]

                if waypoint then
                    waypointRefs[#waypointRefs + 1] = waypoint.waypoint
                end
            end

            if #waypointRefs >= 2 then
                sequences[#sequences + 1] = {
                    name = "Route " .. flag:sub(2),
                    waypoints = waypointRefs,
                    max_lateral_error_nm = 5,
                }
            end
        end
    end

    return sequences
end

function NASG_ATC:ExtractHornetDTCWaypoints(data)
    local rawPoints = self:GetTableValueByPath(data, "data.WYPT.NAV_PTS")

    if type(rawPoints) ~= "table" then
        return nil, nil, nil
    end

    local waypoints = {}
    local waypointsByStptId = {}

    for index, rawPoint in ipairs(rawPoints) do
        local waypoint = self:NormalizeHornetDTCWaypoint(rawPoint)

        if waypoint then
            waypoint.waypoint = waypoint.waypoint or index
            waypoints[#waypoints + 1] = waypoint
            waypointsByStptId[waypoint.stpt_id] = waypoint
        end
    end

    table.sort(waypoints, function(a, b) return (a.waypoint or 0) < (b.waypoint or 0) end)

    return waypoints, waypointsByStptId, rawPoints
end

function NASG_ATC:BuildFlightPlanFromHornetDTC(path, data)
    local waypoints, waypointsByStptId, rawPoints = self:ExtractHornetDTCWaypoints(data)

    if not waypoints or #waypoints == 0 then
        self:Log("Hornet DTC has no usable steerpoints (map coordinate conversion unavailable outside a running mission?): " .. tostring(path))
        return nil
    end

    local stem = self:GetFileStem(path)

    local callsign = self:GetDTCValue(data, {
        "name",
        "data.name",
        "callsign",
        "Callsign",
    }) or stem

    local aircraftType = self:GetDTCValue(data, {
        "type",
        "Type",
        "data.type",
        "data.Type",
    })

    local sequenceRefs = {}

    for _, waypoint in ipairs(waypoints) do
        sequenceRefs[#sequenceRefs + 1] = waypoint.waypoint
    end

    local sequences = {
        {
            name = "DTC",
            waypoints = sequenceRefs,
            max_lateral_error_nm = 5,
        },
    }

    for _, routeSequence in ipairs(self:BuildHornetDTCRouteSequences(rawPoints, waypointsByStptId)) do
        sequences[#sequences + 1] = routeSequence
    end

    return {
        id = "dtc_" .. self:NormalizeFlightPlanLookup(stem),
        source = "dtc_hornet",
        source_file = path,
        callsign = tostring(callsign),
        aircraft_type = aircraftType,
        aliases = {
            stem,
            callsign,
        },
        waypoints = waypoints,
        sequences = sequences,
    }
end


-- F-14 (and other DCS modules that share its DTC schema) store steerpoints
-- as a fixed set of NAV "pages" (route slots), most of them empty templates
-- -- only the page(s) the pilot actually populated have a non-empty
-- `waypoints` array. Unlike the Hornet, these waypoints already carry real
-- lat/lon, so no coordinate conversion is needed; x/y is kept only as a
-- fallback for modules/exports that omit lat/lon.
function NASG_ATC:NormalizeNavPageDTCWaypoint(rawWaypoint, waypointNumber, pageLabel)
    if type(rawWaypoint) ~= "table" then
        return nil
    end

    local lat = tonumber(rawWaypoint.lat)
    local lon = tonumber(rawWaypoint.lon)

    if not lat or not lon then
        lat, lon = self:ConvertDCSPointToLatLon(rawWaypoint.x, rawWaypoint.y)
    end

    if not lat or not lon then
        return nil
    end

    local name = tostring(rawWaypoint.name or "")

    if name == "" then
        name = pageLabel .. " WP" .. tostring(waypointNumber)
    end

    return {
        waypoint = waypointNumber,
        name = name,
        lat = lat,
        lon = lon,
        alt = tonumber(rawWaypoint.elev),
        speed = tonumber(rawWaypoint.spd),
        source = "dtc_navpages",
        raw = rawWaypoint,
    }
end

function NASG_ATC:ExtractNavPageDTCWaypoints(data)
    local navPages = self:GetTableValueByPath(data, "data.NAV")

    if type(navPages) ~= "table" then
        return nil, nil
    end

    local waypoints = {}
    local sequences = {}
    local runningNumber = 0

    for pageIndex, navPage in ipairs(navPages) do
        local rawWaypoints = type(navPage) == "table" and navPage.waypoints or nil

        if type(rawWaypoints) == "table" and rawWaypoints[1] then
            local pageName = navPage.name

            if type(pageName) ~= "string" or pageName == "" then
                pageName = "NAV " .. tostring(pageIndex)
            end

            local sequenceRefs = {}

            for _, rawWaypoint in ipairs(rawWaypoints) do
                runningNumber = runningNumber + 1

                local waypoint = self:NormalizeNavPageDTCWaypoint(rawWaypoint, runningNumber, pageName)

                if waypoint then
                    waypoints[#waypoints + 1] = waypoint
                    sequenceRefs[#sequenceRefs + 1] = waypoint.waypoint
                end
            end

            if #sequenceRefs >= 2 then
                sequences[#sequences + 1] = {
                    name = pageName,
                    waypoints = sequenceRefs,
                    max_lateral_error_nm = 5,
                }
            end
        end
    end

    return waypoints, sequences
end

function NASG_ATC:BuildFlightPlanFromNavPagesDTC(path, data)
    local waypoints, sequences = self:ExtractNavPageDTCWaypoints(data)

    if not waypoints or #waypoints == 0 then
        self:Log("NAV-page DTC has no usable waypoints: " .. tostring(path))
        return nil
    end

    local stem = self:GetFileStem(path)

    local callsign = self:GetDTCValue(data, {
        "name",
        "data.name",
        "callsign",
        "Callsign",
    }) or stem

    local aircraftType = self:GetDTCValue(data, {
        "type",
        "Type",
        "data.type",
        "data.Type",
    })

    return {
        id = "dtc_" .. self:NormalizeFlightPlanLookup(stem),
        source = "dtc_navpages",
        source_file = path,
        callsign = tostring(callsign),
        aircraft_type = aircraftType,
        aliases = {
            stem,
            callsign,
        },
        waypoints = waypoints,
        sequences = sequences,
    }
end


function NASG_ATC:GetFlightPlanJsonKind(data)
    if type(data) ~= "table" then
        return "unknown"
    end

    if data.flight_plans or data.FlightPlans then
        return "nasg_atc"
    end

    local hornetWaypoints = self:GetTableValueByPath(data, "data.WYPT.NAV_PTS")

    if type(hornetWaypoints) == "table" and hornetWaypoints[1] then
        return "dtc_hornet"
    end

    local navPages = self:GetTableValueByPath(data, "data.NAV")

    if type(navPages) == "table" then
        for _, navPage in ipairs(navPages) do
            if type(navPage) == "table" and type(navPage.waypoints) == "table" and navPage.waypoints[1] then
                return "dtc_navpages"
            end
        end
    end

    if self:FindFirstTableByPaths(data, {
        "packages",
        "Packages",
        "flights",
        "Flights",
        "routes",
        "Routes",
        "route.waypoints",
        "route.Waypoints",
        "flightPlan.waypoints",
        "flightPlan.Waypoints",
        "mission.routes",
        "mission.Routes",
    }) then
        return "combatflite"
    end

    if self:FindFirstTableByPaths(data, {
        "waypoints",
        "Waypoints",
        "dtc.waypoints",
        "dtc.Waypoints",
        "aircraft.waypoints",
        "aircraft.Waypoints",
        "data.waypoints",
        "data.Waypoints",
    }) then
        return "dtc"
    end

    return "unknown"
end

function NASG_ATC:NormalizeCombatFliteJsonWaypoint(rawWaypoint, index)
    if type(rawWaypoint) ~= "table" then
        return nil
    end

    local waypoint = self:NormalizeDTCWaypoint(rawWaypoint, index)

    if waypoint then
        waypoint.source = "combatflite_json"
    end

    return waypoint
end

function NASG_ATC:ExtractCombatFliteJsonWaypoints(data)
    local waypointTables = {
        "waypoints",
        "Waypoints",
        "route.waypoints",
        "route.Waypoints",
        "routes.1.waypoints",
        "routes.1.Waypoints",
        "flightPlan.waypoints",
        "flightPlan.Waypoints",
        "flight_plan.waypoints",
        "flight_plan.Waypoints",
        "mission.waypoints",
        "mission.Waypoints",
        "mission.routes.1.waypoints",
        "mission.Routes.1.Waypoints",
        "flights.1.waypoints",
        "Flights.1.Waypoints",
        "flights.1.route.waypoints",
        "Flights.1.Route.Waypoints",
        "packages.1.flights.1.waypoints",
        "Packages.1.Flights.1.Waypoints",
        "packages.1.flights.1.route.waypoints",
        "Packages.1.Flights.1.Route.Waypoints",
    }

    local rawWaypoints = self:FindFirstTableByPaths(data, waypointTables)

    if not rawWaypoints then
        return {}
    end

    local waypoints = {}

    for index, rawWaypoint in ipairs(rawWaypoints) do
        local waypoint = self:NormalizeCombatFliteJsonWaypoint(rawWaypoint, index)

        if waypoint then
            waypoints[#waypoints + 1] = waypoint
        end
    end

    return waypoints
end

function NASG_ATC:BuildFlightPlanFromCombatFliteJson(path, data)
    local waypoints = self:ExtractCombatFliteJsonWaypoints(data)

    if #waypoints == 0 then
        self:Log("CombatFlite JSON has no usable waypoints: " .. tostring(path))
        return nil
    end

    local stem = self:GetFileStem(path)

    local callsign = self:GetDTCValue(data, {
        "callsign",
        "Callsign",
        "callSign",
        "flight.callsign",
        "flight.Callsign",
        "flights.1.callsign",
        "Flights.1.Callsign",
        "package.callsign",
        "package.Callsign",
        "packages.1.callsign",
        "Packages.1.Callsign",
        "packages.1.flights.1.callsign",
        "Packages.1.Flights.1.Callsign",
        "aircraft.callsign",
        "aircraft.Callsign",
        "mission.callsign",
        "mission.Callsign",
    }) or stem

    local aircraftType = self:GetDTCValue(data, {
        "aircraft.type",
        "aircraft.Type",
        "aircraftType",
        "AircraftType",
        "flights.1.aircraft",
        "Flights.1.Aircraft",
        "packages.1.flights.1.aircraft",
        "Packages.1.Flights.1.Aircraft",
    })

    local sequenceRefs = {}

    for _, waypoint in ipairs(waypoints) do
        sequenceRefs[#sequenceRefs + 1] = waypoint.waypoint
    end

    return {
        id = "combatflite_" .. self:NormalizeFlightPlanLookup(stem),
        source = "combatflite_json",
        source_file = path,
        callsign = tostring(callsign),
        aircraft_type = aircraftType,
        aliases = {
            stem,
            callsign,
        },
        waypoints = waypoints,
        sequences = {
            {
                name = "CombatFlite",
                waypoints = sequenceRefs,
                max_lateral_error_nm = 5,
            },
        },
    }
end


function NASG_ATC:ListDTCFiles(folder)
    local files = {}

    if not folder or folder == "" then
        return files
    end

    if not lfs or not lfs.dir or not lfs.attributes then
        self:Log("Cannot scan flight plan folder because lfs.dir or lfs.attributes is unavailable")
        return files
    end

    local function getAttributes(path)
        local ok, attributes = pcall(function()
            return lfs.attributes(path)
        end)

        if ok then
            return attributes
        end

        return nil
    end

    local function scanFolder(currentFolder)
        local folderAttributes = getAttributes(currentFolder)

        if not folderAttributes then
            self:Log("Flight plan folder does not exist or is not accessible: " .. tostring(currentFolder))
            return
        end

        if folderAttributes.mode ~= "directory" then
            self:Log("Flight plan path is not a directory: " .. tostring(currentFolder))
            return
        end

        local ok, iterator, directoryObject = pcall(function()
            return lfs.dir(currentFolder)
        end)

        if not ok or not iterator then
            self:Log("Unable to open flight plan folder: " .. tostring(currentFolder))
            return
        end

        while true do
            local nextOk, filename = pcall(function()
                return iterator(directoryObject)
            end)

            if not nextOk then
                self:Log("Unable to continue scanning flight plan folder: " .. tostring(currentFolder))
                return
            end

            if not filename then
                break
            end

            if filename ~= "." and filename ~= ".." then
                local path = self:JoinPath(currentFolder, filename)
                local attributes = getAttributes(path)
                local mode = attributes and attributes.mode
                local lower = string.lower(filename)

                if mode == "directory" then
                    scanFolder(path)
                elseif mode == "file" and (lower:match("%.dtc$") or lower:match("%.json$")) then
                    files[#files + 1] = path
                end
            end
        end
    end

    scanFolder(folder)

    table.sort(files)
    return files
end

-- Non-recursive: just the immediate child directories of `folder`, used to
-- enumerate mission-number folders under a day folder (see
-- LoadMissionFlightPlans below) without descending into them.
function NASG_ATC:ListImmediateSubfolders(folder)
    local subfolders = {}

    if not folder or folder == "" or not lfs or not lfs.dir or not lfs.attributes then
        return subfolders
    end

    local ok, iterator, directoryObject = pcall(function()
        return lfs.dir(folder)
    end)

    if not ok or not iterator then
        self:Log("Unable to open folder for mission scan: " .. tostring(folder))
        return subfolders
    end

    while true do
        local nextOk, filename = pcall(function()
            return iterator(directoryObject)
        end)

        if not nextOk or not filename then
            break
        end

        if filename ~= "." and filename ~= ".." then
            local path = self:JoinPath(folder, filename)
            local attributesOk, attributes = pcall(function() return lfs.attributes(path) end)

            if attributesOk and attributes and attributes.mode == "directory" then
                subfolders[#subfolders + 1] = { name = filename, path = path }
            end
        end
    end

    table.sort(subfolders, function(a, b) return a.name < b.name end)
    return subfolders
end

function NASG_ATC:ApplyFlightPlanFolderCallsign(flightPlan, path)
    if not flightPlan then
        return
    end

    local folderCallsign = self:GetFlightPlanCallsignFolder(path)

    if not folderCallsign or folderCallsign == "" then
        return
    end

    flightPlan.folder_callsign = folderCallsign
    flightPlan.package_callsign = flightPlan.package_callsign or folderCallsign
    flightPlan.callsign = flightPlan.callsign or folderCallsign

    self:AddFlightPlanAliases(flightPlan, {
        folderCallsign,
        self:GetFileStem(path),
    })
end

function NASG_ATC:BuildFlightPlanAliasMap(flightPlans)
    local byStem = {}

    for _, flightPlan in ipairs(flightPlans or {}) do
        local folderCallsign = flightPlan.folder_callsign
        local stem, number = self:GetCallsignStemAndNumber(folderCallsign)

        if stem and number then
            byStem[stem] = byStem[stem] or {}
            byStem[stem][number] = flightPlan
        end
    end

    for stem, plansByNumber in pairs(byStem) do
        local numbers = {}

        for number, _ in pairs(plansByNumber) do
            numbers[#numbers + 1] = number
        end

        table.sort(numbers)

        for index, number in ipairs(numbers) do
            local flightPlan = plansByNumber[number]
            local nextNumber = numbers[index + 1]
            local aliasStart = number
            local aliasEnd = nil

            if nextNumber then
                aliasEnd = nextNumber - 1
            else
                local flightBase = math.floor(number / 10) * 10
                aliasEnd = flightBase + 4
            end

            local aliases = {}

            for aliasNumber = aliasStart, aliasEnd do
                aliases[#aliases + 1] = stem .. tostring(aliasNumber)
            end

            self:AddFlightPlanAliases(flightPlan, aliases)
        end
    end
end

-- Shared kind-detection/build dispatch used by both the per-callsign
-- day-folder loader (LoadDTCFlightPlans) and the mission-number loader
-- (LoadMissionFlightPlans), so a new DTC/JSON shape only needs to be taught
-- to GetFlightPlanJsonKind + one Build* function to work in both places.
-- Always returns a list (kind "nasg_atc" files can contain several plans).
function NASG_ATC:BuildFlightPlansFromFile(path, data)
    local kind = self:GetFlightPlanJsonKind(data)

    if kind == "nasg_atc" then
        return data.flight_plans or data.FlightPlans or {}, kind
    end

    local flightPlan = nil

    if kind == "combatflite" then
        flightPlan = self:BuildFlightPlanFromCombatFliteJson(path, data)
    elseif kind == "dtc_hornet" then
        flightPlan = self:BuildFlightPlanFromHornetDTC(path, data)
    elseif kind == "dtc_navpages" then
        flightPlan = self:BuildFlightPlanFromNavPagesDTC(path, data)
    elseif kind == "dtc" then
        flightPlan = self:BuildFlightPlanFromDTC(path, data)
    else
        flightPlan = self:BuildFlightPlanFromHornetDTC(path, data)

        if not flightPlan then
            flightPlan = self:BuildFlightPlanFromNavPagesDTC(path, data)
        end

        if not flightPlan then
            flightPlan = self:BuildFlightPlanFromDTC(path, data)
        end

        if not flightPlan then
            flightPlan = self:BuildFlightPlanFromCombatFliteJson(path, data)
        end
    end

    if flightPlan then
        return { flightPlan }, kind
    end

    return {}, kind
end

function NASG_ATC:LoadDTCFlightPlans()
    if not self.DTCFlightPlanEnabled then
        self:Log("DTC/current-day flight plan loading disabled")
        return {}
    end

    local folder = self:GetCurrentFlightPlanDayFolder()

    self:Log("Current-day flight plan folder: " .. tostring(folder))

    if not folder or folder == "" then
        self:Log("Current-day flight plan folder is not configured")
        return {}
    end

    local flightPlans = {}
    local files = self:ListDTCFiles(folder)

    self:Log("Current-day flight plan files found: " .. tostring(#files))

    for _, path in ipairs(files) do
        self:Log("Loading flight plan file: " .. tostring(path))

        local data = self:DecodeJsonFile(path)

        if data then
            local plans, kind = self:BuildFlightPlansFromFile(path, data)

            self:Log("Flight plan JSON kind: " .. tostring(kind) .. " file=" .. tostring(path))

            if #plans == 0 then
                self:Log("No usable flight plan built from file: " .. tostring(path))
            end

            for _, plan in ipairs(plans) do
                self:ApplyFlightPlanFolderCallsign(plan, path)
                flightPlans[#flightPlans + 1] = plan
                self:Log("Loaded flight plan id=" .. tostring(plan.id) .. " callsign=" .. tostring(plan.callsign))
            end
        else
            self:Log("Unable to decode JSON/DTC flight plan file: " .. tostring(path))
        end
    end

    self:BuildFlightPlanAliasMap(flightPlans)

    self:Log("Loaded current-day flight plans from: " .. tostring(folder) .. " count=" .. tostring(#flightPlans))
    return flightPlans
end

-- Mission check-in folders live one level below the day folder used by
-- LoadDTCFlightPlans -- Root/<today>/<mission number>/<platform-specific
-- plan> -- so a pilot's personal callsign folder (Root/<today>/<callsign>)
-- and mission folders can coexist side by side under the same day folder.
-- Every immediate subfolder of the day folder is treated as a mission
-- number; its files are also picked up (harmlessly) by LoadDTCFlightPlans's
-- recursive callsign-folder scan above, they're just additionally indexed
-- here by mission number + aircraft type for CheckInToMission/
-- GetMissionFlightPlan to use.
function NASG_ATC:LoadMissionFlightPlans()
    self.MissionFlightPlansByNumber = {}

    if not self.DTCFlightPlanEnabled then
        return {}
    end

    local dayFolder = self:GetCurrentFlightPlanDayFolder()

    if not dayFolder or dayFolder == "" then
        return {}
    end

    local missionFolders = self:ListImmediateSubfolders(dayFolder)
    local flightPlans = {}

    for _, missionFolder in ipairs(missionFolders) do
        local missionKey = self:NormalizeFlightPlanLookup(missionFolder.name)

        if missionKey ~= "" then
            local files = self:ListDTCFiles(missionFolder.path)

            for _, path in ipairs(files) do
                local data = self:DecodeJsonFile(path)

                if data then
                    local plans = self:BuildFlightPlansFromFile(path, data)

                    for _, plan in ipairs(plans) do
                        self:ApplyFlightPlanFolderCallsign(plan, path)
                        plan.mission_number = missionFolder.name

                        local typeKey = self:NormalizeFlightPlanLookup(plan.aircraft_type)

                        if typeKey ~= "" then
                            self.MissionFlightPlansByNumber[missionKey] = self.MissionFlightPlansByNumber[missionKey] or {}
                            self.MissionFlightPlansByNumber[missionKey][typeKey] = plan
                        else
                            self:Log("Mission flight plan has no aircraft_type, cannot be platform-matched: " .. tostring(path))
                        end

                        flightPlans[#flightPlans + 1] = plan
                    end
                else
                    self:Log("Unable to decode mission flight plan file: " .. tostring(path))
                end
            end
        end
    end

    self:BuildFlightPlanAliasMap(flightPlans)

    self:Log(
            "Loaded mission flight plans from: " .. tostring(dayFolder)
                    .. " missions=" .. tostring(#missionFolders)
                    .. " plans=" .. tostring(#flightPlans)
    )

    return flightPlans
end

-- Matches an actual DCS aircraft type (e.g. "FA-18C_hornet") against the
-- aircraft_type keys a mission folder actually has plans for. Tries an
-- exact normalized match first, then falls back to substring-contains
-- either direction (same spirit as FuzzyMatchLookupKey) so a DTC's own
-- `type` field of just "hornet" still matches the real "FA-18C_hornet".
function NASG_ATC:MatchAircraftTypeKey(aircraftType, availableTypeKeys)
    local query = self:NormalizeFlightPlanLookup(aircraftType)

    if query == "" or not availableTypeKeys then
        return nil
    end

    if availableTypeKeys[query] then
        return query
    end

    for key, _ in pairs(availableTypeKeys) do
        if key ~= "" and (query:find(key, 1, true) or key:find(query, 1, true)) then
            return key
        end
    end

    return nil
end

function NASG_ATC:GetMissionFlightPlan(missionNumber, aircraftType)
    local missionKey = self:NormalizeFlightPlanLookup(missionNumber)
    local plansByType = self.MissionFlightPlansByNumber[missionKey]

    if not plansByType then
        return nil
    end

    local typeKey = self:MatchAircraftTypeKey(aircraftType, plansByType)

    return typeKey and plansByType[typeKey] or nil
end

-- Shared by the Clearance Delivery voice intent and the F10 "Select
-- Mission" menu. Attaches immediately if the client's aircraft type can be
-- resolved and matches a plan on file; otherwise the check-in still
-- "sticks" on the session and GetOrAttachFlightPlan will retry later.
-- Returns ok, normalized mission number, matched flight plan (or nil),
-- and a failure reason ("no_session"/"no_mission_number"/"unknown_mission").
function NASG_ATC:CheckInToMission(session, client, missionNumberRaw)
    if not session then
        return false, nil, nil, "no_session"
    end

    local missionKey = self:NormalizeFlightPlanLookup(missionNumberRaw)

    if missionKey == "" then
        return false, nil, nil, "no_mission_number"
    end

    if not self.MissionFlightPlansByNumber[missionKey] then
        return false, missionKey, nil, "unknown_mission"
    end

    session.MissionNumber = missionKey
    session.FlightPlanId = nil
    session.ActiveSequenceName = nil
    session.ActiveLegIndex = nil
    session.UpdatedAt = timer.getTime()

    local aircraftType = client and self:GetMooseUnitTypeNameSafe(client)
    local matchedFlightPlan = aircraftType and self:GetMissionFlightPlan(missionKey, aircraftType) or nil

    if matchedFlightPlan then
        self:AttachFlightPlanToSession(session, matchedFlightPlan)
    end

    return true, missionKey, matchedFlightPlan, nil
end


function NASG_ATC:IndexFlightPlans()
    self.FlightPlansById = {}
    self.FlightPlansByLookup = {}

    for _, flightPlan in ipairs(self.FlightPlans or {}) do
        local id = tostring(flightPlan.id or flightPlan.Id or "")
        local callsign = tostring(flightPlan.callsign or flightPlan.Callsign or "")

        if id ~= "" then
            self.FlightPlansById[id] = flightPlan
        end

        if callsign ~= "" then
            self:RegisterFlightPlanLookup(callsign, flightPlan)
        end

        for _, alias in ipairs(flightPlan.aliases or flightPlan.Aliases or {}) do
            self:RegisterFlightPlanLookup(alias, flightPlan)
        end

        if flightPlan.pilot_name then
            self:RegisterFlightPlanLookup(flightPlan.pilot_name, flightPlan)
        end

        if flightPlan.player_name then
            self:RegisterFlightPlanLookup(flightPlan.player_name, flightPlan)
        end

        if flightPlan.folder_callsign then
            self:RegisterFlightPlanLookup(flightPlan.folder_callsign, flightPlan)
        end

        if flightPlan.source_file then
            self:RegisterFlightPlanLookup(self:GetFileStem(flightPlan.source_file), flightPlan)
        end
    end

    self:Log("Indexed ATC flight plans: " .. tostring(#(self.FlightPlans or {})))
end

function NASG_ATC:LoadFlightPlans()
    local path = self.FlightPlanFile
    local loadedFlightPlans = {}

    if path and path ~= "" then
        self:Log("Loading ATC flight plan file: " .. tostring(path))

        local data = self:DecodeJsonFile(path)

        if data then
            if data.flight_plans or data.FlightPlans then
                loadedFlightPlans = data.flight_plans or data.FlightPlans or {}
            elseif data[1] then
                loadedFlightPlans = data
            else
                self:Log("ATC flight plan file decoded but no flight_plans array found: " .. tostring(path))
            end

            self:Log("Loaded ATC flight plans from file count=" .. tostring(#loadedFlightPlans))
        else
            self:Log("No usable ATC flight plan JSON found: " .. tostring(path))
        end
    else
        self:Log("Flight plan file not configured")
    end

    local dtcFlightPlans = self:LoadDTCFlightPlans()

    for _, flightPlan in ipairs(dtcFlightPlans or {}) do
        loadedFlightPlans[#loadedFlightPlans + 1] = flightPlan
    end

    local missionFlightPlans = self:LoadMissionFlightPlans()

    for _, flightPlan in ipairs(missionFlightPlans or {}) do
        loadedFlightPlans[#loadedFlightPlans + 1] = flightPlan
    end

    self.FlightPlans = loadedFlightPlans
    self:IndexFlightPlans()

    return #(self.FlightPlans or {}) > 0
end
function NASG_ATC:GetFlightPlanForCallsign(callsign)
    local key = self:NormalizeFlightPlanLookup(callsign)
    return self.FlightPlansByLookup[key]
end

function NASG_ATC:GetFlightPlanForClient(client, event)
    -- ResolveEffectiveCallsign (NASG_ATC_Core.lua) implements this same
    -- callsign-alias -> event.callsign -> player name -> unit name chain,
    -- plus a pilot-set callsign alias ahead of all of it.
    local callsign = self:ResolveEffectiveCallsign(client, event)

    if callsign then
        local fp = self:GetFlightPlanForCallsign(callsign)

        if fp then
            return fp
        end
    end

    if event then
        local fp = self:GetFlightPlanForCallsign(event.srs_client_name)

        if fp then
            return fp
        end
    end

    return nil
end

function NASG_ATC:AttachFlightPlanToSession(session, flightPlan)
    if not session or not flightPlan then
        return
    end

    session.FlightPlanId = flightPlan.id or flightPlan.Id
    session.ActiveSequenceName = session.ActiveSequenceName or self:GetDefaultFlightPlanSequenceName(flightPlan)
    session.ActiveLegIndex = session.ActiveLegIndex or 1
end

function NASG_ATC:GetOrAttachFlightPlan(client, session, event)
    local flightPlan = self:GetSessionFlightPlan(session)

    if flightPlan then
        return flightPlan
    end

    -- A pilot who's checked into a mission (CheckInToMission) gets that
    -- mission's platform-matched plan ahead of the legacy callsign-folder
    -- match -- e.g. if aircraft type couldn't be resolved yet at check-in
    -- time but can be now.
    if session and session.MissionNumber then
        local aircraftType = self:GetMooseUnitTypeNameSafe(client)
        flightPlan = aircraftType and self:GetMissionFlightPlan(session.MissionNumber, aircraftType)

        if flightPlan then
            self:AttachFlightPlanToSession(session, flightPlan)
            return flightPlan
        end
    end

    flightPlan = self:GetFlightPlanForClient(client, event)

    if flightPlan then
        self:AttachFlightPlanToSession(session, flightPlan)
    end

    return flightPlan
end

function NASG_ATC:GetDefaultFlightPlanSequenceName(flightPlan)
    if not flightPlan then
        return nil
    end

    local sequences = flightPlan.sequences or flightPlan.Sequences or {}

    if sequences[1] then
        return sequences[1].name or sequences[1].Name
    end

    return nil
end

function NASG_ATC:GetFlightPlanById(id)
    return self.FlightPlansById[tostring(id or "")]
end

function NASG_ATC:GetSessionFlightPlan(session)
    if not session or not session.FlightPlanId then
        return nil
    end

    return self:GetFlightPlanById(session.FlightPlanId)
end

function NASG_ATC:GetFlightPlanWaypoints(flightPlan)
    return flightPlan and (flightPlan.waypoints or flightPlan.Waypoints) or {}
end

function NASG_ATC:GetFlightPlanSequences(flightPlan)
    return flightPlan and (flightPlan.sequences or flightPlan.Sequences) or {}
end

function NASG_ATC:GetWaypointNumber(waypoint)
    return tonumber(waypoint and (waypoint.waypoint or waypoint.Waypoint or waypoint.number or waypoint.Number))
end

function NASG_ATC:GetWaypointName(waypoint)
    return tostring(waypoint and (waypoint.name or waypoint.Name or "") or "")
end

function NASG_ATC:GetWaypointRole(waypoint)
    return tostring(waypoint and (waypoint.role or waypoint.Role or "") or ""):lower()
end

function NASG_ATC:GetWaypointAltitudeFeet(waypoint)
    if not waypoint then
        return nil
    end

    return tonumber(
            waypoint.altitude_ft
                    or waypoint.AltitudeFt
                    or waypoint.alt
                    or waypoint.Alt
                    or waypoint.altitude
                    or waypoint.Altitude
                    or waypoint.elevation
                    or waypoint.Elevation
    )
end

function NASG_ATC:FindWaypointByNumber(flightPlan, waypointNumber)
    local number = tonumber(waypointNumber)

    if not number then
        return nil
    end

    for _, waypoint in ipairs(self:GetFlightPlanWaypoints(flightPlan)) do
        if self:GetWaypointNumber(waypoint) == number then
            return waypoint
        end
    end

    return nil
end

function NASG_ATC:FindWaypointByName(flightPlan, name)
    local lookup = self:NormalizeFlightPlanLookup(name)

    if lookup == "" then
        return nil
    end

    local waypoints = self:GetFlightPlanWaypoints(flightPlan)
    local keyToWaypoint = {}
    local keys = {}

    for _, waypoint in ipairs(waypoints) do
        local normalizedName = self:NormalizeFlightPlanLookup(self:GetWaypointName(waypoint))

        if normalizedName == lookup then
            return waypoint
        end

        if normalizedName ~= "" then
            keys[#keys + 1] = normalizedName
            keyToWaypoint[normalizedName] = waypoint
        end
    end

    local fuzzyKey = self:FuzzyMatchLookupKey(lookup, keys)

    if fuzzyKey then
        self:Log(string.format("Fuzzy-matched flight-plan waypoint request '%s' to '%s'", lookup, fuzzyKey))
        return keyToWaypoint[fuzzyKey]
    end

    return nil
end

function NASG_ATC:FindWaypointByRole(flightPlan, role)
    local lookup = tostring(role or ""):lower()

    if lookup == "" then
        return nil
    end

    for _, waypoint in ipairs(self:GetFlightPlanWaypoints(flightPlan)) do
        if self:GetWaypointRole(waypoint) == lookup then
            return waypoint
        end
    end

    return nil
end

function NASG_ATC:FindFlightPlanWaypoint(flightPlan, value)
    if not flightPlan or not value then
        return nil
    end

    local text = tostring(value)
    local number = tonumber(text)

    if number then
        local waypoint = self:FindWaypointByNumber(flightPlan, number)

        if waypoint then
            return waypoint
        end
    end

    local byName = self:FindWaypointByName(flightPlan, text)

    if byName then
        return byName
    end

    local byRole = self:FindWaypointByRole(flightPlan, text)

    if byRole then
        return byRole
    end

    return nil
end

function NASG_ATC:FindSequenceByName(flightPlan, sequenceName)
    local lookup = self:NormalizeFlightPlanLookup(sequenceName)

    if lookup == "" then
        return nil
    end

    for _, sequence in ipairs(self:GetFlightPlanSequences(flightPlan)) do
        if self:NormalizeFlightPlanLookup(sequence.name or sequence.Name) == lookup then
            return sequence
        end
    end

    return nil
end

function NASG_ATC:GetActiveSequence(flightPlan, session)
    if not flightPlan or not session then
        return nil
    end

    if session.ActiveSequenceName then
        local sequence = self:FindSequenceByName(flightPlan, session.ActiveSequenceName)

        if sequence then
            return sequence
        end
    end

    local sequences = self:GetFlightPlanSequences(flightPlan)
    return sequences[1]
end

function NASG_ATC:GetWaypointBySequenceEntry(flightPlan, entry)
    if type(entry) == "number" then
        return self:FindWaypointByNumber(flightPlan, entry)
    end

    return self:FindFlightPlanWaypoint(flightPlan, entry)
end

function NASG_ATC:GetActiveLeg(flightPlan, session)
    local sequence = self:GetActiveSequence(flightPlan, session)

    if not sequence then
        return nil
    end

    local waypointRefs = sequence.waypoints or sequence.Waypoints or {}

    if #waypointRefs < 2 then
        return nil
    end

    local legIndex = tonumber(session.ActiveLegIndex or 1) or 1

    if legIndex < 1 then
        legIndex = 1
    end

    if legIndex >= #waypointRefs then
        legIndex = #waypointRefs - 1
    end

    local startWaypoint = self:GetWaypointBySequenceEntry(flightPlan, waypointRefs[legIndex])
    local endWaypoint = self:GetWaypointBySequenceEntry(flightPlan, waypointRefs[legIndex + 1])

    if not startWaypoint or not endWaypoint then
        return nil
    end

    return {
        Sequence = sequence,
        SequenceName = sequence.name or sequence.Name,
        LegIndex = legIndex,
        StartWaypoint = startWaypoint,
        EndWaypoint = endWaypoint,
        MaxLateralErrorNM = tonumber(sequence.max_lateral_error_nm or sequence.MaxLateralErrorNM or 5) or 5,
    }
end

function NASG_ATC:GetWaypointDisplayName(waypoint)
    if not waypoint then
        return "waypoint"
    end

    local name = self:GetWaypointName(waypoint)

    if name ~= "" then
        return name
    end

    local number = self:GetWaypointNumber(waypoint)

    -- Real DTC exports frequently leave the very first steerpoint unnamed
    -- (it's usually just the takeoff/ramp point). Falling back to "waypoint
    -- 1" reads as if that number meant something to the pilot; it doesn't,
    -- so say the standard "continue as fragged" instead of the id.
    if number == 1 then
        return "continue as fragged"
    end

    if number then
        return "waypoint " .. tostring(number)
    end

    return "waypoint"
end

function NASG_ATC:GetPrimaryDivert(flightPlan)
    local diverts = flightPlan and (flightPlan.diverts or flightPlan.Diverts) or {}

    return diverts[1]
end

function NASG_ATC:GetFlightPlanArrivalAirportId(flightPlan)
    if not flightPlan then
        return nil
    end

    local arrival = flightPlan.arrival or flightPlan.Arrival

    if not arrival then
        return nil
    end

    return arrival.airport_id or arrival.AirportId
end

NASG_ATC:Log("NASG_ATC_FlightPlans loaded")
NASG_ATC:LoadFlightPlans()