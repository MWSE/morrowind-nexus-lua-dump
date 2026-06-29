-- FurnitureProfileLoader.lua
-- Parses SDP-style furniture profile TSV files plus legacy ProceduralChatter TSVs.

local Loader = {}

local okVfs, vfs = pcall(require, "openmw.vfs")
if not okVfs then vfs = nil end

local function trim(s)
    if s == nil then return "" end
    return tostring(s):match("^%s*(.-)%s*$") or ""
end

local function splitTabs(line)
    local out = {}
    line = tostring(line or "")
    local start = 1
    while true do
        local tabAt = line:find("\t", start, true)
        if not tabAt then
            out[#out + 1] = trim(line:sub(start))
            break
        end
        out[#out + 1] = trim(line:sub(start, tabAt - 1))
        start = tabAt + 1
    end
    return out
end

local function splitPipes(line)
    local out = {}
    line = tostring(line or "")
    local start = 1
    while true do
        local at = line:find("|", start, true)
        if not at then
            out[#out + 1] = trim(line:sub(start))
            break
        end
        out[#out + 1] = trim(line:sub(start, at - 1))
        start = at + 1
    end
    return out
end

local function parseNumber(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    return tonumber(raw)
end

local function parseVec3(raw)
    raw = trim(raw)
    if raw == "" then return nil end
    local x, y, z = raw:match("^%s*([^,]+),%s*([^,]+),%s*([^,]+)%s*$")
    if not x then return nil end
    return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

local function parseFlags(raw)
    local flags = {}
    raw = trim(raw)
    if raw == "" then return flags end
    for token in raw:gmatch("[^,;|%s]+") do
        flags[string.lower(token)] = true
    end
    return flags
end

local function parseApproachOffsets(raw)
    local out = {}
    raw = trim(raw)
    if raw == "" then return out end
    for part in raw:gmatch("[^;]+") do
        local name, x, y, z = part:match("^%s*([^:]+):([^:]+):([^:]+):([^:]+)%s*$")
        if name then
            out[#out + 1] = {
                id = trim(name),
                offset = { x = tonumber(x) or 0, y = tonumber(y) or 0, z = tonumber(z) or 0 },
            }
        end
    end
    return out
end

local function forEachVfsLine(stream, onLine)
    local content = nil
    local okRead, readResult = pcall(function()
        if stream.read then
            return stream:read("*all")
        end
        return nil
    end)
    if okRead and readResult then
        content = tostring(readResult)
    end

    if content then
        for line in content:gmatch("[^\r\n]+") do
            onLine(line)
        end
    elseif stream.readline then
        while true do
            local okLine, line = pcall(stream.readline, stream)
            if not okLine or line == nil then break end
            onLine(line)
        end
    end
end

local function parseSlots(raw, interactionType, profile)
    local slots = {}
    raw = trim(raw)
    if raw == "" or raw == "default" then
        return {
            {
                slotId = raw ~= "" and raw or "default",
                interactionType = interactionType,
                profileId = profile.profileId,
                localOffset = {
                    x = interactionType == "sit" and (profile.width or 0) or (profile.finalRightOffset or 0),
                    y = interactionType == "sit" and (profile.depth or 0) or (profile.finalForwardOffset or 0),
                    z = interactionType == "sit" and (profile.height or 0) or (profile.finalZOffset or 0),
                },
                localFacingYaw = profile.yawOffset,
                flags = profile.flags or {},
            }
        }
    end

    for part in raw:gmatch("[^;]+") do
        local fields = splitPipes(part)
        if #fields >= 2 then
            local slotId = fields[1]
            local finalOffset, approachOffset, exitOffset, yaw

            if interactionType == "sleep" then
                -- Sleep slot format: name|sleepOffset|approachOffset|sleepRootLocalOffset|sleepLateralOffset
                local sleepOffset = parseVec3(fields[2])
                approachOffset = parseVec3(fields[3])
                local sleepRootLocal = parseVec3(fields[4])

                -- Combine sleepOffset + sleepRootLocalOffset for final local offset.
                if sleepRootLocal and sleepOffset then
                    finalOffset = {
                        x = sleepRootLocal.x + sleepOffset.x,
                        y = sleepRootLocal.y + sleepOffset.y,
                        z = sleepRootLocal.z + sleepOffset.z,
                    }
                elseif sleepRootLocal then
                    finalOffset = sleepRootLocal
                elseif sleepOffset then
                    finalOffset = sleepOffset
                else
                    finalOffset = {
                        x = profile.finalRightOffset or profile.sleepRootRightOffset or 0,
                        y = profile.finalForwardOffset or profile.sleepRootForwardOffset or 0,
                        z = profile.finalZOffset or 0,
                    }
                end

                -- yaw comes from profile SleepPoseYawDeg, NEVER from sleepLateralOffset (field 5)
                yaw = profile.yawOffset
            else
                -- Sit slot format: name|approach|exit|final|yaw
                approachOffset = parseVec3(fields[2])
                exitOffset = parseVec3(fields[3])
                finalOffset = parseVec3(fields[4]) or parseVec3(fields[2]) or {
                    x = profile.finalRightOffset or 0,
                    y = profile.finalForwardOffset or 0,
                    z = profile.finalZOffset or 0,
                }
                yaw = parseNumber(fields[5]) or profile.yawOffset
            end

            slots[#slots + 1] = {
                slotId = trim(slotId) ~= "" and trim(slotId) or ("slot_" .. tostring(#slots + 1)),
                interactionType = interactionType,
                profileId = profile.profileId,
                localOffset = finalOffset,
                localFacingYaw = yaw,
                approachOffset = approachOffset,
                exitOffset = exitOffset,
                flags = profile.flags or {},
            }
        else
            local id = trim(part)
            if id ~= "" then
                slots[#slots + 1] = {
                    slotId = id,
                    interactionType = interactionType,
                    profileId = profile.profileId,
                    localOffset = {
                        x = interactionType == "sit" and (profile.width or 0) or (profile.finalRightOffset or 0),
                        y = interactionType == "sit" and (profile.depth or 0) or (profile.finalForwardOffset or 0),
                        z = interactionType == "sit" and (profile.height or 0) or (profile.finalZOffset or 0),
                    },
                    localFacingYaw = profile.yawOffset,
                    usesSharedSeatAnchor = interactionType == "sit" and id ~= "default",
                    flags = profile.flags or {},
                }
            end
        end
    end
    return slots
end

local function readRows(path)
    local rows = {}
    local diagnostics = { lines = 0, loaded = 0, missing = false }
    if not vfs then
        diagnostics.missing = true
        return rows, diagnostics
    end
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then
        diagnostics.missing = true
        return rows, diagnostics
    end

    local header = nil
    local function consumeLine(line)
        diagnostics.lines = diagnostics.lines + 1
        line = trim(line)
        if line == "" or line:sub(1, 1) == "#" then return end
        local cols = splitTabs(line)
        if not header then
            header = {}
            for i, name in ipairs(cols) do
                header[name] = i
            end
            return
        end
        rows[#rows + 1] = { header = header, cols = cols }
        diagnostics.loaded = diagnostics.loaded + 1
    end

    forEachVfsLine(stream, consumeLine)
    pcall(function() stream:close() end)
    return rows, diagnostics
end

local function col(row, name)
    local idx = row.header[name]
    if not idx then return "" end
    return trim(row.cols[idx])
end

function Loader.loadChairProfiles(path)
    local rows, diag = readRows(path)
    local profiles = {}
    for _, row in ipairs(rows) do
        local recordId = string.lower(col(row, "RecordID"))
        local profile = {
            profileId = col(row, "ProfileID"),
            interactionType = "sit",
            source = "sdp",
            recordId = recordId,
            model = string.lower(col(row, "Model")),
            seatType = col(row, "SeatType"),
            width = parseNumber(col(row, "WidthOffset")),
            depth = parseNumber(col(row, "DepthOffset")),
            height = parseNumber(col(row, "HeightOffset")),
            rotationMode = col(row, "RotationMode"),
            yawOffset = parseNumber(col(row, "YawOffset")),
            finalForwardOffset = parseNumber(col(row, "FinalForwardOffset")),
            finalRightOffset = parseNumber(col(row, "WidthOffset")),
            finalZOffset = parseNumber(col(row, "FinalZOffset")),
            approachOffsets = parseApproachOffsets(col(row, "ApproachOffsets")),
            flags = parseFlags(col(row, "Flags")),
        }
        if profile.profileId == "" then profile.profileId = recordId end
        profile.slots = parseSlots(col(row, "Slots"), "sit", profile)
        profiles[#profiles + 1] = profile
    end
    return profiles, diag
end

function Loader.loadBedProfiles(path)
    local rows, diag = readRows(path)
    local profiles = {}
    for _, row in ipairs(rows) do
        local recordId = string.lower(col(row, "RecordID"))
        local root = parseVec3(col(row, "SleepRootLocalOffset")) or { x = 0, y = 0, z = 0 }
        local dedicatedZ = parseNumber(col(row, "SleepRootZOffset"))
        local grid = parseVec3(col(row, "SleepSurfaceGrid"))
        local profile = {
            profileId = col(row, "ProfileID"),
            interactionType = "sleep",
            source = "sdp",
            recordId = recordId,
            model = string.lower(col(row, "Model")),
            bedType = col(row, "BedType"),
            rotationMode = "object",
            yawOffset = parseNumber(col(row, "SleepPoseYawDeg")),
            finalForwardOffset = root.y,
            finalRightOffset = root.x,
            finalZOffset = root.z,
            sleepRootForwardOffset = root.y,
            sleepRootRightOffset = root.x,
            sleepRootZOffset = dedicatedZ,
            surfaceSampleWidth = grid and grid.x or nil,
            surfaceSampleDepth = grid and grid.y or nil,
            surfaceMinZ = parseNumber(col(row, "SleepSurfaceMinHeight")),
            surfaceMaxZ = parseNumber(col(row, "SleepSurfaceMaxHeight")),
            flags = parseFlags(col(row, "Flags")),
        }
        if profile.profileId == "" then profile.profileId = recordId end
        profile.slots = parseSlots(col(row, "Slots"), "sleep", profile)
        if #profile.slots == 0 then
            profile.slots = parseSlots("sleep_main", "sleep", profile)
        end
        profiles[#profiles + 1] = profile
    end
    return profiles, diag
end

local function loadVariants(path, interactionType)
    local rows, diag = readRows(path)
    local variants = {}
    for _, row in ipairs(rows) do
        variants[#variants + 1] = {
            interactionType = interactionType,
            recordId = string.lower(col(row, "RecordID")),
            model = string.lower(col(row, "Model")),
            profileId = col(row, "ProfileID"),
            slotId = col(row, "SlotName"),
            yawBucket90 = parseNumber(col(row, "YawBucket90")),
            yawMinDeg = parseNumber(col(row, "YawMinDeg")),
            yawMaxDeg = parseNumber(col(row, "YawMaxDeg")),
            finalRightOffset = parseNumber(col(row, "WidthOffset")),
            finalForwardOffset = parseNumber(col(row, "DepthOffset")),
            finalZOffset = parseNumber(col(row, "HeightOffset")),
            yawOffset = parseNumber(col(row, "YawOffset")) or parseNumber(col(row, "SleepPoseYawDeg")),
            sleepRootLocalOffset = parseVec3(col(row, "SleepRootLocalOffset")),
            objectX = parseNumber(col(row, "ObjectX")),
            objectY = parseNumber(col(row, "ObjectY")),
            objectZ = parseNumber(col(row, "ObjectZ")),
        }
    end
    return variants, diag
end

function Loader.loadChairVariants(path)
    return loadVariants(path, "sit")
end

function Loader.loadBedVariants(path)
    return loadVariants(path, "sleep")
end

function Loader.loadAnimationOffsets(path)
    local rows, diag = readRows(path)
    local offsets = {}
    for _, row in ipairs(rows) do
        offsets[#offsets + 1] = {
            interactionType = col(row, "InteractionType"),
            animationId = string.lower(col(row, "Animation")),
            recordId = string.lower(col(row, "RecordID")),
            model = string.lower(col(row, "Model")),
            profileId = col(row, "ProfileID"),
            slotId = col(row, "SlotName"),
            yawBucket90 = parseNumber(col(row, "YawBucket90")),
            finalRightOffset = parseNumber(col(row, "WidthOffset")),
            finalForwardOffset = parseNumber(col(row, "DepthOffset")),
            finalZOffset = parseNumber(col(row, "HeightOffset")),
            yawOffset = parseNumber(col(row, "YawOffset")),
            yawMinDeg = parseNumber(col(row, "YawMinDeg")),
            yawMaxDeg = parseNumber(col(row, "YawMaxDeg")),
        }
    end
    return offsets, diag
end

function Loader.loadObjectList(path)
    local records, models = {}, {}
    local diag = { missing = false, loaded = 0, lines = 0 }
    if not vfs then
        diag.missing = true
        return records, models, diag
    end
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then
        diag.missing = true
        return records, models, diag
    end
    forEachVfsLine(stream, function(line)
        diag.lines = diag.lines + 1
        line = trim(line)
        if line == "" or line:sub(1, 1) == "#" then return end
        local cols = splitTabs(line)
        local recordId = string.lower(trim(cols[1]))
        local model = string.lower(trim(cols[2]))
        if recordId ~= "" then records[recordId] = true end
        if model ~= "" then models[model] = true end
        if recordId ~= "" or model ~= "" then diag.loaded = diag.loaded + 1 end
    end)
    pcall(function() stream:close() end)
    return records, models, diag
end

function Loader.loadLegacyProfiles(path, interactionType)
    local result = {}
    if not vfs then return result, { missing = true, loaded = 0, lines = 0 } end
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then return result, { missing = true, loaded = 0, lines = 0 } end
    local diag = { missing = false, loaded = 0, lines = 0 }
    forEachVfsLine(stream, function(line)
        diag.lines = diag.lines + 1
        line = trim(line)
        if line == "" or line:sub(1, 1) == "#" then return end
        local cols = splitTabs(line)
        local recordId = string.lower(trim(cols[1]))
        if recordId == "" then return end
        local z = parseNumber(cols[2]) or 0
        local x = parseNumber(cols[3]) or 0
        local y = parseNumber(cols[4]) or 0
        result[#result + 1] = {
            profileId = "legacy:" .. recordId,
            interactionType = interactionType,
            source = "legacy",
            recordId = recordId,
            finalRightOffset = x,
            finalForwardOffset = y,
            finalZOffset = z,
            yawOffset = nil,
            flags = {},
            slots = {
                {
                    slotId = "legacy_" .. tostring(#result + 1),
                    interactionType = interactionType,
                    profileId = "legacy:" .. recordId,
                    localOffset = { x = x, y = y, z = z },
                    flags = {},
                }
            },
        }
        diag.loaded = diag.loaded + 1
    end)
    pcall(function() stream:close() end)
    return result, diag
end

return Loader
