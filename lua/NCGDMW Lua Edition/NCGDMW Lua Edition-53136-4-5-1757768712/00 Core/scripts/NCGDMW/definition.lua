local core = require('openmw.core')

local module = {
    MOD_NAME = "NCGDMW",
    isOpenMW049 = core.API_REVISION >= 70,
    interfaceVersion = 4.3,
    savedGameVersion = 4.4,
}

module.events = {
    -- Player
    showStatsMenu = module.MOD_NAME .. "_showStatsMenu",
    applySkillUsedHandlers = module.MOD_NAME .. "_applySkillUsedHandlers",
    updateRequest = module.MOD_NAME .. "_updateRequest",
    changeDecayRate = module.MOD_NAME .. "_changeDecayRate",
    onSkillLevelUp = module.MOD_NAME .. "_showSkillLevelUpMessage",
    -- Global
    skipGameHours = module.MOD_NAME .. "_skipGameHours",
}

module.renderers = {
    hotkey = module.MOD_NAME .. "_hotkey",
    number = module.MOD_NAME .. "_number",
    range = module.MOD_NAME .. "_range",
    decay_rate = module.MOD_NAME .. "_decay_rate",
    per_skill_uncapper = module.MOD_NAME .. "_per_skill_uncapper",
    per_attribute_uncapper = module.MOD_NAME .. "_per_attribute_uncapper",
}

module.mwscriptGlobalVars = {
    skipGameHours = module.MOD_NAME .. "_Skip_Game_Hours",
}

module.formulas = {
    getLogRangeFactor = function(value, min, max)
        return (min / 100) / ((min / max - 1) * (value / 100) ^ 2 + 1)
    end,
}

module.requestTypes = {
    softInit = "softInit",
    starterSpells = "starterSpells",
    startAttrsOnResume = "startAttrsOnResume",
    refreshStats = "refreshStats",
    refreshStatsOnResume = "refreshStatsOnResume",
    skillChange = "skillChange",
    health = "health",
}

module.skillTypes = { combat = "combat", magic = "magic", stealth = "stealth" }

local Skills = core.stats.Skill.records
module.skillsBySchool = {
    [module.skillTypes.combat] = { Skills.block.id, Skills.armorer.id, Skills.mediumarmor.id, Skills.heavyarmor.id, Skills.bluntweapon.id, Skills.longblade.id, Skills.axe.id, Skills.spear.id, Skills.athletics.id },
    [module.skillTypes.magic] = { Skills.enchant.id, Skills.destruction.id, Skills.alteration.id, Skills.illusion.id, Skills.conjuration.id, Skills.mysticism.id, Skills.restoration.id, Skills.alchemy.id, Skills.unarmored.id },
    [module.skillTypes.stealth] = { Skills.security.id, Skills.sneak.id, Skills.acrobatics.id, Skills.lightarmor.id, Skills.shortblade.id, Skills.marksman.id, Skills.mercantile.id, Skills.speechcraft.id, Skills.handtohand.id },
}

return module
