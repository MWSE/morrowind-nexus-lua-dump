local ChargenScenarios = include("mer.chargenScenarios")
if not ChargenScenarios then return end
---@type ChargenScenarios.ItemListInput[]
local loadouts = {
    {
        name = "Рыболовные снасти",
        description = "Начальный набор рыболовных снастей.",
        items = {
            { id = "misc_de_fishing_pole" },
            { id = "misc_com_basket_02" },
            {
                description = "Блесна",
                ids = {
                    "mer_bug_spinner",
                    "mer_bug_spinner2",
                    "mer_silver_lure"
                }
            },
            {
                description = "Живец",
                ids = {
                    "mer_meat_seabass",
                    "mer_meat_cod",
                    "mer_meat_tambaqui"
                },
                count = 3
            },
            ChargenScenarios.itemPicks.knife
        }
    },
}

event.register("initialized", function (e)
    for _, loadout in ipairs(loadouts) do
        ChargenScenarios.registerLoadout{
            id = "ultimateFishing:" .. loadout.name,
            itemList = loadout
        }
    end
end)
