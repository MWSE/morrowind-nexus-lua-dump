local storage = require('openmw.storage')
local UI = require('openmw.interfaces').UI

local setPauseMode = require('Scripts.CustomSpellBindings.pauseHandler').setPauseMode
local _spellWindow = require('Scripts.CustomSpellBindings.spellWindow')
local _bindingWindow = require('Scripts.CustomSpellBindings.bindingWindow')
local _hotkeyCollection = require('Scripts.CustomSpellBindings.hotkeyCollection')
local _playerSettings = storage.playerSection('CustomSpellHotkeysSection')

local function addSpellBindingCallback(key, spell, bindingType)
    _hotkeyCollection.addSpellBinding(key, spell, bindingType)
end

local function deleteSpellBindingCallback(hotkeyIndex)
    _hotkeyCollection.removeHotkeyByIndex(hotkeyIndex)
end

return {
    engineHandlers = {
        onKeyPress = function(key)
            if not _playerSettings:get('modEnabled') then
                return
            end
            
            if _spellWindow.handleKeyPress(key) then
                return
            end

            if _bindingWindow.handleKeyPress(key) then
                return
            end

            if UI.getMode() ~= nil then
                return
            end

            if key.code == _playerSettings:get('spellListKey') then
                _spellWindow.renderSpellWindow(_hotkeyCollection.getSpellhotkeys(), deleteSpellBindingCallback)
                return
            end

            if key.code == _playerSettings:get('setHotkeyKey') then
                _bindingWindow.renderBindingWindow(addSpellBindingCallback)
                return
            end
            
            _hotkeyCollection.selectSpellByKeycode(key.code)
        end,
        onSave = function()
            return { 
                spellHotkeys = _hotkeyCollection.getSpellhotkeys() 
            };
        end,
        onLoad = function(data)
            _hotkeyCollection.setSpellhotkeys(data.spellHotkeys)
        end
        
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == nil and (_spellWindow.isWindowOpen() or _bindingWindow.isWindowOpen()) then
                setPauseMode(false)
                _spellWindow.closeWindows()
                _bindingWindow.closeWindows()
            end
        end,
    },
}

