local self = require('openmw.self')

local quests = {

    {
        id = "MD_AshGem",
        name = "Crystallizing Ash Zombies",
        category = "Mages Guild",
        subcategory = "Ald-ruhn",
        master = "Salt Gems of Bensamsi",
        text = "Jitha-Nan seeks assistance with an unusual study involving ash creatures in Bensamsi."
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