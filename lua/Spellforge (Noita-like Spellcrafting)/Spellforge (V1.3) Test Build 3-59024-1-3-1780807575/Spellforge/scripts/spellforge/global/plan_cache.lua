---@omw-context global
local limits = require("scripts.spellforge.shared.limits")
local operator_params = require("scripts.spellforge.shared.operator_params")
local parser = require("scripts.spellforge.global.parser")
local canonicalize_effect_list = require("scripts.spellforge.global.canonicalize_effect_list")
local emission_slots = require("scripts.spellforge.global.emission_slots")
local helper_record_specs = require("scripts.spellforge.global.helper_record_specs")
local helper_records = require("scripts.spellforge.global.helper_records")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local validation = require("scripts.spellforge.shared.validation_contract")

local plan_cache = {}

local CANONICAL_VERSION = "spellforge-effect-list-v1"
local PRESENTATION_METADATA_FIELDS = {
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
}

local plans_by_recipe_id = {}

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

local function sanitizeEffect(effect)
    if type(effect) ~= "table" then
        return {
            id = tostring(effect),
        }
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

local function sanitizeEffects(effects)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        out[i] = sanitizeEffect(effect)
    end
    return out
end

local function cloneOp(op)
    if type(op) ~= "table" then
        return nil
    end
    return {
        opcode = op.opcode,
        effect_id = op.effect_id,
        params = cloneParams(op.params),
        index = op.index,
        payload_scope = op.payload_scope,
    }
end

local function cloneEffects(effects)
    local out = {}
    for i, effect in ipairs(effects or {}) do
        out[i] = sanitizeEffect(effect)
    end
    return out
end

local function cloneGroups(groups)
    local out = {}
    for i, group in ipairs(groups or {}) do
        local prefix_ops = {}
        for j, op in ipairs(group.prefix_ops or {}) do
            prefix_ops[j] = cloneOp(op)
        end

        local postfix_ops = {}
        for j, op in ipairs(group.postfix_ops or {}) do
            postfix_ops[j] = cloneOp(op)
        end

        out[i] = {
            kind = group.kind,
            range = group.range,
            effects = cloneEffects(group.effects),
            prefix_ops = prefix_ops,
            postfix_ops = postfix_ops,
            payload = group.payload and {
                scope = group.payload.scope,
                effects = cloneEffects(group.payload.effects),
                note = group.payload.note,
            } or nil,
            emission_count_static = group.emission_count_static,
        }
    end
    return out
end

local function cloneErrors(errors)
    return validation.cloneIssues(errors, "error")
end

local function cloneWarnings(warnings)
    return validation.cloneIssues(warnings, "warning")
end

local function summarizeBounds(groups, effect_count)
    local bounds = {
        static_emission_count = 0,
        max_projectiles = limits.MAX_PROJECTILES_PER_CAST,
        has_trigger = false,
        has_timer = false,
        has_multicast = false,
        has_pattern = false,
        has_chain = false,
        has_bounce = false,
        has_pierce = false,
        has_homing = false,
        has_speed_plus = false,
        has_size_plus = false,
        group_count = #(groups or {}),
        effect_count = effect_count or 0,
    }

    for _, group in ipairs(groups or {}) do
        bounds.static_emission_count = bounds.static_emission_count + (group.emission_count_static or 1)

        for _, op in ipairs(group.prefix_ops or {}) do
            if op.opcode == "Multicast" then
                bounds.has_multicast = true
            elseif op.opcode == "Burst" or op.opcode == "Spread" then
                bounds.has_pattern = true
            elseif op.opcode == "Chain" then
                bounds.has_chain = true
            elseif op.opcode == "Bounce" then
                bounds.has_bounce = true
            elseif op.opcode == "Pierce" then
                bounds.has_pierce = true
            elseif op.opcode == "Homing" then
                bounds.has_homing = true
            elseif op.opcode == "Speed+" then
                bounds.has_speed_plus = true
            elseif op.opcode == "Size+" then
                bounds.has_size_plus = true
            end
        end

        for _, op in ipairs(group.postfix_ops or {}) do
            if op.opcode == "Trigger" then
                bounds.has_trigger = true
            elseif op.opcode == "Timer" then
                bounds.has_timer = true
            end
        end
    end

    return bounds
end

local function planDisplayName(options)
    local text = tostring(
        (options and (options.helper_display_name or options.plan_display_name or options.title))
            or ""
    )
    if text == "" then
        return nil
    end
    if #text > 48 then
        return string.sub(text, 1, 48)
    end
    return text
end

local function buildPlan(effects, parse_result, canonical, opts)
    local options = opts or {}
    local groups = cloneGroups(parse_result.groups)
    local plan = {
        recipe_id = canonical.recipe_id,
        canonical = canonical.canonical,
        canonical_version = CANONICAL_VERSION,
        display_name = planDisplayName(options),
        source_kind = "effect_list",
        effects = sanitizeEffects(effects),
        parse_result = {
            ok = parse_result.ok,
            warnings = cloneWarnings(parse_result.warnings),
            errors = cloneErrors(parse_result.errors),
        },
        groups = groups,
        bounds = summarizeBounds(groups, #(effects or {})),
        warnings = cloneWarnings(parse_result.warnings),
        created_runtime_records = false,
        helper_records = {},
        runtime_status = "staged_only",
    }
    return plan
end

function plan_cache.put(plan)
    if type(plan) ~= "table" or type(plan.recipe_id) ~= "string" or plan.recipe_id == "" then
        return false
    end
    plans_by_recipe_id[plan.recipe_id] = plan
    return true
end

function plan_cache.get(recipe_id)
    return plans_by_recipe_id[recipe_id]
end

function plan_cache.has(recipe_id)
    return plans_by_recipe_id[recipe_id] ~= nil
end

function plan_cache.clearForTests()
    plans_by_recipe_id = {}
end

function plan_cache.clear()
    plan_cache.clearForTests()
end

function plan_cache.compileOrGet(effects, opts)
    local normalized_effects = operator_params.mirrorEffects(effects)
    local canonical = canonicalize_effect_list.run(normalized_effects, opts)
    local cached = plan_cache.get(canonical.recipe_id)
    if cached then
        runtime_stats.inc("plans_reused")
        return {
            ok = true,
            reused = true,
            recipe_id = canonical.recipe_id,
            canonical = canonical.canonical,
            plan = cached,
        }
    end

    local parse_result = parser.parseEffectList(normalized_effects, opts)
    if not parse_result.ok then
        return {
            ok = false,
            reused = false,
            recipe_id = canonical.recipe_id,
            canonical = canonical.canonical,
            errors = cloneErrors(parse_result.errors),
            warnings = cloneWarnings(parse_result.warnings),
        }
    end

    local plan = buildPlan(normalized_effects, parse_result, canonical, opts)
    plan_cache.put(plan)
    runtime_stats.inc("plans_compiled")

    return {
        ok = true,
        reused = false,
        recipe_id = canonical.recipe_id,
        canonical = canonical.canonical,
        plan = plan,
        warnings = cloneWarnings(parse_result.warnings),
    }
end

function plan_cache.attachEmissionSlots(recipe_id, opts)
    local plan = plan_cache.get(recipe_id)
    if not plan then
        runtime_stats.inc("helper_records_attach_failed")
        return {
            ok = false,
            errors = {
                validation.error(
                    "recipe_id",
                    string.format("No cached plan for recipe_id=%s", tostring(recipe_id)),
                    "plan_not_cached"
                ),
            },
            warnings = {},
        }
    end

    local allocated = emission_slots.allocate(plan, opts)
    if not allocated.ok then
        return allocated
    end

    plan.emission_slots = allocated.slots
    plan.slot_count = allocated.slot_count
    plan.summon_source_count = allocated.summon_source_count
    plan.slot_warnings = allocated.warnings

    return {
        ok = true,
        recipe_id = recipe_id,
        slot_count = allocated.slot_count,
        summon_source_count = allocated.summon_source_count,
        warnings = allocated.warnings,
        plan = plan,
    }
end

function plan_cache.attachHelperSpecs(recipe_id, opts)
    local plan = plan_cache.get(recipe_id)
    if not plan then
        return {
            ok = false,
            errors = {
                validation.error(
                    "recipe_id",
                    string.format("No cached plan for recipe_id=%s", tostring(recipe_id)),
                    "plan_not_cached"
                ),
            },
            warnings = {},
        }
    end

    if type(plan.emission_slots) ~= "table" or #plan.emission_slots == 0 then
        local attached_slots = plan_cache.attachEmissionSlots(recipe_id, opts)
        if not attached_slots.ok then
            return attached_slots
        end
        plan = attached_slots.plan
    end

    local generated = helper_record_specs.generate(plan, plan.emission_slots, opts)
    if not generated.ok then
        return generated
    end

    plan.helper_specs = generated.specs
    plan.helper_spec_count = generated.spec_count
    plan.helper_spec_warnings = generated.warnings

    return {
        ok = true,
        recipe_id = recipe_id,
        spec_count = generated.spec_count,
        warnings = generated.warnings,
        plan = plan,
    }
end

function plan_cache.attachHelperRecords(recipe_id, opts)
    local plan = plan_cache.get(recipe_id)
    if not plan then
        return {
            ok = false,
            errors = {
                validation.error(
                    "recipe_id",
                    string.format("No cached plan for recipe_id=%s", tostring(recipe_id)),
                    "plan_not_cached"
                ),
            },
            warnings = {},
        }
    end

    if type(plan.helper_specs) ~= "table" or #plan.helper_specs == 0 then
        local attached_specs = plan_cache.attachHelperSpecs(recipe_id, opts)
        if not attached_specs.ok then
            runtime_stats.inc("helper_records_attach_failed")
            return attached_specs
        end
        plan = attached_specs.plan
    end

    local materialized = helper_records.materialize({
        recipe_id = plan.recipe_id,
        specs = plan.helper_specs,
    }, opts)
    if not materialized.ok then
        runtime_stats.inc("helper_records_attach_failed")
        return materialized
    end

    plan.helper_records = materialized.records
    plan.helper_record_count = materialized.record_count
    plan.helper_records_reused = materialized.reused
    runtime_stats.inc("helper_records_attached", materialized.record_count or 0)

    return {
        ok = true,
        recipe_id = recipe_id,
        record_count = materialized.record_count,
        reused = materialized.reused,
        warnings = materialized.warnings,
        plan = plan,
    }
end

return plan_cache
