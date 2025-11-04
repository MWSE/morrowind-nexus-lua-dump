local core = require('openmw.core')

local module = {
    MOD_NAME = "NCGDMW",
    isOpenMW50 = core.API_REVISION >= 91,
    interfaceVersion = 4.3,
    savedGameVersion = 4.64,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    -- Player
    showStatsMenu = key("show_stats_menu"),
    applySkillUsedHandlers = key("apply_skill_used_handlers"),
    updateRequest = key("update_request"),
    changeDecayRate = key("change_decay_rate"),
    onSkillLevelUp = key("show_skill_level_up_message"),
    onActorHit = key("on_actor_hit"),
    onPlayerHit = key("on_player_hit"),
    onActorAnimHit = key("on_actor_anim_hit"),
    setWerewolfClawMult = key("set_werewolf_claw_mult"),
    -- Global
    skipGameHours = key("skip_game_hours"),
}

module.requestTypes = {
    softInit = "soft_init",
    starterSpells = "starter_spells",
    startAttrsOnResume = "start_attrs_on_resume",
    refreshStats = "refresh_stats",
    refreshStatsOnResume = "refresh_stats_on_resume",
    health = "health",
}

module.refreshModes = {
    normal = "normal",
    skillChange = "skill_change",
}

module.renderers = {
    hotkey = key("hotkey"),
    number = key("number"),
    range = key("range"),
    decayRate = key("decay_rate"),
    perSkillUncapper = key("per_skill_uncapper"),
    perAttributeUncapper = key("per_attribute_uncapper"),
}

module.mwscriptGlobalVars = {
    werewolfClawMult = "werewolfclawmult",
    skipGameHours = key("Skip_Game_Hours"),
}

module.logRangeTypes = {
    scaledTrainingDuration = "scaledTrainingDuration",
    skillGainFactorRange = "skillGainFactorRange",
}

module.logRangeFunctions = {
    [module.logRangeTypes.skillGainFactorRange] = function(value, min, max)
        return (min / 100) / ((min / max - 1) * (value / 100) ^ 2 + 1)
    end,
    [module.logRangeTypes.scaledTrainingDuration] = function(value, min, max)
        return min + (max - min) * (value / 100) ^ 2
    end
}

return module
