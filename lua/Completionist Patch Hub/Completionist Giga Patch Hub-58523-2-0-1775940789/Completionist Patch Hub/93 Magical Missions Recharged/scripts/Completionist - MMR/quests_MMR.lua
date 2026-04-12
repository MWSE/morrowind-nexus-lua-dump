local self = require('openmw.self')
local quests = {
    {
        id = "VD_MG2_AntlasSalobar",
        name = "Mages Guild: The Murdered Magician",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Investigate the death of a Mages Guild member and uncover the truth behind the crime."
    },

    {
        id = "VD_MG1_MelvosOrathi",
        name = "Mages Guild: Message for Melvos",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Deliver a coded message to a Mages Guild contact in Balmora."
    },

    {
        id = "VD_MG3_HlaaluVault",
        name = "Mages Guild: Hlaalu Heist",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Investigate a magical theft from the Hlaalu Vaults in Vivec."
    },

    {
        id = "VD_MG5_BethTreddur",
        name = "Mages Guild: The Dark Tome",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Recover a dangerous grimoire for Folms Mirel."
    },

    {
        id = "VD_MG4_GameofWits",
        name = "Mages Guild: A Game of Wits",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Negotiate for the return of a lost family heirloom from a Telvanni master."
    },

    {
        id = "MG_WarlocksRing",
        name = "Mages Guild: Warlock's Ring",
        category = "Guild Quests",
        subcategory = "Mages Guild",
        master = "Magical Missions Recharged",
        text = "Recover the Warlock's Ring from a hostile sorceress."
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

-- Quest count: 6
