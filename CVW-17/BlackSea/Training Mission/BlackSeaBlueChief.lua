local KobuletiStorage = STORAGE:FindByName("Kobuleti")

local f18 = KobuletiStorage:GetItemAmount("FA-18C_hornet")
env.info(string.format("We currently have %d F/A-18C's available", f18))

local airwing = AIRWING:New("wh","test")
