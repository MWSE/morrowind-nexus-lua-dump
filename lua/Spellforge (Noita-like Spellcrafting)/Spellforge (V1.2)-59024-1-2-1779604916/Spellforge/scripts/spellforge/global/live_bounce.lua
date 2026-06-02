local dev = require("scripts.spellforge.shared.dev")
local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.live_bounce")
local chain_target_provider = require("scripts.spellforge.global.chain_target_provider")
local helper_records = require("scripts.spellforge.global.helper_records")
local ir_runtime_adapter = require("scripts.spellforge.global.ir_runtime_adapter")
local live_chain = require("scripts.spellforge.global.live_chain")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")
local payload_pattern = require("scripts.spellforge.global.payload_pattern")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")

local live_bounce = {}

local MAX_BINDINGS = 128
local MAX_DUPLICATE_KEYS = 512

local bindings_by_cast_source = {}
local bindings_by_latest_source = {}
local binding_order = {}
local duplicate_keys = {}
local duplicate_order = {}
local bounce_event_counts_by_projectile = {}

local compactPayloadsFromBinding
local payloadSlotIds
local payloadHelperEngineIds

local function appendBounded(order, key, max_count, on_evict)
    order[#order + 1] = key
    while #order > max_count do
        local evicted = table.remove(order, 1)
        if on_evict then
            on_evict(evicted)
        end
    end
end

local function castSourceKey(recipe_id, slot_id, cast_id)
    return string.format("%s::%s::%s", tostring(recipe_id), tostring(slot_id), tostring(cast_id))
end

local function recipeSlotKey(recipe_id, slot_id)
    return string.format("%s::%s", tostring(recipe_id), tostring(slot_id))
end

local function readField(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function compactNumber(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    return string.format("%.1f", number)
end

local function compactVector(value)
    if value == nil then
        return nil
    end
    local x = compactNumber(readField(value, "x"))
    local y = compactNumber(readField(value, "y"))
    local z = compactNumber(readField(value, "z"))
    if x and y and z then
        return string.format("%s,%s,%s", x, y, z)
    end
    return tostring(value)
end

local function objectKind(value)
    if value == nil then
        return nil
    end
    return readField(value, "type")
        or readField(value, "objectType")
        or readField(value, "recordType")
        or type(value)
end

local function noteBounceEvent(projectile_id)
    if projectile_id == nil then
        return
    end
    local key = tostring(projectile_id)
    bounce_event_counts_by_projectile[key] = (bounce_event_counts_by_projectile[key] or 0) + 1
end

local function bounceBranchRoot(binding)
    if type(binding.branch_id) == "string" and binding.branch_id ~= "" then
        return binding.branch_id
    end
    if type(binding.bounce_id) == "string" and binding.bounce_id ~= "" then
        return binding.bounce_id
    end
    return string.format(
        "bounce:%s:%s",
        tostring(binding.cast_id or "no-cast"),
        tostring(binding.source_slot_id or "no-source")
    )
end

local function bounceBranchScope(binding)
    if type(binding.branch_scope) == "string" and binding.branch_scope ~= "" then
        return binding.branch_scope
    end
    return bounceBranchRoot(binding)
end

local function bounceBranchParentId(binding)
    return bounceBranchRoot(binding)
end

local function sourceBranchInfo(binding)
    if type(binding.branch_id) == "string" and binding.branch_id ~= "" then
        return {
            branch_scope = binding.branch_scope or binding.branch_id,
            branch_parent_id = binding.branch_parent_id or binding.branch_id,
            branch_id = binding.branch_id,
            branch_kind = binding.branch_kind or "bounce_source",
            branch_index = binding.branch_index or 1,
            branch_count = binding.branch_count or 1,
        }
    end
    local parent_id = bounceBranchParentId(binding)
    return {
        branch_scope = bounceBranchScope(binding),
        branch_parent_id = parent_id,
        branch_id = parent_id .. ":source",
        branch_kind = binding.branch_kind or "bounce_source",
        branch_index = binding.branch_index or 1,
        branch_count = binding.branch_count or 1,
    }
end

local function eventBranchInfo(binding, route, kind)
    local bounce_index = tonumber(route and route.bounce_index) or 0
    local parent_id = bounceBranchParentId(binding)
    local role = kind or "event"
    return {
        branch_scope = string.format(
            "%s:b%s",
            tostring(bounceBranchScope(binding)),
            tostring(bounce_index)
        ),
        branch_parent_id = parent_id,
        branch_id = string.format("%s:b%s:%s", tostring(parent_id), tostring(bounce_index), tostring(role)),
        branch_kind = "bounce_" .. tostring(role),
        branch_index = bounce_index,
        branch_count = tonumber(binding.bounce_max) or 1,
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

local function shallowCopy(value)
    local out = {}
    for key, item in pairs(value or {}) do
        out[key] = item
    end
    return out
end

local function irBounceRuntimeEnabled(options)
    if options and options.force_ir_bounce_runtime_disabled == true then
        return false
    end
    return (options and options.force_ir_bounce_runtime_enabled == true)
        or dev.irBounceRuntimeEnabled()
end

local function irPlannerOptions(binding, options)
    return {
        allow_payload_multicast = binding.payload_multicast == true
            or (options and options.allow_payload_multicast == true)
            or (options and options.force_payload_multicast_enabled == true)
            or binding.force_payload_multicast_enabled == true,
        allow_payload_pattern = binding.payload_pattern == true
            or (options and options.allow_payload_pattern == true)
            or (options and options.force_payload_pattern_enabled == true)
            or binding.force_payload_pattern_enabled == true,
        allow_chain_runtime = binding.has_chain_payload == true
            or (options and options.force_chain_runtime_enabled == true),
        max_depth = options and options.max_depth or limits.MAX_RECURSION_DEPTH,
        max_jobs = binding.max_payload_fanout or (options and options.max_jobs),
        max_fanout = binding.max_payload_fanout or (options and options.max_fanout),
        max_projectiles = binding.max_projectiles or (options and options.max_projectiles),
        max_bounce_count = binding.bounce_max or (options and options.max_bounce_count),
        max_chain_hops = binding.chain_max_hops or (options and options.max_chain_hops),
        max_chain_jobs = options and options.max_chain_jobs,
        max_live_launches_per_tick = binding.max_live_launches_per_tick
            or (options and options.max_live_launches_per_tick),
        chaos_budget_profile = binding.chaos_budget_profile or (options and options.chaos_budget_profile),
    }
end

local function irBounceFallback(binding, reason, marker)
    runtime_stats.inc("ir_bounce_runtime_fallback")
    log.info(string.format(
        "%s recipe_id=%s cast_id=%s bounce_id=%s source_slot_id=%s reason=%s",
        marker or "SPELLFORGE_IR_BOUNCE_RUNTIME_FALLBACK",
        tostring(binding and binding.recipe_id),
        tostring(binding and binding.cast_id),
        tostring(binding and binding.bounce_id),
        tostring(binding and binding.source_slot_id),
        tostring(reason)
    ))
    return {
        fallback = true,
        reason = reason,
        mismatch = marker == "SPELLFORGE_IR_BOUNCE_RUNTIME_MISMATCH",
    }
end

local function irBounceMismatch(binding, reason)
    runtime_stats.inc("ir_bounce_runtime_mismatch")
    return irBounceFallback(binding, reason, "SPELLFORGE_IR_BOUNCE_RUNTIME_MISMATCH")
end

local function hasOps(ops)
    return type(ops) == "table" and #ops > 0
end

local function countOpcode(ops, opcode)
    local count = 0
    local first = nil
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            count = count + 1
            first = first or op
        end
    end
    return count, first
end

local function sourceModifierPolicyAccepts(options, entry)
    if not hasOps(entry and entry.prefix_ops) or #(entry.prefix_ops or {}) <= 1 then
        return true, nil
    end
    local policy = options and options.source_modifier_policy or nil
    if type(policy) ~= "table" or policy.ok ~= true then
        return false, policy and policy.rejection_reason or "source_modifier_unsupported_prefix"
    end
    if policy.mutations and policy.mutations.source_modifier_kind ~= nil then
        return true, nil
    end
    return false, "source_modifier_unsupported_prefix"
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

local function postfixIsEmptyOrTrigger(value)
    local ops = value and value.postfix_ops or nil
    if not hasOps(ops) then
        return true
    end
    return #ops == 1 and ops[1] and ops[1].opcode == "Trigger"
end

local function hasTriggerPostfix(value)
    local count = countOpcode(value and value.postfix_ops or nil, "Trigger")
    return count == 1
end

local function clampBounceCount(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = 1
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    end
    local max = tonumber(limits.MAX_BOUNCE_COUNT_HARD) or 12
    if n > max then
        n = max
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

local function rejectSelect(reason, counter_name)
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return nil, reason
end

local function selectBounceTriggerChainPayload(plan, options)
    local chain_plan, reason, audit = live_chain.selectV0Plan(plan, {
        max_hops = options.max_chain_hops or limits.MAX_CHAIN_HOPS,
        max_jobs = options.max_chain_jobs or limits.MAX_CHAIN_JOBS_PER_CAST,
        max_candidates = options.max_chain_scan_candidates or options.candidate_cap or limits.MAX_CHAIN_SCAN_CANDIDATES,
        scan_radius = options.chain_scan_radius or options.scan_radius,
    })
    if not chain_plan then
        return nil, reason, audit
    end
    if chain_plan.chain_shape ~= "trigger_payload_chain" then
        return nil, "bounce_chain_deferred", audit
    end
    if chain_plan.payload_modifier_kind ~= nil then
        return nil, "bounce_chain_modifier_deferred", audit
    end
    return chain_plan, nil, audit
end

local function compactChainPayload(chain_payload_plan, source_slot)
    if type(chain_payload_plan) ~= "table" then
        return nil
    end
    return {
        slot_id = chain_payload_plan.payload_slot_id,
        helper_engine_id = chain_payload_plan.payload_helper_engine_id,
        effect_id = chain_payload_plan.payload_effect_id,
        parent_slot_id = source_slot and source_slot.slot_id or chain_payload_plan.source_slot_id,
        root_source_slot_id = chain_payload_plan.source_slot_id,
        current_source_slot_id = chain_payload_plan.payload_slot_id,
        payload_depth = 1,
    }
end

local function triggerPayloadHasChain(plan, source_slot_id)
    for _, slot in ipairs(plan.emission_slots or {}) do
        if slot
            and slot.parent_slot_id == source_slot_id
            and slot.source_postfix_opcode == "Trigger" then
            local chain_count = countOpcode(slot.prefix_ops, "Chain")
            if chain_count > 0 then
                return true
            end
        end
    end
    return false
end

function live_bounce.selectV0Plan(plan, opts)
    local options = opts or {}
    if type(plan) ~= "table" then
        return rejectSelect("missing_plan")
    end

    local bounds = plan.bounds or {}
    local chain_payload_plan = nil
    local chain_payload_reason = nil
    if bounds.has_chain then
        chain_payload_plan, chain_payload_reason = selectBounceTriggerChainPayload(plan, options)
        if not chain_payload_plan then
            return rejectSelect(chain_payload_reason or "bounce_chain_deferred", "live_bounce_chain_reject")
        end
    end
    if bounds.has_homing then
        return rejectSelect("homing_bounce_physics_unsupported", "live_bounce_homing_reject")
    end
    if bounds.has_multicast or bounds.has_pattern then
        return rejectSelect("bounce_fanout_deferred", "live_bounce_fanout_reject")
    end
    if bounds.group_count ~= 1 then
        return rejectSelect("not_single_group")
    end
    if tonumber(bounds.static_emission_count) ~= 1 then
        return rejectSelect("not_single_source_emission")
    end

    local group = plan.groups and plan.groups[1] or nil
    if type(group) ~= "table" then
        return rejectSelect("missing_group")
    end
    local bounce_count, bounce_op = countOpcode(group.prefix_ops, "Bounce")
    if bounce_count ~= 1 then
        return rejectSelect("missing_bounce_op")
    end
    local group_prefix_ok, group_prefix_reason = sourceModifierPolicyAccepts(options, group)
    if not group_prefix_ok then
        return rejectSelect(group_prefix_reason or "source_modifier_unsupported_prefix", "live_bounce_modifier_reject")
    end
    if not postfixIsEmptyOrTrigger(group) then
        return rejectSelect("bounce_postfix_deferred", "live_bounce_trigger_timer_reject")
    end

    local slots = plan.emission_slots or {}
    local helpers = plan.helper_records or {}
    local source_slot = nil
    for _, slot in ipairs(slots) do
        if slot.kind == "primary_emission" then
            if source_slot then
                return rejectSelect("multiple_bounce_sources")
            end
            source_slot = slot
        end
    end
    if not source_slot then
        return rejectSelect("missing_bounce_source_slot")
    end
    if source_slot.parent_slot_id ~= nil or source_slot.source_postfix_opcode ~= nil then
        return rejectSelect("source_slot_not_primary")
    end
    local slot_bounce_count, _ = countOpcode(source_slot.prefix_ops, "Bounce")
    local slot_prefix_ok, slot_prefix_reason = sourceModifierPolicyAccepts(options, source_slot)
    if slot_bounce_count ~= 1 or not slot_prefix_ok then
        if slot_bounce_count == 1 then
            return rejectSelect(slot_prefix_reason or "source_modifier_unsupported_prefix", "live_bounce_modifier_reject")
        end
        return rejectSelect("source_slot_not_bounce")
    end
    if not postfixIsEmptyOrTrigger(source_slot) then
        return rejectSelect("source_slot_postfix_deferred")
    end

    local helpers_by_slot = helperBySlotId(helpers)
    local source_helper = helpers_by_slot[source_slot.slot_id]
    if not source_helper or type(source_helper.engine_id) ~= "string" or source_helper.engine_id == "" then
        return rejectSelect("source_helper_missing")
    end
    if source_helper.parent_slot_id ~= nil or source_helper.source_postfix_opcode ~= nil then
        return rejectSelect("source_helper_not_primary")
    end
    local helper_bounce_count, _ = countOpcode(source_helper.prefix_ops, "Bounce")
    local helper_prefix_ok, helper_prefix_reason = sourceModifierPolicyAccepts(options, source_helper)
    if helper_bounce_count ~= 1 or not helper_prefix_ok then
        if helper_bounce_count == 1 then
            return rejectSelect(helper_prefix_reason or "source_modifier_unsupported_prefix", "live_bounce_modifier_reject")
        end
        return rejectSelect("source_helper_not_bounce")
    end
    if not postfixIsEmptyOrTrigger(source_helper) then
        return rejectSelect("source_helper_postfix_deferred")
    end

    local bounce_max = clampBounceCount(bounce_op and bounce_op.params and bounce_op.params.bounces)
    local effective_cap = tonumber(options.max_bounce_count) or limits.MAX_BOUNCE_COUNT
    if bounce_max > effective_cap then
        runtime_stats.inc("live_bounce_cap_reject")
        return rejectSelect("bounce_count_cap_exceeded")
    end
    local bounce_power = clampBouncePower(bounce_op and bounce_op.params and bounce_op.params.power)
    local has_trigger_payload = hasTriggerPostfix(source_slot)

    if has_trigger_payload and chain_payload_plan == nil and triggerPayloadHasChain(plan, source_slot.slot_id) then
        chain_payload_plan, chain_payload_reason = selectBounceTriggerChainPayload(plan, options)
        if not chain_payload_plan then
            return rejectSelect(chain_payload_reason or "bounce_chain_deferred", "live_bounce_chain_reject")
        end
    end

    local payload_result = nil
    if has_trigger_payload then
        if chain_payload_plan then
            if chain_payload_plan.source_slot_id ~= source_slot.slot_id then
                return rejectSelect("bounce_chain_deferred", "live_bounce_chain_reject")
            end
            payload_result = {
                ok = true,
                payload_slot_id = chain_payload_plan.payload_slot_id,
                payload_helper_engine_id = chain_payload_plan.payload_helper_engine_id,
                payload_slots = { compactChainPayload(chain_payload_plan, source_slot) },
                payload_slot_ids = { chain_payload_plan.payload_slot_id },
                payload_helper_engine_ids = { chain_payload_plan.payload_helper_engine_id },
                payload_count = 1,
                payload_group_key = "bounce_trigger_chain_payload",
                payload_effect_id = chain_payload_plan.payload_effect_id,
                chain_plan = chain_payload_plan,
            }
            runtime_stats.inc("live_bounce_chain_payload_qualified")
        else
            payload_result = payload_multicast.resolvePayloadHelpersForSource(plan, source_slot, {
                source_opcode = "Trigger",
                allow_payload_multicast = options.allow_payload_multicast == true,
                allow_payload_pattern = options.allow_payload_pattern == true,
                max_depth = options.max_depth,
                max_jobs = options.max_jobs,
                max_fanout = options.max_fanout,
                max_projectiles = options.max_projectiles,
                allowed_primary_prefix_ops = { Bounce = true },
            })
            if payload_result.detected_payload_multicast then
                runtime_stats.inc("payload_multicast_attempts")
            end
            if payload_result.detected_payload_pattern then
                runtime_stats.inc("payload_pattern_attempts")
            end
            if not payload_result.ok then
                local reason = payload_result.rejection_reason or "bounce_trigger_payload_resolution_failed"
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
                    else
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
                local counter = nil
                if reason == "nested_payload_runtime_deferred" then
                    counter = "live_bounce_nested_payload_reject"
                end
                return rejectSelect(reason, counter)
            end
            if payload_result.is_payload_multicast then
                runtime_stats.inc("payload_multicast_qualified")
            end
            if payload_result.is_payload_pattern then
                runtime_stats.inc("payload_pattern_qualified")
            end
        end
    elseif group.payload and type(group.payload.effects) == "table" and #group.payload.effects > 0 then
        return rejectSelect("bounce_payload_without_trigger_deferred")
    end

    return {
        ok = true,
        source = {
            slot = source_slot,
            helper = source_helper,
        },
        source_slot_id = source_slot.slot_id,
        source_helper_engine_id = source_helper.engine_id,
        bounce_op = bounce_op,
        bounce_max = bounce_max,
        bounce_power = bounce_power,
        detonate_on_actor_hit = false,
        has_trigger_payload = has_trigger_payload,
        has_chain_payload = chain_payload_plan ~= nil,
        chain_plan = chain_payload_plan,
        chain_requested_hops = chain_payload_plan and chain_payload_plan.requested_hops or nil,
        chain_max_hops = chain_payload_plan and chain_payload_plan.max_hops or nil,
        chain_shape = chain_payload_plan and chain_payload_plan.chain_shape or nil,
        payload_slot_id = payload_result and payload_result.payload_slot_id or nil,
        payload_helper_engine_id = payload_result and payload_result.payload_helper_engine_id or nil,
        payloads = payload_result and payload_result.payload_slots or nil,
        payload_slot_ids = payload_result and payload_result.payload_slot_ids or nil,
        payload_helper_engine_ids = payload_result and payload_result.payload_helper_engine_ids or nil,
        payload_count = payload_result and payload_result.payload_count or 0,
        payload_group_key = payload_result and payload_result.payload_group_key or nil,
        payload_effect_id = payload_result and payload_result.payload_effect_id or nil,
        payload_effect_ids = payload_result and payload_result.payload_effect_ids or nil,
        payload_multicast = payload_result and payload_result.is_payload_multicast == true or false,
        payload_pattern = payload_result and payload_result.is_payload_pattern == true or false,
        payload_pattern_kind = payload_result and payload_result.pattern_kind or nil,
        payload_pattern_op = payload_result and payload_result.pattern_op or nil,
        payload_multicast_fanout_count = payload_result and payload_result.fanout_count or nil,
        max_payload_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT,
        max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST,
        max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
        max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        chaos_budget_profile = options.chaos_budget_profile,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
    }, nil
end

function live_bounce.decorateSourceJob(job, binding)
    if type(job) ~= "table" or type(binding) ~= "table" then
        return
    end
    local branch = sourceBranchInfo(binding)
    job.bounceEnabled = true
    job.bounceMax = binding.bounce_max
    job.bouncePower = binding.bounce_power
    job.detonateOnActorHit = false
    job.bounce_runtime = true
    job.bounce_role = "source"
    job.bounce_id = binding.bounce_id
    job.bounce_max = binding.bounce_max
    job.bounce_power = binding.bounce_power
    job.bounce_detonate_on_actor_hit = false
    job.bounce_trigger_payload_slot_id = binding.payload_slot_id
    job.source_prefix_opcode = "Bounce"
    job.source_postfix_opcode = binding.has_trigger_payload and "Trigger" or nil
    job.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    job.trigger_source_slot_id = binding.has_trigger_payload and binding.source_slot_id or nil
    job.trigger_payload_slot_id = binding.payload_slot_id
    job.trigger_payload_slot_ids = binding.payload_slot_ids
    job.has_trigger_payload = binding.has_trigger_payload == true
    job.has_chain_payload = binding.has_chain_payload == true
    job.payload_multicast = binding.payload_multicast == true
    job.payload_pattern = binding.payload_pattern == true
    job.payload_pattern_kind = binding.payload_pattern_kind
    job.chain_runtime = binding.has_chain_payload == true or job.chain_runtime == true
    job.chain_id = binding.chain_id
    job.chain_hop_index = binding.has_chain_payload == true and 0 or job.chain_hop_index
    job.chain_max_hops = binding.chain_max_hops
    job.chain_targeting_mode = binding.chain_targeting_mode
    job.payload_count = tonumber(binding.payload_count) or nil
    copyBranchFields(job, branch)

    job.payload = job.payload or {}
    job.payload.bounceEnabled = true
    job.payload.bounceMax = binding.bounce_max
    job.payload.bouncePower = binding.bounce_power
    job.payload.detonateOnActorHit = false
    job.payload.bounce_runtime = true
    job.payload.bounce_role = "source"
    job.payload.bounce_id = binding.bounce_id
    job.payload.bounce_max = binding.bounce_max
    job.payload.bounce_power = binding.bounce_power
    job.payload.bounce_detonate_on_actor_hit = false
    job.payload.bounce_trigger_payload_slot_id = binding.payload_slot_id
    job.payload.source_prefix_opcode = "Bounce"
    job.payload.source_postfix_opcode = binding.has_trigger_payload and "Trigger" or nil
    job.payload.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.payload.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    job.payload.trigger_source_slot_id = binding.has_trigger_payload and binding.source_slot_id or nil
    job.payload.trigger_payload_slot_id = binding.payload_slot_id
    job.payload.trigger_payload_slot_ids = binding.payload_slot_ids
    job.payload.has_trigger_payload = binding.has_trigger_payload == true
    job.payload.has_chain_payload = binding.has_chain_payload == true
    job.payload.payload_multicast = binding.payload_multicast == true
    job.payload.payload_pattern = binding.payload_pattern == true
    job.payload.payload_pattern_kind = binding.payload_pattern_kind
    job.payload.chain_runtime = binding.has_chain_payload == true or job.payload.chain_runtime == true
    job.payload.chain_id = binding.chain_id
    job.payload.chain_hop_index = binding.has_chain_payload == true and 0 or job.payload.chain_hop_index
    job.payload.chain_max_hops = binding.chain_max_hops
    job.payload.chain_targeting_mode = binding.chain_targeting_mode
    job.payload.payload_count = tonumber(binding.payload_count) or nil
    copyBranchFields(job.payload, branch)
end

function live_bounce.registerBinding(binding)
    local input = binding or {}
    local payloads = compactPayloadsFromBinding(input)
    if type(input.recipe_id) ~= "string" or input.recipe_id == ""
        or type(input.source_slot_id) ~= "string" or input.source_slot_id == ""
        or type(input.source_helper_engine_id) ~= "string" or input.source_helper_engine_id == "" then
        return false
    end
    if input.has_trigger_payload == true and #payloads == 0 then
        return false
    end
    if #payloads > 0 then
        input.payloads = payloads
        input.payload_slot_ids = payloadSlotIds(payloads)
        input.payload_helper_engine_ids = payloadHelperEngineIds(payloads)
        input.payload_count = #payloads
        input.payload_slot_id = input.payload_slot_id or payloads[1].slot_id
        input.payload_helper_engine_id = input.payload_helper_engine_id or payloads[1].helper_engine_id
    end
    input.runtime_generation = runtime_session.currentGeneration()
    local cast_key = castSourceKey(input.recipe_id, input.source_slot_id, input.cast_id)
    local latest_key = recipeSlotKey(input.recipe_id, input.source_slot_id)
    bindings_by_cast_source[cast_key] = input
    bindings_by_latest_source[latest_key] = input
    appendBounded(binding_order, cast_key, MAX_BINDINGS, function(evicted)
        local evicted_binding = bindings_by_cast_source[evicted]
        bindings_by_cast_source[evicted] = nil
        if evicted_binding then
            local evicted_latest = recipeSlotKey(evicted_binding.recipe_id, evicted_binding.source_slot_id)
            if bindings_by_latest_source[evicted_latest] == evicted_binding then
                bindings_by_latest_source[evicted_latest] = nil
            end
        end
    end)
    return true
end

local function bindingForRoute(route)
    local user_data = route.user_data or {}
    local cast_key = castSourceKey(route.recipe_id, route.slot_id, user_data.cast_id)
    return bindings_by_cast_source[cast_key] or bindings_by_latest_source[recipeSlotKey(route.recipe_id, route.slot_id)]
end

local function duplicateKey(route, binding)
    return string.format(
        "bounce:%s:%s:%s:%s:%s:%s",
        tostring(binding.cast_id or (route.user_data and route.user_data.cast_id) or "no-cast"),
        tostring(binding.recipe_id or route.recipe_id),
        tostring(binding.source_slot_id or route.slot_id),
        tostring(binding.source_helper_engine_id or route.helper_engine_id),
        tostring(route.projectile_id or "no-projectile"),
        tostring(route.bounce_index or "no-bounce")
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

compactPayloadsFromBinding = function(binding)
    local payloads = {}
    if type(binding and binding.payloads) == "table" and #binding.payloads > 0 then
        for index, payload in ipairs(binding.payloads) do
            local payload_slot = type(payload.slot) == "table" and payload.slot or nil
            local payload_helper = type(payload.helper) == "table" and payload.helper or nil
            payloads[index] = {
                slot_id = payload.slot_id or (payload_slot and payload_slot.slot_id),
                helper_engine_id = payload.helper_engine_id
                    or payload.engine_id
                    or (payload_helper and (payload_helper.engine_id or payload_helper.helper_engine_id)),
                effect_id = payload.effect_id,
                emission_index = payload.emission_index,
                group_index = payload.group_index,
                direction = payload.direction,
                pattern_kind = payload.pattern_kind,
                pattern_index = payload.pattern_index,
                pattern_count = payload.pattern_count,
                pattern_direction_key = payload.pattern_direction_key,
                parent_slot_id = payload.parent_slot_id or (payload_slot and payload_slot.parent_slot_id),
                root_source_slot_id = payload.root_source_slot_id or (payload_slot and payload_slot.root_source_slot_id),
                current_source_slot_id = payload.current_source_slot_id or (payload_slot and payload_slot.current_source_slot_id),
                payload_depth = payload.payload_depth or (payload_slot and payload_slot.payload_depth),
                nested_stage_kind = payload.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
            }
        end
    elseif type(binding and binding.payload_slot_id) == "string" and type(binding.payload_helper_engine_id) == "string" then
        payloads[1] = {
            slot_id = binding.payload_slot_id,
            helper_engine_id = binding.payload_helper_engine_id,
            effect_id = binding.payload_effect_id,
        }
    end
    return payloads
end

payloadSlotIds = function(payloads)
    local ids = {}
    for index, payload in ipairs(payloads or {}) do
        ids[index] = payload.slot_id
    end
    return ids
end

payloadHelperEngineIds = function(payloads)
    local ids = {}
    for index, payload in ipairs(payloads or {}) do
        ids[index] = payload.helper_engine_id
    end
    return ids
end

local function fanoutBranchInfo(binding, route, payload, index, count)
    local bounce_index = tonumber(route and route.bounce_index) or 0
    local parent_id = bounceBranchParentId(binding)
    local payload_slot_id = payload and payload.slot_id or binding.payload_slot_id or "no-payload"
    local kind = "bounce_trigger_payload_multicast"
    if binding.payload_pattern == true then
        kind = "bounce_trigger_payload_pattern"
    end
    return {
        branch_scope = string.format(
            "%s:b%s",
            tostring(bounceBranchScope(binding)),
            tostring(bounce_index)
        ),
        branch_parent_id = parent_id,
        branch_id = string.format(
            "%s:b%s:trigger_payload:%s:%s",
            tostring(parent_id),
            tostring(bounce_index),
            tostring(index),
            tostring(payload_slot_id)
        ),
        branch_kind = kind,
        branch_index = index,
        branch_count = count,
    }
end

local function validateIrBounceJobPlan(binding, payloads, continuation_plan, job_plan, expected_kind)
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
        if expected_kind ~= nil and job.kind ~= expected_kind then
            return false, "job_kind_mismatch"
        end
    end
    return true, nil
end

local function buildIrBounceRuntimePlan(route, binding, options, payloads, is_final, expected_kind)
    if not irBounceRuntimeEnabled(options) then
        return nil
    end

    runtime_stats.inc("ir_bounce_runtime_attempts")
    local plan = binding.plan or binding.compiled_plan or binding.attached_plan
    local planner_options = irPlannerOptions(binding, options)
    local source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    local event = {
        event_kind = "bounce",
        source_slot_id = binding.source_slot_id,
        source_prefix_opcode = "Bounce",
        source_postfix_opcode = binding.has_trigger_payload == true and "Trigger" or nil,
        cast_id = binding.cast_id,
        source_job_id = source_job_id,
        parent_job_id = source_job_id,
        bounce_id = binding.bounce_id,
        bounce_index = route.bounce_index,
        bounce_max = binding.bounce_max,
        bounce_power = binding.bounce_power,
        bounce_final = is_final == true,
        chain_id = binding.chain_id,
        chain_hop_index = 0,
        chain_max_hops = binding.chain_max_hops,
        chain_targeting_mode = binding.chain_targeting_mode,
        branch_scope = bounceBranchScope(binding),
        branch_parent_id = bounceBranchParentId(binding),
    }
    local planned = ir_runtime_adapter.planEvent(binding, plan, event, planner_options)
    if planned.ok ~= true then
        if planned.stage == "ir" then
            return irBounceFallback(binding, planned.rejection_reason)
        end
        return irBounceMismatch(binding, planned.rejection_reason or "continuation_plan_failed")
    end
    local continuation_plan = planned.continuation_plan
    local job_plan = planned.job_plan
    local valid, reason = validateIrBounceJobPlan(binding, payloads or {}, continuation_plan, job_plan, expected_kind)
    if not valid then
        return irBounceMismatch(binding, reason)
    end

    return {
        ok = true,
        continuation_plan = continuation_plan,
        job_plan = job_plan,
        event = event,
    }
end

local function noteIrBounceRuntimePlanned(route, binding, options, payloads, is_final, expected_kind, role)
    local ir_runtime = buildIrBounceRuntimePlan(route, binding, options, payloads, is_final, expected_kind)
    if ir_runtime == nil then
        return nil
    end
    if ir_runtime.ok ~= true then
        return ir_runtime
    end
    local counter = role == "chain_handoff" and "ir_bounce_runtime_chain_handoff_planned"
        or role == "trigger_payload_detonation" and "ir_bounce_runtime_detonation_planned"
        or "ir_bounce_runtime_planned"
    runtime_stats.inc(counter)
    log.info(string.format(
        "SPELLFORGE_IR_BOUNCE_RUNTIME_PLANNED role=%s recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s source_slot_id=%s payload_count=%s job_count=%s branch_kind=%s",
        tostring(role),
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.source_slot_id),
        tostring(#(payloads or {})),
        tostring(ir_runtime.job_plan and ir_runtime.job_plan.planned_job_count or nil),
        tostring(ir_runtime.job_plan and ir_runtime.job_plan.planned_jobs and ir_runtime.job_plan.planned_jobs[1] and ir_runtime.job_plan.planned_jobs[1].branch_kind or nil)
    ))
    return ir_runtime
end

local function enrichIrBounceTriggerPayload(planned_job, binding, route, payload, index, count, duplicate_key, is_final, actor, start_pos, direction)
    local branch = fanoutBranchInfo(binding, route, payload, index, count)
    local payload_launch = shallowCopy(planned_job.payload or {})
    payload_launch.actor = actor
    payload_launch.start_pos = start_pos
    payload_launch.direction = payload.direction or direction
    payload_launch.hit_object = route.target
    payload_launch.cast_id = binding.cast_id
    payload_launch.source_slot_id = binding.source_slot_id
    payload_launch.source_prefix_opcode = "Bounce"
    payload_launch.source_helper_engine_id = binding.source_helper_engine_id
    payload_launch.source_postfix_opcode = "Trigger"
    payload_launch.root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id or binding.source_slot_id
    payload_launch.current_source_slot_id = payload.current_source_slot_id or payload.slot_id
    payload_launch.parent_slot_id = payload.parent_slot_id or binding.source_slot_id
    payload_launch.payload_depth = payload.payload_depth or 1
    payload_launch.nested_stage_kind = payload.nested_stage_kind
    payload_launch.nested_stage_index = payload.nested_stage_index
    payload_launch.has_trigger_payload = payload.has_trigger_payload
    payload_launch.has_timer_payload = payload.has_timer_payload
    payload_launch.payload_slot_id = payload.slot_id
    payload_launch.trigger_source_slot_id = binding.source_slot_id
    payload_launch.trigger_payload_slot_id = payload.slot_id
    payload_launch.trigger_route = "bounce"
    payload_launch.trigger_duplicate_key = shortKey(duplicate_key)
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
    payload_launch.bounce_runtime = true
    payload_launch.bounce_role = "trigger_payload_launch"
    payload_launch.bounce_id = binding.bounce_id
    payload_launch.bounce_index = route.bounce_index
    payload_launch.bounce_max = binding.bounce_max
    payload_launch.bounce_power = binding.bounce_power
    payload_launch.bounce_detonate_on_actor_hit = false
    payload_launch.bounce_trigger_payload_slot_id = payload.slot_id
    payload_launch.bounce_final = is_final == true
    payload_launch.mute_audio = binding.mute_audio
    payload_launch.mute_light = binding.mute_light
    copyBranchFields(payload_launch, branch)

    local job = shallowCopy(planned_job)
    job.kind = orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND
    job.recipe_id = binding.recipe_id
    job.slot_id = payload.slot_id
    job.helper_engine_id = payload.helper_engine_id
    job.idempotency_key = string.format("%s:%s", tostring(duplicate_key), tostring(payload.slot_id))
    job.source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    job.parent_job_id = job.source_job_id
    job.depth = 1
    job.cast_id = binding.cast_id
    job.emission_index = payload.emission_index
    job.group_index = payload.group_index
    job.fanout_count = count
    job.max_live_launches_per_tick = binding.max_live_launches_per_tick
    job.chaos_budget_profile = binding.chaos_budget_profile
    job.root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id or binding.source_slot_id
    job.current_source_slot_id = payload.current_source_slot_id or payload.slot_id
    job.parent_slot_id = payload.parent_slot_id or binding.source_slot_id
    job.payload_depth = payload.payload_depth or 1
    job.nested_stage_kind = payload.nested_stage_kind
    job.nested_stage_index = payload.nested_stage_index
    job.has_trigger_payload = payload.has_trigger_payload
    job.has_timer_payload = payload.has_timer_payload
    job.pattern_kind = payload.pattern_kind
    job.pattern_index = payload.pattern_index
    job.pattern_count = payload.pattern_count
    job.pattern_direction_key = payload.pattern_direction_key
    job.source_slot_id = binding.source_slot_id
    job.source_prefix_opcode = "Bounce"
    job.source_helper_engine_id = binding.source_helper_engine_id
    job.source_postfix_opcode = "Trigger"
    job.payload_slot_id = payload.slot_id
    job.trigger_route = "bounce"
    job.trigger_duplicate_key = shortKey(duplicate_key)
    job.bounce_runtime = true
    job.bounce_role = "trigger_payload_launch"
    job.bounce_id = binding.bounce_id
    job.bounce_index = route.bounce_index
    job.bounce_max = binding.bounce_max
    job.bounce_power = binding.bounce_power
    job.bounce_detonate_on_actor_hit = false
    job.bounce_trigger_payload_slot_id = payload.slot_id
    job.bounce_final = is_final == true
    copyBranchFields(job, branch)
    job.payload = payload_launch
    return job
end

local function enqueueIrBounceRuntime(route, binding, duplicate_key, is_final, options, payloads, actor, start_pos, direction)
    local ir_runtime = buildIrBounceRuntimePlan(
        route,
        binding,
        options,
        payloads,
        is_final,
        orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND
    )
    if ir_runtime == nil then
        return nil
    end
    if ir_runtime.ok ~= true then
        return ir_runtime
    end

    local job_ids = {}
    for index, payload in ipairs(payloads or {}) do
        local planned_job = ir_runtime.job_plan.planned_jobs[index]
        local job = enrichIrBounceTriggerPayload(
            planned_job,
            binding,
            route,
            payload,
            index,
            #payloads,
            duplicate_key,
            is_final,
            actor,
            start_pos,
            direction
        )
        local enqueue = orchestrator.enqueue(job)
        if not enqueue.ok then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            return {
                ok = false,
                error = enqueue.error or "IR bounce trigger payload enqueue failed",
                job_ids = job_ids,
                ir_bounce_runtime = true,
            }
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end

    runtime_stats.inc("ir_bounce_runtime_enqueued")
    runtime_stats.inc("ir_bounce_runtime_jobs_enqueued", #job_ids)
    local first_job = orchestrator.getJob(job_ids[1])
    log.info(string.format(
        "SPELLFORGE_IR_BOUNCE_RUNTIME_ENQUEUED recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s source_slot_id=%s payload_count=%s first_job_id=%s branch_kind=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(job_ids[1]),
        tostring(first_job and first_job.branch_kind or nil)
    ))
    return {
        ok = true,
        job_ids = job_ids,
        ir_bounce_runtime = true,
    }
end

local function routeFromBouncePayload(payload)
    local data = payload or {}
    local user_data = sfp_userdata.extract(data)
    local spellforge_user_data = sfp_userdata.isSpellforgeUserData(user_data) and user_data or nil
    local spell_id = data.spellId or data.spell_id
    local helper_engine_id = spellforge_user_data and spellforge_user_data.helper_engine_id or spell_id
    local mapping = helper_records.getByEngineId(helper_engine_id) or helper_records.getByEngineId(spell_id)
    local projectile, projectile_id, projectile_id_source = sfp_adapter.extractProjectileFromHit(data)
    if not mapping then
        return { ok = false, error = "bounce helper mapping missing" }
    end
    return {
        ok = true,
        source = "bounce",
        spell_id = spell_id,
        recipe_id = mapping.recipe_id,
        slot_id = mapping.slot_id,
        helper_engine_id = mapping.engine_id,
        mapping = mapping,
        attacker = data.attacker,
        target = data.hitObject or data.hit_object,
        hit_pos = data.hitPos or data.hit_pos,
        hit_normal = data.hitNormal or data.hit_normal,
        bounce_direction = data.hitNormal or data.hit_normal,
        bounce_index = tonumber(data.bounceCount or data.bounce_count) or 0,
        speed = data.speed,
        user_data = spellforge_user_data,
        projectile = projectile,
        projectile_id = projectile_id,
        projectile_id_source = projectile_id_source,
    }
end

local function objectCell(value)
    return readField(value, "cell")
end

local function objectToken(value)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return tostring(value)
    end
    return readField(value, "id")
        or readField(value, "recordId")
        or readField(value, "refId")
        or readField(value, "name")
        or objectToken(readField(value, "object"))
end

local function rawBounceEventInfo(payload)
    local data = payload or {}
    local user_data = sfp_userdata.extract(data)
    local spellforge_user_data = sfp_userdata.isSpellforgeUserData(user_data) and user_data or nil
    local spell_id = data.spellId or data.spell_id
    local projectile, projectile_id, projectile_id_source = sfp_adapter.extractProjectileFromHit(data)
    local hit_object = data.hitObject or data.hit_object or data.target
    return {
        spell_id = spell_id,
        helper_engine_id = spellforge_user_data and spellforge_user_data.helper_engine_id or spell_id,
        recipe_id = spellforge_user_data and spellforge_user_data.recipe_id or nil,
        slot_id = spellforge_user_data and spellforge_user_data.slot_id or nil,
        cast_id = spellforge_user_data and spellforge_user_data.cast_id or nil,
        projectile = projectile,
        projectile_id = projectile_id,
        projectile_id_source = projectile_id_source,
        bounce_index = tonumber(data.bounceCount or data.bounce_count) or 0,
        hit_object = hit_object,
        hit_object_id = objectToken(hit_object),
        hit_object_type = objectKind(hit_object),
        hit_object_cell = objectToken(objectCell(hit_object)) or (objectCell(hit_object) and tostring(objectCell(hit_object)) or nil),
        hit_pos = data.hitPos or data.hit_pos,
        hit_normal = data.hitNormal or data.hit_normal,
        has_user_data = spellforge_user_data ~= nil,
    }
end

local function logBounceEventSeen(info, route, route_ok, reason)
    local event = info or {}
    local resolved_route = route or {}
    log.info(string.format(
        "SPELLFORGE_BOUNCE_EVENT_SEEN spell_id=%s helper_engine_id=%s recipe_id=%s slot_id=%s cast_id=%s projectile_id=%s projectile_id_source=%s bounce_index=%s hit_object_id=%s hit_object_type=%s hit_object_cell=%s hit_pos=%s hit_normal=%s has_user_data=%s route_ok=%s reason=%s",
        tostring(event.spell_id or resolved_route.spell_id),
        tostring(resolved_route.helper_engine_id or event.helper_engine_id),
        tostring(resolved_route.recipe_id or event.recipe_id),
        tostring(resolved_route.slot_id or event.slot_id),
        tostring((resolved_route.user_data and resolved_route.user_data.cast_id) or event.cast_id),
        tostring(resolved_route.projectile_id or event.projectile_id),
        tostring(resolved_route.projectile_id_source or event.projectile_id_source),
        tostring(resolved_route.bounce_index or event.bounce_index),
        tostring(event.hit_object_id or objectToken(resolved_route.target)),
        tostring(event.hit_object_type or objectKind(resolved_route.target)),
        tostring(event.hit_object_cell or objectToken(objectCell(resolved_route.target)) or (objectCell(resolved_route.target) and tostring(objectCell(resolved_route.target)) or nil)),
        tostring(compactVector(resolved_route.hit_pos or event.hit_pos)),
        tostring(compactVector(resolved_route.hit_normal or event.hit_normal)),
        tostring(event.has_user_data == true),
        tostring(route_ok == true),
        tostring(reason)
    ))
end

local function logBounceEventRouteFailed(info, route, reason)
    local event = info or {}
    local resolved_route = route or {}
    runtime_stats.inc("live_bounce_event_route_failed")
    log.info(string.format(
        "SPELLFORGE_BOUNCE_EVENT_ROUTE_FAILED reason=%s spell_id=%s helper_engine_id=%s projectile_id=%s has_user_data=%s",
        tostring(reason),
        tostring(event.spell_id or resolved_route.spell_id),
        tostring(resolved_route.helper_engine_id or event.helper_engine_id),
        tostring(resolved_route.projectile_id or event.projectile_id),
        tostring(event.has_user_data == true)
    ))
end

local function inferBounceChainSourceTarget(route, binding)
    if route.target ~= nil or route.hit_pos == nil then
        return route.target, nil, nil
    end
    if binding.chain_source_target ~= nil then
        runtime_stats.inc("live_bounce_chain_source_target_inferred")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_SOURCE_TARGET_INFERRED recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s source_target_id=%s candidate_count=%s radius=%s provider=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(objectToken(binding.chain_source_target)),
            tostring(1),
            tostring(0),
            "injected"
        ))
        return binding.chain_source_target, nil, {
            ok = true,
            provider = "injected",
            candidate_count = 1,
            radius = 0,
        }
    end
    if binding.chain_candidate_provider ~= nil then
        return route.target, nil, nil
    end

    local hop_context = {
        caster = route.attacker or binding.actor,
        source_target = nil,
        current_hit_target = nil,
        current_hit_position = route.hit_pos,
        current_cell = objectCell(route.projectile) or objectCell(route.attacker or binding.actor),
        cast_id = binding.cast_id,
        recipe_id = binding.recipe_id,
        source_slot_id = binding.source_slot_id,
        payload_slot_id = binding.payload_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        chain_id = binding.chain_id,
        hop_index = 1,
        max_hops = binding.chain_max_hops,
        exclude_caster = true,
        exclude_current_hit_target = false,
    }
    local provider_result = chain_target_provider.collectCandidates(hop_context, {
        radius = binding.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
        max_radius = limits.MAX_CHAIN_SCAN_RADIUS,
        candidate_cap = binding.candidate_cap or limits.MAX_CHAIN_SCAN_CANDIDATES,
        actor_scan_cap = binding.scan_actor_cap or limits.MAX_CHAIN_SCAN_ACTORS,
        max_vertical_delta = limits.BOUNCE_CHAIN_SOURCE_VERTICAL_DELTA or limits.MAX_CHAIN_VERTICAL_DELTA,
        vertical_reference = "aim",
    })
    if not provider_result or provider_result.ok ~= true then
        runtime_stats.inc("live_bounce_chain_source_target_missing")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_SOURCE_TARGET_MISSING recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s candidate_count=%s vertical_rejected=%s radius=%s max_vertical_delta=%s provider=%s no_target_reason=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(provider_result and provider_result.candidate_count or 0),
            tostring(provider_result and provider_result.vertical_rejected or nil),
            tostring(provider_result and provider_result.radius or binding.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS),
            tostring(provider_result and provider_result.max_vertical_delta or limits.BOUNCE_CHAIN_SOURCE_VERTICAL_DELTA or limits.MAX_CHAIN_VERTICAL_DELTA),
            "real",
            tostring(provider_result and (provider_result.rejection_reason or provider_result.unsupported_reason) or "chain_target_provider_missing")
        ))
        return nil, nil, provider_result
    end

    local candidates = provider_result.candidates or {}
    local source_candidate = candidates[1]
    local source_target = source_candidate and (source_candidate.object or source_candidate) or nil
    if source_target ~= nil then
        runtime_stats.inc("live_bounce_chain_source_target_inferred")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_SOURCE_TARGET_INFERRED recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s source_target_id=%s candidate_count=%s radius=%s provider=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(objectToken(source_target) or (source_candidate and source_candidate.id) or nil),
            tostring(provider_result.candidate_count),
            tostring(provider_result.radius),
            "real"
        ))
    else
        runtime_stats.inc("live_bounce_chain_source_target_missing")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_SOURCE_TARGET_MISSING recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s candidate_count=%s vertical_rejected=%s radius=%s max_vertical_delta=%s provider=%s no_target_reason=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(provider_result.candidate_count),
            tostring(provider_result.vertical_rejected),
            tostring(provider_result.radius),
            tostring(provider_result.max_vertical_delta),
            "real",
            "no_source_target_candidate"
        ))
    end
    return source_target, candidates, provider_result
end

local function detonateBounceSource(route, binding, is_final)
    local mapping = route.mapping or helper_records.getByEngineId(binding.source_helper_engine_id)
    local presentation = mapping and mapping.presentation or nil
    local branch = eventBranchInfo(binding, route, "source_detonation")
    runtime_stats.inc("live_bounce_source_detonation_attempts")
    local detonate_user_data = sfp_userdata.buildHelperUserData({
        runtime = "2.2c_live_helper",
        mapping = mapping,
        recipe_id = binding.recipe_id,
        slot_id = binding.source_slot_id,
        helper_engine_id = binding.source_helper_engine_id,
        job_kind = "live_bounce_source_detonation",
        source_slot_id = binding.source_slot_id,
        source_prefix_opcode = "Bounce",
        source_postfix_opcode = binding.has_trigger_payload and "Trigger" or nil,
        source_helper_engine_id = binding.source_helper_engine_id,
        trigger_source_slot_id = binding.has_trigger_payload and binding.source_slot_id or nil,
        trigger_payload_slot_id = binding.payload_slot_id,
        has_trigger_payload = binding.has_trigger_payload == true,
        cast_id = binding.cast_id,
        bounce_runtime = true,
        bounce_role = "source_detonation",
        bounce_id = binding.bounce_id,
        bounce_index = route.bounce_index,
        bounce_max = binding.bounce_max,
        bounce_power = binding.bounce_power,
        bounce_detonate_on_actor_hit = false,
        bounce_trigger_payload_slot_id = binding.payload_slot_id,
        bounce_manual_detonation = true,
        bounce_final = is_final == true,
        branch_scope = branch.branch_scope,
        branch_id = branch.branch_id,
        branch_parent_id = branch.branch_parent_id,
        branch_kind = branch.branch_kind,
        branch_index = branch.branch_index,
        branch_count = branch.branch_count,
    })
    local result = sfp_adapter.detonateSpellAtPos({
        spellId = binding.source_helper_engine_id,
        caster = route.attacker or binding.actor,
        position = route.hit_pos,
        cell = objectCell(route.projectile) or objectCell(route.attacker or binding.actor),
        areaVfxRecId = presentation and presentation.areaVfxRecId or nil,
        areaVfxScale = presentation and presentation.areaVfxScale or nil,
        userData = detonate_user_data,
        muteAudio = binding.mute_audio,
        muteLight = binding.mute_light,
    })
    if result.ok then
        runtime_stats.inc("live_bounce_source_detonation_ok")
    else
        runtime_stats.inc("live_bounce_source_detonation_failed")
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_SOURCE_DETONATED recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s bounce_max=%s branch_scope=%s branch_id=%s helper_engine_id=%s ok=%s final=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.bounce_max),
        tostring(branch.branch_scope),
        tostring(branch.branch_id),
        tostring(binding.source_helper_engine_id),
        tostring(result.ok == true),
        tostring(is_final == true)
    ))
    return result
end

local function detonateBounceTriggerPayload(route, binding, duplicate_key, is_final, options)
    local payload_mapping = helper_records.getByRecipeSlot(binding.recipe_id, binding.payload_slot_id)
        or helper_records.getByEngineId(binding.payload_helper_engine_id)
    if not payload_mapping or payload_mapping.engine_id ~= binding.payload_helper_engine_id then
        runtime_stats.inc("live_bounce_trigger_payload_detonation_failed")
        return {
            ok = false,
            error = "bounce trigger payload helper mapping missing",
        }
    end

    local ir_runtime = noteIrBounceRuntimePlanned(
        route,
        binding,
        options or {},
        compactPayloadsFromBinding(binding),
        is_final,
        orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND,
        "trigger_payload_detonation"
    )
    local presentation = payload_mapping.presentation or nil
    local branch = eventBranchInfo(binding, route, "trigger_payload")
    runtime_stats.inc("live_bounce_trigger_payload_detonation_attempts")
    local detonate_user_data = sfp_userdata.buildHelperUserData({
        runtime = "2.2c_live_helper",
        mapping = payload_mapping,
        recipe_id = binding.recipe_id,
        slot_id = binding.payload_slot_id,
        helper_engine_id = binding.payload_helper_engine_id,
        job_kind = "live_bounce_trigger_payload_detonation",
        source_slot_id = binding.source_slot_id,
        source_prefix_opcode = "Bounce",
        source_postfix_opcode = "Trigger",
        source_helper_engine_id = binding.source_helper_engine_id,
        trigger_source_slot_id = binding.source_slot_id,
        trigger_payload_slot_id = binding.payload_slot_id,
        has_trigger_payload = true,
        trigger_route = "bounce",
        trigger_duplicate_key = shortKey(duplicate_key),
        payload_slot_id = binding.payload_slot_id,
        cast_id = binding.cast_id,
        bounce_runtime = true,
        bounce_role = "trigger_payload_detonation",
        bounce_id = binding.bounce_id,
        bounce_index = route.bounce_index,
        bounce_max = binding.bounce_max,
        bounce_power = binding.bounce_power,
        bounce_detonate_on_actor_hit = false,
        bounce_trigger_payload_slot_id = binding.payload_slot_id,
        bounce_manual_detonation = true,
        bounce_final = is_final == true,
        branch_scope = branch.branch_scope,
        branch_id = branch.branch_id,
        branch_parent_id = branch.branch_parent_id,
        branch_kind = branch.branch_kind,
        branch_index = branch.branch_index,
        branch_count = branch.branch_count,
    })
    local result = sfp_adapter.detonateSpellAtPos({
        spellId = binding.payload_helper_engine_id,
        caster = route.attacker or binding.actor,
        position = route.hit_pos,
        cell = objectCell(route.projectile) or objectCell(route.attacker or binding.actor),
        areaVfxRecId = presentation and presentation.areaVfxRecId or nil,
        areaVfxScale = presentation and presentation.areaVfxScale or nil,
        userData = detonate_user_data,
        muteAudio = binding.mute_audio,
        muteLight = binding.mute_light,
    })
    if result.ok then
        runtime_stats.inc("live_bounce_trigger_payload_detonation_ok")
    else
        runtime_stats.inc("live_bounce_trigger_payload_detonation_failed")
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_TRIGGER_PAYLOAD_DETONATED recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s bounce_max=%s branch_scope=%s branch_id=%s payload_slot_id=%s helper_engine_id=%s ok=%s final=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.bounce_max),
        tostring(branch.branch_scope),
        tostring(branch.branch_id),
        tostring(binding.payload_slot_id),
        tostring(binding.payload_helper_engine_id),
        tostring(result.ok == true),
        tostring(is_final == true)
    ))
    return {
        ok = result.ok == true,
        error = result.error,
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        payload_slot_id = binding.payload_slot_id,
        payload_helper_engine_id = binding.payload_helper_engine_id,
        payload_count = 1,
        trigger_route = "bounce",
        duplicate_key = duplicate_key,
        launch_accepted = result.ok == true,
        launch_count = result.ok == true and 1 or 0,
        detonation_result = result,
        launch_user_data = detonate_user_data,
        ir_bounce_runtime = ir_runtime and ir_runtime.ok == true or false,
        ir_bounce_runtime_job_count = ir_runtime and ir_runtime.ok == true
            and ir_runtime.job_plan
            and ir_runtime.job_plan.planned_job_count
            or nil,
        ir_bounce_runtime_fallback_used = ir_runtime and ir_runtime.fallback == true or false,
        ir_bounce_runtime_fallback_reason = ir_runtime and ir_runtime.fallback and ir_runtime.reason or nil,
        ir_bounce_runtime_mismatch = ir_runtime and ir_runtime.mismatch == true or false,
    }
end

local function routeBounceTriggerFanoutPayload(route, binding, duplicate_key, is_final, options)
    local route_options = options or {}
    local payloads = compactPayloadsFromBinding(binding)
    if #payloads == 0 then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
        return {
            ok = false,
            error = "bounce trigger payload helper mapping missing",
        }
    end

    local max_payload_fanout = tonumber(binding.max_payload_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_projectiles = tonumber(binding.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if #payloads > max_payload_fanout or #payloads > max_projectiles then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
        runtime_stats.inc("payload_multicast_cap_reject")
        return {
            ok = false,
            error = "bounce trigger payload multicast fanout exceeds cap",
        }
    end

    for _, payload in ipairs(payloads) do
        local payload_mapping = helper_records.getByRecipeSlot(binding.recipe_id, payload.slot_id)
            or helper_records.getByEngineId(payload.helper_engine_id)
        if not payload_mapping or payload_mapping.engine_id ~= payload.helper_engine_id then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            return {
                ok = false,
                error = "bounce trigger payload helper mapping missing",
            }
        end
        if payload_mapping.source_postfix_opcode ~= "Trigger"
            or payload_mapping.trigger_source_slot_id ~= binding.source_slot_id then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            return {
                ok = false,
                error = "bounce trigger payload helper mapping mismatch",
            }
        end
    end

    local actor = route.attacker or binding.actor
    local start_pos = route.hit_pos
    local direction = route.bounce_direction or route.hit_normal or binding.direction
    if actor == nil then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
        return { ok = false, error = "missing caster for bounce trigger payload" }
    end
    if start_pos == nil then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
        return { ok = false, error = "missing bounce position for trigger payload" }
    end
    if direction == nil then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
        return { ok = false, error = "missing bounce direction for trigger payload" }
    end

    local pattern_info = nil
    if binding.payload_pattern == true then
        local pattern_err = nil
        pattern_info, pattern_err = payload_pattern.compute(payloads, direction, binding.payload_pattern_kind, binding.payload_pattern_op)
        if not pattern_info then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            runtime_stats.inc("payload_pattern_rejected")
            return { ok = false, error = pattern_err or "bounce trigger payload pattern direction failed" }
        end
        payloads = pattern_info.payloads
    end

    local source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    local ir_enqueue = enqueueIrBounceRuntime(
        route,
        binding,
        duplicate_key,
        is_final,
        route_options,
        payloads,
        actor,
        start_pos,
        direction
    )
    if ir_enqueue and ir_enqueue.ok == false then
        return ir_enqueue
    end

    local ir_bounce_runtime_used = ir_enqueue and ir_enqueue.ir_bounce_runtime == true
    local ir_bounce_runtime_fallback_reason = ir_enqueue and ir_enqueue.fallback and ir_enqueue.reason or nil
    local ir_bounce_runtime_mismatch = ir_enqueue and ir_enqueue.mismatch == true or false
    local job_ids = ir_bounce_runtime_used and ir_enqueue.job_ids or {}
    if not ir_bounce_runtime_used then
        for index, payload in ipairs(payloads) do
            local payload_key = string.format("%s:%s", tostring(duplicate_key), tostring(payload.slot_id))
            local branch = fanoutBranchInfo(binding, route, payload, index, #payloads)
            local payload_launch = {
                actor = actor,
                start_pos = start_pos,
                direction = payload.direction or direction,
                hit_object = route.target,
                cast_id = binding.cast_id,
                source_slot_id = binding.source_slot_id,
                source_prefix_opcode = "Bounce",
                source_helper_engine_id = binding.source_helper_engine_id,
                source_postfix_opcode = "Trigger",
                root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id or binding.source_slot_id,
                current_source_slot_id = payload.current_source_slot_id or payload.slot_id,
                parent_slot_id = payload.parent_slot_id or binding.source_slot_id,
                payload_depth = payload.payload_depth or 1,
                nested_stage_kind = payload.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
                payload_slot_id = payload.slot_id,
                trigger_source_slot_id = binding.source_slot_id,
                trigger_payload_slot_id = payload.slot_id,
                trigger_route = "bounce",
                trigger_duplicate_key = shortKey(duplicate_key),
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
                bounce_runtime = true,
                bounce_role = "trigger_payload_launch",
                bounce_id = binding.bounce_id,
                bounce_index = route.bounce_index,
                bounce_max = binding.bounce_max,
                bounce_power = binding.bounce_power,
                bounce_detonate_on_actor_hit = false,
                bounce_trigger_payload_slot_id = payload.slot_id,
                bounce_final = is_final == true,
                mute_audio = binding.mute_audio,
                mute_light = binding.mute_light,
            }
            copyBranchFields(payload_launch, branch)
            local enqueue = orchestrator.enqueue({
                kind = orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND,
                recipe_id = binding.recipe_id,
                slot_id = payload.slot_id,
                helper_engine_id = payload.helper_engine_id,
                idempotency_key = payload_key,
                source_job_id = source_job_id,
                parent_job_id = source_job_id,
                depth = 1,
                cast_id = binding.cast_id,
                emission_index = payload.emission_index,
                group_index = payload.group_index,
                fanout_count = #payloads,
                max_live_launches_per_tick = binding.max_live_launches_per_tick,
                chaos_budget_profile = binding.chaos_budget_profile,
                root_source_slot_id = payload.root_source_slot_id or binding.root_source_slot_id or binding.source_slot_id,
                current_source_slot_id = payload.current_source_slot_id or payload.slot_id,
                parent_slot_id = payload.parent_slot_id or binding.source_slot_id,
                payload_depth = payload.payload_depth or 1,
                nested_stage_kind = payload.nested_stage_kind,
                nested_stage_index = payload.nested_stage_index,
                has_trigger_payload = payload.has_trigger_payload,
                has_timer_payload = payload.has_timer_payload,
                pattern_kind = payload.pattern_kind,
                pattern_index = payload.pattern_index,
                pattern_count = payload.pattern_count,
                pattern_direction_key = payload.pattern_direction_key,
                source_slot_id = binding.source_slot_id,
                source_prefix_opcode = "Bounce",
                source_helper_engine_id = binding.source_helper_engine_id,
                source_postfix_opcode = "Trigger",
                payload_slot_id = payload.slot_id,
                trigger_route = "bounce",
                trigger_duplicate_key = shortKey(duplicate_key),
                bounce_runtime = true,
                bounce_role = "trigger_payload_launch",
                bounce_id = binding.bounce_id,
                bounce_index = route.bounce_index,
                bounce_max = binding.bounce_max,
                bounce_power = binding.bounce_power,
                bounce_detonate_on_actor_hit = false,
                bounce_trigger_payload_slot_id = payload.slot_id,
                bounce_final = is_final == true,
                branch_scope = branch.branch_scope,
                branch_id = branch.branch_id,
                branch_parent_id = branch.branch_parent_id,
                branch_kind = branch.branch_kind,
                branch_index = branch.branch_index,
                branch_count = branch.branch_count,
                payload = payload_launch,
            })
            if not enqueue.ok then
                runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
                return {
                    ok = false,
                    error = enqueue.error or "bounce trigger payload enqueue failed",
                    job_ids = job_ids,
                }
            end
            job_ids[#job_ids + 1] = enqueue.job_id
        end
    end

    runtime_stats.inc("live_bounce_trigger_payload_jobs_enqueued", #job_ids)
    if binding.payload_multicast == true then
        runtime_stats.inc("payload_multicast_jobs", #job_ids)
        runtime_stats.inc("payload_multicast_bounce_trigger_jobs", #job_ids)
        runtime_stats.inc("payload_multicast_runtime_ok")
    end
    if binding.payload_pattern == true then
        runtime_stats.inc("payload_pattern_jobs", #job_ids)
        runtime_stats.inc("payload_pattern_bounce_trigger_jobs", #job_ids)
        runtime_stats.inc("payload_pattern_runtime_ok")
        if binding.payload_pattern_kind == "Spread" then
            runtime_stats.inc("payload_pattern_spread_jobs", #job_ids)
        elseif binding.payload_pattern_kind == "Burst" then
            runtime_stats.inc("payload_pattern_burst_jobs", #job_ids)
        end
    end

    local marker = binding.payload_pattern == true
        and "SPELLFORGE_BOUNCE_TRIGGER_PAYLOAD_PATTERN_ENQUEUED"
        or "SPELLFORGE_BOUNCE_TRIGGER_PAYLOAD_MULTICAST_ENQUEUED"
    local first_queued_job = orchestrator.getJob(job_ids[1])
    log.info(string.format(
        "%s recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s source_slot_id=%s payload_count=%s pattern_kind=%s first_branch_id=%s branch_kind=%s first_job_id=%s final=%s",
        marker,
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(binding.payload_pattern_kind),
        tostring(first_queued_job and first_queued_job.branch_id or nil),
        tostring(first_queued_job and first_queued_job.branch_kind or nil),
        tostring(job_ids[1]),
        tostring(is_final == true)
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
            max_jobs_per_tick = tonumber(binding.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
            max_live_launches_per_tick = tonumber(binding.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        }
        if route_options.simulate_update_ticks == true then
            tick_options.dt_seconds = tonumber(route_options.simulated_dt_seconds) or 0
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
    local launch_ok_count = 0
    local pending_count = 0
    local projectile_ids = {}
    for index, job_id in ipairs(job_ids) do
        local job = orchestrator.getJob(job_id)
        local job_ok = job and job.status == "complete" and job.launch_accepted == true
        local pending = job and (job.status == "queued" or job.status == "running")
        if job_ok then
            launch_ok_count = launch_ok_count + 1
            if job.projectile_id ~= nil then
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
            pattern_kind = job and job.pattern_kind or nil,
            pattern_index = job and job.pattern_index or nil,
            pattern_count = job and job.pattern_count or nil,
            pattern_direction_key = job and job.pattern_direction_key or nil,
            branch_scope = job and job.branch_scope or nil,
            branch_id = job and job.branch_id or nil,
            branch_parent_id = job and job.branch_parent_id or nil,
            branch_kind = job and job.branch_kind or nil,
            branch_index = job and job.branch_index or nil,
            branch_count = job and job.branch_count or nil,
            source_slot_id = job and job.source_slot_id or nil,
            source_prefix_opcode = job and job.source_prefix_opcode or nil,
            source_helper_engine_id = job and job.source_helper_engine_id or nil,
            source_postfix_opcode = job and job.source_postfix_opcode or nil,
            payload_slot_id = job and job.payload_slot_id or nil,
            trigger_route = job and job.trigger_route or nil,
            trigger_duplicate_key = job and job.trigger_duplicate_key or nil,
            bounce_runtime = job and job.bounce_runtime == true or false,
            bounce_role = job and job.bounce_role or nil,
            bounce_id = job and job.bounce_id or nil,
            bounce_index = job and job.bounce_index or nil,
            bounce_final = job and job.bounce_final == true or false,
            launch_accepted = job and job.launch_accepted == true or false,
            launch_direction = job and job.launch_direction or nil,
            projectile_id = job and job.projectile_id or nil,
            launch_user_data = job and job.launch_user_data or nil,
            error = job and job.error or nil,
        }
    end
    if launch_ok_count > 0 then
        runtime_stats.inc("live_bounce_trigger_payload_launch_ok", launch_ok_count)
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_TRIGGER_PAYLOAD_OK recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s source_slot_id=%s payload_count=%s launch_ok_count=%s first_branch_id=%s branch_kind=%s first_projectile_id=%s final=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(route.bounce_index),
            tostring(binding.source_slot_id),
            tostring(#payloads),
            tostring(launch_ok_count),
            tostring(jobs[1] and jobs[1].branch_id or nil),
            tostring(jobs[1] and jobs[1].branch_kind or nil),
            tostring(projectile_ids[1]),
            tostring(is_final == true)
        ))
    end
    if not launch_ok then
        runtime_stats.inc("live_bounce_trigger_payload_launch_failed", #payloads - launch_ok_count)
    end

    return {
        ok = launch_ok == true,
        error = launch_ok and nil or "bounce trigger payload job did not complete",
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        payload_slot_id = binding.payload_slot_id,
        payload_helper_engine_id = binding.payload_helper_engine_id,
        payload_slot_ids = payloadSlotIds(payloads),
        payload_helper_engine_ids = payloadHelperEngineIds(payloads),
        payload_count = #payloads,
        payload_multicast = binding.payload_multicast == true,
        payload_pattern = binding.payload_pattern == true,
        payload_pattern_kind = binding.payload_pattern_kind,
        payload_pattern_direction_keys = pattern_info and pattern_info.direction_keys or nil,
        trigger_route = "bounce",
        duplicate_key = duplicate_key,
        job_id = job_ids[1],
        job_ids = job_ids,
        ir_bounce_runtime = ir_bounce_runtime_used == true,
        ir_bounce_runtime_job_count = ir_bounce_runtime_used and #job_ids or nil,
        ir_bounce_runtime_fallback_used = ir_bounce_runtime_fallback_reason ~= nil,
        ir_bounce_runtime_fallback_reason = ir_bounce_runtime_fallback_reason,
        ir_bounce_runtime_mismatch = ir_bounce_runtime_mismatch == true,
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
    }
end

local function routeBounceTriggerChainPayload(route, binding, duplicate_key, is_final, options)
    runtime_stats.inc("live_bounce_chain_payload_attempts")
    local chain_source_target, precollected_candidates, precollected_provider_result =
        inferBounceChainSourceTarget(route, binding)
    if chain_source_target == nil and route.hit_pos == nil then
        runtime_stats.inc("live_bounce_chain_payload_ignored")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_PAYLOAD_ROUTED recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s bounce_max=%s source_slot_id=%s payload_slot_id=%s ok=true ignored=true stop_reason=missing_chain_hit_position final=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(binding.bounce_max),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(is_final == true)
        ))
        return {
            ok = true,
            ignored = true,
            stop_reason = "missing_chain_hit_position",
            source_slot_id = binding.source_slot_id,
            source_helper_engine_id = binding.source_helper_engine_id,
            payload_slot_id = binding.payload_slot_id,
            payload_helper_engine_id = binding.payload_helper_engine_id,
            payload_count = 1,
            trigger_route = "bounce_chain",
            duplicate_key = duplicate_key,
            chain_id = binding.chain_id,
            launch_accepted = false,
            launch_count = 0,
        }
    end
    local branch = eventBranchInfo(binding, route, "trigger_chain_payload")
    local ir_runtime = noteIrBounceRuntimePlanned(
        route,
        binding,
        options or {},
        compactPayloadsFromBinding(binding),
        is_final,
        "live_chain_handoff",
        "chain_handoff"
    )
    local handoff_provider = binding.chain_candidate_provider ~= nil and "mock"
        or (precollected_provider_result and precollected_provider_result.provider)
        or "real"
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_TRIGGER_CHAIN_BINDING_OK recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s source_slot_id=%s payload_slot_id=%s source_helper_engine_id=%s payload_helper_engine_id=%s branch_scope=%s branch_id=%s current_hit_target_id=%s provider=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(binding.chain_id),
        tostring(route.bounce_index),
        tostring(binding.source_slot_id),
        tostring(binding.payload_slot_id),
        tostring(binding.source_helper_engine_id),
        tostring(binding.payload_helper_engine_id),
        tostring(branch.branch_scope),
        tostring(branch.branch_id),
        tostring(objectToken(chain_source_target)),
        tostring(handoff_provider)
    ))
    local chain_route = {
        ok = true,
        source = "bounce",
        recipe_id = binding.recipe_id,
        slot_id = binding.source_slot_id,
        helper_engine_id = binding.source_helper_engine_id,
        attacker = route.attacker or binding.actor,
        target = chain_source_target,
        hit_pos = route.hit_pos,
        hit_normal = route.hit_normal,
        projectile = route.projectile,
        projectile_id = route.projectile_id,
        projectile_id_source = route.projectile_id_source,
        user_data = {
            runtime = "2.2c_live_helper",
            recipe_id = binding.recipe_id,
            slot_id = binding.source_slot_id,
            helper_engine_id = binding.source_helper_engine_id,
            job_kind = "live_bounce_chain_source_hit",
            job_id = binding.source_job_id,
            source_job_id = binding.source_job_id,
            source_slot_id = binding.source_slot_id,
            source_prefix_opcode = "Bounce",
            source_postfix_opcode = "Trigger",
            source_helper_engine_id = binding.source_helper_engine_id,
            trigger_source_slot_id = binding.source_slot_id,
            trigger_payload_slot_id = binding.payload_slot_id,
            has_trigger_payload = true,
            trigger_route = "bounce",
            trigger_duplicate_key = shortKey(duplicate_key),
            payload_slot_id = binding.payload_slot_id,
            cast_id = binding.cast_id,
            chain_runtime = true,
            chain_role = "source",
            chain_id = binding.chain_id,
            chain_hop_index = 0,
            chain_max_hops = binding.chain_max_hops,
            chain_targeting_mode = binding.chain_targeting_mode or "no_immediate_repeat",
            bounce_chain_source_target_id = objectToken(chain_source_target),
            bounce_chain_source_inferred = route.target == nil and chain_source_target ~= nil or nil,
            bounce_runtime = true,
            bounce_role = "trigger_chain_payload",
            bounce_id = binding.bounce_id,
            bounce_index = route.bounce_index,
            bounce_max = binding.bounce_max,
            bounce_power = binding.bounce_power,
            bounce_detonate_on_actor_hit = false,
            bounce_trigger_payload_slot_id = binding.payload_slot_id,
            bounce_final = is_final == true,
            branch_scope = branch.branch_scope,
            branch_id = branch.branch_id,
            branch_parent_id = branch.branch_parent_id,
            branch_kind = branch.branch_kind,
            branch_index = branch.branch_index,
            branch_count = branch.branch_count,
        },
    }
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_CHAIN_HANDOFF_ATTEMPT recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s chain_hop_index=%s chain_max_hops=%s branch_scope=%s branch_id=%s current_hit_target_id=%s provider=%s projectile_id=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(binding.chain_id),
        tostring(route.bounce_index),
        tostring(0),
        tostring(binding.chain_max_hops),
        tostring(branch.branch_scope),
        tostring(branch.branch_id),
        tostring(objectToken(chain_source_target)),
        tostring(handoff_provider),
        tostring(route.projectile_id)
    ))
    runtime_stats.inc("live_bounce_chain_handoff_attempts")
    local result = live_chain.handleResolvedHit(chain_route, {
        candidate_provider = binding.chain_candidate_provider,
        precollected_candidates = precollected_candidates,
        precollected_provider_result = precollected_provider_result,
        max_chain_ticks = binding.max_chain_ticks,
        max_jobs_per_tick = binding.max_jobs_per_tick,
        max_live_launches_per_tick = binding.max_live_launches_per_tick,
        force_enabled = binding.force_chain_runtime_enabled == true,
    })
    local selected_target_id = result and result.selected_target_id or nil
    local result_provider = result and (result.provider or (result.provider_result and result.provider_result.provider)) or nil
    if result and result.ok == true and result.ignored ~= true then
        runtime_stats.inc("live_bounce_chain_payload_ok")
    elseif result and result.ignored == true then
        runtime_stats.inc("live_bounce_chain_payload_ignored")
    else
        runtime_stats.inc("live_bounce_chain_payload_failed")
    end
    if result and result.ok == true and result.ignored ~= true
        and (tonumber(result.launch_count) or 0) > 0 then
        runtime_stats.inc("live_bounce_chain_handoff_ok")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_HANDOFF_OK recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s chain_hop_index=%s chain_max_hops=%s branch_scope=%s branch_id=%s current_hit_target_id=%s selected_target_id=%s provider=%s launch_count=%s projectile_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(result.chain_hop_index),
            tostring(result.max_hops or binding.chain_max_hops),
            tostring(branch.branch_scope),
            tostring(branch.branch_id),
            tostring(result.current_hit_target_id or objectToken(chain_source_target)),
            tostring(selected_target_id),
            tostring(result_provider or handoff_provider),
            tostring(result.launch_count),
            tostring(result.projectile_id)
        ))
    elseif result and result.ok == true and result.pending_los == true then
        runtime_stats.inc("live_bounce_chain_handoff_pending_los")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_HANDOFF_OK recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s chain_hop_index=%s chain_max_hops=%s branch_scope=%s branch_id=%s current_hit_target_id=%s selected_target_id=%s provider=%s launch_count=%s projectile_id=%s pending_los=true",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(result.chain_hop_index),
            tostring(result.max_hops or binding.chain_max_hops),
            tostring(branch.branch_scope),
            tostring(branch.branch_id),
            tostring(objectToken(chain_source_target)),
            tostring(selected_target_id),
            tostring(result_provider or handoff_provider),
            tostring(0),
            tostring(route.projectile_id)
        ))
    elseif result and result.stop_reason ~= nil then
        runtime_stats.inc("live_bounce_chain_handoff_no_target")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_HANDOFF_NO_TARGET recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s chain_hop_index=%s chain_max_hops=%s branch_scope=%s branch_id=%s current_hit_target_id=%s provider=%s no_target_reason=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(binding.chain_id),
            tostring(route.bounce_index),
            tostring(result.chain_hop_index),
            tostring(result.max_hops or binding.chain_max_hops),
            tostring(branch.branch_scope),
            tostring(branch.branch_id),
            tostring(result.current_hit_target_id or objectToken(chain_source_target)),
            tostring(result_provider or handoff_provider),
            tostring(result.stop_reason)
        ))
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_CHAIN_PAYLOAD_ROUTED recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s bounce_max=%s branch_scope=%s branch_id=%s source_slot_id=%s payload_slot_id=%s ok=%s ignored=%s stop_reason=%s final=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(binding.chain_id),
        tostring(route.bounce_index),
        tostring(binding.bounce_max),
        tostring(branch.branch_scope),
        tostring(branch.branch_id),
        tostring(binding.source_slot_id),
        tostring(binding.payload_slot_id),
        tostring(result and result.ok == true),
        tostring(result and result.ignored == true),
        tostring(result and result.stop_reason or nil),
        tostring(is_final == true)
    ))
    return {
        ok = result and result.ok == true,
        ignored = result and result.ignored == true or nil,
        error = result and result.error or nil,
        stop_reason = result and result.stop_reason or nil,
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        payload_slot_id = binding.payload_slot_id,
        payload_helper_engine_id = binding.payload_helper_engine_id,
        payload_count = 1,
        trigger_route = "bounce_chain",
        duplicate_key = duplicate_key,
        chain_id = binding.chain_id,
        chain_result = result,
        chain_hop_index = result and result.chain_hop_index or nil,
        current_hit_target_id = result and result.current_hit_target_id or objectToken(chain_source_target),
        selected_target_id = selected_target_id,
        provider = result_provider or handoff_provider,
        job_id = result and result.job_id or nil,
        job_ids = result and result.job_ids or nil,
        jobs = result and result.jobs or nil,
        launch_accepted = result and result.launch_count == 1 or false,
        launch_count = result and result.launch_count or 0,
        projectile_id = result and result.projectile_id or nil,
        projectile_ids = result and result.projectile_ids or nil,
        launch_user_data = chain_route.user_data,
        ir_bounce_runtime = ir_runtime and ir_runtime.ok == true or false,
        ir_bounce_runtime_job_count = ir_runtime and ir_runtime.ok == true
            and ir_runtime.job_plan
            and ir_runtime.job_plan.planned_job_count
            or nil,
        ir_bounce_runtime_fallback_used = ir_runtime and ir_runtime.fallback == true or false,
        ir_bounce_runtime_fallback_reason = ir_runtime and ir_runtime.fallback and ir_runtime.reason or nil,
        ir_bounce_runtime_mismatch = ir_runtime and ir_runtime.mismatch == true or false,
    }
end

function live_bounce.handleBouncePayload(payload, opts)
    local options = opts or {}
    local event_info = rawBounceEventInfo(payload)
    runtime_stats.inc("live_bounce_callbacks_seen")
    noteBounceEvent(event_info.projectile_id)
    local route = routeFromBouncePayload(payload)
    if route.ok ~= true then
        logBounceEventSeen(event_info, route, false, route.error)
        logBounceEventRouteFailed(event_info, route, route.error)
        return { ok = false, ignored = true, error = route.error }
    end
    local binding = bindingForRoute(route)
    if not binding then
        logBounceEventSeen(event_info, route, false, "no_live_bounce_binding")
        logBounceEventRouteFailed(event_info, route, "no_live_bounce_binding")
        return { ok = true, ignored = true, reason = "no_live_bounce_binding" }
    end
    if runtime_session.shouldDrop(binding.runtime_generation, "live_bounce_binding", {
        id = binding.source_slot_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.user_data and runtime_session.shouldDrop(route.user_data.runtime_generation, "live_bounce_route", {
        id = route.projectile_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.helper_engine_id ~= binding.source_helper_engine_id then
        logBounceEventSeen(event_info, route, false, "not_bounce_source_helper")
        logBounceEventRouteFailed(event_info, route, "not_bounce_source_helper")
        return { ok = true, ignored = true, reason = "not_bounce_source_helper" }
    end
    if options.force_enabled ~= true and not dev.liveBounceEnabled() then
        runtime_stats.inc("live_bounce_rejected")
        runtime_stats.inc("live_bounce_disabled_rejections")
        logBounceEventSeen(event_info, route, false, "live_bounce_disabled")
        logBounceEventRouteFailed(event_info, route, "live_bounce_disabled")
        return { ok = false, disabled = true, error = "live bounce disabled" }
    end

    runtime_stats.inc("live_bounce_events")
    logBounceEventSeen(event_info, route, true, nil)
    local key = duplicateKey(route, binding)
    if duplicate_keys[key] then
        runtime_stats.inc("live_bounce_duplicate_suppressed")
        if binding.has_chain_payload == true then
            runtime_stats.inc("live_bounce_chain_duplicate_suppressed")
            log.info(string.format(
                "SPELLFORGE_LIVE_BOUNCE_CHAIN_DUPLICATE_SUPPRESSED recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s bounce_index=%s source_slot_id=%s payload_slot_id=%s projectile_id=%s duplicate_key=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.bounce_id),
                tostring(binding.chain_id),
                tostring(route.bounce_index),
                tostring(binding.source_slot_id),
                tostring(binding.payload_slot_id),
                tostring(route.projectile_id),
                tostring(shortKey(key) or "<long>")
            ))
        end
        return {
            ok = true,
            duplicate_suppressed = true,
            duplicate_key = key,
            bounce_index = route.bounce_index,
            bounce_max = binding.bounce_max,
        }
    end
    rememberDuplicateKey(key)

    local is_final = tonumber(route.bounce_index) >= tonumber(binding.bounce_max)
    detonateBounceSource(route, binding, is_final)

    local trigger_result = nil
    if binding.has_trigger_payload == true then
        if options.force_trigger_enabled ~= true and not dev.liveTriggerEnabled() then
            runtime_stats.inc("live_bounce_trigger_payload_detonation_failed")
            trigger_result = { ok = false, disabled = true, error = "live trigger disabled" }
        elseif binding.has_chain_payload == true then
            trigger_result = routeBounceTriggerChainPayload(route, binding, key, is_final, options)
        elseif binding.payload_multicast == true
            and options.force_payload_multicast_enabled ~= true
            and binding.force_payload_multicast_enabled ~= true
            and not dev.livePayloadMulticastEnabled() then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            runtime_stats.inc("payload_multicast_disabled_reject")
            trigger_result = { ok = false, disabled = true, error = "live payload multicast disabled" }
        elseif binding.payload_pattern == true
            and options.force_payload_pattern_enabled ~= true
            and binding.force_payload_pattern_enabled ~= true
            and not dev.livePayloadPatternEnabled() then
            runtime_stats.inc("live_bounce_trigger_payload_launch_failed")
            runtime_stats.inc("payload_pattern_disabled_reject")
            trigger_result = { ok = false, disabled = true, error = "live payload pattern disabled" }
        elseif binding.payload_multicast == true or binding.payload_pattern == true then
            trigger_result = routeBounceTriggerFanoutPayload(route, binding, key, is_final, options)
        else
            trigger_result = detonateBounceTriggerPayload(route, binding, key, is_final, options)
        end
        if trigger_result and trigger_result.ok == true and trigger_result.ignored ~= true then
            runtime_stats.inc("live_bounce_trigger_payloads")
        end
    end

    local cancel_result = nil
    if is_final then
        if route.projectile_id == nil then
            cancel_result = { ok = false, error = "missing_projectile_id" }
        else
            cancel_result = sfp_adapter.cancelSpell(route.projectile_id)
        end
        if cancel_result.ok then
            runtime_stats.inc("live_bounce_final_cancel_ok")
        else
            runtime_stats.inc("live_bounce_final_cancel_failed")
        end
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_FINAL_CANCELLED recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s projectile_id=%s ok=%s error=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.bounce_id),
            tostring(route.bounce_index),
            tostring(route.projectile_id),
            tostring(cancel_result.ok == true),
            tostring(cancel_result.error)
        ))
    end

    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_EVENT recipe_id=%s cast_id=%s bounce_id=%s bounce_index=%s bounce_max=%s projectile_id=%s trigger_payload_slot_id=%s final=%s duplicate_key=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.bounce_id),
        tostring(route.bounce_index),
        tostring(binding.bounce_max),
        tostring(route.projectile_id),
        tostring(binding.payload_slot_id),
        tostring(is_final),
        tostring(shortKey(key) or "<long>")
    ))

    local trigger_payload_result = trigger_result or {}
    return {
        ok = true,
        bounce_index = route.bounce_index,
        bounce_max = binding.bounce_max,
        bounce_id = binding.bounce_id,
        projectile_id = route.projectile_id,
        final = is_final,
        trigger_result = trigger_result,
        trigger_payload_slot_id = binding.payload_slot_id,
        trigger_payload_helper_engine_id = binding.payload_helper_engine_id,
        payload_slot_id = trigger_payload_result.payload_slot_id,
        payload_helper_engine_id = trigger_payload_result.payload_helper_engine_id,
        payload_slot_ids = trigger_payload_result.payload_slot_ids,
        payload_helper_engine_ids = trigger_payload_result.payload_helper_engine_ids,
        payload_count = trigger_payload_result.payload_count,
        payload_multicast = trigger_payload_result.payload_multicast,
        payload_pattern = trigger_payload_result.payload_pattern,
        payload_pattern_kind = trigger_payload_result.payload_pattern_kind,
        payload_pattern_direction_keys = trigger_payload_result.payload_pattern_direction_keys,
        job_id = trigger_payload_result.job_id,
        job_ids = trigger_payload_result.job_ids,
        jobs = trigger_payload_result.jobs,
        job_status = trigger_payload_result.job_status,
        launch_accepted = trigger_payload_result.launch_accepted,
        launch_count = trigger_payload_result.launch_count,
        pending_launch_jobs = trigger_payload_result.pending_launch_jobs,
        pending_job_count = trigger_payload_result.pending_job_count,
        all_launch_jobs_complete = trigger_payload_result.all_launch_jobs_complete,
        trigger_payload_projectile_id = trigger_payload_result.projectile_id,
        projectile_ids = trigger_payload_result.projectile_ids,
        launch_user_data = trigger_payload_result.launch_user_data,
        ir_bounce_runtime = trigger_payload_result.ir_bounce_runtime == true,
        ir_bounce_runtime_job_count = trigger_payload_result.ir_bounce_runtime_job_count,
        ir_bounce_runtime_fallback_used = trigger_payload_result.ir_bounce_runtime_fallback_used == true,
        ir_bounce_runtime_fallback_reason = trigger_payload_result.ir_bounce_runtime_fallback_reason,
        ir_bounce_runtime_mismatch = trigger_payload_result.ir_bounce_runtime_mismatch == true,
        tick = trigger_payload_result.tick,
        cancel_result = cancel_result,
    }
end

function live_bounce.bounceEventCount(projectile_id)
    if projectile_id == nil then
        return 0
    end
    return bounce_event_counts_by_projectile[tostring(projectile_id)] or 0
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

function live_bounce.summary()
    return {
        bindings = countMap(bindings_by_cast_source),
        latest_bindings = countMap(bindings_by_latest_source),
        duplicate_keys = countMap(duplicate_keys),
        bounce_events = countMap(bounce_event_counts_by_projectile),
        runtime_generation = runtime_session.currentGeneration(),
    }
end

function live_bounce.clearTransient(reason)
    local before = live_bounce.summary()
    bindings_by_cast_source = {}
    bindings_by_latest_source = {}
    binding_order = {}
    duplicate_keys = {}
    duplicate_order = {}
    bounce_event_counts_by_projectile = {}
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_CLEARED reason=%s bounce_entries=%s duplicate_keys=%s bounce_events=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.bindings),
        tostring(before.duplicate_keys),
        tostring(before.bounce_events),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function live_bounce.clearForTests()
    return live_bounce.clearTransient("tests")
end

return live_bounce
