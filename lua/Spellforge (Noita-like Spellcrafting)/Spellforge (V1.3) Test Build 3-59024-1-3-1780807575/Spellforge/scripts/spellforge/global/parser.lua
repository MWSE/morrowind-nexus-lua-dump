---@omw-context global
local limits = require("scripts.spellforge.shared.limits")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local opcodes = require("scripts.spellforge.shared.opcodes")
local operator_params = require("scripts.spellforge.shared.operator_params")
local validation = require("scripts.spellforge.shared.validation_contract")

local parser = {}

local DEFAULT_OPERATOR_ID_TO_OPCODE = {
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

local PREFIX_OPS = {
    Multicast = true,
    Spread = true,
    Burst = true,
    ["Speed+"] = true,
    ["Size+"] = true,
    Chain = true,
    Bounce = true,
    Pierce = true,
    Homing = true,
    Detonate = true,
}

local POSTFIX_OPS = {
    Trigger = true,
    Timer = true,
}

local RANGE_SELF = 0
local RANGE_TARGET = 2
local RANGE_TOUCH = 1

local function appendError(errors, index, message, code, details)
    errors[#errors + 1] = validation.error(
        string.format("effects[%d]", index),
        message,
        code,
        details
    )
end

local function cloneEffect(effect)
    if type(effect) ~= "table" then
        return effect
    end
    local out = operator_params.mirrorEffect(effect)
    for k, v in pairs(effect) do
        if out[k] == nil then
            out[k] = v
        end
    end
    return out
end

local function cloneEffectSlice(effects, start_index)
    local out = {}
    for i = start_index, #effects do
        out[#out + 1] = cloneEffect(effects[i])
    end
    return out
end

local function normalizeId(value)
    return effect_registry.normalizeEffectId(value, { keep_operators = true })
end

local function isSpellforgeLookingId(effect_id_norm)
    return type(effect_id_norm) == "string" and string.sub(effect_id_norm, 1, 11) == "spellforge_"
end

local function validateParam(errors, index, opcode_name, key, spec, value)
    if spec.type == "integer" then
        if type(value) ~= "number" or value % 1 ~= 0 then
            appendError(errors, index, string.format("%s.%s must be an integer", opcode_name, key), "invalid_opcode_parameter", {
                opcode = opcode_name,
                parameter = key,
                expected = "integer",
            })
            return
        end
    elseif spec.type == "number" then
        if type(value) ~= "number" then
            appendError(errors, index, string.format("%s.%s must be a number", opcode_name, key), "invalid_opcode_parameter", {
                opcode = opcode_name,
                parameter = key,
                expected = "number",
            })
            return
        end
    end

    if spec.min ~= nil and value < spec.min then
        appendError(errors, index, string.format("%s.%s must be >= %s", opcode_name, key, tostring(spec.min)), "invalid_opcode_parameter", {
            opcode = opcode_name,
            parameter = key,
            min = spec.min,
            value = value,
        })
    end
    if spec.max ~= nil and value > spec.max then
        appendError(errors, index, string.format("%s.%s must be <= %s", opcode_name, key, tostring(spec.max)), "invalid_opcode_parameter", {
            opcode = opcode_name,
            parameter = key,
            max = spec.max,
            value = value,
        })
    end
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

local function validateOpcodeParams(errors, index, opcode_name, effect)
    local def = opcodes[opcode_name]
    if not def then
        appendError(errors, index, string.format("Unknown opcode: %s", tostring(opcode_name)), "unknown_opcode", {
            opcode = opcode_name,
        })
        return nil
    end
    local params = operator_params.paramsForEffect(effect, opcode_name)
    for key, spec in pairs(def.parameters or {}) do
        local value = params[key]
        if value == nil and spec.default ~= nil then
            value = spec.default
            params[key] = value
        end
        if value == nil then
            appendError(errors, index, string.format("Missing parameter %s for %s", key, opcode_name), "missing_opcode_parameter", {
                opcode = opcode_name,
                parameter = key,
            })
        else
            validateParam(errors, index, opcode_name, key, spec, value)
        end
    end
    return params
end

local function computeEmissionCount(prefix_ops)
    local count = 1
    for _, op in ipairs(prefix_ops or {}) do
        if op.opcode == "Multicast" then
            count = count * (op.params and op.params.count or 1)
        end
    end
    return count
end

local function isTargetRange(range)
    if tonumber(range) == RANGE_TARGET then
        return true
    end
    return string.lower(tostring(range or "")) == "target"
end

local function isTouchRange(range)
    if tonumber(range) == RANGE_TOUCH then
        return true
    end
    return string.lower(tostring(range or "")) == "touch"
end

local function isSelfRange(range)
    if tonumber(range) == RANGE_SELF then
        return true
    end
    return string.lower(tostring(range or "")) == "self"
end

local function hasPrefixOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true
        end
    end
    return false
end

local function prefixCount(ops)
    local count = 0
    for _, op in ipairs(ops or {}) do
        if op and op.opcode ~= nil then
            count = count + 1
        end
    end
    return count
end

local function auditContinuationDepth(effects, errors, max_depth, operator_id_to_opcode)
    local depth = 0
    local opcode_map = operator_id_to_opcode or DEFAULT_OPERATOR_ID_TO_OPCODE
    local limit = tonumber(max_depth) or limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3
    for index, effect in ipairs(effects or {}) do
        local effect_id_norm = normalizeId(effect and effect.id)
        local opcode_name = effect_id_norm and opcode_map[effect_id_norm] or nil
        if POSTFIX_OPS[opcode_name] then
            depth = depth + 1
            if depth > limit then
                appendError(errors, index, string.format("Nested continuation depth exceeds supported live depth (%d)", limit), "nested_depth_exceeded", {
                    opcode = opcode_name,
                    depth = depth,
                    limit = limit,
                })
                return false
            end
        end
    end
    return true
end

function parser.parseEffectList(effects, opts)
    local options = opts or {}
    local operator_id_to_opcode = options.operator_id_to_opcode or DEFAULT_OPERATOR_ID_TO_OPCODE
    local max_projectiles = (options.limits and options.limits.MAX_PROJECTILES_PER_CAST) or limits.MAX_PROJECTILES_PER_CAST

    if type(effects) ~= "table" then
        return {
            ok = false,
            errors = { validation.error("effects", "effects must be an array", "effects_not_array") },
            warnings = {},
        }
    end

    local groups = {}
    local warnings = {}
    local errors = {}
    local pending_prefix_ops = {}
    local total_static_emissions = 0

    auditContinuationDepth(effects, errors, options.max_live_nested_continuation_depth or options.max_nested_payload_depth, operator_id_to_opcode)
    if #errors > 0 then
        return {
            ok = false,
            errors = errors,
            warnings = warnings,
            groups = groups,
        }
    end

    local function flushEmitter(effect, index)
        local last_group = groups[#groups]
        local compatible_with_last = last_group
            and last_group.kind == "emitter_group"
            and #last_group.effects > 0
            and #pending_prefix_ops == 0
            and last_group.range == effect.range
            and last_group.accepts_implicit_following_effects == true

        if compatible_with_last then
            last_group.effects[#last_group.effects + 1] = cloneEffect(effect)
            return last_group
        end

        local prefix_for_group = pending_prefix_ops
        pending_prefix_ops = {}

        local has_multicast = false
        local has_pattern = false
        local fanout_opcode = nil
        for _, op in ipairs(prefix_for_group) do
            if op.opcode == "Multicast" then
                has_multicast = true
                fanout_opcode = fanout_opcode or op.opcode
            end
            if op.opcode == "Burst" or op.opcode == "Spread" then
                has_pattern = true
                fanout_opcode = fanout_opcode or op.opcode
            end
        end
        if has_pattern and not has_multicast then
            appendError(errors, index, "Burst/Spread requires Multicast in the same prefix chain", "pattern_requires_multicast")
        end
        local allow_non_target_payload_multicast = options.allow_non_target_payload_multicast == true
            and has_multicast
            and not has_pattern
            and isTouchRange(effect.range)
        local allow_self_summon_multicast = has_multicast
            and not has_pattern
            and isSelfRange(effect.range)
            and effect_registry.isSummonEffect(effect)
        local has_detonate = hasPrefixOpcode(prefix_for_group, "Detonate")
        if has_detonate then
            local unsupported_detonate_prefix = nil
            local detonate_count = 0
            local multicast_count = 0
            for _, op in ipairs(prefix_for_group) do
                if op and op.opcode == "Detonate" then
                    detonate_count = detonate_count + 1
                elseif op and op.opcode == "Multicast" then
                    multicast_count = multicast_count + 1
                elseif op and op.opcode ~= nil then
                    unsupported_detonate_prefix = unsupported_detonate_prefix or op.opcode
                end
            end
            if options.fanout_context ~= "continuation_payload" then
                appendError(errors, index, "Detonate can only modify Trigger/Timer payload emitters", "detonate_requires_payload_context", {
                    range = effect.range,
                    area = effect.area,
                })
            end
            if detonate_count ~= 1 or multicast_count > 1 or unsupported_detonate_prefix ~= nil then
                appendError(errors, index, "Detonate cannot be combined with other payload modifiers yet", "detonate_modifier_combo_deferred", {
                    prefix_count = prefixCount(prefix_for_group),
                    allowed_with_detonate = "Multicast",
                    unsupported_prefix = unsupported_detonate_prefix,
                })
            end
            if not isTargetRange(effect.range) then
                appendError(errors, index, "Detonate payload requires Target range", "detonate_requires_target_range", {
                    range = effect.range,
                })
            end
            if (tonumber(effect.area) or 0) <= 0 then
                appendError(errors, index, "Detonate payload requires area greater than zero", "detonate_requires_area", {
                    area = effect.area,
                })
            end
        end
        if fanout_opcode ~= nil
            and not isTargetRange(effect.range)
            and not allow_non_target_payload_multicast
            and not allow_self_summon_multicast then
            appendError(errors, index, "Multicast/Spread/Burst fanout requires Target range", "fanout_requires_target_range", {
                opcode = fanout_opcode,
                range = effect.range,
                context = options.fanout_context,
            })
        end

        local emission_count_static = computeEmissionCount(prefix_for_group)
        if emission_count_static > max_projectiles then
            appendError(errors, index, string.format("Emitter group static emissions exceed MAX_PROJECTILES_PER_CAST (%d)", max_projectiles), "static_emission_cap_exceeded", {
                limit = max_projectiles,
                count = emission_count_static,
            })
        end
        total_static_emissions = total_static_emissions + emission_count_static
        if total_static_emissions > max_projectiles then
            appendError(errors, index, string.format("Recipe static emission estimate exceeds MAX_PROJECTILES_PER_CAST (%d)", max_projectiles), "recipe_static_emission_cap_exceeded", {
                limit = max_projectiles,
                count = total_static_emissions,
            })
        end

        local group = {
            kind = "emitter_group",
            range = effect.range,
            effects = { cloneEffect(effect) },
            prefix_ops = prefix_for_group,
            postfix_ops = {},
            payload = nil,
            emission_count_static = emission_count_static,
            accepts_implicit_following_effects = #prefix_for_group == 0,
        }
        groups[#groups + 1] = group
        return group
    end

    local stop_after_payload = false
    for index, effect in ipairs(effects) do
        if type(effect) ~= "table" then
            appendError(errors, index, "Effect must be a table", "effect_not_table")
        else
            local effect_id_norm = normalizeId(effect.id)
            local opcode_name = effect_id_norm and operator_id_to_opcode[effect_id_norm] or nil

            if opcode_name then
                local opcode_params = validateOpcodeParams(errors, index, opcode_name, effect)
                if PREFIX_OPS[opcode_name] then
                    pending_prefix_ops[#pending_prefix_ops + 1] = {
                        opcode = opcode_name,
                        effect_id = effect.id,
                        params = opcode_params or cloneParams(effect.params),
                        index = index,
                    }
                elseif POSTFIX_OPS[opcode_name] then
                    local last_group = groups[#groups]
                    if not last_group then
                        appendError(errors, index, string.format("%s has no preceding emitter group", opcode_name), "postfix_missing_source", {
                            opcode = opcode_name,
                        })
                    elseif hasPrefixOpcode(last_group.prefix_ops, "Detonate") then
                        appendError(errors, index, "Detonate payloads cannot open nested Trigger/Timer payloads yet", "detonate_nested_continuation_unsupported", {
                            opcode = opcode_name,
                        })
                    else
                        local op = {
                            opcode = opcode_name,
                            effect_id = effect.id,
                            params = opcode_params or cloneParams(effect.params),
                            index = index,
                            payload_scope = "remaining_effect_list_segment",
                        }
                        last_group.postfix_ops[#last_group.postfix_ops + 1] = op
                        last_group.payload = {
                            scope = "remaining_effect_list_segment",
                            effects = cloneEffectSlice(effects, index + 1),
                            note = "Trigger/Timer payload executes once per emission (runtime, not implemented in parser skeleton)",
                        }
                        stop_after_payload = true
                    end
                end
            else
                if isSpellforgeLookingId(effect_id_norm) then
                    appendError(errors, index, string.format("Unknown Spellforge operator effect ID: %s", tostring(effect.id)), "unknown_spellforge_operator", {
                        effect_id = effect.id,
                    })
                end
                flushEmitter(effect, index)
            end
        end
        if stop_after_payload then
            break
        end
    end

    if #pending_prefix_ops > 0 then
        local first = pending_prefix_ops[1]
        appendError(errors, first.index or #effects, string.format("%s must be followed by an emitter group", tostring(first.opcode)), "prefix_missing_emitter", {
            opcode = first.opcode,
        })
    end

    if #groups == 0 then
        appendError(errors, 1, "Recipe has no emitter groups", "recipe_has_no_emitter_groups")
    end

    if #errors > 0 then
        return {
            ok = false,
            errors = errors,
            warnings = warnings,
            groups = groups,
        }
    end

    return {
        ok = true,
        groups = groups,
        warnings = warnings,
    }
end

local function mergedContinuationPayloadOptions(opts)
    local out = {}
    for key, value in pairs(opts or {}) do
        out[key] = value
    end
    out.allow_non_target_payload_multicast = true
    out.fanout_context = "continuation_payload"
    return out
end

function parser.parseContinuationPayloadEffectList(effects, opts)
    local parsed = parser.parseEffectList(effects, mergedContinuationPayloadOptions(opts))
    parsed.allow_non_target_payload_multicast = true
    parsed.fanout_context = "continuation_payload"
    return parsed
end

return parser
