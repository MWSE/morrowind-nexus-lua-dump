DataManager = {}

DataManager.configPrefix = "custom/__config_"
DataManager.dataPrefix = "custom/__data_"

local function getConfigPath(scriptName)
    return DataManager.configPrefix .. scriptName .. ".json"
end

local function getDataPath(scriptName)
    return DataManager.dataPrefix .. scriptName .. ".json"
end

if jsonConfig then
    function DataManager.saveConfiguration(scriptName, config, keyOrder)
    end

    function DataManager.loadConfiguration(scriptName, defaultConfig, keyOrder)
        return jsonConfig.Load(scriptName, defaultConfig, keyOrder)
    end
else
    function DataManager.saveConfiguration(scriptName, config, keyOrder)
        local filePath = getConfigPath(scriptName)
        return jsonInterface.save(filePath, config, keyOrder)
    end

    function DataManager.loadConfiguration(scriptName, defaultConfig, keyOrder)
        local filePath = getConfigPath(scriptName)
        local config = jsonInterface.load(filePath)
        if config == nil then
            config = defaultConfig
        end
        DataManager.saveConfiguration(scriptName, config, keyOrder)
        return config
    end

    jsonConfig = {}
    function jsonConfig.Load(name, default, keyOrderArray)
        return DataManager.loadConfiguration(name, default, keyOrderArray)
    end
end

if storage then
    -- storage data gets saved automatically
    function DataManager.saveData(scriptName, data, keyOrder)end

    function DataManager.loadData(scriptName, defaultData, keyOrder)
        storage.Load(scriptName, defaultData)
    end
else
    function DataManager.saveData(scriptName, data, keyOrder)
        local filePath = getDataPath(scriptName)
        return jsonInterface.save(filePath, data, keyOrder)
    end

    function DataManager.loadData(scriptName, defaultData, keyOrder)
        local filePath = getDataPath(scriptName)
        local data = jsonInterface.load(filePath)
        if data == nil then
            data = defaultData
        end
        DataManager.saveData(scriptName, data, keyOrder)
        return data
    end

    storage = {
        data = {}
    }

    function storage.Save(key)
        DataManager.saveData(key, storage.data[key])
    end

    function storage.SaveAll()
        for key in pairs(storage.data) do
            storage.Save(key)
        end
    end

    function storage.SaveAllAsync()
        return storage.SaveAll() -- no async in 0.7
    end

    function storage.Load(key, default)
        if not storage.data[key] then
            local eventStatus = customEventHooks.triggerValidators('OnStorageLoad', {key})
            if eventStatus.validDefaultHandler then
                storage.data[key] = DataManager.loadData(key, default)
            end
            customEventHooks.triggerHandlers('OnStorageLoad', eventStatus, {key})
        end
        return storage.data[key]
    end

    customEventHooks.registerHandler("OnServerExit", function(eventStatus)
        if not eventStatus.validDefaultHandler then return end
        storage.SaveAll()
    end)
end

return DataManager
