local self = require("openmw.self")

require("scripts.CanonicalGear.utils")

local function equipItem(data)
    local equipped = self.type.equipment(self)
    equipped[data.slot] = data.item.recordId
    self.type.setEquipment(self, equipped)
    Log("Equipped " .. data.item.recordId .. " to " .. self.recordId)
end

return {
    eventHandlers = {
        equipItem = equipItem
    }
}