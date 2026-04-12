local self = require('openmw.self')

local quests = {

    {
        id = "AL93_CPSideQuest2",
        name = "Letter to Tibbi-Ra",
        category = "Miscellaneous",
        subcategory = "Habasi Family",
        master = "Ash and Justice",
        text = "Deliver a letter and supplies to a mage in Vivec."
    },

    {
        id = "AL93_CPSideQuest3",
        name = "Letters",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        master = "Ash and Justice",
        text = "Deliver a pair of letters and recover a few personal effects."
    },

    {
        id = "AL93_CPSideQuest",
        name = "Letter to Silk-Fur Zihra",
        category = "Miscellaneous",
        subcategory = "Habasi Family",
        master = "Ash and Justice",
        text = "Deliver a family letter and help recover some Dwemer scrap."
    },

    {
        id = "AL93_CPQuest",
        name = "Ash and Justice",
        category = "Main Quest",
        subcategory = "Vivec",
        master = "Ash and Justice",
        text = "Investigate the murder of a loanshark in Vivec."
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