--[[
    Register items that can be quickkeyed
]]
local items = {
    mer_tgw_flute = true
}

local function canQuickKey(e)
    local id = e.item.id:lower()
    return items[id]
end

event.register("filterInventorySelect", function(e)
    if canQuickKey(e) then e.filter = true end
end, { filter = "quick" })