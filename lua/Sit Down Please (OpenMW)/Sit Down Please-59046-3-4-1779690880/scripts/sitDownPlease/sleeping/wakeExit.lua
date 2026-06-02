local module = {}
local manualAssignment = require('scripts/sitDownPlease/assignment/manualAssignment')

function module.create(env)
    local M = {}

    local core = assert(env.core, "wakeExit.create requires env.core")
    local isObjValid = assert(env.isObjValid, "wakeExit.create requires env.isObjValid")
    local tryTeleport = assert(env.tryTeleport, "wakeExit.create requires env.tryTeleport")
    local debugLog = assert(env.debugLog, "wakeExit.create requires env.debugLog")
    local infoLog = env.infoLog or function() end

    local pendingStandTeleports = {}
    local pendingPostWakeActivations = {}
    local pendingWakeExitWalks = {}
    local pendingWakeCleanups = {}
    local STAND_TELEPORT_RETRY_DELAY = 0.25
    local STAND_TELEPORT_BUSY_TIMEOUT = 2.0
    local STAND_TELEPORT_MAX_PENDING_SECONDS = 6.0

    local function isTeleportInProgressError(err)
        local text = tostring(err or "")
        return text:find("Teleport currently in progress", 1, true) ~= nil
            or text:find("teleport currently in progress", 1, true) ~= nil
            or text:find("already in the process of teleporting", 1, true) ~= nil
    end

    local function vectorLooksValid(pos)
        if pos == nil then return false end
        local ok = pcall(function()
            return pos.x + pos.y + pos.z
        end)
        return ok == true
    end

    local function clearStandTeleportWithReason(npcId, npc, reason, context)
        pendingStandTeleports[npcId] = nil
        debugLog("stand teleport skipped", npc and (npc.recordId or npc.id) or tostring(npcId), tostring(reason), tostring(context or "queued"))
    end

    local function queuedActorMatches(npcId, npc, tdata)
        local expected = tostring(tdata and tdata.actorId or npcId or "")
        local actual = tostring(npc and npc.id or "")
        if expected == "" or actual == "" or expected == actual then
            if npc and npc.id then debugLog("wake_exit_actor_verified", npc.recordId or npc.id, "actorId", tostring(npc.id)) end
            return true
        end
        pendingStandTeleports[npcId] = nil
        debugLog(
            "ignored stale wakeExit entry",
            "expected", expected,
            "actual", actual,
            "expectedRecord", tostring(tdata and tdata.actorRecordId),
            "actualRecord", tostring(npc and npc.recordId),
            "reason", tostring(tdata and tdata.reason)
        )
        return false
    end

    local function canRunStandTeleport(npcId, npc, pos, context)
        if not isObjValid(npc) then
            clearStandTeleportWithReason(npcId, npc, "invalid_npc", context)
            return false
        end
        if not (npc and npc.cell) then
            clearStandTeleportWithReason(npcId, npc, "missing_cell", context)
            return false
        end
        if not vectorLooksValid(pos) then
            clearStandTeleportWithReason(npcId, npc, "missing_or_invalid_destination", context)
            return false
        end
        return true
    end

    local function horizontalDistance(a, b)
        if not (a and b) then return math.huge end
        local dx = (a.x or 0) - (b.x or 0)
        local dy = (a.y or 0) - (b.y or 0)
        return math.sqrt(dx * dx + dy * dy)
    end

    local function standDestinationRejectReason(item, pos)
        if not vectorLooksValid(pos) then return "missing_or_invalid_destination" end
        if item and item.interactionType == "sleeping" and vectorLooksValid(item.finalPosition) then
            local horizontal = horizontalDistance(pos, item.finalPosition)
            local floorDrop = tonumber(item.floorDrop or 4) or 4
            if horizontal <= 220 and (pos.z or 0) > ((item.finalPosition.z or 0) - floorDrop) then
                return "not_floor_exit_destination"
            end
            local maxDrop = tonumber(item.maxSleepExitDrop or item.maxFloorExitDrop or 260) or 260
            if horizontal <= 260 and ((item.finalPosition.z or 0) - (pos.z or 0)) > maxDrop then
                return "sleep_exit_destination_too_low"
            end
        end
        return nil
    end

    local function wakeExitWalkRejectReason(npc, pos, opts)
        local rejectReason = standDestinationRejectReason(opts, pos)
        if rejectReason then return rejectReason end
        if opts and opts.interactionType == "sleeping" and vectorLooksValid(npc and npc.position) then
            local maxWalkDrop = tonumber(opts.maxWakeExitWalkDrop or opts.maxSleepExitDrop or 260) or 260
            if ((npc.position.z or 0) - (pos.z or 0)) > maxWalkDrop then
                return "wake_exit_walk_destination_too_low"
            end
        end
        return nil
    end

    local function sanitizeStandPositions(item, positions)
        local cleaned = {}
        for _, pos in ipairs(positions or {}) do
            local rejectReason = standDestinationRejectReason(item, pos)
            if not rejectReason then
                table.insert(cleaned, pos)
            else
                local npc = item and item.npc
                debugLog("stand teleport destination rejected", npc and (npc.recordId or npc.id) or "<npc>", tostring(item and item.reason), "reason", rejectReason, "dest", tostring(pos))
            end
        end
        return cleaned
    end

    local function onStandTeleportSuccess(npcId, npc, tdata, index, mode)
        if env.onStandTeleportSuccess then
            env.onStandTeleportSuccess(npcId, npc, tdata, index, mode)
        end
    end

    local function attemptStandTeleportStep(npcId, tdata, mode)
        local npc = tdata and tdata.npc
        if not isObjValid(npc) then
            pendingStandTeleports[npcId] = nil
            return
        end
        if not queuedActorMatches(npcId, npc, tdata) then return end

        local now = core.getSimulationTime() or 0
        if mode == "queued" and tdata.nextAttemptAt and tdata.nextAttemptAt > now then
            return
        end
        local maxPendingSeconds = tonumber(tdata.maxPendingSeconds or STAND_TELEPORT_MAX_PENDING_SECONDS) or STAND_TELEPORT_MAX_PENDING_SECONDS
        if tdata.queuedAt and maxPendingSeconds > 0 and now - tdata.queuedAt > maxPendingSeconds then
            pendingStandTeleports[npcId] = nil
            debugLog("queued stand teleport expired", npc.recordId or npc.id, tostring(tdata.reason), "seconds", tostring(now - tdata.queuedAt))
            if manualAssignment.isManualReassignReason(tdata.reason) then
                infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "failure", "stand_teleport_expired")
            end
            return
        end

        local positions = tdata.positions or {}
        local index = tdata.index or 1
        local pos = positions[index]

        if pos == nil then
            pendingStandTeleports[npcId] = nil
            debugLog(mode == "immediate" and "stand teleport skipped" or "queued stand teleport exhausted", npc.recordId or npc.id, tostring(tdata.reason), "reason", "no_destination")
            if manualAssignment.isManualReassignReason(tdata.reason) then
                infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "failure", "no_destination")
            end
            return
        end

        local rejectReason = standDestinationRejectReason(tdata, pos)
        if rejectReason then
            if index < #positions then
                tdata.index = index + 1
                debugLog("queued stand teleport fallback skipped", npc.recordId or npc.id, tostring(tdata.reason), "exitIndex", tostring(index), "reason", tostring(rejectReason))
            else
                pendingStandTeleports[npcId] = nil
                debugLog("queued stand teleport exhausted", npc.recordId or npc.id, tostring(tdata.reason), "reason", tostring(rejectReason))
                if manualAssignment.isManualReassignReason(tdata.reason) then
                    infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "failure", tostring(rejectReason))
                end
            end
            return
        end

        if not canRunStandTeleport(npcId, npc, pos, mode) then
            if index < #positions then
                tdata.index = index + 1
            end
            return
        end

        local ok, err = tryTeleport(npc, npc.cell, pos, { rotation = tdata.rotation or npc.rotation })
        if ok then
            if mode == "immediate" then
                debugLog("stand teleport", npc.recordId or npc.id, tostring(tdata.reason), "type", tostring(tdata.interactionType), "exitIndex", tostring(index))
            else
                debugLog("queued stand teleport", npc.recordId or npc.id, tostring(tdata.reason), "type", tostring(tdata.interactionType), "exitIndex", tostring(index))
            end
            if manualAssignment.isManualReassignReason(tdata.reason) then
                infoLog("safe_exit_completed", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "mode", tostring(mode), "exitIndex", tostring(index))
            end
            onStandTeleportSuccess(npcId, npc, tdata, index, mode)
            pendingStandTeleports[npcId] = nil
            return
        end

        if isTeleportInProgressError(err) then
            local busyNow = core.getSimulationTime() or now
            tdata.busyFirstAt = tdata.busyFirstAt or busyNow
            tdata.busyCount = (tdata.busyCount or 0) + 1
            local busyDuration = busyNow - tdata.busyFirstAt
            local maxBusySeconds = tonumber(tdata.maxBusySeconds or STAND_TELEPORT_BUSY_TIMEOUT) or STAND_TELEPORT_BUSY_TIMEOUT
            if busyDuration > maxBusySeconds then
                pendingStandTeleports[npcId] = nil
                debugLog("queued stand teleport busy timeout", npc.recordId or npc.id, tostring(tdata.reason), "seconds", tostring(busyDuration), tostring(err))
                if manualAssignment.isManualReassignReason(tdata.reason) then
                    infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "failure", "teleport_busy_timeout")
                end
                return
            end
            tdata.nextAttemptAt = busyNow + STAND_TELEPORT_RETRY_DELAY
            if mode == "immediate" then
                debugLog("stand teleport queued", npc.recordId or npc.id, tostring(tdata.reason))
            elseif tdata.busyCount == 1 then
                debugLog("queued stand teleport deferred", npc.recordId or npc.id, tostring(tdata.reason), tostring(err))
            end
            return
        end

        if mode == "immediate" then
            debugLog("stand teleport failed", npc.recordId or npc.id, tostring(tdata.reason), tostring(err), "trying fallback exits")
            return
        end

        if index < #positions then
            tdata.index = index + 1
            debugLog("queued stand teleport fallback", npc.recordId or npc.id, tostring(tdata.reason), "nextExitIndex", tostring(tdata.index), tostring(err))
        else
            debugLog("queued stand teleport exhausted", npc.recordId or npc.id, tostring(tdata.reason), tostring(err))
            if manualAssignment.isManualReassignReason(tdata.reason) then
                infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(tdata.interactionType), "reason", tostring(tdata.reason), "failure", tostring(err))
            end
            pendingStandTeleports[npcId] = nil
        end
    end

    function M.queueStandTeleport(item)
        local npc = item and item.npc
        if not (npc and npc.id) then
            debugLog("stand teleport skipped", "<npc>", tostring(item and item.reason or "unknown"), "reason", "missing_npc_or_id")
            return false
        end

        if not isObjValid(npc) then
            debugLog("stand teleport skipped", npc.recordId or npc.id, tostring(item.reason), "reason", "invalid_npc")
            return false
        end

        if not npc.cell then
            debugLog("stand teleport skipped", npc.recordId or npc.id, tostring(item.reason), "reason", "missing_cell")
            return false
        end

        local positions = sanitizeStandPositions(item, item.positions or { item.position })
        if #positions == 0 then
            debugLog("stand teleport skipped", npc.recordId or npc.id, tostring(item.reason), "reason", "no_valid_destinations")
            if manualAssignment.isManualReassignReason(item.reason) then
                infoLog("safe_exit_failed_fallback", npc.recordId or npc.id, "type", tostring(item.interactionType), "reason", tostring(item.reason), "failure", "no_valid_destinations")
            end
            return false
        end

        pendingStandTeleports[npc.id] = {
            npc = npc,
            actorId = npc.id,
            actorRecordId = npc.recordId,
            positions = positions,
            index = tonumber(item.index or 1) or 1,
            rotation = item.rotation,
            reason = item.reason,
            interactionType = item.interactionType,
            returnOriginPosition = item.returnOriginPosition,
            finalPosition = item.finalPosition,
            floorDrop = item.floorDrop,
            clearSleepHomeOnSuccess = item.clearSleepHomeOnSuccess == true,
            queuedAt = core.getSimulationTime() or 0,
            maxBusySeconds = item.maxBusySeconds,
            maxPendingSeconds = item.maxPendingSeconds,
        }
        return true
    end

    function M.tryImmediateStandTeleportForNpc(npcId)
        local tdata = npcId and pendingStandTeleports[npcId] or nil
        if not tdata then return end
        attemptStandTeleportStep(npcId, tdata, "immediate")
    end

    function M.processPendingStandTeleports()
        for npcId, tdata in pairs(pendingStandTeleports) do
            attemptStandTeleportStep(npcId, tdata, "queued")
        end
    end

    function M.queueWakeExitWalk(npc, wakeExitWalkPosition, reason, opts)
        if not (npc and npc.id and isObjValid(npc)) then
            debugLog("wake exit walk skipped", npc and (npc.recordId or npc.id) or "<npc>", tostring(reason), "reason", "invalid_npc")
            return false
        end
        if not vectorLooksValid(wakeExitWalkPosition) then
            debugLog("wake exit walk skipped", npc.recordId or npc.id, tostring(reason), "reason", "missing_or_invalid_destination")
            return false
        end
        local rejectReason = wakeExitWalkRejectReason(npc, wakeExitWalkPosition, opts)
        if rejectReason then
            debugLog("wake exit walk skipped", npc.recordId or npc.id, tostring(reason), "reason", tostring(rejectReason), "dest", tostring(wakeExitWalkPosition))
            return false
        end
        local startedAt = core.getSimulationTime()
        pendingWakeExitWalks[npc.id] = {
            npc = npc,
            destPosition = wakeExitWalkPosition,
            startedAt = startedAt,
            timeout = (opts and opts.timeout) or 6.0,
            radius = (opts and opts.radius) or 80,
            reason = reason,
            nudges = 0,
            maxNudges = (opts and opts.maxNudges) or 1,
            nextNudgeAt = startedAt + ((opts and opts.firstNudgeAfter) or 2.5),
        }
        npc:sendEvent('SitDownPleaseStartAIPackage', {
            type = "Travel",
            destPosition = wakeExitWalkPosition,
            isRepeat = false,
            cancelOther = true,
        })
        debugLog("wake exit walk queued", npc.recordId or npc.id, tostring(reason), "dest", tostring(wakeExitWalkPosition))
        return true
    end

    function M.processWakeExitWalks()
        local t = core.getSimulationTime()
        for npcId, item in pairs(pendingWakeExitWalks) do
            local npc = item and item.npc
            local dest = item and item.destPosition
            if not (item and isObjValid(npc) and vectorLooksValid(dest)) then
                pendingWakeExitWalks[npcId] = nil
            else
                local dist = (npc.position - dest):length()
                local radius = item.radius or 70
                if dist <= radius then
                    pendingWakeExitWalks[npcId] = nil
                    debugLog("wake exit walk reached", npc.recordId or npc.id, "distance", tostring(dist), "reason", tostring(item.reason))
                elseif item.startedAt and item.timeout and t - item.startedAt >= item.timeout then
                    pendingWakeExitWalks[npcId] = nil
                    debugLog("wake exit walk timeout", npc.recordId or npc.id, "distance", tostring(dist), "reason", tostring(item.reason))
                elseif (item.maxNudges or 0) > (item.nudges or 0) and item.nextNudgeAt and item.nextNudgeAt <= t then
                    item.nudges = (item.nudges or 0) + 1
                    item.nextNudgeAt = t + 2.0
                    npc:sendEvent('SitDownPleaseStartAIPackage', {
                        type = "Travel",
                        destPosition = dest,
                        isRepeat = false,
                        cancelOther = true,
                    })
                end
            end
        end
    end

    function M.queuePostWakeActivation(npc, actor, reason)
        if not (npc and npc.id and actor and actor.isValid) then return end
        pendingPostWakeActivations[npc.id] = {
            npc = npc,
            actor = actor,
            reason = reason or "activated_by_player_dialogue",
            due = core.getSimulationTime() + 1.5,
        }
        debugLog("queued post-wake activation", npc.recordId or npc.id, tostring(reason or "activated_by_player_dialogue"))
    end

    function M.processPostWakeActivations()
        local t = core.getSimulationTime()
        for npcId, item in pairs(pendingPostWakeActivations) do
            local npc = item and item.npc
            local actor = item and item.actor
            if not item or (item.due and item.due > t) then
                -- not due yet
            elseif env.isNpcBusyForPostWake and env.isNpcBusyForPostWake(npcId) then
                item.due = t + 0.10
            elseif not (isObjValid(npc) and isObjValid(actor)) then
                pendingPostWakeActivations[npcId] = nil
            else
                pendingPostWakeActivations[npcId] = nil
                local ok, err = pcall(function() npc:activateBy(actor) end)
                if ok then
                    debugLog("post-wake activation", npc.recordId or npc.id, tostring(item.reason))
                else
                    debugLog("post-wake activation failed", npc.recordId or npc.id, tostring(err))
                end
            end
        end
    end


    function M.markPendingWakeCleanup(npc, reason)
        if npc and npc.id then
            pendingWakeCleanups[npc.id] = {
                npc = npc,
                reason = reason or "wake_cleanup",
                markedAt = core.getSimulationTime(),
            }
            debugLog("wake cleanup pending", npc.recordId or npc.id, tostring(reason or "wake_cleanup"))
        end
    end

    function M.sendPendingWakeCleanupIfNeeded(npc, reason)
        if not (npc and npc.id) then return false end
        local entry = pendingWakeCleanups[npc.id]
        if not entry then return false end
        if not isObjValid(npc) then return false end
        pendingWakeCleanups[npc.id] = nil
        npc:sendEvent('StopInteractionObject', {
            reason = entry.reason or reason or "pending_wake_cleanup",
            interactionType = "sleeping",
            wakeCleanupOnly = true,
        })
        debugLog("wake local cleanup requested", npc.recordId or npc.id, tostring(entry.reason or reason or "pending_wake_cleanup"))
        return true
    end

    function M.getWakeExitWalkForNpc(npcId)
        return npcId and pendingWakeExitWalks[npcId] or nil
    end

    function M.hasPendingStandTeleport(npcId)
        return npcId ~= nil and pendingStandTeleports[npcId] ~= nil
    end

    function M.hasPendingWakeExitWalk(npcId)
        return npcId ~= nil and pendingWakeExitWalks[npcId] ~= nil
    end

    function M.hasPendingPostWakeActivation(npcId)
        return npcId ~= nil and pendingPostWakeActivations[npcId] ~= nil
    end

    function M.clearForNpc(npcId)
        if not npcId then return end
        pendingStandTeleports[npcId] = nil
        pendingPostWakeActivations[npcId] = nil
        pendingWakeExitWalks[npcId] = nil
        pendingWakeCleanups[npcId] = nil
    end

    function M.clearStandTeleportForNpc(npcId)
        if not npcId then return end
        pendingStandTeleports[npcId] = nil
    end

    function M.clearWakeExitWalkForNpc(npcId)
        if not npcId then return end
        pendingWakeExitWalks[npcId] = nil
    end

    function M.clearPostWakeActivationForNpc(npcId)
        if not npcId then return end
        pendingPostWakeActivations[npcId] = nil
    end

    function M.clearStandAndWakeForNpc(npcId)
        if not npcId then return end
        pendingStandTeleports[npcId] = nil
        pendingWakeExitWalks[npcId] = nil
    end

    function M.clearAll()
        pendingStandTeleports = {}
        pendingPostWakeActivations = {}
        pendingWakeExitWalks = {}
        pendingWakeCleanups = {}
    end

    function M.clearStandAndWakeAll()
        pendingStandTeleports = {}
        pendingWakeExitWalks = {}
    end

    return M
end

return module
