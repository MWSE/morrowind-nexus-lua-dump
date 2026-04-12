local self = require('openmw.self')

local quests = {

    {
        id = "dd19_escaped_prisoner_1",
        name = "Ebonheart Underworks: The Escaped Prisoner",
        category = "Imperial Legion",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A guard in the Ebonheart sewers is searching for an escaped prisoner and may need assistance."
    },

    {
        id = "dd19_escaped_prisoner_2",
        name = "Ebonheart Underworks: The Escaped Prisoner",
        category = "Imperial Cult",
        subcategory = "Ebonheart",
        master = "Ebonheart Underworks",
        text = "A ring found in the sewers bears a curious engraving that may lead to its rightful owner."
    },

    {
        id = "dd19_escaped_prisoner",
        name = "Ebonheart Underworks: The Escaped Prisoner",
        category = "Imperial Legion",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "An escaped prisoner is trapped in the Ebonheart sewers, and I have become involved in his predicament."
    },

    {
        id = "dd19_e_corruption_tg",
        name = "Ebonheart Underworks: Corruption",
        category = "Thieves Guild",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A Thieves Guild contact has asked me to interfere with a questionable ebony shipment in the Ebonheart sewers."
    },

    {
        id = "dd19_e_corruption",
        name = "Ebonheart Underworks: Corruption",
        category = "East Empire Company",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A suspicious East Empire Company man in the Ebonheart sewers has offered me discreet work involving ebony cargo."
    },

    {
        id = "dd19_naked_drunk4",
        name = "Ebonheart Underworks: The Drunk Legionnaire",
        category = "Imperial Legion",
        subcategory = "Skyrim Mission",
        master = "Ebonheart Underworks",
        text = "I have calmed a missing legionnaire in the sewers and should bring word back to his wife."
    },

    {
        id = "dd19_mushroomancy",
        name = "Ebonheart Underworks: Fungi Voodoo",
        category = "Miscellaneous",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "An odd patch of mushrooms in the Ebonheart sewers seems worth a closer look."
    },

    {
        id = "dd19_naked_drunk2",
        name = "Ebonheart Underworks: The Drunk Legionnaire",
        category = "Imperial Legion",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A drunken legionnaire in the sewers has mistaken me for an enemy and caused a commotion."
    },

    {
        id = "dd19_naked_drunk3",
        name = "Ebonheart Underworks: The Drunk Legionnaire",
        category = "Imperial Legion",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "Inglam's axe bears an inscription that may be of interest."
    },

    {
        id = "dd19_naked_drunk",
        name = "Ebonheart Underworks: The Drunk Legionnaire",
        category = "Imperial Legion",
        subcategory = "Skyrim Mission",
        master = "Ebonheart Underworks",
        text = "Eiruki Hearth-Healer has asked me to find her missing husband somewhere in the Ebonheart sewers."
    },

    {
        id = "dd19_knownbug",
        name = "Ebonheart Underworks: Known Bug",
        category = "Miscellaneous",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A strange old man in the sewers has told me about his pet shalk and its unusual appetite."
    },

    {
        id = "dd01_jour01_1",
        name = "Shal Overgrown: Telura Ulver's Research",
        category = "Miscellaneous",
        subcategory = "Sadrith Mora",
        master = "Ebonheart Underworks",
        text = "Telura Ulver's research concerns an unusual problem that may merit investigation."
    },

    {
        id = "dd19_CaveIn",
        name = "Ebonheart Underworks: The Cave-in",
        category = "Miscellaneous",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "Someone has been trapped by a cave-in in the Ebonheart sewers and may need help."
    },

    {
        id = "dd19_TL_01",
        name = "Ebonheart Underworks: Twin Lamps",
        category = "Twin Lamps",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "I have discovered a Twin Lamps safehouse in the Ebonheart sewers and may be able to aid its occupants."
    },

    {
        id = "dd19_TL_02",
        name = "Ebonheart Underworks: The Slavehunter",
        category = "Twin Lamps",
        subcategory = "Ebonheart Sewers",
        master = "Ebonheart Underworks",
        text = "A slavehunter in the Ebonheart sewers is looking for a nearby safehouse and may prove dangerous."
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