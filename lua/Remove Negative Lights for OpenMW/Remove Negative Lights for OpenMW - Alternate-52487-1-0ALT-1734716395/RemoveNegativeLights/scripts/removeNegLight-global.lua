local core = require('openmw.core')
local types = require('openmw.types')

local darkname = 'dark_'

return {
    eventHandlers = {
        ['noDarkLights'] = function(e)
            player = e.player
            for _, object in ipairs(player.cell:getAll(types.Light)) do
                if string.match(types.Light.record(object).id,darkname) ~= nil then
                object.enabled = false
                end
            end
        end
    }
}