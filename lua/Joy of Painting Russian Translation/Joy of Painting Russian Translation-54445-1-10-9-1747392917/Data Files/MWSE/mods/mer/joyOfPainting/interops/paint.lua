local JoyOfPainting = require("mer.joyOfPainting")

local paletteItems = {
    {
        id = "ashfall_ingred_coal_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 1,
    },
    {
        id = "t_ingmine_charcoal_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 1,
    },
    {
        id = "jop_coal_sticks_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 10,
    },
    {
        id = "misc_inkwell",
        meshOverride = "meshes\\jop\\inkwell.nif",
        paintType = "ink",
        fullByDefault = true,
        uses = 20,
        paintValue = 20,
    },
    {
        id = "jop_water_palette_01",
        paintType = "watercolor",
        uses = 15,
        paintValue = 20,
        fullByDefault = true,
    },
    {
        id = "Jop_oil_palette_01",
        paintType = "oil",
        uses = 10,
        paintValue = 40,
    },
    {
        id = "T_Com_Paint_Palette_01",
        paintType = "oil",
        uses = 10,
        paintValue = 40,
    },
    {
        id = "jop_color_pencils_01",
        paintType = "pencil",
        uses = 20,
        paintValue = 30,
        fullByDefault = true,
        breaks = true,
    },
    {
        id = "jop_pastels_01",
        paintType = "pastel",
        uses = 20,
        fullByDefault = true,
        breaks = true,
    }
}

---@type JOP.PaintType[]
local paintTypes = {
    {
        id = "charcoal",
        name = "Уголь",
        brushType = nil,
        action = "Рисовать",
    },
    {
        id = "ink",
        name = "Чернила",
        brushType = "quill",
        action = "Сделать эскиз",
    },
    {
        id = "watercolor",
        name = "Акварельная краска",
        brushType = "brush",
        action = "Написать картину",
    },
    {
        id = "oil",
        name = "Масляная краска",
        brushType = "brush",
        action = "Написать картину",
    },
    {
        id = "pencil",
        name = "Цветные карандаши",
        brushType = nil,
        action = "Рисовать",
    },
    {
        id = "pastel",
        name = "Пастель",
        brushType = nil,
        action = "Рисовать",
    }

}
event.register(tes3.event.initialized, function()
    for _, item in ipairs(paletteItems) do
        JoyOfPainting.Palette.registerPaletteItem(item)
    end
    for _, paintType in ipairs(paintTypes) do
        JoyOfPainting.Palette.registerPaintType(paintType)
    end
end)
