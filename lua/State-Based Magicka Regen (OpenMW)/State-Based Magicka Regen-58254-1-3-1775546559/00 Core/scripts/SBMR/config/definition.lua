local core = require("openmw.core")

local module = {
    MOD_NAME = "SBMR",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    saveVersion = 1.0,
    interfaceVersion = 1.0,
}

module.getMessageKeyIfOpenMWTooOld = function(key)
    if not module.isLuaApiRecentEnough then
        return "requiresOpenMW49"
    end
    return key
end

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.scripts = {
    actor = "scripts/SBMR/actor.lua",
}

module.events = {
    updateArguments = key("update_arguments"),
    setCurrPlayerRegen = key("set_curr_player_regen"),
}

module.renderers = {
    number = key("number"),
    range = key("range"),
}

return module