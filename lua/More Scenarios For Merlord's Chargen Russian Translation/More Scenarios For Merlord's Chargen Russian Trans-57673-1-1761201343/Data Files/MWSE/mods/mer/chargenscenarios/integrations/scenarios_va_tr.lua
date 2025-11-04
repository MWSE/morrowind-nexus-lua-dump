
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- TR

    {
        id = "leftForDeadarvud_va",
        name = "Морровинд: Брошенный умирать в Армуне",
        description = "По дороге в Арвуд на вас напали разбойники. Вас бросили умирать на обочине дороги.",
        journalEntry = "На меня напали разбойники. Мне нужно найти способ добраться до цивилизации.",
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
        name = "Морровинд: Выживание в Шипал-Шине",
        description = "Вы пытаетесь выжить во враждебном и бесплодном Шипал-Шине.",
        journalEntry = "Я пытаюсь выжить во враждебном Шипал-Шине.",
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
        name = "Морровинд: Прибытие к Вратам Септима",
        description = "Вы прибыли в Морровинд из Киродиила через перевал Врат Септима.",
        journalEntry = "Мне удалось добраться до Морровинда",
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
        name = "Морровинд: Прибытие в Нивалис",
        description = "Вы прибыли в Нивалис на севере Морровинда.",
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
        name = "Морровинд: Кораблекрушение в Море Призраков",
        description = "Вы пережили кораблекрушение в северо-восточной части Моря Призраков.",
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
        name = "Морровинд: Прятки в канализации Нарсиса",
        description = "Вы - разыскиваемый преступник, скрывающийся в канализации Нарсиса.",
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
                description = "Украденные драгоценные камни",
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
        journalEntry = "Власти охотятся за мной, и за мою голову назначена награда. Следующий шаг очевиден: либо продать эти драгоценности и собрать достаточно денег, чтобы заплатить штраф, либо разыскать Гильдию Воров. Говорят, что они могут очистить мое имя... за определенную плату. Так или иначе, я не могу вечно прятаться.",
    },
	
    {
        id = "barnarsis_va",
        name = "Морровинд: Распитие в баре Нарсиса",
        description = "Вы пьете в баре Нарсиса.",
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
        name = "Морровинд: Распитие в таверне Файрвотча",
        description = "Вы пьете в таверне Файрвотча.",
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
        name = "Морровинд: Заключенный в Хелниме",
        description = "Вы собираетесь совершить побег из тюрьмы в Хелниме, после того, как вас посадили за тяжкое преступление.",
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
