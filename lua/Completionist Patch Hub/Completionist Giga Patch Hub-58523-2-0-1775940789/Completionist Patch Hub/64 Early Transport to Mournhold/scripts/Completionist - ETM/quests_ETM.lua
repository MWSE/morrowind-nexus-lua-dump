local self = require('openmw.self')

local quests = {

    {
        id = "necro_mh_transport",
        name = "Transport to Mournhold",
        category = "Miscellaneous",
        subcategory = "",
        master = "Early Transport to Mournhold",
        text = "Find a way to secure transport to Mournhold before normal routes become available."
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
