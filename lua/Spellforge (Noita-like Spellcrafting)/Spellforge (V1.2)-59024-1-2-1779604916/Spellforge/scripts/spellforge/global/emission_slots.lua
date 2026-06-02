local limits = require("scripts.spellforge.shared.limits")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local parser = require("scripts.spellforge.global.parser")
local validation = require("scripts.spellforge.shared.validation_contract")
local log = require("scripts.spellforge.shared.log").new("global.emission_slots")

local emission_slots = {}
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

local function isSummonEffect(effect)
    return effect_registry.isSummonEffect(effect)
end

local function splitEffectsForSummonSources(effects)
    local batches = {}
    local pending = {}

    local function flushPending()
        if #pending == 0 then
            return
        end
        batches[#batches + 1] = {
            effects = pending,
            is_summon_source = false,
        }
        pending = {}
    end

    for _, effect in ipairs(effects or {}) do
        local cloned = cloneEffect(effect)
        if isSummonEffect(cloned) then
            flushPending()
            batches[#batches + 1] = {
                effects = { cloned },
                is_summon_source = true,
            }
        else
            pending[#pending + 1] = cloned
        end
    end

    flushPending()

    if #batches == 0 then
        batches[1] = {
            effects = cloneEffects(effects),
            is_summon_source = false,
        }
    end

    return batches
end

local function cloneOps(ops)
    local out = {}
    for i, op in ipairs(ops or {}) do
        out[i] = {
            opcode = op.opcode,
            effect_id = op.effect_id,
            params = cloneParams(op.params),
            index = op.index,
            payload_scope = op.payload_scope,
        }
    end
    return out
end

local function countMulticast(prefix_ops)
    local count = 1
    for _, op in ipairs(prefix_ops or {}) do
        if op.opcode == "Multicast" then
            count = count * (op.params and op.params.count or 1)
        end
    end
    return count
end

local function appendError(errors, path, message, code, details)
    errors[#errors + 1] = validation.error(path, message, code, details)
end

local function hasPostfix(group, opcode)
    for _, op in ipairs(group.postfix_ops or {}) do
        if op.opcode == opcode then
            return true
        end
    end
    return false
end

local function hasPrefix(group, opcode)
    for _, op in ipairs(group.prefix_ops or {}) do
        if op.opcode == opcode then
            return true
        end
    end
    return false
end

local function parsePayloadGroups(payload_effects, opts)
    local payload_parse = parser.parseContinuationPayloadEffectList(payload_effects, opts)
    if payload_parse.ok then
        log.info(string.format(
            "SPELLFORGE_PAYLOAD_PARSE_CONTEXT_OK source=emission_slots payload_effect_count=%s payload_group_count=%s fanout_context=%s allow_non_target_payload_multicast=%s",
            tostring(#(payload_effects or {})),
            tostring(#(payload_parse.groups or {})),
            tostring(payload_parse.fanout_context),
            tostring(payload_parse.allow_non_target_payload_multicast == true)
        ))
        return payload_parse.groups, nil
    end
    return nil, payload_parse.errors
end

local function appendFatalPayloadParseErrors(errors, group_index, payload_errors)
    local appended = false
    for _, issue in ipairs(payload_errors or {}) do
        local code = issue and issue.code
        if code == "fanout_requires_target_range"
            or code == "detonate_requires_payload_context"
            or code == "detonate_requires_target_range"
            or code == "detonate_requires_area"
            or code == "detonate_modifier_combo_deferred"
            or code == "detonate_nested_continuation_unsupported" then
            local cloned = validation.cloneIssue(issue, "error")
            local child_path = tostring(cloned.path or "")
            if child_path ~= "" then
                cloned.path = string.format("groups[%d].payload.%s", group_index, child_path)
            else
                cloned.path = string.format("groups[%d].payload", group_index)
            end
            errors[#errors + 1] = cloned
            appended = true
        end
    end
    return appended
end

function emission_slots.allocate(plan, opts)
    local options = opts or {}
    local max_slots = (options.limits and options.limits.MAX_PROJECTILES_PER_CAST) or limits.MAX_PROJECTILES_PER_CAST
    local max_summon_sources = (options.limits and options.limits.MAX_SUMMON_SOURCES_PER_SPELL)
        or limits.MAX_SUMMON_SOURCES_PER_SPELL
        or 3
    local warnings = {}
    local errors = {}

    if type(plan) ~= "table" then
        appendError(errors, "plan", "plan must be a table", "plan_not_table")
        return { ok = false, errors = errors, warnings = warnings }
    end
    if type(plan.recipe_id) ~= "string" or plan.recipe_id == "" then
        appendError(errors, "plan.recipe_id", "plan.recipe_id must be a non-empty string", "plan_recipe_id_required")
    end
    if type(plan.groups) ~= "table" then
        appendError(errors, "plan.groups", "plan.groups must be an array", "plan_groups_not_array")
    end
    if type(plan.parse_result) == "table" and plan.parse_result.ok == false then
        appendError(errors, "plan.parse_result", "plan.parse_result.ok is false", "plan_parse_failed")
    end
    if #errors > 0 then
        return { ok = false, errors = errors, warnings = warnings }
    end

    local slots = {}
    local slot_counter = 0
    local summon_source_count = 0

    local function nextSlotId()
        slot_counter = slot_counter + 1
        return string.format("%s:s%d", plan.recipe_id, slot_counter)
    end

    local function nextSummonSourceOrdinal(path)
        summon_source_count = summon_source_count + 1
        if summon_source_count > max_summon_sources then
            appendError(
                errors,
                path,
                string.format("Spellforge summon limit exceeded: max %d summon sources per spell", max_summon_sources),
                "summon_source_cap_exceeded",
                {
                    limit = max_summon_sources,
                    count = summon_source_count,
                }
            )
            log.info(string.format(
                "SPELLFORGE_SUMMON_LIMIT_EXCEEDED recipe_id=%s count=%s max=%s",
                tostring(plan.recipe_id),
                tostring(summon_source_count),
                tostring(max_summon_sources)
            ))
            return nil
        end
        return summon_source_count
    end

    local function ensureCap(next_count, path)
        if next_count > max_slots then
            appendError(errors, path, string.format("Slot count exceeds MAX_PROJECTILES_PER_CAST (%d)", max_slots), "slot_cap_exceeded", {
                limit = max_slots,
                count = next_count,
            })
            return false
        end
        return true
    end

    local max_live_depth = tonumber(options.max_live_nested_continuation_depth or options.max_nested_payload_depth)
        or limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH
        or 3

    local function allocateGroups(groups, parent_slot_id, source_slot_id, source_opcode, depth)
        if depth > max_live_depth then
            appendError(errors, "slots", string.format("Nested continuation depth exceeds supported live depth (%d)", max_live_depth), "nested_depth_exceeded", {
                limit = max_live_depth,
                depth = depth,
            })
            return
        end

        for group_index, group in ipairs(groups or {}) do
            local emission_count = group.emission_count_static or countMulticast(group.prefix_ops)
            local emission_count_number = tonumber(emission_count) or 1
            local effect_batches = splitEffectsForSummonSources(group.effects)

            if hasPrefix(group, "Chain") then
                warnings[#warnings + 1] = {
                    path = string.format("groups[%d]", group_index),
                    message = "Chain metadata preserved only; chain runtime fanout is not implemented in slot allocator",
                }
            end

            for emission_index = 1, emission_count_number do
                for batch_index, batch in ipairs(effect_batches) do
                    if not ensureCap(#slots + 1, "slots") then
                        return
                    end

                    local summon_source_ordinal = nil
                    if batch.is_summon_source == true then
                        summon_source_ordinal = nextSummonSourceOrdinal(string.format("groups[%d].effects", group_index))
                        if summon_source_ordinal == nil then
                            return
                        end
                    end

                    local slot_id = nextSlotId()
                    local slot = {
                        slot_id = slot_id,
                        recipe_id = plan.recipe_id,
                        group_index = group_index,
                        emission_index = emission_index,
                        effect_batch_index = batch_index,
                        kind = parent_slot_id and "payload_emission" or "primary_emission",
                        range = group.range,
                        effects = cloneEffects(batch.effects),
                        prefix_ops = cloneOps(group.prefix_ops),
                        postfix_ops = cloneOps(group.postfix_ops),
                        parent_slot_id = parent_slot_id,
                        trigger_source_slot_id = source_opcode == "Trigger" and source_slot_id or nil,
                        timer_source_slot_id = source_opcode == "Timer" and source_slot_id or nil,
                        source_postfix_opcode = source_opcode,
                        helper_record_id = nil,
                        runtime_record_created = false,
                        payload_bindings = {},
                        summon_source = batch.is_summon_source == true,
                        summon_source_ordinal = summon_source_ordinal,
                    }
                    slots[#slots + 1] = slot

                    if batch.is_summon_source == true then
                        local first_effect = slot.effects and slot.effects[1] or nil
                        log.debug(string.format(
                            "SPELLFORGE_SUMMON_SOURCE_SLOT recipe_id=%s ordinal=%s effect_id=%s slot_id=%s group_index=%s emission_index=%s",
                            tostring(plan.recipe_id),
                            tostring(summon_source_ordinal),
                            tostring(first_effect and first_effect.id),
                            tostring(slot_id),
                            tostring(group_index),
                            tostring(emission_index)
                        ))
                    end

                    if group.payload and type(group.payload.effects) == "table" and #group.payload.effects > 0 then
                        local payload_groups, payload_errors = parsePayloadGroups(group.payload.effects, options)
                        if payload_groups then
                            local payload_op = hasPostfix(group, "Trigger") and "Trigger" or (hasPostfix(group, "Timer") and "Timer" or "Payload")
                            slot.payload_bindings[#slot.payload_bindings + 1] = {
                                source_opcode = payload_op,
                                payload_scope = group.payload.scope,
                                planned_child_group_count = #payload_groups,
                            }
                            allocateGroups(payload_groups, slot_id, slot_id, payload_op, depth + 1)
                            if #errors > 0 then
                                return
                            end
                        else
                            if appendFatalPayloadParseErrors(errors, group_index, payload_errors) then
                                return
                            end
                            warnings[#warnings + 1] = {
                                path = string.format("groups[%d].payload", group_index),
                                message = "payload parse failed for slot planning; preserving metadata only",
                                details = payload_errors,
                            }
                            slot.payload_bindings[#slot.payload_bindings + 1] = {
                                source_opcode = hasPostfix(group, "Trigger") and "Trigger" or (hasPostfix(group, "Timer") and "Timer" or "Payload"),
                                payload_scope = group.payload.scope,
                                planned_child_group_count = 0,
                                parse_ok = false,
                            }
                        end
                    end
                end
            end
        end
    end

    allocateGroups(plan.groups, nil, nil, nil, 0)

    if #errors > 0 then
        return {
            ok = false,
            recipe_id = plan.recipe_id,
            errors = errors,
            warnings = warnings,
        }
    end

    return {
        ok = true,
        recipe_id = plan.recipe_id,
        slots = slots,
        slot_count = #slots,
        summon_source_count = summon_source_count,
        warnings = warnings,
    }
end

return emission_slots
