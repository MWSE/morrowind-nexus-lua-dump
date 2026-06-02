-- seating/posePlanner.lua
-- Local-script facing/open-space helpers for sitting assignments.
local util = require('openmw.util')
local nearby = require('openmw.nearby')

local module = {}

function module.normalizeDirection3(v)
    if not v then return nil end
    local x, y = v.x or 0, v.y or 0
    local len = math.sqrt((x * x) + (y * y))
    if len <= 0.001 then return nil end
    return util.vector3(x / len, y / len, 0)
end

function module.objectForwardDirection(obj)
    local yaw = 0
    if obj and obj.rotation then yaw = obj.rotation:getYaw() end
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

function module.objectRightDirection(obj)
    local f = module.objectForwardDirection(obj)
    return util.vector3(f.y, -f.x, 0)
end

function module.directionDot2(a, b)
    if not (a and b) then return -1 end
    return (a.x or 0) * (b.x or 0) + (a.y or 0) * (b.y or 0)
end

function module.clearDistanceForDirection(pos, direction, maxDistance)
    local dir = module.normalizeDirection3(direction)
    if not (pos and dir) then return 0 end
    local from = pos + util.vector3(0, 0, 70)
    local to = from + dir * (maxDistance or 130)
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
    if result.hit and result.hitPos then
        return math.max(0, (result.hitPos - from):length())
    end
    return maxDistance or 130
end

function module.bestOpenDirection(pos, directions)
    local bestDir, bestScore = nil, nil
    for _, direction in ipairs(directions or {}) do
        local dir = module.normalizeDirection3(direction)
        if dir then
            local score = module.clearDistanceForDirection(pos, dir, 130)
            if not bestScore or score > bestScore then
                bestDir, bestScore = dir, score
            end
        end
    end
    if bestDir then return bestDir, bestScore end
    return util.vector3(0, 1, 0), 0
end

function module.profileLocksBodyToFurniture(ctx, profile, obj)
    if not profile then return false end
    local mode = tostring(profile.rotationMode or ""):lower()
    local category = ctx.sittingSeatCategory(profile, obj)
    return category == "backed_chair"
        or category == "single_seat_bench"
        or mode == "respectfurnitureforward"
        or mode == "chairforward"
        or mode == "objectforward"
        or mode == "useobjectyaw"
end

function module.allRadialDirections()
    local directions = {}
    local angleStep = math.pi / 6
    for i = 0, 11 do
        local angle = i * angleStep
        directions[#directions + 1] = util.vector3(math.cos(angle), math.sin(angle), 0)
    end
    return directions
end

function module.directionIsUsable(pos, direction, minClearance)
    if not direction then return false end
    return module.clearDistanceForDirection(pos, direction, minClearance or 95) >= (minClearance or 95) - 6
end

function module.focusDirectionIsUsable(ctx, sitPosition, direction, minClearance)
    if not module.directionIsUsable(sitPosition, direction, minClearance or 72) then return false end
    if ctx and ctx.focusVisibleFromSeat and ctx.focusVisibleFromSeat(sitPosition) == false then return false end
    if ctx and ctx.focusSurfaceHitFromSeat and ctx.focusSurfaceHitFromSeat() == false then return false end
    return true
end

function module.determineFacingDirection(ctx, sitPosition, orientation, preferredFacingDirection, preferredFacingKind, profile, obj)
    local debugLog = ctx.debugLog or function() end
    local preferred = module.normalizeDirection3(preferredFacingDirection)
    local category = ctx.sittingSeatCategory(profile, obj)

    if category == "single_seat_bench" then
        local objectForward = module.objectForwardDirection(obj)
        local objectBack = objectForward * -1
        debugLog("single-seat bench profile selected", tostring(obj and obj.recordId), "profile", tostring(profile and profile.profileId))
        if preferred and (preferredFacingKind == "table" or preferredFacingKind == "bar") then
            local bestPhysical = module.directionDot2(preferred, objectForward) >= module.directionDot2(preferred, objectBack) and objectForward or objectBack
            local bestName = bestPhysical == objectForward and "object_forward" or "object_back"
            local focusVisible = true
            if ctx.focusVisibleFromSeat then
                focusVisible = ctx.focusVisibleFromSeat(sitPosition) ~= false
            end
            if focusVisible and module.directionDot2(preferred, bestPhysical) > 0.25 and module.directionIsUsable(sitPosition, bestPhysical, 48) then
                debugLog("single-seat bench facing source table_compatible_" .. bestName, "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
                return module.normalizeDirection3(bestPhysical), "single_seat_bench_table_compatible_" .. bestName
            end
            debugLog("single-seat bench table focus blocked", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind), "best", bestName)
        end
        if preferred then
            debugLog("single-seat bench arbitrary rotation rejected", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
        end
        local openDir = module.bestOpenDirection(sitPosition, { objectForward, objectBack })
        local openName = module.directionDot2(openDir, objectForward) >= module.directionDot2(openDir, objectBack) and "object_forward" or "object_back"
        debugLog("single-seat bench facing source " .. openName, "object", tostring(obj and obj.recordId))
        return openDir, "single_seat_bench_" .. openName
    end

    if module.profileLocksBodyToFurniture(ctx, profile, obj) then
        debugLog("backed_chair_rotation_source", "object_physical_forward", "object", tostring(obj and obj.recordId), "profile", tostring(profile and profile.profileId))
        if preferred and (preferredFacingKind == "table" or preferredFacingKind == "bar") then
            debugLog("backed_chair_table_focus_ignored_due_to_physical_forward", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
        end
        return module.objectForwardDirection(obj), "backed_chair_physical_forward"
    end

    if category == "bench" then
        local right = orientation and orientation.crossAxis or module.objectRightDirection(obj)
        local directions = { right, right * -1 }
        if preferred and (preferredFacingKind == "table" or preferredFacingKind == "bar") then
            if orientation and orientation.singleSeatBench == true and module.focusDirectionIsUsable(ctx, sitPosition, preferred, 72) then
                debugLog("bench facing source single_seat_table", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
                return preferred, "bench_single_seat_table_focus"
            end
            local bestPhysical = module.directionDot2(preferred, right) >= module.directionDot2(preferred, right * -1) and right or right * -1
            local focusVisible = true
            if ctx.focusVisibleFromSeat then
                focusVisible = ctx.focusVisibleFromSeat(sitPosition) ~= false
            end
            if focusVisible and module.directionDot2(preferred, bestPhysical) > 0.25 and module.directionIsUsable(sitPosition, bestPhysical, 48) then
                debugLog("bench facing source table", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
                return module.normalizeDirection3(bestPhysical), "bench_table_focus"
            end
            debugLog("bench facing table blocked", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
        end
        local openDir = module.bestOpenDirection(sitPosition, directions)
        debugLog("bench facing source open_side", "object", tostring(obj and obj.recordId))
        return openDir, "bench_open_side"
    end

    if preferred then
        if preferredFacingKind == "table" or preferredFacingKind == "bar" then
            local focusVisible = true
            if ctx.focusVisibleFromSeat then
                focusVisible = ctx.focusVisibleFromSeat(sitPosition) ~= false
            end
            if not focusVisible then
                debugLog("stool/table focus blocked by world", "object", tostring(obj and obj.recordId), "focus", tostring(preferredFacingKind))
            else
                return preferred, "preferred_" .. tostring(preferredFacingKind)
            end
        elseif module.directionIsUsable(sitPosition, preferred, 70) then
            return preferred, "preferred_" .. tostring(preferredFacingKind or "focus")
        end
    end

    local directions = {}
    if orientation then
        local cross = orientation.crossAxis or nil
        if cross then
            directions[#directions + 1] = cross
            directions[#directions + 1] = cross * -1
        elseif orientation == "x" then
            directions[#directions + 1] = util.vector3(0, -1, 0)
            directions[#directions + 1] = util.vector3(0, 1, 0)
        else
            directions[#directions + 1] = util.vector3(-1, 0, 0)
            directions[#directions + 1] = util.vector3(1, 0, 0)
        end
    else
        directions = module.allRadialDirections()
    end

    local openDir = module.bestOpenDirection(sitPosition, directions)
    return openDir, preferred and "preferred_blocked_open_space" or "open_space_raycast"
end

return module
