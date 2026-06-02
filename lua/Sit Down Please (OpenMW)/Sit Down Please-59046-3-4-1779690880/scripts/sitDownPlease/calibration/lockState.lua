-- calibration/lockState.lua
--
-- Runtime-only calibration target/session helper for the global assignment script.
-- Keep this out of interactionAssignment.lua to avoid OpenMW/Lua's chunk-local
-- variable ceiling and to make calibration controls easier to audit.

local M = {
    session = nil,
    lastTargets = { sitting = nil, sleeping = nil },
}

local HOLD_SECONDS = 45

local function friendlySlotLabel(session)
    if not session then return "unknown slot" end
    local raw = tostring(session.slotName or session.slotKey or "default")
    local interactionType = tostring(session.interactionType or "")
    local profile = session.profile or {}
    local bedType = tostring(profile.bedType or profile.type or "")
    if interactionType == "sleeping" and (bedType == "bottom_bunk" or bedType == "top_bunk") and (raw == "sleep_main" or raw == "default") then
        return bedType == "top_bunk" and "top bunk" or "bottom bunk"
    end
    if raw == "default" then
        return interactionType == "sleeping" and "main bed slot" or "main seat"
    end
    if raw == "sleep_main" then return "main bed slot" end
    if raw == "sleep_left" then return "left bed slot" end
    if raw == "sleep_right" then return "right bed slot" end
    if raw == "sleep_a" then return "bed slot A" end
    if raw == "sleep_b" then return "bed slot B" end
    if raw == "seat_a" then return "seat A" end
    if raw == "seat_b" then return "seat B" end
    if raw == "seat_c" then return "seat C" end
    if raw == "seat_d" then return "seat D" end
    return raw
end

local function profileSourceLabel(session)
    if not session then return nil end
    local profile = session.profile or {}
    if profile.isFallback == true then return "fallback" end
    if profile.profileBedTypeFallback ~= nil then return "bed average" end
    if profile.orientationVariantSource or profile.chairOrientationVariantSource then return "profile variant" end
    if profile.externalProfile == true then return "profile" end
    return "built-in"
end

local function label(session)
    if not session then return "none" end
    local actor = session.actor or session.npc
    local object = session.object
    local actorLabel = session.actorRecordId or session.actorId or (actor and (actor.recordId or actor.id))
    local objectLabel = session.objectRecordId or session.objectKey or session.objectId or (object and (object.recordId or object.id))
    return tostring(actorLabel or "<actor>")
        .. " -> "
        .. tostring(objectLabel or "<furniture>")
        .. " ("
        .. friendlySlotLabel(session)
        .. "; "
        .. tostring(profileSourceLabel(session) or "unknown source")
        .. ")"
end

local function matches(data, session)
    if not (data and session) then return false end
    return data.interactionType == session.interactionType
        and data.slotKey == session.slotKey
        and tostring(data.objectId or (data.object and data.object.recordId) or "") == tostring(session.objectRecordId or "")
end

local function safeCell(obj)
    local ok, cell = pcall(function() return obj and obj.cell end)
    if ok then return cell end
    return nil
end

local function currentPlayerCell(ctx)
    local player = ctx and ctx.world and ctx.world.players and ctx.world.players[1] or nil
    return safeCell(player)
end

local function sameCell(cellA, cellB, ctx)
    if not cellA or not cellB then return false end
    if cellA == cellB then return true end
    if ctx and ctx.cellName then
        local okA, nameA = pcall(ctx.cellName, cellA)
        local okB, nameB = pcall(ctx.cellName, cellB)
        if okA and okB and nameA ~= nil and nameB ~= nil then
            return tostring(nameA) == tostring(nameB)
        end
    end
    return false
end

local function targetInCurrentCell(data, ctx)
    local playerCell = currentPlayerCell(ctx)
    if not playerCell then return true end
    local actor = data and (data.npc or data.actor) or nil
    local object = data and data.object or nil
    local actorCell = safeCell(actor)
    local objectCell = safeCell(object)
    if actorCell and not sameCell(actorCell, playerCell, ctx) then return false end
    if objectCell and not sameCell(objectCell, playerCell, ctx) then return false end
    return actorCell ~= nil or objectCell ~= nil
end

local function rememberFields(data, ctx, reason)
    local actor = data.npc or data.actor
    local object = data.object
    return {
        interactionType = data.interactionType,
        actor = actor,
        actorId = actor and actor.id or data.actorId,
        actorRecordId = actor and actor.recordId or data.actorRecordId,
        object = object,
        objectKey = tostring(object and (object.id or object.recordId) or data.objectId),
        objectRecordId = data.objectId or (object and object.recordId),
        model = data.model,
        cellName = ctx and ctx.cellName and actor and ctx.cellName(actor.cell) or nil,
        slotKey = data.slotKey,
        slotName = data.slotName,
        slot = data.slot,
        profile = data.profile,
        profileId = data.profileId,
        profileOffset = data.profileOffset,
        animationOffset = data.animationOffset,
        animationName = data.animationName or data.animation,
        calibration = data.calibration,
        approachPos = data.approachPos,
        finalPosition = data.finalPosition,
        finalRotation = data.finalRotation,
        facingDirection = data.facingDirection,
        facingObjectId = data.facingObjectId,
        facingKind = data.facingKind,
        facingObjectPosition = data.facingObjectPosition,
        startedAt = ctx and ctx.now and ctx.now() or nil,
        reason = reason or "accepted",
    }
end

local function shouldActivateSession(data, reason)
    if data and data.calibrationAction == true then return true end
    local text = tostring(reason or "")
    return text:find("manual", 1, true) ~= nil
        or text:find("developer", 1, true) ~= nil
        or text:find("calibration", 1, true) ~= nil
        or text:find("pending", 1, true) ~= nil
end

function M.rememberTarget(data, ctx, reason)
    if not (data and data.interactionType and (data.npc or data.actor) and data.object and data.slotKey) then return end
    local session = rememberFields(data, ctx, reason)
    M.lastTargets[data.interactionType] = session
    if shouldActivateSession(data, reason) then
        M.session = session
        if ctx and ctx.infoLog then
            ctx.infoLog("calibration_target_set", tostring(session.interactionType), label(session), "reason", tostring(reason or "remembered"))
            ctx.infoLog("calibration_target_display_state", label(session), "source", tostring(reason or "remembered"))
        end
    end
end

local function scoreTargetData(data, ctx, playerPos, maxDistance)
    local actor = data and (data.npc or data.actor) or nil
    if not (data and ctx and ctx.isObjValid and ctx.isObjValid(actor) and ctx.isObjValid(data.object)) then return nil end
    if not targetInCurrentCell(data, ctx) then return nil end
    local dist = 0
    if playerPos then
        local actorDist = actor.position and (actor.position - playerPos):length() or math.huge
        local objectDist = data.object.position and (data.object.position - playerPos):length() or math.huge
        local finalDist = data.finalPosition and (data.finalPosition - playerPos):length() or math.huge
        dist = math.min(actorDist, objectDist, finalDist)
    end
    if dist > (tonumber(maxDistance) or 1800) then return nil end
    return dist + (data.state == ctx.interactingState and -100000 or 0), dist
end

local function findTargetOfType(interactionType, ctx)
    local player = ctx and ctx.world and ctx.world.players and ctx.world.players[1] or nil
    local playerPos = player and player.position or nil
    local best, bestScore = nil, nil
    for _, data in pairs(ctx.assignedActors or {}) do
        if data and data.interactionType == interactionType then
            local score = scoreTargetData(data, ctx, playerPos)
            if score and (not bestScore or score < bestScore) then
                best, bestScore = data, score
            end
        end
    end
    if best then return best, "active_near_player" end
    local last = M.lastTargets[interactionType]
    if scoreTargetData(last, ctx, playerPos, 1800) then
        return last, "last_accepted"
    elseif last then
        M.lastTargets[interactionType] = nil
    end
    return nil, "no_current_calibration_target"
end

local function findAnyTarget(ctx)
    local player = ctx and ctx.world and ctx.world.players and ctx.world.players[1] or nil
    local playerPos = player and player.position or nil
    local best, bestScore = nil, nil
    for _, data in pairs(ctx.assignedActors or {}) do
        if data and (data.interactionType == "sleeping" or data.interactionType == "sitting") then
            local score = scoreTargetData(data, ctx, playerPos)
            if score and (not bestScore or score < bestScore) then
                best, bestScore = data, score
            end
        end
    end
    if best then return best, "active_near_player" end

    for _, interactionType in ipairs({ "sleeping", "sitting" }) do
        local last = M.lastTargets[interactionType]
        local score, dist = scoreTargetData(last, ctx, playerPos, 2200)
        if score then
            score = score + 10000
            if not bestScore or score < bestScore then
                best, bestScore = last, score
            end
        elseif last then
            M.lastTargets[interactionType] = nil
        end
    end
    if best then return best, "last_accepted" end
    return nil, "no_current_calibration_target"
end

local function findTarget(interactionType, ctx)
    if interactionType == "auto" or interactionType == nil then
        return findAnyTarget(ctx)
    end
    return findTargetOfType(interactionType, ctx)
end

local function captureSession(interactionType, ctx, reason)
    local data, source = findTarget(interactionType, ctx)
    if not data then
        ctx.infoLog("calibration action failed", tostring(interactionType), "reason", tostring(source))
        return nil, source
    end
    if not ctx.isObjValid(data.npc or data.actor) then
        ctx.infoLog("calibration action failed", tostring(interactionType), "reason", "actor_invalid")
        return nil, "actor_invalid"
    end
    if not ctx.isObjValid(data.object) then
        ctx.infoLog("calibration action failed", tostring(interactionType), "reason", "object_invalid")
        return nil, "object_invalid"
    end

    M.session = rememberFields(data, ctx, reason or source)
    ctx.infoLog("calibration target captured", tostring(interactionType), label(M.session), "source", tostring(source), "reason", tostring(reason))
    ctx.infoLog("calibration_target_set", tostring(M.session.interactionType), label(M.session), "source", tostring(source), "reason", tostring(reason))
    ctx.infoLog("calibration_target_display_state", label(M.session), "source", tostring(source))
    return M.session, "ok"
end

local function validateSession(interactionType, ctx)
    local session = M.session
    if not session then
        return nil, "no_current_calibration_target"
    end
    if interactionType ~= "auto" and session.interactionType ~= interactionType then
        return nil, "no_current_calibration_target"
    end
    if not ctx.isObjValid(session.actor) then return nil, "actor_invalid" end
    if not ctx.isObjValid(session.object) then return nil, "object_invalid" end
    if not targetInCurrentCell(session, ctx) then
        M.session = nil
        return nil, "target_wrong_cell"
    end
    if not session.slotKey then return nil, "slot_invalid" end
    local data = ctx.assignedActors and ctx.assignedActors[session.actor.id] or nil
    if data and not matches(data, session) then return nil, "lock_mismatch" end
    return session, "ok"
end

function M.clearForCellChange(ctx, reason)
    local hadTarget = M.session ~= nil or M.lastTargets.sitting ~= nil or M.lastTargets.sleeping ~= nil
    if not hadTarget then return false end
    if ctx and ctx.infoLog then
        ctx.infoLog("calibration target cleared", "cell_change", M.session and label(M.session) or "last_targets", "reason", tostring(reason or "cell_change"))
        ctx.infoLog("calibration_target_display_state", "Target: none selected", "source", tostring(reason or "cell_change"))
    end
    M.session = nil
    M.lastTargets.sitting = nil
    M.lastTargets.sleeping = nil
    return true
end

local function candidateFromSession(session, ctx, reason)
    return {
        object = session.object,
        objectId = session.objectRecordId,
        model = session.model or ctx.profiles.objectModelPath(session.object),
        profile = session.profile,
        profileId = session.profileId,
        interactionType = session.interactionType,
        slot = session.slot or { name = session.slotName or "default" },
        slotName = session.slotName,
        slotKey = session.slotKey,
        approachPos = session.approachPos,
        preferredFacingDirection = session.facingDirection,
        facingObjectId = session.facingObjectId,
        facingKind = session.facingKind,
        facingObjectPosition = session.facingObjectPosition,
        currentHour = ctx.profiles.getGameHour(),
        calibrationAction = true,
        calibrationReason = reason or "calibration",
        ignoreTimeGate = true,
    }
end

local function refreshHold(session, ctx, reason)
    if not (session and ctx and ctx.assignedActors and session.actor and session.actor.id) then return false end
    local data = ctx.assignedActors[session.actor.id]
    if not matches(data, session) then return false end
    local now = ctx.now and ctx.now() or 0
    data.calibrationMenuHoldUntil = now + HOLD_SECONDS
    data.teleportBusySkips = nil
    data.teleportBusyFirstAt = nil
    if ctx.debugLog then
        ctx.debugLog("calibration hold refreshed", tostring(session.interactionType), label(session), "reason", tostring(reason), "seconds", tostring(HOLD_SECONDS))
    end
    return true
end


function M.captureTarget(interactionType, ctx, reason)
    local session = captureSession(interactionType, ctx, reason or "menu_capture")
    if session then refreshHold(session, ctx, reason or "menu_capture") end
    return session
end

function M.currentSession(interactionType, ctx)
    local session, status = validateSession(interactionType, ctx)
    if session then return session, status end
    return nil, status
end

function M.ensureSession(interactionType, ctx, reason)
    local session, status = validateSession(interactionType, ctx)
    if session then
        refreshHold(session, ctx, reason or status or "menu")
        return session, status
    end
    session = captureSession(interactionType, ctx, reason or status or "menu")
    if session then refreshHold(session, ctx, reason or status or "menu") end
    return session
end

function M.sessionLabel(session)
    return label(session)
end

function M.refreshHold(interactionType, ctx, reason)
    local session = validateSession(interactionType, ctx)
    if not session then return false end
    return refreshHold(session, ctx, reason or "developer_menu")
end

function M.handleAction(actionSpec, key, ctx)
    local interactionType = actionSpec and actionSpec.interactionType
    local action = actionSpec and actionSpec.action
    if not (ctx and ctx.profiles and (ctx.profiles.INTERACTION_TYPES[interactionType] or interactionType == "auto")) then
        ctx.infoLog("calibration action failed", tostring(key), "reason", "unsupported_interaction_type")
        return
    end

    if action == "clear" then
        if M.session and (interactionType == "auto" or M.session.interactionType == interactionType) then
            refreshHold(M.session, ctx, tostring(key or "developer_menu_clear"))
            ctx.infoLog("calibration target cleared", tostring(interactionType), label(M.session))
            ctx.infoLog("calibration_target_cleared", tostring(interactionType), label(M.session), "reason", tostring(key or "clear"))
            ctx.infoLog("calibration_target_display_state", "Target: none selected", "source", tostring(key or "clear"))
            M.session = nil
        else
            ctx.infoLog("calibration target clear", tostring(interactionType), "reason", "no_current_calibration_target")
        end
        return
    end

    local session = validateSession(interactionType, ctx)
    if not session then session = captureSession(interactionType, ctx, tostring(action or key)) end
    if not session then return end
    interactionType = session.interactionType
    refreshHold(session, ctx, tostring(key or action or "developer_menu"))

    local data = ctx.assignedActors and ctx.assignedActors[session.actor.id] or nil
    if data and not matches(data, session) then
        ctx.infoLog("calibration action failed", tostring(interactionType), "reason", "lock_mismatch", label(session))
        return
    end

    if action == "resume" then
        if data and matches(data, session) then
            session.actor:sendEvent("SitDownPleaseReapplyLockedCalibration", {
                interactionType = interactionType,
                slotKey = session.slotKey,
                profileId = session.profileId,
                reason = tostring(key),
            })
            ctx.infoLog("calibration resume reapplied", tostring(interactionType), label(session))
        else
            ctx.sendConsiderInteraction(session.actor, candidateFromSession(session, ctx, tostring(key)))
            ctx.infoLog("calibration resume assignment requested", tostring(interactionType), label(session))
        end
        return session
    end

    if action == "reapply" then
        session.actor:sendEvent("SitDownPleaseReapplyLockedCalibration", {
            interactionType = interactionType,
            slotKey = session.slotKey,
            profileId = session.profileId,
            reason = tostring(key),
        })
        ctx.infoLog("calibration reapply requested", tostring(interactionType), label(session))
        return session
    end

    if action == "reenter" or action == "send" then
        ctx.sendConsiderInteraction(session.actor, candidateFromSession(session, ctx, tostring(key)))
        ctx.infoLog("calibration target assignment requested", tostring(action), tostring(interactionType), label(session))
        return session
    end

    ctx.infoLog("calibration action failed", tostring(key), "reason", "unsupported_action")
end

function M.notifyDisguiseInitialPlacement(npc, interactionType, reason, ctx)
    if not (ctx and ctx.settings and ctx.settings.disguiseInitialPlacement == true and ctx.world and ctx.world.players) then return end
    for _, player in ipairs(ctx.world.players) do
        pcall(function()
            player:sendEvent('SitDownPleaseDisguiseInitialPlacement', {
                actor = npc,
                actorId = npc and npc.id or nil,
                recordId = npc and npc.recordId or nil,
                object = ctx.object,
                objectId = ctx.object and ctx.object.recordId or ctx.objectId,
                targetPosition = ctx.finalPosition or ctx.position or (ctx.object and ctx.object.position) or (npc and npc.position),
                holdDuration = tonumber(ctx.holdDuration),
                interactionType = interactionType,
                reason = reason or "initial_placement",
                duration = tonumber(ctx.duration) or 0.65,
            })
        end)
    end
end

function M.onSleepUpdated(ev, ctx)
    local npc = ev and ev.npc
    if not (npc and npc.id and ev.finalPosition) then return end
    local data = ctx.assignedActors[npc.id]
    if not (data and data.interactionType == "sleeping") then return end
    if ev.slotKey and data.slotKey and ev.slotKey ~= data.slotKey then
        ctx.debugLog("sleep calibration update rejected", npc.recordId or npc.id, "reason", "slot_mismatch", "expected", tostring(data.slotKey), "got", tostring(ev.slotKey))
        return
    end

    data.finalPosition = ev.finalPosition
    data.finalRotation = ev.finalRotation or data.finalRotation
    data.position = ev.finalPosition
    data.approachPos = ev.approachPos or data.approachPos
    data.exitPosition = ev.exitPosition or data.exitPosition
    data.exitPositions = ev.exitPositions or data.exitPositions
    data.profile = ev.profile or data.profile
    data.profileId = ev.profileId or data.profileId
    data.profileOffset = ev.profileOffset or data.profileOffset
    data.animationOffset = ev.animationOffset or data.animationOffset
    data.calibration = ev.calibration or data.calibration

    -- Developer calibration is an active, player-driven pose adjustment. Do not let
    -- stale teleport-busy bookkeeping from the normal correction loop wake the NPC
    -- or dump them out of bed while the calibration UI is nudging/reapplying them.
    local now = ctx.now and ctx.now() or nil
    data.calibrationMenuHoldUntil = (now or 0) + 45
    data.teleportBusySkips = nil
    data.teleportBusyFirstAt = nil

    if data.state == ctx.states.interacting or data.state == ctx.states.transitioning then
        local ok, err = ctx.tryTeleport(npc, npc.cell, ev.finalPosition, { rotation = ctx.rotationFromYaw(data.finalRotation or npc.rotation:getYaw(), npc.rotation) })
        if ok then
            ctx.infoLog("sleep calibration applied", npc.recordId or npc.id, "reason", tostring(ev.reason or "calibration"), "object", tostring(data.objectId), "profile", tostring(data.profileId), "slot", tostring(data.slotName), "final", tostring(ev.finalPosition), "rotation", tostring(data.finalRotation))
        elseif not ctx.deferTeleportFailure(data, err, "sleep_calibration") then
            ctx.debugLog("sleep calibration teleport failed", npc.recordId or npc.id, tostring(err))
        end
    else
        ctx.debugLog("sleep calibration stored", npc.recordId or npc.id, "state", tostring(data.state), "reason", tostring(ev.reason or "calibration"))
    end
end

return M
