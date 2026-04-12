local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: The Fiend of Ald Andalor
    -- #########################################################################

    {
        id = "TBD_TombInv",
        name = "Andalor Tomb Investigation",
        category = "Miscellaneous",
        subcategory = "",
        master = "The Fiend of Ald Andalor", text = "Folvys Andalor has asked to investigate the strange happenings in his family tomb."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending The Fiend of Ald Andalor data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
