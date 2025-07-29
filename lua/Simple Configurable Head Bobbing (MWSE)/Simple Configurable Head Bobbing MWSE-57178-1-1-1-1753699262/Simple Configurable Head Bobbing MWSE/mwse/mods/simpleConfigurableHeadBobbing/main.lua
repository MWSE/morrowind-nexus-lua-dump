--[[
	Mod: Simple Configurable Head Bobbing
	Author: rhjelte
	Version: 1.1.1
]]--

local config = {}

local bobPhase = { x = 0, y = 0 }
local baseBobFrequency = { x = 1, y = 2 }
local baseBobAmplitude = { x = 3, y = 1.5 }
local sneakingBobAmplitudeMultiplier = { x = 1, y = 0.5 }
local walkingBobAmplitudeMultiplier = { x = 1, y = 1 }
local runningBobAmplitudeMultiplier = { x = 1.5, y = 1.5 }

local baseBobFrequencyMultiplier = 0.6
local speedBobFrequencyMultiplier = 0.04

local currentBobFrequencyMultiplier = 0
local targetBobFrequencyMultiplier = 0

local currentBobAmplitudeMultiplier = {x = 0, y = 0}
local targetBobAmplitudeMultiplier = {x = 0, y = 0}

local maxRayDistance = 5000
local targetRayDistance
local currentRayDistance

local playerSpeed = 0

local cosineYprev = 0
local blockSound = false

local footStepName = {
	["footbareleft"] = true,
	["footbareright"] = true,
	["footlightleft"] = true,
	["footlightright"] = true,
	["footmedleft"] = true,
	["footmedright"] = true,
	["footheavyleft"] = true,
	["footheavyright"] = true,
}

local weightClassFootStepMapping = {
    [tes3.armorWeightClass["light"]] = {left = "FootLightLeft", right = "FootLightRight"},
    [tes3.armorWeightClass["medium"]] = {left = "FootMedLeft", right = "FootMedRight"},
    [tes3.armorWeightClass["heavy"]] = {left = "FootHeavyLeft", right = "FootHeavyRight"}
}

local function getEquipmentClass(reference, slot)
    local equipped = tes3.getEquippedItem({ actor = reference, objectType = tes3.objectType.armor, slot = slot })
    if (not equipped) then
        return nil
    end
    return equipped.object.weightClass
end

local function lerp(start, goal, alpha)
    return start + (goal - start)*alpha
end

local function isMoving(mobile)
    return mobile.isMovingForward or mobile.isMovingBack or mobile.isMovingLeft or mobile.isMovingRight
end

local function headBob(e)

    if config.modEnabled ~= true then
        return
    end

    if e.animationController.vanityCamera then
        return
    end

    if e.animationController.is3rdPerson then
        if config.thirdPersonBobEnabled ~= true then
            return
        end
    end

    --Save down time since start of program in seconds and delta time
    local dt = tes3.worldController.deltaTime

    --Get the needed rotations
    local r_matrix = e.cameraTransform.rotation:copy()
    
    local upVector = r_matrix:getUpVector()
    local rightVector = r_matrix:getRightVector()

    --Get positions to manipulate
    local targetPosition = e.cameraTransform.translation:copy()
    local originalPosition = e.cameraTransform.translation:copy()

    -- First person arms control
    local firstPersonNode = tes3.player1stPerson.sceneNode
    local armTargetPosition
    if firstPersonNode ~= nil then
        armTargetPosition = firstPersonNode.translation:copy()
    end
    

    -- If no bobbing state, set target bob amplitude to zero
    targetBobAmplitudeMultiplier = { x = 0, y = 0}

    -- Check if we should bob, and set a target based on state
    if not tes3.mobilePlayer.isJumping and not tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isSwimming and not tes3.mobilePlayer.isFlying then
        if isMoving(tes3.mobilePlayer) == true then
            if tes3.mobilePlayer.isSneaking then
                targetBobAmplitudeMultiplier.x = sneakingBobAmplitudeMultiplier.x * (config.sneakingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = sneakingBobAmplitudeMultiplier.y * (config.sneakingCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isWalking then
                targetBobAmplitudeMultiplier.x = walkingBobAmplitudeMultiplier.x * (config.walkingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = walkingBobAmplitudeMultiplier.y * (config.walkingCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isRunning then
                targetBobAmplitudeMultiplier.x = runningBobAmplitudeMultiplier.x * (config.runningCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = runningBobAmplitudeMultiplier.y * (config.runningCustomizableAmplitudeMultiplierY * 0.01)
            end
        end
    end

    local cameraDependentMultiplier = 1
    if e.animationController.is3rdPerson and config.thirdPersonBobEnabled then
       cameraDependentMultiplier = config.thirdPersonBobMultiplier * 0.01
    end
    
    -- Smooth transition to bob amplitude
    currentBobAmplitudeMultiplier.x = lerp(currentBobAmplitudeMultiplier.x, targetBobAmplitudeMultiplier.x * cameraDependentMultiplier, 1 - math.exp(-dt * config.smoothValue))
    currentBobAmplitudeMultiplier.y = lerp(currentBobAmplitudeMultiplier.y, targetBobAmplitudeMultiplier.y * cameraDependentMultiplier, 1 - math.exp(-dt * config.smoothValue))
    
    -- Set target occilation speed based on movement speed and smooth transition to actual bob frequency
    local speedFrequencyOffset = math.sqrt(playerSpeed) * speedBobFrequencyMultiplier --To make the curve flatten on higher values of speed
    -- Lessen the speed when sneaking
    if tes3.mobilePlayer.isSneaking then
        targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.sneakFrequencyMultiplier * 0.01
    else
        targetBobFrequencyMultiplier = baseBobFrequencyMultiplier + speedFrequencyOffset
    end
    
    currentBobFrequencyMultiplier = lerp(currentBobFrequencyMultiplier, targetBobFrequencyMultiplier, 1 - math.exp(-dt * config.smoothValue))

    -- Increment phase based on smoothed frequency
    bobPhase.x = bobPhase.x + dt * baseBobFrequency.x * currentBobFrequencyMultiplier * (config.bobCustomizableFrequencyMultiplier * 0.01) * 2 * math.pi
    bobPhase.y = bobPhase.y + dt * baseBobFrequency.y * currentBobFrequencyMultiplier * (config.bobCustomizableFrequencyMultiplier * 0.01)* 2 * math.pi

    -- Wrap phase to avoid overflow
    bobPhase.x = bobPhase.x % (2 * math.pi)
    bobPhase.y = bobPhase.y % (2 * math.pi)

    local bobOscillate = {
        x = math.sin(bobPhase.x),
        y = math.sin(bobPhase.y)
    }

    -- Do the head bob 
    targetPosition = targetPosition + (rightVector * bobOscillate.x * baseBobAmplitude.x * currentBobAmplitudeMultiplier.x * (config.bobCustomizableAmplitudeMultiplier * 0.01))
    targetPosition = targetPosition + (upVector * bobOscillate.y * baseBobAmplitude.y * currentBobAmplitudeMultiplier.y* (config.bobCustomizableAmplitudeMultiplier * 0.01))

    -- Do a smaller version of the head bob for the arms
    armTargetPosition = armTargetPosition + (rightVector * bobOscillate.x * baseBobAmplitude.x * currentBobAmplitudeMultiplier.x * (config.armAmplitudeMultiplier*0.01) * (config.bobCustomizableAmplitudeMultiplier * 0.01))
    armTargetPosition = armTargetPosition + (upVector * bobOscillate.y * baseBobAmplitude.y * currentBobAmplitudeMultiplier.y * (config.armAmplitudeMultiplier*0.01) * (config.bobCustomizableAmplitudeMultiplier * 0.01))

    -- Apply new position to camera
    local newPosition = targetPosition
    e.cameraTransform.translation = newPosition

    -- Raycast to use for eye stabilization post moving the camera
    local hitResult = tes3.rayTest({
        position = originalPosition, 
        direction = r_matrix:getForwardVector(),
        maxDistance = maxRayDistance,
        ignore = { tes3.player }
    })

    -- The look at point is either the ray hit position, OR along the ray but the max or min distance
    local lookAtPoint
    if hitResult == nil then
        targetRayDistance = maxRayDistance
    else
        if hitResult.distance < config.minimumLookAtDistance then
            targetRayDistance = config.minimumLookAtDistance
        else
            targetRayDistance = hitResult.distance
        end
    end

    if currentRayDistance == nil then
        currentRayDistance = targetRayDistance
    else
        -- Smooth the look at point along the ray, and set it to the inbetween value
        currentRayDistance = lerp(currentRayDistance, targetRayDistance, 1 - math.exp(-dt * 5))
    end

    lookAtPoint = originalPosition + (r_matrix:getForwardVector() * currentRayDistance)

    -- Apply position to the arms, and update them to calculate position and rotation properly.
    if firstPersonNode ~= nil then
        local newArmPosition = armTargetPosition
        firstPersonNode.translation = newArmPosition
        firstPersonNode:update()
    end

    --Get the right rotation and apply it to the camera.
    local lookDirection = lookAtPoint - newPosition
    local newRotation = tes3matrix33.new()
    newRotation:lookAt(lookDirection:normalized(), upVector)
    e.cameraTransform.rotation = newRotation

    -- Sync the armCameraTransform and the cameraTransform (for some reason the sky bounces aorund if this is not done)
    e.armCameraTransform = e.cameraTransform

    -- Get the right footstep, and trigger footstep sounds only on bottom of oscilation
    local bootWeightClass = getEquipmentClass(tes3.player, tes3.armorSlot["boots"])

    local cosY = math.cos(bobPhase.y)
    if config.syncFootsteps then
        if e.animationController.is3rdPerson == false then
            if not tes3.mobilePlayer.isJumping and not tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isSwimming and not tes3.mobilePlayer.isFlying then
                if isMoving(tes3.mobilePlayer) == true then
                    if cosY == 0 or (cosY > 0 and cosineYprev < 0) then
                        if bobOscillate.y <= 0 then
                            blockSound = false
                            if bootWeightClass == nil then
                                if bobOscillate.x <= 0 then
                                    tes3.playSound({sound = "FootBareLeft", mixChannel = tes3.soundMix.footsteps, volume = 0.6})
                                else
                                    tes3.playSound({sound = "FootBareRight", mixChannel = tes3.soundMix.footsteps, volume = 0.6})
                                end
                            else
                                if bobOscillate.x <= 0 then
                                    tes3.playSound({sound = weightClassFootStepMapping[bootWeightClass].left, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                else
                                    tes3.playSound({sound = weightClassFootStepMapping[bootWeightClass].right, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    cosineYprev = cosY
end
event.register(tes3.event.cameraControl, headBob)

-- Get the player speed
local function calcMoveSpeedCallback(e)
    if e.reference == tes3.player then
        playerSpeed = e.speed
    end
end
event.register(tes3.event.calcMoveSpeed, calcMoveSpeedCallback)



-- Block footstep sounds from playing unless allowed
local function onAddSound(e)
    if config.modEnabled == false or config.syncFootsteps == false then
        return
    end

    if e.isVoiceover then
        return
    end

    local ref = e.reference or tes3.player
    if ref ~= tes3.player then
        return
    end

    if tes3.mobilePlayer.is3rdPerson or tes3.getVanityMode() then
        return
    end

    local id = e.sound.id:lower()
    if footStepName[id] then
        if blockSound then
            return false
        else
            blockSound = true
        end
    end
end
event.register("addSound", onAddSound, {priority = 10000000000})

event.register(tes3.event.modConfigReady, function()
    require("simpleConfigurableHeadBobbing.mcm")
	config = require("simpleConfigurableHeadBobbing.config").loaded
end)