local JoyOfPainting = require("mer.joyOfPainting")

local paletteItems = {
    {
        id = "ashfall_ingred_coal_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 5,
    },
    {
        id = "t_ingmine_charcoal_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 5,
    },
    {
        id = "jop_coal_sticks_01",
        paintType = "charcoal",
        breaks = true,
        fullByDefault = true,
        uses = 20,
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
    }
}

local paintTypes = {
    {
        id = "charcoal",
        name = "Charcoal",
        brushType = nil,
    },
    {
        id = "ink",
        name = "Ink",
        brushType = "quill",
    },
    {
        id = "watercolor",
        name = "Watercolor Paint",
        brushType = "brush",
    },
    {
        id = "oil",
        name = "Oil Paint",
        brushType = "brush",
    },
    {
        id = "pencil",
        name = "Color Pencil",
        brushType = nil,
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
