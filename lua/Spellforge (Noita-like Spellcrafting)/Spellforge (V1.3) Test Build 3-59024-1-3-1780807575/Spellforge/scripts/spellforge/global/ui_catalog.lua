---@omw-context global
local events = require("scripts.spellforge.shared.events")
local feature_matrix = require("scripts.spellforge.global.feature_matrix")
local base_effect_catalog = require("scripts.spellforge.shared.base_effect_catalog")
local limits = require("scripts.spellforge.shared.limits")
local opcodes = require("scripts.spellforge.shared.opcodes")
local operator_params = require("scripts.spellforge.shared.operator_params")
local recipe_model = require("scripts.spellforge.shared.recipe_model")

local ui_catalog = {}

ui_catalog.VERSION = "spellforge-ui-catalog-v1"

local OPERATOR_EFFECT_IDS = {
    { effect_id = "spellforge_multicast", opcode = "Multicast" },
    { effect_id = "spellforge_spread", opcode = "Spread" },
    { effect_id = "spellforge_burst", opcode = "Burst" },
    { effect_id = "spellforge_speed_plus", opcode = "Speed+" },
    { effect_id = "spellforge_size_plus", opcode = "Size+" },
    { effect_id = "spellforge_chain", opcode = "Chain" },
    { effect_id = "spellforge_bounce", opcode = "Bounce" },
    { effect_id = "spellforge_pierce", opcode = "Pierce" },
    { effect_id = "spellforge_homing", opcode = "Homing" },
    { effect_id = "spellforge_detonate", opcode = "Detonate" },
    { effect_id = "spellforge_trigger", opcode = "Trigger" },
    { effect_id = "spellforge_timer", opcode = "Timer" },
}

local OPERATOR_ORDER = {
    "Multicast",
    "Spread",
    "Burst",
    "Speed+",
    "Size+",
    "Chain",
    "Bounce",
    "Pierce",
    "Homing",
    "Detonate",
    "Trigger",
    "Timer",
}

local RECIPE_EFFECT_FIELDS = {
    "id",
    "engine_effect_id",
    "range",
    "area",
    "duration",
    "magnitudeMin",
    "magnitudeMax",
    "affectedAttribute",
    "affectedSkill",
    "params",
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
    "ui_id",
    "label",
}

local function cloneScalarMap(tbl)
    local out = {}
    for k, v in pairs(tbl or {}) do
        out[k] = v
    end
    return out
end

local function cloneArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

local function recipeEffectFields()
    local fields = cloneArray(RECIPE_EFFECT_FIELDS)
    for _, field in ipairs(operator_params.encodedFieldNames()) do
        fields[#fields + 1] = field
    end
    return fields
end

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function cloneParameters(parameters)
    local out = {}
    for _, key in ipairs(sortedKeys(parameters)) do
        out[key] = cloneScalarMap(parameters[key])
    end
    return out
end

local function buildOperator(opcode)
    local def = opcodes[opcode] or {}
    return {
        opcode = opcode,
        kind = def.kind,
        display_name = def.display_name or opcode,
        description = def.description,
        icon = def.icon,
        large_icon = def.large_icon,
        parameters = cloneParameters(def.parameters),
    }
end

local function buildOperators()
    local by_opcode = {}
    local list = {}
    for i, opcode in ipairs(OPERATOR_ORDER) do
        local entry = buildOperator(opcode)
        list[i] = entry
        by_opcode[opcode] = entry
    end
    return list, by_opcode
end

local function buildOperatorEffectIds()
    local list = {}
    local by_effect_id = {}
    for i, mapping in ipairs(OPERATOR_EFFECT_IDS) do
        local entry = {
            effect_id = mapping.effect_id,
            opcode = mapping.opcode,
            icon = (opcodes[mapping.opcode] or {}).icon,
            large_icon = (opcodes[mapping.opcode] or {}).large_icon,
        }
        list[i] = entry
        by_effect_id[mapping.effect_id] = mapping.opcode
    end
    return list, by_effect_id
end

local function buildLimits()
    return {
        max_projectiles_per_cast = limits.MAX_PROJECTILES_PER_CAST,
        max_projectiles_per_cast_hard = limits.MAX_PROJECTILES_PER_CAST_HARD,
        max_summon_sources_per_spell = limits.MAX_SUMMON_SOURCES_PER_SPELL,
        max_payload_fanout = limits.MAX_PAYLOAD_FANOUT,
        max_payload_fanout_hard = limits.MAX_PAYLOAD_FANOUT_HARD,
        max_chain_hops = limits.MAX_CHAIN_HOPS,
        max_chain_multicast_fanout = limits.MAX_CHAIN_MULTICAST_FANOUT,
        max_bounce_count = limits.MAX_BOUNCE_COUNT,
        max_bounce_count_hard = limits.MAX_BOUNCE_COUNT_HARD,
        max_pierce_count = limits.MAX_PIERCE_COUNT,
        max_pierce_count_hard = limits.MAX_PIERCE_COUNT_HARD,
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
        max_jobs_per_tick = limits.MAX_JOBS_PER_TICK,
        max_live_launches_per_tick = limits.MAX_LIVE_LAUNCHES_PER_TICK,
        max_homing_projectiles_active = limits.MAX_HOMING_PROJECTILES_ACTIVE,
        max_homing_state_requests_per_tick = limits.MAX_HOMING_STATE_REQUESTS_PER_TICK,
        max_homing_payload_state_requests_per_tick = limits.MAX_HOMING_PAYLOAD_STATE_REQUESTS_PER_TICK,
        max_homing_redirects_per_projectile = limits.HOMING_MAX_REDIRECTS_PER_PROJECTILE,
        max_homing_payload_redirects_per_projectile = limits.HOMING_PAYLOAD_MAX_REDIRECTS_PER_PROJECTILE,
        max_homing_retargets_per_projectile = limits.HOMING_MAX_RETARGETS_PER_PROJECTILE,
        homing_steer_interval_seconds = limits.HOMING_STEER_INTERVAL_SECONDS,
        homing_initial_steer_delay_seconds = limits.HOMING_INITIAL_STEER_DELAY_SECONDS,
        homing_redirect_blend = limits.HOMING_REDIRECT_BLEND,
        homing_payload_force_vec_assist_multiplier = limits.HOMING_PAYLOAD_FORCE_VEC_ASSIST_MULTIPLIER,
        homing_payload_early_steer_interval_seconds = limits.HOMING_PAYLOAD_EARLY_STEER_INTERVAL_SECONDS,
        homing_payload_settled_steer_interval_seconds = limits.HOMING_PAYLOAD_SETTLED_STEER_INTERVAL_SECONDS,
        homing_payload_early_redirect_blend = limits.HOMING_PAYLOAD_EARLY_REDIRECT_BLEND,
        homing_payload_settled_redirect_blend = limits.HOMING_PAYLOAD_SETTLED_REDIRECT_BLEND,
        homing_payload_early_steer_seconds = limits.HOMING_PAYLOAD_EARLY_STEER_SECONDS,
        homing_payload_early_redirect_count = limits.HOMING_PAYLOAD_EARLY_REDIRECT_COUNT,
    }
end

local function buildSupportTruth()
    return {
        reason_classifications = {
            "feature_gated",
            "unsupported_by_design",
            "future_deferred",
            "cap_or_budget_rejected",
            "gate_disabled",
            "internal_error",
        },
        runtime_closure = {
            strict_gate = "SpellforgeDev.enable_ir_runtime_strict_v0",
            public_truth = "feature_matrix",
            notes = "Pack H expects supported runtime surfaces to use IR/shared policy paths with zero unexpected fallback or mismatch.",
        },
        bounce_v0 = {
            gates = {
                "SpellforgeDev.enable_live_2_2c_runtime",
                "SpellforgeDev.enable_live_bounce_v0",
            },
            supported_shapes = {
                "Bounce N -> simple target emitter",
                "Bounce N -> source Multicast/Spread/Burst + Multicast",
                "Bounce N -> source Speed+/Size+/Speed+ Size+ + Multicast/Pattern",
                "Bounce N -> target emitter -> Trigger -> simple payload",
                "Bounce N -> target emitter -> Trigger -> payload Multicast",
                "Bounce N -> target emitter -> Trigger -> payload Spread/Burst + Multicast",
                "Bounce N -> target emitter -> Trigger -> Chain N -> simple payload",
                "Bounce N -> target emitter -> Timer -> supported payload",
                "Bounce N -> source fanout -> Timer -> supported payload",
            },
            observed_surfaces = {
                "actor/contact",
                "interior wall/static",
                "exterior wall/static",
                "terrain/ground",
            },
            chain_handoff = "Bounce events may not include a hit actor; Spellforge infers a Chain source near the bounce point when possible and stops safely when no candidates exist.",
            deferred = {
                "Bounce + Homing",
                "Bounce + direct source Chain",
                "Bounce source Speed+/Size+ with Trigger payload",
                "simple no-fanout Bounce source Speed+ Size+",
                "Bounce + arbitrary nested payload runtime",
                "Bounce + recursion",
                "Bounce + post-launch steering",
                "per-projectile Lua brains",
            },
        },
        pierce_v0 = {
            gates = {
                "SpellforgeDev.enable_live_2_2c_runtime",
                "SpellforgeDev.enable_live_pierce_v0",
            },
            supported_shapes = {
                "Pierce N -> simple target emitter",
                "Pierce N -> source Multicast/Spread/Burst + Multicast",
                "Pierce N -> source Speed+/Size+/Speed+ Size+ + Multicast/Pattern",
                "Pierce N -> target emitter -> Trigger -> simple payload",
                "Pierce N -> target emitter -> Trigger -> payload Multicast",
                "Pierce N -> target emitter -> Trigger -> payload Spread/Burst + Multicast",
                "Pierce N -> target emitter -> Trigger -> Chain N -> simple payload",
                "Pierce N -> target emitter -> Timer -> supported payload",
                "Pierce N -> source fanout -> Timer -> supported payload",
            },
            behavior = "SFP treats N as a pass-through budget, then stops on the next actor or geometry hit; Spellforge routes Trigger continuations from Pierce events with bounded duplicate suppression.",
            deferred = {
                "Pierce + Bounce",
                "Pierce + Homing",
                "Pierce + direct source Chain",
                "Pierce source Speed+/Size+ with Trigger payload",
                "simple no-fanout Pierce source Speed+ Size+",
                "Pierce + arbitrary nested payload runtime",
                "Pierce recursion",
                "repeated same-actor Pierce ticks",
            },
        },
    }
end

function ui_catalog.build(payload)
    local operators, operators_by_opcode = buildOperators()
    local operator_effect_ids, operator_opcode_by_effect_id = buildOperatorEffectIds()
    local p = payload or {}
    local available_effects = base_effect_catalog.buildAvailableEffects(p.available_effects or p)

    return {
        request_id = p.request_id,
        ok = true,
        catalog_version = ui_catalog.VERSION,
        contract_version = recipe_model.CONTRACT_VERSION,
        schema_version = recipe_model.SCHEMA_VERSION,
        source_kind = recipe_model.SOURCE_KIND_EFFECT_LIST,
        recipe_model = {
            schema_version = recipe_model.SCHEMA_VERSION,
            source_kind = recipe_model.SOURCE_KIND_EFFECT_LIST,
            effect_fields = recipeEffectFields(),
            generated_ui_id_prefix = "effect:",
        },
        events = {
            validate_recipe = events.VALIDATE_RECIPE,
            validate_result = events.VALIDATE_RESULT,
            preview_recipe = events.PREVIEW_RECIPE,
            preview_result = events.PREVIEW_RESULT,
            query_catalog = events.QUERY_UI_CATALOG,
            catalog_result = events.UI_CATALOG_RESULT,
            query_available_effects = events.QUERY_AVAILABLE_EFFECTS,
            available_effects_result = events.AVAILABLE_EFFECTS_RESULT,
        },
        available_effects = available_effects,
        base_effects = available_effects.base_effects,
        base_effect_count = available_effects.base_effect_count,
        available_effect_source_mode = available_effects.source_mode,
        available_effect_warnings = available_effects.warnings,
        available_effect_capability_notes = available_effects.capability_notes,
        operators = operators,
        operators_by_opcode = operators_by_opcode,
        operator_effect_ids = operator_effect_ids,
        operator_opcode_by_effect_id = operator_opcode_by_effect_id,
        operator_count = #operators,
        feature_matrix = {
            version = feature_matrix.VERSION,
            features = feature_matrix.catalog(),
        },
        support_truth = buildSupportTruth(),
        limits = buildLimits(),
        defaults = {
            live_runtime_enabled = false,
            preview_materializes_records = false,
            preview_launches_projectiles = false,
        },
    }
end

function ui_catalog.availableEffects(payload)
    local p = payload or {}
    local result = base_effect_catalog.buildAvailableEffects(p.available_effects or p)
    result.request_id = p.request_id
    return result
end

return ui_catalog
