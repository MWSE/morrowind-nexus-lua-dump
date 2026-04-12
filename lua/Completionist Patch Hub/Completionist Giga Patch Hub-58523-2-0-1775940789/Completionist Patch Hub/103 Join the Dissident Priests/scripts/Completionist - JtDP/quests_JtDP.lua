local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Join the Dissident Priests
    -- #########################################################################

    {
        id = "AL93_DissPriestHintQuest1",
        name = "A Heretic in the Temple?",
        category = "Temple",
        subcategory = "",
        master = "Join the Dissident Priests", text = "A local adventurer met an Ordinator in Balmora's Eight Plates tavern."
    },
    {
        id = "AL93_DissPriestsBoethiah",
        name = "Dissident Priests: Boethian Manuscripts",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Complete a task for Dissident Priests."
    },
    {
        id = "AL93_DissPriestsSadrith",
        name = "Dissident Priests: Finding a Hiding Place in Sadrith Mora",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Gilvas Barelo asked them to find a hiding place or escape route for the Dissident Priests, in case the Ordinators find Holamayan."
    },
    {
        id = "AL93_DissPriestsConvert",
        name = "Dissident Priests: Finding a Convert",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Gilvas Barelo asked them to convince Feldrelo Sadri to join us."
    },
    {
        id = "AL93_DissPriestMephala",
        name = "Dissident Priests: Staff of Mephala",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "There is a rumor at Holamayan Monastery that Ashlanders use a unique staff to worship Mephala."
    },
    {
        id = "AL93_DissPriestLetter",
        name = "Dissident Priests: Finding a Convert... Again",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Tivam Sadri heard about their failed attempt to convert his sister."
    },
    {
        id = "AL93_DissPriestsAshl",
        name = "Dissident Priests: Finding a Hiding Place Among the Ashlanders",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Gilvas Barelo told them that a Scroll of Almsivi Intervention would take them from Holamayan to Molag Mar."
    },
    {
        id = "AL93_DissPriestRing",
        name = "The Priestess' Ring",
        category = "Miscellaneous",
        subcategory = "",
        master = "Join the Dissident Priests", text = "Attend to a matter involving the priestess' ring."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Join the Dissident Priests data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 8
