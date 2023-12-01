local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")

return {
    engineHandlers = {
        onActive = function()
            if self.recordId ~= "dm_k_qk_camera" then
                return
            end

            local duration = 6.0
            local strength = 0.3

            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.Player then
                    actor:sendEvent("dm_k_qk_shake", {duration, strength})
                end
            end
        end
    }
}
