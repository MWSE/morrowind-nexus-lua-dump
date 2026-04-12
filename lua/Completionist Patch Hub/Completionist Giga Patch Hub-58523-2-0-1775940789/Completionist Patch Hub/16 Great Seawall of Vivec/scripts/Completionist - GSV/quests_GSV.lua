local self = require('openmw.self')

local quests = {

    {
        id = "KJS_sw_census_delivery",
        name = "Witness Structure: Dispatch for the Seawall",
        category = "Imperial",
        subcategory = "Census and Excise",
        master = "Great Seawall of Vivec",
        text = "Deliver a Census and Excise dispatch to the Seawall office."
    },

    {
        id = "KJS_sw_dreugh_treasure",
        name = "Witness Structure: Witnessed and Regarded",
        category = "Miscellaneous",
        subcategory = "Seawall",
        master = "Great Seawall of Vivec",
        text = "Investigate a strange dreugh encounter beneath the Seawall."
    },

    {
        id = "KJS_sw_tt_pilgrimage",
        name = "Witness Structure: Pilgrimage of the Wall",
        category = "Temple",
        subcategory = "Pilgrimage",
        master = "Great Seawall of Vivec",
        text = "Complete a Temple pilgrimage at the Shrine-Upon-the-Wall."
    },

    {
        id = "KJS_sw_barmaid_mazte",
        name = "Witness Structure: Measured Indulgence",
        category = "Temple",
        subcategory = "Seawall",
        master = "Great Seawall of Vivec",
        text = "Look into a missing shipment meant for the Seawall kitchens."
    },

    {
        id = "KJS_sw_turret_stones",
        name = "Witness Structure: Turret Restorations",
        category = "Imperial",
        subcategory = "Western Tower",
        master = "Great Seawall of Vivec",
        text = "Assist with restoring the Western Tower's turret defenses."
    },

    {
        id = "KJS_sw_tg_journal",
        name = "Witness Structure: Borrowed Reflections",
        category = "Thieves Guild",
        subcategory = "",
        master = "Great Seawall of Vivec",
        text = "Recover a journal from the Seawall for the Thieves Guild."
    },

    {
        id = "KJS_sw_Delms_urn",
        name = "Witness Structure: Final Interment",
        category = "Miscellaneous",
        subcategory = "Seawall",
        master = "Great Seawall of Vivec",
        text = "Retrieve an ancestor's urn from the Seawall tomb."
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