local core = require('openmw.core')

local module = {
    MOD_NAME = "HBFS",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 2.0,
    interfaceVersion = 1.0,
}

module.renderers = {
    percentAndIncrease = "hbfs_percentAndIncrease",
    empty = module.MOD_NAME .. "hbfs_empty",
}

module.events = {
    updatePercentSetting = "hbfs_updatePercentSetting",
    updatePercentSettings = "hbfs_updatePercentSettings",
    updatePlayerSetting = "hbfs_updatePlayerSetting",
    onActorActive = "hbfs_onActorActive",
    onActorReady = "hbfs_onActorReady",
    updateActorStats = "hbfs_updateActorStats",
    showMessage = "hbfs_showMessage",
}

return module