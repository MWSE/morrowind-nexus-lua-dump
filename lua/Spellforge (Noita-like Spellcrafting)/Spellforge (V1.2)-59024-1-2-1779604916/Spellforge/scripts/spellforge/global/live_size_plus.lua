local limits = require("scripts.spellforge.shared.limits")

local live_size_plus = {}

local MIN_MULTIPLIER = 0.1
local MAX_MULTIPLIER = 4.0
local MIN_AREA = 1
local MAX_AREA = 50
local MUTATION_FIELD = "effect.area"

local function isFinite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function sizeOps(ops)
    local out = {}
    for _, op in ipairs(ops or {}) do
        if op.opcode == "Size+" then
            out[#out + 1] = op
        end
    end
    return out
end

local function firstEffectArea(spec)
    local first = spec and spec.effects and spec.effects[1] or nil
    return tonumber(first and first.area)
end

local function round(value)
    return math.floor(value + 0.5)
end

local function computeSizeMutation(op)
    local percent = tonumber(op and op.params and op.params.percent)
    if not isFinite(percent) then
        return nil, "size_plus_value_invalid"
    end

    local multiplier = 1 + (percent / 100)
    if not isFinite(multiplier) or multiplier <= 0 then
        return nil, "size_plus_value_invalid"
    end

    local capped = false
    if multiplier < MIN_MULTIPLIER then
        multiplier = MIN_MULTIPLIER
        capped = true
    elseif multiplier > MAX_MULTIPLIER then
        multiplier = MAX_MULTIPLIER
        capped = true
    end

    return {
        size_plus = true,
        size_plus_mode = "multiplier",
        size_plus_percent = percent,
        size_plus_value = multiplier,
        size_plus_multiplier = multiplier,
        size_plus_field = MUTATION_FIELD,
        size_plus_capped = capped,
    }, nil
end

function live_size_plus.selectV0Plan(plan)
    if type(plan) ~= "table" then
        return nil, "missing_plan", nil
    end

    local bounds = plan.bounds or {}
    if bounds.has_trigger or bounds.has_timer then
        return nil, "size_plus_payload_unsupported", "live_size_plus_payload_rejections"
    end
    if bounds.has_chain or bounds.has_speed_plus then
        return nil, "size_plus_unsupported_combo", "live_size_plus_unsupported_combo_rejections"
    end
    if bounds.group_count ~= 1 then
        return nil, "not_single_group", "live_size_plus_unsupported_combo_rejections"
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
        return nil, "size_plus_payload_unsupported", "live_size_plus_payload_rejections"
    end
    if group.payload ~= nil then
        return nil, "size_plus_payload_unsupported", "live_size_plus_payload_rejections"
    end

    local ops = sizeOps(group.prefix_ops)
    if #ops == 0 then
        return nil, "size_plus_missing", nil
    end
    if #ops > 1 then
        return nil, "size_plus_ambiguous", "live_size_plus_unsupported_combo_rejections"
    end

    local saw_multicast = false
    local pattern_kind = nil
    local pattern_op = nil
    for _, op in ipairs(group.prefix_ops or {}) do
        if op.opcode == "Size+" then
            -- handled above
        elseif op.opcode == "Multicast" then
            saw_multicast = true
        elseif op.opcode == "Spread" or op.opcode == "Burst" then
            if pattern_kind ~= nil then
                return nil, "size_plus_ambiguous_pattern", "live_size_plus_unsupported_combo_rejections"
            end
            pattern_kind = op.opcode
            pattern_op = op
        else
            return nil, "size_plus_unsupported_combo", "live_size_plus_unsupported_combo_rejections"
        end
    end
    if pattern_kind ~= nil and not saw_multicast then
        return nil, "size_plus_pattern_without_multicast", "live_size_plus_unsupported_combo_rejections"
    end

    local mutation, err = computeSizeMutation(ops[1])
    if not mutation then
        return nil, err, "live_size_plus_value_invalid"
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
        pattern_kind = pattern_kind,
        pattern_op = pattern_op,
        primary_mode = primary_mode,
    }, nil, nil
end

local function applyToHelperSpecsWhere(plan, mutation, predicate)
    if type(plan) ~= "table" or type(plan.helper_specs) ~= "table" then
        return nil, "helper_specs_missing"
    end
    if type(mutation) ~= "table" or not isFinite(mutation.size_plus_multiplier) then
        return nil, "size_plus_value_invalid"
    end

    local specs_mutated = 0
    local effects_mutated = 0
    local first_base_area = nil
    local first_mutated_area = nil
    local area_capped = mutation.size_plus_capped == true

    for _, spec in ipairs(plan.helper_specs) do
        local routing = spec.routing or {}
        if predicate(spec, routing) then
            local spec_mutated = false
            for _, effect in ipairs(spec.effects or {}) do
                local base_area = tonumber(effect._spellforge_size_plus_base_area or effect.area)
                if base_area ~= nil then
                    effect._spellforge_size_plus_base_area = base_area
                end
                if isFinite(base_area) and base_area > 0 then
                    local mutated_area = round(base_area * mutation.size_plus_multiplier)
                    if mutated_area < MIN_AREA then
                        mutated_area = MIN_AREA
                        area_capped = true
                    elseif mutated_area > MAX_AREA then
                        mutated_area = MAX_AREA
                        area_capped = true
                    end
                    effect.area = mutated_area
                    effects_mutated = effects_mutated + 1
                    spec_mutated = true
                    first_base_area = first_base_area or base_area
                    first_mutated_area = first_mutated_area or mutated_area
                end
            end
            if spec_mutated then
                specs_mutated = specs_mutated + 1
            end
        end
    end

    if specs_mutated == 0 then
        return nil, "size_plus_field_missing"
    end

    mutation.size_plus_capped = area_capped
    mutation.size_plus_base_area = first_base_area
    mutation.size_plus_area = first_mutated_area

    return {
        ok = true,
        specs_mutated = specs_mutated,
        effects_mutated = effects_mutated,
        size_plus_field = MUTATION_FIELD,
        size_plus_base_area = first_base_area,
        size_plus_area = first_mutated_area,
        size_plus_capped = area_capped,
    }, nil
end

function live_size_plus.computeMutation(op)
    return computeSizeMutation(op)
end

function live_size_plus.applyToHelperSpecs(plan, mutation)
    return applyToHelperSpecsWhere(plan, mutation, function(_, routing)
        return routing.kind == "primary_emission"
            and routing.parent_slot_id == nil
            and routing.source_postfix_opcode == nil
    end)
end

function live_size_plus.applyToPayloadSlotHelperSpecs(plan, slot_id, mutation)
    if type(slot_id) ~= "string" or slot_id == "" then
        return nil, "payload_slot_id_missing"
    end
    return applyToHelperSpecsWhere(plan, mutation, function(spec)
        return spec and spec.slot_id == slot_id
    end)
end

function live_size_plus.firstHelperArea(helper)
    return firstEffectArea(helper)
end

return live_size_plus
