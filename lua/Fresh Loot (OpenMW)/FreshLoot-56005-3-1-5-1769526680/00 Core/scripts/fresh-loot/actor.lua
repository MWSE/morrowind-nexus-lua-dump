local core = require("openmw.core")
local self = require("openmw.self")
local T = require("openmw.types")
local ai = require('openmw.interfaces').AI

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")

local function equipItems(itemsToEquip)
    local equipment = T.Actor.getEquipment(self)
    for _, itemToEquip in ipairs(itemsToEquip) do
        equipment[itemToEquip.slot] = itemToEquip.item
    end
    T.Actor.setEquipment(self, equipment)
end

local function getActorStats()
    local package = ai.getActivePackage()
    return mT.new.actorStats(self, package and package.type or "Wander", package and package.distance or 0)
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        revertLoot = function() return core.sendGlobalEvent(mDef.events.revertLoot, self) end,
    },
    eventHandlers = {
        [mDef.events.equipItems] = equipItems,
        [mDef.events.getActorStats] = function(event) mObj.answerRequestEvent(event, getActorStats()) end,
    }
}
