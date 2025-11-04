local core = require('openmw.core')
local self = require('openmw.self')

local function Died()
    core.sendGlobalEvent('processDiedCreature', self)
end

return {
    eventHandlers = {
        Died = Died
    }
}
