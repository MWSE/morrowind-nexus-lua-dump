local limits = require("scripts.spellforge.shared.limits")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local homing_launch_policy = require("scripts.spellforge.global.homing_launch_policy")

local runtime_job_planner = {}

runtime_job_planner.VERSION = "spellforge-runtime-job-planner-v1"

local TIMER_TICKS_PER_SECOND = 2
local DEFAULT_TIMER_SECONDS = 1.0
local MAX_TIMER_SECONDS = 5.0

local LIVE_TRIGGER_PAYLOAD_JOB_KIND = "live_trigger_payload_launch"
local LIVE_TIMER_PAYLOAD_JOB_KIND = "live_timer_payload_launch"
local LIVE_CHAIN_PAYLOAD_JOB_KIND = "live_chain_payload_launch"
local CHAIN_HANDOFF_JOB_KIND = "live_chain_handoff"

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function payloadModifierOptions(opts)
    local out = {}
    for key, value in pairs(opts or {}) do
        out[key] = value
    end
    out.allow_payload_detonate = true
    return out
end

local function helperId(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return entry.helper_engine_id or entry.helper_logical_id
end

local function entryBySlot(ir, slot_id)
    if type(slot_id) ~= "string" or slot_id == "" then
        return nil
    end
    if ir and ir.entries_by_slot_id and ir.entries_by_slot_id[slot_id] then
        return ir.entries_by_slot_id[slot_id]
    end
    for _, entry in ipairs(ir and ir.entries or {}) do
        if entry.slot_id == slot_id then
            return entry
        end
    end
    return nil
end

local function continuationById(ir, continuation_id)
    if type(continuation_id) ~= "string" or continuation_id == "" then
        return nil
    end
    if ir and ir.continuations_by_id and ir.continuations_by_id[continuation_id] then
        return ir.continuations_by_id[continuation_id]
    end
    for _, continuation in ipairs(ir and ir.continuations or {}) do
        if continuation.continuation_id == continuation_id then
            return continuation
        end
    end
    return nil
end

local function continuationBySourceKind(ir, source_slot_id, kind)
    for _, continuation in ipairs(ir and ir.continuations or {}) do
        if continuation.source_slot_id == source_slot_id and continuation.kind == kind then
            return continuation
        end
    end
    return nil
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true, op
        end
    end
    return false, nil
end

local function clampPositiveInteger(value, default_value, hard_max)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = default_value or 1
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    end
    if hard_max and n > hard_max then
        n = hard_max
    end
    return n
end

local function clampBouncePower(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = tonumber(limits.BOUNCE_POWER_DEFAULT) or 0.72
    end
    local min_value = tonumber(limits.BOUNCE_POWER_MIN) or 0.2
    local max_value = tonumber(limits.BOUNCE_POWER_MAX) or 1.25
    if n < min_value then
        n = min_value
    elseif n > max_value then
        n = max_value
    end
    return n
end

local function timerDelayFromContinuation(continuation, event)
    local event_ticks = event and event.timer_delay_ticks
    local event_seconds = event and event.timer_delay_seconds
    if event_ticks ~= nil or event_seconds ~= nil then
        local seconds = tonumber(event_seconds)
        local ticks = tonumber(event_ticks)
        if seconds == nil and ticks ~= nil then
            seconds = ticks / TIMER_TICKS_PER_SECOND
        end
        if ticks == nil and seconds ~= nil then
            ticks = math.ceil(seconds * TIMER_TICKS_PER_SECOND)
        end
        return seconds, clampPositiveInteger(ticks, 1, nil)
    end

    local raw_seconds = continuation and continuation.params and continuation.params.seconds
    local seconds = raw_seconds == nil and DEFAULT_TIMER_SECONDS or tonumber(raw_seconds)
    if seconds == nil or seconds ~= seconds or seconds < 0 then
        seconds = DEFAULT_TIMER_SECONDS
    end
    if seconds > MAX_TIMER_SECONDS then
        seconds = MAX_TIMER_SECONDS
    end
    local ticks = math.ceil(seconds * TIMER_TICKS_PER_SECOND)
    if ticks < 1 then
        ticks = 1
    end
    return seconds, ticks
end

local function runtimeKind(semantic_kind, event_kind)
    if semantic_kind == "trigger_payload_launch"
        or semantic_kind == "bounce_trigger_payload_launch"
        or semantic_kind == "pierce_trigger_payload_launch"
        or semantic_kind == "trigger_nested_continuation" then
        return LIVE_TRIGGER_PAYLOAD_JOB_KIND
    elseif semantic_kind == "timer_payload_launch"
        or semantic_kind == "timer_nested_continuation" then
        return LIVE_TIMER_PAYLOAD_JOB_KIND
    elseif semantic_kind == "chain_payload_hop" then
        return LIVE_CHAIN_PAYLOAD_JOB_KIND
    elseif semantic_kind == "chain_handoff" then
        return CHAIN_HANDOFF_JOB_KIND
    elseif event_kind == "timer_matured" then
        return LIVE_TIMER_PAYLOAD_JOB_KIND
    elseif event_kind == "chain" or event_kind == "chain_hit" or event_kind == "chain_hop" then
        return LIVE_CHAIN_PAYLOAD_JOB_KIND
    end
    return semantic_kind or "dry_run_runtime_job"
end

local function reject(plan, ir, continuation_plan, event, reason)
    return {
        ok = false,
        version = runtime_job_planner.VERSION,
        recipe_id = (continuation_plan and continuation_plan.recipe_id) or (ir and ir.recipe_id) or (plan and plan.recipe_id),
        event_kind = event and event.event_kind or (continuation_plan and continuation_plan.event_kind),
        source_slot_id = continuation_plan and continuation_plan.source_slot_id or (event and event.source_slot_id),
        source_helper_engine_id = continuation_plan and continuation_plan.source_helper_engine_id or nil,
        continuation_id = continuation_plan and continuation_plan.continuation_id or nil,
        planned_job_count = 0,
        planned_jobs = {},
        rejection_reason = reason,
    }
end

local function sourcePostfix(continuation_plan, event, source_entry)
    local continuation_kind = continuation_plan and continuation_plan.continuation_kind
    if continuation_kind ~= "Trigger" and continuation_kind ~= "Timer" then
        continuation_kind = nil
    end
    return firstNonNil(
        event and event.source_postfix_opcode,
        continuation_kind,
        source_entry and source_entry.source_postfix_opcode
    )
end

local function sourcePrefix(continuation_plan, event, source_entry)
    if event and event.source_prefix_opcode then
        return event.source_prefix_opcode
    end
    if continuation_plan and continuation_plan.bounce_mode then
        return "Bounce"
    end
    if continuation_plan and continuation_plan.pierce_mode then
        return "Pierce"
    end
    if continuation_plan and continuation_plan.has_chain_payload == true then
        return "Chain"
    end
    if hasOpcode(source_entry and source_entry.prefix_ops or nil, "Bounce") then
        return "Bounce"
    end
    if hasOpcode(source_entry and source_entry.prefix_ops or nil, "Pierce") then
        return "Pierce"
    end
    if hasOpcode(source_entry and source_entry.prefix_ops or nil, "Chain") then
        return "Chain"
    end
    return nil
end

local function branchScope(continuation_plan, event)
    return firstNonNil(
        event and event.branch_scope,
        continuation_plan and continuation_plan.continuation_id,
        continuation_plan and continuation_plan.recipe_id,
        "dry_run"
    )
end

local function branchParentId(continuation_plan, event)
    return firstNonNil(
        event and event.branch_parent_id,
        event and event.parent_job_id,
        continuation_plan and continuation_plan.source_slot_id,
        "source"
    )
end

local function branchId(scope, branch_kind, branch_index, slot_id)
    return table.concat({
        tostring(scope or "dry_run"),
        tostring(branch_kind or "branch"),
        tostring(branch_index or 1),
        tostring(slot_id or "slot"),
    }, ":")
end

local function eventCastId(event, opts)
    return firstNonNil(
        event and event.cast_id,
        opts and opts.cast_id,
        "dry_run_cast"
    )
end

local function bounceInfo(source_entry, continuation_plan, event)
    local _, bounce_op = hasOpcode(source_entry and source_entry.prefix_ops or nil, "Bounce")
    local bounce_max = firstNonNil(
        event and event.bounce_max,
        continuation_plan and continuation_plan.bounce_max,
        bounce_op and bounce_op.params and bounce_op.params.bounces
    )
    local bounce_power = firstNonNil(
        event and event.bounce_power,
        bounce_op and bounce_op.params and bounce_op.params.power
    )
    return {
        bounce_id = firstNonNil(
            event and event.bounce_id,
            continuation_plan and continuation_plan.bounce_id,
            "bounce:" .. tostring((continuation_plan and continuation_plan.recipe_id) or (source_entry and source_entry.recipe_id) or "recipe")
                .. ":" .. tostring(source_entry and source_entry.slot_id or "source")
        ),
        bounce_index = tonumber(event and event.bounce_index) or 1,
        bounce_max = clampPositiveInteger(bounce_max, 1, limits.MAX_BOUNCE_COUNT_HARD),
        bounce_power = clampBouncePower(bounce_power),
        bounce_final = event and event.bounce_final == true or false,
    }
end

local function pierceInfo(source_entry, continuation_plan, event)
    local _, pierce_op = hasOpcode(source_entry and source_entry.prefix_ops or nil, "Pierce")
    local pierce_limit = firstNonNil(
        event and event.pierce_limit,
        continuation_plan and continuation_plan.pierce_limit,
        pierce_op and pierce_op.params and pierce_op.params.pierces
    )
    return {
        pierce_id = firstNonNil(
            event and event.pierce_id,
            continuation_plan and continuation_plan.pierce_id,
            "pierce:" .. tostring((continuation_plan and continuation_plan.recipe_id) or (source_entry and source_entry.recipe_id) or "recipe")
                .. ":" .. tostring(source_entry and source_entry.slot_id or "source")
        ),
        pierce_count = tonumber(event and event.pierce_count) or 1,
        pierce_limit = clampPositiveInteger(pierce_limit, 1, limits.MAX_PIERCE_COUNT_HARD),
    }
end

local function chainInfo(continuation_plan, event, payload_entry)
    return {
        chain_id = firstNonNil(
            event and event.chain_id,
            continuation_plan and continuation_plan.chain_id,
            "chain:" .. tostring((continuation_plan and continuation_plan.recipe_id) or (payload_entry and payload_entry.recipe_id) or "recipe")
                .. ":" .. tostring(payload_entry and payload_entry.slot_id or "payload")
        ),
        chain_hop_index = tonumber(firstNonNil(event and event.chain_hop_index, 0)) or 0,
        chain_max_hops = tonumber(firstNonNil(
            event and event.chain_max_hops,
            continuation_plan and continuation_plan.max_hops,
            continuation_plan and continuation_plan.requested_hops,
            limits.MAX_CHAIN_HOPS
        )) or limits.MAX_CHAIN_HOPS,
        chain_targeting_mode = firstNonNil(event and event.chain_targeting_mode, "no_immediate_repeat"),
    }
end

local function patternInfo(continuation_plan, planned, payload_entry, index, count)
    local kind = firstNonNil(
        planned and planned.pattern_kind,
        payload_entry and payload_entry.fanout and payload_entry.fanout.has_pattern and continuation_plan and continuation_plan.payload_pattern_kind,
        continuation_plan and continuation_plan.payload_pattern_kind
    )
    if kind == false then
        kind = nil
    end
    return {
        pattern_kind = kind,
        pattern_index = kind and index or nil,
        pattern_count = kind and count or nil,
        pattern_direction_key = kind and string.format("dry:%s:%s", tostring(kind), tostring(index)) or nil,
    }
end

local function payloadMetadata(job)
    return {
        cast_id = job.cast_id,
        source_slot_id = job.source_slot_id,
        source_helper_engine_id = job.source_helper_engine_id,
        source_prefix_opcode = job.source_prefix_opcode,
        source_postfix_opcode = job.source_postfix_opcode,
        actor = job.actor,
        start_pos = job.start_pos,
        direction = job.direction,
        hit_pos = job.hit_pos,
        hit_object = job.hit_object,
        payload_slot_id = job.payload_slot_id,
        trigger_source_slot_id = job.trigger_source_slot_id,
        trigger_payload_slot_id = job.trigger_payload_slot_id,
        timer_source_slot_id = job.timer_source_slot_id,
        timer_payload_slot_id = job.timer_payload_slot_id,
        timer_id = job.timer_id,
        timer_delay_ticks = job.timer_delay_ticks,
        timer_delay_seconds = job.timer_delay_seconds,
        timer_due_tick = job.timer_due_tick,
        timer_due_seconds = job.timer_due_seconds,
        bounce_runtime = job.bounce_runtime,
        bounce_role = job.bounce_role,
        bounce_id = job.bounce_id,
        bounce_index = job.bounce_index,
        bounce_max = job.bounce_max,
        bounce_power = job.bounce_power,
        bounce_manual_detonation = job.bounce_manual_detonation,
        bounce_final = job.bounce_final,
        pierce_runtime = job.pierce_runtime,
        pierce_role = job.pierce_role,
        pierce_id = job.pierce_id,
        pierce_count = job.pierce_count,
        pierce_limit = job.pierce_limit,
        pierce_trigger_payload_slot_id = job.pierce_trigger_payload_slot_id,
        trigger_route = job.trigger_route,
        current_hit_target_id = job.current_hit_target_id,
        excludeTarget = job.excludeTarget,
        chain_runtime = job.chain_runtime,
        chain_role = job.chain_role,
        chain_id = job.chain_id,
        chain_hop_index = job.chain_hop_index,
        chain_max_hops = job.chain_max_hops,
        chain_continuation_group_id = job.chain_continuation_group_id,
        chain_side_continuation_kind = job.chain_side_continuation_kind,
        chain_side_continuation_id = job.chain_side_continuation_id,
        chain_side_payload_count = job.chain_side_payload_count,
        nested_depth = job.nested_depth,
        nested_root_slot_id = job.nested_root_slot_id,
        nested_parent_slot_id = job.nested_parent_slot_id,
        nested_parent_continuation_id = job.nested_parent_continuation_id,
        nested_continuation_id = job.nested_continuation_id,
        nested_continuation_kind = job.nested_continuation_kind,
        nested_final_payload_count = job.nested_final_payload_count,
        branch_scope = job.branch_scope,
        branch_id = job.branch_id,
        branch_parent_id = job.branch_parent_id,
        branch_kind = job.branch_kind,
        branch_index = job.branch_index,
        branch_count = job.branch_count,
        pattern_kind = job.pattern_kind,
        pattern_index = job.pattern_index,
        pattern_count = job.pattern_count,
        pattern_direction_key = job.pattern_direction_key,
        payload_modifier_kind = job.payload_modifier_kind,
        payload_detonate = job.payload_detonate,
        detonate_at_launch = job.detonate_at_launch,
        speed = job.speed,
        maxSpeed = job.maxSpeed,
        speed_plus = job.speed_plus,
        speed_plus_mode = job.speed_plus_mode,
        speed_plus_value = job.speed_plus_value,
        speed_plus_base_speed = job.speed_plus_base_speed,
        speed_plus_multiplier = job.speed_plus_multiplier,
        speed_plus_speed = job.speed_plus_speed,
        speed_plus_max_speed = job.speed_plus_max_speed,
        speed_plus_field = job.speed_plus_field,
        speed_plus_capped = job.speed_plus_capped,
        size_plus = job.size_plus,
        size_plus_mode = job.size_plus_mode,
        size_plus_value = job.size_plus_value,
        size_plus_multiplier = job.size_plus_multiplier,
        size_plus_field = job.size_plus_field,
        size_plus_capped = job.size_plus_capped,
        size_plus_base_area = job.size_plus_base_area,
        size_plus_area = job.size_plus_area,
        forceVec = job.forceVec,
        homing = job.homing,
        homing_mode = job.homing_mode,
        homing_force = job.homing_force,
        homing_field = job.homing_field,
        homing_target_id = job.homing_target_id,
        homing_target_object = job.homing_target_object,
        homing_target_position = job.homing_target_position,
        homing_target_provider = job.homing_target_provider,
        homing_target_kind = job.homing_target_kind,
        homing_targeting_mode = job.homing_targeting_mode,
        homing_payload_targeting = job.homing_payload_targeting,
        homing_initial_steer_delay_seconds = job.homing_initial_steer_delay_seconds,
        homing_initial_retarget_delay_seconds = job.homing_initial_retarget_delay_seconds,
        homing_payload_search_origin = job.homing_payload_search_origin,
        homing_payload_search_radius = job.homing_payload_search_radius,
        homing_candidate_count = job.homing_candidate_count,
        homing_actor_candidate_count = job.homing_actor_candidate_count,
        homing_creature_candidate_count = job.homing_creature_candidate_count,
        homing_npc_candidate_count = job.homing_npc_candidate_count,
        homing_force_key = job.homing_force_key,
        homing_direction_key = job.homing_direction_key,
    }
end

local function buildJob(plan, ir, continuation_plan, event, opts, planned, index, count)
    local payload_entry = entryBySlot(ir, planned and (planned.payload_slot_id or planned.slot_id))
    local source_entry = entryBySlot(ir, continuation_plan and continuation_plan.source_slot_id)
    local continuation = continuationById(ir, continuation_plan and continuation_plan.continuation_id)
        or continuationBySourceKind(ir, continuation_plan and continuation_plan.source_slot_id, continuation_plan and continuation_plan.continuation_kind)
    local cast_id = eventCastId(event, opts)
    local branch_kind = planned and planned.branch_kind or "continuation_payload"
    local scope = branchScope(continuation_plan, event)
    local branch_index = planned and planned.branch_index or index
    local planned_slot_id = planned and (planned.payload_slot_id or planned.slot_id)
    local branch_id = branchId(scope, branch_kind, branch_index, planned_slot_id)
    local planned_depth = tonumber(planned and planned.depth) or tonumber(payload_entry and payload_entry.payload_depth) or 0
    local nested_depth = tonumber(planned and planned.nested_depth)
        or planned_depth
        or tonumber(event and event.nested_depth)
    local source_prefix_opcode = sourcePrefix(continuation_plan, event, source_entry)
    local source_postfix_opcode = sourcePostfix(continuation_plan, event, source_entry)
    local chain_side_kind = continuation_plan and continuation_plan.chain_side_continuation_kind or nil
    local is_chain_payload_hop = planned and planned.job_kind == "chain_payload_hop"
    if is_chain_payload_hop and (chain_side_kind == "Trigger" or chain_side_kind == "Timer") then
        source_postfix_opcode = chain_side_kind
    end
    local pattern = patternInfo(continuation_plan, planned, payload_entry, index, count)
    local bounce = nil
    if source_prefix_opcode == "Bounce"
        or continuation_plan.bounce_mode ~= nil
        or (event and event.event_kind == "bounce") then
        bounce = bounceInfo(source_entry, continuation_plan, event)
    end
    local pierce = nil
    if source_prefix_opcode == "Pierce"
        or continuation_plan.pierce_mode ~= nil
        or (event and event.event_kind == "pierce") then
        pierce = pierceInfo(source_entry, continuation_plan, event)
    end
    local chain = nil
    if (planned and (planned.job_kind == "chain_handoff" or planned.job_kind == "chain_payload_hop"))
        or continuation_plan.has_chain_payload == true then
        chain = chainInfo(continuation_plan, event, payload_entry)
    end
    local timer_seconds, timer_ticks = nil, nil
    if (event and event.event_kind == "timer_matured") or source_postfix_opcode == "Timer" then
        timer_seconds, timer_ticks = timerDelayFromContinuation(continuation, event)
    end

    local job = {
        kind = runtimeKind(planned and planned.job_kind, event and event.event_kind),
        recipe_id = (continuation_plan and continuation_plan.recipe_id) or (plan and plan.recipe_id),
        slot_id = payload_entry and payload_entry.slot_id or planned and planned.slot_id,
        helper_engine_id = helperId(payload_entry) or planned and planned.helper_engine_id,
        idempotency_key = table.concat({
            "dry",
            tostring(event and event.event_kind or continuation_plan.event_kind or "event"),
            tostring(continuation_plan.continuation_id or "continuation"),
            tostring(planned and planned.payload_slot_id or planned and planned.slot_id or "slot"),
            tostring(nested_depth or ""),
            tostring(branch_id or ""),
            tostring(event and event.current_hit_target_id or event and event.actor_id or ""),
            tostring(event and event.pierce_count or ""),
            tostring(index),
        }, ":"),
        source_job_id = event and event.source_job_id or nil,
        parent_job_id = firstNonNil(event and event.parent_job_id, event and event.source_job_id),
        depth = planned_depth,
        nested_depth = nested_depth,
        nested_root_slot_id = firstNonNil(
            event and event.nested_root_slot_id,
            planned and planned.nested_root_slot_id,
            continuation_plan and continuation_plan.nested_root_slot_id,
            continuation_plan and continuation_plan.source_slot_id
        ),
        nested_parent_slot_id = firstNonNil(
            event and event.nested_parent_slot_id,
            planned and planned.nested_parent_slot_id,
            continuation_plan and continuation_plan.nested_parent_slot_id,
            continuation_plan and continuation_plan.source_slot_id
        ),
        nested_parent_continuation_id = firstNonNil(
            event and event.nested_parent_continuation_id,
            planned and planned.nested_parent_continuation_id,
            continuation_plan and continuation_plan.nested_parent_continuation_id
        ),
        nested_continuation_id = firstNonNil(
            event and event.nested_continuation_id,
            planned and planned.nested_continuation_id,
            continuation_plan and continuation_plan.nested_continuation_id
        ),
        nested_continuation_kind = firstNonNil(
            event and event.nested_continuation_kind,
            planned and planned.nested_continuation_kind,
            continuation_plan and continuation_plan.nested_continuation_kind
        ),
        nested_final_payload_count = firstNonNil(
            planned and planned.nested_final_payload_count,
            continuation_plan and continuation_plan.nested_final_payload_count
        ),
        cast_id = cast_id,
        emission_index = payload_entry and payload_entry.emission_index or nil,
        group_index = payload_entry and payload_entry.group_index or nil,
        fanout_count = count,
        max_live_launches_per_tick = tonumber(opts and opts.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        chaos_budget_profile = opts and opts.chaos_budget_profile or nil,
        source_slot_id = continuation_plan.source_slot_id,
        source_helper_engine_id = continuation_plan.source_helper_engine_id,
        source_prefix_opcode = source_prefix_opcode,
        source_postfix_opcode = source_postfix_opcode,
        payload_slot_id = planned and (planned.payload_slot_id or planned.slot_id) or nil,
        branch_scope = scope,
        branch_id = branch_id,
        branch_parent_id = branchParentId(continuation_plan, event),
        branch_kind = branch_kind,
        branch_index = branch_index,
        branch_count = planned and planned.branch_count or count,
        pattern_kind = pattern.pattern_kind,
        pattern_index = pattern.pattern_index,
        pattern_count = pattern.pattern_count,
        pattern_direction_key = pattern.pattern_direction_key,
        actor = firstNonNil(event and event.actor, event and event.sender, opts and opts.actor, opts and opts.sender),
        start_pos = firstNonNil(event and event.start_pos, event and event.origin, event and event.hit_pos, opts and opts.start_pos),
        direction = firstNonNil(event and event.direction, opts and opts.direction),
        hit_pos = firstNonNil(event and event.hit_pos, event and event.hitPos),
        hit_object = firstNonNil(event and event.hit_object, opts and opts.hit_object),
        current_hit_target_id = firstNonNil(event and event.current_hit_target_id, event and event.actor_id, event and event.hit_object),
        excludeTarget = firstNonNil(event and event.excludeTarget, event and event.exclude_target),
        homing_target_id = firstNonNil(event and event.homing_target_id, opts and opts.homing_target_id),
        homing_target_object = firstNonNil(event and event.homing_target_object, opts and opts.homing_target_object),
        homing_target_position = firstNonNil(event and event.homing_target_position, opts and opts.homing_target_position),
    }

    if source_postfix_opcode == "Trigger" then
        job.trigger_source_slot_id = is_chain_payload_hop and job.payload_slot_id or continuation_plan.source_slot_id
        job.trigger_payload_slot_id = job.payload_slot_id
        job.has_trigger_payload = is_chain_payload_hop or nil
    elseif source_postfix_opcode == "Timer" or (event and event.event_kind == "timer_matured") then
        job.timer_source_slot_id = is_chain_payload_hop and job.payload_slot_id or continuation_plan.source_slot_id
        job.timer_payload_slot_id = job.payload_slot_id
        job.timer_id = firstNonNil(event and event.timer_id, "timer:" .. tostring(cast_id) .. ":" .. tostring(continuation_plan.source_slot_id))
        job.timer_delay_ticks = timer_ticks
        job.timer_delay_seconds = timer_seconds
        job.timer_due_tick = event and event.timer_due_tick or nil
        job.timer_due_seconds = event and event.timer_due_seconds or nil
        job.has_timer_payload = is_chain_payload_hop or nil
    end

    if bounce then
        job.bounce_runtime = true
        job.bounce_role = planned and planned.job_kind == "chain_handoff" and "trigger_chain_payload"
            or "trigger_payload_launch"
        job.bounce_id = bounce.bounce_id
        job.bounce_index = bounce.bounce_index
        job.bounce_max = bounce.bounce_max
        job.bounce_power = bounce.bounce_power
        job.bounce_manual_detonation = true
        job.bounce_final = bounce.bounce_final
        job.bounce_trigger_payload_slot_id = job.payload_slot_id
    end

    if pierce then
        job.pierce_runtime = true
        job.pierce_role = planned and planned.job_kind == "chain_handoff" and "trigger_chain_payload"
            or "trigger_payload_launch"
        job.pierce_id = pierce.pierce_id
        job.pierce_count = pierce.pierce_count
        job.pierce_limit = pierce.pierce_limit
        job.pierce_trigger_payload_slot_id = job.payload_slot_id
        job.trigger_route = "pierce"
        job.current_hit_target_id = firstNonNil(event and event.current_hit_target_id, event and event.actor_id)
        job.excludeTarget = firstNonNil(event and event.excludeTarget, event and event.exclude_target)
        job.start_pos = firstNonNil(event and event.start_pos, event and event.origin)
        job.direction = event and event.direction or nil
    end

    if chain then
        local chain_hop_index = chain.chain_hop_index
        if planned and planned.job_kind == "chain_payload_hop" then
            chain_hop_index = chain_hop_index + 1
        end
        job.chain_runtime = true
        job.chain_role = planned and planned.job_kind == "chain_handoff" and "source" or "payload"
        job.chain_id = chain.chain_id
        job.chain_hop_index = chain_hop_index
        job.chain_max_hops = chain.chain_max_hops
        job.chain_targeting_mode = chain.chain_targeting_mode
        job.chain_continuation_group_id = firstNonNil(event and event.chain_continuation_group_id, scope)
        job.chain_side_continuation_kind = chain_side_kind
        job.chain_side_continuation_id = continuation_plan and continuation_plan.chain_side_continuation_id or nil
        job.chain_side_payload_count = continuation_plan and continuation_plan.chain_side_payload_count or nil
    end

    job.payload = payloadMetadata(job)
    local policy = launch_modifier_policy.applyToJob(plan, ir, payload_entry, job, event, payloadModifierOptions(opts))
    if policy.ok ~= true then
        job.payload_modifier_rejection_reason = policy.rejection_reason
        if type(job.payload) == "table" then
            job.payload.payload_modifier_rejection_reason = policy.rejection_reason
        end
    else
        job.payload = payloadMetadata(job)
    end
    local homing = homing_launch_policy.applyToJob(plan, ir, payload_entry, job, event, opts)
    if homing.ok ~= true then
        job.payload_homing_rejection_reason = homing.rejection_reason
        if type(job.payload) == "table" then
            job.payload.payload_homing_rejection_reason = homing.rejection_reason
        end
    else
        job.payload = payloadMetadata(job)
    end
    return job
end

local function sourceEventMetadata(plan, ir, continuation_plan, event, opts)
    local source_entry = entryBySlot(ir, continuation_plan and continuation_plan.source_slot_id)
    local source_prefix_opcode = sourcePrefix(continuation_plan, event, source_entry)
    if source_prefix_opcode ~= "Bounce" and source_prefix_opcode ~= "Pierce" then
        return nil
    end
    if source_prefix_opcode == "Pierce" then
        local pierce = pierceInfo(source_entry, continuation_plan, event)
        return {
            kind = "pierce_source_event",
            recipe_id = (continuation_plan and continuation_plan.recipe_id) or (plan and plan.recipe_id),
            event_kind = event and event.event_kind,
            cast_id = eventCastId(event, opts),
            source_slot_id = continuation_plan.source_slot_id,
            source_helper_engine_id = continuation_plan.source_helper_engine_id,
            source_prefix_opcode = "Pierce",
            source_postfix_opcode = sourcePostfix(continuation_plan, event, source_entry),
            pierce_runtime = true,
            pierce_role = "source",
            pierce_id = pierce.pierce_id,
            pierce_count = pierce.pierce_count,
            pierce_limit = pierce.pierce_limit,
        }
    end
    local bounce = bounceInfo(source_entry, continuation_plan, event)
    return {
        kind = "bounce_source_event",
        recipe_id = (continuation_plan and continuation_plan.recipe_id) or (plan and plan.recipe_id),
        event_kind = event and event.event_kind,
        cast_id = eventCastId(event, opts),
        source_slot_id = continuation_plan.source_slot_id,
        source_helper_engine_id = continuation_plan.source_helper_engine_id,
        source_prefix_opcode = "Bounce",
        source_postfix_opcode = sourcePostfix(continuation_plan, event, source_entry),
        bounce_runtime = true,
        bounce_role = "source",
        bounce_id = bounce.bounce_id,
        bounce_index = bounce.bounce_index,
        bounce_max = bounce.bounce_max,
        bounce_power = bounce.bounce_power,
        bounce_manual_detonation = false,
        bounce_final = bounce.bounce_final,
    }
end

function runtime_job_planner.planJobs(plan, ir, continuation_plan, event_context, opts)
    local options = opts or {}
    local event = event_context or {}
    if type(ir) ~= "table" or ir.ok ~= true then
        return reject(plan, ir, continuation_plan, event, "runtime_ir_required")
    end
    if type(continuation_plan) ~= "table" then
        return reject(plan, ir, continuation_plan, event, "continuation_plan_required")
    end
    if continuation_plan.ok ~= true then
        return reject(plan, ir, continuation_plan, event, continuation_plan.rejection_reason or "continuation_plan_rejected")
    end

    local planned_jobs = {}
    local source_event = sourceEventMetadata(plan, ir, continuation_plan, event, options)
    local source_entry = entryBySlot(ir, continuation_plan.source_slot_id)
    local count = #(continuation_plan.planned_jobs or {})
    for index, planned in ipairs(continuation_plan.planned_jobs or {}) do
        planned_jobs[index] = buildJob(plan, ir, continuation_plan, event, options, planned, index, count)
    end

    return {
        ok = true,
        version = runtime_job_planner.VERSION,
        recipe_id = continuation_plan.recipe_id or ir.recipe_id or plan.recipe_id,
        event_kind = event.event_kind or continuation_plan.event_kind,
        source_slot_id = continuation_plan.source_slot_id,
        source_helper_engine_id = continuation_plan.source_helper_engine_id or helperId(source_entry),
        continuation_id = continuation_plan.continuation_id,
        planned_job_count = #planned_jobs,
        planned_jobs = planned_jobs,
        source_event = source_event,
        rejection_reason = nil,
    }
end

return runtime_job_planner
