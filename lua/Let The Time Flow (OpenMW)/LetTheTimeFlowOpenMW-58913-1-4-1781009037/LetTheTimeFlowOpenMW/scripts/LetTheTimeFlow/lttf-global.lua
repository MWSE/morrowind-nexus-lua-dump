--
-- [ Libraries ]
--
local types = require('openmw.types')
local acti = require("openmw.interfaces").Activation
local core = require('openmw.core')


--
-- [ Variables ]
--
local cannotRestGMST = 'sRestMenu4'
local restCounter = 1


--
-- [ Functions ]
--
-- _ Rest counter receiver _
local function onRestCounterReceived(value)
    restCounter = value
end
-- _ Show no bed message receiver _
local function onNoBedReceived(actor)
    if restCounter > 0 then
        actor:sendEvent('showMessageNoBed')
    end
end
-- _ Prevent bed activation _
local function activateBed(object, actor)
    if (types.Activator.record(object.recordId).mwscript == 'bed_standard' or types.Activator.record(object.recordId).mwscript == 'chargenbed') and restCounter <= 0 then
        actor:sendEvent('showGMSTMessage', core.getGMST(cannotRestGMST))
        return false
    end
end


--
-- [ Handlers ]
--
acti.addHandlerForType(types.Activator, activateBed)
return {
    eventHandlers = {
        onRestCounterReceived = onRestCounterReceived,
        onNoBedReceived = onNoBedReceived
    }
}
