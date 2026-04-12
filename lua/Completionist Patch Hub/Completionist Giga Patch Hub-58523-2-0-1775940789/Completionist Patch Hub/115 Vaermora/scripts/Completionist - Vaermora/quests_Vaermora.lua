local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Vaermora
    -- #########################################################################

    {
        id = "fgt_bosmerattack",
        name = "Vaermora: Bosmer Revengeance",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "CUT ENTRY - UN-SKYRIMING THE QUEST."
    },
    {
        id = "FGT_PlayerHome",
        name = "Vaermora: Assisted Foul Murder",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Complete a task for Vaermora."
    },
    {
        id = "FGT_Pyromancer",
        name = "Vaermora: Playing With Fire",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Garyn Flame-Brother, a breton staying at Dreryn's Villa, wishes to ascend his mortal form to become a flame atronach."
    },
    {
        id = "FGT_MissingCup",
        name = "Vaermora: Found and Lost",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Eats-With-Demitasse is an argonian who is missing his cup."
    },
    {
        id = "FGT_GodKilling",
        name = "Vaermora: How Can You Kill A God?",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Complete a task for Vaermora."
    },
    {
        id = "FGT_DaiKatana",
        name = "Vaermora: The Ultimate Sin",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Drakken Sin-Screamer, a distressed dremora hanging out at Dreryn's Villa, is wailing about his destroyed daedric dai-katana."
    },
    {
        id = "FGT_Entrance",
        name = "Vaermora: Patience is a Virtue",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "One has arrived at Vaermora, Walking Stance Hold of the Thrice-Dreamed, however one has been stuck inside a waiting room."
    },
    {
        id = "FGT_Jizarga",
        name = "Vaermora: Rising Force",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Complete a task for Vaermora."
    },
    {
        id = "FGT_EggHunt",
        name = "Vaermora: Retsae Egg Hunt",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Blim-Dim, an argonian taking a nap on Tel Uren, wishes for them to collect the retsae eggs hidden throughout Vaermora."
    },
    {
        id = "fgt_OrcLove",
        name = "Vaermora: Love in the Time of Orcs",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "A very inebriated Crimson Argonaut named Fim-Fob in Dreryn's Villa is trying to get two orcs to stop arguing."
    },
    {
        id = "FGT_Racers",
        name = "Vaermora: Big Game Hunter",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Goren Bethnal is a dunmer in Dreryn's Villa who says he will pay them 100 gold for every cliff racer plume one bring him."
    },
    {
        id = "FGT_Well",
        name = "Vaermora: All's Well That Ends Well",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Complete a task for Vaermora."
    },
    {
        id = "FGT_MQ1",
        name = "Vaermora: Blood Runs Vermillion",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Complete a task for Vaermora."
    },
    {
        id = "FGT_MQ2",
        name = "Vaermora: A Tribe Mourned",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Dagoth Sarys of the Unmourned Necropolis has tasked them with retrieving a sixth house amulet for him as a show of their loyalty."
    },
    {
        id = "FGT_MQ3",
        name = "Vaermora: Can't Beat 'em? Make 'em Join You!",
        category = "Miscellaneous",
        subcategory = "",
        master = "Vaermora", text = "Theris Uren has hired them as a mercenary to take care of some business that he needs done."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Vaermora data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 15
