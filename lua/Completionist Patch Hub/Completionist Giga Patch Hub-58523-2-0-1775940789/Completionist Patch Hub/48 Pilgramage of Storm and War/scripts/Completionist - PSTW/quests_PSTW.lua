local self = require('openmw.self')
local quests = {
    {
        id = "MwG_PSW",
        name = "Pilgrimage of Storm and War",
        category = "Imperial Cult",
        subcategory = "Solstheim",
        master = "Pilgrimage of Storm and War",
        text = "Investigate a ruined statue of Talos and uncover the source of its lingering power."
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
