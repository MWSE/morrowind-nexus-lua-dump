---@omw-context global
local limits = require("scripts.spellforge.shared.limits")
local emission_slots = require("scripts.spellforge.global.emission_slots")
local helper_record_specs = require("scripts.spellforge.global.helper_record_specs")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local chain_targeting = {}

local function countList(value)
    if type(value) ~= "table" then
        return 0
    end
    return #value
end

local function addReason(set, reason)
    if type(reason) == "string" and reason ~= "" then
        set[reason] = true
    end
end

local function sortedReasons(set)
    local out = {}
    for reason in pairs(set or {}) do
        out[#out + 1] = reason
    end
    table.sort(out)
    return out
end

local function firstReason(reasons)
    return reasons and reasons[1] or nil
end

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

local function multicastFanout(ops)
    local count = 1
    local found = false
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == "Multicast" then
            found = true
            local op_count = tonumber(op.params and op.params.count) or 1
            count = count * math.max(1, math.floor(op_count))
        end
    end
    return found and count or 1
end

local function hasPayloadBindings(value)
    return type(value) == "table" and #value > 0
end

local function isPrimary(slot)
    return type(slot) == "table"
        and slot.kind == "primary_emission"
        and slot.parent_slot_id == nil
        and slot.source_postfix_opcode == nil
end

local function sortedSlots(slots)
    local out = {}
    for _, slot in ipairs(slots or {}) do
        out[#out + 1] = slot
    end
    table.sort(out, function(a, b)
        local ag = tonumber(a and a.group_index) or 0
        local bg = tonumber(b and b.group_index) or 0
        if ag ~= bg then
            return ag < bg
        end
        local ae = tonumber(a and a.emission_index) or 0
        local be = tonumber(b and b.emission_index) or 0
        if ae ~= be then
            return ae < be
        end
        return tostring(a and a.slot_id) < tostring(b and b.slot_id)
    end)
    return out
end

local function slotMap(slots)
    local out = {}
    for _, slot in ipairs(slots or {}) do
        if slot and slot.slot_id ~= nil then
            out[slot.slot_id] = slot
        end
    end
    return out
end

local function ensureSlots(plan, opts)
    if type(plan.emission_slots) == "table" and #plan.emission_slots > 0 then
        return plan.emission_slots, nil
    end

    local allocated = emission_slots.allocate(plan, opts)
    if not allocated.ok then
        return nil, allocated.errors or { { message = "slot_allocation_failed" } }
    end
    return allocated.slots or {}, nil
end

local function ensureHelperCount(plan, slots, opts)
    if type(plan.helper_records) == "table" and #plan.helper_records > 0 then
        return #plan.helper_records
    end
    if type(plan.helper_specs) == "table" and #plan.helper_specs > 0 then
        return #plan.helper_specs
    end
    local generated = helper_record_specs.generate(plan, slots, opts)
    if generated.ok and type(generated.specs) == "table" then
        return #generated.specs
    end
    return #slots
end

local function clonePosition(value)
    if value == nil then
        return nil
    end
    local function readComponent(key)
        local ok, result = pcall(function()
            return value[key]
        end)
        if ok then
            return result
        end
        return nil
    end
    return {
        x = tonumber(readComponent("x")) or 0,
        y = tonumber(readComponent("y")) or 0,
        z = tonumber(readComponent("z")) or 0,
    }
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

local function component(position, key)
    local value = position and position[key]
    return tonumber(value) or 0
end

local function distanceBetween(a, b)
    local ax = component(a, "x")
    local ay = component(a, "y")
    local az = component(a, "z")
    local bx = component(b, "x")
    local by = component(b, "y")
    local bz = component(b, "z")
    local dx = ax - bx
    local dy = ay - by
    local dz = az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
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

local function candidateId(candidate, index)
    return tostring(candidate and (candidate.id or candidate.recordId or candidate.refId) or ("candidate_" .. tostring(index)))
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

local function compactTarget(candidate, index, distance)
    return {
        id = candidateId(candidate, index),
        object_id = objectToken(candidate and candidate.object) or objectToken(candidate),
        distance = distance,
        vertical_delta = candidate and candidate.vertical_delta or nil,
        cell = cellToken(candidate and candidate.cell),
        position = clonePosition(tablePosition(candidate)),
    }
end

local function rejectResult(result, reason)
    result.ok = false
    result.rejection_reason = reason
    return result
end

local function normalizeHopCount(chain_op, hop_cap)
    local raw = chain_op and chain_op.params and chain_op.params.hops
    local requested = tonumber(raw)
    if requested == nil then
        return nil, "chain_hops_invalid"
    end
    if requested ~= requested or requested == math.huge or requested == -math.huge then
        return requested, "chain_hops_invalid"
    end
    if requested < 1 or requested ~= math.floor(requested) then
        return requested, "chain_hops_invalid"
    end
    if requested > hop_cap then
        return requested, "chain_hop_cap_exceeded"
    end
    return requested, nil
end

local function primaryBefore(ordered, chain_slot)
    local source_slot = nil
    for _, slot in ipairs(ordered or {}) do
        if slot == chain_slot then
            break
        end
        if isPrimary(slot) then
            source_slot = slot
        end
    end
    return source_slot
end

function chain_targeting.inspectPlan(plan, opts)
    local options = opts or {}
    local hop_cap = tonumber(options.max_hops or limits.MAX_CHAIN_AUDIT_HOPS or limits.MAX_CHAIN_HOPS) or 1
    local max_jobs = tonumber(options.max_jobs or limits.MAX_CHAIN_JOBS_PER_CAST) or hop_cap
    local allow_chain_multicast = options.allow_chain_multicast == true
    local allow_chain_pattern = options.allow_chain_pattern == true or options.allow_payload_pattern == true
    local allow_chain_event_continuation = options.allow_chain_event_continuation == true
    local chain_multicast_fanout_cap = tonumber(options.max_chain_multicast_fanout or limits.MAX_CHAIN_MULTICAST_FANOUT) or 1
    local chain_pattern_fanout_cap = tonumber(options.max_chain_pattern_fanout or options.max_chain_multicast_fanout or limits.MAX_CHAIN_PATTERN_FANOUT) or chain_multicast_fanout_cap
    local reasons = {}
    local result = {
        ok = false,
        mode = "chain_targeting_audit",
        audit_only = true,
        runtime_enabled = false,
        recipe_id = plan and plan.recipe_id or nil,
        has_chain = false,
        chain_candidate = false,
        chain_shape = nil,
        requested_hops = nil,
        max_hops = 0,
        max_hops_cap = hop_cap,
        source_slot_id = nil,
        payload_slot_id = nil,
        has_trigger_payload_context = false,
        has_timer_payload_context = false,
        hop_index = 0,
        scan_radius = tonumber(options.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS) or limits.MAX_SCAN_RADIUS,
        candidate_count = 0,
        valid_candidate_count = 0,
        selected_count = 0,
        selected_targets = {},
        excluded_count = 0,
        exclusion_reasons = {},
        rejection_reason = nil,
        unsupported_reasons = {},
        would_enqueue_jobs = 0,
        would_launch_payloads = 0,
        exceeds_radius_cap = false,
        exceeds_candidate_cap = false,
        exceeds_hop_cap = false,
        exceeds_job_cap = false,
        has_nested_chain = false,
        has_chain_in_nested_payload = false,
        has_chain_with_multicast = false,
        has_chain_with_pattern = false,
        has_chain_with_trigger_timer = false,
        has_chain_with_modifier_combo = false,
        has_speed_plus_payload = false,
        has_size_plus_payload = false,
        has_multicast_payload = false,
        chain_multicast_runtime_candidate = false,
        chain_multicast_fanout_count = 1,
        chain_multicast_fanout_cap = chain_multicast_fanout_cap,
        chain_pattern_fanout_cap = chain_pattern_fanout_cap,
        payload_slot_ids = nil,
        has_pattern_payload = false,
        has_trigger_timer_payload = false,
        chain_side_continuation_kind = nil,
        chain_side_payload_count = 0,
        chain_event_continuation_budget = 0,
        has_chain_recursion = false,
        payload_modifier_kind = nil,
        chain_runtime_candidate = false,
        live_safe_under_current_limits = false,
        future_runtime_candidate = false,
        slot_count = 0,
        helper_count = 0,
    }

    if type(plan) ~= "table" then
        addReason(reasons, "missing_plan")
        result.unsupported_reasons = sortedReasons(reasons)
        result.rejection_reason = firstReason(result.unsupported_reasons)
        return result
    end

    local slots, slot_errors = ensureSlots(plan, options)
    if slot_errors then
        for _, err in ipairs(slot_errors or {}) do
            addReason(reasons, err and err.message or "slot_allocation_failed")
        end
        result.unsupported_reasons = sortedReasons(reasons)
        result.rejection_reason = firstReason(result.unsupported_reasons)
        return result
    end

    result.slot_count = #slots
    result.helper_count = ensureHelperCount(plan, slots, options)

    local ordered = sortedSlots(slots)
    local by_id = slotMap(slots)
    local chain_slots = {}
    local total_chain_ops = 0
    for _, slot in ipairs(ordered) do
        local chain_count, chain_op = countOpcode(slot.prefix_ops, "Chain")
        if chain_count > 0 then
            result.has_chain = true
            total_chain_ops = total_chain_ops + chain_count
            chain_slots[#chain_slots + 1] = { slot = slot, op = chain_op, count = chain_count }
            if chain_count > 1 then
                result.has_nested_chain = true
                result.has_chain_recursion = true
                addReason(reasons, "chain_recursion_deferred")
            end
            if hasOpcode(slot.prefix_ops, "Multicast") then
                result.has_chain_with_multicast = true
                result.has_multicast_payload = true
                result.chain_multicast_fanout_count = math.max(result.chain_multicast_fanout_count or 1, multicastFanout(slot.prefix_ops))
                if not allow_chain_multicast then
                    addReason(reasons, "chain_multicast_deferred")
                end
            end
            if hasOpcode(slot.prefix_ops, "Spread") or hasOpcode(slot.prefix_ops, "Burst") then
                result.has_chain_with_pattern = true
                result.has_pattern_payload = true
                if not hasOpcode(slot.prefix_ops, "Multicast") or not allow_chain_pattern then
                    addReason(reasons, "chain_pattern_disabled")
                end
            end
            if hasOpcode(slot.prefix_ops, "Speed+") then
                result.has_speed_plus_payload = true
            end
            if hasOpcode(slot.prefix_ops, "Size+") then
                result.has_size_plus_payload = true
            end
            if result.has_speed_plus_payload and result.has_size_plus_payload then
                result.has_chain_with_modifier_combo = true
                result.payload_modifier_kind = "speed_plus_size_plus"
            elseif result.has_speed_plus_payload then
                result.payload_modifier_kind = "speed_plus"
            elseif result.has_size_plus_payload then
                result.payload_modifier_kind = "size_plus"
            end
            local has_trigger_postfix = hasOpcode(slot.postfix_ops, "Trigger")
            local has_timer_postfix = hasOpcode(slot.postfix_ops, "Timer")
            if has_trigger_postfix or has_timer_postfix or hasPayloadBindings(slot.payload_bindings) then
                result.has_chain_with_trigger_timer = true
                result.has_trigger_timer_payload = true
                if has_trigger_postfix and has_timer_postfix then
                    addReason(reasons, "chain_nested_payload_deferred")
                elseif has_trigger_postfix or has_timer_postfix then
                    result.chain_side_continuation_kind = has_trigger_postfix and "Trigger" or "Timer"
                    if not allow_chain_event_continuation then
                        addReason(reasons, "chain_trigger_timer_deferred")
                    end
                else
                    addReason(reasons, "chain_trigger_timer_deferred")
                end
            end

            local requested, hop_err = normalizeHopCount(chain_op, hop_cap)
            result.requested_hops = requested
            result.max_hops = requested and math.min(requested, hop_cap) or 0
            if hop_err == "chain_hop_cap_exceeded" then
                result.exceeds_hop_cap = true
            end
            if hop_err then
                addReason(reasons, hop_err)
            end
        elseif hasOpcode(slot.postfix_ops, "Trigger") or hasOpcode(slot.postfix_ops, "Timer") then
            if result.has_chain then
                result.has_chain_with_trigger_timer = true
                addReason(reasons, "chain_trigger_timer_deferred")
            end
        end
    end

    local logical_chain_slot_count = #chain_slots
    local chain_multicast_fanout_slots = false
    if allow_chain_multicast and #chain_slots > 1 then
        local first = chain_slots[1] and chain_slots[1].slot or nil
        local first_slot = type(first) == "table" and first or nil
        local same_group = first_slot ~= nil and hasOpcode(first_slot.prefix_ops, "Multicast")
        for _, entry in ipairs(chain_slots) do
            local slot = entry.slot
            if slot == nil
                or not hasOpcode(slot.prefix_ops, "Multicast")
                or first_slot == nil
                or tonumber(slot["group_index"]) ~= tonumber(first_slot["group_index"])
                or tostring(slot["kind"]) ~= tostring(first_slot["kind"])
                or tostring(slot["parent_slot_id"]) ~= tostring(first_slot["parent_slot_id"])
                or tostring(slot["source_postfix_opcode"]) ~= tostring(first_slot["source_postfix_opcode"])
                or entry.count ~= 1 then
                same_group = false
                break
            end
        end
        if same_group then
            chain_multicast_fanout_slots = true
            logical_chain_slot_count = 1
            result.payload_slot_ids = {}
            for _, entry in ipairs(chain_slots) do
                result.payload_slot_ids[#result.payload_slot_ids + 1] = entry.slot.slot_id
            end
            result.chain_multicast_fanout_count = math.max(#chain_slots, result.chain_multicast_fanout_count or 1)
        end
    end

    local active_fanout_cap = result.has_chain_with_pattern and chain_pattern_fanout_cap or chain_multicast_fanout_cap
    if result.has_chain_with_multicast == true
        and result.chain_multicast_fanout_count > active_fanout_cap then
        addReason(reasons, result.has_chain_with_pattern and "chain_pattern_fanout_cap_exceeded" or "chain_multicast_fanout_cap_exceeded")
    end

    if (total_chain_ops > 1 or #chain_slots > 1) and not chain_multicast_fanout_slots then
        result.has_nested_chain = true
        result.has_chain_recursion = true
        addReason(reasons, "chain_recursion_deferred")
    end

    if #chain_slots == 0 then
        addReason(reasons, "no_chain")
    elseif logical_chain_slot_count == 1 then
        local chain_slot = chain_slots[1].slot
        result.payload_slot_id = chain_slot.slot_id
        if result.chain_side_continuation_kind ~= nil then
            for _, slot in ipairs(ordered) do
                if slot
                    and slot.kind == "payload_emission"
                    and slot.parent_slot_id == chain_slot.slot_id
                    and slot.source_postfix_opcode == result.chain_side_continuation_kind then
                    result.chain_side_payload_count = result.chain_side_payload_count + 1
                end
            end
            if result.chain_side_payload_count == 0 then
                addReason(reasons, "chain_nested_payload_deferred")
            end
        end

        if isPrimary(chain_slot) then
            local source_slot = primaryBefore(ordered, chain_slot)
            if source_slot then
                result.source_slot_id = source_slot.slot_id
                result.chain_shape = "source_chain_payload"
            else
                result.source_slot_id = chain_slot.slot_id
                result.chain_shape = "source_chain_payload"
            end
        elseif chain_slot.source_postfix_opcode == "Trigger" then
            result.has_trigger_payload_context = true
            local source_slot = by_id[chain_slot.parent_slot_id]
            if source_slot
                and isPrimary(source_slot)
                and hasOpcode(source_slot.postfix_ops, "Trigger")
                and tonumber(chain_slot.group_index) == 1 then
                result.source_slot_id = source_slot.slot_id
                result.chain_shape = "trigger_payload_chain"
            else
                result.chain_shape = "chain_nested_or_unbound"
                result.has_chain_in_nested_payload = true
                addReason(reasons, "chain_nested_payload_deferred")
            end
        elseif chain_slot.source_postfix_opcode == "Timer" then
            result.has_timer_payload_context = true
            result.chain_shape = "timer_payload_chain"
            result.has_chain_with_trigger_timer = true
            addReason(reasons, "chain_timer_context_deferred")
        else
            result.chain_shape = "chain_nested_or_unbound"
            result.has_chain_in_nested_payload = true
            addReason(reasons, "chain_nested_payload_deferred")
        end
    end

    local jobs_per_hop = result.has_chain_with_multicast == true and (tonumber(result.chain_multicast_fanout_count) or 1) or 1
    result.would_enqueue_jobs = (tonumber(result.max_hops) or 0) * jobs_per_hop
    result.would_launch_payloads = result.would_enqueue_jobs
    local side_budget_exceeded = false
    if result.chain_side_continuation_kind ~= nil then
        local side_jobs_per_hop = jobs_per_hop * math.max(1, tonumber(result.chain_side_payload_count) or 1)
        local side_budget = (tonumber(result.max_hops) or 0) * side_jobs_per_hop
        result.chain_event_continuation_budget = side_budget
        local side_cap = tonumber(options.max_chain_event_continuation_jobs)
            or (result.chain_side_continuation_kind == "Trigger"
                and tonumber(options.max_chain_trigger_side_payload_jobs or limits.MAX_CHAIN_TRIGGER_SIDE_PAYLOAD_JOBS_PER_CAST)
                or tonumber(options.max_chain_timer_side_payload_jobs or limits.MAX_CHAIN_TIMER_SIDE_PAYLOAD_JOBS_PER_CAST))
            or limits.MAX_CHAIN_EVENT_CONTINUATION_JOBS_PER_CAST
        if side_budget > side_cap then
            side_budget_exceeded = true
            addReason(
                reasons,
                result.chain_side_continuation_kind == "Trigger"
                    and "chain_trigger_side_payload_budget_exceeded"
                    or "chain_timer_side_payload_budget_exceeded"
            )
        end
    end
    if result.has_chain_with_pattern == true and options.max_jobs == nil then
        max_jobs = tonumber(limits.MAX_CHAIN_PATTERN_JOBS_PER_CAST_DEFAULT) or max_jobs
    end
    result.exceeds_job_cap = result.would_enqueue_jobs > max_jobs or side_budget_exceeded
    if result.exceeds_job_cap then
        addReason(reasons, result.has_chain_with_pattern and "chain_pattern_jobs_cap_exceeded" or "chain_job_cap_exceeded")
    end

    result.chain_candidate = result.has_chain == true
        and logical_chain_slot_count == 1
        and (result.chain_shape == "source_chain_payload" or result.chain_shape == "trigger_payload_chain")
        and result.source_slot_id ~= nil
        and result.payload_slot_id ~= nil
        and result.requested_hops ~= nil
        and result.requested_hops >= 1
        and result.has_nested_chain == false
        and result.has_chain_in_nested_payload == false
        and (result.has_chain_with_multicast == false or allow_chain_multicast)
        and (result.has_chain_with_pattern == false or (allow_chain_pattern and result.has_chain_with_multicast))
        and (result.has_chain_with_trigger_timer == false
            or (allow_chain_event_continuation and result.chain_side_continuation_kind ~= nil))
        and result.exceeds_hop_cap == false
        and result.exceeds_job_cap == false
        and (result.has_chain_with_multicast == false or result.chain_multicast_fanout_count <= chain_multicast_fanout_cap)

    result.chain_multicast_runtime_candidate = result.chain_candidate == true
        and result.has_chain_with_multicast == true
        and allow_chain_multicast == true

    result.unsupported_reasons = sortedReasons(reasons)
    result.rejection_reason = result.chain_candidate and nil or firstReason(result.unsupported_reasons)
    result.chain_runtime_candidate = result.chain_candidate
    result.live_safe_under_current_limits = result.chain_candidate
    result.future_runtime_candidate = result.chain_candidate
    result.ok = result.chain_candidate
    return result
end

function chain_targeting.resolveNextTarget(hit_context, candidates, opts)
    local options = opts or {}
    local radius_cap = tonumber(options.max_radius or limits.MAX_CHAIN_SCAN_RADIUS) or limits.MAX_SCAN_RADIUS
    local radius = tonumber(options.scan_radius) or radius_cap
    if radius > radius_cap then
        radius = radius_cap
    end
    local candidate_cap = tonumber(options.max_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES) or 16
    local target_cap = tonumber(options.max_targets or limits.MAX_CHAIN_TARGETS_PER_HOP) or 1
    local result = {
        ok = false,
        mode = "chain_targeting_audit",
        audit_only = true,
        runtime_enabled = false,
        recipe_id = type(hit_context) == "table" and hit_context.recipe_id or nil,
        cast_id = type(hit_context) == "table" and hit_context.cast_id or nil,
        source_slot_id = type(hit_context) == "table" and hit_context.source_slot_id or nil,
        payload_slot_id = type(hit_context) == "table" and hit_context.payload_slot_id or nil,
        chain_id = type(hit_context) == "table" and hit_context.chain_id or options.chain_id,
        hop_index = tonumber(options.hop_index or (type(hit_context) == "table" and hit_context.hop_index)) or 1,
        max_hops = tonumber(options.max_hops or (type(hit_context) == "table" and hit_context.max_hops) or limits.MAX_CHAIN_AUDIT_HOPS) or 1,
        targeting_mode = options.targeting_mode or "no_immediate_repeat",
        scan_radius = radius,
        candidate_count = countList(candidates),
        considered_candidate_count = 0,
        valid_candidate_count = 0,
        selected_count = 0,
        selected_targets = {},
        excluded_count = 0,
        exclusion_reasons = {},
        excluded_current_target_id = nil,
        rejection_reason = nil,
        unsupported_reasons = {},
        exceeds_radius_cap = (tonumber(options.scan_radius) or radius) > radius_cap,
        exceeds_candidate_cap = countList(candidates) > candidate_cap,
        exceeds_hop_cap = false,
        exceeds_job_cap = target_cap < 1,
        would_enqueue_jobs = 0,
        would_launch_payloads = 0,
    }

    runtime_stats.inc("chain_target_resolve_attempts")
    runtime_stats.inc("chain_target_candidates_seen", result.candidate_count)
    if result.exceeds_candidate_cap then
        runtime_stats.inc("chain_target_cap_reject")
    end

    if type(hit_context) ~= "table" then
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_invalid_context_reject")
        return rejectResult(result, "invalid_chain_hit_context")
    end
    if result.hop_index > result.max_hops then
        result.exceeds_hop_cap = true
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_recursion_reject")
        return rejectResult(result, "chain_hop_cap_exceeded")
    end
    if result.exceeds_job_cap then
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_cap_reject")
        return rejectResult(result, "chain_job_cap_exceeded")
    end

    local current_target = hit_context.current_hit_target or hit_context.source_target
    local origin = tablePosition(hit_context.current_hit_position)
        or tablePosition(current_target)
        or tablePosition(hit_context.hit_position)
    if not origin then
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_invalid_context_reject")
        return rejectResult(result, "missing_chain_hit_position")
    end
    if type(candidates) ~= "table" then
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_invalid_context_reject")
        return rejectResult(result, "missing_chain_candidates")
    end

    local hit_cell = cellToken(hit_context.current_cell or hit_context.hit_cell)
    local caster_token = objectToken(hit_context.caster)
    local current_token = objectToken(current_target)
    local valid = {}
    local considered = math.min(#candidates, candidate_cap)
    result.considered_candidate_count = considered

    for index = 1, considered do
        local candidate = candidates[index]
        local id = candidateId(candidate, index)
        local reason = nil
        if type(candidate) ~= "table" then
            reason = "candidate_invalid"
        else
            local token = objectToken(candidate.object) or objectToken(candidate)
            if hit_context.exclude_caster ~= false and caster_token ~= nil and token == caster_token then
                reason = "excluded_caster"
            elseif hit_context.exclude_current_hit_target ~= false and current_token ~= nil and token == current_token then
                reason = "excluded_current_hit_target"
                result.excluded_current_target_id = id
                runtime_stats.inc("chain_target_no_immediate_repeat_exclusions")
            elseif candidate.is_valid == false then
                reason = "candidate_invalid"
            elseif candidate.is_alive == false then
                reason = "candidate_dead"
            elseif candidate.is_actor == false then
                reason = "candidate_non_actor"
            elseif candidate.can_be_targeted == false then
                reason = "candidate_untargetable"
            elseif options.allow_different_cells ~= true and hit_cell ~= nil and cellToken(candidate.cell) ~= hit_cell then
                reason = "candidate_different_cell"
            end
        end

        local distance = nil
        if reason == nil then
            distance = tonumber(candidate.distance_override)
            if distance == nil then
                local position = tablePosition(candidate)
                if not position then
                    reason = "candidate_position_missing"
                else
                    distance = distanceBetween(origin, position)
                end
            end
        end
        if reason == nil and distance > radius then
            reason = "candidate_out_of_radius"
            runtime_stats.inc("chain_target_radius_reject")
        end

        if reason then
            result.excluded_count = result.excluded_count + 1
            result.exclusion_reasons[#result.exclusion_reasons + 1] = {
                id = id,
                reason = reason,
            }
        else
            valid[#valid + 1] = {
                candidate = candidate,
                index = index,
                id = id,
                distance = distance,
            }
        end
    end

    table.sort(valid, function(a, b)
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        return tostring(a.id) < tostring(b.id)
    end)

    result.valid_candidate_count = #valid
    runtime_stats.inc("chain_target_candidates_valid", result.valid_candidate_count)
    local selected_count = math.min(#valid, target_cap)
    for index = 1, selected_count do
        local item = valid[index]
        result.selected_targets[index] = compactTarget(item.candidate, item.index, item.distance)
    end
    result.selected_count = #result.selected_targets
    result.would_enqueue_jobs = result.selected_count
    result.would_launch_payloads = result.selected_count
    runtime_stats.inc("chain_target_candidates_selected", result.selected_count)

    if result.selected_count == 0 then
        runtime_stats.inc("chain_target_resolve_rejected")
        runtime_stats.inc("chain_target_no_target_reject")
        return rejectResult(result, "no_valid_chain_target")
    end

    result.ok = true
    runtime_stats.inc("chain_target_resolve_ok")
    return result
end

function chain_targeting.resolveTargets(hit_context, candidates, opts)
    return chain_targeting.resolveNextTarget(hit_context, candidates, opts)
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

local function copyContext(base)
    local out = {}
    for key, value in pairs(base or {}) do
        out[key] = value
    end
    return out
end

function chain_targeting.simulateHops(plan, initial_hit_context, candidate_provider, opts)
    local options = opts or {}
    runtime_stats.inc("chain_hop_dry_run_attempts")
    local inspect = chain_targeting.inspectPlan(plan, options)
    local result = {
        ok = false,
        mode = "chain_hop_dry_run",
        audit_only = true,
        runtime_enabled = false,
        recipe_id = inspect.recipe_id,
        chain_id = options.chain_id or string.format("chain:%s:%s:%s", tostring(inspect.recipe_id), tostring(inspect.source_slot_id), tostring(inspect.payload_slot_id)),
        requested_hops = inspect.requested_hops,
        max_hops = inspect.max_hops,
        completed_hops = 0,
        stop_reason = nil,
        hops = {},
        selected_target_ids = {},
        would_enqueue_jobs = 0,
        would_launch_payloads = 0,
        rejection_reason = nil,
        source_slot_id = inspect.source_slot_id,
        payload_slot_id = inspect.payload_slot_id,
        chain_shape = inspect.chain_shape,
    }

    runtime_stats.inc("chain_hops_requested", tonumber(inspect.requested_hops) or 0)
    if inspect.chain_candidate ~= true then
        result.stop_reason = "unsupported_shape"
        result.rejection_reason = inspect.rejection_reason or "unsupported_chain_shape"
        runtime_stats.inc("chain_hop_dry_run_rejected")
        return result
    end
    if type(initial_hit_context) ~= "table" then
        result.stop_reason = "invalid_context"
        result.rejection_reason = "invalid_chain_hit_context"
        runtime_stats.inc("chain_hop_dry_run_rejected")
        return result
    end

    local current = copyContext(initial_hit_context)
    current.chain_id = result.chain_id
    current.recipe_id = current.recipe_id or inspect.recipe_id
    current.source_slot_id = current.source_slot_id or inspect.source_slot_id
    current.payload_slot_id = current.payload_slot_id or inspect.payload_slot_id
    current.max_hops = inspect.max_hops
    current.exclude_current_hit_target = current.exclude_current_hit_target ~= false
    current.exclude_caster = current.exclude_caster ~= false

    for hop_index = 1, inspect.max_hops do
        current.hop_index = hop_index
        local candidates = candidatesForHop(candidate_provider, current)
        local resolved = chain_targeting.resolveNextTarget(current, candidates, {
            hop_index = hop_index,
            max_hops = inspect.max_hops,
            scan_radius = options.scan_radius,
            max_radius = options.max_radius,
            max_candidates = options.max_candidates,
            max_targets = options.max_targets,
            targeting_mode = options.targeting_mode or "no_immediate_repeat",
            allow_different_cells = options.allow_different_cells,
            chain_id = result.chain_id,
        })
        local selected = resolved.selected_targets and resolved.selected_targets[1] or nil
        local hop_entry = {
            hop_index = hop_index,
            current_hit_target_id = objectToken(current.current_hit_target or current.source_target),
            excluded_current_target_id = resolved.excluded_current_target_id,
            candidate_count = resolved.candidate_count,
            valid_candidate_count = resolved.valid_candidate_count,
            selected_target_id = selected and selected.id or nil,
            selected_distance = selected and selected.distance or nil,
            rejection_reason = resolved.rejection_reason,
        }
        result.hops[#result.hops + 1] = hop_entry

        if not resolved.ok or not selected then
            result.stop_reason = resolved.rejection_reason or "no_valid_chain_target"
            result.rejection_reason = resolved.rejection_reason
            if result.stop_reason == "no_valid_chain_target" then
                runtime_stats.inc("chain_hop_stop_no_target")
            end
            break
        end

        result.completed_hops = result.completed_hops + 1
        result.selected_target_ids[#result.selected_target_ids + 1] = selected.id
        current.current_hit_target = {
            id = selected.id,
            object = selected.object_id or selected.id,
            position = selected.position,
            cell = selected.cell,
        }
        current.current_hit_position = selected.position
        current.current_cell = selected.cell
    end

    result.would_enqueue_jobs = result.completed_hops
    result.would_launch_payloads = result.completed_hops
    runtime_stats.inc("chain_hops_completed", result.completed_hops)

    if result.completed_hops >= inspect.max_hops then
        result.ok = true
        result.stop_reason = "max_hops_reached"
        runtime_stats.inc("chain_hop_stop_max")
        runtime_stats.inc("chain_hop_dry_run_ok")
    elseif result.completed_hops > 0 then
        result.ok = true
        runtime_stats.inc("chain_hop_dry_run_ok")
    else
        result.ok = false
        runtime_stats.inc("chain_hop_dry_run_rejected")
    end

    return result
end

function chain_targeting.auditChainDryRun(plan, initial_hit_context, candidate_provider, opts)
    local options = opts or {}
    runtime_stats.inc("chain_audit_attempts")
    local inspect = chain_targeting.inspectPlan(plan, options)
    local result = {}
    for key, value in pairs(inspect) do
        result[key] = value
    end
    result.audit_only = true
    result.runtime_enabled = false

    if inspect.chain_candidate ~= true then
        runtime_stats.inc("chain_audit_rejected")
        if inspect.has_chain_in_nested_payload then
            runtime_stats.inc("chain_target_nested_reject")
        end
        if inspect.has_chain_with_multicast then
            runtime_stats.inc("chain_target_multicast_reject")
        end
        if inspect.has_chain_with_pattern then
            runtime_stats.inc("chain_target_pattern_reject")
        end
        if inspect.has_chain_with_trigger_timer then
            runtime_stats.inc("chain_target_trigger_timer_reject")
        end
        if inspect.has_nested_chain then
            runtime_stats.inc("chain_target_recursion_reject")
        end
        return result
    end

    local simulated = chain_targeting.simulateHops(plan, initial_hit_context, candidate_provider, options)
    result.completed_hops = simulated.completed_hops
    result.stop_reason = simulated.stop_reason
    result.hops = simulated.hops
    result.selected_target_ids = simulated.selected_target_ids
    result.would_enqueue_jobs = simulated.would_enqueue_jobs
    result.would_launch_payloads = simulated.would_launch_payloads
    result.cast_id = type(initial_hit_context) == "table" and initial_hit_context.cast_id or result.cast_id
    result.ok = simulated.ok == true
    result.future_runtime_candidate = result.ok == true and result.completed_hops > 0
    result.live_safe_under_current_limits = result.future_runtime_candidate
    result.rejection_reason = simulated.ok == true and nil or simulated.rejection_reason
    if result.ok then
        runtime_stats.inc("chain_audit_ok")
        runtime_stats.inc("chain_audit_future_candidate")
        if result.chain_side_continuation_kind ~= nil then
            runtime_stats.inc("chain_event_continuation_policy_ok")
            runtime_stats.inc("chain_event_continuation_budget_ok")
        end
    else
        runtime_stats.inc("chain_audit_rejected")
    end
    return result
end

return chain_targeting
