local self = require('openmw.self')
local quests = {

    {
        id = "md24_j_redwisdom",
        name = "The Search for Red Wisdom",
        category = "Ashlanders",
        subcategory = "Red Wisdom",
        master = "Red Wisdom",
        text = "An Ashlander wise woman has asked me to help follow the signs of Red Wisdom among the tribes."
    },

    {
        id = "md24_j_guarhide",
        name = "Inscribed Guar Hide",
        category = "Ashlanders",
        subcategory = "Red Wisdom",
        master = "Red Wisdom",
        text = "I found an inscribed guar hide that may point the way to an Ashlander prophecy."
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

-- Quest count: 2
