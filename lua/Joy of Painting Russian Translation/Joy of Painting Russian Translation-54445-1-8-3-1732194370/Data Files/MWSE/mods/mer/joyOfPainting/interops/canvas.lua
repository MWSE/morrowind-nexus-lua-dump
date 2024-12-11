--Add canvases via the interop
local JoyOfPainting = require("mer.joyOfPainting")

---@type JOP.Canvas[]
local canvases = {
    {
        canvasId = "jop_canvas_square_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "square",
        valueModifier = 2.0,
        canvasTexture = "jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01",
        clampOffset = 4,
    },
    {
        canvasId = "jop_canvas_tall_01",
        rotatedId = "jop_canvas_wide_01",
        textureWidth = 512,
        textureHeight = 1024,
        frameSize = "tall",
        valueModifier = 2.0,
        canvasTexture = "jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01",
        clampOffset = 25,
    },
    {
        canvasId = "jop_canvas_wide_01",
        rotatedId = "jop_canvas_tall_01",
        textureWidth = 1024,
        textureHeight = 512,
        frameSize = "wide",
        valueModifier = 2.0,
        canvasTexture = "jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01",
        clampOffset = -5.5,
    },
    {
        canvasId = "sc_paper plain",
        rotatedId = "jop_paper_h",
        meshOverride = "meshes\\jop\\medium\\paper_01.nif",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_portrait",
        valueModifier = 1,
        canvasTexture = "tx_paper_plain_01.dds",
        animSpeed = 2.0,
        animSound = "jop_scribble_01"
    },
    {
        canvasId = "jop_paper_h",
        rotatedId = "sc_paper plain",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_landscape",
        valueModifier = 1,
        canvasTexture = "tx_paper_plain_01.dds",
        animSpeed = 2.0,
        animSound = "jop_scribble_01",
        baseRotation = 90,
    },

    {
        canvasId = "jop_parchment_01",
        rotatedId = "jop_parchment_h_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_portrait",
        valueModifier = 1.1,
        canvasTexture = "jop\\parchment.dds",
        animSound = "jop_scribble_01",
        animSpeed = 2.0,
    },

    {
        canvasId = "jop_parchment_h_01",
        rotatedId = "jop_parchment_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_landscape",
        valueModifier = 1.1,
        canvasTexture = "jop\\parchment.dds",
        animSound = "jop_scribble_01",
        animSpeed = 2.0,
        baseRotation = 90,
    }
}

event.register(tes3.event.initialized, function()
    ---@type JOP.ArtStyle[]
    for _, canvas in ipairs(canvases) do
        JoyOfPainting.Painting.registerCanvas(canvas)
    end
end)
