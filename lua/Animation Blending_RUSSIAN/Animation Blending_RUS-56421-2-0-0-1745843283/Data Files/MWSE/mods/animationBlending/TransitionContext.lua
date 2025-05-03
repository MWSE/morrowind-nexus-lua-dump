local TransitionSection = require("animationBlending.TransitionSection")


---@class TransitionContext
---@field transformsCaptured boolean
---@field bodySections table<tes3.animationBodySection, TransitionSection>
local TransitionContext = {}
TransitionContext.__index = TransitionContext


--- Create a new TransitionContext instance.
---
---@return TransitionContext
function TransitionContext.new()
    return setmetatable({
        transformsCaptured = false,
        bodySections = {
            [tes3.animationBodySection.lower] = TransitionSection.new(),
            [tes3.animationBodySection.upper] = TransitionSection.new(),
            [tes3.animationBodySection.leftArm] = TransitionSection.new(),
        },
    }, TransitionContext)
end


--- Get the transition context for a reference, create it if absent.
---
---@param ref tes3reference
---@return TransitionContext
function TransitionContext.getOrCreateForReference(ref)
    local context = ref.tempData.transitionContext

    if context == nil then
        context = TransitionContext.new()
        ref.tempData.transitionContext = context
    end

    return context
end


--- Capture the current animation transforms of the given reference.
---
--- If transforms were already captured this does nothing.
---
---@parame reference tes3reference
function TransitionContext:captureTransforms(reference)
    if self.transformsCaptured == false then
        self.transformsCaptured = true
        for index, section in pairs(self.bodySections) do
            section:captureTransforms(reference, index)
        end
    end
end


--- Clear all captured transforms.
---
function TransitionContext:clearTransforms()
    self.transformsCaptured = false
    for _, section in pairs(self.bodySections) do
        section:clearTransforms()
    end
end


--- Apply animation blending for the given time.
---
--- Returns true if the scene graph needs updated.
---
---@param time number
---@return boolean
function TransitionContext:applyAnimationBlending(time)
    local needsUpdate = false

    for _, section in pairs(self.bodySections) do
        if section:applyAnimationBlending(time) then
            needsUpdate = true
        end
    end

    return needsUpdate
end


--- Set the rule for a given body section.
---
--- Returns true if the rule was successfully set.
---
---@param bodySection tes3.animationBodySection
---@param rule BlendRule
function TransitionContext:setRule(bodySection, rule)
    local section = self.bodySections[bodySection]
    section.startTime = tes3.getSimulationTimestamp(false)
    section.rule = rule
end


return TransitionContext
