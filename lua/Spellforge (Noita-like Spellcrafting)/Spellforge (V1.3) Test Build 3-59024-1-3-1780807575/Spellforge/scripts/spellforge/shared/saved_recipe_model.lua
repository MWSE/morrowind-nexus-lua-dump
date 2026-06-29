---@omw-context none
local recipe_model = require("scripts.spellforge.shared.recipe_model")
local validation = require("scripts.spellforge.shared.validation_contract")

local saved_recipe_model = {}

saved_recipe_model.SCHEMA_VERSION = "spellforge-saved-recipe-v1"
saved_recipe_model.DEFAULT_TITLE = "Untitled Spellforge Recipe"

local SAVED_METADATA_FIELDS = {
    "id",
    "title",
    "name",
    "description",
    "created_at",
    "updated_at",
    "recipe_id",
    "last_validated_recipe_id",
    "last_previewed_recipe_id",
}

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 5 then
        return tostring(value)
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function nowToken(opts)
    local options = opts or {}
    if options.now ~= nil then
        return options.now
    end
    return os.time()
end

local function sourceRecipe(input)
    if type(input) ~= "table" then
        return input
    end
    if type(input.recipe) == "table" then
        return input.recipe
    end
    if type(input.effects) == "table" then
        return {
            title = input.title or input.name,
            description = input.description,
            effects = input.effects,
        }
    end
    return input
end

function saved_recipe_model.isSupportedVersion(version)
    return version == nil or version == saved_recipe_model.SCHEMA_VERSION
end

function saved_recipe_model.normalize(input, opts)
    local options = opts or {}
    local errors = {}
    local warnings = {}

    if type(input) ~= "table" then
        return {
            ok = false,
            errors = { validation.error("saved_recipe", "saved recipe must be a table", "saved_recipe_not_table") },
            warnings = warnings,
        }
    end

    if not saved_recipe_model.isSupportedVersion(input.schema_version) then
        errors[#errors + 1] = validation.error(
            "saved_recipe.schema_version",
            string.format("unsupported saved recipe schema_version: %s", tostring(input.schema_version)),
            "unsupported_saved_recipe_schema_version"
        )
    end

    local recipe_result = recipe_model.normalize(sourceRecipe(input), options.recipe_options)
    for _, err in ipairs(recipe_result.errors or {}) do
        errors[#errors + 1] = validation.cloneIssue(err, "error")
    end
    for _, warn in ipairs(recipe_result.warnings or {}) do
        warnings[#warnings + 1] = validation.cloneIssue(warn, "warning")
    end

    local timestamp = nowToken(options)
    local saved = {
        schema_version = saved_recipe_model.SCHEMA_VERSION,
        id = input.id or options.id,
        title = input.title or input.name or (recipe_result.recipe and (recipe_result.recipe.title or recipe_result.recipe.name)) or saved_recipe_model.DEFAULT_TITLE,
        description = input.description or (recipe_result.recipe and recipe_result.recipe.description) or nil,
        created_at = input.created_at or timestamp,
        updated_at = options.updated_at or input.updated_at or timestamp,
        recipe = recipe_result.recipe,
        recipe_id = input.recipe_id,
        last_validated_recipe_id = input.last_validated_recipe_id,
        last_previewed_recipe_id = input.last_previewed_recipe_id,
    }

    if type(saved.id) ~= "string" or saved.id == "" then
        errors[#errors + 1] = validation.error("saved_recipe.id", "saved recipe id must be a non-empty string", "saved_recipe_id_required")
    end

    for _, field in ipairs(SAVED_METADATA_FIELDS) do
        if saved[field] == nil and input[field] ~= nil then
            saved[field] = cloneValue(input[field], 0)
        end
    end

    return {
        ok = #errors == 0,
        saved_recipe = saved,
        recipe = saved.recipe,
        errors = errors,
        warnings = warnings,
    }
end

function saved_recipe_model.create(input, opts)
    return saved_recipe_model.normalize(input, opts)
end

function saved_recipe_model.update(existing, patch, opts)
    local base = cloneValue(existing or {}, 0)
    local changes = patch or {}
    for k, v in pairs(changes) do
        base[k] = cloneValue(v, 0)
    end
    base.updated_at = (opts and opts.now) or os.time()
    return saved_recipe_model.normalize(base, opts)
end

function saved_recipe_model.migrate(input, opts)
    return saved_recipe_model.normalize(input, opts)
end

return saved_recipe_model
