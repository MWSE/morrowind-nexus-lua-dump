local common = require("celediel.MoreAttentiveGuards.common")
local this = {}

local currentConfig

this.default = {
    -- common
    language = "english",
    debug = false,
    -- sneak
    sneakEnable = true,
    sneakDialogue = true,
    sneakDialogueTimer = 5,
    sneakDialogueChance = 67,
    -- combat
    combatEnable = true,
    combatDistance = 850,
    combatDialogue = true,
    ignored = {
        ["mer_tgw_guar"] = true,
        ["mer_tgw_guar_w"] = true
    }
}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configString, this.default)
    return currentConfig
end

return this
