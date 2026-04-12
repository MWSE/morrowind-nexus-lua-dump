local self = require('openmw.self')

local quests = {

    {
        id = "SSMainQuest",
        name = "The Silent Siren",
        category = "Miscellaneous",
        subcategory = "Bitter Coast",
        master = "The Curse of The Silent Siren",
        text = "Investigate the tale of a cursed ship told at Land's End Tavern."
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
