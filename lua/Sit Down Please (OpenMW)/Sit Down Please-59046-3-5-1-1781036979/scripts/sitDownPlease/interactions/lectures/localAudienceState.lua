-- interactions/lectures/localAudienceState.lua
---@omw-context none
-- Per-actor local lecture-audience state used to bridge sitting animation start
-- to the global lecture session without losing the presenter station key.

local audiencePrimitives = require('scripts/sitDownPlease/interactions/audience')

local M = {}

function M.create()
    local state = {
        target = false,
        sessionId = nil,
        stationSlotKey = nil,
    }

    local controller = {}

    function controller.resetFromAssignment(data)
        state.target = data and data.lectureAudienceTarget == true or false
        state.sessionId = data and (data.lectureSessionId or data.stationSlotKey) or nil
        state.stationSlotKey = data and data.stationSlotKey or nil
        audiencePrimitives.resetSeatedNotification()
    end

    function controller.applyTransition(data)
        state.target = true
        state.sessionId = data and (data.lectureSessionId or data.stationSlotKey) or state.sessionId
        state.stationSlotKey = data and data.stationSlotKey or state.stationSlotKey
    end

    function controller.clear()
        state.target = false
        state.sessionId = nil
        state.stationSlotKey = nil
    end

    function controller.target()
        return state.target == true
    end

    function controller.sessionId()
        return state.sessionId
    end

    function controller.notifySeated(ctx, data)
        ctx = ctx or {}
        return audiencePrimitives.notifySeated({
            core = ctx.core,
            debugLog = ctx.debugLog,
            trace = ctx.trace,
            eventName = "SitDownPleaseLectureAudienceSeated",
            traceTag = "audience_seated_notified",
            npc = ctx.npc,
            interactionType = ctx.interactionType,
            audienceTarget = state.target == true,
            audienceKey = data and data.stationSlotKey or state.stationSlotKey,
            stationSlotKey = data and data.stationSlotKey or state.stationSlotKey,
            lectureSessionId = data and data.lectureSessionId or state.sessionId,
            sessionId = data and data.lectureSessionId or state.sessionId,
            objectId = ctx.objectId,
            slotName = ctx.slotName,
            slotKey = ctx.slotKey,
        })
    end

    return controller
end

return M
