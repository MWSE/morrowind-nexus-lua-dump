---@omw-context global
local dev = require("scripts.spellforge.shared.dev")
local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.chaos_budget")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local chaos_budget = {}

local function truthy(value)
    return value == true
end

local function profileName(opts)
    opts = opts or {}
    if truthy(opts.force_chaos_budget_disabled) then
        return "default"
    end
    if truthy(opts.force_chaos_budget_enabled) or opts.chaos_budget_profile == "chaos" then
        return "chaos"
    end
    if dev.chaosBudgetEnabled() then
        return "chaos"
    end
    return "default"
end

local function choose(profile, default_value, chaos_value)
    if profile == "chaos" then
        return chaos_value
    end
    return default_value
end

local function effectiveLimits(profile)
    local max_chain_hops = choose(profile, limits.MAX_CHAIN_HOPS_DEFAULT, limits.MAX_CHAIN_HOPS_CHAOS)
    local max_projectiles = choose(profile, limits.MAX_PROJECTILES_PER_CAST_DEFAULT, limits.MAX_PROJECTILES_PER_CAST_CHAOS)
    local max_payload_fanout = choose(profile, limits.MAX_PAYLOAD_FANOUT_DEFAULT, limits.MAX_PAYLOAD_FANOUT_CHAOS)
    local max_nested_final_fanout = choose(profile, limits.MAX_NESTED_FINAL_FANOUT_DEFAULT, limits.MAX_NESTED_FINAL_FANOUT_CHAOS)
    local max_jobs_per_tick = choose(profile, limits.MAX_JOBS_PER_TICK_DEFAULT, limits.MAX_JOBS_PER_TICK_CHAOS)
    local max_live_launches_per_tick = choose(profile, limits.MAX_LIVE_LAUNCHES_PER_TICK_DEFAULT, limits.MAX_LIVE_LAUNCHES_PER_TICK_CHAOS)
    local max_live_launches_initial_burst = choose(profile, limits.MAX_LIVE_LAUNCHES_INITIAL_BURST_DEFAULT, limits.MAX_LIVE_LAUNCHES_INITIAL_BURST_CHAOS)
    local max_nested_jobs = choose(profile, limits.MAX_NESTED_PAYLOAD_JOBS_DEFAULT, limits.MAX_NESTED_PAYLOAD_JOBS_CHAOS)
    local max_cast_jobs = choose(profile, limits.MAX_CAST_TOTAL_JOB_BUDGET_DEFAULT, limits.MAX_CAST_TOTAL_JOB_BUDGET_CHAOS)
    local max_chain_scan_candidates = choose(profile, limits.MAX_CHAIN_SCAN_CANDIDATES_DEFAULT, limits.MAX_CHAIN_SCAN_CANDIDATES_CHAOS)
    local max_chain_scan_actors = choose(profile, limits.MAX_CHAIN_SCAN_ACTORS_DEFAULT, limits.MAX_CHAIN_SCAN_ACTORS_CHAOS)
    local max_chain_branches = choose(profile, limits.MAX_CHAIN_BRANCHES_DEFAULT, limits.MAX_CHAIN_BRANCHES_CHAOS)
    local max_chain_multicast_fanout = choose(profile, limits.MAX_CHAIN_MULTICAST_FANOUT_DEFAULT, limits.MAX_CHAIN_MULTICAST_FANOUT_CHAOS)

    return {
        MAX_RECURSION_DEPTH = limits.MAX_RECURSION_DEPTH,
        MAX_PROJECTILES_PER_CAST = math.min(max_projectiles, limits.MAX_PROJECTILES_PER_CAST_HARD),
        MAX_SCAN_RADIUS = limits.MAX_SCAN_RADIUS,
        MAX_PAYLOAD_FANOUT = math.min(max_payload_fanout, limits.MAX_PAYLOAD_FANOUT_HARD),
        MAX_NESTED_FINAL_FANOUT = math.min(max_nested_final_fanout, limits.MAX_NESTED_FINAL_FANOUT_HARD),
        MAX_CAST_TOTAL_JOB_BUDGET = math.min(max_cast_jobs, limits.MAX_CAST_TOTAL_JOB_BUDGET_HARD),
        MAX_CHAIN_HOPS = max_chain_hops,
        MAX_CHAIN_AUDIT_HOPS = max_chain_hops,
        MAX_CHAIN_TARGETS_PER_HOP = limits.MAX_CHAIN_TARGETS_PER_HOP,
        MAX_CHAIN_SCAN_RADIUS = limits.MAX_CHAIN_SCAN_RADIUS,
        MAX_CHAIN_SCAN_CANDIDATES = max_chain_scan_candidates,
        MAX_CHAIN_SCAN_ACTORS = max_chain_scan_actors,
        MAX_CHAIN_VERTICAL_DELTA = limits.MAX_CHAIN_VERTICAL_DELTA,
        CHAIN_AIM_HEIGHT = limits.CHAIN_AIM_HEIGHT,
        MAX_CHAIN_JOBS_PER_CAST = max_chain_hops * math.max(1, math.min(max_chain_multicast_fanout, limits.MAX_CHAIN_MULTICAST_FANOUT_HARD)),
        MAX_CHAIN_BRANCHES = max_chain_branches,
        MAX_CHAIN_MULTICAST_FANOUT = math.min(max_chain_multicast_fanout, limits.MAX_CHAIN_MULTICAST_FANOUT_HARD),
        MAX_JOBS_PER_TICK = max_jobs_per_tick,
        MAX_LIVE_LAUNCHES_PER_TICK = max_live_launches_per_tick,
        MAX_LIVE_LAUNCHES_INITIAL_BURST = math.min(max_live_launches_initial_burst, limits.MAX_LIVE_LAUNCHES_INITIAL_BURST_HARD),
        MAX_NESTED_PAYLOAD_JOBS = max_nested_jobs,
        MAX_NESTED_PAYLOAD_DEPTH = limits.MAX_NESTED_PAYLOAD_DEPTH,
        MAX_NESTED_PAYLOAD_FANOUT = math.min(max_payload_fanout, limits.MAX_PAYLOAD_FANOUT_HARD),
    }
end

function chaos_budget.effective(opts)
    local profile = profileName(opts)
    local budget_limits = effectiveLimits(profile)
    return {
        profile = profile,
        enabled = profile == "chaos",
        limits = budget_limits,
    }
end

function chaos_budget.withBudget(opts)
    local source = opts or {}
    local out = {}
    for key, value in pairs(source) do
        out[key] = value
    end

    local budget = chaos_budget.effective(source)
    local budget_limits = budget.limits
    out.chaos_budget = budget
    out.chaos_budget_profile = budget.profile
    out.budget_limits = budget_limits
    out.max_projectiles = tonumber(out.max_projectiles) or budget_limits.MAX_PROJECTILES_PER_CAST
    out.max_payload_fanout = tonumber(out.max_payload_fanout) or budget_limits.MAX_PAYLOAD_FANOUT
    out.max_jobs_per_tick = tonumber(out.max_jobs_per_tick) or budget_limits.MAX_JOBS_PER_TICK
    out.max_live_launches_per_tick = tonumber(out.max_live_launches_per_tick) or budget_limits.MAX_LIVE_LAUNCHES_PER_TICK
    out.max_live_launches_initial_burst = tonumber(out.max_live_launches_initial_burst) or budget_limits.MAX_LIVE_LAUNCHES_INITIAL_BURST
    out.max_nested_payload_jobs = tonumber(out.max_nested_payload_jobs) or budget_limits.MAX_NESTED_PAYLOAD_JOBS
    out.max_nested_payload_depth = tonumber(out.max_nested_payload_depth) or budget_limits.MAX_NESTED_PAYLOAD_DEPTH
    out.nested_final_fanout_max_fanout = tonumber(out.nested_final_fanout_max_fanout) or budget_limits.MAX_NESTED_FINAL_FANOUT
    out.max_chain_hops = tonumber(out.max_chain_hops) or budget_limits.MAX_CHAIN_HOPS
    out.max_chain_jobs = tonumber(out.max_chain_jobs) or budget_limits.MAX_CHAIN_JOBS_PER_CAST
    out.max_chain_scan_candidates = tonumber(out.max_chain_scan_candidates) or budget_limits.MAX_CHAIN_SCAN_CANDIDATES
    out.max_chain_scan_actors = tonumber(out.max_chain_scan_actors) or budget_limits.MAX_CHAIN_SCAN_ACTORS
    out.max_chain_branches = tonumber(out.max_chain_branches) or budget_limits.MAX_CHAIN_BRANCHES
    out.max_chain_multicast_fanout = tonumber(out.max_chain_multicast_fanout) or budget_limits.MAX_CHAIN_MULTICAST_FANOUT
    out.max_cast_total_jobs = tonumber(out.max_cast_total_jobs) or budget_limits.MAX_CAST_TOTAL_JOB_BUDGET
    return out
end

function chaos_budget.report(opts)
    local budget = chaos_budget.effective(opts)
    local budget_limits = budget.limits
    if budget.profile == "chaos" then
        runtime_stats.inc("chaos_budget_profile_chaos")
    else
        runtime_stats.inc("chaos_budget_profile_default")
    end
    log.info(string.format(
        "SPELLFORGE_CHAOS_BUDGET_PROFILE profile=%s enabled=%s",
        budget.profile,
        tostring(budget.enabled)
    ))
    log.info(string.format(
        "SPELLFORGE_CHAOS_BUDGET_LIMITS profile=%s projectile_cap=%d job_cap=%d fanout_cap=%d nested_final_fanout_cap=%d chain_hop_cap=%d chain_branch_cap=%d chain_multicast_fanout_cap=%d chain_candidate_cap=%d chain_actor_scan_cap=%d jobs_per_tick=%d live_launches_per_tick=%d live_launch_initial_burst=%d",
        budget.profile,
        budget_limits.MAX_PROJECTILES_PER_CAST,
        budget_limits.MAX_CAST_TOTAL_JOB_BUDGET,
        budget_limits.MAX_PAYLOAD_FANOUT,
        budget_limits.MAX_NESTED_FINAL_FANOUT,
        budget_limits.MAX_CHAIN_HOPS,
        budget_limits.MAX_CHAIN_BRANCHES,
        budget_limits.MAX_CHAIN_MULTICAST_FANOUT,
        budget_limits.MAX_CHAIN_SCAN_CANDIDATES,
        budget_limits.MAX_CHAIN_SCAN_ACTORS,
        budget_limits.MAX_JOBS_PER_TICK,
        budget_limits.MAX_LIVE_LAUNCHES_PER_TICK,
        budget_limits.MAX_LIVE_LAUNCHES_INITIAL_BURST
    ))
    return budget
end

function chaos_budget.recordReject(reason, category)
    runtime_stats.inc("chaos_budget_cap_reject")
    if category == "projectile" then
        runtime_stats.inc("chaos_budget_projectile_cap_reject")
    elseif category == "job" then
        runtime_stats.inc("chaos_budget_job_cap_reject")
    elseif category == "depth" then
        runtime_stats.inc("chaos_budget_depth_cap_reject")
    elseif category == "queue" then
        runtime_stats.inc("chaos_budget_queue_cap_reject")
    elseif category == "fanout" then
        runtime_stats.inc("chaos_budget_fanout_cap_reject")
    end
    log.warn(string.format(
        "SPELLFORGE_CHAOS_BUDGET_REJECTED reason=%s category=%s",
        tostring(reason or "unknown"),
        tostring(category or "unknown")
    ))
end

function chaos_budget.observe(fields)
    fields = fields or {}
    runtime_stats.max("chaos_budget_max_jobs_observed", tonumber(fields.jobs) or tonumber(fields.total_jobs) or tonumber(fields.job_count) or 0)
    runtime_stats.max("chaos_budget_max_queue_observed", tonumber(fields.queue) or tonumber(fields.max_queue) or 0)
    runtime_stats.max("chaos_budget_max_projectiles_observed", tonumber(fields.projectiles) or tonumber(fields.launches) or tonumber(fields.launch_count) or 0)
    runtime_stats.max("chaos_budget_max_live_launches_per_tick_observed", tonumber(fields.live_launches_per_tick) or tonumber(fields.live_launches) or 0)
    runtime_stats.max("chaos_budget_max_live_launches_initial_burst_observed", tonumber(fields.live_launches_initial_burst) or tonumber(fields.initial_burst) or 0)
end

return chaos_budget
