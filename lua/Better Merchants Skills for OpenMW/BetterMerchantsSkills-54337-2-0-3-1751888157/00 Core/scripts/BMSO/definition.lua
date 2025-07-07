local core = require('openmw.core')
local util = require('openmw.util')

local module = {
    MOD_NAME = "BMSO",
    -- 44 for UiModeChanged
    isLuaApiRecentEnough = core.API_REVISION >= 44,
    isOpenMW049 = core.API_REVISION > 29,
    minSkill = 20,
}

module.baseSkill = function(npcLevel)
    return math.min(100, npcLevel * 4 + module.minSkill)
end

module.difficultyPercent = function(setting, playerLevel)
    return util.round(setting.from + (math.min(setting.maxLvl, playerLevel) - 1) * (setting.to - setting.from) / (setting.maxLvl - 1))
end

module.events = {
    -- GLobal
    updateSettings = "bmso_updateSettings",
    -- Player
    modStats = "bmso_modStats",
    -- NPCs
    handleStats = "bmso_handleStats",
}

module.renderers = {
    number = "bmso_number",
    scalingPercent = "bmso_scalingPercent",
}

return module
