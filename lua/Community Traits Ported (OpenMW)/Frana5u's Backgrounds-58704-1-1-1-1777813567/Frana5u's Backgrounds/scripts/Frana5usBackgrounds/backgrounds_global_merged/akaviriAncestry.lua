---@diagnostic disable: assign-type-mismatch
local world = require("openmw.world")
local core = require("openmw.core")

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

local function upgradeSword(player)
    local inv = player.type.inventory(player)
    local oldSword = inv:find("MB_akaviri_blade")
    if not oldSword then return end

    oldSword:remove()
    core.sendGlobalEvent(
        "Frana5usBackgrounds_addItems",
        {
            {
                player = player,
                itemId = "MB_akaviri_blade_rep",
                count = 1,
                autoEquip = true,
            },
        }
    )
    player:sendEvent("Frana5usBackgrounds_swordUpgraded")
end

return {
    eventHandlers = {
        Frana5usBackgrounds_addItems = addItems,
        Frana5usBackgrounds_upgradeSword = upgradeSword,
    }
}
