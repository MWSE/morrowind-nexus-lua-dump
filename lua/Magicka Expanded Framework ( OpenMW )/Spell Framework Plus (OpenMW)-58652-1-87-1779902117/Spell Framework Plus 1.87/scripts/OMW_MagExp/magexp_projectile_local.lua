-- ============================================================
-- Spell Framework Plus - skrow42
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
local anchorRecordId = "Colony_Assassin_act" -- default fallback
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
local boltVfxId = nil
-- ---- Bounce system ----
local bounceEnabled      = false
local bounceMax          = 0       -- 0 = unlimited bounces until lifetime expires
local bounceCount        = 0
local bouncePower        = 0.7     -- restitution coeff: 1.0 = perfect elastic, 0 = dead stop

-- ---- Actor detonation rule ----
-- When true (default): actor contact always detonates regardless of remaining bounces.
-- When false: actors are treated as static surface for bounce purposes.
local detonateOnActorHit = true

-- ---- Piercing system ----
local piercing       = false  -- If true, projectile passes through actors
local pierceLimit    = nil    -- Max actor pass-throughs before the next actor collision (nil = unlimited)
local pierceCount    = 0      -- How many actors have been pierced so far
local piercedActors  = {}     -- Set of actor object keys to prevent double-piercing
local piercedActorObjects = {} -- Actor objects ignored by future raycasts for this projectile

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
    if boltVfxId and boltVfxId ~= "" then
        pcall(function() anim.removeVfx(self, boltVfxId) end)
        boltVfxId = nil
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
        -- Piercing
        piercing           = data.piercing           or false
        pierceLimit        = data.pierceLimit
        pierceCount        = 0
        piercedActors      = {}
        piercedActorObjects = {}
        unreflectable      = data.unreflectable      or false
        casterLinked       = data.casterLinked       or false
        -- Impact
        impactImpulse = data.impactImpulse or 0
        userData      = data.userData      or nil
        muteAudio     = data.muteAudio     or false
        muteLight     = data.muteLight     or false
        continuousVfx = data.continuousVfx or false
        effectScale   = data.effectScale
        anchorRecordId = data.anchorRecordId or anchorRecordId

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

        -- ============================================================
        -- ✅ FIX #3: LAYERED VFX for multi-element destruction spells
        -- Spawns ALL unique bolt VFX models simultaneously on the projectile.
        -- ============================================================
        if data.boltModels and #data.boltModels > 0 then
            print(string.format("[MagExp] Layering %d bolt VFX models on projectile", #data.boltModels))
            
            for i, model in ipairs(data.boltModels) do
                local vfxId = string.format("MagExpBolt_%s_%d", tostring(self.id), i)
                local particle = (data.particleTextures and data.particleTextures[i]) or ""
                
                print(string.format("[MagExp] Adding VFX layer %d/%d: model=%s particle=%s vfxId=%s",
                    i, #data.boltModels, tostring(model), tostring(particle), vfxId))
                
                local opts = {
                    loop = true,
                    vfxId = vfxId,
                    boneName = "", -- projectiles usually don't have bones
                }
                
                if particle ~= "" then
                    opts.particleTextureOverride = particle
                end
                
                pcall(function()
                    anim.addVfx(self, model, opts)
                end)
            end
            
        elseif data.boltModel and data.boltModel ~= "" then
            -- Fallback: single VFX (backward compatibility with old spells/mods)
            boltVfxId = vfxRecId or ("MagExp_Bolt_" .. tostring(self.id))

            print(string.format("[MagExp] Adding single projectile bolt VFX: model=%s vfxId=%s",
                tostring(data.boltModel), tostring(boltVfxId)))

            local opts = {
                loop = true,
                vfxId = boltVfxId,
                boneName = "",
            }
            
            if data.particle and data.particle ~= "" then
                opts.particleTextureOverride = data.particle
            end

            pcall(function()
                anim.addVfx(self, data.boltModel, opts)
            end)
        end

        -- Request Sound Anchor creation on global side
        if boltSound and boltSound ~= "" then
            core.sendGlobalEvent('MagExp_CreateSoundAnchor', { 
                recordId = anchorRecordId, 
                sound = boltSound, 
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

    local function isActorObject(obj)
        return obj and obj:isValid() and types.Actor.objectIsInstance(obj)
    end

    local function isLiveActorObject(obj)
        return isActorObject(obj) and not types.Actor.isDead(obj)
    end

    local function buildIgnoreList()
        local ignore = { self }
        if attacker then ignore[#ignore + 1] = attacker end
        for _, actor in pairs(piercedActorObjects) do
            if actor and actor:isValid() then
                ignore[#ignore + 1] = actor
            end
        end
        return ignore
    end

    local function castFirstHit(segmentFrom, segmentDistance)
        if segmentDistance <= 0 then return nil end
        local ignore = buildIgnoreList()
        for _, offset in ipairs(offsets) do
            local startPos = segmentFrom + offset
            local endPos   = startPos + dir * segmentDistance
            local hit      = nearby.castRay(startPos, endPos, { ignore = ignore })
            if hit.hit then
                local hitObj = hit.hitObject
                -- Dead actor pass-through
                if isActorObject(hitObj) and types.Actor.isDead(hitObj) then
                    -- skip
                else
                    return hit
                end
            end
        end
        return nil
    end

    local function sendPierceEvent(hitObj, hit)
        core.sendGlobalEvent('MagExp_OnProjectilePierce', {
            projectile    = self,
            hitObject     = hitObj,
            hitPos        = hit.hitPos,
            hitNormal     = hit.hitNormal,
            velocity      = velocity,
            impactSpeed   = velocity:length(),
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
            effectScale   = effectScale,
            pierceCount   = pierceCount,
            pierceLimit   = pierceLimit,
            isPierce      = true
        })
    end

    local function collideAfterPierceLimit(hitObj, hit)
        impactSpeed = velocity:length()
        hasCollided = true
        stopSound()
        core.sendGlobalEvent('MagExp_ProjectileCollision', {
            projectile    = self,
            hitObject     = hitObj,
            hitPos        = hit.hitPos,
            hitNormal     = hit.hitNormal,
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
            effectScale   = effectScale,
            pierceCount   = pierceCount,
            pierceLimit   = pierceLimit,
            isPierce      = false
        })
    end

    local segmentFrom = from
    local segmentDistance = lookAheadDist
    local maxPierceChecks = 1
    if piercing then
        maxPierceChecks = math.min((tonumber(pierceLimit) or 8) + 1, 16)
    end

    for _ = 1, maxPierceChecks do
        ray = castFirstHit(segmentFrom, segmentDistance)
        if not ray then break end

        local hitObj = ray.hitObject
        if piercing and isLiveActorObject(hitObj) then
            local actorKey = tostring(hitObj)
            if not piercedActors[actorKey] then
                -- pierceLimit is a pass-through budget: Pierce 3 ignores
                -- actors 1-3, then actor 4 collides through the normal path.
                if pierceLimit and pierceCount >= pierceLimit then
                    collideAfterPierceLimit(hitObj, ray)
                    return
                end

                piercedActors[actorKey] = true
                piercedActorObjects[actorKey] = hitObj
                pierceCount = pierceCount + 1
                sendPierceEvent(hitObj, ray)
            else
                piercedActorObjects[actorKey] = hitObj
            end

            -- Treat the pierced actor as non-blocking and keep checking the
            -- remaining segment so walls/statics behind the actor still collide.
            segmentFrom = ray.hitPos + dir * 1
            segmentDistance = lookAheadDist - (segmentFrom - from):length()
            ray = nil
            if segmentDistance <= 0 then break end
        else
            break
        end
    end

    -- ---- Collision / Bounce / Piercing decision ----
    if ray then
        local hitObj  = ray.hitObject
        local isActor = hitObj and hitObj:isValid()
                        and types.Actor.objectIsInstance(hitObj)
                        and not types.Actor.isDead(hitObj)

        local bounceLimitReached = (bounceMax > 0 and bounceCount >= bounceMax)

        -- Determine whether to detonate or bounce (non-piercing path)
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
            if data.piercing           ~= nil then piercing           = data.piercing end
            if data.pierceLimit        ~= nil then pierceLimit        = data.pierceLimit end
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
                piercing           = piercing,
                pierceLimit        = pierceLimit,
                pierceCount        = pierceCount,
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
