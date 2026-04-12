local self = require('openmw.self')

local quests = {

    {
        id = "VMJ_Quest1",
        name = "Aether Pirate's Trinket",
        category = "Aethership",
        subcategory = "Aethership",
        master = "Aether Pirate's Discovery",
        text = "Investigate a strange jar connected to an aethership crew."
    },

    {
        id = "VMJ_Quest2",
        name = "Out of the Shadows",
        category = "Aethership",
        subcategory = "Aethership",
        master = "Aether Pirate's Discovery",
        text = "Help a spirit restore a body through a series of ritual offerings."
    },

    {
        id = "VMJ_Quest3",
        name = "Aether Pirate's Treasure",
        category = "Aethership",
        subcategory = "Aethership",
        master = "Aether Pirate's Discovery",
        text = "Check on a companion after a dangerous discovery in a hidden realm."
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

-- Quest count: 3