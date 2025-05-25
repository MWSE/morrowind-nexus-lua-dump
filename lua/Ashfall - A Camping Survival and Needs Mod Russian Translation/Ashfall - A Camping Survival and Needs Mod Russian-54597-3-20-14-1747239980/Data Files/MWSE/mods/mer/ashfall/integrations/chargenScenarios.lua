local ChargenScenarios = include("mer.chargenScenarios")
if not ChargenScenarios then return end
---@type ChargenScenarios.ItemListInput[]
local loadouts = {
    {
        name = "Снаряжение для выживания",
        description = "Базовый набор снаряжения для выживания в дикой природе.",
        items = {
            { id = "ashfall_woodaxe", noDuplicates = true },
            { id = "ashfall_flintsteel", noDuplicates = true },
            { id = "ashfall_cooking_pot", noDuplicates = true },
            {
                id = "ashfall_waterskin",
                noDuplicates = true,
                data = { waterAmount = 50 },
            },
            { id = "ashfall_tent_base_m", noDuplicates = true },
            { id = "misc_com_iron_ladle", noDuplicates = true },
        }
    },
    {
        name = "Чайный сервиз",
        description = "Чайный сервиз для спокойных моментов в перерыве между приключениями.",
        items = {
            { id = "ashfall_stand_01", noDuplicates = true },
            {
                description = "Чайник",
                id = "ashfall_kettle_08",
                noDuplicates = true,
                data = {
                    waterAmount = 100,
                    teaProgress = 100,
                    waterHeat = 100,
                    waterType = "ingred_hackle-lo_leaf_01"
                }
            },
            {
                description = "Чашка",
                id = "ashfall_teacup_01",
                count = 2,
            },
        }
    }
}

for _, loadout in ipairs(loadouts) do
    ChargenScenarios.registerLoadout{
        id = "ashfall:" .. loadout.name,
        itemList = loadout
    }
end