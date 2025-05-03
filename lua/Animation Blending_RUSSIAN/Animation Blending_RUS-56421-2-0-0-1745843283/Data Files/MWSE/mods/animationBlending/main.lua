--[[
    Animation Blending
    By Greatness7
--]]

local rules = require("animationBlending.rules")
local config = require("animationBlending.config")
local TransitionContext = require("animationBlending.TransitionContext")


--- Tracks all references that are currently transitioning.
---
---@type table<tes3reference, TransitionContext>
local transitioning = {}


--- When an animation group is changed track the reference.
---
---@param e playGroupEventData
local function onPlayGroup(e)
    if config.enabled == false then
        return
    end

    -- Do nothing if transitioning between the same group.
    if e.currentGroup == e.group then
        return
    end

    -- Do nothing if transitioning between invalid groups.
    if e.currentGroup == 0xFF or e.group == 0xFF then
        return
    end

    -- Handle the 'playerOnly' user configuration setting.
    if config.playerOnly
        and e.reference ~= tes3.player
        and e.reference ~= tes3.player1stPerson
    then
        return
    end

    -- Do nothing if no valid transition rules were found.
    local rule = rules.get(e.reference, e.currentGroup, e.group)
    if rule == nil or rule.duration == 0 then
        return
    end

    local context = TransitionContext.getOrCreateForReference(e.reference)
    context:captureTransforms(e.reference)
    context:setRule(e.index, rule)

    transitioning[e.reference] = context
end
event.register("playGroup", onPlayGroup, { priority = -1000 })


--- Do animation blending for all transitioning references.
---
local function onSimulated()
    if table.empty(transitioning) then
        return
    end

    -- We will use camera distance and frustum culling to skip blending when viable.
    local camera = tes3.getCamera()
    local cameraPosition = tes3.getCameraPosition()
    local time = tes3.getSimulationTimestamp(false)

    -- For performance we want to call the update function as few times as possible.
    -- We defer all updating during the loop, then call it after on a shared parent.
    ---@type table<number, niAVObject>
    local update = table.new(0, 3)

    for ref, context in pairs(transitioning) do
        context.transformsCaptured = false -- Ensures next playGroup event captures.

        local sceneNode = ref.sceneNode
        if sceneNode
            and sceneNode:isAppCulled() == false
            and sceneNode:isFrustumCulled(camera) == false
            and sceneNode.worldBoundOrigin:distance(cameraPosition) <= config.maxDistance
        then
            local needsUpdate = context:applyAnimationBlending(time)
            if needsUpdate == false then -- Transition has completed, stop tracking.
                context:clearTransforms()
                transitioning[ref] = nil
            else
                -- The player sub graph does not share a parent, so use it directly.
                if ref ~= tes3.player and ref ~= tes3.player1stPerson then
                    sceneNode = sceneNode.parent
                end
                --- Uses the scene node address as our table key for de-duplication.
                ---@type fun(ob:niObject):number
                ---@diagnostic disable-next-line
                local addressOf = mwse.memory.convertFrom.niObject
                update[addressOf(sceneNode)] = sceneNode
            end
        end
    end

    for _, sceneNode in pairs(update) do
        sceneNode:update()
    end
end
event.register("simulated", onSimulated, { priority = 1000 })


event.register("loaded", function()
    table.clear(transitioning)
end)


event.register("referenceDeactivated", function(e)
    transitioning[e.reference] = nil
end)


event.register("referenceSceneNodeCreated", function(e)
    transitioning[e.reference] = nil
end)


event.register("modConfigReady", function()
    dofile("animationBlending.mcm")
end)


if table.find(os.getCommandLine(), "--testAnimationBlending") then
    return dofile("animationBlending.tests")
end
