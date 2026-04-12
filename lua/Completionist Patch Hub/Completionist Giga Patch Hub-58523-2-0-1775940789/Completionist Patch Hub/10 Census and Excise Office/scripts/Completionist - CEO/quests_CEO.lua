local self = require('openmw.self')

local quests = {

    {
        id = "PleaseLetThisWork",
        name = "Census and Excise Office: Wood Elf Immigrant",
        category = "Factions | Census and Excise Office",
        subcategory = "Immigration Control",
        master = "Census and Excise Office",
        text = "Socucius Ergalla has assigned me to evaluate a Wood Elf immigrant seeking entry into Morrowind."
    },

    {
        id = "AAA_CensusList",
        name = "Census and Excise Office: Smuggler Caves",
        category = "Factions | Census and Excise Office",
        subcategory = "Contraband and Smuggling",
        master = "Census and Excise Office",
        text = "I have received information about smuggler caves along the Bitter Coast and the contraband bounty offered by the Census and Excise Office."
    },

    {
        id = "ZZZ_Immigrant1",
        name = "Census and Excise Office: Dunmer Miner Immigrant",
        category = "Factions | Census and Excise Office",
        subcategory = "Immigration Control",
        master = "Census and Excise Office",
        text = "I have been asked to question a Dunmer miner who wishes to enter Morrowind."
    },

    {
        id = "AAA_FineMouth",
        name = "Census and Excise Office: Fine-Mouth's Taxes",
        category = "Factions | Census and Excise Office",
        subcategory = "Tax Collection",
        master = "Census and Excise Office",
        text = "I have been ordered to collect the taxes owed by Fine-Mouth in Seyda Neen."
    },

    {
        id = "AAA_Eldafire",
        name = "Census and Excise Office: Eldafire's Taxes",
        category = "Factions | Census and Excise Office",
        subcategory = "Tax Collection",
        master = "Census and Excise Office",
        text = "Socucius Ergalla has sent me to collect overdue taxes from Eldafire in Seyda Neen."
    },

    {
        id = "AAA_Pelagiad",
        name = "Census and Excise Office: Census in Pelagiad",
        category = "Factions | Census and Excise Office",
        subcategory = "Census Work",
        master = "Census and Excise Office",
        text = "I have been sent to conduct a census of the permanent residents in Pelagiad."
    },

    {
        id = "GuiltyDunmer",
        name = "Census and Excise Office: Female Dark Elf Immigrant",
        category = "Factions | Census and Excise Office",
        subcategory = "Immigration Control",
        master = "Census and Excise Office",
        text = "I must question a female Dunmer immigrant and decide how her case should be handled."
    },

    {
        id = "AAA_Legion",
        name = "Census and Excise Office: Salary for the Legion",
        category = "Factions | Census and Excise Office",
        subcategory = "Imperial Duties",
        master = "Census and Excise Office",
        text = "Socucius Ergalla has entrusted me with delivering the monthly pay to the soldiers at Fort Moonmoth."
    },

    {
        id = "AAA_Erval",
        name = "Census and Excise Office: Erval's Taxes",
        category = "Factions | Census and Excise Office",
        subcategory = "Tax Collection",
        master = "Census and Excise Office",
        text = "I have been assigned to collect the taxes owed by Erval in Pelagiad."
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
-- Quest count: 9