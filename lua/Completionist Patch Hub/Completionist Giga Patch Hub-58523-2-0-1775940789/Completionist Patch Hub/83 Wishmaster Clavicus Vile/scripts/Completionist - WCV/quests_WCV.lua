local self = require('openmw.self')

local quests = {

    {
        id = "gg_los_timsa",
        name = "Timsa-Come-By",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Meet Timsa-Come-By, a selective Argonian florist in Caldera with courier work available."
    },
    {
        id = "gg_los_timsa01rose",
        name = "A Rose for Eydis Fire-Eye",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver a rose to the Fighters Guild steward in Balmora on behalf of a local florist."
    },
    {
        id = "gg_los_timsa02game",
        name = "The Game Must Go On",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver a deck of cards to a pawnbroker in Caldera for a local florist."
    },
    {
        id = "gg_los_timsa03golden",
        name = "All That is Golden",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver Gold Kanet flowers to a woman in Gnaar Mok for a local florist."
    },
    {
        id = "gg_los_timsa04poppies",
        name = "A Pocketful of Poppies",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver poppies to a clothier in Suran on behalf of a local florist."
    },
    {
        id = "gg_los_timsa05claw",
        name = "Sharp as a Scamp's Claw",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver a dagger to a contact in Ald-ruhn for a local florist."
    },
    {
        id = "gg_los_timsa06glove",
        name = "Eldrasea's Right Hand",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Deliver a glove to a contact in a shop basement in Balmora."
    },
    {
        id = "gg_wm_wish00coin",
        name = "A Black Coin",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Craft a Black Coin from a black soul gem and a gold coin."
    },
    {
        id = "gg_wm_wish00book",
        name = "A Sload Book",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Find a rare Sload necromantic book for the Wishmaster's agent."
    },
    {
        id = "gg_wm_wish01cure",
        name = "A Wish for a Cure",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Travel to Ald Velothi to cure an ailing young woman on behalf of the Wishmaster."
    },
    {
        id = "gg_wm_wish02veng",
        name = "A Wish for Vengeance",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Ruin the life of an anonymous target in Suran on behalf of the Wishmaster."
    },
    {
        id = "gg_wm_wish03infant",
        name = "A Wish for an Infant",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Act as intermediary between two people in Sadrith Mora to fulfill a wish for a child."
    },
    {
        id = "gg_wm_wish04loss",
        name = "A Wish for Loss",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Help an ex-cultist in Mournhold troubled by haunting memories of his past."
    },
    {
        id = "gg_wm_wish05escape",
        name = "A Wish for an Escape",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Help a poet in Tel Branora who is desperate to escape an unusual affliction."
    },
    {
        id = "gg_wm_wish06nine",
        name = "Name Here",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Plant evidence to disgrace a traitor to the Cult of Clavicus Vile."
    },
    {
        id = "gg_wm_hunter01scamp",
        name = "A Runaway Scamp",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Track down and eliminate a scamp hiding near a Daedric shrine."
    },
    {
        id = "gg_wm_hunter02atro",
        name = "The Cold-fire Atronach",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Eliminate an unusual atronach lurking outside a Daedric shrine near Ald-ruhn."
    },
    {
        id = "gg_wm_hunter03lunatic",
        name = "The Lunatic",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Hunt down a dangerous cultist of Sheogorath on behalf of a contact."
    },
    {
        id = "gg_wm_hunter05vampire",
        name = "The Wayward Vampire",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Track down and eliminate an Orcish vampire hiding in a Daedric ruin."
    },
    {
        id = "gg_wm_hunter06mortal",
        name = "At the Crossroads",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Eliminate a dangerous cultist of Clavicus Vile who has gone rogue."
    },
    {
        id = "gg_wm_hunter07ashal",
        name = "Disrupting Ashalmawia",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Eliminate an important Molag Bal cultist in the Daedric shrine of Ashalmawia."
    },
    {
        id = "gg_wm_hunter08roth",
        name = "Disrupting Rotheran",
        category = "Daedric",
        subcategory = "Cult of Clavicus Vile",
        master = "Wishmaster Clavicus Vile Questline",
        text = "Eliminate an important Molag Bal cultist in the Dunmer stronghold of Rotheran."
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
