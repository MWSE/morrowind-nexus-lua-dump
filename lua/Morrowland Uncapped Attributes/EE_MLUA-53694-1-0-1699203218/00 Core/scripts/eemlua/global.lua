local world = require('openmw.world')
local mwscript = world.mwscript

local function onLevelUp(data)
    local globals = mwscript.getGlobalVariables(data.player)
    if globals.EE_MLuaState == 0 then
        globals.EE_MLuaState = 1
    end
end

local function onFinishLevelUp(data)
    local globals = mwscript.getGlobalVariables(data.player)
    if globals.EE_MLuaState == 2 then
        if data.hasLevel then
            globals.EE_MLuaState = 1
        else
            globals.EE_MLuaState = 0
        end
    end
end

return {
    eventHandlers = {
        EE_MLua_InitLevel = onLevelUp,
        EE_MLua_FinishLevel = onFinishLevelUp
    }
}