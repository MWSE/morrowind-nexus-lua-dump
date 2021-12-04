local core = require('openmw.core')
if core.API_REVISION < 5 then
    error('This mod requires a newer version of OpenMW, please update.')
end

return {
    engineHandlers = {
        onPlayerAdded = function(player)
            player:addScript('fastexit/main.lua')
        end,
    },
}
