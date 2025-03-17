local core = require('openmw.core')

local module = {
    MOD_NAME = "NCGDMW",
    isOpenMW049 = core.API_REVISION >= 70
}

module.events = {
    applySkillUsedHandlers = "ncgd_applySkillUsedHandlers",
    updatePlayerStats = "ncgd_updatePlayerStats",
    updatePlayerStatsOnFrame = "ncgd_updatePlayerStatsOnFrame",
    updateProfileOnUpdate = "ncgd_updateProfileOnUpdate",
    showStatsMenu = "ncgd_showStatsMenu",
    refreshDecay = "ncgd_refreshDecay",
}

module.renderers = {
    hotkey = "NCGDMW_hotkey",
    number = "NCGDMW_number",
    per_skill_uncapper = "NCGDMW_per_skill_uncapper",
    per_attribute_uncapper = "NCGDMW_per_attribute_uncapper",
}

module.skillTypes = { combat = "combat", magic = "magic", stealth = "stealth" }

local Skills = core.stats.Skill.records
module.skillsBySchool = {
    [module.skillTypes.combat] = { Skills.block.id, Skills.armorer.id, Skills.mediumarmor.id, Skills.heavyarmor.id, Skills.bluntweapon.id, Skills.longblade.id, Skills.axe.id, Skills.spear.id, Skills.athletics.id },
    [module.skillTypes.magic] = { Skills.enchant.id, Skills.destruction.id, Skills.alteration.id, Skills.illusion.id, Skills.conjuration.id, Skills.mysticism.id, Skills.restoration.id, Skills.alchemy.id, Skills.unarmored.id },
    [module.skillTypes.stealth] = { Skills.security.id, Skills.sneak.id, Skills.acrobatics.id, Skills.lightarmor.id, Skills.shortblade.id, Skills.marksman.id, Skills.mercantile.id, Skills.speechcraft.id, Skills.handtohand.id },
}

return module
