local self = require('openmw.self')
local quests = {
    {
        id = "detd_killpainterquest",
        name = "To Paint A Picture",
        category = "Miscellaneous",
        subcategory = "Sadrith Mora",
        master = "Melodies and Moonlight",
        text = "I have become involved in a troubling affair concerning Veradul Dervayn in Sadrith Mora."
    },

    {
        id = "detd_painter_quest",
        name = "Painter of Shadows",
        category = "Great Houses",
        subcategory = "House Telvanni",
        master = "Melodies and Moonlight",
        text = "A strange painter in Sadrith Mora has asked for my help with a series of unusual tasks."
    },

    {
        id = "detd_destinyquest",
        name = "Of Heads and Melodies",
        category = "Miscellaneous",
        subcategory = "Music",
        master = "Melodies and Moonlight",
        text = "A peculiar musical matter has drawn me into the affairs of several performers."
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
