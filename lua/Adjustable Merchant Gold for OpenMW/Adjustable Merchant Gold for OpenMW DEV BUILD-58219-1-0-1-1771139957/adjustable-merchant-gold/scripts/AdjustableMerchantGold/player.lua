local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settings = require('scripts.AdjustableMerchantGold.settings')

-----------------------------------------------------------
-- Settings UI registration
-----------------------------------------------------------

I.Settings.registerPage(settings.page)
I.Settings.registerGroup(settings.group)

-----------------------------------------------------------
-- Sync multiplier to global script
-----------------------------------------------------------

local playerSettings = storage.playerSection(settings.SETTINGS_KEY)

local function syncMultiplier()
    core.sendGlobalEvent('AdjustableMerchantGold_SetMultiplier', {
        multiplier = settings.getMultiplier(),
    })
end

playerSettings:subscribe(async:callback(function(_, key)
    if key == 'GoldMultiplier' or key == nil then
        syncMultiplier()
    end
end))

return {
    engineHandlers = {
        onActive = function()
            syncMultiplier()
        end,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == 'Dialogue' and data.arg then
                -- Player started talking to an NPC; tell global to watch them
                -- so restocks are caught immediately by per-frame polling.
                core.sendGlobalEvent('AdjustableMerchantGold_WatchMerchant', {
                    actor = data.arg,
                })
            elseif data.newMode == nil then
                -- All UI closed; stop watching.
                core.sendGlobalEvent('AdjustableMerchantGold_UnwatchMerchant')
            end
        end,
    },
}
