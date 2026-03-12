local mp = "scripts/MaxYari/dynamic reticle/"

local Tweener = require("scripts/MaxYari/dynamic reticle/tweener")
local world = require("openmw.world")
local core = require("openmw.core")
local util = require("openmw.util")
local gutils = require(mp .. "gutils")

local slowdownTweener = nil

local function handleSlowdownEffect(data)
    if slowdownTweener then
        slowdownTweener:finish()
        slowdownTweener = nil
    end

    slowdownTweener = Tweener:new()
    slowdownTweener
        :add(data.inTime, Tweener.easings.easeOutCubic, function(t)
            local scale = gutils.lerp(1, data.minScale, t)
            world.setSimulationTimeScale(t)
        end)
        :add(data.hold, Tweener.easings.linear, function()
            world.setSimulationTimeScale(data.minScale)
        end)
        :add(data.outTime, Tweener.easings.easeInCubic, function(t)
            world.setSimulationTimeScale(gutils.lerp(data.minScale, 1, t))
        end)
end

local function onUpdate(dt)
    if slowdownTweener then
        slowdownTweener:tick(dt)        
    end    
end

local function onLoad()    
    world.setSimulationTimeScale(1)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad    
    },
    eventHandlers = {
        SlowdownEffect = handleSlowdownEffect        
    },
    
}