
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- TOTSP

    {
        id = "solstheimsurvive_va",
        name = "Солстхейм: Выживание на Солстхейме",
        description = "Вы пытались выжить во враждебных и бесплодных пустошах Солстхейма.",
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
        name = "Солстхейм: В гостях у Скаалов",
        description = "Вы посетили деревню Скаалов на Солстхейме.",
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
        name = "Солстхейм: Прибытие в Форт Инеевой Бабочки",
        description = "Вы только что прибыли в Форт Инеевой Бабочки на Солстхейме.",
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
        name = "Солстхейм: Выброшенный на берег Солстхейма",
        description = "Вы пережили кораблекрушение в Море Призраков и вас выбросило на северный берег Солстхейма.",
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
