local self = require('openmw.self')

local quests = {

    {
        id = "SLF_The_Secret_of_Bethamez",
        name = "The Secret of Bethamez",
        category = "Miscellaneous",
        subcategory = "Gnisis",
        master = "Of Eggs and Dwarves",
        text = "Investigate tremors affecting the Gnisis eggmine."
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