local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: TheManifoldSpires
    -- #########################################################################

    {
        id = "DK_SpiresQuest",
        name = "The State of Siege",
        category = "Miscellaneous",
        subcategory = "",
        master = "TheManifoldSpires", text = "One has heard rumors around Vivec that Berel Sala, leader of the Ordinators, is hiring freelance adventurers for some Temple business."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending TheManifoldSpires data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
