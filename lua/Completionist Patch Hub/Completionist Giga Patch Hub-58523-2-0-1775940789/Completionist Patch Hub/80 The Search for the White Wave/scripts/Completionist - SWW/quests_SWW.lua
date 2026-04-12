local self = require('openmw.self')

local quests = {

    {
        id = "mdWW_Journal",
        name = "The Search for the White Wave",
        category = "Miscellaneous",
        subcategory = "",
        master = "The Search for the White Wave",
        text = "Join an Imperial Navy captain in searching for a missing civilian vessel."
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
