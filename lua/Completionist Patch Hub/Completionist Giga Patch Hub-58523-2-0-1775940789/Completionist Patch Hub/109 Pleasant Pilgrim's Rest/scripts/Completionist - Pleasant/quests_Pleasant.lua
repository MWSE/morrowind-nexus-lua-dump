local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Pleasant Pilgrim's Rest
    -- #########################################################################

    {
        id = "Endify_TPR_RaviroBounty",
        name = "Vampires in Raviro Ancestral Tomb",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "The Tribunal Temple has issued a bounty on the vampires in Raviro Ancestral Tomb."
    },
    {
        id = "Endify_TPR_FindSerelos",
        name = "Finding Serelos Redaloth",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "Selkirnemus has told them that Serelos Redaloth, the local drunk, is missing."
    },
    {
        id = "Endify_TPR_APCalcNeed",
        name = "The Quest for a Calcinator",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "Dunel Saryon needs an Apprentice's Calcinator to continue his research."
    },
    {
        id = "Endify_TPR_HakiBounty",
        name = "Worshippers at Zaintiraris",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "The Tribunal Temple has issued a bounty on Haki the Halt, a Daedric worshipper located in Zaintiraris."
    },
    {
        id = "Endify_TPR_LostRing",
        name = "Mundrila's Lost Ring",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "Mundrila Ienith has lost her family heirloom - a ring that has been in her family for generations."
    },
    {
        id = "Endify_TPR_Sujamma",
        name = "The Quest for Sujamma",
        category = "Miscellaneous",
        subcategory = "",
        master = "Pleasant Pilgrim's Rest", text = "Selkirnemus, the proprietor of The Pilgrim's Rest in Molag Mar, is facing some supply shortages."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Pleasant data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 6
