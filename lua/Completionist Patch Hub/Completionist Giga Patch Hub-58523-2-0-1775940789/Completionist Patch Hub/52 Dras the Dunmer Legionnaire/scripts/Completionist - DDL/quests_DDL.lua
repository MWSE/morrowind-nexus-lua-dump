local self = require('openmw.self')

local quests = {

    {
        id = "q_DrasKingslayer",
        name = "Kingslayer",
        category = "Tribunal",
        subcategory = "Mournhold",
        master = "Dras the Dunmer Legionnaire",
        text = "Help Dras with a dangerous plan involving the king."
    },

    {
        id = "q_DrasRevenge",
        name = "Revenge is a dish served cold",
        category = "Camonna Tong",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Aid Dras in striking against his enemies."
    },

    {
        id = "q_DrasMonster",
        name = "Monster",
        category = "Sixth House",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Investigate Dras after troubling dreams and rumors."
    },

    {
        id = "q_DrasMurder",
        name = "Legionnaire and Murderer",
        category = "Imperial Legion",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Hear out a legionnaire seeking quiet help with a murder case."
    },

    {
        id = "q_DrasFamily",
        name = "Love and Hatred",
        category = "Companion",
        subcategory = "Family",
        master = "Dras the Dunmer Legionnaire",
        text = "Look into Dras' family troubles with outside help."
    },

    {
        id = "q_DrasVision",
        name = "The Vision and Swordsman",
        category = "Ashlanders",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Follow up on a wise woman's vision about a mysterious swordsman."
    },

    {
        id = "q_DrasLove",
        name = "Playing with Fire",
        category = "Companion",
        subcategory = "Romance",
        master = "Dras the Dunmer Legionnaire",
        text = "Spend time with Dras and decide how close the bond should become."
    },

    {
        id = "q_DrasWrit",
        name = "An Honorable Death",
        category = "Morag Tong",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Deal with a writ involving Dras."
    },

    {
        id = "q_DrasCT",
        name = "The Traitor",
        category = "Camonna Tong",
        subcategory = "",
        master = "Dras the Dunmer Legionnaire",
        text = "Handle the conflict between Dras and the Camonna Tong."
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

-- Quest count: 9