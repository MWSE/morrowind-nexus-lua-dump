local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.chain_target_provider")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")

local ok_world, world = pcall(require, "openmw.world")
local ok_types, types = pcall(require, "openmw.types")

local chain_target_provider = {}

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

local function callMethod(value, key)
    local fn = readField(value, key)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, value)
    if ok then
        return result
    end
    return nil
end

local function scalarToken(value)
    if value == nil then
        return nil
    end
    local value_type = type(value)
    if value_type == "string" then
        return value ~= "" and value or nil
    elseif value_type == "number" or value_type == "boolean" then
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
    return scalarToken(readField(value, "id"))
        or scalarToken(readField(value, "recordId"))
        or scalarToken(readField(value, "refId"))
        or scalarToken(readField(value, "name"))
        or scalarToken(callMethod(value, "getFormId"))
        or tostring(value)
end

local function objectIdentityToken(value)
    if value == nil then
        return nil
    end
    local value_type = type(value)
    if value_type ~= "table" then
        return scalarToken(value) or tostring(value)
    end
    local wrapped = readField(value, "object")
    if wrapped ~= nil then
        local wrapped_token = objectIdentityToken(wrapped)
        if wrapped_token then
            return wrapped_token
        end
    end
    return scalarToken(readField(value, "id"))
        or scalarToken(readField(value, "recordId"))
        or scalarToken(readField(value, "refId"))
        or scalarToken(readField(value, "name"))
        or scalarToken(callMethod(value, "getFormId"))
        or tostring(value)
end

local function cellToken(value)
    local direct = scalarToken(value)
    if direct then
        return direct
    end
    if value == nil then
        return nil
    end
    return scalarToken(readField(value, "id"))
        or scalarToken(readField(value, "name"))
        or tostring(value)
end

local function positionOf(value)
    if value == nil then
        return nil
    end
    local position = readField(value, "position") or readField(value, "pos")
    if position ~= nil then
        return position
    end
    if readField(value, "x") ~= nil and readField(value, "y") ~= nil then
        return value
    end
    return nil
end

local function component(position, key)
    return tonumber(readField(position, key)) or 0
end

local function clonePosition(position)
    if position == nil then
        return nil
    end
    return {
        x = component(position, "x"),
        y = component(position, "y"),
        z = component(position, "z"),
    }
end

local function elevatedPosition(position, height)
    if position == nil then
        return nil
    end
    return {
        x = component(position, "x"),
        y = component(position, "y"),
        z = component(position, "z") + (tonumber(height) or 0),
    }
end

local function distanceBetween(a, b)
    local ax = component(a, "x")
    local ay = component(a, "y")
    local az = component(a, "z")
    local bx = component(b, "x")
    local by = component(b, "y")
    local bz = component(b, "z")
    local dx = ax - bx
    local dy = ay - by
    local dz = az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function actorHealth(object)
    if not ok_types or not types or not types.Actor or not types.Actor.stats
        or not types.Actor.stats.dynamic or type(types.Actor.stats.dynamic.health) ~= "function" then
        return nil
    end
    local ok, health = pcall(types.Actor.stats.dynamic.health, object)
    if ok then
        return health
    end
    return nil
end

local function actorAlive(object)
    local health = actorHealth(object)
    if health == nil then
        return true
    end
    local current = tonumber(health.current)
    if current == nil then
        return true
    end
    return current > 0
end

local function objectValid(object)
    local valid = readField(object, "isValid")
    if type(valid) == "boolean" then
        return valid
    end
    local method_valid = callMethod(object, "isValid")
    if type(method_valid) == "boolean" then
        return method_valid
    end
    return object ~= nil
end

local function supportedStatus()
    if not ok_world or world == nil then
        return false, "openmw_world_unavailable"
    end
    local active_actors = readField(world, "activeActors")
    if active_actors == nil then
        return false, "world_active_actors_unavailable"
    end
    return true, nil, active_actors
end

function chain_target_provider.isSupported()
    local supported, reason = supportedStatus()
    return {
        ok = supported,
        supported = supported,
        provider = supported and "real" or "unavailable",
        rejection_reason = reason,
        unsupported_reason = reason,
    }
end

function chain_target_provider.makeCandidate(object, hit_context, opts)
    local options = opts or {}
    if object == nil then
        runtime_stats.inc("chain_provider_object_invalid")
        return nil
    end
    local base_position = positionOf(object)
    if base_position == nil then
        return nil
    end
    local origin = positionOf(hit_context and (hit_context.current_hit_target or hit_context.source_target))
        or positionOf(hit_context and (hit_context.current_hit_position or hit_context.hit_position))
    local distance = nil
    local vertical_delta = nil
    if origin ~= nil then
        distance = distanceBetween(origin, base_position)
        local vertical_position = options.vertical_reference == "aim"
            and elevatedPosition(base_position, limits.CHAIN_AIM_HEIGHT)
            or base_position
        vertical_delta = math.abs(component(origin, "z") - component(vertical_position, "z"))
    end
    local radius = tonumber(options.radius or options.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS) or limits.MAX_CHAIN_SCAN_RADIUS
    if distance ~= nil and distance > radius then
        return nil, "candidate_out_of_radius"
    end
    local max_vertical_delta = tonumber(options.max_vertical_delta or limits.MAX_CHAIN_VERTICAL_DELTA)
    if vertical_delta ~= nil and max_vertical_delta ~= nil and vertical_delta > max_vertical_delta then
        return nil, "candidate_vertical_delta"
    end

    local id = objectToken(object)
    return {
        id = id,
        object = object,
        position = elevatedPosition(base_position, limits.CHAIN_AIM_HEIGHT),
        base_position = clonePosition(base_position),
        cell = readField(object, "cell"),
        is_actor = true,
        is_alive = actorAlive(object),
        is_valid = objectValid(object),
        distance = distance,
        distance_override = distance,
        vertical_delta = vertical_delta,
        can_be_targeted = true,
    }
end

function chain_target_provider.collectCandidates(hit_context, opts)
    local options = opts or {}
    runtime_stats.inc("chain_provider_attempts")
    runtime_stats.inc("chain_provider_real_attempts")

    local radius = tonumber(options.radius or options.scan_radius or limits.MAX_CHAIN_SCAN_RADIUS) or limits.MAX_CHAIN_SCAN_RADIUS
    local radius_cap = tonumber(options.max_radius or limits.MAX_CHAIN_SCAN_RADIUS) or limits.MAX_CHAIN_SCAN_RADIUS
    if radius > radius_cap then
        radius = radius_cap
    end
    local candidate_cap = math.floor(tonumber(options.candidate_cap or options.max_candidates or limits.MAX_CHAIN_SCAN_CANDIDATES) or 16)
    if candidate_cap < 1 then
        candidate_cap = 1
    end
    local actor_scan_cap = math.floor(tonumber(options.actor_scan_cap
        or options.scan_actor_cap
        or options.max_scan_actors
        or options.max_chain_scan_actors
        or limits.MAX_CHAIN_SCAN_ACTORS
        or limits.MAX_CHAIN_SCAN_CANDIDATES) or 16)
    if actor_scan_cap < candidate_cap then
        actor_scan_cap = candidate_cap
    end
    local result = {
        ok = false,
        provider = "real",
        candidate_count = 0,
        candidates = {},
        rejection_reason = nil,
        unsupported_reason = nil,
        radius = radius,
        candidate_cap = candidate_cap,
        actor_scan_cap = actor_scan_cap,
        scan_actor_cap = actor_scan_cap,
        inspected_count = 0,
        current_excluded = 0,
        caster_excluded = 0,
        actor_scan_cap_hit = false,
        candidate_cap_hit = false,
        cell_id = cellToken(hit_context and (hit_context.current_cell or hit_context.hit_cell)),
    }

    local active_actors = options.active_actors or options.test_active_actors
    local supported = true
    local unsupported = nil
    if active_actors == nil then
        supported, unsupported, active_actors = supportedStatus()
    end
    if not supported then
        result.provider = "unavailable"
        result.rejection_reason = "chain_target_provider_unavailable"
        result.unsupported_reason = unsupported
        runtime_stats.inc("chain_provider_real_unavailable")
        log.info(string.format(
            "SPELLFORGE_CHAIN_PROVIDER_REAL_UNAVAILABLE recipe_id=%s cast_id=%s chain_id=%s hop_index=%s rejection_reason=%s unsupported_reason=%s",
            tostring(hit_context and hit_context.recipe_id or nil),
            tostring(hit_context and hit_context.cast_id or nil),
            tostring(hit_context and hit_context.chain_id or nil),
            tostring(hit_context and hit_context.hop_index or nil),
            tostring(result.rejection_reason),
            tostring(unsupported)
        ))
        return result
    end
    if type(hit_context) ~= "table" then
        result.rejection_reason = "invalid_chain_hit_context"
        runtime_stats.inc("chain_provider_real_failed")
        runtime_stats.inc("chain_provider_context_missing")
        return result
    end
    if positionOf(hit_context.current_hit_position or hit_context.hit_position)
        == nil and positionOf(hit_context.current_hit_target or hit_context.source_target) == nil then
        result.rejection_reason = "missing_chain_hit_position"
        runtime_stats.inc("chain_provider_real_failed")
        runtime_stats.inc("chain_provider_position_missing")
        return result
    end
    if result.cell_id == nil then
        runtime_stats.inc("chain_provider_cell_missing")
    end

    runtime_stats.inc("chain_provider_radius_applied")
    local candidates = {}
    local inspected = 0
    local vertical_rejected = 0
    local current_excluded = 0
    local caster_excluded = 0
    local actor_scan_cap_hit = false
    local candidate_cap_hit = false
    local current_target = hit_context.current_hit_target or hit_context.source_target
    local current_token = objectIdentityToken(current_target)
    local caster_token = objectIdentityToken(hit_context.caster)
    local iterated, iterate_err = pcall(function()
        for _, object in ipairs(active_actors) do
            if inspected >= actor_scan_cap then
                actor_scan_cap_hit = true
                break
            end
            inspected = inspected + 1
            local identity_token = objectIdentityToken(object)
            if hit_context.exclude_caster ~= false and caster_token ~= nil and identity_token == caster_token then
                caster_excluded = caster_excluded + 1
                runtime_stats.inc("chain_provider_caster_excluded")
            elseif hit_context.exclude_current_hit_target ~= false
                and current_token ~= nil
                and identity_token == current_token then
                current_excluded = current_excluded + 1
                runtime_stats.inc("chain_provider_current_target_excluded")
            else
                local candidate, rejection_reason = chain_target_provider.makeCandidate(object, hit_context, {
                    radius = radius,
                    max_vertical_delta = options.max_vertical_delta or limits.MAX_CHAIN_VERTICAL_DELTA,
                    vertical_reference = options.vertical_reference,
                })
                if candidate then
                    candidates[#candidates + 1] = candidate
                elseif rejection_reason == "candidate_vertical_delta" then
                    vertical_rejected = vertical_rejected + 1
                    runtime_stats.inc("chain_provider_vertical_reject")
                end
            end
        end
    end)
    if not iterated then
        result.provider = "unavailable"
        result.rejection_reason = "chain_target_provider_unavailable"
        result.unsupported_reason = tostring(iterate_err)
        runtime_stats.inc("chain_provider_real_unavailable")
        runtime_stats.inc("chain_provider_real_failed")
        log.info(string.format(
            "SPELLFORGE_CHAIN_PROVIDER_REAL_REJECTED recipe_id=%s cast_id=%s chain_id=%s hop_index=%s rejection_reason=%s",
            tostring(hit_context.recipe_id),
            tostring(hit_context.cast_id),
            tostring(hit_context.chain_id),
            tostring(hit_context.hop_index),
            tostring(result.rejection_reason)
        ))
        return result
    end

    table.sort(candidates, function(a, b)
        local ad = tonumber(a.distance_override) or math.huge
        local bd = tonumber(b.distance_override) or math.huge
        if ad ~= bd then
            return ad < bd
        end
        return tostring(a.id) < tostring(b.id)
    end)
    while #candidates > candidate_cap do
        table.remove(candidates)
        candidate_cap_hit = true
    end

    result.ok = true
    result.candidate_count = #candidates
    result.candidates = candidates
    result.vertical_rejected = vertical_rejected
    result.max_vertical_delta = options.max_vertical_delta or limits.MAX_CHAIN_VERTICAL_DELTA
    result.inspected_count = inspected
    result.current_excluded = current_excluded
    result.caster_excluded = caster_excluded
    result.actor_scan_cap_hit = actor_scan_cap_hit
    result.candidate_cap_hit = candidate_cap_hit
    runtime_stats.inc("chain_provider_candidates_seen", inspected)
    runtime_stats.inc("chain_provider_candidates_returned", result.candidate_count)
    if actor_scan_cap_hit then
        runtime_stats.inc("chain_provider_actor_scan_cap_hit")
    end
    if candidate_cap_hit then
        runtime_stats.inc("chain_provider_candidate_cap_hit")
    end
    runtime_stats.inc("chain_provider_real_ok")
    log.info(string.format(
        "SPELLFORGE_CHAIN_PROVIDER_REAL_OK recipe_id=%s cast_id=%s chain_id=%s hop_index=%s candidate_count=%s radius=%s candidate_cap=%s actor_scan_cap=%s inspected_count=%s current_excluded=%s caster_excluded=%s actor_scan_cap_hit=%s candidate_cap_hit=%s vertical_rejected=%s max_vertical_delta=%s aim_height=%s",
        tostring(hit_context.recipe_id),
        tostring(hit_context.cast_id),
        tostring(hit_context.chain_id),
        tostring(hit_context.hop_index),
        tostring(result.candidate_count),
        tostring(radius),
        tostring(candidate_cap),
        tostring(actor_scan_cap),
        tostring(inspected),
        tostring(current_excluded),
        tostring(caster_excluded),
        tostring(actor_scan_cap_hit),
        tostring(candidate_cap_hit),
        tostring(vertical_rejected),
        tostring(result.max_vertical_delta),
        tostring(limits.CHAIN_AIM_HEIGHT)
    ))
    return result
end

return chain_target_provider
