-- interactions/sitting/focusSelector.lua
---@omw-context none
-- Global sitting focus selection for tables, bars, fires, grinders, and lecture lecterns.

local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')

local M = {}

local function verboseLog(env, ...)
    if env and env.verboseLog then env.verboseLog(...) end
end

local function traceFocusCandidates(options)
    return options and options.traceFocusCandidates == true
end

local function directionBetween(util, fromPos, toPos)
    if not fromPos or not toPos then return nil end
    local delta = toPos - fromPos
    local flat = util.vector2(delta.x, delta.y)
    if flat:length() <= 1 then return nil end
    local norm = flat:normalize()
    return util.vector3(norm.x, norm.y, 0)
end

local function objectName(obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then return obj.type.record(obj) end
        return nil
    end)
    if ok and rec and rec.name then return rec.name end
    return nil
end

local function objectText(profiles, obj)
    if not obj then return "" end
    return objectMatchers.objectText(obj, profiles and profiles.objectModelPath, objectName(obj))
end

function M.objectForwardDirection(util, obj)
    local yaw = 0
    if obj and obj.rotation then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then yaw = value end
    end
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

function M.forwardDotToFocus(util, seatObj, fromPos, focusPos)
    local direction = directionBetween(util, fromPos, focusPos)
    if not direction then return nil end
    local forward = M.objectForwardDirection(util, seatObj)
    return (forward.x or 0) * (direction.x or 0) + (forward.y or 0) * (direction.y or 0)
end

function M.focusCompatible(util, kind, seatObj, profile, fromPos, focusPos)
    if kind ~= "lectern" then return true, nil end
    local category = tostring(profile and (profile.seatCategory or profile.type or profile.seatType) or ""):lower()
    local mode = tostring(profile and profile.rotationMode or ""):lower()
    local direction = directionBetween(util, fromPos, focusPos)
    if not direction then return false, "lectern_focus_missing_direction" end
    local forwardDot = M.forwardDotToFocus(util, seatObj, fromPos, focusPos)

    if category == "backed_chair"
        or mode == "respectfurnitureforward"
        or mode == "chairforward"
        or mode == "objectforward"
        or mode == "useobjectyaw" then
        if forwardDot and forwardDot < 0.35 then return false, "lectern_focus_chair_facing_away" end
    elseif category == "single_seat_bench" then
        if forwardDot and math.max(forwardDot, -forwardDot) < 0.25 then return false, "lectern_focus_single_seat_sideways" end
    end

    return true, nil
end

local function focusKind(profiles, obj)
    local text = objectText(profiles, obj)
    if text == "light_fire" or text:find("^light_fire[%W_]", 1, false) then return nil end
    local kind = objectMatchers.surfaceKindFromText(text)
    if kind then return kind end
    if text:find("hearth", 1, true)
        or text:find("fireplace", 1, true)
        or text:find("pitfire", 1, true)
        or text:find("campfire", 1, true)
        or text:find("fire", 1, true)
        or text:find("logpile", 1, true) then
        return "fire"
    end
    return nil
end

local function seatLooksLikeStool(profiles, obj)
    return objectText(profiles, obj):find("stool", 1, true) ~= nil
end

local function seatLooksLikeBarstool(profiles, obj)
    local text = objectText(profiles, obj)
    return text:find("barstool", 1, true) ~= nil
        or text:find("ab_furn_demidstool", 1, true) ~= nil
        or text:find("de_rm_stool", 1, true) ~= nil
end

local function localTableOrBarBias(kind, dist, forwardDot)
    if kind == "table" or kind == "bar" then
        if dist <= 210 and (not forwardDot or forwardDot > -0.2) then return -120 end
        if dist <= 260 and (not forwardDot or forwardDot > -0.35) then return -70 end
    elseif kind == "fire" and dist > 120 then
        return 95
    end
    return 0
end

function M.seatObjectLooksOverturned(env, obj)
    if not (obj and obj.rotation and obj.position and env and env.util and env.util.vector3) then return false end
    local text = objectText(env.profiles, obj)
    if text:find("overturned", 1, true)
        or text:find("tipped", 1, true)
        or text:find("upside", 1, true)
        or text:find("knocked", 1, true) then
        return true
    end
    local ok, up = pcall(function() return obj.rotation * env.util.vector3(0, 0, 1) end)
    if not (ok and up and tonumber(up.z)) then return false end
    return up.z < 0.94
end

function M.nearestDirection(env, cell, fromPos, seatObj, profile, options)
    options = options or {}
    local bestObj = nil
    local bestKind = nil
    local bestScore = nil
    local maxDist = 340
    local lecternFocusMaxDist = 1350
    local focusCandidates = {}
    local seatIsStool = seatLooksLikeStool(env.profiles, seatObj)
    local seatIsBarstool = seatLooksLikeBarstool(env.profiles, seatObj)
    local lecternRejectedOrientation = 0
    local lecternRejectedDistance = 0

    if options.lectureAudienceTarget == true and options.lectureFocusPosition then
        local focusPos = options.lectureFocusPosition
        local compatible, reason = M.focusCompatible(env.util, "lectern", seatObj, profile, fromPos, focusPos)
        local direction = compatible and directionBetween(env.util, fromPos, focusPos) or nil
        if compatible and direction then
            local dist = (focusPos - fromPos):length()
            local focusCandidates = {
                {
                    object = options.lectureFocusObject,
                    recordId = options.lectureFocusObject and options.lectureFocusObject.recordId or nil,
                    refId = options.lectureFocusObject and options.lectureFocusObject.id or nil,
                    model = options.lectureFocusObject and env.profiles.objectModelPath(options.lectureFocusObject) or nil,
                    name = options.lectureFocusObject and objectName(options.lectureFocusObject) or nil,
                    scale = options.lectureFocusObject and options.lectureFocusObject.scale or nil,
                    kind = "lectern",
                    position = focusPos,
                    distance = dist,
                    score = dist - 120,
                    forwardDot = M.forwardDotToFocus(env.util, seatObj, fromPos, focusPos),
                },
            }
            return direction, options.lectureFocusObject, "lectern", focusCandidates
        end
        if env.verboseLog and traceFocusCandidates(options) then
            local dist = fromPos and (focusPos - fromPos):length() or nil
            verboseLog(env,
                "lectern focus candidate rejected",
                "cell", tostring(cell and (cell.name or cell.id)),
                "lectern", tostring(options.lectureFocusObject and (options.lectureFocusObject.recordId or options.lectureFocusObject.id)),
                "seat", tostring(seatObj and (seatObj.recordId or seatObj.id)),
                "seatModel", tostring(env.profiles.objectModelPath(seatObj)),
                "distance", tostring(dist),
                "angleDot", tostring(M.forwardDotToFocus(env.util, seatObj, fromPos, focusPos)),
                "candidateYaw", tostring(seatObj and seatObj.rotation and seatObj.rotation.getYaw and seatObj.rotation:getYaw() or nil),
                "accepted", "false",
                "reason", tostring(reason or "missing_direction")
            )
        end
        return nil, nil, nil, {}
    end

    local focusObjects = options.focusObjects or cell:getAll()
    for _, obj in ipairs(focusObjects) do
        if obj and obj.position then
            local kind = focusKind(env.profiles, obj)
            if kind == "lectern" then
                if options.lectureAudienceTarget ~= true then kind = nil end
                local stationProfile = kind and env.profiles.stationProfileForObject(obj, env.settings) or nil
                local claim = stationProfile and env.stationAssignments and env.stationAssignments.lecternClaimForObject(obj, env.stationSlotKey(obj, stationProfile)) or nil
                if kind and not claim and options.allowUnclaimedLecternFocus ~= true then kind = nil end
                if kind then
                    local compatible, reason = M.focusCompatible(env.util, kind, seatObj, profile, fromPos, obj.position)
                    if not compatible then
                        lecternRejectedOrientation = lecternRejectedOrientation + 1
                        if env.verboseLog and traceFocusCandidates(options) then
                            verboseLog(env,
                                "lectern focus candidate rejected",
                                "cell", tostring(cell and (cell.name or cell.id)),
                                "lectern", tostring(obj.recordId or obj.id),
                                "seat", tostring(seatObj and (seatObj.recordId or seatObj.id)),
                                "seatModel", tostring(env.profiles.objectModelPath(seatObj)),
                                "distance", tostring((obj.position - fromPos):length()),
                                "angleDot", tostring(M.forwardDotToFocus(env.util, seatObj, fromPos, obj.position)),
                                "candidateYaw", tostring(seatObj and seatObj.rotation and seatObj.rotation.getYaw and seatObj.rotation:getYaw() or nil),
                                "accepted", "false",
                                "reason", tostring(reason or "facing_away")
                            )
                        end
                        kind = nil
                    end
                end
            end
            if kind then
                local dist = (obj.position - fromPos):length()
                local effectiveMaxDist = kind == "lectern" and options.interiorLecternAudience == true and math.huge
                    or (kind == "lectern" and lecternFocusMaxDist or maxDist)
                if dist <= effectiveMaxDist then
                    local score = dist
                    local forwardDot = nil
                    if kind == "lectern" or kind == "table" or kind == "bar" or kind == "fire" or kind == "grinder" then
                        forwardDot = M.forwardDotToFocus(env.util, seatObj, fromPos, obj.position)
                    end
                    if kind == "bar" then
                        if seatIsBarstool then score = score - (dist <= 220 and 145 or 70)
                        elseif seatIsStool then score = score + 35
                        else score = score + 35 end
                    end
                    if kind == "table" then score = score - (seatIsStool and 20 or 35) end
                    if kind == "grinder" then score = score - 35 end
                    if kind == "lectern" then score = score - 120 end
                    if kind == "fire" then score = score + 30 end
                    score = score + localTableOrBarBias(kind, dist, forwardDot)
                    if kind == "table" or kind == "bar" or kind == "fire" or kind == "grinder" then
                        if forwardDot and forwardDot > 0.35 then score = score - 25
                        elseif forwardDot and forwardDot < -0.2 then score = score + 45 end
                    end
                    if seatIsBarstool and kind == "bar" and dist <= 240 then
                        if forwardDot and forwardDot > 0.35 then score = score - 180
                        elseif forwardDot and forwardDot < -0.2 then score = score + 35 end
                    end
                    if kind == "table" or kind == "bar" or kind == "fire" or kind == "lectern" or kind == "grinder" then
                        if kind == "lectern" and env.verboseLog and traceFocusCandidates(options) then
                            verboseLog(env,
                                "lectern focus candidate accepted",
                                "cell", tostring(cell and (cell.name or cell.id)),
                                "lectern", tostring(obj.recordId or obj.id),
                                "seat", tostring(seatObj and (seatObj.recordId or seatObj.id)),
                                "seatModel", tostring(env.profiles.objectModelPath(seatObj)),
                                "distance", tostring(dist),
                                "angleDot", tostring(forwardDot),
                                "candidateYaw", tostring(seatObj and seatObj.rotation and seatObj.rotation.getYaw and seatObj.rotation:getYaw() or nil),
                                "accepted", "true",
                                "reason", "within_radius_and_orientation"
                            )
                        end
                        focusCandidates[#focusCandidates + 1] = {
                            object = obj,
                            recordId = obj.recordId,
                            refId = obj.id,
                            model = env.profiles.objectModelPath(obj),
                            name = objectName(obj),
                            scale = obj.scale,
                            kind = kind,
                            position = obj.position,
                            distance = dist,
                            score = score,
                            forwardDot = forwardDot,
                        }
                    end
                    if not bestScore or score < bestScore then
                        bestObj = obj
                        bestKind = kind
                        bestScore = score
                    end
                elseif kind == "lectern" then
                    lecternRejectedDistance = lecternRejectedDistance + 1
                    if env.verboseLog and traceFocusCandidates(options) then
                        verboseLog(env,
                            "lectern focus candidate rejected",
                            "cell", tostring(cell and (cell.name or cell.id)),
                            "lectern", tostring(obj.recordId or obj.id),
                            "seat", tostring(seatObj and (seatObj.recordId or seatObj.id)),
                            "seatModel", tostring(env.profiles.objectModelPath(seatObj)),
                            "distance", tostring(dist),
                            "angleDot", tostring(M.forwardDotToFocus(env.util, seatObj, fromPos, obj.position)),
                            "candidateYaw", tostring(seatObj and seatObj.rotation and seatObj.rotation.getYaw and seatObj.rotation:getYaw() or nil),
                            "accepted", "false",
                            "reason", "too_far"
                        )
                    end
                end
            end
        end
    end

    if options.lectureAudienceTarget == true and env.verboseLog and not traceFocusCandidates(options) and (lecternRejectedOrientation > 0 or lecternRejectedDistance > 0 or #focusCandidates > 0) then
        verboseLog(env,
            "lectern focus candidate summary",
            "cell", tostring(cell and (cell.name or cell.id)),
            "seat", tostring(seatObj and (seatObj.recordId or seatObj.id)),
            "seatModel", tostring(env.profiles.objectModelPath(seatObj)),
            "accepted", tostring(#focusCandidates),
            "rejectedOrientation", tostring(lecternRejectedOrientation),
            "rejectedDistance", tostring(lecternRejectedDistance)
        )
    end

    if bestObj and bestKind == "fire" then
        local fireDistance = (bestObj.position - fromPos):length()
        local bestLocalSurface = nil
        for _, candidate in ipairs(focusCandidates) do
            if (candidate.kind == "table" or candidate.kind == "bar")
                and (candidate.distance or math.huge) <= 260
                and (candidate.forwardDot == nil or candidate.forwardDot > -0.35)
                and (not bestLocalSurface or (candidate.distance or math.huge) < (bestLocalSurface.distance or math.huge)) then
                bestLocalSurface = candidate
            end
        end
        if bestLocalSurface and ((bestLocalSurface.distance or math.huge) <= 210 or (bestLocalSurface.distance or math.huge) + 90 <= fireDistance) then
            bestObj = bestLocalSurface.object
            bestKind = bestLocalSurface.kind
            bestScore = bestLocalSurface.score
        end
    end

    if bestObj then
        table.sort(focusCandidates, function(a, b)
            if seatIsStool then
                local scoreA = a.score or math.huge
                local scoreB = b.score or math.huge
                if scoreA ~= scoreB then return scoreA < scoreB end
            end
            return (a.distance or math.huge) < (b.distance or math.huge)
        end)
        while #focusCandidates > 8 do table.remove(focusCandidates) end
        return directionBetween(env.util, fromPos, bestObj.position), bestObj, bestKind, focusCandidates
    end
    return nil, nil, nil, focusCandidates
end

function M.candidateSeatPosition(env, obj, profile, slot, slotIndex)
    if not (obj and obj.position) then return nil end
    local slots = profile and profile.slots or nil
    local slotCount = slots and #slots or 0
    local category = tostring(profile and (profile.seatCategory or profile.type or profile.seatType) or ""):lower()
    if slotCount <= 1 or category:find("bench", 1, true) == nil then return obj.position end

    local name = tostring(slot and slot.name or ""):lower()
    local index = tonumber(slotIndex or 1) or 1
    if name == "seat_a" then index = 1
    elseif name == "seat_b" then index = 2
    elseif name == "seat_c" then index = 3
    elseif name == "seat_d" then index = 4 end

    local spacing = slotCount >= 3 and 64 or 82
    local centeredIndex = index - ((slotCount + 1) / 2)
    return env.objectLocalOffset(obj, { x = centeredIndex * spacing, y = 0, z = 0 })
end

return M
