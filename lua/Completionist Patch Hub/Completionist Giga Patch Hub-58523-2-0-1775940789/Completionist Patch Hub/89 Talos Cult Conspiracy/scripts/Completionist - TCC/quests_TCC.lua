local self = require('openmw.self')

local quests = {

    {
        id = "TC_Zenosephora",
        name = "Talos Cult: Elenwen",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Ask about Elenwen and trace her connection to the Talos Cult."
    },

    {
        id = "TC_Pilgrimage",
        name = "Talos Cult: Pilgrimage",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Complete a Talos pilgrimage to prove devotion to the cult."
    },

    {
        id = "TC_Informant",
        name = "Talos Cult: Orders from Pelagiad",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Find a contact in Pelagiad and deliver the coded package."
    },

    {
        id = "TC_Motierre",
        name = "Talos Cult: The Assassin",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Meet a noble contact in Khuul and hear her proposal."
    },

    {
        id = "TC_Traitor",
        name = "Talos Cult: Cold Feet",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Track down a former cult member who fled the cause."
    },

    {
        id = "TC_Endgame",
        name = "Talos Cult: Endgame",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Recover proof against Elenwen and bring it to Frik."
    },

    {
        id = "TC_Updates",
        name = "Spying for General Darius",
        category = "Imperial Legion Quests",
        subcategory = "General Darius",
        master = "Talos Cult Conspiracy",
        text = "Report the Talos Cult's activities to General Darius."
    },

    {
        id = "TC_Altmer",
        name = "Talos Cult: The Treasonous Courier",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Investigate the courier who tampered with the Talos Cult's messages."
    },

    {
        id = "TC_Decoy",
        name = "Talos Cult: To Kill an Emperor",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Wait for Arius to return from his attempt on the Emperor."
    },

    {
        id = "TC_Quiz",
        name = "Talos Cult: A Quiz on Talos",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Study Talos and pass Arius' test."
    },

    {
        id = "TC_Mace",
        name = "Talos Cult: A Perfect Murder Weapon",
        category = "Talos Cult Quests",
        subcategory = "Talos Cult",
        master = "Talos Cult Conspiracy",
        text = "Obtain an ebony mace for the Talos Cult's plans."
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

-- Quest count: 11