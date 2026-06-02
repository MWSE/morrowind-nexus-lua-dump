-- ============================================================
-- Kinetic Bolt — GLOBAL Script
-- ============================================================

local world   = require('openmw.world')
local core    = require('openmw.core')
local types   = require('openmw.types')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')
local async   = require('openmw.async')

-- ============================================================
-- HOVER LOOP SOUND RECORD ID
-- ============================================================
local HOVER_SOUND_ID = 'kinetic_bolt'

local function startHoverLoop(obj)
    if not obj or not obj:isValid() then return end
    pcall(function()
        core.sound.playSound3d(HOVER_SOUND_ID, obj, { loop = true, volume = 0.55 })
    end)
end

local function stopHoverLoop(obj)
    if not obj or not obj:isValid() then return end
    pcall(function()
        core.sound.stopSound3d(HOVER_SOUND_ID, obj)
    end)
end

-- ============================================================
-- SPELL / EFFECT ID TABLES
-- ============================================================
local WATCHED_SPELLS = {
    kinetic_bolt = 'bolt',
    kinetic_expl = 'explosion',
}

local KINETIC_EFFECTS = {
    kb_mgef = 'bolt',
    ke_mgef = 'explosion',
}

local seenActiveSpellIds = {}

-- ============================================================
-- DEBUG LOGGING
-- ============================================================
local function debugLog(msg)
    print("[KineticForces] " .. tostring(msg))
end

-- ============================================================
-- EFFECT-BASED SPELL DETECTION
-- ============================================================
local detectKineticSpellByEffects
detectKineticSpellByEffects = function(activeSpellData, instanceId)
    local spellId = ''
    if activeSpellData.id then
        spellId = activeSpellData.id:lower()
    elseif activeSpellData.spell and activeSpellData.spell.id then
        spellId = activeSpellData.spell.id:lower()
    end

    local legacyHandler = WATCHED_SPELLS[spellId]
    if legacyHandler then
        debugLog("Detected legacy spell: " .. spellId .. " -> " .. legacyHandler)
        return legacyHandler
    end

    local effects = nil
    if activeSpellData.effects and type(activeSpellData.effects) == 'table' then
        effects = activeSpellData.effects
    end
    if not effects and activeSpellData.spell and activeSpellData.spell.effects then
        effects = activeSpellData.spell.effects
    end
    if not effects and spellId and spellId ~= '' then
        local spellRecord = nil
        pcall(function() spellRecord = core.magic.spells.records[spellId] end)
        if spellRecord and spellRecord.effects then
            effects = spellRecord.effects
        end
    end

    if not effects then return nil end

    for _, effect in ipairs(effects) do
        local effectId = effect.id
        if effectId then
            local handler = KINETIC_EFFECTS[effectId]
            if handler then
                if not seenActiveSpellIds[instanceId] then
                    debugLog("Detected custom spell with effect: " .. tostring(effectId) .. " -> " .. handler)
                end
                return handler
            end
        end
    end

    return nil
end

-- ============================================================
-- Independent State Containers
-- ============================================================
local boltState      = nil
local explosionState = nil

local SPELL_COST_BOLT  = 45
local SPELL_COST_EXPL  = 60
local SPIN_SPEED       = 10.0

local BOLT_CARRIER_REC = 'Colony_Assassin_act'

-- ============================================================
-- NO-COLLISION CARRIER RECORD (LIGHT) — Phase 1 only
-- ============================================================
local kineticCarrierLightRecId = nil

local function ensureNoCollisionCarrierRecId()
    if kineticCarrierLightRecId and types.Light.records[kineticCarrierLightRecId] then
        return kineticCarrierLightRecId
    end

    local ok, rec = pcall(function()
        local draft = types.Light.createRecordDraft({
            name        = "Kinetic Carrier (NoCollision)",
            color       = util.color and util.color.rgb and util.color.rgb(0, 0, 0) or util.vector3(0, 0, 0),
            radius      = 1,
            isDynamic   = true,
            isCarriable = false,
            isFire      = false,
            flicker     = false,
        })
        return world.createRecord(draft)
    end)

    if ok and rec and rec.id then
        kineticCarrierLightRecId = rec.id
        print("[KineticBolt] No-collision carrier record created:", kineticCarrierLightRecId)
        return kineticCarrierLightRecId
    end

    kineticCarrierLightRecId = BOLT_CARRIER_REC
    print("[KineticBolt] WARNING: failed to create no-collision carrier record; fallback:", kineticCarrierLightRecId)
    return kineticCarrierLightRecId
end

-- ============================================================
-- [BOLT LOGIC]
-- ============================================================
local function removeBolt()
    if boltState and boltState.bolt and boltState.bolt:isValid() then
        boltState.isRemoving = true
        stopHoverLoop(boltState.bolt)
        boltState.bolt:sendEvent('MagExp_ForceCancel')
    end
    boltState = nil
end

local function onBoltPhase1(data)
    print("[KineticBolt] Phase 1 - Bolt")
    local attacker = data.attacker
    if not attacker or not attacker:isValid() then return end

    local hDir = (data.direction or util.vector3(0, 1, 0)):normalize()
    local hPos = data.spawnPos or (attacker.position + hDir * 105 - util.vector3(0, 0, 50))

    local carrierRecId = ensureNoCollisionCarrierRecId()

    local bolt = I.MagExp.launchSpell({
        attacker           = attacker,
        spellId            = 'kb_launch',
        startPos           = hPos,
        direction          = hDir,
        spellType          = core.magic.RANGE.Target,

        speed              = 0,
        maxSpeed           = 5000,
        accelerationExp    = 0,

        spinSpeed          = 10.0,
        vfxRecId           = 'VFX_Soul_Trap',

        boltModel          = 'meshes/w/magic_target.nif',
        castModel          = 'meshes/e/magic_cast_myst.nif',
        hitModel           = 'meshes/e/magic_hit_myst.nif',

        boltLightId        = { color = util.vector3(0.6, 0.2, 0.9), radius = 250 },

        projectileRecordId = carrierRecId,
        muteAudio          = true,

        isFree             = true,
        unreflectable      = true,
        spawnOffset        = 0,
        maxLifetime        = 10,

        isPaused           = true,
        detonateOnImpact   = false,
        detonateOnStaticHit = false,

        -- FIX: piercing is intentional in Phase 1 so the hovering orb ignores corpses.
        --      It will NOT carry over to Phase 2.
        piercing           = true,
        pierceLimit        = nil,
    })

    print("[KineticBolt] Phase1 launch result:", bolt and (bolt:isValid() and "VALID" or "INVALID") or "NIL")

    if bolt and bolt:isValid() then
        startHoverLoop(bolt)
    end

    I.MagExp.applySpellToActor(attacker, 'kinetic_bolt')
    boltState = { bolt = bolt, dir = hDir, pos = hPos, attacker = attacker, rotX = 0, isRemoving = false }
end

local function onBoltPhase2()
    if not boltState or not boltState.bolt or not boltState.bolt:isValid() then return end
    local attacker = boltState.attacker
    local lDir     = boltState.dir
    local pos      = boltState.pos
    local boltObj  = boltState.bolt

    boltState.isRemoving = true
    stopHoverLoop(boltObj)

    if attacker and attacker:isValid() then
        attacker:sendEvent('KineticBolt_Refund', { amount = SPELL_COST_BOLT })
        types.Actor.activeSpells(attacker):remove('kinetic_bolt')
    end

    print("[KineticBolt] LAUNCHING BOLT (Phase 2)")

    pcall(function() boltObj:sendEvent('MagExp_ForceCancel') end)

    async:newUnsavableSimulationTimer(0.0, function()
        local bolt2 = I.MagExp.launchSpell({
            attacker             = attacker,
            spellId              = 'kb_launch',
            startPos             = pos,
            direction            = lDir,
            spellType            = core.magic.RANGE.Target,

            speed                = 40,
            maxSpeed             = 5000,
            accelerationExp      = 2.25,

            spinSpeed            = SPIN_SPEED,
            vfxRecId             = 'VFX_Soul_Trap',

            boltModel            = 'meshes/w/magic_target.nif',
            castModel            = 'meshes/e/magic_cast_myst.nif',
            hitModel             = 'meshes/e/magic_hit_myst.nif',

            boltLightId          = { color = util.vector3(0.6, 0.2, 0.9), radius = 250 },

            projectileRecordId   = nil,
            muteAudio            = false,

            isFree               = true,
            unreflectable        = true,
            spawnOffset          = 0,
            maxLifetime          = 10,

            detonateOnActorHit   = true,
            detonateOnImpact     = true,
            detonateOnStaticHit  = true,

            -- FIX: Do NOT set piercing = true here.
            -- Phase 2 must collide with actors so MagExp registers the hit,
            -- fires MagExp_OnMagicHit, and detonation triggers correctly.
            -- piercing = false is the default; omitting it is sufficient.
        })

        boltState = { bolt = bolt2, dir = lDir, pos = pos, attacker = attacker, rotX = 0, isRemoving = false }
    end)
end

-- ============================================================
-- [EXPLOSION LOGIC]
-- ============================================================
local function removeExplosion()
    if explosionState and explosionState.bolt and explosionState.bolt:isValid() then
        explosionState.isRemoving = true
        stopHoverLoop(explosionState.bolt)
        explosionState.bolt:sendEvent('MagExp_ForceCancel')
    end
    explosionState = nil
end

local function onExplosionPhase1(data)
    print("[KineticBolt] Phase 1 - Explosion")
    local attacker = data.attacker
    if not attacker or not attacker:isValid() then return end

    local hDir = (data.direction or util.vector3(0, 1, 0)):normalize()
    local hPos = data.spawnPos or (attacker.position + hDir * 105 - util.vector3(0, 0, 50))

    local carrierRecId = ensureNoCollisionCarrierRecId()

    local bolt = I.MagExp.launchSpell({
        attacker           = attacker,
        spellId            = 'ke_launch',
        startPos           = hPos,
        direction          = hDir,
        spellType          = core.magic.RANGE.Target,

        speed              = 0,
        maxSpeed           = 5000,
        accelerationExp    = 0,

        spinSpeed          = 10.0,
        vfxRecId           = 'VFX_Soul_Trap',

        areaVfxRecId       = 'VFX_MysticismArea',
        areaVfxScale       = 0.25,

        boltModel          = 'meshes/w/magic_target.nif',
        castModel          = 'meshes/e/magic_cast_myst.nif',
        hitModel           = 'meshes/e/magic_hit_myst.nif',

        boltLightId        = { color = util.vector3(0.6, 0.2, 0.9), radius = 250 },

        projectileRecordId = carrierRecId,
        muteAudio          = true,

        isFree             = true,
        unreflectable      = true,
        spawnOffset        = 0,
        maxLifetime        = 10,

        isPaused           = true,
        detonateOnImpact   = false,
        detonateOnStaticHit = false,

        -- FIX: piercing intentional in Phase 1 only (corpse immunity).
        piercing           = true,
        pierceLimit        = nil,
    })

    print("[KineticBolt] Explosion Phase1 launch result:", bolt and (bolt:isValid() and "VALID" or "INVALID") or "NIL")

    if bolt and bolt:isValid() then
        startHoverLoop(bolt)
    end

    I.MagExp.applySpellToActor(attacker, 'kinetic_expl')
    explosionState = { bolt = bolt, dir = hDir, pos = hPos, attacker = attacker, rotX = 0, isRemoving = false }
end

local function onExplosionPhase2()
    if not explosionState or not explosionState.bolt or not explosionState.bolt:isValid() then return end
    local attacker = explosionState.attacker
    local lDir     = explosionState.dir
    local pos      = explosionState.pos
    local boltObj  = explosionState.bolt

    explosionState.isRemoving = true
    stopHoverLoop(boltObj)

    if attacker and attacker:isValid() then
        attacker:sendEvent('KineticExplosion_Refund', { amount = SPELL_COST_EXPL })
        types.Actor.activeSpells(attacker):remove('kinetic_expl')
    end

    print("[KineticBolt] LAUNCHING EXPLOSION (Phase 2)")

    pcall(function() boltObj:sendEvent('MagExp_ForceCancel') end)

    async:newUnsavableSimulationTimer(0.0, function()
        local bolt2 = I.MagExp.launchSpell({
            attacker             = attacker,
            spellId              = 'ke_launch',
            startPos             = pos,
            direction            = lDir,
            spellType            = core.magic.RANGE.Target,

            speed                = 40,
            maxSpeed             = 5000,
            accelerationExp      = 2.25,

            spinSpeed            = SPIN_SPEED,
            vfxRecId             = 'VFX_Soul_Trap',

            areaVfxRecId         = 'VFX_MysticismArea',
            areaVfxScale         = 0.25,

            boltModel            = 'meshes/w/magic_target.nif',
            castModel            = 'meshes/e/magic_cast_myst.nif',
            hitModel             = 'meshes/e/magic_hit_myst.nif',

            boltLightId          = { color = util.vector3(0.6, 0.2, 0.9), radius = 250 },

            projectileRecordId   = nil,
            muteAudio            = false,

            isFree               = true,
            unreflectable        = true,
            spawnOffset          = 0,
            maxLifetime          = 10,

            area                 = 8,

            detonateOnActorHit   = true,
            detonateOnImpact     = true,
            detonateOnStaticHit  = true,

            -- FIX: Do NOT set piercing = true here.
            -- Phase 2 must collide with actors so MagExp registers the hit,
            -- fires MagExp_OnMagicHit, and detonation triggers correctly.
            -- piercing = false is the default; omitting it is sufficient.
        })

        explosionState = { bolt = bolt2, dir = lDir, pos = pos, attacker = attacker, rotX = 0, isRemoving = false }
    end)
end

-- ============================================================
-- onUpdate: Phase 1 follow (teleport) for both orbs
-- ============================================================
local function onUpdate(dt)
    if boltState and boltState.bolt and boltState.bolt:isValid() and not boltState.isRemoving then
        boltState.rotX = boltState.rotX + SPIN_SPEED * dt
        local d = boltState.dir
        local yaw   = math.atan2(d.x, d.y)
        local pitch = math.asin(math.max(-1, math.min(1, d.z)))
        local rot   = util.transform.rotateZ(yaw) * util.transform.rotateX(-pitch) * util.transform.rotateX(boltState.rotX)

        local cell = (boltState.attacker and boltState.attacker:isValid()) and boltState.attacker.cell or boltState.bolt.cell
        pcall(function()
            boltState.bolt:teleport(cell, boltState.pos, rot)
            boltState.bolt:sendEvent('MagExp_ForceTeleport', { cellName = cell.name, pos = boltState.pos })
        end)
    elseif boltState and (not boltState.bolt or not boltState.bolt:isValid()) then
        boltState = nil
    end

    if explosionState and explosionState.bolt and explosionState.bolt:isValid() and not explosionState.isRemoving then
        explosionState.rotX = explosionState.rotX + (SPIN_SPEED * 1.5) * dt
        local d = explosionState.dir
        local yaw   = math.atan2(d.x, d.y)
        local pitch = math.asin(math.max(-1, math.min(1, d.z)))
        local rot   = util.transform.rotateZ(yaw) * util.transform.rotateX(-pitch) * util.transform.rotateX(explosionState.rotX)

        local cell = (explosionState.attacker and explosionState.attacker:isValid()) and explosionState.attacker.cell or explosionState.bolt.cell
        pcall(function()
            explosionState.bolt:teleport(cell, explosionState.pos, rot)
            explosionState.bolt:sendEvent('MagExp_ForceTeleport', { cellName = cell.name, pos = explosionState.pos })
        end)
    elseif explosionState and (not explosionState.bolt or not explosionState.bolt:isValid()) then
        explosionState = nil
    end
end

-- ============================================================
-- Helper: checks if an actor already has a specific spell
-- ============================================================
local function hasSpell(actor, spellId)
    spellId = spellId:lower()
    local mySpells = types.Actor.spells(actor)
    for i = 1, #mySpells do
        if mySpells[i].id:lower() == spellId then
            return true
        end
    end
    return false
end

local injected_npcs = {}

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function()
            return {
                injected_npcs            = injected_npcs,
                kineticCarrierLightRecId = kineticCarrierLightRecId,
            }
        end,
        onLoad = function(data)
            if data then
                if data.injected_npcs            then injected_npcs            = data.injected_npcs            end
                if data.kineticCarrierLightRecId  then kineticCarrierLightRecId = data.kineticCarrierLightRecId  end
            end
        end,
        onActorActive = function(actor)
            if not types.NPC.objectIsInstance(actor) then return end
            if not actor.id or injected_npcs[actor.id] then return end

            local alteration = types.NPC.stats.skills.alteration(actor).base

            if alteration >= 40 then
                if not hasSpell(actor, "kinetic_bolt") then
                    types.Actor.spells(actor):add("kinetic_bolt")
                    print("[EnergyBolt] Injected Kinetic Bolt to: " .. actor.recordId)
                end
            end

            if alteration >= 60 then
                if not hasSpell(actor, "kinetic_expl") then
                    types.Actor.spells(actor):add("kinetic_expl")
                    print("[EnergyBolt] Injected Kinetic Explosion to: " .. actor.recordId)
                end
            end

            injected_npcs[actor.id] = true
        end
    },

    eventHandlers = {
        Bolt_Phase1 = onBoltPhase1,
        Bolt_Phase2 = onBoltPhase2,
        Bolt_Cancel = removeBolt,
        Bolt_Update = function(data)
            if boltState then
                boltState.pos = data.position
                boltState.dir = data.direction:normalize()
            end
        end,

        Explosion_Phase1 = onExplosionPhase1,
        Explosion_Phase2 = onExplosionPhase2,
        Explosion_Cancel = removeExplosion,
        Explosion_Update = function(data)
            if explosionState then
                explosionState.pos = data.position
                explosionState.dir = data.direction:normalize()
            end
        end,

        MagExp_CastRequest = function(data)
            local player = world.players[1]
            if not player or not player:isValid() then return end

            local handler = detectKineticSpellByEffects(data, data.instanceId or "unknown")
            if handler == 'bolt' then
                player:sendEvent('Bolt_CastDetected')
            elseif handler == 'explosion' then
                player:sendEvent('Explosion_CastDetected')
            end
        end,

        MagExp_ProjectileExpired = function(data)
            print("[MagExp] Projectile EXPIRED: " .. tostring(data.spellId or "nil"))
        end,

    MagExp_OnMagicHit = function(data)
    if not data or (data.spellId ~= 'kb_launch' and data.spellId ~= 'ke_launch') then
        return
    end

    -- Guard: ignore dead actors
    if data.target and data.target:isValid() and types.Actor.objectIsInstance(data.target) then
        if types.Actor.isDead(data.target) then
            print("[KineticBolt] Ignoring collision with dead body:", tostring(data.target.recordId or "unknown"))
            return
        end
    end

    -- Safe fallback so valid hits are never swallowed when impactSpeed is absent
    local spd    = data.impactSpeed or data.speed or 1000
    local maxSpd = data.maxSpeed or 5000

    local magMin = data.magMin or 10
    local magMax = data.magMax or magMin

    local ratio  = (maxSpd > 0) and (spd / maxSpd) or 1.0
    ratio = math.max(0, math.min(1.0, ratio))

    local finalDmg = magMin + (magMax - magMin) * ratio

    if data.target and data.target:isValid()
        and types.Actor.objectIsInstance(data.target)
        and not types.Actor.isDead(data.target) then

        data.target:sendEvent('Hit', {
            attacker   = data.attacker,
            damage     = { health = finalDmg },
            type       = 'Thrust',
            sourceType = 'Magic',
            successful = true,
            strength   = 1.0,
        })

        print(string.format("[KineticBolt] Hit %s for %.1f damage (speed %.0f / %.0f)",
            tostring(data.target.recordId or "?"), finalDmg, spd, maxSpd))
    end
    end,

        Kinetic_FailureEffects = function(data)
            if not data.pos then return end

            local soundAnchor = data.target
            local dummy = nil
            if not (soundAnchor and soundAnchor:isValid()) then
                dummy = world.createObject(BOLT_CARRIER_REC, data.pos)
                soundAnchor = dummy
            end

            core.sound.playSoundFile3d("sound/Fx/magic/altrFAIL.wav", soundAnchor)
            world.vfx.spawn('meshes/e/magic_hit.NIF', data.pos + util.vector3(0, 0, -30), { scale = 0.8 })

            if dummy then
                async:newUnsavableSimulationTimer(1.0, function()
                    if dummy:isValid() then dummy:remove() end
                end)
            end
        end,

        Bolt_CastDetected = function(data)
            if not data or not data.attacker or not data.attacker:isValid() then return end
            print("[KineticBolt] Global: Bolt_CastDetected received from OSSC")
            data.attacker:sendEvent('Bolt_CastDetected', {})
        end,

        Explosion_CastDetected = function(data)
            if not data or not data.attacker or not data.attacker:isValid() then return end
            print("[KineticBolt] Global: Explosion_CastDetected received from OSSC")
            data.attacker:sendEvent('Explosion_CastDetected', {})
        end,
    }
}