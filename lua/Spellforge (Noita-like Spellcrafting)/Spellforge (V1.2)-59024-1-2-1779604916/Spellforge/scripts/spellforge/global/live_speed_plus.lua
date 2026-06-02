local limits = require("scripts.spellforge.shared.limits")
local projectile_speed_policy = require("scripts.spellforge.global.projectile_speed_policy")

local live_speed_plus = {}

local MIN_MULTIPLIER = 0.1
local MAX_MULTIPLIER = 5.0
local SUPPORTED_LAUNCH_SPEED_FIELD = "speed"
local SUPPORTED_LAUNCH_MAX_SPEED_FIELD = "maxSpeed"

local function speedOps(ops)
    local out = {}
    for _, op in ipairs(ops or {}) do
        if op.opcode == "Speed+" then
            out[#out + 1] = op
        end
    end
    return out
end

local function isFinite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function contextValue(context, key)
    if type(context) ~= "table" then
        return nil
    end
    return context[key]
end

local function resolveBaseline(context)
    local source = contextValue(context, "slot")
        or contextValue(context, "entry")
        or contextValue(context, "mapping")
        or contextValue(context, "group")
        or context
    local baseline, details = projectile_speed_policy.resolveForSlot(source, {
        log = false,
        apply_race_weight = false,
        recipe_id = contextValue(context, "recipe_id"),
        slot_id = contextValue(context, "slot_id"),
        helper_engine_id = contextValue(context, "helper_engine_id"),
        helper_logical_id = contextValue(context, "helper_logical_id"),
    })
    baseline = tonumber(baseline)
    if not isFinite(baseline) or baseline <= 0 then
        baseline = projectile_speed_policy.targetSpellSpeed()
        details = details or {}
        details.baseline_speed = baseline
        details.source = "fallback"
    end
    return baseline, details or {}
end

local function computeSpeedMutation(op, context)
    local percent = tonumber(op and op.params and op.params.percent)
    if not isFinite(percent) then
        return nil, "speed_plus_value_invalid"
    end

    local multiplier = 1 + (percent / 100)
    if not isFinite(multiplier) or multiplier <= 0 then
        return nil, "speed_plus_value_invalid"
    end

    local capped = false
    if multiplier < MIN_MULTIPLIER then
        multiplier = MIN_MULTIPLIER
        capped = true
    elseif multiplier > MAX_MULTIPLIER then
        multiplier = MAX_MULTIPLIER
        capped = true
    end

    local baseline, baseline_details = resolveBaseline(context)
    local speed, speed_capped = projectile_speed_policy.applySpeedPlusMultiplier(baseline, multiplier)
    if not isFinite(speed) or speed <= 0 then
        return nil, "speed_plus_value_invalid"
    end
    capped = capped or speed_capped == true

    local mutation = {
        speed_plus = true,
        speed_plus_mode = "initial_speed",
        speed_plus_percent = percent,
        speed_plus_value = speed,
        speed_plus_base_speed = baseline,
        speed_plus_multiplier = multiplier,
        speed_plus_speed = speed,
        speed_plus_max_speed = speed,
        speed_plus_field = SUPPORTED_LAUNCH_SPEED_FIELD,
        speed_plus_capped = capped,
        speed_plus_baseline_source = baseline_details.source,
        speed_plus_effect_id = baseline_details.effect_ids and baseline_details.effect_ids[1] or nil,
        launch_speed_field = SUPPORTED_LAUNCH_SPEED_FIELD,
        launch_max_speed_field = SUPPORTED_LAUNCH_MAX_SPEED_FIELD,
    }
    return mutation, nil
end

function live_speed_plus.launchSpeedField()
    return SUPPORTED_LAUNCH_SPEED_FIELD
end

function live_speed_plus.launchMaxSpeedField()
    return SUPPORTED_LAUNCH_MAX_SPEED_FIELD
end

function live_speed_plus.computeMutation(op, context)
    return computeSpeedMutation(op, context)
end

function live_speed_plus.selectV1Plan(plan)
    if type(plan) ~= "table" then
        return nil, "missing_plan", nil
    end

    local bounds = plan.bounds or {}
    if bounds.has_trigger or bounds.has_timer then
        return nil, "speed_plus_payload_unsupported", "live_speed_plus_payload_rejections"
    end
    if bounds.has_chain or bounds.has_size_plus then
        return nil, "speed_plus_unsupported_combo", "live_speed_plus_unsupported_combo_rejections"
    end
    if bounds.group_count ~= 1 then
        return nil, "not_single_group", "live_speed_plus_unsupported_combo_rejections"
    end
    local static_emission_count = tonumber(bounds.static_emission_count) or 0
    if static_emission_count < 1 then
        return nil, "no_static_emissions", nil
    end
    if static_emission_count > limits.MAX_PROJECTILES_PER_CAST then
        return nil, "projectile_cap_exceeded", nil
    end

    local group = plan.groups and plan.groups[1] or nil
    if type(group) ~= "table" then
        return nil, "missing_group", nil
    end
    if type(group.effects) ~= "table" or #group.effects == 0 then
        return nil, "missing_emitter_effects", nil
    end
    if type(group.postfix_ops) == "table" and #group.postfix_ops > 0 then
        return nil, "speed_plus_payload_unsupported", "live_speed_plus_payload_rejections"
    end
    if group.payload ~= nil then
        return nil, "speed_plus_payload_unsupported", "live_speed_plus_payload_rejections"
    end

    local ops = speedOps(group.prefix_ops)
    if #ops == 0 then
        return nil, "speed_plus_missing", nil
    end
    if #ops > 1 then
        return nil, "speed_plus_ambiguous", "live_speed_plus_unsupported_combo_rejections"
    end

    local saw_multicast = false
    local pattern_kind = nil
    local pattern_op = nil
    for _, op in ipairs(group.prefix_ops or {}) do
        if op.opcode == "Speed+" then
            -- handled above
        elseif op.opcode == "Multicast" then
            saw_multicast = true
        elseif op.opcode == "Spread" or op.opcode == "Burst" then
            if pattern_kind ~= nil then
                return nil, "speed_plus_ambiguous_pattern", "live_speed_plus_unsupported_combo_rejections"
            end
            pattern_kind = op.opcode
            pattern_op = op
        else
            return nil, "speed_plus_unsupported_combo", "live_speed_plus_unsupported_combo_rejections"
        end
    end
    if pattern_kind ~= nil and not saw_multicast then
        return nil, "speed_plus_pattern_without_multicast", "live_speed_plus_unsupported_combo_rejections"
    end

    local mutation, err = computeSpeedMutation(ops[1], {
        recipe_id = plan.recipe_id,
        slot_id = group.slot_id,
        group = group,
        slot = group,
    })
    if not mutation then
        return nil, err, "live_speed_plus_value_invalid"
    end

    local emission_count = tonumber(bounds.static_emission_count or group.emission_count_static) or 1
    local primary_mode = "single"
    if pattern_kind == "Spread" then
        primary_mode = "spread"
    elseif pattern_kind == "Burst" then
        primary_mode = "burst"
    elseif saw_multicast and emission_count > 1 then
        primary_mode = "multicast"
    end

    return {
        mutation = mutation,
        emission_count = emission_count,
        has_multicast = saw_multicast,
        has_pattern = pattern_kind ~= nil,
        pattern_kind = pattern_kind,
        pattern_op = pattern_op,
        primary_mode = primary_mode,
    }, nil, nil
end

live_speed_plus.selectV0Plan = live_speed_plus.selectV1Plan

return live_speed_plus
