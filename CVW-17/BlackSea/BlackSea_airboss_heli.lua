-- Debuging
-- BASE:TraceOnOff(true)
-- BASE:TraceLevel(3)
-- BASE:TraceClass('AIRBOSS_HELI')
BASE:I("BlackSea_airboss_heli.lua | Loading...")


AIRBOSS_HELI = {
    ClassName = "AIRBOSS_HELI",
    lid = "AIRBOSS_HELI",
    _airbossObjs = {},
    _clients = {},
    _requestRecovery = false,
    _recovering = false
}

function AIRBOSS_HELI:New(airbossObjs)
    self = BASE:Inherit(self, BASE:New())
    self:HandleEvent(EVENTS.PlayerEnterAircraft)

    self._airbossObjs = airbossObjs

    return self
end

function AIRBOSS_HELI:OnEventPlayerEnterAircraft(event_data)
    local group = event_data.IniGroup

    if group:IsHelicopter() then
        self:_SetupMenu(group)
    end
end

function AIRBOSS_HELI:DisplayCarrierInfo(heliGroup, airbossObj)
    local _airbossObj = airbossObj

    -- Current coordinates.
    local coord=_airbossObj:GetCoordinate()

    -- Carrier speed and heading.
    local carrierheading=_airbossObj.carrier:GetHeading()
    local carrierspeed=UTILS.MpsToKnots(_airbossObj.carrier:GetVelocityMPS())

    -- TACAN/ICLS.
    local tacan="unknown"
    local icls="unknown"
    if _airbossObj.TACANon and _airbossObj.TACANchannel~=nil then
    tacan=string.format("%d%s (%s)", _airbossObj.TACANchannel, _airbossObj.TACANmode, _airbossObj.TACANmorse)
    end
    if _airbossObj.ICLSon and _airbossObj.ICLSchannel~=nil then
    icls=string.format("%d (%s)", _airbossObj.ICLSchannel, _airbossObj.ICLSmorse)
    end

    -- Wind on flight deck
    local wind=UTILS.MpsToKnots(select(1, _airbossObj:GetWindOnDeck()))

    -- Get groups, units in queues.
    local Nmarshal,nmarshal   = _airbossObj:_GetQueueInfo(_airbossObj.Qmarshal)
    local Npattern,npattern   = _airbossObj:_GetQueueInfo(_airbossObj.Qpattern)
    local Nspinning,nspinning = _airbossObj:_GetQueueInfo(_airbossObj.Qspinning)
    local Nwaiting,nwaiting   = _airbossObj:_GetQueueInfo(_airbossObj.Qwaiting)
    local Ntotal,ntotal       = _airbossObj:_GetQueueInfo(_airbossObj.flights)

    -- Current abs time.
    local Tabs=timer.getAbsTime()

    -- Get recovery times of carrier.
    local recoverytext="Recovery time windows (max 5):"
    if #_airbossObj.recoverytimes==0 then
        recoverytext=recoverytext.." none."
        else
        -- Loop over recovery windows.
        local rw=0
        for _,_recovery in pairs(_airbossObj.recoverytimes) do
            local recovery=_recovery --#AIRBOSS.Recovery
            -- Only include current and future recovery windows.
            if Tabs<recovery.STOP then
                -- Output text.
                recoverytext=recoverytext..string.format("\n* %s - %s: Case %d (%d°)", UTILS.SecondsToClock(recovery.START), UTILS.SecondsToClock(recovery.STOP), recovery.CASE, recovery.OFFSET)
                if recovery.WIND then
                    recoverytext=recoverytext..string.format(" @ %.1f kts wind", recovery.SPEED)
                end
                rw=rw+1
                if rw>=5 then
                    -- Break the loop after 5 recovery times.
                    break
                end
            end
        end
    end

    -- Recovery tanker TACAN text.
    local tankertext=nil
    if _airbossObj.tanker then
        tankertext=string.format("Recovery tanker frequency %.3f MHz\n", _airbossObj.tanker.RadioFreq)
        if _airbossObj.tanker.TACANon then
            tankertext=tankertext..string.format("Recovery tanker TACAN %d%s (%s)",_airbossObj.tanker.TACANchannel, _airbossObj.tanker.TACANmode, _airbossObj.tanker.TACANmorse)
        else
            tankertext=tankertext.."Recovery tanker TACAN n/a"
        end
    end

    -- Carrier FSM state. Idle is not clear enough.
    local state=_airbossObj:GetState()
    if state=="Idle" then
    state="Deck closed"
    end
    if _airbossObj.turning then
    state=state.." (turning currently)"
    end

    -- Message text.
    local text=string.format("%s info:\n", _airbossObj.alias)
    text=text..string.format("================================\n")
    text=text..string.format("Carrier state: %s\n", state)
    if _airbossObj.case==1 then
    text=text..string.format("Case %d recovery ops\n", _airbossObj.case)
    else
    local radial=self:GetRadial(_airbossObj.case, true, true, false)
    text=text..string.format("Case %d recovery ops\nMarshal radial %03d°\n", _airbossObj.case, radial)
    end
    text=text..string.format("BRC %03d° - FB %03d°\n", _airbossObj:GetBRC(), _airbossObj:GetFinalBearing(true))
    text=text..string.format("Speed %.1f kts - Wind on deck %.1f kts\n", carrierspeed, wind)
    text=text..string.format("Tower frequency %.3f MHz\n", _airbossObj.TowerFreq)
    text=text..string.format("Marshal radio %.3f MHz\n", _airbossObj.MarshalFreq)
    text=text..string.format("LSO radio %.3f MHz\n", _airbossObj.LSOFreq)
    text=text..string.format("TACAN Channel %s\n", tacan)
    text=text..string.format("ICLS Channel %s\n", icls)
    if tankertext then
    text=text..tankertext.."\n"
    end
    text=text..string.format("# A/C total %d (%d)\n", Ntotal, ntotal)
    text=text..string.format("# A/C marshal %d (%d)\n", Nmarshal, nmarshal)
    text=text..string.format("# A/C pattern %d (%d) - spinning %d (%d)\n", Npattern, npattern, Nspinning, nspinning)
    text=text..string.format("# A/C waiting %d (%d)\n", Nwaiting, nwaiting)
    text=text..string.format(recoverytext)
    -- self:T2(self.lid..text)

    MESSAGE:New(text, 20):ToGroup(heliGroup)
end

function AIRBOSS_HELI:SetRecovery(heliGroup, airbossObj)
    local _airbossObj = airbossObj

    BASE:I("***************")
    BASE:I(_airbossObj)
    local text = ""
    local case = 1

    -- if not self._recovering then
    if _airbossObj:IsRecovering() then
        text = "Negative, we are already recovering."
    else
        -- Recovery staring in 5 min for 30 min.
        local t0=timer.getAbsTime()+5*60
        local t9=t0+_airbossObj.skipperTime*60
        local C0=UTILS.SecondsToClock(t0)
        local C9=UTILS.SecondsToClock(t9)

        text = string.format("Affirm, Case %d recovery will start in 5 min for %d min. Wind on deck %d knots. U-turn=%s. BRC expected to be %d degrees",
                            case,
                            _airbossObj.skipperTime,
                            _airbossObj.skipperSpeed,
                            tostring(_airbossObj.skipperUturn),
                            _airbossObj:GetBRCintoWind()
        )
        
        _airbossObj:AddRecoveryWindow(C0,
                                            C9,
                                            case,
                                            _airbossObj.skipperOffset,
                                            true,
                                            _airbossObj.skipperSpeed,
                                            _airbossObj.skipperUturn
        )
    end

    MESSAGE:New(text, 15):ToGroup(heliGroup)

    return self
end

function AIRBOSS_HELI:_SetupMenu(heliGroup)
    self:T(self.lid .. " _SetupMenu")

    -- BASE:I("-------------------------------------")
    -- BASE:I(self._airbossObj)
    -- BASE:I(heliGroup:GetUnits()[1])
    -- -- BASE:I(_unitName)
    -- BASE:I("-------------------------------------")


    local heli_menu = MENU_GROUP:New(
            heliGroup,
            "Airboss (Heli)"
    )
    for _, airbossObj in pairs(self._airbossObjs) do
        self:T(self.lid .. "Setting up menu for " .. airbossObj.alias)

        local airboss_heli_submenu = MENU_GROUP:New(heliGroup, airbossObj.alias, heli_menu)

        local heli_menu_command01 = MENU_GROUP_COMMAND:New(
            heliGroup,
            "Carrier Info",
            airboss_heli_submenu,
            self.DisplayCarrierInfo,
            self,
            heliGroup,
            airbossObj
        )

        local heli_menu_command02 = MENU_GROUP_COMMAND:New(
            heliGroup,
            "Start Recovery",
            airboss_heli_submenu,
            self.SetRecovery,
            self,
            heliGroup,
            airbossObj
        )
    end

    return self
end

BASE:I("BlackSea_airboss_heli.lua | Loaded.")
