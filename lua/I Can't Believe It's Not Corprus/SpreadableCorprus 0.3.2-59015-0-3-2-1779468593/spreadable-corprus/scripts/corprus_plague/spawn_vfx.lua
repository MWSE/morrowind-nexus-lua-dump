local core = require('openmw.core')
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')

local M = {}

local resolvedModel
local resolvedParticle

local function modelFromStaticId(staticId)
    if not staticId or staticId == '' then
        return nil
    end
    local staticRec = types.Static.record(staticId)
    if staticRec and staticRec.model and staticRec.model ~= '' then
        return staticRec.model
    end
    return nil
end

local function modelFromMagicEffect(mgef)
    if not mgef then
        return nil
    end
    for _, staticId in ipairs({ mgef.hitStatic, mgef.castStatic, mgef.areaStatic }) do
        local model = modelFromStaticId(staticId)
        if model then
            return model, mgef.particle
        end
    end
    return nil
end

local function resolveSpawnVfx()
    for _, effectId in ipairs(config.spawnVfxMagicEffectIds) do
        local mgef = core.magic.effects.records[effectId]
        local model, particle = modelFromMagicEffect(mgef)
        if model then
            return model, particle
        end
    end
    return nil
end

do
    local model, particle = resolveSpawnVfx()
    resolvedModel = model
    resolvedParticle = particle
end

function M.play(actor)
    if not resolvedModel then
        return
    end
    if not actor or not actor:isValid() then
        return
    end

    local options = {
        vfxId = config.spawnVfxId,
        loop = false,
    }
    if resolvedParticle and resolvedParticle ~= '' then
        options.particleTextureOverride = resolvedParticle
    end

    actor:sendEvent('AddVfx', {
        model = resolvedModel,
        options = options,
    })
end

return M
