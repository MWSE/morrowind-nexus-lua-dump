local itemPicks = require("mer.chargenScenarios.util.itemPicks")
local Loadouts = require("mer.chargenScenarios.component.Loadouts")

---@type ChargenScenarios.ItemListInput[]
local itemListInputs = {
    {
        name = "Алхимический набор",
        description = "Базовый набор алхимических инструментов и несколько случайных ингредиентов.",
        items = {
            { id = "apparatus_a_mortar_01" },
            { id = "apparatus_a_alembic_01" },
            { id = "apparatus_a_retort_01" },
            {
                description = "Алхимические ингредиенты",
                ids = {
                    "ingred_ash_salts_01",
                    "ingred_bonemeal_01",
                    "ingred_ectoplasm_01",
                    "ingred_fire_salts_01",
                    "ingred_frost_salts_01",
                    "ingred_bc_ampoule_pod",
                    "ingred_wickwheat_01",
                    "ingred_marshmerrow_01",
                    "Ingred_meadow_rye_01",
                },
                count = 5.
            }
        }
    },
    {
        name = "Доспехи",
        description = "Полный комплект легких, средних или тяжелых доспехов, в зависимости от того, что лучше всего подходит для выбранного класса. Уже занятые слоты брони игнорируются.",
        items = {
            itemPicks.helm,
            itemPicks.boots,
            itemPicks.cuirass,
            itemPicks.greaves,
            itemPicks.leftGauntlet,
            itemPicks.rightGauntlet,
            itemPicks.leftPauldron,
            itemPicks.rightPauldron,
        }
    },
    {
        name = "Оружие",
        description = "Базовое оружие, соответствующее лучшему навыку для выбранного класса.",
        items = {
            itemPicks.weapon,
        }
    },
    {
        name = "Продукты питания",
        description = "Набор продуктов питания.",
        items = {
            { id = "ingred_bread_01", count = 2 },
            { id = "ingred_comberry_01", count = 3 },
            {
                id = "ingred_hound_meat_01",
                count = 1,
                data = { cookedAmount = 100, grillState = "cooked" }
            },
            {
                id = "ingred_crab_meat_01",
                count = 1,
                data = { cookedAmount = 100, grillState = "cooked" }
            }
        }
    },
    {
        name = "Зелья",
        description = "Набор базовых зелий восстановления здоровья, магии и усталости.",
        items = {
            { id = "p_restore_health_c", count = 2 },
            { id = "p_restore_magicka_c", count = 2 },
            { id = "p_restore_fatigue_c", count = 2 }
        }
    },
    {
        name = "Камни душ",
        description = "Набор камней душ.",
        items = {
            itemPicks.soulGems(3)
        }
    },
    {
        name = "Выпивка",
        description = "Набор алкогольных напитков.",
        items = {
            itemPicks.booze(4)
        }
    },
    {
        name = "Лютня",
        description = "Лютня, если у вас ее еще нет.",
        items = {
            itemPicks.lute
        }
    },
    {
        name = "Воровские инструменты",
        description = "Отмычки и щупы для начинающего вора.",
        items = {
            { id = "pick_apprentice_01", count = 2, },
            { id = "probe_apprentice_01", count = 2, },
        }
    },
}


for _, loadout in ipairs(itemListInputs) do
    Loadouts.register{
        id = loadout.name,
        itemList = loadout
    }
end

