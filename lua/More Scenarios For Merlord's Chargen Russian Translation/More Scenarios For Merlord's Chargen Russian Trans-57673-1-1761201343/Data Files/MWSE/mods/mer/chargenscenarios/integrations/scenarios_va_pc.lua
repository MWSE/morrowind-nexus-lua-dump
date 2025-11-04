
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- PC

    {
        id = "fortheathdungeon_va",
        name = "Киродиил: Заключенный в Форте Хит",
        description = "Вы собираетесь совершить побег из подземелья Форта Хит в Киродииле, после того, как вас посадили за тяжкое преступление.",
        location = {
                position = {4273, 3463, 6239},
                orientation =69,
                cellId = "Fort Heath, Prison"
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
        id = "anvilharbour_va",
        name = "Киродиил: Прибытие в гавань Анвила",
        description = "Вы только что прибыли на корабле в гавань Анвила.",
        location =     { 
            position = {4627, 4820, 6277},
            orientation =240,
            cellId = "Olive Ridley: Hold"
        },
        items = {
            itemPicks.gold(35),
            {
                id = "T_Sc_GuideToAnvilPC",
                noDuplicates = true,
            },
            {
                id = "T_Imp_Cm_RobeCol_01",
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "abeceanseashipwreck_va",
        name = "Киродиил: Кораблекрушение в Абесинском море",
        description = "Вы пережили кораблекрушение в Абесинском море.",
        location = { 
            position = {-1087283, -326046, -40},
            orientation =12,
        },
    },

    {
        id = "barcharach_va",
        name = "Киродиил: Распитие в Чараче",
        description = "Вы пьете в таверне Чарача.",
        location =     { 
            position = {3710, 4441, 15684},
            orientation =349,
            cellId = "Charach, Old Seawater Inn"
        },
        items = {
            itemPicks.gold(35),
            {
                id = "T_Imp_Drink_WineTamikaClr_01",
                noDuplicates = true,
            },
            {
                id = "T_Imp_Cm_RobeCol_02",
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "fromsutch_va",
        name = "Киродиил: Прибытие из Сатча",
        description = "Вы прибыли из Сатча в королевство Анвил.",
        location = {
            position = {-959965, -372977, 2259},
            orientation =166,
        },
        items = {
            itemPicks.gold(75),
            {
                id = "T_Sc_MapCountyAnvilPC",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "light_com_lantern_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Imp_Cm_RobeCol_02",
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
	table.insert(scenario.requirements.plugins, "Cyr_Main.esm")
    Scenario:register(scenario)
end
