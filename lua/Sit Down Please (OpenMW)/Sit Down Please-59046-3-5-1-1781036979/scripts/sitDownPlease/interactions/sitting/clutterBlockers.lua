-- interactions/sitting/clutterBlockers.lua
---@omw-context none

local clutterItems = require('scripts/sitDownPlease/world/clutterItems')
local scaleContext = require('scripts/sitDownPlease/world/scaleContext')
local M = {}

function M.kind(env, item)
    return clutterItems.kind(env, item)
end

local function lists(env)
    local nearby = env and env.nearby
    local result = {}
    if env and env.objects then result[#result + 1] = env.objects end
    if env and env.objectLists then
        for _, list in ipairs(env.objectLists) do
            if list then result[#result + 1] = list end
        end
    end
    if not nearby then return result end
    if nearby.items then result[#result + 1] = nearby.items end
    if nearby.activators then result[#result + 1] = nearby.activators end
    -- Some furniture-like blockers (stacked stools/chairs, display pieces, etc.)
    -- can live in the static list rather than items/activators.  Keep this
    -- conservative by only treating records that classify as clutter/furniture
    -- blockers as hits later in surfaceBlocker().
    if nearby.statics then result[#result + 1] = nearby.statics end
    return result
end

function M.softSurfaceTopZ(env, item, sitPosition)
    local nearby = env and env.nearby
    local util = env and env.util
    local rayHitBelongsToObject = env and env.rayHitBelongsToObject
    if not (item and item.position and sitPosition and nearby and nearby.castRay and nearby.COLLISION_TYPE and util and rayHitBelongsToObject) then return nil end
    local bestZ = nil
    local probes = {
        sitPosition,
        item.position,
        item.position + util.vector3(8, 0, 0),
        item.position + util.vector3(-8, 0, 0),
        item.position + util.vector3(0, 8, 0),
        item.position + util.vector3(0, -8, 0),
    }
    for _, base in ipairs(probes) do
        local result = nearby.castRay(base + util.vector3(0, 0, 80), base - util.vector3(0, 0, 30), {
            collisionType = nearby.COLLISION_TYPE.World,
            radius = 0,
        })
        if result.hit and result.hitPos and rayHitBelongsToObject(result.hitObject, item) then
            bestZ = bestZ and math.max(bestZ, result.hitPos.z) or result.hitPos.z
        end
    end
    if not bestZ and item.position.z and item.position.z > sitPosition.z then
        bestZ = item.position.z
    end
    if bestZ and bestZ >= sitPosition.z - 2 and bestZ <= sitPosition.z + 70 then
        return bestZ
    end
    return nil
end

local function localHit(env, item, sitPosition, profile, currentObject)
    if not (item and item.position and sitPosition) then return false, nil, nil, nil end
    local sittingSeatCategory = env and env.sittingSeatCategory
    local category = sittingSeatCategory and sittingSeatCategory(profile, currentObject) or nil
    local dx = (item.position.x or 0) - (sitPosition.x or 0)
    local dy = (item.position.y or 0) - (sitPosition.y or 0)
    local dz = (item.position.z or 0) - (sitPosition.z or 0)
    local flatToSeat = math.sqrt(dx * dx + dy * dy)

    -- This blocker is meant to detect objects actually on the resolved seat
    -- surface. Older backed-chair logic also accepted anything inside a broad
    -- chair-local pan. In cluttered shops that caught bottles/books on the
    -- adjacent table/counter and produced false "Item on seat surface"
    -- blockers. Keep the test tight and centered on the resolved sit point;
    -- table/counter clearance is handled by the separate clearance module.
    local radius
    if category == "bench" or category == "single_seat_bench" then
        radius = 24
    elseif category == "stool" or category == "barstool" then
        radius = 18
    elseif category == "backed_chair" then
        radius = 20
    else
        radius = 24
    end

    radius = scaleContext.scaledRadius(radius, currentObject, item, { minRadius = radius * 0.7, maxRadius = radius * 1.35, largeBlockerBonus = 6 })
    local minZ, maxZ = scaleContext.scaledVerticalBand(-10, 42, item, { largeBlockerZBonus = 8 })
    if flatToSeat <= radius and dz >= minZ and dz <= maxZ then
        return true, flatToSeat, dz, "seat_position"
    end

    -- Furniture stacked around a stool/chair can sit outside the normal
    -- loose-item height band while still making the final pose invalid. Keep
    -- the test narrow so ordinary nearby furniture does not veto valid seats.
    if env and clutterItems.isFurnitureLike and clutterItems.isFurnitureLike(env, item) then
        local stackedRadius = (category == "stool" or category == "barstool") and 34 or 28
        stackedRadius = scaleContext.scaledRadius(stackedRadius, currentObject, item, { minRadius = stackedRadius * 0.75, maxRadius = stackedRadius * 1.75, largeBlockerBonus = 16 })
        local minStackZ, maxStackZ = scaleContext.scaledVerticalBand(-105, 18, item, { largeBlockerZBonus = 20 })
        if flatToSeat <= stackedRadius and dz >= minStackZ and dz <= maxStackZ then
            return true, flatToSeat, dz, "stacked_furniture_under_seat"
        end
        local minAboveZ, maxAboveZ = scaleContext.scaledVerticalBand(18, 135, item, { largeBlockerZBonus = 24 })
        if flatToSeat <= stackedRadius + 10 and dz >= minAboveZ and dz <= maxAboveZ then
            return true, flatToSeat, dz, "stacked_furniture_on_seat"
        end
    end

    return false, flatToSeat, dz, nil
end

function M.surfaceBlocker(env, sitPosition, profile, currentObject)
    if not sitPosition then return nil end
    for _, list in ipairs(lists(env)) do
        for _, item in ipairs(list) do
            local kind = M.kind(env, item)
            if item ~= currentObject and clutterItems.objectEnabled(item) and kind ~= nil and item.position then
                local hit, flat, dz, reason = localHit(env, item, sitPosition, profile, currentObject)
                if hit then
                    return item, flat, dz, reason, kind
                end
            end
        end
    end
    return nil
end

return M
