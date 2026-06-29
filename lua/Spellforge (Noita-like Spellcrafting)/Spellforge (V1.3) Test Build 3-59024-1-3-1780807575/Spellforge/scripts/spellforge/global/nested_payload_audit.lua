---@omw-context global
local limits = require("scripts.spellforge.shared.limits")
local emission_slots = require("scripts.spellforge.global.emission_slots")
local helper_record_specs = require("scripts.spellforge.global.helper_record_specs")

local nested_payload_audit = {}

local ALLOWED_PREFIX_OPS = {
    Multicast = true,
    Spread = true,
    Burst = true,
    ["Speed+"] = true,
    ["Size+"] = true,
    Chain = true,
    Homing = true,
    Detonate = true,
}

local ALLOWED_POSTFIX_OPS = {
    Trigger = true,
    Timer = true,
}

local function countList(value)
    if type(value) ~= "table" then
        return 0
    end
    return #value
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            return true
        end
    end
    return false
end

local function hasAnyPayloadBinding(slot)
    return type(slot) == "table"
        and type(slot.payload_bindings) == "table"
        and #slot.payload_bindings > 0
end

local function isPrimary(slot)
    return type(slot) == "table"
        and slot.parent_slot_id == nil
        and slot.source_postfix_opcode == nil
end

local function isPayload(slot)
    return type(slot) == "table"
        and (slot.parent_slot_id ~= nil or slot.source_postfix_opcode ~= nil)
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

local function ensureSlots(plan, opts)
    if type(plan.emission_slots) == "table" and #plan.emission_slots > 0 then
        return plan.emission_slots, plan.slot_warnings or {}, nil
    end

    local allocated = emission_slots.allocate(plan, opts)
    if not allocated.ok then
        return nil, allocated.warnings or {}, allocated.errors or { { message = "slot allocation failed" } }
    end
    return allocated.slots or {}, allocated.warnings or {}, nil
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

local function slotDepth(slot, by_slot_id, visiting, cache, reasons)
    if type(slot) ~= "table" or type(slot.slot_id) ~= "string" then
        return 0
    end
    if cache[slot.slot_id] ~= nil then
        return cache[slot.slot_id]
    end
    if visiting[slot.slot_id] then
        addReason(reasons, "slot_parent_cycle")
        cache[slot.slot_id] = 0
        return 0
    end
    visiting[slot.slot_id] = true

    local depth = 0
    if type(slot.parent_slot_id) == "string" then
        local parent = by_slot_id[slot.parent_slot_id]
        if parent then
            depth = slotDepth(parent, by_slot_id, visiting, cache, reasons) + 1
        else
            addReason(reasons, "missing_parent_slot")
            depth = 1
        end
    end

    visiting[slot.slot_id] = nil
    cache[slot.slot_id] = depth
    return depth
end

local function countChildrenByParent(slots)
    local counts = {}
    for _, slot in ipairs(slots or {}) do
        if type(slot.parent_slot_id) == "string" then
            counts[slot.parent_slot_id] = (counts[slot.parent_slot_id] or 0) + 1
        end
    end
    return counts
end

local function auditOps(slot, reasons, result, options)
    local allowed_primary_prefix_ops = options.allowed_primary_prefix_ops or {}
    local primary = isPrimary(slot)
    for _, op in ipairs(slot.prefix_ops or {}) do
        local opcode = op and op.opcode
        if primary and allowed_primary_prefix_ops[opcode] == true then
            -- Caller-owned primary runtime, such as Bounce, can be audited while
            -- keeping payload prefix policy strict.
        elseif not ALLOWED_PREFIX_OPS[opcode] then
            addReason(reasons, "unsupported_prefix_" .. tostring(opcode))
        elseif opcode == "Chain" then
            result.has_chain = true
            addReason(reasons, "chain_deferred")
        elseif isPayload(slot) and opcode == "Multicast" then
            result.has_multicast_payload = true
        elseif isPayload(slot) and (opcode == "Spread" or opcode == "Burst") then
            result.has_pattern_payload = true
        elseif isPayload(slot) and opcode == "Speed+" then
            result.has_speed_plus_payload = true
        elseif isPayload(slot) and opcode == "Size+" then
            result.has_size_plus_payload = true
        elseif isPayload(slot) and opcode == "Homing" then
            result.has_homing_payload = true
        end
    end

    for _, op in ipairs(slot.postfix_ops or {}) do
        local opcode = op and op.opcode
        if not ALLOWED_POSTFIX_OPS[opcode] then
            addReason(reasons, "unsupported_postfix_" .. tostring(opcode))
        end
    end
end

local function auditEffects(slot, reasons)
    for _, effect in ipairs(slot.effects or {}) do
        local effect_id = effect and effect.id and string.lower(tostring(effect.id)) or nil
        if type(effect_id) == "string" and string.sub(effect_id, 1, 11) == "spellforge_" then
            addReason(reasons, "unsupported_spellforge_effect_" .. effect_id)
        end
    end
end

local function warningShowsDepthCap(warning)
    local message = warning and warning.message and tostring(warning.message) or ""
    return string.find(message, "payload depth exceeded", 1, true) ~= nil
end

function nested_payload_audit.inspectPlan(plan, opts)
    local options = opts or {}
    local depth_cap = tonumber(options.max_depth or limits.MAX_NESTED_PAYLOAD_DEPTH) or limits.MAX_RECURSION_DEPTH
    local job_cap = tonumber(options.max_jobs or limits.MAX_NESTED_PAYLOAD_JOBS) or limits.MAX_PROJECTILES_PER_CAST
    local projectile_cap = tonumber(options.max_projectiles or limits.MAX_PROJECTILES_PER_CAST) or limits.MAX_PROJECTILES_PER_CAST
    local fanout_cap = tonumber(options.max_fanout or limits.MAX_NESTED_PAYLOAD_FANOUT) or limits.MAX_PROJECTILES_PER_CAST
    local reasons = {}

    local result = {
        ok = false,
        mode = "nested_payload_audit",
        live_runtime_enabled = false,
        audit_only = true,
        recipe_id = plan and plan.recipe_id or nil,
        plan_recipe_id = plan and plan.recipe_id or nil,
        slot_count = 0,
        helper_count = 0,
        group_count = plan and plan.bounds and plan.bounds.group_count or countList(plan and plan.groups),
        primary_emission_count = 0,
        payload_emission_count = 0,
        trigger_source_count = 0,
        timer_source_count = 0,
        trigger_payload_count = 0,
        timer_payload_count = 0,
        nested_payload_count = 0,
        max_payload_depth = 0,
        max_fanout = 1,
        estimated_total_jobs = 0,
        estimated_immediate_jobs = 0,
        estimated_async_timer_jobs = 0,
        estimated_trigger_hit_jobs = 0,
        has_multicast_payload = false,
        has_pattern_payload = false,
        has_timer_payload = false,
        has_trigger_payload = false,
        has_speed_plus_payload = false,
        has_size_plus_payload = false,
        has_homing_payload = false,
        has_chain = plan and plan.bounds and plan.bounds.has_chain == true or false,
        exceeds_projectile_cap = false,
        exceeds_depth_cap = false,
        exceeds_job_cap = false,
        exceeds_fanout_cap = false,
        unsupported_reasons = {},
        rejection_reason = nil,
        live_safe_under_current_limits = false,
        future_runtime_candidate = false,
    }

    if type(plan) ~= "table" then
        addReason(reasons, "missing_plan")
        result.unsupported_reasons = sortedReasons(reasons)
        result.rejection_reason = firstReason(result.unsupported_reasons)
        return result
    end

    local slots, warnings, allocation_errors = ensureSlots(plan, options)
    if allocation_errors then
        for _, err in ipairs(allocation_errors or {}) do
            addReason(reasons, err and err.message or "slot_allocation_failed")
        end
        result.unsupported_reasons = sortedReasons(reasons)
        result.rejection_reason = firstReason(result.unsupported_reasons)
        return result
    end

    if type(slots) ~= "table" then
        slots = {}
    end
    result.slot_count = #slots
    result.helper_count = ensureHelperCount(plan, slots, options)
    result.estimated_total_jobs = #slots

    local by_slot_id = {}
    for _, slot in ipairs(slots) do
        if type(slot.slot_id) == "string" then
            by_slot_id[slot.slot_id] = slot
        end
    end

    local child_counts = countChildrenByParent(slots)
    local depth_cache = {}
    for _, slot in ipairs(slots) do
        auditOps(slot, reasons, result, options)
        auditEffects(slot, reasons)

        local primary = isPrimary(slot)
        local payload = isPayload(slot)
        if primary then
            result.primary_emission_count = result.primary_emission_count + 1
        end
        if payload then
            result.payload_emission_count = result.payload_emission_count + 1
        end
        if hasOpcode(slot.postfix_ops, "Trigger") then
            result.trigger_source_count = result.trigger_source_count + 1
        end
        if hasOpcode(slot.postfix_ops, "Timer") then
            result.timer_source_count = result.timer_source_count + 1
        end
        if slot.source_postfix_opcode == "Trigger" then
            result.trigger_payload_count = result.trigger_payload_count + 1
        elseif slot.source_postfix_opcode == "Timer" then
            result.timer_payload_count = result.timer_payload_count + 1
        end
        if payload and (hasAnyPayloadBinding(slot) or hasOpcode(slot.postfix_ops, "Trigger") or hasOpcode(slot.postfix_ops, "Timer")) then
            result.nested_payload_count = result.nested_payload_count + 1
        end

        local depth = slotDepth(slot, by_slot_id, {}, depth_cache, reasons)
        if payload and depth > result.max_payload_depth then
            result.max_payload_depth = depth
        end
    end

    for _, warning in ipairs(warnings or {}) do
        if warningShowsDepthCap(warning) then
            result.exceeds_depth_cap = true
            result.max_payload_depth = math.max(result.max_payload_depth, depth_cap + 1)
            addReason(reasons, "exceeds_depth_cap")
        end
    end

    for _, count in pairs(child_counts) do
        if count > result.max_fanout then
            result.max_fanout = count
        end
    end
    if result.primary_emission_count > result.max_fanout then
        result.max_fanout = result.primary_emission_count
    end

    result.estimated_immediate_jobs = result.primary_emission_count
    result.estimated_async_timer_jobs = result.timer_payload_count
    result.estimated_trigger_hit_jobs = result.trigger_payload_count
    result.has_timer_payload = result.timer_payload_count > 0
    result.has_trigger_payload = result.trigger_payload_count > 0

    result.exceeds_projectile_cap = result.estimated_total_jobs > projectile_cap
    result.exceeds_job_cap = result.estimated_total_jobs > job_cap
    result.exceeds_depth_cap = result.exceeds_depth_cap or result.max_payload_depth > depth_cap
    result.exceeds_fanout_cap = result.max_fanout > fanout_cap

    if result.exceeds_projectile_cap then
        addReason(reasons, "exceeds_projectile_cap")
    end
    if result.exceeds_job_cap then
        addReason(reasons, "exceeds_job_cap")
    end
    if result.exceeds_depth_cap then
        addReason(reasons, "exceeds_depth_cap")
    end
    if result.exceeds_fanout_cap then
        addReason(reasons, "exceeds_fanout_cap")
    end
    if result.has_chain then
        addReason(reasons, "chain_deferred")
    end

    local simple_v0 = result.payload_emission_count == 1
        and result.nested_payload_count == 0
        and result.max_payload_depth == 1
        and result.has_multicast_payload == false
        and result.has_pattern_payload == false
        and result.has_speed_plus_payload == false
        and result.has_size_plus_payload == false
        and result.has_homing_payload == false
        and result.has_chain == false
        and ((result.timer_source_count == 1 and result.timer_payload_count == 1 and result.trigger_source_count == 0 and result.trigger_payload_count == 0)
            or (result.trigger_source_count == 1 and result.trigger_payload_count == 1 and result.timer_source_count == 0 and result.timer_payload_count == 0))

    result.unsupported_reasons = sortedReasons(reasons)
    result.rejection_reason = firstReason(result.unsupported_reasons)
    result.live_safe_under_current_limits = result.rejection_reason == nil
    result.future_runtime_candidate = result.live_safe_under_current_limits
        and result.payload_emission_count > 0
        and not simple_v0
    result.ok = result.live_safe_under_current_limits

    return result
end

return nested_payload_audit
