local core = require('openmw.core')
local storage = require('openmw.storage')

local playerSettings = storage.playerSection('SettingsPlayerDubiousConcoctions')

return {
    eventHandlers = {
        UiModeChanged = function(data)
            --print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
            if data.oldMode == "Dialogue" and not data.newMode then -- "Barter" then
                core.sendGlobalEvent('returnCheapPotion')
                --print("return")
            elseif data.newMode == "Dialogue" and not data.oldMode and data.arg then
                core.sendGlobalEvent('removeCheapPotion', {
                    npc = data.arg,
                    -- strictPotion = playerSettings:get('dcStricterConditionsPotion'),
                    -- strictPoison = playerSettings:get('dcStricterConditionsPoison')
                })
                --print("remove")
            end
        end
    }
}
