local self = require('openmw.self')

local quests = {

    {
        id = "kk_journal",
        name = "The Kagouti King",
        category = "Miscellaneous",
        subcategory = "",
        master = "Kagouti King Sword",
        text = "Help an Orc craftsman in Mournhold reforge an ancient ancestral sword."
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
