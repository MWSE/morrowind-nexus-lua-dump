local I = require("openmw.interfaces")

local mDef = require("scripts.MRF.config.definition")
local mStore = require("scripts.MRF.config.store")
local mDebug = require("scripts.MRF.util.debug")

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
    if showSpellMode ~= mStore.showSpellModes.Disabled then
        mDebug.uiModeChanged(data)
    end
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
    },
}