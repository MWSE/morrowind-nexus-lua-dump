local common = require("celediel.MoreAttentiveGuards.common")
local this = {}

local currentConfig

this.default = {
    -- common
    language = "english",
    debug = false,
    -- sneak
    sneakEnable = true,
    sneakDialogue = common.dialogueMode.voice,
    sneakDialogueTimer = 5,
    sneakDialogueChance = 67,
    -- combat
    combatEnable = true,
    factionMembersHelp = true,
    factionMembersHelpRank = 1,
    combatDistance = 850,
    combatDialogue = common.dialogueMode.voice,
    ignored = {
        ["mer_tgw_guar"] = true,
        ["mer_tgw_guar_w"] = true
    },
    ignoredFactions = {}
}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configString, this.default)
    return currentConfig
end

return this
