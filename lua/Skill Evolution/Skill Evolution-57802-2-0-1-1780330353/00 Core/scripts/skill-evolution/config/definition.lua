local core = require('openmw.core')

local module = {
    MOD_NAME = "SkillEvolution",
    isOpenMW50 = core.API_REVISION >= 91,
    interfaceVersion = 1.0,
    savedGameVersion = 2.0,
}

local L = core.l10n(module.MOD_NAME)

module.getSkillUseTypeName = function(useTypeKey)
    return L(string.format("skillUseType_%s", useTypeKey))
end

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    -- Player
    applySkillUsedHandlers = key("apply_skill_used_handlers"),
    setCapperMaxLevels = key("set_capper_max_levels"),
    updateStats = key("update_stats"),
    onSkillsChanged = key("on_skills_changed"),
    onSkillLevelUp = key("show_skill_level_up_message"),
    changeDecayRate = key("change_decay_rate"),
    onActorHit = key("on_actor_hit"),
    onPlayerHit = key("on_player_hit"),
    onActorAnimHit = key("on_actor_anim_hit"),
    skipWeaponScaling = key("skip_weapon_scaling"),
    skipArmorScaling = key("skip_armor_scaling"),
    skipBlockScaling = key("skip_block_scaling"),
    setWerewolfClawMult = key("set_werewolf_claw_mult"),
    showMessage = key("show_message"),
    showModSkill = key("show_mod_skill"),
    onTimePassed = key("on_time_passed"),
    -- Global
    passHours = key("pass_hours"),
    removeObject = key("remove_object"),
    addObject = key("add_object"),
    addNewPotion = key("add_new_potion"),
}

module.renderers = {
    number = key("number"),
    skillGains = key("skillGains"),
    range = key("range"),
    decayRate = key("decay_rate"),
    perSkillUncapper = key("per_skill_uncapper"),
    empty = key("empty"),
}

module.callbacks = {
    skipWeaponScaling = key("skip_weapon_scaling"),
    skipArmorScaling = key("skip_armor_scaling"),
    skipBlockScaling = key("skip_block_scaling"),
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
    [module.logRangeTypes.skillLevelBasedScalingRange] = function(value, from, to)
        return (from / 100) / ((from / to - 1) * (value / 100) ^ 2 + 1)
    end,
    [module.logRangeTypes.scaledTrainingDuration] = function(value, from, to)
        return from + (to - from) * (value / 100) ^ 2
    end
}

return module
