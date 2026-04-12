local self = require('openmw.self')

local quests = {

    {
        id = "ORC_Provisions",
        name = "Orc Stronghold: Provisions",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Collect the first shipment of provisions from the Legion for an Orc stronghold."
    },
    {
        id = "ORC_StupidRock",
        name = "Orc Stronghold: The Stupid Rock",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Hear an Orc Blood-Kin's tale involving a diamond and a rival clan."
    },
    {
        id = "ORC_Promotion",
        name = "Orc Stronghold: Orcish Promotion",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Prove your worth to an Orc who doubts your fitness as Blood-Kin."
    },
    {
        id = "ORC_Propylon",
        name = "Orc Stronghold: The Propylon Index",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Recover a propylon index stolen from the Orc stronghold by Ashlanders."
    },
    {
        id = "ORC_Malacath",
        name = "Orc Stronghold: Serving Malacath",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Serve the Daedric Prince Malacath at the behest of a pious Orc warrior."
    },
    {
        id = "IL_NewFort",
        name = "Imperial Legion: A new Fort",
        category = "Faction",
        subcategory = "Imperial Legion",
        master = "The Fires of Orc",
        text = "Travel to a Dunmer fortress to negotiate an Orc clan's entry into the Imperial Legion."
    },
    {
        id = "ORC_Dowry",
        name = "Orc Stronghold: The Dowry",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Help a Blood-Kin deal with an unwanted marriage arrangement."
    },
    {
        id = "ORC_Kwama",
        name = "Orc Stronghold: The Blighted Mine",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Deal with a blight threat affecting the kwama mine near the Orc stronghold."
    },
    {
        id = "ORC_Book",
        name = "Orc Stronghold: Sloadic Language",
        category = "Faction",
        subcategory = "Orc Stronghold",
        master = "The Fires of Orc",
        text = "Retrieve two books for a Blood-Kin to prove Orcish scholarly capability."
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
