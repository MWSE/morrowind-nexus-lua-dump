local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")

local mDef = require("scripts.MRF.config.definition")
local mStore = require("scripts.MRF.config.store")
local mDebug = require("scripts.MRF.util.debug")
local mH = require("scripts.MRF.util.helpers")
local log = require("scripts.MRF.util.log")

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local showSpellMode = mStore.showSpellModes.Disabled

local function onFrame(deltaTime)
    if showSpellMode ~= mStore.showSpellModes.Disabled then
        mDebug.checkActorSpells(deltaTime, showSpellMode)
    end
end

local function uiModeChanged(data)
    if mStore.settings.magicEffectDurationForPausedDialogue.get() then
        core.sendGlobalEvent(mDef.events.onUiChanged, { uiMode = data.newMode, player = self, target = data.arg })
    end
    if showSpellMode ~= mStore.showSpellModes.Disabled then
        mDebug.uiModeChanged(data)
    end
end

local function refreshUiMode(uiMode, target)
    log(string.format("Refreshing UI mode %s for target %s", uiMode, mH.objectId(target)))
    I.UI.removeMode(uiMode)
    I.UI.addMode(uiMode, { target = target })
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        hideSpells = function() showSpellMode = mStore.showSpellModes.Disabled end,
        showKnownSpells = function() showSpellMode = mStore.showSpellModes.Known end,
        showActiveSpells = function() showSpellMode = mStore.showSpellModes.Active end,
    },
    engineHandlers = {
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [mDef.events.refreshUiMode] = function(data) refreshUiMode(data.uiMode, data.target) end,
    },
}