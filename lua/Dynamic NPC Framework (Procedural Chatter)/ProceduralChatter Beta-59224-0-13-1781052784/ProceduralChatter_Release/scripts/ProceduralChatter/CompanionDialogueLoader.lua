-- CompanionDialogueLoader.lua
-- Runtime loader for companion dialogue JSON files under data/CompanionDialogue/.
-- Requires FollowerDetectionUtil (FDU) for live follower detection.

local vfs = require("openmw.vfs")
local storage = require("openmw.storage")
local json = require("scripts.ProceduralChatter.lib.json")

local CompanionDialogueLoader = {}

local DIALOGUE_PREFIXES = {
    "scripts/ProceduralChatter/data/CompanionDialogue/",
    "Scripts/ProceduralChatter/Data/CompanionDialogue/",
    "scripts/ProceduralChatter/Data/CompanionDialogue/",
    "Scripts/ProceduralChatter/data/CompanionDialogue/",
    "scripts/proceduralchatter/data/companiondialogue/",
    "scripts/data/companiondialogue/",
    "Scripts/Data/CompanionDialogue/",
    "scripts/",
    "Scripts/",
}

local loaded = false
local declaredCompanions = {}   -- recordId (lower) -> true
local entriesByCompanion = {}   -- recordId (lower) -> { entry, ... }
local allEntries = {}           -- flat list of all entries

local okDeclaredStore, declaredStore = pcall(function()
    return storage.globalSection("PC_CompanionDialogueDeclared")
end)
if not okDeclaredStore then
    declaredStore = nil
end

local function normalizeId(id)
    if not id then return "" end
    return string.lower(tostring(id):match("^%s*(.-)%s*$") or "")
end

local function readVfsFile(path)
    local ok, stream = pcall(vfs.open, path)
    if not ok or not stream then return nil end
    local chunks = {}
    local readOk, err = pcall(function()
        for line in stream:lines() do
            chunks[#chunks + 1] = line .. "\n"
        end
    end)
    pcall(function() stream:close() end)
    if not readOk then return nil end
    return table.concat(chunks)
end

local function isCompanionDialogueJson(path)
    if type(path) ~= "string" then return false end
    local lower = string.lower(path)
    if not lower:match("%.json$") then return false end
    return lower:find("/data/companiondialogue/", 1, true) ~= nil
        or lower:find("\\data\\companiondialogue\\", 1, true) ~= nil
end

local function getStoredDeclaredCompanions()
    if not declaredStore then return nil end
    local stored = declaredStore:get("ids")
    if type(stored) ~= "table" then return nil end
    return stored
end

local function persistDeclaredCompanions()
    if declaredStore then
        pcall(function()
            declaredStore:set("ids", declaredCompanions)
        end)
    end
end

local function indexEntry(companionId, entry)
    if not companionId or companionId == "" or type(entry) ~= "table" then return end
    if not entry.id or entry.id == "" then
        print(string.format("[CompanionDialogueLoader] SKIP entry missing id in file for '%s'", companionId))
        return
    end
    entry.repeatable = entry.repeatable ~= false -- default true

    if not entriesByCompanion[companionId] then
        entriesByCompanion[companionId] = {}
    end
    table.insert(entriesByCompanion[companionId], entry)
end

local function addEntry(entry, primaryId)
    if type(entry) ~= "table" or not entry.id or entry.id == "" then return end

    local seen = {}
    local entryCompanions = {}

    -- Per-entry companion override
    if entry.companion then
        local cid = normalizeId(entry.companion)
        if cid ~= "" then
            entryCompanions[#entryCompanions + 1] = cid
            seen[cid] = true
        end
    end

    -- Participants (banter entries list every speaker here)
    if type(entry.participants) == "table" then
        for _, pid in ipairs(entry.participants) do
            local normPid = normalizeId(pid)
            if normPid ~= "" and not seen[normPid] then
                entryCompanions[#entryCompanions + 1] = normPid
                seen[normPid] = true
            end
        end
    end

    -- Fallback to file primary
    if #entryCompanions == 0 then
        entryCompanions[1] = primaryId
    end

    -- companionId used by playback routing (first declared companion)
    if not entry.companionId or entry.companionId == "" then
        entry.companionId = entryCompanions[1]
    end

    -- Index under each companion so any of them can trigger it
    for _, cid in ipairs(entryCompanions) do
        indexEntry(cid, entry)
    end

    table.insert(allEntries, entry)
end

--- Parse a comma-separated companion string into a list of normalized IDs.
--- The first ID is treated as the primary (file owner) for entry attribution.
local function parseCompanionField(raw)
    local prim = normalizeId(raw)
    if prim == "" then return {}, nil end

    local ids = {}
    local primary = nil
    for token in string.gmatch(raw, "([^,]+)") do
        local id = normalizeId(token)
        if id ~= "" then
            table.insert(ids, id)
            if not primary then primary = id end
        end
    end
    return ids, primary
end

local function loadFile(path)
    local text = readVfsFile(path)
    if not text or text == "" then
        print(string.format("[CompanionDialogueLoader] WARNING: empty or unreadable file '%s'", path))
        return
    end

    local ok, data = pcall(json.decode, text)
    if not ok or type(data) ~= "table" then
        print(string.format("[CompanionDialogueLoader] WARNING: failed to parse '%s': %s", path, tostring(data)))
        return
    end

    local companionIds, primaryId = parseCompanionField(data.companion)
    if not primaryId then
        print(string.format("[CompanionDialogueLoader] WARNING: file '%s' missing companion field", path))
        return
    end

    for _, id in ipairs(companionIds) do
        declaredCompanions[id] = true
    end

    local totalIndexed = 0
    if type(data.entries) == "table" then
        for _, entry in ipairs(data.entries) do
            addEntry(entry, primaryId)
            totalIndexed = totalIndexed + 1
        end
    end

    print(string.format("[CompanionDialogueLoader] Loaded '%s' from %s (%d entries, declared: %s)",
        primaryId, path, totalIndexed,
        table.concat(companionIds, ", ")))
end

function CompanionDialogueLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    if not (vfs and vfs.pathsWithPrefix) then
        print("[CompanionDialogueLoader] WARNING: vfs.pathsWithPrefix unavailable")
        return
    end

    local count = 0
    local seenPaths = {}
    for _, prefix in ipairs(DIALOGUE_PREFIXES) do
        for path in vfs.pathsWithPrefix(prefix) do
            local key = string.lower(path)
            if isCompanionDialogueJson(path) and not seenPaths[key] then
                seenPaths[key] = true
                loadFile(path)
                count = count + 1
            end
        end
    end

    print(string.format("[CompanionDialogueLoader] Scan complete: %d json file(s), %d total entries, %d declared companions",
        count, #allEntries, CompanionDialogueLoader.getDeclaredCount()))
    persistDeclaredCompanions()
end

function CompanionDialogueLoader.reload()
    loaded = false
    declaredCompanions = {}
    entriesByCompanion = {}
    allEntries = {}
    CompanionDialogueLoader.ensureLoaded()
end

function CompanionDialogueLoader.isDeclaredCompanion(recordId)
    CompanionDialogueLoader.ensureLoaded()
    return declaredCompanions[normalizeId(recordId)] == true
end

--- Cheap declared-companion lookup for non-player scripts.
--- This intentionally does not load dialogue entries, because Blacklist checks can run
--- in every NPC script context and would otherwise parse all companion JSON per actor.
function CompanionDialogueLoader.isDeclaredCompanionCached(recordId)
    local norm = normalizeId(recordId)
    if norm == "" then return false end
    if declaredCompanions[norm] == true then return true end

    local stored = getStoredDeclaredCompanions()
    return stored and stored[norm] == true or false
end

function CompanionDialogueLoader.clearDeclaredCache()
    loaded = false
    declaredCompanions = {}
    entriesByCompanion = {}
    allEntries = {}
    if declaredStore then
        pcall(function()
            declaredStore:set("ids", {})
        end)
    end
end

local function getFollowerList()
    local ok, list = pcall(function()
        local I = require("openmw.interfaces")
        if not I.FollowerDetectionUtil then return nil end
        return I.FollowerDetectionUtil.getFollowerList()
    end)
    if not ok or type(list) ~= "table" then return nil end
    return list
end

local function getActorIds(actorOrId)
    if not actorOrId then return nil, "" end
    if type(actorOrId) == "string" then
        return actorOrId, normalizeId(actorOrId)
    end

    local okId, actorId = pcall(function() return actorOrId.id end)
    local okRecordId, recordId = pcall(function() return actorOrId.recordId end)
    return okId and actorId or nil, okRecordId and normalizeId(recordId) or ""
end

--- Returns true if the given actor is currently an active follower of the player.
--- FDU indexes followers by actor.id, so callers should pass the live actor object
--- whenever possible. Record-ID matching is kept only as a fallback for dialogue
--- data that refers to companions by record ID.
function CompanionDialogueLoader.isLiveFollower(actorOrId)
    local actorId, recordId = getActorIds(actorOrId)
    if not actorId and recordId == "" then return false end

    local list = getFollowerList()
    if not list then return false end

    local state = actorId and list[actorId] or nil
    if state and state.followsPlayer == true then
        return true
    end

    if recordId == "" then return false end
    for _, candidate in pairs(list) do
        if candidate and candidate.followsPlayer == true and candidate.actor then
            local okRecordId, candidateRecordId = pcall(function()
                return candidate.actor.recordId
            end)
            if okRecordId and normalizeId(candidateRecordId) == recordId then
                return true
            end
        end
    end
    return false
end

function CompanionDialogueLoader.getDeclaredCount()
    local n = 0
    for _ in pairs(declaredCompanions) do n = n + 1 end
    return n
end

function CompanionDialogueLoader.getEntriesForCompanion(recordId)
    CompanionDialogueLoader.ensureLoaded()
    return entriesByCompanion[normalizeId(recordId)] or {}
end

function CompanionDialogueLoader.getAllEntries()
    CompanionDialogueLoader.ensureLoaded()
    return allEntries
end

function CompanionDialogueLoader.getDeclaredCompanions()
    CompanionDialogueLoader.ensureLoaded()
    local list = {}
    for id in pairs(declaredCompanions) do
        table.insert(list, id)
    end
    return list
end

return CompanionDialogueLoader
