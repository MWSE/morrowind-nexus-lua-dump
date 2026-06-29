-- GeneratedScheduleManager.lua
-- Persistent generated schedule layer. Static ScheduleData.lua remains first
-- priority; this manager only fills gaps for newly observed eligible NPCs.

local core = require("openmw.core")
local storage = require("openmw.storage")
local types = require("openmw.types")

local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local Config = require("scripts.ProceduralChatter.data.ScheduleGenerationConfig")
local json = require("scripts.ProceduralChatter.lib.json")
local BakedScheduleLoader = require("scripts.ProceduralChatter.BakedScheduleLoader")
local Collector = require("scripts.ProceduralChatter.schedule.ScheduleDestinationCollector")
local Generator = require("scripts.ProceduralChatter.schedule.ScheduleGenerator")
local Ledger = require("scripts.ProceduralChatter.schedule.ScheduleOccupancyLedger")

local Manager = {}

local STORE_KEY = "root"
local SCHEDULE_KEY_PREFIX = "schedule:"
local SCHEDULE_INDEX_KEY = "scheduleIndex"
local store = storage.globalSection("PC_GeneratedSchedules")

local root = nil
local generatedByRecord = nil
local staticLedger = nil

local function isUsableGeneratedEntry(entry)
    if not entry or not entry.schedule then return false end
    if Config.REQUIRE_BASE_EXTERIOR then
        local baseExterior = entry.baseExterior or entry.schedule.BaseExterior or ""
        return baseExterior ~= ""
    end
    return true
end

local function rebuildGeneratedLedger()
    if not root then return end
    root.occupancyLedger = {}
    for _, entry in pairs(root.schedules or {}) do
        if isUsableGeneratedEntry(entry) and entry.meta and entry.meta.reservations then
            Ledger.applyReservations(root.occupancyLedger, entry.meta.reservations)
        end
    end
end

local function pruneInteriorNativeSchedules()
    if not root or not Config.REQUIRE_BASE_EXTERIOR or root.prunedInteriorNativeV1 then return end
    local removed = 0
    for key, entry in pairs(root.schedules or {}) do
        if not isUsableGeneratedEntry(entry) then
            root.schedules[key] = nil
            root.rejections[key] = {
                recordId = entry and entry.recordId or key,
                reason = "interior_native",
                generationVersion = Config.GENERATION_VERSION,
                gameDay = 0,
            }
            removed = removed + 1
        end
    end
    if removed > 0 then
        rebuildGeneratedLedger()
        print(string.format("[GeneratedScheduleManager] pruned %d interior-native generated schedules", removed))
    end
    root.prunedInteriorNativeV1 = true
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do count = count + 1 end
    return count
end

local sanitizeForStorage

local function jsonEscape(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub("\"", "\\\"")
    value = value:gsub("\b", "\\b")
    value = value:gsub("\f", "\\f")
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "\\r")
    value = value:gsub("\t", "\\t")
    return "\"" .. value .. "\""
end

local jsonEncodeValue

local function isArrayTable(value)
    if type(value) ~= "table" then return false end
    local maxIndex = 0
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end
        if key > maxIndex then maxIndex = key end
        count = count + 1
    end
    return count == maxIndex
end

local function sortedStringKeys(value)
    local keys = {}
    for key in pairs(value or {}) do
        if type(key) == "string" or type(key) == "number" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

jsonEncodeValue = function(value)
    local valueType = type(value)
    if valueType == "nil" then return "null" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    end
    if valueType == "string" then return jsonEscape(value) end
    if valueType ~= "table" then return "null" end

    if isArrayTable(value) then
        local parts = {}
        for index = 1, #value do
            parts[#parts + 1] = jsonEncodeValue(value[index])
        end
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local parts = {}
    for _, key in ipairs(sortedStringKeys(value)) do
        local encodedValue = jsonEncodeValue(value[key])
        if encodedValue ~= "null" then
            parts[#parts + 1] = jsonEscape(key) .. ":" .. encodedValue
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function encodeStoredTable(value)
    return jsonEncodeValue(sanitizeForStorage(value))
end

local function decodeStoredTable(value)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return nil end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return nil
end

local function loadScheduleIndex()
    local index = store:get(SCHEDULE_INDEX_KEY)
    if type(index) == "table" then return index end
    if type(index) ~= "string" or index == "" then return {} end
    local out = {}
    for recordId in string.gmatch(index, "([^\n]+)") do
        out[#out + 1] = lower(recordId)
    end
    return out
end

local function saveScheduleIndex(index)
    local out = {}
    for _, recordId in ipairs(index or {}) do
        if recordId and recordId ~= "" then
            out[#out + 1] = lower(recordId)
        end
    end
    table.sort(out)
    store:set(SCHEDULE_INDEX_KEY, table.concat(out, "\n"))
end

local function indexContains(index, recordId)
    local target = lower(recordId)
    for _, existing in ipairs(index or {}) do
        if lower(existing) == target then
            return true
        end
    end
    return false
end

local function addScheduleIndexRecord(recordId)
    if not recordId or recordId == "" then return end
    local index = loadScheduleIndex()
    if not indexContains(index, recordId) then
        index[#index + 1] = lower(recordId)
        table.sort(index)
        saveScheduleIndex(index)
    end
end

local function removeScheduleIndexRecord(recordId)
    if not recordId or recordId == "" then return end
    local target = lower(recordId)
    local index = loadScheduleIndex()
    local kept = {}
    local changed = false
    for _, existing in ipairs(index) do
        if lower(existing) == target then
            changed = true
        else
            kept[#kept + 1] = existing
        end
    end
    if changed then
        saveScheduleIndex(kept)
    end
end

local function makeKey(recordId, contentFile)
    return lower(recordId) .. "|" .. lower(contentFile)
end

local function makeScheduleStoreKey(recordId)
    return SCHEDULE_KEY_PREFIX .. lower(recordId)
end

local function recordIdFromStoredKey(key)
    local raw = tostring(key or "")
    local recordId = raw:match("^(.-)|")
    if recordId and recordId ~= "" then
        return lower(recordId)
    end
    return lower(raw)
end

local function normalizeGeneratedEntry(key, entry)
    if type(entry) ~= "table" then return entry, false end
    if entry.schedule then return entry, false end
    if not entry.Schedule then return entry, false end

    return {
        recordId = lower(entry.recordId or entry.RecordId or recordIdFromStoredKey(key)),
        contentFile = lower(entry.contentFile or entry.ContentFile or ""),
        name = entry.name or entry.Name or "",
        city = entry.city or entry.City or "",
        baseExterior = entry.baseExterior or entry.BaseExterior or "",
        source = entry.source or "generated_legacy",
        generatedAtGameDay = entry.generatedAtGameDay,
        generationVersion = entry.generationVersion or Config.GENERATION_VERSION,
        seed = entry.seed,
        schedule = entry,
        meta = entry.meta or entry.Meta or {},
    }, true
end

local function normalizeStoredSchedules()
    if not root or not root.schedules then return false end
    local changed = false
    for key, entry in pairs(root.schedules) do
        local normalized, didNormalize = normalizeGeneratedEntry(key, entry)
        if didNormalize then
            root.schedules[key] = normalized
            changed = true
        end
    end
    if changed then
        print("[GeneratedScheduleManager] normalized legacy generated schedule entries")
    end
    return changed
end

local function restoreIndexedSchedules()
    if not root then return 0, 0, 0 end
    root.schedules = root.schedules or {}
    local restored = 0
    local missing = 0
    local unusable = 0
    local keptIndex = {}
    local changedIndex = false
    for _, recordId in ipairs(loadScheduleIndex()) do
        local loRecordId = lower(recordId)
        local rawStored = store:get(makeScheduleStoreKey(loRecordId))
        local stored = decodeStoredTable(rawStored)
        local normalized = nil
        normalized = normalizeGeneratedEntry(loRecordId, stored)
        if isUsableGeneratedEntry(normalized) then
            local key = makeKey(normalized.recordId, normalized.contentFile or "")
            if not root.schedules[key] then
                root.schedules[key] = normalized
                restored = restored + 1
            end
            keptIndex[#keptIndex + 1] = loRecordId
        elseif rawStored == nil then
            missing = missing + 1
            changedIndex = true
        else
            unusable = unusable + 1
            changedIndex = true
        end
    end
    if changedIndex then
        saveScheduleIndex(keptIndex)
    end
    if restored > 0 then
        print(string.format("[GeneratedScheduleManager] restored %d generated schedules from persisted index", restored))
    end
    return restored, missing, unusable
end

function sanitizeForStorage(value, seen)
    local valueType = type(value)
    if valueType == "nil"
            or valueType == "string"
            or valueType == "boolean" then
        return value
    end
    if valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil
        end
        return value
    end
    if valueType ~= "table" then
        return nil
    end

    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true

    local out = {}
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            local cleanChild = sanitizeForStorage(child, seen)
            if cleanChild ~= nil then
                out[key] = cleanChild
            end
        end
    end

    seen[value] = nil
    return out
end

local function persistGeneratedEntry(entry)
    if not entry or not entry.recordId then return end
    store:set(makeScheduleStoreKey(entry.recordId), encodeStoredTable(entry))
    addScheduleIndexRecord(entry.recordId)
end

local function syncScheduleIndexFromRoot()
    if not root or not root.schedules then return end
    for _, entry in pairs(root.schedules) do
        if isUsableGeneratedEntry(entry) and entry.recordId then
            addScheduleIndexRecord(entry.recordId)
        end
    end
end

local function saveRoot()
    if root then
        local persistRoot = {}
        for key, value in pairs(root) do
            if key ~= "schedules" then
                persistRoot[key] = value
            end
        end
        persistRoot.schedules = {}
        store:set(STORE_KEY, sanitizeForStorage(persistRoot))
    end
end

local function ensureRoot()
    if root then return root end
    root = store:get(STORE_KEY)
    if type(root) ~= "table" then
        root = {}
    end
    root.version = root.version or Config.GENERATION_VERSION
    root.schedules = root.schedules or {}
    root.occupancyLedger = root.occupancyLedger or {}
    root.rejections = root.rejections or {}
    local restored = restoreIndexedSchedules()
    local normalized = normalizeStoredSchedules()
    pruneInteriorNativeSchedules()
    if normalized or restored > 0 then
        rebuildGeneratedLedger()
    end
    syncScheduleIndexFromRoot()
    saveRoot()
    return root
end

local function rebuildGeneratedIndex()
    ensureRoot()
    generatedByRecord = {}
    for key, entry in pairs(root.schedules or {}) do
        if entry and entry.recordId and entry.schedule and isUsableGeneratedEntry(entry) then
            local recordId = lower(entry.recordId)
            if not generatedByRecord[recordId] then
                generatedByRecord[recordId] = key
            end
            persistGeneratedEntry(entry)
        end
    end
end

local function ensureGeneratedIndex()
    if not generatedByRecord then rebuildGeneratedIndex() end
end

local function ensureStaticLedger()
    if not staticLedger then
        staticLedger = Ledger.seedFromSchedules(BakedScheduleLoader.getData())
    end
    return staticLedger
end

local function combinedLedger()
    ensureRoot()
    return Ledger.merge(ensureStaticLedger(), root.occupancyLedger)
end

local function getRecord(actor)
    local rec = nil
    pcall(function() rec = actor.type and actor.type.record and actor.type.record(actor) end)
    if not rec then
        pcall(function() rec = types.NPC.record(actor) end)
    end
    return rec
end

local function getActorRecordId(actor)
    local recordId = nil
    pcall(function() recordId = actor.recordId end)
    if not recordId or recordId == "" then
        local rec = getRecord(actor)
        recordId = rec and rec.id or nil
    end
    return lower(recordId)
end

local function getContentFile(actor)
    local contentFile = ""
    pcall(function() contentFile = actor.contentFile or "" end)
    return lower(contentFile)
end

local function getBaseExterior(actor)
    local cell = nil
    pcall(function() cell = actor.cell end)
    if not cell then return "" end
    local isExterior = false
    pcall(function() isExterior = cell.isExterior end)
    if not isExterior then return "" end
    local gx, gy = nil, nil
    pcall(function()
        gx = cell.gridX
        gy = cell.gridY
    end)
    if gx ~= nil and gy ~= nil then
        return string.format("Exterior: %d, %d", gx, gy)
    end
    return ""
end

local function gameDay()
    local day = 0
    pcall(function() day = math.floor(core.getGameTime() / 86400) end)
    return day
end

local function buildSummary(actor, player)
    local recordId = getActorRecordId(actor)
    if not recordId or recordId == "" then return nil, "generation_error" end

    local rec = getRecord(actor)
    local name = ""
    local className = ""
    local race = ""
    pcall(function() name = rec and rec.name or actor.recordId or recordId end)
    pcall(function() className = rec and rec.class or "" end)
    pcall(function() race = rec and rec.race or "" end)

    local city = Collector.getCityForActor(actor)
    if not city then return nil, "no_city_context" end

    local nativeCell = nil
    pcall(function()
        local c = nil
        c = NPCState.loadNativeHome(actor)
        nativeCell = c
    end)

    local summary = {
        recordId = recordId,
        contentFile = getContentFile(actor),
        name = name,
        className = className,
        race = race,
        city = city,
        baseExterior = getBaseExterior(actor),
        nativeCell = nativeCell,
        generatedAtGameDay = gameDay(),
        generationVersion = Config.GENERATION_VERSION,
    }
    summary.homeCell = Collector.resolveHome(actor, summary)
    summary.seed = Generator.makeSeed(summary.recordId, summary.contentFile, summary.city, summary.generationVersion)
    return summary, nil
end

local function rememberRejection(key, recordId, reason)
    ensureRoot()
    root.rejections[key] = {
        recordId = recordId,
        reason = reason,
        generationVersion = Config.GENERATION_VERSION,
        gameDay = gameDay(),
    }
    saveRoot()
end

function Manager.hasStaticSchedule(recordId)
    local data = BakedScheduleLoader.getData()
    return data and data[lower(recordId)] ~= nil
end

function Manager.hasSchedule(recordId)
    return Manager.getSchedule(recordId) ~= nil
end

function Manager.getSchedule(recordId)
    ensureRoot()
    ensureGeneratedIndex()
    local loRecordId = lower(recordId)
    local key = generatedByRecord[loRecordId]
    local entry = key and root.schedules[key] or nil
    if not entry then
        local stored = decodeStoredTable(store:get(makeScheduleStoreKey(loRecordId)))
        local normalized = nil
        normalized = normalizeGeneratedEntry(loRecordId, stored)
        entry = normalized
        if isUsableGeneratedEntry(entry) then
            local restoredKey = makeKey(entry.recordId, entry.contentFile or "")
            root.schedules[restoredKey] = entry
            generatedByRecord[loRecordId] = restoredKey
            saveRoot()
        end
    end
    if not isUsableGeneratedEntry(entry) then return nil end
    return entry and entry.schedule or nil
end

function Manager.getAllSchedules()
    ensureRoot()
    local out = {}
    for _, entry in pairs(root.schedules or {}) do
        if entry.recordId and entry.schedule and isUsableGeneratedEntry(entry) then
            out[lower(entry.recordId)] = entry.schedule
        end
    end
    return out
end

local function findActorByRecordId(recordId)
    local world = nil
    pcall(function() world = require("openmw.world") end)
    if not world then return nil end
    local ok, actors = pcall(function() return world.activeActors end)
    if not ok or not actors then return nil end
    local target = lower(recordId)
    for _, actor in ipairs(actors) do
        local isNpc = false
        pcall(function() isNpc = types.NPC.objectIsInstance(actor) end)
        if isNpc then
            local id = getActorRecordId(actor)
            if id == target then
                return actor
            end
        end
    end
    return nil
end

local function findHomelessOccupant(tavernName, city, excludeRecordId)
    if not tavernName or tavernName == "" then return nil end
    ensureRoot()
    local targetTavern = lower(tavernName)
    local targetCity = lower(city or "")
    for key, entry in pairs(root.schedules or {}) do
        if not isUsableGeneratedEntry(entry) then goto continue end
        local recordId = lower(entry.recordId or "")
        if recordId == "" or recordId == lower(excludeRecordId or "") then goto continue end
        if entry.meta and entry.meta.eveningTavern
                and lower(entry.meta.eveningTavern) == targetTavern then
            -- Homeless if they also shelter at this tavern (night blocks == tavern)
            if entry.meta.homeOrShelter
                    and lower(entry.meta.homeOrShelter) == targetTavern then
                return { key = key, entry = entry, recordId = entry.recordId }
            end
        end
        ::continue::
    end
    return nil
end

local function removeEveningTavernFromEntry(entry, tavernName)
    if not entry or not entry.schedule or not entry.schedule.Schedule then return end
    if not entry.meta then return end
    local targetTavern = lower(tavernName)
    -- Remove 18-21 blocks from schedule
    for _, dayName in ipairs(Config.DAYS) do
        local daySchedule = entry.schedule.Schedule[dayName]
        if daySchedule and daySchedule[Config.EVENING_BLOCK]
                and lower(daySchedule[Config.EVENING_BLOCK]) == targetTavern then
            daySchedule[Config.EVENING_BLOCK] = nil
        end
    end
    -- Remove reservations from meta and ledger
    if entry.meta.reservations then
        local kept = {}
        for _, res in ipairs(entry.meta.reservations) do
            if res.timeBlock == Config.EVENING_BLOCK
                    and lower(res.destination or "") == targetTavern then
                Ledger.release(root.occupancyLedger, res.city, res.day, res.timeBlock, res.destination, res.amount or 1)
            else
                kept[#kept + 1] = res
            end
        end
        entry.meta.reservations = kept
    end
    if entry.meta.eveningTavern and lower(entry.meta.eveningTavern) == targetTavern then
        entry.meta.eveningTavern = nil
    end
end

local function addEveningTavernToCurrent(entry, meta, tavernName, summary)
    if not entry or not entry.schedule or not meta then return end
    -- Add 18-21 blocks
    for _, dayName in ipairs(Config.DAYS) do
        if not entry.schedule.Schedule[dayName] then
            entry.schedule.Schedule[dayName] = {}
        end
        entry.schedule.Schedule[dayName][Config.EVENING_BLOCK] = tavernName
    end
    -- Add ledger reservations
    local newReservations = Ledger.reserveAll(root.occupancyLedger, summary.city, Config.DAYS, { Config.EVENING_BLOCK }, tavernName, 1)
    for _, res in ipairs(newReservations) do
        meta.reservations[#meta.reservations + 1] = res
    end
    meta.eveningTavern = tavernName
end

function Manager.ensureGeneratedForActor(actor, player)
    if not Config.ENABLED then return false, "generation_disabled" end
    if not actor then return false, "generation_error" end

    local okNpc, isNpc = pcall(function() return types.NPC.objectIsInstance(actor) end)
    if not okNpc or not isNpc then return false, "not_npc" end

    local enabled = false
    pcall(function() enabled = actor.enabled end)
    if not enabled then
        return false, "npc_disabled"
    end

    local recordId = getActorRecordId(actor)
    if not recordId or recordId == "" then return false, "generation_error" end
    if Manager.hasStaticSchedule(recordId) then return false, "static_schedule_exists" end

    local contentFile = getContentFile(actor)
    local key = makeKey(recordId, contentFile)
    ensureRoot()
    ensureGeneratedIndex()
    if Manager.getSchedule(recordId) then
        return true, "generated_schedule_exists"
    end
    if root.schedules[key] and not isUsableGeneratedEntry(root.schedules[key]) then
        root.schedules[key] = nil
        rebuildGeneratedLedger()
        saveRoot()
        rebuildGeneratedIndex()
    end
    if root.schedules[key] or generatedByRecord[recordId] then
        return true, "generated_schedule_exists"
    end

    local rejection = root.rejections[key]
    if rejection and rejection.reason ~= "no_city_context"
            and rejection.reason ~= "no_destinations"
            and rejection.reason ~= "quest_locked"
            and rejection.reason ~= "generation_error" then
        return false, rejection.reason
    end

    if Blacklist.isScheduleBlacklisted(actor, player) then
        rememberRejection(key, recordId, "blacklisted_actor")
        return false, "blacklisted_actor"
    end
    if player and Blacklist.isQuestLocked(actor, player) then
        rememberRejection(key, recordId, "quest_locked")
        return false, "quest_locked"
    end

    local summary, summaryReason = buildSummary(actor, player)
    if not summary then
        rememberRejection(key, recordId, summaryReason or "generation_error")
        return false, summaryReason or "generation_error"
    end
    if Config.REQUIRE_BASE_EXTERIOR and (not summary.baseExterior or summary.baseExterior == "") then
        rememberRejection(key, recordId, "interior_native")
        return false, "interior_native"
    end

    -- Service providers (merchants, trainers, etc.) who live in exteriors
    -- should not be scheduled to visit other shops or markets.
    if summary.baseExterior and summary.baseExterior ~= "" then
        local rec = getRecord(actor)
        local hasAny = false
        if rec and rec.services then
            for _, val in pairs(rec.services) do
                if val then hasAny = true; break end
            end
        end
        if not hasAny and rec and rec.servicesOffered then
            for _, val in pairs(rec.servicesOffered) do
                if val then hasAny = true; break end
            end
        end
        if hasAny then
            summary.noShopping = true
        end
    end

    local pools, poolReason = Collector.collect(actor, summary)
    if not pools then
        rememberRejection(key, recordId, poolReason or "no_destinations")
        return false, poolReason or "no_destinations"
    end

    local workingLedger = combinedLedger()
    local entry, meta = Generator.generate(summary, pools, workingLedger)
    if not entry then
        rememberRejection(key, recordId, meta or "no_destinations")
        return false, meta or "no_destinations"
    end

    root.schedules[key] = {
        recordId = summary.recordId,
        contentFile = summary.contentFile,
        name = summary.name,
        city = summary.city,
        baseExterior = summary.baseExterior,
        source = "generated",
        generatedAtGameDay = summary.generatedAtGameDay,
        generationVersion = summary.generationVersion,
        seed = summary.seed,
        schedule = entry,
        meta = meta,
    }
    persistGeneratedEntry(root.schedules[key])
    root.rejections[key] = nil
    Ledger.applyReservations(root.occupancyLedger, meta and meta.reservations or {})
    saveRoot()
    rebuildGeneratedIndex()

    -- Booting: homeowners who failed to get their nearest tavern can displace a homeless occupant
    if summary.homeCell and meta and not meta.eveningTavern and pools.taverns and pools.taverns[1] then
        local nearestTavern = pools.taverns[1].name
        if nearestTavern and nearestTavern ~= "" then
            local booted = findHomelessOccupant(nearestTavern, summary.city, summary.recordId)
            if booted then
                -- Strip evening tavern from booted NPC
                removeEveningTavernFromEntry(booted.entry, nearestTavern)

                -- Give evening tavern to current NPC
                addEveningTavernToCurrent(root.schedules[key], meta, nearestTavern, summary)
                persistGeneratedEntry(root.schedules[key])
                saveRoot()
                rebuildGeneratedIndex()

                print(string.format("[GeneratedScheduleManager] BOOT npc='%s' booted='%s' tavern='%s'",
                    recordId, lower(booted.recordId or "?"), nearestTavern))

                -- Try to instantly regenerate booted NPC
                local bootedActor = findActorByRecordId(booted.recordId)
                if bootedActor then
                    store:set(makeScheduleStoreKey(booted.recordId), nil)
                    removeScheduleIndexRecord(booted.recordId)
                    root.schedules[booted.key] = nil
                    rebuildGeneratedLedger()
                    saveRoot()
                    rebuildGeneratedIndex()
                    Manager.ensureGeneratedForActor(bootedActor, player)
                else
                    -- Deloaded: clear schedule so they regenerate fresh when next active
                    store:set(makeScheduleStoreKey(booted.recordId), nil)
                    removeScheduleIndexRecord(booted.recordId)
                    root.schedules[booted.key] = nil
                    rebuildGeneratedLedger()
                    saveRoot()
                    rebuildGeneratedIndex()
                end
            end
        end
    end

    print(string.format("[GeneratedScheduleManager] generated npc='%s' city='%s'", recordId, tostring(summary.city)))
    return true, "generated"
end

function Manager.getDiagnostics()
    ensureRoot()
    return {
        version = root.version,
        generationVersion = Config.GENERATION_VERSION,
        staticSchedules = countMap(BakedScheduleLoader.getData()),
        generatedSchedules = countMap(root.schedules),
        rejected = countMap(root.rejections),
        indexedSchedules = #loadScheduleIndex(),
        occupancyEntries = countMap(root.occupancyLedger),
    }
end

function Manager.dumpNpc(recordId)
    ensureRoot()
    ensureGeneratedIndex()
    local key = generatedByRecord[lower(recordId)]
    if key then return root.schedules[key] end
    return nil
end

function Manager.clearGeneratedSchedules()
    ensureRoot()
    for _, recordId in ipairs(loadScheduleIndex()) do
        store:set(makeScheduleStoreKey(recordId), nil)
    end
    for _, entry in pairs(root.schedules or {}) do
        if entry and entry.recordId then
            store:set(makeScheduleStoreKey(entry.recordId), nil)
        end
    end
    root = {
        version = Config.GENERATION_VERSION,
        schedules = {},
        occupancyLedger = {},
        rejections = {},
    }
    generatedByRecord = {}
    saveScheduleIndex({})
    saveRoot()
end

function Manager.clearRejectedCache()
    ensureRoot()
    root.rejections = {}
    saveRoot()
end

local DAYS_ORDER = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

function Manager.dumpAllSchedulesToLog()
    ensureRoot()
    local entries = {}
    local rawCount = 0
    local unusableCount = 0
    for _, entry in pairs(root.schedules or {}) do
        rawCount = rawCount + 1
        if entry.recordId and entry.schedule and isUsableGeneratedEntry(entry) then
            table.insert(entries, entry)
        else
            unusableCount = unusableCount + 1
        end
    end

    print(string.format("[PC_GEN_SCHED_DUMP] BEGIN count=%d", #entries))
    print(string.format("[PC_GEN_SCHED_DUMP_META] raw=%d unusable=%d rejected=%d indexed=%d prunedInteriorNativeV1=%s",
        rawCount, unusableCount, countMap(root.rejections), #loadScheduleIndex(), tostring(root.prunedInteriorNativeV1 == true)))
    local rejectionReasons = {}
    for _, rejection in pairs(root.rejections or {}) do
        local reason = tostring((type(rejection) == "table" and rejection.reason) or "unknown")
        rejectionReasons[reason] = (rejectionReasons[reason] or 0) + 1
    end
    for _, reason in ipairs(sortedKeys(rejectionReasons)) do
        print(string.format("[PC_GEN_SCHED_REJECTION_SUMMARY] reason=%s count=%d",
            reason, rejectionReasons[reason] or 0))
    end
    for _, recordId in ipairs(loadScheduleIndex()) do
        local rawStored = store:get(makeScheduleStoreKey(recordId))
        local decoded = decodeStoredTable(rawStored)
        local normalized = normalizeGeneratedEntry(recordId, decoded)
        print(string.format("[PC_GEN_SCHED_STORE] recordId=%s rawType=%s rawLen=%s decoded=%s usable=%s",
            tostring(recordId),
            type(rawStored),
            type(rawStored) == "string" and tostring(#rawStored) or "",
            tostring(type(decoded) == "table"),
            tostring(isUsableGeneratedEntry(normalized))))
    end
    for _, key in ipairs(sortedKeys(root.rejections)) do
        local rejection = root.rejections[key]
        if type(rejection) == "table" then
            print(string.format("[PC_GEN_SCHED_REJECTION] key=%s recordId=%s reason=%s gameDay=%s generationVersion=%s",
                key,
                tostring(rejection.recordId or ""),
                tostring(rejection.reason or "unknown"),
                tostring(rejection.gameDay or ""),
                tostring(rejection.generationVersion or "")))
        else
            print(string.format("[PC_GEN_SCHED_REJECTION] key=%s recordId= reason=%s gameDay= generationVersion=",
                key, tostring(rejection or "unknown")))
        end
    end
    for _, entry in ipairs(entries) do
        local sched = entry.schedule
        print(string.format("[PC_GEN_SCHED_DUMP_START] %s", entry.recordId))
        print(string.format("Name=%s", sched.Name or entry.name or entry.recordId))
        print(string.format("City=%s", sched.City or entry.city or ""))
        print(string.format("BaseExterior=%s", sched.BaseExterior or entry.baseExterior or ""))
        if sched.Schedule then
            for _, day in ipairs(DAYS_ORDER) do
                local blocks = sched.Schedule[day]
                if blocks then
                    for timeBlock, dest in pairs(blocks) do
                        print(string.format("SCHEDULE|%s|%s|%s", day, timeBlock, dest))
                    end
                end
            end
        end
        print(string.format("[PC_GEN_SCHED_DUMP_END] %s", entry.recordId))
    end
    print("[PC_GEN_SCHED_DUMP] COMPLETE")
end

return Manager
