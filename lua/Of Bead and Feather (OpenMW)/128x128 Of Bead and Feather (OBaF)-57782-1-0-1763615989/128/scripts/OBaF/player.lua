local core = require('openmw.core')
local storage = require('openmw.storage')
local playerSettings = storage.playerSection('SettingsPlayerOBaF')

return {
    eventHandlers = {
        UiModeChanged = function(data)
            -- print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
            if data.oldMode == "Alchemy" then
                local variant = playerSettings:get('obafVariant') == "variant1" and 1 or
                                    playerSettings:get('obafVariant') == "variant3" and 3 or 2

                core.sendGlobalEvent('checkNewPotions', {
                    variant = variant,
                    changePrice = playerSettings:get('obafChangePrice'),
                    cache = playerSettings:get('obafCache'),
                    replace = playerSettings:get('obafReplaceName')
                })
            end
        end
    }
}
