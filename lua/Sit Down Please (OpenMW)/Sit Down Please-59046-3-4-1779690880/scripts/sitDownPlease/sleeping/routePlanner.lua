-- sleeping/routePlanner.lua
-- Local-script sleep approach/exit planning helpers split out from
-- interactionSeeker.lua to reduce file size and top-level local pressure.
local util = require('openmw.util')
local nearby = require('openmw.nearby')

local module = {}

function module.collectApproachOffsets(slot, profile)
    local offsets = {}

    local function add(offset)
        if offset then table.insert(offsets, offset) end
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
        or reason == "wrong_floor_or_unreachable"
end

function module.chooseApproach(ctx, data, slot, profile, finalPos)
    if data and data.approachPos then
        local reachable, reason, details = ctx.sleepApproachReachability(data.approachPos, finalPos, data, "sleep_entry_rejected")
        return (details and details.navPos) or data.approachPos, "assigned", reachable, reason, details
    end

    local hardRouteReject = false
    local bestReachable = nil
    local bestReachableScore = nil
    local bestRejected = nil
    local bestRejectedScore = nil

    for _, offset in ipairs(module.collectApproachOffsets(slot, profile)) do
        local pos = ctx.projectedObjectOffset(offset)
        local actorDist = (ctx.selfObject().position - pos):length()
        local finalDist = finalPos and (finalPos - pos):length() or 0
        local reachable, reason, details = ctx.sleepApproachReachability(pos, finalPos, data, nil)
        if not reachable and module.isHardApproachReject(reason) then
            hardRouteReject = true
        end
        local actorLineBlocked = details and details.actorLineBlocked == true or false
        local routeDist = details and details.pathLength or actorDist
        local score = routeDist + (finalDist * 0.15) + (actorLineBlocked and 800 or 0)
        details = details or {}
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

local function sleepExitClearancePenalty(pos, finalPos)
    if not pos or not finalPos then return 0 end
    local dx = (pos.x or 0) - (finalPos.x or 0)
    local dy = (pos.y or 0) - (finalPos.y or 0)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len < 1 then return 400 end

    local dir = util.vector3(dx / len, dy / len, 0)
    local penalty = 0

    local outFrom = pos + util.vector3(0, 0, 72)
    local outTo = outFrom + (dir * 70)
    local outHit = nearby.castRay(outFrom, outTo, { collisionType = nearby.COLLISION_TYPE.World })
    if outHit.hit then penalty = penalty + 900 end

    if len > 55 then
        local from = finalPos + (dir * 55) + util.vector3(0, 0, 72)
        local to = pos + util.vector3(0, 0, 72)
        local crossHit = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
        if crossHit.hit then penalty = penalty + 450 end
    end

    return penalty
end

function module.chooseExits(ctx, slot, profile, finalPos, approachPos, approachName)
    local positions = {}
    local clearFloor = {}
    local groundish = {}
    local minExitDistance = tonumber(profile and profile.sleepMinExitDistance or 70) or 70
    local floorDrop = tonumber(profile and profile.sleepExitFloorDrop or 6) or 6

    local function addExit(pos, name, extraScore, sourceKind, offset)
        if not pos then return end
        local actorDist = (ctx.selfObject().position - pos):length()
        local finalDist = finalPos and (finalPos - pos):length() or 0
        local approachDist = approachPos and (approachPos - pos):length() or actorDist
        local horizontal = horizontalDistance(pos, finalPos)
        local onFloor = not finalPos or not pos.z or pos.z <= finalPos.z - floorDrop
        local farEnough = not finalPos or horizontal >= minExitDistance
        local penalty = sleepExitClearancePenalty(pos, finalPos)
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
        local entry = { pos = pos, name = name or "exit", score = score, horizontal = horizontal, onFloor = onFloor, farEnough = farEnough, sourceKind = sourceKind, approachName = approachName }
        table.insert(positions, entry)

        if onFloor and farEnough then
            table.insert(clearFloor, entry)
        elseif onFloor then
            table.insert(groundish, entry)
        end
    end

    local authoredExitOffsets = module.collectExitOffsets(slot, profile)
    for _, offset in ipairs(authoredExitOffsets) do
        if not (profile and profile.sleepExitSideOnly == true and exitOffsetIsHeadOrFoot(offset)) then
            addExit(projectedSleepExitOffset(ctx, offset, finalPos), offset.name or "exit", 0, "profile", offset)
        end
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

    if approachPos and not (profile and profile.sleepExitIncludeApproachFallback == false) then
        addExit(approachPos, "approach_exit", 80, "approach")
    end

    local source = #clearFloor > 0 and clearFloor or (#groundish > 0 and groundish or positions)
    table.sort(source, function(a, b) return (a.score or 0) < (b.score or 0) end)

    local result = {}
    for _, entry in ipairs(source) do
        table.insert(result, entry.pos)
    end

    return result, source[1] and source[1].name or nil
end

function module.finalPlacementLocallySane(ctx, finalPos, approachPos, bedTop, profile, stage)
    if not finalPos then return false, "missing_final_position", nil, nil end
    local currentObject = ctx.currentObject()
    local objectPos = currentObject and currentObject.position or nil
    if approachPos then
        local maxAboveApproach = tonumber(profile and profile.sleepFinalMaxAboveApproachZ or 170) or 170
        local dz = (finalPos.z or 0) - (approachPos.z or 0)
        if dz > maxAboveApproach then
            return false, "final_above_approach", dz, maxAboveApproach
        end
    end
    if objectPos then
        local maxAboveObject = tonumber(profile and profile.sleepFinalMaxAboveObjectZ or 260) or 260
        local dzObj = (finalPos.z or 0) - (objectPos.z or 0)
        if dzObj > maxAboveObject then
            return false, "final_above_bed_object", dzObj, maxAboveObject
        end
        local maxBelowObject = tonumber(profile and profile.sleepFinalMaxBelowObjectZ or 360) or 360
        if dzObj < -maxBelowObject then
            return false, "final_below_bed_object", dzObj, maxBelowObject
        end
    end
    if bedTop then
        local maxAboveSurface = tonumber(profile and profile.sleepFinalMaxAboveSurfaceZ or 90) or 90
        local dzSurface = (finalPos.z or 0) - (bedTop.z or 0)
        if dzSurface > maxAboveSurface then
            return false, "final_above_sampled_surface", dzSurface, maxAboveSurface
        end
    end
    return true, "ok", nil, nil
end

return module
