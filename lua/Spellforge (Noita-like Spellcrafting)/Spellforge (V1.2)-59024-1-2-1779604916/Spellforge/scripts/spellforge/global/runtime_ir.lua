local runtime_ir = {}

runtime_ir.VERSION = "spellforge-runtime-ir-v1"

local function cloneParams(params)
    local out = {}
    if type(params) ~= "table" then
        return out
    end
    local keys = {}
    for key in pairs(params) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    for _, key in ipairs(keys) do
        out[key] = params[key]
    end
    return out
end

local function cloneEffect(effect)
    if type(effect) ~= "table" then
        return { id = tostring(effect) }
    end
    local out = {}
    for key, value in pairs(effect) do
        if type(value) == "table" and key == "params" then
            out[key] = cloneParams(value)
        else
            out[key] = value
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

local function cloneOp(op)
    if type(op) ~= "table" then
        return {}
    end
    return {
        opcode = op.opcode,
        effect_id = op.effect_id,
        params = cloneParams(op.params),
        index = op.index,
        payload_scope = op.payload_scope,
    }
end

local function cloneOps(ops)
    local out = {}
    for i, op in ipairs(ops or {}) do
        out[i] = cloneOp(op)
    end
    return out
end

local function clonePayloadBindings(bindings)
    local out = {}
    for i, binding in ipairs(bindings or {}) do
        out[i] = {
            source_opcode = binding.source_opcode,
            payload_scope = binding.payload_scope,
            planned_child_group_count = binding.planned_child_group_count,
            parse_ok = binding.parse_ok,
        }
    end
    return out
end

local function cloneBounds(bounds)
    local out = {}
    if type(bounds) ~= "table" then
        return out
    end
    for key, value in pairs(bounds) do
        out[key] = value
    end
    return out
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op.opcode == opcode then
            return true
        end
    end
    return false
end

local function firstOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op.opcode == opcode then
            return op
        end
    end
    return nil
end

local function multicastCount(ops)
    local count = 1
    for _, op in ipairs(ops or {}) do
        if op.opcode == "Multicast" then
            count = count * (tonumber(op.params and op.params.count) or 1)
        end
    end
    return count
end

local function fanoutFromPrefix(prefix_ops, emission_index)
    local fanout = {
        has_multicast = hasOpcode(prefix_ops, "Multicast"),
        has_spread = hasOpcode(prefix_ops, "Spread"),
        has_burst = hasOpcode(prefix_ops, "Burst"),
        multicast_count = multicastCount(prefix_ops),
        emission_index = emission_index,
    }
    fanout.has_pattern = fanout.has_spread == true or fanout.has_burst == true
    fanout.is_fanout = fanout.has_multicast == true or fanout.has_pattern == true
    fanout.is_copy = fanout.has_multicast == true and (tonumber(emission_index) or 1) > 1
    return fanout
end

local function tableCount(values)
    local count = 0
    for _ in pairs(values or {}) do
        count = count + 1
    end
    return count
end

local function sortedKeys(values)
    local keys = {}
    for key in pairs(values or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function helperMaps(plan)
    local by_slot = {}

    for _, spec in ipairs(plan.helper_specs or {}) do
        if type(spec) == "table" and type(spec.slot_id) == "string" and spec.slot_id ~= "" then
            by_slot[spec.slot_id] = by_slot[spec.slot_id] or {}
            by_slot[spec.slot_id].spec = spec
        end
    end

    for _, record in ipairs(plan.helper_records or {}) do
        if type(record) == "table" and type(record.slot_id) == "string" and record.slot_id ~= "" then
            by_slot[record.slot_id] = by_slot[record.slot_id] or {}
            by_slot[record.slot_id].record = record
        end
    end

    return by_slot
end

local function helperInfo(slot_id, helpers_by_slot)
    local helper = helpers_by_slot[slot_id] or {}
    local spec = helper.spec
    local record = helper.record
    return {
        helper_logical_id = (spec and spec.logical_id) or (record and record.logical_id) or nil,
        helper_engine_id = (record and record.engine_id) or (spec and spec.engine_record_id) or nil,
        helper_record_created = record ~= nil,
        helper_spec_present = spec ~= nil,
    }
end

local function slotMaps(slots)
    local by_id = {}
    for _, slot in ipairs(slots or {}) do
        if type(slot) == "table" and type(slot.slot_id) == "string" and slot.slot_id ~= "" then
            by_id[slot.slot_id] = slot
        end
    end
    return by_id
end

local function depthForSlot(slot, slots_by_id, memo, visiting)
    if type(slot) ~= "table" then
        return 0
    end
    local slot_id = slot.slot_id
    if type(slot_id) ~= "string" or slot_id == "" then
        return 0
    end
    if memo[slot_id] ~= nil then
        return memo[slot_id]
    end
    if visiting[slot_id] then
        memo[slot_id] = 0
        return 0
    end
    visiting[slot_id] = true
    local parent = slot.parent_slot_id and slots_by_id[slot.parent_slot_id] or nil
    local depth = parent and (depthForSlot(parent, slots_by_id, memo, visiting) + 1) or 0
    visiting[slot_id] = nil
    memo[slot_id] = depth
    return depth
end

local function entryForSlot(plan, slot, helpers_by_slot, slots_by_id, depth_memo)
    local helper = helperInfo(slot.slot_id, helpers_by_slot)
    local payload_depth = depthForSlot(slot, slots_by_id, depth_memo, {})
    local prefix_ops = cloneOps(slot.prefix_ops)
    local postfix_ops = cloneOps(slot.postfix_ops)
    local fanout = fanoutFromPrefix(prefix_ops, slot.emission_index)
    local entry_id = string.format("%s:entry:%s", tostring(plan.recipe_id), tostring(slot.slot_id))

    return {
        entry_id = entry_id,
        recipe_id = plan.recipe_id,
        slot_id = slot.slot_id,
        helper_engine_id = helper.helper_engine_id,
        helper_logical_id = helper.helper_logical_id,
        helper_record_created = helper.helper_record_created,
        helper_spec_present = helper.helper_spec_present,
        kind = slot.kind,
        group_index = slot.group_index,
        emission_index = slot.emission_index,
        range = slot.range,
        effects = cloneEffects(slot.effects),
        prefix_ops = prefix_ops,
        postfix_ops = postfix_ops,
        modifier_chain = cloneOps(slot.prefix_ops),
        postfix_chain = cloneOps(slot.postfix_ops),
        payload_bindings = clonePayloadBindings(slot.payload_bindings),
        parent_slot_id = slot.parent_slot_id,
        trigger_source_slot_id = slot.trigger_source_slot_id,
        timer_source_slot_id = slot.timer_source_slot_id,
        source_postfix_opcode = slot.source_postfix_opcode,
        source_helper_engine_id = slot.parent_slot_id and helperInfo(slot.parent_slot_id, helpers_by_slot).helper_engine_id or nil,
        payload_depth = payload_depth,
        fanout = fanout,
        continuation_ids = {},
    }
end

local function emitGroupKey(entry)
    return table.concat({
        tostring(entry.kind or "entry"),
        tostring(entry.parent_slot_id or "root"),
        tostring(entry.source_postfix_opcode or "primary"),
        tostring(entry.group_index or "0"),
    }, "|")
end

local function buildEmitGroups(entries)
    local groups_by_key = {}
    local ordered = {}
    for _, entry in ipairs(entries or {}) do
        local key = emitGroupKey(entry)
        local group = groups_by_key[key]
        if not group then
            group = {
                emit_group_id = "emit:" .. tostring(#ordered + 1),
                kind = entry.parent_slot_id and "payload" or "primary",
                parent_slot_id = entry.parent_slot_id,
                source_postfix_opcode = entry.source_postfix_opcode,
                group_index = entry.group_index,
                slot_ids = {},
                entry_ids = {},
                fanout = {
                    has_multicast = false,
                    has_pattern = false,
                    has_spread = false,
                    has_burst = false,
                    static_count = 0,
                },
            }
            groups_by_key[key] = group
            ordered[#ordered + 1] = group
        end
        group.slot_ids[#group.slot_ids + 1] = entry.slot_id
        group.entry_ids[#group.entry_ids + 1] = entry.entry_id
        group.fanout.static_count = group.fanout.static_count + 1
        group.fanout.has_multicast = group.fanout.has_multicast or entry.fanout.has_multicast
        group.fanout.has_pattern = group.fanout.has_pattern or entry.fanout.has_pattern
        group.fanout.has_spread = group.fanout.has_spread or entry.fanout.has_spread
        group.fanout.has_burst = group.fanout.has_burst or entry.fanout.has_burst
    end
    return ordered
end

local function continuationParams(op)
    return op and cloneParams(op.params) or {}
end

local function childEntriesBySource(entries)
    local by_source = {}
    for _, entry in ipairs(entries or {}) do
        if entry.parent_slot_id then
            local key = tostring(entry.parent_slot_id) .. "|" .. tostring(entry.source_postfix_opcode or "Payload")
            by_source[key] = by_source[key] or {}
            by_source[key][#by_source[key] + 1] = entry
        end
    end
    return by_source
end

local function addContinuation(out, entries_by_id, entry, kind, op, payload_entries)
    local continuation_id = string.format("%s:cont:%s:%s", tostring(entry.recipe_id), tostring(entry.slot_id), tostring(kind))
    local continuation = {
        continuation_id = continuation_id,
        kind = kind,
        recipe_id = entry.recipe_id,
        source_entry_id = entry.entry_id,
        source_slot_id = entry.slot_id,
        source_helper_engine_id = entry.helper_engine_id,
        parent_slot_id = entry.parent_slot_id,
        source_postfix_opcode = entry.source_postfix_opcode,
        prefix_ops = cloneOps(entry.prefix_ops),
        postfix_ops = cloneOps(entry.postfix_ops),
        params = continuationParams(op),
        branch_scope = string.format("%s:%s:%s", tostring(entry.recipe_id), tostring(entry.slot_id), tostring(kind)),
        payload_slot_ids = {},
        payload_entry_ids = {},
        static_bounds = {
            payload_count = 0,
            payload_fanout_count = 0,
            max_payload_depth = entry.payload_depth or 0,
        },
    }

    for _, payload_entry in ipairs(payload_entries or {}) do
        continuation.payload_slot_ids[#continuation.payload_slot_ids + 1] = payload_entry.slot_id
        continuation.payload_entry_ids[#continuation.payload_entry_ids + 1] = payload_entry.entry_id
        continuation.static_bounds.payload_count = continuation.static_bounds.payload_count + 1
        if payload_entry.fanout and payload_entry.fanout.is_fanout then
            continuation.static_bounds.payload_fanout_count = continuation.static_bounds.payload_fanout_count + 1
        end
        if (payload_entry.payload_depth or 0) > continuation.static_bounds.max_payload_depth then
            continuation.static_bounds.max_payload_depth = payload_entry.payload_depth
        end
    end

    out[#out + 1] = continuation
    entry.continuation_ids[#entry.continuation_ids + 1] = continuation_id
    entries_by_id[entry.entry_id] = entry
    return continuation
end

local function addPrefixContinuation(out, entries_by_id, entry, kind)
    local op = firstOpcode(entry.prefix_ops, kind)
    if not op then
        return nil
    end
    return addContinuation(out, entries_by_id, entry, kind, op, {})
end

local function buildContinuations(entries, entries_by_id)
    local continuations = {}
    local children = childEntriesBySource(entries)
    for _, entry in ipairs(entries or {}) do
        local trigger = firstOpcode(entry.postfix_ops, "Trigger")
        if trigger then
            local key = tostring(entry.slot_id) .. "|Trigger"
            addContinuation(continuations, entries_by_id, entry, "Trigger", trigger, children[key] or {})
        end

        local timer = firstOpcode(entry.postfix_ops, "Timer")
        if timer then
            local key = tostring(entry.slot_id) .. "|Timer"
            addContinuation(continuations, entries_by_id, entry, "Timer", timer, children[key] or {})
        end

        addPrefixContinuation(continuations, entries_by_id, entry, "Bounce")
        addPrefixContinuation(continuations, entries_by_id, entry, "Pierce")
        addPrefixContinuation(continuations, entries_by_id, entry, "Chain")
    end
    return continuations
end

local function buildScopes(plan, entries)
    local scopes = {
        {
            scope_id = tostring(plan.recipe_id) .. ":scope:root",
            kind = "root",
            parent_slot_id = nil,
            source_postfix_opcode = nil,
            entry_ids = {},
            slot_ids = {},
        },
    }
    local by_key = { root = scopes[1] }

    for _, entry in ipairs(entries or {}) do
        local key = entry.parent_slot_id
            and (tostring(entry.parent_slot_id) .. "|" .. tostring(entry.source_postfix_opcode or "Payload"))
            or "root"
        local scope = by_key[key]
        if not scope then
            scope = {
                scope_id = string.format("%s:scope:%s:%s", tostring(plan.recipe_id), tostring(entry.parent_slot_id), tostring(entry.source_postfix_opcode or "Payload")),
                kind = "payload",
                parent_slot_id = entry.parent_slot_id,
                source_postfix_opcode = entry.source_postfix_opcode,
                entry_ids = {},
                slot_ids = {},
            }
            by_key[key] = scope
            scopes[#scopes + 1] = scope
        end
        scope.entry_ids[#scope.entry_ids + 1] = entry.entry_id
        scope.slot_ids[#scope.slot_ids + 1] = entry.slot_id
    end

    return scopes
end

local function countContinuationsByKind(continuations)
    local counts = {}
    for _, continuation in ipairs(continuations or {}) do
        local kind = continuation.kind or "unknown"
        counts[kind] = (counts[kind] or 0) + 1
    end
    return counts
end

local function summarizeCounts(plan, entries, emit_groups, continuations)
    local counts = {
        group_count = #(plan.groups or {}),
        slot_count = #(plan.emission_slots or {}),
        helper_spec_count = #(plan.helper_specs or {}),
        helper_record_count = #(plan.helper_records or {}),
        entry_count = #entries,
        emit_group_count = #emit_groups,
        continuation_count = #continuations,
        primary_emit_count = 0,
        payload_emit_count = 0,
        fanout_entry_count = 0,
        max_payload_depth = 0,
        continuations_by_kind = countContinuationsByKind(continuations),
    }

    for _, entry in ipairs(entries or {}) do
        if entry.kind == "payload_emission" then
            counts.payload_emit_count = counts.payload_emit_count + 1
        else
            counts.primary_emit_count = counts.primary_emit_count + 1
        end
        if entry.fanout and entry.fanout.is_fanout then
            counts.fanout_entry_count = counts.fanout_entry_count + 1
        end
        if (entry.payload_depth or 0) > counts.max_payload_depth then
            counts.max_payload_depth = entry.payload_depth
        end
    end

    return counts
end

function runtime_ir.build(plan, opts)
    local options = opts or {}
    local warnings = {}
    if type(plan) ~= "table" then
        return {
            ok = false,
            errors = { { code = "runtime_ir_plan_required", message = "plan must be a table" } },
            warnings = warnings,
        }
    end
    if type(plan.recipe_id) ~= "string" or plan.recipe_id == "" then
        return {
            ok = false,
            errors = { { code = "runtime_ir_recipe_id_required", message = "plan.recipe_id must be a non-empty string" } },
            warnings = warnings,
        }
    end
    if type(plan.groups) ~= "table" then
        warnings[#warnings + 1] = { code = "runtime_ir_groups_missing", message = "plan.groups missing; IR will only reflect slots" }
    end
    if type(plan.emission_slots) ~= "table" then
        warnings[#warnings + 1] = { code = "runtime_ir_slots_missing", message = "plan.emission_slots missing; no runtime entries produced" }
    end

    local slots = plan.emission_slots or {}
    local slots_by_id = slotMaps(slots)
    local helpers_by_slot = helperMaps(plan)
    local depth_memo = {}
    local entries = {}
    local entries_by_id = {}
    local entries_by_slot_id = {}

    for _, slot in ipairs(slots) do
        if type(slot) == "table" and type(slot.slot_id) == "string" and slot.slot_id ~= "" then
            local entry = entryForSlot(plan, slot, helpers_by_slot, slots_by_id, depth_memo)
            entries[#entries + 1] = entry
            entries_by_id[entry.entry_id] = entry
            entries_by_slot_id[entry.slot_id] = entry
        end
    end

    local emit_groups = buildEmitGroups(entries)
    local continuations = buildContinuations(entries, entries_by_id)
    local continuations_by_id = {}
    for _, continuation in ipairs(continuations) do
        continuations_by_id[continuation.continuation_id] = continuation
    end

    local scopes = buildScopes(plan, entries)
    local counts = summarizeCounts(plan, entries, emit_groups, continuations)

    if options.include_group_snapshots == true then
        counts.group_snapshot_count = tableCount(plan.groups or {})
    end

    return {
        ok = true,
        version = runtime_ir.VERSION,
        recipe_id = plan.recipe_id,
        source_kind = plan.source_kind,
        canonical_version = plan.canonical_version,
        bounds = cloneBounds(plan.bounds),
        static_bounds = {
            group_count = counts.group_count,
            slot_count = counts.slot_count,
            helper_spec_count = counts.helper_spec_count,
            helper_record_count = counts.helper_record_count,
            entry_count = counts.entry_count,
            emit_group_count = counts.emit_group_count,
            continuation_count = counts.continuation_count,
            primary_emit_count = counts.primary_emit_count,
            payload_emit_count = counts.payload_emit_count,
            fanout_entry_count = counts.fanout_entry_count,
            max_payload_depth = counts.max_payload_depth,
            max_projectiles = plan.bounds and plan.bounds.max_projectiles or nil,
        },
        counts = counts,
        scopes = scopes,
        entries = entries,
        entries_by_id = entries_by_id,
        entries_by_slot_id = entries_by_slot_id,
        emit_groups = emit_groups,
        continuations = continuations,
        continuations_by_id = continuations_by_id,
        warnings = warnings,
    }
end

local function appendInvariantError(errors, code, message, details)
    errors[#errors + 1] = {
        code = code,
        message = message,
        details = details,
    }
end

local function paramsSignature(params)
    local keys = sortedKeys(params or {})
    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(params[key])
    end
    return table.concat(parts, ",")
end

local function opsSignature(ops)
    local parts = {}
    for _, op in ipairs(ops or {}) do
        parts[#parts + 1] = table.concat({
            tostring(op.opcode or ""),
            tostring(op.effect_id or ""),
            paramsSignature(op.params),
            tostring(op.index or ""),
            tostring(op.payload_scope or ""),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function logicalGroupKeyForEntry(entry)
    return table.concat({
        tostring(entry.parent_slot_id or "root"),
        tostring(entry.source_postfix_opcode or "primary"),
        tostring(entry.group_index or "0"),
    }, "|")
end

local function scopeKey(scope)
    return table.concat({
        tostring(scope.parent_slot_id or "root"),
        tostring(scope.source_postfix_opcode or "primary"),
    }, "|")
end

function runtime_ir.validateInvariants(ir, opts)
    local options = opts or {}
    local errors = {}
    local warnings = {}
    if type(ir) ~= "table" then
        appendInvariantError(errors, "runtime_ir_required", "runtime IR must be a table")
        return {
            ok = false,
            errors = errors,
            warnings = warnings,
        }
    end

    local entries = ir.entries or {}
    local entries_by_slot = {}
    local entries_by_entry = {}
    for _, entry in ipairs(entries) do
        if type(entry.slot_id) ~= "string" or entry.slot_id == "" then
            appendInvariantError(errors, "runtime_ir_entry_slot_id_missing", "entry has no slot_id", {
                entry_id = entry.entry_id,
            })
        elseif entries_by_slot[entry.slot_id] then
            appendInvariantError(errors, "runtime_ir_duplicate_slot_id", "duplicate slot_id in IR entries", {
                slot_id = entry.slot_id,
            })
        else
            entries_by_slot[entry.slot_id] = entry
        end

        if type(entry.entry_id) ~= "string" or entry.entry_id == "" then
            appendInvariantError(errors, "runtime_ir_entry_id_missing", "entry has no entry_id", {
                slot_id = entry.slot_id,
            })
        elseif entries_by_entry[entry.entry_id] then
            appendInvariantError(errors, "runtime_ir_duplicate_entry_id", "duplicate entry_id in IR entries", {
                entry_id = entry.entry_id,
            })
        else
            entries_by_entry[entry.entry_id] = entry
        end
    end

    local counts = ir.counts or {}
    if counts.slot_count ~= nil and tonumber(counts.slot_count) ~= #entries then
        appendInvariantError(errors, "runtime_ir_slot_entry_count_mismatch", "slot_count must match IR entry count", {
            slot_count = counts.slot_count,
            entry_count = #entries,
        })
    end
    if (tonumber(counts.helper_spec_count) or 0) > 0 and tonumber(counts.helper_spec_count) ~= #entries then
        appendInvariantError(errors, "runtime_ir_helper_spec_entry_count_mismatch", "helper_spec_count must match IR entry count when helper specs are present", {
            helper_spec_count = counts.helper_spec_count,
            entry_count = #entries,
        })
    end

    local scope_keys = {}
    for _, scope in ipairs(ir.scopes or {}) do
        scope_keys[scopeKey(scope)] = true
    end

    local continuation_ids = {}
    local continuations_by_source_kind = {}
    for _, continuation in ipairs(ir.continuations or {}) do
        local continuation_id = continuation.continuation_id
        if type(continuation_id) ~= "string" or continuation_id == "" then
            appendInvariantError(errors, "runtime_ir_continuation_id_missing", "continuation has no continuation_id", {
                source_slot_id = continuation.source_slot_id,
                kind = continuation.kind,
            })
        elseif continuation_ids[continuation_id] then
            appendInvariantError(errors, "runtime_ir_duplicate_continuation_id", "duplicate continuation_id", {
                continuation_id = continuation_id,
            })
        else
            continuation_ids[continuation_id] = true
        end

        if not entries_by_entry[continuation.source_entry_id] then
            appendInvariantError(errors, "runtime_ir_continuation_source_missing", "continuation source_entry_id does not exist", {
                continuation_id = continuation_id,
                source_entry_id = continuation.source_entry_id,
            })
        end
        if not entries_by_slot[continuation.source_slot_id] then
            appendInvariantError(errors, "runtime_ir_continuation_source_slot_missing", "continuation source_slot_id does not exist", {
                continuation_id = continuation_id,
                source_slot_id = continuation.source_slot_id,
            })
        end

        local source_kind_key = tostring(continuation.source_slot_id) .. "|" .. tostring(continuation.kind)
        continuations_by_source_kind[source_kind_key] = true

        if #(continuation.payload_entry_ids or {}) > 0 then
            local target_scope_key = tostring(continuation.source_slot_id) .. "|" .. tostring(continuation.kind)
            if not scope_keys[target_scope_key] then
                appendInvariantError(errors, "runtime_ir_continuation_target_scope_missing", "continuation payload target scope does not exist", {
                    continuation_id = continuation_id,
                    target_scope_key = target_scope_key,
                })
            end
        end

        for _, payload_entry_id in ipairs(continuation.payload_entry_ids or {}) do
            local payload_entry = entries_by_entry[payload_entry_id]
            if not payload_entry then
                appendInvariantError(errors, "runtime_ir_continuation_payload_entry_missing", "continuation payload entry does not exist", {
                    continuation_id = continuation_id,
                    payload_entry_id = payload_entry_id,
                })
            elseif tostring(payload_entry.parent_slot_id) ~= tostring(continuation.source_slot_id)
                or tostring(payload_entry.source_postfix_opcode) ~= tostring(continuation.kind) then
                appendInvariantError(errors, "runtime_ir_continuation_payload_entry_mismatch", "continuation payload entry does not point back to source continuation", {
                    continuation_id = continuation_id,
                    payload_entry_id = payload_entry_id,
                    parent_slot_id = payload_entry.parent_slot_id,
                    source_postfix_opcode = payload_entry.source_postfix_opcode,
                })
            end
        end

        for _, payload_slot_id in ipairs(continuation.payload_slot_ids or {}) do
            if not entries_by_slot[payload_slot_id] then
                appendInvariantError(errors, "runtime_ir_continuation_payload_slot_missing", "continuation payload slot does not exist", {
                    continuation_id = continuation_id,
                    payload_slot_id = payload_slot_id,
                })
            end
        end
    end

    for _, entry in ipairs(entries) do
        if entry.parent_slot_id then
            if not entries_by_slot[entry.parent_slot_id] then
                appendInvariantError(errors, "runtime_ir_payload_parent_missing", "payload entry parent_slot_id does not exist", {
                    entry_id = entry.entry_id,
                    slot_id = entry.slot_id,
                    parent_slot_id = entry.parent_slot_id,
                })
            else
                local seen = {}
                local current = entry
                while current and current.parent_slot_id do
                    if seen[current.slot_id] then
                        appendInvariantError(errors, "runtime_ir_payload_parent_cycle", "payload parent chain has a cycle", {
                            entry_id = entry.entry_id,
                            slot_id = entry.slot_id,
                        })
                        break
                    end
                    seen[current.slot_id] = true
                    current = entries_by_slot[current.parent_slot_id]
                end
            end

            if entry.source_postfix_opcode == nil or entry.source_postfix_opcode == "" then
                appendInvariantError(errors, "runtime_ir_payload_source_opcode_missing", "payload entry has no source_postfix_opcode", {
                    entry_id = entry.entry_id,
                    slot_id = entry.slot_id,
                    parent_slot_id = entry.parent_slot_id,
                })
            elseif entry.source_postfix_opcode == "Trigger" or entry.source_postfix_opcode == "Timer" then
                local source_kind_key = tostring(entry.parent_slot_id) .. "|" .. tostring(entry.source_postfix_opcode)
                if not continuations_by_source_kind[source_kind_key] then
                    appendInvariantError(errors, "runtime_ir_orphan_payload_entry", "payload entry has no matching source continuation", {
                        entry_id = entry.entry_id,
                        slot_id = entry.slot_id,
                        parent_slot_id = entry.parent_slot_id,
                        source_postfix_opcode = entry.source_postfix_opcode,
                    })
                end
            end
        end
    end

    local groups = {}
    for _, entry in ipairs(entries) do
        local key = logicalGroupKeyForEntry(entry)
        local prefix_sig = opsSignature(entry.prefix_ops)
        local postfix_sig = opsSignature(entry.postfix_ops)
        local group = groups[key]
        if not group then
            groups[key] = {
                prefix_sig = prefix_sig,
                postfix_sig = postfix_sig,
                first_slot_id = entry.slot_id,
            }
        elseif group.prefix_sig ~= prefix_sig or group.postfix_sig ~= postfix_sig then
            appendInvariantError(errors, "runtime_ir_logical_group_mixed_chains", "logical group mixes incompatible prefix/postfix chains", {
                group_key = key,
                first_slot_id = group.first_slot_id,
                slot_id = entry.slot_id,
            })
        end
    end

    if options.require_helper_specs == true and tonumber(counts.helper_spec_count) ~= #entries then
        appendInvariantError(errors, "runtime_ir_required_helper_specs_missing", "required helper specs are missing or incomplete", {
            helper_spec_count = counts.helper_spec_count,
            entry_count = #entries,
        })
    end

    return {
        ok = #errors == 0,
        errors = errors,
        warnings = warnings,
    }
end

function runtime_ir.kindSummary(counts)
    local by_kind = counts and counts.continuations_by_kind or {}
    local keys = sortedKeys(by_kind)
    if #keys == 0 then
        return "none"
    end
    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(by_kind[key])
    end
    return table.concat(parts, ",")
end

return runtime_ir
