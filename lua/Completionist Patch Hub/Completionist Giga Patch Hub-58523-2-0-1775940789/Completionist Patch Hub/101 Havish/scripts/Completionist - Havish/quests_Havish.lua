local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: Havish
    -- #########################################################################

    {
        id = "ZH_FG_0_TG_Warehouse",
        name = "Fighters Guild: The Warehouse",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario had an extra job for them."
    },
    {
        id = "ZH_TG_12_Freelancer",
        name = "Guild of Thieves: A Freelancer Thief",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Eleret wants them to bring a letter to a freelancer thief named Safana."
    },
    {
        id = "ZH_TG_01_Warehouse",
        name = "Guild of Thieves: The Warehouse",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Erdenis gave them a Thieves Guild job: There's a cache of smuggled goods in the southeastern warehouse at the docks."
    },
    {
        id = "ZH_TG_B2_Heedcroft",
        name = "Guild of Thieves: Heedcroft Mansion",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Denia told them to break into Heedcroft Mansion tonight."
    },
    {
        id = "ZH_TG_P1_Messenger",
        name = "Guild of Thieves: The Messenger",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "A messenger from the far away kingdom of Ronielle arrived in Havish."
    },
    {
        id = "ZH_MG_04_Documents",
        name = "Mages Guild: Lost Documents",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "One of the Mages Guild's researchers died recently."
    },
    {
        id = "ZH_TG_P3_Heirloom",
        name = "Guild of Thieves: The Heirloom",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Prince Leshir Moniesce, the man mentioned in that letter one stole earlier, has arrived in Havish, and stays in the Golden Lady inn."
    },
    {
        id = "ZH_TG_S3_Shipment",
        name = "Guild of Thieves: The Missing Shipment",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "A few months ago, a shipment of smuggling goods vanished, and now Chebogg, the mate of the ship was seen in Havish."
    },
    {
        id = "ZH_TG_13_Payments",
        name = "Guild of Thieves: Payments",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Lonas Romaren has an arrangement with the Guild of Thieves: We don't steal from his shop, and get a weekly payment from him."
    },
    {
        id = "ZH_MG_05_Missions",
        name = "Mages Guild: Research Missions",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "A local adventurer talked to Thalemos again."
    },
    {
        id = "ZH_MG_06_Grimward",
        name = "Mages Guild: The Grimward",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "A local adventurer led Thalemos to the place one found, and he worked some spells that made a giant forcefield visible for a few seconds."
    },
    {
        id = "ZH_TG_B1_Drawing",
        name = "Guild of Thieves: The Drawing",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Denia Genechus sent them to Dante's House between Jeweler and Mages Guild."
    },
    {
        id = "ZH_TG_B3_Jeweler",
        name = "Guild of Thieves: The Jeweler's Guard",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Denia wants them to go to Alaina's House of Pleasures between 3 and 4 o' clock in the afternoon."
    },
    {
        id = "ZH_TG_A3_Missing",
        name = "Guild of Thieves: The Missing Girl",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Nevin Baran told them to go to Alaina's House of Pleasures."
    },
    {
        id = "ZH_TG_A2_Puritan",
        name = "Guild of Thieves: The Troublemaker",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Gwyneth Ergadice the owner of the Shimmering Unicorn Inn turns out to be a trouble for the guild."
    },
    {
        id = "ZH_TG_11_Servant",
        name = "Guild of Thieves: The Servant",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Eleret told them to make a visit to the Golden Lady Inn in the evening."
    },
    {
        id = "ZH_TG_15_Amulets",
        name = "Guild of Thieves: Five Amulets",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Eleret sent them out to find four forged emerald amulets."
    },
    {
        id = "ZH_MG_Teleporter",
        name = "Mages Guild: Teleporter Crystals",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "Valeria Nistrus operates a crystal based teleportation chamber, that enables her to transport people across the inner sea."
    },
    {
        id = "ZH_MG_02_Soulgem",
        name = "Mages Guild: Soulgem Express",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "Complete a task for Mages Guild."
    },
    {
        id = "ZH_TG_P2_Damsel",
        name = "Guild of Thieves: Damsel in Distress",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "One of the guild's pickpockets might be in trouble."
    },
    {
        id = "ZH_FG_6_Hunting",
        name = "Fighters Guild: On the Hunt",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario decided to be more aggressive against this animal threat."
    },
    {
        id = "ZH_TG_S1_Skooma",
        name = "Guild of Thieves: The Skooma Trade",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "There's a new source of cheap skooma in town."
    },
    {
        id = "ZH_MG_03_Dwemer",
        name = "Mages Guild: A Dwemer Soul",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "Thalemos is trying to find out why there are no traces of dwemer activities upon Kathaer Island."
    },
    {
        id = "ZH_TG_S2_Glass",
        name = "Guild of Thieves: Fake Glass",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "The guild has an arrangement with Irgola in Caldera."
    },
    {
        id = "ZH_FG_7_Escort",
        name = "Fighters Guild: Escort Service",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario sent them to the Frosty Mug inn."
    },
    {
        id = "ZH_FG_4_Gloves",
        name = "Fighters Guild: The stolen Gloves.",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario sent them to find a Bosmer named Mehindrel."
    },
    {
        id = "ZH_FG_8_Undead",
        name = "Fighters Guild: Undead Invasion",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario sent them to Cerebrold at the Order of Arkay."
    },
    {
        id = "ZH_TG_A1_Wheel",
        name = "Guild of Thieves: The Wheel of Fortune",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Nevin Baran sent them to the Loaded Dice tavern."
    },
    {
        id = "ZH_TG_14_Guard",
        name = "Guild of Thieves: A Troublesome Guard",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "There’s an officer of the citywatch named Demogil Luvelle, who is a bit too dedicated in hunting criminals for Eleret's taste."
    },
    {
        id = "ZH_MG_00_Start",
        name = "Mages Guild: Escort to Havish",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "A mage named Thalemos needs someone to escort him to a city called Havish."
    },
    {
        id = "ZH_MG_01_Necro",
        name = "Mages Guild: The Necromancer",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "Darbien Erdal sent them to the wilderness northwest of Havish."
    },
    {
        id = "ZH_TG_21_Honor",
        name = "Guild of Thieves: Honor among Thieves",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "When one returned from Sadrith Mora, Artemis Entreri waited for them near the Citadel."
    },
    {
        id = "ZH_TG_16_Bank",
        name = "Guild of Thieves: Clenton Residence",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Elerent sent them to the Clenton Residence next to the bank."
    },
    {
        id = "ZH_TG_00_Init",
        name = "Guild of Thieves: First Contact",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "When one entered the Kissing Wench tavern in Havish, a Bosmer bumped into them, and tried to lift some coins from their purse."
    },
    {
        id = "ZH_TG_02_Test",
        name = "Guild of Thieves: A Test of Wits",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "To become a member of Havish's Guild of Thieves, one has to pass another test."
    },
    {
        id = "ZH_Misc_House",
        name = "Estate in Havish",
        category = "Miscellaneous",
        subcategory = "",
        master = "Havish", text = "A local adventurer bought an estate in Havish."
    },
    {
        id = "ZH_MG_07_Mine",
        name = "Mages Guild: The Mine",
        category = "Mages Guild",
        subcategory = "",
        master = "Havish", text = "Again Thalemos relies upon their help."
    },
    {
        id = "ZH_FG_1_Wolf",
        name = "Fighters Guild: A Wild Animal",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "A wild animal got into a residence here in Havish."
    },
    {
        id = "ZH_FG_2_Tomb",
        name = "Fighters Guild: Search and Rescue",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Carus Vario sent them on a search and rescue mission to the old tombs southwest of Havish."
    },
    {
        id = "ZH_FG_5_Bear",
        name = "Fighters Guild: Another Wild Animal",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Another wild animal sneaked into a house in Havish."
    },
    {
        id = "ZH_FG_3_Rats",
        name = "Fighters Guild: Rats !!!",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Rats infested Havish, and Carus Vario wants their help in getting rid of them."
    },
    {
        id = "ZH_Init_TG",
        name = "Thieves Guild: A Visitor from Havish",
        category = "Thieves Guild",
        subcategory = "",
        master = "Havish", text = "Habasi asked them to find a Khajiit named J'Rashirr, who can be found somewhere here in Balmora."
    },
    {
        id = "ZH_Init_FG",
        name = "Fighters Guild: A Visitor from Havish",
        category = "Fighters Guild",
        subcategory = "",
        master = "Havish", text = "Eydis Fire-Eye sent them to the Lucky Lockup here in Balmora, there it seems wise to meed Artemis Entreri, who asked for the Fighter's Guild assistance."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Havish data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 43
