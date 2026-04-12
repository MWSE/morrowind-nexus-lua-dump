local self = require('openmw.self')

local quests = {

    {
        id = "ME_ExileQuest",
        name = "Maren's Misfit Mabrigash",
        category = "Miscellaneous",
        subcategory = "",
        master = "Maren Mabrigash",
        text = "Help an Ashlander search for a friend who was exiled from their clan."
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
-- Quest count: 1
