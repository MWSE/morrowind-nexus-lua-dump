local limits = require("scripts.spellforge.shared.limits")
local nested_payload_audit = require("scripts.spellforge.global.nested_payload_audit")
local chaos_budget = require("scripts.spellforge.global.chaos_budget")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local payload_multicast = {}
local RANGE_SELF = 0

local function hasOps(ops)
    return type(ops) == "table" and #ops > 0
end

local function hasPayloadBindings(value)
    return type(value) == "table" and #value > 0
end

local function firstPostfixKind(value)
    for _, op in ipairs(value and value.postfix_ops or {}) do
        if op and (op.opcode == "Trigger" or op.opcode == "Timer") then
            return op.opcode
        end
    end
    return nil
end

local function payloadDepth(slot, slots_by_id)
    if tonumber(slot and slot.payload_depth) ~= nil then
        return tonumber(slot.payload_depth)
    end
    local depth = 0
    local current = slot
    local seen = {}
    while type(current) == "table" and current.parent_slot_id ~= nil do
        if seen[current.slot_id] then
            break
        end
        seen[current.slot_id] = true
        depth = depth + 1
        current = slots_by_id and slots_by_id[current.parent_slot_id] or nil
    end
    return depth
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true
        end
    end
    return false
end

local function helperBySlotId(helpers)
    local by_slot = {}
    for _, helper in ipairs(helpers or {}) do
        if type(helper) == "table" and type(helper.slot_id) == "string" then
            by_slot[helper.slot_id] = helper
        end
    end
    return by_slot
end

local function firstEffectId(helper)
    local first = helper and helper.effects and helper.effects[1] or nil
    return first and first.id or nil
end

local function sortByEmissionThenSlot(a, b)
    local ae = tonumber(a.emission_index) or 0
    local be = tonumber(b.emission_index) or 0
    if ae ~= be then
        return ae < be
    end
    return tostring(a.slot_id) < tostring(b.slot_id)
end

local function isSelfRange(range)
    if tonumber(range) == RANGE_SELF then
        return true
    end
    return string.lower(tostring(range or "")) == "self"
end

local function effectsAreSelfSummons(effects)
    if type(effects) ~= "table" or #effects == 0 then
        return false
    end
    for _, effect in ipairs(effects) do
        if type(effect) ~= "table"
            or not isSelfRange(effect.range)
            or effect_registry.isSummonEffect(effect) ~= true then
            return false
        end
    end
    return true
end

local function isSummonSourcePayload(payload)
    local slot = payload and payload.slot or nil
    local helper = payload and payload.helper or nil
    return effectsAreSelfSummons(slot and slot.effects)
        or effectsAreSelfSummons(helper and helper.effects)
end

local function allPayloadsAreSummonSources(payloads)
    if type(payloads) ~= "table" or #payloads == 0 then
        return false
    end
    for _, payload in ipairs(payloads) do
        if not isSummonSourcePayload(payload) then
            return false
        end
    end
    return true
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

local function opKey(op)
    if type(op) ~= "table" then
        return nil
    end
    return table.concat({
        tostring(op.opcode or ""),
        tostring(op.effect_id or ""),
        tostring(op.index or ""),
        tostring(op.payload_scope or ""),
    }, "|")
end

local function mergeOps(first, second)
    local out = {}
    local seen = {}
    local function append(ops)
        for _, op in ipairs(ops or {}) do
            local key = opKey(op)
            if key ~= nil and not seen[key] then
                seen[key] = true
                out[#out + 1] = {
                    opcode = op.opcode,
                    effect_id = op.effect_id,
                    params = op.params,
                    index = op.index,
                    payload_scope = op.payload_scope,
                }
            end
        end
    end
    append(first)
    append(second)
    return #out > 0 and out or nil
end

local function compactPayload(slot, helper, slots_by_id)
    local postfix_kind = firstPostfixKind(slot) or firstPostfixKind(helper)
    local payload_detonate = hasOpcode(slot and slot.prefix_ops or nil, "Detonate")
        or hasOpcode(helper and helper.prefix_ops or nil, "Detonate")
    return {
        slot = slot,
        helper = helper,
        slot_id = slot.slot_id,
        helper_engine_id = helper.engine_id,
        effect_id = firstEffectId(helper),
        emission_index = slot.emission_index or helper.emission_index,
        group_index = slot.group_index or helper.group_index,
        parent_slot_id = slot.parent_slot_id or helper.parent_slot_id,
        trigger_source_slot_id = slot.trigger_source_slot_id or helper.trigger_source_slot_id,
        timer_source_slot_id = slot.timer_source_slot_id or helper.timer_source_slot_id,
        source_postfix_opcode = slot.source_postfix_opcode or helper.source_postfix_opcode,
        payload_depth = payloadDepth(slot, slots_by_id),
        prefix_ops = mergeOps(slot.prefix_ops, helper.prefix_ops),
        postfix_ops = mergeOps(slot.postfix_ops, helper.postfix_ops),
        payload_bindings = slot.payload_bindings or helper.payload_bindings,
        has_trigger_payload = postfix_kind == "Trigger" and hasPayloadBindings(slot.payload_bindings),
        has_timer_payload = postfix_kind == "Timer" and hasPayloadBindings(slot.payload_bindings),
        nested_source_postfix_opcode = postfix_kind,
        payload_detonate = payload_detonate == true,
    }
end

local function reject(reason, details)
    local result = details or {}
    result.ok = false
    result.rejection_reason = reason
    return result
end

local function recordBudgetCap(category)
    chaos_budget.recordReject("payload_multicast_cap_exceeded", category)
end

local function homingAllowed(options)
    options = options or {}
    if options.force_homing_disabled == true then
        return false
    end
    return options.force_homing_enabled == true
        or options.homing_enabled == true
        or options.allow_homing == true
        or options.allow_payload_homing == true
end

local function cloneOp(op)
    if type(op) ~= "table" then
        return nil
    end
    return {
        opcode = op.opcode,
        effect_id = op.effect_id,
        params = op.params,
        index = op.index,
        payload_scope = op.payload_scope,
    }
end

local function payloadPrefixPolicy(plan, slot, helper, options)
    local saw_multicast = false
    local pattern_kind = nil
    local pattern_op = nil
    local slot_speed_count = 0
    local slot_size_count = 0
    local slot_homing_count = 0
    local slot_detonate_count = 0
    local helper_speed_count = 0
    local helper_size_count = 0
    local helper_homing_count = 0
    local helper_detonate_count = 0
    for _, op in ipairs(slot.prefix_ops or {}) do
        local opcode = op and op.opcode
        if opcode == "Multicast" then
            saw_multicast = true
        elseif opcode == "Chain" then
            return nil, "payload_multicast_chain_deferred"
        elseif opcode == "Spread" or opcode == "Burst" then
            if pattern_kind ~= nil and pattern_kind ~= opcode then
                return nil, "payload_pattern_ambiguous"
            end
            pattern_kind = opcode
            pattern_op = pattern_op or op
        elseif opcode == "Speed+" then
            slot_speed_count = slot_speed_count + 1
        elseif opcode == "Size+" then
            slot_size_count = slot_size_count + 1
        elseif opcode == "Homing" then
            slot_homing_count = slot_homing_count + 1
        elseif opcode == "Detonate" then
            slot_detonate_count = slot_detonate_count + 1
        else
            return nil, "unsupported_payload_prefix_" .. tostring(opcode)
        end
    end

    for _, op in ipairs(helper.prefix_ops or {}) do
        local opcode = op and op.opcode
        if opcode == "Multicast" then
            saw_multicast = true
        elseif opcode == "Chain" then
            return nil, "payload_multicast_chain_deferred"
        elseif opcode == "Spread" or opcode == "Burst" then
            if pattern_kind ~= nil and pattern_kind ~= opcode then
                return nil, "payload_pattern_ambiguous"
            end
            pattern_kind = opcode
            pattern_op = pattern_op or op
        elseif opcode == "Speed+" then
            helper_speed_count = helper_speed_count + 1
        elseif opcode == "Size+" then
            helper_size_count = helper_size_count + 1
        elseif opcode == "Homing" then
            helper_homing_count = helper_homing_count + 1
        elseif opcode == "Detonate" then
            helper_detonate_count = helper_detonate_count + 1
        else
            return nil, "unsupported_payload_prefix_" .. tostring(opcode)
        end
    end

    if slot_speed_count ~= helper_speed_count
        or slot_size_count ~= helper_size_count
        or slot_homing_count ~= helper_homing_count
        or slot_detonate_count ~= helper_detonate_count then
        return nil, "payload_modifier_unsupported_prefix"
    end
    if slot_detonate_count > 1 or helper_detonate_count > 1 then
        return nil, "detonate_modifier_combo_deferred"
    end
    if slot_detonate_count > 0 then
        if pattern_kind ~= nil
            or slot_speed_count > 0
            or slot_size_count > 0
            or slot_homing_count > 0 then
            return nil, "detonate_modifier_combo_deferred"
        end
        local policy = launch_modifier_policy.inspectPayloadEntry(plan, nil, slot, options)
        if policy.ok ~= true then
            return nil, policy.rejection_reason or "detonate_modifier_combo_deferred", pattern_kind, cloneOp(pattern_op), policy, slot_homing_count > 0
        end
        return saw_multicast, nil, pattern_kind, cloneOp(pattern_op), policy, slot_homing_count > 0
    end
    if slot_speed_count > 0 or slot_size_count > 0 then
        local policy = launch_modifier_policy.inspectPayloadEntry(plan, nil, slot, options)
        if policy.ok ~= true then
            return nil, policy.rejection_reason or "payload_modifier_combo_deferred", pattern_kind, cloneOp(pattern_op), policy, slot_homing_count > 0
        end
        return saw_multicast, nil, pattern_kind, cloneOp(pattern_op), policy, slot_homing_count > 0
    end

    return saw_multicast, nil, pattern_kind, cloneOp(pattern_op), nil, slot_homing_count > 0
end

local function auditAllowsPayloadMulticast(plan, fanout_count, options)
    options = options or {}
    local max_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_jobs = tonumber(options.max_jobs) or limits.MAX_NESTED_PAYLOAD_JOBS
    local max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if options.source_context_validated == true then
        if fanout_count > max_fanout then
            recordBudgetCap("fanout")
            return false, "payload_multicast_fanout_cap_exceeded"
        end
        if fanout_count > max_jobs then
            recordBudgetCap("job")
            return false, "payload_multicast_job_cap_exceeded"
        end
        if fanout_count > max_projectiles then
            recordBudgetCap("projectile")
            return false, "payload_multicast_projectile_cap_exceeded"
        end
        return true
    end
    local audit = nested_payload_audit.inspectPlan(plan, {
        max_depth = options.max_depth or limits.MAX_NESTED_PAYLOAD_DEPTH,
        max_jobs = max_jobs,
        max_fanout = max_fanout,
        max_projectiles = max_projectiles,
        allowed_primary_prefix_ops = options.allowed_primary_prefix_ops,
    })
    if not audit.ok then
        return false, audit.rejection_reason or "nested_payload_audit_rejected", audit
    end
    if audit.has_chain then
        return false, "payload_multicast_chain_deferred", audit
    end
    if options.allow_nested_final_fanout == true then
        local max_depth = tonumber(options.max_depth)
            or tonumber(limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH)
            or 3
        if audit.max_payload_depth > max_depth then
            return false, "nested_depth_exceeded", audit
        end
    elseif audit.max_payload_depth ~= 1 then
        return false, "nested_payload_runtime_deferred", audit
    end
    if audit.nested_payload_count > 0 and options.allow_nested_final_fanout ~= true then
        return false, "nested_payload_runtime_deferred", audit
    end
    if audit.has_pattern_payload and options.allow_payload_pattern ~= true then
        return false, "payload_pattern_runtime_deferred", audit
    end
    if audit.has_speed_plus_payload or audit.has_size_plus_payload then
        local launch_modifiers_allowed = options.allow_payload_launch_modifiers == true
            or options.force_speed_plus_enabled == true
            or options.speed_plus_enabled == true
            or options.force_size_plus_enabled == true
            or options.size_plus_enabled == true
        if not launch_modifiers_allowed then
            return false, "payload_modifier_combo_deferred", audit
        end
        if options.allow_nested_final_fanout == true then
            if audit.max_payload_depth > (limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3) then
                return false, "nested_depth_exceeded", audit
            end
        elseif audit.max_payload_depth ~= 1 or audit.nested_payload_count > 0 then
            return false, "payload_modifier_nested_deferred", audit
        end
    end
    if fanout_count > max_fanout then
        recordBudgetCap("fanout")
        return false, "payload_multicast_fanout_cap_exceeded", audit
    end
    if audit.estimated_total_jobs > max_jobs then
        recordBudgetCap("job")
        return false, "payload_multicast_job_cap_exceeded", audit
    end
    if audit.estimated_total_jobs > max_projectiles then
        recordBudgetCap("projectile")
        return false, "payload_multicast_projectile_cap_exceeded", audit
    end
    return true, nil, audit
end

function payload_multicast.resolvePayloadHelpersForSource(plan, source_slot, opts)
    local options = opts or {}
    local source_opcode = options.source_opcode
    if type(plan) ~= "table" then
        return reject("missing_plan")
    end
    if type(source_slot) ~= "table" or type(source_slot.slot_id) ~= "string" then
        return reject("missing_source_slot")
    end
    if source_opcode ~= "Trigger" and source_opcode ~= "Timer" then
        return reject("unsupported_payload_source_opcode")
    end
    if type(plan.emission_slots) ~= "table" or #plan.emission_slots == 0 then
        return reject("slot_count_zero")
    end
    if type(plan.helper_records) ~= "table" or #plan.helper_records == 0 then
        return reject("helper_record_count_zero")
    end

    local helpers_by_slot = helperBySlotId(plan.helper_records)
    local slots_by_id = {}
    for _, slot in ipairs(plan.emission_slots or {}) do
        if type(slot) == "table" and type(slot.slot_id) == "string" then
            slots_by_id[slot.slot_id] = slot
        end
    end
    local payloads = {}
    local saw_multicast = false
    local saw_pattern = false
    local pattern_kind = nil
    local pattern_op = nil
    local saw_payload_modifier = false
    local saw_payload_homing = false
    local payload_modifier_kinds = {}
    local saw_unrelated_payload = false

    for _, slot in ipairs(plan.emission_slots) do
        if slot.kind == "payload_emission" then
            if slot.parent_slot_id == source_slot.slot_id and slot.source_postfix_opcode == source_opcode then
                local helper = helpers_by_slot[slot.slot_id]
                if not helper or type(helper.engine_id) ~= "string" or helper.engine_id == "" then
                    return reject("payload_helper_missing")
                end
                if helper.parent_slot_id ~= source_slot.slot_id or helper.source_postfix_opcode ~= source_opcode then
                    return reject("payload_helper_mapping_mismatch")
                end
                if source_opcode == "Trigger" then
                    if slot.trigger_source_slot_id ~= source_slot.slot_id or helper.trigger_source_slot_id ~= source_slot.slot_id then
                        return reject("payload_trigger_source_mismatch")
                    end
                    if slot.timer_source_slot_id ~= nil or helper.timer_source_slot_id ~= nil then
                        return reject("payload_timer_source_rejected")
                    end
                else
                    if slot.timer_source_slot_id ~= source_slot.slot_id or helper.timer_source_slot_id ~= source_slot.slot_id then
                        return reject("payload_timer_source_mismatch")
                    end
                    if slot.trigger_source_slot_id ~= nil or helper.trigger_source_slot_id ~= nil then
                        return reject("payload_trigger_source_rejected")
                    end
                end
                local slot_postfix = firstPostfixKind(slot)
                local helper_postfix = firstPostfixKind(helper)
                local has_nested_payload = slot_postfix ~= nil
                    or helper_postfix ~= nil
                    or hasPayloadBindings(slot.payload_bindings)
                    or hasPayloadBindings(helper.payload_bindings)
                local has_detonate_payload = hasOpcode(slot.prefix_ops, "Detonate")
                    or hasOpcode(helper.prefix_ops, "Detonate")
                if has_nested_payload then
                    if has_detonate_payload then
                        return reject("detonate_nested_continuation_unsupported")
                    end
                    if options.allow_nested_trigger_timer ~= true then
                        return reject("nested_payload_runtime_deferred")
                    end
                    if slot_postfix ~= helper_postfix then
                        return reject("nested_recursion_unsupported")
                    end
                    if slot_postfix ~= "Trigger" and slot_postfix ~= "Timer" then
                        return reject("nested_recursion_unsupported")
                    end
                    if payloadDepth(slot, slots_by_id) >= (tonumber(options.max_depth) or limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3) then
                        return reject("nested_depth_exceeded")
                    end
                end

                local prefix_multicast, prefix_reason, prefix_pattern_kind, prefix_pattern_op, prefix_policy, prefix_homing = payloadPrefixPolicy(plan, slot, helper, options)
                if prefix_reason then
                    return reject(prefix_reason, {
                        detected_payload_pattern = prefix_reason == "payload_pattern_ambiguous",
                        detected_payload_modifier = prefix_policy ~= nil,
                        detected_payload_homing = prefix_homing == true,
                    })
                end
                saw_payload_homing = saw_payload_homing or prefix_homing == true
                if prefix_policy and prefix_policy.mutations and prefix_policy.mutations.payload_modifier_kind ~= nil then
                    saw_payload_modifier = true
                    payload_modifier_kinds[#payload_modifier_kinds + 1] = prefix_policy.mutations.payload_modifier_kind
                end
                if prefix_pattern_kind ~= nil then
                    if pattern_kind ~= nil and pattern_kind ~= prefix_pattern_kind then
                        return reject("payload_pattern_ambiguous", {
                            detected_payload_pattern = true,
                        })
                    end
                    saw_pattern = true
                    pattern_kind = prefix_pattern_kind
                    pattern_op = pattern_op or prefix_pattern_op
                end
                saw_multicast = saw_multicast or prefix_multicast == true
                payloads[#payloads + 1] = compactPayload(slot, helper, slots_by_id)
            else
                saw_unrelated_payload = true
            end
        end
    end

    if #payloads == 0 then
        return reject("payload_missing")
    end
    table.sort(payloads, sortByEmissionThenSlot)

    local is_payload_multicast = saw_multicast or #payloads > 1
    local is_payload_pattern = saw_pattern == true
    local is_explicit_summon_source_fanout = #payloads > 1
        and not saw_multicast
        and not is_payload_pattern
        and allPayloadsAreSummonSources(payloads)
    local max_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if saw_payload_homing and not homingAllowed(options) then
        return reject("live_homing_disabled", {
            detected_payload_homing = true,
            detected_payload_multicast = is_payload_multicast,
            detected_payload_pattern = is_payload_pattern,
            payload_count = #payloads,
            fanout_count = #payloads,
            pattern_kind = pattern_kind,
        })
    end
    if #payloads > 1 and not saw_multicast and not is_explicit_summon_source_fanout then
        return reject("multiple_payloads_without_multicast")
    end
    if is_payload_pattern and not is_payload_multicast then
        return reject("payload_pattern_fanout_missing", {
            detected_payload_pattern = true,
            payload_count = #payloads,
            fanout_count = #payloads,
        })
    end
    if is_payload_multicast and not is_explicit_summon_source_fanout and options.allow_payload_multicast ~= true then
        return reject("payload_multicast_disabled", {
            detected_payload_multicast = true,
            detected_payload_pattern = is_payload_pattern,
            payload_count = #payloads,
            fanout_count = #payloads,
        })
    end
    if is_payload_pattern and options.allow_payload_pattern ~= true then
        return reject("payload_pattern_disabled", {
            detected_payload_multicast = true,
            detected_payload_pattern = true,
            payload_count = #payloads,
            fanout_count = #payloads,
            pattern_kind = pattern_kind,
        })
    end
    if is_payload_multicast then
        if #payloads > max_fanout then
            recordBudgetCap("fanout")
            return reject("payload_multicast_fanout_cap_exceeded", {
                detected_payload_multicast = true,
                detected_payload_pattern = is_payload_pattern,
                payload_count = #payloads,
                fanout_count = #payloads,
                fanout_cap = max_fanout,
            })
        end
        if #payloads + 1 > max_projectiles then
            recordBudgetCap("projectile")
            return reject("payload_multicast_projectile_cap_exceeded", {
                detected_payload_multicast = true,
                detected_payload_pattern = is_payload_pattern,
                payload_count = #payloads,
                fanout_count = #payloads,
                projectile_cap = max_projectiles,
            })
        end
        if not is_explicit_summon_source_fanout then
            local audit_ok, audit_reason, audit = auditAllowsPayloadMulticast(plan, #payloads, options)
            if not audit_ok then
                return reject(audit_reason, {
                    detected_payload_multicast = true,
                    detected_payload_pattern = is_payload_pattern,
                    payload_count = #payloads,
                    fanout_count = #payloads,
                    audit = audit,
                })
            end
        end
    elseif saw_unrelated_payload
        and options.allow_nested_final_fanout ~= true
        and options.allow_nested_trigger_timer ~= true
        and options.allow_unrelated_payloads ~= true then
        -- A simple v0 source must not hide extra payload structure elsewhere.
        return reject("nested_payload_runtime_deferred")
    end

    local payload_slot_ids = {}
    local payload_helper_engine_ids = {}
    local payload_effect_ids = {}
    local payload_group_key_parts = {}
    for index, payload in ipairs(payloads) do
        payload_slot_ids[index] = payload.slot_id
        payload_helper_engine_ids[index] = payload.helper_engine_id
        payload_effect_ids[index] = payload.effect_id
        payload_group_key_parts[index] = payload.slot_id
    end

    return {
        ok = true,
        source_slot_id = source_slot.slot_id,
        source_opcode = source_opcode,
        payload_count = #payloads,
        payload_slots = payloads,
        payload_helpers = payloads,
        payload_slot_ids = payload_slot_ids,
        payload_helper_engine_ids = payload_helper_engine_ids,
        payload_effect_ids = payload_effect_ids,
        payload_slot_id = payload_slot_ids[1],
        payload_helper_engine_id = payload_helper_engine_ids[1],
        payload_effect_id = payload_effect_ids[1],
        fanout_count = #payloads,
        detected_payload_multicast = is_payload_multicast,
        detected_payload_pattern = is_payload_pattern,
        detected_summon_source_fanout = is_explicit_summon_source_fanout,
        detected_payload_modifier = saw_payload_modifier,
        detected_payload_homing = saw_payload_homing,
        is_payload_multicast = is_payload_multicast,
        is_payload_pattern = is_payload_pattern,
        is_summon_source_fanout = is_explicit_summon_source_fanout,
        has_payload_modifier = saw_payload_modifier,
        has_payload_homing = saw_payload_homing,
        payload_modifier_kinds = payload_modifier_kinds,
        pattern_kind = pattern_kind,
        pattern_op = pattern_op,
        payload_group_key = table.concat(payload_group_key_parts, ","),
        audit_only = false,
    }
end

return payload_multicast
