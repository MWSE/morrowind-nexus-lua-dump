local events = require('scripts.inventoryManager.events')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local player = world.players[1]

---@param data {item: Item, from: GameObject, to: GameObject, count: number}
local function moveItem(data)
        if not data.item or not data.item.count then return end

        data.item:split(data.count):moveInto(data.to.type.inventory(data.to))

        local container = data.to.type == types.Container and data.to or data.from

        player:sendEvent(events.itemMoved, container)
end


-- local info
local item
local container
-- -@param data {items: Item[], from: GameObject, to: GameObject}
---@param data {itemsInfo: [Item, Container][]}
local function batchmoveItem(data)
        if not data.itemsInfo then return end

        for i = 1, #data.itemsInfo do
                item = data.itemsInfo[i][1]
                container = data.itemsInfo[i][2]

                item:split(item.count):moveInto(container.type.inventory(container))
        end

        player:sendEvent(events.itemMoved, container)
end


local function dropItem(data)
        data.item:teleport(player.cell, player.position + data.item:getBoundingBox().halfSize, { onGround = true })
        player:sendEvent(events.itemMoved)
end

return {
        eventHandlers = {
                [events.moveItem] = moveItem,
                [events.dropItem] = dropItem,
                [events.batchmoveItem] = batchmoveItem,
        },
}
