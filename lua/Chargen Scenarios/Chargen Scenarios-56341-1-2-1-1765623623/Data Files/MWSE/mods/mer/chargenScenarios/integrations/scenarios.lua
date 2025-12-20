local TagManager = require("CraftingFramework").TagManager
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")
local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Scenarios")

local requiresBeastRace = {
    races = {"Argonian", "Khajiit"}
}

local cookingPots = {
    "ashfall_cooking_pot",
    "ashfall_cooking_pot_steel",
    "ashfall_cooking_pot_iron",
}

local requiresOaabShipwreck = {
    plugins = {"OAAB - Shipwrecks.ESP"}
}

local excludesOaabShipwreck = {
    excludedPlugins = {"OAAB - Shipwrecks.ESP"},
}

local taverns = {
    { --Ald-ruhn, Ald Skar Inn
        position = {556, -1140, 2},
        orientation =-3,
        cellId = "Ald-ruhn, Ald Skar Inn"
    },
    { --Balmora, Lucky Lockup
        position = {190, 1244, -505},
        orientation =-3,
        cellId = "Balmora, Lucky Lockup"
    },
    { --Caldera, Shenk's Shovel
        position = {254, -299, 130},
        orientation =-1,
        cellId = "Caldera, Shenk's Shovel"
    },
    { --Dagon Fel, The End of the World
        position = {-509, -12, 130},
        orientation =1.57,
        cellId = "Dagon Fel, The End of the World"
    },
    { --Ebonheart, Six Fishes
        position = {202, 565, 2},
        orientation =-4,
        cellId = "Ebonheart, Six Fishes"
    },
    { --Gnisis, Madach Tradehouse
        position = {24, 646, -126},
        orientation =-4,
        cellId = "Gnisis, Madach Tradehouse"
    },
    { --Maar Gan, Andus Tradehouse
        position = {186, 33, 2},
        orientation =-1,
        cellId = "Maar Gan, Andus Tradehouse"
    },
    { --Molag Mar, The Pilgrim's Rest
        position = {-508, -375, 2},
        orientation =-1,
        cellId = "Molag Mar, The Pilgrim's Rest"
    },
    {  --Pelagiad
        position = {407, 236, 105},
        orientation = 0,
        cellId = "Pelagiad, Halfway Tavern"
    },
    { --Sadrith Mora, Gateway Inn
        position = {4009, 4318, 766},
        orientation =0,
        cellId = "Sadrith Mora, Gateway Inn"
    },
    { --Suran, Desele's House of Earthly Delights
        position = {324, -247, 7},
        orientation =-2,
        cellId = "Suran, Desele's House of Earthly Delights"
    },
    { --Tel Mora, The Covenant
        position = {1315, -364, 606},
        orientation =0,
        cellId = "Tel Mora, The Covenant"
    },
    { --Vivec, The Lizard's Head
        position = {-231, -9, -126},
        orientation =1,
        cellId = "Vivec, The Lizard's Head"
    },

    --TR
    { --Aimrah, The Sailors' Inn
        position = {3768, 3434, 14681},
        orientation =-1,
        cellId = "Aimrah, The Sailors' Inn"
    },

    { --Hunted Hound Inn
        position = {4206, 3500, 15554},
        orientation =-2,
        cellId = "Hunted Hound Inn"
    },


    { --The Inn Between
        position = {3838, 4137, 14466},
        orientation =0,
        cellId = "The Inn Between"
    },


    { --Akamora, The Laughing Goblin
        position = {3059, 3518, 130},
        orientation =1,
        cellId = "Akamora, The Laughing Goblin"
    },


    { --Almas Thirr, Limping Scrib
        position = {654, -543, 2},
        orientation =-1,
        cellId = "Almas Thirr, Limping Scrib"
    },


    { --Andothren, The Dancing Cup
        position = {4306, 4122, 13959},
        orientation =1,
        cellId = "Andothren, The Dancing Cup"
    },


    { --Bodrum, Varalaryn Tradehouse
        position = {831, -1390, -382},
        orientation =-3,
        cellId = "Bodrum, Varalaryn Tradehouse"
    },


    { --Bosmora, The Starlight Inn
        position = {4095, 5119, 15558},
        orientation =3,
        cellId = "Bosmora, The Starlight Inn"
    },


    { --Firewatch, The Queen's Cutlass
        position = {6271, 3678, 16258},
        orientation =0,
        cellId = "Firewatch, The Queen's Cutlass"
    },


    { --Helnim, The Red Drake
        position = {4465, 4135, 14850},
        orientation =-2,
        cellId = "Helnim, The Red Drake"
    },


    { --Necrom, Pilgrim's Respite
        position = {3692, 2306, 12162},
        orientation =1,
        cellId = "Necrom, Pilgrim's Respite"
    },


    { --Old Ebonheart, The Moth and Tiger
        position = {-809, 387, 2},
        orientation =1,
        cellId = "Old Ebonheart, The Moth and Tiger"
    },


    { --Port Telvannis, The Lost Crab Tavern
        position = {3934, 4538, 14114},
        orientation =-4,
        cellId = "Port Telvannis, The Lost Crab Tavern"
    },


    { --Ranyon-ruhn, The Dancing Jug
        position = {4263, 4003, 15170},
        orientation =-1,
        cellId = "Ranyon-ruhn, The Dancing Jug"
    },


    { --Sailen, The Toiling Guar
        position = {3298, 3754, 11266},
        orientation =1,
        cellId = "Sailen, The Toiling Guar"
    },

    { --Vhul, The Howling Hound
        position = {3639, 3889, 15554},
        orientation =0,
        cellId = "Vhul, The Howling Hound"
    },

    { --Anvil, Three Sturgeons Pub
        position = {4170, 4083, 15714},
        orientation =-1.54,
        cellId = "Anvil, Three Sturgeons Pub"
    },
}

---@type ChargenScenariosScenarioInput[]
local scenarios = {
    {
        id = "vanilla",
        name = "--Vanilla--",
        description = "Start the game in the Seyda Neen Census and Excise Office.",
        location = {
            orientation = 2,
            position = {33,-87,194},
            cellId = "Seyda Neen, Census and Excise Office"
        },
        journalEntry = "I need to speak with Sellus Gravius to discuss my duties.",
        items = {
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "hidingFromTheLaw",
        name = "Hiding from the Law",
        description = "You are a wanted criminal, hiding in the outskirts of the Ascadian Isles.",
        location = {
             position = { 13078, -78339, 402},
             orientation = 217
        },
        onStart = function(self)
            tes3.player.mobile.bounty =
                tes3.mobilePlayer.bounty + 75
            tes3.modStatistic{
                reference = tes3.player.mobile,
                name = "health",
                current = math.ceil(tes3.player.object.health * 75)
            }
        end,
        items = {
            {
                description = "Stolen gems",
                ids = {
                    "ingred_diamond_01",
                    "ingred_emerald_01",
                    "ingred_ruby_01"
                },
                count = 3
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "The authorities are after me, and there's a price on my head. The next move is clear: either sell these gems and gather enough money to pay the fine, or track down the Thieves Guild. I've heard they can clear my name... for the right price. Either way, I can't stay hidden forever.",
    },
    {
        id = "pearlDiving",
        name = "Pearl Diving",
        description = "You are diving for pearls in the waters near Pelagiad",
        location = {
            position = {12481, -61011, -280},
            orientation = 0,
        },
        journalUpdates = {
            { id = "mer_cs_pearl" }
        },
        topics = {
            "sell pearls"
        },
        items = {
            {
                id = "ingred_pearl_01",
                count = 2,
            },
            {
                id = "chitin spear",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "huntingInGrazelands",
        name = "Hunting in the Grazelands",
        description = "You are a hunter, stalking your prey in the Grazelands.",
        journalUpdates = {
            { id = "mer_cs_hunt" }
        },
        location = {
            position = {74894, 124753, 1371},
            orientation = 0,
        },
        topics = {
            "sell fresh meat"
        },
        items = {
            {
                id = "ingred_hound_meat_01",
                count = 3
            },
            {
                id = "long bow",
                count = 1,
                noSlotDuplicates = true,
            },
            {
                id = "chitin arrow",
                count = 30,
            },
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "workingInTheFields",
        name = "Working in the Fields",
        description = "You are a lowly slave, toiling in the fields outside of Pelagiad.",
        journalUpdates = {
            { id = "mer_cs_field" }
        },
        location = {
            position = {13449, -57064, 136},
            orientation = 0,
        },
        topics = {
            "remove slave bracer",
        },
        items = {
            {
                id = "ingred_saltrice_01",
                count = 6
            },
            itemPicks.randomCommonPants,
        },
        requirements = requiresBeastRace,
        onStart = function(self)
            --equip the slave bracer
            timer.start{
                duration = 0.6,
                callback = function()
                    tes3.equip{
                        item = "mer_cs_slave_bracer",
                        reference = tes3.player,
                        addItem = true,
                    }
                end
            }
        end,
    },
    {
        id = "gatheringMushrooms",
        name = "Gathering Mushrooms",
        description = "You are in the swamps of the Bitter Coast, searching for ingredients.",
        journalUpdates = {
            { id = "mer_cs_mushrooms" }
        },
        topics = {
            "mushrooms"
        },
        location = {
            position = {-44618, 29841, 598},
            orientation =2,
        },
        items = {
            {
                id = "apparatus_a_mortar_01",
                count = 1,
                noDuplicates = true,
            },
            {
                description = "Mushrooms",
                ids = {
                    "ingred_bc_bungler's_bane",
                    "ingred_bc_hypha_facia",
                    "ingred_bc_coda_flower",
                    "ingred_bc_spore_pod",
                    "ingred_bc_ampoule_pod"
                },
                count = 4
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "graveRobbing",
        name = "Grave Robbing",
        description = "You are a grave robber looting an ancestral tomb.",
        locations = {
            { --Andalen Ancestral Tomb
                position = {878, -1008, 258},
                orientation =-1,
                cellId = "Andalen Ancestral Tomb"
            },
            { --Andalor Ancestral Tomb
                position = {3065, 2881, 386},
                orientation =-2,
                cellId = "Andalor Ancestral Tomb"
            },
            { --Andas Ancestral Tomb
                position = {763, -542, -702},
                orientation =-1,
                cellId = "Andas Ancestral Tomb"
            },
            { --Andavel Ancestral Tomb
                position = {-5194, -601, 2050},
                orientation =-4,
                cellId = "Andavel Ancestral Tomb"
            },
            { --Andrethi Ancestral Tomb
                position = {2617, 1182, -894},
                orientation =-2,
                cellId = "Andrethi Ancestral Tomb"
            },
            { --Andules Ancestral Tomb
                position = {-900, 26, 257},
                orientation =0,
                cellId = "Andules Ancestral Tomb"
            },
            { --Aran Ancestral Tomb
                position = {-2353, 5163, -190},
                orientation =3,
                cellId = "Aran Ancestral Tomb"
            },
            { --Arethan Ancestral Tomb
                position = {-737, 1530, -30},
                orientation =-1,
                cellId = "Arethan Ancestral Tomb"
            },
            { --Arys Ancestral Tomb
                position = {12802, -4140, -702},
                orientation =-1,
                cellId = "Arys Ancestral Tomb"
            },
            { --Baram Ancestral Tomb
                position = {-2533, 248, 1442},
                orientation =-4,
                cellId = "Baram Ancestral Tomb"
            },
            { --Dareleth Ancestral Tomb
                position = {3802, -3038, 1602},
                orientation =-2,
                cellId = "Dareleth Ancestral Tomb"
            },
            { --Dreloth Ancestral Tomb
                position = {0, 1907, 130},
                orientation =3,
                cellId = "Dreloth Ancestral Tomb"
            },
            { --Drinith Ancestral Tomb
                position = {-300, -4552, 2722},
                orientation =-4,
                cellId = "Drinith Ancestral Tomb"
            },
            { --Falas Ancestral Tomb
                position = {-2705, -1280, 1282},
                orientation =1,
                cellId = "Falas Ancestral Tomb"
            },
            { --Helan Ancestral Tomb
                position = {-1776, 380, 258},
                orientation =1,
                cellId = "Helan Ancestral Tomb"
            },
            { --Heran Ancestral Tomb
                position = {-17, 2755, 258},
                orientation =3,
                cellId = "Heran Ancestral Tomb"
            },
            { --Hlaalu Ancestral Tomb
                position = {-249, 1261, 386},
                orientation =3,
                cellId = "Hlaalu Ancestral Tomb"
            },
            { --Hlervi Ancestral Tomb
                position = {3202, -876, 1058},
                orientation =-2,
                cellId = "Hlervi Ancestral Tomb"
            },
            { --Hlervu Ancestral Tomb
                position = {9, 2544, -510},
                orientation =3,
                cellId = "Hlervu Ancestral Tomb"
            },
            { --Indalen Ancestral Tomb
                position = {-487, -97, 2466},
                orientation =3,
                cellId = "Indalen Ancestral Tomb"
            },
            { --Lleran Ancestral Tomb
                position = {995, -958, 98},
                orientation =0,
                cellId = "Lleran Ancestral Tomb"
            },
            { --Norvayn Ancestral Tomb
                position = {-1156, -1793, 1666},
                orientation =1,
                cellId = "Norvayn Ancestral Tomb"
            },
            { --Releth Ancestral Tomb
                position = {2690, 901, 386},
                orientation =-2,
                cellId = "Releth Ancestral Tomb"
            },
            { --Rethandus Ancestral Tomb
                position = {-3160, -100, 1410},
                orientation =-4,
                cellId = "Rethandus Ancestral Tomb"
            },
            { --Sadryn Ancestral Tomb
                position = {703, -639, 34},
                orientation =0,
                cellId = "Sadryon Ancestral Tomb"
            },
            { --Samarys Ancestral Tomb
                position = {-2272, 992, 258},
                orientation =1,
                cellId = "Samarys Ancestral Tomb"
            },
            { --Sandas Ancestral Tomb
                position = {1660, 7, 258},
                orientation =-2,
                cellId = "Sandas Ancestral Tomb"
            },
            { --Sarys Ancestral Tomb
                position = {7028, 4415, 14914},
                orientation =-2,
                cellId = "Sarys Ancestral Tomb"
            },
            { --Tharys Ancestral Tomb
                position = {2092, 272, -190},
                orientation =-2,
                cellId = "Tharys Ancestral Tomb"
            },
            { --Thelas Ancestral Tomb
                position = {374, 3176, 770},
                orientation =3,
                cellId = "Thelas Ancestral Tomb"
            },
            { --Uveran Ancestral Tomb
                position = {1934, -1559, 1695},
                orientation =-4,
                cellId = "Uveran Ancestral Tomb"
            },
        },
        items = {
            itemPicks.silverWeapon,
            {
                id = "pick_apprentice_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "probe_apprentice_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "I've found an ancestral tomb, its secrets untouched for who knows how long. Whatever spirits haunt this place won't care if I help myself to a little of what's left behind… right?",
        onStart = function()
            timer.start{
                duration = math.random(12, 24),
                type = timer.game,
                callback = "mer_scenarios_ghostTimer",
                persist = true
            }
            tes3.equip{
                item = "light_com_torch_01_256",
                reference = tes3.player,
                addItem = true,
            }
        end
    },
    {
        id = "magesGuild",
        name = "Faction: Mages Guild",
        description = "You are an associate of the Mages Guild.",
        factions = {
            { id = "Mages Guild"}
        },
        journalEntry = "I have joined the Mages Guild. I should speak with the guild steward to see what duties they have for me.",
        locations = {
            {
                position = {14, 187, -252},
                orientation =-4,
                name = "Vivec",
                cellId = "Vivec, Guild of Mages"
            },
            {
                position = {370, -584, -761},
                orientation =-4,
                name = "Balmora",
                cellId = "Balmora, Guild of Mages"
            },
            {
                position = {695, 537, 404},
                orientation =0,
                name = "Caldera",
                cellId = "Caldera, Guild of Mages"
            },
            {
                position = {186, 542, 66},
                orientation =0,
                name = "Sadrith Mora",
                cellId = "Sadrith Mora, Wolverine Hall: Mage's Guild"
            },

            { --Akamora, Guild of Mages
                name = "Akamora",
                position = {78, -447, -382},
                orientation =-1,
                cellId = "Akamora, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Almas Thirr, Guild of Mages
                name = "Almas Thirr",
                position = {222, -215, -62},
                orientation =-3,
                cellId = "Almas Thirr, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Andothren, Guild of Mages
                name = "Andothren",
                position = {7847, 4297, 15203},
                orientation =0,
                cellId = "Andothren, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Firewatch, Guild of Mages
                name = "Firewatch",
                position = {5188, 2511, 10842},
                orientation =-2,
                cellId = "Firewatch, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Helnim, Guild of Mages
                name = "Helnim",
                position = {4730, 3631, 12660},
                orientation =2,
                cellId = "Helnim, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Old Ebonheart, Guild of Mages
                name = "Old Ebonheart",
                position = {4295, 4496, 15234},
                orientation =2,
                cellId = "Old Ebonheart, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Narsis, Guild of Mages: Laboratories
                name = "Narsis",
                position = {4162, 4208, 12263},
                orientation =-3.12,
                cellId = "Narsis, Guild of Mages: Laboratories",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
        },
        items = {
            {
                id = "bookskill_Alchemy2",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.gold(25),
            itemPicks.robe,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },

    },
    {
        id = "fightersGuild",
        name = "Faction: Fighters Guild",
        description = "You are an associate of the Fighters Guild.",
        factions = {
            { id = "Fighters Guild" },
            { id = "T_Sky_FightersGuild" }
        },
        topics = {
            "join the Fighters Guild",
            "advancement",
            "orders",
        },
        journalEntry = "I have joined the Fighters Guild. I should speak with the guild steward to see what duties they have for me.",
        locations = {
            {
                position = {-901, -379, -764},
                orientation =0,
                name = "Ald-Rhun",
                cellId = "Ald-ruhn, Guild of Fighters",
            },
            {
                position = {304, 293, -377},
                orientation =0,
                name = "Balmora",
                cellId = "Balmora, Guild of Fighters"
            },
            {
                position = {306, -222, 3},
                orientation =-1,
                name = "Sadrith Mora",
                cellId = "Sadrith Mora, Wolverine Hall: Fighter's Guild"
            },
            {
                position = {179, 822, -508},
                orientation =-2,
                name = "Vivec",
                cellId = "Vivec, Guild of Fighters"
            },


            { --Akamora, Guild of Fighters
                name = "Akamora",
                position = {4431, 4280, 12674},
                orientation =-4,
                cellId = "Akamora, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Almas Thirr, Guild of Fighters
                name = "Almas Thirr",
                position = {4168, 4355, 14979},
                orientation =-4,
                cellId = "Almas Thirr, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Andothren, Guild of Fighters
                name = "Andothren",
                position = {2399, 4231, 14983},
                orientation =3,
                cellId = "Andothren, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Firewatch, Guild of Fighters
                name = "Firewatch",
                position = {4160, 3752, 15714},
                orientation =-2,
                cellId = "Firewatch, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Helnim, Guild of Fighters
                name = "Helnim",
                position = {5597, 4024, 15970},
                orientation =3,
                cellId = "Helnim, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Old Ebonheart, Guild of Fighters
                name = "Old Ebonheart",
                position = {3928, 324, 11714},
                orientation =1,
                cellId = "Old Ebonheart, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            --SHOTN
            { --Karthwasten, Guild of Fighters
                name = "Karthwasten",
                position = {4817, 3730, 15874},
                orientation =-1.5,
                cellId = "Karthwasten, Guild of Fighters",
                requirements = {
                    plugins = { "Sky_Main.esm" }
                }
            },
            { --Narsis, Guild of Fighters
                name = "Narsis",
                position = {31, 758, -121},
                orientation =-0.03,
                cellId = "Narsis, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
        },
        items = {
            {
                id = "p_restore_health_s",
                count = 4,
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "thievesGuild",
        name = "Faction: Thieves Guild",
        description = "You are a freshly recruited Toad of the Thieves Guild, hiding out with your fellow thieves at the South Wall Cornerclub in Balmora.",
        location = { --Balmora, South Wall Cornerclub
            position = {255, -21, -250},
            orientation = 0 ,
            cellId = "Balmora, South Wall Cornerclub"
        },
        items = {
            {
                id = "probe_apprentice_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "pick_apprentice_01",
                count = 2,
            },
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "join the Thieves Guild",
            "jobs",
            "advancement",
            "price on your head"
        },
        factions = {
            { id = "Thieves Guild"}
        },
        journalEntry = "I have joined the Thieves Guild. I should speak with Sugar-Lips Habasi to receive my first job.",
    },
    {
        id = "imperialCult",
        name = "Faction: Imperial Cult",
        description = "You are a layman of the Imperial Cult.",
        locations = {
            { --Ebonheart, Imperial Chapels
                position = {366, -638, 2},
                orientation =0,
                cellId = "Ebonheart, Imperial Chapels"
            },
            { --Karthwasten, Imperial Cult Chapel
                position = {4959, 4016, 15874},
                orientation =3.08,
                cellId = "Karthwasten, Imperial Cult Chapel"
            },
        },
        items = {
            {
                id = "bk_formygodsandemperor",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "common_robe_01",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "Imperial cult",
            "lay member",
            "join the Imperial Cult",
            "requirements",
            "blessings",
            "services"
        },
        journalUpdates = {
            { id = "IC0_ImperialCult", index = 1 },
            { id = "IC_guide", index = 2 }
        },
        factions = {
            { id = "Imperial Cult"}
        },
    },
    {
        id = "imperialLegion",
        name = "Faction: Imperial Legion",
        description = "You are a recruit of the Imperial Legion, awaiting orders in Gnisis.",
        locations = {
            {
                position = {103, 1043, -894},
                orientation = 1,
                cellId = "Gnisis, Madach Tradehouse",
                requirements = {
                    excludedPlugins = { "Beautiful cities of Morrowind.ESP" }
                }
            },
            { --Imperial Legion - Gnisis, Madach Tradehouse
                position = {393, -574, -2046},
                orientation =2.03,
                cellId = "Gnisis, Madach Tradehouse",
                requirements = {
                    plugins = { "Beautiful cities of Morrowind.ESP" }
                }
            },
        },
        items = {
            {
                id = "imperial_chain_cuirass",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "join the Imperial Legion",
            "orders",
            "advancement",
            "requirements"
        },
        onStart = function()
            timer.delayOneFrame(function()
                tes3.equip{ reference = tes3.player, item = "imperial_chain_cuirass" }
                tes3.findGlobal("WearingLegionUni").value = 1
                local darius = tes3.getReference("general darius")
                if darius then
                    darius.mobile.talkedTo = true
                end
            end)
        end,
        factions = {
            { id = "Imperial Legion"}
        },
        journalEntry = "It is my first day in the Imperial Legion. I must speak with General Darius to receive my orders.",
    },
    {
        id = "moragTong",
        name = "Faction: Morag Tong",
        description = "You have been given a writ of execution by the Morag Tong. You must carry out this lawful murder in order to be accepted into the ancient guild of assassins.",
        location =     { --Vivec, Arena Hidden Area
            position = {684, 508, 2},
            orientation =3,
            cellId = "Vivec, Arena Hidden Area"
        },
        journalEntry = "I have been given a writ of execution by the Morag Tong. I must carry out this lawful murder in order to be accepted into the ancient guild of assassins.",
        items = {
            {
                id = "writ_oran",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "sc_ondusisunhinging",
                count = 1
            },
            {
                id = "probe_apprentice_01",
                count = 1,
            },
            {
                id = "cruel viperblade",
                count = 1,
                noDuplicates = true,
            },
            {
                description = "Morag Tong Helm",
                ids = {
                    "morag_tong_helm",
                    "ab_a_moragtonghelm01",
                    "ab_a_moragtonghelm02",
                    "ab_a_moragtonghelm03",
                    "ab_a_moragtonghelm04",
                },
                count = 1,
                noDuplicates = true,
            },
            {
                id = "netch_leather_cuirass",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "join the Morag Tong",
            "Feruren Oran",
            "writ",
        },
        journalUpdates = {
            { id = "MT_WritOran", index = 10 }
        },
        factions = {
            { id = "Morag Tong"}
        },
    },
    {
        id = "houseTelvanni",
        name = "Faction: House Telvanni",
        description = "You are a hireling of House Telvanni, waiting in attendance of the Mouths at the Council Hall in Sadrith Mora.",
        journalEntry = "I am a hireling of House Telvanni. I must speak with the Mouths to receive my first orders.",
        location =     { --Sadrith Mora, Telvanni Council House
            position = {47, -232, 201},
            orientation =-1,
            cellId = "Sadrith Mora, Telvanni Council House"
        },
        items = {
            itemPicks.robe,
            itemPicks.soulGems(3),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "join House Telvanni",
            "chores",
            "advancement",
            "rules",
            "requirements"
        },
        factions = {
            { id = "Telvanni" }
        },
    },
    {
        id = "houseHlaalu",
        name = "Faction: House Hlaalu",
        description = "You are a hireling of House Hlaalu, ready to take up your first order of business in Balmora.",
        journalEntry = "I am a hireling of House Hlaalu. I should speak with Nileno Dorvayn to discuss business.",
        location =     { --Balmora, Hlaalu Council Manor
            position = {-120, 655, 7},
            orientation =-4,
            cellId = "Balmora, Hlaalu Council Manor"
        },
        items = {
            {
                id = "misc_inkwell",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "misc_quill",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "sc_paper plain",
                count = 3,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        topics = {
            "join House Hlaalu",
            "House Hlaalu",
            "Hlaalu councilors",
            "business",
            "advancement"
        },
        factions = {
            { id = "Hlaalu" }
        },
    },
    {
        id = "houseRedoran",
        name = "Faction: House Redoran",
        description = "You are a hireling of House Redoran, waiting in attendance of the Councilors at the Redoran Council Hall in Ald'ruhn.",
        journalEntry = "I am a hireling of House Redoran. I should speak with Neminda at the Redoral Council Entrance to receive my first orders.",
        location = { --Ald-ruhn, Redoran Council Entrance
            position = {749, 763, -126},
            orientation =0,
            cellId = "Ald-ruhn, Redoran Council Entrance"
        },
        items = {
            {
                id = "bonemold_gah-julan_helm",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        factions = {
            { id = "Redoran" }
        },
        topics = {
            "join House Redoran",
            "duties",
            "advancement"
        },
    },
    {
        id = "ashlander",
        name = "Ashlander",
        description = "You live with a small group of Ashlanders in a yurt on the coast of the Grazelands.",
        topics = {
            "our camp"
        },
        journalUpdates = {
            { id = "mer_cs_ashlander", showMessage = true }
        },
        location = { --Massahanud Camp, Sargon's Yurt
            position = {4256, 4014, 15698},
            orientation =-1,
            cellId = "Massahanud Camp, Sargon's Yurt"
        },
        items = {
            { id = "Thisitemdoesn'texist"},
            { id = "ashfall_knife_flint"},
            {
                id = "ashfall_tent_ashl_m",
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        onStart = function (self)
            --Add disposition to nearby Ashlanders
            local friends = {
                "manabi kummimmidan",
                "yahaz ashurnasaddas",
                "sargon santumatus",
                "teshmus assebiriddan"
            }
            for _, id in ipairs(friends) do
                local friendRef = tes3.getReference(id)
                if friendRef then
                    if tes3.modDisposition then
                        tes3.modDisposition{
                            reference = friendRef,
                            value = 40
                        }
                    end
                end
            end
            --Find the nearest active_de_bedroll and remove ownership
            local closestBedroll = nil
            local closestDistance = 999999
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
                if ref.object.id == "active_de_bedroll" then
                    local distance = tes3.player.position:distance(ref.position)
                    if distance < closestDistance then
                        closestBedroll = ref
                        closestDistance = distance
                    end
                end
            end
            if closestBedroll then
                mwse.log("Replacing with player bedroll")
                local newObject = closestBedroll.object:createCopy{}
                newObject.name = "Your Bedroll"
                tes3.createReference{
                    object = newObject,
                    position = closestBedroll.position:copy(),
                    orientation = closestBedroll.orientation:copy(),
                    cell = closestBedroll.cell,
                }
                closestBedroll:delete()
            end
        end,
    },
    {
        id = "lumberjack",
        name = "Lumberjack",
        description = "You are gathering firewood in the wilderness.",
        journalEntry = "It's been a long day gathering firewood. I should head back to town to sell it.",
        location = {
            position = {38154, -53328, 931},
            orientation = 268,
        },
        requirements = {
            plugins = { "Ashfall.ESP" }
        },
        items = {
            itemPicks.axe,
            {
                id = "ashfall_firewood",
                count = 8
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 15,
    },
    {
        id = "prisoner",
        name = "Imprisoned",
        description = "You are imprisoned in the Vivec Hlaalu Prison.",
        journalEntry = "I was released from the prison in Vivec today. Before my arrest, I hid some gold near the entrance to Othrelas Ancestral Tomb, tucked behind a corkbulb root. It's time to reclaim what's mine.",
        location = {
            position = {274, -214, -100},
            orientation = 0,
            cellId = "Vivec, Hlaalu Prison Cells"
        },
        clutter = {
            {
                ids = { "mer_cs_imprisoned_chest" },
                position = { 17989, -69980, 160 },
                orientation = {0, 0, 0},
            }
        },
        items = {
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        onStart = function()
            timer.start{
                duration = 1,
                callback = function()
                    ---Find nearest door and open it
                    local doorId = "in_v_s_jaildoor_01"
                    local nearestDoor = nil
                    for door in tes3.player.cell:iterateReferences(tes3.objectType.door) do
                        if door.baseObject.id:lower() == doorId then
                            if not nearestDoor then
                                nearestDoor = door
                            else
                                if tes3.player.position:distance(door.position) < tes3.player.position:distance(nearestDoor.position) then
                                    nearestDoor = door
                                end
                            end
                        end
                    end
                    if nearestDoor then
                        tes3.unlock{ reference = nearestDoor }
                        tes3.player:activate(nearestDoor)
                    end

                    --Find nearest ordinator and make them speak
                    local ordinatorId = "ordinator wander_hp"
                    local nearestOrdinator = nil
                    for ordinator in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                        if ordinator.baseObject.id:lower() == ordinatorId then
                            if not nearestOrdinator then
                                nearestOrdinator = ordinator
                            else
                                if tes3.player.position:distance(ordinator.position) < tes3.player.position:distance(nearestOrdinator.position) then
                                    nearestOrdinator = ordinator
                                end
                            end
                        end
                    end
                    if nearestOrdinator then
                        tes3.say{
                            reference = nearestOrdinator,
                            text = "Move along, Outlander.",
                            soundPath = "Vo\\d\\m\\Hlo_DM111.mp3"
                        }
                    end
                end
            }
        end
    },
    {
        id = "shipwrecked",
        name = "Shipwrecked",
        description = "You are the sole survivor of a shipwreck.",
        journalEntry = "I am the sole survivor of a shipwreck. I must find a way to survive and make my way back to civilization.",
        locations = {
            {  --abandoned shipwreck - OAAB
                name = "Abandoned Shipwreck",
                position = {9256, 187865, 79},
                orientation = 2,
                requirements = requiresOaabShipwreck,
            },
            {  --Lonesome shipwreck - OAAB
                name = "Lonesome Shipwreck",
                position = {112247, 127534, 30},
                orientation = -2,
                requirements = requiresOaabShipwreck,
            },
            {  --neglected shipwreck - OAAB
                name = "Neglected Shipwreck",
                position = {4049, 4179, 79},
                orientation = -3,
                cellId = "Neglected Shipwreck, Cabin",
                requirements = requiresOaabShipwreck,
            },
            --DISABLED - adds skeletons which will kill you instantly
            -- {  --prelude shipwreck - OAAB
            --     name = "Prelude Shipwreck",
            --     position = {4170, 4245, 63},
            --     orientation = -3,
            --     cellId = "Prelude Shipwreck, Cabin",
            --     requirements = requiresOaabShipwreck,
            -- },
            {  --remote shipwreck - OAAB
                name = "Remote Shipwreck",
                position = {-8307, -84454, 93},
                orientation =-2,
                requirements = requiresOaabShipwreck,
            },
            {  --shunned shipwreck - OAAB
                name = "Shunned Shipwreck",
                position = {-74895, 14527, -29},
                orientation =-3,
                requirements = requiresOaabShipwreck,
            },
            { -- abandoned shipwreck - Vanilla
                name = "Abandoned Shipwreck",
                position = {-1, -185, -26},
                orientation =-4,
                requirements = excludesOaabShipwreck,
                cellId = "Abandoned Shipwreck, Cabin"
            },
            { -- derelict shipwreck - Vanilla
                name = "Derelict Shipwreck",
                position = {-51690, 152197, 256},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- deserted shipwreck - Vanilla
                name = "Deserted Shipwreck",
                position = {74492, -85701, 29},
                orientation =-4,
                requirements = excludesOaabShipwreck,
            },
            { -- lonely shipwreck - Vanilla
                name = "Lonely Shipwreck",
                position = {154892, -6903, 51},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- lost shipwreck - Vanilla
                name = "Lost Shipwreck",
                position = {127322, 94621, -50},
                orientation = 2,
                requirements = excludesOaabShipwreck,
            },
            { -- remote shipwreck - Vanilla
                name= "Remote Shipwreck",
                position = {-7894, -84541, 90},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- shunned shipwreck - Vanilla
                name= "Shunned Shipwreck",
                position = {-75958, 14512, -20},
                orientation =1,
                requirements = excludesOaabShipwreck,
            },
            { -- strange shipwreck - Vanilla
                name= "Strange Shipwreck",
                position = {4172, 4017, 15651},
                orientation =-1,
                requirements = excludesOaabShipwreck,
                cellId = "Strange Shipwreck, Cabin"
            },
            { -- unchartered shipwreck - Vanilla
                name= "Unchartered Shipwreck",
                position = {4221, 4034, 15466},
                orientation =-1,
                requirements = excludesOaabShipwreck,
                cellId = "Unchartered Shipwreck, Cabin"
            },
            { -- unexplored shipwreck - Vanilla
                name= "Unexplored Shipwreck",
                position = {-40235, -55708, 79},
                orientation =-1,
                requirements = excludesOaabShipwreck,
            },
            { -- unknown shipwreck - Vanilla
                name= "Unknown Shipwreck",
                position = {132532, 37476, 338},
                orientation =-2,
                requirements = excludesOaabShipwreck,
            },
        },
        items = {
            itemPicks.booze(4),
            itemPicks.coinpurse,
            {
                id = "t_com_compass_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "t_com_spyglass01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Cm_Hat_04",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "p_water_walking_s",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "p_water_breathing_s",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "ashfallCamping",
        name = "Camping in the Wilderness",
        description = "You are camping in the wilderness.",
        journalEntry = "I've set up camp in the wilderness. It's a good place to rest and cook some food.",
        items = {
            {
                description = "Cooking Pot",
                ids = cookingPots,
                data = {
                    waterAmount = 100
                }
            },
            {
                id = "ashfall_firewood",
                count = 3
            },
            itemPicks.axe,
            itemPicks.meat(4),
            { id = "misc_com_iron_ladle" },
            { id = "ashfall_flintsteel" },
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        locations = {
            { --Camping - South of Vivec

                requirements = {
                    plugins = { "Ashfall.esp" }
                },
                position = {22989, -113084, 599},
                orientation = 1.51,
                clutter = {
                    { --Tent: Common
                        ids = {"ashfall_tent_base_a"},
                        position = {23450, -113182, 633},
                        orientation = {-0, 0.062418811023235, 1.9599673748016},
                        data = {
                            tentCover = "ashfall_cov_common",
                        },
                        onPlaced = function(reference)
                            event.trigger("Ashfall:coverCreated", { reference = reference })
                        end
                    },
                    { --Campfire
                        ids = {"ashfall_campfire"},
                        position = {23183, -113030, 612},
                        orientation = {-0, 0.12435500323772, 0.9062665104866},
                        data = {
                            fuelLevel = 4,
                            isLit = true,
                            burned = true,
                        }
                    },
                    { --Bed: Straw
                        ids = {"ashfall_strawbed_s"},
                        position = {23537, -113230, 639},
                        orientation = {0, -0, 3.5955812931061},
                        data = {
                            crafted = true
                        }
                    },
                }
            },
        },
    },
    {
        id = "khuulCamping",
        name = "Khuul Camper",
        description = "You are camping on an island near Khuul.",
        locations = {
            {
                position = {-78170, 143029, 427},
                orientation = 349,
            },
        },
        journalEntry =  "I've returned to an old campfire, and to my relief, everything is just as I left it-including my chest. Now, if only I could remember where I hid the key!",
        items = {
            {
                description = "Cooking Pot",
                ids = cookingPots
            },
            {
                id = "ashfall_firewood",
                count = 3
            },
            itemPicks.axe,
            itemPicks.meat(3),
            {id = "ashfall_flintsteel"},
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id= "commoner",
        name = "Commoner",
        description = "You are working as a commoner in a tradehouse, Serving drinks and clearing tables.",
        journalUpdates = {
            { id = "mer_cs_commoner" }
        },
        topics = {
            "my wages"
        },
        locations = {
            {
                position = { 29, -384, -386 },
                orientation = 0,
                cellId = "Maar Gan, Andus Tradehouse"
            },
            { --Gnisis, Madach Tradehouse
                position = {-57, 280, -125},
                orientation =-2,
                cellId = "Gnisis, Madach Tradehouse",
                requirements = {
                    excludedPlugins = { "Beautiful cities of Morrowind.ESP" }
                }
            },
            { --Commoner - Gnisis, Madach Tradehouse
                position = {-283, -999, -1718},
                orientation =0.27,
                cellId = "Gnisis, Madach Tradehouse",
                requirements = {
                    plugins = { "Beautiful cities of Morrowind.ESP" }
                }
            },
            { --Suran, Suran Tradehouse
                position = {4, 240, 519},
                orientation =0,
                cellId = "Suran, Suran Tradehouse"
            },
            { --Bodrum, Varalaryn Tradehouse
                position = {413, -1613, -379},
                orientation =0,
                cellId = "Bodrum, Varalaryn Tradehouse",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
        },
        items = {
            itemPicks.coinpurse,
            {
                id = "misc_com_bucket_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "misc_de_cloth10",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "misc_de_tankard_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        onStart = function()
            --find the nearest publican in the cell and set their disposition to 80
            ---@param ref tes3reference
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                local class = ref.object.class
                if TagManager.hasId{ id = class.id, tag = "publican"} then
                    if tes3.modDisposition then
                        local disposition = ref.object.baseDisposition
                        local change = 80 - disposition
                        tes3.modDisposition{
                            reference = ref,
                            value = change
                        }
                    end
                    ref.mobile.talkedTo = true
                    return
                end
            end
        end
    },
    {
        id = "pilgrimage",
        name = "Pilgrimage",
        description = "You are paying homage at the Fields of Kummu.",
        location = {
            position = {14330, -33457, 774},
            orientation = 57,
        },
        items = {
            {
                id = "bk_PilgrimsPath",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "common_robe_01",
                count = 1,
                noSlotDuplicates = true,
            },
            {
                id = "ingred_muck_01",
                count = 2
            },
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "I have made a pilgrimage to the Fields of Kummu. I should read my copy of The Pilgrim's Path and make my offering.",
    },
    {
        id = "shakingDownFargoth",
        name = "Shaking Down Fargoth",
        description = "You are in Seyda Neen, shaking down Fargoth for all he's worth.",
        journalUpdates = {
            { id = "mer_cs_fargoth" }
        },
        location = {
            position = {-10412, -71271, 298},
            orientation = 300,
        },
        onStart = function(self)
            tes3.equip{ reference = tes3.player, item = "iron dagger" }
            local fargoth = tes3.getReference("Fargoth")
            tes3.playAnimation{
                reference=fargoth,
                group=tes3.animationGroup.knockOut,
                startFlag = tes3.animationStartFlag.immediate,
                loopCount = 1
            }
            tes3.setStatistic{
                reference = fargoth,
                name = "fatigue",
                current = 1
            }
            fargoth.object.baseDisposition = 0
        end,
        items = {
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "houseOfEarthlyDelights",
        name = "House of Earthly Delights",
        description = "You are enjoying the pleasures of Desele's House of Earthly Delights in Suran.",
        location = {
            position = {-30, -234, 188},
            orientation = 90,
            cellId = "Suran, Desele's House of Earthly Delights"
        },
        items = {
            {
                id = "potion_local_brew_01",
                count = 1
            },
            {
                id = "ingred_moon_sugar_01",
                count = 2
            },
            itemPicks.gold(69),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 18,
        journalEntry = "I've spent nearly all my money at Desele's House of Earthly Delights... I should probably head home before I'm completely broke.",
    },
    {
        id = "fishing",
        name = "Fishing",
        description = "You are a humble fisherman, casting your line into the waters of Morrowind.",
        journalEntry = "I've spent the day fishing. I should head back to town to sell my catch.",
        locations = {
            { --Hla Oad
                name = "Hla Oad",
                position = {-48464, -38956, 211},
                orientation =-2,
            },
            { --Seyda Neen Outskirts
                name = "Seyda Neen Outskirts",
                position = {39, -76175, 113},
                orientation =-2,
            },
            { --South of Ald Velothi
                name = "South of Ald Velothi",
                position = {-74003, 106003, 37},
                orientation =0,
            },
            -- Seems broken
            -- { --Azura's Coast
            --     name = "Azura's Coast",
            --     position = {142783, -54841, 26},
            --     orientation =-2,
            -- },
            {
                name = "Dragonhead Point",
                position = {330424, -29432, 784},
                orientation = 0,
                requirements = {
                    plugins = {"TR_Mainland.esm"},
                },
            },
            { --Fishing on the beach
                name = "Fort Frostmoth",
                position = {-175695, 137803, 71},
                orientation =3.02,
                requirements = {
                    plugins = {"TR_Mainland.esm"},
                },
            },

        },
        items = {
            itemPicks.gold(20),
            itemPicks.fishingPole,
            {
                id = "ingred_scales_01",
                count = 2
            },
            {
                id = "ingred_crab_meat_01",
                count = 2
            },
            {
                id = "mer_bug_spinner2",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.fishMeat(3),
            itemPicks.knife,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 17,
    },
    {
        id = "eggFarmer",
        name = "Egg Farmer",
        description = "You are farming Kwama Eggs in the Shulk Egg Mine.",
        journalEntry = "It's a hard day's work farming Kwama Eggs.",
        location = {
            position = {4457, 3423, 12612},
            orientation = 0,
            cellId = "Shulk Egg Mine, Mining Camp"
        },
        items = {
            {
                id = "miner's pick",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "food_kwama_egg_02",
                count = 2
            },
            {
                id = "food_kwama_egg_01",
                count = 5
            },
            {
                id = "p_restore_fatigue_c",
                count = 1
            },
            itemPicks.gold(25),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "hauntedRoom",
        name = "Haunted Room",
        description = "You are sleeping in a haunted room at the Gateway Inn in Sadrith Mora.",
        journalEntry = "During my stay at the Gateway Inn, my rest was interrupted by a noise from the other room. I should investigate.",
        location = {
            position = {-219, -159, 276},
            orientation = 0,
            cellId = "Sadrith Mora, Gateway Inn: South Wing"
        },
        items = {
            {
                id = "bk_hospitality_papers",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.gold(70),
            {id = "silver dagger"},
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 19,
    },
    {
        id = "patron",
        name = "Tavern Patron",
        description = "You are a patron at a tavern, enjoying a drink and some food.",
        locations = taverns,
        items = {
            itemPicks.booze(3),
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "bard",
        name = "Performer",
        description = "You are a bard performing in a tavern.",
        journalEntry = "I've been practicing hard my lute and I'm ready to hit the stage. I should speak to the innkeeper to see if I can perform at the tavern.",
        locations = taverns,
        items = {
            itemPicks.gold(25),
            {
                id = "bk_redbookofriddles",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.lute,
            {
                id = "misc_de_drum_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomExpensivePants,
            itemPicks.randomExpensiveShirt,
            itemPicks.randomExpensiveShoes,
        },
        time = 16.5,
        onStart = function()
            local songController = include("mer.bardicInspiration.controllers.songController")
            local songList = include("mer.bardicInspiration.data.songList")
            if songController then
                songController.learnSong(table.choice(songList.beginner))
            end
        end
    },
    {
        id = "necromancer",
        name = "Necromancer's Apprentice",
        description = "You are an apprentice studying the dark arts of necromancy in a secluded cave.",
        journalUpdates = {
            { id = "mer_cs_necro" }
        },
        topics = {
            "necromancy"
        },
        locations = {
            { --Yesamsi
                position = {-930, -405, 272},
                orientation =0,
                cellId = "Yesamsi"
            },
        },
        clutter = {
            { --boulder
                ids = {"in_moldboulder03"},
                position = {-197, -176, -90},
                orientation = {0, -0, 1.8000000715256},
                cell = "Yesamsi",
                scale = 2.0,
            },
            { --boulder
                ids = {"in_moldboulder03"},
                position = {-145, -331, -73},
                orientation = {0, 0, 0.5},
                cell = "Yesamsi",
                scale = 2.0,
            },
            { --Skeleton
                ids = {"mer_cs_skeleton"},
                position = {-100, -218, 52},
                orientation = {0, 0, 0.25054800510406},
                cell = "Yesamsi",
                scale = 1,
            },
            { --Bonepile
                ids = {"mer_cs_bonepile"},
                position = {-133, -249, -12},
                orientation = {0, 0, 0},
                cell = "Yesamsi",
            },
        },
        items = {
            {
                id = "sc_summonskeletalservant",
                count = 3
            },
            {
                id = "ab_c_commonhoodblack",
                pickMethod = "firstValid",
                count = 1,
            },
            {
                description = "Robe",
                ids = {
                    "ab_c_commonrobeblack",
                    "common_robe_01",
                },
                pickMethod = "firstValid",
                count = 1,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 18,
        spells = {
            { id = "summon scamp" }
        },
        onStart = function ()
            --pacify creatures and NPCs
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
                if ref.mobile ~= nil then
                    mwse.log("Pacifying creature %s", ref.object.name)
                    ref.mobile.fight = 0
                end
            end
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if ref.mobile ~= nil then
                    mwse.log("Pacifying NPC %s", ref.object.name)
                    ref.mobile.fight = 0
                end
            end
        end
    },
    {
        id = "skoomaAddict",
        name = "Skooma Addict",
        description = "You are a skooma addict, spending an evening in the Suran Tradehouse. With only one bottle of skooma left, you need to find your next fix.",
        journalEntry = "I've spent the evening in the Suran Tradehouse. I need to find my next fix soon.",
        location = { --Suran, Suran Tradehouse
            position = {101, 543, 519},
            orientation =3,
            cellId = "Suran, Suran Tradehouse"
        },
        items = {
            {
                id = "apparatus_a_spipe_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "ingred_moon_sugar_01",
                count = 3
            },
            {
                id = "potion_skooma_01",
                count = 1
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 21,
        onStart = function()
            timer.delayOneFrame(function()
                tes3.equip{
                    item = "potion_skooma_01",
                    reference = tes3.player,
                }
            end)
        end
    },
    {
        id = "library",
        name = "Studying in the Library",
        description = "You are immersed in study at the Library of Vivec, surrounded by ancient tomes and scrolls.",
        journalEntry = "I've spent the day studying in the Library of Vivec.",
        location =     { --Vivec, Library of Vivec
            position = {-251, 1373, -126},
            orientation =1.58,
            cellId = "Vivec, Library of Vivec"
        },
        items = {
            itemPicks.gold(50),
            {
                id = "bk_BriefHistoryEmpire3",
                noDuplicates = true,
            },
            {
                id = "common_robe_03_a",
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "lostInAshlands",
        name = "Lost in the Ashlands",
        description = "A sudden ash storm has left you disoriented and lost in the Ashlands.",
        journalEntry = "I'm lost in the Ashlands. I need to find shelter before the storm gets worse.",
        location =  { --Ashlands
            position = {5173, 129314, 801},
            orientation = 2.41,
        },
        items = {
            {
                id = "torch",
                noDuplicates = true,
            },
            itemPicks.coinpurse,
            { --robe
                id = "common_robe_01",
                noSlotDuplicates = true,
            },
            { --hood
                id = "ab_c_commonhoodblack",
                noSlotDuplicates = true,
            },
            --Some ashfall gear
            {
                id = "ashfall_firewood",
                count = 3
            },
            {
                id = "ashfall_tent_base_m",
                noDuplicates = true,
            },
            {
                id = "ashfall_flintsteel"
            },
            {
                id = "ashfall_woodaxe_steel",
                noSlotDuplicates = true,
            },
            {
                id = "ashfall_waterskin",
                noDuplicates = true,
                data = {
                    waterAmount = 30
                }
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        weather = tes3.weather.ash,
        time = 20,
    }
}


for _, scenario in ipairs(scenarios) do
    Scenario:register(scenario)
end


timer.register("mer_scenarios_ghostTimer", function()
    local object = tes3.getObject("mer_cs_ancestor_ghost")
        or tes3.getObject("ancestor_ghost")

    local distanceBehind = 128

    local ghost = common.placeBehindPlayer{
        object = object,
        distanceBehind = distanceBehind,
    }
    ghost.mobile:startCombat(tes3.player.mobile)
    tes3.messageBox("You feel a chill down your spine.")
end)

event.register("itemTileUpdated", function(itemTileUpdatedEventData)
    itemTileUpdatedEventData.element:registerBefore("mouseClick", function(mouseclickEventData)
        local currentScenario = Scenario:getSelectedScenario()
        if not currentScenario then return end
        if currentScenario.id ~= "workingInTheFields" then return end
        local tileData = mouseclickEventData.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") --- @type tes3inventoryTile
            if not tileData then return end

        local isSlaveBracer = tileData.item and tileData.item.id:lower() == "mer_cs_slave_bracer"
        if not isSlaveBracer then return end
        logger:debug("Clicked on slave bracer")

        local journalIndex = tes3.getJournalIndex{ id = "journal mer_cs_field"}
        if journalIndex >= 100 then return end
        logger:debug("Bracer still locked, blocking click")
        return false
    end, 10000)
end)