local ambient = require('openmw.ambient')
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')


local currentContainer = nil
local currentBook = nil

-- Setup trigger and settings metadata:
input.registerTrigger {
    key = 'TakeAllTrigger',
    l10n = 'TakeAll',
}

I.Settings.registerPage {
    key = 'TakeAllKeyPage',
    l10n = 'TakeAll',
    name = 'Take All Key',
    description = 'Creates a keyboard shortcut to "Take All"',
}

I.Settings.registerGroup {
    key = 'SettingsTakeAll',
    page = 'TakeAllKeyPage',
    l10n = 'TakeAll',
    name = 'Key Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'ShortcutKey',
            renderer = 'inputBinding',
            name = 'Shortcut Key',
            description = 'Key to press to Take All.',
            default = 'x',
			argument = { key = "TakeAllTrigger", type = "trigger"}
        },
        {
            key = 'TakeBooks',
            renderer = 'checkbox',
            name = 'Take Books',
            description = 'Take all shortcut key also takes books.',
            default = true
        },
    },
}

local playerSettings = storage.playerSection('SettingsTakeAll')

-- Handlers for events and triggers:
function uiModeChanged(e)
	if e.newMode == I.UI.MODE.Container then
		currentContainer = e.arg
    elseif e.newMode == I.UI.MODE.Book then
        currentBook = e.arg
	elseif (e.newMode == nil) then
		currentContainer = nil
        currentBook = nil
	end
end

function takeAllKeyPressed()
	if currentContainer ~= nil then
        local containerInventory = types.Container.content(currentContainer)
        
        self.object:sendEvent("SetUiMode", {mode = nil})
        if #containerInventory:getAll() ~= 0 then
            core.sendGlobalEvent("takeAllEvent", {container=currentContainer, player = self.object})
            ambient.playSound("Item Misc Down")
        end

    elseif currentBook ~= nil and playerSettings:get("TakeBooks") then
        self.object:sendEvent("SetUiMode", {mode = nil})
        core.sendGlobalEvent("takeBook", {book = currentBook, player = self.object})
	end

end

-- Register handlers:
input.registerTriggerHandler('TakeAllTrigger', async:callback(takeAllKeyPressed))

return {
	eventHandlers = {
		UiModeChanged = uiModeChanged
	}
}