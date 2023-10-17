local core = require('openmw.core')
if not core.contentFiles.has(require("scripts.an_unexpected_start.modData").addonFileName) then
    return
end

local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local self = require('openmw.self')

local settings = require("scripts.an_unexpected_start.settings")
core.sendGlobalEvent("usbd_loadConfig", {config = storage.playerSection(settings.storageName):asTable()})

local function usbd_enableControls(data)
    if data.control and data.value then
        local key
        if data.control == "Controls" then
            key = input.CONTROL_SWITCH.Controls
        elseif data.control == "Fighting" then
            key = input.CONTROL_SWITCH.Fighting
        elseif data.control == "Jumping" then
            key = input.CONTROL_SWITCH.Jumping
        elseif data.control == "Looking" then
            key = input.CONTROL_SWITCH.Looking
        elseif data.control == "Magic" then
            key = input.CONTROL_SWITCH.Magic
        elseif data.control == "VanityMode" then
            key = input.CONTROL_SWITCH.VanityMode
        elseif data.control == "ViewMode" then
            key = input.CONTROL_SWITCH.ViewMode
        end
        if not key then return end
        input.setControlSwitch(key, data.value)
    end
end

local function usbd_showMessage(params)
    if params.message then
        ui.showMessage(params.message)
    end
end

return {
    eventHandlers = {
        usbd_enableControls = async:callback(usbd_enableControls),
        usbd_showMessage = async:callback(usbd_showMessage),
    },
}