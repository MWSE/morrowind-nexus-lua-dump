---@omw-context global
local log = require("scripts.spellforge.shared.log").new("global.runtime_session")

local runtime_session = {}

local runtime_generation = 0
local projectile_generations = {}

local function normalizeGeneration(value)
    local generation = tonumber(value)
    if generation == nil or generation ~= generation or generation == math.huge or generation == -math.huge then
        return nil
    end
    return generation
end

local function generationFrom(value)
    if type(value) == "table" then
        return normalizeGeneration(value.runtime_generation)
    end
    return normalizeGeneration(value)
end

function runtime_session.currentGeneration()
    return runtime_generation
end

function runtime_session.stamp(value)
    if type(value) == "table" then
        value.runtime_generation = runtime_generation
    end
    return value
end

function runtime_session.increment(reason)
    local before = runtime_generation
    runtime_generation = runtime_generation + 1
    log.info(string.format(
        "SPELLFORGE_RUNTIME_GENERATION_INCREMENTED reason=%s runtime_generation_before=%s runtime_generation_after=%s",
        tostring(reason),
        tostring(before),
        tostring(runtime_generation)
    ))
    return runtime_generation, before
end

function runtime_session.ensureAtLeast(value, reason)
    local generation = normalizeGeneration(value)
    if generation == nil or generation <= runtime_generation then
        return runtime_generation
    end
    local before = runtime_generation
    runtime_generation = generation
    log.info(string.format(
        "SPELLFORGE_RUNTIME_GENERATION_SEEDED reason=%s runtime_generation_before=%s runtime_generation_after=%s",
        tostring(reason),
        tostring(before),
        tostring(runtime_generation)
    ))
    return runtime_generation
end

function runtime_session.matches(value, opts)
    local generation = generationFrom(value)
    if generation == nil then
        return not (opts and opts.strict == true)
    end
    return generation == runtime_generation
end

function runtime_session.shouldDrop(value, context, opts)
    if runtime_session.matches(value, opts) then
        return false
    end
    local generation = generationFrom(value)
    log.info(string.format(
        "SPELLFORGE_STALE_RUNTIME_CALLBACK_DROPPED context=%s id=%s payload_generation=%s runtime_generation=%s",
        tostring(context),
        tostring(opts and opts.id or nil),
        tostring(generation),
        tostring(runtime_generation)
    ))
    return true
end

function runtime_session.trackProjectile(projectile_id, generation)
    if projectile_id == nil then
        return
    end
    projectile_generations[tostring(projectile_id)] = normalizeGeneration(generation) or runtime_generation
end

function runtime_session.projectileGeneration(projectile_id)
    if projectile_id == nil then
        return nil
    end
    return projectile_generations[tostring(projectile_id)]
end

function runtime_session.projectileIsStale(projectile_id)
    local generation = runtime_session.projectileGeneration(projectile_id)
    return generation ~= nil and generation ~= runtime_generation
end

return runtime_session
