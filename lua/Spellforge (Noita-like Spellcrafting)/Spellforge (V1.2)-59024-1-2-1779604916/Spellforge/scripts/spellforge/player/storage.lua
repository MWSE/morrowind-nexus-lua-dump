local openmw_storage = require("openmw.storage")

local generated_lifecycle = require("scripts.spellforge.shared.generated_spell_lifecycle")
local saved_recipe_model = require("scripts.spellforge.shared.saved_recipe_model")

local storage = {}

local SECTION_NAME = "SpellforgeUi"
local SAVE_STATE_VERSION = 1
local KEY_SAVED_RECIPES = "saved_recipes"
local KEY_LIFECYCLES = "generated_spell_lifecycles"
local KEY_NEXT_ID = "next_saved_recipe_id"

local section = nil
local memory = {
    saved_recipes = {},
    generated_spell_lifecycles = {},
    next_saved_recipe_id = 1,
}
local cached_saved_recipes = nil
local cached_lifecycles = nil
local cached_next_saved_recipe_id = nil

local function initSection()
    if section ~= nil then
        return section
    end
    if type(openmw_storage.playerSection) == "function" then
        local ok, result = pcall(openmw_storage.playerSection, SECTION_NAME)
        if ok then
            section = result
        end
    end
    return section
end

local function sectionGet(key)
    local s = initSection()
    if s and type(s.get) == "function" then
        return s:get(key)
    end
    return memory[key]
end

local function sectionSet(key, value)
    local s = initSection()
    if s and type(s.set) == "function" then
        s:set(key, value)
        return
    end
    memory[key] = value
end

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

local function valuesEqual(left, right, depth)
    if left == right then
        return true
    end
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return false
    end
    if (depth or 0) >= 6 then
        return tostring(left) == tostring(right)
    end
    for k, v in pairs(left) do
        if not valuesEqual(v, right[k], (depth or 0) + 1) then
            return false
        end
    end
    for k in pairs(right) do
        if left[k] == nil then
            return false
        end
    end
    return true
end

local function patchTouchesRecipe(patch)
    return type(patch) == "table" and (type(patch.recipe) == "table" or type(patch.effects) == "table")
end

local function recipesHaveSameEffects(left, right)
    local left_effects = type(left) == "table" and left.effects or nil
    local right_effects = type(right) == "table" and right.effects or nil
    return valuesEqual(left_effects, right_effects, 0)
end

local function normalizeSavedRecipeIndex(value)
    local out = {}
    if type(value) ~= "table" then
        return out
    end
    for id, saved in pairs(value) do
        if type(id) == "string" and type(saved) == "table" then
            local normalized = saved_recipe_model.migrate(saved, { id = id })
            if normalized.ok then
                out[id] = normalized.saved_recipe
            end
        end
    end
    return out
end

local function normalizeLifecycleIndex(value)
    local out = {}
    if type(value) ~= "table" then
        return out
    end
    for id, entry in pairs(value) do
        if type(id) == "string" and type(entry) == "table" then
            local normalized = generated_lifecycle.validateEntry(entry)
            if normalized.ok then
                normalized.entry.saved_recipe_id = normalized.entry.saved_recipe_id or id
                out[id] = normalized.entry
            end
        end
    end
    return out
end

local function mapCount(value)
    local count = 0
    if type(value) ~= "table" then
        return count
    end
    for _ in pairs(value) do
        count = count + 1
    end
    return count
end

local function loadIndex()
    if cached_saved_recipes ~= nil then
        return cloneValue(cached_saved_recipes, 0)
    end

    local value = sectionGet(KEY_SAVED_RECIPES)
    if type(value) ~= "table" then
        cached_saved_recipes = {}
        return {}
    end
    local out = normalizeSavedRecipeIndex(value)
    cached_saved_recipes = out
    return cloneValue(out, 0)
end

local function saveIndex(index)
    cached_saved_recipes = cloneValue(index or {}, 0)
    sectionSet(KEY_SAVED_RECIPES, cached_saved_recipes)
end

local function loadLifecycleIndex()
    if cached_lifecycles ~= nil then
        return cloneValue(cached_lifecycles, 0)
    end

    local value = sectionGet(KEY_LIFECYCLES)
    if type(value) ~= "table" then
        cached_lifecycles = {}
        return {}
    end
    local out = normalizeLifecycleIndex(value)
    cached_lifecycles = out
    return cloneValue(out, 0)
end

local function saveLifecycleIndex(index)
    cached_lifecycles = cloneValue(index or {}, 0)
    sectionSet(KEY_LIFECYCLES, cached_lifecycles)
end

local function nextSavedRecipeId(reserve)
    local next_id = cached_next_saved_recipe_id or tonumber(sectionGet(KEY_NEXT_ID)) or 1
    cached_next_saved_recipe_id = next_id
    if reserve then
        cached_next_saved_recipe_id = next_id + 1
        sectionSet(KEY_NEXT_ID, cached_next_saved_recipe_id)
    end
    return string.format("saved:%d", next_id)
end

function storage.exportState()
    local saved_recipes = loadIndex()
    local lifecycles = loadLifecycleIndex()
    local next_id = cached_next_saved_recipe_id or tonumber(sectionGet(KEY_NEXT_ID)) or 1
    return {
        version = SAVE_STATE_VERSION,
        saved_recipes = cloneValue(saved_recipes, 0),
        generated_spell_lifecycles = cloneValue(lifecycles, 0),
        next_saved_recipe_id = next_id,
        saved_recipe_count = mapCount(saved_recipes),
        lifecycle_count = mapCount(lifecycles),
    }
end

function storage.importState(save_state)
    if type(save_state) ~= "table" then
        cached_saved_recipes = nil
        cached_lifecycles = nil
        cached_next_saved_recipe_id = nil
        return {
            ok = false,
            imported = false,
            reason = "missing_save_state",
            saved_recipe_count = mapCount(loadIndex()),
            lifecycle_count = mapCount(loadLifecycleIndex()),
        }
    end

    local saved_recipes = normalizeSavedRecipeIndex(save_state.saved_recipes)
    local lifecycles = normalizeLifecycleIndex(save_state.generated_spell_lifecycles)
    local next_id = tonumber(save_state.next_saved_recipe_id) or 1
    cached_saved_recipes = cloneValue(saved_recipes, 0)
    cached_lifecycles = cloneValue(lifecycles, 0)
    cached_next_saved_recipe_id = next_id
    sectionSet(KEY_SAVED_RECIPES, cached_saved_recipes)
    sectionSet(KEY_LIFECYCLES, cached_lifecycles)
    sectionSet(KEY_NEXT_ID, cached_next_saved_recipe_id)

    return {
        ok = true,
        imported = true,
        version = tonumber(save_state.version) or 0,
        saved_recipe_count = mapCount(saved_recipes),
        lifecycle_count = mapCount(lifecycles),
        next_saved_recipe_id = next_id,
    }
end

function storage.list()
    local index = loadIndex()
    local out = {}
    for _, saved in pairs(index) do
        out[#out + 1] = cloneValue(saved, 0)
    end
    table.sort(out, function(a, b)
        return tostring(a.title or a.id) < tostring(b.title or b.id)
    end)
    return out
end

function storage.get(saved_recipe_id)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return nil
    end
    local index = loadIndex()
    local saved = index[saved_recipe_id]
    return saved and cloneValue(saved, 0) or nil
end

function storage.save(input, opts)
    local options = opts or {}
    local explicit_id = input and input.id or options.id
    local id = explicit_id or nextSavedRecipeId(false)
    local normalized = saved_recipe_model.normalize(input or {}, {
        id = id,
        now = options.now,
        recipe_options = options.recipe_options,
    })
    if not normalized.ok then
        return normalized
    end

    if not explicit_id then
        nextSavedRecipeId(true)
    end

    local index = loadIndex()
    index[normalized.saved_recipe.id] = normalized.saved_recipe
    saveIndex(index)

    local lifecycle_index = loadLifecycleIndex()
    lifecycle_index[normalized.saved_recipe.id] = generated_lifecycle.newEntry(normalized.saved_recipe, { now = options.now })
    saveLifecycleIndex(lifecycle_index)

    return {
        ok = true,
        saved_recipe = cloneValue(normalized.saved_recipe, 0),
        errors = {},
        warnings = normalized.warnings or {},
    }
end

function storage.update(saved_recipe_id, patch, opts)
    local existing = storage.get(saved_recipe_id)
    if not existing then
        return {
            ok = false,
            errors = {
                {
                    code = "saved_recipe_not_found",
                    path = "saved_recipe.id",
                    message = string.format("No saved recipe found for id=%s", tostring(saved_recipe_id)),
                    severity = "error",
                },
            },
            warnings = {},
        }
    end

    local sanitized_patch = cloneValue(patch or {}, 0)
    sanitized_patch.id = saved_recipe_id

    local updated = saved_recipe_model.update(existing, sanitized_patch, opts)
    if not updated.ok then
        return updated
    end
    if patchTouchesRecipe(sanitized_patch) and not recipesHaveSameEffects(existing.recipe, updated.saved_recipe.recipe) then
        updated.saved_recipe.recipe_id = nil
        updated.saved_recipe.last_validated_recipe_id = nil
        updated.saved_recipe.last_previewed_recipe_id = nil
    end

    local index = loadIndex()
    index[saved_recipe_id] = updated.saved_recipe
    saveIndex(index)
    return {
        ok = true,
        saved_recipe = cloneValue(updated.saved_recipe, 0),
        errors = {},
        warnings = updated.warnings or {},
    }
end

function storage.delete(saved_recipe_id)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return {
            ok = false,
            deleted = false,
            saved_recipe_id = saved_recipe_id,
            errors = {
                {
                    code = "saved_recipe_id_required",
                    path = "saved_recipe.id",
                    message = "saved recipe id must be a non-empty string",
                    severity = "error",
                },
            },
        }
    end

    local index = loadIndex()
    local existed = index[saved_recipe_id] ~= nil
    index[saved_recipe_id] = nil
    saveIndex(index)

    local lifecycle_index = loadLifecycleIndex()
    lifecycle_index[saved_recipe_id] = nil
    saveLifecycleIndex(lifecycle_index)

    return {
        ok = true,
        deleted = existed,
        saved_recipe_id = saved_recipe_id,
    }
end

function storage.getLifecycle(saved_recipe_id)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return nil
    end
    local index = loadLifecycleIndex()
    local entry = index[saved_recipe_id]
    return entry and cloneValue(entry, 0) or nil
end

function storage.listLifecycles()
    return loadLifecycleIndex()
end

function storage.putLifecycle(saved_recipe_id, entry)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return {
            ok = false,
            errors = {
                {
                    code = "saved_recipe_id_required",
                    path = "saved_recipe.id",
                    message = "saved recipe id must be a non-empty string",
                    severity = "error",
                },
            },
            warnings = {},
        }
    end

    local validated = generated_lifecycle.validateEntry(entry)
    if not validated.ok then
        return validated
    end
    validated.entry.saved_recipe_id = validated.entry.saved_recipe_id or saved_recipe_id

    local index = loadLifecycleIndex()
    index[saved_recipe_id] = validated.entry
    saveLifecycleIndex(index)
    return {
        ok = true,
        lifecycle = cloneValue(validated.entry, 0),
        errors = {},
        warnings = validated.warnings or {},
    }
end

function storage.clearForTests()
    cached_saved_recipes = {}
    cached_lifecycles = {}
    cached_next_saved_recipe_id = 1
    sectionSet(KEY_SAVED_RECIPES, {})
    sectionSet(KEY_LIFECYCLES, {})
    sectionSet(KEY_NEXT_ID, 1)
end

return storage
