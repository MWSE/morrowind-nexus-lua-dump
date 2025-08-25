local self = require('openmw.self')
local core = require('openmw.core')

-- Sends an Event to the Global script when Mastrius is killed
return {
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent('MastriusJournalUpdate')
        end
    }
}