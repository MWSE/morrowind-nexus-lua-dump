local core = require('openmw.core')
local world = require('openmw.world')
local cellInfo = require('scripts.survivalmode.cellInfo')
local heatSourceSystem = require('scripts.survivalmode.temperature.heatSourceSystem')

local NEEDS_DYNAMIC_SPELL_REQUEST_EVENT = 'SurvivalNeeds_RequestDynamicDebuffSpell'
local NEEDS_DYNAMIC_SPELL_READY_EVENT = 'SurvivalNeeds_DynamicDebuffSpellReady'
local NEEDS_CELL_INFO_REQUEST_EVENT = 'SurvivalNeeds_RequestCellInfo'
local NEEDS_CELL_INFO_READY_EVENT = 'SurvivalNeeds_CellInfoReady'
local NEEDS_DEBUG_LOGGING_EVENT = 'SurvivalNeeds_SetDebugLoggingEnabled'
local NEEDS_UPSERT_DYNAMIC_HEAT_SOURCE_EVENT = 'SurvivalNeeds_UpsertDynamicHeatSource'
local NEEDS_REMOVE_DYNAMIC_HEAT_SOURCE_EVENT = 'SurvivalNeeds_RemoveDynamicHeatSource'
local latestExteriorRegionContext = {
    region = '',
    regionId = '',
    regionName = '',
}
local exteriorRegionContextCache = {}
local EXTERIOR_SEARCH_MAX_DEPTH = 48
local CELL_INFO_DEBUG_LOG = false
local CELL_INFO_DEBUG_REPEAT_MIN_INTERVAL_SECONDS = 5
local lastCellInfoDebugMessage = nil
local lastCellInfoDebugTime = -math.huge
local cachedTypesApi = nil
local cachedTypesSource = 'unresolved'
local dynamicSpellIdBySignature = {}
local cellInfoCampfirePayloadCacheByCellId = {}
local CAMPFIRE_PAYLOAD_POSITION_QUANTIZE_UNITS = 128

local function normalizeKey(value)
    if type(value) ~= 'string' then
        return ''
    end
    return string.lower(value:match('^%s*(.-)%s*$'))
end

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function sanitizeIdPart(value)
    local sanitized = normalizeKey(value)
    sanitized = sanitized:gsub('[^a-z0-9_]+', '_')
    sanitized = sanitized:gsub('_+', '_')
    sanitized = sanitized:gsub('^_+', '')
    sanitized = sanitized:gsub('_+$', '')
    if sanitized == '' then
        return 'x'
    end
    return sanitized
end

local function resolveTypesApi()
    local globalTypes = rawget(_G, 'types')
    if globalTypes ~= nil and (type(globalTypes) == 'table' or type(globalTypes) == 'userdata') then
        return globalTypes, 'global'
    end

    local ok, loaded = pcall(require, 'openmw.types')
    if ok and loaded ~= nil and (type(loaded) == 'table' or type(loaded) == 'userdata') then
        return loaded, 'require'
    end

    return nil, 'missing'
end

local function getTypesApi()
    local resolved, source = resolveTypesApi()
    if resolved ~= nil and (type(resolved) == 'table' or type(resolved) == 'userdata') then
        cachedTypesApi = resolved
        cachedTypesSource = source
        return cachedTypesApi, cachedTypesSource
    end

    if cachedTypesApi ~= nil and (type(cachedTypesApi) == 'table' or type(cachedTypesApi) == 'userdata') then
        return cachedTypesApi, cachedTypesSource
    end

    return nil, source
end

local function getDoorApi()
    local typesApi, source = getTypesApi()
    if typesApi == nil or (type(typesApi) ~= 'table' and type(typesApi) ~= 'userdata') then
        return nil, source
    end
    local doorApi = typesApi.Door
    if doorApi == nil or (type(doorApi) ~= 'table' and type(doorApi) ~= 'userdata') then
        return nil, source
    end
    return doorApi, source
end

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function normalizeEffect(rawEffect)
    if type(rawEffect) ~= 'table' then
        return nil
    end

    local effectId = normalizeKey(rawEffect.id)
    if effectId == '' then
        return nil
    end

    local magnitudeMin = math.max(0, round(rawEffect.magnitudeMin or rawEffect.magnitude or 0))
    local magnitudeMax = math.max(0, round(rawEffect.magnitudeMax or magnitudeMin))
    if magnitudeMax < magnitudeMin then
        magnitudeMax = magnitudeMin
    end

    local effect = {
        id = effectId,
        range = core.magic.RANGE.Self,
        area = 0,
        duration = 0,
        magnitudeMin = magnitudeMin,
        magnitudeMax = magnitudeMax,
    }

    local affectedSkill = normalizeKey(rawEffect.affectedSkill)
    if affectedSkill ~= '' then
        effect.affectedSkill = affectedSkill
    end

    local affectedAttribute = normalizeKey(rawEffect.affectedAttribute)
    if affectedAttribute ~= '' then
        effect.affectedAttribute = affectedAttribute
    end

    return effect
end

local function buildNormalizedEffects(rawEffects)
    if type(rawEffects) ~= 'table' then
        return {}
    end

    local effects = {}
    for _, rawEffect in ipairs(rawEffects) do
        local normalized = normalizeEffect(rawEffect)
        if normalized ~= nil then
            effects[#effects + 1] = normalized
        end
    end
    return effects
end

local function ensureDynamicSpellRecord(spellName, effects)
    local draft = core.magic.spells.createRecordDraft({
        name = spellName,
        type = core.magic.SPELL_TYPE.Ability,
        cost = 0,
        alwaysSucceedFlag = true,
        starterSpellFlag = false,
        isAutocalc = false,
        effects = effects,
    })

    local createdRecord = world.createRecord(draft)
    local createdSpellId = trim(tostring(createdRecord.id or ''))
    if createdSpellId == '' then
        error('world.createRecord returned a spell record without a valid id')
    end

    return createdSpellId
end

local function buildDynamicSpellSignature(spellName, effects)
    local parts = { trim(tostring(spellName or '')) }
    if type(effects) == 'table' then
        for _, effect in ipairs(effects) do
            if type(effect) == 'table' then
                parts[#parts + 1] = table.concat({
                    normalizeKey(effect.id),
                    normalizeKey(effect.affectedAttribute),
                    normalizeKey(effect.affectedSkill),
                    tostring(math.max(0, tonumber(effect.magnitudeMin) or 0)),
                    tostring(math.max(0, tonumber(effect.magnitudeMax) or 0)),
                }, ':')
            end
        end
    end
    return table.concat(parts, '|')
end

local function hasSpellRecordById(spellId)
    local id = trim(tostring(spellId or ''))
    if id == '' then
        return false
    end

    local records = core.magic.spells.records
    if records == nil then
        return false
    end
    return records[id] ~= nil or records[string.lower(id)] ~= nil
end

local function getOrCreateDynamicSpellRecord(spellName, effects)
    local signature = buildDynamicSpellSignature(spellName, effects)
    local cachedSpellId = dynamicSpellIdBySignature[signature]
    if hasSpellRecordById(cachedSpellId) then
        return cachedSpellId
    end

    local spellId = ensureDynamicSpellRecord(spellName, effects)
    dynamicSpellIdBySignature[signature] = spellId
    return spellId
end

local function sendReadyEvent(player, payload)
    local ok, err = pcall(function()
        player:sendEvent(NEEDS_DYNAMIC_SPELL_READY_EVENT, payload)
    end)
    if not ok then
        print(string.format('[SurvivalMode] Failed to send dynamic debuff response: %s', tostring(err)))
    end
end

local function sendCellInfoEvent(player, payload)
    local ok, err = pcall(function()
        player:sendEvent(NEEDS_CELL_INFO_READY_EVENT, payload)
    end)
    if not ok then
        print(string.format('[SurvivalMode] Failed to send cell info response: %s', tostring(err)))
    end
end

local function getPlayerCellId(player)
    if player == nil then
        return ''
    end

    local cell = nil
    local cellOk = pcall(function()
        cell = player.cell
    end)
    if not cellOk or cell == nil then
        return ''
    end

    local cellId = ''
    local idOk = pcall(function()
        cellId = trim(tostring(cell.id or ''))
    end)
    if not idOk then
        return ''
    end
    return normalizeKey(cellId)
end

local function getCellCacheKeyFromCell(cell)
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
    local idOk = pcall(function()
        cellId = trim(tostring(cell.id or ''))
    end)
    if not idOk then
        return ''
    end
    return normalizeKey(cellId)
end

local function readCellRegionContext(cell)
    local context = {
        region = '',
        regionId = '',
        regionName = '',
    }
    if cell == nil then
        return context
    end

    local function readStringField(container, fieldName)
        if container == nil then
            return ''
        end
        local ok, fieldValue = pcall(function()
            return container[fieldName]
        end)
        if ok and type(fieldValue) == 'string' then
            return trim(fieldValue)
        end
        return ''
    end

    local function extractStringFromValue(value)
        if type(value) == 'string' then
            return trim(value)
        end
        if type(value) ~= 'table' and type(value) ~= 'userdata' then
            return ''
        end

        local candidates = {
            readStringField(value, 'id'),
            readStringField(value, 'recordId'),
            readStringField(value, 'name'),
            readStringField(value, 'region'),
            readStringField(value, 'regionId'),
            readStringField(value, 'regionName'),
        }
        for _, candidate in ipairs(candidates) do
            if candidate ~= '' then
                return candidate
            end
        end
        return ''
    end

    local function readField(fieldName)
        local ok, fieldValue = pcall(function()
            return cell[fieldName]
        end)
        if ok then
            return extractStringFromValue(fieldValue)
        end
        return ''
    end

    context.region = readField('region')
    context.regionId = readField('regionId')
    context.regionName = readField('regionName')
    if context.region == '' then
        context.region = context.regionId
    end
    if context.regionId == '' then
        context.regionId = context.region
    end
    if context.regionName == '' then
        context.regionName = context.region
    end
    return context
end

local function hasRegionContext(context)
    return type(context) == 'table'
        and (
            trim(tostring(context.region or '')) ~= ''
            or trim(tostring(context.regionId or '')) ~= ''
            or trim(tostring(context.regionName or '')) ~= ''
        )
end

local function cloneRegionContext(context)
    if type(context) ~= 'table' then
        return {
            region = '',
            regionId = '',
            regionName = '',
        }
    end
    return {
        region = trim(tostring(context.region or '')),
        regionId = trim(tostring(context.regionId or '')),
        regionName = trim(tostring(context.regionName or '')),
    }
end

local function setPayloadExteriorRegionContext(payload, context)
    if type(payload) ~= 'table' then
        return
    end
    local safeContext = cloneRegionContext(context)
    payload.exteriorRegion = safeContext.region
    payload.exteriorRegionId = safeContext.regionId
    payload.exteriorRegionName = safeContext.regionName
end

local function applyLatestExteriorRegionContext(payload)
    setPayloadExteriorRegionContext(payload, latestExteriorRegionContext)
end

local function updateLatestExteriorRegionContext(context)
    if not hasRegionContext(context) then
        return false
    end
    latestExteriorRegionContext = cloneRegionContext(context)
    return true
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

    local fallback = ''
    pcall(function()
        fallback = tostring(cell)
    end)
    if fallback ~= '' then
        return fallback
    end

    return '<unknown>'
end

local function logCellInfoDebug(message)
    if CELL_INFO_DEBUG_LOG ~= true then
        return
    end
    local text = tostring(message)
    local currentTime = 0
    if type(core.getGameTime) == 'function' then
        local ok, value = pcall(core.getGameTime)
        if ok then
            currentTime = tonumber(value) or 0
        end
    end

    local elapsed = currentTime - (tonumber(lastCellInfoDebugTime) or -math.huge)
    if lastCellInfoDebugMessage == text and elapsed >= 0 and elapsed < CELL_INFO_DEBUG_REPEAT_MIN_INTERVAL_SECONDS then
        return
    end

    lastCellInfoDebugMessage = text
    lastCellInfoDebugTime = currentTime
    print(string.format('[SurvivalMode][CellInfoDebug] %s', text))
end

local function getCellVisitKey(cell)
    if cell == nil then
        return ''
    end

    local key = ''
    local idOk = pcall(function()
        key = normalizeKey(trim(tostring(cell.id or '')))
    end)
    if idOk and key ~= '' then
        return key
    end

    local gridX = nil
    local gridY = nil
    local gridOk = pcall(function()
        gridX = tonumber(cell.gridX)
        gridY = tonumber(cell.gridY)
    end)
    if gridOk and gridX ~= nil and gridY ~= nil then
        return string.format('grid:%d:%d', math.floor(gridX), math.floor(gridY))
    end

    local fallbackOk, fallbackValue = pcall(function()
        return tostring(cell)
    end)
    if fallbackOk and type(fallbackValue) == 'string' then
        return normalizeKey(fallbackValue)
    end

    return ''
end

local function readPositionVector(value)
    if value == nil then
        return nil
    end

    local ok, x, y, z = pcall(function()
        return tonumber(value.x), tonumber(value.y), tonumber(value.z)
    end)
    if not ok or x == nil or y == nil or z == nil then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function quantizePositionComponent(value, step)
    local component = tonumber(value)
    if component == nil then
        return 0
    end
    local divisor = tonumber(step) or 1
    if divisor <= 0 then
        divisor = 1
    end
    return math.floor((component / divisor) + 0.5)
end

local function buildQuantizedPositionToken(position)
    if position == nil then
        return 'npos'
    end
    return string.format(
        '%d:%d:%d',
        quantizePositionComponent(position.x, CAMPFIRE_PAYLOAD_POSITION_QUANTIZE_UNITS),
        quantizePositionComponent(position.y, CAMPFIRE_PAYLOAD_POSITION_QUANTIZE_UNITS),
        quantizePositionComponent(position.z, CAMPFIRE_PAYLOAD_POSITION_QUANTIZE_UNITS)
    )
end

local function applyCampfirePayloadFields(payload, value)
    if type(payload) ~= 'table' or type(value) ~= 'table' then
        return
    end

    payload.campfireInfluence = math.max(0, tonumber(value.campfireInfluence) or 0)
    payload.campfireSourceCount = math.max(0, tonumber(value.campfireSourceCount) or 0)
    payload.campfireActiveSourceCount = math.max(0, tonumber(value.campfireActiveSourceCount) or 0)
    payload.campfireNearestDistance = tonumber(value.campfireNearestDistance)
    payload.campfireNearestRecordId = normalizeKey(value.campfireNearestRecordId)
    payload.campfireDominantSourceType = normalizeKey(value.campfireDominantSourceType)
    payload.campfireDryingMultiplier = math.max(1.0, tonumber(value.campfireDryingMultiplier) or 1.0)
    payload.campfireDryingSourceType = normalizeKey(value.campfireDryingSourceType)
    payload.campfireScanActivatorScanned = math.max(0, tonumber(value.campfireScanActivatorScanned) or 0)
    payload.campfireScanActivatorMatched = math.max(0, tonumber(value.campfireScanActivatorMatched) or 0)
    payload.campfireScanLightScanned = math.max(0, tonumber(value.campfireScanLightScanned) or 0)
    payload.campfireScanLightMatched = math.max(0, tonumber(value.campfireScanLightMatched) or 0)
    payload.campfireScanStaticScanned = math.max(0, tonumber(value.campfireScanStaticScanned) or 0)
    payload.campfireScanStaticMatched = math.max(0, tonumber(value.campfireScanStaticMatched) or 0)
    payload.campfireScanFailures = type(value.campfireScanFailures) == 'table' and value.campfireScanFailures or {}
    payload.campfireScanFailureCount = #payload.campfireScanFailures
    payload.campfireSampleReady = value.campfireSampleReady == true
    payload.campfireSourceSnapshotStamp = normalizeKey(value.campfireSourceSnapshotStamp)
end

local function distanceSq(a, b)
    if a == nil or b == nil then
        return math.huge
    end

    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    local dz = (tonumber(a.z) or 0) - (tonumber(b.z) or 0)
    return (dx * dx) + (dy * dy) + (dz * dz)
end

local function isQuasiExteriorCell(cell)
    if cell == nil or type(cell.hasTag) ~= 'function' then
        return false
    end

    local hasSky = false
    local hasSkyOk = pcall(function()
        hasSky = cell.hasSky == true
    end)
    if not hasSkyOk or not hasSky then
        return false
    end

    local tagOk, isQuasiExterior = pcall(function()
        return cell:hasTag('QuasiExterior')
    end)
    return tagOk and isQuasiExterior == true
end

local function isExteriorLikeCell(cell)
    if cell == nil then
        return false
    end

    local exteriorOk, isExterior = pcall(function()
        return cell.isExterior == true
    end)
    if exteriorOk and isExterior then
        return true
    end

    return isQuasiExteriorCell(cell)
end

local function collectTeleportDestinations(cell, originPosition)
    local destinations = {}
    local doorApi, doorApiSource = getDoorApi()
    local trace = {
        scannedDoors = 0,
        teleportDoors = 0,
        destinationLinks = 0,
        doorApiSource = tostring(doorApiSource or ''),
    }
    if cell == nil
        or type(cell.getAll) ~= 'function'
        or doorApi == nil
        or (type(doorApi) ~= 'table' and type(doorApi) ~= 'userdata') then
        return destinations, trace
    end

    local doorsOk, doors = pcall(function()
        return cell:getAll(doorApi)
    end)
    if not doorsOk or doors == nil then
        return destinations, trace
    end

    local originVector = readPositionVector(originPosition)
    local function addDoorDestination(door)
        if door == nil then
            return
        end

        trace.scannedDoors = trace.scannedDoors + 1
        local isTeleport = false
        if type(doorApi.isTeleport) == 'function' then
            local isTeleportOk = false
            isTeleportOk, isTeleport = pcall(function()
                return doorApi.isTeleport(door)
            end)
            if not isTeleportOk then
                isTeleport = false
            end
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
        if type(doorApi.destCell) == 'function' then
            local destCellOk = false
            destCellOk, destCell = pcall(function()
                return doorApi.destCell(door)
            end)
            if not destCellOk then
                destCell = nil
            end
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
        if type(doorApi.destPosition) == 'function' then
            pcall(function()
                destPosition = doorApi.destPosition(door)
            end)
        end
        if destPosition == nil then
            pcall(function()
                destPosition = door.destPosition
            end)
        end
        local doorPosition = nil
        pcall(function()
            doorPosition = door.position
        end)
        local distanceToDoor = distanceSq(readPositionVector(doorPosition), originVector)

        destinations[#destinations + 1] = {
            cell = destCell,
            position = destPosition,
            distanceSq = distanceToDoor,
        }
        trace.destinationLinks = trace.destinationLinks + 1
    end

    local scanned = 0
    local ipairsOk = pcall(function()
        for _, door in ipairs(doors) do
            scanned = scanned + 1
            addDoorDestination(door)
        end
    end)
    if not ipairsOk or scanned == 0 then
        pcall(function()
            for _, door in pairs(doors) do
                addDoorDestination(door)
            end
        end)
    end

    table.sort(destinations, function(a, b)
        return (tonumber(a.distanceSq) or math.huge) < (tonumber(b.distanceSq) or math.huge)
    end)
    return destinations, trace
end

local function findClosestExteriorRegionContext(startCell, startPosition)
    local doorApi, doorApiSource = getDoorApi()
    local trace = {
        startCell = describeCell(startCell),
        visitedCells = 0,
        scannedDoors = 0,
        teleportDoors = 0,
        destinationLinks = 0,
        doorApiSource = tostring(doorApiSource or ''),
        maxDepthReached = 0,
        foundExteriorCell = '',
        foundRegion = '',
        reason = '',
    }
    if startCell == nil then
        trace.reason = 'start_cell_nil'
        return nil, trace
    end
    if doorApi == nil or (type(doorApi) ~= 'table' and type(doorApi) ~= 'userdata') then
        trace.reason = string.format('door_api_unavailable:%s', trace.doorApiSource)
        return nil, trace
    end

    local queue = {
        {
            cell = startCell,
            position = startPosition,
            depth = 0,
        },
    }
    local nextIndex = 1
    local traversed = {}

    while nextIndex <= #queue do
        local current = queue[nextIndex]
        nextIndex = nextIndex + 1
        local currentCell = current.cell
        local currentDepth = tonumber(current.depth) or 0
        if currentDepth > trace.maxDepthReached then
            trace.maxDepthReached = currentDepth
        end
        local visitKey = getCellVisitKey(currentCell)
        if visitKey ~= '' and traversed[visitKey] ~= true then
            traversed[visitKey] = true
            trace.visitedCells = trace.visitedCells + 1
            if isExteriorLikeCell(currentCell) then
                local regionContext = readCellRegionContext(currentCell)
                if hasRegionContext(regionContext) then
                    trace.foundExteriorCell = describeCell(currentCell)
                    trace.foundRegion = trim(tostring(regionContext.regionName or regionContext.region or regionContext.regionId or ''))
                    trace.reason = 'matched_exterior'
                    return regionContext, trace
                end
            end

            if currentDepth < EXTERIOR_SEARCH_MAX_DEPTH then
                local destinations, doorTrace = collectTeleportDestinations(currentCell, current.position)
                if type(doorTrace) == 'table' then
                    trace.scannedDoors = trace.scannedDoors + (tonumber(doorTrace.scannedDoors) or 0)
                    trace.teleportDoors = trace.teleportDoors + (tonumber(doorTrace.teleportDoors) or 0)
                    trace.destinationLinks = trace.destinationLinks + (tonumber(doorTrace.destinationLinks) or 0)
                    if trace.doorApiSource == '' then
                        trace.doorApiSource = tostring(doorTrace.doorApiSource or '')
                    end
                end
                for _, destination in ipairs(destinations) do
                    local destinationCell = destination.cell
                    local destinationKey = getCellVisitKey(destinationCell)
                    if destinationKey ~= '' and traversed[destinationKey] ~= true then
                        queue[#queue + 1] = {
                            cell = destinationCell,
                            position = destination.position,
                            depth = currentDepth + 1,
                        }
                    end
                end
            end
        end
    end

    trace.reason = 'no_reachable_exterior'
    return nil, trace
end

local function getCachedExteriorRegionContext(cellId)
    local key = normalizeKey(cellId)
    if key == '' then
        return nil
    end

    local cached = exteriorRegionContextCache[key]
    if not hasRegionContext(cached) then
        return nil
    end

    return cloneRegionContext(cached)
end

local function cacheExteriorRegionContext(cellId, context)
    local key = normalizeKey(cellId)
    if key == '' or not hasRegionContext(context) then
        return
    end
    exteriorRegionContextCache[key] = cloneRegionContext(context)
end

local function onRequestDynamicDebuffSpell(data)
    if type(data) ~= 'table' then
        return
    end

    local player = data.player
    if player == nil then
        print('[SurvivalMode] Dynamic debuff request missing player object.')
        return
    end

    local category = sanitizeIdPart(data.category)
    local stageId = sanitizeIdPart(data.stageId)
    local requestId = tonumber(data.requestId)
    local spellName = tostring(data.spellName or '')

    local effects = buildNormalizedEffects(data.effects)
    if #effects == 0 then
        sendReadyEvent(player, {
            category = category,
            stageId = stageId,
            requestId = requestId,
            spellId = nil,
        })
        return
    end

    local spellId = nil
    local ok, err = pcall(function()
        spellId = getOrCreateDynamicSpellRecord(spellName, effects)
    end)
    if not ok then
        print(string.format(
            '[SurvivalMode] Failed to create dynamic debuff spell for %s/%s: %s',
            category,
            stageId,
            tostring(err)
        ))
        sendReadyEvent(player, {
            category = category,
            stageId = stageId,
            requestId = requestId,
            spellId = nil,
        })
        return
    end

    sendReadyEvent(player, {
        category = category,
        stageId = stageId,
        requestId = requestId,
        spellId = spellId,
    })
end

local function onSetDebugLoggingEnabled(data)
    CELL_INFO_DEBUG_LOG = type(data) == 'table' and data.enabled == true
    if CELL_INFO_DEBUG_LOG ~= true then
        lastCellInfoDebugMessage = nil
        lastCellInfoDebugTime = -math.huge
    end
end

local onRequestCellInfo

local function resolvePlayerCellCacheKey(player)
    if player == nil then
        return ''
    end
    local playerCell = nil
    local ok = pcall(function()
        playerCell = player.cell
    end)
    if not ok then
        return ''
    end
    return getCellCacheKeyFromCell(playerCell)
end

local function requestCellInfoRefreshForMutation(player, expectedCellCacheKey)
    if player == nil or type(onRequestCellInfo) ~= 'function' then
        return
    end
    local normalizedExpectedCellCacheKey = normalizeKey(expectedCellCacheKey)
    if normalizedExpectedCellCacheKey == '' then
        return
    end
    local playerCellCacheKey = resolvePlayerCellCacheKey(player)
    if playerCellCacheKey ~= normalizedExpectedCellCacheKey then
        return
    end
    onRequestCellInfo({ player = player })
end

local function onUpsertDynamicHeatSource(data)
    if type(data) ~= 'table' then
        return
    end
    if type(heatSourceSystem.upsertDynamicHeatSource) ~= 'function' then
        return
    end

    local cellCacheKey = normalizeKey(data.cellCacheKey)
    if cellCacheKey == '' then
        cellCacheKey = normalizeKey(data.cellId)
    end
    if cellCacheKey == '' and data.player ~= nil then
        local playerCell = nil
        pcall(function()
            playerCell = data.player.cell
        end)
        cellCacheKey = getCellCacheKeyFromCell(playerCell)
    end

    if cellCacheKey == '' then
        return
    end
    local updated = false
    pcall(function()
        updated = heatSourceSystem.upsertDynamicHeatSource(cellCacheKey, data.source or data) == true
    end)
    if updated then
        requestCellInfoRefreshForMutation(data.player, cellCacheKey)
    end
end

local function onRemoveDynamicHeatSource(data)
    if type(data) ~= 'table' then
        return
    end
    if type(heatSourceSystem.removeDynamicHeatSource) ~= 'function' then
        return
    end

    local cellCacheKey = normalizeKey(data.cellCacheKey)
    if cellCacheKey == '' then
        cellCacheKey = normalizeKey(data.cellId)
    end
    if cellCacheKey == '' and data.player ~= nil then
        local playerCell = nil
        pcall(function()
            playerCell = data.player.cell
        end)
        cellCacheKey = getCellCacheKeyFromCell(playerCell)
    end

    if cellCacheKey == '' then
        return
    end
    local removed = false
    pcall(function()
        removed = heatSourceSystem.removeDynamicHeatSource(cellCacheKey, data.source or data) == true
    end)
    if removed then
        requestCellInfoRefreshForMutation(data.player, cellCacheKey)
    end
end

onRequestCellInfo = function(data)
    if type(data) ~= 'table' then
        return
    end

    local player = data.player
    if player == nil then
        return
    end

    local payload = {
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

    local ok, err = pcall(function()
        local playerCell = player.cell
        payload.cellCacheKey = getCellCacheKeyFromCell(playerCell)
        if payload.cellCacheKey == '' then
            payload.cellCacheKey = normalizeKey(data.cellCacheKey)
        end
        local detected = cellInfo.getCellInfo(playerCell)
        if type(detected) == 'table' then
            local detectedCellId = normalizeKey(detected.cellId)
            if detectedCellId == '' then
                detectedCellId = getPlayerCellId(player)
            end
            payload.cellId = detectedCellId
            payload.isExterior = detected.isExterior == true
            payload.typeKey = normalizeKey(detected.typeKey)
            if payload.typeKey == '' then
                payload.typeKey = 'interior'
            end
            payload.typeLabel = trim(tostring(detected.typeLabel or ''))
            if payload.typeLabel == '' then
                payload.typeLabel = 'Interior'
            end
            local regionContext = readCellRegionContext(playerCell)
            payload.region = regionContext.region
            payload.regionId = regionContext.regionId
            payload.regionName = regionContext.regionName
            payload.scannedObjectCount = math.max(
                0,
                tonumber(detected.scannedObjectCount) or tonumber(detected.scannedStaticCount) or 0
            )
            payload.topScoreType = normalizeKey(detected.topScoreType)
            payload.topScoreValue = math.max(0, tonumber(detected.topScoreValue) or 0)
            if type(heatSourceSystem.getCellHeatSourceSnapshot) == 'function'
                and type(heatSourceSystem.getCampfireModifierForCachedSources) == 'function' then
                local playerPosition = nil
                pcall(function()
                    playerPosition = player.position
                end)
                local heatSnapshot = heatSourceSystem.getCellHeatSourceSnapshot(playerCell, false)
                payload.campfireSources = type(heatSnapshot.sources) == 'table' and heatSnapshot.sources or {}
                local diagnostics = type(heatSnapshot.diagnostics) == 'table' and heatSnapshot.diagnostics or {}
                payload.campfireSourceSnapshotStamp = normalizeKey(heatSnapshot.sourceSnapshotStamp)

                local quantizedPositionToken = buildQuantizedPositionToken(readPositionVector(playerPosition))
                local sourceSnapshotStamp = payload.campfireSourceSnapshotStamp
                if sourceSnapshotStamp == '' then
                    sourceSnapshotStamp = 'missing'
                end
                local campfireCacheKey = payload.cellId ~= '' and payload.cellId or detectedCellId
                if payload.cellCacheKey ~= '' then
                    campfireCacheKey = payload.cellCacheKey
                end
                local campfirePayloadSignature = table.concat({
                    normalizeKey(campfireCacheKey),
                    quantizedPositionToken,
                    sourceSnapshotStamp,
                }, '|')
                local cachedCampfirePayload = nil
                if campfireCacheKey ~= '' then
                    local cachedEntry = cellInfoCampfirePayloadCacheByCellId[campfireCacheKey]
                    if type(cachedEntry) == 'table' and cachedEntry.signature == campfirePayloadSignature then
                        cachedCampfirePayload = cachedEntry.payload
                    end
                end

                if type(cachedCampfirePayload) == 'table' then
                    applyCampfirePayloadFields(payload, cachedCampfirePayload)
                else
                    local campfireData = heatSourceSystem.getCampfireModifierForCachedSources(
                        payload.campfireSources,
                        playerPosition,
                        {
                            -- Influence is climate-agnostic; final warmth is computed in player script
                            -- using detected region category and interior rules.
                            regionCategory = 'neutral',
                            isExteriorCell = true,
                            cellTypeSignedModifier = 0,
                            actor = player,
                            cellCacheKey = heatSnapshot.cacheKey or campfireCacheKey,
                            sourceSnapshotStamp = payload.campfireSourceSnapshotStamp,
                        }
                    )
                    local computedCampfirePayload = {
                        campfireInfluence = math.max(0, tonumber(campfireData.influence) or 0),
                        campfireSourceCount = math.max(
                            0,
                            tonumber(campfireData.sourceCount) or #payload.campfireSources
                        ),
                        campfireActiveSourceCount = math.max(0, tonumber(campfireData.activeSourceCount) or 0),
                        campfireNearestDistance = tonumber(campfireData.nearestDistance),
                        campfireNearestRecordId = normalizeKey(campfireData.nearestRecordId),
                        campfireDominantSourceType = normalizeKey(campfireData.dominantSourceType),
                        campfireDryingMultiplier = math.max(1.0, tonumber(campfireData.dryingMultiplier) or 1.0),
                        campfireDryingSourceType = normalizeKey(campfireData.dryingSourceType),
                        campfireScanActivatorScanned = math.max(0, tonumber(diagnostics.activatorScanned) or 0),
                        campfireScanActivatorMatched = math.max(0, tonumber(diagnostics.activatorMatched) or 0),
                        campfireScanLightScanned = math.max(0, tonumber(diagnostics.lightScanned) or 0),
                        campfireScanLightMatched = math.max(0, tonumber(diagnostics.lightMatched) or 0),
                        campfireScanStaticScanned = math.max(0, tonumber(diagnostics.staticScanned) or 0),
                        campfireScanStaticMatched = math.max(0, tonumber(diagnostics.staticMatched) or 0),
                        campfireScanFailures = type(diagnostics.getAllFailures) == 'table'
                            and diagnostics.getAllFailures
                            or {},
                        campfireSampleReady = true,
                        campfireSourceSnapshotStamp = payload.campfireSourceSnapshotStamp,
                    }
                    applyCampfirePayloadFields(payload, computedCampfirePayload)
                    if campfireCacheKey ~= '' then
                        cellInfoCampfirePayloadCacheByCellId[campfireCacheKey] = {
                            signature = campfirePayloadSignature,
                            payload = computedCampfirePayload,
                        }
                    end
                end
                payload.campfireSampleReady = true
            end

            if payload.isExterior == true then
                updateLatestExteriorRegionContext(regionContext)
                applyLatestExteriorRegionContext(payload)
                logCellInfoDebug(string.format(
                    'cell="%s" exterior=true region="%s" regionId="%s" regionName="%s"',
                    tostring(payload.cellId or ''),
                    tostring(payload.region or ''),
                    tostring(payload.regionId or ''),
                    tostring(payload.regionName or '')
                ))
            else
                local exteriorContext = getCachedExteriorRegionContext(payload.cellId)
                local traversalTrace = nil
                local exteriorSource = 'cache'
                if exteriorContext == nil then
                    local playerPosition = nil
                    pcall(function()
                        playerPosition = player.position
                    end)
                    exteriorContext, traversalTrace = findClosestExteriorRegionContext(playerCell, playerPosition)
                    if exteriorContext ~= nil then
                        cacheExteriorRegionContext(payload.cellId, exteriorContext)
                        exteriorSource = 'traversal'
                    else
                        exteriorSource = 'latest_fallback'
                    end
                end

                if exteriorContext ~= nil then
                    updateLatestExteriorRegionContext(exteriorContext)
                    setPayloadExteriorRegionContext(payload, exteriorContext)
                else
                    applyLatestExteriorRegionContext(payload)
                end
                logCellInfoDebug(string.format(
                    'cell="%s" exterior=false source=%s extRegion="%s" extRegionId="%s" extRegionName="%s" traversal={start="%s",api="%s",reason="%s",visited=%d,doors=%d,teleport=%d,links=%d,depth=%d,matchCell="%s",matchRegion="%s"}',
                    tostring(payload.cellId or ''),
                    tostring(exteriorSource or ''),
                    tostring(payload.exteriorRegion or ''),
                    tostring(payload.exteriorRegionId or ''),
                    tostring(payload.exteriorRegionName or ''),
                    traversalTrace ~= nil and tostring(traversalTrace.startCell or '') or '',
                    traversalTrace ~= nil and tostring(traversalTrace.doorApiSource or '') or '',
                    traversalTrace ~= nil and tostring(traversalTrace.reason or '') or '',
                    traversalTrace ~= nil and (tonumber(traversalTrace.visitedCells) or 0) or 0,
                    traversalTrace ~= nil and (tonumber(traversalTrace.scannedDoors) or 0) or 0,
                    traversalTrace ~= nil and (tonumber(traversalTrace.teleportDoors) or 0) or 0,
                    traversalTrace ~= nil and (tonumber(traversalTrace.destinationLinks) or 0) or 0,
                    traversalTrace ~= nil and (tonumber(traversalTrace.maxDepthReached) or 0) or 0,
                    traversalTrace ~= nil and tostring(traversalTrace.foundExteriorCell or '') or '',
                    traversalTrace ~= nil and tostring(traversalTrace.foundRegion or '') or ''
                ))
            end
        else
            payload.cellId = getPlayerCellId(player)
            if payload.cellCacheKey == '' then
                payload.cellCacheKey = getCellCacheKeyFromCell(player.cell)
            end
            applyLatestExteriorRegionContext(payload)
        end
    end)
    if not ok then
        payload.cellId = getPlayerCellId(player)
        if payload.cellCacheKey == '' then
            payload.cellCacheKey = getCellCacheKeyFromCell(player.cell)
        end
        applyLatestExteriorRegionContext(payload)
        print(string.format('[SurvivalMode] Failed to compute cell info: %s', tostring(err)))
    end

    sendCellInfoEvent(player, payload)
end

return {
    eventHandlers = {
        [NEEDS_DYNAMIC_SPELL_REQUEST_EVENT] = onRequestDynamicDebuffSpell,
        [NEEDS_CELL_INFO_REQUEST_EVENT] = onRequestCellInfo,
        [NEEDS_DEBUG_LOGGING_EVENT] = onSetDebugLoggingEnabled,
        [NEEDS_UPSERT_DYNAMIC_HEAT_SOURCE_EVENT] = onUpsertDynamicHeatSource,
        [NEEDS_REMOVE_DYNAMIC_HEAT_SOURCE_EVENT] = onRemoveDynamicHeatSource,
    },
}
