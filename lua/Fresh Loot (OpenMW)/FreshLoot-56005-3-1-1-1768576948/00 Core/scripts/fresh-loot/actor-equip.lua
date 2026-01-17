local core = require("openmw.core")
local self = require("openmw.self")
local T = require("openmw.types")

local mDef = require("scripts.fresh-loot.config.definition")

local function equipItems(items)
    local equipment = T.Actor.getEquipment(self)
    for _, item in ipairs(items) do
        equipment[item.slot] = item.item
    end
    T.Actor.setEquipment(self, equipment)
end

return {
    eventHandlers = {
        [mDef.events.equipItems] = function(items)
            equipItems(items)
            core.sendGlobalEvent(mDef.events.detachScript, { object = self, scriptPath = mDef.scripts.actorEquip })
        end,
    }
}
