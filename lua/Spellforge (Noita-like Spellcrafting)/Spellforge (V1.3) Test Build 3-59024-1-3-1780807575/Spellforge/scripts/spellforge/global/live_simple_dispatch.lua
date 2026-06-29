---@omw-context global
local dev = require("scripts.spellforge.shared.dev")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local log = require("scripts.spellforge.shared.log").new("global.live_simple_dispatch")
local limits = require("scripts.spellforge.shared.limits")
local helper_records = require("scripts.spellforge.global.helper_records")
local ir_runtime_adapter = require("scripts.spellforge.global.ir_runtime_adapter")
local homing_launch_policy = require("scripts.spellforge.global.homing_launch_policy")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local payload_multicast = require("scripts.spellforge.global.payload_multicast")
local patterns = require("scripts.spellforge.global.patterns")
local plan_cache = require("scripts.spellforge.global.plan_cache")
local nested_payload_audit = require("scripts.spellforge.global.nested_payload_audit")
local nested_trigger_timer = require("scripts.spellforge.global.nested_trigger_timer")
local chain_target_provider = require("scripts.spellforge.global.chain_target_provider")
local chain_targeting = require("scripts.spellforge.global.chain_targeting")
local chaos_budget = require("scripts.spellforge.global.chaos_budget")
local live_bounce = require("scripts.spellforge.global.live_bounce")
local live_chain = require("scripts.spellforge.global.live_chain")
local live_pierce = require("scripts.spellforge.global.live_pierce")
local live_size_plus = require("scripts.spellforge.global.live_size_plus")
local live_speed_plus = require("scripts.spellforge.global.live_speed_plus")
local live_timer = require("scripts.spellforge.global.live_timer")
local live_trigger = require("scripts.spellforge.global.live_trigger")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")
local util = require("openmw.util")

local live_simple_dispatch = {}
live_simple_dispatch.PAYLOAD_HOMING_SYNTHETIC_TRIGGER_DELAY_SECONDS = 0.35
live_simple_dispatch._seen_cast_ids = {}
local next_live_cast_index = 1
local PRESENTATION_METADATA_FIELDS = {
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
}
local function cloneParams(params)
    local out = {}
    if type(params) ~= "table" then
        return out
    end
    local keys = {}
    for key in pairs(params) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        out[key] = params[key]
    end
    return out
end

local function cloneEffect(effect)
    if type(effect) ~= "table" then
        return { id = tostring(effect) }
    end
    local out = {
        id = effect.id,
        engine_effect_id = effect.engine_effect_id,
        range = effect.range,
        area = effect.area,
        duration = effect.duration,
        magnitudeMin = effect.magnitudeMin,
        magnitudeMax = effect.magnitudeMax,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
        params = cloneParams(effect.params),
    }
    for _, field in ipairs(PRESENTATION_METADATA_FIELDS) do
        if effect[field] ~= nil then
            out[field] = effect[field]
        end
    end
    return out
end

local function cloneEffects(effects)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        out[i] = cloneEffect(effect)
    end
    return out
end

local function firstErrorMessage(result)
    local first = result and result.errors and result.errors[1]
    return first and first.message or (result and result.error) or "unknown error"
end

local function firstPresent(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function slotById(slots)
    local by_id = {}
    for _, slot in ipairs(slots or {}) do
        if slot and slot.slot_id then
            by_id[slot.slot_id] = slot
        end
    end
    return by_id
end

local function slotPayloadDepth(slot, slots_by_id, memo)
    if not slot then
        return 0
    end
    if tonumber(slot.payload_depth) ~= nil then
        return tonumber(slot.payload_depth) or 0
    end
    local slot_id = slot.slot_id
    if slot_id and memo[slot_id] ~= nil then
        return memo[slot_id]
    end
    local depth = 0
    if slot.parent_slot_id ~= nil then
        depth = slotPayloadDepth(slots_by_id[slot.parent_slot_id], slots_by_id, memo) + 1
    end
    if slot_id then
        memo[slot_id] = depth
    end
    return depth
end

local function planNestedDepth(plan)
    local slots = plan and plan.emission_slots or {}
    local slots_by_id = slotById(slots)
    local memo = {}
    local max_depth = 0
    for _, slot in ipairs(slots) do
        local depth = slotPayloadDepth(slot, slots_by_id, memo)
        if depth > max_depth then
            max_depth = depth
        end
    end
    return max_depth
end

local function bounceDetonateOnActorHit(job, payload)
    if job == nil then
        return nil
    end
    return firstPresent(
        job.detonateOnActorHit,
        payload and payload.detonateOnActorHit,
        job.bounce_detonate_on_actor_hit,
        payload and payload.bounce_detonate_on_actor_hit
    )
end

local function fallback(reason, details)
    local result = details or {}
    result.ok = false
    result.used_live_2_2c = false
    result.fallback_allowed = true
    result.fallback_reason = reason
    return result
end

local function isLaunchJobFailure(details)
    return type(details) == "table"
        and type(details.stage) == "string"
        and string.find(details.stage, "launch_job", 1, true) ~= nil
end

local function launchJobFailureMessage(message, details)
    local tick_result = type(details) == "table" and details.tick_result or nil
    return string.format(
        "%s job_status=%s job_id=%s slot_id=%s helper_engine_id=%s tick_result.live_launches_this_update=%s max_live_launches_per_tick=%s live_launch_throttled_count=%s remaining_count=%s",
        tostring(message),
        tostring(details and details.job_status),
        tostring(details and details.job_id),
        tostring(details and details.slot_id),
        tostring(details and details.helper_engine_id),
        tostring(tick_result and tick_result.live_launches_this_update),
        tostring((tick_result and tick_result.max_live_launches_per_tick) or (details and details.max_live_launches_per_tick)),
        tostring(tick_result and tick_result.live_launch_throttled_count),
        tostring((tick_result and tick_result.remaining_count) or (details and details.remaining_count))
    )
end

local function bridgeError(message, details)
    local result = details or {}
    local error_message = message
    if isLaunchJobFailure(result) then
        error_message = launchJobFailureMessage(message, result)
        log.error(string.format(
            "SPELLFORGE_LIVE_SIMPLE_DISPATCH_LAUNCH_JOB_FAILED stage=%s %s",
            tostring(result.stage),
            tostring(error_message)
        ))
    end
    result.ok = false
    result.used_live_2_2c = true
    result.fallback_allowed = result.fallback_allowed == true
    result.error = error_message
    return result
end

local function nextCastId(recipe_id, plan_recipe_id)
    local cast_id = string.format(
        "live_2_2c:%s:%s:%d",
        tostring(recipe_id),
        tostring(plan_recipe_id),
        next_live_cast_index
    )
    next_live_cast_index = next_live_cast_index + 1
    if live_simple_dispatch._seen_cast_ids[cast_id] then
        runtime_stats.inc("cast_ids_reused_unexpectedly")
    end
    live_simple_dispatch._seen_cast_ids[cast_id] = true
    runtime_stats.inc("cast_ids_created")
    return cast_id
end

local function rejected(reason, details)
    runtime_stats.inc("live_2_2c_rejected")
    return fallback(reason, details)
end

local function sourceModifierPolicySourceEntry(plan)
    local source = nil
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" and slot.parent_slot_id == nil then
            if source ~= nil then
                return nil, "multiple_source_slots"
            end
            source = slot
        end
    end
    if source == nil then
        return nil, "missing_source_slot"
    end
    return source, nil
end

local function isTargetRange(range)
    return range == 2 or range == "target" or range == "Target"
end

local function isSelfRange(range)
    return range == 0 or range == "self" or range == "Self"
end

local function groupAllowsSelfSummonMulticast(group, bounds)
    if type(group) ~= "table" or type(bounds) ~= "table" then
        return false
    end
    if bounds.has_multicast ~= true or bounds.has_pattern == true then
        return false
    end
    if not isSelfRange(group.range) then
        return false
    end
    if type(group.effects) ~= "table" or #group.effects == 0 then
        return false
    end
    for _, effect in ipairs(group.effects) do
        if not effect_registry.isSummonEffect(effect) then
            return false
        end
    end
    return true
end

local function countSummonEffects(effects)
    local count = 0
    for _, effect in ipairs(effects or {}) do
        if effect_registry.isSummonEffect(effect) then
            count = count + 1
        else
            return 0
        end
    end
    return count
end

local function groupAllowsSelfSummonSourceFanout(group, bounds)
    if type(group) ~= "table" or type(bounds) ~= "table" then
        return false
    end
    if bounds.has_multicast == true or bounds.has_pattern == true then
        return false
    end
    if not isSelfRange(group.range) then
        return false
    end
    return countSummonEffects(group.effects) > 1
end

local function isSingleStoredNode(entry)
    return type(entry) == "table"
        and type(entry.node_metadata) == "table"
        and #entry.node_metadata == 1
end

local function multicastRejected(reason, details, counter_name)
    runtime_stats.inc("live_multicast_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function isPatternMode(mode)
    return mode == "spread" or mode == "burst"
end

local function isFanoutMode(mode)
    return mode == "multicast" or isPatternMode(mode)
end

local function patternModeForKind(pattern_kind)
    if pattern_kind == "Spread" then
        return "spread"
    elseif pattern_kind == "Burst" then
        return "burst"
    end
    return nil
end

local function patternRejected(pattern_kind, reason, details, counter_name)
    if pattern_kind == "Spread" then
        runtime_stats.inc("live_spread_rejected")
    elseif pattern_kind == "Burst" then
        runtime_stats.inc("live_burst_rejected")
    end
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function triggerRejected(reason, details, counter_name)
    runtime_stats.inc("live_trigger_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function timerRejected(reason, details, counter_name)
    runtime_stats.inc("live_timer_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function chainRuntimeRejected(reason, details, counter_name)
    runtime_stats.inc("chain_runtime_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    log.info(string.format(
        "SPELLFORGE_CHAIN_RUNTIME_REJECTED reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s",
        tostring(reason),
        tostring(details and details.plan_recipe_id or nil),
        tostring(details and details.source_slot_id or nil),
        tostring(details and details.payload_slot_id or nil),
        tostring(details and details.requested_hops or nil),
        tostring(details and details.max_hops or nil)
    ))
    return rejected(reason, details)
end

local function bounceRejected(reason, details, counter_name)
    runtime_stats.inc("live_bounce_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_REJECTED reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s bounce_max=%s",
        tostring(reason),
        tostring(details and details.plan_recipe_id or nil),
        tostring(details and details.source_slot_id or nil),
        tostring(details and details.payload_slot_id or nil),
        tostring(details and details.bounce_max or nil)
    ))
    return rejected(reason, details)
end

local function pierceRejected(reason, details, counter_name)
    runtime_stats.inc("live_pierce_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    log.info(string.format(
        "SPELLFORGE_PIERCE_DEFERRED reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s pierce_limit=%s",
        tostring(reason),
        tostring(details and details.plan_recipe_id or nil),
        tostring(details and details.source_slot_id or nil),
        tostring(details and details.payload_slot_id or nil),
        tostring(details and details.pierce_limit or nil)
    ))
    return rejected(reason, details)
end

local function nestedTriggerTimerRejected(reason, details, counter_name)
    local result = details or {}
    result.nested_trigger_timer_rejected = true
    result.rejection_reason = result.rejection_reason or reason
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    log.info(string.format(
        "SPELLFORGE_NESTED_TRIGGER_TIMER_REJECTED reason=%s plan_recipe_id=%s root_source_slot_id=%s intermediate_slot_id=%s final_payload_slot_id=%s root_stage_kind=%s intermediate_stage_kind=%s max_payload_depth=%s has_trigger_payload=%s has_timer_payload=%s has_multicast_payload=%s has_pattern_payload=%s has_chain=%s",
        tostring(reason),
        tostring(result.plan_recipe_id),
        tostring(result.root_source_slot_id),
        tostring(result.intermediate_slot_id),
        tostring(result.final_payload_slot_id),
        tostring(result.root_stage_kind),
        tostring(result.intermediate_stage_kind),
        tostring(result.max_payload_depth),
        tostring(result.has_trigger_payload),
        tostring(result.has_timer_payload),
        tostring(result.has_multicast_payload),
        tostring(result.has_pattern_payload),
        tostring(result.has_chain)
    ))
    if string.find(tostring(reason), "nested_final_fanout", 1, true)
        or result.has_multicast_payload == true
        or result.has_pattern_payload == true then
        log.info(string.format(
            "SPELLFORGE_NESTED_FINAL_FANOUT_REJECTED reason=%s plan_recipe_id=%s root_source_slot_id=%s intermediate_slot_id=%s final_payload_slot_id=%s max_payload_depth=%s has_multicast_payload=%s has_pattern_payload=%s",
            tostring(reason),
            tostring(result.plan_recipe_id),
            tostring(result.root_source_slot_id),
            tostring(result.intermediate_slot_id),
            tostring(result.final_payload_slot_id),
            tostring(result.max_payload_depth),
            tostring(result.has_multicast_payload),
            tostring(result.has_pattern_payload)
        ))
    end
    return rejected(reason, result)
end

local function speedPlusRejected(reason, details, counter_name)
    runtime_stats.inc("live_speed_plus_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function sizePlusRejected(reason, details, counter_name)
    runtime_stats.inc("live_size_plus_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function homingRejected(reason, details, counter_name)
    runtime_stats.inc("live_homing_rejected")
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function payloadMulticastRuntimeEnabled(options)
    if options.force_payload_multicast_disabled == true then
        return false
    end
    return options.force_payload_multicast_enabled == true or dev.livePayloadMulticastEnabled()
end

local function payloadPatternRuntimeEnabled(options)
    if options.force_payload_pattern_disabled == true then
        return false
    end
    return options.force_payload_pattern_enabled == true or dev.livePayloadPatternEnabled()
end

local function nestedTriggerTimerRuntimeEnabled(options)
    if options.force_nested_trigger_timer_disabled == true then
        return false
    end
    return options.force_nested_trigger_timer_enabled == true or dev.liveNestedTriggerTimerEnabled()
end

local function nestedFinalFanoutRuntimeEnabled(options)
    if options.force_nested_final_fanout_disabled == true then
        return false
    end
    return options.force_nested_final_fanout_enabled == true or dev.liveNestedFinalFanoutEnabled()
end

local function addNestedTriggerTimerDiagnostics(details, plan)
    local out = details or {}
    local shape = nested_trigger_timer.inspectShape(plan)
    for key, value in pairs(shape or {}) do
        if out[key] == nil then
            out[key] = value
        end
    end
    return out
end

local function patternAttempt(pattern_kind)
    if pattern_kind == "Spread" then
        runtime_stats.inc("live_spread_attempts")
    elseif pattern_kind == "Burst" then
        runtime_stats.inc("live_burst_attempts")
    end
end

local function patternQualified(pattern_kind, emission_count)
    if pattern_kind == "Spread" then
        runtime_stats.inc("live_spread_qualified")
        runtime_stats.inc("live_spread_emissions_planned", emission_count)
    elseif pattern_kind == "Burst" then
        runtime_stats.inc("live_burst_qualified")
        runtime_stats.inc("live_burst_emissions_planned", emission_count)
    end
end

local function prefixLiveShape(prefix_ops)
    local saw_multicast = false
    local pattern_kind = nil
    local pattern_op = nil
    for _, op in ipairs(prefix_ops or {}) do
        if op.opcode == "Multicast" then
            saw_multicast = true
        elseif op.opcode == "Spread" or op.opcode == "Burst" then
            if pattern_kind ~= nil then
                return false, "ambiguous_pattern", pattern_kind, pattern_op
            end
            pattern_kind = op.opcode
            pattern_op = op
        else
            return false, string.format("unsupported_prefix_%s", tostring(op.opcode))
        end
    end
    if pattern_kind ~= nil and not saw_multicast then
        return false, "pattern_without_multicast", pattern_kind, pattern_op
    end
    if pattern_kind ~= nil then
        return true, string.lower(pattern_kind) .. "_primary", pattern_kind, pattern_op
    end
    return true, saw_multicast and "multicast_primary" or nil, nil, nil
end

local function estimateFirstGroupOperators(effects)
    local info = {
        multicast_count = 1,
        has_multicast = false,
        has_spread = false,
        has_burst = false,
        pattern_kind = nil,
        ambiguous_pattern = false,
    }
    for _, effect in ipairs(effects or {}) do
        local id = effect and effect.id and string.lower(tostring(effect.id)) or nil
        if id == "spellforge_multicast" then
            info.has_multicast = true
            info.multicast_count = info.multicast_count * (tonumber(effect.params and effect.params.count) or 1)
        elseif id == "spellforge_spread" then
            info.has_spread = true
            if info.pattern_kind ~= nil then
                info.ambiguous_pattern = true
            end
            info.pattern_kind = info.pattern_kind or "Spread"
        elseif id == "spellforge_burst" then
            info.has_burst = true
            if info.pattern_kind ~= nil then
                info.ambiguous_pattern = true
            end
            info.pattern_kind = info.pattern_kind or "Burst"
        elseif id and string.sub(id, 1, 11) == "spellforge_" then
            -- Other operators are validated by the parser/plan checks.
        elseif effect ~= nil then
            return info
        end
    end
    return info
end

local function effectListHasOperator(effects, opcode)
    local wanted = opcode == "Timer" and "spellforge_timer"
        or opcode == "Trigger" and "spellforge_trigger"
        or opcode == "Chain" and "spellforge_chain"
        or opcode == "Bounce" and "spellforge_bounce"
        or opcode == "Pierce" and "spellforge_pierce"
        or opcode == "Speed+" and "spellforge_speed_plus"
        or opcode == "Size+" and "spellforge_size_plus"
        or opcode == "Homing" and "spellforge_homing"
        or opcode == "Detonate" and "spellforge_detonate"
        or nil
    if not wanted then
        return false
    end
    for _, effect in ipairs(effects or {}) do
        local id = effect and effect.id and string.lower(tostring(effect.id)) or nil
        if id == wanted then
            return true
        end
    end
    return false
end

local function errorsMentionTimerDelay(errors)
    for _, err in ipairs(errors or {}) do
        local message = err and err.message and tostring(err.message) or ""
        if string.find(message, "Timer.seconds", 1, true) ~= nil
            or string.find(message, "Missing parameter seconds for Timer", 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function errorsMentionSpeedPlusValue(errors)
    for _, err in ipairs(errors or {}) do
        local message = err and err.message and tostring(err.message) or ""
        if string.find(message, "Speed+.percent", 1, true) ~= nil
            or string.find(message, "Missing parameter percent for Speed+", 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function errorsMentionSizePlusValue(errors)
    for _, err in ipairs(errors or {}) do
        local message = err and err.message and tostring(err.message) or ""
        if string.find(message, "Size+.percent", 1, true) ~= nil
            or string.find(message, "Missing parameter percent for Size+", 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function validateLivePrimaryPlan(plan, opts)
    local options = opts or {}
    local projectile_cap = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    local fanout_cap = tonumber(options.max_payload_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    if type(plan) ~= "table" then
        return false, "missing_plan"
    end
    local bounds = plan.bounds or {}
    if bounds.group_count ~= 1 then
        return false, tonumber(bounds.group_count) and tonumber(bounds.group_count) > 1
            and "multiple_source_groups_unsupported"
            or "not_single_group"
    end
    local static_emission_count = tonumber(bounds.static_emission_count) or 0
    if static_emission_count < 1 then
        return false, "no_static_emissions"
    end
    if bounds.has_trigger then
        if bounds.has_pattern then
            return false, "has_trigger", "pattern", "live_pattern_unsupported_opcode_rejections"
        elseif bounds.has_multicast then
            return false, "has_trigger", "multicast", "live_multicast_unsupported_opcode_rejections"
        end
        return false, "has_trigger"
    end
    if bounds.has_timer then
        if bounds.has_pattern then
            return false, "has_timer", "pattern", "live_pattern_unsupported_opcode_rejections"
        elseif bounds.has_multicast then
            return false, "has_timer", "multicast", "live_multicast_unsupported_opcode_rejections"
        end
        return false, "has_timer"
    end
    if bounds.has_chain then
        if bounds.has_pattern then
            return false, "has_chain", "pattern", "live_pattern_unsupported_opcode_rejections"
        elseif bounds.has_multicast then
            return false, "has_chain", "multicast", "live_multicast_unsupported_opcode_rejections"
        end
        return false, "has_chain"
    end

    local group = plan.groups and plan.groups[1] or nil
    if type(group) ~= "table" then
        return false, "missing_group"
    end
    local allows_self_summon_multicast = groupAllowsSelfSummonMulticast(group, bounds)
    local allows_self_summon_source_fanout = groupAllowsSelfSummonSourceFanout(group, bounds)
    if not isTargetRange(group.range)
        and not allows_self_summon_multicast
        and not allows_self_summon_source_fanout then
        if bounds.has_pattern then
            return false, "fanout_requires_target_range", "pattern"
        elseif bounds.has_multicast then
            return false, "fanout_requires_target_range", "multicast"
        end
        return false, "not_target_range"
    end
    if type(group.effects) ~= "table" or #group.effects == 0 then
        return false, "missing_emitter_effects"
    end
    if type(group.postfix_ops) == "table" and #group.postfix_ops > 0 then
        if bounds.has_pattern then
            return false, "has_postfix_ops", "pattern", "live_pattern_payload_rejections"
        elseif bounds.has_multicast then
            return false, "has_postfix_ops", "multicast", "live_multicast_payload_rejections"
        end
        return false, "has_postfix_ops"
    end
    if group.payload ~= nil then
        if bounds.has_pattern then
            return false, "has_payload", "pattern", "live_pattern_payload_rejections"
        elseif bounds.has_multicast then
            return false, "has_payload", "multicast", "live_multicast_payload_rejections"
        end
        return false, "has_payload"
    end

    local prefix_ok, prefix_note, pattern_kind, pattern_op = prefixLiveShape(group.prefix_ops)
    if not prefix_ok then
        if pattern_kind ~= nil or bounds.has_pattern then
            return false, prefix_note, patternModeForKind(pattern_kind) or "pattern", "live_pattern_unsupported_opcode_rejections", pattern_kind, pattern_op
        elseif bounds.has_multicast then
            return false, prefix_note, "multicast", "live_multicast_unsupported_opcode_rejections"
        end
        return false, prefix_note
    end

    local emission_count = tonumber(bounds.static_emission_count or group.emission_count_static) or 1
    if allows_self_summon_source_fanout then
        emission_count = math.max(emission_count, countSummonEffects(group.effects))
    end
    if emission_count > projectile_cap then
        chaos_budget.recordReject("projectile_cap_exceeded", "projectile")
        if pattern_kind ~= nil or bounds.has_pattern then
            return false, "pattern_cap_exceeded", patternModeForKind(pattern_kind) or "pattern", "live_multicast_cap_rejections", pattern_kind, pattern_op
        elseif bounds.has_multicast then
            return false, "multicast_cap_exceeded", "multicast", "live_multicast_cap_rejections"
        end
        return false, "projectile_cap_exceeded"
    end

    local is_multicast = (bounds.has_multicast and emission_count > 1)
        or (allows_self_summon_source_fanout and emission_count > 1)
    if is_multicast and emission_count > fanout_cap then
        chaos_budget.recordReject("multicast_fanout_cap_exceeded", "fanout")
        if pattern_kind ~= nil or bounds.has_pattern then
            return false, "pattern_cap_exceeded", patternModeForKind(pattern_kind) or "pattern", "live_multicast_cap_rejections", pattern_kind, pattern_op
        end
        return false, "multicast_cap_exceeded", "multicast", "live_multicast_cap_rejections"
    end
    if pattern_kind ~= nil then
        if not is_multicast then
            return false, "pattern_fanout_missing", patternModeForKind(pattern_kind), "live_pattern_unsupported_opcode_rejections", pattern_kind, pattern_op
        end
        if options.force_multicast_disabled == true then
            return false, "live_multicast_disabled", patternModeForKind(pattern_kind), nil, pattern_kind, pattern_op
        end
        if options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled() then
            return false, "live_multicast_disabled", patternModeForKind(pattern_kind), nil, pattern_kind, pattern_op
        end
        if options.force_pattern_disabled == true then
            return false, "live_spread_burst_disabled", patternModeForKind(pattern_kind), nil, pattern_kind, pattern_op
        end
        if options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled() then
            return false, "live_spread_burst_disabled", patternModeForKind(pattern_kind), nil, pattern_kind, pattern_op
        end
        return true, prefix_note, patternModeForKind(pattern_kind), emission_count, pattern_kind, pattern_op
    end

    if bounds.has_pattern then
        return false, "has_pattern", "pattern", "live_pattern_unsupported_opcode_rejections"
    end

    if is_multicast then
        if options.force_multicast_disabled == true then
            return false, "live_multicast_disabled", "multicast"
        end
        if options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled() then
            return false, "live_multicast_disabled", "multicast"
        end
        return true, "multicast_primary", "multicast", emission_count
    end

    return true, prefix_note, "single", emission_count
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

local function hasPayloadBindings(value)
    return type(value) == "table" and #value > 0
end

local function collectPrimaryHelpers(plan, opts)
    local options = opts or {}
    local projectile_cap = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if type(plan.emission_slots) ~= "table" or #plan.emission_slots == 0 then
        return nil, "slot_count_zero"
    end
    if type(plan.helper_records) ~= "table" or #plan.helper_records == 0 then
        return nil, "helper_record_count_zero"
    end

    local helpers_by_slot = helperBySlotId(plan.helper_records)
    local selected = {}
    for _, slot in ipairs(plan.emission_slots) do
        if slot.kind ~= "primary_emission" then
            return nil, "slot_not_primary"
        end
        if slot.parent_slot_id ~= nil then
            return nil, "slot_has_parent"
        end
        if slot.source_postfix_opcode ~= nil or slot.trigger_source_slot_id ~= nil or slot.timer_source_slot_id ~= nil then
            return nil, "slot_has_source_postfix"
        end
        if hasPayloadBindings(slot.payload_bindings) then
            return nil, "slot_has_payload_bindings"
        end
        if type(slot.postfix_ops) == "table" and #slot.postfix_ops > 0 then
            return nil, "slot_has_postfix_ops"
        end

        local helper = helpers_by_slot[slot.slot_id]
        if not helper then
            return nil, "helper_missing_for_slot"
        end
        if type(helper.engine_id) ~= "string" or helper.engine_id == "" then
            return nil, "helper_engine_id_missing"
        end
        if helper.parent_slot_id ~= nil then
            return nil, "helper_has_parent"
        end
        if helper.source_postfix_opcode ~= nil or helper.trigger_source_slot_id ~= nil or helper.timer_source_slot_id ~= nil then
            return nil, "helper_is_payload"
        end
        if hasPayloadBindings(helper.payload_bindings) then
            return nil, "helper_has_payload_bindings"
        end

        selected[#selected + 1] = {
            slot = slot,
            helper = helper,
        }
    end

    if #selected ~= #plan.helper_records then
        return nil, "helper_record_count_mismatch"
    end
    if #selected > projectile_cap then
        return nil, "multicast_cap_exceeded"
    end

    return selected, nil
end

local function countPrefixOpcode(entry, opcode)
    local count = 0
    local first = nil
    for _, op in ipairs(entry and entry.prefix_ops or {}) do
        if op and op.opcode == opcode then
            count = count + 1
            first = first or op
        end
    end
    return count, first
end

local function hasPrefixOpcode(entry, opcode)
    return countPrefixOpcode(entry, opcode) > 0
end

local function hasTriggerPostfix(entry)
    local ops = entry and entry.postfix_ops or {}
    return #ops == 1 and ops[1] and ops[1].opcode == "Trigger"
end

local function hasTimerPostfix(entry)
    local ops = entry and entry.postfix_ops or {}
    return #ops == 1 and ops[1] and ops[1].opcode == "Timer"
end

local function hasPostfixOpcodeOnly(entry, opcode)
    if opcode == "Trigger" then
        return hasTriggerPostfix(entry)
    elseif opcode == "Timer" then
        return hasTimerPostfix(entry)
    end
    return false
end

local function hasUnsupportedPostfix(entry, allowed_opcode)
    local ops = entry and entry.postfix_ops or {}
    if #ops == 0 then
        return false
    end
    return not (#ops == 1 and ops[1] and ops[1].opcode == (allowed_opcode or "Trigger"))
end

local function collectEventSourceFanoutHelpers(plan, source_kind, opts)
    local options = opts or {}
    local projectile_cap = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    local continuation_kind = options.continuation_kind or "Trigger"
    local source_opcode = source_kind == "bounce" and "Bounce" or source_kind == "pierce" and "Pierce" or nil
    if source_opcode == nil then
        return nil, "event_source_fanout_unsupported"
    end
    if type(plan.emission_slots) ~= "table" or #plan.emission_slots == 0 then
        return nil, "slot_count_zero"
    end
    if type(plan.helper_records) ~= "table" or #plan.helper_records == 0 then
        return nil, "helper_record_count_zero"
    end

    local helpers_by_slot = helperBySlotId(plan.helper_records)
    local selected = {}
    local continuation_count = 0
    for _, slot in ipairs(plan.emission_slots) do
        if slot.kind == "primary_emission" then
            if slot.parent_slot_id ~= nil or slot.source_postfix_opcode ~= nil then
                return nil, "source_slot_not_primary"
            end
            if hasUnsupportedPostfix(slot, continuation_kind) then
                return nil, source_kind .. "_timer_deferred"
            end
            local source_count = countPrefixOpcode(slot, source_opcode)
            if source_count ~= 1 then
                return nil, "source_slot_not_" .. source_kind
            end
            if source_kind == "bounce" and hasPrefixOpcode(slot, "Pierce") then
                return nil, "pierce_bounce_deferred"
            end
            if source_kind == "pierce" and hasPrefixOpcode(slot, "Bounce") then
                return nil, "pierce_bounce_deferred"
            end
            if hasPrefixOpcode(slot, "Timer") or hasPrefixOpcode(slot, "Homing") or hasPrefixOpcode(slot, "Chain") then
                if hasPrefixOpcode(slot, "Homing") then
                    return nil, source_kind .. "_homing_deferred"
                elseif hasPrefixOpcode(slot, "Chain") then
                    return nil, source_kind .. "_chain_deferred"
                end
                return nil, source_kind .. "_timer_deferred"
            end

            local helper = helpers_by_slot[slot.slot_id]
            if not helper or type(helper.engine_id) ~= "string" or helper.engine_id == "" then
                return nil, "source_helper_missing"
            end
            if helper.parent_slot_id ~= nil or helper.source_postfix_opcode ~= nil then
                return nil, "source_helper_not_primary"
            end
            if hasUnsupportedPostfix(helper, continuation_kind) then
                return nil, source_kind .. "_timer_deferred"
            end
            if countPrefixOpcode(helper, source_opcode) ~= 1 then
                return nil, "source_helper_not_" .. source_kind
            end
            if hasPostfixOpcodeOnly(slot, continuation_kind) then
                continuation_count = continuation_count + 1
            end
            selected[#selected + 1] = {
                slot = slot,
                helper = helper,
            }
        end
    end
    if #selected == 0 then
        return nil, "missing_" .. source_kind .. "_source_slot"
    end
    if #selected > projectile_cap then
        return nil, "multicast_cap_exceeded"
    end
    if continuation_count > 0 and continuation_count ~= #selected then
        return nil, "nested_payload_runtime_deferred"
    end
    return selected, nil, continuation_count == #selected
end

local function computePatternInfo(live_mode, pattern_kind, pattern_op, selected_helpers, launch_payload)
    if not isPatternMode(live_mode) then
        return nil, nil
    end
    local count = #selected_helpers
    local params = pattern_op and pattern_op.params or nil
    local computed = nil
    if live_mode == "spread" then
        computed = patterns.computeSpreadDirections(launch_payload.direction, count, params)
    elseif live_mode == "burst" then
        computed = patterns.computeBurstDirections(launch_payload.direction, count, params)
    else
        return nil, "unknown_pattern_mode"
    end
    if not computed or computed.ok ~= true then
        runtime_stats.inc("live_pattern_direction_failed")
        return nil, computed and computed.error or "pattern direction failed"
    end

    local direction_by_slot_id = {}
    local key_by_slot_id = {}
    for index, pair in ipairs(selected_helpers) do
        local slot_id = pair and pair.helper and pair.helper.slot_id
        if type(slot_id) ~= "string" or computed.directions[index] == nil or computed.direction_keys[index] == nil then
            runtime_stats.inc("live_pattern_direction_failed")
            return nil, "pattern direction missing for helper"
        end
        direction_by_slot_id[slot_id] = computed.directions[index]
        key_by_slot_id[slot_id] = computed.direction_keys[index]
    end
    runtime_stats.inc("live_pattern_direction_jobs", count)

    return {
        pattern_kind = pattern_kind,
        pattern_count = count,
        directions = computed.directions,
        direction_keys = computed.direction_keys,
        direction_by_slot_id = direction_by_slot_id,
        key_by_slot_id = key_by_slot_id,
        spread_preset = computed.preset,
        spread_side_angle_degrees = computed.side_angle_degrees,
        spread_rotation_axis = computed.rotation_axis,
        burst_param_count = computed.burst_param_count,
        burst_ring_angle_degrees = computed.ring_angle_degrees,
        burst_distribution = computed.distribution,
    }, nil
end

local function buildJobInputs(selected_helpers, compiled_recipe_id, cast_id, launch_payload, pattern_info, size_info, speed_info, homing_info)
    local jobs = {}
    local fanout_count = #selected_helpers
    for index, pair in ipairs(selected_helpers) do
        local slot = pair.slot
        local helper = pair.helper
        local emission_index = slot.emission_index or helper.emission_index or index
        local group_index = slot.group_index or helper.group_index
        local launch_direction = launch_payload.direction
        local pattern_direction_key = nil
        if pattern_info and pattern_info.direction_by_slot_id then
            launch_direction = pattern_info.direction_by_slot_id[helper.slot_id] or launch_direction
            pattern_direction_key = pattern_info.key_by_slot_id and pattern_info.key_by_slot_id[helper.slot_id] or nil
        end
        if homing_info and homing_info.direction and homing_info.apply_direction == true then
            launch_direction = homing_info.direction
        end
        jobs[#jobs + 1] = {
            kind = orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND,
            recipe_id = compiled_recipe_id,
            slot_id = helper.slot_id,
            helper_engine_id = helper.engine_id,
            depth = 0,
            cast_attempt_id = launch_payload.cast_attempt_id,
            cast_id = cast_id,
            emission_index = emission_index,
            group_index = group_index,
            fanout_count = fanout_count,
            max_live_launches_per_tick = launch_payload.max_live_launches_per_tick,
            chaos_budget_profile = launch_payload.chaos_budget_profile,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_index = pattern_info and emission_index or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_key = pattern_direction_key,
            size_plus = size_info and true or nil,
            size_plus_mode = size_info and size_info.size_plus_mode or nil,
            size_plus_value = size_info and size_info.size_plus_value or nil,
            size_plus_multiplier = size_info and size_info.size_plus_multiplier or nil,
            size_plus_field = size_info and size_info.size_plus_field or nil,
            size_plus_capped = size_info and size_info.size_plus_capped or nil,
            size_plus_base_area = size_info and size_info.size_plus_base_area or nil,
            size_plus_area = size_info and size_info.size_plus_area or nil,
            speed = speed_info and speed_info.speed_plus_speed or nil,
            maxSpeed = speed_info and speed_info.speed_plus_max_speed or nil,
            speed_plus = speed_info and true or nil,
            speed_plus_mode = speed_info and speed_info.speed_plus_mode or nil,
            speed_plus_value = speed_info and speed_info.speed_plus_value or nil,
            speed_plus_base_speed = speed_info and speed_info.speed_plus_base_speed or nil,
            speed_plus_multiplier = speed_info and speed_info.speed_plus_multiplier or nil,
            speed_plus_speed = speed_info and speed_info.speed_plus_speed or nil,
            speed_plus_max_speed = speed_info and speed_info.speed_plus_max_speed or nil,
            speed_plus_field = speed_info and speed_info.speed_plus_field or nil,
            speed_plus_capped = speed_info and speed_info.speed_plus_capped or nil,
            forceVec = homing_info and homing_info.forceVec or nil,
            homing = homing_info and true or nil,
            homing_mode = homing_info and homing_info.homing_mode or nil,
            homing_force = homing_info and homing_info.homing_force or nil,
            homing_field = homing_info and homing_info.homing_field or nil,
            homing_target_id = homing_info and homing_info.homing_target_id or nil,
            homing_target_provider = homing_info and homing_info.homing_target_provider or nil,
            homing_target_kind = homing_info and homing_info.homing_target_kind or nil,
            homing_candidate_count = homing_info and homing_info.homing_candidate_count or nil,
            homing_actor_candidate_count = homing_info and homing_info.homing_actor_candidate_count or nil,
            homing_creature_candidate_count = homing_info and homing_info.homing_creature_candidate_count or nil,
            homing_npc_candidate_count = homing_info and homing_info.homing_npc_candidate_count or nil,
            homing_force_key = homing_info and homing_info.homing_force_key or nil,
            homing_direction_key = homing_info and homing_info.homing_direction_key or nil,
            payload = {
                actor = launch_payload.actor or launch_payload.sender,
                start_pos = launch_payload.start_pos,
                direction = launch_direction,
                hit_object = launch_payload.hit_object,
                cast_attempt_id = launch_payload.cast_attempt_id,
                cast_id = cast_id,
                fanout_count = fanout_count,
                max_live_launches_per_tick = launch_payload.max_live_launches_per_tick,
                chaos_budget_profile = launch_payload.chaos_budget_profile,
                emission_index = emission_index,
                group_index = group_index,
                pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
                pattern_index = pattern_info and emission_index or nil,
                pattern_count = pattern_info and pattern_info.pattern_count or nil,
                pattern_direction_key = pattern_direction_key,
                size_plus = size_info and true or nil,
                size_plus_mode = size_info and size_info.size_plus_mode or nil,
                size_plus_value = size_info and size_info.size_plus_value or nil,
                size_plus_multiplier = size_info and size_info.size_plus_multiplier or nil,
                size_plus_field = size_info and size_info.size_plus_field or nil,
                size_plus_capped = size_info and size_info.size_plus_capped or nil,
                size_plus_base_area = size_info and size_info.size_plus_base_area or nil,
                size_plus_area = size_info and size_info.size_plus_area or nil,
                speed = speed_info and speed_info.speed_plus_speed or nil,
                maxSpeed = speed_info and speed_info.speed_plus_max_speed or nil,
                speed_plus = speed_info and true or nil,
                speed_plus_mode = speed_info and speed_info.speed_plus_mode or nil,
                speed_plus_value = speed_info and speed_info.speed_plus_value or nil,
                speed_plus_base_speed = speed_info and speed_info.speed_plus_base_speed or nil,
                speed_plus_multiplier = speed_info and speed_info.speed_plus_multiplier or nil,
                speed_plus_speed = speed_info and speed_info.speed_plus_speed or nil,
                speed_plus_max_speed = speed_info and speed_info.speed_plus_max_speed or nil,
                speed_plus_field = speed_info and speed_info.speed_plus_field or nil,
                speed_plus_capped = speed_info and speed_info.speed_plus_capped or nil,
                forceVec = homing_info and homing_info.forceVec or nil,
                homing = homing_info and true or nil,
                homing_mode = homing_info and homing_info.homing_mode or nil,
                homing_force = homing_info and homing_info.homing_force or nil,
                homing_field = homing_info and homing_info.homing_field or nil,
                homing_target_id = homing_info and homing_info.homing_target_id or nil,
                homing_target_provider = homing_info and homing_info.homing_target_provider or nil,
                homing_target_kind = homing_info and homing_info.homing_target_kind or nil,
                homing_candidate_count = homing_info and homing_info.homing_candidate_count or nil,
                homing_actor_candidate_count = homing_info and homing_info.homing_actor_candidate_count or nil,
                homing_creature_candidate_count = homing_info and homing_info.homing_creature_candidate_count or nil,
                homing_npc_candidate_count = homing_info and homing_info.homing_npc_candidate_count or nil,
                homing_force_key = homing_info and homing_info.homing_force_key or nil,
                homing_direction_key = homing_info and homing_info.homing_direction_key or nil,
            },
        }
    end
    return jobs
end

local function hasSourceLaunchModifier(entry)
    for _, op in ipairs(entry and entry.prefix_ops or {}) do
        if op and (op.opcode == "Speed+" or op.opcode == "Size+") then
            return true
        end
    end
    return false
end

local function hasSourceHoming(entry)
    return hasPrefixOpcode(entry, "Homing")
end

local function homingPolicyOptions(options, policy_kind, fanout_count)
    return {
        policy_kind = policy_kind or "source",
        allow_homing = true,
        allow_source_homing = policy_kind ~= "payload",
        allow_payload_homing = policy_kind == "payload",
        force_homing_enabled = options.force_homing_enabled,
        force_homing_disabled = options.force_homing_disabled,
        homing_enabled = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        force_soft_homing_enabled = options.force_soft_homing_enabled,
        force_soft_homing_disabled = options.force_soft_homing_disabled,
        soft_homing_enabled = dev.liveSoftHomingEnabled() == true,
        soft_homing_probe = options.soft_homing_probe == true,
        fanout_count = fanout_count,
        homing_target_id = options.homing_target_id,
        homing_target_position = options.homing_target_position,
        homing_actor_scan = options.homing_actor_scan,
        max_homing_fanout_per_cast = options.max_homing_fanout_per_cast or limits.MAX_HOMING_FANOUT_PER_CAST,
        max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast or limits.MAX_HOMING_TARGET_SCANS_PER_CAST,
        max_soft_homing_registrations_per_cast = options.max_soft_homing_registrations_per_cast
            or limits.MAX_SOFT_HOMING_REGISTRATIONS_PER_CAST,
    }
end

local function singleSourceLaunchModifierSlot(plan)
    local source_slot = nil
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" and hasSourceLaunchModifier(slot) then
            if source_slot then
                return nil, "source_modifier_cap_exceeded"
            end
            source_slot = slot
        end
    end
    return source_slot, nil
end

local function sourcePolicyOptions(options, source_kind)
    local opts = {
        policy_kind = "source",
        apply_size_to_specs = true,
        allow_bounce_source = source_kind == "bounce",
        allow_pierce_source = source_kind == "pierce",
        allow_event_source_fanout = options.allow_event_source_fanout == true,
        allow_event_source_modifier_combo = options.allow_event_source_modifier_combo == true,
        allow_source_continuation_modifiers = options.allow_source_continuation_modifiers == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
    }
    return opts
end

local function sourceContinuationOptions(options)
    local out = {}
    for key, value in pairs(options or {}) do
        out[key] = value
    end
    out.allow_source_continuation_modifiers = true
    return out
end

local function attachHelperRecordsWithSourcePolicy(compiled, options, source_kind)
    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id, { limits = options.budget_limits })
    if not attached_specs.ok then
        runtime_stats.inc("helper_records_attach_failed")
        return nil, "helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        }
    end

    local source_slot, source_reason = singleSourceLaunchModifierSlot(attached_specs.plan)
    if source_reason then
        return nil, source_reason, {
            plan_recipe_id = compiled.recipe_id,
        }
    end

    local inspection = nil
    if source_slot then
        inspection = launch_modifier_policy.inspectSourceEntry(
            attached_specs.plan,
            attached_specs.plan.runtime_ir,
            source_slot,
            sourcePolicyOptions(options, source_kind)
        )
        if inspection.ok ~= true then
            return nil, inspection.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot.slot_id,
            }
        end
    end

    local materialized = helper_records.materialize({
        recipe_id = attached_specs.plan.recipe_id,
        specs = attached_specs.plan.helper_specs,
    }, { limits = options.budget_limits })
    if not materialized.ok then
        runtime_stats.inc("helper_records_attach_failed")
        return nil, "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        }
    end

    attached_specs.plan.helper_records = materialized.records
    attached_specs.plan.helper_record_count = materialized.record_count
    attached_specs.plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    return {
        ok = true,
        recipe_id = compiled.recipe_id,
        record_count = materialized.record_count,
        reused = materialized.reused,
        warnings = materialized.warnings,
        plan = attached_specs.plan,
        source_slot = source_slot,
        source_policy = inspection,
    }, nil, nil
end

local function applySourcePolicyToJob(policy_plan, source_job, event_kind)
    if type(policy_plan) ~= "table" or type(source_job) ~= "table" then
        return nil
    end
    local source_slot = policy_plan.source_slot
    local policy = policy_plan.source_policy
    if type(source_slot) ~= "table" or type(policy) ~= "table" then
        return nil
    end
    local applied = launch_modifier_policy.applySourcePolicyToLaunchSpec(
        policy_plan.plan,
        policy_plan.plan and policy_plan.plan.runtime_ir or nil,
        source_slot,
        source_job,
        { event_kind = event_kind },
        {
            policy_kind = "source",
            inspection = policy,
        }
    )
    return applied
end

local function applyHomingPolicyToJob(policy_plan, source_job, event_kind, launch_payload, options)
    if type(policy_plan) ~= "table" or type(source_job) ~= "table" then
        return nil
    end
    local source_slot = policy_plan.source_slot
    local policy = policy_plan.homing_policy
    if type(source_slot) ~= "table" or type(policy) ~= "table" then
        return nil
    end
    local apply_options = homingPolicyOptions(options or {}, "source", policy_plan.fanout_count)
    apply_options.inspection = policy
    apply_options.apply_homing_direction = policy_plan.apply_homing_direction == true
    apply_options.homing_target_id = apply_options.homing_target_id or source_job.homing_target_id
    apply_options.homing_target_position = apply_options.homing_target_position or source_job.homing_target_position
    local event_context = {
        event_kind = event_kind,
        actor = launch_payload and (launch_payload.actor or launch_payload.sender) or nil,
        sender = launch_payload and launch_payload.sender or nil,
        start_pos = launch_payload and launch_payload.start_pos or nil,
        direction = source_job.direction or (launch_payload and launch_payload.direction) or nil,
        hit_object = launch_payload and launch_payload.hit_object or nil,
        homing_target_id = apply_options.homing_target_id,
        homing_target_position = apply_options.homing_target_position,
        homing_actor_scan = apply_options.homing_actor_scan,
    }
    return homing_launch_policy.applyToLaunchSpec(
        policy_plan.plan,
        policy_plan.plan and policy_plan.plan.runtime_ir or nil,
        source_slot,
        source_job,
        event_context,
        apply_options
    )
end

local function jobSummary(job_id)
    local job = orchestrator.getJob(job_id)
    local payload = job and job.payload or nil
    local homing_force_suppressed = job and job.homing_v2_launch_force_suppressed == true
    local force_vec = nil
    if job and not homing_force_suppressed then
        force_vec = job.forceVec or (payload and payload.forceVec)
    end
    local homing_force = nil
    local homing_force_key = nil
    if job and not homing_force_suppressed then
        homing_force = job.homing_force or (payload and payload.homing_force)
        homing_force_key = job.homing_force_key or (payload and payload.homing_force_key)
    end
    return {
        job_id = job_id,
        job_status = job and job.status or nil,
        slot_id = job and job.slot_id or nil,
        helper_engine_id = job and job.helper_engine_id or nil,
        cast_attempt_id = job and job.cast_attempt_id or nil,
        cast_id = job and job.cast_id or nil,
        emission_index = job and job.emission_index or nil,
        group_index = job and job.group_index or nil,
        fanout_count = job and job.fanout_count or nil,
        root_source_slot_id = job and (job.root_source_slot_id or (payload and payload.root_source_slot_id)) or nil,
        current_source_slot_id = job and (job.current_source_slot_id or (payload and payload.current_source_slot_id)) or nil,
        parent_slot_id = job and (job.parent_slot_id or (payload and payload.parent_slot_id)) or nil,
        payload_depth = job and (job.payload_depth or (payload and payload.payload_depth)) or nil,
        nested_stage_kind = job and (job.nested_stage_kind or (payload and payload.nested_stage_kind)) or nil,
        nested_stage_index = job and (job.nested_stage_index or (payload and payload.nested_stage_index)) or nil,
        pattern_kind = job and job.pattern_kind or nil,
        pattern_index = job and job.pattern_index or nil,
        pattern_count = job and job.pattern_count or nil,
        pattern_direction_key = job and job.pattern_direction_key or nil,
        chain_runtime = job and (job.chain_runtime or (payload and payload.chain_runtime)) or nil,
        chain_role = job and (job.chain_role or (payload and payload.chain_role)) or nil,
        chain_id = job and (job.chain_id or (payload and payload.chain_id)) or nil,
        chain_hop_index = job and (job.chain_hop_index or (payload and payload.chain_hop_index)) or nil,
        chain_max_hops = job and (job.chain_max_hops or (payload and payload.chain_max_hops)) or nil,
        chain_targeting_mode = job and (job.chain_targeting_mode or (payload and payload.chain_targeting_mode)) or nil,
        branch_scope = job and (job.branch_scope or (payload and payload.branch_scope)) or nil,
        branch_id = job and (job.branch_id or (payload and payload.branch_id)) or nil,
        branch_parent_id = job and (job.branch_parent_id or (payload and payload.branch_parent_id)) or nil,
        branch_kind = job and (job.branch_kind or (payload and payload.branch_kind)) or nil,
        branch_index = job and (job.branch_index or (payload and payload.branch_index)) or nil,
        branch_count = job and (job.branch_count or (payload and payload.branch_count)) or nil,
        chain_continuation_group_id = job and (job.chain_continuation_group_id or (payload and payload.chain_continuation_group_id)) or nil,
        current_hit_target_id = job and (job.current_hit_target_id or (payload and payload.current_hit_target_id)) or nil,
        selected_target_id = job and (job.selected_target_id or (payload and payload.selected_target_id)) or nil,
        previous_projectile_id = job and (job.previous_projectile_id or (payload and payload.previous_projectile_id)) or nil,
        bounce_runtime = job and firstPresent(job.bounce_runtime, payload and payload.bounce_runtime) or nil,
        bounce_role = job and firstPresent(job.bounce_role, payload and payload.bounce_role) or nil,
        bounce_id = job and firstPresent(job.bounce_id, payload and payload.bounce_id) or nil,
        bounce_max = job and firstPresent(job.bounce_max, payload and payload.bounce_max) or nil,
        bounce_power = job and firstPresent(job.bounce_power, payload and payload.bounce_power) or nil,
        bounceEnabled = job and firstPresent(job.bounceEnabled, payload and payload.bounceEnabled) or nil,
        bounceMax = job and firstPresent(job.bounceMax, payload and payload.bounceMax) or nil,
        bouncePower = job and firstPresent(job.bouncePower, payload and payload.bouncePower) or nil,
        detonateOnActorHit = bounceDetonateOnActorHit(job, payload),
        post_launch_bounce_attempted = job and job.post_launch_bounce_attempted == true or false,
        post_launch_bounce_ok = job and job.post_launch_bounce_ok == true or false,
        post_launch_bounce_error = job and job.post_launch_bounce_error or nil,
        pierce_runtime = job and firstPresent(job.pierce_runtime, payload and payload.pierce_runtime) or nil,
        pierce_role = job and firstPresent(job.pierce_role, payload and payload.pierce_role) or nil,
        pierce_id = job and firstPresent(job.pierce_id, payload and payload.pierce_id) or nil,
        pierce_count = job and firstPresent(job.pierce_count, payload and payload.pierce_count) or nil,
        pierce_limit = job and firstPresent(job.pierce_limit, payload and payload.pierce_limit) or nil,
        piercing = job and firstPresent(job.piercing, payload and payload.piercing) or nil,
        pierceLimit = job and firstPresent(job.pierceLimit, payload and payload.pierceLimit) or nil,
        post_launch_pierce_attempted = job and job.post_launch_pierce_attempted == true or false,
        post_launch_pierce_ok = job and job.post_launch_pierce_ok == true or false,
        post_launch_pierce_error = job and job.post_launch_pierce_error or nil,
        post_launch_detonate_on_actor_attempted = job and job.post_launch_detonate_on_actor_attempted == true or false,
        post_launch_detonate_on_actor_ok = job and job.post_launch_detonate_on_actor_ok == true or false,
        post_launch_detonate_on_actor_error = job and job.post_launch_detonate_on_actor_error or nil,
        source_modifier_kind = job and (job.source_modifier_kind or (payload and payload.source_modifier_kind)) or nil,
        payload_modifier_kind = job and (job.payload_modifier_kind or (payload and payload.payload_modifier_kind)) or nil,
        source_slot_id = job and job.source_slot_id or nil,
        source_prefix_opcode = job and (job.source_prefix_opcode or (payload and payload.source_prefix_opcode)) or nil,
        source_helper_engine_id = job and job.source_helper_engine_id or nil,
        source_postfix_opcode = job and job.source_postfix_opcode or nil,
        payload_slot_id = job and job.payload_slot_id or nil,
        trigger_route = job and (job.trigger_route or (payload and payload.trigger_route)) or nil,
        trigger_duplicate_key = job and (job.trigger_duplicate_key or (payload and payload.trigger_duplicate_key)) or nil,
        timer_source_slot_id = job and (job.timer_source_slot_id or (payload and payload.timer_source_slot_id)) or nil,
        timer_payload_slot_id = job and (job.timer_payload_slot_id or (payload and payload.timer_payload_slot_id)) or nil,
        timer_id = job and (job.timer_id or (payload and payload.timer_id)) or nil,
        timer_delay_ticks = job and (job.timer_delay_ticks or (payload and payload.timer_delay_ticks)) or nil,
        timer_delay_seconds = job and (job.timer_delay_seconds or (payload and payload.timer_delay_seconds)) or nil,
        timer_scheduled_tick = job and (job.timer_scheduled_tick or (payload and payload.timer_scheduled_tick)) or nil,
        timer_due_tick = job and (job.timer_due_tick or (payload and payload.timer_due_tick)) or nil,
        timer_scheduled_seconds = job and (job.timer_scheduled_seconds or (payload and payload.timer_scheduled_seconds)) or nil,
        timer_due_seconds = job and (job.timer_due_seconds or (payload and payload.timer_due_seconds)) or nil,
        timer_delay_semantics = job and (job.timer_delay_semantics or (payload and payload.timer_delay_semantics)) or nil,
        not_before_seconds = job and job.not_before_seconds or nil,
        created_seconds = job and job.created_seconds or nil,
        timer_duplicate_key = job and (job.timer_duplicate_key or (payload and payload.timer_duplicate_key)) or nil,
        size_plus = job and (job.size_plus or (payload and payload.size_plus)) or nil,
        size_plus_mode = job and (job.size_plus_mode or (payload and payload.size_plus_mode)) or nil,
        size_plus_value = job and (job.size_plus_value or (payload and payload.size_plus_value)) or nil,
        size_plus_multiplier = job and (job.size_plus_multiplier or (payload and payload.size_plus_multiplier)) or nil,
        size_plus_field = job and (job.size_plus_field or (payload and payload.size_plus_field)) or nil,
        size_plus_capped = job and (job.size_plus_capped or (payload and payload.size_plus_capped)) or nil,
        size_plus_base_area = job and (job.size_plus_base_area or (payload and payload.size_plus_base_area)) or nil,
        size_plus_area = job and (job.size_plus_area or (payload and payload.size_plus_area)) or nil,
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
        forceVec = force_vec,
        homing = job and (job.homing or (payload and payload.homing)) or nil,
        homing_mode = job and (job.homing_mode or (payload and payload.homing_mode)) or nil,
        homing_force = homing_force,
        homing_field = job and (job.homing_field or (payload and payload.homing_field)) or nil,
        homing_target_id = job and (job.homing_target_id or (payload and payload.homing_target_id)) or nil,
        homing_target_provider = job and (job.homing_target_provider or (payload and payload.homing_target_provider)) or nil,
        homing_target_kind = job and (job.homing_target_kind or (payload and payload.homing_target_kind)) or nil,
        homing_targeting_mode = job and (job.homing_targeting_mode or (payload and payload.homing_targeting_mode)) or nil,
        homing_initial_steer_delay_seconds = job and (job.homing_initial_steer_delay_seconds or (payload and payload.homing_initial_steer_delay_seconds)) or nil,
        homing_candidate_count = job and (job.homing_candidate_count or (payload and payload.homing_candidate_count)) or nil,
        homing_actor_candidate_count = job and (job.homing_actor_candidate_count or (payload and payload.homing_actor_candidate_count)) or nil,
        homing_creature_candidate_count = job and (job.homing_creature_candidate_count or (payload and payload.homing_creature_candidate_count)) or nil,
        homing_npc_candidate_count = job and (job.homing_npc_candidate_count or (payload and payload.homing_npc_candidate_count)) or nil,
        homing_force_key = homing_force_key,
        homing_direction_key = job and (job.homing_direction_key or (payload and payload.homing_direction_key)) or nil,
        homing_launch_runtime_mode = job and job.homing_launch_runtime_mode or nil,
        homing_v2_launch_force_suppressed = homing_force_suppressed == true,
        homing_v2_payload_force_seeded = job and job.homing_v2_payload_force_seeded == true or false,
        homing_v2_payload_force_seed_multiplier = job and job.homing_v2_payload_force_seed_multiplier or nil,
        homing_v2_manager_attempted = job and job.homing_v2_manager_attempted == true or false,
        homing_v2_manager_registered = job and job.homing_v2_manager_registered == true or false,
        homing_v2_manager_entry_id = job and job.homing_v2_manager_entry_id or nil,
        homing_v2_manager_error = job and job.homing_v2_manager_error or nil,
        launch_accepted = job and job.launch_accepted == true or false,
        projectile_id = job and job.projectile_id or nil,
        projectile_id_source = job and job.projectile_id_source or nil,
        projectile_registered = job and job.projectile_registered == true or false,
        launch_start_pos = job and (job.launch_start_pos or (payload and payload.start_pos)) or nil,
        launch_direction = job and (job.launch_direction or (payload and payload.direction)) or nil,
        excludeTarget = job and (job.excludeTarget or (payload and payload.excludeTarget)) or nil,
        launch_user_data = job and job.launch_user_data or nil,
        error = job and job.error or nil,
    }
end

local function jobsCarrySpeedPlusUserData(jobs, expected_count, cast_id)
    if type(jobs) ~= "table" or #jobs ~= expected_count then
        return false
    end
    for _, job in ipairs(jobs) do
        local user_data = job and job.launch_user_data or nil
        if type(user_data) ~= "table"
            or user_data.spellforge ~= true
            or user_data.schema ~= "spellforge_sfp_userdata_v1"
            or user_data.runtime ~= "2.2c_live_helper"
            or user_data.cast_id ~= cast_id
            or user_data.payload_modifier_kind ~= "speed_plus"
            or user_data.speed_plus ~= true
            or user_data.speed_plus_mode ~= "initial_speed"
            or type(user_data.speed_plus_base_speed) ~= "number"
            or type(user_data.speed_plus_multiplier) ~= "number"
            or user_data.speed_plus_field ~= "speed"
            or type(user_data.speed_plus_speed) ~= "number"
            or user_data.speed_plus_speed == user_data.speed_plus_base_speed then
            return false
        end
    end
    return true
end

local function jobsCarrySizePlusUserData(jobs, expected_count, cast_id)
    if type(jobs) ~= "table" or #jobs ~= expected_count then
        return false
    end
    for _, job in ipairs(jobs) do
        local user_data = job and job.launch_user_data or nil
        if type(user_data) ~= "table"
            or user_data.spellforge ~= true
            or user_data.schema ~= "spellforge_sfp_userdata_v1"
            or user_data.runtime ~= "2.2c_live_helper"
            or user_data.cast_id ~= cast_id
            or user_data.payload_modifier_kind ~= "size_plus"
            or user_data.size_plus ~= true
            or user_data.size_plus_mode ~= "multiplier"
            or type(user_data.size_plus_value) ~= "number"
            or type(user_data.size_plus_multiplier) ~= "number"
            or user_data.size_plus_field ~= "effect.area"
            or type(user_data.size_plus_base_area) ~= "number"
            or type(user_data.size_plus_area) ~= "number"
            or user_data.size_plus_area <= user_data.size_plus_base_area then
            return false
        end
    end
    return true
end

local function tickUntilJobsSettled(job_ids, opts)
    local options = opts or {}
    local max_ticks = tonumber(options.max_launch_ticks) or 3
    local max_jobs_per_tick = tonumber(options.max_jobs_per_tick) or limits.MAX_JOBS_PER_TICK
    local max_live_launches_per_tick = tonumber(options.max_live_launches_per_tick) or limits.MAX_LIVE_LAUNCHES_PER_TICK
    local last_tick = nil

    for _ = 1, max_ticks do
        local all_settled = true
        for _, job_id in ipairs(job_ids or {}) do
            local job = orchestrator.getJob(job_id)
            if not job or job.status == "queued" or job.status == "running" then
                all_settled = false
                break
            end
        end
        if all_settled then
            return last_tick
        end
        last_tick = orchestrator.tick({
            max_jobs_per_tick = max_jobs_per_tick,
            max_live_launches_per_tick = max_live_launches_per_tick,
        })
        if options.allow_pending_launch_jobs == true
            and last_tick
            and tonumber(last_tick.live_launch_throttled_count) ~= nil
            and tonumber(last_tick.live_launch_throttled_count) > 0 then
            return last_tick
        end
    end

    return last_tick
end

local function effectListFromRoot(root)
    if type(root) ~= "table" then
        return nil
    end
    if type(root.effect_list) == "table" and #root.effect_list > 0 then
        return cloneEffects(root.effect_list)
    end
    if type(root.real_effects) == "table" and #root.real_effects > 0 then
        return cloneEffects(root.real_effects)
    end
    return nil
end

local function sourceModifierClosureCandidate(plan)
    local bounds = plan and plan.bounds or nil
    if type(bounds) ~= "table" then
        return false
    end
    if not (bounds.has_speed_plus == true or bounds.has_size_plus == true) then
        return false
    end
    if bounds.has_bounce == true
        or bounds.has_pierce == true
        or bounds.has_chain == true
        or bounds.has_homing == true
        or bounds.has_trigger == true
        or bounds.has_timer == true then
        return false
    end
    if bounds.has_speed_plus == true and bounds.has_size_plus == true then
        return true
    end
    return bounds.has_multicast == true or bounds.has_pattern == true
end

local function sourceModifierKindFromBounds(bounds)
    if bounds and bounds.has_speed_plus == true and bounds.has_size_plus == true then
        return "speed_plus_size_plus"
    elseif bounds and bounds.has_speed_plus == true then
        return "speed_plus"
    elseif bounds and bounds.has_size_plus == true then
        return "size_plus"
    end
    return nil
end

local function sourceModifierClosureRejected(kind, reason, details, counter_name)
    runtime_stats.inc("launch_modifier_closure_rejected")
    if kind == "size_plus" then
        return sizePlusRejected(reason, details, counter_name)
    elseif kind == "speed_plus" then
        return speedPlusRejected(reason, details, counter_name)
    end
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function sourceModifierClosurePrefix(selected_helpers)
    local first_slot = selected_helpers and selected_helpers[1] and selected_helpers[1].slot or nil
    local pattern_kind = nil
    local pattern_op = nil
    local multicast_op = nil
    for _, op in ipairs(first_slot and first_slot.prefix_ops or {}) do
        if op and op.opcode == "Multicast" then
            multicast_op = multicast_op or op
        elseif op and (op.opcode == "Spread" or op.opcode == "Burst") then
            pattern_kind = pattern_kind or op.opcode
            pattern_op = pattern_op or op
        end
    end
    local primary_mode = "single"
    if pattern_kind == "Spread" then
        primary_mode = "spread"
    elseif pattern_kind == "Burst" then
        primary_mode = "burst"
    elseif multicast_op ~= nil or #(selected_helpers or {}) > 1 then
        primary_mode = "multicast"
    end
    return primary_mode, pattern_kind, pattern_op
end

local function eventSourceKindFromBounds(bounds)
    if bounds and bounds.has_bounce == true then
        return "bounce"
    elseif bounds and bounds.has_pierce == true then
        return "pierce"
    end
    return nil
end

local function sourceEntryHasPrimaryFanout(entry)
    return hasPrefixOpcode(entry, "Multicast")
        or hasPrefixOpcode(entry, "Spread")
        or hasPrefixOpcode(entry, "Burst")
end

local function eventSourceFanoutCandidate(plan)
    local bounds = plan and plan.bounds or nil
    if type(bounds) ~= "table" then
        return false
    end
    if not (bounds.has_bounce == true or bounds.has_pierce == true) then
        return false
    end
    if bounds.has_bounce == true and bounds.has_pierce == true then
        return false
    end
    local source_opcode = bounds.has_bounce == true and "Bounce" or "Pierce"
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot
            and slot.kind == "primary_emission"
            and countPrefixOpcode(slot, source_opcode) == 1
            and sourceEntryHasPrimaryFanout(slot) then
            return true
        end
    end
    return false
end

local function eventSourceTimerCandidate(plan)
    local bounds = plan and plan.bounds or nil
    if type(bounds) ~= "table" then
        return false
    end
    if bounds.has_timer ~= true then
        return false
    end
    if not (bounds.has_bounce == true or bounds.has_pierce == true) then
        return false
    end
    if bounds.has_bounce == true and bounds.has_pierce == true then
        return false
    end
    local source_opcode = bounds.has_bounce == true and "Bounce" or "Pierce"
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot
            and slot.kind == "primary_emission"
            and countPrefixOpcode(slot, source_opcode) == 1
            and hasTimerPostfix(slot) then
            return true
        end
    end
    return false
end

local function clampEventCount(value, default_value, hard_max)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = default_value or 1
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    end
    local max_value = tonumber(hard_max)
    if max_value and n > max_value then
        n = max_value
    end
    return n
end

local function clampBouncePowerForFanout(value)
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

local function eventSourceOpAndCount(source_kind, source_entry)
    if source_kind == "bounce" then
        local _, op = countPrefixOpcode(source_entry, "Bounce")
        return op, clampEventCount(
            op and op.params and op.params.bounces,
            1,
            limits.MAX_BOUNCE_COUNT_HARD
        )
    elseif source_kind == "pierce" then
        local _, op = countPrefixOpcode(source_entry, "Pierce")
        return op, clampEventCount(
            op and op.params and op.params.pierces,
            2,
            limits.MAX_PIERCE_COUNT_HARD
        )
    end
    return nil, 1
end

local function eventSourceRejected(source_kind, reason, details, counter_name)
    runtime_stats.inc("event_source_fanout_rejected")
    log.info(string.format(
        "SPELLFORGE_EVENT_SOURCE_FANOUT_POLICY_DEFERRED source_kind=%s reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s",
        tostring(source_kind),
        tostring(reason),
        tostring(details and details.plan_recipe_id or nil),
        tostring(details and details.source_slot_id or nil),
        tostring(details and details.payload_slot_id or nil)
    ))
    if source_kind == "bounce" then
        return bounceRejected(reason, details, counter_name)
    elseif source_kind == "pierce" then
        return pierceRejected(reason, details, counter_name)
    end
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function logEventSourceFanoutOk(source_kind, result_recipe_id, plan_recipe_id, cast_id, fanout_count, primary_mode, trigger_count)
    runtime_stats.inc("event_source_fanout_policy_ok")
    log.info(string.format(
        "SPELLFORGE_EVENT_SOURCE_FANOUT_POLICY_OK source_kind=%s recipe_id=%s plan_recipe_id=%s cast_id=%s fanout_count=%s primary_mode=%s trigger_route_count=%s",
        tostring(source_kind),
        tostring(result_recipe_id),
        tostring(plan_recipe_id),
        tostring(cast_id),
        tostring(fanout_count),
        tostring(primary_mode),
        tostring(trigger_count)
    ))
    if source_kind == "bounce" then
        runtime_stats.inc("bounce_source_fanout_ok")
        log.info(string.format(
            "SPELLFORGE_BOUNCE_SOURCE_FANOUT_OK recipe_id=%s plan_recipe_id=%s cast_id=%s fanout_count=%s trigger_route_count=%s",
            tostring(result_recipe_id),
            tostring(plan_recipe_id),
            tostring(cast_id),
            tostring(fanout_count),
            tostring(trigger_count)
        ))
    elseif source_kind == "pierce" then
        runtime_stats.inc("pierce_source_fanout_ok")
        log.info(string.format(
            "SPELLFORGE_PIERCE_SOURCE_FANOUT_OK recipe_id=%s plan_recipe_id=%s cast_id=%s fanout_count=%s trigger_route_count=%s",
            tostring(result_recipe_id),
            tostring(plan_recipe_id),
            tostring(cast_id),
            tostring(fanout_count),
            tostring(trigger_count)
        ))
    end
end

local function eventSourcePayloadForSource(plan, source_pair, source_kind, options, source_opcode)
    local slot = source_pair and source_pair.slot or nil
    local continuation_opcode = source_opcode or "Trigger"
    if not hasPostfixOpcodeOnly(slot, continuation_opcode) then
        return {
            ok = true,
            has_trigger_payload = false,
            has_timer_payload = false,
            payload_count = 0,
            payload_fanout_count = 1,
        }
    end
    local payload_result = payload_multicast.resolvePayloadHelpersForSource(plan, slot, {
        source_opcode = continuation_opcode,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        allow_payload_launch_modifiers = continuation_opcode == "Timer"
            or options.allow_event_source_fanout_payload_modifiers == true,
        allow_payload_detonate = continuation_opcode == "Timer"
            or options.allow_event_source_fanout_payload_modifiers == true,
        apply_size_to_specs = options.apply_payload_size_to_specs == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        allow_unrelated_payloads = true,
        allowed_primary_prefix_ops = source_kind == "bounce"
            and { Bounce = true, Multicast = true, Spread = true, Burst = true }
            or { Pierce = true, Multicast = true, Spread = true, Burst = true },
    })
    if payload_result.ok ~= true then
        return payload_result
    end
    return {
        ok = true,
        has_trigger_payload = continuation_opcode == "Trigger",
        has_timer_payload = continuation_opcode == "Timer",
        payload_count = payload_result.payload_count or 0,
        payload_fanout_count = payload_result.fanout_count or payload_result.payload_count or 1,
        payload_slot_id = payload_result.payload_slot_id,
        payload_helper_engine_id = payload_result.payload_helper_engine_id,
        payloads = payload_result.payload_slots,
        payload_slot_ids = payload_result.payload_slot_ids,
        payload_helper_engine_ids = payload_result.payload_helper_engine_ids,
        payload_effect_ids = payload_result.payload_effect_ids,
        payload_multicast = payload_result.is_payload_multicast == true,
        payload_pattern = payload_result.is_payload_pattern == true,
        payload_pattern_kind = payload_result.pattern_kind,
        payload_pattern_op = payload_result.pattern_op,
        has_payload_modifier = payload_result.has_payload_modifier == true,
        has_payload_homing = payload_result.has_payload_homing == true,
        payload_modifier_kinds = payload_result.payload_modifier_kinds,
    }
end

local function tryEventSourceFanoutDispatch(compiled, launch_payload, options)
    local bounds = compiled.plan and compiled.plan.bounds or nil
    local source_kind = eventSourceKindFromBounds(bounds)
    runtime_stats.inc("event_source_fanout_attempts")
    if source_kind == nil then
        return eventSourceRejected(nil, "event_source_fanout_unsupported", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if source_kind == "bounce" then
        if options.force_bounce_disabled == true then
            return eventSourceRejected(source_kind, "live_bounce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_disabled_rejections")
        end
        if options.force_bounce_enabled ~= true and not dev.liveBounceEnabled() then
            return eventSourceRejected(source_kind, "live_bounce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_disabled_rejections")
        end
    elseif source_kind == "pierce" then
        if options.force_pierce_disabled == true then
            return eventSourceRejected(source_kind, "live_pierce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_disabled_rejections")
        end
        if options.force_pierce_enabled ~= true and not dev.livePierceEnabled() then
            return eventSourceRejected(source_kind, "live_pierce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_disabled_rejections")
        end
    end

    local capabilities = sfp_adapter.capabilities()
    if source_kind == "bounce" then
        if not capabilities.has_setSpellBounce
            or not capabilities.has_setSpellDetonateOnActor
            or not capabilities.has_detonateSpellAtPos
            or not capabilities.has_cancelSpell then
            return eventSourceRejected(source_kind, "sfp_bounce_missing", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_capability_rejections")
        end
    elseif source_kind == "pierce" then
        if not capabilities.has_setSpellPiercing and not capabilities.has_setSpellPhysics then
            return eventSourceRejected(source_kind, "sfp_pierce_event_unavailable", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_capability_rejections")
        end
    end

    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id, { limits = options.budget_limits })
    if not attached_specs.ok then
        return eventSourceRejected(source_kind, "helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        })
    end

    local plan = attached_specs.plan
    local policy_options = sourcePolicyOptions(options, source_kind)
    policy_options.allow_event_source_fanout = true
    policy_options.allow_event_source_modifier_combo = true
    policy_options.max_source_modifier_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_projectiles = limits.MAX_PROJECTILES_PER_CAST
    local source_policies_by_slot = {}
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" then
            local inspected = launch_modifier_policy.inspectSourceEntry(
                plan,
                plan and plan.runtime_ir or nil,
                slot,
                policy_options
            )
            if inspected.ok ~= true then
                return eventSourceRejected(source_kind, inspected.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = slot.slot_id,
                })
            end
            source_policies_by_slot[slot.slot_id] = inspected
        end
    end

    local materialized = helper_records.materialize({
        recipe_id = plan.recipe_id,
        specs = plan.helper_specs,
    }, { limits = options.budget_limits })
    if not materialized.ok then
        return eventSourceRejected(source_kind, "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        })
    end
    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    local selected_helpers, select_reason, has_trigger_payload = collectEventSourceFanoutHelpers(plan, source_kind, {
        max_projectiles = options.max_projectiles or limits.MAX_PROJECTILES_PER_CAST,
    })
    if not selected_helpers then
        return eventSourceRejected(source_kind, select_reason or "event_source_fanout_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local primary_mode, pattern_kind, pattern_op = sourceModifierClosurePrefix(selected_helpers)
    if primary_mode == "multicast" or primary_mode == "spread" or primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return eventSourceRejected(source_kind, "live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "event_source_fanout_gate_rejections")
        end
    end
    if primary_mode == "spread" or primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return eventSourceRejected(source_kind, "live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "event_source_fanout_gate_rejections")
        end
    end
    if has_trigger_payload == true
        and options.force_trigger_enabled ~= true
        and not dev.liveTriggerEnabled() then
        return eventSourceRejected(source_kind, "live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_trigger_disabled_rejections")
    end

    local pattern_info, pattern_err = computePatternInfo(
        primary_mode,
        pattern_kind,
        pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return eventSourceRejected(source_kind, pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "event_source_fanout_pattern_rejections")
    end

    local payloads_by_slot = {}
    local max_payload_fanout_count = 1
    local trigger_route_count = 0
    for _, pair in ipairs(selected_helpers) do
        local payload_result = eventSourcePayloadForSource(plan, pair, source_kind, options)
        if payload_result.ok ~= true then
            return eventSourceRejected(source_kind, payload_result.rejection_reason or "nested_payload_runtime_deferred", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = pair and pair.slot and pair.slot.slot_id or nil,
            })
        end
        payloads_by_slot[pair.slot.slot_id] = payload_result
        if payload_result.has_trigger_payload == true then
            trigger_route_count = trigger_route_count + 1
        end
        max_payload_fanout_count = math.max(max_payload_fanout_count, tonumber(payload_result.payload_fanout_count) or 1)
    end

    local event_counts_by_slot = {}
    local source_ops_by_slot = {}
    local max_event_count = 1
    local bounce_power_by_slot = {}
    for _, pair in ipairs(selected_helpers) do
        local slot = pair and pair.slot
        local source_op, event_count = eventSourceOpAndCount(source_kind, slot)
        source_ops_by_slot[slot.slot_id] = source_op
        event_counts_by_slot[slot.slot_id] = event_count
        max_event_count = math.max(max_event_count, event_count)
        if source_kind == "bounce" then
            local effective_cap = tonumber(options.max_bounce_count) or limits.MAX_BOUNCE_COUNT
            if event_count > effective_cap then
                return eventSourceRejected(source_kind, "bounce_count_cap_exceeded", {
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = slot.slot_id,
                    bounce_max = event_count,
                }, "live_bounce_cap_reject")
            end
            bounce_power_by_slot[slot.slot_id] = clampBouncePowerForFanout(source_op and source_op.params and source_op.params.power)
        elseif source_kind == "pierce" then
            local effective_cap = tonumber(options.max_pierce_count) or limits.MAX_PIERCE_COUNT
            if event_count > effective_cap then
                return eventSourceRejected(source_kind, "pierce_count_cap_exceeded", {
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = slot.slot_id,
                    pierce_limit = event_count,
                }, "live_pierce_cap_reject")
            end
        end
    end

    local budget = launch_modifier_policy.eventSourceFanoutBudget(
        plan,
        plan and plan.runtime_ir or nil,
        selected_helpers[1] and selected_helpers[1].slot or nil,
        {
            source_kind = source_kind,
            source_fanout_count = #selected_helpers,
            event_count_per_source = max_event_count,
            payload_fanout_count = max_payload_fanout_count,
            max_event_source_resumes_per_cast = options.max_event_source_resumes_per_cast,
            max_bounce_payload_jobs_per_cast = options.max_bounce_payload_jobs_per_cast,
            max_pierce_payload_jobs_per_cast = options.max_pierce_payload_jobs_per_cast,
            max_payload_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
        }
    )
    if budget.ok ~= true then
        return eventSourceRejected(source_kind, budget.rejection_reason or "event_source_fanout_budget_exceeded", {
            plan_recipe_id = compiled.recipe_id,
            source_fanout_count = #selected_helpers,
            event_count_per_source = max_event_count,
            payload_fanout_count = max_payload_fanout_count,
        }, "event_source_fanout_budget_reject")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
    local bindings = {}
    local slot_ids = {}
    local helper_engine_ids = {}
    local pattern_direction_keys = {}
    local event_source_ids = {}
    local modifier_job_count = 0
    local branch_parent_id = string.format("%s_fanout:%s", tostring(source_kind), tostring(cast_id))

    for index, pair in ipairs(selected_helpers) do
        local source_slot = pair and pair.slot
        local source_helper = pair and pair.helper
        local job = job_inputs[index]
        local inspected = source_slot and source_policies_by_slot[source_slot.slot_id] or nil
        if type(inspected) ~= "table" then
            return eventSourceRejected(source_kind, "missing_source_policy", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot and source_slot.slot_id or nil,
            })
        end
        local applied = launch_modifier_policy.applySourcePolicyToLaunchSpec(
            plan,
            plan and plan.runtime_ir or nil,
            source_slot,
            job,
            { event_kind = source_kind .. "_source_fanout" },
            {
                policy_kind = "source",
                inspection = inspected,
            }
        )
        if applied == nil or applied.ok ~= true then
            return eventSourceRejected(source_kind, applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot and source_slot.slot_id or nil,
            })
        end
        if job.source_modifier_kind ~= nil then
            modifier_job_count = modifier_job_count + 1
        end

        local payload_result = payloads_by_slot[source_slot.slot_id] or {}
        local event_source_id = string.format(
            "%s:%s:%s:%s",
            tostring(source_kind),
            tostring(cast_id),
            tostring(source_slot.slot_id),
            tostring(index)
        )
        local binding = {
            plan = plan,
            recipe_id = compiled.recipe_id,
            display_recipe_id = result_recipe_id,
            cast_id = cast_id,
            source_slot_id = source_slot.slot_id,
            source_helper_engine_id = source_helper.engine_id,
            payload_slot_id = payload_result.payload_slot_id,
            payload_helper_engine_id = payload_result.payload_helper_engine_id,
            payloads = payload_result.payloads,
            payload_slot_ids = payload_result.payload_slot_ids,
            payload_helper_engine_ids = payload_result.payload_helper_engine_ids,
            payload_count = payload_result.payload_count,
            payload_multicast = payload_result.payload_multicast == true,
            payload_pattern = payload_result.payload_pattern == true,
            payload_pattern_kind = payload_result.payload_pattern_kind,
            payload_pattern_op = payload_result.payload_pattern_op,
            has_trigger_payload = payload_result.has_trigger_payload == true,
            has_chain_payload = false,
            actor = launch_payload.actor or launch_payload.sender,
            start_pos = launch_payload.start_pos,
            direction = launch_payload.direction,
            mute_audio = launch_payload.mute_audio or launch_payload.muteAudio,
            mute_light = launch_payload.mute_light or launch_payload.muteLight,
            max_payload_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
            max_live_launches_per_tick = options.max_live_launches_per_tick,
            chaos_budget_profile = options.chaos_budget_profile,
            allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
            force_payload_multicast_enabled = options.force_payload_multicast_enabled == true,
            force_payload_pattern_enabled = options.force_payload_pattern_enabled == true,
            branch_scope = branch_parent_id,
            branch_parent_id = branch_parent_id,
            branch_id = string.format("%s:%s", tostring(branch_parent_id), tostring(source_slot.slot_id)),
            branch_kind = source_kind .. "_source",
            branch_index = index,
            branch_count = #selected_helpers,
        }
        if source_kind == "bounce" then
            binding.bounce_id = event_source_id
            binding.bounce_max = event_counts_by_slot[source_slot.slot_id]
            binding.bounce_power = bounce_power_by_slot[source_slot.slot_id]
            live_bounce.decorateSourceJob(job, binding)
        else
            binding.pierce_id = event_source_id
            binding.pierce_limit = event_counts_by_slot[source_slot.slot_id]
            live_pierce.decorateSourceJob(job, binding)
        end
        bindings[index] = binding
        slot_ids[index] = source_slot.slot_id
        helper_engine_ids[index] = source_helper.engine_id
        event_source_ids[index] = event_source_id
        pattern_direction_keys[index] = job.pattern_direction_key
    end

    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("event_source_fanout_qualified")
    if primary_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif primary_mode == "spread" or primary_mode == "burst" then
        patternQualified(pattern_kind, #selected_helpers)
    end
    logEventSourceFanoutOk(source_kind, result_recipe_id, compiled.recipe_id, cast_id, #selected_helpers, primary_mode, trigger_route_count)

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_kind = source_kind,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            event_source_ids = event_source_ids,
            jobs = job_inputs,
            bindings = bindings,
            dispatch_count = #selected_helpers,
            source_dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            source_fanout_count = #selected_helpers,
            source_modifier_job_count = modifier_job_count,
            primary_mode = primary_mode,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            trigger_route_count = trigger_route_count,
            event_count_per_source = max_event_count,
            payload_fanout_count = max_payload_fanout_count,
            event_budget_total = budget.total_event_jobs,
            event_budget_cap = budget.source_cap or budget.shared_cap,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            simple_note = "event_source_fanout",
            live_mode = "event_source_fanout",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for index, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return eventSourceRejected(source_kind, "enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[index] = enqueue.job_id
        bindings[index].source_job_id = enqueue.job_id
        local registered = nil
        if source_kind == "bounce" then
            registered = live_bounce.registerBinding(bindings[index])
        else
            registered = live_pierce.registerBinding(bindings[index])
        end
        if not registered then
            orchestrator.cancel(enqueue.job_id)
            return eventSourceRejected(source_kind, source_kind .. "_binding_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = bindings[index].source_slot_id,
                cast_id = cast_id,
            })
        end
    end
    runtime_stats.inc("event_source_fanout_jobs_enqueued", #job_ids)

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "event-source fanout helper launch job did not complete", {
                stage = "event_source_fanout_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    runtime_stats.inc("live_2_2c_dispatch_ok")
    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        source_kind = source_kind,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        event_source_ids = event_source_ids,
        projectile_ids = projectile_ids,
        job_ids = job_ids,
        jobs = jobs,
        dispatch_count = #job_ids,
        source_dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        source_fanout_count = #selected_helpers,
        trigger_route_count = trigger_route_count,
        event_count_per_source = max_event_count,
        payload_fanout_count = max_payload_fanout_count,
        event_budget_total = budget.total_event_jobs,
        runtime = "2.2c_live_helper",
        fallback = false,
        simple_note = "event_source_fanout",
        live_mode = "event_source_fanout",
        cast_id = cast_id,
    }
end

local function eventSourceTimerRejected(source_kind, reason, details, counter_name)
    runtime_stats.inc("event_source_timer_rejected")
    log.info(string.format(
        "SPELLFORGE_EVENT_SOURCE_TIMER_POLICY_DEFERRED source_kind=%s reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s",
        tostring(source_kind),
        tostring(reason),
        tostring(details and details.plan_recipe_id or nil),
        tostring(details and details.source_slot_id or nil),
        tostring(details and details.payload_slot_id or nil)
    ))
    if source_kind == "bounce" then
        return bounceRejected(reason, details, counter_name)
    elseif source_kind == "pierce" then
        return pierceRejected(reason, details, counter_name)
    end
    if counter_name then
        runtime_stats.inc(counter_name)
    end
    return rejected(reason, details)
end

local function timerPostfixInfo(entry)
    for _, op in ipairs(entry and entry.postfix_ops or {}) do
        if op and op.opcode == "Timer" then
            local seconds, ticks, capped, err = live_timer.delayFromOp(op)
            return seconds, ticks, capped, err, op
        end
    end
    return nil, nil, nil, "source_not_timer", nil
end

local function logEventSourceTimerOk(source_kind, result_recipe_id, plan_recipe_id, cast_id, source_timer_count, payload_job_count, primary_mode)
    runtime_stats.inc("event_source_timer_policy_ok")
    log.info(string.format(
        "SPELLFORGE_EVENT_SOURCE_TIMER_POLICY_OK source_kind=%s recipe_id=%s plan_recipe_id=%s cast_id=%s source_timer_count=%s payload_job_count=%s primary_mode=%s",
        tostring(source_kind),
        tostring(result_recipe_id),
        tostring(plan_recipe_id),
        tostring(cast_id),
        tostring(source_timer_count),
        tostring(payload_job_count),
        tostring(primary_mode)
    ))
    if source_kind == "bounce" then
        runtime_stats.inc("bounce_timer_source_ok")
        log.info(string.format(
            "SPELLFORGE_BOUNCE_TIMER_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_timer_count=%s payload_job_count=%s",
            tostring(result_recipe_id),
            tostring(plan_recipe_id),
            tostring(cast_id),
            tostring(source_timer_count),
            tostring(payload_job_count)
        ))
    elseif source_kind == "pierce" then
        runtime_stats.inc("pierce_timer_source_ok")
        log.info(string.format(
            "SPELLFORGE_PIERCE_TIMER_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_timer_count=%s payload_job_count=%s",
            tostring(result_recipe_id),
            tostring(plan_recipe_id),
            tostring(cast_id),
            tostring(source_timer_count),
            tostring(payload_job_count)
        ))
    end
end

local function modifierKindsInclude(modifier_kinds, expected_kind)
    for _, kind in ipairs(modifier_kinds or {}) do
        if kind == expected_kind then
            return true
        end
        if kind == "speed_plus_size_plus"
            and (expected_kind == "speed_plus" or expected_kind == "size_plus") then
            return true
        end
    end
    return false
end

local function eventSourceTimerPlannerOptions(binding, options)
    local modifier_kinds = binding and binding.payload_modifier_kinds or nil
    local has_speed_modifier = modifierKindsInclude(modifier_kinds, "speed_plus")
    local has_size_modifier = modifierKindsInclude(modifier_kinds, "size_plus")
    return {
        allow_payload_multicast = binding and binding.payload_multicast == true
            or options.force_payload_multicast_enabled == true,
        allow_payload_pattern = binding and binding.payload_pattern == true
            or options.force_payload_pattern_enabled == true,
        allow_payload_launch_modifiers = binding and binding.has_payload_modifier == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true
            or options.force_speed_plus_enabled == true
            or (has_speed_modifier == true and options.force_speed_plus_disabled ~= true),
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true
            or options.force_size_plus_enabled == true
            or (has_size_modifier == true and options.force_size_plus_disabled ~= true),
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        chaos_budget_profile = options.chaos_budget_profile,
    }
end

local function eventSourceTimerMaturityPlan(plan, binding, index, options)
    local event = {
        event_kind = "timer_matured",
        source_slot_id = binding.source_slot_id,
        source_helper_engine_id = binding.source_helper_engine_id,
        source_prefix_opcode = binding.source_prefix_opcode,
        source_postfix_opcode = "Timer",
        cast_id = binding.cast_id,
        source_job_id = binding.source_job_id or ("dry_event_source_timer_job:" .. tostring(index)),
        parent_job_id = binding.source_job_id or ("dry_event_source_timer_job:" .. tostring(index)),
        timer_id = "dry_event_source_timer:" .. tostring(binding.cast_id) .. ":" .. tostring(index),
        timer_delay_ticks = binding.timer_delay_ticks,
        timer_delay_seconds = binding.timer_seconds,
        branch_scope = binding.branch_scope,
        branch_parent_id = binding.branch_parent_id,
        bounce_id = binding.bounce_id,
        bounce_max = binding.bounce_max,
        bounce_power = binding.bounce_power,
        pierce_id = binding.pierce_id,
        pierce_limit = binding.pierce_limit,
    }
    return ir_runtime_adapter.planEvent(binding, plan, event, eventSourceTimerPlannerOptions(binding, options))
end

local function tryEventSourceTimerDispatch(compiled, launch_payload, options)
    local bounds = compiled.plan and compiled.plan.bounds or nil
    local source_kind = eventSourceKindFromBounds(bounds)
    runtime_stats.inc("event_source_timer_attempts")
    if source_kind == nil then
        return eventSourceTimerRejected(nil, "event_source_timer_unsupported", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if source_kind == "bounce" then
        if options.force_bounce_disabled == true then
            return eventSourceTimerRejected(source_kind, "live_bounce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_disabled_rejections")
        end
        if options.force_bounce_enabled ~= true and not dev.liveBounceEnabled() then
            return eventSourceTimerRejected(source_kind, "live_bounce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_disabled_rejections")
        end
    elseif source_kind == "pierce" then
        if options.force_pierce_disabled == true then
            return eventSourceTimerRejected(source_kind, "live_pierce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_disabled_rejections")
        end
        if options.force_pierce_enabled ~= true and not dev.livePierceEnabled() then
            return eventSourceTimerRejected(source_kind, "live_pierce_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_disabled_rejections")
        end
    end
    if options.force_timer_disabled == true
        or (options.force_timer_enabled ~= true and not dev.liveTimerEnabled()) then
        return eventSourceTimerRejected(source_kind, "live_timer_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_timer_disabled_rejections")
    end

    local capabilities = sfp_adapter.capabilities()
    if source_kind == "bounce" then
        if not capabilities.has_setSpellBounce
            or not capabilities.has_setSpellDetonateOnActor
            or not capabilities.has_detonateSpellAtPos
            or not capabilities.has_cancelSpell then
            return eventSourceTimerRejected(source_kind, "sfp_bounce_missing", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_bounce_capability_rejections")
        end
    elseif source_kind == "pierce" then
        if not capabilities.has_setSpellPiercing and not capabilities.has_setSpellPhysics then
            return eventSourceTimerRejected(source_kind, "sfp_pierce_event_unavailable", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_pierce_capability_rejections")
        end
    end

    local prepared, prepare_reason, prepare_details = launch_modifier_policy.prepareCachedPlanPayloadModifiers(compiled.recipe_id, {
        source_opcode = "Timer",
        apply_size_to_specs = true,
        allow_payload_launch_modifiers = true,
        allow_payload_detonate = true,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
    })
    if not prepared then
        return eventSourceTimerRejected(source_kind, prepare_reason or "payload_modifier_combo_deferred", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(prepare_details),
            errors = prepare_details and prepare_details.errors,
        })
    end

    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id, { limits = options.budget_limits })
    if not attached_specs.ok then
        return eventSourceTimerRejected(source_kind, "helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        })
    end

    local plan = attached_specs.plan
    local policy_options = sourcePolicyOptions(options, source_kind)
    policy_options.allow_event_source_fanout = true
    policy_options.allow_event_source_modifier_combo = true
    policy_options.max_source_modifier_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_projectiles = limits.MAX_PROJECTILES_PER_CAST
    local source_policies_by_slot = {}
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" then
            local inspected = launch_modifier_policy.inspectSourceEntry(
                plan,
                plan and plan.runtime_ir or nil,
                slot,
                policy_options
            )
            if inspected.ok ~= true then
                return eventSourceTimerRejected(source_kind, inspected.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = slot.slot_id,
                })
            end
            source_policies_by_slot[slot.slot_id] = inspected
        end
    end

    local materialized = helper_records.materialize({
        recipe_id = plan.recipe_id,
        specs = plan.helper_specs,
    }, { limits = options.budget_limits })
    if not materialized.ok then
        return eventSourceTimerRejected(source_kind, "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        })
    end
    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    local selected_helpers, select_reason, has_timer_payload = collectEventSourceFanoutHelpers(plan, source_kind, {
        max_projectiles = options.max_projectiles or limits.MAX_PROJECTILES_PER_CAST,
        continuation_kind = "Timer",
    })
    if not selected_helpers then
        return eventSourceTimerRejected(source_kind, select_reason or "event_source_timer_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if has_timer_payload ~= true then
        return eventSourceTimerRejected(source_kind, "missing_timer_payload", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_timer_payload_missing")
    end

    local primary_mode, pattern_kind, pattern_op = sourceModifierClosurePrefix(selected_helpers)
    if primary_mode == "multicast" or primary_mode == "spread" or primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return eventSourceTimerRejected(source_kind, "live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "event_source_timer_gate_rejections")
        end
    end
    if primary_mode == "spread" or primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return eventSourceTimerRejected(source_kind, "live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "event_source_timer_gate_rejections")
        end
    end

    local pattern_info, pattern_err = computePatternInfo(
        primary_mode,
        pattern_kind,
        pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return eventSourceTimerRejected(source_kind, pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "event_source_timer_pattern_rejections")
    end

    local payloads_by_slot = {}
    local max_payload_fanout_count = 1
    local payload_job_count = 0
    for _, pair in ipairs(selected_helpers) do
        local payload_result = eventSourcePayloadForSource(plan, pair, source_kind, options, "Timer")
        if payload_result.ok ~= true then
            return eventSourceTimerRejected(source_kind, payload_result.rejection_reason or "nested_payload_runtime_deferred", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = pair and pair.slot and pair.slot.slot_id or nil,
            })
        end
        payloads_by_slot[pair.slot.slot_id] = payload_result
        max_payload_fanout_count = math.max(max_payload_fanout_count, tonumber(payload_result.payload_fanout_count) or 1)
        payload_job_count = payload_job_count + (tonumber(payload_result.payload_count) or 0)
    end

    local budget = launch_modifier_policy.eventSourceTimerBudget(
        plan,
        plan and plan.runtime_ir or nil,
        selected_helpers[1] and selected_helpers[1].slot or nil,
        {
            source_kind = source_kind,
            source_fanout_count = #selected_helpers,
            timer_payload_fanout_count = max_payload_fanout_count,
            max_event_source_timer_jobs_per_cast = options.max_event_source_timer_jobs_per_cast,
            max_timer_payload_jobs_per_cast = source_kind == "bounce"
                and options.max_bounce_payload_jobs_per_cast
                or options.max_pierce_payload_jobs_per_cast,
            max_payload_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
        }
    )
    if budget.ok ~= true then
        return eventSourceTimerRejected(source_kind, budget.rejection_reason or "event_source_timer_budget_exceeded", {
            plan_recipe_id = compiled.recipe_id,
            source_fanout_count = #selected_helpers,
            timer_payload_fanout_count = max_payload_fanout_count,
        }, "event_source_timer_budget_reject")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
    local bindings = {}
    local slot_ids = {}
    local helper_engine_ids = {}
    local timer_ids = {}
    local event_source_ids = {}
    local branch_parent_id = string.format("%s_timer:%s", tostring(source_kind), tostring(cast_id))
    local source_prefix_opcode = source_kind == "bounce" and "Bounce" or "Pierce"

    for index, pair in ipairs(selected_helpers) do
        local source_slot = pair and pair.slot
        local source_helper = pair and pair.helper
        local job = job_inputs[index]
        local inspected = source_slot and source_policies_by_slot[source_slot.slot_id] or nil
        if type(inspected) ~= "table" then
            return eventSourceTimerRejected(source_kind, "missing_source_policy", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot and source_slot.slot_id or nil,
            })
        end
        local applied = launch_modifier_policy.applySourcePolicyToLaunchSpec(
            plan,
            plan and plan.runtime_ir or nil,
            source_slot,
            job,
            { event_kind = source_kind .. "_source_timer" },
            {
                policy_kind = "source",
                inspection = inspected,
            }
        )
        if applied == nil or applied.ok ~= true then
            return eventSourceTimerRejected(source_kind, applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot and source_slot.slot_id or nil,
            })
        end

        local payload_result = payloads_by_slot[source_slot.slot_id] or {}
        local timer_seconds, timer_delay_ticks, timer_delay_capped, timer_delay_err = timerPostfixInfo(source_slot)
        if timer_delay_err then
            return eventSourceTimerRejected(source_kind, timer_delay_err, {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = source_slot.slot_id,
            })
        end
        local source_op, event_count = eventSourceOpAndCount(source_kind, source_slot)
        local event_source_id = string.format(
            "%s_timer:%s:%s:%s",
            tostring(source_kind),
            tostring(cast_id),
            tostring(source_slot.slot_id),
            tostring(index)
        )
        local binding = {
            plan = plan,
            recipe_id = compiled.recipe_id,
            display_recipe_id = result_recipe_id,
            cast_id = cast_id,
            source_slot_id = source_slot.slot_id,
            source_helper_engine_id = source_helper.engine_id,
            source_prefix_opcode = source_prefix_opcode,
            source_postfix_opcode = "Timer",
            payload_slot_id = payload_result.payload_slot_id,
            payload_helper_engine_id = payload_result.payload_helper_engine_id,
            payloads = payload_result.payloads,
            payload_slot_ids = payload_result.payload_slot_ids,
            payload_helper_engine_ids = payload_result.payload_helper_engine_ids,
            payload_count = payload_result.payload_count,
            payload_group_key = payload_result.payload_group_key,
            payload_multicast = payload_result.payload_multicast == true,
            payload_pattern = payload_result.payload_pattern == true,
            payload_pattern_kind = payload_result.payload_pattern_kind,
            payload_pattern_op = payload_result.payload_pattern_op,
            has_timer_payload = true,
            has_trigger_payload = false,
            has_payload_modifier = payload_result.has_payload_modifier == true,
            has_payload_homing = payload_result.has_payload_homing == true,
            payload_modifier_kinds = payload_result.payload_modifier_kinds,
            actor = launch_payload.actor or launch_payload.sender,
            start_pos = launch_payload.start_pos,
            direction = job.payload and job.payload.direction or launch_payload.direction,
            hit_object = launch_payload.hit_object,
            mute_audio = launch_payload.mute_audio or launch_payload.muteAudio,
            mute_light = launch_payload.mute_light or launch_payload.muteLight,
            max_payload_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
            max_live_launches_per_tick = options.max_live_launches_per_tick,
            chaos_budget_profile = options.chaos_budget_profile,
            allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
            branch_scope = branch_parent_id,
            branch_parent_id = branch_parent_id,
            branch_id = string.format("%s:%s", tostring(branch_parent_id), tostring(source_slot.slot_id)),
            branch_kind = source_kind .. "_timer_source",
            branch_index = index,
            branch_count = #selected_helpers,
            timer_seconds = timer_seconds,
            timer_delay_ticks = timer_delay_ticks,
            timer_delay_capped = timer_delay_capped == true,
        }
        if source_kind == "bounce" then
            binding.bounce_id = event_source_id
            binding.bounce_max = event_count
            binding.bounce_power = clampBouncePowerForFanout(source_op and source_op.params and source_op.params.power)
            live_bounce.decorateSourceJob(job, binding)
        else
            binding.pierce_id = event_source_id
            binding.pierce_limit = event_count
            live_pierce.decorateSourceJob(job, binding)
        end
        live_timer.decorateSourceJob(job, binding)
        bindings[index] = binding
        slot_ids[index] = source_slot.slot_id
        helper_engine_ids[index] = source_helper.engine_id
        event_source_ids[index] = event_source_id
    end

    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("event_source_timer_qualified")
    if primary_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif primary_mode == "spread" or primary_mode == "burst" then
        patternQualified(pattern_kind, #selected_helpers)
    end
    logEventSourceTimerOk(source_kind, result_recipe_id, compiled.recipe_id, cast_id, #selected_helpers, payload_job_count, primary_mode)

    if options.dry_run == true then
        local matured_timer_count = 0
        local planned_payload_job_count = 0
        local fallback_count = 0
        local mismatch_count = 0
        local maturity_plans = {}
        for index, binding in ipairs(bindings) do
            local planned = eventSourceTimerMaturityPlan(plan, binding, index, options)
            maturity_plans[index] = planned
            if planned and planned.ok == true and planned.job_plan and planned.job_plan.ok == true then
                matured_timer_count = matured_timer_count + 1
                planned_payload_job_count = planned_payload_job_count + (tonumber(planned.job_plan.planned_job_count) or 0)
            else
                fallback_count = fallback_count + 1
            end
        end
        runtime_stats.inc("event_source_timer_scheduled", #selected_helpers)
        runtime_stats.inc("event_source_timer_matured", matured_timer_count)
        runtime_stats.inc("event_source_timer_payload_enqueued", planned_payload_job_count)
        log.info(string.format(
            "SPELLFORGE_EVENT_SOURCE_TIMER_SCHEDULED source_kind=%s source_timer_count=%s payload_job_count=%s synthetic=true",
            tostring(source_kind),
            tostring(#selected_helpers),
            tostring(payload_job_count)
        ))
        log.info(string.format(
            "SPELLFORGE_EVENT_SOURCE_TIMER_MATURED source_kind=%s matured_timer_count=%s synthetic=true",
            tostring(source_kind),
            tostring(matured_timer_count)
        ))
        log.info(string.format(
            "SPELLFORGE_EVENT_SOURCE_TIMER_PAYLOAD_ENQUEUED source_kind=%s payload_job_count=%s synthetic=true",
            tostring(source_kind),
            tostring(planned_payload_job_count)
        ))
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_kind = source_kind,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            event_source_ids = event_source_ids,
            jobs = job_inputs,
            bindings = bindings,
            maturity_plans = maturity_plans,
            dispatch_count = #selected_helpers,
            source_dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            source_fanout_count = #selected_helpers,
            source_timer_count = #selected_helpers,
            matured_timer_count = matured_timer_count,
            payload_job_count = planned_payload_job_count,
            expected_payload_job_count = payload_job_count,
            primary_mode = primary_mode,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            timer_payload_fanout_count = max_payload_fanout_count,
            event_budget_total = budget.total_timer_jobs,
            event_budget_cap = budget.source_cap or budget.shared_cap,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            fallback_count = fallback_count,
            mismatch_count = mismatch_count,
            simple_note = "event_source_timer",
            live_mode = "event_source_timer",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for index, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return eventSourceTimerRejected(source_kind, "enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[index] = enqueue.job_id
        bindings[index].source_job_id = enqueue.job_id
        local registered = nil
        if source_kind == "bounce" then
            registered = live_bounce.registerBinding(bindings[index])
        else
            registered = live_pierce.registerBinding(bindings[index])
        end
        if not registered then
            orchestrator.cancel(enqueue.job_id)
            return eventSourceTimerRejected(source_kind, source_kind .. "_binding_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = bindings[index].source_slot_id,
                cast_id = cast_id,
            })
        end
    end
    runtime_stats.inc("event_source_timer_source_jobs_enqueued", #job_ids)

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "event-source Timer helper launch job did not complete", {
                stage = "event_source_timer_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
        local binding = bindings[index]
        binding.source_projectile_id = summary.projectile_id
        binding.source_user_data = summary.launch_user_data
        local timer_launch_payload = {}
        for key, value in pairs(launch_payload or {}) do
            timer_launch_payload[key] = value
        end
        timer_launch_payload.direction = job_inputs[index] and job_inputs[index].payload and job_inputs[index].payload.direction
            or launch_payload.direction
        local resolution, resolution_err = live_timer.computeResolution(timer_launch_payload, binding)
        if not resolution then
            return eventSourceTimerRejected(source_kind, "timer_resolution_failed", {
                plan_recipe_id = compiled.recipe_id,
                error = resolution_err,
            }, "live_timer_payload_route_failed")
        end
        binding.resolution = resolution
        local schedule = live_timer.schedulePayload(binding, {
            source_projectile_id = summary.projectile_id,
            source_user_data = summary.launch_user_data,
            delay_ticks_override = options.timer_delay_ticks_override,
            delay_seconds_override = options.timer_delay_seconds_override,
            ttl_ticks_override = options.timer_ttl_ticks_override,
            ttl_seconds_override = options.timer_ttl_seconds_override,
            duplicate_key_suffix = binding.branch_id,
        })
        if not schedule.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(schedule.error or "event-source Timer payload schedule failed", {
                stage = "event_source_timer_payload_schedule",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = binding.source_slot_id,
                helper_engine_id = binding.source_helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
        timer_ids[index] = schedule.timer_id
    end
    runtime_stats.inc("event_source_timer_scheduled", #timer_ids)
    log.info(string.format(
        "SPELLFORGE_EVENT_SOURCE_TIMER_SCHEDULED source_kind=%s source_timer_count=%s payload_job_count=%s synthetic=false",
        tostring(source_kind),
        tostring(#timer_ids),
        tostring(payload_job_count)
    ))

    runtime_stats.inc("live_2_2c_dispatch_ok")
    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        source_kind = source_kind,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        event_source_ids = event_source_ids,
        projectile_ids = projectile_ids,
        timer_ids = timer_ids,
        job_ids = job_ids,
        jobs = jobs,
        dispatch_count = #job_ids,
        source_dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        source_fanout_count = #selected_helpers,
        source_timer_count = #timer_ids,
        payload_job_count = payload_job_count,
        timer_payload_fanout_count = max_payload_fanout_count,
        event_budget_total = budget.total_timer_jobs,
        runtime = "2.2c_live_helper",
        fallback = false,
        simple_note = "event_source_timer",
        live_mode = "event_source_timer",
        cast_id = cast_id,
    }
end

local function trySourceModifierClosureDispatch(compiled, launch_payload, options)
    runtime_stats.inc("launch_modifier_closure_attempts")
    local bounds = compiled.plan and compiled.plan.bounds or nil
    local expected_kind = sourceModifierKindFromBounds(bounds)
    local group = compiled.plan and compiled.plan.groups and compiled.plan.groups[1] or nil
    if expected_kind == nil then
        return sourceModifierClosureRejected(expected_kind, "source_modifier_unsupported_prefix", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if type(group) ~= "table" or not isTargetRange(group.range) then
        return sourceModifierClosureRejected(expected_kind, "not_target_range", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local attached = plan_cache.attachHelperSpecs(compiled.recipe_id, { limits = options.budget_limits })
    if not attached.ok then
        return sourceModifierClosureRejected(expected_kind, "helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached),
            errors = attached.errors,
        })
    end

    local plan = attached.plan
    local source_policies_by_slot = {}
    local policy_options = sourcePolicyOptions(options, nil)
    policy_options.max_source_modifier_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_fanout = limits.MAX_PROJECTILES_PER_CAST
    policy_options.max_projectiles = limits.MAX_PROJECTILES_PER_CAST
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" and hasSourceLaunchModifier(slot) then
            local inspected = launch_modifier_policy.inspectSourceEntry(
                plan,
                plan and plan.runtime_ir or nil,
                slot,
                policy_options
            )
            if inspected.ok ~= true then
                return sourceModifierClosureRejected(expected_kind, inspected.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = slot.slot_id,
                })
            end
            source_policies_by_slot[slot.slot_id] = inspected
        end
    end

    local materialized = helper_records.materialize({
        recipe_id = plan.recipe_id,
        specs = plan.helper_specs,
    }, { limits = options.budget_limits })
    if not materialized.ok then
        return sourceModifierClosureRejected(expected_kind, "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        })
    end
    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    local selected_helpers, materialized_reason = collectPrimaryHelpers(plan)
    if not selected_helpers then
        return sourceModifierClosureRejected(expected_kind, materialized_reason or "helper_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local primary_mode, pattern_kind, pattern_op = sourceModifierClosurePrefix(selected_helpers)
    if primary_mode == "multicast" or primary_mode == "spread" or primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return sourceModifierClosureRejected(expected_kind, "live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "launch_modifier_closure_gate_rejections")
        end
    end
    if primary_mode == "spread" or primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return sourceModifierClosureRejected(expected_kind, "live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "launch_modifier_closure_gate_rejections")
        end
    end

    local pattern_info, pattern_err = computePatternInfo(
        primary_mode,
        pattern_kind,
        pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return sourceModifierClosureRejected(expected_kind, pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "launch_modifier_closure_pattern_rejections")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
    for index, pair in ipairs(selected_helpers) do
        local source_slot = pair and pair.slot
        local inspected = source_slot and source_policies_by_slot[source_slot.slot_id] or nil
        local job_input = job_inputs[index]
        if type(inspected) ~= "table" then
            return sourceModifierClosureRejected(expected_kind, "missing_source_policy", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_slot and source_slot.slot_id or nil,
            })
        end
        local applied = launch_modifier_policy.applySourcePolicyToLaunchSpec(
            plan,
            plan and plan.runtime_ir or nil,
            source_slot,
            job_input,
            { event_kind = "source" },
            {
                policy_kind = "source",
                inspection = inspected,
            }
        )
        if applied == nil or applied.ok ~= true then
            return sourceModifierClosureRejected(expected_kind, applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_slot and source_slot.slot_id or nil,
            })
        end
    end

    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local pattern_direction_keys = {}
    for index, pair in ipairs(selected_helpers) do
        slot_ids[index] = pair.helper.slot_id
        helper_engine_ids[index] = pair.helper.engine_id
        emission_indexes[index] = pair.slot.emission_index or pair.helper.emission_index or index
        if pattern_info and pattern_info.direction_keys then
            pattern_direction_keys[index] = pattern_info.direction_keys[index]
        end
    end

    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("launch_modifier_closure_qualified")
    if primary_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif primary_mode == "spread" or primary_mode == "burst" then
        patternQualified(pattern_kind, #selected_helpers)
    end

    local first_job_input = job_inputs[1] or {}
    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            source_modifier_kind = first_job_input.source_modifier_kind,
            speed_plus = first_job_input.speed_plus,
            speed_plus_speed = first_job_input.speed_plus_speed,
            speed_plus_max_speed = first_job_input.speed_plus_max_speed,
            size_plus = first_job_input.size_plus,
            size_plus_base_area = first_job_input.size_plus_base_area,
            size_plus_area = first_job_input.size_plus_area,
            source_modifier_primary_mode = primary_mode,
            simple_note = "launch_modifier_closure",
            live_mode = "source_modifier_closure",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for _, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return sourceModifierClosureRejected(expected_kind, "enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end
    runtime_stats.inc("launch_modifier_closure_jobs_enqueued", #job_ids)

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "launch modifier closure helper launch job did not complete", {
                stage = "launch_modifier_closure_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    local first_job = jobs[1] or {}
    log.info(string.format(
        "SPELLFORGE_LAUNCH_MODIFIER_CLOSURE_DISPATCH_OK recipe_id=%s plan_recipe_id=%s dispatch_count=%s primary_mode=%s source_modifier_kind=%s pattern_kind=%s first_slot_id=%s first_helper_engine_id=%s projectile_count=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(#job_ids),
        tostring(primary_mode),
        tostring(first_job.source_modifier_kind),
        tostring(pattern_info and pattern_info.pattern_kind or nil),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(projectile_id_count)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")
    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
        pattern_count = pattern_info and pattern_info.pattern_count or nil,
        pattern_direction_keys = pattern_direction_keys,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        job_status = first_job.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        source_modifier_kind = first_job.source_modifier_kind,
        slot_count = plan.slot_count or #plan.emission_slots,
        helper_record_count = plan.helper_record_count or #plan.helper_records,
        speed_plus = first_job.speed_plus,
        speed_plus_speed = first_job.speed_plus_speed,
        speed_plus_max_speed = first_job.speed_plus_max_speed,
        size_plus = first_job.size_plus,
        size_plus_base_area = first_job.size_plus_base_area,
        size_plus_area = first_job.size_plus_area,
        source_modifier_primary_mode = primary_mode,
        simple_note = "launch_modifier_closure",
        live_mode = "source_modifier_closure",
    }
end

local function tryHomingDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_homing_attempts")
    if options.force_homing_disabled == true then
        return homingRejected("live_homing_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_homing_disabled_rejections")
    end
    if options.force_homing_enabled ~= true and not dev.liveHomingEnabled() then
        return homingRejected("live_homing_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_homing_disabled_rejections")
    end

    local group = compiled.plan and compiled.plan.groups and compiled.plan.groups[1] or nil
    if type(group) ~= "table" or not isTargetRange(group.range) then
        return homingRejected("not_target_range", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id, { limits = options.budget_limits })
    if not attached_specs.ok then
        return homingRejected("helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        })
    end

    local plan = attached_specs.plan
    local source_policies_by_slot = {}
    local homing_policies_by_slot = {}
    local source_policy_options = sourcePolicyOptions(options, nil)
    source_policy_options.max_source_modifier_fanout = limits.MAX_PROJECTILES_PER_CAST
    source_policy_options.max_fanout = limits.MAX_PROJECTILES_PER_CAST
    source_policy_options.max_projectiles = limits.MAX_PROJECTILES_PER_CAST
    local homing_policy_options = homingPolicyOptions(
        options,
        "source",
        compiled.plan and compiled.plan.bounds and compiled.plan.bounds.static_emission_count or nil
    )
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" then
            if hasSourceLaunchModifier(slot) then
                local inspected = launch_modifier_policy.inspectSourceEntry(
                    plan,
                    plan and plan.runtime_ir or nil,
                    slot,
                    source_policy_options
                )
                if inspected.ok ~= true then
                    return homingRejected(inspected.rejection_reason or "source_modifier_unsupported_prefix", {
                        plan_recipe_id = compiled.recipe_id,
                        slot_id = slot.slot_id,
                    })
                end
                source_policies_by_slot[slot.slot_id] = inspected
            end
            if hasSourceHoming(slot) then
                local inspected = homing_launch_policy.inspectSourceEntry(
                    plan,
                    plan and plan.runtime_ir or nil,
                    slot,
                    homing_policy_options
                )
                if inspected.ok ~= true then
                    return homingRejected(inspected.rejection_reason or "homing_nested_runtime_deferred", {
                        plan_recipe_id = compiled.recipe_id,
                        slot_id = slot.slot_id,
                    }, "live_homing_unsupported_combo_rejections")
                end
                homing_policies_by_slot[slot.slot_id] = inspected
            end
        end
    end

    local materialized = helper_records.materialize({
        recipe_id = plan.recipe_id,
        specs = plan.helper_specs,
    }, { limits = options.budget_limits })
    if not materialized.ok then
        return homingRejected("helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        })
    end
    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    local selected_helpers, materialized_reason = collectPrimaryHelpers(plan)
    if not selected_helpers then
        local counter = nil
        if string.find(tostring(materialized_reason), "payload", 1, true)
            or string.find(tostring(materialized_reason), "postfix", 1, true)
            or string.find(tostring(materialized_reason), "source", 1, true)
            or string.find(tostring(materialized_reason), "parent", 1, true) then
            counter = "live_homing_payload_rejections"
        end
        return homingRejected(materialized_reason or "helper_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        }, counter)
    end

    local primary_mode, pattern_kind, pattern_op = sourceModifierClosurePrefix(selected_helpers)
    if primary_mode == "multicast" or primary_mode == "spread" or primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return homingRejected("live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_homing_unsupported_combo_rejections")
        end
    end
    if primary_mode == "spread" or primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return homingRejected("live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_homing_unsupported_combo_rejections")
        end
    end

    local pattern_info, pattern_err = computePatternInfo(
        primary_mode,
        pattern_kind,
        pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return homingRejected(pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "live_homing_target_rejections")
    end
    local soft_homing_requested = options.soft_homing_probe == true
        or options.force_soft_homing_enabled == true
    local soft_homing_available = options.force_soft_homing_disabled ~= true
        and dev.liveSoftHomingEnabled()
    local homing_v2_manager_enabled = type(dev.liveHomingV2ManagerEnabled) == "function"
        and dev.liveHomingV2ManagerEnabled() == true
    local use_soft_homing = soft_homing_requested
        or (soft_homing_available and #selected_helpers == 1 and not homing_v2_manager_enabled)
    local soft_homing_cap = tonumber(options.max_soft_homing_registrations_per_cast)
        or tonumber(limits.MAX_SOFT_HOMING_REGISTRATIONS_PER_CAST)
        or tonumber(limits.MAX_HOMING_PROJECTILES_ACTIVE)
        or 1
    if soft_homing_requested and #selected_helpers > soft_homing_cap then
        return homingRejected("homing_soft_high_fanout_deferred", {
            plan_recipe_id = compiled.recipe_id,
            fanout_count = #selected_helpers,
            max = soft_homing_cap,
        }, "live_homing_unsupported_combo_rejections")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_homing_qualified")

    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
    for index, pair in ipairs(selected_helpers) do
        local source_slot = pair and pair.slot
        local job_input = job_inputs[index]
        local source_policy = source_slot and source_policies_by_slot[source_slot.slot_id] or nil
        if type(source_policy) == "table" then
            local applied = launch_modifier_policy.applySourcePolicyToLaunchSpec(
                plan,
                plan and plan.runtime_ir or nil,
                source_slot,
                job_input,
                { event_kind = "source" },
                {
                    policy_kind = "source",
                    inspection = source_policy,
                }
            )
            if applied == nil or applied.ok ~= true then
                return homingRejected(applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = source_slot and source_slot.slot_id or nil,
                })
            end
        end
        local homing_policy = source_slot and homing_policies_by_slot[source_slot.slot_id] or nil
        if type(homing_policy) ~= "table" then
            return homingRejected("homing_missing", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_slot and source_slot.slot_id or nil,
            }, "live_homing_unsupported_combo_rejections")
        end
        local applied = applyHomingPolicyToJob({
            plan = plan,
            source_slot = source_slot,
            homing_policy = homing_policy,
            fanout_count = #selected_helpers,
            apply_homing_direction = options.force_homing_launch_direction == true,
        }, job_input, "source", launch_payload, options)
        if applied == nil or applied.ok ~= true then
            return homingRejected(applied and applied.rejection_reason or "homing_target_missing", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_slot and source_slot.slot_id or nil,
            }, "live_homing_target_rejections")
        end
        if use_soft_homing then
            job_input.forceVec = nil
            job_input.homing_mode = options.soft_homing_probe == true and "soft_redirect_probe" or "soft_redirect"
            job_input.homing_field = "redirectSpell"
            job_input.homing_force = nil
            job_input.homing_force_key = nil
            if type(job_input.payload) == "table" then
                job_input.payload.forceVec = nil
                job_input.payload.homing_mode = job_input.homing_mode
                job_input.payload.homing_field = job_input.homing_field
                job_input.payload.homing_force = nil
                job_input.payload.homing_force_key = nil
            end
        end
    end
    local homing_info = job_inputs[1] or {}
    local launch_homing_info = job_inputs[1] or {}
    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local pattern_direction_keys = {}
    for index, pair in ipairs(selected_helpers) do
        slot_ids[index] = pair.helper.slot_id
        helper_engine_ids[index] = pair.helper.engine_id
        emission_indexes[index] = pair.slot.emission_index or pair.helper.emission_index or index
        if pattern_info and pattern_info.direction_keys then
            pattern_direction_keys[index] = pattern_info.direction_keys[index]
        end
    end

    log.info(string.format(
        "SPELLFORGE_LIVE_HOMING_QUALIFIED recipe_id=%s plan_recipe_id=%s cast_id=%s slot_id=%s helper_engine_id=%s homing_mode=%s homing_field=%s homing_force=%s homing_target_id=%s homing_target_provider=%s homing_target_kind=%s homing_candidate_count=%s homing_actor_candidate_count=%s homing_creature_candidate_count=%s homing_npc_candidate_count=%s force_key=%s fanout_count=%s pattern_kind=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(launch_homing_info.homing_mode),
        tostring(launch_homing_info.homing_field),
        tostring(launch_homing_info.homing_force),
        tostring(launch_homing_info.homing_target_id),
        tostring(launch_homing_info.homing_target_provider),
        tostring(launch_homing_info.homing_target_kind),
        tostring(launch_homing_info.homing_candidate_count),
        tostring(launch_homing_info.homing_actor_candidate_count),
        tostring(launch_homing_info.homing_creature_candidate_count),
        tostring(launch_homing_info.homing_npc_candidate_count),
        tostring(launch_homing_info.homing_force_key),
        tostring(#selected_helpers),
        tostring(pattern_info and pattern_info.pattern_kind or nil)
    ))

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            jobs = job_inputs,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            source_modifier_kind = homing_info.source_modifier_kind,
            speed_plus = homing_info.speed_plus,
            size_plus = homing_info.size_plus,
            homing_mode = homing_info.homing_mode,
            homing_force = homing_info.homing_force,
            homing_field = homing_info.homing_field,
            homing_target_id = homing_info.homing_target_id,
            homing_target_provider = homing_info.homing_target_provider,
            homing_target_kind = homing_info.homing_target_kind,
            homing_candidate_count = homing_info.homing_candidate_count,
            homing_actor_candidate_count = homing_info.homing_actor_candidate_count,
            homing_creature_candidate_count = homing_info.homing_creature_candidate_count,
            homing_npc_candidate_count = homing_info.homing_npc_candidate_count,
            homing_force_key = homing_info.homing_force_key,
            homing_direction_key = homing_info.homing_direction_key,
            simple_note = "homing_policy",
            live_mode = "homing",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for _, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return homingRejected("enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end
    runtime_stats.inc("live_homing_jobs_mutated", #job_ids)
    chaos_budget.observe({
        jobs = #job_ids,
        queue = orchestrator.queueLength(),
        projectiles = #selected_helpers,
    })

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "homing helper launch job did not complete", {
                stage = "homing_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    local first_job = jobs[1] or {}
    local result_homing_mode = first_job.homing_mode or launch_homing_info.homing_mode
    local result_homing_field = first_job.homing_field or launch_homing_info.homing_field
    local result_homing_force = first_job.homing_force
    if result_homing_force == nil
        and first_job.homing_v2_launch_force_suppressed ~= true
        and first_job.homing_v2_payload_force_seeded ~= true then
        result_homing_force = launch_homing_info.homing_force
    end
    local result_homing_force_key = first_job.homing_force_key
    if result_homing_force_key == nil
        and first_job.homing_v2_launch_force_suppressed ~= true
        and first_job.homing_v2_payload_force_seeded ~= true then
        result_homing_force_key = launch_homing_info.homing_force_key
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_HOMING_APPLIED recipe_id=%s plan_recipe_id=%s cast_id=%s slot_id=%s helper_engine_id=%s homing_mode=%s homing_field=%s homing_force=%s homing_target_id=%s homing_target_provider=%s homing_target_kind=%s homing_candidate_count=%s homing_actor_candidate_count=%s homing_creature_candidate_count=%s homing_npc_candidate_count=%s force_key=%s job_id=%s projectile_id=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(result_homing_mode),
        tostring(result_homing_field),
        tostring(result_homing_force),
        tostring(launch_homing_info.homing_target_id),
        tostring(launch_homing_info.homing_target_provider),
        tostring(launch_homing_info.homing_target_kind),
        tostring(launch_homing_info.homing_candidate_count),
        tostring(launch_homing_info.homing_actor_candidate_count),
        tostring(launch_homing_info.homing_creature_candidate_count),
        tostring(launch_homing_info.homing_npc_candidate_count),
        tostring(result_homing_force_key),
        tostring(job_ids[1]),
        tostring(first_job.projectile_id)
    ))
    log.info(string.format(
        "SPELLFORGE_LIVE_HOMING_DISPATCH_OK recipe_id=%s plan_recipe_id=%s dispatch_count=%s first_slot_id=%s first_helper_engine_id=%s homing_mode=%s homing_field=%s homing_force=%s homing_target_id=%s homing_target_provider=%s homing_target_kind=%s homing_candidate_count=%s homing_actor_candidate_count=%s homing_creature_candidate_count=%s homing_npc_candidate_count=%s force_key=%s projectile_count=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(#job_ids),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(result_homing_mode),
        tostring(result_homing_field),
        tostring(result_homing_force),
        tostring(launch_homing_info.homing_target_id),
        tostring(launch_homing_info.homing_target_provider),
        tostring(launch_homing_info.homing_target_kind),
        tostring(launch_homing_info.homing_candidate_count),
        tostring(launch_homing_info.homing_actor_candidate_count),
        tostring(launch_homing_info.homing_creature_candidate_count),
        tostring(launch_homing_info.homing_npc_candidate_count),
        tostring(result_homing_force_key),
        tostring(projectile_id_count)
    ))
    local soft_homing_probe = nil
    local soft_homing_runtime = nil
    if use_soft_homing and first_job.homing_v2_manager_attempted ~= true then
        local live_soft_homing = require("scripts.spellforge.global.live_soft_homing")
        local register_payload = {
            projectile_id = first_job.projectile_id,
            recipe_id = result_recipe_id,
            cast_id = cast_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            job_id = job_ids[1],
            caster = launch_payload.actor or launch_payload.sender,
            target_id = homing_info.homing_target_id,
            target_object = homing_info.homing_target_object,
            target_position = homing_info.homing_target_position,
            target_provider = homing_info.homing_target_provider,
            target_kind = homing_info.homing_target_kind,
            max_lifetime = options.soft_homing_max_lifetime_seconds,
        }
        if options.soft_homing_probe == true then
            soft_homing_probe = live_soft_homing.registerProbe(register_payload)
        else
            soft_homing_runtime = live_soft_homing.registerRuntime(register_payload)
        end
    elseif use_soft_homing and first_job.homing_v2_manager_attempted == true then
        if options.soft_homing_probe == true then
            soft_homing_probe = {
                ok = first_job.homing_v2_manager_registered == true,
                entry_id = first_job.homing_v2_manager_entry_id,
                error = first_job.homing_v2_manager_error,
            }
        else
            soft_homing_runtime = {
                ok = first_job.homing_v2_manager_registered == true,
                entry_id = first_job.homing_v2_manager_entry_id,
                error = first_job.homing_v2_manager_error,
            }
        end
    end
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        projectile_id_source = first_job.projectile_id_source,
        projectile_registered = first_job.projectile_registered == true,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        job_status = first_job.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        slot_count = plan.slot_count or #plan.emission_slots,
        helper_record_count = plan.helper_record_count or #plan.helper_records,
        effect_id = selected_helpers[1] and selected_helpers[1].slot.effects and selected_helpers[1].slot.effects[1] and selected_helpers[1].slot.effects[1].id or nil,
        pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
        pattern_count = pattern_info and pattern_info.pattern_count or nil,
        pattern_direction_keys = pattern_direction_keys,
        source_modifier_kind = first_job.source_modifier_kind,
        speed_plus = first_job.speed_plus,
        size_plus = first_job.size_plus,
        homing_mode = result_homing_mode,
        homing_force = result_homing_force,
        homing_field = result_homing_field,
        homing_target_id = launch_homing_info.homing_target_id,
        homing_target_provider = launch_homing_info.homing_target_provider,
        homing_target_kind = launch_homing_info.homing_target_kind,
        homing_candidate_count = launch_homing_info.homing_candidate_count,
        homing_actor_candidate_count = launch_homing_info.homing_actor_candidate_count,
        homing_creature_candidate_count = launch_homing_info.homing_creature_candidate_count,
        homing_npc_candidate_count = launch_homing_info.homing_npc_candidate_count,
        homing_force_key = result_homing_force_key,
        homing_direction_key = launch_homing_info.homing_direction_key,
        homing_launch_runtime_mode = first_job.homing_launch_runtime_mode,
        homing_v2_launch_force_suppressed = first_job.homing_v2_launch_force_suppressed == true,
        homing_v2_manager_attempted = first_job.homing_v2_manager_attempted == true,
        homing_v2_manager_registered = first_job.homing_v2_manager_registered == true,
        homing_v2_manager_entry_id = first_job.homing_v2_manager_entry_id,
        homing_v2_manager_error = first_job.homing_v2_manager_error,
        soft_homing_probe = soft_homing_probe,
        soft_homing_probe_registered = soft_homing_probe and soft_homing_probe.ok == true or false,
        soft_homing_probe_entry_id = soft_homing_probe and soft_homing_probe.entry_id or nil,
        soft_homing_probe_error = soft_homing_probe and soft_homing_probe.error or nil,
        soft_homing_runtime = soft_homing_runtime,
        soft_homing_runtime_registered = soft_homing_runtime and soft_homing_runtime.ok == true or false,
        soft_homing_runtime_entry_id = soft_homing_runtime and soft_homing_runtime.entry_id or nil,
        soft_homing_runtime_error = soft_homing_runtime and soft_homing_runtime.error or nil,
        simple_note = "homing_policy",
        live_mode = "homing",
    }
end

local function trySpeedPlusDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_speed_plus_attempts")
    if options.force_speed_plus_disabled == true then
        return speedPlusRejected("live_speed_plus_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_disabled_rejections")
    end
    if options.force_speed_plus_enabled ~= true and not dev.liveSpeedPlusEnabled() then
        return speedPlusRejected("live_speed_plus_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_disabled_rejections")
    end

    local speed_plan, speed_reason, speed_counter = live_speed_plus.selectV1Plan(compiled.plan)
    if not speed_plan then
        return speedPlusRejected(speed_reason or "speed_plus_v1_rejected", {
            plan_recipe_id = compiled.recipe_id,
        }, speed_counter)
    end
    if speed_plan.mutation and speed_plan.mutation.speed_plus_capped == true then
        runtime_stats.inc("live_speed_plus_value_capped")
    end

    if live_speed_plus.launchSpeedField() == nil then
        return speedPlusRejected("live_speed_plus_field_missing", {
            plan_recipe_id = compiled.recipe_id,
            speed_plus_mode = speed_plan.mutation and speed_plan.mutation.speed_plus_mode or nil,
            speed_plus_value = speed_plan.mutation and speed_plan.mutation.speed_plus_value or nil,
            speed_plus_multiplier = speed_plan.mutation and speed_plan.mutation.speed_plus_multiplier or nil,
            speed_plus_capped = speed_plan.mutation and speed_plan.mutation.speed_plus_capped or nil,
            launch_speed_field = nil,
            speed_plus_field_missing = true,
            live_mode = "speed_plus",
        }, "live_speed_plus_field_missing")
    end

    local group = compiled.plan and compiled.plan.groups and compiled.plan.groups[1] or nil
    if type(group) ~= "table" or not isTargetRange(group.range) then
        return speedPlusRejected("not_target_range", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    if speed_plan.primary_mode == "multicast" or speed_plan.primary_mode == "spread" or speed_plan.primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return speedPlusRejected("live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_speed_plus_unsupported_combo_rejections")
        end
    end
    if speed_plan.primary_mode == "spread" or speed_plan.primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return speedPlusRejected("live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_speed_plus_unsupported_combo_rejections")
        end
    end

    local attached = plan_cache.attachHelperRecords(compiled.recipe_id, { limits = options.budget_limits })
    if not attached.ok then
        return speedPlusRejected("helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached),
            errors = attached.errors,
        })
    end

    local selected_helpers, materialized_reason = collectPrimaryHelpers(attached.plan)
    if not selected_helpers then
        local counter = nil
        if string.find(tostring(materialized_reason), "payload", 1, true)
            or string.find(tostring(materialized_reason), "postfix", 1, true)
            or string.find(tostring(materialized_reason), "source", 1, true)
            or string.find(tostring(materialized_reason), "parent", 1, true) then
            counter = "live_speed_plus_payload_rejections"
        end
        return speedPlusRejected(materialized_reason or "helper_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        }, counter)
    end

    if speed_plan.primary_mode == "single" and #selected_helpers ~= 1 then
        return speedPlusRejected("slot_count_not_one", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_unsupported_combo_rejections")
    end
    if speed_plan.primary_mode == "multicast" and #selected_helpers <= 1 then
        return speedPlusRejected("multicast_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_unsupported_combo_rejections")
    end
    if (speed_plan.primary_mode == "spread" or speed_plan.primary_mode == "burst") and #selected_helpers <= 1 then
        return speedPlusRejected("pattern_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_unsupported_combo_rejections")
    end

    local pattern_info, pattern_err = computePatternInfo(
        speed_plan.primary_mode,
        speed_plan.pattern_kind,
        speed_plan.pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return speedPlusRejected(pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "live_speed_plus_unsupported_combo_rejections")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_speed_plus_qualified")
    if speed_plan.primary_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif speed_plan.primary_mode == "spread" or speed_plan.primary_mode == "burst" then
        patternQualified(speed_plan.pattern_kind, #selected_helpers)
    end

    local speed_info = speed_plan.mutation
    local source_policy_plan = nil
    if speed_plan.primary_mode == "single" then
        local source_entry = selected_helpers[1] and selected_helpers[1].slot or nil
        local source_policy = launch_modifier_policy.inspectSourceEntry(
            attached.plan,
            attached.plan and attached.plan.runtime_ir or nil,
            source_entry,
            sourcePolicyOptions(options, nil)
        )
        if source_policy.ok ~= true then
            return speedPlusRejected(source_policy.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_entry and source_entry.slot_id or nil,
            })
        end
        source_policy_plan = {
            plan = attached.plan,
            source_slot = source_entry,
            source_policy = source_policy,
        }
        speed_info = source_policy.mutations and source_policy.mutations.speed_plus or speed_info
    end
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info, nil, speed_info)
    if source_policy_plan ~= nil then
        for _, job_input in ipairs(job_inputs) do
            local applied = applySourcePolicyToJob(source_policy_plan, job_input, "source")
            if not applied or applied.ok ~= true then
                return speedPlusRejected(applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = job_input and job_input.slot_id or nil,
                })
            end
        end
    end
    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local pattern_direction_keys = {}
    for index, pair in ipairs(selected_helpers) do
        slot_ids[index] = pair.helper.slot_id
        helper_engine_ids[index] = pair.helper.engine_id
        emission_indexes[index] = pair.slot.emission_index or pair.helper.emission_index or index
        if pattern_info and pattern_info.direction_keys then
            pattern_direction_keys[index] = pattern_info.direction_keys[index]
        end
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            source_modifier_kind = job_inputs[1] and job_inputs[1].source_modifier_kind or nil,
            speed_plus_primary_mode = speed_plan.primary_mode,
            speed_plus_mode = speed_info and speed_info.speed_plus_mode or nil,
            speed_plus_value = speed_info and speed_info.speed_plus_value or nil,
            speed_plus_base_speed = speed_info and speed_info.speed_plus_base_speed or nil,
            speed_plus_multiplier = speed_info and speed_info.speed_plus_multiplier or nil,
            speed_plus_speed = speed_info and speed_info.speed_plus_speed or nil,
            speed_plus_max_speed = speed_info and speed_info.speed_plus_max_speed or nil,
            speed_plus_field = speed_info and speed_info.speed_plus_field or nil,
            speed_plus_capped = speed_info and speed_info.speed_plus_capped or nil,
            launch_speed_field = speed_info and speed_info.launch_speed_field or nil,
            launch_max_speed_field = speed_info and speed_info.launch_max_speed_field or nil,
            simple_note = "speed_plus_v1",
            live_mode = "speed_plus",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for _, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            if #job_ids > 0 then
                return bridgeError(enqueue.error or "enqueue failed", {
                    stage = "speed_plus_enqueue",
                    recipe_id = result_recipe_id,
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = job_input.slot_id,
                    helper_engine_id = job_input.helper_engine_id,
                    cast_id = cast_id,
                    job_ids = job_ids,
                    fallback_allowed = false,
                })
            end
            return speedPlusRejected("enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end
    runtime_stats.inc("live_speed_plus_jobs_mutated", #job_ids)
    if speed_plan.primary_mode == "multicast"
        or speed_plan.primary_mode == "spread"
        or speed_plan.primary_mode == "burst" then
        runtime_stats.inc("live_multicast_jobs_enqueued", #job_ids)
    end

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    local pending_job_count = 0
    local allow_pending_launch_jobs = options.allow_pending_launch_jobs == true
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "speed_plus helper launch job did not complete", {
                stage = "speed_plus_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    local first_job = jobs[1] or {}
    log.info(string.format(
        "SPELLFORGE_LIVE_SPEED_PLUS_DISPATCH_OK recipe_id=%s plan_recipe_id=%s dispatch_count=%s primary_mode=%s first_slot_id=%s first_helper_engine_id=%s speed=%s maxSpeed=%s multiplier=%s projectile_count=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(#job_ids),
        tostring(speed_plan.primary_mode),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(speed_info and speed_info.speed_plus_speed or nil),
        tostring(speed_info and speed_info.speed_plus_max_speed or nil),
        tostring(speed_info and speed_info.speed_plus_multiplier or nil),
        tostring(projectile_id_count)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
        pattern_count = pattern_info and pattern_info.pattern_count or nil,
        pattern_direction_keys = pattern_direction_keys,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        projectile_id_source = first_job.projectile_id_source,
        projectile_registered = first_job.projectile_registered == true,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        job_status = first_job.job_status,
        pending_launch_jobs = pending_job_count > 0,
        pending_job_count = pending_job_count,
        all_launch_jobs_complete = pending_job_count == 0,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        source_modifier_kind = first_job.source_modifier_kind,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        effect_id = selected_helpers[1] and selected_helpers[1].slot.effects and selected_helpers[1].slot.effects[1] and selected_helpers[1].slot.effects[1].id or nil,
        speed_plus_primary_mode = speed_plan.primary_mode,
        speed_plus_mode = speed_info and speed_info.speed_plus_mode or nil,
        speed_plus_value = speed_info and speed_info.speed_plus_value or nil,
        speed_plus_base_speed = speed_info and speed_info.speed_plus_base_speed or nil,
        speed_plus_multiplier = speed_info and speed_info.speed_plus_multiplier or nil,
        speed_plus_speed = speed_info and speed_info.speed_plus_speed or nil,
        speed_plus_max_speed = speed_info and speed_info.speed_plus_max_speed or nil,
        speed_plus_field = speed_info and speed_info.speed_plus_field or nil,
        speed_plus_capped = speed_info and speed_info.speed_plus_capped or nil,
        launch_speed_field = speed_info and speed_info.launch_speed_field or nil,
        launch_max_speed_field = speed_info and speed_info.launch_max_speed_field or nil,
        simple_note = "speed_plus_v1",
        live_mode = "speed_plus",
    }
end

local function trySizePlusDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_size_plus_attempts")
    if options.force_size_plus_disabled == true then
        return sizePlusRejected("live_size_plus_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_disabled_rejections")
    end
    if options.force_size_plus_enabled ~= true and not dev.liveSizePlusEnabled() then
        return sizePlusRejected("live_size_plus_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_disabled_rejections")
    end

    local size_plan, size_reason, size_counter = live_size_plus.selectV0Plan(compiled.plan)
    if not size_plan then
        return sizePlusRejected(size_reason or "size_plus_v0_rejected", {
            plan_recipe_id = compiled.recipe_id,
        }, size_counter)
    end

    local group = compiled.plan and compiled.plan.groups and compiled.plan.groups[1] or nil
    if type(group) ~= "table" or not isTargetRange(group.range) then
        return sizePlusRejected("not_target_range", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    if size_plan.primary_mode == "multicast" or size_plan.primary_mode == "spread" or size_plan.primary_mode == "burst" then
        if options.force_multicast_disabled == true
            or (options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled()) then
            return sizePlusRejected("live_multicast_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_size_plus_unsupported_combo_rejections")
        end
    end
    if size_plan.primary_mode == "spread" or size_plan.primary_mode == "burst" then
        if options.force_pattern_disabled == true
            or (options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled()) then
            return sizePlusRejected("live_spread_burst_disabled", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_size_plus_unsupported_combo_rejections")
        end
    end

    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id)
    if not attached_specs.ok then
        runtime_stats.inc("helper_records_attach_failed")
        return sizePlusRejected("helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        })
    end

    local source_policy_plan = nil
    local apply_result = nil
    local apply_err = nil
    if size_plan.primary_mode == "single" then
        local source_entry, source_reason = sourceModifierPolicySourceEntry(attached_specs.plan)
        if not source_entry then
            return sizePlusRejected(source_reason or "missing_source_slot", {
                plan_recipe_id = compiled.recipe_id,
            }, "live_size_plus_unsupported_combo_rejections")
        end
        local source_policy = launch_modifier_policy.inspectSourceEntry(
            attached_specs.plan,
            attached_specs.plan and attached_specs.plan.runtime_ir or nil,
            source_entry,
            sourcePolicyOptions(options, nil)
        )
        if source_policy.ok ~= true then
            return sizePlusRejected(source_policy.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = source_entry.slot_id,
            })
        end
        source_policy_plan = {
            plan = attached_specs.plan,
            source_slot = source_entry,
            source_policy = source_policy,
        }
        size_plan.mutation = source_policy.mutations and source_policy.mutations.size_plus or size_plan.mutation
        apply_result = source_policy.mutations and source_policy.mutations.size_plus_apply_result or nil
    else
        apply_result, apply_err = live_size_plus.applyToHelperSpecs(attached_specs.plan, size_plan.mutation)
    end
    if not apply_result then
        local counter = nil
        if apply_err == "size_plus_field_missing" then
            counter = "live_size_plus_field_missing"
        elseif apply_err == "size_plus_value_invalid" then
            counter = "live_size_plus_value_invalid"
        end
        return sizePlusRejected(apply_err or "size_plus_apply_failed", {
            plan_recipe_id = compiled.recipe_id,
            live_mode = "size_plus",
            size_plus_mode = size_plan.mutation and size_plan.mutation.size_plus_mode or nil,
            size_plus_value = size_plan.mutation and size_plan.mutation.size_plus_value or nil,
            size_plus_multiplier = size_plan.mutation and size_plan.mutation.size_plus_multiplier or nil,
            size_plus_field = size_plan.mutation and size_plan.mutation.size_plus_field or nil,
            size_plus_field_missing = apply_err == "size_plus_field_missing",
        }, counter)
    end

    runtime_stats.inc("live_size_plus_specs_mutated", apply_result.specs_mutated or 0)
    if size_plan.mutation and size_plan.mutation.size_plus_capped == true then
        runtime_stats.inc("live_size_plus_value_capped")
    end

    local materialized = helper_records.materialize({
        recipe_id = attached_specs.plan.recipe_id,
        specs = attached_specs.plan.helper_specs,
    })
    if not materialized.ok then
        runtime_stats.inc("helper_records_attach_failed")
        return sizePlusRejected("helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(materialized),
            errors = materialized.errors,
        })
    end

    local plan = attached_specs.plan
    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    local selected_helpers, materialized_reason = collectPrimaryHelpers(plan)
    if not selected_helpers then
        local counter = nil
        if string.find(tostring(materialized_reason), "payload", 1, true)
            or string.find(tostring(materialized_reason), "postfix", 1, true)
            or string.find(tostring(materialized_reason), "source", 1, true)
            or string.find(tostring(materialized_reason), "parent", 1, true) then
            counter = "live_size_plus_payload_rejections"
        end
        return sizePlusRejected(materialized_reason or "helper_selection_failed", {
            plan_recipe_id = compiled.recipe_id,
        }, counter)
    end

    if size_plan.primary_mode == "single" and #selected_helpers ~= 1 then
        return sizePlusRejected("slot_count_not_one", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_unsupported_combo_rejections")
    end
    if size_plan.primary_mode == "multicast" and #selected_helpers <= 1 then
        return sizePlusRejected("multicast_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_unsupported_combo_rejections")
    end
    if (size_plan.primary_mode == "spread" or size_plan.primary_mode == "burst") and #selected_helpers <= 1 then
        return sizePlusRejected("pattern_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_unsupported_combo_rejections")
    end

    local pattern_info, pattern_err = computePatternInfo(
        size_plan.primary_mode,
        size_plan.pattern_kind,
        size_plan.pattern_op,
        selected_helpers,
        launch_payload
    )
    if pattern_err then
        return sizePlusRejected(pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        }, "live_size_plus_unsupported_combo_rejections")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_size_plus_qualified")
    if size_plan.primary_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif size_plan.primary_mode == "spread" or size_plan.primary_mode == "burst" then
        patternQualified(size_plan.pattern_kind, #selected_helpers)
    end

    local size_info = size_plan.mutation
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info, size_info)
    if source_policy_plan ~= nil then
        for _, job_input in ipairs(job_inputs) do
            local applied = applySourcePolicyToJob(source_policy_plan, job_input, "source")
            if not applied or applied.ok ~= true then
                return sizePlusRejected(applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = job_input and job_input.slot_id or nil,
                })
            end
        end
    end
    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local pattern_direction_keys = {}
    for index, pair in ipairs(selected_helpers) do
        slot_ids[index] = pair.helper.slot_id
        helper_engine_ids[index] = pair.helper.engine_id
        emission_indexes[index] = pair.slot.emission_index or pair.helper.emission_index or index
        if pattern_info and pattern_info.direction_keys then
            pattern_direction_keys[index] = pattern_info.direction_keys[index]
        end
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            source_modifier_kind = job_inputs[1] and job_inputs[1].source_modifier_kind or nil,
            size_plus_primary_mode = size_plan.primary_mode,
            size_plus_mode = size_info and size_info.size_plus_mode or nil,
            size_plus_value = size_info and size_info.size_plus_value or nil,
            size_plus_multiplier = size_info and size_info.size_plus_multiplier or nil,
            size_plus_field = size_info and size_info.size_plus_field or nil,
            size_plus_capped = size_info and size_info.size_plus_capped or nil,
            size_plus_base_area = size_info and size_info.size_plus_base_area or nil,
            size_plus_area = size_info and size_info.size_plus_area or nil,
            size_plus_specs_mutated = apply_result.specs_mutated,
            size_plus_effects_mutated = apply_result.effects_mutated,
            simple_note = "size_plus_v0",
            live_mode = "size_plus",
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for _, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            if #job_ids > 0 then
                return bridgeError(enqueue.error or "enqueue failed", {
                    stage = "size_plus_enqueue",
                    recipe_id = result_recipe_id,
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = job_input.slot_id,
                    helper_engine_id = job_input.helper_engine_id,
                    cast_id = cast_id,
                    job_ids = job_ids,
                    fallback_allowed = false,
                })
            end
            return sizePlusRejected("enqueue_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            })
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end
    runtime_stats.inc("live_size_plus_jobs_mutated", #job_ids)
    if size_plan.primary_mode == "multicast"
        or size_plan.primary_mode == "spread"
        or size_plan.primary_mode == "burst" then
        runtime_stats.inc("live_multicast_jobs_enqueued", #job_ids)
    end

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    local pending_job_count = 0
    local allow_pending_launch_jobs = options.allow_pending_launch_jobs == true
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        if summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "size_plus helper launch job did not complete", {
                stage = "size_plus_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    local first_job = jobs[1] or {}
    log.info(string.format(
        "SPELLFORGE_LIVE_SIZE_PLUS_DISPATCH_OK recipe_id=%s plan_recipe_id=%s dispatch_count=%s primary_mode=%s first_slot_id=%s first_helper_engine_id=%s size_field=%s base_area=%s size_area=%s projectile_count=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(#job_ids),
        tostring(size_plan.primary_mode),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(size_info and size_info.size_plus_field or nil),
        tostring(size_info and size_info.size_plus_base_area or nil),
        tostring(size_info and size_info.size_plus_area or nil),
        tostring(projectile_id_count)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
        pattern_count = pattern_info and pattern_info.pattern_count or nil,
        pattern_direction_keys = pattern_direction_keys,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        projectile_id_source = first_job.projectile_id_source,
        projectile_registered = first_job.projectile_registered == true,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        pending_launch_jobs = pending_job_count > 0,
        pending_job_count = pending_job_count,
        all_launch_jobs_complete = pending_job_count == 0,
        job_status = first_job.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        source_modifier_kind = first_job.source_modifier_kind,
        slot_count = plan.slot_count or #plan.emission_slots,
        helper_record_count = plan.helper_record_count or #plan.helper_records,
        effect_id = selected_helpers[1] and selected_helpers[1].slot.effects and selected_helpers[1].slot.effects[1] and selected_helpers[1].slot.effects[1].id or nil,
        size_plus_primary_mode = size_plan.primary_mode,
        size_plus_mode = size_info and size_info.size_plus_mode or nil,
        size_plus_value = size_info and size_info.size_plus_value or nil,
        size_plus_multiplier = size_info and size_info.size_plus_multiplier or nil,
        size_plus_field = size_info and size_info.size_plus_field or nil,
        size_plus_capped = size_info and size_info.size_plus_capped or nil,
        size_plus_base_area = size_info and size_info.size_plus_base_area or nil,
        size_plus_area = size_info and size_info.size_plus_area or nil,
        size_plus_specs_mutated = apply_result.specs_mutated,
        size_plus_effects_mutated = apply_result.effects_mutated,
        simple_note = "size_plus_v0",
        live_mode = "size_plus",
    }
end

local function payloadGroupFrom(payload, opts)
    local options = opts or {}
    local payloads = options.payloads
    if type(payloads) ~= "table" or #payloads == 0 then
        payloads = { payload }
    end
    local slot_ids = {}
    local helper_engine_ids = {}
    for index, item in ipairs(payloads) do
        slot_ids[index] = item.slot_id
        helper_engine_ids[index] = item.helper_engine_id
    end
    return {
        payloads = payloads,
        payload_slot_ids = slot_ids,
        payload_helper_engine_ids = helper_engine_ids,
        payload_count = #payloads,
        payload_group_key = options.payload_group_key or table.concat(slot_ids, ","),
        payload_multicast = options.payload_multicast == true,
        payload_pattern = options.payload_pattern == true,
        payload_pattern_kind = options.payload_pattern_kind,
        payload_pattern_op = options.payload_pattern_op,
        nested_final_fanout = options.nested_final_fanout == true,
        nested_final_fanout_kind = options.nested_final_fanout_kind,
        max_payload_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
    }
end

local function nestedTimerBinding(compiled_recipe_id, cast_id, source, payload, launch_payload, timer_seconds, timer_delay_ticks, nested_kind, root_source_slot_id, group_opts)
    local group = payloadGroupFrom(payload, group_opts)
    return {
        recipe_id = compiled_recipe_id,
        cast_id = cast_id,
        source_slot_id = source.slot.slot_id,
        source_helper_engine_id = source.helper.engine_id,
        payload_slot_id = payload.slot_id,
        payload_helper_engine_id = payload.helper_engine_id,
        payloads = group.payloads,
        payload_slot_ids = group.payload_slot_ids,
        payload_helper_engine_ids = group.payload_helper_engine_ids,
        payload_count = group.payload_count,
        payload_group_key = group.payload_group_key,
        payload_multicast = group.payload_multicast,
        payload_pattern = group.payload_pattern,
        payload_pattern_kind = group.payload_pattern_kind,
        payload_pattern_op = group.payload_pattern_op,
        nested_final_fanout = group.nested_final_fanout,
        nested_final_fanout_kind = group.nested_final_fanout_kind,
        max_payload_fanout = group.max_payload_fanout,
        max_projectiles = group.max_projectiles,
        max_jobs_per_tick = group.max_jobs_per_tick,
        max_live_launches_per_tick = group.max_live_launches_per_tick,
        allow_pending_launch_jobs = group.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        hit_object = launch_payload.hit_object,
        timer_seconds = timer_seconds,
        timer_delay_ticks = timer_delay_ticks,
        root_source_slot_id = root_source_slot_id,
        current_source_slot_id = source.slot.slot_id,
        parent_slot_id = source.slot.parent_slot_id,
        source_depth = 1,
        nested_tt = true,
        nested_tt_kind = nested_kind,
        nested_tt_payload_role = nested_kind == "trigger_timer" and "final_timer_payload" or "intermediate_trigger_source",
        nested_stage_kind = nested_kind,
        nested_stage_index = nested_kind == "trigger_timer" and 2 or 1,
        duplicate_key_suffix = "nested_tt:" .. tostring(cast_id) .. ":" .. tostring(source.slot.slot_id) .. ":" .. tostring(group.payload_group_key),
    }
end

local function nestedTriggerBinding(compiled_recipe_id, cast_id, source, payload, launch_payload, nested_kind, root_source_slot_id, group_opts)
    local group = payloadGroupFrom(payload, group_opts)
    return {
        recipe_id = compiled_recipe_id,
        cast_id = cast_id,
        source_slot_id = source.slot.slot_id,
        source_helper_engine_id = source.helper.engine_id,
        payload_slot_id = payload.slot_id,
        payload_helper_engine_id = payload.helper_engine_id,
        payloads = group.payloads,
        payload_slot_ids = group.payload_slot_ids,
        payload_helper_engine_ids = group.payload_helper_engine_ids,
        payload_count = group.payload_count,
        payload_group_key = group.payload_group_key,
        payload_multicast = group.payload_multicast,
        payload_pattern = group.payload_pattern,
        payload_pattern_kind = group.payload_pattern_kind,
        payload_pattern_op = group.payload_pattern_op,
        nested_final_fanout = group.nested_final_fanout,
        nested_final_fanout_kind = group.nested_final_fanout_kind,
        max_payload_fanout = group.max_payload_fanout,
        max_projectiles = group.max_projectiles,
        max_jobs_per_tick = group.max_jobs_per_tick,
        max_live_launches_per_tick = group.max_live_launches_per_tick,
        allow_pending_launch_jobs = group.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        root_source_slot_id = root_source_slot_id,
        current_source_slot_id = source.slot.slot_id,
        parent_slot_id = source.slot.parent_slot_id,
        source_depth = 1,
        nested_tt = true,
        nested_tt_kind = nested_kind,
        nested_tt_payload_role = nested_kind == "timer_trigger" and "final_trigger_payload" or "intermediate_timer_source",
        nested_stage_kind = nested_kind,
        nested_stage_index = nested_kind == "timer_trigger" and 2 or 1,
    }
end

local function tryNestedTriggerTimerDispatch(compiled, launch_payload, options)
    if options.force_timer_disabled == true or (options.force_timer_enabled ~= true and not dev.liveTimerEnabled()) then
        return nestedTriggerTimerRejected("live_timer_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "nested_tt_disabled_reject")
    end
    if options.force_trigger_disabled == true or (options.force_trigger_enabled ~= true and not dev.liveTriggerEnabled()) then
        return nestedTriggerTimerRejected("live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "nested_tt_disabled_reject")
    end

    local attached = plan_cache.attachHelperRecords(compiled.recipe_id, { limits = options.budget_limits })
    if not attached.ok then
        return nestedTriggerTimerRejected("helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached),
            errors = attached.errors,
        })
    end

    local nested_plan, reason = nested_trigger_timer.selectV1Plan(attached.plan, {
        enabled = nestedTriggerTimerRuntimeEnabled(options),
        enable_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        max_fanout = options.nested_final_fanout_max_fanout,
        max_jobs = options.max_nested_payload_jobs,
        max_projectiles = options.max_projectiles,
        max_depth = options.max_nested_payload_depth,
    })
    if not nested_plan then
        return nestedTriggerTimerRejected(reason or "nested_trigger_timer_rejected", addNestedTriggerTimerDiagnostics({
            plan_recipe_id = compiled.recipe_id,
        }, attached.plan))
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")

    local selected_helpers = { nested_plan.root }
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, nil)
    local source_job = job_inputs[1]
    local root_source_slot_id = nested_plan.root_source_slot_id
    local final_group_opts = {
        payloads = nested_plan.final_payloads,
        payload_group_key = nested_plan.final_payload_group_key,
        payload_multicast = nested_plan.payload_multicast == true,
        payload_pattern = nested_plan.payload_pattern == true,
        payload_pattern_kind = nested_plan.payload_pattern_kind,
        payload_pattern_op = nested_plan.payload_pattern_op,
        nested_final_fanout = nested_plan.nested_final_fanout == true,
        nested_final_fanout_kind = nested_plan.nested_final_fanout_kind,
        max_payload_fanout = options.nested_final_fanout_max_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs == true,
    }
    source_job.root_source_slot_id = root_source_slot_id
    source_job.current_source_slot_id = root_source_slot_id
    source_job.payload_depth = 0
    source_job.nested_stage_kind = nested_plan.kind .. "_root"
    source_job.nested_stage_index = 0
    source_job.payload.root_source_slot_id = root_source_slot_id
    source_job.payload.current_source_slot_id = root_source_slot_id
    source_job.payload.payload_depth = 0
    source_job.payload.nested_stage_kind = nested_plan.kind .. "_root"
    source_job.payload.nested_stage_index = 0

    local root_binding = nil
    if nested_plan.root_kind == "Timer" then
        root_binding = nestedTimerBinding(
            compiled.recipe_id,
            cast_id,
            nested_plan.root,
            nested_plan.intermediate_payload,
            launch_payload,
            nested_plan.root_timer_seconds,
            nested_plan.root_timer_delay_ticks,
            nested_plan.kind,
            root_source_slot_id
        )
        root_binding.source_depth = 0
        root_binding.current_source_slot_id = root_source_slot_id
        root_binding.parent_slot_id = nil
        root_binding.nested_stage_index = 0
        live_timer.decorateSourceJob(source_job, root_binding)
    else
        local final_timer_binding = nestedTimerBinding(
            compiled.recipe_id,
            cast_id,
            nested_plan.intermediate,
            nested_plan.final_payload,
            launch_payload,
            nested_plan.nested_timer_seconds,
            nested_plan.nested_timer_delay_ticks,
            nested_plan.kind,
            root_source_slot_id,
            final_group_opts
        )
        root_binding = nestedTriggerBinding(
            compiled.recipe_id,
            cast_id,
            nested_plan.root,
            nested_plan.intermediate_payload,
            launch_payload,
            nested_plan.kind,
            root_source_slot_id
        )
        root_binding.source_depth = 0
        root_binding.current_source_slot_id = root_source_slot_id
        root_binding.parent_slot_id = nil
        root_binding.nested_stage_index = 0
        root_binding.nested_timer_binding = final_timer_binding
        live_trigger.decorateSourceJob(source_job, root_binding)
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            live_mode = "nested_trigger_timer",
            nested_tt_kind = nested_plan.kind,
            nested_tt_runtime = true,
            slot_id = nested_plan.root_source_slot_id,
            helper_engine_id = nested_plan.root_source_helper_engine_id,
            root_source_slot_id = nested_plan.root_source_slot_id,
            intermediate_slot_id = nested_plan.intermediate_slot_id,
            final_payload_slot_id = nested_plan.final_payload_slot_id,
            final_payload_slot_ids = nested_plan.final_payload_slot_ids,
            final_payload_count = nested_plan.final_payload_count,
            nested_final_fanout = nested_plan.nested_final_fanout == true,
            nested_final_fanout_kind = nested_plan.nested_final_fanout_kind,
            payload_multicast = nested_plan.payload_multicast == true,
            payload_pattern = nested_plan.payload_pattern == true,
            payload_pattern_kind = nested_plan.payload_pattern_kind,
            dispatch_count = 1,
            payload_fanout_count = nested_plan.final_payload_count or 1,
            cast_id = cast_id,
        }
    end

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return nestedTriggerTimerRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            error = enqueue.error or "enqueue failed",
            cast_id = cast_id,
        })
    end

    root_binding.source_job_id = enqueue.job_id
    if nested_plan.root_kind == "Trigger" then
        live_trigger.registerBinding(root_binding)
        runtime_stats.inc("live_trigger_source_jobs_enqueued")
    else
        runtime_stats.inc("live_timer_source_jobs_enqueued")
    end

    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    local pending_source_launch = summary.job_status == "queued" or summary.job_status == "running"
    if pending_source_launch and options.allow_pending_launch_jobs == true and nested_plan.root_kind == "Trigger" then
        log.info(string.format(
            "SPELLFORGE_NESTED_TRIGGER_TIMER_SOURCE_PENDING recipe_id=%s plan_recipe_id=%s cast_id=%s job_id=%s job_status=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(enqueue.job_id),
            tostring(summary.job_status)
        ))
        return {
            ok = true,
            used_live_2_2c = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            live_mode = "nested_trigger_timer",
            nested_tt_runtime = true,
            nested_tt_kind = nested_plan.kind,
            slot_id = nested_plan.root_source_slot_id,
            helper_engine_id = nested_plan.root_source_helper_engine_id,
            root_source_slot_id = nested_plan.root_source_slot_id,
            root_source_helper_engine_id = nested_plan.root_source_helper_engine_id,
            intermediate_slot_id = nested_plan.intermediate_slot_id,
            intermediate_helper_engine_id = nested_plan.intermediate_helper_engine_id,
            final_payload_slot_id = nested_plan.final_payload_slot_id,
            final_payload_helper_engine_id = nested_plan.final_payload_helper_engine_id,
            final_payload_slot_ids = nested_plan.final_payload_slot_ids,
            final_payload_helper_engine_ids = nested_plan.final_payload_helper_engine_ids,
            final_payload_count = nested_plan.final_payload_count,
            nested_final_fanout = nested_plan.nested_final_fanout == true,
            nested_final_fanout_kind = nested_plan.nested_final_fanout_kind,
            payload_multicast = nested_plan.payload_multicast == true,
            payload_pattern = nested_plan.payload_pattern == true,
            payload_pattern_kind = nested_plan.payload_pattern_kind,
            projectile_id = summary.projectile_id,
            projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            jobs = { summary },
            source_jobs = { summary },
            job_status = summary.job_status,
            cast_id = cast_id,
            runtime = "2.2c_live_helper",
            fallback = false,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = nested_plan.final_payload_count or 1,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            simple_note = "nested_trigger_timer_v1",
            pending_source_launch_job = true,
            pending_launch_jobs = true,
            pending_job_count = 1,
            all_launch_jobs_complete = false,
            tick_result = tick_result,
        }
    end
    if summary.job_status == "queued" then
        orchestrator.cancel(enqueue.job_id)
    end
    if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(summary.error or "nested Trigger/Timer source launch job did not complete", {
            stage = "nested_trigger_timer_source_launch_job",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            job_status = summary.job_status,
            tick_result = tick_result,
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    local schedule = nil
    local duplicate_schedule = nil
    local nested_trigger_registered = false
    if nested_plan.root_kind == "Timer" then
        local resolution, resolution_err = live_timer.computeResolution(launch_payload, {
            timer_seconds = nested_plan.root_timer_seconds,
        })
        if not resolution then
            return nestedTriggerTimerRejected("timer_resolution_failed", {
                plan_recipe_id = compiled.recipe_id,
                error = resolution_err,
            })
        end
        root_binding.source_job_id = enqueue.job_id
        root_binding.source_projectile_id = summary.projectile_id
        root_binding.source_user_data = summary.launch_user_data
        root_binding.resolution = resolution
        schedule = live_timer.schedulePayload(root_binding, {
            duplicate_key_suffix = root_binding.duplicate_key_suffix,
        })
        if not schedule.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(schedule.error or "nested Timer->Trigger schedule failed", {
                stage = "nested_timer_trigger_schedule",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
        if options.timer_duplicate_schedule_probe == true then
            duplicate_schedule = live_timer.schedulePayload(root_binding, {
                duplicate_key_suffix = root_binding.duplicate_key_suffix,
            })
        end
        local trigger_binding = nestedTriggerBinding(
            compiled.recipe_id,
            cast_id,
            nested_plan.intermediate,
            nested_plan.final_payload,
            launch_payload,
            nested_plan.kind,
            root_source_slot_id,
            final_group_opts
        )
        nested_trigger_registered = live_trigger.registerBinding(trigger_binding)
        log.info(string.format(
            "SPELLFORGE_NESTED_TIMER_TRIGGER_INTERMEDIATE_ENQUEUED recipe_id=%s cast_id=%s root_source_slot_id=%s current_source_slot_id=%s intermediate_slot_id=%s final_payload_slot_id=%s payload_depth=1 stage_kind=Timer->Trigger timer_id=%s",
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(root_source_slot_id),
            tostring(nested_plan.intermediate_slot_id),
            tostring(nested_plan.intermediate_slot_id),
            tostring(nested_plan.final_payload_slot_id),
            tostring(schedule.timer_id)
        ))
    end

    log.info(string.format(
        "SPELLFORGE_NESTED_TRIGGER_TIMER_QUALIFIED recipe_id=%s cast_id=%s root_source_slot_id=%s intermediate_slot_id=%s final_payload_slot_id=%s stage_kind=%s",
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(nested_plan.root_source_slot_id),
        tostring(nested_plan.intermediate_slot_id),
        tostring(nested_plan.final_payload_slot_id),
        tostring(nested_plan.kind)
    ))
    if nested_plan.nested_final_fanout == true then
        log.info(string.format(
            "SPELLFORGE_NESTED_FINAL_FANOUT_QUALIFIED recipe_id=%s cast_id=%s nested_kind=%s root_source_slot_id=%s intermediate_slot_id=%s final_payload_count=%s fanout_count=%s pattern_kind=%s",
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(nested_plan.nested_final_fanout_kind),
            tostring(nested_plan.root_source_slot_id),
            tostring(nested_plan.intermediate_slot_id),
            tostring(nested_plan.final_payload_count),
            tostring(nested_plan.final_fanout_count),
            tostring(nested_plan.payload_pattern_kind)
        ))
    end
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        live_mode = "nested_trigger_timer",
        nested_tt_runtime = true,
        nested_tt_kind = nested_plan.kind,
        slot_id = nested_plan.root_source_slot_id,
        helper_engine_id = nested_plan.root_source_helper_engine_id,
        root_source_slot_id = nested_plan.root_source_slot_id,
        root_source_helper_engine_id = nested_plan.root_source_helper_engine_id,
        intermediate_slot_id = nested_plan.intermediate_slot_id,
        intermediate_helper_engine_id = nested_plan.intermediate_helper_engine_id,
        final_payload_slot_id = nested_plan.final_payload_slot_id,
        final_payload_helper_engine_id = nested_plan.final_payload_helper_engine_id,
        final_payload_slot_ids = nested_plan.final_payload_slot_ids,
        final_payload_helper_engine_ids = nested_plan.final_payload_helper_engine_ids,
        final_payload_count = nested_plan.final_payload_count,
        nested_final_fanout = nested_plan.nested_final_fanout == true,
        nested_final_fanout_kind = nested_plan.nested_final_fanout_kind,
        payload_multicast = nested_plan.payload_multicast == true,
        payload_pattern = nested_plan.payload_pattern == true,
        payload_pattern_kind = nested_plan.payload_pattern_kind,
        timer_id = schedule and schedule.timer_id or nil,
        timer_async_scheduled = schedule and schedule.async_scheduled == true or false,
        timer_pending_count = schedule and schedule.pending_count or nil,
        timer_duplicate_suppressed = duplicate_schedule and duplicate_schedule.duplicate_suppressed == true or false,
        nested_trigger_registered = nested_trigger_registered,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        source_jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = 1,
        payload_fanout_count = nested_plan.final_payload_count or 1,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        simple_note = "nested_trigger_timer_v1",
    }
end

local function chainRuntimeRejectCounter(reason)
    local text = tostring(reason)
    if string.find(text, "disabled", 1, true) then
        return "chain_runtime_disabled_reject"
    elseif string.find(text, "pattern", 1, true) or string.find(text, "modifier", 1, true) then
        return "chain_runtime_pattern_reject"
    elseif string.find(text, "multicast", 1, true) then
        return "chain_runtime_multicast_reject"
    elseif string.find(text, "trigger_timer", 1, true)
        or string.find(text, "timer_context", 1, true)
        or string.find(text, "side_payload_budget", 1, true)
        or string.find(text, "event_payload_chain", 1, true) then
        return "chain_runtime_trigger_timer_reject"
    elseif string.find(text, "nested", 1, true) then
        return "chain_runtime_nested_reject"
    elseif string.find(text, "recursion", 1, true) then
        return "chain_runtime_recursion_reject"
    elseif string.find(text, "cap", 1, true) then
        return "chain_runtime_cap_reject"
    end
    return "chain_runtime_context_reject"
end

local function countChainModifierRejection(reason, audit)
    if not audit or (audit.payload_modifier_kind == nil
        and audit.has_speed_plus_payload ~= true
        and audit.has_size_plus_payload ~= true) then
        return
    end
    runtime_stats.inc("chain_modifier_rejected")
    local text = tostring(reason or audit.rejection_reason)
    if string.find(text, "disabled", 1, true) then
        runtime_stats.inc("chain_modifier_disabled_reject")
    elseif string.find(text, "combo", 1, true) then
        runtime_stats.inc("chain_modifier_combo_reject")
    else
        runtime_stats.inc("chain_modifier_unsupported_reject")
    end
    log.info(string.format(
        "SPELLFORGE_CHAIN_MODIFIER_REJECTED reason=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s payload_modifier_kind=%s",
        tostring(text),
        tostring(audit.plan_recipe_id or audit.recipe_id),
        tostring(audit.source_slot_id),
        tostring(audit.payload_slot_id),
        tostring(audit.requested_hops),
        tostring(audit.max_hops),
        tostring(audit.payload_modifier_kind)
    ))
end

local function tryChainDispatch(compiled, launch_payload, options)
    runtime_stats.inc("chain_runtime_attempts")
    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id

    if options.force_chain_runtime_disabled == true then
        runtime_stats.inc("chain_target_runtime_deferred")
        return chainRuntimeRejected("chain_runtime_disabled", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            runtime_enabled = false,
            audit_enabled = dev.liveChainAuditEnabled() == true,
        }, "chain_runtime_disabled_reject")
    end
    if options.force_chain_runtime_enabled ~= true and not dev.liveChainRuntimeEnabled() then
        runtime_stats.inc("chain_target_runtime_deferred")
        return chainRuntimeRejected("chain_runtime_disabled", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            runtime_enabled = false,
            audit_enabled = dev.liveChainAuditEnabled() == true,
        }, "chain_runtime_disabled_reject")
    end
    local allow_chain_event_continuation = options.force_chain_event_continuation_enabled == true
        or options.allow_chain_event_continuation == true
        or options.force_trigger_enabled == true
        or options.force_timer_enabled == true
        or dev.liveTriggerEnabled() == true
        or dev.liveTimerEnabled() == true

    local attached_specs = plan_cache.attachHelperSpecs(compiled.recipe_id)
    if not attached_specs.ok then
        return chainRuntimeRejected("helper_specs_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached_specs),
            errors = attached_specs.errors,
        }, "chain_runtime_context_reject")
    end

    local modifier_plan, modifier_reason, modifier_audit = live_chain.preparePayloadModifiers(attached_specs.plan, {
        max_hops = options.max_chain_hops,
        max_jobs = options.max_chain_jobs,
        max_candidates = options.max_chain_scan_candidates,
        scan_radius = options.chain_scan_radius,
        allow_chain_multicast = options.force_chain_multicast_enabled == true
            or options.chain_multicast_enabled == true
            or dev.liveChainMulticastEnabled(),
        allow_chain_pattern = options.force_payload_pattern_enabled == true
            or options.allow_payload_pattern == true
            or dev.livePayloadPatternEnabled(),
        allow_payload_pattern = options.force_payload_pattern_enabled == true
            or options.allow_payload_pattern == true
            or dev.livePayloadPatternEnabled(),
        allow_chain_event_continuation = allow_chain_event_continuation,
        allow_chain_trigger_side_continuation = options.force_trigger_enabled == true
            or dev.liveTriggerEnabled() == true,
        allow_chain_timer_side_continuation = options.force_timer_enabled == true
            or dev.liveTimerEnabled() == true,
        max_chain_multicast_fanout = options.max_chain_multicast_fanout,
        max_chain_pattern_fanout = options.max_chain_pattern_fanout,
        max_chain_event_continuation_jobs = options.max_chain_event_continuation_jobs,
        max_chain_trigger_side_payload_jobs = options.max_chain_trigger_side_payload_jobs,
        max_chain_timer_side_payload_jobs = options.max_chain_timer_side_payload_jobs,
        max_chain_side_payload_jobs = options.max_chain_side_payload_jobs,
        max_chain_side_payload_fanout = options.max_chain_side_payload_fanout,
        apply_size_to_specs = true,
        force_chain_multicast_enabled = options.force_chain_multicast_enabled,
        force_chain_multicast_disabled = options.force_chain_multicast_disabled,
        chain_multicast_enabled = dev.liveChainMulticastEnabled() == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
    })
    if modifier_audit and (modifier_audit.payload_modifier_kind ~= nil
        or modifier_audit.has_speed_plus_payload == true
        or modifier_audit.has_size_plus_payload == true) then
        runtime_stats.inc("chain_modifier_attempts")
    end
    if modifier_audit and modifier_audit.has_multicast_payload == true then
        runtime_stats.inc("chain_multicast_attempts")
    end
    if not modifier_plan then
        local details = modifier_audit or {}
        details.recipe_id = result_recipe_id
        details.plan_recipe_id = compiled.recipe_id
        local rejection_reason = modifier_reason or details.rejection_reason
        if options.force_chain_multicast_disabled == true
            and (details.has_multicast_payload == true or details.has_chain_with_multicast == true) then
            rejection_reason = "chain_multicast_disabled"
        end
        details.rejection_reason = rejection_reason
        countChainModifierRejection(rejection_reason, details)
        if details.has_multicast_payload == true or details.has_chain_with_multicast == true then
            runtime_stats.inc("chain_multicast_rejected")
            if tostring(rejection_reason):find("disabled", 1, true) then
                runtime_stats.inc("chain_multicast_disabled_reject")
            elseif tostring(rejection_reason):find("cap", 1, true) then
                runtime_stats.inc("chain_multicast_fanout_cap_reject")
            end
        end
        if details.has_chain_with_pattern == true or details.has_pattern_payload == true then
            log.info(string.format(
                "SPELLFORGE_CHAIN_PATTERN_POLICY_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason)
            ))
        end
        if rejection_reason == "chain_trigger_side_payload_budget_exceeded"
            or rejection_reason == "chain_timer_side_payload_budget_exceeded"
            or rejection_reason == "chain_event_continuation_budget_exceeded"
            or rejection_reason == "chain_trigger_timer_deferred"
            or rejection_reason == "chain_event_payload_chain_deferred" then
            log.info(string.format(
                "SPELLFORGE_CHAIN_EVENT_CONTINUATION_POLICY_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s side_kind=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason),
                tostring(details.chain_side_continuation_kind)
            ))
        end
        if rejection_reason == "chain_trigger_side_payload_budget_exceeded"
            or rejection_reason == "chain_timer_side_payload_budget_exceeded"
            or rejection_reason == "chain_event_continuation_budget_exceeded" then
            log.info(string.format(
                "SPELLFORGE_CHAIN_EVENT_CONTINUATION_BUDGET_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s budget=%s cap=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason),
                tostring(details.chain_event_continuation_budget),
                tostring(details.chain_event_continuation_budget_cap)
            ))
        end
        local reject_counter = details.has_chain_with_pattern == true
            and "chain_runtime_pattern_reject"
            or chainRuntimeRejectCounter(rejection_reason)
        return chainRuntimeRejected(rejection_reason or "unsupported_chain_shape", details, reject_counter)
    end
    if modifier_plan.payload_modifier_kind ~= nil then
        runtime_stats.inc("chain_modifier_qualified")
        if modifier_plan.has_speed_plus_payload == true then
            runtime_stats.inc("chain_modifier_speed_qualified")
        end
        if modifier_plan.has_size_plus_payload == true then
            runtime_stats.inc("chain_modifier_size_qualified")
            runtime_stats.inc("chain_modifier_size_specs_mutated", modifier_plan.size_plus_apply_result and modifier_plan.size_plus_apply_result.specs_mutated or 0)
        end
    end
    if modifier_plan.has_multicast_payload == true then
        runtime_stats.inc("chain_multicast_qualified")
    end

    local attached = plan_cache.attachHelperRecords(compiled.recipe_id, { limits = options.budget_limits })
    if not attached.ok then
        return chainRuntimeRejected("helper_records_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached),
            errors = attached.errors,
        }, "chain_runtime_context_reject")
    end

    local chain_plan, chain_reason, chain_audit = live_chain.selectV0Plan(attached.plan, {
        max_hops = options.max_chain_hops,
        max_jobs = options.max_chain_jobs,
        max_candidates = options.max_chain_scan_candidates,
        scan_radius = options.chain_scan_radius,
        allow_chain_multicast = options.force_chain_multicast_enabled == true
            or options.chain_multicast_enabled == true
            or dev.liveChainMulticastEnabled(),
        allow_chain_pattern = options.force_payload_pattern_enabled == true
            or options.allow_payload_pattern == true
            or dev.livePayloadPatternEnabled(),
        allow_payload_pattern = options.force_payload_pattern_enabled == true
            or options.allow_payload_pattern == true
            or dev.livePayloadPatternEnabled(),
        allow_chain_event_continuation = allow_chain_event_continuation,
        allow_chain_trigger_side_continuation = options.force_trigger_enabled == true
            or dev.liveTriggerEnabled() == true,
        allow_chain_timer_side_continuation = options.force_timer_enabled == true
            or dev.liveTimerEnabled() == true,
        max_chain_multicast_fanout = options.max_chain_multicast_fanout,
        max_chain_pattern_fanout = options.max_chain_pattern_fanout,
        max_chain_event_continuation_jobs = options.max_chain_event_continuation_jobs,
        max_chain_trigger_side_payload_jobs = options.max_chain_trigger_side_payload_jobs,
        max_chain_timer_side_payload_jobs = options.max_chain_timer_side_payload_jobs,
        max_chain_side_payload_jobs = options.max_chain_side_payload_jobs,
        max_chain_side_payload_fanout = options.max_chain_side_payload_fanout,
        prepared_modifier = modifier_plan,
        force_chain_multicast_enabled = options.force_chain_multicast_enabled,
        force_chain_multicast_disabled = options.force_chain_multicast_disabled,
        chain_multicast_enabled = dev.liveChainMulticastEnabled() == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
    })
    if not chain_plan then
        local details = chain_audit or {}
        details.recipe_id = result_recipe_id
        details.plan_recipe_id = compiled.recipe_id
        local rejection_reason = chain_reason or details.rejection_reason
        if options.force_chain_multicast_disabled == true
            and (details.has_multicast_payload == true or details.has_chain_with_multicast == true) then
            rejection_reason = "chain_multicast_disabled"
        end
        details.rejection_reason = rejection_reason
        countChainModifierRejection(rejection_reason, details)
        if details.has_multicast_payload == true or details.has_chain_with_multicast == true then
            runtime_stats.inc("chain_multicast_rejected")
            if tostring(rejection_reason):find("disabled", 1, true) then
                runtime_stats.inc("chain_multicast_disabled_reject")
            elseif tostring(rejection_reason):find("cap", 1, true) then
                runtime_stats.inc("chain_multicast_fanout_cap_reject")
            end
        end
        if details.has_chain_with_pattern == true or details.has_pattern_payload == true then
            log.info(string.format(
                "SPELLFORGE_CHAIN_PATTERN_POLICY_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason)
            ))
        end
        if rejection_reason == "chain_trigger_side_payload_budget_exceeded"
            or rejection_reason == "chain_timer_side_payload_budget_exceeded"
            or rejection_reason == "chain_event_continuation_budget_exceeded"
            or rejection_reason == "chain_trigger_timer_deferred"
            or rejection_reason == "chain_event_payload_chain_deferred" then
            log.info(string.format(
                "SPELLFORGE_CHAIN_EVENT_CONTINUATION_POLICY_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s side_kind=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason),
                tostring(details.chain_side_continuation_kind)
            ))
        end
        if rejection_reason == "chain_trigger_side_payload_budget_exceeded"
            or rejection_reason == "chain_timer_side_payload_budget_exceeded"
            or rejection_reason == "chain_event_continuation_budget_exceeded" then
            log.info(string.format(
                "SPELLFORGE_CHAIN_EVENT_CONTINUATION_BUDGET_DEFERRED recipe_id=%s plan_recipe_id=%s reason=%s budget=%s cap=%s",
                tostring(result_recipe_id),
                tostring(compiled.recipe_id),
                tostring(rejection_reason),
                tostring(details.chain_event_continuation_budget),
                tostring(details.chain_event_continuation_budget_cap)
            ))
        end
        local reject_counter = details.has_chain_with_pattern == true
            and "chain_runtime_pattern_reject"
            or chainRuntimeRejectCounter(rejection_reason)
        return chainRuntimeRejected(rejection_reason or "unsupported_chain_shape", details, reject_counter)
    end
    if chain_plan.chain_shape == "trigger_payload_chain"
        and options.force_trigger_enabled ~= true
        and not dev.liveTriggerEnabled() then
        return chainRuntimeRejected("live_trigger_disabled", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
            requested_hops = chain_plan.requested_hops,
            max_hops = chain_plan.max_hops,
        }, "chain_runtime_disabled_reject")
    end
    if chain_plan.chain_side_continuation_kind == "Trigger"
        and options.force_trigger_enabled ~= true
        and not dev.liveTriggerEnabled() then
        return chainRuntimeRejected("live_trigger_disabled", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
            requested_hops = chain_plan.requested_hops,
            max_hops = chain_plan.max_hops,
        }, "chain_runtime_disabled_reject")
    end
    if chain_plan.chain_side_continuation_kind == "Timer"
        and options.force_timer_enabled ~= true
        and not dev.liveTimerEnabled() then
        return chainRuntimeRejected("live_timer_disabled", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
            requested_hops = chain_plan.requested_hops,
            max_hops = chain_plan.max_hops,
        }, "chain_runtime_disabled_reject")
    end

    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local chain_id = string.format(
        "chain:%s:%s:%s:%s",
        tostring(cast_id),
        tostring(chain_plan.source_slot_id),
        tostring(chain_plan.payload_slot_id),
        tostring(chain_plan.max_hops)
    )
    local binding = {
        plan = attached.plan,
        recipe_id = compiled.recipe_id,
        display_recipe_id = result_recipe_id,
        cast_id = cast_id,
        chain_id = chain_id,
        chain_shape = chain_plan.chain_shape,
        source_slot_id = chain_plan.source_slot_id,
        source_helper_engine_id = chain_plan.source_helper_engine_id,
        payload_slot_id = chain_plan.payload_slot_id,
        payload_helper_engine_id = chain_plan.payload_helper_engine_id,
        payload_slot_ids = chain_plan.payload_slot_ids,
        payload_helper_engine_ids = chain_plan.payload_helper_engine_ids,
        payload_effect_id = chain_plan.payload_effect_id,
        payload_modifier_kind = chain_plan.payload_modifier_kind,
        has_multicast_payload = chain_plan.has_multicast_payload == true,
        has_pattern_payload = chain_plan.has_pattern_payload == true,
        chain_pattern_kind = chain_plan.chain_pattern_kind,
        chain_multicast_fanout_count = chain_plan.chain_multicast_fanout_count or 1,
        has_speed_plus_payload = chain_plan.has_speed_plus_payload == true,
        has_size_plus_payload = chain_plan.has_size_plus_payload == true,
        speed_plus_mutation = chain_plan.speed_plus_mutation,
        size_plus_mutation = chain_plan.size_plus_mutation,
        chain_side_continuation_kind = chain_plan.chain_side_continuation_kind,
        chain_side_continuation_id = chain_plan.chain_side_continuation_id,
        chain_side_payloads = chain_plan.chain_side_payloads,
        chain_side_payload_slot_id = chain_plan.chain_side_payload_slot_id,
        chain_side_payload_helper_engine_id = chain_plan.chain_side_payload_helper_engine_id,
        chain_side_payload_slot_ids = chain_plan.chain_side_payload_slot_ids,
        chain_side_payload_helper_engine_ids = chain_plan.chain_side_payload_helper_engine_ids,
        chain_side_payload_count = chain_plan.chain_side_payload_count,
        chain_side_payload_group_key = chain_plan.chain_side_payload_group_key,
        chain_side_payload_multicast = chain_plan.chain_side_payload_multicast == true,
        chain_side_payload_pattern = chain_plan.chain_side_payload_pattern == true,
        chain_side_payload_pattern_kind = chain_plan.chain_side_payload_pattern_kind,
        chain_side_payload_pattern_op = chain_plan.chain_side_payload_pattern_op,
        chain_side_has_payload_modifier = chain_plan.chain_side_has_payload_modifier == true,
        chain_side_payload_modifier_kinds = chain_plan.chain_side_payload_modifier_kinds,
        chain_side_timer_seconds = chain_plan.chain_side_timer_seconds,
        chain_side_timer_delay_ticks = chain_plan.chain_side_timer_delay_ticks,
        chain_event_continuation_budget = chain_plan.chain_event_continuation_budget,
        chain_event_continuation_budget_cap = chain_plan.chain_event_continuation_budget_cap,
        chain_side_max_payload_fanout = options.max_chain_side_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT,
        payload_emission_index = chain_plan.payload.slot.emission_index or chain_plan.payload.helper.emission_index,
        payload_group_index = chain_plan.payload.slot.group_index or chain_plan.payload.helper.group_index,
        root_source_slot_id = chain_plan.source_slot_id,
        requested_hops = chain_plan.requested_hops,
        max_hops = chain_plan.max_hops,
        candidate_cap = chain_plan.candidate_cap or options.max_chain_scan_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES,
        scan_actor_cap = options.max_chain_scan_actors or limits.MAX_CHAIN_SCAN_ACTORS,
        targeting_mode = "no_immediate_repeat",
        actor = launch_payload.actor or launch_payload.sender,
        candidate_provider = options.chain_candidate_provider or options.candidate_provider,
        scan_radius = options.chain_scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_chain_jobs = options.max_chain_jobs,
        max_projectiles = options.max_projectiles,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        chaos_budget_profile = options.chaos_budget_profile,
        force_enabled = options.force_chain_runtime_enabled == true,
    }

    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("chain_runtime_qualified")
    if chain_plan.chain_shape == "trigger_payload_chain" then
        runtime_stats.inc("chain_runtime_trigger_chain_qualified")
    else
        runtime_stats.inc("chain_runtime_direct_qualified")
    end
    if chain_plan.payload_modifier_kind ~= nil then
        log.info(string.format(
            "SPELLFORGE_CHAIN_MODIFIER_QUALIFIED recipe_id=%s plan_recipe_id=%s cast_id=%s chain_id=%s chain_shape=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s payload_modifier_kind=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(chain_id),
            tostring(chain_plan.chain_shape),
            tostring(chain_plan.source_slot_id),
            tostring(chain_plan.payload_slot_id),
            tostring(chain_plan.requested_hops),
            tostring(chain_plan.max_hops),
            tostring(chain_plan.payload_modifier_kind)
        ))
    end
    if chain_plan.has_multicast_payload == true then
        log.info(string.format(
            "SPELLFORGE_CHAIN_MULTICAST_QUALIFIED recipe_id=%s plan_recipe_id=%s cast_id=%s chain_id=%s chain_shape=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s fanout_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(chain_id),
            tostring(chain_plan.chain_shape),
            tostring(chain_plan.source_slot_id),
            tostring(chain_plan.payload_slot_id),
            tostring(chain_plan.requested_hops),
            tostring(chain_plan.max_hops),
            tostring(chain_plan.chain_multicast_fanout_count or 1)
        ))
    end
    if chain_plan.has_pattern_payload == true then
        log.info(string.format(
            "SPELLFORGE_CHAIN_PATTERN_POLICY_OK recipe_id=%s plan_recipe_id=%s cast_id=%s chain_id=%s chain_shape=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s pattern_kind=%s fanout_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(chain_id),
            tostring(chain_plan.chain_shape),
            tostring(chain_plan.source_slot_id),
            tostring(chain_plan.payload_slot_id),
            tostring(chain_plan.requested_hops),
            tostring(chain_plan.max_hops),
            tostring(chain_plan.chain_pattern_kind),
            tostring(chain_plan.chain_multicast_fanout_count or 1)
        ))
    end

    local job_inputs = buildJobInputs({ chain_plan.source }, compiled.recipe_id, cast_id, launch_payload)
    local source_job = job_inputs[1]
    if not source_job then
        return chainRuntimeRejected("chain_source_job_missing", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
        }, "chain_runtime_context_reject")
    end
    live_chain.decorateSourceJob(source_job, binding)

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            live_mode = "chain",
            chain_runtime = true,
            runtime_enabled = true,
            chain_shape = chain_plan.chain_shape,
            chain_id = chain_id,
            requested_hops = chain_plan.requested_hops,
            max_hops = chain_plan.max_hops,
            targeting_mode = "no_immediate_repeat",
            payload_modifier_kind = chain_plan.payload_modifier_kind,
            has_multicast_payload = chain_plan.has_multicast_payload == true,
            has_pattern_payload = chain_plan.has_pattern_payload == true,
            chain_pattern_kind = chain_plan.chain_pattern_kind,
            chain_multicast_fanout_count = chain_plan.chain_multicast_fanout_count or 1,
            speed_plus = chain_plan.has_speed_plus_payload == true or nil,
            speed_plus_mode = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_mode or nil,
            speed_plus_value = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_value or nil,
            speed_plus_base_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_base_speed or nil,
            speed_plus_multiplier = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_multiplier or nil,
            speed_plus_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_speed or nil,
            speed_plus_max_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_max_speed or nil,
            speed_plus_field = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_field or nil,
            size_plus = chain_plan.has_size_plus_payload == true or nil,
            size_plus_mode = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_mode or nil,
            size_plus_value = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_value or nil,
            size_plus_multiplier = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_multiplier or nil,
            size_plus_field = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_field or nil,
            size_plus_base_area = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_base_area or nil,
            size_plus_area = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_area or nil,
            chain_side_continuation_kind = chain_plan.chain_side_continuation_kind,
            chain_side_payload_count = chain_plan.chain_side_payload_count,
            chain_event_continuation_budget = chain_plan.chain_event_continuation_budget,
            chain_event_continuation_budget_cap = chain_plan.chain_event_continuation_budget_cap,
            slot_id = chain_plan.source_slot_id,
            helper_engine_id = chain_plan.source_helper_engine_id,
            payload_slot_id = chain_plan.payload_slot_id,
            payload_helper_engine_id = chain_plan.payload_helper_engine_id,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = chain_plan.chain_multicast_fanout_count or 1,
            would_launch_payloads = (chain_plan.chain_multicast_fanout_count or 1) * (chain_plan.max_hops or 0),
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            cast_id = cast_id,
        }
    end

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return chainRuntimeRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
            error = enqueue.error or "enqueue failed",
            cast_id = cast_id,
        }, "chain_runtime_context_reject")
    end
    binding.source_job_id = enqueue.job_id
    live_chain.registerBinding(binding)
    local chain_side_trigger_registered = nil
    local chain_side_trigger_registered_count = 0
    if chain_plan.chain_side_continuation_kind == "Trigger" then
        local group = payloadGroupFrom({
            slot_id = chain_plan.chain_side_payload_slot_id,
            helper_engine_id = chain_plan.chain_side_payload_helper_engine_id,
        }, {
            payloads = chain_plan.chain_side_payloads,
            payload_group_key = chain_plan.chain_side_payload_group_key,
            payload_multicast = chain_plan.chain_side_payload_multicast == true,
            payload_pattern = chain_plan.chain_side_payload_pattern == true,
            payload_pattern_kind = chain_plan.chain_side_payload_pattern_kind,
            payload_pattern_op = chain_plan.chain_side_payload_pattern_op,
            max_payload_fanout = options.max_chain_side_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT,
            max_projectiles = options.max_projectiles,
            max_jobs_per_tick = options.max_jobs_per_tick,
            max_live_launches_per_tick = options.max_live_launches_per_tick,
        })
        local trigger_source_slot_ids = chain_plan.payload_slot_ids
        if type(trigger_source_slot_ids) ~= "table" or #trigger_source_slot_ids == 0 then
            trigger_source_slot_ids = { chain_plan.payload_slot_id }
        end
        local trigger_source_helper_ids = chain_plan.payload_helper_engine_ids
        if type(trigger_source_helper_ids) ~= "table" or #trigger_source_helper_ids == 0 then
            trigger_source_helper_ids = { chain_plan.payload_helper_engine_id }
        end
        chain_side_trigger_registered = true
        for index, source_slot_id in ipairs(trigger_source_slot_ids) do
            local registered = live_trigger.registerBinding({
                plan = attached.plan,
                recipe_id = compiled.recipe_id,
                display_recipe_id = result_recipe_id,
                cast_id = cast_id,
                source_job_id = enqueue.job_id,
                source_slot_id = source_slot_id,
                source_helper_engine_id = trigger_source_helper_ids[index] or chain_plan.payload_helper_engine_id,
                payload_slot_id = chain_plan.chain_side_payload_slot_id,
                payload_helper_engine_id = chain_plan.chain_side_payload_helper_engine_id,
                payloads = group.payloads,
                payload_slot_ids = group.payload_slot_ids,
                payload_helper_engine_ids = group.payload_helper_engine_ids,
                payload_count = group.payload_count,
                payload_group_key = group.payload_group_key,
                payload_multicast = group.payload_multicast,
                payload_pattern = group.payload_pattern,
                payload_pattern_kind = group.payload_pattern_kind,
                payload_pattern_op = group.payload_pattern_op,
                max_payload_fanout = group.max_payload_fanout,
                max_projectiles = group.max_projectiles,
                max_jobs_per_tick = group.max_jobs_per_tick,
                max_live_launches_per_tick = group.max_live_launches_per_tick,
                actor = launch_payload.actor or launch_payload.sender,
                root_source_slot_id = chain_plan.source_slot_id,
                source_depth = 1,
                chain_runtime = true,
                chain_side_continuation = true,
                chain_id = chain_id,
            })
            if registered == true then
                chain_side_trigger_registered_count = chain_side_trigger_registered_count + 1
            else
                chain_side_trigger_registered = false
                break
            end
        end
        if chain_side_trigger_registered ~= true then
            return chainRuntimeRejected("chain_trigger_side_binding_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = chain_plan.payload_slot_id,
                payload_slot_id = chain_plan.chain_side_payload_slot_id,
                cast_id = cast_id,
            }, "chain_runtime_context_reject")
        end
    end

    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(summary.error or "Chain source launch job did not complete", {
            stage = "chain_source_launch",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = chain_plan.source_slot_id,
            payload_slot_id = chain_plan.payload_slot_id,
            job_id = enqueue.job_id,
            job_status = summary.job_status,
            tick_result = tick_result,
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    log.info(string.format(
        "SPELLFORGE_CHAIN_RUNTIME_QUALIFIED recipe_id=%s plan_recipe_id=%s cast_id=%s chain_id=%s chain_shape=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s source_projectile_id=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(chain_id),
        tostring(chain_plan.chain_shape),
        tostring(chain_plan.source_slot_id),
        tostring(chain_plan.payload_slot_id),
        tostring(chain_plan.requested_hops),
        tostring(chain_plan.max_hops),
        tostring(summary.projectile_id)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        live_mode = "chain",
        chain_runtime = true,
        runtime_enabled = true,
        chain_shape = chain_plan.chain_shape,
        chain_id = chain_id,
        requested_hops = chain_plan.requested_hops,
        max_hops = chain_plan.max_hops,
        targeting_mode = "no_immediate_repeat",
        payload_modifier_kind = chain_plan.payload_modifier_kind,
        has_multicast_payload = chain_plan.has_multicast_payload == true,
        has_pattern_payload = chain_plan.has_pattern_payload == true,
        chain_pattern_kind = chain_plan.chain_pattern_kind,
        chain_multicast_fanout_count = chain_plan.chain_multicast_fanout_count or 1,
        speed_plus = chain_plan.has_speed_plus_payload == true or nil,
        speed_plus_mode = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_mode or nil,
        speed_plus_value = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_value or nil,
        speed_plus_base_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_base_speed or nil,
        speed_plus_multiplier = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_multiplier or nil,
        speed_plus_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_speed or nil,
        speed_plus_max_speed = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_max_speed or nil,
        speed_plus_field = chain_plan.speed_plus_mutation and chain_plan.speed_plus_mutation.speed_plus_field or nil,
        size_plus = chain_plan.has_size_plus_payload == true or nil,
        size_plus_mode = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_mode or nil,
        size_plus_value = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_value or nil,
        size_plus_multiplier = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_multiplier or nil,
        size_plus_field = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_field or nil,
        size_plus_base_area = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_base_area or nil,
        size_plus_area = chain_plan.size_plus_mutation and chain_plan.size_plus_mutation.size_plus_area or nil,
        chain_side_continuation_kind = chain_plan.chain_side_continuation_kind,
        chain_side_payload_count = chain_plan.chain_side_payload_count,
        chain_event_continuation_budget = chain_plan.chain_event_continuation_budget,
        chain_event_continuation_budget_cap = chain_plan.chain_event_continuation_budget_cap,
        chain_side_trigger_registered = chain_side_trigger_registered,
        chain_side_trigger_registered_count = chain_side_trigger_registered_count,
        slot_id = chain_plan.source_slot_id,
        helper_engine_id = chain_plan.source_helper_engine_id,
        payload_slot_id = chain_plan.payload_slot_id,
        payload_helper_engine_id = chain_plan.payload_helper_engine_id,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        projectile_id_source = summary.projectile_id_source,
        projectile_registered = summary.projectile_registered == true,
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        source_jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = chain_plan.chain_multicast_fanout_count or 1,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        simple_note = "chain_runtime_v0",
        tick_result = tick_result,
    }
end

local function tryTimerDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_timer_attempts")
    if options.force_timer_disabled == true then
        return timerRejected("live_timer_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_timer_disabled_rejections")
    end
    if options.force_timer_enabled ~= true and not dev.liveTimerEnabled() then
        return timerRejected("live_timer_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_timer_disabled_rejections")
    end

    if compiled.plan then
        local prepared, prepare_reason, prepare_details = launch_modifier_policy.prepareCachedPlanPayloadModifiers(compiled.recipe_id, {
            source_opcode = "Timer",
            apply_size_to_specs = true,
            allow_payload_launch_modifiers = true,
            allow_payload_detonate = true,
            allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
            allow_nested_payload_modifiers = true,
            force_speed_plus_enabled = options.force_speed_plus_enabled,
            force_speed_plus_disabled = options.force_speed_plus_disabled,
            speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
            force_size_plus_enabled = options.force_size_plus_enabled,
            force_size_plus_disabled = options.force_size_plus_disabled,
            size_plus_enabled = dev.liveSizePlusEnabled() == true,
            max_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
        })
        if not prepared then
            if prepare_reason == "helper_specs_failed" then
                return timerRejected("helper_specs_failed", {
                    plan_recipe_id = compiled.recipe_id,
                    error = firstErrorMessage(prepare_details),
                    errors = prepare_details and prepare_details.errors,
                })
            end
            return timerRejected(prepare_reason or "payload_modifier_combo_deferred", {
                plan_recipe_id = compiled.recipe_id,
            })
        end
    end

    local attached, attach_reason, attach_details = attachHelperRecordsWithSourcePolicy(
        compiled,
        sourceContinuationOptions(options),
        nil
    )
    if not attached then
        attach_details = attach_details or {}
        attach_details.plan_recipe_id = attach_details.plan_recipe_id or compiled.recipe_id
        return timerRejected(attach_reason or "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attach_details),
            errors = attach_details.errors,
        })
    end

    local timer_plan, timer_reason = live_timer.selectV0Plan(attached.plan, {
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        allow_payload_launch_modifiers = true,
        allow_payload_detonate = true,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
        allow_source_launch_modifiers = true,
        allow_source_homing = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        allow_payload_homing = options.allow_payload_homing == true or options.force_homing_enabled == true,
        allow_homing = options.allow_homing == true or options.force_homing_enabled == true,
        force_homing_enabled = options.force_homing_enabled,
        force_homing_disabled = options.force_homing_disabled,
        homing_enabled = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        max_homing_fanout_per_cast = options.max_homing_fanout_per_cast,
        max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast,
        max_soft_homing_registrations_per_cast = options.max_soft_homing_registrations_per_cast,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs,
    })
    if not timer_plan then
        return timerRejected(timer_reason or "timer_v0_rejected", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_timer_qualified")

    local selected_helpers = { timer_plan.source }
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, nil)
    local source_job = job_inputs[1]
    local source_prefix_opcode = hasSourceHoming(timer_plan.source and timer_plan.source.slot) and "Homing" or nil
    local binding = {
        recipe_id = compiled.recipe_id,
        cast_id = cast_id,
        source_slot_id = timer_plan.source_slot_id,
        source_helper_engine_id = timer_plan.source_helper_engine_id,
        payload_slot_id = timer_plan.payload_slot_id,
        payload_helper_engine_id = timer_plan.payload_helper_engine_id,
        payloads = timer_plan.payloads,
        payload_slot_ids = timer_plan.payload_slot_ids,
        payload_helper_engine_ids = timer_plan.payload_helper_engine_ids,
        payload_count = timer_plan.payload_count,
        payload_group_key = timer_plan.payload_group_key,
        payload_multicast = timer_plan.payload_multicast == true,
        payload_pattern = timer_plan.payload_pattern == true,
        payload_pattern_kind = timer_plan.payload_pattern_kind,
        payload_pattern_op = timer_plan.payload_pattern_op,
        has_payload_homing = timer_plan.has_payload_homing == true,
        has_payload_modifier = timer_plan.has_payload_modifier == true,
        payload_modifier_kinds = timer_plan.payload_modifier_kinds,
        plan = attached.plan,
        max_payload_fanout = timer_plan.max_payload_fanout,
        max_projectiles = timer_plan.max_projectiles,
        max_jobs_per_tick = timer_plan.max_jobs_per_tick,
        max_live_launches_per_tick = timer_plan.max_live_launches_per_tick,
        allow_pending_launch_jobs = timer_plan.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        hit_object = launch_payload.hit_object,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        source_prefix_opcode = source_prefix_opcode,
        timer_seconds = timer_plan.timer_seconds,
        timer_delay_ticks = timer_plan.timer_delay_ticks,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
    }
    live_timer.decorateSourceJob(source_job, binding)
    if attached.source_policy ~= nil then
        local applied = applySourcePolicyToJob(attached, source_job, "timer")
        if not applied or applied.ok ~= true then
            return timerRejected(applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = timer_plan.source_slot_id,
            })
        end
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_CONTINUATION_OK kind=Timer recipe_id=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s modifier_kinds=%s payload_fanout_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(timer_plan.source_slot_id),
            tostring(timer_plan.payload_slot_id),
            tostring(source_job.source_modifier_kind),
            tostring(timer_plan.payload_count)
        ))
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_TIMER_OK recipe_id=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s modifier_kinds=%s speed_plus=%s size_plus=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(timer_plan.source_slot_id),
            tostring(timer_plan.payload_slot_id),
            tostring(source_job.source_modifier_kind),
            tostring(source_job.speed_plus == true),
            tostring(source_job.size_plus == true)
        ))
        log.info(string.format(
            "SPELLFORGE_SUPPORT_TRUTH_SOURCE_MODIFIER_OK kind=Timer recipe_id=%s plan_recipe_id=%s source_slot_id=%s reason=supported",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(timer_plan.source_slot_id)
        ))
    end
    if source_prefix_opcode == "Homing" then
        local inspection = homing_launch_policy.inspectSourceEntry(
            attached.plan,
            attached.plan and attached.plan.runtime_ir or nil,
            timer_plan.source.slot,
            homingPolicyOptions(options, "source", 1)
        )
        if inspection.ok ~= true then
            return timerRejected(inspection.rejection_reason or "homing_nested_runtime_deferred", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = timer_plan.source_slot_id,
            })
        end
        local applied = applyHomingPolicyToJob({
            plan = attached.plan,
            source_slot = timer_plan.source.slot,
            homing_policy = inspection,
            fanout_count = 1,
            apply_homing_direction = options.force_homing_launch_direction == true,
        }, source_job, "source", launch_payload, options)
        if applied == nil or applied.ok ~= true then
            return timerRejected(applied and applied.rejection_reason or "homing_target_missing", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = timer_plan.source_slot_id,
            })
        end
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = timer_plan.source_slot_id,
            helper_engine_id = timer_plan.source_helper_engine_id,
            slot_ids = { timer_plan.source_slot_id },
            helper_engine_ids = { timer_plan.source_helper_engine_id },
            emission_indexes = {
                timer_plan.source.slot.emission_index or timer_plan.source.helper.emission_index or 1,
            },
            timer_payload_slot_id = timer_plan.payload_slot_id,
            timer_payload_helper_engine_id = timer_plan.payload_helper_engine_id,
            timer_payload_slot_ids = timer_plan.payload_slot_ids,
            timer_payload_helper_engine_ids = timer_plan.payload_helper_engine_ids,
            timer_payload_count = timer_plan.payload_count,
            payload_multicast = timer_plan.payload_multicast == true,
            payload_pattern = timer_plan.payload_pattern == true,
            payload_pattern_kind = timer_plan.payload_pattern_kind,
            source_prefix_opcode = source_prefix_opcode,
            has_payload_homing = timer_plan.has_payload_homing == true,
            jobs = { source_job },
            homing = source_job.homing == true,
            homing_mode = source_job.homing_mode,
            homing_field = source_job.homing_field,
            homing_target_provider = source_job.homing_target_provider,
            has_payload_modifier = timer_plan.has_payload_modifier == true,
            payload_modifier_kinds = timer_plan.payload_modifier_kinds,
            timer_payload_effect_id = timer_plan.payload_effect_id,
            timer_seconds = timer_plan.timer_seconds,
            timer_delay_ticks = timer_plan.timer_delay_ticks,
            timer_delay_seconds = timer_plan.timer_seconds,
            timer_ticks_per_second = timer_plan.timer_ticks_per_second,
            timer_delay_capped = timer_plan.timer_delay_capped,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = timer_plan.payload_count,
            simple_note = "timer_v0",
            live_mode = "timer",
            cast_id = cast_id,
        }
    end

    local resolution, resolution_err = live_timer.computeResolution(launch_payload, timer_plan)
    if not resolution then
        return timerRejected("timer_resolution_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = resolution_err,
        }, "live_timer_payload_route_failed")
    end
    binding.resolution = resolution

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return timerRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = timer_plan.source_slot_id,
            helper_engine_id = timer_plan.source_helper_engine_id,
            error = enqueue.error or "enqueue failed",
            cast_id = cast_id,
        })
    end

    runtime_stats.inc("live_timer_source_jobs_enqueued")
    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    if summary.job_status == "queued" then
        orchestrator.cancel(enqueue.job_id)
    end
    if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(summary.error or "timer source launch job did not complete", {
            stage = "timer_source_launch_job",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = timer_plan.source_slot_id,
            helper_engine_id = timer_plan.source_helper_engine_id,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            job_status = summary.job_status,
            tick_result = tick_result,
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    binding.source_job_id = enqueue.job_id
    binding.source_projectile_id = summary.projectile_id
    binding.source_user_data = summary.launch_user_data
    local schedule = live_timer.schedulePayload(binding, {
        delay_ticks_override = options.timer_delay_ticks_override,
        delay_seconds_override = options.timer_delay_seconds_override,
        ttl_ticks_override = options.timer_ttl_ticks_override,
        ttl_seconds_override = options.timer_ttl_seconds_override,
        duplicate_key_suffix = options.timer_duplicate_key_suffix,
    })
    if not schedule.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(schedule.error or "timer payload schedule failed", {
            stage = "timer_payload_schedule",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = timer_plan.source_slot_id,
            helper_engine_id = timer_plan.source_helper_engine_id,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    local duplicate_schedule = nil
    if options.timer_duplicate_schedule_probe == true then
        duplicate_schedule = live_timer.schedulePayload(binding, {
            delay_ticks_override = options.timer_delay_ticks_override,
            delay_seconds_override = options.timer_delay_seconds_override,
            ttl_ticks_override = options.timer_ttl_ticks_override,
            ttl_seconds_override = options.timer_ttl_seconds_override,
            duplicate_key_suffix = options.timer_duplicate_key_suffix,
        })
    end

    local timer_status = live_timer.timerStatus(schedule.timer_id)
    log.info(string.format(
        "SPELLFORGE_LIVE_TIMER_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_slot_id=%s payload_slot_id=%s helper_engine_id=%s timer_id=%s delay_ticks=%s delay_seconds=%s due_tick=%s due_seconds=%s projectile_id=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(timer_plan.source_slot_id),
        tostring(timer_plan.payload_slot_id),
        tostring(timer_plan.source_helper_engine_id),
        tostring(schedule.timer_id),
        tostring(schedule.timer_delay_ticks),
        tostring(schedule.timer_delay_seconds),
        tostring(schedule.timer_due_tick),
        tostring(schedule.timer_due_seconds),
        tostring(summary.projectile_id)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = timer_plan.source_slot_id,
        helper_engine_id = timer_plan.source_helper_engine_id,
        slot_ids = { timer_plan.source_slot_id },
        helper_engine_ids = { timer_plan.source_helper_engine_id },
        emission_indexes = {
            timer_plan.source.slot.emission_index or timer_plan.source.helper.emission_index or 1,
        },
        timer_payload_slot_id = timer_plan.payload_slot_id,
        timer_payload_helper_engine_id = timer_plan.payload_helper_engine_id,
        timer_payload_slot_ids = timer_plan.payload_slot_ids,
        timer_payload_helper_engine_ids = timer_plan.payload_helper_engine_ids,
        timer_payload_count = timer_plan.payload_count,
        payload_multicast = timer_plan.payload_multicast == true,
        payload_pattern = timer_plan.payload_pattern == true,
        payload_pattern_kind = timer_plan.payload_pattern_kind,
        has_payload_homing = timer_plan.has_payload_homing == true,
        has_payload_modifier = timer_plan.has_payload_modifier == true,
        payload_modifier_kinds = timer_plan.payload_modifier_kinds,
        payload_pattern_direction_keys = schedule.payload_pattern_direction_keys,
        timer_payload_effect_id = timer_plan.payload_effect_id,
        timer_seconds = timer_plan.timer_seconds,
        timer_delay_ticks = schedule.timer_delay_ticks,
        timer_delay_seconds = schedule.timer_delay_seconds,
        timer_scheduled_tick = schedule.timer_scheduled_tick,
        timer_due_tick = schedule.timer_due_tick,
        timer_scheduled_seconds = schedule.timer_scheduled_seconds,
        timer_due_seconds = schedule.timer_due_seconds,
        timer_delay_semantics = "async_simulation_timer",
        timer_ticks_per_second = timer_plan.timer_ticks_per_second,
        timer_delay_capped = timer_plan.timer_delay_capped,
        timer_id = schedule.timer_id,
        timer_async_scheduled = schedule.async_scheduled == true,
        timer_pending_count = schedule.pending_count,
        timer_status = timer_status,
        timer_duplicate_suppressed = duplicate_schedule and duplicate_schedule.duplicate_suppressed == true or false,
        ir_timer_runtime_planned = schedule.ir_timer_runtime_planned == true,
        ir_timer_runtime_fallback_used = schedule.ir_timer_runtime_fallback_used == true,
        ir_timer_runtime_fallback_reason = schedule.ir_timer_runtime_fallback_reason,
        ir_timer_runtime_mismatch = schedule.ir_timer_runtime_mismatch == true,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        projectile_id_source = summary.projectile_id_source,
        projectile_registered = summary.projectile_registered == true,
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        source_jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = 1,
        payload_fanout_count = timer_plan.payload_count,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        effect_id = timer_plan.source.slot.effects and timer_plan.source.slot.effects[1] and timer_plan.source.slot.effects[1].id or nil,
        simple_note = "timer_v0",
        live_mode = "timer",
    }
end

local function tryBounceDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_bounce_attempts")
    if options.force_bounce_disabled == true then
        return bounceRejected("live_bounce_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_bounce_disabled_rejections")
    end
    if options.force_bounce_enabled ~= true and not dev.liveBounceEnabled() then
        return bounceRejected("live_bounce_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_bounce_disabled_rejections")
    end

    local capabilities = sfp_adapter.capabilities()
    if not capabilities.has_setSpellBounce
        or not capabilities.has_setSpellDetonateOnActor
        or not capabilities.has_detonateSpellAtPos
        or not capabilities.has_cancelSpell then
        return bounceRejected("sfp_bounce_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_bounce_capability_rejections")
    end

    local attached, attach_reason, attach_details = attachHelperRecordsWithSourcePolicy(compiled, options, "bounce")
    if not attached then
        attach_details = attach_details or {}
        attach_details.plan_recipe_id = attach_details.plan_recipe_id or compiled.recipe_id
        return bounceRejected(attach_reason or "helper_records_failed", attach_details)
    end

    local bounce_plan, bounce_reason = live_bounce.selectV0Plan(attached.plan, {
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_bounce_count = options.max_bounce_count,
        max_chain_hops = options.max_chain_hops,
        max_chain_jobs = options.max_chain_jobs,
        max_chain_scan_candidates = options.max_chain_scan_candidates,
        chain_scan_radius = options.chain_scan_radius,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        chaos_budget_profile = options.chaos_budget_profile,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        source_modifier_policy = attached.source_policy,
    })
    if not bounce_plan then
        return bounceRejected(bounce_reason or "bounce_v0_rejected", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if bounce_plan.has_trigger_payload == true
        and options.force_trigger_enabled ~= true
        and not dev.liveTriggerEnabled() then
        return bounceRejected("live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = bounce_plan.source_slot_id,
            payload_slot_id = bounce_plan.payload_slot_id,
            bounce_max = bounce_plan.bounce_max,
        }, "live_trigger_disabled_rejections")
    end
    if bounce_plan.has_chain_payload == true
        and (options.force_chain_runtime_disabled == true
            or (options.force_chain_runtime_enabled ~= true and not dev.liveChainRuntimeEnabled())) then
        return bounceRejected("bounce_chain_payload_disabled", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = bounce_plan.source_slot_id,
            payload_slot_id = bounce_plan.payload_slot_id,
            bounce_max = bounce_plan.bounce_max,
            chain_max_hops = bounce_plan.chain_max_hops,
        }, "live_bounce_chain_reject")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local bounce_id = string.format(
        "bounce:%s:%s:%s",
        tostring(cast_id),
        tostring(bounce_plan.source_slot_id),
        tostring(bounce_plan.bounce_max)
    )
    local chain_id = nil
    if bounce_plan.has_chain_payload == true then
        chain_id = string.format(
            "chain:%s:%s:%s:%s:bounce",
            tostring(cast_id),
            tostring(bounce_plan.source_slot_id),
            tostring(bounce_plan.payload_slot_id),
            tostring(bounce_plan.chain_max_hops)
        )
    end
    local payload_detonation_mode = nil
    if bounce_plan.has_chain_payload == true then
        payload_detonation_mode = "bounce_chain_runtime"
    elseif bounce_plan.payload_multicast == true or bounce_plan.payload_pattern == true then
        payload_detonation_mode = "bounce_trigger_payload_fanout"
    elseif bounce_plan.has_trigger_payload == true then
        payload_detonation_mode = "bounce_detonate_at_pos"
    end
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_bounce_qualified")
    if bounce_plan.has_trigger_payload == true then
        runtime_stats.inc("live_bounce_trigger_qualified")
    end
    if bounce_plan.has_chain_payload == true then
        runtime_stats.inc("chain_runtime_qualified")
        runtime_stats.inc("chain_runtime_trigger_chain_qualified")
        log.info(string.format(
            "SPELLFORGE_LIVE_BOUNCE_CHAIN_PAYLOAD_QUALIFIED recipe_id=%s plan_recipe_id=%s cast_id=%s bounce_id=%s chain_id=%s source_slot_id=%s payload_slot_id=%s requested_hops=%s max_hops=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(bounce_id),
            tostring(chain_id),
            tostring(bounce_plan.source_slot_id),
            tostring(bounce_plan.payload_slot_id),
            tostring(bounce_plan.chain_requested_hops),
            tostring(bounce_plan.chain_max_hops)
        ))
    end

    local selected_helpers = { bounce_plan.source }
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, nil)
    local source_job = job_inputs[1]
    applySourcePolicyToJob(attached, source_job, "bounce")
    local binding = {
        recipe_id = compiled.recipe_id,
        plan = attached.plan,
        cast_id = cast_id,
        bounce_id = bounce_id,
        source_slot_id = bounce_plan.source_slot_id,
        source_helper_engine_id = bounce_plan.source_helper_engine_id,
        payload_slot_id = bounce_plan.payload_slot_id,
        payload_helper_engine_id = bounce_plan.payload_helper_engine_id,
        payloads = bounce_plan.payloads,
        payload_slot_ids = bounce_plan.payload_slot_ids,
        payload_helper_engine_ids = bounce_plan.payload_helper_engine_ids,
        payload_count = bounce_plan.payload_count,
        payload_group_key = bounce_plan.payload_group_key,
        payload_multicast = bounce_plan.payload_multicast == true,
        payload_pattern = bounce_plan.payload_pattern == true,
        payload_pattern_kind = bounce_plan.payload_pattern_kind,
        payload_pattern_op = bounce_plan.payload_pattern_op,
        max_payload_fanout = bounce_plan.max_payload_fanout,
        max_projectiles = bounce_plan.max_projectiles,
        has_trigger_payload = bounce_plan.has_trigger_payload == true,
        has_chain_payload = bounce_plan.has_chain_payload == true,
        chain_id = chain_id,
        chain_shape = bounce_plan.chain_shape,
        chain_requested_hops = bounce_plan.chain_requested_hops,
        chain_max_hops = bounce_plan.chain_max_hops,
        chain_targeting_mode = "no_immediate_repeat",
        chain_candidate_provider = options.chain_candidate_provider or options.candidate_provider,
        chain_source_target = options.chain_source_target,
        candidate_cap = options.max_chain_scan_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES,
        scan_actor_cap = options.max_chain_scan_actors or limits.MAX_CHAIN_SCAN_ACTORS,
        scan_radius = options.chain_scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
        max_chain_ticks = options.max_chain_ticks,
        max_jobs_per_tick = bounce_plan.max_jobs_per_tick,
        force_chain_runtime_enabled = options.force_chain_runtime_enabled == true,
        bounce_max = bounce_plan.bounce_max,
        bounce_power = bounce_plan.bounce_power,
        actor = launch_payload.actor or launch_payload.sender,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        mute_audio = launch_payload.mute_audio or launch_payload.muteAudio,
        mute_light = launch_payload.mute_light or launch_payload.muteLight,
        max_live_launches_per_tick = bounce_plan.max_live_launches_per_tick,
        chaos_budget_profile = bounce_plan.chaos_budget_profile,
        allow_pending_launch_jobs = bounce_plan.allow_pending_launch_jobs == true,
        force_payload_multicast_enabled = options.force_payload_multicast_enabled == true,
        force_payload_pattern_enabled = options.force_payload_pattern_enabled == true,
    }
    live_bounce.decorateSourceJob(source_job, binding)
    local chain_binding = nil
    if bounce_plan.has_chain_payload == true then
        chain_binding = {
            plan = attached.plan,
            recipe_id = compiled.recipe_id,
            display_recipe_id = result_recipe_id,
            cast_id = cast_id,
            chain_id = chain_id,
            chain_shape = "trigger_payload_chain",
            source_slot_id = bounce_plan.source_slot_id,
            source_helper_engine_id = bounce_plan.source_helper_engine_id,
            payload_slot_id = bounce_plan.payload_slot_id,
            payload_helper_engine_id = bounce_plan.payload_helper_engine_id,
            payload_effect_id = bounce_plan.payload_effect_id,
            payload_emission_index = bounce_plan.chain_plan
                and bounce_plan.chain_plan.payload
                and (bounce_plan.chain_plan.payload.slot.emission_index or bounce_plan.chain_plan.payload.helper.emission_index)
                or nil,
            payload_group_index = bounce_plan.chain_plan
                and bounce_plan.chain_plan.payload
                and (bounce_plan.chain_plan.payload.slot.group_index or bounce_plan.chain_plan.payload.helper.group_index)
                or nil,
            root_source_slot_id = bounce_plan.source_slot_id,
            requested_hops = bounce_plan.chain_requested_hops,
            max_hops = bounce_plan.chain_max_hops,
            candidate_cap = options.max_chain_scan_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES,
            scan_actor_cap = options.max_chain_scan_actors or limits.MAX_CHAIN_SCAN_ACTORS,
            targeting_mode = "no_immediate_repeat",
            actor = launch_payload.actor or launch_payload.sender,
            candidate_provider = options.chain_candidate_provider or options.candidate_provider,
            scan_radius = options.chain_scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
            max_jobs_per_tick = options.max_jobs_per_tick,
            max_chain_jobs = options.max_chain_jobs,
            max_live_launches_per_tick = options.max_live_launches_per_tick,
            chaos_budget_profile = options.chaos_budget_profile,
            force_enabled = options.force_chain_runtime_enabled == true,
        }
        live_chain.decorateSourceJob(source_job, chain_binding)
    end

    if options.dry_run == true then
        local probe_source_job = nil
        local probe_projectile_id = nil
        if options.register_bounce_probe_binding == true then
            binding.source_job_id = string.format("probe_job:%s", tostring(cast_id))
            if not live_bounce.registerBinding(binding) then
                return bounceRejected("bounce_probe_binding_failed", {
                    recipe_id = result_recipe_id,
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = bounce_plan.source_slot_id,
                    payload_slot_id = bounce_plan.payload_slot_id,
                    cast_id = cast_id,
                })
            end
            if chain_binding then
                chain_binding.source_job_id = binding.source_job_id
                if not live_chain.registerBinding(chain_binding) then
                    return bounceRejected("bounce_chain_probe_binding_failed", {
                        recipe_id = result_recipe_id,
                        plan_recipe_id = compiled.recipe_id,
                        source_slot_id = bounce_plan.source_slot_id,
                        payload_slot_id = bounce_plan.payload_slot_id,
                        chain_id = chain_id,
                        cast_id = cast_id,
                    }, "live_bounce_chain_reject")
                end
            end

            local source_payload = source_job.payload or {}
            local source_user_data = sfp_userdata.buildHelperUserData({
                runtime = "2.2c_live_helper",
                mapping = helper_records.getByEngineId(bounce_plan.source_helper_engine_id),
                recipe_id = compiled.recipe_id,
                slot_id = bounce_plan.source_slot_id,
                helper_engine_id = bounce_plan.source_helper_engine_id,
                job_kind = orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND,
                job_id = binding.source_job_id,
                cast_id = cast_id,
                emission_index = source_job.emission_index,
                group_index = source_job.group_index,
                fanout_count = source_job.fanout_count,
                source_slot_id = source_payload.source_slot_id,
                source_prefix_opcode = source_payload.source_prefix_opcode,
                source_postfix_opcode = source_payload.source_postfix_opcode,
                source_helper_engine_id = source_payload.source_helper_engine_id,
                trigger_source_slot_id = source_payload.trigger_source_slot_id,
                trigger_payload_slot_id = source_payload.trigger_payload_slot_id,
                has_trigger_payload = source_payload.has_trigger_payload,
                bounce_runtime = source_payload.bounce_runtime,
                bounce_role = source_payload.bounce_role,
                bounce_id = source_payload.bounce_id,
                bounce_max = source_payload.bounce_max,
                bounce_power = source_payload.bounce_power,
                bounce_detonate_on_actor_hit = source_payload.bounce_detonate_on_actor_hit,
                bounce_trigger_payload_slot_id = source_payload.bounce_trigger_payload_slot_id,
                branch_scope = source_payload.branch_scope,
                branch_id = source_payload.branch_id,
                branch_parent_id = source_payload.branch_parent_id,
                branch_kind = source_payload.branch_kind,
                branch_index = source_payload.branch_index,
                branch_count = source_payload.branch_count,
                source_modifier_kind = source_payload.source_modifier_kind,
                speed_plus = source_payload.speed_plus,
                speed_plus_mode = source_payload.speed_plus_mode,
                speed_plus_value = source_payload.speed_plus_value,
                speed_plus_base_speed = source_payload.speed_plus_base_speed,
                speed_plus_multiplier = source_payload.speed_plus_multiplier,
                speed_plus_speed = source_payload.speed_plus_speed,
                speed_plus_max_speed = source_payload.speed_plus_max_speed,
                speed_plus_field = source_payload.speed_plus_field,
                speed_plus_capped = source_payload.speed_plus_capped,
                size_plus = source_payload.size_plus,
                size_plus_mode = source_payload.size_plus_mode,
                size_plus_value = source_payload.size_plus_value,
                size_plus_multiplier = source_payload.size_plus_multiplier,
                size_plus_field = source_payload.size_plus_field,
                size_plus_capped = source_payload.size_plus_capped,
                size_plus_base_area = source_payload.size_plus_base_area,
                size_plus_area = source_payload.size_plus_area,
            })
            probe_projectile_id = string.format("probe_projectile:%s:%s", tostring(cast_id), tostring(bounce_plan.source_slot_id))
            probe_source_job = {
                job_id = binding.source_job_id,
                job_status = "complete",
                slot_id = bounce_plan.source_slot_id,
                helper_engine_id = bounce_plan.source_helper_engine_id,
                cast_id = cast_id,
                fanout_count = 1,
                bounce_runtime = true,
                bounce_role = "source",
                bounce_id = bounce_id,
                bounce_max = bounce_plan.bounce_max,
                bounce_power = bounce_plan.bounce_power,
                bounceEnabled = true,
                bounceMax = bounce_plan.bounce_max,
                bouncePower = bounce_plan.bounce_power,
                detonateOnActorHit = false,
                source_modifier_kind = source_payload.source_modifier_kind,
                speed = source_payload.speed,
                maxSpeed = source_payload.maxSpeed,
                speed_plus = source_payload.speed_plus,
                speed_plus_field = source_payload.speed_plus_field,
                speed_plus_speed = source_payload.speed_plus_speed,
                speed_plus_max_speed = source_payload.speed_plus_max_speed,
                size_plus = source_payload.size_plus,
                size_plus_field = source_payload.size_plus_field,
                size_plus_base_area = source_payload.size_plus_base_area,
                size_plus_area = source_payload.size_plus_area,
                launch_accepted = false,
                projectile_id = probe_projectile_id,
                projectile_registered = false,
                launch_direction = launch_payload.direction,
                launch_user_data = source_user_data,
            }
        end

        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            bounce_probe_binding_registered = options.register_bounce_probe_binding == true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = bounce_plan.source_slot_id,
            helper_engine_id = bounce_plan.source_helper_engine_id,
            source_slot_id = bounce_plan.source_slot_id,
            source_helper_engine_id = bounce_plan.source_helper_engine_id,
            source_modifier_kind = source_job and source_job.source_modifier_kind or nil,
            speed_plus = source_job and source_job.speed_plus or nil,
            speed_plus_field = source_job and source_job.speed_plus_field or nil,
            speed_plus_speed = source_job and source_job.speed_plus_speed or nil,
            speed_plus_max_speed = source_job and source_job.speed_plus_max_speed or nil,
            size_plus = source_job and source_job.size_plus or nil,
            size_plus_field = source_job and source_job.size_plus_field or nil,
            size_plus_base_area = source_job and source_job.size_plus_base_area or nil,
            size_plus_area = source_job and source_job.size_plus_area or nil,
            slot_ids = { bounce_plan.source_slot_id },
            helper_engine_ids = { bounce_plan.source_helper_engine_id },
            bounce_id = bounce_id,
            bounce_mode = bounce_plan.has_trigger_payload == true and payload_detonation_mode or "source",
            bounce_max = bounce_plan.bounce_max,
            bounce_power = bounce_plan.bounce_power,
            bounce_detonate_on_actor_hit = false,
            has_trigger_payload = bounce_plan.has_trigger_payload == true,
            bounce_trigger_payload_slot_id = bounce_plan.has_trigger_payload == true and bounce_plan.payload_slot_id or nil,
            trigger_payload_slot_id = bounce_plan.has_trigger_payload == true and bounce_plan.payload_slot_id or nil,
            trigger_payload_helper_engine_id = bounce_plan.has_trigger_payload == true and bounce_plan.payload_helper_engine_id or nil,
            trigger_payload_slot_ids = bounce_plan.has_trigger_payload == true and bounce_plan.payload_slot_ids or nil,
            trigger_payload_helper_engine_ids = bounce_plan.has_trigger_payload == true and bounce_plan.payload_helper_engine_ids or nil,
            trigger_payload_count = bounce_plan.has_trigger_payload == true and bounce_plan.payload_count or nil,
            payload_count = bounce_plan.payload_count or 0,
            payload_helper_engine_id = bounce_plan.has_trigger_payload == true and bounce_plan.payload_helper_engine_id or nil,
            payload_multicast = bounce_plan.payload_multicast == true,
            payload_pattern = bounce_plan.payload_pattern == true,
            payload_pattern_kind = bounce_plan.payload_pattern_kind,
            payload_projectile_launches = 0,
            payload_detonation_mode = payload_detonation_mode,
            payload_chain_runtime = bounce_plan.has_chain_payload == true,
            has_chain_payload = bounce_plan.has_chain_payload == true,
            chain_id = chain_id,
            chain_shape = bounce_plan.chain_shape,
            chain_requested_hops = bounce_plan.chain_requested_hops,
            chain_max_hops = bounce_plan.chain_max_hops,
            targeting_mode = bounce_plan.has_chain_payload == true and "no_immediate_repeat" or nil,
            expected_bounce_event_count = bounce_plan.bounce_max,
            projectile_id = probe_projectile_id,
            projectile_ids = probe_projectile_id and { probe_projectile_id } or {},
            jobs = probe_source_job and { probe_source_job } or nil,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = bounce_plan.has_trigger_payload == true and bounce_plan.payload_count or nil,
            simple_note = "bounce_v0",
            live_mode = "bounce",
            cast_id = cast_id,
        }
    end

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bounceRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = bounce_plan.source_slot_id,
            helper_engine_id = bounce_plan.source_helper_engine_id,
            payload_slot_id = bounce_plan.payload_slot_id,
            bounce_max = bounce_plan.bounce_max,
            error = enqueue.error or "enqueue failed",
            cast_id = cast_id,
        })
    end

    binding.source_job_id = enqueue.job_id
    live_bounce.registerBinding(binding)
    if chain_binding then
        chain_binding.source_job_id = enqueue.job_id
        if not live_chain.registerBinding(chain_binding) then
            orchestrator.cancel(enqueue.job_id)
            return bounceRejected("bounce_chain_binding_failed", {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = bounce_plan.source_slot_id,
                payload_slot_id = bounce_plan.payload_slot_id,
                chain_id = chain_id,
                cast_id = cast_id,
            }, "live_bounce_chain_reject")
        end
    end
    runtime_stats.inc("live_bounce_source_jobs_enqueued")

    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    if summary.job_status == "queued" then
        orchestrator.cancel(enqueue.job_id)
    end
    log.info(string.format(
        "SPELLFORGE_BOUNCE_SOURCE_LAUNCH_CONFIG recipe_id=%s display_recipe_id=%s cast_id=%s source_slot_id=%s helper_engine_id=%s projectile_id=%s projectile_id_source=%s bounceEnabled=%s bounceMax=%s bouncePower=%s detonateOnActorHit=%s post_launch_bounce_ok=%s post_launch_actor_toggle_ok=%s launch_accepted=%s job_status=%s",
        tostring(compiled.recipe_id),
        tostring(result_recipe_id),
        tostring(cast_id),
        tostring(bounce_plan.source_slot_id),
        tostring(bounce_plan.source_helper_engine_id),
        tostring(summary.projectile_id),
        tostring(summary.projectile_id_source),
        tostring(summary.bounceEnabled == true),
        tostring(summary.bounceMax),
        tostring(summary.bouncePower),
        tostring(summary.detonateOnActorHit),
        tostring(summary.post_launch_bounce_ok == true),
        tostring(summary.post_launch_detonate_on_actor_ok == true),
        tostring(summary.launch_accepted == true),
        tostring(summary.job_status)
    ))
    if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(summary.error or "bounce source launch job did not complete", {
            stage = "bounce_source_launch_job",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = bounce_plan.source_slot_id,
            helper_engine_id = bounce_plan.source_helper_engine_id,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            job_status = summary.job_status,
            tick_result = tick_result,
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    log.info(string.format(
        "SPELLFORGE_LIVE_BOUNCE_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s bounce_id=%s source_slot_id=%s payload_slot_id=%s bounce_max=%s bounce_power=%s projectile_id=%s bounce_enabled=%s detonate_on_actor_hit=%s post_launch_bounce_ok=%s post_launch_actor_toggle_ok=%s post_launch_bounce_error=%s post_launch_actor_toggle_error=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(bounce_id),
        tostring(bounce_plan.source_slot_id),
        tostring(bounce_plan.payload_slot_id),
        tostring(bounce_plan.bounce_max),
        tostring(bounce_plan.bounce_power),
        tostring(summary.projectile_id),
        tostring(summary.bounceEnabled == true),
        tostring(summary.detonateOnActorHit),
        tostring(summary.post_launch_bounce_ok == true),
        tostring(summary.post_launch_detonate_on_actor_ok == true),
        tostring(summary.post_launch_bounce_error),
        tostring(summary.post_launch_detonate_on_actor_error)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = bounce_plan.source_slot_id,
        helper_engine_id = bounce_plan.source_helper_engine_id,
        slot_ids = { bounce_plan.source_slot_id },
        helper_engine_ids = { bounce_plan.source_helper_engine_id },
        source_modifier_kind = summary.source_modifier_kind,
        speed_plus = summary.speed_plus,
        speed_plus_field = summary.speed_plus_field,
        speed_plus_speed = summary.speed_plus_speed,
        speed_plus_max_speed = summary.speed_plus_max_speed,
        size_plus = summary.size_plus,
        size_plus_field = summary.size_plus_field,
        size_plus_base_area = summary.size_plus_base_area,
        size_plus_area = summary.size_plus_area,
        bounce_id = bounce_id,
        bounce_max = bounce_plan.bounce_max,
        bounce_power = bounce_plan.bounce_power,
        bounce_detonate_on_actor_hit = false,
        post_launch_bounce_ok = summary.post_launch_bounce_ok == true,
        post_launch_detonate_on_actor_ok = summary.post_launch_detonate_on_actor_ok == true,
        post_launch_bounce_error = summary.post_launch_bounce_error,
        post_launch_detonate_on_actor_error = summary.post_launch_detonate_on_actor_error,
        has_trigger_payload = bounce_plan.has_trigger_payload == true,
        trigger_payload_slot_id = bounce_plan.payload_slot_id,
        trigger_payload_helper_engine_id = bounce_plan.payload_helper_engine_id,
        trigger_payload_slot_ids = bounce_plan.payload_slot_ids,
        trigger_payload_helper_engine_ids = bounce_plan.payload_helper_engine_ids,
        trigger_payload_count = bounce_plan.payload_count,
        payload_multicast = bounce_plan.payload_multicast == true,
        payload_pattern = bounce_plan.payload_pattern == true,
        payload_pattern_kind = bounce_plan.payload_pattern_kind,
        payload_projectile_launches = 0,
        payload_detonation_mode = payload_detonation_mode,
        payload_chain_runtime = bounce_plan.has_chain_payload == true,
        has_chain_payload = bounce_plan.has_chain_payload == true,
        chain_id = chain_id,
        chain_shape = bounce_plan.chain_shape,
        chain_requested_hops = bounce_plan.chain_requested_hops,
        chain_max_hops = bounce_plan.chain_max_hops,
        targeting_mode = bounce_plan.has_chain_payload == true and "no_immediate_repeat" or nil,
        expected_bounce_event_count = bounce_plan.bounce_max,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        projectile_id_source = summary.projectile_id_source,
        projectile_registered = summary.projectile_registered == true,
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = 1,
        payload_fanout_count = bounce_plan.payload_count,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        effect_id = bounce_plan.source.slot.effects and bounce_plan.source.slot.effects[1] and bounce_plan.source.slot.effects[1].id or nil,
        simple_note = "bounce_v0",
        live_mode = "bounce",
    }
end

local function tryPierceDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_pierce_attempts")
    if options.force_pierce_disabled == true then
        return pierceRejected("live_pierce_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_pierce_disabled_rejections")
    end
    if options.force_pierce_enabled ~= true and not dev.livePierceEnabled() then
        return pierceRejected("live_pierce_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_pierce_disabled_rejections")
    end

    local capabilities = sfp_adapter.capabilities()
    if not capabilities.has_setSpellPiercing and not capabilities.has_setSpellPhysics then
        return pierceRejected("sfp_pierce_event_unavailable", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_pierce_capability_rejections")
    end

    local attached, attach_reason, attach_details = attachHelperRecordsWithSourcePolicy(compiled, options, "pierce")
    if not attached then
        attach_details = attach_details or {}
        attach_details.plan_recipe_id = attach_details.plan_recipe_id or compiled.recipe_id
        return pierceRejected(attach_reason or "helper_records_failed", attach_details)
    end

    local pierce_plan, pierce_reason = live_pierce.selectV0Plan(attached.plan, {
        max_pierce_count = options.max_pierce_count,
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_hops = options.max_chain_hops,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        allow_chain_multicast = dev.liveChainMulticastEnabled(),
        chaos_budget_profile = options.chaos_budget_profile,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        source_modifier_policy = attached.source_policy,
    })
    if not pierce_plan then
        return pierceRejected(pierce_reason or "pierce_v0_rejected", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if pierce_plan.has_trigger_payload == true and (options.force_trigger_enabled ~= true and not dev.liveTriggerEnabled()) then
        return pierceRejected("live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = pierce_plan.source_slot_id,
            payload_slot_id = pierce_plan.payload_slot_id,
        }, "live_trigger_disabled_rejections")
    end
    if pierce_plan.has_chain_payload == true
        and (options.force_chain_runtime_disabled == true
            or (options.force_chain_runtime_enabled ~= true and not dev.liveChainRuntimeEnabled())) then
        return pierceRejected("pierce_chain_payload_disabled", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = pierce_plan.source_slot_id,
            payload_slot_id = pierce_plan.payload_slot_id,
        }, "live_pierce_deferred_reject")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local pierce_id = string.format("pierce:%s:%s:%s", tostring(cast_id), tostring(pierce_plan.source_slot_id), tostring(pierce_plan.pierce_limit))
    local chain_id = pierce_plan.has_chain_payload == true
        and string.format("chain:%s:%s:%s", tostring(cast_id), tostring(pierce_plan.source_slot_id), tostring(pierce_plan.payload_slot_id))
        or nil
    local job_inputs = buildJobInputs({ pierce_plan.source }, compiled.recipe_id, cast_id, launch_payload, nil)
    local source_job = job_inputs[1]
    if not source_job then
        return pierceRejected("source_job_missing", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = pierce_plan.source_slot_id,
        })
    end
    applySourcePolicyToJob(attached, source_job, "pierce")

    local binding = {
        plan = attached.plan,
        recipe_id = compiled.recipe_id,
        display_recipe_id = result_recipe_id,
        cast_id = cast_id,
        pierce_id = pierce_id,
        source_slot_id = pierce_plan.source_slot_id,
        source_helper_engine_id = pierce_plan.source_helper_engine_id,
        payload_slot_id = pierce_plan.payload_slot_id,
        payload_helper_engine_id = pierce_plan.payload_helper_engine_id,
        payloads = pierce_plan.payloads,
        payload_slot_ids = pierce_plan.payload_slot_ids,
        payload_helper_engine_ids = pierce_plan.payload_helper_engine_ids,
        payload_count = pierce_plan.payload_count,
        payload_multicast = pierce_plan.payload_multicast == true,
        payload_pattern = pierce_plan.payload_pattern == true,
        payload_pattern_kind = pierce_plan.payload_pattern_kind,
        has_trigger_payload = pierce_plan.has_trigger_payload == true,
        has_chain_payload = pierce_plan.has_chain_payload == true,
        chain_id = chain_id,
        chain_shape = pierce_plan.chain_shape,
        chain_requested_hops = pierce_plan.chain_requested_hops,
        chain_max_hops = pierce_plan.chain_max_hops,
        chain_targeting_mode = "no_immediate_repeat",
        chain_candidate_provider = options.chain_candidate_provider or options.candidate_provider,
        max_chain_ticks = options.max_chain_ticks,
        max_jobs_per_tick = pierce_plan.max_jobs_per_tick,
        force_chain_runtime_enabled = options.force_chain_runtime_enabled == true,
        pierce_limit = pierce_plan.pierce_limit,
        actor = launch_payload.actor or launch_payload.sender,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        max_payload_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_live_launches_per_tick = pierce_plan.max_live_launches_per_tick,
        chaos_budget_profile = pierce_plan.chaos_budget_profile,
        force_payload_multicast_enabled = options.force_payload_multicast_enabled == true,
        force_payload_pattern_enabled = options.force_payload_pattern_enabled == true,
    }
    local chain_binding = nil
    if pierce_plan.has_chain_payload == true then
        chain_binding = {
            plan = attached.plan,
            recipe_id = compiled.recipe_id,
            display_recipe_id = result_recipe_id,
            cast_id = cast_id,
            chain_id = chain_id,
            chain_shape = "trigger_payload_chain",
            source_slot_id = pierce_plan.source_slot_id,
            source_helper_engine_id = pierce_plan.source_helper_engine_id,
            payload_slot_id = pierce_plan.payload_slot_id,
            payload_helper_engine_id = pierce_plan.payload_helper_engine_id,
            root_source_slot_id = pierce_plan.source_slot_id,
            requested_hops = pierce_plan.chain_requested_hops,
            max_hops = pierce_plan.chain_max_hops,
            candidate_cap = options.max_chain_scan_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES,
            scan_actor_cap = options.max_chain_scan_actors or limits.MAX_CHAIN_SCAN_ACTORS,
            targeting_mode = "no_immediate_repeat",
            actor = launch_payload.actor or launch_payload.sender,
            candidate_provider = options.chain_candidate_provider or options.candidate_provider,
            scan_radius = options.chain_scan_radius or limits.MAX_CHAIN_SCAN_RADIUS,
            max_jobs_per_tick = options.max_jobs_per_tick,
            max_chain_jobs = options.max_chain_jobs,
            max_live_launches_per_tick = options.max_live_launches_per_tick,
            chaos_budget_profile = options.chaos_budget_profile,
            force_enabled = options.force_chain_runtime_enabled == true,
        }
        live_chain.decorateSourceJob(source_job, chain_binding)
    end
    live_pierce.decorateSourceJob(source_job, binding)

    if options.dry_run == true then
        local probe_source_job = nil
        local probe_projectile_id = nil
        if options.register_pierce_probe_binding == true then
            binding.source_job_id = string.format("probe_job:%s", tostring(cast_id))
            if not live_pierce.registerBinding(binding) then
                return pierceRejected("pierce_probe_binding_failed", {
                    plan_recipe_id = compiled.recipe_id,
                    source_slot_id = pierce_plan.source_slot_id,
                    payload_slot_id = pierce_plan.payload_slot_id,
                })
            end
            if chain_binding then
                chain_binding.source_job_id = binding.source_job_id
                if not live_chain.registerBinding(chain_binding) then
                    return pierceRejected("pierce_chain_probe_binding_failed", {
                        plan_recipe_id = compiled.recipe_id,
                        source_slot_id = pierce_plan.source_slot_id,
                        payload_slot_id = pierce_plan.payload_slot_id,
                    }, "live_pierce_deferred_reject")
                end
            end

            local source_payload = source_job.payload or {}
            local source_user_data = sfp_userdata.buildHelperUserData({
                runtime = "2.2c_live_helper",
                mapping = helper_records.getByEngineId(pierce_plan.source_helper_engine_id),
                recipe_id = compiled.recipe_id,
                slot_id = pierce_plan.source_slot_id,
                helper_engine_id = pierce_plan.source_helper_engine_id,
                job_kind = orchestrator.LIVE_SIMPLE_LAUNCH_JOB_KIND,
                job_id = binding.source_job_id,
                cast_id = cast_id,
                emission_index = source_job.emission_index,
                group_index = source_job.group_index,
                fanout_count = source_job.fanout_count,
                source_slot_id = source_payload.source_slot_id,
                source_prefix_opcode = source_payload.source_prefix_opcode,
                source_postfix_opcode = source_payload.source_postfix_opcode,
                source_helper_engine_id = source_payload.source_helper_engine_id,
                trigger_source_slot_id = source_payload.trigger_source_slot_id,
                trigger_payload_slot_id = source_payload.trigger_payload_slot_id,
                trigger_payload_slot_ids = source_payload.trigger_payload_slot_ids,
                has_trigger_payload = source_payload.has_trigger_payload,
                has_chain_payload = source_payload.has_chain_payload,
                payload_multicast = source_payload.payload_multicast,
                payload_pattern = source_payload.payload_pattern,
                payload_pattern_kind = source_payload.payload_pattern_kind,
                pierce_runtime = source_payload.pierce_runtime,
                pierce_role = source_payload.pierce_role,
                pierce_id = source_payload.pierce_id,
                pierce_limit = source_payload.pierce_limit,
                pierce_trigger_payload_slot_id = source_payload.pierce_trigger_payload_slot_id,
                branch_scope = source_payload.branch_scope,
                branch_id = source_payload.branch_id,
                branch_parent_id = source_payload.branch_parent_id,
                branch_kind = source_payload.branch_kind,
                branch_index = source_payload.branch_index,
                branch_count = source_payload.branch_count,
                source_modifier_kind = source_payload.source_modifier_kind,
                speed_plus = source_payload.speed_plus,
                speed_plus_mode = source_payload.speed_plus_mode,
                speed_plus_value = source_payload.speed_plus_value,
                speed_plus_base_speed = source_payload.speed_plus_base_speed,
                speed_plus_multiplier = source_payload.speed_plus_multiplier,
                speed_plus_speed = source_payload.speed_plus_speed,
                speed_plus_max_speed = source_payload.speed_plus_max_speed,
                speed_plus_field = source_payload.speed_plus_field,
                speed_plus_capped = source_payload.speed_plus_capped,
                size_plus = source_payload.size_plus,
                size_plus_mode = source_payload.size_plus_mode,
                size_plus_value = source_payload.size_plus_value,
                size_plus_multiplier = source_payload.size_plus_multiplier,
                size_plus_field = source_payload.size_plus_field,
                size_plus_capped = source_payload.size_plus_capped,
                size_plus_base_area = source_payload.size_plus_base_area,
                size_plus_area = source_payload.size_plus_area,
            })
            probe_projectile_id = string.format("probe_projectile:%s:%s", tostring(cast_id), tostring(pierce_plan.source_slot_id))
            probe_source_job = {
                job_id = binding.source_job_id,
                job_status = "complete",
                slot_id = pierce_plan.source_slot_id,
                helper_engine_id = pierce_plan.source_helper_engine_id,
                cast_id = cast_id,
                fanout_count = 1,
                pierce_runtime = true,
                pierce_role = "source",
                pierce_id = pierce_id,
                pierce_limit = pierce_plan.pierce_limit,
                piercing = true,
                pierceLimit = pierce_plan.pierce_limit,
                source_modifier_kind = source_payload.source_modifier_kind,
                speed = source_payload.speed,
                maxSpeed = source_payload.maxSpeed,
                speed_plus = source_payload.speed_plus,
                speed_plus_field = source_payload.speed_plus_field,
                speed_plus_speed = source_payload.speed_plus_speed,
                speed_plus_max_speed = source_payload.speed_plus_max_speed,
                size_plus = source_payload.size_plus,
                size_plus_field = source_payload.size_plus_field,
                size_plus_base_area = source_payload.size_plus_base_area,
                size_plus_area = source_payload.size_plus_area,
                launch_accepted = false,
                projectile_id = probe_projectile_id,
                projectile_registered = false,
                launch_direction = launch_payload.direction,
                launch_user_data = source_user_data,
            }
        end
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            pierce_probe_binding_registered = options.register_pierce_probe_binding == true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = pierce_plan.source_slot_id,
            helper_engine_id = pierce_plan.source_helper_engine_id,
            source_slot_id = pierce_plan.source_slot_id,
            source_helper_engine_id = pierce_plan.source_helper_engine_id,
            source_modifier_kind = source_job and source_job.source_modifier_kind or nil,
            speed_plus = source_job and source_job.speed_plus or nil,
            speed_plus_field = source_job and source_job.speed_plus_field or nil,
            speed_plus_speed = source_job and source_job.speed_plus_speed or nil,
            speed_plus_max_speed = source_job and source_job.speed_plus_max_speed or nil,
            size_plus = source_job and source_job.size_plus or nil,
            size_plus_field = source_job and source_job.size_plus_field or nil,
            size_plus_base_area = source_job and source_job.size_plus_base_area or nil,
            size_plus_area = source_job and source_job.size_plus_area or nil,
            slot_ids = { pierce_plan.source_slot_id },
            helper_engine_ids = { pierce_plan.source_helper_engine_id },
            pierce_id = pierce_id,
            pierce_mode = pierce_plan.has_trigger_payload == true and "trigger_payload" or "source",
            pierce_limit = pierce_plan.pierce_limit,
            piercing = true,
            pierceLimit = pierce_plan.pierce_limit,
            has_trigger_payload = pierce_plan.has_trigger_payload == true,
            trigger_payload_slot_id = pierce_plan.payload_slot_id,
            trigger_payload_helper_engine_id = pierce_plan.payload_helper_engine_id,
            trigger_payload_slot_ids = pierce_plan.payload_slot_ids,
            trigger_payload_helper_engine_ids = pierce_plan.payload_helper_engine_ids,
            trigger_payload_count = pierce_plan.payload_count,
            payload_count = pierce_plan.payload_count or 0,
            payload_multicast = pierce_plan.payload_multicast == true,
            payload_pattern = pierce_plan.payload_pattern == true,
            payload_pattern_kind = pierce_plan.payload_pattern_kind,
            payload_chain_runtime = pierce_plan.has_chain_payload == true,
            has_chain_payload = pierce_plan.has_chain_payload == true,
            chain_id = chain_id,
            chain_shape = pierce_plan.chain_shape,
            chain_requested_hops = pierce_plan.chain_requested_hops,
            chain_max_hops = pierce_plan.chain_max_hops,
            projectile_id = probe_projectile_id,
            projectile_ids = probe_projectile_id and { probe_projectile_id } or {},
            jobs = probe_source_job and { probe_source_job } or nil,
            cast_id = cast_id,
            runtime = "2.2c_live_helper",
            fallback = false,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = pierce_plan.payload_count,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            effect_id = pierce_plan.source.slot.effects and pierce_plan.source.slot.effects[1] and pierce_plan.source.slot.effects[1].id or nil,
            simple_note = "pierce_v0",
            live_mode = "pierce",
        }
    end

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        return pierceRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            error = enqueue.error,
        })
    end
    binding.source_job_id = enqueue.job_id
    if not live_pierce.registerBinding(binding) then
        orchestrator.cancel(enqueue.job_id)
        return pierceRejected("pierce_binding_failed", {
            plan_recipe_id = compiled.recipe_id,
            source_slot_id = pierce_plan.source_slot_id,
            payload_slot_id = pierce_plan.payload_slot_id,
        })
    end
    if chain_binding then
        chain_binding.source_job_id = enqueue.job_id
        if not live_chain.registerBinding(chain_binding) then
            orchestrator.cancel(enqueue.job_id)
            return pierceRejected("pierce_chain_binding_failed", {
                plan_recipe_id = compiled.recipe_id,
                source_slot_id = pierce_plan.source_slot_id,
                payload_slot_id = pierce_plan.payload_slot_id,
            }, "live_pierce_deferred_reject")
        end
    end

    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    log.info(string.format(
        "SPELLFORGE_PIERCE_SOURCE_LAUNCH_CONFIG recipe_id=%s display_recipe_id=%s cast_id=%s source_slot_id=%s helper_engine_id=%s projectile_id=%s projectile_id_source=%s piercing=%s pierceLimit=%s post_launch_pierce_ok=%s launch_accepted=%s job_status=%s",
        tostring(compiled.recipe_id),
        tostring(result_recipe_id),
        tostring(cast_id),
        tostring(pierce_plan.source_slot_id),
        tostring(pierce_plan.source_helper_engine_id),
        tostring(summary.projectile_id),
        tostring(summary.projectile_id_source),
        tostring(summary.piercing == true),
        tostring(summary.pierceLimit),
        tostring(summary.post_launch_pierce_ok == true),
        tostring(summary.launch_accepted == true),
        tostring(summary.job_status)
    ))
    log.info(string.format(
        "SPELLFORGE_LIVE_PIERCE_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s pierce_id=%s source_slot_id=%s payload_slot_id=%s pierce_limit=%s projectile_id=%s piercing=%s post_launch_pierce_ok=%s post_launch_pierce_error=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(pierce_id),
        tostring(pierce_plan.source_slot_id),
        tostring(pierce_plan.payload_slot_id),
        tostring(pierce_plan.pierce_limit),
        tostring(summary.projectile_id),
        tostring(summary.piercing == true),
        tostring(summary.post_launch_pierce_ok == true),
        tostring(summary.post_launch_pierce_error)
    ))
    runtime_stats.inc("live_pierce_source_ok")
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = pierce_plan.source_slot_id,
        helper_engine_id = pierce_plan.source_helper_engine_id,
        slot_ids = { pierce_plan.source_slot_id },
        helper_engine_ids = { pierce_plan.source_helper_engine_id },
        source_modifier_kind = summary.source_modifier_kind,
        speed_plus = summary.speed_plus,
        speed_plus_field = summary.speed_plus_field,
        speed_plus_speed = summary.speed_plus_speed,
        speed_plus_max_speed = summary.speed_plus_max_speed,
        size_plus = summary.size_plus,
        size_plus_field = summary.size_plus_field,
        size_plus_base_area = summary.size_plus_base_area,
        size_plus_area = summary.size_plus_area,
        pierce_id = pierce_id,
        pierce_limit = pierce_plan.pierce_limit,
        piercing = summary.piercing == true,
        pierceLimit = summary.pierceLimit,
        post_launch_pierce_ok = summary.post_launch_pierce_ok == true,
        post_launch_pierce_error = summary.post_launch_pierce_error,
        has_trigger_payload = pierce_plan.has_trigger_payload == true,
        trigger_payload_slot_id = pierce_plan.payload_slot_id,
        trigger_payload_helper_engine_id = pierce_plan.payload_helper_engine_id,
        trigger_payload_slot_ids = pierce_plan.payload_slot_ids,
        trigger_payload_helper_engine_ids = pierce_plan.payload_helper_engine_ids,
        trigger_payload_count = pierce_plan.payload_count,
        payload_multicast = pierce_plan.payload_multicast == true,
        payload_pattern = pierce_plan.payload_pattern == true,
        payload_pattern_kind = pierce_plan.payload_pattern_kind,
        payload_chain_runtime = pierce_plan.has_chain_payload == true,
        has_chain_payload = pierce_plan.has_chain_payload == true,
        chain_id = chain_id,
        chain_shape = pierce_plan.chain_shape,
        chain_requested_hops = pierce_plan.chain_requested_hops,
        chain_max_hops = pierce_plan.chain_max_hops,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        projectile_id_source = summary.projectile_id_source,
        projectile_registered = summary.projectile_registered == true,
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = 1,
        payload_fanout_count = pierce_plan.payload_count,
        all_launch_jobs_complete = type(tick_result) == "table" and tick_result.all_complete == true,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        effect_id = pierce_plan.source.slot.effects and pierce_plan.source.slot.effects[1] and pierce_plan.source.slot.effects[1].id or nil,
        simple_note = "pierce_v0",
        live_mode = "pierce",
    }
end

local function tryTriggerDispatch(compiled, launch_payload, options)
    runtime_stats.inc("live_trigger_attempts")
    if options.force_trigger_disabled == true then
        return triggerRejected("live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_trigger_disabled_rejections")
    end
    if options.force_trigger_enabled ~= true and not dev.liveTriggerEnabled() then
        return triggerRejected("live_trigger_disabled", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_trigger_disabled_rejections")
    end

    local attached = nil
    if compiled.plan then
        local prepared, prepare_reason, prepare_details = launch_modifier_policy.prepareCachedPlanPayloadModifiers(compiled.recipe_id, {
            source_opcode = "Trigger",
            apply_size_to_specs = true,
            allow_payload_launch_modifiers = true,
            allow_payload_detonate = true,
            allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
            allow_nested_payload_modifiers = true,
            force_speed_plus_enabled = options.force_speed_plus_enabled,
            force_speed_plus_disabled = options.force_speed_plus_disabled,
            speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
            force_size_plus_enabled = options.force_size_plus_enabled,
            force_size_plus_disabled = options.force_size_plus_disabled,
            size_plus_enabled = dev.liveSizePlusEnabled() == true,
            max_fanout = options.max_payload_fanout,
            max_projectiles = options.max_projectiles,
        })
        if not prepared then
            if prepare_reason == "helper_specs_failed" then
                return triggerRejected("helper_specs_failed", {
                    plan_recipe_id = compiled.recipe_id,
                    error = firstErrorMessage(prepare_details),
                    errors = prepare_details and prepare_details.errors,
                })
            end
            return triggerRejected(prepare_reason or "payload_modifier_combo_deferred", {
                plan_recipe_id = compiled.recipe_id,
            })
        end
    end

    attached = nil
    local attach_reason = nil
    local attach_details = nil
    attached, attach_reason, attach_details = attachHelperRecordsWithSourcePolicy(
        compiled,
        sourceContinuationOptions(options),
        nil
    )
    if not attached then
        attach_details = attach_details or {}
        attach_details.plan_recipe_id = attach_details.plan_recipe_id or compiled.recipe_id
        return triggerRejected(attach_reason or "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attach_details),
            errors = attach_details.errors,
        })
    end

    local trigger_plan, trigger_reason = live_trigger.selectV0Plan(attached.plan, {
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        allow_payload_launch_modifiers = true,
        allow_payload_detonate = true,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
        allow_source_launch_modifiers = true,
        allow_source_homing = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        allow_payload_homing = options.allow_payload_homing == true or options.force_homing_enabled == true,
        allow_homing = options.allow_homing == true or options.force_homing_enabled == true,
        force_homing_enabled = options.force_homing_enabled,
        force_homing_disabled = options.force_homing_disabled,
        homing_enabled = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        max_homing_fanout_per_cast = options.max_homing_fanout_per_cast,
        max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast,
        max_soft_homing_registrations_per_cast = options.max_soft_homing_registrations_per_cast,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs,
    })
    if not trigger_plan then
        return triggerRejected(trigger_reason or "trigger_v0_rejected", {
            plan_recipe_id = compiled.recipe_id,
        })
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    runtime_stats.inc("live_trigger_qualified")

    local selected_helpers = { trigger_plan.source }
    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, nil)
    local source_job = job_inputs[1]
    local source_prefix_opcode = hasSourceHoming(trigger_plan.source and trigger_plan.source.slot) and "Homing" or nil
    local binding = {
        recipe_id = compiled.recipe_id,
        plan = attached.plan,
        cast_id = cast_id,
        source_slot_id = trigger_plan.source_slot_id,
        source_helper_engine_id = trigger_plan.source_helper_engine_id,
        payload_slot_id = trigger_plan.payload_slot_id,
        payload_helper_engine_id = trigger_plan.payload_helper_engine_id,
        payloads = trigger_plan.payloads,
        payload_slot_ids = trigger_plan.payload_slot_ids,
        payload_helper_engine_ids = trigger_plan.payload_helper_engine_ids,
        payload_count = trigger_plan.payload_count,
        payload_group_key = trigger_plan.payload_group_key,
        payload_multicast = trigger_plan.payload_multicast == true,
        payload_pattern = trigger_plan.payload_pattern == true,
        payload_pattern_kind = trigger_plan.payload_pattern_kind,
        payload_pattern_op = trigger_plan.payload_pattern_op,
        has_payload_homing = trigger_plan.has_payload_homing == true,
        has_payload_modifier = trigger_plan.has_payload_modifier == true,
        payload_modifier_kinds = trigger_plan.payload_modifier_kinds,
        max_payload_fanout = trigger_plan.max_payload_fanout,
        max_projectiles = trigger_plan.max_projectiles,
        max_jobs_per_tick = trigger_plan.max_jobs_per_tick,
        max_live_launches_per_tick = trigger_plan.max_live_launches_per_tick,
        allow_pending_launch_jobs = trigger_plan.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        source_prefix_opcode = source_prefix_opcode,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
    }
    live_trigger.decorateSourceJob(source_job, binding)
    if attached.source_policy ~= nil then
        local applied = applySourcePolicyToJob(attached, source_job, "trigger")
        if not applied or applied.ok ~= true then
            return triggerRejected(applied and applied.rejection_reason or "source_modifier_unsupported_prefix", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = trigger_plan.source_slot_id,
            })
        end
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_CONTINUATION_OK kind=Trigger recipe_id=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s modifier_kinds=%s payload_fanout_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(trigger_plan.source_slot_id),
            tostring(trigger_plan.payload_slot_id),
            tostring(source_job.source_modifier_kind),
            tostring(trigger_plan.payload_count)
        ))
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_TRIGGER_OK recipe_id=%s plan_recipe_id=%s source_slot_id=%s payload_slot_id=%s modifier_kinds=%s speed_plus=%s size_plus=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(trigger_plan.source_slot_id),
            tostring(trigger_plan.payload_slot_id),
            tostring(source_job.source_modifier_kind),
            tostring(source_job.speed_plus == true),
            tostring(source_job.size_plus == true)
        ))
        log.info(string.format(
            "SPELLFORGE_SUPPORT_TRUTH_SOURCE_MODIFIER_OK kind=Trigger recipe_id=%s plan_recipe_id=%s source_slot_id=%s reason=supported",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(trigger_plan.source_slot_id)
        ))
    end
    if source_prefix_opcode == "Homing" then
        local inspection = homing_launch_policy.inspectSourceEntry(
            attached.plan,
            attached.plan and attached.plan.runtime_ir or nil,
            trigger_plan.source.slot,
            homingPolicyOptions(options, "source", 1)
        )
        if inspection.ok ~= true then
            return triggerRejected(inspection.rejection_reason or "homing_nested_runtime_deferred", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = trigger_plan.source_slot_id,
            })
        end
        local applied = applyHomingPolicyToJob({
            plan = attached.plan,
            source_slot = trigger_plan.source.slot,
            homing_policy = inspection,
            fanout_count = 1,
            apply_homing_direction = options.force_homing_launch_direction == true,
        }, source_job, "source", launch_payload, options)
        if applied == nil or applied.ok ~= true then
            return triggerRejected(applied and applied.rejection_reason or "homing_target_missing", {
                plan_recipe_id = compiled.recipe_id,
                slot_id = trigger_plan.source_slot_id,
            })
        end
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = trigger_plan.source_slot_id,
            helper_engine_id = trigger_plan.source_helper_engine_id,
            slot_ids = { trigger_plan.source_slot_id },
            helper_engine_ids = { trigger_plan.source_helper_engine_id },
            emission_indexes = {
                trigger_plan.source.slot.emission_index or trigger_plan.source.helper.emission_index or 1,
            },
            trigger_payload_slot_id = trigger_plan.payload_slot_id,
            trigger_payload_helper_engine_id = trigger_plan.payload_helper_engine_id,
            trigger_payload_slot_ids = trigger_plan.payload_slot_ids,
            trigger_payload_helper_engine_ids = trigger_plan.payload_helper_engine_ids,
            trigger_payload_count = trigger_plan.payload_count,
            payload_multicast = trigger_plan.payload_multicast == true,
            payload_pattern = trigger_plan.payload_pattern == true,
            payload_pattern_kind = trigger_plan.payload_pattern_kind,
            source_prefix_opcode = source_prefix_opcode,
            jobs = { source_job },
            homing = source_job.homing == true,
            homing_mode = source_job.homing_mode,
            homing_field = source_job.homing_field,
            homing_target_provider = source_job.homing_target_provider,
            trigger_payload_effect_id = trigger_plan.payload_effect_id,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = trigger_plan.payload_count,
            simple_note = "trigger_v0",
            live_mode = "trigger",
            cast_id = cast_id,
        }
    end

    local enqueue = orchestrator.enqueue(source_job)
    if not enqueue.ok then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return triggerRejected("enqueue_failed", {
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = trigger_plan.source_slot_id,
            helper_engine_id = trigger_plan.source_helper_engine_id,
            error = enqueue.error or "enqueue failed",
            cast_id = cast_id,
        })
    end

    binding.source_job_id = enqueue.job_id
    live_trigger.registerBinding(binding)
    runtime_stats.inc("live_trigger_source_jobs_enqueued")

    local tick_result = tickUntilJobsSettled({ enqueue.job_id }, options)
    local summary = jobSummary(enqueue.job_id)
    local pending_source_launch = summary.job_status == "queued" or summary.job_status == "running"
    if pending_source_launch and options.allow_pending_launch_jobs == true then
        log.info(string.format(
            "SPELLFORGE_LIVE_TRIGGER_SOURCE_PENDING recipe_id=%s plan_recipe_id=%s cast_id=%s source_slot_id=%s payload_slot_id=%s job_id=%s job_status=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(trigger_plan.source_slot_id),
            tostring(trigger_plan.payload_slot_id),
            tostring(enqueue.job_id),
            tostring(summary.job_status)
        ))
        return {
            ok = true,
            used_live_2_2c = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = trigger_plan.source_slot_id,
            helper_engine_id = trigger_plan.source_helper_engine_id,
            slot_ids = { trigger_plan.source_slot_id },
            helper_engine_ids = { trigger_plan.source_helper_engine_id },
            emission_indexes = {
                trigger_plan.source.slot.emission_index or trigger_plan.source.helper.emission_index or 1,
            },
            trigger_payload_slot_id = trigger_plan.payload_slot_id,
            trigger_payload_helper_engine_id = trigger_plan.payload_helper_engine_id,
            trigger_payload_slot_ids = trigger_plan.payload_slot_ids,
            trigger_payload_helper_engine_ids = trigger_plan.payload_helper_engine_ids,
            trigger_payload_count = trigger_plan.payload_count,
            payload_multicast = trigger_plan.payload_multicast == true,
            payload_pattern = trigger_plan.payload_pattern == true,
            payload_pattern_kind = trigger_plan.payload_pattern_kind,
            trigger_payload_effect_id = trigger_plan.payload_effect_id,
            projectile_id = summary.projectile_id,
            projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
            projectile_id_source = summary.projectile_id_source,
            projectile_registered = summary.projectile_registered == true,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            jobs = { summary },
            source_jobs = { summary },
            job_status = summary.job_status,
            cast_id = cast_id,
            runtime = "2.2c_live_helper",
            fallback = false,
            dispatch_count = 1,
            source_dispatch_count = 1,
            fanout_count = 1,
            payload_fanout_count = trigger_plan.payload_count,
            slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
            helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
            effect_id = trigger_plan.source.slot.effects and trigger_plan.source.slot.effects[1] and trigger_plan.source.slot.effects[1].id or nil,
            simple_note = "trigger_v0",
            live_mode = "trigger",
            pending_source_launch_job = true,
            pending_launch_jobs = true,
            pending_job_count = 1,
            all_launch_jobs_complete = false,
            tick_result = tick_result,
        }
    end
    if summary.job_status == "queued" then
        orchestrator.cancel(enqueue.job_id)
    end
    if summary.job_status ~= "complete" or summary.launch_accepted ~= true then
        runtime_stats.inc("live_2_2c_dispatch_failed")
        return bridgeError(summary.error or "trigger source launch job did not complete", {
            stage = "trigger_source_launch_job",
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = trigger_plan.source_slot_id,
            helper_engine_id = trigger_plan.source_helper_engine_id,
            job_id = enqueue.job_id,
            job_ids = { enqueue.job_id },
            job_status = summary.job_status,
            tick_result = tick_result,
            cast_id = cast_id,
            fallback_allowed = false,
        })
    end

    log.info(string.format(
        "SPELLFORGE_LIVE_TRIGGER_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_slot_id=%s payload_slot_id=%s helper_engine_id=%s projectile_id=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(cast_id),
        tostring(trigger_plan.source_slot_id),
        tostring(trigger_plan.payload_slot_id),
        tostring(trigger_plan.source_helper_engine_id),
        tostring(summary.projectile_id)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = trigger_plan.source_slot_id,
        helper_engine_id = trigger_plan.source_helper_engine_id,
        slot_ids = { trigger_plan.source_slot_id },
        helper_engine_ids = { trigger_plan.source_helper_engine_id },
        emission_indexes = {
            trigger_plan.source.slot.emission_index or trigger_plan.source.helper.emission_index or 1,
        },
        trigger_payload_slot_id = trigger_plan.payload_slot_id,
        trigger_payload_helper_engine_id = trigger_plan.payload_helper_engine_id,
        trigger_payload_slot_ids = trigger_plan.payload_slot_ids,
        trigger_payload_helper_engine_ids = trigger_plan.payload_helper_engine_ids,
        trigger_payload_count = trigger_plan.payload_count,
        payload_multicast = trigger_plan.payload_multicast == true,
        payload_pattern = trigger_plan.payload_pattern == true,
        payload_pattern_kind = trigger_plan.payload_pattern_kind,
        trigger_payload_effect_id = trigger_plan.payload_effect_id,
        projectile_id = summary.projectile_id,
        projectile_ids = summary.projectile_id and { summary.projectile_id } or {},
        projectile_id_source = summary.projectile_id_source,
        projectile_registered = summary.projectile_registered == true,
        job_id = enqueue.job_id,
        job_ids = { enqueue.job_id },
        jobs = { summary },
        job_status = summary.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = 1,
        source_dispatch_count = 1,
        fanout_count = 1,
        payload_fanout_count = trigger_plan.payload_count,
        slot_count = attached.plan.slot_count or #attached.plan.emission_slots,
        helper_record_count = attached.plan.helper_record_count or #attached.plan.helper_records,
        effect_id = trigger_plan.source.slot.effects and trigger_plan.source.slot.effects[1] and trigger_plan.source.slot.effects[1].id or nil,
        simple_note = "trigger_v0",
        live_mode = "trigger",
    }
end

local function multiRootDispatchCandidate(plan)
    local bounds = plan and plan.bounds or nil
    if type(bounds) ~= "table" then
        return false
    end
    local group_count = tonumber(bounds.group_count) or 0
    local has_source_fanout_continuation = false
    if group_count == 1 then
        local group = plan.groups and plan.groups[1] or nil
        has_source_fanout_continuation = type(group) == "table"
            and (hasTriggerPostfix(group) or hasTimerPostfix(group))
            and (tonumber(group.emission_count_static) or 1) > 1
    end
    if group_count <= 1 and not has_source_fanout_continuation then
        return false
    end
    for _, group in ipairs(plan.groups or {}) do
        for _, op in ipairs(group and group.prefix_ops or {}) do
            local opcode = op and op.opcode
            if opcode == "Chain"
                or opcode == "Bounce"
                or opcode == "Pierce"
                or opcode == "Homing"
                or opcode == "Speed+"
                or opcode == "Size+" then
                return false
            end
        end
    end
    return true
end

local function sourceLaunchPayloadForJob(launch_payload, source_job)
    local out = {}
    for key, value in pairs(launch_payload or {}) do
        out[key] = value
    end
    local source_payload = source_job and source_job.payload or nil
    if source_payload and source_payload.direction ~= nil then
        out.direction = source_payload.direction
    end
    if source_payload and source_payload.start_pos ~= nil then
        out.start_pos = source_payload.start_pos
    end
    return out
end

local function groupHasPrefixOpcode(group, opcode)
    for _, op in ipairs(group and group.prefix_ops or {}) do
        if op and op.opcode == opcode then
            return true
        end
    end
    return false
end

local function groupPostfixKind(group)
    local trigger = hasTriggerPostfix(group)
    local timer = hasTimerPostfix(group)
    if trigger and timer then
        return nil, "multiple_postfix_ops"
    end
    if trigger then
        return "Trigger"
    end
    if timer then
        return "Timer"
    end
    if type(group and group.postfix_ops) == "table" and #group.postfix_ops > 0 then
        return nil, "unsupported_postfix_ops"
    end
    return nil, nil
end

local function collectPrimaryHelpersForGroup(plan, group_index)
    if type(plan) ~= "table" then
        return nil, "missing_plan"
    end
    if type(plan.emission_slots) ~= "table" or #plan.emission_slots == 0 then
        return nil, "slot_count_zero"
    end
    if type(plan.helper_records) ~= "table" or #plan.helper_records == 0 then
        return nil, "helper_record_count_zero"
    end

    local helpers_by_slot = helperBySlotId(plan.helper_records)
    local selected = {}
    for _, slot in ipairs(plan.emission_slots) do
        if slot.kind == "primary_emission" and tonumber(slot.group_index) == tonumber(group_index) then
            if slot.parent_slot_id ~= nil then
                return nil, "slot_has_parent"
            end
            if slot.source_postfix_opcode ~= nil
                or slot.trigger_source_slot_id ~= nil
                or slot.timer_source_slot_id ~= nil then
                return nil, "slot_has_source_postfix"
            end
            local helper = helpers_by_slot[slot.slot_id]
            if not helper then
                return nil, "helper_missing_for_slot"
            end
            if type(helper.engine_id) ~= "string" or helper.engine_id == "" then
                return nil, "helper_engine_id_missing"
            end
            selected[#selected + 1] = {
                slot = slot,
                helper = helper,
            }
        end
    end
    if #selected == 0 then
        return nil, "missing_group_primary_helpers"
    end
    return selected, nil
end

local function simpleRootGroupShape(group, selected_helpers, options)
    local prefix_ok, prefix_note, pattern_kind, pattern_op = prefixLiveShape(group.prefix_ops)
    if not prefix_ok then
        if pattern_kind ~= nil or groupHasPrefixOpcode(group, "Spread") or groupHasPrefixOpcode(group, "Burst") then
            return nil, prefix_note, patternModeForKind(pattern_kind) or "pattern", pattern_kind, pattern_op
        elseif groupHasPrefixOpcode(group, "Multicast") then
            return nil, prefix_note, "multicast", pattern_kind, pattern_op
        end
        return nil, prefix_note
    end

    local has_multicast = groupHasPrefixOpcode(group, "Multicast")
    local has_pattern = pattern_kind ~= nil
    local allows_self_summon_multicast = has_multicast
        and not has_pattern
        and isSelfRange(group.range)
        and countSummonEffects(group.effects) > 0
    local allows_self_summon_source_fanout = not has_multicast
        and not has_pattern
        and isSelfRange(group.range)
        and countSummonEffects(group.effects) > 1

    if (has_multicast or has_pattern)
        and not isTargetRange(group.range)
        and not allows_self_summon_multicast then
        if has_pattern then
            return nil, "fanout_requires_target_range", patternModeForKind(pattern_kind) or "pattern", pattern_kind, pattern_op
        end
        return nil, "fanout_requires_target_range", "multicast", pattern_kind, pattern_op
    end

    local selected_count = #(selected_helpers or {})
    if has_pattern then
        if selected_count <= 1 then
            return nil, "pattern_fanout_missing", patternModeForKind(pattern_kind), pattern_kind, pattern_op
        end
        if options.force_multicast_disabled == true then
            return nil, "live_multicast_disabled", patternModeForKind(pattern_kind), pattern_kind, pattern_op
        end
        if options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled() then
            return nil, "live_multicast_disabled", patternModeForKind(pattern_kind), pattern_kind, pattern_op
        end
        if options.force_pattern_disabled == true then
            return nil, "live_spread_burst_disabled", patternModeForKind(pattern_kind), pattern_kind, pattern_op
        end
        if options.force_pattern_enabled ~= true and not dev.liveSpreadBurstEnabled() then
            return nil, "live_spread_burst_disabled", patternModeForKind(pattern_kind), pattern_kind, pattern_op
        end
        return patternModeForKind(pattern_kind), prefix_note, patternModeForKind(pattern_kind), pattern_kind, pattern_op
    end

    local is_multicast = (has_multicast and selected_count > 1)
        or (allows_self_summon_source_fanout and selected_count > 1)
    if is_multicast then
        if options.force_multicast_disabled == true then
            return nil, "live_multicast_disabled", "multicast", pattern_kind, pattern_op
        end
        if options.force_multicast_enabled ~= true and not dev.liveMulticastEnabled() then
            return nil, "live_multicast_disabled", "multicast", pattern_kind, pattern_op
        end
        return "multicast", "multicast_primary", "multicast", pattern_kind, pattern_op
    end

    return "single", prefix_note, "single", pattern_kind, pattern_op
end

local function appendSelectedHelperMetadata(selected_helpers, slot_ids, helper_engine_ids, emission_indexes)
    for _, pair in ipairs(selected_helpers or {}) do
        local index = #slot_ids + 1
        slot_ids[index] = pair.helper and pair.helper.slot_id or nil
        helper_engine_ids[index] = pair.helper and pair.helper.engine_id or nil
        emission_indexes[index] = pair.slot and (pair.slot.emission_index or (pair.helper and pair.helper.emission_index)) or index
    end
end

local function triggerPlanOptions(options, group_index)
    return {
        allow_multi_root = true,
        source_group_index = group_index,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_payload_pattern = payloadPatternRuntimeEnabled(options),
        allow_payload_launch_modifiers = true,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
        allow_source_launch_modifiers = true,
        allow_source_homing = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        allow_payload_homing = options.allow_payload_homing == true or options.force_homing_enabled == true,
        allow_homing = options.allow_homing == true or options.force_homing_enabled == true,
        force_homing_enabled = options.force_homing_enabled,
        force_homing_disabled = options.force_homing_disabled,
        homing_enabled = options.force_homing_enabled == true or dev.liveHomingEnabled() == true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_depth = options.max_nested_payload_depth,
        max_jobs = options.max_nested_payload_jobs,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
        max_jobs_per_tick = options.max_jobs_per_tick,
        max_live_launches_per_tick = options.max_live_launches_per_tick,
        max_homing_fanout_per_cast = options.max_homing_fanout_per_cast,
        max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast,
        max_soft_homing_registrations_per_cast = options.max_soft_homing_registrations_per_cast,
        allow_pending_launch_jobs = options.allow_pending_launch_jobs,
    }
end

local function timerPlanOptions(options, group_index)
    local out = triggerPlanOptions(options, group_index)
    out.allow_source_homing = options.force_homing_enabled == true or dev.liveHomingEnabled() == true
    return out
end

local function makeTriggerBinding(compiled, attached_plan, trigger_plan, launch_payload, cast_id, options)
    return {
        recipe_id = compiled.recipe_id,
        plan = attached_plan,
        cast_id = cast_id,
        source_slot_id = trigger_plan.source_slot_id,
        source_helper_engine_id = trigger_plan.source_helper_engine_id,
        payload_slot_id = trigger_plan.payload_slot_id,
        payload_helper_engine_id = trigger_plan.payload_helper_engine_id,
        payloads = trigger_plan.payloads,
        payload_slot_ids = trigger_plan.payload_slot_ids,
        payload_helper_engine_ids = trigger_plan.payload_helper_engine_ids,
        payload_count = trigger_plan.payload_count,
        payload_group_key = trigger_plan.payload_group_key,
        payload_multicast = trigger_plan.payload_multicast == true,
        payload_pattern = trigger_plan.payload_pattern == true,
        payload_pattern_kind = trigger_plan.payload_pattern_kind,
        payload_pattern_op = trigger_plan.payload_pattern_op,
        has_payload_homing = trigger_plan.has_payload_homing == true,
        has_payload_modifier = trigger_plan.has_payload_modifier == true,
        payload_modifier_kinds = trigger_plan.payload_modifier_kinds,
        max_payload_fanout = trigger_plan.max_payload_fanout,
        max_projectiles = trigger_plan.max_projectiles,
        max_jobs_per_tick = trigger_plan.max_jobs_per_tick,
        max_live_launches_per_tick = trigger_plan.max_live_launches_per_tick,
        allow_pending_launch_jobs = trigger_plan.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
    }
end

local function makeTimerBinding(compiled, attached_plan, timer_plan, launch_payload, cast_id, options)
    return {
        recipe_id = compiled.recipe_id,
        cast_id = cast_id,
        source_slot_id = timer_plan.source_slot_id,
        source_helper_engine_id = timer_plan.source_helper_engine_id,
        payload_slot_id = timer_plan.payload_slot_id,
        payload_helper_engine_id = timer_plan.payload_helper_engine_id,
        payloads = timer_plan.payloads,
        payload_slot_ids = timer_plan.payload_slot_ids,
        payload_helper_engine_ids = timer_plan.payload_helper_engine_ids,
        payload_count = timer_plan.payload_count,
        payload_group_key = timer_plan.payload_group_key,
        payload_multicast = timer_plan.payload_multicast == true,
        payload_pattern = timer_plan.payload_pattern == true,
        payload_pattern_kind = timer_plan.payload_pattern_kind,
        payload_pattern_op = timer_plan.payload_pattern_op,
        has_payload_homing = timer_plan.has_payload_homing == true,
        has_payload_modifier = timer_plan.has_payload_modifier == true,
        payload_modifier_kinds = timer_plan.payload_modifier_kinds,
        plan = attached_plan,
        max_payload_fanout = timer_plan.max_payload_fanout,
        max_projectiles = timer_plan.max_projectiles,
        max_jobs_per_tick = timer_plan.max_jobs_per_tick,
        max_live_launches_per_tick = timer_plan.max_live_launches_per_tick,
        allow_pending_launch_jobs = timer_plan.allow_pending_launch_jobs == true,
        actor = launch_payload.actor or launch_payload.sender,
        hit_object = launch_payload.hit_object,
        start_pos = launch_payload.start_pos,
        direction = launch_payload.direction,
        timer_seconds = timer_plan.timer_seconds,
        timer_delay_ticks = timer_plan.timer_delay_ticks,
        allow_nested_trigger_timer = nestedTriggerTimerRuntimeEnabled(options),
        allow_nested_final_fanout = nestedFinalFanoutRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        allow_nested_payload_homing = true,
    }
end

local function prepareMultiRootPayloadModifiers(compiled, options, source_opcode)
    local prepared, prepare_reason, prepare_details = launch_modifier_policy.prepareCachedPlanPayloadModifiers(compiled.recipe_id, {
        source_opcode = source_opcode,
        apply_size_to_specs = true,
        allow_payload_launch_modifiers = true,
        allow_payload_detonate = true,
        allow_payload_multicast = payloadMulticastRuntimeEnabled(options),
        allow_nested_payload_modifiers = true,
        force_speed_plus_enabled = options.force_speed_plus_enabled,
        force_speed_plus_disabled = options.force_speed_plus_disabled,
        speed_plus_enabled = dev.liveSpeedPlusEnabled() == true,
        force_size_plus_enabled = options.force_size_plus_enabled,
        force_size_plus_disabled = options.force_size_plus_disabled,
        size_plus_enabled = dev.liveSizePlusEnabled() == true,
        max_fanout = options.max_payload_fanout,
        max_projectiles = options.max_projectiles,
    })
    if prepared then
        return true, nil, nil
    end
    if prepare_reason == "helper_specs_failed" then
        return nil, "helper_specs_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(prepare_details),
            errors = prepare_details and prepare_details.errors,
        }
    end
    return nil, prepare_reason or "payload_modifier_combo_deferred", {
        plan_recipe_id = compiled.recipe_id,
    }
end

local function tryMultiRootDispatch(compiled, launch_payload, options)
    if not multiRootDispatchCandidate(compiled.plan) then
        return nil
    end

    local bounds = compiled.plan and compiled.plan.bounds or {}
    if bounds.has_trigger == true then
        local prepared, prepare_reason, prepare_details = prepareMultiRootPayloadModifiers(compiled, options, "Trigger")
        if not prepared then
            return triggerRejected(prepare_reason or "payload_modifier_combo_deferred", prepare_details or {
                plan_recipe_id = compiled.recipe_id,
            })
        end
    end
    if bounds.has_timer == true then
        local prepared, prepare_reason, prepare_details = prepareMultiRootPayloadModifiers(compiled, options, "Timer")
        if not prepared then
            return timerRejected(prepare_reason or "payload_modifier_combo_deferred", prepare_details or {
                plan_recipe_id = compiled.recipe_id,
            })
        end
    end

    local attached, attach_reason, attach_details = attachHelperRecordsWithSourcePolicy(
        compiled,
        sourceContinuationOptions(options),
        nil
    )
    if not attached then
        attach_details = attach_details or {}
        attach_details.plan_recipe_id = attach_details.plan_recipe_id or compiled.recipe_id
        return rejected(attach_reason or "helper_records_failed", {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attach_details),
            errors = attach_details.errors,
        })
    end

    local plan = attached.plan
    local projectile_cap = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    local fanout_cap = tonumber(options.max_payload_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    local job_inputs = {}
    local selected_helpers = {}
    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local trigger_bindings_by_job_index = {}
    local timer_bindings_by_job_index = {}
    local timer_plans_by_job_index = {}
    local has_multicast = false
    local has_pattern = false
    local has_trigger = false
    local has_timer = false
    local source_fanout_trigger_count = 0
    local source_fanout_timer_count = 0

    local function appendJobs(group_helpers, group_jobs)
        appendSelectedHelperMetadata(group_helpers, slot_ids, helper_engine_ids, emission_indexes)
        for _, pair in ipairs(group_helpers or {}) do
            selected_helpers[#selected_helpers + 1] = pair
        end
        for _, job in ipairs(group_jobs or {}) do
            job_inputs[#job_inputs + 1] = job
        end
    end

    for group_index, group in ipairs(plan.groups or {}) do
        local postfix_kind, postfix_reason = groupPostfixKind(group)
        if postfix_reason then
            return rejected(postfix_reason, {
                plan_recipe_id = compiled.recipe_id,
                group_index = group_index,
            })
        end

        if postfix_kind == "Trigger" then
            local trigger_plans, trigger_reason = live_trigger.selectV0PlansForGroup(plan, triggerPlanOptions(options, group_index))
            if not trigger_plans then
                return triggerRejected(trigger_reason or "trigger_v0_rejected", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local next_index = #job_inputs + 1
            local group_helpers = {}
            for _, trigger_plan in ipairs(trigger_plans) do
                group_helpers[#group_helpers + 1] = trigger_plan.source
            end
            local live_mode, live_reason, reject_mode, pattern_kind, pattern_op = simpleRootGroupShape(group, group_helpers, options)
            if not live_mode then
                local details = {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }
                if isPatternMode(reject_mode) or reject_mode == "pattern" then
                    return patternRejected(pattern_kind, live_reason, details)
                elseif reject_mode == "multicast" then
                    return multicastRejected(live_reason, details)
                end
                return triggerRejected(live_reason, details)
            end
            if #group_helpers > fanout_cap and live_mode == "multicast" then
                return multicastRejected("multicast_cap_exceeded", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }, "live_multicast_cap_rejections")
            end
            local pattern_info, pattern_err = computePatternInfo(live_mode, pattern_kind, pattern_op, group_helpers, launch_payload)
            if pattern_err then
                return patternRejected(pattern_kind, pattern_err, {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local group_jobs = buildJobInputs(group_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
            for offset, trigger_plan in ipairs(trigger_plans) do
                local source_job = group_jobs[offset]
                local binding_launch_payload = sourceLaunchPayloadForJob(launch_payload, source_job)
                local binding = makeTriggerBinding(compiled, plan, trigger_plan, binding_launch_payload, cast_id, options)
                live_trigger.decorateSourceJob(source_job, binding)
                trigger_bindings_by_job_index[next_index + offset - 1] = binding
            end
            appendJobs(group_helpers, group_jobs)
            has_trigger = true
            has_multicast = has_multicast or live_mode == "multicast"
            has_pattern = has_pattern or isPatternMode(live_mode)
            if #trigger_plans > 1 then
                source_fanout_trigger_count = source_fanout_trigger_count + #trigger_plans
            end
        elseif postfix_kind == "Timer" then
            local timer_plans, timer_reason = live_timer.selectV0PlansForGroup(plan, timerPlanOptions(options, group_index))
            if not timer_plans then
                return timerRejected(timer_reason or "timer_v0_rejected", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local next_index = #job_inputs + 1
            local group_helpers = {}
            for _, timer_plan in ipairs(timer_plans) do
                group_helpers[#group_helpers + 1] = timer_plan.source
            end
            local live_mode, live_reason, reject_mode, pattern_kind, pattern_op = simpleRootGroupShape(group, group_helpers, options)
            if not live_mode then
                local details = {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }
                if isPatternMode(reject_mode) or reject_mode == "pattern" then
                    return patternRejected(pattern_kind, live_reason, details)
                elseif reject_mode == "multicast" then
                    return multicastRejected(live_reason, details)
                end
                return timerRejected(live_reason, details)
            end
            if #group_helpers > fanout_cap and live_mode == "multicast" then
                return multicastRejected("multicast_cap_exceeded", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }, "live_multicast_cap_rejections")
            end
            local pattern_info, pattern_err = computePatternInfo(live_mode, pattern_kind, pattern_op, group_helpers, launch_payload)
            if pattern_err then
                return patternRejected(pattern_kind, pattern_err, {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local group_jobs = buildJobInputs(group_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
            for offset, timer_plan in ipairs(timer_plans) do
                local source_job = group_jobs[offset]
                local binding_launch_payload = sourceLaunchPayloadForJob(launch_payload, source_job)
                local resolution, resolution_err = live_timer.computeResolution(binding_launch_payload, timer_plan)
                if not resolution then
                    return timerRejected("timer_resolution_failed", {
                        plan_recipe_id = compiled.recipe_id,
                        group_index = group_index,
                        slot_id = timer_plan.source_slot_id,
                        error = resolution_err,
                    }, "live_timer_payload_route_failed")
                end
                local binding = makeTimerBinding(compiled, plan, timer_plan, binding_launch_payload, cast_id, options)
                binding.resolution = resolution
                live_timer.decorateSourceJob(source_job, binding)
                timer_bindings_by_job_index[next_index + offset - 1] = binding
                timer_plans_by_job_index[next_index + offset - 1] = timer_plan
            end
            appendJobs(group_helpers, group_jobs)
            has_timer = true
            has_multicast = has_multicast or live_mode == "multicast"
            has_pattern = has_pattern or isPatternMode(live_mode)
            if #timer_plans > 1 then
                source_fanout_timer_count = source_fanout_timer_count + #timer_plans
            end
        else
            if group.payload ~= nil then
                return rejected("has_payload", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local group_helpers, group_reason = collectPrimaryHelpersForGroup(plan, group_index)
            if not group_helpers then
                return rejected(group_reason, {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            for _, pair in ipairs(group_helpers) do
                if hasPayloadBindings(pair.slot and pair.slot.payload_bindings) then
                    return rejected("slot_has_payload_bindings", {
                        plan_recipe_id = compiled.recipe_id,
                        group_index = group_index,
                    })
                end
                if type(pair.slot and pair.slot.postfix_ops) == "table" and #pair.slot.postfix_ops > 0 then
                    return rejected("slot_has_postfix_ops", {
                        plan_recipe_id = compiled.recipe_id,
                        group_index = group_index,
                    })
                end
            end
            local live_mode, live_reason, reject_mode, pattern_kind, pattern_op = simpleRootGroupShape(group, group_helpers, options)
            if not live_mode then
                local details = {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }
                if isPatternMode(reject_mode) or reject_mode == "pattern" then
                    return patternRejected(pattern_kind, live_reason, details)
                elseif reject_mode == "multicast" then
                    return multicastRejected(live_reason, details)
                end
                return rejected(live_reason, details)
            end
            if #group_helpers > fanout_cap and live_mode == "multicast" then
                return multicastRejected("multicast_cap_exceeded", {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                }, "live_multicast_cap_rejections")
            end
            local pattern_info, pattern_err = computePatternInfo(live_mode, pattern_kind, pattern_op, group_helpers, launch_payload)
            if pattern_err then
                return patternRejected(pattern_kind, pattern_err, {
                    plan_recipe_id = compiled.recipe_id,
                    group_index = group_index,
                })
            end
            local group_jobs = buildJobInputs(group_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
            appendJobs(group_helpers, group_jobs)
            has_multicast = has_multicast or live_mode == "multicast"
            has_pattern = has_pattern or isPatternMode(live_mode)
        end
    end

    if #job_inputs == 0 then
        return rejected("missing_multi_root_jobs", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if #job_inputs > projectile_cap then
        chaos_budget.recordReject("projectile_cap_exceeded", "projectile")
        return rejected("projectile_cap_exceeded", {
            plan_recipe_id = compiled.recipe_id,
            count = #job_inputs,
            limit = projectile_cap,
        })
    end

    runtime_stats.inc("live_2_2c_qualified")
    if has_multicast then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    end
    if has_trigger then
        runtime_stats.inc("live_trigger_qualified")
    end
    if has_timer then
        runtime_stats.inc("live_timer_qualified")
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            dispatch_count = #job_inputs,
            fanout_count = #selected_helpers,
            simple_note = "multi_root",
            live_mode = "multi_root",
            has_trigger = has_trigger,
            has_timer = has_timer,
            has_multicast = has_multicast,
            has_pattern = has_pattern,
            cast_id = cast_id,
            jobs = job_inputs,
        }
    end

    local job_ids = {}
    for index, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(enqueue.error or "enqueue failed", {
                stage = "enqueue",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                cast_id = cast_id,
                job_ids = job_ids,
                fallback_allowed = false,
            })
        end
        job_ids[#job_ids + 1] = enqueue.job_id
        local trigger_binding = trigger_bindings_by_job_index[index]
        if trigger_binding then
            trigger_binding.source_job_id = enqueue.job_id
            live_trigger.registerBinding(trigger_binding)
        end
    end

    chaos_budget.observe({
        jobs = #job_ids,
        queue = orchestrator.queueLength(),
        projectiles = #selected_helpers,
    })

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    local pending_job_count = 0
    local allow_pending_launch_jobs = options.allow_pending_launch_jobs == true
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        local pending = summary.job_status == "queued" or summary.job_status == "running"
        if pending and allow_pending_launch_jobs and timer_bindings_by_job_index[index] == nil then
            pending_job_count = pending_job_count + 1
        elseif summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if not (pending and allow_pending_launch_jobs and timer_bindings_by_job_index[index] == nil)
            and (summary.job_status ~= "complete" or summary.launch_accepted ~= true) then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "helper launch job did not complete", {
                stage = "multi_root_launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end

        local timer_binding = timer_bindings_by_job_index[index]
        if timer_binding then
            timer_binding.source_job_id = job_id
            timer_binding.source_projectile_id = summary.projectile_id
            timer_binding.source_user_data = summary.launch_user_data
            local schedule = live_timer.schedulePayload(timer_binding, {
                delay_ticks_override = options.timer_delay_ticks_override,
                delay_seconds_override = options.timer_delay_seconds_override,
                ttl_ticks_override = options.timer_ttl_ticks_override,
                ttl_seconds_override = options.timer_ttl_seconds_override,
                duplicate_key_suffix = options.timer_duplicate_key_suffix,
            })
            if not schedule.ok then
                runtime_stats.inc("live_2_2c_dispatch_failed")
                return bridgeError(schedule.error or "timer payload schedule failed", {
                    stage = "multi_root_timer_payload_schedule",
                    recipe_id = result_recipe_id,
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = timer_binding.source_slot_id,
                    helper_engine_id = timer_binding.source_helper_engine_id,
                    job_id = job_id,
                    job_ids = job_ids,
                    cast_id = cast_id,
                    fallback_allowed = false,
                })
            end
            local timer_plan = timer_plans_by_job_index[index]
            if timer_plan then
                log.info(string.format(
                    "SPELLFORGE_LIVE_MULTI_ROOT_TIMER_SOURCE_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_slot_id=%s payload_slot_id=%s helper_engine_id=%s timer_id=%s projectile_id=%s",
                    tostring(result_recipe_id),
                    tostring(compiled.recipe_id),
                    tostring(cast_id),
                    tostring(timer_plan.source_slot_id),
                    tostring(timer_plan.payload_slot_id),
                    tostring(timer_plan.source_helper_engine_id),
                    tostring(schedule.timer_id),
                    tostring(summary.projectile_id)
                ))
            end
        end
    end

    local first_job = jobs[1] or {}
    if source_fanout_trigger_count > 0 then
        log.info(string.format(
            "SPELLFORGE_SOURCE_FANOUT_TRIGGER_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_count=%s dispatch_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(source_fanout_trigger_count),
            tostring(#job_ids)
        ))
    end
    if source_fanout_timer_count > 0 then
        log.info(string.format(
            "SPELLFORGE_SOURCE_FANOUT_TIMER_OK recipe_id=%s plan_recipe_id=%s cast_id=%s source_count=%s dispatch_count=%s",
            tostring(result_recipe_id),
            tostring(compiled.recipe_id),
            tostring(cast_id),
            tostring(source_fanout_timer_count),
            tostring(#job_ids)
        ))
    end
    log.info(string.format(
        "SPELLFORGE_LIVE_MULTI_ROOT_DISPATCH_OK recipe_id=%s plan_recipe_id=%s root_group_count=%s dispatch_count=%s fanout_count=%s projectile_count=%s has_trigger=%s has_timer=%s has_multicast=%s has_pattern=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(plan.bounds and plan.bounds.group_count),
        tostring(#job_ids),
        tostring(#selected_helpers),
        tostring(projectile_id_count),
        tostring(has_trigger),
        tostring(has_timer),
        tostring(has_multicast),
        tostring(has_pattern)
    ))
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        projectile_id_source = first_job.projectile_id_source,
        projectile_registered = first_job.projectile_registered == true,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        pending_launch_jobs = pending_job_count > 0,
        pending_job_count = pending_job_count,
        all_launch_jobs_complete = pending_job_count == 0,
        job_status = first_job.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        slot_count = plan.slot_count or #plan.emission_slots,
        helper_record_count = plan.helper_record_count or #plan.helper_records,
        effect_id = selected_helpers[1]
            and selected_helpers[1].slot.effects
            and selected_helpers[1].slot.effects[1]
            and selected_helpers[1].slot.effects[1].id
            or nil,
        simple_note = "multi_root",
        live_mode = "multi_root",
        has_trigger = has_trigger,
        has_timer = has_timer,
        has_multicast = has_multicast,
        has_pattern = has_pattern,
    }
end

local function opsHaveLaunchModifier(ops)
    for _, op in ipairs(ops or {}) do
        if op and (op.opcode == "Speed+" or op.opcode == "Size+") then
            return true
        end
    end
    return false
end

local function planHasTriggerPayloadLaunchModifier(plan)
    for _, group in ipairs(plan and plan.groups or {}) do
        local payload = group and group.payload
        if payload and opsHaveLaunchModifier(payload.prefix_ops) then
            return true
        end
    end
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "payload_emission"
            and slot.source_postfix_opcode == "Trigger"
            and opsHaveLaunchModifier(slot.prefix_ops) then
            return true
        end
    end
    return false
end

local function rootPostfixKind(plan)
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "primary_emission" and slot.parent_slot_id == nil then
            if hasTriggerPostfix(slot) then
                return "Trigger"
            elseif hasTimerPostfix(slot) then
                return "Timer"
            end
        end
    end
    local group = plan and plan.groups and plan.groups[1] or nil
    if hasTriggerPostfix(group) then
        return "Trigger"
    elseif hasTimerPostfix(group) then
        return "Timer"
    end
    return nil
end

function live_simple_dispatch.tryDispatch(payload, entry, root, opts)
    local options = chaos_budget.withBudget(opts or {})
    if options.force_disabled == true then
        return fallback("feature_flag_disabled")
    end
    if options.ignore_flag ~= true and not dev.liveSimpleDispatchEnabled() then
        return fallback("feature_flag_disabled")
    end
    runtime_stats.inc("live_2_2c_attempts")
    if options.dry_run == true then
        runtime_stats.inc("live_2_2c_dry_run_attempts")
    end

    local launch_payload = payload or {}
    launch_payload.max_live_launches_per_tick = options.max_live_launches_per_tick
    launch_payload.chaos_budget_profile = options.chaos_budget_profile
    local actor = launch_payload.actor or launch_payload.sender
    if not actor then
        return rejected("missing_actor")
    end
    if not options.skip_entry_shape_check and not isSingleStoredNode(entry) then
        return rejected("not_single_stored_node")
    end

    local effects = effectListFromRoot(root)
    if not effects then
        return rejected("missing_effect_list")
    end
    local has_timer_effect = effectListHasOperator(effects, "Timer")
    local has_trigger_effect = effectListHasOperator(effects, "Trigger")
    local has_chain_effect = effectListHasOperator(effects, "Chain")
    local has_bounce_effect = effectListHasOperator(effects, "Bounce")
    local has_pierce_effect = effectListHasOperator(effects, "Pierce")
    local has_size_plus_effect = effectListHasOperator(effects, "Size+")
    local has_speed_plus_effect = effectListHasOperator(effects, "Speed+")
    local has_homing_effect = effectListHasOperator(effects, "Homing")
    local estimated_ops = estimateFirstGroupOperators(effects)
    local estimated_multicast_count = estimated_ops.multicast_count or 1
    local estimated_multicast_fanout = estimated_ops.has_multicast and estimated_multicast_count > 1
    local estimated_pattern_kind = estimated_ops.pattern_kind
    if estimated_ops.has_spread then
        patternAttempt("Spread")
    end
    if estimated_ops.has_burst then
        patternAttempt("Burst")
    end
    if estimated_multicast_fanout then
        runtime_stats.inc("live_multicast_attempts")
        if estimated_multicast_count > options.max_projectiles then
            chaos_budget.recordReject("multicast_projectile_cap_exceeded", "projectile")
            if estimated_pattern_kind ~= nil then
                return patternRejected(estimated_pattern_kind, "pattern_cap_exceeded", {
                    estimated_emission_count = estimated_multicast_count,
                }, "live_multicast_cap_rejections")
            end
            return multicastRejected("multicast_cap_exceeded", {
                estimated_emission_count = estimated_multicast_count,
            }, "live_multicast_cap_rejections")
        end
        if estimated_multicast_count > options.max_payload_fanout then
            chaos_budget.recordReject("multicast_fanout_cap_exceeded", "fanout")
            if estimated_pattern_kind ~= nil then
                return patternRejected(estimated_pattern_kind, "pattern_cap_exceeded", {
                    estimated_emission_count = estimated_multicast_count,
                }, "live_multicast_cap_rejections")
            end
            return multicastRejected("multicast_cap_exceeded", {
                estimated_emission_count = estimated_multicast_count,
            }, "live_multicast_cap_rejections")
        end
    end
    if estimated_ops.ambiguous_pattern then
        if estimated_ops.has_burst and estimated_ops.has_spread then
            runtime_stats.inc("live_burst_rejected")
        end
        return patternRejected("Spread", "ambiguous_pattern", nil, "live_pattern_unsupported_opcode_rejections")
    end

    local capabilities = sfp_adapter.capabilities()
    if not capabilities.has_interface then
        if estimated_pattern_kind ~= nil then
            return patternRejected(estimated_pattern_kind, "sfp_missing")
        end
        if estimated_multicast_fanout then
            return multicastRejected("sfp_missing")
        end
        return rejected("sfp_missing")
    end
    if not capabilities.has_launchSpell then
        if estimated_pattern_kind ~= nil then
            return patternRejected(estimated_pattern_kind, "sfp_launch_missing")
        end
        if estimated_multicast_fanout then
            return multicastRejected("sfp_launch_missing")
        end
        return rejected("sfp_launch_missing")
    end

    local compiled = plan_cache.compileOrGet(effects, { limits = options.budget_limits })
    if not compiled.ok then
        local details = {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(compiled),
            errors = compiled.errors,
        }
        if has_size_plus_effect then
            runtime_stats.inc("live_size_plus_attempts")
            if errorsMentionSizePlusValue(compiled.errors) then
                runtime_stats.inc("live_size_plus_value_invalid")
            end
            return sizePlusRejected("compile_failed", details)
        end
        if has_speed_plus_effect then
            runtime_stats.inc("live_speed_plus_attempts")
            if errorsMentionSpeedPlusValue(compiled.errors) then
                runtime_stats.inc("live_speed_plus_value_invalid")
            end
            return speedPlusRejected("compile_failed", details)
        end
        if has_homing_effect then
            runtime_stats.inc("live_homing_attempts")
            return homingRejected("compile_failed", details)
        end
        if has_timer_effect then
            runtime_stats.inc("live_timer_attempts")
            if errorsMentionTimerDelay(compiled.errors) then
                runtime_stats.inc("live_timer_delay_invalid")
            end
            return timerRejected("compile_failed", details)
        end
        if has_chain_effect then
            runtime_stats.inc("chain_runtime_attempts")
            return chainRuntimeRejected("compile_failed", details, "chain_runtime_context_reject")
        end
        if has_bounce_effect then
            runtime_stats.inc("live_bounce_attempts")
            return bounceRejected("compile_failed", details)
        end
        if has_pierce_effect then
            runtime_stats.inc("live_pierce_attempts")
            return pierceRejected("compile_failed", details)
        end
        if estimated_pattern_kind ~= nil then
            return patternRejected(estimated_pattern_kind, "compile_failed", details)
        end
        if estimated_multicast_fanout then
            return multicastRejected("compile_failed", details)
        end
        return rejected("compile_failed", details)
    end

    local max_nested_depth = planNestedDepth(compiled.plan)
    local nested_depth_cap = tonumber(options.max_nested_payload_depth) or limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3
    if max_nested_depth > nested_depth_cap then
        return rejected("nested_depth_exceeded", {
            plan_recipe_id = compiled.recipe_id,
            nested_depth = max_nested_depth,
            nested_depth_cap = nested_depth_cap,
        })
    end

    local compiled_bounds = compiled.plan and compiled.plan.bounds or nil
    if multiRootDispatchCandidate(compiled.plan) then
        return tryMultiRootDispatch(compiled, launch_payload, options)
    end
    if eventSourceTimerCandidate(compiled.plan) then
        return tryEventSourceTimerDispatch(compiled, launch_payload, options)
    end

    if eventSourceFanoutCandidate(compiled.plan) then
        return tryEventSourceFanoutDispatch(compiled, launch_payload, options)
    end

    if compiled_bounds and compiled_bounds.has_pierce then
        return tryPierceDispatch(compiled, launch_payload, options)
    end

    if compiled_bounds and compiled_bounds.has_bounce then
        return tryBounceDispatch(compiled, launch_payload, options)
    end

    if has_chain_effect or (compiled_bounds and compiled_bounds.has_chain) then
        return tryChainDispatch(compiled, launch_payload, options)
    end

    if has_bounce_effect then
        return tryBounceDispatch(compiled, launch_payload, options)
    end

    if has_pierce_effect then
        return tryPierceDispatch(compiled, launch_payload, options)
    end

    if has_timer_effect and has_trigger_effect then
        local root_kind = rootPostfixKind(compiled.plan)
        if root_kind == "Trigger" then
            return tryTriggerDispatch(compiled, launch_payload, options)
        elseif root_kind == "Timer" then
            return tryTimerDispatch(compiled, launch_payload, options)
        end
        return tryNestedTriggerTimerDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_trigger
        and planHasTriggerPayloadLaunchModifier(compiled.plan) then
        return tryTriggerDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_homing then
        if compiled.plan.bounds.has_timer then
            return tryTimerDispatch(compiled, launch_payload, options)
        end
        if compiled.plan.bounds.has_trigger then
            return tryTriggerDispatch(compiled, launch_payload, options)
        end
        return tryHomingDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds
        and (compiled.plan.bounds.has_speed_plus == true or compiled.plan.bounds.has_size_plus == true)
        and compiled.plan.bounds.has_timer == true then
        return tryTimerDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds
        and (compiled.plan.bounds.has_speed_plus == true or compiled.plan.bounds.has_size_plus == true)
        and compiled.plan.bounds.has_trigger == true then
        return tryTriggerDispatch(compiled, launch_payload, options)
    end

    if sourceModifierClosureCandidate(compiled.plan) then
        return trySourceModifierClosureDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_size_plus then
        return trySizePlusDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_speed_plus then
        return trySpeedPlusDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_timer then
        return tryTimerDispatch(compiled, launch_payload, options)
    end

    if compiled.plan and compiled.plan.bounds and compiled.plan.bounds.has_trigger then
        return tryTriggerDispatch(compiled, launch_payload, options)
    end

    local live_ok, live_reason, live_mode, planned_count_or_counter, pattern_kind, pattern_op = validateLivePrimaryPlan(compiled.plan, options)
    if not live_ok then
        local details = {
            plan_recipe_id = compiled.recipe_id,
        }
        if isPatternMode(live_mode) or live_mode == "pattern" or estimated_pattern_kind ~= nil then
            return patternRejected(pattern_kind or estimated_pattern_kind, live_reason, details, planned_count_or_counter)
        end
        if live_mode == "multicast" or estimated_multicast_fanout then
            return multicastRejected(live_reason, details, planned_count_or_counter)
        end
        return rejected(live_reason, details)
    end

    local attached = plan_cache.attachHelperRecords(compiled.recipe_id, { limits = options.budget_limits })
    if not attached.ok then
        local details = {
            plan_recipe_id = compiled.recipe_id,
            error = firstErrorMessage(attached),
            errors = attached.errors,
        }
        if isPatternMode(live_mode) then
            return patternRejected(pattern_kind, "helper_records_failed", details)
        end
        if live_mode == "multicast" then
            return multicastRejected("helper_records_failed", details)
        end
        return rejected("helper_records_failed", details)
    end

    local selected_helpers, materialized_reason = collectPrimaryHelpers(attached.plan, options)
    if not selected_helpers then
        local details = {
            plan_recipe_id = compiled.recipe_id,
        }
        if isPatternMode(live_mode) then
            local counter = nil
            if materialized_reason == "multicast_cap_exceeded" then
                counter = "live_multicast_cap_rejections"
            elseif string.find(tostring(materialized_reason), "payload", 1, true)
                or string.find(tostring(materialized_reason), "postfix", 1, true)
                or string.find(tostring(materialized_reason), "source", 1, true)
                or string.find(tostring(materialized_reason), "parent", 1, true) then
                counter = "live_pattern_payload_rejections"
            end
            return patternRejected(pattern_kind, materialized_reason, details, counter)
        elseif live_mode == "multicast" then
            local counter = nil
            if materialized_reason == "multicast_cap_exceeded" then
                counter = "live_multicast_cap_rejections"
            elseif string.find(tostring(materialized_reason), "payload", 1, true)
                or string.find(tostring(materialized_reason), "postfix", 1, true)
                or string.find(tostring(materialized_reason), "source", 1, true)
                or string.find(tostring(materialized_reason), "parent", 1, true) then
                counter = "live_multicast_payload_rejections"
            end
            return multicastRejected(materialized_reason, details, counter)
        end
        return rejected(materialized_reason, details)
    end

    local plan = attached.plan
    if not isFanoutMode(live_mode) and #selected_helpers ~= 1 then
        return rejected("slot_count_not_one", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if live_mode == "multicast" and #selected_helpers <= 1 then
        return multicastRejected("multicast_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    if isPatternMode(live_mode) and #selected_helpers <= 1 then
        return patternRejected(pattern_kind, "pattern_fanout_missing", {
            plan_recipe_id = compiled.recipe_id,
        }, "live_pattern_unsupported_opcode_rejections")
    end

    local source_recipe_id = options.source_recipe_id or launch_payload.recipe_id
    local result_recipe_id = source_recipe_id or compiled.recipe_id

    local pattern_info, pattern_err = computePatternInfo(live_mode, pattern_kind, pattern_op, selected_helpers, launch_payload)
    if pattern_err then
        return patternRejected(pattern_kind, pattern_err, {
            plan_recipe_id = compiled.recipe_id,
        })
    end
    local cast_id = nextCastId(result_recipe_id, compiled.recipe_id)
    runtime_stats.inc("live_2_2c_qualified")
    if live_mode == "multicast" then
        runtime_stats.inc("live_multicast_qualified")
        runtime_stats.inc("live_multicast_emissions_planned", #selected_helpers)
    elseif isPatternMode(live_mode) then
        patternQualified(pattern_kind, #selected_helpers)
    end

    local job_inputs = buildJobInputs(selected_helpers, compiled.recipe_id, cast_id, launch_payload, pattern_info)
    local slot_ids = {}
    local helper_engine_ids = {}
    local emission_indexes = {}
    local pattern_direction_keys = {}
    for index, pair in ipairs(selected_helpers) do
        slot_ids[index] = pair.helper.slot_id
        helper_engine_ids[index] = pair.helper.engine_id
        emission_indexes[index] = pair.slot.emission_index or pair.helper.emission_index or index
        if pattern_info and pattern_info.direction_keys then
            pattern_direction_keys[index] = pattern_info.direction_keys[index]
        end
    end

    if options.dry_run == true then
        return {
            ok = true,
            used_live_2_2c = true,
            dry_run = true,
            recipe_id = result_recipe_id,
            plan_recipe_id = compiled.recipe_id,
            slot_id = slot_ids[1],
            helper_engine_id = helper_engine_ids[1],
            slot_ids = slot_ids,
            helper_engine_ids = helper_engine_ids,
            emission_indexes = emission_indexes,
            pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
            pattern_count = pattern_info and pattern_info.pattern_count or nil,
            pattern_direction_keys = pattern_direction_keys,
            spread_preset = pattern_info and pattern_info.spread_preset or nil,
            spread_side_angle_degrees = pattern_info and pattern_info.spread_side_angle_degrees or nil,
            spread_rotation_axis = pattern_info and pattern_info.spread_rotation_axis or nil,
            burst_param_count = pattern_info and pattern_info.burst_param_count or nil,
            burst_ring_angle_degrees = pattern_info and pattern_info.burst_ring_angle_degrees or nil,
            burst_distribution = pattern_info and pattern_info.burst_distribution or nil,
            slot_count = plan.slot_count or #plan.emission_slots,
            helper_record_count = plan.helper_record_count or #plan.helper_records,
            dispatch_count = #selected_helpers,
            fanout_count = #selected_helpers,
            simple_note = live_reason,
            live_mode = live_mode,
            cast_id = cast_id,
        }
    end

    local job_ids = {}
    for _, job_input in ipairs(job_inputs) do
        local enqueue = orchestrator.enqueue(job_input)
        if not enqueue.ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            if #job_ids > 0 then
                return bridgeError(enqueue.error or "enqueue failed", {
                    stage = "enqueue",
                    recipe_id = result_recipe_id,
                    plan_recipe_id = compiled.recipe_id,
                    slot_id = job_input.slot_id,
                    helper_engine_id = job_input.helper_engine_id,
                    cast_id = cast_id,
                    job_ids = job_ids,
                    fallback_allowed = false,
                })
            end
            local details = {
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = job_input.slot_id,
                helper_engine_id = job_input.helper_engine_id,
                error = enqueue.error or "enqueue failed",
                cast_id = cast_id,
            }
            if isPatternMode(live_mode) then
                return patternRejected(pattern_kind, "enqueue_failed", details)
            elseif live_mode == "multicast" then
                return multicastRejected("enqueue_failed", details)
            end
            return fallback("enqueue_failed", details)
        end
        job_ids[#job_ids + 1] = enqueue.job_id
    end
    if live_mode == "multicast" then
        runtime_stats.inc("live_multicast_jobs_enqueued", #job_ids)
    elseif isPatternMode(live_mode) then
        runtime_stats.inc("live_multicast_jobs_enqueued", #job_ids)
    end
    chaos_budget.observe({
        jobs = #job_ids,
        queue = orchestrator.queueLength(),
        projectiles = #selected_helpers,
    })

    local tick_result = tickUntilJobsSettled(job_ids, options)
    local jobs = {}
    local projectile_ids = {}
    local projectile_id_count = 0
    local pending_job_count = 0
    local allow_pending_launch_jobs = options.allow_pending_launch_jobs == true
    for index, job_id in ipairs(job_ids) do
        local summary = jobSummary(job_id)
        jobs[index] = summary
        if summary.projectile_id ~= nil then
            projectile_ids[#projectile_ids + 1] = summary.projectile_id
            projectile_id_count = projectile_id_count + 1
        end
        local pending = summary.job_status == "queued" or summary.job_status == "running"
        if pending and allow_pending_launch_jobs then
            pending_job_count = pending_job_count + 1
        elseif summary.job_status == "queued" then
            orchestrator.cancel(job_id)
        end
        if not (pending and allow_pending_launch_jobs)
            and (summary.job_status ~= "complete" or summary.launch_accepted ~= true) then
            runtime_stats.inc("live_2_2c_dispatch_failed")
            return bridgeError(summary.error or "helper launch job did not complete", {
                stage = "launch_job",
                recipe_id = result_recipe_id,
                plan_recipe_id = compiled.recipe_id,
                slot_id = summary.slot_id,
                helper_engine_id = summary.helper_engine_id,
                job_id = job_id,
                job_ids = job_ids,
                job_status = summary.job_status,
                tick_result = tick_result,
                cast_id = cast_id,
                fallback_allowed = false,
            })
        end
    end

    local first_job = jobs[1] or {}
    log.info(string.format(
        "SPELLFORGE_LIVE_2_2C_SIMPLE_DISPATCH_OK recipe_id=%s plan_recipe_id=%s dispatch_count=%s fanout_count=%s live_mode=%s pattern_kind=%s first_slot_id=%s first_helper_engine_id=%s projectile_count=%s",
        tostring(result_recipe_id),
        tostring(compiled.recipe_id),
        tostring(#job_ids),
        tostring(#selected_helpers),
        tostring(live_mode),
        tostring(pattern_info and pattern_info.pattern_kind or nil),
        tostring(slot_ids[1]),
        tostring(helper_engine_ids[1]),
        tostring(projectile_id_count)
    ))
    if options.chaos_budget_profile == "chaos" and isFanoutMode(live_mode) then
        runtime_stats.inc("chaos_budget_high_fanout_smoke")
        log.info(string.format(
            "SPELLFORGE_CHAOS_STRESS_OK profile=%s observed_jobs=%d observed_projectiles=%d observed_queue=%d live_mode=%s fanout_count=%d",
            tostring(options.chaos_budget_profile),
            #job_ids,
            #selected_helpers,
            tonumber(orchestrator.queueLength()) or 0,
            tostring(live_mode),
            #selected_helpers
        ))
    end
    runtime_stats.inc("live_2_2c_dispatch_ok")

    return {
        ok = true,
        used_live_2_2c = true,
        recipe_id = result_recipe_id,
        plan_recipe_id = compiled.recipe_id,
        slot_id = slot_ids[1],
        helper_engine_id = helper_engine_ids[1],
        slot_ids = slot_ids,
        helper_engine_ids = helper_engine_ids,
        emission_indexes = emission_indexes,
        pattern_kind = pattern_info and pattern_info.pattern_kind or nil,
        pattern_count = pattern_info and pattern_info.pattern_count or nil,
        pattern_direction_keys = pattern_direction_keys,
        spread_preset = pattern_info and pattern_info.spread_preset or nil,
        spread_side_angle_degrees = pattern_info and pattern_info.spread_side_angle_degrees or nil,
        spread_rotation_axis = pattern_info and pattern_info.spread_rotation_axis or nil,
        burst_param_count = pattern_info and pattern_info.burst_param_count or nil,
        burst_ring_angle_degrees = pattern_info and pattern_info.burst_ring_angle_degrees or nil,
        burst_distribution = pattern_info and pattern_info.burst_distribution or nil,
        projectile_id = first_job.projectile_id,
        projectile_ids = projectile_ids,
        projectile_id_source = first_job.projectile_id_source,
        projectile_registered = first_job.projectile_registered == true,
        job_id = job_ids[1],
        job_ids = job_ids,
        jobs = jobs,
        pending_launch_jobs = pending_job_count > 0,
        pending_job_count = pending_job_count,
        all_launch_jobs_complete = pending_job_count == 0,
        job_status = first_job.job_status,
        cast_id = cast_id,
        runtime = "2.2c_live_helper",
        fallback = false,
        dispatch_count = #job_ids,
        fanout_count = #selected_helpers,
        slot_count = plan.slot_count or #plan.emission_slots,
        helper_record_count = plan.helper_record_count or #plan.helper_records,
        effect_id = selected_helpers[1] and selected_helpers[1].slot.effects and selected_helpers[1].slot.effects[1] and selected_helpers[1].slot.effects[1].id or nil,
        simple_note = live_reason,
        live_mode = live_mode,
    }
end

return live_simple_dispatch
