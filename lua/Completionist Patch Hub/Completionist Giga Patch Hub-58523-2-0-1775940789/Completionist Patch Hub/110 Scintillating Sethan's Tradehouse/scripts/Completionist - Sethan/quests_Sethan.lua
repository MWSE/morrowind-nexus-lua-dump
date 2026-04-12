local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Sethan
    -- #########################################################################

    {
        id = "end_st_lloryananecklace",
        name = "Lloryana's Hidden Amulet",
        category = "Miscellaneous",
        subcategory = "",
        master = "Sethan", text = "Attend to a matter involving lloryana's hidden amulet."
    },
    {
        id = "end_st_letterdelivery",
        name = "Letter to Fedura Sethan",
        category = "Miscellaneous",
        subcategory = "",
        master = "Sethan", text = "Lloryana Sethan has given them a letter to deliver to her cousin, Fedura Sethan who can be found in the St."
    },
    {
        id = "end_st_theranaeggs",
        name = "Selling Kwama Eggs to Therana",
        category = "Miscellaneous",
        subcategory = "",
        master = "Sethan", text = "Vadeal Mirehari has a surplus of Kwama Eggs and wants to sell them to Mistress Therana."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Sethan data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 3
