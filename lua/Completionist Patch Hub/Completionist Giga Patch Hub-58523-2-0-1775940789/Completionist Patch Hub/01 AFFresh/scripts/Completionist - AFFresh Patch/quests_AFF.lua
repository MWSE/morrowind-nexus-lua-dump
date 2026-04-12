local self = require('openmw.self')

local quests = {

    {
        id = "AF_BitterSmugglers",
        name = "Bitter Smugglers",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Deal with smugglers along the Bitter Coast."
    },

    {
        id = "AF_RithleenRecipes",
        name = "Rithleen's Recipes",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Gather ingredients for Rithleen."
    },

    {
        id = "AF_BlueDevils",
        name = "The Blue Devils",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Investigate trouble involving the Blue Devils."
    },

    {
        id = "AF_FlyLikeARacer",
        name = "Fly Like a Racer",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help with a strange racer problem."
    },

    {
        id = "AF_NotSoGreatEscape",
        name = "Not So Great Escape",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        master = "AFFresh",
        text = "Assist with an escape plan."
    },

    {
        id = "AF_EnlightenmentCalicius",
        name = "The Enlightenment of Calicius",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Calicius with a personal matter."
    },

    {
        id = "AF_LuckyMessup",
        name = "The Lucky Mess-Up",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Fix a mistake that caused trouble."
    },

    {
        id = "AF_NephataNeeds",
        name = "Nephata's Needs",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Nephata with a request."
    },

    {
        id = "AF_LittleThings",
        name = "All the Little Things",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Take care of several small tasks."
    },

    {
        id = "AF_HulsHull",
        name = "Hul's Hull",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Speak with Hul about a problem."
    },

    {
        id = "AF_RavirrProposal",
        name = "Ra'virr's Proposal",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Talk to Ra'virr about a request."
    },

    {
        id = "AF_TraceTerinde",
        name = "Trace Terinde",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Look for Terinde."
    },

    {
        id = "AF_BraggingRights",
        name = "Bragging Rights",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Settle a dispute over bragging rights."
    },

    {
        id = "AF_HulsSkulls",
        name = "Hul's Skulls",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Hul recover something."
    },

    {
        id = "AF_LetterForDarvam",
        name = "A Letter for Darvam",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Deliver a letter to Darvam."
    },

    {
        id = "AF_AltmerMystique",
        name = "The Altmer Mystique",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Speak with an Altmer about a matter."
    },

    {
        id = "AF_AldruhnNeedsWater",
        name = "Ald'ruhn's Water Mystery",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Investigate a problem in Ald'ruhn."
    },

    {
        id = "AF_AssassinConscience",
        name = "The Assassin's Conscience",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Look into an assassin's situation."
    },

    {
        id = "AF_HealersCuriousity",
        name = "A Healer's Curiousity",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Speak with a healer about a problem."
    },

    {
        id = "AF_MixedUnits",
        name = "Mixed Up Unit Tactics",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help with a military matter."
    },

    {
        id = "AF_KishniEscape",
        name = "Kishni's Escape",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Kishni escape."
    },

    {
        id = "AF_LightWood",
        name = "A Little Light Wood",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        master = "AFFresh",
        text = "Collect some light wood."
    },

    {
        id = "AF_SeydaNeenFishing",
        name = "Fishing Stories",
        category = "Miscellaneous",
        subcategory = "Seyda Neen",
        master = "AFFresh",
        text = "Help with a fishing problem."
    },

    {
        id = "AF_NixHunt",
        name = "The Nix That Got Away",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Look for a missing nix-hound."
    },

    {
        id = "AF_Contrabash",
        name = "Contrabash",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Deal with contraband."
    },

    {
        id = "AF_SearchForNchulem",
        name = "The Search for Nchulem",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Search for Nchulem."
    },

    {
        id = "AF_WhyDontYouWrite",
        name = "Why Don't You Write Me",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Deliver a message."
    },

    {
        id = "AF_NetchLure",
        name = "The Netch Lure",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help lure a netch."
    },

    {
        id = "AF_SiltStriderSupplies",
        name = "Silt Strider Supplies",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Deliver supplies."
    },
    {
        id = "AF_FargothSaysHello",
        name = "Fargoth Says Hello",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Fargoth with a personal grudge."
    },

    {
        id = "AF_FargothForever",
        name = "Fargoth Forever",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Look into Fargoth's troubles in Seyda Neen."
    },
    {
        id = "AFWILL_Vinnus",
        name = "Wilhelm of the Aedra",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Find Wilhelm and learn more about him."
    },

    {
        id = "AFWILL_Erivase",
        name = "Wilhelm and Erivase",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Meet Wilhelm in Vivec and investigate a disturbance."
    },

    {
        id = "AFWILL_Brerayne",
        name = "Wilhelm and Brerayne",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Wilhelm with Brerayne in the Hall of Justice."
    },

    {
        id = "AFWILL_Adanja",
        name = "Wilhelm and Adanja",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Help Wilhelm with Adanja in Pelagiad."
    },

    {
        id = "AFWILL_Solstheim",
        name = "Wilhelm Goes to Solstheim",
        category = "Miscellaneous",
        subcategory = "",
        master = "AFFresh",
        text = "Escort Wilhelm to Solstheim."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending AFF Data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}