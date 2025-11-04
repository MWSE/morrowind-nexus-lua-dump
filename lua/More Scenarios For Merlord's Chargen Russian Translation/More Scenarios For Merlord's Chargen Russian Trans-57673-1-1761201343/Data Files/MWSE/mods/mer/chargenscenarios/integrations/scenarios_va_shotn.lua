
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

--- SHOTN

    {
        id = "survivethereach_va",
        name = "Скайрим: Выживание в Пределе",
        description = "Вы пытаетесь выжить в Пределе.",
        journalEntry = "Я пытаюсь выжить в Пределе.",
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
        name = "Скайрим: Прибытие в Предел",
        description = "Вы прибыли в Предел из Хаммерфелла через перевал Тро-Туктyра.",
        journalEntry = "Я прибыл в Предел.",
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
        name = "Скайрим: Затаившись в Пределе",
        description = "Вы - разыскиваемый преступник, скрывающийся в Пределе.",
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
        id = "dungeonshotn_va",
        name = "Скайрим: Заключенный в Драгонстаре",
        description = "Вы собираетесь совершить побег из подземелья замка Драгонстар, после того, как вас посадили за тяжкое преступление.",
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
        name = "Скайрим: Распитие в таверне Картвастена",
        description = "Вы пьете в таверне Картвастена.",
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
