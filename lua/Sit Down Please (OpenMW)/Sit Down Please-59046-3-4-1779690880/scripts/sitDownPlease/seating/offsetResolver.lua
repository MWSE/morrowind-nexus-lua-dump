-- seating/offsetResolver.lua
-- Keeps seating profile offsets separate from animation-pose normalization.
-- Profiles and calibration describe furniture placement; animation
-- normalization makes different sitting KF groups share that placement.

local M = {}

local okVfsPackage, vfsPackage = pcall(require, 'openmw.vfs')
if not okVfsPackage then vfsPackage = nil end

local NORMALIZATION_FILE = "sdp_furnitureProfiles/animationNormalizationOffsets.txt"

local FALLBACK_ANIMATION_NORMALIZATION_OFFSETS = {
    sitting = {
        -- `sdpvasitting6` faces opposite the actor yaw in OpenMW. Keep both the
        -- visual yaw fix and matching depth correction in animation
        -- normalization, so furniture profiles remain calibrated to the base
        -- SitIdle1 seating anchor.
        sdpvasitting6 = {
            { x = 0, y = 28.2, z = -10.7, yaw = 182.53 },
        },
    },
    sleeping = {},
}

local loadedAnimationNormalizationOffsets = nil

local function normalizeOffsetKey(value)
    value = tostring(value or "")
    if value == "" then return "" end
    return string.lower(value)
end

local function trim(value)
    if value == nil then return "" end
    return tostring(value):match("^%s*(.-)%s*$") or ""
end

local function splitTabs(line)
    local out = {}
    local index = 1
    for part in (tostring(line or "") .. "\t"):gmatch("([^\t]*)\t") do
        out[index] = trim(part)
        index = index + 1
    end
    return out
end

local function parseNumber(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    return tonumber(raw)
end

local function cloneOffsets(source)
    local out = {}
    for interactionType, offsets in pairs(source or {}) do
        out[interactionType] = {}
        for key, rows in pairs(offsets or {}) do
            out[interactionType][key] = {}
            for _, offset in ipairs(rows or {}) do
                out[interactionType][key][#out[interactionType][key] + 1] = M.copy(offset)
                for _, field in ipairs({ "recordId", "model", "profileId", "slotName", "yawBucket90", "yawMinDeg", "yawMaxDeg" }) do
                    out[interactionType][key][#out[interactionType][key]][field] = offset[field]
                end
            end
        end
    end
    return out
end

local function currentVfs()
    if vfsPackage then return vfsPackage end
    local ok, vfstable = pcall(function() return vfs end)
    if ok and vfstable then return vfstable end
    return rawget(_G, "vfs")
end

local function parseNormalizationRows(content)
    local rows = {}
    local headers = nil
    for rawLine in tostring(content or ""):gmatch("[^\r\n]+") do
        local line = trim(rawLine)
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local parts = splitTabs(line)
            if not headers then
                headers = {}
                for i, header in ipairs(parts) do headers[i] = normalizeOffsetKey(header) end
            else
                local row = {}
                for i, value in ipairs(parts) do
                    local header = headers[i]
                    if header and header ~= "" then row[header] = value end
                end
                rows[#rows + 1] = row
            end
        end
    end
    return rows
end

local function normalizeInteractionType(value)
    local key = normalizeOffsetKey(value)
    if key == "" then return "sitting" end
    if key == "sit" or key == "chair" or key == "seat" then return "sitting" end
    if key == "sleep" or key == "bed" then return "sleeping" end
    return key
end

local function appendNormalizationOffset(offsets, interactionType, animation, offset)
    offsets[interactionType] = offsets[interactionType] or {}
    offsets[interactionType][animation] = offsets[interactionType][animation] or {}
    offsets[interactionType][animation][#offsets[interactionType][animation] + 1] = offset
end

local function loadAnimationNormalizationOffsets()
    local offsets = cloneOffsets(FALLBACK_ANIMATION_NORMALIZATION_OFFSETS)
    local vfstable = currentVfs()
    if not (vfstable and vfstable.open) then return offsets end

    local file = vfstable.open(NORMALIZATION_FILE)
    if not file then return offsets end

    local content = file:read("*all")
    file:close()
    for _, row in ipairs(parseNormalizationRows(content)) do
        local interactionType = normalizeInteractionType(row.interactiontype or row.kind or row.type)
        local animation = normalizeOffsetKey(row.animation or row.animationid or row.group)
        if animation ~= "" then
            appendNormalizationOffset(offsets, interactionType, animation, {
                x = parseNumber(row.widthoffset or row.xoffset or row.offsetx) or 0,
                y = parseNumber(row.depthoffset or row.yoffset or row.offsety) or 0,
                z = parseNumber(row.heightoffset or row.zoffset or row.offsetz) or 0,
                yaw = parseNumber(row.yawoffset or row.yawdeg or row.yawdegrees) or 0,
                recordId = trim(row.recordid or row.objectid or ""),
                model = trim(row.model or row.mesh or ""),
                profileId = trim(row.profileid or row.profile or ""),
                slotName = trim(row.slotname or row.slot or ""),
                yawBucket90 = parseNumber(row.yawbucket90 or row.yawbucket or row.objectyawbucket90),
                yawMinDeg = parseNumber(row.yawmindeg or row.yawmin or row.objectyawmindegmin),
                yawMaxDeg = parseNumber(row.yawmaxdeg or row.yawmax or row.objectyawmaxdeg),
            })
        end
    end
    return offsets
end

local function animationNormalizationOffsets()
    if not loadedAnimationNormalizationOffsets then
        loadedAnimationNormalizationOffsets = loadAnimationNormalizationOffsets()
    end
    return loadedAnimationNormalizationOffsets
end

function M.zero()
    return { x = 0, y = 0, z = 0, yaw = 0 }
end

function M.copy(offset)
    offset = offset or {}
    return {
        x = tonumber(offset.x) or 0,
        y = tonumber(offset.y) or 0,
        z = tonumber(offset.z) or 0,
        yaw = tonumber(offset.yaw) or 0,
    }
end

function M.add(total, offset)
    if not offset then return total end
    total.x = total.x + (tonumber(offset.x) or 0)
    total.y = total.y + (tonumber(offset.y) or 0)
    total.z = total.z + (tonumber(offset.z) or 0)
    total.yaw = total.yaw + (tonumber(offset.yaw) or 0)
    return total
end

local function contextValue(context, key)
    if not context then return "" end
    if context[key] ~= nil then return context[key] end
    local obj = context.object
    if key == "recordId" and obj then return obj.recordId or obj.id end
    if key == "model" and obj then
        if context.objectModel then return context.objectModel end
        if obj.type and obj.type.record and obj.type.record(obj) then
            local record = obj.type.record(obj)
            return record and record.model
        end
    end
    return ""
end

local function matchModel(row, context)
    local expected = normalizeOffsetKey(row.model)
    if expected == "" then return true, 0 end
    local activeModel = normalizeOffsetKey(contextValue(context, "model"))
    if activeModel == expected then return true, 8 end
    local profileModel = normalizeOffsetKey(contextValue(context, "profileModel"))
    if profileModel == expected then return true, 7 end
    return false, 0
end

local function normalizedDegrees(deg)
    return ((tonumber(deg) or 0) % 360 + 360) % 360
end

local function yawInRange(deg, minDeg, maxDeg)
    if minDeg == nil and maxDeg == nil then return true end
    deg = normalizedDegrees(deg)
    if minDeg == nil then return deg <= normalizedDegrees(maxDeg) end
    if maxDeg == nil then return deg >= normalizedDegrees(minDeg) end
    minDeg = normalizedDegrees(minDeg)
    maxDeg = normalizedDegrees(maxDeg)
    if minDeg <= maxDeg then return deg >= minDeg and deg <= maxDeg end
    return deg >= minDeg or deg <= maxDeg
end

local function matchYawRange(row, context)
    if not row or (row.yawMinDeg == nil and row.yawMaxDeg == nil) then return true, 0 end
    local actual = tonumber(contextValue(context, "objectYawDeg"))
    if actual == nil then return false, 0 end
    if not yawInRange(actual, row.yawMinDeg, row.yawMaxDeg) then return false, 0 end
    return true, 3
end

local function filterScore(row, context)
    local score = 0
    local function matchText(rowKey, contextKey, weight)
        local expected = normalizeOffsetKey(row[rowKey])
        if expected == "" then return true end
        local actual = normalizeOffsetKey(contextValue(context, contextKey))
        if actual ~= expected then return false end
        score = score + weight
        return true
    end

    if not matchText("recordId", "recordId", 16) then return nil end
    local modelMatched, modelScore = matchModel(row, context)
    if not modelMatched then return nil end
    score = score + modelScore
    if not matchText("profileId", "profileId", 4) then return nil end
    if not matchText("slotName", "slotName", 2) then return nil end

    if row.yawBucket90 ~= nil then
        local expected = tonumber(row.yawBucket90)
        local actual = tonumber(contextValue(context, "yawBucket90"))
        if not (expected and actual and expected == actual) then return nil end
        score = score + 1
    end
    local yawRangeMatched, yawRangeScore = matchYawRange(row, context)
    if not yawRangeMatched then return nil end
    score = score + yawRangeScore

    return score
end

local function yawDistance90(a, b)
    a = tonumber(a)
    b = tonumber(b)
    if not (a and b) then return nil end
    local diff = math.abs((((a - b) % 360) + 360) % 360)
    if diff > 180 then diff = 360 - diff end
    return diff
end

local function verticalGapFallbackScore(row, context)
    local expected = tonumber(row and row.yawBucket90)
    local actual = tonumber(contextValue(context, "yawBucket90"))
    if not (expected and actual) then return nil end
    if yawDistance90(expected, actual) ~= 180 then return nil end
    local yawRangeMatched, yawRangeScore = matchYawRange(row, context)
    if not yawRangeMatched then return nil end

    local z = tonumber(row.z) or 0
    local yaw = tonumber(row.yaw) or 0
    if math.abs(z) < 30 or math.abs(yaw) > 0.001 then return nil end

    local score = 0
    local function matchText(rowKey, contextKey, weight)
        local expectedText = normalizeOffsetKey(row[rowKey])
        if expectedText == "" then return true end
        local actualText = normalizeOffsetKey(contextValue(context, contextKey))
        if actualText ~= expectedText then return false end
        score = score + weight
        return true
    end

    if not matchText("recordId", "recordId", 16) then return nil end
    local modelMatched, modelScore = matchModel(row, context)
    if not modelMatched then return nil end
    score = score + modelScore
    if not matchText("profileId", "profileId", 4) then return nil end
    if not matchText("slotName", "slotName", 2) then return nil end

    return score + yawRangeScore + 0.25
end

local function verticalOnly(offset)
    if not offset then return nil end
    return {
        x = 0,
        y = 0,
        z = tonumber(offset.z) or 0,
        yaw = 0,
    }
end

function M.normalizationFor(interactionType, animation, context)
    local typeKey = normalizeInteractionType(interactionType)
    local key = normalizeOffsetKey(animation)
    if key == "" then return M.zero() end
    local byType = animationNormalizationOffsets()[typeKey] or {}
    local rows = byType[key] or {}
    local best = nil
    local bestScore = nil
    for _, row in ipairs(rows) do
        local score = filterScore(row, context)
        if score and (bestScore == nil or score >= bestScore) then
            best = row
            bestScore = score
        end
    end
    if best then return M.copy(best) end

    local fallback = nil
    local fallbackScore = nil
    for _, row in ipairs(rows) do
        local score = verticalGapFallbackScore(row, context)
        if score and (fallbackScore == nil or score >= fallbackScore) then
            fallback = row
            fallbackScore = score
        end
    end
    return verticalOnly(fallback) or M.zero()
end

function M.animationNormalizationFor(animation)
    return M.normalizationFor("sitting", animation)
end

function M.profileOffsetFor(profile, activity, animation, slotKey)
    local total = M.zero()
    if not profile then return total end

    local activityOffsets = profile.sittingActivityOffsets or {}
    local activityAnimationOffsets = profile.sittingActivityAnimationOffsets or {}
    local activityKey = normalizeOffsetKey(activity)
    local animationKey = normalizeOffsetKey(animation)
    if activityKey == "" then activityKey = "standard" end
    if activityKey == "base" or activityKey == "default" or activityKey == "normal" then activityKey = "standard" end

    -- Activity-specific rows are overlays on top of standard. If no activity row
    -- exists, contextual animations inherit the standard/base sitting alignment.
    M.add(total, activityOffsets.standard)
    if profile.sittingSlotOrientationOffsets then
        local normalizedSlotKey = normalizeOffsetKey(slotKey or "default")
        M.add(total, profile.sittingSlotOrientationOffsets[normalizedSlotKey] or profile.sittingSlotOrientationOffsets.default)
    end
    if activityKey ~= "standard" then
        local specific = nil
        if animationKey ~= "" then specific = activityAnimationOffsets[activityKey .. "|" .. animationKey] end
        if specific then
            M.add(total, specific)
        else
            M.add(total, activityOffsets[activityKey])
        end
    elseif animationKey ~= "" then
        M.add(total, activityAnimationOffsets[activityKey .. "|" .. animationKey])
    end
    return total
end

function M.mergedOffset(profileOffset, animationOffset, calibrationOffset)
    local total = M.zero()
    M.add(total, profileOffset)
    M.add(total, animationOffset)
    M.add(total, calibrationOffset)
    return total
end

return M
