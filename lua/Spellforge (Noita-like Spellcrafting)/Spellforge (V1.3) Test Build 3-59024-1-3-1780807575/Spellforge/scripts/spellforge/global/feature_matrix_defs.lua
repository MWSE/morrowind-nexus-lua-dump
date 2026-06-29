---@omw-context global
local limits = require("scripts.spellforge.shared.limits")

local defs = {}

defs.VERSION = "spellforge-feature-matrix-v1"

defs.FLAGS = {
    LIVE_2_2C = "SpellforgeDev.enable_live_2_2c_runtime",
    MULTICAST = "SpellforgeDev.enable_live_multicast",
    SPREAD_BURST = "SpellforgeDev.enable_live_spread_burst",
    TRIGGER = "SpellforgeDev.enable_live_trigger",
    TIMER = "SpellforgeDev.enable_live_timer",
    SPEED_PLUS = "SpellforgeDev.enable_live_speed_plus",
    SIZE_PLUS = "SpellforgeDev.enable_live_size_plus",
    PAYLOAD_MULTICAST = "SpellforgeDev.enable_live_payload_multicast_v0",
    PAYLOAD_PATTERN = "SpellforgeDev.enable_live_payload_pattern_v0",
    NESTED_TRIGGER_TIMER = "SpellforgeDev.enable_live_nested_trigger_timer_v1",
    NESTED_FINAL_FANOUT = "SpellforgeDev.enable_live_nested_final_fanout_v0",
    CHAIN = "SpellforgeDev.enable_live_chain_runtime_v0",
    CHAIN_MULTICAST = "SpellforgeDev.enable_live_chain_multicast_v0",
    BOUNCE = "SpellforgeDev.enable_live_bounce_v0",
    PIERCE = "SpellforgeDev.enable_live_pierce_v0",
    HOMING = "SpellforgeDev.enable_live_homing_v0",
    SOFT_HOMING = "SpellforgeDev.enable_live_soft_homing_v0",
    HOMING_V2_MANAGER = "SpellforgeDev.enable_live_homing_v2_manager",
}

defs.OPCODE_TO_FEATURE = {
    Multicast = "multicast",
    Spread = "spread_burst",
    Burst = "spread_burst",
    ["Speed+"] = "speed_plus",
    ["Size+"] = "size_plus",
    Chain = "chain",
    Bounce = "bounce",
    Pierce = "pierce",
    Homing = "homing",
    Trigger = "trigger",
    Timer = "timer",
}

defs.REASON_CLASSIFICATIONS = {
    bounce_chain_deferred = "future_deferred",
    bounce_chain_modifier_deferred = "future_deferred",
    bounce_fanout_deferred = "future_deferred",
    chain_event_payload_chain_deferred = "unsupported_by_design",
    chain_homing_deferred = "unsupported_by_design",
    chain_modifier_combo_deferred = "future_deferred",
    chain_nested_payload_deferred = "future_deferred",
    chain_pattern_disabled = "unsupported_by_design",
    chain_recursion_deferred = "unsupported_by_design",
    chain_recursion_unsupported = "unsupported_by_design",
    chain_trigger_timer_deferred = "future_deferred",
    cyclic_continuation_unsupported_by_design = "unsupported_by_design",
    depth_exceeded_unsupported_by_design = "unsupported_by_design",
    detonate_modifier_combo_deferred = "future_deferred",
    detonate_nested_continuation_unsupported = "unsupported_by_design",
    detonate_requires_area = "unsupported_by_design",
    detonate_requires_payload_context = "unsupported_by_design",
    detonate_requires_target_range = "unsupported_by_design",
    detonate_sfp_capability_missing = "cap_or_budget_rejected",
    fanout_requires_target_range = "unsupported_by_design",
    homing_bounce_physics_unsupported = "unsupported_by_design",
    homing_chain_targeting_unsupported = "unsupported_by_design",
    homing_nested_runtime_deferred = "future_deferred",
    homing_pierce_physics_unsupported = "unsupported_by_design",
    homing_recursion_unsupported = "unsupported_by_design",
    homing_recursion_unsupported_by_design = "unsupported_by_design",
    homing_soft_high_fanout_deferred = "cap_or_budget_rejected",
    multiple_source_groups_unsupported = "unsupported_by_design",
    nested_depth_exceeded = "unsupported_by_design",
    nested_final_payload_budget_exceeded = "cap_or_budget_rejected",
    nested_homing_recursion_deferred = "unsupported_by_design",
    nested_continuation_budget_exceeded = "cap_or_budget_rejected",
    nested_payload_runtime_deferred = "future_deferred",
    nested_recursion_deferred = "unsupported_by_design",
    nested_recursion_unsupported = "unsupported_by_design",
    payload_modifier_nested_deferred = "future_deferred",
    payload_modifier_pattern_deferred = "future_deferred",
    per_frame_scan_unsupported_by_design = "unsupported_by_design",
    per_projectile_brain_unsupported_by_design = "unsupported_by_design",
    pierce_bounce_deferred = "unsupported_by_design",
    pierce_chain_deferred = "future_deferred",
    pierce_modifier_deferred = "future_deferred",
    pierce_nested_payload_deferred = "future_deferred",
    pierce_recursion_deferred = "unsupported_by_design",
    pierce_repeated_actor_ticks_unsupported_by_design = "unsupported_by_design",
    recursion_unsupported_by_design = "unsupported_by_design",
    source_modifier_chain_deferred = "future_deferred",
    source_modifier_combo_deferred = "future_deferred",
    source_fanout_timer_unsupported = "future_deferred",
    source_fanout_trigger_unsupported = "future_deferred",
    source_modifier_nested_deferred = "future_deferred",
    source_modifier_pattern_deferred = "future_deferred",
}

defs.FEATURE_DEFS = {
    {
        id = "simple_projectile",
        display_name = "Simple projectile",
        category = "core",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C },
        summary = "Compiled helper/orchestrator dispatch for ordinary emitter groups.",
    },
    {
        id = "multicast",
        display_name = "Multicast",
        category = "fanout",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.MULTICAST },
        summary = "Primary Multicast fanout, with payload Multicast covered by its payload gate.",
    },
    {
        id = "spread_burst",
        display_name = "Spread/Burst",
        category = "fanout",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.SPREAD_BURST },
        summary = "Launch-time deterministic pattern directions for Multicast emissions.",
    },
    {
        id = "trigger",
        display_name = "Trigger",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.TRIGGER },
        summary = "Direct Trigger payload routing for conservative payload groups.",
    },
    {
        id = "timer",
        display_name = "Timer",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.TIMER },
        summary = "Direct Timer payload routing through OpenMW simulation timers.",
    },
    {
        id = "payload_multicast",
        display_name = "Payload Multicast",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.PAYLOAD_MULTICAST },
        summary = "Direct Trigger/Timer payload Multicast groups, including Bounce/Pierce-owned Trigger payload fanout.",
    },
    {
        id = "payload_pattern",
        display_name = "Payload Spread/Burst",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.PAYLOAD_MULTICAST, defs.FLAGS.PAYLOAD_PATTERN },
        summary = "Direct Trigger/Timer payload Multicast plus Spread/Burst groups, including Bounce/Pierce-owned Trigger payload patterns.",
    },
    {
        id = "nested_trigger_timer",
        display_name = "Nested Trigger/Timer",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.NESTED_TRIGGER_TIMER },
        summary = "Bounded depth-3 Trigger/Timer chains, including same-kind and mixed-kind nesting.",
    },
    {
        id = "nested_final_fanout",
        display_name = "Nested Final Fanout",
        category = "payload",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.NESTED_FINAL_FANOUT },
        summary = "Bounded final Multicast, pattern, modifier, Homing, or non-recursive Chain payloads after depth-3 Trigger/Timer chains.",
    },
    {
        id = "speed_plus",
        display_name = "Speed+",
        category = "modifier",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.SPEED_PLUS },
        summary = "Launch-time speed mutation.",
    },
    {
        id = "size_plus",
        display_name = "Size+",
        category = "modifier",
        status = "feature_gated",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.SIZE_PLUS },
        summary = "Helper effect area mutation.",
    },
    {
        id = "chain",
        display_name = "Chain",
        category = "targeting",
        status = "feature_gated_narrow",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.CHAIN },
        summary = "Direct and Trigger->Chain payload hops, including bounded Trigger/Timer side continuations and Speed+/Size+ payload modifiers.",
    },
    {
        id = "chain_multicast",
        display_name = "Chain+Multicast",
        category = "targeting",
        status = "feature_gated_narrow",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.CHAIN, defs.FLAGS.CHAIN_MULTICAST },
        summary = "Bounded Multicast and Spread/Burst sibling fanout per Chain hop, including combined Speed+ Size+ policy and Trigger/Timer side continuations, with one Chain continuation claim per hop.",
    },
    {
        id = "bounce",
        display_name = "Bounce",
        category = "targeting",
        status = "feature_gated_narrow",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.BOUNCE },
        summary = "Bounce v0 source projectiles, shared source fanout, Trigger payload fanout, and the narrow Trigger->Chain payload bridge.",
    },
    {
        id = "pierce",
        display_name = "Pierce",
        category = "targeting",
        status = "feature_gated_narrow",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.PIERCE },
        summary = "Pierce v0 source projectiles, shared source fanout, Trigger payload fanout, and the narrow Trigger->Chain payload bridge.",
    },
    {
        id = "homing",
        display_name = "Homing",
        category = "targeting",
        status = "feature_gated_narrow",
        gates = { defs.FLAGS.LIVE_2_2C, defs.FLAGS.HOMING },
        optional_gates = { defs.FLAGS.HOMING_V2_MANAGER, defs.FLAGS.SOFT_HOMING },
        summary = "Launch-time Homing composition for bounded source and Trigger/Timer payload launch surfaces, with optional central Homing v2 manager steering.",
    },
}

defs.FEATURE_BY_ID = {}
for _, def in ipairs(defs.FEATURE_DEFS) do
    defs.FEATURE_BY_ID[def.id] = def
end

function defs.cloneArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

function defs.sortedKeys(set)
    local keys = {}
    for key in pairs(set or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function defs.addSet(set, key)
    if key ~= nil and key ~= "" then
        set[key] = true
    end
end

function defs.addAll(set, values)
    for _, value in ipairs(values or {}) do
        defs.addSet(set, value)
    end
end

function defs.buildFeatureEntry(feature_id, summary)
    local active_summary = summary or {}
    local def = defs.FEATURE_BY_ID[feature_id] or {
        id = feature_id,
        display_name = feature_id,
        category = "unknown",
        status = "unknown",
        gates = {},
        optional_gates = {},
        summary = "",
    }

    return {
        id = def.id,
        display_name = def.display_name,
        category = def.category,
        status = def.status,
        active = active_summary.active and active_summary.active[feature_id] == true or false,
        gates = defs.cloneArray(def.gates),
        optional_gates = defs.cloneArray(def.optional_gates),
        count = active_summary.counts and active_summary.counts[feature_id] or 0,
        min_payload_depth = active_summary.min_depth and active_summary.min_depth[feature_id] or nil,
        summary = def.summary,
    }
end

function defs.collectRequiredFlags(active_features)
    local set = {}
    defs.addSet(set, defs.FLAGS.LIVE_2_2C)
    for _, feature_id in ipairs(active_features or {}) do
        local def = defs.FEATURE_BY_ID[feature_id]
        if def then
            defs.addAll(set, def.gates)
        end
    end
    return defs.sortedKeys(set)
end

function defs.classifyReason(reason)
    local key = tostring(reason or "")
    local explicit = defs.REASON_CLASSIFICATIONS[key]
    if explicit then
        return explicit
    end
    if string.find(key, "cap_exceeded", 1, true)
        or string.find(key, "budget_exceeded", 1, true) then
        return "cap_or_budget_rejected"
    end
    if string.find(key, "disabled", 1, true) then
        return "gate_disabled"
    end
    if string.find(key, "fallback", 1, true)
        or string.find(key, "mismatch", 1, true)
        or string.find(key, "parse_failed", 1, true)
        or string.find(key, "internal", 1, true) then
        return "internal_error"
    end
    if string.find(key, "unsupported", 1, true) then
        return "unsupported_by_design"
    end
    if key == "" then
        return "feature_gated"
    end
    return "future_deferred"
end

function defs.classifyReasons(reasons)
    local by_class = {
        feature_gated = {},
        unsupported_by_design = {},
        future_deferred = {},
        cap_or_budget_rejected = {},
        gate_disabled = {},
        internal_error = {},
    }
    local counts = {
        feature_gated = 0,
        unsupported_by_design = 0,
        future_deferred = 0,
        cap_or_budget_rejected = 0,
        gate_disabled = 0,
        internal_error = 0,
    }
    if #(reasons or {}) == 0 then
        counts.feature_gated = 1
        return {
            by_class = by_class,
            counts = counts,
            unsupported_by_design = {},
            future_deferred = {},
            cap_or_budget_rejected = {},
            gate_disabled = {},
            internal_error = {},
        }
    end
    for _, reason in ipairs(reasons or {}) do
        local class = defs.classifyReason(reason)
        if by_class[class] == nil then
            class = "future_deferred"
        end
        by_class[class][#by_class[class] + 1] = reason
        counts[class] = (counts[class] or 0) + 1
    end
    for _, values in pairs(by_class) do
        table.sort(values)
    end
    return {
        by_class = by_class,
        counts = counts,
        unsupported_by_design = by_class.unsupported_by_design,
        future_deferred = by_class.future_deferred,
        cap_or_budget_rejected = by_class.cap_or_budget_rejected,
        gate_disabled = by_class.gate_disabled,
        internal_error = by_class.internal_error,
    }
end

function defs.optionalFlags()
    return { defs.FLAGS.HOMING_V2_MANAGER, defs.FLAGS.SOFT_HOMING }
end

function defs.limitReport()
    return {
        max_projectiles_per_cast = limits.MAX_PROJECTILES_PER_CAST,
        max_payload_fanout = limits.MAX_PAYLOAD_FANOUT,
        max_chain_hops = limits.MAX_CHAIN_HOPS,
        max_chain_multicast_fanout = limits.MAX_CHAIN_MULTICAST_FANOUT,
        max_chain_pattern_fanout = limits.MAX_CHAIN_PATTERN_FANOUT,
        max_chain_pattern_jobs_per_cast = limits.MAX_CHAIN_PATTERN_JOBS_PER_CAST_DEFAULT,
        max_bounce_count = limits.MAX_BOUNCE_COUNT,
        max_pierce_count = limits.MAX_PIERCE_COUNT,
        max_nested_payload_depth = limits.MAX_NESTED_PAYLOAD_DEPTH,
        max_live_nested_continuation_depth = limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH,
        max_nested_continuation_jobs_per_cast = limits.MAX_NESTED_CONTINUATION_JOBS_PER_CAST,
        max_nested_final_payload_jobs_per_cast = limits.MAX_NESTED_FINAL_PAYLOAD_JOBS_PER_CAST,
        max_event_source_resumes_per_cast = limits.MAX_EVENT_SOURCE_RESUMES_PER_CAST,
        max_event_source_timer_jobs_per_cast = limits.MAX_EVENT_SOURCE_TIMER_JOBS_PER_CAST,
        max_bounce_payload_jobs_per_cast = limits.MAX_BOUNCE_PAYLOAD_JOBS_PER_CAST,
        max_pierce_payload_jobs_per_cast = limits.MAX_PIERCE_PAYLOAD_JOBS_PER_CAST,
        max_chain_event_continuation_jobs_per_cast = limits.MAX_CHAIN_EVENT_CONTINUATION_JOBS_PER_CAST,
        max_chain_trigger_side_payload_jobs_per_cast = limits.MAX_CHAIN_TRIGGER_SIDE_PAYLOAD_JOBS_PER_CAST,
        max_chain_timer_side_payload_jobs_per_cast = limits.MAX_CHAIN_TIMER_SIDE_PAYLOAD_JOBS_PER_CAST,
        max_homing_fanout_per_cast = limits.MAX_HOMING_FANOUT_PER_CAST,
        max_homing_target_scans_per_cast = limits.MAX_HOMING_TARGET_SCANS_PER_CAST,
        max_soft_homing_registrations_per_cast = limits.MAX_SOFT_HOMING_REGISTRATIONS_PER_CAST,
        max_homing_state_requests_per_tick = limits.MAX_HOMING_STATE_REQUESTS_PER_TICK,
        max_homing_redirects_per_projectile = limits.HOMING_MAX_REDIRECTS_PER_PROJECTILE,
        max_homing_retargets_per_projectile = limits.HOMING_MAX_RETARGETS_PER_PROJECTILE,
    }
end

function defs.catalog()
    local out = {}
    local empty_summary = {
        active = {},
        counts = {},
        min_depth = {},
    }
    for i, def in ipairs(defs.FEATURE_DEFS) do
        out[i] = defs.buildFeatureEntry(def.id, empty_summary)
    end
    return out
end

return defs
