local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.orchestrator")
local runtime_launch = require("scripts.spellforge.global.runtime_launch")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local orchestrator = {}
orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND = "live_2_2c_simple_launch_helper"
orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND = "live_trigger_payload_launch"
orchestrator.LIVE_TIMER_PAYLOAD_JOB_KIND = "live_timer_payload_launch"
orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND = "live_chain_payload_launch"

local queue = {}
local jobs = {}
local next_job_index = 1
local current_tick = 0
local elapsed_seconds = 0
local live_launches_this_update = 0
local live_launch_density_groups = {}
local LAUNCH_DENSITY_GROUP_TTL_TICKS = 256

local function cloneJob(job)
    if type(job) ~= "table" then
        return nil
    end
    local out = {}
    for k, v in pairs(job) do
        out[k] = v
    end
    return out
end

local function appendError(errors, path, message)
    errors[#errors + 1] = {
        path = path,
        message = message,
    }
end

local function validateDepth(depth)
    local d = tonumber(depth) or 0
    if d > limits.MAX_RECURSION_DEPTH then
        return false, string.format("depth exceeds MAX_RECURSION_DEPTH (%d)", limits.MAX_RECURSION_DEPTH)
    end
    if d < 0 then
        return false, "depth must be >= 0"
    end
    return true, nil
end

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function finiteNonNegative(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge or n < 0 then
        return nil
    end
    return n
end

local function isExpired(job)
    local tick_expired = job.expires_at_tick ~= nil and current_tick >= job.expires_at_tick
    local time_expired = job.expires_at_seconds ~= nil and elapsed_seconds >= job.expires_at_seconds
    return tick_expired or time_expired
end

local function notReady(job)
    local tick_not_ready = job.not_before_tick ~= nil and current_tick < job.not_before_tick
    local time_not_ready = job.not_before_seconds ~= nil and elapsed_seconds + 0.0001 < job.not_before_seconds
    return tick_not_ready or time_not_ready, tick_not_ready, time_not_ready
end

local function isLiveHelperJob(kind)
    return kind == orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND
        or kind == orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND
        or kind == orchestrator.LIVE_TIMER_PAYLOAD_JOB_KIND
        or kind == orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND
end

local function isLiveTimerPayloadJob(kind)
    return kind == orchestrator.LIVE_TIMER_PAYLOAD_JOB_KIND
end

local function clampPositiveInteger(value, fallback)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = tonumber(fallback)
    end
    n = tonumber(n) or 1
    return math.max(1, math.floor(n))
end

local function defaultInitialBurstCap(job, sustained_cap)
    if job and job.chaos_budget_profile == "chaos" then
        return limits.MAX_LIVE_LAUNCHES_INITIAL_BURST_CHAOS or sustained_cap
    end
    return sustained_cap
end

local function launchDensityGroupKey(job)
    if type(job) ~= "table" then
        return nil
    end
    if type(job.launch_density_group_key) == "string" and job.launch_density_group_key ~= "" then
        return job.launch_density_group_key
    end
    local root = job.cast_id or job.recipe_id or "unknown_cast"
    local route = job.timer_id or job.source_job_id or job.parent_job_id or job.source_slot_id or "root"
    return table.concat({
        tostring(root),
        tostring(job.kind or "live_launch"),
        tostring(route),
    }, ":")
end

local function pruneLaunchDensityGroups()
    for key, state in pairs(live_launch_density_groups) do
        local burst_tick = tonumber(state and state.burst_tick) or current_tick
        if current_tick - burst_tick > LAUNCH_DENSITY_GROUP_TTL_TICKS then
            live_launch_density_groups[key] = nil
        end
    end
end

local function liveLaunchCapForJob(job, default_sustained_cap)
    local sustained_cap = clampPositiveInteger(firstNonNil(
        job.max_live_launches_per_tick,
        job.max_live_launches_per_update
    ), default_sustained_cap)
    local burst_cap = clampPositiveInteger(firstNonNil(
        job.max_live_launches_initial_burst,
        job.max_live_launches_initial_burst_per_update
    ), defaultInitialBurstCap(job, sustained_cap))
    burst_cap = math.min(
        math.max(sustained_cap, burst_cap),
        limits.MAX_LIVE_LAUNCHES_INITIAL_BURST_HARD or burst_cap
    )

    local group_key = launchDensityGroupKey(job)
    local state = group_key and live_launch_density_groups[group_key] or nil
    local burst_available = burst_cap > sustained_cap and (state == nil or state.burst_tick == current_tick)
    return burst_available and burst_cap or sustained_cap, sustained_cap, burst_cap, group_key, burst_available and state == nil
end

local function enqueueInternal(job)
    local job_id = string.format("job_%d", next_job_index)
    next_job_index = next_job_index + 1

    local depth = tonumber(job.depth) or 0
    local ttl_ticks = tonumber(job.ttl_ticks)
    local ttl_seconds = finiteNonNegative(job.ttl_seconds)

    local normalized = {
        job_id = job_id,
        kind = job.kind,
        status = "queued",
        runtime_generation = tonumber(job.runtime_generation) or runtime_session.currentGeneration(),
        recipe_id = job.recipe_id,
        slot_id = job.slot_id,
        helper_engine_id = job.helper_engine_id,
        idempotency_key = job.idempotency_key,
        parent_job_id = job.parent_job_id,
        source_job_id = job.source_job_id,
        depth = depth,
        cast_id = job.cast_id,
        emission_index = job.emission_index,
        group_index = job.group_index,
        fanout_count = job.fanout_count,
        max_live_launches_per_tick = job.max_live_launches_per_tick,
        max_live_launches_per_update = job.max_live_launches_per_update,
        max_live_launches_initial_burst = job.max_live_launches_initial_burst,
        max_live_launches_initial_burst_per_update = job.max_live_launches_initial_burst_per_update,
        launch_density_group_key = job.launch_density_group_key,
        chaos_budget_profile = job.chaos_budget_profile,
        pattern_kind = job.pattern_kind,
        pattern_index = job.pattern_index,
        pattern_count = job.pattern_count,
        pattern_direction_key = job.pattern_direction_key,
        bounce_runtime = job.bounce_runtime == true,
        bounce_role = job.bounce_role,
        bounce_id = job.bounce_id,
        bounce_index = job.bounce_index,
        bounce_max = job.bounce_max,
        bounce_power = job.bounce_power,
        bounceEnabled = job.bounceEnabled,
        bounceMax = job.bounceMax,
        bouncePower = job.bouncePower,
        detonateOnActorHit = job.detonateOnActorHit,
        bounce_detonate_on_actor_hit = job.bounce_detonate_on_actor_hit,
        bounce_trigger_payload_slot_id = job.bounce_trigger_payload_slot_id,
        bounce_manual_detonation = job.bounce_manual_detonation,
        bounce_final = job.bounce_final,
        chain_runtime = job.chain_runtime == true,
        chain_role = job.chain_role,
        chain_id = job.chain_id,
        chain_hop_index = job.chain_hop_index,
        chain_max_hops = job.chain_max_hops,
        chain_targeting_mode = job.chain_targeting_mode,
        chain_target_provider = job.chain_target_provider,
        branch_scope = job.branch_scope,
        branch_id = job.branch_id,
        branch_parent_id = job.branch_parent_id,
        branch_kind = job.branch_kind,
        branch_index = job.branch_index,
        branch_count = job.branch_count,
        chain_continuation_group_id = job.chain_continuation_group_id,
        current_hit_target_id = job.current_hit_target_id,
        selected_target_id = job.selected_target_id,
        previous_projectile_id = job.previous_projectile_id,
        payload_modifier_kind = job.payload_modifier_kind,
        created_tick = current_tick,
        created_seconds = elapsed_seconds,
        expires_at_tick = job.expires_at_tick,
        expires_at_seconds = finiteNonNegative(job.expires_at_seconds),
        ttl_ticks = ttl_ticks,
        ttl_seconds = ttl_seconds,
        payload = job.payload,
        not_before_tick = job.not_before_tick,
        not_before_seconds = finiteNonNegative(job.not_before_seconds),
        source_slot_id = job.source_slot_id,
        source_prefix_opcode = job.source_prefix_opcode,
        source_helper_engine_id = job.source_helper_engine_id,
        source_postfix_opcode = job.source_postfix_opcode,
        payload_slot_id = job.payload_slot_id,
        timer_source_slot_id = job.timer_source_slot_id,
        timer_payload_slot_id = job.timer_payload_slot_id,
        timer_id = job.timer_id,
        timer_async = job.timer_async == true,
        timer_delay_ticks = job.timer_delay_ticks,
        timer_delay_seconds = job.timer_delay_seconds,
        timer_scheduled_tick = job.timer_scheduled_tick,
        timer_due_tick = job.timer_due_tick,
        timer_scheduled_seconds = job.timer_scheduled_seconds,
        timer_due_seconds = job.timer_due_seconds,
        timer_delay_semantics = job.timer_delay_semantics,
        timer_duplicate_key = job.timer_duplicate_key,
        error = nil,
        trace = {},
    }

    if ttl_ticks ~= nil then
        normalized.expires_at_tick = current_tick + ttl_ticks
    end
    if ttl_seconds ~= nil then
        normalized.expires_at_seconds = elapsed_seconds + ttl_seconds
    end

    jobs[job_id] = normalized
    queue[#queue + 1] = job_id
    runtime_stats.inc("jobs_enqueued")
    if isLiveHelperJob(normalized.kind) then
        runtime_stats.inc("live_helper_jobs_enqueued")
    end
    runtime_stats.max("max_queue_depth", #queue)

    return normalized
end

function orchestrator.enqueue(job, opts)
    local _ = opts
    if type(job) ~= "table" then
        return { ok = false, error = "job must be a table" }
    end

    local kind = job.kind
    if type(kind) ~= "string" or kind == "" then
        return { ok = false, error = "job.kind must be a non-empty string" }
    end

    local depth_ok, depth_err = validateDepth(job.depth)
    if not depth_ok then
        return { ok = false, error = depth_err }
    end

    local normalized = enqueueInternal(job)
    return {
        ok = true,
        job_id = normalized.job_id,
        status = normalized.status,
    }
end

function orchestrator.cancel(job_id)
    local job = jobs[job_id]
    if not job then
        return { ok = false, error = "job not found" }
    end
    if job.status ~= "queued" then
        return { ok = false, error = string.format("cannot cancel job in status=%s", tostring(job.status)) }
    end
    job.status = "canceled"
    return { ok = true }
end

local function runHandler(job)
    if job.kind == "noop" or job.kind == "mark_complete" then
        return true, nil, nil
    elseif job.kind == "fail" then
        return false, tostring(job.payload and job.payload.error or "dummy fail"), nil
    elseif job.kind == "enqueue_child_dummy" then
        local child_depth = (job.depth or 0) + 1
        local depth_ok, depth_err = validateDepth(child_depth)
        if not depth_ok then
            return false, depth_err, nil
        end
        local child_kind = job.payload and job.payload.child_kind or "noop"
        local child = enqueueInternal({
            kind = child_kind,
            recipe_id = job.recipe_id,
            slot_id = job.slot_id,
            helper_engine_id = job.helper_engine_id,
            parent_job_id = job.job_id,
            source_job_id = job.job_id,
            depth = child_depth,
            payload = job.payload and job.payload.child_payload or nil,
            not_before_tick = current_tick + 1,
        })
        return true, nil, child.job_id
    elseif job.kind == orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND then
        return runtime_launch.runHelperLaunchJob(job, orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND)
    elseif job.kind == orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND then
        return runtime_launch.runHelperLaunchJob(job, orchestrator.LIVE_TRIGGER_PAYLOAD_JOB_KIND, {
            expected_postfix_opcode = "Trigger",
        })
    elseif job.kind == orchestrator.LIVE_TIMER_PAYLOAD_JOB_KIND then
        return runtime_launch.runHelperLaunchJob(job, orchestrator.LIVE_TIMER_PAYLOAD_JOB_KIND, {
            expected_postfix_opcode = "Timer",
        })
    elseif job.kind == orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND then
        return runtime_launch.runHelperLaunchJob(job, orchestrator.LIVE_CHAIN_PAYLOAD_JOB_KIND)
    end

    return false, string.format("unsupported job kind: %s", tostring(job.kind)), nil
end

function orchestrator.tick(opts)
    local options = opts or {}
    local delta_seconds = finiteNonNegative(firstNonNil(
        options.dt_seconds,
        options.delta_seconds,
        options.elapsed_seconds_delta,
        options.dt
    ))
    if delta_seconds ~= nil then
        elapsed_seconds = elapsed_seconds + delta_seconds
        live_launches_this_update = 0
    end
    current_tick = current_tick + 1
    pruneLaunchDensityGroups()

    local max_jobs = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK
    local max_live_launches = tonumber(firstNonNil(
        options.max_live_launches_per_tick,
        options.max_live_launches_per_update
    )) or limits.MAX_LIVE_LAUNCHES_PER_TICK
    max_jobs = math.max(1, math.floor(max_jobs))
    max_live_launches = math.max(1, math.floor(max_live_launches))
    local processed_count = 0
    local completed_count = 0
    local failed_count = 0
    local expired_count = 0
    local canceled_count = 0
    local live_launch_count = 0
    local live_launch_throttled_count = 0
    local effective_live_launch_cap = max_live_launches
    local effective_live_launch_burst_cap = max_live_launches
    local initial_burst_used_count = 0
    local processed_order = {}

    local iterations = 0
    local initial_len = #queue

    while processed_count < max_jobs and #queue > 0 and iterations < initial_len do
        iterations = iterations + 1
        local job_id = table.remove(queue, 1)
        local job = jobs[job_id]

        if job and job.status == "queued" then
            if runtime_session.shouldDrop(job.runtime_generation, "orchestrator_job", {
                id = job.job_id,
                strict = true,
            }) then
                job.status = "canceled"
                processed_count = processed_count + 1
                canceled_count = canceled_count + 1
                processed_order[#processed_order + 1] = job_id
                runtime_stats.inc("jobs_processed")
                runtime_stats.inc("jobs_canceled")
            else
            local job_live_launch_cap = max_live_launches
            local job_live_launch_sustained_cap = max_live_launches
            local job_live_launch_burst_cap = max_live_launches
            local launch_density_group_key = nil
            local should_mark_initial_burst = false
            if isLiveHelperJob(job.kind) then
                job_live_launch_cap,
                    job_live_launch_sustained_cap,
                    job_live_launch_burst_cap,
                    launch_density_group_key,
                    should_mark_initial_burst = liveLaunchCapForJob(job, max_live_launches)
                effective_live_launch_cap = math.min(effective_live_launch_cap, job_live_launch_sustained_cap)
                effective_live_launch_burst_cap = math.max(effective_live_launch_burst_cap, job_live_launch_burst_cap)
            end
            local waiting, _, time_not_ready = notReady(job)
            if waiting then
                queue[#queue + 1] = job_id
                runtime_stats.inc("jobs_skipped_not_ready")
                if isLiveTimerPayloadJob(job.kind) then
                    runtime_stats.inc("live_timer_wait_jobs_not_ready")
                    if time_not_ready then
                        runtime_stats.inc("live_timer_real_delay_not_ready")
                    end
                end
                runtime_stats.max("max_queue_depth", #queue)
            elseif isExpired(job) then
                job.status = "expired"
                processed_count = processed_count + 1
                expired_count = expired_count + 1
                processed_order[#processed_order + 1] = job_id
                runtime_stats.inc("jobs_processed")
                runtime_stats.inc("jobs_expired")
                if isLiveTimerPayloadJob(job.kind) then
                    runtime_stats.inc("live_timer_wait_jobs_expired")
                end
                if isLiveHelperJob(job.kind) then
                    runtime_stats.inc("live_helper_jobs_processed")
                end
            elseif isLiveHelperJob(job.kind) and live_launches_this_update >= job_live_launch_cap then
                queue[#queue + 1] = job_id
                live_launch_throttled_count = live_launch_throttled_count + 1
                runtime_stats.inc("live_launch_density_throttled")
                runtime_stats.inc("chaos_budget_launch_density_throttle")
                runtime_stats.max("max_queue_depth", #queue)
            else
                job.status = "running"
                if should_mark_initial_burst and launch_density_group_key then
                    live_launch_density_groups[launch_density_group_key] = {
                        burst_tick = current_tick,
                    }
                    initial_burst_used_count = initial_burst_used_count + 1
                    runtime_stats.inc("live_launch_density_initial_burst")
                    runtime_stats.inc("chaos_budget_launch_density_initial_burst")
                    runtime_stats.max("chaos_budget_max_live_launches_initial_burst_observed", job_live_launch_burst_cap)
                end
                if isLiveTimerPayloadJob(job.kind) and job.not_before_seconds ~= nil then
                    runtime_stats.inc("live_timer_real_delay_matured")
                end
                local ok, err, child_job_id = runHandler(job)
                processed_count = processed_count + 1
                processed_order[#processed_order + 1] = job_id
                runtime_stats.inc("jobs_processed")
                if isLiveHelperJob(job.kind) then
                    live_launch_count = live_launch_count + 1
                    live_launches_this_update = live_launches_this_update + 1
                    runtime_stats.inc("live_helper_jobs_processed")
                    runtime_stats.max("chaos_budget_max_live_launches_per_tick_observed", live_launches_this_update)
                end
                if isLiveTimerPayloadJob(job.kind) then
                    if job.timer_async ~= true then
                        runtime_stats.inc("live_timer_wait_jobs_processed")
                    end
                    runtime_stats.inc("live_timer_payload_jobs_processed")
                end

                if ok then
                    job.status = "complete"
                    if child_job_id then
                        job.child_job_id = child_job_id
                    end
                    completed_count = completed_count + 1
                    if isLiveTimerPayloadJob(job.kind) then
                        runtime_stats.inc("live_timer_payload_launch_ok")
                        if job.not_before_seconds ~= nil or job.timer_async == true then
                            runtime_stats.inc("live_timer_real_delay_payload_ok")
                        end
                        if job.timer_async == true then
                            runtime_stats.inc("live_timer_async_payload_ok")
                        end
                        log.info(string.format(
                            "SPELLFORGE_LIVE_TIMER_PAYLOAD_OK timer_id=%s recipe_id=%s cast_id=%s source_slot_id=%s payload_slot_id=%s helper_engine_id=%s projectile_id=%s due_tick=%s due_seconds=%s elapsed_seconds=%s",
                            tostring(job.timer_id),
                            tostring(job.recipe_id),
                            tostring(job.cast_id),
                            tostring(job.source_slot_id),
                            tostring(job.payload_slot_id or job.slot_id),
                            tostring(job.helper_engine_id),
                            tostring(job.projectile_id),
                            tostring(job.timer_due_tick),
                            tostring(job.timer_due_seconds or job.not_before_seconds),
                            tostring(elapsed_seconds)
                        ))
                    end
                else
                    job.status = "failed"
                    job.error = tostring(err)
                    failed_count = failed_count + 1
                    runtime_stats.inc("jobs_failed")
                    if isLiveHelperJob(job.kind) then
                        runtime_stats.inc("live_helper_jobs_failed")
                    end
                    if isLiveTimerPayloadJob(job.kind) then
                        runtime_stats.inc("live_timer_payload_launch_failed")
                        runtime_stats.inc("live_timer_payload_route_failed")
                    end
                end
            end
            end
        elseif job and job.status == "canceled" then
            canceled_count = canceled_count + 1
        end
    end

    if #queue == 0 then
        runtime_stats.inc("queue_drained_observed")
    end

    if live_launch_throttled_count > 0 then
        log.info(string.format(
            "SPELLFORGE_LIVE_LAUNCH_DENSITY_THROTTLED tick=%s cap=%d burst_cap=%d throttled=%d remaining=%d",
            tostring(current_tick),
            effective_live_launch_cap,
            effective_live_launch_burst_cap,
            live_launch_throttled_count,
            #queue
        ))
    end

    return {
        tick = current_tick,
        processed_count = processed_count,
        completed_count = completed_count,
        failed_count = failed_count,
        expired_count = expired_count,
        canceled_count = canceled_count,
        remaining_count = #queue,
        processed_order = processed_order,
        elapsed_seconds = elapsed_seconds,
        delta_seconds = delta_seconds or 0,
        live_launch_count = live_launch_count,
        live_launches_this_update = live_launches_this_update,
        max_live_launches_per_tick = effective_live_launch_cap,
        max_live_launches_initial_burst = effective_live_launch_burst_cap,
        live_launch_throttled_count = live_launch_throttled_count,
        initial_burst_used_count = initial_burst_used_count,
    }
end

function orchestrator.getJob(job_id)
    return cloneJob(jobs[job_id])
end

function orchestrator.currentTick()
    return current_tick
end

function orchestrator.currentTimeSeconds()
    return elapsed_seconds
end

function orchestrator.advanceTime(seconds)
    local delta_seconds = finiteNonNegative(seconds)
    if delta_seconds == nil then
        return {
            ok = false,
            error = "seconds must be a finite non-negative number",
            elapsed_seconds = elapsed_seconds,
            live_launches_this_update = live_launches_this_update,
        }
    end
    elapsed_seconds = elapsed_seconds + delta_seconds
    live_launches_this_update = 0
    return {
        ok = true,
        elapsed_seconds = elapsed_seconds,
        delta_seconds = delta_seconds,
        live_launches_this_update = live_launches_this_update,
    }
end

function orchestrator.queueLength()
    return #queue
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

function orchestrator.summary()
    return {
        queue = #queue,
        jobs = countMap(jobs),
        live_launch_density_groups = countMap(live_launch_density_groups),
        live_launches_this_update = live_launches_this_update,
        max_live_launches_per_tick = limits.MAX_LIVE_LAUNCHES_PER_TICK,
        current_tick = current_tick,
        elapsed_seconds = elapsed_seconds,
    }
end

function orchestrator.clearTransient(reason)
    local before = orchestrator.summary()
    queue = {}
    jobs = {}
    next_job_index = 1
    current_tick = 0
    elapsed_seconds = 0
    live_launches_this_update = 0
    live_launch_density_groups = {}
    log.info(string.format(
        "SPELLFORGE_ORCHESTRATOR_CLEARED reason=%s jobs=%s queue=%s density_groups=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.jobs),
        tostring(before.queue),
        tostring(before.live_launch_density_groups),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function orchestrator.clearForTests()
    return orchestrator.clearTransient("tests")
end

return orchestrator
