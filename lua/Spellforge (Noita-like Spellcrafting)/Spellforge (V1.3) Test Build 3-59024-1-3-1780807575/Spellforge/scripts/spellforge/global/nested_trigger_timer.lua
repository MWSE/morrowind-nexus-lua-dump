---@omw-context global
local limits = require("scripts.spellforge.shared.limits")
local chaos_budget = require("scripts.spellforge.global.chaos_budget")
local nested_payload_audit = require("scripts.spellforge.global.nested_payload_audit")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local nested_trigger_timer = {}

local function hasOps(ops)
    return type(ops) == "table" and #ops > 0
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true, op
        end
    end
    return false, nil
end

local function onlyPostfix(slot, opcode)
    local ops = slot and slot.postfix_ops
    return type(ops) == "table" and #ops == 1 and ops[1].opcode == opcode, ops and ops[1] or nil
end

local function stageKind(slot)
    if onlyPostfix(slot, "Trigger") then
        return "Trigger"
    end
    if onlyPostfix(slot, "Timer") then
        return "Timer"
    end
    if hasOpcode(slot and slot.postfix_ops, "Trigger") then
        return "Trigger"
    end
    if hasOpcode(slot and slot.postfix_ops, "Timer") then
        return "Timer"
    end
    return nil
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

local function childrenByParent(slots)
    local out = {}
    for _, slot in ipairs(slots or {}) do
        if type(slot.parent_slot_id) == "string" then
            local children = out[slot.parent_slot_id]
            if not children then
                children = {}
                out[slot.parent_slot_id] = children
            end
            children[#children + 1] = slot
        end
    end
    for _, children in pairs(out) do
        table.sort(children, function(a, b)
            local ai = tonumber(a.emission_index) or 0
            local bi = tonumber(b.emission_index) or 0
            if ai ~= bi then
                return ai < bi
            end
            return tostring(a.slot_id) < tostring(b.slot_id)
        end)
    end
    return out
end

local function firstEffectId(helper)
    local first = helper and helper.effects and helper.effects[1] or nil
    return first and first.id or nil
end

local function timerDelayFromOp(op)
    local seconds = op and op.params and tonumber(op.params.seconds) or 1.0
    if seconds == nil or seconds ~= seconds or seconds < 0 then
        return nil, nil, "timer_delay_invalid"
    end
    if seconds > 5.0 then
        seconds = 5.0
    end
    local ticks = math.ceil(seconds * 2)
    if ticks < 1 then
        ticks = 1
    end
    return seconds, ticks, nil
end

local function reject(reason, counter)
    runtime_stats.inc("nested_tt_rejected")
    if counter then
        runtime_stats.inc(counter)
    end
    return nil, reason
end

local function rejectFinalFanout(reason, tt_counter, final_counter)
    runtime_stats.inc("nested_final_fanout_rejected")
    if final_counter then
        runtime_stats.inc(final_counter)
    end
    return reject(reason, tt_counter)
end

local function recordAuditBudgetReject(reason)
    if reason == "exceeds_fanout_cap" then
        chaos_budget.recordReject("nested_final_fanout_cap_exceeded", "fanout")
    elseif reason == "exceeds_projectile_cap" then
        chaos_budget.recordReject("nested_final_projectile_cap_exceeded", "projectile")
    elseif reason == "exceeds_job_cap" then
        chaos_budget.recordReject("nested_final_job_cap_exceeded", "job")
    elseif reason == "exceeds_depth_cap" then
        chaos_budget.recordReject("nested_payload_depth_cap_exceeded", "depth")
    end
end

local function slotPayload(slot, helper, root_slot_id, current_source_slot_id, payload_depth, stage_kind)
    local has_trigger = hasOpcode(slot.postfix_ops, "Trigger")
    local has_timer = hasOpcode(slot.postfix_ops, "Timer")
    return {
        slot_id = slot.slot_id,
        helper_engine_id = helper.engine_id,
        effect_id = firstEffectId(helper),
        emission_index = slot.emission_index or helper.emission_index,
        group_index = slot.group_index or helper.group_index,
        parent_slot_id = slot.parent_slot_id,
        root_source_slot_id = root_slot_id,
        current_source_slot_id = current_source_slot_id,
        payload_depth = payload_depth,
        nested_stage_kind = stage_kind,
        has_trigger_payload = has_trigger == true,
        has_timer_payload = has_timer == true,
    }
end

local function payloadFromCompact(payload, root_slot_id, current_source_slot_id, payload_depth, stage_kind)
    local slot = payload and payload.slot or {}
    return {
        slot_id = payload.slot_id,
        helper_engine_id = payload.helper_engine_id,
        effect_id = payload.effect_id,
        emission_index = payload.emission_index,
        group_index = payload.group_index,
        parent_slot_id = slot.parent_slot_id,
        root_source_slot_id = root_slot_id,
        current_source_slot_id = current_source_slot_id,
        payload_depth = payload_depth,
        nested_stage_kind = stage_kind,
        has_trigger_payload = false,
        has_timer_payload = false,
    }
end

local function mapFinalFanoutReject(reason)
    if reason == "payload_multicast_chain_deferred" or reason == "chain_deferred" then
        return "nested_tt_chain_reject", "nested_final_fanout_chain_reject"
    elseif reason == "payload_multicast_fanout_cap_exceeded"
        or reason == "payload_multicast_projectile_cap_exceeded"
        or reason == "payload_multicast_job_cap_exceeded"
        or reason == "exceeds_fanout_cap"
        or reason == "exceeds_projectile_cap"
        or reason == "exceeds_job_cap" then
        return "nested_tt_multicast_reject", "nested_final_fanout_cap_reject"
    elseif reason == "payload_pattern_disabled" or reason == "payload_pattern_runtime_deferred" then
        return "nested_tt_pattern_reject", "nested_final_fanout_pattern_reject"
    elseif reason == "payload_modifier_combo_deferred"
        or reason == "payload_modifier_pattern_deferred"
        or reason == "payload_modifier_nested_deferred"
        or reason == "payload_modifier_unsupported_prefix"
        or reason == "payload_speed_plus_disabled"
        or reason == "payload_size_plus_disabled"
        or string.sub(tostring(reason), 1, 28) == "unsupported_payload_prefix_" then
        return "nested_tt_modifier_reject", "nested_final_fanout_nested_behavior_reject"
    elseif reason == "nested_payload_runtime_deferred"
        or reason == "nested_depth_exceeded"
        or reason == "exceeds_depth_cap" then
        return "nested_tt_depth_reject", "nested_final_fanout_nested_behavior_reject"
    end
    return nil, "nested_final_fanout_nested_behavior_reject"
end

local function sourcePair(slot, helper)
    return {
        slot = slot,
        helper = helper,
    }
end

function nested_trigger_timer.inspectShape(plan)
    local audit = nested_payload_audit.inspectPlan(plan, {
        max_depth = limits.MAX_NESTED_PAYLOAD_DEPTH,
        max_jobs = limits.MAX_NESTED_PAYLOAD_JOBS,
        max_fanout = limits.MAX_NESTED_PAYLOAD_FANOUT,
    })
    local details = {
        is_nested_trigger_timer = false,
        rejection_reason = audit.rejection_reason,
        recipe_id = plan and plan.recipe_id or nil,
        plan_recipe_id = plan and plan.recipe_id or nil,
        slot_count = audit.slot_count,
        helper_count = audit.helper_count,
        max_payload_depth = audit.max_payload_depth,
        has_trigger_payload = audit.has_trigger_payload,
        has_timer_payload = audit.has_timer_payload,
        has_multicast_payload = audit.has_multicast_payload,
        has_pattern_payload = audit.has_pattern_payload,
        has_chain = audit.has_chain,
        trigger_source_count = audit.trigger_source_count,
        timer_source_count = audit.timer_source_count,
        trigger_payload_count = audit.trigger_payload_count,
        timer_payload_count = audit.timer_payload_count,
        estimated_total_jobs = audit.estimated_total_jobs,
        unsupported_reasons = audit.unsupported_reasons,
    }
    if type(plan) ~= "table" then
        return details
    end

    local slots = plan.emission_slots or {}
    local children = childrenByParent(slots)
    local root_slot = nil
    for _, slot in ipairs(slots) do
        if slot.kind == "primary_emission" then
            root_slot = root_slot or slot
        end
    end
    if not root_slot then
        return details
    end

    details.root_source_slot_id = root_slot.slot_id
    details.root_stage_kind = stageKind(root_slot)
    local root_children = children[root_slot.slot_id] or {}
    local intermediate_slot = root_children[1]
    if not intermediate_slot then
        return details
    end

    details.intermediate_slot_id = intermediate_slot.slot_id
    details.intermediate_stage_kind = stageKind(intermediate_slot)
    local final_children = children[intermediate_slot.slot_id] or {}
    local final_slot = final_children[1]
    if final_slot then
        details.final_payload_slot_id = final_slot.slot_id
    end

    if details.root_stage_kind == "Trigger" and details.intermediate_stage_kind == "Timer" then
        details.is_nested_trigger_timer = true
        details.nested_kind = "trigger_timer"
    elseif details.root_stage_kind == "Timer" and details.intermediate_stage_kind == "Trigger" then
        details.is_nested_trigger_timer = true
        details.nested_kind = "timer_trigger"
    end
    return details
end

function nested_trigger_timer.selectV1Plan(plan, opts)
    local options = opts or {}
    local max_depth = tonumber(options.max_depth) or limits.MAX_NESTED_PAYLOAD_DEPTH
    local max_jobs = tonumber(options.max_jobs) or limits.MAX_NESTED_PAYLOAD_JOBS
    local max_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    runtime_stats.inc("nested_tt_attempts")
    if type(plan) ~= "table" then
        return reject("missing_plan")
    end

    local audit = nested_payload_audit.inspectPlan(plan, {
        max_depth = max_depth,
        max_jobs = max_jobs,
        max_fanout = max_fanout,
    })
    if audit.ok ~= true then
        local reason = audit.rejection_reason or "nested_audit_rejected"
        if audit.max_payload_depth == 2 and (audit.has_multicast_payload or audit.has_pattern_payload) then
            local tt_counter, final_counter = mapFinalFanoutReject(reason)
            runtime_stats.inc("nested_final_fanout_attempts")
            recordAuditBudgetReject(reason)
            return rejectFinalFanout(reason, tt_counter, final_counter)
        end
        local counter = nil
        if audit.has_chain then
            counter = "nested_tt_chain_reject"
        elseif audit.exceeds_depth_cap then
            counter = "nested_tt_depth_reject"
        end
        return reject(reason, counter)
    end
    if options.enabled ~= true then
        return reject("nested_trigger_timer_disabled", "nested_tt_disabled_reject")
    end
    if audit.max_payload_depth ~= 2 then
        if audit.max_payload_depth > max_depth then
            return reject("nested_depth_exceeded", "nested_tt_depth_reject")
        end
        return reject("nested_recursion_unsupported", "nested_tt_depth_reject")
    end
    if audit.has_chain then
        return reject("chain_deferred", "nested_tt_chain_reject")
    end
    if audit.has_speed_plus_payload or audit.has_size_plus_payload then
        return reject("nested_payload_modifier_deferred", "nested_tt_modifier_reject")
    end
    if audit.trigger_source_count ~= 1 or audit.timer_source_count ~= 1 then
        return reject("nested_recursion_unsupported")
    end
    if audit.estimated_total_jobs > max_jobs
        or audit.estimated_total_jobs > max_projectiles then
        return reject("nested_trigger_timer_job_cap_exceeded", "nested_tt_depth_reject")
    end

    local slots = plan.emission_slots or {}
    local helpers = plan.helper_records or {}
    local helpers_by_slot = helperBySlotId(helpers)
    local children = childrenByParent(slots)

    local root_slot = nil
    for _, slot in ipairs(slots) do
        if slot.kind == "primary_emission" then
            if root_slot then
                return reject("nested_trigger_timer_multiple_roots")
            end
            root_slot = slot
        end
    end
    if not root_slot then
        return reject("nested_trigger_timer_missing_root")
    end
    if hasOps(root_slot.prefix_ops) then
        return reject("nested_trigger_timer_root_prefix_deferred")
    end

    local root_is_timer, root_timer_op = onlyPostfix(root_slot, "Timer")
    local root_is_trigger = onlyPostfix(root_slot, "Trigger")
    if not root_is_timer and not root_is_trigger then
        return reject("nested_trigger_timer_root_not_trigger_or_timer")
    end
    local root_kind = root_is_timer and "Timer" or "Trigger"
    local intermediate_kind = root_kind == "Timer" and "Trigger" or "Timer"
    local nested_kind = root_kind == "Timer" and "timer_trigger" or "trigger_timer"

    local root_helper = helpers_by_slot[root_slot.slot_id]
    if not root_helper or type(root_helper.engine_id) ~= "string" or root_helper.engine_id == "" then
        return reject("nested_trigger_timer_root_helper_missing")
    end

    local root_children = children[root_slot.slot_id] or {}
    if #root_children ~= 1 then
        if #root_children > 1 then
            return reject("nested_payload_multicast_deferred", "nested_tt_multicast_reject")
        end
        return reject("nested_trigger_timer_requires_one_intermediate")
    end
    local intermediate_slot = root_children[1]
    local intermediate_helper = helpers_by_slot[intermediate_slot.slot_id]
    if not intermediate_helper or type(intermediate_helper.engine_id) ~= "string" or intermediate_helper.engine_id == "" then
        return reject("nested_trigger_timer_intermediate_helper_missing")
    end
    if intermediate_slot.source_postfix_opcode ~= root_kind then
        return reject("nested_trigger_timer_intermediate_source_mismatch")
    end
    if hasOps(intermediate_slot.prefix_ops) then
        return reject("nested_trigger_timer_intermediate_prefix_deferred", "nested_tt_modifier_reject")
    end
    if not onlyPostfix(intermediate_slot, intermediate_kind) then
        if hasOpcode(intermediate_slot.postfix_ops, root_kind) then
            return reject("nested_trigger_timer_same_kind_deferred", "nested_tt_depth_reject")
        end
        return reject("nested_trigger_timer_intermediate_postfix_mismatch")
    end

    local final_result = payload_multicast.resolvePayloadHelpersForSource(plan, intermediate_slot, {
        source_opcode = intermediate_kind,
        allow_payload_multicast = true,
        allow_payload_pattern = true,
        allow_nested_final_fanout = true,
        max_depth = max_depth,
        max_jobs = max_jobs,
        max_fanout = max_fanout,
        max_projectiles = max_projectiles,
    })
    if final_result.ok ~= true then
        local result_reason = final_result.rejection_reason or "nested_trigger_timer_final_payload_rejected"
        local tt_counter, final_counter = mapFinalFanoutReject(result_reason)
        if result_reason == "payload_missing" then
            return reject("nested_trigger_timer_requires_one_final_payload")
        end
        if result_reason == "payload_helper_missing" then
            return reject("nested_trigger_timer_final_helper_missing")
        end
        if result_reason == "payload_timer_source_mismatch"
            or result_reason == "payload_trigger_source_mismatch"
            or result_reason == "payload_helper_mapping_mismatch"
            or result_reason == "payload_timer_source_rejected"
            or result_reason == "payload_trigger_source_rejected" then
            return reject("nested_trigger_timer_final_source_mismatch")
        end
        return rejectFinalFanout(result_reason, tt_counter, final_counter)
    end

    local is_final_fanout = final_result.is_payload_multicast == true
        or final_result.is_payload_pattern == true
        or tonumber(final_result.payload_count) > 1
    if is_final_fanout then
        runtime_stats.inc("nested_final_fanout_attempts")
        if options.enable_final_fanout ~= true then
            return rejectFinalFanout(
                "nested_final_fanout_disabled",
                "nested_tt_multicast_reject",
                "nested_final_fanout_disabled_reject"
            )
        end
        if final_result.is_payload_multicast == true and options.allow_payload_multicast ~= true then
            return rejectFinalFanout(
                "payload_multicast_disabled",
                "nested_tt_multicast_reject",
                "nested_final_fanout_disabled_reject"
            )
        end
        if final_result.is_payload_pattern == true and options.allow_payload_pattern ~= true then
            return rejectFinalFanout(
                "payload_pattern_disabled",
                "nested_tt_pattern_reject",
                "nested_final_fanout_pattern_reject"
            )
        end
        if tonumber(final_result.payload_count) < 2 then
            return rejectFinalFanout(
                "nested_final_fanout_requires_multiple_payloads",
                "nested_tt_multicast_reject",
                "nested_final_fanout_cap_reject"
            )
        end
    elseif audit.has_multicast_payload then
        return reject("nested_payload_multicast_deferred", "nested_tt_multicast_reject")
    elseif audit.has_pattern_payload then
        return reject("nested_payload_pattern_deferred", "nested_tt_pattern_reject")
    end

    local final_payload_sources = final_result.payload_slots or {}
    local final_slot = final_payload_sources[1] and final_payload_sources[1].slot or nil
    local final_helper = final_payload_sources[1] and final_payload_sources[1].helper or nil
    if not final_slot or not final_helper then
        return reject("nested_trigger_timer_final_helper_missing")
    end
    local final_payloads = {}
    for index, payload in ipairs(final_payload_sources) do
        final_payloads[index] = payloadFromCompact(
            payload,
            root_slot.slot_id,
            intermediate_slot.slot_id,
            2,
            nested_kind .. "_final"
        )
    end
    local final_payload_slot_ids = {}
    local final_payload_helper_engine_ids = {}
    for index, payload in ipairs(final_payloads) do
        final_payload_slot_ids[index] = payload.slot_id
        final_payload_helper_engine_ids[index] = payload.helper_engine_id
    end

    local nested_timer_seconds, nested_timer_ticks, nested_timer_error = nil, nil, nil
    if intermediate_kind == "Timer" then
        local ok_timer, timer_op = onlyPostfix(intermediate_slot, "Timer")
        if ok_timer then
            nested_timer_seconds, nested_timer_ticks, nested_timer_error = timerDelayFromOp(timer_op)
        end
        if nested_timer_error then
            return reject(nested_timer_error)
        end
    end
    local root_timer_seconds, root_timer_ticks, root_timer_error = nil, nil, nil
    if root_kind == "Timer" then
        root_timer_seconds, root_timer_ticks, root_timer_error = timerDelayFromOp(root_timer_op)
        if root_timer_error then
            return reject(root_timer_error)
        end
    end

    runtime_stats.inc("nested_tt_qualified")
    if nested_kind == "timer_trigger" then
        runtime_stats.inc("nested_tt_timer_trigger_qualified")
    else
        runtime_stats.inc("nested_tt_trigger_timer_qualified")
    end
    if is_final_fanout then
        runtime_stats.inc("nested_final_fanout_qualified")
        if nested_kind == "timer_trigger" then
            runtime_stats.inc("nested_final_fanout_timer_trigger_qualified")
        else
            runtime_stats.inc("nested_final_fanout_trigger_timer_qualified")
        end
    end

    local root_slot_id = root_slot.slot_id
    return {
        ok = true,
        mode = "nested_trigger_timer_v1",
        kind = nested_kind,
        nested_final_fanout = is_final_fanout == true,
        nested_final_fanout_kind = is_final_fanout
            and (nested_kind == "timer_trigger"
                and "timer_trigger_final_fanout"
                or "trigger_timer_final_fanout")
            or nil,
        root_kind = root_kind,
        intermediate_kind = intermediate_kind,
        root = sourcePair(root_slot, root_helper),
        intermediate = sourcePair(intermediate_slot, intermediate_helper),
        final = sourcePair(final_slot, final_helper),
        root_source_slot_id = root_slot_id,
        root_source_helper_engine_id = root_helper.engine_id,
        intermediate_slot_id = intermediate_slot.slot_id,
        intermediate_helper_engine_id = intermediate_helper.engine_id,
        final_payload_slot_id = final_slot.slot_id,
        final_payload_helper_engine_id = final_helper.engine_id,
        final_payload_slot_ids = final_payload_slot_ids,
        final_payload_helper_engine_ids = final_payload_helper_engine_ids,
        final_payload_count = #final_payloads,
        final_payloads = final_payloads,
        final_payload_group_key = final_result.payload_group_key,
        final_fanout_count = #final_payloads,
        payload_multicast = is_final_fanout and final_result.is_payload_multicast == true or false,
        payload_pattern = is_final_fanout and final_result.is_payload_pattern == true or false,
        payload_pattern_kind = is_final_fanout and final_result.pattern_kind or nil,
        payload_pattern_op = is_final_fanout and final_result.pattern_op or nil,
        intermediate_payload = slotPayload(
            intermediate_slot,
            intermediate_helper,
            root_slot_id,
            intermediate_slot.slot_id,
            1,
            nested_kind .. "_intermediate"
        ),
        final_payload = slotPayload(
            final_slot,
            final_helper,
            root_slot_id,
            intermediate_slot.slot_id,
            2,
            nested_kind .. "_final"
        ),
        root_timer_seconds = root_timer_seconds,
        root_timer_delay_ticks = root_timer_ticks,
        nested_timer_seconds = nested_timer_seconds,
        nested_timer_delay_ticks = nested_timer_ticks,
        audit = audit,
    }, nil
end

return nested_trigger_timer
