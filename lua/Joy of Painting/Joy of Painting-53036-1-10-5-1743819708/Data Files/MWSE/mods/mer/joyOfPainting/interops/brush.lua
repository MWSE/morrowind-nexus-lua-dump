local JoyOfPainting = require("mer.joyOfPainting")

local brushes = {
    {
        id = "misc_quill",
        brushType = "quill",
    },
    {
        id = "sx2_quillSword",
        brushType = "quill",
    },
    {
        id = "jop_brush_01",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_01",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_02",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_03",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04r",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04g",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04b",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04y",
        brushType = "brush",
    },
    {
        id = "ab_misc_compaintbrush01",
        brushType = "brush",
    },
    {
        id = "ab_misc_compaintbrush02",
        brushType = "brush",
    },
    {
        id = "ab_misc_reedpen",
        brushType = "quill",
    },
    {
        id = "ab_misc_quillLizard",
        brushType = "quill",
    }
}

local brushTypes = {
    {
        id = "quill",
        name = "Quill",
    },
    {
        id = "brush",
        name = "Paintbrush",
    }
}
event.register(tes3.event.initialized, function()
    for _, brush in ipairs(brushTypes) do
        JoyOfPainting.Brush.registerBrushType(brush)
    end
    for _, brush in ipairs(brushes) do
        JoyOfPainting.Brush.registerBrush(brush)
    end
end)