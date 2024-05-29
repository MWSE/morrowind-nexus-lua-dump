require("diject.remains_of_the_fallen.libs.types")
local log = include("diject.remains_of_the_fallen.utils.log")
local globalStorage = include("diject.remains_of_the_fallen.storage.globalStorage")
local objectSerDes = include("diject.remains_of_the_fallen.libs.objectSerDes")
local fileSys = include("diject.remains_of_the_fallen.utils.fileSys")
local stringLib = include("diject.remains_of_the_fallen.utils.string")
local config = include("diject.remains_of_the_fallen.config")

local playerDataLabel = "playerData"
local deathMapDir = tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\remains_of_the_fallen\\map\\"

local allowedItemTypes = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.ammunition] = true,
}

local this = {}

---@type table<string, jai.storage.playerData> player id as the id
this.playerData = globalStorage.data[playerDataLabel]
if this.playerData == nil then
    this.playerData = {}
    globalStorage.data[playerDataLabel] = this.playerData
end


function this.save()
    globalStorage.save()
end

local function getUniqueId(playerId, id)
    local idlen = id:len()
    if idlen > 31 then
        id = id:sub(31-idlen + 1, idlen)
    end
    for i = 1, 31 - id:len() do
        id = "0"..id
    end
    return playerId..id:sub(#playerId + 1, id:len())
end

---@param race tes3race
---@return jai.storage.race
function this.getRaceData(race)
    local raceBodyPart = {"ankle", "chest", "clavicle", "foot", "forearm", "groin", "hands",
        "knee", "neck", "tail", "upperArm", "upperLeg", "vampireHead", "wrist",
    }
    ---@type jai.storage.race
    local raceData = {female = {}, male = {}, isBeast = race.isBeast}
    for _, bodyPartName in pairs(raceBodyPart) do
        raceData.female[bodyPartName] = race.femaleBody[bodyPartName] and race.femaleBody[bodyPartName].id or nil
        raceData.male[bodyPartName] = race.maleBody[bodyPartName] and race.maleBody[bodyPartName].id or nil
    end
    return raceData
end


---@param playerId string
---@param actor tes3reference
---@param deathCount integer
---@param position tes3vector3
---@param orientation tes3vector3
---@param cell tes3cell
---@return rotf.storage.deathMapRecord
local function serializeActor(playerId, actor, cell, position, orientation, deathCount)
    local mobile = actor.mobile
    local object = actor.object
    local baseObject = actor.baseObject
    ---@type rotf.storage.deathMapRecord
    local out = {
        playerId = playerId,
        recordId = os.time(),
        position = {x = position.x, y = position.y, z = position.z, cell = {name = cell.id, x = cell.gridX, y = cell.gridY}},
        rotation = {x = orientation.x, y = orientation.y, z = orientation.z},
        name = object.name,
        race = object.race.id,
        raceData = this.getRaceData(object.race),
        isBeast = object.race.isBeast,
        isFemale = object.female,
        head = baseObject.head.id,
        hair = baseObject.hair.id,
        deathCount = deathCount,
        stats = {health = mobile.health.base, fatigue = mobile.fatigue.base, magicka = mobile.magicka.base}, ---@diagnostic disable-line: need-check-nil
        customObjects = {},
        attributes = {},
        equipment = {},
        inventory = {},
        skills = {},
        spells = {},
    }

    -- inventory & equipment
    local boundItems = {}
    for _, effect in pairs(mobile.activeMagicEffectList) do ---@diagnostic disable-line: need-check-nil
        if effect.effectInstance.createdData and effect.effectInstance.createdData.object then
            boundItems[effect.effectInstance.createdData.object.id] = true
        end
    end

    local function writeCustomObjectData(obj)
        local objectData = objectSerDes.serializeObject(obj)
        if not objectData then return end
        objectData.id = getUniqueId(playerId, objectData.id) -- to make the id unique
        if objectData.enchantment then objectData.enchantment.id = playerId..objectData.enchantment.id end
        out.customObjects[objectData.id] = objectData
    end

    for _, stack in pairs(object.inventory) do
        local item = stack.object
        if allowedItemTypes[item.objectType] and item.weight and item.weight > 0 and
                (item.objectType ~= tes3.objectType.book or item.enchantment) and
                not boundItems[item.id] and not (item.script and item.script ~= "") then
            local count = stack.count
            local addedToEquipmentTable = false
            if stack.variables then
                for _, itData in pairs(stack.variables) do
                    count = count - 1
                    ---@type jai.storage.itemData
                    local data
                    if item.sourceMod then
                        data = {id = item.id, count = 1}
                    else
                        data = {id = getUniqueId(playerId, item.id), count = 1} -- to make the id unique
                        writeCustomObjectData(item)
                    end
                    data.charge = itData.charge
                    data.condition = itData.condition
                    table.insert(out.inventory, data)
                    if object:hasItemEquipped(item, itData) then
                        data.isEquipped = true
                        table.insert(out.equipment, #out.inventory)
                        addedToEquipmentTable = true
                    end
                end
            end
            if count > 0 then
                ---@type jai.storage.itemData
                local data
                if item.sourceMod then
                    data = {id = item.id, count = item.count}
                else
                    data = {id = getUniqueId(playerId, item.id), count = item.count} -- to make the id unique
                    writeCustomObjectData(item)
                end
                table.insert(out.inventory, data)
            end
            if object:hasItemEquipped(item) and not addedToEquipmentTable then
                table.insert(out.equipment, #out.inventory)
            end
        end
    end

    -- attributes
    for id, value in pairs(object.attributes) do
        out.attributes[id] = value
    end

    -- skills
    if object.objectType == tes3.objectType.npc then
        for id, value in pairs(object.skills) do
            out.skills[id] = value
        end
    end

    -- spells
    for _, spell in pairs(object.spells) do
        if spell.castType == tes3.spellType.spell then
            if spell.sourceMod then
                table.insert(out.spells, spell.id)
            else
                table.insert(out.spells, getUniqueId(playerId, spell.id)) -- to make the id unique
                writeCustomObjectData(spell)
            end
        end
    end

    return out
end

---@param record rotf.storage.deathMapRecord
---@param cell tes3cell
---@param playerId string
function this.saveRecordToDeathMap(record, cell, playerId)
    local cellName = stringLib.getCellName(cell)
    local recordDir = fileSys:new(deathMapDir..stringLib.clearFilename(cellName).."\\"..playerId.."\\")
    recordDir:createTomlFile(stringLib.clearFilename(record.name.." The "..tostring(record.deathCount + 1).."th"..".toml"), record)
end

---@param cell tes3cell
---@return table<string, table<integer, string>>
function this.loadDeathMapFileStructureForCell(cell)
    local out = {}
    local cellName = stringLib.getCellName(cell)
    for _, dirData in pairs(fileSys:new(deathMapDir..stringLib.clearFilename(cellName).."\\"):directories()) do
        out[dirData[1]] = {}
        for _, fileData in pairs(fileSys:new(dirData[2]):files(".toml")) do
            table.insert(out[dirData[1]], fileData[2])
        end
    end
    return out
end

---@param path string
---@return rotf.storage.deathMapRecord|nil
function this.loadRecordFromDeathMapByPath(path)
    return toml.loadFile(path)
end

---@param playerId string
---@return rotf.storage.deathMapRecord
function this.savePlayerDeathInfo(playerId)
    local player = tes3.player
    if not this.playerData[playerId] then this.playerData[playerId] = {} end ---@diagnostic disable-line: missing-fields
    local deathCount = (this.playerData[playerId].count or 0) + 1
    this.playerData[playerId].count = deathCount
    local record = serializeActor(playerId, player, player.cell, player.position, player.orientation, deathCount)

    this.saveRecordToDeathMap(record, player.cell, playerId)

    this.save()

    return record
end

function this.getDeathCount(playerId)
    local playerData = this.playerData[playerId]
    if not playerData then return nil end
    return playerData.count
end

function this.getPlayerName(name, useLocalDeathCounter)
    local num = useLocalDeathCounter and config.localConfig.count or this.getDeathCount(config.localConfig.id)
    if num then
        return tes3.player.object.name.." The "..tostring(num + 1).."th"
    else
        return tes3.player.object.name
    end
end

return this