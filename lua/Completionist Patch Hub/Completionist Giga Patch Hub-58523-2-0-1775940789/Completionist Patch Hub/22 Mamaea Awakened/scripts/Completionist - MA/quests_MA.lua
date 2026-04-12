local self = require('openmw.self')

local quests = {

    {
        id = "FA1_journal",
        name = "Mamaea Awakened",
        category = "Temple",
        subcategory = "Gnisis",
        master = "Mamaea Awakened",
        text = "Investigate renewed trouble surrounding Mamaea and help recover a stolen sacred relic."
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
