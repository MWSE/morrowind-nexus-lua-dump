-- interactions/lectures/audienceTransitionBridge.lua
---@omw-context none
-- Coordinator-facing bridge for seated-to-lecture-audience transitions.

local audienceTransition = require('scripts/sitDownPlease/interactions/lectures/audienceTransition')

local M = {}

function M.create(ctx)
    ctx = ctx or {}
    local bridge = {}

    function bridge.transitionSeated(npc, data, stationData, options)
        local assignedActors = type(ctx.assignedActors) == "function" and ctx.assignedActors() or ctx.assignedActors
        return audienceTransition.transitionSeated(npc, data, stationData, {
            assignedActors = assignedActors,
            interactingState = ctx.interactingState,
            transitioningState = ctx.transitioningState,
            scheduleLifecycle = ctx.scheduleLifecycle,
            slotClaimedByOther = ctx.slotClaimedByOther,
            claimOccupiedSlot = ctx.claimOccupiedSlot,
            noteAudienceMember = ctx.noteAudienceMember,
            trace = ctx.trace,
            sendTransitionEvent = ctx.sendTransitionEvent,
        }, options or {})
    end

    function bridge.clear(data)
        return audienceTransition.clear(data)
    end

    return bridge
end

return M
