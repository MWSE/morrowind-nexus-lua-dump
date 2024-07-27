local core = require('openmw.core')

return {
    MOD_NAME = "NCGDMW",
    isLuaApiRecentEnough = core.API_REVISION >= 56,
    isOpenMW049 = core.API_REVISION > 29,
}
