local time = require('openmw_aux.time')
local core = require('openmw.core')
local self = require('openmw.self')

local function getDaysPassed()
    local daysPassed = math.floor(core.getGameTime() / time.day)
    self.object:sendEvent('daysPassed', { days = daysPassed } )
end

return {
    engineHandlers = {
        onUpdate = getDaysPassed
    }
}