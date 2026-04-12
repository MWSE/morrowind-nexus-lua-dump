local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Of Musk and Mer A Sadrith Mora Tale
    -- #########################################################################

    {
        id = "DD_DefiledTombHunt",
        name = "Defiled Tomb: Hunt for the Desecrator",
        category = "Miscellaneous",
        subcategory = "",
        master = "Of Musk and Mer A Sadrith Mora Tale", text = "Dalmil, the Bug Musk perfumer, has approached them with a request to investigate the Seloth Ancestral Tomb, which has been desecrated and ruined."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Of Musk and Mer A Sadrith Mora Tale data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
