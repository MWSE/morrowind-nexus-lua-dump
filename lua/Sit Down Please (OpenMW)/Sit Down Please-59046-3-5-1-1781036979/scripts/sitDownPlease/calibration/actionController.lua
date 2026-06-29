---@omw-context none
local module = {}
local assignmentEligibility = require('scripts/sitDownPlease/assignment/eligibility')
local manualAssignment = require('scripts/sitDownPlease/assignment/manualAssignment')
local originTracker = require('scripts/sitDownPlease/assignment/originTracker')
local sleepBedAccess = require('scripts/sitDownPlease/interactions/sleeping/bedAccess')
local calibrationExport = require('scripts/sitDownPlease/calibration/exportRows')
local sleepCalibrationWarnings = require('scripts/sitDownPlease/interactions/sleeping/calibrationWarnings')
local sittingStandExit = require('scripts/sitDownPlease/interactions/sitting/standExit')
local lectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')
local calibrationTestActors = require('scripts/sitDownPlease/calibration/testActors')
local focusMetadata = require('scripts/sitDownPlease/calibration/focusMetadata')

local function noSlotOccupied(...)
    return false
end

local function noStationSlotOccupied(...)
    return false, false
end

function module.create(env)
    local M = {}

    local world = assert(env.world, "calibrationMenu.create requires env.world")
    local core = assert(env.core, "calibrationMenu.create requires env.core")
    local types = assert(env.types, "calibrationMenu.create requires env.types")
    local util = assert(env.util, "calibrationMenu.create requires env.util")
    local storage = env.storage
    local profiles = assert(env.profiles, "calibrationMenu.create requires env.profiles")
    local settings = env.settings or {}
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
    local isSlotOccupied = env.isSlotOccupied or noSlotOccupied
    local isNpcEligibleForInteraction = env.isNpcEligibleForInteraction
    local triggerStationLecture = env.triggerStationLecture
    local claimStationWithNpc = env.claimStationWithNpc
    local releaseStationForNpc = env.releaseStationForNpc
    local applyStationCalibration = env.applyStationCalibration
    local stationSlotKey = env.stationSlotKey
    local stationSlotOccupied = env.stationSlotOccupied or noStationSlotOccupied
    local stationDataForNpc = env.stationDataForNpc
    local claimedStationData = env.claimedStationData
    local releaseSafetyGate = env.releaseSafetyGate

    local calibrationTestNpc = nil
    local calibrationTestNpcs = {}
    local calibrationFillActors = {}
    local pendingBorrowedFillTargets = {}
    local calibrationActorIdentities = {}
    local FILL_FURNITURE_MAX_ACTORS = 96
    local FILL_FURNITURE_BORROW_EXISTING_ACTORS = false
    local CALIBRATION_TEST_NPC_RECORDS = calibrationTestActors.records
    local CALIBRATION_FILL_LEDGER_SECTION = "SitDownPleaseCalibrationFill"
    local CALIBRATION_FILL_LEDGER_KEY = "actors"
    local calibrationTestSpawnIndex = 0
    local calibrationTestIdentityIndex = 0
    local calibrationFillIdentityIndex = 0
    local calibrationFillSessionIndex = 0
    local calibrationFillSessionId = nil
    local calibrationFillLedgerSection = nil
    local readCalibrationFillLedger

    local normalizedRecordId = calibrationTestActors.normalizedRecordId

    local function isCalibrationTestNpcRecord(recordId)
        return calibrationTestActors.isTestRecord(recordId)
    end

    local function calibrationTestNpcName(recordId)
        return calibrationTestActors.recordLabel(recordId)
    end

    local function calibrationActorBaseLabel(actor)
        return calibrationTestActors.actorBaseLabel(actor)
    end

    local function twoDigit(index)
        return string.format("%02d", tonumber(index or 0) or 0)
    end

    local function calibrationActorDisplayLabel(base, suffix)
        return tostring(base or "test NPC") .. " - " .. tostring(suffix or "Fill")
    end

    local function readableCalibrationActorLabel(label)
        local text = tostring(label or "")
        text = text:gsub("%s*%[Fill #%s*(%d+)%]", " - Fill %1")
        text = text:gsub("%s*%[Test #%s*(%d+)%]", " - Test %1")
        text = text:gsub("%s*%[borrowed%]", " - borrowed")
        return text
    end

    local fillIdentityForActor

    local function actorRuntimeObjectId(actor)
        local raw = actor and actor.id and tostring(actor.id) or nil
        if not raw or raw == "" then return nil end
        raw = raw:gsub("^L?@?0x", "")
        if #raw > 8 then raw = raw:sub(-8) end
        return raw
    end

    local function markCleanedCalibrationActor(cleanedActors, id, actor, identity)
        if not cleanedActors then return end
        local function mark(value)
            if value ~= nil then cleanedActors[tostring(value)] = true end
        end
        mark(id)
        if actor then
            if cleanedActors.objects then cleanedActors.objects[actor] = true end
            mark(actor.id)
            mark(actorRuntimeObjectId(actor))
        end
        if identity then
            mark(identity.runtimeObjectId)
            mark(identity.label)
        end
    end

    local function cleanedCalibrationActor(cleanedActors, id, actor)
        if not cleanedActors then return false end
        if actor and cleanedActors.objects and cleanedActors.objects[actor] == true then return true end
        local function marked(value)
            return value ~= nil and cleanedActors[tostring(value)] == true
        end
        if marked(id) then return true end
        if actor and (marked(actor.id) or marked(actorRuntimeObjectId(actor))) then return true end
        local identity = actor and fillIdentityForActor(actor) or nil
        return identity and (marked(identity.runtimeObjectId) or marked(identity.label)) or false
    end

    fillIdentityForActor = function(actor)
        if not (actor and actor.id) then return nil end
        local key = tostring(actor.id)
        local identity = calibrationActorIdentities[key]
        if identity then return identity end
        local records = readCalibrationFillLedger()
        local record = records[key]
        if type(record) == "table" and record.fillLabel then
            identity = {
                label = readableCalibrationActorLabel(record.fillLabel),
                role = record.fillRole,
                source = record.fillSource,
                index = record.fillIndex,
                sessionId = record.fillSessionId,
                runtimeObjectId = actorRuntimeObjectId(actor),
            }
            calibrationActorIdentities[key] = identity
            return identity
        end
        return nil
    end

    local function assignCalibrationActorIdentity(actor, role, spawned)
        if not (actor and actor.id) then return nil end
        local key = tostring(actor.id)
        local existing = calibrationActorIdentities[key]
        if existing then return existing end
        role = tostring(role or "fill")
        local source = spawned == true and "generated" or "borrowed"
        local index
        local suffix
        if role == "test" then
            calibrationTestIdentityIndex = calibrationTestIdentityIndex + 1
            index = calibrationTestIdentityIndex
            suffix = "Test " .. twoDigit(index)
        elseif source == "generated" then
            calibrationFillIdentityIndex = calibrationFillIdentityIndex + 1
            index = calibrationFillIdentityIndex
            suffix = "Fill " .. twoDigit(index)
        else
            suffix = "borrowed"
        end
        local identity = {
            label = calibrationActorDisplayLabel(calibrationActorBaseLabel(actor), suffix),
            role = role,
            source = source,
            index = index,
            sessionId = calibrationFillSessionId,
            runtimeObjectId = actorRuntimeObjectId(actor),
        }
        calibrationActorIdentities[key] = identity
        return identity
    end

    local function applyCalibrationActorIdentity(payload, actor)
        local identity = fillIdentityForActor(actor)
        if not (payload and identity) then return payload end
        payload.calibrationFillLabel = identity.label
        payload.calibrationFillRole = identity.role
        payload.calibrationFillSource = identity.source
        payload.calibrationFillIndex = identity.index
        payload.calibrationFillSessionId = identity.sessionId
        payload.calibrationRuntimeObjectId = identity.runtimeObjectId
        if identity.source ~= "borrowed" then
            payload.actorDisplayLabel = identity.label
        end
        return payload
    end

    local function nextCalibrationFillRecordId()
        calibrationTestSpawnIndex = calibrationTestSpawnIndex + 1
        local index = ((calibrationTestSpawnIndex - 1) % #CALIBRATION_TEST_NPC_RECORDS) + 1
        return CALIBRATION_TEST_NPC_RECORDS[index]
    end

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

    local function resolveCalibrationPlayer(player)
        if player and player.cell and player.position then return player end
        for _, candidate in ipairs(world.players or {}) do
            if candidate and candidate.cell and candidate.position then
                return candidate
            end
        end
        return player
    end

    local function calibrationFillLedger()
        if calibrationFillLedgerSection ~= nil then
            return calibrationFillLedgerSection ~= false and calibrationFillLedgerSection or nil
        end
        if not (storage and storage.globalSection) then
            calibrationFillLedgerSection = false
            return nil
        end
        local ok, section = pcall(function() return storage.globalSection(CALIBRATION_FILL_LEDGER_SECTION) end)
        if not (ok and section) then
            calibrationFillLedgerSection = false
            return nil
        end
        calibrationFillLedgerSection = section
        if section.setLifeTime and storage.LIFE_TIME then
            local lifetime = storage.LIFE_TIME.GameSession or storage.LIFE_TIME.Temporary
            if lifetime ~= nil then
                pcall(function() section:setLifeTime(lifetime) end)
            end
        elseif section.removeOnExit then
            pcall(function() section:removeOnExit() end)
        end
        return section
    end

    function readCalibrationFillLedger()
        local section = calibrationFillLedger()
        if not section then return {} end
        local ok, value = pcall(function()
            if section.getCopy then return section:getCopy(CALIBRATION_FILL_LEDGER_KEY) end
            return section:get(CALIBRATION_FILL_LEDGER_KEY)
        end)
        if ok and type(value) == "table" then return value end
        return {}
    end

    local function writeCalibrationFillLedger(records)
        local section = calibrationFillLedger()
        if not (section and section.set) then return end
        pcall(function() section:set(CALIBRATION_FILL_LEDGER_KEY, records or {}) end)
    end

    local function actorLedgerKey(actor)
        return actor and actor.id and tostring(actor.id) or nil
    end

    local function rememberCalibrationFillLedger(actor, target, spawned, identity)
        local key = actorLedgerKey(actor)
        if not key then return end
        local candidate = target and target.candidate or nil
        identity = identity or fillIdentityForActor(actor)
        local records = readCalibrationFillLedger()
        records[key] = {
            actorId = key,
            actorRecordId = actor.recordId and tostring(actor.recordId) or nil,
            cellName = actor.cell and cellName(actor.cell) or nil,
            interactionType = target and target.interactionType or candidate and candidate.interactionType or nil,
            objectId = candidate and candidate.objectId or candidate and candidate.object and candidate.object.recordId or nil,
            slotKey = candidate and candidate.slotKey or nil,
            slotName = candidate and candidate.slotName or nil,
            generated = spawned == true,
            fillLabel = identity and identity.label or nil,
            fillRole = identity and identity.role or nil,
            fillSource = identity and identity.source or (spawned == true and "generated" or "borrowed"),
            fillIndex = identity and identity.index or nil,
            fillSessionId = identity and identity.sessionId or calibrationFillSessionId,
            runtimeObjectId = identity and identity.runtimeObjectId or actorRuntimeObjectId(actor),
            origin = originTracker.saveVector(actor.position),
            originYaw = originTracker.saveRotationYaw(actor.rotation),
        }
        writeCalibrationFillLedger(records)
    end

    local function forgetCalibrationFillLedgerActor(actorOrId)
        local key = type(actorOrId) == "string" and actorOrId or actorLedgerKey(actorOrId)
        if not key then return end
        local records = readCalibrationFillLedger()
        if records[key] ~= nil then
            records[key] = nil
            writeCalibrationFillLedger(records)
        end
        calibrationActorIdentities[key] = nil
    end

    local function currentCellFillLedgerActors(player)
        local found = {}
        local records = readCalibrationFillLedger()
        if next(records) == nil then return found, records end
        local scanPlayer = player or (world.players and world.players[1]) or nil
        if not (scanPlayer and scanPlayer.cell and scanPlayer.cell.getAll) then return found, records end
        local okList, npcs = pcall(function() return scanPlayer.cell:getAll(types.NPC) end)
        if not (okList and npcs) then return found, records end
        local currentCellName = cellName(scanPlayer.cell)
        for _, candidate in ipairs(npcs) do
            local key = actorLedgerKey(candidate)
            local record = key and records[key] or nil
            if record and isObjValid(candidate) and candidate ~= scanPlayer then
                if not record.cellName or not currentCellName or tostring(record.cellName) == tostring(currentCellName) then
                    found[#found + 1] = { actor = candidate, record = record, key = key }
                end
            end
        end
        return found, records
    end

    local function calibrationFillOrTestExists(player)
        if isObjValid(calibrationTestNpc) then return true end
        for id, npc in pairs(calibrationTestNpcs) do
            if isObjValid(npc) then return true end
            calibrationTestNpcs[id] = nil
        end
        for id, actor in pairs(calibrationFillActors) do
            if isObjValid(actor) then return true end
            calibrationFillActors[id] = nil
        end
        for _, item in ipairs(currentCellFillLedgerActors(player)) do
            if item.actor and isObjValid(item.actor) then return true end
        end
        for _, data in pairs(getAssignedActors() or {}) do
            if data and (data.calibrationFill == true or data.calibrationTestNpc == true) then
                local actor = data.npc or data.actor
                if actor and isObjValid(actor) then return true end
            end
        end
        return false
    end

    local function sendCalibrationMenuStatus(player, message, extra)
        if not player then return end
        local payload = type(extra) == "table" and profiles.shallowCopy(extra) or {}
        payload.message = message
        if payload.fillOrTestExists == nil then
            payload.fillOrTestExists = calibrationFillOrTestExists(player)
        end
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

    local function calibrationOffsetUnchanged(cal)
        cal = cal or {}
        return math.abs(tonumber(cal.x) or 0) < 0.001
            and math.abs(tonumber(cal.y) or 0) < 0.001
            and math.abs(tonumber(cal.z) or 0) < 0.001
            and math.abs(tonumber(cal.yaw) or 0) < 0.001
    end

    local currentAssignmentForSession

    local function sessionHasPrintEvidenceContext(session)
        if not session then return false end
        return session.calibrationFill == true
            or session.calibrationTestNpc == true
            or session.explicitFillOverride == true
            or session.testingOverride == true
            or session.manualAssignOverrideApplied == true
            or session.calibrationFillLabel ~= nil
            or session.calibrationFillSource ~= nil
            or session.calibrationFillIndex ~= nil
            or session.calibrationRuntimeObjectId ~= nil
            or session.actorDisplayLabel ~= nil
    end

    local function sessionIsFillOrTest(session)
        if not session then return false end
        if session.calibrationFill == true
            or session.calibrationTestNpc == true
            or session.calibrationFillLabel ~= nil
            or session.calibrationFillSessionId ~= nil then
            return true
        end
        local assignment = currentAssignmentForSession(session)
        return assignment ~= nil and (assignment.calibrationFill == true or assignment.calibrationTestNpc == true)
    end

    local function offsetNonZero(offset)
        if not offset then return false end
        return math.abs(tonumber(offset.x) or 0) > 0.001
            or math.abs(tonumber(offset.y) or 0) > 0.001
            or math.abs(tonumber(offset.z) or 0) > 0.001
            or math.abs(tonumber(offset.yaw) or 0) > 0.001
    end

    local function addUniqueLine(lines, seen, text)
        text = tostring(text or "")
        if text == "" or seen[text] then return end
        seen[text] = true
        lines[#lines + 1] = text
    end

    local function defaultProfileFile(session)
        if not session then return "" end
        if session.interactionType == "station" then return "furnitureProfiles/sdp/global/stationProfiles.txt" end
        if session.interactionType == "sleeping" then return "furnitureProfiles/sdp/global/bedProfiles.txt" end
        if session.interactionType == "sitting" then return "furnitureProfiles/sdp/global/chairProfiles.txt" end
        return ""
    end

    local function defaultVariantFile(session)
        if not session then return "" end
        if session.interactionType == "station" then return "furnitureProfiles/sdp/global/stationProfileVariants.txt" end
        if session.interactionType == "sleeping" then return "furnitureProfiles/sdp/global/bedProfileVariants.txt" end
        if session.interactionType == "sitting" then return "furnitureProfiles/sdp/global/chairProfileVariants.txt" end
        return ""
    end

    local function scopeValue(scope, key)
        local marker = key .. "="
        local start = scope:find(marker, 1, true)
        if not start then return "" end
        start = start + #marker
        local stop = #scope + 1
        for _, nextMarker in ipairs({ " place=", " cell=", " cellPrefix=", " region=" }) do
            local nextStart = scope:find(nextMarker, start, true)
            if nextStart and nextStart < stop then stop = nextStart end
        end
        return scope:sub(start, stop - 1)
    end

    local function titleScopeText(text)
        text = tostring(text or ""):gsub("_", " "):gsub(";", ", ")
        return (text:gsub("(%a)([%w']*)", function(first, rest)
            return first:upper() .. rest
        end))
    end

    local function readableScopeLabel(scopeLabel)
        local scope = tostring(scopeLabel or "")
        if scope == "" or scope == "nil" then return "" end
        local exactCell = scopeValue(scope, "cell")
        if exactCell ~= "" then return titleScopeText(exactCell) .. " only" end
        local cellPrefix = scopeValue(scope, "cellPrefix")
        if cellPrefix ~= "" then return titleScopeText(cellPrefix) .. " only" end
        local place = scopeValue(scope, "place")
        if place ~= "" then return titleScopeText(place) .. " place" end
        local region = scopeValue(scope, "region")
        if region ~= "" then return titleScopeText(region) .. " region" end
        return "scoped"
    end

    local function displayProfilePath(path, scopeLabel)
        local text = tostring(path or "")
        if text == "" or text == "nil" then return "" end
        text = text:gsub("\\", "/")
        local rootPath = text:match("furnitureProfiles/(.+)$")
        local placePath = rootPath and rootPath:match("(.*/places/.+)$") or text:match("^places/(.+)$")
        local sharedPath = rootPath and rootPath:match("(.*/shared/.+)$") or text:match("^(shared/.+)$")
        local globalPath = rootPath and rootPath:match("(.*/global/.+)$") or text:match("^(global/.+)$")
        local fileName = text:match("([^/]+)$") or text
        text = rootPath or (placePath and ("places/" .. placePath) or sharedPath or globalPath or fileName)
        if text:sub(1, 1) ~= "/" then text = "/" .. text end
        local scope = tostring(scopeLabel or "")
        local pathShowsScope = rootPath ~= nil or placePath ~= nil or sharedPath ~= nil or globalPath ~= nil
        if scope ~= "" and scope ~= "nil" and not pathShowsScope then
            text = text .. " (" .. readableScopeLabel(scope) .. ")"
        end
        return text
    end

    local function firstNonEmpty(...)
        for i = 1, select("#", ...) do
            local text = tostring(select(i, ...) or "")
            if text ~= "" and text ~= "nil" then return text end
        end
        return ""
    end

    local function sourceFileForSession(session, profile, trace)
        local sourceName = firstNonEmpty(trace and trace.sourceName, profile and profile.sourceName)
        if sourceName ~= "" then return sourceName end
        local sourceText = tostring(session and session.profileSelectionSource or profile and profile.profileSelectionSource or "")
        if sourceText == "explicit_profile"
            or sourceText == "built_in_profile"
            or sourceText == "explicit_profile_orientation_variant"
            or sourceText == "explicit_chair_orientation_variant"
            or sourceText == "explicit_station_orientation_variant" then
            return defaultProfileFile(session)
        end
        if firstNonEmpty(
            profile and profile.orientationVariantSource,
            profile and profile.chairOrientationVariantSource,
            profile and profile.stationOrientationVariantSource,
            trace and trace.orientationVariantSource,
            trace and trace.chairVariantSource,
            trace and trace.stationVariantSource
        ) ~= "" then
            return defaultProfileFile(session)
        end
        return ""
    end

    local function variantFileForSession(session, profile, trace)
        local variantSource = firstNonEmpty(
            trace and trace.variantSource,
            profile and profile.orientationVariant and profile.orientationVariant.sourceName,
            profile and profile.chairOrientationVariant and profile.chairOrientationVariant.sourceName,
            profile and profile.stationOrientationVariant and profile.stationOrientationVariant.sourceName
        )
        if variantSource ~= "" then return variantSource end
        local hasVariant = firstNonEmpty(
            profile and profile.orientationVariantSource,
            profile and profile.chairOrientationVariantSource,
            profile and profile.stationOrientationVariantSource,
            trace and trace.orientationVariantSource,
            trace and trace.chairVariantSource,
            trace and trace.stationVariantSource
        ) ~= ""
        if hasVariant then return defaultVariantFile(session) end
        return ""
    end

    local function profileDisplayForSession(session, source)
        if not session then return "", false end
        local profile = session.profile or {}
        local trace = session.profileSelectionTrace or profile.profileSelectionTrace or {}
        local sourceText = tostring(session.profileSelectionSource or profile.profileSelectionSource or "")
        local fallback = profile.isFallback == true
            or profile.profileBedTypeFallback ~= nil
            or sourceText:find("fallback", 1, true) ~= nil
            or sourceText == "bed_type_average"
            or sourceText == "bed_type_average_low_confidence"
            or sourceText == "bed_type_average_alias"
        local lines, seen = {}, {}
        if fallback then
            local fallbackLabel = "Generated fallback"
            if sourceText == "bed_type_average" then fallbackLabel = "Fallback average" end
            if sourceText == "bed_type_average_low_confidence" then fallbackLabel = "Low-confidence fallback average" end
            addUniqueLine(lines, seen, fallbackLabel)
        else
            addUniqueLine(lines, seen, displayProfilePath(sourceFileForSession(session, profile, trace), trace and trace.scope))
        end
        local variantFile = variantFileForSession(session, profile, trace)
        if variantFile ~= "" then
            addUniqueLine(lines, seen, displayProfilePath(variantFile, trace and trace.variantScope))
        end
        source = source or session
        if offsetNonZero(source and (source.animationOffset or source.animationNormalizationOffset)) then
            addUniqueLine(lines, seen, displayProfilePath("furnitureProfiles/sdp/global/animationNormalizationOffsets.txt", ""))
        end
        if #lines == 0 then addUniqueLine(lines, seen, defaultProfileFile(session) ~= "" and displayProfilePath(defaultProfileFile(session), "") or "Profile loaded") end
        return table.concat(lines, "\n"), fallback
    end

    currentAssignmentForSession = function(session)
        local actor = session and (session.actor or session.npc) or nil
        if not (actor and actor.id) then return nil end
        local assignedActors = getAssignedActors()
        local data = assignedActors and assignedActors[actor.id] or nil
        if not (data and data.interactionType == session.interactionType and data.slotKey == session.slotKey) then return nil end
        local dataObjectId = data.objectId or (data.object and data.object.recordId)
        if tostring(dataObjectId or "") ~= tostring(session.objectRecordId or "") then return nil end
        return data
    end

    local function currentActorAssignmentForSession(session)
        local actor = session and (session.actor or session.npc) or nil
        if not (actor and actor.id) then return nil end
        local assignedActors = getAssignedActors()
        local data = assignedActors and assignedActors[actor.id] or nil
        if data and data.interactionType == session.interactionType then return data end
        return nil
    end

    local releaseSafetyGateFields

    local function objectContentFile(obj)
        local value = obj and obj.contentFile or nil
        if value == nil or tostring(value) == "" then return nil end
        return tostring(value)
    end

    local function displayContentFile(obj)
        return objectContentFile(obj) or (obj and "dynamic / unknown" or nil)
    end

    local function objectModelPath(obj)
        local value = profiles.objectModelPath and profiles.objectModelPath(obj) or nil
        if value == nil or tostring(value) == "" then
            local ok, rec = pcall(function()
                if obj and obj.type and obj.type.record then return obj.type.record(obj) end
                return nil
            end)
            if ok and rec and rec.model then value = rec.model end
        end
        if value == nil or tostring(value) == "" then return nil end
        return tostring(value)
    end

    local function sessionStatusPayload(session, extra)
        if not session then return extra end
        local assignment = currentAssignmentForSession(session)
        local source = assignment or session
        local sourceActor = source.actor or source.npc or session.actor or session.npc
        local sourceObject = source.object or session.object
        local profileDisplay, fallback = profileDisplayForSession(session, source)
        local payload = type(extra) == "table" and profiles.shallowCopy(extra) or {}
        payload.interactionType = session.interactionType
        payload.targetLabel = calibrationLock.sessionLabel(session)
        payload.profileDisplay = profileDisplay
        payload.profileIsFallback = fallback
        payload.calibrationFillLabel = source.calibrationFillLabel
        payload.calibrationFillRole = source.calibrationFillRole
        payload.calibrationFillSource = source.calibrationFillSource
        payload.calibrationFillIndex = source.calibrationFillIndex
        payload.calibrationFillSessionId = source.calibrationFillSessionId
        payload.calibrationRuntimeObjectId = source.calibrationRuntimeObjectId
        payload.lectureAudienceTarget = source.lectureAudienceTarget == true
        payload.lectureAudienceSource = source.lectureAudienceSource
        payload.lectureAudienceSessionId = source.lectureAudienceSessionId
        payload.manualOverride = source.manualAssignOverrideApplied == true
        payload.manualOverrideReason = source.manualAssignOverrideReason
        payload.surfaceBlockerReason = source.surfaceBlockerReason
        payload.surfaceBlockerOverrideReason = source.surfaceBlockerOverrideReason
        payload.surfaceBlockerKind = source.surfaceBlockerKind
        payload.surfaceBlockerObjectId = source.surfaceBlockerObjectId
        payload.surfaceBlockerDistance = source.surfaceBlockerDistance
        payload.surfaceBlockerVertical = source.surfaceBlockerVertical
        payload.surfaceBlockerLocalReason = source.surfaceBlockerLocalReason
        payload.softBlockerReason = source.softBlockerReason
        payload.hardBlockerReason = source.hardBlockerReason
        payload.sleepSafetyReason = source.sleepSafetyReason
        payload.sleepSafetyDelta = source.sleepSafetyDelta
        payload.sleepSafetyLimit = source.sleepSafetyLimit
        payload.sleepSafetyOverrideReason = source.sleepSafetyOverrideReason
        payload.sleepSafetyRepairReason = source.sleepSafetyRepairReason
        payload.sleepSafetyRepairDelta = source.sleepSafetyRepairDelta
        payload.sleepSafetyRepairLimit = source.sleepSafetyRepairLimit
        payload.sleepCalibrationWarningReason = source.sleepCalibrationWarningReason
        payload.sleepAccessOverrideReason = source.sleepAccessOverrideReason
        payload.rejectionReason = source.rejectionReason
        payload.releaseSafetyGateEnabled = source.releaseSafetyGateEnabled
        payload.releaseSafetyGateStatus = source.releaseSafetyGateStatus
        payload.releaseSafetyGateReason = source.releaseSafetyGateReason
        payload.releaseSafetyGateCell = source.releaseSafetyGateCell
        payload.releaseSafetyGateRegion = source.releaseSafetyGateRegion
        payload.releaseSafetyGateFurnitureType = source.releaseSafetyGateFurnitureType
        payload.releaseSafetyGateLabel = source.releaseSafetyGateLabel
        payload.externalPhysicalClaimed = source.externalPhysicalClaimed == true
        payload.externalPhysicalClaimReason = source.externalPhysicalClaimReason
        payload.externalPhysicalClaimActorRecordId = source.externalPhysicalClaimActorRecordId
        payload.externalPhysicalClaimActorId = source.externalPhysicalClaimActorId
        payload.facingObjectId = source.facingObjectId
        payload.facingObjectRefId = source.facingObjectRefId
        payload.facingObjectModel = source.facingObjectModel
        payload.facingObjectName = source.facingObjectName
        payload.facingObjectScale = source.facingObjectScale
        payload.facingObjectContentFile = source.facingObjectContentFile or displayContentFile(source.facingObject)
        payload.facingObjectDistance = source.facingObjectDistance
        if source.facingObject and source.facingObject.position and sourceActor and sourceActor.position then
            local dx = (source.facingObject.position.x or 0) - (sourceActor.position.x or 0)
            local dy = (source.facingObject.position.y or 0) - (sourceActor.position.y or 0)
            payload.facingObjectDistance = math.sqrt(dx * dx + dy * dy)
        end
        payload.facingKind = source.facingKind
        payload.facingReason = source.facingReason
        payload.facingSurfaceSource = source.facingSurfaceSource
        payload.facingSurfaceHit = source.facingSurfaceHit == true
        payload.facingCandidates = focusMetadata.sanitizeCandidates(source.facingCandidates, 8)
        payload.ignoredFacingObjectId = source.ignoredFacingObjectId
        payload.ignoredFacingObjectRefId = source.ignoredFacingObjectRefId
        payload.ignoredFacingObjectModel = source.ignoredFacingObjectModel
        payload.ignoredFacingObjectName = source.ignoredFacingObjectName
        payload.ignoredFacingObjectScale = source.ignoredFacingObjectScale
        payload.ignoredFacingObjectContentFile = source.ignoredFacingObjectContentFile or displayContentFile(source.ignoredFacingObject)
        payload.ignoredFacingObjectDistance = source.ignoredFacingObjectDistance
        payload.ignoredFacingKind = source.ignoredFacingKind
        payload.ignoredFacingSurfaceSource = source.ignoredFacingSurfaceSource
        payload.ignoredFacingSurfaceHit = source.ignoredFacingSurfaceHit == true
        payload.ignoredFacingFocusDot = source.ignoredFacingFocusDot
        payload.ignoredFacingCandidates = focusMetadata.sanitizeCandidates(source.ignoredFacingCandidates, 8)
        payload.tableClearanceFocusCleared = source.tableClearanceFocusCleared == true
        payload.tableClearanceFocusClearReason = source.tableClearanceFocusClearReason
        payload.actorScale = sourceActor and sourceActor.scale
        payload.objectScale = sourceObject and sourceObject.scale
        payload.sdpOwnedAssignment = session.interactionType == "station" or assignment ~= nil
        payload.nudgeEnabled = sourceObject ~= nil
            and (
                (sourceActor ~= nil and (session.interactionType == "sitting" or session.interactionType == "sleeping"))
                or session.interactionType == "station"
            )
            and source.externalPhysicalClaimed ~= true
            and session.externalPhysicalClaimed ~= true
        payload.actorContentFile = displayContentFile(sourceActor)
        payload.objectContentFile = displayContentFile(sourceObject)
        payload.objectModelPath = source.model or objectModelPath(sourceObject)
        if payload.releaseSafetyGateEnabled == nil and sourceObject then
            local gate = releaseSafetyGateFields(session.interactionType, sourceObject.cell, source.profile, sourceObject, {
                calibrationAction = true,
                profile = source.profile,
                object = sourceObject,
                seatCategory = source.profile and (source.profile.seatCategory or source.profile.type) or nil,
            })
            for key, value in pairs(gate) do payload[key] = value end
        end
        return payload
    end

    local function manualAssignStatusExtra(actor, extra)
        local payload = type(extra) == "table" and profiles.shallowCopy(extra) or {}
        if actor and actor.manualAssignOverrideReason then
            payload.testingOverride = true
            payload.testingOverrideReason = actor.manualAssignOverrideReason
        end
        return payload
    end

    local function sendCalibrationOffsetsForSession(player, session)
        if not (player and session and (session.interactionType == "sitting" or session.interactionType == "sleeping" or session.interactionType == "station")) then return end
        local assignment = currentAssignmentForSession(session)
        local source = assignment or session
        local payload = sessionStatusPayload(session, { replaceTarget = true }) or {}
        payload.profileOffset = source.profileOffset or zeroCalibrationOffset()
        payload.animationOffset = source.animationOffset or zeroCalibrationOffset()
        payload.calibration = source.calibration or zeroCalibrationOffset()
        payload.animation = source.animationName or source.animation
        pcall(function()
            player:sendEvent("SitDownPleaseCalibrationOffsets", payload)
        end)
    end

    local function lookTargetActorKind(lookTarget)
        if not lookTarget then return false end
        if types.NPC and types.NPC.objectIsInstance then
            local ok, value = pcall(types.NPC.objectIsInstance, lookTarget)
            if ok and value == true then return true end
        end
        if types.Creature and types.Creature.objectIsInstance then
            local ok, value = pcall(types.Creature.objectIsInstance, lookTarget)
            if ok and value == true then return true end
        end
        return false
    end

    local function lookTargetFurnitureKind(lookTarget)
        if not lookTarget then return false end
        local recordId = lookTarget.recordId and string.lower(tostring(lookTarget.recordId)) or ""
        local model = profiles.objectModelPath and string.lower(tostring(profiles.objectModelPath(lookTarget) or "")) or ""
        local text = recordId .. " " .. model
        return text:find("furn", 1, true) ~= nil
            or text:find("chair", 1, true) ~= nil
            or text:find("bench", 1, true) ~= nil
            or text:find("stool", 1, true) ~= nil
            or text:find("bed", 1, true) ~= nil
            or text:find("bunk", 1, true) ~= nil
            or text:find("hammock", 1, true) ~= nil
            or text:find("lecturn", 1, true) ~= nil
            or text:find("lectern", 1, true) ~= nil
    end

    local function distance(a, b)
        if not (a and b) then return math.huge end
        local ok, value = pcall(function() return (a - b):length() end)
        return ok and value or math.huge
    end

    releaseSafetyGateFields = function(interactionType, cell, profile, obj, options)
        if not (releaseSafetyGate and releaseSafetyGate.policy) then return {} end
        local policy = releaseSafetyGate.policy(settings, cell, interactionType, profile, obj, options or { calibrationAction = true })
        return {
            releaseSafetyGateEnabled = policy and policy.enabled == true,
            releaseSafetyGateStatus = policy and policy.status or nil,
            releaseSafetyGateReason = policy and policy.reason or nil,
            releaseSafetyGateCell = policy and policy.cellName or nil,
            releaseSafetyGateRegion = policy and policy.regionName or nil,
            releaseSafetyGateFurnitureType = policy and policy.furnitureType or nil,
            releaseSafetyGateLabel = releaseSafetyGate.visibleLabel and releaseSafetyGate.visibleLabel(policy) or nil,
        }
    end

    local function stationSessionDataForObject(obj, actorOverride)
        local profile = profiles.stationProfileForObject and profiles.stationProfileForObject(obj, settings) or nil
        if not profile then return nil end
        local pos = profiles.stationWorldPosition and profiles.stationWorldPosition(obj, profile, util) or obj.position
        if not pos then return nil end
        local slotName = profile.slotName or "station"
        local slotKey = stationSlotKey and stationSlotKey(obj, profile)
            or (tostring(obj and (obj.id or obj.recordId) or "station") .. "|station|" .. tostring(slotName))
        local claim = claimedStationData and claimedStationData(slotKey) or nil
        local actor = actorOverride or (claim and claim.npc) or nil
        local data = {
            interactionType = "station",
            actor = actor,
            npc = actor,
            actorId = actor and actor.id or nil,
            actorRecordId = actor and actor.recordId or nil,
            object = obj,
            objectId = obj and obj.recordId,
            objectRecordId = obj and obj.recordId,
            objectKey = tostring(obj and (obj.id or obj.recordId) or ""),
            model = objectModelPath(obj),
            objectModelPath = objectModelPath(obj),
            slotName = slotName,
            slotKey = slotKey,
            slot = { name = slotName },
            profile = profile,
            profileId = profile.profileId,
            releaseSafetyGateEnabled = claim and claim.releaseSafetyGateEnabled,
            releaseSafetyGateStatus = claim and claim.releaseSafetyGateStatus,
            releaseSafetyGateReason = claim and claim.releaseSafetyGateReason,
            releaseSafetyGateCell = claim and claim.releaseSafetyGateCell,
            releaseSafetyGateRegion = claim and claim.releaseSafetyGateRegion,
            releaseSafetyGateFurnitureType = claim and claim.releaseSafetyGateFurnitureType,
            releaseSafetyGateLabel = claim and claim.releaseSafetyGateLabel,
            profileOffset = {
                x = profile.localOffset and profile.localOffset.x or 0,
                y = profile.localOffset and profile.localOffset.y or 0,
                z = profile.localOffset and profile.localOffset.z or 0,
                yaw = profile.facingYawDeg or 0,
            },
            calibration = zeroCalibrationOffset(),
            finalPosition = pos,
            position = pos,
            stationPosition = pos,
            facingDirection = profiles.stationFacingDirection and profiles.stationFacingDirection(obj, profile, util) or nil,
            facingKind = profile.stationType or "station",
            facingObjectId = obj and obj.recordId,
            facingObjectPosition = obj and obj.position,
        }
        if data.releaseSafetyGateEnabled == nil then
            local gate = releaseSafetyGateFields("station", obj and obj.cell, profile, obj, { calibrationAction = true, profile = profile, object = obj })
            for key, value in pairs(gate) do data[key] = value end
        end
        applyCalibrationActorIdentity(data, actor)
        return data
    end

    local function stationSessionDataForObjectWithActor(player, obj, actorOverride)
        local data = stationSessionDataForObject(obj, actorOverride)
        return data
    end

    local function captureStationSession(player, lookTarget, lookTargetPos)
        if not (player and player.cell and player.cell.getAll) then return nil end
        if lookTargetActorKind(lookTarget) and stationDataForNpc then
            local stationData = stationDataForNpc(lookTarget)
            if stationData and stationData.object then
                local data = stationSessionDataForObjectWithActor(player, stationData.object, lookTarget)
                if data then
                    return calibrationLock.captureStationTarget(data, calibrationContext(), "menu_capture_station_actor")
                end
            end
            local actorAnchor = lookTarget and lookTarget.position or nil
            local nearestData, nearestScore = nil, nil
            local okObjects, objects = pcall(function() return player.cell:getAll() end)
            if okObjects and objects and actorAnchor then
                for _, obj in ipairs(objects) do
                    if isObjValid(obj) then
                        local data = stationSessionDataForObjectWithActor(player, obj, lookTarget)
                        if data and data.finalPosition then
                            local dist = distance(data.finalPosition, actorAnchor)
                            local radius = tonumber(data.profile and data.profile.radius or 260) or 260
                            if dist <= math.max(radius, 180) and (not nearestScore or dist < nearestScore) then
                                nearestData, nearestScore = data, dist
                            end
                        end
                    end
                end
            end
            if nearestData then
                infoLog("calibration station actor paired by position", lookTarget.recordId or lookTarget.id, "object", tostring(nearestData.objectId), "slot", tostring(nearestData.slotName), "distance", tostring(nearestScore))
                return calibrationLock.captureStationTarget(nearestData, calibrationContext(), "menu_capture_station_actor_position")
            end
        end
        if isObjValid(lookTarget) then
            local direct = stationSessionDataForObjectWithActor(player, lookTarget)
            if direct then
                return calibrationLock.captureStationTarget(direct, calibrationContext(), "menu_capture_station_sharedray")
            end
        end
        local anchor = lookTargetPos or (lookTarget and lookTarget.position) or player.position
        local best, bestScore = nil, nil
        local okObjects, objects = pcall(function() return player.cell:getAll() end)
        if not (okObjects and objects) then return nil end
        for _, obj in ipairs(objects) do
            if isObjValid(obj) then
                local data = stationSessionDataForObjectWithActor(player, obj)
                if data and data.finalPosition then
                    local dist = distance(data.finalPosition, anchor)
                    if dist <= tonumber(data.profile and data.profile.radius or 260) then
                        local score = dist
                        if lookTargetPos then score = score - 90 end
                        if not bestScore or score < bestScore then
                            best, bestScore = data, score
                        end
                    end
                end
            end
        end
        if not best then return nil end
        local session = calibrationLock.captureStationTarget(best, calibrationContext(), "menu_capture_station_nearest")
        infoLog("calibration station target captured", tostring(best.objectId), "slot", tostring(best.slotName), "score", tostring(bestScore))
        return session
    end

    local function sameObject(a, b)
        if a == b then return true end
        if not (a and b) then return false end
        local aId = a.id or a.recordId
        local bId = b.id or b.recordId
        return aId ~= nil and bId ~= nil and tostring(aId) == tostring(bId)
    end

    local function slotFamilyKey(slotKey)
        local text = tostring(slotKey or "")
        if text == "" then return "" end
        return text:match("^(.*)::[^:]+$") or text
    end

    local function sameFurnitureSession(data, session)
        if sameObject(data and data.object, session and session.object) then return true end
        local dataFamily = slotFamilyKey(data and data.slotKey)
        local sessionFamily = slotFamilyKey(session and session.slotKey)
        return dataFamily ~= "" and dataFamily == sessionFamily
    end

    local function objectEnabled(obj)
        if not obj then return false end
        local ok, enabled = pcall(function() return obj.enabled end)
        if ok and enabled == false then return false end
        return true
    end

    local function captureLookTargetSession(interactionType, player, lookTarget, lookTargetPos)
        if not (isObjValid(lookTarget) and player and player.cell) then return nil, false end
        local constrainedActor = lookTargetActorKind(lookTarget)
        local constrainedFurniture = not constrainedActor and lookTargetFurnitureKind(lookTarget)
        local constrained = constrainedActor or constrainedFurniture
        local best, bestScore = nil, nil
        local function distance(a, b)
            if not (a and b) then return math.huge end
            local ok, value = pcall(function() return (a - b):length() end)
            return ok and value or math.huge
        end
        for _, data in pairs(getAssignedActors() or {}) do
            if data and (interactionType == "auto" or data.interactionType == interactionType) then
                local actor = data.npc or data.actor
                if isObjValid(actor) and isObjValid(data.object) and actor.cell == player.cell then
                    local directActorMatch = sameObject(actor, lookTarget)
                    local directObjectMatch = sameObject(data.object, lookTarget)
                    local anchor = lookTargetPos or (lookTarget and lookTarget.position) or data.finalPosition or data.position or data.object.position or actor.position
                    local actorDist = actor.position and distance(actor.position, anchor) or math.huge
                    local objectDist = data.object.position and distance(data.object.position, anchor) or math.huge
                    local finalDist = data.finalPosition and distance(data.finalPosition, anchor) or math.huge
                    local scoreObjectDist = objectDist
                    if constrainedFurniture and sameObject(data.object, lookTarget) and lookTargetPos then
                        -- For multi-slot furniture, especially bunks, object-origin distance is
                        -- identical for every slot and can drown out the actual looked-at level.
                        scoreObjectDist = math.huge
                    end
                    local anchorDist = math.min(actorDist, scoreObjectDist, finalDist)
                    local anchoredMatch = constrainedActor and anchorDist <= 320
                    local targetMatches = (constrainedActor and directActorMatch)
                        or (constrainedFurniture and directObjectMatch)
                        or anchoredMatch
                        or ((not constrained) and anchorDist <= 220)
                    if targetMatches then
                        local score = anchorDist
                        if directActorMatch then
                            score = score - 1000000
                        elseif directObjectMatch then
                            score = score - 500000
                        elseif anchoredMatch then
                            score = score - 250000
                        end
                        if data.state == interactingState then score = score - 100000 end
                        if not bestScore or score < bestScore then
                            best, bestScore = data, score
                        end
                    end
                end
            end
        end
        if not best then
            if constrained then
                infoLog(
                    "calibration sharedray exact target missed",
                    tostring(lookTarget and (lookTarget.recordId or lookTarget.id) or "<none>"),
                    "fallback", "nearest_active_target"
                )
            end
            return nil, constrained
        end
        if constrained then
            local actor = best.npc or best.actor
            local directActorMatch = sameObject(actor, lookTarget)
            local directObjectMatch = sameObject(best.object, lookTarget)
            if not directActorMatch and not directObjectMatch then
                infoLog(
                    "calibration sharedray anchored fallback",
                    tostring(lookTarget and (lookTarget.recordId or lookTarget.id) or "<none>"),
                    "targetActor", tostring(actor and (actor.recordId or actor.id) or "<none>"),
                    "targetObject", tostring(best.object and (best.object.recordId or best.object.id) or "<none>")
                )
            end
        end
        calibrationLock.rememberTarget(best, {
            cellName = cellName,
            now = core.getSimulationTime,
            infoLog = infoLog,
        }, "menu_capture_sharedray")
        return calibrationLock.session, constrained
    end

    local function rememberPendingCalibrationTarget(actor, candidate, reason)
        if not (actor and candidate and candidate.object and candidate.slotKey) then return false end
        local data = profiles.shallowCopy(candidate)
        data.npc = actor
        data.actor = actor
        data.actorId = actor.id
        data.actorRecordId = actor.recordId
        applyCalibrationActorIdentity(data, actor)
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
        data.facingObjectScale = candidate.facingObjectScale
        data.facingKind = candidate.facingKind
        data.facingReason = candidate.facingReason
        data.facingObjectPosition = candidate.facingObjectPosition
        calibrationLock.rememberTarget(data, {
            cellName = cellName,
            now = core.getSimulationTime,
            infoLog = infoLog,
        }, reason or "manual_pending")
        return true
    end

    local function furnitureSessionDataForCandidate(candidate, actorOverride)
        if not (candidate and candidate.object and candidate.slotKey and (candidate.interactionType == "sitting" or candidate.interactionType == "sleeping")) then
            return nil
        end
        local actor = actorOverride or candidate.externalPhysicalClaimActor or candidate.npc or candidate.actor or candidate.occupiedByTestNpcActor
        local data = {
            interactionType = candidate.interactionType,
            actor = actor,
            npc = actor,
            actorId = actor and actor.id or nil,
            actorRecordId = actor and actor.recordId or nil,
            object = candidate.object,
            objectId = candidate.objectId or candidate.object.recordId,
            objectRecordId = candidate.objectId or candidate.object.recordId,
            objectKey = tostring(candidate.object and (candidate.object.id or candidate.object.recordId) or ""),
            model = candidate.model or objectModelPath(candidate.object),
            objectModelPath = candidate.model or objectModelPath(candidate.object),
            slot = candidate.slot,
            slotName = candidate.slotName,
            slotKey = candidate.slotKey,
            profile = candidate.profile,
            profileId = candidate.profileId,
            profileSelectionTrace = candidate.profileSelectionTrace,
            profileSelectionSource = candidate.profileSelectionSource or (candidate.profile and candidate.profile.profileSelectionSource),
            profileSelectionReason = candidate.profileSelectionReason or (candidate.profile and candidate.profile.profileSelectionReason),
            profileSelectionKey = candidate.profileSelectionKey or (candidate.profile and candidate.profile.profileSelectionKey),
            profileOffset = candidate.profileOffset,
            animationOffset = candidate.animationOffset,
            animationName = candidate.animationName or candidate.animation,
            calibration = candidate.calibration or zeroCalibrationOffset(),
            approachPos = candidate.approachPos,
            finalPosition = candidate.finalPosition or candidate.position,
            finalRotation = candidate.finalRotation,
            facingDirection = candidate.preferredFacingDirection or candidate.facingDirection,
            facingObjectId = candidate.facingObjectId,
            facingObjectRefId = candidate.facingObjectRefId,
            facingObjectModel = candidate.facingObjectModel,
            facingObjectName = candidate.facingObjectName,
            facingObjectScale = candidate.facingObjectScale,
            facingObjectContentFile = candidate.facingObjectContentFile or displayContentFile(candidate.facingObject),
            facingObjectDistance = candidate.facingObjectDistance,
            facingKind = candidate.facingKind,
            facingReason = candidate.facingReason,
            facingObjectPosition = candidate.facingObjectPosition,
            facingCandidates = candidate.facingCandidates,
            manualAssignOverrideApplied = candidate.manualAssignOverrideApplied == true,
            manualAssignOverrideReason = candidate.manualAssignOverrideReason,
            manualAssignOverrideReasons = candidate.manualAssignOverrideReasons,
            surfaceBlockerReason = candidate.surfaceBlockerReason,
            surfaceBlockerOverrideReason = candidate.surfaceBlockerOverrideReason,
            surfaceBlockerKind = candidate.surfaceBlockerKind,
            surfaceBlockerObjectId = candidate.surfaceBlockerObjectId,
            surfaceBlockerDistance = candidate.surfaceBlockerDistance,
            surfaceBlockerVertical = candidate.surfaceBlockerVertical,
            surfaceBlockerLocalReason = candidate.surfaceBlockerLocalReason,
            softBlockerReason = candidate.softBlockerReason,
            hardBlockerReason = candidate.hardBlockerReason,
            sleepSafetyReason = candidate.sleepSafetyReason,
            sleepSafetyDelta = candidate.sleepSafetyDelta,
            sleepSafetyLimit = candidate.sleepSafetyLimit,
            sleepSafetyOverrideReason = candidate.sleepSafetyOverrideReason,
            sleepSafetyRepairReason = candidate.sleepSafetyRepairReason,
            sleepSafetyRepairDelta = candidate.sleepSafetyRepairDelta,
            sleepSafetyRepairLimit = candidate.sleepSafetyRepairLimit,
            sleepCalibrationWarningReason = candidate.sleepCalibrationWarningReason,
            releaseSafetyGateEnabled = candidate.releaseSafetyGateEnabled,
            releaseSafetyGateStatus = candidate.releaseSafetyGateStatus,
            releaseSafetyGateReason = candidate.releaseSafetyGateReason,
            releaseSafetyGateCell = candidate.releaseSafetyGateCell,
            releaseSafetyGateRegion = candidate.releaseSafetyGateRegion,
            releaseSafetyGateFurnitureType = candidate.releaseSafetyGateFurnitureType,
            releaseSafetyGateLabel = candidate.releaseSafetyGateLabel,
            externalPhysicalClaimed = candidate.externalPhysicalClaimed == true,
            externalPhysicalClaimReason = candidate.externalPhysicalClaimReason,
            externalPhysicalClaimActor = candidate.externalPhysicalClaimActor,
            externalPhysicalClaimActorRecordId = candidate.externalPhysicalClaimActorRecordId,
            externalPhysicalClaimActorId = candidate.externalPhysicalClaimActorId,
            rejectionReason = candidate.rejectionReason,
        }
        if data.releaseSafetyGateEnabled == nil or candidate.externalPhysicalClaimed == true then
            local gate = releaseSafetyGateFields(candidate.interactionType, candidate.object.cell, candidate.profile, candidate.object, {
                calibrationAction = true,
                externalCompatibilityAssist = candidate.externalPhysicalClaimed == true,
                profile = candidate.profile,
                object = candidate.object,
                seatCategory = candidate.profile and (candidate.profile.seatCategory or candidate.profile.type) or nil,
            })
            for key, value in pairs(gate) do data[key] = value end
        end
        applyCalibrationActorIdentity(data, actor)
        return data
    end

    local function sendSiblingLinkedNudge(session, effectiveType, ev)
        if not (session and ev) then return 0, nil end
        if effectiveType ~= "sitting" and effectiveType ~= "sleeping" then return 0 end
        local syncX = ev.syncSlotXY == true and tonumber(ev.x) and tonumber(ev.x) ~= 0
        local syncY = ev.syncSlotXY == true and tonumber(ev.y) and tonumber(ev.y) ~= 0
        local syncZ = ev.syncSlotZ == true and tonumber(ev.z) and tonumber(ev.z) ~= 0
        local syncYaw = ev.syncSlotYaw == true and tonumber(ev.yaw) and tonumber(ev.yaw) ~= 0
        if not (syncX or syncY or syncZ or syncYaw) then return 0, nil end
        local assignedActors = getAssignedActors()
        local sent = 0
        local axes = {}
        if syncX then axes[#axes + 1] = "x" end
        if syncY then axes[#axes + 1] = "y" end
        if syncZ then axes[#axes + 1] = "z" end
        if syncYaw then axes[#axes + 1] = "yaw" end
        local axisLabel = table.concat(axes, ",")
        for _, data in pairs(assignedActors or {}) do
            local actor = data and (data.npc or data.actor)
            if data and actor and actor ~= session.actor
                and data.interactionType == effectiveType
                and data.slotKey ~= session.slotKey
                and sameFurnitureSession(data, session) then
                local payload = {
                    syncSlotZ = false,
                    syncSlotXY = false,
                    syncSlotYaw = false,
                    reason = (syncX or syncY or syncYaw) and "developer_menu_linked_nudge_xyyaw" or "developer_menu_linked_nudge_z",
                }
                if syncX then payload.x = ev.x end
                if syncY then payload.y = ev.y end
                if syncZ then payload.z = ev.z end
                if syncYaw then payload.yaw = ev.yaw end
                actor:sendEvent(effectiveType == "sleeping" and "SitDownPleaseNudgeSleepCalibration" or "SitDownPleaseNudgeSittingCalibration", {
                    x = payload.x,
                    y = payload.y,
                    z = payload.z,
                    yaw = payload.yaw,
                    syncSlotZ = false,
                    syncSlotXY = false,
                    syncSlotYaw = false,
                    reason = payload.reason,
                })
                sent = sent + 1
                infoLog(
                    "calibration linked-slot nudge smooth sent",
                    actor.recordId or actor.id,
                    "type", tostring(effectiveType),
                    "object", tostring(data.objectId),
                    "fromSlot", tostring(session.slotName),
                    "toSlot", tostring(data.slotName),
                    "axes", axisLabel,
                    "x", tostring(payload.x),
                    "y", tostring(payload.y),
                    "z", tostring(payload.z),
                    "yaw", tostring(payload.yaw)
                )
            end
        end
        return sent, axisLabel
    end

    local function sendSiblingLinkedPrint(session, effectiveType)
        if not session then return 0 end
        if effectiveType ~= "sitting" and effectiveType ~= "sleeping" then return 0 end
        local assignedActors = getAssignedActors()
        local sent = 0
        for _, data in pairs(assignedActors or {}) do
            local actor = data and (data.npc or data.actor)
            if data and actor and actor ~= session.actor
                and data.interactionType == effectiveType
                and data.slotKey ~= session.slotKey
                and sameFurnitureSession(data, session) then
                actor:sendEvent(effectiveType == "sleeping" and "SitDownPleasePrintSleepCalibration" or "SitDownPleasePrintSittingCalibration", {
                    reason = "developer_menu_linked_print",
                })
                sent = sent + 1
                infoLog(
                    "calibration linked-slot print sent",
                    actor.recordId or actor.id,
                    "type", tostring(effectiveType),
                    "object", tostring(data.objectId),
                    "fromSlot", tostring(session.slotName),
                    "toSlot", tostring(data.slotName)
                )
            end
        end
        return sent
    end

    local function vecLabel(value)
        if not value then return "nil" end
        return tostring(value.x or 0) .. "," .. tostring(value.y or 0) .. "," .. tostring(value.z or 0)
    end

    local function offsetLabel(value)
        if not value then return "nil" end
        return tostring(value.x or 0) .. "," .. tostring(value.y or 0) .. "," .. tostring(value.z or 0) .. ",yaw=" .. tostring(value.yaw or 0)
    end

    local function reasonAppliesToVisualKind(kind, value)
        local text = tostring(value or "")
        if kind == "sleeping" and (text == "seat_surface_blocked_by_item" or text == "item_blocker" or text == "cushion_surface_blocker") then
            return false
        end
        if kind == "sitting" and (text == "sleep_surface_blocked_by_item" or text:find("^sleep_")) then
            return false
        end
        return true
    end

    local function appendReason(parts, value, kind)
        value = tostring(value or "")
        if value == "" or value == "nil" then return end
        for raw in value:gmatch("[^,%+]+") do
            local item = raw:gsub("^%s+", ""):gsub("%s+$", "")
            if item ~= "" and item ~= "nil" and reasonAppliesToVisualKind(kind, item) then
                local exists = false
                for _, old in ipairs(parts) do
                    if old == item then
                        exists = true
                        break
                    end
                end
                if not exists then parts[#parts + 1] = item end
            end
        end
    end

    local function visualApprovalReasons(source)
        local parts = {}
        local kind = tostring(source and source.interactionType or "")
        appendReason(parts, source and source.manualAssignOverrideReason, kind)
        appendReason(parts, source and source.manualOverrideReason, kind)
        appendReason(parts, source and source.testingOverrideReason, kind)
        appendReason(parts, source and source.surfaceBlockerReason, kind)
        appendReason(parts, source and source.surfaceBlockerOverrideReason, kind)
        appendReason(parts, source and source.softBlockerReason, kind)
        appendReason(parts, source and source.hardBlockerReason, kind)
        appendReason(parts, source and source.sleepSafetyReason, kind)
        appendReason(parts, source and source.sleepSafetyOverrideReason, kind)
        appendReason(parts, source and source.sleepCalibrationWarningReason, kind)
        appendReason(parts, source and source.rejectionReason, kind)
        return table.concat(parts, ",")
    end

    local function splitVisualApprovalReasons(reasons)
        local out = {}
        for raw in tostring(reasons or ""):gmatch("[^,%+]+") do
            local value = raw:gsub("^%s+", ""):gsub("%s+$", "")
            if value ~= "" and value ~= "nil" then out[#out + 1] = value end
        end
        return out
    end

    local function serviceOnlyVisualReason(reason)
        local text = tostring(reason or ""):lower()
        return text == "guard_or_publican_class"
            or text == "publican_class"
            or text == "barter_service_npc"
            or text == "trainer_service_npc"
            or text == "travel_service_npc"
            or text == "service_npc"
            or text:find("service", 1, true) ~= nil
            or text:find("guard", 1, true) ~= nil
            or text:find("publican", 1, true) ~= nil
    end

    local function visualBlockerReview(reasons)
        local review = {}
        for _, reason in ipairs(splitVisualApprovalReasons(reasons)) do
            if not serviceOnlyVisualReason(reason) then
                review[#review + 1] = reason
            end
        end
        if #review == 0 then return "none" end
        return table.concat(review, ",")
    end

    local function logVisualApproval(session, source, linked)
        if not session then return false end
        source = source or currentAssignmentForSession(session) or session
        local actor = source.actor or source.npc or session.actor
        local object = source.object or session.object
        local kind = tostring(source.interactionType or session.interactionType or "")
        local objectId = source.objectId or source.objectRecordId or session.objectRecordId or (object and object.recordId)
        local model = source.objectModelPath or source.model or session.objectModelPath or session.model or objectModelPath(object)
        local profile = source.profile or session.profile
        local profileId = source.profileId or session.profileId or (profile and profile.profileId)
        local trace = source.profileSelectionTrace or session.profileSelectionTrace or (profile and profile.profileSelectionTrace) or {}
        local profileScopeLabel = tostring(trace.scope or "")
        local variantScopeLabel = tostring(trace.variantScope or "")
        local reasons = visualApprovalReasons(source)
        local cal = source.calibration or session.calibration or {}
        local entryClean = calibrationOffsetUnchanged(cal)
        local blockerReview = visualBlockerReview(reasons)
        local scope = entryClean and "entry_no_nudge" or "after_nudge"
        local note = entryClean and "visual_good_on_entry_no_nudge" or "visual_after_nudge_not_entry_approval"
        local surfaceEvidenceReason = kind == "sleeping" and sleepCalibrationWarnings.evidenceReason(source.sleepSurfaceMode or source.surfaceMode, {
            profile = profile,
            slotName = source.slotName or session.slotName,
            slotKey = source.slotKey or session.slotKey,
            objectId = objectId,
        }) or nil
        print("[SitDownPlease Calibration Export]",
            "VISUAL_APPROVAL",
            "kind", kind,
            "note", note,
            "visualApprovalScope", scope,
            "entryClean", tostring(entryClean),
            "nudged", tostring(not entryClean),
            "normalGameplayGuarded", tostring(blockerReview ~= "none"),
            "blockerReview", tostring(blockerReview),
            "linked", tostring(linked == true),
            "actor", tostring(actor and (actor.recordId or actor.id)),
            "actorScale", tostring(actor and actor.scale),
            "object", tostring(objectId),
            "model", tostring(model),
            "objectScale", tostring(object and object.scale),
            "profile", tostring(profileId),
            "profileSource", tostring(source.profileSelectionSource or session.profileSelectionSource),
            "profileKey", tostring(source.profileSelectionKey or session.profileSelectionKey),
            "profileScope", profileScopeLabel,
            "variantScope", variantScopeLabel,
            "slot", tostring(source.slotName or session.slotName),
            "cell", tostring(source.cellName or session.cellName or cellName()),
            "animation", tostring(source.animationName or source.animation or session.animationName or session.animation),
            "profileOffset", offsetLabel(source.profileOffset or session.profileOffset),
            "animationOffset", offsetLabel(source.animationOffset or session.animationOffset),
            "calibration", offsetLabel(source.calibration or session.calibration),
            "final", vecLabel(source.finalPosition or session.finalPosition),
            "surfaceMode", tostring(source.sleepSurfaceMode or source.surfaceMode),
            "rawSurfaceMode", tostring(source.sleepRawSurfaceMode or source.rawSurfaceMode or session.sleepRawSurfaceMode or session.rawSurfaceMode),
            "surfaceAnchorStabilized", tostring(source.sleepSurfaceAnchorStabilized == true or session.sleepSurfaceAnchorStabilized == true),
            "surfaceEvidenceReason", tostring(surfaceEvidenceReason),
            "rawSurface", vecLabel(source.sleepRawSurfacePosition or source.rawBedTop or session.sleepRawSurfacePosition or session.rawBedTop),
            "surfaceSamples", tostring(source.sleepSurfaceSamples or source.surfaceSamples),
            "safetyReason", tostring(source.sleepSafetyReason),
            "safetyDelta", tostring(source.sleepSafetyDelta),
            "safetyLimit", tostring(source.sleepSafetyLimit),
            "blockerReason", tostring(source.surfaceBlockerReason),
            "blockerObject", tostring(source.surfaceBlockerObjectId),
            "reasons", tostring(reasons),
            "simTime", tostring(core.getSimulationTime and core.getSimulationTime() or nil)
        )
        infoLog(
            "VISUAL_APPROVAL",
            "kind", kind,
            "scope", scope,
            "entryClean", tostring(entryClean),
            "normalGameplayGuarded", tostring(blockerReview ~= "none"),
            "blockerReview", tostring(blockerReview),
            "linked", tostring(linked == true),
            "actor", tostring(actor and (actor.recordId or actor.id)),
            "object", tostring(objectId),
            "profile", tostring(profileId),
            "profileScope", profileScopeLabel,
            "variantScope", variantScopeLabel,
            "slot", tostring(source.slotName or session.slotName),
            "surfaceMode", tostring(source.sleepSurfaceMode or source.surfaceMode),
            "rawSurfaceMode", tostring(source.sleepRawSurfaceMode or source.rawSurfaceMode or session.sleepRawSurfaceMode or session.rawSurfaceMode),
            "surfaceAnchorStabilized", tostring(source.sleepSurfaceAnchorStabilized == true or session.sleepSurfaceAnchorStabilized == true),
            "surfaceEvidenceReason", tostring(surfaceEvidenceReason),
            "surfaceSamples", tostring(source.sleepSurfaceSamples or source.surfaceSamples),
            "safetyReason", tostring(source.sleepSafetyReason),
            "blockerReason", tostring(source.surfaceBlockerReason),
            "reasons", tostring(reasons)
        )
        return true
    end

    local function sendSiblingLinkedVisualApproval(session, effectiveType)
        if not session then return 0 end
        if effectiveType ~= "sitting" and effectiveType ~= "sleeping" then return 0 end
        local source = currentAssignmentForSession(session) or session
        local sourceActor = source.actor or source.npc or session.actor or session.npc
        local assignedActors = getAssignedActors()
        local logged = 0
        local seen = {}
        local function actorKey(actor)
            return actor and tostring(actor.id or actor.recordId or "") or ""
        end
        local sourceActorKey = actorKey(sourceActor)
        if sourceActorKey ~= "" then seen[sourceActorKey] = true end
        for _, data in pairs(assignedActors or {}) do
            local actor = data and (data.npc or data.actor)
            if data and actor and actor ~= sourceActor
                and data.interactionType == effectiveType
                and data.slotKey ~= source.slotKey
                and sameFurnitureSession(data, source) then
                local linkedSession = {
                    interactionType = effectiveType,
                    actor = actor,
                    object = data.object or source.object or session.object,
                    objectRecordId = data.objectId or data.objectRecordId or source.objectRecordId or session.objectRecordId,
                    model = data.model or source.model or session.model,
                    profile = data.profile or source.profile or session.profile,
                    profileId = data.profileId or source.profileId or session.profileId,
                    profileSelectionTrace = data.profileSelectionTrace or source.profileSelectionTrace or session.profileSelectionTrace,
                    profileSelectionSource = data.profileSelectionSource or source.profileSelectionSource or session.profileSelectionSource,
                    profileSelectionKey = data.profileSelectionKey or source.profileSelectionKey or session.profileSelectionKey,
                    slotName = data.slotName,
                    slotKey = data.slotKey,
                    cellName = data.cellName or source.cellName or session.cellName,
                }
                if logVisualApproval(linkedSession, data, true) then
                    logged = logged + 1
                    local key = actorKey(actor)
                    if key ~= "" then seen[key] = true end
                end
            end
        end
        local sourceObject = source.object or session.object
        local cell = (sourceObject and sourceObject.cell)
            or (sourceActor and sourceActor.cell)
            or (world.players and world.players[1] and world.players[1].cell)
        if not cell then return logged end
        local candidates = buildCandidateSlots(cell, effectiveType, {
            ignoreTimeGate = true,
            manualAssign = true,
            calibrationAction = true,
            allowOccupiedByTestNpc = true,
        })
        for _, candidate in ipairs(candidates or {}) do
            local actor = candidate and (candidate.externalPhysicalClaimActor or candidate.occupiedByTestNpcActor or candidate.npc or candidate.actor) or nil
            local slotKey = candidate and candidate.slotKey or nil
            local key = actorKey(actor)
            local uniqueKey = key ~= "" and key or tostring(slotKey or "")
            if candidate and actor and actor ~= sourceActor
                and candidate.interactionType == effectiveType
                and slotKey ~= source.slotKey
                and sameFurnitureSession(candidate, source)
                and uniqueKey ~= ""
                and not seen[uniqueKey] then
                local linkedSession = furnitureSessionDataForCandidate(candidate, actor)
                if linkedSession and logVisualApproval(linkedSession, linkedSession, true) then
                    logged = logged + 1
                    seen[uniqueKey] = true
                    infoLog(
                        "calibration linked-slot visual approval recovered from candidate scan",
                        actor.recordId or actor.id,
                        "type", tostring(effectiveType),
                        "object", tostring(candidate.objectId),
                        "fromSlot", tostring(source.slotName),
                        "toSlot", tostring(candidate.slotName)
                    )
                end
            end
        end
        return logged
    end

    local function playerForwardVector(player)
        local yaw = 0
        if player and player.rotation then
            local ok, value = pcall(function() return player.rotation:getYaw() end)
            if ok and value then yaw = tonumber(value) or 0 end
        end
        return util.vector3(math.sin(yaw), math.cos(yaw), 0)
    end

    local function horizontalVector(v)
        if not v then return nil end
        return util.vector3(v.x or 0, v.y or 0, 0)
    end

    local function viewConeScore(player, point, focusPos)
        if not (player and player.position and point) then return nil end
        local from = horizontalVector(player.position)
        local to = horizontalVector(point)
        local delta = to - from
        local dist = delta:length()
        if dist <= 1 or dist > 2400 then return nil end
        local forward = horizontalVector(playerForwardVector(player))
        if not forward then return nil end
        local forwardLen = forward:length()
        if forwardLen <= 0 then return nil end
        forward = forward / forwardLen
        local dir = delta / dist
        local dot = forward.x * dir.x + forward.y * dir.y
        if dot < 0.54 then return nil end
        local perp = math.sqrt(math.max(0, 1 - dot * dot)) * dist
        local focusPenalty = 0
        if focusPos then
            local ok, value = pcall(function() return (point - focusPos):length() end)
            if ok and value then focusPenalty = math.min(value, 1000) end
        end
        return perp * 3 + dist * 0.12 + focusPenalty * 0.35
    end

    local function captureViewConeSession(interactionType, player, focusPos)
        if not (player and player.cell and player.position) then return nil end
        local best, bestScore = nil, nil
        for _, data in pairs(getAssignedActors() or {}) do
            if data and (interactionType == "auto" or data.interactionType == interactionType) then
                local actor = data.npc or data.actor
                if isObjValid(actor) and isObjValid(data.object) and actor.cell == player.cell then
                    local points = {
                        data.finalPosition,
                        actor.position,
                        data.position,
                        data.object and data.object.position,
                    }
                    for _, point in ipairs(points) do
                        local score = viewConeScore(player, point, focusPos)
                        if score then
                            if data.state == interactingState then score = score - 500 end
                            if not bestScore or score < bestScore then
                                best, bestScore = data, score
                            end
                        end
                    end
                end
            end
        end
        if not best then return nil end
        calibrationLock.rememberTarget(best, {
            cellName = cellName,
            now = core.getSimulationTime,
            infoLog = infoLog,
        }, "menu_capture_view_cone")
        infoLog(
            "calibration view-cone target captured",
            tostring(interactionType),
            "actor", tostring((best.npc or best.actor) and ((best.npc or best.actor).recordId or (best.npc or best.actor).id) or "<none>"),
            "object", tostring(best.object and (best.object.recordId or best.object.id) or "<none>"),
            "slot", tostring(best.slotName or best.slotKey),
            "score", tostring(bestScore)
        )
        return calibrationLock.session
    end

    local function registerCalibrationTestNpc(npc)
        if not (npc and npc.id) then return end
        calibrationTestNpc = npc
        calibrationTestNpcs[npc.id] = npc
    end

    local function removeOneCalibrationTestNpc(npc, reason)
        if not isObjValid(npc) then return false end
        local identity = fillIdentityForActor(npc)
        local assignedActors = getAssignedActors()
        local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
        if npc.id and assignedActors[npc.id] and stopInteractionForNpc then
            pcall(function() stopInteractionForNpc(npc, reason or "developer_test_npc_removed") end)
        end
        local ok = pcall(function() npc:remove() end)
        if not ok then
            ok = pcall(function() npc.enabled = false end)
        end
        forgetCalibrationFillLedgerActor(npc)
        infoLog("developer calibration test npc removed", tostring(identity and identity.label or npc.recordId or npc.id), "record", tostring(npc.recordId), "source", tostring(identity and identity.source), "runtimeObject", tostring(identity and identity.runtimeObjectId), "reason", tostring(reason or "developer_test_npc_removed"))
        return ok == true
    end

    local function collectCurrentCellCalibrationTestNpcs(player)
        local found = {}
        local ledgerRecords = readCalibrationFillLedger()
        if player and player.cell and player.cell.getAll then
            local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
            if okList and npcs then
                for _, candidate in ipairs(npcs) do
                    local recordId = candidate and candidate.recordId and string.lower(tostring(candidate.recordId)) or ""
                    local record = candidate and candidate.id and ledgerRecords[tostring(candidate.id)] or nil
                    if isCalibrationTestNpcRecord(recordId) and record and record.generated == true and isObjValid(candidate) and candidate ~= player then
                        found[#found + 1] = candidate
                    end
                end
            end
        end
        return found
    end

    local function registerCalibrationFillActor(actor, target, spawned)
        if actor and actor.id then
            calibrationFillActors[actor.id] = actor
            local identity = assignCalibrationActorIdentity(actor, "fill", spawned == true)
            rememberCalibrationFillLedger(actor, target, spawned, identity)
            infoLog(
                "developer calibration fill actor identity",
                tostring(identity and identity.label or actor.recordId or actor.id),
                "source", tostring(identity and identity.source or (spawned == true and "generated" or "borrowed")),
                "runtimeObject", tostring(identity and identity.runtimeObjectId or actorRuntimeObjectId(actor)),
                "record", tostring(actor.recordId),
                "session", tostring(identity and identity.sessionId)
            )
        end
    end

    local function clearCalibrationFillAssignments(reason, player)
        local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
        local stopped = 0
        local returned = 0
        local removed = 0
        local failed = 0
        local cleanedIds = { objects = {} }
        local assignedActors = getAssignedActors()
        local ledgerById = {}
        local ledgerRecords = readCalibrationFillLedger()
        for _, item in ipairs(currentCellFillLedgerActors(player)) do
            if item.actor and item.key then
                calibrationFillActors[item.key] = item.actor
                ledgerById[item.key] = item.record
            end
        end
        for id, data in pairs(assignedActors or {}) do
            local actor = data and (data.npc or data.actor) or nil
            if data and data.calibrationFill == true and actor and actor.id then
                calibrationFillActors[id] = actor
                ledgerById[tostring(id)] = ledgerRecords[tostring(id)] or ledgerById[tostring(id)]
            end
        end
        for id, actor in pairs(calibrationFillActors) do
            if isObjValid(actor) then
                assignedActors = assignedActors or getAssignedActors()
                local data = assignedActors and assignedActors[id] or nil
                local key = tostring(id)
                local record = ledgerById[key] or ledgerRecords[key]
                local identity = fillIdentityForActor(actor)
                if stopInteractionForNpc then
                    pcall(function() stopInteractionForNpc(actor, reason or "developer_fill_cleanup") end)
                end
                if releaseStationForNpc then
                    pcall(function() releaseStationForNpc(actor, reason or "developer_fill_cleanup") end)
                end
                pcall(function()
                    actor:sendEvent("StopInteractionObject", {
                        reason = reason or "developer_fill_cleanup",
                        forceClearSleepAnimation = true,
                    })
                end)
                pcall(function()
                    actor:sendEvent("SitDownPleaseClearBriefTravel", { reason = reason or "developer_fill_cleanup" })
                end)
                local generated = record and record.generated == true
                local restoreStatus = "not_needed"
                if generated then
                    local okRemove = pcall(function() actor:remove() end)
                    if not okRemove then
                        okRemove = pcall(function() actor.enabled = false end)
                    end
                    if okRemove then
                        removed = removed + 1
                        restoreStatus = "generated_removed"
                    else
                        failed = failed + 1
                        restoreStatus = "generated_remove_failed"
                    end
                else
                    local origin = record and originTracker.loadVector(record.origin) or nil
                    local rotation = record and record.originYaw and util.transform.rotateZ(tonumber(record.originYaw) or 0)
                        or data and data.preInteractionRot
                        or actor.rotation
                    if not origin and data and data.preInteractionPos then
                        origin = data.preInteractionPos
                    end
                    if origin and actor.cell then
                        local okReturn = pcall(function()
                            actor:teleport(actor.cell, origin, { rotation = rotation, onGround = true })
                        end)
                        if okReturn then
                            returned = returned + 1
                            restoreStatus = "borrowed_restored"
                        else
                            failed = failed + 1
                            restoreStatus = "borrowed_restore_failed"
                        end
                    else
                        failed = failed + 1
                        restoreStatus = origin and "borrowed_restore_missing_cell" or "borrowed_restore_missing_origin"
                    end
                end
                infoLog(
                    "developer calibration fill actor cleanup",
                    tostring(record and record.fillLabel or (identity and identity.label) or actor.recordId or actor.id),
                    "source", tostring(record and record.fillSource or nil),
                    "generated", tostring(generated == true),
                    "restoreStatus", tostring(restoreStatus),
                    "reason", tostring(reason or "developer_fill_cleanup")
                )
                stopped = stopped + 1
                if restoreStatus:find("_failed", 1, true) == nil
                    and restoreStatus ~= "borrowed_restore_missing_cell"
                    and restoreStatus ~= "borrowed_restore_missing_origin" then
                    ledgerRecords[tostring(id)] = nil
                    calibrationActorIdentities[tostring(id)] = nil
                    markCleanedCalibrationActor(cleanedIds, id, actor, identity)
                end
            end
            calibrationFillActors[id] = nil
        end
        writeCalibrationFillLedger(ledgerRecords)
        if stopped > 0 then
            infoLog("developer calibration fill assignments cleared", "count", tostring(stopped), "borrowedRestored", tostring(returned), "generatedRemoved", tostring(removed), "failed", tostring(failed), "reason", tostring(reason or "developer_fill_cleanup"))
        end
        return stopped, returned, removed, failed, cleanedIds
    end

    local function removeCalibrationTestNpc(reason, player, options)
        options = options or {}
        local stopped, restoredFill, removedFill, failedFill, cleanedFillIds = clearCalibrationFillAssignments(reason or "developer_test_npc_removed", player)
        local removed = 0
        for id, npc in pairs(calibrationTestNpcs) do
            if cleanedCalibrationActor(cleanedFillIds, id, npc) then
                -- Fill cleanup already removed/restored this generated actor.
            elseif removeOneCalibrationTestNpc(npc, reason) then
                removed = removed + 1
            end
            calibrationTestNpcs[id] = nil
        end
        local npc = calibrationTestNpc
        calibrationTestNpc = nil
        if removed == 0
            and not cleanedCalibrationActor(cleanedFillIds, nil, npc)
            and isObjValid(npc)
            and removeOneCalibrationTestNpc(npc, reason) then
            removed = removed + 1
        end
        local seen = {}
        if npc and npc.id then seen[tostring(npc.id)] = true end
        for _, fallbackNpc in ipairs(collectCurrentCellCalibrationTestNpcs(player)) do
            local fallbackId = fallbackNpc.id and tostring(fallbackNpc.id) or nil
            if fallbackId and not seen[fallbackId] then
                seen[fallbackId] = true
                if cleanedCalibrationActor(cleanedFillIds, fallbackId, fallbackNpc) then
                    -- Already handled by fill cleanup.
                elseif removeOneCalibrationTestNpc(fallbackNpc, reason or "developer_test_npc_removed_after_reloadlua") then
                    removed = removed + 1
                end
            elseif not fallbackId and not cleanedCalibrationActor(cleanedFillIds, nil, fallbackNpc) then
                if removeOneCalibrationTestNpc(fallbackNpc, reason or "developer_test_npc_removed_after_reloadlua") then
                    removed = removed + 1
                end
            end
        end
        if removed > 0 or stopped > 0 then
            clearRelevantObjectCache("developer_test_npc_removed")
        end
        if removed > 0 then
            if options.silent ~= true then
                infoLog("developer calibration test npc removed", "records", table.concat(CALIBRATION_TEST_NPC_RECORDS, ","), "count", tostring(removed), "reason", tostring(reason or "manual"))
            end
        end
        if stopped > 0 then
            local parts = {}
            if (tonumber(removedFill) or 0) > 0 then parts[#parts + 1] = "removed " .. tostring(removedFill) .. " generated fill" end
            if (tonumber(restoredFill) or 0) > 0 then parts[#parts + 1] = "restored " .. tostring(restoredFill) .. " borrowed" end
            if removed > 0 then
                parts[#parts + 1] = removed == 1 and "removed 1 test NPC" or ("removed " .. tostring(removed) .. " test NPCs")
            end
            if (tonumber(failedFill) or 0) > 0 then parts[#parts + 1] = "failed " .. tostring(failedFill) end
            local detail = #parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or ""
            return true, options.silent == true and nil or ("Cleaned up " .. tostring(stopped) .. " fill assignments" .. detail .. ".")
        end
        if removed > 0 then
            if removed == 1 then
                return true, options.silent == true and nil or "Removed 1 test NPC."
            end
            return true, options.silent == true and nil or ("Removed " .. tostring(removed) .. " test NPCs.")
        end
        if options.silent == true then return false, nil end
        return false, "No spawned test NPC to remove."
    end

    local function restoreSelectedBorrowedTarget(actor, session, assignment, record, reason)
        if not (actor and actor.id) then return false, "missing_actor" end
        local origin = record and originTracker.loadVector(record.origin) or nil
        local rotation = record and record.originYaw and util.transform.rotateZ(tonumber(record.originYaw) or 0)
            or assignment and assignment.preInteractionRot
            or actor.rotation
        if not origin and assignment and assignment.preInteractionPos then
            origin = assignment.preInteractionPos
        end

        local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
        if stopInteractionForNpc then
            pcall(function() stopInteractionForNpc(actor, reason or "developer_menu_shift_clear_target", actor.id) end)
        end
        if releaseStationForNpc then
            pcall(function() releaseStationForNpc(actor, reason or "developer_menu_shift_clear_target") end)
        end
        pcall(function()
            actor:sendEvent("StopInteractionObject", {
                reason = reason or "developer_menu_shift_clear_target",
                interactionType = session and session.interactionType,
                forceClearSleepAnimation = true,
            })
        end)
        pcall(function()
            actor:sendEvent("SitDownPleaseClearBriefTravel", { reason = reason or "developer_menu_shift_clear_target" })
        end)

        local restoreStatus
        if origin and actor.cell then
            local okReturn = pcall(function()
                actor:teleport(actor.cell, origin, { rotation = rotation, onGround = true })
            end)
            if okReturn then
                restoreStatus = "borrowed_restored"
                forgetCalibrationFillLedgerActor(actor)
            else
                restoreStatus = "borrowed_restore_failed"
            end
        else
            restoreStatus = origin and "borrowed_restore_missing_cell" or "borrowed_restore_missing_origin"
        end

        infoLog(
            restoreStatus == "borrowed_restored" and "calibration_shift_clear_target_borrowed_restored" or "calibration_shift_clear_target_borrowed_restore_failed",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(session and session.interactionType),
            "object", tostring(session and (session.objectId or session.objectRecordId)),
            "slot", tostring(session and (session.slotName or session.slotKey)),
            "restoreStatus", tostring(restoreStatus),
            "reason", tostring(reason or "developer_menu_shift_clear_target")
        )
        return restoreStatus == "borrowed_restored", restoreStatus
    end

    local function shiftClearSelectedCalibrationActorTarget(session, actor, reason)
        if not (session and actor and actor.id) then return false, nil end
        local key = tostring(actor.id)
        local record = readCalibrationFillLedger()[key]
        local recordId = actor.recordId and string.lower(tostring(actor.recordId)) or ""
        local generated = (record and record.generated == true) or isCalibrationTestNpcRecord(recordId)
        if generated then
            local removed = removeOneCalibrationTestNpc(actor, reason or "developer_menu_shift_clear_target")
            infoLog(
                removed and "calibration_shift_clear_target_generated_removed" or "calibration_shift_clear_target_generated_remove_failed",
                "actor", tostring(actor.recordId or actor.id),
                "type", tostring(session.interactionType),
                "object", tostring(session.objectId or session.objectRecordId),
                "slot", tostring(session.slotName or session.slotKey),
                "reason", tostring(reason or "developer_menu_shift_clear_target")
            )
            return true, removed and "Target cleared and generated actor removed." or "Target cleared; generated actor removal failed."
        end

        local assignment = currentAssignmentForSession(session)
        local borrowed = (record and record.generated ~= true)
            or (assignment and assignment.calibrationFill == true and assignment.calibrationTestNpc ~= true)
            or (assignment and assignment.calibrationFillSource == "borrowed")
        if borrowed then
            local restored, restoreStatus = restoreSelectedBorrowedTarget(actor, session, assignment, record, reason)
            return true, restored and "Target cleared and borrowed NPC restored." or ("Target cleared; borrowed NPC restore failed (" .. tostring(restoreStatus) .. ").")
        end
        return false, nil
    end

    local function spawnCalibrationTestNpcAt(player, spawnPos, rotation, reason, options)
        options = options or {}
        if not (player and player.cell and player.position) then
            return nil, "Player position is not available."
        end
        local requestedRecord = options.recordId or (options.variedRecord == true and nextCalibrationFillRecordId()) or "ken"
        local attemptedRecords = { requestedRecord }
        if requestedRecord ~= "ken" then attemptedRecords[#attemptedRecords + 1] = "ken" end
        local npcOrErr = nil
        local createdRecord = nil
        for _, recordId in ipairs(attemptedRecords) do
            local okCreate, createdOrErr = pcall(function()
                return world.createObject(recordId, 1)
            end)
            if okCreate and createdOrErr then
                npcOrErr = createdOrErr
                createdRecord = recordId
                break
            end
            npcOrErr = createdOrErr
        end
        if not npcOrErr then
            infoLog("developer calibration test npc spawn failed", tostring(npcOrErr))
            return nil, "Could not create a calibration test NPC. Check that vanilla test NPC records are available."
        end

        local npc = npcOrErr
        spawnPos = spawnPos or (player.position + playerForwardVector(player) * 120 + util.vector3(0, 0, 8))
        local okTeleport, teleportErr = pcall(function()
            npc:teleport(player.cell, spawnPos, { rotation = rotation or player.rotation, onGround = true })
        end)
        if not okTeleport then
            pcall(function() npc:remove() end)
            infoLog("developer calibration test npc teleport failed", tostring(teleportErr))
            return nil, "Created " .. calibrationTestNpcName(createdRecord) .. ", but could not place them near the player."
        end
        registerCalibrationTestNpc(npc)
        local identity = nil
        if options.identityRole then
            identity = assignCalibrationActorIdentity(npc, options.identityRole, true)
            rememberCalibrationFillLedger(npc, nil, true, identity)
        end
        clearRelevantObjectCache("developer_test_npc_spawned")
        infoLog("developer calibration test npc spawned", tostring(identity and identity.label or createdRecord or npc.recordId or "unknown"), "record", tostring(createdRecord or npc.recordId or "unknown"), "cell", tostring(cellName(player.cell)), "position", tostring(spawnPos), "reason", tostring(reason or "spawn_test"), "source", "generated", "runtimeObject", tostring(identity and identity.runtimeObjectId or actorRuntimeObjectId(npc)))
        return npc, "Spawned " .. tostring(identity and identity.label or calibrationTestNpcName(createdRecord)) .. "."
    end

    local function candidateTargetPosition(candidate, interactionType)
        if not (candidate and candidate.object) then return nil end
        local obj = candidate.object
        local profile = candidate.profile or {}
        local slot = candidate.slot or {}
        local kind = interactionType or candidate.interactionType
        if kind == "sleeping" then
            local offset = slot.sleepRootLocalOffset or profile.sleepRootLocalOffset or slot.sleepOffset or profile.sleepOffset
            if offset then
                local ok, pos = pcall(function()
                    return obj.position + obj.rotation * util.vector3(offset.x or 0, offset.y or 0, offset.z or 0)
                end)
                if ok and pos then return pos end
            end
        elseif kind == "sitting" then
            return candidate.finalPosition or candidate.position or candidate.approachPos or obj.position
        elseif kind == "station" then
            return candidate.stationPosition or candidate.position or obj.position
        elseif candidate.approachPos then
            return candidate.approachPos
        end
        return obj.position
    end

    local function sittingFillSpawnPosition(candidate)
        if not candidate then return nil, nil end
        if candidate.approachPos then
            return candidate.approachPos + util.vector3(0, 0, 8), "approach"
        end
        local targetPos = candidateTargetPosition(candidate)
        if not targetPos then return nil, nil end
        local standPos = sittingStandExit.primary({
            object = candidate.object,
            finalPosition = targetPos,
            position = targetPos,
            facingDirection = candidate.preferredFacingDirection,
            facingObjectPosition = candidate.facingObjectPosition,
            approachPos = candidate.approachPos,
            seatCategory = candidate.releaseSafetyGateFurnitureType,
        }, util)
        if standPos then
            return standPos + util.vector3(0, 0, 8), "stand_side"
        end
        return nil, nil
    end

    local function roundedPositionPart(value)
        value = tonumber(value) or 0
        return tostring(math.floor(value + (value >= 0 and 0.5 or -0.5)))
    end

    local function fillTargetReservationKey(target)
        local candidate = target and target.candidate
        if not candidate then return nil end
        local interactionType = tostring(target.interactionType or candidate.interactionType or "unknown")
        local slotName = tostring(candidate.slotName or candidate.slotKey or "default")
        local pos = candidateTargetPosition(candidate, interactionType)
        if pos then
            return table.concat({
                interactionType,
                slotName,
                roundedPositionPart(pos.x),
                roundedPositionPart(pos.y),
                roundedPositionPart(pos.z),
            }, "::")
        end
        if candidate.slotKey then
            return interactionType .. "::" .. tostring(candidate.slotKey)
        end
        return nil
    end

    local function candidateDistanceToPlayer(candidate, player, interactionType)
        local pos = candidateTargetPosition(candidate, interactionType)
        if not (pos and player and player.position) then return math.huge end
        return (pos - player.position):length()
    end

    local function pointDistance(a, b)
        if not (a and b) then return math.huge end
        local ok, value = pcall(function() return (a - b):length() end)
        return ok and value or math.huge
    end

    local function flatDistanceAndVertical(a, b)
        if not (a and b) then return math.huge, math.huge end
        local dx = (a.x or 0) - (b.x or 0)
        local dy = (a.y or 0) - (b.y or 0)
        local dz = math.abs((a.z or 0) - (b.z or 0))
        return math.sqrt((dx * dx) + (dy * dy)), dz
    end

    local function objectIsNpc(obj)
        if not (obj and types and types.NPC and types.NPC.objectIsInstance) then return false end
        local ok, isNpc = pcall(types.NPC.objectIsInstance, obj)
        return ok and isNpc == true
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
        if candidate.interactionType == "sleeping" and raw == "sleep_top" then return "top bunk" end
        if candidate.interactionType == "sleeping" and raw == "sleep_bottom" then return "bottom bunk" end
        if candidate.interactionType == "sleeping" and (bedType == "bottom_bunk" or bedType == "top_bunk") and raw == "sleep_main" then
            return bedType == "top_bunk" and "top bunk" or "bottom bunk"
        end
        if raw == "default" then
            if candidate.interactionType == "sleeping" and bedType == "double" then return "bed slot A" end
            return candidate.interactionType == "sleeping" and "main bed slot" or "main seat"
        end
        if raw == "sleep_main" then
            return bedType == "double" and "bed slot A" or "main bed slot"
        end
        if raw == "sleep_left" then return "left bed slot" end
        if raw == "sleep_right" then return "right bed slot" end
        if raw == "sleep_a" then return "bed slot A" end
        if raw == "sleep_b" then return "bed slot B" end
        if candidate.interactionType == "station" then return raw == "default" and "station" or raw end
        if raw == "seat_a" then return "seat A" end
        if raw == "seat_b" then return "seat B" end
        if raw == "seat_c" then return "seat C" end
        return raw
    end

    local function stationFailureCategory(reason)
        reason = tostring(reason or "unknown")
        if reason == "station_already_claimed" or reason == "station_claim_pending" or reason == "already_stationed" or reason == "station_actor_pending" then
            return "already occupied"
        end
        if reason == "missing_station_profile" then return "no station profile" end
        if reason == "missing_station_geometry" or reason == "missing_station_cell" then return "no slot" end
        if reason:find("teleport_failed", 1, true) then return "transform failed" end
        if reason == "pathing_failed" or reason == "pathing" then return "path failed" end
        if reason == "unsupported_interaction_type" then return "unsupported target type" end
        if reason == "follower" or reason == "active_follow_or_escort_package" or reason == "escort_or_follow_package" then return "no non-follower presenter" end
        if reason == "no_presenter_candidate" then return "no non-follower presenter" end
        if reason == "not_station_eligible" or reason == "station_chance_rejected" or reason == "invalid_station_actor" then return "presenter rejected" end
        return "station assignment failed"
    end

    local function stationFailureMessage(reason, prefix)
        local category = stationFailureCategory(reason)
        return tostring(prefix or "Station assignment failed") .. ": " .. category .. " (" .. tostring(reason or "unknown") .. ")."
    end

    local function stationClaimOptions(overrides)
        overrides = overrides or {}
        return {
            testingOverride = overrides.testingOverride ~= false,
            calibrationAction = overrides.calibrationAction ~= false,
            immediatePlacement = overrides.immediatePlacement == true,
            forcePathing = overrides.forcePathing == true,
            forcePathingImmediateRadius = overrides.forcePathingImmediateRadius,
            suppressAudience = overrides.suppressAudience ~= false,
            lectureStartRequested = overrides.lectureStartRequested == true,
            lectureDebugShortcut = overrides.lectureDebugShortcut == true,
            lectureTeleportAudience = overrides.lectureTeleportAudience == true,
            lectureSource = overrides.lectureSource,
        }
    end

    local function stationStartLectureOptions(ev)
        local teleportAudience = ev and (
            ev.teleportAudience == true
            or ev.shiftDown == true
            or ev.shift == true
            or ev.shiftKey == true
        )
        return {
            debugShortcut = true,
            teleportAudience = teleportAudience == true,
        }
    end

    local function claimStationTarget(target, actor, options)
        if not claimStationWithNpc then return false, "station_claim_unavailable" end
        return claimStationWithNpc(target, actor, options or stationClaimOptions())
    end

    local function stationCandidateForSession(data)
        if not (data and data.object and data.slotKey) then return nil end
        return {
            interactionType = "station",
            object = data.object,
            objectId = data.objectId,
            objectRecordId = data.objectRecordId,
            model = data.model,
            slotKey = data.slotKey,
            slotName = data.slotName,
            slot = data.slot,
            stationPosition = data.stationPosition or data.position,
            position = data.position,
            profile = data.profile,
            profileId = data.profileId,
            finalPosition = data.finalPosition,
            facingDirection = data.facingDirection,
            facingKind = data.facingKind,
            facingObjectId = data.facingObjectId,
            facingObjectScale = data.facingObjectScale,
            facingObjectPosition = data.facingObjectPosition,
        }
    end

    local function collectStationTargets(player, options)
        options = options or {}
        local out = {}
        local seen = {}
        if not (player and player.cell and player.cell.getAll) then return out end
        local function addData(data, source)
            local candidate = stationCandidateForSession(data)
            local slotKey = candidate and candidate.slotKey
            if not (candidate and slotKey and not seen[slotKey]) then return end
            seen[slotKey] = true
            local assigned, pending = stationSlotOccupied(slotKey)
            if (assigned or pending) and options.allowOccupied ~= true then
                debugLog("station target skipped", "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName), "reason", assigned and "station_already_claimed" or "station_claim_pending")
                return
            end
            out[#out + 1] = {
                candidate = candidate,
                interactionType = "station",
                distance = candidateDistanceToPlayer(candidate, player),
                source = source,
                occupied = assigned == true,
                pending = pending == true,
            }
        end
        local lookTarget = isObjValid(options.lookTarget) and options.lookTarget or nil
        if lookTargetActorKind(lookTarget) and stationDataForNpc then
            local stationData = stationDataForNpc(lookTarget)
            if stationData and stationData.object then
                addData(stationSessionDataForObjectWithActor(player, stationData.object, lookTarget), "look_actor_station")
            end
        end
        if isObjValid(lookTarget) then
            addData(stationSessionDataForObjectWithActor(player, lookTarget), "look_station_object")
        end
        local okObjects, objects = pcall(function() return player.cell:getAll() end)
        if okObjects and objects then
            for _, obj in ipairs(objects) do
                if isObjValid(obj) then addData(stationSessionDataForObject(obj), "cell_scan") end
            end
        end
        return out
    end

    local function chooseNearestCandidateForPlayer(player, interactionTypes, options)
        options = options or {}
        local best = nil
        local lookedBest = nil
        local targetRadius = tonumber(options.targetRadius or 1200) or 1200
        local lookTargetRadius = tonumber(options.lookTargetRadius or 2200) or 2200
        local lookTarget = isObjValid(options.lookTarget) and options.lookTarget or nil
        local lookTargetPos = options.lookTargetPos
        local useFacingBias = options.useFacingBias == true
        local useTypeBias = options.useTypeBias == true
        local debugSelection = options.debugSelection == true
        local logPrefix = tostring(options.logTagPrefix or "nearest_manual_assign")
        for typeIndex, candidateType in ipairs(interactionTypes or {}) do
            local candidates = candidateType == "station"
                and collectStationTargets(player, { lookTarget = lookTarget, allowOccupied = options.allowOccupiedStations == true })
                or buildCandidateSlots(player.cell, candidateType, { ignoreTimeGate = true, manualAssign = true, calibrationAction = true, allowOccupiedByTestNpc = true })
            for _, candidate in ipairs(candidates or {}) do
                local targetEntry = candidate.candidate and candidate or nil
                candidate = targetEntry and targetEntry.candidate or candidate
                local slotKey = candidate and candidate.slotKey
                local occupied = candidateType == "station" and false or isSlotOccupied(slotKey)
                if candidate and candidate.object and isObjValid(candidate.object) and (not options.avoidSlotKey or slotKey ~= options.avoidSlotKey) and (not occupied or candidate.occupiedByTestNpc == true) then
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
                        debugLog(logPrefix .. "_target_override_candidate", tostring(candidateType), tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "reason", tostring(accessBlockReason))
                    elseif candidateType == "sleeping" and sleepBedAccess.shouldRestrictDoorAssist(player.cell, false, false) then
                        candidate.disallowSleepDoorAssist = true
                    end
                    local dist = targetEntry and targetEntry.distance or candidateDistanceToPlayer(candidate, player)
                    local slotDistance = lookTargetPos and pointDistance(candidateTargetPosition(candidate), lookTargetPos) or math.huge
                    local objectHitDistance = lookTargetPos and pointDistance(candidate.object.position, lookTargetPos) or math.huge
                    local directLookedFurniture = lookTarget ~= nil
                        and (candidate.object == lookTarget or (lookTargetPos ~= nil and sameObject(candidate.object, lookTarget) and objectHitDistance <= 960))
                    local lookedTargetMatches = directLookedFurniture
                        and (dist <= lookTargetRadius or slotDistance <= 420)
                    if lookedTargetMatches then
                        local lookScore = slotDistance + (dist * 0.001) + (typeIndex * 0.001)
                        if debugSelection then
                            debugLog(
                                logPrefix .. "_look_target_candidate",
                                "type", tostring(candidateType),
                                "object", tostring(candidate.objectId),
                                "slot", tostring(candidateSlotLabel(candidate)),
                                "slotDistance", tostring(slotDistance),
                                "playerDistance", tostring(dist),
                                "score", tostring(lookScore)
                            )
                        end
                        if not lookedBest or lookScore < lookedBest.score then
                            lookedBest = {
                                candidate = candidate,
                                interactionType = candidateType,
                                targetDistance = dist,
                                score = lookScore,
                                facingBias = 0,
                                typeBias = 0,
                                lookTargetUsed = true,
                                lookTargetSlotDistance = slotDistance,
                            }
                        end
                    end
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
                                logPrefix .. "_target_candidate",
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
                    debugLog(logPrefix .. "_target_skipped", tostring(candidateType), tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "reason", "occupied_slot")
                    if options.logAssignNearestEvents == true then
                        infoLog(
                            "assign_nearest_candidate_rejected",
                            "type", tostring(candidateType),
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidateSlotLabel(candidate)),
                            "reason", "occupied_slot",
                            "furnitureSource", tostring(objectContentFile(candidate.object) or "dynamic / unknown"),
                            "furnitureModel", tostring(objectModelPath(candidate.object))
                        )
                    end
                end
            end
        end
        if lookedBest then
            debugLog(
                logPrefix .. "_look_target_selected",
                tostring(lookedBest.interactionType),
                tostring(lookedBest.candidate and lookedBest.candidate.objectId),
                "slot", tostring(lookedBest.candidate and candidateSlotLabel(lookedBest.candidate)),
                "score", tostring(lookedBest.score)
            )
            return lookedBest
        end
        return best
    end

    local function spawnAndAssignCalibrationTestNpc(interactionType, player, options)
        options = options or {}
        if interactionType == "station" then
            local selectedStation = calibrationLock.session and calibrationLock.session.interactionType == "station" and calibrationLock.session or nil
            local target = selectedStation == nil and chooseNearestCandidateForPlayer(player, { "station" }, {
                targetRadius = 1200,
                lookTarget = options.lookTarget,
                lookTargetPos = options.lookTargetPos,
                debugSelection = true,
            }) or nil
            local session = selectedStation
                or (target and target.candidate and target.candidate.object and calibrationLock.captureStationTarget(stationSessionDataForObject(target.candidate.object), calibrationContext(), "developer_station_spawn_test_target_first"))
                or captureStationSession(player, options.lookTarget, options.lookTargetPos)
            if not session then
                infoLog("station assign failed", "action", "spawn_test", "reason", "no_valid_station_slot")
                return false, "No station target found nearby. Look at or stand near a profiled station, then try again."
            end
            local stationPos = session.stationPosition or session.position or (session.object and session.object.position)
            local npc, spawnMessage = spawnCalibrationTestNpcAt(player, stationPos and (stationPos + util.vector3(0, 0, 12)) or nil, player.rotation, "spawn_station_test", { variedRecord = true, identityRole = "test" })
            if not npc then return false, spawnMessage end
            local ok, reason = claimStationTarget(session, npc, stationClaimOptions())
            if not ok then
                removeOneCalibrationTestNpc(npc, "station_spawn_claim_failed")
                infoLog("station assign failed", "action", "spawn_test", "object", tostring(session.objectId), "slot", tostring(session.slotName), "reason", tostring(reason), "category", stationFailureCategory(reason))
                return false, stationFailureMessage(reason, "Spawned a test NPC, but could not assign station")
            end
            calibrationLock.captureStationTarget(stationSessionDataForObject(session.object, npc), calibrationContext(), "developer_station_spawn_test")
            return true, spawnMessage .. " Sent them to the selected station.", sessionStatusPayload(calibrationLock.session)
        end
        local target = chooseNearestCandidateForPlayer(player, { interactionType }, {
            targetRadius = 1200,
            lookTarget = options.lookTarget,
            lookTargetPos = options.lookTargetPos,
            debugSelection = true,
        })
        if not target then
            local label = interactionType == "sleeping" and "bed" or "seat"
            return false, "No free " .. label .. " found near you. Stand closer to the furniture and try again."
        end

        local spawnPos, spawnPlacement = nil, nil
        if interactionType == "sitting" then
            spawnPos, spawnPlacement = sittingFillSpawnPosition(target.candidate)
        end
        if not spawnPos then
            spawnPos = candidateTargetPosition(target.candidate)
            spawnPlacement = spawnPos and "target_direct" or "player_fallback"
        end
        removeCalibrationTestNpc("replace_test_npc", player, { silent = true })
        local placedSpawnPos = spawnPlacement == "target_direct"
            and (spawnPos and (spawnPos + util.vector3(0, 0, 12)) or nil)
            or spawnPos
        local npc, spawnMessage = spawnCalibrationTestNpcAt(player, placedSpawnPos, player.rotation, "spawn_test", { identityRole = "test" })
        if not npc then return false, spawnMessage end

        local candidate = target.candidate
        candidate.calibrationAction = true
        candidate.calibrationReason = "developer_test_npc_target_first"
        candidate.ignoreTimeGate = true
        candidate.manualAssign = true
        candidate.manualAssignOverrideTesting = true
        candidate.calibrationTestNpc = true
        applyCalibrationActorIdentity(candidate, npc)
        sendConsiderInteraction(npc, candidate)
        manualAssignment.logRouteStarted(infoLog, npc, candidate)
        rememberPendingCalibrationTarget(npc, candidate, "developer_test_npc_pending")
        infoLog("developer calibration test npc target-first assign", tostring((fillIdentityForActor(npc) and fillIdentityForActor(npc).label) or npc.recordId or npc.id or "test_npc"), "type", tostring(interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "targetDistance", tostring(target.targetDistance), "lookTargetUsed", tostring(target.lookTargetUsed == true), "spawnPosition", tostring(placedSpawnPos), "spawnPlacement", tostring(spawnPlacement))
        local label = interactionType == "sleeping" and "bed" or "seat"
        local targetText = target.lookTargetUsed == true and ("the looked-at " .. label) or ("the nearest " .. label .. " near you")
        return true, spawnMessage .. " Sent him to " .. targetText .. " and made him the active calibration target.", sessionStatusPayload(calibrationLock.session)
    end

    local function actorDeadReason(npc)
        return assignmentEligibility.actorDeadReason(npc, types)
    end

    local function nearestManualInteractionTypes(filterMode)
        if filterMode == "sleeping" then return { "sleeping" } end
        if filterMode == "sitting" then return { "sitting" } end
        if filterMode == "station" then return { "station" } end
        return { "sleeping", "sitting", "station" }
    end

    local function fillCellInteractionTypes(filterMode)
        if filterMode == "sleeping" then return { "sleeping" } end
        if filterMode == "sitting" then return { "sitting" } end
        if filterMode == "station" then return { "station" } end
        -- Auto Fill Cell is for release smoke-testing beds and seats. Stations
        -- are more fragile debug targets and should only be spawned when the
        -- Station filter is explicit; otherwise a cell fill can create lecturer
        -- actors that look like stool/seat targets after the station start fails.
        return { "sleeping", "sitting" }
    end

    local function noFreeTargetMessage(filterMode)
        if filterMode == "sleeping" then
            return "No free bed was found near you. Stand closer to the bed you want to test."
        end
        if filterMode == "sitting" then
            return "No free seat was found near you. Stand closer to the seat you want to test."
        end
        if filterMode == "station" then
            return "No free station was found near you. Stand closer to the station you want to test."
        end
        return "No free bed, seat, or station was found near you. Stand closer to the furniture you want to test."
    end

    local function targetFromCurrentSession(filterMode, player)
        local session = calibrationLock.currentSession(filterMode or "auto", calibrationContext())
        if not (session and session.object and session.slotKey) then return nil end
        if session.interactionType == "station" then
            local candidate = stationCandidateForSession(session)
            if candidate then
                return {
                    candidate = candidate,
                    interactionType = "station",
                    targetDistance = candidateDistanceToPlayer(candidate, player),
                    score = -1000000,
                    selectedSessionUsed = true,
                }
            end
            return nil
        end
        if session.interactionType ~= "sitting" and session.interactionType ~= "sleeping" then return nil end
        local candidate = furnitureSessionDataForCandidate(session, session.actor)
        if candidate then
            return {
                candidate = candidate,
                interactionType = session.interactionType,
                targetDistance = candidateDistanceToPlayer(candidate, player),
                score = -1000000,
                selectedSessionUsed = true,
            }
        end
        return nil
    end

    local function captureCandidateTarget(target, reason)
        local candidate = target and target.candidate or nil
        if not candidate then return nil end
        if target.interactionType == "station" then
            return calibrationLock.captureStationTarget(stationSessionDataForObjectWithActor(world.players and world.players[1], candidate.object, candidate.actor or candidate.npc), calibrationContext(), reason or "menu_capture_candidate_station")
        end
        local data = furnitureSessionDataForCandidate(candidate)
        if not data then return nil end
        return calibrationLock.captureFurnitureTarget(data, calibrationContext(), reason or "menu_capture_candidate")
    end

    local function captureNearestCandidateTarget(filterMode, player, options)
        options = options or {}
        local interactionTypes = nearestManualInteractionTypes(filterMode)
        local target = chooseNearestCandidateForPlayer(player, interactionTypes, {
            targetRadius = tonumber(options.targetRadius or 1400) or 1400,
            lookTargetRadius = tonumber(options.lookTargetRadius or 2200) or 2200,
            lookTarget = options.lookTarget,
            lookTargetPos = options.lookTargetPos,
            useFacingBias = options.useFacingBias == true,
            useTypeBias = filterMode == "auto",
            debugSelection = true,
            allowOccupiedStations = true,
            logTagPrefix = "calibration_target_select",
        })
        if not target then return nil end
        local session = captureCandidateTarget(target, options.reason or "menu_capture_empty_or_candidate")
        if session then
            local candidate = target.candidate
            infoLog("calibration furniture target selected", "type", tostring(target.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidateSlotLabel(candidate)), "lookTargetUsed", tostring(target.lookTargetUsed == true), "reason", tostring(options.reason or "menu_capture_empty_or_candidate"), "furnitureSource", tostring(objectContentFile(candidate and candidate.object) or "dynamic / unknown"), "furnitureModel", tostring(objectModelPath(candidate and candidate.object)), "blockerReason", tostring(candidate and candidate.surfaceBlockerReason), "blockerObject", tostring(candidate and candidate.surfaceBlockerObjectId), "blockerDistance", tostring(candidate and candidate.surfaceBlockerDistance), "blockerVertical", tostring(candidate and candidate.surfaceBlockerVertical), "blockerLocalReason", tostring(candidate and candidate.surfaceBlockerLocalReason))
        end
        return session
    end

    local function captureLookedEmptyFurnitureTarget(filterMode, player, ev, reason)
        if filterMode == "station" or not lookTargetFurnitureKind(ev and ev.lookTarget) then return nil end
        return captureNearestCandidateTarget(filterMode, player, {
            lookTarget = ev.lookTarget,
            lookTargetPos = ev.lookTargetPos,
            targetRadius = 1400,
            reason = reason or "menu_capture_empty_furniture",
        })
    end

    local function cycleTargetKey(target)
        local candidate = target and target.candidate or target
        if not candidate then return "" end
        return tostring(target.interactionType or candidate.interactionType)
            .. "|"
            .. tostring(candidate.slotKey or "")
            .. "|"
            .. tostring(candidate.objectId or candidate.objectRecordId or (candidate.object and candidate.object.recordId) or "")
    end

    local function collectCycleTargets(player, filterMode)
        local out = {}
        local seen = {}
        local typeAllowed = {}
        for _, item in ipairs(nearestManualInteractionTypes(filterMode)) do typeAllowed[item] = true end
        local function addTarget(candidate, interactionType, source)
            if not (candidate and candidate.object and candidate.slotKey and interactionType and typeAllowed[interactionType]) then return end
            local entry = {
                candidate = candidate,
                interactionType = interactionType,
                targetDistance = candidateDistanceToPlayer(candidate, player),
                source = source,
            }
            local key = cycleTargetKey(entry)
            if key == "" or seen[key] then return end
            seen[key] = true
            out[#out + 1] = entry
        end

        for _, data in pairs(getAssignedActors() or {}) do
            if data and data.interactionType and typeAllowed[data.interactionType] then
                local actor = data.npc or data.actor
                local candidate = furnitureSessionDataForCandidate(data, actor)
                if candidate then addTarget(candidate, data.interactionType, "assigned_actor") end
            end
        end

        for _, interactionType in ipairs(nearestManualInteractionTypes(filterMode)) do
            if interactionType == "station" then
                for _, entry in ipairs(collectStationTargets(player, { allowOccupied = true })) do
                    addTarget(entry.candidate, "station", entry.source or "station_scan")
                end
            else
                local candidates = buildCandidateSlots(player.cell, interactionType, { ignoreTimeGate = true, manualAssign = true, calibrationAction = true, allowOccupiedByTestNpc = true })
                for _, candidate in ipairs(candidates or {}) do
                    addTarget(candidate, interactionType, "candidate_scan")
                end
            end
        end

        table.sort(out, function(a, b)
            local ad = tonumber(a.targetDistance) or math.huge
            local bd = tonumber(b.targetDistance) or math.huge
            if math.abs(ad - bd) > 0.01 then return ad < bd end
            local at = tostring(a.interactionType or "")
            local bt = tostring(b.interactionType or "")
            if at ~= bt then return at < bt end
            local ao = tostring(a.candidate and (a.candidate.objectId or a.candidate.objectRecordId or (a.candidate.object and a.candidate.object.recordId)) or "")
            local bo = tostring(b.candidate and (b.candidate.objectId or b.candidate.objectRecordId or (b.candidate.object and b.candidate.object.recordId)) or "")
            if ao ~= bo then return ao < bo end
            return tostring(a.candidate and a.candidate.slotKey or "") < tostring(b.candidate and b.candidate.slotKey or "")
        end)
        return out
    end

    local function cycleCalibrationTarget(filterMode, player)
        if not (player and player.cell) then return nil, "No player cell is available." end
        local targets = collectCycleTargets(player, filterMode)
        if #targets == 0 then return nil, noFreeTargetMessage(filterMode) end
        local session = calibrationLock.currentSession(filterMode or "auto", calibrationContext())
        local currentKey = session and cycleTargetKey(session) or nil
        local nextIndex = 1
        local siblingNextIndex = nil
        if session and session.object and session.slotKey and currentKey then
            local siblingIndices = {}
            local currentSiblingOrdinal = nil
            for index, target in ipairs(targets) do
                local candidate = target and target.candidate
                if candidate and sameFurnitureSession(candidate, session) then
                    siblingIndices[#siblingIndices + 1] = index
                    if cycleTargetKey(target) == currentKey then currentSiblingOrdinal = #siblingIndices end
                end
            end
            if currentSiblingOrdinal and currentSiblingOrdinal < #siblingIndices then
                siblingNextIndex = siblingIndices[currentSiblingOrdinal + 1]
            end
        end
        if currentKey then
            for index, target in ipairs(targets) do
                if cycleTargetKey(target) == currentKey then
                    nextIndex = (index % #targets) + 1
                    break
                end
            end
        end
        if siblingNextIndex then nextIndex = siblingNextIndex end
        local picked = targets[nextIndex]
        local newSession = captureCandidateTarget(picked, "menu_cycle_target")
        if not newSession then return nil, "Could not select the next target." end
        infoLog("calibration target cycled", "filter", tostring(filterMode), "index", tostring(nextIndex), "count", tostring(#targets), "type", tostring(picked.interactionType), "object", tostring(picked.candidate and picked.candidate.objectId), "slot", tostring(picked.candidate and candidateSlotLabel(picked.candidate)))
        return newSession, "Target cycled: " .. calibrationLock.sessionLabel(newSession)
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
        external_control_script = true,
        external_control_movement = true,
        external_control_side_movement = true,
        external_control_jump = true,
        external_control_use = true,
        active_follow_or_escort_package = true,
        escort_or_follow_package = true,
    }

    local function manualNpcEligible(npc, interactionType, options)
        options = options or {}
        if not (npc and npc.id and isObjValid(npc) and npc.position) then return false, "invalid_actor" end
        if not objectEnabled(npc) then return false, "disabled_actor" end
        local dead, deadReason = actorDeadReason(npc)
        if dead then return false, deadReason or "dead_actor" end
        if profiles.externalAnimationNpcReason and profiles.externalAnimationNpcReason(npc) then return false, "external_animation_npc" end
        if profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(npc, { interactionType = interactionType }) then return false, "external_animation_npc" end
        if npcAlreadyAssigned(npc) then
            local recordId = npc.recordId and string.lower(tostring(npc.recordId)) or ""
            if options.allowAssignedTestNpc == true and isCalibrationTestNpcRecord(recordId) then
                return true, nil
            end
            if options.allowAssignedFillNpc == true then
                return true, nil
            end
            return false, "already_assigned"
        end
        if isNpcEligibleForInteraction then
            local ok, allowed, reason = pcall(isNpcEligibleForInteraction, npc, interactionType)
            if not ok then return false, "eligibility_check_failed" end
            if allowed ~= true then
                reason = reason or "ineligible"
                if options.testingOverride == true and not MANUAL_ASSIGN_HARD_REJECTS[tostring(reason)] then
                    debugLog("nearest_manual_assign_eligibility_override", npc.recordId or npc.id, tostring(interactionType), "reason", tostring(reason))
                    return true, nil, tostring(reason)
                end
                return false, reason
            end
        end
        return true, nil
    end

    local function actorOnlyInteractionType(interactionType)
        if interactionType == "sleeping" or interactionType == "station" then return interactionType end
        return "sitting"
    end

    local function selectedActorInteractionTypes(interactionType)
        if interactionType == "sleeping" then return { "sleeping" } end
        if interactionType == "sitting" then return { "sitting" } end
        if interactionType == "station" then return { "station" } end
        return { "sleeping", "sitting" }
    end

    local function captureLooseActorTarget(interactionType, player, actor, reason)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        local effectiveType = actorOnlyInteractionType(interactionType)
        local eligible, rejectReason, overrideReason = manualNpcEligible(actor, effectiveType, { testingOverride = true, allowAssignedTestNpc = true })
        local data = {
            interactionType = effectiveType,
            actor = actor,
            npc = actor,
            actorId = actor.id,
            actorRecordId = actor.recordId,
            actorContentFile = objectContentFile(actor),
            manualAssignOverrideApplied = overrideReason ~= nil,
            manualAssignOverrideReason = overrideReason,
            rejectionReason = eligible and nil or rejectReason,
            hardBlockerReason = eligible and nil or rejectReason,
        }
        applyCalibrationActorIdentity(data, actor)
        local session = calibrationLock.captureActorTarget(data, calibrationContext(), reason or "menu_capture_loose_actor")
        infoLog(
            eligible and "find_target_actor_only_selected" or "find_target_direct_actor_rejected",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(effectiveType),
            "reason", tostring(rejectReason or overrideReason or "ok")
        )
        infoLog(
            "calibration loose actor target selected",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(effectiveType),
            "eligible", tostring(eligible == true),
            "reason", tostring(rejectReason or overrideReason or "ok"),
            "actorSource", tostring(objectContentFile(actor) or "dynamic / unknown")
        )
        return session
    end

    local function captureDirectAssignedActorTarget(interactionType, player, actor)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        local dead = actorDeadReason(actor)
        if not objectEnabled(actor) or dead then return nil end
        if profiles.externalAnimationNpcReason and profiles.externalAnimationNpcReason(actor) then return nil end
        if profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(actor, { interactionType = interactionType }) then return nil end
        for _, data in pairs(getAssignedActors() or {}) do
            local assignedActor = data and (data.npc or data.actor) or nil
            if assignedActor and sameObject(assignedActor, actor) and (interactionType == "auto" or data.interactionType == interactionType) then
                local session = nil
                if data.interactionType == "station" then
                    session = calibrationLock.captureStationTarget(data, calibrationContext(), "find_target_direct_actor")
                else
                    session = calibrationLock.captureFurnitureTarget(furnitureSessionDataForCandidate(data, actor), calibrationContext(), "find_target_direct_actor")
                end
                infoLog(
                    "find_target_direct_actor",
                    "actor", tostring(actor.recordId or actor.id),
                    "type", tostring(data.interactionType),
                    "object", tostring(data.objectId or data.object and data.object.recordId),
                    "slot", tostring(data.slotName or data.slotKey),
                    "mode", "assigned_actor"
                )
                return session
            end
        end
        return nil
    end

    local function externalClaimForActorCandidate(actor, candidate)
        if not (actor and candidate) then return nil end
        if candidate.externalPhysicalClaimed == true and sameObject(candidate.externalPhysicalClaimActor, actor) then
            return candidate.externalPhysicalClaimReason or "external_furniture_claimed", "candidate_claim"
        end
        if profiles.externalAnimationClaimMatch then
            local reason, source, dist, vertical = profiles.externalAnimationClaimMatch(actor, candidate)
            if reason then return reason, source, dist, vertical end
        end
        return nil
    end

    local function externalActorOnlyReason(actor)
        return profiles.externalAnimationNpcReason and profiles.externalAnimationNpcReason(actor) or nil
    end

    local function anyExternalActorReason(actor)
        local actorReason = externalActorOnlyReason(actor)
        if actorReason then return actorReason end
        local sittingReason = profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(actor, { interactionType = "sitting" }) or nil
        if sittingReason then return sittingReason end
        return profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(actor, { interactionType = "sleeping" }) or nil
    end

    local function captureExternalActorOnlyTarget(interactionType, player, actor, reason)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        local claimReason = anyExternalActorReason(actor)
        if not claimReason then return nil end
        local effectiveType = actorOnlyInteractionType(interactionType)
        local data = {
            interactionType = effectiveType,
            actor = actor,
            npc = actor,
            actorId = actor.id,
            actorRecordId = actor.recordId,
            actorContentFile = objectContentFile(actor),
            externalPhysicalClaimed = true,
            externalPhysicalClaimReason = claimReason,
            hardBlockerReason = claimReason,
            rejectionReason = claimReason,
            nudgeEnabled = false,
        }
        applyCalibrationActorIdentity(data, actor)
        local session = calibrationLock.captureActorTarget(data, calibrationContext(), reason or "menu_capture_external_actor_only")
        infoLog(
            "calibration external actor-only target selected",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(effectiveType),
            "claimReason", tostring(claimReason),
            "actorSource", tostring(objectContentFile(actor) or "dynamic / unknown")
        )
        return session
    end

    local function captureExternalActorClaimTarget(interactionType, player, actor, reason)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        if not anyExternalActorReason(actor) then return nil end
        local best, bestScore, bestReason, bestSource, bestDist, bestVertical = nil, nil, nil, nil, nil, nil
        for _, candidateType in ipairs(selectedActorInteractionTypes(interactionType)) do
            if candidateType ~= "station" then
                local candidates = buildCandidateSlots(player.cell, candidateType, { ignoreTimeGate = true, manualAssign = true, calibrationAction = true, allowOccupiedByTestNpc = true })
                for _, candidate in ipairs(candidates or {}) do
                    local claimReason, claimSource, claimDist, claimVertical = externalClaimForActorCandidate(actor, candidate)
                    if claimReason and candidate and candidate.object and candidate.slotKey then
                        local pos = candidateTargetPosition(candidate)
                        local score = pointDistance(actor.position, pos)
                        if not bestScore or score < bestScore then
                            best = candidate
                            bestScore = score
                            bestReason = claimReason
                            bestSource = claimSource
                            bestDist = claimDist
                            bestVertical = claimVertical
                        end
                    end
                end
            end
        end
        if not best then return nil end
        best.externalPhysicalClaimed = true
        best.externalPhysicalClaimReason = bestReason or "external_furniture_claimed"
        best.externalPhysicalClaimActor = actor
        best.externalPhysicalClaimActorRecordId = actor.recordId
        best.externalPhysicalClaimActorId = actor.id
        best.hardBlockerReason = "external_furniture_claimed"
        best.rejectionReason = "external_furniture_claimed"
        local session = calibrationLock.captureFurnitureTarget(furnitureSessionDataForCandidate(best, actor), calibrationContext(), reason or "menu_capture_external_actor_claim")
        infoLog(
            "calibration external actor claim resolved",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(best.interactionType),
            "object", tostring(best.objectId),
            "slot", tostring(candidateSlotLabel(best)),
            "claimReason", tostring(bestReason),
            "claimSource", tostring(bestSource),
            "claimDistance", tostring(bestDist),
            "claimVertical", tostring(bestVertical),
            "furnitureSource", tostring(objectContentFile(best.object) or "dynamic / unknown"),
            "furnitureModel", tostring(objectModelPath(best.object))
        )
        return session
    end

    local function captureNearbyActorFurnitureTarget(interactionType, player, actor, reason)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        local types = selectedActorInteractionTypes(interactionType)
        local target = chooseNearestCandidateForPlayer(actor, types, {
            targetRadius = 260,
            debugSelection = true,
            logTagPrefix = "find_target_actor_nearby",
            logAssignNearestEvents = false,
        })
        local candidate = target and target.candidate or nil
        if not (candidate and candidate.object and candidate.slotKey) then return nil end
        local session = calibrationLock.captureFurnitureTarget(furnitureSessionDataForCandidate(candidate, actor), calibrationContext(), reason or "find_target_actor_nearby_furniture")
        infoLog(
            "find_target_actor_nearby_furniture",
            "actor", tostring(actor.recordId or actor.id),
            "type", tostring(candidate.interactionType),
            "object", tostring(candidate.objectId),
            "slot", tostring(candidateSlotLabel(candidate)),
            "distance", tostring(target and target.targetDistance),
            "furnitureSource", tostring(objectContentFile(candidate.object) or "dynamic / unknown"),
            "furnitureModel", tostring(objectModelPath(candidate.object))
        )
        return session
    end

    local function captureDirectStationActorTarget(player, actor, reason)
        if not (stationDataForNpc and lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        local okStationData, stationData = pcall(stationDataForNpc, actor)
        if not (okStationData and stationData and stationData.object and isObjValid(stationData.object)) then return nil end
        local data = stationSessionDataForObjectWithActor(player, stationData.object, actor)
        if not data then return nil end
        local session = calibrationLock.captureStationTarget(data, calibrationContext(), reason or "find_target_direct_actor_station")
        if session then
            infoLog(
                "find_target_direct_actor_station",
                "actor", tostring(actor.recordId or actor.id),
                "object", tostring(data.objectId),
                "slot", tostring(data.slotName),
                "actorSource", tostring(displayContentFile(actor))
            )
        end
        return session
    end

    local function captureDirectActorTarget(interactionType, player, actor)
        if not (lookTargetActorKind(actor) and player and player.cell and actor.cell == player.cell) then return nil end
        infoLog("find_target_direct_actor", "actor", tostring(actor.recordId or actor.id), "filter", tostring(interactionType))
        local session = captureDirectAssignedActorTarget(interactionType, player, actor)
        if session then return session end
        if interactionType == "auto" or interactionType == "station" then
            session = captureDirectStationActorTarget(player, actor, "find_target_direct_actor")
            if session then return session end
        end
        if interactionType == "station" then
            return captureLooseActorTarget(interactionType, player, actor, "find_target_direct_actor")
        end
        -- Important: resolve known externally seated actors (AM_Writer/AM_Reader/AM_Eater,
        -- MCA readers, VA sitting markers, etc.) against their actual nearby seat first.
        -- Hotfix 3 briefly treated every broad external-animation actor as actor-only here,
        -- which restored the fake-pairing guard but broke AM_Writer seat offsets/calibration.
        session = captureExternalActorClaimTarget(interactionType, player, actor, "find_target_direct_actor")
        if session then return session end
        if anyExternalActorReason(actor) then
            return captureExternalActorOnlyTarget(interactionType, player, actor, "find_target_direct_actor_external_unresolved")
        end
        session = captureNearbyActorFurnitureTarget(interactionType, player, actor, "find_target_direct_actor_nearby_furniture")
        if session then return session end
        return captureLooseActorTarget(interactionType, player, actor, "find_target_direct_actor")
    end

    local function captureViewConeActorTarget(interactionType, player, focusPos)
        if not (player and player.cell and player.position and player.cell.getAll) then return nil end
        if interactionType == "station" then return nil end
        local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
        if not (okList and npcs) then return nil end
        local best, bestScore = nil, nil
        for _, npc in ipairs(npcs) do
            if npc ~= player and isObjValid(npc) and objectEnabled(npc) and npc.position and npc.cell == player.cell then
                local score = viewConeScore(player, npc.position, focusPos)
                if score and (not bestScore or score < bestScore) then
                    best, bestScore = npc, score
                end
            end
        end
        if not best then return nil end
        infoLog("find_target_view_cone_actor", "actor", tostring(best.recordId or best.id), "filter", tostring(interactionType), "score", tostring(bestScore))
        return captureDirectActorTarget(interactionType, player, best)
    end

    local function chooseNearestManualActor(player, npcs, interactionType, options)
        options = options or {}
        local scanRadius = tonumber(options.actorRadius or 1600) or 1600
        local preferredActor = objectIsNpc(options.preferredActor) and options.preferredActor or nil
        local allowAssignedTestNpc = options.allowAssignedTestNpc == true
        if preferredActor and preferredActor ~= player and preferredActor.position and preferredActor.cell == player.cell then
            local dist = (preferredActor.position - player.position):length()
            if dist <= scanRadius then
                local eligible, reason, overrideReason = manualNpcEligible(preferredActor, interactionType, { testingOverride = true, allowAssignedTestNpc = allowAssignedTestNpc })
                if eligible then
                    debugLog("nearest_manual_assign_look_actor_selected", preferredActor.recordId or preferredActor.id, tostring(interactionType), "distance", tostring(dist))
                    return {
                        npc = preferredActor,
                        distance = dist,
                        lookTargetActorUsed = true,
                        manualAssignOverrideApplied = overrideReason ~= nil,
                        manualAssignOverrideReason = overrideReason,
                    }
                end
                debugLog("nearest_manual_assign_look_actor_rejected", tostring(reason), preferredActor.recordId or preferredActor.id, tostring(interactionType))
            end
        end
        local best = nil
        for _, npc in ipairs(npcs or {}) do
            if npc ~= player and npc.position then
                local dist = (npc.position - player.position):length()
                if dist <= scanRadius then
                    local eligible, reason, overrideReason = manualNpcEligible(npc, interactionType, { testingOverride = true, allowAssignedTestNpc = allowAssignedTestNpc })
                    if eligible then
                        if not best or dist < best.distance then
                            best = {
                                npc = npc,
                                distance = dist,
                                manualAssignOverrideApplied = overrideReason ~= nil,
                                manualAssignOverrideReason = overrideReason,
                            }
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
        if interactionType == "station" then
            lectureTrace.log(debugLog, "assign_nearest_station_path_entered", "action", "assign_nearest")
            local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
            if not okList or not npcs then return false, "Could not scan NPCs near you." end
            local target = targetFromCurrentSession("station", player) or chooseNearestCandidateForPlayer(player, { "station" }, {
                targetRadius = tonumber(options.targetRadius or 1200) or 1200,
                lookTarget = options.lookTarget,
                lookTargetPos = options.lookTargetPos,
                debugSelection = true,
                allowOccupiedStations = true,
            })
            if not target then
                infoLog("station assign failed", "action", "assign_nearest", "reason", "no_valid_station_slot")
                return false, "No free station or lectern slot was found nearby. Stand closer to the station you want to test."
            end
            local occupied, pending = stationSlotOccupied(target.candidate and target.candidate.slotKey)
            if occupied then
                local claimed = claimedStationData and claimedStationData(target.candidate.slotKey) or nil
                local session = claimed and calibrationLock.captureStationTarget(stationSessionDataForObjectWithActor(player, claimed.object, claimed.npc), calibrationContext(), "developer_station_assign_nearest_occupied")
                    or calibrationLock.captureStationTarget(stationSessionDataForObjectWithActor(player, target.candidate.object), calibrationContext(), "developer_station_assign_nearest_occupied")
                if claimed and triggerStationLecture then
                    lectureTrace.log(debugLog, "session_start_refresh_called", "path", "assign_nearest_occupied", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotKey))
                    triggerStationLecture(session or calibrationLock.session, { debugShortcut = false })
                end
                infoLog("station assign nearest selected occupied station", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotName), "actor", tostring(claimed and claimed.npc and (claimed.npc.recordId or claimed.npc.id) or "<nearby>"))
                return true, "Selected the occupied station target.", sessionStatusPayload(session or calibrationLock.session)
            elseif pending then
                local session = calibrationLock.captureStationTarget(stationSessionDataForObjectWithActor(player, target.candidate.object), calibrationContext(), "developer_station_assign_nearest_pending")
                infoLog("station assign nearest selected pending station", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotName))
                return true, "Selected the pending station target.", sessionStatusPayload(session or calibrationLock.session)
            end
            local actor = chooseNearestManualActor(player, npcs, "station", {
                actorRadius = tonumber(options.actorRadius or 1600) or 1600,
                preferredActor = options.lookTarget,
            })
            if not actor then
                infoLog("station assign failed", "action", "assign_nearest", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotName), "reason", "no_eligible_npc")
                return false, "Found the station, but no eligible standing NPC was close enough to use as presenter."
            end
            local session = calibrationLock.captureStationTarget(stationSessionDataForObject(target.candidate.object), calibrationContext(), "developer_station_assign_nearest_target_first")
            local ok, reason = claimStationTarget(target.candidate, actor.npc, options.stationClaimOptions or stationClaimOptions({
                calibrationAction = false,
                forcePathing = true,
                forcePathingImmediateRadius = 6,
                lectureStartRequested = true,
                lectureDebugShortcut = false,
                lectureTeleportAudience = false,
                lectureSource = "assign_nearest",
            }))
            if not ok then
                infoLog("station assign failed", "action", "assign_nearest", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotName), "actor", tostring(actor.npc and (actor.npc.recordId or actor.npc.id)), "reason", tostring(reason), "category", stationFailureCategory(reason))
                return false, stationFailureMessage(reason, "Found station and NPC, but could not assign station")
            end
            rememberCalibrationFillLedger(actor.npc, {
                interactionType = "station",
                candidate = {
                    interactionType = "station",
                    object = target.candidate.object,
                    objectId = target.candidate.objectId,
                    slotKey = target.candidate.slotKey,
                    slotName = target.candidate.slotName,
                    stationPosition = target.candidate.stationPosition,
                },
            }, false)
            session = calibrationLock.captureStationTarget(stationSessionDataForObject(target.candidate.object, actor.npc), calibrationContext(), "developer_station_assign_nearest_confirmed") or session or calibrationLock.session
            if reason ~= "pathing" and triggerStationLecture then
                lectureTrace.log(debugLog, "session_start_refresh_called", "path", "assign_nearest_direct", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and target.candidate.slotKey))
                triggerStationLecture(session or calibrationLock.session, { debugShortcut = false, teleportAudience = false })
            end
            local verb = reason == "pathing" and "Sent " or "Assigned "
            local suffix = reason == "pathing" and " toward the selected station." or " to the selected station."
            return true, verb .. tostring(actor.npc.recordId or "nearest NPC") .. suffix, sessionStatusPayload(calibrationLock.session, manualAssignStatusExtra(actor))
        end
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
        local selectedSession = calibrationLock.currentSession(interactionType or "auto", calibrationContext())
        local selectedActor = selectedSession and selectedSession.actor and not selectedSession.object and selectedSession.actor or nil
        if selectedActor then
            infoLog("assign_nearest_selected_actor", "actor", tostring(selectedActor.recordId or selectedActor.id), "filter", tostring(interactionType), "actorSource", tostring(objectContentFile(selectedActor) or "dynamic / unknown"))
            local selectedType = selectedSession.interactionType or actorOnlyInteractionType(interactionType)
            local eligible, actorReason, actorOverrideReason = manualNpcEligible(selectedActor, selectedType, { testingOverride = true, allowAssignedTestNpc = true })
            if not eligible then
                infoLog("assign_nearest_no_valid_candidate", "actor", tostring(selectedActor.recordId or selectedActor.id), "filter", tostring(interactionType), "reason", tostring(actorReason or "actor_ineligible"))
                return false, "Selected actor cannot be assigned: " .. tostring(actorReason or "actor_ineligible")
            end
            interactionTypes = selectedActorInteractionTypes(interactionType)
            local selectedTarget = chooseNearestCandidateForPlayer(selectedActor, interactionTypes, {
                avoidSlotKey = options.avoidSlotKey,
                targetRadius = tonumber(options.targetRadius or 1200) or 1200,
                lookTarget = options.lookTarget,
                lookTargetPos = options.lookTargetPos,
                debugSelection = true,
                logTagPrefix = "assign_nearest",
                logAssignNearestEvents = true,
            })
            if not selectedTarget then
                infoLog("assign_nearest_no_valid_candidate", "actor", tostring(selectedActor.recordId or selectedActor.id), "filter", tostring(interactionType), "reason", "no_free_target")
                return false, noFreeTargetMessage(interactionType)
            end
            local selectedCandidate = selectedTarget.candidate
            infoLog(
                "assign_nearest_candidate_selected",
                "actor", tostring(selectedActor.recordId or selectedActor.id),
                "type", tostring(selectedTarget.interactionType),
                "object", tostring(selectedCandidate and selectedCandidate.objectId),
                "slot", tostring(selectedCandidate and candidateSlotLabel(selectedCandidate)),
                "targetDistance", tostring(selectedTarget.targetDistance),
                "actorSource", tostring(objectContentFile(selectedActor) or "dynamic / unknown"),
                "furnitureSource", tostring(objectContentFile(selectedCandidate and selectedCandidate.object) or "dynamic / unknown"),
                "furnitureModel", tostring(objectModelPath(selectedCandidate and selectedCandidate.object))
            )
            options.selectedActorOverrideReason = actorOverrideReason
            options.selectedActorTarget = selectedTarget
            options.selectedActor = selectedActor
        end
        local target = options.selectedActorTarget or targetFromCurrentSession(interactionType, player) or chooseNearestCandidateForPlayer(player, interactionTypes, {
            avoidSlotKey = options.avoidSlotKey,
            targetRadius = tonumber(options.targetRadius or 1200) or 1200,
            lookTarget = options.lookTarget,
            lookTargetPos = options.lookTargetPos,
            debugSelection = true,
        })

        if not target then
            infoLog("nearest_manual_assign_no_target", "filter", tostring(interactionType), "mode", "target_first")
            return false, noFreeTargetMessage(interactionType)
        end

        local actor = options.selectedActor and {
            npc = options.selectedActor,
            distance = target and target.targetDistance or 0,
            lookTargetActorUsed = true,
            manualAssignOverrideApplied = options.selectedActorOverrideReason ~= nil,
            manualAssignOverrideReason = options.selectedActorOverrideReason,
        } or chooseNearestManualActor(player, npcs, target.interactionType, {
            actorRadius = tonumber(options.actorRadius or 1600) or 1600,
            preferredActor = options.lookTarget,
            allowAssignedTestNpc = true,
        })
        if not actor then
            infoLog("nearest_manual_assign_no_eligible_actor", "filter", tostring(target.interactionType), "mode", "target_first")
            return false, "Found nearby furniture, but no eligible standing NPC was close enough to use as the test actor."
        end

        local candidate = target.candidate
        if target.interactionType == "station" then
            if npcAlreadyAssigned(actor.npc) and isCalibrationTestNpcRecord(actor.npc.recordId) then
                manualAssignment.cleanupBeforeReassign({
                    getAssignedActors = getAssignedActors,
                    stopInteractionForNpc = env.stopInteractionForNpc,
                    infoLog = infoLog,
                    debugLog = debugLog,
                }, actor.npc, candidate, "manual_assign_retarget_test_npc_actor")
                debugLog("nearest_manual_assign_released_assigned_test_npc", actor.npc.recordId or actor.npc.id)
            end
            local session = calibrationLock.captureStationTarget(stationSessionDataForObject(candidate.object), calibrationContext(), "manual_assign_station_target_first")
            local ok, reason = claimStationTarget(candidate, actor.npc, options.stationClaimOptions or stationClaimOptions({
                calibrationAction = false,
                forcePathing = true,
                forcePathingImmediateRadius = 6,
                lectureStartRequested = false,
                lectureDebugShortcut = false,
                lectureTeleportAudience = false,
                lectureSource = "assign_nearest",
            }))
            if not ok then
                infoLog("station assign failed", "action", "assign_nearest_target_first", "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName), "actor", tostring(actor.npc and (actor.npc.recordId or actor.npc.id)), "reason", tostring(reason), "category", stationFailureCategory(reason))
                return false, stationFailureMessage(reason, "Found station and NPC, but could not assign station")
            end
            session = calibrationLock.captureStationTarget(stationSessionDataForObject(candidate.object, actor.npc), calibrationContext(), "manual_assign_station_confirmed") or session
            rememberCalibrationFillLedger(actor.npc, {
                interactionType = "station",
                candidate = {
                    interactionType = "station",
                    object = candidate.object,
                    objectId = candidate.objectId,
                    slotKey = candidate.slotKey,
                    slotName = candidate.slotName,
                    stationPosition = candidate.stationPosition,
                },
            }, false)
            infoLog("nearest_manual_assign_target_chosen_player", "type", "station", "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "targetDistance", tostring(target.targetDistance), "score", tostring(target.score), "facingBias", tostring(target.facingBias), "typeBias", tostring(target.typeBias), "lookTargetUsed", tostring(target.lookTargetUsed == true))
            infoLog("nearest_manual_assign_actor_chosen_player", actor.npc.recordId or actor.npc.id, "type", "station", "npcDistance", tostring(actor.distance), "lookTargetActorUsed", tostring(actor.lookTargetActorUsed == true))
            infoLog("nearest_manual_assign_status", "claimed", actor.npc.recordId or actor.npc.id, "type", "station", "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "mode", "target_first")
            local verb = reason == "pathing" and "Sent " or "Assigned "
            local suffix = reason == "pathing" and " toward the looked-at station." or " to the looked-at station."
            return true, verb .. tostring(actor.npc.recordId or "nearest NPC") .. suffix, sessionStatusPayload(session or calibrationLock.session, manualAssignStatusExtra(actor))
        end

        if candidate.externalPhysicalClaimed == true then
            candidate.hardBlockerReason = "external_furniture_claimed"
            candidate.rejectionReason = "external_furniture_claimed"
            local sessionActor = candidate.externalPhysicalClaimActor or actor.npc
            local session = calibrationLock.captureFurnitureTarget(furnitureSessionDataForCandidate(candidate, sessionActor), calibrationContext(), "manual_assign_external_claimed_target") or calibrationLock.session
            infoLog(
                "nearest_manual_assign_external_claimed_target",
                "type", tostring(target.interactionType),
                "object", tostring(candidate.objectId),
                "slot", tostring(candidateSlotLabel(candidate)),
                "claimActor", tostring(candidate.externalPhysicalClaimActorRecordId or candidate.externalPhysicalClaimActorId),
                "reason", tostring(candidate.externalPhysicalClaimReason)
            )
            return true, "Target selected, but that furniture is claimed by an external animation.", sessionStatusPayload(session, manualAssignStatusExtra(actor))
        end

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
        if npcAlreadyAssigned(actor.npc) and isCalibrationTestNpcRecord(actor.npc.recordId) then
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
        candidate.manualAssignOverrideApplied = actor.manualAssignOverrideApplied == true
        candidate.manualAssignOverrideReason = actor.manualAssignOverrideReason

        sendConsiderInteraction(actor.npc, candidate)
        manualAssignment.logRouteStarted(infoLog, actor.npc, candidate)
        rememberPendingCalibrationTarget(actor.npc, candidate, "manual_assign_pending")
        local activeSession = calibrationLock.captureFurnitureTarget(furnitureSessionDataForCandidate(candidate, actor.npc), calibrationContext(), "manual_assign_pending_selected_actor") or calibrationLock.session
        infoLog("nearest_manual_assign_target_chosen_player", "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "targetDistance", tostring(target.targetDistance), "score", tostring(target.score), "facingBias", tostring(target.facingBias), "typeBias", tostring(target.typeBias), "lookTargetUsed", tostring(target.lookTargetUsed == true), "furnitureSource", tostring(objectContentFile(candidate.object) or "dynamic / unknown"), "furnitureModel", tostring(objectModelPath(candidate.object)))
        infoLog("nearest_manual_assign_actor_chosen_player", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "npcDistance", tostring(actor.distance), "lookTargetActorUsed", tostring(actor.lookTargetActorUsed == true), "actorSource", tostring(objectContentFile(actor.npc) or "dynamic / unknown"))
        infoLog("nearest_manual_assign_testing_override", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "bypass", "route_clearance_only")
        infoLog("nearest_manual_assign_pending_calibration_target", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)))
        infoLog("nearest_manual_assign_status", "sent", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "mode", "target_first")
        local label = target.interactionType == "sleeping" and "bed" or "seat"
        local actorText = actor.lookTargetActorUsed == true and "looked-at NPC" or tostring(actor.npc.recordId or "nearest NPC")
        local targetText = target.lookTargetUsed == true and ("the looked-at " .. label)
            or (options.selectedActor and ("the nearest " .. label .. " near them") or ("the nearest " .. label .. " near you"))
        return true, "Sent " .. actorText .. " to " .. targetText .. ". Waiting for result.", sessionStatusPayload(activeSession, manualAssignStatusExtra(actor))
    end

    local function noteFillReason(stats, reason)
        if not stats then return end
        reason = tostring(reason or "unknown")
        stats.skipped = (stats.skipped or 0) + 1
        stats.reasons = stats.reasons or {}
        stats.reasons[reason] = (stats.reasons[reason] or 0) + 1
    end

    local function fillReasonText(reasons)
        local parts = {}
        for reason, count in pairs(reasons or {}) do
            parts[#parts + 1] = tostring(reason) .. "=" .. tostring(count)
        end
        table.sort(parts)
        return #parts > 0 and table.concat(parts, ", ") or "none"
    end

    local function collectFillCandidates(player, interactionTypes, stats)
        local candidates = {}
        local seenSlots = {}
        local seenTargets = {}
        for _, candidateType in ipairs(interactionTypes or {}) do
            if candidateType == "station" then
                for _, target in ipairs(collectStationTargets(player, { allowOccupied = true }) or {}) do
                    local slotKey = target.candidate and target.candidate.slotKey
                    local reservationKey = fillTargetReservationKey(target)
                    if slotKey
                        and not seenSlots[slotKey]
                        and not (reservationKey and seenTargets[reservationKey]) then
                        seenSlots[slotKey] = true
                        if reservationKey then seenTargets[reservationKey] = true end
                        if target.occupied == true or target.pending == true then
                            if stats then stats.occupied = (stats.occupied or 0) + 1 end
                            noteFillReason(stats, target.pending == true and "station_claim_pending" or "slot_occupied")
                        else
                            candidates[#candidates + 1] = target
                        end
                    elseif reservationKey and seenTargets[reservationKey] then
                        noteFillReason(stats, "fill_target_duplicate")
                    end
                end
            else
            local slots = buildCandidateSlots(player.cell, candidateType, {
                ignoreTimeGate = true,
                calibrationAction = true,
                manualAssign = true,
                lectureAudienceTarget = true,
                allowUnclaimedLecternFocus = true,
                allowOccupiedByTestNpc = true,
                allowOccupiedSlots = true,
            })
            for _, candidate in ipairs(slots or {}) do
                local slotKey = candidate and candidate.slotKey
                local target = candidate and {
                    candidate = candidate,
                    interactionType = candidateType,
                    distance = candidateDistanceToPlayer(candidate, player, candidateType),
                } or nil
                local reservationKey = fillTargetReservationKey(target)
                if candidate and candidate.object and isObjValid(candidate.object)
                    and slotKey and not seenSlots[slotKey]
                    and not (reservationKey and seenTargets[reservationKey]) then
                    seenSlots[slotKey] = true
                    if reservationKey then seenTargets[reservationKey] = true end
                    if candidate.externalPhysicalClaimed == true then
                        if stats then stats.occupied = (stats.occupied or 0) + 1 end
                        noteFillReason(stats, "external_furniture_claimed")
                    elseif isSlotOccupied(slotKey) and candidate.occupiedByTestNpc ~= true and candidate.slotOwnerData ~= nil then
                        if stats then stats.occupied = (stats.occupied or 0) + 1 end
                        noteFillReason(stats, "slot_occupied")
                    else
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
                    end
                    candidates[#candidates + 1] = target
                    end
                elseif reservationKey and seenTargets[reservationKey] then
                    noteFillReason(stats, "fill_target_duplicate")
                else
                    noteFillReason(stats, "slot_invalid")
                end
            end
            end
        end
        table.sort(candidates, function(a, b)
            if a.distance ~= b.distance then return a.distance < b.distance end
            return tostring(a.candidate and a.candidate.slotKey) < tostring(b.candidate and b.candidate.slotKey)
        end)
        return candidates
    end

    local function physicalFillOccupant(player, npcs, target)
        local candidate = target and target.candidate
        local pos = candidateTargetPosition(candidate)
        if not pos then return nil end

        local interactionType = tostring(target and target.interactionType or candidate and candidate.interactionType or "")
        local radius = interactionType == "sleeping" and 115
            or interactionType == "station" and 80
            or 75
        local verticalLimit = interactionType == "sleeping" and 145 or 110

        for _, npc in ipairs(npcs or {}) do
            if npc ~= player and npc.id and npc.position and isObjValid(npc) and objectEnabled(npc) then
                local recordId = npc.recordId and string.lower(tostring(npc.recordId)) or ""
                if not isCalibrationTestNpcRecord(recordId) then
                    local flat, vertical = flatDistanceAndVertical(npc.position, pos)
                    if flat <= radius and vertical <= verticalLimit then
                        return npc, flat, vertical
                    end
                end
            end
        end
        return nil
    end

    local function releaseRetargetedFillSlot(target)
        local candidate = target and target.candidate
        if not (candidate and candidate.slotKey) then return end

        if candidate.occupiedByTestNpc == true and candidate.occupiedByTestNpcActor then
            manualAssignment.cleanupBeforeReassign({
                getAssignedActors = getAssignedActors,
                stopInteractionForNpc = env.stopInteractionForNpc,
                infoLog = infoLog,
                debugLog = debugLog,
            }, candidate.occupiedByTestNpcActor, candidate, "developer_fill_retarget_test_npc_slot")
            pcall(function()
                candidate.occupiedByTestNpcActor:sendEvent("StopInteractionObject", {
                    reason = "developer_fill_retarget_test_npc_slot",
                    interactionType = candidate.occupiedByTestNpcInteractionType,
                    forceClearSleepAnimation = true,
                })
            end)
            debugLog("developer calibration fill released test npc slot", candidate.occupiedByTestNpcActor.recordId or candidate.occupiedByTestNpcActor.id, "slot", tostring(candidateSlotLabel(candidate)))
        elseif candidate.occupiedByAnyActor == true and candidate.slotOwnerData == nil and env.clearOccupiedSlot then
            env.clearOccupiedSlot(candidate.slotKey, "developer_fill_stale_slot_claim")
            debugLog("developer calibration fill cleared stale slot claim", "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "owner", tostring(candidate.slotOwnerId), "source", tostring(candidate.slotOwnerSource))
        end
    end

    local function chooseFillActorForCandidate(player, npcs, target, usedActors)
        local best = nil
        local targetPos = candidateTargetPosition(target and target.candidate)
        for _, npc in ipairs(npcs or {}) do
            if npc ~= player and npc.id and not usedActors[npc.id] and npc.position and objectEnabled(npc) then
                local eligible = manualNpcEligible(npc, target.interactionType, {
                    testingOverride = false,
                    allowAssignedTestNpc = false,
                    allowAssignedFillNpc = true,
                })
                if eligible then
                    local dist = pointDistance(npc.position, targetPos)
                    if not best or dist < best.distance then
                        best = { npc = npc, distance = dist }
                    end
                end
            end
        end
        return best
    end

    local function countFillActorsAvailable(player, npcs, interactionTypes)
        local allowed = {}
        for _, interactionType in ipairs(interactionTypes or {}) do allowed[interactionType] = true end
        local count = 0
        for _, npc in ipairs(npcs or {}) do
            if npc ~= player and npc.id and npc.position and objectEnabled(npc) then
                for interactionType in pairs(allowed) do
                    local eligible = manualNpcEligible(npc, interactionType, {
                        testingOverride = false,
                        allowAssignedFillNpc = true,
                    })
                    if eligible then
                        count = count + 1
                        break
                    end
                end
            end
        end
        return count
    end

    local function spawnPositionForFillCandidate(player, candidate, interactionType)
        if interactionType == "sitting" then
            local pos, placement = sittingFillSpawnPosition(candidate)
            if pos then return pos, placement end
        end
        local pos = candidateTargetPosition(candidate)
        if pos then
            if interactionType == "station" then return pos, "target_direct" end
            return pos + util.vector3(0, 0, 12), "target_direct"
        end
        if player and player.position then
            local key = tostring(candidate and (candidate.slotKey or candidate.objectId or candidate.slotName) or "fill")
            local angleSeed = profiles.stableUnitInterval and profiles.stableUnitInterval(key .. "::spawn_angle") or 0.5
            local radiusSeed = profiles.stableUnitInterval and profiles.stableUnitInterval(key .. "::spawn_radius") or 0.5
            local angle = angleSeed * math.pi * 2
            local radius = 96 + radiusSeed * 80
            return player.position + util.vector3(math.cos(angle) * radius, math.sin(angle) * radius, 8), "player_fallback"
        end
        return nil, nil
    end

    local sendFillAssignment

    local function spawnAndSendFillAssignment(player, target, usedActors)
        local spawnPos, spawnPlacement = spawnPositionForFillCandidate(player, target.candidate, target.interactionType)
        local npc, spawnMessage = spawnCalibrationTestNpcAt(player, spawnPos, player.rotation, "fill_furniture", { variedRecord = true, identityRole = "fill" })
        if npc then
            local identity = fillIdentityForActor(npc)
            infoLog(
                "developer calibration fill spawn placed",
                tostring(identity and identity.label or npc.recordId or npc.id),
                "type", tostring(target.interactionType),
                "object", tostring(target.candidate and target.candidate.objectId),
                "slot", tostring(target.candidate and candidateSlotLabel(target.candidate)),
                "spawnPlacement", tostring(spawnPlacement or "unknown"),
                "position", tostring(spawnPos)
            )
            usedActors[npc.id] = true
            if target.candidate and spawnPos then
                target.candidate.preInteractionPos = spawnPos
                target.candidate.npcStandingPos = spawnPos
            end
            local ok, reason = sendFillAssignment(npc, target, true)
            if ok then return true, nil, npc end
            removeOneCalibrationTestNpc(npc, "station_fill_failed")
            return false, reason or "assignment_failed", npc
        end
        infoLog("developer calibration fill spawn skipped", "type", tostring(target.interactionType), "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and candidateSlotLabel(target.candidate)), "reason", tostring(spawnMessage), "spawnPlacement", tostring(spawnPlacement or "unknown"))
        return false, spawnMessage or "no_eligible_npc_available", nil
    end

    sendFillAssignment = function(actor, target, spawned)
        local candidate = target.candidate
        if candidate and candidate.externalPhysicalClaimed == true then
            infoLog("developer calibration fill external claimed skipped", "type", tostring(target.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidateSlotLabel(candidate)), "claimActor", tostring(candidate.externalPhysicalClaimActorRecordId or candidate.externalPhysicalClaimActorId), "reason", tostring(candidate.externalPhysicalClaimReason))
            return false, "external_furniture_claimed"
        end
        local generatedFill = spawned == true
        local identity = spawned == true
            and (fillIdentityForActor(actor) or assignCalibrationActorIdentity(actor, "fill", true))
            or assignCalibrationActorIdentity(actor, "fill", false)
        if target.interactionType == "station" then
            registerCalibrationFillActor(actor, target, spawned)
            local ok, reason = claimStationTarget(candidate, actor, {
                testingOverride = generatedFill,
                calibrationAction = generatedFill,
                calibrationFill = generatedFill,
                forcePathing = not generatedFill,
                forcePathingImmediateRadius = 6,
                suppressAudience = true,
                calibrationFillLabel = identity and identity.label or nil,
                calibrationFillRole = identity and identity.role or nil,
                calibrationFillSource = identity and identity.source or nil,
                calibrationFillIndex = identity and identity.index or nil,
                calibrationFillSessionId = identity and identity.sessionId or nil,
                calibrationRuntimeObjectId = identity and identity.runtimeObjectId or nil,
            })
            if not ok then
                if generatedFill then
                    calibrationFillActors[actor.id] = nil
                else
                    forgetCalibrationFillLedgerActor(actor)
                    calibrationFillActors[actor.id] = nil
                end
                infoLog("station fill failed", tostring(identity and identity.label or actor.recordId or actor.id), "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName), "reason", tostring(reason), "category", stationFailureCategory(reason), "source", tostring(identity and identity.source), "runtimeObject", tostring(identity and identity.runtimeObjectId))
                return false, reason or "station_assignment_failed"
            end
            local currentSession = calibrationLock.session
            if currentSession
                and currentSession.interactionType == "station"
                and currentSession.slotKey == candidate.slotKey then
                calibrationLock.captureStationTarget(stationSessionDataForObject(candidate.object, actor), calibrationContext(), "developer_station_fill_selected")
            end
            infoLog("developer calibration station fill assignment sent", tostring(identity and identity.label or actor.recordId or actor.id), "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName), "spawned", tostring(spawned == true), "source", tostring(identity and identity.source), "runtimeObject", tostring(identity and identity.runtimeObjectId), "targetDistance", tostring(target.distance))
            return true
        end
        candidate.ignoreTimeGate = true
        candidate.calibrationAction = generatedFill
        candidate.calibrationReason = generatedFill and "developer_fill_furniture_generated" or "developer_fill_furniture_borrowed"
        candidate.manualAssignOverrideTesting = true
        candidate.explicitFillOverride = true
        candidate.manualAssign = true
        candidate.debugForced = generatedFill
        candidate.calibrationTestNpc = generatedFill
        candidate.calibrationFill = true
        candidate.initialPlacement = false
        candidate.suppressInitialPlacementOverlay = true
        if not generatedFill then
            candidate.manualAssignOverrideReason = nil
            candidate.sleepAccessOverrideReason = nil
        end
        applyCalibrationActorIdentity(candidate, actor)
        registerCalibrationFillActor(actor, target, spawned)
        if actor and actor.id then
            if generatedFill then
                pendingBorrowedFillTargets[actor.id] = nil
            else
                pendingBorrowedFillTargets[actor.id] = {
                    target = target,
                    sessionId = identity and identity.sessionId or calibrationFillSessionId,
                }
            end
        end
        local sentOk, sentReason = sendConsiderInteraction(actor, candidate)
        if sentOk == false then
            if generatedFill then
                calibrationFillActors[actor.id] = nil
                removeOneCalibrationTestNpc(actor, "calibration_fill_send_failed")
            else
                forgetCalibrationFillLedgerActor(actor)
                calibrationFillActors[actor.id] = nil
                pendingBorrowedFillTargets[actor.id] = nil
            end
            infoLog(
                "developer calibration fill assignment send failed",
                tostring(identity and identity.label or actor.recordId or actor.id),
                "type", tostring(target.interactionType),
                "object", tostring(candidate.objectId),
                "slot", tostring(candidateSlotLabel(candidate)),
                "reason", tostring(sentReason),
                "source", tostring(identity and identity.source),
                "runtimeObject", tostring(identity and identity.runtimeObjectId)
            )
            return false, sentReason or "assignment_send_failed"
        end
        infoLog(
            "developer calibration fill assignment sent",
            tostring(identity and identity.label or actor.recordId or actor.id),
            "type", tostring(target.interactionType),
            "object", tostring(candidate.objectId),
            "slot", tostring(candidateSlotLabel(candidate)),
            "spawned", tostring(spawned == true),
            "source", tostring(identity and identity.source),
            "runtimeObject", tostring(identity and identity.runtimeObjectId),
            "targetDistance", tostring(target.distance)
        )
        return true
    end

    local function fillFurnitureWithTestActors(interactionType, player)
        if not (player and player.cell and player.position and player.cell.getAll) then
            return false, "No player cell is available."
        end
        removeCalibrationTestNpc("replace_fill_furniture", player, { silent = true })
        calibrationFillSessionIndex = calibrationFillSessionIndex + 1
        calibrationFillIdentityIndex = 0
        calibrationFillSessionId = tostring(cellName(player.cell) or "cell") .. "#" .. twoDigit(calibrationFillSessionIndex)
        local okList, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
        if not okList or not npcs then
            return false, "Could not scan NPCs in this cell."
        end
        local npcList = {}
        for _, npc in ipairs(npcs) do
            npcList[#npcList + 1] = npc
        end
        npcs = npcList

        local fillStats = { occupied = 0, skipped = 0, reasons = {} }
        local interactionTypes = fillCellInteractionTypes(interactionType)
        local actorsAvailable = FILL_FURNITURE_BORROW_EXISTING_ACTORS == true
            and countFillActorsAvailable(player, npcs, interactionTypes)
            or 0
        local targets = collectFillCandidates(player, interactionTypes, fillStats)
        if #targets == 0 then
            infoLog("developer calibration fill summary", "slotsFound", tostring(fillStats.occupied or 0), "available", "0", "occupied", tostring(fillStats.occupied or 0), "filled", "0", "skipped", tostring(fillStats.skipped or 0), "actorsAvailable", tostring(actorsAvailable), "actorsAssigned", "0", "reasons", fillReasonText(fillStats.reasons), "session", tostring(calibrationFillSessionId))
            return false, noFreeTargetMessage(interactionType)
        end

        local usedActors = {}
        local reservedTargets = {}
        local assignedExisting = 0
        local spawnedCount = 0
        local sent = 0
        local limit = math.min(#targets, FILL_FURNITURE_MAX_ACTORS)
        local capped = #targets > FILL_FURNITURE_MAX_ACTORS
        if capped then
            for _ = FILL_FURNITURE_MAX_ACTORS + 1, #targets do
                noteFillReason(fillStats, "fill_cap_reached")
            end
        end

        for index = 1, limit do
            local target = targets[index]
            local reservationKey = fillTargetReservationKey(target)
            if reservationKey and reservedTargets[reservationKey] then
                noteFillReason(fillStats, "fill_target_reserved")
                debugLog("developer calibration fill duplicate target skipped", "type", tostring(target and target.interactionType), "object", tostring(target and target.candidate and target.candidate.objectId), "slot", tostring(target and target.candidate and candidateSlotLabel(target.candidate)), "reservation", tostring(reservationKey))
            else
                local occupant, occupantFlat, occupantVertical = physicalFillOccupant(player, npcs, target)
                if occupant then
                    if reservationKey then reservedTargets[reservationKey] = true end
                    if fillStats then fillStats.occupied = (fillStats.occupied or 0) + 1 end
                    noteFillReason(fillStats, "physical_actor_occupied")
                    infoLog(
                        "developer calibration fill physical occupied skipped",
                        "type", tostring(target and target.interactionType),
                        "object", tostring(target and target.candidate and target.candidate.objectId),
                        "slot", tostring(target and target.candidate and candidateSlotLabel(target.candidate)),
                        "actor", tostring(occupant.recordId or occupant.id),
                        "flat", tostring(occupantFlat),
                        "vertical", tostring(occupantVertical)
                    )
                else
                    if reservationKey then reservedTargets[reservationKey] = true end
                    releaseRetargetedFillSlot(target)
                    local actor = FILL_FURNITURE_BORROW_EXISTING_ACTORS == true
                        and chooseFillActorForCandidate(player, npcs, target, usedActors)
                        or nil
                    if actor then
                        usedActors[actor.npc.id] = true
                        if npcAlreadyAssigned(actor.npc) then
                            manualAssignment.cleanupBeforeReassign({
                                getAssignedActors = getAssignedActors,
                                stopInteractionForNpc = env.stopInteractionForNpc,
                                infoLog = infoLog,
                                debugLog = debugLog,
                            }, actor.npc, target.candidate, "developer_fill_retarget_existing_actor")
                            debugLog("developer calibration fill released existing actor", actor.npc.recordId or actor.npc.id, "type", tostring(target.interactionType), "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and candidateSlotLabel(target.candidate)))
                        end
                        local ok, reason = sendFillAssignment(actor.npc, target, false)
                        if ok then
                            assignedExisting = assignedExisting + 1
                            sent = sent + 1
                        else
                            if target.interactionType == "station" and (reason == "invalid_station_actor" or reason == "not_station_eligible" or reason == "no_presenter_candidate") then
                                local retryOk, retryReason, retryNpc = spawnAndSendFillAssignment(player, target, usedActors)
                                if retryOk then
                                    if retryNpc then table.insert(npcs, retryNpc) end
                                    spawnedCount = spawnedCount + 1
                                    sent = sent + 1
                                    infoLog("station fill retried with spawned debug actor", "object", tostring(target.candidate and target.candidate.objectId), "slot", tostring(target.candidate and candidateSlotLabel(target.candidate)), "originalReason", tostring(reason))
                                else
                                    noteFillReason(fillStats, retryReason or reason or "assignment_failed")
                                end
                            else
                                noteFillReason(fillStats, reason or "assignment_failed")
                            end
                        end
                    else
                        local ok, reason, spawnedNpc = spawnAndSendFillAssignment(player, target, usedActors)
                        if ok then
                            if spawnedNpc then table.insert(npcs, spawnedNpc) end
                            spawnedCount = spawnedCount + 1
                            sent = sent + 1
                        else
                            noteFillReason(fillStats, reason or "assignment_failed")
                        end
                    end
                end
            end
        end

        local skipped = tonumber(fillStats.skipped or 0) or 0
        local reasonsText = fillReasonText(fillStats.reasons)
        infoLog("developer calibration fill complete", "sent", tostring(sent), "existing", tostring(assignedExisting), "spawned", tostring(spawnedCount), "available", tostring(#targets), "occupied", tostring(fillStats.occupied or 0), "skipped", tostring(skipped), "actorsAvailable", tostring(actorsAvailable), "actorsAssigned", tostring(sent), "reasons", reasonsText, "limit", tostring(FILL_FURNITURE_MAX_ACTORS), "session", tostring(calibrationFillSessionId))
        infoLog("developer calibration fill summary", "slotsFound", tostring(#targets + (fillStats.occupied or 0)), "alreadyOccupied", tostring(fillStats.occupied or 0), "available", tostring(#targets), "filled", tostring(sent), "skipped", tostring(skipped), "actorsAvailable", tostring(actorsAvailable), "actorsAssigned", tostring(sent), "reasons", reasonsText, "session", tostring(calibrationFillSessionId))
        if sent == 0 then
            return false, "Found furniture, but could not assign or spawn any test actors. Check openmw.log for station fill failed, no eligible NPC, placement failed, or occupied slot reasons."
        end
        local capText = capped and (" Capped at " .. tostring(FILL_FURNITURE_MAX_ACTORS) .. " targets for save safety.") or ""
        local skipText = skipped > 0 and (" Skipped " .. tostring(skipped) .. " slots (" .. reasonsText .. ").") or ""
        return true, "Fill Cell sent " .. tostring(sent) .. "/" .. tostring(#targets) .. " available assignments (" .. tostring(assignedExisting) .. " existing, " .. tostring(spawnedCount) .. " spawned)." .. skipText .. capText .. " Use Clear Test Actors before saving if you stay in this cell."
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

    function M.onCalibrationFillRejected(ev)
        if not (ev and ev.npc) then return false end
        local fillOwned = ev.calibrationFill == true
            or ev.calibrationTestNpc == true
            or ev.calibrationFillSource ~= nil
            or ev.calibrationFillLabel ~= nil
        if not fillOwned then return false end

        if ev.calibrationTestNpc == true then
            local removed = removeOneCalibrationTestNpc(ev.npc, "calibration_fill_rejected_" .. tostring(ev.reason or "unknown"))
            if removed then
                infoLog(
                    "calibration fill rejected test npc removed",
                    ev.npc.recordId or ev.npc.id,
                    "type", tostring(ev.interactionType),
                    "object", tostring(ev.objectId),
                    "slot", tostring(ev.slotName),
                    "reason", tostring(ev.reason)
                )
            end
            return removed == true
        end

        local pending = ev.npc.id and pendingBorrowedFillTargets[ev.npc.id] or nil
        if ev.npc.id then
            pendingBorrowedFillTargets[ev.npc.id] = nil
            calibrationFillActors[ev.npc.id] = nil
        end
        forgetCalibrationFillLedgerActor(ev.npc)
        if pending and pending.target then
            local player = nil
            for _, candidatePlayer in ipairs(world.players or {}) do
                if candidatePlayer and candidatePlayer.cell and (candidatePlayer.cell == ev.npc.cell or (pending.target.candidate and pending.target.candidate.object and candidatePlayer.cell == pending.target.candidate.object.cell)) then
                    player = candidatePlayer
                    break
                end
            end
            player = player or (world.players and world.players[1]) or nil
            if not player then
                infoLog(
                    "calibration fill borrowed retry failed",
                    ev.npc.recordId or ev.npc.id,
                    "type", tostring(ev.interactionType),
                    "object", tostring(ev.objectId),
                    "slot", tostring(ev.slotName),
                    "reason", tostring(ev.reason),
                    "retryReason", "missing_player"
                )
                return false
            end
            local retryOk, retryReason = spawnAndSendFillAssignment(player, pending.target, {})
            if retryOk then
                infoLog(
                    "calibration fill borrowed rejected retried with spawned debug actor",
                    ev.npc.recordId or ev.npc.id,
                    "type", tostring(ev.interactionType),
                    "object", tostring(ev.objectId),
                    "slot", tostring(ev.slotName),
                    "reason", tostring(ev.reason)
                )
                return true
            end
            infoLog(
                "calibration fill borrowed retry failed",
                ev.npc.recordId or ev.npc.id,
                "type", tostring(ev.interactionType),
                "object", tostring(ev.objectId),
                "slot", tostring(ev.slotName),
                "reason", tostring(ev.reason),
                "retryReason", tostring(retryReason)
            )
        end
        return false
    end

    function M.onCalibrationMenuAction(ev)
        local interactionType = ev and ev.interactionType
        local action = ev and ev.action
        local eventPlayer = ev and ev.player
        local player = resolveCalibrationPlayer(eventPlayer)
        local ctx = calibrationContext()
        if eventPlayer ~= nil and eventPlayer ~= player then
            infoLog("calibration menu action resolved active player", tostring(action), "reason", "event_player_missing_cell")
        end
        if interactionType ~= "auto" and interactionType ~= "sleeping" and interactionType ~= "sitting" and interactionType ~= "station" then
            infoLog("calibration menu action failed", tostring(action), "reason", "unsupported_interaction_type")
            sendCalibrationMenuStatus(player, "Use Auto, Bed, Seat, or Station first.")
            return
        end
        local targetRequiredActions = {
            clear = true,
            resume = true,
            reapply = true,
            reenter = true,
            send = true,
            print = true,
            reset = true,
            nudge = true,
        }
        local visualPrintAutoTarget = action == "print" and ev and ev.visualApproval == true and ev.captureLookTarget == true
        if targetRequiredActions[action] == true and visualPrintAutoTarget ~= true then
            local selectedSession = calibrationLock.currentSession(interactionType, ctx)
            if not selectedSession then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_no_target")
                sendCalibrationMenuStatus(player, "No target selected. Use Find Target first.", { cleared = true })
                return
            end
        end
        if action == "capture" then
            infoLog(
                "calibration menu capture requested",
                "filter", tostring(interactionType),
                "lookTarget", tostring(ev and ev.lookTarget and (ev.lookTarget.recordId or ev.lookTarget.id) or "<none>"),
                "source", tostring(ev and ev.lookTargetSource or "<none>"),
                "type", tostring(ev and ev.lookTargetTypeName or "<none>")
            )
            local session = nil
            local constrained = false
            local lookTargetHasStation = false
            local directActorLookTarget = lookTargetActorKind(ev and ev.lookTarget)
            if directActorLookTarget then
                session = captureDirectActorTarget(interactionType, player, ev.lookTarget)
                constrained = true
            end
            if not session and directActorLookTarget and stationDataForNpc then
                local okStationData, stationData = pcall(stationDataForNpc, ev.lookTarget)
                lookTargetHasStation = okStationData and stationData and stationData.object ~= nil
            end
            local autoStationLookTarget = interactionType == "auto"
                and (
                    (profiles.stationProfileForObject and profiles.stationProfileForObject(ev and ev.lookTarget, settings) ~= nil)
                    or lookTargetHasStation
                )
            if not session and (interactionType == "station" or autoStationLookTarget) then
                session = captureStationSession(player, ev.lookTarget, ev.lookTargetPos)
                constrained = true
            end
            if not session and interactionType ~= "station" and not lookTargetFurnitureKind(ev and ev.lookTarget) then
                session = captureViewConeActorTarget(interactionType, player, ev and ev.lookTargetPos)
                if session then constrained = true end
            end
            if not session and interactionType ~= "station" then
                session = captureLookedEmptyFurnitureTarget(interactionType, player, ev, "menu_capture_empty_furniture")
            end
            if not session and interactionType ~= "station" then
                session, constrained = captureLookTargetSession(interactionType, player, ev.lookTarget, ev.lookTargetPos)
            end
            if not session and interactionType ~= "station" and (constrained == true or lookTargetFurnitureKind(ev and ev.lookTarget)) then
                infoLog("find_target_fallback_nearest", "filter", tostring(interactionType), "source", constrained == true and "direct_target_unresolved" or "looked_furniture")
                session = captureNearestCandidateTarget(interactionType, player, {
                    lookTarget = ev.lookTarget,
                    lookTargetPos = ev.lookTargetPos,
                    targetRadius = 1400,
                    reason = "menu_capture_empty_furniture",
                })
            end
            if not session and (interactionType == "sleeping" or interactionType == "sitting") then
                infoLog("find_target_fallback_nearest", "filter", tostring(interactionType), "source", "nearby_filtered_furniture")
                session = captureNearestCandidateTarget(interactionType, player, {
                    lookTargetPos = ev.lookTargetPos,
                    targetRadius = 560,
                    reason = "menu_capture_nearby_filtered_furniture",
                })
            end
            if not session then
                if interactionType ~= "station" then
                    infoLog("find_target_fallback_nearest", "filter", tostring(interactionType), "source", "view_cone")
                    session = captureViewConeSession(interactionType, player, ev.lookTargetPos)
                end
            end
            if not session then
                if interactionType == "station" then
                    infoLog("calibration station fallback nearest target missed", tostring(interactionType))
                elseif constrained == true then
                    infoLog("calibration sharedray fallback nearest target", tostring(interactionType))
                else
                    infoLog("calibration view-cone fallback nearest target", tostring(interactionType))
                end
                if interactionType ~= "station" then
                    infoLog("find_target_fallback_nearest", "filter", tostring(interactionType), "source", "saved_or_active_target")
                    session = calibrationLock.captureTarget(interactionType, ctx, "menu_capture")
                end
            end
            if session and (interactionType == "station" or autoStationLookTarget) then
                local assigned, pending = stationSlotOccupied(session.slotKey)
                infoLog("station find target selected without assignment", "object", tostring(session.objectId or session.objectRecordId), "slot", tostring(session.slotName), "assigned", tostring(assigned), "pending", tostring(pending))
            end
            sendCalibrationMenuStatus(
                player,
                session and ("Target found: " .. calibrationLock.sessionLabel(session)) or (interactionType == "station" and "No station target found nearby. Look at or stand near a profiled station, then try again." or "No target found nearby. Look at or stand near profiled furniture or an SDP actor, then try again."),
                session and sessionStatusPayload(session, { silent = ev.silent == true or ev.silentOnSuccess == true }) or (ev.silent == true and { silent = true } or nil)
            )
            sendCalibrationOffsetsForSession(player, session)
            return
        end
        if action == "cycle_target" then
            local session, message = cycleCalibrationTarget(interactionType, player)
            sendCalibrationMenuStatus(
                player,
                message or "No target found nearby.",
                session and sessionStatusPayload(session, { silent = true }) or { silent = true }
            )
            sendCalibrationOffsetsForSession(player, session)
            return
        end
        if action == "spawn_test" then
            local spawnType = interactionType == "auto" and "sitting" or interactionType
            local ok, message, status = spawnAndAssignCalibrationTestNpc(spawnType, player, {
                lookTarget = ev.lookTarget,
                lookTargetPos = ev.lookTargetPos,
                variedRecord = true,
            })
            if type(status) ~= "table" then status = {} end
            if ok == true then
                status.silent = true
            end
            status.fillOrTestExists = ok == true or calibrationFillOrTestExists(player)
            sendCalibrationMenuStatus(player, ok == true and "Spawning NPC..." or message, status)
            return
        end
        if action == "fill_furniture" then
            local ok, message = fillFurnitureWithTestActors(interactionType, player)
            local status = { fillOrTestExists = ok == true or calibrationFillOrTestExists(player) }
            sendCalibrationMenuStatus(player, message, status)
            return
        end
        if action == "assign_nearest" then
            local ok, message, status = assignNearestNpc(interactionType, player, {
                lookTarget = ev.lookTarget,
                lookTargetPos = ev.lookTargetPos,
            })
            if ok == true and type(status) == "table" then status.silent = true end
            sendCalibrationMenuStatus(player, message, status)
            return
        end
        if action == "remove_test" then
            if calibrationFillOrTestExists(player) ~= true then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_no_fill_or_test")
                sendCalibrationMenuStatus(player, "No fill/test actors to clear.", { fillOrTestExists = false })
                return
            end
            local selectedSession = calibrationLock.currentSession(interactionType, ctx)
            local clearSelectedTarget = sessionIsFillOrTest(selectedSession)
            local _, message = removeCalibrationTestNpc("developer_menu", player)
            if clearSelectedTarget then
                calibrationLock.handleAction({ interactionType = interactionType, action = "clear" }, "clear_test_actors_target_removed", ctx)
            end
            sendCalibrationMenuStatus(player, message, { cleared = clearSelectedTarget == true, fillOrTestExists = calibrationFillOrTestExists(player) })
            return
        end
        if action == "clear" then
            local session = calibrationLock.ensureSession(interactionType, ctx, "developer_menu_clear_target")
            local actor = session and session.actor or nil
            local recordId = actor and actor.recordId and string.lower(tostring(actor.recordId)) or ""
            local shiftHandled, shiftMessage = false, nil
            if ev and ev.shiftDown == true and actor then
                shiftHandled, shiftMessage = shiftClearSelectedCalibrationActorTarget(session, actor, "developer_menu_shift_clear_target")
            end
            if shiftHandled then
                -- Shift+Clear Target has already stopped/restored/removed the selected calibration actor.
            elseif isCalibrationTestNpcRecord(recordId) then
                removeCalibrationTestNpc("developer_menu_clear_target", player, { silent = true })
            elseif actor and actor.id then
                local assignedActors = getAssignedActors()
                local stopInteractionForNpc = env.stopInteractionForNpc and env.stopInteractionForNpc() or nil
                local assignment = currentAssignmentForSession(session)
                if assignedActors and assignedActors[actor.id] and assignment and stopInteractionForNpc then
                    pcall(function() stopInteractionForNpc(actor, "developer_menu_clear_target", actor.id) end)
                    pcall(function()
                        actor:sendEvent("StopInteractionObject", {
                            reason = "developer_menu_clear_target",
                            interactionType = session and session.interactionType or interactionType,
                        })
                    end)
                    pcall(function()
                        actor:sendEvent("SitDownPleaseClearBriefTravel", { reason = "developer_menu_clear_target" })
                    end)
                    infoLog(
                        "calibration_clear_target_actor_released",
                        "actor", tostring(actor.recordId or actor.id),
                        "type", tostring(assignment.interactionType),
                        "object", tostring(assignment.objectId or assignment.object and assignment.object.recordId),
                        "slot", tostring(assignment.slotName or assignment.slotKey),
                        "originKnown", tostring(assignment.preInteractionPos ~= nil)
                    )
                else
                    infoLog("calibration_clear_target_ui_only", "actor", tostring(actor.recordId or actor.id), "reason", "target_not_owned")
                end
            end
            calibrationLock.handleAction({ interactionType = interactionType, action = "clear" }, "developer_menu_clear", ctx)
            sendCalibrationMenuStatus(player, shiftMessage or "Target cleared.", { cleared = true })
            return
        end
        if action == "resume" or action == "reapply" or action == "reenter" or action == "send" then
            local selectedStationSession = nil
            if interactionType == "station" then
                selectedStationSession = calibrationLock.ensureSession(interactionType, ctx, "developer_menu_station_retain")
            else
                local currentSession = calibrationLock.currentSession(interactionType, ctx)
                if currentSession and currentSession.interactionType == "station" then
                    selectedStationSession = currentSession
                elseif interactionType == "auto" then
                    local stationSession = calibrationLock.currentSession("station", ctx)
                    if stationSession and stationSession.interactionType == "station" then
                        selectedStationSession = stationSession
                    end
                end
            end
            if selectedStationSession and selectedStationSession.interactionType == "station" then
                local session = selectedStationSession
                local lectureOptions = stationStartLectureOptions(ev)
                lectureTrace.log(
                    debugLog,
                    "start_button_path_entered",
                    "action", tostring(action),
                    "filter", tostring(interactionType),
                    "shift", tostring(ev and ev.shiftDown == true),
                    "teleport", tostring(lectureOptions.teleportAudience == true)
                )
                lectureTrace.log(
                    debugLog,
                    "shift_state_detected",
                    "shiftDown", tostring(ev and ev.shiftDown == true),
                    "shift", tostring(ev and ev.shift == true),
                    "shiftKey", tostring(ev and ev.shiftKey == true),
                    "teleport", tostring(lectureOptions.teleportAudience == true)
                )
                lectureTrace.log(
                    debugLog,
                    "station_target_resolved",
                    "ok", tostring(session and session.object ~= nil),
                    "object", tostring(session and session.objectRecordId),
                    "slot", tostring(session and session.slotKey)
                )
                lectureTrace.log(
                    debugLog,
                    "presenter_resolved",
                    "actor", tostring(session and session.actor and (session.actor.recordId or session.actor.id)),
                    "actorId", tostring(session and session.actorId)
                )
                lectureTrace.log(debugLog, "session_start_refresh_called", "path", "start_button", "object", tostring(session and session.objectRecordId), "slot", tostring(session and session.slotKey))
                local started = session and triggerStationLecture and triggerStationLecture(session, lectureOptions) or false
                lectureTrace.log(debugLog, "session_start_refresh_result", "path", "start_button", "started", tostring(started == true))
                local fallbackMessage, fallbackStatus = nil, nil
                if session and not started then
                    lectureTrace.log(debugLog, "start_button_station_fallback_assign", "object", tostring(session.objectRecordId), "slot", tostring(session.slotKey))
                    local okAssign, assignMessage, assignStatus = assignNearestNpc("station", player, {
                        lookTarget = session.object,
                        targetRadius = 999999,
                        actorRadius = 999999,
                        stationClaimOptions = stationClaimOptions({ calibrationAction = false }),
                    })
                    started = okAssign == true
                    fallbackMessage = assignMessage
                    fallbackStatus = assignStatus
                    if started and triggerStationLecture then
                        lectureTrace.log(debugLog, "session_start_refresh_called", "path", "start_button_after_assign", "object", tostring(session.objectRecordId), "slot", tostring(session.slotKey))
                        triggerStationLecture(calibrationLock.session or session, lectureOptions)
                    end
                end
                sendCalibrationMenuStatus(
                    player,
                    session and (started and (lectureOptions.teleportAudience == true and "Starting the lecture with audience teleport..." or "Starting the lecture...") or "Station target retained. No eligible non-follower presenter could be assigned.") or "No station target selected.",
                    started and sessionStatusPayload(session, { silent = true }) or (fallbackStatus or (session and sessionStatusPayload(session) or nil))
                )
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            local selectedSession = calibrationLock.currentSession(interactionType, ctx)
            if selectedSession and selectedSession.actor and not selectedSession.object and not selectedSession.slotKey then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_actor_not_placed_yet")
                sendCalibrationMenuStatus(player, "Actor selected. Use Assign Nearest to choose a nearby slot before applying a pose.", sessionStatusPayload(selectedSession))
                sendCalibrationOffsetsForSession(player, selectedSession)
                return
            end
            if selectedSession and (selectedSession.interactionType == "sitting" or selectedSession.interactionType == "sleeping") and not selectedSession.actor then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_actor_not_placed_yet")
                sendCalibrationMenuStatus(player, "Target selected. Use Assign Nearest or Spawn Test NPC before applying a pose.", sessionStatusPayload(selectedSession))
                sendCalibrationOffsetsForSession(player, selectedSession)
                return
            end
            local session = calibrationLock.handleAction({ interactionType = interactionType, action = action }, "developer_menu_" .. tostring(action), ctx)
            local resumeMessage = "Asking target to sit again..."
            if session and session.interactionType == "sleeping" then
                resumeMessage = "Asking target to lie down again..."
            end
            sendCalibrationMenuStatus(
                player,
                action == "resume" and resumeMessage or (action == "reapply" and "Position reapplied." or "Sent the NPC back to the same furniture."),
                session and sessionStatusPayload(session, action == "resume" and { silent = true } or nil) or nil
            )
            sendCalibrationOffsetsForSession(player, session)
            return
        end

        local session
        local forceLookCaptureForVisualApproval = action == "print" and ev.visualApproval == true and ev.captureLookTarget == true
        if action == "print" and not forceLookCaptureForVisualApproval then
            session = calibrationLock.currentSession(interactionType, ctx)
        elseif action ~= "print" then
            session = calibrationLock.ensureSession(interactionType, ctx, "menu_" .. tostring(action))
        end
        if (not session or forceLookCaptureForVisualApproval) and action == "print" and ev.visualApproval == true then
            local constrained = false
            local lookTargetHasStation = false
            if lookTargetActorKind(ev and ev.lookTarget) and stationDataForNpc then
                local okStationData, stationData = pcall(stationDataForNpc, ev.lookTarget)
                lookTargetHasStation = okStationData and stationData and stationData.object ~= nil
            end
            local autoStationLookTarget = interactionType == "auto"
                and (
                    (profiles.stationProfileForObject and profiles.stationProfileForObject(ev and ev.lookTarget, settings) ~= nil)
                    or lookTargetHasStation
                )
            if not session and lookTargetActorKind(ev and ev.lookTarget) and interactionType ~= "station" and not autoStationLookTarget then
                session = captureDirectActorTarget(interactionType, player, ev.lookTarget)
                constrained = true
            end
            if not session and (interactionType == "station" or autoStationLookTarget) then
                session = captureStationSession(player, ev.lookTarget, ev.lookTargetPos)
                constrained = true
            end
            if not session and interactionType ~= "station" then
                session = captureLookedEmptyFurnitureTarget(interactionType, player, ev, "visual_approval_auto_select_empty_furniture")
            end
            if not session and interactionType ~= "station" then
                session, constrained = captureLookTargetSession(interactionType, player, ev.lookTarget, ev.lookTargetPos)
            end
            if not session and interactionType ~= "station" and (constrained == true or lookTargetFurnitureKind(ev and ev.lookTarget)) then
                session = captureNearestCandidateTarget(interactionType, player, {
                    lookTarget = ev.lookTarget,
                    lookTargetPos = ev.lookTargetPos,
                    targetRadius = 1400,
                    reason = "visual_approval_auto_select_empty_furniture",
                })
            end
            if not session and interactionType ~= "station" then
                session = captureViewConeSession(interactionType, player, ev.lookTargetPos)
            end
            if session then
                infoLog("calibration visual approval auto-selected target", "filter", tostring(interactionType), "target", tostring(calibrationLock.sessionLabel(session)), "lookTarget", tostring(ev and ev.lookTarget and (ev.lookTarget.recordId or ev.lookTarget.id) or "<none>"))
                sendCalibrationOffsetsForSession(player, session)
            end
        end
        if not session then
            infoLog("calibration menu action failed", tostring(action), tostring(interactionType), "reason", "no_current_calibration_target")
            sendCalibrationMenuStatus(player, "No target selected. Click Find Target first.")
            return
        end
        local effectiveType = session.interactionType or interactionType
        if action == "print" then
            if ev.visualApproval == true then
                local linked = ev.linkSameFurnitureSlots == true and sendSiblingLinkedVisualApproval(session, effectiveType) or 0
                local logged = logVisualApproval(session, currentAssignmentForSession(session) or session, false)
                local suffix = linked > 0 and (" Also logged " .. tostring(linked) .. " same-furniture sibling slot approval" .. (linked == 1 and "" or "s") .. ".") or ""
                if ev.linkSameFurnitureSlots == true and linked == 0 then
                    suffix = " No occupied same-furniture sibling slots were available to approve."
                end
                sendCalibrationMenuStatus(player, logged and ("Visual approval logged to openmw.log." .. suffix) or "No target selected for visual approval.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            if effectiveType == "station" then
                local cal = session.calibration or {}
                local unchanged = calibrationOffsetUnchanged(cal)
                if unchanged then
                    infoLog(
                        "NO_CHANGE_APPROVAL",
                        "kind", "station",
                        "actor", tostring(session.actor and (session.actor.recordId or session.actor.id)),
                        "actorScale", tostring(session.actor and session.actor.scale),
                        "object", tostring(session.objectRecordId),
                        "model", tostring(session.objectModelPath or session.model or objectModelPath(session.object)),
                        "objectScale", tostring(session.object and session.object.scale),
                        "profile", tostring(session.profileId),
                        "profileSource", tostring(session.profileSelectionSource),
                        "profileKey", tostring(session.profileSelectionKey),
                        "slot", tostring(session.slotName),
                        "cell", tostring(session.cellName),
                        "simTime", tostring(core.getSimulationTime and core.getSimulationTime() or nil)
                    )
                    sendCalibrationMenuStatus(player, "No changes found; approval logged to openmw.log.", sessionStatusPayload(session))
                    return
                end
                print("[SitDownPlease Calibration Export]",
                    "STATION_METADATA",
                    "object", tostring(session.objectRecordId),
                    "model", tostring(session.objectModelPath or session.model or objectModelPath(session.object)),
                    "objectScale", tostring(session.object and session.object.scale),
                    "actor", tostring(session.actor and (session.actor.recordId or session.actor.id)),
                    "actorScale", tostring(session.actor and session.actor.scale),
                    "profile", tostring(session.profileId),
                    "profileSource", tostring(session.profileSelectionSource),
                    "profileKey", tostring(session.profileSelectionKey),
                    "slot", tostring(session.slotName),
                    "cell", tostring(session.cellName),
                    "simTime", tostring(core.getSimulationTime and core.getSimulationTime() or nil)
                )
                print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/stationProfiles.txt", "TARGET", tostring(session.objectRecordId), "PROFILE", tostring(session.profileId), "SLOT", tostring(session.slotName))
                print("[SitDownPlease Calibration Export]", "STATION_PROFILE_ROW", calibrationExport.stationProfileRow({
                    object = session.object,
                    objectId = session.objectRecordId,
                    profile = session.profile,
                    profileId = session.profileId,
                    profileOffset = session.profileOffset,
                    calibration = session.calibration,
                    slotName = session.slotName,
                    profiles = profiles,
                }))
                print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/stationProfileVariants.txt", "TARGET", tostring(session.objectRecordId), "PROFILE", tostring(session.profileId), "SLOT", tostring(session.slotName))
                print("[SitDownPlease Calibration Export]", "STATION_PROFILE_VARIANT_ROW", calibrationExport.stationProfileVariantRow({
                    object = session.object,
                    objectId = session.objectRecordId,
                    profile = session.profile,
                    profileId = session.profileId,
                    profileOffset = session.profileOffset,
                    calibration = session.calibration,
                    slotName = session.slotName,
                    profiles = profiles,
                }))
                print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/stationObjectOverrides.txt", "TARGET", tostring(session.objectRecordId), "PROFILE", tostring(session.profileId), "SLOT", tostring(session.slotName))
                print("[SitDownPlease Calibration Export]", "STATION_OBJECT_OVERRIDE_ROW", calibrationExport.stationProfileVariantRow({
                    object = session.object,
                    objectId = session.objectRecordId,
                    profile = session.profile,
                    profileId = session.profileId,
                    profileOffset = session.profileOffset,
                    calibration = session.calibration,
                    slotName = session.slotName,
                    profiles = profiles,
                    objectScoped = true,
                }))
                infoLog("STATION_PROFILE_ROW", calibrationExport.stationProfileRow({
                    object = session.object,
                    objectId = session.objectRecordId,
                    profile = session.profile,
                    profileId = session.profileId,
                    profileOffset = session.profileOffset,
                    calibration = session.calibration,
                    slotName = session.slotName,
                    profiles = profiles,
                }))
                sendCalibrationMenuStatus(player, "Profile line printed to openmw.log.", sessionStatusPayload(session))
                return
            end
            if not session.actor then
                infoLog("calibration print skipped no actor", "type", tostring(effectiveType), "object", tostring(session.objectRecordId), "slot", tostring(session.slotName))
                sendCalibrationMenuStatus(player, "Target selected, but no actor is assigned. Use Assign Nearest before printing a profile line.", sessionStatusPayload(session))
                return
            end
            session.actor:sendEvent(effectiveType == "sleeping" and "SitDownPleasePrintSleepCalibration" or "SitDownPleasePrintSittingCalibration", { reason = "developer_menu" })
            local linked = ev.linkSameFurnitureSlots == true and sendSiblingLinkedPrint(session, effectiveType) or 0
            local suffix = linked > 0 and (" Also requested " .. tostring(linked) .. " same-furniture sibling slot print" .. (linked == 1 and "" or "s") .. ".") or ""
            if ev.linkSameFurnitureSlots == true and linked == 0 then
                suffix = " No occupied same-furniture sibling slots were available to print."
            end
            local cal = session.calibration or {}
            local unchanged = calibrationOffsetUnchanged(cal) and sessionHasPrintEvidenceContext(session) ~= true
            local message = unchanged and "No changes found; approval logged to openmw.log." or "Profile line printed to openmw.log."
            sendCalibrationMenuStatus(player, message .. suffix, sessionStatusPayload(session))
            return
        end
        if action == "reset" then
            if effectiveType == "station" then
                session.calibration = zeroCalibrationOffset()
                if applyStationCalibration then
                    local ok, reason = applyStationCalibration(session)
                    if not ok then infoLog("station calibration reset apply failed", tostring(reason)) end
                end
                sendCalibrationMenuStatus(player, "Resetting to saved profile...", sessionStatusPayload(session, { silent = true }))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            if not session.actor then
                session.calibration = zeroCalibrationOffset()
                sendCalibrationMenuStatus(player, "Target selected, but no actor is assigned. Saved offsets are shown without moving an NPC.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            local activeAssignment = currentAssignmentForSession(session)
            local currentActorAssignment = currentActorAssignmentForSession(session)
            if not activeAssignment and currentActorAssignment then
                infoLog(
                    "calibration_action_inert",
                    tostring(action),
                    "reason", "calibration_target_stale",
                    "target", tostring(calibrationLock.sessionLabel(session)),
                    "currentSlot", tostring(currentActorAssignment.slotKey),
                    "selectedSlot", tostring(session.slotKey)
                )
                sendCalibrationMenuStatus(player, "Selected target is stale; reselect the actor or furniture before resetting.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            session.calibration = zeroCalibrationOffset()
            local resetObject = (activeAssignment and activeAssignment.object) or session.object
            session.actor:sendEvent(effectiveType == "sleeping" and "SitDownPleaseResetSleepCalibration" or "SitDownPleaseResetSittingCalibration", {
                reason = "developer_menu",
                objectId = resetObject and resetObject.recordId or (activeAssignment and activeAssignment.objectId) or session.objectRecordId,
                objectRecordId = resetObject and resetObject.recordId or (activeAssignment and activeAssignment.objectRecordId) or session.objectRecordId,
                slotKey = (activeAssignment and activeAssignment.slotKey) or session.slotKey,
                slotName = (activeAssignment and activeAssignment.slotName) or session.slotName,
            })
            sendCalibrationMenuStatus(player, "Resetting to saved profile...", sessionStatusPayload(session, { silent = true }))
            return
        end
        if action == "nudge" then
            if effectiveType == "station" then
                session.calibration = session.calibration or zeroCalibrationOffset()
                session.calibration.x = (tonumber(session.calibration.x) or 0) + (tonumber(ev.x) or 0)
                session.calibration.y = (tonumber(session.calibration.y) or 0) + (tonumber(ev.y) or 0)
                session.calibration.z = (tonumber(session.calibration.z) or 0) + (tonumber(ev.z) or 0)
                session.calibration.yaw = (tonumber(session.calibration.yaw) or 0) + (tonumber(ev.yaw) or 0)
                if applyStationCalibration then
                    local ok, reason = applyStationCalibration(session)
                    if not ok then infoLog("station calibration nudge apply failed", tostring(reason)) end
                end
                sendCalibrationMenuStatus(player, "Position changed for " .. calibrationLock.sessionLabel(session) .. ".", sessionStatusPayload(session, { silent = true }))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            local activeAssignment = currentAssignmentForSession(session)
            local currentActorAssignment = currentActorAssignmentForSession(session)
            if not activeAssignment and currentActorAssignment then
                infoLog(
                    "calibration_action_inert",
                    tostring(action),
                    "reason", "calibration_target_stale",
                    "target", tostring(calibrationLock.sessionLabel(session)),
                    "currentSlot", tostring(currentActorAssignment.slotKey),
                    "selectedSlot", tostring(session.slotKey)
                )
                sendCalibrationMenuStatus(player, "Selected target is stale; reselect the actor or furniture before nudging.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            local nudgeSource = activeAssignment or session
            local nudgeActor = nudgeSource.actor or nudgeSource.npc or session.actor or session.npc
            local nudgeObject = nudgeSource.object or session.object
            if not nudgeActor or not nudgeObject then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_actor_not_placed_yet")
                sendCalibrationMenuStatus(player, "Target selected, but no actor/furniture placement is assigned. Use Assign Nearest or Spawn Test NPC before nudging.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            if nudgeSource.externalPhysicalClaimed == true or session.externalPhysicalClaimed == true then
                infoLog("calibration_action_inert", tostring(action), "reason", "calibration_external_actor_controlled")
                sendCalibrationMenuStatus(player, "Target is externally animated; nudge is disabled for this actor.", sessionStatusPayload(session))
                sendCalibrationOffsetsForSession(player, session)
                return
            end
            if not activeAssignment then
                infoLog("calibration_nudge_sent_pending", "reason", "calibration_target_unowned", "target", tostring(calibrationLock.sessionLabel(session)))
            elseif activeAssignment.state ~= interactingState then
                infoLog("calibration_nudge_sent_pending", "reason", "calibration_actor_not_placed_yet", "target", tostring(calibrationLock.sessionLabel(session)), "state", tostring(activeAssignment.state))
            end
            session.calibration = session.calibration or zeroCalibrationOffset()
            session.calibration.x = (tonumber(session.calibration.x) or 0) + (tonumber(ev.x) or 0)
            session.calibration.y = (tonumber(session.calibration.y) or 0) + (tonumber(ev.y) or 0)
            session.calibration.z = (tonumber(session.calibration.z) or 0) + (tonumber(ev.z) or 0)
            session.calibration.yaw = (tonumber(session.calibration.yaw) or 0) + (tonumber(ev.yaw) or 0)
            if activeAssignment then
                activeAssignment.calibration = activeAssignment.calibration or zeroCalibrationOffset()
                activeAssignment.calibration.x = (tonumber(activeAssignment.calibration.x) or 0) + (tonumber(ev.x) or 0)
                activeAssignment.calibration.y = (tonumber(activeAssignment.calibration.y) or 0) + (tonumber(ev.y) or 0)
                activeAssignment.calibration.z = (tonumber(activeAssignment.calibration.z) or 0) + (tonumber(ev.z) or 0)
                activeAssignment.calibration.yaw = (tonumber(activeAssignment.calibration.yaw) or 0) + (tonumber(ev.yaw) or 0)
            end
            nudgeActor:sendEvent(effectiveType == "sleeping" and "SitDownPleaseNudgeSleepCalibration" or "SitDownPleaseNudgeSittingCalibration", {
                x = ev.x,
                y = ev.y,
                z = ev.z,
                yaw = ev.yaw,
                syncSlotZ = ev.syncSlotZ,
                syncSlotXY = ev.syncSlotXY,
                syncSlotYaw = ev.syncSlotYaw,
                objectId = nudgeObject and nudgeObject.recordId or nudgeSource.objectId or session.objectRecordId,
                objectRecordId = nudgeObject and nudgeObject.recordId or nudgeSource.objectRecordId or session.objectRecordId,
                slotKey = nudgeSource.slotKey or session.slotKey,
                slotName = nudgeSource.slotName or session.slotName,
                reason = "developer_menu",
            })
            local synced, syncedAxes = sendSiblingLinkedNudge(session, effectiveType, ev)
            if synced > 0 then
                infoLog("calibration linked-slot sync applied", "type", tostring(effectiveType), "object", tostring(session.objectRecordId or session.objectId), "sourceSlot", tostring(session.slotName), "siblings", tostring(synced), "axes", tostring(syncedAxes), "x", tostring(ev.x), "y", tostring(ev.y), "z", tostring(ev.z), "yaw", tostring(ev.yaw))
            end
            sendCalibrationMenuStatus(player, "Position changed for " .. calibrationLock.sessionLabel(session) .. ".", sessionStatusPayload(session, { silent = true }))
            sendCalibrationOffsetsForSession(player, session)
            return
        end
        infoLog("calibration menu action failed", tostring(action), tostring(interactionType), "reason", "unsupported_action")
        sendCalibrationMenuStatus(player, "That calibration button is not supported in this build: " .. tostring(action))
    end

    M.isCalibrationFillActor = function(actor)
        if not (actor and actor.id) then return false end
        if isObjValid(calibrationTestNpc) and calibrationTestNpc == actor then return true end
        if calibrationTestNpcs[actor.id] ~= nil then return true end
        if calibrationFillActors[actor.id] ~= nil then return true end
        if fillIdentityForActor(actor) ~= nil then return true end
        return false
    end

    M.removeCalibrationTestNpc = removeCalibrationTestNpc
    M.clearCalibrationTestNpcs = function(reason)
        local ok, message = removeCalibrationTestNpc(reason or "developer_test_npc_cleanup", nil, { silent = false })
        if ok == true and message then
            for _, player in ipairs(world.players or {}) do
                sendCalibrationMenuStatus(player, message .. " Fill cleanup ran because the cell changed.", { cleared = true, fillOrTestExists = calibrationFillOrTestExists(player) })
            end
        end
        return ok, message
    end
    return M
end

return module
