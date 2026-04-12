local self = require('openmw.self')

local quests = {

    {
        id = "slf_wh_WakeOfHanin",
        name = "The Wake of Hanin",
        category = "Dungeon",
        subcategory = "Mordrin Hanin's Tomb",
        master = "The Wake of Hanin",
        text = "Assist a sorceress searching for her missing associate near an old tomb."
    },
    {
        id = "slf_wh_AStrangersHeart",
        name = "A Stranger's Heart",
        category = "Dungeon",
        subcategory = "Mordrin Hanin's Tomb",
        master = "The Wake of Hanin",
        text = "Help a peculiar stranger encountered inside Mordrin Hanin's Tomb reclaim something precious."
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
-- Quest count: 2
