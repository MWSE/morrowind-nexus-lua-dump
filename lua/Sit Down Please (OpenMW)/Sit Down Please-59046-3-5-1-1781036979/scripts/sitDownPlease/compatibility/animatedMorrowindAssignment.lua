-- compatibility/animatedMorrowindAssignment.lua
---@omw-context global
-- Global assignment-side controller for Animated Morrowind seated-actor alignment.

local compat = require('scripts/sitDownPlease/compatibility/animatedMorrowind')
local placementController = require('scripts/sitDownPlease/compatibility/animatedMorrowindController')

local M = {
    SETTING_KEY = compat.SETTING_KEY,
}

local function settingsFrom(ctx)
    if type(ctx.settings) == "function" then return ctx.settings() end
    return ctx.settings or {}
end

local function assignedActors(ctx)
    if type(ctx.assignedActors) == "function" then return ctx.assignedActors() end
    return ctx.assignedActors or {}
end

local function claimRejectCache(ctx)
    if type(ctx.claimRejectLogCache) == "function" then return ctx.claimRejectLogCache() end
    return ctx.claimRejectLogCache
end

function M.create(ctx)
    ctx = ctx or {}
    local state = {
        detected = false,
        detectionReason = nil,
        externalPlacementPatchDetected = false,
        externalPlacementPatchReason = nil,
        detectionLogged = false,
        activeLogged = false,
        externalPlacementPatchLogged = false,
        actorSeenLogged = {},
        checkedActors = {},
        pending = {},
        settle = {},
        retryNextAt = nil,
        retryUntil = nil,
        retryReason = nil,
        retryLogged = false,
    }

    local controller = { state = state }

    function controller.enabled()
        local settings = settingsFrom(ctx)
        return settings and settings.animatedMorrowindAlignmentAssist == true
    end

    function controller.refreshDetection(reason)
        local settings = settingsFrom(ctx)
        local detected, detectionReason = compat.detectContent(ctx.core)
        local externalPatchDetected, externalPatchReason = compat.detectExternalPlacementPatch(ctx.core)
        state.detected = detected == true
        state.detectionReason = detectionReason
        state.externalPlacementPatchDetected = externalPatchDetected == true
        state.externalPlacementPatchReason = externalPatchReason
        if state.detectionLogged ~= true then
            state.detectionLogged = true
            ctx.infoLog(
                "animated morrowind detection",
                "detected", tostring(state.detected),
                "reason", tostring(detectionReason),
                "externalPlacementPatch", tostring(state.externalPlacementPatchDetected),
                "externalPlacementPatchReason", tostring(externalPatchReason),
                "source", tostring(reason or "startup")
            )
        else
            ctx.debugLog(
                "animated morrowind detection",
                "detected", tostring(state.detected),
                "reason", tostring(detectionReason),
                "externalPlacementPatch", tostring(state.externalPlacementPatchDetected),
                "externalPlacementPatchReason", tostring(externalPatchReason),
                "source", tostring(reason or "refresh")
            )
        end
        if state.detected == true
            and state.activeLogged ~= true
            and settings and settings.animatedMorrowindAlignmentAssist == true then
            state.activeLogged = true
            ctx.infoLog(
                "animated morrowind compat active",
                "reason", tostring(detectionReason),
                "setting", tostring(settings and settings.animatedMorrowindAlignmentAssist)
            )
        end
        if state.externalPlacementPatchDetected == true
            and state.externalPlacementPatchLogged ~= true then
            state.externalPlacementPatchLogged = true
            ctx.infoLog(
                "animated morrowind external placement patch detected",
                "reason", tostring(externalPatchReason),
                "assist", "yield_for_patch_positioned_actors"
            )
        end
    end

    function controller.clearRuntime(reason)
        state.checkedActors = {}
        state.pending = {}
        state.settle = {}
        state.retryNextAt = nil
        state.retryUntil = nil
        state.retryReason = nil
        state.retryLogged = false
        if settingsFrom(ctx).debug == true then
            ctx.debugLog("animated morrowind compat runtime cleared", tostring(reason or "unknown"))
        end
    end

    local function noteSitterSeen(npc, reason)
        if not (npc and npc.id) then return end
        if state.actorSeenLogged[npc.id] then return end
        state.actorSeenLogged[npc.id] = true
        ctx.debugLog(
            "animated morrowind sitter recognized",
            npc.recordId or npc.id,
            "reason", tostring(reason),
            "contentDetected", tostring(state.detected)
        )
    end

    local function canConsiderNpc(npc)
        if controller.enabled() ~= true then return false, "setting_disabled" end
        if not (npc and npc.id and npc.position and npc.cell and ctx.types.NPC.objectIsInstance(npc)) then return false, "not_npc" end
        if not ctx.isObjValid(npc) then return false, "invalid_actor" end
        if assignedActors(ctx)[npc.id] then return false, "normal_sdp_assignment_active" end
        if state.checkedActors[npc.id] then return false, "already_checked" end
        if state.pending[npc.id] then return false, "pending" end
        local dead, deadReason = ctx.actorDeadReason(npc)
        if dead then return false, deadReason end
        local hiddenReason = ctx.hiddenOrStagedNpcReason(npc)
        if hiddenReason then return false, hiddenReason end

        if state.externalPlacementPatchDetected == true
            and compat.externalPlacementPatchOwnsActor(npc) then
            return false, "external_am_bcom_patch_positioned_actor"
        end

        local amReason = compat.knownSittingActorReason(npc)
        if not amReason then return false, "not_known_am_sitter" end
        noteSitterSeen(npc, amReason)

        if state.detected ~= true then
            state.detected = true
            state.detectionReason = "known_actor:" .. tostring(npc.recordId or npc.id)
            if state.activeLogged ~= true then
                state.activeLogged = true
                ctx.infoLog(
                    "animated morrowind compat active",
                    "reason", tostring(state.detectionReason),
                    "setting", tostring(settingsFrom(ctx).animatedMorrowindAlignmentAssist)
                )
            end
        end

        return true, amReason
    end

    local function sendRequest(npc, candidate, actorReason, source)
        if not (npc and npc.id and candidate and candidate.object) then return false, "missing_request_data" end
        local requestId = tostring(npc.id) .. ":" .. tostring(ctx.core.getSimulationTime())
        state.pending[npc.id] = {
            requestId = requestId,
            npc = npc,
            object = candidate.object,
            objectId = candidate.objectId,
            sentAt = ctx.core.getSimulationTime(),
        }
        npc:sendEvent("SitDownPleaseAnimatedMorrowindAlignmentAssist", {
            requestId = requestId,
            object = candidate.object,
            objectId = candidate.objectId,
            model = candidate.model,
            profile = candidate.profile,
            profileId = candidate.profileId,
            slot = candidate.slot,
            slotName = candidate.slotName,
            slotKey = candidate.slotKey,
            preferredFacingDirection = candidate.preferredFacingDirection,
            facingKind = candidate.facingKind,
            actorReason = actorReason,
            source = source,
        })
        ctx.debugLog(
            "animated morrowind compat request",
            npc.recordId or npc.id,
            "object", tostring(candidate.objectId),
            "profile", tostring(candidate.profileId),
            "slot", tostring(candidate.slotName),
            "source", tostring(source)
        )
        return true, nil
    end

    function controller.runPass(cell, sittingCandidates, source)
        if not cell or controller.enabled() ~= true then return end

        local compatNpcs = {}
        for _, npc in ipairs(cell:getAll(ctx.types.NPC)) do
            local canConsider, actorReason = canConsiderNpc(npc)
            if canConsider then
                compatNpcs[#compatNpcs + 1] = { npc = npc, actorReason = actorReason }
            elseif actorReason ~= "not_known_am_sitter" and actorReason ~= "already_checked" and actorReason ~= "pending" then
                ctx.debugLogOnce(
                    claimRejectCache(ctx),
                    "am_skip:" .. tostring(npc and (npc.id or npc.recordId) or "<npc>") .. ":" .. tostring(actorReason),
                    "animated morrowind compat skipped",
                    npc and (npc.recordId or npc.id) or "<npc>",
                    "reason", tostring(actorReason)
                )
            end
        end

        if #compatNpcs == 0 then return end

        local candidates = ctx.buildCandidateSlots(cell, "sitting", {
            compatPass = true,
            externalCompatibilityAssist = true,
        })
        if (not candidates or #candidates == 0) and sittingCandidates then candidates = sittingCandidates end
        if not candidates or #candidates == 0 then
            for _, item in ipairs(compatNpcs) do
                if item.npc and item.npc.id then
                    state.checkedActors[item.npc.id] = "no_sitting_candidates"
                    ctx.debugLog("animated morrowind compat skipped", item.npc.recordId or item.npc.id, "reason", "no_sitting_candidates")
                end
            end
            return
        end

        for _, item in ipairs(compatNpcs) do
            local npc = item.npc
            if npc and npc.id then
                local candidate, rejectReason, dist, vertical = compat.chooseNearbySeat(npc, candidates, ctx.profiles)
                if not candidate then
                    candidate, rejectReason, dist, vertical = compat.chooseExternalSurfaceSeat(npc, cell, {
                        isObjValid = ctx.isObjValid,
                        objectModelPath = ctx.profiles.objectModelPath,
                        objectSlotKey = ctx.objectSlotKey,
                        objectName = ctx.objectName,
                    })
                end
                if candidate then
                    sendRequest(npc, candidate, item.actorReason, source)
                else
                    state.checkedActors[npc.id] = rejectReason or "no_candidate"
                    ctx.debugLog(
                        "animated morrowind compat skipped",
                        npc.recordId or npc.id,
                        "reason", tostring(rejectReason),
                        "nearestDistance", tostring(dist),
                        "vertical", tostring(vertical)
                    )
                end
            end
        end
    end

    function controller.scheduleRetry(reason, delaySeconds, durationSeconds)
        if controller.enabled() ~= true then return end
        local now = ctx.core.getSimulationTime()
        state.retryNextAt = now + (tonumber(delaySeconds) or 0.45)
        state.retryUntil = now + (tonumber(durationSeconds) or 2.5)
        state.retryReason = reason or "retry"
        state.retryLogged = false
    end

    function controller.processRetry(lastCell)
        local retryUntil = tonumber(state.retryUntil)
        if not retryUntil then return end
        local now = ctx.core.getSimulationTime()
        if now > retryUntil then
            state.retryNextAt = nil
            state.retryUntil = nil
            state.retryReason = nil
            state.retryLogged = false
            return
        end
        if now < (tonumber(state.retryNextAt) or retryUntil) then return end

        state.retryNextAt = now + 0.55
        if state.retryLogged ~= true then
            state.retryLogged = true
            ctx.debugLog("animated morrowind compat delayed retry", tostring(state.retryReason))
        end
        controller.runPass(lastCell, nil, tostring(state.retryReason or "retry"))
    end

    function controller.onAlignmentResult(ev)
        if not (ev and ev.npc and ev.npc.id) then return end
        local npc = ev.npc
        local pending = state.pending[npc.id]
        if not pending or pending.requestId ~= ev.requestId then
            ctx.debugLog("animated morrowind compat stale result", npc.recordId or npc.id, "request", tostring(ev.requestId))
            return
        end
        state.pending[npc.id] = nil
        state.checkedActors[npc.id] = ev.skippedReason or (ev.correctionNeeded and "corrected" or "checked")

        if assignedActors(ctx)[npc.id] then
            ctx.debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "normal_sdp_assignment_active")
            return
        end
        if not ctx.isObjValid(npc) then return end

        if ev.correctionNeeded ~= true then
            ctx.debugLog(
                "animated morrowind compat skipped",
                npc.recordId or npc.id,
                "reason", tostring(ev.skippedReason or "no_correction_needed"),
                "object", tostring(ev.objectId),
                "originalZ", tostring(ev.originalZ),
                "expectedZ", tostring(ev.expectedZ),
                "delta", tostring(ev.delta)
            )
            return
        end

        local targetZ = tonumber(ev.targetZ)
        if not (targetZ and npc.position and npc.cell) then
            ctx.debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "missing_target")
            return
        end

        local currentPos = npc.position
        if pending.object and ctx.isObjValid(pending.object) and pending.object.position then
            local dist = compat.horizontalDistance(currentPos, pending.object.position)
            if dist and dist > (compat.SEAT_RADIUS + 22) then
                ctx.debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "actor_moved_from_seat", "distance", tostring(dist))
                return
            end
        end
        local newPosition = ctx.util.vector3(currentPos.x, currentPos.y, targetZ)
        local externalController = compat.externalPlacementController(npc)
        local placementControllerOk, placementControllerReason = placementController.registerExternalPlacementController(npc, newPosition, externalController)
        local yaw = 0
        local okYaw, currentYaw = pcall(function() return npc.rotation and npc.rotation:getYaw() or 0 end)
        if okYaw and currentYaw then yaw = currentYaw end
        local smoothQueued = false
        if ctx.smoothMove then
            smoothQueued = ctx.smoothMove(npc, { externalAnimatedMorrowindAlignment = true }, newPosition, yaw, "animated_morrowind_alignment_smooth", "animated_morrowind_alignment_assist", {
                skipStateCheck = true,
                duration = 0.18,
                isActive = function(candidate)
                    return ctx.isObjValid(candidate) and not assignedActors(ctx)[candidate.id]
                end,
            }) == true
        end
        local ok, err = false, nil
        if not smoothQueued then
            ok, err = ctx.tryTeleport(npc, npc.cell, newPosition, { rotation = npc.rotation })
        end
        if smoothQueued or ok or placementControllerOk == true then
            local settleAttempts, settleSeconds, settleInterval, settlePolicy = compat.settlePolicyForActor(npc)
            if (settleAttempts or 0) > 0 and (settleSeconds or 0) > 0 then
                state.settle[npc.id] = {
                    npc = npc,
                    object = pending.object,
                    objectId = ev.objectId,
                    profileId = ev.profileId,
                    targetZ = targetZ,
                    attemptsRemaining = settleAttempts,
                    interval = settleInterval,
                    policy = settlePolicy,
                    lastObservedZ = currentPos.z,
                    externalRestoreStrikes = 0,
                    nextAt = ctx.core.getSimulationTime() + 0.45,
                    expiresAt = ctx.core.getSimulationTime() + settleSeconds,
                }
            else
                state.settle[npc.id] = nil
            end
            ctx.debugLog(
                "animated morrowind compat applied",
                npc.recordId or npc.id,
                "object", tostring(ev.objectId),
                "profile", tostring(ev.profileId),
                "surface", tostring(ev.surfaceMode),
                "originalZ", tostring(ev.originalZ),
                "currentZ", tostring(currentPos.z),
                "correctedZ", tostring(targetZ),
                "delta", tostring(ev.delta),
                "settlePolicy", tostring(settlePolicy),
                "settleAttempts", tostring(settleAttempts),
                "settleSeconds", tostring(settleSeconds),
                "placementController", tostring(placementControllerReason or externalController or "none"),
                "teleportImmediate", tostring(ok == true),
                "smoothQueued", tostring(smoothQueued == true)
            )
            ctx.infoLog(
                "animated morrowind alignment assist",
                npc.recordId or npc.id,
                "object", tostring(ev.objectId),
                "z", tostring(ev.originalZ) .. "->" .. tostring(targetZ),
                "controller", tostring(placementControllerReason or externalController or "none")
            )
        else
            ctx.debugLog(
                "animated morrowind compat teleport failed",
                npc.recordId or npc.id,
                tostring(err),
                "placementController", tostring(placementControllerReason or externalController or "none")
            )
        end
    end

    function controller.processSettleCorrections()
        local now = ctx.core.getSimulationTime()
        for npcId, item in pairs(state.settle or {}) do
            local npc = item and item.npc or nil
            if not item or not ctx.isObjValid(npc) or assignedActors(ctx)[npcId] then
                state.settle[npcId] = nil
            elseif now >= (item.expiresAt or 0) or (item.attemptsRemaining or 0) <= 0 then
                state.settle[npcId] = nil
            elseif now >= (item.nextAt or 0) then
                ---@type any
                local npcAny = npc
                local currentPos = npcAny and npcAny.position or nil
                ---@type any
                local currentPosAny = currentPos
                local currentZ = currentPosAny and tonumber(currentPosAny.z) or nil
                local npcLabel = npcAny and (npcAny.recordId or npcAny.id) or npcId
                local targetZ = tonumber(item.targetZ)
                local shouldRetry = currentPos ~= nil and currentZ ~= nil and targetZ ~= nil and math.abs(currentZ - targetZ) > 4
                if shouldRetry and item.object and ctx.isObjValid(item.object) and item.object.position then
                    local dist = compat.horizontalDistance(currentPos, item.object.position)
                    if dist and dist > (compat.SEAT_RADIUS + 22) then
                        shouldRetry = false
                        state.settle[npcId] = nil
                        ctx.debugLog("animated morrowind compat settle stopped", npcLabel, "reason", "actor_moved_from_seat", "distance", tostring(dist))
                    end
                end
                if shouldRetry then
                    local targetZNumber = targetZ or currentZ or 0
                    if item.lastObservedZ and math.abs(currentZ - item.lastObservedZ) <= 1.5
                        and math.abs(currentZ - targetZNumber) > 4 then
                        item.externalRestoreStrikes = (item.externalRestoreStrikes or 0) + 1
                    else
                        item.externalRestoreStrikes = 0
                    end
                    item.lastObservedZ = currentZ
                    if (item.externalRestoreStrikes or 0) >= 3 then
                        state.settle[npcId] = nil
                        ctx.debugLog(
                            "animated morrowind compat settle stopped",
                            npcLabel,
                            "reason", "external_controller_restored_position",
                            "currentZ", tostring(currentZ),
                            "targetZ", tostring(targetZNumber),
                            "policy", tostring(item.policy)
                        )
                    else
                        local newPosition = ctx.util.vector3(tonumber(currentPosAny.x) or 0, tonumber(currentPosAny.y) or 0, targetZNumber)
                        local ok, err = ctx.tryTeleport(npc, npcAny.cell, newPosition, { rotation = npcAny.rotation })
                        item.attemptsRemaining = (item.attemptsRemaining or 0) - 1
                        item.nextAt = now + (tonumber(item.interval) or compat.DEFAULT_SETTLE_INTERVAL)
                        if ok then
                            ctx.debugLog(
                                "animated morrowind compat settle reapplied",
                                npcLabel,
                                "object", tostring(item.objectId),
                                "currentZ", tostring(currentZ),
                                "targetZ", tostring(targetZNumber),
                                "remaining", tostring(item.attemptsRemaining),
                                "policy", tostring(item.policy)
                            )
                        else
                            ctx.debugLog("animated morrowind compat settle failed", npcLabel, tostring(err))
                        end
                    end
                else
                    item.nextAt = now + (tonumber(item.interval) or compat.DEFAULT_SETTLE_INTERVAL)
                end
            end
        end
    end

    return controller
end

return M
