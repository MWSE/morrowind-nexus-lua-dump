local core = require('openmw.core')

local module = {
    MOD_NAME = "HBFS",
    isOpenMW49OrAbove = core.API_REVISION >= 70,
    isOpenMW50OrAbove = core.API_REVISION >= 91,
    saveVersion = 2.61,
    interfaceVersion = 1.0,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.renderers = {
    percentAndIncrease = key("percent_and_increase"),
}

module.events = {
    -- GLOBAL
    forwardToPlayers = key("forward_to_players"),
    updatePercentSetting = key("update_percent_setting"),
    updatePercentSettings = key("update_percent_settings"),
    moveItem = key("delete_item"),
    modItemCondition = key("mod_item_condition"),
    onActorDied = key("on_actor_died"),
    commitTheft = key("commit_theft"),
    onOpenContainer = key("on_open_container"),
    initActorData = key("init_actor_data"),
    -- PLAYER
    showMessage = key("show_message"),
    refreshUiMode = key("refresh_ui_mode"),
    updatePlayerSetting = key("update_player_setting"),
    setGuardOwnedItems = key("set_guard_owned_items"),
    -- ACTORS
    setActorStats = key("set_actor_stats"),
    onActorReady = key("on_actor_ready"),
    updateActorStats = key("update_actor_stats"),
}

return module