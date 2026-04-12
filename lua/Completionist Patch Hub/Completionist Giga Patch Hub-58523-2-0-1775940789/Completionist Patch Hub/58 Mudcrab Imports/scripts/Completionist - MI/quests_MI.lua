local self = require('openmw.self')
local quests = {
    {
        id = "MI_ClearOut",
        name = "Bandit Free Roads",
        category = "Mudcrab Imports",
        subcategory = "Tradehouse Quests",
        master = "Mudcrab Imports",
        text = "Clear out bandits threatening the trade route near Mudcrab Imports."
    },

    {
        id = "MCT_coinfinder",
        name = "Nord's Lucky Coins",
        category = "Mudcrab Imports",
        subcategory = "Tradehouse Quests",
        master = "Mudcrab Imports",
        text = "Help a local recover a set of missing lucky coins."
    },

    {
        id = "MCT_sailtheseas",
        name = "Sailing the Uncharted Seas",
        category = "Mudcrab Imports",
        subcategory = "Seaside Adventures",
        master = "Mudcrab Imports",
        text = "Investigate a missing shipment and search for a lost sailor at sea."
    },

    {
        id = "SA_crimson",
        name = "Seaside Adventures",
        category = "Mudcrab Imports",
        subcategory = "Seaside Adventures",
        master = "Mudcrab Imports",
        text = "Join a seafaring expedition to recover treasure and deal with trouble along the way."
    },

    {
        id = "SA_endnote1",
        name = "Remains of the Crazed Sea Mage",
        category = "Mudcrab Imports",
        subcategory = "Seaside Adventures",
        master = "Mudcrab Imports",
        text = "Look into the remains and belongings of a strange sea mage."
    },

    {
        id = "SA_slavequest",
        name = "The Good Slavemaster",
        category = "Mudcrab Imports",
        subcategory = "Smugglers' Cross",
        master = "Mudcrab Imports",
        text = "Help reunite a separated family taken through the slave trade."
    },

    {
        id = "SA_smugglersfalls",
        name = "Into the Water Pit",
        category = "Mudcrab Imports",
        subcategory = "Smugglers' Cross",
        master = "Mudcrab Imports",
        text = "Investigate a suspicious trapdoor and uncover what lies below."
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

-- Quest count: 7
