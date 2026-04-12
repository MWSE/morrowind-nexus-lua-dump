local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Caldera Mages Guild Expanded
    -- #########################################################################

    {
        id = "luce_cmg_ralyn",
        name = "Mages Guild: The Prodigal Apprentice",
        category = "Mages Guild",
        subcategory = "",
        master = "Caldera Mages Guild Expanded", text = "It seems one of the apprentices from the Caldera Guild of Mages has gone missing."
    },
    {
        id = "luce_cmg_rent",
        name = "Caldera Mages Guild: Rent a Room",
        category = "Mages Guild",
        subcategory = "",
        master = "Caldera Mages Guild Expanded", text = "It appears there is a room availabe to rent at the Caldera Mages' Guild for 800 drakes a year."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Caldera Mages Guild Expanded data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 2
