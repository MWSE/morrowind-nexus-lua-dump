local self = require('openmw.self')

local quests = {

    {
        id = "IL_RescueComrade",
        name = "Imperial Legion: The Missing Comrade",
        category = "Factions | Imperial Legion",
        subcategory = "Radd Hard-Heart",
        master = "Imperial Legion Expansion",
        text = "Rescue an Imperial Legion courier who has been imprisoned in Tel Vos."
    },

    {
        id = "IL_ArmorDelivery",
        name = "Imperial Legion: Arms Delivery",
        category = "Factions | Imperial Legion",
        subcategory = "Fort Pelagiad",
        master = "Imperial Legion Expansion",
        text = "Pick up a delayed shipment of Legion weapons and return it to Fort Pelagiad."
    },

    {
        id = "IL_Addamasartus",
        name = "Imperial Legion: Addamasartus",
        category = "Factions | Imperial Legion",
        subcategory = "Seyda Neen",
        master = "Imperial Legion Expansion",
        text = "Drive smugglers out of Addamasartus on behalf of a local citizen."
    },

    {
        id = "IL_HouseDagoth",
        name = "Imperial Legion: Dagoth Draven",
        category = "Factions | Imperial Legion",
        subcategory = "Angoril",
        master = "Imperial Legion Expansion",
        text = "Slay a Sixth House cultist threatening Imperial interests near Gnisis."
    },

    {
        id = "IL_NineDivines",
        name = "Imperial Legion: Amulets of the Nine Divines",
        category = "Factions | Imperial Legion",
        subcategory = "Imperial Cult",
        master = "Imperial Legion Expansion",
        text = "Search across Morrowind for the Amulets of the Nine Divines."
    },

    {
        id = "IL_AshVampire",
        name = "Imperial Legion: Dagoth Endus",
        category = "Factions | Imperial Legion",
        subcategory = "Angoril",
        master = "Imperial Legion Expansion",
        text = "Hunt down the Ash Vampire Dagoth Endus within the Ghostfence."
    },

    {
        id = "IL_Vigilance",
        name = "Imperial Legion: Vigilance",
        category = "Factions | Imperial Legion",
        subcategory = "Angoril",
        master = "Imperial Legion Expansion",
        text = "Carry out a discreet mission against a criminal operating near Vivec."
    },

    {
        id = "IL_Innocence",
        name = "Imperial Legion: Comrade in Trouble",
        category = "Factions | Imperial Legion",
        subcategory = "Frald the White",
        master = "Imperial Legion Expansion",
        text = "Undertake a quiet investigation in Vivec to aid a fellow legionnaire."
    },

    {
        id = "AA_Publius",
        name = "Publius Claudius",
        category = "Factions | Imperial Legion",
        subcategory = "Companion Questline",
        master = "Imperial Legion Expansion",
        text = "Serve alongside Publius Claudius and share in his duties as a legionnaire."
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