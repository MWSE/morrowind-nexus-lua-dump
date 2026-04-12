local self = require('openmw.self')

local quests = {

    {
        id = "slf_fh_hilbongard",
        name = "The Forge of Hilbongard",
        category = "Dungeon",
        subcategory = "",
        master = "Forge of Hilbongard Reignited",
        text = "Explore the Forgotten Vaults of Anudnabia and reignite the legendary Forge of Hilbongard."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 1
