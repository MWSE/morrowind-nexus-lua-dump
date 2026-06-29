---@omw-context global
local core = require("openmw.core")

local compiler = require("scripts.spellforge.global.compiler")
local dev = require("scripts.spellforge.shared.dev")
local executor = require("scripts.spellforge.global.executor")
local events = require("scripts.spellforge.shared.events")
local helper_records = require("scripts.spellforge.global.helper_records")
local live_timer = require("scripts.spellforge.global.live_timer")
local live_chain = require("scripts.spellforge.global.live_chain")
local live_soft_homing = require("scripts.spellforge.global.live_soft_homing")
local records = require("scripts.spellforge.global.records")
local rehydrate = require("scripts.spellforge.global.rehydrate")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local ui_catalog = require("scripts.spellforge.global.ui_catalog")
local ui_contract = require("scripts.spellforge.global.ui_contract")
local log = require("scripts.spellforge.shared.log").new("global.init")
local did_records_probe = false
local did_rehydrate_all = false
local ossc_compat_recent = {}

local OSSC_COMPAT_DEDUPE_TTL = 0.5

live_timer.registerCallbacks()

local function isBackendReady()
    return sfp_adapter.capabilities().has_interface == true
end

local function runSpellsRecordsProbe()
    if did_records_probe then
        return
    end
    did_records_probe = true

    local count = 0
    local first_key, first_value
    for k, v in pairs(core.magic.spells.records) do
        count = count + 1
        if count == 1 then
            first_key, first_value = k, v
        end
        if count >= 3 then
            break
        end
    end
    log.debug(string.format(
        "spells.records probe: count>=%d first_key_type=%s first_key=%s first_value_type=%s first_value_id=%s",
        count,
        type(first_key),
        tostring(first_key),
        type(first_value),
        tostring(first_value and first_value.id)
    ))

    local probe_id = first_value and first_value.id or "fireball"
    log.debug(string.format(
        "spells.records lookup probe: by_string=%s by_int=%s",
        tostring(core.magic.spells.records[probe_id] ~= nil),
        tostring(core.magic.spells.records[1] ~= nil)
    ))
end

local function getSender(payload, event_name)
    if not payload or not payload.sender then
        log.error(string.format("%s missing payload.sender", event_name))
        return nil
    end
    if type(payload.sender.sendEvent) ~= "function" then
        log.error(string.format("%s payload.sender is not event-capable actor", event_name))
        return nil
    end
    return payload.sender
end

local function onCheckBackend(payload)
    runSpellsRecordsProbe()

    local sender = getSender(payload, events.CHECK_BACKEND)
    if not sender then
        return
    end

    if isBackendReady() then
        if not did_rehydrate_all then
            did_rehydrate_all = true
            rehydrate.rehydrateAll()
        end
        sender:sendEvent(events.BACKEND_READY, { backend_version = "sfp-unknown" })
        log.debug("backend handshake ready")
    else
        sender:sendEvent(events.BACKEND_UNAVAILABLE, { reason = "Spell Framework Plus (I.MagExp) missing" })
        log.warn("backend handshake unavailable")
    end
end

local function onLoad(data, initData)
    did_rehydrate_all = false
    local record_state = type(data) == "table" and data.compiled_records or nil
    local record_load = records.importState(record_state, "onLoad")
    if record_load.imported ~= true then
        record_load = records.reloadFromStorage("onLoad")
    end
    log.info(string.format(
        "SPELLFORGE_GLOBAL_REHYDRATE_GATE_RESET_ON_LOAD did_rehydrate_all=%s records_before=%s records_after=%s",
        tostring(did_rehydrate_all),
        tostring(record_load and record_load.records_before),
        tostring(record_load and record_load.records_after)
    ))
    executor.onLoad(data, initData)
end

local function onRehydrateCompiled(payload)
    local sender = getSender(payload, events.REHYDRATE_COMPILED_REQUEST)
    if not sender then
        return
    end

    local result = rehydrate.rehydrateRequest(payload or {})
    sender:sendEvent(events.REHYDRATE_COMPILED_RESULT, result)
end

local function onCompileRecipe(payload)
    local sender = getSender(payload, events.COMPILE_RECIPE)
    if not sender then
        return
    end

    if not isBackendReady() then
        sender:sendEvent(events.COMPILE_RESULT, {
            request_id = payload and payload.request_id,
            ok = false,
            error = "Backend unavailable",
        })
        return
    end

    local result = compiler.handleCompileEvent(payload or {})
    sender:sendEvent(events.COMPILE_RESULT, result)
end

local function onValidateRecipe(payload)
    local sender = getSender(payload, events.VALIDATE_RECIPE)
    if not sender then
        return
    end

    sender:sendEvent(events.VALIDATE_RESULT, ui_contract.validateRecipe(payload or {}))
end

local function onPreviewRecipe(payload)
    local sender = getSender(payload, events.PREVIEW_RECIPE)
    if not sender then
        return
    end

    sender:sendEvent(events.PREVIEW_RESULT, ui_contract.previewRecipe(payload or {}))
end

local function onQueryUiCatalog(payload)
    local sender = getSender(payload, events.QUERY_UI_CATALOG)
    if not sender then
        return
    end

    local result = ui_catalog.build(payload or {})
    local available = result.available_effects or {}
    log.info(string.format(
        "SPELLFORGE_AVAILABLE_EFFECTS_QUERY_OK source=%s count=%s",
        tostring(available.source_mode or result.available_effect_source_mode),
        tostring(available.base_effect_count or result.base_effect_count or 0)
    ))
    if available.source_mode == "player_known" then
        log.info(string.format(
            "SPELLFORGE_AVAILABLE_EFFECTS_KNOWN_SCAN_OK count=%s",
            tostring(available.base_effect_count or 0)
        ))
    elseif available.capability_notes and available.capability_notes.known_effect_scan_unavailable then
        log.warn("SPELLFORGE_AVAILABLE_EFFECTS_FALLBACK_USED reason=known_effect_scan_unavailable")
    elseif available.capability_notes and available.capability_notes.known_effect_scan_empty then
        log.warn("SPELLFORGE_AVAILABLE_EFFECTS_FALLBACK_USED reason=known_effect_scan_empty")
    end
    sender:sendEvent(events.UI_CATALOG_RESULT, result)
end

local function onQueryAvailableEffects(payload)
    local sender = getSender(payload, events.QUERY_AVAILABLE_EFFECTS)
    if not sender then
        return
    end

    local result = ui_catalog.availableEffects(payload or {})
    log.info(string.format(
        "SPELLFORGE_AVAILABLE_EFFECTS_QUERY_OK source=%s count=%s",
        tostring(result.source_mode),
        tostring(result.base_effect_count or 0)
    ))
    if result.source_mode == "player_known" then
        log.info(string.format(
            "SPELLFORGE_AVAILABLE_EFFECTS_KNOWN_SCAN_OK count=%s",
            tostring(result.base_effect_count or 0)
        ))
    elseif result.capability_notes and result.capability_notes.known_effect_scan_unavailable then
        log.warn("SPELLFORGE_AVAILABLE_EFFECTS_FALLBACK_USED reason=known_effect_scan_unavailable")
    elseif result.capability_notes and result.capability_notes.known_effect_scan_empty then
        log.warn("SPELLFORGE_AVAILABLE_EFFECTS_FALLBACK_USED reason=known_effect_scan_empty")
    end
    sender:sendEvent(events.AVAILABLE_EFFECTS_RESULT, result)
end

local function onDeleteCompiled(payload)
    local deleted = false
    local recipe_id = nil
    if payload and payload.recipe_id then
        recipe_id = payload.recipe_id
        deleted = records.deleteByRecipeId(recipe_id)
    elseif payload and payload.spell_id then
        deleted, recipe_id = records.deleteBySpellId(payload.spell_id)
    end

    local helper_records_cleared = recipe_id and helper_records.clearForRecipe(recipe_id) or 0
    log.info(string.format(
        "delete request handled deleted=%s recipe_id=%s helper_records_cleared=%s",
        tostring(deleted),
        tostring(recipe_id),
        tostring(helper_records_cleared)
    ))
end


local function onQuerySpellMetadata(payload)
    local sender = getSender(payload, events.QUERY_SPELL_METADATA)
    if not sender then
        return
    end

    local spell_id = payload and payload.spell_id
    local recipe_id, entry, root = records.findRootNodeByEngineSpellId(spell_id)
    sender:sendEvent(events.QUERY_SPELL_METADATA_RESULT, {
        request_id = payload and payload.request_id,
        spell_id = spell_id,
        is_spellforge = recipe_id ~= nil,
        recipe_id = recipe_id,
        root_base_spell_id = root and root.base_spell_id or nil,
        root_range = root and root.marker_range or nil,
        root_real_effects = root and root.real_effects or nil,
        frontend_spell_id = entry and entry.frontend_spell_id or nil,
    })
end

local function onSfpSpellState(payload)
    local handled = live_timer.onSpellState(payload)
    if handled ~= true then
        live_soft_homing.onSpellState(payload)
    end
end

local function hasValue(value)
    return value ~= nil
end

local function simulationTime()
    local ok, value = pcall(core.getSimulationTime)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

local function fieldValue(object, field)
    if object == nil then
        return nil
    end
    local ok, value = pcall(function()
        return object[field]
    end)
    if ok then
        return value
    end
    return nil
end

local function actorKey(actor)
    local record_id = fieldValue(actor, "recordId")
    if type(record_id) == "string" and record_id ~= "" then
        return record_id
    end
    local id = fieldValue(actor, "id")
    if type(id) == "string" and id ~= "" then
        return id
    end
    return tostring(actor)
end

local function vectorKey(value)
    if value == nil then
        return "nil"
    end
    local x = fieldValue(value, "x")
    local y = fieldValue(value, "y")
    local z = fieldValue(value, "z")
    if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        return string.format("%.2f,%.2f,%.2f", x, y, z)
    end
    return tostring(value)
end

local function hasSendEvent(actor)
    return type(fieldValue(actor, "sendEvent")) == "function"
end

local function pruneOsscCompatRecent(now)
    if type(now) ~= "number" then
        ossc_compat_recent = {}
        return
    end
    for key, timestamp in pairs(ossc_compat_recent) do
        if type(timestamp) ~= "number" or now - timestamp > OSSC_COMPAT_DEDUPE_TTL then
            ossc_compat_recent[key] = nil
        end
    end
end

local function onMagExpCastRequestForOsscCompat(payload)
    local data = payload or {}
    local spell_id = data.spellId or data.spell_id
    log.debug(string.format(
        "SPELLFORGE_OSSC_COMPAT_MAGEXP_REQUEST_OBSERVED spell_id=%s has_startPos=%s has_direction=%s has_hitObject=%s spawnOffset=%s isFree=%s effectScale=%s source=ossc_mag_exp_cast_request",
        tostring(spell_id),
        tostring(hasValue(data.startPos or data.start_pos)),
        tostring(hasValue(data.direction)),
        tostring(hasValue(data.hitObject or data.hit_object)),
        tostring(data.spawnOffset or data.spawn_offset),
        tostring(data.isFree),
        tostring(data.effectScale)
    ))

    if type(spell_id) ~= "string" or spell_id == "" then
        return
    end

    local recipe_id, entry, root = records.findRootNodeByEngineSpellId(spell_id)
    if not recipe_id or not entry then
        log.debug(string.format(
            "SPELLFORGE_OSSC_COMPAT_IGNORED_NON_SPELLFORGE spell_id=%s source=ossc_mag_exp_cast_request",
            tostring(spell_id)
        ))
        return
    end

    if type(entry.frontend_spell_id) ~= "string" or entry.frontend_spell_id == "" or entry.frontend_spell_id ~= spell_id then
        log.debug(string.format(
            "SPELLFORGE_OSSC_COMPAT_IGNORED_NOT_FRONTEND spell_id=%s recipe_id=%s frontend_spell_id=%s source=ossc_mag_exp_cast_request",
            tostring(spell_id),
            tostring(recipe_id),
            tostring(entry.frontend_spell_id)
        ))
        return
    end

    local attacker = data.attacker or data.sender
    if attacker == nil or not hasSendEvent(attacker) then
        log.warn(string.format(
            "SPELLFORGE_OSSC_COMPAT_DISPATCH_REQUEST_FAILED spell_id=%s recipe_id=%s reason=missing_event_capable_attacker source=ossc_mag_exp_cast_request",
            tostring(spell_id),
            tostring(recipe_id)
        ))
        return
    end

    local start_pos = data.startPos or data.start_pos
    local direction = data.direction
    local hit_object = data.hitObject or data.hit_object
    local spawn_offset = data.spawnOffset or data.spawn_offset
    local now = simulationTime()
    pruneOsscCompatRecent(now)
    local duplicate_key = table.concat({
        tostring(spell_id),
        actorKey(attacker),
        vectorKey(start_pos),
        vectorKey(direction),
    }, "|")
    if type(now) == "number"
        and ossc_compat_recent[duplicate_key] ~= nil
        and now - ossc_compat_recent[duplicate_key] <= OSSC_COMPAT_DEDUPE_TTL then
        log.info(string.format(
            "SPELLFORGE_OSSC_COMPAT_DUPLICATE_SUPPRESSED spell_id=%s recipe_id=%s source=ossc_mag_exp_cast_request",
            tostring(spell_id),
            tostring(recipe_id)
        ))
        return
    end
    if type(now) == "number" then
        ossc_compat_recent[duplicate_key] = now
    end

    log.info(string.format(
        "SPELLFORGE_OSSC_COMPAT_DISPATCH_REQUESTED spell_id=%s recipe_id=%s attacker=%s has_startPos=%s has_direction=%s has_hitObject=%s spawnOffset=%s isFree=%s effectScale=%s source=ossc_mag_exp_cast_request",
        tostring(spell_id),
        tostring(recipe_id),
        actorKey(attacker),
        tostring(hasValue(start_pos)),
        tostring(hasValue(direction)),
        tostring(hasValue(hit_object)),
        tostring(spawn_offset),
        tostring(data.isFree),
        tostring(data.effectScale)
    ))

    local ok, err = pcall(executor.onInterceptCast, {
        sender = attacker,
        actor = attacker,
        spell_id = spell_id,
        start_pos = start_pos,
        direction = direction,
        hit_object = hit_object,
        hit_pos = data.hitPos or data.hit_pos,
        spawnOffset = spawn_offset,
        spawn_offset = spawn_offset,
        cast_source = "ossc_compat",
        ossc_compat = true,
        ossc_spell_id = spell_id,
        ossc_isFree = data.isFree,
        ossc_effectScale = data.effectScale,
    })

    if ok then
        log.info(string.format(
            "SPELLFORGE_OSSC_COMPAT_OK spell_id=%s recipe_id=%s source=ossc_mag_exp_cast_request",
            tostring(spell_id),
            tostring(recipe_id)
        ))
    else
        log.warn(string.format(
            "SPELLFORGE_OSSC_COMPAT_DISPATCH_REQUEST_FAILED spell_id=%s recipe_id=%s reason=%s source=ossc_mag_exp_cast_request",
            tostring(spell_id),
            tostring(recipe_id),
            tostring(err)
        ))
    end
end

local function onDiagOsscStyleDirectLaunch(payload)
    if not dev.diagOsscStyleCastRequestEnabled() then
        log.warn("SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH skipped reason=diagnostic_disabled")
        return
    end

    local data = payload or {}
    local launch_data = {
        attacker = data.attacker or data.sender,
        spellId = data.spellId or data.spell_id,
        startPos = data.startPos or data.start_pos,
        direction = data.direction,
        area = data.area,
        isFree = data.isFree ~= false,
        itemObject = data.itemObject or data.item,
        hitObject = data.hitObject or data.hit_object,
        spawnOffset = data.spawnOffset or data.spawn_offset,
    }

    log.info(string.format(
        "SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH mode=direct_launch spell_id=%s is_real_vanilla_spell=%s helper_engine_id=%s startPos=%s direction=%s aimPoint=%s hitObject_present=%s distanceToTarget=%s spawnOffset=%s speed_present=false speed=nil maxSpeed_present=false maxSpeed=nil area=%s camera_mode=%s diagnostic_enabled=true",
        tostring(launch_data.spellId),
        tostring(data.is_real_vanilla_spell == true),
        tostring(data.helper_engine_id),
        tostring(launch_data.startPos),
        tostring(launch_data.direction),
        tostring(data.aimPoint or data.aim_point),
        tostring(launch_data.hitObject ~= nil),
        tostring(data.distanceToTarget or data.distance_to_target),
        tostring(launch_data.spawnOffset),
        tostring(launch_data.area),
        tostring(data.camera_mode)
    ))
    log.info(string.format(
        "SPELLFORGE_DIAG_OSSC_STYLE_RESULT_EXPECTED mode=direct_launch spell_id=%s speed_present=%s maxSpeed_present=%s expected=sfp_auto_speed",
        tostring(launch_data.spellId),
        tostring(hasValue(launch_data.speed)),
        tostring(hasValue(launch_data.maxSpeed))
    ))

    local result = sfp_adapter.launchSpell(launch_data)
    if result.ok then
        log.info(string.format(
            "SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH_RESULT ok=true spell_id=%s projectile_id=%s launch_returns_projectile=%s",
            tostring(launch_data.spellId),
            tostring(result.projectile_id),
            tostring(result.launch_returns_projectile == true)
        ))
    else
        log.warn(string.format(
            "SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH_RESULT ok=false spell_id=%s error=%s",
            tostring(launch_data.spellId),
            tostring(result.error)
        ))
    end
end

return {
    eventHandlers = {
        [events.CHECK_BACKEND] = onCheckBackend,
        [events.COMPILE_RECIPE] = onCompileRecipe,
        [events.VALIDATE_RECIPE] = onValidateRecipe,
        [events.PREVIEW_RECIPE] = onPreviewRecipe,
        [events.QUERY_UI_CATALOG] = onQueryUiCatalog,
        [events.QUERY_AVAILABLE_EFFECTS] = onQueryAvailableEffects,
        [events.DELETE_COMPILED] = onDeleteCompiled,
        [events.REHYDRATE_COMPILED_REQUEST] = onRehydrateCompiled,
        [events.QUERY_SPELL_METADATA] = onQuerySpellMetadata,
        [events.CAST_REQUEST] = executor.onCastRequest,
        [events.INTERCEPT_CAST] = executor.onInterceptCast,
        [events.BEGIN_CAST_OBSERVE] = executor.onBeginObserve,
        [events.CAST_DIAG_SIGNAL] = executor.onCastDiagSignal,
        [events.INTERCEPT_DISPATCH_SUPPRESSED] = executor.onInterceptDispatchSuppressed,
        [events.RUNTIME_STATS_REQUEST] = executor.onRuntimeStatsRequest,
        [events.CHAIN_LOS_RESULT] = live_chain.onLosResult,
        [events.DIAG_OSSC_STYLE_DIRECT_LAUNCH] = onDiagOsscStyleDirectLaunch,
        MagExp_CastRequest = onMagExpCastRequestForOsscCompat,
        MagExp_OnMagicHit = executor.onMagicHit,
        MagExp_OnProjectileBounce = executor.onProjectileBounce,
        MagExp_OnProjectilePierce = executor.onProjectilePierce,
        MagExp_SpellState = onSfpSpellState,
    },
    engineHandlers = {
        -- OpenMW engine handlers docs (global scripts): onPlayerAdded/onUpdate are documented;
        -- there is no documented global onSpellCast handler.
        -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/engine_handlers.html
        onLoad = onLoad,
        onPlayerAdded = executor.onPlayerAdded,
        onSave = executor.onSave,
        onUpdate = executor.onUpdate,
    },
}
