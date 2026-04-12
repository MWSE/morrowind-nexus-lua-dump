local self = require('openmw.self')

local quests = {

    {
        id = "mdSM_Journal",
        name = "Alberius' Third Peregrination",
        category = "Miscellaneous",
        subcategory = "",
        master = "The Mananaut's Message",
        text = "Relay an unusual message from a strange traveler to Yagrum Bagarn in the Corprusarium."
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
