local self = require('openmw.self')

local quests = {

    {
        id = "DEG_KBL01_Bandits",
        name = "The Bandits of Kumarahaz",
        category = "Dungeon",
        subcategory = "",
        master = "Kumarahaz Bandit Lair",
        text = "Aid an Imperial agent in Tel Branora investigating bandits hiding in nearby caverns."
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
