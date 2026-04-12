local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Legend of Chemua
    -- #########################################################################

    {
        id = "dd_3_quest2",
        name = "Rime of the Ancient Warrior",
        category = "Miscellaneous",
        subcategory = "",
        master = "Legend of Chemua", text = "Harak Ice-Breaker, an ancient bannerman of the Nords buried on the island of Running Hunger's Rest, has been awakened by the demons that plague the island."
    },
    {
        id = "dd_3_Quest3",
        name = "The Last Laugh",
        category = "Miscellaneous",
        subcategory = "",
        master = "Legend of Chemua", text = "A nordic bard skeleton trapped within the ice in Chemua Barrow has requested that one find a joke book for him."
    },
    {
        id = "DD_3_Quest",
        name = "Running Hunger's Rest",
        category = "Miscellaneous",
        subcategory = "",
        master = "Legend of Chemua", text = "One has been told by a citizen of Dagon Fel that a Nord named Garrick Blight-Born is seeking to hire adventurers to clear his family's tomb of monsters."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Legend of Chemua data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 3
