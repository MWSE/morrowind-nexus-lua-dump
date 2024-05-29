local advTable = include("diject.just_an_incarnate.utils.table")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")
local log = include("diject.just_an_incarnate.utils.log")

local globalStorageName = "JustAnIncarnateByDiject_Config"
local localStorageName = "localConfig"
local version = 0

local this = {}

this.firstInit = false

---@class config.globalData
this.default = {
    revive = {
        enabled = true,
        delay = 5,
        safeTime = 5,
        removeEffects = true,
        removeDiseases = false,
        interior = {
            divineMarker = false,
            templeMarker = false,
            prisonMarker = false,
            exteriorDoorMarker = false,
            interiorDoorMarker = false,
            exitFromInterior = true,
            recall = false,
        },
        exterior = {
            divineMarker = true,
            templeMarker = true,
            prisonMarker = true,
            exteriorDoorMarker = false,
            exitFromInterior = false,
            recall = true,
        },
    },
    misc = {
        bounty = {
            reset = true,
            removeStolen = true,
        },
        rechargePower = true,
        sendDeathEvent = true,
        sendLoadedEvent = false,
        resetActorsToDefault = true,
    },
    change = {
        race = false,
        bodyParts = false,
        class = {
            enbled = false,
            chanceToCustom = 50,
            chanceToPlayerCustom = 50,
        },
        sign = false,
        sex = false,
    },
    decrease = {
        level = {
            count = 1,
            interval = 25,
        },
        skill = {
            count = 1,
            interval = 5,
            levelUp = {
                progress = true,
                attributes = true,
            },
        },
        spell = {
            count = 1,
            interval = 10,
            random = true,
        },
        combine = true,
    },
    spawn = {
        addSummonSpell = true,
        transfer = {
            inPersent = true,
            equipment = 20,
            equipedItems = 20,
            magicItems = 20,
            misc = 20,
            goldPercent = 20,
            books = 0,
            replace = {
                enabled = true,
                regionSize = 75,
            }
        },
        body = {
            chance = 80,
            stats = {
                health = 200,
                fatigue = 200,
                magicka = 200,
            },
            chanceToCorpse = 75,
        },
        creature = {
            chance = 20,
            stats = {
                health = 200,
                fatigue = 150,
                magicka = 200,
            },
            chanceToCorpse = 0,
        },
    },
    text = {
        death = "You have met your destiny and no longer carry the burden of prophecy. You were a false incarnate.",
        summonSpellDescription = "Teleports all false incarnates from the current location to you.",
        statDecreaseMessage = "You feel you were able to accomplish more in another life, but have lost everything."
    },
}

---@class config.globalData
this.data = advTable.deepcopy(this.default)

---@class config.globalData
this.global = advTable.deepcopy(this.default)

do
    local data = mwse.loadConfig(globalStorageName)
    if data then
        this.data = data
        advTable.addMissing(this.data, this.default)
        this.global = advTable.deepcopy(this.data)
    else
        this.firstInit = true
        mwse.saveConfig(globalStorageName, this.data)
    end
end

---@class config.localData
this.localDefault = {
    version = version,
    count = 0, -- number of deaths
    id = nil,
    config = {},
}

---@class config.localData
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

function this.applyDefault()
    local data = advTable.deepcopy(this.default)
    data.revive.enabled = nil
    if tes3.player then
        advTable.addMissing(this.localConfig.config, data)
        advTable.applyChanges(this.localConfig.config, data)
        advTable.applyChanges(this.data, this.localConfig.config)
        log("Local config to default")
    else
        advTable.applyChanges(this.global, data)
        advTable.applyChanges(this.data, data)
        log("Global config to default")
    end
end

return this