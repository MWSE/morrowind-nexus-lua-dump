local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")

require("scripts.CursedTombs.utils.raycast")

local sectionRevenants = storage.globalSection("SettingsCursedTombs_revenants")

local function initCurse(reventants)
    core.sendGlobalEvent("CursedTombs_triggerCurse", {
        revenants = reventants,
        actor = self,
        spawnPos = FindSafeSpawnPos(self, sectionRevenants:get("spawnDistance"))
    })
end

local function quickLoot_lootedItems(eventData)
    local obj = eventData[1]

    if not types.Container.objectIsInstance(obj) then return end

    core.sendGlobalEvent("CursedTombs_activatedContainer", {
        obj = obj,
        actor = self,
        spawnPos = FindSafeSpawnPos(self, sectionRevenants:get("spawnDistance"))
    })
end

return {
    eventHandlers = {
        CursedTombs_initCurse       = initCurse,
        OwnlysQuickLoot_lootedItem  = quickLoot_lootedItems,
        OwnlysQuickLoot_lootedItems = quickLoot_lootedItems,
    }
}
