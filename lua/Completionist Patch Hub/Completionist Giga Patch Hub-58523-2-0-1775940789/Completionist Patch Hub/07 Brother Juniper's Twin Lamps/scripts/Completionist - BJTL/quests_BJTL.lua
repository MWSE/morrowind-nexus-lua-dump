local self = require('openmw.self')

local quests = {

    {
        id = "HH_TwinLamps1",
        name = "Twin Lamps: The Way to Freedom",
        category = "Rescue",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Assist the Twin Lamps with a matter involving escaped slaves."
    },

    {
        id = "HH_TwinLamps3",
        name = "Twin Lamps: Free Hides-His-Foot",
        category = "Rescue",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Help free a captive slave with aid from a local contact."
    },

    {
        id = "TL_Abebaal",
        name = "Twin Lamps: Abebaal Rebellion",
        category = "Rebellion",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Investigate reports of unrest among slaves at a remote mine."
    },

    {
        id = "TL_Arvel",
        name = "Twin Lamps: Arvel Family Business",
        category = "Diplomacy",
        subcategory = "House Arvel",
        master = "Brother Juniper's Twin Lamps",
        text = "Speak with members of the Arvel family about their stance on slavery."
    },

    {
        id = "TL_Arvel2",
        name = "Twin Lamps: Arvel Family Business",
        category = "Diplomacy",
        subcategory = "House Arvel",
        master = "Brother Juniper's Twin Lamps",
        text = "Help settle a dispute within the Arvel family."
    },

    {
        id = "TL_Books",
        name = "Twin Lamps: A Slave's Life",
        category = "Advocacy",
        subcategory = "Publishing",
        master = "Brother Juniper's Twin Lamps",
        text = "Speak with a bookseller about promoting an anti-slavery work."
    },

    {
        id = "TL_Books_1",
        name = "Twin Lamps: A Slave's Life",
        category = "Advocacy",
        subcategory = "Publishing",
        master = "Brother Juniper's Twin Lamps",
        text = "Seek support from a bookseller for distributing an anti-slavery book."
    },

    {
        id = "TL_Books_2",
        name = "Twin Lamps: A Slave's Life",
        category = "Advocacy",
        subcategory = "Publishing",
        master = "Brother Juniper's Twin Lamps",
        text = "Seek support from a bookseller for circulating an anti-slavery book."
    },

    {
        id = "TL_Caldera Mine",
        name = "Twin Lamps: Caldera Uprising",
        category = "Rebellion",
        subcategory = "Caldera Mine",
        master = "Brother Juniper's Twin Lamps",
        text = "Help spark a slave uprising at the Caldera ebony mine."
    },

    {
        id = "TL_FL_GalynTravel",
        name = "Twin Lamps: Fatleg's Camp",
        category = "Travel",
        subcategory = "Fatleg's Camp",
        master = "Brother Juniper's Twin Lamps",
        text = "Travel with an ally to a hidden slaver camp."
    },

    {
        id = "TL_Farmers",
        name = "Twin Lamps: Farmers and Laborers Guild",
        category = "Diplomacy",
        subcategory = "Guild Outreach",
        master = "Brother Juniper's Twin Lamps",
        text = "Seek the support of a local workers' guild against slavery."
    },

    {
        id = "TL_Hlaalu",
        name = "Twin Lamps: Win House Hlaalu",
        category = "Diplomacy",
        subcategory = "Great Houses",
        master = "Brother Juniper's Twin Lamps",
        text = "Work to win support from House Hlaalu."
    },

    {
        id = "TL_Hunter",
        name = "Twin Lamps: Fatleg's Camp",
        category = "Investigation",
        subcategory = "Fatleg's Camp",
        master = "Brother Juniper's Twin Lamps",
        text = "Follow a lead connected to a bounty hunter threatening the Twin Lamps."
    },

    {
        id = "TL_Llovyn",
        name = "Twin Lamps: Farmers and Laborers Guild",
        category = "Diplomacy",
        subcategory = "Guild Outreach",
        master = "Brother Juniper's Twin Lamps",
        text = "Secure the backing of a guild member concerned about retaliation."
    },

    {
        id = "TL_Manat",
        name = "Twin Lamps: Farmers and Laborers Guild",
        category = "Diplomacy",
        subcategory = "Guild Outreach",
        master = "Brother Juniper's Twin Lamps",
        text = "Persuade a wary farmer to support an anti-slavery position."
    },

    {
        id = "TL_Marcion",
        name = "Twin Lamps: Finding Marcion",
        category = "Investigation",
        subcategory = "Marcion",
        master = "Brother Juniper's Twin Lamps",
        text = "Investigate clues pointing to someone named Marcion."
    },

    {
        id = "TL_Marcion2",
        name = "Twin Lamps: Finding Marcion",
        category = "Investigation",
        subcategory = "Marcion",
        master = "Brother Juniper's Twin Lamps",
        text = "Continue the search for Marcion by following local leads."
    },

    {
        id = "TL_Miners",
        name = "Twin Lamps: Miners and Tanners Guild",
        category = "Diplomacy",
        subcategory = "Guild Outreach",
        master = "Brother Juniper's Twin Lamps",
        text = "Seek the support of the Miners and Tanners Guild against slavery."
    },

    {
        id = "TL_Nilera",
        name = "Twin Lamps: Farmers and Laborers Guild",
        category = "Diplomacy",
        subcategory = "Guild Outreach",
        master = "Brother Juniper's Twin Lamps",
        text = "Help a frightened guild supporter deal with intimidation."
    },

    {
        id = "TL_Recruit",
        name = "Twin Lamps: A New Recruit",
        category = "Recruitment",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Look for a promising new recruit for the Twin Lamps."
    },

    {
        id = "TL_Recruit_1",
        name = "Twin Lamps: A New Recruit",
        category = "Recruitment",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Follow up on a lead while searching for a new recruit."
    },

    {
        id = "TL_Recruit_2",
        name = "Twin Lamps: A New Recruit",
        category = "Recruitment",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Pursue an Ashlander lead in the search for a new recruit."
    },

    {
        id = "TL_Redoran",
        name = "Twin Lamps: Redoran Attacks",
        category = "Conflict",
        subcategory = "Great Houses",
        master = "Brother Juniper's Twin Lamps",
        text = "Investigate violent clashes tied to the issue of slavery."
    },

    {
        id = "TL_Shipwreck",
        name = "Twin Lamps: Shipwreck",
        category = "Rescue",
        subcategory = "Coast",
        master = "Brother Juniper's Twin Lamps",
        text = "Look into the aftermath of a slave ship taken over by its captives."
    },

    {
        id = "TL_Siege",
        name = "Twin Lamps: Bitterblade Under Siege",
        category = "Rescue",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Aid a Twin Lamps member trapped by slave hunters."
    },

    {
        id = "TL_SlaveMule",
        name = "Twin Lamps: Rescuing Rabinna",
        category = "Rescue",
        subcategory = "Hla Oad",
        master = "Brother Juniper's Twin Lamps",
        text = "Rescue a slave being held for criminal labor."
    },

    {
        id = "TL_SlaveShip",
        name = "Twin Lamps: Slave Ship",
        category = "Investigation",
        subcategory = "Tel Aruhn",
        master = "Brother Juniper's Twin Lamps",
        text = "Board a slave ship and learn who is behind its operations."
    },

    {
        id = "TL_Strategy",
        name = "Twin Lamps: A Choice of Strategy",
        category = "Strategy",
        subcategory = "Twin Lamps",
        master = "Brother Juniper's Twin Lamps",
        text = "Speak with Twin Lamps leaders about their next course of action."
    },

    {
        id = "TL_Temple",
        name = "Twin Lamps: Temple Support",
        category = "Diplomacy",
        subcategory = "Temple",
        master = "Brother Juniper's Twin Lamps",
        text = "Ask the Temple to take a position against slavery."
    },

    {
        id = "TL_Vertimus",
        name = "Twin Lamps: Fatleg's Camp",
        category = "Conflict",
        subcategory = "Fatleg's Camp",
        master = "Brother Juniper's Twin Lamps",
        text = "Deal with the threat posed by a hostile bounty hunter."
    },

    {
        id = "TL_Zaranda",
        name = "Twin Lamps: Fatleg's Camp",
        category = "Investigation",
        subcategory = "Fatleg's Camp",
        master = "Brother Juniper's Twin Lamps",
        text = "Examine evidence concerning a suspected informant."
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

-- Quest count: 31