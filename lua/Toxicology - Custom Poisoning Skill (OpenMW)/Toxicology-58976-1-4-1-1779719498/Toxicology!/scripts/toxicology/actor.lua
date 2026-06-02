--[[
    Toxicology! — Actor script (NPC, CREATURE scope)

    When the player hits an NPC or creature with a poisoned weapon, we need
    to apply the poison's effects to the victim. The engine fires a `Hit`
    event on the defending actor with the AttackInfo payload, and that's
    our signal.

    Flow:
      1. Engine fires `Hit` on victim (this actor).
      2. We check: was the attacker the player? Did the attack succeed?
      3. If yes, we forward to global (which has itemData write access).
      4. Global reads the weapon's poisoned state, applies active spell
         effects to the victim, decrements charges.

    Kill tracking: we also listen for the victim's death and, if the last
    poisoned hit was recent, report a poison kill for XP.
]]

local core    = require('openmw.core')
local I       = require('openmw.interfaces')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local anim    = require('openmw.animation')

local config = require('scripts.toxicology.config')

local RANGED_ATTACK_SOURCE_TYPE = I.Combat and I.Combat.ATTACK_SOURCE_TYPES and I.Combat.ATTACK_SOURCE_TYPES.Ranged

local runtimeSection = storage.globalSection('Runtime_Toxicology')
local throwingRuntimeSection = storage.globalSection('Runtime_Throwing')
local projectileRuntimeSection = storage.globalSection('Runtime_ToxicologyProjectile')
local weaponPoisonSection = storage.globalSection('Runtime_ToxicologyWeaponPoison')
local THROWN_POISON_PREFIX = 'thrown:'
local WEAPON_POISON_NAMESPACE_KEY = '__activeNamespace'

local function liveWeaponPoisonStorageKey(key)
    if not key then return nil end
    local ns = weaponPoisonSection:get(WEAPON_POISON_NAMESPACE_KEY)
    if ns == nil then return nil end
    return tostring(ns) .. '|' .. tostring(key)
end
local THROWING_PENDING_WINDOW = 2.5
-- Long enough for held bow draws plus projectile flight; overwritten or
-- cleared on the next ranged attack-start edge.
local TOXICOLOGY_PROJECTILE_CONTEXT_WINDOW = 300.0

local function readRuntimeSetting(key, default)
    local value = runtimeSection:get(key)
    if value == nil then return default end
    return value
end

local function debugLog(msg)
    if readRuntimeSetting('debugMessages', false) and readRuntimeSetting('debugActorMessages', false) then
        print('[Toxicology!] ' .. tostring(msg))
    end
end

local function objectIsAvailable(obj)
    if not obj then return false end
    local ok, valid = pcall(function()
        if obj.isValid then return obj:isValid() end
        return true
    end)
    return ok and valid ~= false
end

local function safeWeaponRecord(weapon)
    if not objectIsAvailable(weapon) then return nil end
    local ok, isWeapon = pcall(types.Weapon.objectIsInstance, weapon)
    if not ok or not isWeapon then return nil end
    local okRec, rec = pcall(types.Weapon.record, weapon)
    if not okRec then return nil end
    return rec
end

local function safeObjectField(obj, field)
    if not objectIsAvailable(obj) then return nil end
    local ok, value = pcall(function() return obj[field] end)
    if not ok then return nil end
    return value
end

local function isThrownWeaponObject(weapon)
    local rec = safeWeaponRecord(weapon)
    return rec and rec.type == types.Weapon.TYPE.MarksmanThrown
end

local function poisonStorageKey(weapon)
    local rec = safeWeaponRecord(weapon)
    if not rec then return nil end
    if rec.type == types.Weapon.TYPE.MarksmanThrown then
        local recordId = safeObjectField(weapon, 'recordId')
        if not recordId then return nil end
        return THROWN_POISON_PREFIX .. tostring(recordId)
    end
    return safeObjectField(weapon, 'id')
end

local function poisonDataIsActive(data)
    return data and (data.poisonId ~= nil or data.layer2PoisonId ~= nil or data.layer3PoisonId ~= nil)
end

local function poisonedDataForKey(key)
    if not key then return nil end
    local liveKey = liveWeaponPoisonStorageKey(key)
    if not liveKey then return nil end
    local data = weaponPoisonSection:get(liveKey)
    if poisonDataIsActive(data) then
        return data
    end
    return nil
end

local function recentThrownRecordId()
    if not throwingRuntimeSection:get('active') then return nil end
    local recordId = throwingRuntimeSection:get('recordId')
    local releasedAt = throwingRuntimeSection:get('releasedAt')
    if not recordId or releasedAt == nil then return nil end

    local age = core.getSimulationTime() - releasedAt
    if age < 0 or age > THROWING_PENDING_WINDOW then return nil end
    return recordId
end

local function recentToxicologyProjectileContext()
    if not projectileRuntimeSection:get('active') then return nil end
    local token = projectileRuntimeSection:get('token')
    local weaponKey = projectileRuntimeSection:get('weaponKey')
    local recordId = projectileRuntimeSection:get('recordId')
    local weaponType = projectileRuntimeSection:get('weaponType')
    local releasedAt = projectileRuntimeSection:get('releasedAt')
    local poisonData = projectileRuntimeSection:get('poisonData')
    if token == nil or not weaponKey or releasedAt == nil then return nil end

    local age = core.getSimulationTime() - releasedAt
    if age < 0 or age > TOXICOLOGY_PROJECTILE_CONTEXT_WINDOW then return nil end

    return {
        token = token,
        key = weaponKey,
        recordId = recordId,
        weaponType = weaponType,
        poisonData = poisonData,
    }
end

local function firstUsableWeaponObject(...)
    for i = 1, select('#', ...) do
        local obj = select(i, ...)
        if safeWeaponRecord(obj) then return obj end
    end
    return nil
end

local function poisonedHitSource(attack)
    local weapon = firstUsableWeaponObject(attack.weapon, attack.projectile, attack.source)
    if weapon then
        local rec = safeWeaponRecord(weapon)
        local key = poisonStorageKey(weapon)
        -- Do not rely exclusively on attack.sourceType here. Some ranged hit
        -- payloads can still expose the bow as attack.weapon while the sourceType
        -- path is inconsistent, and then global would treat the hit as melee and
        -- spend a second charge. Match the active Toxicology projectile snapshot
        -- by weapon key for any hit source, then pass its token downstream.
        local projectile = recentToxicologyProjectileContext()
        if projectile and projectile.key ~= key then
            projectile = nil
        end

        local hasPoison = poisonedDataForKey(key) ~= nil
            or (projectile and poisonDataIsActive(projectile.poisonData))
        if hasPoison then
            local token = nil
            if projectile and projectile.key == key then
                token = projectile.token
            end
            return {
                key = key,
                weapon = weapon,
                recordId = safeObjectField(weapon, 'recordId'),
                weaponType = rec and rec.type,
                projectileToken = token,
            }
        end
    end

    -- Thrown or marksman projectiles may arrive in Hit events as already-unavailable
    -- object (@0x0). Prefer Toxicology's attack-start snapshot, which exists even
    -- after the coating has already been spent. Fall back to Throwing!'s short
    -- release state only for older/edge cases. Keep this scoped to ranged hits
    -- to avoid stale throw state ever affecting melee/unarmed impacts.
    if attack.sourceType ~= RANGED_ATTACK_SOURCE_TYPE then return nil end

    local projectile = recentToxicologyProjectileContext()
    if projectile and (poisonedDataForKey(projectile.key) or poisonDataIsActive(projectile.poisonData)) then
        return {
            key = projectile.key,
            weapon = nil,
            recordId = projectile.recordId,
            weaponType = projectile.weaponType,
            projectileToken = projectile.token,
        }
    end

    local recordId = recentThrownRecordId()
    if recordId then
        local key = THROWN_POISON_PREFIX .. tostring(recordId)
        if poisonedDataForKey(key) then
            return {
                key = key,
                weapon = nil,
                recordId = recordId,
                weaponType = types.Weapon.TYPE.MarksmanThrown,
                projectileToken = nil,
            }
        end
    end

    return nil
end

-- Track the last time this actor was hit by a poisoned weapon.
-- If it dies within killWindow seconds, we credit the kill to Toxicology.
local lastPoisonHit = {
    time = -math.huge,
    attacker = nil,
}
local DEATH_CHECK_INTERVAL = 0.25
local deathCheckTimer = math.random() * DEATH_CHECK_INTERVAL

local function isPoisonedWeapon(weapon)
    return poisonedDataForKey(poisonStorageKey(weapon)) ~= nil
end

local function onHit(attack)
    if not attack then return end
    if attack.successful == false then return end
    if not attack.attacker then return end
    if not types.Player.objectIsInstance(attack.attacker) then return end

    -- Quick filter: only forward to global if the weapon/throw record is
    -- actually poisoned. This avoids round-trip overhead on every player hit and
    -- prevents unavailable projectile objects from throwing objectIsInstance
    -- errors on thrown-weapon impacts.
    local source = poisonedHitSource(attack)
    if not source then return end

    -- Forward to global. Global has itemData write scope and will apply the
    -- poison's effects to us (self is the victim here).
    core.sendGlobalEvent('Toxicology_ApplyHit', {
        attacker = attack.attacker,
        victim = self.object,
        weapon = source.weapon,
        weaponKey = source.key,
        weaponRecordId = source.recordId,
        projectileToken = source.projectileToken,
        strength = attack.strength or 0,
        hitPos = attack.hitPos,
        sourceType = attack.sourceType,
        weaponType = source.weaponType,
    })

    lastPoisonHit.time = core.getSimulationTime()
    lastPoisonHit.attacker = attack.attacker

    -- XP for landing the strike — fired on the player, not here.
    attack.attacker:sendEvent('Toxicology_GrantXp', {
        useType = 'strike',
        amount = config.xp.strike,
    })
end

-- ─── Play hit FX (called from global) ─────────────────────────────────────
-- The global script can't call animation.addVfx or core.sound.playSound3d
-- directly on another actor — those APIs are "self only". So global sends
-- us this event with a list of effect IDs, and we fire the FX locally on
-- ourselves. Payload: { effectIds = { "damagehealth", "paralyze", ... } }
--
-- Pattern matches Poison Weapons mod (nexusmods 57257): pass `self` (the
-- module) directly to addVfx, use the effect's magic-school hit sound,
-- iterate per-effect.
local function onPlayFx(evt)
    debugLog('actor onPlayFx: received event on ' .. tostring(self.object))
    if not evt or not evt.effectIds then
        debugLog('actor onPlayFx: no effectIds in payload')
        return
    end
    local playVfx = readRuntimeSetting('hitVfx', true)
    local playSound = readRuntimeSetting('hitSound', true)
    if not playVfx and not playSound then return end

    for _, effId in ipairs(evt.effectIds) do
        local mgef = core.magic.effects.records[effId]
        if not mgef then
            debugLog('actor onPlayFx: no MagicEffect record for ' .. tostring(effId))
        else
            debugLog('actor onPlayFx: playing fx for ' .. tostring(effId) ..
                  ' (school=' .. tostring(mgef.school) .. ' hitStatic=' .. tostring(mgef.hitStatic) .. ')')
            -- Hit visual: spawn the effect's hit static model on us.
            if playVfx and mgef.hitStatic and types.Static.records[mgef.hitStatic] then
                local model = types.Static.records[mgef.hitStatic].model
                anim.addVfx(self, model)
            end
            -- Hit sound: use the magic school's generic hit sound, like "destruction hit".
            if playSound and mgef.school then
                core.sound.playSound3d(mgef.school .. ' hit', self)
            end
        end
    end
end

-- Death handler — if the victim dies soon after a poisoned hit, grant kill XP.
local function clearLastPoisonHit()
    lastPoisonHit.time = -math.huge
    lastPoisonHit.attacker = nil
end

local function onUpdate(dt)
    -- Only check death when we have a pending poisoned-hit track. This actor
    -- script can be attached to many NPCs/creatures, so avoid per-frame death
    -- and simulation-time reads while no poisoned hit is pending.
    if lastPoisonHit.time == -math.huge then return end

    deathCheckTimer = deathCheckTimer + (tonumber(dt) or 0)
    if deathCheckTimer < DEATH_CHECK_INTERVAL then return end
    while deathCheckTimer >= DEATH_CHECK_INTERVAL do
        deathCheckTimer = deathCheckTimer - DEATH_CHECK_INTERVAL
    end

    local now = core.getSimulationTime()
    if now - lastPoisonHit.time > config.xp.killWindow then
        clearLastPoisonHit()
        return
    end

    local isDead = types.Actor.isDead and types.Actor.isDead(self.object)
    if not isDead then return end

    if lastPoisonHit.attacker and types.Player.objectIsInstance(lastPoisonHit.attacker) then
        lastPoisonHit.attacker:sendEvent('Toxicology_GrantXp', {
            useType = 'kill',
            amount = config.xp.kill,
        })
    end

    -- Clear so we don't double-credit
    clearLastPoisonHit()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        Hit = onHit,
        Toxicology_PlayFx = onPlayFx,
    },
}
