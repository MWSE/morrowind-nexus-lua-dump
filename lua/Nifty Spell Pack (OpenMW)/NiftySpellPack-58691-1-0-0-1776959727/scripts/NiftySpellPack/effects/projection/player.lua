local camera = require('openmw.camera')
local self = require('openmw.self')
local core = require('openmw.core')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local postprocessing = require('openmw.postprocessing')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

local helpers = require('scripts.NiftySpellPack.util.helpers_p')

local MOUSE_SENSITIVITY = 0.005
local MIN_INERTIA_FACTOR = 0.997
local MAX_INERTIA_FACTOR = 0.94
local INERTIA_FACTOR_CURVE = 3
local MIN_MOVEMENT_SPEED = 200
local MAX_MOVEMENT_SPEED = 1000
local MOVEMENT_SPEED_CURVE = 1.5
local MIN_RADIUS = 800
local MAX_RADIUS = 8000
local RADIUS_CURVE = 1
local RADIUS_EXTERIOR_MULT = 1.0
local RADIUS_LIMIT = 8000
local MIN_FOG_NEAR = 0
local MAX_FOG_NEAR = 2000
local MIN_FOG_FAR = 250
local MAX_FOG_FAR = 8000
local FOG_CURVE = 1
local COLLISION_RADIUS = 32
local COLLISION_EPSILON = 0.25
local SLIDE_ITERATIONS = 4
local MAX_COLLISION_SUBSTEPS = 320
local COLLISION_STEP_SCALE = 1.0
local OBJECT_COLLISION_MASK = nearby.COLLISION_TYPE.Default - nearby.COLLISION_TYPE.Actor
local BARRIER_SOFTNESS = 0.04
local BARRIER_MIN_THICKNESS = 160.0
local BARRIER_EPSILON = 8.0
local BARRIER_RETURN_FORCE = 2600.0
local PULLBACK_DURATION = 2.0
local PULLBACK_MOUSE_SENSITIVITY_MULT = 0.12
local PULLBACK_AIM_SPEED = 10.0
local START_FOV_MULT = 0.1
local START_FOV_DURATION = 1
local START_FOV_CURVE = 1/4

local DEFAULT_PROJECTION_PALETTE = {
    base = util.vector3(0.1, 0, 0.7),
    highlight = util.vector3(0.95, 0.8, 0.95),
    void = util.vector3(0.045, 0.0, 0.075),
    fog = util.vector3(0, 0.35, 0.5),
    edge = util.vector3(0.6, 0.35, 0.85),
    startup = util.vector3(0.32, -0.03, 0.42),
}

local PROJECTION_PALETTES = {
    nsp_projection = DEFAULT_PROJECTION_PALETTE,
    nsp_projection_temple = {
        base = util.vector3(0.95, 0.72, 0.22)*0.6,
        highlight = util.vector3(1.0, 0.94, 0.82),
        void = util.vector3(0.92, 0.46, 0.0)*2,
        fog = util.vector3(0.42, 0.27, 0.06),
        edge = util.vector3(0.6, 0.55, 0.1),
        startup = util.vector3(0.5, 0.48, -0.02),
    },
}

local trans = util.transform
local shader = postprocessing.load('nfs_projection')
local activeSpells = self.type.activeSpells(self)
local activeEffects = self.type.activeEffects(self)

if I.S3maphore then
    I.S3maphore.registerPlaylist {
        id = 'ProjectionSpell',
        priority = 1,
        interruptMode = 2,
        isValidCallback = function()
            return activeEffects:getEffect('nsp_projection').magnitude > 0 or activeEffects:getEffect('nsp_greaterprojection').magnitude > 0
        end,
        tracks = {
            'sound/niftyspellpack/projection.mp3',
        }
    }
end

-- Stateless helpers

local function getBaseMovementVector()
    local left = input.getRangeActionValue('MoveLeft')
    local right = input.getRangeActionValue('MoveRight')
    local forward = input.getRangeActionValue('MoveForward')
    local backward = input.getRangeActionValue('MoveBackward')
    return util.vector3(right - left, forward - backward, 0)
end

local function getLookAngles(direction)
    local horizontalLength = math.sqrt(direction.x * direction.x + direction.y * direction.y)
    local yaw = math.atan2(direction.x, direction.y)
    local pitch = -math.atan2(direction.z, math.max(horizontalLength, 0.001))
    return yaw, util.clamp(pitch, -math.pi / 2 + 0.01, math.pi / 2 - 0.01)
end

local function getLookDirection(yaw, pitch)
    local horizontalLength = math.cos(pitch)
    return util.vector3(
        math.sin(yaw) * horizontalLength,
        math.cos(yaw) * horizontalLength,
        -math.sin(pitch)
    )
end

local function slerpDirection(fromDir, toDir, t)
    local fromLength = fromDir:length()
    local toLength = toDir:length()
    if fromLength <= 0.001 then
        fromDir = util.vector3(0, 0, 0)
    else
        fromDir = fromDir:normalize()
    end
    if toLength <= 0.001 then
        toDir = util.vector3(0, 0, 0)
    else
        toDir = toDir:normalize()
    end
    local dot = util.clamp(fromDir:dot(toDir), -1, 1)

    if dot > 0.9995 then
        local blended = fromDir + (toDir - fromDir) * t
        return blended:length() <= 0.001 and util.vector3(0, 0, 0) or blended:normalize()
    end

    if dot < -0.9995 then
        local fallbackAxis = fromDir:cross(util.vector3(0, 0, 1))
        if fallbackAxis:length() <= 0.001 then
            fallbackAxis = fromDir:cross(util.vector3(0, 1, 0))
        end
        return util.transform.rotate(math.pi * t, fallbackAxis:normalize()) * fromDir
    end

    local axis = fromDir:cross(toDir):normalize()
    local angle = math.acos(dot) * t
    return util.transform.rotate(angle, axis) * fromDir
end

local function getProjectionPalette(spellId)
    return PROJECTION_PALETTES[spellId] or DEFAULT_PROJECTION_PALETTE
end

-- Land collision helpers

local function getLandHeight(position, cell)
    return core.land.getHeightAt(util.vector3(position.x, position.y, 0), cell)
end

local function getMaxCollisionStep()
    return math.max(COLLISION_EPSILON * COLLISION_STEP_SCALE, 0.001)
end

local function clampToLand(position, velocity)
    local cell = self.cell
    if not cell or not cell.isExterior then
        return position, velocity
    end

    local minZ = getLandHeight(position, cell) + COLLISION_RADIUS
    if position.z >= minZ then
        return position, velocity
    end

    position = util.vector3(position.x, position.y, minZ)
    if velocity.z < 0 then
        velocity = util.vector3(velocity.x, velocity.y, 0)
    end

    return position, velocity
end

-- Factory: creates an independent projection effect instance

local function createProjectionEffect(config)
    config = config or {}
    local effectId = config.effectId or 'nsp_projection'
    local minRadius = config.minRadius or MIN_RADIUS
    local maxRadius = config.maxRadius or MAX_RADIUS
    local minInertia = config.minInertia or MIN_INERTIA_FACTOR
    local maxInertia = config.maxInertia or MAX_INERTIA_FACTOR
    local useObjectCollision = config.useObjectCollision ~= false

    local setStartMusic = false
    local startMusic = false

    local state = {
        active = false,
        pos = nil,
        pitch = nil,
        yaw = nil,
        velocity = util.vector3(0,0,0),
        oldMode = nil,
        oldPitch = nil,
        oldYaw = nil,
        oldPlayerPitch = nil,
        oldPlayerYaw = nil,
        oldControls = nil,
        elapsedTime = 0.0,
        magnitude = 0,
        pullbackProgress = nil,
        palette = DEFAULT_PROJECTION_PALETTE,
        activeSpellId = effectId,
    }

    local function applyCameraTransform(v)
        return (trans.rotateZ(state.yaw) * trans.rotateX(state.pitch)) * v
    end

    local function applyPlayerTransform(v)
        return (trans.rotateZ(self.rotation:getYaw()) * trans.rotateX(state.pitch)) * v
    end

    local function getMovementVector()
        local base = applyCameraTransform(getBaseMovementVector())

        local down = input.isActionPressed(input.ACTION.Sneak) and 1 or 0
        local up = input.isActionPressed(input.ACTION.Jump) and 1 or 0

        return util.vector3(base.x, base.y, base.z + up - down):normalize()
    end

    local function getCurrentRadius()
        local extMult = self.cell and self.cell.isExterior and RADIUS_EXTERIOR_MULT or 1.0
        local radius = (minRadius + (maxRadius - minRadius) * math.pow(state.magnitude / 100, RADIUS_CURVE)) * extMult
        if maxRadius then
            radius = math.min(radius, RADIUS_LIMIT)
        end
        return radius
    end

    local function getMagnitudeFactor()
        return state.magnitude / 100
    end

    local function getFogDistances()
        local magnitudeFactor = math.pow(getMagnitudeFactor(), FOG_CURVE)
        local interiorFactor = self.cell and not self.cell.isExterior and 0.5 or 1.0
        local fogNear = math.min((MIN_FOG_NEAR + (MAX_FOG_NEAR - MIN_FOG_NEAR) * magnitudeFactor) * interiorFactor, MAX_FOG_NEAR)
        local fogFar = math.min((MIN_FOG_FAR + (MAX_FOG_FAR - MIN_FOG_FAR) * magnitudeFactor) * interiorFactor, MAX_FOG_FAR)
        return fogNear, fogFar
    end

    local function updateProjectionPalette(spellId)
        state.palette = getProjectionPalette(spellId)
        if shader:isEnabled() then
            shader:setVector3('paletteBase', state.palette.base)
            shader:setVector3('paletteHighlight', state.palette.highlight)
            shader:setVector3('paletteVoid', state.palette.void)
            shader:setVector3('paletteFog', state.palette.fog)
            shader:setVector3('paletteEdge', state.palette.edge)
            shader:setVector3('paletteStartup', state.palette.startup)
        end
    end

    local function getBarrierCenter()
        return camera.getTrackedPosition()
    end

    local function applyBoundaryResistance(position, velocity, radius, dt, pushingOutward)
        local offset = position - getBarrierCenter()
        local distance = offset:length()
        if distance <= 0.001 then
            return velocity
        end

        local boundaryNormal = offset / distance
        local barrierThickness = math.max(BARRIER_MIN_THICKNESS, radius * BARRIER_SOFTNESS)
        local penetrationDepth = math.max(distance - radius, 0)
        if penetrationDepth <= 0 then
            return velocity
        end

        local barrierFactor = util.clamp(penetrationDepth / barrierThickness, 0, 1)
        local outwardSpeed = velocity:dot(boundaryNormal)
        if outwardSpeed > 0 then
            local outwardScale = 1 - barrierFactor * barrierFactor
            velocity = velocity - boundaryNormal * outwardSpeed * (1 - outwardScale)
        end

        if not pushingOutward then
            local returnStrength = (0.2 + barrierFactor * barrierFactor * 0.8) * BARRIER_RETURN_FORCE * dt
            velocity = velocity - boundaryNormal * returnStrength
        end

        return velocity
    end

    local function isPushingOutward(position, moveVec)
        if moveVec:length() <= 0.001 then
            return false
        end

        local offset = position - getBarrierCenter()
        local distance = offset:length()
        if distance <= 0.001 then
            return false
        end

        return moveVec:dot(offset / distance) > 0
    end

    local function constrainToBarrier(position, velocity, radius)
        local offset = position - getBarrierCenter()
        local distance = offset:length()
        local barrierThickness = math.max(BARRIER_MIN_THICKNESS, radius * BARRIER_SOFTNESS)
        local maxDistance = radius + barrierThickness - BARRIER_EPSILON
        if state.pullbackProgress then
            local t = math.pow(state.pullbackProgress, 4)
            maxDistance = radius * t + maxDistance * (1 - t)
        end
        local targetDistance = maxDistance
        maxDistance = math.max(maxDistance, 0)
        targetDistance = math.max(targetDistance, 0)
        if distance <= maxDistance or distance <= 0.001 then
            return position, velocity
        end

        local boundaryNormal = offset / distance
        local constrainedPosition = getBarrierCenter() + boundaryNormal * targetDistance
        local outwardSpeed = velocity:dot(boundaryNormal)
        if outwardSpeed > 0 then
            velocity = velocity - boundaryNormal * outwardSpeed
        end

        return constrainedPosition, velocity
    end

    -- Object collision via physics raycast

    local function castCollision(startPos, targetPos)
        local hit = nearby.castRay(startPos, targetPos, {
            radius = COLLISION_RADIUS,
            collisionType = OBJECT_COLLISION_MASK,
        })
        if hit and hit.hit then
            return hit
        end
    end

    local function slideMoveStep(pos, velocity, dt)
        local resolvedVelocity = velocity
        local remainingTime = dt

        for _ = 1, SLIDE_ITERATIONS do
            if remainingTime <= 0 then break end
            if resolvedVelocity:length() <= 0.001 then
                resolvedVelocity = util.vector3(0, 0, 0)
                break
            end

            local step = resolvedVelocity * remainingTime
            local stepLength = step:length()
            if stepLength <= 0.001 then break end

            local target = pos + step
            local hit = castCollision(pos, target)

            if not hit or not hit.hit or not hit.hitPos then
                pos = target
                break
            end

            local hitOffset = hit.hitPos - pos
            local hitDistance = math.min(hitOffset:length(), stepLength)
            local moveDistance = math.max(hitDistance - COLLISION_EPSILON, 0.0)
            if moveDistance > 0 then
                pos = pos + step:normalize() * moveDistance
            end

            local timeToHit = remainingTime * (hitDistance / stepLength)
            remainingTime = math.max(remainingTime - timeToHit, 0)

            local hitNormal = hit.hitNormal
            if not hitNormal then
                resolvedVelocity = util.vector3(0, 0, 0)
                break
            end

            local towardSurface = resolvedVelocity:dot(hitNormal)
            if towardSurface < 0 then
                resolvedVelocity = resolvedVelocity - hitNormal * towardSurface
            end

            pos = pos + hitNormal * COLLISION_EPSILON
        end

        return pos, resolvedVelocity
    end

    local function fullSlideMove(startPos, velocity, dt)
        local speed = velocity:length()
        if dt <= 0 or speed <= 0.001 then
            return startPos, velocity
        end

        local maxCollisionStep = getMaxCollisionStep()
        local totalDistance = speed * dt
        local maxResolvableDistance = maxCollisionStep * MAX_COLLISION_SUBSTEPS
        if totalDistance > maxResolvableDistance then
            velocity = velocity * (maxResolvableDistance / totalDistance)
            speed = velocity:length()
            totalDistance = speed * dt
        end

        local substeps = math.max(1, math.min(MAX_COLLISION_SUBSTEPS, math.ceil(totalDistance / maxCollisionStep)))
        local stepDt = dt / substeps
        local pos = startPos
        local resolvedVelocity = velocity

        for _ = 1, substeps do
            pos, resolvedVelocity = slideMoveStep(pos, resolvedVelocity, stepDt)
            if resolvedVelocity:length() <= 0.001 then
                resolvedVelocity = util.vector3(0, 0, 0)
                break
            end
        end

        return pos, resolvedVelocity
    end

    local function resolveMovement(pos, velocity, dt)
        if useObjectCollision then
            return fullSlideMove(pos, velocity, dt)
        else
            pos = pos + velocity * dt
            return clampToLand(pos, velocity)
        end
    end

    local function updateShader()
        if state.active then
            if not shader:isEnabled() then
                shader:enable()
            end
            local fogNear, fogFar = getFogDistances()
            shader:setFloat('elapsed', state.elapsedTime)
            shader:setFloat('radius', getCurrentRadius())
            shader:setFloat('fogNear', fogNear)
            shader:setFloat('fogFar', fogFar)
            shader:setFloat('pullbackProgress', state.pullbackProgress or 0)
            shader:setVector3('center', camera.getTrackedPosition())
            updateProjectionPalette(state.activeSpellId)
        elseif shader:isEnabled() then
            shader:disable()
        end
    end

    local function setActive(active)
        if active and not state.active then
            state.pos = camera.getPosition()
            state.pitch = camera.getPitch()
            state.yaw = camera.getYaw()
            state.velocity = applyPlayerTransform(util.vector3(0, 100, 0))

            state.oldMode = camera.getMode()
            state.oldPitch = state.pitch
            state.oldYaw = state.yaw

            if state.oldMode == camera.MODE.FirstPerson then
                state.oldPlayerPitch = state.pitch
                state.oldPlayerYaw = state.yaw
            else
                state.oldPlayerPitch = self.rotation:getPitch()
                state.oldPlayerYaw = self.rotation:getYaw()

                if state.oldMode == camera.MODE.Static then
                    state.oldMode = camera.MODE.FirstPerson
                    state.oldPitch = state.oldPlayerPitch
                    state.oldYaw = state.oldPlayerYaw
                end
            end

            camera.setMode(camera.MODE.Static, true)
            camera.setStaticPosition(state.pos)

            state.oldControls = state.oldControls or {}
            for _, switch in pairs(self.type.CONTROL_SWITCH) do
                state.oldControls[switch] = self.type.getControlSwitch(self, switch)
                self.type.setControlSwitch(self, switch, false)
            end

            self.controls.pitchChange = state.oldPlayerPitch
            self.controls.yawChange = state.oldPlayerYaw

            state.elapsedTime = 0.0
            state.pullbackProgress = nil
            state.activeSpellId = effectId
            updateShader()

            ambient.playSoundFile('sound/niftyspellpack/projection_end.wav')

            if I.S3maphore then
                I.S3maphore.skipTrack()
            else
                ambient.stopMusic()
                ambient.streamMusic('sound/niftyspellpack/projection.mp3', { fadeOut = 0.5 })
            end
        elseif not active and state.active then
            for _, switch in pairs(self.type.CONTROL_SWITCH) do
                self.type.setControlSwitch(self, switch, state.oldControls and state.oldControls[switch] or true)
            end

            camera.setMode(state.oldMode or camera.MODE.FirstPerson, true)
            camera.setPitch(state.oldPitch or 0)
            camera.setYaw(state.oldYaw or 0)
            camera.setFieldOfView(camera.getBaseFieldOfView())

            shader:disable()

            ambient.stopSoundFile('sound/niftyspellpack/projection_pullback.wav')
            ambient.playSoundFile('sound/niftyspellpack/projection_end.wav')

            if I.S3maphore then
                I.S3maphore.skipTrack()
            else
                ambient.stopMusic()
                ambient.streamMusic('sound/niftyspellpack/nothing_2s.mp3', { fadeOut = 0.5 })
            end
        end
        state.active = active
        state.cancelTime = nil
    end

    local function updateActiveSpellId()
        local highestRemainingDuration
        local activeProjectionSpellId
        for _, spell in pairs(activeSpells) do
            for _, effect in pairs(spell.effects) do
                if effect.id == effectId and effect.minMagnitude > 0 then
                    activeProjectionSpellId = spell.id or activeProjectionSpellId
                    if not highestRemainingDuration or effect.durationLeft > highestRemainingDuration then
                        highestRemainingDuration = effect.durationLeft
                    end
                end
            end
        end
        state.activeSpellId = activeProjectionSpellId or effectId

        if state.cancelTime then
            highestRemainingDuration = math.min(highestRemainingDuration or math.huge, state.cancelTime - core.getSimulationTime())
        end

        return state.activeSpellId, highestRemainingDuration
    end

    return {
        realtimeMagnitudeWhileActive = true,
        onMagnitudeChange = function(ctx)
            state.magnitude = ctx.newMagnitude
            updateShader()
            if state.magnitude == 0 then
                setActive(false)
            else
                setActive(true)
            end
        end,
        onFrame = function(dt, magnitude)
            if dt == 0 or magnitude <= 0 then return end
            if not state.active then return end

            -- Weird workaround for OMW built in music system. If we don't delay this track will get overriden on reload
            if not I.S3maphore then
                if startMusic then
                    ambient.stopMusic()
                    ambient.streamMusic('sound/niftyspellpack/projection.mp3', { fadeOut = 0.5 })
                    startMusic = false
                end

                if setStartMusic then
                    startMusic = true
                    setStartMusic = false
                end
            end

            state.elapsedTime = state.elapsedTime + dt
            camera.setFieldOfView(camera.getBaseFieldOfView() * (START_FOV_MULT + (1 - START_FOV_MULT) * math.pow(math.min(state.elapsedTime / START_FOV_DURATION, 1), START_FOV_CURVE)))

            local _, highestRemainingDuration = updateActiveSpellId()
            updateShader()

            if camera.getMode() ~= camera.MODE.Static then
                camera.setMode(camera.MODE.Static, true)
            end

            if highestRemainingDuration and highestRemainingDuration <= PULLBACK_DURATION then
                if highestRemainingDuration <= 0 then
                    helpers.removeSpellsByEffectId(effectId, true)
                    return
                end

                if not state.pullbackProgress then
                    ambient.playSoundFile('sound/niftyspellpack/projection_pullback.wav')
                    if not I.S3maphore then
                        ambient.streamMusic('sound/niftyspellpack/nothing_2s.mp3', { fadeOut = PULLBACK_DURATION })
                    end
                end
                state.pullbackProgress = 1 - highestRemainingDuration / PULLBACK_DURATION
                local pullbackFOV = math.min(camera.getBaseFieldOfView() * (1 + 1.0 * math.pow(state.pullbackProgress, 4)), math.pi)
                if not self.cell.isExterior then
                    camera.setFieldOfView(pullbackFOV)
                end
            else
                ambient.stopSoundFile('sound/niftyspellpack/projection_pullback.wav')
                state.pullbackProgress = nil
            end

            local mouseMovementX = input.getMouseMoveX()
            local mouseMovementY = input.getMouseMoveY()
            local pullbackInputScale = 1.0
            if state.pullbackProgress and state.pos then
                pullbackInputScale = 1.0 - (1.0 - PULLBACK_MOUSE_SENSITIVITY_MULT) * math.pow(state.pullbackProgress, 2)
            end

            state.yaw = (state.yaw or 0) + mouseMovementX * MOUSE_SENSITIVITY * pullbackInputScale
            state.pitch = util.clamp((state.pitch or 0) + mouseMovementY * MOUSE_SENSITIVITY * pullbackInputScale, -math.pi/2 + 0.01, math.pi/2 - 0.01)

            if state.pullbackProgress and state.pos then
                local vectorToCenter = getBarrierCenter() - state.pos
                if vectorToCenter:length() > 0.001 then
                    local pullAim = util.clamp(dt * PULLBACK_AIM_SPEED * math.pow(state.pullbackProgress, 2), 0, 1)
                    local currentDir = getLookDirection(state.yaw, state.pitch)
                    local blendedDir = slerpDirection(currentDir, vectorToCenter, pullAim)
                    state.yaw, state.pitch = getLookAngles(blendedDir)
                end
            end

            camera.setYaw(state.yaw)
            camera.setPitch(state.pitch)

            local moveVec = getMovementVector()
            local speed = MIN_MOVEMENT_SPEED + (MAX_MOVEMENT_SPEED - MIN_MOVEMENT_SPEED) * math.pow(magnitude / 100, MOVEMENT_SPEED_CURVE)
            if input.getBooleanActionValue('Run') then
                speed = speed / 2
            end
            local inertia = minInertia + (maxInertia - minInertia) * math.pow(magnitude / 100, INERTIA_FACTOR_CURVE)
            state.velocity = state.velocity * inertia + moveVec * speed * (1 - inertia)
            local radius = getCurrentRadius()
            local pushingOutward = isPushingOutward(state.pos, moveVec)

            if state.pullbackProgress then
                radius = 8 + (radius - 8) * (1 - math.pow(state.pullbackProgress, 4))
                shader:setFloat('radius', radius)
            end

            state.velocity = applyBoundaryResistance(state.pos, state.velocity, radius, dt, pushingOutward)

            state.pos, state.velocity = resolveMovement(state.pos, state.velocity, dt)
            state.pos, state.velocity = constrainToBarrier(state.pos, state.velocity, radius)

            camera.setStaticPosition(state.pos)

            for _, switch in pairs(self.type.CONTROL_SWITCH) do
                if self.type.getControlSwitch(self, switch) then
                    self.type.setControlSwitch(self, switch, false)
                end
            end
        end,
        onUse = function()
            if not state.cancelTime then
                state.cancelTime = core.getSimulationTime() + PULLBACK_DURATION
            end
        end,
        onLoad = function(savedState)
            if savedState then
                for k,v in pairs(savedState) do
                    state[k] = v
                end
            end

            if state.active then
                camera.setMode(camera.MODE.Static, true)
                camera.setStaticPosition(state.pos or camera.getPosition())
                camera.setPitch(state.pitch or 0)
                camera.setYaw(state.yaw or 0)
                setStartMusic = true
            end
            updateActiveSpellId()
            updateShader()
        end,
        onSave = function()
            return state
        end,
    }
end

-- Standard Projection: collides with objects, radius capped at 8000
local handlers = createProjectionEffect({
    effectId = 'nsp_projection',
    minRadius = MIN_RADIUS,
    maxRadius = MAX_RADIUS,
    minInertia = MIN_INERTIA_FACTOR,
    maxInertia = MAX_INERTIA_FACTOR,
    useObjectCollision = true,
})
handlers.createProjectionEffect = createProjectionEffect

local activeEffects = self.type.activeEffects(self)
local oldOnFrame = handlers.onFrame
handlers.onFrame = function(dt, magnitude)
    if activeEffects:getEffect('nsp_greaterprojection').magnitude > 0 then
        return
    end

    oldOnFrame(dt, magnitude)
end

return handlers
