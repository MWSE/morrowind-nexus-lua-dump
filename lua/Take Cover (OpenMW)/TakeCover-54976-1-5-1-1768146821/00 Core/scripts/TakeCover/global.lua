local world = require('openmw.world')
local async = require('openmw.async')

local mDef = require("scripts.TakeCover.definition")
local mS = require('scripts.TakeCover.settings')
mS.initSettings()

local enabled = mS.globalStorage:get("enabled")
local updateTime = 0.5
local lastUpdateTime = 0

local onUpdate = function(deltaTime)
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < updateTime then return end
    lastUpdateTime = 0

    if not enabled then return end

    for _, actor in pairs(world.activeActors) do
        actor:sendEvent(mDef.events.handle_actor)
    end
end

mS.globalStorage:subscribe(async:callback(function(_, key)
    if key == "enabled" then
        enabled = mS.globalStorage:get("enabled")
    end
end))

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}