---@diagnostic disable: missing-parameter

local function db(msg)
    log.write('ROLLN', log.INFO, msg)
end

---Draws a circle on F10 map where unit is located. Draws the text at a 45 degree offset at the offset distance away from center of circle.
---Draws a line between the center of the circle to the offset text. Updates map every 60 seconds.
---@param Unit UNIT Unit to center the circle on.
---@param Coalition number Coalition to draw to. e.g. -1=All, 0=Neutral, 1=Red, 2=Blue. Default is -1. 
---@param Radius number Circle radius in meters. Default is 4000
---@param Color table A table containing the RGB color for text, circle and line. e.g. {0,1,0,0.5} for green with 50% tranparency. Default is empty table {}.
---@param ColorFill table A table containing the RGB color to fill the circle. e.g. {0,1,0,0.5} for green with 50% tranparency. Default is empty table {}.
---@param FontSize number Text font size. Default is 14.
---@param LineType number Line type. e.g. 0=No Line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot Dash, 5=Long Dash, 6=Two Dash. Default is 0
---@param Text string Text to be drawn. Default is empty string (no text).
---@param TextOffsetDist number Offset in NM from the center of the circle to write the text. Default is 4.5.
---@param TextOffsetDegrees number Offset degrees from center of the circle to write the text. Default is 45.
---@param UpdateFrequency number Frequency in seconds to update the drawn items. Default is 0.
---@param MarkIDText number Mark ID of the drawn text. Auto generated, do not set.
---@param MarkIDCircle number Mark ID of the drawn circle. Auto generated, do not set.
---@param MarkIDLine number Mark ID of the drawn line. Auto generated, do not set.
local function unitCustomMarkUpdater(Unit, Coalition, Radius, Color, ColorFill, FontSize, LineType, Text, TextOffsetDist, TextOffsetDegrees, UpdateFrequency,
                                     MarkIDText, MarkIDCircle, MarkIDLine)
    local _coalition = Coalition or -1
    local _unit = Unit or nil
    local _radius = Radius or 4000
    local _color = Color or {}
    local _colorFill = ColorFill or {}
    local _fontSize = FontSize or 14
    local _lineType = LineType or 0
    local _text = Text or ''
    local _textOffsetDist = TextOffsetDist or 4.5
    local _textOffsetDegrees = TextOffsetDegrees or 45
    local _updateFrequency = UpdateFrequency or 0
    local _markIDText = MarkIDText
    local _markIDCircle = MarkIDCircle
    local _markIDLine = MarkIDLine

    -- db('Name: '.._unit:GetName()..'  IsClient: '..tostring(_unit:IsClient())..'  IsActive: '..tostring(_unit:IsActive())..'  IsAlive: '..tostring(_unit:IsAlive()))
    if _unit then
        -- Unit may still be valid but is not alive, if not alive, delete it's marks and don't reschedule update.
        if _unit:IsAlive() then
            local _unitCoordinate = _unit:GetCoordinate()
            local _unitVec3 = _unitCoordinate:GetVec3()
            local _textOffsetVec3 = _unitCoordinate:Translate(UTILS.NMToMeters(_textOffsetDist), _textOffsetDegrees)
            local _lineStartPoint = _unitCoordinate:Translate(_radius, _textOffsetDegrees)

            -- If no mark ID, create a new one and draw them for the first time.  If there is a mark ID, draw them ising the updated locations.
            if not _markIDText then
                -- db('New mark for '.._unit:GetName())
                _markIDText = UTILS.GetMarkID()
                _markIDCircle = UTILS.GetMarkID()
                _markIDLine = UTILS.GetMarkID()

                trigger.action.textToAll(_coalition, _markIDText, _textOffsetVec3, _color, {}, _fontSize, true, _text)
                trigger.action.circleToAll(_coalition, _markIDCircle, _unitVec3, _radius, _color, _colorFill, 0, true)
                trigger.action.lineToAll(_coalition, _markIDLine, _lineStartPoint, _textOffsetVec3, {255, 255, 255, 1}, _lineType, true)
            else
                -- db('Updating mark for '.._unit:GetName())
                trigger.action.setMarkupPositionStart(_markIDText, _textOffsetVec3)
                trigger.action.setMarkupPositionStart(_markIDCircle, _unitVec3)
                trigger.action.setMarkupPositionStart(_markIDLine, _lineStartPoint)
                trigger.action.setMarkupPositionEnd(_markIDLine, _textOffsetVec3)
            end

            -- db('UpdateFrequency: '.._updateFrequency)
            if _updateFrequency > 0 then
                TIMER:New(unitCustomMarkUpdater, _unit, _coalition, _radius, _color, _colorFill, _fontSize, _lineType, _text,
                    _textOffsetDist, _textOffsetDegrees, _updateFrequency, _markIDText, _markIDCircle, _markIDLine):Start(_updateFrequency)
            end
        else
            -- db('Removing mark for '.._unit:GetName())
            trigger.action.removeMark(_markIDText)
            trigger.action.removeMark(_markIDCircle)
            trigger.action.removeMark(_markIDLine)
        end
    end
end

-- Default DCS map icon color code rgb(17, 191, 254) / #11bffe

-- Mark the main ships
unitCustomMarkUpdater(Washington.carrier, coalition.side.BLUE, 8000, { 255, 255, 255, 1 }, { 0, 0, 1, 0.2 }, 14, 1, Washington.alias, 6.5, 45, 60)
unitCustomMarkUpdater(Tarawa.carrier, coalition.side.BLUE, 8000, { 255, 255, 255, 1 }, { 0, 0, 1, 0.2 }, 14, 1, Tarawa.alias, 6.5, 45, 60)

-- Mark the FARPs
unitCustomMarkUpdater(UNIT:FindByName('FARP-DUBLIN-VEH-1'), coalition.side.BLUE, 1, { 255, 255, 255, 1 }, { 255, 255, 255, 0.2 }, 15, 1, 'Dublin FARP', 2.5)
unitCustomMarkUpdater(UNIT:FindByName('FARP-DALLAS-VEH-1'), coalition.side.BLUE, 1, { 255, 255, 255, 1 }, { 255, 255, 255, 0.2 }, 15, 1, 'Dallas FARP', 2.5)
unitCustomMarkUpdater(UNIT:FindByName('FARP-ROME-VEH-1'), coalition.side.BLUE, 1, { 255, 255, 255, 1 }, { 255, 255, 255, 0.2 }, 15, 1, 'Rome FARP', 2.5, 315)

-- Mark all Blue coalition clients.
function BLUE_CLIENT_SET:OnEventPlayerEnterAircraft(EventData)
    local _eventData = EventData
    local _unit = _eventData.IniUnit
    local _unitCoalition = _unit:GetCoalition()

    if _unitCoalition == coalition.side.BLUE then
        unitCustomMarkUpdater(_unit, coalition.side.BLUE, 5000, { 255, 255, 255, 1 }, { 255, 255, 255, 0.2 }, 14, 1, _unit:GetPlayerName(), 5.0, 45, 30)
    end
end

-- Mark all Red coalition clients.
function RED_CLIENT_SET:OnEventPlayerEnterAircraft(EventData)
    local _eventData = EventData
    local _unit = _eventData.IniUnit
    local _unitCoalition = _unit:GetCoalition()

    if _unitCoalition == coalition.side.RED then
        unitCustomMarkUpdater(_unit, coalition.side.RED, 5000, { 255, 255, 255, 1 }, { 255, 255, 255, 0.2 }, 14, 1, _unit:GetPlayerName(), 5.0, 45, 30)
    end
end