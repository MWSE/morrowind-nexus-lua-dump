local self = require('openmw.self')

local quests = {

    {
        id = "NF_MissingAgent",
        name = "A Troubling Disappearance",
        category = "Side Quest",
        subcategory = "Huleeya",
        master = "The Unhatched",
        text = "I should look into Huleeya's disappearance and learn what became of him."
    },

    {
        id = "Nf_Hist_healed",
        name = "Hist Healed",
        category = "Miscellaneous",
        subcategory = "Hist",
        master = "The Unhatched",
        text = "I have played a part in setting right a troubling matter involving the Hist."
    },

    {
        id = "NF_UnhatchedA1",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "Temple Eggs",
        master = "The Unhatched",
        text = "I found one of the stone eggs needed for the matter of the Unhatched."
    },

    {
        id = "NF_UnhatchedA2",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "Temple Eggs",
        master = "The Unhatched",
        text = "I found another stone egg tied to the search for the Unhatched."
    },

    {
        id = "NF_UnhatchedA3",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "Temple Eggs",
        master = "The Unhatched",
        text = "I recovered another stone egg from one of the old temples."
    },

    {
        id = "NF_UnhatchedA4",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "Temple Eggs",
        master = "The Unhatched",
        text = "I found yet another stone egg connected to the Unhatched."
    },

    {
        id = "NF_DarkSecret",
        name = "Shadow of the Hist",
        category = "Main Quest",
        subcategory = "The Unhatched",
        master = "The Unhatched",
        text = "I should follow new leads concerning a dark matter surrounding the Hist."
    },

    {
        id = "NF_DreamThree",
        name = "A Future in Ruin",
        category = "Main Quest",
        subcategory = "Dream Visions",
        master = "The Unhatched",
        text = "I experienced another troubling vision that may bear on the fate of this place."
    },

    {
        id = "NF_UnhatchedA",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "Temple Eggs",
        master = "The Unhatched",
        text = "I should gather the missing stone eggs and return them where they belong."
    },

    {
        id = "NF_Unhatched",
        name = "The Unhatched",
        category = "Main Quest",
        subcategory = "The Unhatched",
        master = "The Unhatched",
        text = "I should continue my search for the Unhatched and learn more of the trouble surrounding it."
    },

    {
        id = "NF_DreamOne",
        name = "A Prophecy Disrupted",
        category = "Main Quest",
        subcategory = "Dream Visions",
        master = "The Unhatched",
        text = "I witnessed a strange vision that may offer clues to the greater mystery."
    },

    {
        id = "NF_DreamTwo",
        name = "Raised in the Shadow",
        category = "Main Quest",
        subcategory = "Dream Visions",
        master = "The Unhatched",
        text = "I passed through another unsettling vision tied to the mystery before me."
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
-- Quest count: 12