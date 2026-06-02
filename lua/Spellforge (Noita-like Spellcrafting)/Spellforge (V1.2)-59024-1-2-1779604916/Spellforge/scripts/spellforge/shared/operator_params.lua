local opcodes = require("scripts.spellforge.shared.opcodes")

local operator_params = {}

local OPERATOR_ID_TO_OPCODE = {
    spellforge_multicast = "Multicast",
    spellforge_spread = "Spread",
    spellforge_burst = "Burst",
    spellforge_speed_plus = "Speed+",
    spellforge_size_plus = "Size+",
    spellforge_chain = "Chain",
    spellforge_bounce = "Bounce",
    spellforge_pierce = "Pierce",
    spellforge_homing = "Homing",
    spellforge_detonate = "Detonate",
    spellforge_trigger = "Trigger",
    spellforge_timer = "Timer",
}

local function normalizeId(value)
    if value == nil then
        return nil
    end
    return string.lower(tostring(value))
end

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 4 then
        return tostring(value)
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function cloneParams(params)
    local out = {}
    if type(params) ~= "table" then
        return out
    end
    for key, value in pairs(params) do
        out[key] = value
    end
    return out
end

local function coerceParamValue(spec, value)
    if value == nil or type(spec) ~= "table" then
        return value
    end
    if (spec.type == "number" or spec.type == "integer") and type(value) == "string" then
        local numeric = tonumber(value)
        if numeric ~= nil then
            return numeric
        end
    end
    return value
end

function operator_params.encodedFieldName(param_name)
    return "spellforge_param_" .. tostring(param_name)
end

function operator_params.encodedFieldNames()
    local seen = {}
    local out = {}
    for _, def in pairs(opcodes) do
        for name in pairs(def.parameters or {}) do
            local field = operator_params.encodedFieldName(name)
            if not seen[field] then
                seen[field] = true
                out[#out + 1] = field
            end
        end
    end
    table.sort(out)
    return out
end

function operator_params.opcodeForEffect(effect)
    if type(effect) ~= "table" then
        return nil
    end
    local normalized = normalizeId(effect and effect.id)
    return normalized and OPERATOR_ID_TO_OPCODE[normalized] or nil
end

function operator_params.copyEncodedFields(source, target)
    if type(source) ~= "table" or type(target) ~= "table" then
        return
    end
    for _, def in pairs(opcodes) do
        for name in pairs(def.parameters or {}) do
            local field = operator_params.encodedFieldName(name)
            if source[field] ~= nil then
                target[field] = source[field]
            end
        end
    end
end

function operator_params.paramsForEffect(effect, opcode)
    if type(effect) ~= "table" then
        return {}
    end
    local resolved_opcode = opcode or operator_params.opcodeForEffect(effect)
    local params = cloneParams(effect and effect.params)
    local def = resolved_opcode and opcodes[resolved_opcode] or nil
    if not def then
        return params
    end

    for name, spec in pairs(def.parameters or {}) do
        if params[name] == nil then
            local encoded = effect and effect[operator_params.encodedFieldName(name)] or nil
            if encoded ~= nil then
                params[name] = encoded
            end
        end
        params[name] = coerceParamValue(spec, params[name])
    end
    return params
end

function operator_params.mirrorEffect(effect)
    if type(effect) ~= "table" then
        return effect
    end
    local out = cloneValue(effect or {}, 0)
    local opcode = operator_params.opcodeForEffect(out)
    if not opcode then
        return out
    end

    local params = operator_params.paramsForEffect(out, opcode)
    out.params = params
    local def = opcodes[opcode] or {}
    for name in pairs(def.parameters or {}) do
        if params[name] ~= nil then
            out[operator_params.encodedFieldName(name)] = params[name]
        end
    end
    return out
end

function operator_params.mirrorEffects(effects)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        out[i] = operator_params.mirrorEffect(effect)
    end
    return out
end

return operator_params
