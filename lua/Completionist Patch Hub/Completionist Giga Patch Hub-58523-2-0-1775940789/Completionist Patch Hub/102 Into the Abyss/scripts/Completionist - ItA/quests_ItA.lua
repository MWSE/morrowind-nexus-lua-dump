local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Into the Abyss
    -- #########################################################################

    {
        id = "INTA_MG3_The_Soul_Anchors",
        name = "Mages Guild: The Soul Anchors",
        category = "Mages Guild",
        subcategory = "",
        master = "Into the Abyss", text = "Complete a task for Mages Guild."
    },
    {
        id = "INTA_Artifact_for_Jooh",
        name = "An Artifact for Joohius",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "The local shopkeeper of Craterhold, Joohius Hayar, is jealous that adventurers who return from the Abyss haven't been bringing him any artifacts."
    },
    {
        id = "INTA_MG1_Sunken_Amulet",
        name = "Mages Guild: Amulet Overboard",
        category = "Mages Guild",
        subcategory = "",
        master = "Into the Abyss", text = "Olvupius Julesius asked them to go down to the Craterhold docks to speak with Hyarmilrmerel Chaeifeth about an amulet that he has lost."
    },
    {
        id = "INTA_MG2_Cursed_Bosmer",
        name = "Mages Guild: The Cursed Bosmer",
        category = "Mages Guild",
        subcategory = "",
        master = "Into the Abyss", text = "Recently, someone came back from an expedition into the Abyss, and has suffered serious injuries."
    },
    {
        id = "INTA_Lost_Brother",
        name = "Lost Brother",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "One has met an Argonian outside Diver's Rest who has lost his brother to the Abyss, and wishes for them to find him."
    },
    {
        id = "INTA_Crystal_Hunt",
        name = "Field Research",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "Attend to a matter involving field research."
    },
    {
        id = "INTA_03_SpiderQ",
        name = "Gather Silk",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "One has to bring back Spider Silk from the Spider Cave on the 3rd Layer for the Basecamp, so they can use it to create more durable rope."
    },
    {
        id = "INTA_03_GoblinQ",
        name = "Goblin Extermination",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "The Goblins near Basecamp are more aggressive than ever lately."
    },
    {
        id = "INTA_Crabman",
        name = "The Crab-Man",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "The fisherman of Craterhold, Rontulain Sagesky, told them about the Crab-Man, who has scared him off from fishing along the edge of the island."
    },
    {
        id = "INTA_Pirates",
        name = "Pirates of the Abecean",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "Tuserion Thaorwatch, the vice captain of the Blue Whale, warned them about some pirates that have been attacking Altmer ships lately."
    },
    {
        id = "INTA_MQ",
        name = "Into the Abyss",
        category = "Miscellaneous",
        subcategory = "",
        master = "Into the Abyss", text = "Edwinna Elbert of the Ald'ruhn Mages guild is having trouble getting a strange compass to work, and has asked them to help her."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Into the Abyss data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 11
