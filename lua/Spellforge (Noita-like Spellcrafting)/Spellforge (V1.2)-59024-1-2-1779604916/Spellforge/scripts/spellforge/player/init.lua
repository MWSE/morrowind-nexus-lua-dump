local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local input = require("openmw.input")
local interfaces = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local util = require("openmw.util")

local dev = require("scripts.spellforge.shared.dev")
local events = require("scripts.spellforge.shared.events")
local log = require("scripts.spellforge.shared.log").new("player.init")
local spellcrafting_ui = require("scripts.spellforge.player.spellcrafting_ui")
local storage = require("scripts.spellforge.player.storage")
local ui = require("scripts.spellforge.player.ui")

local state = {
    backend = "INIT",
    handshake_timer = nil,
    unavailable_logged = false,
    is_casting = false,
    animation_diag_registered = false,
    pending_spell_queries = {},
    spell_metadata_cache = {},
    pending_metadata_by_spell_id = {},
    last_selected_spell_id = nil,
    pending_intercept_spell_id = nil,
    pending_intercept_variant = nil,
    intercept_spell_id = nil,
    intercept_variant = nil,
    pending_cast_authorized = false,
    pending_release_spell_id = nil,
    pending_release_timer = nil,
    skill_handler_registered = false,
    pending_repair_by_spell_id = {},
    generated_spell_aliases = {},
    rehydrate_timer = nil,
}

local refreshSpellMetadata
local refreshSelectedSpellMetadata
local requestGeneratedSpellRepair
local resetTransientRuntime

local function savedStoragePayload(data)
    if type(data) ~= "table" then
        return nil
    end
    return data.spellforge_player_storage or data.storage
end

local function mapCount(index)
    local count = 0
    for _ in pairs(index or {}) do
        count = count + 1
    end
    return count
end

local function safeCancelTimer(timer)
    if timer then
        pcall(function()
            timer:cancel()
        end)
    end
end

local function registerGeneratedSpellAlias(old_spell_id, new_spell_id, saved_recipe_id, reason)
    if type(old_spell_id) ~= "string" or old_spell_id == "" then
        return false
    end
    if type(new_spell_id) ~= "string" or new_spell_id == "" or new_spell_id == old_spell_id then
        return false
    end
    state.generated_spell_aliases[old_spell_id] = {
        spell_id = new_spell_id,
        saved_recipe_id = saved_recipe_id,
        reason = reason,
        updated_at = os.time(),
    }
    log.info(string.format(
        "SPELLFORGE_STALE_SELECTED_SPELL_ALIAS_REGISTERED old_frontend_spell_id=%s new_frontend_spell_id=%s saved_recipe_id=%s reason=%s",
        tostring(old_spell_id),
        tostring(new_spell_id),
        tostring(saved_recipe_id),
        tostring(reason)
    ))
    return true
end

local function resolveGeneratedSpellAlias(spell_id, reason)
    local alias = type(spell_id) == "string" and state.generated_spell_aliases[spell_id] or nil
    if not alias or type(alias.spell_id) ~= "string" or alias.spell_id == "" then
        return spell_id, nil
    end
    if reason ~= "onFrame" then
        log.info(string.format(
            "SPELLFORGE_STALE_SELECTED_SPELL_ALIAS_USED old_frontend_spell_id=%s new_frontend_spell_id=%s saved_recipe_id=%s reason=%s",
            tostring(spell_id),
            tostring(alias.spell_id),
            tostring(alias.saved_recipe_id),
            tostring(reason)
        ))
    end
    return alias.spell_id, alias
end

local function onSave()
    local exported = storage.exportState()
    log.info(string.format(
        "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK phase=onSave saved_recipe_count=%s lifecycle_count=%s next_saved_recipe_id=%s",
        tostring(exported.saved_recipe_count),
        tostring(exported.lifecycle_count),
        tostring(exported.next_saved_recipe_id)
    ))
    return {
        version = 1,
        spellforge_player_storage = exported,
    }
end

local function onLoad(data)
    local imported = storage.importState(savedStoragePayload(data))
    log.info(string.format(
        "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK phase=onLoad imported=%s saved_recipe_count=%s lifecycle_count=%s next_saved_recipe_id=%s reason=%s",
        tostring(imported.imported == true),
        tostring(imported.saved_recipe_count),
        tostring(imported.lifecycle_count),
        tostring(imported.next_saved_recipe_id),
        tostring(imported.reason)
    ))
    resetTransientRuntime("onLoad")
end

local function cancelHandshakeTimer()
    if state.handshake_timer then
        state.handshake_timer:cancel()
        state.handshake_timer = nil
    end
end

resetTransientRuntime = function(reason)
    local reset_reason = reason or "unknown"
    local backend_before = state.backend
    local pending_queries = mapCount(state.pending_spell_queries)
    local metadata_cache = mapCount(state.spell_metadata_cache)
    local pending_metadata = mapCount(state.pending_metadata_by_spell_id)
    local pending_repairs = mapCount(state.pending_repair_by_spell_id)
    local generated_aliases = mapCount(state.generated_spell_aliases)
    local had_handshake_timer = state.handshake_timer ~= nil
    local had_rehydrate_timer = state.rehydrate_timer ~= nil
    local had_release_timer = state.pending_release_timer ~= nil

    safeCancelTimer(state.handshake_timer)
    safeCancelTimer(state.rehydrate_timer)
    safeCancelTimer(state.pending_release_timer)

    state.backend = "INIT"
    state.handshake_timer = nil
    state.unavailable_logged = false
    state.is_casting = false
    state.pending_spell_queries = {}
    state.spell_metadata_cache = {}
    state.pending_metadata_by_spell_id = {}
    state.last_selected_spell_id = nil
    state.pending_intercept_spell_id = nil
    state.pending_intercept_variant = nil
    state.intercept_spell_id = nil
    state.intercept_variant = nil
    state.pending_cast_authorized = false
    state.pending_release_spell_id = nil
    state.pending_release_timer = nil
    state.pending_repair_by_spell_id = {}
    state.generated_spell_aliases = {}
    state.rehydrate_timer = nil

    if type(ui.resetTransientRuntime) == "function" then
        ui.resetTransientRuntime(reset_reason)
    end

    log.info(string.format(
        "SPELLFORGE_PLAYER_RUNTIME_RESET_ON_LOAD reason=%s backend_before=%s backend_after=%s pending_queries=%s metadata_cache=%s pending_metadata=%s pending_repairs=%s generated_aliases=%s handshake_timer=%s rehydrate_timer=%s release_timer=%s skill_handler_registered=%s animation_diag_registered=%s",
        tostring(reset_reason),
        tostring(backend_before),
        tostring(state.backend),
        tostring(pending_queries),
        tostring(metadata_cache),
        tostring(pending_metadata),
        tostring(pending_repairs),
        tostring(generated_aliases),
        tostring(had_handshake_timer),
        tostring(had_rehydrate_timer),
        tostring(had_release_timer),
        tostring(state.skill_handler_registered),
        tostring(state.animation_diag_registered)
    ))
end

local function requestBackend()
    state.backend = "PENDING"
    core.sendGlobalEvent(events.CHECK_BACKEND, {
        sender = self.object,
    })

    cancelHandshakeTimer()
    state.handshake_timer = async:newUnsavableSimulationTimer(3, function()
        if state.backend == "PENDING" then
            state.backend = "UNAVAILABLE"
            if not state.unavailable_logged then
                log.warn("backend handshake timeout after 3 seconds")
                state.unavailable_logged = true
            end
        end
    end)
end

local function runPlayerRehydratePass()
    state.rehydrate_timer = nil
    if state.backend ~= "READY" then
        return
    end
    ui.rehydrateCompiledLifecycles(function(result)
        if result and result.ok == true then
            local spell_id = result.spell_id or result.frontend_spell_id
            if type(spell_id) == "string" and spell_id ~= "" then
                if type(result.old_frontend_spell_id) == "string" then
                    registerGeneratedSpellAlias(result.old_frontend_spell_id, spell_id, result.saved_recipe_id, "rehydrate-result")
                end
                refreshSpellMetadata(spell_id, "rehydrate-result")
            end
        elseif result and result.recompile_requested then
            log.info(string.format(
                "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=%s",
                tostring(result.saved_recipe_id),
                tostring(result.recipe_id),
                tostring(result.old_frontend_spell_id),
                tostring(result.error)
            ))
        elseif result and result.ok == false then
            log.warn(string.format(
                "SPELLFORGE_REHYDRATE_ENTRY saved_recipe_id=%s recipe_id=%s action=failed error=%s",
                tostring(result.saved_recipe_id),
                tostring(result.recipe_id),
                tostring(result.error)
            ))
        end
    end)
    refreshSelectedSpellMetadata("rehydrate-selected")
end

local function onBackendReady(payload)
    cancelHandshakeTimer()
    state.backend = "READY"
    state.unavailable_logged = false
    log.info(string.format("backend ready version=%s", tostring(payload and payload.backend_version)))
    if state.rehydrate_timer then
        state.rehydrate_timer:cancel()
    end
    refreshSelectedSpellMetadata("backend-ready-selected")
    state.rehydrate_timer = async:newUnsavableSimulationTimer(0.5, runPlayerRehydratePass)
end

local function onBackendUnavailable(payload)
    cancelHandshakeTimer()
    state.backend = "UNAVAILABLE"
    if not state.unavailable_logged then
        log.warn(string.format("backend unavailable: %s", tostring(payload and payload.reason)))
        state.unavailable_logged = true
    end
end

local function onCompileResult(payload)
    if payload.ok then
        log.info(string.format("compile success recipe_id=%s engine_spell_id=%s reused=%s", tostring(payload.recipe_id), tostring(payload.spell_id), tostring(payload.reused)))
    else
        log.error(string.format("compile failed request=%s error=%s", tostring(payload.request_id), tostring(payload.error or payload.error_message or "validation failed")))
    end
end

local function resolveSelectedSpell()
    if core.magic and type(core.magic.getSelectedSpell) == "function" then
        local spell = core.magic.getSelectedSpell()
        if spell and spell.id then
            return spell
        end
    end

    if types.Player and type(types.Player.getSelectedSpell) == "function" then
        local spell = types.Player.getSelectedSpell(self)
        if spell and spell.id then
            return spell
        end
    end

    if types.Player and type(types.Player.getSelectedEnchantedItem) == "function" then
        local enchanted = types.Player.getSelectedEnchantedItem(self)
        if enchanted and enchanted.id then
            return enchanted
        end
    end

    local actor_spell = types.Actor.getSelectedSpell(self)
    if actor_spell and actor_spell.id then
        return actor_spell
    end

    return nil
end

local function querySpellMetadata(spell_id, callback)
    -- TODO(2.2c): replace per-cast async metadata query with a player-side metadata cache
    -- populated ahead of cast input to avoid query/animation-start race windows.
    local request_id = string.format("spell-query-%d", os.time() + math.random(1, 100000))
    state.pending_spell_queries[request_id] = callback
    core.sendGlobalEvent(events.QUERY_SPELL_METADATA, {
        sender = self.object,
        request_id = request_id,
        spell_id = spell_id,
    })

    async:newUnsavableSimulationTimer(0.25, function()
        if state.pending_spell_queries[request_id] then
            local cb = state.pending_spell_queries[request_id]
            state.pending_spell_queries[request_id] = nil
            cb({ is_spellforge = false, error = "metadata query timeout" })
        end
    end)
end

local function isSelectedRefreshReason(reason)
    return reason == "selected-changed"
        or reason == "selected-cache-miss"
        or reason == "backend-ready-selected"
        or reason == "rehydrate-selected"
end

refreshSpellMetadata = function(spell_id, reason)
    if type(spell_id) ~= "string" or spell_id == "" then
        return
    end
    if state.backend ~= "READY" then
        return
    end
    if state.pending_metadata_by_spell_id[spell_id] then
        return
    end

    state.pending_metadata_by_spell_id[spell_id] = true
    if isSelectedRefreshReason(reason) then
        log.info(string.format(
            "SPELLFORGE_PLAYER_SELECTED_METADATA_REFRESH_QUEUED spell_id=%s reason=%s backend=%s",
            tostring(spell_id),
            tostring(reason),
            tostring(state.backend)
        ))
    end
    querySpellMetadata(spell_id, function(meta)
        state.pending_metadata_by_spell_id[spell_id] = nil
        if type(meta) ~= "table" then
            state.spell_metadata_cache[spell_id] = {
                is_spellforge = false,
                updated_at = os.time(),
                error = "invalid metadata response",
            }
            if isSelectedRefreshReason(reason) then
                log.warn(string.format(
                    "SPELLFORGE_PLAYER_SELECTED_METADATA_REFRESH_OK spell_id=%s reason=%s is_spellforge=false error=%s",
                    tostring(spell_id),
                    tostring(reason),
                    "invalid metadata response"
                ))
            end
            return
        end

        state.spell_metadata_cache[spell_id] = {
            is_spellforge = meta.is_spellforge == true,
            recipe_id = meta.recipe_id,
            root_base_spell_id = meta.root_base_spell_id,
            root_range = meta.root_range,
            frontend_spell_id = meta.frontend_spell_id,
            updated_at = os.time(),
            reason = reason,
            error = meta.error,
        }
        log.debug(string.format(
            "metadata cache updated spell_id=%s is_spellforge=%s reason=%s",
            tostring(spell_id),
            tostring(meta.is_spellforge == true),
            tostring(reason)
        ))
        if isSelectedRefreshReason(reason) then
            log.info(string.format(
                "SPELLFORGE_PLAYER_SELECTED_METADATA_REFRESH_OK spell_id=%s reason=%s is_spellforge=%s recipe_id=%s error=%s",
                tostring(spell_id),
                tostring(reason),
                tostring(meta.is_spellforge == true),
                tostring(meta.recipe_id),
                tostring(meta.error)
            ))
        end
        if meta.is_spellforge ~= true and requestGeneratedSpellRepair then
            requestGeneratedSpellRepair(spell_id, "metadata-missing")
        end
    end)
end

refreshSelectedSpellMetadata = function(reason)
    if state.backend ~= "READY" then
        return false, "backend_not_ready"
    end
    local selected = resolveSelectedSpell()
    local selected_spell_id = selected and selected.id or nil
    if type(selected_spell_id) ~= "string" or selected_spell_id == "" then
        return false, "selected_spell_missing"
    end
    local runtime_spell_id = resolveGeneratedSpellAlias(selected_spell_id, reason or "selected-cache-miss")
    refreshSpellMetadata(runtime_spell_id, reason or "selected-cache-miss")
    return true, runtime_spell_id
end

requestGeneratedSpellRepair = function(spell_id, reason)
    if type(spell_id) ~= "string" or spell_id == "" then
        return false
    end
    if state.backend ~= "READY" then
        return false
    end
    if state.pending_repair_by_spell_id[spell_id] then
        return true
    end
    local match = ui.findLifecycleByGeneratedSpellId(spell_id)
    if not match then
        return false
    end
    state.pending_repair_by_spell_id[spell_id] = true
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s reason=%s",
        tostring(match.saved_recipe_id),
        tostring(spell_id),
        tostring(reason)
    ))
    local queued = ui.repairGeneratedSpellId(spell_id, function(result)
        state.pending_repair_by_spell_id[spell_id] = nil
        if result and result.ok == true then
            local repaired_spell_id = result.spell_id or result.frontend_spell_id
            if type(repaired_spell_id) == "string" and repaired_spell_id ~= "" then
                registerGeneratedSpellAlias(
                    spell_id,
                    repaired_spell_id,
                    result.saved_recipe_id or match.saved_recipe_id,
                    "generated-id-repair"
                )
                refreshSpellMetadata(repaired_spell_id, "generated-id-repair")
            end
        elseif result then
            log.warn(string.format(
                "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s action=failed error=%s",
                tostring(result.saved_recipe_id),
                tostring(spell_id),
                tostring(result.error)
            ))
        end
    end, {
        preserve_old_frontend_spell_id = true,
        preserve_reason = "selected_spell_alias",
    })
    if not queued or queued.ok == false then
        state.pending_repair_by_spell_id[spell_id] = nil
        return false
    end
    return true
end

local function classifyVariant(root_base_spell_id, root_range)
    local base = root_base_spell_id and core.magic.spells.records[root_base_spell_id] or nil
    local range = (base and base.effects and base.effects[1] and base.effects[1].range) or root_range

    -- OpenMW spell effect range in records is numeric in many runtimes:
    --   0=self, 1=touch, 2=target.
    -- Keep string handling for compatibility with environments exposing symbolic strings.
    if range == 2 or range == "target" or range == "Target" then
        return "target"
    end
    if range == 1 or range == "touch" or range == "Touch" then
        return "touch"
    end
    return "self"
end

local function canAffordSpell(spell_id)
    local spell_record = core.magic.spells.records[spell_id]
    if not spell_record then
        return false
    end
    local magicka = types.Actor.stats.dynamic.magicka(self)
    local current_magicka = magicka and magicka.current or 0
    return current_magicka >= (spell_record.cost or 0)
end

local function dispatchInterceptCast(spell_id)
    local cp = -camera.getPitch()
    local cy = camera.getYaw()
    local camera_dir = util.vector3(
        math.cos(cp) * math.sin(cy),
        math.cos(cp) * math.cos(cy),
        math.sin(cp)
    )

    local start_pos = camera.getPosition()
    local hit_object = nil
    local hit_pos = start_pos

    local ray = nearby.castRay(start_pos, start_pos + (camera_dir * 500), { ignore = self })
    if ray and ray.hit and ray.hitObject then
        hit_object = ray.hitObject
    end
    if ray and ray.hitPos then
        hit_pos = ray.hitPos
    end

    core.sendGlobalEvent(events.INTERCEPT_CAST, {
        sender = self.object,
        spell_id = spell_id,
        start_pos = start_pos,
        direction = camera_dir,
        hit_object = hit_object,
        hit_pos = hit_pos,
    })

    log.info(string.format("intercept dispatch sent spell_id=%s", tostring(spell_id)))
end

local function recordCompiledDispatchSuppressed(spell_id, authorized, reason)
    log.info(string.format(
        "SPELLFORGE_COMPILED_DISPATCH_SUPPRESSED spell_id=%s authorized=%s reason=%s",
        tostring(spell_id),
        tostring(authorized),
        tostring(reason)
    ))
    core.sendGlobalEvent(events.INTERCEPT_DISPATCH_SUPPRESSED, {
        sender = self.object,
        spell_id = spell_id,
        authorized = authorized,
        reason = reason,
    })
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

local function scalarToken(value)
    local value_type = type(value)
    if value_type == "string" then
        return value ~= "" and value or nil
    end
    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end
    return nil
end

local function objectToken(value)
    local direct = scalarToken(value)
    if direct then
        return direct
    end
    if value == nil then
        return nil
    end

    local nested = readField(value, "object")
    if nested ~= nil and nested ~= value then
        local nested_token = objectToken(nested)
        if nested_token then
            return nested_token
        end
    end

    return scalarToken(readField(value, "id"))
        or scalarToken(readField(value, "recordId"))
        or scalarToken(readField(value, "refId"))
        or scalarToken(readField(value, "name"))
        or tostring(value)
end

local function sameObject(left, right, token)
    if left ~= nil and right ~= nil and left == right then
        return true
    end
    local left_token = objectToken(left)
    local right_token = objectToken(right)
    local candidate_token = token ~= nil and tostring(token) or nil
    return (left_token ~= nil and candidate_token ~= nil and left_token == candidate_token)
        or (left_token ~= nil and right_token ~= nil and left_token == right_token)
end

local function positionComponent(position, key)
    local value = readField(position, key)
    return tonumber(value)
end

local function vectorFromPayload(value)
    if value == nil then
        return nil
    end
    local position = readField(value, "position") or value
    local x = positionComponent(position, "x")
    local y = positionComponent(position, "y")
    local z = positionComponent(position, "z")
    if x == nil or y == nil then
        return nil
    end
    return util.vector3(x, y, z or 0)
end

local function safeCall(fn)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return nil
end

local function vectorLength(value)
    if value == nil then
        return nil
    end
    return safeCall(function()
        return value:length()
    end)
end

local function normalizeVector(value, fallback)
    local length = vectorLength(value)
    if length == nil or length <= 0.001 then
        return fallback
    end
    return safeCall(function()
        return value:normalize()
    end) or fallback
end

local function cameraForward()
    local direct = safeCall(function()
        return camera.getViewDirection()
    end)
    if direct ~= nil then
        return normalizeVector(direct, util.vector3(0, 1, 0))
    end

    local yaw = safeCall(function()
        return camera.getYaw()
    end) or 0
    local pitch = safeCall(function()
        return camera.getPitch()
    end) or 0
    local cos_pitch = math.cos(pitch)
    return normalizeVector(util.vector3(
        math.sin(yaw) * cos_pitch,
        math.cos(yaw) * cos_pitch,
        -math.sin(pitch)
    ), util.vector3(0, 1, 0))
end

local function cameraRight(forward)
    local left = safeCall(function()
        return camera.getLeft()
    end)
    if left ~= nil then
        return normalizeVector(left * -1, util.vector3(1, 0, 0))
    end
    local candidate = util.vector3(forward.y, -forward.x, 0)
    return normalizeVector(candidate, util.vector3(1, 0, 0))
end

local function cameraModeInfo()
    local mode = safeCall(function()
        return camera.getMode()
    end)
    local first_person = false
    local mode_name = "unknown"
    if camera.MODE and mode == camera.MODE.FirstPerson then
        first_person = true
        mode_name = "first_person"
    elseif camera.MODE and mode == camera.MODE.ThirdPerson then
        mode_name = "third_person"
    elseif mode ~= nil then
        mode_name = tostring(mode)
    end
    return mode, mode_name, first_person
end

local function spellArea(spell_id)
    local record = spell_id and core.magic and core.magic.spells and core.magic.spells.records[spell_id] or nil
    local area = readField(record, "area")
    if area ~= nil then
        return area
    end
    local effects = readField(record, "effects")
    local first = effects and readField(effects, 1) or nil
    return readField(first, "area")
end

local function inferSelectedSpellforgeHelperId(selected_spell_id)
    local match = ui.findLifecycleByGeneratedSpellId(selected_spell_id)
    local ids = match and match.lifecycle and match.lifecycle.generated_engine_spell_ids or nil
    if type(ids) ~= "table" then
        return nil
    end
    for _, engine_id in ipairs(ids) do
        if type(engine_id) == "string" and engine_id ~= "" and engine_id ~= selected_spell_id then
            return engine_id
        end
    end
    return nil
end

local function buildOsscStyleLaunchPayload(spell_id, opts)
    local options = opts or {}
    local mode, camera_mode, first_person = cameraModeInfo()
    local forward = cameraForward()
    local right = cameraRight(forward)
    local camera_pos = safeCall(function()
        return camera.getPosition()
    end) or readField(self, "position") or readField(self.object, "position") or util.vector3(0, 0, 0)
    local actor_pos = readField(self, "position") or readField(self.object, "position") or camera_pos

    local start_pos
    if first_person then
        start_pos = camera_pos + (forward * 20) - util.vector3(0, 0, 10) - (right * 45)
    else
        start_pos = actor_pos + (forward * 20) + util.vector3(0, 0, 110) - (right * 30)
    end

    local ray_end = camera_pos + (forward * 10000)
    local ray = safeCall(function()
        return nearby.castRay(camera_pos, ray_end, { ignore = self })
    end)
    local hit_object = nil
    local aim_point = ray_end
    if ray and readField(ray, "hit") then
        hit_object = readField(ray, "hitObject")
        aim_point = readField(ray, "hitPos") or aim_point
    end

    local hit_pos = vectorFromPayload(aim_point) or ray_end
    local distance_to_target = vectorLength(hit_pos - start_pos)
    local spawn_offset = 80
    if hit_object ~= nil and distance_to_target ~= nil and distance_to_target < 200 then
        spawn_offset = 10
    end
    local direction = normalizeVector(hit_pos - start_pos, forward)

    local payload = {
        attacker = options.global_direct == true and (self.object or self) or self,
        spellId = spell_id,
        startPos = start_pos,
        direction = direction,
        area = spellArea(spell_id),
        isFree = true,
        item = nil,
        hitObject = hit_object,
        spawnOffset = spawn_offset,
    }
    local telemetry = {
        camera_mode = camera_mode,
        camera_mode_raw = tostring(mode),
        startPos = start_pos,
        direction = direction,
        aimPoint = hit_pos,
        hitObject = hit_object,
        distanceToTarget = distance_to_target,
        spawnOffset = spawn_offset,
        area = payload.area,
    }
    return payload, telemetry
end

local function logDiagLaunchPayload(marker, mode, payload, telemetry, opts)
    local options = opts or {}
    log.info(string.format(
        "%s mode=%s spell_id=%s is_real_vanilla_spell=%s helper_engine_id=%s startPos=%s direction=%s aimPoint=%s hitObject_present=%s distanceToTarget=%s spawnOffset=%s speed_present=%s speed=%s maxSpeed_present=%s maxSpeed=%s area=%s camera_mode=%s diagnostic_enabled=%s",
        marker,
        tostring(mode),
        tostring(payload and payload.spellId),
        tostring(options.is_real_vanilla_spell == true),
        tostring(options.helper_engine_id),
        tostring(telemetry and telemetry.startPos),
        tostring(telemetry and telemetry.direction),
        tostring(telemetry and telemetry.aimPoint),
        tostring(telemetry and telemetry.hitObject ~= nil),
        tostring(telemetry and telemetry.distanceToTarget),
        tostring(telemetry and telemetry.spawnOffset),
        tostring(payload and payload.speed ~= nil),
        tostring(payload and payload.speed),
        tostring(payload and payload.maxSpeed ~= nil),
        tostring(payload and payload.maxSpeed),
        tostring(payload and payload.area),
        tostring(telemetry and telemetry.camera_mode),
        tostring(dev.diagOsscStyleCastRequestEnabled())
    ))
    log.info(string.format(
        "SPELLFORGE_DIAG_LAUNCH_PAYLOAD_COMPARE mode=%s spell_id=%s is_real_vanilla_spell=%s helper_engine_id=%s startPos=%s direction=%s aimPoint=%s hitObject_present=%s distanceToTarget=%s spawnOffset=%s speed_present=%s speed=%s maxSpeed_present=%s maxSpeed=%s area=%s camera_mode=%s diagnostic_flag_state=%s",
        tostring(mode),
        tostring(payload and payload.spellId),
        tostring(options.is_real_vanilla_spell == true),
        tostring(options.helper_engine_id),
        tostring(telemetry and telemetry.startPos),
        tostring(telemetry and telemetry.direction),
        tostring(telemetry and telemetry.aimPoint),
        tostring(telemetry and telemetry.hitObject ~= nil),
        tostring(telemetry and telemetry.distanceToTarget),
        tostring(telemetry and telemetry.spawnOffset),
        tostring(payload and payload.speed ~= nil),
        tostring(payload and payload.speed),
        tostring(payload and payload.maxSpeed ~= nil),
        tostring(payload and payload.maxSpeed),
        tostring(payload and payload.area),
        tostring(telemetry and telemetry.camera_mode),
        tostring(dev.diagOsscStyleCastRequestEnabled())
    ))
    log.info(string.format(
        "SPELLFORGE_DIAG_OSSC_STYLE_RESULT_EXPECTED mode=%s spell_id=%s speed_present=%s maxSpeed_present=%s expected=sfp_auto_speed",
        tostring(mode),
        tostring(payload and payload.spellId),
        tostring(payload and payload.speed ~= nil),
        tostring(payload and payload.maxSpeed ~= nil)
    ))
end

local function sendDirectDiagLaunch(payload, telemetry, opts)
    local direct_payload = {}
    for key, value in pairs(payload or {}) do
        direct_payload[key] = value
    end
    direct_payload.sender = self.object
    direct_payload.attacker = self.object or self
    direct_payload.is_real_vanilla_spell = opts and opts.is_real_vanilla_spell == true
    direct_payload.helper_engine_id = opts and opts.helper_engine_id or nil
    direct_payload.camera_mode = telemetry and telemetry.camera_mode or nil
    direct_payload.aimPoint = telemetry and telemetry.aimPoint or nil
    direct_payload.distanceToTarget = telemetry and telemetry.distanceToTarget or nil
    core.sendGlobalEvent(events.DIAG_OSSC_STYLE_DIRECT_LAUNCH, direct_payload)
end

local function onDiagOsscStyleCast(data)
    if not dev.diagOsscStyleCastRequestEnabled() then
        log.warn("SPELLFORGE_DIAG_OSSC_STYLE_CAST_REQUEST skipped reason=diagnostic_disabled")
        return
    end

    local request = type(data) == "table" and data or {}
    local mode = request.mode or "cast_request"
    local selected = resolveSelectedSpell()
    local selected_spell_id = selected and selected.id or nil
    local spell_id = request.spell_id or request.spellId or request.real_spell_id or dev.diagOsscStyleRealSpellId()
    local is_real_vanilla_spell = true
    local helper_engine_id = nil
    local marker = "SPELLFORGE_DIAG_OSSC_STYLE_CAST_REQUEST"

    if mode == "generated_helper" or mode == "generated_helper_cast_request" then
        helper_engine_id = request.helper_engine_id or request.helperEngineId or inferSelectedSpellforgeHelperId(selected_spell_id)
        spell_id = helper_engine_id
        is_real_vanilla_spell = false
        marker = "SPELLFORGE_DIAG_OSSC_STYLE_GENERATED_HELPER_CAST"
        mode = "generated_helper"
    elseif mode == "direct" then
        mode = "direct_launch"
        marker = "SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH"
    elseif mode ~= "direct_launch" then
        mode = "cast_request"
    else
        marker = "SPELLFORGE_DIAG_OSSC_STYLE_DIRECT_LAUNCH"
    end

    if type(spell_id) ~= "string" or spell_id == "" then
        log.warn(string.format(
            "SPELLFORGE_DIAG_OSSC_STYLE_RESULT_EXPECTED mode=%s spell_id=nil expected=failed reason=missing_spell_id selected_spell_id=%s",
            tostring(mode),
            tostring(selected_spell_id)
        ))
        return
    end
    if core.magic.spells.records[spell_id] == nil then
        log.warn(string.format(
            "SPELLFORGE_DIAG_OSSC_STYLE_RESULT_EXPECTED mode=%s spell_id=%s expected=failed reason=spell_record_missing selected_spell_id=%s helper_engine_id=%s",
            tostring(mode),
            tostring(spell_id),
            tostring(selected_spell_id),
            tostring(helper_engine_id)
        ))
        return
    end

    local payload, telemetry = buildOsscStyleLaunchPayload(spell_id, {
        global_direct = mode == "direct_launch",
    })
    logDiagLaunchPayload(marker, mode, payload, telemetry, {
        is_real_vanilla_spell = is_real_vanilla_spell,
        helper_engine_id = helper_engine_id,
    })

    if mode == "direct_launch" then
        sendDirectDiagLaunch(payload, telemetry, {
            is_real_vanilla_spell = is_real_vanilla_spell,
            helper_engine_id = helper_engine_id,
        })
        return
    end

    core.sendGlobalEvent("MagExp_CastRequest", payload)
end

local function offsetRayStart(start_pos, target_pos)
    local sx = positionComponent(start_pos, "x")
    local sy = positionComponent(start_pos, "y")
    local sz = positionComponent(start_pos, "z") or 0
    local tx = positionComponent(target_pos, "x")
    local ty = positionComponent(target_pos, "y")
    local tz = positionComponent(target_pos, "z") or 0
    if sx == nil or sy == nil or tx == nil or ty == nil then
        return nil, nil
    end

    local dx = tx - sx
    local dy = ty - sy
    local dz = tz - sz
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    if distance <= 1 then
        return nil, distance
    end

    local offset = math.min(24, distance * 0.25)
    return util.vector3(
        sx + (dx / distance) * offset,
        sy + (dy / distance) * offset,
        sz + (dz / distance) * offset
    ), distance
end

local function castLosRay(ray_start, target_pos, ignore_object)
    local ok, ray = pcall(function()
        return nearby.castRay(ray_start, target_pos, { ignore = ignore_object or self })
    end)
    if ok then
        return ray, nil
    end

    if ignore_object ~= self then
        local fallback_ok, fallback_ray = pcall(function()
            return nearby.castRay(ray_start, target_pos, { ignore = self })
        end)
        if fallback_ok then
            return fallback_ray, nil
        end
        return nil, tostring(fallback_ray)
    end

    return nil, tostring(ray)
end

local function losCandidateId(candidate, index)
    return tostring(candidate and candidate.id or ("candidate_" .. tostring(index)))
end

local function raycastChainLosCandidate(start_pos, current_target, candidate, index)
    if type(candidate) ~= "table" then
        return false, "invalid_candidate", false
    end

    local target_pos = vectorFromPayload(candidate.position)
    if target_pos == nil then
        return false, "missing_candidate_position", false
    end

    local ray_start, distance = offsetRayStart(start_pos, target_pos)
    if ray_start == nil then
        return distance ~= nil and distance <= 1, "too_close", false
    end

    local ray, err = castLosRay(ray_start, target_pos, current_target)
    if err ~= nil then
        return false, "cast_failed", true, err
    end

    if not readField(ray, "hit") then
        return true, "clear", true
    end

    local hit_object = readField(ray, "hitObject")
    if sameObject(hit_object, candidate.object, candidate.id) then
        return true, "candidate_hit", true
    end

    return false, "occluded", true
end

local function onChainLosRequest(payload)
    local request_id = payload and payload.request_id
    if type(request_id) ~= "string" or request_id == "" then
        return
    end

    local start_pos = vectorFromPayload(payload.start_pos)
    if start_pos == nil then
        core.sendGlobalEvent(events.CHAIN_LOS_RESULT, {
            request_id = request_id,
            ok = false,
            rejection_reason = "chain_los_invalid_request",
            error = "missing start_pos",
        })
        return
    end

    local candidates = payload.candidates
    if type(candidates) ~= "table" then
        candidates = {}
    end

    local visible_ids = {}
    local blocked_count = 0
    local raycast_count = 0
    local error_count = 0
    local current_target = payload.current_target
    for index, candidate in ipairs(candidates) do
        local visible, reason, did_raycast, err = raycastChainLosCandidate(start_pos, current_target, candidate, index)
        if did_raycast then
            raycast_count = raycast_count + 1
        end
        if visible then
            visible_ids[#visible_ids + 1] = losCandidateId(candidate, index)
        else
            blocked_count = blocked_count + 1
            if reason == "cast_failed" then
                error_count = error_count + 1
                log.warn(string.format(
                    "Chain LOS raycast failed request_id=%s candidate_id=%s error=%s",
                    tostring(request_id),
                    losCandidateId(candidate, index),
                    tostring(err)
                ))
            end
        end
    end

    if #candidates > 0 and error_count == #candidates then
        core.sendGlobalEvent(events.CHAIN_LOS_RESULT, {
            request_id = request_id,
            ok = false,
            rejection_reason = "chain_los_unavailable",
            error = "all local raycasts failed",
            raycast_count = raycast_count,
        })
        return
    end

    core.sendGlobalEvent(events.CHAIN_LOS_RESULT, {
        request_id = request_id,
        ok = true,
        visible_ids = visible_ids,
        blocked_count = blocked_count,
        raycast_count = raycast_count,
    })
    log.info(string.format(
        "SPELLFORGE_CHAIN_LOS_LOCAL_RESULT request_id=%s candidate_count=%s visible_count=%s blocked_count=%s raycast_count=%s",
        tostring(request_id),
        tostring(#candidates),
        tostring(#visible_ids),
        tostring(blocked_count),
        tostring(raycast_count)
    ))
end

local function clearInterceptState()
    state.is_casting = false
    state.pending_intercept_spell_id = nil
    state.pending_intercept_variant = nil
    state.intercept_spell_id = nil
    state.intercept_variant = nil
    state.pending_cast_authorized = false
end

local function clearPendingReleaseState()
    if state.pending_release_timer then
        state.pending_release_timer:cancel()
        state.pending_release_timer = nil
    end
    state.pending_release_spell_id = nil
end

local function spellAlwaysSucceeds(spell_id)
    local spell_record = spell_id and core.magic.spells.records[spell_id] or nil
    if type(spell_record) ~= "table" then
        return false
    end

    if spell_record.alwaysSucceedFlag ~= nil then
        return spell_record.alwaysSucceedFlag == true or spell_record.alwaysSucceedFlag == 1
    end
    if spell_record.alwaysSucceed ~= nil then
        return spell_record.alwaysSucceed == true or spell_record.alwaysSucceed == 1
    end
    return false
end

local function registerSkillProgressionHandler()
    if state.skill_handler_registered then
        return
    end

    local progression = interfaces.SkillProgression
    if progression == nil or type(progression.addSkillUsedHandler) ~= "function" then
        log.warn("skill progression unavailable: addSkillUsedHandler missing")
        return
    end

    local use_types = progression.SKILL_USE_TYPES or {}
    local spellcast_success = use_types.Spellcast_Success
    if spellcast_success == nil then
        log.warn("skill progression unavailable: SKILL_USE_TYPES.Spellcast_Success missing")
        return
    end

    progression.addSkillUsedHandler(function(skillid, params)
        log.debug(string.format(
            "SKILL_USED_RAW skillid=%s useType=%s",
            tostring(skillid),
            tostring(params and params.useType)
        ))

        local selected_spell = resolveSelectedSpell()
        local selected_spell_id = selected_spell and selected_spell.id or state.last_selected_spell_id
        local selected_runtime_spell_id = resolveGeneratedSpellAlias(selected_spell_id, "skill-progression")
        local selected_meta = selected_runtime_spell_id and state.spell_metadata_cache[selected_runtime_spell_id] or nil
        local selected_is_cached_spellforge = selected_meta and selected_meta.is_spellforge == true or false
        local should_log_diag = state.pending_intercept_spell_id ~= nil
            or state.intercept_spell_id ~= nil
            or state.is_casting == true
            or selected_is_cached_spellforge

        if should_log_diag then
            log.debug(string.format(
                "SPELLFORGE_SKILL_USE_DIAG skillid=%s useType=%s expectedSuccess=%s skill=%s source=%s actor=%s selected_spell_id=%s runtime_spell_id=%s pending_spell_id=%s intercept_spell_id=%s is_casting=%s pending_cast_authorized=%s",
                tostring(skillid),
                tostring(params and params.useType),
                tostring(spellcast_success),
                tostring(params and params.skill),
                tostring(params and params.source),
                tostring(params and params.actor),
                tostring(selected_spell_id),
                tostring(selected_runtime_spell_id),
                tostring(state.pending_intercept_spell_id),
                tostring(state.intercept_spell_id),
                tostring(state.is_casting),
                tostring(state.pending_cast_authorized)
            ))
        end

        if not params or params.useType ~= spellcast_success then
            return
        end

        if selected_is_cached_spellforge and not state.is_casting and state.intercept_spell_id == nil and state.pending_intercept_spell_id == nil then
            log.debug(string.format(
                "SPELLFORGE_SKILL_SUCCESS_OUTSIDE_INTERCEPT_WINDOW useType=%s selected_spell_id=%s",
                tostring(params.useType),
                tostring(selected_spell_id)
            ))
        end

        if state.is_casting then
            state.pending_cast_authorized = true
            log.debug(string.format(
                "cast authorization received useType=%s active_spell_id=%s",
                tostring(params.useType),
                tostring(state.intercept_spell_id)
            ))
        elseif state.pending_release_spell_id then
            local late_spell_id = state.pending_release_spell_id
            clearPendingReleaseState()
            log.debug(string.format(
                "late cast authorization received after release spell_id=%s; dispatching now",
                tostring(late_spell_id)
            ))
            dispatchInterceptCast(late_spell_id)
        end
    end)

    state.skill_handler_registered = true
    log.debug("registered skill progression Spellcast_Success handler")
end

local function registerAnimationTextKeys()
    if state.animation_diag_registered then
        return
    end
    if interfaces.AnimationController == nil or type(interfaces.AnimationController.addTextKeyHandler) ~= "function" then
        log.warn("animation diagnostics unavailable: AnimationController.addTextKeyHandler missing")
        return
    end

    interfaces.AnimationController.addTextKeyHandler("spellcast", function(groupname, key)
        if groupname ~= "spellcast" then
            return
        end

        local selected_spell = resolveSelectedSpell()
        core.sendGlobalEvent(events.CAST_DIAG_SIGNAL, {
            sender = self.object,
            groupname = groupname,
            key = key,
            selected_spell_id = (selected_spell and selected_spell.id) or state.intercept_spell_id,
        })

        if not state.is_casting then
            local pending_spell_id = state.pending_intercept_spell_id
            local pending_variant = state.pending_intercept_variant or "self"
            if pending_spell_id and key == (pending_variant .. " start") then
                local always_succeed = spellAlwaysSucceeds(pending_spell_id)
                state.pending_cast_authorized = always_succeed == true
                state.is_casting = true
                state.intercept_spell_id = pending_spell_id
                state.intercept_variant = pending_variant
                state.pending_intercept_spell_id = nil
                state.pending_intercept_variant = nil
                log.debug(string.format(
                    "intercept armed spell_id=%s variant=%s alwaysSucceed=%s authorized_initial=%s",
                    tostring(state.intercept_spell_id),
                    tostring(state.intercept_variant),
                    tostring(always_succeed),
                    tostring(state.pending_cast_authorized)
                ))
            end
            return
        end

        local variant = state.intercept_variant or "self"
        if key == (variant .. " release") then
            local spell_id = state.intercept_spell_id
            local authorized = state.pending_cast_authorized == true

            if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
                clearInterceptState()
                clearPendingReleaseState()
                log.debug("intercept release aborted: stance changed")
                return
            end

            log.debug(string.format(
                "intercept release spell_id=%s variant=%s authorized=%s",
                tostring(spell_id),
                tostring(variant),
                tostring(authorized)
            ))
            if spell_id and authorized then
                dispatchInterceptCast(spell_id)
                clearPendingReleaseState()
            else
                local reason = authorized and "missing spell_id" or "no authorization"
                if spell_id and not authorized then
                    clearPendingReleaseState()
                    state.pending_release_spell_id = spell_id
                    state.pending_release_timer = async:newUnsavableSimulationTimer(0.35, function()
                        if not state.pending_release_spell_id then
                            return
                        end
                        local timeout_spell_id = state.pending_release_spell_id
                        clearPendingReleaseState()
                        log.debug(string.format(
                            "intercept release suppressed spell_id=%s reason=late authorization timeout",
                            tostring(timeout_spell_id)
                        ))
                        recordCompiledDispatchSuppressed(timeout_spell_id, false, "late authorization timeout")
                    end)
                    log.debug(string.format(
                        "intercept release waiting for late authorization spell_id=%s window=0.35",
                        tostring(spell_id)
                    ))
                else
                    clearPendingReleaseState()
                    log.debug(string.format(
                        "intercept release suppressed spell_id=%s reason=%s",
                        tostring(spell_id),
                        reason
                    ))
                    recordCompiledDispatchSuppressed(spell_id, authorized, reason)
                end
            end
            clearInterceptState()
        elseif key == (variant .. " stop") then
            clearInterceptState()
            clearPendingReleaseState()
            log.debug("intercept canceled on stop key")
        end
    end)

    state.animation_diag_registered = true
    log.debug("registered spellcast text-key handler")
end

local function onInputAction(action)
    if action ~= input.ACTION.Use then
        return true
    end

    if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
        return true
    end

    local selected = resolveSelectedSpell()
    local selected_spell_id = selected and selected.id
    if type(selected_spell_id) ~= "string" or selected_spell_id == "" then
        return true
    end

    local runtime_spell_id = resolveGeneratedSpellAlias(selected_spell_id, "input")
    local meta = state.spell_metadata_cache[runtime_spell_id]
    if not meta then
        refreshSpellMetadata(runtime_spell_id, "input-miss")
        return true
    end
    if meta.is_spellforge ~= true then
        if runtime_spell_id == selected_spell_id then
            requestGeneratedSpellRepair(selected_spell_id, "input-non-spellforge")
        end
        return true
    end

    if state.is_casting or state.pending_intercept_spell_id ~= nil or state.pending_release_spell_id ~= nil then
        return true
    end

    if not canAffordSpell(runtime_spell_id) then
        log.debug(string.format("intercept skipped: insufficient magicka spell_id=%s selected_spell_id=%s", tostring(runtime_spell_id), tostring(selected_spell_id)))
        return true
    end

    local variant = classifyVariant(meta.root_base_spell_id, meta.root_range)
    state.pending_intercept_spell_id = runtime_spell_id
    state.pending_intercept_variant = variant
    state.pending_cast_authorized = false
    log.debug(string.format(
        "intercept pending spell_id=%s selected_spell_id=%s variant=%s",
        tostring(runtime_spell_id),
        tostring(selected_spell_id),
        tostring(variant)
    ))

    return true
end

local function onKeyPress(key)
    local ui_handled = spellcrafting_ui.handleKeyPress(key)
    if ui_handled == false then
        return false
    end
    if spellcrafting_ui.isVisible() then
        return true
    end

    return true
end

local function classifyDispatchResult(payload)
    if type(payload) ~= "table" then
        return nil
    end
    if type(payload.dispatch_kind) == "string" then
        return payload.dispatch_kind
    end
    if payload.recipe_id ~= nil then
        return "compiled_spellforge"
    end
    return nil
end

local function onInterceptDispatchResult(payload)
    if type(payload) ~= "table" then
        return
    end

    local dispatch_kind = classifyDispatchResult(payload)
    if payload.ok == true then
        if dispatch_kind == "compiled_spellforge" or dispatch_kind == "compiled_spellforge_2_2c_helper" then
            log.info(string.format(
                "SPELLFORGE_COMPILED_DISPATCH_OK spell_id=%s dispatch_count=%s",
                tostring(payload.spell_id),
                tostring(payload.dispatch_count)
            ))
        else
            log.debug(string.format(
                "intercept dispatch result ignored: unknown dispatch kind spell_id=%s",
                tostring(payload.spell_id)
            ))
        end
        return
    end

    log.error(string.format("intercept dispatch failed spell_id=%s err=%s", tostring(payload.spell_id), tostring(payload.error)))
    recordCompiledDispatchSuppressed(payload.spell_id, "unknown", payload.error or "dispatch failed")
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onFrame = function()
            if state.backend == "INIT" then
                requestBackend()
                return
            end
            if state.backend ~= "READY" then
                return
            end

            local selected = resolveSelectedSpell()
            local selected_spell_id = selected and selected.id or nil
            local runtime_spell_id = resolveGeneratedSpellAlias(selected_spell_id, "onFrame")
            if selected_spell_id ~= state.last_selected_spell_id then
                state.last_selected_spell_id = selected_spell_id
                refreshSpellMetadata(runtime_spell_id, "selected-changed")
            elseif runtime_spell_id
                and state.spell_metadata_cache[runtime_spell_id] == nil
                and state.pending_metadata_by_spell_id[runtime_spell_id] == nil
            then
                refreshSpellMetadata(runtime_spell_id, "selected-cache-miss")
            end
        end,
        onKeyPress = onKeyPress,
        onInputAction = onInputAction,
    },
    eventHandlers = {
        [events.BACKEND_READY] = function(payload)
            onBackendReady(payload)
            registerSkillProgressionHandler()
            registerAnimationTextKeys()
        end,
        [events.BACKEND_UNAVAILABLE] = onBackendUnavailable,
        [events.QUERY_SPELL_METADATA_RESULT] = function(payload)
            local request_id = payload and payload.request_id
            local cb = request_id and state.pending_spell_queries[request_id]
            if cb then
                state.pending_spell_queries[request_id] = nil
                cb(payload)
            end
        end,
        [events.COMPILE_RESULT] = function(payload)
            onCompileResult(payload)
            ui.handleCompileResult(payload)
            if payload and payload.ok and payload.spell_id then
                refreshSpellMetadata(payload.spell_id, "compile-result")
            end
        end,
        [events.REHYDRATE_COMPILED_RESULT] = ui.handleRehydrateResult,
        [events.VALIDATE_RESULT] = ui.handleValidateResult,
        [events.PREVIEW_RESULT] = ui.handlePreviewResult,
        [events.UI_CATALOG_RESULT] = ui.handleCatalogResult,
        [events.AVAILABLE_EFFECTS_RESULT] = ui.handleAvailableEffectsResult,
        [events.INTERCEPT_DISPATCH_RESULT] = onInterceptDispatchResult,
        [events.CHAIN_LOS_REQUEST] = onChainLosRequest,
        [events.DIAG_OSSC_STYLE_CAST] = onDiagOsscStyleCast,
        UiModeChanged = function(data)
            spellcrafting_ui.handleUiModeChanged(data)
        end,
    },
}
