--[[
    Staves! — NPC Actor Script (CUSTOM)

    Applies Staves perk procs when the player hits this actor with a staff.
    Mirrors Throwing's pattern: reads a Runtime_Staves global storage section
    populated by the player script, applies effects, and sends a
    Staves_ResolvedHit event back to the player with proc details.

    Attached dynamically by scripts/Staves/global.lua via addScript().
]]

local core    = require('openmw.core')
local I       = require('openmw.interfaces')
local storage = require('openmw.storage')
local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')

local runtimeSection = storage.globalSection('Runtime_Staves')
local SILENCE_ID = core.magic.EFFECT_TYPE.Silence

local silenceMagnitudeApplied = 0
local silenceExpireTime = 0

local function get(key, default)
    local v = runtimeSection:get(key)
    if v == nil then return default end
    return v
end

local function playNamedSound(sound)
    if not sound or sound == '' then return end
    pcall(function()
        core.sound.playSound3d(sound, self)
    end)
end

local function playMagicEffectFx(effectId, fallbackSound)
    local effectRecord = core.magic.effects.records[effectId]
    if effectRecord and effectRecord.hitStatic and types.Static.records[effectRecord.hitStatic] then
        local model = types.Static.records[effectRecord.hitStatic].model
        if model then
            pcall(function() anim.addVfx(self, model) end)
        end
    end

    if effectRecord and effectRecord.school then
        playNamedSound(effectRecord.school .. ' hit')
    else
        playNamedSound(fallbackSound or 'illusion hit')
    end
end

local function clearSilenceEffect()
    if silenceMagnitudeApplied == 0 then return end
    local effects = types.Actor.activeEffects(self)
    effects:modify(-silenceMagnitudeApplied, SILENCE_ID)
    silenceMagnitudeApplied = 0
    silenceExpireTime = 0
end

local function updateTemporaryEffects()
    if silenceMagnitudeApplied ~= 0 and core.getSimulationTime() >= silenceExpireTime then
        clearSilenceEffect()
    end
end

local function applyNullPulse(data)
    local duration = math.max(0, tonumber(data and data.duration) or 0)
    if duration <= 0 or types.Actor.isDead(self) then return false end

    clearSilenceEffect()

    local effects = types.Actor.activeEffects(self)
    effects:modify(1, SILENCE_ID)
    silenceMagnitudeApplied = 1
    silenceExpireTime = core.getSimulationTime() + duration

    playMagicEffectFx(SILENCE_ID, data and data.sound or nil)
    return true
end

local function isStaffAttack(attack)
    if not attack or not attack.weapon then return false end
    if not types.Weapon.objectIsInstance(attack.weapon) then return false end
    local ok, record = pcall(types.Weapon.record, attack.weapon)
    if not ok or not record then return false end
    return record.type == types.Weapon.TYPE.BluntTwoWide
end

local function onHit(attack)
    if not get('active', false) then return end
    if not attack or attack.successful == false then return end
    if not attack.attacker or not types.Player.objectIsInstance(attack.attacker) then return end
    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
    if not isStaffAttack(attack) then return end
    if not attack.damage or type(attack.damage.health) ~= 'number' then return end

    local skill = tonumber(get('skill', 5)) or 5
    local procConcussive = false
    local procArcaneSiphon = false
    local procResonantConduit = false
    local procNullPulse = false
    local concussiveFatigue = 0
    local arcaneSiphonAmount = 0
    local resonantConduitCharge = 0

    -- 25: Concussive Strike — chance-based fatigue damage.
    if get('concussiveEnabled', true)
        and skill >= (tonumber(get('concussiveLevel', 25)) or 25) then
        local chance = tonumber(get('concussiveChance', 0)) or 0
        if math.random() <= chance then
            concussiveFatigue = tonumber(get('concussiveFatigue', 0)) or 0
            if concussiveFatigue > 0 then
                attack.damage.fatigue = (attack.damage.fatigue or 0) + concussiveFatigue
                procConcussive = true
                playNamedSound(get('concussiveSound', nil))
            end
        end
    end

    -- 50: Arcane Siphon — drains target magicka and sends the drained amount
    -- back to the player script so it can restore the player's magicka pool.
    if get('arcaneSiphonEnabled', true)
        and skill >= (tonumber(get('arcaneSiphonLevel', 50)) or 50) then
        local chance = tonumber(get('arcaneSiphonChance', 0)) or 0
        if math.random() <= chance then
            local requestedDrain = tonumber(get('arcaneSiphonAmount', 0)) or 0
            if requestedDrain > 0 then
                local magicka = types.Actor.stats.dynamic.magicka(self)
                local current = tonumber(magicka and magicka.current) or 0
                local actualDrain = math.min(current, requestedDrain)
                if actualDrain > 0 then
                    magicka.current = current - actualDrain
                    arcaneSiphonAmount = actualDrain
                    procArcaneSiphon = true
                    playNamedSound(get('arcaneSiphonSound', nil))
                end
            end
        end
    end

    -- 75: Resonant Conduit — rare burst of charge restoration on the player's
    -- equipped enchanted staff. The player script performs the inventory write.
    if get('resonantConduitEnabled', true)
        and skill >= (tonumber(get('resonantConduitLevel', 75)) or 75) then
        local chance = tonumber(get('resonantConduitChance', 0)) or 0
        if math.random() <= chance then
            resonantConduitCharge = tonumber(get('resonantConduitCharge', 0)) or 0
            if resonantConduitCharge > 0 then
                procResonantConduit = true
            end
        end
    end

    -- 100: Null Pulse — applies Silence locally and plays the Silence VFX/sound
    -- so the proc is readable even when visible feedback messages are disabled.
    if get('nullPulseEnabled', true)
        and skill >= (tonumber(get('nullPulseLevel', 100)) or 100) then
        local chance = tonumber(get('nullPulseChance', 0)) or 0
        if math.random() <= chance then
            procNullPulse = applyNullPulse({
                duration = tonumber(get('nullPulseDuration', 0)) or 0,
                sound = get('nullPulseSound', nil),
            })
        end
    end

    -- Feedback back to the player
    if procConcussive or procArcaneSiphon or procResonantConduit or procNullPulse then
        attack.attacker:sendEvent('Staves_ResolvedHit', {
            staffRecordId = get('staffRecordId', nil),
            procConcussive = procConcussive,
            procArcaneSiphon = procArcaneSiphon,
            procResonantConduit = procResonantConduit,
            procNullPulse = procNullPulse,
            concussiveFatigue = concussiveFatigue,
            arcaneSiphonAmount = arcaneSiphonAmount,
            resonantConduitCharge = resonantConduitCharge,
        })
    end
end

local function onLoad(data)
    silenceMagnitudeApplied = tonumber(data and data.silenceMagnitudeApplied) or 0
    silenceExpireTime = tonumber(data and data.silenceExpireTime) or 0
    updateTemporaryEffects()
end

local function onSave()
    return {
        silenceMagnitudeApplied = silenceMagnitudeApplied,
        silenceExpireTime = silenceExpireTime,
    }
end

return {
    engineHandlers = {
        onUpdate = function() updateTemporaryEffects() end,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        Hit = onHit,
        Staves_ApplyNullPulse = applyNullPulse,
    },
}
