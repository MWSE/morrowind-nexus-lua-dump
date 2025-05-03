local nearby = require('openmw.nearby')
local self = require('openmw.self')

local function onDeath()
    for i, player in pairs(nearby.players) do
        player:sendEvent('EE_MLua_Kill', { actor = self })
    end
end

return {
    eventHandlers = { Died = onDeath }
}