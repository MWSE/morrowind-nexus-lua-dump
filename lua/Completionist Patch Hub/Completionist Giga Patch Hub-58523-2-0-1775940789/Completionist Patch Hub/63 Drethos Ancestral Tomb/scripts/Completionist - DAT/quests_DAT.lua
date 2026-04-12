local self = require('openmw.self')

local quests = {

    {
        id = "slf_ho_drethosancestraltomb",
        name = "Drethos Ancestral Tomb",
        category = "Miscellaneous",
        subcategory = "",
        master = "Drethos Ancestral Tomb",
        text = "Help a traveler from the mainland learn about her ancestors buried in a nearby tomb."
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
