local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local core    = require("openmw.core")
local async   = require("openmw.async")

local section = storage.playerSection('SettingsNWNB')

local cachedSettings = {
    MOD_ENABLED   = true,
    DEBUG_ENABLED = false,
}

local function broadcastSettings()
    core.sendGlobalEvent("NWNB_SettingsUpdated", {
        MOD_ENABLED   = cachedSettings.MOD_ENABLED,
        DEBUG_ENABLED = cachedSettings.DEBUG_ENABLED,
    })
end

local function refreshCache()
    local mod   = section:get('MOD_ENABLED')
    local debug = section:get('DEBUG_ENABLED')
    if mod   ~= nil then cachedSettings.MOD_ENABLED   = mod   end
    if debug ~= nil then cachedSettings.DEBUG_ENABLED = debug end
    broadcastSettings()
end

section:subscribe(async:callback(function()
    refreshCache()
end))

local function BC_ShowMessage(message)
    ui.showMessage(message)
end

return {
    engineHandlers = {
        onInit = function()
            refreshCache()
        end,
        onLoad = function()
            refreshCache()
        end,
    },
    eventHandlers = {
        BC_ShowMessage = BC_ShowMessage,
    },
}