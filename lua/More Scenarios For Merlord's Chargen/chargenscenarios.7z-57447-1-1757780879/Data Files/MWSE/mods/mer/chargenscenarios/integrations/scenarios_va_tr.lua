
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- TR

    {
        id = "leftForDeadarvud_va",
        name = "TR: Left for Dead in the Armun",
        description = "While travelling to Arvud, you were attacked by bandits. You have been left for dead on the side of the road.",
        journalEntry = "I have been attacked by bandits. I should find a way to get back to civilization.",
        location = { 
            position = {-19257, -227139, 636},
            orientation =154,
        },
        onStart = function()
            tes3.setStatistic{
                reference = tes3.player,
                name = "health",
                current = 5,
            }
        end
    },
	
    {
        id = "shipalshin_va",
        name = "TR: Surviving the Shipal-Shin",
        description = "You have been trying to survive in the hostile and barren Shipal-Shin.",
        journalEntry = "I am trying to survive in the hostile Shipal-Shin.",
        location = { 
            position = {80345, -464932, 5629},
            orientation =257,
        },
        items = {
            itemPicks.gold(15),
            {
                id = "T_Sc_GuideToNarsisDistrictTR",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_De_Drink_GuarMilk_01",
                count = 3,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "septimsgate_va",
        name = "TR: Arriving at Septim's Gate",
        description = "You have arrived in Morrowind from Cyrodiil at the Septim's Gate Pass.",
        journalEntry = "I have arrived in Morrowind.",
        location = { 
            position = {-64607, -406149, 7912},
            orientation =86,
        },
        items = {
            itemPicks.gold(75),
            {
                id = "T_Sc_GuideToNarsisDistrictTR",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "light_com_lantern_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "nivalis_va",
        name = "TR: Arriving in Nivalis",
        description = "You have arrived in Nivalis in northern Morrowind.",
        location = { 
            position = {99352, 226446, 121},
            orientation =331,
        },
        items = {
            itemPicks.gold(15),
            {
                id = "T_Sc_GuideToFirewatchTR",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "light_com_lantern_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "BM_Nordic01_Robe",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "seaofghostsshipwreck_va",
        name = "TR: Wrecked in the Sea of Ghosts",
        description = "You have survived a shipwreck in north eastern Sea of Ghosts.",
        location = { 
            position = {222095, 207891, 7},
            orientation =234,
        },
        onStart = function()
            tes3.setStatistic{
                reference = tes3.player,
                name = "health",
                current = 14,
            }
        end
    },
	
    {
        id = "hidingFromTheLawnarsis_va",
        name = "TR: Hiding in the Narsis Sewers",
        description = "You are a wanted criminal, hiding in the Narsis Sewers.",
        location = {
                position = {-2536, 2326, 37},
                orientation =69,
                cellId = "Narsis, Sewers: Market Quarter West"
            },
        onStart = function(self)
            tes3.player.mobile.bounty =
                tes3.mobilePlayer.bounty + 650
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
            {
                id = "pick_journeyman_01",
                count = 2,
                noDuplicates = true,
            },
            {
                id = "probe_journeyman_01",
                count = 2,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "The authorities are after me, and there's a price on my head. The next move is clear: either sell these gems and gather enough money to pay the fine, or track down the Thieves Guild. I've heard they can clear my name... for the right price. Either way, I can't stay hidden forever.",
    },
	
    {
        id = "barnarsis_va",
        name = "TR: Drinking in a Narsis bar",
        description = "You are drinking in a bar in Narsis.",
        location =     { 
            position = {4241, 4180, 15351},
            orientation =245,
            cellId = "Narsis, The Last Drop"
        },
        items = {
            itemPicks.gold(35),
            {
                id = "potion_local_liquor_01",
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
        id = "barfirewatch_va",
        name = "TR: Drinking in a Firewatch inn",
        description = "You are drinking in a bar in Firewatch.",
        location =     { 
            position = {6264, 3758, 16257},
            orientation =275,
            cellId = "Firewatch, The Queen's Cutlass"
        },
        items = {
            itemPicks.gold(85),
            {
                id = "T_Sc_GuideToFirewatchTR",
                noDuplicates = true,
            },
            {
                id = "potion_cyro_brandy_01",
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
	
    {
        id = "helnimdungeon_va",
        name = "TR: Incarcerated in Helnim",
        description = "You are about to make your escape attempt from Helnim prison after being incarcerated for a serious crime.",
        location = {
                position = {4182, 4152, 14328},
                orientation =268,
                cellId = "Helnim, Prison Tower"
            },
        onStart = function(self)
            tes3.player.mobile.bounty =
                tes3.mobilePlayer.bounty + 1000
            tes3.modStatistic{
                reference = tes3.player.mobile,
                name = "health",
                current = math.ceil(tes3.player.object.health * 90)
            }
        end,
        items = {
            {
                id = "pick_journeyman_01",
                count = 2,
                noDuplicates = true,
            },
            {
                id = "probe_journeyman_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShoes,
        },
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
