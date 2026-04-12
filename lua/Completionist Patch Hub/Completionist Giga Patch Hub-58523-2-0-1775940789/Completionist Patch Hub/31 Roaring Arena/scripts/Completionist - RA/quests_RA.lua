local self = require('openmw.self')

local quests = {

    {
        id = "GVEA_VArena_Rank1",
        name = "Vivec Arena: Pit-Dog",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I have begun my career in the Vivec Arena and must prove myself in the pit."
    },

    {
        id = "GVEA_VArena_Rank2",
        name = "Vivec Arena: Guar-Bait",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I continue to rise through the ranks of the Vivec Arena by earning victories in the pit."
    },

    {
        id = "GVEA_VArena_Rank3",
        name = "Vivec Arena: Sunnabet",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "My standing in the Vivec Arena grows as I press onward through the contests of the pit."
    },

    {
        id = "GVEA_VArena_Rank4",
        name = "Vivec Arena: Kogobet",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I have earned a higher place in the Vivec Arena and must keep fighting to advance."
    },

    {
        id = "GVEA_VArena_Rank5",
        name = "Vivec Arena: Ash-Tempered",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I am advancing through the harsher ranks of the Vivec Arena and must continue to prove my worth."
    },

    {
        id = "GVEA_VArena_Rank6",
        name = "Vivec Arena: Seyda Molag",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "My progress in the Vivec Arena has brought me to a more honored rank, with greater trials ahead."
    },

    {
        id = "GVEA_VArena_Rank7",
        name = "Vivec Arena: Molag Ouada",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I have reached one of the higher ranks of the Vivec Arena and must continue my ascent."
    },

    {
        id = "GVEA_VArena_Rank8",
        name = "Vivec Arena: Blight-Bane",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "My victories in the Vivec Arena have earned me renown, but further contests still await."
    },

    {
        id = "GVEA_VArena_Rank9",
        name = "Vivec Arena: Almsivi Avenger",
        category = "Arena",
        subcategory = "Vivec Arena",
        master = "Roaring Arena",
        text = "I stand among the foremost fighters of the Vivec Arena and have nearly reached the top."
    },

    {
        id = "GVEA_Beast_Mnlnd",
        name = "Beasts of Morrowind",
        category = "Arena",
        subcategory = "Beast Procurement",
        master = "Roaring Arena",
        text = "Brotnar has asked me to help secure new beasts for the Vivec Arena."
    },

    {
        id = "GVEA_Beast_BMrkt",
        name = "Beasts of Questionable Origin",
        category = "Arena",
        subcategory = "Beast Procurement",
        master = "Roaring Arena",
        text = "I may be able to help the Vivec Arena acquire some unusual beasts for the pit."
    },

    {
        id = "GVEA_Beast_Sols",
        name = "Beasts of Solstheim",
        category = "Arena",
        subcategory = "Beast Procurement",
        master = "Roaring Arena",
        text = "I have been sent to arrange for beasts from Solstheim to be brought to the Vivec Arena."
    },

    {
        id = "GVEA_Beast_Sky",
        name = "Beasts of Skyrim",
        category = "Arena",
        subcategory = "Beast Procurement",
        master = "Roaring Arena",
        text = "I have been sent to arrange for beasts from Skyrim to be brought to the Vivec Arena."
    },

    {
        id = "GVEA_Beast_Cyr",
        name = "Beasts of Cyrodiil",
        category = "Arena",
        subcategory = "Beast Procurement",
        master = "Roaring Arena",
        text = "I have been sent to arrange for beasts from Cyrodiil to be brought to the Vivec Arena."
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
-- Quest count: 14