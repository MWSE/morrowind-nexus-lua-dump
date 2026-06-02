local interfaces = require("openmw.interfaces")
local log = require("scripts.spellforge.shared.log").new("global.sfp_adapter")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local sfp_adapter = {}

local BETA3_LAUNCH_FIELDS = {
    "attacker",
    "spellId",
    "itemObject",
    "casterLinked",
    "startPos",
    "direction",
    "hitObject",
    "isFree",
    "userData",
    "muteAudio",
    "muteLight",
    "speed",
    "maxSpeed",
    "minSpeed",
    "accelerationExp",
    "forceVec",
    "maxLifetime",
    "spawnOffset",
    "isPaused",
    "bounceEnabled",
    "bounceMax",
    "bouncePower",
    "piercing",
    "pierceLimit",
    "detonateOnActorHit",
    "impactImpulse",
    "areaVfxRecId",
    "areaVfxScale",
    "vfxRecId",
    "boltModel",
    "hitModel",
    "boltSound",
    "boltLightId",
    "spinSpeed",
    "muteCastGlow",
    "continuousVfx",
    "excludeTarget",
    "forcedEffects",
    "spellType",
    "area",
    "unreflectable",
    "nonRecastable",
    "itemRequirements",
}

local BETA3_DETONATE_FIELDS = {
    "spellId",
    "caster",
    "position",
    "cell",
    "itemObject",
    "forcedEffects",
    "unreflectable",
    "casterLinked",
    "vfxOverride",
    "impactSpeed",
    "maxSpeed",
    "areaVfxRecId",
    "areaVfxScale",
    "excludeTarget",
    "userData",
    "muteAudio",
    "muteLight",
}

local DETONATE_ALIASES = {
    spellId = { "spellId", "spell_id" },
    caster = { "caster", "attacker", "actor" },
    position = { "position", "pos", "hitPos", "hit_pos" },
    cell = { "cell" },
    itemObject = { "itemObject", "item_object", "item" },
    forcedEffects = { "forcedEffects", "forced_effects" },
    unreflectable = { "unreflectable" },
    casterLinked = { "casterLinked", "caster_linked" },
    vfxOverride = { "vfxOverride", "vfx_override" },
    impactSpeed = { "impactSpeed", "impact_speed" },
    maxSpeed = { "maxSpeed", "max_speed" },
    areaVfxRecId = { "areaVfxRecId", "area_vfx_rec_id" },
    areaVfxScale = { "areaVfxScale", "area_vfx_scale" },
    excludeTarget = { "excludeTarget", "exclude_target" },
    userData = { "userData", "user_data" },
    muteAudio = { "muteAudio", "mute_audio" },
    muteLight = { "muteLight", "mute_light" },
}

local MAGIC_HIT_TELEMETRY_FIELDS = {
    "impactSpeed",
    "maxSpeed",
    "velocity",
    "magMin",
    "magMax",
    "casterLinked",
    "stackLimit",
    "stackCount",
}

local function magExp()
    return interfaces.MagExp
end

local function hasFunction(name)
    local mag = magExp()
    return mag ~= nil and type(mag[name]) == "function"
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

local function firstPresent(tbl, aliases)
    if type(tbl) ~= "table" then
        return nil
    end
    for _, key in ipairs(aliases or {}) do
        local value = readField(tbl, key)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function detectPresentFields(value, fields)
    local out = { count = 0 }
    for _, field in ipairs(fields or {}) do
        if readField(value, field) ~= nil then
            out[field] = true
            out.count = out.count + 1
        end
    end
    return out
end

local function countArray(values)
    local n = 0
    for _, value in ipairs(values or {}) do
        if value ~= nil then
            n = n + 1
        end
    end
    return n
end

local function noteBeta3ForwardCounters(forwarded)
    if not forwarded then
        return
    end
    if forwarded.areaVfxRecId then
        runtime_stats.inc("sfp_adapter_area_vfx_forwarded")
    end
    if forwarded.areaVfxScale then
        runtime_stats.inc("sfp_adapter_area_vfx_scale_forwarded")
    end
    if forwarded.excludeTarget then
        runtime_stats.inc("sfp_adapter_exclude_target_forwarded")
    end
    if forwarded.spawnOffset then
        runtime_stats.inc("sfp_adapter_spawn_offset_forwarded")
    end
    if forwarded.maxLifetime then
        runtime_stats.inc("sfp_adapter_max_lifetime_forwarded")
    end
    if forwarded.forceVec then
        runtime_stats.inc("sfp_adapter_force_vec_forwarded")
    end
    if forwarded.muteCastGlow then
        runtime_stats.inc("sfp_adapter_mute_cast_glow_forwarded")
    end
    if forwarded.piercing then
        runtime_stats.inc("sfp_adapter_piercing_forwarded")
    end
    if forwarded.pierceLimit then
        runtime_stats.inc("sfp_adapter_pierce_limit_forwarded")
    end
end

local function normalizeId(value)
    if value == nil then
        return nil
    end
    local value_type = type(value)
    if value_type == "string" then
        if value == "" then
            return nil
        end
        return value
    elseif value_type == "number" then
        return tostring(value)
    end
    return nil
end

local function nonEmptyString(value)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

local function finitePositiveNumber(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge or n <= 0 then
        return nil
    end
    return n
end

function sfp_adapter.extractProjectileId(projectile)
    local direct = normalizeId(projectile)
    if direct then
        return direct, "direct"
    end

    local id = normalizeId(readField(projectile, "id"))
    if id then
        return id, "id"
    end

    id = normalizeId(readField(projectile, "projId"))
    if id then
        return id, "projId"
    end

    id = normalizeId(readField(projectile, "projectileId"))
    if id then
        return id, "projectileId"
    end

    return nil, nil
end

function sfp_adapter.extractProjectileFromHit(payload)
    local data = payload or {}
    local projectile = data.projectile or data.proj or data.spellProjectile
    local projectile_id = normalizeId(data.projectile_id)
        or normalizeId(data.projectileId)
        or normalizeId(data.proj_id)
        or normalizeId(data.projId)

    local id_source = nil
    if projectile_id then
        id_source = "payload"
    elseif projectile ~= nil then
        projectile_id, id_source = sfp_adapter.extractProjectileId(projectile)
        if id_source then
            id_source = "projectile." .. id_source
        end
    end

    return projectile, projectile_id, id_source
end

function sfp_adapter.magicHitTelemetry(payload)
    local data = payload or {}
    local telemetry = {}
    local present_count = 0
    for _, field in ipairs(MAGIC_HIT_TELEMETRY_FIELDS) do
        local value = data[field]
        telemetry[field] = value
        telemetry["has_" .. field] = value ~= nil
        if value ~= nil then
            present_count = present_count + 1
        end
    end
    telemetry.present_count = present_count
    telemetry.has_any_beta2_fields = present_count > 0
    return telemetry
end

function sfp_adapter.capabilities()
    local mag = magExp()
    local has_launch_spell = hasFunction("launchSpell")
    return {
        has_interface = mag ~= nil,
        has_launchSpell = has_launch_spell,
        has_getActiveSpellIds = hasFunction("getActiveSpellIds"),
        has_getSpellState = hasFunction("getSpellState"),
        has_setSpellPhysics = hasFunction("setSpellPhysics"),
        has_redirectSpell = hasFunction("redirectSpell"),
        has_setSpellSpeed = hasFunction("setSpellSpeed"),
        has_setSpellPaused = hasFunction("setSpellPaused"),
        has_cancelSpell = hasFunction("cancelSpell"),
        has_setSpellBounce = hasFunction("setSpellBounce"),
        has_setSpellPiercing = hasFunction("setSpellPiercing"),
        has_setSpellDetonateOnActor = hasFunction("setSpellDetonateOnActor"),
        has_detonateSpellAtPos = hasFunction("detonateSpellAtPos"),
        has_applySpellToActor = hasFunction("applySpellToActor"),
        has_emitProjectileFromObject = hasFunction("emitProjectileFromObject"),
        has_addTargetFilter = hasFunction("addTargetFilter"),
        has_setTargetFilter = hasFunction("setTargetFilter"),
        has_impactImpulse_field = mag ~= nil and has_launch_spell,
        has_impactImpulse_launch_field = mag ~= nil and has_launch_spell,
        has_magic_hit_impactSpeed = false,
        has_magic_hit_magMin_magMax = false,
        has_magic_hit_casterLinked = false,
        known_launch_fields = BETA3_LAUNCH_FIELDS,
        known_detonate_fields = BETA3_DETONATE_FIELDS,
    }
end

local function callFunction(name, ...)
    local mag = magExp()
    if mag == nil then
        return { ok = false, capability = false, error = "I.MagExp missing" }
    end
    local fn = mag[name]
    if type(fn) ~= "function" then
        return { ok = false, capability = false, error = "I.MagExp." .. name .. " missing" }
    end

    local ok, result = pcall(fn, ...)
    if not ok then
        return { ok = false, capability = true, error = tostring(result) }
    end
    return { ok = true, capability = true, result = result }
end

local function guardedProjectileCall(name, projectile_id, ...)
    log.info(string.format(
        "SPELLFORGE_SFP_CALL_GUARDED fn=%s projectile_id=%s projectile_generation=%s runtime_generation=%s",
        tostring(name),
        tostring(projectile_id),
        tostring(runtime_session.projectileGeneration(projectile_id)),
        tostring(runtime_session.currentGeneration())
    ))
    if projectile_id == nil then
        local result = { ok = false, capability = false, error = "projectile_id missing" }
        log.warn(string.format(
            "SPELLFORGE_SFP_CALL_FAILED fn=%s projectile_id=%s error=%s",
            tostring(name),
            tostring(projectile_id),
            tostring(result.error)
        ))
        return result
    end
    if runtime_session.projectileIsStale(projectile_id) then
        local result = {
            ok = false,
            capability = true,
            skipped_stale_generation = true,
            error = "stale_runtime_generation",
        }
        log.warn(string.format(
            "SPELLFORGE_SFP_CALL_SKIPPED_STALE_GENERATION fn=%s projectile_id=%s projectile_generation=%s runtime_generation=%s",
            tostring(name),
            tostring(projectile_id),
            tostring(runtime_session.projectileGeneration(projectile_id)),
            tostring(runtime_session.currentGeneration())
        ))
        return result
    end

    local result = callFunction(name, projectile_id, ...)
    if not result.ok then
        log.warn(string.format(
            "SPELLFORGE_SFP_CALL_FAILED fn=%s projectile_id=%s error=%s",
            tostring(name),
            tostring(projectile_id),
            tostring(result.error)
        ))
    end
    return result
end

function sfp_adapter.launchSpell(data)
    runtime_stats.inc("sfp_adapter_launch_calls")
    local forwarded_fields = sfp_adapter.forwardedLaunchFields(data)
    noteBeta3ForwardCounters(forwarded_fields)
    local result = callFunction("launchSpell", data)
    if not result.ok then
        runtime_stats.inc("sfp_adapter_launch_failed")
        result.forwarded_fields = forwarded_fields
        return result
    end
    runtime_stats.inc("sfp_adapter_launch_ok")

    local projectile = result.result
    local projectile_id, projectile_id_source = sfp_adapter.extractProjectileId(projectile)
    result.projectile_id = projectile_id
    result.projectile_id_source = projectile_id_source
    result.launch_result_raw = projectile
    result.launch_returns_projectile = projectile ~= nil
    result.can_extract_projectile_id = projectile_id ~= nil
    result.forwarded_fields = forwarded_fields
    result.warnings = {}
    result.capability_notes = {
        launch_returns_projectile = result.launch_returns_projectile,
        can_extract_projectile_id = result.can_extract_projectile_id,
    }
    return result
end

function sfp_adapter.forwardedLaunchFields(data)
    return detectPresentFields(data, BETA3_LAUNCH_FIELDS)
end

function sfp_adapter.getActiveSpellIds()
    return callFunction("getActiveSpellIds")
end

function sfp_adapter.requestSpellState(projectile_id, tag)
    return guardedProjectileCall("getSpellState", projectile_id, tag)
end

function sfp_adapter.getSpellState(projectile_id, tag)
    return sfp_adapter.requestSpellState(projectile_id, tag)
end

function sfp_adapter.setSpellPhysics(projectile_id, data)
    return guardedProjectileCall("setSpellPhysics", projectile_id, data)
end

function sfp_adapter.redirectSpell(projectile_id, direction)
    return guardedProjectileCall("redirectSpell", projectile_id, direction)
end

function sfp_adapter.setSpellSpeed(projectile_id, speed)
    return guardedProjectileCall("setSpellSpeed", projectile_id, speed)
end

function sfp_adapter.setSpellPaused(projectile_id, paused)
    return guardedProjectileCall("setSpellPaused", projectile_id, paused)
end

function sfp_adapter.cancelSpell(projectile_id)
    runtime_stats.inc("sfp_adapter_cancel_calls")
    if not hasFunction("cancelSpell") then
        runtime_stats.inc("sfp_adapter_missing_cancel")
    end
    local result = guardedProjectileCall("cancelSpell", projectile_id)
    if result.ok then
        runtime_stats.inc("sfp_adapter_cancel_ok")
    else
        runtime_stats.inc("sfp_adapter_cancel_failed")
    end
    return result
end

function sfp_adapter.setSpellBounce(projectile_id, enabled, max, power)
    return guardedProjectileCall("setSpellBounce", projectile_id, enabled, max, power)
end

function sfp_adapter.setSpellPiercing(projectile_id, enabled, newLimit)
    return guardedProjectileCall("setSpellPiercing", projectile_id, enabled, newLimit)
end

function sfp_adapter.setSpellDetonateOnActor(projectile_id, enabled)
    return guardedProjectileCall("setSpellDetonateOnActor", projectile_id, enabled)
end

local function normalizeDetonateArgs(...)
    local arg_count = select("#", ...)
    local first = select(1, ...)
    if type(first) == "table" then
        local args = first
        local normalized = {
            legacy_positional = false,
            spellId = firstPresent(args, DETONATE_ALIASES.spellId),
            caster = firstPresent(args, DETONATE_ALIASES.caster),
            position = firstPresent(args, DETONATE_ALIASES.position),
            cell = firstPresent(args, DETONATE_ALIASES.cell),
            itemObject = firstPresent(args, DETONATE_ALIASES.itemObject),
            forcedEffects = firstPresent(args, DETONATE_ALIASES.forcedEffects),
            unreflectable = firstPresent(args, DETONATE_ALIASES.unreflectable),
            casterLinked = firstPresent(args, DETONATE_ALIASES.casterLinked),
            vfxOverride = firstPresent(args, DETONATE_ALIASES.vfxOverride),
            impactSpeed = firstPresent(args, DETONATE_ALIASES.impactSpeed),
            maxSpeed = firstPresent(args, DETONATE_ALIASES.maxSpeed),
            areaVfxRecId = firstPresent(args, DETONATE_ALIASES.areaVfxRecId),
            areaVfxScale = firstPresent(args, DETONATE_ALIASES.areaVfxScale),
            excludeTarget = firstPresent(args, DETONATE_ALIASES.excludeTarget),
            userData = firstPresent(args, DETONATE_ALIASES.userData),
            muteAudio = firstPresent(args, DETONATE_ALIASES.muteAudio),
            muteLight = firstPresent(args, DETONATE_ALIASES.muteLight),
        }
        if normalized.vfxOverride == nil then
            normalized.vfxOverride = normalized.areaVfxRecId
        end
        normalized.forwarded_fields = detectPresentFields(normalized, BETA3_DETONATE_FIELDS)
        normalized.positional_count = countArray({
            normalized.spellId,
            normalized.caster,
            normalized.position,
            normalized.cell,
            normalized.itemObject,
            normalized.forcedEffects,
            normalized.unreflectable,
            normalized.casterLinked,
            normalized.vfxOverride,
            normalized.impactSpeed,
            normalized.maxSpeed,
            normalized.areaVfxScale,
            normalized.excludeTarget,
            normalized.userData,
            normalized.muteAudio,
            normalized.muteLight,
        })
        return normalized
    end

    local spell_id = select(1, ...)
    local caster = select(2, ...)
    local pos = select(3, ...)
    local cell = select(4, ...)
    local fifth = select(5, ...)
    local normalized = {
        legacy_positional = arg_count <= 5,
        spellId = spell_id,
        caster = caster,
        position = pos,
        cell = cell,
    }
    if arg_count <= 5 then
        normalized.item = fifth
    else
        normalized.itemObject = fifth
        normalized.forcedEffects = select(6, ...)
        normalized.unreflectable = select(7, ...)
        normalized.casterLinked = select(8, ...)
        normalized.vfxOverride = select(9, ...)
        normalized.impactSpeed = select(10, ...)
        normalized.maxSpeed = select(11, ...)
        normalized.areaVfxScale = select(12, ...)
        normalized.excludeTarget = select(13, ...)
        normalized.userData = select(14, ...)
        normalized.muteAudio = select(15, ...)
        normalized.muteLight = select(16, ...)
        normalized.areaVfxRecId = normalized.vfxOverride
    end
    normalized.forwarded_fields = detectPresentFields(normalized, BETA3_DETONATE_FIELDS)
    normalized.positional_count = arg_count
    return normalized
end

function sfp_adapter.previewDetonateArgs(...)
    local normalized = normalizeDetonateArgs(...)
    normalized.ok = true
    return normalized
end

function sfp_adapter.previewCollisionVfxArgs(data)
    local args = data or {}
    local area_vfx_rec_id = nonEmptyString(firstPresent(args, DETONATE_ALIASES.areaVfxRecId))
    local area_vfx_scale = finitePositiveNumber(firstPresent(args, DETONATE_ALIASES.areaVfxScale))
    local vfx_rec_id = nonEmptyString(readField(args, "vfxRecId")) or nonEmptyString(readField(args, "vfx_rec_id"))
    local hit_model = nonEmptyString(readField(args, "hitModel")) or nonEmptyString(readField(args, "hit_model"))

    -- Spellforge's boundary policy mirrors the required SFP collision fix:
    -- never promote bolt vfxRecId into the area VFX override. A nil area
    -- override must leave SFP free to fall back to the spell effect areaStatic.
    return {
        ok = true,
        spellId = firstPresent(args, DETONATE_ALIASES.spellId),
        caster = firstPresent(args, DETONATE_ALIASES.caster),
        position = firstPresent(args, DETONATE_ALIASES.position),
        cell = firstPresent(args, DETONATE_ALIASES.cell),
        excludeTarget = firstPresent(args, DETONATE_ALIASES.excludeTarget),
        areaVfxRecId = area_vfx_rec_id,
        areaVfxScale = area_vfx_scale,
        vfxRecId = vfx_rec_id,
        hitModel = hit_model,
        userData = firstPresent(args, DETONATE_ALIASES.userData),
        muteAudio = firstPresent(args, DETONATE_ALIASES.muteAudio),
        muteLight = firstPresent(args, DETONATE_ALIASES.muteLight),
        vfx_override_passed = area_vfx_rec_id,
        used_bolt_as_area_override = false,
        default_area_fallback_expected = area_vfx_rec_id == nil,
        area_override_used = area_vfx_rec_id ~= nil,
        areaVfxScale_forwarded = area_vfx_scale ~= nil,
        hit_model_spawn_attempted = hit_model ~= nil,
    }
end

function sfp_adapter.detonateSpellAtPos(...)
    runtime_stats.inc("sfp_adapter_detonate_calls")
    if not hasFunction("detonateSpellAtPos") then
        runtime_stats.inc("sfp_adapter_missing_detonate")
    end

    local args = normalizeDetonateArgs(...)
    noteBeta3ForwardCounters(args.forwarded_fields)

    -- Legacy positional calls keep the original five-argument SFP shape:
    -- detonateSpellAtPos(spellId, caster, pos, cell, item).
    -- Spellforge table args are normalized onto the SFP 1.7 ordered shape:
    -- item, forcedEffects, unreflectable, casterLinked, vfxOverride,
    -- impactSpeed, maxSpeed, areaVfxScale, excludeTarget, userData, mutes.
    local result
    if args.legacy_positional then
        result = callFunction("detonateSpellAtPos", args.spellId, args.caster, args.position, args.cell, args.item)
    else
        result = callFunction(
            "detonateSpellAtPos",
            args.spellId,
            args.caster,
            args.position,
            args.cell,
            args.itemObject,
            args.forcedEffects,
            args.unreflectable,
            args.casterLinked,
            args.vfxOverride,
            args.impactSpeed,
            args.maxSpeed,
            args.areaVfxScale,
            args.excludeTarget,
            args.userData,
            args.muteAudio,
            args.muteLight
        )
    end

    result.forwarded_fields = args.forwarded_fields
    result.legacy_positional = args.legacy_positional == true
    if result.ok then
        runtime_stats.inc("sfp_adapter_detonate_ok")
    else
        runtime_stats.inc("sfp_adapter_detonate_failed")
    end
    return result
end

function sfp_adapter.applySpellToActor(spell_id, caster, target, hit_pos, is_aoe, item)
    return callFunction("applySpellToActor", spell_id, caster, target, hit_pos, is_aoe, item)
end

function sfp_adapter.emitProjectileFromObject(data)
    return callFunction("emitProjectileFromObject", data)
end

function sfp_adapter.registerTargetFilter(fn)
    if type(fn) ~= "function" then
        return { ok = false, capability = false, error = "target filter must be a function" }
    end
    if hasFunction("addTargetFilter") then
        return callFunction("addTargetFilter", fn)
    end
    if hasFunction("setTargetFilter") then
        return callFunction("setTargetFilter", fn)
    end
    return { ok = false, capability = false, error = "I.MagExp target filter API missing" }
end

return sfp_adapter
