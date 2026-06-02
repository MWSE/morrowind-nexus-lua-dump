local types = require('openmw.types')

local SCORE_THRESHOLD = 3
local SOFT_SCORE_THRESHOLD = 2
local TYPE_LABELS = {
    exterior = 'Exterior',
    interior = 'Interior',
    volcanic = 'Volcanic',
    cave = 'Cave',
    ice_cave = 'Ice Cave',
    mine = 'Mine',
    dwemer = 'Dwemer',
    daedric = 'Daedric',
    tomb = 'Tomb',
    house = 'House',
    castle = 'Castle',
    mushroom = 'Telvanni',
    hlaalu = 'Hlaalu',
    redoran = 'Redoran',
    sewer = 'Sewer',
    temple = 'Temple',
}
local PRIMARY_TYPE_PRIORITY = {
    'volcanic',
    'ice_cave',
    'mine',
    'sewer',
    'temple',
    'daedric',
    'dwemer',
    'tomb',
    'castle',
    'cave',
    'mushroom',
    'hlaalu',
    'redoran',
    'house',
}
local STATIC_PATTERNS = {
    volcanic = { 'lava', 'magma', 'molten', 'in_lava_', 'lavafall', 'lavapool' },
    ice_cave = { 'ice', 'frost', 'snow', 'frozen', '_caveic_', 'caveice', 't_glb_terrice_', 'icicle', 'bm_ice' },
    cave = { 'cave', 'cavern', 'grotto', 't_cnq_cave_', 't_glb_cave' },
    dwemer = { 'dwrv_', 'in_dwe', 'ex_dwe', 'dwemer', '_dwe_', 'centurion', 't_dwe_dng' },
    daedric = { '_dae_', 'daedric', 'ex_dae', 'in_dae', 'daed_', 't_dae_dng' },
    mine = { 'mine', 'in_cavern_', 'eggmine', 'kvatch', 't_com_setmine_', 'mineentr' },
    tomb = { 'tomb', 'in_om_', 'in_bm_', 'ancestral', 'crypt', 'burial', 'furn_bone', 't_bre_dngcrypt', 'coffin', 'sarcophagus' },
    house = { 'house', 'shack', 'hut', 'in_common_', 'in_de_', 'in_nord_', 'in_redoran_', 'in_hlaalu_', 'furn_', 'ex_common_building', 'ex_nord_house', 'ex_redoran_hut', 'housepod', 'housestem' },
    castle = { 'stronghold', '_keep', 'fort', 'castle', 'guardtower', 'imp_tower', 'wall_512', 'battlement', 'ex_vivec', 'in_impbig', 't_bre_setostc_', 'keepwall', 'keepbase' },
    mushroom = { 'in_t_', 'telv', 'mushroom', 'mush' },
    hlaalu = { 'in_hlaalu', 'in_h_' },
    redoran = { 'in_redoran', 'in_r_' },
    sewer = { 'sewer', 'underwork' },
    temple = { 'temple', 'shrine', 'in_velothi', 'prayer_stool', 'in_mh_temple' },
}

local cacheByCellId = {}

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    return string.lower(trim(tostring(value or '')))
end

local function hasCellTag(cell, tagName)
    if cell == nil or type(cell.hasTag) ~= 'function' then
        return false
    end
    local ok, hasTag = pcall(function()
        return cell:hasTag(tagName)
    end)
    return ok and hasTag == true
end

local function isCellExterior(cell)
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
    local skyOk = pcall(function()
        hasSky = cell.hasSky == true
    end)
    if skyOk and hasSky and hasCellTag(cell, 'QuasiExterior') then
        return true
    end

    return false
end

local function collectCellId(cell)
    if cell == nil then
        return ''
    end

    local cellId = ''
    local ok = pcall(function()
        cellId = trim(cell.id)
    end)
    if not ok then
        return ''
    end

    return cellId
end

local function collectCellCacheKey(cell)
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

    local cellId = collectCellId(cell)
    if cellId ~= '' then
        return normalizeKey(cellId)
    end

    local fallback = ''
    pcall(function()
        fallback = trim(tostring(cell))
    end)
    return normalizeKey(fallback)
end

local function bumpScore(scores, key, amount)
    if type(scores) ~= 'table' then
        return
    end
    local normalizedKey = normalizeKey(key)
    if normalizedKey == '' then
        return
    end
    scores[normalizedKey] = (tonumber(scores[normalizedKey]) or 0) + (tonumber(amount) or 1)
end

local function collectObjectTextCandidates(object, recordReader)
    local candidates = {}

    local function addCandidate(value)
        local text = trim(tostring(value or ''))
        if text ~= '' then
            candidates[#candidates + 1] = text
        end
    end

    local directRecordId = ''
    local directOk = pcall(function()
        directRecordId = trim(object.recordId)
    end)
    if directOk then
        addCandidate(directRecordId)
    end

    if type(recordReader) == 'function' then
        local recordOk, recordValue = pcall(recordReader, object)
        if recordOk and type(recordValue) == 'table' then
            addCandidate(recordValue.id)
            addCandidate(recordValue.name)
            addCandidate(recordValue.model)
            addCandidate(recordValue.mesh)
        end
    end

    local fallbackId = ''
    local fallbackOk = pcall(function()
        fallbackId = trim(tostring(object.id or ''))
    end)
    if fallbackOk then
        addCandidate(fallbackId)
    end

    return candidates
end

local function isLavaCandidate(recordId)
    local normalizedId = normalizeKey(recordId)
    if normalizedId == '' then
        return false
    end
    if normalizedId:find('in_lava_blacksquare', 1, true) ~= nil then
        return false
    end
    return normalizedId:find('lava', 1, true) ~= nil
end

local function scoreRecordId(scores, recordId, matchedScoreTypes)
    local normalizedId = normalizeKey(recordId)
    if normalizedId == '' then
        return
    end

    for scoreKey, patterns in pairs(STATIC_PATTERNS) do
        for _, pattern in ipairs(patterns) do
            if normalizedId:find(pattern, 1, true) ~= nil then
                if scoreKey == 'volcanic' and normalizedId:find('in_lava_blacksquare', 1, true) ~= nil then
                    break
                end
                bumpScore(scores, scoreKey, 1)
                if type(matchedScoreTypes) == 'table' then
                    matchedScoreTypes[scoreKey] = true
                end
                if scoreKey == 'temple' and pattern == 'in_mh_temple' then
                    bumpScore(scores, scoreKey, 4)
                end
                break
            end
        end
    end
end

local function scoreCellObjects(scores, cell, objectType, recordReader, staticMatchStats)
    if cell == nil or type(cell.getAll) ~= 'function' or objectType == nil then
        return 0
    end

    local ok, statics = pcall(function()
        return cell:getAll(objectType)
    end)
    if not ok or statics == nil then
        return 0
    end

    local scannedCount = 0
    local function scanObject(object)
        local candidates = collectObjectTextCandidates(object, recordReader)
        if #candidates > 0 then
            scannedCount = scannedCount + 1
            local matchedScoreTypes = {}
            local hasLavaCandidate = false
            for _, candidate in ipairs(candidates) do
                scoreRecordId(scores, candidate, matchedScoreTypes)
                if isLavaCandidate(candidate) then
                    hasLavaCandidate = true
                end
            end
            if type(staticMatchStats) == 'table' then
                if matchedScoreTypes.dwemer == true then
                    staticMatchStats.dwemer = (tonumber(staticMatchStats.dwemer) or 0) + 1
                end
                if hasLavaCandidate then
                    staticMatchStats.lava = (tonumber(staticMatchStats.lava) or 0) + 1
                end
            end
        end
    end

    local ipairsScanned = 0
    local ipairsOk = pcall(function()
        for _, object in ipairs(statics) do
            ipairsScanned = ipairsScanned + 1
            scanObject(object)
        end
    end)
    if not ipairsOk or ipairsScanned == 0 then
        pcall(function()
            for _, object in pairs(statics) do
                scanObject(object)
            end
        end)
    end

    return scannedCount
end

local function scoreCellIdHints(scores, cellId)
    local normalizedCellId = normalizeKey(cellId)
    if normalizedCellId == '' then
        return
    end

    if normalizedCellId:find('sea of ghosts', 1, true) ~= nil then
        bumpScore(scores, 'ice_cave', SCORE_THRESHOLD)
        bumpScore(scores, 'cave', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('ice cave', 1, true) ~= nil
        or normalizedCellId:find('glacial', 1, true) ~= nil
        or normalizedCellId:find('frozen', 1, true) ~= nil
        or normalizedCellId:find('frost', 1, true) ~= nil then
        bumpScore(scores, 'ice_cave', SCORE_THRESHOLD)
        bumpScore(scores, 'cave', SOFT_SCORE_THRESHOLD)
    end
    if normalizedCellId:find('grotto', 1, true) ~= nil then
        bumpScore(scores, 'cave', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('sewer', 1, true) ~= nil then
        bumpScore(scores, 'sewer', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('catac', 1, true) ~= nil then
        bumpScore(scores, 'tomb', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('temple', 1, true) ~= nil
        or normalizedCellId:find('shrine', 1, true) ~= nil
        or normalizedCellId:find('chapel', 1, true) ~= nil
        or normalizedCellId:find('sanctum', 1, true) ~= nil then
        bumpScore(scores, 'temple', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('house', 1, true) ~= nil
        or normalizedCellId:find('home', 1, true) ~= nil
        or normalizedCellId:find('manor', 1, true) ~= nil
        or normalizedCellId:find('hut', 1, true) ~= nil
        or normalizedCellId:find('shack', 1, true) ~= nil
        or normalizedCellId:find('apartment', 1, true) ~= nil
        or normalizedCellId:find(', guild', 1, true) ~= nil then
        bumpScore(scores, 'house', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('dwemer', 1, true) ~= nil then
        bumpScore(scores, 'dwemer', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('daedric', 1, true) ~= nil then
        bumpScore(scores, 'daedric', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('lava', 1, true) ~= nil
        or normalizedCellId:find('magma', 1, true) ~= nil
        or normalizedCellId:find('molten', 1, true) ~= nil
        or normalizedCellId:find('volcan', 1, true) ~= nil then
        bumpScore(scores, 'volcanic', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('tomb', 1, true) ~= nil
        or normalizedCellId:find('crypt', 1, true) ~= nil
        or normalizedCellId:find('burial', 1, true) ~= nil then
        bumpScore(scores, 'tomb', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('mine', 1, true) ~= nil
        or normalizedCellId:find('eggmine', 1, true) ~= nil then
        bumpScore(scores, 'mine', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('cave', 1, true) ~= nil
        or normalizedCellId:find('cavern', 1, true) ~= nil then
        bumpScore(scores, 'cave', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('telvanni', 1, true) ~= nil then
        bumpScore(scores, 'mushroom', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('mushroom', 1, true) ~= nil then
        bumpScore(scores, 'mushroom', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('hlaalu', 1, true) ~= nil then
        bumpScore(scores, 'hlaalu', SCORE_THRESHOLD)
    end
    if normalizedCellId:find('redoran', 1, true) ~= nil then
        bumpScore(scores, 'redoran', SCORE_THRESHOLD)
    end
end

local function buildFlagsFromScores(scores)
    local flags = {}
    local function markIfThreshold(typeKey, threshold)
        if (tonumber(scores[typeKey]) or 0) >= (threshold or SCORE_THRESHOLD) then
            flags[typeKey] = true
        end
    end

    markIfThreshold('ice_cave', 1)
    markIfThreshold('volcanic', 1)
    markIfThreshold('mine', 2)
    markIfThreshold('sewer', 2)
    markIfThreshold('temple', 2)
    markIfThreshold('daedric', 1)
    markIfThreshold('dwemer', 1)
    markIfThreshold('castle', 2)
    markIfThreshold('mushroom', 1)
    markIfThreshold('hlaalu', 1)
    markIfThreshold('redoran', 1)
    markIfThreshold('tomb', SCORE_THRESHOLD)

    if flags.ice_cave or flags.mine then
        flags.cave = true
    end
    if (tonumber(scores.cave) or 0) >= SOFT_SCORE_THRESHOLD then
        flags.cave = true
    end

    local hasNonHouseInteriorType = (
        flags.volcanic
        or flags.ice_cave
        or flags.mine
        or flags.sewer
        or flags.temple
        or flags.daedric
        or flags.dwemer
        or flags.tomb
        or flags.castle
        or flags.cave
    )

    if (tonumber(scores.house) or 0) >= 2 and not hasNonHouseInteriorType then
        flags.house = true
    end

    local hasPrimaryType = false
    for _, typeKey in ipairs(PRIMARY_TYPE_PRIORITY) do
        if flags[typeKey] == true then
            hasPrimaryType = true
            break
        end
    end
    if not hasPrimaryType then
        local bestType = nil
        local bestScore = 0
        for scoreKey, scoreValue in pairs(scores) do
            local score = tonumber(scoreValue) or 0
            if score > bestScore then
                bestScore = score
                bestType = normalizeKey(scoreKey)
            end
        end
        if bestType ~= nil and bestType ~= '' and bestScore > 0 then
            flags[bestType] = true
            if bestType == 'ice_cave' or bestType == 'mine' then
                flags.cave = true
            end
        end
    end

    return flags
end

local function choosePrimaryType(isExterior, flags)
    if isExterior then
        return 'exterior'
    end

    for _, typeKey in ipairs(PRIMARY_TYPE_PRIORITY) do
        if flags[typeKey] == true then
            return typeKey
        end
    end

    return 'interior'
end

local function getTopScoredType(scores)
    local bestType = nil
    local bestScore = 0
    for scoreKey, scoreValue in pairs(scores) do
        local score = tonumber(scoreValue) or 0
        if score > bestScore then
            bestScore = score
            bestType = normalizeKey(scoreKey)
        end
    end
    return bestType, bestScore
end

local function cloneFlags(flags)
    local copied = {}
    for key, value in pairs(flags) do
        copied[key] = value
    end
    return copied
end

local function cloneArray(values)
    local cloned = {}
    if type(values) ~= 'table' then
        return cloned
    end
    for index, value in ipairs(values) do
        cloned[index] = value
    end
    return cloned
end

local function evaluateCell(cell)
    local cellId = collectCellId(cell)
    local exterior = isCellExterior(cell)
    local scores = {}
    local flags = {}

    local scannedObjectCount = 0
    local staticMatchStats = {
        dwemer = 0,
        lava = 0,
    }
    if not exterior then
        scoreCellIdHints(scores, cellId)
        scannedObjectCount = scannedObjectCount + scoreCellObjects(
            scores,
            cell,
            types.Static,
            type(types.Static) == 'table' and type(types.Static.record) == 'function' and types.Static.record or nil,
            staticMatchStats
        )
        scannedObjectCount = scannedObjectCount + scoreCellObjects(
            scores,
            cell,
            types.Activator,
            type(types.Activator) == 'table' and type(types.Activator.record) == 'function' and types.Activator.record or nil
        )
        scannedObjectCount = scannedObjectCount + scoreCellObjects(
            scores,
            cell,
            types.Light,
            type(types.Light) == 'table' and type(types.Light.record) == 'function' and types.Light.record or nil
        )
        scannedObjectCount = scannedObjectCount + scoreCellObjects(
            scores,
            cell,
            types.Door,
            type(types.Door) == 'table' and type(types.Door.record) == 'function' and types.Door.record or nil
        )
        flags = buildFlagsFromScores(scores)
    end

    local topScoreType, topScoreValue = getTopScoredType(scores)
    local typeKey = choosePrimaryType(exterior, flags)
    local dwemerStaticCount = math.max(0, tonumber(staticMatchStats.dwemer) or 0)
    local lavaStaticCount = math.max(0, tonumber(staticMatchStats.lava) or 0)
    if not exterior and typeKey == 'volcanic' and dwemerStaticCount > lavaStaticCount then
        typeKey = 'dwemer'
    end
    return {
        cellId = cellId,
        isExterior = exterior,
        typeKey = typeKey,
        typeLabel = TYPE_LABELS[typeKey] or TYPE_LABELS.interior,
        flags = cloneFlags(flags),
        scannedStaticCount = scannedObjectCount,
        scannedObjectCount = scannedObjectCount,
        topScoreType = topScoreType,
        topScoreValue = tonumber(topScoreValue) or 0,
        dwemerStaticCount = dwemerStaticCount,
        lavaStaticCount = lavaStaticCount,
    }
end

local function getCellInfo(cell)
    if cell == nil then
        return {
            cellId = '',
            isExterior = false,
            typeKey = 'interior',
            typeLabel = TYPE_LABELS.interior,
            flags = {},
        }
    end

    local cellId = collectCellId(cell)
    if cellId ~= '' then
        local cached = cacheByCellId[cellId]
        if type(cached) == 'table' then
            return cached
        end
    end

    local evaluated = evaluateCell(cell)
    local scannedCount = tonumber(evaluated.scannedStaticCount) or 0
    local canCache = evaluated.isExterior == true
        or evaluated.typeKey ~= 'interior'
        or scannedCount > 0
    if cellId ~= '' and canCache then
        cacheByCellId[cellId] = evaluated
    end
    return evaluated
end

local DEFAULT_RUNTIME_INFO = {
    cellId = '',
    cellCacheKey = '',
    isExterior = false,
    typeKey = 'interior',
    typeLabel = 'Interior',
    region = '',
    regionId = '',
    regionName = '',
    exteriorRegion = '',
    exteriorRegionId = '',
    exteriorRegionName = '',
    scannedObjectCount = 0,
    topScoreType = '',
    topScoreValue = 0,
    campfireInfluence = 0,
    campfireSourceCount = 0,
    campfireActiveSourceCount = 0,
    campfireNearestDistance = nil,
    campfireNearestRecordId = '',
    campfireDominantSourceType = '',
    campfireDryingMultiplier = 1.0,
    campfireDryingSourceType = 'none',
    campfireScanActivatorScanned = 0,
    campfireScanActivatorMatched = 0,
    campfireScanLightScanned = 0,
    campfireScanLightMatched = 0,
    campfireScanStaticScanned = 0,
    campfireScanStaticMatched = 0,
    campfireScanFailureCount = 0,
    campfireScanFailures = {},
    campfireSources = {},
    campfireSourceSnapshotStamp = '',
    campfireSampleReady = false,
}

local function cloneRuntimeInfo(info)
    return {
        cellId = info.cellId,
        cellCacheKey = info.cellCacheKey,
        isExterior = info.isExterior,
        typeKey = info.typeKey,
        typeLabel = info.typeLabel,
        region = info.region,
        regionId = info.regionId,
        regionName = info.regionName,
        exteriorRegion = info.exteriorRegion,
        exteriorRegionId = info.exteriorRegionId,
        exteriorRegionName = info.exteriorRegionName,
        scannedObjectCount = info.scannedObjectCount,
        topScoreType = info.topScoreType,
        topScoreValue = info.topScoreValue,
        campfireInfluence = info.campfireInfluence,
        campfireSourceCount = info.campfireSourceCount,
        campfireActiveSourceCount = info.campfireActiveSourceCount,
        campfireNearestDistance = info.campfireNearestDistance,
        campfireNearestRecordId = info.campfireNearestRecordId,
        campfireDominantSourceType = info.campfireDominantSourceType,
        campfireDryingMultiplier = info.campfireDryingMultiplier,
        campfireDryingSourceType = info.campfireDryingSourceType,
        campfireScanActivatorScanned = info.campfireScanActivatorScanned,
        campfireScanActivatorMatched = info.campfireScanActivatorMatched,
        campfireScanLightScanned = info.campfireScanLightScanned,
        campfireScanLightMatched = info.campfireScanLightMatched,
        campfireScanStaticScanned = info.campfireScanStaticScanned,
        campfireScanStaticMatched = info.campfireScanStaticMatched,
        campfireScanFailureCount = info.campfireScanFailureCount,
        campfireScanFailures = type(info.campfireScanFailures) == 'table' and info.campfireScanFailures or {},
        campfireSources = cloneArray(type(info.campfireSources) == 'table' and info.campfireSources or {}),
        campfireSourceSnapshotStamp = normalizeKey(info.campfireSourceSnapshotStamp),
        campfireSampleReady = info.campfireSampleReady == true,
    }
end

local latestRuntimeInfo = cloneRuntimeInfo(DEFAULT_RUNTIME_INFO)

local function sanitizeRuntimeInfo(raw)
    local info = type(raw) == 'table' and raw or {}
    local typeKey = normalizeKey(info.typeKey)
    if typeKey == '' then
        typeKey = DEFAULT_RUNTIME_INFO.typeKey
    end

    local typeLabel = trim(tostring(info.typeLabel or ''))
    if typeLabel == '' then
        typeLabel = DEFAULT_RUNTIME_INFO.typeLabel
    end

    return {
        cellId = normalizeKey(info.cellId),
        cellCacheKey = normalizeKey(info.cellCacheKey),
        isExterior = info.isExterior == true,
        typeKey = typeKey,
        typeLabel = typeLabel,
        region = trim(tostring(info.region or '')),
        regionId = trim(tostring(info.regionId or '')),
        regionName = trim(tostring(info.regionName or '')),
        exteriorRegion = trim(tostring(info.exteriorRegion or '')),
        exteriorRegionId = trim(tostring(info.exteriorRegionId or '')),
        exteriorRegionName = trim(tostring(info.exteriorRegionName or '')),
        scannedObjectCount = math.max(0, tonumber(info.scannedObjectCount) or 0),
        topScoreType = normalizeKey(info.topScoreType),
        topScoreValue = math.max(0, tonumber(info.topScoreValue) or 0),
        campfireInfluence = math.max(0, tonumber(info.campfireInfluence) or 0),
        campfireSourceCount = math.max(0, tonumber(info.campfireSourceCount) or 0),
        campfireActiveSourceCount = math.max(0, tonumber(info.campfireActiveSourceCount) or 0),
        campfireNearestDistance = tonumber(info.campfireNearestDistance),
        campfireNearestRecordId = normalizeKey(info.campfireNearestRecordId),
        campfireDominantSourceType = normalizeKey(info.campfireDominantSourceType),
        campfireDryingMultiplier = math.max(1.0, tonumber(info.campfireDryingMultiplier) or 1.0),
        campfireDryingSourceType = normalizeKey(info.campfireDryingSourceType),
        campfireScanActivatorScanned = math.max(0, tonumber(info.campfireScanActivatorScanned) or 0),
        campfireScanActivatorMatched = math.max(0, tonumber(info.campfireScanActivatorMatched) or 0),
        campfireScanLightScanned = math.max(0, tonumber(info.campfireScanLightScanned) or 0),
        campfireScanLightMatched = math.max(0, tonumber(info.campfireScanLightMatched) or 0),
        campfireScanStaticScanned = math.max(0, tonumber(info.campfireScanStaticScanned) or 0),
        campfireScanStaticMatched = math.max(0, tonumber(info.campfireScanStaticMatched) or 0),
        campfireScanFailureCount = math.max(0, tonumber(info.campfireScanFailureCount) or 0),
        campfireScanFailures = type(info.campfireScanFailures) == 'table' and info.campfireScanFailures or {},
        campfireSources = cloneArray(type(info.campfireSources) == 'table' and info.campfireSources or {}),
        campfireSourceSnapshotStamp = normalizeKey(info.campfireSourceSnapshotStamp),
        campfireSampleReady = info.campfireSampleReady == true,
    }
end

local function setLatest(info)
    latestRuntimeInfo = sanitizeRuntimeInfo(info)
end

local function getLatest()
    return latestRuntimeInfo
end

local function getLatestForCell(cell)
    local currentCellId = ''
    local currentCellCacheKey = ''
    local currentCellIsExterior = false
    if cell ~= nil then
        local ok = pcall(function()
            currentCellId = normalizeKey(cell.id)
        end)
        if not ok then
            currentCellId = ''
        end
        currentCellCacheKey = collectCellCacheKey(cell)

        pcall(function()
            currentCellIsExterior = cell.isExterior == true
        end)
        if not currentCellIsExterior then
            pcall(function()
                if cell.hasSky == true and type(cell.hasTag) == 'function' then
                    currentCellIsExterior = cell:hasTag('QuasiExterior') == true
                end
            end)
        end
    end

    local lastKnownKey = normalizeKey(latestRuntimeInfo.cellCacheKey)
    if lastKnownKey == '' then
        lastKnownKey = normalizeKey(latestRuntimeInfo.cellId)
    end
    local currentKey = normalizeKey(currentCellCacheKey)
    if currentKey == '' then
        currentKey = normalizeKey(currentCellId)
    end
    if currentKey ~= '' and lastKnownKey ~= '' and lastKnownKey ~= currentKey then
        local info = cloneRuntimeInfo(DEFAULT_RUNTIME_INFO)
        info.cellId = currentCellId
        info.cellCacheKey = currentKey
        if currentCellIsExterior then
            info.isExterior = true
            info.typeKey = 'exterior'
            info.typeLabel = TYPE_LABELS.exterior or 'Exterior'
            info.region = latestRuntimeInfo.region
            info.regionId = latestRuntimeInfo.regionId
            info.regionName = latestRuntimeInfo.regionName
        end
        info.exteriorRegion = latestRuntimeInfo.exteriorRegion
        info.exteriorRegionId = latestRuntimeInfo.exteriorRegionId
        info.exteriorRegionName = latestRuntimeInfo.exteriorRegionName
        return info
    end

    return latestRuntimeInfo
end

local function reset()
    latestRuntimeInfo = cloneRuntimeInfo(DEFAULT_RUNTIME_INFO)
end

return {
    getCellInfo = getCellInfo,
    setLatest = setLatest,
    getLatest = getLatest,
    getLatestForCell = getLatestForCell,
    reset = reset,
}
