local self = require('openmw.self')

local quests = {

    {
        id = "aa22_Journal_NegotiationsReward",
        name = "Massama: Negotiations",
        category = "Diplomacy",
        subcategory = "Massama",
        master = "Secrets of the Crystal City",
        text = "I should return to Massama to speak with those involved in the recent negotiations."
    },

    {
        id = "aa22_Journal_HauntedBuilding",
        name = "Massama: Ghost Sightings",
        category = "Investigation",
        subcategory = "Massama",
        master = "Secrets of the Crystal City",
        text = "I have been asked to investigate troubling ghost sightings connected to a manor in Massama."
    },

    {
        id = "aa22_Journal_UxithKeiBahleel",
        name = "Massama: The Uxith-Kei",
        category = "Faction",
        subcategory = "Uxith-Kei",
        master = "Secrets of the Crystal City",
        text = "I am involved in the growing dispute between the Uxith-Kei and the Bahleel in Massama."
    },

    {
        id = "aa22_Journal_Reconciliation",
        name = "Massama: Reconciliation",
        category = "Main Quest",
        subcategory = "Massama",
        master = "Secrets of the Crystal City",
        text = "I am trying to mend an old division tied to the unrest surrounding Massama."
    },

    {
        id = "aa22_Journal_EscapeMassama",
        name = "Massama: Slaves in the Grazelands",
        category = "Wilderness",
        subcategory = "Grazelands",
        master = "Secrets of the Crystal City",
        text = "My dealings with the escaped slaves in the Grazelands have led me into the depths of Massama."
    },

    {
        id = "aa22_Journal_Negotiations",
        name = "Massama: Negotiations",
        category = "Diplomacy",
        subcategory = "Massama",
        master = "Secrets of the Crystal City",
        text = "I have been asked to calm rising tensions in Massama through negotiation."
    },

    {
        id = "aa22_Journal_CursedShield",
        name = "Massama: The Curse",
        category = "Main Quest",
        subcategory = "Massama",
        master = "Secrets of the Crystal City",
        text = "I am searching for the source of the strange curse that hangs over Massama."
    },

    {
        id = "aa22_Journal_SlaveBounty",
        name = "Massama: Slaves in the Grazelands",
        category = "Bounty",
        subcategory = "Grazelands",
        master = "Secrets of the Crystal City",
        text = "I have learned of a bounty concerning escaped slaves in the Grazelands."
    },

    {
        id = "aa22_Journal_FindMassama",
        name = "Massama: Slaves in the Grazelands",
        category = "Discovery",
        subcategory = "Grazelands",
        master = "Secrets of the Crystal City",
        text = "I am following reports in the Grazelands that may lead me to the hidden city of Massama."
    },

    {
        id = "aa22_Journal_UxithKei",
        name = "Massama: The Uxith-Kei",
        category = "Faction",
        subcategory = "Uxith-Kei",
        master = "Secrets of the Crystal City",
        text = "I must deal with new demands from the Uxith-Kei as tensions in Massama continue to rise."
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
-- Quest count: 10