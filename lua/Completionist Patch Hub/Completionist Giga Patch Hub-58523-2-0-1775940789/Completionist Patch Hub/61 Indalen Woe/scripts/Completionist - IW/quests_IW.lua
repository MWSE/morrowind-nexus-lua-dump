local self = require('openmw.self')

local quests = {

    {
        id = "DM_FortuneWoe",
        name = "Dreams of the Dead",
        category = "Miscellaneous",
        subcategory = "",
        master = "DM IndalenWoe",
        text = "Investigate the Indalen Ancestral Tomb after hearing about a troubled local in Caldera."
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
