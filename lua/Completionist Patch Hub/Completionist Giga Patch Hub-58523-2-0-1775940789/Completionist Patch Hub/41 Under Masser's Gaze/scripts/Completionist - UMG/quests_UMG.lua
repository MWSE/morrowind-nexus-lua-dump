local self = require('openmw.self')

local quests = {

    {
        id = "ttd_livingnearthemoon",
        name = "Into Thin Air",
        category = "Mages Guild",
        subcategory = "Under Masser's Gaze",
        master = "Under Masser's Gaze",
        text = "Follow the trail of the missing Khajiit and learn what became of them."
    },

    {
        id = "TTD_MissingKhajiit",
        name = "Missing Khajiit",
        category = "Mages Guild",
        subcategory = "Under Masser's Gaze",
        master = "Under Masser's Gaze",
        text = "Investigate the disappearance of a group of Khajiit."
    },

    {
        id = "ttd_orcmason",
        name = "A Place Worthy",
        category = "Mages Guild",
        subcategory = "Under Masser's Gaze",
        master = "Under Masser's Gaze",
        text = "Find help for an important construction effort."
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