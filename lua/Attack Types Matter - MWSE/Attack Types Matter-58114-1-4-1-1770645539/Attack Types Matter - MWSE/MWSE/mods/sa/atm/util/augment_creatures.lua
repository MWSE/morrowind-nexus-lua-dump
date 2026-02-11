--
-- CSV remains headerless. Base 6 columns stay the same:
--  1 id, 2 slash, 3 pierce, 4 blunt, 5 materialType, 6 bonus
-- Extra appended columns (always populated, never empty):
--  7 mesh_sig
--  8 slash_conf, 9 pierce_conf, 10 blunt_conf, 11 mat_conf, 12 bonus_conf
--  13 needs_review
--  14 inferred_from
--  15 inferred_key

local M = {}

local log = mwse.Logger.new()
local lfs = require("lfs")
local util = require("sa.atm.util")

local csvloader = require("sa.atm.util.csvloader")
local interop   = require("sa.atm.interop")

-- -------------------------
-- Paths (same idea as csvloader)
-- -------------------------
local function getScriptDirAbsolute()
    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    local dir = source:match("(.+[/\\])")
    if not dir then
        return lfs.currentdir() .. "/"
    end
    if dir:sub(1, 1) == "." then
        local cwd = lfs.currentdir()
        if cwd:sub(-1) ~= "/" then cwd = cwd .. "/" end
        dir = cwd .. dir:sub(2)
    end
    dir = dir:gsub("[/\\]+", "/")
    return dir
end

local MOD_DIR  = getScriptDirAbsolute() .. "../"
local CSV_PATH = MOD_DIR .. "creatures.csv"

-- -------------------------
-- CSV parsing/writing
-- Note: your csvloader.parseLine uses ([^,]+), so we must never output empty fields.
-- -------------------------
local function parseLine(line)
    local fields = {}
    for field in line:gmatch("([^,]+)") do
        fields[#fields + 1] = field:match("^%s*(.-)%s*$")
    end
    return fields
end

local function readCreaturesCsv(path)
    local file = io.open(path, "r")
    if not file then
        log:error("Could not open CSV for reading: %s", path)
        return {}
    end

    local rows = {} -- idLower -> fields[]
    for line in file:lines() do
        if line:match("%S") then
            local fields = parseLine(line)
            if #fields >= 6 then
                local id = fields[1] and fields[1]:lower()
                if id and id ~= "" then
                    rows[id] = fields
                end
            end
        end
    end
    file:close()
    return rows
end

local function writeCreaturesCsv(path, orderedIds, rows)
    local file = io.open(path, "w")
    if not file then
        log:error("Could not open CSV for writing: %s", path)
        return false
    end

    for i = 1, #orderedIds do
        local id = orderedIds[i]
        local row = rows[id]
        if row then
            file:write(table.concat(row, ","))
            file:write("\n")
        end
    end

    file:close()
    return true
end

local function backupCsv(path)
    local ts = os.date("%Y%m%d-%H%M%S")
    local bak = path .. ".bak-" .. ts
    local src = io.open(path, "r")
    if not src then return nil end
    local dst = io.open(bak, "w")
    if not dst then src:close(); return nil end
    dst:write(src:read("*a"))
    src:close()
    dst:close()
    return bak
end

-- Ensure extra columns exist and are never empty.
local function ensureExtras(fields, meshSig, cS, cP, cB, cM, cX, needsReview, inferredFrom, inferredKey)
    fields[7]  = (meshSig and meshSig ~= "" and meshSig) or (fields[7] or "none")

    fields[8]  = cS ~= nil and string.format("%.3f", cS) or (fields[8] or "0.000")
    fields[9]  = cP ~= nil and string.format("%.3f", cP) or (fields[9] or "0.000")
    fields[10] = cB ~= nil and string.format("%.3f", cB) or (fields[10] or "0.000")
    fields[11] = cM ~= nil and string.format("%.3f", cM) or (fields[11] or "0.000")
    fields[12] = cX ~= nil and string.format("%.3f", cX) or (fields[12] or "0.000")

    fields[13] = needsReview ~= nil and tostring(needsReview) or (fields[13] or "1")
    fields[14] = (inferredFrom and inferredFrom ~= "" and inferredFrom) or (fields[14] or "default")
    fields[15] = (inferredKey and inferredKey ~= "" and inferredKey) or (fields[15] or "none")
    return fields
end

-- -------------------------
-- Mesh keys
-- -------------------------
local function extractStem(path)
    if not path or path == "" then return "none" end
    path = path:gsub("[%s%c]+$", "")
    -- Extract filename (after last slash or backslash)
    local filename = path:match("([^\\/]+)$") or path
    filename = filename:lower()
    -- Remove .nif extension (case-insensitive), but allow for missing extension
    local stem = filename:match("^(.*)%.nif$") or filename
    -- If stem is empty, fall back to filename, and only return 'none' if that is also empty
    if not stem or stem == "" then
        if filename and filename ~= "" then
            return filename
        else
            return "none"
        end
    end
    return stem
end

local function normalizeStem(stem)
    if not stem or stem == "" then return "" end
    stem = stem:lower()

    -- Remove a single trailing group like _01, -02, or space+number, but not numbers in the middle
    stem = stem:gsub("([_%-%s]%d+)$", "")

    -- Remove common suffix tokens only if separated by _ or - or space
    stem = stem:gsub("([_%-%s])(unique|variant|alt|test|copy)$", "")
    stem = stem:gsub("([_%-%s])(m|f)$", "")

    -- Normalize separators: replace spaces and dashes with underscores, collapse multiple underscores
    stem = stem:gsub("[%s%-]+", "_")
    stem = stem:gsub("__+", "_")

    -- Trim trailing separators
    stem = stem:gsub("[_%-%s]+$", "")

    return stem
end

-- Extract tags from a stem, splitting on underscores and spaces, only tags with 3 or more letters
local function extractTags(stem)
    if not stem or stem == "" then return {} end
    local tags = {}
    -- Replace underscores with spaces, then split on spaces
    local normalized = stem:gsub("_", " ")
    for tag in normalized:gmatch("%S+") do
        if #tag >= 3 then
            tags[#tags + 1] = tag
        end
    end
    return tags
end

local function buildIdToMeshKeys()
    local objects = tes3.dataHandler.nonDynamicData.objects
    local idTo = {}

    for _, object in pairs(objects) do
        if object.objectType == tes3.objectType.creature then
            local id = object.id:lower()
            local stem = extractStem(object.mesh)
            local normstem = normalizeStem(stem)
            local tags = extractTags(normstem)
            idTo[id] = {
                stem = stem,
                normstem = normstem,
                tags = tags,
            }
        end
    end

    return idTo
end

-- -------------------------
-- Quantized mode utilities (0..2 in steps of 0.25)
-- -------------------------
local STEP, MINV, MAXV = 0.25, 0.0, 2.0
local MAXBIN = math.floor((MAXV / STEP) + 0.5) -- 8

local function to_bin(x)
    if x == nil then return nil end
    if x < MINV then x = MINV end
    if x > MAXV then x = MAXV end
    local bin = math.floor((x / STEP) + 0.5)
    if bin < 0 then bin = 0 end
    if bin > MAXBIN then bin = MAXBIN end
    return bin
end

local function from_bin(bin) return bin * STEP end

-- tie_break: "neutral" (closest to 1.0), "high", "low"
local function mode_quantized(values, tie_break)
    local counts = {}
    local total, maxCount = 0, 0

    for i = 1, #values do
        local v = values[i]
        if v ~= nil then
            local bin = to_bin(v)
            if bin ~= nil then
                total = total + 1
                local c = (counts[bin] or 0) + 1
                counts[bin] = c
                if c > maxCount then maxCount = c end
            end
        end
    end

    if total == 0 then return nil, 0, 0 end

    local tied = {}
    for bin, c in pairs(counts) do
        if c == maxCount then tied[#tied + 1] = bin end
    end

    local bestBin = tied[1]
    if #tied > 1 then
        if tie_break == "high" then
            for i = 2, #tied do if tied[i] > bestBin then bestBin = tied[i] end end
        elseif tie_break == "low" then
            for i = 2, #tied do if tied[i] < bestBin then bestBin = tied[i] end end
        else
            local target = to_bin(1.0) -- 4
            local bestDist = math.abs(bestBin - target)
            for i = 2, #tied do
                local b = tied[i]
                local d = math.abs(b - target)
                if d < bestDist then
                    bestDist, bestBin = d, b
                elseif d == bestDist and b > bestBin then
                    bestBin = b
                end
            end
        end
    end

    return from_bin(bestBin), (maxCount / total), total
end

local function mode_int(values)
    local counts = {}
    local total, maxCount = 0, 0
    local best = nil

    for i = 1, #values do
        local v = values[i]
        if v ~= nil then
            v = math.floor(v + 0.5)
            total = total + 1
            local c = (counts[v] or 0) + 1
            counts[v] = c
            if c > maxCount then
                maxCount, best = c, v
            end
        end
    end

    if total == 0 then return nil, 0, 0 end
    return best, (maxCount / total), total
end

local function computeAggregate(samples)
    local out = {}

    out.slash,  out.slash_conf,  out.slash_n  = mode_quantized(samples.slash,  "neutral")
    out.pierce, out.pierce_conf, out.pierce_n = mode_quantized(samples.pierce, "neutral")
    out.blunt,  out.blunt_conf,  out.blunt_n  = mode_quantized(samples.blunt,  "neutral")
    out.mat,    out.mat_conf,    out.mat_n    = mode_int(samples.mat)
    out.bonus,  out.bonus_conf,  out.bonus_n  = mode_quantized(samples.bonus, "neutral")

    return out
end

local function pushSamples(map, key, fields)
    if not key or key == "" then return end

    local s = map[key]
    if not s then
        s = { slash={}, pierce={}, blunt={}, mat={}, bonus={} }
        map[key] = s
    end

    local slash  = tonumber(fields[2])
    local pierce = tonumber(fields[3])
    local blunt  = tonumber(fields[4])
    local mat    = tonumber(fields[5])
    local bonus  = tonumber(fields[6])

    if slash  then s.slash[#s.slash+1] = slash end
    if pierce then s.pierce[#s.pierce+1] = pierce end
    if blunt  then s.blunt[#s.blunt+1] = blunt end
    if mat    then s.mat[#s.mat+1] = mat end
    if bonus  then s.bonus[#s.bonus+1] = bonus end
end

local function buildAggregates(existingRows, idToKeys)
    -- We only keep what the 3-pass logic needs:
    --  PASS 1: exact stem match
    --  PASS 2: tag match (larger tags first)
    local samplesStem, samplesTags = {}, {}

    for id, fields in pairs(existingRows) do
        local keys = idToKeys[id]
        if keys then
            pushSamples(samplesStem, keys.stem, fields)

            if keys.tags then
                for _, tag in ipairs(keys.tags) do
                    pushSamples(samplesTags, tag, fields)
                end
            end
        end
    end

    local function buildAgg(samplesMap)
        local agg = {}
        for key, samples in pairs(samplesMap) do
            agg[key] = computeAggregate(samples)
        end
        return agg
    end

    return buildAgg(samplesStem), buildAgg(samplesTags)
end

local function sortTagsBySpecificity(tags)
    if not tags or #tags == 0 then return tags end
    -- sort in-place by descending length, then lexicographically for determinism
    table.sort(tags, function(a, b)
        if #a ~= #b then return #a > #b end
        return a < b
    end)
    return tags
end

-- 3-pass inference:
--  1) exact stem match -> NOT for review
--  2) tag match (larger tags first) -> review
--  3) default -> review
local function pickAgg(keys, aggStem, aggTags)
    -- PASS 1: exact nif/stem match
    if keys.stem ~= "" and aggStem[keys.stem] then
        return aggStem[keys.stem], "stem", keys.stem
    end

    -- PASS 2: tag match (favor longer tags first)
    if keys.tags and aggTags then
        sortTagsBySpecificity(keys.tags)
        for _, tag in ipairs(keys.tags) do
            if aggTags[tag] then
                return aggTags[tag], "tag", tag
            end
        end
    end

    -- PASS 3: fallback
    return nil, "default", "none"
end
-- (group needs_review by inferred_from + inferred_key)
-- -------------------------
local function buildReviewGroups(rows)
    local groups = {} -- key -> {count=, examples={}, inferred_from=, inferred_key=}
    for id, fields in pairs(rows) do
        local needs = tonumber(fields[13]) or 0
        if needs == 1 then
            local inferredFrom = fields[14] or "unknown"
            local inferredKey  = fields[15] or "none"
            local k = inferredFrom .. " | " .. inferredKey

            local g = groups[k]
            if not g then
                g = { count = 0, examples = {}, inferred_from = inferredFrom, inferred_key = inferredKey }
                groups[k] = g
            end
            g.count = g.count + 1
            if #g.examples < 6 then
                g.examples[#g.examples + 1] = id
            end
        end
    end
    return groups
end

local function sortedGroups(groups)
    local list = {}
    for k, g in pairs(groups) do
        list[#list + 1] = { key = k, count = g.count, examples = g.examples, inferred_from = g.inferred_from, inferred_key = g.inferred_key }
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.key < b.key
    end)
    return list
end

-- -------------------------
-- Public: augment CSV + refresh runtime
-- -------------------------
function M.run()
    if not tes3.dataHandler or not tes3.dataHandler.nonDynamicData then
        log:error("DataHandler not ready; run after initialized.")
        return false, "DataHandler not ready."
    end

    local existing = readCreaturesCsv(CSV_PATH)
    local idToKeys = buildIdToMeshKeys()

    local bak = backupCsv(CSV_PATH)
    if bak then log:info("Backed up creatures.csv to: %s", bak) end

    -- Ensure extras for existing rows (keep their existing extra cols if already present)
    for id, fields in pairs(existing) do
        local keys = idToKeys[id] or { stem="none", normstem="", tags={} }

        local meshSig = (fields[7] and fields[7] ~= "none" and fields[7]) or keys.stem

        local cS = tonumber(fields[8])  or 1.0
        local cP = tonumber(fields[9])  or 1.0
        local cB = tonumber(fields[10]) or 1.0
        local cM = tonumber(fields[11]) or 1.0
        local cX = tonumber(fields[12]) or 1.0

        local needs = tonumber(fields[13]) or 0
        local from  = fields[14] or "manual"
        local key   = fields[15] or "id"

        ensureExtras(fields, meshSig, cS, cP, cB, cM, cX, needs, from, key)
    end

    local aggStem, aggTags = buildAggregates(existing, idToKeys)
    local objects = tes3.dataHandler.nonDynamicData.objects
    local addedCount, reviewedCount = 0, 0

    for _, object in pairs(objects) do
        if object.objectType == tes3.objectType.creature then
            local idLower = object.id:lower()
            if not existing[idLower] then
                local keys = idToKeys[idLower] or { sig="", stem="", normstem="", tags={} }
                local agg, inferredFrom, inferredKey = pickAgg(keys, aggStem, aggTags)

                -- Defaults (hard fallback)
                local slash, pierce, blunt = 1.0, 1.0, 1.0
                local matType, bonus = 0, 0.0
                local cS, cP, cB, cM, cX = 0, 0, 0, 0, 0

                if agg then
                    slash   = agg.slash  or slash
                    pierce  = agg.pierce or pierce
                    blunt   = agg.blunt  or blunt
                    matType = agg.mat    or matType
                    bonus   = agg.bonus  or bonus

                    cS = agg.slash_conf  or 0
                    cP = agg.pierce_conf or 0
                    cB = agg.blunt_conf  or 0
                    cM = agg.mat_conf    or 0
                    cX = agg.bonus_conf  or 0
                end

-- Review policy:
--  stem   -> not for review
--  tag    -> for review
--  default-> for review
local needsReview = (inferredFrom ~= "stem") and 1 or 0
if needsReview == 1 then
    reviewedCount = reviewedCount + 1
end

local fields = {
    object.id,
    string.format("%.2f", slash),
    string.format("%.2f", pierce),
    string.format("%.2f", blunt),
    tostring(math.floor(matType + 0.5)),
    string.format("%.2f", bonus),
}
                ensureExtras(fields, keys.sig, cS, cP, cB, cM, cX, needsReview, inferredFrom, inferredKey)
                existing[idLower] = fields
                addedCount = addedCount + 1
            end
        end
    end

    local ordered = {}
    for id in pairs(existing) do ordered[#ordered+1] = id end
    table.sort(ordered)

    local ok = writeCreaturesCsv(CSV_PATH, ordered, existing)
    if not ok then
        return false, "Failed to write creatures.csv"
    end

    -- Refresh runtime (in place)
    local newData = csvloader.load("creatures.csv") or {}
    util.replaceTableInPlace(interop.creatures, newData)

    log:info("Augmented creatures.csv: added %d new creatures (%d flagged for review). Total rows: %d",
        addedCount, reviewedCount, #ordered)

    return true, string.format("Added %d creatures (%d need review).", addedCount, reviewedCount)
end

-- -------------------------
-- Public: report review groups (reads current CSV on disk)
-- -------------------------
function M.report(limit)
    limit = limit or 50

    local rows = readCreaturesCsv(CSV_PATH)
    local groups = buildReviewGroups(rows)
    local list = sortedGroups(groups)

    log:info("ATM review report: %d groups (showing top %d)", #list, math.min(limit, #list))
    for i = 1, math.min(limit, #list) do
        local g = list[i]
        log:info("%4d  %s  ex: %s", g.count, g.key, table.concat(g.examples, ", "))
    end

    return true, string.format("Logged top %d review groups to MWSE.log.", math.min(limit, #list))
end

return M