local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")

return {
    engineHandlers = {
        onActive = function()
            if self.recordId ~= "tremors_dm_k_qk_camera" then
                return
            end

            local duration = 7.0
            local strength = 7

            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.Player then
                    actor:sendEvent("tremors_dm_k_qk_shake", {duration, strength})
                end
            end
        end
    }
}
