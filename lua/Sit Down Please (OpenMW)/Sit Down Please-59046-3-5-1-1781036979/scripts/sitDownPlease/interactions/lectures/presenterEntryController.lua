-- interactions/lectures/presenterEntryController.lua
---@omw-context none
-- Local-script controller for smooth presenter station entry and deferred animation.

local presenterEntry = require('scripts/sitDownPlease/interactions/lectures/presenterEntry')

local M = {}

function M.create(ctx)
    ctx = ctx or {}
    local entry = nil
    local pendingAnimation = nil
    local dialogueActive = false
    local dialogueHoldUntil = 0
    local dialogueFacingRestoreUntil = 0
    local lastSuppressedTraceAt = -999

    local controller = {}

    function controller.active()
        return presenterEntry.active(entry)
    end

    function controller.onStationAssigned(data)
        local now = ctx.now and ctx.now() or 0
        entry = presenterEntry.start(ctx.actor and ctx.actor() or nil, data, now, ctx.util)
        if entry and ctx.trace then
            ctx.trace(
                "presenter_entry_smooth_started",
                "object", tostring(data and data.objectId),
                "slot", tostring(data and data.slotKey),
                "distance", tostring(entry.distance),
                "duration", tostring(entry.duration)
            )
        end
        if entry and data and data.lectureAnimation then
            pendingAnimation = data.lectureAnimation
            if ctx.trace then
                ctx.trace(
                    "presenter_animation_deferred",
                    "reason", "presenter_entry_smooth",
                    "session", tostring(data.lectureSessionId or data.slotKey),
                    "object", tostring(data.objectId)
                )
            end
            return true
        end
        return false
    end

    function controller.onLectureAnimationRefresh(data)
        if not presenterEntry.active(entry) then return false end
        pendingAnimation = data
        if ctx.trace then
            ctx.trace(
                "presenter_animation_deferred",
                "reason", "presenter_entry_smooth",
                "session", tostring(data and data.sessionId),
                "object", tostring(data and data.objectId)
            )
        end
        return true
    end

    function controller.onDialogueStarted(duration)
        local now = ctx.now and ctx.now() or 0
        dialogueActive = true
        dialogueHoldUntil = now + (tonumber(duration) or 5)
        dialogueFacingRestoreUntil = 0
        if ctx.trace then
            ctx.trace("presenter_hold_suppressed", "reason", "dialogue_started", "until", tostring(dialogueHoldUntil))
        end
    end

    function controller.onDialogueStopped(grace)
        local now = ctx.now and ctx.now() or 0
        dialogueActive = false
        local hold = tonumber(grace) or 1.5
        dialogueHoldUntil = now + hold
        dialogueFacingRestoreUntil = dialogueHoldUntil + 6
        if ctx.trace then
            ctx.trace("presenter_hold_suppressed", "reason", "dialogue_stopped_grace", "until", tostring(dialogueHoldUntil))
        end
    end

    function controller.holdSuppressed(reason)
        local now = ctx.now and ctx.now() or 0
        local suppressed = dialogueActive == true or now <= (tonumber(dialogueHoldUntil) or 0)
        if suppressed and ctx.trace and now - lastSuppressedTraceAt >= 1.5 then
            lastSuppressedTraceAt = now
            ctx.trace("presenter_hold_suppressed", "reason", tostring(reason or "station_hold"), "until", tostring(dialogueHoldUntil))
        end
        return suppressed
    end

    function controller.consumeDialogueFacingRestore(reason)
        local now = ctx.now and ctx.now() or 0
        if dialogueActive == true or now <= (tonumber(dialogueHoldUntil) or 0) then return false end
        if now > (tonumber(dialogueFacingRestoreUntil) or 0) then return false end
        dialogueFacingRestoreUntil = 0
        if ctx.trace then
            ctx.trace("presenter_facing_restore_after_dialogue", "reason", tostring(reason or "station_hold_rotation"))
        end
        return true
    end

    function controller.process(dt)
        if not presenterEntry.active(entry) then return false end
        if controller.holdSuppressed("presenter_entry_dialogue") then return true end
        local active, completed = presenterEntry.step(entry, dt, {
            requestPose = function(pos, yaw, reason, options)
                return ctx.requestPose and ctx.requestPose(pos, yaw, reason, options)
            end,
        })
        if completed then
            if ctx.trace then
                local assignment = ctx.currentAssignment and ctx.currentAssignment() or nil
                ctx.trace(
                    "presenter_entry_smooth_complete",
                    "object", tostring(assignment and assignment.objectId),
                    "slot", tostring(assignment and assignment.slotKey)
                )
            end
            entry = nil
            if ctx.markPoseRestoreNow then ctx.markPoseRestoreNow(ctx.now and ctx.now() or 0) end
            if pendingAnimation and ctx.startPresenterAnimation then
                local payload = pendingAnimation
                pendingAnimation = nil
                ctx.startPresenterAnimation(payload)
            end
        end
        return active == true
    end

    function controller.clear()
        entry = nil
        pendingAnimation = nil
        dialogueActive = false
        dialogueHoldUntil = 0
        dialogueFacingRestoreUntil = 0
        lastSuppressedTraceAt = -999
    end

    return controller
end

return M
