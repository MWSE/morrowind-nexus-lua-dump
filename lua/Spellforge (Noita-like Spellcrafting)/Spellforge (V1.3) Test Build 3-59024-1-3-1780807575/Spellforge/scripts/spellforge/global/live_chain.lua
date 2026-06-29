---@omw-context global
local async = require("openmw.async")
local util = require("openmw.util")
local ok_types, types = pcall(require, "openmw.types")

local dev = require("scripts.spellforge.shared.dev")
local events = require("scripts.spellforge.shared.events")
local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.live_chain")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")
local chain_target_provider = require("scripts.spellforge.global.chain_target_provider")
local chain_targeting = require("scripts.spellforge.global.chain_targeting")
local helper_records = require("scripts.spellforge.global.helper_records")
local ir_runtime_adapter = require("scripts.spellforge.global.ir_runtime_adapter")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_hits = require("scripts.spellforge.global.runtime_hits")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local live_timer = require("scripts.spellforge.global.live_timer")

local live_chain = {}

local MAX_BINDINGS = 128
local MAX_DUPLICATE_KEYS = 512
local MAX_PENDING_LOS = 64
local LOS_TIMEOUT_SECONDS = 0.5

local bindings_by_cast_source = {}
local bindings_by_chain_id = {}
local binding_order = {}
local duplicate_keys = {}
local duplicate_order = {}
local continuation_claims = {}
local continuation_claim_order = {}
local pending_los = {}
local pending_los_order = {}
local next_los_request_index = 0

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

local function hasOps(ops)
    return type(ops) == "table" and #ops > 0
end

local function hasPayloadBindings(value)
    return type(value) == "table" and #value > 0
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

local function hasOpcode(ops, opcode)
    local count = countOpcode(ops, opcode)
    return count > 0
end

local function analyzePayloadPrefixOps(ops)
    local info = {
        chain_count = 0,
        chain_op = nil,
        speed_count = 0,
        speed_op = nil,
        size_count = 0,
        size_op = nil,
        multicast_count = 0,
        multicast_op = nil,
        pattern_count = 0,
        pattern_kind = nil,
        pattern_op = nil,
        unsupported_count = 0,
        unsupported_opcode = nil,
    }
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == "Chain" then
            info.chain_count = info.chain_count + 1
            info.chain_op = info.chain_op or op
        elseif op and op.opcode == "Speed+" then
            info.speed_count = info.speed_count + 1
            info.speed_op = info.speed_op or op
        elseif op and op.opcode == "Size+" then
            info.size_count = info.size_count + 1
            info.size_op = info.size_op or op
        elseif op and op.opcode == "Multicast" then
            info.multicast_count = info.multicast_count + 1
            info.multicast_op = info.multicast_op or op
        elseif op and (op.opcode == "Spread" or op.opcode == "Burst") then
            info.pattern_count = info.pattern_count + 1
            if info.pattern_kind ~= nil and info.pattern_kind ~= op.opcode then
                info.pattern_ambiguous = true
            end
            info.pattern_kind = info.pattern_kind or op.opcode
            info.pattern_op = info.pattern_op or op
        else
            info.unsupported_count = info.unsupported_count + 1
            info.unsupported_opcode = info.unsupported_opcode or (op and op.opcode)
        end
    end
    return info
end

local function multicastFanout(op)
    local count = tonumber(op and op.params and op.params.count) or 1
    if count ~= count or count == math.huge or count == -math.huge then
        return 1
    end
    return math.max(1, math.floor(count))
end

local function chainMulticastEnabled(options)
    if options.force_chain_multicast_disabled == true then
        return false
    end
    return options.force_chain_multicast_enabled == true
        or options.allow_chain_multicast == true
        or options.chain_multicast_enabled == true
        or dev.liveChainMulticastEnabled()
end

local function clonePayload(payload)
    local out = {}
    for key, value in pairs(payload or {}) do
        out[key] = value
    end
    return out
end

local function cloneJobInput(job)
    local out = {}
    for key, value in pairs(job or {}) do
        if key == "payload" then
            out.payload = clonePayload(value)
        else
            out[key] = value
        end
    end
    return out
end

local function irChainRuntimeEnabled(options)
    if options and options.force_ir_chain_runtime_disabled == true then
        return false
    end
    return (options and options.force_ir_chain_runtime_enabled == true)
        or dev.irChainRuntimeEnabled()
end

local function irPlannerOptions(binding, options)
    local modifier_kinds = {}
    if binding and binding.payload_modifier_kind ~= nil then
        modifier_kinds[#modifier_kinds + 1] = binding.payload_modifier_kind
    end
    if binding and (binding.has_speed_plus_payload == true or type(binding.speed_plus_mutation) == "table") then
        modifier_kinds[#modifier_kinds + 1] = "speed_plus"
    end
    if binding and (binding.has_size_plus_payload == true or type(binding.size_plus_mutation) == "table") then
        modifier_kinds[#modifier_kinds + 1] = "size_plus"
    end
    local gates = launch_modifier_policy.gateHintsForModifierKinds(modifier_kinds, options)
    return {
        allow_chain_multicast = binding and binding.has_multicast_payload == true
            or (options and options.allow_chain_multicast == true)
            or (options and options.force_chain_multicast_enabled == true)
            or (options and options.chain_multicast_enabled == true),
        allow_payload_pattern = binding and binding.has_pattern_payload == true
            or (options and options.allow_payload_pattern == true)
            or (options and options.force_payload_pattern_enabled == true)
            or (options and options.payload_pattern_enabled == true),
        max_hops = binding and binding.max_hops or (options and options.max_chain_hops),
        max_jobs = binding and binding.max_chain_jobs or (options and options.max_chain_jobs),
        max_chain_multicast_fanout = binding and binding.chain_multicast_fanout_count
            or (options and options.max_chain_multicast_fanout),
        allow_chain_event_continuation = binding and binding.chain_side_continuation_kind ~= nil
            or (options and options.allow_chain_event_continuation == true),
        max_chain_event_continuation_jobs = binding and binding.chain_event_continuation_budget_cap
            or (options and options.max_chain_event_continuation_jobs),
        max_chain_trigger_side_payload_jobs = binding and binding.chain_event_continuation_budget_cap
            or (options and options.max_chain_trigger_side_payload_jobs),
        max_chain_timer_side_payload_jobs = binding and binding.chain_event_continuation_budget_cap
            or (options and options.max_chain_timer_side_payload_jobs),
        max_live_launches_per_tick = binding and binding.max_live_launches_per_tick
            or (options and options.max_live_launches_per_tick),
        chaos_budget_profile = binding and binding.chaos_budget_profile or (options and options.chaos_budget_profile),
        force_speed_plus_enabled = gates.force_speed_plus_enabled,
        force_speed_plus_disabled = gates.force_speed_plus_disabled,
        speed_plus_enabled = gates.speed_plus_enabled,
        force_size_plus_enabled = gates.force_size_plus_enabled,
        force_size_plus_disabled = gates.force_size_plus_disabled,
        size_plus_enabled = gates.size_plus_enabled,
        allow_payload_homing = options and options.allow_payload_homing == true,
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
    }
end

local function irChainFallback(binding, reason, marker)
    runtime_stats.inc("ir_chain_runtime_fallback")
    log.info(string.format(
        "%s recipe_id=%s cast_id=%s chain_id=%s source_slot_id=%s reason=%s",
        marker or "SPELLFORGE_IR_CHAIN_RUNTIME_FALLBACK",
        tostring(binding and binding.recipe_id),
        tostring(binding and binding.cast_id),
        tostring(binding and binding.chain_id),
        tostring(binding and binding.source_slot_id),
        tostring(reason)
    ))
    return {
        fallback = true,
        reason = reason,
        mismatch = marker == "SPELLFORGE_IR_CHAIN_RUNTIME_MISMATCH",
    }
end

local function irChainMismatch(binding, reason)
    runtime_stats.inc("ir_chain_runtime_mismatch")
    return irChainFallback(binding, reason, "SPELLFORGE_IR_CHAIN_RUNTIME_MISMATCH")
end

local function validateIrChainJobPlan(binding, fanout_count, continuation_plan, job_plan)
    if type(continuation_plan) ~= "table" or continuation_plan.ok ~= true then
        return false, continuation_plan and continuation_plan.rejection_reason or "continuation_plan_failed"
    end
    if continuation_plan.source_slot_id ~= binding.source_slot_id then
        return false, "source_slot_mismatch"
    end
    if continuation_plan.source_helper_engine_id ~= binding.source_helper_engine_id then
        return false, "source_helper_mismatch"
    end
    if continuation_plan.chain_shape ~= binding.chain_shape then
        return false, "chain_shape_mismatch"
    end
    if type(job_plan) ~= "table" or job_plan.ok ~= true then
        return false, job_plan and job_plan.rejection_reason or "runtime_job_plan_failed"
    end
    if tonumber(job_plan.planned_job_count) ~= fanout_count then
        return false, "payload_count_mismatch"
    end
    for index = 1, fanout_count do
        local job = job_plan.planned_jobs and job_plan.planned_jobs[index] or nil
        if type(job) ~= "table" then
            return false, "planned_job_missing"
        end
        if job.kind ~= orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND then
            return false, "job_kind_mismatch"
        end
        if fanout_count == 1 then
            if job.slot_id ~= binding.payload_slot_id or job.payload_slot_id ~= binding.payload_slot_id then
                return false, "payload_slot_mismatch"
            end
            if job.helper_engine_id ~= binding.payload_helper_engine_id then
                return false, "payload_helper_mismatch"
            end
        end
    end
    return true, nil
end

local function mergeIrChainPlannedJob(planned_job, legacy_job)
    if type(planned_job) ~= "table" then
        return legacy_job
    end
    local job = cloneJobInput(planned_job)
    local planned_payload = clonePayload(planned_job.payload or {})
    for key, value in pairs(legacy_job or {}) do
        if key ~= "payload" then
            job[key] = value
        end
    end
    job.payload = planned_payload
    for key, value in pairs((legacy_job and legacy_job.payload) or {}) do
        job.payload[key] = value
    end
    if legacy_job and legacy_job.source_prefix_opcode == nil then
        job.source_prefix_opcode = nil
    end
    if legacy_job and legacy_job.payload and legacy_job.payload.source_prefix_opcode == nil then
        job.payload.source_prefix_opcode = nil
    end
    return job
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

local function slotById(slots)
    local by_slot = {}
    for _, slot in ipairs(slots or {}) do
        if type(slot) == "table" and type(slot.slot_id) == "string" then
            by_slot[slot.slot_id] = slot
        end
    end
    return by_slot
end

local function firstEffectId(helper)
    local first = helper and helper.effects and helper.effects[1] or nil
    return first and first.id or nil
end

local function objectToken(value)
    if value == nil then
        return nil
    end
    local value_type = type(value)
    if value_type ~= "table" then
        return tostring(value)
    end
    if value_type == "table" then
        return value.id
            or value.recordId
            or value.refId
            or value.name
            or objectToken(value.object)
    end
    return tostring(value)
end

local function cellToken(value)
    if value == nil then
        return nil
    end
    if type(value) == "table" then
        return value.id or value.name or tostring(value)
    end
    return tostring(value)
end

local function tablePosition(value)
    if value == nil then
        return nil
    end
    local direct_ok, direct_x = pcall(function()
        return value.x
    end)
    local direct_y = nil
    if direct_ok then
        local ok_y, y = pcall(function()
            return value.y
        end)
        if ok_y then
            direct_y = y
        end
    end
    if direct_ok and direct_x ~= nil and direct_y ~= nil then
        return value
    end
    local ok, position = pcall(function()
        return value.position
    end)
    if ok and position ~= nil then
        return position
    end
    return nil
end

local function positionComponent(position, key)
    if position == nil then
        return 0
    end
    local ok, value = pcall(function()
        return position[key]
    end)
    if ok then
        return tonumber(value) or 0
    end
    return 0
end

local function elevatedPosition(position, height)
    if position == nil then
        return nil
    end
    return {
        x = positionComponent(position, "x"),
        y = positionComponent(position, "y"),
        z = positionComponent(position, "z") + (tonumber(height) or 0),
    }
end

local function targetIsKnownNonActor(value)
    if value == nil then
        return false
    end
    if type(value) == "table" then
        if value.is_actor ~= nil then
            return value.is_actor ~= true
        end
        if value.object ~= nil then
            return targetIsKnownNonActor(value.object)
        end
    end
    if not ok_types or not types or not types.Actor or not types.Actor.stats
        or not types.Actor.stats.dynamic or type(types.Actor.stats.dynamic.health) ~= "function" then
        return false
    end
    local ok, health = pcall(types.Actor.stats.dynamic.health, value)
    return not (ok and health ~= nil)
end

local function vectorFromPosition(value)
    local position = tablePosition(value)
    if not position then
        return nil
    end
    return util.vector3(
        tonumber(position.x) or 0,
        tonumber(position.y) or 0,
        tonumber(position.z) or 0
    )
end

local function directionBetween(origin_value, target_value)
    local origin = tablePosition(origin_value)
    local target = tablePosition(target_value)
    if not origin or not target then
        return nil, "chain_target_direction_missing"
    end
    local dx = (tonumber(target.x) or 0) - (tonumber(origin.x) or 0)
    local dy = (tonumber(target.y) or 0) - (tonumber(origin.y) or 0)
    local dz = (tonumber(target.z) or 0) - (tonumber(origin.z) or 0)
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if length <= 0 then
        return nil, "chain_target_direction_zero"
    end
    return util.vector3(dx / length, dy / length, dz / length), nil
end

local function candidateObjectForSelected(candidates, selected_id)
    for _, candidate in ipairs(candidates or {}) do
        local id = candidate and (candidate.id or objectToken(candidate.object) or objectToken(candidate))
        if tostring(id) == tostring(selected_id) then
            return candidate.object
        end
    end
    return nil
end

local function candidateToken(candidate, index)
    return tostring(candidate and (candidate.id or objectToken(candidate.object) or objectToken(candidate)) or ("candidate_" .. tostring(index)))
end

local function isCandidateDescriptor(value)
    return type(value) == "table"
        and (value.id ~= nil or value.object ~= nil or value.position ~= nil or value.distance_override ~= nil)
end

local function isCandidateList(value)
    return type(value) == "table" and isCandidateDescriptor(value[1])
end

local function candidatesForHop(provider, hop_context)
    if type(provider) == "function" then
        return provider(hop_context)
    end
    if type(provider) ~= "table" then
        return nil
    end
    local keyed = provider[hop_context.hop_index]
    if isCandidateList(keyed) then
        return keyed
    end
    if isCandidateList(provider) then
        return provider
    end
    return nil
end

local function collectCandidates(provider, hop_context, binding, options)
    if provider ~= nil then
        runtime_stats.inc("chain_provider_attempts")
        runtime_stats.inc("chain_provider_mock_attempts")
        local candidates = candidatesForHop(provider, hop_context)
        local count = type(candidates) == "table" and #candidates or 0
        runtime_stats.inc("chain_provider_candidates_returned", count)
        if candidates then
            runtime_stats.inc("chain_provider_selected_mock")
            log.info(string.format(
                "SPELLFORGE_CHAIN_PROVIDER_MOCK_OK recipe_id=%s cast_id=%s chain_id=%s hop_index=%s candidate_count=%s",
                tostring(hop_context and hop_context.recipe_id or nil),
                tostring(hop_context and hop_context.cast_id or nil),
                tostring(hop_context and hop_context.chain_id or nil),
                tostring(hop_context and hop_context.hop_index or nil),
                tostring(count)
            ))
        end
        return candidates, {
            ok = candidates ~= nil,
            provider = "mock",
            candidate_count = count,
            candidates = candidates,
            rejection_reason = candidates == nil and "chain_target_provider_missing" or nil,
        }
    end

    local collected = chain_target_provider.collectCandidates(hop_context, {
        radius = binding and binding.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
        max_radius = limits.MAX_CHAIN_SCAN_RADIUS,
        candidate_cap = binding and binding.candidate_cap or limits.MAX_CHAIN_SCAN_CANDIDATES,
        actor_scan_cap = binding and binding.scan_actor_cap or limits.MAX_CHAIN_SCAN_ACTORS,
    })
    if collected and collected.ok then
        return collected.candidates or {}, collected
    end
    return nil, collected
end

local function compactJob(job_id)
    local job = orchestrator.getJob(job_id)
    local payload = job and job.payload or nil
    return {
        job_id = job_id,
        job_status = job and job.status or nil,
        slot_id = job and job.slot_id or nil,
        helper_engine_id = job and job.helper_engine_id or nil,
        cast_id = job and job.cast_id or nil,
        emission_index = job and job.emission_index or nil,
        group_index = job and job.group_index or nil,
        source_slot_id = job and job.source_slot_id or nil,
        payload_slot_id = job and job.payload_slot_id or nil,
        root_source_slot_id = job and (job.root_source_slot_id or (payload and payload.root_source_slot_id)) or nil,
        chain_runtime = job and (job.chain_runtime or (payload and payload.chain_runtime)) or nil,
        chain_role = job and (job.chain_role or (payload and payload.chain_role)) or nil,
        chain_id = job and (job.chain_id or (payload and payload.chain_id)) or nil,
        chain_hop_index = job and (job.chain_hop_index or (payload and payload.chain_hop_index)) or nil,
        chain_max_hops = job and (job.chain_max_hops or (payload and payload.chain_max_hops)) or nil,
        chain_targeting_mode = job and (job.chain_targeting_mode or (payload and payload.chain_targeting_mode)) or nil,
        chain_target_provider = job and (job.chain_target_provider or (payload and payload.chain_target_provider)) or nil,
        branch_scope = job and (job.branch_scope or (payload and payload.branch_scope)) or nil,
        branch_id = job and (job.branch_id or (payload and payload.branch_id)) or nil,
        branch_parent_id = job and (job.branch_parent_id or (payload and payload.branch_parent_id)) or nil,
        branch_kind = job and (job.branch_kind or (payload and payload.branch_kind)) or nil,
        branch_index = job and (job.branch_index or (payload and payload.branch_index)) or nil,
        branch_count = job and (job.branch_count or (payload and payload.branch_count)) or nil,
        bounce_runtime = job and ((job.bounce_runtime or (payload and payload.bounce_runtime)) == true) or false,
        bounce_role = job and (job.bounce_role or (payload and payload.bounce_role)) or nil,
        bounce_id = job and (job.bounce_id or (payload and payload.bounce_id)) or nil,
        bounce_index = job and (job.bounce_index or (payload and payload.bounce_index)) or nil,
        bounce_final = job and ((job.bounce_final or (payload and payload.bounce_final)) == true) or false,
        chain_continuation_group_id = job and (job.chain_continuation_group_id or (payload and payload.chain_continuation_group_id)) or nil,
        current_hit_target_id = job and (job.current_hit_target_id or (payload and payload.current_hit_target_id)) or nil,
        selected_target_id = job and (job.selected_target_id or (payload and payload.selected_target_id)) or nil,
        previous_projectile_id = job and (job.previous_projectile_id or (payload and payload.previous_projectile_id)) or nil,
        payload_modifier_kind = job and (job.payload_modifier_kind or (payload and payload.payload_modifier_kind)) or nil,
        speed = job and (job.speed or (payload and payload.speed)) or nil,
        maxSpeed = job and (job.maxSpeed or (payload and payload.maxSpeed)) or nil,
        speed_plus = job and (job.speed_plus or (payload and payload.speed_plus)) or nil,
        speed_plus_mode = job and (job.speed_plus_mode or (payload and payload.speed_plus_mode)) or nil,
        speed_plus_value = job and (job.speed_plus_value or (payload and payload.speed_plus_value)) or nil,
        speed_plus_base_speed = job and (job.speed_plus_base_speed or (payload and payload.speed_plus_base_speed)) or nil,
        speed_plus_multiplier = job and (job.speed_plus_multiplier or (payload and payload.speed_plus_multiplier)) or nil,
        speed_plus_speed = job and (job.speed_plus_speed or (payload and payload.speed_plus_speed)) or nil,
        speed_plus_max_speed = job and (job.speed_plus_max_speed or (payload and payload.speed_plus_max_speed)) or nil,
        speed_plus_field = job and (job.speed_plus_field or (payload and payload.speed_plus_field)) or nil,
        speed_plus_capped = job and (job.speed_plus_capped or (payload and payload.speed_plus_capped)) or nil,
        size_plus = job and (job.size_plus or (payload and payload.size_plus)) or nil,
        size_plus_mode = job and (job.size_plus_mode or (payload and payload.size_plus_mode)) or nil,
        size_plus_value = job and (job.size_plus_value or (payload and payload.size_plus_value)) or nil,
        size_plus_multiplier = job and (job.size_plus_multiplier or (payload and payload.size_plus_multiplier)) or nil,
        size_plus_field = job and (job.size_plus_field or (payload and payload.size_plus_field)) or nil,
        size_plus_capped = job and (job.size_plus_capped or (payload and payload.size_plus_capped)) or nil,
        size_plus_base_area = job and (job.size_plus_base_area or (payload and payload.size_plus_base_area)) or nil,
        size_plus_area = job and (job.size_plus_area or (payload and payload.size_plus_area)) or nil,
        chain_side_continuation_kind = job and (job.chain_side_continuation_kind or (payload and payload.chain_side_continuation_kind)) or nil,
        chain_side_continuation_id = job and (job.chain_side_continuation_id or (payload and payload.chain_side_continuation_id)) or nil,
        chain_side_payload_count = job and (job.chain_side_payload_count or (payload and payload.chain_side_payload_count)) or nil,
        launch_accepted = job and job.launch_accepted == true or false,
        projectile_id = job and job.projectile_id or nil,
        projectile_id_source = job and job.projectile_id_source or nil,
        launch_start_pos = job and (job.launch_start_pos or (payload and payload.start_pos)) or nil,
        launch_direction = job and job.launch_direction or nil,
        launch_user_data = job and job.launch_user_data or nil,
        error = job and job.error or nil,
    }
end

local function makeProbeVirtualPayloadJob(job, job_id, projectile_id)
    local source = job or {}
    local payload = source.payload or {}
    local user_data_args = cloneJobInput(source)
    user_data_args.runtime = "2.2c_live_helper"
    user_data_args.mapping = helper_records.getByEngineId(source.helper_engine_id)
    user_data_args.job_kind = user_data_args.job_kind or user_data_args.kind
    user_data_args.job_id = job_id
    local user_data = sfp_userdata.buildHelperUserData(user_data_args)
    return {
        job_id = job_id,
        job_status = "complete",
        slot_id = source.slot_id,
        helper_engine_id = source.helper_engine_id,
        cast_id = source.cast_id,
        emission_index = source.emission_index,
        group_index = source.group_index,
        source_slot_id = source.source_slot_id,
        payload_slot_id = source.payload_slot_id,
        root_source_slot_id = source.root_source_slot_id or payload.root_source_slot_id,
        chain_runtime = source.chain_runtime or payload.chain_runtime,
        chain_role = source.chain_role or payload.chain_role,
        chain_id = source.chain_id or payload.chain_id,
        chain_hop_index = source.chain_hop_index or payload.chain_hop_index,
        chain_max_hops = source.chain_max_hops or payload.chain_max_hops,
        chain_targeting_mode = source.chain_targeting_mode or payload.chain_targeting_mode,
        chain_target_provider = source.chain_target_provider or payload.chain_target_provider,
        branch_scope = source.branch_scope or payload.branch_scope,
        branch_id = source.branch_id or payload.branch_id,
        branch_parent_id = source.branch_parent_id or payload.branch_parent_id,
        branch_kind = source.branch_kind or payload.branch_kind,
        branch_index = source.branch_index or payload.branch_index,
        branch_count = source.branch_count or payload.branch_count,
        chain_continuation_group_id = source.chain_continuation_group_id or payload.chain_continuation_group_id,
        current_hit_target_id = source.current_hit_target_id or payload.current_hit_target_id,
        selected_target_id = source.selected_target_id or payload.selected_target_id,
        previous_projectile_id = source.previous_projectile_id or payload.previous_projectile_id,
        payload_modifier_kind = source.payload_modifier_kind or payload.payload_modifier_kind,
        speed = source.speed or payload.speed,
        maxSpeed = source.maxSpeed or payload.maxSpeed,
        speed_plus = source.speed_plus or payload.speed_plus,
        speed_plus_mode = source.speed_plus_mode or payload.speed_plus_mode,
        speed_plus_value = source.speed_plus_value or payload.speed_plus_value,
        speed_plus_base_speed = source.speed_plus_base_speed or payload.speed_plus_base_speed,
        speed_plus_multiplier = source.speed_plus_multiplier or payload.speed_plus_multiplier,
        speed_plus_speed = source.speed_plus_speed or payload.speed_plus_speed,
        speed_plus_max_speed = source.speed_plus_max_speed or payload.speed_plus_max_speed,
        speed_plus_field = source.speed_plus_field or payload.speed_plus_field,
        speed_plus_capped = source.speed_plus_capped or payload.speed_plus_capped,
        size_plus = source.size_plus or payload.size_plus,
        size_plus_mode = source.size_plus_mode or payload.size_plus_mode,
        size_plus_value = source.size_plus_value or payload.size_plus_value,
        size_plus_multiplier = source.size_plus_multiplier or payload.size_plus_multiplier,
        size_plus_field = source.size_plus_field or payload.size_plus_field,
        size_plus_capped = source.size_plus_capped or payload.size_plus_capped,
        size_plus_base_area = source.size_plus_base_area or payload.size_plus_base_area,
        size_plus_area = source.size_plus_area or payload.size_plus_area,
        chain_side_continuation_kind = source.chain_side_continuation_kind or payload.chain_side_continuation_kind,
        chain_side_continuation_id = source.chain_side_continuation_id or payload.chain_side_continuation_id,
        chain_side_payload_count = source.chain_side_payload_count or payload.chain_side_payload_count,
        launch_accepted = true,
        projectile_id = projectile_id,
        projectile_id_source = "probe_virtual",
        launch_start_pos = source.launch_start_pos or payload.start_pos,
        launch_direction = source.launch_direction or payload.direction,
        launch_user_data = user_data,
        probe_virtual = true,
    }
end

local function jobsSettled(job_ids)
    for _, job_id in ipairs(job_ids or {}) do
        local job = orchestrator.getJob(job_id)
        if not job or job.status == "queued" or job.status == "running" then
            return false
        end
    end
    return true
end

local function tickJobs(job_ids, opts)
    local options = opts or {}
    local max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick)
        or limits.MAX_LIVE_LAUNCHES_PER_TICK
    local job_count = type(job_ids) == "table" and #job_ids or 0
    local default_ticks = math.max(
        8,
        math.ceil(job_count / math.max(1, max_live_launches_per_tick)) + 2
    )
    local max_ticks = tonumber(options.max_chain_ticks) or default_ticks
    local tick_result = nil
    local tick_results = {}
    for _ = 1, max_ticks do
        if jobsSettled(job_ids) then
            break
        end
        local tick_options = {
            max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
            max_live_launches_per_tick = max_live_launches_per_tick,
        }
        if options.simulate_update_ticks == true then
            tick_options.dt_seconds = tonumber(options.simulated_dt_seconds) or 0
        end
        tick_result = orchestrator.tick(tick_options)
        tick_results[#tick_results + 1] = tick_result
    end
    return tick_result, tick_results
end

local function shortKey(key)
    if type(key) == "string" and #key <= 180 then
        return key
    end
    return nil
end

local function inspectPayloadModifier(plan, audit, options)
    local slots_by_id = slotById(plan and plan.emission_slots)
    local payload_slot = slots_by_id[audit and audit.payload_slot_id]
    if not payload_slot then
        return nil, "chain_slot_mapping_missing"
    end

    local prefix = analyzePayloadPrefixOps(payload_slot.prefix_ops)
    if prefix.chain_count ~= 1 or prefix.chain_op == nil then
        return nil, "chain_payload_prefix_missing"
    end
    local policy = launch_modifier_policy.inspectPayloadEntry(plan, nil, payload_slot, {
        compatibility = "chain",
        require_chain_prefix = true,
        apply_size_to_specs = options and options.apply_size_to_specs == true,
        allow_chain_multicast = chainMulticastEnabled(options or {}),
        force_chain_multicast_enabled = options and options.force_chain_multicast_enabled,
        force_chain_multicast_disabled = options and options.force_chain_multicast_disabled,
        chain_multicast_enabled = options and options.chain_multicast_enabled == true,
        allow_payload_pattern = options and (options.allow_payload_pattern == true or options.force_payload_pattern_enabled == true),
        payload_pattern_enabled = options and options.payload_pattern_enabled == true,
        force_payload_pattern_enabled = options and options.force_payload_pattern_enabled,
        force_payload_pattern_disabled = options and options.force_payload_pattern_disabled,
        max_chain_multicast_fanout = options and options.max_chain_multicast_fanout or limits.MAX_CHAIN_MULTICAST_FANOUT,
        max_chain_pattern_fanout = options and options.max_chain_pattern_fanout or limits.MAX_CHAIN_PATTERN_FANOUT,
        force_speed_plus_enabled = options and options.force_speed_plus_enabled,
        force_speed_plus_disabled = options and options.force_speed_plus_disabled,
        force_size_plus_enabled = options and options.force_size_plus_enabled,
        force_size_plus_disabled = options and options.force_size_plus_disabled,
        speed_plus_enabled = options and options.speed_plus_enabled == true,
        size_plus_enabled = options and options.size_plus_enabled == true,
        allow_nested_payload_modifiers = options and options.allow_chain_event_continuation == true,
    })
    if policy.ok ~= true then
        return nil, policy.rejection_reason or "chain_payload_modifier_deferred"
    end

    local mutations = policy.mutations or {}
    local kind = mutations.payload_modifier_kind
    local fanout_count = mutations.chain_multicast_fanout_count or 1
    local has_speed_plus = type(mutations.speed_plus) == "table"
    local has_size_plus = type(mutations.size_plus) == "table"

    return {
        payload_modifier_kind = kind,
        has_speed_plus_payload = has_speed_plus,
        has_size_plus_payload = has_size_plus,
        has_multicast_payload = prefix.multicast_count == 1,
        has_pattern_payload = prefix.pattern_count == 1,
        chain_pattern_kind = prefix.pattern_kind,
        chain_multicast_fanout_count = fanout_count,
        speed_plus_mutation = mutations.speed_plus,
        size_plus_mutation = mutations.size_plus,
        size_plus_apply_result = mutations.size_plus_apply_result,
    }, nil
end

local function sideContinuationKind(slot)
    local has_trigger, trigger_op = countOpcode(slot and slot.postfix_ops or nil, "Trigger")
    local has_timer, timer_op = countOpcode(slot and slot.postfix_ops or nil, "Timer")
    if has_trigger > 0 and has_timer > 0 then
        return nil, nil, "chain_nested_payload_deferred"
    end
    if has_trigger == 1 then
        return "Trigger", trigger_op, nil
    elseif has_timer == 1 then
        return "Timer", timer_op, nil
    elseif has_trigger > 1 or has_timer > 1 then
        return nil, nil, "chain_nested_payload_deferred"
    end
    return nil, nil, nil
end

local function resolveSidePayloads(plan, payload_slot, side_kind, options)
    if side_kind ~= "Trigger" and side_kind ~= "Timer" then
        return nil, nil
    end
    local payload_result = payload_multicast.resolvePayloadHelpersForSource(plan, payload_slot, {
        source_opcode = side_kind,
        allow_payload_multicast = options.allow_payload_multicast == true
            or options.force_payload_multicast_enabled == true
            or options.payload_multicast_enabled == true,
        allow_payload_pattern = options.allow_payload_pattern == true
            or options.force_payload_pattern_enabled == true
            or options.payload_pattern_enabled == true,
        allow_payload_launch_modifiers = options.allow_payload_launch_modifiers == true
            or options.force_speed_plus_enabled == true
            or options.force_size_plus_enabled == true
            or options.speed_plus_enabled == true
            or options.size_plus_enabled == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = options.speed_plus_enabled == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = options.size_plus_enabled == true,
        max_depth = options.max_depth,
        max_jobs = options.max_chain_side_payload_jobs or limits.MAX_NESTED_PAYLOAD_JOBS,
        max_fanout = options.max_chain_side_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT,
        max_projectiles = options.max_projectiles,
        allow_unrelated_payloads = true,
        source_context_validated = true,
    })
    if not payload_result.ok then
        return nil, payload_result.rejection_reason or "chain_nested_payload_deferred"
    end
    for _, side_payload in ipairs(payload_result.payload_slots or {}) do
        if hasOpcode(side_payload and side_payload.prefix_ops or nil, "Chain") then
            return nil, "chain_event_payload_chain_deferred"
        end
        if hasOpcode(side_payload and side_payload.prefix_ops or nil, "Homing") then
            return nil, "homing_chain_targeting_unsupported"
        end
    end
    return payload_result, nil
end

local function sideBudgetReason(side_kind, max_hops, chain_fanout_count, side_payload_count, options)
    local budget = (tonumber(max_hops) or 0)
        * math.max(1, tonumber(chain_fanout_count) or 1)
        * math.max(1, tonumber(side_payload_count) or 1)
    local cap = tonumber(options.max_chain_event_continuation_jobs)
        or (side_kind == "Trigger"
            and tonumber(options.max_chain_trigger_side_payload_jobs or limits.MAX_CHAIN_TRIGGER_SIDE_PAYLOAD_JOBS_PER_CAST)
            or tonumber(options.max_chain_timer_side_payload_jobs or limits.MAX_CHAIN_TIMER_SIDE_PAYLOAD_JOBS_PER_CAST))
        or limits.MAX_CHAIN_EVENT_CONTINUATION_JOBS_PER_CAST
    if budget > cap then
        return side_kind == "Trigger"
            and "chain_trigger_side_payload_budget_exceeded"
            or "chain_timer_side_payload_budget_exceeded",
            budget,
            cap
    end
    return nil, budget, cap
end

function live_chain.preparePayloadModifiers(plan, opts)
    local options = opts or {}
    local audit = chain_targeting.inspectPlan(plan, {
        max_hops = options.max_hops or limits.MAX_CHAIN_HOPS,
        max_jobs = options.max_jobs or limits.MAX_CHAIN_JOBS_PER_CAST,
        scan_radius = options.scan_radius,
        max_candidates = options.max_candidates or options.candidate_cap,
        allow_chain_multicast = chainMulticastEnabled(options),
        allow_chain_pattern = options.allow_chain_pattern == true or options.allow_payload_pattern == true or options.force_payload_pattern_enabled == true,
        allow_payload_pattern = options.allow_payload_pattern == true or options.force_payload_pattern_enabled == true,
        allow_chain_event_continuation = options.allow_chain_event_continuation == true,
        max_chain_multicast_fanout = options.max_chain_multicast_fanout,
        max_chain_pattern_fanout = options.max_chain_pattern_fanout,
    })
    if audit.chain_candidate ~= true then
        return nil, audit.rejection_reason or "unsupported_chain_shape", audit
    end
    if audit.chain_shape ~= "source_chain_payload" and audit.chain_shape ~= "trigger_payload_chain" then
        return nil, "unsupported_chain_shape", audit
    end

    local modifier, reason = inspectPayloadModifier(plan, audit, options)
    if not modifier then
        audit.rejection_reason = reason
        return nil, reason, audit
    end
    audit.payload_modifier_kind = modifier.payload_modifier_kind
    audit.has_speed_plus_payload = modifier.has_speed_plus_payload == true
    audit.has_size_plus_payload = modifier.has_size_plus_payload == true
    audit.has_multicast_payload = modifier.has_multicast_payload == true
    audit.has_pattern_payload = modifier.has_pattern_payload == true
    audit.chain_pattern_kind = modifier.chain_pattern_kind
    audit.chain_multicast_fanout_count = modifier.chain_multicast_fanout_count
    log.info(string.format(
        "SPELLFORGE_CHAIN_MODIFIER_POLICY_COMPAT_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s payload_modifier_kind=%s",
        tostring(plan and plan.recipe_id),
        tostring(audit.source_slot_id),
        tostring(audit.payload_slot_id),
        tostring(modifier.payload_modifier_kind)
    ))
    return modifier, nil, audit
end

function live_chain.selectV0Plan(plan, opts)
    local options = opts or {}
    local audit = chain_targeting.inspectPlan(plan, {
        max_hops = options.max_hops or limits.MAX_CHAIN_HOPS,
        max_jobs = options.max_jobs or limits.MAX_CHAIN_JOBS_PER_CAST,
        scan_radius = options.scan_radius,
        max_candidates = options.max_candidates or options.candidate_cap,
        allow_chain_multicast = chainMulticastEnabled(options),
        allow_chain_pattern = options.allow_chain_pattern == true or options.allow_payload_pattern == true or options.force_payload_pattern_enabled == true,
        allow_payload_pattern = options.allow_payload_pattern == true or options.force_payload_pattern_enabled == true,
        allow_chain_event_continuation = options.allow_chain_event_continuation == true,
        max_chain_multicast_fanout = options.max_chain_multicast_fanout,
        max_chain_pattern_fanout = options.max_chain_pattern_fanout,
    })
    if audit.chain_candidate ~= true then
        return nil, audit.rejection_reason or "unsupported_chain_shape", audit
    end
    if audit.chain_shape ~= "source_chain_payload" and audit.chain_shape ~= "trigger_payload_chain" then
        return nil, "unsupported_chain_shape", audit
    end

    local modifier = options.prepared_modifier
    if type(modifier) ~= "table" then
        local modifier_reason = nil
        modifier, modifier_reason = inspectPayloadModifier(plan, audit, options)
        if not modifier then
            audit.rejection_reason = modifier_reason
            return nil, modifier_reason or "chain_payload_modifier_deferred", audit
        end
    end
    log.info(string.format(
        "SPELLFORGE_CHAIN_MODIFIER_POLICY_COMPAT_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s payload_modifier_kind=%s",
        tostring(plan and plan.recipe_id),
        tostring(audit.source_slot_id),
        tostring(audit.payload_slot_id),
        tostring(modifier.payload_modifier_kind)
    ))
    if modifier.has_pattern_payload == true then
        log.info(string.format(
            "SPELLFORGE_CHAIN_PATTERN_POLICY_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s pattern_kind=%s fanout_count=%s payload_modifier_kind=%s",
            tostring(plan and plan.recipe_id),
            tostring(audit.source_slot_id),
            tostring(audit.payload_slot_id),
            tostring(modifier.chain_pattern_kind),
            tostring(modifier.chain_multicast_fanout_count or 1),
            tostring(modifier.payload_modifier_kind)
        ))
    end
    if modifier.payload_modifier_kind == "speed_plus_size_plus" and modifier.has_multicast_payload == true then
        log.info(string.format(
            "SPELLFORGE_CHAIN_SPEED_SIZE_MULTICAST_POLICY_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s fanout_count=%s pattern_kind=%s",
            tostring(plan and plan.recipe_id),
            tostring(audit.source_slot_id),
            tostring(audit.payload_slot_id),
            tostring(modifier.chain_multicast_fanout_count or 1),
            tostring(modifier.chain_pattern_kind)
        ))
    end

    local slots_by_id = slotById(plan.emission_slots)
    local helpers_by_slot = helperBySlotId(plan.helper_records)
    local source_slot = slots_by_id[audit.source_slot_id]
    local payload_slot = slots_by_id[audit.payload_slot_id]
    local source_helper = helpers_by_slot[audit.source_slot_id]
    local payload_helper = helpers_by_slot[audit.payload_slot_id]

    if not source_slot or not payload_slot then
        return nil, "chain_slot_mapping_missing", audit
    end
    if not source_helper or type(source_helper.engine_id) ~= "string" or source_helper.engine_id == "" then
        return nil, "chain_source_helper_missing", audit
    end
    if not payload_helper or type(payload_helper.engine_id) ~= "string" or payload_helper.engine_id == "" then
        return nil, "chain_payload_helper_missing", audit
    end

    local prefix = analyzePayloadPrefixOps(payload_slot.prefix_ops)
    if prefix.chain_count ~= 1 or prefix.chain_op == nil then
        return nil, "chain_payload_prefix_missing", audit
    end
    local side_kind, side_op, side_reason = sideContinuationKind(payload_slot)
    if side_reason then
        return nil, side_reason, audit
    end
    local helper_side_kind, helper_side_op, helper_side_reason = sideContinuationKind(payload_helper)
    if helper_side_reason then
        return nil, helper_side_reason, audit
    end
    if side_kind ~= nil or helper_side_kind ~= nil
        or hasPayloadBindings(payload_slot.payload_bindings)
        or hasPayloadBindings(payload_helper.payload_bindings) then
        if side_kind == nil or helper_side_kind ~= side_kind then
            return nil, "chain_nested_payload_deferred", audit
        end
        if options.allow_chain_event_continuation ~= true then
            return nil, "chain_trigger_timer_deferred", audit
        end
        if side_kind == "Trigger" and options.allow_chain_trigger_side_continuation == false then
            return nil, "chain_trigger_timer_deferred", audit
        end
        if side_kind == "Timer" and options.allow_chain_timer_side_continuation == false then
            return nil, "chain_trigger_timer_deferred", audit
        end
    elseif hasOps(payload_helper.postfix_ops) then
        return nil, "chain_payload_nested_deferred", audit
    end
    local helper_prefix = analyzePayloadPrefixOps(payload_helper.prefix_ops)
    if helper_prefix.chain_count ~= 1 then
        return nil, "chain_payload_modifier_deferred", audit
    end
    if helper_prefix.speed_count ~= prefix.speed_count or helper_prefix.size_count ~= prefix.size_count then
        return nil, "chain_modifier_payload_unsupported", audit
    end
    if helper_prefix.multicast_count ~= prefix.multicast_count then
        return nil, "chain_multicast_payload_unsupported", audit
    end
    if helper_prefix.pattern_count ~= prefix.pattern_count or helper_prefix.pattern_kind ~= prefix.pattern_kind then
        return nil, "chain_pattern_disabled", audit
    end
    if helper_prefix.unsupported_count > 0
        or #(payload_helper.prefix_ops or {}) ~= #(payload_slot.prefix_ops or {}) then
        return nil, "chain_payload_modifier_deferred", audit
    end

    local side_payloads = nil
    local side_budget = nil
    local side_budget_cap = nil
    local timer_seconds = nil
    local timer_delay_ticks = nil
    if side_kind ~= nil then
        local side_payload_reason = nil
        side_payloads, side_payload_reason = resolveSidePayloads(plan, payload_slot, side_kind, options)
        if not side_payloads then
            return nil, side_payload_reason or "chain_nested_payload_deferred", audit
        end
        local side_budget_reason = nil
        side_budget_reason, side_budget, side_budget_cap = sideBudgetReason(
            side_kind,
            audit.max_hops,
            modifier.chain_multicast_fanout_count or 1,
            side_payloads.payload_count or 1,
            options
        )
        if side_budget_reason then
            audit.chain_side_continuation_kind = side_kind
            audit.chain_side_payload_count = side_payloads.payload_count or 1
            audit.chain_event_continuation_budget = side_budget
            audit.chain_event_continuation_budget_cap = side_budget_cap
            return nil, side_budget_reason, audit
        end
        if side_kind == "Timer" then
            local delay_reason = nil
            timer_seconds, timer_delay_ticks, _, delay_reason = live_timer.delayFromOp(side_op or helper_side_op)
            if not timer_seconds then
                return nil, delay_reason or "timer_delay_invalid", audit
            end
        end
        audit.chain_side_continuation_kind = side_kind
        audit.chain_side_payload_count = side_payloads.payload_count or 1
        audit.chain_event_continuation_budget = side_budget
        audit.chain_event_continuation_budget_cap = side_budget_cap
        runtime_stats.inc("chain_event_continuation_policy_ok")
        runtime_stats.inc("chain_event_continuation_budget_ok")
        log.info(string.format(
            "SPELLFORGE_CHAIN_EVENT_CONTINUATION_POLICY_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s side_kind=%s side_payload_count=%s chain_fanout_count=%s max_hops=%s",
            tostring(plan and plan.recipe_id),
            tostring(audit.source_slot_id),
            tostring(audit.payload_slot_id),
            tostring(side_kind),
            tostring(side_payloads.payload_count or 1),
            tostring(modifier.chain_multicast_fanout_count or 1),
            tostring(audit.max_hops)
        ))
        log.info(string.format(
            "SPELLFORGE_CHAIN_EVENT_CONTINUATION_BUDGET_OK recipe_id=%s source_slot_id=%s payload_slot_id=%s side_kind=%s budget=%s cap=%s",
            tostring(plan and plan.recipe_id),
            tostring(audit.source_slot_id),
            tostring(audit.payload_slot_id),
            tostring(side_kind),
            tostring(side_budget),
            tostring(side_budget_cap)
        ))
    end

    local chain_payload_slot_ids = audit.payload_slot_ids
    if type(chain_payload_slot_ids) ~= "table" or #chain_payload_slot_ids == 0 then
        chain_payload_slot_ids = { audit.payload_slot_id }
    end
    local chain_payload_helper_engine_ids = {}
    for index, slot_id in ipairs(chain_payload_slot_ids) do
        local helper = helpers_by_slot[slot_id]
        chain_payload_helper_engine_ids[index] = helper and helper.engine_id or nil
    end

    return {
        ok = true,
        chain_shape = audit.chain_shape,
        requested_hops = audit.requested_hops,
        max_hops = audit.max_hops,
        candidate_cap = tonumber(options.max_candidates or options.candidate_cap) or limits.MAX_CHAIN_SCAN_CANDIDATES,
        max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        chaos_budget_profile = options.chaos_budget_profile,
        source_slot_id = audit.source_slot_id,
        payload_slot_id = audit.payload_slot_id,
        payload_slot_ids = chain_payload_slot_ids,
        source_helper_engine_id = source_helper.engine_id,
        payload_helper_engine_id = payload_helper.engine_id,
        payload_helper_engine_ids = chain_payload_helper_engine_ids,
        payload_effect_id = firstEffectId(payload_helper),
        payload_modifier_kind = modifier.payload_modifier_kind,
        payload_multicast = modifier.has_multicast_payload == true,
        payload_pattern = modifier.has_pattern_payload == true,
        payload_pattern_kind = modifier.chain_pattern_kind,
        has_multicast_payload = modifier.has_multicast_payload == true,
        has_pattern_payload = modifier.has_pattern_payload == true,
        chain_pattern_kind = modifier.chain_pattern_kind,
        chain_multicast_fanout_count = modifier.chain_multicast_fanout_count or 1,
        has_speed_plus_payload = modifier.has_speed_plus_payload == true,
        has_size_plus_payload = modifier.has_size_plus_payload == true,
        speed_plus_mutation = modifier.speed_plus_mutation,
        size_plus_mutation = modifier.size_plus_mutation,
        size_plus_apply_result = modifier.size_plus_apply_result,
        chain_side_continuation_kind = side_kind,
        chain_side_continuation_id = side_kind and string.format(
            "%s:%s:%s",
            tostring(side_kind),
            tostring(audit.source_slot_id),
            tostring(audit.payload_slot_id)
        ) or nil,
        chain_side_payloads = side_payloads and side_payloads.payload_slots or nil,
        chain_side_payload_slot_id = side_payloads and side_payloads.payload_slot_id or nil,
        chain_side_payload_helper_engine_id = side_payloads and side_payloads.payload_helper_engine_id or nil,
        chain_side_payload_slot_ids = side_payloads and side_payloads.payload_slot_ids or nil,
        chain_side_payload_helper_engine_ids = side_payloads and side_payloads.payload_helper_engine_ids or nil,
        chain_side_payload_count = side_payloads and side_payloads.payload_count or nil,
        chain_side_payload_group_key = side_payloads and side_payloads.payload_group_key or nil,
        chain_side_payload_multicast = side_payloads and side_payloads.is_payload_multicast == true or nil,
        chain_side_payload_pattern = side_payloads and side_payloads.is_payload_pattern == true or nil,
        chain_side_payload_pattern_kind = side_payloads and side_payloads.pattern_kind or nil,
        chain_side_payload_pattern_op = side_payloads and side_payloads.pattern_op or nil,
        chain_side_has_payload_modifier = side_payloads and side_payloads.has_payload_modifier == true or nil,
        chain_side_payload_modifier_kinds = side_payloads and side_payloads.payload_modifier_kinds or nil,
        chain_side_timer_seconds = timer_seconds,
        chain_side_timer_delay_ticks = timer_delay_ticks,
        chain_event_continuation_budget = side_budget,
        chain_event_continuation_budget_cap = side_budget_cap,
        has_trigger_payload_context = audit.has_trigger_payload_context == true,
        source = {
            slot = source_slot,
            helper = source_helper,
        },
        payload = {
            slot = payload_slot,
            helper = payload_helper,
        },
        audit = audit,
    }, nil, audit
end

function live_chain.decorateSourceJob(job, binding)
    if type(job) ~= "table" or type(binding) ~= "table" then
        return
    end
    job.chain_runtime = true
    job.chain_role = "source"
    job.chain_id = binding.chain_id
    job.chain_hop_index = 0
    job.chain_max_hops = binding.max_hops
    job.chain_targeting_mode = binding.targeting_mode or "no_immediate_repeat"
    job.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.current_source_slot_id = binding.source_slot_id
    job.parent_slot_id = nil
    job.payload_depth = 0
    job.source_slot_id = binding.source_slot_id
    job.source_helper_engine_id = binding.source_helper_engine_id
    job.payload_slot_id = binding.payload_slot_id
    job.payload_modifier_kind = binding.payload_modifier_kind
    job.branch_scope = binding.branch_scope or "default"
    job.branch_id = binding.root_branch_id or binding.chain_id
    job.branch_kind = binding.branch_kind or "chain"
    job.branch_count = binding.chain_multicast_fanout_count or 1
    if binding.chain_shape == "trigger_payload_chain" then
        job.source_postfix_opcode = "Trigger"
    end
    job.payload = job.payload or {}
    job.payload.chain_runtime = true
    job.payload.chain_role = "source"
    job.payload.chain_id = binding.chain_id
    job.payload.chain_hop_index = 0
    job.payload.chain_max_hops = binding.max_hops
    job.payload.chain_targeting_mode = binding.targeting_mode or "no_immediate_repeat"
    job.payload.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.payload.current_source_slot_id = binding.source_slot_id
    job.payload.parent_slot_id = nil
    job.payload.payload_depth = 0
    job.payload.source_slot_id = binding.source_slot_id
    job.payload.source_helper_engine_id = binding.source_helper_engine_id
    job.payload.payload_slot_id = binding.payload_slot_id
    job.payload.payload_modifier_kind = binding.payload_modifier_kind
    job.payload.branch_scope = binding.branch_scope or "default"
    job.payload.branch_id = binding.root_branch_id or binding.chain_id
    job.payload.branch_kind = binding.branch_kind or "chain"
    job.payload.branch_count = binding.chain_multicast_fanout_count or 1
    if binding.chain_shape == "trigger_payload_chain" then
        job.payload.source_postfix_opcode = "Trigger"
    end
end

function live_chain.registerBinding(binding)
    local input = binding or {}
    if type(input.recipe_id) ~= "string" or input.recipe_id == ""
        or type(input.source_slot_id) ~= "string" or input.source_slot_id == ""
        or type(input.payload_slot_id) ~= "string" or input.payload_slot_id == ""
        or type(input.chain_id) ~= "string" or input.chain_id == "" then
        return false
    end
    local cast_key = castSourceKey(input.recipe_id, input.source_slot_id, input.cast_id)
    input.runtime_generation = runtime_session.currentGeneration()
    bindings_by_cast_source[cast_key] = input
    bindings_by_chain_id[input.chain_id] = input
    appendBounded(binding_order, cast_key, MAX_BINDINGS, function(evicted)
        local evicted_binding = bindings_by_cast_source[evicted]
        if evicted_binding and evicted_binding.chain_id then
            bindings_by_chain_id[evicted_binding.chain_id] = nil
        end
        bindings_by_cast_source[evicted] = nil
    end)
    return true
end

local function bindingForRoute(route)
    if not route or route.ok ~= true then
        return nil
    end
    local user_data = route.user_data or {}
    if type(user_data.chain_id) == "string" and user_data.chain_id ~= "" then
        local by_chain = bindings_by_chain_id[user_data.chain_id]
        if by_chain then
            return by_chain
        end
    end
    local cast_id = user_data.cast_id
    if type(route.recipe_id) == "string" and type(route.slot_id) == "string" and type(cast_id) == "string" then
        return bindings_by_cast_source[castSourceKey(route.recipe_id, route.slot_id, cast_id)]
    end
    return nil
end

local function routeHopIndex(route, binding)
    local user_data = route.user_data or {}
    if user_data.chain_runtime == true
        and user_data.chain_id == binding.chain_id
        and (user_data.chain_role == "payload"
            or (route.slot_id == binding.payload_slot_id
                and route.helper_engine_id == binding.payload_helper_engine_id)) then
        return tonumber(user_data.chain_hop_index) or 0, "payload"
    end
    if route.slot_id == binding.source_slot_id
        and route.helper_engine_id == binding.source_helper_engine_id then
        return 0, "source"
    end
    return nil, nil
end

local function routeContinuationScope(route)
    local user_data = route and route.user_data or nil
    if user_data and type(user_data.branch_scope) == "string" and user_data.branch_scope ~= "" then
        return user_data.branch_scope
    end
    if user_data and user_data.bounce_runtime == true and user_data.bounce_index ~= nil then
        local bounce_id = tostring(user_data.bounce_id or "no-bounce")
        if string.sub(bounce_id, 1, 7) ~= "bounce:" then
            bounce_id = "bounce:" .. bounce_id
        end
        return string.format(
            "%s:b%s",
            bounce_id,
            tostring(user_data.bounce_index)
        )
    end
    return "default"
end

local function copyBounceContinuationScope(route, target)
    local user_data = route and route.user_data or nil
    if type(target) ~= "table" or not user_data
        or user_data.bounce_runtime ~= true
        or user_data.bounce_index == nil then
        return
    end

    -- Keep Bounce-triggered Chain branches independent without making the
    -- chained payload itself bounce. These fields are continuation identity.
    target.bounce_runtime = true
    target.bounce_role = "chain_branch_scope"
    target.bounce_id = user_data.bounce_id
    target.bounce_index = user_data.bounce_index
    target.bounce_max = user_data.bounce_max
    target.bounce_power = user_data.bounce_power
    target.bounce_trigger_payload_slot_id = user_data.bounce_trigger_payload_slot_id
    target.bounce_final = user_data.bounce_final
end

local function copyPierceContinuationScope(route, target)
    local user_data = route and route.user_data or nil
    if type(target) ~= "table" or not user_data or user_data.pierce_runtime ~= true then
        return
    end

    target.pierce_runtime = true
    target.pierce_role = "chain_branch_scope"
    target.pierce_id = user_data.pierce_id
    target.pierce_count = user_data.pierce_count
    target.pierce_limit = user_data.pierce_limit
    target.pierce_trigger_payload_slot_id = user_data.pierce_trigger_payload_slot_id
end

local function duplicateKey(route, binding, hop_index)
    return string.format(
        "chain:%s:%s:%s:%s:%s:%s:%s:%s",
        tostring(binding.chain_id),
        tostring(binding.cast_id or (route.user_data and route.user_data.cast_id) or "no-cast"),
        tostring(hop_index),
        tostring(route.slot_id),
        tostring(route.helper_engine_id),
        tostring(route.projectile_id or "no-projectile"),
        tostring(binding.payload_slot_id),
        routeContinuationScope(route)
    )
end

-- One Chain continuation may produce several hit reports from a single detonation.
-- Claim by hop, not projectile, so async LOS cannot fan those reports into branches.
-- Bounce sources are the exception: each bounce index is its own discrete trigger.
local function continuationClaimKey(route, binding, hop_index)
    local user_data = route and route.user_data or {}
    local continuation_group = user_data.chain_continuation_group_id
        or string.format(
            "%s:%s:%s",
            tostring(route and route.slot_id),
            tostring(route and route.helper_engine_id),
            tostring(binding.payload_slot_id)
        )
    return string.format(
        "chain-continuation:%s:%s:%s:%s:%s",
        tostring(binding.chain_id),
        tostring(binding.cast_id or (user_data and user_data.cast_id) or "no-cast"),
        tostring(hop_index),
        tostring(continuation_group),
        routeContinuationScope(route)
    )
end

local function rememberDuplicateKey(key)
    duplicate_keys[key] = true
    appendBounded(duplicate_order, key, MAX_DUPLICATE_KEYS, function(evicted)
        duplicate_keys[evicted] = nil
    end)
end

local function rememberContinuationClaim(key)
    continuation_claims[key] = true
    appendBounded(continuation_claim_order, key, MAX_DUPLICATE_KEYS, function(evicted)
        continuation_claims[evicted] = nil
    end)
end

local function clearPendingLos(request_id)
    local pending = request_id and pending_los[request_id] or nil
    if pending and pending.timer then
        pending.timer:cancel()
    end
    if request_id then
        pending_los[request_id] = nil
    end
end

local function nextLosRequestId(binding, next_hop)
    next_los_request_index = next_los_request_index + 1
    return string.format(
        "chain-los:%s:%s:%d",
        tostring(binding and binding.chain_id or "chain"),
        tostring(next_hop or 0),
        next_los_request_index
    )
end

local function visibleIdSet(values)
    local set = {}
    for _, value in ipairs(values or {}) do
        if value ~= nil then
            set[tostring(value)] = true
        end
    end
    return set
end

local function filterCandidatesByVisibleIds(candidates, visible_ids)
    local visible = visibleIdSet(visible_ids)
    local filtered = {}
    for index, candidate in ipairs(candidates or {}) do
        local id = candidateToken(candidate, index)
        if visible[id] then
            filtered[#filtered + 1] = candidate
        end
    end
    return filtered
end

local function compactLosCandidate(candidate, index)
    return {
        id = candidateToken(candidate, index),
        object = candidate and candidate.object or nil,
        position = candidate and candidate.position or tablePosition(candidate),
    }
end

local function stopResult(reason, binding, route, previous_hop, extra)
    local result = extra or {}
    local branch_scope = routeContinuationScope(route)
    result.ok = result.ok ~= false
    result.stopped = true
    result.stop_reason = reason
    result.rejection_reason = result.rejection_reason
    result.chain_id = binding and binding.chain_id or nil
    result.cast_id = binding and binding.cast_id or nil
    result.source_slot_id = binding and binding.source_slot_id or nil
    result.payload_slot_id = binding and binding.payload_slot_id or nil
    result.chain_hop_index = previous_hop
    result.max_hops = binding and binding.max_hops or nil
    result.projectile_id = route and route.projectile_id or nil
    result.branch_scope = branch_scope
    log.info(string.format(
        "SPELLFORGE_CHAIN_HOP_STOPPED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s max_hops=%s stop_reason=%s",
        tostring(binding and binding.recipe_id or nil),
        tostring(binding and binding.cast_id or nil),
        tostring(binding and binding.chain_id or nil),
        tostring(branch_scope),
        tostring(previous_hop),
        tostring(binding and binding.max_hops or nil),
        tostring(reason)
    ))
    return result
end

local function completeLosRequest(request_id, payload)
    local pending = request_id and pending_los[request_id] or nil
    if not pending then
        return { ok = true, ignored = true, reason = "unknown_chain_los_request" }
    end

    if runtime_session.shouldDrop(pending.runtime_generation, "live_chain_los", {
        id = request_id,
        strict = true,
    }) then
        clearPendingLos(request_id)
        return { ok = true, ignored = true, stale_generation = true }
    end

    clearPendingLos(request_id)

    if payload and payload.ok == false then
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_los_unavailable")
        return stopResult(payload.rejection_reason or "chain_los_unavailable", pending.binding, pending.route, pending.previous_hop, {
            ok = false,
            rejection_reason = payload.rejection_reason or "chain_los_unavailable",
            los_request_id = request_id,
            los_error = payload.error,
        })
    end

    local filtered = filterCandidatesByVisibleIds(pending.candidates, payload and payload.visible_ids or {})
    local original_count = #(pending.candidates or {})
    local provider_result = {}
    for key, value in pairs(pending.provider_result or {}) do
        provider_result[key] = value
    end
    provider_result.candidate_count = #filtered
    provider_result.los_candidate_count = original_count
    provider_result.los_visible_count = #filtered
    provider_result.los_blocked_count = tonumber(payload and payload.blocked_count) or math.max(0, original_count - #filtered)
    provider_result.los_raycast_count = tonumber(payload and payload.raycast_count) or 0
    provider_result.los_request_id = request_id

    log.info(string.format(
        "SPELLFORGE_CHAIN_LOS_RESULT recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s request_id=%s candidate_count=%s visible_count=%s blocked_count=%s raycast_count=%s",
        tostring(pending.binding and pending.binding.recipe_id or nil),
        tostring(pending.binding and pending.binding.cast_id or nil),
        tostring(pending.binding and pending.binding.chain_id or nil),
        tostring(routeContinuationScope(pending.route)),
        tostring(pending.next_hop),
        tostring(request_id),
        tostring(original_count),
        tostring(#filtered),
        tostring(provider_result.los_blocked_count),
        tostring(provider_result.los_raycast_count)
    ))

    if #filtered == 0 then
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_stop_no_target")
        runtime_stats.inc("chain_runtime_no_target")
        runtime_stats.inc("chain_runtime_los_no_visible_target")
        return stopResult("no_visible_chain_target", pending.binding, pending.route, pending.previous_hop, {
            resolved = {
                ok = false,
                rejection_reason = "no_visible_chain_target",
                los_request_id = request_id,
                candidate_count = original_count,
                visible_count = 0,
            },
            provider_result = provider_result,
        })
    end

    runtime_stats.inc("chain_runtime_los_visible_candidates", #filtered)
    return live_chain.handleResolvedHit(pending.route, {
        precollected_candidates = filtered,
        precollected_provider_result = provider_result,
        bypass_duplicate = true,
        skip_los = true,
        resume_after_los = true,
        max_chain_ticks = pending.options and pending.options.max_chain_ticks or nil,
        max_jobs_per_tick = pending.options and pending.options.max_jobs_per_tick or nil,
        max_live_launches_per_tick = pending.options and pending.options.max_live_launches_per_tick or nil,
        simulate_update_ticks = pending.options and pending.options.simulate_update_ticks == true,
        simulated_dt_seconds = pending.options and pending.options.simulated_dt_seconds or nil,
        force_ir_chain_runtime_enabled = pending.options and pending.options.force_ir_chain_runtime_enabled == true,
        force_ir_chain_runtime_disabled = pending.options and pending.options.force_ir_chain_runtime_disabled == true,
    })
end

local function requestLosFilter(binding, route, previous_hop, current_target, hit_context, candidates, provider_result, options)
    local candidate_count = #(candidates or {})
    if options.skip_los == true
        or not provider_result
        or provider_result.provider ~= "real"
        or candidate_count == 0 then
        return nil
    end

    local los_actor = route.attacker or binding.actor
    if not los_actor or type(los_actor.sendEvent) ~= "function" then
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_los_unavailable")
        return stopResult("chain_los_unavailable", binding, route, previous_hop, {
            ok = false,
            rejection_reason = "chain_los_unavailable",
        })
    end

    local next_hop = (tonumber(previous_hop) or 0) + 1
    local request_id = nextLosRequestId(binding, next_hop)
    local start_pos = elevatedPosition(tablePosition(current_target), limits.CHAIN_AIM_HEIGHT)
        or hit_context.current_hit_position

    local los_candidates = {}
    for index, candidate in ipairs(candidates or {}) do
        los_candidates[#los_candidates + 1] = compactLosCandidate(candidate, index)
    end

    pending_los[request_id] = {
        runtime_generation = runtime_session.currentGeneration(),
        binding = binding,
        route = route,
        previous_hop = previous_hop,
        next_hop = next_hop,
        candidates = candidates,
        provider_result = provider_result,
        options = options,
    }
    appendBounded(pending_los_order, request_id, MAX_PENDING_LOS, function(evicted)
        pending_los[evicted] = nil
    end)
    pending_los[request_id].timer = async:newUnsavableSimulationTimer(LOS_TIMEOUT_SECONDS, function()
        local pending = pending_los[request_id]
        if pending and runtime_session.shouldDrop(pending.runtime_generation, "live_chain_los_timeout", {
            id = request_id,
            strict = true,
        }) then
            clearPendingLos(request_id)
            return
        end
        if pending_los[request_id] then
            completeLosRequest(request_id, {
                ok = false,
                rejection_reason = "chain_los_timeout",
                error = "Chain LOS request timed out",
            })
        end
    end)

    local sent, send_err = pcall(function()
        los_actor:sendEvent(events.CHAIN_LOS_REQUEST, {
            request_id = request_id,
            start_pos = start_pos,
            current_target = current_target,
            candidates = los_candidates,
        })
    end)
    if not sent then
        clearPendingLos(request_id)
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_los_unavailable")
        return stopResult("chain_los_unavailable", binding, route, previous_hop, {
            ok = false,
            rejection_reason = "chain_los_unavailable",
            los_error = tostring(send_err),
        })
    end

    runtime_stats.inc("chain_runtime_los_requests")
    log.info(string.format(
        "SPELLFORGE_CHAIN_LOS_REQUESTED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s request_id=%s candidate_count=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.chain_id),
        tostring(routeContinuationScope(route)),
        tostring(next_hop),
        tostring(request_id),
        tostring(candidate_count)
    ))

    return {
        ok = true,
        pending_los = true,
        mode = "chain_runtime",
        chain_runtime = true,
        chain_id = binding.chain_id,
        cast_id = binding.cast_id,
        chain_hop_index = next_hop,
        previous_hop_index = previous_hop,
        max_hops = binding.max_hops,
        los_request_id = request_id,
        branch_scope = routeContinuationScope(route),
    }
end

local function buildIrChainRuntimePlan(binding, route, options, previous_hop, next_hop, fanout_count, continuation_group_id, branch_scope)
    if not irChainRuntimeEnabled(options) then
        return nil
    end

    runtime_stats.inc("ir_chain_runtime_attempts")
    local plan = binding.plan or binding.compiled_plan or binding.attached_plan
    local source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    local event = {
        event_kind = "chain_hit",
        source_slot_id = binding.source_slot_id,
        source_postfix_opcode = "Chain",
        cast_id = binding.cast_id,
        source_job_id = source_job_id,
        parent_job_id = route.user_data and route.user_data.job_id or source_job_id,
        chain_id = binding.chain_id,
        chain_hop_index = previous_hop,
        chain_max_hops = binding.max_hops,
        chain_targeting_mode = binding.targeting_mode or "no_immediate_repeat",
        chain_continuation_group_id = continuation_group_id,
        branch_scope = branch_scope,
        branch_parent_id = continuation_group_id,
    }
    local planner_options = irPlannerOptions(binding, options)
    local planned = ir_runtime_adapter.planEvent(binding, plan, event, planner_options)
    if planned.ok ~= true then
        if planned.stage == "ir" then
            return irChainFallback(binding, planned.rejection_reason)
        end
        return irChainMismatch(binding, planned.rejection_reason or "continuation_plan_failed")
    end
    local continuation_plan = planned.continuation_plan
    local job_plan = planned.job_plan
    local valid, reason = validateIrChainJobPlan(binding, fanout_count, continuation_plan, job_plan)
    if not valid then
        return irChainMismatch(binding, reason)
    end

    log.info(string.format(
        "SPELLFORGE_IR_CHAIN_RUNTIME_PLANNED recipe_id=%s cast_id=%s chain_id=%s source_slot_id=%s payload_count=%s hop_index=%s job_count=%s branch_kind=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.chain_id),
        tostring(binding.source_slot_id),
        tostring(fanout_count),
        tostring(next_hop),
        tostring(job_plan.planned_job_count),
        tostring(job_plan.planned_jobs and job_plan.planned_jobs[1] and job_plan.planned_jobs[1].branch_kind or nil)
    ))
    return {
        ok = true,
        continuation_plan = continuation_plan,
        job_plan = job_plan,
        event = event,
    }
end

function live_chain.handleResolvedHit(route, opts)
    local options = opts or {}
    if not route or route.ok ~= true then
        return { ok = false, ignored = true, error = route and route.error or "unresolved hit" }
    end

    local binding = bindingForRoute(route)
    if not binding then
        return { ok = true, ignored = true, reason = "no_live_chain_binding" }
    end
    if runtime_session.shouldDrop(binding.runtime_generation, "live_chain_binding", {
        id = binding.chain_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.user_data and runtime_session.shouldDrop(route.user_data.runtime_generation, "live_chain_route", {
        id = route.projectile_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end

    local previous_hop, route_kind = routeHopIndex(route, binding)
    if previous_hop == nil then
        return { ok = true, ignored = true, reason = "not_chain_source_or_payload" }
    end
    local branch_scope = routeContinuationScope(route)

    if options.force_enabled ~= true and binding.force_enabled ~= true and not dev.liveChainRuntimeEnabled() then
        runtime_stats.inc("chain_runtime_rejected")
        runtime_stats.inc("chain_runtime_disabled_reject")
        return { ok = false, disabled = true, error = "live Chain runtime disabled" }
    end

    if route_kind == "source" and options.resume_after_los ~= true then
        runtime_stats.inc("chain_runtime_source_hits")
    end
    if options.resume_after_los ~= true then
        runtime_stats.inc("chain_runtime_hop_attempts")
    end

    if previous_hop >= (tonumber(binding.max_hops) or 0) then
        runtime_stats.inc("chain_runtime_stop_max_hops")
        return stopResult("max_hops_reached", binding, route, previous_hop, {
            completed_hops = previous_hop,
            selected_target_ids = {},
        })
    end

    local current_target = route.target
    if current_target == nil and route.user_data and route.user_data.selected_target_id ~= nil then
        current_target = {
            id = route.user_data.selected_target_id,
            object = route.user_data.selected_target_id,
            is_actor = true,
        }
    end
    if targetIsKnownNonActor(current_target) then
        runtime_stats.inc("chain_runtime_hit_non_actor")
        return stopResult("chain_hit_non_actor", binding, route, previous_hop, {
            ignored = true,
            current_hit_target_id = objectToken(current_target),
        })
    end

    local key = duplicateKey(route, binding, previous_hop)
    local claim_key = continuationClaimKey(route, binding, previous_hop)
    if options.bypass_duplicate ~= true then
        if continuation_claims[claim_key] or duplicate_keys[key] then
            runtime_stats.inc("chain_runtime_duplicate_suppressed")
            log.info(string.format(
                "SPELLFORGE_CHAIN_DUPLICATE_SUPPRESSED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s key=%s claim_key=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(previous_hop),
                tostring(shortKey(key) or "<long>"),
                tostring(shortKey(claim_key) or "<long>")
            ))
            if route.user_data and route.user_data.branch_kind == "chain_pattern" then
                log.info(string.format(
                    "SPELLFORGE_CHAIN_PATTERN_SIBLING_NONCONTINUING_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s continuation_group_id=%s",
                    tostring(binding.recipe_id),
                    tostring(binding.cast_id),
                    tostring(binding.chain_id),
                    tostring(branch_scope),
                    tostring(previous_hop),
                    tostring(route.user_data.chain_continuation_group_id)
                ))
            end
            return {
                ok = true,
                duplicate_suppressed = true,
                duplicate_key = key,
                continuation_claim_key = claim_key,
                chain_id = binding.chain_id,
                chain_hop_index = previous_hop,
                max_hops = binding.max_hops,
                branch_scope = branch_scope,
            }
        end
        rememberDuplicateKey(key)
        rememberContinuationClaim(claim_key)
        if route.user_data and route.user_data.branch_kind == "chain_pattern" then
            log.info(string.format(
                "SPELLFORGE_CHAIN_PATTERN_CONTINUATION_CLAIM_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s continuation_group_id=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(previous_hop),
                tostring(route.user_data.chain_continuation_group_id)
            ))
        end
        if binding.chain_side_continuation_kind ~= nil then
            runtime_stats.inc("chain_event_continuation_claim_stable")
            log.info(string.format(
                "SPELLFORGE_CHAIN_EVENT_CONTINUATION_CLAIM_STABLE recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s side_kind=%s continuation_group_id=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(previous_hop),
                tostring(binding.chain_side_continuation_kind),
                tostring(route.user_data and route.user_data.chain_continuation_group_id)
            ))
        end
    end

    local next_hop = previous_hop + 1
    local hit_context = {
        caster = route.attacker or binding.actor,
        source_target = current_target,
        current_hit_target = current_target,
        current_hit_position = route.hit_pos or tablePosition(current_target),
        current_cell = cellToken(current_target and current_target.cell),
        cast_id = binding.cast_id,
        recipe_id = binding.recipe_id,
        source_slot_id = binding.source_slot_id,
        payload_slot_id = binding.payload_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        chain_id = binding.chain_id,
        hop_index = next_hop,
        max_hops = binding.max_hops,
        exclude_caster = true,
        exclude_current_hit_target = true,
    }
    local candidates = options.precollected_candidates
    local provider_result = options.precollected_provider_result
    if candidates == nil then
        local provider = options.candidate_provider or binding.candidate_provider or binding.target_provider
        candidates, provider_result = collectCandidates(provider, hit_context, binding, options)
    end
    if candidates == nil then
        local reason = provider_result and (provider_result.rejection_reason or provider_result.unsupported_reason)
            or "chain_target_provider_missing"
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_target_provider_missing")
        return stopResult(reason, binding, route, previous_hop, {
            ok = false,
            rejection_reason = reason,
            provider_result = provider_result,
        })
    end
    local los_result = requestLosFilter(binding, route, previous_hop, current_target, hit_context, candidates, provider_result, options)
    if los_result then
        return los_result
    end
    local resolved = chain_targeting.resolveNextTarget(hit_context, candidates, {
        hop_index = next_hop,
        max_hops = binding.max_hops,
        scan_radius = binding.scan_radius,
        max_radius = limits.MAX_CHAIN_SCAN_RADIUS,
        max_candidates = binding.candidate_cap or limits.MAX_CHAIN_SCAN_CANDIDATES,
        max_targets = limits.MAX_CHAIN_TARGETS_PER_HOP,
        targeting_mode = binding.targeting_mode or "no_immediate_repeat",
        chain_id = binding.chain_id,
    })
    local selected = resolved.selected_targets and resolved.selected_targets[1] or nil
    if not resolved.ok or not selected then
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_stop_no_target")
        runtime_stats.inc("chain_runtime_no_target")
        return stopResult(resolved.rejection_reason or "no_valid_chain_target", binding, route, previous_hop, {
            resolved = resolved,
            provider_result = provider_result,
        })
    end

    local origin = route.hit_pos or tablePosition(current_target)
    if provider_result and provider_result.provider == "real" then
        origin = elevatedPosition(tablePosition(current_target), limits.CHAIN_AIM_HEIGHT) or origin
    end
    local start_pos = vectorFromPosition(origin)
    local direction, direction_err = directionBetween(origin, selected.position)
    if not start_pos or not direction then
        runtime_stats.inc("chain_runtime_hop_rejected")
        runtime_stats.inc("chain_runtime_context_reject")
        return stopResult(direction_err or "chain_target_direction_missing", binding, route, previous_hop, {
            ok = false,
            rejection_reason = direction_err or "chain_target_direction_missing",
            resolved = resolved,
        })
    end

    runtime_stats.inc("chain_runtime_hop_qualified")
    local selected_object = candidateObjectForSelected(candidates, selected.id)
    if type(selected_object) ~= "table" and type(selected_object) ~= "userdata" then
        selected_object = nil
    end
    log.info(string.format(
        "SPELLFORGE_CHAIN_HOP_TARGET_SELECTED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s source_slot_id=%s payload_slot_id=%s hop_index=%s max_hops=%s current_hit_target_id=%s selected_target_id=%s targeting_mode=%s provider=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.chain_id),
        tostring(branch_scope),
        tostring(binding.source_slot_id),
        tostring(binding.payload_slot_id),
        tostring(next_hop),
        tostring(binding.max_hops),
        tostring(objectToken(current_target)),
        tostring(selected.id),
        tostring(binding.targeting_mode or "no_immediate_repeat"),
        tostring(provider_result and provider_result.provider or "unknown")
    ))
    if provider_result and provider_result.provider == "real" then
        runtime_stats.inc("chain_provider_selected_real")
        log.info(string.format(
            "SPELLFORGE_CHAIN_REAL_TARGET_SELECTED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s selected_target_id=%s candidate_count=%s radius=%s vertical_delta=%s aim_height=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(next_hop),
            tostring(selected.id),
            tostring(provider_result.candidate_count),
            tostring(provider_result.radius),
            tostring(selected.vertical_delta),
            tostring(limits.CHAIN_AIM_HEIGHT)
        ))
    end

    local source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
    local side_kind = binding.chain_side_continuation_kind
    local payload_postfix_opcode = (side_kind == "Trigger" or side_kind == "Timer") and side_kind or "Chain"
    local idempotency_key = string.format(
        "%s:%s:%s:%s",
        tostring(binding.chain_id),
        tostring(next_hop),
        tostring(selected.id),
        tostring(branch_scope)
    )
    local job_input = {
        kind = orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND,
        recipe_id = binding.recipe_id,
        slot_id = binding.payload_slot_id,
        helper_engine_id = binding.payload_helper_engine_id,
        idempotency_key = idempotency_key,
        source_job_id = source_job_id,
        parent_job_id = route.user_data and route.user_data.job_id or source_job_id,
        depth = 1,
        cast_id = binding.cast_id,
        emission_index = binding.payload_emission_index,
        group_index = binding.payload_group_index,
        fanout_count = binding.chain_multicast_fanout_count or 1,
        max_live_launches_per_tick = binding.max_live_launches_per_tick,
        chaos_budget_profile = binding.chaos_budget_profile,
        root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id,
        current_source_slot_id = binding.payload_slot_id,
        parent_slot_id = binding.source_slot_id,
        payload_depth = 1,
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        source_postfix_opcode = payload_postfix_opcode,
        payload_slot_id = binding.payload_slot_id,
        has_trigger_payload = side_kind == "Trigger" or nil,
        has_timer_payload = side_kind == "Timer" or nil,
        trigger_source_slot_id = side_kind == "Trigger" and binding.payload_slot_id or nil,
        timer_source_slot_id = side_kind == "Timer" and binding.payload_slot_id or nil,
        chain_runtime = true,
        chain_role = "payload",
        chain_id = binding.chain_id,
        chain_hop_index = next_hop,
        chain_max_hops = binding.max_hops,
        chain_targeting_mode = binding.targeting_mode or "no_immediate_repeat",
        chain_target_provider = provider_result and provider_result.provider or nil,
        chain_side_continuation_kind = side_kind,
        chain_side_continuation_id = binding.chain_side_continuation_id,
        chain_side_payload_count = binding.chain_side_payload_count,
        branch_scope = branch_scope,
        branch_kind = binding.has_pattern_payload and "chain_pattern" or binding.has_multicast_payload and "chain_multicast" or "chain",
        branch_count = binding.chain_multicast_fanout_count or 1,
        chain_continuation_group_id = string.format("%s:h%s:%s", tostring(binding.chain_id), tostring(next_hop), tostring(branch_scope)),
        current_hit_target_id = objectToken(current_target),
        selected_target_id = selected.id,
        previous_projectile_id = route.projectile_id,
        payload = {
            actor = route.attacker or binding.actor,
            start_pos = start_pos,
            direction = direction,
            hit_object = selected_object,
            excludeTarget = current_target,
            cast_id = binding.cast_id,
            source_slot_id = binding.source_slot_id,
            source_helper_engine_id = binding.source_helper_engine_id,
            source_postfix_opcode = payload_postfix_opcode,
            root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id,
            current_source_slot_id = binding.payload_slot_id,
            parent_slot_id = binding.source_slot_id,
            payload_depth = 1,
            payload_slot_id = binding.payload_slot_id,
            has_trigger_payload = side_kind == "Trigger" or nil,
            has_timer_payload = side_kind == "Timer" or nil,
            trigger_source_slot_id = side_kind == "Trigger" and binding.payload_slot_id or nil,
            timer_source_slot_id = side_kind == "Timer" and binding.payload_slot_id or nil,
            fanout_count = binding.chain_multicast_fanout_count or 1,
            emission_index = binding.payload_emission_index,
            group_index = binding.payload_group_index,
            chain_runtime = true,
            chain_role = "payload",
            chain_id = binding.chain_id,
            chain_hop_index = next_hop,
            chain_max_hops = binding.max_hops,
            chain_targeting_mode = binding.targeting_mode or "no_immediate_repeat",
            chain_target_provider = provider_result and provider_result.provider or nil,
            chain_side_continuation_kind = side_kind,
            chain_side_continuation_id = binding.chain_side_continuation_id,
            chain_side_payload_count = binding.chain_side_payload_count,
            branch_scope = branch_scope,
            branch_kind = binding.has_pattern_payload and "chain_pattern" or binding.has_multicast_payload and "chain_multicast" or "chain",
            branch_count = binding.chain_multicast_fanout_count or 1,
            chain_continuation_group_id = string.format("%s:h%s:%s", tostring(binding.chain_id), tostring(next_hop), tostring(branch_scope)),
            current_hit_target_id = objectToken(current_target),
            selected_target_id = selected.id,
            previous_projectile_id = route.projectile_id,
        },
    }
    copyBounceContinuationScope(route, job_input)
    copyBounceContinuationScope(route, job_input.payload)
    copyPierceContinuationScope(route, job_input)
    copyPierceContinuationScope(route, job_input.payload)

    local modifier_kind = binding.payload_modifier_kind
    local applied_modifiers = launch_modifier_policy.copyMutationSetFields(job_input, {
        payload_modifier_kind = modifier_kind,
        speed_plus = binding.speed_plus_mutation,
        size_plus = binding.size_plus_mutation,
    })
    launch_modifier_policy.copyMutationSetFields(job_input.payload, {
        payload_modifier_kind = modifier_kind,
        speed_plus = binding.speed_plus_mutation,
        size_plus = binding.size_plus_mutation,
    })
    if applied_modifiers.speed_plus == true then
        runtime_stats.inc("chain_modifier_speed_jobs")
        runtime_stats.inc("chain_modifier_speed_mutated")
        log.info(string.format(
            "SPELLFORGE_CHAIN_SPEED_PLUS_APPLIED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s max_hops=%s payload_modifier_kind=%s source_slot_id=%s payload_slot_id=%s selected_target_id=%s speed_value=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(next_hop),
            tostring(binding.max_hops),
            tostring(modifier_kind),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(selected.id),
            tostring(binding.speed_plus_mutation and binding.speed_plus_mutation.speed_plus_speed or nil)
        ))
    end
    if applied_modifiers.size_plus == true then
        runtime_stats.inc("chain_modifier_size_jobs")
        runtime_stats.inc("chain_modifier_size_mutated")
        log.info(string.format(
            "SPELLFORGE_CHAIN_SIZE_PLUS_APPLIED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s max_hops=%s payload_modifier_kind=%s source_slot_id=%s payload_slot_id=%s selected_target_id=%s size_area=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(next_hop),
            tostring(binding.max_hops),
            tostring(modifier_kind),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(selected.id),
            tostring(binding.size_plus_mutation and binding.size_plus_mutation.size_plus_area or nil)
        ))
    end

    local fanout_count = math.max(1, tonumber(binding.chain_multicast_fanout_count) or 1)
    local continuation_group_id = job_input.chain_continuation_group_id
    local branch_parent_id = continuation_group_id
    local launch_density_group_key = string.format(
        "chainfanout:%s:%s:%s",
        tostring(binding.chain_id),
        tostring(next_hop),
        tostring(branch_scope)
    )
    local job_ids = {}
    local real_job_ids = {}
    local jobs = {}
    local projectile_ids = {}
    local tick_results = {}
    local chain_timer_side_schedules = {}
    local probe_virtual_jobs = {}
    local probe_virtual_fanout_after = tonumber(options.probe_virtual_fanout_after)
    local virtualized_count = 0
    local virtualized_first_branch_index = nil
    local virtualized_last_branch_index = nil
    local virtualized_sample_job_id = nil
    if probe_virtual_fanout_after ~= nil then
        probe_virtual_fanout_after = math.max(1, math.floor(probe_virtual_fanout_after))
    end
    if fanout_count <= 1 then
        probe_virtual_fanout_after = nil
    end

    local ir_runtime = buildIrChainRuntimePlan(
        binding,
        route,
        options,
        previous_hop,
        next_hop,
        fanout_count,
        continuation_group_id,
        branch_scope
    )
    if ir_runtime and ir_runtime.ok ~= true then
        ir_runtime = nil
    end
    local ir_runtime_used = false

    if fanout_count > 1 then
        runtime_stats.inc("chain_multicast_hops")
        runtime_stats.inc("branch_observability_chain_multicast_branches")
        runtime_stats.max("branch_observability_max_branch_fanout", fanout_count)
        log.info(string.format(
            "SPELLFORGE_CHAIN_MULTICAST_HOP_QUALIFIED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s max_hops=%s fanout_count=%s selected_target_id=%s continuation_group_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(next_hop),
            tostring(binding.max_hops),
            tostring(fanout_count),
            tostring(selected.id),
            tostring(continuation_group_id)
        ))
        if binding.has_pattern_payload == true then
            runtime_stats.inc("chain_pattern_hops")
            log.info(string.format(
                "SPELLFORGE_CHAIN_PATTERN_HOP_ENQUEUED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s hop_index=%s max_hops=%s pattern_kind=%s fanout_count=%s selected_target_id=%s continuation_group_id=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(next_hop),
                tostring(binding.max_hops),
                tostring(binding.chain_pattern_kind),
                tostring(fanout_count),
                tostring(selected.id),
                tostring(continuation_group_id)
            ))
        end
    end

    for fanout_index = 1, fanout_count do
        local job_to_enqueue = fanout_index == 1 and job_input or cloneJobInput(job_input)
        local planned_job = ir_runtime
            and ir_runtime.job_plan
            and ir_runtime.job_plan.planned_jobs
            and ir_runtime.job_plan.planned_jobs[fanout_index]
            or nil
        if planned_job then
            job_to_enqueue = mergeIrChainPlannedJob(planned_job, job_to_enqueue)
            ir_runtime_used = true
        end
        local branch_id = fanout_count > 1
            and string.format("%s:f%s", tostring(branch_parent_id), tostring(fanout_index))
            or branch_parent_id
        job_to_enqueue.idempotency_key = fanout_count > 1
            and string.format("%s:f%s", tostring(idempotency_key), tostring(fanout_index))
            or idempotency_key
        job_to_enqueue.fanout_count = fanout_count
        job_to_enqueue.branch_id = branch_id
        job_to_enqueue.branch_parent_id = branch_parent_id
        job_to_enqueue.branch_kind = binding.has_pattern_payload and "chain_pattern" or fanout_count > 1 and "chain_multicast" or "chain"
        job_to_enqueue.branch_index = fanout_index
        job_to_enqueue.branch_count = fanout_count
        job_to_enqueue.chain_continuation_group_id = continuation_group_id
        job_to_enqueue.launch_density_group_key = launch_density_group_key
        if binding.has_pattern_payload == true then
            job_to_enqueue.pattern_kind = job_to_enqueue.pattern_kind or binding.chain_pattern_kind
            job_to_enqueue.pattern_index = job_to_enqueue.pattern_index or fanout_index
            job_to_enqueue.pattern_count = job_to_enqueue.pattern_count or fanout_count
            job_to_enqueue.pattern_direction_key = job_to_enqueue.pattern_direction_key
                or string.format("dry:%s:%s", tostring(binding.chain_pattern_kind), tostring(fanout_index))
        end
        if job_to_enqueue.payload then
            job_to_enqueue.payload.fanout_count = fanout_count
            job_to_enqueue.payload.branch_id = branch_id
            job_to_enqueue.payload.branch_parent_id = branch_parent_id
            job_to_enqueue.payload.branch_kind = job_to_enqueue.branch_kind
            job_to_enqueue.payload.branch_index = fanout_index
            job_to_enqueue.payload.branch_count = fanout_count
            job_to_enqueue.payload.chain_continuation_group_id = continuation_group_id
            if binding.has_pattern_payload == true then
                job_to_enqueue.payload.pattern_kind = job_to_enqueue.payload.pattern_kind or job_to_enqueue.pattern_kind
                job_to_enqueue.payload.pattern_index = job_to_enqueue.payload.pattern_index or job_to_enqueue.pattern_index
                job_to_enqueue.payload.pattern_count = job_to_enqueue.payload.pattern_count or job_to_enqueue.pattern_count
                job_to_enqueue.payload.pattern_direction_key = job_to_enqueue.payload.pattern_direction_key or job_to_enqueue.pattern_direction_key
            end
        end

        local probe_virtual = probe_virtual_fanout_after ~= nil and fanout_index > probe_virtual_fanout_after
        local enqueued_job_id = nil
        if probe_virtual then
            enqueued_job_id = string.format(
                "probe_virtual_chain:%s:%s:%s:%s",
                tostring(binding.chain_id),
                tostring(next_hop),
                tostring(branch_scope),
                tostring(fanout_index)
            )
            probe_virtual_jobs[enqueued_job_id] = makeProbeVirtualPayloadJob(
                job_to_enqueue,
                enqueued_job_id,
                "probe_virtual:" .. enqueued_job_id
            )
            runtime_stats.inc("chain_runtime_probe_virtual_payload_jobs")
            virtualized_count = virtualized_count + 1
            virtualized_first_branch_index = virtualized_first_branch_index or fanout_index
            virtualized_last_branch_index = fanout_index
            virtualized_sample_job_id = virtualized_sample_job_id or enqueued_job_id
        else
            local enqueue = orchestrator.enqueue(job_to_enqueue)
            if not enqueue.ok then
                runtime_stats.inc("chain_runtime_hop_rejected")
                runtime_stats.inc("chain_runtime_context_reject")
                if fanout_count > 1 then
                    runtime_stats.inc("chain_multicast_payload_failed")
                end
                return { ok = false, error = enqueue.error or "Chain payload enqueue failed" }
            end
            enqueued_job_id = enqueue.job_id
            real_job_ids[#real_job_ids + 1] = enqueue.job_id
            runtime_stats.inc("chain_runtime_sfp_launch_attempts")
            log.info(string.format(
                "SPELLFORGE_CHAIN_HOP_ENQUEUED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s branch_id=%s branch_index=%s branch_count=%s source_slot_id=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s job_id=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(branch_id),
                tostring(fanout_index),
                tostring(fanout_count),
                tostring(binding.source_slot_id),
                tostring(binding.payload_slot_id),
                tostring(next_hop),
                tostring(binding.max_hops),
                tostring(selected.id),
                tostring(enqueued_job_id)
            ))
            if binding.has_pattern_payload == true then
                log.info(string.format(
                    "SPELLFORGE_CHAIN_PATTERN_PAYLOAD_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s branch_id=%s branch_index=%s branch_count=%s pattern_kind=%s payload_slot_id=%s hop_index=%s selected_target_id=%s job_id=%s",
                    tostring(binding.recipe_id),
                    tostring(binding.cast_id),
                    tostring(binding.chain_id),
                    tostring(branch_scope),
                    tostring(branch_id),
                    tostring(fanout_index),
                    tostring(fanout_count),
                    tostring(binding.chain_pattern_kind),
                    tostring(binding.payload_slot_id),
                    tostring(next_hop),
                    tostring(selected.id),
                    tostring(enqueued_job_id)
                ))
            end
        end

        job_ids[#job_ids + 1] = enqueued_job_id
        runtime_stats.inc("chain_runtime_payload_jobs")
        if fanout_count > 1 then
            runtime_stats.inc("chain_multicast_jobs")
            runtime_stats.inc("branch_observability_events")
        end
        if modifier_kind ~= nil then
            log.info(string.format(
                "SPELLFORGE_CHAIN_MODIFIED_HOP_ENQUEUED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s source_slot_id=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s payload_modifier_kind=%s job_id=%s",
                tostring(binding.recipe_id),
                tostring(binding.cast_id),
                tostring(binding.chain_id),
                tostring(branch_scope),
                tostring(binding.source_slot_id),
                tostring(binding.payload_slot_id),
                tostring(next_hop),
                tostring(binding.max_hops),
                tostring(selected.id),
                tostring(modifier_kind),
                tostring(enqueued_job_id)
            ))
        end
    end
    if ir_runtime_used then
        runtime_stats.inc("ir_chain_runtime_enqueued")
        runtime_stats.inc("ir_chain_runtime_jobs_planned", #job_ids)
        runtime_stats.inc("ir_chain_runtime_jobs_enqueued", #real_job_ids)
        log.info(string.format(
            "SPELLFORGE_IR_CHAIN_RUNTIME_ENQUEUED recipe_id=%s cast_id=%s chain_id=%s source_slot_id=%s payload_count=%s hop_index=%s first_job_id=%s branch_kind=%s virtual_job_count=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(binding.source_slot_id),
            tostring(#job_ids),
            tostring(next_hop),
            tostring(job_ids[1]),
            tostring(fanout_count > 1 and "chain_multicast" or "chain"),
            tostring(#job_ids - #real_job_ids)
        ))
    end
    if virtualized_count > 0 then
        log.info(string.format(
            "SPELLFORGE_CHAIN_HOP_PROBE_VIRTUALIZED recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s branch_count=%s virtual_branch_count=%s first_virtual_branch_index=%s last_virtual_branch_index=%s source_slot_id=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s sample_job_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(fanout_count),
            tostring(virtualized_count),
            tostring(virtualized_first_branch_index),
            tostring(virtualized_last_branch_index),
            tostring(binding.source_slot_id),
            tostring(binding.payload_slot_id),
            tostring(next_hop),
            tostring(binding.max_hops),
            tostring(selected.id),
            tostring(virtualized_sample_job_id)
        ))
    end
    runtime_stats.inc("chain_runtime_hops_launched")

    local failed_job = nil
    local tick_result = nil
    tick_result, tick_results = tickJobs(real_job_ids, {
        max_chain_ticks = options.max_chain_ticks,
        max_jobs_per_tick = options.max_jobs_per_tick or binding.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick or binding.max_live_launches_per_tick,
        simulate_update_ticks = options.simulate_update_ticks == true,
        simulated_dt_seconds = options.simulated_dt_seconds,
    })

    local virtual_ok_count = 0
    local virtual_ok_first_branch_index = nil
    local virtual_ok_last_branch_index = nil
    local virtual_ok_sample_projectile_id = nil
    for _, job_id in ipairs(job_ids) do
        local job = probe_virtual_jobs[job_id] or compactJob(job_id)
        jobs[#jobs + 1] = job
        runtime_stats.inc("chain_runtime_payload_processed")
        if job.job_status == "complete" and job.launch_accepted == true then
            runtime_stats.inc("chain_runtime_payload_ok")
            if job.probe_virtual == true then
                runtime_stats.inc("chain_runtime_probe_virtual_payload_ok")
                virtual_ok_count = virtual_ok_count + 1
                virtual_ok_first_branch_index = virtual_ok_first_branch_index or job.branch_index
                virtual_ok_last_branch_index = job.branch_index
                virtual_ok_sample_projectile_id = virtual_ok_sample_projectile_id or job.projectile_id
            else
                runtime_stats.inc("chain_runtime_sfp_launch_ok")
                log.info(string.format(
                    "SPELLFORGE_CHAIN_HOP_PAYLOAD_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s branch_id=%s branch_index=%s branch_count=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s projectile_id=%s",
                    tostring(binding.recipe_id),
                    tostring(binding.cast_id),
                    tostring(binding.chain_id),
                    tostring(branch_scope),
                    tostring(job.branch_id),
                    tostring(job.branch_index),
                    tostring(job.branch_count),
                    tostring(binding.payload_slot_id),
                    tostring(next_hop),
                    tostring(binding.max_hops),
                    tostring(selected.id),
                    tostring(job.projectile_id)
                ))
            end
            if modifier_kind ~= nil then
                runtime_stats.inc("chain_modifier_payload_ok")
            end
            if fanout_count > 1 then
                runtime_stats.inc("chain_multicast_payload_ok")
            end
            if binding.has_pattern_payload == true then
                runtime_stats.inc("chain_pattern_payload_ok")
            end
            if job.projectile_id ~= nil then
                projectile_ids[#projectile_ids + 1] = job.projectile_id
            end
            if side_kind == "Timer" then
                local timer_resolution, timer_resolution_error = live_timer.computeResolution({
                    start_pos = job.launch_start_pos or start_pos,
                    direction = job.launch_direction or direction,
                    hit_object = selected_object,
                }, {
                    timer_seconds = binding.chain_side_timer_seconds,
                })
                if not timer_resolution then
                    failed_job = job
                    job.error = timer_resolution_error or "chain timer side resolution failed"
                    runtime_stats.inc("chain_timer_side_payload_schedule_failed")
                    break
                end
                local timer_binding = {
                    plan = binding.plan,
                    recipe_id = binding.recipe_id,
                    display_recipe_id = binding.display_recipe_id,
                    cast_id = binding.cast_id,
                    source_job_id = job.job_id,
                    source_projectile_id = job.projectile_id,
                    source_user_data = job.launch_user_data,
                    source_slot_id = job.payload_slot_id or binding.payload_slot_id,
                    source_helper_engine_id = job.helper_engine_id or binding.payload_helper_engine_id,
                    source_prefix_opcode = "Chain",
                    source_postfix_opcode = "Timer",
                    payload_slot_id = binding.chain_side_payload_slot_id,
                    payload_helper_engine_id = binding.chain_side_payload_helper_engine_id,
                    payloads = binding.chain_side_payloads,
                    payload_slot_ids = binding.chain_side_payload_slot_ids,
                    payload_helper_engine_ids = binding.chain_side_payload_helper_engine_ids,
                    payload_count = binding.chain_side_payload_count,
                    payload_group_key = binding.chain_side_payload_group_key,
                    payload_multicast = binding.chain_side_payload_multicast == true,
                    payload_pattern = binding.chain_side_payload_pattern == true,
                    payload_pattern_kind = binding.chain_side_payload_pattern_kind,
                    payload_pattern_op = binding.chain_side_payload_pattern_op,
                    max_payload_fanout = binding.chain_side_max_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT,
                    max_projectiles = binding.max_projectiles,
                    max_jobs_per_tick = binding.max_jobs_per_tick,
                    max_live_launches_per_tick = binding.max_live_launches_per_tick,
                    actor = route.attacker or binding.actor,
                    hit_object = selected_object,
                    resolution = timer_resolution,
                    timer_seconds = binding.chain_side_timer_seconds,
                    timer_delay_ticks = binding.chain_side_timer_delay_ticks,
                    root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id,
                    current_source_slot_id = job.payload_slot_id or binding.payload_slot_id,
                    parent_slot_id = binding.source_slot_id,
                    source_depth = 1,
                    chain_runtime = true,
                    chain_role = "payload",
                    chain_id = binding.chain_id,
                    chain_hop_index = next_hop,
                    chain_max_hops = binding.max_hops,
                    chain_continuation_group_id = continuation_group_id,
                    branch_scope = branch_scope,
                    branch_id = job.branch_id,
                    branch_parent_id = job.branch_parent_id,
                    branch_kind = job.branch_kind,
                    branch_index = job.branch_index,
                    branch_count = job.branch_count,
                }
                local schedule = live_timer.schedulePayload(timer_binding, {
                    source_projectile_id = job.projectile_id,
                    source_user_data = job.launch_user_data,
                    duplicate_key_suffix = string.format(
                        "chain_side:%s:%s:%s:%s",
                        tostring(binding.chain_id),
                        tostring(next_hop),
                        tostring(job.branch_id),
                        tostring(job.projectile_id or job.job_id)
                    ),
                })
                if not schedule or schedule.ok ~= true then
                    failed_job = job
                    job.error = schedule and schedule.error or "chain timer side schedule failed"
                    runtime_stats.inc("chain_timer_side_payload_schedule_failed")
                    break
                end
                chain_timer_side_schedules[#chain_timer_side_schedules + 1] = schedule
            end
            if modifier_kind ~= nil then
                log.info(string.format(
                    "SPELLFORGE_CHAIN_MODIFIED_PAYLOAD_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s payload_modifier_kind=%s projectile_id=%s",
                    tostring(binding.recipe_id),
                    tostring(binding.cast_id),
                    tostring(binding.chain_id),
                    tostring(branch_scope),
                    tostring(binding.payload_slot_id),
                    tostring(next_hop),
                    tostring(binding.max_hops),
                    tostring(selected.id),
                    tostring(modifier_kind),
                    tostring(job.projectile_id)
                ))
            end
        else
            failed_job = job
            runtime_stats.inc("chain_runtime_payload_failed")
            runtime_stats.inc("chain_runtime_sfp_launch_failed")
            if modifier_kind ~= nil then
                runtime_stats.inc("chain_modifier_payload_failed")
            end
            if fanout_count > 1 then
                runtime_stats.inc("chain_multicast_payload_failed")
            end
        end
    end
    if virtual_ok_count > 0 then
        log.info(string.format(
            "SPELLFORGE_CHAIN_HOP_PAYLOAD_VIRTUAL_OK recipe_id=%s cast_id=%s chain_id=%s branch_scope=%s branch_count=%s virtual_payload_count=%s first_virtual_branch_index=%s last_virtual_branch_index=%s payload_slot_id=%s hop_index=%s max_hops=%s selected_target_id=%s sample_projectile_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.chain_id),
            tostring(branch_scope),
            tostring(fanout_count),
            tostring(virtual_ok_count),
            tostring(virtual_ok_first_branch_index),
            tostring(virtual_ok_last_branch_index),
            tostring(binding.payload_slot_id),
            tostring(next_hop),
            tostring(binding.max_hops),
            tostring(selected.id),
            tostring(virtual_ok_sample_projectile_id)
        ))
    end

    if failed_job then
        return {
            ok = false,
            error = failed_job.error or "Chain payload launch failed",
            chain_id = binding.chain_id,
            chain_hop_index = next_hop,
            max_hops = binding.max_hops,
            branch_scope = branch_scope,
            job_id = failed_job.job_id,
            job = failed_job,
            jobs = jobs,
            job_ids = job_ids,
            tick_result = tick_result,
            tick_results = tick_results,
            resolved = resolved,
        }
    end

    runtime_stats.inc("chain_runtime_hops_completed")

    return {
        ok = true,
        mode = "chain_runtime",
        chain_runtime = true,
        chain_id = binding.chain_id,
        cast_id = binding.cast_id,
        chain_shape = binding.chain_shape,
        chain_hop_index = next_hop,
        previous_hop_index = previous_hop,
        max_hops = binding.max_hops,
        branch_scope = branch_scope,
        targeting_mode = binding.targeting_mode or "no_immediate_repeat",
        current_hit_target_id = objectToken(current_target),
        selected_target_id = selected.id,
        selected_targets = resolved.selected_targets,
        selected_count = resolved.selected_count,
        candidate_count = resolved.candidate_count,
        valid_candidate_count = resolved.valid_candidate_count,
        payload_modifier_kind = modifier_kind,
        speed_plus_mutation = binding.speed_plus_mutation,
        size_plus_mutation = binding.size_plus_mutation,
        provider = provider_result and provider_result.provider or nil,
        provider_result = provider_result,
        excluded_current_target_id = resolved.excluded_current_target_id,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        launch_count = #jobs,
        payload_job = jobs[1],
        payload_slot_id = binding.payload_slot_id,
        payload_helper_engine_id = binding.payload_helper_engine_id,
        has_multicast_payload = fanout_count > 1,
        chain_multicast_fanout_count = fanout_count,
        projectile_id = jobs[1] and jobs[1].projectile_id or nil,
        projectile_ids = projectile_ids,
        launch_user_data = jobs[1] and jobs[1].launch_user_data or nil,
        resolved = resolved,
        tick_result = tick_result,
        tick_results = tick_results,
        ir_chain_runtime = ir_runtime_used == true,
        ir_chain_runtime_job_count = ir_runtime_used and #job_ids or 0,
        ir_chain_runtime_real_job_count = ir_runtime_used and #real_job_ids or 0,
        chain_side_continuation_kind = side_kind,
        chain_side_payload_count = binding.chain_side_payload_count,
        chain_timer_side_schedule_count = #chain_timer_side_schedules,
        chain_timer_side_schedules = chain_timer_side_schedules,
    }
end

function live_chain.handleHitPayload(payload, opts)
    local route = runtime_hits.resolveHelperHit(payload or {})
    return live_chain.handleResolvedHit(route, opts)
end

function live_chain.onLosResult(payload)
    local request_id = payload and payload.request_id
    return completeLosRequest(request_id, payload or {})
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

function live_chain.summary()
    return {
        bindings = countMap(bindings_by_cast_source),
        chain_bindings = countMap(bindings_by_chain_id),
        duplicate_keys = countMap(duplicate_keys),
        continuation_claims = countMap(continuation_claims),
        pending_los = countMap(pending_los),
        runtime_generation = runtime_session.currentGeneration(),
    }
end

function live_chain.clearTransient(reason)
    local before = live_chain.summary()
    for _, request_id in ipairs(pending_los_order or {}) do
        clearPendingLos(request_id)
    end
    bindings_by_cast_source = {}
    bindings_by_chain_id = {}
    binding_order = {}
    duplicate_keys = {}
    duplicate_order = {}
    continuation_claims = {}
    continuation_claim_order = {}
    pending_los = {}
    pending_los_order = {}
    next_los_request_index = 0
    log.info(string.format(
        "SPELLFORGE_LIVE_CHAIN_CLEARED reason=%s chain_entries=%s duplicate_keys=%s continuation_claims=%s pending_los=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.bindings),
        tostring(before.duplicate_keys),
        tostring(before.continuation_claims),
        tostring(before.pending_los),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function live_chain.clearForTests()
    return live_chain.clearTransient("tests")
end

return live_chain
