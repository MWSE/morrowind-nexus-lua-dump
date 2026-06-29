-- calibration/lockState.lua
---@omw-context none
--
-- Runtime-only calibration target/session helper for the global assignment script.
-- Keep this out of interactionAssignment.lua to avoid OpenMW/Lua's chunk-local
-- variable ceiling and keep calibration controls focused.

local M = {
    session = nil,
    lastTargets = { sitting = nil, sleeping = nil, station = nil },
}

local calibrationTestActors = require('scripts/sitDownPlease/calibration/testActors')
local focusMetadata = require('scripts/sitDownPlease/calibration/focusMetadata')

local HOLD_SECONDS = 45

local function effectiveBedType(profile, rawSlotName)
    local raw = tostring(rawSlotName or ""):lower()
    if raw == "sleep_top" then return "top_bunk" end
    if raw == "sleep_bottom" then return "bottom_bunk" end
    return tostring(profile and (profile.bedType or profile.type) or "")
end

local function friendlySlotLabel(session)
    if not session then return "unknown slot" end
    local raw = tostring(session.slotName or session.slotKey or "default")
    local interactionType = tostring(session.interactionType or "")
    local profile = session.profile or {}
    local bedType = effectiveBedType(profile, raw)
    if interactionType == "sleeping" and (bedType == "bottom_bunk" or bedType == "top_bunk") and (raw == "sleep_main" or raw == "default") then
        return bedType == "top_bunk" and "top bunk" or "bottom bunk"
    end
    if interactionType == "sleeping" and raw == "sleep_top" then return "top bunk" end
    if interactionType == "sleeping" and raw == "sleep_bottom" then return "bottom bunk" end
    if raw == "default" then
        if interactionType == "sleeping" and bedType == "double" then return "bed slot A" end
        return interactionType == "sleeping" and "main bed slot" or "main seat"
    end
    if raw == "sleep_main" then return bedType == "double" and "bed slot A" or "main bed slot" end
    if raw == "sleep_left" then return "left bed slot" end
    if raw == "sleep_right" then return "right bed slot" end
    if raw == "sleep_a" then return "bed slot A" end
    if raw == "sleep_b" then return "bed slot B" end
    if raw == "seat_a" then return "seat A" end
    if raw == "seat_b" then return "seat B" end
    if raw == "seat_c" then return "seat C" end
    if raw == "seat_d" then return "seat D" end
    if raw == "presenter" then return "presenter station" end
    return raw
end

local function profileSourceLabel(session)
    if not session then return nil end
    local profile = session.profile or {}
    local raw = tostring(session.profileSelectionSource or profile.profileSelectionSource or profile.orientationVariantSource or profile.chairOrientationVariantSource or "")
    if raw == "explicit_profile_orientation_variant"
        or raw == "explicit_chair_orientation_variant"
        or raw == "explicit_station_orientation_variant" then
        return session.interactionType == "station" and "station profile" or "loaded profile"
    end
    if raw == "explicit_profile" then return session.interactionType == "station" and "station profile" or "loaded profile" end
    if raw == "bed_type_average_low_confidence" then return "low-confidence fallback average" end
    if raw == "bed_type_average" then return "fallback average" end
    if raw == "fallback_profile" or raw == "fallback" or profile.isFallback == true then return "generated fallback" end
    if profile.profileBedTypeFallbackLowConfidence == true then return "low-confidence fallback average" end
    if profile.profileBedTypeFallback ~= nil then return "fallback average" end
    if profile.orientationVariantSource or profile.chairOrientationVariantSource or profile.stationOrientationVariantSource then return session.interactionType == "station" and "station profile" or "loaded profile" end
    if profile.externalProfile == true then return session.interactionType == "station" and "station profile" or "loaded profile" end
    return "loaded profile"
end

local function profileTypeLabel(session)
    if not session then return nil end
    local profile = session.profile or {}
    local raw = session.interactionType == "sleeping"
        and effectiveBedType(profile, session.slotName or session.slotKey)
        or (profile.bedType or profile.category or profile.type or profile.kind)
    raw = raw and tostring(raw) or ""
    if raw == "" or raw == "nil" then return nil end
    if session.interactionType == "sleeping" and (raw == "top_bunk" or raw == "bottom_bunk" or raw == "bunk" or raw == "bunk_bed") then
        return "bunk bed"
    end
    return raw
end

local function shortObjectId(obj)
    local raw = obj and obj.id and tostring(obj.id) or nil
    if not raw or raw == "" then return nil end
    raw = raw:gsub("^L?@?0x", "")
    if #raw > 6 then raw = raw:sub(-6) end
    return raw
end

local function readableActorLabel(label)
    local text = tostring(label or "")
    text = text:gsub("%s*%[Fill #%s*(%d+)%]", " - Fill %1")
    text = text:gsub("%s*%[Test #%s*(%d+)%]", " - Test %1")
    text = text:gsub("%s*%[borrowed%]", " - borrowed")
    return text
end

local function actorDisplayLabel(session, actor)
    if session and session.actorDisplayLabel and tostring(session.actorDisplayLabel) ~= "" then
        return readableActorLabel(session.actorDisplayLabel)
    end
    if session and session.calibrationFillSource ~= "borrowed" and session.calibrationFillLabel and tostring(session.calibrationFillLabel) ~= "" then
        return readableActorLabel(session.calibrationFillLabel)
    end
    local base = session.actorRecordId or session.actorId or (actor and (actor.recordId or actor.id))
    if not base then return nil end
    local recordId = tostring(session.actorRecordId or (actor and actor.recordId) or ""):lower()
    if session.calibrationFill == true
        or session.calibrationTestNpc == true
        or calibrationTestActors.isTestRecord(recordId) then
        local suffix = shortObjectId(actor) or shortObjectId({ id = session.actorId })
        if suffix then
            return tostring(base or "ken") .. "#" .. suffix
        end
    end
    return base
end

local function label(session)
    if not session then return "none" end
    local actor = session.actor or session.npc
    local object = session.object
    local actorLabel = actorDisplayLabel(session, actor)
    local objectLabel = session.objectRecordId or session.objectKey or session.objectId or (object and (object.recordId or object.id))
    if actorLabel and not objectLabel then
        return tostring(actorLabel) .. " (actor selected)"
    end
    local typeLabel = profileTypeLabel(session)
    local sourceLabel = tostring(profileSourceLabel(session) or "unknown source")
    if session.interactionType == "sitting" and session.lectureAudienceTarget == true then
        sourceLabel = "lecture audience; " .. sourceLabel
    end
    if typeLabel and typeLabel ~= sourceLabel then
        sourceLabel = typeLabel .. "; " .. sourceLabel
    end
    if session.interactionType == "station" then
        local prefix = tostring(objectLabel or "<station>")
        if actorLabel then
            prefix = tostring(actorLabel) .. " at " .. prefix
        end
        return prefix
            .. " ("
            .. friendlySlotLabel(session)
            .. "; "
            .. sourceLabel
            .. ")"
    end
    if actorLabel then
        return tostring(actorLabel)
            .. " at "
            .. tostring(objectLabel or "<furniture>")
            .. " ("
            .. friendlySlotLabel(session)
            .. "; "
            .. sourceLabel
            .. ")"
    end
    return tostring(objectLabel or "<furniture>")
        .. " ("
        .. friendlySlotLabel(session)
        .. "; "
        .. sourceLabel
        .. ")"
end

local function logFocus(ctx, session, reason)
    if not (ctx and ctx.infoLog and session and session.interactionType == "sitting") then return end
    local focus, detail, candidates = focusMetadata.logSummary(session)
    if focus == "" and candidates == "" then return end
    ctx.infoLog(
        "calibration_target_focus",
        "object", tostring(session.objectRecordId),
        "slot", tostring(session.slotName),
        "focus", tostring(focus),
        "focusModel", tostring(detail),
        "topFocuses", tostring(candidates),
        "source", tostring(reason or session.reason or "target")
    )
end

local function matches(data, session)
    if not (data and session) then return false end
    local dataObject = data.object
    local sessionObject = session.object
    local dataObjectKey = dataObject and tostring(dataObject.id or dataObject.recordId or "")
    local sessionObjectKey = session.objectKey or (sessionObject and tostring(sessionObject.id or sessionObject.recordId or ""))
    if dataObjectKey and dataObjectKey ~= "" and sessionObjectKey and sessionObjectKey ~= "" and dataObjectKey ~= sessionObjectKey then
        return false
    end
    return data.interactionType == session.interactionType
        and data.slotKey == session.slotKey
        and tostring(data.objectId or (data.object and data.object.recordId) or "") == tostring(session.objectRecordId or "")
end

local function slotObjectKey(slotKey)
    local raw = tostring(slotKey or "")
    if raw == "" then return nil end
    return raw:match("^(.-)::")
end

local function sameSleepObjectForUpdate(data, ev)
    if not (data and ev) then return false end
    if data.object and ev.object and data.object == ev.object then return true end
    local dataSlotObject = slotObjectKey(data.slotKey)
    local eventSlotObject = slotObjectKey(ev.slotKey)
    if dataSlotObject and eventSlotObject and dataSlotObject == eventSlotObject then
        return true
    end
    return false
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
    local labelCell = actor and actor.cell or object and object.cell or nil
    return {
        interactionType = data.interactionType,
        actor = actor,
        actorId = actor and actor.id or data.actorId,
        actorRecordId = actor and actor.recordId or data.actorRecordId,
        object = object,
        objectKey = tostring(object and (object.id or object.recordId) or data.objectId),
        objectRecordId = data.objectId or (object and object.recordId),
        model = data.model,
        cellName = ctx and ctx.cellName and labelCell and ctx.cellName(labelCell) or nil,
        slotKey = data.slotKey,
        slotName = data.slotName,
        slot = data.slot,
        profile = data.profile,
        profileId = data.profileId,
        profileSelectionTrace = data.profileSelectionTrace or (data.profile and data.profile.profileSelectionTrace),
        profileSelectionSource = data.profileSelectionSource or (data.profile and data.profile.profileSelectionSource),
        profileSelectionReason = data.profileSelectionReason or (data.profile and data.profile.profileSelectionReason),
        profileSelectionKey = data.profileSelectionKey or (data.profile and data.profile.profileSelectionKey),
        profileOffset = data.profileOffset,
        animationOffset = data.animationOffset,
        animationName = data.animationName or data.animation,
        calibration = data.calibration,
        calibrationFill = data.calibrationFill == true,
        calibrationTestNpc = data.calibrationTestNpc == true,
        approachPos = data.approachPos,
        finalPosition = data.finalPosition,
        finalRotation = data.finalRotation,
        facingDirection = data.facingDirection,
        facingObject = data.facingObject,
        facingObjectId = data.facingObjectId,
        facingObjectRefId = data.facingObjectRefId,
        facingObjectModel = data.facingObjectModel,
        facingObjectName = data.facingObjectName,
        facingObjectScale = data.facingObjectScale,
        facingObjectContentFile = data.facingObjectContentFile or (data.facingObject and data.facingObject.contentFile),
        facingObjectDistance = data.facingObjectDistance,
        facingKind = data.facingKind,
        facingReason = data.facingReason,
        facingObjectPosition = data.facingObjectPosition,
        facingCandidates = data.facingCandidates,
        ignoredFacingObject = data.ignoredFacingObject,
        ignoredFacingObjectId = data.ignoredFacingObjectId,
        ignoredFacingObjectRefId = data.ignoredFacingObjectRefId,
        ignoredFacingObjectModel = data.ignoredFacingObjectModel,
        ignoredFacingObjectName = data.ignoredFacingObjectName,
        ignoredFacingObjectScale = data.ignoredFacingObjectScale,
        ignoredFacingObjectContentFile = data.ignoredFacingObjectContentFile or (data.ignoredFacingObject and data.ignoredFacingObject.contentFile),
        ignoredFacingObjectDistance = data.ignoredFacingObjectDistance,
        ignoredFacingKind = data.ignoredFacingKind,
        ignoredFacingObjectPosition = data.ignoredFacingObjectPosition,
        ignoredFacingCandidates = data.ignoredFacingCandidates,
        ignoredFacingSurfaceHit = data.ignoredFacingSurfaceHit == true,
        ignoredFacingSurfaceSource = data.ignoredFacingSurfaceSource,
        ignoredFacingFocusDot = data.ignoredFacingFocusDot,
        tableClearanceFocusCleared = data.tableClearanceFocusCleared == true,
        tableClearanceFocusClearReason = data.tableClearanceFocusClearReason,
        lectureAudienceTarget = data.lectureAudienceTarget == true,
        lectureAudienceSource = data.audienceSource,
        lectureAudienceSessionId = data.lectureSessionId,
        manualAssignOverrideApplied = data.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = data.manualAssignOverrideReason,
        manualAssignOverrideReasons = data.manualAssignOverrideReasons,
        calibrationFillLabel = data.calibrationFillLabel,
        calibrationFillRole = data.calibrationFillRole,
        calibrationFillSource = data.calibrationFillSource,
        calibrationFillIndex = data.calibrationFillIndex,
        calibrationFillSessionId = data.calibrationFillSessionId,
        calibrationRuntimeObjectId = data.calibrationRuntimeObjectId,
        actorDisplayLabel = data.actorDisplayLabel,
        actorContentFile = data.actorContentFile or (actor and actor.contentFile),
        objectContentFile = data.objectContentFile or (object and object.contentFile),
        objectModelPath = data.objectModelPath or data.model,
        externalPhysicalClaimed = data.externalPhysicalClaimed == true,
        externalPhysicalClaimReason = data.externalPhysicalClaimReason,
        externalPhysicalClaimActorRecordId = data.externalPhysicalClaimActorRecordId,
        externalPhysicalClaimActorId = data.externalPhysicalClaimActorId,
        surfaceBlockerReason = data.surfaceBlockerReason,
        surfaceBlockerOverrideReason = data.surfaceBlockerOverrideReason,
        surfaceBlockerKind = data.surfaceBlockerKind,
        surfaceBlockerObjectId = data.surfaceBlockerObjectId,
        surfaceBlockerDistance = data.surfaceBlockerDistance,
        surfaceBlockerVertical = data.surfaceBlockerVertical,
        surfaceBlockerLocalReason = data.surfaceBlockerLocalReason,
        softBlockerReason = data.softBlockerReason,
        hardBlockerReason = data.hardBlockerReason,
        sleepSafetyReason = data.sleepSafetyReason,
        sleepSafetyDelta = data.sleepSafetyDelta,
        sleepSafetyLimit = data.sleepSafetyLimit,
        sleepSafetyOverrideReason = data.sleepSafetyOverrideReason,
        sleepSafetyRepairReason = data.sleepSafetyRepairReason,
        sleepSafetyRepairDelta = data.sleepSafetyRepairDelta,
        sleepSafetyRepairLimit = data.sleepSafetyRepairLimit,
        sleepCalibrationWarningReason = data.sleepCalibrationWarningReason,
        rejectionReason = data.rejectionReason,
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
        or text:find("menu_capture", 1, true) ~= nil
        or text:find("sharedray", 1, true) ~= nil
        or text:find("pending", 1, true) ~= nil
end

function M.rememberTarget(data, ctx, reason)
    if not (data and data.interactionType and (data.npc or data.actor) and data.object and data.slotKey) then return end
    local session = rememberFields(data, ctx, reason)
    M.lastTargets[data.interactionType] = session
    if shouldActivateSession(data, reason) then
        M.session = session
        if ctx and ctx.infoLog then
        ctx.infoLog("calibration_target_set", tostring(session.interactionType), label(session), "reason", tostring(reason or "remembered"), "actorSource", tostring(session.actorContentFile or "dynamic / unknown"), "furnitureSource", tostring(session.objectContentFile or "dynamic / unknown"), "furnitureModel", tostring(session.objectModelPath or session.model))
            ctx.infoLog(
                "calibration_target_profile_selection",
                tostring(session.interactionType),
                "object", tostring(session.objectRecordId),
                "slot", tostring(session.slotName),
                "profile", tostring(session.profileId),
                "source", tostring(session.profileSelectionSource),
                "selectionKey", tostring(session.profileSelectionKey),
                "selectionReason", tostring(session.profileSelectionReason)
            )
            ctx.infoLog("calibration_target_display_state", label(session), "source", tostring(reason or "remembered"))
            logFocus(ctx, session, reason or "remembered")
        end
    end
end

function M.captureActorTarget(data, ctx, reason)
    if not (data and (data.npc or data.actor)) then return nil, "actor_invalid" end
    data.interactionType = data.interactionType == "sleeping" and "sleeping"
        or (data.interactionType == "station" and "station" or "sitting")
    M.session = rememberFields(data, ctx, reason or "actor_capture")
    if ctx and ctx.infoLog then
        ctx.infoLog("calibration actor target captured", tostring(data.interactionType), label(M.session), "reason", tostring(reason or "actor_capture"), "actorSource", tostring(M.session.actorContentFile or "dynamic / unknown"))
        ctx.infoLog("calibration_target_set", tostring(data.interactionType), label(M.session), "reason", tostring(reason or "actor_capture"), "actorSource", tostring(M.session.actorContentFile or "dynamic / unknown"))
        ctx.infoLog("calibration_target_display_state", label(M.session), "source", tostring(reason or "actor_capture"))
        logFocus(ctx, M.session, reason or "actor_capture")
    end
    return M.session, "ok"
end

local function scoreTargetData(data, ctx, playerPos, maxDistance)
    local actor = data and (data.npc or data.actor) or nil
    if not (data and ctx and ctx.isObjValid and ctx.isObjValid(data.object)) then return nil end
    if data.interactionType ~= "station" and actor ~= nil and not ctx.isObjValid(actor) then return nil end
    if not targetInCurrentCell(data, ctx) then return nil end
    local dist = 0
    if playerPos then
        ---@type any
        local actorAny = actor
        local actorPos = actorAny and actorAny.position or nil
        local actorDist = actorPos and (actorPos - playerPos):length() or math.huge
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
        if data and (data.interactionType == "sleeping" or data.interactionType == "sitting" or data.interactionType == "station") then
            local score = scoreTargetData(data, ctx, playerPos)
            if score and (not bestScore or score < bestScore) then
                best, bestScore = data, score
            end
        end
    end
    if best then return best, "active_near_player" end

    for _, interactionType in ipairs({ "sleeping", "sitting", "station" }) do
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
    ctx.infoLog("calibration_target_set", tostring(M.session.interactionType), label(M.session), "source", tostring(source), "reason", tostring(reason), "actorSource", tostring(M.session.actorContentFile or "dynamic / unknown"), "furnitureSource", tostring(M.session.objectContentFile or "dynamic / unknown"), "furnitureModel", tostring(M.session.objectModelPath or M.session.model))
    ctx.infoLog(
        "calibration_target_profile_selection",
        tostring(M.session.interactionType),
        "object", tostring(M.session.objectRecordId),
        "slot", tostring(M.session.slotName),
        "profile", tostring(M.session.profileId),
        "source", tostring(M.session.profileSelectionSource),
        "selectionKey", tostring(M.session.profileSelectionKey),
        "selectionReason", tostring(M.session.profileSelectionReason)
    )
    ctx.infoLog("calibration_target_display_state", label(M.session), "source", tostring(source))
    logFocus(ctx, M.session, source)
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
    if session.interactionType ~= "station" and session.actor ~= nil and not ctx.isObjValid(session.actor) then return nil, "actor_invalid" end
    if session.actor ~= nil and not session.object and not session.slotKey then
        if not targetInCurrentCell(session, ctx) then
            M.session = nil
            return nil, "target_wrong_cell"
        end
        return session, "ok"
    end
    if not ctx.isObjValid(session.object) then return nil, "object_invalid" end
    if not targetInCurrentCell(session, ctx) then
        M.session = nil
        return nil, "target_wrong_cell"
    end
    if not session.slotKey then return nil, "slot_invalid" end
    if session.interactionType == "station" then return session, "ok" end
    if not session.actor then return session, "ok" end
    local data = ctx.assignedActors and ctx.assignedActors[session.actor.id] or nil
    if data and not matches(data, session) then return nil, "lock_mismatch" end
    return session, "ok"
end

function M.clearForCellChange(ctx, reason)
    local hadTarget = M.session ~= nil or M.lastTargets.sitting ~= nil or M.lastTargets.sleeping ~= nil or M.lastTargets.station ~= nil
    if not hadTarget then return false end
    if ctx and ctx.infoLog then
        ctx.infoLog("calibration target cleared", "cell_change", M.session and label(M.session) or "last_targets", "reason", tostring(reason or "cell_change"))
        ctx.infoLog("calibration_target_display_state", "Target: none selected", "source", tostring(reason or "cell_change"))
    end
    M.session = nil
    M.lastTargets.sitting = nil
    M.lastTargets.sleeping = nil
    M.lastTargets.station = nil
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
        facingObject = session.facingObject,
        facingObjectId = session.facingObjectId,
        facingObjectRefId = session.facingObjectRefId,
        facingObjectModel = session.facingObjectModel,
        facingObjectName = session.facingObjectName,
        facingObjectScale = session.facingObjectScale,
        facingKind = session.facingKind,
        facingReason = session.facingReason,
        facingObjectPosition = session.facingObjectPosition,
        facingCandidates = session.facingCandidates,
        ignoredFacingObject = session.ignoredFacingObject,
        ignoredFacingObjectId = session.ignoredFacingObjectId,
        ignoredFacingObjectRefId = session.ignoredFacingObjectRefId,
        ignoredFacingObjectModel = session.ignoredFacingObjectModel,
        ignoredFacingObjectName = session.ignoredFacingObjectName,
        ignoredFacingObjectScale = session.ignoredFacingObjectScale,
        ignoredFacingKind = session.ignoredFacingKind,
        ignoredFacingObjectPosition = session.ignoredFacingObjectPosition,
        ignoredFacingCandidates = session.ignoredFacingCandidates,
        ignoredFacingSurfaceHit = session.ignoredFacingSurfaceHit == true,
        ignoredFacingSurfaceSource = session.ignoredFacingSurfaceSource,
        ignoredFacingFocusDot = session.ignoredFacingFocusDot,
        tableClearanceFocusCleared = session.tableClearanceFocusCleared == true,
        tableClearanceFocusClearReason = session.tableClearanceFocusClearReason,
        currentHour = ctx.profiles.getGameHour(),
        calibrationAction = true,
        calibrationReason = reason or "calibration",
        calibration = session.calibration,
        ignoreTimeGate = true,
        calibrationFill = session.calibrationFill == true,
        calibrationTestNpc = session.calibrationTestNpc == true,
        calibrationFillLabel = session.calibrationFillLabel,
        calibrationFillRole = session.calibrationFillRole,
        calibrationFillSource = session.calibrationFillSource,
        calibrationFillIndex = session.calibrationFillIndex,
        calibrationFillSessionId = session.calibrationFillSessionId,
        calibrationRuntimeObjectId = session.calibrationRuntimeObjectId,
        actorDisplayLabel = session.actorDisplayLabel,
        lectureAudienceTarget = session.lectureAudienceTarget == true,
        lectureAudienceSource = session.lectureAudienceSource,
        lectureAudienceSessionId = session.lectureAudienceSessionId,
    }
end

local function refreshHold(session, ctx, reason)
    if not (session and ctx and ctx.assignedActors and session.actor and session.actor.id) then return false end
    local data = ctx.assignedActors[session.actor.id]
    if not matches(data, session) then return false end
    session.profileOffset = data.profileOffset or session.profileOffset
    session.animationOffset = data.animationOffset or session.animationOffset
    session.animationName = data.animationName or data.animation or session.animationName
    session.calibration = data.calibration or session.calibration
    session.finalPosition = data.finalPosition or session.finalPosition
    session.finalRotation = data.finalRotation or session.finalRotation
    session.approachPos = data.approachPos or session.approachPos
    session.facingDirection = data.facingDirection or session.facingDirection
    session.facingObject = data.facingObject or session.facingObject
    session.facingObjectId = data.facingObjectId or session.facingObjectId
    session.facingObjectRefId = data.facingObjectRefId or session.facingObjectRefId
    session.facingObjectModel = data.facingObjectModel or session.facingObjectModel
    session.facingObjectName = data.facingObjectName or session.facingObjectName
    session.facingObjectScale = data.facingObjectScale or session.facingObjectScale
    session.facingKind = data.facingKind or session.facingKind
    session.facingReason = data.facingReason or session.facingReason
    session.facingObjectPosition = data.facingObjectPosition or session.facingObjectPosition
    session.facingCandidates = data.facingCandidates or session.facingCandidates
    session.ignoredFacingObject = data.ignoredFacingObject or session.ignoredFacingObject
    session.ignoredFacingObjectId = data.ignoredFacingObjectId or session.ignoredFacingObjectId
    session.ignoredFacingObjectRefId = data.ignoredFacingObjectRefId or session.ignoredFacingObjectRefId
    session.ignoredFacingObjectModel = data.ignoredFacingObjectModel or session.ignoredFacingObjectModel
    session.ignoredFacingObjectName = data.ignoredFacingObjectName or session.ignoredFacingObjectName
    session.ignoredFacingObjectScale = data.ignoredFacingObjectScale or session.ignoredFacingObjectScale
    session.ignoredFacingKind = data.ignoredFacingKind or session.ignoredFacingKind
    session.ignoredFacingObjectPosition = data.ignoredFacingObjectPosition or session.ignoredFacingObjectPosition
    session.ignoredFacingCandidates = data.ignoredFacingCandidates or session.ignoredFacingCandidates
    session.ignoredFacingSurfaceHit = data.ignoredFacingSurfaceHit == true or session.ignoredFacingSurfaceHit
    session.ignoredFacingSurfaceSource = data.ignoredFacingSurfaceSource or session.ignoredFacingSurfaceSource
    session.ignoredFacingFocusDot = data.ignoredFacingFocusDot or session.ignoredFacingFocusDot
    session.tableClearanceFocusCleared = data.tableClearanceFocusCleared == true or session.tableClearanceFocusCleared
    session.tableClearanceFocusClearReason = data.tableClearanceFocusClearReason or session.tableClearanceFocusClearReason
    session.lectureAudienceTarget = data.lectureAudienceTarget == true
    session.lectureAudienceSource = data.audienceSource or session.lectureAudienceSource
    session.lectureAudienceSessionId = data.lectureSessionId or session.lectureAudienceSessionId
    session.calibrationFillLabel = data.calibrationFillLabel or session.calibrationFillLabel
    session.calibrationFillRole = data.calibrationFillRole or session.calibrationFillRole
    session.calibrationFillSource = data.calibrationFillSource or session.calibrationFillSource
    session.calibrationFillIndex = data.calibrationFillIndex or session.calibrationFillIndex
    session.calibrationFillSessionId = data.calibrationFillSessionId or session.calibrationFillSessionId
    session.calibrationRuntimeObjectId = data.calibrationRuntimeObjectId or session.calibrationRuntimeObjectId
    session.actorDisplayLabel = data.actorDisplayLabel or session.actorDisplayLabel
    session.surfaceBlockerReason = data.surfaceBlockerReason
    session.surfaceBlockerOverrideReason = data.surfaceBlockerOverrideReason
    session.surfaceBlockerKind = data.surfaceBlockerKind
    session.surfaceBlockerObjectId = data.surfaceBlockerObjectId
    session.surfaceBlockerDistance = data.surfaceBlockerDistance
    session.surfaceBlockerVertical = data.surfaceBlockerVertical
    session.surfaceBlockerLocalReason = data.surfaceBlockerLocalReason
    session.softBlockerReason = data.softBlockerReason
    session.hardBlockerReason = data.hardBlockerReason
    session.sleepSafetyReason = data.sleepSafetyReason
    session.sleepSafetyDelta = data.sleepSafetyDelta
    session.sleepSafetyLimit = data.sleepSafetyLimit
    session.sleepSafetyOverrideReason = data.sleepSafetyOverrideReason
    session.sleepSafetyRepairReason = data.sleepSafetyRepairReason
    session.sleepSafetyRepairDelta = data.sleepSafetyRepairDelta
    session.sleepSafetyRepairLimit = data.sleepSafetyRepairLimit
    session.sleepCalibrationWarningReason = data.sleepCalibrationWarningReason
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

function M.captureStationTarget(data, ctx, reason)
    if not (data and data.object and data.slotKey) then return nil, "station_invalid" end
    data.interactionType = "station"
    M.session = rememberFields(data, ctx, reason or "station_capture")
    M.lastTargets.station = M.session
    if ctx and ctx.infoLog then
        ctx.infoLog("calibration station target captured", label(M.session), "reason", tostring(reason or "station_capture"))
        ctx.infoLog("calibration_target_set", "station", label(M.session), "reason", tostring(reason or "station_capture"), "actorSource", tostring(M.session.actorContentFile or "dynamic / unknown"), "furnitureSource", tostring(M.session.objectContentFile or "dynamic / unknown"), "furnitureModel", tostring(M.session.objectModelPath or M.session.model))
        ctx.infoLog(
            "calibration_target_profile_selection",
            "station",
            "object", tostring(M.session.objectRecordId),
            "slot", tostring(M.session.slotName),
            "profile", tostring(M.session.profileId),
            "source", tostring(M.session.profileSelectionSource),
            "selectionKey", tostring(M.session.profileSelectionKey),
            "selectionReason", tostring(M.session.profileSelectionReason)
        )
        ctx.infoLog("calibration_target_display_state", label(M.session), "source", tostring(reason or "station_capture"))
        logFocus(ctx, M.session, reason or "station_capture")
    end
    return M.session, "ok"
end

function M.captureFurnitureTarget(data, ctx, reason)
    if not (data and data.object and data.slotKey and (data.interactionType == "sitting" or data.interactionType == "sleeping")) then
        return nil, "target_invalid"
    end
    M.session = rememberFields(data, ctx, reason or "furniture_capture")
    M.lastTargets[data.interactionType] = M.session
    if ctx and ctx.infoLog then
        ctx.infoLog("calibration furniture target captured", tostring(data.interactionType), label(M.session), "reason", tostring(reason or "furniture_capture"))
        ctx.infoLog("calibration_target_set", tostring(data.interactionType), label(M.session), "reason", tostring(reason or "furniture_capture"), "actorSource", tostring(M.session.actorContentFile or "dynamic / unknown"), "furnitureSource", tostring(M.session.objectContentFile or "dynamic / unknown"), "furnitureModel", tostring(M.session.objectModelPath or M.session.model))
        ctx.infoLog(
            "calibration_target_profile_selection",
            tostring(data.interactionType),
            "object", tostring(M.session.objectRecordId),
            "slot", tostring(M.session.slotName),
            "profile", tostring(M.session.profileId),
            "source", tostring(M.session.profileSelectionSource),
            "selectionKey", tostring(M.session.profileSelectionKey),
            "selectionReason", tostring(M.session.profileSelectionReason)
        )
        ctx.infoLog("calibration_target_display_state", label(M.session), "source", tostring(reason or "furniture_capture"))
        logFocus(ctx, M.session, reason or "furniture_capture")
    end
    return M.session, "ok"
end

function M.currentSession(interactionType, ctx)
    local session, status = validateSession(interactionType, ctx)
    if session then
        refreshHold(session, ctx, status or "current_session")
        return session, status
    end
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
    if not (ctx and ctx.profiles and (ctx.profiles.INTERACTION_TYPES[interactionType] or interactionType == "auto" or interactionType == "station")) then
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
                precover = ctx.precover == true,
                bridge = ctx.bridge == true,
                visibilityReason = ctx.visibilityReason,
                failSafeDuration = tonumber(ctx.failSafeDuration),
                actorCount = tonumber(ctx.actorCount),
                cellName = ctx.cellName,
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
        if sameSleepObjectForUpdate(data, ev) then
            ctx.debugLog("sleep calibration update corrected slot", npc.recordId or npc.id, "expected", tostring(data.slotKey), "got", tostring(ev.slotKey), "object", tostring(data.objectId or ev.objectId))
        else
            ctx.debugLog("sleep calibration update rejected", npc.recordId or npc.id, "reason", "slot_mismatch", "expected", tostring(data.slotKey), "got", tostring(ev.slotKey))
            return
        end
    end

    data.object = ev.object or data.object
    data.objectId = ev.objectId or data.objectId
    data.slot = ev.slot or data.slot
    data.slotKey = ev.slotKey or data.slotKey
    data.slotName = ev.slotName or data.slotName
    data.slotIndex = ev.slotIndex or data.slotIndex
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
    local function clearable(key)
        if ev[key] ~= nil or ev.safetyEvaluated == true then
            data[key] = ev[key]
        end
    end
    clearable("surfaceBlockerReason")
    clearable("surfaceBlockerOverrideReason")
    clearable("surfaceBlockerKind")
    clearable("surfaceBlockerObjectId")
    clearable("surfaceBlockerDistance")
    clearable("surfaceBlockerVertical")
    clearable("surfaceBlockerLocalReason")
    clearable("softBlockerReason")
    clearable("hardBlockerReason")
    clearable("sleepSafetyReason")
    clearable("sleepSafetyDelta")
    clearable("sleepSafetyLimit")
    clearable("sleepSafetyOverrideReason")
    clearable("sleepSafetyRepairReason")
    clearable("sleepSafetyRepairDelta")
    clearable("sleepSafetyRepairLimit")
    clearable("sleepCalibrationWarningReason")
    data.surfaceMode = ev.sleepSurfaceMode or ev.surfaceMode or data.surfaceMode
    data.surfaceSamples = ev.sleepSurfaceSamples or ev.surfaceSamples or data.surfaceSamples
    data.sleepSurfaceMode = ev.sleepSurfaceMode or ev.surfaceMode or data.sleepSurfaceMode
    data.sleepRawSurfaceMode = ev.sleepRawSurfaceMode or ev.rawSurfaceMode or data.sleepRawSurfaceMode
    data.rawSurfaceMode = ev.rawSurfaceMode or ev.sleepRawSurfaceMode or data.rawSurfaceMode
    data.sleepSurfaceAnchorStabilized = ev.sleepSurfaceAnchorStabilized == true or data.sleepSurfaceAnchorStabilized == true
    data.sleepSurfaceSamples = ev.sleepSurfaceSamples or ev.surfaceSamples or data.sleepSurfaceSamples
    data.sleepRawSurfacePosition = ev.sleepRawSurfacePosition or ev.rawBedTop or data.sleepRawSurfacePosition
    data.rawBedTop = ev.rawBedTop or ev.sleepRawSurfacePosition or data.rawBedTop

    M.rememberTarget(data, ctx, "sleep_calibration_update")

    -- Keep normal correction bookkeeping from interrupting active calibration nudges.
    local now = ctx.now and ctx.now() or nil
    data.calibrationMenuHoldUntil = (now or 0) + 45
    data.teleportBusySkips = nil
    data.teleportBusyFirstAt = nil

    if data.state == ctx.states.interacting or data.state == ctx.states.transitioning then
        local targetYaw = data.finalRotation or npc.rotation:getYaw()
        if ctx.smoothMove and ctx.smoothMove(npc, data, ev.finalPosition, targetYaw, "sleep_calibration_smooth", ev.reason) then
            ctx.infoLog("sleep calibration smooth queued", npc.recordId or npc.id, "reason", tostring(ev.reason or "calibration"), "object", tostring(data.objectId), "profile", tostring(data.profileId), "slot", tostring(data.slotName), "final", tostring(ev.finalPosition), "rotation", tostring(data.finalRotation))
            return
        end
        local ok, err = ctx.tryTeleport(npc, npc.cell, ev.finalPosition, { rotation = ctx.rotationFromYaw(targetYaw, npc.rotation) })
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
