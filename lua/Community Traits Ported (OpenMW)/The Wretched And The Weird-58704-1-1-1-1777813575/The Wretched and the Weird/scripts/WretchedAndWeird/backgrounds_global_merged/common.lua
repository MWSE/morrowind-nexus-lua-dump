local world = require("openmw.world")
local core = require("openmw.core")

local itemDeletionBlacklist = {
    ["bk_a1_1_directionscaiuscosades"] = true,
    ["bk_a1_1_caiuspackage"] = true,
}

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

local function clrearInventory(actor)
    for _, item in ipairs(actor.type.inventory(actor):getAll()) do
        local record = item.type.records[item.recordId]
        if not itemDeletionBlacklist[item.recordId] and not record.mwscript then
            item:remove()
        end
    end
end

return {
    eventHandlers = {
        WretchedAndWeird_addItems = addItems,
        WretchedAndWeird_clrearInventory = clrearInventory
    }
}