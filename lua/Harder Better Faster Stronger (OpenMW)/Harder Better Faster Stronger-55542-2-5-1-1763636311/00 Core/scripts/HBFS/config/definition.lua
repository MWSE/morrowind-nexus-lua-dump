local core = require('openmw.core')

local module = {
    MOD_NAME = "HBFS",
    isOpenMW49OrAbove = core.API_REVISION >= 70,
    isOpenMW50OrAbove = core.API_REVISION >= 91,
    gameSaveVersion = 2.3,
    interfaceVersion = 1.0,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.renderers = {
    percentAndIncrease = key("percentAndIncrease"),
}

module.events = {
    -- GLOBAL
    updatePercentSetting = key("updatePercentSetting"),
    updatePercentSettings = key("updatePercentSettings"),
    forwardToPlayers = key("forwardToPlayers"),
    moveItem = key("deleteItem"),
    modItemCondition = key("modItemCondition"),
    onActorDied = key("onActorDied"),
    commitTheft = key("commitTheft"),
    -- PLAYER
    showMessage = key("showMessage"),
    refreshUiMode = key("refreshUiMode"),
    updatePlayerSetting = key("updatePlayerSetting"),
    setGuardOwnedItems = key("setGuardOwnedItems"),
    -- ACTORS
    onActorActive = key("onActorActive"),
    onActorReady = key("onActorReady"),
    updateActorStats = key("updateActorStats"),
}

return module