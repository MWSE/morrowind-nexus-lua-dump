local core = require('openmw.core')
local self = require('openmw.self')

local function Died()
    core.sendGlobalEvent('DiedCreature', self)
end

return {
    eventHandlers = {
        Died = Died
    }
}
