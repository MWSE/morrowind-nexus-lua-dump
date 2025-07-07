local core = require('openmw.core')

local module = {
    MOD_NAME = "NCGDMW",
    isOpenMW049 = core.API_REVISION >= 70,
    interfaceVersion = 4.3,
    savedGameVersion = 4.3,
}

module.events = {
    -- Player
    applySkillUsedHandlers = "ncgd_applySkillUsedHandlers",
    updateGrowth = "ncgd_updateGrowth",
    updateGrowthAllAttrs = "ncgd_updateGrowthAllAttrs",
    updateGrowthAllAttrsOnResume = "ncgd_updateGrowthAllAttrsOnResume",
    updateStartAttrsOnResume = "ncgd_updateStartAttrsOnResume",
    showStatsMenu = "ncgd_showStatsMenu",
    refreshDecay = "ncgd_refreshDecay",
    -- Global
    skipGameHours = "ncgd_skipGameHours",
}

module.renderers = {
    hotkey = "NCGDMW_hotkey",
    number = "NCGDMW_number",
    range = "NCGDMW_range",
    per_skill_uncapper = "NCGDMW_per_skill_uncapper",
    per_attribute_uncapper = "NCGDMW_per_attribute_uncapper",
}

module.mwscriptGlobalVars = {
    skipGameHours = "NCGDMW_Skip_Game_Hours",
}

module.formulas = {
    getLogRangeFactor = function(value, min, max)
        return (min / 100) / ((min / max - 1) * (value / 100) ^ 2 + 1)
    end,
}

module.skillTypes = { combat = "combat", magic = "magic", stealth = "stealth" }

local Skills = core.stats.Skill.records
module.skillsBySchool = {
    [module.skillTypes.combat] = { Skills.block.id, Skills.armorer.id, Skills.mediumarmor.id, Skills.heavyarmor.id, Skills.bluntweapon.id, Skills.longblade.id, Skills.axe.id, Skills.spear.id, Skills.athletics.id },
    [module.skillTypes.magic] = { Skills.enchant.id, Skills.destruction.id, Skills.alteration.id, Skills.illusion.id, Skills.conjuration.id, Skills.mysticism.id, Skills.restoration.id, Skills.alchemy.id, Skills.unarmored.id },
    [module.skillTypes.stealth] = { Skills.security.id, Skills.sneak.id, Skills.acrobatics.id, Skills.lightarmor.id, Skills.shortblade.id, Skills.marksman.id, Skills.mercantile.id, Skills.speechcraft.id, Skills.handtohand.id },
}

return module
