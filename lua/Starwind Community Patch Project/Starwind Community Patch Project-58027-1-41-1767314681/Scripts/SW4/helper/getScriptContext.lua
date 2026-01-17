local isNotMenu, types = pcall(function() return require('openmw.types') end)
local isGlobal, _ = pcall(function() require('openmw.world') end)
local isMenu, _ = pcall(function() require('openmw.menu') end)

local ScriptContext = {
    Types = {
        Local = 1,
        Global = 2,
        Player = 3,
        Menu = 4,
    },
}

function ScriptContext.GetScriptContext()
    if isGlobal then
        return ScriptContext.Types.Global
    elseif isMenu then
        return ScriptContext.Types.Menu
    elseif isNotMenu then
        local self = require('openmw.self')

        assert(types, "Types module is not available")
        if types.Player.objectIsInstance(self) then
            return ScriptContext.Types.Player
        else
            return ScriptContext.Types.Local
        end
    else
        error("Unable to determine script context")
    end
end

return ScriptContext
