local patterns = require("scripts.spellforge.global.patterns")

local payload_pattern = {}

local function reject(reason)
    return nil, reason
end

local function modeForKind(pattern_kind)
    if pattern_kind == "Spread" then
        return "spread"
    elseif pattern_kind == "Burst" then
        return "burst"
    end
    return nil
end

local function cloneOps(ops)
    local out = {}
    for index, op in ipairs(ops or {}) do
        if type(op) == "table" then
            out[index] = {
                opcode = op.opcode,
                effect_id = op.effect_id,
                params = op.params,
                index = op.index,
                payload_scope = op.payload_scope,
            }
        end
    end
    return #out > 0 and out or nil
end

function payload_pattern.modeForKind(pattern_kind)
    return modeForKind(pattern_kind)
end

function payload_pattern.compute(payloads, base_direction, pattern_kind, pattern_op)
    local mode = modeForKind(pattern_kind)
    if mode == nil then
        return reject("payload_pattern_unknown_kind")
    end

    local count = #(payloads or {})
    if count <= 1 then
        return reject("payload_pattern_fanout_missing")
    end

    local params = pattern_op and pattern_op.params or nil
    local computed = nil
    if mode == "spread" then
        computed = patterns.computeSpreadDirections(base_direction, count, params)
    elseif mode == "burst" then
        computed = patterns.computeBurstDirections(base_direction, count, params)
    end
    if not computed or computed.ok ~= true then
        return reject(computed and computed.error or "payload_pattern_direction_failed")
    end

    local enriched = {}
    local direction_by_slot_id = {}
    local key_by_slot_id = {}
    for index, payload in ipairs(payloads or {}) do
        local direction = computed.directions and computed.directions[index] or nil
        local direction_key = computed.direction_keys and computed.direction_keys[index] or nil
        if direction == nil or direction_key == nil then
            return reject("payload_pattern_direction_missing")
        end
        local slot_id = payload and payload.slot_id
        if type(slot_id) ~= "string" or slot_id == "" then
            return reject("payload_pattern_slot_missing")
        end
        enriched[index] = {
            slot_id = slot_id,
            helper_engine_id = payload.helper_engine_id,
            effect_id = payload.effect_id,
            emission_index = payload.emission_index,
            group_index = payload.group_index,
            parent_slot_id = payload.parent_slot_id,
            trigger_source_slot_id = payload.trigger_source_slot_id,
            timer_source_slot_id = payload.timer_source_slot_id,
            source_postfix_opcode = payload.source_postfix_opcode,
            root_source_slot_id = payload.root_source_slot_id,
            current_source_slot_id = payload.current_source_slot_id,
            payload_depth = payload.payload_depth,
            nested_stage_kind = payload.nested_stage_kind,
            has_trigger_payload = payload.has_trigger_payload,
            has_timer_payload = payload.has_timer_payload,
            nested_source_postfix_opcode = payload.nested_source_postfix_opcode,
            prefix_ops = cloneOps(payload.prefix_ops),
            postfix_ops = cloneOps(payload.postfix_ops),
            payload_bindings = payload.payload_bindings,
            payload_modifier_kind = payload.payload_modifier_kind,
            payload_detonate = payload.payload_detonate,
            detonate_at_launch = payload.detonate_at_launch,
            direction = direction,
            pattern_kind = pattern_kind,
            pattern_index = payload.emission_index or index,
            pattern_count = count,
            pattern_direction_key = direction_key,
        }
        direction_by_slot_id[slot_id] = direction
        key_by_slot_id[slot_id] = direction_key
    end

    return {
        ok = true,
        pattern_kind = pattern_kind,
        pattern_count = count,
        payloads = enriched,
        direction_by_slot_id = direction_by_slot_id,
        key_by_slot_id = key_by_slot_id,
        direction_keys = computed.direction_keys,
        spread_preset = computed.preset,
        spread_side_angle_degrees = computed.side_angle_degrees,
        spread_rotation_axis = computed.rotation_axis,
        burst_param_count = computed.burst_param_count,
        burst_ring_angle_degrees = computed.ring_angle_degrees,
        burst_distribution = computed.distribution,
    }, nil
end

return payload_pattern
