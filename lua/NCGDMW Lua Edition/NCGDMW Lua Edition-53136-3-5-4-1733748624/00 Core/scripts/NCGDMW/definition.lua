local core = require('openmw.core')

return {
    MOD_NAME = "NCGDMW",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
}
