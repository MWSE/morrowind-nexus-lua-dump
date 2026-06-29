-- interactions/sleeping/routePlanner.lua
---@omw-context local
-- Local-script sleep approach/exit planning helpers split out from
-- interactionSeeker.lua to reduce file size and top-level local pressure.
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local finalSafety = require('scripts/sitDownPlease/interactions/sleeping/finalSafety')
local clutterItems = require('scripts/sitDownPlease/world/clutterItems')

local module = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function objectText(obj)
    if not obj then return "" end
    return table.concat({
        lower(obj["recordId"]),
        lower(obj["name"]),
        lower(obj["model"]),
    }, " ")
end

local function objectLooksLikeSoftPartition(obj)
    local text = objectText(obj)
    return text:find("screen", 1, true) ~= nil
        or text:find("curtain", 1, true) ~= nil
        or text:find("tapestry", 1, true) ~= nil
        or text:find("banner", 1, true) ~= nil
        or text:find("fabric", 1, true) ~= nil
        or text:find("cloth", 1, true) ~= nil
        or text:find("roomt", 1, true) ~= nil
        or text:find("guar", 1, true) ~= nil
        or text:find("hide", 1, true) ~= nil
        or text:find("partition", 1, true) ~= nil
        or text:find("divider", 1, true) ~= nil
        or text:find("hanging", 1, true) ~= nil
end

local function isBunkProfile(slot, profile)
    local text = table.concat({
        lower(slot and slot.name),
        lower(profile and profile.profileId),
        lower(profile and profile.bedType),
        lower(profile and profile.type),
    }, " ")
    return text:find("bunk", 1, true) ~= nil
        or text:find("sleep_top", 1, true) ~= nil
        or text:find("sleep_bottom", 1, true) ~= nil
end

function module.collectApproachOffsets(slot, profile)
    local offsets = {}
    local seen = {}
    local bunkProfile = isBunkProfile(slot, profile)

    local function add(offset)
        if not offset then return end
        local key = tostring(offset.name or "") .. "|" .. tostring(offset.x or 0) .. "|" .. tostring(offset.y or 0) .. "|" .. tostring(offset.z or 0)
        if seen[key] then return end
        seen[key] = true
        table.insert(offsets, offset)
    end

    if bunkProfile then
        -- Bunks often sit against posts/walls and their top surface can catch
        -- floor probes. Try tighter aisle-side points before declaring the slot
        -- unreachable from the generic bed ring.
        add({ name = "bunk_near_left", x = -92, y = 0, z = 0 })
        add({ name = "bunk_near_right", x = 92, y = 0, z = 0 })
        add({ name = "bunk_near_foot", x = 0, y = -92, z = 0 })
        add({ name = "bunk_near_head", x = 0, y = 92, z = 0 })
        add({ name = "bunk_foot_left", x = -82, y = -82, z = 0 })
        add({ name = "bunk_foot_right", x = 82, y = -82, z = 0 })
        add({ name = "bunk_head_left", x = -82, y = 82, z = 0 })
        add({ name = "bunk_head_right", x = 82, y = 82, z = 0 })
    end

    add(slot and slot.approachOffset)

    if slot and slot.approachOffsets then
        for _, offset in ipairs(slot.approachOffsets) do add(offset) end
    end

    if profile and profile.approachOffsets then
        for _, offset in ipairs(profile.approachOffsets) do add(offset) end
    end

    if #offsets == 0 then
        add({ name = "foot", x = 0, y = -140, z = 0 })
        add({ name = "head", x = 0, y = 140, z = 0 })
        add({ name = "left", x = -140, y = 0, z = 0 })
        add({ name = "right", x = 140, y = 0, z = 0 })
    end

    return offsets
end

function module.isHardApproachReject(reason)
    reason = tostring(reason or "")
    return reason == "blocked_by_wall"
        or reason == "route_too_indirect"
        or reason == "no_path_to_bed"
        or reason == "approach_navmesh_behind_collision"
        or reason == "public_bed_requires_door_assist"
        or reason == "locked_route_door"
        or reason == "blocked_route_door"
        or reason == "trapped_route_door"
        or reason == "wrong_floor_or_unreachable"
end

function module.approachPathTooIndirect(ctx, route)
    route = route or {}
    local pathLength = tonumber(route.pathLength)
    if not (pathLength and route.actorLineBlocked == true) then return false, nil, nil end

    local straightDistance = tonumber(route.straightDistance) or math.huge
    local maxIndirectRoute = math.max(750, (straightDistance * 3.0) + 240)
    if pathLength <= maxIndirectRoute then return false, nil, nil end

    if ctx and ctx.debug == true and ctx.debugLog then
        local obj = ctx.currentObject and ctx.currentObject() or nil
        ctx.debugLog(
            ctx.logPrefix or "sleep_entry_rejected",
            "reason", "route_too_indirect",
            "object", tostring(obj and obj.recordId),
            "approach", tostring(route.approach),
            "navApproach", tostring(route.navApproach),
            "pathLength", tostring(pathLength),
            "straightDistance", tostring(straightDistance)
        )
    end

    return true, "route_too_indirect", {
        pathLength = pathLength,
        actorLineBlocked = route.actorLineBlocked == true,
        straightDistance = straightDistance,
    }
end

function module.initialMayBypassApproachRoute(data, profile, reason, details)
    if not (data and data.initialPlacement == true and profile and profile.externalProfile == true) then return false end
    if data.calibrationAction == true or data.fallback == true then return false end

    reason = tostring(reason or "")
    if reason == "locked_route_door" or reason == "blocked_route_door" or reason == "trapped_route_door" or reason == "public_bed_requires_door_assist" then return false end
    if details and details.sawLockedRouteDoorReject == true then return false end
    local routeDoorReason = tostring(details and details.routeDoorReason or "")
    if routeDoorReason:find("locked_route_door", 1, true)
        or routeDoorReason:find("blocked_route_door", 1, true)
        or routeDoorReason:find("trapped_route_door", 1, true) then
        return false
    end
    if details and (details.hardRouteReject == true or details.actorLineBlocked == true or details.routeTooIndirectNearBed == true) then return false end
    return reason == "approach_too_far_from_navmesh"
end

local function isLockedRouteReject(reason, details)
    local reasonText = tostring(reason or "")
    local detailText = tostring(details and details.routeDoorReason or "")
    return reasonText == "locked_route_door"
        or reasonText == "blocked_route_door"
        or reasonText:find("trapped_route_door", 1, true) ~= nil
        or detailText:find("locked_route_door", 1, true) ~= nil
        or detailText:find("blocked_route_door", 1, true) ~= nil
        or detailText:find("trapped_route_door", 1, true) ~= nil
end

local function overlyIndirectNearBedRoute(ctx, actorDist, finalDist, details)
    local pathLength = tonumber(details and details.pathLength)
    if not pathLength then return false end
    actorDist = tonumber(actorDist) or math.huge
    finalDist = tonumber(finalDist) or math.huge
    local obj = ctx and ctx.currentObject and ctx.currentObject() or nil
    local npc = ctx and ctx.selfObject and ctx.selfObject() or nil
    local objectDist = obj and npc and obj.position and npc.position and (obj.position - npc.position):length() or math.huge
    local nearDist = math.min(actorDist, objectDist)
    if nearDist > 700 or finalDist > 280 then return false end

    -- Open doors and pathgrid quirks can make a wall-separated bed look reachable
    -- even though the path goes out through a different room and back around.
    -- For nearby beds, that kind of long route is a room-boundary warning, not
    -- a valid ambient sleep target.
    local maxIndirectRoute = math.max(1150, nearDist * 3.0 + 260)
    return pathLength > maxIndirectRoute
end

function module.chooseApproach(ctx, data, slot, profile, finalPos)
    if data and data.approachPos then
        local reachable, reason, details = ctx.sleepApproachReachability(data.approachPos, finalPos, data, "sleep_entry_rejected")
        details = details or {}
        if not reachable and isLockedRouteReject(reason, details) then
            details.sawLockedRouteDoorReject = true
        end
        return (details and details.navPos) or data.approachPos, "assigned", reachable, reason, details
    end

    local hardRouteReject = false
    local sawLockedRouteDoorReject = false
    local bestReachable = nil
    local bestReachableScore = nil
    local bestRejected = nil
    local bestRejectedScore = nil

    for _, offset in ipairs(module.collectApproachOffsets(slot, profile)) do
        local pos = ctx.projectedObjectOffset(offset)
        local actorDist = (ctx.selfObject().position - pos):length()
        local finalDist = finalPos and (finalPos - pos):length() or 0
        local reachable, reason, details = ctx.sleepApproachReachability(pos, finalPos, data, nil)
        details = details or {}
        if not reachable and module.isHardApproachReject(reason) then
            hardRouteReject = true
        end
        if not reachable and isLockedRouteReject(reason, details) then
            sawLockedRouteDoorReject = true
        end
        local actorLineBlocked = details.actorLineBlocked == true or false
        local routeDist = details.pathLength or actorDist
        if reachable and overlyIndirectNearBedRoute(ctx, actorDist, finalDist, details) then
            reachable = false
            reason = "route_too_indirect"
            details.routeTooIndirectNearBed = true
            details.routeDist = routeDist
            details.actorDist = actorDist
            details.finalDist = finalDist
            local obj = ctx and ctx.currentObject and ctx.currentObject() or nil
            local npc = ctx and ctx.selfObject and ctx.selfObject() or nil
            details.objectDist = obj and npc and obj.position and npc.position and (obj.position - npc.position):length() or nil
            hardRouteReject = true
            if ctx and ctx.debugLog then
                local obj = ctx.currentObject and ctx.currentObject() or nil
                ctx.debugLog(
                    "sleep_entry_rejected",
                    "reason", "route_too_indirect",
                    "object", tostring(obj and obj.recordId),
                    "approach", tostring(pos),
                    "pathLength", tostring(routeDist),
                    "straightDistance", tostring(actorDist),
                    "objectDistance", tostring(details.objectDist),
                    "finalDistance", tostring(finalDist)
                )
            end
        end
        local score = routeDist + (finalDist * 0.15) + (actorLineBlocked and 800 or 0)
        details.actorLineBlocked = actorLineBlocked
        details.routeDist = routeDist
        local entry = { pos = (details and details.navPos) or pos, rawPos = pos, name = offset.name or "offset", reason = reason, details = details, score = score }
        if reachable then
            if not bestReachableScore or score < bestReachableScore then
                bestReachable = entry
                bestReachableScore = score
            end
        elseif not bestRejectedScore or score < bestRejectedScore then
            bestRejected = entry
            bestRejectedScore = score
        end
    end

    local currentObject = ctx.currentObject()
    if bestReachable then
        return bestReachable.pos, bestReachable.name, true, bestReachable.reason, bestReachable.details
    end

    if currentObject and currentObject.position and finalPos then
        local actorPos = ctx.selfObject().position
        local horizontalToBed = ctx.horizontalDistance3(actorPos, currentObject.position)
        local verticalToBed = math.abs((actorPos.z or 0) - (currentObject.position.z or 0))
        local horizontalToFinal = ctx.horizontalDistance3(actorPos, finalPos)
        local verticalToFinal = math.abs((actorPos.z or 0) - (finalPos.z or 0))
        local wallBlocked = ctx.rayBlockedBetween(actorPos + util.vector3(0, 0, 54), finalPos + util.vector3(0, 0, 54), 34)
        if not hardRouteReject and horizontalToBed <= 145 and horizontalToFinal <= 160 and verticalToBed <= 70 and verticalToFinal <= 95 and not wallBlocked then
            return actorPos, "direct_bedside", true, "direct_beside_bed_snap", { directSnap = true }
        end
    end

    if bestRejected then
        bestRejected.details = bestRejected.details or {}
        bestRejected.details.sawLockedRouteDoorReject = sawLockedRouteDoorReject == true
        bestRejected.details.hardRouteReject = hardRouteReject == true
        return bestRejected.pos, bestRejected.name, false, bestRejected.reason or "no_path_to_bed", bestRejected.details
    end

    return finalPos, "final", false, "no_path_to_bed", nil
end

function module.collectExitOffsets(slot, profile)
    local offsets = {}

    local function add(offset)
        if offset then table.insert(offsets, offset) end
    end

    add(slot and slot.exitOffset)

    if slot and slot.exitOffsets then
        for _, offset in ipairs(slot.exitOffsets) do add(offset) end
    end

    if profile and profile.exitOffsets then
        for _, offset in ipairs(profile.exitOffsets) do add(offset) end
    end

    if #offsets == 0 then
        for _, offset in ipairs(module.collectApproachOffsets(slot, profile)) do add(offset) end
    end

    return offsets
end

function module.hasExitPositions(exitPositions)
    return type(exitPositions) == "table" and exitPositions[1] ~= nil
end

function module.missingExitMayBeOverridden(data)
    return data and (
        data.manualAssignOverrideTesting == true
        or data.explicitFillOverride == true
        or data.calibrationFill == true
        or data.calibrationAction == true
    )
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end

local function projectedSleepExitOffset(ctx, offset, finalPos)
    local currentObject = ctx.currentObject()
    if offset and (offset.anchor == "sleep_root" or offset.anchor == "final" or offset.anchor == "sleep") and finalPos then
        local pos = finalPos
            + ctx.objectLocalHorizontalOffset(currentObject, offset)
            + util.vector3(0, 0, offset.z or 0)
        return ctx.projectToFloor(pos, 0)
    end
    return ctx.projectedObjectOffset(offset)
end

local function exitOffsetIsHeadOrFoot(offset)
    local name = string.lower(tostring(offset and offset.name or ""))
    return name:find("head", 1, true) ~= nil or name:find("foot", 1, true) ~= nil
end

local function sleepExitClearancePenalty(pos, finalPos, opts)
    if not pos or not finalPos then return 0, false, false end
    local dx = (pos.x or 0) - (finalPos.x or 0)
    local dy = (pos.y or 0) - (finalPos.y or 0)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len < 1 then return 400, false, false end

    local dir = util.vector3(dx / len, dy / len, 0)
    local penalty = 0
    local hardBlocked = false
    local blocked = false

    local outFrom = pos + util.vector3(0, 0, 72)
    local outTo = outFrom + (dir * 70)
    local outHit = nearby.castRay(outFrom, outTo, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
    if outHit.hit then
        penalty = penalty + 900
        blocked = true
        -- A bed pushed against a wall can have a perfectly valid floor exit where
        -- the outward probe immediately hits that wall.  Treat the outward hit as
        -- a score penalty unless the caller explicitly wants the old hard veto;
        -- the wall-separated and footprint checks below remain hard safety gates.
        if opts and opts.hardOutHit == true then hardBlocked = true end
    end

    if len > 55 then
        local from = finalPos + (dir * 55) + util.vector3(0, 0, 72)
        local to = pos + util.vector3(0, 0, 72)
        local crossHit = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
        if crossHit.hit then penalty = penalty + 450 end
    end

    return penalty, hardBlocked, blocked
end

local function bunkExitFootprintPenalty(pos, currentObject)
    if not (pos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return 0, false, "unavailable" end

    local supportOffsets = {
        util.vector3(0, 0, 0),
        util.vector3(42, 0, 0),
        util.vector3(-42, 0, 0),
        util.vector3(0, 42, 0),
        util.vector3(0, -42, 0),
        util.vector3(30, 30, 0),
        util.vector3(-30, 30, 0),
        util.vector3(30, -30, 0),
        util.vector3(-30, -30, 0),
    }
    local unsupported = 0
    local uneven = 0
    local centerUnsupported = false
    local centerUneven = false
    for _, offset in ipairs(supportOffsets) do
        local probe = pos + offset
        local hit = nearby.castRay(
            probe + util.vector3(0, 0, 48),
            probe - util.vector3(0, 0, 120),
            { collisionType = nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if not (hit and hit.hit and hit.hitPos) then
            unsupported = unsupported + 1
            if offset.x == 0 and offset.y == 0 then centerUnsupported = true end
        else
            local dz = math.abs((hit.hitPos.z or 0) - (pos.z or 0))
            if dz > 24 then
                uneven = uneven + 1
                if offset.x == 0 and offset.y == 0 then centerUneven = true end
            end
        end
    end

    local clearanceOffsets = {
        util.vector3(46, 0, 0),
        util.vector3(-46, 0, 0),
        util.vector3(0, 46, 0),
        util.vector3(0, -46, 0),
        util.vector3(34, 34, 0),
        util.vector3(-34, 34, 0),
        util.vector3(34, -34, 0),
        util.vector3(-34, -34, 0),
    }
    local blocked = 0
    local waist = pos + util.vector3(0, 0, 54)
    for _, offset in ipairs(clearanceOffsets) do
        -- `ignore` is not supported by OpenMW sphere casts. Use zero-radius rays
        -- here so the current bunk's own rails/posts do not mark every tight
        -- bedside floor point as blocked; walls and separate objects still hit.
        local hit = nearby.castRay(
            waist,
            waist + offset,
            { collisionType = nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if hit and hit.hit then blocked = blocked + 1 end
    end

    local penalty = (unsupported * 650) + (uneven * 450) + (blocked * 350)
    local hardBlocked = centerUnsupported
        or centerUneven
        or unsupported >= 6
        or uneven >= 6
        or blocked >= 5
    local reason = centerUnsupported and "center_unsupported"
        or centerUneven and "center_uneven"
        or unsupported >= 6 and "unsupported"
        or uneven >= 6 and "uneven"
        or blocked >= 5 and "blocked"
        or "ok"
    return penalty, hardBlocked, reason, unsupported, uneven, blocked
end

local function standardExitFootprintPenalty(pos, currentObject)
    if not (pos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return 0, false, "unavailable" end

    local supportOffsets = {
        util.vector3(0, 0, 0),
        util.vector3(34, 0, 0),
        util.vector3(-34, 0, 0),
        util.vector3(0, 34, 0),
        util.vector3(0, -34, 0),
        util.vector3(24, 24, 0),
        util.vector3(-24, 24, 0),
        util.vector3(24, -24, 0),
        util.vector3(-24, -24, 0),
    }
    local unsupported = 0
    local uneven = 0
    local centerUnsupported = false
    local centerUneven = false
    for _, offset in ipairs(supportOffsets) do
        local probe = pos + offset
        local hit = nearby.castRay(
            probe + util.vector3(0, 0, 38),
            probe - util.vector3(0, 0, 96),
            { collisionType = nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if not (hit and hit.hit and hit.hitPos) then
            unsupported = unsupported + 1
            if offset.x == 0 and offset.y == 0 then centerUnsupported = true end
        else
            local dz = math.abs((hit.hitPos.z or 0) - (pos.z or 0))
            if dz > 26 then
                uneven = uneven + 1
                if offset.x == 0 and offset.y == 0 then centerUneven = true end
            end
        end
    end

    local clearanceOffsets = {
        util.vector3(38, 0, 0),
        util.vector3(-38, 0, 0),
        util.vector3(0, 38, 0),
        util.vector3(0, -38, 0),
        util.vector3(28, 28, 0),
        util.vector3(-28, 28, 0),
        util.vector3(28, -28, 0),
        util.vector3(-28, -28, 0),
    }
    local blocked = 0
    local waist = pos + util.vector3(0, 0, 48)
    for _, offset in ipairs(clearanceOffsets) do
        local hit = nearby.castRay(
            waist,
            waist + offset,
            { collisionType = nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if hit and hit.hit then blocked = blocked + 1 end
    end

    local penalty = (unsupported * 500) + (uneven * 350) + (blocked * 260)
    local hardBlocked = centerUnsupported
        or centerUneven
        or unsupported >= 7
        or uneven >= 7
        or blocked >= 7
    local reason = centerUnsupported and "center_unsupported"
        or centerUneven and "center_uneven"
        or unsupported >= 7 and "unsupported"
        or uneven >= 7 and "uneven"
        or blocked >= 7 and "blocked"
        or "ok"
    return penalty, hardBlocked, reason, unsupported, uneven, blocked
end


local function wallSeparatedFromSleep(pos, finalPos, currentObject)
    if not (pos and finalPos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return false end
    local heights = { 28, 54, 82 }
    local hits = 0
    for _, z in ipairs(heights) do
        local hit = nearby.castRay(
            finalPos + util.vector3(0, 0, z),
            pos + util.vector3(0, 0, z),
            { collisionType = nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if hit and hit.hit and not objectLooksLikeSoftPartition(hit.hitObject) then hits = hits + 1 end
    end
    return hits >= 2
end

local function pathStatusIsSuccess(status)
    if status == nil then return false end
    local findPathStatus = nearby and nearby["FIND_PATH_STATUS"] or nil
    if findPathStatus and status == findPathStatus.Success then return true end
    local label = tostring(status)
    return label == "Success" or label == "success" or label:find("Success", 1, true) ~= nil
end

local function navPathLength(path)
    if type(path) ~= "table" then return nil end
    local length = 0
    local prev = nil
    for _, pos in ipairs(path) do
        if prev and pos then length = length + (pos - prev):length() end
        prev = pos
    end
    return length
end

local function nearestWalkNavmeshPosition(ctx, pos, includeFlags, maxDelta, maxBlockedSnap)
    if not pos then return nil, "missing_position", math.huge end
    if ctx and ctx.nearestWalkNavmeshPosition then
        return ctx.nearestWalkNavmeshPosition(pos, includeFlags, maxDelta, maxBlockedSnap)
    end
    return pos, "unavailable", 0
end

local function sleepExitNavmeshCandidate(ctx, pos, finalPos, floorDrop)
    local flags = nearby and nearby["NAVIGATOR_FLAGS"] or nil
    if not (ctx and pos and flags) then return nil, "navmesh_unavailable", math.huge end
    local includeFlags = (flags.Walk or 0) + (flags.UsePathgrid or 0)
    if includeFlags == 0 then return nil, "navmesh_unavailable", math.huge end
    -- Do not use the blocked-snap veto here. A valid candidate often starts on a
    -- bed or hammock surface and snaps vertically to the actor-walkable floor;
    -- wall separation and footprint probes below are the hard safety checks.
    local navPos, reason, delta = nearestWalkNavmeshPosition(ctx, pos, includeFlags, 260, nil)
    if not navPos then return nil, reason or "exit_no_navmesh", delta or math.huge end
    if finalPos and navPos.z and finalPos.z and navPos.z > finalPos.z - (floorDrop or 6) then
        return nil, "exit_navmesh_not_floor", delta or 0
    end
    return navPos, reason, delta or 0
end


local function exitPathRejectReason(ctx, pos, approachPos, finalPos, bunkProfile)
    if not bunkProfile then return nil, nil end
    local navigatorFlags = nearby and nearby["NAVIGATOR_FLAGS"] or nil
    if not (pos and approachPos and nearby and nearby.findPath and navigatorFlags) then return nil, nil end

    local includeFlags = (navigatorFlags.Walk or 0) + (navigatorFlags.UsePathgrid or 0)
    local navExit, exitNavReason = nearestWalkNavmeshPosition(ctx, pos, includeFlags, 190, 48)
    if not navExit then return exitNavReason or "exit_no_navmesh", nil end

    local navApproach = nearestWalkNavmeshPosition(ctx, approachPos, includeFlags, 260, 58)
    if not navApproach then
        -- Bunk entry can be accepted from a trusted bedside raw point while the
        -- actual route target is a snapped navmesh point. Do not reject every
        -- otherwise-safe exit just because this later check only receives the
        -- raw approach point.
        return nil, nil
    end

    local options = {
        includeFlags = includeFlags,
        destinationTolerance = 48,
        agentBounds = nil,
        areaCosts = nil,
        checkpoints = nil,
    }
    local ok, status, path = pcall(nearby.findPath, navApproach, navExit, options)
    if not ok or not pathStatusIsSuccess(status) or not path or #path < 2 then
        return "exit_no_path_from_approach", nil
    end

    local pathLength = navPathLength(path)
    if not pathLength then return nil, nil end

    local straight = horizontalDistance(navApproach, navExit)
    if pathLength > math.max(260, straight * 2.5 + 90) then
        return "exit_path_too_indirect", pathLength
    end

    if finalPos then
        local finalDist = horizontalDistance(finalPos, navExit)
        if finalDist <= 260 and pathLength > finalDist * 3.0 + 160 then
            return "exit_path_room_boundary", pathLength
        end
    end

    return nil, pathLength
end

local function objectLooksLikeExitBlocker(obj)
    if objectLooksLikeSoftPartition(obj) then return true end
    local text = objectText(obj)
    return text:find("chest", 1, true) ~= nil
        or text:find("crate", 1, true) ~= nil
        or text:find("barrel", 1, true) ~= nil
        or text:find("cabinet", 1, true) ~= nil
        or text:find("closet", 1, true) ~= nil
        or text:find("sack", 1, true) ~= nil
        or text:find("urn", 1, true) ~= nil
        or text:find("basket", 1, true) ~= nil
end

local function exitBlockerLists()
    local lists = {}
    if nearby.containers then lists[#lists + 1] = { list = nearby.containers, radius = 105, kind = "container" } end
    if nearby.activators then lists[#lists + 1] = { list = nearby.activators, radius = 82, kind = "activator" } end
    if nearby.items then lists[#lists + 1] = { list = nearby.items, radius = 62, kind = "item" } end
    return lists
end

local function exitObjectBlocker(pos, currentObject)
    if not pos then return nil, nil, nil end
    for _, group in ipairs(exitBlockerLists()) do
        for _, obj in ipairs(group.list) do
            if obj ~= currentObject and clutterItems.objectEnabled(obj) and obj.position then
                local dx = (obj.position.x or 0) - (pos.x or 0)
                local dy = (obj.position.y or 0) - (pos.y or 0)
                local flat = math.sqrt((dx * dx) + (dy * dy))
                local vertical = math.abs((obj.position.z or 0) - (pos.z or 0))
                local hard = group.kind == "container"
                    or objectLooksLikeExitBlocker(obj)
                    or clutterItems.kind(nil, obj) == "hard_blocker"
                if hard and flat <= group.radius and vertical <= 145 then
                    return obj, group.kind, flat
                end
            end
        end
    end
    return nil, nil, nil
end

function module.chooseExits(ctx, slot, profile, finalPos, approachPos, approachName)
    local positions = {}
    local clearFloor = {}
    local groundish = {}
    local minExitDistance = tonumber(profile and profile.sleepMinExitDistance or 70) or 70
    local floorDrop = tonumber(profile and profile.sleepExitFloorDrop or 6) or 6
    local currentObject = ctx.currentObject()
    local bunkProfile = isBunkProfile(slot, profile)

    local function addExit(pos, name, extraScore, sourceKind, offset)
        if not pos then return end
        local navReason = nil
        local navDelta = nil
        local navSnapped = false
        local navPos, snappedReason, snappedDelta = sleepExitNavmeshCandidate(ctx, pos, finalPos, floorDrop)
        if navPos then
            local posOnFloor = not finalPos or not pos.z or pos.z <= finalPos.z - floorDrop
            if not posOnFloor or (snappedDelta or 0) <= 96 or sourceKind == "sleep_root_fallback" or sourceKind == "approach_floor" then
                pos = navPos
                navSnapped = true
            end
            navReason = snappedReason
            navDelta = snappedDelta
        else
            navReason = snappedReason
            navDelta = snappedDelta
        end

        local actorDist = (ctx.selfObject().position - pos):length()
        local finalDist = finalPos and (finalPos - pos):length() or 0
        local approachDist = approachPos and (approachPos - pos):length() or actorDist
        local horizontal = horizontalDistance(pos, finalPos)
        local onFloor = not finalPos or not pos.z or pos.z <= finalPos.z - floorDrop
        local farEnough = not finalPos or horizontal >= minExitDistance
        local penalty, hardBlocked, clearanceBlocked = sleepExitClearancePenalty(pos, finalPos, { softOutHit = true })
        local footprintReason = nil
        local footprintUnsupported = 0
        local footprintUneven = 0
        local footprintBlocked = 0
        local wallSeparated = false
        local pathRejectReason = nil
        local exitPathLength = nil
        do
            local footprintPenalty, footprintHardBlocked, reason, unsupported, uneven, blocked
            if bunkProfile then
                footprintPenalty, footprintHardBlocked, reason, unsupported, uneven, blocked = bunkExitFootprintPenalty(pos, currentObject)
            else
                footprintPenalty, footprintHardBlocked, reason, unsupported, uneven, blocked = standardExitFootprintPenalty(pos, currentObject)
            end
            penalty = penalty + (footprintPenalty or 0)
            if footprintHardBlocked then penalty = penalty + 900 end
            footprintReason = reason
            footprintUnsupported = unsupported or 0
            footprintUneven = uneven or 0
            footprintBlocked = blocked or 0
            if footprintHardBlocked then hardBlocked = true end
        end
        if wallSeparatedFromSleep(pos, finalPos, currentObject) then
            penalty = penalty + 2600
            hardBlocked = true
            wallSeparated = true
            footprintReason = footprintReason == "ok" and "wall_separated" or tostring(footprintReason) .. "_wall_separated"
        end
        if bunkProfile then
            pathRejectReason, exitPathLength = exitPathRejectReason(ctx, pos, approachPos, finalPos, bunkProfile)
            if pathRejectReason then
                -- The nav path from bed approach to wake exit is advisory here.
                -- Census-style bunks can have valid floor beside them while
                -- findPath routes around furniture poorly; footprint and wall
                -- probes are the hard safety gates.
                penalty = penalty + (pathRejectReason == "exit_no_path_from_approach" and 700 or 1100)
                footprintReason = footprintReason == "ok" and pathRejectReason or tostring(footprintReason) .. "_" .. pathRejectReason
            end
        end
        local objectBlocker, objectBlockerKind, objectBlockerDistance = exitObjectBlocker(pos, currentObject)
        if objectBlocker then
            if objectLooksLikeSoftPartition(objectBlocker) then
                penalty = penalty + 650
                footprintReason = footprintReason == "ok" and "soft_partition_near_exit" or tostring(footprintReason) .. "_soft_partition_near_exit"
            else
                penalty = penalty + 1800
                hardBlocked = true
            end
        end
        if not onFloor then penalty = penalty + 2000 end
        if not farEnough then penalty = penalty + 1000 end
        local anchoredToSleep = offset and (offset.anchor == "sleep_root" or offset.anchor == "final" or offset.anchor == "sleep")
        local preferApproachSide = profile and profile.sleepExitPreferApproachSide == true and sourceKind == "profile"
        local score
        if anchoredToSleep or preferApproachSide then
            score = (approachDist * 0.8) + (finalDist * 0.05) + (extraScore or 0) + penalty - 80
        else
            score = actorDist + (finalDist * 0.1) + (extraScore or 0) + penalty
        end
        local entry = { pos = pos, name = name or "exit", score = score, horizontal = horizontal, onFloor = onFloor, farEnough = farEnough, sourceKind = sourceKind, approachName = approachName, hardBlocked = hardBlocked, clearanceBlocked = clearanceBlocked, footprintReason = footprintReason, footprintUnsupported = footprintUnsupported, footprintUneven = footprintUneven, footprintBlocked = footprintBlocked, wallSeparated = wallSeparated, exitPathReason = pathRejectReason, exitPathLength = exitPathLength, blocker = objectBlocker, blockerKind = objectBlockerKind, blockerDistance = objectBlockerDistance, navSnapped = navSnapped, navReason = navReason, navDelta = navDelta }
        table.insert(positions, entry)

        if onFloor and farEnough and not hardBlocked then
            table.insert(clearFloor, entry)
        elseif onFloor and not hardBlocked then
            table.insert(groundish, entry)
        end
    end

    local function addSleepRootFallbackExits()
        if not finalPos then return end
        local fallbackOffsets = {
            { name = "floor_left", anchor = "sleep_root", x = -135, y = 0, z = 0 },
            { name = "floor_right", anchor = "sleep_root", x = 135, y = 0, z = 0 },
            { name = "floor_foot", anchor = "sleep_root", x = 0, y = -150, z = 0 },
            { name = "floor_head", anchor = "sleep_root", x = 0, y = 150, z = 0 },
            { name = "floor_foot_left", anchor = "sleep_root", x = -118, y = -118, z = 0 },
            { name = "floor_foot_right", anchor = "sleep_root", x = 118, y = -118, z = 0 },
            { name = "floor_head_left", anchor = "sleep_root", x = -118, y = 118, z = 0 },
            { name = "floor_head_right", anchor = "sleep_root", x = 118, y = 118, z = 0 },
            { name = "floor_left_wide", anchor = "sleep_root", x = -175, y = 0, z = 0 },
            { name = "floor_right_wide", anchor = "sleep_root", x = 175, y = 0, z = 0 },
            { name = "floor_foot_wide", anchor = "sleep_root", x = 0, y = -185, z = 0 },
            { name = "floor_head_wide", anchor = "sleep_root", x = 0, y = 185, z = 0 },
        }
        for _, offset in ipairs(fallbackOffsets) do
            addExit(projectedSleepExitOffset(ctx, offset, finalPos), offset.name, 260, "sleep_root_fallback", offset)
        end
    end

    local authoredExitOffsets = module.collectExitOffsets(slot, profile)
    for _, offset in ipairs(authoredExitOffsets) do
        if not (profile and profile.sleepExitSideOnly == true and not bunkProfile and exitOffsetIsHeadOrFoot(offset)) then
            addExit(projectedSleepExitOffset(ctx, offset, finalPos), offset.name or "exit", 0, "profile", offset)
        end
    end

    if bunkProfile then
        local bunkExitOffsets = {
            { name = "bunk_exit_left", x = -150, y = 0, z = 0 },
            { name = "bunk_exit_right", x = 150, y = 0, z = 0 },
            { name = "bunk_exit_foot", x = 0, y = -150, z = 0 },
            { name = "bunk_exit_head", x = 0, y = 150, z = 0 },
            { name = "bunk_exit_foot_left", x = -125, y = -125, z = 0 },
            { name = "bunk_exit_foot_right", x = 125, y = -125, z = 0 },
            { name = "bunk_exit_head_left", x = -125, y = 125, z = 0 },
            { name = "bunk_exit_head_right", x = 125, y = 125, z = 0 },
            { name = "bunk_exit_left_close", x = -92, y = 0, z = 0 },
            { name = "bunk_exit_right_close", x = 92, y = 0, z = 0 },
            { name = "bunk_exit_foot_close", x = 0, y = -92, z = 0 },
            { name = "bunk_exit_head_close", x = 0, y = 92, z = 0 },
        }
        for _, offset in ipairs(bunkExitOffsets) do
            addExit(ctx.projectedObjectOffset(offset), offset.name, 40, "bunk", offset)
        end
    end

    if #clearFloor == 0 then
        addSleepRootFallbackExits()
    end

    if #clearFloor == 0 and approachPos then
        addExit(approachPos, "approach_floor_exit", 180, "approach_floor")
    end

    if not (profile and profile.sleepExitDisableRingFallback == true) then
        local ringOffsets = {
            { name = "ring_foot", x = 0, y = -150, z = 0 },
            { name = "ring_head", x = 0, y = 150, z = 0 },
            { name = "ring_left", x = -120, y = 0, z = 0 },
            { name = "ring_right", x = 120, y = 0, z = 0 },
            { name = "ring_foot_left", x = -105, y = -125, z = 0 },
            { name = "ring_foot_right", x = 105, y = -125, z = 0 },
            { name = "ring_head_left", x = -105, y = 125, z = 0 },
            { name = "ring_head_right", x = 105, y = 125, z = 0 },
        }
        for _, offset in ipairs(ringOffsets) do
            if not (profile and profile.sleepExitSideOnly == true and exitOffsetIsHeadOrFoot(offset)) then
                addExit(ctx.projectedObjectOffset(offset), offset.name, 120, "ring", offset)
            end
        end
    end

    if approachPos and (bunkProfile or not (profile and profile.sleepExitIncludeApproachFallback == false)) then
        addExit(approachPos, "approach_exit", 80, "approach")
    end

    -- Wake code rejects non-floor sleep exits. Do not accept a bed just because
    -- a bunk/top-surface ray produced an otherwise unobstructed candidate.
    local source = #clearFloor > 0 and clearFloor or groundish
    table.sort(source, function(a, b) return (a.score or 0) < (b.score or 0) end)

    local result = {}
    for _, entry in ipairs(source) do
        table.insert(result, entry.pos)
    end

    if #result == 0 and ctx.debugLog then
        local hardBlocked = 0
        local notOnFloor = 0
        local tooClose = 0
        local footprintUnsupportedCandidates = 0
        local footprintUnsupportedSamples = 0
        local footprintUnevenCandidates = 0
        local footprintUnevenSamples = 0
        local footprintBlockedCandidates = 0
        local footprintBlockedSamples = 0
        local wallSeparated = 0
        local navSnapped = 0
        local navRejected = 0
        local exitPathRejected = 0
        local exitPathReasons = {}
        local clearanceBlocked = 0
        for _, entry in ipairs(positions) do
            if entry.hardBlocked then hardBlocked = hardBlocked + 1 end
            if not entry.onFloor then notOnFloor = notOnFloor + 1 end
            if not entry.farEnough then tooClose = tooClose + 1 end
            if entry.clearanceBlocked then clearanceBlocked = clearanceBlocked + 1 end
            if (entry.footprintUnsupported or 0) > 0 then
                footprintUnsupportedCandidates = footprintUnsupportedCandidates + 1
                footprintUnsupportedSamples = footprintUnsupportedSamples + (entry.footprintUnsupported or 0)
            end
            if (entry.footprintUneven or 0) > 0 then
                footprintUnevenCandidates = footprintUnevenCandidates + 1
                footprintUnevenSamples = footprintUnevenSamples + (entry.footprintUneven or 0)
            end
            if (entry.footprintBlocked or 0) > 0 then
                footprintBlockedCandidates = footprintBlockedCandidates + 1
                footprintBlockedSamples = footprintBlockedSamples + (entry.footprintBlocked or 0)
            end
            if entry.wallSeparated then wallSeparated = wallSeparated + 1 end
            if entry.navSnapped then navSnapped = navSnapped + 1 end
            if entry.navReason and not entry.navSnapped then navRejected = navRejected + 1 end
            if entry.exitPathReason then
                exitPathRejected = exitPathRejected + 1
                local reason = tostring(entry.exitPathReason)
                exitPathReasons[reason] = (exitPathReasons[reason] or 0) + 1
            end
        end
        local exitPathReasonParts = {}
        for reason, count in pairs(exitPathReasons) do
            exitPathReasonParts[#exitPathReasonParts + 1] = reason .. "=" .. tostring(count)
        end
        table.sort(exitPathReasonParts)
        ctx.debugLog(
            "sleep exit candidates rejected",
            "object", tostring(currentObject and currentObject.recordId),
            "slot", tostring(slot and slot.name),
            "profile", tostring(profile and profile.profileId),
            "candidates", tostring(#positions),
            "hardBlocked", tostring(hardBlocked),
            "notOnFloor", tostring(notOnFloor),
            "tooClose", tostring(tooClose),
            "clearanceBlocked", tostring(clearanceBlocked),
            "footprintUnsupported", tostring(footprintUnsupportedCandidates) .. "/" .. tostring(footprintUnsupportedSamples),
            "footprintUneven", tostring(footprintUnevenCandidates) .. "/" .. tostring(footprintUnevenSamples),
            "footprintBlocked", tostring(footprintBlockedCandidates) .. "/" .. tostring(footprintBlockedSamples),
            "wallSeparated", tostring(wallSeparated),
            "navSnapped", tostring(navSnapped),
            "navRejected", tostring(navRejected),
            "exitPathRejected", tostring(exitPathRejected),
            "exitPathReasons", table.concat(exitPathReasonParts, ","),
            "approach", tostring(approachName)
        )
    end

    return result, source[1] and source[1].name or nil
end

function module.finalPlacementLocallySane(ctx, finalPos, approachPos, bedTop, profile, stage, opts)
    opts = opts or {}
    local currentObject = ctx.currentObject()
    return finalSafety.validate({
        data = {
            interactionType = "sleeping",
            fallbackUsed = opts.fallbackUsed == true,
            calibrationAction = opts.calibrationAction == true,
            calibrationFill = opts.calibrationFill == true,
            explicitFillOverride = opts.explicitFillOverride == true,
            manualAssignOverrideTesting = opts.manualAssignOverrideTesting == true,
            manualAssign = opts.manualAssign == true,
            manualSleepEntryOverride = opts.manualSleepEntryOverride == true,
            debugForced = opts.debugForced == true,
            initialPlacement = opts.initialPlacement == true,
            reachedValidSleepApproach = opts.reachedValidSleepApproach == true,
        },
        finalPosition = finalPos,
        approachPosition = approachPos,
        surfacePosition = bedTop,
        surfaceTopPosition = opts.surfaceTopPosition,
        object = currentObject,
        objectPosition = currentObject and currentObject.position or nil,
        objectId = currentObject and (currentObject.recordId or currentObject.id),
        npc = opts.actor,
        profile = profile,
        slotName = opts.slotName,
        slotKey = opts.slotKey,
        surfaceMode = opts.surfaceMode,
        surfaceSamples = opts.surfaceSamples,
        fallbackUsed = opts.fallbackUsed,
        calibrationAction = opts.calibrationAction,
        calibrationFill = opts.calibrationFill,
        explicitFillOverride = opts.explicitFillOverride,
        manualAssignOverrideTesting = opts.manualAssignOverrideTesting,
        manualSleepEntryOverride = opts.manualSleepEntryOverride,
        debugForced = opts.debugForced,
        initialPlacement = opts.initialPlacement,
        reachedValidSleepApproach = opts.reachedValidSleepApproach,
        serviceActor = opts.serviceActor,
        trigger = stage,
    })
end

return module
