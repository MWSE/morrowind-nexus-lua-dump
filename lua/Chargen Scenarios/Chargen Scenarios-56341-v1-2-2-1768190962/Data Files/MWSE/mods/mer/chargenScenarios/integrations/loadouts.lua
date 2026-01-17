local itemPicks = require("mer.chargenScenarios.util.itemPicks")
local Loadouts = require("mer.chargenScenarios.component.Loadouts")

---@type ChargenScenarios.ItemListInput[]
local itemListInputs = {
    {
        name = "Alchemy Set",
        description = "A basic set of alchemical tools and a few random ingredients.",
        items = {
            { id = "apparatus_a_mortar_01" },
            { id = "apparatus_a_alembic_01" },
            { id = "apparatus_a_retort_01" },
            {
                description = "Alchemical Ingredient",
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
        name = "Armor",
        description = "Fills in any empty armor slots with light, medium or heave armor, whichever is best for the chosen class.",
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
        name = "Weapon",
        description = "A basic weapon matching the best skill for the chosen class.",
        items = {
            itemPicks.weapon,
        }
    },
    {
        name = "Food",
        description = "A selection of food items.",
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
        name = "Potions",
        description = "A selection of basic restore health, magick and fatigue potions.",
        items = {
            { id = "p_restore_health_c", count = 2 },
            { id = "p_restore_magicka_c", count = 2 },
            { id = "p_restore_fatigue_c", count = 2 }
        }
    },
    {
        name = "Soul Gems",
        description = "A selection of soul gems.",
        items = {
            itemPicks.soulGems(3)
        }
    },
    {
        name = "Booze",
        description = "A selection of alcoholic beverages.",
        items = {
            itemPicks.booze(4)
        }
    },
    {
        name = "Lute",
        description = "A lute, if you don't already have one.",
        items = {
            itemPicks.lute
        }
    },
    {
        name = "Thief's Tools",
        description = "Lockpicks and probes for the aspiring thief.",
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

