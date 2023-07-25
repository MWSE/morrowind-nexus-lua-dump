
local self = require("openmw.self")
local updatenow = 0
local function onUpdate()
return

end

return {
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        recieveActivators = recieveActivators
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame
    }
}
