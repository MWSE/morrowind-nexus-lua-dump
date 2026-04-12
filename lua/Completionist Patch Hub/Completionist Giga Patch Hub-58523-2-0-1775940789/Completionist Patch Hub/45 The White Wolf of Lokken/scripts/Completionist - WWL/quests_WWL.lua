local self = require('openmw.self')

local quests = {

    {
        id = "BT_WhiteWolf",
        name = "The White Wolf of Lokken",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Investigate rumors about a white wolf near Lokken."
    },

    {
        id = "BT_LokkenTrouble",
        name = "Trouble in Lokken",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Speak with the people of Lokken about their troubles."
    },

    {
        id = "BT_MissingHunters",
        name = "Missing Hunters",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Look for hunters who did not return."
    },

    {
        id = "BT_FrozenCave",
        name = "The Frozen Cave",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Search a cave near Lokken."
    },

    {
        id = "BT_WolfTracks",
        name = "Wolf Tracks",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Follow tracks found near the village."
    },

    {
        id = "BT_SkaalMessage",
        name = "Message for the Skaal",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Deliver a message to the Skaal."
    },

    {
        id = "BT_IceDen",
        name = "The Ice Den",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Investigate a den in the ice."
    },

    {
        id = "BT_HunterCamp",
        name = "Hunter's Camp",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Check on a hunter's camp."
    },

    {
        id = "BT_LokkenSupplies",
        name = "Supplies for Lokken",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Bring supplies to Lokken."
    },

    {
        id = "BT_SnowBeasts",
        name = "Snow Beasts",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Deal with beasts near the village."
    },

    {
        id = "BT_IceLake",
        name = "The Frozen Lake",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Investigate the frozen lake."
    },

    {
        id = "BT_WolfDen",
        name = "Wolf Den",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Search a wolf den."
    },

    {
        id = "BT_SkaalRequest",
        name = "A Skaal Request",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Help the Skaal with a request."
    },

    {
        id = "BT_LokkenGuard",
        name = "Guard Duty",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Assist the guards of Lokken."
    },

    {
        id = "BT_FinalHunt",
        name = "The Final Hunt",
        category = "Lokken Quests",
        subcategory = "",
        master = "The White Wolf of Lokken",
        text = "Prepare for a hunt near Lokken."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending WWL Data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
