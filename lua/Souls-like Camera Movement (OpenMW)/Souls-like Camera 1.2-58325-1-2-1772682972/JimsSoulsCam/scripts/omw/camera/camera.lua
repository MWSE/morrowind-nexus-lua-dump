local camera = require('openmw.camera')
local core = require('openmw.core')
local debug = require('openmw.debug')
local input = require('openmw.input')
local util = require('openmw.util')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Actor = require('openmw.types').Actor
local Player = require('openmw.types').Player

local MODE = camera.MODE

local function clampScalar(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function clamp01(x)
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

local function expAlpha(rate, dt)
    if not dt or dt <= 0 then return 1 end
    return 1 - math.exp(-rate * dt)
end

local function wrapPi(a)
    while a >  math.pi do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end

local function softDeadzone(x, dz)
    local ax = math.abs(x)
    if ax <= dz then return 0 end
    local t = (ax - dz) / (1 - dz)
    t = clampScalar(t, 0, 1)
    local y = t * t
    return (x >= 0) and y or -y
end

input.registerAction {
    key = 'TogglePOV',
    l10n = 'OMWControls',
    name = 'TogglePOV_name',
    description = 'TogglePOV_description',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
}

input.registerAction {
    key = 'Zoom3rdPerson',
    l10n = 'OMWControls',
    name = 'Zoom3rdPerson_name',
    description = 'Zoom3rdPerson_description',
    type = input.ACTION_TYPE.Number,
    defaultValue = 0,
}

local settings = storage.playerSection('SettingsOMWCameraThirdPerson')
local head_bobbing = require('scripts.omw.camera.head_bobbing')
local pov_auto_switch = require('scripts.omw.camera.first_person_auto_switch')

local move360 = (function()
    local core2 = require('openmw.core')
    local camera2 = require('openmw.camera')
    local input2 = require('openmw.input')
    local self2 = require('openmw.self')
    local util2 = require('openmw.util')
    local I2 = require('openmw.interfaces')

    local Actor2 = require('openmw.types').Actor
    local Player2 = require('openmw.types').Player

    local MODE2 = camera2.MODE

    local active = false

    local M2 = {
        enabled = false,
        turnSpeed = 5,
    }

    local function turnOn()
        I2.Camera.disableStandingPreview()
        active = true
    end

    local function turnOff()
        I2.Camera.enableStandingPreview()
        active = false
        if camera2.getMode() == MODE2.Preview then
            camera2.setMode(MODE2.ThirdPerson)
        end
    end

    local function processZoom3rdPerson()
        if
            not Player2.getControlSwitch(self2, Player2.CONTROL_SWITCH.ViewMode) or
            not Player2.getControlSwitch(self2, Player2.CONTROL_SWITCH.Controls) or
            input2.getBooleanActionValue('TogglePOV') or
            not I2.Camera.isModeControlEnabled() or
            not I2.Camera.isZoomEnabled()
        then
            return
        end
        local Zoom3rdPerson = input2.getNumberActionValue('Zoom3rdPerson')
        if Zoom3rdPerson > 0 and camera2.getMode() == MODE2.Preview
            and I2.Camera.getBaseThirdPersonDistance() == 30 then
            self2.controls.yawChange = camera2.getYaw() - self2.rotation:getYaw()
            camera2.setMode(MODE2.FirstPerson)
        elseif Zoom3rdPerson < 0 and camera2.getMode() == MODE2.FirstPerson then
            camera2.setMode(MODE2.Preview)
            I2.Camera.setBaseThirdPersonDistance(30)
        end
    end

    function M2.onFrame(dt)
        if core2.isWorldPaused() then return end

        -- MOD: keep active even when weapon/spell is readied.
        local newActive = M2.enabled

        if newActive and not active then
            turnOn()
        elseif not newActive and active then
            turnOff()
        end
        if not active then return end

        processZoom3rdPerson()
        if camera2.getMode() == MODE2.Static then return end
        if camera2.getMode() == MODE2.ThirdPerson then camera2.setMode(MODE2.Preview) end

        if camera2.getMode() == MODE2.Preview and not input2.getBooleanActionValue('TogglePOV') then
            camera2.showCrosshair(camera2.getFocalPreferredOffset():length() > 5)

            local move = util2.vector2(self2.controls.sideMovement, self2.controls.movement)
            local yawDelta = camera2.getYaw() - self2.rotation:getYaw()
            move = move:rotate(-yawDelta)

            self2.controls.sideMovement = move.x
            self2.controls.movement = move.y

            self2.controls.pitchChange = camera2.getPitch() * math.cos(yawDelta) - self2.rotation:getPitch()

            if move:length() > 0.05 then
                local delta = math.atan2(move.x, move.y)
                local maxDelta = math.max(delta, 1) * M2.turnSpeed * dt
                self2.controls.yawChange = util2.clamp(delta, -maxDelta, maxDelta)
            else
                self2.controls.yawChange = 0
            end
        end
    end

    return M2
end)()


local third_person = (function()
    local camera2 = require('openmw.camera')
    local util2 = require('openmw.util')
    local self2 = require('openmw.self')
    local nearby2 = require('openmw.nearby')
    local async2 = require('openmw.async')
    local storage2 = require('openmw.storage')

    local Actor2 = require('openmw.types').Actor

    local settings2 = storage2.playerSection('SettingsOMWCameraThirdPerson')

    local MODE2 = camera2.MODE
    local STATE2 = { RightShoulder = 0, LeftShoulder = 1, Combat = 2, Swimming = 3 }

    local M2 = {
        baseDistance = 192,
        preferredDistance = 0,
        standingPreview = false,
        noOffsetControl = {},
    }

    local viewOverShoulder, autoSwitchShoulder
    local shoulderOffset
    local zoomOutWhenMoveCoef

    local defaultShoulder, rightShoulderOffset, leftShoulderOffset
    local combatOffset = util2.vector2(0, 15)

    local noThirdPersonLastFrame = true

    local function updateSettings()
        viewOverShoulder = settings2:get('viewOverShoulder')
        autoSwitchShoulder = settings2:get('autoSwitchShoulder')
        shoulderOffset = util2.vector2(settings2:get('shoulderOffsetX'),
            settings2:get('shoulderOffsetY'))
        zoomOutWhenMoveCoef = settings2:get('zoomOutWhenMoveCoef')

        defaultShoulder = (shoulderOffset.x > 0 and STATE2.RightShoulder) or STATE2.LeftShoulder
        rightShoulderOffset = util2.vector2(math.abs(shoulderOffset.x), shoulderOffset.y)
        leftShoulderOffset = util2.vector2(-math.abs(shoulderOffset.x), shoulderOffset.y)
        noThirdPersonLastFrame = true
    end
    updateSettings()
    settings2:subscribe(async2:callback(updateSettings))

    local state = defaultShoulder

    local function ray(from, angle, limit)
        local to = from + util2.transform.rotateZ(angle) * util2.vector3(0, limit, 0)
        local res = nearby2.castRay(from, to, { collisionType = camera2.getCollisionType() })
        if res.hit then
            return (res.hitPos - from):length()
        else
            return limit
        end
    end

    local function trySwitchShoulder()
        local limitToSwitch = 120
        local limitToSwitchBack = 300

        local pos = camera2.getTrackedPosition()
        local rayRight = ray(pos, camera2.getYaw() + math.rad(90), limitToSwitchBack + 1)
        local rayLeft = ray(pos, camera2.getYaw() - math.rad(90), limitToSwitchBack + 1)
        local rayRightForward = ray(pos, camera2.getYaw() + math.rad(30), limitToSwitchBack + 1)
        local rayLeftForward = ray(pos, camera2.getYaw() - math.rad(30), limitToSwitchBack + 1)

        local distRight = math.min(rayRight, rayRightForward)
        local distLeft = math.min(rayLeft, rayLeftForward)

        if distLeft < limitToSwitch and distRight > limitToSwitchBack then
            state = STATE2.RightShoulder
        elseif distRight < limitToSwitch and distLeft > limitToSwitchBack then
            state = STATE2.LeftShoulder
        elseif distRight > limitToSwitchBack and distLeft > limitToSwitchBack then
            state = defaultShoulder
        end
    end

    local function calculateDistance(smoothedSpeed)
        local smoothedSpeedSqr = smoothedSpeed * smoothedSpeed
        return (M2.baseDistance + math.max(camera2.getPitch(), 0) * 50
            + smoothedSpeedSqr / (smoothedSpeedSqr + 300 * 300) * zoomOutWhenMoveCoef)
    end

    local function updateState()
        local mode = camera2.getMode()
        local oldState = state
        if Actor2.getStance(self2) ~= Actor2.STANCE.Nothing and mode == MODE2.ThirdPerson then
            state = STATE2.Combat
        elseif Actor2.isSwimming(self2) then
            state = STATE2.Swimming
        elseif oldState == STATE2.Combat or oldState == STATE2.Swimming then
            state = defaultShoulder
        elseif not state then
            state = defaultShoulder
        end
        if (mode == MODE2.ThirdPerson or Actor2.getCurrentSpeed(self2) > 0 or state ~= oldState or noThirdPersonLastFrame)
            and (state == STATE2.LeftShoulder or state == STATE2.RightShoulder) then
            if autoSwitchShoulder then
                trySwitchShoulder()
            else
                state = defaultShoulder
            end
        end
        if oldState ~= state or noThirdPersonLastFrame then
            if mode == MODE2.Vanity then
                camera2.setFocalTransitionSpeed(0.2)
            elseif (oldState == STATE2.Combat or state == STATE2.Combat) and
                (mode ~= MODE2.Preview or M2.standingPreview) then
                camera2.setFocalTransitionSpeed(5.0)
            else
                camera2.setFocalTransitionSpeed(1.0)
            end

            if state == STATE2.RightShoulder then
                camera2.setFocalPreferredOffset(rightShoulderOffset)
            elseif state == STATE2.LeftShoulder then
                camera2.setFocalPreferredOffset(leftShoulderOffset)
            else
                camera2.setFocalPreferredOffset(combatOffset)
            end
        end
    end


    local forwardToDist = 0.125
    local maxLagDist    = 50000.0
    local followRateDist = 4.0

    local velLowpassRate = 12.0
    local dtInvalid = 0.10

    local pitchTightenStart = math.rad(20)
    local pitchTightenEnd   = math.rad(70)
    local minPitchScale     = 0.15

    local lagDist = 0.0
    local lastPos = nil
    local velRaw = util2.vector3(0, 0, 0)
    local velLP  = util2.vector3(0, 0, 0)

    local function resetZoomLag()
        lastPos = self2.position
        velRaw = util2.vector3(0, 0, 0)
        velLP  = util2.vector3(0, 0, 0)
        lagDist = 0.0
    end

    local function updateVelocity(dt)
        local p = self2.position
        if not lastPos then
            lastPos = p
            velRaw = util2.vector3(0, 0, 0)
            velLP  = util2.vector3(0, 0, 0)
            return velRaw, velLP
        end

        if not dt or dt <= 0 or dt > dtInvalid then
            lastPos = p
            velRaw = util2.vector3(0, 0, 0)
        else
            local dp = p - lastPos
            lastPos = p
            velRaw = dp / dt
        end

        local aLP = expAlpha(velLowpassRate, dt or 0)
        velLP = velLP + (velRaw - velLP) * aLP

        return velRaw, velLP
    end

    local function computeZoomLagTarget(dt)
        local v, _ = updateVelocity(dt)

        local yaw = camera2.getYaw()
        local forward = util2.transform.rotateZ(yaw) * util2.vector3(0, 1, 0)

        local vPlanar = util2.vector3(v.x, v.y, 0)
        local vForward = vPlanar:dot(forward)

        local pitchAbs = math.abs(camera2.getPitch())
        local t = 0.0
        if pitchAbs <= pitchTightenStart then
            t = 0.0
        elseif pitchAbs >= pitchTightenEnd then
            t = 1.0
        else
            t = (pitchAbs - pitchTightenStart) / (pitchTightenEnd - pitchTightenStart)
            t = clamp01(t)
        end
        local pitchScale = (1.0 - t) + (minPitchScale * t)

        return clampScalar(vForward * forwardToDist * pitchScale, -maxLagDist, maxLagDist)
    end

    function M2.update(dt, smoothedSpeed)
        local mode = camera2.getMode()
        if mode == MODE2.FirstPerson or mode == MODE2.Static then
            noThirdPersonLastFrame = true
            return
        end
        if not viewOverShoulder then
            M2.preferredDistance = M2.baseDistance
            camera2.setPreferredThirdPersonDistance(M2.baseDistance)
            if noThirdPersonLastFrame then
                camera2.setFocalPreferredOffset(util2.vector2(0, 0))
                camera2.instantTransition()
                noThirdPersonLastFrame = false
                resetZoomLag()
            end
            return
        end

        if not next(M2.noOffsetControl) then
            updateState()
        else
            state = nil
        end

        local base = calculateDistance(smoothedSpeed)

        local d = dt or 0.016
        local tDist = computeZoomLagTarget(d)
        local aDist = expAlpha(followRateDist, d)
        lagDist = lagDist + (tDist - lagDist) * aDist

        M2.preferredDistance = base + lagDist

        if noThirdPersonLastFrame then
            camera2.setPreferredThirdPersonDistance(M2.preferredDistance)
            camera2.instantTransition()
            noThirdPersonLastFrame = false
            resetZoomLag()
        else
            local maxIncrease = d * (100 + M2.baseDistance)
            camera2.setPreferredThirdPersonDistance(math.min(
                M2.preferredDistance, camera2.getThirdPersonDistance() + maxIncrease))
        end
    end

    return M2
end)()


local previewIfStandStill = false
local showCrosshairInThirdPerson = false
local slowViewChange = false

local function updateSettings()
    previewIfStandStill = settings:get('previewIfStandStill')
    showCrosshairInThirdPerson = settings:get('viewOverShoulder')
    camera.allowCharacterDeferredRotation(settings:get('deferredPreviewRotation'))
    local collisionType = util.bitAnd(nearby.COLLISION_TYPE.Default, util.bitNot(nearby.COLLISION_TYPE.Actor))
    collisionType = util.bitOr(collisionType, nearby.COLLISION_TYPE.Camera)
    if settings:get('ignoreNC') then
        collisionType = util.bitOr(collisionType, nearby.COLLISION_TYPE.VisualOnly)
    end
    camera.setCollisionType(collisionType)
    move360.enabled = settings:get('move360')
    move360.turnSpeed = settings:get('move360TurnSpeed')
    pov_auto_switch.enabled = settings:get('povAutoSwitch')
    slowViewChange = settings:get('slowViewChange')
end

local primaryMode

local noModeControl = {}
local noStandingPreview = {}
local noHeadBobbing = {}
local noZoom = {}

local function init()
    camera.setFieldOfView(camera.getBaseFieldOfView())
    if camera.getMode() == MODE.FirstPerson then
        primaryMode = MODE.FirstPerson
    else
        primaryMode = MODE.ThirdPerson
        camera.setMode(MODE.ThirdPerson)
    end
    updateSettings()
end

settings:subscribe(async:callback(updateSettings))

local smoothedSpeed = 0
local previewTimer = 0

local function updatePOV(dt)
    local switchLimit = 0.25
    if input.getBooleanActionValue('TogglePOV') and Player.getControlSwitch(self, Player.CONTROL_SWITCH.ViewMode) then
        previewTimer = previewTimer + dt
        if primaryMode == MODE.ThirdPerson or previewTimer >= switchLimit then
            third_person.standingPreview = false
            camera.setMode(MODE.Preview)
        end
    elseif previewTimer > 0 then
        if previewTimer <= switchLimit then
            if primaryMode == MODE.FirstPerson then
                primaryMode = MODE.ThirdPerson
            else
                primaryMode = MODE.FirstPerson
            end
        end
        camera.setMode(primaryMode)
        if camera.getMode() == MODE.Preview then
            camera.setMode(MODE.ThirdPerson)
            camera.setMode(MODE.FirstPerson)
        end
        previewTimer = 0
    end
end

local idleTimer = 0
local vanityDelay = core.getGMST('fVanityDelay')

local function updateVanity(dt)
    local vanityAllowed = Player.getControlSwitch(self, Player.CONTROL_SWITCH.VanityMode)
    if vanityAllowed and idleTimer > vanityDelay and camera.getMode() ~= MODE.Vanity then
        camera.setMode(MODE.Vanity)
    end
    if camera.getMode() == MODE.Vanity then
        if not vanityAllowed or idleTimer == 0 then
            camera.setMode(primaryMode)
        else
            camera.setYaw(camera.getYaw() + math.rad(3) * dt)
        end
    end
end

local function updateSmoothedSpeed(dt)
    local speed = Actor.getCurrentSpeed(self)
    speed = speed / (1 + speed / 500)
    local maxDelta = 300 * dt
    smoothedSpeed = smoothedSpeed + util.clamp(speed - smoothedSpeed, -maxDelta, maxDelta)
end

local minDistance = 30
local maxDistance = 800

local function zoom(delta)
    if not Player.getControlSwitch(self, Player.CONTROL_SWITCH.ViewMode) or
        not Player.getControlSwitch(self, Player.CONTROL_SWITCH.Controls) or
        camera.getMode() == MODE.Static or next(noZoom) then
        return
    end
    if camera.getMode() ~= MODE.FirstPerson then
        local obstacleDelta = third_person.preferredDistance - camera.getThirdPersonDistance()
        if delta > 0 and third_person.baseDistance == minDistance and
            (camera.getMode() ~= MODE.Preview or third_person.standingPreview) and not next(noModeControl) then
            primaryMode = MODE.FirstPerson
            camera.setMode(primaryMode)
        elseif delta > 0 or obstacleDelta < -delta then
            third_person.baseDistance = util.clamp(third_person.baseDistance - delta - obstacleDelta, minDistance,
                maxDistance)
        end
    elseif delta < 0 and not next(noModeControl) then
        primaryMode = MODE.ThirdPerson
        camera.setMode(primaryMode)
        third_person.baseDistance = minDistance
    end
end

local function updateStandingPreview()
    local mode = camera.getMode()
    if not previewIfStandStill or next(noStandingPreview)
        or mode == MODE.FirstPerson or mode == MODE.Static or mode == MODE.Vanity then
        third_person.standingPreview = false
        return
    end
    local standingStill = Actor.getCurrentSpeed(self) == 0 and Actor.getStance(self) == Actor.STANCE.Nothing
    if standingStill and mode == MODE.ThirdPerson then
        third_person.standingPreview = true
        camera.setMode(MODE.Preview)
    elseif not standingStill and third_person.standingPreview then
        third_person.standingPreview = false
        camera.setMode(primaryMode)
    end
end

local function updateCrosshair()
    camera.showCrosshair(
        camera.getMode() == MODE.FirstPerson or
        (showCrosshairInThirdPerson and (camera.getMode() == MODE.ThirdPerson or third_person.standingPreview)))
end

local function updateIdleTimer(dt)
    if not input.isIdle() then
        idleTimer = 0
    elseif self.controls.movement ~= 0 or self.controls.sideMovement ~= 0 or self.controls.jump or self.controls.use ~= 0 then
        idleTimer = 0
    else
        idleTimer = idleTimer + dt
    end
end


local MOVE_STEER_ENABLED = true
local MOVE_STEER_YAW_SPEED = math.rad(30)
local MOVE_STEER_FOLLOW_RATE = 6.0
local MOVE_STEER_DZ = 0.12

local moveSteerYawRateLP = 0.0

local function applyMovementSteerYaw(dt)
    if not MOVE_STEER_ENABLED then
        moveSteerYawRateLP = 0.0
        return
    end

    local mode = camera.getMode()

    local queued = camera.getQueuedMode()
    if mode ~= MODE.ThirdPerson and mode ~= MODE.Preview and mode ~= MODE.Vanity then
        moveSteerYawRateLP = 0.0
        return
    end
    if queued == MODE.FirstPerson or mode == MODE.FirstPerson then
        moveSteerYawRateLP = 0.0
        return
    end

    local d = dt or 0.016
    d = clampScalar(d, 0.001, 0.05)

    local sx = softDeadzone(clampScalar(self.controls.sideMovement, -1, 1), MOVE_STEER_DZ)

    local targetYawRate = sx * MOVE_STEER_YAW_SPEED

    local a = expAlpha(MOVE_STEER_FOLLOW_RATE, d)
    moveSteerYawRateLP = moveSteerYawRateLP + (targetYawRate - moveSteerYawRateLP) * a

    camera.setYaw(wrapPi(camera.getYaw() + moveSteerYawRateLP * d))
end

local OFFSET_X_ENABLED = true
local OFFSET_X_PER_INPUT = 30.0
local OFFSET_X_MAX = 180.0
local OFFSET_X_FOLLOW = 2.0
local OFFSET_X_RETURN = 2.0
local OFFSET_X_DZ = 0.10

local offsetX = 0.0

local function applyHorizontalFocalOffset(dt)
    if not OFFSET_X_ENABLED then
        offsetX = 0.0
        return
    end

    local mode = camera.getMode()
    local queued = camera.getQueuedMode()
    if mode ~= MODE.ThirdPerson and mode ~= MODE.Preview and mode ~= MODE.Vanity then
        offsetX = 0.0
        return
    end
    if queued == MODE.FirstPerson or mode == MODE.FirstPerson then
        offsetX = 0.0
        return
    end

    local d = clampScalar(dt or 0.016, 0.001, 0.05)

    local sx = clampScalar(self.controls.sideMovement, -1, 1)
    if math.abs(sx) < OFFSET_X_DZ then sx = 0 end

    local targetX = 0.0
    if sx ~= 0.0 then
        targetX = clampScalar(-sx * OFFSET_X_PER_INPUT, -OFFSET_X_MAX, OFFSET_X_MAX)
    end

    local rate = (sx ~= 0.0) and OFFSET_X_FOLLOW or OFFSET_X_RETURN
    local a = clampScalar(d * rate, 0.0, 1.0)
    offsetX = offsetX + (targetX - offsetX) * a

    camera.setFocalTransitionSpeed(1000.0)

    local base = camera.getFocalPreferredOffset()
    camera.setFocalPreferredOffset(util.vector2(offsetX, base.y))
end

local OFFSET_Y_ENABLED = true
local OFFSET_Y_PER_VZ  = 0.17
local OFFSET_Y_FOLLOW  = 4.0
local OFFSET_Y_RETURN  = 4.0
local OFFSET_Y_MAX     = 50.0
local OFFSET_Y_VZ_DZ   = 0.0

local yAbs     = 0.0
local lastPosZ = nil

local function applyVerticalFocalOffset(dt)
    if not OFFSET_Y_ENABLED then
        yAbs = 0.0
        lastPosZ = nil
        local cur = camera.getFocalPreferredOffset()
        camera.setFocalPreferredOffset(util.vector2(cur.x, 0.0))
        return
    end

    local mode = camera.getMode()
    local queued = camera.getQueuedMode()
    if mode ~= MODE.ThirdPerson and mode ~= MODE.Preview and mode ~= MODE.Vanity then
        yAbs = 0.0
        lastPosZ = nil
        return
    end
    if queued == MODE.FirstPerson or mode == MODE.FirstPerson then
        yAbs = 0.0
        lastPosZ = nil
        return
    end

    local d = clampScalar(dt or 0.016, 0.001, 0.05)

    -- Z velocity (only)
    local z = self.position.z
    local vz = 0.0
    if lastPosZ ~= nil then
        vz = (z - lastPosZ) / d
    end
    lastPosZ = z

    if math.abs(vz) < OFFSET_Y_VZ_DZ then
        vz = 0.0
    else
        vz = vz - (OFFSET_Y_VZ_DZ * (vz > 0 and 1 or -1))
    end

    local targetY = 0.0
    if vz ~= 0.0 then
        targetY = -vz * OFFSET_Y_PER_VZ
        targetY = clampScalar(targetY, -OFFSET_Y_MAX, OFFSET_Y_MAX)
    end

    local rate = (vz ~= 0.0) and OFFSET_Y_FOLLOW or OFFSET_Y_RETURN
    local a = expAlpha(rate, d)
    yAbs = yAbs + (targetY - yAbs) * a

    yAbs = clampScalar(yAbs, -OFFSET_Y_MAX, OFFSET_Y_MAX)

    local cur = camera.getFocalPreferredOffset()
    camera.setFocalPreferredOffset(util.vector2(cur.x, yAbs))
end

local MOVE_STEER_PITCH_ENABLED = false
local MOVE_STEER_PITCH_SPEED = math.rad(35)
local MOVE_STEER_PITCH_FOLLOW = 7.0
local MOVE_STEER_PITCH_DZ = 0.10
local MOVE_STEER_PITCH_MAX_RATE = math.rad(80)
local MOVE_STEER_PITCH_MAX_STEP = math.rad(6)

local moveSteerPitchRateLP = 0.0

local function applyMovementSteerPitch(dt)
    if not MOVE_STEER_PITCH_ENABLED then
        moveSteerPitchRateLP = 0.0
        return
    end

    local mode = camera.getMode()
    local queued = camera.getQueuedMode()
    if mode ~= MODE.ThirdPerson and mode ~= MODE.Preview and mode ~= MODE.Vanity then
        moveSteerPitchRateLP = 0.0
        return
    end
    if queued == MODE.FirstPerson or mode == MODE.FirstPerson then
        moveSteerPitchRateLP = 0.0
        return
    end

    local d = clampScalar(dt or 0.016, 0.001, 0.05)

    local mx = clampScalar(self.controls.sideMovement, -1, 1)
    local my = clampScalar(self.controls.movement, -1, 1)
    local moveMag = math.sqrt(mx * mx + my * my)
    if moveMag <= MOVE_STEER_PITCH_DZ then
        moveSteerPitchRateLP = 0.0
        return
    end

    local pitch = camera.getPitch()
    local err = -pitch

    local targetRate = clampScalar(err, -1, 1) * MOVE_STEER_PITCH_SPEED
    targetRate = clampScalar(targetRate, -MOVE_STEER_PITCH_MAX_RATE, MOVE_STEER_PITCH_MAX_RATE)

    local a = expAlpha(MOVE_STEER_PITCH_FOLLOW, d)
    moveSteerPitchRateLP = moveSteerPitchRateLP + (targetRate - moveSteerPitchRateLP) * a

    local step = clampScalar(moveSteerPitchRateLP * d, -MOVE_STEER_PITCH_MAX_STEP, MOVE_STEER_PITCH_MAX_STEP)
    camera.setPitch(pitch + step)
end

local PITCH_LAG_ENABLED = true
local VZ_TO_EXTRA_PITCH = math.rad(14) / 400.0
local PITCH_LAG_FOLLOW_RATE = 5.0
local PITCH_LAG_RETURN_RATE = 14.0
local MAX_EXTRA_PITCH_LAG = math.rad(12)
local VZ_DEADZONE = 250.0

local pitchLag = 0.0
local lastPosZ = nil

local function applyPitchLag(dt)
    if not PITCH_LAG_ENABLED then
        pitchLag = 0.0
        lastPosZ = nil
        return 0.0
    end

    local mode = camera.getMode()
    if mode ~= MODE.ThirdPerson and mode ~= MODE.Preview and mode ~= MODE.Vanity then
        pitchLag = 0.0
        lastPosZ = nil
        return 0.0
    end

    local d = dt or 0.016
    d = clampScalar(d, 0.001, 0.05)

    local z = self.position.z
    local vz = 0.0
    if lastPosZ ~= nil then
        vz = (z - lastPosZ) / d
    end
    lastPosZ = z

    if math.abs(vz) < VZ_DEADZONE then
        vz = 0.0
    else
        vz = vz - (VZ_DEADZONE * (vz > 0 and 1 or -1))
    end

    local target = clampScalar(-vz * VZ_TO_EXTRA_PITCH, -MAX_EXTRA_PITCH_LAG, MAX_EXTRA_PITCH_LAG)

    local rate = (vz ~= 0.0) and PITCH_LAG_FOLLOW_RATE or PITCH_LAG_RETURN_RATE
    local a = expAlpha(rate, d)
    pitchLag = pitchLag + (target - pitchLag) * a

    return pitchLag
end

local function onUpdate(dt)
    camera.setFirstPersonOffset(util.vector3(0, 0, 0))
    updateSmoothedSpeed(dt)
    pov_auto_switch.onUpdate(dt)
end

local function onFrame(dt)
    if core.isWorldPaused() or I.UI.getMode() then return end

    updateIdleTimer(dt)

    local mode = camera.getMode()
    if (mode == MODE.FirstPerson or mode == MODE.ThirdPerson) and not camera.getQueuedMode() then
        primaryMode = mode
    end

    if mode ~= MODE.Static then
        local paralysis = Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Paralyze)
        local paralyzed = not debug.isGodMode() and paralysis.magnitude > 0
        if not next(noModeControl) and not paralyzed then
            updatePOV(dt)
            updateVanity(dt)
        end
        updateStandingPreview()
        updateCrosshair()
    end

    do
        local Zoom3rdPerson = input.getNumberActionValue('Zoom3rdPerson')
        if Zoom3rdPerson ~= 0 then
            zoom(Zoom3rdPerson)
        end
    end

    third_person.update(dt, smoothedSpeed)
    if not next(noHeadBobbing) then head_bobbing.update(dt, smoothedSpeed) end
    if slowViewChange then
        local maxIncrease = dt * (100 + third_person.baseDistance)
        camera.setPreferredThirdPersonDistance(
            math.min(camera.getThirdPersonDistance() + maxIncrease, third_person.preferredDistance))
    end

    local mNow = camera.getMode()
    if mNow == MODE.ThirdPerson or mNow == MODE.Preview or mNow == MODE.Vanity then
        applyMovementSteerYaw(dt)
        applyMovementSteerPitch(dt)
        applyHorizontalFocalOffset(dt)
        applyVerticalFocalOffset(dt)
    else
        moveSteerYawRateLP = 0.0
    end

    local modeNow = camera.getMode()
    if modeNow == MODE.ThirdPerson or modeNow == MODE.Preview or modeNow == MODE.Vanity then
        local pLag = applyPitchLag(dt)
        camera.setExtraPitch(pLag)
        camera.setExtraYaw(0)
        camera.setExtraRoll(0)
    else
        pitchLag = 0.0
        lastPosZ = nil
        camera.setExtraPitch(0)
        camera.setExtraYaw(0)
        camera.setExtraRoll(0)
    end

    move360.onFrame(dt)
end

return {
    interfaceName = 'Camera',
    interface = {
        version = 1,

        getPrimaryMode = function() return primaryMode end,

        getBaseThirdPersonDistance = function() return third_person.baseDistance end,
        setBaseThirdPersonDistance = function(v) third_person.baseDistance = v end,
        getTargetThirdPersonDistance = function() return third_person.preferredDistance end,

        isModeControlEnabled = function() return not next(noModeControl) end,
        disableModeControl = function(tag) noModeControl[tag or ''] = true end,
        enableModeControl = function(tag) noModeControl[tag or ''] = nil end,

        isStandingPreviewEnabled = function() return previewIfStandStill and not next(noStandingPreview) end,
        disableStandingPreview = function(tag) noStandingPreview[tag or ''] = true end,
        enableStandingPreview = function(tag) noStandingPreview[tag or ''] = nil end,

        isHeadBobbingEnabled = function() return head_bobbing.enabled and not next(noHeadBobbing) end,
        disableHeadBobbing = function(tag) noHeadBobbing[tag or ''] = true end,
        enableHeadBobbing = function(tag) noHeadBobbing[tag or ''] = nil end,

        isZoomEnabled = function() return not next(noZoom) end,
        disableZoom = function(tag) noZoom[tag or ''] = true end,
        enableZoom = function(tag) noZoom[tag or ''] = nil end,

        isThirdPersonOffsetControlEnabled = function() return not next(third_person.noOffsetControl) end,
        disableThirdPersonOffsetControl = function(tag) third_person.noOffsetControl[tag or ''] = true end,
        enableThirdPersonOffsetControl = function(tag) third_person.noOffsetControl[tag or ''] = nil end,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame,
        onTeleported = function()
            camera.instantTransition()
        end,
        onActive = init,
        onLoad = function(data)
            if data and data.distance then third_person.baseDistance = data.distance end
        end,
        onSave = function()
            return { version = 0, distance = third_person.baseDistance }
        end,
    },
}
