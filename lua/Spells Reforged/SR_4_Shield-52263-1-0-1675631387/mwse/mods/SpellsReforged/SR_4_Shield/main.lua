---@param node niNode
---@param reference tes3reference
---@param attacker tes3reference
local function fixRotation(node, reference, attacker)
    local dir = attacker.position - reference.position
    local angle = math.atan2(dir.x, dir.y)

    local rot = reference.sceneNode.worldTransform.rotation:copy()
    rot:reorthogonalize()

    local mat = rot:copy()
    mat:toRotationZ(angle)

    node.rotation = rot:invert() * mat
end

---@param e damagedEventData
local function onDamaged(e)
    if e.source ~= "attack" then
        return
    end

    local _, shield = next(e.mobile:getActiveMagicEffects({effect=tes3.effect.shield}))
    if not shield then
        return
    end

    local vfx = tes3.createVisualEffect({
        effect = "VFX_k_ShieldOnHit",
        avObject = e.reference.sceneNode,
        lifespan = 1.5,
    })

    local switch = vfx.effectNode.children[1]
    if switch then
        fixRotation(switch, e.reference, e.attackerReference)
        switch.switchIndex = math.random(#switch.children - 1)
    end

    -- copy scale/offset from the shield vfx
    local visual = shield.effectInstance.visual
    vfx.effectNode.scale = visual.effectNode.scale
    vfx.verticalOffset = visual.verticalOffset
end
event.register("damaged", onDamaged)


---@param sourceInstance tes3magicSourceInstance
---@param effectId number
local function hasEffect(sourceInstance, effectId)
    if sourceInstance then
        for _, effect in pairs(sourceInstance.sourceEffects) do
            if effect.id == effectId then
                return true
            end
        end
    end
    return false
end


---@param caster tes3reference
local function createCreatureHandsVFX(caster)
    if caster.object.objectType ~= tes3.objectType.creature then
        return
    end

    for _, name in pairs({"Bip01 L Hand", "Bip01 R Hand"}) do
        local object = caster.sceneNode:getObjectByName(name)
        if object then
            tes3.createVisualEffect({effect = "VFX_k_ShieldHands", avObject = object, lifespan = 1.0})
        end
    end
end


---@param e vfxCreatedEventData
local function onVfxCreated(e)

    if not hasEffect(e.vfx.sourceInstance, tes3.effect.shield) then
        return
    end


    local vfxObjectId = e.vfx.effectObject and e.vfx.effectObject.id
    if vfxObjectId == "VFX_k_ShieldCast" then
        createCreatureHandsVFX(e.vfx.sourceInstance.caster)
        return
    end

    if vfxObjectId == "VFX_Hands" then
        -- get rid of the vanilla hands vfx
        e.vfx.expired = true
        -- show replacement vfx in its place
        tes3.createVisualEffect({effect = "VFX_k_ShieldHands", avObject = e.vfx.attachNode, lifespan = 1.0})
        return
    end
end
event.register("vfxCreated", onVfxCreated)
