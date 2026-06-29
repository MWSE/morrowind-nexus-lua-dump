-- interactions/sitting/standExit.lua
---@omw-context none
-- Floor-side standing candidates for releasing actors from seated poses.

local M = {}

local function vector(util, x, y, z)
    if util and util.vector3 then return util.vector3(x, y, z) end
    return { x = x, y = y, z = z }
end

local function hasPosition(pos)
    return pos and pos.x ~= nil and pos.y ~= nil and pos.z ~= nil
end

local function coord(pos, key)
    if not pos then return 0 end
    return tonumber(pos[key]) or 0
end

local function lowerFloorZ(data)
    local final = data and (data.finalPosition or data.position)
    local finalZ = final and tonumber(final.z) or nil
    local z = nil
    for _, pos in ipairs({
        data and data.preInteractionPos,
        data and data.npcStandingPos,
        data and data.approachPos,
        data and data.exitPosition,
    }) do
        if hasPosition(pos) then
            local value = tonumber(pos.z)
            if value
                and (not finalZ or (value >= finalZ - 140 and value <= finalZ + 260))
                and (not z or value < z) then
                z = value
            end
        end
    end
    if z then return z end
    return final and tonumber(final.z) or nil
end

local function normalized(dx, dy)
    dx = tonumber(dx) or 0
    dy = tonumber(dy) or 0
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0.001 then return nil, nil end
    return dx / len, dy / len
end

local function add(out, seen, util, pos, zOverride)
    if not hasPosition(pos) then return end
    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    local z = tonumber(zOverride ~= nil and zOverride or pos.z)
    if not (x and y and z) then return end
    local key = tostring(math.floor(x + 0.5)) .. ":" .. tostring(math.floor(y + 0.5)) .. ":" .. tostring(math.floor(z + 0.5))
    if seen[key] then return end
    seen[key] = true
    out[#out + 1] = vector(util, x, y, z)
end

local function addCandidate(out, seen, util, pos, label, zOverride)
    if not hasPosition(pos) then return end
    local tmp = {}
    add(tmp, seen, util, pos, zOverride)
    if tmp[1] then
        out[#out + 1] = {
            position = tmp[1],
            label = label,
        }
    end
end

local function focusPosition(data)
    if data and hasPosition(data.facingObjectPosition) then return data.facingObjectPosition end
    if data and data.object and hasPosition(data.object.position) then return data.object.position end
    return nil
end

function M.primary(data, util)
    local final = data and (data.finalPosition or data.position)
    if not hasPosition(final) then return nil end
    local z = lowerFloorZ(data) or final.z
    local dx, dy
    local focus = focusPosition(data)
    if focus then
        dx = (tonumber(final.x) or 0) - (tonumber(focus.x) or 0)
        dy = (tonumber(final.y) or 0) - (tonumber(focus.y) or 0)
    elseif data and data.facingDirection then
        dx = tonumber(data.facingDirection.x) or 0
        dy = tonumber(data.facingDirection.y) or 0
    end
    dx, dy = normalized(dx, dy)
    if not dx then
        if hasPosition(data and data.approachPos) then
            return vector(util, data.approachPos.x, data.approachPos.y, z)
        end
        if hasPosition(data and data.npcStandingPos) then
            return vector(util, data.npcStandingPos.x, data.npcStandingPos.y, z)
        end
        return nil
    end
    return vector(util, (tonumber(final.x) or 0) + dx * 96, (tonumber(final.y) or 0) + dy * 96, z)
end

local function actorFacingCandidate(data, util, distance)
    local final = data and (data.finalPosition or data.position)
    if not (hasPosition(final) and data and data.facingDirection) then return nil end
    local dx, dy = normalized(data.facingDirection.x, data.facingDirection.y)
    if not dx then return nil end
    local z = lowerFloorZ(data) or final.z
    return vector(util, coord(final, "x") + dx * (distance or 96), coord(final, "y") + dy * (distance or 96), z)
end

function M.detailedCandidates(data, util)
    local out = {}
    local seen = {}
    local final = data and (data.finalPosition or data.position)
    local z = lowerFloorZ(data)
    local primary = M.primary(data, util)
    local actorFacing = actorFacingCandidate(data, util, 96)
    local category = tostring(data and (data.seatCategory or data.releaseSafetyGateFurnitureType) or ""):lower()
    local isBench = category:find("bench", 1, true) ~= nil

    if isBench then
        addCandidate(out, seen, util, actorFacing, "bench_actor_facing", nil)
        addCandidate(out, seen, util, primary, focusPosition(data) and "bench_focus_open_side" or "bench_actor_facing_primary", nil)
        addCandidate(out, seen, util, data and data.npcStandingPos, "bench_stored_standing", z)
        addCandidate(out, seen, util, data and data.approachPos, "bench_approach", z)
    else
        addCandidate(out, seen, util, data and data.npcStandingPos, "stored_standing", z)
        addCandidate(out, seen, util, data and data.approachPos, "approach", z)
        addCandidate(out, seen, util, primary, focusPosition(data) and "focus_open_side" or "actor_facing", nil)
    end
    if hasPosition(final) and hasPosition(primary) then
        local primaryX = coord(primary, "x")
        local primaryY = coord(primary, "y")
        local finalX = coord(final, "x")
        local finalY = coord(final, "y")
        local dx, dy = normalized(primaryX - finalX, primaryY - finalY)
        if dx then
            local farLabel = "open_side_far"
            if isBench then
                farLabel = focusPosition(data) and "bench_focus_open_side_far" or "bench_actor_facing_far"
            end
            addCandidate(out, seen, util, vector(util, finalX + dx * 132, finalY + dy * 132, z or final.z), farLabel, nil)
        end
    end
    addCandidate(out, seen, util, data and data.exitPosition, "stored_exit", z)
    return out
end

local function log(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local FORCED_REASON_PATTERNS = {
    "cleanup",
    "clear",
    "debug",
    "developer",
    "handoff",
    "external",
    "control",
    "script",
    "follow",
    "escort",
    "combat",
    "pursue",
    "travel",
    "package",
    "sleep_priority",
    "cell_change",
    "cell_leave",
    "unload",
    "invalid",
    "dead",
    "died",
    "hit",
    "dialogue",
    "activated_by_player",
    "settings_disabled",
    "cancel",
    "restore",
    "reassign",
    "retarget",
    "manual",
    "fill",
    "test_npc",
    "calibration",
    "force",
    "forced",
}

local AMBIENT_REASONS = {
    sitting_lifecycle_change_seat = true,
    sitting_lifecycle_return_origin = true,
    off_hours_service_window_ended = true,
}

function M.isForcedRelease(reason, data)
    if data and (data.forceStandExitFallback == true or data.cleanupRelease == true or data.handoffRelease == true) then
        return true
    end
    local text = tostring(reason or ""):lower()
    if text == "" then return false end
    if AMBIENT_REASONS[text] then return false end
    for _, pattern in ipairs(FORCED_REASON_PATTERNS) do
        if text:find(pattern, 1, true) then return true end
    end
    return false
end

function M.assignmentMayUseForcedAcceptance(data)
    if not data then return false end
    if data.calibrationFill == true
        or data.explicitFillOverride == true
        or data.calibrationTestNpc == true
        or data.calibrationFillSource ~= nil
        or data.calibrationFillLabel ~= nil
        or data.calibrationFillSessionId ~= nil then
        return data.calibrationTestNpc == true
            or data.calibrationFillSource == "generated"
    end
    return data.manualAssignOverrideTesting == true
        or data.manualAssignOverrideApplied == true
        or data.calibrationAction == true
end

function M.acceptedExitPosition(data, util, ev)
    local normal = ev and ev.sittingStandExitPositions
    if normal and normal[1] then return normal[1] end
    local forced = ev and ev.sittingForcedStandExitPositions
    if forced and forced[1] then return forced[1] end
    return M.primary(data, util) or (ev and ev.approachPos) or (data and data.approachPos)
end

function M.fallbackLogName(label)
    local text = tostring(label or "")
    if text == "same_cell_pre_interaction_origin" or text == "same_cell_approach" then
        return "stand_exit_forced_fallback_origin"
    end
    if text:find("nearest_safe_furniture", 1, true) then
        return "stand_exit_forced_fallback_near_furniture"
    end
    if text:find("nearest_safe_actor", 1, true) then
        return "stand_exit_forced_fallback_near_actor"
    end
    if text == "emergency_same_cell_origin" then
        return "stand_exit_emergency_origin"
    end
    return nil
end

local function horizontal(a, b)
    if not (hasPosition(a) and hasPosition(b)) then return math.huge end
    local dx = coord(a, "x") - coord(b, "x")
    local dy = coord(a, "y") - coord(b, "y")
    return math.sqrt(dx * dx + dy * dy)
end

local function withZ(util, pos, dz)
    return vector(util, coord(pos, "x"), coord(pos, "y"), coord(pos, "z") + (tonumber(dz) or 0))
end

local function rejection(ctx, actor, label, reason, pos, extra)
    log(ctx, "sitting stand exit candidate rejected", actor, "label", tostring(label), "reason", tostring(reason), "pos", tostring(pos), "extra", tostring(extra))
    return false, reason
end

local function accept(ctx, actor, label, pos, sourcePos, navReason, navDelta, tier)
    log(ctx, "sitting stand exit candidate selected", actor, "label", tostring(label), "pos", tostring(pos), "source", tostring(sourcePos), "nav", tostring(navReason), "navDelta", tostring(navDelta))
    return {
        position = pos,
        label = label,
        tier = tier or "normal",
        navReason = navReason,
        navDelta = navDelta,
    }
end

local function validateCandidate(data, util, ctx, candidate, label, tier)
    local actor = ctx and ctx.actorLabel or "<npc>"
    if not hasPosition(candidate) then return rejection(ctx, actor, label, "missing_position", candidate) end

    local final = data and (data.finalPosition or data.position)
    local floorZ = lowerFloorZ(data)
    if floorZ and coord(candidate, "z") > floorZ + 72 then
        return rejection(ctx, actor, label, "above_practical_floor", candidate, floorZ)
    end
    if final and horizontal(candidate, final) < 42 then
        return rejection(ctx, actor, label, "too_close_to_seated_pose", candidate)
    end

    local navPos, navReason, navDelta = candidate, "unavailable", 0
    if ctx and ctx.nearestWalkNavmeshPosition then
        navPos, navReason, navDelta = ctx.nearestWalkNavmeshPosition(candidate)
        if not navPos then
            return rejection(ctx, actor, label, navReason or "no_nearest_navmesh", candidate, navDelta)
        end
        if navDelta and navDelta > (ctx.maxNavSnap or 145) then
            return rejection(ctx, actor, label, "navmesh_snap_too_far", candidate, navDelta)
        end
    end

    if floorZ and coord(navPos, "z") > floorZ + 72 then
        return rejection(ctx, actor, label, "navmesh_above_practical_floor", navPos, floorZ)
    end
    if floorZ and coord(navPos, "z") < floorZ - 220 then
        return rejection(ctx, actor, label, "navmesh_void_drop", navPos, floorZ)
    end

    if ctx and ctx.floorHitReason then
        local floorOk, floorReason, floorExtra = ctx.floorHitReason(navPos, floorZ)
        if floorOk ~= true then
            return rejection(ctx, actor, label, floorReason or "floor_probe_failed", navPos, floorExtra)
        end
    end

    if final and ctx and ctx.rayBlockedBetween then
        local lowBlocked = ctx.rayBlockedBetween(withZ(util, final, 64), withZ(util, navPos, 64), 34)
        local highBlocked = ctx.rayBlockedBetween(withZ(util, final, 124), withZ(util, navPos, 124), 44)
        if lowBlocked and highBlocked then
            return rejection(ctx, actor, label, "wall_between_seat_and_exit", navPos)
        end
    end

    return true, accept(ctx, actor, label, navPos, candidate, navReason, navDelta, tier)
end

local function radialFallbacks(data, util, out, center, labelPrefix)
    if not hasPosition(center) then return end
    local z = lowerFloorZ(data) or center.z
    local dirs = {
        data and data.facingDirection,
        { x = 1, y = 0 },
        { x = -1, y = 0 },
        { x = 0, y = 1 },
        { x = 0, y = -1 },
        { x = 0.707, y = 0.707 },
        { x = -0.707, y = 0.707 },
        { x = 0.707, y = -0.707 },
        { x = -0.707, y = -0.707 },
    }
    for _, dist in ipairs({ 80, 120, 168, 220 }) do
        for _, dir in ipairs(dirs) do
            local dx, dy = normalized(dir and dir.x, dir and dir.y)
            if dx then
                out[#out + 1] = {
                    position = vector(util, coord(center, "x") + dx * dist, coord(center, "y") + dy * dist, z),
                    label = tostring(labelPrefix or "nearest_safe_radial") .. "_" .. tostring(dist),
                    tier = labelPrefix or "fallback",
                }
            end
        end
    end
end

local function smallExitPads(data, util, out, center, labelPrefix)
    if not hasPosition(center) then return end
    local z = lowerFloorZ(data) or center.z
    local final = data and (data.finalPosition or data.position)
    local primary = M.primary(data, util)
    local dirs = {}

    local function addDir(dir, name)
        local dx, dy = normalized(dir and dir.x, dir and dir.y)
        if dx then
            dirs[#dirs + 1] = { x = dx, y = dy, name = name }
        end
    end

    local facingDx, facingDy = normalized(data and data.facingDirection and data.facingDirection.x, data and data.facingDirection and data.facingDirection.y)
    if focusPosition(data) and facingDx then
        addDir({ x = -facingDy, y = facingDx }, "side_left")
        addDir({ x = facingDy, y = -facingDx }, "side_right")
        addDir({ x = -facingDx, y = -facingDy }, "behind")
    end
    if hasPosition(primary) and hasPosition(final) then
        addDir({
            x = coord(primary, "x") - coord(final, "x"),
            y = coord(primary, "y") - coord(final, "y"),
        }, "primary")
    end
    addDir(data and data.facingDirection, "facing")
    addDir({ x = 1, y = 0 }, "east")
    addDir({ x = -1, y = 0 }, "west")
    addDir({ x = 0, y = 1 }, "north")
    addDir({ x = 0, y = -1 }, "south")

    for _, dist in ipairs({ 64, 96, 128 }) do
        for _, dir in ipairs(dirs) do
            out[#out + 1] = {
                position = vector(util, coord(center, "x") + dir.x * dist, coord(center, "y") + dir.y * dist, z),
                label = tostring(labelPrefix or "nearby_exit_pad") .. "_" .. tostring(dir.name or "dir") .. "_" .. tostring(dist),
                tier = "nearby_exit_pad",
            }
        end
    end
end

local function shouldPreferSmallExitPads(data)
    local category = tostring(data and (data.seatCategory or data.releaseSafetyGateFurnitureType) or ""):lower()
    return focusPosition(data) ~= nil
        and (category:find("backed", 1, true) ~= nil or category:find("chair", 1, true) ~= nil)
end

local function addFallbackCandidates(data, util, candidates, opts)
    if opts and opts.allowNearbyPads == true and not (opts.preferNearbyPads == true and shouldPreferSmallExitPads(data)) then
        smallExitPads(data, util, candidates, data and data.finalPosition or data and data.position, "nearby_exit_pad")
    end
    if opts and opts.allowNearbySearch == true then
        radialFallbacks(data, util, candidates, data and data.object and data.object.position or data and data.finalPosition or data and data.position, "nearest_safe_furniture")
    end
    if not (opts and opts.forced == true) then return end
    if data and hasPosition(data.approachPos) then
        candidates[#candidates + 1] = {
            position = data.approachPos,
            label = "same_cell_approach",
            tier = "forced_origin",
        }
    end
    if data and hasPosition(data.preInteractionPos) then
        candidates[#candidates + 1] = {
            position = data.preInteractionPos,
            label = "same_cell_pre_interaction_origin",
            tier = "forced_origin",
        }
    end
    radialFallbacks(data, util, candidates, data and data.object and data.object.position or data and data.finalPosition or data and data.position, "nearest_safe_furniture")
    radialFallbacks(data, util, candidates, data and data.actorPosition, "nearest_safe_actor")
end

function M.validatedCandidates(data, util, ctx, opts)
    opts = opts or {}
    local validated = {}
    local entries = {}
    local rejected = 0
    local raw = M.detailedCandidates(data, util)
    local candidates = {}
    if opts.allowNearbyPads == true and opts.preferNearbyPads == true and shouldPreferSmallExitPads(data) then
        smallExitPads(data, util, candidates, data and data.finalPosition or data and data.position, "nearby_exit_pad")
    end
    for _, item in ipairs(raw) do
        candidates[#candidates + 1] = {
            position = item.position,
            label = item.label or "candidate",
            tier = "normal",
        }
    end

    addFallbackCandidates(data, util, candidates, opts)

    for _, item in ipairs(candidates) do
        local ok, result = validateCandidate(data, util, ctx, item.position, item.label, item.tier)
        if ok and result and result.position then
            validated[#validated + 1] = result.position
            entries[#entries + 1] = result
        else
            rejected = rejected + 1
        end
    end

    if #validated == 0 and opts.forced == true and opts.allowEmergencyOrigin == true and data and hasPosition(data.preInteractionPos) then
        validated[#validated + 1] = data.preInteractionPos
        entries[#entries + 1] = {
            position = data.preInteractionPos,
            label = "emergency_same_cell_origin",
            tier = "emergency_origin",
        }
        if opts.logFallbackSelection ~= false then
            log(ctx, "stand_exit_no_safe_candidate", ctx and ctx.actorLabel or "<npc>", "rejected", tostring(rejected), "object", tostring(data and data.objectId), "slot", tostring(data and data.slotName), "forced", "true")
        end
    end

    if #validated == 0 then
        log(ctx, "stand_exit_no_safe_candidate", ctx and ctx.actorLabel or "<npc>", "rejected", tostring(rejected), "object", tostring(data and data.objectId), "slot", tostring(data and data.slotName), "forced", tostring(opts.forced == true))
        if opts.forced == true then
            log(ctx, "stand_exit_forced_release_failed", ctx and ctx.actorLabel or "<npc>", "reason", tostring(opts.reason), "object", tostring(data and data.objectId), "slot", tostring(data and data.slotName))
        else
            log(ctx, "stand_exit_retry_later", ctx and ctx.actorLabel or "<npc>", "reason", tostring(opts.reason), "object", tostring(data and data.objectId), "slot", tostring(data and data.slotName))
        end
    elseif opts.forced == true and opts.logFallbackSelection ~= false then
        local fallbackLog = M.fallbackLogName(entries[1] and entries[1].label)
        if fallbackLog then
            log(ctx, fallbackLog, ctx and ctx.actorLabel or "<npc>", "reason", tostring(opts.reason), "label", tostring(entries[1].label), "pos", tostring(entries[1].position), "object", tostring(data and data.objectId), "slot", tostring(data and data.slotName))
        end
    end
    return validated, {
        entries = entries,
        firstLabel = entries[1] and entries[1].label or nil,
        firstTier = entries[1] and entries[1].tier or nil,
        firstFallbackLog = entries[1] and M.fallbackLogName(entries[1].label) or nil,
        selected = #validated,
        rejected = rejected,
        raw = #candidates,
    }
end

return M
