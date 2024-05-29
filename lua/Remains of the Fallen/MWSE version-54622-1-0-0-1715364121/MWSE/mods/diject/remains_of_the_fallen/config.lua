local advTable = include("diject.remains_of_the_fallen.utils.table")
local localStorage = include("diject.remains_of_the_fallen.storage.localStorage")
local log = include("diject.remains_of_the_fallen.utils.log")

local globalStorageName = "RemainsOfTheFallen_Config"
local localStorageName = "localConfig"
local version = 0

local this = {}

---@class rotf.config.globalData
this.default = {
    map = {
        enabled = true,
        ---@class rotf.config.mapSpawn
        spawn = {
            interval = 72, -- game hours
            chance = 25,
            count = 1,
            maxCount = 1,
            playerCount = 5,
            items = {
                change = {
                    enbaled = true,
                    multiplier = 0.5,
                    costMul = 0.02,
                },
            },
            transfer = {
                inPersent = true,
                equipment = 100,
                equipedItems = 100,
                magicItems = 100,
                misc = 0,
                goldPercent = 0,
                books = 0,
            },
            body = {
                chance = 100,
                stats = {
                    health = 200,
                    fatigue = 200,
                    magicka = 200,
                },
                chanceToCorpse = 100,
            },
            creature = {
                chance = 0,
                stats = {
                    health = 200,
                    fatigue = 150,
                    magicka = 200,
                },
                chanceToCorpse = 0,
            },
        },
    },
    text = {
        itemPrefix = "Worn-out",
        nameTemplate = "!name! The !ndeath!th"
    },
}

---@class rotf.config.globalData
this.data = advTable.deepcopy(this.default)

---@class rotf.config.globalData
this.global = advTable.deepcopy(this.default)

do
    local data = mwse.loadConfig(globalStorageName)
    if data then
        this.data = data
        advTable.addMissing(this.data, this.default)
        this.global = advTable.deepcopy(this.data)
    else
        mwse.saveConfig(globalStorageName, this.data)
    end
end

---@class rotf.config.localData
this.localDefault = {
    version = version,
    count = 0, -- number of deaths
    id = nil,
    config = {},
    spawnedPlayers = {},
}

---@class rotf.config.localData
this.localConfig = advTable.deepcopy(this.localDefault)


function this.initLocalData()
    if localStorage.isReady() then
        advTable.applyChanges(this.data, this.global)
        local storageData = localStorage.data[localStorageName]
        if not storageData then
            this.localConfig = advTable.deepcopy(this.localDefault)
            local id = tostring(os.time())
            this.localConfig.id = id:sub(3, id:len())
            localStorage.data[localStorageName] = this.localConfig
        else
            this.localConfig = storageData
            advTable.addMissing(this.localConfig, this.localDefault)
            advTable.applyChanges(this.data, this.localConfig.config)
        end
        return true
    end
    return false
end

function this.resetLocalToDefault()
    if not localStorage.isReady() then return end
    advTable.applyChanges(this.localConfig, this.localDefault)
end

---@param path string
---@return any, boolean return return value and is the value from the local config
function this.getValueByPath(path)
    local value = advTable.getValueByPath(this.localConfig.config, path)
    if value ~= nil then
        return value, true
    end
    return advTable.getValueByPath(this.data, path), false
end

---@param path string
---@param newValue any
---@return boolean success
function this.setValueByPath(path, newValue)
    if tes3.player then
        advTable.setValueByPath(this.localConfig.config, path, newValue)
        log("Local config value", path, newValue)
    else
        advTable.setValueByPath(this.global, path, newValue)
        log("Global config value", path, newValue)
    end
    return advTable.setValueByPath(this.data, path, newValue)
end

---@param path string
---@param newValue any
---@return boolean success
function this.setGlobalValueByPath(path, newValue)
    advTable.setValueByPath(this.global, path, newValue)
    log("Global config value", path, newValue)
    return advTable.setValueByPath(this.data, path, newValue)
end

function this.resetValueToGlobal(path)
    local globalVal = advTable.getValueByPath(this.global, path)
    if tes3.player then
        advTable.setValueByPath(this.localConfig.config, path, nil)
        log("Local config value", path, "nil")
    end
    log("Global config value", path, globalVal)
    advTable.setValueByPath(this.data, path, globalVal)
    return globalVal
end

function this.save()
    mwse.saveConfig(globalStorageName, this.global)
end

function this.updateVersionInPlayerStorage()
    this.localConfig.version = version
end

return this