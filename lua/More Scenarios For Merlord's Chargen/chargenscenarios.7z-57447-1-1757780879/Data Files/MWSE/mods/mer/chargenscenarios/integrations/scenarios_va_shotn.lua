
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- SHOTN

    {
        id = "survivethereach_va",
        name = "SHotN: Surviving the Reach",
        description = "You have been trying to survive in the Reach.",
        journalEntry = "I am trying to survive in the Reach.",
        location = {
            position = {-882954, 134984, 759},
            orientation =354,
        },
        items = {
            itemPicks.gold(5),
            {
                id = "BM_Wool01_Robe",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "BM huntsman axe",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "trotukturapass_va",
        name = "SHotN: Arriving in the Reach",
        description = "You have arrived in the Reach from Hammerfell at the Tro-Tuktura Pass.",
        journalEntry = "I have arrived in the Reach.",
        location = {
            position = {-940287, 92023, 3624},
            orientation =189,
        },
        items = {
            itemPicks.gold(75),
            {
                id = "T_Bk_PeoplesOfTheReachSHOTN",
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
        id = "hidingFromTheLawshotn_va",
        name = "SHotN: Laying Low in the Reach",
        description = "You are a wanted criminal, hiding in the Reach.",
        location = {
                position = {-896609, 126436, 2528},
                orientation =234,
            },
        onStart = function(self)
            tes3.player.mobile.bounty =
                tes3.mobilePlayer.bounty + 500
            tes3.modStatistic{
                reference = tes3.player.mobile,
                name = "health",
                current = math.ceil(tes3.player.object.health * 8)
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
        id = "dungeonshotn_va",
        name = "SHotN: Incarcerated in Dragonstar",
        description = "You are about to make your escape attempt from Dragonstar Castle dungeons after being incarcerated for a serious crime.",
        location = {
                position = {9529, 9653, 15145},
                orientation =143,
                cellId = "Dragonstar East, Castle Dragonstar: Upper Dungeon"
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
	
    {
        id = "barkarthwasten_va",
        name = "SHotN: Drinking in Karthwasten",
        description = "You are drinking in an inn in Karthwasten.",
        location =     { 
            position = {756, 888, 0},
            orientation =143,
            cellId = "Karthwasten, Ruby Drake Inn"
        },
        items = {
            itemPicks.gold(35),
            {
                id = "potion_nord_mead",
                noDuplicates = true,
            },
            {
                id = "BM_Nordic01_Robe",
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
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
	table.insert(scenario.requirements.plugins, "Sky_Main.esm")
    Scenario:register(scenario)
end
