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


function NASG_ATC:GetFlightPlanJsonKind(data)
    if type(data) ~= "table" then
        return "unknown"
    end

    if data.flight_plans or data.FlightPlans then
        return "nasg_atc"
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
            local kind = self:GetFlightPlanJsonKind(data)

            self:Log("Flight plan JSON kind: " .. tostring(kind) .. " file=" .. tostring(path))

            local flightPlan = nil

            if kind == "combatflite" then
                flightPlan = self:BuildFlightPlanFromCombatFliteJson(path, data)
            elseif kind == "dtc" then
                flightPlan = self:BuildFlightPlanFromDTC(path, data)
            elseif kind == "nasg_atc" then
                for _, plan in ipairs(data.flight_plans or data.FlightPlans or {}) do
                    self:ApplyFlightPlanFolderCallsign(plan, path)
                    flightPlans[#flightPlans + 1] = plan
                end
            else
                flightPlan = self:BuildFlightPlanFromDTC(path, data)

                if not flightPlan then
                    flightPlan = self:BuildFlightPlanFromCombatFliteJson(path, data)
                end
            end

            if flightPlan then
                self:ApplyFlightPlanFolderCallsign(flightPlan, path)
                flightPlans[#flightPlans + 1] = flightPlan
                self:Log("Loaded flight plan id=" .. tostring(flightPlan.id) .. " callsign=" .. tostring(flightPlan.callsign))
            else
                self:Log("No usable flight plan built from file: " .. tostring(path))
            end
        else
            self:Log("Unable to decode JSON/DTC flight plan file: " .. tostring(path))
        end
    end

    self:BuildFlightPlanAliasMap(flightPlans)

    self:Log("Loaded current-day flight plans from: " .. tostring(folder) .. " count=" .. tostring(#flightPlans))
    return flightPlans
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

    self.FlightPlans = loadedFlightPlans
    self:IndexFlightPlans()

    return #(self.FlightPlans or {}) > 0
end
function NASG_ATC:GetFlightPlanForCallsign(callsign)
    local key = self:NormalizeFlightPlanLookup(callsign)
    return self.FlightPlansByLookup[key]
end

function NASG_ATC:GetFlightPlanForClient(client, event)
    if event then
        local fp = self:GetFlightPlanForCallsign(event.callsign or event.client_name or event.srs_client_name)

        if fp then
            return fp
        end
    end

    if client then
        local playerName = self:GetClientPlayerNameSafe(client)
        local fp = self:GetFlightPlanForCallsign(playerName)

        if fp then
            return fp
        end

        local clientName = self:GetClientNameSafe(client)
        fp = self:GetFlightPlanForCallsign(clientName)

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

    for _, waypoint in ipairs(self:GetFlightPlanWaypoints(flightPlan)) do
        local waypointName = self:GetWaypointName(waypoint)

        if self:NormalizeFlightPlanLookup(waypointName) == lookup then
            return waypoint
        end
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