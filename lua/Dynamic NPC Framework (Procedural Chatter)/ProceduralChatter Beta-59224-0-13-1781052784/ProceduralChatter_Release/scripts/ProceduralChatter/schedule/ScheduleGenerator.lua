-- ScheduleGenerator.lua
-- Deterministic weekly schedule generation based on the scanner compiler.

local Config = require("scripts.ProceduralChatter.data.ScheduleGenerationConfig")
local Ledger = require("scripts.ProceduralChatter.schedule.ScheduleOccupancyLedger")

local Generator = {}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function stableHash(text)
    local hash = 2166136261
    text = tostring(text or "")
    for i = 1, #text do
        hash = (hash + string.byte(text, i)) * 16777619
        hash = hash % 4294967296
    end
    return hash
end

local SOURCE_PRIORITY = {
    door_scan = 1,
    static_schedule = 2,
    town_data = 3,
    fallback = 4,
}

local function sortCandidates(list)
    local out = {}
    for index, item in ipairs(list or {}) do
        out[index] = item
    end
    table.sort(out, function(a, b)
        local ad = (type(a) == "table" and a.distance) or nil
        local bd = (type(b) == "table" and b.distance) or nil
        ad = ad or math.huge
        bd = bd or math.huge
        if ad ~= bd then return ad < bd end

        local as = type(a) == "table" and a.source or nil
        local bs = type(b) == "table" and b.source or nil
        local ap = SOURCE_PRIORITY[as] or 99
        local bp = SOURCE_PRIORITY[bs] or 99
        if ap ~= bp then return ap < bp end

        local an = type(a) == "table" and a.name or tostring(a)
        local bn = type(b) == "table" and b.name or tostring(b)
        return lower(an) < lower(bn)
    end)
    return out
end

local function stableSortStrings(list, seed, salt)
    local out = {}
    for index, item in ipairs(list or {}) do
        out[index] = item
    end
    table.sort(out, function(a, b)
        local ah = stableHash(tostring(seed) .. "|" .. tostring(salt) .. "|" .. lower(a))
        local bh = stableHash(tostring(seed) .. "|" .. tostring(salt) .. "|" .. lower(b))
        if ah ~= bh then return ah < bh end
        return lower(a) < lower(b)
    end)
    return out
end

local function appendAll(dest, src)
    for _, value in ipairs(src or {}) do
        dest[#dest + 1] = value
    end
end

local function isDunmer(race)
    local r = lower(race)
    return r:find("dark elf", 1, true) ~= nil or r:find("dunmer", 1, true) ~= nil
end

local function prefersImperialShrine(race)
    local r = lower(race)
    return r:find("imperial", 1, true)
        or r:find("breton", 1, true)
        or r:find("nord", 1, true)
        or r:find("redguard", 1, true)
end

local function candidateName(item)
    if type(item) == "table" then return item.name end
    return item
end

local function usableCandidate(item)
    return item and not (item.locked and item.source == "door_scan")
end

local function addBlock(schedule, dayName, timeBlock, destination)
    if not destination or destination == "" then return end
    if not schedule[dayName] then schedule[dayName] = {} end
    schedule[dayName][timeBlock] = destination
end

local function hasAnyBlock(schedule)
    for _, daySchedule in pairs(schedule or {}) do
        for _ in pairs(daySchedule or {}) do
            return true
        end
    end
    return false
end

local function findAllDaysDestination(summary, ledger, candidates, timeBlocks, cap, salt)
    local city = summary.city
    local ordered = sortCandidates(candidates)
    for _, item in ipairs(ordered) do
        if usableCandidate(item) then
            local name = candidateName(item)
            if summary.city and lower(summary.city) == "moonmoth legion fort" and lower(name):find("balmora", 1, true) then
                goto continue
            end
            if Ledger.canReserveAll(ledger, city, Config.DAYS, timeBlocks, name, cap) then
                return name
            end
        end
        ::continue::
    end
    return nil
end

local function reserveAllDays(reservations, ledger, city, timeBlocks, destination)
    appendAll(reservations, Ledger.reserveAll(ledger, city, Config.DAYS, timeBlocks, destination, 1))
end

local function religiousCandidatesForRace(pools, race)
    local result = {}
    if isDunmer(race) then
        appendAll(result, pools.temples)
        appendAll(result, pools.religious)
        return result
    end
    if prefersImperialShrine(race) then
        appendAll(result, pools.imperialShrines)
        for _, item in ipairs(pools.religious or {}) do
            if not item.temple then result[#result + 1] = item end
        end
        return result
    end
    for _, item in ipairs(pools.religious or {}) do
        if not item.temple then result[#result + 1] = item end
    end
    appendAll(result, pools.religious)
    return result
end

local function findSundayService(summary, pools, ledger, hasEvening)
    local slots = hasEvening and Config.SERVICE_SLOTS_WITH_EVENING or Config.SERVICE_SLOTS
    local candidates = sortCandidates(religiousCandidatesForRace(pools, summary.race))
    for _, item in ipairs(candidates) do
        if usableCandidate(item) then
            local name = candidateName(item)
            for _, slot in ipairs(slots) do
                if Ledger.canReserve(ledger, summary.city, "Sunday", slot, name, Config.RELIGIOUS_SERVICE_CAP) then
                    return name, slot
                end
            end
        end
    end
    return nil, nil
end

local function findShelter(summary, pools, ledger, eveningTavern)
    if eveningTavern and Ledger.canReserveAll(ledger, summary.city, Config.DAYS, Config.NIGHT_BLOCKS, eveningTavern, Config.NIGHT_SHELTER_CAP) then
        return eveningTavern
    end

    local tavern = findAllDaysDestination(summary, ledger, pools.taverns, Config.NIGHT_BLOCKS, Config.NIGHT_SHELTER_CAP, "night-tavern")
    if tavern then return tavern end

    local religious = findAllDaysDestination(
        summary,
        ledger,
        religiousCandidatesForRace(pools, summary.race),
        Config.NIGHT_BLOCKS,
        Config.NIGHT_SHELTER_CAP,
        "night-religious"
    )
    if religious then return religious end

    return findAllDaysDestination(summary, ledger, pools.military, Config.NIGHT_BLOCKS, Config.NIGHT_SHELTER_CAP, "night-military")
end

local function addShopping(summary, pools, ledger, schedule, reservations)
    if summary.noShopping then return end
    local shopPool = {}
    appendAll(shopPool, pools.shops)
    if pools.exteriorMarket then
        shopPool[#shopPool + 1] = { name = "Market:Exterior", kind = "market", source = "town_data" }
    end
    if #shopPool == 0 then return end

    local days = stableSortStrings(Config.WEEKDAYS, summary.seed, "shopping-days")
    local assigned = 0
    for _, dayName in ipairs(days) do
        if assigned >= 3 then return end
        local slots = stableSortStrings(Config.SHOPPING_SLOTS, summary.seed, "shopping-slots-" .. dayName)
        local shops = sortCandidates(shopPool)
        for _, slot in ipairs(slots) do
            if schedule[dayName] and schedule[dayName][slot] then goto nextSlot end
            for _, item in ipairs(shops) do
                if usableCandidate(item) then
                    local name = candidateName(item)
                    local cap = name == "Market:Exterior" and Config.EXTERIOR_MARKET_CAP or Config.SHOPPING_CAP
                    if Ledger.canReserve(ledger, summary.city, dayName, slot, name, cap) then
                        addBlock(schedule, dayName, slot, name)
                        reservations[#reservations + 1] = {
                            key = Ledger.reserve(ledger, summary.city, dayName, slot, name, 1),
                            city = summary.city,
                            day = dayName,
                            timeBlock = slot,
                            destination = name,
                            amount = 1,
                        }
                        assigned = assigned + 1
                        goto nextDay
                    end
                end
            end
            ::nextSlot::
        end
        ::nextDay::
    end
end

function Generator.makeSeed(recordId, contentFile, city, version)
    return stableHash(lower(recordId) .. "|" .. lower(contentFile) .. "|" .. lower(city) .. "|" .. tostring(version or Config.GENERATION_VERSION))
end

function Generator.generate(summary, pools, ledger)
    if not summary or not summary.recordId then
        return nil, "generation_error"
    end
    if not pools then
        return nil, "no_destinations"
    end

    local schedule = {}
    local reservations = {}
    local workingLedger = ledger

    local eveningTavern = findAllDaysDestination(summary, workingLedger, pools.taverns, { Config.EVENING_BLOCK }, Config.EVENING_TAVERN_CAP, "evening-tavern")
    if eveningTavern then
        for _, dayName in ipairs(Config.DAYS) do
            addBlock(schedule, dayName, Config.EVENING_BLOCK, eveningTavern)
        end
        reserveAllDays(reservations, workingLedger, summary.city, { Config.EVENING_BLOCK }, eveningTavern)
    end

    local homeOrShelter = summary.homeCell
    if not homeOrShelter then
        homeOrShelter = findShelter(summary, pools, workingLedger, eveningTavern)
    end
    if homeOrShelter then
        for _, dayName in ipairs(Config.DAYS) do
            for _, block in ipairs(Config.NIGHT_BLOCKS) do
                addBlock(schedule, dayName, block, homeOrShelter)
            end
        end
        if not summary.homeCell then
            reserveAllDays(reservations, workingLedger, summary.city, Config.NIGHT_BLOCKS, homeOrShelter)
        end
    end

    local serviceDestination, serviceSlot = findSundayService(summary, pools, workingLedger, eveningTavern ~= nil)
    if serviceDestination and serviceSlot then
        addBlock(schedule, "Sunday", serviceSlot, serviceDestination)
        reservations[#reservations + 1] = {
            key = Ledger.reserve(workingLedger, summary.city, "Sunday", serviceSlot, serviceDestination, 1),
            city = summary.city,
            day = "Sunday",
            timeBlock = serviceSlot,
            destination = serviceDestination,
            amount = 1,
        }
    end

    addShopping(summary, pools, workingLedger, schedule, reservations)

    if not hasAnyBlock(schedule) then
        return nil, "no_destinations"
    end

    return {
        Name = summary.name or "",
        City = summary.city,
        BaseExterior = summary.baseExterior or "",
        Schedule = schedule,
    }, {
        reservations = reservations,
        eveningTavern = eveningTavern,
        homeOrShelter = homeOrShelter,
        sundayService = serviceDestination,
        sundayServiceSlot = serviceSlot,
    }
end

return Generator
