local limits = require("scripts.spellforge.shared.limits")
local launch_modifier_policy = require("scripts.spellforge.global.launch_modifier_policy")
local homing_launch_policy = require("scripts.spellforge.global.homing_launch_policy")

local continuation_planner = {}

continuation_planner.VERSION = "spellforge-continuation-planner-v1"

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true, op
        end
    end
    return false, nil
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

local function hasPayloadBindings(entry)
    return type(entry and entry.payload_bindings) == "table" and #entry.payload_bindings > 0
end

local function helperId(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return entry.helper_engine_id or entry.helper_logical_id
end

local function firstEffectId(entry)
    local first = entry and entry.effects and entry.effects[1] or nil
    return first and first.id or nil
end

local function entryBySlot(ir, slot_id)
    if type(slot_id) ~= "string" or slot_id == "" then
        return nil
    end
    if ir and ir.entries_by_slot_id and ir.entries_by_slot_id[slot_id] then
        return ir.entries_by_slot_id[slot_id]
    end
    for _, entry in ipairs(ir and ir.entries or {}) do
        if entry.slot_id == slot_id then
            return entry
        end
    end
    return nil
end

local function continuationBySourceKind(ir, source_slot_id, kind)
    for _, continuation in ipairs(ir and ir.continuations or {}) do
        if continuation.source_slot_id == source_slot_id and continuation.kind == kind then
            return continuation
        end
    end
    return nil
end

local function firstContinuation(ir, kind)
    for _, continuation in ipairs(ir and ir.continuations or {}) do
        if continuation.kind == kind then
            return continuation
        end
    end
    return nil
end

local function entriesForContinuation(ir, continuation)
    local entries = {}
    for _, entry_id in ipairs(continuation and continuation.payload_entry_ids or {}) do
        local entry = ir and ir.entries_by_id and ir.entries_by_id[entry_id] or nil
        if entry then
            entries[#entries + 1] = entry
        end
    end
    table.sort(entries, function(a, b)
        local ae = tonumber(a.emission_index) or 0
        local be = tonumber(b.emission_index) or 0
        if ae ~= be then
            return ae < be
        end
        return tostring(a.slot_id) < tostring(b.slot_id)
    end)
    return entries
end

local function payloadSlotIds(entries)
    local ids = {}
    for i, entry in ipairs(entries or {}) do
        ids[i] = entry.slot_id
    end
    return ids
end

local function payloadHelperEngineIds(entries)
    local ids = {}
    for i, entry in ipairs(entries or {}) do
        ids[i] = helperId(entry)
    end
    return ids
end

local function payloadEffectIds(entries)
    local ids = {}
    for i, entry in ipairs(entries or {}) do
        ids[i] = firstEffectId(entry)
    end
    return ids
end

local function patternKind(entries)
    local kind = nil
    local op = nil
    for _, entry in ipairs(entries or {}) do
        local has_spread, spread_op = hasOpcode(entry.prefix_ops, "Spread")
        local has_burst, burst_op = hasOpcode(entry.prefix_ops, "Burst")
        if has_spread then
            if kind ~= nil and kind ~= "Spread" then
                return "ambiguous", nil
            end
            kind = "Spread"
            op = op or spread_op
        elseif has_burst then
            if kind ~= nil and kind ~= "Burst" then
                return "ambiguous", nil
            end
            kind = "Burst"
            op = op or burst_op
        end
    end
    return kind, op
end

local function payloadFeatures(entries)
    local features = {
        multicast = false,
        pattern = false,
        pattern_kind = nil,
        chain = false,
        pierce = false,
        homing = false,
        speed_plus = false,
        size_plus = false,
        detonate = false,
        nested_postfix = false,
    }
    if #(entries or {}) > 1 then
        features.multicast = true
    end
    for _, entry in ipairs(entries or {}) do
        if entry.fanout and entry.fanout.has_multicast then
            features.multicast = true
        end
        if entry.fanout and entry.fanout.has_pattern then
            features.pattern = true
        end
        if hasOpcode(entry.prefix_ops, "Multicast") then
            features.multicast = true
        end
        if hasOpcode(entry.prefix_ops, "Spread") or hasOpcode(entry.prefix_ops, "Burst") then
            features.pattern = true
        end
        if hasOpcode(entry.prefix_ops, "Chain") then
            features.chain = true
        end
        if hasOpcode(entry.prefix_ops, "Pierce") then
            features.pierce = true
        end
        if hasOpcode(entry.prefix_ops, "Homing") then
            features.homing = true
        end
        if hasOpcode(entry.prefix_ops, "Speed+") then
            features.speed_plus = true
        end
        if hasOpcode(entry.prefix_ops, "Size+") then
            features.size_plus = true
        end
        if hasOpcode(entry.prefix_ops, "Detonate") then
            features.detonate = true
        end
        if hasOpcode(entry.postfix_ops, "Trigger")
            or hasOpcode(entry.postfix_ops, "Timer")
            or hasPayloadBindings(entry) then
            features.nested_postfix = true
        end
    end
    features.pattern_kind = patternKind(entries)
    if features.pattern_kind == "ambiguous" then
        features.pattern_kind = nil
        features.pattern_ambiguous = true
    end
    return features
end

local function payloadMulticastEnabled(options)
    if options.force_payload_multicast_disabled == true then
        return false
    end
    return options.force_payload_multicast_enabled == true
        or options.allow_payload_multicast == true
        or options.payload_multicast_enabled == true
end

local function payloadPatternEnabled(options)
    if options.force_payload_pattern_disabled == true then
        return false
    end
    return options.force_payload_pattern_enabled == true
        or options.allow_payload_pattern == true
        or options.payload_pattern_enabled == true
end

local function chainMulticastEnabled(options)
    if options.force_chain_multicast_disabled == true then
        return false
    end
    return options.force_chain_multicast_enabled == true
        or options.allow_chain_multicast == true
        or options.chain_multicast_enabled == true
end

local function clampPositiveInteger(value, default_value, hard_max)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        n = default_value or 1
    end
    n = math.floor(n)
    if n < 1 then
        n = 1
    end
    if hard_max and n > hard_max then
        n = hard_max
    end
    return n
end

local function reject(plan, ir, event, source_entry, continuation, reason)
    return {
        ok = false,
        version = continuation_planner.VERSION,
        event_kind = event and event.event_kind or nil,
        recipe_id = (ir and ir.recipe_id) or (plan and plan.recipe_id),
        source_slot_id = source_entry and source_entry.slot_id or (event and event.source_slot_id),
        source_helper_engine_id = helperId(source_entry),
        continuation_id = continuation and continuation.continuation_id or nil,
        continuation_kind = continuation and continuation.kind or nil,
        payload_count = 0,
        payload_slot_ids = {},
        payload_helper_engine_ids = {},
        payload_features = {
            multicast = false,
            pattern = false,
            pattern_kind = nil,
            chain = false,
            pierce = false,
            homing = false,
            detonate = false,
        },
        planned_jobs = {},
        rejection_reason = reason,
    }
end

local function buildJobs(source_entry, payload_entries, event, job_kind, branch_kind, job_extra)
    local jobs = {}
    local count = #payload_entries
    for index, entry in ipairs(payload_entries) do
        local job = {
            job_kind = job_kind,
            slot_id = entry.slot_id,
            helper_engine_id = helperId(entry),
            payload_slot_id = entry.slot_id,
            source_slot_id = source_entry and source_entry.slot_id or nil,
            depth = entry.payload_depth or ((source_entry and source_entry.payload_depth or 0) + 1),
            branch_kind = branch_kind,
            branch_index = index,
            branch_count = count,
            bounce_index = event and event.bounce_index or nil,
        }
        for key, value in pairs(job_extra or {}) do
            job[key] = value
        end
        jobs[index] = job
    end
    return jobs
end

local function success(plan, ir, event, source_entry, continuation, payload_entries, features, jobs, extra)
    local first_payload = payload_entries and payload_entries[1] or nil
    local result = {
        ok = true,
        version = continuation_planner.VERSION,
        event_kind = event and event.event_kind or nil,
        recipe_id = (ir and ir.recipe_id) or (plan and plan.recipe_id),
        source_slot_id = source_entry and source_entry.slot_id or nil,
        source_helper_engine_id = helperId(source_entry),
        continuation_id = continuation and continuation.continuation_id or nil,
        continuation_kind = continuation and continuation.kind or nil,
        payload_count = #(payload_entries or {}),
        payload_slot_id = first_payload and first_payload.slot_id or nil,
        payload_helper_engine_id = helperId(first_payload),
        payload_slot_ids = payloadSlotIds(payload_entries),
        payload_helper_engine_ids = payloadHelperEngineIds(payload_entries),
        payload_effect_ids = payloadEffectIds(payload_entries),
        payload_features = {
            multicast = features and features.multicast == true or false,
            pattern = features and features.pattern == true or false,
            pattern_kind = features and features.pattern_kind or nil,
            chain = features and features.chain == true or false,
            pierce = features and features.pierce == true or false,
            homing = features and features.homing == true or false,
            detonate = features and features.detonate == true or false,
        },
        payload_multicast = features and features.multicast == true or false,
        payload_pattern = features and features.pattern == true or false,
        payload_pattern_kind = features and features.pattern_kind or nil,
        has_chain_payload = features and features.chain == true or false,
        planned_jobs = jobs or {},
        rejection_reason = nil,
    }
    for key, value in pairs(extra or {}) do
        result[key] = value
    end
    return result
end

local function validatePayloadSet(plan, ir, entries, features, options)
    local max_fanout = tonumber(options.max_fanout) or limits.MAX_NESTED_PAYLOAD_FANOUT
    local max_projectiles = tonumber(options.max_projectiles) or limits.MAX_PROJECTILES_PER_CAST
    if #entries == 0 then
        return "payload_missing"
    end
    if features.pattern_ambiguous then
        return "payload_pattern_ambiguous"
    end
    if features.nested_postfix and options.allow_nested_trigger_timer ~= true then
        return "nested_payload_runtime_deferred"
    end
    if features.pierce then
        return "pierce_recursion_deferred"
    end
    if features.homing then
        if features.chain then
            return "homing_chain_targeting_unsupported"
        end
        for _, entry in ipairs(entries or {}) do
            local policy = homing_launch_policy.inspectPayloadEntry(plan, ir, entry, {
                allow_payload_homing = options.allow_payload_homing == true,
                allow_nested_payload_homing = options.allow_nested_payload_homing == true,
                allow_homing = options.allow_homing == true,
                force_homing_enabled = options.force_homing_enabled,
                force_homing_disabled = options.force_homing_disabled,
                homing_enabled = options.homing_enabled == true,
                fanout_count = #entries,
                max_homing_fanout_per_cast = options.max_homing_fanout_per_cast,
                max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast,
                quiet = options.quiet_homing_policy == true,
            })
            if policy.ok ~= true then
                return policy.rejection_reason or "homing_nested_runtime_deferred"
            end
        end
    end
    if features.speed_plus or features.size_plus or features.detonate then
        local policy_options = options
        if features.chain then
            policy_options = {}
            for key, value in pairs(options or {}) do
                policy_options[key] = value
            end
            policy_options.compatibility = "chain"
            policy_options.require_chain_prefix = true
            policy_options.allow_chain_multicast = chainMulticastEnabled(options)
        end
        for _, entry in ipairs(entries or {}) do
            local policy = launch_modifier_policy.inspectPayloadEntry(plan, ir, entry, policy_options)
            if policy.ok ~= true then
                return policy.rejection_reason or "payload_modifier_combo_deferred"
            end
        end
    end
    if features.pattern and not features.multicast then
        return "payload_pattern_fanout_missing"
    end
    if features.multicast and not payloadMulticastEnabled(options) then
        return "payload_multicast_disabled"
    end
    if features.pattern and not payloadPatternEnabled(options) then
        return "payload_pattern_disabled"
    end
    if features.multicast and #entries > max_fanout then
        return "payload_multicast_fanout_cap_exceeded"
    end
    if features.multicast and #entries + 1 > max_projectiles then
        return "payload_multicast_projectile_cap_exceeded"
    end
    return nil
end

local function postfixOnly(entry, opcode)
    local ops = entry and entry.postfix_ops or nil
    return type(ops) == "table" and #ops == 1 and ops[1] and ops[1].opcode == opcode
end

local function postfixKind(entry)
    if postfixOnly(entry, "Trigger") then
        return "Trigger"
    elseif postfixOnly(entry, "Timer") then
        return "Timer"
    end
    return nil
end

local function maxLiveNestedDepth(options)
    return tonumber(options and options.max_live_nested_continuation_depth)
        or tonumber(limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH)
        or 3
end

local function maxNestedContinuationJobs(options)
    return tonumber(options and options.max_nested_continuation_jobs_per_cast)
        or tonumber(options and options.max_nested_payload_jobs)
        or tonumber(limits.MAX_NESTED_CONTINUATION_JOBS_PER_CAST)
        or tonumber(limits.MAX_NESTED_PAYLOAD_JOBS)
        or 32
end

local function maxNestedFinalPayloadJobs(options)
    return tonumber(options and options.max_nested_final_payload_jobs_per_cast)
        or tonumber(options and options.max_nested_payload_jobs)
        or tonumber(limits.MAX_NESTED_FINAL_PAYLOAD_JOBS_PER_CAST)
        or tonumber(limits.MAX_NESTED_PAYLOAD_JOBS)
        or 32
end

local function mergeNestedStats(target, source)
    target.continuation_jobs = target.continuation_jobs + (source.continuation_jobs or 0)
    target.final_jobs = target.final_jobs + (source.final_jobs or 0)
    target.max_final_depth = math.max(target.max_final_depth or 0, source.max_final_depth or 0)
    for _, slot_id in ipairs(source.final_payload_slot_ids or {}) do
        target.final_payload_slot_ids[#target.final_payload_slot_ids + 1] = slot_id
    end
    for _, helper_engine_id in ipairs(source.final_payload_helper_engine_ids or {}) do
        target.final_payload_helper_engine_ids[#target.final_payload_helper_engine_ids + 1] = helper_engine_id
    end
    local features = source.final_payload_features or {}
    for key, value in pairs(features) do
        if key ~= "pattern_kind" then
            target.final_payload_features[key] = target.final_payload_features[key] or value == true
        end
    end
    if features.pattern_kind and target.final_payload_features.pattern_kind == nil then
        target.final_payload_features.pattern_kind = features.pattern_kind
    end
end

local function nestedTreeStats(plan, ir, entries, options, visited)
    local stats = {
        continuation_jobs = 0,
        final_jobs = 0,
        max_final_depth = 0,
        final_payload_slot_ids = {},
        final_payload_helper_engine_ids = {},
        final_payload_features = {
            multicast = false,
            pattern = false,
            pattern_kind = nil,
            chain = false,
            homing = false,
            speed_plus = false,
            size_plus = false,
            detonate = false,
        },
    }
    local max_depth = maxLiveNestedDepth(options)
    local seen = visited or {}
    for _, entry in ipairs(entries or {}) do
        local depth = tonumber(entry and entry.payload_depth) or 0
        if depth > max_depth then
            return nil, "nested_depth_exceeded"
        end
        if countOpcode(entry and entry.prefix_ops or {}, "Chain") > 1 then
            return nil, "chain_recursion_unsupported"
        end
        if countOpcode(entry and entry.prefix_ops or {}, "Homing") > 1 then
            return nil, "homing_recursion_unsupported"
        end

        local nested_kind = postfixKind(entry)
        if nested_kind == "Trigger" or nested_kind == "Timer" then
            if depth >= max_depth then
                return nil, "nested_depth_exceeded"
            end
            local visit_key = tostring(entry.slot_id) .. "|" .. tostring(nested_kind)
            if seen[visit_key] then
                return nil, "nested_recursion_unsupported"
            end
            local nested_continuation = continuationBySourceKind(ir, entry.slot_id, nested_kind)
            if not nested_continuation then
                return nil, "payload_missing"
            end
            local child_entries = entriesForContinuation(ir, nested_continuation)
            if #child_entries == 0 then
                return nil, "payload_missing"
            end
            local child_features = payloadFeatures(child_entries)
            local child_reason = validatePayloadSet(plan, ir, child_entries, child_features, options)
            if child_reason then
                return nil, child_reason
            end
            seen[visit_key] = true
            local child_stats, child_stats_reason = nestedTreeStats(plan, ir, child_entries, options, seen)
            seen[visit_key] = nil
            if not child_stats then
                return nil, child_stats_reason
            end
            stats.continuation_jobs = stats.continuation_jobs + 1
            mergeNestedStats(stats, child_stats)
        else
            local final_features = payloadFeatures({ entry })
            stats.final_jobs = stats.final_jobs + 1
            stats.max_final_depth = math.max(stats.max_final_depth, depth)
            stats.final_payload_slot_ids[#stats.final_payload_slot_ids + 1] = entry.slot_id
            stats.final_payload_helper_engine_ids[#stats.final_payload_helper_engine_ids + 1] = entry.helper_engine_id
            stats.final_payload_features.multicast = stats.final_payload_features.multicast or final_features.multicast == true
            stats.final_payload_features.pattern = stats.final_payload_features.pattern or final_features.pattern == true
            stats.final_payload_features.pattern_kind = stats.final_payload_features.pattern_kind or final_features.pattern_kind
            stats.final_payload_features.chain = stats.final_payload_features.chain or final_features.chain == true
            stats.final_payload_features.homing = stats.final_payload_features.homing or final_features.homing == true
            stats.final_payload_features.speed_plus = stats.final_payload_features.speed_plus or final_features.speed_plus == true
            stats.final_payload_features.size_plus = stats.final_payload_features.size_plus or final_features.size_plus == true
            stats.final_payload_features.detonate = stats.final_payload_features.detonate or final_features.detonate == true
        end
    end
    return stats, nil
end

local function validateNestedContinuation(plan, ir, source_entry, continuation, payload_entries, features, options, root_kind)
    if options.allow_nested_trigger_timer ~= true then
        return false, "nested_payload_runtime_deferred", nil
    end
    if features.chain then
        return false, "chain_recursion_unsupported", nil
    elseif features.pierce then
        return false, "nested_recursion_unsupported", nil
    end

    local intermediate_entry = payload_entries[1]
    local nested_kind = postfixKind(intermediate_entry)
    if nested_kind ~= "Trigger" and nested_kind ~= "Timer" then
        return false, "nested_payload_runtime_deferred", nil
    end

    local max_depth = maxLiveNestedDepth(options)
    local intermediate_depth = tonumber(intermediate_entry.payload_depth)
        or ((source_entry and tonumber(source_entry.payload_depth) or 0) + 1)
    if intermediate_depth > max_depth then
        return false, "nested_depth_exceeded", nil
    end

    local final_options = {}
    for key, value in pairs(options or {}) do
        final_options[key] = value
    end
    final_options.allow_nested_trigger_timer = true
    final_options.allow_nested_final_fanout = true
    final_options.allow_nested_payload_modifiers = true
    final_options.allow_payload_detonate = true
    final_options.allow_nested_payload_homing = true

    local stats, stats_reason = nestedTreeStats(plan, ir, payload_entries, final_options, {})
    if not stats then
        return false, stats_reason or "nested_payload_runtime_deferred", nil
    end

    local nested_job_budget = tonumber(stats.continuation_jobs) or 0
    if nested_job_budget > maxNestedContinuationJobs(final_options) then
        return false, "nested_continuation_budget_exceeded", nil
    end
    if (tonumber(stats.final_jobs) or 0) > maxNestedFinalPayloadJobs(final_options) then
        return false, "nested_final_payload_budget_exceeded", nil
    end

    local root_slot_id = source_entry and source_entry.slot_id or nil
    return true, nil, {
        nested_trigger_timer = true,
        nested_continuation_kind = string.lower(tostring(root_kind)) .. "_" .. string.lower(tostring(nested_kind)),
        nested_depth = intermediate_depth,
        nested_root_slot_id = root_slot_id,
        nested_parent_slot_id = root_slot_id,
        nested_parent_continuation_id = continuation and continuation.continuation_id or nil,
        nested_continuation_id = nil,
        nested_final_payload_count = stats.final_jobs,
        nested_final_payload_slot_ids = stats.final_payload_slot_ids,
        nested_final_payload_helper_engine_ids = stats.final_payload_helper_engine_ids,
        nested_final_payload_features = stats.final_payload_features,
    }
end

local function findRootPostfixContinuation(ir, kind)
    for _, continuation in ipairs(ir and ir.continuations or {}) do
        if continuation.kind == kind then
            local source = entryBySlot(ir, continuation.source_slot_id)
            if source and (source.payload_depth or 0) == 0 then
                return continuation, source
            end
        end
    end
    return nil, nil
end

local function planPostfixEvent(plan, ir, event, kind, opts)
    local options = opts or {}
    local source_entry = entryBySlot(ir, event and event.source_slot_id)
    local continuation = nil
    if source_entry then
        continuation = continuationBySourceKind(ir, source_entry.slot_id, kind)
    else
        continuation, source_entry = findRootPostfixContinuation(ir, kind)
    end
    if not source_entry then
        return reject(plan, ir, event, nil, nil, kind == "Trigger" and "missing_trigger_source_slot" or "missing_timer_source_slot")
    end
    if not continuation then
        return reject(plan, ir, event, source_entry, nil, kind == "Trigger" and "source_not_trigger" or "source_not_timer")
    end
    if hasOpcode(source_entry.prefix_ops, "Homing") then
        local source_homing = homing_launch_policy.inspectSourceEntry(plan, ir, source_entry, {
            allow_source_homing = options.allow_source_homing == true,
            allow_homing = options.allow_homing == true,
            force_homing_enabled = options.force_homing_enabled,
            force_homing_disabled = options.force_homing_disabled,
            homing_enabled = options.homing_enabled == true,
            max_homing_fanout_per_cast = options.max_homing_fanout_per_cast,
            max_homing_target_scans_per_cast = options.max_homing_target_scans_per_cast,
            quiet = options.quiet_homing_policy == true,
        })
        if source_homing.ok ~= true then
            return reject(plan, ir, event, source_entry, continuation, source_homing.rejection_reason or "homing_nested_runtime_deferred")
        end
    end

    local payload_entries = entriesForContinuation(ir, continuation)
    local features = payloadFeatures(payload_entries)
    local payload_reason = validatePayloadSet(plan, ir, payload_entries, features, options)
    local nested_extra = nil
    if payload_reason then
        if payload_reason == "nested_payload_runtime_deferred" then
            local nested_ok, nested_reason, nested_metadata = validateNestedContinuation(
                plan,
                ir,
                source_entry,
                continuation,
                payload_entries,
                features,
                options,
                kind
            )
            if nested_ok then
                nested_extra = nested_metadata
                payload_reason = nil
            else
                payload_reason = nested_reason or payload_reason
            end
        end
    end
    if payload_reason == nil and features.nested_postfix and nested_extra == nil then
        local nested_ok, nested_reason, nested_metadata = validateNestedContinuation(
            plan,
            ir,
            source_entry,
            continuation,
            payload_entries,
            features,
            options,
            kind
        )
        if nested_ok then
            nested_extra = nested_metadata
            payload_reason = nil
        else
            payload_reason = nested_reason or "nested_payload_runtime_deferred"
        end
    end
    if payload_reason then
        return reject(plan, ir, event, source_entry, continuation, payload_reason)
    end

    local job_kind = kind == "Trigger" and "trigger_payload_launch" or "timer_payload_launch"
    local branch_kind = kind == "Trigger" and "trigger_payload" or "timer_payload"
    if features.chain then
        job_kind = "chain_handoff"
        branch_kind = string.lower(kind) .. "_chain_payload"
    elseif features.pattern then
        branch_kind = branch_kind .. "_pattern"
    elseif features.multicast then
        branch_kind = branch_kind .. "_multicast"
    elseif features.nested_postfix then
        job_kind = kind == "Trigger" and "trigger_nested_continuation" or "timer_nested_continuation"
        branch_kind = string.lower(kind) .. "_nested_continuation"
    end

    return success(plan, ir, event, source_entry, continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, job_kind, branch_kind, nested_extra), {
        nested_trigger_timer = features.nested_postfix == true,
        nested_continuation_kind = nested_extra and nested_extra.nested_continuation_kind or nil,
        nested_depth = nested_extra and nested_extra.nested_depth or nil,
        nested_root_slot_id = nested_extra and nested_extra.nested_root_slot_id or nil,
        nested_parent_slot_id = nested_extra and nested_extra.nested_parent_slot_id or nil,
        nested_parent_continuation_id = nested_extra and nested_extra.nested_parent_continuation_id or nil,
        nested_continuation_id = nested_extra and nested_extra.nested_continuation_id or nil,
        nested_final_payload_count = nested_extra and nested_extra.nested_final_payload_count or nil,
        nested_final_payload_slot_ids = nested_extra and nested_extra.nested_final_payload_slot_ids or nil,
        nested_final_payload_helper_engine_ids = nested_extra and nested_extra.nested_final_payload_helper_engine_ids or nil,
        nested_final_payload_features = nested_extra and nested_extra.nested_final_payload_features or nil,
        chain_shape = features.chain and "trigger_payload_chain" or nil,
    })
end

local function sourceHasOnlyBounce(entry)
    local prefix = entry and entry.prefix_ops or {}
    local bounce_count = countOpcode(prefix, "Bounce")
    return bounce_count == 1 and #prefix == 1
end

local function sourceHasLaunchModifier(entry)
    return hasOpcode(entry and entry.prefix_ops or nil, "Speed+")
        or hasOpcode(entry and entry.prefix_ops or nil, "Size+")
end

local function sourceModifierPolicyOptions(options, source_kind)
    local opts = {
        policy_kind = "source",
        apply_size_to_specs = false,
        allow_bounce_source = source_kind == "bounce",
        allow_pierce_source = source_kind == "pierce",
        force_speed_plus_enabled = options and options.force_speed_plus_enabled,
        force_speed_plus_disabled = options and options.force_speed_plus_disabled,
        speed_plus_enabled = options and options.speed_plus_enabled == true,
        force_size_plus_enabled = options and options.force_size_plus_enabled,
        force_size_plus_disabled = options and options.force_size_plus_disabled,
        size_plus_enabled = options and options.size_plus_enabled == true,
    }
    return opts
end

local function sourceHasEventSourceFanout(entry, opcode)
    local prefix = entry and entry.prefix_ops or {}
    return countOpcode(prefix, opcode) == 1
        and (hasOpcode(prefix, "Multicast")
            or hasOpcode(prefix, "Spread")
            or hasOpcode(prefix, "Burst"))
end

local function validateSourceLaunchModifier(plan, ir, source_entry, options, source_kind)
    if not sourceHasLaunchModifier(source_entry) then
        return nil
    end
    local policy_options = sourceModifierPolicyOptions(options, source_kind)
    local source_opcode = source_kind == "bounce" and "Bounce" or source_kind == "pierce" and "Pierce" or nil
    if source_opcode and sourceHasEventSourceFanout(source_entry, source_opcode) then
        policy_options.allow_event_source_fanout = true
        policy_options.allow_event_source_modifier_combo = true
    end
    local policy = launch_modifier_policy.inspectSourceEntry(
        plan,
        ir,
        source_entry,
        policy_options
    )
    if policy.ok ~= true then
        return policy.rejection_reason or "source_modifier_unsupported_prefix"
    end
    return nil
end

local function firstBounceContinuation(ir)
    local continuation = firstContinuation(ir, "Bounce")
    return continuation, continuation and entryBySlot(ir, continuation.source_slot_id) or nil
end

local function hasDirectBounceChain(ir, bounce_source_slot_id)
    for _, entry in ipairs(ir and ir.entries or {}) do
        if hasOpcode(entry.prefix_ops, "Chain")
            and not (entry.parent_slot_id == bounce_source_slot_id and entry.source_postfix_opcode == "Trigger") then
            return true
        end
    end
    return false
end

local function validateBounceSource(plan, ir, event, source_entry, bounce_continuation, options)
    if not source_entry then
        return "missing_bounce_source_slot"
    end
    local bounce_count, bounce_op = countOpcode(source_entry.prefix_ops, "Bounce")
    if bounce_count ~= 1 then
        return "source_slot_not_bounce"
    end
    local source_modifier_reason = validateSourceLaunchModifier(plan, ir, source_entry, options, "bounce")
    if source_modifier_reason then
        return source_modifier_reason
    end
    if hasOpcode(source_entry.prefix_ops, "Chain") or hasDirectBounceChain(ir, source_entry.slot_id) then
        return "bounce_chain_deferred"
    end
    if hasOpcode(source_entry.prefix_ops, "Homing") then
        return "homing_bounce_physics_unsupported"
    end
    if not sourceHasLaunchModifier(source_entry)
        and not sourceHasOnlyBounce(source_entry)
        and not sourceHasEventSourceFanout(source_entry, "Bounce") then
        return "bounce_prefix_combo_deferred"
    end
    if hasOpcode(source_entry.postfix_ops, "Timer") then
        return "bounce_timer_deferred"
    end
    if hasOpcode(source_entry.postfix_ops, "Homing") then
        return "homing_bounce_physics_unsupported"
    end
    if hasOpcode(source_entry.postfix_ops, "Trigger") and not postfixOnly(source_entry, "Trigger") then
        return "bounce_postfix_deferred"
    end
    if #(source_entry.postfix_ops or {}) > 0 and not postfixOnly(source_entry, "Trigger") then
        return "bounce_postfix_deferred"
    end
    local bounce_max = clampPositiveInteger(bounce_op and bounce_op.params and bounce_op.params.bounces, 1, limits.MAX_BOUNCE_COUNT_HARD)
    local cap = tonumber(options.max_bounce_count) or limits.MAX_BOUNCE_COUNT
    if bounce_max > cap then
        return "bounce_count_cap_exceeded"
    end
    return nil
end

local function planBounceEvent(plan, ir, event, opts)
    local options = opts or {}
    local bounce_continuation = nil
    local source_entry = entryBySlot(ir, event and event.source_slot_id)
    if source_entry then
        bounce_continuation = continuationBySourceKind(ir, source_entry.slot_id, "Bounce")
    else
        bounce_continuation, source_entry = firstBounceContinuation(ir)
    end
    local source_reason = validateBounceSource(plan, ir, event, source_entry, bounce_continuation, options)
    if source_reason then
        return reject(plan, ir, event, source_entry, bounce_continuation, source_reason)
    end

    local has_trigger = postfixOnly(source_entry, "Trigger")
    if not has_trigger then
        local _, bounce_op = countOpcode(source_entry.prefix_ops, "Bounce")
        return success(plan, ir, event, source_entry, bounce_continuation, {}, {
            multicast = false,
            pattern = false,
            chain = false,
        }, {}, {
            bounce_mode = "source_only",
            bounce_max = clampPositiveInteger(bounce_op and bounce_op.params and bounce_op.params.bounces, 1, limits.MAX_BOUNCE_COUNT_HARD),
        })
    end

    local trigger_continuation = continuationBySourceKind(ir, source_entry.slot_id, "Trigger")
    if not trigger_continuation then
        return reject(plan, ir, event, source_entry, bounce_continuation, "source_trigger_binding_missing")
    end
    local payload_entries = entriesForContinuation(ir, trigger_continuation)
    local features = payloadFeatures(payload_entries)
    if features.chain then
        if #payload_entries ~= 1 then
            return reject(plan, ir, event, source_entry, trigger_continuation, "bounce_fanout_deferred")
        end
        if features.multicast or features.pattern then
            return reject(plan, ir, event, source_entry, trigger_continuation, "bounce_fanout_deferred")
        end
        if features.speed_plus or features.size_plus then
            return reject(plan, ir, event, source_entry, trigger_continuation, "bounce_chain_modifier_deferred")
        end
        if features.nested_postfix then
            return reject(plan, ir, event, source_entry, trigger_continuation, "chain_trigger_timer_deferred")
        end
        return success(plan, ir, event, source_entry, trigger_continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, "chain_handoff", "bounce_trigger_chain_payload"), {
            bounce_mode = "trigger_payload",
            chain_shape = "trigger_payload_chain",
        })
    end

    local payload_reason = validatePayloadSet(plan, ir, payload_entries, features, options)
    if payload_reason then
        return reject(plan, ir, event, source_entry, trigger_continuation, payload_reason)
    end
    local branch_kind = "bounce_trigger_payload"
    if features.pattern then
        branch_kind = "bounce_trigger_payload_pattern"
    elseif features.multicast then
        branch_kind = "bounce_trigger_payload_multicast"
    end
    return success(plan, ir, event, source_entry, trigger_continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, "bounce_trigger_payload_launch", branch_kind), {
        bounce_mode = "trigger_payload",
    })
end

local function sourceHasOnlyPierce(entry)
    local prefix = entry and entry.prefix_ops or {}
    local pierce_count = countOpcode(prefix, "Pierce")
    return pierce_count == 1 and #prefix == 1
end

local function firstPierceContinuation(ir)
    local continuation = firstContinuation(ir, "Pierce")
    return continuation, continuation and entryBySlot(ir, continuation.source_slot_id) or nil
end

local function hasDirectPierceChain(ir, pierce_source_slot_id)
    for _, entry in ipairs(ir and ir.entries or {}) do
        if hasOpcode(entry.prefix_ops, "Chain")
            and not (entry.parent_slot_id == pierce_source_slot_id and entry.source_postfix_opcode == "Trigger") then
            return true
        end
    end
    return false
end

local function validatePierceSource(plan, ir, event, source_entry, pierce_continuation, options)
    if not source_entry then
        return "missing_pierce_source_slot"
    end
    local pierce_count, pierce_op = countOpcode(source_entry.prefix_ops, "Pierce")
    if pierce_count ~= 1 then
        return "source_slot_not_pierce"
    end
    local source_modifier_reason = validateSourceLaunchModifier(plan, ir, source_entry, options, "pierce")
    if source_modifier_reason then
        return source_modifier_reason
    end
    if hasOpcode(source_entry.prefix_ops, "Bounce") then
        return "pierce_bounce_deferred"
    end
    if hasOpcode(source_entry.prefix_ops, "Chain") or hasDirectPierceChain(ir, source_entry.slot_id) then
        return "pierce_chain_deferred"
    end
    if hasOpcode(source_entry.prefix_ops, "Homing") then
        return "homing_pierce_physics_unsupported"
    end
    if not sourceHasLaunchModifier(source_entry)
        and not sourceHasOnlyPierce(source_entry)
        and not sourceHasEventSourceFanout(source_entry, "Pierce") then
        return "pierce_modifier_deferred"
    end
    if hasOpcode(source_entry.postfix_ops, "Timer") then
        return "pierce_timer_deferred"
    end
    if hasOpcode(source_entry.postfix_ops, "Homing") then
        return "homing_pierce_physics_unsupported"
    end
    if hasOpcode(source_entry.postfix_ops, "Trigger") and not postfixOnly(source_entry, "Trigger") then
        return "pierce_nested_payload_deferred"
    end
    if #(source_entry.postfix_ops or {}) > 0 and not postfixOnly(source_entry, "Trigger") then
        return "pierce_nested_payload_deferred"
    end
    local pierce_limit = clampPositiveInteger(pierce_op and pierce_op.params and pierce_op.params.pierces, 1, limits.MAX_PIERCE_COUNT_HARD)
    local cap = tonumber(options.max_pierce_count) or limits.MAX_PIERCE_COUNT
    if pierce_limit > cap then
        return "pierce_count_cap_exceeded"
    end
    return nil
end

local function planPierceEvent(plan, ir, event, opts)
    local options = opts or {}
    local pierce_continuation = nil
    local source_entry = entryBySlot(ir, event and event.source_slot_id)
    if source_entry then
        pierce_continuation = continuationBySourceKind(ir, source_entry.slot_id, "Pierce")
    else
        pierce_continuation, source_entry = firstPierceContinuation(ir)
    end
    local source_reason = validatePierceSource(plan, ir, event, source_entry, pierce_continuation, options)
    if source_reason then
        return reject(plan, ir, event, source_entry, pierce_continuation, source_reason)
    end

    local _, pierce_op = countOpcode(source_entry.prefix_ops, "Pierce")
    local pierce_limit = clampPositiveInteger(pierce_op and pierce_op.params and pierce_op.params.pierces, 1, limits.MAX_PIERCE_COUNT_HARD)
    local has_trigger = postfixOnly(source_entry, "Trigger")
    if not has_trigger then
        return success(plan, ir, event, source_entry, pierce_continuation, {}, {
            multicast = false,
            pattern = false,
            chain = false,
        }, {}, {
            pierce_mode = "source_only",
            pierce_limit = pierce_limit,
        })
    end

    local trigger_continuation = continuationBySourceKind(ir, source_entry.slot_id, "Trigger")
    if not trigger_continuation then
        return reject(plan, ir, event, source_entry, pierce_continuation, "source_trigger_binding_missing")
    end
    local payload_entries = entriesForContinuation(ir, trigger_continuation)
    local features = payloadFeatures(payload_entries)
    if features.chain then
        if #payload_entries ~= 1 then
            return reject(plan, ir, event, source_entry, trigger_continuation, "pierce_fanout_deferred")
        end
        if features.multicast or features.pattern then
            return reject(plan, ir, event, source_entry, trigger_continuation, "pierce_fanout_deferred")
        end
        if features.speed_plus or features.size_plus then
            return reject(plan, ir, event, source_entry, trigger_continuation, "pierce_modifier_deferred")
        end
        if features.nested_postfix then
            return reject(plan, ir, event, source_entry, trigger_continuation, "pierce_nested_payload_deferred")
        end
        local _, chain_op = countOpcode(payload_entries[1] and payload_entries[1].prefix_ops or {}, "Chain")
        local requested_hops = clampPositiveInteger(chain_op and chain_op.params and chain_op.params.hops, 1, nil)
        local max_hops = tonumber(options.max_hops) or limits.MAX_CHAIN_HOPS
        if requested_hops > max_hops then
            return reject(plan, ir, event, source_entry, trigger_continuation, "chain_hop_cap_exceeded")
        end
        return success(plan, ir, event, source_entry, trigger_continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, "chain_handoff", "pierce_trigger_chain_payload"), {
            pierce_mode = "trigger_payload",
            pierce_limit = pierce_limit,
            chain_shape = "trigger_payload_chain",
            requested_hops = requested_hops,
            max_hops = math.min(requested_hops, max_hops),
        })
    end

    local payload_reason = validatePayloadSet(plan, ir, payload_entries, features, options)
    if payload_reason == "nested_payload_runtime_deferred" then
        payload_reason = "pierce_nested_payload_deferred"
    end
    if payload_reason then
        return reject(plan, ir, event, source_entry, trigger_continuation, payload_reason)
    end
    local branch_kind = "pierce_trigger_payload"
    if features.pattern then
        branch_kind = "pierce_trigger_payload_pattern"
    elseif features.multicast then
        branch_kind = "pierce_trigger_payload_multicast"
    end
    return success(plan, ir, event, source_entry, trigger_continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, "pierce_trigger_payload_launch", branch_kind), {
        pierce_mode = "trigger_payload",
        pierce_limit = pierce_limit,
    })
end

local function sortedChainEntries(ir)
    local entries = {}
    for _, entry in ipairs(ir and ir.entries or {}) do
        if hasOpcode(entry.prefix_ops, "Chain") then
            entries[#entries + 1] = entry
        end
    end
    table.sort(entries, function(a, b)
        local ag = tonumber(a.group_index) or 0
        local bg = tonumber(b.group_index) or 0
        if ag ~= bg then
            return ag < bg
        end
        local ae = tonumber(a.emission_index) or 0
        local be = tonumber(b.emission_index) or 0
        if ae ~= be then
            return ae < be
        end
        return tostring(a.slot_id) < tostring(b.slot_id)
    end)
    return entries
end

local function previousPrimaryEntry(ir, chain_entry)
    local previous = nil
    for _, entry in ipairs(ir and ir.entries or {}) do
        if entry.slot_id == chain_entry.slot_id then
            return previous
        end
        if entry.kind == "primary_emission" and entry.parent_slot_id == nil then
            previous = entry
        end
    end
    return nil
end

local function chainPayloadEntries(ir, first_entry, chain_entries, options)
    local has_multicast = hasOpcode(first_entry.prefix_ops, "Multicast") or #chain_entries > 1
    local has_pattern = hasOpcode(first_entry.prefix_ops, "Spread") or hasOpcode(first_entry.prefix_ops, "Burst")
    if not has_multicast then
        return { first_entry }, nil
    end
    if not chainMulticastEnabled(options) then
        return nil, "chain_multicast_disabled"
    end
    local cap = has_pattern
        and (tonumber(options.max_chain_pattern_fanout)
            or tonumber(options.max_chain_multicast_fanout)
            or limits.MAX_CHAIN_PATTERN_FANOUT)
        or (tonumber(options.max_chain_multicast_fanout) or limits.MAX_CHAIN_MULTICAST_FANOUT)
    if #chain_entries > cap then
        return nil, has_pattern and "chain_pattern_fanout_cap_exceeded" or "chain_multicast_fanout_cap_exceeded"
    end
    return chain_entries, nil
end

local function chainSideContinuationKind(entry)
    local has_trigger = hasOpcode(entry and entry.postfix_ops or nil, "Trigger")
    local has_timer = hasOpcode(entry and entry.postfix_ops or nil, "Timer")
    if has_trigger and has_timer then
        return nil, "chain_nested_payload_deferred"
    end
    if has_trigger then
        return "Trigger", nil
    end
    if has_timer then
        return "Timer", nil
    end
    return nil, nil
end

local function validateChainSideContinuation(plan, ir, first_entry, side_kind, requested_hops, chain_fanout_count, options)
    if side_kind == nil then
        return nil, nil
    end
    if options.allow_chain_event_continuation ~= true then
        return nil, "chain_trigger_timer_deferred"
    end
    local side_continuation = continuationBySourceKind(ir, first_entry.slot_id, side_kind)
    if not side_continuation then
        return nil, "chain_nested_payload_deferred"
    end
    local side_payload_entries = entriesForContinuation(ir, side_continuation)
    local side_features = payloadFeatures(side_payload_entries)
    if side_features.chain then
        return nil, "chain_event_payload_chain_deferred"
    end
    if side_features.nested_postfix then
        return nil, "chain_nested_payload_deferred"
    end
    local side_reason = validatePayloadSet(plan, ir, side_payload_entries, side_features, options)
    if side_reason then
        return nil, side_reason
    end
    local side_payload_count = #side_payload_entries
    local budget = (tonumber(requested_hops) or 0)
        * math.max(1, tonumber(chain_fanout_count) or 1)
        * math.max(1, side_payload_count)
    local cap = tonumber(options.max_chain_event_continuation_jobs)
        or (side_kind == "Trigger"
            and tonumber(options.max_chain_trigger_side_payload_jobs or limits.MAX_CHAIN_TRIGGER_SIDE_PAYLOAD_JOBS_PER_CAST)
            or tonumber(options.max_chain_timer_side_payload_jobs or limits.MAX_CHAIN_TIMER_SIDE_PAYLOAD_JOBS_PER_CAST))
        or limits.MAX_CHAIN_EVENT_CONTINUATION_JOBS_PER_CAST
    if budget > cap then
        return nil, side_kind == "Trigger"
            and "chain_trigger_side_payload_budget_exceeded"
            or "chain_timer_side_payload_budget_exceeded"
    end
    return {
        kind = side_kind,
        continuation = side_continuation,
        continuation_id = side_continuation.continuation_id,
        payload_entries = side_payload_entries,
        payload_count = side_payload_count,
        payload_slot_ids = payloadSlotIds(side_payload_entries),
        payload_helper_engine_ids = payloadHelperEngineIds(side_payload_entries),
        payload_features = side_features,
        budget = budget,
        budget_cap = cap,
    }, nil
end

local function planChainEvent(plan, ir, event, opts)
    local options = opts or {}
    local chain_entries = sortedChainEntries(ir)
    if #chain_entries == 0 then
        return reject(plan, ir, event, nil, nil, "no_chain")
    end
    local first_entry = chain_entries[1]
    local chain_continuation = continuationBySourceKind(ir, first_entry.slot_id, "Chain")
    local chain_count, chain_op = countOpcode(first_entry.prefix_ops, "Chain")
    if chain_count ~= 1 then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_recursion_deferred")
    end
    if #chain_entries > 1 and not hasOpcode(first_entry.prefix_ops, "Multicast") then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_recursion_deferred")
    end
    local side_kind, side_kind_reason = chainSideContinuationKind(first_entry)
    if side_kind_reason then
        return reject(plan, ir, event, first_entry, chain_continuation, side_kind_reason)
    end
    if (side_kind ~= nil or hasPayloadBindings(first_entry))
        and side_kind == nil then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_trigger_timer_deferred")
    end
    if side_kind ~= nil and options.allow_chain_event_continuation ~= true then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_trigger_timer_deferred")
    end
    if first_entry.payload_depth and first_entry.payload_depth >= 2 then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_nested_payload_deferred")
    end
    local source_entry = nil
    local chain_shape = nil
    if first_entry.parent_slot_id == nil then
        source_entry = previousPrimaryEntry(ir, first_entry)
        if not source_entry then
            source_entry = first_entry
        end
        chain_shape = "source_chain_payload"
    elseif first_entry.source_postfix_opcode == "Trigger" then
        source_entry = entryBySlot(ir, first_entry.parent_slot_id)
        chain_shape = "trigger_payload_chain"
    elseif first_entry.source_postfix_opcode == "Timer" then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_timer_context_deferred")
    end
    if not source_entry then
        return reject(plan, ir, event, first_entry, chain_continuation, "chain_source_missing")
    end

    local requested_hops = clampPositiveInteger(chain_op and chain_op.params and chain_op.params.hops, 1, nil)
    local max_hops = tonumber(options.max_hops) or limits.MAX_CHAIN_HOPS
    if requested_hops > max_hops then
        return reject(plan, ir, event, source_entry, chain_continuation, "chain_hop_cap_exceeded")
    end

    local payload_entries, payload_reason = chainPayloadEntries(ir, first_entry, chain_entries, options)
    if payload_reason then
        return reject(plan, ir, event, source_entry, chain_continuation, payload_reason)
    end
    local features = payloadFeatures(payload_entries)
    features.chain = true
    if features.pattern_ambiguous then
        return reject(plan, ir, event, source_entry, chain_continuation, "chain_pattern_disabled")
    end
    if features.pattern then
        if not features.multicast then
            return reject(plan, ir, event, source_entry, chain_continuation, "chain_pattern_disabled")
        end
        if not payloadPatternEnabled(options) then
            return reject(plan, ir, event, source_entry, chain_continuation, "chain_pattern_disabled")
        end
    end
    if features.speed_plus or features.size_plus then
        for _, entry in ipairs(payload_entries or {}) do
            local policy = launch_modifier_policy.inspectPayloadEntry(plan, ir, entry, {
                compatibility = "chain",
                require_chain_prefix = true,
                allow_chain_multicast = chainMulticastEnabled(options),
                force_chain_multicast_enabled = options.force_chain_multicast_enabled,
                force_chain_multicast_disabled = options.force_chain_multicast_disabled,
                chain_multicast_enabled = options.chain_multicast_enabled == true,
                max_chain_multicast_fanout = options.max_chain_multicast_fanout,
                allow_nested_payload_modifiers = side_kind ~= nil and options.allow_chain_event_continuation == true,
                force_speed_plus_enabled = options.force_speed_plus_enabled,
                force_speed_plus_disabled = options.force_speed_plus_disabled,
                speed_plus_enabled = options.speed_plus_enabled == true,
                force_size_plus_enabled = options.force_size_plus_enabled,
                force_size_plus_disabled = options.force_size_plus_disabled,
                size_plus_enabled = options.size_plus_enabled == true,
            })
            if policy.ok ~= true then
                return reject(plan, ir, event, source_entry, chain_continuation, policy.rejection_reason or "chain_payload_modifier_deferred")
            end
        end
    end
    local jobs_per_hop = #payload_entries
    local max_jobs = tonumber(options.max_jobs)
        or (features.pattern and limits.MAX_CHAIN_PATTERN_JOBS_PER_CAST_DEFAULT)
        or limits.MAX_CHAIN_JOBS_PER_CAST
    if requested_hops * jobs_per_hop > max_jobs then
        return reject(plan, ir, event, source_entry, chain_continuation, features.pattern and "chain_pattern_jobs_cap_exceeded" or "chain_job_cap_exceeded")
    end
    local side_info, side_reason = validateChainSideContinuation(
        plan,
        ir,
        first_entry,
        side_kind,
        requested_hops,
        #payload_entries,
        options
    )
    if side_reason then
        return reject(plan, ir, event, source_entry, chain_continuation, side_reason)
    end

    local branch_kind = features.pattern and "chain_payload_pattern"
        or features.multicast and "chain_payload_multicast"
        or "chain_payload"
    if side_info and side_info.kind == "Trigger" then
        branch_kind = branch_kind .. "_trigger"
    elseif side_info and side_info.kind == "Timer" then
        branch_kind = branch_kind .. "_timer"
    end
    return success(plan, ir, event, source_entry, chain_continuation, payload_entries, features, buildJobs(source_entry, payload_entries, event, "chain_payload_hop", branch_kind), {
        chain_shape = chain_shape,
        requested_hops = requested_hops,
        max_hops = math.min(requested_hops, max_hops),
        has_multicast_payload = features.multicast == true,
        has_pattern_payload = features.pattern == true,
        chain_pattern_kind = features.pattern_kind,
        chain_multicast_fanout_count = #payload_entries,
        chain_event_continuation = side_info ~= nil,
        chain_side_continuation_kind = side_info and side_info.kind or nil,
        chain_side_continuation_id = side_info and side_info.continuation_id or nil,
        chain_side_payload_count = side_info and side_info.payload_count or nil,
        chain_side_payload_slot_ids = side_info and side_info.payload_slot_ids or nil,
        chain_side_payload_helper_engine_ids = side_info and side_info.payload_helper_engine_ids or nil,
        chain_event_continuation_budget = side_info and side_info.budget or nil,
        chain_event_continuation_budget_cap = side_info and side_info.budget_cap or nil,
    })
end

function continuation_planner.planFromEvent(plan, ir, event, opts)
    local options = opts or (event and event.options) or event or {}
    if type(ir) ~= "table" or ir.ok ~= true then
        return reject(plan, ir, event, nil, nil, "runtime_ir_required")
    end
    if type(event) ~= "table" then
        return reject(plan, ir, event, nil, nil, "event_required")
    end
    local event_kind = event.event_kind
    if event_kind == "trigger_hit" then
        return planPostfixEvent(plan, ir, event, "Trigger", options)
    elseif event_kind == "timer_matured" then
        return planPostfixEvent(plan, ir, event, "Timer", options)
    elseif event_kind == "bounce" then
        return planBounceEvent(plan, ir, event, options)
    elseif event_kind == "pierce" then
        return planPierceEvent(plan, ir, event, options)
    elseif event_kind == "chain" or event_kind == "chain_hit" or event_kind == "chain_hop" then
        return planChainEvent(plan, ir, event, options)
    end
    return reject(plan, ir, event, nil, nil, "unsupported_event_kind")
end

return continuation_planner
