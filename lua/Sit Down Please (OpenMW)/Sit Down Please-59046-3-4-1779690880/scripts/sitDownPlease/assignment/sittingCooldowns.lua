local module = {}

function module.new()
    return {
        normal = {},
        animationReject = {},
    }
end

local function actorKey(npc)
    if not (npc and npc.id) then return nil end
    return npc.id
end

function module.setNormal(state, core, npc, seconds, defaultSeconds, debugLog, reason)
    local key = actorKey(npc)
    if not key then return end
    seconds = tonumber(seconds or defaultSeconds) or tonumber(defaultSeconds) or 0
    if seconds <= 0 then return end
    state.normal[key] = core.getSimulationTime() + seconds
    if debugLog then debugLog("sitting cooldown", npc.recordId or npc.id, tostring(reason or "cooldown"), "seconds", tostring(seconds)) end
end

function module.isNormalActive(state, core, npc)
    local key = actorKey(npc)
    if not key then return false end
    local untilTime = state.normal[key]
    if not untilTime then return false end
    if core.getSimulationTime() >= untilTime then
        state.normal[key] = nil
        return false
    end
    return true
end

function module.setAnimationReject(state, core, npc, seconds, debugLog, reason)
    local key = actorKey(npc)
    if not key then return end
    seconds = tonumber(seconds or 1800) or 1800
    if seconds <= 0 then return end
    state.animationReject[key] = core.getSimulationTime() + seconds
    if debugLog then debugLog("sitting animation reject cooldown", npc.recordId or npc.id, tostring(reason or "missing_animation"), "seconds", tostring(seconds)) end
end

function module.isAnimationRejectActive(state, core, npc)
    local key = actorKey(npc)
    if not key then return false end
    local untilTime = state.animationReject[key]
    if not untilTime then return false end
    if core.getSimulationTime() >= untilTime then
        state.animationReject[key] = nil
        return false
    end
    return true
end

return module
