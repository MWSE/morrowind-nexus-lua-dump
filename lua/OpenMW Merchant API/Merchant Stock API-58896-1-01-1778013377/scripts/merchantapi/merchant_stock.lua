local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local markup = require('openmw.markup')
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')

local RESTOCK_SETTINGS_KEY = 'RestockReimplSettings'
local RESTOCK_DELAY_KEY = 'RESTOCK_DELAY_DAYS'
local SECONDS_PER_DAY = 24 * 60 * 60
local REGION_TRAVERSAL_MAX_DEPTH = 48
local MERCHANT_STOCK_DIALOGUE_OPEN_EVENT = 'MerchantStock_DialogueOpen'

local DEFAULT_CONFIG = {
    itemCountDefault = 120,
    quantityMinDefault = 2,
    quantityMaxDefault = 8,
    quantityBiasDefault = 0.60,
}
local ITEM_COUNT_MIN = 1
local ITEM_COUNT_MAX = 9999
local QUANTITY_MIN = 1
local QUANTITY_MAX = 9999

local restockSettings = storage.globalSection(RESTOCK_SETTINGS_KEY)
-- Mutable runtime and save-backed caches.
local state = {
    poolLoaded = false,
    stockRules = {},
    regionGroups = {},
    ruleKeySeen = {},
    merchantPlans = {},
    lastRefillDays = {},
    exteriorRegionValuesByCell = {},
    config = {},
    validation = { warnings = 0, errors = 0 },
}

local function normalize(value)
    return type(value) == 'string' and string.lower((value:gsub('^%s+', ''):gsub('%s+$', ''))) or ''
end

-- Similar to normalize(), but removes punctuation for loose matching.
local function normalizeLoose(value)
    return normalize(value):gsub('[^%a%d]', '')
end

local function splitWords(value)
    local words = {}
    local norm = normalize(value):gsub('[^%a%d]+', ' ')
    for word in norm:gmatch('%S+') do
        words[#words + 1] = word
    end
    return words
end

local function allTokenWordsPresent(value, token)
    local tokenWords = splitWords(token)
    if #tokenWords == 0 then return false end
    local valueWordSet = {}
    for _, word in ipairs(splitWords(value)) do valueWordSet[word] = true end
    for _, tokenWord in ipairs(tokenWords) do
        if valueWordSet[tokenWord] ~= true then return false end
    end
    return true
end

local function appendUnique(list, seen, value)
    local token = normalize(value)
    if token == '' or seen[token] == true then return end
    seen[token] = true
    list[#list + 1] = token
end

local function appendAnyToken(list, seen, value)
    if value == nil then return end
    local valueType = type(value)
    if valueType == 'string' or valueType == 'number' then
        appendUnique(list, seen, tostring(value))
        return
    end
    if valueType == 'table' or valueType == 'userdata' then
        local fieldId, fieldName, fieldRecordId, fieldDisplayName = nil, nil, nil, nil
        pcall(function() fieldId = value.id end)
        pcall(function() fieldName = value.name end)
        pcall(function() fieldRecordId = value.recordId end)
        pcall(function() fieldDisplayName = value.displayName end)
        appendAnyToken(list, seen, fieldId)
        appendAnyToken(list, seen, fieldName)
        appendAnyToken(list, seen, fieldRecordId)
        appendAnyToken(list, seen, fieldDisplayName)
    end
    local asString = tostring(value)
    if type(asString) == 'string' and asString ~= '' and not asString:find('^table:') then
        appendUnique(list, seen, asString)
    end
end

local function shallowCopy(input)
    local out = {}
    for k, v in pairs(input) do out[k] = v end
    return out
end

-- Keeps config values inside expected numeric bounds.
local function clampNumber(value, minValue, maxValue, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    if minValue ~= nil and n < minValue then n = minValue end
    if maxValue ~= nil and n > maxValue then n = maxValue end
    return n
end

local function resetValidationCounters()
    state.validation = { warnings = 0, errors = 0 }
end

local function logValidation(level, sourcePath, sourceIndex, message)
    local source = tostring(sourcePath or '?')
    local idx = tonumber(sourceIndex)
    local where = idx ~= nil and string.format('%s#%d', source, idx) or source
    print(string.format('[MerchantStock][%s] %s: %s', tostring(level or 'WARN'), where, tostring(message or '')))
    local counters = state.validation
    if type(counters) ~= 'table' then return end
    if tostring(level) == 'ERROR' then
        counters.errors = (tonumber(counters.errors) or 0) + 1
    else
        counters.warnings = (tonumber(counters.warnings) or 0) + 1
    end
end

local function finalizeConfig(config)
    config.itemCountDefault = math.floor(clampNumber(config.itemCountDefault, ITEM_COUNT_MIN, ITEM_COUNT_MAX, DEFAULT_CONFIG.itemCountDefault))
    config.quantityMinDefault = math.floor(clampNumber(config.quantityMinDefault, QUANTITY_MIN, QUANTITY_MAX, DEFAULT_CONFIG.quantityMinDefault))
    config.quantityMaxDefault = math.floor(clampNumber(config.quantityMaxDefault, QUANTITY_MIN, QUANTITY_MAX, DEFAULT_CONFIG.quantityMaxDefault))
    if config.quantityMinDefault > config.quantityMaxDefault then config.quantityMinDefault = config.quantityMaxDefault end
    config.quantityBiasDefault = clampNumber(config.quantityBiasDefault, 0, 1, DEFAULT_CONFIG.quantityBiasDefault)
end

local function resetConfig()
    state.config = shallowCopy(DEFAULT_CONFIG)
    finalizeConfig(state.config)
end

-- If restock.omwscripts is present, we mimic its delay behavior.
local function isRestockCompatEnabled()
    if core == nil or core.contentFiles == nil or type(core.contentFiles.has) ~= 'function' then return false end
    return core.contentFiles.has('restock.omwscripts')
end

local function gameDayNow() return world.getGameTime() / SECONDS_PER_DAY end

local function getRestockDelayDays()
    local configured = nil
    if restockSettings ~= nil and type(restockSettings.get) == 'function' then configured = restockSettings:get(RESTOCK_DELAY_KEY) end
    local delay = tonumber(configured)
    if delay == nil then delay = 0 end
    if delay < 0 then delay = 0 end
    return delay
end

local function addPoolRecordId(pool, recordId)
    if type(pool) ~= 'table' then return end
    local normalizedId = normalize(recordId)
    if normalizedId == '' then return end
    if pool.recordIdSet[normalizedId] then return end
    pool.recordIdSet[normalizedId] = true
    pool.recordIds[#pool.recordIds + 1] = normalizedId
end

local function addEntries(pool, entries)
    if type(pool) ~= 'table' or type(entries) ~= 'table' then return end
    for _, entry in ipairs(entries) do
        if type(entry) == 'string' then
            addPoolRecordId(pool, entry)
        elseif type(entry) == 'table' then
            if type(entry.id) == 'string' then addPoolRecordId(pool, entry.id) end
            if type(entry.recordId) == 'string' then addPoolRecordId(pool, entry.recordId) end
        end
    end
end

-- Flattens scalar/list/object inputs into normalized string tokens.
local function addStringTokens(list, seen, value)
    if value == nil then return end
    local valueType = type(value)
    if valueType == 'string' or valueType == 'number' then
        appendUnique(list, seen, tostring(value))
        return
    end
    if valueType == 'table' then
        if type(value.regions) == 'table' then addStringTokens(list, seen, value.regions) end
        for _, entry in pairs(value) do addStringTokens(list, seen, entry) end
    end
end

-- Region groups with same name are merged across files.
local function addRegionGroup(name, value)
    local groupName = normalize(name)
    if groupName == '' then return end
    if type(state.regionGroups[groupName]) ~= 'table' then state.regionGroups[groupName] = {} end
    local existing = state.regionGroups[groupName]
    local merged, seen = {}, {}
    for token in pairs(existing) do appendUnique(merged, seen, token) end
    addStringTokens(merged, seen, value)
    local updated = {}
    for _, token in ipairs(merged) do updated[token] = true end
    state.regionGroups[groupName] = updated
end

local function loadRegionGroupsBlock(block)
    if type(block) ~= 'table' then return end
    if #block > 0 then
        for _, entry in ipairs(block) do
            if type(entry) == 'table' then
                local name = entry.name or entry.id or entry.group
                if type(name) == 'string' then addRegionGroup(name, entry.regions or entry.values or entry.list or entry.items or {}) end
            end
        end
        return
    end
    for name, value in pairs(block) do addRegionGroup(name, value) end
end

local function loadContainer(pool, container)
    if type(pool) ~= 'table' or type(container) ~= 'table' then return end
    if type(container.ids) == 'table' then
        for _, recordId in ipairs(container.ids) do addPoolRecordId(pool, recordId) end
    end
    -- Name-based matching was removed; keep this warning for existing data files.
    if type(container.names) == 'table' and #container.names > 0 then
        print('[MerchantStock] item-table.names is ignored (ID-only mode). Use item-table.ids.')
    end
    addEntries(pool, container)
end

local function isStringTokenArray(value)
    if type(value) == 'string' then return true end
    if type(value) ~= 'table' then return false end
    for _, entry in pairs(value) do
        if type(entry) ~= 'string' then return false end
    end
    return true
end

local function validateScalarOrRange(fieldName, value, sourcePath, sourceIndex)
    if value == nil then return true end
    local valueType = type(value)
    if valueType == 'number' or valueType == 'string' then
        if tonumber(value) == nil then
            logValidation('ERROR', sourcePath, sourceIndex, string.format('"%s" must be numeric when scalar.', fieldName))
            return false
        end
        return true
    end
    if valueType ~= 'table' then
        logValidation('ERROR', sourcePath, sourceIndex, string.format('"%s" must be a number or { min, max } table.', fieldName))
        return false
    end
    if value.min == nil and value.max == nil then
        logValidation('ERROR', sourcePath, sourceIndex, string.format('"%s" range table must include "min" and/or "max".', fieldName))
        return false
    end
    if value.min ~= nil and tonumber(value.min) == nil then
        logValidation('ERROR', sourcePath, sourceIndex, string.format('"%s.min" must be numeric.', fieldName))
        return false
    end
    if value.max ~= nil and tonumber(value.max) == nil then
        logValidation('ERROR', sourcePath, sourceIndex, string.format('"%s.max" must be numeric.', fieldName))
        return false
    end
    return true
end

local function hasUsableMerchantItemEntries(container)
    if type(container) ~= 'table' then return false end
    if type(container.ids) == 'table' then
        for _, recordId in ipairs(container.ids) do
            if type(recordId) == 'string' and normalize(recordId) ~= '' then return true end
        end
    end
    for _, entry in ipairs(container) do
        if type(entry) == 'string' and normalize(entry) ~= '' then return true end
        if type(entry) == 'table' then
            local id = type(entry.id) == 'string' and normalize(entry.id) or ''
            local recordId = type(entry.recordId) == 'string' and normalize(entry.recordId) or ''
            if id ~= '' or recordId ~= '' then return true end
        end
    end
    return false
end

local function validateRuleData(ruleData, sourcePath, sourceIndex)
    if type(ruleData) ~= 'table' then
        logValidation('ERROR', sourcePath, sourceIndex, 'Rule must be a YAML table/object.')
        return false
    end

    local ok = true
    local classField = ruleData.classes or ruleData.class
    if classField ~= nil and not isStringTokenArray(classField) then
        logValidation('ERROR', sourcePath, sourceIndex, '"classes"/"class" must be a string or list of strings.')
        ok = false
    end

    local regionField = ruleData.regions or ruleData.region
    if regionField ~= nil and not isStringTokenArray(regionField) then
        logValidation('ERROR', sourcePath, sourceIndex, '"regions"/"region" must be a string or list of strings.')
        ok = false
    end

    local excludedField = ruleData['blacklisted-npcs']
    if excludedField ~= nil and not isStringTokenArray(excludedField) then
        logValidation('ERROR', sourcePath, sourceIndex, '"blacklisted-npcs" must be a string or list of strings.')
        ok = false
    end

    local includedField = ruleData['whitelisted-NPCs']
    if includedField ~= nil and not isStringTokenArray(includedField) then
        logValidation('ERROR', sourcePath, sourceIndex, '"whitelisted-NPCs" must be a string or list of strings.')
        ok = false
    end

    if not validateScalarOrRange('item-count', ruleData['item-count'], sourcePath, sourceIndex) then ok = false end
    if not validateScalarOrRange('quantity', ruleData['quantity'], sourcePath, sourceIndex) then ok = false end

    local quantityBias = ruleData['quantity-bias']
    if quantityBias ~= nil and tonumber(quantityBias) == nil then
        logValidation('ERROR', sourcePath, sourceIndex, '"quantity-bias" must be numeric between 0 and 1.')
        ok = false
    elseif quantityBias ~= nil then
        local q = tonumber(quantityBias)
        if q ~= nil and (q < 0 or q > 1) then
            logValidation('WARN', sourcePath, sourceIndex, '"quantity-bias" is outside 0..1 and will be clamped.')
        end
    end

    local merchantItems = ruleData['item-table']
    if type(merchantItems) ~= 'table' then
        logValidation('ERROR', sourcePath, sourceIndex, '"item-table" must be a table/list of IDs.')
        ok = false
    elseif not hasUsableMerchantItemEntries(merchantItems) then
        logValidation('ERROR', sourcePath, sourceIndex, '"item-table" has no valid IDs.')
        ok = false
    end

    return ok
end

-- Build a normalized set plus a flag telling whether it has at least one token.
local function buildMatchSet(value)
    local set = {}
    if type(value) == 'string' then
        local token = normalize(value)
        if token ~= '' then set[token] = true; return set, true end
        return set, false
    end
    if type(value) == 'table' then
        for _, entry in pairs(value) do
            local token = normalize(entry)
            if token ~= '' then set[token] = true end
        end
    end
    return set, next(set) ~= nil
end

local function setToSortedCsv(set)
    local values = {}
    if type(set) == 'table' then for token in pairs(set) do values[#values + 1] = token end end
    table.sort(values)
    return table.concat(values, ',')
end

local function buildRuleIdentity(sourcePath, sourceIndex, ruleData, classSet, regionSet, excludedNpcSet)
    local explicitId = normalize((type(ruleData) == 'table' and (ruleData['rule-id'] or ruleData.ruleId or ruleData.id)) or nil)
    if explicitId ~= '' then return string.format('%s|id=%s', tostring(sourcePath or ''), explicitId) end

    local baseKey = string.format('%s|class=%s|region=%s|exclude=%s',
        tostring(sourcePath or ''),
        setToSortedCsv(classSet),
        setToSortedCsv(regionSet),
        setToSortedCsv(excludedNpcSet)
    )

    if state.ruleKeySeen[baseKey] == nil then
        state.ruleKeySeen[baseKey] = 1
        return baseKey
    end

    local fallbackKey = string.format('%s|slot=%d', baseKey, tonumber(sourceIndex) or (state.ruleKeySeen[baseKey] + 1))
    state.ruleKeySeen[baseKey] = state.ruleKeySeen[baseKey] + 1
    state.ruleKeySeen[fallbackKey] = 1
    print(string.format('[MerchantStock] Duplicate auto rule key, using fallback key "%s". Add "rule-id" to make this stable.', fallbackKey))
    return fallbackKey
end

-- Expand direct regions and region-group references into a single token list.
local function buildRuleRegionTokens(ruleData)
    local merged, seen = {}, {}
    local rawRegions, rawRegionSeen = {}, {}
    addStringTokens(rawRegions, rawRegionSeen, ruleData.regions or ruleData.region)
    for _, token in ipairs(rawRegions) do
        local group = state.regionGroups[normalize(token)]
        if type(group) == 'table' then
            for regionToken in pairs(group) do appendUnique(merged, seen, regionToken) end
        else
            appendUnique(merged, seen, token)
        end
    end

    local groupRefs, groupSeen = {}, {}
    addStringTokens(groupRefs, groupSeen, ruleData['region-group'])
    addStringTokens(groupRefs, groupSeen, ruleData['regions-group'])
    addStringTokens(groupRefs, groupSeen, ruleData['region-groups'])
    addStringTokens(groupRefs, groupSeen, ruleData['regions-groups'])

    for _, ref in ipairs(groupRefs) do
        local group = state.regionGroups[normalize(ref)]
        if type(group) == 'table' then
            for token in pairs(group) do appendUnique(merged, seen, token) end
        else
            print(string.format('[MerchantStock] Unknown region group "%s"', tostring(ref)))
        end
    end

    return merged
end

local function parseRuleGenerationConfig(ruleData)
    local c = state.config
    -- item-count controls how many unique item ids are selected.
    local itemCountMin = c.itemCountDefault
    local itemCountMax = c.itemCountDefault
    local itemCount = ruleData['item-count']
    if type(itemCount) == 'table' then
        local minRaw = itemCount.min
        local maxRaw = itemCount.max
        if minRaw == nil and maxRaw ~= nil then minRaw = maxRaw end
        if maxRaw == nil and minRaw ~= nil then maxRaw = minRaw end
        itemCountMin = clampNumber(minRaw, ITEM_COUNT_MIN, ITEM_COUNT_MAX, c.itemCountDefault)
        itemCountMax = clampNumber(maxRaw, ITEM_COUNT_MIN, ITEM_COUNT_MAX, c.itemCountDefault)
    else
        local fixed = clampNumber(itemCount, ITEM_COUNT_MIN, ITEM_COUNT_MAX, c.itemCountDefault)
        itemCountMin = fixed
        itemCountMax = fixed
    end
    itemCountMin = math.floor(itemCountMin)
    itemCountMax = math.floor(itemCountMax)
    if itemCountMin > itemCountMax then itemCountMin = itemCountMax end

    -- quantity controls stack size for each selected item id.
    local stackMin = c.quantityMinDefault
    local stackMax = c.quantityMaxDefault
    local quantity = ruleData['quantity']
    local hasExplicitQuantity = false
    if type(quantity) == 'number' or type(quantity) == 'string' then
        hasExplicitQuantity = true
        local fixed = clampNumber(quantity, QUANTITY_MIN, QUANTITY_MAX, c.quantityMaxDefault)
        stackMin = math.floor(fixed)
        stackMax = math.floor(fixed)
    elseif type(quantity) == 'table' then
        hasExplicitQuantity = true
        local minRaw = quantity.min
        local maxRaw = quantity.max
        if minRaw == nil and maxRaw ~= nil then minRaw = maxRaw end
        if maxRaw == nil and minRaw ~= nil then maxRaw = minRaw end
        stackMin = clampNumber(minRaw, QUANTITY_MIN, QUANTITY_MAX, c.quantityMinDefault)
        stackMax = clampNumber(maxRaw, QUANTITY_MIN, QUANTITY_MAX, c.quantityMaxDefault)
        stackMin = math.floor(stackMin)
        stackMax = math.floor(stackMax)
    end
    if stackMin > stackMax then stackMin = stackMax end

    local quantityBiasFallback = c.quantityBiasDefault
    if hasExplicitQuantity and ruleData['quantity-bias'] == nil then quantityBiasFallback = 1.0 end
    local quantityBias = clampNumber(ruleData['quantity-bias'], 0, 1, quantityBiasFallback)
    return { itemCountMin = itemCountMin, itemCountMax = itemCountMax, stackMin = stackMin, stackMax = stackMax, quantityBias = quantityBias }
end

local function addStockRule(ruleData, sourcePath, sourceIndex)
    if not validateRuleData(ruleData, sourcePath, sourceIndex) then return end
    local pool = { recordIds = {}, recordIdSet = {} }
    loadContainer(pool, ruleData['item-table'])
    if #pool.recordIds == 0 then
        logValidation('ERROR', sourcePath, sourceIndex, 'Rule has no usable merchant item IDs after parsing.')
        return
    end

    local classSet, hasClassFilter = buildMatchSet(ruleData.classes or ruleData.class)
    local regionSet, hasRegionFilter = buildMatchSet(buildRuleRegionTokens(ruleData))
    local excludedNpcSet, hasExcludedNpcFilter = buildMatchSet(ruleData['blacklisted-npcs'])
    local includedNpcSet, hasIncludedNpcFilter = buildMatchSet(ruleData['whitelisted-NPCs'])
    local generationConfig = parseRuleGenerationConfig(ruleData)
    local seedRaw = nil
    pcall(function() seedRaw = ruleData.seed or ruleData['seed'] end)
    local seedToken = type(seedRaw) == 'string' and tostring(seedRaw) or (seedRaw ~= nil and tostring(seedRaw) or '')
    -- Allow rules with either class filters or explicit NPC whitelist entries.
    if not hasClassFilter and not hasIncludedNpcFilter then
        print(string.format('[MerchantStock] Skipping rule with no class filter or whitelisted-NPCs: %s#%d', tostring(sourcePath), tonumber(sourceIndex) or 0))
        return
    end
    local ruleKey = buildRuleIdentity(sourcePath, sourceIndex, ruleData, classSet, regionSet, excludedNpcSet)

    state.stockRules[#state.stockRules + 1] = {
        ruleKey = ruleKey,
        sourcePath = sourcePath,
        sourceIndex = sourceIndex,
        classSet = classSet,
        hasClassFilter = hasClassFilter,
        regionSet = regionSet,
        hasRegionFilter = hasRegionFilter,
        excludedNpcSet = excludedNpcSet,
        hasExcludedNpcFilter = hasExcludedNpcFilter,
        includedNpcSet = includedNpcSet,
        hasIncludedNpcFilter = hasIncludedNpcFilter,
        seed = seedToken,
        poolRecordIds = pool.recordIds,
        generationConfig = generationConfig,
    }

    print(string.format('[MerchantStock] Rule loaded: %s#%d items=%d classFilter=%s regionFilter=%s excludedNpc=%s includedNpc=%s',
        tostring(sourcePath), tonumber(sourceIndex) or 0, #pool.recordIds, tostring(hasClassFilter), tostring(hasRegionFilter), tostring(hasExcludedNpcFilter), tostring(hasIncludedNpcFilter)))
end

local function loadRulesBlock(block, sourcePath, keyName)
    if type(block) ~= 'table' then
        logValidation('ERROR', sourcePath, nil, string.format('"%s" must contain a table/object or list of rule objects.', tostring(keyName)))
        return
    end
    local sourceTag = string.format('%s:%s', sourcePath, keyName)
    if #block > 0 then
        for index, ruleData in ipairs(block) do addStockRule(ruleData, sourceTag, index) end
        return
    end
    addStockRule(block, sourceTag, 1)
end

local function isYamlPath(path)
    local p = normalize(path:gsub('\\', '/'))
    return p:sub(-5) == '.yaml' or p:sub(-4) == '.yml'
end

local function isRegionGroupYamlPath(path)
    local p = normalize(path:gsub('\\', '/'))
    -- Region-group files are loaded only from the merchantapi namespace.
    return p:sub(1, 28) == 'database/merchantapi/region/'
        or p:sub(1, 29) == 'database/merchantapi/regions/'
end

local function collectYamlPaths()
    local paths = {}
    if type(vfs.pathsWithPrefix) ~= 'function' then return paths end
    for path in vfs.pathsWithPrefix('') do
        if isYamlPath(path) then paths[#paths + 1] = path end
    end
    table.sort(paths)
    return paths
end

local function loadRegionGroupsFromFile(path)
    local ok, data = pcall(markup.loadYaml, path)
    if not ok then
        logValidation('ERROR', path, nil, string.format('Failed to parse YAML: %s', tostring(data)))
        return
    end
    if type(data) ~= 'table' then
        logValidation('WARN', path, nil, 'YAML root is not a table; skipping region-group scan.')
        return
    end
    for key, value in pairs(data) do
        local keyNorm = normalize(key)
        if keyNorm == 'region-groups' then
            loadRegionGroupsBlock(value)
        end
    end
end

local function loadSourceFile(path)
    local ok, data = pcall(markup.loadYaml, path)
    if not ok then
        logValidation('ERROR', path, nil, string.format('Failed to parse YAML: %s', tostring(data)))
        return
    end
    if type(data) ~= 'table' then
        logValidation('WARN', path, nil, 'YAML root is not a table; skipping merchant stock scan.')
        return
    end

    for key, value in pairs(data) do
        if type(key) == 'string' then
            local keyNorm = normalize(key)
            if keyNorm == 'merchant-stock' or keyNorm:match('^merchant%-stock%-') ~= nil then
                loadRulesBlock(value, path, key)
            end
        end
    end
end

local function ensurePoolLoaded()
    if state.poolLoaded then return end
    state.poolLoaded = true
    state.stockRules = {}
    state.regionGroups = {}
    state.ruleKeySeen = {}
    resetValidationCounters()
    resetConfig()

    -- Two-pass load: region groups first, then merchant stock rules.
    local allYamlPaths = collectYamlPaths()
    local regionFilesLoaded = 0
    for _, path in ipairs(allYamlPaths) do
        if isRegionGroupYamlPath(path) then
            loadRegionGroupsFromFile(path)
            regionFilesLoaded = regionFilesLoaded + 1
        end
    end

    local loadedFileCount = 0
    for _, path in ipairs(allYamlPaths) do
        loadSourceFile(path)
        loadedFileCount = loadedFileCount + 1
    end

    local warningCount = tonumber(state.validation.warnings) or 0
    local errorCount = tonumber(state.validation.errors) or 0
    print(string.format('[MerchantStock] Scanned %d YAML files (%d region-group files), loaded %d merchant stock rules. Validation warnings=%d errors=%d.', loadedFileCount, regionFilesLoaded, #state.stockRules, warningCount, errorCount))
end

local function getNpcRecord(actor)
    -- Guard engine calls: some handles may be invalid depending on timing/context.
    local ok, record = pcall(types.NPC.record, actor)
    return ok and record or nil
end

local function extractClassId(npcRecord)
    if npcRecord == nil then return '' end
    local classValue = nil
    pcall(function() classValue = npcRecord.class end)
    if classValue == nil then return '' end
    if type(classValue) == 'string' then return classValue end
    local classId = nil
    pcall(function() classId = classValue.id end)
    if type(classId) == 'string' then return classId end
    local className = nil
    pcall(function() className = classValue.name end)
    if type(className) == 'string' then return className end
    local classAsString = tostring(classValue or '')
    return classAsString ~= '' and classAsString or ''
end

local function getActorKey(actor)
    if actor == nil then return '' end
    local runtimeId = normalize(tostring(actor.id or ''))
    if runtimeId ~= '' then return runtimeId end
    local recordKey = normalize(tostring(actor.recordId or ''))
    if recordKey == '' then
        local npcRecord = getNpcRecord(actor)
        if npcRecord ~= nil and type(npcRecord.id) == 'string' then recordKey = normalize(npcRecord.id) end
    end
    if recordKey == '' then return '' end
    local cellKey = actor.cell and normalize(tostring(actor.cell.id or actor.cell.name or '')) or ''
    return cellKey ~= '' and string.format('%s@%s', recordKey, cellKey) or recordKey
end

local function getStableActorId(actor)
    if actor == nil then return '' end
    local recordKey = normalize(tostring(actor.recordId or ''))
    if recordKey == '' then
        local npcRecord = getNpcRecord(actor)
        if npcRecord ~= nil and type(npcRecord.id) == 'string' then recordKey = normalize(npcRecord.id) end
    end
    if recordKey == '' then return '' end
    local cellKey = actor.cell and normalize(tostring(actor.cell.id or actor.cell.name or '')) or ''
    return cellKey ~= '' and string.format('%s@%s', recordKey, cellKey) or recordKey
end

local function hashStringToUint32(s)
    -- Simple hash for deterministic seeded randomization.
    local h = 2166136261
    for i = 1, #s do
        h = (h * 16777619 + string.byte(s, i)) % 4294967296
    end
    return h
end

local function createRngFromUint32(seed)
    local stateVal = tonumber(seed) or 0
    stateVal = stateVal % 4294967296
    return function()
        stateVal = (stateVal * 1664525 + 1013904223) % 4294967296
        return stateVal
    end
end

local function createRngFromString(seedStr)
    if seedStr == nil then return nil end
    local hashed = hashStringToUint32(tostring(seedStr))
    return createRngFromUint32(hashed)
end

local function chooseStackCount(generationConfig, rng)
    if type(generationConfig) ~= 'table' then generationConfig = {} end
    local c = state.config
    local stackMin = clampNumber(generationConfig.stackMin, QUANTITY_MIN, QUANTITY_MAX, c.quantityMinDefault)
    local stackMax = clampNumber(generationConfig.stackMax, QUANTITY_MIN, QUANTITY_MAX, c.quantityMaxDefault)
    local quantityBias = clampNumber(generationConfig.quantityBias, 0, 1, c.quantityBiasDefault)
    if stackMin > stackMax then stackMin = stackMax end
    if type(rng) ~= 'function' then
        if math.random() < quantityBias then return math.random(math.floor(stackMin), math.floor(stackMax)) end
        return 1
    end
    -- RNG provided: use deterministic PRNG (rng returns uint32)
    local function rand01() return (rng() % 4294967296) / 4294967296 end
    if rand01() < quantityBias then
        local minv = math.floor(stackMin)
        local maxv = math.floor(stackMax)
        local range = maxv - minv + 1
        if range <= 1 then return minv end
        return minv + (rng() % range)
    end
    return 1
end

-- Gather both class id and class name so rules can match either token.
local function getClassValues(actor)
    local values, seen = {}, {}
    local npcRecord = getNpcRecord(actor)
    if npcRecord == nil then return values end

    local classRaw = extractClassId(npcRecord)
    appendUnique(values, seen, classRaw)
    if classRaw ~= '' then
        local ok, classRecord = pcall(types.NPC.classes.record, classRaw)
        if ok and classRecord ~= nil then
            local className = nil
            pcall(function() className = classRecord.name end)
            appendUnique(values, seen, className)
        end
    end
    return values
end

local function getNpcIdValues(actor)
    local values, seen = {}, {}
    if actor == nil then return values end
    -- Include stable ID candidates and display name tokens for
    -- whitelisted-NPCs/blacklisted-npcs matching.
    local recordId = nil
    pcall(function() recordId = actor.recordId end)
    appendUnique(values, seen, recordId)
    local npcRecord = getNpcRecord(actor)
    if npcRecord ~= nil then
        local npcId = nil
        local npcName = nil
        pcall(function() npcId = npcRecord.id end)
        pcall(function() npcName = npcRecord.name end)
        appendUnique(values, seen, npcId)
        appendUnique(values, seen, npcName)
    end
    return values
end

local function isExteriorCell(cell)
    if cell == nil then return false end
    local ok, result = pcall(function() return (type(cell.isExterior) == 'function' and cell:isExterior() == true) or cell.isExterior == true end)
    return ok and result == true
end

local function getCellTraversalKey(cell)
    if cell == nil then return '' end
    local cellId = ''
    local idOk = pcall(function() cellId = normalize(tostring(cell.id or '')) end)
    if idOk and cellId ~= '' then return cellId end
    local gridX, gridY = nil, nil
    local gridOk = pcall(function()
        gridX = tonumber(cell.gridX)
        gridY = tonumber(cell.gridY)
    end)
    if gridOk and gridX ~= nil and gridY ~= nil then
        return string.format('grid:%d:%d', math.floor(gridX), math.floor(gridY))
    end
    local strOk, asString = pcall(function() return tostring(cell) end)
    if strOk and type(asString) == 'string' then return normalize(asString) end
    return ''
end

local function collectTeleportDestinationCells(cell)
    -- Used to walk interior door links until we can resolve an exterior region.
    local destinations = {}
    if cell == nil or type(cell.getAll) ~= 'function' then return destinations end
    local doorsOk, doors = pcall(function() return cell:getAll(types.Door) end)
    if not doorsOk or doors == nil then return destinations end

    local function addDoorDestination(door)
        if door == nil then return end
        local isTeleport = false
        if type(types.Door.isTeleport) == 'function' then
            local teleportOk = false
            teleportOk, isTeleport = pcall(function() return types.Door.isTeleport(door) end)
            if not teleportOk then isTeleport = false end
        else
            pcall(function() isTeleport = door.isTeleport == true or door.teleport == true end)
        end
        if isTeleport ~= true then return end

        local destCell = nil
        if type(types.Door.destCell) == 'function' then
            local destOk = false
            destOk, destCell = pcall(function() return types.Door.destCell(door) end)
            if not destOk then destCell = nil end
        end
        if destCell == nil then pcall(function() destCell = door.destCell end) end
        if destCell ~= nil then destinations[#destinations + 1] = destCell end
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
            for _, door in pairs(doors) do addDoorDestination(door) end
        end)
    end

    return destinations
end

local function findClosestExteriorCellByTraversal(startCell)
    if startCell == nil then return nil end
    if isExteriorCell(startCell) then return startCell end

    -- Breadth-first traversal across teleport destinations.
    local queue = {
        { cell = startCell, depth = 0 },
    }
    local nextIndex = 1
    local visited = {}

    while nextIndex <= #queue do
        local current = queue[nextIndex]
        nextIndex = nextIndex + 1

        local currentCell = current.cell
        local currentDepth = tonumber(current.depth) or 0
        local visitKey = getCellTraversalKey(currentCell)
        if visitKey ~= '' and visited[visitKey] ~= true then
            visited[visitKey] = true
            if isExteriorCell(currentCell) then return currentCell end

            if currentDepth < REGION_TRAVERSAL_MAX_DEPTH then
                local destinations = collectTeleportDestinationCells(currentCell)
                for _, destinationCell in ipairs(destinations) do
                    local destinationKey = getCellTraversalKey(destinationCell)
                    if destinationKey ~= '' and visited[destinationKey] ~= true then
                        queue[#queue + 1] = {
                            cell = destinationCell,
                            depth = currentDepth + 1,
                        }
                    end
                end
            end
        end
    end

    return nil
end

local function getRegionValuesFromCell(cell)
    local values, seen = {}, {}
    if not isExteriorCell(cell) then return values end
    local region, cellName, cellId = nil, nil, nil
    pcall(function() region = cell.region end)
    pcall(function() cellName = cell.name end)
    pcall(function() cellId = cell.id end)
    appendAnyToken(values, seen, region)
    appendAnyToken(values, seen, cellName)
    appendAnyToken(values, seen, cellId)
    appendAnyToken(values, seen, cell)
    return values
end

local function getRegionValues(cell)
    local cacheKey = getCellTraversalKey(cell)
    if cacheKey ~= '' then
        local cached = state.exteriorRegionValuesByCell[cacheKey]
        if type(cached) == 'table' and #cached > 0 then return cached end
    end

    local regionValues = getRegionValuesFromCell(cell)
    if #regionValues <= 0 then
        local exteriorCell = findClosestExteriorCellByTraversal(cell)
        regionValues = getRegionValuesFromCell(exteriorCell)
    end

    -- Cache lookup result so we do not repeat cell traversal every dialogue open.
    if cacheKey ~= '' and #regionValues > 0 then state.exteriorRegionValuesByCell[cacheKey] = regionValues end
    return regionValues
end

local function tokenMatches(value, token)
    if token == '*' then return true end
    if value == '' or token == '' then return false end
    if value == token or value:find(token, 1, true) ~= nil or token:find(value, 1, true) ~= nil then return true end
    local valueLoose = normalizeLoose(value)
    local tokenLoose = normalizeLoose(token)
    if valueLoose ~= '' and tokenLoose ~= '' then
        if valueLoose == tokenLoose or valueLoose:find(tokenLoose, 1, true) ~= nil or tokenLoose:find(valueLoose, 1, true) ~= nil then return true end
    end
    return allTokenWordsPresent(value, token)
end

local function anyTokenMatchesValueSet(valueSet, token)
    if token == '*' then return true end
    for _, value in ipairs(valueSet) do if tokenMatches(value, token) then return true end end
    return false
end

local function ruleMatches(rule, classValues, regionValues, npcIdValues)
    if rule.hasExcludedNpcFilter then
        for _, npcId in ipairs(npcIdValues) do
            if rule.excludedNpcSet[npcId] == true then return false end
        end
    end
    if rule.hasIncludedNpcFilter then
        for _, npcId in ipairs(npcIdValues) do
            if rule.includedNpcSet[npcId] == true then return true end
        end
    end
    if rule.hasClassFilter then
        -- Require exact normalized class ID matches only (no fuzzy/substring matching)
        local classMatch = false
        local classValueSet = {}
        for _, v in ipairs(classValues) do classValueSet[v] = true end
        for token in pairs(rule.classSet) do
            if classValueSet[token] == true then
                classMatch = true
                break
            end
        end
        if not classMatch then return false end
    end
    if rule.hasRegionFilter then
        local regionMatch = false
        for token in pairs(rule.regionSet) do if anyTokenMatchesValueSet(regionValues, token) then regionMatch = true break end end
        if not regionMatch then return false end
    end
    return true
end

local function buildMatchedRulesForActor(actor)
    local classValues = getClassValues(actor)
    local regionValues = getRegionValues(actor ~= nil and actor.cell or nil)
    local npcIdValues = getNpcIdValues(actor)
    local matchedRules = {}
    for _, rule in ipairs(state.stockRules) do if ruleMatches(rule, classValues, regionValues, npcIdValues) then matchedRules[#matchedRules + 1] = rule end end
    return matchedRules, classValues, regionValues
end

-- Build one rule-specific plan; with a seed this stays stable per actor.
local function buildMerchantPlanForRule(rule, stableActorId)
    if type(rule) ~= 'table' or type(rule.poolRecordIds) ~= 'table' or #rule.poolRecordIds == 0 then return nil end
    local allOrder = {}
    for i = 1, #rule.poolRecordIds do allOrder[i] = rule.poolRecordIds[i] end

    local rng = nil
    if type(rule.seed) == 'string' and rule.seed ~= '' then
        local seedStr = rule.seed
        if type(stableActorId) == 'string' and stableActorId ~= '' then seedStr = seedStr .. '|' .. stableActorId end
        rng = createRngFromString(seedStr)
    end

    if type(rng) == 'function' then
        -- deterministic Fisher-Yates using rng()
        for i = #allOrder, 2, -1 do
            local j = (rng() % i) + 1
            allOrder[i], allOrder[j] = allOrder[j], allOrder[i]
        end
    else
        for i = #allOrder, 2, -1 do local j = math.random(i); allOrder[i], allOrder[j] = allOrder[j], allOrder[i] end
    end

    local generationConfig = type(rule.generationConfig) == 'table' and rule.generationConfig or {}
    local c = state.config
    local itemCountMin = math.floor(clampNumber(generationConfig.itemCountMin, ITEM_COUNT_MIN, ITEM_COUNT_MAX, c.itemCountDefault))
    local itemCountMax = math.floor(clampNumber(generationConfig.itemCountMax, ITEM_COUNT_MIN, ITEM_COUNT_MAX, c.itemCountDefault))
    if itemCountMin > itemCountMax then itemCountMin = itemCountMax end
    local requested = itemCountMin
    if itemCountMax > itemCountMin then
        if type(rng) == 'function' then
            local range = itemCountMax - itemCountMin + 1
            requested = itemCountMin + (rng() % range)
        else
            requested = math.random(itemCountMin, itemCountMax)
        end
    end
    local picks = math.min(requested, #allOrder)
    if picks < 1 then return nil end
    local plan = {}
    for i = 1, picks do
        local recordId = allOrder[i]
        local count = chooseStackCount(generationConfig, rng)
        if count < 1 then count = 1 end
        plan[recordId] = (plan[recordId] or 0) + count
    end

    return next(plan) ~= nil and plan or nil
end

local function getRuleKey(rule)
    if type(rule) ~= 'table' then return '' end
    local key = normalize(rule.ruleKey)
    if key ~= '' then return key end
    return normalize(tostring(rule.sourcePath or ''))
end

local function getActorRulePlans(actorKey)
    local rulePlans = state.merchantPlans[actorKey]
    if type(rulePlans) ~= 'table' then
        rulePlans = {}
        state.merchantPlans[actorKey] = rulePlans
        return rulePlans
    end
    return rulePlans
end

local function buildCombinedPlanFromRulePlans(rulePlans, matchedRules)
    if type(matchedRules) ~= 'table' or #matchedRules == 0 then return nil end
    local plan = {}
    for _, rule in ipairs(matchedRules) do
        local subPlan = rulePlans[getRuleKey(rule)]
        if type(subPlan) == 'table' then
            for recordId, count in pairs(subPlan) do plan[recordId] = (plan[recordId] or 0) + count end
        end
    end
    return next(plan) ~= nil and plan or nil
end

local function countOf(inventory, recordId)
    local ok, count = pcall(function() return inventory:countOf(recordId) end)
    if ok and type(count) == 'number' then return count end
    local total = 0
    local okStacks, stacks = pcall(function() return inventory:findAll(recordId) end)
    if okStacks and type(stacks) == 'table' then for _, stack in ipairs(stacks) do total = total + (stack.count or 0) end end
    return total
end

local function getMerchantInventories(actor)
    local allInventories, ownedContainerInventories = {}, {}
    if actor == nil then return allInventories, nil end
    local actorInventory = types.Actor.inventory(actor)
    pcall(function() if not actorInventory:isResolved() then actorInventory:resolve() end end)
    allInventories[#allInventories + 1] = actorInventory

    -- Also include owned containers in-cell (common merchant chest setup).
    if actor.cell ~= nil then
        local okContainers, containers = pcall(function() return actor.cell:getAll(types.Container) end)
        if okContainers and type(containers) == 'table' then
            for _, container in ipairs(containers) do
                local ownerRecordId = nil
                pcall(function() if container.owner ~= nil then ownerRecordId = container.owner.recordId end end)
                if type(ownerRecordId) == 'string' and type(actor.recordId) == 'string' and normalize(ownerRecordId) == normalize(actor.recordId) then
                    local inv = types.Container.inventory(container)
                    pcall(function() if not inv:isResolved() then inv:resolve() end end)
                    allInventories[#allInventories + 1] = inv
                    ownedContainerInventories[#ownedContainerInventories + 1] = inv
                end
            end
        end
    end

    local preferredInventory = actorInventory
    if #ownedContainerInventories > 0 then preferredInventory = ownedContainerInventories[1] end
    return allInventories, preferredInventory
end

local function applyMerchantPlan(actor, plan)
    if actor == nil or type(plan) ~= 'table' then return 0 end
    local inventories, preferredInventory = getMerchantInventories(actor)
    if #inventories == 0 or preferredInventory == nil then return 0 end
    local added = 0
    local actorId = normalize(tostring(actor.recordId or actor.id or ''))
    -- Only add the missing delta; never remove existing stock.
    for recordId, targetCount in pairs(plan) do
        local currentCount = 0
        for _, inv in ipairs(inventories) do currentCount = currentCount + countOf(inv, recordId) end
        if currentCount < targetCount then
            local missing = targetCount - currentCount
            if missing > 0 then
                local okCreate, createErr = pcall(function()
                    world.createObject(recordId, missing):moveInto(preferredInventory)
                end)
                if okCreate then
                    added = added + missing
                else
                    print(string.format(
                        '[MerchantStock] Failed to add recordId="%s" count=%d actor="%s": %s',
                        tostring(recordId),
                        tonumber(missing) or 0,
                        tostring(actorId),
                        tostring(createErr)
                    ))
                end
            end
        end
    end
    return added
end

-- Main actor pipeline: resolve rules -> seed plans -> apply restock.
local function processMerchantActor(actor)
    if actor == nil or types.NPC.objectIsInstance(actor) ~= true then return false end
    ensurePoolLoaded()
    if #state.stockRules == 0 then return false end

    local actorKey = getActorKey(actor)
    if actorKey == '' then return false end

    local matchedRules, classValues, regionValues = buildMatchedRulesForActor(actor)
    if #matchedRules == 0 then
        print(string.format('[MerchantStock] No matching stock rule for actor=%s class="%s" region="%s"', actorKey, table.concat(classValues, ','), table.concat(regionValues, ',')))
        return false
    end

    local rulePlans = getActorRulePlans(actorKey)
    local seededNewRule = false
    local stableActorId = getStableActorId(actor)
    for _, rule in ipairs(matchedRules) do
        local ruleKey = getRuleKey(rule)
        if ruleKey ~= '' and (type(rulePlans[ruleKey]) ~= 'table' or next(rulePlans[ruleKey]) == nil) then
            local subPlan = buildMerchantPlanForRule(rule, stableActorId)
            if type(subPlan) == 'table' and next(subPlan) ~= nil then
                rulePlans[ruleKey] = subPlan
                seededNewRule = true
            end
        end
    end

    local plan = buildCombinedPlanFromRulePlans(rulePlans, matchedRules)
    if type(plan) ~= 'table' or next(plan) == nil then return false end

    local restockCompat = isRestockCompatEnabled()
    if seededNewRule then
        local seeded = applyMerchantPlan(actor, plan) > 0
        if restockCompat then state.lastRefillDays[actorKey] = gameDayNow() end
        return seeded
    end

    if restockCompat then
        -- Respect global restock delay when compatibility mode is active.
        local delayDays = getRestockDelayDays()
        if delayDays > 0 then
            local now = gameDayNow()
            local last = tonumber(state.lastRefillDays[actorKey])
            if last == nil then state.lastRefillDays[actorKey] = now; return false end
            if (now - last) < delayDays then return false end
        end
        local refilled = applyMerchantPlan(actor, plan) > 0
        state.lastRefillDays[actorKey] = gameDayNow()
        return refilled
    end

    return applyMerchantPlan(actor, plan) > 0
end

-- Lifecycle handlers persist plan state between saves/new games.
local function onLoad(data)
    state.poolLoaded = false
    state.exteriorRegionValuesByCell = {}
    data = type(data) == 'table' and data or {}
    state.merchantPlans = type(data.merchantPlans) == 'table' and data.merchantPlans or {}
    state.lastRefillDays = type(data.lastRefillDays) == 'table' and data.lastRefillDays or {}
    resetConfig()
end

local function onNewGame()
    state.poolLoaded = false
    state.merchantPlans = {}
    state.lastRefillDays = {}
    state.exteriorRegionValuesByCell = {}
    resetConfig()
end

local function onSave()
    return {
        merchantPlans = state.merchantPlans,
        lastRefillDays = state.lastRefillDays,
    }
end

local function onGlobalDialogueOpen(data)
    local merchant = nil
    pcall(function() merchant = type(data) == 'table' and (data.merchant or data.arg) or nil end)
    if not merchant or not merchant:isValid() then return end
    processMerchantActor(merchant)
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onNewGame = onNewGame,
        onSave = onSave,
    },
    eventHandlers = {
        [MERCHANT_STOCK_DIALOGUE_OPEN_EVENT] = onGlobalDialogueOpen,
    },
}
