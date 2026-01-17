local core = require('openmw.core')

local module = {
    MOD_NAME = "SkillEvolution",
    isOpenMW50 = core.API_REVISION >= 91,
    interfaceVersion = 1.0,
    savedGameVersion = 1.62,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    -- Player
    applySkillUsedHandlers = key("apply_skill_used_handlers"),
    updateStats = key("update_stats"),
    onSkillsChanged = key("on_skills_changed"),
    onSkillLevelUp = key("show_skill_level_up_message"),
    changeDecayRate = key("change_decay_rate"),
    onActorHit = key("on_actor_hit"),
    onPlayerHit = key("on_player_hit"),
    onActorAnimHit = key("on_actor_anim_hit"),
    setWerewolfClawMult = key("set_werewolf_claw_mult"),
    showMessage = key("show_message"),
    showModSkill = key("show_mod_skill"),
    onGameUnpaused = key("on_game_unpaused"),
    -- Global
    skipGameHours = key("skip_game_hours"),
    removeObject = key("remove_object"),
    addObject = key("add_object"),
    addNewPotion = key("add_new_potion"),
}

module.renderers = {
    number = key("number"),
    range = key("range"),
    decayRate = key("decay_rate"),
    perSkillUncapper = key("per_skill_uncapper"),
}

module.mwscriptGlobalVars = {
    werewolfClawMult = "werewolfclawmult",
    skipGameHours = key("Skip_Game_Hours"),
}

module.logRangeTypes = {
    scaledTrainingDuration = "scaledTrainingDuration",
    skillLevelBasedScalingRange = "skillLevelBasedScalingRange",
}

module.logRangeFunctions = {
    [module.logRangeTypes.skillLevelBasedScalingRange] = function(value, min, max)
        return (min / 100) / ((min / max - 1) * (value / 100) ^ 2 + 1)
    end,
    [module.logRangeTypes.scaledTrainingDuration] = function(value, min, max)
        return min + (max - min) * (value / 100) ^ 2
    end
}

return module
