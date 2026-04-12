local self = require('openmw.self')

local quests = {

    {
        id = "AAkarRV_BH_ArgoNecr1",
        name = "Sinkhole Passage: Potent Kwama Poison Delivery",
        category = "Miscellaneous",
        subcategory = "Sinkhole Passage",
        master = "Legacy of the Blades",
        text = "Deliver potent kwama poison to a local necromancer in Sinkhole Passage."
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
