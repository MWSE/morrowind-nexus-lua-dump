local self = require('openmw.self')
local quests = {

    {
        id = "VA_QuarraClan",
        name = "Joining the Quarra Clan",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has set me a task that may earn me a place within the Quarra clan."
    },

    {
        id = "QC_Eleven",
        name = "The Temple's Last Stand",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has ordered me to deal with a Temple threat gathering against the clan."
    },

    {
        id = "QC_Aundae",
        name = "The Fall of Clan Aundae",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Before I can rise further in the Quarra clan, I must carry out a final task against a rival vampire power."
    },

    {
        id = "QC_Three",
        name = "Escort Morana to Druscashti",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "I have been charged with finding Morana and bringing her safely to Druscashti."
    },

    {
        id = "QC_Seven",
        name = "Clear the Daedric Ruins",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra wants the nearby daedric ruins cleared to make the area safer for the clan."
    },

    {
        id = "QC_Eight",
        name = "Purge the Maar Gan Shrine",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has ordered me to strike at hostile worshippers gathering near Maar Gan."
    },

    {
        id = "QC_Igna1",
        name = "Igna's New Clothes",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Igna has asked me to bring her a selection of fine clothing."
    },

    {
        id = "QC_Igna2",
        name = "Igna's Perfume",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Igna wants me to obtain a supply of Telvanni bug musk for her."
    },

    {
        id = "QC_Berne",
        name = "Destroy Raxle Berne",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has sent me to eliminate a dangerous rival from Clan Berne."
    },

    {
        id = "QC_Four",
        name = "Pelf's Family",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Pelf has begun pursuing a strange scheme involving members of his own family."
    },

    {
        id = "QC_Five",
        name = "Pelf's Boots",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Pelf has asked me to find him a strongly enchanted pair of boots."
    },

    {
        id = "QC_Nine",
        name = "Neloth's Hlaalu Bargain",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has sent me to Master Neloth to assist with a matter involving House Hlaalu."
    },

    {
        id = "QC_Coup",
        name = "The Quarra Coup",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Siri has approached me with a dangerous proposal that could change the leadership of Clan Quarra."
    },

    {
        id = "QC_One",
        name = "Slay Branas Hlaaran",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Pelf has ordered me to deal with a Temple hireling working against the clan."
    },

    {
        id = "QC_Two",
        name = "Supplies for Clan Quarra",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Pelf has sent me to Sadrith Mora to arrange a delivery of goods for Clan Quarra."
    },

    {
        id = "QC_Six",
        name = "Kill Pelf",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has commanded me to hunt down Pelf before he can leave Druscashti."
    },

    {
        id = "QC_Ten",
        name = "Hunt the Aundae Survivors",
        category = "Faction",
        subcategory = "Clan Quarra",
        master = "Quarra Clan Refreshed",
        text = "Volrina Quarra has tasked me with finding and destroying a group of Aundae vampires."
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

-- Quest count: 17
