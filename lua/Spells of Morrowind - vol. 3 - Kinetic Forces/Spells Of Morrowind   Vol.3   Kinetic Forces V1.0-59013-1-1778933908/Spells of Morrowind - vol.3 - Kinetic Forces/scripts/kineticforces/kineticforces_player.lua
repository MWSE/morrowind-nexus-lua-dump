-- ============================================================
-- Kinetic Bolt — PLAYER Script
-- Independent logic paths for Bolt and Explosion.
-- ============================================================

local self   = require('openmw.self')
local types  = require('openmw.types')
local core   = require('openmw.core')
local input  = require('openmw.input')
local async  = require('openmw.async')
local camera = require('openmw.camera')
local util   = require('openmw.util')
local I      = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local anim   = require('openmw.animation')
local debug  = require('openmw.debug')
local ui     = require('openmw.ui')

-- Independent Phase States
local boltState      = { phase = 0, gen = 0 }
local explosionState = { phase = 0, gen = 0 }
local isUseBlocked = false

local CAST_DELAY  = 0.9
local COOLDOWN    = 1.8
local lastCastEndTime = -10
local isCastActive = false
local isCastIntentActive = false

-- ============================================================
-- ANIMATION GROUPS TO INTERCEPT
-- All groups that can trigger a kinetic cast.
-- Each gets its own explicit handler registration below.
-- ============================================================
local CAST_GROUPS = {
    'spellcast',
    'quickcast',
    'quickbuff',
    'qcconj',
    'qctouch',
    'qcalt',
    'qcalts',
    'qcill',
    'qcsnap',
    'qcdrain',
    'qcskrow',
}

-- ============================================================
-- [CAMERA]
-- ============================================================
local function getSuspensionPos()
    local pitch = -camera.getPitch()
    local yaw = camera.getYaw()

    local MODE_1ST = 1
    if camera.getMode and camera.MODE and camera.getMode() ~= camera.MODE.FirstPerson then
        pitch = 0
        local fwd = self.rotation * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    elseif not camera.getMode then
        pitch = 0
        local fwd = self.rotation * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    end

    local dir = util.vector3(math.cos(pitch) * math.sin(yaw), math.cos(pitch) * math.cos(yaw), math.sin(pitch))
    local eyePos = self.position + util.vector3(0, 0, 85)
    local targetPos = eyePos + dir * 105

    local hit = nearby.castRay(eyePos, targetPos, { ignore = self })
    if hit and hit.hitPos then
        if hit.hitObject and hit.hitObject.type and (hit.hitObject.type == types.NPC or hit.hitObject.type == types.Creature) then
            return hit.hitPos, dir, true, hit.hitObject
        end
        local dist = (hit.hitPos - eyePos):length()
        targetPos = eyePos + dir * math.max(0, dist - 15)
    end

    return targetPos, dir, false
end

-- ============================================================
-- [MUTUAL CANCELLATION HELPERS]
-- ============================================================
local function cancelBolt(pos, target)
    if boltState.phase == 1 then
        boltState.phase = 0
        boltState.gen = boltState.gen + 1
        core.sendGlobalEvent('Bolt_Cancel', { pos = pos })
        if pos then
            core.sendGlobalEvent('Kinetic_FailureEffects', { pos = pos, target = target, sound = 'spell failure alteration', vfx = 'VFX_AlterationCast' })
        end
    end
end

local function cancelExplosion(pos, target)
    if explosionState.phase == 1 then
        explosionState.phase = 0
        explosionState.gen = explosionState.gen + 1
        core.sendGlobalEvent('Explosion_Cancel', { pos = pos })
        if pos then
            core.sendGlobalEvent('Kinetic_FailureEffects', { pos = pos, target = target, sound = 'spell failure alteration', vfx = 'VFX_AlterationCast' })
        end
    end
end

-- ============================================================
-- [BOLT LOGIC]
-- ============================================================
local function tryAdvanceBolt()
    local spawnPos, dir, shouldCancel, target = getSuspensionPos()
    if shouldCancel then cancelBolt(spawnPos, target); return end

    if boltState.phase == 0 then
        if not debug.isGodMode() then
            local spell = core.magic.spells.records['kinetic_bolt']
            local cost = spell and (spell.cost or 0) or 45
            local magicka = types.Actor.stats.dynamic.magicka(self)
            if magicka.current < cost then
                ui.showMessage("You do not have enough magicka to cast the spell.")
                return
            end
            magicka.current = magicka.current - cost
        end

        cancelExplosion()
        boltState.phase = 1
        core.sendGlobalEvent('Bolt_Phase1', { attacker = self, spawnPos = spawnPos, direction = dir })

        local myGen = boltState.gen
        async:newUnsavableSimulationTimer(10, function()
            if boltState.gen == myGen and boltState.phase == 1 then
                local p = getSuspensionPos()
                cancelBolt(p, self)
                print("[KineticBolt] Orb Dissipated (Timeout)")
            end
        end)
    else
        boltState.phase = 0
        boltState.gen = boltState.gen + 1
        lastCastEndTime = core.getSimulationTime()
        core.sendGlobalEvent('Bolt_Phase2', { attacker = self, direction = dir })
    end
end

-- ============================================================
-- [EXPLOSION LOGIC]
-- ============================================================
local function tryAdvanceExplosion()
    local spawnPos, dir, shouldCancel, target = getSuspensionPos()
    if shouldCancel then cancelExplosion(spawnPos, target); return end

    if explosionState.phase == 0 then
        if not debug.isGodMode() then
            local spell = core.magic.spells.records['kinetic_expl']
            local cost = spell and (spell.cost or 0) or 60
            local magicka = types.Actor.stats.dynamic.magicka(self)
            if magicka.current < cost then
                ui.showMessage("You do not have enough magicka to cast the spell.")
                return
            end
            magicka.current = magicka.current - cost
        end

        cancelBolt()
        explosionState.phase = 1
        core.sendGlobalEvent('Explosion_Phase1', { attacker = self, spawnPos = spawnPos, direction = dir })

        local myGen = explosionState.gen
        async:newUnsavableSimulationTimer(10, function()
            if explosionState.gen == myGen and explosionState.phase == 1 then
                local p = getSuspensionPos()
                cancelExplosion(p, self)
                print("[KineticExpl] Orb Dissipated (Timeout)")
            end
        end)
    else
        explosionState.phase = 0
        explosionState.gen = explosionState.gen + 1
        lastCastEndTime = core.getSimulationTime()
        core.sendGlobalEvent('Explosion_Phase2', { attacker = self, direction = dir })
    end
end

-- ============================================================
-- Input Handler
-- ============================================================
local function onInputAction(action)
    if action ~= input.ACTION.Use then return end

    local now = core.getSimulationTime()
    local stance = types.Actor.getStance(self)

    if now < (lastCastEndTime + COOLDOWN) and stance == types.Actor.STANCE.Spell then
        local sel = types.Actor.getSelectedSpell(self)
        if sel and (sel.id == 'kinetic_bolt' or sel.id == 'kinetic_expl') then
            if boltState.phase == 0 and explosionState.phase == 0 then
                return
            end
        end
    end

    if stance == types.Actor.STANCE.Weapon then
        if boltState.phase == 1 then
            boltState.phase, boltState.gen = 0, boltState.gen + 1
            core.sendGlobalEvent('Bolt_Cancel', {})
        end
        if explosionState.phase == 1 then
            explosionState.phase, explosionState.gen = 0, explosionState.gen + 1
            core.sendGlobalEvent('Explosion_Cancel', {})
        end
        return
    end

    if stance ~= types.Actor.STANCE.Spell then return end
    local sel = types.Actor.getSelectedSpell(self)
    if not sel then return end

    if sel.id == 'kinetic_bolt' or sel.id == 'kinetic_expl' then
        if now < (lastCastEndTime + COOLDOWN) then return end

        -- Check if ANY of our cast groups is currently playing
        local castPlaying = false
        for _, g in ipairs(CAST_GROUPS) do
            if anim.isPlaying(self, g) then
                castPlaying = true
                break
            end
        end
        if castPlaying then return end

        isCastIntentActive = true
    end
end

-- ============================================================
-- Text Key Handler
-- Registered once per group in CAST_GROUPS below.
-- ============================================================
local function onTextKey(group, key)
    local lowerKey = tostring(key):lower()
    local now = core.getSimulationTime()
    local sel = types.Actor.getSelectedSpell(self)

    if not isCastIntentActive or not sel then return end

    if sel.id == 'kinetic_bolt' then
        if now < (lastCastEndTime + COOLDOWN) then return end

        if boltState.phase == 0 and lowerKey:find('release') then
            if isCastActive then return end
            isCastActive = true
            isCastIntentActive = false  -- Block new input until release completes
            local myGen = boltState.gen
            async:newUnsavableSimulationTimer(0.1, function()
                if boltState.gen == myGen and boltState.phase == 0 then tryAdvanceBolt() end
                isCastActive = false  -- Allow new input after release completes
            end)

        elseif boltState.phase == 1 and lowerKey:find('release') then
            if isCastActive then return end
            isCastActive = true
            isCastIntentActive = false  -- Block new input until release completes
            local myGen = boltState.gen
            async:newUnsavableSimulationTimer(0.08, function()
                if boltState.gen == myGen and boltState.phase == 1 then tryAdvanceBolt() end
                isCastActive = false  -- Allow new input after release completes
            end)
        end

    elseif sel.id == 'kinetic_expl' then
        if now < (lastCastEndTime + COOLDOWN) then return end

        if explosionState.phase == 0 and lowerKey:find('release') then
            if isCastActive then return end
            isCastActive = true
            isCastIntentActive = false  -- Block new input until release completes
            local myGen = explosionState.gen
            async:newUnsavableSimulationTimer(0.1, function()
                if explosionState.gen == myGen and explosionState.phase == 0 then tryAdvanceExplosion() end
                isCastActive = false  -- Allow new input after release completes
            end)

        elseif explosionState.phase == 1 and lowerKey:find('release') then
            if isCastActive then return end
            isCastActive = true
            isCastIntentActive = false  -- Block new input until release completes
            local myGen = explosionState.gen
            async:newUnsavableSimulationTimer(0.08, function()
                if explosionState.gen == myGen and explosionState.phase == 1 then tryAdvanceExplosion() end
                isCastActive = false  -- Allow new input after release completes
            end)
        end
    end
end

-- ============================================================
-- REGISTER TEXT KEY HANDLER FOR EVERY CAST GROUP EXPLICITLY
-- Using '' alone is unreliable for custom/modded animation groups.
-- We register once for each group so none are missed.
-- ============================================================
if I.AnimationController then
    -- Keep the catch-all for anything we didn't list
    I.AnimationController.addTextKeyHandler('', onTextKey)

    -- Explicit per-group registrations (custom groups require this)
    for _, group in ipairs(CAST_GROUPS) do
        I.AnimationController.addTextKeyHandler(group, onTextKey)
    end
end

-- ============================================================
-- Update Loop
-- ============================================================
local function onUpdate(dt)
    local now = core.getSimulationTime()

    -- [GLOBAL COOLDOWN] Block engine casting if on cooldown
    if now < lastCastEndTime + COOLDOWN and not isCastActive then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Spell then
            local sel = types.Actor.getSelectedSpell(self)
            if sel and (sel.id == 'kinetic_bolt' or sel.id == 'kinetic_expl') then
                for _, g in ipairs(CAST_GROUPS) do
                    if anim.isPlaying(self, g) then
                        anim.cancel(self, g)
                    end
                end
            end
        end
    end

    -- [ANIMATION TRACKING CLEANUP]
    -- Reset cast flags when no cast group is playing anymore
    local anyPlaying = false
    for _, g in ipairs(CAST_GROUPS) do
        if anim.isPlaying(self, g) then
            anyPlaying = true
            break
        end
    end
    if not anyPlaying then
        isCastActive = false
        isCastIntentActive = false
    end

    -- Update Bolt Position
    if boltState.phase == 1 then
        local p, d, shouldCancel, target = getSuspensionPos()
        if shouldCancel then
            cancelBolt(p, target)
        else
            core.sendGlobalEvent('Bolt_Update', { position = p, direction = d })
        end
    end

    -- Update Explosion Position
    if explosionState.phase == 1 then
        local p, d, shouldCancel, target = getSuspensionPos()
        if shouldCancel then
            cancelExplosion(p, target)
        else
            core.sendGlobalEvent('Explosion_Update', { position = p, direction = d })
        end
    end
end

return {
    engineHandlers = { onUpdate = onUpdate, onInputAction = onInputAction },
    eventHandlers = {
        Bolt_CastDetected = function(data)
            local now = core.getSimulationTime()
            if now < lastCastEndTime + COOLDOWN then return end
            if boltState.phase == 0 then tryAdvanceBolt()
            elseif boltState.phase == 1 then tryAdvanceBolt()
            end
        end,
        Explosion_CastDetected = function(data)
            local now = core.getSimulationTime()
            if now < lastCastEndTime + COOLDOWN then return end
            if explosionState.phase == 0 then tryAdvanceExplosion()
            elseif explosionState.phase == 1 then tryAdvanceExplosion()
            end
        end,
        KineticBolt_Refund = function(data)
            types.Actor.stats.dynamic.magicka(self).current = math.min(
                types.Actor.stats.dynamic.magicka(self).current + (data.amount or 45),
                types.Actor.stats.dynamic.magicka(self).base + types.Actor.stats.dynamic.magicka(self).modifier
            )
            print("[KineticBolt] Magicka Refunded (Bolt)")
        end,
        KineticExplosion_Refund = function(data)
            types.Actor.stats.dynamic.magicka(self).current = math.min(
                types.Actor.stats.dynamic.magicka(self).current + (data.amount or 60),
                types.Actor.stats.dynamic.magicka(self).base + types.Actor.stats.dynamic.magicka(self).modifier
            )
            print("[KineticBolt] Magicka Refunded (Explosion)")
        end,
    }
}