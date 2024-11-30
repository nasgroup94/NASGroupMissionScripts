-- -- Debuging
--[[
	BASE:TraceOnOff(true)
	BASE:TraceLevel(1)
	BASE:TraceClass('MARKEROPS_TANKER')
    BASE:TraceClass('MARKEROPS_BASE')
    BASE:TraceClass('MARKEROPS')
    BASE:TraceClass('AUFTRAG')
    BASE:TraceClass('BASE')
	--]]

local io = require('io')

BASE:T("markerops_tanker | Loading...")

-- Hacked AUFTRAG:NewTANKER -- doesn't actually work

--- **[AIR]** Create a TANKER mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number RefuelSystem Refueling system (0=boom, 1=probe). This info is *only* for AIRWINGs so they launch the right tanker type.
-- @return #AUFTRAG self
function AUFTRAG:NewTANKER_MOD(Coordinate, Altitude, Speed, Heading, Leg, RefuelSystem)

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)

  -- Mission type TANKER.
  mission.type=AUFTRAG.Type.ORBIT

  mission:_SetLogID()

  mission.refuelSystem=RefuelSystem

  -- Mission options:
--   mission.missionTask=ENUMS.MissionTask.REFUELING
    mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

local function minsToSeconds(Minutes)
    if type(Minutes) == 'number' then
        return Minutes * 60
    else
        return 0
    end
end

--#region Tanker marker ops
local tankerFreqs = {
    {
        val = 230,
        state = false,
    },
    {
        val = 231,
        state = false,
    },
    {
        val = 232,
        state = false,
    },
    {
        val = 233,
        state = false,
    },
    {
        val = 234,
        state = false,
    },
    {
        val = 235,
        state = false,
    },
    {
        val = 236,
        state = false,
    },
    {
        val = 237,
        state = false,
    },
    {
        val = 238,
        state = false,
    },
    {
        val = 239,
        state = false,
    },
    {
        val = 240,
        state = false,
    },
    {
        val = 241,
        state = false,
    },
    {
        val = 242,
        state = false,
    },
    {
        val = 243,
        state = false,
    },
    {
        val = 244,
        state = false,
    },
    {
        val = 245,
        state = false,
    },
    {
        val = 246,
        state = false,
    },
    {
        val = 247,
        state = false,
    },
    {
        val = 248,
        state = false,
    },
    {
        val = 249,
        state = false,
    },
}

local tankerTACANS = {
    {
        val = 30,
        state = false,
    },
    {
        val = 31,
        state = false,
    },
    {
        val = 32,
        state = false,
    },
    {
        val = 34,
        state = false,
    },
    {
        val = 35,
        state = false,
    },
    {
        val = 36,
        state = false,
    },
    {
        val = 37,
        state = false,
    },
    {
        val = 38,
        state = false,
    },
    {
        val = 39,
        state = false,
    },
    {
        val = 40,
        state = false,
    },
    {
        val = 41,
        state = false,
    },
    {
        val = 42,
        state = false,
    },
    {
        val = 43,
        state = false,
    },
    {
        val = 44,
        state = false,
    },
    {
        val = 45,
        state = false,
    },
    {
        val = 46,
        state = false,
    },
    {
        val = 47,
        state = false,
    },
    {
        val = 48,
        state = false,
    },
    {
        val = 49,
        state = false,
    },
}

local tankerCallsigns = {
    {
        val = 3,
        state = false,
    },
    {
        val = 4,
        state = false,
    },
    {
        val = 5,
        state = false,
    },
    {
        val = 6,
        state = false,
    },
    {
        val = 7,
        state = false,
    },
    {
        val = 8,
        state = false,
    },
    {
        val = 9,
        state = false,
    },
}

local function getRandomFreeValueFromPool(Tbl)
    if type(Tbl) == 'table' then
        while true do
            local element = UTILS.GetRandomTableElement(Tbl, true)
            if element then
                if element.state == false then
                    element.state = true
                    return element.val
                end
            end
        end
    end
end

local function returnValueToPool(Tbl, Value)
    if type(Tbl) == 'table' then
        for idx, item in pairs(Tbl) do
            if item.val == Value then
                Tbl[idx].state = false
                break
            end
        end
    end
end

local defaultParamsTanker = {
    alt = {
        value = MISSION_TANKER_ALTS.Offgoing or 18000,
        min = 2000,
        max = 30000,
    },
    spd = {
        value = 260,
        min = 240,
        max = 280
    },
    hdg = {
        value = 90,
        min = 0,
        max = 360
    },
    leg = {
        value = 20,
        min = 15,
        max = 30
    },
    req = {
        value = 1,
        min = 1,
        max = 4
    },
    start = {
        value = 1, -- 1 minute (value in minutes)
        min = 1, -- 1 minute
        max = 240 -- 4 hours
    },
    dur = {
        value = minsToSeconds(60), -- 1 hour (value in minutes)
        min = 30, -- 0.5 hours
        max = nil, -- till it runs out of fuel, so actually this param never used.
    },
    probe = 1,
    boom = 0,
    cap = false,
    carrier = {CVN73_ARCO3},
    airbase = {SQDN_ARS909MPRS, SQDN_ARS909},
    done = false,
}

local function validateTankerMarker(Tag, Text)
    BASE:T("validateTankerMarker")
    local tempParams = UTILS.DeepCopy(defaultParamsTanker)

    BASE:T(string.format("\nTag:%s\nText:%s\nKeywords:%s", Tag, Text, ROLLN.print_table(tempParams)))

    if Text:find(Tag, nil, true) then

        --For each of our keywords, search for the patterns
        for keyword, _ in pairs(tempParams) do
            BASE:T("validateTankerMarker - keyword:"..tostring(keyword))

            --Search for value:value patterns (e.g. spd:260 alt:240 ident:40 from:carrier)
            for data in string.gmatch(Text, '%a+:%w+') do
                BASE:T("validateTankerMarker - \tdata:"..tostring(data))
                local key, val = data:lower():match('(%a+):(%w+)')
                BASE:T('validateTankerMarker - \t\tkey:'..tostring(key)..'\tval:'..tostring(val))

                if keyword:lower() == key:lower() then
                    -- Check if val can be converted to a number or not.
                    -- If val is a number, validate val.
                    -- If val in NOT a number, check against
                    -- keywords that may need string values.
                    -- If that fails, break out.
                    
                    if tonumber(val) ~= nil then
                        BASE:I("validateTankerMarker - Looking for number values.")
                        val = tonumber(val)
                        if key == 'alt' then
                            if val < tempParams.alt.min then
                                tempParams.alt.value = tempParams.alt.min
                            elseif val > tempParams.alt.max then
                                tempParams.alt.value = tempParams.alt.max
                            else
                                tempParams.alt.value = val
                            end
                        elseif key == 'spd' then
                            if val < tempParams.spd.min then
                                tempParams.spd.value = tempParams.spd.min
                            elseif val > tempParams.spd.max then
                                tempParams.spd.value = tempParams.spd.max
                            else
                                tempParams.spd.value = val
                            end
                        elseif key == 'hdg' then
                            if val < tempParams.hdg.min then
                                tempParams.hdg.value = tempParams.hdg.min
                            elseif val > tempParams.hdg.max then
                                tempParams.hdg.value = tempParams.hdg.max
                            else
                                tempParams.hdg.value = val
                            end
                        elseif key == 'leg' then
                            if val < tempParams.leg.min then
                                tempParams.leg.value = tempParams.leg.min
                            elseif val > tempParams.leg.max then
                                tempParams.leg.value = tempParams.leg.max
                            else
                                tempParams.leg.value = val
                            end
                        elseif key == 'req' then
                            BASE:T()
                            if val < tempParams.req.min then
                                tempParams.req.value = tempParams.req.min
                            elseif val > tempParams.req.max then
                                tempParams.req.value = tempParams.req.max
                            else
                                tempParams.req.value = val
                            end
                        elseif key == 'start' then
                            -- convert the minute val from the marker into seconds for the auftrag
                            if val < tempParams.start.min then
                                tempParams.start.value = minsToSeconds(tempParams.start.min)
                            elseif val > tempParams.start.max then
                                tempParams.start.value = minsToSeconds(tempParams.start.max)
                            else
                                tempParams.start.value = minsToSeconds(val)
                            end
                        elseif key == 'dur' then
                            -- convert the minute val from the marker into seconds for the auftrag
                            if val < tempParams.dur.min then
                                tempParams.dur.value = minsToSeconds(tempParams.dur.min)
                            else
                                tempParams.dur.value = minsToSeconds(val)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    return UTILS.DeepCopy(tempParams)
end

local markersMasterList = {}
local markerId = 0

local function createMarkerId()
    markerId = markerId + 1
    return markerId
end


--#region MarkerOps Tanker Cancel

TankerCancelMarkerOps = MARKEROPS_BASE:New("-cancel tanker\n", {"id"})

function TankerCancelMarkerOps:OnAfterMarkChanged(From, Event, To, Text, Keywords, Coord)
    self:T(self.lid..'TankerCancelMarkerOps:OnAfterMarkChanged')

    for _, word in pairs(Keywords) do
        if word == "id" then
            local key, val = Text:lower():match('(%a+):(%d+)')
            if key then
                if val then
                    self:T(self.lid.."Key: "..key.." val: "..val)
                    for _, marker in pairs(markersMasterList) do
                        self:T(self.lid.."Marker ID: "..marker._Id)
                        if marker._Id == tonumber(val) then
                            self:T(self.lid.."We found the marker")
                            for _, auftrag in pairs(marker._Auftrags) do
                                self:T(self.lid.."Cancelling auftrag: "..auftrag:GetName())
                                auftrag:Cancel()
                            end
                            break
                        end
                    end
                else
                    self:E(self.lid.."Could not find a numerical val in id:val pair.")
                end
            else
                self:E(self.lid.."Could not find the word 'id' in id:val pair.")
            end
        end
    end
end

--#endregion MarkerOps Tanker Cancel

BASE:T("Mission Tanker Alts:\n"..ROLLN.print_table(MISSION_TANKER_ALTS))


--#region MarkerOps Tanker Create

--Build a keyword table from the defaultParams table. Keyword table is used for MARKEROPS_BASE
local markerKeywordsTanker = {}
for key, _ in pairs(defaultParamsTanker) do
    table.insert(markerKeywordsTanker, key)
end
BASE:T(string.format("Tanker marker keywords:\n%s", ROLLN.print_table(markerKeywordsTanker)))

TacticalTankerMaker = MARKEROPS_BASE:New("-tanker\n", markerKeywordsTanker)
-- TacticalTankerMaker.debug = true
TacticalTankerMaker.valid = false

-- Tanker from:carrier freq:242 chan:42 req:2 alt:12000 spd:265 hdg:45 leg:17 start:2 dur:45
-- Tanker req:1 alt:5000 start:1 dur:5
function TacticalTankerMaker:OnAfterMarkChanged(From,Event,To,Text,Keywords,Coord)
    self:T(self.lid..'OnAfterMarkChanged')
    self:T("\n"..self.lid..string.format("Data:\nText:%s\nKeywords:%s", Text, ROLLN.print_table(Keywords)))

    local completeMarkerText = false
    for _, word in pairs(Keywords) do
        if word == "done" then
            completeMarkerText = true
            break
        end
    end

    if completeMarkerText then
        local currentTime = timer.getAbsTime()
        -- Text = Text:gsub('\n', ' ') -- remove newline chars from the marker text

        -- Remove the original mark and add a new one so we can update the text
        -- trigger.action.removeMark(self.markId)
        
        local newMarker = UTILS.DeepCopy(Coord)
        -- local newMarker = MARKER:New(Coord, "Submitting..."):ReadOnly():ToBlue()
        -- self:T(self.lid..'Marker ID: '..tostring(self.markId))

        newMarker._Id = createMarkerId()
        newMarker._Text = string.format("(%03d) Submitting...", newMarker._Id)
        newMarker._TextMGRS = "\n\n"..newMarker:ToStringMGRS()
        newMarker._TextCAP = ""
        newMarker._TextCoord = COORDINATE:NewFromVec3{x = Coord.x, y = Coord.y, z =  Coord.z + 4000}
        newMarker._CircleId = newMarker:CircleToAll(3000, 2, {1,0,0}, 0.8, {1,0,0}, 0.3,  1)
        newMarker._TextId = newMarker._TextCoord:TextToAll(newMarker._Text, 2, {255,255,255}, 0.6, {0,0,1}, 0, 9)
        newMarker._Auftrags = {}

        local tankerParams = validateTankerMarker(self.Tag, Text)

        self:T(self.lid.."Validated tanker params alt: "..tankerParams.alt.value)
        self:T(self.lid.."Validated tanker params dur: "..tankerParams.dur.value)
        self:T(self.lid.."Validated tanker params hdg: "..tankerParams.hdg.value)
        self:T(self.lid.."Validated tanker params leg: "..tankerParams.leg.value)
        self:T(self.lid.."Validated tanker params req: "..tankerParams.req.value)
        self:T(self.lid.."Validated tanker params spd: "..tankerParams.spd.value)
        self:T(self.lid.."Validated tanker params cap: "..tostring(tankerParams.cap))
        self:T(self.lid.."Validated tanker params start: "..tankerParams.start.value)
        -- self:T(self.lid.."Validated tanker params type : "..tankerParams.type.value)
        -- self:T(self.lid.."Validated tanker params:from"..ROLLN.print_table(tankerParams.from))

        self:T(self.lid.."Creating auftrag(s)")

        local _capAssigned = false
        
        -- For the number of tankers requested, build an AUFTRAG for each.  Offest altitues, frequencies, TACAN channels
        -- and TACAN idents for each mission.
        for i = 1, tankerParams.req.value do
            local _start, _alt, _freq, _chan, _ident, _tankerType, _requestedBase, _cap

            -- If more than one tanker has been requested, offset some of the values
            _start = tankerParams.start.value + ((i - 1) * 120) -- Offest the start times of each AUFTRAG by 2 minutes. This also ensures callsigns are issued incrementally (7-1, 7-2, 7-3, etc) 
            _alt = tankerParams.alt.value + ((i -1) * 1000) -- Offset each tanker by 1000 feet in altitude
            
            -- randomize the radio stuff
            _freq = getRandomFreeValueFromPool(tankerFreqs) + round(math.random() / 0.05)*0.05
            _chan = getRandomFreeValueFromPool(tankerTACANS)
            _ident = ''
            _tankerType = 1 -- probe
            _cap = tankerParams.cap

            -- Set the refueling type and whether or not to issue a CAP flight
            for _, val in pairs(Keywords) do
                if val == "cap" then
                    _cap = true
                elseif val == "boom" then
                    _tankerType = tankerParams.boom
                elseif val == "probe" then
                    _tankerType = tankerParams.probe
                end
            end
            self:T(string.format("%s alt:%s freq:%s chan:%s ident:%s cap:%s", self.lid, _alt, _freq, _chan, _ident, tostring(_cap)))
        
            local tankerMission = AUFTRAG:NewTANKER(
                Coord,
                _alt,
                tankerParams.spd.value,
                tankerParams.hdg.value,
                tankerParams.leg.value,
                _tankerType)
                :SetTime(_start)
                :SetDuration(tankerParams.dur.value)
                :SetMissionRange(500)
                -- :SetRadio(_freq)
                -- :SetTACAN(_chan, _ident)

            -- check for specific tanker starting location
            for _, val in pairs(Keywords) do
                if val == "carrier" then
                    _requestedBase = "carrier"
                    tankerMission:AssignSquadrons(tankerParams.carrier)
                elseif val == "ground" then
                    _requestedBase = "airbase"
                    tankerMission:AssignSquadrons(tankerParams.airbase)
                end
            end

            -- tankerMission.type = AUFTRAG.Type.TANKER

            -- Keep track of values so they are easily accessible in the future
            tankerMission._alt = _alt
            tankerMission._freq = _freq
            tankerMission._chan = _chan
            tankerMission._ident = _ident
            tankerMission._dur = tankerParams.dur.value
            tankerMission._hdg = tankerParams.hdg.value
            tankerMission._leg = tankerParams.leg.value
            tankerMission._spd = tankerParams.spd.value
            tankerMission._start = tankerParams.start.value
            tankerMission._cap = tankerParams.cap
            tankerMission._callsignNumbers = ""
            tankerMission._callsignName = ""
            tankerMission._parentMarkerId = nil
            tankerMission._isTanker = true
            tankerMission._tankerType = _tankerType
            tankerMission._cap = _cap
            tankerMission._requestedBase = _requestedBase


            function tankerMission:OnAfterStarted(From, Event, To)
                self:T(self.lid.."OnAfterStarted")
                local _opsGroup = self:GetOpsGroups()[1]
                
                -- Clear the tanker task (so not shown in radio tanker menu yet) and get the 
                -- callsign asigned by DCS
                if _opsGroup then
                    self:T(self.lid.."We have an opsgroup.")
                    -- _opsGroup:TurnOffTACAN()
                    local _group = _opsGroup:GetGroup()
                    if _group then
                        self:T(self.lid.."We have a group")
                        -- _group:SetTask({id='NoTask', params={}})
                        -- self:T(self.lid.."Setting 'NoTask' task.")

                        -- callsignName → e.g. Arco
                        -- callsignNumbers → e.g. 23
                        -- _ident → e.g. A23
                        local callsign = _group:GetCallsign()
                        self._callsignName = callsign:sub(1, #callsign-3)
                        self._callsignNumbers = callsign:sub(#callsign-2, #callsign-2)..callsign:sub(#callsign,#callsign)

                        self._ident = callsign:sub(1,1)..self._callsignNumbers
                        self:T(self.lid.."Getting callsigns.  callsignName:"..self._callsignName.."  callsignNumbers:"..self._callsignNumbers.."  _ident:"..self._ident)

                        _group:CommandSetFrequency(self._freq,radio.modulation.AM,2)
                        self:T(self.lid.."Setting radio freq: "..self._freq)

                        _opsGroup:SwitchTACAN(self._chan, self._ident)
                        self:T(self.lid.."Turning on TACAN. chan: "..self._chan.."  ident: "..self._ident)
                    end
                end

                -- Update marker text to AAR : Launched → Enroute
                local markerFound = false
                local updateText = false
                if self._isTanker then
                    for _, marker in pairs(markersMasterList) do
                        if not markerFound then
                            for _, auftrag in pairs(marker._Auftrags) do 
                                if auftrag:GetName() == self:GetName() then
                                    self:T(self.lid.."Found marker this auftrag belongs to.")
                                    markerFound = true
                                end
                            end
                            if markerFound then
                                -- marker._Text = {}
                                -- table.insert(marker._Text, 'AAR : Launched → Enroute')

                                marker._Text = string.format("(%03d) AAR : Starting → Enroute\n", marker._Id)

                                for _, auftrag in pairs(marker._Auftrags) do
                                    -- Only use the Tanker auftrags to update marker text, not the cap auftrag should there be one.
                                    self:T(self.lid.."Auftrag type: "..tostring(auftrag.type).."  isTanker: "..tostring(auftrag._isTanker))
                                    if auftrag._isTanker and auftrag:IsStarted() then
                                        -- Arco71 240.25 40Y A71 12000
                                        self:T(self.lid.."Auftrag name: "..auftrag:GetName())
                                        local auftragText = string.format("\n%s%s %.2f %dY %s %d", auftrag._callsignName, auftrag._callsignNumbers, auftrag._freq, auftrag._chan, auftrag._ident, auftrag._alt)
                                        -- table.insert(marker._Text, auftragText)
                                        marker._Text = marker._Text..auftragText

                                        if not updateText then
                                            updateText = true
                                        end
                                    end
                                end

                                if not updateText then
                                    updateText = true
                                end

                                marker._Text = marker._Text..marker._TextMGRS
                                trigger.action.setMarkupText(marker._TextId, marker._Text)
                                trigger.action.setMarkupColor(marker._CircleId, {1,1,0, 0.8})
                                trigger.action.setMarkupColorFill(marker._CircleId, {1,1,0, 0.3})
                                self:T(self.lid.."Updating enroute marker text: "..marker._Text)
                                break
                            end
                        end
                    end
                end
            end

            function tankerMission:OnBeforeExecuting(From, Event, To)
                self:T(self.lid.."OnBeforeExecuting")

                local _opsGroup = self:GetOpsGroups()[1]
                
                -- Enable the tanker task and turn on the TACAN
                if _opsGroup then
                    self:T(self.lid.."We have an opsgroup.")
                    local _group = _opsGroup:GetGroup()
                    if _group then
                        -- self:T(self.lid.."We have a group, setting 'Tanker' task and radio to "..self._freq.." MHz")
                        -- _group:SetTask({id = 'Tanker', params = {}})

                        -- self:T(self.lid.."Setting radio to "..self._freq.." MHz. Mission freq.")
                        -- _group:CommandSetFrequency(self._freq)
                    end
                    -- _opsGroup:SwitchTACAN(self._chan, self._ident)
                    -- self:T(self.lid.."Turning on TACAN. chan: "..self._chan.."  ident: "..self._ident)
                end

                -- Update marker text to AAR : On Station until → 00:00:00
                local markerFound = false
                local updateText = false
                if self._isTanker then
                    for _, marker in pairs(markersMasterList) do
                        if not markerFound then
                            for _, auftrag in pairs(marker._Auftrags) do
                                if auftrag:GetName() == self:GetName() then
                                    self:T(self.lid.."Found marker this auftrag belongs to.")
                                    markerFound = true
                                end
                            end
                            if markerFound then
                                self:T(self.lid.."Building text for each auftrag of this marker.")

                                -- marker._Text = {} -- Reset the text table for rebuild
                                -- local finishTime = UTILS.SecondsToClock(timer.getAbsTime() + self._dur, true)
                                -- table.insert(marker._Text, string.format("AAR : On station until → %s", finishTime))

                                local finishTime = UTILS.SecondsToClock(timer.getAbsTime() + self._dur, true)
                                marker._Text = string.format("(%03d) AAR : On station until → %s\n", marker._Id, finishTime)

                                for _, auftrag in pairs(marker._Auftrags) do
                                    -- Only use the Tanker auftrags to update marker text, not the cap auftrag should there be one.
                                    self:T(self.lid.."Auftrag type: "..tostring(auftrag.type).."  isTanker: "..tostring(auftrag._isTanker))
                                    if auftrag._isTanker then
                                        -- Arco71 240.25 40Y A71 12000
                                        self:T(self.lid.."Auftrag name: "..auftrag:GetName())
                                        local auftragText = string.format("\n%s%s %.2f %dY %s %d", auftrag._callsignName, auftrag._callsignNumbers, auftrag._freq, auftrag._chan, auftrag._ident, auftrag._alt)
                                        -- table.insert(marker._Text, auftragText)

                                        marker._Text = marker._Text..auftragText

                                        if not updateText then
                                            updateText = true
                                        end
                                    end
                                end

                                if updateText then
                                    marker._Text = marker._Text..marker._TextMGRS
                                end

                                trigger.action.setMarkupText(marker._TextId, marker._Text)
                                trigger.action.setMarkupColor(marker._TextId, {1,1,1,1})
                                trigger.action.setMarkupColor(marker._CircleId, {0,1,0,0.8})
                                trigger.action.setMarkupColorFill(marker._CircleId, {0,1,0,0.3})
                                self:T(self.lid.."Updating on station marker text: "..marker._TextId)
                                break
                            end
                        end
                    end
                end
            end

            function tankerMission:OnAfterDone(From, Event, To)
                self:T(self.lid.."OnAfterDone")

                local _opsGroup = self:GetOpsGroups()[1]
                
                if _opsGroup then
                    self:T(self.lid.."We have an opsgroup.")
                    local _group = _opsGroup:GetGroup()
                    if _group then
                        -- self:T(self.lid.."We have a group, setting 'NoTask' task.")
                        -- _group:SetTask({id='NoTask', params={}})
                    end
                    -- self:SetRadio(265) -- Warfighter tower
                    -- _opsGroup:TurnOffTACAN()
                end

                -- Delete the marker
                if self._isTanker then
                    local currentMarkerId = nil
                    for _, marker in pairs(markersMasterList) do
                        for _, auftrag in pairs(marker._Auftrags) do 
                            if auftrag:GetName() == self:GetName() then
                                -- marker:Remove()
                                currentMarkerId = marker._Id

                                marker:RemoveMark(marker._CircleId)
                                marker:RemoveMark(marker._TextId)
                                self:T(self.lid.."We have a marker this auftrag belongs to.  Deleting marker.")
                            end
                        end
                    end
                    if currentMarkerId then
                        for i = 1, #markersMasterList, 1 do
                            if markersMasterList[i]._Id == currentMarkerId then
                                table.remove(markersMasterList, i)
                                break
                            end
                        end
                    end
                end
            end

            function tankerMission:OnAfterStop(From, Event, To)
                self:T(self.lid.."OnAfterStop")

                -- Return freq and TACAN values to the pool
                returnValueToPool(tankerFreqs, self._freq)
                returnValueToPool(tankerTACANS, self._chan)
            end

            local newMission = UTILS.DeepCopy(tankerMission)
            table.insert(newMarker._Auftrags, newMission)
            NATO_CHIEF:AddMission(newMission)
            self.valid = true

            self:T(self.lid.."Keywords: "..table.concat(Keywords,", "))
            if _cap and not _capAssigned then
                --CAP flight requested
                local capZoneCoordinate = newMarker:GetCoordinate()
                local capZone = ZONE_RADIUS:New("tankerCapZone", capZoneCoordinate:GetVec2(), 300000)
        
                local capMission = AUFTRAG:NewCAP(capZone, 30000, 320, capZoneCoordinate, tankerParams.hdg.value, tankerParams.leg.value)
                    :SetTime(tankerParams.start.value + 300)  -- start 10 mins later than tanker
                    :SetDuration(tankerParams.dur.value + 900) -- on station 15 mins longer than the tanker duration
                    :SetMissionRange(500)
        
                table.insert(newMarker._Auftrags, capMission)
                NATO_CHIEF:AddMission(capMission)

                _capAssigned = true
            end
        end

        local commenceTime = UTILS.SecondsToClock(currentTime + tankerParams.start.value + 300, true)
        newMarker._Text = string.format("(%03d) AAR : Starts at → %s", newMarker._Id, commenceTime)

        newMarker._Text = newMarker._Text..newMarker._TextMGRS

        trigger.action.setMarkupText(newMarker._TextId, newMarker._Text)
        trigger.action.setMarkupColor(newMarker._CircleId, {1,0.5,0,0.8})
        trigger.action.setMarkupColorFill(newMarker._CircleId, {1,0.5,0,0.3})

        table.insert(markersMasterList, newMarker)
        self:T(self.lid.."markerMasterList count: "..#markersMasterList)
    end
end

--#endregion MarkerOps Tanker Create

--#endregion MarkerOps Tanker

BASE:I("markerops_tanker | Loaded...")