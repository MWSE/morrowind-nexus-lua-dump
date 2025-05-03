local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local setPauseMode = require('Scripts.CustomSpellBindings.pauseHandler').setPauseMode
local bindingTypeEnum = require('Scripts.CustomSpellBindings.bindingTypeEnum')
local KEY = require('openmw.input').KEY

local _window = nil
local _bindingCallback = nil

local function closeWindows()
    if _window ~= nil then
        _window:destroy()
        _window = nil
        _bindingCallback = nil
        setPauseMode(false)
    end
end

local function handleKeyPress(key)
    if _window == nil then
        return false
    end

    if key.code == KEY.Escape then
        return true
    end

    if _bindingCallback ~= nil then
        local selectedSpell = types.Actor.getSelectedSpell(self)
        if selectedSpell ~= nil then
            _bindingCallback(key, selectedSpell, bindingTypeEnum.Spell)
            closeWindows()
            return true
        end

        local selectedEnchantedItem = types.Actor.getSelectedEnchantedItem(self)
        if selectedEnchantedItem ~= nil then
            _bindingCallback(key, selectedEnchantedItem, bindingTypeEnum.EnchantedItem)
            closeWindows()
            return true
        end
    end
    
    closeWindows()
    return true
end

local function renderTextEntry(text)
    return {
        type = ui.TYPE.Container,
        content = ui.content({
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                props = {
                    autoSize = false,
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = text,
                            textSize = 16,
                            textColor = I.MWUI.templates.textNormal.props.textColor,
                            arrange = ui.ALIGNMENT.Center,
                        }
                    }
                })
            }
        })
    }
end

local function isWindowOpen()
    return _window ~= nil
end

local renderBindingWindow = function(bindingCallback)
    if types.Actor.getSelectedSpell(self) == nil and types.Actor.getSelectedEnchantedItem(self) == nil then
        ui.showMessage('You need to select a spell or an enchanted item first in order to create a custom hotkey')
        return
    end

    setPauseMode(true)

    _bindingCallback = bindingCallback

    _window = ui.create({
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                content = ui.content({renderTextEntry('Press a key to create a spell binding or ESC to cancel')}),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Start,
                }
            }
        })
    })
end

return {
    renderBindingWindow = renderBindingWindow,
    handleKeyPress = handleKeyPress,
    closeWindows = closeWindows,
    isWindowOpen = isWindowOpen,
}