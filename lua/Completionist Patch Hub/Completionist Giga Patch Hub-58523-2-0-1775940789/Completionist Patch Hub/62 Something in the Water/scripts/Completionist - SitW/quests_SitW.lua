local self = require('openmw.self')

local quests = {

    {
        id = "gg_SomethingInTheWater",
        name = "There's Something in the Water",
        category = "Daedric",
        subcategory = "Peryite",
        master = "Daedric Shrine Peryite - Something in the Water",
        text = "Investigate a problem with the water supply from an old well in Pelagiad."
    },
    {
        id = "gg_sitw_kwama",
        name = "Uncuring the Kwama Queen",
        category = "Daedric",
        subcategory = "Peryite",
        master = "Daedric Shrine Peryite - Something in the Water",
        text = "Help a scamp foreman with a problem involving the local kwama queen."
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
-- Quest count: 2
