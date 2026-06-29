-- profiles/fileLoader.lua
---@omw-context all
--
-- Small Sun's-Dusk-style TSV loader for Sit Down Please object profiles.
-- Profiles stay editable in tab-separated .txt files under furnitureProfiles/.
-- SDP-owned release files live under furnitureProfiles/sdp/. Third-party
-- profile packs may live elsewhere under furnitureProfiles/, but the "sdp"
-- folder name is reserved for SDP's bundled/system namespace.

local module = {}
module.lastLoadSummary = nil

local profileScope = require('scripts/sitDownPlease/profiles/scope')

local okVfsPackage, loadedVfsPackage = pcall(require, 'openmw.vfs')
---@type any
local vfsPackage = okVfsPackage and loadedVfsPackage or nil

local SHARED_PROFILE_ROOT = "furnitureProfiles/"
local PROFILE_ROOT = SHARED_PROFILE_ROOT .. "sdp/"
local GLOBAL_PROFILE_ROOT = PROFILE_ROOT .. "global/"

local GLOBAL_PROFILE_FILES = {
    ["bedprofiles.txt"] = "bedProfiles.txt",
    ["chairprofiles.txt"] = "chairProfiles.txt",
    ["stationprofiles.txt"] = "stationProfiles.txt",
    ["bedprofilevariants.txt"] = "bedProfileVariants.txt",
    ["bedobjectoverrides.txt"] = "bedObjectOverrides.txt",
    ["stationprofilevariants.txt"] = "stationProfileVariants.txt",
    ["stationobjectoverrides.txt"] = "stationObjectOverrides.txt",
    ["chairobjectoverrides.txt"] = "chairObjectOverrides.txt",
    ["chairprofilevariants.txt"] = "chairProfileVariants.txt",
    ["animationnormalizationoffsets.txt"] = "animationNormalizationOffsets.txt",
}

local function trim(value)
    if value == nil then return "" end
    return tostring(value):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    local s = trim(value)
    if s == "" then return "" end
    return string.lower(s)
end

local function canonicalProfilePath(path)
    local raw = trim(path):gsub("\\", "/")
    local lowered = string.lower(raw)
    local suffix = lowered:match("^furnitureprofiles/sdp/(.+)$")
    if not suffix then return raw end
    if suffix:match("^global/") or suffix:match("^places/") or suffix:match("^shared/") then
        return raw
    end
    local globalFile = GLOBAL_PROFILE_FILES[suffix]
    if globalFile then return GLOBAL_PROFILE_ROOT .. globalFile end
    return raw
end

local function normalizedPath(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function isTextProfilePath(path)
    local filename = normalizedPath(path)
    local name = lower(filename)
    return filename:match("%.txt$") ~= nil
        and not filename:match("/%._")
        and not name:find("animationnormalizationoffsets", 1, true)
end

local function split(raw, sep)
    local out = {}
    raw = tostring(raw or "")
    sep = sep or ";"
    if raw == "" then return out end
    local pattern = "([^" .. sep .. "]+)"
    for part in raw:gmatch(pattern) do
        local value = trim(part)
        if value ~= "" then out[#out + 1] = value end
    end
    return out
end

local function splitPreserveEmpty(raw, sep)
    local out = {}
    raw = tostring(raw or "")
    sep = sep or "|"
    local pattern = "([^" .. sep .. "]*)"
    local index = 1
    for part in (raw .. sep):gmatch(pattern .. sep) do
        out[index] = trim(part)
        index = index + 1
    end
    return out
end

local function parseBool(raw)
    raw = lower(raw)
    if raw == "true" or raw == "yes" or raw == "1" or raw == "on" then return true end
    if raw == "false" or raw == "no" or raw == "0" or raw == "off" then return false end
    return nil
end

local function parseNumber(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    return tonumber(raw)
end

local function parseVector(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    raw = raw:gsub("^vec:", "")
    local parts = split(raw, ",")
    if #parts < 2 then return nil end
    return {
        x = tonumber(parts[1]) or 0,
        y = tonumber(parts[2]) or 0,
        z = tonumber(parts[3]) or 0,
    }
end

local function parseObjectPosition(row)
    local x = parseNumber(row.objectx)
    local y = parseNumber(row.objecty)
    if x == nil or y == nil then return nil end
    return {
        x = x,
        y = y,
        z = parseNumber(row.objectz),
    }
end

local function storeVariant(variants, key, variant)
    local existing = variants[key]
    if not existing then
        variants[key] = variant
    elseif existing.recordId ~= nil then
        variants[key] = { existing, variant }
    else
        existing[#existing + 1] = variant
    end
end

local function storeScopedProfile(profilesByRecordId, recordId, profile)
    local existing = profilesByRecordId[recordId]
    if not existing then
        profilesByRecordId[recordId] = { profile }
    else
        existing[#existing + 1] = profile
    end
end

local function parseSlots(raw)
    local slots = {}
    for _, entry in ipairs(split(raw, ";")) do
        -- name|sleepOffset|approachOffset|rootOffset|lateralOffset. Plain names remain valid.
        local parts = splitPreserveEmpty(entry, "|")
        local name = trim(parts[1] or entry)
        if name ~= "" then
            local slot = { name = name }
            if parts[2] and trim(parts[2]) ~= "" then slot.sleepOffset = parseVector(parts[2]) end
            if parts[3] and trim(parts[3]) ~= "" then slot.approachOffset = parseVector(parts[3]) end
            if parts[4] and trim(parts[4]) ~= "" then slot.sleepRootLocalOffset = parseVector(parts[4]) end
            if parts[5] and trim(parts[5]) ~= "" then slot.sleepLateralOffset = tonumber(parts[5]) or 0 end
            slots[#slots + 1] = slot
        end
    end
    if #slots > 0 then return slots end
    return nil
end

local function parseOffsets(raw)
    local offsets = {}
    for _, entry in ipairs(split(raw, ";")) do
        local parts = split(entry, ":")
        if #parts >= 4 then
            local item = {
                name = trim(parts[1]),
                x = tonumber(parts[2]) or 0,
                y = tonumber(parts[3]) or 0,
                z = tonumber(parts[4]) or 0,
            }
            if parts[5] and trim(parts[5]) ~= "" then item.anchor = trim(parts[5]) end
            offsets[#offsets + 1] = item
        end
    end
    if #offsets > 0 then return offsets end
    return nil
end

local function makeSurfaceGrid(width, length, step)
    local offsets = {}
    local halfWidth = (tonumber(width) or 0) / 2
    local halfLength = (tonumber(length) or 0) / 2
    local sampleStep = tonumber(step) or 80

    local function add(x, y)
        offsets[#offsets + 1] = { x = x, y = y, z = 0 }
    end

    add(0, 0)
    local x = -halfWidth
    while x <= halfWidth + 0.001 do
        local y = -halfLength
        while y <= halfLength + 0.001 do
            if not (math.abs(x) < 0.001 and math.abs(y) < 0.001) then add(x, y) end
            y = y + sampleStep
        end
        x = x + sampleStep
    end

    return offsets
end

local function parseGrid(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    raw = raw:gsub("^grid:", "")
    local parts = split(raw, ",")
    if #parts < 3 then return nil end
    return makeSurfaceGrid(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
end

local function parseStringList(raw)
    local list = split(raw, ";")
    if #list > 0 then return list end
    return nil
end

local function parseVariants(raw)
    local variants = {}
    for _, entry in ipairs(split(raw, ";")) do
        -- animation|label|yawDeg|x,y,z
        local parts = split(entry, "|")
        if #parts >= 1 then
            local item = { animation = trim(parts[1]) }
            if parts[2] and trim(parts[2]) ~= "" then item.label = trim(parts[2]) end
            if parts[3] and trim(parts[3]) ~= "" then item.sleepPoseYawOffset = math.rad(tonumber(parts[3]) or 0) end
            if parts[4] and trim(parts[4]) ~= "" then item.sleepRootLocalOffset = parseVector(parts[4]) end
            variants[#variants + 1] = item
        end
    end
    if #variants > 0 then return variants end
    return nil
end

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t or {}) do copy[k] = v end
    return copy
end

local parseRows
local hasAnyColumn

local function profileFileCategory(sourceName)
    local name = lower(sourceName)
    if name:find("bedprofilevariants", 1, true) or name:find("bedorientationprofiles", 1, true) or name:find("bedobjectoverrides", 1, true) then return "bedVariantRows" end
    if name:find("chairprofilevariants", 1, true) or name:find("chairorientationprofiles", 1, true) or name:find("chairoverrides", 1, true) or name:find("chairobjectoverrides", 1, true) then return "chairVariantRows" end
    if name:find("stationprofilevariants", 1, true) or name:find("stationobjectoverrides", 1, true) then return "stationVariantRows" end
    if name:find("bedprofiles", 1, true) then return "bedRows" end
    if name:find("chairprofiles", 1, true) or name:find("seatprofiles", 1, true) then return "chairRows" end
    if name:find("stationprofiles", 1, true) then return "stationRows" end
    return "otherRows"
end

local function profileCategoryFromHeader(header)
    if not header or not hasAnyColumn(header, { "recordid", "matchid" }) then return "otherRows" end
    if hasAnyColumn(header, { "stationtype" }) or hasAnyColumn(header, { "localoffset", "offset" }) then
        if header.yawbucket90 then return "stationVariantRows" end
        return "stationRows"
    end
    if hasAnyColumn(header, {
        "bedtype",
        "sleeprootlocaloffset",
        "sleeprootzoffset",
        "sleepposeyawdeg",
        "sleepinwardoffsetfromapproach",
        "sleepsurfacegrid",
        "sleepsurfacecentermode",
    }) then
        if header.yawbucket90 or header.slotname then return "bedVariantRows" end
        return "bedRows"
    end
    if hasAnyColumn(header, {
        "seattype",
        "widthoffset",
        "seatwidthoffset",
        "xoffset",
        "offsetx",
        "depthoffset",
        "seatdepthoffset",
        "yoffset",
        "offsety",
        "heightoffset",
        "seatheightoffset",
        "zoffset",
        "offsetz",
        "yawoffset",
        "rotationmode",
    }) then
        if header.yawbucket90 or header.slotname then return "chairVariantRows" end
        return "chairRows"
    end
    return "otherRows"
end

local function ensureSummary()
    module.lastLoadSummary = module.lastLoadSummary or {
        bedRows = 0,
        chairRows = 0,
        stationRows = 0,
        bedVariantRows = 0,
        chairVariantRows = 0,
        stationVariantRows = 0,
        otherRows = 0,
        malformedRows = 0,
        skippedRows = 0,
        duplicateKeys = {},
        acceptedRows = {},
        rejectedRows = {},
        loadedFiles = {},
        missingFiles = {},
        seenKeys = {},
    }
    return module.lastLoadSummary
end

local function noteDuplicate(summary, key, sourceName)
    if not (summary and key and key ~= "") then return end
    summary.duplicateKeys[#summary.duplicateKeys + 1] = tostring(sourceName or "<unknown>") .. ":" .. tostring(key)
end

local function noteAccepted(summary, sourceName, kind, key, detail)
    if not summary then return end
    summary.acceptedRows = summary.acceptedRows or {}
    summary.acceptedRows[#summary.acceptedRows + 1] = {
        source = canonicalProfilePath(sourceName),
        kind = tostring(kind or "profile"),
        key = tostring(key or "<unknown>"),
        detail = tostring(detail or ""),
    }
end

local function noteRejected(summary, sourceName, kind, reason, detail)
    if not summary then return end
    summary.rejectedRows = summary.rejectedRows or {}
    summary.rejectedRows[#summary.rejectedRows + 1] = {
        source = canonicalProfilePath(sourceName),
        kind = tostring(kind or "profile"),
        reason = tostring(reason or "malformed_row"),
        detail = tostring(detail or ""),
    }
end

local function scopeDetail(scope)
    local label = profileScope.label(scope)
    if label ~= "" then return " scope=" .. label end
    return ""
end

local function rowHasExtraFields(row)
    local fieldCount = tonumber(row and row.__fieldcount)
    local headerCount = tonumber(row and row.__headercount)
    return fieldCount ~= nil and headerCount ~= nil and fieldCount > headerCount
end

local function rowColumnDetail(row)
    return "fields=" .. tostring(row and row.__fieldcount) .. " headers=" .. tostring(row and row.__headercount)
end

local function variantKey(recordId, model, profileId, slotName, yawBucket90)
    return table.concat({
        lower(recordId),
        lower(model),
        lower(profileId),
        lower(slotName),
        tostring(tonumber(yawBucket90) or 0),
    }, "|")
end

local sittingOffsetFromRow

local function loadOrientationVariantRows(host, content, sourceName)
    host.sleepOrientationVariants = host.sleepOrientationVariants or {}
    local summary = ensureSummary()
    local loaded = 0
    for _, row in ipairs(parseRows(content)) do
        if rowHasExtraFields(row) then
            summary.malformedRows = (summary.malformedRows or 0) + 1
            noteRejected(summary, sourceName, "bed_variant", "extra_tsv_columns", "fields=" .. tostring(row.__fieldcount) .. " headers=" .. tostring(row.__headercount))
        else
            local recordId = lower(row.recordid)
            if recordId == "" then recordId = lower(row.matchid) end
            local slotName = lower(row.slotname)
            local bucket = parseNumber(row.yawbucket90)
            local rootOffset = parseVector(row.sleeprootlocaloffset)
            if recordId ~= "" and slotName ~= "" and bucket ~= nil and rootOffset then
                local variant = {
                    recordId = recordId,
                    model = trim(row.model),
                    profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId,
                    slotName = slotName,
                    yawBucket90 = bucket,
                    sleepRootLocalOffset = rootOffset,
                    scope = profileScope.scopeFromRow(row, sourceName),
                    objectPosition = parseObjectPosition(row),
                    yawMinDeg = parseNumber(row.yawmindeg),
                    yawMaxDeg = parseNumber(row.yawmaxdeg),
                    sourceRow = shallowCopy(row),
                    sourceName = sourceName,
                }
                if trim(row.sleepposeyawdeg) ~= "" then
                    variant.sleepPoseYawOffset = math.rad(tonumber(row.sleepposeyawdeg) or 0)
                end
                local notes = lower(row.notes)
                if notes:find("splitslotyaw=true", 1, true) or notes:find("split_slot_yaw", 1, true) then
                    variant.splitSlotYaw = true
                end
                storeVariant(host.sleepOrientationVariants, variantKey(recordId, row.model, variant.profileId, slotName, bucket), variant)
                if trim(row.model) ~= "" then
                    storeVariant(host.sleepOrientationVariants, variantKey(recordId, "", variant.profileId, slotName, bucket), variant)
                end
                noteAccepted(summary, sourceName, "bed_variant", variantKey(recordId, row.model, variant.profileId, slotName, bucket), "slot=" .. tostring(slotName) .. " offset=" .. tostring(row.sleeprootlocaloffset) .. scopeDetail(variant.scope))
                loaded = loaded + 1
            else
                summary.malformedRows = (summary.malformedRows or 0) + 1
                noteRejected(summary, sourceName, "bed_variant", "malformed_row", "record=" .. tostring(recordId) .. " slot=" .. tostring(slotName) .. " bucket=" .. tostring(bucket))
            end
        end
    end
    summary.bedVariantRows = (summary.bedVariantRows or 0) + loaded
    return loaded
end

local function loadChairOrientationVariantRows(host, content, sourceName)
    host.chairOrientationVariants = host.chairOrientationVariants or {}
    local summary = ensureSummary()
    local loaded = 0
    for _, row in ipairs(parseRows(content)) do
        if rowHasExtraFields(row) then
            summary.malformedRows = (summary.malformedRows or 0) + 1
            noteRejected(summary, sourceName, "chair_variant", "extra_tsv_columns", "fields=" .. tostring(row.__fieldcount) .. " headers=" .. tostring(row.__headercount))
        else
            local recordId = lower(row.recordid)
            if recordId == "" then recordId = lower(row.matchid) end
            local slotName = lower(row.slotname)
            if slotName == "" then slotName = "default" end
            local bucket = parseNumber(row.yawbucket90)
            local offset = sittingOffsetFromRow(row)
            if recordId ~= "" and slotName ~= "" and bucket ~= nil and offset then
                local variant = {
                    recordId = recordId,
                    model = trim(row.model),
                    profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId,
                    slotName = slotName,
                    yawBucket90 = bucket,
                    offset = offset,
                    scope = profileScope.scopeFromRow(row, sourceName),
                    objectPosition = parseObjectPosition(row),
                    yawMinDeg = parseNumber(row.yawmindeg),
                    yawMaxDeg = parseNumber(row.yawmaxdeg),
                    sourceRow = shallowCopy(row),
                    sourceName = sourceName,
                }
                storeVariant(host.chairOrientationVariants, variantKey(recordId, row.model, variant.profileId, slotName, bucket), variant)
                if trim(row.model) ~= "" then
                    storeVariant(host.chairOrientationVariants, variantKey(recordId, "", variant.profileId, slotName, bucket), variant)
                end
                noteAccepted(summary, sourceName, "chair_variant", variantKey(recordId, row.model, variant.profileId, slotName, bucket), "slot=" .. tostring(slotName) .. " offset=" .. tostring(row.widthoffset or row.xoffset or "") .. "," .. tostring(row.depthoffset or row.yoffset or "") .. "," .. tostring(row.heightoffset or row.zoffset or "") .. scopeDetail(variant.scope))
                loaded = loaded + 1
            else
                summary.malformedRows = (summary.malformedRows or 0) + 1
                noteRejected(summary, sourceName, "chair_variant", "malformed_row", "record=" .. tostring(recordId) .. " slot=" .. tostring(slotName) .. " bucket=" .. tostring(bucket))
            end
        end
    end
    summary.chairVariantRows = (summary.chairVariantRows or 0) + loaded
    return loaded
end

local function loadStationProfileRows(host, content, sourceName)
    host.stationProfilesByRecordId = host.stationProfilesByRecordId or {}
    host.scopedStationProfilesByRecordId = host.scopedStationProfilesByRecordId or {}
    local summary = ensureSummary()
    local loaded = 0
    for _, row in ipairs(parseRows(content)) do
        if rowHasExtraFields(row) then
            summary.malformedRows = (summary.malformedRows or 0) + 1
            noteRejected(summary, sourceName, "station_profile", "extra_tsv_columns", rowColumnDetail(row))
        else
            local recordId = lower(row.recordid)
            if recordId == "" then recordId = lower(row.matchid) end
            local localOffset = parseVector(row.localoffset)
            if not localOffset then localOffset = parseVector(row.offset) end
            if recordId ~= "" and localOffset then
                local profile = {
                    recordId = recordId,
                    model = trim(row.model),
                    profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId,
                    interactionType = "station",
                    stationType = trim(row.stationtype) ~= "" and trim(row.stationtype) or "station",
                    slotName = lower(row.slotname) ~= "" and lower(row.slotname) or "station",
                    localOffset = localOffset,
                    facingYawDeg = parseNumber(row.facingyawdeg) or parseNumber(row.yawdeg) or 0,
                    radius = parseNumber(row.radius) or 220,
                    flags = parseStringList(row.flags) or {},
                    scope = profileScope.scopeFromRow(row, sourceName),
                    sourceRow = shallowCopy(row),
                    sourceName = canonicalProfilePath(sourceName),
                }
                if profile.scope then
                    storeScopedProfile(host.scopedStationProfilesByRecordId, recordId, profile)
                else
                    host.stationProfilesByRecordId[recordId] = profile
                end
                noteAccepted(summary, sourceName, "station_profile", "station|" .. recordId .. "|" .. tostring(profile.profileId) .. "|" .. tostring(profile.slotName), "offset=" .. tostring(row.localoffset or row.offset or "") .. scopeDetail(profile.scope) .. " " .. rowColumnDetail(row))
                loaded = loaded + 1
            else
                summary.malformedRows = (summary.malformedRows or 0) + 1
                noteRejected(summary, sourceName, "station_profile", "missing_required_columns", "record=" .. tostring(recordId) .. " offset=" .. tostring(row.localoffset or row.offset) .. " " .. rowColumnDetail(row))
            end
        end
    end
    summary.stationRows = (summary.stationRows or 0) + loaded
    return loaded
end

local function loadStationVariantRows(host, content, sourceName)
    host.stationOrientationVariants = host.stationOrientationVariants or {}
    local summary = ensureSummary()
    local loaded = 0
    for _, row in ipairs(parseRows(content)) do
        if rowHasExtraFields(row) then
            summary.malformedRows = (summary.malformedRows or 0) + 1
            noteRejected(summary, sourceName, "station_variant", "extra_tsv_columns", rowColumnDetail(row))
        else
            local recordId = lower(row.recordid)
            if recordId == "" then recordId = lower(row.matchid) end
            local slotName = lower(row.slotname)
            if slotName == "" then slotName = "presenter" end
            local bucket = parseNumber(row.yawbucket90)
            local localOffset = parseVector(row.localoffset)
            if not localOffset then localOffset = parseVector(row.offset) end
            if recordId ~= "" and slotName ~= "" and bucket ~= nil and localOffset then
                local variant = {
                    recordId = recordId,
                    model = trim(row.model),
                    profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId,
                    stationType = trim(row.stationtype),
                    slotName = slotName,
                    yawBucket90 = bucket,
                    localOffset = localOffset,
                    facingYawDeg = parseNumber(row.facingyawdeg) or parseNumber(row.yawdeg),
                    radius = parseNumber(row.radius),
                    flags = parseStringList(row.flags),
                    scope = profileScope.scopeFromRow(row, sourceName),
                    objectPosition = parseObjectPosition(row),
                    yawMinDeg = parseNumber(row.yawmindeg),
                    yawMaxDeg = parseNumber(row.yawmaxdeg),
                    sourceRow = shallowCopy(row),
                    sourceName = canonicalProfilePath(sourceName),
                }
                storeVariant(host.stationOrientationVariants, variantKey(recordId, row.model, variant.profileId, slotName, bucket), variant)
                if trim(row.model) ~= "" then
                    storeVariant(host.stationOrientationVariants, variantKey(recordId, "", variant.profileId, slotName, bucket), variant)
                end
                noteAccepted(summary, sourceName, "station_variant", variantKey(recordId, row.model, variant.profileId, slotName, bucket), "slot=" .. tostring(slotName) .. " offset=" .. tostring(row.localoffset or row.offset or "") .. scopeDetail(variant.scope))
                loaded = loaded + 1
            else
                summary.malformedRows = (summary.malformedRows or 0) + 1
                noteRejected(summary, sourceName, "station_variant", "malformed_row", "record=" .. tostring(recordId) .. " slot=" .. tostring(slotName) .. " bucket=" .. tostring(bucket))
            end
        end
    end
    summary.stationVariantRows = (summary.stationVariantRows or 0) + loaded
    return loaded
end

local function splitTsvLine(line)
    local fields = {}
    (line .. "\t"):gsub("([^\t]*)\t", function(field)
        fields[#fields + 1] = field
        return ""
    end)
    return fields
end

local function firstHeaderMap(content)
    for rawLine in tostring(content or ""):gmatch("[^\r\n]+") do
        local line = rawLine:match("^[^#]*") or ""
        if trim(line) ~= "" then
            local header = {}
            for _, name in ipairs(splitTsvLine(line)) do
                local key = lower(name)
                if key ~= "" then header[key] = true end
            end
            return header
        end
    end
    return nil
end

hasAnyColumn = function(header, names)
    for _, name in ipairs(names) do
        if header[name] then return true end
    end
    return false
end

local function profileCategoryForSource(sourceName, content)
    local header = firstHeaderMap(content)
    local category = profileFileCategory(sourceName)
    if category == "otherRows" then category = profileCategoryFromHeader(header) end
    if category == "otherRows" or not header then return "otherRows" end
    if not hasAnyColumn(header, { "recordid", "matchid" }) then return "otherRows" end

    if category == "bedVariantRows" then
        if header.slotname == true
            and header.yawbucket90 == true
            and hasAnyColumn(header, { "sleeprootlocaloffset", "sleepposeyawdeg" }) then
            return category
        end
        return "otherRows"
    end
    if category == "chairVariantRows" then
        if header.yawbucket90 == true
            and hasAnyColumn(header, { "widthoffset", "seatwidthoffset", "xoffset", "offsetx" })
            and hasAnyColumn(header, { "depthoffset", "seatdepthoffset", "yoffset", "offsety" }) then
            return category
        end
        return "otherRows"
    end
    if category == "stationVariantRows" then
        if header.yawbucket90 == true and hasAnyColumn(header, { "localoffset", "offset" }) then
            return category
        end
        return "otherRows"
    end
    if category == "stationRows" then
        if hasAnyColumn(header, { "localoffset", "offset" }) then return category end
        return "otherRows"
    end
    if category == "bedRows" or category == "chairRows" then return category end
    return "otherRows"
end

parseRows = function(content)
    local rows = {}
    local headers = nil

    for rawLine in tostring(content or ""):gmatch("[^\r\n]+") do
        local line = rawLine:match("^[^#]*") or ""
        if trim(line) ~= "" then
            local fields = splitTsvLine(line)
            if not headers then
                headers = {}
                for i, name in ipairs(fields) do headers[i] = lower(name) end
            else
                local row = {}
                for i, name in ipairs(headers) do
                    if name and name ~= "" then row[name] = fields[i] or "" end
                end
                row.__fieldcount = #fields
                row.__headercount = #headers
                rows[#rows + 1] = row
            end
        end
    end

    return rows
end

local scalarParsers = {
    profileid = "string",
    interactiontype = "string",
    type = "string",
    bedtype = "string",
    animation = "string",
    rotationmode = "string",
    sleepsurfacecentermode = "string",
    finalforwardoffset = "number",
    finalzoffset = "number",
    sleeprootzoffset = "number",
    sleepposeyawdeg = "yawDegrees",
    sleepinwardoffsetfromapproach = "number",
    sleepsurfaceminheight = "number",
    sleepsurfacemaxheight = "number",
    sleepminexitdistance = "number",
    sleepexitfloordrop = "number",
    transitiondistance = "number",
    approachstucktimeout = "number",
    approachhardtimeout = "number",
    approachforceminseconds = "number",
    approachforcetransitiondistance = "number",
    approachforceobjectdistance = "number",
    supportsslots = "boolean",
}

local keyMap = {
    recordid = "recordId",
    matchid = "recordId",
    profileid = "profileId",
    interactiontype = "interactionType",
    bedtype = "bedType",
    seattype = "type",
    matchmodel = "model",
    rotationmode = "rotationMode",
    animation = "animation",
    finalforwardoffset = "finalForwardOffset",
    finalzoffset = "finalZOffset",
    sleeprootlocaloffset = "sleepRootLocalOffset",
    sleeprootzoffset = "sleepRootZOffset",
    sleepposeyawdeg = "sleepPoseYawOffset",
    model = "model",
    sleepinwardoffsetfromapproach = "sleepInwardOffsetFromApproach",
    sleepsurfacegrid = "sleepSurfaceSampleOffsets",
    sleepsurfacecentermode = "sleepSurfaceCenterMode",
    sleepsurfaceminheight = "sleepSurfaceMinHeight",
    sleepsurfacemaxheight = "sleepSurfaceMaxHeight",
    sleepminexitdistance = "sleepMinExitDistance",
    sleepexitfloordrop = "sleepExitFloorDrop",
    sleepanimationvariants = "sleepAnimationVariants",
    allowperframecorrection = "allowPerFrameCorrection",
    allowfallbackpositioning = "allowFallbackPositioning",
    supportsslots = "supportsSlots",
    approachstucktimeout = "approachStuckTimeout",
    approachhardtimeout = "approachHardTimeout",
    approachforceminseconds = "approachForceMinSeconds",
    approachforcetransitiondistance = "approachForceTransitionDistance",
    approachforceobjectdistance = "approachForceObjectDistance",
}

local function valueForColumn(name, raw)
    raw = trim(raw)
    if raw == "" then return nil end

    if name == "slots" then return parseSlots(raw) end
    if name == "approachoffsets" then return parseOffsets(raw) end
    if name == "exitoffsets" then return parseOffsets(raw) end
    if name == "sleeprootlocaloffset" then return parseVector(raw) end
    if name == "sleepsurfacegrid" then return parseGrid(raw) end
    if name == "sleepanimationvariants" then return parseVariants(raw) end
    if name == "sleepflags" or name == "flags" then return parseStringList(raw) end

    if name == "sleepposeyawdeg" then
        local n = parseNumber(raw)
        if n ~= nil then return math.rad(n) end
        return nil
    end

    local bool = parseBool(raw)
    if bool ~= nil then return bool end

    local n = parseNumber(raw)
    if n ~= nil then return n end

    return raw
end

local function applySpecialFlags(profile, raw)
    for _, flag in ipairs(parseStringList(raw) or {}) do
        flag = lower(flag)
        local sharedAxes = flag:match("^sharedslotaxes[:=](.+)$")
            or flag:match("^shared_slot_axes[:=](.+)$")
        if flag == "sharedslotz" then sharedAxes = "z" end
        if sharedAxes then
            profile.sharedSlotAxes = profile.sharedSlotAxes or {}
            for axis in sharedAxes:gmatch("[xyz]") do
                profile.sharedSlotAxes[axis] = true
            end
        end
        if flag == "absorbmatchingsleepcalibration" then profile.absorbMatchingSleepCalibration = true end
        if flag == "sleepexitsideonly" then profile.sleepExitSideOnly = true end
        if flag == "disableapproachfallback" then profile.sleepExitIncludeApproachFallback = false end
        if flag == "disableringfallback" then profile.sleepExitDisableRingFallback = true end
        if flag == "preferapproachside" then profile.sleepExitPreferApproachSide = true end
        if flag == "whitelistonly" then profile.whitelistOnly = true end
        if flag == "unsafeifblocked" then profile.unsafeIfBlocked = true end
        if flag == "allowblockedapproachteleport" then profile.allowBlockedApproachTeleport = true end
        if flag == "sleepreturntooriginfallback" then profile.sleepReturnToOriginFallback = true end
        if flag == "noanysleepsurfacehit" or flag == "objectsleepsurfaceonly" then profile.allowAnySleepSurfaceHit = false end
        if flag == "allowanysleepsurfaceanchor" or flag == "allow_any_sleep_surface_anchor" then profile.allowAnySleepSurfaceAnchor = true end
        local sleepSurfaceAnchor = flag:match("^sleepsurfaceanchor[:=](.+)$")
            or flag:match("^sleep_surface_anchor[:=](.+)$")
        if sleepSurfaceAnchor then profile.sleepSurfaceAnchorPolicy = sleepSurfaceAnchor end
        if flag == "highanytopsleepanchor" or flag == "sleephighanytopanchor" then profile.sleepSurfaceAnchorPolicy = "high_any_top" end
        if flag == "allowlowobjectorigintop" then profile.allowLowObjectOriginTop = true end
        if flag == "allowobjectoriginfallbacksleep"
            or flag == "allowweaksleepfallback"
            or flag == "allowsleepfallbacksurface" then
            profile.allowObjectOriginFallbackSleep = true
        end
    end
end

local function inferredInteractionType(row, sourceName, category)
    local interactionType = lower(row.interactiontype)
    if interactionType ~= "" then return interactionType end
    if category == "bedRows" then return "sleeping" end
    if category == "chairRows" then return "sitting" end

    local source = lower(sourceName)
    if source:find("bed", 1, true) then return "sleeping" end
    if source:find("chair", 1, true) or source:find("seat", 1, true) then return "sitting" end

    return ""
end

local function profileBaseForRow(host, row, sourceName, category)
    local recordId = lower(row.recordid)
    local interactionType = inferredInteractionType(row, sourceName, category)
    local baseKey = lower(row.base)

    if baseKey == "existing" and host.profilesByRecordId[recordId] then return host.profilesByRecordId[recordId] end
    if interactionType == "sleeping" then return host.sleepingProfileSchema end
    if interactionType == "sitting" then return host.profilesByRecordId[recordId] or host.fallbackProfiles and host.fallbackProfiles.sitting or nil end
    return host.profilesByRecordId[recordId]
end


local function firstNumber(row, names)
    for _, name in ipairs(names) do
        local value = parseNumber(row[name])
        if value ~= nil then return value end
    end
    return nil
end

local function ensureSittingOffsetTables(profile)
    profile.sittingActivityOffsets = profile.sittingActivityOffsets or {}
    profile.sittingActivityAnimationOffsets = profile.sittingActivityAnimationOffsets or {}
end

sittingOffsetFromRow = function(row)
    local x = firstNumber(row, { "widthoffset", "seatwidthoffset", "xoffset", "offsetx" })
    local y = firstNumber(row, { "depthoffset", "seatdepthoffset", "yoffset", "offsety" })
    local z = firstNumber(row, { "heightoffset", "seatheightoffset", "zoffset", "offsetz" })
    local yaw = firstNumber(row, { "yawoffset", "yawdeg", "yawdegrees", "seatyawoffset" })
    if x == nil and y == nil and z == nil and yaw == nil then return nil end
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        yaw = yaw or 0,
    }
end

local function applySittingActivityOffset(profile, row)
    if not profile or profile.interactionType ~= "sitting" then return end
    local activity = lower(row.activity)
    local animation = lower(row.animation)
    local offset = sittingOffsetFromRow(row)
    if activity == "" and not offset then return end

    ensureSittingOffsetTables(profile)

    if activity == "" then activity = "standard" end
    if activity == "base" or activity == "default" or activity == "normal" then activity = "standard" end

    if offset then
        if animation ~= "" then
            profile.sittingActivityAnimationOffsets[activity .. "|" .. animation] = offset
        else
            profile.sittingActivityOffsets[activity] = offset
        end
    end
end

function module.loadProfileRows(host, content, sourceName, forcedCategory)
    if not host or not content then return 0 end
    local category = forcedCategory or profileFileCategory(sourceName)
    if category == "bedVariantRows" then
        return loadOrientationVariantRows(host, content, sourceName)
    end
    if category == "chairVariantRows" then
        return loadChairOrientationVariantRows(host, content, sourceName)
    end
    if category == "stationVariantRows" then
        return loadStationVariantRows(host, content, sourceName)
    end
    if category == "stationRows" then
        return loadStationProfileRows(host, content, sourceName)
    end
    local summary = ensureSummary()
    local loaded = 0

    for _, row in ipairs(parseRows(content)) do
        if rowHasExtraFields(row) then
            summary.malformedRows = (summary.malformedRows or 0) + 1
            noteRejected(summary, sourceName, category, "extra_tsv_columns", rowColumnDetail(row))
        else
            local recordId = lower(row.recordid)
            if recordId == "" then recordId = lower(row.matchid) end
            if recordId ~= "" then
            local interactionType = inferredInteractionType(row, sourceName, category)
            local profileIdForKey = trim(row.profileid) ~= "" and lower(row.profileid) or recordId
            local scope = profileScope.scopeFromRow(row, sourceName)
            local rowKey = interactionType .. "|" .. recordId .. "|" .. profileIdForKey .. scopeDetail(scope)
            if summary.seenKeys[rowKey] then
                noteDuplicate(summary, rowKey, sourceName)
            else
                summary.seenKeys[rowKey] = true
            end
            local base = profileBaseForRow(host, row, sourceName, category) or {}
            local profile = shallowCopy(base)
            profile.profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId
            profile.interactionType = interactionType ~= "" and interactionType or profile.interactionType
            profile.externalProfile = true
            profile.isFallback = false
            profile.profileBedTypeFallback = nil
            profile.profileBedTypeFallbackCount = nil
            profile.profileBedTypeFallbackLowConfidence = nil
            profile.profileBedTypeFallbackAxes = nil
            profile.scope = scope
            profile.sourceRow = shallowCopy(row)
            profile.sourceName = canonicalProfilePath(sourceName)
            if profile.interactionType == "sleeping" then
                -- Universal sleep behavior belongs in Lua defaults, not in bedProfiles.txt.
                profile.animation = host.sleepingProfileSchema and host.sleepingProfileSchema.animation or profile.animation
                profile.animations = host.sleepingProfileSchema and host.sleepingProfileSchema.animations or profile.animations
                profile.sleepAnimationVariants = host.sleepingProfileSchema and host.sleepingProfileSchema.sleepAnimationVariants or profile.sleepAnimationVariants
                profile.approachOffsets = host.sleepingProfileSchema and host.sleepingProfileSchema.approachOffsets or profile.approachOffsets
                profile.exitOffsets = host.sleepingProfileSchema and host.sleepingProfileSchema.exitOffsets or profile.exitOffsets
                profile.sleepExitSideOnly = true
                profile.sleepExitIncludeApproachFallback = false
                profile.sleepExitDisableRingFallback = true
                profile.sleepExitPreferApproachSide = true
                profile.allowBlockedApproachTeleport = false
                profile.sleepReturnToOriginFallback = true
            end

            for rawName, rawValue in pairs(row) do
                local name = lower(rawName)
                local activity = lower(row.activity)
                local isSittingActivitySpecific = profile.interactionType == "sitting" and activity ~= "" and activity ~= "standard" and activity ~= "base" and activity ~= "default" and activity ~= "normal"
                local skipSittingActivityColumn = profile.interactionType == "sitting" and (
                    name == "activity" or name == "widthoffset" or name == "seatwidthoffset" or name == "xoffset" or name == "offsetx"
                    or name == "depthoffset" or name == "seatdepthoffset" or name == "yoffset" or name == "offsety"
                    or name == "heightoffset" or name == "seatheightoffset" or name == "zoffset" or name == "offsetz"
                    or name == "yawoffset" or name == "yawdeg" or name == "yawdegrees" or name == "seatyawoffset"
                    or (isSittingActivitySpecific and name == "animation")
                )
                if name ~= "" and name:sub(1, 2) ~= "__" and name ~= "recordid" and name ~= "matchid" and name ~= "base" and name ~= "notes" and name ~= "propfamily" and name ~= "placekey" and name ~= "place" and name ~= "place_key" and name ~= "cell" and name ~= "cellname" and name ~= "exactcell" and name ~= "cellprefix" and name ~= "cell_prefix" and name ~= "region" and name ~= "regionname" and not skipSittingActivityColumn and trim(rawValue) ~= "" then
                    if name == "flags" or name == "sleepflags" then
                        applySpecialFlags(profile, rawValue)
                    else
                        local key = keyMap[name] or rawName
                        local value = valueForColumn(name, rawValue)
                        if value ~= nil then profile[key] = value end
                    end
                end
            end

            applySittingActivityOffset(profile, row)

            if profile.interactionType == "sleeping" and lower(profile.bedType or "") == "hammock" then
                -- Hammocks support the usual lying variants; the visual failure seen in
                -- testing appears more likely tied to load/assignment timing than the
                -- side-sleep group itself. Keep both variants available and let the
                -- local actor choose the first available/stable option.
                profile.sleepAnimationVariants = {
                    { animation = "sdpvasitting9", label = "hammock_lying_on_back", sleepPoseYawOffset = math.rad(-90) },
                    { animation = "sdpvasitting8", label = "hammock_sleeping_on_side", sleepPoseYawOffset = math.rad(-90) },
                }
            end

            if profile.scope then
                host.scopedProfilesByRecordId = host.scopedProfilesByRecordId or {}
                storeScopedProfile(host.scopedProfilesByRecordId, recordId, profile)
            else
                host.profilesByRecordId[recordId] = profile
            end
            noteAccepted(summary, sourceName, category, rowKey, "profile=" .. tostring(profile.profileId) .. " type=" .. tostring(profile.interactionType) .. scopeDetail(profile.scope) .. " " .. rowColumnDetail(row))
            loaded = loaded + 1
            else
                summary.skippedRows = (summary.skippedRows or 0) + 1
                noteRejected(summary, sourceName, category, "missing_record_id", "profile=" .. tostring(row.profileid) .. " " .. rowColumnDetail(row))
            end
        end
    end

    summary[category] = (summary[category] or 0) + loaded
    return loaded
end

local function currentVfs()
    -- OpenMW's VFS API should be imported with require('openmw.vfs').
    -- The old global-vfs probe was unreliable and produced profileRows=0 in-game.
    if vfsPackage then return vfsPackage end

    return rawget(_G, "vfs")
end

local function tryOpenVfs(path)
    local vfstable = currentVfs()
    if not (vfstable and vfstable.open) then return nil end
    local file = vfstable.open(path)
    return file
end

local function filePriority(filename)
    local name = lower(filename)
    if name:find("chairprofiles", 1, true) then return 10 end
    if name:find("bedprofiles", 1, true) then return 20 end
    if name:find("stationprofiles", 1, true) then return 25 end
    if name:find("stationprofilevariants", 1, true) then return 35 end
    if name:find("chairprofilevariants", 1, true) or name:find("chairorientationprofiles", 1, true) then return 30 end
    if name:find("bedprofilevariants", 1, true) or name:find("bedorientationprofiles", 1, true) then return 40 end
    if name:find("chairobjectoverrides", 1, true) then return 45 end
    if name:find("bedobjectoverrides", 1, true) then return 46 end
    if name:find("stationobjectoverrides", 1, true) then return 47 end
    return 50
end

local function sourceLayerPriority(filename)
    local name = lower(filename):gsub("\\", "/")
    if name:match("^furnitureprofiles/sdp/global/") then return 10 end
    if name:match("^furnitureprofiles/sdp/shared/") then return 30 end
    if name:match("^furnitureprofiles/sdp/places/") then return 40 end
    return 50
end

local function isSdpSystemPath(path)
    return lower(path):gsub("\\", "/"):match("^furnitureprofiles/sdp/") ~= nil
end

local function isReservedNestedSdpAddonPath(path)
    local name = lower(path):gsub("\\", "/")
    return name:match("^furnitureprofiles/.+/sdp/") ~= nil and not isSdpSystemPath(name)
end

local function categoryPriority(category)
    if category == "chairRows" then return 10 end
    if category == "bedRows" then return 20 end
    if category == "stationRows" then return 25 end
    if category == "chairVariantRows" then return 30 end
    if category == "stationVariantRows" then return 35 end
    if category == "bedVariantRows" then return 40 end
    return 50
end

function module.loadProfileFiles(host, debugLog)
    local vfstable = currentVfs()
    module.lastLoadSummary = {
        bedRows = 0,
        chairRows = 0,
        stationRows = 0,
        bedVariantRows = 0,
        chairVariantRows = 0,
        stationVariantRows = 0,
        otherRows = 0,
        malformedRows = 0,
        skippedRows = 0,
        duplicateKeys = {},
        acceptedRows = {},
        rejectedRows = {},
        loadedFiles = {},
        missingFiles = {},
        seenKeys = {},
    }
    local summary = module.lastLoadSummary
    if not (vfstable and vfstable.pathsWithPrefix and vfstable.open) then
        if debugLog then debugLog("profile tsv loader skipped", "vfs_unavailable") end
        return 0
    end

    local files, seenFiles = {}, {}
    local function addProfileFile(filename)
        filename = normalizedPath(filename)
        if seenFiles[filename] or not isTextProfilePath(filename) then return end
        seenFiles[filename] = true
        files[#files + 1] = filename
        summary.loadedFiles[canonicalProfilePath(filename)] = false
    end

    for filename in vfstable.pathsWithPrefix(PROFILE_ROOT) do
        addProfileFile(filename)
    end
    for filename in vfstable.pathsWithPrefix(SHARED_PROFILE_ROOT) do
        local normalized = normalizedPath(filename)
        if not isSdpSystemPath(normalized) and not isReservedNestedSdpAddonPath(normalized) then
            addProfileFile(normalized)
        end
    end
    local candidates = {}
    for _, filename in ipairs(files) do
        local file = tryOpenVfs(filename)
        if file then
            local content = file:read("*all")
            file:close()
            local canonical = canonicalProfilePath(filename)
            local category = profileCategoryForSource(canonical, content)
            if category ~= "otherRows" then
                candidates[#candidates + 1] = {
                    filename = filename,
                    canonical = canonical,
                    content = content,
                    category = category,
                }
            elseif debugLog then
                debugLog("profile tsv ignored", canonical, "unrecognized_schema")
            end
        end
    end

    table.sort(candidates, function(a, b)
        local ca, cb = categoryPriority(a.category), categoryPriority(b.category)
        if ca ~= cb then return ca < cb end
        local pa, pb = filePriority(a.filename), filePriority(b.filename)
        if pa ~= pb then return pa < pb end
        local la, lb = sourceLayerPriority(a.filename), sourceLayerPriority(b.filename)
        if la ~= lb then return la < lb end
        return tostring(a.filename) < tostring(b.filename)
    end)

    local total = 0
    for _, candidate in ipairs(candidates) do
        local loaded = module.loadProfileRows(host, candidate.content, candidate.canonical, candidate.category)
        total = total + loaded
        summary.loadedFiles[candidate.canonical] = true
        if debugLog then debugLog("profile tsv loaded", candidate.canonical, tostring(loaded)) end
    end
    for _, expected in ipairs({
        "furnitureProfiles/sdp/global/bedProfiles.txt",
        "furnitureProfiles/sdp/global/chairProfiles.txt",
        "furnitureProfiles/sdp/global/stationProfiles.txt",
        "furnitureProfiles/sdp/global/stationProfileVariants.txt",
        "furnitureProfiles/sdp/global/chairProfileVariants.txt",
        "furnitureProfiles/sdp/global/bedProfileVariants.txt",
        "furnitureProfiles/sdp/global/chairObjectOverrides.txt",
        "furnitureProfiles/sdp/global/bedObjectOverrides.txt",
        "furnitureProfiles/sdp/global/stationObjectOverrides.txt",
    }) do
        local canonical = canonicalProfilePath(expected)
        if summary.loadedFiles[canonical] == nil then
            summary.missingFiles[#summary.missingFiles + 1] = expected
        end
    end
    summary.totalRows = total
    return total
end

return module
