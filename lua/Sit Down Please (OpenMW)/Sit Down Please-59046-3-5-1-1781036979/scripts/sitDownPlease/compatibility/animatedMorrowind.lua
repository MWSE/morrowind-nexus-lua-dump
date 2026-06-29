-- compatibility/animatedMorrowind.lua
---@omw-context none
--
-- Narrow visual alignment assist for external animated seated actors. This is
-- intentionally not a sitting system: it only identifies known seated actor
-- families and bounds whether a one-shot Z correction is safe to consider.

local M = {}
local externalAnimationCompat = require('scripts/sitDownPlease/compatibility/externalAnimations')

M.SETTING_KEY = "animatedMorrowindAlignmentAssist"

M.SEAT_RADIUS = 118
M.SEAT_VERTICAL_TOLERANCE = 90
M.TABLE_TASK_SEAT_RADIUS = 220
M.TABLE_TASK_SEAT_VERTICAL_TOLERANCE = 175
M.AMBIGUOUS_DISTANCE = 12
M.MIN_Z_ERROR = 6
-- AM writer/reader chair roots can be around 65-70 units above SDP's seated
-- root estimate. Keep the cap bounded, but high enough for observed AM chairs.
M.MAX_Z_CORRECTION = 120
M.WRITER_SURFACE_TASK_LIFT = 14
M.WRITER_LOW_SEAT_TASK_LIFT = 8
M.WRITER_LOW_SEAT_ROOT_DELTA_MAX = 35
-- External Animated Morrowind sitters are pre-posed meshes, not SDP actors
-- playing SitIdle1 from the normal OpenMW actor root. Target the sampled seat
-- surface instead of SDP's seated root so the assist does not push them into
-- stools/chairs when the two root conventions differ.
M.EXTERNAL_SEATED_ROOT_SURFACE_OFFSET = 20
M.DEFAULT_SETTLE_ATTEMPTS = 3
M.DEFAULT_SETTLE_SECONDS = 3.0
M.DEFAULT_SETTLE_INTERVAL = 0.55
-- Animated Morrowind's bard pose/root is controller-owned. SDP recognizes AM
-- bards as external seated actors, but does not Z-correct them because AM
-- restores their position and visible correction becomes bouncing.
-- AM writer roots are controller-owned in practice. SDP should still compute
-- the real-chair correction, but hand the corrected position to ODAR's static
-- actor controller when available instead of running its own settle loop.

local KNOWN_CONTENT_FILES = {
    ["animated_morrowind - merged.esp"] = true,
    ["animated_morrowind.esp"] = true,
    ["animated morrowind.esp"] = true,
}

local EXTERNAL_PLACEMENT_PATCH_FILES = {
    ["Animated Morrowind and BCOM OpenMW Patch.omwaddon"] = true,
    ["animated morrowind and bcom openmw patch.omwaddon"] = true,
}

local EXTERNAL_PLACEMENT_PATCH_POSITIONED_IDS = {
    ["am_eaternight12"] = true,
    ["am_reader3"] = true,
    ["am_reader8"] = true,
    ["am_sitter5"] = true,
    ["am_sitternight6"] = true,
    ["am_slavesittingkm"] = true,
}

-- Narrow Phase 2 compatibility debt: AM_Writer-family actors use a real chair,
-- but their root/controller behavior differs from ordinary SDP sitters.
local AM_WRITER_REAL_CHAIR_PREFIXES = {
    "am_writer",
}

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function actorRecordIdHasPrefix(actor, prefixes)
    local recordId = lower(actor and actor.recordId)
    if recordId == "" then return false end
    for _, prefix in ipairs(prefixes or {}) do
        if recordId:find("^" .. prefix) ~= nil then return true end
    end
    return false
end

local function horizontalDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end
M.horizontalDistance = horizontalDistance

function M.contentFileLooksLikeAnimatedMorrowind(fileName)
    local name = lower(fileName)
    if name == "" then return false end
    if KNOWN_CONTENT_FILES[name] then return true end
    -- Also catch common repacks/renames while avoiding generic "animated"
    -- matches. A compat patch with this token is enough to make the assist
    -- available, but actor targeting still stays restricted to known AM sitters.
    if name:find("animated_morrowind", 1, true) then return true end
    if name:find("animatedmorrowind", 1, true) then return true end
    return false
end

function M.detectContent(core)
    if not (core and core.contentFiles) then return false, "missing_contentfiles_api" end

    if core.contentFiles.has then
        for fileName in pairs(KNOWN_CONTENT_FILES) do
            local ok, present = pcall(core.contentFiles.has, fileName)
            if ok and present == true then return true, fileName end
        end
    end

    local list = core.contentFiles.list
    if type(list) == "table" then
        for _, fileName in ipairs(list) do
            if M.contentFileLooksLikeAnimatedMorrowind(fileName) then
                return true, tostring(fileName)
            end
        end
    end

    return false, "not_in_load_order"
end

function M.detectExternalPlacementPatch(core)
    if not (core and core.contentFiles) then return false, "missing_contentfiles_api" end

    if core.contentFiles.has then
        for fileName in pairs(EXTERNAL_PLACEMENT_PATCH_FILES) do
            local ok, present = pcall(core.contentFiles.has, fileName)
            if ok and present == true then return true, fileName end
        end
    end

    local list = core.contentFiles.list
    if type(list) == "table" then
        for _, fileName in ipairs(list) do
            local name = lower(fileName)
            if EXTERNAL_PLACEMENT_PATCH_FILES[name] then
                return true, tostring(fileName)
            end
        end
    end

    return false, "not_in_load_order"
end

function M.externalPlacementPatchOwnsActor(actor)
    return EXTERNAL_PLACEMENT_PATCH_POSITIONED_IDS[lower(actor and actor.recordId)] == true
end

function M.knownSittingActorReason(actor)
    return externalAnimationCompat.knownSittingActorReason(actor)
end

function M.candidateLooksLikeSeat(candidate, profiles)
    if not (candidate and candidate.object and candidate.interactionType == "sitting") then return false, "not_sitting_candidate" end
    local category = nil
    if profiles and profiles.sittingSeatCategory then
        category = profiles.sittingSeatCategory(candidate.profile, candidate.object)
    else
        category = candidate.profile and (candidate.profile.seatCategory or candidate.profile.type) or nil
    end
    category = lower(category)
    if category == "chair" or category == "backedchair" then category = "backed_chair" end
    if category == "stool" or category == "barstool" or category == "bench" or category == "backed_chair" or category == "single_seat_bench" then
        return true, category
    end
    return false, "unsupported_seat_category:" .. tostring(category)
end

function M.chooseNearbySeat(actor, candidates, profiles)
    if not (actor and actor.position and candidates) then return nil, "missing_actor_or_candidates" end

    local best, bestDist, bestVertical, bestScore = nil, nil, nil, nil
    local ambiguous = false
    local bestObjectId = nil
    local tableTaskActor = M.actorUsesTableTaskSeat(actor)

    for _, candidate in ipairs(candidates) do
        local ok, category = M.candidateLooksLikeSeat(candidate, profiles)
        local obj = ok and candidate.object or nil
        if obj and obj.position then
            local dist = horizontalDistance(actor.position, obj.position)
            local vertical = math.abs((actor.position.z or 0) - (obj.position.z or 0))
            local tableTaskSeat = tableTaskActor == true and M.candidateLooksLikeTableTaskSeat(candidate, category)
            local radius = tableTaskSeat and M.TABLE_TASK_SEAT_RADIUS or M.SEAT_RADIUS
            local verticalTolerance = tableTaskSeat and M.TABLE_TASK_SEAT_VERTICAL_TOLERANCE or M.SEAT_VERTICAL_TOLERANCE
            if dist and dist <= radius and vertical <= verticalTolerance then
                local score = dist
                if tableTaskSeat then
                    score = score - 70
                    local kind = lower(candidate and candidate.facingKind)
                    if kind == "table" or kind == "bar" then score = score - 45 end
                end
                if not bestScore or score < bestScore then
                    best = candidate
                    bestDist = dist
                    bestVertical = vertical
                    bestScore = score
                    bestObjectId = obj.id or obj.recordId
                    ambiguous = false
                elseif bestScore and math.abs(score - bestScore) <= M.AMBIGUOUS_DISTANCE then
                    local objectId = obj.id or obj.recordId
                    if objectId ~= bestObjectId then ambiguous = true end
                end
            end
        end
    end

    if ambiguous then return nil, "ambiguous_nearby_seats" end
    if best then return best, nil, bestDist, bestVertical end
    return nil, "no_nearby_plausible_seat"
end

function M.minZErrorForActor(actor)
    return M.MIN_Z_ERROR
end

function M.correctionTarget(currentZ, expectedZ, actor)
    currentZ = tonumber(currentZ)
    expectedZ = tonumber(expectedZ)
    if not (currentZ and expectedZ) then return nil, "missing_z" end

    local delta = expectedZ - currentZ
    local absDelta = math.abs(delta)
    if absDelta < M.minZErrorForActor(actor) then return nil, "within_tolerance", delta end
    if absDelta > M.MAX_Z_CORRECTION then return nil, "correction_too_large", delta end
    return expectedZ, nil, delta
end

function M.actorUsesSurfaceRootOffset(actor)
    local recordId = lower(actor and actor.recordId)
    return recordId:find("^am_sitter") ~= nil
        or recordId:find("^am_sitternight") ~= nil
        or recordId:find("^am_slavesitting") ~= nil
        or recordId:find("^am_bard") ~= nil
        or recordId:find("barguy", 1, true) ~= nil
end

function M.actorUsesSdpRootOffset(actor)
    local recordId = lower(actor and actor.recordId)
    return M.actorIsWriterRealChair(actor)
        or recordId:find("^am_reader") ~= nil
        or recordId:find("^am_eater") ~= nil
end

function M.actorUsesTableTaskSeat(actor)
    return M.actorUsesSdpRootOffset(actor)
end

function M.actorIsWriterRealChair(actor)
    return actorRecordIdHasPrefix(actor, AM_WRITER_REAL_CHAIR_PREFIXES)
end

function M.externalPlacementController(actor)
    if M.actorIsWriterRealChair(actor) then
        return "odar_static_actor"
    end
    return nil
end

function M.candidateLooksLikeTableTaskSeat(candidate, category)
    category = lower(category)
    if category ~= "backed_chair" and category ~= "single_seat_bench" then return false end
    local kind = lower(candidate and candidate.facingKind)
    if kind == "table" or kind == "bar" then return true end
    return candidate and candidate.facingObjectPosition ~= nil
end

function M.settlePolicyForActor(actor)
    local controller = M.externalPlacementController(actor)
    if controller then return 0, 0, M.DEFAULT_SETTLE_INTERVAL, controller end
    return M.DEFAULT_SETTLE_ATTEMPTS, M.DEFAULT_SETTLE_SECONDS, M.DEFAULT_SETTLE_INTERVAL, "default"
end

function M.writerTaskLift(actor, sdpExpectedZ, originalZ)
    if M.actorIsWriterRealChair(actor) then
        return M.WRITER_LOW_SEAT_TASK_LIFT, "sdp_root_offset_writer_task_lift_low_seat"
    end
    sdpExpectedZ = tonumber(sdpExpectedZ)
    originalZ = tonumber(originalZ)
    if sdpExpectedZ and originalZ then
        local currentRootDelta = originalZ - sdpExpectedZ
        if currentRootDelta <= M.WRITER_LOW_SEAT_ROOT_DELTA_MAX then
            return M.WRITER_LOW_SEAT_TASK_LIFT, "sdp_root_offset_writer_task_lift_low_seat"
        end
    end
    return M.WRITER_SURFACE_TASK_LIFT, "sdp_root_offset_writer_task_lift"
end

function M.expectedExternalSeatedZ(actor, surfaceZ, sdpExpectedZ, originalZ)
    local recordId = lower(actor and actor.recordId)
    if M.actorUsesSdpRootOffset(actor) then
        sdpExpectedZ = tonumber(sdpExpectedZ)
        if not sdpExpectedZ then return nil, "missing_sdp_expected_z" end
        if M.actorIsWriterRealChair(actor) then
            local lift, reason = M.writerTaskLift(actor, sdpExpectedZ, originalZ)
            return sdpExpectedZ + lift, reason
        end
        return sdpExpectedZ, "sdp_root_offset"
    end
    if not M.actorUsesSurfaceRootOffset(actor) then return nil, "unsupported_external_root_family" end
    if recordId:find("^am_bard") ~= nil then
        return nil, "am_bard_controller_owned"
    end
    surfaceZ = tonumber(surfaceZ)
    if not surfaceZ then return nil, "missing_surface_z" end
    return surfaceZ + M.EXTERNAL_SEATED_ROOT_SURFACE_OFFSET, "surface_root_offset"
end

local EXTERNAL_SURFACE_PROFILE = {
    profileId = "external_am_surface_seat",
    interactionType = "sitting",
    type = "stool",
    seatCategory = "stool",
    animation = "sitidle1",
    finalForwardOffset = -7,
    finalZOffset = -36,
    rotationMode = "faceOpenSide",
    allowPerFrameCorrection = true,
    allowFallbackPositioning = true,
    externalProfile = true,
    surfaceRootOnly = true,
}

local function externalSurfaceSupportText(obj, helpers)
    helpers = helpers or {}
    local recordId = tostring(obj and (obj.recordId or obj.id) or "")
    local model = helpers.objectModelPath and tostring(helpers.objectModelPath(obj) or "") or ""
    local name = helpers.objectName and tostring(helpers.objectName(obj) or "") or ""
    return lower(recordId .. " " .. model .. " " .. name)
end

local function objectLooksLikeExternalSeatSurface(obj, helpers)
    if not (obj and obj.position) then return false end
    if helpers and helpers.isObjValid and helpers.isObjValid(obj) ~= true then return false end
    local text = externalSurfaceSupportText(obj, helpers)
    if text:find("barrel", 1, true) or text:find("sack", 1, true) or text:find("basket", 1, true) then return false end
    return text:find("chest", 1, true) ~= nil
        or text:find("crate", 1, true) ~= nil
        or text:find("box", 1, true) ~= nil
end

function M.chooseExternalSurfaceSeat(actor, cell, helpers)
    if not (actor and actor.position and cell) then return nil, "missing_actor_or_cell" end
    if M.actorUsesTableTaskSeat(actor) then return nil, "table_task_actor_requires_real_seat" end
    helpers = helpers or {}
    local best, bestDist, bestVertical = nil, nil, nil
    local ambiguous = false
    for _, obj in ipairs(cell:getAll()) do
        if obj ~= actor and objectLooksLikeExternalSeatSurface(obj, helpers) then
            local dist = horizontalDistance(actor.position, obj.position)
            local vertical = math.abs((actor.position.z or 0) - (obj.position.z or 0))
            if dist and dist <= M.SEAT_RADIUS and vertical <= (M.SEAT_VERTICAL_TOLERANCE + 55) then
                if not bestDist or dist < bestDist then
                    best = obj
                    bestDist = dist
                    bestVertical = vertical
                    ambiguous = false
                elseif bestDist and math.abs(dist - bestDist) <= M.AMBIGUOUS_DISTANCE then
                    ambiguous = true
                end
            end
        end
    end
    if ambiguous then return nil, "ambiguous_external_support_surfaces", bestDist, bestVertical end
    if not best then return nil, "no_nearby_external_support_surface" end
    local slotName = "external_surface"
    return {
        object = best,
        objectId = best.recordId or best.id,
        model = helpers.objectModelPath and helpers.objectModelPath(best) or nil,
        profile = EXTERNAL_SURFACE_PROFILE,
        profileId = EXTERNAL_SURFACE_PROFILE.profileId,
        interactionType = "sitting",
        slot = { name = slotName },
        slotName = slotName,
        slotKey = helpers.objectSlotKey and helpers.objectSlotKey(best, slotName) or tostring(best.id or best.recordId or "<object>") .. "::" .. slotName,
        position = best.position,
        approachPos = best.position,
    }, nil, bestDist, bestVertical
end

return M
