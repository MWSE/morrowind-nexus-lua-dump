local self = require('openmw.self')
local quests = {
    {
        id = "md24_j_rockjoint",
        name = "A Sample of Rockjoint",
        category = "Miscellaneous",
        subcategory = "The Popular Plague",
        master = "The Popular Plague",
        text = "Acquire a sample of Rockjoint for Delphiara."
    },

    {
        id = "md24_j_delphiara",
        name = "Delphiara's Trail",
        category = "Miscellaneous",
        subcategory = "The Popular Plague",
        master = "The Popular Plague",
        text = "Investigate Delphiara and her connection to the disease."
    },

    {
        id = "md24_j_disease",
        name = "Great New Disease",
        category = "Miscellaneous",
        subcategory = "The Popular Plague",
        master = "The Popular Plague",
        text = "Investigate a strange disease spreading through Pelagiad."
    },

    {
        id = "md24_j_rats",
        name = "Catch Five Rats",
        category = "Miscellaneous",
        subcategory = "The Popular Plague",
        master = "The Popular Plague",
        text = "Capture several diseased rats for Delphiara."
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

-- Quest count: 4
