local core = require'openmw.core'

local eventName = 'styxd.bdc.PlayerNoClothes'

local function sendEvent(playerObject)
    core.sendGlobalEvent(eventName, {player = playerObject})
end

return {
    eventName = eventName,
    sendEvent = sendEvent
}
