require("scripts.roaming_creeper.openmw")
local modInfo = require("scripts.roaming_creeper.modInfo")
local globalSetting = storage.globalSection("SettingsRoamingCreeperMain")

local items = require("scripts.roaming_creeper.items")
local destinations = require("scripts.roaming_creeper.destinations")

local currentDay = math.huge -- world.mwscript.getGlobalVariables().day

local creeper = world.getObjectByFormId(core.getFormId('Morrowind.esm', 175909))
local creeperOriginCell = "caldera, ghorak manor"
local creeperStartingPos = util.vector3(0, 0, 0)
local hasFollowAi = false

local creeperSales = {}
local creeperLastSales = {}

local function setup()
    if not creeper or not creeper:isValid() or creeper.recordId ~= "scamp_creeper" then
        for k, v in pairs(world.cells) do
            for a, b in pairs(v:getAll(types.Creature)) do
                if b.type.record(b).id == "scamp_creeper" then
                    creeper = b -- assuming only 1 creeper in the world, we only manipulate this creeper
                    creeperOriginCell = creeper.cell
                    creeperStartingPos = creeper.position
                    creeper:addScript("scripts/roaming_creeper/creeper.lua")
                    goto creeperFound
                end
            end
        end
        error("Creeper not found! Roaming Creeper will not work")
    end


    ::creeperFound::
    for _, stuff in pairs(items) do
        for _, item in pairs(stuff) do
            table.insert(creeperSales, item)
        end
    end
    for _, book in pairs(types.Book.records) do
        if book.isScroll and book.enchant:len() > 0 then
            table.insert(creeperSales, book.id)
        end
    end
end

local function removeLastSales()
    for _, item in pairs(creeperLastSales) do
        local inv = types.Actor.inventory(creeper)
        local itemToRemove = inv:find(item)
        if itemToRemove then
            itemToRemove:remove()
        end
    end
    creeperLastSales = {}
end


local function addNewSales()
    for _, item in pairs(creeperSales) do
        if math.random(1000) < 100 then
            world.createObject(item, math.random(4)):moveInto(creeper)
            table.insert(creeperLastSales, item)
        end
    end
    -- same as above but for wares mod
    if core.contentFiles.has("Wares-base.esm") and false then --disabled for now until api for levelled item is available
        for _, lvlitem in pairs(types.LevelledItem.records) do
            if lvlitem.id:match("^aa_") then                  -- startswith
                local item = lvlitem.getRandomId()
                if item and math.random(1000) < 100 then
                    world.createObject(item):moveInto(creeper)
                    table.insert(creeperLastSales, item)
                end
            end
        end
    end
end

local function nextDest(debug)
    local dest = destinations[math.random(#destinations)]
    local position, cell = dest.position, dest.cell
    local isDead = types.Actor.isDead(creeper)

    if hasFollowAi or not creeper or not position or not cell or isDead or not creeper:isValid() then
        return
    end

    if currentDay == 1 then
        creeper:teleport(creeperOriginCell, creeperStartingPos)
        cell = creeperOriginCell
    else
        creeper:teleport(cell, util.vector3(table.unpack(position)))
    end

    world.createObject("sprigganup"):teleport(cell, util.vector3(table.unpack(position)))
    async:newUnsavableSimulationTimer(0, function() core.sound.playSound3d("conjuration hit", creeper) end)
    creeper:sendEvent("startAIPackage", { type = "Wander", distance = 4096, duration = 24 }) -- doesnt work?, ai bug

    pcall(removeLastSales)
    pcall(addNewSales)

    if debug then
        for _, player in pairs(world.players) do
            player:teleport(cell, util.vector3(table.unpack(position)))
            player:sendEvent("RoamingCreeper_debug_eqnx", cell)
        end
        return
    end

    creeper:sendEvent("RoamingCreeper_update_eqnx", { fatigue = -5 })
end


async:newUnsavableSimulationTimer(0, setup)
return {
    interfaceName = "RoamingCreeper_interface",
    interface = {
        nextDest = nextDest
    },
    engineHandlers = {
        onLoad = function(data)
            if data then
                creeper = data.creeper
            end
        end,
        onSave = function()
            return { creeper = creeper }
        end,
        onUpdate = function()
            assert(modInfo.MIN_API == core.API_REVISION,
                string.format("[%s] requires API_REVISION %s", modInfo.MOD_NAME, modInfo.MIN_API))

            if globalSetting:get("Mod Status") and currentDay ~= world.mwscript.getGlobalVariables().day then
                currentDay = world.mwscript.getGlobalVariables().day
                pcall(nextDest)
            end
        end,
    },
    eventHandlers = {
        -- from settings_G.lua
        RoamingCreeper_update_eqnx = function(data)
            if data then
                hasFollowAi = data.hasFollowAi or hasFollowAi
                if data.turnedOff then
                    pcall(function() creeper:teleport(creeperOriginCell, creeperStartingPos, creeper.startingRotation) end)
                    pcall(removeLastSales)
                end
            end
        end
    }
}
