local self = require('openmw.self')

local quests = {

    {
        id = "DEG_AF01_AOP",
        name = "Artifacts of the Past",
        category = "Miscellaneous",
        subcategory = "Sheogorad",
        master = "Ancient Foes",
        text = "A young Nord in the Sheogorad seeks help recovering long-lost relics tied to his family's past."
    },

    {
        id = "DEG_AF02_HD",
        name = "Heifnir's Delivery",
        category = "Miscellaneous",
        subcategory = "Dagon Fel",
        master = "Ancient Foes",
        text = "A delayed shipment in Dagon Fel must be collected and brought to its intended recipient."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
