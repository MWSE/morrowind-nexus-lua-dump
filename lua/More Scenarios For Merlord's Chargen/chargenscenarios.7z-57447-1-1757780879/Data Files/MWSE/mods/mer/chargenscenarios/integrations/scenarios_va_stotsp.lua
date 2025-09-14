
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- TOTSP

    {
        id = "solstheimsurvive_va",
        name = "TotSP: Surviving Solstheim",
        description = "You have been trying to survive in the hostile and barren wastes of Solstheim.",
        location = { 
            position = {-127293, 238093, 921},
            orientation =245,
        },
        items = {
            itemPicks.gold(5),
            {
                id = "bk_ThirskHistory",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "potion_nord_mead",
                count = 2,
                noDuplicates = true,
            },
            {
                id = "BM huntsman axe",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "BM_Wool01_Robe",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "skaal_va",
        name = "TotSP: Visiting the Skaal",
        description = "You have been visiting the Skaal on Solstheim.",
        location = { 
            position = {-101502, 262420, 4018},
            orientation =155,
        },
        items = {
            itemPicks.gold(85),
            {
                id = "potion_nord_mead",
                count = 2,
                noDuplicates = true,
            },
            {
                id = "BM huntsman axe",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "BM_Wool01_Robe",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "solstheimdock_va",
        name = "TotSP: Arriving at Fort Frostmoth",
        description = "You have just arrived at Fort Frostmoth on Solstheim.",
        location = { 
            position = {-116654, 187996, 316},
            orientation =22,
        },
        items = {
            itemPicks.gold(150),
            {
                id = "BM_Wool01_Robe",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Bk_MineralsOfMorrowindTR",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
	
    {
        id = "shipwrecksolstheim_va",
        name = "TotSP: Washed ashore on Solstheim",
        description = "You have survived a shipwreck in the Sea of Ghosts and have washed up on the northern shore of Solstheim.",
        location = { 
            position = {-146562, 273880, 49},
            orientation =183,
        },
        onStart = function()
            tes3.setStatistic{
                reference = tes3.player,
                name = "health",
                current = 12,
            }
        end
    },


}

for _, scenario in ipairs(scenarios) do
    if not scenario.requirements then
        scenario.requirements = {}
    end
    if not scenario.requirements.plugins then
        scenario.requirements.plugins = {}
    end
	table.insert(scenario.requirements.plugins, "Solstheim Tomb of the Snow Prince.esm")
    Scenario:register(scenario)
end
