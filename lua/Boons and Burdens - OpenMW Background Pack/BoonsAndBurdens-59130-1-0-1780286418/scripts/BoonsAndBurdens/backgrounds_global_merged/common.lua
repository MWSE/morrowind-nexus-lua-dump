---@omw-context global
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local core = require("openmw.core")
local world = require("openmw.world")

local function dropItems(data)
    for _, item in ipairs(data.items) do
        item:teleport(data.cell, data.pos, { onGround = true })
    end
end

local function addItems(eventData)
    for _, itemData in ipairs(eventData) do
        local items = world.createObject(itemData.itemId, itemData.count)
        ---@diagnostic disable-next-line: discard-returns
        items:moveInto(itemData.player)

        if itemData.autoEquip then
            core.sendGlobalEvent("UseItem", {
                object = items,
                actor = itemData.player,
            })
        end
    end
end

return {
    eventHandlers = {
        BoonsAndBurdens_dropItems = dropItems,
        BoonsAndBurdens_addItems = addItems,
    }
}
