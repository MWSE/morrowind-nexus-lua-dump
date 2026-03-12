local core = require('openmw.core')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local playerSettings = storage.playerSection('SettingsPlayerDubiousConcoctions')

return {
    eventHandlers = {
        UiModeChanged = function(data)
            --print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
            if data.oldMode == "Dialogue" and not data.newMode then -- "Barter" then
                core.sendGlobalEvent('returnCheapPotion')
            elseif data.newMode == "Dialogue" and not data.oldMode and data.arg then
                core.sendGlobalEvent('removeCheapPotion', {
                    npc = data.arg,
                })
            elseif data.oldMode == "Dialogue" and data.newMode == "Barter" and  playerSettings:get('dcDialog') then
                core.sendGlobalEvent('merchantsRemark', {
                    npc = data.arg,
                })
            end
        end,
        dcShowMessage = function(data)
            ui.showMessage(data.message)
        end        
    }
}
