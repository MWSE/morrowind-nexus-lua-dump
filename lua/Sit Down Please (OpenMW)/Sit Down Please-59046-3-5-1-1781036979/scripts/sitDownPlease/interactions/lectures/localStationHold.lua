-- interactions/lectures/localStationHold.lua
---@omw-context none
-- NPC-local station pose maintenance for presenters and other station actors.

local M = {}

local HOLD_TICK_SECONDS = 0.5
local HOLD_POSE_RESTORE_DEBOUNCE_SECONDS = 2.0
local ROTATION_RESTORE_DEBOUNCE_SECONDS = 1.0
local DIALOGUE_ROTATION_RESTORE_DEBOUNCE_SECONDS = 0.25
local LECTERN_ROTATION_ONLY_DISTANCE = 128
local DEFAULT_ROTATION_ONLY_DISTANCE = 64
local FALLBACK_ATTEMPTS = 2
local FALLBACK_MAX_DISTANCE = 160
local FALLBACK_OBJECT_RADIUS = 96
local FALLBACK_STABLE_DELTA = 8
local YAW_SKIP_TRACE_INTERVAL_SECONDS = 8

local function actor(ctx)
    if ctx and type(ctx.actor) == "function" then return ctx.actor() end
    return ctx and ctx.actor or nil
end

local function controls(ctx)
    if ctx and type(ctx.controls) == "function" then return ctx.controls() end
    return ctx and ctx.controls or nil
end

local function assignment(ctx)
    if ctx and type(ctx.currentAssignment) == "function" then return ctx.currentAssignment() end
    return ctx and ctx.currentAssignment or nil
end

local function presenterEntryController(ctx)
    if ctx and type(ctx.presenterEntryController) == "function" then return ctx.presenterEntryController() end
    return ctx and ctx.presenterEntryController or nil
end

local function presenterAnimationState(ctx)
    if ctx and type(ctx.presenterAnimationState) == "function" then return ctx.presenterAnimationState() end
    return ctx and ctx.presenterAnimationState or nil
end

local function now(ctx)
    if ctx and type(ctx.now) == "function" then return ctx.now() end
    return 0
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function trace(ctx, tag, ...)
    if ctx and ctx.trace then ctx.trace(tag, ...) end
end

local function activeAssignment(ctx)
    local current = assignment(ctx)
    if current and current.active == true then return current end
    return nil
end

local function releaseCurrent(ctx, reason)
    if ctx and ctx.releaseStation then
        ctx.releaseStation({ reason = reason })
    end
end

local function cancelCurrent(ctx, reason)
    local npc = actor(ctx)
    if not (ctx and ctx.sendGlobalEvent and npc) then return end
    ctx.sendGlobalEvent('CancelInteractionForNpc', {
        npc = npc,
        npcId = npc.id,
        recordId = npc.recordId,
        reason = reason,
    })
end

function M.create(ctx)
    ctx = ctx or {}
    local state = {
        holdTimer = 0,
        lastPoseRestoreAt = 0,
        lastRotationRequestAt = 0,
        lastLectureYawSkipAt = 0,
    }
    local controller = { state = state }

    function controller.rotationFromYaw(yaw, fallback)
        if type(yaw) == "number" and ctx.util then return ctx.util.transform.rotateZ(yaw) end
        return fallback
    end

    function controller.yawFromDirection(fromPos, toPos, fallbackYaw)
        if not (fromPos and toPos) then return fallbackYaw end
        local dx = (toPos.x or 0) - (fromPos.x or 0)
        local dy = (toPos.y or 0) - (fromPos.y or 0)
        if math.sqrt(dx * dx + dy * dy) <= 1 then return fallbackYaw end
        return math.atan2(dx, dy)
    end

    function controller.currentActorYaw()
        local npc = actor(ctx)
        if not (npc and npc.rotation) then return nil end
        local ok, yaw = pcall(function() return npc.rotation:getYaw() end)
        return ok and yaw or nil
    end

    function controller.yawDifference(a, b)
        if type(a) ~= "number" or type(b) ~= "number" then return math.huge end
        local diff = (a - b) % (math.pi * 2)
        if diff > math.pi then diff = diff - (math.pi * 2) end
        return math.abs(diff)
    end

    function controller.requestPoseRestore(pos, yaw, reason, options)
        local current = activeAssignment(ctx)
        local npc = actor(ctx)
        if not (current and npc and ctx.sendGlobalEvent) then return false end
        local presenterEntry = presenterEntryController(ctx)
        if presenterEntry and presenterEntry.holdSuppressed
            and presenterEntry.holdSuppressed(reason or "station_pose_restore") then
            return false
        end
        local ok, err = pcall(function()
            ctx.sendGlobalEvent("SitDownPleaseStationPoseRequest", {
                npc = npc,
                objectId = current.objectId,
                slotKey = current.slotKey,
                finalPosition = pos,
                finalRotation = yaw,
                reason = reason,
                smoothDuration = options and options.smoothDuration or nil,
            })
        end)
        if not ok then
            debugLog(ctx, "station pose request failed", tostring(reason or "station"), tostring(err))
            return false
        end
        return true
    end

    function controller.rotateActor(yaw, reason)
        local current = activeAssignment(ctx)
        if not (current and type(yaw) == "number") then return false end
        local presenterEntry = presenterEntryController(ctx)
        if presenterEntry and presenterEntry.holdSuppressed
            and presenterEntry.holdSuppressed(reason or "station_rotation") then
            return false
        end
        local currentTime = now(ctx)
        local currentYaw = controller.currentActorYaw()
        local stationHoldRotation = reason == "station_hold_rotation"
        local animationState = presenterAnimationState(ctx)
        local presenterAnimationActive = stationHoldRotation
            and animationState
            and animationState.active == true
        local diff = currentYaw and controller.yawDifference(currentYaw, yaw) or nil
        local restoreAfterDialogue = stationHoldRotation
            and diff
            and diff > math.rad(5)
            and presenterEntry
            and presenterEntry.consumeDialogueFacingRestore
            and presenterEntry.consumeDialogueFacingRestore(reason or "station_hold_rotation")
        local lecturePresenterActive = presenterAnimationActive == true and restoreAfterDialogue ~= true
        local restoreReason = reason or "station_rotation"
        local restoreOptions = nil
        if restoreAfterDialogue == true then
            restoreReason = "station_dialogue_facing_restore"
            restoreOptions = { smoothDuration = 1.15 }
        end
        if lecturePresenterActive then
            if diff and diff > math.rad(5) and currentTime - (state.lastLectureYawSkipAt or 0) >= YAW_SKIP_TRACE_INTERVAL_SECONDS then
                state.lastLectureYawSkipAt = currentTime
                trace(
                    ctx,
                    "presenter_yaw_hold_skipped",
                    "reason", "presenter_animation_active",
                    "diffDeg", tostring(diff * 180 / math.pi),
                    "targetYaw", tostring(yaw)
                )
            end
            return false
        end
        if diff and diff <= math.rad(5) then return false end
        local debounce = restoreAfterDialogue == true and DIALOGUE_ROTATION_RESTORE_DEBOUNCE_SECONDS or ROTATION_RESTORE_DEBOUNCE_SECONDS
        if currentTime - (state.lastRotationRequestAt or 0) < debounce then return false end
        state.lastRotationRequestAt = currentTime
        local npc = actor(ctx)
        if controller.requestPoseRestore(npc and npc.position or nil, yaw, restoreReason, restoreOptions) then
            debugLog(ctx, "station rotation requested", tostring(restoreReason), "yaw", tostring(yaw))
            trace(ctx, "presenter_facing_hold_applied", "reason", tostring(restoreReason), "yaw", tostring(yaw), "diffDeg", tostring(diff and diff * 180 / math.pi or nil), "smooth", tostring(restoreAfterDialogue == true))
            return true
        end
        return false
    end

    function controller.markPoseRestoreNow(currentTime)
        currentTime = tonumber(currentTime) or now(ctx)
        state.lastPoseRestoreAt = currentTime
        state.lastRotationRequestAt = currentTime
    end

    function controller.resetHoldTimers(currentTime)
        currentTime = tonumber(currentTime) or now(ctx)
        state.holdTimer = 0
        state.lastPoseRestoreAt = currentTime
        state.lastRotationRequestAt = currentTime
    end

    function controller.clear()
        state.holdTimer = 0
        state.lastPoseRestoreAt = 0
        state.lastRotationRequestAt = 0
        state.lastLectureYawSkipAt = 0
    end

    function controller.stationTravelMatches(pkgDest, radius)
        local current = activeAssignment(ctx)
        if not current then return false end
        local currentTime = now(ctx)
        if current.travelGraceUntil and currentTime <= current.travelGraceUntil then
            return true
        end
        if not pkgDest then return false end
        local finalPosition = current.finalPosition
        return finalPosition and (pkgDest - finalPosition):length() < (radius or 220) or false
    end

    function controller.maintain(dt)
        local presenterEntry = presenterEntryController(ctx)
        if presenterEntry and presenterEntry.active and presenterEntry.active() then return end
        if presenterEntry and presenterEntry.holdSuppressed
            and presenterEntry.holdSuppressed("station_maintenance") then return end

        local current = activeAssignment(ctx)
        if not (current and not (ctx.interactionActive and ctx.interactionActive())) then return end

        local dangerReason = ctx.activeDangerReason and ctx.activeDangerReason() or nil
        if dangerReason then
            cancelCurrent(ctx, dangerReason)
            releaseCurrent(ctx, dangerReason)
            return
        end

        local followTargets = ctx.getAiTargets and ctx.getAiTargets("Follow") or nil
        local escortTargets = ctx.getAiTargets and ctx.getAiTargets("Escort") or nil
        local pkg = ctx.getActiveAiPackage and ctx.getActiveAiPackage() or nil
        local pkgType = pkg and pkg.type or nil
        local pkgDest = pkg and (pkg.destPosition or pkg.destination) or nil
        local ownStationTravel = pkgType == "Travel" and controller.stationTravelMatches(pkgDest, 220)
        if (followTargets and #followTargets > 0) or (escortTargets and #escortTargets > 0)
            or pkgType == "Follow" or pkgType == "Escort" or pkgType == "Combat" or pkgType == "Pursue"
            or (pkgType == "Travel" and not ownStationTravel)
            or (pkgType ~= nil and pkgType ~= "Wander" and pkgType ~= "Travel") then
            local reason = (pkgType == "Combat" or pkgType == "Pursue") and "combat"
                or ((followTargets and #followTargets > 0) or (escortTargets and #escortTargets > 0) or pkgType == "Follow" or pkgType == "Escort") and "follow_or_escort"
                or pkgType == "Travel" and "other_travel"
                or "other_ai_package"
            cancelCurrent(ctx, reason)
            releaseCurrent(ctx, reason)
            return
        end

        local movementControls = controls(ctx)
        if movementControls then
            movementControls.movement = 0
            movementControls.sideMovement = 0
            movementControls.yawChange = 0
        end
        if ctx.applySuppression then ctx.applySuppression() end

        state.holdTimer = (state.holdTimer or 0) + (tonumber(dt) or 0)
        if state.holdTimer < HOLD_TICK_SECONDS then return end
        state.holdTimer = 0

        local target = current.finalPosition
        local npc = actor(ctx)
        if not (target and npc and npc.position and npc.cell) then return end
        local dist = (npc.position - target):length()
        local holdRotationOnlyDistance = tostring(current.stationType or "") == "lectern" and LECTERN_ROTATION_ONLY_DISTANCE or DEFAULT_ROTATION_ONLY_DISTANCE
        if dist <= holdRotationOnlyDistance then
            current.holdRestoreAttempts = 0
            current.lastHoldRestoreDistance = nil
            controller.rotateActor(current.finalRotation, "station_hold_rotation")
            return
        end

        local currentTime = now(ctx)
        local stationObject = current.object
        local objectDist = stationObject and stationObject.position and (npc.position - stationObject.position):length() or nil
        local restoreAttempts = tonumber(current.holdRestoreAttempts) or 0
        local lastDist = tonumber(current.lastHoldRestoreDistance)
        local stableMiss = lastDist ~= nil and math.abs(dist - lastDist) <= FALLBACK_STABLE_DELTA
        if tostring(current.stationType or "") == "lectern"
            and restoreAttempts >= FALLBACK_ATTEMPTS
            and stableMiss == true
            and dist <= FALLBACK_MAX_DISTANCE
            and objectDist ~= nil
            and objectDist <= FALLBACK_OBJECT_RADIUS then
            current.finalPosition = npc.position
            current.holdRestoreAttempts = 0
            current.lastHoldRestoreDistance = nil
            current.nearLecternHoldFallback = true
            debugLog(
                ctx,
                "station hold accepted near lectern fallback",
                tostring(current.objectId),
                "distance", tostring(dist),
                "objectDistance", tostring(objectDist)
            )
            controller.rotateActor(current.finalRotation, "station_hold_rotation")
            return
        end

        if currentTime - (state.lastPoseRestoreAt or 0) < HOLD_POSE_RESTORE_DEBOUNCE_SECONDS then return end
        state.lastPoseRestoreAt = currentTime
        if controller.requestPoseRestore(target, current.finalRotation, "station_hold_position") then
            current.holdRestoreAttempts = restoreAttempts + 1
            current.lastHoldRestoreDistance = dist
            debugLog(ctx, "station hold position restore requested", tostring(current.objectId), "distance", tostring(dist))
        end
    end

    return controller
end

return M
