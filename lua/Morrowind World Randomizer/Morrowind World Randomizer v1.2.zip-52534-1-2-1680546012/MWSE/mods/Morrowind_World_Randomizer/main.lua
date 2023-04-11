local esp_name = "Morrowind World Randomizer.ESP"

local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local randomizer = include("Morrowind_World_Randomizer.Randomizer")
local gui = include("Morrowind_World_Randomizer.gui")
local i18n = mwse.loadTranslations("Morrowind_World_Randomizer")
local log = include("Morrowind_World_Randomizer.log")
local generator = include("Morrowind_World_Randomizer.generator")

local function getCellLastRandomizeTime(cellId)
    local playerData = dataSaver.getObjectData(tes3.player)
    if playerData then
        if playerData.cellTimestamps == nil then playerData.cellTimestamps = {} end
        if playerData.cellTimestamps[cellId] then return playerData.cellTimestamps[cellId] end
    end
    return nil
end

local function setCellLastRandomizeTime(cellId, timestamp, gameTime)
    local playerData = dataSaver.getObjectData(tes3.player)
    if playerData then
        if playerData.cellTimestamps == nil then playerData.cellTimestamps = {} end
        playerData.cellTimestamps[cellId] = {timestamp = timestamp, gameTime = gameTime}
    end
end

local function forcedActorRandomization(reference)
    local mobile = reference.mobile
    if mobile then
        randomizer.randomizeMobileActor(mobile)
        randomizer.randomizeScale(reference)
        randomizer.saveAndRestoreBaseObjectInitialData(mobile.object.baseObject)
        randomizer.randomizeActorBaseObject(mobile.object.baseObject, mobile.actorType)
        randomizer.randomizeBody(reference)
        local configGroup
        if reference.object.objectType == tes3.objectType.npc then
            configGroup = randomizer.config.data.NPCs
        elseif reference.object.objectType == tes3.objectType.creature then
            configGroup = randomizer.config.data.creatures
        end
        if configGroup.items.randomize then
            randomizer.randomizeContainerItems(reference, configGroup.items.region.min, configGroup.items.region.max)
        end
        if configGroup.randomizeOnlyOnce then
            randomizer.StopRandomization(reference)
        else
            randomizer.StopRandomizationTemp(reference)
        end
    end
end

local function randomizeActor(reference)
    local playerData = dataSaver.getObjectData(tes3.player)
    if playerData and playerData.randomizedBaseObjects and playerData.randomizedBaseObjects[reference.baseObject.id] then
        randomizer.setBaseObjectData(reference.baseObject, playerData.randomizedBaseObjects[reference.baseObject.id])
        reference:updateEquipment()
    end

    if not randomizer.isRandomizationStopped(reference) and not randomizer.isRandomizationStoppedTemp(reference) then

        forcedActorRandomization(reference)

    end

    if playerData then
        if playerData.randomizedBaseObjects == nil then playerData.randomizedBaseObjects = {} end
        playerData.randomizedBaseObjects[reference.baseObject.id] = randomizer.getBaseObjectData(reference.baseObject)
    end
end

local function randomizeCellOnly(cell)
    setCellLastRandomizeTime(cell.editorName, os.time(), tes3.getSimulationTimestamp())
    randomizer.randomizeWeatherChance(cell)
    timer.delayOneFrame(function() randomizer.randomizeCell(cell) end)
end

local function forcedCellRandomization(cell, isForcedActorRandomization)
    randomizeCellOnly(cell)

    for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
        if isForcedActorRandomization then
            forcedActorRandomization(ref)
        else
            randomizeActor(ref)
        end
    end
end

local function randomizeLoadedCells(addedGameTime, forceCellRandomization, forceActorRandomization)
    if addedGameTime == nil then addedGameTime = 0 end
    local cells = tes3.getActiveCells()
    if cells ~= nil then
        for i, cell in pairs(cells) do
            local cellLastRandomizeTime = getCellLastRandomizeTime(cell.editorName)
            if forceCellRandomization or cellLastRandomizeTime == nil or not randomizer.config.getConfig().cells.randomizeOnlyOnce and
                    ((tes3.getSimulationTimestamp() - cellLastRandomizeTime.gameTime + addedGameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                    (os.time() - cellLastRandomizeTime.timestamp) > randomizer.config.global.cellRandomizationCooldown) then

                forcedCellRandomization(cell, forceActorRandomization)
            end
        end
    end
end

local function generateRandomizedLandscapeTextureIndices()
    randomizer.config.global.landscape.textureIndices = generator.generateRandomizedLandscapeTextureIndices()
    randomizer.config.save()
end

local function loadRandomizedLandscapeTextures()
    if not randomizer.config.global.landscape.textureIndices then return end

    local textures = randomizer.config.global.landscape.textureIndices
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if cell.landscape then
            for i, val in pairs(cell.landscape.textureIndices) do
                local valStr = tostring(val)
                if textures[valStr] then
                    cell.landscape.textureIndices[i] = textures[valStr]
                end
            end
        end
    end
end

local function isLandscapeTexturesValid()
    if not randomizer.config.global.landscape.textureIndices then return false end

    local textures = randomizer.config.global.landscape.textureIndices
    for _, texture in pairs(tes3.dataHandler.nonDynamicData.landTextures) do
        if not textures[tostring(texture.id)] then
            return false
        end
    end
    local count = 0
    for _, _ in pairs(randomizer.config.global.landscape.textureIndices) do
        count = count + 1
    end
    if count ~= #tes3.dataHandler.nonDynamicData.landTextures then
        return false
    end
    return true
end

local function itemDropped(e)
    if randomizer.config.getConfig().enabled then
        if e.reference ~= nil and e.reference.data ~= nil then
            randomizer.StopRandomization(e.reference)
        end
    end
end

local function cellActivated(e)
    if randomizer.config.getConfig().enabled then

        local cellLastRandomizeTime = getCellLastRandomizeTime(e.cell.editorName)
        if cellLastRandomizeTime == nil or not randomizer.config.getConfig().cells.randomizeOnlyOnce and
                ((tes3.getSimulationTimestamp() - cellLastRandomizeTime.gameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                (os.time() - cellLastRandomizeTime.timestamp) > randomizer.config.global.cellRandomizationCooldown) then

            randomizeCellOnly(e.cell)

        elseif randomizer.config.getConfig().light.randomize then
            randomizer.restoreCellLight(e.cell)
        end
    end
end

local function load(e)
    randomizer.restoreAllBaseInitialData()
    randomizer.config.resetConfig()
end

local function loaded(e)
    randomizer.config.getConfig()
    randomizer.genNonStaticData()

    if randomizer.config.getConfig().enabled then
        if mge.enabled() then
            if randomizer.config.getConfig().other.disableMGEDistantStatics == true and mge.render.distantStatics then
                mge.render.distantStatics = false
                mge.render.distantWater = false
            end
            if randomizer.config.getConfig().other.disableMGEDistantLand == true and (mge.render.distantLand or mge.render.distantWater) then
                mge.render.distantStatics = false
                mge.render.distantLand = false
                mge.render.distantWater = false
            end
        end

        randomizeLoadedCells()

    end
end

local goldToAdd = 0
local function leveledItemPicked(e)
    if randomizer.config.getConfig().enabled then
        if randomizer.config.data.containers.items.randomize and e.pick ~= nil and e.pick.id ~= nil and
                not randomizer.isRandomizationStoppedTemp(e.spawner) then

            if e.pick.objectType == tes3.objectType.miscItem and e.pick.id == "Gold_001" and e.spawner ~= nil then

                local newCount = randomizer.config.data.gold.region.min + math.random() *
                    (randomizer.config.data.gold.region.max - randomizer.config.data.gold.region.min)

                goldToAdd = goldToAdd + newCount
                if goldToAdd >= 2 then
                    local count = math.floor(goldToAdd - 1)
                    tes3.addItem({ reference = e.spawner, item = e.pick.id, count = count, })
                    goldToAdd = goldToAdd - count
                end
                if goldToAdd < 1 then
                    e.block = true
                else
                    goldToAdd = goldToAdd - 1
                end

            end
            local newId = randomizer.getNewRandomItemId(e.pick.id)
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
end

local function leveledCreaturePicked(e)
    if randomizer.config.getConfig().enabled then
        if e.pick ~= nil and randomizer.config.data.creatures.randomize then
            local newId = randomizer.getRandomCreatureId(e.pick.id)
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
end

local function mobileActivated(e)
    if randomizer.config.getConfig().enabled then
        if (e.reference.object.objectType == tes3.objectType.npc or e.reference.object.objectType == tes3.objectType.creature) then
            randomizeActor(e.reference)
        end
    end
end

local function landscapeRandOptionCallback(e)
    if e.button == 0 then
        randomizer.config.global.landscape.randomize = true
        randomizer.config.save()
        generateRandomizedLandscapeTextureIndices()
        loadRandomizedLandscapeTextures()
    end
end

local function showLandscapeRandOptionMessage()
    if not randomizer.config.global.landscape.randomize then
        tes3.messageBox({ message = i18n("messageBox.enableLandscapeRand.message"),
            buttons = {i18n("messageBox.enableRandomizer.button.yes"), i18n("messageBox.enableRandomizer.button.no")},
            callback = landscapeRandOptionCallback, showInDialog = false})
    end
end

local function distantLandOptionsCallback(e)
    if e.button == 0 then
        randomizer.config.getConfig().other.disableMGEDistantLand = true
        mge.render.distantStatics = false
        mge.render.distantLand = false
        mge.render.distantWater = false
    elseif e.button == 1 then
        randomizer.config.getConfig().other.disableMGEDistantStatics = true
        mge.render.distantStatics = false
    elseif e.button == 2 then
        randomizer.config.getConfig().trees.randomize = false
        randomizer.config.getConfig().stones.randomize = false
    end
    randomizeLoadedCells()
    showLandscapeRandOptionMessage()
end

local function enableRandomizerCallback(e)
    if e.button == 0 then
        randomizer.config.getConfig().enabled = true
        if mge.enabled() and (mge.render.distantStatics or mge.render.distantLand) then
            tes3.messageBox({ message = i18n("messageBox.selectDistantLandOption.message"),
                buttons = {i18n("messageBox.selectDistantLandOption.button.disableDistantLand"), i18n("messageBox.selectDistantLandOption.button.disableDistantStatics"),
                i18n("messageBox.selectDistantLandOption.button.disableRandomization"), i18n("messageBox.selectDistantLandOption.button.doNothing")},
                callback = distantLandOptionsCallback, showInDialog = false})
        else
            randomizeLoadedCells()
            showLandscapeRandOptionMessage()
        end
    end
end

local function activate(e)
    if randomizer.config.getConfig().enabled then
        if e.target  ~= nil and e.target.data ~= nil and (e.target.baseObject.objectType == tes3.objectType.container or
                (e.target.isDead == true and (e.target.baseObject.objectType == tes3.objectType.creature or
                e.target.baseObject.objectType == tes3.objectType.npc))) then

            randomizer.StopRandomization(e.target)

        elseif e.target  ~= nil and e.target.baseObject.objectType == tes3.objectType.door and
                not randomizer.config.data.doors.onlyOnCellRandomization then

            randomizer.doors.resetDoorDestination(e.target)
            randomizer.doors.randomizeDoor(e.target)

        end
    end
    if e.target.baseObject.id == "chargen_shipdoor" and not randomizer.config.global.globalConfig and
            dataSaver.getObjectData(tes3.player) and not dataSaver.getObjectData(tes3.player).messageShown and
            not randomizer.config.getConfig().enabled then

        dataSaver.getObjectData(tes3.player).messageShown = true
        e.block = true
        tes3.messageBox({ message = i18n("messageBox.enableRandomizer.message"), buttons = {i18n("messageBox.enableRandomizer.button.yes"),
            i18n("messageBox.enableRandomizer.button.no")}, callback = enableRandomizerCallback, showInDialog = false})
    end
end

local function calcRestInterrupt(e)
    if randomizer.config.getConfig().enabled then
        randomizeLoadedCells(e.hour)
    end
end

event.register(tes3.event.initialized, function(e)
    if not tes3.isModActive(esp_name) then
        gui.hide()
        return
    end

    randomizer.config.load()
    math.randomseed(os.time())
    randomizer.genStaticData()

    if randomizer.config.global.landscape.randomize then
        if not isLandscapeTexturesValid() and not randomizer.config.global.landscape.randomizeOnlyOnce then
            generateRandomizedLandscapeTextureIndices()
        end
        loadRandomizedLandscapeTextures()
    end

    event.register(tes3.event.itemDropped, itemDropped)
    event.register(tes3.event.cellActivated, cellActivated)
    event.register(tes3.event.load, load)
    event.register(tes3.event.loaded, loaded)
    event.register(tes3.event.leveledItemPicked, leveledItemPicked)
    event.register(tes3.event.leveledCreaturePicked, leveledCreaturePicked)
    event.register(tes3.event.mobileActivated, mobileActivated)
    event.register(tes3.event.activate, activate)
    event.register(tes3.event.calcRestInterrupt, calcRestInterrupt)
    log("Morrowind World Randomizer is ready")
end)

gui.init(randomizer.config, i18n, {generateStaticFunc = randomizer.genStaticData, randomizeLoadedCellsFunc = function() enableRandomizerCallback({button = 0}) end,
    randomizeLoadedCells = randomizeLoadedCells, genRandLandTextureInd = generateRandomizedLandscapeTextureIndices, loadRandLandTextures = loadRandomizedLandscapeTextures})
event.register(tes3.event.modConfigReady, gui.registerModConfig)