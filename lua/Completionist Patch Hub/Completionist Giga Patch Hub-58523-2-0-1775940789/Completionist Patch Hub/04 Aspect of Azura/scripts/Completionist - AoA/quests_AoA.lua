local self = require('openmw.self')

local quests = {

    {
        id = "ABaa_Journal",
        name = "Aspect of Azura",
        category = "Daedric Quests",
        subcategory = "Azura",
        master = "Aspect of Azura",
        text = "Tivam Sadri at Holamayan Monastery has directed me toward a task connected to Azura and the Face of Revelation."
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