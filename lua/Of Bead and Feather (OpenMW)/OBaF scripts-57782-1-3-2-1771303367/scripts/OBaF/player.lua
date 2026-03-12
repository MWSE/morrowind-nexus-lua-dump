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

                local cache = playerSettings:get('obafCache') ~= "stack3"
                local replaceWeight = playerSettings:get('obafCache') == "stack2"

                core.sendGlobalEvent('checkNewPotions', {
                    variant = variant,
                    changePrice = playerSettings:get('obafChangePrice'),
                    replace = playerSettings:get('obafReplaceName'),
                    cache = cache,
                    replaceWeight = replaceWeight
                })
            end
        end
    }
}
