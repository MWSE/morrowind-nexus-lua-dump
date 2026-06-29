-- Rescue actors left on sleep furniture after a hidden initial-placement reject.
---@omw-context global

local M = {}

local function vectorOk(pos)
    local ok, x, y, z = pcall(function()
        return pos and pos.x, pos and pos.y, pos and pos.z
    end)
    return ok and x ~= nil and y ~= nil and z ~= nil
end

local function distance(a, b)
    if not (a and b) then return nil end
    local ok, value = pcall(function() return (a - b):length() end)
    if ok then return value end
    return nil
end

local function horizontalDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end

local function positionLooksLikeRejectedSleepSurface(ev, pos)
    if not vectorOk(pos) then return true end
    local objectPos = ev and ev.object and ev.object.position or nil
    local finalPos = ev and ev.finalPosition or nil
    local nearObject = objectPos and horizontalDistance(pos, objectPos) or nil
    if nearObject and nearObject <= 280 then
        if objectPos and pos.z and objectPos.z and pos.z > objectPos.z - 18 then return true end
        if finalPos and pos.z and finalPos.z and pos.z > finalPos.z - 12 then return true end
    end
    return false
end

local function addCandidate(list, ev, pos, rotation, label)
    if not vectorOk(pos) then return end
    if positionLooksLikeRejectedSleepSurface(ev, pos) then return end
    for _, item in ipairs(list) do
        local dist = distance(item.position, pos)
        if dist and dist < 8 then return end
    end
    list[#list + 1] = {
        position = pos,
        rotation = rotation,
        label = label or "candidate",
    }
end

local function recordOrigin(ctx, record, fallbackRotation)
    if not (ctx and ctx.loadVector and record) then return nil, nil end
    local pos = ctx.loadVector(record.origin)
    local rot = fallbackRotation
    if record.originYaw ~= nil and ctx.rotationFromYaw then
        rot = ctx.rotationFromYaw(tonumber(record.originYaw), fallbackRotation)
    end
    return pos, rot
end

local function candidateOrigin(candidate, fallbackRotation)
    if not candidate then return nil, nil end
    return candidate.preInteractionPos or candidate.originPosition, candidate.preInteractionRot or candidate.originRotation or fallbackRotation
end

function M.rescue(ctx, ev, opts)
    if not (ev and ev.initialPlacement == true and ev.interactionType == "sleeping") then return false end
    local npc = ev.npc
    if not (npc and npc.cell and ctx and ctx.tryTeleport) then return false end

    opts = opts or {}
    local candidates = {}
    local fallbackRotation = ev.preInteractionRot or npc.rotation

    addCandidate(candidates, ev, ev.rescuePosition, fallbackRotation, "local_floor_rescue")

    local savedPos, savedRot = recordOrigin(ctx, opts.savedOrigin, fallbackRotation)
    addCandidate(candidates, ev, savedPos, savedRot, "saved_origin")

    local home = opts.homeOrigin
    addCandidate(candidates, ev, home and home.position, home and home.rotation or fallbackRotation, "home_origin")

    local handoffPos, handoffRot = candidateOrigin(opts.handoffCandidate, fallbackRotation)
    addCandidate(candidates, ev, handoffPos, handoffRot, "handoff_origin")

    addCandidate(candidates, ev, ev.preInteractionPos, ev.preInteractionRot or fallbackRotation, "local_origin")
    addCandidate(candidates, ev, ev.sleepRouteNavPos, fallbackRotation, "route_nav")
    addCandidate(candidates, ev, ev.sleepRouteApproachPos or ev.approachPos, fallbackRotation, "route_approach")

    local lastErr = nil
    for _, item in ipairs(candidates) do
        local ok, err = ctx.tryTeleport(npc, npc.cell, item.position, {
            rotation = item.rotation or fallbackRotation or npc.rotation,
            onGround = true,
        })
        if ok then
            if ctx.debugLog then
                ctx.debugLog(
                    "sleep initial reject rescue placed",
                    npc.recordId or npc.id,
                    "reason", tostring(ev.reason),
                    "object", tostring(ev.objectId),
                    "slot", tostring(ev.slotName),
                    "target", tostring(item.label),
                    "position", tostring(item.position)
                )
            end
            return true, item.label
        end
        lastErr = err
    end

    if ctx.debugLog then
        ctx.debugLog(
            "sleep initial reject rescue failed",
            npc.recordId or npc.id,
            "reason", tostring(ev.reason),
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName),
            "candidates", tostring(#candidates),
            "error", tostring(lastErr)
        )
    end
    return false, lastErr
end

return M
