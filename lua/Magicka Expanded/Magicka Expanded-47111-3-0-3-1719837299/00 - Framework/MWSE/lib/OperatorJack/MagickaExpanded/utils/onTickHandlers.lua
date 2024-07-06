local nodes = require("OperatorJack.MagickaExpanded.vfx.nodes")

--- OnTickerHandlers module for abstracting some common onTick event handlers in magic effects.
---@class OnTickerHandlers
local this = {}

local attackEffects = {}
local vfx = {}
local vfxFirstPerson = {}

---@param e attackHitEventData
local function onAttack(e)
    if (not e.targetReference) then return end

    for effect, config in pairs(attackEffects) do
        if (tes3.isAffectedBy({reference = e.reference, effect = effect})) then
            local magnitude = tes3.getEffectMagnitude({reference = e.reference, effect = effect})

            e.targetReference.mobile:applyDamage({
                damage = magnitude,
                resistAttribute = config.resistAttribute
            })
            tes3.createVisualEffect({
                position = e.targetReference.position,
                object = config.vfxHitObjectId,
                lifespan = 1.0
            })
        end
    end
end

event.register(tes3.event.attackHit, onAttack)

---@class OnPalmEffectTickParams
---@field effect tes3.effect
---@field resistAttribute tes3.effectAttribute?
---@field tickEventData tes3magicEffectTickEventData
---@field vfxRootNodeName string The root node name of the palm effect VFX. This is used to attach and deattach it from the caster's hand.
---@field vfxPath string The path to the palm effect VFX.
---@field vfxHitObjectId string The object ID of the VFX to show on the target when they are struck by the palm effect.

---@param e OnPalmEffectTickParams
this.onPalmEffectTick = function(e)
    local tick = e.tickEventData
    local reference = tick.sourceInstance.caster

    if (not attackEffects[e.effect]) then
        attackEffects[e.effect] = {
            resistAttribute = e.resistAttribute,
            vfxHitObjectId = e.vfxHitObjectId
        }
    end

    if (tick.effectInstance.state == tes3.spellState.working and
        not vfx[tick.sourceInstance.serialNumber]) then
        -- Attach VFX to hand.
        local node = nodes.getOrAttachVfx(reference, e.vfxRootNodeName, e.vfxPath, "Weapon Bone")

        if (node) then
            node.scale = 0.7 + (tick.effectInstance.magnitude / 100)
            node.appCulled = false
            node:update({controllers = true})
            node:updateEffects()
            vfx[tick.sourceInstance.serialNumber] = node
        end

        if (reference == tes3.player) then
            local firstPersonNode = nodes.getOrAttachVfx(tes3.player1stPerson, e.vfxRootNodeName,
                                                         e.vfxPath, "Weapon Bone")

            if (firstPersonNode) then
                firstPersonNode.scale = 0.7 + (tick.effectInstance.magnitude / 100)
                firstPersonNode.appCulled = false
                firstPersonNode:update({controllers = true})
                firstPersonNode:updateEffects()
                vfxFirstPerson[tick.sourceInstance.serialNumber] = firstPersonNode
            end
        end

    end
    if (tick.effectInstance.state == tes3.spellState.ending and
        vfx[tick.sourceInstance.serialNumber]) then
        -- Remove VFX from hand.
        local node = vfx[tick.sourceInstance.serialNumber]
        nodes.hideNode(node)
        vfx[tick.sourceInstance.serialNumber] = nil
    end
    if (tick.effectInstance.state == tes3.spellState.ending and
        vfxFirstPerson[tick.sourceInstance.serialNumber]) then
        -- Remove VFX from hand.
        local node = vfxFirstPerson[tick.sourceInstance.serialNumber]
        nodes.hideNode(node)
        vfxFirstPerson[tick.sourceInstance.serialNumber] = nil
    end

    tick:trigger()
end

return this
