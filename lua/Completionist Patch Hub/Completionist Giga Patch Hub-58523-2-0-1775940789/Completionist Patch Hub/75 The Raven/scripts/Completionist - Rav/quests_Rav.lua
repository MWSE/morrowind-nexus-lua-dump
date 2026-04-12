local self = require('openmw.self')

local quests = {

    {
        id = "Sorka1_1",
        name = "A Bloody Package",
        category = "Miscellaneous",
        subcategory = "The Raven",
        master = "The Raven",
        text = "Deliver a package for the necromancer Sorkavild in Dagon Fel."
    },
    {
        id = "Sorka2_2",
        name = "Sorkavild's Stranglehold",
        category = "Miscellaneous",
        subcategory = "The Raven",
        master = "The Raven",
        text = "Bring the local garrison at Dagon Fel under Sorkavild's influence."
    },
    {
        id = "Sorka3_3",
        name = "The Leper Prince",
        category = "Miscellaneous",
        subcategory = "The Raven",
        master = "The Raven",
        text = "Infiltrate a lich's lair to retrieve research notes for the necromancer Sorkavild."
    },
    {
        id = "Sorka4_4",
        name = "A Cure for Wormlung",
        category = "Miscellaneous",
        subcategory = "The Raven",
        master = "The Raven",
        text = "Find a cure for the rare disease afflicting the necromancer Sorkavild."
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
-- Quest count: 4
