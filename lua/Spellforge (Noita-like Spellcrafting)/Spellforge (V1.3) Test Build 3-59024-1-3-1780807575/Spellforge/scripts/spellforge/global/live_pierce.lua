---@omw-context global
local core = require("openmw.core")
local limits = require("scripts.spellforge.shared.limits")
local dev = require("scripts.spellforge.shared.dev")
local helper_records = require("scripts.spellforge.global.helper_records")
local ir_runtime_adapter = require("scripts.spellforge.global.ir_runtime_adapter")
local live_chain = require("scripts.spellforge.global.live_chain")
local log = require("scripts.spellforge.shared.log").new("global.live_pierce")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")

local live_pierce = {}

local bindings_by_key = {}
local bindings_by_helper = {}
local duplicate_keys = {}

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
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
    return countOpcode(ops, opcode) > 0
end

local function sourceModifierPolicyAccepts(options, entry)
    if type(entry and entry.prefix_ops) ~= "table" or #(entry.prefix_ops or {}) <= 1 then
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

local function clampPierceCount(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = 2
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    elseif n > limits.MAX_PIERCE_COUNT_HARD then
        n = limits.MAX_PIERCE_COUNT_HARD
    end
    return n
end

local function helperBySlotId(helpers)
    local out = {}
    for _, helper in ipairs(helpers or {}) do
        if helper and helper.slot_id then
            out[helper.slot_id] = helper
        end
    end
    return out
end

local function rejectSelect(reason, counter)
    if counter then
        runtime_stats.inc(counter)
    end
    runtime_stats.inc("live_pierce_rejected")
    return nil, reason
end

local function postfixIsEmptyOrTrigger(entry)
    local ops = entry and entry.postfix_ops or {}
    return #ops == 0 or (#ops == 1 and ops[1] and ops[1].opcode == "Trigger")
end

local function payloadsFromContinuationPlan(plan, continuation_plan)
    local payloads = {}
    local ids = continuation_plan and continuation_plan.payload_slot_ids or {}
    local helpers_by_slot = helperBySlotId(plan.helper_records or {})
    for _, slot_id in ipairs(ids) do
        local helper = helpers_by_slot[slot_id] or helper_records.getByRecipeSlot(plan.recipe_id, slot_id)
        if not helper then
            return nil, "payload_helper_missing"
        end
        payloads[#payloads + 1] = {
            slot_id = slot_id,
            helper_engine_id = helper.engine_id,
            helper = helper,
            emission_index = helper.emission_index,
            group_index = helper.group_index,
            prefix_ops = helper.prefix_ops,
            postfix_ops = helper.postfix_ops,
            parent_slot_id = helper.parent_slot_id,
            source_postfix_opcode = helper.source_postfix_opcode,
        }
    end
    return payloads, nil
end

local function compactPayloadIds(payloads)
    local slot_ids = {}
    local helper_ids = {}
    for i, payload in ipairs(payloads or {}) do
        slot_ids[i] = payload.slot_id
        helper_ids[i] = payload.helper_engine_id
    end
    return slot_ids, helper_ids
end

function live_pierce.selectV0Plan(plan, opts)
    local options = opts or {}
    if type(plan) ~= "table" then
        return rejectSelect("missing_plan")
    end

    local bounds = plan.bounds or {}
    if bounds.has_bounce then
        return rejectSelect("pierce_bounce_deferred", "live_pierce_deferred_reject")
    end
    if bounds.has_homing then
        return rejectSelect("homing_pierce_physics_unsupported", "live_pierce_deferred_reject")
    end
    if bounds.has_multicast or bounds.has_pattern then
        return rejectSelect("pierce_fanout_deferred", "live_pierce_deferred_reject")
    end
    if bounds.has_chain then
        local has_trigger_chain = false
        for _, slot in ipairs(plan.emission_slots or {}) do
            if slot.parent_slot_id ~= nil and slot.source_postfix_opcode == "Trigger" and hasOpcode(slot.prefix_ops, "Chain") then
                has_trigger_chain = true
                break
            end
        end
        if not has_trigger_chain then
            return rejectSelect("pierce_chain_deferred", "live_pierce_deferred_reject")
        end
    end
    if bounds.group_count ~= 1 or tonumber(bounds.static_emission_count) ~= 1 then
        return rejectSelect("not_single_pierce_source")
    end

    local group = plan.groups and plan.groups[1] or nil
    if type(group) ~= "table" then
        return rejectSelect("missing_group")
    end
    local pierce_count, pierce_op = countOpcode(group.prefix_ops, "Pierce")
    if pierce_count ~= 1 then
        return rejectSelect("missing_pierce_op")
    end
    local group_prefix_ok, group_prefix_reason = sourceModifierPolicyAccepts(options, group)
    if not group_prefix_ok then
        return rejectSelect(group_prefix_reason or "source_modifier_unsupported_prefix", "live_pierce_deferred_reject")
    end
    if not postfixIsEmptyOrTrigger(group) then
        return rejectSelect("pierce_nested_payload_deferred", "live_pierce_deferred_reject")
    end

    local source_slot = nil
    for _, slot in ipairs(plan.emission_slots or {}) do
        if slot.kind == "primary_emission" then
            if source_slot then
                return rejectSelect("multiple_pierce_sources")
            end
            source_slot = slot
        end
    end
    if not source_slot then
        return rejectSelect("missing_pierce_source_slot")
    end
    local slot_prefix_ok, slot_prefix_reason = sourceModifierPolicyAccepts(options, source_slot)
    if not postfixIsEmptyOrTrigger(source_slot)
        or countOpcode(source_slot.prefix_ops, "Pierce") ~= 1
        or not slot_prefix_ok then
        if slot_prefix_ok == false then
            return rejectSelect(slot_prefix_reason or "source_modifier_unsupported_prefix", "live_pierce_deferred_reject")
        end
        return rejectSelect("source_slot_not_pierce")
    end

    local helpers_by_slot = helperBySlotId(plan.helper_records or {})
    local source_helper = helpers_by_slot[source_slot.slot_id]
    if not source_helper or type(source_helper.engine_id) ~= "string" or source_helper.engine_id == "" then
        return rejectSelect("source_helper_missing")
    end

    local pierce_limit = clampPierceCount(pierce_op and pierce_op.params and pierce_op.params.pierces)
    local effective_cap = tonumber(options.max_pierce_count) or limits.MAX_PIERCE_COUNT
    if pierce_limit > effective_cap then
        runtime_stats.inc("live_pierce_cap_reject")
        return rejectSelect("pierce_count_cap_exceeded")
    end

    local event = {
        event_kind = "pierce",
        source_slot_id = source_slot.slot_id,
        source_prefix_opcode = "Pierce",
        source_postfix_opcode = source_slot.postfix_ops and source_slot.postfix_ops[1] and source_slot.postfix_ops[1].opcode or nil,
    }
    local planned = ir_runtime_adapter.planEvent({ runtime_ir = plan.runtime_ir }, plan, event, {
        allow_payload_multicast = options.allow_payload_multicast == true,
        allow_payload_pattern = options.allow_payload_pattern == true,
        allow_chain_multicast = options.allow_chain_multicast == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = options.speed_plus_enabled == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = options.size_plus_enabled == true,
        max_pierce_count = effective_cap,
        max_fanout = options.max_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs = options.max_jobs,
        max_hops = options.max_hops,
        max_chain_multicast_fanout = options.max_chain_multicast_fanout,
    })
    if planned.ok ~= true then
        local reason = planned.rejection_reason or "pierce_ir_plan_failed"
        if reason == "nested_payload_runtime_deferred" then
            reason = "pierce_nested_payload_deferred"
        elseif reason == "bounce_prefix_combo_deferred" then
            reason = "pierce_bounce_deferred"
        end
        return rejectSelect(reason, "live_pierce_deferred_reject")
    end

    local payloads, payload_reason = payloadsFromContinuationPlan(plan, planned.continuation_plan)
    if payload_reason then
        return rejectSelect(payload_reason)
    end
    local payload_slot_ids, payload_helper_engine_ids = compactPayloadIds(payloads)
    local has_trigger_payload = #(payloads or {}) > 0
    local first_payload = payloads and payloads[1] or nil

    runtime_stats.inc("live_pierce_qualified")
    return {
        ok = true,
        source = {
            slot = source_slot,
            helper = source_helper,
        },
        source_slot_id = source_slot.slot_id,
        source_helper_engine_id = source_helper.engine_id,
        pierce_op = pierce_op,
        pierce_limit = pierce_limit,
        has_trigger_payload = has_trigger_payload,
        has_chain_payload = planned.continuation_plan.has_chain_payload == true,
        chain_shape = planned.continuation_plan.chain_shape,
        chain_requested_hops = planned.continuation_plan.requested_hops,
        chain_max_hops = planned.continuation_plan.max_hops,
        payload_slot_id = first_payload and first_payload.slot_id or nil,
        payload_helper_engine_id = first_payload and first_payload.helper_engine_id or nil,
        payloads = payloads,
        payload_slot_ids = payload_slot_ids,
        payload_helper_engine_ids = payload_helper_engine_ids,
        payload_count = #(payloads or {}),
        payload_multicast = planned.continuation_plan.payload_multicast == true,
        payload_pattern = planned.continuation_plan.payload_pattern == true,
        payload_pattern_kind = planned.continuation_plan.payload_pattern_kind,
        max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK,
        max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK,
        chaos_budget_profile = options.chaos_budget_profile,
        continuation_plan = planned.continuation_plan,
        runtime_job_plan = planned.job_plan,
    }, nil
end

local function bindingKey(recipe_id, cast_id, source_slot_id, helper_engine_id)
    return table.concat({
        tostring(recipe_id),
        tostring(cast_id),
        tostring(source_slot_id),
        tostring(helper_engine_id),
    }, "::")
end

function live_pierce.decorateSourceJob(job, binding)
    if type(job) ~= "table" or type(binding) ~= "table" then
        return job
    end
    local branch_scope = binding.branch_scope or binding.pierce_id
    local branch_parent_id = binding.branch_parent_id
        or string.format("root:%s:%s", tostring(binding.cast_id or "no-cast"), tostring(binding.source_slot_id or "no-source"))
    local branch_id = binding.branch_id or string.format("%s:pierce_source:%s", tostring(branch_parent_id), tostring(binding.source_slot_id))
    local payload = job.payload or {}
    job.payload = payload
    job.piercing = true
    job.pierceLimit = binding.pierce_limit
    job.pierce_runtime = true
    job.pierce_role = "source"
    job.pierce_id = binding.pierce_id
    job.pierce_limit = binding.pierce_limit
    job.source_prefix_opcode = "Pierce"
    job.source_postfix_opcode = binding.has_trigger_payload and "Trigger" or nil
    job.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    job.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    job.trigger_source_slot_id = binding.has_trigger_payload and binding.source_slot_id or nil
    job.trigger_payload_slot_id = binding.has_trigger_payload and binding.payload_slot_id or nil
    job.trigger_payload_slot_ids = binding.payload_slot_ids
    job.has_trigger_payload = binding.has_trigger_payload == true
    job.has_chain_payload = binding.has_chain_payload == true
    job.payload_multicast = binding.payload_multicast == true
    job.payload_pattern = binding.payload_pattern == true
    job.payload_pattern_kind = binding.payload_pattern_kind
    job.branch_scope = branch_scope
    job.branch_id = branch_id
    job.branch_parent_id = branch_parent_id
    job.branch_kind = binding.branch_kind or "pierce_source"
    job.branch_index = binding.branch_index or 1
    job.branch_count = binding.branch_count or 1
    payload.pierce_runtime = true
    payload.pierce_role = "source"
    payload.pierce_id = binding.pierce_id
    payload.pierce_limit = binding.pierce_limit
    payload.piercing = true
    payload.pierceLimit = binding.pierce_limit
    payload.source_slot_id = binding.source_slot_id
    payload.source_helper_engine_id = binding.source_helper_engine_id
    payload.source_prefix_opcode = "Pierce"
    payload.source_postfix_opcode = binding.has_trigger_payload and "Trigger" or nil
    payload.trigger_source_slot_id = binding.has_trigger_payload and binding.source_slot_id or nil
    payload.trigger_payload_slot_id = binding.has_trigger_payload and binding.payload_slot_id or nil
    payload.trigger_payload_slot_ids = binding.payload_slot_ids
    payload.has_trigger_payload = binding.has_trigger_payload == true
    payload.has_chain_payload = binding.has_chain_payload == true
    payload.payload_multicast = binding.payload_multicast == true
    payload.payload_pattern = binding.payload_pattern == true
    payload.payload_pattern_kind = binding.payload_pattern_kind
    payload.pierce_trigger_payload_slot_id = binding.has_trigger_payload and binding.payload_slot_id or nil
    payload.root_source_slot_id = binding.root_source_slot_id or binding.source_slot_id
    payload.current_source_slot_id = binding.current_source_slot_id or binding.source_slot_id
    payload.branch_scope = branch_scope
    payload.branch_id = branch_id
    payload.branch_parent_id = branch_parent_id
    payload.branch_kind = binding.branch_kind or "pierce_source"
    payload.branch_index = binding.branch_index or 1
    payload.branch_count = binding.branch_count or 1
    return job
end

function live_pierce.registerBinding(binding)
    if type(binding) ~= "table" then
        return false
    end
    local key = bindingKey(binding.recipe_id, binding.cast_id, binding.source_slot_id, binding.source_helper_engine_id)
    binding.binding_key = key
    binding.runtime_generation = runtime_session.currentGeneration()
    bindings_by_key[key] = binding
    bindings_by_helper[tostring(binding.source_helper_engine_id)] = binding
    runtime_stats.inc("live_pierce_source_jobs")
    return true
end

local function compactVector(value)
    if type(value) ~= "table" then
        return nil
    end
    return {
        x = tonumber(value.x) or tonumber(value[1]) or 0,
        y = tonumber(value.y) or tonumber(value[2]) or 0,
        z = tonumber(value.z) or tonumber(value[3]) or 0,
    }
end

local function normalizeVector(value)
    local v = compactVector(value)
    if not v then
        return nil
    end
    local len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    if len <= 0.0001 then
        return nil
    end
    return { x = v.x / len, y = v.y / len, z = v.z / len }
end

local function addScaled(pos, dir, scale)
    local p = compactVector(pos)
    local d = normalizeVector(dir)
    if not p or not d then
        return p
    end
    return {
        x = p.x + d.x * scale,
        y = p.y + d.y * scale,
        z = p.z + d.z * scale,
    }
end

local function objectToken(obj)
    if obj == nil then
        return nil
    end
    if type(obj) ~= "table" then
        return tostring(obj)
    end
    return tostring(obj.id or obj.recordId or obj.record_id or obj.objectId or obj.object_id or obj)
end

local function bindingForRoute(route)
    local user_data = route and route.user_data or {}
    local key = bindingKey(
        route.recipe_id or user_data.recipe_id,
        route.cast_id or user_data.cast_id,
        route.source_slot_id or user_data.source_slot_id or user_data.slot_id,
        route.helper_engine_id or user_data.source_helper_engine_id or user_data.helper_engine_id
    )
    return bindings_by_key[key] or bindings_by_helper[tostring(route and route.helper_engine_id)]
end

local function routeFromPiercePayload(payload)
    local data = type(payload) == "table" and payload or {}
    local user_data = sfp_userdata.extract(data)
    if not sfp_userdata.isSpellforgeUserData(user_data) or type(user_data) ~= "table" then
        return { ok = false, error = "sfp_pierce_userdata_missing" }
    end
    local projectile, projectile_id = sfp_adapter.extractProjectileFromHit(data)
    if projectile_id == nil then
        return { ok = false, error = "sfp_pierce_projectile_id_missing", user_data = user_data }
    end
    local helper_engine_id = firstNonNil(data.spellId, data.spell_id, user_data.helper_engine_id, user_data.source_helper_engine_id)
    local actor = firstNonNil(data.hitObject, data.hit_object, data.actor, data.target)
    local actor_id = firstNonNil(data.actorId, data.actor_id, objectToken(actor))
    return {
        ok = true,
        recipe_id = user_data.recipe_id,
        cast_id = user_data.cast_id,
        source_slot_id = firstNonNil(user_data.source_slot_id, user_data.slot_id),
        helper_engine_id = helper_engine_id,
        source_helper_engine_id = firstNonNil(user_data.source_helper_engine_id, helper_engine_id),
        attacker = firstNonNil(data.attacker, user_data.attacker),
        actor = actor,
        actor_id = actor_id,
        current_hit_target = actor,
        current_hit_target_id = actor_id,
        hit_pos = firstNonNil(data.hitPos, data.hit_pos, data.position, data.pos),
        hit_normal = firstNonNil(data.hitNormal, data.hit_normal),
        velocity = data.velocity,
        direction = normalizeVector(data.velocity),
        projectile = projectile,
        projectile_id = projectile_id,
        projectile_id_source = "pierce_event",
        sound_anchor = firstNonNil(data.soundAnchor, data.sound_anchor),
        light_anchor = firstNonNil(data.lightAnchor, data.light_anchor),
        pierce_count = tonumber(firstNonNil(data.pierceCount, data.pierce_count, user_data.pierce_count)) or 1,
        pierce_limit = tonumber(firstNonNil(data.pierceLimit, data.pierce_limit, user_data.pierce_limit)) or nil,
        is_pierce = firstNonNil(data.isPierce, data.is_pierce) == true,
        user_data = user_data,
    }
end

local function duplicateKey(route, binding)
    return table.concat({
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.source_slot_id),
        tostring(binding.source_helper_engine_id),
        tostring(route.projectile_id),
        tostring(route.actor_id),
        tostring(route.pierce_count),
        tostring(binding.payload_group_key or binding.payload_slot_id or "source"),
    }, "::")
end

local function shouldSkipProjectileMutation(route, options)
    if options and options.simulate_update_ticks == true then
        return true
    end
    local projectile_id = route and route.projectile_id
    return type(projectile_id) == "string" and string.sub(projectile_id, 1, 17) == "probe_projectile:"
end

local function stopAtPierceLimit(route, binding, options)
    local limit = tonumber(binding and binding.pierce_limit)
    local count = tonumber(route and route.pierce_count)
    -- Pierce N means N actor pass-through events. SFP should collide normally
    -- on the next actor/geometry hit, so Spellforge only cancels defensively if
    -- an unexpected over-limit Pierce event is observed.
    if limit == nil or count == nil or count <= limit then
        return nil
    end
    if route.projectile_id == nil or shouldSkipProjectileMutation(route, options) then
        return nil
    end

    local result = sfp_adapter.cancelSpell(route.projectile_id)
    local ok = result and result.ok == true
    runtime_stats.inc(ok and "live_pierce_limit_stop_ok" or "live_pierce_limit_stop_failed")
    log.info(string.format(
        "SPELLFORGE_LIVE_PIERCE_LIMIT_STOP recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s projectile_id=%s pierce_count=%s pierce_limit=%s ok=%s error=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.pierce_id),
        tostring(binding.source_slot_id),
        tostring(route.projectile_id),
        tostring(count),
        tostring(limit),
        tostring(ok),
        tostring(result and result.error or nil)
    ))
    return {
        ok = ok,
        error = result and result.error or nil,
        pierce_count = count,
        pierce_limit = limit,
    }
end

local function safeOrigin(route, binding)
    local direction = normalizeVector(route.velocity) or normalizeVector(route.direction) or normalizeVector(binding.direction)
    local origin = nil
    if direction ~= nil then
        origin = addScaled(route.hit_pos, direction, limits.PIERCE_PAYLOAD_EXIT_OFFSET)
    else
        origin = compactVector(route.hit_pos)
    end
    if origin ~= nil and direction ~= nil then
        log.info(string.format(
            "SPELLFORGE_PIERCE_PAYLOAD_ORIGIN_SAFE recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s actor_id=%s offset=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.pierce_id),
            tostring(binding.source_slot_id),
            tostring(route.actor_id),
            tostring(limits.PIERCE_PAYLOAD_EXIT_OFFSET)
        ))
    end
    return origin, direction
end

local function plannerOptions(binding, options)
    return {
        allow_payload_multicast = binding.force_payload_multicast_enabled == true or options.allow_payload_multicast == true,
        allow_payload_pattern = binding.force_payload_pattern_enabled == true or options.allow_payload_pattern == true,
        allow_chain_multicast = options.allow_chain_multicast == true,
        max_pierce_count = limits.MAX_PIERCE_COUNT,
        max_fanout = binding.max_payload_fanout,
        max_projectiles = binding.max_projectiles,
        max_jobs = options.max_jobs or binding.max_jobs,
        max_hops = binding.chain_max_hops,
        max_live_launches_per_tick = binding.max_live_launches_per_tick,
        chaos_budget_profile = binding.chaos_budget_profile,
    }
end

local function routeTriggerPayloads(route, binding, key, options)
    local origin, direction = safeOrigin(route, binding)
    local event = {
        event_kind = "pierce",
        source_slot_id = binding.source_slot_id,
        source_prefix_opcode = "Pierce",
        source_postfix_opcode = "Trigger",
        cast_id = binding.cast_id,
        source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id),
        parent_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id),
        pierce_id = binding.pierce_id,
        pierce_count = route.pierce_count,
        pierce_limit = binding.pierce_limit,
        projectile_id = route.projectile_id,
        actor_id = route.actor_id,
        current_hit_target_id = route.actor_id,
        excludeTarget = route.actor,
        start_pos = origin,
        direction = direction,
        branch_scope = binding.branch_scope or binding.pierce_id,
        branch_parent_id = binding.source_job_id,
    }
    runtime_stats.inc("ir_pierce_runtime_attempts")
    local planned = ir_runtime_adapter.planEvent(binding, binding.plan, event, plannerOptions(binding, options or {}))
    if planned.ok ~= true then
        runtime_stats.inc("ir_pierce_runtime_mismatch")
        return { ok = false, error = planned.rejection_reason or "pierce_ir_plan_failed" }
    end
    if type(planned.job_plan) ~= "table" or planned.job_plan.ok ~= true then
        runtime_stats.inc("ir_pierce_runtime_mismatch")
        return { ok = false, error = planned.job_plan and planned.job_plan.rejection_reason or "pierce_job_plan_failed" }
    end
    local job_ids = {}
    local payload_slot_ids = {}
    local payload_helper_engine_ids = {}
    for index, planned_job in ipairs(planned.job_plan.planned_jobs or {}) do
        local payload = binding.payloads and binding.payloads[index] or {}
        local job = planned_job
        job.kind = orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND
        job.recipe_id = binding.recipe_id
        job.slot_id = payload.slot_id or job.slot_id
        job.helper_engine_id = payload.helper_engine_id or job.helper_engine_id
        job.idempotency_key = string.format("%s:%s", tostring(key), tostring(job.payload_slot_id or job.slot_id))
        job.source_job_id = binding.source_job_id or (route.user_data and route.user_data.job_id)
        job.parent_job_id = job.source_job_id
        job.cast_id = binding.cast_id
        job.source_slot_id = binding.source_slot_id
        job.source_helper_engine_id = binding.source_helper_engine_id
        job.source_prefix_opcode = "Pierce"
        job.source_postfix_opcode = "Trigger"
        job.payload_slot_id = payload.slot_id or job.payload_slot_id
        job.trigger_source_slot_id = binding.source_slot_id
        job.trigger_payload_slot_id = payload.slot_id or job.payload_slot_id
        job.trigger_route = "pierce"
        job.trigger_duplicate_key = key
        job.start_pos = origin
        job.direction = direction
        job.hit_object = route.actor
        job.excludeTarget = route.actor
        job.current_hit_target_id = route.actor_id
        job.pierce_runtime = true
        job.pierce_role = "trigger_payload_launch"
        job.pierce_id = binding.pierce_id
        job.pierce_count = route.pierce_count
        job.pierce_limit = binding.pierce_limit
        job.pierce_trigger_payload_slot_id = job.payload_slot_id
        job.payload = job.payload or {}
        for field, value in pairs({
            actor = binding.actor,
            start_pos = origin,
            direction = direction,
            hit_object = route.actor,
            excludeTarget = route.actor,
            current_hit_target_id = route.actor_id,
            trigger_route = "pierce",
            trigger_duplicate_key = key,
            pierce_runtime = true,
            pierce_role = "trigger_payload_launch",
            pierce_id = binding.pierce_id,
            pierce_count = route.pierce_count,
            pierce_limit = binding.pierce_limit,
            pierce_trigger_payload_slot_id = job.payload_slot_id,
        }) do
            job.payload[field] = value
        end
        local enqueue = orchestrator.enqueue(job)
        if not enqueue.ok then
            runtime_stats.inc("live_pierce_trigger_payload_failed")
            return { ok = false, error = enqueue.error or "pierce payload enqueue failed", job_ids = job_ids }
        end
        job_ids[#job_ids + 1] = enqueue.job_id
        payload_slot_ids[#payload_slot_ids + 1] = job.payload_slot_id
        payload_helper_engine_ids[#payload_helper_engine_ids + 1] = job.helper_engine_id
    end
    runtime_stats.inc("ir_pierce_runtime_enqueued")
    runtime_stats.inc("live_pierce_trigger_payload_enqueued", #job_ids)
    log.info(string.format(
        "SPELLFORGE_IR_PIERCE_RUNTIME_ENQUEUED recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s payload_count=%s first_job_id=%s branch_kind=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.pierce_id),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(job_ids[1]),
        tostring(planned.job_plan.planned_jobs and planned.job_plan.planned_jobs[1] and planned.job_plan.planned_jobs[1].branch_kind or nil)
    ))
    log.info(string.format(
        "SPELLFORGE_LIVE_PIERCE_TRIGGER_PAYLOAD_OK recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s payload_count=%s actor_id=%s projectile_id=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.pierce_id),
        tostring(binding.source_slot_id),
        tostring(#job_ids),
        tostring(route.actor_id),
        tostring(route.projectile_id)
    ))
    runtime_stats.inc("live_pierce_trigger_payload_ok")
    return {
        ok = true,
        job_ids = job_ids,
        trigger_route = "pierce",
        launch_count = #job_ids,
        payload_count = #job_ids,
        payload_slot_id = payload_slot_ids[1],
        payload_helper_engine_id = payload_helper_engine_ids[1],
        payload_slot_ids = payload_slot_ids,
        payload_helper_engine_ids = payload_helper_engine_ids,
        ir_pierce_runtime = true,
        ir_pierce_runtime_job_count = #job_ids,
    }
end

local function routeTriggerChain(route, binding, key, options)
    local origin, direction = safeOrigin(route, binding)
    local chain_route = {
        ok = true,
        source = "pierce",
        recipe_id = binding.recipe_id,
        slot_id = binding.source_slot_id,
        helper_engine_id = binding.source_helper_engine_id,
        attacker = route.attacker or binding.actor,
        target = route.actor,
        hit_pos = origin or route.hit_pos,
        hit_normal = route.hit_normal,
        projectile = route.projectile,
        projectile_id = route.projectile_id,
        projectile_id_source = route.projectile_id_source,
        user_data = {
            runtime = "2.2c_live_helper",
            recipe_id = binding.recipe_id,
            slot_id = binding.source_slot_id,
            helper_engine_id = binding.source_helper_engine_id,
            job_kind = "live_pierce_chain_source_hit",
            job_id = binding.source_job_id,
            source_job_id = binding.source_job_id,
            source_slot_id = binding.source_slot_id,
            source_prefix_opcode = "Pierce",
            source_postfix_opcode = "Trigger",
            source_helper_engine_id = binding.source_helper_engine_id,
            trigger_source_slot_id = binding.source_slot_id,
            trigger_payload_slot_id = binding.payload_slot_id,
            trigger_route = "pierce",
            trigger_duplicate_key = key,
            payload_slot_id = binding.payload_slot_id,
            cast_id = binding.cast_id,
            chain_runtime = true,
            chain_role = "source",
            chain_id = binding.chain_id,
            chain_hop_index = 0,
            chain_max_hops = binding.chain_max_hops,
            chain_targeting_mode = binding.chain_targeting_mode or "no_immediate_repeat",
            current_hit_target_id = route.actor_id,
            pierce_runtime = true,
            pierce_role = "trigger_chain_payload",
            pierce_id = binding.pierce_id,
            pierce_count = route.pierce_count,
            pierce_limit = binding.pierce_limit,
            pierce_trigger_payload_slot_id = binding.payload_slot_id,
            branch_scope = binding.branch_scope or binding.pierce_id,
            branch_id = string.format(
                "%s:p%s:chain",
                tostring(binding.branch_parent_id or binding.pierce_id or "pierce"),
                tostring(route.pierce_count or 0)
            ),
            branch_parent_id = binding.branch_parent_id or binding.source_job_id,
            branch_kind = "pierce_trigger_chain_payload",
            branch_index = tonumber(route.pierce_count) or 1,
            branch_count = tonumber(binding.pierce_limit) or 1,
        },
    }
    runtime_stats.inc("ir_pierce_runtime_attempts")
    local result = live_chain.handleResolvedHit(chain_route, {
        candidate_provider = binding.chain_candidate_provider,
        max_chain_ticks = binding.max_chain_ticks,
        max_jobs_per_tick = binding.max_jobs_per_tick,
        max_live_launches_per_tick = binding.max_live_launches_per_tick,
        force_enabled = binding.force_chain_runtime_enabled == true,
    })
    if result and result.ok == true then
        runtime_stats.inc("ir_pierce_runtime_enqueued")
        runtime_stats.inc("live_pierce_trigger_payload_ok")
    end
    log.info(string.format(
        "SPELLFORGE_IR_PIERCE_RUNTIME_ENQUEUED recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s payload_count=%s branch_kind=%s chain_id=%s stop_reason=%s",
        tostring(binding.recipe_id),
        tostring(binding.cast_id),
        tostring(binding.pierce_id),
        tostring(binding.source_slot_id),
        tostring(result and result.launch_count or 0),
        "pierce_trigger_chain_payload",
        tostring(binding.chain_id),
        tostring(result and result.stop_reason or nil)
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
        trigger_route = "pierce_chain",
        duplicate_key = key,
        chain_id = binding.chain_id,
        chain_result = result,
        chain_hop_index = result and result.chain_hop_index or nil,
        current_hit_target_id = result and result.current_hit_target_id or route.actor_id,
        selected_target_id = result and result.selected_target_id or nil,
        provider = result and result.provider or nil,
        job_id = result and result.job_id or nil,
        job_ids = result and result.job_ids or nil,
        jobs = result and result.jobs or nil,
        launch_accepted = result and result.launch_count == 1 or false,
        launch_count = result and result.launch_count or 0,
        projectile_id = result and result.projectile_id or nil,
        projectile_ids = result and result.projectile_ids or nil,
        launch_user_data = chain_route.user_data,
        ir_pierce_runtime = true,
        ir_pierce_runtime_job_count = result and result.launch_count or 0,
    }
end

function live_pierce.handlePiercePayload(payload, opts)
    local options = opts or {}
    runtime_stats.inc("live_pierce_events")
    local route = routeFromPiercePayload(payload)
    if route.ok ~= true then
        log.info(string.format(
            "SPELLFORGE_LIVE_PIERCE_EVENT route_ok=false reason=%s projectile_id=%s has_user_data=%s",
            tostring(route.error),
            tostring(route.projectile_id),
            tostring(route.user_data ~= nil)
        ))
        return { ok = false, ignored = true, error = route.error }
    end
    log.info(string.format(
        "SPELLFORGE_SFP_PIERCE_CONTRACT_OK spell_id=%s projectile_id=%s actor_id=%s pierce_count=%s pierce_limit=%s is_pierce=%s has_user_data=true",
        tostring(route.helper_engine_id),
        tostring(route.projectile_id),
        tostring(route.actor_id),
        tostring(route.pierce_count),
        tostring(route.pierce_limit),
        tostring(route.is_pierce)
    ))

    local binding = bindingForRoute(route)
    log.info(string.format(
        "SPELLFORGE_LIVE_PIERCE_EVENT recipe_id=%s cast_id=%s source_slot_id=%s helper_engine_id=%s projectile_id=%s actor_id=%s pierce_count=%s pierce_limit=%s route_ok=%s",
        tostring(route.recipe_id),
        tostring(route.cast_id),
        tostring(route.source_slot_id),
        tostring(route.helper_engine_id),
        tostring(route.projectile_id),
        tostring(route.actor_id),
        tostring(route.pierce_count),
        tostring(route.pierce_limit),
        tostring(binding ~= nil)
    ))
    if not binding then
        return { ok = true, ignored = true, reason = "no_live_pierce_binding" }
    end
    if runtime_session.shouldDrop(binding.runtime_generation, "live_pierce_binding", {
        id = binding.source_slot_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if route.user_data and runtime_session.shouldDrop(route.user_data.runtime_generation, "live_pierce_route", {
        id = route.projectile_id,
        strict = true,
    }) then
        return { ok = true, ignored = true, stale_generation = true }
    end
    if options.force_enabled ~= true and not dev.livePierceEnabled() then
        return { ok = true, ignored = true, reason = "live_pierce_disabled" }
    end
    if route.actor_id == nil then
        return { ok = true, ignored = true, reason = "sfp_pierce_actor_id_missing" }
    end

    local key = duplicateKey(route, binding)
    if duplicate_keys[key] then
        runtime_stats.inc("live_pierce_duplicate_suppressed")
        log.info(string.format(
            "SPELLFORGE_LIVE_PIERCE_DUPLICATE_SUPPRESSED recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s actor_id=%s pierce_count=%s projectile_id=%s",
            tostring(binding.recipe_id),
            tostring(binding.cast_id),
            tostring(binding.pierce_id),
            tostring(binding.source_slot_id),
            tostring(route.actor_id),
            tostring(route.pierce_count),
            tostring(route.projectile_id)
        ))
        return { ok = true, ignored = true, duplicate = true, duplicate_suppressed = true, duplicate_key = key }
    end
    duplicate_keys[key] = true

    local result = nil
    if binding.has_trigger_payload ~= true then
        result = { ok = true, trigger_route = "pierce_source", payload_count = 0 }
    elseif binding.has_chain_payload == true then
        result = routeTriggerChain(route, binding, key, options)
    else
        result = routeTriggerPayloads(route, binding, key, options)
    end
    local limit_stop = stopAtPierceLimit(route, binding, options)
    if type(result) == "table" and limit_stop ~= nil then
        result.pierce_limit_stop = limit_stop
        result.pierce_limit_stop_ok = limit_stop.ok == true
    end
    return result
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

function live_pierce.summary()
    return {
        bindings = countMap(bindings_by_key),
        helper_bindings = countMap(bindings_by_helper),
        duplicate_keys = countMap(duplicate_keys),
        runtime_generation = runtime_session.currentGeneration(),
    }
end

function live_pierce.clearTransient(reason)
    local before = live_pierce.summary()
    bindings_by_key = {}
    bindings_by_helper = {}
    duplicate_keys = {}
    log.info(string.format(
        "SPELLFORGE_LIVE_PIERCE_CLEARED reason=%s pierce_entries=%s duplicate_keys=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.bindings),
        tostring(before.duplicate_keys),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function live_pierce.clearForTests()
    return live_pierce.clearTransient("tests")
end

return live_pierce
