local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')

I.Settings.registerPage {
    key = 'PickpocketEquippedPage',
    l10n = 'PickpocketEquipped',
    name = 'Pickpocket Settings',
    description = 'Settings for the Pickpocket Mod',
}

I.Settings.registerGroup {
    key = 'SettingsGlobalPickpocket',
    page = 'PickpocketEquippedPage',
    l10n = 'PickpocketEquipped',
    name = 'Vendor Inventory Options',
    permanentStorage = true,
    settings = {
        {
            key = 'EnableVendorPickpocketing',
            renderer = 'checkbox',
            name = 'Pickpocket Vendor Chests',
            description = 'Allows you to secretly access a merchant\'s shop inventory directly from their pockets.',
            default = false,
        },
    },
}

local storage = require('openmw.storage')
local modSettings = storage.playerSection('SettingsGlobalPickpocket')

local function syncSettings()
    local enable = modSettings:get('EnableVendorPickpocketing')
    if enable == nil then enable = false end
    
    core.sendGlobalEvent('UpdatePickpocketSettings', { 
        EnableVendorPickpocketing = enable
    })
end

local async = require('openmw.async')
modSettings:subscribe(async:callback(function(section, key)
    syncSettings()
end))

local isSneaking = false
local monitoringPhase = 0 -- 0: idle, 1: waiting for UI to open, 2: waiting for UI to close
local firstLoadSyncDone = false

local function onUpdate(dt)
    if not firstLoadSyncDone then
        syncSettings()
        firstLoadSyncDone = true
    end


    if self.controls then
        if self.controls.sneak ~= isSneaking then
            isSneaking = self.controls.sneak
            core.sendGlobalEvent('PlayerSneakStateChanged', { sneaking = isSneaking })
        end
    end

    if monitoringPhase == 1 then
        if I.UI.getMode() ~= nil then
            monitoringPhase = 2
        end
    elseif monitoringPhase == 2 then
        if I.UI.getMode() == nil then
            monitoringPhase = 0
            core.sendGlobalEvent('PickpocketWindowClosed')
        end
    end
end

local function StartMonitoringPickpocket()
    monitoringPhase = 1
end

local function ShowMessage(msg)
    local ui = require('openmw.ui')
    ui.showMessage(msg)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        StartMonitoringPickpocket = StartMonitoringPickpocket,
        ShowMessage = ShowMessage
    }
}
