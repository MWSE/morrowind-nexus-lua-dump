local self = require('openmw.self')

local quests = {

    {
        id = "POT_TimeQuest",
        name = "Frozen in Time",
        category = "Miscellaneous",
        subcategory = "Azura's Coast",
        master = "Frozen in Time",
        text = "Investigate a strange disturbance tied to a forgotten family and an old curse."
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
