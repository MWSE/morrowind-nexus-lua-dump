local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local core = require('openmw.core')

local source = nil
local isChoosing = false
local playerSettings = storage.playerSection('SettingsPlayerTransmog')
local msgParams = {
    showInDialogue = false,
}

local function validateSubtypes(style)
    local sourceTemplate = nil
    local styleTemplate = nil
    if source.type == types.Armor then
       sourceTemplate = types.Armor.record(source)
        styleTemplate = types.Armor.record(style)
    elseif source.type == types.Weapon then
       sourceTemplate = types.Weapon.record(source)
        styleTemplate = types.Weapon.record(style)
    elseif source.type == types.Clothing then
       sourceTemplate = types.Clothing.record(source)
        styleTemplate = types.Clothing.record(style)
    else
        return true
    end
    return sourceTemplate.type == styleTemplate.type
end

local function onTransmogItemSelected(item)
    if isChoosing == false then
        return
    end
    if source == nil then
        source = item
        ui.showMessage('TRANSMOG: Pick up the style item.', msgParams)
    elseif source == item then
        -- For some reason, onActivated sometimes gets called twice?
        return
    elseif source.type ~= item.type then
        ui.showMessage(('TRANSMOG: Both items must be of same type. Source is %s, but style was %s. Canceling transmogrification.'):format(source.type, item.type), msgParams)
        isChoosing = false
        source = nil
    else
        if validateSubtypes(item) then
            core.sendGlobalEvent('transmog', { source = source, style = item })
        else
            ui.showMessage('TRANSMOG: Both items need to be of the same subtype (e.g. cuirass or one-handed axe). Canceling transmogrification.', msgParams)
        end
        isChoosing = false
        source = nil
    end
end

local function onTransmogCompleted()
    ui.showMessage('TRANSMOG: Completed.', msgParams)
end

local function onTransmogFailed(reason)
    ui.showMessage(('TRANSMOG: Failed because source item does not have %s, but the style item does.'):format(reason), msgParams)
end

local function onKeyPress(key)
    if not types.Player.isCharGenFinished(self) then
        return
    end
    if key.code == playerSettings:get('transmogMenuKey') then
        if isChoosing then
            ui.showMessage('TRANSMOG: Canceled item selection.')
            isChoosing = false
            source = nil
        else
            isChoosing = true
            ui.showMessage('TRANSMOG: Pick up the source item.', msgParams)
        end
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
    },
    eventHandlers = {
        transmogItemSelected = onTransmogItemSelected,
        transmogFailed = onTransmogFailed,
        transmogCompleted = onTransmogCompleted,
    }
}
