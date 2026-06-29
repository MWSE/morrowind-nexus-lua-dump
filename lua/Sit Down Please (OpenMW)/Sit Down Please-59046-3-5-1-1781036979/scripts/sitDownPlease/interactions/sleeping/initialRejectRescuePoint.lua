-- Local-script floor/navmesh rescue point selection for rejected initial sleep placement.
---@omw-context local

local M = {}

function M.position(ctx, data, reason)
    if not (data and data.initialPlacement == true and data.interactionType == "sleeping") then return nil end
    if not (ctx and ctx.currentObject and ctx.nearby and ctx.nearby.NAVIGATOR_FLAGS) then return nil end

    local currentObject = ctx.currentObject()
    if not (currentObject and currentObject.position) then return nil end

    local reasonText = tostring(reason or "")
    if reasonText == "missing_animation" or reasonText:find("active_", 1, true) == 1 then return nil end

    local objectPos = currentObject.position
    local finalPos = data.finalPosition or (ctx.currentFinalPosition and ctx.currentFinalPosition())
    local flags = ctx.nearby.NAVIGATOR_FLAGS
    local includeFlags = (flags.Walk or 0) + (flags.UsePathgrid or 0)
    local offsets = {
        { name = "rescue_left", x = -170, y = 0, z = 0 },
        { name = "rescue_right", x = 170, y = 0, z = 0 },
        { name = "rescue_foot", x = 0, y = -170, z = 0 },
        { name = "rescue_head", x = 0, y = 170, z = 0 },
        { name = "rescue_foot_left", x = -145, y = -145, z = 0 },
        { name = "rescue_foot_right", x = 145, y = -145, z = 0 },
        { name = "rescue_head_left", x = -145, y = 145, z = 0 },
        { name = "rescue_head_right", x = 145, y = 145, z = 0 },
        { name = "rescue_left_far", x = -230, y = 0, z = 0 },
        { name = "rescue_right_far", x = 230, y = 0, z = 0 },
    }

    local best, bestScore, bestName = nil, nil, nil
    for _, offset in ipairs(offsets) do
        local raw = ctx.projectedObjectOffset and ctx.projectedObjectOffset(offset) or nil
        local navPos, navReason, navDelta = nil, nil, nil
        if raw and ctx.nearestWalkNavmeshPosition then
            navPos, navReason, navDelta = ctx.nearestWalkNavmeshPosition(raw, includeFlags, 190, 54)
        end
        if navPos then
            local belowObject = navPos.z and objectPos.z and navPos.z <= objectPos.z - 18
            local belowFinal = not finalPos or not (navPos.z and finalPos.z) or navPos.z <= finalPos.z - 12
            if belowObject and belowFinal then
                local actor = ctx.selfObject and ctx.selfObject() or nil
                local actorDist = actor and actor.position and (actor.position - navPos):length() or 0
                local objectDist = (objectPos - navPos):length()
                local score = objectDist + (actorDist * 0.2) + (tonumber(navDelta) or 0)
                if not bestScore or score < bestScore then
                    best, bestScore, bestName = navPos, score, offset.name
                end
            elseif ctx.settings and ctx.settings.debug == true and ctx.debugLog then
                ctx.debugLog(
                    "sleep initial reject rescue candidate skipped",
                    "object", tostring(currentObject and currentObject.recordId),
                    "slot", tostring(ctx.currentSlotName and ctx.currentSlotName()),
                    "name", tostring(offset.name),
                    "pos", tostring(navPos),
                    "navReason", tostring(navReason),
                    "belowObject", tostring(belowObject),
                    "belowFinal", tostring(belowFinal)
                )
            end
        end
    end

    if best and ctx.settings and ctx.settings.debug == true and ctx.debugLog then
        ctx.debugLog(
            "sleep initial reject rescue floor candidate",
            "object", tostring(currentObject and currentObject.recordId),
            "slot", tostring(ctx.currentSlotName and ctx.currentSlotName()),
            "name", tostring(bestName),
            "pos", tostring(best),
            "reason", tostring(reason)
        )
    end

    return best
end

return M
