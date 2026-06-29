---@omw-context global
local async = require("openmw.async")
local core = require("openmw.core")
local types = require("openmw.types")
local util = require("openmw.util")

local dev = require("scripts.spellforge.shared.dev")
local effect_identity = require("scripts.spellforge.shared.effect_identity")
local events = require("scripts.spellforge.shared.events")
local limits = require("scripts.spellforge.shared.limits")
local live_bounce = require("scripts.spellforge.global.live_bounce")
local live_chain = require("scripts.spellforge.global.live_chain")
local live_pierce = require("scripts.spellforge.global.live_pierce")
local live_simple_dispatch = require("scripts.spellforge.global.live_simple_dispatch")
local live_soft_homing = require("scripts.spellforge.global.live_soft_homing")
local live_timer = require("scripts.spellforge.global.live_timer")
local live_trigger = require("scripts.spellforge.global.live_trigger")
local log = require("scripts.spellforge.shared.log").new("global.executor")
local orchestrator = require("scripts.spellforge.global.orchestrator")
local projectile_registry = require("scripts.spellforge.global.projectile_registry")
local records = require("scripts.spellforge.global.records")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_hits = require("scripts.spellforge.global.runtime_hits")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local projectile_speed_policy = require("scripts.spellforge.global.projectile_speed_policy")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")

local executor = {}

local watchers = {}
local dispatch_spell_cache = {}
local launch_cookies = {}
local proxy_active_cleanup_queue = {}

local player_ref = nil
local last_active_spell_ids = {}
local fireball_logged = false
local target_filter_registered = false
local DISPATCH_KIND_COMPILED = "compiled_spellforge"
local DISPATCH_KIND_COMPILED_2_2C_HELPER = "compiled_spellforge_2_2c_helper"
local PROXY_ACTIVE_CLEANUP_MAX_SECONDS = 0.20
local PROXY_ACTIVE_CLEANUP_MAX_ATTEMPTS = 8

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

local function safeSummary(module, fallback)
    if type(module) ~= "table" or type(module.summary) ~= "function" then
        return fallback or {}
    end
    local ok, result = pcall(module.summary)
    if ok and type(result) == "table" then
        return result
    end
    return fallback or {}
end

local function transientCounts()
    local projectiles = safeSummary(projectile_registry)
    local jobs = safeSummary(orchestrator)
    local timers = safeSummary(live_timer)
    local triggers = safeSummary(live_trigger)
    local chains = safeSummary(live_chain)
    local bounces = safeSummary(live_bounce)
    local pierces = safeSummary(live_pierce)
    local homing = safeSummary(live_soft_homing)
    return {
        projectiles = tonumber(projectiles.projectiles) or 0,
        homing_entries = tonumber(homing.active_count) or 0,
        timers = tonumber(timers.pending) or 0,
        trigger_bindings = tonumber(triggers.bindings) or 0,
        jobs = tonumber(jobs.jobs) or 0,
        bounce_entries = tonumber(bounces.bindings) or 0,
        pierce_entries = tonumber(pierces.bindings) or 0,
        chain_entries = tonumber(chains.bindings) or 0,
        launch_cookies = countMap(launch_cookies),
        watchers = countMap(watchers),
        proxy_active_cleanup = #proxy_active_cleanup_queue,
        active_spell_ids = countMap(last_active_spell_ids),
    }
end

local CAST_TRACE_FIELD_ORDER = {
    "attempt_id",
    "spell_id",
    "recipe_id",
    "variant",
    "reason",
    "ray_hit",
    "ray_distance",
    "hitObject_present",
    "dispatch_count",
    "cast_id",
    "live_2_2c",
    "projectile_id",
    "projectile_count",
    "job_id",
    "error",
}

local function appendCastTraceField(parts, fields, key)
    local value = fields and fields[key]
    if value ~= nil then
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
end

local function castTrace(stage, fields, level)
    local parts = {
        "SPELLFORGE_CAST_TRACE stage=" .. tostring(stage),
    }
    local seen = {}
    for _, key in ipairs(CAST_TRACE_FIELD_ORDER) do
        appendCastTraceField(parts, fields, key)
        seen[key] = true
    end
    for key in pairs(fields or {}) do
        if not seen[key] then
            appendCastTraceField(parts, fields, key)
        end
    end
    local message = table.concat(parts, " ")
    if level == "warn" then
        log.warn(message)
    elseif level == "error" then
        log.error(message)
    else
        log.info(message)
    end
end

local function clearTransientModule(module, name, reason)
    if type(module) ~= "table" then
        return
    end
    local clear = module.clearTransient or module.clearForTests
    if type(clear) ~= "function" then
        return
    end
    local ok, err = pcall(clear, reason)
    if not ok then
        log.warn(string.format("runtime reset clear failed module=%s reason=%s err=%s", tostring(name), tostring(reason), tostring(err)))
    end
end

function executor.resetTransientRuntime(reason, opts)
    local options = opts or {}
    local reset_reason = reason or "manual"
    local counts = transientCounts()
    local generation_before = runtime_session.currentGeneration()
    log.debug(string.format(
        "SPELLFORGE_RUNTIME_RESET_BEGIN reason=%s projectiles=%s homing_entries=%s timers=%s trigger_bindings=%s jobs=%s bounce_entries=%s pierce_entries=%s chain_entries=%s launch_cookies=%s watchers=%s active_spell_ids=%s runtime_generation_before=%s",
        tostring(reset_reason),
        tostring(counts.projectiles),
        tostring(counts.homing_entries),
        tostring(counts.timers),
        tostring(counts.trigger_bindings),
        tostring(counts.jobs),
        tostring(counts.bounce_entries),
        tostring(counts.pierce_entries),
        tostring(counts.chain_entries),
        tostring(counts.launch_cookies),
        tostring(counts.watchers),
        tostring(counts.active_spell_ids),
        tostring(generation_before)
    ))

    local generation_after = runtime_session.increment(reset_reason)
    launch_cookies = {}
    watchers = {}
    proxy_active_cleanup_queue = {}
    last_active_spell_ids = {}
    if options.clear_player_ref == true then
        player_ref = nil
    end

    clearTransientModule(orchestrator, "orchestrator", reset_reason)
    clearTransientModule(live_timer, "live_timer", reset_reason)
    clearTransientModule(live_trigger, "live_trigger", reset_reason)
    clearTransientModule(live_chain, "live_chain", reset_reason)
    clearTransientModule(live_bounce, "live_bounce", reset_reason)
    clearTransientModule(live_pierce, "live_pierce", reset_reason)
    clearTransientModule(live_soft_homing, "live_soft_homing", reset_reason)
    clearTransientModule(projectile_registry, "projectile_registry", reset_reason)

    log.info(string.format(
        "SPELLFORGE_RUNTIME_RESET_OK reason=%s runtime_generation=%s",
        tostring(reset_reason),
        tostring(generation_after)
    ))
    log.debug(string.format(
        "SPELLFORGE_RUNTIME_RESET_DETAIL reason=%s projectiles=%s homing_entries=%s timers=%s trigger_bindings=%s jobs=%s bounce_entries=%s pierce_entries=%s chain_entries=%s runtime_generation_before=%s runtime_generation_after=%s",
        tostring(reset_reason),
        tostring(counts.projectiles),
        tostring(counts.homing_entries),
        tostring(counts.timers),
        tostring(counts.trigger_bindings),
        tostring(counts.jobs),
        tostring(counts.bounce_entries),
        tostring(counts.pierce_entries),
        tostring(counts.chain_entries),
        tostring(generation_before),
        tostring(generation_after)
    ))
    log.info(string.format(
        "SPELLFORGE_RUNTIME_SAVE_LOAD_PROJECTILE_CRASH_GUARD_OK reason=%s runtime_generation=%s",
        tostring(reset_reason),
        tostring(generation_after)
    ))
    return {
        runtime_generation_before = generation_before,
        runtime_generation_after = generation_after,
        counts = counts,
    }
end

local function cancelActiveProjectilesForSave()
    local projectile_ids = projectile_registry.projectileIds()
    local ok_count = 0
    local failed_count = 0
    for _, projectile_id in ipairs(projectile_ids) do
        local ok, result = pcall(sfp_adapter.cancelSpell, projectile_id)
        if ok and type(result) == "table" and result.ok == true then
            ok_count = ok_count + 1
        else
            failed_count = failed_count + 1
            log.warn(string.format(
                "SPELLFORGE_RUNTIME_SAVE_CLEANUP_CANCEL_WARN projectile_id=%s ok=%s error=%s",
                tostring(projectile_id),
                tostring(ok),
                tostring(ok and result and result.error or result)
            ))
        end
    end
    return {
        attempted = #projectile_ids,
        ok = ok_count,
        failed = failed_count,
    }
end

local function stringifyValue(value, depth)
    if depth <= 0 then
        return "<max-depth>"
    end
    local value_type = type(value)
    if value_type == "table" then
        local parts = {}
        for k, v in pairs(value) do
            parts[#parts + 1] = string.format("%s=%s", tostring(k), stringifyValue(v, depth - 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(value)
end

local function effectId(effect)
    if type(effect) ~= "table" then
        return nil
    end
    local id = effect.id
    if id == nil then
        return nil
    end
    return string.lower(tostring(id))
end

local function effectListHasSpellforgeOperator(effects)
    if type(effects) ~= "table" then
        return false
    end
    for _, effect in ipairs(effects) do
        local id = effectId(effect)
        if type(id) == "string" and string.sub(id, 1, 11) == "spellforge_" then
            return true
        end
    end
    return false
end

local function rootRequiresLiveRuntime(root)
    return effectListHasSpellforgeOperator(root and root.effect_list)
end

local function readField(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function callMethod(value, method_name)
    local method = readField(value, method_name)
    if type(method) ~= "function" then
        return nil
    end
    local ok, result = pcall(method, value)
    if ok then
        return result
    end
    return nil
end

local function objectValid(value)
    if value == nil then
        return false
    end
    local valid = readField(value, "isValid")
    if type(valid) == "boolean" then
        return valid
    end
    local method_valid = callMethod(value, "isValid")
    if type(method_valid) == "boolean" then
        return method_valid
    end
    return true
end

local function objectToken(value)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return tostring(value)
    end
    return readField(value, "id")
        or readField(value, "recordId")
        or readField(value, "refId")
        or readField(value, "name")
        or objectToken(readField(value, "object"))
end

local function refreshPlayerRefFromPayload(payload, reason)
    if objectValid(player_ref) then
        return false
    end
    if type(payload) ~= "table" then
        return false
    end

    local actor = payload.sender
    if not objectValid(actor) then
        actor = payload.actor
    end
    if not objectValid(actor) then
        return false
    end

    local previous = objectToken(player_ref)
    player_ref = actor
    last_active_spell_ids = {}
    log.debug(string.format(
        "diagnostic player_ref refreshed reason=%s previous=%s actor=%s",
        tostring(reason),
        tostring(previous),
        tostring(objectToken(actor))
    ))
    return true
end

local function actorActiveSpells(actor)
    if not objectValid(actor) then
        return nil, "actor_invalid"
    end
    local ok, active_spells = pcall(types.Actor.activeSpells, actor)
    if ok and active_spells ~= nil then
        return active_spells, nil
    end
    return nil, tostring(active_spells)
end

local function activeSpellSourceId(active_spell)
    return readField(active_spell, "id")
        or readField(active_spell, "spellId")
        or readField(active_spell, "recordId")
end

local function activeSpellInstanceId(active_spell)
    return readField(active_spell, "activeSpellId")
        or readField(active_spell, "active_spell_id")
end

local function tryRemoveProxyActiveSpell(actor, proxy_spell_id)
    if type(proxy_spell_id) ~= "string" or proxy_spell_id == "" then
        return false, "proxy_spell_id_missing"
    end

    local active_spells, active_err = actorActiveSpells(actor)
    if not active_spells then
        return false, active_err
    end

    local remove = readField(active_spells, "remove")
    if type(remove) ~= "function" then
        return false, "activeSpells.remove missing"
    end

    local ok_iter, removed, iter_err = pcall(function()
        for _, active_spell in pairs(active_spells) do
            if activeSpellSourceId(active_spell) == proxy_spell_id then
                local active_spell_id = activeSpellInstanceId(active_spell)
                if type(active_spell_id) ~= "string" or active_spell_id == "" then
                    return false, "activeSpellId missing"
                end
                local ok_remove, remove_err = pcall(remove, active_spells, active_spell_id)
                if ok_remove then
                    return true, nil
                end
                return false, tostring(remove_err)
            end
        end
        return false, nil
    end)

    if not ok_iter then
        return false, tostring(removed)
    end
    return removed, iter_err
end

local function queueProxyActiveCleanup(actor, proxy_spell_id, recipe_id, cast_id)
    if type(proxy_spell_id) ~= "string" or proxy_spell_id == "" or not objectValid(actor) then
        return
    end

    local removed, remove_err = tryRemoveProxyActiveSpell(actor, proxy_spell_id)
    if removed then
        log.debug(string.format(
            "SPELLFORGE_PROXY_ACTIVE_CLEANUP_REMOVED spell_id=%s recipe_id=%s cast_id=%s mode=immediate",
            tostring(proxy_spell_id),
            tostring(recipe_id),
            tostring(cast_id)
        ))
        return
    end
    if remove_err ~= nil then
        log.debug(string.format(
            "SPELLFORGE_PROXY_ACTIVE_CLEANUP_DEFERRED spell_id=%s recipe_id=%s cast_id=%s reason=%s",
            tostring(proxy_spell_id),
            tostring(recipe_id),
            tostring(cast_id),
            tostring(remove_err)
        ))
    end

    proxy_active_cleanup_queue[#proxy_active_cleanup_queue + 1] = {
        actor = actor,
        proxy_spell_id = proxy_spell_id,
        recipe_id = recipe_id,
        cast_id = cast_id,
        elapsed = 0,
        attempts = 1,
    }
end

local function processProxyActiveCleanup(dt_seconds)
    if #proxy_active_cleanup_queue == 0 then
        return
    end

    local next_queue = {}
    for _, cleanup in ipairs(proxy_active_cleanup_queue) do
        if not objectValid(cleanup.actor) then
            log.debug(string.format(
                "SPELLFORGE_PROXY_ACTIVE_CLEANUP_EXPIRED spell_id=%s recipe_id=%s cast_id=%s reason=actor_invalid",
                tostring(cleanup.proxy_spell_id),
                tostring(cleanup.recipe_id),
                tostring(cleanup.cast_id)
            ))
        else
            local removed, remove_err = tryRemoveProxyActiveSpell(cleanup.actor, cleanup.proxy_spell_id)
            if removed then
                log.debug(string.format(
                    "SPELLFORGE_PROXY_ACTIVE_CLEANUP_REMOVED spell_id=%s recipe_id=%s cast_id=%s mode=deferred attempts=%s elapsed=%.3f",
                    tostring(cleanup.proxy_spell_id),
                    tostring(cleanup.recipe_id),
                    tostring(cleanup.cast_id),
                    tostring((cleanup.attempts or 1) + 1),
                    tonumber(cleanup.elapsed) or 0
                ))
            else
                cleanup.elapsed = (tonumber(cleanup.elapsed) or 0) + dt_seconds
                cleanup.attempts = (tonumber(cleanup.attempts) or 1) + 1
                if cleanup.elapsed < PROXY_ACTIVE_CLEANUP_MAX_SECONDS
                    and cleanup.attempts < PROXY_ACTIVE_CLEANUP_MAX_ATTEMPTS then
                    next_queue[#next_queue + 1] = cleanup
                elseif remove_err ~= nil then
                    log.debug(string.format(
                        "SPELLFORGE_PROXY_ACTIVE_CLEANUP_EXPIRED spell_id=%s recipe_id=%s cast_id=%s reason=%s attempts=%s elapsed=%.3f",
                        tostring(cleanup.proxy_spell_id),
                        tostring(cleanup.recipe_id),
                        tostring(cleanup.cast_id),
                        tostring(remove_err),
                        tostring(cleanup.attempts),
                        tonumber(cleanup.elapsed) or 0
                    ))
                end
            end
        end
    end
    proxy_active_cleanup_queue = next_queue
end

local function objectKind(value)
    if value == nil then
        return nil
    end
    return readField(value, "type")
        or readField(value, "objectType")
        or readField(value, "recordType")
        or type(value)
end

local function compactNumber(value)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    return string.format("%.1f", number)
end

local function compactVector(value)
    if value == nil then
        return nil
    end
    local x = compactNumber(readField(value, "x"))
    local y = compactNumber(readField(value, "y"))
    local z = compactNumber(readField(value, "z"))
    if x and y and z then
        return string.format("%s,%s,%s", x, y, z)
    end
    return tostring(value)
end

local function compactBounceUserData(user_data)
    if type(user_data) ~= "table" then
        return nil
    end
    return string.format(
        "recipe_id=%s slot_id=%s cast_id=%s bounce_id=%s bounce_role=%s",
        tostring(user_data.recipe_id),
        tostring(user_data.slot_id),
        tostring(user_data.cast_id),
        tostring(user_data.bounce_id),
        tostring(user_data.bounce_role)
    )
end

local function logBounceMagicHitWithoutBounce(payload, helper_hit, helper_mapping, user_data)
    if type(user_data) ~= "table"
        or user_data.bounce_runtime ~= true
        or user_data.bounce_role ~= "source"
        or user_data.bounce_manual_detonation == true then
        return
    end

    local projectile_id = helper_hit and helper_hit.projectile_id or nil
    if projectile_id == nil then
        local _, extracted_projectile_id = sfp_adapter.extractProjectileFromHit(payload)
        projectile_id = extracted_projectile_id
    end
    if live_bounce.bounceEventCount(projectile_id) > 0 then
        return
    end

    runtime_stats.inc("live_bounce_magic_hit_without_bounce")
    local target = payload and (payload.target or payload.hitObject or payload.hit_object) or nil
    log.info(string.format(
        "SPELLFORGE_BOUNCE_SOURCE_MAGIC_HIT_WITHOUT_BOUNCE spell_id=%s helper_engine_id=%s projectile_id=%s target_id=%s target_type=%s hit_pos=%s userData=%s",
        tostring(payload and (payload.spellId or payload.spell_id) or nil),
        tostring((helper_mapping and helper_mapping.engine_id) or user_data.helper_engine_id),
        tostring(projectile_id),
        tostring(objectToken(target)),
        tostring(objectKind(target)),
        tostring(compactVector(payload and (payload.hitPos or payload.hit_pos) or nil)),
        tostring(compactBounceUserData(user_data))
    ))
end

local function logSpellRecord(label, spell_id)
    local record = spell_id and core.magic.spells.records[spell_id] or nil
    if not record then
        log.debug(string.format("%s spell_id=%s record=nil", label, tostring(spell_id)))
        return
    end

    log.debug(string.format(
        "%s spell_id=%s name=%s type=%s cost=%s isAutocalc=%s record=%s",
        label,
        tostring(spell_id),
        tostring(record.name),
        tostring(record.type),
        tostring(record.cost),
        tostring(record.isAutocalc),
        tostring(record)
    ))

    local effects = record.effects
    if type(effects) ~= "table" then
        log.debug(string.format("%s spell_id=%s effects=nil", label, tostring(spell_id)))
        return
    end
    for i, effect in ipairs(effects) do
        log.debug(string.format(
            "%s effect[%d] id=%s range=%s area=%s duration=%s magnitudeMin=%s magnitudeMax=%s",
            label,
            i,
            tostring(effect.id),
            tostring(effect.range),
            tostring(effect.area),
            tostring(effect.duration),
            tostring(effect.magnitudeMin),
            tostring(effect.magnitudeMax)
        ))
    end
end

local function sendResult(sender, request_id, ok, err)
    if sender and type(sender.sendEvent) == "function" then
        sender:sendEvent(events.CAST_OBSERVE_RESULT, {
            request_id = request_id,
            ok = ok,
            error = err,
        })
    end
end

local function findSpellforgeEntry(engine_id)
    local recipe_id, entry = records.findByEngineSpellId(engine_id)
    if recipe_id then
        return recipe_id, entry
    end
    return nil, nil
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

local function draftEffectFor(effect)
    local records_table, effects_api = magicEffectRecordsTable()
    local resolved = effect_identity.resolveEngineEffectId(effect, records_table, effects_api)
    if not resolved.ok then
        return nil, resolved.message or "missing magic effect record"
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
        nil
end

local function createDispatchSpellForEffect(recipe_id, effect_index, effect)
    local cache_key = string.format("%s:%d", tostring(recipe_id), effect_index)
    if dispatch_spell_cache[cache_key] then
        return dispatch_spell_cache[cache_key], nil
    end

    local draft_effect, draft_effect_err = draftEffectFor(effect)
    if not draft_effect then
        log.error(string.format(
            "executor dispatch effect id invalid recipe_id=%s effect_index=%s effect_id=%s engine_effect_id=%s err=%s",
            tostring(recipe_id),
            tostring(effect_index),
            tostring(effect and effect.id),
            tostring(effect and effect.engine_effect_id),
            tostring(draft_effect_err)
        ))
        return nil, tostring(draft_effect_err)
    end

    local draft_ok, draft = pcall(core.magic.spells.createRecordDraft, {
        id = string.format("spellforge_%s_dispatch_%d", tostring(recipe_id), effect_index),
        name = string.format("Spellforge Dispatch %s %d", tostring(recipe_id), effect_index),
        type = core.magic.SPELL_TYPE.Spell,
        cost = 0,
        isAutocalc = false,
        autocalcFlag = false,
        alwaysSucceedFlag = false,
        starterSpellFlag = false,
        effects = { draft_effect },
    })
    if not draft_ok then
        log.error(string.format("executor create dispatch draft failed recipe_id=%s effect_index=%s err=%s", tostring(recipe_id), tostring(effect_index), tostring(draft)))
        return nil, tostring(draft)
    end

    local created, create_err = records.createRecord(draft)
    if create_err then
        log.error(string.format("executor create dispatch spell failed recipe_id=%s effect_index=%s err=%s", tostring(recipe_id), tostring(effect_index), tostring(create_err)))
        return nil, tostring(create_err)
    end

    local dispatch_spell_id = created and created.id
    if type(dispatch_spell_id) ~= "string" or dispatch_spell_id == "" then
        return nil, "dispatch spell create returned invalid id"
    end

    dispatch_spell_cache[cache_key] = dispatch_spell_id
    return dispatch_spell_id, nil
end

local function launchSpell(actor, dispatch_spell_id, start_pos, direction, hit_object, opts)
    local options = opts or {}
    runtime_stats.inc("sfp_launch_attempts")
    local capabilities = sfp_adapter.capabilities()
    if not capabilities.has_interface then
        runtime_stats.inc("sfp_launch_missing_interface")
        runtime_stats.inc("sfp_launch_failed")
        return false, "I.MagExp missing"
    end
    if not capabilities.has_launchSpell then
        runtime_stats.inc("sfp_launch_missing_interface")
        runtime_stats.inc("sfp_launch_failed")
        return false, "I.MagExp.launchSpell missing"
    end

    log.debug(string.format(
        "executor launchSpell params attacker=%s spellId=%s startPos=%s direction=%s isFree=true hitObject=%s",
        tostring(actor and actor.recordId),
        tostring(dispatch_spell_id),
        tostring(start_pos),
        tostring(direction),
        tostring(hit_object and hit_object.recordId or hit_object)
    ))

    local launch_data = {
        attacker = actor,
        spellId = dispatch_spell_id,
        startPos = start_pos,
        direction = direction,
        hitObject = hit_object,
        isFree = true,
    }
    if type(options.userData) == "table" then
        launch_data.userData = options.userData
    end
    if options.muteAudio ~= nil then
        launch_data.muteAudio = options.muteAudio
    end
    if options.muteLight ~= nil then
        launch_data.muteLight = options.muteLight
    end
    projectile_speed_policy.applyBaselineLaunchSpeed(launch_data, {
        launch = {
            actor = actor,
            recipe_id = options.recipe_id,
            slot_id = options.slot_id,
            helper_engine_id = dispatch_spell_id,
        },
        mapping = {
            recipe_id = options.recipe_id,
            slot_id = options.slot_id,
            engine_id = dispatch_spell_id,
            logical_id = dispatch_spell_id,
            effects = options.effects,
        },
    })

    local result = sfp_adapter.launchSpell(launch_data)
    if not result.ok then
        runtime_stats.inc("sfp_launch_failed")
        log.error(string.format("executor launchSpell failed spell_id=%s err=%s", tostring(dispatch_spell_id), tostring(result.error)))
        return false, tostring(result.error)
    end
    runtime_stats.inc("sfp_launch_ok")
    if result.projectile_id ~= nil then
        runtime_stats.inc("sfp_projectile_id_returned")
    else
        runtime_stats.inc("sfp_projectile_id_missing")
    end

    log.debug(string.format(
        "executor launchSpell dispatched spell_id=%s actor=%s projectile_id=%s",
        tostring(dispatch_spell_id),
        tostring(actor and actor.recordId),
        tostring(result.projectile_id)
    ))
    return true, nil
end

function executor.onCastRequest(payload)
    refreshPlayerRefFromPayload(payload, "onCastRequest")
    local sender = payload and payload.sender
    local actor = payload and payload.actor or sender
    local request_id = payload and payload.request_id
    local engine_id = payload and payload.spell_id
    if not sender then
        return
    end
    if not actor then
        sendResult(sender, request_id, false, "missing actor")
        return
    end

    local recipe_id, entry = findSpellforgeEntry(engine_id)
    if not entry then
        sendResult(sender, request_id, false, "spell is not in Spellforge compiled index")
        return
    end

    log.debug(string.format(
        "cast request matched recipe_id=%s logical_id=%s engine_id=%s",
        tostring(recipe_id),
        tostring(entry.frontend_logical_id),
        tostring(engine_id)
    ))

    local ok, err = launchSpell(actor, engine_id, actor.position + util.vector3(0, 0, 120), actor.rotation * util.vector3(0, 1, 0), nil)
    sendResult(sender, request_id, ok, err)
end

function executor.onInterceptCast(payload)
    refreshPlayerRefFromPayload(payload, "onInterceptCast")
    local sender = payload and payload.sender
    local engine_id = payload and payload.spell_id
    local cast_attempt_id = payload and payload.cast_attempt_id
    if not sender then
        return
    end
    castTrace("global_intercept_received", {
        attempt_id = cast_attempt_id,
        spell_id = engine_id,
        variant = payload and payload.intercept_variant or nil,
        reason = payload and payload.dispatch_reason or nil,
        ray_hit = payload and payload.ray_hit or nil,
        ray_distance = payload and payload.ray_distance or nil,
        hitObject_present = payload and payload.hit_object ~= nil or nil,
    })

    local recipe_id, entry, root = records.findRootNodeByEngineSpellId(engine_id)
    if not recipe_id or not root then
        castTrace("global_metadata_missing", {
            attempt_id = cast_attempt_id,
            spell_id = engine_id,
            error = "metadata not found",
        }, "error")
        log.error(string.format("intercept cast missing metadata for spell_id=%s attempt_id=%s", tostring(engine_id), tostring(cast_attempt_id)))
        sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
            ok = false,
            dispatch_kind = DISPATCH_KIND_COMPILED,
            spell_id = engine_id,
            cast_attempt_id = cast_attempt_id,
            error = "metadata not found",
        })
        return
    end

    local dispatched = 0
    local requires_live_runtime = rootRequiresLiveRuntime(root)
    local live_runtime_fallback_reason = nil
    -- Transitional 2.2b scaffolding:
    -- root-only real_effects dispatch proves intercept->launch path, not final 2.2c runtime.
    -- TODO(2.2c): move to compiled effect-list plan execution with bounded job orchestration.
    log.debug(string.format(
        "intercept metadata root recipe_id=%s spell_id=%s real_effect_count=%s real_effects=%s",
        tostring(recipe_id),
        tostring(engine_id),
        tostring(root.real_effects and #root.real_effects or 0),
        stringifyValue(root.real_effects, 3)
    ))
    queueProxyActiveCleanup(sender, engine_id, recipe_id, nil)

    if dev.liveSimpleDispatchEnabled() then
        local live_ok, live_result_or_err = pcall(live_simple_dispatch.tryDispatch, payload, entry, root, {
            source_recipe_id = recipe_id,
        })
        local live_result = live_ok and live_result_or_err or {
            ok = false,
            used_live_2_2c = true,
            fallback_allowed = false,
            error = tostring(live_result_or_err),
        }
        if not live_ok then
            runtime_stats.inc("live_2_2c_dispatch_failed")
        end
        if live_result.ok and live_result.used_live_2_2c then
            local helper_engine_ids = live_result.helper_engine_ids or { live_result.helper_engine_id }
            local slot_ids = live_result.slot_ids or { live_result.slot_id }
            for index, helper_engine_id in ipairs(helper_engine_ids) do
                if type(helper_engine_id) == "string" and helper_engine_id ~= "" then
                    launch_cookies[helper_engine_id] = {
                        recipe_id = recipe_id,
                        plan_recipe_id = live_result.plan_recipe_id,
                        slot_id = slot_ids[index] or live_result.slot_id,
                        source_actor = sender,
                        live_2_2c = true,
                        cast_id = live_result.cast_id,
                        cast_attempt_id = cast_attempt_id,
                    }
                end
            end
            runtime_stats.inc("compiled_dispatch_ok")
            castTrace("global_live_dispatch_ok", {
                attempt_id = cast_attempt_id,
                spell_id = engine_id,
                recipe_id = recipe_id,
                dispatch_count = live_result.dispatch_count or 1,
                cast_id = live_result.cast_id,
                live_2_2c = true,
                projectile_id = live_result.projectile_id,
                projectile_count = type(live_result.projectile_ids) == "table" and #live_result.projectile_ids or nil,
                job_id = live_result.job_id,
            })
            sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
                ok = true,
                dispatch_kind = DISPATCH_KIND_COMPILED_2_2C_HELPER,
                runtime = "2.2c_live_helper",
                spell_id = engine_id,
                cast_attempt_id = cast_attempt_id,
                recipe_id = recipe_id,
                live_2_2c = true,
                live_2_2c_plan_recipe_id = live_result.plan_recipe_id,
                slot_id = live_result.slot_id,
                slot_ids = live_result.slot_ids,
                helper_engine_id = live_result.helper_engine_id,
                helper_engine_ids = live_result.helper_engine_ids,
                projectile_id = live_result.projectile_id,
                projectile_ids = live_result.projectile_ids,
                projectile_registered = live_result.projectile_registered == true,
                job_id = live_result.job_id,
                job_ids = live_result.job_ids,
                cast_id = live_result.cast_id,
                fanout_count = live_result.fanout_count,
                live_mode = live_result.live_mode,
                pattern_kind = live_result.pattern_kind,
                pattern_count = live_result.pattern_count,
                pattern_direction_keys = live_result.pattern_direction_keys,
                trigger_payload_slot_id = live_result.trigger_payload_slot_id,
                trigger_payload_helper_engine_id = live_result.trigger_payload_helper_engine_id,
                timer_payload_slot_id = live_result.timer_payload_slot_id,
                timer_payload_helper_engine_id = live_result.timer_payload_helper_engine_id,
                timer_delay_ticks = live_result.timer_delay_ticks,
                timer_job_id = live_result.timer_job_id,
                dispatch_count = live_result.dispatch_count or 1,
                fallback = false,
            })
            return
        end
        if live_result.used_live_2_2c then
            if live_result.fallback_allowed == false then
                runtime_stats.inc("fallback_after_enqueue_blocked")
                runtime_stats.inc("duplicate_cast_or_dispatch_suppressed")
                log.error(string.format(
                    "SPELLFORGE_LIVE_2_2C_SIMPLE_DISPATCH_ERR spell_id=%s attempt_id=%s recipe_id=%s err=%s; fallback blocked after live attempt",
                    tostring(engine_id),
                    tostring(cast_attempt_id),
                    tostring(recipe_id),
                    tostring(live_result.error or live_result.fallback_reason or "unknown")
                ))
                castTrace("global_live_dispatch_failed", {
                    attempt_id = cast_attempt_id,
                    spell_id = engine_id,
                    recipe_id = recipe_id,
                    cast_id = live_result.cast_id,
                    live_2_2c = true,
                    job_id = live_result.job_id,
                    error = live_result.error or live_result.fallback_reason or "live 2.2c helper dispatch failed",
                }, "error")
                sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
                    ok = false,
                    dispatch_kind = DISPATCH_KIND_COMPILED_2_2C_HELPER,
                    runtime = "2.2c_live_helper",
                    spell_id = engine_id,
                    cast_attempt_id = cast_attempt_id,
                    recipe_id = recipe_id,
                    error = live_result.error or live_result.fallback_reason or "live 2.2c helper dispatch failed",
                    live_2_2c = true,
                    live_2_2c_plan_recipe_id = live_result.plan_recipe_id,
                    slot_id = live_result.slot_id,
                    helper_engine_id = live_result.helper_engine_id,
                    job_id = live_result.job_id,
                    cast_id = live_result.cast_id,
                    fallback = false,
                })
                return
            end
            log.warn(string.format(
                "SPELLFORGE_LIVE_2_2C_SIMPLE_DISPATCH_ERR spell_id=%s attempt_id=%s recipe_id=%s err=%s; falling back to 2.2b",
                tostring(engine_id),
                tostring(cast_attempt_id),
                tostring(recipe_id),
                tostring(live_result.error or live_result.fallback_reason or "unknown")
            ))
            castTrace("global_live_dispatch_fallback", {
                attempt_id = cast_attempt_id,
                spell_id = engine_id,
                recipe_id = recipe_id,
                cast_id = live_result.cast_id,
                live_2_2c = true,
                job_id = live_result.job_id,
                error = live_result.error or live_result.fallback_reason or "live_runtime_failed",
            }, "warn")
            live_runtime_fallback_reason = live_result.error or live_result.fallback_reason or "live_runtime_failed"
        else
            log.debug(string.format(
                "SPELLFORGE_LIVE_2_2C_SIMPLE_DISPATCH_FALLBACK spell_id=%s recipe_id=%s reason=%s",
                tostring(engine_id),
                tostring(recipe_id),
                tostring(live_result.fallback_reason or "not_qualified")
            ))
            live_runtime_fallback_reason = live_result.fallback_reason or "not_qualified"
        end
    else
        live_runtime_fallback_reason = "feature_flag_disabled"
    end

    if requires_live_runtime then
        runtime_stats.inc("legacy_fallback_blocked_runtime_recipe")
        runtime_stats.inc("duplicate_cast_or_dispatch_suppressed")
        local reason = live_runtime_fallback_reason or "live_runtime_not_qualified"
        log.warn(string.format(
            "SPELLFORGE_COMPILED_RUNTIME_FALLBACK_BLOCKED spell_id=%s attempt_id=%s recipe_id=%s reason=%s",
            tostring(engine_id),
            tostring(cast_attempt_id),
            tostring(recipe_id),
            tostring(reason)
        ))
        castTrace("global_runtime_fallback_blocked", {
            attempt_id = cast_attempt_id,
            spell_id = engine_id,
            recipe_id = recipe_id,
            reason = reason,
            error = "live runtime required",
        }, "warn")
        sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
            ok = false,
            dispatch_kind = DISPATCH_KIND_COMPILED_2_2C_HELPER,
            runtime = "2.2c_live_helper",
            spell_id = engine_id,
            cast_attempt_id = cast_attempt_id,
            recipe_id = recipe_id,
            error = "live runtime required for Spellforge operator recipe: " .. tostring(reason),
            live_2_2c = false,
            fallback = false,
        })
        return
    end

    if #(root.real_effects or {}) > 0 then
        runtime_stats.inc("legacy_fallback_used")
    end
    for effect_index, effect in ipairs(root.real_effects or {}) do
        log.debug(string.format(
            "intercept real_effect[%d] id=%s range=%s area=%s duration=%s magnitudeMin=%s magnitudeMax=%s",
            effect_index,
            tostring(effect.id),
            tostring(effect.range),
            tostring(effect.area),
            tostring(effect.duration),
            tostring(effect.magnitudeMin),
            tostring(effect.magnitudeMax)
        ))
        local dispatch_spell_id, dispatch_err = createDispatchSpellForEffect(recipe_id, effect_index, effect)
        if not dispatch_spell_id then
            castTrace("global_legacy_dispatch_spell_failed", {
                attempt_id = cast_attempt_id,
                spell_id = engine_id,
                recipe_id = recipe_id,
                error = dispatch_err,
            }, "error")
            sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
                ok = false,
                dispatch_kind = DISPATCH_KIND_COMPILED,
                spell_id = engine_id,
                cast_attempt_id = cast_attempt_id,
                error = dispatch_err,
            })
            return
        end

        logSpellRecord("dispatch spell record", dispatch_spell_id)
        if not fireball_logged then
            fireball_logged = true
            logSpellRecord("vanilla fireball record", "fireball")
        end

        local ok, launch_err = launchSpell(sender, dispatch_spell_id, payload.start_pos, payload.direction, payload.hit_object, {
            recipe_id = recipe_id,
            slot_id = string.format("legacy:%s", tostring(effect_index)),
            effects = { effect },
            userData = sfp_userdata.buildLegacyDispatchUserData({
                recipe_id = recipe_id,
                cast_attempt_id = cast_attempt_id,
                source_spell_id = engine_id,
                dispatch_spell_id = dispatch_spell_id,
                effect_index = effect_index,
            }),
        })
        if not ok then
            castTrace("global_legacy_launch_failed", {
                attempt_id = cast_attempt_id,
                spell_id = engine_id,
                recipe_id = recipe_id,
                dispatch_count = dispatched,
                error = launch_err,
            }, "error")
            sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
                ok = false,
                dispatch_kind = DISPATCH_KIND_COMPILED,
                spell_id = engine_id,
                cast_attempt_id = cast_attempt_id,
                error = launch_err,
            })
            return
        end

        launch_cookies[dispatch_spell_id] = {
            recipe_id = recipe_id,
            node_path = { 1 },
            source_actor = sender,
            cast_attempt_id = cast_attempt_id,
        }
        dispatched = dispatched + 1
    end

    castTrace("global_legacy_dispatch_result", {
        attempt_id = cast_attempt_id,
        spell_id = engine_id,
        recipe_id = recipe_id,
        dispatch_count = dispatched,
        live_2_2c = false,
    }, dispatched > 0 and nil or "warn")
    sender:sendEvent(events.INTERCEPT_DISPATCH_RESULT, {
        ok = dispatched > 0,
        dispatch_kind = DISPATCH_KIND_COMPILED,
        spell_id = engine_id,
        cast_attempt_id = cast_attempt_id,
        recipe_id = recipe_id,
        dispatch_count = dispatched,
    })
    if dispatched > 0 then
        runtime_stats.inc("compiled_dispatch_ok")
    end
end

function executor.onBeginObserve(payload)
    local sender = payload and payload.sender
    local request_id = payload and payload.request_id
    local engine_id = payload and payload.spell_id
    local timeout_seconds = payload and payload.timeout_seconds or 30
    if not sender then
        return
    end
    local actor_id = sender.recordId or tostring(sender)
    watchers[actor_id] = {
        sender = sender,
        request_id = request_id,
        spell_id = engine_id,
    }
    async:newUnsavableSimulationTimer(timeout_seconds, function()
        if watchers[actor_id] and watchers[actor_id].request_id == request_id then
            watchers[actor_id] = nil
            sendResult(sender, request_id, false, "observe timeout")
        end
    end)
    sendResult(sender, request_id, true, nil)
    log.debug(string.format("registered cast observe actor=%s spell_id=%s timeout=%s", tostring(actor_id), tostring(engine_id), tostring(timeout_seconds)))
end

function executor.onMagicHit(payload)
    -- 2.2c helper hits use shared routing only when a dev/live 2.2c gate is enabled;
    -- live 2.2b dispatch cookies stay unchanged.
    runtime_stats.inc("hits_seen")

    local attacker_id = payload and payload.attacker and payload.attacker.recordId or nil
    local victim_id = payload and payload.target and payload.target.recordId or nil
    local spell_id = payload and (payload.spellId or payload.spell_id) or nil
    local hit_pos = payload and payload.hitPos or nil
    local hit_user_data = sfp_userdata.extract(payload)
    local spellforge_hit_user_data = sfp_userdata.isSpellforgeUserData(hit_user_data) and hit_user_data or nil
    log.debug(string.format(
        "MagExp_OnMagicHit spell_id=%s attacker=%s victim=%s has_user_data=%s recipe_id=%s slot_id=%s",
        tostring(spell_id),
        tostring(attacker_id),
        tostring(victim_id),
        tostring(spellforge_hit_user_data ~= nil),
        tostring(spellforge_hit_user_data and spellforge_hit_user_data.recipe_id or nil),
        tostring(spellforge_hit_user_data and spellforge_hit_user_data.slot_id or nil)
    ))
    if spellforge_hit_user_data and spellforge_hit_user_data.runtime == "2.2b_live_dispatch" then
        runtime_stats.inc("hits_legacy_seen")
    end

    local helper_hit = nil
    if dev.liveSimpleDispatchEnabled() then
        helper_hit = runtime_hits.resolveHelperHit(payload)
    end
    local helper_mapping = helper_hit and helper_hit.ok and helper_hit.mapping or nil
    local skip_live_continuations = spellforge_hit_user_data
        and spellforge_hit_user_data.bounce_manual_detonation == true
    if not skip_live_continuations then
        logBounceMagicHitWithoutBounce(payload, helper_hit, helper_mapping, spellforge_hit_user_data)
    end

    local chain_result = nil
    local trigger_result = nil
    local timer_result = nil
    if helper_mapping and dev.liveSimpleDispatchEnabled() and not skip_live_continuations then
        live_soft_homing.onResolvedHit(helper_hit)
        chain_result = live_chain.handleResolvedHit(helper_hit)
        trigger_result = live_trigger.handleResolvedHit(helper_hit)
        timer_result = live_timer.handleResolvedHit(helper_hit)
    end

    local cookie = spell_id and launch_cookies[spell_id] or nil
    if not cookie and helper_mapping then
        cookie = launch_cookies[helper_mapping.engine_id]
    end
    if cookie then
        log.debug(string.format(
            "Spellforge hit matched recipe_id=%s spell_id=%s attacker=%s victim=%s hit_pos=%s",
            tostring(cookie.recipe_id),
            tostring(spell_id),
            tostring(attacker_id),
            tostring(victim_id),
            tostring(hit_pos)
        ))
    end

    local recipe_id = nil
    if cookie then
        recipe_id = cookie.recipe_id
    elseif helper_mapping then
        recipe_id = helper_mapping.recipe_id
    elseif spellforge_hit_user_data and spellforge_hit_user_data.recipe_id then
        recipe_id = spellforge_hit_user_data.recipe_id
    elseif type(spell_id) == "string" then
        recipe_id = select(1, findSpellforgeEntry(spell_id))
    end
    local hit_cast_attempt_id = spellforge_hit_user_data and spellforge_hit_user_data.cast_attempt_id
        or cookie and cookie.cast_attempt_id
        or nil
    if spellforge_hit_user_data or cookie or helper_mapping then
        castTrace("global_magic_hit", {
            attempt_id = hit_cast_attempt_id,
            spell_id = spell_id,
            recipe_id = recipe_id,
            cast_id = spellforge_hit_user_data and spellforge_hit_user_data.cast_id or cookie and cookie.cast_id or nil,
            projectile_id = helper_hit and helper_hit.projectile_id or nil,
            hitObject_present = payload and payload.target ~= nil or nil,
        })
    end

    for actor_id, watcher in pairs(watchers) do
        if watcher.sender and type(watcher.sender.sendEvent) == "function" then
            local match = recipe_id ~= nil and (watcher.spell_id == spell_id or recipe_id == select(1, findSpellforgeEntry(watcher.spell_id)))
            if match then
                watcher.sender:sendEvent(events.CAST_HIT_OBSERVED, {
                    request_id = watcher.request_id,
                    spell_id = spell_id,
                    matched = true,
                    attacker_id = attacker_id,
                    victim_id = victim_id,
                    recipe_id = recipe_id,
                    cast_attempt_id = hit_cast_attempt_id,
                    live_2_2c = cookie and cookie.live_2_2c == true or false,
                    live_2_2c_plan_recipe_id = cookie and cookie.plan_recipe_id or nil,
                    cast_id = cookie and cookie.cast_id or nil,
                    pattern_kind = spellforge_hit_user_data and spellforge_hit_user_data.pattern_kind or nil,
                    pattern_index = spellforge_hit_user_data and spellforge_hit_user_data.pattern_index or nil,
                    pattern_count = spellforge_hit_user_data and spellforge_hit_user_data.pattern_count or nil,
                    trigger_payload_job_id = trigger_result and trigger_result.job_id or nil,
                    trigger_payload_slot_id = trigger_result and trigger_result.payload_slot_id or nil,
                    trigger_payload_helper_engine_id = trigger_result and trigger_result.payload_helper_engine_id or nil,
                    trigger_payload_launched = trigger_result and trigger_result.ok == true or false,
                    timer_payload_job_id = timer_result and timer_result.job_id or nil,
                    timer_payload_slot_id = timer_result and timer_result.payload_slot_id or nil,
                    timer_payload_helper_engine_id = timer_result and timer_result.payload_helper_engine_id or nil,
                    timer_payload_launched = timer_result and timer_result.ok == true or false,
                    chain_payload_job_id = chain_result and chain_result.job_id or nil,
                    chain_payload_slot_id = chain_result and chain_result.payload_slot_id or nil,
                    chain_payload_helper_engine_id = chain_result and chain_result.payload_helper_engine_id or nil,
                    chain_payload_launched = chain_result and chain_result.ok == true and chain_result.launch_count == 1 or false,
                    chain_id = chain_result and chain_result.chain_id or (spellforge_hit_user_data and spellforge_hit_user_data.chain_id or nil),
                    chain_hop_index = chain_result and chain_result.chain_hop_index or (spellforge_hit_user_data and spellforge_hit_user_data.chain_hop_index or nil),
                    slot_id = helper_mapping and helper_mapping.slot_id or (cookie and cookie.slot_id or nil),
                    helper_engine_id = helper_mapping and helper_mapping.engine_id or nil,
                    projectile_id = helper_hit and helper_hit.projectile_id or nil,
                })
                watchers[actor_id] = nil
            end
        end
    end
end

function executor.onProjectileBounce(payload)
    if not dev.liveSimpleDispatchEnabled() then
        return
    end
    live_bounce.handleBouncePayload(payload)
end

function executor.onProjectilePierce(payload)
    if not dev.liveSimpleDispatchEnabled() then
        return
    end
    live_pierce.handlePiercePayload(payload)
end

local function buildActiveSpellIdSet(actor)
    local ids = {}
    for _, active_spell in pairs(types.Actor.activeSpells(actor)) do
        if active_spell and type(active_spell.id) == "string" then
            ids[active_spell.id] = true
        end
    end
    return ids
end

local function ensureTargetFilter()
    if target_filter_registered then
        return
    end
    local capabilities = sfp_adapter.capabilities()
    if not capabilities.has_interface then
        return
    end
    if not capabilities.has_addTargetFilter and not capabilities.has_setTargetFilter then
        return
    end
    local registered = sfp_adapter.registerTargetFilter(function(target)
        local target_id = target and target.recordId or nil
        if target == nil then
            log.debug("target filter target=nil result=true")
            return true
        end
        local health = types.Actor.stats.dynamic.health(target)
        if not health then
            log.debug(string.format("target filter target=%s health=nil result=true", tostring(target_id)))
            return true
        end
        local allow = (health.current or 0) > 0
        log.debug(string.format(
            "target filter target=%s health=%s result=%s",
            tostring(target_id),
            tostring(health.current),
            tostring(allow)
        ))
        return allow
    end)
    target_filter_registered = registered.ok == true
    -- TODO(2.2c): route launch/hit work through a central bounded job queue/orchestrator.
end

function executor.onPlayerAdded(player)
    executor.resetTransientRuntime("onPlayerAdded", {
        clear_player_ref = false,
    })
    player_ref = player
    last_active_spell_ids = {}
    ensureTargetFilter()
    log.debug(string.format("diagnostic onPlayerAdded player=%s", tostring(player and player.recordId)))
end

function executor.onLoad(data, initData)
    local __ = initData
    if type(data) == "table" then
        runtime_session.ensureAtLeast(data.runtime_generation, "onLoad")
    end
    executor.resetTransientRuntime("onLoad", {
        clear_player_ref = true,
    })
end

function executor.onSave(data)
    local _ = data
    local ok, result = pcall(function()
        local counts = transientCounts()
        local generation_before = runtime_session.currentGeneration()
        log.debug(string.format(
            "SPELLFORGE_RUNTIME_SAVE_CLEANUP_BEGIN projectiles=%s homing_entries=%s timers=%s trigger_bindings=%s jobs=%s bounce_entries=%s pierce_entries=%s chain_entries=%s runtime_generation_before=%s",
            tostring(counts.projectiles),
            tostring(counts.homing_entries),
            tostring(counts.timers),
            tostring(counts.trigger_bindings),
            tostring(counts.jobs),
            tostring(counts.bounce_entries),
            tostring(counts.pierce_entries),
            tostring(counts.chain_entries),
            tostring(generation_before)
        ))
        local cancel_counts = cancelActiveProjectilesForSave()
        local reset = executor.resetTransientRuntime("onSave", {
            clear_player_ref = false,
        })
        log.info(string.format(
            "SPELLFORGE_RUNTIME_SAVE_CLEANUP_OK projectiles=%s cancel_attempted=%s cancel_ok=%s cancel_failed=%s runtime_generation=%s",
            tostring(counts.projectiles),
            tostring(cancel_counts.attempted),
            tostring(cancel_counts.ok),
            tostring(cancel_counts.failed),
            tostring(reset.runtime_generation_after)
        ))
        log.debug(string.format(
            "SPELLFORGE_RUNTIME_SAVE_CLEANUP_DETAIL projectiles=%s cancel_attempted=%s cancel_ok=%s cancel_failed=%s homing_entries=%s timers=%s trigger_bindings=%s jobs=%s bounce_entries=%s pierce_entries=%s chain_entries=%s runtime_generation_before=%s runtime_generation_after=%s",
            tostring(counts.projectiles),
            tostring(cancel_counts.attempted),
            tostring(cancel_counts.ok),
            tostring(cancel_counts.failed),
            tostring(counts.homing_entries),
            tostring(counts.timers),
            tostring(counts.trigger_bindings),
            tostring(counts.jobs),
            tostring(counts.bounce_entries),
            tostring(counts.pierce_entries),
            tostring(counts.chain_entries),
            tostring(reset.runtime_generation_before),
            tostring(reset.runtime_generation_after)
        ))
        return {
            runtime_generation = runtime_session.currentGeneration(),
            save_cleanup_projectiles = counts.projectiles,
            save_cleanup_cancel_attempted = cancel_counts.attempted,
            save_cleanup_cancel_ok = cancel_counts.ok,
            save_cleanup_cancel_failed = cancel_counts.failed,
            compiled_records = records.exportState(),
        }
    end)
    if ok then
        return result
    end
    log.error(string.format("SPELLFORGE_RUNTIME_SAVE_CLEANUP_FAILED error=%s", tostring(result)))
    return {
        runtime_generation = runtime_session.currentGeneration(),
        save_cleanup_error = tostring(result),
    }
end

function executor.onUpdate(dt)
    local dt_seconds = tonumber(dt) or 0
    processProxyActiveCleanup(dt_seconds)

    if player_ref and objectValid(player_ref) then
        local ok, current_ids = pcall(buildActiveSpellIdSet, player_ref)
        if ok and type(current_ids) == "table" then
            for id in pairs(current_ids) do
                if not last_active_spell_ids[id] then
                    log.debug(string.format("diagnostic active spell added id=%s", tostring(id)))
                end
            end
            last_active_spell_ids = current_ids
        else
            log.warn(string.format(
                "diagnostic active spell scan failed actor=%s err=%s",
                tostring(objectToken(player_ref)),
                tostring(current_ids)
            ))
            player_ref = nil
            last_active_spell_ids = {}
        end
    else
        if player_ref ~= nil then
            log.debug(string.format("diagnostic player_ref invalidated actor=%s", tostring(objectToken(player_ref))))
        end
        player_ref = nil
        last_active_spell_ids = {}
    end

    if orchestrator.queueLength() > 0 then
        orchestrator.tick({
            max_jobs_per_tick = limits.MAX_JOBS_PER_TICK,
            max_live_launches_per_tick = limits.MAX_LIVE_LAUNCHES_PER_TICK,
            dt_seconds = dt_seconds,
        })
    else
        orchestrator.advanceTime(dt_seconds)
    end
    live_soft_homing.onUpdate(dt_seconds)
end

function executor.onCastDiagSignal(payload)
    log.debug(string.format(
        "diagnostic cast signal group=%s key=%s selected_spell_id=%s sender=%s",
        tostring(payload and payload.groupname),
        tostring(payload and payload.key),
        tostring(payload and payload.selected_spell_id),
        tostring(payload and payload.sender and payload.sender.recordId)
    ))
end

function executor.onInterceptDispatchSuppressed(payload)
    runtime_stats.inc("compiled_dispatch_suppressed")
    castTrace("global_dispatch_suppressed_observed", {
        attempt_id = payload and payload.cast_attempt_id or nil,
        spell_id = payload and payload.spell_id or nil,
        reason = payload and payload.reason or nil,
        error = payload and payload.reason or nil,
    }, payload and payload.authorized == false and "warn" or nil)
    if payload and payload.authorized == false then
        runtime_stats.inc("live_2_2c_suppressed_unauthorized")
    end
end

function executor.onRuntimeStatsRequest(payload)
    local sender = payload and payload.sender
    if not sender or type(sender.sendEvent) ~= "function" then
        return
    end
    if payload and payload.reset_before == true then
        runtime_stats.reset()
        live_timer.clearForTests()
        live_trigger.clearForTests()
        live_chain.clearForTests()
        live_bounce.clearForTests()
        live_pierce.clearForTests()
        live_soft_homing.clearForTests()
    end
    local orchestrator_summary = orchestrator.summary()
    sender:sendEvent(events.RUNTIME_STATS_RESULT, {
        request_id = payload and payload.request_id,
        ok = true,
        snapshot = runtime_stats.snapshot(),
        summary_lines = runtime_stats.summaryLines(),
        orchestrator = orchestrator_summary,
        live_launch_cap_diagnostic = {
            live_launches_this_update = orchestrator_summary.live_launches_this_update,
            max_live_launches_per_tick = orchestrator_summary.max_live_launches_per_tick,
            player_ref_present = objectValid(player_ref),
            update_resets_without_player_ref = true,
        },
    })
end

return executor
