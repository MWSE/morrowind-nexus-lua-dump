local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Even Seedier
    -- #########################################################################

    {
        id = "luce_esep_tg_plates",
        name = "Thieves Guild: Eight Plates",
        category = "Thieves Guild",
        subcategory = "",
        master = "Even Seedier Eight Plates", text = "Sugar-Lips Habasi asked them to steal the eight decorative plates from the Eight Plates tavern in Balmora."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Even Seedier data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
