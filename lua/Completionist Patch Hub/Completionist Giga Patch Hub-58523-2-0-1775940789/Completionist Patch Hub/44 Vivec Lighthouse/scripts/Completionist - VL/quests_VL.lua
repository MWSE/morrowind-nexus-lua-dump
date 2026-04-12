local self = require('openmw.self')

local quests = {

    {
        id = "Lighthouse_q_alt",
        name = "Vivec Lighthouse: The Darkness Below",
        category = "Miscellaneous",
        subcategory = "Vivec Lighthouse",
        master = "Vivec Lighthouse",
        text = "Evidence surrounding Bolayn Sareloth has drawn me into a troubling matter at the Vivec lighthouse."
    },

    {
        id = "Lighthouse_q_1",
        name = "Vivec Lighthouse: Wickie Work",
        category = "Miscellaneous",
        subcategory = "Vivec Lighthouse",
        master = "Vivec Lighthouse",
        text = "Aras Favel has hired me as an assistant at the Vivec lighthouse and set me to work on its daily duties."
    },

    {
        id = "Lighthouse_q_2",
        name = "Vivec Lighthouse: Strange Sights in the Storm",
        category = "Miscellaneous",
        subcategory = "Vivec Lighthouse",
        master = "Vivec Lighthouse",
        text = "A fierce storm at the Vivec lighthouse has brought strange events that Aras Favel wants me to help with."
    },

    {
        id = "Lighthouse_q_3",
        name = "Vivec Lighthouse: Resupplying the Rations",
        category = "Miscellaneous",
        subcategory = "Vivec Lighthouse",
        master = "Vivec Lighthouse",
        text = "Aras Favel has sent me to secure fresh supplies for the Vivec lighthouse."
    },

    {
        id = "Lighthouse_q_4",
        name = "Vivec Lighthouse: A Fresh Face",
        category = "Miscellaneous",
        subcategory = "Vivec Lighthouse",
        master = "Vivec Lighthouse",
        text = "With Aras Favel gone, someone must be found to take over the Vivec lighthouse."
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
-- Quest count: 5