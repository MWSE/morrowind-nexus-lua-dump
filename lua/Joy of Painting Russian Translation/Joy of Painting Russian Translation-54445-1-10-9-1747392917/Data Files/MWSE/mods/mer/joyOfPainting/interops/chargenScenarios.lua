local ChargenScenarios = include("mer.chargenScenarios")
if not ChargenScenarios then return end
---@type ChargenScenarios.ItemListInput[]
local loadouts = {
    name = "Принадлежности для рисования",
    description = "Базовый набор принадлежностей для рисования.",
    items = {
        {
            ids = {
                "sc_paper plain",
                "jop_parchment_01"
            },
            count = 5,
        },
        {
            id = "jop_brush_01",
            count = 1,
        },
        {
            id = "jop_water_palette_01",
            count = 1,
            data = {
                joyOfPainting = {
                    uses = 15
                }
            }
        },
        {
            ids = {
                "jop_color_pencils_01",
                "jop_pastels_01",
                "misc_inkwell"
            },
            ammo = {
                {
                    weaponId = "misc_inkwell",
                    ammoId = "misc_quill"
                }
            },
            count = 1
        }
    }
}

event.register("initialized", function (e)
    ChargenScenarios.registerLoadout{
        id = "joyOfPainting:" .. loadouts.name,
        itemList = loadouts
    }
end)