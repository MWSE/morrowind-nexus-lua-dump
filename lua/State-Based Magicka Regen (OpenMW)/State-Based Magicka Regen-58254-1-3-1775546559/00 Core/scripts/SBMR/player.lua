local core = require("openmw.core")
local I = require("openmw.interfaces")

local mDef = require("scripts.SBMR.config.definition")
local mStore = require("scripts.SBMR.config.store")
local mActors = require("scripts.SBMR.util.actors")
local mStats = require("scripts.SBMR.util.stats")
local mH = require("scripts.SBMR.util.helpers")
local log = require("scripts.SBMR.util.log")

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local L = core.l10n(mDef.MOD_NAME)

local function getSettingArguments()
    local arguments = {}

    local setting = mStore.settings.playerMainStatRegenPerMinPercent
    local baseRegen = mActors.getBaseRegen(setting.value)
    local finalRegen = baseRegen * mActors.getRegenFactor()
    setting.argument.notes = {
        L("playerBaseRegenPerMin", { value = mH.round(baseRegen, 1) }),
        L("playerFinalRegenPerMin", { value = mH.round(finalRegen, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.timescaleForLongPeriodsOfTimePassed
    local regenForLongTimePassed = finalRegen * 60 / mStore.settings.timescaleForLongPeriodsOfTimePassed.value
    setting.argument.notes = {
        L("playerFinalRegenForPeriods", { value = mH.round(regenForLongTimePassed, 1) }),
        L("playerFinalRegenForPeriodsInABed", { value = mH.round(regenForLongTimePassed * mStore.settings.restInBedRegenPercent.value / 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.willpowerRegenImpactPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getWillpowerFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.intelligenceRegenImpactPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getIntelligenceFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.fatigueRegenImpactPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getFatigueFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.encumbranceRegenImpactPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getEncumbranceFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.regeneratingActorsRegenPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getRegeneratingActorsFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    setting = mStore.settings.stuntedMagickaRegenPercent
    setting.argument.notes = {
        L("currentPlayerFactor", { value = mH.round(mActors.getStuntedMagickaFactor() * 100, 1) }),
    }
    arguments[setting.key] = setting.argument

    return arguments
end

local function updateSettingArguments()
    core.sendGlobalEvent(mDef.events.updateArguments, getSettingArguments())
end

local function uiModeChanged(data)
    log(string.format('UI mode changed from %s to %s, arg is %s', data.oldMode, data.newMode, data.arg))
    if data.newMode == "MainMenu" then
        updateSettingArguments()
    end
end

local function onActive()
    if I.StatsWindow then
        mStats.setStatsWindow()
    end
end

mStore.addTrackerCallback(function(_, _)
    updateSettingArguments()
end)

updateSettingArguments()

return {
    engineHandlers = {
        onActive = onActive,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [mDef.events.setCurrPlayerRegen] = mStats.setCurrPlayerRegen,
    },
}