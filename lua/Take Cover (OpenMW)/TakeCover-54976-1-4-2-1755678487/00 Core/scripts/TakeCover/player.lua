local I = require("openmw.interfaces")
local nearby = require('openmw.nearby')

local S = require('scripts.TakeCover.settings')

I.Settings.registerPage {
    key = S.MOD_NAME,
    l10n = S.MOD_NAME,
    name = "name",
    description = "description",
}

local updateRate = 0.5
local lastUpdateTime = 0
local onUpdate = function(deltaTime)
    if not S.globalStorage:get("enabled") then return end

    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < updateRate then return end
    lastUpdateTime = 0

    for _, actor in pairs(nearby.actors) do
        actor:sendEvent("tc_handle")
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
