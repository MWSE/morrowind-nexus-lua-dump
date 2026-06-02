-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/global.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
--
-- Because access to data and item creation happens in the GLOBAL scope, we need
-- to pass events back and forth, otherwise we'd end up loading and transforming
-- data multiple times. 
-- -----------------------------------------------------------------------------

local types = require("openmw.types")
local world = require("openmw.world")
local interfaces = require("openmw.interfaces")

local function checkItem(id, itemTypes)
    local searchId = id:lower()
    for _, itemType in ipairs(itemTypes) do
        for _, record in ipairs(types[itemType].records) do
            if record.id:lower() == searchId then return true end
        end
    end
    return false
end

local function playerFillContainer(eventData)
    local Data = interfaces.BasicNeedsData
    local player = eventData.player
    local playerInventory = types.Actor.inventory(player)
    -- Obtenemos todos los objetos misceláneos una sola vez
    local miscItems = playerInventory:getAll(types.Miscellaneous)
    
    local summary = {}
    local foundAny = false

    for _, item in ipairs(miscItems) do
        local filledId = Data.getFilledVariantId(item.recordId)
        if filledId then
            local count = item.count
            -- Obtenemos el nombre. Si no tiene (raro), usamos la ID.
            local record = types.Miscellaneous.record(item.recordId)
            local containerName = record.name ~= "" and record.name or item.recordId
            
            table.insert(summary, { name = containerName, count = count })
            
            -- Procesamiento seguro: eliminar y crear
            item:remove(count)
            world.createObject(filledId, count):moveInto(playerInventory)
            
            foundAny = true
        end
    end

    if not foundAny then
        player:sendEvent("PlayerFilledContainer", {}) 
    else
        player:sendEvent("PlayerFilledContainer", { summary = summary })
    end
end

local function playerConsumeItem(eventData)
    local Data = interfaces.BasicNeedsData
    if not eventData or not eventData.item then return end
    
    local consumable = Data.getConsumableValues(eventData.item.recordId)
    if consumable then
        eventData.player:sendEvent("PlayerConsumedFood", {
            thirst = consumable[1],
            hunger = consumable[2],
            exhaustion = consumable[3],
        })
        return
    end

    local empty = Data.getEmptyVariantId(eventData.item.recordId)
    
    -- Si no encuentra por ID exacto, intenta por convención _filled
    if not empty then
        local baseId = eventData.item.recordId:gsub("_filled$", "")
        if baseId ~= eventData.item.recordId and checkItem(baseId, { "Miscellaneous" }) then
            empty = baseId
        end
    end

    if empty then
        local playerInventory = types.Actor.inventory(eventData.player)
        world.createObject(empty, 1):moveInto(playerInventory)
        eventData.player:sendEvent("PlayerConsumedFood", {
            thirst = -150,
            hunger = 0,
            exhaustion = 0,
        })
    end
end

return {
    eventHandlers = {
        PlayerConsumeItem = playerConsumeItem,
        PlayerFillContainer = playerFillContainer,
    },
}