local self = require('openmw.self')

local quests = {

    {
        id = "VV23_ArmourRecovery",
        name = "Find The Missing Guardian",
        category = "Side Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "A guardian of the Monastery of Order has gone missing, and I have been asked to look into their disappearance.",
    },

    {
        id = "VV23_SheoRift",
        name = "Investigate the Daedric Energies",
        category = "Side Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "The Monastery has concerns about a dangerous rift nearby, and I have been asked to investigate it.",
    },

    {
        id = "VV23_TGDwemTurq",
        name = "Retrieve a Turquoise of Lies",
        category = "Faction",
        subcategory = "Thieves Guild",
        master = "Greymarch Dawn",
        text = "A job posted in the Pit has sent me in search of a rare Dwemer mineral hidden beneath Suran.",
    },

    {
        id = "VV23_TGInanius",
        name = "Retrieve the dead drop from Inanius Mine",
        category = "Faction",
        subcategory = "Thieves Guild",
        master = "Greymarch Dawn",
        text = "A Thieves Guild job has sent me to Inanius Mine to recover a misplaced item from a dead drop.",
    },

    {
        id = "VV23_TGTombIllusion",
        name = "Retrieve the Gem of Greedbane",
        category = "Faction",
        subcategory = "Thieves Guild",
        master = "Greymarch Dawn",
        text = "A Thieves Guild notice has directed me to recover the Gem of Greedbane from an old tomb.",
    },

    {
        id = "VV23_slaythegolem",
        name = "Slay a Crystal Golem",
        category = "Side Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "The Monastery has posted a warning about a dangerous crystal golem, and I have been asked to deal with it.",
    },

    {
        id = "vv23_DwrvBarrel",
        name = "Crystal-Clear Waters",
        category = "Side Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "A researcher at the Monastery needs a sample of unusual water from nearby Dwemer ruins.",
    },

    {
        id = "vv23_codex_chaos",
        name = "Brushstrokes of Chaos",
        category = "Main Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "A cryptic message has set me on the trail of a mysterious figure tied to unrest within the Monastery of Order.",
    },

    {
        id = "vv23_guilty",
        name = "A Guilty Conscience",
        category = "Main Quest",
        subcategory = "A Guilty Conscience",
        master = "Greymarch Dawn",
        text = "I found a prisoner within the Monastery of Order whose story raises troubling questions about the Codex.",
    },

    {
        id = "vv23_guilty_brother",
        name = "A Guilty Conscience",
        category = "Main Quest",
        subcategory = "A Guilty Conscience",
        master = "Greymarch Dawn",
        text = "To learn the truth behind Lucien's plight, I have been told to seek out his brother.",
    },

    {
        id = "vv23_guilty_escape",
        name = "A Guilty Conscience",
        category = "Main Quest",
        subcategory = "A Guilty Conscience",
        master = "Greymarch Dawn",
        text = "Lucien wants to escape the Monastery of Order, but first I must find a way to break the enchantment that binds him.",
    },

    {
        id = "vv23_introductions",
        name = "Introductions are in Order",
        category = "Main Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "After arriving at the strange tower, I was welcomed inside and introduced to its unusual purpose.",
    },

    {
        id = "vv23_opposites",
        name = "Opposites Attract",
        category = "Side Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "A simple delivery within the Monastery has drawn me into a personal matter between two of its residents.",
    },

    {
        id = "vv23_tg_intro",
        name = "An Unbreakable Lock",
        category = "Main Quest",
        subcategory = "Suran",
        master = "Greymarch Dawn",
        text = "The Thieves Guild has offered me work connected to a mysterious tower that appeared beneath Suran.",
    },

    {
        id = "vv23_vault",
        name = "Heart of Order, Soul of Chaos",
        category = "Main Quest",
        subcategory = "Monastery of Order",
        master = "Greymarch Dawn",
        text = "With a chaotic artifact in hand, I must return to the Monastery and confront the fate of the Codex.",
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

-- Quest count: 15
