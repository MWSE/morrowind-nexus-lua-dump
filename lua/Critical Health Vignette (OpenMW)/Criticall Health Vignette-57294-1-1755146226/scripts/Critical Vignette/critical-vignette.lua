local selfObj = require("openmw.self")
local types = require("openmw.types")
local postprocessing = require("openmw.postprocessing")
local storage = require('openmw.storage')
local betterBarSettings = storage.playerSection('SettingsPlayerBetterBars')

-- Threshold for critical health (35%)
local threshold = betterBarSettings:get("HEALTH_FLASHING_THRESHOLD") or 0.35
local shader = postprocessing.load("critical-vignette")

local function healthPercent()
    local stats = types.Actor.stats.dynamic
    local hp = stats.health(selfObj)
    return hp.current / hp.base
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            local hp = healthPercent()

            if hp <= threshold then
                if not shader:isEnabled() then
                    shader:enable()
                end
                if shader.setFloat then
                    -- Smooth fade based on health
                    shader:setFloat("uMidPoint", (1 * hp) + 0.5)
                end
            else
                if shader:isEnabled() then
                    shader:disable()
                end
            end
        end
    }
}