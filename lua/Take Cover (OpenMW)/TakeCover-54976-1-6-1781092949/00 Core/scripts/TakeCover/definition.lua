local core = require('openmw.core')

local module = {
    MOD_NAME = "TakeCover",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.42,
    interfaceVersion = 1.0,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    handle_actor = key("handle_actor"),
}

return module
