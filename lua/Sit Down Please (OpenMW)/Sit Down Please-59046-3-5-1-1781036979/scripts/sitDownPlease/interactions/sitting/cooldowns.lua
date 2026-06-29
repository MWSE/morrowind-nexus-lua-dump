-- interactions/sitting/cooldowns.lua
---@omw-context none
local module = {}

function module.new()
    return {
        normal = {},
        animationReject = {},
        localReject = {},
    }
end

local function actorKey(npc)
    if not (npc and npc.id) then return nil end
    return npc.id
end

local function actorSlotKey(npc, slotKey)
    local key = actorKey(npc)
    if not (key and slotKey) then return nil end
    return tostring(key) .. "|" .. tostring(slotKey)
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

function module.isRetryableLocalReject(reason)
    reason = tostring(reason or "")
    return reason == "tight_table_or_counter_rejected"
        or reason == "clearance_blocked_by_object"
        or reason == "seat_surface_blocked_by_item"
        or reason == "no_safe_sitting_stand_exit"
        or reason == "collision_or_raycast_validation_failed"
        or reason == "initial_sitting_vertical_rejected"
end

function module.setLocalReject(state, core, npc, slotKey, seconds, debugLog, reason)
    local key = actorSlotKey(npc, slotKey)
    if not key then return end
    seconds = tonumber(seconds or 75) or 75
    if seconds <= 0 then return end
    state.localReject[key] = core.getSimulationTime() + seconds
    if debugLog then debugLog("sitting local reject cooldown", npc.recordId or npc.id, tostring(reason or "local_reject"), "slot", tostring(slotKey), "seconds", tostring(seconds)) end
end

function module.isLocalRejectActive(state, core, npc, slotKey)
    local key = actorSlotKey(npc, slotKey)
    if not key then return false end
    local untilTime = state.localReject[key]
    if not untilTime then return false end
    if core.getSimulationTime() >= untilTime then
        state.localReject[key] = nil
        return false
    end
    return true
end

return module
