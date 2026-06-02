local core = require("openmw.core")
local interfaces = require("openmw.interfaces")
local types = require("openmw.types")
local world = require("openmw.world")

local config = require("scripts.sptLimits.shared.config")
local exclusions = require("scripts.sptLimits.shared.exclusions")
local L = core.l10n("sptLimits")

local mwscriptGlobals = world.mwscript.getGlobalVariables()

local excludedPotions = exclusions.excludedPotions
local isPotionExcluded = exclusions.isPotionExcluded

local settingsCache = {
    potionLimitEnabled = config.potionLimitEnabled,
    statLimitEnabled = config.statLimitEnabled,
    excludeSunsDusk = config.excludeSunsDusk,
}

local playerState = {
    knockedOut = false,
    drinkOverdose = false,
    allNormalSlotsFull = false,
    potionTrackingMode = "counter",
}

interfaces.ItemUsage.addHandlerForType(types.Potion, function(potion, player)
    if not settingsCache.potionLimitEnabled then
        return nil
    end
    if not types.Player.objectIsInstance(player) then
        return nil
    end

    local potionRecord = types.Potion.record(potion)
    if potionRecord and isPotionExcluded(potionRecord.id, settingsCache.excludeSunsDusk) then
        return nil
    end

    if playerState.potionTrackingMode == "slots" then
        if playerState.knockedOut then
            player:sendEvent("sptLimitsShowMessage", { text = L("cantDrinkNow") })
            return false
        end
        if playerState.allNormalSlotsFull then
            player:sendEvent("sptLimitsShowMessage", { text = L("cantDrinkMore") })
            return false
        end
        return nil
    end

    if playerState.knockedOut then
        if playerState.drinkOverdose then
            player:sendEvent("sptLimitsShowMessage", { text = L("cantDrinkNow") })
            return false
        end
        return nil
    end

    if playerState.drinkOverdose then
        player:sendEvent("sptLimitsShowMessage", { text = L("cantDrinkMore") })
        return false
    end

    return nil
end)

interfaces.ItemUsage.addHandlerForType(types.Apparatus, function(apparatus, player)
    if not settingsCache.statLimitEnabled and not settingsCache.potionLimitEnabled then
        return nil
    end
    if not types.Player.objectIsInstance(player) then
        return nil
    end

    if playerState.knockedOut then
        player:sendEvent("sptLimitsShowMessage", { text = L("cantUseNow") })
        return false
    end

    return nil
end)

interfaces.ItemUsage.addHandlerForType(types.Repair, function(repair, player)
    if not settingsCache.statLimitEnabled and not settingsCache.potionLimitEnabled then
        return nil
    end
    if not types.Player.objectIsInstance(player) then
        return nil
    end

    if playerState.knockedOut then
        player:sendEvent("sptLimitsShowMessage", { text = L("cantUseNow") })
        return false
    end

    return nil
end)

interfaces.ItemUsage.addHandlerForType(types.Miscellaneous, function(miscellaneous, player)
    if not settingsCache.statLimitEnabled and not settingsCache.potionLimitEnabled then
        return nil
    end
    if not types.Player.objectIsInstance(player) then
        return nil
    end

    if playerState.knockedOut then
        player:sendEvent("sptLimitsShowMessage", { text = L("cantUseNow") })
        return false
    end

    return nil
end)

return {
    eventHandlers = {
        sptLimitsStateUpdate = function(data)
            if data then
                playerState.knockedOut = data.knockedOut or false
                playerState.drinkOverdose = data.drinkOverdose or false
                playerState.allNormalSlotsFull = data.allNormalSlotsFull or false
                playerState.potionTrackingMode = data.potionTrackingMode or "counter"
            end
        end,
        sptLimitsSettingsUpdate = function(data)
            if data then
                settingsCache.potionLimitEnabled = data.potionLimitEnabled
                settingsCache.statLimitEnabled = data.statLimitEnabled
                settingsCache.excludeSunsDusk = data.excludeSunsDusk
            end
        end,
        sptLimitsExcludePotion = function(data)
            if data and data.recordId then
                excludedPotions[data.recordId] = true
            end
        end,
        sptLimitsIncludePotion = function(data)
            if data and data.recordId then
                excludedPotions[data.recordId] = nil
            end
        end,
        sptLimitsTrainBlock = function(data)
            if data then
                mwscriptGlobals.sptTrainBlocked = data.blocked and 1 or 0
            end
        end,
    },
}
