local self = require('openmw.self')
local quests = {
    {
        id = "IEO_SpreadingTheWord_Ebonheart",
        name = "Imperial Employment Office: Spreading the Word",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver an informational leaflet to the Chief of Information in Ebonheart."
    },

    {
        id = "IEO_SpreadingTheWord_Aldruhn",
        name = "Imperial Employment Office: Spreading the Word",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver an informational leaflet to the Chief of Information in Ald'ruhn."
    },

    {
        id = "IEO_SpreadingTheWord_Balmora",
        name = "Imperial Employment Office: Spreading the Word",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver an informational leaflet to the Chief of Information in Balmora."
    },

    {
        id = "IEO_EmbarrasingConsequences",
        name = "Imperial Employment Office: Embarrassing Consequences",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Retrieve a family heirloom from a troublesome chest near Balmora."
    },

    {
        id = "IEO_DiplomaticPersuasion",
        name = "Imperial Employment Office: Diplomatic Persuasion",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Help settle a trade dispute on behalf of the Imperial Employment Office."
    },

    {
        id = "IEO_SpreadingTheWord_SM",
        name = "Imperial Employment Office: Spreading the Word",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver an informational leaflet to the Chief of Information in Sadrith Mora."
    },

    {
        id = "IEO_AlchemistAssistant",
        name = "Imperial Employment Office: Alchemist Assistance",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Gather Daedra hearts for an alchemical contract."
    },

    {
        id = "IEO_ClientSatisfaction",
        name = "Imperial Employment Office: Client Satisfaction",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Approve and review a survey of past Imperial Employment Office clients."
    },

    {
        id = "IEO_ConfiscatedSkooma",
        name = "Imperial Employment Office: Confiscated Skooma",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Carry a sensitive courier package from Gnisis to Seyda Neen."
    },

    {
        id = "IEO_PrefectRetirement",
        name = "Imperial Employment Office: Retirement",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Conclude your service at the Imperial Employment Office and arrange your retirement."
    },

    {
        id = "IEO_SpreadingTheWord",
        name = "Imperial Employment Office: Spreading the Word",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Distribute informational leaflets to Chiefs of Information across Vvardenfell."
    },

    {
        id = "IEO_ForgetfulAltmer",
        name = "Imperial Employment Office: Forgetful High Elf",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Recover a misplaced amulet for a forgetful High Elf."
    },

    {
        id = "IEO_BladeCollection",
        name = "Imperial Employment Office: Blade Collection",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Track down a missing short blade for a collector."
    },

    {
        id = "IEO_ImperialLibrary",
        name = "Imperial Employment Office: Imperial Library",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Obtain a complete historical book series for the library at Fort Moonmoth."
    },

    {
        id = "IEO_LearningModules",
        name = "Imperial Employment Office: Learning Modules",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Approve J'Dari's request to improve the office training program."
    },

    {
        id = "IEO_CourierService",
        name = "Imperial Employment Office: Courier Service",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver a note between Balmora and Caldera for the office."
    },

    {
        id = "IEO_GroceryService",
        name = "Imperial Employment Office: Grocery Service",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Bring a set of household supplies to a client near Vivec."
    },

    {
        id = "IEO_SkillTraining",
        name = "Imperial Employment Office: Skill Training",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Grant J'Dari leave so he can improve his skills and training methods."
    },

    {
        id = "IEO_RefillPlease",
        name = "Imperial Employment Office: Refill, please!",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Deliver a shipment of greef between two Vivec cornerclubs."
    },

    {
        id = "IEO_Networking",
        name = "Imperial Employment Office: Networking",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Authorize Naelin to negotiate new arrangements with other guilds."
    },

    {
        id = "IEO_JoinIEO",
        name = "Imperial Employment Office: Joining the Commision",
        category = "Factions",
        subcategory = "Imperial Employment Office",
        master = "Imperial Employment Office",
        text = "Register for work with the Imperial Employment Office."
    },

    {
        id = "IEO_prefect",
        name = "Imperial Employment Office: Prefect",
        category = "Factions",
        subcategory = "Imperial Employment Office Leadership",
        master = "Imperial Employment Office",
        text = "Assume the duties of Prefect and oversee the office's weekly affairs."
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

-- Quest count: 22
