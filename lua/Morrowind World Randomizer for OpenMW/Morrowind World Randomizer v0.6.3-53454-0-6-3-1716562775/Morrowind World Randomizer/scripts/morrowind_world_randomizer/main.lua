local log = require("scripts.morrowind_world_randomizer.utils.log")

local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local localConfig = require("scripts.morrowind_world_randomizer.config.local")
local localStorage = require("scripts.morrowind_world_randomizer.storage.local")
local globalStorage = require("scripts.morrowind_world_randomizer.storage.global")

local random = require("scripts.morrowind_world_randomizer.utils.random")
local advString = require("scripts.morrowind_world_randomizer.utils.string")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local async = require('openmw.async')
local types = require('openmw.types')
local world = require("openmw.world")
local util = require("openmw.util")
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local Activation = require('openmw.interfaces').Activation

local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local cellLib = require("scripts.morrowind_world_randomizer.cell")

local profiles = require("scripts.morrowind_world_randomizer.storage.profiles")

local itemGenerator = require("scripts.morrowind_world_randomizer.generator.newItems")

local function isReadyForRandomization(ref, once)
    local tm = localStorage.getRefRandomizationTimestamp(ref)
    if tm and once then
        return false
    elseif tm and (localConfig.data.randomizeOnce or (tm + localConfig.data.randomizeAfter * 3600 > world.getGameTime())) then
        return false
    end
    return true
end

local function createItem(id, oldItem, advData, skipOwner)
    local new = world.createObject(id, advData.count or oldItem.count)
    if not skipOwner then
        local newOwner = new.owner
        local oldOwner = oldItem.owner
        newOwner.factionId = oldOwner.factionId
        newOwner.factionRank = oldOwner.factionRank
        newOwner.recordId = oldOwner.fecordId
    end
    return new
end

local function rebuildStorageData()
    local step = 0
    local statics = require("scripts.morrowind_world_randomizer.generator.statics")
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.treesData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.TreesData_TR"))
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.rocksData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.RocksData_TR"))
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        local itemSafeMode = storage.globalSection(globalStorage.storageName):get("itemSafeMode")
        globalStorage.data.itemsData = require("scripts.morrowind_world_randomizer.generator.items").generateData(itemSafeMode)
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.floraData = statics.generateFloraData()
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.herbsData = require("scripts.morrowind_world_randomizer.generator.containers").generateHerbData()
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        local creatureSafeMode = storage.globalSection(globalStorage.storageName):get("creatureSafeMode")
        globalStorage.data.creaturesData = require("scripts.morrowind_world_randomizer.generator.creatures").generateCreatureData(creatureSafeMode)
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.spellsData = require("scripts.morrowind_world_randomizer.generator.spells").generateSpellData()
        step = step + 1
    end)
    async:newUnsavableSimulationTimer(0.1, function()
        globalStorage.data.lightsData = require("scripts.morrowind_world_randomizer.generator.lights").generateData()
        step = step + 1
    end)
    local timer
    timer = time.runRepeatedly(function()
        if step >= 8 then
            globalStorage.data.version = globalStorage.version
            globalStorage.saveGameFilesDataToStorage()
            globalStorage.save()
            cellLib.init(globalStorage.data, localConfig, localStorage)
            itemGenerator.init(globalStorage.data, localConfig.data)
            timer()
        end
    end, 1 * time.second, {})
end

local function initData()
    if globalStorage.init() then
        rebuildStorageData()
    end
    cellLib.init(globalStorage.data, localConfig, localStorage)
    itemGenerator.init(globalStorage.data, localConfig.data)
end

-- fixes for created creatures
local function killParentCreature(parentData)
    if not parentData then return end
    local cellData = parentData.cellData
    local parentId = parentData.parentId
    local cell = cellData.isExterior and world.getExteriorCell(cellData.gridX, cellData.gridY) or
        world.getCellByName(cellData.name)
    if not cell then return end
    for _, ref in pairs(cell:getAll(types.Creature)) do
        if ref.id == parentId then
            if types.Actor.stats.dynamic.health(ref).current > 0 then
                ref.enabled = true
                ref:addScript("scripts/morrowind_world_randomizer/local/killNewCreature.lua")
                localStorage.saveObjectScale(ref.id, 0.0001)
                ref:setScale(0.0001)
                log("Parent actor killed", ref)
                return true
            end
            break
        end
    end
end

local function deleteParentCreature(parentData)
    if parentData then
        local cellData = parentData.cellData
        local parentId = parentData.parentId
        local cell = cellData.isExterior and world.getExteriorCell(cellData.gridX, cellData.gridY) or
            world.getCellByName(cellData.name)
        if not cell then return end
        for _, ref in pairs(cell:getAll(types.Creature)) do
            if ref.id == parentId then
                log("Parent actor removed", ref)
                ref:remove()
                return true
            end
        end
    end
    return nil
end

local cellsForCreatureCheck = {}
local creaCheckTimer = time.runRepeatedly(function()
    for cell, _ in pairs(cellsForCreatureCheck) do
        for _, actor in pairs(cell:getAll(types.Creature)) do
            if localStorage.isIdInDeletionList(actor.id) then
                localStorage.removeIdFromDeletionList(actor.id)
                log("Parent actor removed", actor)
                actor:remove()
            end
        end
        cellsForCreatureCheck[cell] = nil
    end
end, 1 * time.second, { initialDelay = math.random() * 5 * time.second })

local creaturesForHealthCheck = {}
time.runRepeatedly(function()
    for id, reference in pairs(creaturesForHealthCheck) do
        if reference and reference:isValid() and types.Actor.stats.dynamic.health(reference).current == 0 then
            local parentData = localStorage.getCreatureParentData(reference.id)
            if killParentCreature(parentData) then
                creaturesForHealthCheck[id] = nil
            end
        end
    end
end, 1 * time.second, { initialDelay = math.random() * time.second })
--

local function onActorActive(actor)
    if not localConfig.data.enabled then return end
    if localConfig.data.creature.killParent then
        local actorParentId = localStorage.getCreatureParentData(actor.id)
        if actorParentId and not creaturesForHealthCheck[actor.id] then
            creaturesForHealthCheck[actor.id] = actor
        end
    end
    cellsForCreatureCheck[actor.cell] = true
    async:newUnsavableSimulationTimer(0.2, function()
        if not actor or not actor:isValid() then return end
        local actorSavedData = localStorage.saveActorData(actor)
        if not actorSavedData then return end
        local config = localConfig.getConfigTableByObjectType(actor.type)
        if not config then return end
        local firstRandomization = isReadyForRandomization(actor, true)
        local isAlive = types.Actor.stats.dynamic.health(actor).current > 0

        if firstRandomization then
            if actor.type == types.Creature and config.randomize and (not config.onlyLeveled or not actor.contentFile) and
                    globalStorage.data.creaturesData.objects[actor.recordId] and isAlive then
                local actorData = globalStorage.data.creaturesData.objects[actor.recordId]
                local group
                if config.byType then
                    group = globalStorage.data.creaturesData.groups[actorData.type]
                else
                    group = {}
                    for _, grp in pairs(globalStorage.data.creaturesData.groups) do
                        tableLib.addTableValuesToTable(group, grp)
                    end
                end
                local newActor = group[random.getRandom(actorData.pos, #group, config.rregion.min, config.rregion.max)]
                local new = world.createObject(newActor)
                localStorage.setRefRandomizationTimestamp(new)
                if config.item.randomize then new:sendEvent("mwr_actor_randomizeInventory", {itemsData = globalStorage.data.itemsData, config = config}) end
                log("new creature", new, "old", actor)
                new:teleport(actor.cell, actor.position, {onGround = true, rotation = actor.rotation})
                localStorage.setCreatureParentData(new, actor)
                if localConfig.data.creature.killParent then
                    creaturesForHealthCheck[new.id] = new
                end
                actor.enabled = false
            end
        end

        if firstRandomization or (isAlive and isReadyForRandomization(actor)) then
            if config.item.randomize then
                localStorage.setRefRandomizationTimestamp(actor)
                actor:sendEvent("mwr_actor_randomizeInventory", {itemsData = globalStorage.data.itemsData, config = config})
            end

            if config.stat.dynamic.randomize and isAlive then
                local health = actorSavedData.health
                local magicka = actorSavedData.magicka
                local fatigue = actorSavedData.fatigue
                if config.stat.dynamic.additive then
                    health = math.max(1, health + random.getBetween(config.stat.dynamic.health.vregion.min, config.stat.dynamic.health.vregion.max))
                    magicka = math.max(1, magicka + random.getBetween(config.stat.dynamic.magicka.vregion.min, config.stat.dynamic.magicka.vregion.max))
                    fatigue = math.max(1, fatigue + random.getBetween(config.stat.dynamic.fatigue.vregion.min, config.stat.dynamic.fatigue.vregion.max))
                else
                    health = math.max(1, health * random.getBetween(config.stat.dynamic.health.vregion.min, config.stat.dynamic.health.vregion.max))
                    magicka = math.max(1, magicka * random.getBetween(config.stat.dynamic.magicka.vregion.min, config.stat.dynamic.magicka.vregion.max))
                    fatigue = math.max(1, fatigue * random.getBetween(config.stat.dynamic.fatigue.vregion.min, config.stat.dynamic.fatigue.vregion.max))
                end
                actor:sendEvent("mwr_actor_setDynamicBaseStats", {health = health, magicka = magicka, fatigue = fatigue})
            end

            if config.stat.attributes and config.stat.attributes.randomize then
                local attributes = actorSavedData.attributes
                local attrConfig = config.stat.attributes
                local getVal = function(val)
                    if attrConfig.additive then
                        return math.floor(math.max(0, math.min(attrConfig.limit, val + random.getBetween(attrConfig.vregion.min, attrConfig.vregion.max))))
                    else
                        return math.floor(math.max(0, math.min(attrConfig.limit, val * random.getBetween(attrConfig.vregion.min, attrConfig.vregion.max))))
                    end
                end
                local data = {}
                data.agility = getVal(attributes.agility)
                data.endurance = getVal(attributes.endurance)
                data.intelligence = getVal(attributes.intelligence)
                data.luck = getVal(attributes.luck)
                data.personality = getVal(attributes.personality)
                data.speed = getVal(attributes.speed)
                data.strength = getVal(attributes.strength)
                data.willpower = getVal(attributes.willpower)
                actor:sendEvent("mwr_actor_setAttributeBase", data)
            end

            if config.stat.skills and config.stat.skills.randomize then
                actor:sendEvent("mwr_actor_randomizeSkillBaseValues", {config = config, actorData = actorSavedData})
            end

            if config.spell then
                async:newUnsavableSimulationTimer(0.2, function()
                    actor:sendEvent("mwr_actor_randomizeSpells", {config = config, spellsData = globalStorage.data.spellsData, actorData = actorSavedData})
                end)
            end
        end
    end)
end

local cellsToRandomize = {}
local cellListUpdated = false

local function onObjectActive(object)
    local objectScale = localStorage.getObjectScale(object.id)
    if objectScale then
        object:setScale(objectScale)
    end
    if not localConfig.data.enabled then return end
    cellsToRandomize[object.cell] = os.time()
    cellListUpdated = true
end

local function onInit()
    math.randomseed(os.time())
    initData()
end

local function onSave()
    localConfig.data.version = localConfig.default.version ---@diagnostic disable-line: inject-field
    return {config = localConfig.data, storage = localStorage.data}
end

local function updateSettings()
    async:newUnsavableSimulationTimer(0.5, function()
        if #world.players > 0 then
            world.players[1]:sendEvent("mwrbd_updateSettings", {configData = localConfig.data})
            world.players[1]:sendEvent("mwrbd_updateProfiles", {profileNames = profiles.getProfileNames(), protectedNames = profiles.protectedNames})
        else
            updateSettings()
        end
    end)
end

local function onLoad(data)
    math.randomseed(os.time())
    localConfig.loadData(data.config)
    updateSettings()
    localStorage.loadData(data.storage)
    if localStorage.getDeletionListCount() == 0 and not localStorage.hasCreatureOldParentData() then -- removes a part from the old version
        creaCheckTimer()
    end
    if not globalStorage.data then
        initData()
    end
    cellLib.init(globalStorage.data, localConfig, localStorage)
end

local function onNewGame()
    updateSettings()
end

local function onActivate(object, actor)
    if not localConfig.data.enabled then return end
    if localConfig.data.doNot.activatedContainers and object.type == types.Container and not types.Lockable.isLocked(object) then
        localStorage.setRefRandomizationTimestamp(object, 999999999)
    end

    if localConfig.data.other.restockFix.enabled and object.type.baseType and object.type.baseType == types.Actor and
            types.Actor.stats.dynamic.health(object).current > 0 and object.contentFile and types.Actor.getStance(object) == types.Actor.STANCE.Nothing then

        local inventory = types.Actor.inventory(object)

        if not localStorage.data.other.lastItems[object.id] then
            localStorage.data.other.lastItems[object.id] = {}
            local lastItems = localStorage.data.other.lastItems[object.id]
            local itemData = {}
            for _, item in pairs(inventory:getAll()) do
                if globalStorage.data.itemsData.items[item.recordId] and (item.type == types.Book or item.type == types.Potion or item.type == types.Repair or
                        item.type == types.Probe or item.type == types.Lockpick or item.type == types.Ingredient) then
                    table.insert(itemData, {id = item.recordId, count = item.count})
                end
            end
            local count = random.getIntBetween(localConfig.data.other.restockFix.iregion.min, localConfig.data.other.restockFix.iregion.max)
            while count > 0 and #itemData > 0 do
                local pos = math.random(#itemData)
                local itData = itemData[pos]
                lastItems[itData.id] = {count = itData.count}
                table.remove(itemData, pos)
                count = count - 1
            end
        else
            local items = tableLib.deepcopy(localStorage.data.other.lastItems[object.id])

            for id, data in pairs(items) do
                local count = data.count
                for _, item in pairs(inventory:findAll(id)) do
                    count = count - item.count
                end
                if count <= 0 then
                    items[id] = nil
                else
                    data.count = count
                end
            end
            for id, data in pairs(items) do
                local newItem = world.createObject(id, data.count)
                newItem:moveInto(inventory)
            end
        end
    end
end

local function onPlayerAdded(player)

end

local function mwr_updateInventory(data)
    local config = localConfig.getConfigTableByObjectType(data.objectType)
    if config then
        local equipment = (data.objectType == objectType.npc or data.objectType == objectType.creature) and types.Actor.getEquipment(data.object) or {}
        local restockData
        if localConfig.data.other.restockFix.enabled and localStorage.data.other.lastItems[data.object.id] then
            restockData = localStorage.data.other.lastItems[data.object.id]
        else
            restockData = {}
        end
        for _, itemData in pairs(data.items) do
            if itemData.item.count == 0 then goto continue end
            ---@type mwr.itemPosData
            local advData = itemData.advData or globalStorage.data.itemsData.items[itemData.item.recordId]
            if not advData then goto continue end
            local isArtifact = generatorData.obtainableArtifacts[itemData.item.recordId]
            local newId
            local newData
            if isArtifact and localConfig.data.item.artifactsAsSeparate then
                if not localStorage.data.other.artifacts or #localStorage.data.other.artifacts == 0 then
                    localStorage.data.other.artifacts = {}
                    for id, _ in pairs(generatorData.obtainableArtifacts) do
                        table.insert(localStorage.data.other.artifacts, id)
                    end
                end
                local pos = math.random(1, #localStorage.data.other.artifacts)
                newId = localStorage.data.other.artifacts[pos]
                table.remove(localStorage.data.other.artifacts, pos)
            else
                if localConfig.data.item.safeMode and advData.count and localConfig.data.item.safeModeThreshold > advData.count then
                    goto continue
                end
                local grp = globalStorage.data.itemsData.groups[advData.type][advData.subType]
                newId = grp[random.getRandom(advData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
                newData = globalStorage.data.itemsData.items[newId]
                local i = 10
                while (data.objectType == objectType.npc or data.objectType == objectType.creature) and
                        i > 0 and newData and newData.isDangerous do
                    newId = grp[random.getRandom(advData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
                    newData = globalStorage.data.itemsData.items[newId]
                    i = i - 1
                end
                if i == 0 then goto continue end
            end
            if not isArtifact and math.random() < localConfig.data.item.new.chance * 0.01 then
                newId = itemGenerator.new(newId, itemData.item.type) or newId
            end
            if not itemData.item.type.record(newId) then goto continue end
            local newItem = createItem(newId, itemData.item, itemData, data.objectType == objectType.creature)
            log("object ", data.object, "new item ", newItem, "old item ", itemData.item, "count ", newItem.count)
            localStorage.setRefRandomizationTimestamp(newItem)
            local inventory = (data.objectType == objectType.npc or data.objectType == objectType.creature) and
                types.Actor.inventory(data.object) or types.Container.content(data.object)
            newItem:moveInto(inventory)
            local restockItem = restockData[itemData.item.recordId]
            if restockItem then
                restockData[newId] = {count = restockItem.count}
                restockData[itemData.item.recordId] = nil
            end
            localStorage.removeObjectData(itemData.item)
            itemData.item:remove()
            if itemData.slot then
                equipment[itemData.slot] = newItem
            end
            ::continue::
        end
        if data.objectType == objectType.npc or data.objectType == objectType.creature then
            data.object:sendEvent("mwr_actor_setEquipment", equipment)
        end
    end
end

local function mwr_moveToPoint(data)
    if not data.params or not data.params.object then return end
    local object = data.params.object
    object:teleport(data.params.cell, data.res or data.params.pos, {onGround = data.res and false or true, rotation = data.params.rotation})
end

local function mwr_deactivateObject(data)
    local object = data.object
    local parentId = localStorage.getCreatureParentId(object.id)
    if parentId then
        local parentData = localStorage.getCreatureParentData(object.id)
        if parentData then
            if deleteParentCreature(parentData) then localStorage.clearCreatureParentData(object.id) end
        else
            localStorage.addIdToDeletionList(parentId)
            localStorage.clearCreatureParentData(object.id)
        end
    end
    localStorage.clearRefRandomizationTimestamp(object)
    log("Deactivated", object)
end

local function mwr_loadLocalConfigData(data)
    localConfig.loadPlayerSettings(data)
end

local updateGenSettings = false

local function mwr_updateGeneratorSettings(data)
    local global = storage.globalSection(globalStorage.storageName)
    for name, val in pairs(data) do
        globalStorage.data[name] = val
        global:set(name, val)
    end
    updateGenSettings = true
    async:newUnsavableSimulationTimer(0.2, function()
        if updateGenSettings then
            updateGenSettings = false
            rebuildStorageData()
        end
    end)
end

local function mwrbd_saveProfile(data)
    profiles.saveProfile(data.name, localConfig)
    if world.players[1] then
        world.players[1]:sendEvent("mwrbd_updateProfiles", {profileNames = profiles.getProfileNames(), protectedNames = profiles.protectedNames})
    end
end

local function mwrbd_deleteProfile(data)
    profiles.deleteProfile(data.name)
    if world.players[1] then
        world.players[1]:sendEvent("mwrbd_updateProfiles", {profileNames = profiles.getProfileNames(), protectedNames = profiles.protectedNames})
    end
end

local function mwrbd_loadProfile(data)
    profiles.loadProfile(data.name, localConfig)
    world.players[1]:sendEvent("mwrbd_updateSettings", {configData = localConfig.data})
end

local function mwrbd_processDeathOfDisabled(data)
    local reference = data.reference
    if not reference then return end
    reference:removeScript("scripts/morrowind_world_randomizer/local/killNewCreature.lua")
end

local function onUpdate()
    if not localConfig.data.enabled or not cellListUpdated then return end
    for cell, tm in pairs(cellsToRandomize) do
        async:newUnsavableSimulationTimer(0, function()
            cellLib.randomize(cell)
        end)
        cellsToRandomize[cell] = nil
    end
end

return {
    engineHandlers = {
        onActorActive = async:callback(onActorActive),
        onObjectActive = async:callback(onObjectActive),
        onInit = async:callback(onInit),
        onSave = async:callback(onSave),
        onLoad = async:callback(onLoad),
        onNewGame = async:callback(onNewGame),
        onActivate = async:callback(onActivate),
        -- onPlayerAdded = async:callback(onPlayerAdded),
        onUpdate = async:callback(onUpdate),
    },
    eventHandlers = {
        mwr_updateInventory = async:callback(mwr_updateInventory),
        mwr_loadLocalConfigData = mwr_loadLocalConfigData,
        mwr_moveToPoint = async:callback(mwr_moveToPoint),
        mwr_deactivateObject = async:callback(mwr_deactivateObject),
        mwr_updateGeneratorSettings = async:callback(mwr_updateGeneratorSettings),
        mwrbd_saveProfile = async:callback(mwrbd_saveProfile),
        mwrbd_deleteProfile = async:callback(mwrbd_deleteProfile),
        mwrbd_loadProfile = async:callback(mwrbd_loadProfile),
        mwrbd_processDeathOfDisabled = async:callback(mwrbd_processDeathOfDisabled),
    },
}