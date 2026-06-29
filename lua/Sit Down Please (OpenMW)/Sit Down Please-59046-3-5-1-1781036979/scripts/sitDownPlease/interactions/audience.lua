-- interactions/audience.lua
---@omw-context none
-- Shared audience/crowd timing primitives for interaction-specific modules.

local M = {}
local lastSeatedNotificationKey = nil

local function stableUnit(ctx, key)
    local profiles = ctx and ctx.profiles or nil
    if profiles and profiles.stableUnitInterval then
        return profiles.stableUnitInterval(tostring(key))
    end
    return 0.5
end

local function actorKey(npc)
    return tostring(npc and (npc.recordId or npc.id) or "<npc>")
end

function M.joinDelay(ctx, npc, slotKey, options)
    options = options or {}
    local unit = stableUnit(ctx, actorKey(npc) .. "::" .. tostring(slotKey) .. "::audience_join_delay")
    local index = tonumber(options.index) or 1
    local stagger = math.max(0, index - 1) * 0.12
    if options.initialPlacement == true then
        return unit * 0.7 + stagger
    end
    if options.fromExistingSeat == true then
        if index <= 2 then return 0.05 + unit * 0.45 + stagger end
        return 0.25 + unit * 2.2 + stagger
    end
    if index <= 2 then return 0.12 + unit * 0.65 + stagger end
    return 0.45 + unit * 3.5 + stagger
end

function M.releaseDelay(ctx, npc, slotKey, index)
    local unit = stableUnit(ctx, actorKey(npc) .. "::" .. tostring(slotKey) .. "::audience_leave_delay")
    return 1.0 + unit * 8.0 + math.max(0, (tonumber(index) or 1) - 1) * 0.35
end

function M.chanceAllows(ctx, npc, slotKey, chanceKey, stableSuffix)
    local settings = ctx and ctx.settings or {}
    local chance = tonumber(settings and settings[chanceKey])
    if chance == nil then chance = 0.55 end
    if chanceKey == "stationLecternAudienceChance" and chance == 0.55 then chance = 0.70 end
    if chance >= 1 then return true, chance, 0 end
    if chance <= 0 then return false, chance, 1 end
    local unit = stableUnit(ctx, actorKey(npc) .. "::" .. tostring(slotKey) .. "::" .. tostring(stableSuffix or "audience"))
    return unit <= chance, chance, unit
end

function M.resetSeatedNotification()
    lastSeatedNotificationKey = nil
end

function M.notifySeated(ctx)
    if not (ctx and ctx.interactionType == "sitting" and ctx.audienceTarget == true) then return false end
    local core = ctx.core
    local eventName = tostring(ctx.eventName or "")
    if not (eventName ~= "" and core and core.sendGlobalEvent) then return false end
    local audienceKey = ctx.audienceKey
    if not audienceKey then return false end
    local notifyKey = tostring(audienceKey) .. "::" .. tostring(ctx.sessionId or "") .. "::" .. tostring(ctx.slotKey or "")
    if lastSeatedNotificationKey == notifyKey then return false end
    lastSeatedNotificationKey = notifyKey

    core.sendGlobalEvent(eventName, {
        npc = ctx.npc,
        audienceKey = audienceKey,
        stationSlotKey = ctx.stationSlotKey or audienceKey,
        lectureSessionId = ctx.lectureSessionId or ctx.sessionId,
        sessionId = ctx.sessionId,
        objectId = ctx.objectId,
        slotName = ctx.slotName,
        slotKey = ctx.slotKey,
    })

    if ctx.trace and ctx.debugLog then
        ctx.trace(
            ctx.debugLog,
            tostring(ctx.traceTag or "audience_seated_notified"),
            "audience", tostring(audienceKey),
            "slot", tostring(ctx.slotName),
            "session", tostring(ctx.sessionId)
        )
    end
    return true
end

return M
