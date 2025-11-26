local core = require('openmw.core')

local module = {
    MOD_NAME = "NCG",
    isOpenMW49 = core.API_REVISION >= 70,
    interfaceVersion = 1.0,
    savedGameVersion = 1.0,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.actions = {
    showLogs = key("show_logs"),
}

module.inputKeys = {
    defaultLogsKey = module.actions.showLogs .. "_default",
}

module.events = {
    refreshLogsWindow = key("refresh_logs_window"),
    updateRequest = key("update_request"),
    onSkillLevelUp = key("on_skill_level_up"),
}

module.requestTypes = {
    softInit = "soft_init",
    starterSpells = "starter_spells",
    startAttrsOnResume = "start_attrs_on_resume",
    refreshStats = "refresh_stats",
    refreshStatsOnResume = "refresh_stats_on_resume",
    health = "health",
}

module.renderers = {
    hotkey = key("hotkey"),
    number = key("number"),
    perAttributeUncapper = key("per_attribute_uncapper"),
}

return module
