local items = require("kd_circlets.items")

local function rebalance(itemQuality, expectedEnchant, expectedValue)
    local itemId = itemQuality .. '_amulet_01'
    local item = tes3.getObject(itemId)
    -- mwse.log('id: %s, value: %d, ench: %d', itemId, item.value, item.enchantCapacity)
    if item.enchantCapacity ~= expectedEnchant or item.value ~= expectedValue then
        for _, kditemId in ipairs(items.all) do
            local kditem = tes3.getObject(kditemId)
            if string.startswith(kditem.name:lower(), itemQuality) then
                kditem.value = item.value
                kditem.enchantCapacity = item.enchantCapacity
            end
        end
    end
end

event.register("initialized", function()
	rebalance('common', 10, 2)
    rebalance('expensive', 150, 30)
    rebalance('extravagant', 600, 120)
    rebalance('expensive', 1200, 240)
end)