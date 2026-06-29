---@omw-context global
local dev = require("scripts.spellforge.shared.dev")
local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.live_trigger")
local helper_records = require("scripts.spellforge.global.helper_records")
local homing_launch_policy = require("scripts.spellforge.global.homing_launch_policy")
local ir_runtime_adapter = require("scripts.spellforge.global.ir_runtime_adapter")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local nested_continuation_runtime = require("scripts.spellforge.global.nested_continuation_runtime")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local live_timer = require("scripts.spellforge.global.live_timer")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")
local payload_pattern = require("scripts.spellforge.global.payload_pattern")
local runtime_hits = require("scripts.spellforge.global.runtime_hits")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local live_trigger = {}

local MAX_BINDINGS = 128
local MAX_DUPLICATE_KEYS = 256

local bindings_by_cast_source = {}
local bindings_by_latest_source = {}
local binding_order = {}
local duplicate_keys = {}
local duplicate_order = {}

local function recipeSlotKey(recipe_id, slot_id)
    return string.format("%s::%s", tostring(recipe_id), tostring(slot_id))
end

local function castSourceKey(recipe_id, slot_id, cast_id)
    return string.format("%s::%s::%s", tostring(recipe_id), tostring(slot_id), tostring(cast_id))
end

local function appendBounded(order, key, max_count, on_evict)
    order[#order + 1] = key
    while #order > max_count do
        local evicted = table.remove(order, 1)
        if on_evict then
            on_evict(evicted)
        end
    end
end

local function hasOps(ops)
    return type(ops) == "table" and #ops > 0
end

local function sourcePrefixAllowed(ops, options)
    if not hasOps(ops) then
        return true
    end
    if options and options.allow_source_homing == true and #ops == 1 and ops[1] and ops[1].opcode == "Homing" then
        return true
    end
    if options and options.allow_source_launch_modifiers == true then
        for _, op in ipairs(ops or {}) do
            local opcode = op and op.opcode
            if opcode ~= "Speed+" and opcode ~= "Size+" then
                return false
            end
        end
        return true
    end
    return false
end

local function sourceFanoutPrefixAllowed(ops)
    local saw_multicast = false
    local pattern_kind = nil
    for _, op in ipairs(ops or {}) do
        local opcode = op and op.opcode
        if opcode == "Multicast" then
            saw_multicast = true
        elseif opcode == "Spread" or opcode == "Burst" then
            if pattern_kind ~= nil and pattern_kind ~= opcode then
                return false
            end
            pattern_kind = opcode
        else
            return false
        end
    end
    return pattern_kind == nil or saw_multicast == true
end

local function hasPayloadBindings(value)
    return type(value) == "table" and #value > 0
end

local function firstEffectId(helper)
    local first = helper and helper.effects and helper.effects[1] or nil
    return first and first.id or nil
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

local function slotHasOneTriggerBinding(slot)
    local bindings = slot and slot.payload_bindings
    if type(bindings) ~= "table" or #bindings ~= 1 then
        return false
    end
    return bindings[1] and bindings[1].source_opcode == "Trigger"
end

local function postfixIsOnlyTrigger(slot)
    local ops = slot and slot.postfix_ops
    return type(ops) == "table" and #ops == 1 and ops[1].opcode == "Trigger"
end

local function rejectSelect(reason, counter_name)
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return nil, reason
end

local function buildTriggerPlanForSource(plan, source_slot, source_helper, options)
    local payload_result = payload_multicast.resolvePayloadHelpersForSource(plan, source_slot, {
        source_opcode = "Trigger",
        allow_payload_multicast = options.allow_payload_multicast == true,
        allow_payload_pattern = options.allow_payload_pattern == true,
        allow_payload_launch_modifiers = options.allow_payload_launch_modifiers == true,
        allow_payload_detonate = options.allow_payload_detonate == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = options.speed_plus_enabled == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = options.size_plus_enabled == true,
        allow_payload_homing = options.allow_payload_homing == true,
        allow_nested_trigger_timer = options.allow_nested_trigger_timer == true,
        allow_nested_final_fanout = options.allow_nested_final_fanout == true,
        allow_nested_payload_modifiers = options.allow_nested_payload_modifiers == true,
        allow_nested_payload_homing = options.allow_nested_payload_homing == true,
        allow_homing = options.allow_homing == true,
        force_homing_enabled = options.force_homing_enabled,
        force_homing_disabled = options.force_homing_disabled,
        homing_enabled = options.homing_enabled == true,
        max_depth = options.max_depth,
        max_jobs = options.max_jobs,
        max_fanout = options.max_fanout,
        max_projectiles = options.max_projectiles,
        allow_unrelated_payloads = options.allow_unrelated_payloads == true,
    })
    if payload_result.detected_payload_multicast then
        runtime_stats.inc("payload_multicast_attempts")
    end
    if payload_result.detected_payload_pattern then
        runtime_stats.inc("payload_pattern_attempts")
    end
    if not payload_result.ok then
        local reason = payload_result.rejection_reason or "trigger_payload_resolution_failed"
        if payload_result.detected_payload_multicast then
            runtime_stats.inc("payload_multicast_rejected")
            if reason == "payload_multicast_disabled" then
                runtime_stats.inc("payload_multicast_disabled_reject")
            elseif reason == "payload_multicast_fanout_cap_exceeded"
                or reason == "payload_multicast_projectile_cap_exceeded"
                or reason == "payload_multicast_job_cap_exceeded" then
                runtime_stats.inc("payload_multicast_cap_reject")
            elseif reason == "payload_multicast_chain_deferred" then
                runtime_stats.inc("payload_multicast_chain_reject")
            elseif reason == "nested_payload_runtime_deferred"
                or reason == "payload_pattern_runtime_deferred"
                or reason == "payload_modifier_nested_deferred"
                or reason == "payload_modifier_combo_deferred"
                or reason == "payload_speed_plus_disabled"
                or reason == "payload_size_plus_disabled" then
                runtime_stats.inc("payload_multicast_nested_reject")
            end
        end
        if payload_result.detected_payload_pattern then
            runtime_stats.inc("payload_pattern_rejected")
            if reason == "payload_pattern_disabled" then
                runtime_stats.inc("payload_pattern_disabled_reject")
            elseif reason == "payload_multicast_fanout_cap_exceeded"
                or reason == "payload_multicast_projectile_cap_exceeded"
                or reason == "payload_multicast_job_cap_exceeded"
                or reason == "payload_pattern_fanout_missing" then
                runtime_stats.inc("payload_pattern_cap_reject")
            elseif reason == "payload_multicast_chain_deferred" then
                runtime_stats.inc("payload_pattern_chain_reject")
            else
                runtime_stats.inc("payload_pattern_nested_reject")
            end
        end
        local counter = reason == "payload_missing" and "live_trigger_payload_missing" or nil
        return rejectSelect(reason, counter)
    end
    if payload_result.is_payload_multicast then
        runtime_stats.inc("payload_multicast_qualified")
    end
    if payload_result.is_payload_pattern then
        runtime_stats.inc("payload_pattern_qualified")
    end

    return {
        source = {
            slot = source_slot,
            helper = source_helper,
        },
        payload = {
            slot = payload_result.payload_slots[1].slot,
            helper = payload_result.payload_slots[1].helper,
        },
        source_slot_id = source_slot.slot_id,
        source_helper_engine_id = source_helper.engine_id,
        payload_slot_id = payload_result.payload_slot_id,
        payload_helper_engine_id = payload_result.payload_helper_engine_id,
        payload_effect_id = payload_result.payload_effect_id,
        payloads = payload_result.payload_slots,
        payload_slot_ids = payload_result.payload_slot_ids,
        payload_helper_engine_ids = payload_result.payload_helper_engine_ids,
        payload_effect_ids = payload_result.payload_effect_ids,
        payload_count = payload_result.payload_count,
        payload_group_key = payload_result.payload_group_key,
        payload_multicast = payload_result.is_payload_multicast == true,
        payload_pattern = payload_result.is_payload_pattern == true,
        payload_pattern_kind = payload_result.pattern_kind,
        payload_pattern_op = payload_result.pattern_op,
        payload_modifier_kinds = payload_result.payload_modifier_kinds,
        has_payload_modifier = payload_result.has_payload_modifier == true,
        has_payload_homing = payload_result.has_payload_homing == true,
        payload_multicast_fanout_count = payload_result.fanout_count,
        max_payload_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT,
        max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST,
        max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
        max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        chaos_budget_profile = options.chaos_budget_profile,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
    }, nil
end

function live_trigger.selectV0Plan(plan, opts)
    local options = opts or {}
    if type(plan) ~= "table" then
        return rejectSelect("missing_plan")
    end
    local bounds = plan.bounds or {}
    local requested_group_index = tonumber(options.source_group_index)
    local requested_slot_id = type(options.source_slot_id) == "string" and options.source_slot_id or nil
    local allow_multi_root = options.allow_multi_root == true
        and (requested_group_index ~= nil or requested_slot_id ~= nil)
    if not allow_multi_root and bounds.has_timer and options.allow_nested_trigger_timer ~= true then
        return rejectSelect("nested_payload_runtime_deferred", "payload_multicast_nested_reject")
    end
    if bounds.has_chain then
        return rejectSelect("payload_multicast_chain_deferred", "payload_multicast_chain_reject")
    end

    if not allow_multi_root then
        if bounds.group_count ~= 1 then
            return rejectSelect(tonumber(bounds.group_count) and tonumber(bounds.group_count) > 1
                and "multiple_source_groups_unsupported"
                or "not_single_group")
        end
        if tonumber(bounds.static_emission_count) ~= 1 then
            return rejectSelect("source_fanout_trigger_unsupported")
        end
    end

    local group = plan.groups and plan.groups[requested_group_index or 1] or nil
    if type(group) ~= "table" then
        return rejectSelect("missing_group")
    end
    if allow_multi_root and tonumber(group.emission_count_static) ~= 1 then
        return rejectSelect("source_fanout_trigger_unsupported")
    end
    if not sourcePrefixAllowed(group.prefix_ops, options) then
        return rejectSelect("source_has_prefix_ops")
    end
    if not postfixIsOnlyTrigger(group) then
        return rejectSelect("source_not_trigger")
    end
    if not group.payload or type(group.payload.effects) ~= "table" or #group.payload.effects == 0 then
        return rejectSelect("missing_trigger_payload", "live_trigger_payload_missing")
    end

    local slots = plan.emission_slots or {}
    local helpers = plan.helper_records or {}

    local source_slot = nil
    for _, slot in ipairs(slots) do
        if slot.kind == "primary_emission" then
            local matches_requested = not allow_multi_root
                or (requested_slot_id ~= nil and slot.slot_id == requested_slot_id)
                or (requested_slot_id == nil and requested_group_index ~= nil and tonumber(slot.group_index) == requested_group_index)
            if not matches_requested then
                -- Other root sources are handled by the multi-root dispatcher.
            elseif source_slot then
                return rejectSelect("multiple_trigger_sources")
            else
                source_slot = slot
            end
        elseif slot.kind == "payload_emission" then
            -- Payload slots are validated as a direct Trigger payload group below.
        else
            return rejectSelect("unknown_slot_kind")
        end
    end

    if not source_slot then
        return rejectSelect("missing_trigger_source_slot")
    end
    if source_slot.parent_slot_id ~= nil or source_slot.source_postfix_opcode ~= nil then
        return rejectSelect("source_slot_not_primary")
    end
    if source_slot.trigger_source_slot_id ~= nil or source_slot.timer_source_slot_id ~= nil then
        return rejectSelect("source_slot_has_payload_source")
    end
    if not sourcePrefixAllowed(source_slot.prefix_ops, options) then
        return rejectSelect("source_slot_has_prefix_ops")
    end
    if not postfixIsOnlyTrigger(source_slot) then
        return rejectSelect("source_slot_not_trigger")
    end
    if not slotHasOneTriggerBinding(source_slot) then
        return rejectSelect("source_trigger_binding_missing", "live_trigger_payload_missing")
    end

    local helpers_by_slot = helperBySlotId(helpers)
    local source_helper = helpers_by_slot[source_slot.slot_id]
    if not source_helper or type(source_helper.engine_id) ~= "string" or source_helper.engine_id == "" then
        return rejectSelect("source_helper_missing")
    end
    if source_helper.parent_slot_id ~= nil or source_helper.source_postfix_opcode ~= nil then
        return rejectSelect("source_helper_not_primary")
    end
    if not slotHasOneTriggerBinding(source_helper) then
        return rejectSelect("source_helper_trigger_binding_missing", "live_trigger_payload_missing")
    end

    return buildTriggerPlanForSource(plan, source_slot, source_helper, options)
end

function live_trigger.selectV0PlansForGroup(plan, opts)
    local options = opts or {}
    if type(plan) ~= "table" then
        return rejectSelect("missing_plan")
    end
    local bounds = plan.bounds or {}
    local requested_group_index = tonumber(options.source_group_index)
    local requested_slot_id = type(options.source_slot_id) == "string" and options.source_slot_id or nil
    local allow_multi_root = options.allow_multi_root == true
        and (requested_group_index ~= nil or requested_slot_id ~= nil)
    if not allow_multi_root and bounds.has_timer and options.allow_nested_trigger_timer ~= true then
        return rejectSelect("nested_payload_runtime_deferred", "payload_multicast_nested_reject")
    end
    if bounds.has_chain then
        return rejectSelect("payload_multicast_chain_deferred", "payload_multicast_chain_reject")
    end

    local group = plan.groups and plan.groups[requested_group_index or 1] or nil
    if type(group) ~= "table" then
        return rejectSelect("missing_group")
    end
    if not sourceFanoutPrefixAllowed(group.prefix_ops) then
        return rejectSelect("source_has_prefix_ops")
    end
    if not postfixIsOnlyTrigger(group) then
        return rejectSelect("source_not_trigger")
    end
    if not group.payload or type(group.payload.effects) ~= "table" or #group.payload.effects == 0 then
        return rejectSelect("missing_trigger_payload", "live_trigger_payload_missing")
    end

    local slots = plan.emission_slots or {}
    local helpers_by_slot = helperBySlotId(plan.helper_records or {})
    local plans = {}

    for _, slot in ipairs(slots) do
        if slot.kind == "primary_emission" then
            local matches_requested = requested_slot_id ~= nil and slot.slot_id == requested_slot_id
                or requested_slot_id == nil and requested_group_index ~= nil and tonumber(slot.group_index) == requested_group_index
                or not allow_multi_root and requested_slot_id == nil and requested_group_index == nil
            if matches_requested then
                if slot.parent_slot_id ~= nil or slot.source_postfix_opcode ~= nil then
                    return rejectSelect("source_slot_not_primary")
                end
                if slot.trigger_source_slot_id ~= nil or slot.timer_source_slot_id ~= nil then
                    return rejectSelect("source_slot_has_payload_source")
                end
                if not sourceFanoutPrefixAllowed(slot.prefix_ops) then
                    return rejectSelect("source_slot_has_prefix_ops")
                end
                if not postfixIsOnlyTrigger(slot) then
                    return rejectSelect("source_slot_not_trigger")
                end
                if not slotHasOneTriggerBinding(slot) then
                    return rejectSelect("source_trigger_binding_missing", "live_trigger_payload_missing")
                end

                local source_helper = helpers_by_slot[slot.slot_id]
                if not source_helper or type(source_helper.engine_id) ~= "string" or source_helper.engine_id == "" then
                    return rejectSelect("source_helper_missing")
                end
                if source_helper.parent_slot_id ~= nil or source_helper.source_postfix_opcode ~= nil then
                    return rejectSelect("source_helper_not_primary")
                end
                if not slotHasOneTriggerBinding(source_helper) then
                    return rejectSelect("source_helper_trigger_binding_missing", "live_trigger_payload_missing")
                end

                local plan_for_source, plan_reason = buildTriggerPlanForSource(plan, slot, source_helper, {
                    allow_payload_multicast = options.allow_payload_multicast == true,
                    allow_payload_pattern = options.allow_payload_pattern == true,
                    allow_payload_launch_modifiers = options.allow_payload_launch_modifiers == true,
                    allow_payload_detonate = options.allow_payload_detonate == true,
                    force_speed_plus_enabled = options.force_speed_plus_enabled,
                    force_speed_plus_disabled = options.force_speed_plus_disabled,
                    speed_plus_enabled = options.speed_plus_enabled == true,
                    force_size_plus_enabled = options.force_size_plus_enabled,
                    force_size_plus_disabled = options.force_size_plus_disabled,
                    size_plus_enabled = options.size_plus_enabled == true,
                    allow_payload_homing = options.allow_payload_homing == true,
                    allow_nested_trigger_timer = options.allow_nested_trigger_timer == true,
                    allow_nested_final_fanout = options.allow_nested_final_fanout == true,
                    allow_nested_payload_modifiers = options.allow_nested_payload_modifiers == true,
                    allow_nested_payload_homing = options.allow_nested_payload_homing == true,
                    allow_homing = options.allow_homing == true,
                    force_homing_enabled = options.force_homing_enabled,
                    force_homing_disabled = options.force_homing_disabled,
                    homing_enabled = options.homing_enabled == true,
                    max_depth = options.max_depth,
                    max_jobs = options.max_jobs,
                    max_fanout = options.max_fanout,
                    max_projectiles = options.max_projectiles,
                    max_jobs_per_tick = options.max_jobs_per_tick,
                    max_live_launches_per_tick = options.max_live_launches_per_tick,
                    chaos_budget_profile = options.chaos_budget_profile,
                    allow_pending_launch_jobs = options.allow_pending_launch_jobs,
                    allow_unrelated_payloads = true,
                })
                if not plan_for_source then
                    return nil, plan_reason
                end
                plans[#plans + 1] = plan_for_source
            end
        elseif slot.kind == "payload_emission" then
            -- Payload slots are resolved per selected source slot above.
        else
            return rejectSelect("unknown_slot_kind")
        end
    end

    if #plans == 0 then
        return rejectSelect("missing_trigger_source_slot")
    end
    return plans, nil
end

function live_trigger.decorateSourceJob(job, binding)
    if type(job) ~= "table" or type(binding) ~= "table" then
        return
    end
    job.source_prefix_opcode = binding.source_prefix_opcode or job.source_prefix_opcode
    job.source_postfix_opcode = "Trigger"
    job.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    job.parent_slot_id = binding.parent_slot_id
    job.payload_depth = tonumber(binding.source_depth) or 0
    job.nested_stage_kind = binding.nested_stage_kind
    job.nested_stage_index = binding.nested_stage_index
    job.trigger_source_slot_id = binding.source_slot_id
    job.trigger_payload_slot_id = binding.payload_slot_id
    job.trigger_payload_slot_ids = binding.payload_slot_ids
    job.has_trigger_payload = true
    job.payload_multicast = binding.payload_multicast == true
    job.payload_pattern = binding.payload_pattern == true
    job.payload_pattern_kind = binding.payload_pattern_kind
    job.nested_final_fanout = binding.nested_final_fanout == true
    job.nested_final_fanout_kind = binding.nested_final_fanout_kind
    job.payload_count = tonumber(binding.payload_count) or 1
    job.payload = job.payload or {}
    job.payload.source_prefix_opcode = binding.source_prefix_opcode or job.payload.source_prefix_opcode
    job.payload.source_slot_id = binding.source_slot_id
    job.payload.source_helper_engine_id = binding.source_helper_engine_id
    job.payload.source_postfix_opcode = "Trigger"
    job.payload.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.payload.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    job.payload.parent_slot_id = binding.parent_slot_id
    job.payload.payload_depth = tonumber(binding.source_depth) or 0
    job.payload.nested_stage_kind = binding.nested_stage_kind
    job.payload.nested_stage_index = binding.nested_stage_index
    job.payload.trigger_source_slot_id = binding.source_slot_id
    job.payload.trigger_payload_slot_id = binding.payload_slot_id
    job.payload.trigger_payload_slot_ids = binding.payload_slot_ids
    job.payload.has_trigger_payload = true
    job.payload.payload_multicast = binding.payload_multicast == true
    job.payload.payload_pattern = binding.payload_pattern == true
    job.payload.payload_pattern_kind = binding.payload_pattern_kind
    job.payload.nested_final_fanout = binding.nested_final_fanout == true
    job.payload.nested_final_fanout_kind = binding.nested_final_fanout_kind
    job.payload.payload_count = tonumber(binding.payload_count) or 1
end

local function compactPayloadsFromBinding(binding)
    local payloads = {}
    if type(binding.payloads) == "table" and #binding.payloads > 0 then
        for index, payload in ipairs(binding.payloads) do
            payloads[index] = {
                slot_id = payload.slot_id,
                helper_engine_id = payload.helper_engine_id,
                effect_id = payload.effect_id,
                emission_index = payload.emission_index,
                group_index = payload.group_index,
                direction = payload.direction,
                pattern_kind = payload.pattern_kind,
                pattern_index = payload.pattern_index,
                pattern_count = payload.pattern_count,
                pattern_direction_key = payload.pattern_direction_key,
                parent_slot_id = payload.parent_slot_id,
                root_source_slot_id = payload.root_source_slot_id,
                current_source_slot_id = payload.current_source_slot_id,
                payload_depth = payload.payload_depth,
                nested_stage_kind = payload.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
                payload_modifier_kind = payload.payload_modifier_kind,
                payload_detonate = payload.payload_detonate,
                detonate_at_launch = payload.detonate_at_launch,
            }
        end
    elseif type(binding.payload_slot_id) == "string" and type(binding.payload_helper_engine_id) == "string" then
        payloads[1] = {
            slot_id = binding.payload_slot_id,
            helper_engine_id = binding.payload_helper_engine_id,
        }
    end
    return payloads
end

local function payloadSlotIds(payloads)
    local ids = {}
    for index, payload in ipairs(payloads or {}) do
        ids[index] = payload.slot_id
    end
    return ids
end

function live_trigger.registerBinding(binding)
    local input = binding or {}
    local payloads = compactPayloadsFromBinding(input)
    if type(input.recipe_id) ~= "string" or input.recipe_id == ""
        or type(input.source_slot_id) ~= "string" or input.source_slot_id == ""
        or #payloads == 0 then
        return false
    end
    input.payloads = payloads
    input.payload_slot_ids = payloadSlotIds(payloads)
    input.payload_count = #payloads
    input.runtime_generation = runtime_session.currentGeneration()

    local cast_key = castSourceKey(input.recipe_id, input.source_slot_id, input.cast_id)
    local latest_key = recipeSlotKey(input.recipe_id, input.source_slot_id)
    bindings_by_cast_source[cast_key] = input
    bindings_by_latest_source[latest_key] = input
    appendBounded(binding_order, cast_key, MAX_BINDINGS, function(evicted)
        local evicted_binding = bindings_by_cast_source[evicted]
        if evicted_binding then
            local evicted_latest_key = recipeSlotKey(evicted_binding.recipe_id, evicted_binding.source_slot_id)
            if bindings_by_latest_source[evicted_latest_key] == evicted_binding then
                bindings_by_latest_source[evicted_latest_key] = nil
            end
        end
        bindings_by_cast_source[evicted] = nil
    end)
    return true
end

local function activateNestedContinuations(binding, payloads, jobs, job_ids, context, options)
    local activated_count = 0
    for index, payload in ipairs(payloads or {}) do
        local job = jobs and jobs[index] or nil
        if job and job.launch_accepted == true then
            local nested_context = {
                cast_id = binding.cast_id,
                actor = context.actor,
                hit_object = context.hit_object,
                start_pos = job.launch_start_pos or context.start_pos,
                direction = job.launch_direction or payload.direction or context.direction,
                source_job_id = job_ids and job_ids[index] or job.job_id,
                source_projectile_id = job.projectile_id,
                source_user_data = job.launch_user_data,
                root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id,
                resolution_kind = context.resolution_kind or "trigger_hit",
            }
            local nested_binding, reason, kind = nested_continuation_runtime.bindingForLaunchedPayload(
                binding.plan,
                payload,
                nested_context,
                options
            )
            if nested_binding then
                if kind == "Trigger" then
                    if options.force_trigger_enabled ~= true and not dev.liveTriggerEnabled() then
                        return false, "live_trigger_disabled"
                    end
                    live_trigger.registerBinding(nested_binding)
                    activated_count = activated_count + 1
                elseif kind == "Timer" then
                    if options.force_timer_enabled ~= true and not dev.liveTimerEnabled() then
                        return false, "live_timer_disabled"
                    end
                    local schedule = live_timer.schedulePayload(nested_binding, {
                        duplicate_key_suffix = nested_binding.source_job_id,
                    })
                    if not schedule.ok then
                        return false, schedule.error or "nested timer schedule failed"
                    end
                    activated_count = activated_count + 1
                end
            elseif reason ~= "not_nested_continuation_source" then
                return false, reason or "nested continuation activation failed"
            end
        end
    end
    return true, nil, activated_count
end

local function bindingForRoute(route)
    if not route or not route.ok then
        return nil
    end
    local user_data = route.user_data or {}
    local recipe_id = route.recipe_id
    local source_slot_id = route.slot_id
    local cast_id = user_data.cast_id
    if type(recipe_id) == "string" and type(source_slot_id) == "string" and type(cast_id) == "string" then
        local binding = bindings_by_cast_source[castSourceKey(recipe_id, source_slot_id, cast_id)]
        if binding then
            return binding
        end
    end
    if type(recipe_id) == "string" and type(source_slot_id) == "string" then
        return bindings_by_latest_source[recipeSlotKey(recipe_id, source_slot_id)]
    end
    return nil
end

local function duplicateKey(route, binding)
    local payload_key = binding.payload_group_key or binding.payload_slot_id
    local bounce_key = route.bounce_index or (route.user_data and route.user_data.bounce_index) or "no-bounce"
    return string.format(
        "trigger:%s:%s:%s:%s:%s:%s:%s",
        tostring(binding.cast_id or (route.user_data and route.user_data.cast_id) or "no-cast"),
        tostring(binding.recipe_id or route.recipe_id),
        tostring(binding.source_slot_id or route.slot_id),
        tostring(payload_key),
        tostring(binding.source_helper_engine_id or route.helper_engine_id),
        tostring(route.projectile_id or "no-projectile"),
        tostring(bounce_key)
    )
end

local function rememberDuplicateKey(key)
    duplicate_keys[key] = true
    appendBounded(duplicate_order, key, MAX_DUPLICATE_KEYS, function(evicted)
        duplicate_keys[evicted] = nil
    end)
end

local function shortKey(key)
    if type(key) == "string" and #key <= 180 then
        return key
    end
    return nil
end

local function shallowCopy(value)
    local out = {}
    for key, item in pairs(value or {}) do
        out[key] = item
    end
    return out
end

local function irTriggerRuntimeEnabled(options)
    if options and options.force_ir_trigger_runtime_disabled == true then
        return false
    end
    return (options and options.force_ir_trigger_runtime_enabled == true)
        or dev.irTriggerRuntimeEnabled()
end

local function irPlannerOptions(binding, options)
    local gates = launch_modifier_policy.gateHintsForModifierKinds(
        binding and binding.payload_modifier_kinds,
        options
    )
    return {
        allow_payload_multicast = binding.payload_multicast == true
            or (options and options.allow_payload_multicast == true)
            or (options and options.force_payload_multicast_enabled == true),
        allow_payload_pattern = binding.payload_pattern == true
            or (options and options.allow_payload_pattern == true)
            or (options and options.force_payload_pattern_enabled == true),
        allow_payload_launch_modifiers = binding.has_payload_modifier == true
            or (options and options.allow_payload_launch_modifiers == true),
        force_speed_plus_enabled = gates.force_speed_plus_enabled,
        force_speed_plus_disabled = gates.force_speed_plus_disabled,
        speed_plus_enabled = gates.speed_plus_enabled,
        force_size_plus_enabled = gates.force_size_plus_enabled,
        force_size_plus_disabled = gates.force_size_plus_disabled,
        size_plus_enabled = gates.size_plus_enabled,
        max_depth = options and options.max_depth or limits.MAX_RECURSION_DEPTH,
        max_jobs = binding.max_payload_fanout or (options and options.max_jobs),
        max_fanout = binding.max_payload_fanout or (options and options.max_fanout),
        max_projectiles = binding.max_projectiles or (options and options.max_projectiles),
        max_live_launches_per_tick = binding.max_live_launches_per_tick
            or (options and options.max_live_launches_per_tick),
        chaos_budget_profile = binding.chaos_budget_profile or (options and options.chaos_budget_profile),
        allow_source_homing = options and options.allow_source_homing == true,
        allow_payload_homing = (binding and binding.has_payload_homing == true)
            or (options and options.allow_payload_homing == true),
        allow_homing = options and options.allow_homing == true,
        force_homing_enabled = options and options.force_homing_enabled,
        force_homing_disabled = options and options.force_homing_disabled,
        homing_enabled = (options and options.homing_enabled == true) or dev.liveHomingEnabled() == true,
        max_homing_fanout_per_cast = options and options.max_homing_fanout_per_cast,
        max_homing_target_scans_per_cast = options and options.max_homing_target_scans_per_cast,
        max_soft_homing_registrations_per_cast = options and options.max_soft_homing_registrations_per_cast,
        homing_target_id = options and options.homing_target_id,
        homing_target_position = options and options.homing_target_position,
        homing_actor_scan = options and options.homing_actor_scan,
        allow_nested_trigger_timer = (binding and binding.allow_nested_trigger_timer == true)
            or (options and options.allow_nested_trigger_timer == true),
        allow_nested_final_fanout = (binding and binding.allow_nested_final_fanout == true)
            or (options and options.allow_nested_final_fanout == true),
        allow_nested_payload_modifiers = (binding and binding.allow_nested_payload_modifiers == true)
            or (options and options.allow_nested_payload_modifiers == true),
        allow_nested_payload_homing = (binding and binding.allow_nested_payload_homing == true)
            or (options and options.allow_nested_payload_homing == true),
        allow_payload_detonate = true,
        max_live_nested_continuation_depth = options and options.max_live_nested_continuation_depth,
        max_nested_continuation_jobs_per_cast = options and options.max_nested_continuation_jobs_per_cast,
        max_nested_final_payload_jobs_per_cast = options and options.max_nested_final_payload_jobs_per_cast,
    }
end

local function slotEntryById(plan, slot_id)
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.slot_id == slot_id then
            return slot
        end
    end
    return nil
end

local function entryHasHoming(entry)
    for _, op in ipairs(entry and entry.prefix_ops or {}) do
        if op and op.opcode == "Homing" then
            return true
        end
    end
    return false
end

local function clearHomingSelection(target)
    if type(target) ~= "table" then
        return
    end
    target.homing = nil
    target.homing_mode = nil
    target.homing_force = nil
    target.homing_field = nil
    target.homing_target_id = nil
    target.homing_target_object = nil
    target.homing_target_position = nil
    target.homing_target_provider = nil
    target.homing_target_kind = nil
    target.homing_candidate_count = nil
    target.homing_actor_candidate_count = nil
    target.homing_creature_candidate_count = nil
    target.homing_npc_candidate_count = nil
    target.homing_force_key = nil
    target.homing_direction_key = nil
    target.homing_rejection_reason = nil
    target.payload_homing_rejection_reason = nil
end

local function triggerHomingEvent(binding, job, event_kind)
    local payload = job and job.payload or {}
    return {
        event_kind = event_kind or "trigger_payload",
        source_slot_id = binding and binding.source_slot_id,
        source_helper_engine_id = binding and binding.source_helper_engine_id,
        source_postfix_opcode = "Trigger",
        cast_id = binding and binding.cast_id,
        actor = payload.actor or (binding and binding.actor),
        sender = payload.actor or (binding and binding.actor),
        source_job_id = job and job.source_job_id,
        parent_job_id = job and job.parent_job_id,
        start_pos = payload.start_pos or (job and job.hit_pos),
        origin = payload.start_pos or (job and job.hit_pos),
        hit_pos = job and job.hit_pos,
        direction = payload.direction or (job and job.direction) or (binding and binding.direction),
        launch_direction = payload.direction or (job and job.direction) or (binding and binding.direction),
        source_direction = binding and binding.direction,
        homing_caster_forward_direction = binding and binding.direction,
        hit_object = job and job.hit_object,
        current_hit_target_id = job and job.current_hit_target_id,
        excludeTarget = job and job.excludeTarget,
        trigger_source_slot_id = binding and binding.source_slot_id,
        trigger_payload_slot_id = job and job.slot_id,
    }
end

local function triggerHomingOptions(binding, job)
    local count = tonumber(job and job.fanout_count) or tonumber(binding and binding.payload_count) or 1
    return {
        allow_payload_homing = binding and binding.has_payload_homing == true,
        allow_nested_payload_homing = true,
        allow_homing = binding and binding.has_payload_homing == true,
        force_homing_enabled = binding and binding.has_payload_homing == true or nil,
        homing_enabled = dev.liveHomingEnabled() == true,
        homing_actor_scan = true,
        apply_homing_direction = false,
        fanout_count = count,
        payload_fanout_count = count,
        homing_fanout_count = count,
        max_homing_fanout_per_cast = limits.MAX_HOMING_FANOUT_PER_CAST,
        max_homing_target_scans_per_cast = limits.MAX_HOMING_TARGET_SCANS_PER_CAST,
        max_soft_homing_registrations_per_cast = limits.MAX_SOFT_HOMING_REGISTRATIONS_PER_CAST,
    }
end

local function applyPayloadLaunchPolicy(binding, options, payload, job, event_kind)
    local plan = binding and binding.plan or nil
    local payload_entry = slotEntryById(plan, payload and payload.slot_id) or payload
    local policy = launch_modifier_policy.applyToJob(
        plan,
        plan and plan.runtime_ir or nil,
        payload_entry,
        job,
        { event_kind = event_kind },
        irPlannerOptions(binding or {}, options or {})
    )
    if policy.ok ~= true then
        return false, policy.rejection_reason or "payload_modifier_unsupported_prefix"
    end
    if entryHasHoming(payload_entry) then
        clearHomingSelection(job)
        clearHomingSelection(job and job.payload)
        local homing = homing_launch_policy.applyToJob(
            plan,
            plan and plan.runtime_ir or nil,
            payload_entry,
            job,
            triggerHomingEvent(binding, job, event_kind),
            triggerHomingOptions(binding, job)
        )
        if homing.ok ~= true then
            if type(job) == "table" then
                job.payload_homing_rejection_reason = homing.rejection_reason
            end
            if type(job and job.payload) == "table" then
                job.payload.payload_homing_rejection_reason = homing.rejection_reason
            end
            runtime_stats.inc("trigger_payload_homing_deferred")
        end
    end
    return true, nil
end

local function branchScope(binding, route)
    local user_data = route and route.user_data or nil
    return binding.branch_scope
        or (user_data and user_data.branch_scope)
        or "default"
end

local function branchParentId(binding, route)
    local user_data = route and route.user_data or nil
    return binding.branch_id
        or (user_data and user_data.branch_id)
        or string.format(
            "root:%s:%s",
            tostring(binding.cast_id or (user_data and user_data.cast_id) or "no-cast"),
            tostring(binding.source_slot_id or "no-source")
        )
end

local function branchKind(binding, count)
    if binding.nested_final_fanout == true then
        return "nested_final_fanout"
    end
    local prefix = "trigger_payload"
    if binding.payload_pattern == true then
        return prefix .. "_pattern"
    end
    if binding.payload_multicast == true or tonumber(count) ~= 1 then
        return prefix .. "_multicast"
    end
    return prefix
end

local function branchInfo(binding, route, payload, index, count)
    local parent_id = branchParentId(binding, route)
    local payload_slot_id = payload and payload.slot_id or binding.payload_slot_id or "no-payload"
    local user_data = route and route.user_data or nil
    return {
        branch_scope = branchScope(binding, route),
        branch_parent_id = parent_id,
        branch_id = string.format("%s:trigger:%s:%s", tostring(parent_id), tostring(index), tostring(payload_slot_id)),
        branch_kind = branchKind(binding, count),
        branch_index = index,
        branch_count = count,
        chain_continuation_group_id = binding.chain_continuation_group_id
            or (user_data and user_data.chain_continuation_group_id),
    }
end

local function copyBranchFields(target, branch)
    if type(target) ~= "table" or type(branch) ~= "table" then
        return
    end
    target.branch_scope = branch.branch_scope
    target.branch_id = branch.branch_id
    target.branch_parent_id = branch.branch_parent_id
    target.branch_kind = branch.branch_kind
    target.branch_index = branch.branch_index
    target.branch_count = branch.branch_count
    target.chain_continuation_group_id = branch.chain_continuation_group_id
end

local function irTriggerFallback(binding, reason, marker)
    runtime_stats.inc("ir_trigger_runtime_fallback")
    log.info(string.format(
        "%s recipe_id=%s cast_id=%s source_slot_id=%s reason=%s",
        marker or "SPELLFORGE_IR_TRIGGER_RUNTIME_FALLBACK",
        tostring(binding and binding.recipe_id),
        tostring(binding and binding.cast_id),
        tostring(binding and binding.source_slot_id),
        tostring(reason)
    ))
    return {
        fallback = true,
        reason = reason,
        mismatch = marker == "SPELLFORGE_IR_TRIGGER_RUNTIME_MISMATCH",
    }
end

local function irTriggerMismatch(binding, reason)
    runtime_stats.inc("ir_trigger_runtime_mismatch")
    return irTriggerFallback(binding, reason, "SPELLFORGE_IR_TRIGGER_RUNTIME_MISMATCH")
end

local function validateIrTriggerJobPlan(binding, payloads, continuation_plan, job_plan)
    if type(continuation_plan) ~= "table" or continuation_plan.ok ~= true then
        return false, continuation_plan and continuation_plan.rejection_reason or "continuation_plan_failed"
    end
    if continuation_plan.source_slot_id ~= binding.source_slot_id then
        return false, "source_slot_mismatch"
    end
    if continuation_plan.source_helper_engine_id ~= binding.source_helper_engine_id then
        return false, "source_helper_mismatch"
    end
    if type(job_plan) ~= "table" or job_plan.ok ~= true then
        return false, job_plan and job_plan.rejection_reason or "runtime_job_plan_failed"
    end
    if tonumber(job_plan.planned_job_count) ~= #payloads then
        return false, "payload_count_mismatch"
    end
    for index, payload in ipairs(payloads or {}) do
        local job = job_plan.planned_jobs and job_plan.planned_jobs[index] or nil
        if type(job) ~= "table" then
            return false, "planned_job_missing"
        end
        if job.slot_id ~= payload.slot_id or job.payload_slot_id ~= payload.slot_id then
            return false, "payload_slot_mismatch"
        end
        if job.helper_engine_id ~= payload.helper_engine_id then
            return false, "payload_helper_mismatch"
        end
        if job.kind ~= orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND then
            return false, "job_kind_mismatch"
        end
    end
    return true, nil
end

local function enrichIrTriggerPayload(planned_job, binding, route, payload, index, count, payload_depth, trigger_route, key, actor, start_pos, direction)
    local branch = branchInfo(binding, route, payload, index, count)
    local payload_launch = shallowCopy(planned_job.payload or {})
    payload_launch.actor = actor
    payload_launch.start_pos = start_pos
    payload_launch.direction = payload.direction or direction
    payload_launch.hit_object = route.target
    payload_launch.hit_pos = start_pos
    payload_launch.current_hit_target_id = route.target
    payload_launch.excludeTarget = route.target
    payload_launch.cast_id = binding.cast_id
    payload_launch.source_slot_id = binding.source_slot_id
    payload_launch.source_helper_engine_id = binding.source_helper_engine_id
    payload_launch.source_postfix_opcode = "Trigger"
    payload_launch.root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id
    payload_launch.current_source_slot_id = payload.current_source_slot_id or payload.slot_id
    payload_launch.parent_slot_id = payload.parent_slot_id or binding.source_slot_id
    payload_launch.payload_depth = payload.payload_depth or payload_depth
    payload_launch.nested_stage_kind = payload.nested_stage_kind or binding.nested_stage_kind
    payload_launch.nested_stage_index = payload.nested_stage_index or binding.nested_stage_index
    payload_launch.has_trigger_payload = payload.has_trigger_payload
    payload_launch.has_timer_payload = payload.has_timer_payload
    payload_launch.payload_slot_id = payload.slot_id
    payload_launch.trigger_source_slot_id = binding.source_slot_id
    payload_launch.trigger_payload_slot_id = payload.slot_id
    payload_launch.trigger_route = trigger_route
    payload_launch.trigger_duplicate_key = shortKey(key)
    payload_launch.payload_multicast = binding.payload_multicast == true
    payload_launch.payload_pattern = binding.payload_pattern == true
    payload_launch.payload_count = count
    payload_launch.fanout_count = count
    payload_launch.emission_index = payload.emission_index
    payload_launch.group_index = payload.group_index
    payload_launch.pattern_kind = payload.pattern_kind
    payload_launch.pattern_index = payload.pattern_index
    payload_launch.pattern_count = payload.pattern_count
    payload_launch.pattern_direction_key = payload.pattern_direction_key
    payload_launch.nested_final_fanout = binding.nested_final_fanout == true
    payload_launch.nested_final_fanout_kind = binding.nested_final_fanout_kind
    payload_launch.final_fanout_count = binding.nested_final_fanout == true and count or nil
    payload_launch.final_fanout_index = binding.nested_final_fanout == true and index or nil
    payload_launch.chain_runtime = binding.chain_runtime or (route.user_data and route.user_data.chain_runtime)
    payload_launch.chain_role = binding.chain_role or (route.user_data and route.user_data.chain_role)
    payload_launch.chain_id = binding.chain_id or (route.user_data and route.user_data.chain_id)
    payload_launch.chain_hop_index = binding.chain_hop_index or (route.user_data and route.user_data.chain_hop_index)
    payload_launch.chain_max_hops = binding.chain_max_hops or (route.user_data and route.user_data.chain_max_hops)
    payload_launch.chain_continuation_group_id = binding.chain_continuation_group_id
        or (route.user_data and route.user_data.chain_continuation_group_id)
    copyBranchFields(payload_launch, branch)

    local job = shallowCopy(planned_job)
    job.kind = orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND
    job.recipe_id = binding.recipe_id
    job.slot_id = payload.slot_id
    job.helper_engine_id = payload.helper_engine_id
    job.idempotency_key = string.format("%s:%s", tostring(key), tostring(payload.slot_id))
    job.source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    job.parent_job_id = job.source_job_id
    job.depth = payload_depth
    job.cast_id = binding.cast_id
    job.emission_index = payload.emission_index
    job.group_index = payload.group_index
    job.fanout_count = count
    job.max_live_launches_per_tick = binding.max_live_launches_per_tick
    job.chaos_budget_profile = binding.chaos_budget_profile
    job.root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id
    job.current_source_slot_id = payload.current_source_slot_id or payload.slot_id
    job.parent_slot_id = payload.parent_slot_id or binding.source_slot_id
    job.payload_depth = payload.payload_depth or payload_depth
    job.nested_stage_kind = payload.nested_stage_kind or binding.nested_stage_kind
    job.nested_stage_index = payload.nested_stage_index or binding.nested_stage_index
    job.has_trigger_payload = payload.has_trigger_payload
    job.has_timer_payload = payload.has_timer_payload
    job.pattern_kind = payload.pattern_kind
    job.pattern_index = payload.pattern_index
    job.pattern_count = payload.pattern_count
    job.pattern_direction_key = payload.pattern_direction_key
    job.nested_final_fanout = binding.nested_final_fanout == true
    job.nested_final_fanout_kind = binding.nested_final_fanout_kind
    job.final_fanout_count = binding.nested_final_fanout == true and count or nil
    job.final_fanout_index = binding.nested_final_fanout == true and index or nil
    job.chain_runtime = payload_launch.chain_runtime
    job.chain_role = payload_launch.chain_role
    job.chain_id = payload_launch.chain_id
    job.chain_hop_index = payload_launch.chain_hop_index
    job.chain_max_hops = payload_launch.chain_max_hops
    job.chain_continuation_group_id = payload_launch.chain_continuation_group_id
    job.source_slot_id = binding.source_slot_id
    job.source_helper_engine_id = binding.source_helper_engine_id
    job.source_postfix_opcode = "Trigger"
    job.payload_slot_id = payload.slot_id
    job.hit_pos = start_pos
    job.hit_object = route.target
    job.current_hit_target_id = route.target
    job.excludeTarget = route.target
    job.trigger_source_slot_id = binding.source_slot_id
    job.trigger_payload_slot_id = payload.slot_id
    job.trigger_route = trigger_route
    job.trigger_duplicate_key = shortKey(key)
    copyBranchFields(job, branch)
    job.payload = payload_launch
    return job
end

local function enqueueIrTriggerRuntime(route, options, binding, payloads, payload_depth, key, trigger_route, actor, start_pos, direction)
    if not irTriggerRuntimeEnabled(options) then
        return nil
    end
    if binding.nested_tt == true or binding.nested_final_fanout == true then
        return nil
    end

    runtime_stats.inc("ir_trigger_runtime_attempts")
    local plan = binding.plan or binding.compiled_plan or binding.attached_plan
    local planner_options = irPlannerOptions(binding, options)
    local event = {
        event_kind = "trigger_hit",
        source_slot_id = binding.source_slot_id,
        source_postfix_opcode = "Trigger",
        cast_id = binding.cast_id,
        actor = actor,
        sender = actor,
        source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id),
        parent_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id),
        start_pos = start_pos,
        origin = start_pos,
        hit_pos = start_pos,
        direction = direction,
        launch_direction = direction,
        hit_object = route.target,
        current_hit_target_id = route.target,
        excludeTarget = route.target,
        branch_scope = branchScope(binding, route),
        branch_parent_id = branchParentId(binding, route),
        chain_runtime = binding.chain_runtime or (route.user_data and route.user_data.chain_runtime),
        chain_role = binding.chain_role or (route.user_data and route.user_data.chain_role),
        chain_id = binding.chain_id or (route.user_data and route.user_data.chain_id),
        chain_hop_index = binding.chain_hop_index or (route.user_data and route.user_data.chain_hop_index),
        chain_max_hops = binding.chain_max_hops or (route.user_data and route.user_data.chain_max_hops),
        chain_continuation_group_id = binding.chain_continuation_group_id
            or (route.user_data and route.user_data.chain_continuation_group_id),
    }
    local planned = ir_runtime_adapter.planEvent(binding, plan, event, planner_options)
    if planned.ok ~= true then
        if planned.stage == "ir" then
            return irTriggerFallback(binding, planned.rejection_reason)
        end
        return irTriggerMismatch(binding, planned.rejection_reason or "continuation_plan_failed")
    end
    local continuation_plan = planned.continuation_plan
    local job_plan = planned.job_plan
    local valid, reason = validateIrTriggerJobPlan(binding, payloads, continuation_plan, job_plan)
    if not valid then
        return irTriggerMismatch(binding, reason)
    end

    local job_ids = {}
    for index, payload in ipairs(payloads or {}) do
        local planned_job = job_plan.planned_jobs[index]
        local job = enrichIrTriggerPayload(
            planned_job,
            binding,
            route,
            payload,
            index,
            #payloads,
            payload_depth,
            trigger_route,
            key,
            actor,
            start_pos,
            direction
        )
        local enqueue = orchestrator.enqueue(job)
        if not enqueue.ok then
            runtime_stats.inc("live_trigger_payload_route_failed")
            return {
                ok = false,
                error = enqueue.error or "IR trigger payload enqueue failed",
                job_ids = job_ids,
                ir_trigger_runtime = true,
            }
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end

    runtime_stats.inc("ir_trigger_runtime_enqueued")
    runtime_stats.inc("ir_trigger_runtime_jobs_enqueued", #job_ids)
    local first_job = orchestrator.getJob(job_ids[1])
    log.info(string.format(
        "SPELLFORGE_IR_TRIGGER_RUNTIME_ENQUEUED recipe_id=%s cast_id=%s source_slot_id=%s payload_count=%s first_job_id=%s branch_kind=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(job_ids[1]),
        tostring(first_job and first_job.branch_kind or nil)
    ))
    return {
        ok = true,
        job_ids = job_ids,
        ir_trigger_runtime = true,
    }
end

function live_trigger.handleResolvedHit(route, opts)
    local options = opts or {}
    if not route or route.ok ~= true then
        return { ok = false, ignored = true, error = route and route.error or "unresolved hit" }
    end

    local binding = bindingForRoute(route)
    if not binding then
        return { ok = true, ignored = true, reason = "no_live_trigger_binding" }
    end
    if runtime_session.shouldDrop(binding.runtime_generation, "live_trigger_binding", {
        id = binding.source_slot_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.user_data and runtime_session.shouldDrop(route.user_data.runtime_generation, "live_trigger_route", {
        id = route.projectile_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.helper_engine_id ~= binding.source_helper_engine_id then
        return { ok = true, ignored = true, reason = "not_trigger_source_helper" }
    end

    if options.force_enabled ~= true and not dev.liveTriggerEnabled() then
        runtime_stats.inc("live_trigger_rejected")
        runtime_stats.inc("live_trigger_disabled_rejections")
        return { ok = false, disabled = true, error = "live trigger disabled" }
    end

    runtime_stats.inc("live_trigger_source_hits")

    local source_depth = tonumber(route.user_data and route.user_data.depth) or 0
    local payload_depth = source_depth + 1
    if payload_depth > limits.MAX_RECURSION_DEPTH then
        runtime_stats.inc("live_trigger_depth_rejections")
        runtime_stats.inc("live_trigger_payload_route_failed")
        return { ok = false, error = "trigger payload depth exceeds MAX_RECURSION_DEPTH" }
    end

    local key = duplicateKey(route, binding)
    if duplicate_keys[key] then
        runtime_stats.inc("live_trigger_duplicate_hits_suppressed")
        if binding.nested_tt == true then
            runtime_stats.inc("nested_tt_duplicate_suppressed")
        end
        if binding.nested_final_fanout == true
            or (type(binding.nested_timer_binding) == "table"
                and binding.nested_timer_binding.nested_final_fanout == true) then
            runtime_stats.inc("nested_final_fanout_duplicate_suppressed")
        end
        log.debug(string.format(
            "live Trigger duplicate payload skipped recipe_id=%s source_slot_id=%s payload_slot_id=%s key=%s",
            tostring(binding.recipe_id),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(shortKey(key) or "<long>")
        ))
        return {
            ok = true,
            duplicate_suppressed = true,
            duplicate_key = key,
            source_slot_id = binding.source_slot_id,
            payload_slot_id = binding.payload_slot_id,
            payload_slot_ids = binding.payload_slot_ids,
            payload_count = binding.payload_count,
            payload_multicast = binding.payload_multicast == true,
            payload_pattern = binding.payload_pattern == true,
            payload_pattern_kind = binding.payload_pattern_kind,
            nested_final_fanout = binding.nested_final_fanout == true,
            nested_final_fanout_kind = binding.nested_final_fanout_kind,
        }
    end

    local payloads = compactPayloadsFromBinding(binding)
    if #payloads == 0 then
        runtime_stats.inc("live_trigger_payload_missing")
        runtime_stats.inc("live_trigger_payload_route_failed")
        return { ok = false, error = "trigger payload helper mapping missing" }
    end
    local max_payload_fanout = tonumber(binding.max_payload_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_projectiles = tonumber(binding.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if #payloads > max_payload_fanout or #payloads > max_projectiles then
        runtime_stats.inc("live_trigger_payload_route_failed")
        runtime_stats.inc("payload_multicast_cap_reject")
        return { ok = false, error = "trigger payload multicast fanout exceeds cap" }
    end
    for index, payload in ipairs(payloads) do
        local payload_mapping = helper_records.getByRecipeSlot(binding.recipe_id, payload.slot_id)
            or helper_records.getByEngineId(payload.helper_engine_id)
        if not payload_mapping or payload_mapping.engine_id ~= payload.helper_engine_id then
            runtime_stats.inc("live_trigger_payload_missing")
            runtime_stats.inc("live_trigger_payload_route_failed")
            return { ok = false, error = "trigger payload helper mapping missing" }
        end
        if payload_mapping.source_postfix_opcode ~= "Trigger"
            or payload_mapping.trigger_source_slot_id ~= binding.source_slot_id then
            runtime_stats.inc("live_trigger_payload_route_failed")
            return { ok = false, error = "trigger payload helper mapping mismatch" }
        end
    end

    local actor = route.attacker or binding.actor
    local start_pos = route.hit_pos
    local direction = route.bounce_direction or route.hit_normal or binding.direction
    if actor == nil then
        runtime_stats.inc("live_trigger_payload_route_failed")
        return { ok = false, error = "missing caster for trigger payload" }
    end
    if start_pos == nil then
        runtime_stats.inc("live_trigger_payload_route_failed")
        return { ok = false, error = "missing hit position for trigger payload" }
    end
    if direction == nil then
        runtime_stats.inc("live_trigger_payload_route_failed")
        return { ok = false, error = "missing source direction for trigger payload" }
    end

    local pattern_info = nil
    if binding.payload_pattern == true then
        local pattern_err = nil
        pattern_info, pattern_err = payload_pattern.compute(payloads, direction, binding.payload_pattern_kind, binding.payload_pattern_op)
        if not pattern_info then
            runtime_stats.inc("live_trigger_payload_route_failed")
            runtime_stats.inc("payload_pattern_rejected")
            runtime_stats.inc("payload_pattern_nested_reject")
            return { ok = false, error = pattern_err or "trigger payload pattern direction failed" }
        end
        payloads = pattern_info.payloads
    end

    local trigger_route = route.source or "unknown"
    local source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    local ir_enqueue = enqueueIrTriggerRuntime(
        route,
        options,
        binding,
        payloads,
        payload_depth,
        key,
        trigger_route,
        actor,
        start_pos,
        direction
    )
    if ir_enqueue and ir_enqueue.ok == false then
        return ir_enqueue
    end

    local ir_trigger_runtime_used = ir_enqueue and ir_enqueue.ir_trigger_runtime == true
    local ir_trigger_runtime_fallback_reason = ir_enqueue and ir_enqueue.fallback and ir_enqueue.reason or nil
    local ir_trigger_runtime_mismatch = ir_enqueue and ir_enqueue.mismatch == true or false
    local job_ids = ir_trigger_runtime_used and type(ir_enqueue) == "table" and ir_enqueue.job_ids or {}
    if not ir_trigger_runtime_used then
        for index, payload in ipairs(payloads) do
            local payload_key = string.format("%s:%s", tostring(key), tostring(payload.slot_id))
            local branch = branchInfo(binding, route, payload, index, #payloads)
            local payload_launch = {
                actor = actor,
                start_pos = start_pos,
                direction = payload.direction or direction,
                hit_object = route.target,
                hit_pos = start_pos,
                current_hit_target_id = route.target,
                excludeTarget = route.target,
                cast_id = binding.cast_id,
                source_slot_id = binding.source_slot_id,
                source_helper_engine_id = binding.source_helper_engine_id,
                source_postfix_opcode = "Trigger",
                root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id,
                current_source_slot_id = payload.current_source_slot_id or payload.slot_id,
                parent_slot_id = payload.parent_slot_id or binding.source_slot_id,
                payload_depth = payload.payload_depth or payload_depth,
                nested_stage_kind = payload.nested_stage_kind or binding.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index or binding.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
                payload_slot_id = payload.slot_id,
                trigger_source_slot_id = binding.source_slot_id,
                trigger_payload_slot_id = payload.slot_id,
                trigger_route = trigger_route,
                trigger_duplicate_key = shortKey(key),
                payload_multicast = binding.payload_multicast == true,
                payload_pattern = binding.payload_pattern == true,
                payload_count = #payloads,
                fanout_count = #payloads,
                emission_index = payload.emission_index,
                group_index = payload.group_index,
                pattern_kind = payload.pattern_kind,
                pattern_index = payload.pattern_index,
                pattern_count = payload.pattern_count,
                pattern_direction_key = payload.pattern_direction_key,
                nested_final_fanout = binding.nested_final_fanout == true,
                nested_final_fanout_kind = binding.nested_final_fanout_kind,
                final_fanout_count = binding.nested_final_fanout == true and #payloads or nil,
                final_fanout_index = binding.nested_final_fanout == true and index or nil,
                chain_runtime = binding.chain_runtime or (route.user_data and route.user_data.chain_runtime),
                chain_role = binding.chain_role or (route.user_data and route.user_data.chain_role),
                chain_id = binding.chain_id or (route.user_data and route.user_data.chain_id),
                chain_hop_index = binding.chain_hop_index or (route.user_data and route.user_data.chain_hop_index),
                chain_max_hops = binding.chain_max_hops or (route.user_data and route.user_data.chain_max_hops),
                chain_continuation_group_id = binding.chain_continuation_group_id
                    or (route.user_data and route.user_data.chain_continuation_group_id),
            }
            copyBranchFields(payload_launch, branch)
            local payload_job = {
                kind = orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND,
                recipe_id = binding.recipe_id,
                slot_id = payload.slot_id,
                helper_engine_id = payload.helper_engine_id,
                idempotency_key = payload_key,
                source_job_id = source_job_id,
                parent_job_id = source_job_id,
                depth = payload_depth,
                cast_id = binding.cast_id,
                emission_index = payload.emission_index,
                group_index = payload.group_index,
                fanout_count = #payloads,
                max_live_launches_per_tick = binding.max_live_launches_per_tick,
                chaos_budget_profile = binding.chaos_budget_profile,
                root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id,
                current_source_slot_id = payload.current_source_slot_id or payload.slot_id,
                parent_slot_id = payload.parent_slot_id or binding.source_slot_id,
                payload_depth = payload.payload_depth or payload_depth,
                nested_stage_kind = payload.nested_stage_kind or binding.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index or binding.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
                pattern_kind = payload.pattern_kind,
                pattern_index = payload.pattern_index,
                pattern_count = payload.pattern_count,
                pattern_direction_key = payload.pattern_direction_key,
                nested_final_fanout = binding.nested_final_fanout == true,
                nested_final_fanout_kind = binding.nested_final_fanout_kind,
                final_fanout_count = binding.nested_final_fanout == true and #payloads or nil,
                final_fanout_index = binding.nested_final_fanout == true and index or nil,
                chain_runtime = payload_launch.chain_runtime,
                chain_role = payload_launch.chain_role,
                chain_id = payload_launch.chain_id,
                chain_hop_index = payload_launch.chain_hop_index,
                chain_max_hops = payload_launch.chain_max_hops,
                source_slot_id = binding.source_slot_id,
                source_helper_engine_id = binding.source_helper_engine_id,
                source_postfix_opcode = "Trigger",
                hit_pos = start_pos,
                hit_object = route.target,
                current_hit_target_id = route.target,
                excludeTarget = route.target,
                payload_slot_id = payload.slot_id,
                branch_scope = branch.branch_scope,
                branch_id = branch.branch_id,
                branch_parent_id = branch.branch_parent_id,
                branch_kind = branch.branch_kind,
                branch_index = branch.branch_index,
                branch_count = branch.branch_count,
                chain_continuation_group_id = payload_launch.chain_continuation_group_id or branch.chain_continuation_group_id,
                payload = payload_launch,
            }
            local policy_ok, policy_error = applyPayloadLaunchPolicy(binding, options, payload, payload_job, "trigger_payload")
            if not policy_ok then
                runtime_stats.inc("live_trigger_payload_route_failed")
                return { ok = false, error = policy_error or "payload modifier policy failed", job_ids = job_ids }
            end
            local enqueue = orchestrator.enqueue(payload_job)
            if not enqueue.ok then
                runtime_stats.inc("live_trigger_payload_route_failed")
                return { ok = false, error = enqueue.error or "trigger payload enqueue failed", job_ids = job_ids }
            end
            job_ids[#job_ids + 1] = enqueue.job_id
        end
    end

    rememberDuplicateKey(key)
    runtime_stats.inc("live_trigger_payload_jobs_enqueued", #job_ids)
    if binding.nested_tt == true then
        runtime_stats.inc("nested_tt_trigger_hits")
        if binding.nested_tt_kind == "trigger_timer" then
            runtime_stats.inc("nested_tt_intermediate_jobs", #job_ids)
        elseif binding.nested_tt_kind == "timer_trigger" then
            runtime_stats.inc("nested_tt_final_jobs", #job_ids)
        end
    end
    if binding.payload_multicast == true then
        runtime_stats.inc("payload_multicast_jobs", #job_ids)
        runtime_stats.inc("payload_multicast_trigger_jobs", #job_ids)
        runtime_stats.inc("payload_multicast_runtime_ok")
    end
    if binding.payload_pattern == true then
        runtime_stats.inc("payload_pattern_jobs", #job_ids)
        runtime_stats.inc("payload_pattern_trigger_jobs", #job_ids)
        runtime_stats.inc("payload_pattern_runtime_ok")
        if binding.payload_pattern_kind == "Spread" then
            runtime_stats.inc("payload_pattern_spread_jobs", #job_ids)
        elseif binding.payload_pattern_kind == "Burst" then
            runtime_stats.inc("payload_pattern_burst_jobs", #job_ids)
        end
    end
    runtime_stats.max("chaos_budget_max_jobs_observed", #job_ids)
    runtime_stats.max("chaos_budget_max_projectiles_observed", #job_ids)
    runtime_stats.max("chaos_budget_max_queue_observed", orchestrator.queueLength())
    if #job_ids > limits.MAX_NESTED_PAYLOAD_FANOUT then
        runtime_stats.inc("chaos_budget_high_fanout_smoke")
        log.info(string.format(
            "SPELLFORGE_CHAOS_STRESS_OK profile=chaos observed_jobs=%d observed_projectiles=%d observed_queue=%d live_mode=trigger_payload fanout_count=%d",
            #job_ids,
            #job_ids,
            orchestrator.queueLength(),
            #job_ids
        ))
    end
    if binding.nested_final_fanout == true then
        runtime_stats.inc("nested_final_fanout_jobs", #job_ids)
        runtime_stats.inc("nested_final_fanout_trigger_jobs", #job_ids)
        runtime_stats.inc("nested_final_fanout_runtime_ok")
        if binding.payload_pattern_kind == "Spread" then
            runtime_stats.inc("nested_final_fanout_spread_jobs", #job_ids)
        elseif binding.payload_pattern_kind == "Burst" then
            runtime_stats.inc("nested_final_fanout_burst_jobs", #job_ids)
        end
    end
    local marker = binding.nested_final_fanout == true
        and "SPELLFORGE_NESTED_FINAL_FANOUT_TRIGGER_ENQUEUED"
        or binding.payload_pattern == true
        and "SPELLFORGE_PAYLOAD_PATTERN_TRIGGER_ENQUEUED"
        or binding.payload_multicast == true
        and "SPELLFORGE_PAYLOAD_MULTICAST_TRIGGER_ENQUEUED"
        or "SPELLFORGE_LIVE_TRIGGER_PAYLOAD_ENQUEUED"
    local first_queued_job = orchestrator.getJob(job_ids[1])
    log.info(string.format(
        "%s recipe_id=%s cast_id=%s source_slot_id=%s payload_count=%s pattern_kind=%s route=%s first_branch_id=%s branch_kind=%s first_job_id=%s",
        marker,
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(binding.payload_pattern_kind),
        tostring(trigger_route),
        tostring(first_queued_job and first_queued_job.branch_id or nil),
        tostring(first_queued_job and first_queued_job.branch_kind or nil),
        tostring(job_ids[1])
    ))

    local tick = nil
    local jobs = {}
    for _ = 1, 3 do
        local all_settled = true
        for _, job_id in ipairs(job_ids) do
            local job = orchestrator.getJob(job_id)
            if not job or job.status == "queued" or job.status == "running" then
                all_settled = false
                break
            end
        end
        if all_settled then
            break
        end
        local tick_options = {
            max_jobs_per_tick = tonumber(options.max_jobs_per_tick or binding.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
            max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick or binding.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        }
        if options.simulate_update_ticks == true then
            tick_options.dt_seconds = tonumber(options.simulated_dt_seconds) or 0
        end
        tick = orchestrator.tick(tick_options)
        if binding.allow_pending_launch_jobs == true
            and tick
            and tonumber(tick.live_launch_throttled_count) ~= nil
            and tonumber(tick.live_launch_throttled_count) > 0 then
            break
        end
    end

    local launch_ok = true
    local processed_count = 0
    local launch_ok_count = 0
    local pending_count = 0
    local projectile_ids = {}
    for index, job_id in ipairs(job_ids) do
        local job = orchestrator.getJob(job_id)
        local processed = job and job.status ~= "queued" and job.status ~= "running"
        if processed then
            processed_count = processed_count + 1
        end
        local job_ok = job and job.status == "complete" and job.launch_accepted == true
        local pending = job and (job.status == "queued" or job.status == "running")
        if job_ok then
            launch_ok_count = launch_ok_count + 1
            if type(job) == "table" and job.projectile_id ~= nil then
                projectile_ids[#projectile_ids + 1] = job.projectile_id
            end
        elseif pending and binding.allow_pending_launch_jobs == true then
            pending_count = pending_count + 1
        else
            launch_ok = false
        end
        jobs[index] = {
            job_id = job_id,
            job_status = job and job.status or nil,
            slot_id = job and job.slot_id or nil,
            helper_engine_id = job and job.helper_engine_id or nil,
            cast_id = job and job.cast_id or nil,
            emission_index = job and job.emission_index or nil,
            group_index = job and job.group_index or nil,
            fanout_count = job and job.fanout_count or nil,
            root_source_slot_id = job and job.root_source_slot_id or nil,
            current_source_slot_id = job and job.current_source_slot_id or nil,
            parent_slot_id = job and job.parent_slot_id or nil,
            payload_depth = job and job.payload_depth or nil,
            nested_stage_kind = job and job.nested_stage_kind or nil,
            nested_stage_index = job and job.nested_stage_index or nil,
            pattern_kind = job and job.pattern_kind or nil,
            pattern_index = job and job.pattern_index or nil,
            pattern_count = job and job.pattern_count or nil,
            pattern_direction_key = job and job.pattern_direction_key or nil,
            nested_final_fanout = job and job.nested_final_fanout == true or false,
            nested_final_fanout_kind = job and job.nested_final_fanout_kind or nil,
            final_fanout_count = job and job.final_fanout_count or nil,
            final_fanout_index = job and job.final_fanout_index or nil,
            branch_scope = job and job.branch_scope or nil,
            branch_id = job and job.branch_id or nil,
            branch_parent_id = job and job.branch_parent_id or nil,
            branch_kind = job and job.branch_kind or nil,
            branch_index = job and job.branch_index or nil,
            branch_count = job and job.branch_count or nil,
            chain_continuation_group_id = job and job.chain_continuation_group_id or nil,
            source_slot_id = job and job.source_slot_id or nil,
            source_helper_engine_id = job and job.source_helper_engine_id or nil,
            source_postfix_opcode = job and job.source_postfix_opcode or nil,
            payload_slot_id = job and job.payload_slot_id or nil,
            trigger_route = job and job.trigger_route or nil,
            trigger_duplicate_key = job and job.trigger_duplicate_key or nil,
            launch_accepted = job and job.launch_accepted == true or false,
            launch_direction = job and job.launch_direction or nil,
            projectile_id = job and job.projectile_id or nil,
            launch_user_data = job and job.launch_user_data or nil,
            error = job and job.error or nil,
        }
    end
    if processed_count > 0 then
        runtime_stats.inc("live_trigger_payload_jobs_processed", processed_count)
    end
    if launch_ok_count > 0 then
        runtime_stats.inc("live_trigger_payload_launch_ok", launch_ok_count)
        log.info(string.format(
            "SPELLFORGE_LIVE_TRIGGER_PAYLOAD_OK recipe_id=%s cast_id=%s source_slot_id=%s payload_count=%s launch_ok_count=%s first_branch_id=%s branch_kind=%s first_projectile_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.source_slot_id),
            tostring(#payloads),
            tostring(launch_ok_count),
            tostring(jobs[1] and jobs[1].branch_id or nil),
            tostring(jobs[1] and jobs[1].branch_kind or nil),
            tostring(projectile_ids[1])
        ))
    end
    if not launch_ok then
        runtime_stats.inc("live_trigger_payload_launch_failed", #payloads - launch_ok_count)
        runtime_stats.inc("live_trigger_payload_route_failed")
    end

    if launch_ok and binding.allow_nested_trigger_timer == true then
        local nested_ok, nested_error, nested_count = activateNestedContinuations(binding, payloads, jobs, job_ids, {
            actor = actor,
            hit_object = route.target,
            start_pos = start_pos,
            direction = direction,
            resolution_kind = "trigger_hit",
        }, options)
        if not nested_ok then
            runtime_stats.inc("live_trigger_payload_route_failed")
            return { ok = false, error = nested_error or "nested continuation activation failed" }
        end
        if (tonumber(nested_count) or 0) > 0 then
            log.info(string.format(
                "SPELLFORGE_NESTED_CONTINUATION_ACTIVATED recipe_id=%s cast_id=%s source_slot_id=%s activated_count=%s source_kind=Trigger",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.source_slot_id),
                tostring(nested_count)
            ))
        end
    end

    local nested_timer_schedule = nil
    if launch_ok and binding.nested_tt == true and binding.nested_tt_kind == "trigger_timer" then
        if options.force_timer_enabled ~= true and not dev.liveTimerEnabled() then
            runtime_stats.inc("nested_tt_rejected")
            runtime_stats.inc("nested_tt_disabled_reject")
            return { ok = false, error = "nested Trigger->Timer requires live Timer enabled" }
        end
        local nested_binding = binding.nested_timer_binding
        local first_payload = payloads[1]
        if type(nested_binding) ~= "table" or not first_payload then
            runtime_stats.inc("nested_tt_rejected")
            return { ok = false, error = "nested Trigger->Timer binding missing" }
        end
        nested_binding.actor = actor
        nested_binding.hit_object = route.target
        nested_binding.source_job_id = job_ids[1]
        nested_binding.source_projectile_id = jobs[1] and jobs[1].projectile_id or nil
        nested_binding.source_user_data = jobs[1] and jobs[1].launch_user_data or nil
        nested_binding.source_depth = 1
        nested_binding.resolution = {
            timer_start_pos = start_pos,
            timer_direction = first_payload.direction or direction,
            resolution_pos = start_pos,
            resolution_kind = "trigger_hit",
            resolution_hit_object = route.target,
        }
        nested_timer_schedule = live_timer.schedulePayload(nested_binding, {
            duplicate_key_suffix = nested_binding.duplicate_key_suffix,
        })
        if not nested_timer_schedule.ok then
            runtime_stats.inc("nested_tt_rejected")
            return { ok = false, error = nested_timer_schedule.error or "nested Trigger->Timer schedule failed" }
        end
        log.info(string.format(
            "SPELLFORGE_NESTED_TRIGGER_TIMER_INTERMEDIATE_ENQUEUED recipe_id=%s cast_id=%s root_source_slot_id=%s current_source_slot_id=%s intermediate_slot_id=%s final_payload_slot_id=%s payload_depth=1 stage_kind=Trigger->Timer job_count=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.root_source_slot_id or binding.source_slot_id),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(nested_binding.payload_slot_id),
            tostring(#job_ids)
        ))
    elseif launch_ok and binding.nested_tt == true and binding.nested_tt_kind == "timer_trigger" then
        runtime_stats.inc("nested_tt_runtime_ok")
        log.info(string.format(
            "SPELLFORGE_NESTED_TIMER_TRIGGER_FINAL_ENQUEUED recipe_id=%s cast_id=%s root_source_slot_id=%s current_source_slot_id=%s final_payload_slot_id=%s payload_depth=2 job_count=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.root_source_slot_id or binding.source_slot_id),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(#job_ids)
        ))
    end

    return {
        ok = launch_ok == true,
        error = launch_ok and nil or "trigger payload job did not complete",
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        payload_slot_id = binding.payload_slot_id,
        payload_helper_engine_id = binding.payload_helper_engine_id,
        payload_slot_ids = payloadSlotIds(payloads),
        payload_count = #payloads,
        payload_multicast = binding.payload_multicast == true,
        payload_pattern = binding.payload_pattern == true,
        payload_pattern_kind = binding.payload_pattern_kind,
        payload_pattern_direction_keys = pattern_info and pattern_info.direction_keys or nil,
        nested_final_fanout = binding.nested_final_fanout == true,
        nested_final_fanout_kind = binding.nested_final_fanout_kind,
        duplicate_key = key,
        trigger_route = trigger_route,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        job_status = jobs[1] and jobs[1].job_status or nil,
        launch_accepted = launch_ok == true,
        launch_count = launch_ok_count,
        pending_launch_jobs = pending_count > 0,
        pending_job_count = pending_count,
        all_launch_jobs_complete = pending_count == 0,
        projectile_id = projectile_ids[1],
        projectile_ids = projectile_ids,
        launch_user_data = jobs[1] and jobs[1].launch_user_data or nil,
        tick = tick,
        nested_tt = binding.nested_tt == true,
        nested_tt_kind = binding.nested_tt_kind,
        nested_timer_schedule = nested_timer_schedule,
        ir_trigger_runtime = ir_trigger_runtime_used == true,
        ir_trigger_runtime_job_count = ir_trigger_runtime_used and #job_ids or nil,
        ir_trigger_runtime_fallback_used = ir_trigger_runtime_fallback_reason ~= nil,
        ir_trigger_runtime_fallback_reason = ir_trigger_runtime_fallback_reason,
        ir_trigger_runtime_mismatch = ir_trigger_runtime_mismatch == true,
    }
end

function live_trigger.handleHitPayload(payload, opts)
    runtime_stats.inc("hits_seen")
    local route = runtime_hits.resolveHelperHit(payload)
    if not route.ok then
        return {
            ok = false,
            route = route,
            error = route.error,
        }
    end
    local result = live_trigger.handleResolvedHit(route, opts)
    result.route = route
    return result
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

function live_trigger.summary()
    return {
        bindings = countMap(bindings_by_cast_source),
        latest_bindings = countMap(bindings_by_latest_source),
        duplicate_keys = countMap(duplicate_keys),
        runtime_generation = runtime_session.currentGeneration(),
    }
end

function live_trigger.clearTransient(reason)
    local before = live_trigger.summary()
    bindings_by_cast_source = {}
    bindings_by_latest_source = {}
    binding_order = {}
    duplicate_keys = {}
    duplicate_order = {}
    log.info(string.format(
        "SPELLFORGE_LIVE_TRIGGER_CLEARED reason=%s trigger_bindings=%s duplicate_keys=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.bindings),
        tostring(before.duplicate_keys),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function live_trigger.clearForTests()
    return live_trigger.clearTransient("tests")
end

return live_trigger
