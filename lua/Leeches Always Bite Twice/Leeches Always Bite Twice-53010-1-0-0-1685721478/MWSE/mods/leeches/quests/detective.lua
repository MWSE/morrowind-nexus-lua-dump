local animationStatus = { idle = 0, interrupted = 1, combat = 2 }

--- Make water droplets less synchronized.
local function offsetWaterDrops()
    local ref = tes3.getReference("leech_bucket_drip")
    if ref then
        tes3.setAnimationTiming({ reference = ref, timing = 2.0 })
    end
end

local function playSleepingAnimation()
    local ref = tes3.getReference("leech_private_eye_01")
    local prop = tes3.getReference("leech_office_chair")
    if not (ref and prop) then
        return
    end

    -- Disable greeting/turning.
    ref.mobile.movementCollision = false
    ref.mobile.hello = 0

    -- Center on the chair.
    ref.position = prop.position
    ref.orientation = prop.orientation

    -- Play the animation.
    tes3.playAnimation({
        reference = ref,
        group = tes3.animationGroup.idle8,
        mesh = "leeches\\k\\chair_sleeping.nif",
    })

    -- Play snoring sounds.
    tes3.playSound({
        reference = ref,
        sound = "leeches_male_snoring",
        loop = true,
    })

    -- Attach cigar.
    local attachNode = ref.sceneNode:getObjectByName("AttachCigar") --[[@as niNode?]]
    if attachNode then
        local cigar = tes3.loadMesh("leeches\\m\\cigar_smoke.nif")
        attachNode:attachChild(cigar:clone()) ---@diagnostic disable-line
        attachNode:update()
        attachNode:updateEffects()
        attachNode:updateProperties()
    end

    -- Close eyes.
    local animData = ref.mobile.animationController.animationData
    animData.headMorphTiming = 1.7
    animData.timeToNextBlink = 1e9

    -- Update animation status.
    ref.tempData.leech_animStatus = animationStatus.idle
    ref.tempData.leech_animFacing = ref.facing
end

local function onCellLoaded()
    if tes3.player.cell.id == "Balmora, Detective's Office" then
        offsetWaterDrops()
        playSleepingAnimation()
    end
end
event.register("cellActivated", onCellLoaded)
event.register("loaded", onCellLoaded)
