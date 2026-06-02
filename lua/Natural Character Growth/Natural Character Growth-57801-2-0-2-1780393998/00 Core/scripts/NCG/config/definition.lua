local core = require('openmw.core')

local module = {
    MOD_NAME = "NCG",
    isLuaApiRecentEnough = core.API_REVISION >= 70,
    interfaceVersion = 1.0,
    savedGameVersion = 2.0,
}

module.getMessageKeyIfOpenMWTooOld = function(key)
    if not module.isLuaApiRecentEnough then
        return "requiresOpenMW49"
    end
    return key
end

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
    -- Global
    onBitterCupHandled = key("on_bitter_cup_handled"),
    -- Player
    refreshLogsWindow = key("refresh_logs_window"),
    updateRequest = key("update_request"),
    onSkillLevelUp = key("on_skill_level_up"),
    modAttributes = key("mod_attributes"),
    onBitterCupActivated = key("on_bitter_cup_activated"),
    -- External
    statsWindowShown = "StatsWindow_Shown",
    skillEvolutionOnSkillsChanged = "SkillEvolution_on_skills_changed",
    onChargenModRegistration = "onChargenModRegistration",
    onChargenModFinished = "onChargenModFinished",

}

module.requestTypes = {
    initProfile = "init_profile",
    starterSpells = "starter_spells",
    startAttrsOnResume = "start_attrs_on_resume",
    refreshStats = "refresh_stats",
    health = "health",
}

module.renderers = {
    hotkey = key("hotkey"),
    number = key("number"),
    perAttributeUncapper = key("per_attribute_uncapper"),
}

return module
