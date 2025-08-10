

function hookTest()
local playerUnits = {}
for _, group in pairs(coalition.getPlayers(coalition.side.BLUE)) do
    for _, unit in pairs(group:getUnits()) do
        table.insert(playerUnits, unit)

    local unitClient = Unit.getByName()
    local hookArgument = unitClient:getDrawArgumentValue(25)
    local hookArgument_Tomcat = unitClient:getDrawArgumentValue(1305)
    if hookArgument then
    env.info("the Hook is up")
    else    
        env.info("the Hook is down")
    end
        end
end
end
local hookTestTimer = TIMER:New(hookTest)
hookTestTimer:Start(nil,1)


  
