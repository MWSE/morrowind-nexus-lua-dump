local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.launch_modifier_policy")
local plan_cache = require("scripts.spellforge.global.plan_cache")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local live_size_plus = require("scripts.spellforge.global.live_size_plus")
local live_speed_plus = require("scripts.spellforge.global.live_speed_plus")

local launch_modifier_policy = {}

launch_modifier_policy.VERSION = "spellforge-launch-modifier-policy-v4"

local RANGE_TARGET = 2

local function hasPayloadBindings(entry)
    return type(entry and entry.payload_bindings) == "table" and #entry.payload_bindings > 0
end

local function hasPostfix(entry)
    return type(entry and entry.postfix_ops) == "table" and #entry.postfix_ops > 0
end

local function isTargetRange(range)
    if tonumber(range) == RANGE_TARGET then
        return true
    end
    return string.lower(tostring(range or "")) == "target"
end

local function detonatePayloadSafety(entry)
    local effect_count = 0
    for _, effect in ipairs(entry and entry.effects or {}) do
        effect_count = effect_count + 1
        if not isTargetRange(effect.range) then
            return false, "detonate_requires_target_range"
        end
        if (tonumber(effect.area) or 0) <= 0 then
            return false, "detonate_requires_area"
        end
    end
    if effect_count == 0 then
        return false, "detonate_requires_area"
    end
    return true, nil
end

local function entryBySlotId(plan, ir, slot_id)
    if slot_id == nil then
        return nil
    end
    if ir and ir.entries_by_slot_id and ir.entries_by_slot_id[slot_id] then
        return ir.entries_by_slot_id[slot_id]
    end
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.slot_id == slot_id then
            return slot
        end
    end
    return nil
end

local function isNestedPayloadEntry(plan, ir, entry)
    if tonumber(entry and entry.payload_depth) and tonumber(entry.payload_depth) >= 2 then
        return true
    end
    local parent = entryBySlotId(plan, ir, entry and entry.parent_slot_id)
    if parent and tonumber(parent.payload_depth) and tonumber(parent.payload_depth) >= 1 then
        return true
    end
    if parent and (parent.source_postfix_opcode == "Trigger" or parent.source_postfix_opcode == "Timer") then
        return true
    end
    return false
end

local function cloneWarnings(warnings)
    local out = {}
    for index, warning in ipairs(warnings or {}) do
        out[index] = warning
    end
    return out
end

local function emitDeferred(entry, reason, opts)
    if opts and opts.quiet == true then
        return
    end
    if opts and opts.policy_kind == "source" then
        runtime_stats.inc("source_modifier_policy_deferred")
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_POLICY_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
    else
        runtime_stats.inc("payload_modifier_policy_deferred")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_POLICY_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
    end
end

local function emitOk(entry, kind, opts)
    if opts and opts.quiet == true then
        return
    end
    if opts and opts.policy_kind == "source" then
        runtime_stats.inc("source_modifier_policy_ok")
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_POLICY_OK recipe_id=%s slot_id=%s source_modifier_kind=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(kind)
        ))
    else
        runtime_stats.inc("payload_modifier_policy_ok")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_POLICY_OK recipe_id=%s slot_id=%s payload_modifier_kind=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(kind)
        ))
    end
end

local emitFanoutDeferred
local emitFanoutOk
local inspectPrefixOps

local function modifierKind(features)
    if features and features.speed_plus == true and features.size_plus == true then
        return "speed_plus_size_plus"
    elseif features and features.speed_plus == true then
        return "speed_plus"
    elseif features and features.size_plus == true then
        return "size_plus"
    elseif features and features.detonate == true then
        return "detonate"
    end
    return nil
end

local function compatibilityReason(reason, opts)
    if opts and opts.compatibility == "chain" then
        if reason == "payload_speed_plus_disabled" then
            return "chain_speed_plus_disabled"
        elseif reason == "payload_size_plus_disabled" then
            return "chain_size_plus_disabled"
        elseif reason == "payload_speed_plus_field_missing" then
            return "chain_speed_plus_field_missing"
        elseif reason == "payload_size_plus_apply_failed" then
            return "chain_size_plus_apply_failed"
        elseif reason == "payload_modifier_combo_deferred" then
            return "chain_modifier_combo_deferred"
        elseif reason == "payload_modifier_cap_exceeded" then
            return "chain_multicast_fanout_cap_exceeded"
        elseif reason == "payload_modifier_unsupported_prefix" then
            return "chain_payload_modifier_deferred"
        end
    end
    return reason
end

local function reject(entry, reason, features, mutations, warnings, opts)
    local mapped = compatibilityReason(reason, opts)
    emitDeferred(entry, mapped, opts)
    if emitFanoutDeferred then
        emitFanoutDeferred(entry, mapped, features, opts)
    end
    return {
        ok = false,
        version = launch_modifier_policy.VERSION,
        rejection_reason = mapped,
        modifier_features = features or {},
        mutations = mutations or {},
        warnings = cloneWarnings(warnings),
    }
end

local function success(entry, features, mutations, warnings, opts)
    local kind = mutations and (mutations.payload_modifier_kind or mutations.source_modifier_kind) or nil
    if kind ~= nil then
        emitOk(entry, kind, opts)
    end
    return {
        ok = true,
        version = launch_modifier_policy.VERSION,
        rejection_reason = nil,
        modifier_features = features or {},
        mutations = mutations or {},
        warnings = cloneWarnings(warnings),
    }
end

local function multicastFanout(op)
    local count = tonumber(op and op.params and op.params.count) or 1
    if count ~= count or count == math.huge or count == -math.huge then
        return 1
    end
    return math.max(1, math.floor(count))
end

local function clampPositiveInt(value, default_value, hard_max)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = default_value or 1
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    end
    local max_value = tonumber(hard_max)
    if max_value ~= nil and n > max_value then
        n = max_value
    end
    return n
end

local function sourceEventCount(source_kind, source_entry)
    local _, details = inspectPrefixOps(source_entry)
    if source_kind == "bounce" then
        return clampPositiveInt(
            details and details.bounce_op and details.bounce_op.params and details.bounce_op.params.bounces,
            1,
            limits.MAX_BOUNCE_COUNT_HARD
        )
    elseif source_kind == "pierce" then
        return clampPositiveInt(
            details and details.pierce_op and details.pierce_op.params and details.pierce_op.params.pierces,
            2,
            limits.MAX_PIERCE_COUNT_HARD
        )
    end
    return 1
end

local function payloadFanoutModifier(features)
    return features
        and features.multicast == true
        and (features.speed_plus == true or features.size_plus == true)
end

local function payloadPatternModifier(features)
    return payloadFanoutModifier(features) and features.pattern == true
end

emitFanoutDeferred = function(entry, reason, features, opts)
    if opts and opts.quiet == true then
        return
    end
    if opts and opts.policy_kind == "source" then
        return
    end
    if not payloadFanoutModifier(features) then
        return
    end
    runtime_stats.inc("payload_modifier_fanout_policy_deferred")
    log.info(string.format(
        "SPELLFORGE_PAYLOAD_MODIFIER_FANOUT_POLICY_DEFERRED recipe_id=%s slot_id=%s reason=%s",
        tostring(entry and entry.recipe_id),
        tostring(entry and entry.slot_id),
        tostring(reason)
    ))
    if features.speed_plus == true and features.size_plus == true then
        runtime_stats.inc("payload_modifier_combined_fanout_deferred")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_COMBINED_FANOUT_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
    end
    if reason == "payload_modifier_combo_deferred" and features.speed_plus == true and features.size_plus == true then
        runtime_stats.inc("payload_modifier_combined_multicast_deferred")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_COMBINED_MULTICAST_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
        if features.pattern == true then
            runtime_stats.inc("payload_modifier_combined_pattern_deferred")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_MODIFIER_COMBINED_PATTERN_DEFERRED recipe_id=%s slot_id=%s reason=%s",
                tostring(entry and entry.recipe_id),
                tostring(entry and entry.slot_id),
                tostring(reason)
            ))
        end
    elseif reason == "payload_modifier_pattern_deferred" then
        runtime_stats.inc("payload_modifier_pattern_deferred")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_PATTERN_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
    end
    if payloadPatternModifier(features) then
        runtime_stats.inc("payload_modifier_pattern_policy_deferred")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_PATTERN_POLICY_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
        if reason == "payload_modifier_nested_deferred" then
            runtime_stats.inc("payload_modifier_nested_pattern_deferred")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_MODIFIER_NESTED_PATTERN_DEFERRED recipe_id=%s slot_id=%s reason=%s",
                tostring(entry and entry.recipe_id),
                tostring(entry and entry.slot_id),
                tostring(reason)
            ))
        end
    end
end

emitFanoutOk = function(entry, kind, features, details, opts)
    if opts and opts.quiet == true then
        return
    end
    if opts and opts.policy_kind == "source" then
        return
    end
    if kind == nil or not payloadFanoutModifier(features) then
        return
    end
    runtime_stats.inc("payload_modifier_fanout_policy_ok")
    log.info(string.format(
        "SPELLFORGE_PAYLOAD_MODIFIER_FANOUT_POLICY_OK recipe_id=%s slot_id=%s payload_modifier_kind=%s fanout_count=%s",
        tostring(entry and entry.recipe_id),
        tostring(entry and entry.slot_id),
        tostring(kind),
        tostring(multicastFanout(details and details.multicast_op))
    ))
    if kind == "speed_plus_size_plus" then
        runtime_stats.inc("payload_modifier_combined_fanout_policy_ok")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_COMBINED_FANOUT_POLICY_OK recipe_id=%s slot_id=%s fanout_count=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(multicastFanout(details and details.multicast_op))
        ))
    end
    if payloadPatternModifier(features) then
        runtime_stats.inc("payload_modifier_pattern_policy_ok")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_MODIFIER_PATTERN_POLICY_OK recipe_id=%s slot_id=%s payload_modifier_kind=%s pattern_kind=%s fanout_count=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(kind),
            tostring(features.pattern_kind),
            tostring(multicastFanout(details and details.multicast_op))
        ))
    end
end

inspectPrefixOps = function(entry)
    local features = {
        speed_plus = false,
        size_plus = false,
        multicast = false,
        pattern = false,
        pattern_kind = nil,
        chain = false,
        pierce = false,
        bounce = false,
        homing = false,
        detonate = false,
    }
    local details = {
        speed_count = 0,
        speed_op = nil,
        size_count = 0,
        size_op = nil,
        multicast_count = 0,
        multicast_op = nil,
        pattern_count = 0,
        pattern_op = nil,
        chain_count = 0,
        chain_op = nil,
        pierce_count = 0,
        pierce_op = nil,
        bounce_count = 0,
        bounce_op = nil,
        homing_count = 0,
        homing_op = nil,
        detonate_count = 0,
        detonate_op = nil,
        unsupported_count = 0,
        unsupported_opcode = nil,
    }

    for _, op in ipairs(entry and entry.prefix_ops or {}) do
        local opcode = op and op.opcode
        if opcode == "Speed+" then
            features.speed_plus = true
            details.speed_count = details.speed_count + 1
            details.speed_op = details.speed_op or op
        elseif opcode == "Size+" then
            features.size_plus = true
            details.size_count = details.size_count + 1
            details.size_op = details.size_op or op
        elseif opcode == "Multicast" then
            features.multicast = true
            details.multicast_count = details.multicast_count + 1
            details.multicast_op = details.multicast_op or op
        elseif opcode == "Spread" or opcode == "Burst" then
            features.pattern = true
            details.pattern_count = details.pattern_count + 1
            if features.pattern_kind ~= nil and features.pattern_kind ~= opcode then
                details.pattern_ambiguous = true
            end
            features.pattern_kind = features.pattern_kind or opcode
            details.pattern_op = details.pattern_op or op
        elseif opcode == "Chain" then
            features.chain = true
            details.chain_count = details.chain_count + 1
            details.chain_op = details.chain_op or op
        elseif opcode == "Pierce" then
            features.pierce = true
            details.pierce_count = details.pierce_count + 1
            details.pierce_op = details.pierce_op or op
        elseif opcode == "Bounce" then
            features.bounce = true
            details.bounce_count = details.bounce_count + 1
            details.bounce_op = details.bounce_op or op
        elseif opcode == "Homing" then
            features.homing = true
            details.homing_count = details.homing_count + 1
            details.homing_op = details.homing_op or op
        elseif opcode == "Detonate" then
            features.detonate = true
            details.detonate_count = details.detonate_count + 1
            details.detonate_op = details.detonate_op or op
        else
            details.unsupported_count = details.unsupported_count + 1
            details.unsupported_opcode = details.unsupported_opcode or opcode
        end
    end

    return features, details
end

function launch_modifier_policy.eventSourceFanoutBudget(plan, ir, source_entry, opts)
    local options = opts or {}
    local source_kind = options.source_kind
    if source_kind ~= "bounce" and source_kind ~= "pierce" then
        return {
            ok = false,
            rejection_reason = "event_source_fanout_budget_exceeded",
            source_kind = source_kind,
        }
    end

    local source_fanout_count = clampPositiveInt(
        options.source_fanout_count,
        1,
        options.max_source_fanout or options.max_projectiles or limits.MAX_PROJECTILES_PER_CAST
    )
    local event_count_per_source = clampPositiveInt(
        options.event_count_per_source or sourceEventCount(source_kind, source_entry),
        1,
        source_kind == "bounce" and limits.MAX_BOUNCE_COUNT_HARD or limits.MAX_PIERCE_COUNT_HARD
    )
    local payload_fanout_count = clampPositiveInt(
        options.payload_fanout_count,
        1,
        options.max_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT
    )
    local total_event_jobs = source_fanout_count * event_count_per_source * payload_fanout_count
    local shared_cap = tonumber(options.max_event_source_resumes_per_cast)
        or limits.MAX_EVENT_SOURCE_RESUMES_PER_CAST
    local source_cap = nil
    local source_reason = nil
    if source_kind == "bounce" then
        source_cap = tonumber(options.max_bounce_payload_jobs_per_cast)
            or limits.MAX_BOUNCE_PAYLOAD_JOBS_PER_CAST
        source_reason = "bounce_fanout_budget_exceeded"
    elseif source_kind == "pierce" then
        source_cap = tonumber(options.max_pierce_payload_jobs_per_cast)
            or limits.MAX_PIERCE_PAYLOAD_JOBS_PER_CAST
        source_reason = "pierce_fanout_budget_exceeded"
    end

    local ok = total_event_jobs <= shared_cap and (source_cap == nil or total_event_jobs <= source_cap)
    local reason = nil
    if total_event_jobs > shared_cap then
        reason = "event_source_fanout_budget_exceeded"
    elseif source_cap ~= nil and total_event_jobs > source_cap then
        reason = source_reason
    end

    if options.quiet ~= true then
        if ok then
            runtime_stats.inc("event_source_fanout_budget_ok")
            log.info(string.format(
                "SPELLFORGE_EVENT_SOURCE_FANOUT_BUDGET_OK source_kind=%s source_fanout_count=%s event_count_per_source=%s payload_fanout_count=%s total_event_jobs=%s shared_cap=%s source_cap=%s",
                tostring(source_kind),
                tostring(source_fanout_count),
                tostring(event_count_per_source),
                tostring(payload_fanout_count),
                tostring(total_event_jobs),
                tostring(shared_cap),
                tostring(source_cap)
            ))
        else
            runtime_stats.inc("event_source_fanout_budget_deferred")
            log.info(string.format(
                "SPELLFORGE_EVENT_SOURCE_FANOUT_BUDGET_DEFERRED source_kind=%s reason=%s source_fanout_count=%s event_count_per_source=%s payload_fanout_count=%s total_event_jobs=%s shared_cap=%s source_cap=%s",
                tostring(source_kind),
                tostring(reason),
                tostring(source_fanout_count),
                tostring(event_count_per_source),
                tostring(payload_fanout_count),
                tostring(total_event_jobs),
                tostring(shared_cap),
                tostring(source_cap)
            ))
        end
    end

    return {
        ok = ok,
        rejection_reason = reason,
        source_kind = source_kind,
        source_fanout_count = source_fanout_count,
        event_count_per_source = event_count_per_source,
        payload_fanout_count = payload_fanout_count,
        total_event_jobs = total_event_jobs,
        shared_cap = shared_cap,
        source_cap = source_cap,
    }
end

function launch_modifier_policy.eventSourceTimerBudget(plan, ir, source_entry, opts)
    local options = opts or {}
    local source_kind = options.source_kind
    if source_kind ~= "bounce" and source_kind ~= "pierce" then
        return {
            ok = false,
            rejection_reason = "event_source_timer_budget_exceeded",
            source_kind = source_kind,
        }
    end

    local source_fanout_count = clampPositiveInt(
        options.source_fanout_count,
        1,
        options.max_source_fanout or options.max_projectiles or limits.MAX_PROJECTILES_PER_CAST
    )
    local payload_fanout_count = clampPositiveInt(
        options.timer_payload_fanout_count or options.payload_fanout_count,
        1,
        options.max_payload_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT
    )
    local total_timer_jobs = source_fanout_count * payload_fanout_count
    local shared_cap = tonumber(options.max_event_source_timer_jobs_per_cast)
        or limits.MAX_EVENT_SOURCE_TIMER_JOBS_PER_CAST
    local source_cap = tonumber(options.max_timer_payload_jobs_per_cast)
        or (source_kind == "bounce" and limits.MAX_BOUNCE_PAYLOAD_JOBS_PER_CAST)
        or (source_kind == "pierce" and limits.MAX_PIERCE_PAYLOAD_JOBS_PER_CAST)
        or shared_cap
    local source_reason = source_kind == "bounce"
        and "bounce_timer_budget_exceeded"
        or "pierce_timer_budget_exceeded"

    local ok = total_timer_jobs <= shared_cap and total_timer_jobs <= source_cap
    local reason = nil
    if total_timer_jobs > shared_cap then
        reason = "event_source_timer_budget_exceeded"
    elseif total_timer_jobs > source_cap then
        reason = source_reason
    end

    if options.quiet ~= true then
        if ok then
            runtime_stats.inc("event_source_timer_budget_ok")
            log.info(string.format(
                "SPELLFORGE_EVENT_SOURCE_TIMER_BUDGET_OK source_kind=%s source_fanout_count=%s timer_payload_fanout_count=%s total_timer_jobs=%s shared_cap=%s source_cap=%s",
                tostring(source_kind),
                tostring(source_fanout_count),
                tostring(payload_fanout_count),
                tostring(total_timer_jobs),
                tostring(shared_cap),
                tostring(source_cap)
            ))
        else
            runtime_stats.inc("event_source_timer_budget_deferred")
            log.info(string.format(
                "SPELLFORGE_EVENT_SOURCE_TIMER_BUDGET_DEFERRED source_kind=%s reason=%s source_fanout_count=%s timer_payload_fanout_count=%s total_timer_jobs=%s shared_cap=%s source_cap=%s",
                tostring(source_kind),
                tostring(reason),
                tostring(source_fanout_count),
                tostring(payload_fanout_count),
                tostring(total_timer_jobs),
                tostring(shared_cap),
                tostring(source_cap)
            ))
        end
    end

    return {
        ok = ok,
        rejection_reason = reason,
        source_kind = source_kind,
        source_fanout_count = source_fanout_count,
        timer_payload_fanout_count = payload_fanout_count,
        payload_fanout_count = payload_fanout_count,
        total_timer_jobs = total_timer_jobs,
        shared_cap = shared_cap,
        source_cap = source_cap,
    }
end

local function modifierEnabled(kind, opts)
    local options = opts or {}
    if kind == "speed_plus" then
        if options.force_speed_plus_disabled == true then
            return false
        end
        return options.force_speed_plus_enabled == true
            or options.speed_plus_enabled == true
            or options.allow_speed_plus == true
    elseif kind == "size_plus" then
        if options.force_size_plus_disabled == true then
            return false
        end
        return options.force_size_plus_enabled == true
            or options.size_plus_enabled == true
            or options.allow_size_plus == true
    end
    return true
end

function launch_modifier_policy.gateHintsForModifierKinds(modifier_kinds, opts)
    local options = opts or {}
    local has_speed = false
    local has_size = false
    for _, kind in ipairs(modifier_kinds or {}) do
        if kind == "speed_plus" or kind == "speed_plus_size_plus" then
            has_speed = true
        end
        if kind == "size_plus" or kind == "speed_plus_size_plus" then
            has_size = true
        end
    end
    local force_speed_disabled = options.force_speed_plus_disabled == true
    local force_size_disabled = options.force_size_plus_disabled == true
    return {
        force_speed_plus_enabled = not force_speed_disabled
            and (options.force_speed_plus_enabled == true or has_speed),
        force_speed_plus_disabled = force_speed_disabled,
        speed_plus_enabled = not force_speed_disabled
            and (options.speed_plus_enabled == true or has_speed),
        force_size_plus_enabled = not force_size_disabled
            and (options.force_size_plus_enabled == true or has_size),
        force_size_plus_disabled = force_size_disabled,
        size_plus_enabled = not force_size_disabled
            and (options.size_plus_enabled == true or has_size),
    }
end

local function chainMulticastEnabled(opts)
    local options = opts or {}
    if options.force_chain_multicast_disabled == true then
        return false
    end
    return options.force_chain_multicast_enabled == true
        or options.allow_chain_multicast == true
        or options.chain_multicast_enabled == true
end

local function attachSizeAreaFromSpecs(plan, entry, mutation)
    if type(plan) ~= "table" or type(plan.helper_specs) ~= "table" or type(mutation) ~= "table" then
        return
    end
    for _, spec in ipairs(plan.helper_specs) do
        if spec and spec.slot_id == entry.slot_id then
            local effect = spec.effects and spec.effects[1] or nil
            if effect then
                mutation.size_plus_base_area = tonumber(effect._spellforge_size_plus_base_area or mutation.size_plus_base_area)
                mutation.size_plus_area = tonumber(effect.area or mutation.size_plus_area)
                return
            end
        end
    end
end

function launch_modifier_policy.copyMutationFields(target, mutation, kind, opts)
    if type(target) ~= "table" or type(mutation) ~= "table" then
        return
    end
    local options = opts or {}
    if options.kind_field then
        target[options.kind_field] = kind
    else
        target.payload_modifier_kind = kind
    end
    if kind == "speed_plus" then
        target.speed = mutation.speed_plus_speed
        target.maxSpeed = mutation.speed_plus_max_speed
        target.speed_plus = true
        target.speed_plus_mode = mutation.speed_plus_mode
        target.speed_plus_value = mutation.speed_plus_value
        target.speed_plus_base_speed = mutation.speed_plus_base_speed
        target.speed_plus_multiplier = mutation.speed_plus_multiplier
        target.speed_plus_speed = mutation.speed_plus_speed
        target.speed_plus_max_speed = mutation.speed_plus_max_speed
        target.speed_plus_field = mutation.speed_plus_field
        target.speed_plus_capped = mutation.speed_plus_capped
    elseif kind == "size_plus" then
        target.size_plus = true
        target.size_plus_mode = mutation.size_plus_mode
        target.size_plus_value = mutation.size_plus_value
        target.size_plus_multiplier = mutation.size_plus_multiplier
        target.size_plus_field = mutation.size_plus_field
        target.size_plus_capped = mutation.size_plus_capped
        target.size_plus_base_area = mutation.size_plus_base_area
        target.size_plus_area = mutation.size_plus_area
    end
end

function launch_modifier_policy.copyMutationSetFields(target, mutations, opts)
    if type(target) ~= "table" or type(mutations) ~= "table" then
        return {
            speed_plus = false,
            size_plus = false,
            detonate = false,
        }
    end
    local options = opts or {}
    local kind_field = options.kind_field or "payload_modifier_kind"
    local kind = mutations[kind_field] or mutations.payload_modifier_kind or mutations.source_modifier_kind
    local applied = {
        speed_plus = false,
        size_plus = false,
        detonate = false,
    }
    if type(mutations.speed_plus) == "table" then
        launch_modifier_policy.copyMutationFields(target, mutations.speed_plus, "speed_plus", options)
        applied.speed_plus = true
    end
    if type(mutations.size_plus) == "table" then
        launch_modifier_policy.copyMutationFields(target, mutations.size_plus, "size_plus", options)
        applied.size_plus = true
    end
    if mutations.payload_detonate == true then
        target.payload_detonate = true
        target.detonate_at_launch = true
        applied.detonate = true
    end
    target[kind_field] = kind
    return applied
end

function launch_modifier_policy.inspectPayloadEntry(plan, ir, payload_entry, opts)
    local options = opts or {}
    if type(payload_entry) ~= "table" then
        return reject(payload_entry, "payload_modifier_unsupported_prefix", nil, nil, nil, options)
    end

    local features, details = inspectPrefixOps(payload_entry)
    local mutations = {
        payload_modifier_kind = nil,
        speed_plus = nil,
        size_plus = nil,
        payload_detonate = nil,
        chain_multicast_fanout_count = nil,
    }
    local warnings = {}

    if details.unsupported_count > 0 then
        return reject(payload_entry, "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if options.require_chain_prefix == true and details.chain_count ~= 1 then
        return reject(payload_entry, "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if details.speed_count > 1 or details.size_count > 1 then
        return reject(payload_entry, "payload_modifier_combo_deferred", features, mutations, warnings, options)
    end
    if details.detonate_count > 1 then
        return reject(payload_entry, "detonate_modifier_combo_deferred", features, mutations, warnings, options)
    end
    if details.pattern_ambiguous == true then
        return reject(payload_entry, "payload_modifier_pattern_deferred", features, mutations, warnings, options)
    end

    if features.detonate then
        if options.allow_payload_detonate ~= true then
            return reject(payload_entry, "detonate_requires_payload_context", features, mutations, warnings, options)
        end
        if features.pattern
            or features.speed_plus
            or features.size_plus
            or features.chain
            or features.pierce
            or features.bounce
            or features.homing then
            return reject(payload_entry, "detonate_modifier_combo_deferred", features, mutations, warnings, options)
        end
        if hasPostfix(payload_entry) or hasPayloadBindings(payload_entry) then
            return reject(payload_entry, "detonate_nested_continuation_unsupported", features, mutations, warnings, options)
        end
        local safe, safety_reason = detonatePayloadSafety(payload_entry)
        if not safe then
            return reject(payload_entry, safety_reason or "detonate_requires_area", features, mutations, warnings, options)
        end
        mutations.payload_detonate = true
        mutations.payload_modifier_kind = "detonate"
        emitOk(payload_entry, "detonate", options)
        return success(payload_entry, features, mutations, warnings, options)
    end

    local has_modifier = features.speed_plus == true or features.size_plus == true
    if has_modifier then
        if isNestedPayloadEntry(plan, ir, payload_entry) and options.allow_nested_payload_modifiers ~= true then
            return reject(payload_entry, "payload_modifier_nested_deferred", features, mutations, warnings, options)
        end
        if (features.pierce or features.bounce) and options.allow_payload_source_modifiers ~= true then
            return reject(payload_entry, "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        if (hasPostfix(payload_entry) or hasPayloadBindings(payload_entry)) and options.allow_nested_payload_modifiers ~= true then
            return reject(payload_entry, "payload_modifier_nested_deferred", features, mutations, warnings, options)
        end
        if features.pattern then
            if not features.multicast or details.pattern_count ~= 1 then
                return reject(payload_entry, "payload_modifier_pattern_deferred", features, mutations, warnings, options)
            end
        end
    end

    if features.chain then
        if details.chain_count ~= 1 then
            return reject(payload_entry, "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        if details.multicast_count > 1 then
            return reject(payload_entry, "payload_modifier_cap_exceeded", features, mutations, warnings, options)
        end
    elseif details.multicast_count > 1 then
        return reject(payload_entry, "payload_modifier_cap_exceeded", features, mutations, warnings, options)
    end

    if features.multicast then
        local fanout_count = multicastFanout(details.multicast_op)
        mutations.chain_multicast_fanout_count = fanout_count
        if features.chain and not chainMulticastEnabled(options) then
            return reject(payload_entry, "chain_multicast_disabled", features, mutations, warnings, options)
        end
        local cap = features.pattern
            and tonumber(options.max_chain_pattern_fanout or options.max_chain_multicast_fanout or options.max_payload_modifier_fanout or options.max_fanout)
            or tonumber(options.max_chain_multicast_fanout or options.max_payload_modifier_fanout or options.max_fanout)
            or limits.MAX_NESTED_PAYLOAD_FANOUT
        if fanout_count > cap then
            return reject(payload_entry, "payload_modifier_cap_exceeded", features, mutations, warnings, options)
        end
    end

    local mutation = nil
    local mutation_err = nil
    if features.speed_plus then
        if not modifierEnabled("speed_plus", options) then
            return reject(payload_entry, "payload_speed_plus_disabled", features, mutations, warnings, options)
        end
        if live_speed_plus.launchSpeedField() == nil then
            return reject(payload_entry, "payload_speed_plus_field_missing", features, mutations, warnings, options)
        end
        mutation, mutation_err = live_speed_plus.computeMutation(details.speed_op, {
            recipe_id = plan and plan.recipe_id or payload_entry.recipe_id,
            slot_id = payload_entry.slot_id,
            entry = payload_entry,
            slot = payload_entry,
        })
        if not mutation then
            return reject(payload_entry, mutation_err or "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        mutations.speed_plus = mutation
    end
    if features.size_plus then
        if not modifierEnabled("size_plus", options) then
            return reject(payload_entry, "payload_size_plus_disabled", features, mutations, warnings, options)
        end
        mutation, mutation_err = live_size_plus.computeMutation(details.size_op)
        if not mutation then
            return reject(payload_entry, mutation_err or "payload_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        if options.apply_size_to_specs == true then
            local apply_result = nil
            apply_result, mutation_err = live_size_plus.applyToPayloadSlotHelperSpecs(plan, payload_entry.slot_id, mutation)
            if not apply_result then
                return reject(payload_entry, "payload_size_plus_apply_failed", features, mutations, warnings, options)
            end
            mutations.size_plus_apply_result = apply_result
        else
            attachSizeAreaFromSpecs(plan, payload_entry, mutation)
        end
        mutations.size_plus = mutation
    end
    mutations.payload_modifier_kind = modifierKind(features)
    emitFanoutOk(payload_entry, mutations.payload_modifier_kind, features, details, options)

    return success(payload_entry, features, mutations, warnings, options)
end

function launch_modifier_policy.inspectSourceEntry(plan, ir, source_entry, opts)
    local options = {}
    for key, value in pairs(opts or {}) do
        options[key] = value
    end
    options.policy_kind = "source"
    if type(source_entry) ~= "table" then
        return reject(source_entry, "source_modifier_unsupported_prefix", nil, nil, nil, options)
    end

    local features, details = inspectPrefixOps(source_entry)
    local mutations = {
        source_modifier_kind = nil,
        speed_plus = nil,
        size_plus = nil,
        size_plus_apply_result = nil,
        source_multicast_fanout_count = nil,
    }
    local warnings = {}
    local has_modifier = features.speed_plus == true or features.size_plus == true

    if details.unsupported_count > 0 then
        return reject(source_entry, "source_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if features.detonate then
        return reject(source_entry, "detonate_requires_payload_context", features, mutations, warnings, options)
    end
    if details.speed_count > 1 or details.size_count > 1 then
        return reject(source_entry, "source_modifier_combo_deferred", features, mutations, warnings, options)
    end
    if (features.bounce or features.pierce)
        and features.speed_plus
        and features.size_plus
        and options.allow_event_source_modifier_combo ~= true then
        return reject(source_entry, "source_modifier_combo_deferred", features, mutations, warnings, options)
    end
    if details.pattern_ambiguous == true then
        return reject(source_entry, "source_modifier_pattern_deferred", features, mutations, warnings, options)
    end
    if (features.bounce or features.pierce)
        and (features.pattern or features.multicast)
        and options.allow_event_source_fanout ~= true then
        return reject(source_entry, "source_modifier_pattern_deferred", features, mutations, warnings, options)
    end
    if features.pattern then
        if not features.multicast or details.pattern_count ~= 1 then
            return reject(source_entry, "source_modifier_pattern_deferred", features, mutations, warnings, options)
        end
    end
    if features.chain then
        if features.bounce or features.pierce or has_modifier then
            return reject(source_entry, "source_modifier_chain_deferred", features, mutations, warnings, options)
        end
    end
    if has_modifier
        and (hasPostfix(source_entry) or hasPayloadBindings(source_entry))
        and options.allow_source_continuation_modifiers ~= true then
        return reject(source_entry, "source_modifier_nested_deferred", features, mutations, warnings, options)
    end
    if features.bounce and features.pierce then
        return reject(source_entry, "source_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if details.bounce_count > 1 or details.pierce_count > 1 or details.homing_count > 1 or details.chain_count > 1 then
        return reject(source_entry, "source_modifier_cap_exceeded", features, mutations, warnings, options)
    end
    if features.bounce and options.allow_bounce_source ~= true then
        return reject(source_entry, "source_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if features.pierce and options.allow_pierce_source ~= true then
        return reject(source_entry, "source_modifier_unsupported_prefix", features, mutations, warnings, options)
    end
    if features.multicast then
        local fanout_count = multicastFanout(details.multicast_op)
        mutations.source_multicast_fanout_count = fanout_count
        local cap = tonumber(options.max_source_modifier_fanout or options.max_fanout or options.max_projectiles)
            or limits.MAX_PROJECTILES_PER_CAST
        if fanout_count > cap then
            return reject(source_entry, "source_modifier_cap_exceeded", features, mutations, warnings, options)
        end
    end

    local mutation = nil
    local mutation_err = nil
    if features.speed_plus then
        if not modifierEnabled("speed_plus", options) then
            return reject(source_entry, "source_speed_plus_disabled", features, mutations, warnings, options)
        end
        if live_speed_plus.launchSpeedField() == nil then
            return reject(source_entry, "source_speed_plus_field_missing", features, mutations, warnings, options)
        end
        mutation, mutation_err = live_speed_plus.computeMutation(details.speed_op, {
            recipe_id = plan and plan.recipe_id or source_entry.recipe_id,
            slot_id = source_entry.slot_id,
            entry = source_entry,
            slot = source_entry,
        })
        if not mutation then
            return reject(source_entry, mutation_err or "source_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        mutations.speed_plus = mutation
    end
    if features.size_plus then
        if not modifierEnabled("size_plus", options) then
            return reject(source_entry, "source_size_plus_disabled", features, mutations, warnings, options)
        end
        mutation, mutation_err = live_size_plus.computeMutation(details.size_op)
        if not mutation then
            return reject(source_entry, mutation_err or "source_modifier_unsupported_prefix", features, mutations, warnings, options)
        end
        if options.apply_size_to_specs == true then
            local apply_result = nil
            apply_result, mutation_err = live_size_plus.applyToPayloadSlotHelperSpecs(plan, source_entry.slot_id, mutation)
            if not apply_result then
                return reject(source_entry, "source_size_plus_apply_failed", features, mutations, warnings, options)
            end
            mutations.size_plus_apply_result = apply_result
        else
            attachSizeAreaFromSpecs(plan, source_entry, mutation)
        end
        mutations.size_plus = mutation
    end
    mutations.source_modifier_kind = modifierKind(features)

    return success(source_entry, features, mutations, warnings, options)
end

function launch_modifier_policy.applyToJob(plan, ir, payload_entry, job, event_context, opts)
    local inspected = launch_modifier_policy.inspectPayloadEntry(plan, ir, payload_entry, opts)
    if inspected.ok ~= true then
        return inspected
    end
    local mutations = inspected.mutations or {}
    local applied = launch_modifier_policy.copyMutationSetFields(job, mutations)
    if type(job.payload) == "table" then
        launch_modifier_policy.copyMutationSetFields(job.payload, mutations)
    end
    if applied.speed_plus == true then
        runtime_stats.inc("payload_speed_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_SPEED_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s speed_value=%s",
            tostring(job and job.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(job and job.slot_id),
            tostring(job and job.payload_slot_id),
            tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed)
        ))
        if inspected.modifier_features and inspected.modifier_features.multicast == true then
            runtime_stats.inc("payload_speed_plus_multicast_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SPEED_PLUS_MULTICAST_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s fanout_count=%s speed_value=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.fanout_count),
                tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed)
            ))
        end
        if inspected.modifier_features and inspected.modifier_features.pattern == true then
            runtime_stats.inc("payload_speed_plus_pattern_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SPEED_PLUS_PATTERN_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s pattern_kind=%s pattern_index=%s pattern_count=%s speed_value=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.pattern_kind),
                tostring(job and job.pattern_index),
                tostring(job and job.pattern_count),
                tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed)
            ))
        end
    end
    if applied.size_plus == true then
        runtime_stats.inc("payload_size_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_SIZE_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s size_area=%s",
            tostring(job and job.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(job and job.slot_id),
            tostring(job and job.payload_slot_id),
            tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
        ))
        if inspected.modifier_features and inspected.modifier_features.multicast == true then
            runtime_stats.inc("payload_size_plus_multicast_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SIZE_PLUS_MULTICAST_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s fanout_count=%s size_area=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.fanout_count),
                tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
            ))
        end
        if inspected.modifier_features and inspected.modifier_features.pattern == true then
            runtime_stats.inc("payload_size_plus_pattern_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SIZE_PLUS_PATTERN_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s pattern_kind=%s pattern_index=%s pattern_count=%s size_area=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.pattern_kind),
                tostring(job and job.pattern_index),
                tostring(job and job.pattern_count),
                tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
            ))
        end
    end
    if applied.speed_plus == true and applied.size_plus == true then
        runtime_stats.inc("payload_speed_size_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_SPEED_SIZE_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s speed_value=%s size_area=%s",
            tostring(job and job.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(job and job.slot_id),
            tostring(job and job.payload_slot_id),
            tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed),
            tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
        ))
        if inspected.modifier_features and inspected.modifier_features.multicast == true then
            runtime_stats.inc("payload_speed_size_plus_multicast_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SPEED_SIZE_PLUS_MULTICAST_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s fanout_count=%s speed_value=%s size_area=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.fanout_count),
                tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed),
                tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
            ))
        end
        if inspected.modifier_features and inspected.modifier_features.pattern == true then
            runtime_stats.inc("payload_speed_size_plus_pattern_policy_applied")
            log.info(string.format(
                "SPELLFORGE_PAYLOAD_SPEED_SIZE_PLUS_PATTERN_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s payload_slot_id=%s pattern_kind=%s pattern_index=%s pattern_count=%s speed_value=%s size_area=%s",
                tostring(job and job.recipe_id),
                tostring(event_context and event_context.event_kind),
                tostring(job and job.slot_id),
                tostring(job and job.payload_slot_id),
                tostring(job and job.pattern_kind),
                tostring(job and job.pattern_index),
                tostring(job and job.pattern_count),
                tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed),
                tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
            ))
        end
    end
    return inspected
end

function launch_modifier_policy.applySourcePolicyToLaunchSpec(plan, ir, source_entry, launch_spec, event_context, opts)
    local options = opts or {}
    local inspected = options.inspection
    if type(inspected) ~= "table" then
        inspected = launch_modifier_policy.inspectSourceEntry(plan, ir, source_entry, options)
    end
    if inspected.ok ~= true then
        if type(launch_spec) == "table" then
            launch_spec.source_modifier_rejection_reason = inspected.rejection_reason
            if type(launch_spec.payload) == "table" then
                launch_spec.payload.source_modifier_rejection_reason = inspected.rejection_reason
            end
        end
        return inspected
    end

    local mutations = inspected.mutations or {}
    local applied = launch_modifier_policy.copyMutationSetFields(launch_spec, mutations, {
        kind_field = "source_modifier_kind",
    })
    if type(launch_spec.payload) == "table" then
        launch_modifier_policy.copyMutationSetFields(launch_spec.payload, mutations, {
            kind_field = "source_modifier_kind",
        })
    end
    if applied.speed_plus == true then
        runtime_stats.inc("source_speed_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_SOURCE_SPEED_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s speed_value=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed)
        ))
    end
    if applied.size_plus == true then
        runtime_stats.inc("source_size_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_SOURCE_SIZE_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s size_area=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
        ))
    end
    if applied.speed_plus == true and applied.size_plus == true then
        runtime_stats.inc("source_speed_size_plus_policy_applied")
        log.info(string.format(
            "SPELLFORGE_SOURCE_SPEED_SIZE_PLUS_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s speed_value=%s size_area=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(mutations.speed_plus and mutations.speed_plus.speed_plus_speed),
            tostring(mutations.size_plus and mutations.size_plus.size_plus_area)
        ))
    end
    if inspected.modifier_features and inspected.modifier_features.multicast == true then
        runtime_stats.inc("source_modifier_multicast_policy_applied")
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_MULTICAST_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s source_modifier_kind=%s fanout_count=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(launch_spec and launch_spec.source_modifier_kind),
            tostring(launch_spec and launch_spec.fanout_count or mutations.source_multicast_fanout_count)
        ))
    end
    if inspected.modifier_features and inspected.modifier_features.pattern == true then
        runtime_stats.inc("source_modifier_pattern_policy_applied")
        log.info(string.format(
            "SPELLFORGE_SOURCE_MODIFIER_PATTERN_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s source_modifier_kind=%s pattern_kind=%s pattern_index=%s pattern_count=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(launch_spec and launch_spec.source_modifier_kind),
            tostring(launch_spec and launch_spec.pattern_kind),
            tostring(launch_spec and launch_spec.pattern_index),
            tostring(launch_spec and launch_spec.pattern_count)
        ))
    end
    return inspected
end

function launch_modifier_policy.preparePlanPayloadModifiers(plan, opts)
    local options = opts or {}
    local modifiers = {}
    local inspected_count = 0
    for _, slot in ipairs(plan and plan.emission_slots or {}) do
        if slot and slot.kind == "payload_emission" then
            if options.source_opcode == nil or slot.source_postfix_opcode == options.source_opcode then
                if options.source_slot_id == nil or slot.parent_slot_id == options.source_slot_id then
                    local inspection = launch_modifier_policy.inspectPayloadEntry(plan, nil, slot, options)
                    if inspection.ok ~= true then
                        return nil, inspection.rejection_reason, {
                            ok = false,
                            rejection_reason = inspection.rejection_reason,
                            payload_slot_id = slot.slot_id,
                            modifier_features = inspection.modifier_features,
                        }
                    end
                    if inspection.mutations and inspection.mutations.payload_modifier_kind ~= nil then
                        inspected_count = inspected_count + 1
                        modifiers[slot.slot_id] = inspection
                    end
                end
            end
        end
    end
    return {
        ok = true,
        modifier_count = inspected_count,
        modifiers_by_slot_id = modifiers,
    }, nil, nil
end

function launch_modifier_policy.prepareCachedPlanPayloadModifiers(recipe_id, opts)
    local options = opts or {}
    local attached_specs = plan_cache.attachHelperSpecs(recipe_id, options.helper_spec_options)
    if not attached_specs.ok then
        return nil, "helper_specs_failed", {
            ok = false,
            rejection_reason = "helper_specs_failed",
            recipe_id = recipe_id,
            error = attached_specs.error,
            errors = attached_specs.errors,
            warnings = attached_specs.warnings,
        }
    end

    local prepared, prepare_reason, details = launch_modifier_policy.preparePlanPayloadModifiers(attached_specs.plan, options)
    if not prepared then
        details = details or {}
        details.ok = false
        details.recipe_id = recipe_id
        details.rejection_reason = details.rejection_reason or prepare_reason or "payload_modifier_combo_deferred"
        return nil, details.rejection_reason, details
    end

    prepared.recipe_id = recipe_id
    prepared.plan = attached_specs.plan
    prepared.spec_count = attached_specs.spec_count
    prepared.warnings = attached_specs.warnings
    return prepared, nil, nil
end

return launch_modifier_policy
