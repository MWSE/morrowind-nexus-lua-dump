local common = require("celediel.ASinkingFeeling.common")

local defaultConfig = {enabled = true, debug = false, playerOnly = false, downPullMultiplier = 100, mode = common.modes.equippedArmour}
local config = mwse.loadConfig(common.configString, defaultConfig)

return config