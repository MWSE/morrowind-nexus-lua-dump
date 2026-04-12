local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Rise of House Telvanni
    -- #########################################################################

    {
        id = "RoHT_BosmeriPreacher",
        name = "Removing an Annoyance",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Remove an annoyance."
    },
    {
        id = "RoHT_CoupDEtat",
        name = "House Telvanni Grasps Power",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Deal with the order of succesion."
    },
    {
        id = "RoHT_EastEmpireCompany",
        name = "Acting Against Imprudent Imperials",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "The East Empire Company is causing trouble."
    },
    {
        id = "RoHT_EdwinnaMadness",
        name = "An Unhealthy Obsession",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Edwinna Elbert is no longer herself."
    },
    {
        id = "RoHT_EdwinnaQuests",
        name = "A New Member: Edwinna Elbert",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Edwinna has a new project."
    },
    {
        id = "RoHT_EdwinnaTower",
        name = "A Mechanic's Dream",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Help Edwinna with her tower."
    },
    {
        id = "RoHT_FinalGratification",
        name = "A Present from the Grandmagister",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Deal with some politics."
    },
    {
        id = "RoHT_GothrenSuccessor",
        name = "Replace Archmagister Gothren",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Replace the Archmgister."
    },
    {
        id = "RoHT_Initiation",
        name = "Taking Over Leadership of House Telvanni",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Take over leadership."
    },
    {
        id = "RoHT_MagesGuild",
        name = "Eliminating the Guild of Mages",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Eliminate the Guild of Mages."
    },
    {
        id = "RoHT_MGRecruitEdwinna",
        name = "Tempting Edwinna",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Persuade Edwinna."
    },
    {
        id = "RoHT_MGRecruitSkink",
        name = "Converting Skink-in-Tree's-Shade",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Recruit Skink."
    },
    {
        id = "RoHT_Misc_AlighiereQuest",
        name = "Till Final Death do us Part",
        category = "Miscellaneous",
        subcategory = "Alighiere",
        master = "Rise of House Telvanni", text = "Aomething is bothering Alighiere."
    },
    {
        id = "RoHT_Misc_ElmeraQuest",
        name = "An Axe for an Axe",
        category = "Miscellaneous",
        subcategory = "Elmera",
        master = "Rise of House Telvanni", text = "Regain the axe."
    },
    {
        id = "RoHT_Misc_FamilyTies",
        name = "Unexpected Family Ties",
        category = "Miscellaneous",
        subcategory = "Endalos",
        master = "Rise of House Telvanni", text = "Become a member of the family."
    },
    {
        id = "RoHT_SkinkQuests",
        name = "A New Member: Skink-in-Tree's-Shade",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Skirk is missing."
    },
    {
        id = "RoHT_Summoning",
        name = "Ghosts from the Past",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "There has been an abduction."
    },
    {
        id = "RoHT_TheranasRevenge",
        name = "Headaches after the Celebrations",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "There has been an abduction."
    },
    {
        id = "RoHT_TwinLamps",
        name = "Freedom ... or something like it",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Help the Twin Lamps."
    },
    {
        id = "RoHT_UvooQuest",
        name = "Investigating Pergamaea",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Investigate the request."
    },
    {
        id = "RoHT_UvooTower",
        name = "Building Tel Llarelah",
        category = "Great Houses | Great House Telvanni",
        subcategory = "House Business",
        master = "Rise of House Telvanni", text = "Mistress Zubadaiah needs assistance."
    },
    {
        id = "RoHT_Wards1ZafirbelsStar",
        name = "The Wards of Trine: Star of Zafirbel",
        category = "Great Houses | Great House Telvanni",
        subcategory = "The Wards of Trine",
        master = "Rise of House Telvanni", text = "Discover a Ward of Trine."
    },
    {
        id = "RoHT_Wards2UvirithsCube",
        name = "The Wards of Trine: Cube of Uvirith",
        category = "Great Houses | Great House Telvanni",
        subcategory = "The Wards of Trine",
        master = "Rise of House Telvanni", text = "Discover another amulet."
    },
    {
        id = "RoHT_Wards3TelvannisChalice",
        name = "The Wards of Trine: Telvanni's Chalice",
        category = "Great Houses | Great House Telvanni",
        subcategory = "The Wards of Trine",
        master = "Rise of House Telvanni", text = "The last amulet has been discovered."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Rise of House Telvanni data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}