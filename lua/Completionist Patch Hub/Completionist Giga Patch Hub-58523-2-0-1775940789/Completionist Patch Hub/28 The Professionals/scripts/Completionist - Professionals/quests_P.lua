local self = require('openmw.self')
local quests = {
    {
        id = "TP_Caravaner_Prep1",
        name = "The Caravaner",
        category = "The Professionals",
        subcategory = "Caravaner",
        master = "The Professionals",
        text = "I agreed to help with early arrangements tied to a caravaner's work."
    },

    {
        id = "TP_Caravaner_Prep2",
        name = "The Caravaner",
        category = "The Professionals",
        subcategory = "Caravaner",
        master = "The Professionals",
        text = "I am assisting with further preparations for a caravaner's business."
    },

    {
        id = "TP_Glassworker",
        name = "The Glassmaker",
        category = "The Professionals",
        subcategory = "Glassmaker",
        master = "The Professionals",
        text = "I agreed to aid a glassmaker with a matter concerning her craft."
    },

    {
        id = "TP_Caravaner",
        name = "The Caravaner",
        category = "The Professionals",
        subcategory = "Caravaner",
        master = "The Professionals",
        text = "I agreed to help a caravaner with troubles along the trade roads."
    },

    {
        id = "TP_Monk_P1",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I set out on one part of a monk's pilgrimage and must complete the rite."
    },

    {
        id = "TP_Monk_P2",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I set out on another part of a monk's pilgrimage and must complete the rite."
    },

    {
        id = "TP_Monk_P3",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I set out on another part of a monk's pilgrimage and must complete the rite."
    },

    {
        id = "TP_Monk_P4",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I set out on another part of a monk's pilgrimage and must complete the rite."
    },

    {
        id = "TP_Monk_P5",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I set out on another part of a monk's pilgrimage and must complete the rite."
    },

    {
        id = "TP_Savant",
        name = "The Savant",
        category = "The Professionals",
        subcategory = "Savant",
        master = "The Professionals",
        text = "I agreed to assist a savant with a scholarly matter."
    },

    {
        id = "TP_Monk",
        name = "The Monk",
        category = "Pilgrimage",
        subcategory = "Monk",
        master = "The Professionals",
        text = "I have undertaken a monk's path of pilgrimage and reflection."
    },

    {
        id = "TP_Chandler_Ad1",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I am helping a chandler place word of his wares in Ald-ruhn."
    },

    {
        id = "TP_Chandler_Ad2",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I am helping a chandler place word of his wares in Ald-ruhn."
    },

    {
        id = "TP_Chandler_Ad3",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I am helping a chandler place word of his wares in Ald-ruhn."
    },

    {
        id = "TP_Chandler_Ad4",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I am helping a chandler place word of his wares in Ald-ruhn."
    },

    {
        id = "TP_Chandler_Ad5",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I am helping a chandler place word of his wares in Ald-ruhn."
    },

    {
        id = "TP_Bookbinder",
        name = "The Bookbinder",
        category = "The Professionals",
        subcategory = "Bookbinder",
        master = "The Professionals",
        text = "I agreed to help a bookbinder with work related to the making of books."
    },

    {
        id = "TP_Medico_P1",
        name = "The Medico",
        category = "The Professionals",
        subcategory = "Medico",
        master = "The Professionals",
        text = "I am carrying out one part of a medico's instructions."
    },

    {
        id = "TP_Medico_P2",
        name = "The Medico",
        category = "The Professionals",
        subcategory = "Medico",
        master = "The Professionals",
        text = "I am carrying out one part of a medico's instructions."
    },

    {
        id = "TP_Medico_P3",
        name = "The Medico",
        category = "The Professionals",
        subcategory = "Medico",
        master = "The Professionals",
        text = "I am carrying out one part of a medico's instructions."
    },

    {
        id = "TP_Chandler",
        name = "The Chandler",
        category = "The Professionals",
        subcategory = "Chandler",
        master = "The Professionals",
        text = "I agreed to help a chandler with the sale of his candles."
    },

    {
        id = "TP_Medico",
        name = "The Medico",
        category = "The Professionals",
        subcategory = "Medico",
        master = "The Professionals",
        text = "I agreed to assist a medico with a matter of healing and care."
    },

    {
        id = "TP_Trader",
        name = "The Trader",
        category = "The Professionals",
        subcategory = "Trader",
        master = "The Professionals",
        text = "I agreed to help a trader with business among the Ashlanders."
    },

    {
        id = "TP_Artificer_B",
        name = "The Artificer",
        category = "The Professionals",
        subcategory = "Artificer",
        master = "The Professionals",
        text = "I am handling one part of an artificer's commission."
    },

    {
        id = "TP_Artificer_C",
        name = "The Artificer",
        category = "The Professionals",
        subcategory = "Artificer",
        master = "The Professionals",
        text = "I am handling one part of an artificer's commission."
    },

    {
        id = "TP_Artificer_D",
        name = "The Artificer",
        category = "The Professionals",
        subcategory = "Artificer",
        master = "The Professionals",
        text = "I am handling one part of an artificer's commission."
    },

    {
        id = "TP_Clothier_A",
        name = "The Clothier",
        category = "The Professionals",
        subcategory = "Clothier",
        master = "The Professionals",
        text = "I am carrying out one part of a clothier's work."
    },

    {
        id = "TP_Clothier_B",
        name = "The Clothier",
        category = "The Professionals",
        subcategory = "Clothier",
        master = "The Professionals",
        text = "I am carrying out one part of a clothier's work."
    },

    {
        id = "TP_Clothier_C",
        name = "The Clothier",
        category = "The Professionals",
        subcategory = "Clothier",
        master = "The Professionals",
        text = "I am carrying out one part of a clothier's work."
    },

    {
        id = "TP_Artificer",
        name = "The Artificer",
        category = "The Professionals",
        subcategory = "Artificer",
        master = "The Professionals",
        text = "I agreed to help an artificer with a matter related to a crafted device."
    },

    {
        id = "TP_Clothier",
        name = "The Clothier",
        category = "The Professionals",
        subcategory = "Clothier",
        master = "The Professionals",
        text = "I agreed to assist a clothier with work related to fine garments."
    },

    {
        id = "TP_Gardener",
        name = "The Gardener",
        category = "The Professionals",
        subcategory = "Gardener",
        master = "The Professionals",
        text = "I agreed to help a gardener with work involving plants and cultivation."
    },

    {
        id = "TP_Miner",
        name = "The Miner",
        category = "The Professionals",
        subcategory = "Miner",
        master = "The Professionals",
        text = "I agreed to help a miner with trouble deep in the mine."
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

-- Quest count: 33
