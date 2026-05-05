local core = require('openmw.core')
local util = require('openmw.util')

local M = {}

M.effectId = 'rt_conjure_soul_wisp_effect'
M.spellId = 'rt_conjure_soul_wisp'
M.visualRecordId = '4nm_totem'
M.wispScript = 'scripts/wispspell/effects/soulwisp/wisp.lua'

M.defaultDuration = 15
M.defaultMagnitude = 2
M.defaultRadius = 1800
M.visualZOffset = 90
M.scanInterval = 0.15
M.fadeOutTime = 1.0
M.splitPayloadProjectiles = true
M.baseProjectileSpeed = 1200 -- 1500
M.minProjectileSpeed = 700
M.maxProjectileSpeed = 6000

function M.log(scope, message)
    print('[wispspell][' .. tostring(scope) .. '] ' .. tostring(message))
end

function M.isValid(object)
    return object ~= nil and object:isValid()
end

function M.lower(value)
    if value == nil then return nil end
    return string.lower(tostring(value))
end

function M.copyEffect(effect)
    if not effect then return nil end

    local id = effect.id or (effect.effect and effect.effect.id)
    if not id then return nil end

    return {
        id = id,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
        range = effect.range or core.magic.RANGE.Target,
        area = effect.area or 0,
        duration = math.max(1, tonumber(effect.duration) or tonumber(effect.durationLeft) or 1),
        magnitudeMin = tonumber(effect.magnitudeMin or effect.minMagnitude or effect.magnitude or effect.magnitudeThisFrame) or 0,
        magnitudeMax = tonumber(effect.magnitudeMax or effect.maxMagnitude or effect.magnitude or effect.magnitudeThisFrame or effect.magnitudeMin or effect.minMagnitude) or 0,
    }
end

function M.asTargetEffect(effect)
    local copied = M.copyEffect(effect)
    if copied then copied.range = core.magic.RANGE.Target end
    return copied
end

function M.averageMagnitude(effect)
    local minMagnitude = tonumber(effect and (effect.magnitudeMin or effect.minMagnitude or effect.magnitude or effect.magnitudeThisFrame)) or M.defaultMagnitude
    local maxMagnitude = tonumber(effect and (effect.magnitudeMax or effect.maxMagnitude or effect.magnitude or effect.magnitudeThisFrame)) or minMagnitude
    return math.max(1, (minMagnitude + maxMagnitude) / 2)
end

function M.intervalFromMagnitude(magnitude)
    return util.clamp(6 / math.max(1, tonumber(magnitude) or M.defaultMagnitude), 0.5, 8)
end

function M.projectileSpeedFromMagnitude(magnitude)
    -- local m = math.max(1, tonumber(magnitude) or M.defaultMagnitude)
    -- return util.clamp(M.baseProjectileSpeed * (m / M.defaultMagnitude), M.minProjectileSpeed, M.maxProjectileSpeed)
    return M.baseProjectileSpeed -- Projectile speed scaling looked ugly, also magnitude already controls firing interval so it indirectly affects DPS.
end

function M.payloadIndexes(effects)
    local indexes = {}
    for i = 1, #(effects or {}) do
        indexes[i] = i - 1 -- OpenMW spell effect indexes are zero based.
    end
    return indexes
end

function M.objectHeightOffset(object, fallback)
    local z = fallback or 80
    if not M.isValid(object) then return z end
    pcall(function()
        local bbox = object:getBoundingBox()
        if bbox and bbox.halfSize then
            z = util.clamp(bbox.halfSize.z, 40, 120)
        end
    end)
    return z
end

return M
