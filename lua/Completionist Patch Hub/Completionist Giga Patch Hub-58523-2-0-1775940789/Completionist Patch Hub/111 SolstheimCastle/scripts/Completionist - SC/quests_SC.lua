local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: SolstheimCastle
    -- #########################################################################

    {
        id = "KO_Castle_Main",
        name = "The Riddle Of The Door",
        category = "Miscellaneous",
        subcategory = "",
        master = "SolstheimCastle", text = "A local adventurer could not open the doors to Solstheim Castle."
    },
    {
        id = "PKO_BuyCastle",
        name = "Funds, My Liege",
        category = "Miscellaneous",
        subcategory = "",
        master = "SolstheimCastle", text = "Despite Aegir's blessing to claim his castle, the servants insist on having a proper liege to serve...which requires proper funds."
    },
    {
        id = "KO_lovenote",
        name = "The Love Note",
        category = "Miscellaneous",
        subcategory = "",
        master = "SolstheimCastle", text = "While exploring in Solstheim Castle one found a strange coded love note in one of the servants' rooms."
    },
    {
        id = "KO_Captain",
        name = "The Mystery of Geirleif, Son of Ardian",
        category = "Miscellaneous",
        subcategory = "",
        master = "SolstheimCastle", text = "A local adventurer ventured into the Merchant hall here at Solstheim Castle with the intentions of doing a bit of shopping."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending SolstheimCastle data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 4
