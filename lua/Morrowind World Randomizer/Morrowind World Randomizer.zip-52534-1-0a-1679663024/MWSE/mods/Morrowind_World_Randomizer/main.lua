local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local randomizer = require("Morrowind_World_Randomizer.Randomizer")
local gui = require("Morrowind_World_Randomizer.gui")
local i18n = mwse.loadTranslations("Morrowind_World_Randomizer")
local log = require("Morrowind_World_Randomizer.log")

local cellLastRandomizeTime = {}

local function randomizeActor(reference)
    local mobile = reference.mobile
    if mobile and not randomizer.isRandomizationStopped(reference) and not randomizer.isRandomizationStoppedTemp(reference) then
        if reference.object.objectType == tes3.objectType.npc then
            randomizer.randomizeContainerItems(reference, randomizer.config.data.NPCs.items.region.min, randomizer.config.data.NPCs.items.region.max)
        elseif reference.object.objectType == tes3.objectType.creature then
            randomizer.randomizeContainerItems(reference, randomizer.config.data.creatures.items.region.min, randomizer.config.data.creatures.items.region.max)
        end

        randomizer.randomizeMobileActor(mobile)
        randomizer.randomizeBody(mobile)
        randomizer.randomizeScale(reference)
        randomizer.StopRandomizationTemp(reference)
        randomizer.randomizeActorBaseObject(mobile.object.baseObject, mobile.actorType)
    end
end

local function randomizeLoadedCells(addedGameTime)
    if addedGameTime == nil then addedGameTime = 0 end
    local cells = tes3.getActiveCells()
    if cells ~= nil then
        for i, cell in pairs(cells) do
            if cellLastRandomizeTime[cell.editorName] == nil or
                    (tes3.getSimulationTimestamp() - cellLastRandomizeTime[cell.editorName].gameTime + addedGameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                    (os.time() - cellLastRandomizeTime[cell.editorName].timestamp) > randomizer.config.global.cellRandomizationCooldown then

                cellLastRandomizeTime[cell.editorName] = {timestamp = os.time(), gameTime = tes3.getSimulationTimestamp()}
                randomizer.randomizeWeatherChance(cell)
                timer.delayOneFrame(function() randomizer.randomizeCell(cell) end)

                for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
                    randomizeActor(ref)
                end
            end
        end
    end
end

event.register(tes3.event.itemDropped, function(e)
    if randomizer.config.getConfig().enabled then
        if e.reference ~= nil and e.reference.data ~= nil then
            randomizer.StopRandomization(e.reference)
        end
    end
end)

event.register(tes3.event.activate, function(e)
    if randomizer.config.getConfig().enabled then
        if e.target  ~= nil and e.target.data ~= nil and (e.target.baseObject.objectType == tes3.objectType.container or
                (e.target.isDead == true and (e.target.baseObject.objectType == tes3.objectType.creature or
                e.target.baseObject.objectType == tes3.objectType.npc))) then

            randomizer.StopRandomization(e.target)

        elseif e.target  ~= nil and e.target.baseObject.objectType == tes3.objectType.door then

            randomizer.doors.resetDoorDestination(e.target)
            randomizer.doors.randomizeDoor(e.target)

        end
    end
end)

event.register(tes3.event.cellActivated, function(e)
    if randomizer.config.getConfig().enabled then

        if cellLastRandomizeTime[e.cell.editorName] == nil or
                (tes3.getSimulationTimestamp() - cellLastRandomizeTime[e.cell.editorName].gameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                (os.time() - cellLastRandomizeTime[e.cell.editorName].timestamp) > randomizer.config.global.cellRandomizationCooldown then

            cellLastRandomizeTime[e.cell.editorName] = {timestamp = os.time(), gameTime = tes3.getSimulationTimestamp()}
            randomizer.randomizeWeatherChance(e.cell)
            timer.delayOneFrame(function() randomizer.randomizeCell(e.cell) end)
        end
    end
end)

event.register(tes3.event.load, function(e)
    cellLastRandomizeTime = {}
    randomizer.config.resetConfig()
end)

event.register(tes3.event.loaded, function(e)
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
end)

local goldToAdd = 0
event.register(tes3.event.leveledItemPicked, function(e)
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
end)

event.register(tes3.event.leveledCreaturePicked, function(e)
    if randomizer.config.getConfig().enabled then
        if e.pick ~= nil and randomizer.config.data.creatures.randomize then
            local newId = randomizer.getRandomCreatureId(e.pick.id)
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
end)

event.register(tes3.event.initialized, function(e)
    math.randomseed(os.time())
    randomizer.genStaticData()
end)

event.register(tes3.event.mobileActivated, function(e)
    if randomizer.config.getConfig().enabled then
        if (e.reference.object.objectType == tes3.objectType.npc or e.reference.object.objectType == tes3.objectType.creature) and
                not randomizer.isRandomizationStopped(e.reference) and not randomizer.isRandomizationStoppedTemp(e.reference) then
            randomizeActor(e.reference)
        end
    end
end)

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
    cellLastRandomizeTime = {}
    randomizeLoadedCells()
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
            cellLastRandomizeTime = {}
            randomizeLoadedCells()
        end
    end
end

event.register(tes3.event.activate, function(e)
    if e.target.baseObject.id == "chargen_shipdoor" and not randomizer.config.global.globalConfig and
            dataSaver.getObjectData(tes3.player) and not dataSaver.getObjectData(tes3.player).messageShown and
            not randomizer.config.getConfig().enabled then

        dataSaver.getObjectData(tes3.player).messageShown = true
        e.block = true
        tes3.messageBox({ message = i18n("messageBox.enableRandomizer.message"), buttons = {i18n("messageBox.enableRandomizer.button.yes"),
            i18n("messageBox.enableRandomizer.button.no")}, callback = enableRandomizerCallback, showInDialog = false})
    end
end)

event.register(tes3.event.calcRestInterrupt, function(e)
    if randomizer.config.getConfig().enabled then
        randomizeLoadedCells(e.hour)
    end
end)

gui.init(randomizer.config, i18n, {generateStaticFunc = randomizer.genStaticData, randomizeLoadedCellsFunc = function() enableRandomizerCallback({button = 0}) end})
event.register(tes3.event.modConfigReady, gui.registerModConfig)