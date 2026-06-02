local core = require('openmw.core')

local module = {
    MOD_NAME = "UltimateLeveling",
    isOpenMW049 = core.API_REVISION >= 70,
    interfaceVersion = 2.0,
    savedGameVersion = 2.0,
}

module.events = {
    init = "UltimateLeveling_init",
    updateStartSkills = "UltimateLeveling_updateStartSkills",
    updateStartAttrs = "UltimateLeveling_updateStartAttrs",
    updateStartStats = "UltimateLeveling_updateStartStats",
    updateSkillGrowth = "UltimateLeveling_updateSkillGrowth",
    updateReputation = "UltimateLeveling_updateReputation",
    updateStats = "UltimateLeveling_updateStats",
    updateAttributes = "UltimateLeveling_updateAttributes",
    updateLevel = "UltimateLeveling_updateLevel",
    updateHealth = "UltimateLeveling_updateHealth",
    updateStatsExtMod = "UltimateLeveling_updateStatsExtMod",
    --updatePerSkillRenderer = "UltimateLeveling_updatePerSkillRenderer",
    showStatsMenu = "UltimateLeveling_showStatsMenu",
}

module.renderers = {
    hotkey = "UltimateLeveling_hotkey",
    number = "UltimateLeveling_number",
    per_skill_uncapper = "UltimateLeveling_per_skill_uncapper",
    per_attribute_uncapper = "UltimateLeveling_per_attribute_uncapper",
}

module.mwscriptGlobalVars = {
    playerReputation = "UltimateLeveling_Reputation",
}

return module
