local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Ald'Ruhn Outskirts - Ancestral Refuge
    -- #########################################################################

    {
        id = "AAkarAO_Quest6LittleSpiders",
        name = "Ancestral Refuge: Scary Spiders",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Complete a task for Ancestral Refuge."
    },
    {
        id = "AAkarAO_Quest8AdrenithTomb",
        name = "Ancestral Refuge: Adrenith Ancestral Tomb",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Complete a task for Ancestral Refuge."
    },
    {
        id = "AAkarAO_Quest5PilgrimHelp",
        name = "Ancestral Refuge: An Old Pilgrim",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Near Ald'ruhn's Stider Port one has met with an old man, Gathal Veri."
    },
    {
        id = "AAkarAO_Quest3LostRing",
        name = "Ancestral Refuge: Lost Family Heirloom",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "In the Ancestral Refuge, a temple near Ald'ruhn, one has met with Boler Arns."
    },
    {
        id = "AAkarAO_Quest2Skulls",
        name = "Ancestral Refuge: Love for Skulls",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Ulvena Hledri, Curate of the mages in the Ancestral Refuge near Ald'ruhn, asked them to hunt down an orc bandit who attacked a group of pilgrims."
    },
    {
        id = "AAkarAO_Quest7MyName",
        name = "Ancestral Refuge: My name",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Complete a task for Ancestral Refuge."
    },
    {
        id = "AAkarAO_Quest1House",
        name = "Ancestral Refuge: Fire Fern Quarters",
        category = "Miscellaneous",
        subcategory = "",
        master = "Ald'Ruhn Outskirts - Ancestral Refuge", text = "Ulvena Hledri, Curate of the mages in the Ancestral Refuge near Ald'ruhn, offered them to buy nice living quarters in the temple."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Ald'Ruhn Outskirts - Ancestral Refuge data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 7
