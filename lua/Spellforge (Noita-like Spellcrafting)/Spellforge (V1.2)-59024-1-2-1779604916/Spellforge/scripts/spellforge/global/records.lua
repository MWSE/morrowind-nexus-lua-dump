local storage = require("openmw.storage")
local world = require("openmw.world")
local log = require("scripts.spellforge.shared.log").new("global.records")

local records = {}

local section = storage.globalSection("SpellforgeCompiled")
local KEY_RECIPE_INDEX = "recipe_index"

local function sanitizeGeneratedSpellIds(generated_spell_ids)
    local out = {}
    if type(generated_spell_ids) ~= "table" then
        return out
    end
    for i, spell_id in ipairs(generated_spell_ids) do
        if type(spell_id) == "string" then
            out[i] = spell_id
        end
    end
    return out
end

local function sanitizeGeneratedEngineSpellIds(generated_engine_spell_ids)
    local out = {}
    if type(generated_engine_spell_ids) ~= "table" then
        return out
    end
    for i, engine_id in ipairs(generated_engine_spell_ids) do
        if type(engine_id) == "string" then
            out[i] = engine_id
        end
    end
    return out
end

local function sanitizeStringArray(values)
    local out = {}
    if type(values) ~= "table" then
        return out
    end
    for i, value in ipairs(values) do
        if type(value) == "string" then
            out[i] = value
        end
    end
    return out
end

local function sanitizeRealEffects(real_effects)
    local out = {}
    if type(real_effects) ~= "table" then
        return out
    end
    for i, effect in ipairs(real_effects) do
        if type(effect) == "table" then
            out[i] = {
                id = effect.id,
                engine_effect_id = type(effect.engine_effect_id) == "string" and effect.engine_effect_id or nil,
                range = effect.range,
                area = effect.area,
                duration = effect.duration,
                magnitudeMin = effect.magnitudeMin,
                magnitudeMax = effect.magnitudeMax,
                affectedAttribute = effect.affectedAttribute,
                affectedSkill = effect.affectedSkill,
            }
        end
    end
    return out
end

local function sanitizeParams(params)
    local out = {}
    if type(params) ~= "table" then
        return nil
    end
    for k, v in pairs(params) do
        if type(k) == "string" and (type(v) == "string" or type(v) == "number" or type(v) == "boolean") then
            out[k] = v
        end
    end
    return out
end

local function sanitizeEffectList(effect_list)
    local out = {}
    if type(effect_list) ~= "table" then
        return out
    end
    for i, effect in ipairs(effect_list) do
        if type(effect) == "table" then
            out[i] = {
                id = effect.id,
                engine_effect_id = type(effect.engine_effect_id) == "string" and effect.engine_effect_id or nil,
                range = effect.range,
                area = effect.area,
                duration = effect.duration,
                magnitudeMin = effect.magnitudeMin,
                magnitudeMax = effect.magnitudeMax,
                affectedAttribute = effect.affectedAttribute,
                affectedSkill = effect.affectedSkill,
                params = sanitizeParams(effect.params),
                ui_id = type(effect.ui_id) == "string" and effect.ui_id or nil,
            }
        end
    end
    return out
end

local function sanitizeNodeMetadata(node_metadata)
    local out = {}
    if type(node_metadata) ~= "table" then
        return out
    end

    for i, node in ipairs(node_metadata) do
        if type(node) == "table" then
            out[i] = {
                logical_id = type(node.logical_id) == "string" and node.logical_id or nil,
                engine_id = type(node.engine_id) == "string" and node.engine_id or nil,
                base_spell_id = type(node.base_spell_id) == "string" and node.base_spell_id or nil,
                marker_range = node.marker_range,
                real_effects = sanitizeRealEffects(node.real_effects),
                effect_list = sanitizeEffectList(node.effect_list),
            }
        end
    end

    return out
end

local function sanitizeRecipe(recipe)
    if type(recipe) ~= "table" then
        return nil
    end
    return {
        id = type(recipe.id) == "string" and recipe.id or nil,
        title = type(recipe.title) == "string" and recipe.title or nil,
        name = type(recipe.name) == "string" and recipe.name or nil,
        effects = sanitizeEffectList(recipe.effects),
    }
end

local function sanitizeEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local generated_spell_ids = sanitizeGeneratedSpellIds(entry.generated_spell_ids)
    local generated_engine_spell_ids = sanitizeGeneratedEngineSpellIds(entry.generated_engine_spell_ids)
    if #generated_engine_spell_ids == 0 and type(entry.frontend_spell_id) == "string" and entry.frontend_spell_id ~= "" then
        generated_engine_spell_ids[1] = entry.frontend_spell_id
    end
    local frontend_logical_id = type(entry.frontend_logical_id) == "string" and entry.frontend_logical_id or generated_spell_ids[1]
    return {
        canonical = type(entry.canonical) == "string" and entry.canonical or nil,
        source_kind = type(entry.source_kind) == "string" and entry.source_kind or nil,
        frontend_spell_id = type(entry.frontend_spell_id) == "string" and entry.frontend_spell_id or nil,
        frontend_logical_id = frontend_logical_id,
        frontend_name = type(entry.frontend_name) == "string" and entry.frontend_name or nil,
        generated_spell_ids = generated_spell_ids,
        generated_engine_spell_ids = generated_engine_spell_ids,
        cost_model_version = type(entry.cost_model_version) == "string" and entry.cost_model_version or nil,
        compiled_cost = tonumber(entry.compiled_cost),
        dominant_school = type(entry.dominant_school) == "string" and entry.dominant_school or nil,
        cost_tier = type(entry.cost_tier) == "string" and entry.cost_tier or nil,
        cost_model_hash = type(entry.cost_model_hash) == "string" and entry.cost_model_hash or nil,
        cost_breakdown_hash = type(entry.cost_breakdown_hash) == "string" and entry.cost_breakdown_hash or nil,
        frontend_display_signature_version = type(entry.frontend_display_signature_version) == "string" and entry.frontend_display_signature_version or nil,
        frontend_display_effect_ids = sanitizeStringArray(entry.frontend_display_effect_ids),
        frontend_display_icon_paths = sanitizeStringArray(entry.frontend_display_icon_paths),
        frontend_display_hash = type(entry.frontend_display_hash) == "string" and entry.frontend_display_hash or nil,
        node_metadata = sanitizeNodeMetadata(entry.node_metadata),
        recipe = sanitizeRecipe(entry.recipe),
        marker_effect_applied = entry.marker_effect_applied == true,
    }
end

local function normalizeRecipeIndex(value)
    local normalized = {}
    if value == nil then
        return normalized
    end

    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) == "string" then
                normalized[k] = sanitizeEntry(v)
            end
        end
        return normalized
    end

    local ok, err = pcall(function()
        for k, v in pairs(value) do
            if type(k) == "string" then
                normalized[k] = sanitizeEntry(v)
            end
        end
    end)
    if not ok then
        log.error(string.format("records.normalizeRecipeIndex failed: %s", tostring(err)))
        return {}
    end

    return normalized
end

local in_memory = {
    by_recipe = normalizeRecipeIndex(section:get(KEY_RECIPE_INDEX)),
}

local function mapCount(index)
    local count = 0
    for _ in pairs(index or {}) do
        count = count + 1
    end
    return count
end

local function persist()
    section:set(KEY_RECIPE_INDEX, in_memory.by_recipe)
end

function records.reloadFromStorage(reason)
    local before_count = mapCount(in_memory.by_recipe)
    in_memory.by_recipe = normalizeRecipeIndex(section:get(KEY_RECIPE_INDEX))
    local after_count = mapCount(in_memory.by_recipe)
    log.info(string.format(
        "SPELLFORGE_RECORDS_RELOADED_ON_LOAD reason=%s records_before=%s records_after=%s",
        tostring(reason),
        tostring(before_count),
        tostring(after_count)
    ))
    return {
        records_before = before_count,
        records_after = after_count,
    }
end

function records.exportState()
    local recipe_index = records.listAll()
    local count = mapCount(recipe_index)
    log.info(string.format(
        "SPELLFORGE_RECORDS_EXPORTED_ON_SAVE records=%s",
        tostring(count)
    ))
    return {
        version = 1,
        recipe_index = recipe_index,
        record_count = count,
    }
end

function records.importState(save_state, reason)
    local state = save_state or {}
    local recipe_index = type(state.recipe_index) == "table" and state.recipe_index or nil
    if recipe_index == nil then
        log.info(string.format(
            "SPELLFORGE_RECORDS_IMPORTED_ON_LOAD reason=%s imported=false records_before=%s records_after=%s error=missing_recipe_index",
            tostring(reason),
            tostring(mapCount(in_memory.by_recipe)),
            tostring(mapCount(in_memory.by_recipe))
        ))
        return {
            imported = false,
            records_before = mapCount(in_memory.by_recipe),
            records_after = mapCount(in_memory.by_recipe),
            error = "missing_recipe_index",
        }
    end

    local before_count = mapCount(in_memory.by_recipe)
    in_memory.by_recipe = normalizeRecipeIndex(recipe_index)
    persist()
    local after_count = mapCount(in_memory.by_recipe)
    log.info(string.format(
        "SPELLFORGE_RECORDS_IMPORTED_ON_LOAD reason=%s imported=true records_before=%s records_after=%s",
        tostring(reason),
        tostring(before_count),
        tostring(after_count)
    ))
    return {
        imported = true,
        records_before = before_count,
        records_after = after_count,
    }
end

function records.getByRecipeId(recipe_id)
    return in_memory.by_recipe[recipe_id]
end

function records.listAll()
    local out = {}
    for recipe_id, entry in pairs(in_memory.by_recipe) do
        if type(recipe_id) == "string" and entry ~= nil then
            out[recipe_id] = sanitizeEntry(entry)
        end
    end
    return out
end

function records.put(recipe_id, payload)
    in_memory.by_recipe[recipe_id] = sanitizeEntry(payload)
    persist()
end

function records.updateGeneratedEngineSpellIds(recipe_id, frontend_spell_id, helper_engine_ids)
    local entry = in_memory.by_recipe[recipe_id]
    if type(entry) ~= "table" then
        return false
    end
    local generated_engine_spell_ids = {}
    if type(frontend_spell_id) == "string" and frontend_spell_id ~= "" then
        generated_engine_spell_ids[#generated_engine_spell_ids + 1] = frontend_spell_id
        entry.frontend_spell_id = frontend_spell_id
    elseif type(entry.frontend_spell_id) == "string" and entry.frontend_spell_id ~= "" then
        generated_engine_spell_ids[#generated_engine_spell_ids + 1] = entry.frontend_spell_id
    end
    for _, engine_id in ipairs(helper_engine_ids or {}) do
        if type(engine_id) == "string" and engine_id ~= "" then
            generated_engine_spell_ids[#generated_engine_spell_ids + 1] = engine_id
        end
    end
    entry.generated_engine_spell_ids = generated_engine_spell_ids
    persist()
    return true
end

function records.deleteByRecipeId(recipe_id)
    if in_memory.by_recipe[recipe_id] ~= nil then
        in_memory.by_recipe[recipe_id] = nil
        persist()
        return true
    end
    return false
end

function records.createRecord(draft)
    local ok, created_or_err = pcall(world.createRecord, draft)
    if not ok then
        log.error(string.format("records.createRecord failed: %s", tostring(created_or_err)))
        return nil, created_or_err
    end
    return created_or_err, nil
end

function records.deleteBySpellId(spell_id)
    for recipe_id, entry in pairs(in_memory.by_recipe) do
        if entry.frontend_spell_id == spell_id then
            in_memory.by_recipe[recipe_id] = nil
            persist()
            return true, recipe_id
        end
    end
    return false, nil
end

function records.findByEngineSpellId(engine_id)
    if type(engine_id) ~= "string" or engine_id == "" then
        return nil, nil
    end
    for recipe_id, entry in pairs(in_memory.by_recipe) do
        if entry and entry.frontend_spell_id == engine_id then
            return recipe_id, entry
        end
        for _, generated_engine_id in ipairs(entry and entry.generated_engine_spell_ids or {}) do
            if generated_engine_id == engine_id then
                return recipe_id, entry
            end
        end
    end
    return nil, nil
end


function records.findRootNodeByEngineSpellId(engine_id)
    local recipe_id, entry = records.findByEngineSpellId(engine_id)
    if not recipe_id or not entry then
        return nil, nil, nil
    end
    local root = entry.node_metadata and entry.node_metadata[1] or nil
    return recipe_id, entry, root
end

return records
