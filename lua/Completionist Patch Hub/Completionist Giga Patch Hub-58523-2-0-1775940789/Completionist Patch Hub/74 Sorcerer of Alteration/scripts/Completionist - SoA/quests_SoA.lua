local self = require('openmw.self')

local quests = {

    {
        id = "SOA_SeryneIntro",
        name = "Sorcerer of Alteration",
        category = "Miscellaneous",
        subcategory = "Sorcerer of Alteration",
        master = "Sorcerer of Alteration",
        text = "Seek out a renowned alteration sorceress mentioned in the book Breathing Water."
    },
    {
        id = "SOA_heavy_burdens_sideq",
        name = "Better Robe for Seryne",
        category = "Miscellaneous",
        subcategory = "Sorcerer of Alteration",
        master = "Sorcerer of Alteration",
        text = "Give a better robe to the sorceress Seryne Relas in Tel Branora."
    },
    {
        id = "SOA_Ardarume_SideQ",
        name = "Ardarume's Grimoire",
        category = "Miscellaneous",
        subcategory = "Sorcerer of Alteration",
        master = "Sorcerer of Alteration",
        text = "Retrieve a lost grimoire on behalf of a sorceress at Tel Vos."
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
