-- sitting/benchSlots.lua
---@omw-context none
-- Bench-specific slot basis and spacing logic for local sitting placement.

local M = {}

local MIN_BENCH_SLOT_SEPARATION = 62

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function belongsToBench(ctx, hitObject, bench)
    if ctx and ctx.rayHitBelongsToObject then
        return ctx.rayHitBelongsToObject(hitObject, bench) == true
    end
    return hitObject == bench
end

local function positionAt(util, center, axis, t, zLevel)
    local pos = center + axis * t
    return util.vector3(pos.x, pos.y, zLevel)
end

local function buildPositions(util, center, axis, minT, maxT, zLevel, slotCount)
    local positions = {}
    local usableLength = math.max(20, maxT - minT)
    if slotCount == 1 then
        positions[1] = positionAt(util, center, axis, (minT + maxT) / 2, zLevel)
    elseif slotCount == 2 then
        positions[1] = positionAt(util, center, axis, minT + usableLength / 4, zLevel)
        positions[2] = positionAt(util, center, axis, minT + usableLength * 3 / 4, zLevel)
    else
        local step = usableLength / 3
        positions[1] = positionAt(util, center, axis, minT + step / 2, zLevel)
        positions[2] = positionAt(util, center, axis, minT + step * 1.5, zLevel)
        positions[3] = positionAt(util, center, axis, minT + step * 2.5, zLevel)
    end
    return positions
end

local function closestDistance(positions)
    local closest = nil
    for i = 1, #positions - 1 do
        for j = i + 1, #positions do
            local dist = (positions[i] - positions[j]):length()
            closest = closest and math.min(closest, dist) or dist
        end
    end
    return closest
end

function M.legacyAxisProbe(ctx, bench)
    local center = bench and bench.position
    local util = ctx and ctx.util
    local nearby = ctx and ctx.nearby
    local xHits, yHits = 0, 0
    local xLength, yLength = 0, 0
    if not (center and util and nearby and nearby.castRay and nearby.COLLISION_TYPE) then
        return { xHits = 0, yHits = 0, xLength = 0, yLength = 0 }
    end
    for i = -5, 5 do
        local xResult = nearby.castRay(center + util.vector3(i * 10, 0, 100), center + util.vector3(i * 10, 0, 0), { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
        if xResult.hit and belongsToBench(ctx, xResult.hitObject, bench) then
            xHits = xHits + 1
            xLength = xLength + 10
        end
        local yResult = nearby.castRay(center + util.vector3(0, i * 10, 100), center + util.vector3(0, i * 10, 0), { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
        if yResult.hit and belongsToBench(ctx, yResult.hitObject, bench) then
            yHits = yHits + 1
            yLength = yLength + 10
        end
    end
    return { xHits = xHits, yHits = yHits, xLength = xLength, yLength = yLength, axis = xHits > yHits and "world_x" or "world_y" }
end

function M.axisExtents(ctx, bench, axis, label)
    local center = bench and bench.position
    local util = ctx and ctx.util
    local nearby = ctx and ctx.nearby
    if not (center and axis and util and nearby and nearby.castRay and nearby.COLLISION_TYPE) then
        return { length = 0, hits = 0, min = 0, max = 0, zLevel = center and center.z or 0, label = label }
    end
    local minT, maxT, hits = nil, nil, 0
    local zLevel = center.z
    for i = -16, 16 do
        local t = i * 20
        local p = center + axis * t
        local result = nearby.castRay(p + util.vector3(0, 0, 140), p - util.vector3(0, 0, 80), { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
        if result.hit and result.hitPos and belongsToBench(ctx, result.hitObject, bench) then
            hits = hits + 1
            minT = minT and math.min(minT, t) or t
            maxT = maxT and math.max(maxT, t) or t
            zLevel = result.hitPos.z
        end
    end
    local length = (minT ~= nil and maxT ~= nil) and math.max(20, maxT - minT + 20) or 0
    return { length = length, hits = hits, min = minT or 0, max = maxT or 0, zLevel = zLevel, label = label }
end

function M.determineOrientationAndLength(ctx, bench)
    local forward = ctx.objectForwardDirection(bench)
    local right = ctx.objectRightDirection(bench)
    local legacy = M.legacyAxisProbe(ctx, bench)
    local fExt = M.axisExtents(ctx, bench, forward, "object_forward")
    local rExt = M.axisExtents(ctx, bench, right, "object_right")
    local selected = (fExt.length >= rExt.length) and fExt or rExt
    local longAxis = (selected == fExt) and forward or right
    local crossAxis = (selected == fExt) and right or forward
    local length = selected.length
    if length <= 0 then
        length = math.max(160, math.max(legacy.xLength or 0, legacy.yLength or 0))
    end
    debugLog(
        ctx,
        "bench basis comparison current_vs_legacy",
        "object", tostring(bench and bench.recordId),
        "legacyAxis", tostring(legacy.axis),
        "legacyX", tostring(legacy.xLength),
        "legacyY", tostring(legacy.yLength),
        "objectForwardLength", tostring(fExt.length),
        "objectRightLength", tostring(rExt.length)
    )
    debugLog(ctx, "bench extents raw", "object", tostring(bench and bench.recordId), "forwardHits", tostring(fExt.hits), "forwardMinMax", tostring(fExt.min) .. ":" .. tostring(fExt.max), "rightHits", tostring(rExt.hits), "rightMinMax", tostring(rExt.min) .. ":" .. tostring(rExt.max))
    debugLog(ctx, "bench long axis selected", "object", tostring(bench and bench.recordId), "axis", tostring(selected.label), "length", tostring(length))
    return {
        longAxis = longAxis,
        crossAxis = crossAxis,
        label = selected.label,
        legacy = legacy,
        min = selected.min,
        max = selected.max,
        hits = selected.hits,
    }, length, selected.zLevel or (bench.position and bench.position.z or 0)
end

function M.sittingPositions(ctx, bench, orientation, length, zLevel, profile)
    local center = bench and bench.position
    local util = ctx and ctx.util
    if not (center and util and util.vector3) then return {} end

    local positions = {}
    local profileSlots = profile and profile.slots or nil
    local desiredSlots = math.max(1, #(profileSlots or {}))
    local longAxis = orientation and orientation.longAxis or ctx.objectRightDirection(bench)
    local minT = orientation and tonumber(orientation.min) or nil
    local maxT = orientation and tonumber(orientation.max) or nil
    local hasMeasuredSpan = (orientation and tonumber(orientation.hits) or 0) > 0 and minT ~= nil and maxT ~= nil and maxT > minT
    local measuredLength = tonumber(length) or 0
    if hasMeasuredSpan and desiredSlots >= 2 and measuredLength < 128 then
        local legacy = orientation and orientation.legacy or nil
        local legacyLength = math.max(tonumber(legacy and legacy.xLength) or 0, tonumber(legacy and legacy.yLength) or 0)
        if legacyLength >= 110 then
            hasMeasuredSpan = false
            measuredLength = math.max(legacyLength, 160)
            debugLog(ctx, "bench measured span undersampled; using explicit two-slot span", "object", tostring(bench and bench.recordId), "measured", tostring(length), "legacy", tostring(legacyLength), "slots", tostring(desiredSlots))
        end
    end
    local slotCount = math.min(math.max(1, desiredSlots), 3)
    if hasMeasuredSpan then
        if measuredLength < 128 then
            if desiredSlots >= 2 then
                hasMeasuredSpan = false
                measuredLength = 160
                slotCount = math.min(slotCount, 2)
                debugLog(ctx, "bench explicit slots using fallback span", "object", tostring(bench and bench.recordId), "measured", tostring(length), "profileSlots", tostring(desiredSlots), "span", tostring(measuredLength))
            else
                slotCount = 1
            end
        elseif measuredLength < 176 then
            slotCount = math.min(slotCount, 2)
        end
    end
    if orientation then
        orientation.singleSeatBench = slotCount == 1
    end
    local usableLength = math.max(measuredLength, slotCount >= 2 and 160 or 80)
    if not hasMeasuredSpan then
        minT = -usableLength / 2
        maxT = usableLength / 2
    end
    positions = buildPositions(util, center, longAxis, minT, maxT, zLevel, slotCount)

    if #positions >= 2 then
        local closest = closestDistance(positions)
        if closest and closest < MIN_BENCH_SLOT_SEPARATION and desiredSlots < 2 then
            positions = buildPositions(util, center, longAxis, (minT + maxT) / 2, (minT + maxT) / 2, zLevel, 1)
            if orientation then orientation.singleSeatBench = true end
            debugLog(ctx, "bench slots collapsed short span", "object", tostring(bench and bench.recordId), "closest", tostring(closest), "minimum", tostring(MIN_BENCH_SLOT_SEPARATION), "length", tostring(length))
        elseif closest and closest < MIN_BENCH_SLOT_SEPARATION then
            local safeSpan = math.max(slotCount == 2 and 160 or 240, MIN_BENCH_SLOT_SEPARATION * slotCount)
            minT = -safeSpan / 2
            maxT = safeSpan / 2
            positions = buildPositions(util, center, longAxis, minT, maxT, zLevel, slotCount)
            if orientation then orientation.singleSeatBench = false end
            debugLog(ctx, "bench explicit slots widened from tight sampled spacing", "object", tostring(bench and bench.recordId), "closest", tostring(closest), "minimum", tostring(MIN_BENCH_SLOT_SEPARATION), "length", tostring(length), "profileSlots", tostring(desiredSlots), "span", tostring(safeSpan))
        end
    end

    debugLog(ctx, "bench slot count computed", "object", tostring(bench and bench.recordId), "length", tostring(length), "profileSlots", tostring(desiredSlots), "slots", tostring(#positions), "span", tostring(minT) .. ":" .. tostring(maxT), "measured", tostring(hasMeasuredSpan), "singleSeat", tostring(orientation and orientation.singleSeatBench == true))
    if #positions >= 2 then
        debugLog(ctx, "bench multi slot allowed", "object", tostring(bench and bench.recordId), "length", tostring(length), "slots", tostring(#positions))
    else
        debugLog(ctx, "bench single slot due to explicit profile", "object", tostring(bench and bench.recordId), "length", tostring(length))
    end
    for i, pos in ipairs(positions) do
        local localLabel = i == 1 and "seat_a" or (i == 2 and "seat_b" or "seat_c")
        debugLog(ctx, "bench slot positions local", "object", tostring(bench and bench.recordId), "slot", localLabel, "world", tostring(pos), "axis", tostring(orientation and orientation.label))
    end
    return positions
end

return M
