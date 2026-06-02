local defs = require("scripts.spellforge.global.feature_matrix_defs")
local feature_matrix_ir = require("scripts.spellforge.global.feature_matrix_ir")
local parser = require("scripts.spellforge.global.parser")
local runtime_ir = require("scripts.spellforge.global.runtime_ir")
local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.feature_matrix")

local feature_matrix = {}

feature_matrix.VERSION = defs.VERSION

local OPCODE_TO_FEATURE = defs.OPCODE_TO_FEATURE
local FEATURE_BY_ID = defs.FEATURE_BY_ID
local FLAG_LIVE_2_2C = defs.FLAGS.LIVE_2_2C
local FLAG_HOMING_V2_MANAGER = defs.FLAGS.HOMING_V2_MANAGER
local FLAG_SOFT_HOMING = defs.FLAGS.SOFT_HOMING

local function cloneArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

local function sortedKeys(set)
    local keys = {}
    for key in pairs(set or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function addSet(set, key)
    if key ~= nil and key ~= "" then
        set[key] = true
    end
end

local function hasSet(set, key)
    return set and set[key] == true
end

local function copySet(set)
    local out = {}
    for key, value in pairs(set or {}) do
        out[key] = value
    end
    return out
end

local function addAll(set, values)
    for _, value in ipairs(values or {}) do
        addSet(set, value)
    end
end

local function contextName(depth)
    if depth <= 0 then
        return "primary"
    elseif depth == 1 then
        return "payload"
    end
    return "nested_payload"
end

local function addFeature(summary, feature_id, depth)
    if not feature_id then
        return
    end
    addSet(summary.active, feature_id)
    addSet(summary.contexts[contextName(depth)], feature_id)
    summary.counts[feature_id] = (summary.counts[feature_id] or 0) + 1
    local previous_depth = summary.min_depth[feature_id]
    if previous_depth == nil or depth < previous_depth then
        summary.min_depth[feature_id] = depth
    end
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op.opcode == opcode then
            return true
        end
    end
    return false
end

local function prefixFeatureForOpcode(opcode, depth)
    if depth > 0 and (opcode == "Multicast" or opcode == "Spread" or opcode == "Burst") then
        return nil
    end
    return OPCODE_TO_FEATURE[opcode]
end

local function firstPostfixOpcode(group)
    for _, op in ipairs(group.postfix_ops or {}) do
        if op.opcode == "Trigger" or op.opcode == "Timer" then
            return op.opcode
        end
    end
    return nil
end

local function groupsHavePrefixOpcode(groups, opcode)
    for _, group in ipairs(groups or {}) do
        if hasOpcode(group.prefix_ops, opcode) then
            return true
        end
    end
    return false
end

local function groupsHavePostfixOpcode(groups, opcode)
    for _, group in ipairs(groups or {}) do
        if hasOpcode(group.postfix_ops, opcode) then
            return true
        end
    end
    return false
end

local function groupsHaveUnsupportedMultiRootSourceModifier(groups)
    for _, group in ipairs(groups or {}) do
        local prefix = group and group.prefix_ops or {}
        if hasOpcode(prefix, "Bounce")
            or hasOpcode(prefix, "Pierce")
            or hasOpcode(prefix, "Homing")
            or hasOpcode(prefix, "Speed+")
            or hasOpcode(prefix, "Size+") then
            return true
        end
    end
    return false
end

local function sourcePostfixOpcode(group)
    if hasOpcode(group and group.postfix_ops or {}, "Trigger") then
        return "Trigger"
    elseif hasOpcode(group and group.postfix_ops or {}, "Timer") then
        return "Timer"
    end
    return nil
end

local function scanGroups(groups, summary, depth, payload_stack, options)
    summary.max_payload_depth = math.max(summary.max_payload_depth, depth)

    for _, group in ipairs(groups or {}) do
        local prefix = group.prefix_ops or {}
        local postfix = group.postfix_ops or {}
        local has_chain = hasOpcode(prefix, "Chain")
        local has_multicast = hasOpcode(prefix, "Multicast")
        local has_pattern = hasOpcode(prefix, "Spread") or hasOpcode(prefix, "Burst")
        local has_speed = hasOpcode(prefix, "Speed+")
        local has_size = hasOpcode(prefix, "Size+")
        local has_bounce = hasOpcode(prefix, "Bounce")
        local has_pierce = hasOpcode(prefix, "Pierce")
        local has_homing = hasOpcode(prefix, "Homing")
        local has_trigger = hasOpcode(postfix, "Trigger")
        local has_timer = hasOpcode(postfix, "Timer")
        local payload_groups = nil
        local has_payload_effects = group.payload and type(group.payload.effects) == "table" and #group.payload.effects > 0

        if has_payload_effects then
            local parsed = parser.parseContinuationPayloadEffectList(group.payload.effects, options)
            if parsed.ok then
                payload_groups = parsed.groups or {}
                log.info(string.format(
                    "SPELLFORGE_FEATURE_MATRIX_PAYLOAD_PARSE_OK recipe_id=%s source_opcode=%s payload_effect_count=%s payload_group_count=%s fanout_context=%s allow_non_target_payload_multicast=%s",
                    tostring(summary.recipe_id),
                    tostring(sourcePostfixOpcode(group)),
                    tostring(#(group.payload.effects or {})),
                    tostring(#payload_groups),
                    tostring(parsed.fanout_context or "continuation_payload"),
                    tostring(parsed.allow_non_target_payload_multicast == true)
                ))
            else
                log.warn(string.format(
                    "SPELLFORGE_FEATURE_MATRIX_PAYLOAD_PARSE_FAILED recipe_id=%s source_opcode=%s payload_effect_count=%s fanout_context=%s allow_non_target_payload_multicast=%s reason=payload_parse_failed",
                    tostring(summary.recipe_id),
                    tostring(sourcePostfixOpcode(group)),
                    tostring(#(group.payload.effects or {})),
                    tostring(parsed.fanout_context or "continuation_payload"),
                    tostring(parsed.allow_non_target_payload_multicast == true)
                ))
            end
        end

        for _, op in ipairs(prefix) do
            addFeature(summary, prefixFeatureForOpcode(op.opcode, depth), depth)
        end
        for _, op in ipairs(postfix) do
            addFeature(summary, OPCODE_TO_FEATURE[op.opcode], depth)
        end

        if has_chain and has_multicast then
            addFeature(summary, "chain_multicast", depth)
            addSet(summary.combos, "chain_multicast")
        end
        if has_chain and has_pattern then
            addSet(summary.combos, "chain_pattern")
        end
        if has_pattern and (depth > 0 or has_chain) then
            addFeature(summary, "payload_pattern", depth)
        end
        if has_multicast and depth > 0 then
            addFeature(summary, "payload_multicast", depth)
        end
        if depth > 0 and (has_trigger or has_timer) then
            addFeature(summary, "nested_trigger_timer", depth)
        end
        if depth >= 2 and (has_multicast or has_pattern) then
            addFeature(summary, "nested_final_fanout", depth)
        end
        if has_bounce then
            addSet(summary.combos, "bounce_source")
            if has_trigger and has_payload_effects then
                addSet(summary.combos, "bounce_trigger_payload")
                if groupsHavePrefixOpcode(payload_groups, "Chain") then
                    addSet(summary.combos, "bounce_trigger_chain")
                    if groupsHavePrefixOpcode(payload_groups, "Multicast")
                        or groupsHavePrefixOpcode(payload_groups, "Spread")
                        or groupsHavePrefixOpcode(payload_groups, "Burst") then
                        addSet(summary.deferred_reasons, "bounce_fanout_deferred")
                    end
                    if groupsHavePrefixOpcode(payload_groups, "Speed+") or groupsHavePrefixOpcode(payload_groups, "Size+") then
                        addSet(summary.deferred_reasons, "bounce_chain_modifier_deferred")
                    end
                end
                if groupsHavePrefixOpcode(payload_groups, "Multicast") then
                    addSet(summary.combos, "bounce_trigger_payload_multicast")
                end
                if groupsHavePrefixOpcode(payload_groups, "Spread") or groupsHavePrefixOpcode(payload_groups, "Burst") then
                    addSet(summary.combos, "bounce_trigger_payload_pattern")
                end
                if groupsHavePostfixOpcode(payload_groups, "Trigger") or groupsHavePostfixOpcode(payload_groups, "Timer") then
                    addSet(summary.deferred_reasons, "nested_payload_runtime_deferred")
                end
            end
        end

        if has_pierce then
            addSet(summary.combos, "pierce_source")
            if has_trigger and has_payload_effects then
                addSet(summary.combos, "pierce_trigger_payload")
                if groupsHavePrefixOpcode(payload_groups, "Chain") then
                    addSet(summary.combos, "pierce_trigger_chain")
                    if groupsHavePrefixOpcode(payload_groups, "Multicast")
                        or groupsHavePrefixOpcode(payload_groups, "Spread")
                        or groupsHavePrefixOpcode(payload_groups, "Burst") then
                        addSet(summary.deferred_reasons, "pierce_fanout_deferred")
                    end
                    if groupsHavePrefixOpcode(payload_groups, "Speed+") or groupsHavePrefixOpcode(payload_groups, "Size+") then
                        addSet(summary.deferred_reasons, "pierce_modifier_deferred")
                    end
                end
                if groupsHavePrefixOpcode(payload_groups, "Multicast") then
                    addSet(summary.combos, "pierce_trigger_payload_multicast")
                end
                if groupsHavePrefixOpcode(payload_groups, "Spread") or groupsHavePrefixOpcode(payload_groups, "Burst") then
                    addSet(summary.combos, "pierce_trigger_payload_pattern")
                end
                if groupsHavePrefixOpcode(payload_groups, "Pierce") then
                    addSet(summary.deferred_reasons, "pierce_recursion_deferred")
                end
                if groupsHavePostfixOpcode(payload_groups, "Trigger")
                    or groupsHavePostfixOpcode(payload_groups, "Timer") then
                    addSet(summary.deferred_reasons, "pierce_nested_payload_deferred")
                end
            end
        end

        if has_chain and has_pattern and not has_multicast then
            addSet(summary.deferred_reasons, "chain_pattern_disabled")
        end
        if has_chain and has_trigger then
            addSet(summary.combos, "chain_trigger_side_payload")
        end
        if has_chain and has_timer then
            addSet(summary.combos, "chain_timer_side_payload")
        end
        if has_chain
            and (has_trigger or has_timer)
            and groupsHavePrefixOpcode(payload_groups, "Chain") then
            addSet(summary.deferred_reasons, "chain_event_payload_chain_deferred")
        end
        if depth == 0
            and (has_speed or has_size)
            and not has_chain
            and not has_bounce
            and not has_pierce then
            if has_pattern and not has_multicast then
                addSet(summary.deferred_reasons, "source_modifier_pattern_deferred")
            elseif has_payload_effects and not (has_trigger or has_timer) then
                addSet(summary.deferred_reasons, "source_modifier_nested_deferred")
            end
        end
        if has_chain and hasSet(payload_stack, "Chain") then
            addSet(summary.deferred_reasons, "chain_recursion_deferred")
        end
        if depth > 0 and (has_speed or has_size) and not has_chain then
            if has_pattern and not has_multicast then
                addSet(summary.deferred_reasons, "payload_modifier_pattern_deferred")
            end
        end

        if has_bounce and has_chain then
            addSet(summary.deferred_reasons, "bounce_chain_deferred")
        end
        if has_bounce and (has_speed or has_size) then
            if has_speed and has_size and not (has_multicast or has_pattern) then
                addSet(summary.deferred_reasons, "source_modifier_combo_deferred")
            elseif has_chain then
                addSet(summary.deferred_reasons, "source_modifier_chain_deferred")
            elseif has_timer then
                addSet(summary.deferred_reasons, "source_modifier_nested_deferred")
            elseif has_trigger then
                addSet(summary.deferred_reasons, "source_modifier_nested_deferred")
            end
        end
        if has_bounce and has_homing then
            addSet(summary.deferred_reasons, "homing_bounce_physics_unsupported")
        end

        if has_pierce and has_bounce then
            addSet(summary.deferred_reasons, "pierce_bounce_deferred")
        end
        if has_pierce and has_chain then
            addSet(summary.deferred_reasons, "pierce_chain_deferred")
        end
        if has_pierce and (has_speed or has_size) then
            if has_speed and has_size and not (has_multicast or has_pattern) then
                addSet(summary.deferred_reasons, "source_modifier_combo_deferred")
            elseif has_chain then
                addSet(summary.deferred_reasons, "source_modifier_chain_deferred")
            elseif has_timer then
                addSet(summary.deferred_reasons, "source_modifier_nested_deferred")
            elseif has_trigger then
                addSet(summary.deferred_reasons, "source_modifier_nested_deferred")
            end
        end
        if has_pierce and has_homing then
            addSet(summary.deferred_reasons, "homing_pierce_physics_unsupported")
        end
        if has_pierce and (depth > 0 or hasSet(payload_stack, "Pierce")) then
            addSet(summary.deferred_reasons, "pierce_nested_payload_deferred")
        end

        if has_homing and has_chain then
            addSet(summary.deferred_reasons, "homing_chain_targeting_unsupported")
        end
        if has_homing and depth > (limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3) then
            addSet(summary.deferred_reasons, "homing_nested_runtime_deferred")
        end

        local payload_opcode = firstPostfixOpcode(group)
        if has_payload_effects then
            summary.has_payload = true
            local child_stack = copySet(payload_stack)
            if payload_opcode then
                if depth >= (limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or 3) then
                    addSet(summary.deferred_reasons, "nested_depth_exceeded")
                end
                addSet(child_stack, payload_opcode)
            end
            if has_chain then
                addSet(child_stack, "Chain")
            end
            if has_pierce then
                addSet(child_stack, "Pierce")
            end

            if payload_groups then
                scanGroups(payload_groups, summary, depth + 1, child_stack, options)
            else
                addSet(summary.deferred_reasons, "payload_parse_failed")
            end
        end
    end
end

local function buildSummary(plan, options)
    local summary = {
        recipe_id = plan and plan.recipe_id or nil,
        active = { simple_projectile = true },
        counts = {},
        min_depth = {},
        contexts = {
            primary = {},
            payload = {},
            nested_payload = {},
        },
        combos = {},
        deferred_reasons = {},
        max_payload_depth = 0,
        has_payload = false,
    }
    summary.counts.simple_projectile = 1
    summary.min_depth.simple_projectile = 0
    summary.contexts.primary.simple_projectile = true

    local root_groups = plan and plan.groups or {}
    scanGroups(root_groups, summary, 0, {}, options or {})

    if #root_groups > 1 and groupsHaveUnsupportedMultiRootSourceModifier(root_groups) then
        addSet(summary.deferred_reasons, "source_modifier_combo_deferred")
    end

    if summary.active.bounce and summary.active.chain and not summary.combos.bounce_trigger_chain then
        addSet(summary.deferred_reasons, "bounce_chain_deferred")
    end
    if summary.active.pierce and summary.active.chain and not summary.combos.pierce_trigger_chain then
        addSet(summary.deferred_reasons, "pierce_chain_deferred")
    end

    if summary.max_payload_depth > (limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH or limits.MAX_NESTED_PAYLOAD_DEPTH) then
        addSet(summary.deferred_reasons, "nested_depth_exceeded")
    end

    return summary
end

local function buildFeatureEntry(feature_id, summary)
    local def = FEATURE_BY_ID[feature_id] or {
        id = feature_id,
        display_name = feature_id,
        category = "unknown",
        status = "unknown",
        gates = {},
        summary = "",
    }

    return {
        id = def.id,
        display_name = def.display_name,
        category = def.category,
        status = def.status,
        active = summary.active[feature_id] == true,
        gates = cloneArray(def.gates),
        optional_gates = cloneArray(def.optional_gates),
        count = summary.counts[feature_id] or 0,
        min_payload_depth = summary.min_depth[feature_id],
        summary = def.summary,
    }
end

local function collectRequiredFlags(active_features)
    local set = {}
    addSet(set, FLAG_LIVE_2_2C)
    for _, feature_id in ipairs(active_features or {}) do
        local def = FEATURE_BY_ID[feature_id]
        if def then
            addAll(set, def.gates)
        end
    end
    return sortedKeys(set)
end

function feature_matrix.catalog()
    return defs.catalog()
end

function feature_matrix.legacyAnalyze(plan, opts)
    local options = opts or {}
    local summary = buildSummary(plan or {}, options)
    local active_feature_ids = sortedKeys(summary.active)
    local deferred_reasons = sortedKeys(summary.deferred_reasons)
    local active_features = {}
    for i, feature_id in ipairs(active_feature_ids) do
        active_features[i] = buildFeatureEntry(feature_id, summary)
    end

    local reason_report = defs.classifyReasons(deferred_reasons)
    local support_status = #deferred_reasons > 0 and "deferred" or "feature_gated"
    local required_flags = collectRequiredFlags(active_feature_ids)

    return {
        version = feature_matrix.VERSION,
        source_kind = plan and plan.source_kind or nil,
        recipe_id = plan and plan.recipe_id or nil,
        preview_status = "supported",
        live_runtime_status = support_status,
        default_enabled = false,
        active_feature_ids = active_feature_ids,
        active_features = active_features,
        contexts = {
            primary = sortedKeys(summary.contexts.primary),
            payload = sortedKeys(summary.contexts.payload),
            nested_payload = sortedKeys(summary.contexts.nested_payload),
        },
        combos = sortedKeys(summary.combos),
        deferred_reasons = deferred_reasons,
        reason_classifications = reason_report.by_class,
        reason_classification_counts = reason_report.counts,
        unsupported_reasons = reason_report.unsupported_by_design,
        future_deferred_reasons = reason_report.future_deferred,
        cap_budget_reasons = reason_report.cap_or_budget_rejected,
        gate_disabled_reasons = reason_report.gate_disabled,
        internal_error_reasons = reason_report.internal_error,
        required_flags = required_flags,
        optional_flags = { FLAG_HOMING_V2_MANAGER, FLAG_SOFT_HOMING },
        limits = {
            max_projectiles_per_cast = limits.MAX_PROJECTILES_PER_CAST,
            max_payload_fanout = limits.MAX_PAYLOAD_FANOUT,
            max_chain_hops = limits.MAX_CHAIN_HOPS,
            max_chain_multicast_fanout = limits.MAX_CHAIN_MULTICAST_FANOUT,
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
        },
        notes = options.notes,
    }
end

local function hasRequiredIrArtifacts(plan)
    return type(plan) == "table"
        and type(plan.emission_slots) == "table"
        and #plan.emission_slots > 0
        and type(plan.helper_specs) == "table"
        and #plan.helper_specs == #plan.emission_slots
end

function feature_matrix.analyze(plan, opts)
    if hasRequiredIrArtifacts(plan) then
        local ir = runtime_ir.build(plan, opts)
        if ir and ir.ok == true then
            return feature_matrix_ir.analyzeFromIr(ir, opts)
        end
    end

    return feature_matrix.legacyAnalyze(plan, opts)
end

return feature_matrix
