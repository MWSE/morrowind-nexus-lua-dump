local self = require('openmw.self')
local quests = {
    {
        id = "HT_PrisonerFelinglith",
        name = "Tel Uvirith: The Prisoner Felinglith",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "A prisoner held at Tel Uvirith awaits judgment, and I may choose to review her case myself."
    },

    {
        id = "HT_Uvi_DrathaDremora",
        name = "Dratha's Dremora",
        category = "House Telvanni",
        subcategory = "Mistress Dratha",
        master = "Uvirith's Legacy",
        text = "Mistress Dratha seeks my aid in a strange dremora matter that promises further complications."
    },

    {
        id = "HT_Zhariphel_Council",
        name = "The Zhariphel Council House",
        category = "Zhariphel",
        subcategory = "Mine",
        master = "Uvirith's Legacy",
        text = "The miners of Zhariphel want a proper council house, and someone must see the matter through."
    },

    {
        id = "HT_PrisonerValodius",
        name = "Tel Uvirith: The Prisoner Valodius",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "An Imperial prisoner in my dungeon appears to be under an unnatural affliction that merits investigation."
    },

    {
        id = "HT_MissingPrisoner",
        name = "Tel Uvirith: The Missing Prisoner",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "An escaped prisoner and a theft from my vaults have revealed a troubling breach beneath Tel Uvirith."
    },

    {
        id = "HT_Uvi_SaraRevenge",
        name = "Tel Uvirith: Jealousy and Revenge in the Tower",
        category = "Tel Uvirith",
        subcategory = "Tower Staff",
        master = "Uvirith's Legacy",
        text = "A petty feud among the women of my tower threatens to become something more troublesome."
    },

    {
        id = "HT_Uvi_Asharakumuk",
        name = "Asharakumuk",
        category = "Daedra",
        subcategory = "Ash-Kosh",
        master = "Uvirith's Legacy",
        text = "Ash-Kosh has shown me a strange place bound to its comings and goings."
    },

    {
        id = "HT_VampApprentice",
        name = "Vampirism: The Vampire Apprentice",
        category = "Vampirism",
        subcategory = "Apprentice",
        master = "Uvirith's Legacy",
        text = "My apprentice has become entangled in matters of vampirism, and I must decide how to handle him."
    },

    {
        id = "HT_UvirithCookies",
        name = "Salmeama's Cookies",
        category = "Tel Uvirith",
        subcategory = "Tower Staff",
        master = "Uvirith's Legacy",
        text = "A ridiculous dispute over Salmeama's guarded cookie jar has somehow become a matter in my tower."
    },

    {
        id = "HT_PrisonerNaked",
        name = "Tel Uvirith: The Naked Prisoner",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "A most unusual prisoner has been found in my tower, and I intend to learn why."
    },

    {
        id = "HT_UvirithVerena",
        name = "Tel Uvirith: The Troubles of Mistress Verena",
        category = "Tel Uvirith",
        subcategory = "Tower Staff",
        master = "Uvirith's Legacy",
        text = "Mistress Verena has become a growing problem in my household, and I must find a way to deal with her."
    },

    {
        id = "HT_VivecTeleport",
        name = "The Telvanni Canton Connection",
        category = "Travel",
        subcategory = "House Telvanni",
        master = "Uvirith's Legacy",
        text = "A proposal to improve Telvanni travel to Vivec may finally be within reach."
    },

    {
        id = "HT_Uvi_SaraStay",
        name = "Tel Uvirith: A Gift for Sara",
        category = "Tel Uvirith",
        subcategory = "Sara",
        master = "Uvirith's Legacy",
        text = "While Sara stays at Tel Uvirith, I may yet find a gift worthy of her."
    },

    {
        id = "GP_UvirithQueen",
        name = "Tel Uvirith: Queen of Uvirith",
        category = "Uvirith",
        subcategory = "Ancient Mysteries",
        master = "Uvirith's Legacy",
        text = "An ancient presence in Tel Uvirith has called upon me to accept a peculiar burden."
    },

    {
        id = "HT_DaedricBooks",
        name = "House Telvanni: The Books of Daedric Summoning.",
        category = "House Telvanni",
        subcategory = "Daedric Research",
        master = "Uvirith's Legacy",
        text = "Scattered pages from the Books of Daedric Summoning are said to hold dangerous knowledge worth recovering."
    },

    {
        id = "HT_VampResearch",
        name = "Vampirism: Experiments in Vampirism",
        category = "Vampirism",
        subcategory = "Research",
        master = "Uvirith's Legacy",
        text = "Existing writings on vampirism are lacking, so I have begun a line of research of my own."
    },

    {
        id = "HT_UvirithTomb",
        name = "Tel Uvirith: Uvirith's Tomb",
        category = "Uvirith",
        subcategory = "Ancient Mysteries",
        master = "Uvirith's Legacy",
        text = "A curse laid upon me in Uvirith's Tomb can only be answered by seeking out a powerful dremora."
    },

    {
        id = "HT_UviPrisoner",
        name = "Tel Uvirith: The Prisoner Arnamir",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "The wizard Arnamir remains in my custody, and his continued imprisonment may yet prove useful."
    },

    {
        id = "HT_Uvi_RockNPC",
        name = "Erwin the Rock",
        category = "House Telvanni",
        subcategory = "Mistress Dratha",
        master = "Uvirith's Legacy",
        text = "A most unfortunate victim of Dratha's magic may be persuaded back into proper shape."
    },

    {
        id = "HT_EddieTable",
        name = "Tel Uvirith: The Alchemy Table",
        category = "Tel Uvirith",
        subcategory = "Crafting",
        master = "Uvirith's Legacy",
        text = "Fast Eddie has pointed me toward a remarkable alchemy table that may be worth acquiring."
    },

    {
        id = "HT_Apprentice",
        name = "House Telvanni: The Master's Apprentice",
        category = "House Telvanni",
        subcategory = "Apprentice",
        master = "Uvirith's Legacy",
        text = "An opportunity has arisen to take on an apprentice for my household."
    },

    {
        id = "HT_PowerShift",
        name = "House Telvanni: Shifts in Power",
        category = "House Telvanni",
        subcategory = "Council Politics",
        master = "Uvirith's Legacy",
        text = "A former apprentice of Gothren has settled in Tel Aruhn, and his presence may upset the balance of power."
    },

    {
        id = "HT_UviWeather",
        name = "Tel Uvirith: Building The Tower Weather Control Device",
        category = "Tel Uvirith",
        subcategory = "Crafting",
        master = "Uvirith's Legacy",
        text = "Arnamir has offered knowledge for building a weather control device for my tower."
    },

    {
        id = "HT_Spellbook",
        name = "Tel Uvirith: The Tome of Ancient Knowledge",
        category = "Tel Uvirith",
        subcategory = "Arcane Research",
        master = "Uvirith's Legacy",
        text = "Fast Eddie has promised a rare tome of magical learning if I can secure the means to obtain it."
    },

    {
        id = "HT_Zhariphel",
        name = "House Telvanni: Problems in the Telvanni Mines",
        category = "Zhariphel",
        subcategory = "Mine",
        master = "Uvirith's Legacy",
        text = "There is trouble in the Telvanni mines, and I must learn what is wrong before it worsens."
    },

    {
        id = "HT_EddieBag",
        name = "Tel Uvirith: The Bag of Holding",
        category = "Tel Uvirith",
        subcategory = "Crafting",
        master = "Uvirith's Legacy",
        text = "A book from Master Aryon may contain the secret to making a magical bag of holding."
    },

    {
        id = "HT_Intruder",
        name = "Tel Uvirith: An Intruder in the Dungeon",
        category = "Tel Uvirith",
        subcategory = "Prison",
        master = "Uvirith's Legacy",
        text = "An intruder in my dungeon has left behind clues that suggest a deeper matter."
    },

    {
        id = "HT_Primus",
        name = "House Telvanni: Building a Better Centurion",
        category = "House Telvanni",
        subcategory = "Constructs",
        master = "Uvirith's Legacy",
        text = "Work has begun on an improved steam centurion for my tower, but the task requires materials."
    },

    {
        id = "DHM_Insc",
        name = "Tel Uvirith: Inscription Quills",
        category = "Tel Uvirith",
        subcategory = "Crafting",
        master = "Uvirith's Legacy",
        text = "My apprentice has set me on the path toward learning inscription, beginning with the proper tools."
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

-- Quest count: 29
