local self = require('openmw.self')

local quests = {

    {
        id = "mdSR_DA_Sanguine",
        name = "Sanguine's Quest",
        category = "Daedric",
        subcategory = "Sanguine",
        master = "The Sanguine Rose",
        text = "Carry out a task for the Daedric Prince Sanguine at his shrine in Balmora."
    },
    {
        id = "mdSR_DA_Betrayal",
        name = "Sanguine's Quest",
        category = "Daedric",
        subcategory = "Sanguine",
        master = "The Sanguine Rose",
        text = "Inform the Temple's Justice Division of the location of Sanguine's shrine in Balmora."
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
