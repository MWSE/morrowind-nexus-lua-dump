local core = require('openmw.core')
local self = require('openmw.self')

local function stopCurrent()
    if core.sound.isSayActive(self) then
        core.sound.stopSay(self)
    end
end

return {
    eventHandlers = {
        DiverseVoices_OpenMW_Play = function(e)
            stopCurrent()
            core.sound.say(e.path, self)
        end,
        DiverseVoices_OpenMW_Stop = function()
            stopCurrent()
        end,
    },
}
