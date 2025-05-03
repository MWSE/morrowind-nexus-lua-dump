
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {
    {
        id = "oldEbonheart",
        name = "Old Ebonheart",
        description = "You have just stepped off the boat at Old Ebonheart.",
        journalEntry = "I have just stepped off the boat at Old Ebonheart. Time to find my way around the city.",
        location = { --Stepping off the boat in Old Ebonheart
            position = {60970, -144577, 341},
            orientation =1.41,
        },
        items = {
            itemPicks.gold(50),
            {
                id = "t_sc_mapindorillandsnorthwesttr",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Cm_Hat_04",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "firewatchCollege",
        name = "College of Firewatch",
        description = "You are a prospective student at the College of Firewatch.",
        journalEntry = "I have finally saved up enough to enroll at the College of Firewatch. I should speak to Marilus Arjus and decide what course to enrol in.",
        location =     { --Firewatch, College
            position = {5182, 3518, 12098},
            orientation =3.14,
            cellId = "Firewatch, College"
        },
        items = {
            itemPicks.gold(1500),
            {
                id = "TR_m1_FW_College_EnrollmentInfo",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "potion_t_bug_musk_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomExpensivePants,
            itemPicks.randomExpensiveShirt,
            itemPicks.randomExpensiveShoes,
        },
        onStart = function()
            local marilus = tes3.getReference("TR_m1_Marilus_Arjus")
            if marilus then
                local currentDisp = marilus.object.baseDisposition
                if currentDisp < 50 then
                    local change = 50 - currentDisp
                    tes3.modDisposition{
                        reference = marilus,
                        value = change
                    }
                end
            end
        end
    },
    {
        id = "dreynimSpa",
        name = "Dreynim Spa",
        description = "You are on holiday at Dreynim Spa.",
        journalEntry = "I am on holiday at Dreynim Spa. The baths are hot and the drinks are cold.",
        location = {
            position = {240656, -176840, 709},
            orientation = 0,
        },
        items = {
            {
                id = "T_Com_Ep_Robe_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_ClothRed_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Soap_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "arrivingInNivalis",
        name = "Nivalis",
        description = "You have just arrived at the Imperial settlement of Nivalis.",
        journalEntry = "I have just arrived at the Imperial settlement of Nivalis.",
        location = {
            position = {98094, 227955, 544},
            orientation = 90,
        },
        items = {
            {
                id = "fur_colovian_helm",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.gold(50),
            {

                id = "T_Imp_ColFur_Boots_01",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
        },
    },
    {
        id = "sadasPlantation",
        name = "Plantation Slave",
        description = "You are a slave working on the Sadas Plantation.",
        journalEntry = "Master Sadas has me working on his plantation. I need to keep my head down.",
        location = {
            position = {291563, 144320, 424},
            orientation = 0,
        },
        items = {
            {
                id = "slave_bracer_right",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "pick_apprentice_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Farm_Pitchfork_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        requirements = {
            races = {"Argonian", "Khajiit"},
        },
    },
    {
        id = "teynCensus",
        name = "Teyn Census Office",
        description = "You are being processed at the census office in Teyn.",
        journalEntry = "I have been processed at the census office in Teyn.",
        location = { --Teyn, Census and Excise Office
            position = {4321, 4372, 16322},
            orientation =3.13,
            cellId = "Teyn, Census and Excise Office"
        },
        items = {
            itemPicks.gold(75),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "unwelcomeVisitor",
        name = "Unwelcome Visitor",
        description = "You have wandered into the Andothren Council Club for a game of thirty-six. You feel the eyes of the patrons glaring at you. You should probably leave.",
        journalEntry = "I have wandered into the Andothren Council Club for a game of thirty-six. I should probably leave.",
        location =  { --Andothren, Council Club
            position = {4102, 3970, 12295},
            orientation =0.02,
            cellId = "Andothren, Council Club"
        },
        items = {
            {
                id = "t_com_dice_01",
                count = 2,
                noDuplicates = true,
            },
            itemPicks.gold(100),
            {
                id = "iron dagger",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 21,
        onStart = function()
            -- Lower the disposition of nearby NPCs to reflect their distrust
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if ref and ref.mobile then
                    tes3.modDisposition{
                        reference = ref,
                        value = -20
                    }
                end
            end
        end,
    },
    {
        id = "bakery",
        name = "Buying Fresh Bread",
        description = "You have stopped by a local bakery to buy some fresh bread.",
        journalEntry = "I have arrived at the bakery. I should see what they have available.",
        locations = {
            {
             --Vhul, Bakers' Hall
                name = "Vhul",
                position = {111, 52, -126},
                orientation =2.86,
                cellId = "Vhul, Bakers' Hall"
            },
            { --Karthwasten, Lelena Aurtius: Baker
                name = "Karthwasten",
                position = {-752, 74, 2},
                orientation =-0.14,
                cellId = "Karthwasten, Lelena Aurtius: Baker"
            },
            { --Old Ebonheart, Gul-Ei's Pantry
                name = "Old Ebonheart",
                position = {4309, 4124, 15405},
                orientation =-1.62,
                cellId = "Old Ebonheart, Gul-Ei's Pantry"
            }
        },
        items = {
            itemPicks.gold(30),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "erothHermit",
        name = "Hermit of Eroth",
        description = "You are a hermit living on the Island of Eroth. You have few possessions and no friends, but that's just the way you like it.",
        location ={ --Living as a hermit on Eroth Island
            position = {357102, -31316, 361},
            orientation =0.59,
        },
        items = {
            {
                id = "ashfall_bedroll",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        id = "botheanFalls",
        name = "Boethian Falls Pilgrimage",
        description = "You are on a pilgrimage to the Boethian Falls.",
        location =     { --Visiting the Boethian Falls
            position = {265250, 4529, 19},
            orientation =-2.48,
        },
        items = {
            {
                id = "T_IngFlor_BlackrosePetal_01",
                count = 1,
            },
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "I have made it to the Boethian Falls. I should find the shrine and offer a black rose to complete my pilgrimage.",
    },

    {
        id = "leftForDead",
        name = "Left for Dead",
        description = "While travelling to the fort of Ammar, you were attacked by bandits. You have been left for dead on the side of the road.",
        journalEntry = "I have been attacked by bandits. I should find a way to get back to civilization.",
        location = { --Left for dead on the side of the road
            position = {195622, -74295, 478},
            orientation =-0.27,
        },
        onStart = function()
            tes3.setStatistic{
                reference = tes3.player,
                name = "health",
                current = 5,
            }
            tes3.playAnimation{
                reference=tes3.player,
                group=tes3.animationGroup.knockOut,
                startFlag = tes3.animationStartFlag.immediate,
                loopCount = 1
            }
        end
    },

    {
        id = "necromCatacombs",
        name = "Necrom Catacombs",
        description = "You are in Necrom, exploring the catacombs beneath the city.",
        location = { --Necrom, Catacombs: First Chamber
            position = {134, 1287, -446},
            orientation =-3.09,
            cellId = "Necrom, Catacombs: First Chamber"
        },
        items = {
            itemPicks.gold(50),
            {
                id = "pick_apprentice_01",
                count = 1,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        --equip torch
        onStart = function()
            tes3.equip{
                item = "light_com_torch_01_256",
                reference = tes3.player,
                addItem = true,
            }
        end,
    },

    {
        id = "akamoraTemple",
        name = "Akamora Temple",
        description = "You are in the temple of Akamora, praying to the gods.",
        journalEntry = "I have arrived at the temple of Akamora.",
        location = { --Praying at the temple of Akamora
            position = {4544, 3322, 11970},
            orientation =-2.35,
            cellId = "Akamora, Temple"
        },
        items = {
            itemPicks.gold(50),
            {
                id = "bk_LivesOfTheSaints",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "common_robe_05",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "portTelvannis",
        name = "Port Telvannis",
        description = "You are seeking access to Port Telvannis. You have your hospitality papers, hopefully they will be enough.",
        location = { --Seeking access into Port Telvannis
            position = {3589, 4561, 12289},
            orientation =0,
            cellId = "Port Telvannis, The Avenue"
        },
        topics = {
            "hospitality papers",
        },
        items = {
            itemPicks.gold(50),
            {
                id = "TR_m1_sc_T_hospitalitypapers",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },


    {
        id = "arrivedInAnvil",
        name = "Anvil by Carriage",
        description = "You have just arrived in the city of Anvil after a long journey by carriage from Hal Sadek.",
        journalEntry = "I have just arrived in the city of Anvil after a long journey by carriage from Hal Sadek. I should seek food, drink and information about the city at the Caravan Stop nearby.",
        location =  { --Anvil, Marina
            position = {-976885, -446000, 426},
            orientation =-1.39,
        },
        items = {
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "workingOnTheDocks",
        name = "Anvil Dock Worker",
        description = "You are at the docks of Anvil, looking for work.",
        journalEntry = "I have arrived at the Anvil Docks. I should chat to Kharag gro-Uratag, I hear he needs help looking for work too.",
        location =     { --Anvil, Port Quarter
            position = {-993310, -449487, 193},
            orientation =-0.82,
        },
        items = {
            itemPicks.gold(15),
            {
                id = "T_Com_Mallet_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "misc_hook",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Var_Harpoon_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "market",
        name = "Market Shopping",
        description = "You are shopping for a new outfit at an open-air market in Meralag.",
        location = { --Browsing an Indoril open-air market
            position = {209924, -174964, 539},
            orientation =0.14,
        },
        items = {
            itemPicks.gold(100),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        location =     { --Getting directions at a waystation
            position = {4461, 3242, 12242},
            orientation =0.3,
            cellId = "Telvanni Waystation"
            --Notes: Start with guide to the sacred lands region
        },
        id = "waystation",
        name = "Telvanni Waystation",
        description = "You are at a Telvanni waystation, seeking directions to the sacred lands.",
        items = {
            itemPicks.gold(50),
            itemPicks.robe,
            {
                id = "T_Sc_GuideToNecrom",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "astrologicalSociety",
        name = "Astrological Society",
        description = "You are a prospective member of the Imperial Astrological Society in Anvil.",
        journalEntry = "I have arrived at the Imperial Astrological Society in Anvil. I should speak to Sarria Caviran about joining.",
        location = { --Anvil, Imperial Astrological Society
            position = {2311, 159, 17474},
            orientation =0.43,
            cellId = "Anvil, Imperial Astrological Society"
        },
        items = {
            {
                id = "t_com_spyglass01",
            },
            itemPicks.gold(40),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        id = "bountyHunter",
        name = "Bounty Hunter",
        description = "You are a bounty hunter in Karthwasten, tasked with hunting down a fugitive.",
        journalEntry = "I should speak to Hadnar White-Wind about the bounty on Dovica, or ask about other available bounties.",
        topics = { "Dovica" },
        location =     { --Karthwasten, Guard Barracks
            position = {1300, -1302, 642},
            orientation =-1.72,
            cellId = "Karthwasten, Guard Barracks"
        },
        items = {
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "houseOfMara",
        name = "House of Mara",
        description = "You are at the House of Mara in Dragonstar, seeking guidance and wisdom.",
        journalEntry = "I have arrived at the House of Mara in Dragonstar. I should speak to the priestess Helle.",
        location =     { --Dragonstar East, House of Mara
            position = {3844, 3965, 15738},
            orientation =1.6,
            cellId = "Dragonstar East, House of Mara"
        },
        items = {
            itemPicks.coinpurse,
            {
                id = "common_robe_05",
                count = 1,
                noSlotDuplicates = true,
            },
            {
                id = "bk_LivesOfTheSaints",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
}

for _, scenario in ipairs(scenarios) do
    if not scenario.requirements then
        scenario.requirements = {}
    end
    if not scenario.requirements.plugins then
        scenario.requirements.plugins = {}
    end
    table.insert(scenario.requirements.plugins, "TR_Mainland.esm")
    Scenario:register(scenario)
end
