-- Calibration menu cell audit orchestration. OpenMW APIs are passed in by the
-- caller entrypoint so this module can stay API-context agnostic.
---@omw-context none
local surfaceProbe = require('scripts/sitDownPlease/world/surfaceProbe')

local M = {}

local state = {
    lastCell = nil,
    lastAt = -100,
    sequence = 0,
    minInterval = 2.5,
    radius = 1800,
    maxCandidates = 36,
    maxSurfaceProbes = 8,
    auditedCells = {},
}

local function objectValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return obj:isValid() end)
    return ok and valid == true
end

local function cellKey(cell)
    if not cell then return "missing_cell" end
    local ok, value = pcall(function()
        return cell.name or cell.id
    end)
    if ok and value ~= nil then return tostring(value) end
    return tostring(cell)
end

local function distanceFromPlayer(player, pos)
    if not (pos and player and player.position) then return math.huge end
    local ok, value = pcall(function() return (pos - player.position):length() end)
    return ok and value or math.huge
end

local function objectLabel(obj)
    if not obj then return "<none>" end
    return tostring(obj.recordId or obj.id or "<unknown>")
end

local function objectModel(profiles, obj)
    local ok, value = pcall(function()
        return profiles.objectModelPath and profiles.objectModelPath(obj) or nil
    end)
    return ok and value or nil
end

local function yawBuckets(profiles, obj)
    local ok, buckets = pcall(function()
        return profiles.objectYawBuckets and profiles.objectYawBuckets(obj) or nil
    end)
    if not (ok and buckets) then return nil end
    return buckets
end

local function rayHitBelongsToObject(hitObject, obj)
    if hitObject == obj then return true end
    if not (hitObject and obj) then return false end
    local hitPos = hitObject.position
    local objPos = obj.position
    local positionsClose = false
    if hitPos and objPos then
        local ok, dist = pcall(function() return (hitPos - objPos):length() end)
        positionsClose = ok and dist <= 12
    end
    if hitObject.id and obj.id and hitObject.id == obj.id then
        return not (hitPos and objPos) or positionsClose
    end
    if hitObject.recordId and obj.recordId and hitObject.recordId == obj.recordId then
        return positionsClose
    end
    return false
end

local function profileFor(profiles, settings, obj, interactionType)
    local ok, profile, reason = pcall(function()
        return profiles.getProfileForObject(obj, interactionType, settings)
    end)
    if ok then return profile, reason end
    return nil, tostring(profile)
end

local function candidateFor(env, obj, interactionType)
    local profile, reason = profileFor(env.profiles, env.settings, obj, interactionType)
    if profile then
        return {
            object = obj,
            interactionType = interactionType,
            profile = profile,
            reason = reason or "profile_selected",
            distance = distanceFromPlayer(env.player, obj.position),
        }
    end
    local okRelevant, relevant = pcall(function()
        return env.profiles.objectLooksRelevantForInteraction(obj, interactionType, env.settings)
    end)
    if okRelevant and relevant == true then
        return {
            object = obj,
            interactionType = interactionType,
            profile = nil,
            reason = reason or "relevant_without_profile",
            distance = distanceFromPlayer(env.player, obj.position),
        }
    end
    return nil
end

local function priority(candidate)
    if not candidate then return 1000 end
    local score = 0
    if not candidate.profile then score = score - 150 end
    local profile = candidate.profile
    local source = tostring(profile and profile.profileSelectionSource or "")
    if source:find("fallback", 1, true) or source == "bed_type_average" or source == "bed_type_average_low_confidence" then
        score = score - 80
    end
    local scale = tonumber(candidate.object and candidate.object.scale) or 1
    if math.abs(scale - 1) > 0.01 then score = score - 60 end
    return score + ((tonumber(candidate.distance) or 0) * 0.001)
end

local function printCandidate(env, sequence, index, candidate, probed)
    local obj = candidate.object
    local profile = candidate.profile
    local buckets = yawBuckets(env.profiles, obj) or {}
    local scale = tonumber(obj and obj.scale) or 1
    print("[SitDownPlease Calibration Audit]",
        "CELL_AUDIT_CANDIDATE",
        "audit_sequence", tostring(sequence),
        "index", tostring(index),
        "kind", tostring(candidate.interactionType),
        "object", objectLabel(obj),
        "model", tostring(objectModel(env.profiles, obj)),
        "profile", tostring(profile and profile.profileId or "<missing>"),
        "profileSource", tostring(profile and profile.profileSelectionSource or "<none>"),
        "profileKey", tostring(profile and profile.profileSelectionKey or "<none>"),
        "reason", tostring(candidate.reason),
        "distance", tostring(math.floor((tonumber(candidate.distance) or 0) + 0.5)),
        "objectScale", tostring(scale),
        "objectScaleNonStandard", tostring(math.abs(scale - 1) > 0.01),
        "yawBucket45", tostring(buckets.yawBucket45),
        "yawBucket90", tostring(buckets.yawBucket90),
        "surfaceProbe", tostring(probed == true)
    )
end

function M.run(env, reason, options)
    options = options or {}
    local cell = env.cell or (env.player and env.player.cell) or nil
    if not (cell and cell.getAll) then return false, "No player cell is available for audit." end
    local now = env.core.getRealTime()
    local key = cellKey(cell)
    if options.force ~= true
        and state.lastCell == key
        and now - (state.lastAt or -100) < state.minInterval then
        return false, "Cell audit already ran recently."
    end
    if options.force ~= true and state.auditedCells[key] == true then
        return false, "Cell audit already ran for this cell."
    end
    state.lastCell = key
    state.lastAt = now
    state.sequence = state.sequence + 1
    local sequence = state.sequence

    local okObjects, objects = pcall(function() return cell:getAll() end)
    if not (okObjects and objects) then return false, "Could not scan objects in this cell." end
    state.auditedCells[key] = true

    local candidates = {}
    local seen = {}
    local scanned = 0
    for _, obj in ipairs(objects) do
        if objectValid(obj) and obj.position then
            local dist = distanceFromPlayer(env.player, obj.position)
            if dist <= state.radius then
                scanned = scanned + 1
                for _, interactionType in ipairs({ "sleeping", "sitting" }) do
                    local candidate = candidateFor(env, obj, interactionType)
                    if candidate then
                        local seenKey = tostring(interactionType) .. "|" .. tostring(obj.id or obj.recordId)
                        if not seen[seenKey] then
                            seen[seenKey] = true
                            candidates[#candidates + 1] = candidate
                        end
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        local ap = priority(a)
        local bp = priority(b)
        if math.abs(ap - bp) > 0.001 then return ap < bp end
        local ad = tonumber(a.distance) or math.huge
        local bd = tonumber(b.distance) or math.huge
        if math.abs(ad - bd) > 0.01 then return ad < bd end
        return objectLabel(a.object) < objectLabel(b.object)
    end)

    local candidateCount = #candidates
    local limit = math.min(candidateCount, state.maxCandidates)
    local probeLimit = math.min(limit, state.maxSurfaceProbes)
    print("[SitDownPlease Calibration Audit]",
        "CELL_AUDIT",
        "audit_sequence", tostring(sequence),
        "reason", tostring(reason or "manual"),
        "cell", tostring(key),
        "objectsScanned", tostring(scanned),
        "candidates", tostring(candidateCount),
        "printed", tostring(limit),
        "surfaceProbes", tostring(probeLimit),
        "radius", tostring(state.radius)
    )

    for index = 1, limit do
        local candidate = candidates[index]
        local probed = index <= probeLimit and candidate.profile ~= nil
        printCandidate(env, sequence, index, candidate, probed)
        if probed then
            surfaceProbe.request({
                nearby = env.nearby,
                async = env.async,
                util = env.util,
                actor = env.player,
                profiles = env.profiles,
                rayHitBelongsToObject = rayHitBelongsToObject,
            }, {
                sequence = "audit-" .. tostring(sequence) .. "-" .. tostring(index),
                kind = candidate.interactionType,
                object = candidate.object,
                profile = candidate.profile,
                selectedSurface = nil,
                surfaceMode = "audit_probe",
                surfaceSamples = "audit",
            })
        end
    end

    if candidateCount == 0 then
        return true, "Audit complete: no nearby SDP furniture candidates."
    end
    local capped = candidateCount > limit and (" Printed top " .. tostring(limit) .. ".") or ""
    return true, "Audit complete: " .. tostring(candidateCount) .. " nearby candidate(s), " .. tostring(probeLimit) .. " surface probe(s)." .. capped
end

return M
