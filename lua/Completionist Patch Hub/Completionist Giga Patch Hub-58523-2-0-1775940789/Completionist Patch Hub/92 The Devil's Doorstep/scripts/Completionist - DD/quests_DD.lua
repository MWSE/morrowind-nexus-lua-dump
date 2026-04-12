local self = require('openmw.self')

local quests = {

    {
        id = "AAkarRV_RedNecrQuest",
        name = "The Icey Grip of the Dead",
        category = "Miscellaneous",
        subcategory = "Solstheim",
        master = "The Devil's Doorstep",
        text = "Explore a remote island and investigate the undead presence there."
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