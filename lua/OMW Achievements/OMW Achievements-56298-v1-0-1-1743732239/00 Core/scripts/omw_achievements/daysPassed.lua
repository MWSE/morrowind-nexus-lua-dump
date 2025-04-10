local time = require('openmw_aux.time')
local core = require('openmw.core')
local self = require('openmw.self')

local function getDaysPassed()
    local daysPassed = math.floor(core.getGameTime() / time.day)
    if daysPassed >= 60 then
        self.object:sendEvent('daysPassed')
    end
end

return {
    engineHandlers = {
        onUpdate = getDaysPassed
    }
}