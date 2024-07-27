local log = include("Morrowind_World_Randomizer.log")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local random = include("Morrowind_World_Randomizer.Random")
local light = include("Morrowind_World_Randomizer.light")
local itemLib = include("Morrowind_World_Randomizer.item")
local saveRestore = include("Morrowind_World_Randomizer.saveRestore")
local inventoryEvents = include("Morrowind_World_Randomizer.inventoryEvents")

local treesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\TreesData_TR")
local rocksData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\RocksData_TR")
local floraData

local generator = include("Morrowind_World_Randomizer.generator")

local itemsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Items")
local creaturesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Creatures")
local herbsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Herbs")
local headPartsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\HeadsHairs")
local travelDestinationsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\TravelDestinations")
local spellsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Spells")
local itemLibData = nil

local this = {}

this.config = include("Morrowind_World_Randomizer.config")
this.storage = include("Morrowind_World_Randomizer.storage")
this.doors = include("Morrowind_World_Randomizer.doorRandomizer")
this.doors.initConfig(this.config)

this.randomizeCellLight = light.randomizeCellLight
this.restoreLightData = light.restoreLightData
this.restoreCellLight = light.restoreCellLight

this.itemsToUntrackForUnique = {}

function this.genStaticData()
    local TRDataVersion = 0
    for i, mod in pairs(tes3.dataHandler.nonDynamicData.activeMods) do
        if mod.filename:lower() == "tamriel_data.esm" then
            TRDataVersion = tonumber(string.match(mod.description, "%d+") or "0")
        end
    end

    -- if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --     -- treesData = require("Morrowind_World_Randomizer.Data.TreesData_TR")
    --     -- rocksData = require("Morrowind_World_Randomizer.Data.RocksData_TR")
    --     treesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\TreesData_TR")
    --     rocksData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\RocksData_TR")
    -- end
    treesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\TreesData_TR")
    rocksData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\RocksData_TR")
    if this.config.global.generation.generateTreeData then
        treesData = generator.fillTrees()
    else
        generator.correctStaticsData(treesData)
    end
    if this.config.global.generation.generateRockData then
        rocksData = generator.fillRocks()
    else
        generator.correctStaticsData(rocksData)
    end

    floraData = generator.fillFlora()
    -- if this.config.global.dataTables.usePregeneratedItemData then
    --     if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --         itemsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Items_TR")
    --     else
    --         itemsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Items")
    --     end
    -- else
        itemsData = generator.fillItems()
    -- end

    -- if this.config.global.dataTables.usePregeneratedCreatureData then
    --     if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --         creaturesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Creatures_TR")
    --     else
    --         creaturesData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Creatures")
    --     end
    -- else
        creaturesData = generator.fillCreatures()
    -- end

    -- if this.config.global.dataTables.usePregeneratedHeadHairData then
    --     if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --         headPartsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\HeadsHairs_TR")
    --     else
    --         headPartsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\HeadsHairs")
    --     end
    -- else
        headPartsData = generator.fillHeadsHairs()
    -- end

    -- if this.config.global.dataTables.usePregeneratedSpellData then
    --     if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --         spellsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Spells_TR")
    --     else
    --         spellsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Spells")
    --     end
    -- else
        spellsData = generator.fillSpells()
    -- end

    -- if this.config.global.dataTables.usePregeneratedHerbData then
    --     if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
    --         herbsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Herbs_TR")
    --     else
    --         herbsData = json.loadfile("mods\\Morrowind_World_Randomizer\\Data\\Herbs")
    --     end
    -- else
        herbsData = generator.fillHerbs()
    -- end

    travelDestinationsData = generator.findTravelDestinations()
    itemLibData = itemLib.generateData()

    -- local newRocksData = generator.rebuildRocksTreesData(require("Morrowind_World_Randomizer.Data.RocksData_TR"))
    -- local newTreesData = generator.rebuildRocksTreesData(require("Morrowind_World_Randomizer.Data.TreesData_TR"))
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\RocksData_TR", rocksData)
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\TreesData_TR", treesData)

    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\Items", itemsData)
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\Creatures", creaturesData)
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\HeadsHairs", headPartsData)
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\Spells", spellsData)
    -- json.savefile("mods\\Morrowind_World_Randomizer\\Data\\Herbs", herbsData)
end

function this.genNonStaticData()
    this.doors.findDoors()
end

function this.fixLoaded()
    timer.start{duration = 1, callback = function()
        local cells = tes3.getActiveCells()
        if cells ~= nil then
            for i, cell in pairs(cells) do
                itemLib.fixCell(cell, true)
            end
        end
        itemLib.fixPlayerInventory(true)
        tes3.updateInventoryGUI{reference = tes3.player}
    end}
end

function this.randomizeBaseItems()
    this.storage.restoreAllItems(true)
    this.storage.deleteUncreatedItems()
    itemLib.randomizeItems(itemLibData)
    itemLib.clearFixedCellList()
    this.fixLoaded()
end

---@deprecated
function this.restoreItems()
    if itemLib.hasRandomizedItems() then
        itemLib.restoreItems()
        this.fixLoaded()
    end
end

local function getGroundZ(vector)
    local res = tes3.rayTest {
        position = tes3vector3.new(vector.x, vector.y, vector.z + 2000),
        direction = tes3vector3.new(0, 0, -1),
        root = tes3.game.worldLandscapeRoot,
        useBackTriangles = true,
        maxDistance = 6000
    }
    if res == nil then
        res = tes3.rayTest {
            position = tes3vector3.new(vector.x, vector.y, vector.z - 2000),
            direction = tes3vector3.new(0, 0, 1),
            root = tes3.game.worldLandscapeRoot,
            useBackTriangles = true,
            maxDistance = 6000
        }
    end
    if res ~= nil then
        return res.intersection.z
    end
    log("Ray tracing failed %s %s %s", tostring(vector.x), tostring(vector.y), tostring(vector.z))
    return nil
end

local function getGroundPos(vector, offset)
    local res = getGroundZ(vector)
    if res ~= nil then
        return tes3vector3.new(vector.x, vector.y, res + offset)
    end
    return nil
end

local pointOnCircleSin = {}
local pointOnCircleCos = {}
for i = 1, 8 do
    pointOnCircleSin[i] = math.sin((math.pi / 4) * i)
    pointOnCircleCos[i] = math.cos((math.pi / 4) * i)
end

local function getMinGroundPosInCircle(vector, radius, offset)
    local minZ = math.huge
    for i = 1, 8 do
        local posVector = tes3vector3.new(vector.x + radius * pointOnCircleCos[i], vector.y + radius * pointOnCircleSin[i], vector.z)
        local z = getGroundZ(posVector)
        if z ~= nil then
            minZ = math.min(minZ, z)
        end
    end
    local z = getGroundZ(vector)
    if z ~= nil then
        minZ = math.min(minZ, z)
    end
    if minZ ~= math.huge then
        return tes3vector3.new(vector.x, vector.y, minZ + offset)
    end
    return nil
end

---@param vector1 tes3vector3
---@param vector2 tes3vector3
---@return number
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

local function putOriginMark(object)
    local data = dataSaver.getObjectData(object)
    data.origin = true
end

local function deleteOriginMark(object)
    local data = dataSaver.getObjectData(object)
    data.origin = nil
end

local function randomizeSoulgemItemData(itemData)
    local config = this.config.data.soulGems
    if config.soul.randomize and itemData ~= nil and itemData.soul ~= nil then
        local soulCrea = creaturesData.Creatures[itemData.soul.id:lower()]
        if soulCrea ~= nil then
            local creaGroup = creaturesData.CreatureGroups[soulCrea.SubType]
            local newCreaId = creaGroup.Items[random.GetRandom(soulCrea.Position, creaGroup.Count,
                config.soul.region.min, config.soul.region.max)]
            log("Soul %s to %s", tostring(itemData.soul), tostring(newCreaId))
            itemData.soul = tes3.getObject(newCreaId)
        end
    end
end

function this.getRandomSoulIdForGem(creaGroup, soulgemCapacity)
    local soulId
    if creaGroup then
        soulId = creaGroup.Items[random.GetRandom(math.floor(#creaGroup.Items * math.min(1, soulgemCapacity / this.config.data.soulGems.maxCapacity)),
            #creaGroup.Items, this.config.data.soulGems.soul.region.min, this.config.data.soulGems.soul.region.max)]
        log("New soul %s", tostring(soulId))
    end
    return soulId
end

function this.isOrigin(object)
    local data = dataSaver.getObjectData(object)
    return data.origin or false
end

function this.StopRandomizationTemp(object)
    local data = dataSaver.getObjectTempData(object)
    data.stopRand = true
end

function this.StopRandomization(object)
    local data = dataSaver.getObjectData(object)
    data.stopRand = true
end

function this.isRandomizationStoppedTemp(object)
    local data = dataSaver.getObjectTempData(object)
    if data ~= nil and data.stopRand == true then
        return true
    end
    return false
end

function this.isRandomizationStopped(object)
    local data = dataSaver.getObjectData(object)
    if data ~= nil and data.stopRand == true then
        return true
    end
    return false
end

function this.getNewRandomItemId(oldItemId, min, max)
    local newId
    local itemAdvData = itemsData.Items[oldItemId]
    if itemAdvData ~= nil then
        local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
        newId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count,
            min or this.config.data.containers.items.region.min, max or this.config.data.containers.items.region.max)]
        log("Item id selected %s to %s", tostring(oldItemId), tostring(newId))
    end
    return newId
end

function this.getRandomCreatureId(oldCreatureId)
    local creaId = oldCreatureId:lower()
    local creature = creaturesData.Creatures[creaId]
    if creature ~= nil then
        local newCreaGroup = creaturesData.CreatureGroups[creature.SubType]
        local newCreaId = newCreaGroup.Items[random.GetRandom(creature.Position, newCreaGroup.Count,
            this.config.data.creatures.region.min, this.config.data.creatures.region.max)]
        log("Creature id selected %s to %s", tostring(oldCreatureId), tostring(newCreaId))
        return newCreaId
    end
    return nil
end

---@param id string
function this.getNewItem(id)
    local it = tes3.getObject(id)
    if it then
        if this.config.data.item.unique and it.sourceMod and (itemLib.itemTypeForUnique[it.objectType]) and
                (not it.script or this.config.data.item.uniqueScriptItems) then
            this.storage.saveItem(it, nil, true)
            it.weight = 0
            itemLib.setDummyEnchantment(it)
            it = itemLib.randomizeBaseItem(it, {createNewItem = true})
            log("New item %s to %s", id, tostring(it and it.id))
        end
    end
    return it
end

function this.updatePlayerInventory()
    if this.config.data.item.unique then
        local player = tes3.mobilePlayer
        if not player then return end
        local updated = false
        local changed = inventoryEvents.getInventoryChanges()
        if changed then
            for id, data in pairs(changed) do
                if itemLib.itemTypeForUnique[data.object.objectType] then
                    local wasCreated, origId = itemLib.isItemWasCreated(data.object.id)
                    if data.object.script and not this.config.data.item.uniqueScriptItems then
                        if not wasCreated then goto continue end
                        this.storage.restoreItem(origId, true)
                        itemLib.randomizeBaseItem(tes3.getObject(origId), {})
                        tes3.removeItem{reference = player, item = data.object, count = data.count, playSound = false}
                        tes3.addItem{reference = player, item = origId, count = data.count, playSound = false}
                        updated = true
                    elseif wasCreated then
                        if data.count > 0 then
                            tes3.addItem{reference = player, item = origId, count = data.count, playSound = false}
                            updated = true
                            log("Added original item %s", tostring(origId))
                        elseif data.count < 0 then
                            tes3.removeItem{reference = player, item = origId, count = -data.count, playSound = false}
                            updated = true
                            log("Removed original item %s", tostring(origId))
                        end
                    else
                        if data.count > 0 then
                            local item = this.getNewItem(id)
                            if item and not this.itemsToUntrackForUnique[item.id] then
                                tes3.addItem{reference = player, item = item, count = data.count, playSound = false}
                                updated = true
                                log("Added unoriginal item %s", tostring(item))
                                local origItem = tes3.getObject(id)
                                if origItem then
                                    origItem.weight = 0
                                    itemLib.setDummyEnchantment(origItem)
                                end
                                for i = 1, data.count do
                                    local equipped = tes3.getEquippedItem{actor = player, objectType = item.objectType, slot = item.slot,
                                        type = item.objectType == tes3.objectType.weapon and item.type or nil}
                                    if equipped then
                                        player:unequip{item = data.object}
                                        player:equip{item = item}
                                    else
                                        break
                                    end
                                end
                            end
                        elseif data.count < 0 then
                            local count = -data.count
                            for _, stack in pairs(player.inventory) do
                                local _, itOrigId = itemLib.isItemWasCreated(stack.object.id)
                                if data.id == itOrigId then
                                    count = count - tes3.removeItem{reference = player, item = stack.object, count = count, playSound = false}
                                    updated = true
                                    log("Removed unoriginal item %s", tostring(stack.object))
                                end
                                if count <= 0 then break end
                            end
                        end
                    end
                end
                ::continue::
            end
            if updated then
                itemLib.fixPlayerWeight()
                inventoryEvents.saveInventoryChanges()
                tes3.updateInventoryGUI{ reference = player }
            end
        end
    end
end

function this.randomizeContainerItems(reference, regionMin, regionMax)

    if reference and not this.isRandomizationStopped(reference) and not this.isRandomizationStoppedTemp(reference) then

        log("Container randomization %s", tostring(reference))
        local config = this.config.data
        local newItems = {}
        local oldItems = {}
        local artifacts = {}

        for _, stack in pairs(reference.baseObject.inventory.items) do
            local item = stack.object
            if item ~= nil then
                local itemId = item.id:lower()
                local itemAdvData = itemsData.Items[itemId]
                if itemAdvData ~= nil then
                    if config.other.randomizeArtifactsAsSeparateCategory == true and itemAdvData.IsArtifact == true then
                        artifacts[itemId] = true
                    end
                end
            end
        end

        for _, stack in pairs(reference.object.inventory.items) do
            local item = stack.object
            local count = math.abs(stack.count)
            local itemId = item.id:lower()
            local itemAdvData = itemsData.Items[itemId]
            if itemAdvData ~= nil then
                if artifacts[itemId] == nil then
                    local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
                    local newItemId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, #newItemGroup.Items, regionMin, regionMax)]
                    table.insert(newItems, {id = newItemId, count = stack.count})
                    table.insert(oldItems, {id = item.id, count = count})
                    if stack.count < 0 then stack.count = -stack.count end
                else
                    local data = dataSaver.getObjectData(tes3.player)
                    if data then
                        if data.unfoundArtifacts == nil or #data.unfoundArtifacts == 0 then
                            data.unfoundArtifacts = {}
                            for _, id in pairs(itemsData.ItemGroups["ARTF"]["0"].Items) do
                                table.insert(data.unfoundArtifacts, id)
                            end
                        end
                        local idInList = math.random(1, #data.unfoundArtifacts)
                        local newItemId = data.unfoundArtifacts[idInList]
                        table.remove(data.unfoundArtifacts, idInList)
                        table.insert(newItems, {id = newItemId, count = stack.count})
                        table.insert(oldItems, {id = item.id, count = count})
                        if stack.count < 0 then stack.count = -stack.count end
                    end
                    this.StopRandomization(reference)
                end

            elseif stack.object.isGold and config.gold.randomize then

                local newGoldCount = config.gold.additive and count + random.GetBetween(config.gold.region.min, config.gold.region.max) or
                    count * random.GetBetween(config.gold.region.min, config.gold.region.max)
                local newCount = math.floor(math.max(1, newGoldCount))
                log("Gold count %s to %s", tostring(stack.count), tostring(newCount))
                stack.count = newCount

            elseif stack.object.isSoulGem and config.soulGems.soul.randomize then
                if stack.variables then
                    for _, itemData in pairs(stack.variables) do
                        randomizeSoulgemItemData(itemData)
                    end
                else
                    table.insert(oldItems, {id = item.id, count = count})
                    for i = 1, count do
                        local soulId = nil
                        if config.soulGems.soul.add.chance > math.random() then
                            local creaGroup = creaturesData.CreatureGroups[tostring(math.random(0, 3))]
                            if creaGroup then
                                soulId = this.getRandomSoulIdForGem(creaGroup, item.soulGemCapacity)
                            end
                        end
                        table.insert(newItems, {id = item.id, count = 1, soul = soulId})
                    end
                end

            elseif this.config.data.item.unique and item.sourceMod and itemLib.itemTypeForUnique[item.objectType] then

                table.insert(newItems, {id = item.id, count = stack.count})
                table.insert(oldItems, {id = item.id, count = count})
                if stack.count < 0 then stack.count = -stack.count end

            end
        end

        for i, item in pairs(oldItems) do
            tes3.removeItem({ reference = reference, item = item.id, count = item.count, updateGUI = false })
            log("Item removed %s %s", tostring(item.id), tostring(item.count))
        end

        local negativeStock = {}
        for i, item in pairs(newItems) do
            local it = this.getNewItem(item.id)
            local count = math.abs(item.count)
            if it then
                tes3.addItem({ reference = reference, item = it, count = count, soul = item.soul, updateGUI = false })
                if item.count < 0 then
                    negativeStock[it.id] = item.count
                end
                log("Item added %s (%s) %s", tostring(it.id), tostring(item.id), tostring(item.count))
            end
        end

        for _, stack in pairs(reference.object.inventory.items) do
            if negativeStock[stack.object.id] and stack.count > 0 then
                stack.count = -stack.count
            end
        end
        tes3.setSourceless(reference.baseObject, false)
        tes3.setSourceless(reference.object, false)
        tes3.setSourceless(reference, false)
    end
end

function this.createObject(object)
    local newObject = tes3.getObject(object.id)
    if newObject ~= nil then
        log("New object %s", tostring(newObject))
        if this.config.data.item.unique and itemLib.itemTypeForUnique[newObject.objectType] then
            newObject = this.getNewItem(newObject.id)
        end
        local reference = tes3.createReference{ object = newObject, position = object.pos, orientation = object.rot, cell = object.cell, scale = object.scale or 1 }
        if reference ~= nil then
            local objData = dataSaver.getObjectData(reference)
            if objData then objData.isCreated = true end
            local itemData = object.itemData
            if itemData ~= nil then
                local count = itemData.count
                local owner = itemData.owner
                local requirement = itemData.requirement
                if owner ~= nil or requirement ~= nil then
                    tes3.setOwner({ reference = reference, owner = owner, requiredRank = requirement })
                end
                if reference.itemData then
                    reference.itemData.count = count
                else
                    local createdData = tes3.addItemData({ to = reference, item = reference.object, updateGUI = false })
                    if createdData then createdData.count = count end
                end
                log("New object count %s", tostring(count))
            end
            if object.stopRand and objData then
                this.StopRandomization(reference)
            end
        end
        return reference
    end
    return nil
end

function this.randomizeCell(cell)
    log("Cell randomization %s", tostring(cell.editorName))
    local newObjects = {}
    local config = this.config.data
  
    local newTreeGroupList = {}
    local newRockGroupList = {}
    for i = 1, math.max(1, config.trees.typesPerCell) do
        table.insert(newTreeGroupList, treesData.Groups[math.random(1, #treesData.Groups)])
    end
    for i = 1, math.max(1, config.stones.typesPerCell) do
        table.insert(newRockGroupList, rocksData.Groups[math.random(1, #rocksData.Groups)])
    end
    local newFloraGroup = {}
    for i = 1, this.config.data.flora.typesPerCell do
        local groupId = math.random(1, #floraData.Groups)
        for _, val in pairs(floraData.Groups[groupId] or {}) do
            table.insert(newFloraGroup, val)
        end
    end

    local herbsList = {}
    local herbsToListCount = config.herbs.herbSpeciesPerCell
    local herbsTempTable = {}
    while herbsToListCount > 0 do
        local dt = herbsData.HerbsObjectList[math.random(1, herbsData.HerbsListCount)]:lower()
        if herbsTempTable[dt] == nil then
            herbsToListCount = herbsToListCount - 1
            herbsTempTable[dt] = true
        end
    end
    for id, _ in pairs(herbsTempTable) do
        table.insert(herbsList, id)
    end

    local maxFightOnActor = 0
    for actor in cell:iterateReferences({tes3.objectType.creature, tes3.objectType.npc}) do
        if actor and actor.mobile and actor.mobile.fight then
            maxFightOnActor = math.max(maxFightOnActor, actor.mobile.fight)
        end
    end
    log("Max cell fight %s", tostring(maxFightOnActor))

    local importantObjPositions = {}
    if not cell.isInterior then
        for i = cell.gridX - 1, cell.gridX + 1 do
            for j = cell.gridY - 1, cell.gridY + 1 do
                local objCell = tes3.getCell{ x = i, y = j}
                if objCell then
                    for obj in objCell:iterateReferences({tes3.objectType.door, tes3.objectType.npc, tes3.objectType.activator}) do
                        if obj ~= nil and obj.disabled ~= true then
                            table.insert(importantObjPositions, obj.position)
                        end
                    end
                end
            end
        end
    elseif cell.isOrBehavesAsExterior then
        for obj in cell:iterateReferences({tes3.objectType.door, tes3.objectType.npc, tes3.objectType.activator}) do
            if obj ~= nil and obj.disabled ~= true then
                table.insert(importantObjPositions, obj.position)
            end
        end
    end

    if this.config.data.light.randomize then
        this.randomizeCellLight(cell)
    end

    for object in cell:iterateReferences() do
        if object ~= nil and object.data ~= nil and object.deleted ~= true and not this.isRandomizationStopped(object) and
                not this.isRandomizationStoppedTemp(object) then
            local objectId = object.id:lower()
            local objectPos = object.position
            local objectRot = object.orientation
            local objectScale = object.scale or 1
            local objectData = dataSaver.getObjectData(object)


            if objectData ~= nil and objectData.isCreated == true and not object.isDead then
                object:delete()

            elseif object.baseObject.objectType == tes3.objectType.static and cell.isOrBehavesAsExterior then

                local treeAdvData = treesData.Data[objectId]
                local rockAdvData = rocksData.Data[objectId]
                local floraAdvData = floraData.Data[objectId]
                local objAdvData = treeAdvData or rockAdvData or floraAdvData
                if objAdvData then
                    local success = false
                    local configLink
                    local grp
                    local arr
                    if treeAdvData ~= nil and objectScale < config.trees.exceptScale then
                        configLink = config.trees
                        grp = newTreeGroupList[math.random(1, #newTreeGroupList)]
                        arr = treesData
                        success = true
                    elseif rockAdvData ~= nil and objectScale < config.stones.exceptScale then
                        configLink = config.stones
                        grp = newRockGroupList[math.random(1, #newRockGroupList)]
                        arr = rocksData
                        success = true
                    elseif floraAdvData ~= nil then
                        configLink = config.flora
                        grp = newFloraGroup
                        arr = floraData
                        success = true
                    end
                    if success and configLink.randomize and (this.isOrigin(object) or not object.disabled) then
                        local newId = grp[math.random(1, #grp)]
                        local newAdvData = arr.Data[newId:lower()]
                        local newOffset
                        local radius = 300
                        if newAdvData == nil then
                            newOffset = 0
                        else
                            newOffset = newAdvData.Offset
                            radius = newAdvData.Radius
                        end

                        local scale = objectScale
                        local distanceToObj =  minDistanceBetweenVectors(objectPos, importantObjPositions)
                        local radiusScaled = radius * scale
                        if distanceToObj < radiusScaled * 1.3 then
                            scale = math.min(scale, scale * distanceToObj / radiusScaled * 0.6)
                        end

                        local posVector = getMinGroundPosInCircle(objectPos, radius * scale, newOffset * scale)
                        if posVector == nil then
                            posVector = tes3vector3.new(objectPos.x, objectPos.y, (newOffset - objAdvData.Offset - math.random(0, 50)) * scale)
                        end
                        table.insert(newObjects, {id = newId, pos = posVector, rot = objectRot, scale = scale, cell = cell})
                        putOriginMark(object)
                        object:disable()

                    elseif this.isOrigin(object) and object.disabled then
                        this.deleteOriginMark(object)
                        object:enable()
                    end
                end

            elseif object.baseObject.objectType == tes3.objectType.container then

                local herbAdvData = herbsData.Herbs[objectId]
                if herbAdvData ~= nil then
                    if config.herbs.randomize and cell.isOrBehavesAsExterior and (this.isOrigin(object) or not object.disabled) then
                        local newId = herbsList[math.random(1, #herbsList)]
                        local newHerbAdvData = herbsData.Herbs[newId]
                        if newHerbAdvData ~= nil then
                            local posVector = getGroundPos(objectPos, (newHerbAdvData.Offset - math.random(0, 5)) * objectScale)
                            if posVector == nil then
                                posVector = tes3vector3.new(objectPos.x, objectPos.y, (newHerbAdvData.Offset - herbAdvData.Offset - math.random(0, 5)) * objectScale)
                            end

                            local rot = objectRot:copy()
                            if newId:sub(1, -4) == "flora_bc_shelffungus" then
                                rot.y = rot.y + 1.65
                            end

                            -- this.StopRandomizationTemp(object)
                            local stopRand = this.config.data.herbs.doNotRandomizeInventory
                            table.insert(newObjects, {id = newId, pos = posVector, rot = rot, scale = objectScale, stopRand = stopRand, cell = cell})
                            putOriginMark(object)
                            object:disable()

                        end
                    elseif this.isOrigin(object) and object.disabled then
                        this.deleteOriginMark(object)
                        object:enable()
                    end

                else
                    if config.containers.items.randomize or config.item.unique then
                        this.randomizeContainerItems(object, this.config.data.containers.items.region.min, this.config.data.containers.items.region.max)
                    end
                    if not object.baseObject.script then
                        this.randomizeLockTrap(object)
                    end
                end

            elseif (config.items.randomize or (config.item.unique and itemLib.itemTypeForUnique[object.baseObject.objectType])) and
                    (object.baseObject.objectType == tes3.objectType.weapon or
                    object.baseObject.objectType == tes3.objectType.alchemy or
                    object.baseObject.objectType == tes3.objectType.apparatus or
                    object.baseObject.objectType == tes3.objectType.armor or
                    object.baseObject.objectType == tes3.objectType.book or
                    object.baseObject.objectType == tes3.objectType.clothing or
                    object.baseObject.objectType == tes3.objectType.ingredient or
                    object.baseObject.objectType == tes3.objectType.lockpick or
                    object.baseObject.objectType == tes3.objectType.probe or
                    object.baseObject.objectType == tes3.objectType.repairItem) then

                local uniqBehavior = false
                if config.item.unique and itemLib.itemTypeForUnique[object.baseObject.objectType] then
                    uniqBehavior = true
                end
                local itemAdvData = itemsData.Items[objectId]
                if itemAdvData ~= nil then
                    if itemAdvData.IsArtifact ~= true then
                        local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
                        local newItemId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count,
                            this.config.data.items.region.min, this.config.data.items.region.max)]
                        table.insert(newObjects, {id = this.getNewItem(newItemId).id, pos = objectPos, rot = objectRot, scale = objectScale, itemData = object.itemData,
                            objectType = object.object.objectType, stopRand = uniqBehavior, cell = cell})
                        object:disable()
                        if uniqBehavior then
                            this.StopRandomization(object)
                        end

                    else
                        local data = dataSaver.getObjectData(tes3.player)
                        if data then
                            if data.unfoundArtifacts == nil or #data.unfoundArtifacts == 0 then
                                data.unfoundArtifacts = {}
                                for _, id in pairs(itemsData.ItemGroups["ARTF"]["0"].Items) do
                                    table.insert(data.unfoundArtifacts, id)
                                end
                            end
                            local idInList = math.random(1, #data.unfoundArtifacts)
                            local newItemId = data.unfoundArtifacts[idInList]
                            local itemData = object.itemData and {count = object.itemData.count, owner = object.itemData.owner, requirement = object.itemData.requirement} or nil
                            local newRef = this.createObject({id = this.getNewItem(newItemId).id, pos = objectPos, rot = objectRot, scale = objectScale,
                                itemData = itemData, objectType = object.object.objectType, cell = cell})
                            if newRef then
                                table.remove(data.unfoundArtifacts, idInList)
                                this.StopRandomization(object)
                                this.StopRandomization(newRef)
                                object:disable()
                            end
                        end
                    end

                elseif uniqBehavior then

                    table.insert(newObjects, {id = this.getNewItem(objectId).id, pos = objectPos, rot = objectRot, scale = objectScale, itemData = object.itemData,
                        objectType = object.object.objectType, stopRand = true, cell = cell})
                    this.StopRandomization(object)
                    object:disable()

                end

            elseif object.baseObject.objectType == tes3.objectType.miscItem then

                if object.object.isSoulGem then

                    randomizeSoulgemItemData(object.itemData)

                end

            elseif not object.isDead and object.baseObject.objectType == tes3.objectType.creature and
                    this.config.data.creatures.randomize and object.leveledBaseReference ~= true then

                local newCreaId = this.getRandomCreatureId(object.baseObject.id)
                if newCreaId ~= nil and object.mobile ~= nil then
                    object.mobile:kill()
                    object:disable()
                    table.insert(newObjects, {id = newCreaId, cell = cell, pos = objectPos, rot = objectRot, scale = objectScale})
                end

            elseif object.baseObject.objectType == tes3.objectType.npc and object.isDead then

                this.randomizeContainerItems(object, this.config.data.NPCs.items.region.min, this.config.data.NPCs.items.region.max)
                this.StopRandomization(object)

            elseif object.baseObject.objectType == tes3.objectType.creature and object.isDead then

                this.randomizeContainerItems(object, this.config.data.creatures.items.region.min, this.config.data.creatures.items.region.max)
                this.StopRandomization(object)

            elseif object.baseObject.objectType == tes3.objectType.door then

                this.doors.resetDoorDestination(object)
                if this.config.data.doors.onlyOnCellRandomization then
                    this.doors.randomizeDoor(object)
                end
                local cnfg = this.config.data.doors
                local tolock = not cnfg.lock.safeCellMode.enabled or (cnfg.lock.safeCellMode.enabled and maxFightOnActor >= cnfg.lock.safeCellMode.fightValue)
                local totrap = not cnfg.trap.safeCellMode.enabled or (cnfg.trap.safeCellMode.enabled and maxFightOnActor >= cnfg.trap.safeCellMode.fightValue)
                this.randomizeLockTrap(object, tolock, totrap)

            end

        elseif object ~= nil and object.baseObject.objectType == tes3.objectType.miscItem and object.itemData ~= nil and
                object.object.isGold and config.gold.randomize then

            local newGoldVal = config.gold.additive and object.itemData.count + random.GetBetween(config.gold.region.min, config.gold.region.max) or
                object.itemData.count * random.GetBetween(config.gold.region.min, config.gold.region.max)
            local newCount = math.floor(math.max(newGoldVal, 1))
            object.itemData.count = newCount

        elseif object ~= nil and config.items.randomize and object.baseObject.objectType == tes3.objectType.ammunition then

            local objectId = object.id:lower()
            if object.sourceMod and not object.disabled then
                local itemAdvData = itemsData.Items[objectId]
                local itemData = object.itemData and {count = object.itemData.count, owner = object.itemData.owner, requirement = object.itemData.requirement} or nil
                if itemAdvData ~= nil then

                    local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
                    local newItemId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count,
                        this.config.data.items.region.min, this.config.data.items.region.max)]
                    table.insert(newObjects, {id = this.getNewItem(newItemId).id, pos = object.position, rot = object.orientation,
                        scale = object.scale, itemData = itemData, objectType = object.object.objectType, cell = cell})
                    object:disable()

                elseif config.item.unique and itemLib.itemTypeForUnique[object.baseObject.objectType] then

                    table.insert(newObjects, {id = this.getNewItem(object.id).id, pos = object.position, rot = object.orientation,
                        scale = object.scale, itemData = itemData, objectType = object.object.objectType, cell = cell})
                    object:disable()
                end
            end

        end
    end

    for i, object in pairs(newObjects) do
        local newRef = this.createObject(object)
        -- if newRef then
        --     this.StopRandomizationTemp(newRef)
        -- end
    end
    if itemLib.isObjectFixRequired() then
        timer.delayOneFrame(function() itemLib.fixCell(cell, false, true) end)
    end
end

local aiBlackList = {["chargen boat guard 1"]=true,["chargen boat guard 2"]=true,["chargen boat guard 3"]=true,["chargen captain"]=true,["chargen class"]=true,["chargen dock guard"]=true,["chargen door guard"]=true,["chargen name"]=true,}

local positiveAttrs = { "chameleon", "waterBreathing", "waterWalking", "swiftSwim", "shield"}
local negativeAttrs = { "sound", "silence" } -- "blind", "paralyze" banned
local bothAttrs = { "resistNormalWeapons", "sanctuary", "attackBonus", "resistMagicka", "resistFire", "resistFrost", "resistShock", "resistPoison", "resistParalysis" } -- "resistCommonDisease", "resistBlightDisease", "resistCorprus" banned
local combatSkillIds = {tes3.skill.block, tes3.skill.armorer,  tes3.skill.mediumArmor, tes3.skill.heavyArmor, tes3.skill.bluntWeapon, tes3.skill.longBlade, tes3.skill.axe, tes3.skill.spear, tes3.skill.athletics,}
local magicSkillIds = {tes3.skill.enchant, tes3.skill.destruction,  tes3.skill.alteration, tes3.skill.illusion, tes3.skill.conjuration, tes3.skill.mysticism, tes3.skill.restoration, tes3.skill.alchemy, tes3.skill.unarmored,}
local stealthSkillIds = {tes3.skill.security, tes3.skill.sneak,  tes3.skill.acrobatics, tes3.skill.lightArmor, tes3.skill.shortBlade, tes3.skill.marksman, tes3.skill.mercantile, tes3.skill.speechcraft, tes3.skill.handToHand,}

function this.randomizeMobileActor(mobile)
    local objectData = dataSaver.getObjectData(mobile.reference)
    local configData = this.config.data
    local configTable
    if mobile.actorType == tes3.actorType.npc then
        configTable = configData.NPCs
    elseif mobile.actorType == tes3.actorType.creature then
        configTable = configData.creatures
    end

    if configTable == nil or objectData == nil then
        return
    end

    -- Save or restore initial data
    if objectData.actorData == nil then objectData.actorData = {} end

    if objectData.actorData.skills == nil then
        objectData.actorData.skills = {}
        for i, skillVal in ipairs(mobile.skills) do
            objectData.actorData.skills[i] = skillVal.base
        end
    else
        for i, skillVal in ipairs(mobile.skills) do
            mobile.skills[i].base = objectData.actorData.skills[i]
        end
    end

    if objectData.actorData.attributes == nil then
        objectData.actorData.attributes = {}
        for i, attributeVal in ipairs(mobile.attributes) do
            objectData.actorData.attributes[i] = attributeVal.base
        end
    else
        for i, attributeVal in ipairs(mobile.attributes) do
            mobile.attributes[i].base = objectData.actorData.attributes[i]
        end
    end

    if objectData.actorData.health == nil then
        objectData.actorData.health = mobile.health.base
        objectData.actorData.magicka = mobile.magicka.base
        objectData.actorData.fatigue = mobile.fatigue.base
    else
        mobile.health.base = objectData.actorData.health
        mobile.magicka.base = objectData.actorData.magicka
        mobile.fatigue.base = objectData.actorData.fatigue
    end

    if objectData.actorData.ai == nil then
        objectData.actorData.ai = {}
        for label, data in ipairs(configTable.ai) do
            objectData.actorData.ai[label] = mobile[label]
        end
    else
        for label, data in ipairs(configTable.ai) do
            mobile[label] = objectData.actorData.ai[label]
        end
    end

    if objectData.actorData.effects == nil then
        objectData.actorData.effects = {}
        for i, effAttr in ipairs(mobile.effectAttributes) do
            objectData.actorData.effects[i] = effAttr
        end
    else
        for i, effAttr in ipairs(mobile.effectAttributes) do
            mobile.effectAttributes[i] = objectData.actorData.effects[i]
        end
    end

    local setNew = function(attribute, region, limit, useRangeVal, min)
        if limit == nil then limit = math.huge end
        local base = attribute.base
        local normalized = attribute.normalized
        local newVal = 0
        if useRangeVal then
            newVal = random.GetRandom(base, limit, region.min, region.max)
        else
            if region.additive then
                newVal = math.floor(math.min(math.max(min or 0, base + random.GetBetween(region.min, region.max)), limit))
            else
                newVal = math.floor(math.min(math.max(min or 0, base * random.GetBetween(region.min, region.max)), limit))
            end
        end
        log("%s to %s", tostring(attribute.base), tostring(newVal))
        attribute.base = newVal
        attribute.current = newVal * normalized
    end

    if configTable.health.randomize then
        log("Health %s", tostring(mobile.object))
        setNew(mobile.health, configTable.health.region)
    end
    if configTable.fatigue.randomize then
        log("Fatigue %s", tostring(mobile.object))
        setNew(mobile.fatigue, configTable.fatigue.region)
    end
    if configTable.magicka.randomize then
        log("Magicka %s", tostring(mobile.object))
        setNew(mobile.magicka, configTable.magicka.region)
    end

    if not aiBlackList[mobile.object.id] then
        for label, data in pairs(configTable.ai) do
            local newVal = random.GetRandom(mobile[label], 100, data.region.min, data.region.max)
            log("AI %s %s %s to %s", tostring(mobile.object), tostring(label), tostring(mobile[label]), tostring(newVal))
            mobile[label] = newVal
        end
    end

    local posListCount = #positiveAttrs
    local bothListCount = #bothAttrs
    local negListCount = #negativeAttrs

    local posEffectsAddCount = configTable.effects.positive.add.count
    local posEffects = {}
    local posRepeat = 50
    while posEffectsAddCount > 0 and posRepeat > 0 do
        if configTable.effects.positive.add.chance > math.random() then
            local count = posListCount + bothListCount
            local pos = math.random(1, count)
            local param
            local val = math.random(configTable.effects.positive.add.region.min, configTable.effects.positive.add.region.max)
            if pos <= posListCount then
                param = positiveAttrs[pos]
            else
                param = bothAttrs[pos - posListCount]
            end

            if param == "attackBonus" then
                val = math.ceil(val * 0.1)
            end

            if posEffects[param] == nil then
                posEffectsAddCount = posEffectsAddCount - 1
            end
            log("Positive effect %s %s %s", tostring(mobile.object), tostring(param), tostring(val))
            posEffects[param] = val
        end
        posRepeat = posRepeat - 1
    end
    local negEffectsAddCount = configTable.effects.negative.add.count
    local negEffects = {}
    local negRepeat = 50
    while negEffectsAddCount > 0 and negRepeat > 0 do
        if configTable.effects.negative.add.chance > math.random() then
            local count = negListCount + bothListCount
            local pos = math.random(1, count)
            local param
            local val = math.random(configTable.effects.negative.add.region.min, configTable.effects.negative.add.region.max)
            if pos <= negListCount then
                param = negativeAttrs[pos]
            else
                param = bothAttrs[pos - negListCount]
                val = -val
            end

            if param == "attackBonus" then
                val = math.floor(val * 0.1)
            end

            if negEffects[param] == nil then
                negEffectsAddCount = negEffectsAddCount - 1
            end
            log("Negative effect %s %s %s", tostring(mobile.object), tostring(param), tostring(val))
            negEffects[param] = val
        end
        negRepeat = negRepeat - 1
    end

    for param, val in pairs(posEffects) do
        mobile[param] = mobile[param] + val
    end

    for param, val in pairs(negEffects) do
        mobile[param] = mobile[param] + val
    end

    local object = mobile.object
    local baseObject = object.baseObject
    for skillId, skillVal in ipairs(baseObject.skills) do
        if skillVal ~= mobile.skills[skillId].base then
            local diff = mobile.skills[skillId].current - mobile.skills[skillId].base
            mobile.skills[skillId].base = skillVal
            mobile.skills[skillId].current = math.max(0, skillVal + diff)
        end
    end

    if object.objectType == tes3.objectType.npc then
        for id, val in ipairs(baseObject.attributes) do
            if val ~= mobile.attributes[id].base then
                local diff = mobile.attributes[id].current - mobile.attributes[id].base
                mobile.attributes[id].base = val
                mobile.attributes[id].current = math.max(1, val + diff)
            end
        end
    end

    mobile.reference.modified = true
    mobile:updateDerivedStatistics()
    mobile:updateOpacity()
end

---@deprecated
function this.restoreAllBaseActorData()
    local playerData = dataSaver.getObjectData(tes3.player)
    if not playerData then return end
    if playerData.randomizedBaseObjects ~= nil then
        local foundData = false
        local dt = playerData.randomizedBaseObjects
        for id, objData in pairs(dt) do
            local object = tes3.getObject(id)
            if object then
                foundData = true
                this.storage.addActorData(id, objData, false)
                this.storage.restoreActor(object, false)
            end
        end
        local cells = tes3.getActiveCells()
        if foundData and cells ~= nil then
            for _, cell in pairs(cells) do
                for ref in cell:iterateReferences({ tes3.objectType.npc }) do
                    ref:updateEquipment()
                end
            end
        end
        playerData.randomizedBaseObjects = nil
    end
end

local lastBaseRandTimestamp = {}
function this.randomizeActorBaseObject(object, actorType)
    if not object then return end
    -- to prevent multiple randomization
    if lastBaseRandTimestamp[object.id] and lastBaseRandTimestamp[object.id] > os.time() then
        return
    else
        lastBaseRandTimestamp[object.id] = os.time() + 2
    end

    local configData = this.config.data
    local configTable
    if object.actorType == tes3.actorType.npc or actorType == tes3.actorType.npc then
        configTable = configData.NPCs
    elseif object.actorType == tes3.actorType.creature or actorType == tes3.actorType.creature then
        configTable = configData.creatures
    end

    if configTable == nil then
        return
    end

    this.storage.saveOrRestoreInitialActor(object)

    -- object.modified = true

    if configTable.attack ~= nil and configTable.attack.randomize and object.attacks ~= nil then
        log("Attack bonus %s", tostring(object))
        for i, val in ipairs(object.attacks) do
            local min = configTable.attack.region.additive and val.min + random.GetBetween(configTable.attack.region.min, configTable.attack.region.max) or
                val.min * math.abs(random.GetBetween(configTable.attack.region.min, configTable.attack.region.max))
            local max = configTable.attack.region.additive and val.max + random.GetBetween(configTable.attack.region.min, configTable.attack.region.max) or
                val.max * math.abs(random.GetBetween(configTable.attack.region.min, configTable.attack.region.max))
            if min > max then max = min end
            log("min %s to %s max %s to %s", tostring(val.min), tostring(min), tostring(val.max), tostring(max))
            val.min = min
            val.max = max
        end
    end

    local tesAI = object.aiConfig

    if tesAI.travelDestinations ~= nil and configData.transport.randomize then
        local arrWithPos = {}
        local destCount = #tesAI.travelDestinations
        for i = 1, destCount do
            table.insert(arrWithPos, i)
        end
        for i = 1, destCount do
            local rnd = math.random(1, destCount)
            arrWithPos[i], arrWithPos[rnd] = arrWithPos[rnd], arrWithPos[i]
        end

        local toDoors = configData.transport.toDoorsCount
        local toRandomPoint = configData.transport.toRandomPointCount
        for i, pos in ipairs(arrWithPos) do

            if i > configData.transport.unrandomizedCount then

                local destination = tesAI.travelDestinations[arrWithPos[pos]]
                if toDoors > 0 then
                    toDoors = toDoors - 1
                    local door = this.doors.doorsData.All[math.random(1, #this.doors.doorsData.All)]
                    if door ~= nil then
                        destination.cell = door.destination.cell
                        destination.marker = door.destination.marker
                    end

                elseif toRandomPoint > 0 then -- TODO
                    toRandomPoint = toRandomPoint - 1
                    local x = math.random(-20000, 20000)
                    local y = math.random(-20000, 20000)
                    destination.cell = tes3.getCell{ x = math.floor(x / 8192), y = math.floor(y / 8192)}
                    destination.marker.position = tes3vector3.new(x, y, 4000)
                    destination.marker.orientation = tes3vector3.new(0, 0, 0)

                else
                    local newDest = travelDestinationsData[math.random(1, #travelDestinationsData)]
                    destination.cell = newDest.cell
                    destination.marker.position = tes3vector3.new(newDest.marker.position.x, newDest.marker.position.y, newDest.marker.position.z)
                    destination.marker.orientation = tes3vector3.new(newDest.marker.orientation.x, newDest.marker.orientation.y, newDest.marker.orientation.z)
                end

                log("Travel destination %s %s %s (%s, %s, %s)", tostring(object), tostring(pos), tostring(destination.cell),
                    tostring(destination.marker.position.x), tostring(destination.marker.position.y), tostring(destination.marker.position.z))
            end
        end
    end

    local setNew = function(attribute, region, limit, useRangeVal, min)
        if limit == nil then limit = math.huge end
        local base = attribute
        local newVal = 0
        if useRangeVal then
            newVal = random.GetRandom(base, limit, region.min, region.max)
        else
            if region.additive then
                newVal = math.floor(math.min(math.max(min or 0, base + random.GetBetween(region.min, region.max)), limit))
            else
                newVal = math.floor(math.min(math.max(min or 0, base * random.GetBetween(region.min, region.max)), limit))
            end
        end
        log("%s to %s", tostring(attribute), tostring(newVal))
        return newVal
    end

    if object.objectType == tes3.objectType.npc then
        if configTable.attributes.randomize then
            log("Attributes %s", tostring(object))
            for id, attributeVal in ipairs(object.attributes) do
                local limit = math.max(attributeVal, configTable.attributes.limit)
                object.attributes[id] = setNew(attributeVal, configTable.attributes.region, limit, nil, 1)
            end
        end
    end

    if configTable.skills.randomize then
        if object.objectType == tes3.objectType.npc then
            log("Combat skills %s", tostring(object))
            for _, skillId in pairs(combatSkillIds) do
                object.skills[skillId + 1] = setNew(object.skills[skillId + 1], configTable.skills.combat.region, configTable.skills.limit, true)
            end
            log("Magic skills %s", tostring(object))
            for _, skillId in pairs(magicSkillIds) do
                object.skills[skillId + 1] = setNew(object.skills[skillId + 1], configTable.skills.magic.region, configTable.skills.limit, true)
            end
            log("Stealth skills %s", tostring(object))
            for _, skillId in pairs(stealthSkillIds) do
                object.skills[skillId + 1] = setNew(object.skills[skillId + 1], configTable.skills.stealth.region, configTable.skills.limit, true)
            end
        elseif object.objectType == tes3.objectType.creature then
            log("Skills %s", tostring(object))
            object.skills[tes3.specialization.combat + 1] = setNew(object.skills[tes3.specialization.combat + 1], configTable.skills.combat.region, configTable.skills.limit, true)
            object.skills[tes3.specialization.magic + 1] = setNew(object.skills[tes3.specialization.magic + 1], configTable.skills.magic.region, configTable.skills.limit, true)
            object.skills[tes3.specialization.stealth + 1] = setNew(object.skills[tes3.specialization.stealth + 1], configTable.skills.stealth.region, configTable.skills.limit, true)
        end
    end

    local spellList = object.spells
    local newSpells = {}
    local configGroupByType = {"spells", "abilities", "diseases", "diseases"}
    for i, spell in pairs(spellList) do
        local spellId = spell.id:lower()
        local spellData = spellsData.Spells[spellId]
        local spellType = spell.castType
        if spellData ~= nil then
            if (spellType == tes3.spellType.spell and configTable.spells.randomize) or
                    (spellType == tes3.spellType.ability and configTable.abilities.randomize) or
                    ((spellType == tes3.spellType.blight or spellType == tes3.spellType.disease) and configTable.diseases.randomize) then
                local spellEffectData = spellData[math.random(1, #spellData)]
                local spellGroup = spellsData.SpellGroups[tostring(spellEffectData.SubType)]
                local pos = random.GetRandom(spellEffectData.Position, spellGroup.Count,
                    configTable[configGroupByType[spellType + 1]].region.min, configTable[configGroupByType[spellType + 1]].region.max)
                local i = 20
                while i > 0 and newSpells[spellGroup.Items[pos]] ~= nil do
                    i = i - 1
                    pos = random.GetRandom(spellEffectData.Position, spellGroup.Count,
                        configTable[configGroupByType[spellType + 1]].region.min, configTable[configGroupByType[spellType + 1]].region.max)
                end
                newSpells[spellGroup.Items[pos]] = true
                spellList:remove(spell)
            end
        end
    end

    local spellsAddCount = configTable.spells.add.count
    for i = 1, spellsAddCount do
        if configTable.spells.add.chance > math.random() then
            local skillSchoolId = 10
            if configTable.spells.add.bySkill then
                local skillValue = {}
                for j = 10, 15 do
                    table.insert(skillValue, {id = j, value = object.skills[j + 1]})
                end
                table.sort(skillValue, function(a, b) return a.value > b.value end)
                skillSchoolId = skillValue[math.random(1, math.min(6, configTable.spells.add.bySkillMax))].id
            else
                skillSchoolId = math.random(10, 15)
            end
            local newSpellGroup = spellsData.SpellGroups[tostring(skillSchoolId)]
            local pos = random.GetRandom(math.floor(math.min(newSpellGroup.Count * (object.level / configTable.spells.add.levelReference), newSpellGroup.Count)),
                newSpellGroup.Count, configTable.spells.region.min, configTable.spells.region.max)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = random.GetRandom(math.floor(math.min(newSpellGroup.Count * (object.level / configTable.spells.add.levelReference), newSpellGroup.Count)),
                    newSpellGroup.Count, configTable.spells.region.min, configTable.spells.region.max)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    local abilitiesAddCount = configTable.abilities.add.count
    for i = 1, abilitiesAddCount do
        if configTable.abilities.add.chance > math.random() then
            local newSpellGroup = spellsData.SpellGroups["200"]
            local pos = math.random(1, newSpellGroup.Count)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = math.random(1, newSpellGroup.Count)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    local diseasesAddCount = configTable.diseases.add.count
    for i = 1, diseasesAddCount do
        if configTable.diseases.add.chance > math.random() then
            local newSpellGroup = spellsData.SpellGroups["201"]
            local pos = math.random(1, newSpellGroup.Count)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = math.random(1, newSpellGroup.Count)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    for spell, _ in pairs(newSpells) do
        log("New spell %s %s", tostring(object), tostring(spell))
        spellList:add(spell)
    end

    if configData.barterGold.randomize and object.barterGold ~= nil then
        local newVal = math.floor(configData.barterGold.region.additive and
            object.barterGold + random.GetBetween(configData.barterGold.region.min, configData.barterGold.region.max) or
            object.barterGold * random.GetBetween(configData.barterGold.region.min, configData.barterGold.region.max))
        if newVal < 0 then newVal = 0 end
        log("Barter gold %s %s to %s", tostring(object), tostring(object.barterGold), tostring(newVal))
        object.barterGold = newVal
    end

    this.randomizeBody(object)

    this.storage.saveActor(object)
end

local races = {}
for race, val in pairs(headPartsData.Parts) do
    table.insert(races, race)
end

function this.randomizeBody(object)
    local configData = this.config.data
    if object.objectType == tes3.objectType.npc then
        local race = object.race.id:lower()
        if configData.NPCs.hair.randomize and headPartsData.List["1"][object.hair.id:lower()] and headPartsData.Parts[race] ~= nil then
            local newRace = race
            local genderId = object.female and 1 or 0
            if not configData.NPCs.hair.raceLimit then
                local newRaceId = math.random(1, #races)
                newRace = races[newRaceId]
            end
            if not configData.NPCs.hair.genderLimit then
                genderId = math.random(0, 1)
            end

            local hairList = headPartsData.Parts[newRace]["1"][tostring(genderId)]
            local hairId = hairList[math.random(1, #hairList)]
            log("Hair %s %s to %s", tostring(object), tostring(object.hair.id), tostring(hairId))
            object.hair = tes3.getObject(hairId)
        end
        if configData.NPCs.head.randomize and headPartsData.List["0"][object.head.id:lower()] and headPartsData.Parts[race] ~= nil then
            local newRace = race
            local genderId = object.female and 1 or 0
            if not configData.NPCs.head.raceLimit then
                local newRaceId = math.random(1, #races)
                newRace = races[newRaceId]
            end
            if not configData.NPCs.head.genderLimit then
                genderId = math.random(0, 1)
            end

            local headList = headPartsData.Parts[newRace]["0"][tostring(genderId)]
            local headId = headList[math.random(1, #headList)]
            log("Hair %s %s to %s", tostring(object), tostring(object.head.id), tostring(headId))
            object.head = tes3.getObject(headId)
        end
    end
end

function this.randomizeScale(reference)
    local configData
    if reference.mobile.actorType == tes3.actorType.npc then
        configData = this.config.data.NPCs
    elseif reference.mobile.actorType == tes3.actorType.creature then
        configData = this.config.data.creatures
    end

    if configData ~= nil then
        if configData.scale.randomize then
            local newVal = configData.scale.region.additive and reference.object.scale + random.GetBetween(configData.scale.region.min, configData.scale.region.max) or
                reference.object.scale * random.GetBetween(configData.scale.region.min, configData.scale.region.max)
            if newVal <= 0 then newVal = 1 end
            log("Scale %s %s to %s", tostring(reference), tostring(reference.scale), tostring(newVal))
            reference.scale = newVal
        end
    end
end

function this.randomizeWeatherChance(cell)
    if this.config.data.weather.randomize and cell ~= nil and cell.region ~= nil then
        local weatherChances = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        for i = 1, 10 do
            local pos = math.random(1, 10)
            weatherChances[pos] = weatherChances[pos] + 10
        end
        cell.region.weatherChanceAsh = weatherChances[1]
        cell.region.weatherChanceBlight = weatherChances[2]
        cell.region.weatherChanceBlizzard = weatherChances[3]
        cell.region.weatherChanceClear = weatherChances[4]
        cell.region.weatherChanceCloudy = weatherChances[5]
        cell.region.weatherChanceFoggy = weatherChances[6]
        cell.region.weatherChanceOvercast = weatherChances[7]
        cell.region.weatherChanceRain = weatherChances[8]
        cell.region.weatherChanceSnow = weatherChances[9]
        cell.region.weatherChanceThunder = weatherChances[10]
    end
end

local function saveLockTrapInitialState(reference)
    local data = dataSaver.getObjectData(reference)
    if data and not data.lockNode and reference.lockNode then
        data.lockNode = {
            level = reference.lockNode.level,
            locked = reference.lockNode.locked,
        }
        if reference.lockNode.trap and reference.lockNode.trap.id then
            data.lockNode.trapId = reference.lockNode.trap.id
        end
    end
end

local function getLockTrapCDTimestamp(data)
    return data.lockTrapCDTimestamp or 0
end

local function setLockTrapCDTimestamp(data, value)
    data.lockTrapCDTimestamp = value
end

function this.resetLockTrapToDefault(reference)
    local data = dataSaver.getObjectData(reference)
    if data and data.lockNode and (getLockTrapCDTimestamp(data) < tes3.getSimulationTimestamp() or this.config.data.enabled == false) then
        log("LockTrap to default %s", tostring(reference))
        if data.lockNode.level ~= reference.lockNode.level then
            tes3.setLockLevel{ reference = reference, level = data.lockNode.level }
        end
        if data.lockNode.locked ~= reference.lockNode.locked then
            reference.lockNode.locked = data.lockNode.locked
        end
        if reference.lockNode.trap and data.lockNode.trapId and reference.lockNode.trap.id ~= data.lockNode.trapId then
            tes3.setTrap{ reference = reference, spell = data.lockNode.trapId }
        end
    end
end

function this.randomizeLockTrap(reference, toLock, toTrap)
    local configTable
    if reference.baseObject.objectType == tes3.objectType.door then
        if this.doors.forbiddenDoorIds[reference.baseObject.id:lower()] then
            return
        end
        configTable = this.config.data.doors
    elseif reference.baseObject.objectType == tes3.objectType.container then
        configTable = this.config.data.containers
    end
    local data = dataSaver.getObjectData(reference)
    if configTable and data and getLockTrapCDTimestamp(data) < tes3.getSimulationTimestamp() then
        saveLockTrapInitialState(reference)
        this.resetLockTrapToDefault(reference)
        setLockTrapCDTimestamp(data, tes3.getSimulationTimestamp() + configTable.lockTrapCooldown)

        if toLock ~= false and reference.lockNode ~= nil and configTable.lock.randomize and reference.lockNode.level > 0 then
            local newLevel = random.GetRandom(reference.lockNode.level, 100, configTable.lock.region.min, configTable.lock.region.max)

            log("Lock level %s %s to %s", tostring(reference), tostring(reference.lockNode.level), tostring(newLevel))
            tes3.setLockLevel{ reference = reference, level = newLevel }
        end
        if toLock ~= false and (reference.lockNode == nil or reference.lockNode.level == 0) and configTable.lock.add.chance > math.random() then
            local newLevel = math.random(1, math.min(100, configTable.lock.add.levelMultiplier * tes3.player.object.level))

            log("Lock level new %s %s", tostring(reference), tostring(newLevel))
            tes3.setLockLevel{ reference = reference, level = newLevel }
            reference.lockNode.locked = true
        end
        if toTrap ~= false and reference.lockNode ~= nil and configTable.trap.randomize and reference.lockNode.trap ~= nil and reference.lockNode.trap.id ~= nil then
            local trapEffData = spellsData.TouchRange[reference.lockNode.trap.id:lower()]
            if trapEffData ~= nil and #trapEffData > 0 then
                local trapData = trapEffData[math.random(1, #trapEffData)]
                local trapGroup = spellsData.SpellGroups[tostring(trapData.SubType)]
                if trapGroup ~= nil then
                    local newTrapSpellId
                    local newTrapSpell
                    local limit = 20
                    while not newTrapSpell and limit > 0 do
                        limit = limit - 1
                        newTrapSpellId = random.GetRandom(trapData.Position, trapGroup.Count, configTable.trap.region.min, configTable.trap.region.max)
                        newTrapSpell = tes3.getObject(trapGroup.Items[newTrapSpellId])
                        if newTrapSpell.effects then
                            for _, effect in pairs(newTrapSpell.effects) do
                                if effect.object and effect.object.casterLinked then
                                    newTrapSpell = nil
                                    break
                                end
                            end
                            break
                        end
                        newTrapSpell = nil
                    end
                    if newTrapSpell ~= nil then
                        log("Trap %s %s to %s", tostring(reference), tostring(reference.lockNode.trap), tostring(newTrapSpell))
                        reference.lockNode.trap = newTrapSpell
                    end
                end
            end
        end
        if toTrap ~= false and (reference.lockNode == nil or reference.lockNode.trap == nil) and configTable.trap.add.chance > math.random() then
            local newGroup
            if configTable.trap.add.onlyDestructionSchool then
                newGroup = spellsData.SpellGroups["110"]
            else
                newGroup = spellsData.SpellGroups[tostring(math.random(110, 115))]
            end
            local newTrapSpellId
            local newTrapSpell
            local limit = 20
            while not newTrapSpell and limit > 0 do
                limit = limit - 1
                newTrapSpellId = math.random(1, math.floor(math.min(newGroup.Count,
                newGroup.Count * configTable.trap.add.levelMultiplier * tes3.player.object.level * 0.01)))
                newTrapSpell = tes3.getObject(newGroup.Items[newTrapSpellId])
                if newTrapSpell.effects then
                    for _, effect in pairs(newTrapSpell.effects) do
                        if effect.object and effect.object.casterLinked then
                            newTrapSpell = nil
                            break
                        end
                    end
                    break
                end
                newTrapSpell = nil
            end
            if newTrapSpell then
                log("Trap new %s %s", tostring(reference), tostring(newTrapSpell.id))
                tes3.setTrap({ reference = reference, spell = newTrapSpell })
            end
        end
    end
end

return this