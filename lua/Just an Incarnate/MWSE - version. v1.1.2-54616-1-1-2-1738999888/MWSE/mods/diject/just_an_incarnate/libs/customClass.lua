local log = include("diject.just_an_incarnate.utils.log")
local globalStorage = include("diject.just_an_incarnate.storage.globalStorage")

local storageLable = "classes"

local this = {}

this.customClassId = "jai_dummyclass_0"

this.storage = globalStorage.data[storageLable]
if this.storage == nil then
    this.storage = {}
    globalStorage.data[storageLable] = this.storage
end

---@return boolean
function this.isGameCustomClass()
    if tes3.player.object.class.id == "NEWCLASSID_CHARGEN" then
        return true
    end
    return false
end

---@return integer
function this.storageSize()
    local count = 0
    for name, data in pairs(this.storage) do
        count = count + 1
    end
    return count
end

---@return tes3class|nil
function this.getCustomClassRecord()
    return tes3.findClass(this.customClassId)
end

---@param class tes3class
---@return table
function this.serializeClass(class)
    local out = {attributes = {}, skills = {}}
    for i, val in pairs(class.attributes) do
        out.attributes[i] = val
    end
    for i, val in pairs(class.skills) do
        out.skills[i] = val
    end
    out.name = class.name
    out.description = class.description
    out.specialization = class.specialization
    out.image = class.image
    return out
end

---@param class tes3class
function this.deserializeClass(class, classData)
    for i, val in pairs(classData.attributes) do
        class.attributes[i] = val
    end
    for i, val in pairs(classData.skills) do
        class.skills[i] = val
    end
    class.name = classData.name
    class.description = classData.description
    class.specialization = classData.specialization
    class.image = classData.image
end

---@param class tes3class
function this.saveClassData(class)
    this.storage[class.name] = this.serializeClass(class)
    globalStorage.save()
end

---@return boolean
function this.deserializeClassToPlayerCustom(classData)
    ---@type tes3class
    local class = tes3.findClass(this.customClassId)

    if class then
        class.playable = true
        log("custom class:", classData)
        this.deserializeClass(class, classData)
        class.modified = true
        return true
    end
    return false
end

---@return boolean
function this.loadRandomCustomClass()
    local classDataArr = {}
    for name, data in pairs(this.storage) do
        table.insert(classDataArr, data)
    end
    if #classDataArr == 0 then return false end
    if this.deserializeClassToPlayerCustom(classDataArr[math.random(#classDataArr)]) then
        return true
    end
    return false
end

---Creates random class data and loads it to the custom class if possible
---@return boolean
function this.createAndLoadCustomClass()
    local attributes = {}
    for i = 0, 7 do
        table.insert(attributes, i)
    end
    local skills = {}
    for i = 0, 26 do
        table.insert(skills, i)
    end
    local classData = {attributes = {}, skills = {}, name = "Adventurer", description = "", image = "textures\\levelup\\Warrior.bmp"}
    classData.specialization = math.random(0, 2)
    for i = 0, 1 do
        local id = math.random(1, #attributes)
        table.insert(classData.attributes, attributes[id])
        table.remove(attributes, id)
    end
    for i = 0, 9 do
        local id = math.random(1, #skills)
        table.insert(classData.skills, skills[id])
        table.remove(skills, id)
    end
    return this.deserializeClassToPlayerCustom(classData)
end

return this