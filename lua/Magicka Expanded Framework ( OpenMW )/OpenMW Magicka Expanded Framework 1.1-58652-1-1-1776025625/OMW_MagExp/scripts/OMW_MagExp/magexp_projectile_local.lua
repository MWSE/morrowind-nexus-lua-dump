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

local velocity     = nil
local attacker     = nil
local spellId      = nil
local area         = 0
local lifetime     = 0
local maxLifetime  = 10
local hasCollided  = false
local boltSound    = nil
local soundAnchor  = nil
local lightAnchor  = nil
local isRotating   = false
local currentRotation = nil
local rotSpinLog   = 0
local spinSpeed    = 0
local boltVfxHandle = nil
local isProjectile = false

local function stopSound()
    if boltSound then
        pcall(function() core.sound.stopSound3d(boltSound, self) end)
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
        pcall(function() boltVfxHandle:remove() end)
        boltVfxHandle = nil
    end
end

local function onInit(data)
    if data and data.velocity then
        -- Main projectile initialization
        isProjectile    = true
        velocity        = data.velocity
        attacker        = data.attacker
        spellId         = data.spellId
        area            = data.area or 0
        boltSound       = data.boltSound or nil
        lifetime        = 0
        hasCollided     = false
        isRotating      = false
        currentRotation = self.rotation
        spinSpeed       = data.spinSpeed or 0
        maxLifetime     = data.maxLifetime or 10
        if spinSpeed > 0 then isRotating = true end

        if data.boltModel and data.boltModel ~= "" then
            local opts = {
                useAmbientLight = true,
                loop = true,
                vfxId = data.vfxRecId or "MagExp_SpellVFX"
            }
            if data.particle and data.particle ~= "" then
                opts.particleTextureOverride = data.particle
            end
            boltVfxHandle = anim.addVfx(self, data.boltModel, opts)
        end

        -- Request Sound Anchor creation on global side
        if boltSound and boltSound ~= "" then
            core.sendGlobalEvent('MagExp_CreateSoundAnchor', {
                recordId  = "Colony_Assassin_act",
                sound     = boltSound,
                projectile = self
            })
            boltSound = nil
        end

        -- Request Light Anchor creation on global side
        if data.boltLightId then
            core.sendGlobalEvent('MagExp_CreateLightAnchor', {
                recordId  = data.boltLightId,
                projectile = self
            })
        end

    elseif data and data.isSoundAnchor then
        -- Sound anchor initialization
        isProjectile = false
        boltSound    = data.sound
        if boltSound then
            core.sound.playSound3d(boltSound, self, { loop = true })
        end
    end
end

local function onUpdate(dt)
    if not isProjectile or hasCollided or not velocity then return end

    lifetime = lifetime + dt
    if lifetime > maxLifetime then
        hasCollided = true
        stopSound()
        core.sendGlobalEvent('MagExp_ProjectileExpired', {
            projectile  = self,
            soundAnchor = soundAnchor,
            lightAnchor = lightAnchor
        })
        return
    end

    if isRotating then
        rotSpinLog = rotSpinLog + spinSpeed * dt
        local dir   = velocity:normalize()
        local yaw   = math.atan2(dir.x, dir.y)
        local pitch = math.asin(dir.z)
        currentRotation = util.transform.rotateZ(yaw) * util.transform.rotateX(-pitch) * util.transform.rotateY(rotSpinLog)
    end

    local from = self.position
    local to   = from + velocity * dt

    local hit = nearby.castRay(from, to, { ignore = { self, attacker } })
    if hit.hit then
        hasCollided = true
        stopSound()
        core.sendGlobalEvent('MagExp_ProjectileCollision', {
            projectile  = self,
            hitObject   = hit.hitObject,
            hitPos      = hit.hitPos,
            hitNormal   = hit.hitNormal,
            velocity    = velocity,
            attacker    = attacker,
            spellId     = spellId,
            area        = area,
            soundAnchor = soundAnchor,
            lightAnchor = lightAnchor
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

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        MagExp_InitProjectile  = onInit,
        MagExp_InitSound       = onInit,
        MagExp_StopSound       = stopSound,
        MagExp_SetSoundAnchor  = function(data) soundAnchor = data.anchor end,
        MagExp_SetLightAnchor  = function(data) lightAnchor = data.anchor end,
    },
}
