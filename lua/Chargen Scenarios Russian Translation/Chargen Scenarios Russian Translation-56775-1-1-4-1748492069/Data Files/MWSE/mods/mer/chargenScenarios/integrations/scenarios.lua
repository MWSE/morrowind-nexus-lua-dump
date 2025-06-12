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
        name = "--Оригинальное начало--",
        description = "Начните игру в Имперской канцелярии в Сейда Нин.",
        location = {
            orientation = 2,
            position = {33,-87,194},
            cellId = "Seyda Neen, Census and Excise Office"
        },
        journalEntry = "Мне нужно поговорить с Селлусом Гравиусом, чтобы обсудить мои обязанности.",
        items = {
            itemPicks.coinpurse,
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "hidingFromTheLaw",
        name = "Вне закона",
        description = "Вы разыскиваемый преступник, скрывающийся на окраине Аскадианских островов.",
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
                description = "Украденные драгоценности",
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
        journalEntry = "Власти преследуют меня, и за мою голову назначена награда. Дальнейшие действия очевидны: либо продать эти драгоценные камни и собрать достаточно денег, чтобы заплатить штраф, либо разыскать Гильдию воров. Ходят слухи, что они могут очистить мое имя... за соответствующую цену. В любом случае, у меня не получится скрываться вечно.",
    },
    {
        id = "pearlDiving",
        name = "Ныряльщик за жемчугом",
        description = "Вы ныряльщик за жемчугом в водах близ Пелагиада.",
        location = {
            position = {12481, -61011, -280},
            orientation = 0,
        },
        journalUpdates = {
            { id = "mer_cs_pearl" }
        },
        topics = {
            "продать жемчужины"
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
        name = "Охота в Грейзленде",
        description = "Вы охотник, выслеживающий добычу в Грейзленде.",
        journalUpdates = {
            { id = "mer_cs_hunt" }
        },
        location = {
            position = {74894, 124753, 1371},
            orientation = 0,
        },
        topics = {
            "продать свежее мясо"
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
        name = "Работник полей",
        description = "Вы ничтожный раб, трудящийся на полях за пределами Пелагиада.",
        journalUpdates = {
            { id = "mer_cs_field" }
        },
        location = {
            position = {13449, -57064, 136},
            orientation = 0,
        },
        topics = {
            "снять рабский наруч",
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
        name = "Сбор грибов",
        description = "Вы находитесь на болотах Горького берега в поисках ингредиентов.",
        journalUpdates = {
            { id = "mer_cs_mushrooms" }
        },
        topics = {
            "грибы"
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
                description = "Грибы",
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
        name = "Расхититель гробниц",
        description = "Вы грабитель могил, расхищающий родовую гробницу.",
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
        journalEntry = "Мне попалась родовая гробница, секреты которой оставались нетронутыми долгое время. Какие бы духи ни обитали в этом месте, им ведь будет все равно, если я возьму немного из того, что осталось… верно?",
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
        name = "Фракция: Гильдия магов",
        description = "Вы являетесь членом Гильдии магов.",
        factions = {
            { id = "Mages Guild"}
        },
        journalEntry = "Мне удалось вступить в Гильдию магов. Нужно поговорить с главами гильдии, чтобы узнать, есть у них для меня задания.",
        locations = {
            {
                position = {14, 187, -252},
                orientation =-4,
                name = "Вивек",
                cellId = "Vivec, Guild of Mages"
            },
            {
                position = {370, -584, -761},
                orientation =-4,
                name = "Балмора",
                cellId = "Balmora, Guild of Mages"
            },
            {
                position = {695, 537, 404},
                orientation =0,
                name = "Кальдера",
                cellId = "Caldera, Guild of Mages"
            },
            {
                position = {186, 542, 66},
                orientation =0,
                name = "Садрит Мора",
                cellId = "Sadrith Mora, Wolverine Hall: Mage's Guild"
            },

            { --Akamora, Guild of Mages
                name = "Акамора",
                position = {78, -447, -382},
                orientation =-1,
                cellId = "Akamora, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Almas Thirr, Guild of Mages
                name = "Алмас Тирр",
                position = {222, -215, -62},
                orientation =-3,
                cellId = "Almas Thirr, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Andothren, Guild of Mages
                name = "Андотрен",
                position = {7847, 4297, 15203},
                orientation =0,
                cellId = "Andothren, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Firewatch, Guild of Mages
                name = "Фаервотч",
                position = {5188, 2511, 10842},
                orientation =-2,
                cellId = "Firewatch, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Helnim, Guild of Mages
                name = "Хелним",
                position = {4730, 3631, 12660},
                orientation =2,
                cellId = "Helnim, Guild of Mages",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Old Ebonheart, Guild of Mages
                name = "Старый Эбенгард",
                position = {4295, 4496, 15234},
                orientation =2,
                cellId = "Old Ebonheart, Guild of Mages",
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
        name = "Фракция: Гильдия бойцов",
        description = "Вы являетесь членом Гильдии бойцов.",
        factions = {
            { id = "Fighters Guild" },
            { id = "T_Sky_FightersGuild" }
        },
        topics = {
            "вступить в Гильдию Бойцов",
            "Повышение",
            "Приказы",
        },
        journalEntry = "Мне удалось вступить в гильдию бойцов. Нужно поговорить с главами гильдии, чтобы узнать, есть у них для меня задания.",
        locations = {
            {
                position = {-901, -379, -764},
                orientation =0,
                name = "Альд'рун",
                cellId = "Ald-ruhn, Guild of Fighters",
            },
            {
                position = {304, 293, -377},
                orientation =0,
                name = "Балмора",
                cellId = "Balmora, Guild of Fighters"
            },
            {
                position = {306, -222, 3},
                orientation =-1,
                name = "Садрит Мора",
                cellId = "Sadrith Mora, Wolverine Hall: Fighter's Guild"
            },
            {
                position = {179, 822, -508},
                orientation =-2,
                name = "Вивек",
                cellId = "Vivec, Guild of Fighters"
            },


            { --Akamora, Guild of Fighters
                name = "Акамора",
                position = {4431, 4280, 12674},
                orientation =-4,
                cellId = "Akamora, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Almas Thirr, Guild of Fighters
                name = "Алмас Тирр",
                position = {4168, 4355, 14979},
                orientation =-4,
                cellId = "Almas Thirr, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Andothren, Guild of Fighters
                name = "Андотрен",
                position = {2399, 4231, 14983},
                orientation =3,
                cellId = "Andothren, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Firewatch, Guild of Fighters
                name = "Фаервотч",
                position = {4160, 3752, 15714},
                orientation =-2,
                cellId = "Firewatch, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Helnim, Guild of Fighters
                name = "Хелним",
                position = {5597, 4024, 15970},
                orientation =3,
                cellId = "Helnim, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            { --Old Ebonheart, Guild of Fighters
                name = "Старый Эбенгард",
                position = {3928, 324, 11714},
                orientation =1,
                cellId = "Old Ebonheart, Guild of Fighters",
                requirements = {
                    plugins = { "TR_Mainland.esm" }
                }
            },
            --SHOTN
            { --Karthwasten, Guild of Fighters
                name = "Картвастен",
                position = {4817, 3730, 15874},
                orientation =-1.5,
                cellId = "Karthwasten, Guild of Fighters",
                requirements = {
                    plugins = { "Sky_Main.esm" }
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
        name = "Фракция: Гильдия воров",
        description = "Вы - новоиспеченный член Гильдии воров, имеющий ранг Лягуха, скрывающийся со своими приятелями-ворами в трактире \"Южная стена\" в Балморе.",
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
            "вступить в Гильдию Воров",
            "Работенка",
            "Повышение",
            "цена за твою голову"
        },
        factions = {
            { id = "Thieves Guild"}
        },
        journalEntry = "Мне удалось вступить в Гильдию воров. Нужно поговорить с Сладкоголосой Хабаси, чтобы получить свое первое задание.",
    },
    {
        id = "imperialCult",
        name = "Фракция: Имперский культ",
        description = "Вы - мирянин Имперского культа.",
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
            "Имперский культ",
            "мирской участник",
            "приобщиться к Имперскому культу",
            "Требования",
            "благословения",
            "Услуги"
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
        name = "Фракция: Имперский легион",
        description = "Вы Рекрут Имперского Легиона, ожидающий приказов в Гнисисе.",
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
            "вступить в Имперский Легион",
            "Приказы",
            "Повышение",
            "Требования"
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
        journalEntry = "Сегодня мой первый день в Имперском легионе. Нужно поговорить с генералом Дариусом, чтобы получить приказы.",
    },
    {
        id = "moragTong",
        name = "Фракция: Мораг Тонг",
        description = "Мораг Тонг выдали вам Приказ на Благородную Казнь. Вы должны совершить это законное убийство, чтобы быть принятым в древнюю гильдию убийц.",
        location =     { --Vivec, Arena Hidden Area
            position = {684, 508, 2},
            orientation =3,
            cellId = "Vivec, Arena Hidden Area"
        },
        journalEntry = "Мораг Тонг выдали мне Приказ на Благородную Казнь. Нужно совершить это законное убийство, чтобы меня приняли в древнюю гильдию убийц.",
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
            "присоединиться к Мораг Тонг",
            "Ферурен Оран",
            "Приказ",
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
        name = "Фракция: Дом Телванни",
        description = "Вы наемник Дома Телванни, ожидающий встречи с Голосами в Зале Совета в Садрит Море.",
        journalEntry = "Я наемник Дома Телванни. Я должен поговорить с Голосами, чтобы получить свои первые приказы.",
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
            "присоединиться к Дому Телванни",
            "задания",
            "Повышение",
            "правила",
            "Требования"
        },
        factions = {
            { id = "Telvanni" }
        },
    },
    {
        id = "houseHlaalu",
        name = "Фракция: Дом Хлаалу",
        description = "Вы наемник Дома Хлаалу, готовый приступить к своим первым делам в Балморе.",
        journalEntry = "Я наемник Дома Хлаалу. Мне нужно поговорить с Нилено Дорвайн, чтобы обсудить дела.",
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
            "присоединиться к Дому Хлаалу",
            "Дом Хлаалу",
            "советники Хлаалу",
            "дела",
            "Повышение"
        },
        factions = {
            { id = "Hlaalu" }
        },
    },
    {
        id = "houseRedoran",
        name = "Фракция: Дом Редоран",
        description = "Вы наемник Дома Редоран, ожидающий встречи с Советниками в Зале Совета Редорана в Альд'руне.",
        journalEntry = "Я наемник Дома Редоран. Мне следует поговорить с Неминдой у входа в Совет Редорала, чтобы получить свои первые приказы.",
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
            "присоединиться к Дому Редоран",
            "Задания",
            "Повышение"
        },
    },
    {
        id = "ashlander",
        name = "Эшлендер",
        description = "Вы живете с небольшой группой эшлендеров в юрте на побережье Грейзленда.",
        topics = {
            "наш лагерь"
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
                newObject.name = "Мой спальник"
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
        name = "Дровосек",
        description = "Вы собираете дрова в пустошах.",
        journalEntry = "Это был долгий день сбора дров. Нужно вернуться в город, чтобы продать их.",
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
        name = "Заключенный",
        description = "Вы заключенный в тюремной камере Хлаалу в Вивеке.",
        journalEntry = "Сегодня меня выпустили из тюрьмы в Вивеке. Перед арестом у меня получилось спрятать немного золота у входа в родовую гробницу Отреласов, за корнем пробочника. Пора вернуть свое имущество.",
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
        name = "Кораблекрушение",
        description = "Вы единственный выживший после кораблекрушения.",
        journalEntry = "Только мне удалось спастись во время кораблекрушения. Нужно найти способ выжить и добраться до цивилизации.",
        locations = {
            {  --abandoned shipwreck - OAAB
                name = "Обломки покинутого судна",
                position = {9256, 187865, 79},
                orientation = 2,
                requirements = requiresOaabShipwreck,
            },
            {  --Lonesome shipwreck - OAAB
                name = "Унылые обломки корабля",
                position = {112247, 127534, 30},
                orientation = -2,
                requirements = requiresOaabShipwreck,
            },
            {  --neglected shipwreck - OAAB
                name = "Обломки забытого корабля",
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
                name = "Отдаленные обломки корабля",
                position = {-8307, -84454, 93},
                orientation =-2,
                requirements = requiresOaabShipwreck,
            },
            {  --shunned shipwreck - OAAB
                name = "Сохраненные обломки корабля",
                position = {-74895, 14527, -29},
                orientation =-3,
                requirements = requiresOaabShipwreck,
            },
            { -- abandoned shipwreck - Vanilla
                name = "Обломки покинутого судна",
                position = {-1, -185, -26},
                orientation =-4,
                requirements = excludesOaabShipwreck,
                cellId = "Abandoned Shipwreck, Cabin"
            },
            { -- derelict shipwreck - Vanilla
                name = "Обломки брошенного корабля",
                position = {-51690, 152197, 256},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- deserted shipwreck - Vanilla
                name = "Опустошенные обломки корабля",
                position = {74492, -85701, 29},
                orientation =-4,
                requirements = excludesOaabShipwreck,
            },
            { -- lonely shipwreck - Vanilla
                name = "Уединенные обломки корабля",
                position = {154892, -6903, 51},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- lost shipwreck - Vanilla
                name = "Обломки потерянного корабля",
                position = {127322, 94621, -50},
                orientation = 2,
                requirements = excludesOaabShipwreck,
            },
            { -- remote shipwreck - Vanilla
                name= "Отдаленные обломки корабля",
                position = {-7894, -84541, 90},
                orientation =2,
                requirements = excludesOaabShipwreck,
            },
            { -- shunned shipwreck - Vanilla
                name= "Сохраненные обломки корабля",
                position = {-75958, 14512, -20},
                orientation =1,
                requirements = excludesOaabShipwreck,
            },
            { -- strange shipwreck - Vanilla
                name= "Странные обломки корабля",
                position = {4172, 4017, 15651},
                orientation =-1,
                requirements = excludesOaabShipwreck,
                cellId = "Strange Shipwreck, Cabin"
            },
            { -- unchartered shipwreck - Vanilla
                name= "Бесполезные обломки корабля",
                position = {4221, 4034, 15466},
                orientation =-1,
                requirements = excludesOaabShipwreck,
                cellId = "Unchartered Shipwreck, Cabin"
            },
            { -- unexplored shipwreck - Vanilla
                name= "Неисследованные обломки корабля",
                position = {-40235, -55708, 79},
                orientation =-1,
                requirements = excludesOaabShipwreck,
            },
            { -- unknown shipwreck - Vanilla
                name= "Обломки неизвестного корабля",
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
        name = "Лагерь в дикой местности",
        description = "Вы разбили лагерь в дикой местности.",
        journalEntry = "Установка лагеря завершена. Хорошее место, чтобы отдохнуть и приготовить еду.",
        items = {
            {
                description = "Кастрюля",
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
        name = "Лагерь около Хуула",
        description = "Вы разбили лагерь на острове неподалеку от Хуула.",
        locations = {
            {
                position = {-78170, 143029, 427},
                orientation = 349,
            },
        },
        journalEntry =  "А вот и мой старый лагерь, и, к моему облегчению, все вещи остались на своих местах, включая мой сундук. Вот только бы вспомнить, где спрятан ключ!",
        items = {
            {
                description = "Кастрюля",
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
        name = "Обыватель",
        description = "Вы обыватель, работаете в трактире, разносите напитки и убираете со столов.",
        journalUpdates = {
            { id = "mer_cs_commoner" }
        },
        topics = {
            "мое жалование"
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
        name = "Паломничество",
        description = "Вы отдаете дань уважения на полях Кумму.",
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
        journalEntry = "Паломничество в Поля Кумму подошло к концу. Нужно прочитать свой экземпляр \"Пути паломника\" и сделать подношение.",
    },
    {
        id = "shakingDownFargoth",
        name = "Запугивание Фаргота",
        description = "Вы в Сейда Нин, выбиваете из Фаргота все, что можно.",
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
        name = "Дом Земных Наслаждений",
        description = "Вы расслабляетесь в Доме Земных Наслаждений Дезель в Суране.",
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
        journalEntry = "Уже почти все деньги потрачены в Доме земных наслаждений Дезель... Наверное, пора возвращаться домой, если я хочу избежать разорения.",
    },
    {
        id = "fishing",
        name = "Рыбалка",
        description = "Вы скромный рыбак, закидывающий свою удочку в водах Морровинда.",
        journalEntry = "Очередной день проведен за рыбалкой. Пора возвращаться в город, чтобы продать свой улов.",
        locations = {
            { --Hla Oad
                name = "Хла Оуд",
                position = {-48464, -38956, 211},
                orientation =-2,
            },
            { --Seyda Neen Outskirts
                name = "Окрестности Сейда Нин",
                position = {39, -76175, 113},
                orientation =-2,
            },
            { --South of Ald Velothi
                name = "К югу от Альд Велоти",
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
                name = "Мыс Драконьей Головы",
                position = {330424, -29432, 784},
                orientation = 0,
                requirements = {
                    plugins = {"TR_Mainland.esm"},
                },
            },
            { --Fishing on the beach
                name = "Форт инеевой бабочки",
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
        name = "Яичный фермер",
        description = "Вы выращиваете яйца Квама в яичной шахте Шалка.",
        journalEntry = "Выращивание яиц Квама - это тяжелый труд.",
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
        name = "Комната с привидениями",
        description = "Вы ночуете в комнате с привидениями в Привратном Трактире в Садрит Море.",
        journalEntry = "Во время моего пребывания в Привратном Трактире, мой отдых был прерван шумом из соседней комнаты. Нужно выяснить в чем дело.",
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
        name = "Завсегдатай таверны",
        description = "Вы завсегдатай таверны, наслаждающийся напитками и едой.",
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
        name = "Бард",
        description = "Вы бард, выступающий в таверне.",
        journalEntry = "Репетиция \"Под грибным деревом\" на лютне прошла успешно. Мне нужно поговорить с трактирщиком и  узнать, могу ли я выступить.",
        locations = taverns,
        items = {
            itemPicks.gold(25),
            {
                id = "bk_bardic_inspiration",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "bk_bardic_inspiration_2",
                count = 1,
                noDuplicates = true,
            },
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
        time = 17,
        onStart = function()
            local songController = include("mer.bardicInspiration.controllers.songController")
            if songController then
                songController.learnSong{
                    name = "Под грибным деревом",
                    path = "mer_bard/beg/2.mp3",
                    difficulty = "beginner",
                }
            end
        end
    },
    {
        id = "necromancer",
        name = "Ученик некроманта",
        description = "Вы ученик, изучающий темные искусства некромантии в уединенной пещере.",
        journalUpdates = {
            { id = "mer_cs_necro" }
        },
        topics = {
            "некромантия"
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
                description = "Мантия",
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
        name = "Скуумозависимый",
        description = "Вы пристрастились к скууме и проводите вечер в трактире Сурана. У вас осталась всего одна бутылка скумы, и вам нужно найти следующую порцию.",
        journalEntry = "Вечер в трактире Сурана пролетел незаметно. Мне нужно поскорее найти следующую порцию.",
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
        name = "Ученик в библиотеке",
        description = "Вы поглощены учебой в библиотеке Вивека, в окружении древних фолиантов и свитков.",
        journalEntry = "День в библиотеке Вивека пролетел незаметно.",
        location = { --Vivec, Library of Vivec
            position = {-509, 1713, -126},
            orientation = 1.5,
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
        name = "Затерянный в Эшленде",
        description = "Внезапная пепельная буря сбила вас с пути и вы заблудились в Эшленде.",
        journalEntry = "Угораздило меня заблудился в Эшленде. Нужно найти убежище, пока буря не усилилась.",
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

    -- Get the player's forward direction vector
    local forwardVector = tes3.getPlayerEyeVector()
    -- Invert it to get the backward direction
    local backwardVector = -forwardVector
    -- Calculate the new position
    local position = tes3.player.position:copy() + backwardVector * distanceBehind

    local ghost = tes3.createReference{
        object = object,
        position = position,
        --facing player
        orientation = tes3.player.orientation:copy() + tes3vector3.new(0, 0, math.pi),
        cell = tes3.player.cell
    }
    ghost.mobile:startCombat(tes3.player.mobile)
    tes3.messageBox("Вы ощущаете, как по спине пробегает холодок.")
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