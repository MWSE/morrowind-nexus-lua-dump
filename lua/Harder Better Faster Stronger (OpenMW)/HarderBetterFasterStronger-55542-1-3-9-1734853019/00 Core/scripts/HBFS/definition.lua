local core = require('openmw.core')

return {
    MOD_NAME = "HBFS",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.38,
    interfaceVersion = 1.0,
}

