local module = {}
local manualAssignment = require('scripts/sitDownPlease/assignment/manualAssignment')
local sleepBedAccess = require('scripts/sitDownPlease/sleeping/bedAccess')

function module.create(env)
    local M = {}

    local world = assert(env.world, "calibrationMenu.create requires env.world")
    local core = assert(env.core, "calibrationMenu.create requires env.core")
    local types = assert(env.types, "calibrationMenu.create requires env.types")
    local util = assert(env.util, "calibrationMenu.create requires env.util")
    local profiles = assert(env.profiles, "calibrationMenu.create requires env.profiles")
    local calibrationLock = assert(env.calibrationLock, "calibrationMenu.create requires env.calibrationLock")
    local interactingState = assert(env.interactingState, "calibrationMenu.create requires env.interactingState")
    local isObjValid = assert(env.isObjValid, "calibrationMenu.create requires env.isObjValid")
    local buildCandidateSlots = assert(env.buildCandidateSlots, "calibrationMenu.create requires env.buildCandidateSlots")
    local chooseCandidateForNpc = assert(env.chooseCandidateForNpc, "calibrationMenu.create requires env.chooseCandidateForNpc")
    local sendConsiderInteraction = assert(env.sendConsiderInteraction, "calibrationMenu.create requires env.sendConsiderInteraction")
    local infoLog = assert(env.infoLog, "calibrationMenu.create requires env.infoLog")
    local debugLog = assert(env.debugLog, "calibrationMenu.create requires env.debugLog")
    local cellName = assert(env.cellName, "calibrationMenu.create requires env.cellName")
    local clearRelevantObjectCache = assert(env.clearRelevantObjectCache, "calibrationMenu.create requires env.clearRelevantObjectCache")
    local getAssignedActors = assert(env.getAssignedActors, "calibrationMenu.create requires env.getAssignedActors")
    local isSlotOccupied = env.isSlotOccupied or function() return false end
    local isNpcEligibleForInteraction = env.isNpcEligibleForInteraction

    local calibrationTestNpc = nil

    local function calibrationContext()
        return {
            profiles = profiles,
            world = world,
            assignedActors = getAssignedActors(),
            interactingState = interactingState,
            isObjValid = isObjValid,
            sendConsiderInteraction = sendConsiderInteraction,
            infoLog = infoLog,
            debugLog = debugLog,
            cellName = cellName,
            now = core.getSimulationTime,
        }
    end

    local function sendCalibrationMenuStatus(player, message, extra)
        if not player then return end
        local payload = type(extra) == "table" and profiles.shallowCopy(extra) or {}
        payload.message = message
        if payload.targetLabel then
            infoLog("calibration_target_display_state", tostring(payload.targetLabel), "message", tostring(message))
        elseif payload.cleared == true then
            infoLog("calibration_target_display_state", "Target: none selected", "message", tostring(message))
        end
        pcall(function()
            player:sendEvent("SitDownPleaseCalibrationMenuStatus", payload)
        end)
    end

    local function zeroCalibrationOffset()
        return { x = 0, y = 0, z = 0, yaw = 0 }
    end

    local function currentAssignmentForSession(session)
        if not (session and session.actor and session.actor.id) then return nil end
        local assignedActors = getAssignedActors()
        local data = assignedActors and assignedActors[session.actor.id] or nil
        if not (data and data.interactionType == session.interactionType and data.slotKey == session.slotKey) then return nil end
        local dataObjectId = data.objectId or (data.object and data.object.recordId)
        if tostring(dataObjectId or "") ~= tostring(session.objectRecordId or "") then return nil end
        return data
    end

    local function sendCalibrationOffsetsForSession(player, session)
        if not (player and session and (session.interactionType == "sitting" or session.interactionType == "sleeping")) then return end
        local source = currentAssignmentForSession(session) or session
        pcall(function()
            player:sendEvent("SitDownPleaseCalibrationOffsets", {
                interactionType = session.interactionType,
                profileOffset = source.profileOffset or zeroCalibrationOffset(),
                animationOffset = source.animationOffset or zeroCalibrationOffset(),
                calibration = source.calibration or zeroCalibrationOffset(),
                animation = source.animationName or source.animation,
                targetLabel = calibrationLock.sessionLabel(session),
            })
        end)
    end

    local function rememberPendingCalibrationTarget(actor, candidate, reason)
        if not (actor and candidate and candidate.object and candidate.slotKey) then return false end
        local data = profiles.shallowCopy(candidate)
        data.npc = actor
        data.actor = actor
        data.actorId = actor.id
        data.actorRecordId = actor.recordId
        data.object = candidate.object
        data.objectId = candidate.objectId or (candidate.object and candidate.object.recordId)
        data.model = candidate.model
        data.profile = candidate.profile
        data.profileId = candidate.profileId
        data.interactionType = candidate.interactionType
        data.slot = candidate.slot
        data.slotName = candidate.slotName
        data.slotKey = candidate.slotKey
        data.finalPosition = candidate.finalPosition
        data.approachPos = candidate.approachPos
        data.facingDirection = candidate.preferredFacingDirection
        data.facingObjectId = candidate.facingObjectId
        data.facingKind = candidate.facingKind
        data.facingObjectPosition = candidate.facingObjectPosition
        calibrationLock.rememberTarget(data, {
            cellName = cellName,
            now = core.getSimulationTime,
            infoLog = infoLog,
        }, reason or "manual_pending")
        return true
    end

    local function playerForwardVector(player)
        local yaw = 0
        if player and player.rotation then
            local ok, value = pcall(function() return player.rotation:getYaw() end)
            if ok and value then yaw = tonumber(value) or 0 end
        end
        return util.vector3(math.sin(yaw), math.cos(yaw), 0)
    end

    local function removeCalibrationTestNpc(reason, player, options)
        options = options or {}
        local npc = calibrationTestNpc
        if not isObjValid(npc) and player and player.cell and player.position and player.cell.getAll then
            local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
            if okList and npcs then
                local best, bestDist = nil, nil
                for _, candidate in ipairs(npcs) do
                    local recordId = candidate and candidate.recordId and string.lower(tostring(candidate.recordId)) or ""
                    if recordId == "ken" and isObjValid(candidate) then
                        local dist = candidate.position and (candidate.position - player.position):length() or math.huge
                        if dist <= 3500 and (not bestDist or dist < bestDist) then
                            best, bestDist = candidate, dist
                        end
                    end
                end
                npc = best
            end
        end
        calibrationTestNpc = nil
        if not isObjValid(npc) then
            if options.silent == true then return false, nil end
            return false, "No spawned test NPC to remove."
        end
        local assignedActors = getAssignedActors()
        local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
        if npc.id and assignedActors[npc.id] and stopInteractionForNpc then
            pcall(function() stopInteractionForNpc(npc, reason or "developer_test_npc_removed") end)
        end
        local ok, err = pcall(function() npc:remove() end)
        if not ok then
            ok, err = pcall(function() npc.enabled = false end)
        end
        if ok then
            clearRelevantObjectCache("developer_test_npc_removed")
            if options.silent ~= true then
                infoLog("developer calibration test npc removed", "ken", "reason", tostring(reason or "manual"))
            end
            return true, options.silent == true and nil or "Removed Admiral Rolston."
        end
        infoLog("developer calibration test npc remove failed", tostring(err))
        return false, "Could not remove the spawned test NPC. Check openmw.log."
    end

    local function spawnCalibrationTestNpcNearPlayer(player)
        if not (player and player.cell and player.position) then
            return nil, "Player position is not available."
        end
        removeCalibrationTestNpc("replace_test_npc", player, { silent = true })
        local okCreate, npcOrErr = pcall(function()
            return world.createObject("ken", 1)
        end)
        if not okCreate or not npcOrErr then
            infoLog("developer calibration test npc spawn failed", tostring(npcOrErr))
            return nil, "Could not create Admiral Rolston. Check that the vanilla NPC record 'ken' is available."
        end

        local npc = npcOrErr
        local spawnPos = player.position + playerForwardVector(player) * 120 + util.vector3(0, 0, 8)
        local okTeleport, teleportErr = pcall(function()
            npc:teleport(player.cell, spawnPos, { rotation = player.rotation, onGround = true })
        end)
        if not okTeleport then
            pcall(function() npc:remove() end)
            infoLog("developer calibration test npc teleport failed", tostring(teleportErr))
            return nil, "Created Admiral Rolston, but could not place him near the player."
        end
        calibrationTestNpc = npc
        clearRelevantObjectCache("developer_test_npc_spawned")
        infoLog("developer calibration test npc spawned", "ken", "cell", tostring(cellName(player.cell)), "position", tostring(spawnPos))
        return npc, "Spawned Admiral Rolston."
    end

    local function candidateTargetPosition(candidate)
        if not (candidate and candidate.object) then return nil end
        local obj = candidate.object
        local profile = candidate.profile or {}
        local slot = candidate.slot or {}
        if candidate.interactionType == "sleeping" then
            local offset = slot.sleepRootLocalOffset or profile.sleepRootLocalOffset or slot.sleepOffset or profile.sleepOffset
            if offset then
                local ok, pos = pcall(function()
                    return obj.position + obj.rotation * util.vector3(offset.x or 0, offset.y or 0, 0)
                end)
                if ok and pos then return pos end
            end
        elseif candidate.interactionType == "sitting" then
            return candidate.finalPosition or candidate.position or candidate.approachPos or obj.position
        elseif candidate.approachPos then
            return candidate.approachPos
        end
        return obj.position
    end

    local function candidateDistanceToPlayer(candidate, player)
        local pos = candidateTargetPosition(candidate)
        if not (pos and player and player.position) then return math.huge end
        return (pos - player.position):length()
    end

    local function candidateFacingBonus(candidate, player)
        local pos = candidateTargetPosition(candidate)
        if not (pos and player and player.position) then return 0 end
        local delta = pos - player.position
        local flat = util.vector3(delta.x or 0, delta.y or 0, 0)
        if flat:length() <= 1 then return 0 end
        local facing = playerForwardVector(player)
        local dir = flat:normalize()
        local dot = (dir.x * facing.x) + (dir.y * facing.y)
        if dot >= 0.85 then return -300 end
        if dot >= 0.55 then return -180 end
        if dot >= 0.2 then return -60 end
        if dot < -0.45 then return 320 end
        if dot < -0.1 then return 160 end
        return 0
    end

    local function candidateSlotLabel(candidate)
        if not candidate then return "default" end
        local raw = tostring(candidate.slotName or candidate.slotKey or "default")
        local profile = candidate.profile or {}
        local bedType = tostring(profile.bedType or profile.type or "")
        if candidate.interactionType == "sleeping" and (bedType == "bottom_bunk" or bedType == "top_bunk") and raw == "sleep_main" then
            return bedType == "top_bunk" and "top bunk" or "bottom bunk"
        end
        if raw == "default" then return candidate.interactionType == "sleeping" and "main bed slot" or "main seat" end
        if raw == "sleep_main" then return "main bed slot" end
        if raw == "sleep_left" then return "left bed slot" end
        if raw == "sleep_right" then return "right bed slot" end
        if raw == "sleep_a" then return "bed slot A" end
        if raw == "sleep_b" then return "bed slot B" end
        if raw == "seat_a" then return "seat A" end
        if raw == "seat_b" then return "seat B" end
        if raw == "seat_c" then return "seat C" end
        return raw
    end

    local function chooseNearestCandidateForPlayer(player, interactionTypes, options)
        options = options or {}
        local best = nil
        local targetRadius = tonumber(options.targetRadius or 1200) or 1200
        local useFacingBias = options.useFacingBias == true
        local useTypeBias = options.useTypeBias == true
        local debugSelection = options.debugSelection == true
        for typeIndex, candidateType in ipairs(interactionTypes or {}) do
            local candidates = buildCandidateSlots(player.cell, candidateType, { ignoreTimeGate = true, manualAssign = true, calibrationAction = true, allowOccupiedByTestNpc = true })
            for _, candidate in ipairs(candidates or {}) do
                local slotKey = candidate and candidate.slotKey
                if candidate and candidate.object and isObjValid(candidate.object) and (not options.avoidSlotKey or slotKey ~= options.avoidSlotKey) and (not isSlotOccupied(slotKey) or candidate.occupiedByTestNpc == true) then
                    local accessBlockReason = candidateType == "sleeping" and sleepBedAccess.normalAssignmentBlockReason({
                        cell = player.cell,
                        candidate = candidate,
                        originPreferred = false,
                        initialPlacement = false,
                        debugForce = false,
                        helpers = {
                            objectModelPath = profiles.objectModelPath,
                            types = types,
                        },
                    }) or nil
                    if accessBlockReason then
                        candidate.manualAssignOverrideTesting = true
                        candidate.manualAssignOverrideReason = tostring(accessBlockReason)
                        candidate.sleepAccessOverrideReason = tostring(accessBlockReason)
                        debugLog("nearest_manual_assign_target_override_candidate", tostring(candidateType), tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "reason", tostring(accessBlockReason))
                    elseif candidateType == "sleeping" and sleepBedAccess.shouldRestrictDoorAssist(player.cell, false, false) then
                        candidate.disallowSleepDoorAssist = true
                    end
                        local dist = candidateDistanceToPlayer(candidate, player)
                        if dist <= targetRadius then
                            local typeBias = 0
                            if useTypeBias and #interactionTypes > 1 then
                                local bedBias = targetRadius <= 450 and -90 or -35
                                typeBias = candidateType == "sleeping" and bedBias or 0
                            end
                            local facingBias = useFacingBias and candidateFacingBonus(candidate, player) or 0
                            -- Manual assignment should mean the target physically closest to the
                            -- player. Keep only tiny deterministic tiebreakers after distance.
                            local score = dist + facingBias + typeBias + (typeIndex * 0.001)
                            if debugSelection then
                                debugLog(
                                    "nearest_manual_assign_target_candidate",
                                    "type", tostring(candidateType),
                                    "object", tostring(candidate.objectId),
                                    "slot", tostring(candidateSlotLabel(candidate)),
                                    "distance", tostring(dist),
                                    "facingBias", tostring(facingBias),
                                    "typeBias", tostring(typeBias),
                                    "score", tostring(score)
                                )
                            end
                            if not best or score < best.score then
                                best = {
                                    candidate = candidate,
                                    interactionType = candidateType,
                                    targetDistance = dist,
                                    score = score,
                                    facingBias = facingBias,
                                    typeBias = typeBias,
                                }
                            end
                        end
                elseif candidate and slotKey and isSlotOccupied(slotKey) then
                    debugLog("nearest_manual_assign_target_skipped", tostring(candidateType), tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "reason", "occupied_slot")
                end
            end
        end
        return best
    end

    local function spawnAndAssignCalibrationTestNpc(interactionType, player)
        local target = chooseNearestCandidateForPlayer(player, { interactionType }, {
            targetRadius = 1200,
            debugSelection = true,
        })
        if not target then
            local label = interactionType == "sleeping" and "bed" or "seat"
            return false, "No free " .. label .. " found near you. Stand closer to the furniture and try again."
        end

        local npc, spawnMessage = spawnCalibrationTestNpcNearPlayer(player)
        if not npc then return false, spawnMessage end

        local candidate = target.candidate
        candidate.calibrationAction = true
        candidate.calibrationReason = "developer_test_npc_target_first"
        candidate.ignoreTimeGate = true
        candidate.manualAssign = true
        candidate.manualAssignOverrideTesting = true
        candidate.calibrationTestNpc = true
        sendConsiderInteraction(npc, candidate)
        manualAssignment.logRouteStarted(infoLog, npc, candidate)
        rememberPendingCalibrationTarget(npc, candidate, "developer_test_npc_pending")
        infoLog("developer calibration test npc target-first assign", "ken", "type", tostring(interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "targetDistance", tostring(target.targetDistance))
        local label = interactionType == "sleeping" and "bed" or "seat"
        return true, spawnMessage .. " Sent him to the nearest " .. label .. " near you and made him the active calibration target.", {
            interactionType = interactionType,
            targetLabel = calibrationLock.sessionLabel(calibrationLock.session),
        }
    end

    local function actorDead(npc)
        local actorType = types and types.Actor or nil
        if not actorType then return false end
        if actorType.isDead then
            local ok, dead = pcall(actorType.isDead, npc)
            if ok and dead == true then return true end
        end
        if actorType.isDeathFinished then
            local ok, dead = pcall(actorType.isDeathFinished, npc)
            if ok and dead == true then return true end
        end
        return false
    end

    local function nearestManualInteractionTypes(filterMode)
        if filterMode == "sleeping" then return { "sleeping" } end
        if filterMode == "sitting" then return { "sitting" } end
        return { "sleeping", "sitting" }
    end

    local function noFreeTargetMessage(filterMode)
        if filterMode == "sleeping" then
            return "No free bed was found near you. Stand closer to the bed you want to test."
        end
        if filterMode == "sitting" then
            return "No free seat was found near you. Stand closer to the seat you want to test."
        end
        return "No free bed or seat was found near you. Stand closer to the furniture you want to test."
    end

    local function npcAlreadyAssigned(npc)
        local assignedActors = getAssignedActors()
        return npc and npc.id and assignedActors and assignedActors[npc.id] ~= nil
    end

    local MANUAL_ASSIGN_ELIGIBILITY_OVERRIDES = {
        barter_service_npc = true,
        trainer_service_npc = true,
        travel_service_npc = true,
        service_npc = true,
        guard_or_publican_class = true,
        publican_class = true,
        quest_npc = true,
        important_npc = true,
        high_rank_or_quest_npc = true,
    }

    local MANUAL_ASSIGN_HARD_REJECTS = {
        dead_actor = true,
        invalid_actor = true,
        already_assigned = true,
        follower = true,
        external_animation_npc = true,
        active_follow_or_escort_package = true,
        escort_or_follow_package = true,
    }

    local function manualNpcEligible(npc, interactionType, options)
        options = options or {}
        if not (npc and npc.id and isObjValid(npc) and npc.position) then return false, "invalid_actor" end
        if actorDead(npc) then return false, "dead_actor" end
        if npcAlreadyAssigned(npc) then
            local recordId = npc.recordId and string.lower(tostring(npc.recordId)) or ""
            if options.allowAssignedTestNpc == true and recordId == "ken" then
                return true, nil
            end
            return false, "already_assigned"
        end
        if isNpcEligibleForInteraction then
            local ok, allowed, reason = pcall(isNpcEligibleForInteraction, npc, interactionType)
            if not ok then return false, "eligibility_check_failed" end
            if allowed ~= true then
                reason = reason or "ineligible"
                if options.testingOverride == true and not MANUAL_ASSIGN_HARD_REJECTS[tostring(reason)] and MANUAL_ASSIGN_ELIGIBILITY_OVERRIDES[tostring(reason)] then
                    debugLog("nearest_manual_assign_eligibility_override", npc.recordId or npc.id, tostring(interactionType), "reason", tostring(reason))
                    return true, nil
                end
                return false, reason
            end
        end
        return true, nil
    end

    local function chooseNearestManualActor(player, npcs, interactionType, options)
        options = options or {}
        local scanRadius = tonumber(options.actorRadius or 1600) or 1600
        local best = nil
        for _, npc in ipairs(npcs or {}) do
            if npc ~= player and npc.position then
                local dist = (npc.position - player.position):length()
                if dist <= scanRadius then
                    local eligible, reason = manualNpcEligible(npc, interactionType, { testingOverride = true, allowAssignedTestNpc = true })
                    if eligible then
                        if not best or dist < best.distance then
                            best = { npc = npc, distance = dist }
                        end
                    else
                        if reason == "follower" or reason == "active_follow_or_escort_package" or reason == "dead_actor" then
                            debugLog("nearest_manual_assign_skip_actor", tostring(reason), npc.recordId or npc.id)
                        end
                        debugLog("nearest_manual_assign_skip_actor", tostring(reason), npc.recordId or npc.id, tostring(interactionType))
                    end
                end
            end
        end
        return best
    end

    local function assignNearestNpc(interactionType, player, options)
        options = options or {}
        if not (player and player.cell and player.position and player.cell.getAll) then
            infoLog("nearest_manual_assign_no_actor", "reason", "missing_player_cell")
            return false, "No player cell is available."
        end

        local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
        if not okList or not npcs then
            infoLog("nearest_manual_assign_no_actor", "reason", "npc_scan_failed")
            return false, "Could not scan NPCs near you."
        end

        local interactionTypes = nearestManualInteractionTypes(interactionType)
        local target = chooseNearestCandidateForPlayer(player, interactionTypes, {
            avoidSlotKey = options.avoidSlotKey,
            targetRadius = tonumber(options.targetRadius or 1200) or 1200,
            debugSelection = true,
        })

        if not target then
            infoLog("nearest_manual_assign_no_target", "filter", tostring(interactionType), "mode", "target_first")
            return false, noFreeTargetMessage(interactionType)
        end

        local actor = chooseNearestManualActor(player, npcs, target.interactionType, { actorRadius = tonumber(options.actorRadius or 1600) or 1600 })
        if not actor then
            infoLog("nearest_manual_assign_no_eligible_actor", "filter", tostring(target.interactionType), "mode", "target_first")
            return false, "Found nearby furniture, but no eligible standing NPC was close enough to use as the test actor."
        end

        local candidate = target.candidate
        if candidate.occupiedByTestNpc == true and candidate.occupiedByTestNpcActor then
            manualAssignment.cleanupBeforeReassign({
                getAssignedActors = getAssignedActors,
                stopInteractionForNpc = env.stopInteractionForNpc,
                infoLog = infoLog,
                debugLog = debugLog,
            }, candidate.occupiedByTestNpcActor, candidate, "manual_assign_retarget_test_npc_slot")
            candidate.occupiedByTestNpcActor:sendEvent("StopInteractionObject", { reason = "manual_assign_retarget_test_npc_slot", interactionType = candidate.occupiedByTestNpcInteractionType, forceClearSleepAnimation = true })
            debugLog("nearest_manual_assign_released_test_npc_slot", candidate.occupiedByTestNpcActor.recordId or candidate.occupiedByTestNpcActor.id, "slot", tostring(candidateSlotLabel(candidate)))
        end
        if npcAlreadyAssigned(actor.npc) and actor.npc.recordId and string.lower(tostring(actor.npc.recordId)) == "ken" then
            manualAssignment.cleanupBeforeReassign({
                getAssignedActors = getAssignedActors,
                stopInteractionForNpc = env.stopInteractionForNpc,
                infoLog = infoLog,
                debugLog = debugLog,
            }, actor.npc, candidate, "manual_assign_retarget_test_npc_actor")
            debugLog("nearest_manual_assign_released_assigned_test_npc", actor.npc.recordId or actor.npc.id)
        end
        candidate.manualAssign = true
        candidate.manualAssignRetryCount = tonumber(options.retryCount or 0) or 0
        candidate.ignoreTimeGate = true
        candidate.calibrationAction = true
        candidate.calibrationReason = "manual_assign_nearest_target_first_override"
        candidate.manualAssignOverrideTesting = true

        sendConsiderInteraction(actor.npc, candidate)
        manualAssignment.logRouteStarted(infoLog, actor.npc, candidate)
        rememberPendingCalibrationTarget(actor.npc, candidate, "manual_assign_pending")
        infoLog("nearest_manual_assign_target_chosen_player", "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "targetDistance", tostring(target.targetDistance), "score", tostring(target.score), "facingBias", tostring(target.facingBias), "typeBias", tostring(target.typeBias))
        infoLog("nearest_manual_assign_actor_chosen_player", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "npcDistance", tostring(actor.distance))
        infoLog("nearest_manual_assign_testing_override", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "bypass", "route_clearance_only")
        infoLog("nearest_manual_assign_pending_calibration_target", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)))
        infoLog("nearest_manual_assign_status", "sent", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "mode", "target_first")
        local label = target.interactionType == "sleeping" and "bed" or "seat"
        return true, "Sent " .. tostring(actor.npc.recordId or "nearest NPC") .. " to the nearest " .. label .. " near you. Waiting for result.", {
            interactionType = target.interactionType,
            targetLabel = calibrationLock.sessionLabel(calibrationLock.session),
        }
    end

    function M.onManualAssignTimeout(npc, candidate, reason)
        infoLog("nearest_manual_assign_timeout", npc and (npc.recordId or npc.id), "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidate.slotName), "reason", tostring(reason))
        infoLog("reassign_failed_timeout", npc and (npc.recordId or npc.id), "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidate.slotName), "reason", tostring(reason))
        infoLog("nearest_manual_assign_status", "timed out", npc and (npc.recordId or npc.id), "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId))
        infoLog("nearest_manual_assign_clear_pending_target", npc and (npc.recordId or npc.id), "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidate.slotName))
        calibrationLock.handleAction({ interactionType = candidate and candidate.interactionType or "auto", action = "clear" }, "manual_assign_timeout", calibrationContext())
        local message = candidate and candidate.calibrationTestNpc == true
            and "Spawn Test NPC did not get a local actor response; target cleared."
            or "Manual assignment did not get a local actor response; target cleared."
        for _, player in ipairs(world.players or {}) do
            sendCalibrationMenuStatus(player, message, {
                interactionType = candidate and candidate.interactionType,
                cleared = true,
            })
        end
    end

    function M.onManualAssignRejected(ev)
        local status = ev and ev.manualAssignOverrideTesting == true and "normal_play_blocker" or "failed"
        local message = ev and ev.manualAssignOverrideTesting == true
            and ("Assign Nearest normal-play blocker: " .. tostring(ev and ev.reason or "unknown"))
            or ("Assign Nearest could not complete: " .. tostring(ev and ev.reason or "unknown"))
        infoLog("nearest_manual_assign_status", status, ev and ev.npc and (ev.npc.recordId or ev.npc.id), "type", tostring(ev and ev.interactionType), "object", tostring(ev and ev.objectId), "slot", tostring(ev and ev.slotName), "reason", tostring(ev and ev.reason))
        for _, player in ipairs(world.players or {}) do
            sendCalibrationMenuStatus(player, message, {
                interactionType = ev and ev.interactionType,
            })
        end
        return true
    end

    function M.onCalibrationMenuAction(ev)
        local interactionType = ev and ev.interactionType
        local action = ev and ev.action
        local player = ev and ev.player
        local ctx = calibrationContext()
        if interactionType ~= "auto" and interactionType ~= "sleeping" and interactionType ~= "sitting" then
            infoLog("calibration menu action failed", tostring(action), "reason", "unsupported_interaction_type")
            sendCalibrationMenuStatus(player, "Use Auto, Bed, or Seat first.")
            return
        end
        if action == "capture" then
            local session = calibrationLock.captureTarget(interactionType, ctx, "menu_capture")
            sendCalibrationMenuStatus(
                player,
                session and ("Target found: " .. calibrationLock.sessionLabel(session)) or "No target found nearby. Stand near an NPC already sitting or sleeping, then try again.",
                session and { interactionType = session.interactionType, targetLabel = calibrationLock.sessionLabel(session) } or nil
            )
            sendCalibrationOffsetsForSession(player, session)
            return
        end
        if action == "spawn_test" then
            local spawnType = interactionType == "auto" and "sitting" or interactionType
            local _, message, status = spawnAndAssignCalibrationTestNpc(spawnType, player)
            sendCalibrationMenuStatus(player, message, status)
            return
        end
        if action == "assign_nearest" then
            local _, message, status = assignNearestNpc(interactionType, player)
            sendCalibrationMenuStatus(player, message, status)
            return
        end
        if action == "remove_test" then
            local _, message = removeCalibrationTestNpc("developer_menu", player)
            sendCalibrationMenuStatus(player, message)
            return
        end
        if action == "clear" then
            local session = calibrationLock.ensureSession(interactionType, ctx, "developer_menu_clear_target")
            local actor = session and session.actor or nil
            local recordId = actor and actor.recordId and string.lower(tostring(actor.recordId)) or ""
            if actor and actor.id then
                pcall(function()
                    actor:sendEvent("StopInteractionObject", {
                        reason = "developer_menu_clear_target",
                        interactionType = session and session.interactionType or interactionType,
                    })
                end)
                pcall(function()
                    actor:sendEvent("SitDownPleaseClearBriefTravel", { reason = "developer_menu_clear_target" })
                end)
            end
            if recordId == "ken" then
                removeCalibrationTestNpc("developer_menu_clear_target", player, { silent = true })
            elseif actor and actor.id then
                local assignedActors = getAssignedActors()
                local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
                if assignedActors and assignedActors[actor.id] and stopInteractionForNpc then
                    pcall(function() stopInteractionForNpc(actor, "developer_menu_clear_target") end)
                end
            end
            calibrationLock.handleAction({ interactionType = interactionType, action = "clear" }, "developer_menu_clear", ctx)
            sendCalibrationMenuStatus(player, "Target cleared.", { cleared = true })
            return
        end
        if action == "resume" or action == "reapply" or action == "reenter" or action == "send" then
            local session = calibrationLock.handleAction({ interactionType = interactionType, action = action }, "developer_menu_" .. tostring(action), ctx)
            sendCalibrationMenuStatus(
                player,
                action == "resume" and "Asked the target to sit or lie down again." or (action == "reapply" and "Position reapplied." or "Sent the NPC back to the same furniture."),
                session and { interactionType = session.interactionType, targetLabel = calibrationLock.sessionLabel(session) } or nil
            )
            sendCalibrationOffsetsForSession(player, session)
            return
        end

        local session = calibrationLock.ensureSession(interactionType, ctx, "menu_" .. tostring(action))
        if not session then
            infoLog("calibration menu action failed", tostring(action), tostring(interactionType), "reason", "no_current_calibration_target")
            sendCalibrationMenuStatus(player, "No target selected. Click Find Target first.")
            return
        end
        local effectiveType = session.interactionType or interactionType
        if action == "print" then
            session.actor:sendEvent(effectiveType == "sleeping" and "SitDownPleasePrintSleepCalibration" or "SitDownPleasePrintSittingCalibration", { reason = "developer_menu" })
            sendCalibrationMenuStatus(player, "Profile line printed to openmw.log for " .. calibrationLock.sessionLabel(session) .. ".", { interactionType = effectiveType, targetLabel = calibrationLock.sessionLabel(session) })
            return
        end
        if action == "reset" then
            session.actor:sendEvent(effectiveType == "sleeping" and "SitDownPleaseResetSleepCalibration" or "SitDownPleaseResetSittingCalibration", { reason = "developer_menu" })
            sendCalibrationMenuStatus(player, "Reset to saved profile for " .. calibrationLock.sessionLabel(session) .. ".", { interactionType = effectiveType, targetLabel = calibrationLock.sessionLabel(session) })
            return
        end
        if action == "nudge" then
            session.actor:sendEvent(effectiveType == "sleeping" and "SitDownPleaseNudgeSleepCalibration" or "SitDownPleaseNudgeSittingCalibration", {
                x = ev.x,
                y = ev.y,
                z = ev.z,
                yaw = ev.yaw,
                reason = "developer_menu",
            })
            sendCalibrationMenuStatus(player, "Position changed for " .. calibrationLock.sessionLabel(session) .. ".", { interactionType = effectiveType, targetLabel = calibrationLock.sessionLabel(session) })
            return
        end
        infoLog("calibration menu action failed", tostring(action), tostring(interactionType), "reason", "unsupported_action")
        sendCalibrationMenuStatus(player, "That calibration button is not supported in this build: " .. tostring(action))
    end

    M.removeCalibrationTestNpc = removeCalibrationTestNpc
    return M
end

return module
