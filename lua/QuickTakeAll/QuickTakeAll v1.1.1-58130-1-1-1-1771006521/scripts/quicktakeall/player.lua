local core = require('openmw.core')
local self = require('openmw.self')
local input = require('openmw.input')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')

local l10n = core.l10n('QuickTakeAll')

-- Register the Take All trigger
input.registerTrigger({
    key = 'TakeAll',
    l10n = 'QuickTakeAll',
    name = 'TakeAll',
    description = 'TakeAll_description',
})

-- Register settings page
I.Settings.registerPage({
    key = 'QuickTakeAll',
    l10n = 'QuickTakeAll',
    name = 'SettingsPage',
    description = 'SettingsPageDesc',
})

-- Register settings group with input binding
I.Settings.registerGroup({
    key = 'SettingsQuickTakeAll',
    page = 'QuickTakeAll',
    l10n = 'QuickTakeAll',
    name = 'SettingsGroup',
    description = 'SettingsGroupDesc',
    permanentStorage = true,
    settings = {
        {
            key = 'TakeAllBinding',
            renderer = 'inputBinding',
            name = 'TakeAllKey',
            description = 'TakeAllKey_description',
            default = 'TakeAllBinding',
            argument = {
                key = 'TakeAll',
                type = 'trigger',
            },
        },
        {
            key = 'ShowValue',
            renderer = 'checkbox',
            name = 'ShowValue',
            description = 'ShowValue_description',
            default = true,
        },
        {
            key = 'ShowWeight',
            renderer = 'checkbox',
            name = 'ShowWeight',
            description = 'ShowWeight_description',
            default = true,
        },
        {
            key = 'DisposeCorpse',
            renderer = 'checkbox',
            name = 'DisposeCorpse',
            description = 'DisposeCorpse_description',
            default = false,
        },
    },
})

local settingsSection = storage.playerSection('SettingsQuickTakeAll')

-- Set default keybinding (R) if not already set
local bindingSection = storage.playerSection('OMWInputBindings')
local initialized = false

local function initDefaultBinding()
    if initialized then return end
    initialized = true

    if not bindingSection:get('TakeAllBinding') then
        bindingSection:set('TakeAllBinding', {
            device = 'keyboard',
            button = input.KEY.R,
            type = 'trigger',
            key = 'TakeAll',
        })
    end
end

-- Track the last activated container/corpse
local activeTarget = nil
local activeIsCorpse = false

local function takeAllFromTarget()
    if not activeTarget then
        return
    end

    if not activeTarget:isValid() then
        ui.showMessage(l10n('ContainerInvalid'))
        activeTarget = nil
        return
    end

    core.sendGlobalEvent('TakeAllRequest', {
        target = activeTarget,
        player = self.object,
        isCorpse = activeIsCorpse,
        disposeCorpse = activeIsCorpse and settingsSection:get('DisposeCorpse'),
    })

    activeTarget = nil
    activeIsCorpse = false
end

-- Register trigger handler
input.registerTriggerHandler('TakeAll', async:callback(function()
    takeAllFromTarget()
end))

local function onTakeAllResult(data)
    -- Always close the container UI first
    if I.UI and I.UI.setMode then
        I.UI.setMode()
    end

    -- Show appropriate message and play sound
    if data.count > 0 then
        local showValue = settingsSection:get('ShowValue')
        local showWeight = settingsSection:get('ShowWeight')
        local weight = string.format('%.1f', data.weight)

        local message
        if showValue and showWeight then
            message = l10n('TookItemsFull', { count = data.count, value = data.value, weight = weight })
        elseif showValue then
            message = l10n('TookItemsValue', { count = data.count, value = data.value })
        elseif showWeight then
            message = l10n('TookItemsWeight', { count = data.count, weight = weight })
        else
            message = l10n('TookItems', { count = data.count })
        end

        ui.showMessage(message)
        ambient.playSound('Item Misc Up')
    else
        ui.showMessage(l10n('ContainerEmpty'))
    end
end

local function onContainerActivated(data)
    activeTarget = data.object
    activeIsCorpse = data.isCorpse or false
end

local function onUiModeChanged(data)
    -- Clear active target when container/companion UI is closed
    local closedContainer = data.oldMode == 'Container' and data.newMode ~= 'Container'
    local closedCompanion = data.oldMode == 'Companion' and data.newMode ~= 'Companion'
    if closedContainer or closedCompanion then
        activeTarget = nil
        activeIsCorpse = false
    end
end

return {
    engineHandlers = {
        onFrame = function()
            initDefaultBinding()
        end,
    },
    eventHandlers = {
        ContainerActivated = onContainerActivated,
        TakeAllResult = onTakeAllResult,
        UiModeChanged = onUiModeChanged,
    },
}
