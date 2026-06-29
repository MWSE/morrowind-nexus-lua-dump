local core = require('openmw.core')

local module = {
    MOD_NAME = "TakeCover",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.6,
    interfaceVersion = 1.0,
}

module.getMessageKeyIfOpenMWTooOld = function(key)
    if not module.isLuaApiRecentEnough then
        return "requiresOpenMW49"
    end
    return key
end

module.scripts = {
    actor = "scripts/TakeCover/actor.lua",
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    -- actor
    onTargetsChanged = key("on_targets_changed"),
    -- global
    onActorTargetsChanged = key("on_actor_targets_changed"),
}

return module
