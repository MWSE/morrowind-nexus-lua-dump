local core = require("openmw.core")

local plan_cache = require("scripts.spellforge.global.plan_cache")
local records = require("scripts.spellforge.global.records")
local log = require("scripts.spellforge.shared.log").new("global.rehydrate")

local rehydrate = {}

local function safeCall(fn)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return nil
end

local function joinIds(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = tostring(value)
    end
    return table.concat(out, ",")
end

local function firstRoot(entry)
    return type(entry) == "table" and type(entry.node_metadata) == "table" and entry.node_metadata[1] or nil
end

local function effectListForEntry(entry)
    local root = firstRoot(entry)
    if root and type(root.effect_list) == "table" and #root.effect_list > 0 then
        return root.effect_list
    end
    if type(entry) == "table" and type(entry.recipe) == "table" and type(entry.recipe.effects) == "table" and #entry.recipe.effects > 0 then
        return entry.recipe.effects
    end
    return nil
end

local function spellRecordExists(spell_id)
    if type(spell_id) ~= "string" or spell_id == "" then
        return false
    end
    return safeCall(function()
        return core.magic.spells.records[spell_id] ~= nil
    end) == true
end

local function helperEngineIds(attached)
    local out = {}
    local helpers = attached and attached.plan and attached.plan.helper_records or {}
    for _, helper in ipairs(helpers) do
        if helper and type(helper.engine_id) == "string" and helper.engine_id ~= "" then
            out[#out + 1] = helper.engine_id
        end
    end
    return out
end

local function result(payload)
    payload.ok = payload.ok == true
    payload.success = payload.ok
    return payload
end

function rehydrate.rehydrateEntry(recipe_id, entry, opts)
    local options = opts or {}
    local saved_recipe_id = options.saved_recipe_id
    local old_frontend_spell_id = options.frontend_spell_id or (entry and entry.frontend_spell_id)
    local generated_engine_spell_ids = options.generated_engine_spell_ids or (entry and entry.generated_engine_spell_ids) or {}
    local record_exists = spellRecordExists(old_frontend_spell_id)

    log.info(string.format(
        "SPELLFORGE_REHYDRATE_ENTRY saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s generated_engine_spell_ids=%s record_exists=%s status=%s",
        tostring(saved_recipe_id),
        tostring(recipe_id),
        tostring(old_frontend_spell_id),
        joinIds(generated_engine_spell_ids),
        tostring(record_exists),
        tostring(options.status)
    ))

    if type(entry) ~= "table" then
        log.warn(string.format(
            "SPELLFORGE_REHYDRATE_GLOBAL_INDEX_MISSING saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s action=recompile_requested",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
        log.info(string.format(
            "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=global_index_missing",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
        return result({
            request_id = options.request_id,
            saved_recipe_id = saved_recipe_id,
            recipe_id = recipe_id,
            old_frontend_spell_id = old_frontend_spell_id,
            recompile_requested = true,
            action = "recompile_requested",
            error = "global_index_missing",
        })
    end

    log.info(string.format(
        "SPELLFORGE_REHYDRATE_GLOBAL_INDEX_OK saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s",
        tostring(saved_recipe_id),
        tostring(recipe_id),
        tostring(old_frontend_spell_id)
    ))

    if record_exists then
        log.info(string.format(
            "SPELLFORGE_REHYDRATE_FRONTEND_RECORD_OK saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
    else
        log.warn(string.format(
            "SPELLFORGE_REHYDRATE_FRONTEND_RECORD_MISSING saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s action=recompile_requested",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
        log.info(string.format(
            "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=frontend_record_missing",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
        return result({
            request_id = options.request_id,
            saved_recipe_id = saved_recipe_id,
            recipe_id = recipe_id,
            old_frontend_spell_id = old_frontend_spell_id,
            recompile_requested = true,
            action = "recompile_requested",
            error = "frontend_record_missing",
        })
    end

    local effects = effectListForEntry(entry)
    if not effects then
        log.warn(string.format(
            "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=effect_list_missing",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id)
        ))
        return result({
            request_id = options.request_id,
            saved_recipe_id = saved_recipe_id,
            recipe_id = recipe_id,
            old_frontend_spell_id = old_frontend_spell_id,
            recompile_requested = true,
            action = "recompile_requested",
            error = "effect_list_missing",
        })
    end

    local compiled = plan_cache.compileOrGet(effects, { limits = options.limits })
    if not compiled.ok then
        log.warn(string.format(
            "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=plan_compile_failed plan_recipe_id=%s",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id),
            tostring(compiled.recipe_id)
        ))
        return result({
            request_id = options.request_id,
            saved_recipe_id = saved_recipe_id,
            recipe_id = recipe_id,
            old_frontend_spell_id = old_frontend_spell_id,
            plan_recipe_id = compiled.recipe_id,
            recompile_requested = true,
            action = "recompile_requested",
            error = "plan_compile_failed",
            errors = compiled.errors,
        })
    end

    log.info(string.format(
        "SPELLFORGE_REHYDRATE_PLAN_OK saved_recipe_id=%s recipe_id=%s plan_recipe_id=%s plan_cached=%s",
        tostring(saved_recipe_id),
        tostring(recipe_id),
        tostring(compiled.recipe_id),
        tostring(plan_cache.has(compiled.recipe_id))
    ))

    local attached = plan_cache.attachHelperRecords(compiled.recipe_id, { limits = options.limits })
    if not attached.ok then
        log.warn(string.format(
            "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=helper_records_failed plan_recipe_id=%s",
            tostring(saved_recipe_id),
            tostring(recipe_id),
            tostring(old_frontend_spell_id),
            tostring(compiled.recipe_id)
        ))
        return result({
            request_id = options.request_id,
            saved_recipe_id = saved_recipe_id,
            recipe_id = recipe_id,
            old_frontend_spell_id = old_frontend_spell_id,
            plan_recipe_id = compiled.recipe_id,
            recompile_requested = true,
            action = "recompile_requested",
            error = "helper_records_failed",
            errors = attached.errors,
        })
    end

    local helper_ids = helperEngineIds(attached)
    records.updateGeneratedEngineSpellIds(recipe_id, old_frontend_spell_id, helper_ids)
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_HELPERS_OK saved_recipe_id=%s recipe_id=%s plan_recipe_id=%s helper_record_count=%s generated_engine_spell_ids=%s",
        tostring(saved_recipe_id),
        tostring(recipe_id),
        tostring(compiled.recipe_id),
        tostring(attached.record_count or 0),
        joinIds(helper_ids)
    ))
    log.info(string.format(
        "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s action=rehydrated helper_record_count=%s",
        tostring(saved_recipe_id),
        tostring(recipe_id),
        tostring(old_frontend_spell_id),
        tostring(attached.record_count or 0)
    ))

    return result({
        ok = true,
        request_id = options.request_id,
        saved_recipe_id = saved_recipe_id,
        recipe_id = recipe_id,
        plan_recipe_id = compiled.recipe_id,
        old_frontend_spell_id = old_frontend_spell_id,
        frontend_spell_id = old_frontend_spell_id,
        generated_engine_spell_ids = records.getByRecipeId(recipe_id) and records.getByRecipeId(recipe_id).generated_engine_spell_ids or generated_engine_spell_ids,
        record_exists = true,
        global_index_exists = true,
        plan_cached = true,
        helper_record_count = attached.record_count or 0,
        action = "rehydrated",
    })
end

function rehydrate.rehydrateRequest(payload)
    local request = payload or {}
    local recipe_id = request.recipe_id
    local entry = type(recipe_id) == "string" and records.getByRecipeId(recipe_id) or nil
    if not entry and type(request.frontend_spell_id) == "string" then
        recipe_id, entry = records.findByEngineSpellId(request.frontend_spell_id)
    end

    log.info(string.format(
        "SPELLFORGE_REHYDRATE_START saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s mode=request",
        tostring(request.saved_recipe_id),
        tostring(recipe_id or request.recipe_id),
        tostring(request.frontend_spell_id)
    ))
    local out = rehydrate.rehydrateEntry(recipe_id or request.recipe_id, entry, {
        request_id = request.request_id,
        saved_recipe_id = request.saved_recipe_id,
        frontend_spell_id = request.frontend_spell_id,
        generated_engine_spell_ids = request.generated_engine_spell_ids,
        status = request.status,
        limits = request.limits,
    })
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_COMPLETE saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s ok=%s action=%s error=%s mode=request",
        tostring(request.saved_recipe_id),
        tostring(out.recipe_id or recipe_id or request.recipe_id),
        tostring(request.frontend_spell_id),
        tostring(out.ok == true),
        tostring(out.action),
        tostring(out.error)
    ))
    return out
end

function rehydrate.rehydrateAll(opts)
    local options = opts or {}
    local all = records.listAll()
    local count, ok_count, stale_count, failed_count = 0, 0, 0, 0
    for _ in pairs(all) do
        count = count + 1
    end
    log.info(string.format("SPELLFORGE_REHYDRATE_START count=%s mode=global_index", tostring(count)))
    for recipe_id, entry in pairs(all) do
        local out = rehydrate.rehydrateEntry(recipe_id, entry, {
            limits = options.limits,
        })
        if out.ok then
            ok_count = ok_count + 1
        elseif out.recompile_requested then
            stale_count = stale_count + 1
        else
            failed_count = failed_count + 1
        end
    end
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_COMPLETE count=%s ok=%s stale=%s failed=%s mode=global_index",
        tostring(count),
        tostring(ok_count),
        tostring(stale_count),
        tostring(failed_count)
    ))
    return {
        ok = failed_count == 0,
        count = count,
        ok_count = ok_count,
        stale_count = stale_count,
        failed_count = failed_count,
    }
end

return rehydrate
