local world = require('openmw.world')

local function setAlarmConditional(data)
    world.players[1]:sendEvent('setAlarmConditional', data)
end

return {
    eventHandlers = {
        setAlarmConditional = setAlarmConditional
    }
}
