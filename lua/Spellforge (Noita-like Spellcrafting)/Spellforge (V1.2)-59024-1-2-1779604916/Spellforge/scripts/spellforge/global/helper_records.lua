local core = require("openmw.core")
local effect_identity = require("scripts.spellforge.shared.effect_identity")
local limits = require("scripts.spellforge.shared.limits")
local records = require("scripts.spellforge.global.records")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local log = require("scripts.spellforge.shared.log").new("global.helper_records")

local helper_records = {}
local PRESENTATION_METADATA_FIELDS = {
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
}

local by_logical_id = {}
local by_engine_id = {}
local by_recipe_slot = {}

local function recipeSlotKey(recipe_id, slot_id)
    return string.format("%s::%s", tostring(recipe_id), tostring(slot_id))
end

local function appendError(errors, path, message, code, details)
    errors[#errors + 1] = {
        path = path,
        message = message,
        code = code,
        severity = "error",
        details = details,
    }
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

local function cloneEffects(effects, include_metadata)
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
        if include_metadata then
            for _, field in ipairs(PRESENTATION_METADATA_FIELDS) do
                if effect[field] ~= nil then
                    cloned[field] = effect[field]
                end
            end
        end
        out[i] = cloned
    end
    return out
end

local function clonePresentation(presentation)
    local out = {
        school = presentation and presentation.school or nil,
        element = presentation and presentation.element or nil,
    }
    for _, field in ipairs(PRESENTATION_METADATA_FIELDS) do
        if presentation and presentation[field] ~= nil then
            out[field] = presentation[field]
        end
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

local function cloneStringArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

local function cloneStackPolicy(policy)
    if type(policy) ~= "table" then
        return nil
    end
    return {
        stackable = policy.stackable == true,
        reason = policy.reason,
        effect_ids = cloneStringArray(policy.effect_ids),
        is_fanout = policy.is_fanout == true,
        shared_helper = policy.shared_helper == true,
        shared_key = policy.shared_key,
        summon_source = policy.summon_source == true,
        summon_source_ordinal = policy.summon_source_ordinal,
    }
end

local function magicEffectRecordsTable()
    local ok_effects, effects = pcall(function()
        return core.magic.effects
    end)
    if not ok_effects or effects == nil then
        return nil, nil
    end
    local ok_records, records_table = pcall(function()
        return effects.records
    end)
    if ok_records then
        return records_table, effects
    end
    return nil, effects
end

local function draftEffectFrom(effect, records_table, effects_api)
    local resolved = effect_identity.resolveEngineEffectId(effect, records_table, effects_api)
    if not resolved.ok then
        return nil, resolved
    end
    return {
        id = resolved.engine_effect_id,
        range = effect.range,
        area = effect.area,
        duration = effect.duration,
        magnitudeMin = effect.magnitudeMin,
        magnitudeMax = effect.magnitudeMax,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
    },
        resolved
end

local function draftEffects(effects, records_table, effects_api)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        local draft_effect, resolved = draftEffectFrom(effect, records_table, effects_api)
        if not draft_effect then
            return nil, i, resolved
        end
        out[i] = draft_effect
    end
    return out, nil, nil
end

local function buildDraft(spec)
    local records_table, effects_api = magicEffectRecordsTable()
    local effects, failed_index, identity_error = draftEffects(spec.effects, records_table, effects_api)
    if not effects then
        return nil, {
            index = failed_index,
            error = identity_error,
        }
    end
    return core.magic.spells.createRecordDraft {
        id = spec.logical_id,
        name = spec.planned_name or string.format("Spellforge Helper %s", tostring(spec.slot_id)),
        cost = spec.cost or 0,
        isAutocalc = spec.is_autocalc == true,
        effects = effects,
    }
end

local function toMapping(spec, engine_id, reused)
    return {
        recipe_id = spec.recipe_id,
        slot_id = spec.slot_id,
        group_index = spec.routing and spec.routing.group_index or nil,
        emission_index = spec.routing and spec.routing.emission_index or nil,
        kind = spec.routing and spec.routing.kind or nil,
        parent_slot_id = spec.routing and spec.routing.parent_slot_id or nil,
        trigger_source_slot_id = spec.routing and spec.routing.trigger_source_slot_id or nil,
        timer_source_slot_id = spec.routing and spec.routing.timer_source_slot_id or nil,
        source_postfix_opcode = spec.routing and spec.routing.source_postfix_opcode or nil,
        logical_id = spec.logical_id,
        engine_id = engine_id,
        internal = spec.internal == true,
        visible_to_player = spec.visible_to_player == true,
        effects = cloneEffects(spec.effects, true),
        presentation = clonePresentation(spec.presentation),
        stack_policy = cloneStackPolicy(spec.stack_policy),
        payload_bindings = spec.routing and spec.routing.payload_bindings or nil,
        prefix_ops = cloneOps(spec.routing and spec.routing.prefix_ops),
        postfix_ops = cloneOps(spec.routing and spec.routing.postfix_ops),
        reused = reused == true,
    }
end

local function putMapping(mapping)
    by_logical_id[mapping.logical_id] = mapping
    by_engine_id[mapping.engine_id] = mapping
    by_recipe_slot[recipeSlotKey(mapping.recipe_id, mapping.slot_id)] = mapping
end

local function removeMapping(mapping)
    if type(mapping) ~= "table" then
        return
    end
    if mapping.logical_id ~= nil then
        by_logical_id[mapping.logical_id] = nil
    end
    if mapping.engine_id ~= nil then
        by_engine_id[mapping.engine_id] = nil
    end
    by_recipe_slot[recipeSlotKey(mapping.recipe_id, mapping.slot_id)] = nil
end

function helper_records.getByLogicalId(logical_id)
    return by_logical_id[logical_id]
end

function helper_records.getByEngineId(engine_id)
    return by_engine_id[engine_id]
end

function helper_records.getByRecipeSlot(recipe_id, slot_id)
    return by_recipe_slot[recipeSlotKey(recipe_id, slot_id)]
end

function helper_records.clearForTests()
    by_logical_id = {}
    by_engine_id = {}
    by_recipe_slot = {}
end

function helper_records.clearForRecipe(recipe_id)
    local to_clear = {}
    for _, mapping in pairs(by_recipe_slot) do
        if mapping and mapping.recipe_id == recipe_id then
            to_clear[#to_clear + 1] = mapping
        end
    end

    local cleared = 0
    for _, mapping in ipairs(to_clear) do
        removeMapping(mapping)
        cleared = cleared + 1
    end
    return cleared
end

function helper_records.materialize(specs_or_result, opts)
    local options = opts or {}
    local max_specs = (options.limits and options.limits.MAX_PROJECTILES_PER_CAST) or limits.MAX_PROJECTILES_PER_CAST
    local warnings = {}
    local errors = {}

    local specs = specs_or_result
    local recipe_id = nil
    if type(specs_or_result) == "table" and type(specs_or_result.specs) == "table" then
        specs = specs_or_result.specs
        recipe_id = specs_or_result.recipe_id
    end

    if type(specs) ~= "table" then
        appendError(errors, "specs", "specs must be an array or generator result containing specs")
        return { ok = false, errors = errors, warnings = warnings }
    end

    if #specs > max_specs then
        appendError(errors, "specs", string.format("Spec count exceeds MAX_PROJECTILES_PER_CAST (%d)", max_specs))
        return {
            ok = false,
            recipe_id = recipe_id,
            errors = errors,
            warnings = warnings,
        }
    end

    local materialized = {}
    local any_new = false

    for i, spec in ipairs(specs) do
        if type(spec) ~= "table" then
            appendError(errors, string.format("specs[%d]", i), "spec must be a table")
            break
        end
        if type(spec.logical_id) ~= "string" or spec.logical_id == "" then
            appendError(errors, string.format("specs[%d].logical_id", i), "logical_id must be a non-empty string")
            break
        end
        if type(spec.recipe_id) ~= "string" or spec.recipe_id == "" then
            appendError(errors, string.format("specs[%d].recipe_id", i), "recipe_id must be a non-empty string")
            break
        end
        if type(spec.slot_id) ~= "string" or spec.slot_id == "" then
            appendError(errors, string.format("specs[%d].slot_id", i), "slot_id must be a non-empty string")
            break
        end
        if type(spec.effects) ~= "table" or #spec.effects == 0 then
            appendError(errors, string.format("specs[%d].effects", i), "effects must be a non-empty array")
            break
        end

        recipe_id = recipe_id or spec.recipe_id

        local existing = helper_records.getByLogicalId(spec.logical_id)
        if existing then
            local reused_mapping = toMapping(spec, existing.engine_id, true)
            putMapping(reused_mapping)
            materialized[#materialized + 1] = reused_mapping
            runtime_stats.inc("helper_records_reused")
        else
            local draft_ok, draft, draft_build_error = pcall(buildDraft, spec)
            if not draft_ok or not draft then
                local identity_error = draft_ok and draft_build_error and draft_build_error.error or nil
                local failed_index = draft_ok and draft_build_error and draft_build_error.index or nil
                local first = failed_index and spec.effects and spec.effects[failed_index] or spec.effects and spec.effects[1] or nil
                local message = identity_error and identity_error.message
                    or string.format("createRecordDraft failed: %s", tostring(draft_ok and draft_build_error or draft))
                local code = identity_error and identity_error.code or "invalid_engine_effect_id"
                log.error(string.format(
                    "helper createRecordDraft failed logical_id=%s slot_id=%s effect_index=%s effect_id=%s engine_effect_id=%s err=%s",
                    tostring(spec.logical_id),
                    tostring(spec.slot_id),
                    tostring(failed_index),
                    tostring(first and first.id),
                    tostring(first and first.engine_effect_id),
                    tostring(message)
                ))
                appendError(errors, string.format("specs[%d].effects[%s]", i, tostring(failed_index or "?")), message, code, identity_error)
                break
            end
            local created_record, create_error = records.createRecord(draft)
            if create_error then
                local first = spec.effects and spec.effects[1] or nil
                local keys = {}
                for k in pairs(draft or {}) do
                    keys[#keys + 1] = tostring(k)
                end
                table.sort(keys)
                log.error(string.format(
                    "helper createRecord failed logical_id=%s slot_id=%s effect_count=%d first_effect={id=%s engine_effect_id=%s range=%s area=%s duration=%s min=%s max=%s} draft_keys=%s err=%s",
                    tostring(spec.logical_id),
                    tostring(spec.slot_id),
                    #(spec.effects or {}),
                    tostring(first and first.id),
                    tostring(first and first.engine_effect_id),
                    tostring(first and first.range),
                    tostring(first and first.area),
                    tostring(first and first.duration),
                    tostring(first and first.magnitudeMin),
                    tostring(first and first.magnitudeMax),
                    table.concat(keys, ","),
                    tostring(create_error)
                ))
                appendError(errors, string.format("specs[%d]", i), string.format("world.createRecord failed: %s", tostring(create_error)))
                break
            end
            local engine_id = created_record and created_record.id or nil
            if type(engine_id) ~= "string" or engine_id == "" then
                appendError(errors, string.format("specs[%d]", i), "world.createRecord returned unusable engine id")
                break
            end

            local mapping = toMapping(spec, engine_id, false)
            putMapping(mapping)
            materialized[#materialized + 1] = mapping
            any_new = true
            runtime_stats.inc("helper_records_created")
        end
    end

    if #errors > 0 then
        return {
            ok = false,
            recipe_id = recipe_id,
            errors = errors,
            warnings = warnings,
            partial_records = materialized,
            partial_count = #materialized,
        }
    end

    return {
        ok = true,
        recipe_id = recipe_id,
        records = materialized,
        record_count = #materialized,
        reused = not any_new,
        warnings = warnings,
    }
end

return helper_records
