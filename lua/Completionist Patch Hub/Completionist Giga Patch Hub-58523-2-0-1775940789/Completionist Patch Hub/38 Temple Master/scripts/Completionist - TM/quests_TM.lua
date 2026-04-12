local self = require('openmw.self')
local quests = {
    {
        id = "mdTemp_Appointment",
        name = "Temple: Suran Appointment",
        category = "Temple",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "I have been appointed to oversee the Suran Temple and should speak with the local clergy about my new duties."
    },

    {
        id = "mdTemp_Charity",
        name = "Temple: Suran Charity",
        category = "Temple",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "The Suran Temple can now support charitable works, and I should decide where its donations will be directed."
    },

    {
        id = "mdTemp_Expansion",
        name = "Temple: Suran Expansion",
        category = "Temple",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "Plans are being made to expand the Suran Temple, and I must help arrange what is needed."
    },

    {
        id = "mdTemp_ExpansionHealer",
        name = "Temple: Suran Expansion",
        category = "Temple Services",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "A new healer must be chosen for service at the Suran Temple."
    },

    {
        id = "mdTemp_ExpansionMonk",
        name = "Temple: Suran Expansion",
        category = "Temple Services",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "A new monk must be chosen for service at the Suran Temple."
    },

    {
        id = "mdTemp_Hostel",
        name = "Temple: Suran Hostel",
        category = "Temple",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "The Suran Temple may add a hostel, and I should assist with preparations for the project."
    },

    {
        id = "mdTemp_HostelElvil",
        name = "Temple: Suran Hostel",
        category = "Temple Services",
        subcategory = "Suran Temple Hostel",
        master = "Temple Master",
        text = "One possible hosteller has been suggested for the Suran Temple hostel, and I should speak with him."
    },

    {
        id = "mdTemp_HostelSovor",
        name = "Temple: Suran Hostel",
        category = "Temple Services",
        subcategory = "Suran Temple Hostel",
        master = "Temple Master",
        text = "One possible hosteller has been suggested for the Suran Temple hostel, and I should speak with him."
    },

    {
        id = "mdTemp_Kummu",
        name = "Temple: Suran Pilgrims",
        category = "Temple",
        subcategory = "Pilgrimage",
        master = "Temple Master",
        text = "The Suran Temple seeks to draw more pilgrims, and I should help promote the local pilgrimage."
    },

    {
        id = "mdTemp_Relic",
        name = "Temple: Suran Relic",
        category = "Temple",
        subcategory = "Relics",
        master = "Temple Master",
        text = "A rumor concerning a sacred relic has reached the Suran Temple, and I should investigate it."
    },

    {
        id = "mdTemp_Shrine",
        name = "Temple: Suran Shrine",
        category = "Temple",
        subcategory = "Suran Temple",
        master = "Temple Master",
        text = "The Suran Temple needs a shrine, and I should gather support to make its installation possible."
    },

    {
        id = "mdTemp_ShrineAshumanu",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineAvon",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A prominent resident of Suran may support the temple shrine if I can win his favor."
    },

    {
        id = "mdTemp_ShrineDesele",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineDranas",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineFolsi",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineGoldyn",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineRalds",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineRanosa",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineRavoso",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a resident of Suran."
    },

    {
        id = "mdTemp_ShrineTirnur",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a traveler staying in Suran."
    },

    {
        id = "mdTemp_ShrineVerara",
        name = "Temple: Suran Shrine",
        category = "Temple Donations",
        subcategory = "Suran Shrine Fund",
        master = "Temple Master",
        text = "A donation for the Suran Temple shrine may be secured from a local merchant."
    },

    {
        id = "mdTemp_SideUlms",
        name = "Uncle Ulms the Unbeliever",
        category = "Side Quests",
        subcategory = "Elynu Saren",
        master = "Temple Master",
        text = "Elynu Saren has asked me to look into the fate of her wayward uncle."
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

-- Quest count: 23
