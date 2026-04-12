local self = require('openmw.self')
local quests = {
    {
        id = "MQ_anarelle",
        name = "Alvura's Amulet",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Recover a stolen amulet for a local in Tel Branora."
    },

    {
        id = "MQ_cannibal",
        name = "Cannibal in Tel Branora",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Look into troubling rumors about a local resident."
    },

    {
        id = "MQ_gratha",
        name = "Rogue Sorceresses",
        category = "House Telvanni",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Deal with two rogue sorceresses operating near Tel Branora."
    },

    {
        id = "MQ_serula",
        name = "The Desecrated Tomb",
        category = "Tribunal Temple",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Cleanse a desecrated tomb near Tel Branora."
    },

    {
        id = "MQ_zeta",
        name = "A Tomb Near Tel Branora",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Investigate a dangerous tomb described by a local warrior."
    },

    {
        id = "MQ_yanz",
        name = "Yanz and Neva",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Speak with a smuggler on behalf of a worried lover."
    },

    {
        id = "MQ_vase",
        name = "Dra'Jhor's Lost Axe",
        category = "Miscellaneous",
        subcategory = "Tel Branora",
        master = "Tales of Tel Branora",
        text = "Recover a lost axe from dangerous tunnels beneath Tel Branora."
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

-- Quest count: 7
