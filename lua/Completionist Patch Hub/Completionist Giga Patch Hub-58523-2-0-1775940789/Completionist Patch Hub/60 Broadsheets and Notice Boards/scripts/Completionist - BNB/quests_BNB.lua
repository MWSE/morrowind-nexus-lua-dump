local self = require('openmw.self')

local quests = {

    {
        id = "KJS_Nalcaraya_request",
        name = "Nalcarya's Request",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Deliver a raw glass sample to an alchemist in Vivec."
    },
    {
        id = "KJS_junallei_request",
        name = "The Pearl Diver's Mishap",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Help a pearl diver in Pelagiad recover pearls lost during a dreugh attack."
    },
    {
        id = "KJS_Andrani_Request",
        name = "Bolnor's Dagger",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Recover a lost ancestral dagger posted on a notice board."
    },
    {
        id = "KJS_arathor_request",
        name = "Arathor's Bow",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Retrieve a bow from a cave on behalf of a man in Balmora."
    },
    {
        id = "KJS_Missing_Amulet",
        name = "The Lady's Heirloom",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Investigate the disappearance of a servant and a family heirloom near Suran."
    },
    {
        id = "KJS_catia_request",
        name = "A Book for Catia Sosia",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Find a copy of a specific book for a smith in the Mournhold Bazaar."
    },
    {
        id = "KJS_omavel_bounty",
        name = "Bounty on Dravil Omavel",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Track down a smuggler with a bounty on his head near Pelagiad."
    },
    {
        id = "KJS_bols_request",
        name = "Ebony for the Craftsman",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Obtain raw ebony ore for a craftsman at the Mournhold Craftsmen's Hall."
    },
    {
        id = "KJS_DB_contract",
        name = "The Assassin's Creed",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Report a discovered Dark Brotherhood contract to the appropriate authorities."
    },
    {
        id = "KJS_Crabmeat",
        name = "Crab Meat for a Fishwife",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Help a woman in Seyda Neen dealing with a food shortage."
    },
    {
        id = "KJS_Delivery",
        name = "The Saint Delyn Courier",
        category = "Miscellaneous",
        subcategory = "Notice Board",
        master = "Broadsheets and Notice Boards",
        text = "Deliver a broadsheet to recipients across Vivec City."
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
