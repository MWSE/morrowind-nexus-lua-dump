local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Unnamed_Isle
    -- #########################################################################

    {
        id = "ui_mysteryIsle",
        name = "The Unnamed Isle",
        category = "Miscellaneous",
        subcategory = "",
        master = "Unnamed Isle", text = "A guy who came from the beach attacked Bask for no reason."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Unnamed_Isle data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
