local self = require('openmw.self')
local quests = {

    {
        id = "TT_Quest0",
        name = "Battlemage's Investigation",
        category = "Main Quest",
        subcategory = "Menistes Polusus",
        master = "Lord of Rebirth",
        text = "A battlemage near Ald Velothi asked for help investigating a dangerous cave and recovering his fallen companion.",
    },

    {
        id = "TT_QuestBattlemage",
        name = "Battlemage's Flight",
        category = "Main Quest",
        subcategory = "Menistes Polusus",
        master = "Lord of Rebirth",
        text = "I should help Menistes Polusus escape his confinement and return safely from the strange realm.",
    },

    {
        id = "TT_Quest1",
        name = "Alchemists of the Void",
        category = "Main Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "Octaen Stomire invited me to aid the alchemists of Lunarvine in their struggle and studies within the realm.",
    },

    {
        id = "TT_QuestPir1",
        name = "Pirates of the Void",
        category = "Main Quest",
        subcategory = "Void Pirates",
        master = "Lord of Rebirth",
        text = "Captain Grissom Sharr offered me a place among the void pirates and asked for my help in their cause.",
    },

    {
        id = "TT_QuestSublord",
        name = "Regret and Rebirth",
        category = "Main Quest",
        subcategory = "Luminous Vale",
        master = "Lord of Rebirth",
        text = "Therris set me to work on a secret plan that could change the balance of power in the realm.",
    },

    {
        id = "TT_QuestExiledAlchKK",
        name = "Exiled alchemist",
        category = "Side Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "An alchemist of Lunarvine asked me to recover the journal of an exile known for dangerous experiments.",
    },

    {
        id = "TT_QuestAlchBookKK",
        name = "The mysteries of the Outer Realms",
        category = "Side Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "Brallion asked me to retrieve a rare Dwemer book from the Crystal Mine for his research.",
    },

    {
        id = "TT_QuestAlchCel",
        name = "Channeling with a Colossal",
        category = "Side Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "Celent wants an escort to a great skeleton so he can attempt a dangerous act of channeling.",
    },

    {
        id = "TT_QuestAlchLec",
        name = "Tree Hunting",
        category = "Side Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "Lecella asked me to gather spriggan materials for one of her experiments.",
    },

    {
        id = "TT_QuestAlchCid",
        name = "Blood Atronach",
        category = "Side Quest",
        subcategory = "Alchemists",
        master = "Lord of Rebirth",
        text = "Cidrith needs help with an errand and the training of a strange blood-forged atronach.",
    },

    {
        id = "TT_QuestPiratesBloodtearKK",
        name = "The Bloodtear",
        category = "Side Quest",
        subcategory = "Void Pirates",
        master = "Lord of Rebirth",
        text = "Memkuuz Ux asked me to locate a crimson-bladed dagger known as the Bloodtear and show it to him.",
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

-- Quest count: 11
