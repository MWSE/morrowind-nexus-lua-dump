local self = require('openmw.self')

local quests = {

    {
        id = "RG_keelhouse",
        name = "The Keelhouse Archeologist",
        category = "Miscellaneous",
        subcategory = "",
        master = "Keelhouse",
        text = "Retrieve an artifact from a nearby ruin for a wizard-archaeologist on the Thirr River."
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
