local saveRestore = include("Morrowind_World_Randomizer.saveRestore")
local file = include("Morrowind_World_Randomizer.file")
local log = include("Morrowind_World_Randomizer.log")

local extension = ".mwrdata"

---@class mwrStorage
local this = {}

this.version = 6

this.data = {items = {}, actors = {}, enchantments = {}, version = this.version, playerId = nil}
this.initial = {items = {}, actors = {}, enchantments = {}, version = this.version}

function this.resetStorageData()
    this.data.items = {}
    this.data.actors = {}
    this.data.enchantments = {}
end

---@param fileName string
function this.saveToFile(fileName, playerId)
    log("Saving data to %s", fileName)
    local itemsJson = json.encode(this.data.items, nil)
    local actorsJson = json.encode(this.data.actors, nil)
    local enchantmentsJson = json.encode(this.data.enchantments, nil)
    local fileTable = {itemsJson = itemsJson, actorsJson = actorsJson, enchantmentsJson = enchantmentsJson, version = this.version, playerId = playerId}
    file.save.toSaveDirectory(fileName..extension, fileTable)
end

---@param fileName string
---@return boolean
function this.loadFromFile(fileName)
    log("Loading data from %s", fileName)
    local fileTable = file.load.fromSaveDirectory(fileName..extension)
    if fileTable then
        this.data.version = fileTable.version
        this.data.playerId = fileTable.playerId
        local items = json.decode(fileTable.itemsJson)
        local actors = json.decode(fileTable.actorsJson)
        local enchantments = json.decode(fileTable.enchantmentsJson)
        if items then this.data.items = items else this.data.items = {} end
        if actors then this.data.actors = actors else this.data.actors = {} end
        if enchantments then this.data.enchantments = enchantments else this.data.enchantments = {} end
        return true
    else
        this.data.items = {}
        this.data.actors = {}
        this.data.enchantments = {}
        return false
    end
end

---@param enchantment tes3enchantment
---@param toInitial boolean|nil
function this.saveEnchantment(enchantment, toInitial)
    if not enchantment then return end
    local data = saveRestore.serializeItemEnchantment(enchantment)
    if not toInitial then
        this.data.enchantments[enchantment.id] = data
    end
    if toInitial or not this.initial.enchantments[enchantment.id] then
        this.initial.enchantments[enchantment.id] = data
    end
end

---@param id string
---@param restoreToInitial boolean|nil
---@return boolean
function this.restoreEnchantment(id, restoreToInitial)
    local data
    if restoreToInitial then
        data = this.initial.enchantments[id]
    else
        data = this.data.enchantments[id]
    end
    if data then
        local object = tes3.getObject(id)
        if object then
            if not this.initial.enchantments[id] then
                this.initial.enchantments[id] = saveRestore.serializeItemEnchantment(object)
            end
            saveRestore.restoreEnchantment(object, data)
            return true
        else
            object = saveRestore.createEnchantment(id, data)
        end
    end
    return false
end

---@param originalId string|nil
---@param toInitial boolean|nil
function this.saveItem(object, originalId, toInitial)
    if not object then return end
    if not toInitial then
        this.data.items[object.id] = saveRestore.serializeItemBaseObject(object, originalId)
    elseif not this.initial.items[object.id] then
        this.initial.items[object.id] = saveRestore.serializeItemBaseObject(object, originalId)
    end
    if object.enchantment then
        this.saveEnchantment(object.enchantment)
    end
end

---@param id string
---@param restoreToInitial boolean|nil
---@return boolean
function this.restoreItem(id, restoreToInitial)
    local data
    if restoreToInitial then
        data = this.initial.items[id]
    else
        data = this.data.items[id]
    end
    if data then
        local origId = data.originalId or data.id
        local object = tes3.getObject(origId)
        if object then
            if data.originalId and data.originalId ~= data.id then
                local newObj = tes3.getObject(data.id)
                if not newObj then
                    object = object:createCopy{id = data.id, sourceless = true}
                else
                    object = newObj
                end
            elseif not this.initial.items[origId] then
                this.initial.items[origId] = saveRestore.serializeItemBaseObject(object)
            end
            saveRestore.restoreItemBaseObject(object, data, false)
            return true
        end
    end
    return false
end

---@param id string
---@param data table
---@param isInitial boolean|nil
function this.addItemData(id, data, isInitial)
    if isInitial then
        if data.enchantment and data.enchantment.castType then
            this.initial.enchantments[data.enchantment.id] = data.enchantment
            data.enchantment = {id = data.enchantment.id}
        end
        this.initial.items[id] = data
    else
        if data.enchantment and data.enchantment.castType then
            this.data.enchantments[data.enchantment.id] = data.enchantment
            data.enchantment = {id = data.enchantment.id}
        end
        this.data.items[id] = data
    end
end

---@param id string
---@param isInitial boolean|nil
function this.getItemData(id, isInitial)
    if isInitial then
        return this.initial.items[id]
    else
        return this.data.items[id]
    end
end

---@param id string
function this.deleteItemData(id)
    this.data.items[id] = nil
end

---@param restoreToInitial boolean|nil
function this.restoreAllEnchantments(restoreToInitial)
    local arr = restoreToInitial and this.initial.enchantments or this.data.enchantments
    for id, data in pairs(arr) do
        this.restoreEnchantment(id, restoreToInitial)
    end
end

---@param restoreToInitial boolean|nil
---@param deleteCreated boolean|nil
function this.restoreAllItems(restoreToInitial, deleteCreated)
    local arr = restoreToInitial and this.initial.items or this.data.items
    for id, data in pairs(arr) do
        if deleteCreated and data.created then
            local object = tes3.getObject(id)
            if object then
                tes3.deleteObject(object)
            end
        else
            this.restoreItem(id, restoreToInitial)
        end
    end
end

function this.deleteCreatedItems()
    for id, data in pairs(this.data.items) do
        if data.originalId and data.id ~= data.originalId then
            this.data.items[id] = nil
        end
    end
end

function this.deleteUncreatedItems()
    for id, data in pairs(this.data.items) do
        if not data.originalId or data.id == data.originalId then
            this.data.items[id] = nil
        end
    end
end

---@param object tes3npc|tes3creature
---@param toInitial boolean|nil
function this.saveActor(object, toInitial)
    if not object then return end
    local id = object.id
    if not toInitial then
        this.data.actors[id] = saveRestore.serializeActorBaseObject(object)
    elseif not this.initial.actors[id] then
        this.initial.actors[id] = saveRestore.serializeActorBaseObject(object)
    end
end

---@param object string|tes3npc|tes3creature|any
---@param restoreToInitial boolean|nil
---@return boolean
function this.restoreActor(object, restoreToInitial)
    if not object then return false end
    local id = nil
    local obj = nil
    if type(object) == "string" then
        id = object
        obj = tes3.getObject(id)
    else
        id = object.id
        obj = object
    end
    if not restoreToInitial and not this.initial.actors[id] then
        this.saveActor(obj, true)
    end
    local arr = restoreToInitial and this.initial.actors or this.data.actors
    local data = arr[id]
    if data then
        saveRestore.restoreActorBaseObject(obj, data)
        return true
    end
    return false
end

---@param id string
---@param data table
---@param isInitial boolean|nil
function this.addActorData(id, data, isInitial)
    if isInitial then
        this.initial.actors[id] = data
    else
        this.data.actors[id] = data
    end
end

function this.restoreAllActors(restoreToInitial)
    local arr = restoreToInitial and this.initial.actors or this.data.actors
    for id, data in pairs(arr) do
        local object = tes3.getObject(id)
        this.restoreActor(object, restoreToInitial)
    end
end

---@param object tes3npc|tes3creature
function this.saveOrRestoreInitialActor(object)
    if not object then return end
    if this.initial.actors[object.id] then
        this.restoreActor(object, true)
    else
        this.saveActor(object, true)
    end
end

return this