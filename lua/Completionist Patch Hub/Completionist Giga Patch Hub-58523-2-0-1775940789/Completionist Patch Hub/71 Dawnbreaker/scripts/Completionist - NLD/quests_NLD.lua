local self = require('openmw.self')

local quests = {

    {
        id = "NL_ShrineofMeridia",
        name = "Enemy of the Dead",
        category = "Daedric",
        subcategory = "Meridia",
        master = "NL Dawnbreaker",
        text = "Seek out the Shrine of Meridia and eliminate the lich dwelling within."
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
