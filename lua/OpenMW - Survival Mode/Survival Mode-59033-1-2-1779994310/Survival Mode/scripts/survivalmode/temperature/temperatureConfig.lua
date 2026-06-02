local markup = require('openmw.markup')
local vfs = require('openmw.vfs')
local core = require('openmw.core')
local selfObject = (function()
    local ok, loaded = pcall(require, 'openmw.self')
    if ok then
        return loaded
    end
    return nil
end)()
local types = (function()
    local ok, loaded = pcall(require, 'openmw.types')
    if ok and loaded ~= nil and (type(loaded) == 'table' or type(loaded) == 'userdata') then
        return loaded
    end
    return nil
end)()
local calendar = (function()
    local ok, loaded = pcall(require, 'openmw_aux.calendar')
    if ok and type(loaded) == 'table' then
        return loaded
    end
    return nil
end)()
local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')
local cellInfo = require('scripts.survivalmode.cellInfo')
local heatSourceSystem = require('scripts.survivalmode.temperature.heatSourceSystem')
local regionModifierConfig = temperatureBalanceConfig.regionModifiers
assert(type(regionModifierConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.regionModifiers must be a table.')
local cellTypeModifierConfig = temperatureBalanceConfig.cellTypeModifiers
assert(type(cellTypeModifierConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.cellTypeModifiers must be a table.')
local interiorBaseByRegionConfig = temperatureBalanceConfig.interiorBaseByRegion
assert(type(interiorBaseByRegionConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.interiorBaseByRegion must be a table.')
local seasonalRegionOffsetConfig = temperatureBalanceConfig.seasonalRegionOffsets
assert(type(seasonalRegionOffsetConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.seasonalRegionOffsets must be a table.')
local seasonalTimeOfDayRegionOffsetConfig = temperatureBalanceConfig.seasonalTimeOfDayRegionOffsets
assert(
    type(seasonalTimeOfDayRegionOffsetConfig) == 'table',
    '[SurvivalMode] temperatureBalanceConfig.seasonalTimeOfDayRegionOffsets must be a table.'
)

local REGION_SCAN_PREFIX = 'database/survivalmode/Temperature Regions'
local REGION_SCAN_FALLBACK_PREFIX = 'database'
local REGION_CATEGORIES = {
    'very_hot',
    'hot',
    'warm',
    'neutral',
    'chilly',
    'cold',
    'very_cold',
}
local CATEGORY_FALLBACKS = {
    very_hot = { 'hot', 'warm', 'neutral' },
    hot = { 'very_hot', 'warm', 'neutral' },
    warm = { 'hot', 'neutral', 'chilly' },
    neutral = { 'warm', 'chilly', 'hot', 'cold' },
    chilly = { 'cold', 'neutral', 'warm' },
    cold = { 'very_cold', 'chilly', 'neutral' },
    very_cold = { 'cold', 'chilly', 'neutral' },
}
local CATEGORY_PRIORITY = {
    'very_hot',
    'hot',
    'warm',
    'very_cold',
    'cold',
    'chilly',
    'neutral',
}
local DEFAULT_CATEGORY = 'neutral'
local SECONDS_PER_GAME_DAY = 24 * 60 * 60
local SECONDS_PER_GAME_HOUR = 60 * 60
local MORNING_START_HOUR = 6
local MORNING_END_HOUR = 8
local EVENING_START_HOUR = 19
local EVENING_END_HOUR = 21
local NIGHT_START_HOUR = 22
local NIGHT_END_HOUR = 5
local DAY_ANCHOR_HOUR = ((MORNING_END_HOUR + 1) + (EVENING_START_HOUR - 1)) / 2
local VOLCANIC_CELL_TYPE_KEY = 'volcanic'
local VOLCANIC_BASE_REGION_CATEGORY = 'very_hot'
local cachedSeasonGameDay = nil
local cachedSeasonValue = nil
local cachedTimeOfDayGameMinute = nil
local cachedTimeOfDayValue = nil
local ARMOR_WEIGHT_CLASS_BY_SLOT = {
    boots = {
        lightMax = 12.0,
        heavyMinExclusive = 18.0,
    },
    cuirass = {
        lightMax = 18.0,
        heavyMinExclusive = 27.0,
    },
    greaves = {
        lightMax = 9.0,
        heavyMinExclusive = 13.5,
    },
    helmet = {
        lightMax = 3.0,
        heavyMinExclusive = 4.5,
    },
    gauntlet = {
        lightMax = 3.0,
        heavyMinExclusive = 4.5,
    },
    pauldron = {
        lightMax = 6.0,
        heavyMinExclusive = 9.0,
    },
}

local cachedRegionSets = nil
local cachedLoadedFileCount = 0
local cachedExteriorRegionCategory = nil
local cachedExteriorMatchedRegionName = nil
local cachedTraversalRegionCandidatesByCell = {}
local loggedTraversalTraceByCell = {}
local INTERIOR_EXTERIOR_TRAVERSAL_MAX_DEPTH = 48
local TEMPERATURE_TRAVERSAL_DEBUG_LOG = false

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    return string.lower(trim(tostring(value or '')))
end

local function lerp(startValue, endValue, factor)
    local t = math.min(1, math.max(0, tonumber(factor) or 0))
    local startNumber = tonumber(startValue) or 0
    local endNumber = tonumber(endValue) or 0
    return startNumber + ((endNumber - startNumber) * t)
end

local function smoothstep(factor)
    local t = math.min(1, math.max(0, tonumber(factor) or 0))
    return t * t * (3 - (2 * t))
end

local function normalizeStructureKey(value)
    local normalized = normalizeKey(value)
    normalized = normalized:gsub('[^%w]+', '')
    return normalized
end

local function normalizeRegionName(value)
    local normalized = normalizeKey(value)
    normalized = normalized:gsub('[%._%-:]+', ' ')
    normalized = normalized:gsub("'", '')
    normalized = normalized:gsub('[^%w%s]+', ' ')
    normalized = normalized:gsub('%s+', ' ')
    normalized = trim(normalized)
    return normalized
end

local function addRegionToken(targetSet, token)
    if type(targetSet) ~= 'table' then
        return 0
    end

    local normalized = normalizeRegionName(token)
    if normalized == '' then
        return 0
    end
    if targetSet[normalized] == true then
        return 0
    end

    targetSet[normalized] = true
    return 1
end

local function addRegionTokenVariants(targetSet, rawToken)
    local added = 0
    local normalized = normalizeRegionName(rawToken)
    if normalized == '' then
        return 0
    end

    added = added + addRegionToken(targetSet, normalized)
    local compact = normalizeStructureKey(normalized)
    if compact ~= '' then
        added = added + addRegionToken(targetSet, compact)
    end

    local withoutRegionSuffix = normalized:gsub('%s+region$', '')
    if withoutRegionSuffix ~= normalized and withoutRegionSuffix ~= '' then
        added = added + addRegionToken(targetSet, withoutRegionSuffix)
        local withoutRegionSuffixCompact = normalizeStructureKey(withoutRegionSuffix)
        if withoutRegionSuffixCompact ~= '' then
            added = added + addRegionToken(targetSet, withoutRegionSuffixCompact)
        end
    end

    local withoutRegionPrefix = normalized:gsub('^region%s+', '')
    if withoutRegionPrefix ~= normalized and withoutRegionPrefix ~= '' then
        added = added + addRegionToken(targetSet, withoutRegionPrefix)
        local withoutRegionPrefixCompact = normalizeStructureKey(withoutRegionPrefix)
        if withoutRegionPrefixCompact ~= '' then
            added = added + addRegionToken(targetSet, withoutRegionPrefixCompact)
        end
    end

    return added
end

local function isYamlPath(filePath)
    local normalizedPath = normalizeKey(filePath):gsub('\\', '/')
    return normalizedPath:match('%.yaml$') ~= nil or normalizedPath:match('%.yml$') ~= nil
end

local function addRegionName(regionSet, value)
    if type(value) ~= 'string' then
        return 0
    end

    return addRegionTokenVariants(regionSet, value)
end

local function addRegionNamesFromEntries(regionSet, entries)
    if type(entries) ~= 'table' then
        return 0
    end

    local added = 0
    for _, entry in ipairs(entries) do
        if type(entry) == 'string' then
            added = added + addRegionName(regionSet, entry)
        elseif type(entry) == 'table' then
            added = added + addRegionName(regionSet, entry.id)
            added = added + addRegionName(regionSet, entry.name)
            if type(entry.ids) == 'table' then
                added = added + addRegionNamesFromEntries(regionSet, entry.ids)
            end
            if type(entry.names) == 'table' then
                added = added + addRegionNamesFromEntries(regionSet, entry.names)
            end
        end
    end

    return added
end

local function findCaseInsensitiveTableField(container, expectedKey)
    if type(container) ~= 'table' then
        return nil
    end

    local expected = normalizeStructureKey(expectedKey)
    for key, value in pairs(container) do
        if normalizeStructureKey(key) == expected then
            return value
        end
    end

    return nil
end

local function loadCategoryRegions(container, categoryName, targetSet)
    local category = findCaseInsensitiveTableField(container, categoryName)
    if type(category) ~= 'table' then
        return false, 0
    end

    local loaded = false
    local added = 0

    if type(category.ids) == 'table' then
        loaded = true
        added = added + addRegionNamesFromEntries(targetSet, category.ids)
    end

    if type(category.names) == 'table' then
        loaded = true
        added = added + addRegionNamesFromEntries(targetSet, category.names)
    end

    if #category > 0 then
        loaded = true
        added = added + addRegionNamesFromEntries(targetSet, category)
    end

    return loaded, added
end

local function loadTemperatureRegionYamlFile(filePath, regionSets)
    if type(markup.loadYaml) ~= 'function' then
        print('[SurvivalMode] openmw.markup.loadYaml is unavailable.')
        return false
    end

    local ok, data = pcall(markup.loadYaml, filePath)
    if not ok then
        print(string.format('[SurvivalMode] Failed to parse temperature yaml "%s": %s', filePath, tostring(data)))
        return false
    end

    if type(data) ~= 'table' then
        return false
    end

    local container = findCaseInsensitiveTableField(data, 'Temperature Regions')
    if type(container) ~= 'table' then
        container = data
    end

    local hasSupportedField = false
    local addedTotal = 0

    for _, category in ipairs(REGION_CATEGORIES) do
        local loaded, added = loadCategoryRegions(container, category, regionSets[category])
        if loaded then
            hasSupportedField = true
            addedTotal = addedTotal + added
        end
    end

    if not hasSupportedField then
        return false
    end

    if addedTotal == 0 then
        print(string.format('[SurvivalMode] Temperature yaml has no valid region names: %s', filePath))
    end

    return true
end

local function buildRegionSets()
    local regionSets = {}
    for _, category in ipairs(REGION_CATEGORIES) do
        regionSets[category] = {}
    end

    if type(vfs.pathsWithPrefix) ~= 'function' then
        print('[SurvivalMode] openmw.vfs.pathsWithPrefix is unavailable.')
        return regionSets, 0
    end

    local function scanPrefix(prefix)
        local normalizedPrefix = normalizeKey(prefix):gsub('\\', '/')
        if normalizedPrefix == '' then
            return 0
        end

        local loaded = 0
        for filePath in vfs.pathsWithPrefix(prefix) do
            if isYamlPath(filePath) and loadTemperatureRegionYamlFile(filePath, regionSets) then
                loaded = loaded + 1
            end
        end
        return loaded
    end

    local loadedFiles = scanPrefix(REGION_SCAN_PREFIX)
    if loadedFiles == 0 then
        loadedFiles = loadedFiles + scanPrefix(REGION_SCAN_FALLBACK_PREFIX)
    end

    if loadedFiles == 0 then
        print(string.format(
            '[SurvivalMode] No temperature region sources found under "%s" (fallback: "%s")',
            tostring(REGION_SCAN_PREFIX),
            tostring(REGION_SCAN_FALLBACK_PREFIX)
        ))
    end

    return regionSets, loadedFiles
end

local function ensureRegionSets()
    if cachedRegionSets ~= nil then
        return cachedRegionSets
    end

    cachedRegionSets, cachedLoadedFileCount = buildRegionSets()
    return cachedRegionSets
end

local function addCandidate(candidates, value)
    if type(value) == 'string' then
        addRegionTokenVariants(candidates, value)
        return
    end

    if type(value) ~= 'table' and type(value) ~= 'userdata' then
        return
    end

    local fields = {
        'id',
        'name',
        'region',
        'regionId',
        'regionName',
        'recordId',
    }

    for _, fieldName in ipairs(fields) do
        local ok, fieldValue = pcall(function()
            return value[fieldName]
        end)
        if ok and type(fieldValue) == 'string' then
            addCandidate(candidates, fieldValue)
        end
    end
end

local function getCellRegionCandidates(cell)
    local candidates = {}
    if cell == nil then
        return candidates
    end

    local fieldNames = {
        'region',
        'regionId',
        'regionName',
        'name',
        'id',
    }

    for _, fieldName in ipairs(fieldNames) do
        local ok, fieldValue = pcall(function()
            return cell[fieldName]
        end)
        if ok then
            addCandidate(candidates, fieldValue)
        end
    end

    return candidates
end

local function logTraversalDebug(message)
    if TEMPERATURE_TRAVERSAL_DEBUG_LOG ~= true then
        return
    end
    print(string.format('[SurvivalMode][TempTraversal] %s', tostring(message)))
end

local function describeCell(cell)
    if cell == nil then
        return '<nil>'
    end

    local cellId = ''
    pcall(function()
        cellId = trim(tostring(cell.id or ''))
    end)
    if cellId ~= '' then
        return cellId
    end

    local gridX = nil
    local gridY = nil
    pcall(function()
        gridX = tonumber(cell.gridX)
        gridY = tonumber(cell.gridY)
    end)
    if gridX ~= nil and gridY ~= nil then
        return string.format('<exterior:%d,%d>', math.floor(gridX), math.floor(gridY))
    end

    return '<unknown>'
end

local function getTraversalCacheKey(cell)
    if cell == nil then
        return ''
    end

    local cellId = ''
    pcall(function()
        cellId = normalizeKey(trim(tostring(cell.id or '')))
    end)
    if cellId ~= '' then
        return cellId
    end

    local gridX = nil
    local gridY = nil
    pcall(function()
        gridX = tonumber(cell.gridX)
        gridY = tonumber(cell.gridY)
    end)
    if gridX ~= nil and gridY ~= nil then
        return string.format('grid:%d:%d', math.floor(gridX), math.floor(gridY))
    end

    return ''
end

local function isExteriorLikeCell(cell)
    if cell == nil then
        return false
    end

    local isExterior = false
    local exteriorOk = pcall(function()
        isExterior = cell.isExterior == true
    end)
    if exteriorOk and isExterior then
        return true
    end

    local hasSky = false
    pcall(function()
        hasSky = cell.hasSky == true
    end)
    if hasSky ~= true or type(cell.hasTag) ~= 'function' then
        return false
    end

    local isQuasiExterior = false
    local tagOk = pcall(function()
        isQuasiExterior = cell:hasTag('QuasiExterior') == true
    end)
    return tagOk and isQuasiExterior == true
end

local function collectTraversalDestinations(cell, doorType, trace)
    local destinations = {}
    if cell == nil
        or type(cell.getAll) ~= 'function'
        or doorType == nil
        or (type(doorType) ~= 'table' and type(doorType) ~= 'userdata') then
        return destinations
    end

    local ok, doors = pcall(function()
        return cell:getAll(doorType)
    end)
    if not ok or doors == nil then
        return destinations
    end

    local function addDoor(door)
        if door == nil then
            return
        end

        trace.scannedDoors = trace.scannedDoors + 1

        local isTeleport = false
        if type(doorType.isTeleport) == 'function' then
            pcall(function()
                isTeleport = doorType.isTeleport(door) == true
            end)
        else
            pcall(function()
                isTeleport = door.isTeleport == true or door.teleport == true
            end)
        end
        if isTeleport ~= true then
            return
        end
        trace.teleportDoors = trace.teleportDoors + 1

        local destCell = nil
        if type(doorType.destCell) == 'function' then
            pcall(function()
                destCell = doorType.destCell(door)
            end)
        end
        if destCell == nil then
            pcall(function()
                destCell = door.destCell
            end)
        end
        if destCell == nil then
            return
        end

        local destPosition = nil
        if type(doorType.destPosition) == 'function' then
            pcall(function()
                destPosition = doorType.destPosition(door)
            end)
        end
        if destPosition == nil then
            pcall(function()
                destPosition = door.destPosition
            end)
        end

        destinations[#destinations + 1] = {
            cell = destCell,
            position = destPosition,
        }
        trace.destinationLinks = trace.destinationLinks + 1
    end

    local scanned = 0
    local ipairsOk = pcall(function()
        for _, door in ipairs(doors) do
            scanned = scanned + 1
            addDoor(door)
        end
    end)
    if not ipairsOk or scanned == 0 then
        pcall(function()
            for _, door in pairs(doors) do
                addDoor(door)
            end
        end)
    end

    return destinations
end

local function findTraversalExteriorRegionCandidates(startCell)
    local trace = {
        start = describeCell(startCell),
        reason = '',
        visitedCells = 0,
        scannedDoors = 0,
        teleportDoors = 0,
        destinationLinks = 0,
        depth = 0,
        matchCell = '',
        matchRegion = '',
    }
    if startCell == nil then
        trace.reason = 'start_cell_nil'
        return {}, trace
    end

    local resolvedTypes = types
    if resolvedTypes == nil then
        local globalTypes = rawget(_G, 'types')
        if globalTypes ~= nil and (type(globalTypes) == 'table' or type(globalTypes) == 'userdata') then
            resolvedTypes = globalTypes
        end
    end

    local doorType = nil
    if resolvedTypes ~= nil and (type(resolvedTypes) == 'table' or type(resolvedTypes) == 'userdata') then
        doorType = resolvedTypes.Door
    end
    if doorType == nil or (type(doorType) ~= 'table' and type(doorType) ~= 'userdata') then
        trace.reason = 'door_type_missing'
        return {}, trace
    end

    local queue = {
        { cell = startCell, depth = 0 },
    }
    local nextIndex = 1
    local traversed = {}

    while nextIndex <= #queue do
        local current = queue[nextIndex]
        nextIndex = nextIndex + 1

        local currentCell = current.cell
        local currentDepth = tonumber(current.depth) or 0
        if currentDepth > trace.depth then
            trace.depth = currentDepth
        end

        local visitKey = getTraversalCacheKey(currentCell)
        if visitKey ~= '' and traversed[visitKey] ~= true then
            traversed[visitKey] = true
            trace.visitedCells = trace.visitedCells + 1

            if isExteriorLikeCell(currentCell) then
                local foundCandidates = getCellRegionCandidates(currentCell)
                if next(foundCandidates) ~= nil then
                    trace.reason = 'matched_exterior'
                    trace.matchCell = describeCell(currentCell)
                    for name, _ in pairs(foundCandidates) do
                        trace.matchRegion = name
                        break
                    end
                    return foundCandidates, trace
                end
            end

            if currentDepth < INTERIOR_EXTERIOR_TRAVERSAL_MAX_DEPTH then
                local destinations = collectTraversalDestinations(currentCell, doorType, trace)
                for _, destination in ipairs(destinations) do
                    local destinationCell = destination.cell
                    local destinationKey = getTraversalCacheKey(destinationCell)
                    if destinationKey ~= '' and traversed[destinationKey] ~= true then
                        queue[#queue + 1] = {
                            cell = destinationCell,
                            depth = currentDepth + 1,
                        }
                    end
                end
            end
        end
    end

    trace.reason = 'no_reachable_exterior'
    return {}, trace
end

local function addTraversalRegionCandidates(candidates, cell)
    if type(candidates) ~= 'table' then
        return
    end

    local cacheKey = getTraversalCacheKey(cell)
    if cacheKey == '' then
        return
    end

    local cached = cachedTraversalRegionCandidatesByCell[cacheKey]
    local trace = nil
    if type(cached) ~= 'table' then
        cached, trace = findTraversalExteriorRegionCandidates(cell)
        if type(cached) ~= 'table' then
            cached = {}
        end
        cachedTraversalRegionCandidatesByCell[cacheKey] = cached
    end

    for name, _ in pairs(cached) do
        addCandidate(candidates, name)
    end

    if trace ~= nil and loggedTraversalTraceByCell[cacheKey] ~= true then
        loggedTraversalTraceByCell[cacheKey] = true
        logTraversalDebug(string.format(
            'cell="%s" reason="%s" visited=%d doors=%d teleport=%d links=%d depth=%d matchCell="%s" matchRegion="%s"',
            tostring(trace.start or ''),
            tostring(trace.reason or ''),
            tonumber(trace.visitedCells) or 0,
            tonumber(trace.scannedDoors) or 0,
            tonumber(trace.teleportDoors) or 0,
            tonumber(trace.destinationLinks) or 0,
            tonumber(trace.depth) or 0,
            tostring(trace.matchCell or ''),
            tostring(trace.matchRegion or '')
        ))
    end
end

local function addRuntimeRegionCandidates(candidates, latestInfo)
    if type(candidates) ~= 'table' or type(latestInfo) ~= 'table' then
        return
    end

    local candidateFields = {
        'region',
        'regionId',
        'regionName',
        'exteriorRegion',
        'exteriorRegionId',
        'exteriorRegionName',
    }
    for _, fieldName in ipairs(candidateFields) do
        addCandidate(candidates, latestInfo[fieldName])
    end
end

local function classifyCandidates(candidates, regionSets)
    for _, category in ipairs(CATEGORY_PRIORITY) do
        local categorySet = regionSets[category]
        if type(categorySet) == 'table' then
            for name, _ in pairs(candidates) do
                if categorySet[name] == true then
                    return category, name, true
                end
            end
        end
    end

    return DEFAULT_CATEGORY, nil, false
end

local function getRegionModifierValue(categoryName)
    local category = normalizeKey(categoryName)
    local configured = tonumber(regionModifierConfig[category])
    if configured ~= nil then
        return configured
    end

    local fallbacks = CATEGORY_FALLBACKS[category]
    if type(fallbacks) == 'table' then
        for _, fallbackCategory in ipairs(fallbacks) do
            configured = tonumber(regionModifierConfig[fallbackCategory])
            if configured ~= nil then
                return configured
            end
        end
    end
    configured = tonumber(regionModifierConfig[DEFAULT_CATEGORY])
    assert(configured ~= nil, string.format(
        '[SurvivalMode] temperatureBalanceConfig.regionModifiers.%s must be a number.',
        tostring(DEFAULT_CATEGORY)
    ))
    return configured
end

local function getInteriorBaseValueByCategory(categoryName)
    local category = normalizeKey(categoryName)
    if category == '' then
        return nil
    end

    return tonumber(interiorBaseByRegionConfig[category])
end

local function getInteriorBaseMultiplierValue(categoryName)
    local category = normalizeKey(categoryName)
    if category == '' then
        category = DEFAULT_CATEGORY
    end

    local configured = getInteriorBaseValueByCategory(category)
    if configured ~= nil then
        return configured
    end

    local fallbacks = CATEGORY_FALLBACKS[category]
    if type(fallbacks) == 'table' then
        for _, fallbackCategory in ipairs(fallbacks) do
            configured = getInteriorBaseValueByCategory(fallbackCategory)
            if configured ~= nil then
                return configured
            end
        end
    end

    configured = getInteriorBaseValueByCategory(DEFAULT_CATEGORY)
    assert(configured ~= nil, string.format(
        '[SurvivalMode] temperatureBalanceConfig.interiorBaseByRegion.%s must be a number.',
        tostring(DEFAULT_CATEGORY)
    ))
    return configured
end

local function getCellTypeModifierTableForCategory(categoryName)
    local category = normalizeKey(categoryName)
    if category == 'chilly' or category == 'cold' or category == 'very_cold' then
        local coldTable = cellTypeModifierConfig.chillyToFreezing
        if type(coldTable) == 'table' then
            return coldTable
        end
    else
        local warmTable = cellTypeModifierConfig.neutralToScorching
        if type(warmTable) == 'table' then
            return warmTable
        end
    end

    error(string.format(
        '[SurvivalMode] Missing cell type modifier table for category "%s".',
        tostring(categoryName)
    ))
end

local function getCellTypeModifierValue(cellTypeKey, categoryName)
    local normalizedType = normalizeKey(cellTypeKey)
    if normalizedType == '' then
        normalizedType = 'interior'
    end

    local modifierTable = getCellTypeModifierTableForCategory(categoryName)
    local defaultValue = tonumber(modifierTable[normalizedType])
    if defaultValue == nil and normalizedType ~= 'interior' then
        defaultValue = tonumber(modifierTable.interior)
    end
    assert(defaultValue ~= nil, string.format(
        '[SurvivalMode] Missing cell type modifier for "%s" in category "%s".',
        tostring(normalizedType),
        tostring(categoryName)
    ))
    return defaultValue
end

local function getCurrentSeason()
    if type(core.getGameTime) ~= 'function' then
        return nil
    end

    local gameTimeSeconds = math.max(0, tonumber(core.getGameTime()) or 0)
    local gameDay = math.floor(gameTimeSeconds / SECONDS_PER_GAME_DAY)
    if cachedSeasonGameDay ~= nil and cachedSeasonGameDay == gameDay and cachedSeasonValue ~= nil then
        return cachedSeasonValue
    end

    local monthIndex = nil
    if calendar ~= nil and type(calendar.formatGameTime) == 'function' then
        local dateTable = calendar.formatGameTime('*t', gameTimeSeconds)
        if type(dateTable) == 'table' then
            monthIndex = tonumber(dateTable.month)
        end
        if monthIndex == nil then
            monthIndex = tonumber(calendar.formatGameTime('%m', gameTimeSeconds))
        end
    end

    if monthIndex == nil then
        return nil
    end

    monthIndex = math.floor(monthIndex)
    if monthIndex < 1 or monthIndex > 12 then
        return nil
    end
    local season = 'spring'
    if monthIndex == 12 or monthIndex <= 2 then
        season = 'winter'
    elseif monthIndex >= 3 and monthIndex <= 5 then
        season = 'spring'
    elseif monthIndex >= 6 and monthIndex <= 8 then
        season = 'summer'
    elseif monthIndex >= 9 and monthIndex <= 11 then
        season = 'autumn'
    end

    cachedSeasonGameDay = gameDay
    cachedSeasonValue = season
    return season
end

local function getCurrentHourOfDay()
    if type(core.getGameTime) ~= 'function' then
        return nil
    end

    local gameTimeSeconds = math.max(0, tonumber(core.getGameTime()) or 0)
    local gameMinute = math.floor(gameTimeSeconds / 60)
    if cachedTimeOfDayGameMinute ~= nil and cachedTimeOfDayGameMinute == gameMinute and cachedTimeOfDayValue ~= nil then
        return cachedTimeOfDayValue
    end

    local hour = (gameTimeSeconds / SECONDS_PER_GAME_HOUR) % 24
    if hour < 0 or hour >= 24 then
        return nil
    end

    cachedTimeOfDayGameMinute = gameMinute
    cachedTimeOfDayValue = hour
    return hour
end

local function getCurrentTimeOfDay()
    local hour = getCurrentHourOfDay()
    if hour == nil then
        return nil
    end

    if hour >= MORNING_START_HOUR and hour <= MORNING_END_HOUR then
        return 'morning'
    end

    if hour >= EVENING_START_HOUR and hour <= EVENING_END_HOUR then
        return 'evening'
    end

    if hour >= NIGHT_START_HOUR or hour <= NIGHT_END_HOUR then
        return 'night'
    end

    return 'day'
end

local function getSeasonalOffset(categoryName, seasonName)
    local category = normalizeKey(categoryName)
    local season = normalizeKey(seasonName)
    if season == '' or category == '' then
        return 0
    end

    local seasonTable = seasonalRegionOffsetConfig[season]
    assert(type(seasonTable) == 'table', string.format(
        '[SurvivalMode] temperatureBalanceConfig.seasonalRegionOffsets.%s must be a table.',
        tostring(season)
    ))

    local configured = tonumber(seasonTable[category])
    if configured ~= nil then
        return configured
    end

    local fallbacks = CATEGORY_FALLBACKS[category]
    if type(fallbacks) == 'table' then
        for _, fallbackCategory in ipairs(fallbacks) do
            configured = tonumber(seasonTable[fallbackCategory])
            if configured ~= nil then
                return configured
            end
        end
    end

    configured = tonumber(seasonTable[DEFAULT_CATEGORY])
    assert(configured ~= nil, string.format(
        '[SurvivalMode] temperatureBalanceConfig.seasonalRegionOffsets.%s.%s must be a number.',
        tostring(season),
        tostring(DEFAULT_CATEGORY)
    ))
    return configured
end

local function getConfiguredTimeOfDaySeasonalOffset(categoryName, seasonName, timeOfDayName)
    local category = normalizeKey(categoryName)
    local season = normalizeKey(seasonName)
    local timeOfDay = normalizeKey(timeOfDayName)
    if season == '' or category == '' or timeOfDay == '' then
        return 0
    end

    local seasonTable = seasonalTimeOfDayRegionOffsetConfig[season]
    assert(type(seasonTable) == 'table', string.format(
        '[SurvivalMode] temperatureBalanceConfig.seasonalTimeOfDayRegionOffsets.%s must be a table.',
        tostring(season)
    ))

    local timeOfDayTable = seasonTable[timeOfDay]
    assert(type(timeOfDayTable) == 'table', string.format(
        '[SurvivalMode] temperatureBalanceConfig.seasonalTimeOfDayRegionOffsets.%s.%s must be a table.',
        tostring(season),
        tostring(timeOfDay)
    ))

    local configured = tonumber(timeOfDayTable[category])
    if configured ~= nil then
        return configured
    end

    local fallbacks = CATEGORY_FALLBACKS[category]
    if type(fallbacks) == 'table' then
        for _, fallbackCategory in ipairs(fallbacks) do
            configured = tonumber(timeOfDayTable[fallbackCategory])
            if configured ~= nil then
                return configured
            end
        end
    end

    configured = tonumber(timeOfDayTable[DEFAULT_CATEGORY])
    assert(configured ~= nil, string.format(
        '[SurvivalMode] temperatureBalanceConfig.seasonalTimeOfDayRegionOffsets.%s.%s.%s must be a number.',
        tostring(season),
        tostring(timeOfDay),
        tostring(DEFAULT_CATEGORY)
    ))
    return configured
end

local function getTimeOfDaySeasonalOffset(categoryName, seasonName, hourOfDay)
    local hour = tonumber(hourOfDay)
    local season = normalizeKey(seasonName)
    local category = normalizeKey(categoryName)
    if hour == nil or season == '' or category == '' then
        return 0
    end

    local normalizedHour = hour % 24
    if normalizedHour < 0 then
        normalizedHour = normalizedHour + 24
    end
    if normalizedHour < MORNING_START_HOUR then
        normalizedHour = normalizedHour + 24
    end

    local anchors = {
        {
            hour = MORNING_START_HOUR,
            value = getConfiguredTimeOfDaySeasonalOffset(category, season, 'night'),
        },
        {
            hour = MORNING_END_HOUR,
            value = getConfiguredTimeOfDaySeasonalOffset(category, season, 'morning'),
        },
        {
            hour = DAY_ANCHOR_HOUR,
            value = 0,
        },
        {
            hour = EVENING_START_HOUR,
            value = 0,
        },
        {
            hour = EVENING_END_HOUR,
            value = getConfiguredTimeOfDaySeasonalOffset(category, season, 'evening'),
        },
        {
            hour = NIGHT_START_HOUR,
            value = getConfiguredTimeOfDaySeasonalOffset(category, season, 'night'),
        },
        {
            hour = MORNING_START_HOUR + 24,
            value = getConfiguredTimeOfDaySeasonalOffset(category, season, 'night'),
        },
    }

    for index = 1, #anchors - 1 do
        local currentAnchor = anchors[index]
        local nextAnchor = anchors[index + 1]
        if normalizedHour >= currentAnchor.hour and normalizedHour <= nextAnchor.hour then
            local span = nextAnchor.hour - currentAnchor.hour
            if span <= 0 then
                return tonumber(currentAnchor.value) or 0
            end

            local transitionFactor = smoothstep((normalizedHour - currentAnchor.hour) / span)
            return lerp(currentAnchor.value, nextAnchor.value, transitionFactor)
        end
    end

    return 0
end

local function getModifiersForCell(cell, options)
    local regionSets = ensureRegionSets()
    local resolvedCellInfo = cellInfo.getLatestForCell(cell)
    local cellTypeKey = 'interior'
    local cellTypeLabel = 'Interior'
    local scannedStaticCount = 0
    local topScoreType = ''
    local topScoreValue = 0
    if type(resolvedCellInfo) == 'table' then
        local detectedType = normalizeKey(resolvedCellInfo.typeKey)
        if detectedType ~= '' then
            cellTypeKey = detectedType
        end
        local detectedLabel = trim(tostring(resolvedCellInfo.typeLabel or ''))
        if detectedLabel ~= '' then
            cellTypeLabel = detectedLabel
        end
        scannedStaticCount = math.max(
            0,
            tonumber(resolvedCellInfo.scannedObjectCount)
                or tonumber(resolvedCellInfo.scannedStaticCount)
                or 0
        )
        topScoreType = normalizeKey(resolvedCellInfo.topScoreType)
        topScoreValue = tonumber(resolvedCellInfo.topScoreValue) or 0
    end
    local isExteriorCell = normalizeKey(cellTypeKey) == 'exterior'

    local candidates = getCellRegionCandidates(cell)
    addRuntimeRegionCandidates(candidates, resolvedCellInfo)
    if not isExteriorCell then
        addTraversalRegionCandidates(candidates, cell)
    end
    local category, matchedRegionName, hasMatchedRegion = classifyCandidates(candidates, regionSets)
    if isExteriorCell and hasMatchedRegion then
        cachedExteriorRegionCategory = category
        cachedExteriorMatchedRegionName = matchedRegionName
    elseif not hasMatchedRegion and cachedExteriorRegionCategory ~= nil then
        category = cachedExteriorRegionCategory
        matchedRegionName = cachedExteriorMatchedRegionName
        hasMatchedRegion = true
    end

    local details = type(options) == 'table' and options or {}
    local seasonalVariationsEnabled = details.seasonalVariationsEnabled == true

    local regionBaseModifier = getRegionModifierValue(category)
    local exteriorRegionSignedModifier = regionBaseModifier
    local interiorBaseMultiplier = 0
    local season = nil
    local seasonalOffset = 0
    local timeOfDay = nil
    local timeOfDaySeasonalOffset = 0
    if seasonalVariationsEnabled then
        season = getCurrentSeason()
        local currentHourOfDay = getCurrentHourOfDay()
        seasonalOffset = getSeasonalOffset(category, season)
        timeOfDay = getCurrentTimeOfDay()
        timeOfDaySeasonalOffset = getTimeOfDaySeasonalOffset(category, season, currentHourOfDay)
    end
    exteriorRegionSignedModifier = exteriorRegionSignedModifier + seasonalOffset + timeOfDaySeasonalOffset
    if not isExteriorCell then
        interiorBaseMultiplier = getInteriorBaseMultiplierValue(category)
    end
    local usesVolcanicBaseOverride = (not isExteriorCell) and normalizeKey(cellTypeKey) == VOLCANIC_CELL_TYPE_KEY
    if usesVolcanicBaseOverride then
        interiorBaseMultiplier = getInteriorBaseMultiplierValue(VOLCANIC_BASE_REGION_CATEGORY)
    end
    local regionSignedModifier = 0
    local interiorBaseSignedModifier = 0
    if isExteriorCell then
        regionSignedModifier = exteriorRegionSignedModifier
    else
        if usesVolcanicBaseOverride then
            interiorBaseSignedModifier = getRegionModifierValue(VOLCANIC_BASE_REGION_CATEGORY) * interiorBaseMultiplier
        else
            interiorBaseSignedModifier = exteriorRegionSignedModifier * interiorBaseMultiplier
        end
    end
    local regionWarmModifier = 0
    local regionColdModifier = 0
    if regionSignedModifier > 0 then
        regionWarmModifier = regionSignedModifier
    elseif regionSignedModifier < 0 then
        regionColdModifier = regionSignedModifier
    end
    local interiorBaseWarmModifier = 0
    local interiorBaseColdModifier = 0
    if interiorBaseSignedModifier > 0 then
        interiorBaseWarmModifier = interiorBaseSignedModifier
    elseif interiorBaseSignedModifier < 0 then
        interiorBaseColdModifier = interiorBaseSignedModifier
    end

    local cellTypeSignedModifier = getCellTypeModifierValue(cellTypeKey, category)
    local cellTypeWarmModifier = 0
    local cellTypeColdModifier = 0
    if cellTypeSignedModifier > 0 then
        cellTypeWarmModifier = cellTypeSignedModifier
    elseif cellTypeSignedModifier < 0 then
        cellTypeColdModifier = cellTypeSignedModifier
    end

    local campfireData = nil
    local scanDiagnostics = {}
    local runtimeCampfireSources = type(resolvedCellInfo) == 'table' and resolvedCellInfo.campfireSources or nil
    local runtimeCampfireSampleReady = type(resolvedCellInfo) == 'table' and resolvedCellInfo.campfireSampleReady == true
    local runtimeCampfireSourceSnapshotStamp = type(resolvedCellInfo) == 'table'
        and normalizeKey(resolvedCellInfo.campfireSourceSnapshotStamp)
        or ''
    local runtimeCellCacheKey = ''
    if type(resolvedCellInfo) == 'table' then
        runtimeCellCacheKey = normalizeKey(resolvedCellInfo.cellCacheKey)
        if runtimeCellCacheKey == '' then
            runtimeCellCacheKey = normalizeKey(resolvedCellInfo.cellId)
        end
    end
    if type(heatSourceSystem.getCampfireModifierForCachedSources) == 'function'
        and runtimeCampfireSampleReady
        and type(runtimeCampfireSources) == 'table' then
        local playerPosition = nil
        if selfObject ~= nil then
            pcall(function()
                playerPosition = selfObject.position
            end)
        end
        campfireData = heatSourceSystem.getCampfireModifierForCachedSources(runtimeCampfireSources, playerPosition, {
            regionCategory = category,
            isExteriorCell = isExteriorCell,
            cellTypeSignedModifier = cellTypeSignedModifier,
            cellCacheKey = runtimeCellCacheKey,
            sourceSnapshotStamp = runtimeCampfireSourceSnapshotStamp,
        })
        scanDiagnostics = {
            activatorScanned = math.max(0, tonumber(resolvedCellInfo.campfireScanActivatorScanned) or 0),
            activatorMatched = math.max(0, tonumber(resolvedCellInfo.campfireScanActivatorMatched) or 0),
            lightScanned = math.max(0, tonumber(resolvedCellInfo.campfireScanLightScanned) or 0),
            lightMatched = math.max(0, tonumber(resolvedCellInfo.campfireScanLightMatched) or 0),
            staticScanned = math.max(0, tonumber(resolvedCellInfo.campfireScanStaticScanned) or 0),
            staticMatched = math.max(0, tonumber(resolvedCellInfo.campfireScanStaticMatched) or 0),
            getAllFailures = type(resolvedCellInfo.campfireScanFailures) == 'table'
                and resolvedCellInfo.campfireScanFailures
                or {},
        }
    else
        campfireData = {
            warmModifier = 0,
            sourceCount = 0,
            activeSourceCount = 0,
            nearestDistance = nil,
            baseWarmModifier = 0,
            interiorMultiplier = 1.0,
            nearestRecordId = '',
            dominantSourceType = '',
            dryingMultiplier = 1.0,
            dryingSourceType = 'none',
        }
        scanDiagnostics = {
            activatorScanned = 0,
            activatorMatched = 0,
            lightScanned = 0,
            lightMatched = 0,
            staticScanned = 0,
            staticMatched = 0,
            getAllFailures = {},
        }
    end

    local campfireWarmModifier = math.max(0, tonumber(campfireData.warmModifier) or 0)
    local campfireSourceCount = math.max(0, tonumber(campfireData.sourceCount) or 0)
    local campfireActiveSourceCount = math.max(0, tonumber(campfireData.activeSourceCount) or 0)
    local campfireNearestDistance = tonumber(campfireData.nearestDistance)
    local campfireBaseWarmModifier = math.max(0, tonumber(campfireData.baseWarmModifier) or 0)
    local campfireInteriorMultiplier = math.max(0, tonumber(campfireData.interiorMultiplier) or 1.0)
    local campfireNearestRecordId = normalizeKey(campfireData.nearestRecordId)
    local campfireDominantSourceType = normalizeKey(campfireData.dominantSourceType)
    local campfireDryingMultiplier = math.max(1.0, tonumber(campfireData.dryingMultiplier) or 1.0)
    local campfireDryingSourceType = normalizeKey(campfireData.dryingSourceType)

    local signedModifier = regionSignedModifier + interiorBaseSignedModifier + cellTypeSignedModifier + campfireWarmModifier
    local warmModifier = 0
    local coldModifier = 0

    if signedModifier > 0 then
        warmModifier = signedModifier
    elseif signedModifier < 0 then
        coldModifier = signedModifier
    end

    local totalModifier = warmModifier + coldModifier

    return {
        warmModifier = warmModifier,
        coldModifier = coldModifier,
        totalModifier = totalModifier,
        category = category,
        matchedRegionName = matchedRegionName,
        hasMatchedRegion = hasMatchedRegion,
        baseModifier = isExteriorCell and regionBaseModifier or interiorBaseMultiplier,
        isExteriorCell = isExteriorCell,
        usesInteriorBase = not isExteriorCell,
        regionBaseModifier = regionBaseModifier,
        exteriorRegionSignedModifier = exteriorRegionSignedModifier,
        interiorBaseMultiplier = interiorBaseMultiplier,
        regionSignedModifier = regionSignedModifier,
        regionWarmModifier = regionWarmModifier,
        regionColdModifier = regionColdModifier,
        interiorBaseSignedModifier = interiorBaseSignedModifier,
        interiorBaseWarmModifier = interiorBaseWarmModifier,
        interiorBaseColdModifier = interiorBaseColdModifier,
        seasonalOffset = seasonalOffset,
        timeOfDay = timeOfDay,
        timeOfDaySeasonalOffset = timeOfDaySeasonalOffset,
        cellType = cellTypeKey,
        cellTypeLabel = cellTypeLabel,
        cellTypeScannedStaticCount = scannedStaticCount,
        cellTypeTopScoreType = topScoreType,
        cellTypeTopScoreValue = topScoreValue,
        cellTypeSignedModifier = cellTypeSignedModifier,
        cellTypeWarmModifier = cellTypeWarmModifier,
        cellTypeColdModifier = cellTypeColdModifier,
        campfireWarmModifier = campfireWarmModifier,
        campfireSourceCount = campfireSourceCount,
        campfireActiveSourceCount = campfireActiveSourceCount,
        campfireNearestDistance = campfireNearestDistance,
        campfireBaseWarmModifier = campfireBaseWarmModifier,
        campfireInteriorMultiplier = campfireInteriorMultiplier,
        campfireNearestRecordId = campfireNearestRecordId,
        campfireDominantSourceType = campfireDominantSourceType,
        campfireDryingMultiplier = campfireDryingMultiplier,
        campfireDryingSourceType = campfireDryingSourceType,
        campfireScanActivatorScanned = math.max(0, tonumber(scanDiagnostics.activatorScanned) or 0),
        campfireScanActivatorMatched = math.max(0, tonumber(scanDiagnostics.activatorMatched) or 0),
        campfireScanLightScanned = math.max(0, tonumber(scanDiagnostics.lightScanned) or 0),
        campfireScanLightMatched = math.max(0, tonumber(scanDiagnostics.lightMatched) or 0),
        campfireScanStaticScanned = math.max(0, tonumber(scanDiagnostics.staticScanned) or 0),
        campfireScanStaticMatched = math.max(0, tonumber(scanDiagnostics.staticMatched) or 0),
        campfireScanFailureCount = math.max(0, #((type(scanDiagnostics.getAllFailures) == 'table' and scanDiagnostics.getAllFailures) or {})),
        campfireScanFailures = (type(scanDiagnostics.getAllFailures) == 'table' and scanDiagnostics.getAllFailures) or {},
        season = season,
        loadedFileCount = cachedLoadedFileCount,
    }
end

return {
    getModifiersForCell = getModifiersForCell,
    setTraversalDebugLoggingEnabled = function(enabled)
        TEMPERATURE_TRAVERSAL_DEBUG_LOG = enabled == true
    end,
    setLatestCellInfo = function(info)
        cellInfo.setLatest(info)
    end,
    resetLatestCellInfo = function()
        cellInfo.reset()
        if type(heatSourceSystem.resetRuntimeCache) == 'function' then
            heatSourceSystem.resetRuntimeCache()
        end
        cachedExteriorRegionCategory = nil
        cachedExteriorMatchedRegionName = nil
        cachedTraversalRegionCandidatesByCell = {}
        loggedTraversalTraceByCell = {}
    end,
    getArmorWeightClassBySlot = function()
        return ARMOR_WEIGHT_CLASS_BY_SLOT
    end,
}
