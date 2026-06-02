-- Formatting helpers for developer calibration export rows.
-- Split from interactionSeeker.lua to keep the NPC local script below Lua's
-- active-local compile limit.

local M = {}

function M.cleanNumber(value)
    value = tonumber(value) or 0
    if math.abs(value) < 0.0001 then value = 0 end
    local rounded = math.floor(value + (value >= 0 and 0.5 or -0.5))
    if math.abs(value - rounded) < 0.0001 then return tostring(rounded) end
    local text = string.format("%.3f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    return text
end

function M.profileVectorString(offset)
    if not offset then return "0,0,0" end
    return M.cleanNumber(offset.x) .. "," .. M.cleanNumber(offset.y) .. "," .. M.cleanNumber(offset.z)
end

function M.slotVectorString(offset)
    if not offset then return "" end
    return M.profileVectorString(offset)
end

function M.slotsProfileString(profile, activeSlotName, replacementRootOffset)
    local slots = profile and profile.slots
    if not slots or #slots == 0 then return "" end
    local out = {}
    for _, slot in ipairs(slots) do
        local name = tostring(slot.name or "slot")
        local rootOffset = slot.sleepRootLocalOffset
        if activeSlotName and name == activeSlotName and replacementRootOffset then
            rootOffset = replacementRootOffset
        end
        if slot.sleepOffset or slot.approachOffset or rootOffset or slot.sleepLateralOffset ~= nil then
            local text = name .. "|" .. M.slotVectorString(slot.sleepOffset) .. "|" .. M.slotVectorString(slot.approachOffset) .. "|" .. M.slotVectorString(rootOffset)
            if slot.sleepLateralOffset ~= nil then
                text = text .. "|" .. M.cleanNumber(slot.sleepLateralOffset)
            end
            out[#out + 1] = text
        else
            out[#out + 1] = name
        end
    end
    return table.concat(out, ";")
end

function M.bedProfileCopyRow(data)
    data = data or {}
    local profile = data.profile or {}
    local row = profile.sourceRow or {}
    local rootOffset = data.mergedRootOffset or profile.sleepRootLocalOffset or { x = 0, y = 0, z = 0 }
    local rootZ = row.sleeprootzoffset or profile.sleepRootZOffset or -180
    local yaw = data.poseYawOffset or profile.sleepPoseYawOffset or math.rad(-90)
    local yawDeg = M.cleanNumber(math.deg(yaw))
    local slots = row.slots or ""
    if profile.slots and #profile.slots > 0 then
        slots = M.slotsProfileString(profile, data.slotName, rootOffset)
        -- For slotted beds, the row-level root offset remains the shared base.
        -- The active slot receives the printed change in the Slots column.
        rootOffset = profile.sleepRootLocalOffset or { x = 0, y = 0, z = 0 }
    end
    local profiles = data.profiles
    local object = data.object
    return table.concat({
        row.recordid or (object and object.recordId) or "<bed>",
        row.model or (object and profiles and profiles.objectModelPath(object)) or "",
        row.profileid or profile.profileId or "<profile>",
        row.bedtype or profile.bedType or profile.type or "single",
        M.profileVectorString(rootOffset),
        M.cleanNumber(rootZ),
        yawDeg,
        row.sleepinwardoffsetfromapproach or profile.sleepInwardOffsetFromApproach or 0,
        row.sleepsurfacegrid or "",
        row.sleepsurfacecentermode or profile.sleepSurfaceCenterMode or "sample_extents",
        row.sleepsurfaceminheight or profile.sleepSurfaceMinHeight or "",
        row.sleepsurfacemaxheight or profile.sleepSurfaceMaxHeight or "",
        slots or "",
    }, "\t")
end

function M.bedOrientationProfileRow(data)
    data = data or {}
    local profile = data.profile or {}
    local object = data.object
    local profiles = data.profiles
    local buckets = profiles and profiles.objectYawBuckets and profiles.objectYawBuckets(object) or {}
    local rootOffset = data.mergedRootOffset or profile.sleepRootLocalOffset or { x = 0, y = 0, z = 0 }
    local yaw = data.poseYawOffset or profile.sleepPoseYawOffset or math.rad(-90)
    local cols = {
        object and object.recordId or "<bed>",
        object and profiles and profiles.objectModelPath(object) or "",
        profile.profileId or (object and object.recordId) or "<profile>",
        data.slotName or "sleep_main",
        M.cleanNumber(buckets.yawBucket90 or 0),
        M.profileVectorString(rootOffset),
        M.cleanNumber(math.deg(yaw)),
        "",
        "",
        "",
        "",
        "",
        "calibrated orientation variant; objectYawDeg=" .. M.cleanNumber(buckets.objectYawDeg or 0) .. "; yawBucket45=" .. M.cleanNumber(buckets.yawBucket45 or 0),
    }
    for i, value in ipairs(cols) do cols[i] = M.exportSafe(value) end
    return table.concat(cols, "\t")
end

function M.animationNormalizationRow(data)
    data = data or {}
    local object = data.object
    local profiles = data.profiles
    local baseOffset = data.baseOffset or {}
    local delta = data.delta or {}
    local cols = {
        data.interactionType or "sleeping",
        data.animation or "",
        object and object.recordId or "",
        object and profiles and profiles.objectModelPath(object) or "",
        data.profileId or "",
        data.slotName or "",
        data.yawBucket90 or "",
        M.cleanNumber((tonumber(baseOffset.x) or 0) + (tonumber(delta.x) or 0)),
        M.cleanNumber((tonumber(baseOffset.y) or 0) + (tonumber(delta.y) or 0)),
        M.cleanNumber((tonumber(baseOffset.z) or 0) + (tonumber(delta.z) or 0)),
        M.cleanNumber((tonumber(baseOffset.yaw) or 0) + (tonumber(delta.yaw) or 0)),
        data.notes or "Scoped animation normalization; use when the same furniture profile is correct for one animation but offset for this animation.",
    }
    for i, value in ipairs(cols) do cols[i] = M.exportSafe(value) end
    return table.concat(cols, "\t")
end

function M.sleepProfileSource(profile)
    if profile and profile.orientationVariantSource == "explicit_profile_orientation_variant" then return "explicit_profile_orientation_variant" end
    if profile and profile.externalProfile == true then return "explicit_profile" end
    if profile and profile.profileBedTypeFallback then return "bed_type_average" end
    return "fallback"
end

function M.exportSafe(value)
    return tostring(value == nil and "" or value):gsub("[\r\n\t]", " ")
end

function M.shortNumber(value)
    local n = tonumber(value) or 0
    if math.abs(n - math.floor(n + 0.5)) < 0.001 then
        return tostring(math.floor(n + 0.5))
    end
    local s = string.format("%.3f", n)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    if s == "-0" then s = "0" end
    return s
end

function M.offsetLabel(offset)
    if not offset then return "nil" end
    return tostring(offset.x or 0) .. "," .. tostring(offset.y or 0) .. "," .. tostring(offset.z or 0) .. (offset.yaw ~= nil and (",yaw=" .. tostring(offset.yaw)) or "")
end

function M.traceLocalSittingAcceptance(core, actor, currentObject, currentSlotName, debugLog, stage, data)
    data = data or {}
    local payload = {
        npc = actor,
        npcId = actor and actor.id or nil,
        recordId = actor and actor.recordId or nil,
        objectId = data.objectId or (data.object and data.object.recordId) or (currentObject and currentObject.recordId) or nil,
        slotName = data.slotName or currentSlotName,
        stage = stage,
        reason = data.reason,
    }
    pcall(function() core.sendGlobalEvent("SitDownPleaseLocalSittingAcceptanceTrace", payload) end)
    if debugLog then
        debugLog(
            stage == "blocked" and "sitting local acceptance blocked reason=" .. tostring(data.reason or "unknown") or ("sitting local acceptance " .. tostring(stage)),
            "object", tostring(payload.objectId),
            "slot", tostring(payload.slotName)
        )
    end
end

function M.sittingSolverSnapshot(object, basePos, finalPos, actor, finalYawOffset, facingDirection, facingReason, data, surfaceMode, surfaceSamples)
    local objectYaw = 0
    if object and object.rotation and object.rotation.getYaw then
        local okYaw, yaw = pcall(function() return object.rotation:getYaw() end)
        if okYaw and yaw then objectYaw = yaw end
    end
    local c = math.cos(-objectYaw)
    local s = math.sin(-objectYaw)
    local function toLocal(pos)
        if not (object and object.position and pos) then return nil end
        local delta = pos - object.position
        return {
            x = (delta.x or 0) * c - (delta.y or 0) * s,
            y = (delta.x or 0) * s + (delta.y or 0) * c,
            z = delta.z or 0,
        }
    end
    local baseLocal = toLocal(basePos)
    local finalLocal = toLocal(finalPos)
    local deltaLocal = nil
    if baseLocal and finalLocal then
        deltaLocal = {
            x = (finalLocal.x or 0) - (baseLocal.x or 0),
            y = (finalLocal.y or 0) - (baseLocal.y or 0),
            z = (finalLocal.z or 0) - (baseLocal.z or 0),
        }
    end
    return {
        baseLocal = baseLocal,
        finalLocal = finalLocal,
        deltaLocal = deltaLocal,
        objectYawDeg = math.deg(objectYaw),
        objectScale = object and object.scale or nil,
        actorScale = actor and actor.scale or nil,
        finalYawOffsetDeg = math.deg(finalYawOffset or 0),
        facingDirection = facingDirection,
        facingReason = facingReason,
        facingKind = data and data.facingKind,
        facingObjectId = data and data.facingObjectId,
        facingObjectModel = data and data.facingObjectModel,
        surfaceMode = surfaceMode,
        surfaceSamples = surfaceSamples,
    }
end

function M.logSittingSolverBasis(debugLog, label, object, profile, snap)
    if not debugLog then return end
    snap = snap or {}
    debugLog(
        label or "sitting solver basis",
        "object", tostring(object and object.recordId),
        "profile", tostring(profile and profile.profileId),
        "baseLocal", M.offsetLabel(snap.baseLocal),
        "finalLocal", M.offsetLabel(snap.finalLocal),
        "deltaLocal", M.offsetLabel(snap.deltaLocal),
        "objectYawDeg", tostring(M.shortNumber(snap.objectYawDeg or 0)),
        "objectScale", tostring(snap.objectScale),
        "actorScale", tostring(snap.actorScale),
        "facingReason", tostring(snap.facingReason),
        "facingKind", tostring(snap.facingKind),
        "facingDir", tostring(snap.facingDirection),
        "surface", tostring(snap.surfaceMode),
        "surfaceSamples", tostring(snap.surfaceSamples)
    )
end

function M.logDemidChairBasisComparison(debugLog, actor, object, snap, clearance)
    if not (debugLog and object and tostring(object.recordId or ""):lower() == "ab_furn_demidchair") then return end
    clearance = clearance or {}
    debugLog(
        "ab_furn_demidchair basis comparison",
        "actor", tostring(actor and (actor.recordId or actor.id)),
        "baseLocal", M.offsetLabel(snap and snap.baseLocal),
        "finalLocal", M.offsetLabel(snap and snap.finalLocal),
        "deltaLocal", M.offsetLabel(snap and snap.deltaLocal),
        "objectYawDeg", tostring(M.shortNumber(snap and snap.objectYawDeg or 0)),
        "objectScale", tostring(snap and snap.objectScale),
        "actorScale", tostring(snap and snap.actorScale),
        "facingReason", tostring(snap and snap.facingReason),
        "blocker", tostring(clearance.blockerRecord), tostring(clearance.blockerModel),
        "blocker distance", tostring(clearance.blockerDistance or clearance.tableDistance or clearance.bodyDistance or clearance.frontDistance),
        "vertical", tostring(clearance.vertical),
        "tabletopOverlap", tostring(clearance.tabletopOverlap == true),
        "rejection/acceptance", tostring(clearance.result or "accepted")
    )
end

function M.offsetDiffers(a, b, epsilon)
    epsilon = tonumber(epsilon or 0.5) or 0.5
    a = a or {}
    b = b or {}
    return math.abs((tonumber(a.x) or 0) - (tonumber(b.x) or 0)) > epsilon
        or math.abs((tonumber(a.y) or 0) - (tonumber(b.y) or 0)) > epsilon
        or math.abs((tonumber(a.z) or 0) - (tonumber(b.z) or 0)) > epsilon
        or math.abs((tonumber(a.yaw) or 0) - (tonumber(b.yaw) or 0)) > epsilon
end

function M.sleepPromotionHint(profile, rowDiffers)
    if profile and profile.externalProfile == true then
        if rowDiffers then return "orientation_variant" end
        return "explicit_profile"
    end
    return "explicit_profile"
end

function M.sittingPromotionClassification(profile, obj, profileOffset, changes, data)
    local rowDiffers = M.offsetDiffers(profileOffset, {
        x = (tonumber(profileOffset and profileOffset.x) or 0) + (tonumber(changes and changes.x) or 0),
        y = (tonumber(profileOffset and profileOffset.y) or 0) + (tonumber(changes and changes.y) or 0),
        z = (tonumber(profileOffset and profileOffset.z) or 0) + (tonumber(changes and changes.z) or 0),
        yaw = (tonumber(profileOffset and profileOffset.yaw) or 0) + (tonumber(changes and changes.yaw) or 0),
    })
    local facingKind = tostring(data and data.facingKind or "")
    local tableContext = facingKind == "table" or facingKind == "bar" or data and data.facingObjectPosition ~= nil
    local profileId = tostring(profile and profile.profileId or "")
    local objectId = tostring(obj and obj.recordId or "")
    local external = profile and profile.externalProfile == true
    local manualOverride = data and data.manualOverride == true

    if rowDiffers and manualOverride then
        return {
            rowDiffers = true,
            hint = "manual_override_do_not_promote",
            label = "chair calibration manual override context",
            conflict = external or profileId == objectId or profileId ~= "",
            reason = "manual_override_or_blocker_bypass",
        }
    end

    if rowDiffers and tableContext then
        return {
            rowDiffers = true,
            hint = "suspicious_context_do_not_promote",
            label = "chair calibration likely placement-specific",
            conflict = external,
            reason = "solver_basis_or_context_differs",
        }
    end
    if rowDiffers and external then
        return {
            rowDiffers = true,
            hint = "review_before_promote",
            label = "chair calibration differs from explicit profile",
            conflict = profileId == objectId or profileId ~= "",
            reason = "differs_from_loaded_profile_visual_verification_required",
        }
    end
    return {
        rowDiffers = rowDiffers,
        hint = rowDiffers and "explicit_profile" or "explicit_profile",
        label = "chair profile universal candidate",
        conflict = false,
        reason = rowDiffers and "unprofiled_or_changed_profile" or "matches_loaded_profile",
    }
end

function M.rawSource(profile, key, fallback)
    local row = profile and profile.sourceRow or nil
    local value = row and row[string.lower(tostring(key or ""))] or nil
    if value ~= nil and tostring(value) ~= "" then return value end
    return fallback
end

function M.sittingSlotsText(profile)
    local rowValue = M.rawSource(profile, "slots", nil)
    if rowValue then return rowValue end
    local parts = {}
    for i, slot in ipairs(profile and profile.slots or {}) do
        parts[#parts + 1] = tostring(slot.name or ("seat_" .. tostring(i)))
    end
    if #parts == 0 then return "default" end
    return table.concat(parts, ";")
end

function M.sittingApproachOffsetsText(profile)
    local rowValue = M.rawSource(profile, "approachoffsets", nil)
    if rowValue then return rowValue end
    local parts = {}
    for _, offset in ipairs(profile and profile.approachOffsets or {}) do
        local item = tostring(offset.name or "front") .. ":" .. M.shortNumber(offset.x) .. ":" .. M.shortNumber(offset.y) .. ":" .. M.shortNumber(offset.z)
        if offset.anchor then item = item .. ":" .. tostring(offset.anchor) end
        parts[#parts + 1] = item
    end
    return table.concat(parts, ";")
end

function M.sittingFlagsText(profile)
    local rowValue = M.rawSource(profile, "flags", nil)
    if rowValue then return rowValue end
    if profile and profile.unsafeIfBlocked then return "unsafeIfBlocked" end
    return ""
end

function M.sittingProfileExportRow(profile, obj, profiles, profileOffset, changes)
    profileOffset = profileOffset or { x = 0, y = 0, z = 0, yaw = 0 }
    changes = changes or { x = 0, y = 0, z = 0, yaw = 0 }
    local finalOffset = {
        x = (tonumber(profileOffset.x) or 0) + (tonumber(changes.x) or 0),
        y = (tonumber(profileOffset.y) or 0) + (tonumber(changes.y) or 0),
        z = (tonumber(profileOffset.z) or 0) + (tonumber(changes.z) or 0),
        yaw = (tonumber(profileOffset.yaw) or 0) + (tonumber(changes.yaw) or 0),
    }
    local cols = {
        M.rawSource(profile, "recordid", obj and obj.recordId or "<seat>"),
        M.rawSource(profile, "profileid", profile and profile.profileId or (obj and obj.recordId) or "<profile>"),
        M.rawSource(profile, "seattype", profile and profile.type or "stool"),
        M.rawSource(profile, "model", obj and profiles and profiles.objectModelPath(obj) or ""),
        M.shortNumber(finalOffset.x),
        M.shortNumber(finalOffset.y),
        M.shortNumber(finalOffset.z),
        M.shortNumber(finalOffset.yaw),
        M.rawSource(profile, "rotationmode", profile and profile.rotationMode or "faceNearestTableOrCounter"),
        M.rawSource(profile, "finalforwardoffset", profile and profile.finalForwardOffset or -7),
        M.rawSource(profile, "finalzoffset", profile and profile.finalZOffset or -36),
        M.sittingSlotsText(profile),
        M.sittingApproachOffsetsText(profile),
        M.sittingFlagsText(profile),
        M.rawSource(profile, "notes", "calibrated from developer menu"),
    }
    for i, value in ipairs(cols) do cols[i] = M.exportSafe(value) end
    return table.concat(cols, "\t")
end

function M.chairOrientationProfileRow(profile, obj, profiles, profileOffset, changes, slotName)
    profileOffset = profileOffset or { x = 0, y = 0, z = 0, yaw = 0 }
    changes = changes or { x = 0, y = 0, z = 0, yaw = 0 }
    local finalOffset = {
        x = (tonumber(profileOffset.x) or 0) + (tonumber(changes.x) or 0),
        y = (tonumber(profileOffset.y) or 0) + (tonumber(changes.y) or 0),
        z = (tonumber(profileOffset.z) or 0) + (tonumber(changes.z) or 0),
        yaw = (tonumber(profileOffset.yaw) or 0) + (tonumber(changes.yaw) or 0),
    }
    local buckets = profiles and profiles.objectYawBuckets and profiles.objectYawBuckets(obj) or {}
    local cols = {
        obj and obj.recordId or "<seat>",
        obj and profiles and profiles.objectModelPath(obj) or "",
        profile and profile.profileId or (obj and obj.recordId) or "<profile>",
        slotName or "default",
        M.shortNumber(buckets.yawBucket90 or 0),
        M.shortNumber(finalOffset.x),
        M.shortNumber(finalOffset.y),
        M.shortNumber(finalOffset.z),
        M.shortNumber(finalOffset.yaw),
        "calibrated chair orientation variant; objectYawDeg=" .. M.shortNumber(buckets.objectYawDeg or 0) .. "; yawBucket45=" .. M.shortNumber(buckets.yawBucket45 or 0),
    }
    for i, value in ipairs(cols) do cols[i] = M.exportSafe(value) end
    return table.concat(cols, "\t")
end

return M
