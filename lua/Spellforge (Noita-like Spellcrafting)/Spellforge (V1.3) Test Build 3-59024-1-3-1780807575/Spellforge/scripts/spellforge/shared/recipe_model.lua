---@omw-context none
local validation = require("scripts.spellforge.shared.validation_contract")
local operator_params = require("scripts.spellforge.shared.operator_params")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local recipe_model = {}

recipe_model.CONTRACT_VERSION = "spellforge-ui-contract-v1"
recipe_model.SCHEMA_VERSION = "spellforge-ui-recipe-v1"
recipe_model.SOURCE_KIND_EFFECT_LIST = "effect_list"

local EFFECT_FIELDS = {
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
    "display_name",
    "school",
    "category",
    "runtime_category",
}

local RECIPE_METADATA_FIELDS = {
    "title",
    "name",
    "description",
}

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 4 then
        return tostring(value)
    end

    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function hasArrayEntry(tbl)
    return type(tbl) == "table" and tbl[1] ~= nil
end

local function isEmptyTable(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    return next(tbl) == nil
end

local function copyRecipeMetadata(source, recipe)
    for _, field in ipairs(RECIPE_METADATA_FIELDS) do
        if source[field] ~= nil then
            recipe[field] = cloneValue(source[field], 0)
        end
    end
end

local function cloneEffect(effect, index)
    local cloned = {}
    for _, field in ipairs(EFFECT_FIELDS) do
        if effect[field] ~= nil then
            cloned[field] = cloneValue(effect[field], 0)
        end
    end
    operator_params.copyEncodedFields(effect, cloned)
    local mirrored = operator_params.mirrorEffect(cloned)
    if type(mirrored) == "table" then
        cloned = mirrored
    end
    if type(cloned.id) == "string" and cloned.id ~= "" then
        cloned.id = effect_registry.normalizeEffectId(cloned.id) or cloned.id
        if type(cloned.engine_effect_id) == "string"
            and effect_registry.normalizeEffectId(cloned.engine_effect_id) ~= cloned.id then
            cloned.engine_effect_id = nil
        end
        if not effect_registry.isOperatorEffectId(cloned.id) then
            effect_registry.normalizeEffectParams(cloned, effect_registry.getFallbackInfo(cloned.id))
        end
    end
    if cloned.ui_id == nil or cloned.ui_id == "" then
        cloned.ui_id = string.format("effect:%d", index)
    end
    return cloned
end

local function extractEffects(input)
    if type(input) ~= "table" then
        return nil, nil, validation.error("recipe", "recipe must be a table", "recipe_not_table")
    end

    if type(input.nodes) == "table" then
        return nil, nil, validation.error(
            "recipe.nodes",
            "legacy node recipes are not supported by the UI recipe contract",
            "legacy_node_recipe_not_supported"
        )
    end

    if type(input.effects) == "table" then
        return input.effects, input, nil
    end

    if hasArrayEntry(input) or isEmptyTable(input) then
        return input, { effects = input }, nil
    end

    return nil, nil, validation.error("recipe.effects", "recipe.effects must be an array", "effects_not_array")
end

function recipe_model.normalize(input, opts)
    local options = opts or {}
    local effects, source, extract_error = extractEffects(input)
    local errors = {}
    local warnings = {}

    if extract_error then
        errors[#errors + 1] = extract_error
        return {
            ok = false,
            errors = errors,
            warnings = warnings,
        }
    end

    if type(source) == "table"
        and source.source_kind ~= nil
        and source.source_kind ~= recipe_model.SOURCE_KIND_EFFECT_LIST then
        errors[#errors + 1] = validation.error(
            "recipe.source_kind",
            string.format("unsupported recipe.source_kind: %s", tostring(source.source_kind)),
            "unsupported_source_kind"
        )
    end

    if type(source) == "table"
        and source.schema_version ~= nil
        and source.schema_version ~= recipe_model.SCHEMA_VERSION then
        errors[#errors + 1] = validation.error(
            "recipe.schema_version",
            string.format("unsupported recipe.schema_version: %s", tostring(source.schema_version)),
            "unsupported_schema_version"
        )
    end

    local normalized_effects = {}
    for index, effect in ipairs(effects or {}) do
        if type(effect) ~= "table" then
            errors[#errors + 1] = validation.error(
                string.format("effects[%d]", index),
                "effect must be a table",
                "effect_not_table"
            )
        else
            local cloned = cloneEffect(effect, index)
            if cloned.id == nil or cloned.id == "" then
                errors[#errors + 1] = validation.error(
                    string.format("effects[%d].id", index),
                    "effect.id must be a non-empty string",
                    "effect_id_required"
                )
            end
            normalized_effects[#normalized_effects + 1] = cloned
        end
    end

    if #normalized_effects == 0 then
        errors[#errors + 1] = validation.error("effects", "recipe.effects must include at least one effect", "effects_empty")
    end

    local recipe = {
        schema_version = recipe_model.SCHEMA_VERSION,
        source_kind = recipe_model.SOURCE_KIND_EFFECT_LIST,
        effects = normalized_effects,
    }
    copyRecipeMetadata(source, recipe)

    if options.preserve_request_id and type(source) == "table" and source.request_id ~= nil then
        recipe.request_id = source.request_id
    end

    return {
        ok = #errors == 0,
        recipe = recipe,
        effects = normalized_effects,
        errors = errors,
        warnings = warnings,
    }
end

return recipe_model
