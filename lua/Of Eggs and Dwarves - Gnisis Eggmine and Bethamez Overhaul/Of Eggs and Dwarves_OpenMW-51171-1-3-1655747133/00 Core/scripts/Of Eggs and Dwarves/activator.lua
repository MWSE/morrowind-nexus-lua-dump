local types = require('openmw.types')
local nearby = require('openmw.nearby')
local self = require("openmw.self")

return {
    engineHandlers = {
        onActive = function()
            if self.recordId == "slf_qk_helper" then
                local r = self.rotation * (180 / math.pi)
                for _, actor in ipairs(nearby.actors) do
                    if actor.type == types.Player then
                        actor:sendEvent("slf_qk_animation", {r.y, r.z})
                    end
                end
            end
        end,
        onInactive = function()
            if self.recordId == "slf_qk_helper" then
                for _, actor in ipairs(nearby.actors) do
                    if actor.type == types.Player then
                        actor:sendEvent("slf_qk_animation", nil)
                    end
                end
            end
        end
    }
}
