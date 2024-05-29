local log = include("diject.remains_of_the_fallen.utils.log")
local config = include("diject.remains_of_the_fallen.config")
local localStorage = include("diject.remains_of_the_fallen.storage.localStorage")
local dataStorage = include("diject.remains_of_the_fallen.storage.dataStorage")
local mapSpawner = include("diject.remains_of_the_fallen.mapSpawner")
local npc = include("diject.remains_of_the_fallen.libs.npc")

--- @param e loadedEventData
local function loadedCallback(e)
    localStorage.initPlayerStorage()
    config.initLocalData()

    if e.newGame then return end
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e loadEventData
local function loadCallback(e)
    config.resetLocalToDefault()
    localStorage.reset()
end
event.register(tes3.event.load, loadCallback, {priority = -9999})

--- @param e saveEventData
local function saveCallback(e)
    config.updateVersionInPlayerStorage()
end
event.register(tes3.event.save, saveCallback)

--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if not localStorage.isReady() or not config.data.map.enabled then return end
    local spawner = mapSpawner:new(e.cell, config.localConfig.id, localStorage.data, config.data.map.spawn.playerCount)

    local cellInfo = spawner:getCellLocalInfo()
    if cellInfo.lastSpawnTimestamp and cellInfo.lastSpawnTimestamp + config.data.map.spawn.interval > tes3.getSimulationTimestamp() then return end
    cellInfo.lastSpawnTimestamp = tes3.getSimulationTimestamp()

    ---@type rotf.item.decreaseItemStats.params
    local itemStatMultipliers
    if config.data.map.spawn.items.change.enbaled then
        itemStatMultipliers = {multiplier = config.data.map.spawn.items.change.multiplier, valueMul = config.data.map.spawn.items.change.costMul}
    end
    local count = 0
    for i = 1, config.data.map.spawn.count do
        if config.data.map.spawn.chance / 100 > math.random() then
            count = count + 1
        end
    end
    if count > 0 then
        spawner:spawn{count = count, maxCount = config.data.map.spawn.maxCount,
            actorParams = {spawnConfig = config.data.map.spawn.body, transferConfig = config.data.map.spawn.transfer,
            createNewItemRecord = config.data.map.spawn.items.change.enbaled, itemStatMultipliers = itemStatMultipliers, newItemPrefix = config.data.text.itemPrefix}}
    end
end
event.register(tes3.event.cellActivated, cellActivatedCallback)


local function modCallback()
    dataStorage.savePlayerDeathInfo(config.localConfig.id)
    -- increase the death counter
    config.localConfig.count = config.localConfig.count + 1 ---@diagnostic disable-line: inject-field
end

event.register("rotf_register_death", modCallback)


--- @param e deathEventData
local function deathCallback(e)
    if e.reference ~= tes3.player then
        return
    end
    modCallback()
end
event.register(tes3.event.death, deathCallback)

local randomizerConfig = include("Morrowind_World_Randomizer.storage")
if randomizerConfig and (not randomizerConfig.version or randomizerConfig.version <= 6) then

    local randomizer = include("Morrowind_World_Randomizer.Randomizer")
    --- @param e mobileActivatedEventData
    local function mobileActivatedCallback(e)
        if e.reference.baseObject.id:find(npc.npcTemplate) then
            randomizer.StopRandomization(e.reference)
        end
    end
    event.register(tes3.event.mobileActivated, mobileActivatedCallback, {priority = 10})
end