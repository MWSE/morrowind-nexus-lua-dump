local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Beyond the Firmament
    -- #########################################################################

    {
        id = "SHH_SerpentOffer",
        name = "The Serpent's Offer",
        category = "Miscellaneous",
        subcategory = "",
        master = "Beyond the Firmament", text = "The Serpent made them an offer."
    },
    {
        id = "SSH_Shipwrecked",
        name = "Shipwrecked without Stars",
        category = "Miscellaneous",
        subcategory = "",
        master = "Beyond the Firmament", text = "Something has gone wrong."
    },
    {
        id = "SSH_Stargazing",
        name = "Serenity Among the Stars",
        category = "Miscellaneous",
        subcategory = "",
        master = "Beyond the Firmament", text = "We've successfully taken off."
    },
    {
        id = "SHH_Mananaut",
        name = "Mages Guild: The Regulations of Regulus",
        category = "Mages Guild",
        subcategory = "",
        master = "Beyond the Firmament", text = "A 'Mananaut' has arrived from the Imperial City."
    },
    {
        id = "SHH_Captain",
        name = "Mages Guild: Oh Captain My Captain",
        category = "Mages Guild",
        subcategory = "",
        master = "Beyond the Firmament", text = "Complete a task for Mages Guild."
    },
    {
        id = "SSH_Takeoff",
        name = "Get Galerion Geared Up",
        category = "Miscellaneous",
        subcategory = "",
        master = "Beyond the Firmament", text = "Edwinna was thrilled with their success in retrieving the varla stones."
    },
    {
        id = "SHH_Healer",
        name = "Mages Guild: Snail Season",
        category = "Mages Guild",
        subcategory = "",
        master = "Beyond the Firmament", text = "Edwinna has asked them to find a doctor for our voyage."
    },
    {
        id = "SSH_Voices",
        name = "Voices from the Void",
        category = "Miscellaneous",
        subcategory = "",
        master = "Beyond the Firmament", text = "A voice spoke to them."
    },
    {
        id = "SHH_Astro",
        name = "Mages Guild: The Secluded Stargazer",
        category = "Mages Guild",
        subcategory = "",
        master = "Beyond the Firmament", text = "Edwinna has asked them to ask around the Mages Guild halls to see who would be a capable astral navigator."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Beyond the Firmament data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 9
