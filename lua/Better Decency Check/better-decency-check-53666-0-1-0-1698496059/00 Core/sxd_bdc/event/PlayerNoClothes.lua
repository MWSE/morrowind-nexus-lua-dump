local core = require'openmw.core'

local eventName = 'PlayerNoClothes'

local function sendEvent(playerObject)
    core.sendGlobalEvent(eventName, {player = playerObject})
end

return {
    eventName = eventName,
    sendEvent = sendEvent
}
