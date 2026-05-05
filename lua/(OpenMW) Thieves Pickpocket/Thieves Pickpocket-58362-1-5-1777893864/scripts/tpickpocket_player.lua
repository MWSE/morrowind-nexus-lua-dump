local core    = require("openmw.core")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local ui      = require("openmw.ui")

local shared   = require("scripts.tshared")
local DEFAULTS = shared.DEFAULTS

local section = storage.playerSection("SettingsTP")

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local function broadcastSettings()
    core.sendGlobalEvent("TP_SettingsUpdated", {
        MOD_ENABLED     = get("MOD_ENABLED"),
        STEAL_RADIUS  = get("STEAL_RADIUS"),
        STEAL_CHANCE  = get("STEAL_CHANCE"),
        MIN_GOLD      = get("MIN_GOLD"),
        MAX_GOLD      = get("MAX_GOLD"),
        AGILITY_MIN   = get("AGILITY_MIN"),
        SNEAK_MIN     = get("SNEAK_MIN"),
        SCAN_INTERVAL = get("SCAN_INTERVAL"),
        USE_DISPOSITION = get("USE_DISPOSITION"),
        MAX_DISPOSITION = get("MAX_DISPOSITION"),
        PLAY_SOUND      = get("PLAY_SOUND"),
        SHOW_MESSAGE    = get("SHOW_MESSAGE"),
        STEAL_ITEMS     = get("STEAL_ITEMS"),
        RETALIATION_ENABLED = get("RETALIATION_ENABLED"),
        RETALIATION_WINDOW  = get("RETALIATION_WINDOW"),
        RETALIATION_RADIUS  = get("RETALIATION_RADIUS"),
        RETALIATION_STANDOFF = get("RETALIATION_STANDOFF"),
        RETALIATION_LEVEL_DIFF = get("RETALIATION_LEVEL_DIFF"),
    })
end

section:subscribe(async:callback(function()
    broadcastSettings()
end))

return {
engineHandlers = {
    onInit = function()
        broadcastSettings()
    end,
    onLoad = function()
        broadcastSettings()
    end,
},
    eventHandlers = {
        PickpocketMessage = function(data)
            if data and data.message then
                ui.showMessage(data.message)
            end
        end,
    },
}