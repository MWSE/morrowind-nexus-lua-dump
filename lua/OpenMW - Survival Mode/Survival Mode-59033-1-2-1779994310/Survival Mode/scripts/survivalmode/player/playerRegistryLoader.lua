local M = {}

function M.create(deps)
    local markup = assert(deps.markup)
    local vfs = assert(deps.vfs)
    local playerConfig = assert(deps.playerConfig)
    local state = assert(deps.state)
    local normalizePath = assert(deps.normalizePath)
    local normalizeKey = assert(deps.normalizeKey)

    local function addIdToSet(idSet, value)
        if type(value) ~= 'string' then
            return 0
        end

        local normalizedValue = normalizeKey(value)
        if normalizedValue == '' then
            return 0
        end

        if idSet[normalizedValue] == true then
            return 0
        end

        idSet[normalizedValue] = true
        return 1
    end

    local function addIdsFromEntries(idSet, entries)
        if type(entries) ~= 'table' then
            return 0
        end

        local added = 0
        for _, entry in ipairs(entries) do
            if type(entry) == 'string' then
                added = added + addIdToSet(idSet, entry)
            elseif type(entry) == 'table' then
                added = added + addIdToSet(idSet, entry.id)
                if type(entry.ids) == 'table' then
                    added = added + addIdsFromEntries(idSet, entry.ids)
                end
            end
        end

        return added
    end

    local function loadFoodYamlFile(filePath)
        if type(markup.loadYaml) ~= 'function' then
            print('[SurvivalMode] openmw.markup.loadYaml is unavailable.')
            return false
        end

        local ok, data = pcall(markup.loadYaml, filePath)
        if not ok then
            print(string.format('[SurvivalMode] Failed to parse food yaml "%s": %s', filePath, tostring(data)))
            return false
        end

        if type(data) ~= 'table' then
            print(string.format('[SurvivalMode] Food yaml must be a table: %s', filePath))
            return false
        end

        local hasSupportedField = false
        local addedIds = 0

        if type(data.food) == 'table' then
            if type(data.food.ids) == 'table' then
                hasSupportedField = true
                addedIds = addedIds + addIdsFromEntries(state.foodIds, data.food.ids)
            end
            if #data.food > 0 then
                hasSupportedField = true
                addedIds = addedIds + addIdsFromEntries(state.foodIds, data.food)
            end
        end

        if not hasSupportedField then
            return false
        end

        if addedIds == 0 then
            print(string.format('[SurvivalMode] Food yaml has no valid IDs: %s', filePath))
        end

        return true
    end

    local function loadThirstYamlFile(filePath)
        if type(markup.loadYaml) ~= 'function' then
            print('[SurvivalMode] openmw.markup.loadYaml is unavailable.')
            return false
        end

        local ok, data = pcall(markup.loadYaml, filePath)
        if not ok then
            print(string.format('[SurvivalMode] Failed to parse thirst yaml "%s": %s', filePath, tostring(data)))
            return false
        end

        if type(data) ~= 'table' then
            print(string.format('[SurvivalMode] Thirst yaml must be a table: %s', filePath))
            return false
        end

        local hasSupportedField = false
        local addedIds = 0

        local function loadDrinkContainer(container)
            if type(container) ~= 'table' then
                return false
            end

            local loaded = false
            if type(container.ids) == 'table' then
                loaded = true
                addedIds = addedIds + addIdsFromEntries(state.thirstIds, container.ids)
            end
            if #container > 0 then
                loaded = true
                addedIds = addedIds + addIdsFromEntries(state.thirstIds, container)
            end

            return loaded
        end

        if loadDrinkContainer(data.drinks) then
            hasSupportedField = true
        end

        if loadDrinkContainer(data.thirst) then
            hasSupportedField = true
        end

        if not hasSupportedField then
            return false
        end

        if addedIds == 0 then
            print(string.format('[SurvivalMode] Drink yaml has no valid IDs: %s', filePath))
        end

        return true
    end

    local function isYamlPath(filePath)
        local normalizedPath = normalizePath(filePath)
        return normalizedPath:match('%.yaml$') ~= nil or normalizedPath:match('%.yml$') ~= nil
    end

    local function loadFoodList()
        if state.foodListLoaded then
            return
        end

        state.foodListLoaded = true
        state.foodIds = {}

        if type(vfs.pathsWithPrefix) ~= 'function' then
            print('[SurvivalMode] openmw.vfs.pathsWithPrefix is unavailable.')
            return
        end

        local loadedFiles = 0
        local foodScanPrefix = playerConfig.scanPrefixes.food or 'database'
        for filePath in vfs.pathsWithPrefix(foodScanPrefix) do
            if isYamlPath(filePath) and loadFoodYamlFile(filePath) then
                loadedFiles = loadedFiles + 1
            end
        end

        if loadedFiles == 0 then
            print('[SurvivalMode] No food ID sources found under "' .. foodScanPrefix .. '"')
        end
    end

    local function loadThirstList()
        if state.thirstListLoaded then
            return
        end

        state.thirstListLoaded = true
        state.thirstIds = {}

        if type(vfs.pathsWithPrefix) ~= 'function' then
            print('[SurvivalMode] openmw.vfs.pathsWithPrefix is unavailable.')
            return
        end

        local loadedFiles = 0
        local thirstScanPrefix = playerConfig.scanPrefixes.thirst or 'database'
        for filePath in vfs.pathsWithPrefix(thirstScanPrefix) do
            if isYamlPath(filePath) and loadThirstYamlFile(filePath) then
                loadedFiles = loadedFiles + 1
            end
        end

        if loadedFiles == 0 then
            print('[SurvivalMode] No drink ID sources found under "' .. thirstScanPrefix .. '"')
        end
    end

    return {
        loadFoodList = loadFoodList,
        loadThirstList = loadThirstList,
    }
end

function M.createConsumption(deps)
    local types = assert(deps.types)
    local state = assert(deps.state)
    local normalizeKey = assert(deps.normalizeKey)
    local loadFoodList = assert(deps.loadFoodList)
    local loadThirstList = assert(deps.loadThirstList)
    local hungerRestorePerWeight = assert(deps.hungerRestorePerWeight)
    local hungerRestoreSoftCap = assert(deps.hungerRestoreSoftCap)
    local hungerRestoreOverCapEfficiency = assert(deps.hungerRestoreOverCapEfficiency)

    local function getListedFoodRecord(item)
        if types.Potion.objectIsInstance(item) then
            return types.Potion.record(item)
        end
        if types.Ingredient.objectIsInstance(item) then
            return types.Ingredient.record(item)
        end
        return nil
    end

    local function isListedFoodItem(item)
        loadFoodList()

        local record = getListedFoodRecord(item)
        if record == nil then
            return false
        end

        local recordId = normalizeKey(record.id)
        return state.foodIds[recordId] == true
    end

    local function getFoodHungerReduction(item)
        if not isListedFoodItem(item) then
            return 0
        end

        local record = getListedFoodRecord(item)
        if record == nil or type(record.weight) ~= 'number' then
            return 0
        end

        local baseReduction = math.max(0, record.weight * hungerRestorePerWeight)
        if baseReduction <= hungerRestoreSoftCap then
            return baseReduction
        end

        local extra = baseReduction - hungerRestoreSoftCap
        return hungerRestoreSoftCap + (extra * hungerRestoreOverCapEfficiency)
    end

    local function isListedThirstDrink(item)
        loadThirstList()

        local record = nil
        if types.Potion.objectIsInstance(item) then
            record = types.Potion.record(item)
        elseif types.Ingredient.objectIsInstance(item) then
            record = types.Ingredient.record(item)
        else
            return false
        end

        if record == nil then
            return false
        end

        local recordId = normalizeKey(record.id)
        return state.thirstIds[recordId] == true
    end

    local function getThirstDrinkRestoreAmount(item)
        if not isListedThirstDrink(item) then
            return 0
        end

        local record = nil
        if types.Potion.objectIsInstance(item) then
            record = types.Potion.record(item)
        elseif types.Ingredient.objectIsInstance(item) then
            record = types.Ingredient.record(item)
        end

        local weight = 0
        if record ~= nil and type(record.weight) == 'number' then
            weight = record.weight
        end

        if weight >= 3.1 then
            return 400
        end

        if weight >= 1.0 then
            return 250
        end

        return 150
    end

    return {
        getFoodHungerReduction = getFoodHungerReduction,
        getThirstDrinkRestoreAmount = getThirstDrinkRestoreAmount,
    }
end

return M
