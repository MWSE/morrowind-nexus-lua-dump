---@omw-context none
local validation = require("scripts.spellforge.shared.validation_contract")

local lifecycle = {}

lifecycle.VERSION = "spellforge-generated-spell-lifecycle-v1"

lifecycle.STATUS_DRAFT = "draft"
lifecycle.STATUS_VALIDATED = "validated"
lifecycle.STATUS_PREVIEWED = "previewed"
lifecycle.STATUS_COMPILE_PENDING = "compile_pending"
lifecycle.STATUS_COMPILED = "compiled"
lifecycle.STATUS_STALE = "stale"
lifecycle.STATUS_DELETE_PENDING = "delete_pending"
lifecycle.STATUS_DELETED = "deleted"
lifecycle.STATUS_ERROR = "error"

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

local function cloneArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

local function firstArrayValue(values)
    if type(values) ~= "table" then
        return nil
    end
    return values[1]
end

local function nowToken(opts)
    local options = opts or {}
    if options.now ~= nil then
        return options.now
    end
    return os.time()
end

local function ensureEntry(entry, opts)
    local out = cloneValue(entry or {}, 0)
    out.lifecycle_version = lifecycle.VERSION
    out.status = out.status or lifecycle.STATUS_DRAFT
    out.compile_generation = tonumber(out.compile_generation) or 0
    out.generated_spell_ids = cloneArray(out.generated_spell_ids)
    out.generated_engine_spell_ids = cloneArray(out.generated_engine_spell_ids)
    out.updated_at = nowToken(opts)
    return out
end

function lifecycle.newEntry(saved_recipe, opts)
    local saved = saved_recipe or {}
    return {
        lifecycle_version = lifecycle.VERSION,
        saved_recipe_id = saved.id,
        recipe_id = saved.recipe_id,
        status = lifecycle.STATUS_DRAFT,
        compile_generation = 0,
        frontend_spell_id = nil,
        frontend_logical_id = nil,
        generated_spell_ids = {},
        generated_engine_spell_ids = {},
        cleanup_required = false,
        created_at = nowToken(opts),
        updated_at = nowToken(opts),
    }
end

function lifecycle.applyValidation(entry, validation_result, opts)
    local out = ensureEntry(entry, opts)
    local result = validation_result or {}
    out.last_validation = cloneValue(result.validation or result, 0)
    out.last_validated_recipe_id = result.recipe_id
    if result.ok == true then
        out.recipe_id = result.recipe_id or out.recipe_id
        out.status = lifecycle.STATUS_VALIDATED
        out.error = nil
    else
        out.status = lifecycle.STATUS_ERROR
        out.error = "validation_failed"
    end
    return out
end

function lifecycle.applyPreview(entry, preview_result, opts)
    local out = ensureEntry(entry, opts)
    local result = preview_result or {}
    out.last_preview = cloneValue(result.preview, 0)
    out.last_previewed_recipe_id = result.recipe_id
    if result.ok == true then
        out.recipe_id = result.recipe_id or out.recipe_id
        out.status = lifecycle.STATUS_PREVIEWED
        out.error = nil
    else
        out.status = lifecycle.STATUS_ERROR
        out.error = "preview_failed"
    end
    return out
end

function lifecycle.markCompileRequested(entry, request_id, opts)
    local out = ensureEntry(entry, opts)
    out.status = lifecycle.STATUS_COMPILE_PENDING
    out.compile_request_id = request_id
    out.compile_generation = out.compile_generation + 1
    out.error = nil
    return out
end

function lifecycle.applyCompileResult(entry, compile_result, opts)
    local out = ensureEntry(entry, opts)
    local result = compile_result or {}
    out.last_compile_result = cloneValue(result, 0)
    if result.ok == true then
        out.status = lifecycle.STATUS_COMPILED
        out.recipe_id = result.recipe_id or out.recipe_id
        out.frontend_spell_id = result.spell_id or out.frontend_spell_id
        out.frontend_logical_id = result.frontend_logical_id or out.frontend_logical_id
        if type(result.generated_spell_ids) == "table" then
            out.generated_spell_ids = cloneArray(result.generated_spell_ids)
        elseif result.frontend_logical_id ~= nil and #out.generated_spell_ids == 0 then
            out.generated_spell_ids[1] = result.frontend_logical_id
        end
        if type(result.generated_engine_spell_ids) == "table" then
            out.generated_engine_spell_ids = cloneArray(result.generated_engine_spell_ids)
        elseif result.spell_id ~= nil and #out.generated_engine_spell_ids == 0 then
            out.generated_engine_spell_ids[1] = result.spell_id
        end
        out.frontend_spell_id = out.frontend_spell_id or firstArrayValue(out.generated_engine_spell_ids)
        out.cleanup_required = false
        out.error = nil
    else
        out.status = lifecycle.STATUS_ERROR
        out.error = result.error or result.error_message or "compile_failed"
    end
    return out
end

function lifecycle.markRecipeChanged(entry, saved_recipe, opts)
    local out = ensureEntry(entry, opts)
    local saved = saved_recipe or {}
    local next_recipe_id = saved.recipe_id or saved.last_previewed_recipe_id or saved.last_validated_recipe_id
    if out.status == lifecycle.STATUS_COMPILED and next_recipe_id ~= nil and next_recipe_id ~= out.recipe_id then
        out.status = lifecycle.STATUS_STALE
        out.cleanup_required = true
        out.stale_reason = "recipe_id_changed"
        out.next_recipe_id = next_recipe_id
    elseif out.status == lifecycle.STATUS_COMPILED and next_recipe_id == nil then
        out.status = lifecycle.STATUS_STALE
        out.cleanup_required = true
        out.stale_reason = "recipe_changed"
        out.next_recipe_id = nil
    elseif out.status == lifecycle.STATUS_COMPILED then
        out.cleanup_required = false
        out.stale_reason = nil
        out.next_recipe_id = nil
    else
        out.status = lifecycle.STATUS_DRAFT
        out.cleanup_required = out.cleanup_required == true
    end
    return out
end

function lifecycle.markStale(entry, reason, opts)
    local out = ensureEntry(entry, opts)
    out.status = lifecycle.STATUS_STALE
    out.cleanup_required = true
    out.stale_reason = reason or "stale_generated_id"
    out.error = nil
    return out
end

function lifecycle.cleanupPlan(entry)
    local out = ensureEntry(entry)
    local has_compiled_identity = out.frontend_spell_id ~= nil
        or #(out.generated_engine_spell_ids or {}) > 0
    return {
        ok = true,
        needed = out.cleanup_required == true and has_compiled_identity,
        recipe_id = out.recipe_id,
        spell_id = out.frontend_spell_id,
        generated_engine_spell_ids = cloneArray(out.generated_engine_spell_ids),
        remove_from_spellbook = false,
        delete_compiled_record = true,
        reason = out.stale_reason or "lifecycle_cleanup",
    }
end

function lifecycle.markDeleteRequested(entry, opts)
    local out = ensureEntry(entry, opts)
    out.status = lifecycle.STATUS_DELETE_PENDING
    out.cleanup_required = true
    return out
end

function lifecycle.markDeleted(entry, opts)
    local out = ensureEntry(entry, opts)
    out.status = lifecycle.STATUS_DELETED
    out.cleanup_required = false
    out.deleted_at = nowToken(opts)
    return out
end

function lifecycle.validateEntry(entry)
    if type(entry) ~= "table" then
        return {
            ok = false,
            errors = { validation.error("generated_spell", "generated spell lifecycle entry must be a table", "lifecycle_entry_not_table") },
            warnings = {},
        }
    end
    if entry.lifecycle_version ~= nil and entry.lifecycle_version ~= lifecycle.VERSION then
        return {
            ok = false,
            errors = {
                validation.error(
                    "generated_spell.lifecycle_version",
                    string.format("unsupported lifecycle_version: %s", tostring(entry.lifecycle_version)),
                    "unsupported_lifecycle_version"
                ),
            },
            warnings = {},
        }
    end
    return {
        ok = true,
        entry = ensureEntry(entry),
        errors = {},
        warnings = {},
    }
end

return lifecycle
