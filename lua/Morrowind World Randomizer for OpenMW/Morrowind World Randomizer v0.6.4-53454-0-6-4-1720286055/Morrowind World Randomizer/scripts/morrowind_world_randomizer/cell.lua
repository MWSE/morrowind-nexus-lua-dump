local this = {}

local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local log = require("scripts.morrowind_world_randomizer.utils.log")
local random = require("scripts.morrowind_world_randomizer.utils.random")
local advString = require("scripts.morrowind_world_randomizer.utils.string")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local types = require('openmw.types')
local world = require("openmw.world")
local util = require("openmw.util")
local core = require('openmw.core')
local async = require('openmw.async')

local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

require("scripts.morrowind_world_randomizer.generator.items")

---@type mwr.itemsData
this.itemsData = nil
---@type mwr.staticsData
this.treesData = nil
---@type mwr.staticsData
this.rocksData = nil
---@type mwr.staticsData
this.floraData = nil
---@type mwr.containersData
this.herbsData = nil
---@type mwr.spellsData
this.spellsData = nil
---@type mwr.lightsData
this.lightsData = nil
---@type mwr.config
this.config = nil
---@type mwr.localStorage
this.storage = nil

function this.isCellReadyForRandomization(cellName)
    local time = this.storage.getCellRandomizationTimestamp(cellName)
    if time and (this.config.data.randomizeOnce or (time + this.config.data.randomizeAfter * 3600 > world.getGameTime())) then
        return false
    end
    return true
end

local function isReadyForRandomization(ref, once)
    local tm = this.storage.getRefRandomizationTimestamp(ref)
    if tm and once then
        return false
    elseif tm and (this.config.data.randomizeOnce or (tm + this.config.data.randomizeAfter * 3600 > world.getGameTime())) then
        return false
    end
    return true
end

function this.createItem(id, oldItemData)
    local new = world.createObject(id, oldItemData.count)
    local newOwner = new.owner
    local oldOwner = oldItemData.owner
    newOwner.factionId = oldOwner.factionId
    newOwner.factionRank = oldOwner.factionRank
    newOwner.recordId = oldOwner.fecordId
    return new
end

---@param globalStorage mwr.globalStorageData
---@param config mwr.config
---@param storage mwr.localStorage
function this.init(globalStorage, config, storage)
    this.itemsData = globalStorage.itemsData
    this.treesData = globalStorage.treesData
    this.rocksData = globalStorage.rocksData
    this.floraData = globalStorage.floraData
    this.herbsData = globalStorage.herbsData
    this.spellsData = globalStorage.spellsData
    this.lightsData = globalStorage.lightsData
    this.config = config
    this.storage = storage
end

local function get2DDistance(vector1, vector2)
    if not vector1 or not vector2 then return 0 end
    return math.sqrt((vector2.x - vector1.x) ^ 2 + (vector2.y - vector1.y) ^ 2)
end

local function minDistanceBetweenVectors(vector, vectorArray)
    local distance = math.huge
    for i, vector2 in pairs(vectorArray) do
        distance = math.min(distance, get2DDistance(vector, vector2))
    end
    return distance
end

local function createNewStatic(oldObj, group, nearestObjects)
    local newObj = world.createObject(group[math.random(1, #group)], 1)
    local box1 = oldObj:getBoundingBox()
    local box2 = newObj:getBoundingBox()
    local scale = math.huge
    local radius1 = 0
    local radius2 = 0
    for i, vert in pairs(box1.vertices) do
        radius1 = math.max(math.abs(vert.x), radius1)
        radius1 = math.max(math.abs(vert.y), radius1)
        radius2 = math.max(math.abs(box2.vertices[i].x), radius2)
        radius2 = math.max(math.abs(box2.vertices[i].y), radius2)
    end
    scale = radius1 / radius2
    if nearestObjects then
        local distanceToNearest = minDistanceBetweenVectors(oldObj.position, nearestObjects)
        local safeRadius = radius1 * 1.3
        if safeRadius > distanceToNearest then
            scale = distanceToNearest / (safeRadius * radius2)
        end
    end
    local offset = (box2.vertices[1].z + math.abs(box2.vertices[8].z - box2.vertices[1].z) * 0.15) * scale
    world.players[1]:sendEvent("mwr_lowestPosInCircle", {
        object = newObj,
        cell = oldObj.cell.name,
        pos = util.vector3(oldObj.position.x, oldObj.position.y, oldObj.position.z + 1000),
        rotation = oldObj.rotation,
        radius = radius1,
        offset = -offset,
        callbackName = "mwr_moveToPoint",
    })
    newObj:setScale(scale)
    this.storage.data.scale[newObj.id] = scale
    this.storage.data.scale[oldObj.id] = nil
    oldObj:remove()
end

local function lockTrap(object, config)
    if types.Lockable.isLocked(object) then
        if config.lock.remove.chance * 0.01 > math.random() then
            types.Lockable.unlock(object)
        elseif config.lock.chance * 0.01 > math.random() then
            local lockLevel = types.Lockable.getLockLevel(object)
            types.Lockable.lock(object, math.max(1, random.getRandom(lockLevel, config.lock.maxValue, config.lock.rregion.min, config.lock.rregion.max)))
        end
    elseif config.lock.add.chance * 0.01 > math.random() then
        local playerLevel = types.Actor.stats.level(world.players[1]).current
        local val = math.floor(math.max(1, math.random() * config.lock.maxValue * math.min(1, playerLevel / config.lock.add.levelReference)))
        types.Lockable.lock(object, val)
    end
    local trap = types.Lockable.getTrapSpell(object)
    if trap then
        if config.trap.remove.chance * 0.01 > math.random() then
            types.Lockable.setTrapSpell(object, nil)
        elseif config.trap.chance * 0.01 > math.random() then
            local group = this.spellsData.groups[core.magic.SPELL_TYPE.Spell].trapHarm
            local playerLevel = types.Actor.stats.level(world.players[1]).current
            local pos = random.getRandom(math.floor(#group * math.min(1, playerLevel / config.trap.levelReference)), #group, 100, 0)
            types.Lockable.setTrapSpell(object, group[pos])
        end
    elseif config.trap.add.chance * 0.01 > math.random() then
        local group = this.spellsData.groups[core.magic.SPELL_TYPE.Spell].trapHarm
        local playerLevel = types.Actor.stats.level(world.players[1]).current
        local pos = random.getRandom(math.floor(#group * math.min(1, playerLevel / config.trap.add.levelReference)), #group, 100, 0)
        types.Lockable.setTrapSpell(object, group[pos])
    end
end

this.randomize = async:callback(function(cell)
    if not cell then return end
    local cellName = advString.getCellName(cell)
    local firstTime = not this.storage.getCellRandomizationTimestamp(cellName)
    if this.isCellReadyForRandomization(cellName) then
        log("cell randomization", cellName)

        this.randomizeStatics(cell, firstTime)

        if this.config.data.world.light.randomize then
            local lightPos = {["0"] = math.random(), ["1"] = math.random(), ["2"] = math.random()}
            for _, light in pairs(cell:getAll(types.Light)) do
                local advData = this.lightsData.objects[light.recordId]
                if advData and light.enabled then
                    local group = this.lightsData.groups[advData.group]
                    local newObj = world.createObject(group[random.getRandom(math.floor(lightPos[advData.group] * #group), #group, 10, 10)], 1)
                    local box1 = light:getBoundingBox()
                    local box2 = newObj:getBoundingBox()
                    local offset = (box1.vertices[1].z - box2.vertices[1].z)
                    local pos = util.vector3(light.position.x, light.position.y, light.position.z + offset)
                    newObj.owner.recordId = light.owner.recordId
                    newObj.owner.factionId = light.owner.factionId
                    newObj.owner.factionRank = light.owner.factionRank
                    light:remove()
                    newObj:teleport(light.cell, pos, {rotation = light.rotation})
                end
            end
        end

        this.storage.setCellRandomizationTimestamp(cellName)
        local config = this.config.getConfigTableByObjectType(nil)
        local items = cell:getAll()
        for _, item in pairs(items or {}) do
            if not item.enabled then goto continue end
            ---@type mwr.itemPosData
            local advItemData = this.itemsData.items[item.recordId]
            local isArtifact = generatorData.obtainableArtifacts[item.recordId]
            local newId
            if isArtifact and this.config.data.item.artifactsAsSeparate then
                if not this.storage.data.other.artifacts or #this.storage.data.other.artifacts == 0 then
                    this.storage.data.other.artifacts = {}
                    for id, _ in pairs(generatorData.obtainableArtifacts) do
                        table.insert(this.storage.data.other.artifacts, id)
                    end
                end
                local pos = math.random(1, #this.storage.data.other.artifacts)
                newId = this.storage.data.other.artifacts[pos]
                table.remove(this.storage.data.other.artifacts, pos)
            elseif advItemData and config then
                if this.config.data.item.safeMode and advItemData.count and this.config.data.item.safeModeThreshold > advItemData.count then
                    goto continue
                end
                local grp = this.itemsData.groups[advItemData.type][advItemData.subType]
                newId = grp[random.getRandom(advItemData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
            end

            if newId then
                local new = this.createItem(newId, item)
                local pos = item.position
                local rot = item.rotation
                log("world", item, "new item", new, "count ", new.count)
                new.owner.recordId = item.owner.recordId
                new.owner.factionId = item.owner.factionId
                new.owner.factionRank = item.owner.factionRank
                item:remove()
                new:teleport(cell, pos, {onGround = true, rotation = rot})
            end
            ::continue::
        end

        local containers = cell:getAll(types.Container)
        config = this.config.getConfigTableByObjectType(objectType.container)
        for _, container in pairs(containers or {}) do
            local record = types.Container.record(container)
            if record.mwscript ~= "" or not container.enabled or (not isReadyForRandomization(container) and this.config.data.doNot.activatedContainers) or
                    generatorData.forbiddenContainersDoors[container.recordId] then goto continue end
            if this.herbsData.objects[container.recordId] then -- for herbs
                if this.config.data.world.herb.item.randomize then
                    local inventory = types.Container.content(container)
                    if not inventory:isResolved() then
                        inventory:resolve()
                    end
                    container:sendEvent("mwr_container_randomizeInventory", {itemsData = this.itemsData, config = this.config.getConfigTableByObjectType("HERB")})
                end
                if this.config.data.world.herb.randomize then
                    local group = {}
                    for i = 1, this.config.data.world.herb.typesPerCell do
                        table.insert(group, this.herbsData.list[math.random(1, #this.herbsData.list)])
                    end
                    createNewStatic(container, group)
                end
            elseif config then
                if config.item.randomize then
                    local inventory = types.Container.content(container)
                    if not inventory:isResolved() then
                        inventory:resolve()
                    end
                    container:sendEvent("mwr_container_randomizeInventory", {itemsData = this.itemsData, config = config})
                end
                lockTrap(container, config)
            end
            ::continue::
        end

        local doors = cell:getAll(types.Door)
        config = this.config.getConfigTableByObjectType(objectType.door)
        for _, door in pairs(doors or {}) do
            if not generatorData.forbiddenContainersDoors[door.recordId] then
                lockTrap(door, config)
            end
        end
    end
end)

this.randomizeStatics = async:callback(function(cell, isFirstTime)
    if not cell.isExterior then return end
    local config = this.config.data.world.static
    if config.tree.randomize or config.rock.randomize or config.rock.randomize then
        local statics = cell:getAll(types.Static)

        local importantObjPositions
        if isFirstTime then
            importantObjPositions = {}
            for i = cell.gridX - 1, cell.gridX + 1 do
                for j = cell.gridY - 1, cell.gridY + 1 do
                    local objCell = world.getExteriorCell(i, j)
                    if objCell then
                        local objects = {}
                        tableLib.addTableValuesToTable(objects, cell:getAll(types.Door))
                        tableLib.addTableValuesToTable(objects, cell:getAll(types.NPC))
                        tableLib.addTableValuesToTable(objects, cell:getAll(types.Creature))
                        tableLib.addTableValuesToTable(objects, cell:getAll(types.Activator))
                        for _, obj in pairs(objects) do
                            table.insert(importantObjPositions, util.vector2(obj.position.x, obj.position.y))
                        end
                    end
                end
            end
        end

        local groupTrees = {}
        if config.tree.randomize then
            for i = 1, config.tree.typesPerCell do
                tableLib.addTableValuesToTable(groupTrees, this.treesData.groups[math.random(1, #this.treesData.groups)])
            end
        end
        local groupRocks = {}
        if config.rock.randomize then
            for i = 1, config.rock.typesPerCell do
                tableLib.addTableValuesToTable(groupRocks, this.rocksData.groups[math.random(1, #this.rocksData.groups)])
            end
        end
        local groupFlora = {}
        if config.rock.randomize then
            for i = 1, config.flora.typesPerCell do
                tableLib.addTableValuesToTable(groupFlora, this.floraData.groups[math.random(1, #this.floraData.groups)])
            end
        end
        for i, obj in pairs(statics) do
            if obj.enabled then
                if config.tree.randomize and this.treesData.objects[obj.recordId] then
                    createNewStatic(obj, groupTrees, importantObjPositions)
                elseif config.rock.randomize and this.rocksData.objects[obj.recordId] then
                    createNewStatic(obj, groupRocks, importantObjPositions)
                elseif config.flora.randomize and this.floraData.objects[obj.recordId] then
                    createNewStatic(obj, groupFlora, importantObjPositions)
                end
            end
        end
    end
end)

return this