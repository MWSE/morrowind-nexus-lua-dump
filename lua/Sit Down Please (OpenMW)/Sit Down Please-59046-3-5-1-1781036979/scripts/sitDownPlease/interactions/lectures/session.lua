-- interactions/lectures/session.lua
---@omw-context none
-- Runtime lecture presenter/session ownership for calibrated lecterns.

local M = {}
local claims = require('scripts/sitDownPlease/assignment/claims')
local lecternPolicy = require('scripts/sitDownPlease/interactions/lectures/presenterPolicy')
local lectureAudience = require('scripts/sitDownPlease/interactions/lectures/audience')
local lectureAnimation = require('scripts/sitDownPlease/interactions/lectures/animation')
local lectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')
local presenterApproach = require('scripts/sitDownPlease/interactions/lectures/presenterApproach')
local persistedActors = require('scripts/sitDownPlease/interactions/lectures/persistedActors')
local restoreSafety = require('scripts/sitDownPlease/interactions/lectures/restoreSafety')

local stationClaims = claims.createRegistry({ claimType = "station", source = "station_assignment" })
local pendingStationClaims = claims.createRegistry({ claimType = "station_pending", source = "station_assignment" })
local assignmentsBySlot = stationClaims.byTarget
local assignmentByNpc = stationClaims.byActor
local pendingBySlot = pendingStationClaims.byTarget
local pendingByNpc = pendingStationClaims.byActor
local scanElapsed = 0
local lastAudienceRebalanceBySlot = {}
local lastLectureStartWindowSkipBySlot = {}
local pendingInitialStationActorIds = {}
local recentlyReleasedForSleepByNpc = {}
local lectureSessionsByCell = {}
local recentlyCompletedLectureSessions = {}
local lectureReleaseSequenceBySlot = {}
local validObject
local STATION_ARRIVAL_RADIUS = 64
local STATION_FORCE_CLAIM_SECONDS = 14
local STATION_DEBUG_FORCE_CLAIM_SECONDS = 3.0
local STATION_OBJECT_APPROACH_RADIUS = 420
local LECTERN_SMOOTH_ENTRY_MAX_DISTANCE = 320
local LECTERN_SMOOTH_ENTRY_OBJECT_RADIUS = 96
local LECTERN_SMOOTH_ENTRY_STATION_RADIUS = 180
local STATION_TRAVEL_RETRY_SECONDS = 2.5
local STATION_PENDING_LOG_SECONDS = 8
local STATION_CLAIM_DRIFT_GRACE_SECONDS = 4.0
local STATION_PRESENTER_ENTRY_DRIFT_GRACE_SECONDS = 14.0
local LECTURE_START_INTERVAL_MINUTES = 30
local LECTURE_START_WINDOW_MINUTES = 10
local INITIAL_ACTIVE_LECTURE_CHANCE = 0.35
local LECTURE_END_APPLAUSE_CHANCE = 0.25
local MIN_AUDIENCE_FOR_PRESENTER_ANIMATION = 2
local LECTURE_STATION_COOLDOWN_SECONDS = 3600
local LECTURE_PRESENTER_COOLDOWN_SECONDS = 24 * 3600
local LECTURE_AUDIENCE_RADIUS = 1800
local LECTURE_RESTORE_VISIBLE_GRACE_SECONDS = 60
local LECTURE_WAIT_ADVANCE_SECONDS = 5 * 60
local LECTERN_NEAR_MARKER_HOLD_RADIUS = 14
local LECTERN_ALREADY_AT_MARKER_RADIUS = 128
local LECTERN_APPROACH_EXTRA_DISTANCE = 56
local LECTERN_APPROACH_ACCEPT_RADIUS = 96
local LECTERN_CLOSE_OBJECT_ACCEPT_RADIUS = 160
local LECTERN_STABLE_CLOSE_SECONDS = 8
local LECTERN_TRAVEL_TOLERANCE = 12
local lastLectureCooldownSkipByKey = {}
local lastNoAudienceLogBySlot = {}

local function audienceAnimationsEnabled()
    return not (lectureAnimation.audienceAnimationsEnabled and lectureAnimation.audienceAnimationsEnabled() ~= true)
end

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function stationAllowedByReleaseGate(ctx, cell, options)
    local gate = ctx and ctx.releaseSafetyGate or nil
    if not (gate and gate.stationAllowed) then return true, "gate_unavailable" end
    return gate.stationAllowed(ctx.settings, cell, options)
end

local function hasFlag(profile, flag)
    local want = lower(flag)
    for _, value in ipairs(profile and profile.flags or {}) do
        if lower(value) == want then return true end
    end
    return false
end

local function yawFromDirection(direction, fallbackYaw)
    if direction and direction.x and direction.y then
        return math.atan2(direction.x, direction.y)
    end
    return fallbackYaw or 0
end

local function profileWithCalibration(profile, calibration)
    if not profile then return nil end
    calibration = calibration or {}
    local copy = {}
    for k, v in pairs(profile) do copy[k] = v end
    local baseOffset = profile.localOffset or {}
    copy.localOffset = {
        x = (tonumber(baseOffset.x) or 0) + (tonumber(calibration.x) or 0),
        y = (tonumber(baseOffset.y) or 0) + (tonumber(calibration.y) or 0),
        z = (tonumber(baseOffset.z) or 0) + (tonumber(calibration.z) or 0),
    }
    copy.facingYawDeg = (tonumber(profile.facingYawDeg) or 0) + (tonumber(calibration.yaw) or 0)
    return copy
end

validObject = function(ctx, obj)
    if ctx and ctx.isObjValid then return ctx.isObjValid(obj) == true end
    return obj ~= nil and obj.position ~= nil
end

local function currentHourAllowsStation(ctx)
    local settings = ctx.settings or {}
    if settings.enableSitting ~= true then return false, "sitting_disabled" end
    if settings.stationLecternEnabled == false then return false, "lectern_station_disabled" end
    local hour = ctx.profiles and ctx.profiles.getGameHour and ctx.profiles.getGameHour() or nil
    if hour == nil then return true, nil end
    if ctx.profiles and ctx.profiles.isHourInWindow
        and ctx.profiles.isHourInWindow(hour, settings.serviceNpcOffHoursStartHour or 20, settings.serviceNpcOffHoursEndHour or 8) then
        return false, "off_hours"
    end
    if ctx.profiles and ctx.profiles.isHourInWindow
        and ctx.profiles.isHourInWindow(hour, settings.sleepStartHour or 22, settings.sleepEndHour or 8) then
        return false, "sleep_window"
    end
    return true, nil
end

local function hasSavedLectureSessions(name)
    local byCell = lectureSessionsByCell[name]
    if not byCell then return false end
    for _ in pairs(byCell) do return true end
    return false
end

local function regularLectureStartWindow(ctx)
    local hour = ctx and ctx.profiles and ctx.profiles.getGameHour and ctx.profiles.getGameHour() or nil
    if hour == nil then return true, nil, nil end
    local totalMinutes = (tonumber(hour) or 0) * 60
    totalMinutes = totalMinutes % (24 * 60)
    local intoInterval = totalMinutes % LECTURE_START_INTERVAL_MINUTES
    local minutesFromStart = math.min(intoInterval, LECTURE_START_INTERVAL_MINUTES - intoInterval)
    if minutesFromStart <= LECTURE_START_WINDOW_MINUTES then
        return true, nil, minutesFromStart
    end
    return false, "outside_regular_lecture_start_window", minutesFromStart
end

local function gameTime(ctx)
    local getGameTime = ctx and ctx.profiles and ctx.profiles.getGameTime
    if getGameTime then
        local value = getGameTime()
        if value ~= nil then return value end
    end
    return ctx and ctx.now and ctx.now() or 0
end

local function runtimeNow(ctx)
    if ctx and ctx.now then return ctx.now() end
    return gameTime(ctx)
end

local function shouldLogStartWindowSkip(slotKey, ctx)
    if not (slotKey and ctx and ctx.now) then return false end
    local now = ctx.now()
    local last = tonumber(lastLectureStartWindowSkipBySlot[slotKey]) or -999
    if now - last < 45 then return false end
    lastLectureStartWindowSkipBySlot[slotKey] = now
    return true
end

local function stationSlotKey(ctx, obj, profile)
    return claims.targetKey(ctx, obj, "station:" .. tostring(profile and profile.slotName or "station"), "station")
end

local function actorLabel(npc)
    return tostring(npc and (npc.recordId or npc.id) or "<npc>")
end

local function resolvePresenterOrigin(npc, ctx, options)
    options = options or {}
    local originPosition = options.originPosition
    local originRotation = options.originRotation
    local originSource = options.originSource
    if not originPosition and ctx and ctx.stationPresenterOrigin then
        local priorPosition, priorRotation, priorSource = ctx.stationPresenterOrigin(npc)
        if priorPosition then
            originPosition = priorPosition
            originRotation = priorRotation
            originSource = priorSource or "previous_assignment_origin"
        end
    end
    if not originPosition then
        originPosition = npc and npc.position or nil
        originRotation = npc and npc.rotation or nil
        originSource = originSource or "current_actor_position"
    elseif not originRotation then
        originRotation = npc and npc.rotation or nil
    end
    return originPosition, originRotation, originSource
end

local function cellIsInterior(cell)
    if not cell then return false end
    local ok, value = pcall(function() return cell.isExterior end)
    if ok and type(value) == "boolean" then return value ~= true end
    if type(cell.isExterior) == "function" then
        local okMethod, methodValue = pcall(function() return cell:isExterior() end)
        if okMethod and type(methodValue) == "boolean" then return methodValue ~= true end
    end
    return true
end

local function cellName(ctx, cell)
    if ctx and ctx.cellName and cell then
        local ok, value = pcall(ctx.cellName, cell)
        if ok and value then return tostring(value) end
    end
    return tostring(cell and cell.name or "")
end

local function positionSnapshot(pos)
    if not pos then return nil end
    return { x = pos.x or 0, y = pos.y or 0, z = pos.z or 0 }
end

local function positionFromSnapshot(ctx, pos)
    if not pos then return nil end
    if ctx and ctx.util and ctx.util.vector3 then
        return ctx.util.vector3(pos.x or 0, pos.y or 0, pos.z or 0)
    end
    return pos
end

local function rotationYawSnapshot(rotation)
    if type(rotation) == "number" then return tonumber(rotation) or 0 end
    if not rotation then return nil end
    local ok, yaw = pcall(function() return rotation:getYaw() end)
    if ok and yaw ~= nil then return tonumber(yaw) or 0 end
    return nil
end

local function rotationFromSnapshot(ctx, yaw, fallback)
    local value = tonumber(yaw)
    if value == nil then return fallback end
    if ctx and ctx.rotationFromYaw then
        return ctx.rotationFromYaw(value, fallback)
    end
    return fallback
end

local function snapshotAudience(data)
    local snapshot = {}
    for _, item in pairs(data and data.audience or {}) do
        local npc = item and item.npc or nil
        if npc then
            snapshot[#snapshot + 1] = {
                actorRecordId = npc.recordId,
                actorId = npc.id,
                actorPosition = positionSnapshot(npc.position),
                stationSlotKey = item.stationSlotKey,
                sector = item.sector,
                originPosition = positionSnapshot(item.originPosition),
                originYaw = rotationYawSnapshot(item.originRotation),
                returnMode = item.returnMode,
                wasAlreadySitting = item.wasAlreadySitting == true,
                originalAnimation = item.originalAnimation,
            }
        end
    end
    return snapshot
end

local function copyPositionSnapshot(pos)
    if not (type(pos) == "table" and pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then return nil end
    return {
        x = tonumber(pos.x) or 0,
        y = tonumber(pos.y) or 0,
        z = tonumber(pos.z) or 0,
    }
end

local function copyAudienceSnapshot(audience)
    local copy = {}
    for _, item in ipairs(audience or {}) do
        if item and (item.actorId or item.actorRecordId) then
            copy[#copy + 1] = {
                actorRecordId = item.actorRecordId,
                actorId = item.actorId,
                actorPosition = copyPositionSnapshot(item.actorPosition),
                stationSlotKey = item.stationSlotKey,
                sector = item.sector,
                originPosition = copyPositionSnapshot(item.originPosition),
                originYaw = tonumber(item.originYaw) or rotationYawSnapshot(item.originRotation),
                returnMode = item.returnMode,
                wasAlreadySitting = item.wasAlreadySitting == true,
                originalAnimation = item.originalAnimation,
            }
        end
    end
    return copy
end

local function copySessionSnapshot(session)
    if not (type(session) == "table" and session.cellName and session.objectId and (session.actorId or session.actorRecordId)) then
        return nil
    end
    return {
        key = session.key,
        cellName = tostring(session.cellName),
        objectId = session.objectId,
        objectPosition = copyPositionSnapshot(session.objectPosition),
        actorRecordId = session.actorRecordId,
        actorId = session.actorId,
        actorPosition = copyPositionSnapshot(session.actorPosition),
        originPosition = copyPositionSnapshot(session.originPosition),
        originYaw = tonumber(session.originYaw) or rotationYawSnapshot(session.originRotation),
        profileId = session.profileId,
        slotName = session.slotName,
        releaseAt = tonumber(session.releaseAt),
        audience = copyAudienceSnapshot(session.audience),
        savedAt = tonumber(session.savedAt),
    }
end

local function positionDistance(a, b)
    if not (a and b) then return math.huge end
    local ax, ay, az = a.x or 0, a.y or 0, a.z or 0
    local bx, by, bz = b.x or 0, b.y or 0, b.z or 0
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function flatDirection(util, fromPos, toPos)
    if not (util and fromPos and toPos) then return nil end
    local dx = (toPos.x or 0) - (fromPos.x or 0)
    local dy = (toPos.y or 0) - (fromPos.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    return util.vector3(dx / len, dy / len, 0)
end

local function objectForward(util, obj)
    if not util then return nil end
    local yaw = 0
    if obj and obj.rotation and obj.rotation.getYaw then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then yaw = value end
    end
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

local function audienceSeatCompatibleWithLectern(ctx, seatObj, seatProfile, lecternPos)
    if not (ctx and ctx.util and seatObj and seatObj.position and seatProfile and lecternPos) then return false, "missing_audience_geometry" end
    local category = lower(seatProfile.seatCategory or seatProfile.type or seatProfile.seatType)
    local mode = lower(seatProfile.rotationMode)
    local direction = flatDirection(ctx.util, seatObj.position, lecternPos)
    if not direction then return false, "missing_audience_direction" end
    local forward = objectForward(ctx.util, seatObj)
    local forwardDot = forward and ((forward.x or 0) * (direction.x or 0) + (forward.y or 0) * (direction.y or 0)) or nil
    if category == "backed_chair"
        or mode == "respectfurnitureforward"
        or mode == "chairforward"
        or mode == "objectforward"
        or mode == "useobjectyaw" then
        if forwardDot and forwardDot < 0.35 then return false, "audience_chair_faces_away" end
    elseif category == "single_seat_bench" then
        if forwardDot and math.max(forwardDot, -forwardDot) < 0.25 then return false, "audience_single_seat_sideways" end
    end
    return true, nil
end

local function stationHasPlausibleAudience(cell, obj, ctx)
    if not (cell and cell.getAll and obj and obj.position and ctx and ctx.profiles and ctx.profiles.getProfileForObject) then
        return false, "missing_audience_scan_context"
    end
    local scanned, relevant, compatible = 0, 0, 0
    for _, candidate in ipairs(cell:getAll()) do
        if candidate ~= obj and validObject(ctx, candidate) and candidate.position then
            local dist = (candidate.position - obj.position):length()
            if dist <= LECTURE_AUDIENCE_RADIUS then
                scanned = scanned + 1
                local seatProfile = ctx.profiles.getProfileForObject(candidate, "sitting", ctx.settings)
                if seatProfile and seatProfile.interactionType == "sitting" then
                    relevant = relevant + 1
                    local ok = audienceSeatCompatibleWithLectern(ctx, candidate, seatProfile, obj.position)
                    if ok then
                        compatible = compatible + 1
                        return true, nil, scanned, relevant, compatible
                    end
                end
            end
        end
    end
    return false, "no_plausible_audience_seat", scanned, relevant, compatible
end

local function pendingDistance(npc, pending)
    local dist = npc and npc.position and pending and pending.stationPos and (npc.position - pending.stationPos):length() or math.huge
    local objectDist = npc and npc.position and pending and pending.object and pending.object.position and (npc.position - pending.object.position):length() or math.huge
    local approachDist = npc and npc.position and pending and pending.approachPos and (npc.position - pending.approachPos):length() or math.huge
    return dist, objectDist, approachDist
end

local function lecternApproachPosition(ctx, obj, stationPos)
    if not (ctx and ctx.util and obj and obj.position and stationPos) then return nil end
    local approachPos = presenterApproach.approachPosition(obj, { stationType = "lectern" }, stationPos, ctx.util, {
        distance = LECTERN_APPROACH_EXTRA_DISTANCE,
    })
    if approachPos == stationPos then return nil end
    return approachPos
end

local function lectureSessionKey(data)
    local pos = data and data.object and data.object.position or nil
    local posKey = pos and (tostring(math.floor((pos.x or 0) + 0.5)) .. "," .. tostring(math.floor((pos.y or 0) + 0.5)) .. "," .. tostring(math.floor((pos.z or 0) + 0.5))) or "no_pos"
    return tostring(data and data.objectId or "<station>") .. "::" .. tostring(data and data.slotName or "station") .. "::" .. posKey
end

local function lectureSessionRecentKey(cellNameValue, sessionKey)
    return tostring(cellNameValue or "") .. "::" .. tostring(sessionKey or "")
end

local function lecturePresenterRecentKey(cellNameValue, npc)
    return tostring(cellNameValue or "") .. "::presenter::" .. tostring(npc and (npc.recordId or npc.id) or "<npc>")
end

local function purgeCompletedLectureCache(ctx)
    local now = gameTime(ctx)
    for key, expiresAt in pairs(recentlyCompletedLectureSessions) do
        if now >= (tonumber(expiresAt) or 0) then
            recentlyCompletedLectureSessions[key] = nil
        end
    end
end

local function lectureCompletionCooldownApplies(reason)
    local text = tostring(reason or "")
    return text == "station_duration_complete"
        or text == "station_duration_complete_after_wait"
        or text == "station_actor_moved_away"
        or text == "station_actor_released"
end

local function lectureSessionCanPersist(data, reason)
    if not (data and lower(data.stationType) == "lectern") then return false end
    if data.calibrationAction ~= true then return true end
    local text = tostring(reason or "")
    return data.releaseAt ~= nil
        or data.lectureStartRequested == true
        or data.lectureDebugShortcut == true
        or text == "developer_start_lecture"
        or text == "lecture_refreshed"
end

local function saveLectureSession(data, ctx, reason)
    if not lectureSessionCanPersist(data, reason) then return false end
    local cell = data.object and data.object.cell or data.npc and data.npc.cell
    local name = cellName(ctx, cell)
    if name == "" then return false end
    local byCell = lectureSessionsByCell[name] or {}
    lectureSessionsByCell[name] = byCell
    byCell[lectureSessionKey(data)] = {
        cellName = name,
        objectId = data.objectId,
        objectPosition = positionSnapshot(data.object and data.object.position),
        actorRecordId = data.npc and data.npc.recordId or nil,
        actorId = data.npc and data.npc.id or nil,
        actorPosition = positionSnapshot(data.npc and data.npc.position),
        originPosition = positionSnapshot(data.originPosition),
        originYaw = rotationYawSnapshot(data.originRotation),
        profileId = data.profileId,
        slotName = data.slotName,
        releaseAt = data.releaseAt,
        audience = snapshotAudience(data),
        savedAt = ctx and ctx.now and ctx.now() or 0,
    }
    if ctx and ctx.debugLog then
        ctx.debugLog("lecture session saved", tostring(name), "object", tostring(data.objectId), "actor", actorLabel(data.npc), "reason", tostring(reason))
    end
    return true
end

local function forgetLectureSession(data, ctx, reason)
    local cell = data and (data.object and data.object.cell or data.npc and data.npc.cell)
    local name = cellName(ctx, cell)
    local sessionKey = lectureSessionKey(data)
    local byCell = lectureSessionsByCell[name]
    if byCell then byCell[sessionKey] = nil end
    if lectureCompletionCooldownApplies(reason) then
        local now = gameTime(ctx)
        recentlyCompletedLectureSessions[lectureSessionRecentKey(name, sessionKey)] = now + LECTURE_STATION_COOLDOWN_SECONDS
        if data and data.slotKey then
            recentlyCompletedLectureSessions[lectureSessionRecentKey(name, data.slotKey)] = now + LECTURE_STATION_COOLDOWN_SECONDS
        end
        if data and data.npc then
            recentlyCompletedLectureSessions[lecturePresenterRecentKey(name, data.npc)] = now + LECTURE_PRESENTER_COOLDOWN_SECONDS
        end
    end
    if ctx and ctx.debugLog then
        ctx.debugLog("lecture session cleared", tostring(name), "object", tostring(data and data.objectId), "reason", tostring(reason))
    end
end

local function cooldownReasonForPresenter(ctx, cell, slotKey, npc)
    local name = cellName(ctx, cell)
    local now = gameTime(ctx)
    local stationKey = lectureSessionRecentKey(name, slotKey)
    local presenterKey = lecturePresenterRecentKey(name, npc)
    local stationUntil = tonumber(recentlyCompletedLectureSessions[stationKey])
    if stationUntil and stationUntil > now then return "station_lecture_cooldown", stationUntil - now, stationKey end
    local presenterUntil = tonumber(recentlyCompletedLectureSessions[presenterKey])
    if presenterUntil and presenterUntil > now then return "presenter_lecture_cooldown", presenterUntil - now, presenterKey end
    return nil, nil, nil
end

local function logCooldownSkip(ctx, slotKey, npc, reason, remaining, key)
    if not (ctx and ctx.debugLog and key) then return end
    local now = ctx.now and ctx.now() or 0
    local last = tonumber(lastLectureCooldownSkipByKey[key]) or -999
    if now - last < 45 then return end
    lastLectureCooldownSkipByKey[key] = now
    ctx.debugLog(
        "lecture lifecycle cooldown skip",
        "actor", actorLabel(npc),
        "slot", tostring(slotKey),
        "reason", tostring(reason),
        "remainingGameSeconds", tostring(remaining)
    )
end

local function presenterAnimationPayload(data, reason)
    if not (data and lower(data.stationType) == "lectern" and data.calibrationAction ~= true) then return nil end
    return lectureAnimation.presenterPayload(data, reason)
end

local function audienceCount(data)
    local count = 0
    for _, item in pairs(data and data.audience or {}) do
        if item and item.seatedAccepted == true then count = count + 1 end
    end
    return count
end

local function presenterAnimationPayloadIfAudience(data, reason)
    if audienceCount(data) < MIN_AUDIENCE_FOR_PRESENTER_ANIMATION then return nil end
    return presenterAnimationPayload(data, reason)
end

local function sendPresenterAnimationRefresh(data, reason, ctx)
    local payload = presenterAnimationPayloadIfAudience(data, reason)
    if not payload then
        lectureTrace.ctx(
            ctx,
            "presenter_animation_skipped",
            "reason", audienceCount(data) < MIN_AUDIENCE_FOR_PRESENTER_ANIMATION and "waiting_for_audience" or "missing_payload",
            "audience", tostring(audienceCount(data)),
            "required", tostring(MIN_AUDIENCE_FOR_PRESENTER_ANIMATION),
            "object", tostring(data and data.objectId),
            "slot", tostring(data and data.slotKey),
            "stage", tostring(reason or "lecture_animation_refresh")
        )
        return
    end
    if payload and data.npc and data.npc.sendEvent then
        data.npc:sendEvent("SitDownPleaseLectureAnimationRefresh", payload)
    end
end

local function findSessionActor(cell, session, ctx)
    if not (cell and cell.getAll and session) then return nil, "missing_cell" end
    local ok, npcs = pcall(function() return cell:getAll(ctx.types.NPC) end)
    if not (ok and npcs) then return nil, "npc_scan_failed" end
    local npc, reason = persistedActors.findActor(npcs, session, {
        isValid = function(actor) return validObject(ctx, actor) end,
        positionTolerance = 180,
    })
    if npc then return npc, nil end
    return nil, reason == "actor_not_loaded" and "presenter_not_loaded" or reason
end

local function findSessionObject(cell, session, ctx)
    if not (cell and cell.getAll and session) then return nil, "missing_cell" end
    local ok, objects = pcall(function() return cell:getAll() end)
    if not (ok and objects) then return nil, "object_scan_failed" end
    local best, bestDist = nil, nil
    for _, obj in ipairs(objects) do
        if validObject(ctx, obj) and lower(obj.recordId) == lower(session.objectId) then
            local profile = ctx.profiles.stationProfileForObject(obj, ctx.settings)
            if profile and tostring(profile.slotName or "station") == tostring(session.slotName or "station") then
                local dist = positionDistance(obj.position, session.objectPosition)
                if not bestDist or dist < bestDist then
                    best, bestDist = obj, dist
                end
            end
        end
    end
    if best then return best, nil end
    return nil, "station_object_not_loaded"
end

local function findAudienceActor(cell, item, ctx)
    if not (cell and cell.getAll and item and ctx and ctx.types and ctx.types.NPC) then return nil end
    local ok, npcs = pcall(function() return cell:getAll(ctx.types.NPC) end)
    if not (ok and npcs) then return nil end
    local npc = persistedActors.findActor(npcs, item, {
        isValid = function(actor) return validObject(ctx, actor) end,
        positionTolerance = 180,
    })
    return npc
end

local function restoreAudienceMembers(data, session, cell, ctx)
    if not (data and session and session.audience and cell) then return 0 end
    local restored = 0
    data.audience = data.audience or {}
    for _, item in ipairs(session.audience) do
        local npc = findAudienceActor(cell, item, ctx)
        if npc and npc.id then
            local yieldReason = restoreSafety.actorYieldReason(ctx, npc)
            if yieldReason then
                lectureTrace.ctx(
                    ctx,
                    "lecture_audience_restore_yield_external_control",
                    "actor", actorLabel(npc),
                    "object", tostring(data.objectId),
                    "slot", tostring(item.stationSlotKey),
                    "reason", tostring(yieldReason)
                )
            else
                data.audience[npc.id] = {
                    npc = npc,
                    stationSlotKey = item.stationSlotKey,
                    sector = item.sector or lectureAnimation.audienceSector(data, npc),
                    seatedAccepted = true,
                    originPosition = positionFromSnapshot(ctx, item.originPosition),
                    originRotation = rotationFromSnapshot(ctx, item.originYaw, item.originRotation),
                    returnMode = item.returnMode,
                    wasAlreadySitting = item.wasAlreadySitting == true,
                    originalAnimation = item.originalAnimation,
                }
                restored = restored + 1
            end
        end
    end
    if restored > 0 then
        lectureAnimation.rebuildAudienceSummary(data)
        sendPresenterAnimationRefresh(data, "audience_restored")
        lectureTrace.ctx(
            ctx,
            "lecture_audience_restored",
            "actor", actorLabel(data.npc),
            "object", tostring(data.objectId),
            "slot", tostring(data.slotKey),
            "count", tostring(restored)
        )
    end
    return restored
end

local function releaseSavedAudienceMembers(session, cell, ctx, reason, slotKey)
    if not (session and session.audience and cell and ctx and ctx.releaseAudienceNpc) then return 0 end
    local released = 0
    for _, item in ipairs(session.audience) do
        local npc = findAudienceActor(cell, item, ctx)
        if validObject(ctx, npc) then
            local yieldReason = restoreSafety.actorYieldReason(ctx, npc)
            if yieldReason then
                lectureTrace.ctx(
                    ctx,
                    "lecture_saved_audience_release_yield_external_control",
                    "actor", actorLabel(npc),
                    "object", tostring(session.objectId),
                    "slot", tostring(item.stationSlotKey or slotKey),
                    "reason", tostring(yieldReason)
                )
            else
                released = released + 1
                ctx.releaseAudienceNpc(npc, reason or "lecture_expired_before_restore_after_wait", 0.05 + (released - 1) * 0.05, {
                    stationSlotKey = item.stationSlotKey or slotKey,
                    originPosition = positionFromSnapshot(ctx, item.originPosition),
                    originRotation = rotationFromSnapshot(ctx, item.originYaw, item.originRotation),
                    returnMode = item.returnMode,
                    wasAlreadySitting = item.wasAlreadySitting == true,
                    originalAnimation = item.originalAnimation,
                })
            end
        end
    end
    if released > 0 then
        lectureTrace.ctx(
            ctx,
            "lecture_saved_audience_release",
            "object", tostring(session.objectId),
            "slot", tostring(slotKey or session.slotName),
            "count", tostring(released),
            "reason", tostring(reason or "lecture_expired_before_restore_after_wait")
        )
    end
    return released
end

local function releaseSlot(slotKey, reason, ctx, returnToOrigin)
    local data = assignmentsBySlot[slotKey]
    if not data then return false end
    lectureTrace.ctx(
        ctx,
        "release_end_fired",
        "actor", actorLabel(data.npc),
        "object", tostring(data.objectId),
        "slot", tostring(slotKey),
        "reason", tostring(reason or "station_released"),
        "releaseAt", tostring(data.releaseAt),
        "gameTime", tostring(gameTime(ctx))
    )
    stationClaims:release(slotKey, data.npc, reason or "station_released")
    if tostring(reason or "") == "sleep_window" and data.npc and data.npc.id then
        recentlyReleasedForSleepByNpc[data.npc.id] = (ctx.now and ctx.now() or 0) + 45
        if ctx.infoLog then
            ctx.infoLog("station released for sleep window", actorLabel(data.npc), "slot", tostring(slotKey), "object", tostring(data.objectId))
        end
    end
    if validObject(ctx, data.npc) then
        data.npc:sendEvent("SitDownPleaseStationReleased", {
            reason = reason or "station_released",
            stationType = data.stationType,
            slotKey = slotKey,
        })
        if returnToOrigin == true and data.originPosition then
            if ctx.returnToOrigin then
                ctx.returnToOrigin(data.npc, data.originPosition, data.originRotation, reason or "station_released")
            elseif ctx.tryStartTravel then
                ctx.tryStartTravel(data.npc, data.originPosition, reason or "station_released")
            end
        end
    end
    if ctx.debugLog then
        ctx.debugLog("station released", actorLabel(data.npc), "slot", tostring(slotKey), "reason", tostring(reason))
    end
    forgetLectureSession(data, ctx, reason or "station_released")
    return true
end

local function clearPending(slotKey, npcId)
    local pending = slotKey and pendingBySlot[slotKey] or nil
    if slotKey then pendingStationClaims:release(slotKey, pending and pending.npc or npcId, "pending_station_cleared") end
    if npcId and pendingByNpc[npcId] then pendingStationClaims:releaseForActor(npcId, "pending_station_cleared") end
end

local function markPendingLectureStart(slotKey, options, ctx)
    local pending = slotKey and pendingBySlot[slotKey] or nil
    if not pending then return false, "missing_pending_presenter" end
    pending.lectureStartRequested = true
    pending.lectureDebugShortcut = options and options.debugShortcut == true
    pending.lectureTeleportAudience = options and options.teleportAudience == true
    pending.lectureSource = options and options.source or "developer_start_lecture"
    pending.allowRouteDoorOverride = pending.allowRouteDoorOverride == true
        or pending.testingOverride == true
        or pending.calibrationAction == true
        or pending.lectureDebugShortcut == true
    if ctx then
        lectureTrace.ctx(
            ctx,
            "pending_presenter_lecture_deferred",
            "actor", actorLabel(pending.npc),
            "object", tostring(pending.object and pending.object.recordId),
            "slot", tostring(slotKey),
            "source", tostring(pending.lectureSource),
            "teleport", tostring(pending.lectureTeleportAudience == true)
        )
    end
    return true, pending
end

local function sharedSmoothMoveActive(ctx, npc)
    if not (ctx and ctx.smoothMoveActive and npc and npc.id) then return false end
    return ctx.smoothMoveActive(npc.id) == true
end

local function eligiblePresenter(npc, profile, ctx)
    if not validObject(ctx, npc) or not npc.id then return false, "invalid_npc" end
    if assignmentByNpc[npc.id] then return false, "already_stationed" end
    if ctx.assignedActors and ctx.assignedActors[npc.id] then return false, "active_sdp_assignment" end
    if ctx.actorDeadReason then
        local dead, deadReason = ctx.actorDeadReason(npc)
        if dead then return false, deadReason or "dead_actor" end
    end
    local rec = ctx.servicePolicy and ctx.servicePolicy.record and ctx.servicePolicy.record(npc, ctx.types) or nil
    local isFactionLeader = ctx.actorRoles and ctx.actorRoles.isFactionLeader and ctx.actorRoles.isFactionLeader(npc, ctx.types, ctx.core) or false
    local isTrainer = rec and rec.servicesOffered and rec.servicesOffered.Training == true
    local isLectern = lower(profile and profile.stationType) == "lectern"
    if ctx.isNpcEligibleForInteraction then
        local ok, reason = ctx.isNpcEligibleForInteraction(npc, "station")
        local allowedServicePost = isTrainer and reason == "training_service_npc"
            or isFactionLeader and (
                reason == "faction_leader"
                or reason == "barter_service_npc"
                or reason == "training_service_npc"
            )
            or isLectern and (
                reason == "barter_service_npc"
                or reason == "training_service_npc"
                or reason == "faction_leader"
            )
        if not ok and not allowedServicePost then
            return false, reason or "not_station_eligible"
        end
    end

    if ctx.servicePolicy and ctx.servicePolicy.hasTravelService and ctx.servicePolicy.hasTravelService(rec) then
        return false, "travel_service_npc"
    end

    if hasFlag(profile, "trainerOrFactionRankOnly") and not isLectern and not (isTrainer or isFactionLeader) then
        return false, "not_trainer_or_faction_leader"
    end
    if isLectern then
        local allowed, reason = lecternPolicy.presenterAllowed(npc, rec, profile, ctx)
        if not allowed then return false, reason or "lectern_policy_rejected" end
    end
    return true, nil
end

local function chanceAllows(npc, profile, slotKey, ctx)
    local settings = ctx.settings or {}
    local chance = tonumber(settings.stationLecternPresenterChance)
    if chance == nil then chance = 0.35 end
    if chance == 0.35 then chance = 0.50 end
    if chance <= 0 then return false end
    if chance >= 1 then return true end
    local stable = ctx.profiles and ctx.profiles.stableUnitInterval
    local unit = stable and stable(tostring(npc and (npc.recordId or npc.id)) .. "::" .. tostring(slotKey) .. "::presenter") or 0
    return unit <= chance
end

local function stableUnit(ctx, seed)
    local stable = ctx and ctx.profiles and ctx.profiles.stableUnitInterval
    return stable and stable(seed) or 0.5
end

local function nextLectureReleaseSequence(slotKey)
    local key = tostring(slotKey or "lecture")
    local value = (tonumber(lectureReleaseSequenceBySlot[key]) or 0) + 1
    lectureReleaseSequenceBySlot[key] = value
    return value
end

local function rounded(value, places)
    local scale = 10 ^ (tonumber(places) or 1)
    return math.floor((tonumber(value) or 0) * scale + 0.5) / scale
end

local function releaseHour(ctx, durationSeconds)
    local hour = ctx and ctx.profiles and ctx.profiles.getGameHour and ctx.profiles.getGameHour() or nil
    if hour == nil then return nil end
    return (tonumber(hour) + ((tonumber(durationSeconds) or 0) / 3600)) % 24
end

local function traceReleaseScheduled(ctx, data, reason)
    if not data then return end
    local now = gameTime(ctx)
    local releaseAt = tonumber(data.releaseAt)
    local duration = tonumber(data.releaseDurationSeconds)
    if not duration and releaseAt then duration = releaseAt - now end
    lectureTrace.ctx(
        ctx,
        "release_end_scheduled",
        "actor", actorLabel(data.npc),
        "object", tostring(data.objectId or (data.object and data.object.recordId)),
        "slot", tostring(data.slotKey),
        "releaseAt", tostring(data.releaseAt),
        "reason", tostring(reason or (data.releaseAt and "scheduled" or "calibration_or_debug_hold")),
        "gameTime", tostring(now),
        "durationGameMinutes", tostring(duration and rounded(duration / 60, 1) or nil),
        "durationGameHours", tostring(duration and rounded(duration / 3600, 2) or nil),
        "releaseGameHour", tostring(duration and releaseHour(ctx, duration) and rounded(releaseHour(ctx, duration), 2) or nil),
        "minHours", tostring(data.releaseMinHours),
        "maxHours", tostring(data.releaseMaxHours),
        "releaseSequence", tostring(data.releaseSequence)
    )
end

local function lectureReleaseAt(npc, slotKey, ctx, options)
    options = options or {}
    local settings = ctx.settings or {}
    local minHours = tonumber(settings.stationLecternMinHours) or 0.5
    local maxHours = tonumber(settings.stationLecternMaxHours) or 3
    if maxHours < minHours then maxHours = minHours end
    local minDelay = minHours * 3600
    local maxDelay = maxHours * 3600
    local sequence = options.releaseSequence
    if sequence == nil and options.initialMidLecture ~= true and options.stableRelease ~= true then
        sequence = nextLectureReleaseSequence(slotKey)
    end
    options.releaseSequence = sequence
    options.releaseMinHours = minHours
    options.releaseMaxHours = maxHours
    local seed = tostring(npc and (npc.recordId or npc.id)) .. "::" .. tostring(slotKey) .. "::lecture_release"
    if sequence ~= nil then seed = seed .. "::seq" .. tostring(sequence) end
    local durationUnit = stableUnit(ctx, seed .. "::duration")
    local duration = minDelay + durationUnit * math.max(0, maxDelay - minDelay)
    if options.initialMidLecture == true then
        local progressUnit = stableUnit(ctx, seed .. "::initial_progress")
        local remaining = duration * (1 - progressUnit * 0.65)
        duration = math.max(minDelay * 0.5, remaining)
    end
    options.releaseDurationSeconds = duration
    return gameTime(ctx) + duration
end

local function initialActiveLectureAllowed(ctx, slotKey, cell)
    if not (ctx and ctx.initialPlacement == true) then return false end
    local recentKey = nil
    if cell then
        local name = cellName(ctx, cell)
        recentKey = lectureSessionRecentKey(name, slotKey)
    end
    if recentKey and recentlyCompletedLectureSessions[recentKey] then return false end
    return stableUnit(ctx, tostring(slotKey) .. "::initial_active_lecture") <= INITIAL_ACTIVE_LECTURE_CHANCE
end

local function findPresenterForStation(cell, obj, profile, stationPos, slotKey, ctx)
    local bestNpc, bestDist = nil, nil
    local radius = tonumber(profile and profile.radius) or 260
    local isLectern = lower(profile and profile.stationType) == "lectern"
    if isLectern and cellIsInterior(cell) then
        radius = math.huge
    end
    for _, npc in ipairs(cell:getAll(ctx.types.NPC)) do
        local ok = eligiblePresenter(npc, profile, ctx)
        if ok and isLectern then
            local cooldownReason, remaining, cooldownKey = cooldownReasonForPresenter(ctx, cell, slotKey, npc)
            if cooldownReason then
                logCooldownSkip(ctx, slotKey, npc, cooldownReason, remaining, cooldownKey)
                ok = false
            end
        end
        local dist = npc.position and stationPos and (npc.position - stationPos):length() or nil
        local objectDist = npc.position and obj and obj.position and (npc.position - obj.position):length() or nil
        local alreadyAtLectern = isLectern and ((dist and dist <= 160) or (objectDist and objectDist <= 96))
        if ok and (alreadyAtLectern == true or chanceAllows(npc, profile, slotKey, ctx)) then
            if dist and dist <= radius and (not bestDist or dist < bestDist) then
                bestNpc, bestDist = npc, dist
            end
        end
    end
    return bestNpc, bestDist
end

local function claimStationWithNpc(cell, obj, profile, slotKey, npc, dist, ctx, options)
    options = options or {}
    local stationPos = ctx.profiles.stationWorldPosition(obj, profile, ctx.util)
    local facingDirection = ctx.profiles.stationFacingDirection(obj, profile, ctx.util)
    if not (stationPos and facingDirection) then
        lectureTrace.ctx(ctx, "station_target_resolved", "ok", "false", "object", tostring(obj and obj.recordId), "slot", tostring(slotKey), "reason", "missing_station_geometry")
        return false, "missing_station_geometry"
    end
    lectureTrace.ctx(
        ctx,
        "station_target_resolved",
        "ok", "true",
        "object", tostring(obj and obj.recordId),
        "slot", tostring(slotKey),
        "stationType", tostring(profile and profile.stationType),
        "position", tostring(stationPos)
    )
    if not validObject(ctx, npc) then
        if options.testingOverride == true and npc and npc.position then
            if ctx.debugLog then
                ctx.debugLog(
                    "station debug actor validity bypass",
                    npc.recordId or npc.id,
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey)
                )
            end
        else
            return false, "invalid_station_actor"
        end
    end
    if options.replaceExisting == true then
        local hadPendingSlot = pendingBySlot[slotKey] ~= nil
        local hadPendingActor = npc.id and pendingByNpc[npc.id] ~= nil
        if hadPendingSlot or hadPendingActor then
            clearPending(slotKey, npc.id)
            lectureTrace.ctx(
                ctx,
                "pending_presenter_force_claim",
                "actor", actorLabel(npc),
                "object", tostring(obj and obj.recordId),
                "slot", tostring(slotKey),
                "pendingSlot", tostring(hadPendingSlot == true),
                "pendingActor", tostring(hadPendingActor == true)
            )
        end
    end
    if assignmentsBySlot[slotKey] and options.replaceExisting ~= true then return false, "station_already_claimed" end
    if pendingBySlot[slotKey] and options.replaceExisting ~= true then return false, "station_claim_pending" end
    if assignmentByNpc[npc.id] then return false, "already_stationed" end
    if pendingByNpc[npc.id] then return false, "station_actor_pending" end
    if ctx.followerBlockReason then
        local followerReason = ctx.followerBlockReason(npc)
        if followerReason then return false, followerReason end
    end
    local restoreSession = options.restoreLectureSession == true
    local softEligibilityBypassed = options.testingOverride == true or restoreSession == true
    if softEligibilityBypassed ~= true then
        local allowed, reason = eligiblePresenter(npc, profile, ctx)
        if not allowed then return false, reason or "not_station_eligible" end
        if lower(profile and profile.stationType) == "lectern"
            and options.calibrationAction ~= true
            and restoreSession ~= true then
            local audienceOk, audienceReason, scanned, relevant, compatible = stationHasPlausibleAudience(cell, obj, ctx)
            if not audienceOk then
                local logKey = tostring(slotKey)
                local nowForLog = ctx.now and ctx.now() or 0
                if ctx.debugLog and nowForLog - (tonumber(lastNoAudienceLogBySlot[logKey]) or -999) >= 45 then
                    lastNoAudienceLogBySlot[logKey] = nowForLog
                    ctx.debugLog(
                        "lecture lifecycle skipped no audience",
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "reason", tostring(audienceReason),
                        "scanned", tostring(scanned or 0),
                        "sittingCandidates", tostring(relevant or 0),
                        "compatible", tostring(compatible or 0)
                    )
                end
                return false, audienceReason or "no_plausible_audience_seat"
            end
            if options.ignoreCooldown ~= true then
                local cooldownReason, remaining, cooldownKey = cooldownReasonForPresenter(ctx, cell, slotKey, npc)
                if cooldownReason then
                    logCooldownSkip(ctx, slotKey, npc, cooldownReason, remaining, cooldownKey)
                    return false, cooldownReason
                end
            end
        end
        if options.ignoreChance ~= true and not chanceAllows(npc, profile, slotKey, ctx) then
            return false, "station_chance_rejected"
        end
    else
        if restoreSession == true then
            local allowed, reason = eligiblePresenter(npc, profile, ctx)
            if not allowed then
                lectureTrace.ctx(
                    ctx,
                    "lecture_restore_soft_eligibility_bypass",
                    "actor", actorLabel(npc),
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey),
                    "reason", tostring(reason or "not_station_eligible")
                )
            end
        end
        if ctx.actorDeadReason then
            local dead, deadReason = ctx.actorDeadReason(npc)
            if dead then return false, deadReason or "dead_actor" end
        end
    end

    local originPosition, originRotation, originSource = resolvePresenterOrigin(npc, ctx, options)
    local yaw = yawFromDirection(facingDirection, npc.rotation and npc.rotation:getYaw() or 0)
    local distanceToStation = npc.position and stationPos and (npc.position - stationPos):length() or 0
    local distanceToObject = npc.position and obj and obj.position and (npc.position - obj.position):length() or nil
    local distanceToOrigin = npc.position and originPosition and (npc.position - originPosition):length() or nil
    local now = gameTime(ctx)
    local pendingNow = runtimeNow(ctx)
    local forcePathing = options.forcePathing == true
    local forcePathingImmediateRadius = tonumber(options.forcePathingImmediateRadius) or 6
    local lecternStation = lower(profile and profile.stationType) == "lectern"
    local alreadyAtLectern = forcePathing == true
        and lecternStation == true
        and distanceToStation
        and distanceToStation <= LECTERN_ALREADY_AT_MARKER_RADIUS
    local immediate = (forcePathing == true and distanceToStation <= forcePathingImmediateRadius)
        or alreadyAtLectern == true
        or (forcePathing ~= true and (options.immediatePlacement == true
        or options.calibrationAction == true
        or distanceToStation <= 96))
    lectureTrace.ctx(
        ctx,
        "presenter_resolved",
        "actor", actorLabel(npc),
        "object", tostring(obj and obj.recordId),
        "slot", tostring(slotKey),
        "distance", tostring(distanceToStation),
        "objectDistance", tostring(distanceToObject),
        "originSource", tostring(originSource),
        "originDistance", tostring(distanceToOrigin),
        "immediate", tostring(immediate == true),
        "alreadyAtLectern", tostring(alreadyAtLectern == true),
        "forcePathing", tostring(forcePathing == true),
        "testingOverride", tostring(options.testingOverride == true),
        "calibrationAction", tostring(options.calibrationAction == true)
    )
    if immediate ~= true and ctx.tryStartTravel then
        local approachPos = lecternStation and lecternApproachPosition(ctx, obj, stationPos) or nil
        local travelTarget = approachPos or stationPos
        local pendingData = {
            npc = npc,
            object = obj,
            profile = profile,
            slotKey = slotKey,
            stationPos = stationPos,
            approachPos = approachPos,
            facingDirection = facingDirection,
            finalRotation = yaw,
            originPosition = originPosition,
            originRotation = originRotation,
            originSource = originSource,
            startedAt = pendingNow,
            expiresAt = pendingNow + (tonumber(options.pendingSeconds) or 75),
            releaseAt = options.releaseAt,
            sourceDistance = dist,
            initialPlacement = options.initialPlacement == true,
            testingOverride = options.testingOverride == true,
            calibrationAction = options.calibrationAction == true,
            releaseSafetyGateEnabled = options.releaseSafetyGateEnabled,
            releaseSafetyGateStatus = options.releaseSafetyGateStatus,
            releaseSafetyGateReason = options.releaseSafetyGateReason,
            releaseSafetyGateCell = options.releaseSafetyGateCell,
            releaseSafetyGateRegion = options.releaseSafetyGateRegion,
            releaseSafetyGateFurnitureType = options.releaseSafetyGateFurnitureType,
            releaseSafetyGateLabel = options.releaseSafetyGateLabel,
            lectureStartRequested = options.lectureStartRequested == true,
            lectureDebugShortcut = options.lectureDebugShortcut == true,
            lectureTeleportAudience = options.lectureTeleportAudience == true,
            lectureSource = options.lectureSource,
            allowRouteDoorOverride = options.testingOverride == true
                or options.calibrationAction == true
                or options.lectureDebugShortcut == true,
            smoothEntry = options.smoothEntry ~= false
                and options.initialPlacement ~= true
                and options.calibrationAction ~= true
                and options.calibrationFill ~= true,
            lastTravelRequestAt = pendingNow,
        }
        local claimOk, claimReason = pendingStationClaims:claim(slotKey, npc, pendingData, {
            reason = "station_pathing",
            claimedAt = pendingNow,
        })
        if not claimOk then return false, claimReason or "station_claim_pending" end
        local travelOk = ctx.tryStartTravel(npc, travelTarget, "station_assignment", {
            stationType = profile.stationType,
            slotKey = slotKey,
            objectId = obj.recordId,
            cancelOther = true,
            destinationTolerance = lecternStation and LECTERN_TRAVEL_TOLERANCE or nil,
        })
        if travelOk == false then
            clearPending(slotKey, npc.id)
            return false, "pathing_failed"
        end
        npc:sendEvent("SitDownPleaseStationPathingStarted", {
            stationType = profile.stationType or "station",
            slotName = profile.slotName or "station",
            slotKey = slotKey,
            object = obj,
            objectId = obj.recordId,
            finalPosition = stationPos,
            approachPosition = approachPos,
            finalRotation = yaw,
            facingDirection = facingDirection,
            allowRouteDoorOverride = pendingData.allowRouteDoorOverride == true,
        })
        if ctx.infoLog then
            ctx.infoLog("station pathing started", actorLabel(npc), "type", tostring(profile.stationType), "object", tostring(obj.recordId), "slot", tostring(profile.slotName), "distance", tostring(distanceToStation), "approach", tostring(approachPos))
        end
        lectureTrace.ctx(
            ctx,
            "session_start_refresh_called",
            "path", "station_pending_path",
            "actor", actorLabel(npc),
            "object", tostring(obj.recordId),
            "slot", tostring(slotKey),
            "testingOverride", tostring(options.testingOverride == true)
        )
        return true, "pathing"
    end
    clearPending(slotKey, npc.id)
    local targetCell = npc.cell or cell or obj.cell
    if not targetCell then return false, "missing_station_cell" end
    local lecternObjectArrival = lecternStation == true
        and distanceToStation <= LECTERN_SMOOTH_ENTRY_MAX_DISTANCE
        and distanceToObject ~= nil
        and distanceToObject <= LECTERN_SMOOTH_ENTRY_OBJECT_RADIUS
    local nearLecternHold = lecternStation == true
        and distanceToStation <= LECTERN_NEAR_MARKER_HOLD_RADIUS
    local smoothEntry = options.smoothEntry ~= false
        and options.initialPlacement ~= true
        and options.calibrationAction ~= true
        and options.calibrationFill ~= true
        and distanceToStation > 6
        and (distanceToStation <= 180 or lecternObjectArrival == true)
    if smoothEntry ~= true and nearLecternHold ~= true then
        local ok, err = ctx.tryTeleport(npc, targetCell, stationPos, {
            rotation = ctx.rotationFromYaw(yaw, npc.rotation),
        })
        if not ok then return false, "teleport_failed:" .. tostring(err) end
    elseif nearLecternHold == true then
        lectureTrace.ctx(
            ctx,
            "presenter_entry_smooth_skipped",
            "actor", actorLabel(npc),
            "object", tostring(obj and obj.recordId),
            "slot", tostring(slotKey),
            "distance", tostring(distanceToStation),
            "objectDistance", tostring(distanceToObject),
            "reason", "near_lectern_marker_hold"
        )
    else
        lectureTrace.ctx(
            ctx,
            "presenter_entry_smooth_queued",
            "actor", actorLabel(npc),
            "object", tostring(obj and obj.recordId),
            "slot", tostring(slotKey),
            "distance", tostring(distanceToStation),
            "yaw", tostring(yaw)
        )
    end

    local assignmentData = {
        npc = npc,
        object = obj,
        objectId = obj.recordId,
        profile = profile,
        profileId = profile.profileId,
        stationType = profile.stationType or "station",
        slotName = profile.slotName or "station",
        slotKey = slotKey,
        position = stationPos,
        facingDirection = facingDirection,
        finalRotation = yaw,
        originPosition = originPosition,
        originRotation = originRotation,
        originSource = originSource,
        claimedAt = ctx.now and ctx.now() or 0,
        releaseAt = options.calibrationAction == true and nil or (options.releaseAt or lectureReleaseAt(npc, slotKey, ctx, options)),
        releaseDurationSeconds = options.releaseDurationSeconds,
        releaseMinHours = options.releaseMinHours,
        releaseMaxHours = options.releaseMaxHours,
        releaseSequence = options.releaseSequence,
        sourceDistance = dist,
        testingOverride = options.testingOverride == true,
        calibrationAction = options.calibrationAction == true,
        releaseSafetyGateEnabled = options.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = options.releaseSafetyGateStatus,
        releaseSafetyGateReason = options.releaseSafetyGateReason,
        releaseSafetyGateCell = options.releaseSafetyGateCell,
        releaseSafetyGateRegion = options.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = options.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = options.releaseSafetyGateLabel,
        calibrationFill = options.calibrationFill == true,
        calibrationFillLabel = options.calibrationFillLabel,
        calibrationFillRole = options.calibrationFillRole,
        calibrationFillSource = options.calibrationFillSource,
        calibrationFillIndex = options.calibrationFillIndex,
        calibrationFillSessionId = options.calibrationFillSessionId,
        calibrationRuntimeObjectId = options.calibrationRuntimeObjectId,
        actorDisplayLabel = options.calibrationFillLabel,
        initialPlacement = options.initialPlacement == true,
        presenterEntrySmooth = smoothEntry == true,
        lectureStartRequested = options.lectureStartRequested == true,
        lectureDebugShortcut = options.lectureDebugShortcut == true,
        lectureTeleportAudience = options.lectureTeleportAudience == true,
        lectureSource = options.lectureSource,
        audience = {},
    }
    assignmentData.lectureSessionId = lectureAnimation.sessionId(assignmentData)
    lectureAnimation.rebuildAudienceSummary(assignmentData)
    lectureTrace.ctx(
        ctx,
        "session_start_refresh_called",
        "path", "station_claim",
        "actor", actorLabel(npc),
        "object", tostring(obj and obj.recordId),
        "slot", tostring(slotKey),
        "releaseAt", tostring(assignmentData.releaseAt),
        "calibrationAction", tostring(options.calibrationAction == true)
    )
    local claimOk, claimReason = stationClaims:claim(slotKey, npc, assignmentData, {
        replaceExisting = options.replaceExisting == true,
        reason = options.calibrationAction == true and "station_calibration" or "station_claimed",
        claimedAt = assignmentData.claimedAt,
    })
    if not claimOk then return false, claimReason or "station_claim_failed" end
    npc:sendEvent("SitDownPleaseStationAssigned", {
        stationType = profile.stationType or "station",
        slotName = profile.slotName or "station",
        slotKey = slotKey,
        object = obj,
        objectId = obj.recordId,
        finalPosition = stationPos,
        finalRotation = yaw,
        facingDirection = facingDirection,
        calibrationFillLabel = options.calibrationFillLabel,
        calibrationFillRole = options.calibrationFillRole,
        calibrationFillSource = options.calibrationFillSource,
        calibrationFillIndex = options.calibrationFillIndex,
        calibrationFillSessionId = options.calibrationFillSessionId,
        calibrationRuntimeObjectId = options.calibrationRuntimeObjectId,
        actorDisplayLabel = options.calibrationFillLabel,
        releaseSafetyGateEnabled = options.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = options.releaseSafetyGateStatus,
        releaseSafetyGateReason = options.releaseSafetyGateReason,
        releaseSafetyGateCell = options.releaseSafetyGateCell,
        releaseSafetyGateRegion = options.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = options.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = options.releaseSafetyGateLabel,
        lectureSessionId = assignmentData.lectureSessionId,
        lectureAnimation = presenterAnimationPayloadIfAudience(assignmentData, "station_assigned"),
        presenterEntrySmooth = smoothEntry == true,
    })
    lectureTrace.ctx(
        ctx,
        "presenter_facing_hold_applied",
        "actor", actorLabel(npc),
        "object", tostring(obj and obj.recordId),
        "slot", tostring(slotKey),
        "yaw", tostring(yaw),
        "final", tostring(stationPos)
    )
    traceReleaseScheduled(ctx, assignmentData, assignmentData.releaseAt and "scheduled" or "calibration_or_debug_hold")
    if not assignmentData.releaseAt then
        lectureTrace.ctx(
            ctx,
            "release_end_skipped",
            "actor", actorLabel(npc),
            "object", tostring(obj and obj.recordId),
            "slot", tostring(slotKey),
            "reason", options.calibrationAction == true and "calibration_action_hold" or "missing_release_time"
        )
    end
    if ctx.infoLog then
        ctx.infoLog(
            "station claimed",
            actorLabel(npc),
            "type", tostring(profile.stationType),
            "object", tostring(obj.recordId),
            "model", tostring(ctx.profiles.objectModelPath and ctx.profiles.objectModelPath(obj) or nil),
            "profile", tostring(profile.profileId),
            "slot", tostring(profile.slotName),
            "fillLabel", tostring(options.calibrationFillLabel),
            "fillSource", tostring(options.calibrationFillSource),
            "final", tostring(stationPos),
            "rotation", tostring(yaw),
            "initialPlacement", tostring(options.initialPlacement == true)
        )
    end
    if ctx.initialPlacement == true and npc.id then
        pendingInitialStationActorIds[npc.id] = true
    end
    saveLectureSession(assignmentData, ctx, "claimed")
    return true, "claimed"
end

local function processPendingClaims(ctx)
    local newlyClaimed = {}
    local now = runtimeNow(ctx)
    local pendingKeys = {}
    for slotKey in pairs(pendingBySlot) do pendingKeys[#pendingKeys + 1] = slotKey end
    for _, slotKey in ipairs(pendingKeys) do
        local pending = pendingBySlot[slotKey]
        local npc = pending and pending.npc or nil
        local obj = pending and pending.object or nil
        local npcId = npc and npc.id or nil
        if not validObject(ctx, npc) then
            clearPending(slotKey)
            if ctx.debugLog then ctx.debugLog("station pending cleared", "reason", "invalid_actor", "slot", tostring(slotKey)) end
        elseif not validObject(ctx, obj) then
            clearPending(slotKey, npcId)
            if ctx.debugLog then ctx.debugLog("station pending cleared", actorLabel(npc), "reason", "invalid_object", "slot", tostring(slotKey)) end
        elseif pending.expiresAt and now > pending.expiresAt then
            clearPending(slotKey, npcId)
            if ctx.debugLog then ctx.debugLog("station pending cleared", actorLabel(npc), "reason", "timeout", "slot", tostring(slotKey)) end
        else
            local distanceToStation, distanceToObject, distanceToApproach = pendingDistance(npc, pending)
            local elapsed = now - (tonumber(pending.startedAt) or now)
            local allowForcedClaim = pending.initialPlacement == true
                or pending.calibrationAction == true
                or pending.testingOverride == true
            local isLectern = lower(pending.profile and pending.profile.stationType) == "lectern"
            local forceClaimObjectRadius = isLectern and LECTERN_SMOOTH_ENTRY_OBJECT_RADIUS or STATION_OBJECT_APPROACH_RADIUS
            local forceClaimSeconds = allowForcedClaim and STATION_DEBUG_FORCE_CLAIM_SECONDS or STATION_FORCE_CLAIM_SECONDS
            local stationArrivalRadius = isLectern and 18 or STATION_ARRIVAL_RADIUS
            local acceptArrival
            local lecternArrivalReason
            local lecternSideProgress
            if isLectern then
                -- Lecterns must not accept the actor merely because they are beside
                -- or in front of the furniture.  Accept at the final marker, near
                -- the shallow approach point, or after pathing has demonstrably
                -- stalled close enough for the station entry smoother to settle.
                acceptArrival, lecternArrivalReason, lecternSideProgress = presenterApproach.arrivalState(
                    obj,
                    pending.stationPos,
                    npc and npc.position,
                    {
                        station = distanceToStation,
                        object = distanceToObject,
                        approach = distanceToApproach,
                    },
                    elapsed,
                    {
                        markerRadius = stationArrivalRadius,
                        approachRadius = LECTERN_APPROACH_ACCEPT_RADIUS,
                        settleRadius = LECTERN_SMOOTH_ENTRY_STATION_RADIUS,
                        objectRadius = LECTERN_CLOSE_OBJECT_ACCEPT_RADIUS,
                        stableSeconds = LECTERN_STABLE_CLOSE_SECONDS,
                    }
                )
            else
                acceptArrival = distanceToStation <= stationArrivalRadius
                    or (
                        allowForcedClaim
                        and elapsed >= forceClaimSeconds
                        and distanceToObject ~= nil
                        and distanceToObject <= forceClaimObjectRadius
                    )
            end
            if acceptArrival then
                lectureTrace.ctx(
                    ctx,
                    "pending_presenter_arrival_accepted",
                    "actor", actorLabel(npc),
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey),
                    "distance", tostring(distanceToStation),
                    "objectDistance", tostring(distanceToObject),
                    "approachDistance", tostring(distanceToApproach),
                    "elapsed", tostring(elapsed),
                    "arrivalReason", tostring(lecternArrivalReason),
                    "sideProgress", tostring(lecternSideProgress),
                    "testingOverride", tostring(pending.testingOverride == true)
                )
                clearPending(slotKey, npcId)
                local cell = (obj and obj.cell) or (npc and npc.cell)
                local ok, reason = claimStationWithNpc(cell, obj, pending.profile, slotKey, npc, pending.sourceDistance, ctx, {
                    ignoreChance = true,
                    immediatePlacement = true,
                    smoothEntry = pending.smoothEntry == true,
                    initialPlacement = pending.initialPlacement == true,
                    releaseAt = pending.releaseAt,
                    originPosition = pending.originPosition,
                    originRotation = pending.originRotation,
                    originSource = pending.originSource or "pending_path_origin",
                    testingOverride = pending.testingOverride == true,
                    calibrationAction = pending.calibrationAction == true,
                    releaseSafetyGateEnabled = pending.releaseSafetyGateEnabled,
                    releaseSafetyGateStatus = pending.releaseSafetyGateStatus,
                    releaseSafetyGateReason = pending.releaseSafetyGateReason,
                    releaseSafetyGateCell = pending.releaseSafetyGateCell,
                    releaseSafetyGateRegion = pending.releaseSafetyGateRegion,
                    releaseSafetyGateFurnitureType = pending.releaseSafetyGateFurnitureType,
                    releaseSafetyGateLabel = pending.releaseSafetyGateLabel,
                    lectureStartRequested = pending.lectureStartRequested == true,
                    lectureDebugShortcut = pending.lectureDebugShortcut == true,
                    lectureTeleportAudience = pending.lectureTeleportAudience == true,
                    lectureSource = pending.lectureSource,
                })
                if ok and assignmentsBySlot[slotKey] then
                    newlyClaimed[#newlyClaimed + 1] = assignmentsBySlot[slotKey]
                elseif ctx.infoLog then
                    lectureTrace.ctx(
                        ctx,
                        "pending_presenter_claim_failed",
                        "actor", actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "reason", tostring(reason or "claim_failed")
                    )
                    ctx.infoLog(
                        "station pending arrival claim failed",
                        actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "reason", tostring(reason or "claim_failed"),
                        "distance", tostring(distanceToStation),
                        "objectDistance", tostring(distanceToObject)
                    )
                end
                if ctx.infoLog then
                    ctx.infoLog(
                        "station pending arrival accepted",
                        actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "distance", tostring(distanceToStation),
                        "objectDistance", tostring(distanceToObject),
                        "approachDistance", tostring(distanceToApproach),
                        "elapsed", tostring(elapsed)
                    )
                end
            elseif ctx.tryStartTravel and pending.stationPos then
                local lastTravelRequestAt = tonumber(pending.lastTravelRequestAt) or 0
                if now - lastTravelRequestAt >= STATION_TRAVEL_RETRY_SECONDS then
                    pending.lastTravelRequestAt = now
                    ctx.tryStartTravel(npc, pending.approachPos or pending.stationPos, "station_assignment_continue", {
                        stationType = pending.profile and pending.profile.stationType,
                        slotKey = slotKey,
                        objectId = obj and obj.recordId,
                        cancelOther = true,
                        destinationTolerance = isLectern and LECTERN_TRAVEL_TOLERANCE or nil,
                    })
                end
                local lastLogAt = tonumber(pending.lastPendingLogAt) or 0
                if ctx.debugLog and now - lastLogAt >= STATION_PENDING_LOG_SECONDS then
                    pending.lastPendingLogAt = now
                    ctx.debugLog(
                        "station pending waiting",
                        actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "distance", tostring(distanceToStation),
                        "objectDistance", tostring(distanceToObject),
                        "approachDistance", tostring(distanceToApproach),
                        "elapsed", tostring(elapsed)
                    )
                end
            end
        end
    end
    return newlyClaimed
end

local function restoreLectureSessions(cell, ctx)
    local name = cellName(ctx, cell)
    local byCell = lectureSessionsByCell[name]
    if not byCell then return {} end
    local restored = {}
    local now = gameTime(ctx)
    for key, session in pairs(byCell) do
        local obj, objReason = findSessionObject(cell, session, ctx)
        local npc, npcReason = findSessionActor(cell, session, ctx)
        local profile = obj and ctx and ctx.profiles and ctx.profiles.stationProfileForObject and ctx.profiles.stationProfileForObject(obj, ctx.settings) or nil
        local slotKey = profile and stationSlotKey(ctx, obj, profile) or nil
        local originPosition = positionFromSnapshot(ctx, session.originPosition)
        local originRotation = rotationFromSnapshot(ctx, session.originYaw, session.originRotation)
        if session.releaseAt and now >= session.releaseAt then
            local expiredReason = "lecture_expired_before_restore_after_wait"
            local existingSlot = npc and npc.id and assignmentByNpc[npc.id] or nil
            if existingSlot and assignmentsBySlot[existingSlot] then
                releaseSlot(existingSlot, expiredReason, ctx, true)
            elseif npc and originPosition and ctx and ctx.returnToOrigin then
                ctx.returnToOrigin(npc, originPosition, originRotation, expiredReason)
            elseif npc and originPosition and ctx and ctx.tryStartTravel then
                ctx.tryStartTravel(npc, originPosition, expiredReason)
            end
            releaseSavedAudienceMembers(session, cell, ctx, expiredReason, slotKey)
            byCell[key] = nil
            recentlyCompletedLectureSessions[lectureSessionRecentKey(name, key)] = now + (20 * 60)
            lectureTrace.ctx(
                ctx,
                "release_end_skipped",
                "object", tostring(session.objectId),
                "slot", tostring(session.slotName),
                "reason", "expired_before_restore",
                "releaseAt", tostring(session.releaseAt),
                "gameTime", tostring(now)
            )
            if ctx.infoLog then ctx.infoLog("lecture restore skipped", tostring(name), "object", tostring(session.objectId), "reason", "station_duration_complete") end
        elseif obj and profile and slotKey and not npc and npcReason == "presenter_not_loaded" then
            lectureTrace.ctx(
                ctx,
                "lecture_restore_waiting_for_presenter",
                "object", tostring(session.objectId),
                "actor", tostring(session.actorRecordId),
                "slot", tostring(slotKey),
                "releaseAt", tostring(session.releaseAt),
                "gameTime", tostring(now)
            )
            if ctx.infoLog then
                ctx.infoLog(
                    "lecture restore pending",
                    tostring(name),
                    "object", tostring(session.objectId),
                    "actor", tostring(session.actorRecordId),
                    "reason", "presenter_not_loaded"
                )
            end
        elseif not obj or not npc or not profile or not slotKey then
            byCell[key] = nil
            if ctx.infoLog then
                ctx.infoLog(
                    "lecture restore cleared",
                    tostring(name),
                    "object", tostring(session.objectId),
                    "actor", tostring(session.actorRecordId),
                    "reason", tostring(objReason or npcReason or (profile and "missing_slot_key" or "missing_station_profile"))
                )
            end
        else
            local restoreYieldReason = restoreSafety.presenterYieldReason(ctx, npc)
            if restoreYieldReason then
                local existingSlot = npc and npc.id and assignmentByNpc[npc.id] or nil
                if existingSlot and assignmentsBySlot[existingSlot] then
                    releaseSlot(existingSlot, "lecture_restore_yield_" .. tostring(restoreYieldReason), ctx, false)
                end
                releaseSavedAudienceMembers(session, cell, ctx, "lecture_restore_yield_" .. tostring(restoreYieldReason), slotKey)
                byCell[key] = nil
                lectureTrace.ctx(
                    ctx,
                    "lecture_restore_yield_external_control",
                    "actor", actorLabel(npc),
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey),
                    "reason", tostring(restoreYieldReason)
                )
                if ctx.infoLog then
                    ctx.infoLog(
                        "lecture restore yielded",
                        tostring(name),
                        actorLabel(npc),
                        "object", tostring(obj.recordId),
                        "slot", tostring(profile.slotName),
                        "reason", tostring(restoreYieldReason)
                    )
                end
            else
            local existingData = assignmentsBySlot[slotKey]
            if existingData and existingData.npc == npc then
                local releaseAt = session.releaseAt
                if releaseAt and (releaseAt - now) < LECTURE_RESTORE_VISIBLE_GRACE_SECONDS then
                    releaseAt = now + LECTURE_RESTORE_VISIBLE_GRACE_SECONDS
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_grace_extended",
                        "object", tostring(session.objectId),
                        "slot", tostring(session.slotName),
                        "releaseAt", tostring(releaseAt),
                        "gameTime", tostring(now)
                    )
                end
                existingData.releaseAt = releaseAt or existingData.releaseAt
                existingData.originPosition = originPosition or existingData.originPosition
                existingData.originRotation = originRotation or existingData.originRotation
                if originPosition then existingData.originSource = "restored_session_origin" end
                restoreAudienceMembers(existingData, session, cell, ctx)
                saveLectureSession(existingData, ctx, "restored_existing")
                byCell[key] = nil
                restored[#restored + 1] = existingData
                lectureTrace.ctx(
                    ctx,
                    "lecture_restore_existing_owner",
                    "actor", actorLabel(npc),
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey),
                    "releaseAt", tostring(existingData.releaseAt)
                )
                if ctx.infoLog then
                    ctx.infoLog(
                        "lecture restored existing station",
                        tostring(name),
                        actorLabel(npc),
                        "object", tostring(obj.recordId),
                        "slot", tostring(profile.slotName),
                        "releaseAt", tostring(existingData.releaseAt)
                    )
                end
            else
                local actorSlot = npc.id and assignmentByNpc[npc.id] or nil
                if actorSlot and actorSlot ~= slotKey then
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_presenter_reclaim",
                        "actor", actorLabel(npc),
                        "fromSlot", tostring(actorSlot),
                        "toSlot", tostring(slotKey)
                    )
                    releaseSlot(actorSlot, "lecture_restore_presenter_reclaim", ctx, false)
                end
                if ctx.assignedActors and npc.id and ctx.assignedActors[npc.id] and ctx.stopInteractionForNpc then
                    ctx.stopInteractionForNpc(npc, "lecture_restore_presenter_reclaim")
                end
                if existingData and existingData.npc ~= npc then
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_slot_conflict",
                        "existingActor", actorLabel(existingData.npc),
                        "restoredActor", actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey)
                    )
                    releaseSlot(slotKey, "lecture_restore_slot_conflict", ctx, false)
                end
                local pending = pendingBySlot[slotKey]
                if pending then
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_pending_slot_cleared",
                        "pendingActor", actorLabel(pending.npc),
                        "restoredActor", actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey)
                    )
                    clearPending(slotKey, pending.npc and pending.npc.id or nil)
                end
                if npc.id and pendingByNpc[npc.id] then
                    clearPending(slotKey, npc.id)
                end
                local releaseAt = session.releaseAt
                if releaseAt and (releaseAt - now) < LECTURE_RESTORE_VISIBLE_GRACE_SECONDS then
                    releaseAt = now + LECTURE_RESTORE_VISIBLE_GRACE_SECONDS
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_grace_extended",
                        "object", tostring(session.objectId),
                        "slot", tostring(session.slotName),
                        "releaseAt", tostring(releaseAt),
                        "gameTime", tostring(now)
                    )
                end
                lectureTrace.ctx(
                    ctx,
                    "lecture_restore_claim_attempt",
                    "actor", actorLabel(npc),
                    "object", tostring(obj and obj.recordId),
                    "slot", tostring(slotKey),
                    "releaseAt", tostring(releaseAt)
                )
                local ok, reason = claimStationWithNpc(cell, obj, profile, slotKey, npc, nil, ctx, {
                    ignoreChance = true,
                    immediatePlacement = true,
                    initialPlacement = false,
                    releaseAt = releaseAt,
                    originPosition = originPosition,
                    originRotation = originRotation,
                    originSource = originPosition and "restored_session_origin" or "restored_session",
                    replaceExisting = true,
                    ignoreCooldown = true,
                    restoreLectureSession = true,
                })
                if ok and assignmentsBySlot[slotKey] then
                    restoreAudienceMembers(assignmentsBySlot[slotKey], session, cell, ctx)
                    byCell[key] = nil
                    restored[#restored + 1] = assignmentsBySlot[slotKey]
                    if ctx.infoLog then ctx.infoLog("lecture restored on cell entry", tostring(name), actorLabel(npc), "object", tostring(obj.recordId), "slot", tostring(profile.slotName), "releaseAt", tostring(session.releaseAt)) end
                else
                    byCell[key] = nil
                    lectureTrace.ctx(
                        ctx,
                        "lecture_restore_claim_failed",
                        "actor", actorLabel(npc),
                        "object", tostring(obj and obj.recordId),
                        "slot", tostring(slotKey),
                        "reason", tostring(reason or "claim_failed")
                    )
                    if ctx.infoLog then ctx.infoLog("lecture restore cleared", tostring(name), "object", tostring(session.objectId), "actor", tostring(session.actorRecordId), "reason", tostring(reason or "claim_failed")) end
                end
            end
            end
        end
    end
    return restored
end

local function claimStation(cell, obj, profile, slotKey, ctx, options)
    options = options or {}
    local stationPos = ctx.profiles.stationWorldPosition(obj, profile, ctx.util)
    if not stationPos then return false, "missing_station_geometry" end
    local npc, dist = findPresenterForStation(cell, obj, profile, stationPos, slotKey, ctx)
    if not npc then return false, "no_presenter_candidate" end
    local gateOk, gateReason, gatePolicy = stationAllowedByReleaseGate(ctx, cell, {
        targetedManual = options.targetedManual == true or ctx.targetStationObject == obj,
        calibrationAction = options.calibrationAction == true or ctx.calibrationAction,
        testingOverride = options.testingOverride == true or ctx.testingOverride,
        debugForce = options.debugForce == true or ctx.debugForce,
        profile = profile,
        object = obj,
    })
    if gateOk ~= true then return false, gateReason or "unverified_location_gate" end
    local claimOptions = {}
    for k, v in pairs(options) do claimOptions[k] = v end
    claimOptions.ignoreChance = options.ignoreChance ~= false
    claimOptions.immediatePlacement = options.immediatePlacement == true or ctx.initialPlacement == true
    claimOptions.initialPlacement = options.initialPlacement == true or ctx.initialPlacement == true
    claimOptions.initialMidLecture = options.initialMidLecture == true
    claimOptions.releaseSafetyGateEnabled = gatePolicy and gatePolicy.enabled == true
    claimOptions.releaseSafetyGateStatus = gatePolicy and gatePolicy.status
    claimOptions.releaseSafetyGateReason = gatePolicy and gatePolicy.reason
    claimOptions.releaseSafetyGateCell = gatePolicy and gatePolicy.cellName
    claimOptions.releaseSafetyGateRegion = gatePolicy and gatePolicy.regionName
    claimOptions.releaseSafetyGateFurnitureType = gatePolicy and gatePolicy.furnitureType
    claimOptions.releaseSafetyGateLabel = gatePolicy and ctx.releaseSafetyGate and ctx.releaseSafetyGate.visibleLabel and ctx.releaseSafetyGate.visibleLabel(gatePolicy) or nil
    return claimStationWithNpc(cell, obj, profile, slotKey, npc, dist, ctx, claimOptions)
end

local function releaseAudienceMembers(data, ctx, reason, options)
    options = options or {}
    if not (data and data.audience and ctx and ctx.releaseAudienceNpc) then return 0, false end
    local releaseIndex = 0
    local canPlayAudienceAnimation = audienceAnimationsEnabled()
    local applauseRoll = stableUnit(ctx, tostring(data.slotKey or data.objectId or "lecture") .. "::" .. tostring(data.releaseAt or data.claimedAt or 0) .. "::end_applause")
    local doApplause = tostring(reason or "") == "station_duration_complete"
        and options.skipApplause ~= true
        and canPlayAudienceAnimation == true
        and applauseRoll <= LECTURE_END_APPLAUSE_CHANCE
    for npcId, item in pairs(data.audience) do
        local npc = item and item.npc or nil
        if validObject(ctx, npc) then
            releaseIndex = releaseIndex + 1
            local delay = lectureAudience.releaseDelay(ctx, npc, data.slotKey, releaseIndex)
            if doApplause and ctx.sendAudienceReaction then
                ctx.sendAudienceReaction(npc, {
                    group = "sdpaudiencesitspectator4",
                    reason = "lecture_end_applause",
                    restoreBaseAfter = 2.35,
                    skipBaseRestore = true,
                })
                delay = delay + 2.55
            end
            if options.immediate == true then
                delay = 0.05 + (math.max(0, releaseIndex - 1) * 0.05)
            end
            ctx.releaseAudienceNpc(npc, reason or "lecture_ended", delay, item)
        end
        data.audience[npcId] = nil
    end
    if doApplause then
        lectureTrace.ctx(
            ctx,
            "audience_end_applause",
            "object", tostring(data.objectId),
            "slot", tostring(data.slotKey),
            "chance", tostring(LECTURE_END_APPLAUSE_CHANCE),
            "roll", tostring(applauseRoll),
            "count", tostring(releaseIndex)
        )
    elseif tostring(reason or "") == "station_duration_complete" then
        lectureTrace.ctx(
            ctx,
            "audience_end_applause_skipped",
            "object", tostring(data.objectId),
            "slot", tostring(data.slotKey),
            "chance", tostring(LECTURE_END_APPLAUSE_CHANCE),
            "roll", tostring(applauseRoll),
            "count", tostring(releaseIndex),
            "reason", canPlayAudienceAnimation == true and (releaseIndex > 0 and "chance_roll" or "no_audience") or "audience_assets_disabled"
        )
    end
    return releaseIndex, doApplause
end

local function refreshAssignments(ctx, allow, releaseReason)
    for slotKey, data in pairs(assignmentsBySlot) do
        local npc = data and data.npc or nil
        local obj = data and data.object or nil
        local currentGameTime = gameTime(ctx)
        local previousGameTime = tonumber(data and data.lastRefreshGameTime)
        local largeAdvance = ctx and ctx.largeTimeAdvance == true
            or (previousGameTime ~= nil and (currentGameTime - previousGameTime) >= LECTURE_WAIT_ADVANCE_SECONDS)
        if data then data.lastRefreshGameTime = currentGameTime end
        if allow ~= true then
            releaseAudienceMembers(data, ctx, releaseReason or "station_time_window_closed")
            releaseSlot(slotKey, releaseReason or "station_time_window_closed", ctx, true)
        elseif not validObject(ctx, npc) then
            releaseAudienceMembers(data, ctx, "invalid_station_actor")
            releaseSlot(slotKey, "invalid_station_actor", ctx, false)
        elseif not validObject(ctx, obj) then
            releaseAudienceMembers(data, ctx, "invalid_station_object")
            releaseSlot(slotKey, "invalid_station_object", ctx, false)
        elseif data.presenterReleaseDueAt then
            local now = ctx.now and ctx.now() or math.huge
            if now >= data.presenterReleaseDueAt then
                lectureTrace.ctx(
                    ctx,
                    "release_presenter_delay_complete",
                    "actor", actorLabel(npc),
                    "object", tostring(data.objectId),
                    "slot", tostring(slotKey),
                    "reason", tostring(data.presenterReleaseReason or "station_duration_complete")
                )
                releaseSlot(slotKey, data.presenterReleaseReason or "station_duration_complete", ctx, data.presenterReleaseReturnToOrigin ~= false)
            end
        elseif data.releaseAt and largeAdvance == true and data.releaseAt > currentGameTime
            and (data.releaseAt - currentGameTime) < LECTURE_RESTORE_VISIBLE_GRACE_SECONDS then
            data.releaseAt = currentGameTime + LECTURE_RESTORE_VISIBLE_GRACE_SECONDS
            lectureTrace.ctx(
                ctx,
                "lecture_visible_grace_extended",
                "actor", actorLabel(npc),
                "object", tostring(data.objectId),
                "slot", tostring(slotKey),
                "releaseAt", tostring(data.releaseAt),
                "gameTime", tostring(currentGameTime),
                "reason", "large_time_advance"
            )
        elseif data.releaseAt and currentGameTime >= data.releaseAt then
            local durationReason = largeAdvance == true and "station_duration_complete_after_wait" or "station_duration_complete"
            lectureTrace.ctx(
                ctx,
                "release_end_due",
                "actor", actorLabel(npc),
                "object", tostring(data.objectId),
                "slot", tostring(slotKey),
                "releaseAt", tostring(data.releaseAt),
                "gameTime", tostring(currentGameTime),
                "largeAdvance", tostring(largeAdvance == true)
            )
            if largeAdvance == true and ctx and ctx.disguiseStationRelease then
                ctx.disguiseStationRelease(npc, obj, durationReason, {
                    position = data.position,
                    releaseAt = data.releaseAt,
                    gameTime = currentGameTime,
                })
            end
            local releasedAudience, didApplause = releaseAudienceMembers(data, ctx, durationReason, {
                immediate = largeAdvance == true,
                skipApplause = largeAdvance == true,
            })
            if releasedAudience > 0 and largeAdvance == true then
                lectureTrace.ctx(
                    ctx,
                    "release_presenter_immediate_after_wait",
                    "actor", actorLabel(npc),
                    "object", tostring(data.objectId),
                    "slot", tostring(slotKey),
                    "audienceReleased", tostring(releasedAudience)
                )
                releaseSlot(slotKey, durationReason, ctx, true)
            elseif releasedAudience > 0 and ctx.now then
                local delay = largeAdvance == true and 0.25 or (4 + (stableUnit(ctx, tostring(slotKey) .. "::presenter_release_delay") * 6))
                if didApplause then delay = delay + 2.8 end
                data.presenterReleaseDueAt = ctx.now() + delay
                data.presenterReleaseReason = durationReason
                data.presenterReleaseReturnToOrigin = true
                lectureTrace.ctx(
                    ctx,
                    "release_presenter_delayed",
                    "actor", actorLabel(npc),
                    "object", tostring(data.objectId),
                    "slot", tostring(slotKey),
                    "audienceReleased", tostring(releasedAudience),
                    "delay", tostring(delay),
                    "applause", tostring(didApplause == true)
                )
            else
                releaseSlot(slotKey, durationReason, ctx, true)
            end
        elseif not sharedSmoothMoveActive(ctx, npc) and npc and npc.position and data.position and (npc.position - data.position):length() > math.max(220, (tonumber(data.profile and data.profile.radius) or 260) + 120) then
            local now = ctx.now and ctx.now() or 0
            local claimElapsed = now - (tonumber(data.claimedAt) or now)
            local driftGrace = claimElapsed <= STATION_CLAIM_DRIFT_GRACE_SECONDS
                or (data.presenterEntrySmooth == true and claimElapsed <= STATION_PRESENTER_ENTRY_DRIFT_GRACE_SECONDS)
            if driftGrace == true then
                if now - (tonumber(data.lastStationDriftIgnoredLogAt) or -999) >= 2 then
                    data.lastStationDriftIgnoredLogAt = now
                    lectureTrace.ctx(
                        ctx,
                        "presenter_release_deferred",
                        "reason", "station_claim_settle_grace",
                        "actor", actorLabel(npc),
                        "object", tostring(data.objectId),
                        "slot", tostring(slotKey),
                        "distance", tostring((npc.position - data.position):length()),
                        "elapsed", tostring(claimElapsed),
                        "smoothEntry", tostring(data.presenterEntrySmooth == true)
                    )
                end
            elseif ctx.infoLog and now - (tonumber(data.lastStationDriftLogAt) or -999) >= 8 then
                data.lastStationDriftLogAt = now
                ctx.infoLog(
                    "station actor drift detected",
                    actorLabel(npc),
                    "object", tostring(data.objectId),
                    "slot", tostring(data.slotName),
                    "distance", tostring((npc.position - data.position):length()),
                    "release", data.calibrationFill == true and "held_for_station_restore" or "station_actor_moved_away"
                )
            end
            if driftGrace == true then
                -- Keep the station claim alive while global and local actor state settle after claim/teleport.
            elseif data.calibrationFill == true then
                data.releaseAt = nil
            else
                releaseAudienceMembers(data, ctx, "station_actor_moved_away")
                releaseSlot(slotKey, "station_actor_moved_away", ctx, false)
            end
        end
    end
end

function M.process(cell, ctx)
    if not (cell and ctx and ctx.types and ctx.types.NPC and ctx.profiles) then return {} end
    purgeCompletedLectureCache(ctx)
    local allow, reason = currentHourAllowsStation(ctx)
    local name = cellName(ctx, cell)
    local releaseGateOk, releaseGateReason = stationAllowedByReleaseGate(ctx, cell, {
        targetedManual = ctx.targetStationObject ~= nil,
        calibrationAction = ctx.calibrationAction,
        testingOverride = ctx.testingOverride,
        debugForce = ctx.debugForce,
    })
    if releaseGateOk ~= true then
        refreshAssignments(ctx, false, releaseGateReason or "unverified_location_gate")
        if ctx.debugLog then
            ctx.debugLog("lecture assignment skipped by release safety gate", tostring(name), tostring(releaseGateReason))
        end
        return {}
    end
    local savedSessions = hasSavedLectureSessions(name)
    refreshAssignments(ctx, allow == true or savedSessions == true, reason)
    local newlyClaimed = {}
    if savedSessions == true then
        local restored = restoreLectureSessions(cell, ctx)
        for _, data in ipairs(restored) do newlyClaimed[#newlyClaimed + 1] = data end
    end
    if allow ~= true then
        local pendingKeys = {}
        for slotKey in pairs(pendingBySlot) do pendingKeys[#pendingKeys + 1] = slotKey end
        for _, slotKey in ipairs(pendingKeys) do
            local pending = pendingBySlot[slotKey]
            clearPending(slotKey, pending and pending.npc and pending.npc.id)
        end
        if lectureSessionsByCell[name] and hasSavedLectureSessions(name) ~= true then
            lectureSessionsByCell[name] = nil
            if ctx.infoLog then ctx.infoLog("lecture restore cleared", tostring(name), "reason", tostring(reason or "station_time_window_closed")) end
        end
        return newlyClaimed
    end
    for _, data in ipairs(processPendingClaims(ctx)) do newlyClaimed[#newlyClaimed + 1] = data end

    local scanInterval = tonumber(ctx.settings and ctx.settings.stationLecternScanSeconds) or 10
    if ctx.forceScan == true then
        scanElapsed = scanInterval
    else
        scanElapsed = scanElapsed + (tonumber(ctx.dt) or 0)
    end
    if scanElapsed < scanInterval then
        return newlyClaimed
    end
    scanElapsed = 0

    local startWindowOk, startWindowReason, startWindowDistance = regularLectureStartWindow(ctx)
    for _, obj in ipairs(cell:getAll()) do
        if validObject(ctx, obj) then
            local profile = ctx.profiles.stationProfileForObject(obj, ctx.settings)
            if profile and lower(profile.stationType) == "lectern" then
                local gateOk, gateReason = stationAllowedByReleaseGate(ctx, cell, {
                    targetedManual = ctx.targetStationObject == obj,
                    calibrationAction = ctx.calibrationAction,
                    testingOverride = ctx.testingOverride,
                    debugForce = ctx.debugForce,
                    profile = profile,
                    object = obj,
                })
                local slotKey = stationSlotKey(ctx, obj, profile)
                local targetOk = not ctx.targetStationObject or ctx.targetStationObject == obj
                if gateOk ~= true then
                    if ctx.debugLog then
                        ctx.debugLog("lecture object skipped by release safety gate", tostring(obj.recordId or obj.id), tostring(gateReason))
                    end
                elseif targetOk and not assignmentsBySlot[slotKey] and not pendingBySlot[slotKey] then
                    local initialMidLecture = initialActiveLectureAllowed(ctx, slotKey, cell)
                    if ctx.targetStationObject or startWindowOk == true or initialMidLecture == true then
                        local ok = claimStation(cell, obj, profile, slotKey, ctx, { initialMidLecture = initialMidLecture })
                        if ok and assignmentsBySlot[slotKey] then
                            newlyClaimed[#newlyClaimed + 1] = assignmentsBySlot[slotKey]
                        end
                    elseif ctx.debugLog and shouldLogStartWindowSkip(slotKey, ctx) then
                        ctx.debugLog(
                            "lecture lifecycle waiting for regular start window",
                            "object", tostring(obj.recordId),
                            "slot", tostring(profile.slotName),
                            "reason", tostring(startWindowReason),
                            "minutesFromBoundary", tostring(startWindowDistance)
                        )
                    end
                end
            end
        end
    end
    return newlyClaimed
end

function M.snapshotActiveLectures(ctx, reason)
    local saved = 0
    for _, data in pairs(assignmentsBySlot) do
        if saveLectureSession(data, ctx, reason or "cell_change") then saved = saved + 1 end
    end
    if saved > 0 and ctx and ctx.infoLog then
        ctx.infoLog("lecture sessions preserved for cell leave", tostring(saved), "reason", tostring(reason or "cell_change"))
    end
    return saved
end

function M.onSave(ctx)
    M.snapshotActiveLectures(ctx, "save")
    local rows = {}
    for name, byCell in pairs(lectureSessionsByCell or {}) do
        for key, session in pairs(byCell or {}) do
            local copy = copySessionSnapshot(session)
            if copy then
                copy.cellName = copy.cellName or tostring(name)
                copy.key = copy.key or tostring(key)
                rows[#rows + 1] = copy
            end
        end
    end
    return {
        version = 1,
        sessions = rows,
    }
end

function M.onLoad(data)
    lectureSessionsByCell = {}
    local rows = data and data.sessions or nil
    if type(rows) ~= "table" then return 0 end
    local loaded = 0
    for _, row in ipairs(rows) do
        local copy = copySessionSnapshot(row)
        if copy and loaded < 80 then
            local name = copy.cellName
            local key = tostring(copy.key or (copy.objectId or "<station>") .. "::" .. (copy.slotName or "station"))
            lectureSessionsByCell[name] = lectureSessionsByCell[name] or {}
            lectureSessionsByCell[name][key] = copy
            loaded = loaded + 1
        end
    end
    return loaded
end

function M.refreshLecture(slotKey, ctx, reason)
    local data = slotKey and assignmentsBySlot[slotKey] or nil
    if not data then return false, "station_not_claimed" end
    if lower(data.stationType) ~= "lectern" then return false, "not_lectern_station" end
    local releaseOptions = {}
    data.releaseAt = lectureReleaseAt(data.npc, slotKey, ctx, releaseOptions)
    data.releaseDurationSeconds = releaseOptions.releaseDurationSeconds
    data.releaseMinHours = releaseOptions.releaseMinHours
    data.releaseMaxHours = releaseOptions.releaseMaxHours
    data.releaseSequence = releaseOptions.releaseSequence
    lectureTrace.ctx(
        ctx,
        "session_start_refresh_called",
        "path", "refreshLecture",
        "actor", actorLabel(data.npc),
        "object", tostring(data.objectId),
        "slot", tostring(slotKey),
        "reason", tostring(reason or "lecture_refreshed")
    )
    traceReleaseScheduled(ctx, data, tostring(reason or "lecture_refreshed"))
    saveLectureSession(data, ctx, reason or "lecture_refreshed")
    sendPresenterAnimationRefresh(data, reason or "lecture_refreshed", ctx)
    if ctx.infoLog then
        ctx.infoLog("lecture refreshed", actorLabel(data.npc), "object", tostring(data.objectId), "slot", tostring(data.slotName), "releaseAt", tostring(data.releaseAt), "reason", tostring(reason or "lecture_refreshed"))
    end
    return true, "lecture_refreshed", data
end

function M.takePendingInitialActorIds()
    local list = {}
    for id in pairs(pendingInitialStationActorIds) do
        list[#list + 1] = id
        pendingInitialStationActorIds[id] = nil
    end
    return list
end

function M.lecternClaimForObject(obj, slotKey)
    local data = slotKey and assignmentsBySlot[slotKey] or nil
    if data and data.object == obj and lower(data.stationType) == "lectern" then return data end
    return true
end

function M.claimedStationData(slotKey)
    return slotKey and assignmentsBySlot[slotKey] or nil
end

function M.markPendingLectureStart(slotKey, options, ctx)
    return markPendingLectureStart(slotKey, options, ctx)
end

function M.stationSlotOccupied(slotKey)
    if not slotKey then return false, false end
    return assignmentsBySlot[slotKey] ~= nil, pendingBySlot[slotKey] ~= nil
end

function M.stationDataForNpc(npc)
    local slotKey = npc and npc.id and assignmentByNpc[npc.id] or nil
    if slotKey and assignmentsBySlot[slotKey] then return assignmentsBySlot[slotKey] end
    slotKey = npc and npc.id and pendingByNpc[npc.id] or nil
    return slotKey and pendingBySlot[slotKey] or nil
end

function M.applyCalibration(session, ctx)
    if not (session and session.object and ctx and ctx.profiles and ctx.util) then
        return false, "missing_station_calibration_context"
    end
    local obj = session.object
    local profile = session.profile or ctx.profiles.stationProfileForObject(obj, ctx.settings)
    if not profile then return false, "missing_station_profile" end
    local slotKey = session.slotKey or stationSlotKey(ctx, obj, profile)
    local data = assignmentsBySlot[slotKey]
    if not data then
        slotKey = stationSlotKey(ctx, obj, profile)
        data = assignmentsBySlot[slotKey]
    end
    local adjusted = profileWithCalibration(profile, session.calibration)
    local stationPos = ctx.profiles.stationWorldPosition(obj, adjusted, ctx.util)
    local facingDirection = ctx.profiles.stationFacingDirection(obj, adjusted, ctx.util)
    if not (stationPos and facingDirection) then return false, "missing_station_geometry" end

    session.position = stationPos
    session.finalPosition = stationPos
    session.stationPosition = stationPos
    session.facingDirection = facingDirection
    session.finalRotation = yawFromDirection(facingDirection, session.finalRotation or 0)

    if not data then return true, "station_session_calibration_stored" end
    data.calibration = session.calibration
    data.position = stationPos
    data.facingDirection = facingDirection
    data.finalRotation = session.finalRotation
    if validObject(ctx, data.npc) then
        local queuedSmooth = ctx.smoothMove and ctx.smoothMove(data.npc, data, stationPos, data.finalRotation, "station_calibration_smooth", "developer_menu", {
            skipStateCheck = true,
            isActive = function(npc, moveData)
                return npc and npc.id and moveData and assignmentByNpc[npc.id] == moveData.slotKey and assignmentsBySlot[moveData.slotKey] == moveData
            end,
        }) or false
        if not queuedSmooth then
            local ok, err = ctx.tryTeleport(data.npc, data.npc.cell, stationPos, {
                rotation = ctx.rotationFromYaw(data.finalRotation, data.npc.rotation),
            })
            if not ok then return false, "teleport_failed:" .. tostring(err) end
        end
        data.npc:sendEvent("SitDownPleaseStationAssigned", {
            stationType = data.stationType,
            slotName = data.slotName,
            slotKey = data.slotKey,
            object = obj,
            objectId = obj.recordId,
            finalPosition = stationPos,
            finalRotation = data.finalRotation,
            facingDirection = facingDirection,
            lectureSessionId = data.lectureSessionId,
            lectureAnimation = presenterAnimationPayloadIfAudience(data, "station_calibration"),
        })
        if queuedSmooth and ctx.debugLog then
            ctx.debugLog("station calibration smooth queued", actorLabel(data.npc), "object", tostring(obj.recordId), "slot", tostring(profile.slotName), "final", tostring(stationPos))
        end
    end
    if ctx.infoLog then
        ctx.infoLog("station calibration applied", actorLabel(data.npc), "object", tostring(obj.recordId), "slot", tostring(profile.slotName), "final", tostring(stationPos), "rotation", tostring(data.finalRotation))
    end
    return true, "station_calibration_applied"
end

function M.claimWithNpc(obj, npc, ctx, options)
    if not (obj and npc and ctx and ctx.profiles) then return false, "missing_station_claim_context" end
    local profile = ctx.profiles.stationProfileForObject(obj, ctx.settings)
    if not profile then return false, "missing_station_profile" end
    local slotKey = stationSlotKey(ctx, obj, profile)
    local cell = obj.cell or npc.cell
    if not cell then return false, "missing_station_cell" end
    options = options or {}
    options.profile = options.profile or profile
    options.object = options.object or obj
    local gateOk, gateReason, gatePolicy = stationAllowedByReleaseGate(ctx, cell, options)
    if gateOk ~= true then return false, gateReason or "unverified_location_gate" end
    if gatePolicy then
        options.releaseSafetyGateEnabled = gatePolicy.enabled == true
        options.releaseSafetyGateStatus = gatePolicy.status
        options.releaseSafetyGateReason = gatePolicy.reason
        options.releaseSafetyGateCell = gatePolicy.cellName
        options.releaseSafetyGateRegion = gatePolicy.regionName
        options.releaseSafetyGateFurnitureType = gatePolicy.furnitureType
        options.releaseSafetyGateLabel = ctx.releaseSafetyGate and ctx.releaseSafetyGate.visibleLabel and ctx.releaseSafetyGate.visibleLabel(gatePolicy) or nil
    end
    local stationPos = ctx.profiles.stationWorldPosition(obj, profile, ctx.util)
    local dist = npc.position and stationPos and (npc.position - stationPos):length() or nil
    return claimStationWithNpc(cell, obj, profile, slotKey, npc, dist, ctx, options)
end

function M.claimNearestPresenterForStation(obj, ctx, options)
    if not (obj and ctx and ctx.profiles) then return false, "missing_station_claim_context" end
    local profile = ctx.profiles.stationProfileForObject(obj, ctx.settings)
    if not profile then return false, "missing_station_profile" end
    local slotKey = stationSlotKey(ctx, obj, profile)
    local cell = obj.cell
    if not cell then return false, "missing_station_cell" end
    options = options or {}
    options.profile = options.profile or profile
    options.object = options.object or obj
    return claimStation(cell, obj, profile, slotKey, ctx, options)
end

function M.stationSlotKey(obj, profile, ctx)
    return stationSlotKey(ctx or {}, obj, profile)
end

function M.shouldRebalanceAudience(slotKey, now)
    now = tonumber(now) or 0
    local last = tonumber(lastAudienceRebalanceBySlot[slotKey] or -999) or -999
    if now - last < 8 then return false end
    lastAudienceRebalanceBySlot[slotKey] = now
    return true
end

function M.noteAudienceMember(slotKey, npc, details)
    local data = slotKey and assignmentsBySlot[slotKey] or nil
    if not (data and npc and npc.id) then return false end
    details = details or {}
    data.audience = data.audience or {}
    data.audience[npc.id] = {
        npc = npc,
        stationSlotKey = slotKey,
        sector = lectureAnimation.audienceSector(data, npc),
        seatedAccepted = true,
        originPosition = details.originPosition,
        originRotation = details.originRotation,
        returnMode = details.returnMode,
        wasAlreadySitting = details.wasAlreadySitting == true,
        originalAnimation = details.originalAnimation,
    }
    lectureAnimation.rebuildAudienceSummary(data)
    sendPresenterAnimationRefresh(data, "audience_changed")
    return true
end

function M.reset(preserveLectureSessions)
    stationClaims:clear()
    pendingStationClaims:clear()
    lastAudienceRebalanceBySlot = {}
    lastLectureStartWindowSkipBySlot = {}
    pendingInitialStationActorIds = {}
    recentlyReleasedForSleepByNpc = {}
    recentlyCompletedLectureSessions = {}
    lastLectureCooldownSkipByKey = {}
    lastNoAudienceLogBySlot = {}
    if preserveLectureSessions ~= true then lectureSessionsByCell = {} end
    scanElapsed = 0
end

function M.releaseForNpc(npc, reason, ctx)
    local slotKey = npc and npc.id and assignmentByNpc[npc.id] or nil
    if not slotKey then return false end
    return releaseSlot(slotKey, reason or "station_actor_released", ctx, false)
end

function M.consumeSleepWindowReleaseForNpc(npc, now)
    local npcId = npc and npc.id
    if not npcId then return false end
    local expiresAt = recentlyReleasedForSleepByNpc[npcId]
    if not expiresAt then return false end
    if tonumber(now or 0) > expiresAt then
        recentlyReleasedForSleepByNpc[npcId] = nil
        return false
    end
    recentlyReleasedForSleepByNpc[npcId] = nil
    return true
end

return M
