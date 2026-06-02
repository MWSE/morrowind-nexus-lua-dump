local core = require('openmw.core')
local self = (function()
    local ok, loaded = pcall(require, 'openmw.self')
    if ok then
        return loaded
    end
    return nil
end)()
local types = require('openmw.types')
local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')

local campfireConfig = temperatureBalanceConfig.campfire
assert(type(campfireConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.campfire must be a table.')
local campfireWarmthByRegionConfig = campfireConfig.warmthByRegion
assert(
    type(campfireWarmthByRegionConfig) == 'table',
    '[SurvivalMode] temperatureBalanceConfig.campfire.warmthByRegion must be a table.'
)
local campfireFalloffConfig = campfireConfig.falloff
assert(type(campfireFalloffConfig) == 'table', '[SurvivalMode] temperatureBalanceConfig.campfire.falloff must be a table.')

local function requireNumericConfigField(container, fieldName, configPath)
    local value = tonumber(container[fieldName])
    assert(value ~= nil, string.format(
        '[SurvivalMode] %s.%s must be a number.',
        tostring(configPath),
        tostring(fieldName)
    ))
    return value
end

local CAMPFIRE_DEFAULT_RADIUS = math.max(
    1,
    requireNumericConfigField(campfireConfig, 'defaultRadius', 'temperatureBalanceConfig.campfire')
)
local LAVA_RADIUS_MULTIPLIER = 16.0
local LAVA_INTERIOR_RADIUS_MULTIPLIER = 16.0
local LAVA_HEAT_MULTIPLIER = 10 -- 1.5x increase from previous 4.0
local HELD_TORCH_INFLUENCE = 0.5
local TORCH_HEAT_MULTIPLIER = HELD_TORCH_INFLUENCE
local DRYING_MULTIPLIER_NONE = 1.0
local DRYING_MULTIPLIER_TORCH = 1.5
local DRYING_MULTIPLIER_FIRE = 2.5
local DRYING_MULTIPLIER_LAVA = 5.0
local CAMPFIRE_INTERIOR_POSITIVE_CELLTYPE_MULTIPLIER = math.max(
    0,
    requireNumericConfigField(
        campfireConfig,
        'interiorPositiveCellTypeMultiplier',
        'temperatureBalanceConfig.campfire'
    )
)
local CAMPFIRE_FALLOFF_INNER_RADIUS_UNITS = math.max(
    0,
    requireNumericConfigField(
        campfireFalloffConfig,
        'innerRadiusUnits',
        'temperatureBalanceConfig.campfire.falloff'
    )
)
local CAMPFIRE_FIRE_FALLOFF_INNER_RADIUS_UNITS = math.max(
    0,
    requireNumericConfigField(
        campfireFalloffConfig,
        'fireInnerRadiusUnits',
        'temperatureBalanceConfig.campfire.falloff'
    )
)
local CAMPFIRE_FIRE_INTERIOR_RADIUS_UNITS = math.max(
    1,
    requireNumericConfigField(
        campfireFalloffConfig,
        'fireInteriorRadiusUnits',
        'temperatureBalanceConfig.campfire.falloff'
    )
)
local CAMPFIRE_FALLOFF_EXPONENT = math.max(
    0.1,
    requireNumericConfigField(campfireFalloffConfig, 'exponent', 'temperatureBalanceConfig.campfire.falloff')
)

local SOURCE_CACHE_RESCAN_SECONDS = requireNumericConfigField(
    campfireConfig,
    'sourceCacheRescanSeconds',
    'temperatureBalanceConfig.campfire'
)
local SOURCE_CACHE_RESCAN_SECONDS_WITH_SOURCES = math.max(0.5, tonumber(SOURCE_CACHE_RESCAN_SECONDS) or 0.5)
local SOURCE_CACHE_RESCAN_SECONDS_NO_SOURCES = 4.0
local CAMPFIRE_MOVEMENT_REUSE_DISTANCE_UNITS = 128

local HEAT_WORDS = {
    'fire',
    'lava',
    'flame',
}
local LIGHT_SOURCE_BUILDER_WORDS = {
    'log',
    'fire',
    'flame',
}

local sourceCacheByCellKey = {}
local campfireEvaluationCacheByCellKey = {}

local function cloneTableArray(values)
    local cloned = {}
    if type(values) ~= 'table' then
        return cloned
    end
    for index, value in ipairs(values) do
        cloned[index] = value
    end
    return cloned
end

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    return string.lower(trim(tostring(value or '')))
end

local function getCellCacheKey(cell)
    if cell == nil then
        return ''
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

    local cellId = ''
    pcall(function()
        cellId = normalizeKey(cell.id)
    end)
    if cellId ~= '' then
        return cellId
    end

    return ''
end

local function getCurrentGameTime()
    if core ~= nil and type(core.getGameTime) == 'function' then
        local ok, value = pcall(core.getGameTime)
        if ok then
            return tonumber(value) or 0
        end
    end
    return 0
end

local function getObjectRecordId(object)
    local recordId = ''
    if object ~= nil then
        pcall(function()
            recordId = normalizeKey(object.recordId)
        end)
    end
    return recordId
end

local function readSourcePosition(source)
    if source == nil then
        return nil
    end

    local x = nil
    local y = nil
    local z = nil
    local vectorOk = pcall(function()
        x = tonumber(source.x)
        y = tonumber(source.y)
        z = tonumber(source.z)
    end)
    if vectorOk and x ~= nil and y ~= nil and z ~= nil then
        return { x = x, y = y, z = z }
    end

    local sourcePosition = nil
    pcall(function()
        sourcePosition = source.position
    end)
    if sourcePosition == nil or sourcePosition == source then
        return nil
    end
    return readSourcePosition(sourcePosition)
end

local function getSourceRecordId(source)
    if type(source) == 'table' and type(source.recordId) == 'string' then
        return normalizeKey(source.recordId)
    end
    return getObjectRecordId(source)
end


local function isLavaMistRecordId(recordId)
    local normalized = normalizeKey(recordId)
    if normalized == '' then
        return false
    end
    return string.find(normalized, 'ab_fx_lavamist', 1, true) ~= nil
end

local function getHeatSourceTypeFromRecordId(recordId)
    local normalized = normalizeKey(recordId)
    if normalized == '' then
        return nil
    end

    if string.find(normalized, 'lava', 1, true) ~= nil then
        return 'lava'
    end

    if string.find(normalized, 'torch', 1, true) ~= nil then
        return 'torch'
    end

    for _, word in ipairs(HEAT_WORDS) do
        if string.find(normalized, word, 1, true) ~= nil then
            return 'fire'
        end
    end

    return nil
end

local function getLightSourceHeatTypeFromRecordId(recordId)
    local resolved = getHeatSourceTypeFromRecordId(recordId)
    if resolved ~= nil then
        return resolved
    end

    local normalized = normalizeKey(recordId)
    if normalized == '' or string.find(normalized, 'light', 1, true) == nil then
        return nil
    end

    for _, word in ipairs(LIGHT_SOURCE_BUILDER_WORDS) do
        if string.find(normalized, word, 1, true) ~= nil then
            return 'fire'
        end
    end

    return nil
end

local function getSourceHeatType(source, recordId)
    if type(source) == 'table' and type(source.heatSourceType) == 'string' then
        local normalized = normalizeKey(source.heatSourceType)
        if normalized ~= '' then
            return normalized
        end
    end
    local normalizedRecordId = normalizeKey(recordId)
    if normalizedRecordId == '' then
        normalizedRecordId = getSourceRecordId(source)
    end
    local sourceType = getHeatSourceTypeFromRecordId(normalizedRecordId)
    if sourceType == nil then
        sourceType = getLightSourceHeatTypeFromRecordId(normalizedRecordId)
    end
    return sourceType
end

local function isHeatSourceObject(object, resolveHeatSourceType)
    local recordId = getObjectRecordId(object)
    if recordId == '' then
        return false
    end

    if string.match(recordId, '_[Oo]ff$')
        or string.match(recordId, 'burnedout')
        or string.match(recordId, 'broke')
        or string.match(recordId, 'flame light')
        or string.match(recordId, 'slf_cp_lavaarea_music')
        or string.match(recordId, 'music')
        or string.match(recordId, 'in_lava_blacksquare')
        or string.match(recordId, 'roht_mg_fire') then
        return false
    end

    if type(resolveHeatSourceType) == 'function' then
        return resolveHeatSourceType(recordId) ~= nil
    end
    return getHeatSourceTypeFromRecordId(recordId) ~= nil
end

local function textContainsTorch(value)
    local normalized = normalizeKey(value)
    if normalized == '' then
        return false
    end
    return string.find(normalized, 'torch', 1, true) ~= nil
end

local function itemMatchesTorchName(equippedItem)
    if equippedItem == nil then
        return false
    end

    local candidates = {}
    local function addCandidate(value)
        if value == nil then
            return
        end
        local valueType = type(value)
        if valueType == 'string' or valueType == 'number' then
            candidates[#candidates + 1] = tostring(value)
        end
    end

    pcall(function()
        addCandidate(equippedItem.recordId)
    end)
    pcall(function()
        addCandidate(equippedItem.id)
    end)
    pcall(function()
        addCandidate(equippedItem.name)
    end)

    local genericRecord = nil
    pcall(function()
        local objectType = equippedItem.type
        if objectType ~= nil and type(objectType.record) == 'function' then
            genericRecord = objectType.record(equippedItem)
        end
    end)
    if type(genericRecord) == 'table' then
        addCandidate(genericRecord.name)
        addCandidate(genericRecord.id)
        addCandidate(genericRecord.recordId)
    end

    if types.Light ~= nil and type(types.Light.record) == 'function' then
        local record = nil
        local recordOk = pcall(function()
            record = types.Light.record(equippedItem)
        end)
        if recordOk and type(record) == 'table' then
            addCandidate(record.name)
            addCandidate(record.id)
            addCandidate(record.recordId)
        end
    end

    for _, candidate in ipairs(candidates) do
        if textContainsTorch(candidate) then
            return true
        end
    end

    return false
end

local function actorHasHeldTorch(actor)
    if actor == nil
        or types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(actor) then
        return false
    end

    local ok, equipmentTable = pcall(types.Actor.getEquipment, actor)
    local equipmentType = type(equipmentTable)
    if not ok or (equipmentType ~= 'table' and equipmentType ~= 'userdata') then
        return false
    end

    local foundTorch = false
    local iterOk = pcall(function()
        for _, equippedItem in pairs(equipmentTable) do
            if itemMatchesTorchName(equippedItem) then
                foundTorch = true
                break
            end
        end
    end)
    return iterOk and foundTorch
end

local function getHeldTorchInfluence(options)
    local details = type(options) == 'table' and options or {}
    local actor = details.actor
    if actor == nil then
        actor = self
    end
    if actorHasHeldTorch(actor) then
        return HELD_TORCH_INFLUENCE
    end
    return 0
end

local function getDryingMultiplierForHeatSourceType(heatSourceType)
    if heatSourceType == 'lava' then
        return DRYING_MULTIPLIER_LAVA
    end
    if heatSourceType == 'fire' then
        return DRYING_MULTIPLIER_FIRE
    end
    if heatSourceType == 'torch' then
        return DRYING_MULTIPLIER_TORCH
    end
    return DRYING_MULTIPLIER_NONE
end

local function appendHeatSourcesFromCollection(sources, collection, options)
    local details = type(options) == 'table' and options or {}
    local excludeTorch = details.excludeTorch == true
    local allowOnlyType = normalizeKey(details.allowOnlyType)
    local resolveHeatSourceType = details.resolveHeatSourceType
    local stats = {
        scanned = 0,
        matched = 0,
    }
    if type(collection) ~= 'table' and type(collection) ~= 'userdata' then
        return stats
    end

    local scanned = 0
    local ipairsOk = pcall(function()
        for _, object in ipairs(collection) do
            scanned = scanned + 1
            stats.scanned = stats.scanned + 1
            local recordId = getObjectRecordId(object)
            local heatSourceType = type(resolveHeatSourceType) == 'function'
                and resolveHeatSourceType(recordId)
                or getHeatSourceTypeFromRecordId(recordId)
            if heatSourceType ~= nil
                and (allowOnlyType == '' or heatSourceType == allowOnlyType)
                and not (excludeTorch and heatSourceType == 'torch')
                and isHeatSourceObject(object, resolveHeatSourceType) then
                sources[#sources + 1] = object
                stats.matched = stats.matched + 1
            end
        end
    end)
    if not ipairsOk or scanned == 0 then
        pcall(function()
            for _, object in pairs(collection) do
                stats.scanned = stats.scanned + 1
                local recordId = getObjectRecordId(object)
                local heatSourceType = type(resolveHeatSourceType) == 'function'
                    and resolveHeatSourceType(recordId)
                    or getHeatSourceTypeFromRecordId(recordId)
                if heatSourceType ~= nil
                    and (allowOnlyType == '' or heatSourceType == allowOnlyType)
                    and not (excludeTorch and heatSourceType == 'torch')
                    and isHeatSourceObject(object, resolveHeatSourceType) then
                    sources[#sources + 1] = object
                    stats.matched = stats.matched + 1
                end
            end
        end)
    end

    return stats
end

local function serializeHeatSource(source)
    local recordId = getSourceRecordId(source)
    local heatSourceType = getSourceHeatType(source, recordId)
    local position = readSourcePosition(source)
    if recordId == '' or heatSourceType == nil or position == nil then
        return nil
    end

    return {
        recordId = recordId,
        heatSourceType = heatSourceType,
        x = tonumber(position.x),
        y = tonumber(position.y),
        z = tonumber(position.z),
    }
end

local function buildSerializedHeatSources(sources)
    local serialized = {}
    if type(sources) ~= 'table' then
        return serialized
    end
    for _, source in ipairs(sources) do
        local sourceData = serializeHeatSource(source)
        if sourceData ~= nil then
            serialized[#serialized + 1] = sourceData
        end
    end
    return serialized
end

local function hasSerializedHeatSources(sources)
    return type(sources) == 'table' and #sources > 0
end

local function getEffectiveRescanSecondsForSerializedSources(sources)
    if hasSerializedHeatSources(sources) then
        return SOURCE_CACHE_RESCAN_SECONDS_WITH_SOURCES
    end
    return SOURCE_CACHE_RESCAN_SECONDS_NO_SOURCES
end

local function buildSourceSnapshotStamp(serializedSources, scanTime)
    local roundedScanTimeMillis = math.floor((tonumber(scanTime) or 0) * 1000 + 0.5)
    local count = type(serializedSources) == 'table' and #serializedSources or 0
    local first = type(serializedSources) == 'table' and serializedSources[1] or nil
    local firstToken = 'none'
    if type(first) == 'table' then
        firstToken = table.concat({
            normalizeKey(first.recordId),
            tostring(math.floor((tonumber(first.x) or 0) + 0.5)),
            tostring(math.floor((tonumber(first.y) or 0) + 0.5)),
            tostring(math.floor((tonumber(first.z) or 0) + 0.5)),
        }, ':')
    end
    return table.concat({
        tostring(roundedScanTimeMillis),
        tostring(count),
        firstToken,
    }, '|')
end

local function shallowCopyTable(value)
    local copy = {}
    if type(value) ~= 'table' then
        return copy
    end
    for key, item in pairs(value) do
        copy[key] = item
    end
    return copy
end

local function cloneScanDiagnostics(rawDiagnostics)
    local diagnostics = type(rawDiagnostics) == 'table' and rawDiagnostics or {}
    return {
        activatorScanned = math.max(0, tonumber(diagnostics.activatorScanned) or 0),
        activatorMatched = math.max(0, tonumber(diagnostics.activatorMatched) or 0),
        lightScanned = math.max(0, tonumber(diagnostics.lightScanned) or 0),
        lightMatched = math.max(0, tonumber(diagnostics.lightMatched) or 0),
        staticScanned = math.max(0, tonumber(diagnostics.staticScanned) or 0),
        staticMatched = math.max(0, tonumber(diagnostics.staticMatched) or 0),
        getAllFailures = cloneTableArray(type(diagnostics.getAllFailures) == 'table' and diagnostics.getAllFailures or {}),
    }
end

local function scanCellHeatSources(cell)
    local sources = {}
    local diagnostics = {
        activatorScanned = 0,
        activatorMatched = 0,
        lightScanned = 0,
        lightMatched = 0,
        staticScanned = 0,
        staticMatched = 0,
        getAllFailures = {},
    }
    if cell == nil or type(cell.getAll) ~= 'function' then
        diagnostics.getAllFailures[#diagnostics.getAllFailures + 1] = 'cell.getAll unavailable'
        return sources, diagnostics
    end

    local function scanObjectType(objectType, label)
        if objectType == nil then
            diagnostics.getAllFailures[#diagnostics.getAllFailures + 1] = string.format('%s type unavailable', tostring(label))
            return
        end

        local collection = nil
        local ok, err = pcall(function()
            collection = cell:getAll(objectType)
        end)
        if ok and collection ~= nil then
            local typeStats = appendHeatSourcesFromCollection(sources, collection, {
                excludeTorch = true,
                allowOnlyType = label == 'static' and 'lava' or nil,
                resolveHeatSourceType = label == 'light' and getLightSourceHeatTypeFromRecordId or nil,
            })
            if label == 'activator' then
                diagnostics.activatorScanned = typeStats.scanned
                diagnostics.activatorMatched = typeStats.matched
            elseif label == 'light' then
                diagnostics.lightScanned = typeStats.scanned
                diagnostics.lightMatched = typeStats.matched
            elseif label == 'static' then
                diagnostics.staticScanned = typeStats.scanned
                diagnostics.staticMatched = typeStats.matched
            end
        else
            diagnostics.getAllFailures[#diagnostics.getAllFailures + 1] = string.format(
                '%s getAll failed: %s',
                tostring(label),
                tostring(err)
            )
        end
    end

    scanObjectType(types.Activator, 'activator')
    scanObjectType(types.Light, 'light')
    scanObjectType(types.Static, 'static')
    return sources, diagnostics
end

local function getCellHeatSources(cell)
    local cacheKey = getCellCacheKey(cell)
    if cacheKey == '' then
        return scanCellHeatSources(cell)
    end

    local now = getCurrentGameTime()
    local cached = sourceCacheByCellKey[cacheKey]
    if type(cached) == 'table' then
        local elapsed = now - (tonumber(cached.lastScanTime) or -math.huge)
        local cachedSerializedSources = cached.serializedSources
        local effectiveRescanSeconds = getEffectiveRescanSecondsForSerializedSources(cachedSerializedSources)
        if elapsed >= 0 and elapsed < effectiveRescanSeconds and type(cached.sources) == 'table' then
            return cached.sources, cached.diagnostics or {}
        end
    end

    local sources, diagnostics = scanCellHeatSources(cell)
    local serializedSources = buildSerializedHeatSources(sources)
    sourceCacheByCellKey[cacheKey] = {
        lastScanTime = now,
        sources = sources,
        serializedSources = serializedSources,
        sourceSnapshotStamp = buildSourceSnapshotStamp(serializedSources, now),
        diagnostics = diagnostics,
    }
    return sources, diagnostics
end

local function getCellHeatSourceSnapshot(cell, forceRescan)
    local shouldBypassCache = forceRescan == true
    local cacheKey = getCellCacheKey(cell)
    local now = getCurrentGameTime()
    local cached = nil
    if not shouldBypassCache and cacheKey ~= '' then
        cached = sourceCacheByCellKey[cacheKey]
    end

    local sources = nil
    local diagnostics = nil
    local useCached = false
    local snapshotScanTime = now
    local snapshotSourceStamp = ''
    if type(cached) == 'table' then
        local elapsed = now - (tonumber(cached.lastScanTime) or -math.huge)
        local cachedSources = cached.sources
        local cachedSerializedSources = cached.serializedSources
        local preferredSerializedSources = type(cachedSerializedSources) == 'table' and cachedSerializedSources
            or cachedSources
        local effectiveRescanSeconds = getEffectiveRescanSecondsForSerializedSources(preferredSerializedSources)
        if elapsed >= 0 and elapsed < effectiveRescanSeconds then
            if type(cachedSerializedSources) == 'table' and #cachedSerializedSources > 0 then
                sources = cachedSerializedSources
            else
                sources = cachedSources
            end
            diagnostics = cached.diagnostics
            useCached = true
            snapshotScanTime = tonumber(cached.lastScanTime) or now
            snapshotSourceStamp = normalizeKey(cached.sourceSnapshotStamp)
        end
    end

    if not useCached then
        sources, diagnostics = scanCellHeatSources(cell)
    end

    local serializedSources = {}
    if type(sources) == 'table' and #sources > 0 and type(sources[1]) == 'table' and sources[1].x ~= nil then
        serializedSources = cloneTableArray(sources)
    else
        serializedSources = buildSerializedHeatSources(sources)
    end
    local cacheData = {
        cacheKey = cacheKey,
        lastScanTime = snapshotScanTime,
        sources = sources,
        serializedSources = serializedSources,
        sourceSnapshotStamp = snapshotSourceStamp ~= ''
            and snapshotSourceStamp
            or buildSourceSnapshotStamp(serializedSources, snapshotScanTime),
        diagnostics = cloneScanDiagnostics(diagnostics),
    }
    if cacheKey ~= '' then
        sourceCacheByCellKey[cacheKey] = cacheData
    end

    return {
        cacheKey = cacheKey,
        lastScanTime = snapshotScanTime,
        sources = serializedSources,
        sourceSnapshotStamp = cacheData.sourceSnapshotStamp,
        diagnostics = cloneScanDiagnostics(diagnostics),
    }
end

local function readVector3(value)
    if value == nil then
        return nil
    end

    local x = nil
    local y = nil
    local z = nil
    local ok = pcall(function()
        x = tonumber(value.x)
        y = tonumber(value.y)
        z = tonumber(value.z)
    end)
    if not ok or x == nil or y == nil or z == nil then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function getPlayerPosition()
    if self == nil then
        return nil
    end

    local position = nil
    pcall(function()
        position = self.position
    end)
    return readVector3(position)
end

local function isValidObject(object)
    if object == nil then
        return false
    end

    if type(object.isValid) == 'function' then
        local valid = false
        local ok = pcall(function()
            valid = object:isValid() == true
        end)
        if ok then
            return valid
        end
    end

    return true
end

local function distanceBetween(a, b)
    if a == nil or b == nil then
        return math.huge
    end

    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    local dz = (tonumber(a.z) or 0) - (tonumber(b.z) or 0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function getBaseCampfireWarmth(category)
    local normalizedCategory = normalizeKey(category)
    if normalizedCategory == '' then
        normalizedCategory = 'neutral'
    end

    local configured = tonumber(campfireWarmthByRegionConfig[normalizedCategory])
    if configured == nil then
        if normalizedCategory == 'very_hot' then
            configured = tonumber(campfireWarmthByRegionConfig.hot)
                or tonumber(campfireWarmthByRegionConfig.warm)
        elseif normalizedCategory == 'hot' then
            configured = tonumber(campfireWarmthByRegionConfig.very_hot)
        elseif normalizedCategory == 'warm' then
            configured = tonumber(campfireWarmthByRegionConfig.hot)
                or tonumber(campfireWarmthByRegionConfig.neutral)
        elseif normalizedCategory == 'chilly' then
            configured = tonumber(campfireWarmthByRegionConfig.cold)
                or tonumber(campfireWarmthByRegionConfig.neutral)
        elseif normalizedCategory == 'very_cold' then
            configured = tonumber(campfireWarmthByRegionConfig.cold)
                or tonumber(campfireWarmthByRegionConfig.chilly)
        elseif normalizedCategory == 'cold' then
            configured = tonumber(campfireWarmthByRegionConfig.very_cold)
        end
    end
    if configured == nil then
        configured = tonumber(campfireWarmthByRegionConfig.neutral)
    end
    assert(configured ~= nil, string.format(
        '[SurvivalMode] temperatureBalanceConfig.campfire.warmthByRegion has no numeric value for "%s" or fallback.',
        tostring(normalizedCategory)
    ))
    return math.max(0, configured)
end

local function getSourceParameters(source, baseWarmth, options)
    local recordId = getSourceRecordId(source)
    local heatSourceType = getSourceHeatType(source, recordId)
    if heatSourceType == nil then
        return nil, nil, recordId, nil, nil
    end

    local details = type(options) == 'table' and options or {}
    local radius = CAMPFIRE_DEFAULT_RADIUS
    local warmth = baseWarmth
    local innerRadiusOverride = nil

    if heatSourceType == 'lava' then
        radius = radius * LAVA_RADIUS_MULTIPLIER
        if details.isExteriorCell ~= true then
            radius = radius * LAVA_INTERIOR_RADIUS_MULTIPLIER
        end
        warmth = warmth * LAVA_HEAT_MULTIPLIER
    elseif heatSourceType == 'torch' then
        warmth = warmth * TORCH_HEAT_MULTIPLIER
    elseif heatSourceType == 'fire' and details.isExteriorCell ~= true then
        local originalFalloffDistance = math.max(0, CAMPFIRE_DEFAULT_RADIUS - CAMPFIRE_FIRE_FALLOFF_INNER_RADIUS_UNITS)
        radius = CAMPFIRE_FIRE_INTERIOR_RADIUS_UNITS
        innerRadiusOverride = math.max(0, radius - originalFalloffDistance)
    end

    if radius <= 0 or warmth <= 0 then
        return nil, nil, recordId, heatSourceType, innerRadiusOverride
    end
    return radius, warmth, recordId, heatSourceType, innerRadiusOverride
end

local function getInteriorMultiplier(isExteriorCell, cellTypeSignedModifier)
    if isExteriorCell == true then
        return 1.0
    end
    if (tonumber(cellTypeSignedModifier) or 0) > 0 then
        return CAMPFIRE_INTERIOR_POSITIVE_CELLTYPE_MULTIPLIER
    end
    return 1.0
end

local function computeWarmthFromInfluence(influence, options)
    local details = type(options) == 'table' and options or {}
    local baseWarmth = getBaseCampfireWarmth(details.regionCategory)
    local interiorMultiplier = getInteriorMultiplier(details.isExteriorCell == true, details.cellTypeSignedModifier)
    local normalizedInfluence = math.max(0, tonumber(influence) or 0)
    return {
        warmModifier = baseWarmth * normalizedInfluence * interiorMultiplier,
        baseWarmModifier = baseWarmth,
        interiorMultiplier = interiorMultiplier,
        influence = normalizedInfluence,
    }
end

local function evaluateCampfireModifierForSources(sources, position, options)
    local details = type(options) == 'table' and options or {}
    local playerPosition = readVector3(position)
    local heldTorchInfluence = getHeldTorchInfluence(details)
    local cellCacheKey = normalizeKey(details.cellCacheKey)
    local sourceSnapshotStamp = normalizeKey(details.sourceSnapshotStamp)
    local sourceCount = type(sources) == 'table' and #sources or 0
    if sourceSnapshotStamp == '' then
        sourceSnapshotStamp = 'count:' .. tostring(sourceCount)
    end
    local hasNonLavaMistLavaSource = false
    if sourceCount > 0 then
        for _, sourceObject in ipairs(sources) do
            if sourceObject ~= nil then
                local sourceRecordId = getSourceRecordId(sourceObject)
                local sourceType = getSourceHeatType(sourceObject, sourceRecordId)
                if sourceType == 'lava' and not isLavaMistRecordId(sourceRecordId) then
                    hasNonLavaMistLavaSource = true
                    break
                end
            end
        end
    end
    local strongestInfluence = heldTorchInfluence
    local dominantSourceType = heldTorchInfluence > 0 and 'torch' or ''
    local dryingMultiplier = DRYING_MULTIPLIER_NONE
    local dryingSourceType = 'none'
    local selectedDistance = heldTorchInfluence > 0 and 0 or nil
    local selectedRecordId = heldTorchInfluence > 0 and 'held_torch' or ''
    if heldTorchInfluence > 0 then
        dryingMultiplier = DRYING_MULTIPLIER_TORCH
        dryingSourceType = 'torch'
    end
    local baseWarmth = math.max(0.01, getBaseCampfireWarmth(details.regionCategory))
    local evaluationOptionsSignature = table.concat({
        normalizeKey(details.regionCategory),
        details.isExteriorCell == true and '1' or '0',
        tostring(math.floor((tonumber(details.cellTypeSignedModifier) or 0) + 0.5)),
        tostring(math.floor((tonumber(heldTorchInfluence) or 0) * 1000 + 0.5)),
    }, '|')

    if playerPosition ~= nil and cellCacheKey ~= '' then
        local cachedEvaluation = campfireEvaluationCacheByCellKey[cellCacheKey]
        if type(cachedEvaluation) == 'table'
            and cachedEvaluation.sourceSnapshotStamp == sourceSnapshotStamp
            and cachedEvaluation.optionsSignature == evaluationOptionsSignature
            and type(cachedEvaluation.result) == 'table'
            and type(cachedEvaluation.position) == 'table'
            and distanceBetween(playerPosition, cachedEvaluation.position) <= CAMPFIRE_MOVEMENT_REUSE_DISTANCE_UNITS then
            return shallowCopyTable(cachedEvaluation.result)
        end
    end

    if playerPosition ~= nil and sourceCount > 0 then
        for _, source in ipairs(sources) do
            if source ~= nil and (type(source) == 'table' or isValidObject(source)) then
                local sourceVector = readSourcePosition(source)
                if sourceVector ~= nil then
                    local distance = distanceBetween(playerPosition, sourceVector)
                    local sourceRecordId = getSourceRecordId(source)
                    if hasNonLavaMistLavaSource and isLavaMistRecordId(sourceRecordId) then
                        goto continue_source
                    end
                    local radius, sourceWarmth, recordId, heatSourceType, innerRadiusOverride = getSourceParameters(
                        source,
                        baseWarmth,
                        details
                    )
                    if radius ~= nil and sourceWarmth ~= nil and distance < radius then
                        local configuredInnerRadius = CAMPFIRE_FALLOFF_INNER_RADIUS_UNITS
                        if heatSourceType == 'fire' then
                            configuredInnerRadius = CAMPFIRE_FIRE_FALLOFF_INNER_RADIUS_UNITS
                        end
                        if innerRadiusOverride ~= nil then
                            configuredInnerRadius = innerRadiusOverride
                        end
                        local innerRadius = math.min(radius, configuredInnerRadius)
                        local effectiveDistance = math.max(0, distance - innerRadius)
                        local distanceMod = math.max(0, 1 - (effectiveDistance / radius)) ^ CAMPFIRE_FALLOFF_EXPONENT
                        local sourceInfluence = (sourceWarmth / baseWarmth) * distanceMod
                        if sourceInfluence > strongestInfluence then
                            strongestInfluence = sourceInfluence
                            dominantSourceType = heatSourceType or ''
                            selectedDistance = distance
                            selectedRecordId = recordId
                            dryingMultiplier = getDryingMultiplierForHeatSourceType(heatSourceType)
                            dryingSourceType = heatSourceType or 'none'
                        end
                    end
                end
            end
            ::continue_source::
        end
    end

    local activeSourceCount = strongestInfluence > 0 and 1 or 0

    local warmthData = computeWarmthFromInfluence(strongestInfluence, details)
    local result = {
        warmModifier = math.max(0, tonumber(warmthData.warmModifier) or 0),
        sourceCount = sourceCount,
        activeSourceCount = activeSourceCount,
        nearestDistance = selectedDistance,
        baseWarmModifier = math.max(0, tonumber(warmthData.baseWarmModifier) or 0),
        interiorMultiplier = math.max(0, tonumber(warmthData.interiorMultiplier) or 1.0),
        influence = math.max(0, tonumber(warmthData.influence) or 0),
        dominantSourceType = dominantSourceType,
        nearestRecordId = selectedRecordId,
        dryingMultiplier = math.max(DRYING_MULTIPLIER_NONE, tonumber(dryingMultiplier) or DRYING_MULTIPLIER_NONE),
        dryingSourceType = dryingSourceType,
    }
    if cellCacheKey ~= '' then
        campfireEvaluationCacheByCellKey[cellCacheKey] = {
            sourceSnapshotStamp = sourceSnapshotStamp,
            optionsSignature = evaluationOptionsSignature,
            position = playerPosition,
            result = shallowCopyTable(result),
        }
    end
    return result
end

local function getCampfireModifierForCachedSources(cachedSources, position, options)
    local details = type(options) == 'table' and options or {}
    local sourceList = type(cachedSources) == 'table' and cachedSources or {}
    if details.sourceSnapshotStamp == nil then
        details.sourceSnapshotStamp = buildSourceSnapshotStamp(sourceList, details.scanTime)
    end
    return evaluateCampfireModifierForSources(sourceList, position, details)
end

local function getCampfireModifierForPosition(cell, position, options)
    local snapshot = getCellHeatSourceSnapshot(cell, false)
    local details = type(options) == 'table' and options or {}
    if details.cellCacheKey == nil or normalizeKey(details.cellCacheKey) == '' then
        details.cellCacheKey = normalizeKey(snapshot.cacheKey)
    end
    details.sourceSnapshotStamp = snapshot.sourceSnapshotStamp
    local evaluated = evaluateCampfireModifierForSources(snapshot.sources, position, details)
    evaluated.scanDiagnostics = snapshot.diagnostics or {}
    return evaluated
end

local function getCampfireModifier(cell, options)
    local details = type(options) == 'table' and options or {}
    if details.actor == nil then
        details.actor = self
    end
    return getCampfireModifierForPosition(cell, getPlayerPosition(), details)
end

local function resolveCacheKey(cellOrCellKey)
    if type(cellOrCellKey) == 'string' then
        return normalizeKey(cellOrCellKey)
    end
    return getCellCacheKey(cellOrCellKey)
end

local function upsertDynamicHeatSource(cellOrCellKey, sourceEntry)
    local cacheKey = resolveCacheKey(cellOrCellKey)
    if cacheKey == '' then
        return false
    end

    local normalizedSource = serializeHeatSource(sourceEntry)
    if normalizedSource == nil then
        return false
    end

    local cached = sourceCacheByCellKey[cacheKey]
    if type(cached) ~= 'table' then
        cached = {
            lastScanTime = getCurrentGameTime(),
            sources = {},
            serializedSources = {},
            sourceSnapshotStamp = '',
            diagnostics = cloneScanDiagnostics(),
        }
        sourceCacheByCellKey[cacheKey] = cached
    end

    if type(cached.serializedSources) ~= 'table' then
        cached.serializedSources = {}
    end
    local replaced = false
    for index, existing in ipairs(cached.serializedSources) do
        if type(existing) == 'table'
            and normalizeKey(existing.recordId) == normalizedSource.recordId
            and tonumber(existing.x) == tonumber(normalizedSource.x)
            and tonumber(existing.y) == tonumber(normalizedSource.y)
            and tonumber(existing.z) == tonumber(normalizedSource.z) then
            cached.serializedSources[index] = normalizedSource
            replaced = true
            break
        end
    end
    if not replaced then
        cached.serializedSources[#cached.serializedSources + 1] = normalizedSource
    end
    cached.lastScanTime = getCurrentGameTime()
    cached.sourceSnapshotStamp = buildSourceSnapshotStamp(cached.serializedSources, cached.lastScanTime)
    campfireEvaluationCacheByCellKey[cacheKey] = nil
    return true
end

local function removeDynamicHeatSource(cellOrCellKey, sourceEntry)
    local cacheKey = resolveCacheKey(cellOrCellKey)
    if cacheKey == '' then
        return false
    end

    local cached = sourceCacheByCellKey[cacheKey]
    if type(cached) ~= 'table' or type(cached.serializedSources) ~= 'table' then
        return false
    end

    local normalizedSource = serializeHeatSource(sourceEntry)
    if normalizedSource == nil then
        return false
    end

    local removed = false
    local kept = {}
    for _, existing in ipairs(cached.serializedSources) do
        if type(existing) == 'table'
            and normalizeKey(existing.recordId) == normalizedSource.recordId
            and tonumber(existing.x) == tonumber(normalizedSource.x)
            and tonumber(existing.y) == tonumber(normalizedSource.y)
            and tonumber(existing.z) == tonumber(normalizedSource.z)
            and not removed then
            removed = true
        else
            kept[#kept + 1] = existing
        end
    end
    cached.serializedSources = kept
    cached.lastScanTime = getCurrentGameTime()
    cached.sourceSnapshotStamp = buildSourceSnapshotStamp(cached.serializedSources, cached.lastScanTime)
    campfireEvaluationCacheByCellKey[cacheKey] = nil
    return removed
end

local function resetRuntimeCache()
    sourceCacheByCellKey = {}
    campfireEvaluationCacheByCellKey = {}
end

return {
    getCampfireModifier = getCampfireModifier,
    getCampfireModifierForPosition = getCampfireModifierForPosition,
    getCampfireModifierForCachedSources = getCampfireModifierForCachedSources,
    getCellHeatSourceSnapshot = getCellHeatSourceSnapshot,
    upsertDynamicHeatSource = upsertDynamicHeatSource,
    removeDynamicHeatSource = removeDynamicHeatSource,
    computeWarmthFromInfluence = computeWarmthFromInfluence,
    resetRuntimeCache = resetRuntimeCache,
}
