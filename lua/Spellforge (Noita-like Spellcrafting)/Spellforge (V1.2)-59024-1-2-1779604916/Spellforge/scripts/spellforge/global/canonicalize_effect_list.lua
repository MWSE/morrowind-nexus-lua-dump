local util = require("openmw.util")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local canonicalize_effect_list = {}

local FNV_OFFSET_32 = 2166136261
local FNV_PRIME_32 = 16777619
local DEFAULT_COMPILER_VERSION = "2.2c.2"
local PRESENTATION_METADATA_FIELDS = {
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
}

local function sortedKeys(tbl)
    local keys = {}
    if type(tbl) ~= "table" then
        return keys
    end
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function normalizeId(id)
    if id == nil then
        return "<nil>"
    end
    return effect_registry.normalizeEffectId(id, { keep_operators = true }) or "<nil>"
end

local function serializeNumber(n)
    if n ~= n then
        return "nan"
    end
    if n == math.huge then
        return "inf"
    end
    if n == -math.huge then
        return "-inf"
    end
    return string.format("%.17g", n)
end

local function serializeScalar(v)
    local t = type(v)
    if t == "nil" then
        return "~"
    elseif t == "number" then
        return serializeNumber(v)
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "string" then
        return v
    end
    return tostring(v)
end

local function serializeParams(params)
    local parts = {}
    for _, key in ipairs(sortedKeys(params)) do
        parts[#parts + 1] = string.format("%s=%s", tostring(key), serializeScalar(params[key]))
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function canonicalEngineEffectId(effect, normalized_id)
    if effect_registry.isOperatorEffectId(effect and effect.id) then
        return nil
    end
    local engine_effect_id = effect and effect.engine_effect_id
    if type(engine_effect_id) ~= "string" or engine_effect_id == "" then
        return nil
    end
    local preserved = string.gsub(string.lower(engine_effect_id), "%s+", "")
    if preserved == normalized_id then
        return nil
    end
    return engine_effect_id
end

local function serializeEffect(effect)
    local e = effect or {}
    local normalized_id = normalizeId(e.id)
    local pieces = {
        "id=" .. normalized_id,
        "range=" .. serializeScalar(e.range),
        "magmin=" .. serializeScalar(e.magnitudeMin),
        "magmax=" .. serializeScalar(e.magnitudeMax),
        "attr=" .. serializeScalar(e.affectedAttribute),
        "skill=" .. serializeScalar(e.affectedSkill),
        "area=" .. serializeScalar(e.area),
        "duration=" .. serializeScalar(e.duration),
        "params=" .. serializeParams(e.params),
    }
    local engine_effect_id = canonicalEngineEffectId(e, normalized_id)
    if engine_effect_id then
        pieces[#pieces + 1] = "engine_effect_id=" .. serializeScalar(engine_effect_id)
    end
    for _, field in ipairs(PRESENTATION_METADATA_FIELDS) do
        pieces[#pieces + 1] = tostring(field) .. "=" .. serializeScalar(e[field])
    end
    return "(" .. table.concat(pieces, "|") .. ")"
end

local function serializeEffects(effects)
    local parts = {}
    for i, effect in ipairs(effects or {}) do
        parts[i] = serializeEffect(effect)
    end
    return "[" .. table.concat(parts, ";") .. "]"
end

local function serializeOp(op)
    local o = op or {}
    local pieces = {
        "opcode=" .. serializeScalar(o.opcode),
        "effect_id=" .. normalizeId(o.effect_id),
        "params=" .. serializeParams(o.params),
    }
    return "(" .. table.concat(pieces, "|") .. ")"
end

local function serializeOps(ops)
    local parts = {}
    for i, op in ipairs(ops or {}) do
        parts[i] = serializeOp(op)
    end
    return "[" .. table.concat(parts, ";") .. "]"
end

local function serializeGroups(groups)
    local parts = {}
    for i, group in ipairs(groups or {}) do
        local piece = table.concat({
            "kind=" .. serializeScalar(group.kind),
            "range=" .. serializeScalar(group.range),
            "effects=" .. serializeEffects(group.effects),
            "prefix=" .. serializeOps(group.prefix_ops),
            "postfix=" .. serializeOps(group.postfix_ops),
        }, "|")
        parts[i] = "{" .. piece .. "}"
    end
    return "[" .. table.concat(parts, "=>") .. "]"
end

local function fnv1a32(input)
    local hash = FNV_OFFSET_32
    for i = 1, #input do
        hash = util.bitXor(hash, string.byte(input, i))
        hash = util.bitAnd(hash * FNV_PRIME_32, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

function canonicalize_effect_list.run(payload, opts)
    local options = opts or {}
    local compiler_version = options.compiler_version or DEFAULT_COMPILER_VERSION
    local identity_salt = options.recipe_identity_salt

    local body
    if type(payload) == "table" and type(payload.groups) == "table" then
        body = "groups=" .. serializeGroups(payload.groups)
    else
        body = "effects=" .. serializeEffects(payload)
    end

    local canonical = string.format("compiler=%s|%s", tostring(compiler_version), body)
    if type(identity_salt) == "string" and identity_salt ~= "" then
        canonical = string.format("%s|identity=%s", canonical, identity_salt)
    end

    return {
        canonical = canonical,
        recipe_id = fnv1a32(canonical),
        compiler_version = compiler_version,
    }
end

return canonicalize_effect_list
