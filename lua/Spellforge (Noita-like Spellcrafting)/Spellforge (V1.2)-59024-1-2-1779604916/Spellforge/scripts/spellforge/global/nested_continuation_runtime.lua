local dev = require("scripts.spellforge.shared.dev")
local limits = require("scripts.spellforge.shared.limits")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")

local nested_continuation_runtime = {}

local TIMER_TICKS_PER_SECOND = 2
local DEFAULT_TIMER_SECONDS = 1.0
local MAX_TIMER_SECONDS = 5.0

local function slotById(plan, slot_id)
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.slot_id == slot_id then
            return slot
        end
    end
    return nil
end

local function helperBySlotId(plan, slot_id)
    for _, helper in ipairs(plan and plan.helper_records or {}) do
        if helper and helper.slot_id == slot_id then
            return helper
        end
    end
    return nil
end

local function firstPostfix(slot)
    for _, op in ipairs(slot and slot.postfix_ops or {}) do
        if op and (op.opcode == "Trigger" or op.opcode == "Timer") then
            return op.opcode, op
        end
    end
    return nil, nil
end

local function slotDepth(plan, slot)
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
        current = slotById(plan, current.parent_slot_id)
    end
    return depth
end

local function timerDelayFromOp(op)
    local raw_seconds = op and op.params and op.params.seconds
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

local function payloadOptions(kind, options)
    local opts = options or {}
    return {
        source_opcode = kind,
        allow_payload_multicast = opts.allow_payload_multicast == true or dev.livePayloadMulticastEnabled(),
        allow_payload_pattern = opts.allow_payload_pattern == true or dev.livePayloadPatternEnabled(),
        allow_payload_launch_modifiers = true,
        allow_nested_trigger_timer = opts.allow_nested_trigger_timer == true or dev.liveNestedTriggerTimerEnabled(),
        allow_nested_final_fanout = opts.allow_nested_final_fanout == true or dev.liveNestedFinalFanoutEnabled(),
        allow_nested_payload_modifiers = true,
        allow_payload_detonate = opts.allow_payload_detonate == true,
        allow_payload_homing = opts.allow_payload_homing == true or dev.liveHomingEnabled(),
        allow_nested_payload_homing = true,
        allow_homing = opts.allow_homing == true or dev.liveHomingEnabled(),
        force_homing_enabled = opts.force_homing_enabled,
        force_homing_disabled = opts.force_homing_disabled,
        homing_enabled = opts.homing_enabled == true or dev.liveHomingEnabled(),
        force_speed_plus_enabled = opts.force_speed_plus_enabled,
        force_speed_plus_disabled = opts.force_speed_plus_disabled,
        speed_plus_enabled = opts.speed_plus_enabled == true or dev.liveSpeedPlusEnabled(),
        force_size_plus_enabled = opts.force_size_plus_enabled,
        force_size_plus_disabled = opts.force_size_plus_disabled,
        size_plus_enabled = opts.size_plus_enabled == true or dev.liveSizePlusEnabled(),
        max_depth = opts.max_depth or opts.max_nested_payload_depth or limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH,
        max_jobs = opts.max_jobs or opts.max_nested_payload_jobs or limits.MAX_NESTED_PAYLOAD_JOBS,
        max_fanout = opts.max_fanout or opts.max_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT,
        max_projectiles = opts.max_projectiles or limits.MAX_PROJECTILES_PER_CAST,
    }
end

function nested_continuation_runtime.bindingForLaunchedPayload(plan, payload, context, opts)
    local options = opts or {}
    local source_slot = slotById(plan, payload and payload.slot_id)
    if not source_slot then
        return nil, "nested_source_slot_missing"
    end
    local helper = helperBySlotId(plan, source_slot.slot_id)
    if not helper or type(helper.engine_id) ~= "string" or helper.engine_id == "" then
        return nil, "nested_source_helper_missing"
    end

    local kind, postfix_op = firstPostfix(source_slot)
    local helper_kind = firstPostfix(helper)
    if kind == nil and helper_kind ~= nil then
        kind = helper_kind
    elseif helper_kind ~= nil and helper_kind ~= kind then
        return nil, "nested_recursion_unsupported"
    end
    if kind ~= "Trigger" and kind ~= "Timer" then
        return nil, "not_nested_continuation_source"
    end

    local source_depth = tonumber(payload and payload.payload_depth) or slotDepth(plan, source_slot)
    local max_depth = tonumber(options.max_depth or options.max_nested_payload_depth)
        or tonumber(limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH)
        or 3
    if source_depth >= max_depth then
        return nil, "nested_depth_exceeded"
    end

    local payload_result = payload_multicast.resolvePayloadHelpersForSource(plan, source_slot, payloadOptions(kind, options))
    if payload_result.ok ~= true then
        return nil, payload_result.rejection_reason or "nested_payload_resolution_failed"
    end

    local timer_seconds, timer_delay_ticks = nil, nil
    if kind == "Timer" then
        timer_seconds, timer_delay_ticks = timerDelayFromOp(postfix_op)
    end

    local binding = {
        recipe_id = plan.recipe_id,
        plan = plan,
        cast_id = context.cast_id,
        source_slot_id = source_slot.slot_id,
        source_helper_engine_id = helper.engine_id,
        payload_slot_id = payload_result.payload_slot_id,
        payload_helper_engine_id = payload_result.payload_helper_engine_id,
        payloads = payload_result.payload_slots,
        payload_slot_ids = payload_result.payload_slot_ids,
        payload_helper_engine_ids = payload_result.payload_helper_engine_ids,
        payload_count = payload_result.payload_count,
        payload_group_key = payload_result.payload_group_key,
        payload_multicast = payload_result.is_payload_multicast == true,
        payload_pattern = payload_result.is_payload_pattern == true,
        payload_pattern_kind = payload_result.pattern_kind,
        payload_pattern_op = payload_result.pattern_op,
        has_payload_homing = payload_result.has_payload_homing == true,
        has_payload_modifier = payload_result.has_payload_modifier == true,
        payload_modifier_kinds = payload_result.payload_modifier_kinds,
        max_payload_fanout = tonumber(options.max_payload_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT,
        max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST,
        max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
        max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
        actor = context.actor,
        hit_object = context.hit_object,
        start_pos = context.start_pos,
        direction = context.direction,
        source_job_id = context.source_job_id,
        source_projectile_id = context.source_projectile_id,
        source_user_data = context.source_user_data,
        source_depth = source_depth,
        root_source_slot_id = context.root_source_slot_id or payload.root_source_slot_id,
        current_source_slot_id = source_slot.slot_id,
        parent_slot_id = source_slot.parent_slot_id,
        nested_stage_kind = "nested_" .. string.lower(kind),
        nested_stage_index = source_depth,
        allow_nested_trigger_timer = true,
        allow_nested_final_fanout = true,
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
        timer_seconds = timer_seconds,
        timer_delay_ticks = timer_delay_ticks,
    }

    if kind == "Timer" then
        binding.resolution = {
            timer_start_pos = context.start_pos,
            timer_direction = context.direction,
            resolution_pos = context.start_pos,
            resolution_kind = context.resolution_kind,
            resolution_hit_object = context.hit_object,
        }
    end

    return binding, nil, kind
end

return nested_continuation_runtime
