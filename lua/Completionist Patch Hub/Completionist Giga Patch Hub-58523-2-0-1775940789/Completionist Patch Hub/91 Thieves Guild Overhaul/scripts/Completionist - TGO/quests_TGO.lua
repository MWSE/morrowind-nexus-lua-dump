local self = require('openmw.self')

local quests = {

    {
        id = "G93_BalMolagPauper",
        name = "Thieves' Guild: Bal Molagmer, A Room of One's Own",
        category = "Thieves Guild",
        subcategory = "Bal Molagmer",
        master = "Thieves Guild Overhaul",
        text = "Recover documents to help a dispossessed pauper."
    },

    {
        id = "AA_PlunderDungeon",
        name = "Tel Fyr: Plundering the Dungeon",
        category = "Miscellaneous",
        subcategory = "Tel Fyr",
        master = "Thieves Guild Overhaul",
        text = "Explore a dangerous dungeon beneath Tel Fyr."
    },

    {
        id = "TG_FreePrisoners",
        name = "Thieves' Guild: Free the Prisoners",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Free imprisoned guild members for a local operation."
    },

    {
        id = "G93_BalLoanshark",
        name = "Thieves' Guild: Bal Molagmer, The Loanshark",
        category = "Thieves Guild",
        subcategory = "Bal Molagmer",
        master = "Thieves Guild Overhaul",
        text = "Deliver a book to settle a troubling debt."
    },

    {
        id = "TG_CamonnaGnaar",
        name = "Thieves' Guild: Camonna Tong in Gnaar Mok",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Deal with a local Camonna Tong problem."
    },

    {
        id = "G93_BalDiamond",
        name = "Thieves' Guild: Bal Molagmer, Diamonds",
        category = "Thieves Guild",
        subcategory = "Bal Molagmer",
        master = "Thieves Guild Overhaul",
        text = "Steal valuable diamonds for a guild contact."
    },

    {
        id = "TG_RearGuard",
        name = "Thieves' Guild: The Rear Guard",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Steal a book for the guild."
    },

    {
        id = "TG_Smuggling",
        name = "Thieves' Guild: Taking Over the Smuggling Operation",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Secure support for a smuggling operation."
    },

    {
        id = "TG_Delivery",
        name = "Thieves' Guild: Deliver a Letter",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Deliver a letter to a senior guild contact."
    },

    {
        id = "TG_Convince",
        name = "Thieves' Guild: Convince Nadene Rotheran",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Persuade a local resident to cooperate with the guild."
    },

    {
        id = "TG_Caryarel",
        name = "Thieves' Guild: Kill Caryarel",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Remove a troublesome thief from local affairs."
    },

    {
        id = "TG_Clutter",
        name = "Thieves' Guild: Collecting Clutter",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Collect a set of stolen goblets for the guild."
    },

    {
        id = "TG_Hlaalu",
        name = "Thieves' Guild: Bribing the Hlaalu",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Deliver a bribe to secure local support."
    },

    {
        id = "TG_Herder",
        name = "Thieves' Guild: The Herder's Crook",
        category = "Thieves Guild",
        subcategory = "Gnaar Mok",
        master = "Thieves Guild Overhaul",
        text = "Steal a prized staff for the guild."
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
