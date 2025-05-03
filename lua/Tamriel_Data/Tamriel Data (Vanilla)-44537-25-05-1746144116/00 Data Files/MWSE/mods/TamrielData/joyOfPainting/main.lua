local JoyOfPainting = include("mer.joyOfPainting")

local paletteItems = {
    {
        id = "T_Bre_RedGlassInkwell_01",
        paintType = "ink",
        fullByDefault = true,
        uses = 50,
        paintValue = 20,
    },
	{
        id = "T_Com_InkVial_01",
        paintType = "ink",
        fullByDefault = true,
        uses = 50,
        paintValue = 20,
    },
	    {
        id = "T_De_BluewareInkwell01",
        paintType = "ink",
        fullByDefault = true,
        uses = 50,
        paintValue = 20,
    },
	    {
        id = "T_De_EbonyInkwell_01",
        paintType = "ink",
        fullByDefault = true,
        uses = 50,
        paintValue = 20,
    },
	    {
        id = "T_Rga_Inkwell_01",
        paintType = "ink",
        fullByDefault = true,
        uses = 50,
        paintValue = 20,
    },
}

event.register(tes3.event.initialized, function()
    if JoyOfPainting then
        for _,item in ipairs(paletteItems) do
            JoyOfPainting.Palette.registerPaletteItem(item)
        end

        -- for _, brush in ipairs(brushes) do
            -- JoyOfPainting.Brush.registerBrush(brush)
        -- end

        -- for _, paintType in ipairs(paintTypes) do
            -- JoyOfPainting.Palette.registerPaintType(paintType)
        -- end
    end
end)
