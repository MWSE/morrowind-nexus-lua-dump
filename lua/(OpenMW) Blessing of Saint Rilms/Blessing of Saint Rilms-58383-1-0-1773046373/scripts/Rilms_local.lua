local self   = require("openmw.self")
local types  = require("openmw.types")
local core   = require("openmw.core")

return {
    engineHandlers = {
        onActivated = function(activator)
            if not types.Player.objectIsInstance(activator) then return end
            local npcId = tostring(self.object.id)
            core.sendGlobalEvent("RilmsSetActiveNpc", { npcId = npcId })
            core.sendGlobalEvent("RilmsUpdateNpcFull", { npcId = npcId })
        end,
    },
}