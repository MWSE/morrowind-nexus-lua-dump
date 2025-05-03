local util = require('openmw.util')
local ui = require('openmw.ui')
local KEY = require('openmw.input').KEY
local I = require('openmw.interfaces')
local async = require('openmw.async')
local setPauseMode = require('Scripts.CustomSpellBindings.pauseHandler').setPauseMode
local infoWindow = require('Scripts.CustomSpellBindings.infoWindow')

local _selectedHotkeyIndex = nil
local _spellHotkeys = nil
local _deleteSpellBindingCallback = nil
local _window = nil
local _baseIndex = 1
local _pageSize = 10

local renderSpellWindow = function(spellHotkeys, deleteSpellBindingCallback) end

local function closeWindows(preserveData)
    if _window ~= nil then
        _window:destroy()
        _window = nil
        infoWindow.closeWindow()
        if preserveData ~= true then
            _selectedHotkeyIndex = nil
            _baseIndex = 1
        end
    end
end

local function redrawSpellWindowWithSelectedHotkey()
    closeWindows(true)
    renderSpellWindow(_spellHotkeys, _deleteSpellBindingCallback)
end

local function mouseClick(event, item)
    _selectedHotkeyIndex = item.props.index
    redrawSpellWindowWithSelectedHotkey()
end

local function renderTextEntry(text, index, spellHotkey, isSelected)
    local textColor

    if isSelected then
        textColor = util.color.rgb(255, 0, 0)
    else
        textColor = I.MWUI.templates.textNormal.props.textColor
    end

    return {
        type = ui.TYPE.Container,
        content = ui.content({
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                events = {
                    mousePress = async:callback(mouseClick),
                },
                props = {
                    index = index,
                    autoSize = false,
                    spellHotkey = spellHotkey
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = text,
                            textSize = 16,
                            textColor = textColor,
                            arrange = ui.ALIGNMENT.Center,
                        }
                    }
                })
            }
        })
    }
end


local  function renderSpellItem(spellHotkey, index)
    local itemText = string.format('Key "%s" bound to spell "%s"', spellHotkey.keySymbol, spellHotkey.spellName);
    local isSelected = index == _selectedHotkeyIndex

    return renderTextEntry(itemText, index, spellHotkey, isSelected)
end

renderSpellWindow = function(spellHotkeys, deleteSpellBindingCallback)
    if spellHotkeys[1] == nil then
        ui.showMessage('No custom spell bindings have been defined')
        return
    end

    _spellHotkeys = spellHotkeys
    _deleteSpellBindingCallback = deleteSpellBindingCallback
    setPauseMode(true)

    local content = {}

    if _selectedHotkeyIndex ~= nil and _selectedHotkeyIndex > #_spellHotkeys then
        _selectedHotkeyIndex = #spellHotkeys
    end

    for i=_baseIndex, _pageSize + _baseIndex - 1 do
        if i > #_spellHotkeys then
            break
        end
        table.insert(content, renderSpellItem(_spellHotkeys[i], i))
    end

    if _selectedHotkeyIndex == nil then
        table.insert(content, renderTextEntry(string.format('No hotkey selected. Avaialable hotkeys: %d', #_spellHotkeys)))
    else
        table.insert(content, renderTextEntry(string.format('Selected hotkey %d out of %d', _selectedHotkeyIndex, #_spellHotkeys)))
    end

    closeWindows()

    _window = ui.create({
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
            spellHotkeys = spellHotkeys,
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    size = util.vector2(400, 100),
                    vertical = true,
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Start,
                }
            }
        })
    })

    infoWindow.renderInfoWindow()
end

local function selectPreviousSpell()
    if _spellHotkeys == nil or #_spellHotkeys == 0 then 
        return
    end

    if _selectedHotkeyIndex == nil then
        _selectedHotkeyIndex = 1
    elseif _selectedHotkeyIndex == 1 then
        _selectedHotkeyIndex = #_spellHotkeys
        if _selectedHotkeyIndex > _pageSize then
            _baseIndex = _selectedHotkeyIndex - _pageSize + 1
        end
        redrawSpellWindowWithSelectedHotkey()
        return
    else
        _selectedHotkeyIndex = _selectedHotkeyIndex - 1
    end

    if _baseIndex > _selectedHotkeyIndex then
        _baseIndex = _baseIndex - 1
    end

    redrawSpellWindowWithSelectedHotkey()
end

local function selectNextSpell()
    local spellHotkeyCount = #_spellHotkeys
    if _spellHotkeys == nil or spellHotkeyCount == 0 then 
        return 
    end

    if _selectedHotkeyIndex == spellHotkeyCount then
        _selectedHotkeyIndex = 1
        _baseIndex = 1
        redrawSpellWindowWithSelectedHotkey()
        return
    end

    if _selectedHotkeyIndex == nil then
        _selectedHotkeyIndex = 1
    else
        _selectedHotkeyIndex = _selectedHotkeyIndex + 1
    end

    if (_baseIndex + _pageSize) <= _selectedHotkeyIndex then
        _baseIndex = _baseIndex + 1
    end

    redrawSpellWindowWithSelectedHotkey()
end

local function isWindowOpen() 
    return _window ~= nil
end

local function handleKeyPress(key)
    if isWindowOpen() then
        if key.code == KEY.Delete and _selectedHotkeyIndex ~= nil then
            if _deleteSpellBindingCallback ~= nil then
                _deleteSpellBindingCallback(_selectedHotkeyIndex)
                redrawSpellWindowWithSelectedHotkey()
            end
            return true
        end

        if key.code == KEY.UpArrow or key.code == KEY.W then
            selectPreviousSpell()
            return true
        end

        if key.code == KEY.DownArrow or key.code == KEY.S then
            selectNextSpell()
            return true
        end
        return true
    end

    return false
end

return {
    renderSpellWindow = renderSpellWindow,
    closeWindows = closeWindows,
    handleKeyPress = handleKeyPress,
    isWindowOpen = isWindowOpen
}