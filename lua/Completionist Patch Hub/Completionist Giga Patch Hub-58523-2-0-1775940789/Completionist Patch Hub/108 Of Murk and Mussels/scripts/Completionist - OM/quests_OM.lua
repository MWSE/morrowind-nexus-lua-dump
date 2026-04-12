local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Of Murk and Mussels
    -- #########################################################################

    {
        id = "detd_investigate_skiff",
        name = "The Sunken Mussel Amulet",
        category = "Miscellaneous",
        subcategory = "",
        master = "Of Murk and Mussels", text = "Nevos Selman has assigned them the task of retrieving a valuable mussel amulet from a sunken skiff located south of Wolverine Hall."
    },
    {
        id = "detd_sea_rumours",
        name = "Wrath Of The Sea",
        category = "Miscellaneous",
        subcategory = "",
        master = "Of Murk and Mussels", text = "A local adventurer heard a rumor of a peculiar nature, suggesting a series of mysterious vanishings among sailors and fishermen."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Of_Murk data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 2
