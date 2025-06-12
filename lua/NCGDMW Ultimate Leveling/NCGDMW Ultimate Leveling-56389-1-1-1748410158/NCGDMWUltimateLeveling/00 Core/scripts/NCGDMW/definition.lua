local core = require('openmw.core')

local module = {
    MOD_NAME = "NCGDMW",
    isOpenMW049 = core.API_REVISION >= 70,
    interfaceVersion = 100.0,
    savedGameVersion = 100.1,
}

module.events = {
    applySkillUsedHandlers = "ncgd_applySkillUsedHandlers",
    updateGrowth = "ncgd_updateGrowth",
    updateGrowthAllAttrs = "ncgd_updateGrowthAllAttrs",
    updateGrowthAllAttrsOnResume = "ncgd_updateGrowthAllAttrsOnResume",
    updateStartAttrsOnResume = "ncgd_updateStartAttrsOnResume",
    showStatsMenu = "ncgd_showStatsMenu",
    refreshDecay = "ncgd_refreshDecay",
    skipGameHours = "ncgd_skipGameHours",
    playerReputation = "ncgd_reputation",
}

module.renderers = {
    hotkey = "NCGDMW_hotkey",
    number = "NCGDMW_number",
    logRange = "NCGDMW_range",
    per_skill_uncapper = "NCGDMW_per_skill_uncapper",
    per_attribute_uncapper = "NCGDMW_per_attribute_uncapper",
}

module.mwscriptGlobalVars = {
    skipGameHours = "NCGDMW_Skip_Game_Hours",
    playerReputation = "NCGDMW_Reputation",
}

module.formulas = {
    getLogRangeFactor = function(value, min, max)
        return (min / 100) / ((min / max - 1) * (value / 100) ^ 2 + 1)
    end,
}

module.skillTypes = { combat = "combat", magic = "magic", stealth = "stealth" }

local Skills = core.stats.Skill.records
module.skillsBySchool = {
    [module.skillTypes.combat] = { Skills.armorer.id, Skills.athletics.id, Skills.axe.id, Skills.block.id, Skills.bluntweapon.id, Skills.heavyarmor.id, Skills.longblade.id, Skills.mediumarmor.id, Skills.spear.id },
    [module.skillTypes.magic] = { Skills.alchemy.id, Skills.alteration.id, Skills.conjuration.id, Skills.destruction.id, Skills.enchant.id, Skills.illusion.id, Skills.mysticism.id, Skills.restoration.id, Skills.unarmored.id },
    [module.skillTypes.stealth] = { Skills.acrobatics.id, Skills.handtohand.id, Skills.lightarmor.id, Skills.marksman.id, Skills.mercantile.id, Skills.security.id, Skills.shortblade.id, Skills.sneak.id, Skills.speechcraft.id },
}

return module
