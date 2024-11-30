

local FsmSwitch = FSM:New() -- #FsmDemo
BASE:E("starting FSM")


FsmSwitch:SetStartState( "Off" )
FsmSwitch:AddTransition( "Off", "SwitchOn", "On" )
FsmSwitch:AddTransition( "*", "SwitchMiddle", "Middle" )
FsmSwitch:AddTransition( "*", "SwitchOff", "Off" )
FsmSwitch:AddTransition( "Middle", "SwitchOff", "Off" )



function FsmSwitch:OnAfterSwitchOn(From,Event,To)
    self:E("leaving off")
    FsmSwitch:__SwitchMiddle(5)

end

-- function FsmSwitch:OnSwitchOn(From,Event,To)
--     self:E("Triggered")
-- end

-- function FsmSwitch:OnAfterOn(From,Event,To)
--     self:E("Switch turned on")
--     FsmSwitch:__SwitchMiddle(5)
-- end

function FsmSwitch:OnAfterSwitchMiddle(From,Event,To)
    self:E("Switch in middle")
    FsmSwitch:__SwitchOff(5)
end

function FsmSwitch:OnAfterSwitchOff(From,Event,To)
    self:E("Switch off")
    FsmSwitch:__SwitchOn(5)
end





FsmSwitch:SwitchOn()

