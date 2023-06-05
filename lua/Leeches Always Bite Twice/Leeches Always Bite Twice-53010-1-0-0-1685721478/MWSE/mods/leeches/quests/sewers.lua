local animationStatus = { idle = 0, interrupted = 1, combat = 2 }
local animations = {
    ["leech_sewers_sleeper"] = {
        mesh = "leeches\\k\\ground_sleep.nif",
        prop = "leech_sewers_sleeper_bed",
    },
    ["leech_sewers_sitter"] = {
        mesh = "leeches\\k\\log_sit.nif",
        prop = "leech_sewers_sitter_log",
    },
    ["leech_sewers_leaner"] = {
        mesh = "leeches\\k\\rail_lean.nif",
        prop = "leech_sewers_leaner_rail",
    },
}

---@param e referenceActivatedEventData
local function playIdleAnimations(e)
    local ref = e.reference

    local id = ref.baseObject.id:lower()
    local animationData = animations[id]
    if animationData == nil then
        return
    end

    local prop = tes3.getReference(animationData.prop)
    if prop == nil then
        return
    end

    -- Disable physics/turning.
    ref.mobile.movementCollision = false
    ref.mobile.hello = 0

    -- Center on the animation prop.
    ref.position = prop.position
    ref.orientation = prop.orientation

    -- Play the animation.
    tes3.playAnimation({
        reference = ref,
        group = tes3.animationGroup.idle8,
        mesh = animationData.mesh,
    })

    -- Update animation status.
    ref.tempData.leech_animStatus = animationStatus.idle
    ref.tempData.leech_animFacing = ref.facing
end
event.register("referenceActivated", playIdleAnimations)

--- Ensure `playIdleAnimations` triggers when loading a save.
---@param e loadedEventData
local function onLoaded(e)
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            playIdleAnimations({ reference = ref })
        end
    end
end
event.register("loaded", onLoaded)

---@param e combatStartedEventData
local function onCombatStarted(e)
    local ref = e.target.reference
    local tempData = ref.tempData
    if tempData == nil then
        return
    end

    local status = tempData.leech_animStatus
    if status ~= animationStatus.idle then
        return
    end

    -- Prevent actor turning.
    local mobile = ref.mobile
    if mobile then
        mobile.actionData.animationAttackState = tes3.animationState.knockedOut
        do -- Ugly fix for the single-frame turn that happens when when combat first starts.
            local handle = assert(tes3.makeSafeObjectHandle(ref))
            event.register("cameraControl", function()
                if handle:valid() then handle.facing = handle.tempData.leech_animFacing end
            end, { doOnce = true })
        end
    end

    tes3.playAnimation({
        reference = ref,
        group = tes3.animationGroup.idle9,
        loopCount = 0,
    })

    -- Update animation status.
    tempData.leech_animStatus = animationStatus.interrupted
end
event.register("combatStarted", onCombatStarted)

---@param e playGroupEventData
event.register("playGroup", function(e)
    local ref = e.reference
    local tempData = ref.tempData
    if tempData == nil then
        return
    end

    local status = tempData.leech_animStatus
    if status ~= animationStatus.interrupted then
        return
    end

    if e.group ~= tes3.animationGroup.idle9 then
        tempData.leech_animStatus = animationStatus.combat
        local mobile = ref.mobile
        if mobile then
            mobile.movementCollision = true
            mobile.actionData.animationAttackState = tes3.animationState.idle
        end
    end
end)
