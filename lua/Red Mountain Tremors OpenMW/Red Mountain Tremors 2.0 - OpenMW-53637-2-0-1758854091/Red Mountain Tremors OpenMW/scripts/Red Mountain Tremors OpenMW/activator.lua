local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")

return {
    engineHandlers = {
        onActive = function()

            if self.recordId == "tremors_dm_k_qk_camera" then
                strength = 0.1 -- Akulakhan's chamber
            elseif self.recordId == "tremors_dm_k_qk_camera_2" then
                strength = 2.0 -- Dagoth Ur
            elseif self.recordId == "tremors_dm_k_qk_camera_3" then
                strength = 4.0 -- Red Mountain and Molag Amur
            elseif self.recordId == "tremors_dm_k_qk_camera_4" then
                strength = 6.0 -- Ashlands
            elseif self.recordId == "tremors_dm_k_qk_camera_5" then
                strength = 10.0 -- Others
            else
                return -- Si no coincide con ninguno, no hace nada
            end

            local duration = 7.0

            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.Player then
                    actor:sendEvent("tremors_dm_k_qk_shake", {duration, strength})
                end
            end
        end
    }
}
