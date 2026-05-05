local self = require('openmw.self')

-- =============================================================================

local MyPatchQuests = {
    {
        id = "INTA_MQ",
        name = "Into the Abyss: Main Quest",
        category = "Into the Abyss",
        subcategory = "Main Quest",
        text = "Dive into the Abyss."
    },
    {
        id = "INTA_MG1_Sunken_Amulet",
        name = "Amulet Overboard",
        category = "Into the Abyss",
        subcategory = "Mages Guild",
        text = "A ship went down with some valuables."
    },
	{
        id = "INTA_MG2_Cursed_Bosmer",
        name = "The Cursed Bosmer",
        category = "Into the Abyss",
        subcategory = "Mages Guild",
        text = "Someone returned. In an ideal condition."
    },
	{
        id = "INTA_MG3_The_Soul_Anchors",
        name = "The Soul Anchors",
        category = "Into the Abyss",
        subcategory = "Mages Guild",
        text = "Climbing the scaffold of Craterhold gets tiresome. Perhaps an Artifact can speed things up?"
    },
	{
        id = "INTA_03_GoblinQ",
        name = "Goblin Extermination",
        category = "Into the Abyss",
        subcategory = "Third Layer",
        text = "The Goblins inhabiting the third layer are causing problems."
    },
	{
        id = "INTA_03_SpiderQ",
        name = "Gathering Silk",
        category = "Into the Abyss",
        subcategory = "Third Layer",
        text = "The Silk from the local spiders are valuable in making rope."
    },
	{
        id = "INTA_Pirates",
        name = "Pirates of the Abecean",
        category = "Into the Abyss",
        subcategory = "Misc Quests",
        text = "Pirates have been causing trouble for trade."
    },
	{
        id = "INTA_Lost_Brother",
        name = "Lost Brother",
        category = "Into the Abyss",
        subcategory = "Misc Quests",
        text = "A traveler is looking for his brother."
    },
	{
        id = "INTA_Crystal_Hunt",
        name = "Field Research",
        category = "Into the Abyss",
        subcategory = "Third Layer",
        text = "A local researcher needs help with some tests."
    },
	{
        id = "INTA_Crabman",
        name = "The Crab-Man",
        category = "Into the Abyss",
        subcategory = "Misc Quests",
        text = "Half man, half crab. Is it true, or just a local superstition?"
    },
	{
        id = "INTA_Artifact_for_Jooh",
        name = "An Artifact for Joohius",
        category = "Into the Abyss",
        subcategory = "Misc Quests",
        text = "The shop keeper of Craterhold is looking for something valuable."
    },
}

-- =============================================================================
-- REGISTRATION LOGIC
-- =============================================================================
local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
            -- Sends the quest packet to the main tracker on the first frame
            if not hasSent then
                self:sendEvent("INTA_Completion_RegisterPack", MyPatchQuests)
                
                print("[INTA_Completion Patch] Quests registered successfully.")
                
                hasSent = true
            end
        end
    }
}