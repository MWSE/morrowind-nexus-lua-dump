local core = require('openmw.core')

local module = {
    MOD_NAME = "HBFS",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    isOpenMW049 = core.API_REVISION > 29,
    gameSaveVersion = 2.3,
    interfaceVersion = 1.0,
}

module.renderers = {
    percentAndIncrease = "hbfs_percentAndIncrease",
    empty = module.MOD_NAME .. "hbfs_empty",
}

module.events = {
    -- GLOBAL
    updatePercentSetting = "hbfs_updatePercentSetting",
    updatePercentSettings = "hbfs_updatePercentSettings",
    forwardToPlayers = "hbfs_forwardToPlayers",
    moveItem = "hbfs_deleteItem",
    onActorDied = "hbfs_onActorDied",
    commitTheft = "hbfs_commitTheft",
    -- PLAYER
    showMessage = "hbfs_showMessage",
    updatePlayerSetting = "hbfs_updatePlayerSetting",
    setGuardOwnedItems = "hbfs_setGuardOwnedItems",
    -- ACTORS
    onActorActive = "hbfs_onActorActive",
    onActorReady = "hbfs_onActorReady",
    updateActorStats = "hbfs_updateActorStats",
}

return module