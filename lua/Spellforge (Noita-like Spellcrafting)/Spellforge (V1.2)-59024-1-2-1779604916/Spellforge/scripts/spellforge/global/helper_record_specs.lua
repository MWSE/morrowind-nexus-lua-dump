local limits = require("scripts.spellforge.shared.limits")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local effect_stack_policy = require("scripts.spellforge.global.effect_stack_policy")
local log = require("scripts.spellforge.shared.log").new("global.helper_record_specs")
local validation = require("scripts.spellforge.shared.validation_contract")

local helper_record_specs = {}
local PRESENTATION_METADATA_FIELDS = {
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
}

local ELEMENT_SCHOOL_BY_EFFECT_ID = {
    firedamage = { school = "destruction", element = "fire" },
    frostdamage = { school = "destruction", element = "frost" },
    shockdamage = { school = "destruction", element = "shock" },
}

local function appendError(errors, path, message, code, details)
    errors[#errors + 1] = validation.error(path, message, code, details)
end

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

local function cloneEffects(effects)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        local cloned = {
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
                cloned[field] = effect[field]
            end
        end
        out[i] = cloned
    end
    return out
end

local function normalizeEffectId(effect_id)
    return effect_registry.normalizeEffectId(effect_id)
end

local function sanitizeForId(value)
    local s = tostring(value or "")
    return (string.gsub(s, "[^%w_]", "_"))
end

local function safeDisplayName(value)
    local text = tostring(value or "")
    if text == "" then
        return "Spellforge Spell"
    end
    if #text > 40 then
        return string.sub(text, 1, 40)
    end
    return text
end

local function summonHelperName(plan, options, ordinal)
    local base = safeDisplayName(
        options.helper_display_name
            or options.plan_display_name
            or plan.display_name
            or plan.frontend_name
            or "Spellforge Spell"
    )
    return string.format("%s Summon %d", base, tonumber(ordinal) or 1)
end

local function resolvePresentation(effects)
    local first = effects and effects[1]
    local normalized = normalizeEffectId(first and first.id)
    local mapped = normalized and ELEMENT_SCHOOL_BY_EFFECT_ID[normalized] or nil
    local presentation = {
        school = mapped and mapped.school or nil,
        element = mapped and mapped.element or nil,
    }
    if type(first) == "table" then
        for _, field in ipairs(PRESENTATION_METADATA_FIELDS) do
            if first[field] ~= nil then
                presentation[field] = first[field]
            end
        end
    end
    -- Do not synthesize areaVfxRecId from vfxRecId or boltModel here.
    -- Bolt presentation records are not guaranteed to be valid area statics.
    return presentation
end

function helper_record_specs.auditPresentationMetadata(spec_or_effect)
    local effect = spec_or_effect
    if type(spec_or_effect) == "table" and spec_or_effect.presentation then
        local p = spec_or_effect.presentation
        return {
            has_areaVfxRecId = p.areaVfxRecId ~= nil,
            has_areaVfxScale = p.areaVfxScale ~= nil,
            has_vfxRecId = p.vfxRecId ~= nil,
            has_boltModel = p.boltModel ~= nil,
            has_hitModel = p.hitModel ~= nil,
            spellforge_synthesizes_area_from_bolt = false,
        }
    end
    local p = resolvePresentation({ effect })
    return {
        has_areaVfxRecId = p.areaVfxRecId ~= nil,
        has_areaVfxScale = p.areaVfxScale ~= nil,
        has_vfxRecId = p.vfxRecId ~= nil,
        has_boltModel = p.boltModel ~= nil,
        has_hitModel = p.hitModel ~= nil,
        spellforge_synthesizes_area_from_bolt = false,
    }
end

local function hasOpcode(ops, opcode)
    for _, op in ipairs(ops or {}) do
        if op.opcode == opcode then
            return true
        end
    end
    return false
end

local function multicastCount(ops)
    local count = 1
    for _, op in ipairs(ops or {}) do
        if op.opcode == "Multicast" then
            local n = tonumber(op.params and op.params.count) or 1
            count = count * math.max(1, n)
        end
    end
    return count
end

local function isFanoutSlot(slot)
    local prefix_ops = slot and slot.prefix_ops or nil
    local has_fanout_op = hasOpcode(prefix_ops, "Multicast")
        or hasOpcode(prefix_ops, "Spread")
        or hasOpcode(prefix_ops, "Burst")
    return has_fanout_op and multicastCount(prefix_ops) > 1
end

local function effectIdsSummary(effect_ids)
    return table.concat(effect_ids or {}, ",")
end

local function effectsContainSummon(effects)
    for _, effect in ipairs(effects or {}) do
        if effect_registry.isSummonEffect(effect) then
            return true
        end
    end
    return false
end

function helper_record_specs.generate(plan, slots_or_result, opts)
    local options = opts or {}
    local max_specs = (options.limits and options.limits.MAX_PROJECTILES_PER_CAST) or limits.MAX_PROJECTILES_PER_CAST
    local errors = {}
    local warnings = {}

    if type(plan) ~= "table" then
        appendError(errors, "plan", "plan must be a table", "plan_not_table")
    elseif type(plan.recipe_id) ~= "string" or plan.recipe_id == "" then
        appendError(errors, "plan.recipe_id", "plan.recipe_id must be a non-empty string", "plan_recipe_id_required")
    end

    local slots = slots_or_result
    if type(slots_or_result) == "table" and type(slots_or_result.slots) == "table" then
        slots = slots_or_result.slots
    end

    if type(slots) ~= "table" then
        appendError(errors, "slots", "slots must be an array or an allocation result containing slots", "slots_not_array")
    end

    if #errors > 0 then
        return {
            ok = false,
            errors = errors,
            warnings = warnings,
        }
    end

    if #slots > max_specs then
        appendError(errors, "slots", string.format("Spec count exceeds MAX_PROJECTILES_PER_CAST (%d)", max_specs), "spec_cap_exceeded", {
            limit = max_specs,
            count = #slots,
        })
        return {
            ok = false,
            recipe_id = plan.recipe_id,
            errors = errors,
            warnings = warnings,
        }
    end

    local specs = {}
    local stack_policy_shared = 0
    local stack_policy_unique = 0
    local fallback_summon_source_ordinal = 0
    for index, slot in ipairs(slots) do
        if type(slot) ~= "table" or type(slot.slot_id) ~= "string" or slot.slot_id == "" then
            appendError(errors, string.format("slots[%d]", index), "slot must include a non-empty slot_id", "slot_id_required")
        else
            local effects = cloneEffects(slot.effects)
            local presentation = resolvePresentation(effects)
            local has_multicast = hasOpcode(slot.prefix_ops, "Multicast")
            local is_fanout = isFanoutSlot(slot)
            local stackable, stack_reason, effect_ids = effect_stack_policy.helperEffectsAreStackable(effects)
            local is_summon_source = slot.summon_source == true or effectsContainSummon(effects)
            local summon_source_ordinal = tonumber(slot.summon_source_ordinal)
            if is_summon_source and summon_source_ordinal == nil then
                fallback_summon_source_ordinal = fallback_summon_source_ordinal + 1
                summon_source_ordinal = fallback_summon_source_ordinal
            end

            local logical_id = string.format(
                "spellforge_helper_%s_%s",
                sanitizeForId(plan.recipe_id),
                sanitizeForId(slot.slot_id)
            )
            if is_summon_source and summon_source_ordinal ~= nil then
                logical_id = string.format(
                    "spellforge_summon_%s_%03d",
                    sanitizeForId(plan.recipe_id),
                    summon_source_ordinal
                )
            end
            local stack_policy = {
                stackable = stackable == true,
                reason = stack_reason,
                effect_ids = effect_ids,
                is_fanout = is_fanout == true,
                shared_helper = false,
                shared_key = nil,
                summon_source = is_summon_source == true,
                summon_source_ordinal = summon_source_ordinal,
            }

            if is_fanout and not stackable and not is_summon_source then
                local shared_key = effect_stack_policy.sharedFanoutKeyForSlot(plan.recipe_id, slot, effects)
                logical_id = string.format(
                    "spellforge_helper_%s",
                    sanitizeForId(shared_key)
                )
                stack_policy.shared_helper = true
                stack_policy.shared_key = shared_key
                stack_policy_shared = stack_policy_shared + 1
                log.debug(string.format(
                    "SPELLFORGE_STACK_POLICY_HELPER_SHARED recipe_id=%s group_index=%s slot_id=%s emission_index=%s helper_logical_id=%s shared_helper_logical_id=%s effect_ids=%s stackable=false reason=%s source=%s",
                    tostring(plan.recipe_id),
                    tostring(slot.group_index),
                    tostring(slot.slot_id),
                    tostring(slot.emission_index),
                    tostring(logical_id),
                    tostring(logical_id),
                    effectIdsSummary(effect_ids),
                    tostring(stack_reason),
                    tostring(slot.kind)
                ))
            else
                stack_policy_unique = stack_policy_unique + 1
                if is_summon_source then
                    log.debug(string.format(
                        "SPELLFORGE_SUMMON_SOURCE_HELPER recipe_id=%s ordinal=%s group_index=%s slot_id=%s emission_index=%s helper_logical_id=%s effect_ids=%s",
                        tostring(plan.recipe_id),
                        tostring(summon_source_ordinal),
                        tostring(slot.group_index),
                        tostring(slot.slot_id),
                        tostring(slot.emission_index),
                        tostring(logical_id),
                        effectIdsSummary(effect_ids)
                    ))
                end
                if is_fanout then
                    log.debug(string.format(
                        "SPELLFORGE_STACK_POLICY_HELPER_UNIQUE recipe_id=%s group_index=%s slot_id=%s emission_index=%s helper_logical_id=%s effect_ids=%s stackable=%s reason=%s source=%s",
                        tostring(plan.recipe_id),
                        tostring(slot.group_index),
                        tostring(slot.slot_id),
                        tostring(slot.emission_index),
                        tostring(logical_id),
                        effectIdsSummary(effect_ids),
                        tostring(stackable == true),
                        tostring(stack_reason),
                        tostring(slot.kind)
                    ))
                end
            end

            if is_fanout then
                log.debug(string.format(
                    "SPELLFORGE_STACK_POLICY_CLASSIFIED recipe_id=%s group_index=%s slot_id=%s emission_index=%s effect_ids=%s stackable=%s reason=%s shared_helper=%s source=%s",
                    tostring(plan.recipe_id),
                    tostring(slot.group_index),
                    tostring(slot.slot_id),
                    tostring(slot.emission_index),
                    effectIdsSummary(effect_ids),
                    tostring(stackable == true),
                    tostring(stack_reason),
                    tostring(stack_policy.shared_helper == true),
                    tostring(slot.kind)
                ))
            end

            specs[#specs + 1] = {
                recipe_id = plan.recipe_id,
                slot_id = slot.slot_id,
                logical_id = logical_id,
                planned_name = is_summon_source
                    and summonHelperName(plan, options, summon_source_ordinal)
                    or string.format("Spellforge Helper %s", tostring(slot.slot_id)),
                internal = true,
                visible_to_player = false,
                engine_record_id = nil,
                engine_record_resolved = false,
                record_type = "spell",
                is_autocalc = false,
                cost = 0,
                range = slot.range,
                effects = effects,
                presentation = presentation,
                stack_policy = stack_policy,
                fanout = {
                    is_multicast = has_multicast,
                    is_copy = has_multicast and (slot.emission_index or 1) > 1,
                },
                routing = {
                    group_index = slot.group_index,
                    emission_index = slot.emission_index,
                    kind = slot.kind,
                    parent_slot_id = slot.parent_slot_id,
                    trigger_source_slot_id = slot.trigger_source_slot_id,
                    timer_source_slot_id = slot.timer_source_slot_id,
                    source_postfix_opcode = slot.source_postfix_opcode,
                    payload_bindings = slot.payload_bindings,
                    prefix_ops = cloneOps(slot.prefix_ops),
                    postfix_ops = cloneOps(slot.postfix_ops),
                },
                source = {
                    source_kind = plan.source_kind,
                    canonical_version = plan.canonical_version,
                },
            }
        end
    end

    if #errors > 0 then
        return {
            ok = false,
            recipe_id = plan.recipe_id,
            errors = errors,
            warnings = warnings,
        }
    end

    if stack_policy_shared > 0 or stack_policy_unique > 0 then
        log.debug(string.format(
            "SPELLFORGE_STACK_POLICY_OK recipe_id=%s specs=%d shared_helpers=%d unique_helpers=%d",
            tostring(plan.recipe_id),
            #specs,
            stack_policy_shared,
            stack_policy_unique
        ))
    end

    return {
        ok = true,
        recipe_id = plan.recipe_id,
        specs = specs,
        spec_count = #specs,
        warnings = warnings,
    }
end

return helper_record_specs
