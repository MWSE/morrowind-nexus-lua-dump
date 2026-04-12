local self = require('openmw.self')

local quests = {

    {
        id = "mdFM_Journal",
        name = "Where Merchants Flea",
        category = "Miscellaneous",
        subcategory = "",
        master = "Where Merchants Flea",
        text = "Help an Orc warrior in Suran track down a Khajiit merchant who sold her a bad deal."
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
