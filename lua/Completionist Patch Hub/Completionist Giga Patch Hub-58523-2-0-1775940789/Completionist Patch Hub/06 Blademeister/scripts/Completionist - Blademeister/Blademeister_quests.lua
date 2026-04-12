local self = require('openmw.self')

local quests = {

    {
        id = "sd_FelthornIntro",
        name = "The Sword in the Bone",
        category = "Miscellaneous",
        subcategory = "Felthorn",
        master = "Blademeister",
        text = "A strange sentient weapon found in Addamasartus may prove more trouble than it first appears."
    },

    {
        id = "sd_FelthornPower",
        name = "Blademeister",
        category = "Miscellaneous",
        subcategory = "Felthorn",
        master = "Blademeister",
        text = "Felthorn seeks rare offerings and daedric power in pursuit of a greater form."
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