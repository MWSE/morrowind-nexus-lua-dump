-- ScheduleDestinationCollector.lua
-- Builds deterministic destination pools for runtime schedule generation.

local types = require("openmw.types")

local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local ScheduleDestinationLoader = require("scripts.ProceduralChatter.ScheduleDestinationLoader")
local DestinationData = ScheduleDestinationLoader.getData()
local DestinationResolver = require("scripts.ProceduralChatter.schedule.DestinationResolver")
local BakedScheduleLoader = require("scripts.ProceduralChatter.BakedScheduleLoader")

local Collector = {}

local SOURCE_PRIORITY = {
    door_scan = 1,
    static_schedule = 2,
    town_data = 3,
    fallback = 4,
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function exactCellMatch(value, cells)
    local text = lower(value)
    if text == "" then return false end
    for _, cellName in ipairs(cells or {}) do
        if text == lower(cellName) then
            return true
        end
    end
    return false
end

local function keywordMatchesCell(cellName, keyword)
    local text = lower(cellName)
    local pattern = lower(keyword)
    if text == "" or pattern == "" then return false end

    -- Fully-qualified cell names are exact matches. Generic terms like "hotel"
    -- remain partial matches for cells such as "Bran's Hotel".
    if pattern:find(",", 1, true) then
        return text == pattern
    end
    return text:find(pattern, 1, true) ~= nil
end

local function hasDestinationKeyword(cellName, keywords)
    for _, keyword in ipairs(keywords or {}) do
        if keywordMatchesCell(cellName, keyword) then
            return true
        end
    end
    return false
end

local function destinationRef()
    return DestinationData.luaNpcSchedule or {}
end

local function isGenerationBlacklistedCell(cellName)
    local ref = destinationRef()
    return Blacklist.isDestinationBlacklisted(cellName, "generation")
        or exactCellMatch(cellName, ref.blacklistedCells)
end

local function displayCityName(name)
    if not name or name == "" then return nil end
    return (name:gsub("^%l", string.upper))
end

local function lookupVariants(city)
    local variants = {}
    local seen = {}
    local function add(value)
        if value and value ~= "" and not seen[value] then
            seen[value] = true
            variants[#variants + 1] = value
        end
    end
    add(city)
    if city then
        add(city:gsub("Ald%-ruhn", "Ald'ruhn"))
        add(city:gsub("Ald'ruhn", "Ald-ruhn"))
        add(city:gsub("Sadrith Mora", "Sadrith-Mora"))
        add(city:gsub("Sadrith%-Mora", "Sadrith Mora"))
    end
    return variants
end

local function valuesForCity(map, city)
    local values = {}
    for _, variant in ipairs(lookupVariants(city)) do
        for key, list in pairs(map or {}) do
            if lower(key) == lower(variant) then
                return list
            end
        end
    end
    return values
end

local function classifyWithReferenceData(name)
    local class = {
        safe = false,
        religious = false,
        military = false,
        shop = false,
        temple = false,
        imperialShrine = false,
        blacklisted = isGenerationBlacklistedCell(name),
    }
    local ref = destinationRef()
    if class.blacklisted then return class end

    for _, cellName in ipairs(ref.tribunalTempleCells or {}) do
        if lower(cellName) == lower(name) then
            class.religious = true
            class.temple = true
        end
    end
    for _, cellName in ipairs(ref.imperialShrineCells or {}) do
        if lower(cellName) == lower(name) then
            class.religious = true
            class.imperialShrine = true
        end
    end
    for _, keyword in ipairs(ref.shopKeywords or {}) do
        if lower(name):find(lower(keyword), 1, true) then
            class.shop = true
        end
    end
    if hasDestinationKeyword(name, ref.tavernKeywords) then
        class.safe = true
    end
    if hasDestinationKeyword(name, ref.militaryKeywords) then
        class.military = true
        if not exactCellMatch(name, ref.tavernKeywords) then
            class.safe = false
        end
    end
    return class
end

local function candidate(name, kind, source, distance, extra)
    local class = classifyWithReferenceData(name)
    if class.blacklisted then return nil end
    local item = {
        name = name,
        kind = kind,
        source = source or "fallback",
        distance = distance,
        locked = extra and extra.locked or false,
        blacklisted = false,
        safe = class.safe,
        religious = class.religious,
        temple = class.temple,
        imperialShrine = class.imperialShrine,
        military = class.military,
        shop = class.shop,
    }
    return item
end

local function addCandidate(pool, seen, item)
    if not item or not item.name or item.name == "" then return end
    local key = lower(item.name)
    local existing = seen[key]
    if existing then
        local oldPriority = SOURCE_PRIORITY[existing.source] or 99
        local newPriority = SOURCE_PRIORITY[item.source] or 99
        local oldDist = existing.distance or math.huge
        local newDist = item.distance or math.huge
        if newPriority < oldPriority or (newPriority == oldPriority and newDist < oldDist) then
            for index, value in ipairs(pool) do
                if value == existing then
                    pool[index] = item
                    break
                end
            end
            seen[key] = item
        end
        return
    end
    seen[key] = item
    pool[#pool + 1] = item
end

local function sortPool(pool)
    table.sort(pool, function(a, b)
        local ad = a.distance or math.huge
        local bd = b.distance or math.huge
        if ad ~= bd then return ad < bd end
        local ap = SOURCE_PRIORITY[a.source] or 99
        local bp = SOURCE_PRIORITY[b.source] or 99
        if ap ~= bp then return ap < bp end
        return lower(a.name) < lower(b.name)
    end)
end

local function getRecordId(actor)
    local id = nil
    pcall(function() id = string.lower(actor.recordId) end)
    return id
end

local function getCellName(actor)
    local name = nil
    pcall(function() name = actor.cell and actor.cell.name or nil end)
    return name
end

function Collector.getCityForActor(actor)
    local cellName = getCellName(actor)
    if cellName and cellName ~= "" then
        local lowerCell = lower(cellName)
        if Blacklist.isInCity(cellName) or Blacklist.isCellWhitelisted(cellName) then
            return cellName
        end
        local prefix = lowerCell:match("^(.-),%s")
        if prefix and Blacklist.isInCity(prefix) then
            return displayCityName(prefix)
        end
        if prefix and Blacklist.isCellWhitelisted(prefix) then
            return displayCityName(prefix)
        end
    end
    return nil
end

local function scanDoors(actor, pools, seen)
    local ok, objects = pcall(function() return actor.cell and actor.cell:getAll() end)
    if not ok or not objects then return end

    for _, obj in ipairs(objects) do
        local isDoor = false
        pcall(function() isDoor = types.Door.objectIsInstance(obj) end)
        if not isDoor then goto continue end

        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(obj) end)
        if not isTeleport then goto continue end

        local okDest, destCell = pcall(types.Door.destCell, obj)
        if not okDest or not destCell or destCell.isExterior then goto continue end
        local name = destCell.name or ""
        if name == "" or isGenerationBlacklistedCell(name) then goto continue end

        local locked = false
        pcall(function() locked = types.Lockable.isLocked(obj) end)
        if locked then goto continue end
        local distance = nil
        pcall(function() distance = (obj.position - actor.position):length() end)
        local class = classifyWithReferenceData(name)

        if hasDestinationKeyword(name, destinationRef().tavernKeywords) and not class.military then
            addCandidate(pools.taverns, seen.taverns, candidate(name, "tavern", "door_scan", distance, { locked = locked }))
        end
        if class.shop and not hasDestinationKeyword(name, destinationRef().tavernKeywords) then
            addCandidate(pools.shops, seen.shops, candidate(name, "shop", "door_scan", distance, { locked = locked }))
        end
        if class.religious then
            addCandidate(pools.religious, seen.religious, candidate(name, "religious", "door_scan", distance, { locked = locked }))
        end
        if class.temple then
            addCandidate(pools.temples, seen.temples, candidate(name, "temple", "door_scan", distance, { locked = locked }))
        end
        if class.imperialShrine then
            addCandidate(pools.imperialShrines, seen.imperialShrines, candidate(name, "imperialShrine", "door_scan", distance, { locked = locked }))
        end
        if class.military then
            addCandidate(pools.military, seen.military, candidate(name, "military", "door_scan", distance, { locked = locked }))
        end

        ::continue::
    end
end

local function addTownData(city, pools, seen)
    for _, shopName in ipairs(valuesForCity(DestinationData.storesByTown, city)) do
        if not hasDestinationKeyword(shopName, destinationRef().tavernKeywords) then
            addCandidate(pools.shops, seen.shops, candidate(shopName, "shop", "town_data"))
        end
    end
    for _, religiousName in ipairs(valuesForCity(DestinationData.religiousByTown, city)) do
        local class = classifyWithReferenceData(religiousName)
        local item = candidate(religiousName, "religious", "town_data")
        addCandidate(pools.religious, seen.religious, item)
        if class.temple then
            addCandidate(pools.temples, seen.temples, candidate(religiousName, "temple", "town_data"))
        end
        if class.imperialShrine then
            addCandidate(pools.imperialShrines, seen.imperialShrines, candidate(religiousName, "imperialShrine", "town_data"))
        end
    end
    for _, religiousName in ipairs(valuesForCity((DestinationData.luaNpcSchedule or {}).religiousByTown, city)) do
        local class = classifyWithReferenceData(religiousName)
        addCandidate(pools.religious, seen.religious, candidate(religiousName, "religious", "fallback"))
        if class.temple then
            addCandidate(pools.temples, seen.temples, candidate(religiousName, "temple", "fallback"))
        end
        if class.imperialShrine then
            addCandidate(pools.imperialShrines, seen.imperialShrines, candidate(religiousName, "imperialShrine", "fallback"))
        end
    end

    for _, cellName in ipairs(valuesForCity((DestinationData.luaNpcSchedule or {}).overrideCellsByTown, city)) do
        local class = classifyWithReferenceData(cellName)
        if hasDestinationKeyword(cellName, destinationRef().tavernKeywords) and not class.military then
            addCandidate(pools.taverns, seen.taverns, candidate(cellName, "tavern", "fallback"))
        end
        if class.shop and not hasDestinationKeyword(cellName, destinationRef().tavernKeywords) then
            addCandidate(pools.shops, seen.shops, candidate(cellName, "shop", "fallback"))
        end
        if class.religious then
            addCandidate(pools.religious, seen.religious, candidate(cellName, "religious", "fallback"))
        end
        if class.temple then
            addCandidate(pools.temples, seen.temples, candidate(cellName, "temple", "fallback"))
        end
        if class.imperialShrine then
            addCandidate(pools.imperialShrines, seen.imperialShrines, candidate(cellName, "imperialShrine", "fallback"))
        end
        if class.military then
            addCandidate(pools.military, seen.military, candidate(cellName, "military", "fallback"))
        end
    end
end

local function addStaticScheduleData(city, pools, seen)
    local cityLower = lower(city)
    local StaticScheduleData = BakedScheduleLoader.getData()
    for _, entry in pairs(StaticScheduleData or {}) do
        if entry.City and lower(entry.City) == cityLower then
            for _, daySchedule in pairs(entry.Schedule or {}) do
                for _, destination in pairs(daySchedule or {}) do
                    if destination and destination ~= "" and destination ~= "Market:Exterior" and not destination:find("Exterior:", 1, true) then
                        local class = classifyWithReferenceData(destination)
                        if hasDestinationKeyword(destination, destinationRef().tavernKeywords) and not class.military then
                            addCandidate(pools.taverns, seen.taverns, candidate(destination, "tavern", "static_schedule"))
                        end
                        if class.shop and not hasDestinationKeyword(destination, destinationRef().tavernKeywords) then
                            addCandidate(pools.shops, seen.shops, candidate(destination, "shop", "static_schedule"))
                        end
                        if class.religious then
                            addCandidate(pools.religious, seen.religious, candidate(destination, "religious", "static_schedule"))
                        end
                        if class.temple then
                            addCandidate(pools.temples, seen.temples, candidate(destination, "temple", "static_schedule"))
                        end
                        if class.imperialShrine then
                            addCandidate(pools.imperialShrines, seen.imperialShrines, candidate(destination, "imperialShrine", "static_schedule"))
                        end
                        if class.military then
                            addCandidate(pools.military, seen.military, candidate(destination, "military", "static_schedule"))
                        end
                    end
                end
            end
        end
    end
end

function Collector.resolveHome(actor, summary)
    local recordId = summary and summary.recordId or getRecordId(actor)
    local home = nil
    pcall(function()
        local dest = DestinationResolver.findPersonalHome(actor, recordId)
        if dest and dest.destCellName then
            home = dest.destCellName
        end
    end)
    if home and not isGenerationBlacklistedCell(home) then
        return home
    end

    local nativeCell = summary and summary.nativeCell or nil
    if nativeCell and nativeCell ~= "" and not Blacklist.isOutdoorCell(nativeCell) and not Blacklist.isInCity(nativeCell) then
        if not isGenerationBlacklistedCell(nativeCell) then
            return nativeCell
        end
    end
    return nil
end

function Collector.collect(actor, summary)
    local city = summary and summary.city or Collector.getCityForActor(actor)
    if not city then
        return nil, "no_city_context"
    end

    local pools = {
        home = summary and summary.homeCell or nil,
        taverns = {},
        shops = {},
        religious = {},
        temples = {},
        imperialShrines = {},
        military = {},
        exteriorMarket = false,
    }
    local seen = {
        taverns = {},
        shops = {},
        religious = {},
        temples = {},
        imperialShrines = {},
        military = {},
    }

    addTownData(city, pools, seen)
    addStaticScheduleData(city, pools, seen)
    scanDoors(actor, pools, seen)

    for _, poolName in ipairs({ "taverns", "shops", "religious", "temples", "imperialShrines", "military" }) do
        sortPool(pools[poolName])
    end

    return pools, nil
end

return Collector
