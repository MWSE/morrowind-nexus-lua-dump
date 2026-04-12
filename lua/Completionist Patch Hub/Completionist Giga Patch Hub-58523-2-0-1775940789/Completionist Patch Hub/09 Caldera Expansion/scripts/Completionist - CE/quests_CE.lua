local self = require('openmw.self')
local quests = {
    {
        id = "TDM_CM_UnrulySlave",
        name = "Gold-Heart",
        category = "Miscellaneous",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "An overseer at Caldera Mine wants me to deal with a troublesome slave."
    },

    {
        id = "TDM_CM_AtroIngreds",
        name = "An Atronach Menagerie",
        category = "Miscellaneous",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "A mage at Caldera Mine has asked me to gather several rare atronach salts."
    },

    {
        id = "DD_HR_CalderaMine",
        name = "Blood Pact",
        category = "House Redoran",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "A Redoran retainer has sent me to find a troubled man tied to the fate of Caldera Mine."
    },

    {
        id = "TDM_CM_RisingSun",
        name = "Rising Sun the Scrib",
        category = "Miscellaneous",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "A slave at Caldera Mine has asked me to find her missing pet scrib."
    },

    {
        id = "TDM_CM_Telvanni",
        name = "An Unstable Situation",
        category = "House Telvanni",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "A Telvanni councilor wants my help with a dangerous matter involving Caldera Mine."
    },

    {
        id = "tdm_cm_radimus",
        name = "Enlightenment",
        category = "Miscellaneous",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "One of the mine's resident mages has asked me to perform a series of dubious errands."
    },

    {
        id = "TDM_CC_HLAALU",
        name = "Snakes and Liars",
        category = "House Hlaalu",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "House Hlaalu has business for me concerning growing tensions around Caldera Mine."
    },

    {
        id = "TDM_CM_Axe",
        name = "The Lucky Pickaxe",
        category = "Miscellaneous",
        subcategory = "Caldera Mine",
        master = "Caldera Expansion",
        text = "A miner wants me to recover her missing lucky pickaxe."
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

-- Quest count: 8
