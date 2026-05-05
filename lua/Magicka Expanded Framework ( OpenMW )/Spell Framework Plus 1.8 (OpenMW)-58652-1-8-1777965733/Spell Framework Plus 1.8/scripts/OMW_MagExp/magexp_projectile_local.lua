-- ============================================================
-- OMW_MagExp: Magic Expansion Framework for OpenMW
-- magexp_projectile_local.lua (CUSTOM script - attached to projectile objects)
--
-- Handles per-frame physics, ray-cast collision detection, and
-- lifecycle events. All global events use the MagExp_ prefix.
-- ============================================================

local self   = require('openmw.self')
local nearby = require('openmw.nearby')
local core   = require('openmw.core')
local util   = require('openmw.util')
local anim   = require('openmw.animation')
local types  = require('openmw.types')

-- ---- Core state ----
local velocity        = nil
local attacker        = nil
local spellId         = nil
local area            = 0
local lifetime        = 0
local maxLifetime     = 10
local hasCollided     = false
local boltSound       = nil
local soundAnchor     = nil
local lightAnchor     = nil
local isRotating      = false
local currentRotation = nil
local rotSpinLog      = 0
local spinSpeed       = 0
local boltVfxHandle   = nil
local effectIndexes   = nil
local isProjectile    = false
local maxSpeed        = 0
local isPaused        = false
local unreflectable   = false
local casterLinked    = false
local userData        = nil
local muteAudio       = false
local muteLight       = false
local continuousVfx   = false
local effectScale     = nil

-- ---- Physics extensions ----
-- accelerationExp: exponential signed speed multiplier per frame.
-- When signedSpeed crosses zero the spell reverses direction.
-- forceVec: true directional force added to velocity each frame (Vector3, units/sec²).
local accelerationExp = 0
local forceVec        = nil

-- signedSpeed tracks the current speed WITH sign along baseDir.
-- Negative = traveling in reverse of the original launch direction.
local signedSpeed  = 0
-- baseDir is the 'positive forward' axis used by accelerationExp.
-- Updated whenever velocity or direction is explicitly overridden.
local baseDir      = util.vector3(0, 1, 0)

-- ---- VFX identity ----
local vfxRecId        = nil   -- BUG FIX: was referenced in collision payload without declaration
local areaVfxRecId    = nil

-- ---- Bounce system ----
local bounceEnabled      = false
local bounceMax          = 0       -- 0 = unlimited bounces until lifetime expires
local bounceCount        = 0
local bouncePower        = 0.7     -- restitution coeff: 1.0 = perfect elastic, 0 = dead stop

-- ---- Actor detonation rule ----
-- When true (default): actor contact always detonates regardless of remaining bounces.
-- When false: actors are treated as static surface for bounce purposes.
local detonateOnActorHit = true

-- ---- Impact data ----
local impactSpeed     = 0     -- speed captured the frame collision is confirmed (units/sec)
local impactImpulse   = 0     -- MaxYari LuaPhysics impulse magnitude applied on detonation

-- ============================================================
-- [INTERNAL] Clean up sounds and lights
-- ============================================================
local function stopSound()
    if boltSound then
        core.sound.stopSound3d(boltSound, self)
    end
    if soundAnchor and soundAnchor:isValid() then
        soundAnchor:sendEvent('MagExp_StopSound')
        core.sendGlobalEvent('MagExp_RemoveObject', soundAnchor)
        soundAnchor = nil
    end
    if lightAnchor and lightAnchor:isValid() then
        core.sendGlobalEvent('MagExp_RemoveObject', lightAnchor)
        lightAnchor = nil
    end
    if boltVfxHandle then
        boltVfxHandle:remove()
        boltVfxHandle = nil
    end
end

-- ============================================================
-- [EVENT] MagExp_InitProjectile / MagExp_InitSound
-- ============================================================
local function onInit(data)
    if data and data.velocity then
        -- ---- Main projectile initialization ----
        isProjectile    = true
        velocity        = data.velocity
        attacker        = data.attacker
        spellId         = data.spellId
        area            = data.area            or 0
        boltSound       = data.boltSound       or nil
        lifetime        = 0
        hasCollided     = false
        isRotating      = false
        currentRotation = self.rotation
        spinSpeed       = data.spinSpeed       or 0
        maxLifetime     = data.maxLifetime     or 10
        effectIndexes   = data.effectIndexes   or nil
        accelerationExp = data.accelerationExp or 0
        forceVec        = data.forceVec        or nil
        maxSpeed        = data.maxSpeed        or 0
        isPaused        = data.isPaused        or false
        -- VFX
        vfxRecId        = data.vfxRecId
        areaVfxRecId    = data.areaVfxRecId
        -- Bounce
        bounceEnabled      = data.bounceEnabled      or false
        bounceMax          = data.bounceMax          or 0
        bouncePower        = data.bouncePower        or 0.7
        detonateOnActorHit = (data.detonateOnActorHit ~= false)
        unreflectable      = data.unreflectable      or false
        casterLinked       = data.casterLinked       or false
        -- Impact
        impactImpulse = data.impactImpulse or 0
        userData      = data.userData      or nil
        muteAudio     = data.muteAudio     or false
        muteLight     = data.muteLight     or false
        continuousVfx = data.continuousVfx or false
        effectScale   = data.effectScale

        if spinSpeed > 0 then isRotating = true end

        -- [FIX] Always set baseDir from the provided direction, never default to North
        if data.direction then
            baseDir = data.direction:normalize()
        elseif velocity and velocity:length() > 0.01 then
            baseDir = velocity:normalize()
        end

        -- Initialise signed-speed tracking
        if velocity then
            signedSpeed = velocity:length()
        end

        if data.boltModel and data.boltModel ~= "" then
            local opts = {
                useAmbientLight = true,
                loop            = true,
                vfxId           = vfxRecId or "MagExp_SpellVFX"
            }
            if data.particle and data.particle ~= "" then
                opts.particleTextureOverride = data.particle
            end
            boltVfxHandle = anim.addVfx(self, data.boltModel, opts)
        end

        -- Request Sound Anchor creation on global side
        if boltSound and boltSound ~= "" then
            core.sendGlobalEvent('MagExp_CreateSoundAnchor', {
                recordId   = "Colony_Assassin_act",
                sound      = boltSound,
                projectile = self
            })
            boltSound = nil
        end

        -- Request Light Anchor creation on global side
        if data.boltLightId then
            core.sendGlobalEvent('MagExp_CreateLightAnchor', {
                recordId   = data.boltLightId,
                projectile = self
            })
        end

    elseif data and data.isSoundAnchor then
        -- ---- Sound anchor initialization ----
        isProjectile = false
        boltSound    = data.sound
        if boltSound then
            core.sound.playSound3d(boltSound, self, { loop = true })
        end
    end
end

-- ============================================================
-- [PER FRAME] Physics update
-- ============================================================
local function onUpdate(dt)
    if isPaused or not isProjectile or hasCollided or not velocity then return end

    lifetime = lifetime + dt
    if lifetime > maxLifetime then
        hasCollided = true
        stopSound()
        core.sendGlobalEvent('MagExp_ProjectileExpired', {
            projectile  = self,
            spellId     = spellId,
            userData    = userData,
            soundAnchor = soundAnchor,
            lightAnchor = lightAnchor
        })
        return
    end

    -- ---- Spin ----
    if isRotating then
        rotSpinLog = rotSpinLog + spinSpeed * dt
        local spd = velocity:length()
        local dir = (spd > 0.01) and velocity:normalize() or baseDir
        
        local yaw   = math.atan2(dir.x, dir.y)
        local pitch = math.asin(math.max(-1, math.min(1, dir.z)))
        currentRotation = util.transform.rotateZ(yaw)
                        * util.transform.rotateX(-pitch)
                        * util.transform.rotateY(rotSpinLog)
    end

    -- ---- accelerationExp: exponential signed speed multiplier (positive=accelerate, negative=decelerate/reverse) ----
    -- signedSpeed can cross zero: when it goes negative the spell reverses along baseDir.
    if accelerationExp ~= 0 then
        signedSpeed = signedSpeed * math.exp(accelerationExp * dt)
        -- Optional cap: applies to magnitude (|signedSpeed|)
        if maxSpeed > 0 and math.abs(signedSpeed) > maxSpeed then
            signedSpeed = signedSpeed > 0 and maxSpeed or -maxSpeed
        end
        -- Reconstruct velocity: negative signedSpeed flips the direction
        velocity = baseDir * signedSpeed
    end

    -- ---- forceVec: true directional continuous force (units/sec²) ----
    -- Use this for deceleration, homing, gravity, or any directional push.
    if forceVec then
        velocity = velocity + forceVec * dt
        local spd = velocity:length()
        if spd < 0.5 then
            -- Spell has effectively stopped — expire gracefully
            hasCollided = true
            stopSound()
            core.sendGlobalEvent('MagExp_ProjectileExpired', {
                projectile  = self,
                soundAnchor = soundAnchor,
                lightAnchor = lightAnchor
            })
            return
        end
    end

    local from     = self.position
    local moveDist = velocity:length() * dt
    local dir      = velocity:normalize()
    local to       = from + dir * moveDist

    -- ---- 5-point cross raycast (physical volume simulation, radius ~12 units) ----
    local right = util.vector3(dir.y, -dir.x, 0):normalize()
    if right:length() < 0.01 then right = util.vector3(1, 0, 0) end
    local up      = dir:cross(right):normalize()
    local radius  = 12
    local offsets = {
        util.vector3(0, 0, 0),
        right * radius, -right * radius,
        up * radius,    -up * radius,
    }

    local lookAheadDist = moveDist * 2.0
    local ray           = nil

    for _, offset in ipairs(offsets) do
        local startPos = from + offset
        local endPos   = startPos + dir * lookAheadDist
        local hit      = nearby.castRay(startPos, endPos, { ignore = { self, attacker } })
        if hit.hit then
            local hitObj = hit.hitObject
            -- Dead actor pass-through
            if hitObj and hitObj:isValid()
               and types.Actor.objectIsInstance(hitObj)
               and types.Actor.isDead(hitObj) then
                -- skip
            else
                ray = hit; break
            end
        end
    end

    -- ---- Collision / Bounce decision ----
    if ray then
        local hitObj  = ray.hitObject
        local isActor = hitObj and hitObj:isValid()
                        and types.Actor.objectIsInstance(hitObj)
                        and not types.Actor.isDead(hitObj)

        local bounceLimitReached = (bounceMax > 0 and bounceCount >= bounceMax)

        -- Determine whether to detonate or bounce
        local shouldDetonate = true
        if bounceEnabled then
            if isActor then
                -- Actor: detonate unless detonateOnActorHit is disabled
                shouldDetonate = detonateOnActorHit or bounceLimitReached
            else
                -- Static / terrain: bounce unless limit reached
                shouldDetonate = bounceLimitReached
            end
        end

        if not shouldDetonate then
            -- ---- BOUNCE ----
            local n    = ray.hitNormal
            velocity   = (velocity - n * (2 * velocity:dot(n))) * bouncePower
            bounceCount = bounceCount + 1
            -- Nudge off surface to avoid re-hitting same polygon next frame
            core.sendGlobalEvent('MagExp_ProjectileMove', {
                projectile  = self,
                newPos      = ray.hitPos + n * 8,
                newRot      = currentRotation,
                soundAnchor = soundAnchor,
                lightAnchor = lightAnchor
            })
            core.sendGlobalEvent('MagExp_OnProjectileBounce', {
                projectile   = self,
                spellId      = spellId,
                attacker     = attacker,
                hitPos       = ray.hitPos,
                hitNormal    = ray.hitNormal,
                bounceCount  = bounceCount,
                speed        = velocity:length(),
                userData     = userData,
                soundAnchor  = soundAnchor,
                lightAnchor  = lightAnchor
            })
            -- Continue flying — do NOT set hasCollided
            return
        end

        -- ---- DETONATE ----
        impactSpeed = velocity:length()
        hasCollided = true
        stopSound()
        core.sendGlobalEvent('MagExp_ProjectileCollision', {
            projectile    = self,
            hitObject     = ray.hitObject,
            hitPos        = ray.hitPos,
            hitNormal     = ray.hitNormal,
            velocity      = velocity,
            impactSpeed   = impactSpeed,
            attacker      = attacker,
            spellId       = spellId,
            area          = area,
            effectIndexes = effectIndexes,
            soundAnchor   = soundAnchor,
            lightAnchor   = lightAnchor,
            vfxRecId      = vfxRecId,
            areaVfxRecId  = areaVfxRecId,
            impactImpulse = impactImpulse,
            unreflectable = unreflectable,
            casterLinked  = casterLinked,
            userData      = userData,
            muteAudio     = muteAudio,
            muteLight     = muteLight,
            continuousVfx = continuousVfx,
            effectScale   = effectScale
        })
        return
    end

    core.sendGlobalEvent('MagExp_ProjectileMove', {
        projectile  = self,
        newPos      = to,
        newRot      = currentRotation,
        soundAnchor = soundAnchor,
        lightAnchor = lightAnchor
    })
end

-- ============================================================
-- Event Handlers
-- ============================================================
return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        MagExp_InitProjectile = onInit,
        MagExp_InitSound      = onInit,
        MagExp_StopSound      = stopSound,

        MagExp_SetSoundAnchor = function(data) soundAnchor = data.anchor end,
        MagExp_SetLightAnchor = function(data) lightAnchor = data.anchor end,

        -- ----------------------------------------------------------------
        -- MagExp_SetPhysics: Full in-flight property mutation.
        -- All fields are optional; only provided keys are changed.
        -- ----------------------------------------------------------------
        MagExp_SetPhysics = function(data)
            -- Auto-unpause if speed/velocity provided unless isPaused is explicitly requested
            if (data.speed ~= nil or data.velocity ~= nil or data.direction ~= nil) and data.isPaused == nil then
                isPaused = false
            end

            if data.velocity ~= nil then
                velocity    = data.velocity
                signedSpeed = velocity:length()
                if signedSpeed > 0.01 then baseDir = velocity:normalize() end
            end
            -- speed: override magnitude, preserve direction
            if data.speed ~= nil then
                signedSpeed = data.speed   -- can be negative to travel backward from baseDir
                velocity    = baseDir * signedSpeed
            end
            -- direction: redirect, preserve current signed speed
            if data.direction ~= nil then
                baseDir  = data.direction:normalize()
                velocity = baseDir * signedSpeed
            end
            if data.accelerationExp    ~= nil then accelerationExp    = data.accelerationExp end
            if data.forceVec           ~= nil then forceVec           = data.forceVec end
            if data.maxSpeed           ~= nil then maxSpeed           = data.maxSpeed end
            if data.bounceEnabled      ~= nil then bounceEnabled      = data.bounceEnabled end
            if data.bounceMax          ~= nil then bounceMax          = data.bounceMax end
            if data.bouncePower        ~= nil then bouncePower        = data.bouncePower end
            if data.detonateOnActorHit ~= nil then detonateOnActorHit = data.detonateOnActorHit end
            if data.spellId            ~= nil then spellId            = data.spellId end
            if data.area               ~= nil then area               = data.area end
            if data.areaVfxRecId       ~= nil then areaVfxRecId       = data.areaVfxRecId end
            if data.vfxRecId           ~= nil then vfxRecId           = data.vfxRecId end
            if data.maxLifetime        ~= nil then maxLifetime        = data.maxLifetime end
            if data.impactImpulse      ~= nil then impactImpulse      = data.impactImpulse end
            if data.isPaused           ~= nil then isPaused           = data.isPaused end

            -- [SYNC] Tell global to update its registry so damage scales stay correct
            if data.maxSpeed or data.spellId or data.area then
                core.sendGlobalEvent('MagExp_UpdateRegistry', {
                    projId = self.id,
                    maxSpeed = maxSpeed,
                    spellId = spellId,
                    area = area
                })
            end
        end,

        -- ----------------------------------------------------------------
        -- MagExp_UpdatePhysics: Backward-compatibility alias.
        -- Always unpauses. New code should use MagExp_SetPhysics.
        -- ----------------------------------------------------------------
        MagExp_UpdatePhysics = function(data)
            if data.velocity        ~= nil then velocity        = data.velocity end
            if data.accelerationExp ~= nil then accelerationExp = data.accelerationExp end
            if data.maxSpeed        ~= nil then maxSpeed        = data.maxSpeed end
            if data.spellId         ~= nil then spellId         = data.spellId end
            if data.areaVfxRecId    ~= nil then areaVfxRecId    = data.areaVfxRecId end
            isPaused = false  -- always unpauses (original behaviour)
        end,

        -- ----------------------------------------------------------------
        -- MagExp_GetState: Returns a full state snapshot.
        -- Reply arrives as global event MagExp_SpellState { tag = ... }.
        -- ----------------------------------------------------------------
        MagExp_GetState = function(data)
            core.sendGlobalEvent('MagExp_SpellState', {
                projectile         = self,
                tag                = data and data.tag,
                velocity           = velocity,
                speed              = velocity and velocity:length() or 0,
                direction          = velocity and velocity:normalize() or util.vector3(0, 1, 0),
                position           = self.position,
                spellId            = spellId,
                area               = area,
                lifetime           = lifetime,
                maxLifetime        = maxLifetime,
                isPaused           = isPaused,
                accelerationExp    = accelerationExp,
                forceVec           = forceVec,
                maxSpeed           = maxSpeed,
                bounceEnabled      = bounceEnabled,
                bounceCount        = bounceCount,
                bounceMax          = bounceMax,
                bouncePower        = bouncePower,
                detonateOnActorHit = detonateOnActorHit,
                hasCollided        = hasCollided,
                vfxRecId           = vfxRecId,
                areaVfxRecId       = areaVfxRecId,
                impactImpulse      = impactImpulse,
                userData           = userData
            })
        end,

        -- ----------------------------------------------------------------
        -- MagExp_ForceCancel: Immediately expire the projectile.
        -- ----------------------------------------------------------------
        MagExp_ForceCancel = function()
            if hasCollided then return end
            hasCollided = true
            stopSound()
            core.sendGlobalEvent('MagExp_ProjectileExpired', {
                projectile  = self,
                userData    = userData,
                soundAnchor = soundAnchor,
                lightAnchor = lightAnchor
            })
        end,

        -- ----------------------------------------------------------------
        -- MagExp_ForceTeleport: Sync anchors when global moves the object.
        -- ----------------------------------------------------------------
        MagExp_ForceTeleport = function(data)
            local cellName, pos = data.cellName, data.pos
            if not pos then return end
            core.sendGlobalEvent('MagExp_AnchorTeleport', {
                cellName    = cellName,
                pos         = pos,
                lightAnchor = lightAnchor,
                soundAnchor = soundAnchor
            })
        end,
    },
}
