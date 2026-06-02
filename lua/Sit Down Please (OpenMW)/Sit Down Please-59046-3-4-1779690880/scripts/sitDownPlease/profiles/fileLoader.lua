-- profiles/fileLoader.lua
--
-- Small Sun's-Dusk-style TSV loader for Sit Down Please object profiles.
-- Profiles stay editable in tab-separated .txt files under sdp_furnitureProfiles/,
-- while the Lua schemas remain as stable defaults/fallbacks.

local module = {}
module.lastLoadSummary = nil

local okVfsPackage, vfsPackage = pcall(require, 'openmw.vfs')
if not okVfsPackage then vfsPackage = nil end

local CANONICAL_PROFILE_PATHS = {
    ["sdp_furnitureprofiles/bedprofiles.txt"] = "sdp_furnitureProfiles/bedProfiles.txt",
    ["sdp_furnitureprofiles/chairprofiles.txt"] = "sdp_furnitureProfiles/chairProfiles.txt",
    ["sdp_furnitureprofiles/bedprofilevariants.txt"] = "sdp_furnitureProfiles/bedProfileVariants.txt",
    ["sdp_furnitureprofiles/chairprofilevariants.txt"] = "sdp_furnitureProfiles/chairProfileVariants.txt",
    ["sdp_furnitureprofiles/animationnormalizationoffsets.txt"] = "sdp_furnitureProfiles/animationNormalizationOffsets.txt",
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
    local raw = trim(path)
    return CANONICAL_PROFILE_PATHS[string.lower(raw)] or raw
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

local function profileFileCategory(sourceName)
    local name = lower(sourceName)
    if name:find("bedprofilevariants", 1, true) or name:find("bedorientationprofiles", 1, true) then return "bedVariantRows" end
    if name:find("chairprofilevariants", 1, true) or name:find("chairorientationprofiles", 1, true) then return "chairVariantRows" end
    if name:find("bedprofiles", 1, true) then return "bedRows" end
    if name:find("chairprofiles", 1, true) or name:find("seatprofiles", 1, true) then return "chairRows" end
    return "otherRows"
end

local function ensureSummary()
    module.lastLoadSummary = module.lastLoadSummary or {
        bedRows = 0,
        chairRows = 0,
        bedVariantRows = 0,
        chairVariantRows = 0,
        otherRows = 0,
        malformedRows = 0,
        skippedRows = 0,
        duplicateKeys = {},
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
                objectPosition = parseObjectPosition(row),
                yawMinDeg = parseNumber(row.yawmindeg),
                yawMaxDeg = parseNumber(row.yawmaxdeg),
                sourceRow = shallowCopy(row),
                sourceName = sourceName,
            }
            if trim(row.sleepposeyawdeg) ~= "" then
                variant.sleepPoseYawOffset = math.rad(tonumber(row.sleepposeyawdeg) or 0)
            end
            storeVariant(host.sleepOrientationVariants, variantKey(recordId, row.model, variant.profileId, slotName, bucket), variant)
            if trim(row.model) ~= "" then
                storeVariant(host.sleepOrientationVariants, variantKey(recordId, "", variant.profileId, slotName, bucket), variant)
            end
            loaded = loaded + 1
        else
            summary.malformedRows = (summary.malformedRows or 0) + 1
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
                yawMinDeg = parseNumber(row.yawmindeg),
                yawMaxDeg = parseNumber(row.yawmaxdeg),
                sourceRow = shallowCopy(row),
                sourceName = sourceName,
            }
            storeVariant(host.chairOrientationVariants, variantKey(recordId, row.model, variant.profileId, slotName, bucket), variant)
            if trim(row.model) ~= "" then
                storeVariant(host.chairOrientationVariants, variantKey(recordId, "", variant.profileId, slotName, bucket), variant)
            end
            loaded = loaded + 1
        else
            summary.malformedRows = (summary.malformedRows or 0) + 1
        end
    end
    summary.chairVariantRows = (summary.chairVariantRows or 0) + loaded
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
    end
end

local function inferredInteractionType(row, sourceName)
    local interactionType = lower(row.interactiontype)
    if interactionType ~= "" then return interactionType end

    local source = lower(sourceName)
    if source:find("bed", 1, true) then return "sleeping" end
    if source:find("chair", 1, true) or source:find("seat", 1, true) then return "sitting" end

    return ""
end

local function profileBaseForRow(host, row, sourceName)
    local recordId = lower(row.recordid)
    local interactionType = inferredInteractionType(row, sourceName)
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

local function findSittingProfileById(host, profileKey)
    profileKey = lower(profileKey)
    if profileKey == "" then return nil end
    if host.profilesByRecordId and host.profilesByRecordId[profileKey] then return host.profilesByRecordId[profileKey] end
    for _, profile in pairs(host.profilesByRecordId or {}) do
        if profile and lower(profile.profileId) == profileKey and profile.interactionType == "sitting" then
            return profile
        end
    end
    return nil
end


function module.loadProfileRows(host, content, sourceName)
    if not host or not content then return 0 end
    if lower(sourceName):find("bedprofilevariants", 1, true) or lower(sourceName):find("bedorientationprofiles", 1, true) then
        return loadOrientationVariantRows(host, content, sourceName)
    end
    if lower(sourceName):find("chairprofilevariants", 1, true) or lower(sourceName):find("chairorientationprofiles", 1, true) then
        return loadChairOrientationVariantRows(host, content, sourceName)
    end
    local summary = ensureSummary()
    local category = profileFileCategory(sourceName)
    local loaded = 0

    for _, row in ipairs(parseRows(content)) do
        local recordId = lower(row.recordid)
        if recordId == "" then recordId = lower(row.matchid) end
        if recordId ~= "" then
            local interactionType = inferredInteractionType(row, sourceName)
            local profileIdForKey = trim(row.profileid) ~= "" and lower(row.profileid) or recordId
            local rowKey = interactionType .. "|" .. recordId .. "|" .. profileIdForKey
            if summary.seenKeys[rowKey] then
                noteDuplicate(summary, rowKey, sourceName)
            else
                summary.seenKeys[rowKey] = true
            end
            local base = profileBaseForRow(host, row, sourceName) or {}
            local profile = shallowCopy(base)
            profile.profileId = trim(row.profileid) ~= "" and trim(row.profileid) or recordId
            profile.interactionType = interactionType ~= "" and interactionType or profile.interactionType
            profile.externalProfile = true
            profile.isFallback = false
            profile.profileBedTypeFallback = nil
            profile.profileBedTypeFallbackCount = nil
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
                if name ~= "" and name ~= "recordid" and name ~= "matchid" and name ~= "base" and name ~= "notes" and name ~= "propfamily" and not skipSittingActivityColumn and trim(rawValue) ~= "" then
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

            host.profilesByRecordId[recordId] = profile
            loaded = loaded + 1
        else
            summary.skippedRows = (summary.skippedRows or 0) + 1
        end
    end

    summary[category] = (summary[category] or 0) + loaded
    return loaded
end

local function currentVfs()
    -- OpenMW's VFS API should be imported with require('openmw.vfs').
    -- The old global-vfs probe was unreliable and produced profileRows=0 in-game.
    if vfsPackage then return vfsPackage end

    -- Keep these only as last-ditch compatibility fallbacks for unusual builds.
    local ok, vfstable = pcall(function() return vfs end)
    if ok and vfstable then return vfstable end
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
    if name:find("chairprofilevariants", 1, true) or name:find("chairorientationprofiles", 1, true) then return 30 end
    if name:find("bedprofilevariants", 1, true) or name:find("bedorientationprofiles", 1, true) then return 40 end
    return 50
end

function module.loadProfileFiles(host, debugLog)
    local vfstable = currentVfs()
    module.lastLoadSummary = {
        bedRows = 0,
        chairRows = 0,
        bedVariantRows = 0,
        chairVariantRows = 0,
        otherRows = 0,
        malformedRows = 0,
        skippedRows = 0,
        duplicateKeys = {},
        loadedFiles = {},
        missingFiles = {},
        seenKeys = {},
    }
    local summary = module.lastLoadSummary
    if not (vfstable and vfstable.pathsWithPrefix and vfstable.open) then
        if debugLog then debugLog("profile tsv loader skipped", "vfs_unavailable") end
        return 0
    end

    local files = {}
    for filename in vfstable.pathsWithPrefix("sdp_furnitureProfiles/") do
        if filename:match("%.txt$") and not filename:match("/%._") and not lower(filename):find("animationnormalizationoffsets", 1, true) then
            files[#files + 1] = filename
            summary.loadedFiles[canonicalProfilePath(filename)] = false
        end
    end
    table.sort(files, function(a, b)
        local pa, pb = filePriority(a), filePriority(b)
        if pa ~= pb then return pa < pb end
        return tostring(a) < tostring(b)
    end)

    local total = 0
    for _, filename in ipairs(files) do
        local file = tryOpenVfs(filename)
        if file then
            local content = file:read("*all")
            file:close()
            local canonical = canonicalProfilePath(filename)
            local loaded = module.loadProfileRows(host, content, canonical)
            total = total + loaded
            summary.loadedFiles[canonical] = true
            if debugLog then debugLog("profile tsv loaded", canonical, tostring(loaded)) end
        end
    end
    for _, expected in ipairs({
        "sdp_furnitureProfiles/bedProfiles.txt",
        "sdp_furnitureProfiles/chairProfiles.txt",
        "sdp_furnitureProfiles/chairProfileVariants.txt",
        "sdp_furnitureProfiles/bedProfileVariants.txt",
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
