local I = require("openmw.interfaces")
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local core = require('openmw.core')

local MODNAME = "QuickUnequip"
local playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
local TIMER_DELAY = 1.55 * time.second

-- =====================
-- STATE
-- =====================

local storedEquipment = nil
local wasSwimming = false

-- =====================
-- SETTINGS
-- =====================

settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = "Devilish Dress Undress Hotkey",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "Hotkey",
            name = "Keybinding Setup",
            description = "Click and choose a key",
            renderer = "inputBinding",
            default = "U",
            argument = {
                type = "action",
                key = "QUnequipAction",
            }
        },
        {
            key = "UNDRESS_WHEN_SWIMMING",
            name = "Undress when swimming",
            description = "Automatically undress when swimming",
            renderer = "checkbox",
            default = false
        },
        {
            key = "BLACKOUT",
            name = "Blackout effect",
            description = "Add blackout spell and delay when toggling equipment",
            renderer = "checkbox",
            default = false
        }
        
    }
}
I.Settings.registerGroup(settings)

local Actions = {
    {
        key = 'QUnequipAction',
        type = input.ACTION_TYPE.Boolean,
        l10n = "none",
        name = '',
        description = '',
        defaultValue = false,
    },
}

for _, action in ipairs(Actions) do
    input.registerAction(action)
end

-- =====================
-- EQUIPMENT TOGGLE
-- =====================

local function toggleEquipment(forceUndress)
    local eq = types.Actor.getEquipment(self)
    local equipmentPieces = 0
    for _ in pairs(eq) do
        equipmentPieces = equipmentPieces + 1
    end

    local shouldUndress
    if forceUndress ~= nil then
        shouldUndress = forceUndress
    elseif equipmentPieces > 3 then
        shouldUndress = true
    elseif storedEquipment then
        shouldUndress = false
    else
        shouldUndress = equipmentPieces > 0
    end

    if shouldUndress and equipmentPieces > 0 then
        storedEquipment = eq
        types.Actor.setEquipment(self, {})
    elseif not shouldUndress and storedEquipment then
        types.Actor.setEquipment(self, storedEquipment)
        storedEquipment = nil
    end
end

local delayedToggle = async:registerTimerCallback('DelayedToggle', function()
    toggleEquipment()
end)

local function hotkeyPressed(pressed)
    if I.UI.getMode() or core.isWorldPaused() then return end
    if not pressed then return end
    if playerSection:get("BLACKOUT") then
        types.Actor.spells(self):add('detd_blackoutnaked')
        time.newSimulationTimer(TIMER_DELAY, delayedToggle)
    else
        toggleEquipment()
    end
end

input.registerActionHandler('QUnequipAction', async:callback(hotkeyPressed))

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = "Devilish Dress & Undress Hotkey",
    description = ""
}

-- =====================
-- SWIMMING WATCHER
-- =====================

local function checkSwimming()
    if not playerSection:get("UNDRESS_WHEN_SWIMMING") then
        return
    end
    local swimming = types.Actor.isSwimming(self)
    if swimming ~= wasSwimming then
        toggleEquipment(swimming)
    end
    wasSwimming = swimming
end

time.runRepeatedly(checkSwimming, time.second)

return {}