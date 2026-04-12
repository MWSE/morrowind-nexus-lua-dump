local self = require('openmw.self')
local quests = {
    {
        id = "dgb_journal_shipwrecked",
        name = "Where There's Smoke, There's Skooma",
        category = "Smuggling",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Check on a missing smuggling shipment and recover what can be salvaged."
    },

    {
        id = "dgb_journal_bloodbath",
        name = "Bloodbath in Bo-muul",
        category = "Imperial Legion",
        subcategory = "Larrius Varro",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Eliminate a group of smugglers and recover a hidden package."
    },

    {
        id = "dgb_journal_island",
        name = "Smuggler's Island",
        category = "Smuggling",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Pick up a smuggled package from a contact on a coastal island."
    },

    {
        id = "dgb_journal_forged",
        name = "Forging Larrius Varro's Demise",
        category = "Intrigue",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Obtain forged evidence and deliver it to the proper authority."
    },

    {
        id = "dgb_journal_dwemer",
        name = "Dwemer Elements of Surprise",
        category = "Dwemer",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Search a Dwemer ruin for a valuable artifact of interest."
    },

    {
        id = "dgb_journal_varro",
        name = "Larrius Varro Gives a Little Bounty",
        category = "Imperial Legion",
        subcategory = "Larrius Varro",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Take on a bounty contract against a local target."
    },

    {
        id = "dgb_journal_house",
        name = "Sale of Dura gra-Bol's House",
        category = "Property",
        subcategory = "Balmora",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Inquire about purchasing a house that has been put up for sale."
    },

    {
        id = "dgb_journal_deal",
        name = "In Cahoots with Smugglers in Balmora",
        category = "Smuggling",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Make an arrangement with a smuggler and formalize the terms."
    },

    {
        id = "dgb_journal_rat",
        name = "A Rat Among Us",
        category = "Smuggling",
        subcategory = "Dura gra-Bol",
        master = "Dura Gra-Bol's House Reclaimed",
        text = "Help identify a suspected informant within a smuggling operation."
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
