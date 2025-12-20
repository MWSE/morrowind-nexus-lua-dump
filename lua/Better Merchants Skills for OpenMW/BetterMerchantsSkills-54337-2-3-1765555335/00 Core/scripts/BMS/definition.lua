local core = require('openmw.core')
local util = require('openmw.util')

local module = {
    MOD_NAME = "BMS",
    -- 44 for UiModeChanged
    isLuaApiRecentEnough = core.API_REVISION >= 44,
    isOpenMW049 = core.API_REVISION > 29,
    minSkill = 20,
    saveVersion = 1.0,
}

module.baseSkill = function(npcLevel)
    return math.min(100, npcLevel * 4 + module.minSkill)
end

module.difficultyPercent = function(setting, playerLevel)
    return util.round(setting.from + (math.min(setting.maxLvl, playerLevel) - 1) * (setting.to - setting.from) / (setting.maxLvl - 1))
end

module.events = {
    -- GLobal
    updateSettings = module.MOD_NAME .. "_updateSettings",
    -- Player
    notify = module.MOD_NAME .. "_notify",
    modPcStats = module.MOD_NAME .. "_modPcStats",
    -- NPCs
    modStats = module.MOD_NAME .. "_modStats",
    modDisp = module.MOD_NAME .. "_modDisp",
}

module.renderers = {
    number = module.MOD_NAME .. "_number",
    scalingPercent = module.MOD_NAME .. "_scalingPercent",
    dispScaling = module.MOD_NAME .. "_dispScaling",
}

return module
