local core    = require("openmw.core")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local ui      = require("openmw.ui")
local shared  = require("scripts.Rilms_shared")

local DEFAULTS = shared.DEFAULTS
local section  = storage.playerSection("SettingsRilms")
local state    = storage.playerSection("RilmsState")

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local function broadcastSettings()
    core.sendGlobalEvent("Rilms_SettingsUpdated", {
        DONATE_CHANCE = get("DONATE_CHANCE"),
        MAX_DONATIONS = get("MAX_DONATIONS"),
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
            local donationCounts = state:get("donationCounts")
            if donationCounts ~= nil then
                local plain = {}
                for k, v in pairs(donationCounts) do
                    plain[k] = v
                end
                core.sendGlobalEvent("RilmsRestoreState", { donationCounts = plain })
end
        end,
    },
    eventHandlers = {
        RilmsMessage = function(data)
            if data and data.message then
                ui.showMessage(data.message)
            end
        end,
        RilmsSaveState = function(data)
            if data and data.donationCounts then
                state:set("donationCounts", data.donationCounts)
            end
        end,
    },
}