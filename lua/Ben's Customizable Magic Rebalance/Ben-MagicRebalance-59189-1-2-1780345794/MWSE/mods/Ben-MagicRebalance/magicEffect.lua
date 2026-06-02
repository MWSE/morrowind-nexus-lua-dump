local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local function logExcludedFromRebalance(magicEffect, reason)

    common.log("  Excluded From Rebalance: %s", reason)

    common.log("  Base Magicka Cost: %.2f", magicEffect.baseMagickaCost)
    common.log("  Allow Spellmaking: %s", magicEffect.allowSpellmaking)
    common.log("  Allow Enchanting: %s", magicEffect.allowEnchanting)

end

local function rebalanceMagicEffect(magicEffect)

    -- https://mwse.github.io/MWSE/types/tes3magicEffect/

    common.log("Magic Effect ID: %s | Name: %s", magicEffect.id, magicEffect.name)
    common.log("  Source Mod: %s", magicEffect.sourceMod or "nil")

    --------------------------------------------------

    if gameConfig.shared.excludedEffectIds[magicEffect.id] then
        logExcludedFromRebalance(magicEffect, "In \"Excluded Effects\" List")
        return
    end

    local effectConfig = common.getEffectConfig(magicEffect.id)

    if effectConfig.baseMagickaCost == 0 then
        logExcludedFromRebalance(magicEffect, "Base Magicka Cost is Zero")
        return
    end

    common.log("  Included In Rebalance")

    --------------------------------------------------

    local baseMagickaCost = effectConfig.baseMagickaCost
    local allowSpellmaking = gameConfig.magicEffect.noSpellmakingEffectIds[magicEffect.id] ~= true
    local allowEnchanting = gameConfig.magicEffect.noEnchantingEffectIds[magicEffect.id] ~= true

    --------------------------------------------------

    common.log("  Base Magicka Cost: %.2f -> %.2f", magicEffect.baseMagickaCost, baseMagickaCost)
    common.log("  Allow Spellmaking: %s -> %s", magicEffect.allowSpellmaking, allowSpellmaking)
    common.log("  Allow Enchanting: %s -> %s", magicEffect.allowEnchanting, allowEnchanting)

    --------------------------------------------------

    magicEffect.baseMagickaCost = baseMagickaCost
    magicEffect.allowSpellmaking = allowSpellmaking
    magicEffect.allowEnchanting = allowEnchanting

end

local this = {}

this.onLoaded = function(e)

    if not gameConfig.magicEffect.rebalanceEnabled then return end
    if not gameConfigUpdated.magicEffect then return end
    gameConfigUpdated.magicEffect = false

    common.log("--------------------------------------------------")
    common.log("Magic Effect GMSTs")
    common.log("--------------------------------------------------")

    common.setGmsts(gameConfig.magicEffect.gameSettings)

    common.log("--------------------------------------------------")
    common.log("Magic Effect Rebalance")
    common.log("--------------------------------------------------")

    for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        rebalanceMagicEffect(magicEffect)
    end

end

return this
