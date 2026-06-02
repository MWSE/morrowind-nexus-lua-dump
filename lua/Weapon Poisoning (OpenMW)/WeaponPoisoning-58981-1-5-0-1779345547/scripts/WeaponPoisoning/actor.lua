local anim = require('openmw.animation')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')

local NPC_COMBAT_CHECK_INTERVAL = 1

local pendingNpcPoisonCastEffect = nil
local npcPoisonCombatPollingEnabled = false
local nextNpcPoisonCombatCheck = 0
local animationHandlersRegistered = false
local ensureAnimationHandlers
local activePoisonHitVfx = {}
local nextPoisonHitVfxId = 0

local function restorationCastSound()
    local effectType = core.magic.EFFECT_TYPE
    local restoreHealth = effectType and effectType.RestoreHealth or nil
    local effect = restoreHealth and core.magic.effects.records[restoreHealth] or nil
    return effect and effect.castSound or 'restoration cast'
end

local function restorationEffect()
    local effectType = core.magic.EFFECT_TYPE
    local restoreHealth = effectType and effectType.RestoreHealth or nil
    return restoreHealth and core.magic.effects.records[restoreHealth] or nil
end

local function playRestorationHitEffect()
    local effect = restorationEffect()

    pcall(function()
        local hitSound = effect and effect.hitSound or nil
        core.sound.playSound3d(hitSound and hitSound ~= '' and hitSound or 'restoration hit', self)
    end)

    pcall(function()
        if not effect then
            return
        end
        local hitStatic = effect.hitStatic and types.Static.records[effect.hitStatic] or nil
        if not hitStatic or not hitStatic.model then
            return
        end
        anim.addVfx(self, hitStatic.model, {
            particleTextureOverride = effect.particle,
            loop = false,
        })
    end)
end

local function poisonHitSound(magicEffect)
    if magicEffect.hitSound and magicEffect.hitSound ~= '' then
        return magicEffect.hitSound
    end

    local skill = magicEffect.school and core.stats.Skill.records[magicEffect.school] or nil
    local school = skill and skill.school or nil
    return school and school.hitSound or nil
end

local function poisonEffectIsActive(ref)
    for _, spell in pairs(types.Actor.activeSpells(self)) do
        if spell.id == ref.poisonRecordId then
            for _, effect in pairs(spell.effects) do
                if effect.id == ref.effectId and effect.index == ref.effectIndex then
                    return true
                end
            end
        end
    end
    return false
end

local function poisonHitVfxIsActive(entry)
    local activeRefs = {}
    for _, ref in ipairs(entry.refs) do
        if poisonEffectIsActive(ref) then
            activeRefs[#activeRefs + 1] = ref
        end
    end
    entry.refs = activeRefs
    return #activeRefs > 0
end

local function removeAllPoisonHitVfx()
    for vfxId in pairs(activePoisonHitVfx) do
        activePoisonHitVfx[vfxId] = nil
        pcall(function()
            anim.removeVfx(self, vfxId)
        end)
    end
end

local function removeInactivePoisonHitVfx()
    if types.Actor.isDead(self) then
        removeAllPoisonHitVfx()
        return
    end

    for vfxId, entry in pairs(activePoisonHitVfx) do
        if not poisonHitVfxIsActive(entry) then
            activePoisonHitVfx[vfxId] = nil
            pcall(function()
                anim.removeVfx(self, vfxId)
            end)
        end
    end
end

local function addPoisonHitVfx(model, particle, refs, loop)
    if loop then
        local key = model .. '\n' .. particle
        for _, entry in pairs(activePoisonHitVfx) do
            if entry.key == key then
                for _, ref in ipairs(refs) do
                    entry.refs[#entry.refs + 1] = ref
                end
                return
            end
        end

        nextPoisonHitVfxId = nextPoisonHitVfxId + 1
        local vfxId = 'wp_poison_hit_' .. tostring(nextPoisonHitVfxId)
        local ok = pcall(function()
            anim.addVfx(self, model, {
                vfxId = vfxId,
                particleTextureOverride = particle,
                loop = true,
            })
        end)
        if ok then
            activePoisonHitVfx[vfxId] = {
                key = key,
                refs = refs,
            }
        end
        return
    end

    pcall(function()
        anim.addVfx(self, model, {
            particleTextureOverride = particle,
            loop = false,
        })
    end)
end

local function playPoisonHitVfx(data)
    pcall(function()
        local poisonRecord = data and data.poisonRecordId and types.Potion.records[data.poisonRecordId] or nil
        if not poisonRecord or not poisonRecord.effects then
            return
        end

        local playedVfx = {}
        local playedSounds = {}
        local playVfx = data == nil or data.playVfx ~= false
        local playSound = data == nil or data.playSound ~= false
        local fullDuration = data and data.fullDuration == true
        for i, poisonEffect in ipairs(poisonRecord.effects) do
            local magicEffect = poisonEffect and core.magic.effects.records[poisonEffect.id] or nil
            if magicEffect then
                local hitSound = playSound and poisonHitSound(magicEffect) or nil
                if hitSound and hitSound ~= '' and not playedSounds[hitSound] then
                    playedSounds[hitSound] = true
                    pcall(function()
                        core.sound.playSound3d(hitSound, self)
                    end)
                end

                local hitStatic = magicEffect.hitStatic and types.Static.records[magicEffect.hitStatic] or nil
                if not hitStatic or not hitStatic.model then
                    hitStatic = types.Static.records['VFX_DefaultHit']
                end
                if playVfx and hitStatic and hitStatic.model then
                    local particle = magicEffect.particle or ''
                    local key = hitStatic.model .. '\n' .. particle
                    if not playedVfx[key] then
                        playedVfx[key] = {
                            refs = {},
                        }
                    end
                    if fullDuration then
                        local refs = playedVfx[key].refs
                        refs[#refs + 1] = {
                            poisonRecordId = poisonRecord.id,
                            effectId = poisonEffect.id,
                            effectIndex = i - 1,
                        }
                    end
                end
            end
        end

        for key, entry in pairs(playedVfx) do
            local separator = key:find('\n', 1, true)
            if separator then
                addPoisonHitVfx(key:sub(1, separator - 1), key:sub(separator + 1), entry.refs, fullDuration)
            end
        end
    end)
end

local function playNpcPoisonAnimation(data)
    local controller = I.AnimationController

    pcall(function()
        core.sound.playSound3d(restorationCastSound(), self)
    end)

    pcall(function()
        local poisonRecord = data and data.poisonRecordId and types.Potion.records[data.poisonRecordId] or nil
        local firstEffect = poisonRecord and poisonRecord.effects and poisonRecord.effects[1] or nil
        local magicEffect = firstEffect and core.magic.effects.records[firstEffect.id] or nil
        local handsStatic = types.Static.records['VFX_Hands']
        if not magicEffect or not handsStatic or not handsStatic.model then
            return
        end

        if anim.hasBone(self, 'Bip01 L Hand') then
            anim.addVfx(self, handsStatic.model, {
                boneName = 'Bip01 L Hand',
                particleTextureOverride = magicEffect.particle,
                loop = false,
            })
        end
        if anim.hasBone(self, 'Bip01 R Hand') then
            anim.addVfx(self, handsStatic.model, {
                boneName = 'Bip01 R Hand',
                particleTextureOverride = magicEffect.particle,
                loop = false,
            })
        end
    end)

    local animationStarted = false
    if ensureAnimationHandlers() and controller and type(controller.playBlendedAnimation) == 'function' then
        local ok = pcall(function()
            if anim.hasGroup(self, 'spellcast') == false then
                return
            end
            controller.playBlendedAnimation('spellcast', {
                startKey = 'self start',
                stopKey = 'self stop',
                priority = {
                    [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
                    [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
                    [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
                    [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.WeaponLowerBody,
                },
                blendMask = anim.BLEND_MASK.All,
                autoDisable = true,
                loops = 0,
                speed = 1,
            })
            pendingNpcPoisonCastEffect = true
            animationStarted = true
        end)
        animationStarted = ok and animationStarted
    end

    if not animationStarted then
        playRestorationHitEffect()
        core.sendGlobalEvent('WP_NpcPoisonAnimationComplete', { actor = self })
    end
end

local function onAnimationTextKey(groupname, key)
    if groupname ~= 'spellcast' or pendingNpcPoisonCastEffect ~= true then
        return
    end
    if key == 'self release' then
        pendingNpcPoisonCastEffect = nil
        playRestorationHitEffect()
        core.sendGlobalEvent('WP_NpcPoisonAnimationComplete', { actor = self })
    end
end

local function onAnimationEnded(groupname)
    if groupname ~= 'spellcast' or pendingNpcPoisonCastEffect ~= true then
        return
    end

    pendingNpcPoisonCastEffect = nil
    playRestorationHitEffect()
    core.sendGlobalEvent('WP_NpcPoisonAnimationComplete', { actor = self })
end

function ensureAnimationHandlers()
    if animationHandlersRegistered then
        return true
    end

    local controller = I.AnimationController
    if not controller
        or type(controller.addTextKeyHandler) ~= 'function'
        or type(controller.addAnimationEndedHandler) ~= 'function'
    then
        return false
    end

    controller.addTextKeyHandler('spellcast', onAnimationTextKey)
    controller.addAnimationEndedHandler(onAnimationEnded)
    animationHandlersRegistered = true
    return true
end

local function setNpcPoisonCombatPolling(data)
    npcPoisonCombatPollingEnabled = data and data.enabled == true
    nextNpcPoisonCombatCheck = 0
end

local function validCombatTarget(target)
    return target and target:isValid() and types.Actor.objectIsInstance(target) and not types.Actor.isDead(target)
end

local function npcPoisonCombatCheck()
    removeInactivePoisonHitVfx()

    if not npcPoisonCombatPollingEnabled then
        return
    end
    if self.type ~= types.NPC or types.Actor.isDead(self) then
        npcPoisonCombatPollingEnabled = false
        return
    end

    local now = core.getSimulationTime()
    if now < nextNpcPoisonCombatCheck then
        return
    end
    nextNpcPoisonCombatCheck = now + NPC_COMBAT_CHECK_INTERVAL

    local ai = I.AI
    if not ai or type(ai.getTargets) ~= 'function' then
        return
    end

    local target = nil
    if type(ai.getActiveTarget) == 'function' then
        local ok, activeTarget = pcall(ai.getActiveTarget, 'Combat')
        if ok and validCombatTarget(activeTarget) then
            target = activeTarget
        end
    end

    local ok, targets = pcall(ai.getTargets, 'Combat')
    if not ok or not targets or #targets == 0 then
        return
    end
    if not target then
        for _, candidate in ipairs(targets) do
            if validCombatTarget(candidate) then
                target = candidate
                break
            end
        end
    end
    if not target then
        return
    end

    core.sendGlobalEvent('WP_NpcPoisonCombatCandidate', {
        actor = self,
        target = target,
    })
end

I.Combat.addOnHitHandler(function(attack)
    if attack and attack.successful == true and attack.attacker and attack.weapon then
        core.sendGlobalEvent('WP_WeaponHit', {
            attacker = attack.attacker,
            target = self,
            weapon = attack.weapon,
        })
    end
end)

return {
    eventHandlers = {
        WP_PlayNpcPoisonAnimation = playNpcPoisonAnimation,
        WP_PlayPoisonHitVfx = playPoisonHitVfx,
        WP_ClearPoisonHitVfx = removeAllPoisonHitVfx,
        WP_SetNpcPoisonCombatPolling = setNpcPoisonCombatPolling,
    },
    engineHandlers = {
        onUpdate = npcPoisonCombatCheck,
    },
}
