local self = require('openmw.self')

local quests = {

    {
        id = "MwG_apo_TheScentofSuspicion",
        name = "The Scent of Suspicion",
        category = "Miscellaneous",
        subcategory = "",
        master = "The Scent of Suspicion",
        text = "Assist the owner of the Suran apothecary with a delicate matter involving his research."
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
