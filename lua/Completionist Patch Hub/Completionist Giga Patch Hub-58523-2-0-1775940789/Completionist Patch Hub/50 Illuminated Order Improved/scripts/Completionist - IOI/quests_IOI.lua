local self = require('openmw.self')
local quests = {

    {
        id = "OR_CosmologyLesson",
        name = "Cosmology Lesson",
        category = "Illuminated Order",
        subcategory = "Barataria",
        master = "Illuminated Order Improved",
        text = "Consult a strange device to learn about the heavens."
    },

    {
        id = "OR_sentbarataria",
        name = "Illuminated Order: Journey to Barataria",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Travel to Barataria and report to a member of the Order."
    },

    {
        id = "OR_sentfionnovar",
        name = "Illuminated Order: Travel to Fionnovar",
        category = "Illuminated Order",
        subcategory = "Fionnovar",
        master = "Illuminated Order Improved",
        text = "Travel to a hidden Order stronghold and seek new instructions."
    },

    {
        id = "OR_becomealiche",
        name = "The Ritual of Becoming",
        category = "Illuminated Order",
        subcategory = "Lich Studies",
        master = "Illuminated Order Improved",
        text = "Learn what is required to undergo the Ritual of Becoming."
    },

    {
        id = "OR_vampire",
        name = "It's In The Blood",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Decide whether to embrace or avoid a dangerous affliction."
    },

    {
        id = "OR_join1",
        name = "Lich or Lunatic?",
        category = "Miscellaneous",
        subcategory = "",
        master = "Illuminated Order Improved",
        text = "Investigate a disturbed recluse who claims to be pursuing lichdom."
    },

    {
        id = "OR_TT1",
        name = "Illuminated Order: Lies, Damnable Lies",
        category = "Illuminated Order",
        subcategory = "Thuvien Demnevanni",
        master = "Illuminated Order Improved",
        text = "Deliver a dubious message to a known liar."
    },

    {
        id = "OR_TT2",
        name = "Illuminated Order: Chaining the Spirit",
        category = "Illuminated Order",
        subcategory = "Thuvien Demnevanni",
        master = "Illuminated Order Improved",
        text = "Capture a spirit and return it to the Order for questioning."
    },

    {
        id = "OR_TT3",
        name = "Illuminated Order: Bone of Contention",
        category = "Illuminated Order",
        subcategory = "Thuvien Demnevanni",
        master = "Illuminated Order Improved",
        text = "Recover an ancient bone sought by the Order."
    },

    {
        id = "OR_TT4",
        name = "Illuminated Order: Journey to Scourge Barrow",
        category = "Illuminated Order",
        subcategory = "Thuvien Demnevanni",
        master = "Illuminated Order Improved",
        text = "Enter Scourge Barrow and retrieve an item for the Order."
    },

    {
        id = "OR_D_1",
        name = "Illuminated Order: A New Vampiric Threat",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Search for notes concerning a troubling vampiric matter."
    },

    {
        id = "OR_D_2",
        name = "Illuminated Order: Hunter's Hunted",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Deal with a hunter who has become entangled in the Order's affairs."
    },

    {
        id = "OR_D_4",
        name = "Illuminated Order: Pool of Forgetfulness",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Obtain water from a strange pool to resolve a growing suspicion."
    },

    {
        id = "OR_D_5",
        name = "Illuminated Order: Cuts Like a Knife",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Retrieve a peculiar dagger for the Order to study."
    },

    {
        id = "OR_D_3",
        name = "Illuminated Order: Books Gone Awry",
        category = "Illuminated Order",
        subcategory = "Decius Mus",
        master = "Illuminated Order Improved",
        text = "Recover a missing book shipment meant for the Order."
    },

    {
        id = "OR_R_2",
        name = "Illuminated Order: Waking the Dreamer",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Question a captive sleeper and report the findings."
    },

    {
        id = "OR_R_1",
        name = "Illuminated Order: The Wererat at Torvayn Lighthouse",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Investigate reports of a wererat at a remote lighthouse."
    },

    {
        id = "OR_R_3",
        name = "Illuminated Order: Ashes to Ashes",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Collect ash statues for the Order's research."
    },

    {
        id = "OR_R_4",
        name = "Illuminated Order: Stories Bones Tell",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Recover lost plans after the Order uncovers a new lead."
    },

    {
        id = "OR_R_5",
        name = "Illuminated Order: A Skull, a Book, a Tablet, and an Island",
        category = "Illuminated Order",
        subcategory = "Romana Corvus",
        master = "Illuminated Order Improved",
        text = "Investigate a mysterious island and gather several important relics."
    },

    {
        id = "OR_S_1",
        name = "Illuminated Order: Lair of a Lich",
        category = "Illuminated Order",
        subcategory = "Selrach Otived",
        master = "Illuminated Order Improved",
        text = "Confront a lich in search of knowledge about a forbidden ritual."
    },

    {
        id = "OR_S_2",
        name = "Illuminated Order: Stories Ghosts Tell",
        category = "Illuminated Order",
        subcategory = "Selrach Otived",
        master = "Illuminated Order Improved",
        text = "Speak with a summoned spirit to learn more about the Order's past."
    },

    {
        id = "OR_S_3",
        name = "Illuminated Order: Shadows and Dust",
        category = "Illuminated Order",
        subcategory = "Selrach Otived",
        master = "Illuminated Order Improved",
        text = "Track down another lich and seek answers in its lair."
    },

    {
        id = "OR_S_4",
        name = "Illuminated Order: Tomes and Tombs",
        category = "Illuminated Order",
        subcategory = "Selrach Otived",
        master = "Illuminated Order Improved",
        text = "Recover a book that may clarify the Ritual of Becoming."
    },

    {
        id = "OR_S_5",
        name = "Illuminated Order: Confirm the Ritual of Becoming",
        category = "Illuminated Order",
        subcategory = "Selrach Otived",
        master = "Illuminated Order Improved",
        text = "Journey to the ritual site and confirm what is needed to proceed."
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

-- Quest count: 25
