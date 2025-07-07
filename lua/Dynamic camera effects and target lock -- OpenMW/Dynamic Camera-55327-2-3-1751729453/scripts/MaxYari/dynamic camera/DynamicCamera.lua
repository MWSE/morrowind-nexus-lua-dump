local mp = "scripts/MaxYari/dynamic camera/"
local sp = "scripts\\MaxYari\\dynamic camera\\sounds\\"

local omwself = require('openmw.self')
local util = require('openmw.util')
local camera = require('openmw.camera')
local types = require('openmw.types')
local core = require("openmw.core")
local storage = require("openmw.storage")
local I = require('openmw.interfaces')
local animation = require('openmw.animation')
local nearby = require("openmw.nearby")
local debug = require("openmw.debug")
local input = require("openmw.input")
local async = require("openmw.async")
local ui = require("openmw.ui")


local settings = require(mp .. "scripts/settings")
local gutils = require(mp .. "scripts/gutils")
local Tweener = require(mp .. "scripts/tweener")
local shaderUtils = require(mp .. "scripts/shader_utils")

local iMaxActivateDist = core.getGMST("iMaxActivateDist")

local selfActor = gutils.Actor:new(omwself)

local lastTargetSwitchTime = 0
local maxTargetDistance = 15 * 69
local targetSwitchCooldown = 0.3
local targetSwitchMouseVel = 10

local LOSCheckFailTime = 3
local LOSCheckTimer = 0

-- Retrieve settings
local function get100Setting(settings, name)
    return settings:get(name) / 100
end

local soundSettings = storage.playerSection('3FPViewDynamicsSoundSettings')
local visualSettings = storage.playerSection('2FPViewDynamicsVisualSettings')
local visualExtraSettings = storage.playerSection('4FPViewDynamicsVisualExtraSettings')
local controlsSettings = storage.playerSection('1FPViewDynamicsControlsSettings')
local SpeedWindVolume = get100Setting(soundSettings, "SpeedWindVolume")

local ViewmodelIntertiaStrength = get100Setting(visualSettings, "ViewmodelIntertiaStrength")
local HighSpeedEffects = visualSettings:get("HighSpeedEffects")
local HighSpeedEffectStart = visualSettings:get("HighSpeedEffectStart")
local SpeedBlurStrength = get100Setting(visualSettings, "SpeedBlurStrength")
local DofEffects = visualSettings:get("DofEffects")
local CellTransitionDuration = visualSettings:get("CellTransitionDuration")
local SneakVignetteOpacity = get100Setting(visualSettings, "SneakVignetteOpacity")
local BlackBarsRatio = visualExtraSettings:get("BlackBarsRatio")
local StrafeRollStrength = get100Setting(visualExtraSettings, "StrafeRollStrength")
local LookAroundRollStrength = get100Setting(visualExtraSettings, "LookAroundRollStrength")
visualSettings:subscribe(async:callback(function(val)
    ViewmodelIntertiaStrength = get100Setting(visualSettings, "ViewmodelIntertiaStrength")
    HighSpeedEffects = visualSettings:get("HighSpeedEffects")
    HighSpeedEffectStart = visualSettings:get("HighSpeedEffectStart")
    SpeedBlurStrength = get100Setting(visualSettings, "SpeedBlurStrength")
    DofEffects = visualSettings:get("DofEffects")
    CellTransitionDuration = visualSettings:get("CellTransitionDuration")
    SneakVignetteOpacity = get100Setting(visualSettings, "SneakVignetteOpacity")
    BlackBarsRatio = visualExtraSettings:get("BlackBarsRatio")
    StrafeRollStrength = get100Setting(visualExtraSettings, "StrafeRollStrength")
    LookAroundRollStrength = get100Setting(visualExtraSettings, "LookAroundRollStrength")
end))


-- Initialize shaders
local speedShader = shaderUtils.ShaderWrapper:new('speedBlur',{
    uRadius = 0
}, function (self) return self.u.uRadius > 0 end)
local blackScreenShader = shaderUtils.ShaderWrapper:new('blackScreen', {
    opacity = 0
}, function(self) return self.u.opacity > 0 end )
local hexDofShader = shaderUtils.ShaderWrapper:new("hexDoFProgrammable", {
    uDepth = 0,
    uAperture = 0
}, function(self) return DofEffects end) -- Persistent
local sneakVigShader = shaderUtils.ShaderWrapper:new("sneakVignette", {
    uMidPoint = 1
}, function(self) return self.u.uMidPoint < 1 end)
local blackBarsShader = shaderUtils.ShaderWrapper:new("blackBarsProgrammable", {
    ratio = 0
}, function(self) return self.u.ratio > 0 end)


-- TO DO: Later - maybe make targeting height adjustable?
-- TO DO: Later - make jump animation depend on jump strength and landing velocity

--[[ if controlsSettings:get("LockTargetButton") == nil then
    ui.showMessage("Player View Dynamics: Lock Target button not set. You can set it or disable this message in Options->Scripts->Player View Dynamics.")
end ]]

-- Helper functions ------------------------------------------------
--------------------------------------------------------------------
local function jumpBobFunction(t)
    return math.sin((t ^ (2 / 3)) * math.pi)
end

local function shouldDoSpeedEffects()
    local s = HighSpeedEffects
    local o = settings.HighSpeedEffectsOpts
    local grounded = selfActor:isOnGround()
    return s == o.Everywhere or (s == o.Air and not grounded) or (s == o.Ground and grounded)
end

local function isAnimPlaying(groupname)
    local time = animation.getCurrentTime(omwself, groupname)
    return time and time >= 0
end

local function clampAngleDifference(current, saved, maxAngle)
    -- Author: GPT 4o (Copilot)
    local diff = util.normalizeAngle(current - saved)

    -- Adjust the difference to account for angle wrapping

    if math.abs(diff) > maxAngle then
        if diff > 0 then
            return saved + maxAngle
        else
            return saved - maxAngle
        end
    end
    return current
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function slerpAngle(a, b, t)
    local delta =  util.normalizeAngle(b - a)
    return a + delta * t
end

local lockOffsetCache = {}

local function actorLockPos(actor)
    local actorId = actor.recordId
    local actorPosition = actor.position

    -- Default height calculation for the player or fallback
    local bbox = actor:getBoundingBox()

    if not bbox.halfSize.z == 0 or bbox.halfSize.z < 1 then
        return nil
    end

    local actorHeight = bbox.halfSize.z * 2
    local lockOffset = util.vector3(0, 0, actorHeight * 0.82)

    -- If actor is the player, return fallback height directly
    if actorId == "player" then
        -- We already have good enough actorHeight here
    elseif lockOffsetCache[actorId] then
        -- Adjust height based on scale difference if needed
        local cachedData = lockOffsetCache[actorId]
        --print("Get cached",cachedData.offset, cachedData.scale)
        lockOffset = cachedData.offset * (actor.scale / cachedData.scale)
    else
        -- Perform raycasts to find height
        local rayStart = actorPosition - util.vector3(0, 0, 10)
        local rayEnd = actorPosition + util.vector3(0, 0, 1000)
        local castResult = nearby.castRay(rayStart, rayEnd, { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })
        --print(actor,"lock pos Raycast 1 result: ", castResult.hitObject, " hitPos: ", castResult.hitPos)

        if castResult.hitPos then
            local secondRayStart = castResult.hitPos + util.vector3(0, 0, actorHeight * 5)
            local secondRayEnd = castResult.hitPos
            local secondCastResult = nearby.castRay(secondRayStart, secondRayEnd, { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Actor })

            --print(actor,"lock pos Raycast 2 result: ", castResult.hitObject, " hitPos: ", castResult.hitPos)
            if secondCastResult.hitPos then
                -- Calculate height from raycast results
                actorHeight = (secondCastResult.hitPos - castResult.hitPos):length()
                lockOffset = castResult.hitPos - actorPosition + util.vector3(0, 0, actorHeight * 0.82)
            end
        end
    end

    lockOffsetCache[actorId] = { offset = lockOffset, scale = actor.scale }

    return actorPosition + lockOffset
end

local function testLOS(actor)
    local from = actorLockPos(omwself)
    local to = actorLockPos(actor)
    local castResult = nearby.castRay(from, to, {ignore=omwself})
    --print("Testing LOS for: ", actor, " result: ", castResult.hitObject)
    return castResult.hitObject == actor
end

local function findBestTarget(mouseDirection, currentTarget)
    local camPos = camera.getPosition()
    local bestTarget = nil
    local bestScore = math.huge

    --print(mouseDirection, currentTarget)

    for _, actor in ipairs(nearby.actors) do
        if actor == omwself.object or actor == currentTarget then goto continue end

        local actorPos = actor.position
        local lockPos = actorLockPos(actor)

        if not lockPos then goto continue end

        local distanceToSelf = (actorPos - omwself.position):length()

        --print("1",actor, distanceToSelf, maxTargetDistance)

        if distanceToSelf > maxTargetDistance then goto continue end

        local toActor = (lockPos - camPos):normalize()
        local camDir = camera.viewportToWorldVector(util.vector2(0.5,0.5))

        local lookDot = toActor:dot(camDir)
        --print("CamDir",camDir,"toActor",toActor, "lookDot", lookDot)

        --print("2",actor)

        if lookDot < 0 then goto continue end

        --print("3",actor)

        if not actor:isValid() then goto continue end

        local mouseDot = 1
        if mouseDirection then
            local toMouseVec = camera.viewportToWorldVector(util.vector2(0.5,0.5)+mouseDirection)
            local worldMouseDir = toMouseVec - camDir
            mouseDot = toActor:dot(worldMouseDir)
        end

        --print("4",actor)

        if mouseDot < 0 then goto continue end
        if not testLOS(actor) then goto continue end

        --print("5",actor)
        -- Combine distance and direction into a score
        local score
        if currentTarget then
            score = (actorPos - currentTarget.position):length()
        else
            score = -lookDot
        end
        --print(score, actor, lookDot, currentTarget)
        if score < bestScore then
            bestScore = score
            bestTarget = actor
            --print("Best target",actor)
        end

        ::continue::
    end

    return bestTarget
end

local function updateTargetLock(mouseVelocity, currentTarget, dt)
    --print(mouseVelocity:length())
    local mouseDirection = mouseVelocity:length() > targetSwitchMouseVel and mouseVelocity:normalize() or nil
    local now = core.getRealTime()

    -- Check if current target is still ok
    if currentTarget and not currentTarget:isValid() then currentTarget = nil end
    if currentTarget and types.Actor.isDead(currentTarget) then currentTarget = nil end
    if currentTarget and (omwself.position - currentTarget.position):length() >= maxTargetDistance*1.2 then currentTarget = nil end
    if currentTarget and not testLOS(currentTarget) then
        LOSCheckTimer = LOSCheckTimer + dt
        if LOSCheckTimer > LOSCheckFailTime then currentTarget = nil end
    else
        LOSCheckTimer = 0
    end

    local updatedTarget = currentTarget

    if currentTarget then
        -- Handle target switching
        if mouseDirection and now - lastTargetSwitchTime > targetSwitchCooldown then
            local newTarget = findBestTarget(mouseDirection, currentTarget)
            if newTarget then
                updatedTarget = newTarget
                lastTargetSwitchTime = now
            end
        end
    end

    return updatedTarget
end

-------------------------------------------------------------------









local lastOnGround = true
local currentDeltaPitch = 0
local shouldBlendJumpAnim = false

local bobTweener = nil

local cameraYaw = omwself.rotation:getYaw()
local cameraPitch = omwself.rotation:getPitch()
local cameraRoll = 0
local _CamVelocity = 0

local cameraVelSampler = gutils.MeanSampler:new(0.3)
local cameraVelSamplerShort = gutils.MeanSampler:new(0.1)
local velSampler = gutils.MeanSampler:new(0.2)


local isParalyzed = false
local savedParalysedRotation = { pitch = 0, yaw = 0 }
local maxParalysedAngle = 0.33 -- Set the maximum angle difference allowed when paralyzed

local lastPosition = omwself.position;
local lastFrameTs = core.getRealTime();
local airSoundPlaying = false;

local windSoundTimer = nil
local currentWindVolume = 0
local desiredWindVolume = 0
local windSoundStartTime = 0

local isInUI = false;
local badAnimations = {}

local wasSneaking = false
local prevDt = 0.01
local prevCell = omwself.cell

local CamLockTarget = nil

local airSoundFile = sp .. "wind2.wav"
local airSoundDuration = 13.35

local desiredBlurStrength = 0
local blurStrength = 0

local function updateWindSound(dt)
    -- Gradually adjust current volume towards desired volume
    currentWindVolume = gutils.lerp(currentWindVolume, desiredWindVolume, gutils.dtForLerp(dt, 5))
    local timeOffset = (core.getRealTime() - windSoundStartTime) % airSoundDuration

    -- If the sound is playing, restart it every 0.1 seconds with updated volume
    if airSoundPlaying and core.getRealTime() - windSoundStartTime >= 0.1 then
        core.sound.stopSoundFile3d(airSoundFile, omwself)
        core.sound.playSoundFile3d(airSoundFile, omwself, {
            volume = currentWindVolume,
            loop = true,
            timeOffset = timeOffset
        })
    end
end

local function handleSpeedBlur(velSampler, dt)
    local shouldDoSpeed = shouldDoSpeedEffects()

    local blurMin = 0
    local blurMax = 0.1
    local speedMin = HighSpeedEffectStart
    local speedMax = speedMin * 2
    desiredBlurStrength = util.clamp(util.remap(velSampler.mean, speedMin, speedMax, blurMin, blurMax), blurMin, blurMax)
    if not shouldDoSpeed then desiredBlurStrength = 0 end

    -- Gradually adjust blurStrength towards desiredBlurStrength
    blurStrength = gutils.lerp(blurStrength, desiredBlurStrength, gutils.dtForLerp(dt, 5))
    speedShader.u.uRadius = blurStrength * SpeedBlurStrength
end

local function handleCamRoll(velocity, camVelocity, dt)
    local lookDir = gutils.lookDirection(omwself)
    local sideDir = lookDir:cross(util.vector3(0,0,1))
    local sideSpeed = velocity:dot(sideDir)
    local desiredCamRoll = (-sideSpeed / 6000) * StrafeRollStrength - camVelocity * LookAroundRollStrength
    cameraRoll = gutils.lerp(cameraRoll, desiredCamRoll, gutils.dtForLerp(dt, 10))
    camera.setRoll(cameraRoll)
end

local currentExtraPitch = 0
local function startBobAnimation(bobStrengthMult, durationMult)
    local bobDuration = 0.15
    local bobPitch = 1.5

    local downDuration = bobDuration * durationMult
    local upDuration = downDuration * 3 * durationMult

    local startPitch = currentExtraPitch
    local endPitch = math.rad(bobPitch * bobStrengthMult)


    bobTweener = Tweener:new()
    bobTweener:add(downDuration, Tweener.easings.easeOutSine, function(t)
        currentExtraPitch = startPitch + (endPitch - startPitch) * t
        camera.setExtraPitch(currentExtraPitch)
    end)
    bobTweener:add(upDuration, Tweener.easings.easeInOutCubic, function(t)
        currentExtraPitch = (1 - t) * endPitch
        camera.setExtraPitch(currentExtraPitch)
    end)
end

local function onFrame(dt)
    if dt == 0 then return end

    local isFirstPerson = camera.MODE.FirstPerson == camera.getMode()
    local cell = omwself.cell

    local currentPosition = omwself.position
    local deltaPos = currentPosition - lastPosition

    -- Check if paralyzed
    if selfActor:isParalyzed() then
        if not isParalyzed then
            isParalyzed = true
            savedParalysedRotation.pitch = omwself.rotation:getPitch()
            savedParalysedRotation.yaw = omwself.rotation:getYaw()
        end
    else
        isParalyzed = false
        savedParalysedRotation = { pitch = 0, yaw = 0 }
    end

    -- Calculate new camera yaw and pitch
    local newCameraYaw = cameraYaw + omwself.controls.yawChange
    local newCameraPitch = util.clamp(cameraPitch + omwself.controls.pitchChange, -1.57, 1.57)


    local mouseDeltaYaw = omwself.controls.yawChange
    local mouseDeltaPitch = omwself.controls.pitchChange

    local camVelocity = (newCameraYaw - cameraYaw) / dt / 100
    local mouseVelocity = util.vector2(mouseDeltaYaw, mouseDeltaPitch) / prevDt

    if not isInUI and #badAnimations == 0 then
        -- Camera lock ----------------------------------------
        -------------------------------------------------------
        CamLockTarget = updateTargetLock(mouseVelocity, CamLockTarget, dt)

        if CamLockTarget then
            local camPos = camera.getPosition()
            local lockPos = actorLockPos(CamLockTarget)
            local toTarget = (lockPos - camPos):normalize()

            -- Corrected math for targetYaw and targetPitch
            local targetYaw = math.atan2(toTarget.x, toTarget.y)
            local targetPitch = -math.asin(toTarget.z)

            -- Smoothly interpolate yaw and pitch using slerp
            newCameraYaw = slerpAngle(cameraYaw, targetYaw, gutils.dtForLerp(dt, 20))
            newCameraPitch = slerpAngle(cameraPitch, targetPitch, gutils.dtForLerp(dt, 20))

            if I.DynamicReticle then
                I.DynamicReticle.setReticleWorldPos(lockPos)
                I.DynamicReticle.setCurrentEnemy(CamLockTarget)
            end
            hexDofShader.u.uDepth = (lockPos - camPos):length()
            hexDofShader.u.uAperture = gutils.lerp(hexDofShader.u.uAperture, 0.2, gutils.dtForLerp(dt, 5))
            blackBarsShader.u.ratio = gutils.lerp(blackBarsShader.u.ratio, BlackBarsRatio, gutils.dtForLerp(dt, 5))
        else
            local centerPos = util.vector2(0.5, 0.5)
            if I.DynamicReticle then
                I.DynamicReticle.setReticleScreenPos(centerPos)
            end
            hexDofShader.u.uAperture = gutils.lerp(hexDofShader.u.uAperture, 0, gutils.dtForLerp(dt, 5))
            blackBarsShader.u.ratio = gutils.lerp(blackBarsShader.u.ratio, 0, gutils.dtForLerp(dt, 5))
        end

        -- Limit view angles if paralyzed
        if isParalyzed then
            newCameraPitch = clampAngleDifference(newCameraPitch, savedParalysedRotation.pitch, maxParalysedAngle)
            newCameraYaw = clampAngleDifference(newCameraYaw, savedParalysedRotation.yaw, maxParalysedAngle)
        end

        -- View model inertia ------------------------------------------------
        ----------------------------------------------------------------------
        ---
        camVelocity = (newCameraYaw - cameraYaw) / dt / 100

        if CamLockTarget or isFirstPerson then
            camera.setYaw(newCameraYaw)
            omwself.controls.yawChange = 0

            camera.setPitch(newCameraPitch)
            omwself.controls.pitchChange = 0

            cameraYaw = newCameraYaw
            -- Ensure that camera yaw doesn't overflow, otherwise it'll crash
            cameraYaw = util.normalizeAngle(cameraYaw)
            cameraPitch = newCameraPitch
            cameraPitch = util.normalizeAngle(cameraPitch)
            -- Offsetting view model yaw from camera yaw based on rotation velocity


            cameraVelSampler:sample(camVelocity)
            cameraVelSamplerShort:sample(camVelocity)
            local newViewModelYaw = cameraYaw - cameraVelSampler.mean * ViewmodelIntertiaStrength

            -- View model yaw can only be set by providing a delta value, so calculating such
            local deltaModelYaw = newViewModelYaw - omwself.rotation:getYaw()
            local deltaModelPitch = newCameraPitch - omwself.rotation:getPitch()


            if isFirstPerson then
                omwself.controls.yawChange = deltaModelYaw
                omwself.controls.pitchChange = deltaModelPitch
            else
                omwself.controls.yawChange = deltaModelYaw * 20 * dt
                omwself.controls.pitchChange = deltaModelPitch * 20 * dt
            end
        else
            -- We are not controlling camera, but still better save curent cam rotation
            cameraPitch = camera.getPitch()
            cameraYaw = camera.getYaw()
        end
    else
        -- We are not controlling camera, but still better save curent cam rotation
        cameraPitch = camera.getPitch()
        cameraYaw = camera.getYaw()
    end

    _CamVelocity = camVelocity
end

local function onUpdate(dt)
    if dt == 0 then return end

    local cell = omwself.cell
    local currentPosition = omwself.position
    local deltaPos = currentPosition - lastPosition
    local wasTeleported = deltaPos:length() >= 1000 or (cell ~= prevCell and not (cell.isExterior and prevCell.isExterior)) -- possibly also with cell change?
    local velocity = deltaPos / prevDt
    --print("DPos: ", deltaPos:length(), "Vel:",velocity:length(), "dt:", dt)

    -- If deltaPos is very high - probably we got teleported - shouldn't consider this a valid velocity sample then
    if not wasTeleported then velSampler:sample(velocity:length()) end

    -- Epoch's speed blur shader --------------------------
    -------------------------------------------------------
    handleSpeedBlur(velSampler, dt)
    -- Adjust camera roll based on strafe velocity and looking around
    --------------------------------------------------------
    if not wasTeleported then
        handleCamRoll(velocity, _CamVelocity, dt)
    end

    -- Wareya's hex dof on cell transition ---------------
    ------------------------------------------------------
    if wasTeleported then
        if hexDofShader.tweener and hexDofShader.tweener.playing then hexDofShader.tweener.canPlay = true end
    end

    --cancel transition if wasnt teleported (got false positive on door press, e.g locked door)
    if hexDofShader.tweener and hexDofShader.tweener.playing and not wasTeleported and not hexDofShader.tweener.canPlay then
        hexDofShader.tweener:finish()
        blackScreenShader.tweener:finish()
    end


    -- Nimlos's speed wind sound -------------------------------------------
    ------------------------------------------------------------------------

    if blurStrength > 0 then
        desiredWindVolume = 10 * SpeedWindVolume * blurStrength
        if not airSoundPlaying then
            core.sound.playSoundFile3d(airSoundFile, omwself, {
                volume = currentWindVolume,
                loop = true,
                timeOffset = 0
            })
            airSoundPlaying = true
            windSoundStartTime = core.getRealTime()
        end
    else
        desiredWindVolume = 0
        if airSoundPlaying and currentWindVolume <= 0.01 then
            core.sound.stopSoundFile3d(airSoundFile, omwself)
            airSoundPlaying = false
        end
    end

    updateWindSound(dt)
    -- if blurStrength > 0 then print("HIGH SPEED!") end

    -- Check if view inertia blocking animation is still playing ---------
    for i = #badAnimations, 1, -1 do -- Iterate backwards to safely remove items
        local groupname = badAnimations[i]
        if not isAnimPlaying(groupname) then
            -- print("Animation stopped: " .. groupname)
            table.remove(badAnimations, i)
        end
    end

    -- Check if was teleported
    if wasTeleported then
        cameraPitch = omwself.rotation:getPitch()
        cameraYaw = omwself.rotation:getYaw()
        camera.setYaw(cameraYaw)
        camera.setPitch(cameraPitch)
    end

    -- Jump camera animation -----------------------------------------------------
    ------------------------------------------------------------------------------
    if selfActor.isOnGround() ~= lastOnGround then
        -- Just jumped or just landed
        shouldBlendJumpAnim = currentDeltaPitch ~= 0
        local bobDurationMult = 1
        local bobStrengthMult = 1

        if selfActor.isOnGround() then
            -- We have landed
            local velScale = 1
            local minVel = 400
            local maxVel = 1000
            local minScale = 1
            local maxScale = 3
            velScale = util.remap(velSampler.mean, minVel, maxVel, minScale, maxScale)
            velScale = util.clamp(velScale, minScale, maxScale)

            bobStrengthMult = 1 * get100Setting(visualSettings, "LandBobStrength") * velScale
            bobDurationMult = 1 + (velScale-1)/5

            startBobAnimation(bobStrengthMult, bobDurationMult)
        else
            -- We have jumped
            bobDurationMult = 1
            bobStrengthMult = 1 * get100Setting(visualSettings, "JumpBobStrength")
            startBobAnimation(bobStrengthMult, bobDurationMult)
        end
    end
    lastOnGround = selfActor.isOnGround()

    if bobTweener then
        bobTweener:tick(dt)
        if not bobTweener.playing then
            bobTweener = nil
            camera.setExtraPitch(0) -- Reset pitch after animation
            currentExtraPitch = 0
        end
    end

    -- Sneaking vignette -------------------------------
    ----------------------------------------------------
    if omwself.controls.sneak then
        sneakVigShader.u.uMidPoint = gutils.lerp(sneakVigShader.u.uMidPoint, 1 - SneakVignetteOpacity, gutils.dtForLerp(dt, 5))
    else
        sneakVigShader.u.uMidPoint = gutils.lerp(sneakVigShader.u.uMidPoint, 1, gutils.dtForLerp(dt, 5))
    end

    -- Taking care of shaders -------------------------------------
    ---------------------------------------------------------------
    for _, shader in pairs(shaderUtils.instances) do
        if shader.tweener then shader.tweener:tick(dt) end
        if shader:shouldBeEnabled() then
            shader:enable()
        end
    end

    lastPosition = currentPosition
    prevDt = dt
    prevCell = cell
end


-- Detecting problematic animations -----------
-----------------------------------------------
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    -- print("New animation started! " .. groupname .. " : " .. options.startKey .. " --> " .. options.stopKey)
    -- Detect being staggered
    if groupname == "knockdown" or groupname == "knockout" then
        table.insert(badAnimations, groupname)
    end
end)

-- Start playing cell transition animation when attempt to open a door is detected,
-- If we use on activate event in global script itself - it will arrive in player script too late.
input.registerTriggerHandler("Activate", async:callback(function(val)
    local lookDir = camera.viewportToWorldVector(util.vector2(0.5,0.5))
    local camPos = camera.getPosition()
    local camDist = camera.getThirdPersonDistance()
    local activationDist = camDist + iMaxActivateDist
    local castRes = nearby.castRenderingRay(camPos, camPos + lookDir*activationDist,{ignore=omwself, collisionType=nearby.COLLISION_TYPE.Door})

    if castRes.hitObject and castRes.hitObject.type == types.Door and types.Door.isTeleport(castRes.hitObject) and selfActor:canOpenDoor(castRes.hitObject) then

        hexDofShader.tweener = Tweener:new()
        blackScreenShader.tweener = Tweener:new()

        local blackScreenDuration = math.max(CellTransitionDuration * 0.66,0.1)
        if CellTransitionDuration == 0 then blackScreenDuration = 0 end
        blackScreenShader.tweener:add(blackScreenDuration, Tweener.easings.linear, function(t)
            blackScreenShader.u.opacity = 1-t
        end)

        hexDofShader.tweener:add(CellTransitionDuration, Tweener.easings.easeOutCubic, function(t)
            hexDofShader.u.uAperture = 0.1*(1-t)
            hexDofShader.u.uDepth = 1
        end)
    end
end))

input.registerTriggerHandler("LockTarget", async:callback(function(val)
    if CamLockTarget then
        CamLockTarget = nil -- Release target
    else
        CamLockTarget = findBestTarget(nil, nil) -- Lock onto the closest actor
    end
end))

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame
    },
    eventHandlers = {
        UiModeChanged = function(e)
            -- Turn off inertia when UI window is active. Idea courtesy of taitechnic.
            if e.newMode then
                isInUI = true
            else
                isInUI = false
            end
        end
    },
    interfaceName = "DynamicCamera",
    interface = {
        version=1.0,
        shaders=shaderUtils.instances
    }
}
