local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Baal Duun
    -- #########################################################################

    {
        id = "DB_QuestSheogorath",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "A local adventurer met a golden saint in the caves below Baal Duun who's challenged them to complete a painting which she has failed to do after multiple tries."
    },
    {
        id = "DB_QuestJumpstart",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "Attend to a matter involving expedition to baal duun."
    },
    {
        id = "DB_QuestNoDaedra",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "A local adventurer decided not to side with any of the Daedric Princes in the contest for Baal Duun."
    },
    {
        id = "DB_QuestMalacath",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "A local adventurer met an Ogrim in the caves below Baal Duun who's challenged them to pick up a boulder and place it on a nearby brazier."
    },
    {
        id = "DB_QuestMehrunes",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "A local adventurer met a Dremora in the caves below Baal Duun who's challenged them to stand in a pool of lava for five seconds."
    },
    {
        id = "DB_QuestMolag",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "A local adventurer met a Daedroth in the caves below Baal Duun who's challenged them to beat a scamp summoned into submission."
    },
    {
        id = "DB_Quest",
        name = "Expedition to Baal Duun",
        category = "Miscellaneous",
        subcategory = "",
        master = "Baal Duun", text = "On the road between Gnisis and Ald Velothi, one met a man being waylaid by a pair of bandits."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Baal Duun data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 7
