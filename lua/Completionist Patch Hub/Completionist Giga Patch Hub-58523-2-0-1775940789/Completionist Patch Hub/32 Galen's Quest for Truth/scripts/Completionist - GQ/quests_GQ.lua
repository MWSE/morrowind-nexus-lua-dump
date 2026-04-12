local self = require('openmw.self')
local quests = {
    {
        id = "aa_ws_galen00",
        name = "Galen's Quest for Truth",
        category = "Temple",
        subcategory = "Galen",
        master = "Galen's Quest For Truth",
        text = "Aid a fugitive priest who is seeking answers about a troubling illness."
    },

    {
        id = "aa_ws_galen01",
        name = "Galen's Quest for Truth",
        category = "Temple",
        subcategory = "Galen",
        master = "Galen's Quest For Truth",
        text = "Seek further insight into the divine disease from a knowledgeable expert."
    },

    {
        id = "aa_ws_galen02",
        name = "Galen's Quest for Truth",
        category = "Temple",
        subcategory = "Galen",
        master = "Galen's Quest For Truth",
        text = "Help Galen with the next stage of his search for the truth."
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

-- Quest count: 3
