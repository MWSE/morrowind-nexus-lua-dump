--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.6
    link: https://www.nexusmods.com/morrowind/mods/57178

    Heavy inspiration, and some code straight up in some places, was taken from Steadicam by Hrnchamd
    Their work can be found here: https://www.nexusmods.com/morrowind/mods/52225
]]--

local this = {}
this.freeLookRotateZ = 0
local config = {}
local common = require("Modernized 1st Person Experience.common")
local addonBridge = require("Modernized 1st Person Experience.addonBridge")
--local data

-- Base values for head bobbing
local bobPhase = { x = 0, y = 0 }
local baseBobFrequency = { x = 1, y = 2 }
local baseBobAmplitude = { x = 3, y = 1.5 }

-- State specific multipliers for amplitude
local sneakingBobAmplitudeMultiplier = { x = 1, y = 0.5 }
local walkingBobAmplitudeMultiplier = { x = 1, y = 1 }
local runningBobAmplitudeMultiplier = { x = 1.5, y = 1.5 }
local flyingBobAmplitudeMultiplier = { x = 1.2, y = 1.2 }
local swimmingBobAmplitudeMultiplier = { x = 1.2, y = 0.8 }

-- Multipliers to dictate how much of the frequency comes from base values and how much comes from player speed
local baseBobFrequencyMultiplier = 0.6
local speedBobFrequencyMultiplier = 0.04
local playerSpeed = 0

-- Work variables. Not for tweaking, used when calculating movement in the code down below.
local currentBobFrequencyMultiplier = 0
local targetBobFrequencyMultiplier = 0

local currentBobAmplitudeMultiplier = {x = 0, y = 0}
local targetBobAmplitudeMultiplier = {x = 0, y = 0}

-- Raycast variables
local maxRayDistance = 5000
local targetRayDistance
local currentRayDistance

-- Variables to check when sound should be played
local cosineYprev = 0
local blockSound = false

-- For rotation around the forward axis
local currentZrotation = 0

-- For body inertia
local currentArmForwardRollAngle = 0

-- Peeking variables
local peek = {
    left = false,
    right = false
}
local currentPeekAmount = 0

-- Jumping variables
local currentJumpCameraPitch = 0

-- Sneak functionality
local currentStealthHeight = 0

-- Set up base values for perlin noise
local perlin = require("Modernized 1st Person Experience.loopablePerlin")
perlin.configure({
    loopDuration = 20,
    numSamples = 512
})
-- For evolving perlin noise over time
local timeOffset = 0

-- Name of footstep sounds (these are used to BLOCK sounds)
local footStepName = {
	["footbareleft"] = true,
	["footbareright"] = true,
	["footlightleft"] = true,
	["footlightright"] = true,
	["footmedleft"] = true,
	["footmedright"] = true,
	["footheavyleft"] = true,
	["footheavyright"] = true,
    ["footwaterleft"] = true,
    ["footwaterright"] = true,
}

-- Name on sound events mapped per armor class (these are used to PLAY sounds)
local weightClassFootStepMapping = {
    [tes3.armorWeightClass["light"]] = {left = "FootLightLeft", right = "FootLightRight"},
    [tes3.armorWeightClass["medium"]] = {left = "FootMedLeft", right = "FootMedRight"},
    [tes3.armorWeightClass["heavy"]] = {left = "FootHeavyLeft", right = "FootHeavyRight"}
}

local footStepSounds = {
    bare = {
        left = "FootBareLeft",
        right = "FootBareRight"
    },
    water = {
        left = "FootWaterLeft",
        right = "FootWaterRight"
    }
}

-- Used for checking if vanity mode transition is ongoing or not
local togglePOVisDown = false

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Utility functions
local function createRollRotationMatrix(rotationValue)
    local rotationMatrix = tes3matrix33.new()
    rotationMatrix.x.x = math.cos(rotationValue)
    rotationMatrix.x.y = 0
    rotationMatrix.x.z = -math.sin(rotationValue)

    rotationMatrix.y.x = 0
    rotationMatrix.y.y = 1
    rotationMatrix.y.z = 0

    rotationMatrix.z.x = math.sin(rotationValue)
    rotationMatrix.z.y = 0
    rotationMatrix.z.z = math.cos(rotationValue)
    return rotationMatrix
end

local function createPitchRotationMatrix(rotationValue)
    local rotationMatrix = tes3matrix33.new()
    rotationMatrix.x.x = 1
    rotationMatrix.x.y = 0
    rotationMatrix.x.z = 0

    rotationMatrix.y.x = 0
    rotationMatrix.y.y = math.cos(rotationValue)
    rotationMatrix.y.z = math.sin(rotationValue)

    rotationMatrix.z.x = 0
    rotationMatrix.z.y = -math.sin(rotationValue)
    rotationMatrix.z.z = math.cos(rotationValue)
    return rotationMatrix
end


local function lerp(start, goal, alpha)
    return start + (goal - start)*alpha
end

local function wrapPi(angle)
    angle = angle % (2 * math.pi)  -- Wrap to [0, 2ПЂ]
    if angle > math.pi then
        angle = angle - 2 * math.pi  -- Shift to [-ПЂ, ПЂ]
    end
    return angle
end

local function getEquipmentClass(reference, slot)
    local equipped = tes3.getEquippedItem({ actor = reference, objectType = tes3.objectType.armor, slot = slot })
    if (not equipped) then
        return nil
    end
    return equipped.object.weightClass
end

local function isMoving(mobile)
    return mobile.isMovingForward or mobile.isMovingBack or mobile.isMovingLeft or mobile.isMovingRight
end

local function getQuatAngleDifference(q0, q1)
	return math.acos(math.min(1, math.abs(q0:dot(q1))))
end

local function smoothstep(x)
    return x * x * (3 - 2 * x)
end

local function quadratic(x)
    return x ^ 2
end

--Tried using for the camera too, but not really good. Using for arms only now. Might add MCM to choose smoothing function later on, so keeping it as a generic function
local function smoothRotationStep(fromQuat, toQuat, dt, baseSpeed, curveFn)
    local maxAngle = math.rad(90)
    local angleToTarget = getQuatAngleDifference(fromQuat, toQuat)
    local normalizedAngle = math.min(angleToTarget / maxAngle, 1.0)

    local lowAngleBoostMultiplier = 0.5
    -- Apply curve and boost convergence at low angles
    local curveValue = curveFn(normalizedAngle)
    -- Soft boost near zero
    local lowAngleBoost = 1 + lowAngleBoostMultiplier / (angleToTarget + 0.01)
    local adaptiveSpeed = baseSpeed * curveValue * lowAngleBoost

    local t = 1 - math.exp(-dt * adaptiveSpeed)
    local stepSize = angleToTarget * t
    return fromQuat:rotateTowards(toQuat, stepSize)
end

-- Update stealth settings. Called from many places.
local function updateSneakSettings(e)
    tes3.mobilePlayer.cameraHeight = nil
    this.defaultCameraHeight = tes3.mobilePlayer.cameraHeight
    tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value = this.savedDownSneakGMST

 
    if config.modEnabled then
        if config.sneakCameraSmoothingEnabled then
            tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value = 0
            if tes3.mobilePlayer.isSneaking then

                if tes3.mobilePlayer.animationController.vanityCamera then
                    return
                end

                if tes3.mobilePlayer.animationController.is3rdPerson and config.thirdPersonBobEnabled then
                    tes3.mobilePlayer.cameraHeight = this.defaultCameraHeight * (1 - ((config.sneakCameraHeight * config.sneak3rdPersonHeightMultiplier * 0.01)/(100)))
                else
                    tes3.mobilePlayer.cameraHeight = this.defaultCameraHeight * (1 - ((config.sneakCameraHeight * 0.01)/(100)))
                end
            end
        end
    end
end
 
function addonBridge.getValues()
    local table = {
        config = {}
    }
    -- Make sure there is an updated copy of the relevant config values
    table.config.sneakCameraSmoothingEnabled = config.sneakCameraSmoothingEnabled
    table.config.sneakCameraHeight = config.sneakCameraHeight
    table.config.sneakCameraSmoothing = config.sneakCameraSmoothing
    table.config.modEnabled = config.modEnabled
    return table
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Main function that controls the camera
local function headBob(e)

    local animController = e.animationController

    if config.modEnabled ~= true then
        return
    end

    if tes3.menuMode() then
        return
    end

    if tes3.mobilePlayer.mouseLookDisabled then
        return
    end

    if animController.vanityCamera then
        updateSneakSettings()
        return
    end

    if animController.is3rdPerson then
        if config.thirdPersonBobEnabled ~= true then
            updateSneakSettings()
            return
        end
    end

    if not config.peekEnabled then
        peek.left = false
        peek.right = false
    end
    local isPeeking = peek.left or peek.right

    

    --Save down delta time
    local dt = tes3.worldController.deltaTime

    --Get the needed rotations and vectors
    local r_matrix = e.cameraTransform.rotation:copy()

    local upVector = r_matrix:getUpVector()
    local rightVector = r_matrix:getRightVector()

    --Get positions
    local targetPosition = e.cameraTransform.translation:copy()
    local originalPosition = e.cameraTransform.translation:copy()

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Camera position
    
    -- If no bobbing state, set target bob amplitude to zero so we can smooth back to still
    targetBobAmplitudeMultiplier = { x = 0, y = 0}

    -- Check if we should bob, and set a target amplitude based on state
    if not tes3.mobilePlayer.isJumping and not tes3.mobilePlayer.isFalling then
        if isMoving(tes3.mobilePlayer) then
            if tes3.mobilePlayer.isSneaking then
                targetBobAmplitudeMultiplier.x = sneakingBobAmplitudeMultiplier.x * (config.sneakingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = sneakingBobAmplitudeMultiplier.y * (config.sneakingCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isWalking then
                targetBobAmplitudeMultiplier.x = walkingBobAmplitudeMultiplier.x * (config.walkingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = walkingBobAmplitudeMultiplier.y * (config.walkingCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isRunning then
                targetBobAmplitudeMultiplier.x = runningBobAmplitudeMultiplier.x * (config.runningCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = runningBobAmplitudeMultiplier.y * (config.runningCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isFlying then
                targetBobAmplitudeMultiplier.x = flyingBobAmplitudeMultiplier.x * (config.flyingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = flyingBobAmplitudeMultiplier.y * (config.flyingCustomizableAmplitudeMultiplierY * 0.01)
            elseif tes3.mobilePlayer.isSwimming then
                targetBobAmplitudeMultiplier.x = swimmingBobAmplitudeMultiplier.x * (config.swimmingCustomizableAmplitudeMultiplierX * 0.01)
                targetBobAmplitudeMultiplier.y = swimmingBobAmplitudeMultiplier.y * (config.swimmingCustomizableAmplitudeMultiplierY * 0.01)
            end
        else
            -- For levitating and swimming, just use half the standard values to make a floaty effect
            if tes3.mobilePlayer.isFlying then
                targetBobAmplitudeMultiplier.x = flyingBobAmplitudeMultiplier.x * (config.flyingCustomizableAmplitudeMultiplierX * 0.01) * 0.5
                targetBobAmplitudeMultiplier.y = flyingBobAmplitudeMultiplier.y * (config.flyingCustomizableAmplitudeMultiplierY * 0.01) * 0.5
            elseif tes3.mobilePlayer.isSwimming then
                targetBobAmplitudeMultiplier.x = swimmingBobAmplitudeMultiplier.x * (config.swimmingCustomizableAmplitudeMultiplierX * 0.01) * 0.5
                targetBobAmplitudeMultiplier.y = swimmingBobAmplitudeMultiplier.y * (config.swimmingCustomizableAmplitudeMultiplierY * 0.01) * 0.5
            end
        end
    end

    if isPeeking or togglePOVisDown or tes3.mobilePlayer.isParalyzed then
        targetBobAmplitudeMultiplier.x = 0
        targetBobAmplitudeMultiplier.y = 0
    end

    -- Make sure we can set different amplitude multipliers depending on 1st person or 3rd person
    local cameraDependentMultiplier = 1
    if animController.is3rdPerson and config.thirdPersonBobEnabled then
       cameraDependentMultiplier = config.thirdPersonBobMultiplier * 0.01
    end

    -- Smooth transition from current bob amplitude to target bob amplitude
    currentBobAmplitudeMultiplier.x = lerp(currentBobAmplitudeMultiplier.x, targetBobAmplitudeMultiplier.x * cameraDependentMultiplier, 1 - math.exp(-dt * config.smoothValue))
    currentBobAmplitudeMultiplier.y = lerp(currentBobAmplitudeMultiplier.y, targetBobAmplitudeMultiplier.y * cameraDependentMultiplier, 1 - math.exp(-dt * config.smoothValue))
    
    -- Set target occilation speed based on movement speed
    local speedFrequencyOffset = math.sqrt(playerSpeed) * speedBobFrequencyMultiplier
    -- Lessen the speed when sneaking
    if tes3.mobilePlayer.isSneaking then
        targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.sneakFrequencyMultiplier * 0.01
    -- Swimming and levitating have a bobbing speed also when still and different when moving
    elseif tes3.mobilePlayer.isFlying then
        if isMoving(tes3.mobilePlayer) then
            targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.flyingFrequencyMultiplierMoving * 0.01
        else
            targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.flyingFrequencyMultiplierStill * 0.01
        end
    elseif tes3.mobilePlayer.isSwimming then
        if isMoving(tes3.mobilePlayer) then
            targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.swimmingFrequencyMultiplierMoving * 0.01
        else
            targetBobFrequencyMultiplier = (baseBobFrequencyMultiplier + speedFrequencyOffset) * config.swimmingFrequencyMultiplierStill * 0.01
        end
    else
        targetBobFrequencyMultiplier = baseBobFrequencyMultiplier + speedFrequencyOffset
    end
    -- Smooth transition from current bob frequency to target bob frequency
    currentBobFrequencyMultiplier = lerp(currentBobFrequencyMultiplier, targetBobFrequencyMultiplier, 1 - math.exp(-dt * config.smoothValue))

    -- Increment phase based on smoothed frequency. Multiply frequency with the main tweak variable
    bobPhase.x = bobPhase.x + dt * baseBobFrequency.x * currentBobFrequencyMultiplier * (config.bobCustomizableFrequencyMultiplier * 0.01) * 2 * math.pi
    bobPhase.y = bobPhase.y + dt * baseBobFrequency.y * currentBobFrequencyMultiplier * (config.bobCustomizableFrequencyMultiplier * 0.01)* 2 * math.pi

    -- Wrap phase to avoid overflow
    bobPhase.x = bobPhase.x % (2 * math.pi)
    bobPhase.y = bobPhase.y % (2 * math.pi)

    local bobOscillate = {
        x = math.sin(bobPhase.x),
        y = math.sin(bobPhase.y)
    }

    -- Calculate target positions from the head bobbing
    targetPosition = targetPosition + (rightVector * bobOscillate.x * baseBobAmplitude.x * currentBobAmplitudeMultiplier.x * (config.bobCustomizableAmplitudeMultiplier * 0.01))
    targetPosition = targetPosition + (upVector * bobOscillate.y * baseBobAmplitude.y * currentBobAmplitudeMultiplier.y* (config.bobCustomizableAmplitudeMultiplier * 0.01))

    -- Peek logic
    if config.peekEnabled then
        local peekPadding = config.peekLength *0.25
        local peekSmoothing = config.peekSmoothing
        local peekSmoothingBase = config.peekSmoothing
        local peekSmoothingWhenRayHit = 10000
        local maxPeekAmount = {
            left = config.peekLength,
            right = config.peekLength
        }

        local targetPeekAmount = 0

        -- Important that peek.left is checked first everywhere to sync behavior for rotation and position
        if peek.left then
            local peekHitResultLeft = tes3.rayTest({
                position = originalPosition,
                direction = -r_matrix:getRightVector(),
                maxDistance = config.peekLength + peekPadding,
                root = tes3.dataHandler.worldObjectRoot,
                ignore = { tes3.player }
            })

            if peekHitResultLeft ~= nil then
                if peekHitResultLeft.distance < maxPeekAmount.left + peekPadding then
                    maxPeekAmount.left = peekHitResultLeft.distance - peekPadding
                    peekSmoothing = peekSmoothingWhenRayHit
                end
            end
            
            if currentPeekAmount < maxPeekAmount.left then
                peekSmoothing = peekSmoothingBase
            end
            targetPeekAmount = -maxPeekAmount.left

        elseif peek.right then
            local peekHitResultRight = tes3.rayTest({
                position = originalPosition,
                direction = r_matrix:getRightVector(),
                maxDistance = 80,
                root = tes3.dataHandler.worldObjectRoot,
                ignore = { tes3.player }
            })
            if peekHitResultRight ~= nil then
                if peekHitResultRight.distance < maxPeekAmount.right + peekPadding then
                    maxPeekAmount.right = peekHitResultRight.distance - peekPadding
                    peekSmoothing = peekSmoothingWhenRayHit
                end
            end

            if currentPeekAmount < maxPeekAmount.right then
                peekSmoothing = peekSmoothingBase
            end
            targetPeekAmount = maxPeekAmount.right
        end

        if tes3.mobilePlayer.isParalyzed == false then
            currentPeekAmount = lerp(currentPeekAmount, targetPeekAmount, 1 - math.exp(-dt * peekSmoothing))
        end

        targetPosition = targetPosition + rightVector * currentPeekAmount
    end

    -- Perlin camera noise
    if config.noiseEnabled and tes3.mobilePlayer.isParalyzed == false then
        timeOffset = timeOffset + dt
        local perlinConfig = {
            noiseScale = config.noiseScale,
            noiseAmplitude = config.noiseAmplitude
        }

        if tes3.mobilePlayer.isFlying then 
            perlinConfig.noiseAmplitude = config.noiseAmplitude * config.flyingNoiseAmplitudeMultiplier * 0.01
        elseif tes3.mobilePlayer.isSwimming then
            perlinConfig.noiseAmplitude = config.noiseAmplitude * config.swimmingNoiseAmplitudeMultiplier * 0.01
        end

        perlinConfig.noiseAmplitude = perlinConfig.noiseAmplitude

        local xNoise = perlin.sample(timeOffset, perlinConfig)
        local yNoise = perlin.sampleOffset(timeOffset, 0.25, perlinConfig)

        targetPosition = targetPosition + rightVector * xNoise
        targetPosition = targetPosition + upVector * yNoise
    end

    -- Smooth camera movement when sneaking
    if config.sneakCameraSmoothingEnabled then

        

        local heightMultiplier = 100
        if animController.is3rdPerson then
            heightMultiplier = config.sneak3rdPersonHeightMultiplier
        end

        if tes3.mobilePlayer.isSneaking then

            if config.sneakCameraSmoothingEnabled then
                tes3.mobilePlayer.cameraHeight = lerp(tes3.mobilePlayer.cameraHeight, this.defaultCameraHeight * (1 - ((config.sneakCameraHeight * heightMultiplier * 0.01)/(100))), 1 - math.exp(-dt * config.sneakCameraSmoothing))
            end
        else
            if config.sneakCameraSmoothingEnabled then
                tes3.mobilePlayer.cameraHeight = lerp(tes3.mobilePlayer.cameraHeight, this.defaultCameraHeight, 1 - math.exp(-dt * config.sneakCameraSmoothing))
            end
        end
    end

    -- Apply new position to camera
    local newPosition = targetPosition
    e.cameraTransform.translation = newPosition

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Camera rotation
    -- Raycast to use for eye stabilization post moving the camera. 
    -- Notice we are using the original position (plus peek amount) as start point, which is where the camera would be without this mod, this to keep the crosshair stable.
    local hitResult = tes3.rayTest({
        position = originalPosition + rightVector * currentPeekAmount,
        direction = r_matrix:getForwardVector(),
        maxDistance = maxRayDistance,
        ignore = { tes3.player }
    })

    -- The look at point wants to be at the ray hit position, OR along the ray but the max or min distance
    if hitResult == nil then
        targetRayDistance = maxRayDistance
    else
        if hitResult.distance < config.minimumLookAtDistance then
            targetRayDistance = config.minimumLookAtDistance
        else
            targetRayDistance = hitResult.distance
        end
    end

    if isPeeking then
        targetRayDistance = maxRayDistance
    end

    if currentRayDistance == nil then
        currentRayDistance = targetRayDistance
    else
        -- Smooth the look at point along the ray
        currentRayDistance = lerp(currentRayDistance, targetRayDistance, 1 - math.exp(-dt * 5))
    end

    local lookAtPoint = originalPosition + (r_matrix:getForwardVector() * currentRayDistance)

    --Get the rotation for eye stabilization and store in new rotation matrix
    local lookDirection = lookAtPoint - newPosition
    local newRotation = tes3matrix33.new()
    newRotation:lookAt(lookDirection:normalized(), upVector)

    --Check if we do view rolling, and apply result to the rotation matrix
    local targetZrotation = 0
   
    if config.viewRollingEnabled then
        if tes3.mobilePlayer.isMovingRight then
            targetZrotation = -config.viewRollingMaxAngle
        elseif tes3.mobilePlayer.isMovingLeft then
            targetZrotation = config.viewRollingMaxAngle
        end
    end

    -- Peeking also uses rolling, so checking here how much we roll
    -- Important that peek.left is checked first everywhere to sync behavior for rotation and position
    if config.peekEnabled then
        if peek.left then
            targetZrotation = config.peekRotation
        elseif peek.right then
            targetZrotation = -config.peekRotation
        end
    end

    if tes3.mobilePlayer.isParalyzed == false then
        if config.viewRollingEnabled or config.peekEnabled then
            currentZrotation = lerp(currentZrotation, targetZrotation, 1 - math.exp(-dt * config.viewRollingSmoothing))
            local rollRotation = createRollRotationMatrix(math.rad(currentZrotation))

            newRotation = newRotation * rollRotation
        end
    end
    

    -- Jumping feature (for both 1st and 3rd person)
    if config.jumpEnabled and tes3.mobilePlayer.isParalyzed == false then
        local previousCameraZ = this.previousZPosition or tes3.mobilePlayer.position.z
        local dz = tes3.mobilePlayer.position.z - previousCameraZ

        -- Calculate the jumping speed
        local jumpVelocity = dz / (dt*10000)
        
        -- Detect landing and set pitch target
        if this.fallingLastFrame and not tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isJumping then
            this.landingPitchTarget = config.landingMaxAngle * 0.001 * (math.abs(jumpVelocity) / config.jumpVelocityMax)
            this.landingPitch = 0  -- Start from zero for smooth build-updateLayout 
        end

        if this.landingPitchTarget ~= nil then
            if this.landingPitchTarget > config.landingMaxAngle * 0.001  then
                this.landingPitchTarget = config.landingMaxAngle * 0.001
            end
        end

        -- Ease in toward the impulse target
        this.landingPitch = lerp(this.landingPitch or 0, this.landingPitchTarget or 0, 1 - math.exp(-dt * config.landingEaseAwaySmoothing))

        -- Decay target itself over time
        this.landingPitchTarget = lerp(this.landingPitchTarget or 0, 0, 1 - math.exp(-dt * config.landingEaseBackSmoothing))

        --Assume we are going back to 0
        local targetJumpCameraPitch = this.landingPitch

        -- Check if we just jumped and if we should then set the target pitch based on the trajectory instead
        local scalar = math.abs(jumpVelocity) / config.jumpVelocityMax
        if scalar > 1 then
            scalar = 1
        end
        if tes3.mobilePlayer.isJumping or tes3.mobilePlayer.isFalling then
            -- On our way up
            if jumpVelocity > 0 then
                targetJumpCameraPitch = config.jumpMaxAngle * 0.001 * scalar
            else -- On our way down
                targetJumpCameraPitch = 0
            end
        end

        -- Smooth the actual pitch value
        currentJumpCameraPitch = lerp(currentJumpCameraPitch, targetJumpCameraPitch, 1 - math.exp(-dt * config.jumpAngleSmoothing))

        -- Rotate with the pitch value
        local pitchMatrix = tes3matrix33.new()
        pitchMatrix = createPitchRotationMatrix(math.deg(currentJumpCameraPitch))

        -- Apply to the camera rotation
        newRotation = newRotation * pitchMatrix
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Extra rotation exclusive to 1st person camera
    if tes3.mobilePlayer.is3rdPerson ~= true then

        -- Freelook is active during peeking
        local r = newRotation:toQuaternion()
        local rPrevQuaternion = e.previousCameraTransform.rotation:toQuaternion()

        if this.freeLookMode == true then
            -- Free look mode needs horizontal rotation to be tracked separately, vertical look is handled by the game
            -- That rotation is then added to the standard player camera
            local dz = -tes3.worldController.inputController.mouseState.x * tes3.worldController.mouseSensitivityX
            this.freeLookRotateZ = this.freeLookRotateZ + dz

            this.freeLookRotateZ = wrapPi(this.freeLookRotateZ)

            local q = niQuaternion.new()
            q:fromAngleAxis(this.freeLookRotateZ, tes3vector3.new(0, 0, 1))
            r = q * r

        elseif this.freeLookRotateZ ~= 0 and tes3.mobilePlayer.isParalyzed == false then
            
            this.freeLookRotateZ = lerp(this.freeLookRotateZ, 0, 1 - math.exp(-dt * config.peekSmoothing))
            if math.abs(this.freeLookRotateZ) < 0.01 then
                this.freeLookRotateZ = 0
            end

            local q = niQuaternion.new()
            q:fromAngleAxis(this.freeLookRotateZ, tes3vector3.new(0, 0, 1))
            r = q * r
        end

        -- Camera rotation smoothing (for some reason, without this, the arm smoothing becomes jittery)
        local delta_angle = getQuatAngleDifference(rPrevQuaternion, r) + 1e-3
        local speed = 10 * config.firstPersonCameraSmoothing * delta_angle * delta_angle
        speed = math.max(0.01, speed)
        newRotation = rPrevQuaternion:rotateTowards(r, 1 - math.exp(-dt * speed)):toRotation()
    end

    -- Set the new camera rotation
    if togglePOVisDown == false and tes3.mobilePlayer.isParalyzed == false then
        e.cameraTransform.rotation = newRotation
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Arm follow and body inertia 
    local firstPersonNode = tes3.player1stPerson.sceneNode
    if not animController.is3rdPerson and firstPersonNode ~= nil then
        local armTargetPosition = firstPersonNode.translation:copy()

        -- Do a smaller version of the head bob for the arms. Arm bobbing.
        armTargetPosition = armTargetPosition + (rightVector * bobOscillate.x * baseBobAmplitude.x * currentBobAmplitudeMultiplier.x * (config.armAmplitudeMultiplier*0.01) * (config.bobCustomizableAmplitudeMultiplier * 0.01))
        armTargetPosition = armTargetPosition + (upVector * bobOscillate.y * baseBobAmplitude.y * currentBobAmplitudeMultiplier.y * (config.armAmplitudeMultiplier*0.01) * (config.bobCustomizableAmplitudeMultiplier * 0.01))
        
        armTargetPosition = armTargetPosition + rightVector * currentPeekAmount * 0.9

        local newArmPosition = armTargetPosition
        firstPersonNode.translation = newArmPosition
        
        -- Lock first person Z axis rotation to smoothed camera while keeping gameplay procedural rotation
        -- This removes jitter from the unsmoothed movement controller
        local armCameraRotation = e.armCameraTransform.rotation:copy()
        local proceduralRot = (firstPersonNode.rotation:transpose() * armCameraRotation):transpose()

        if tes3.mobilePlayer.hasFreeAction then
            firstPersonNode.rotation = newRotation * proceduralRot
        end

        if config.bodyInertiaEnabled and firstPersonNode ~= nil then
            -- Body inertia converges on calculated rotation
            if not this.lastBodyInertiaRotation then
                this.lastBodyInertiaRotation = firstPersonNode.rotation:copy()
            end
      
            local armPrevQuaternion = this.lastBodyInertiaRotation:toQuaternion()
            local armRotation = firstPersonNode.rotation

            local prevForward = this.lastBodyInertiaRotation:getForwardVector()
            local frw_armRotation = armRotation:getForwardVector()

            local cross = prevForward:cross(frw_armRotation)
            local sign = cross:dot(upVector)

            local armTargetForwardRollAngle = 0
            if sign < 0.1 then
                armTargetForwardRollAngle = -config.armMaxAngle -- turning left
            elseif sign > 0.1 then
                armTargetForwardRollAngle = config.armMaxAngle -- turning right
            end

            if math.abs(sign) < 0.1 then
                armTargetForwardRollAngle = 0
            end

            currentArmForwardRollAngle = lerp(currentArmForwardRollAngle, armTargetForwardRollAngle, 1 - math.exp(-dt * config.armRollingSmoothing))
            
            local armRollRotation = createRollRotationMatrix(math.rad(currentArmForwardRollAngle))

            armRotation = armRotation * armRollRotation
            firstPersonNode.rotation = armRotation

            local armQuaternion = firstPersonNode.rotation:toQuaternion()
            local smoothedQuat = smoothRotationStep(armPrevQuaternion, armQuaternion, dt, config.armSpeed, smoothstep)
            local newArmRotation = smoothedQuat:toRotation()

            firstPersonNode.rotation = newArmRotation
            this.lastBodyInertiaRotation = newArmRotation
        end
        if this.freeLookMode then
            animController.groundPlaneRotation = this.savedGroundPlaneRotation
        end
        firstPersonNode:update()
    end
     -- Sync the armCameraTransform and the cameraTransform
    e.armCameraTransform = e.cameraTransform

--------------------------------------------------------------------------------------------------------------------------------------------------------------- Handle audio
    -- Get the right footstep, and trigger footstep sounds only on bottom of oscilation
    local cosY = math.cos(bobPhase.y)
    if config.syncFootsteps then
        if animController.is3rdPerson == false then
             if not tes3.mobilePlayer.isJumping and not tes3.mobilePlayer.isFlying and not tes3.mobilePlayer.isSwimming and not tes3.mobilePlayer.isFalling then
                if isMoving(tes3.mobilePlayer) == true and not isPeeking then
                    if cosY == 0 or (cosY > 0 and cosineYprev < 0) then
                        if bobOscillate.y <= 0 then
                            blockSound = false

                            -- Check if we should play water footsteps
                            local currentCell = tes3.player.cell
                            local waterLevel = nil

                            if currentCell.waterLevel ~= nil then
                                waterLevel = currentCell.waterLevel
                            end
                            local playerVerticalPosition = tes3.mobilePlayer.position.z

                            local playWaterSound = false
                            if waterLevel ~= nil then
                                if waterLevel >= playerVerticalPosition then
                                    playWaterSound = true
                                end
                            end

                            -- Fetch the weight class of the boots, and play the correct sound event
                            local bootWeightClass = getEquipmentClass(tes3.player, tes3.armorSlot["boots"])
                            if playWaterSound then
                                if bobOscillate.x <= 0 then
                                    tes3.playSound({sound = footStepSounds.water.left, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                else
                                    tes3.playSound({sound = footStepSounds.water.right, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                end
                            elseif bootWeightClass == nil then
                                if bobOscillate.x <= 0 then
                                    tes3.playSound({sound = footStepSounds.bare.left, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                else
                                    tes3.playSound({sound = footStepSounds.bare.right, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.7})
                                end
                            else
                                if bobOscillate.x <= 0 then
                                    tes3.playSound({sound = weightClassFootStepMapping[bootWeightClass].left, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.75})
                                else
                                    tes3.playSound({sound = weightClassFootStepMapping[bootWeightClass].right, reference = tes3.player, mixChannel = tes3.soundMix.footsteps, volume = 0.75})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Save this frames cosine for check when footsteps play
    cosineYprev = cosY
--------------------------------------------------------------------------------------------------------------------------------------------------------------- Set things to be checked for previous frame values and reset for the next frame
    this.previousZPosition = tes3.mobilePlayer.position.z
    this.fallingLastFrame = tes3.mobilePlayer.isFalling or tes3.mobilePlayer.isJumping

    if togglePOVisDown then
        togglePOVisDown = false
    return
    end
end
event.register(tes3.event.cameraControl, headBob, {priority = 10000})


-- Get the player speed
local function calcMoveSpeedCallback(e)
    if e.reference == tes3.player then
        local isPeeking = peek.left or peek.right
        if isPeeking then
            e.speed = 0
        end
        playerSpeed = e.speed
    end
end
event.register(tes3.event.calcMoveSpeed, calcMoveSpeedCallback, {priority = -10000}) -- Especially want to be after skillful sneaking


-- Disable jumping when peeking, and set justJumped to true so we can start jump animation
local function onJump(e)
    if e.mobile ~= tes3.mobilePlayer then
        return
    end

    if peek.left or peek.right then
        return false
    end
end
event.register(tes3.event.jump, onJump)

-- Block footstep sounds from playing unless allowed
local function onAddSound(e)
    local isPeeking = peek.left or peek.right
    if not isPeeking then
        if config.modEnabled == false or config.syncFootsteps == false then
            return
        end
    end

    if e.isVoiceover then
        return
    end

    if e.reference ~= tes3.player or e.reference == nil then
        return
    end

    if tes3.mobilePlayer.is3rdPerson or tes3.mobilePlayer.animationController.vanityCamera then
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
event.register("addSound", onAddSound, {priority = 1000000})

-- Check to see that we have opened the race menu, then call Update Stealth Settings when closed
local function raceMenuActivated(e)
    e.element:registerAfter(tes3.uiEvent.destroy, updateSneakSettings)
end
event.register(tes3.event.uiActivated, raceMenuActivated, {filter = "MenuRaceSex"})

function common.updateSneakSettingsFromMenu()
    if config.modEnabled and config.sneakCameraSmoothingEnabled then
        tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value = 0
        tes3.messageBox(string.format("Для работы плавного перемещения камеры в режим скрытности GMST высоты камеры установлен в 0.\n\nТекущее значение (%d) сохранено и будет восстановлено при отключении мода или функции \"Плавный переход в режим скрытности\".",this.savedDownSneakGMST))
    else
        tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value = this.savedDownSneakGMST
        tes3.messageBox(string.format("Восстановление GMST высоты камеры скрытности к сохраненному значению %d.",this.savedDownSneakGMST))
    end

    if tes3.onMainMenu() then
         return
    else
        updateSneakSettings()
    end
end

event.register(tes3.event.modConfigReady, function()
    require("Modernized 1st Person Experience.mcm")
	config = require("Modernized 1st Person Experience.config").loaded
end)

local function loadedCallback(e)
    -- Make sure we have the right settings for sneaking (camera height, scale etc.)
    updateSneakSettings()
    -- Make sure everything for peeking is set up
    peek.left = false
    peek.right = false

    -- We turn off the encumbered message during peeking by setting the string to "".
    -- This is due to giving 0 in speed in the calcMoveSpeed event starts the encumbered message.
    -- Here we save down the original string so we can reset it whenever we move out from peeking.
    tes3.findGMST(tes3.gmst.sNotifyMessage59).value = this.encumberedString
    
    -- We are not pressing the button for toggle to vanity mode
    togglePOVisDown = false

    if not e.newGame then
        -- Just a fail safe to make sure we can move when we laod in if something like that was saved down.
        tes3.setPlayerControlState({enabled = true})
    end
end
event.register(tes3.event.loaded, loadedCallback)





event.register(tes3.event.initialized, function ()
    -- Save down GMST so we can reset them later
    this.encumberedString = tes3.findGMST(tes3.gmst.sNotifyMessage59).value
    this.savedDownSneakGMST = tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value
    print("[Modernized 1st Person Experience] initialized")
end, {priority = -100000}) -- Set low to allow other games to affect the GMST before saving them down


-- Whenever we need to check if we are in free look mode or not
local function updateFreeLookMode()
    local isPeeking = peek.left or peek.right

    if isPeeking and not this.freeLookMode then
        this.freeLookMode = true
        this.freeLookRotateZ = 0
        this.savedGroundPlaneRotation = tes3.mobilePlayer.animationController.groundPlaneRotation:copy()
        this.encumberedString = tes3.findGMST(tes3.gmst.sNotifyMessage59).value
        tes3.findGMST(tes3.gmst.sNotifyMessage59).value  = ""
    elseif (not isPeeking and this.freeLookMode) or not config.peekEnabled then
        this.freeLookMode = false
        tes3.findGMST(tes3.gmst.sNotifyMessage59).value = this.encumberedString
    end
end


local function togglePOVkeybindTested(e)
    if not e.result then
        return
    end
    togglePOVisDown = (e.transition == tes3.keyTransition.isDown)
end
event.register('keybindTested', togglePOVkeybindTested, {filter = tes3.keybind.togglePOV})

-- PRESSED Key functionality
local function pressedKey(e)
    if tes3.menuMode() then return end
    if config.peekEnabled then
        if not tes3.mobilePlayer.isJumping and not tes3.mobilePlayer.isFalling and not tes3.mobilePlayer.isSwimming and not tes3.mobilePlayer.isFlying then
            if e.keyCode == config.peekLeftKey.keyCode then
                peek.left = true
            elseif e.keyCode == config.peekRightKey.keyCode then
                peek.right = true
            end
        end
    else
        peek.left = false
        peek.right = false
    end
    updateFreeLookMode()
end
event.register(tes3.event.keyDown, pressedKey)


-- RELEASED Key functionality
local function releasedKey(e)
    if tes3.menuMode() then return end
    if config.peekEnabled then
        if e.keyCode == config.peekLeftKey.keyCode then
                peek.left = false
        elseif e.keyCode == config.peekRightKey.keyCode then
            peek.right = false
        end
    else
        peek.left = false
        peek.right = false
    end
    updateFreeLookMode()
end
event.register(tes3.event.keyUp, releasedKey)