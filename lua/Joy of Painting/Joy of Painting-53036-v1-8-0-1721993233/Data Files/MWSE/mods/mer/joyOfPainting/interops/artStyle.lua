local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local JoyOfPainting = require("mer.joyOfPainting")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

---@type JOP.ArtStyle.shader[]
local shaders = {
    { id = "adjuster", shaderId = "jop_adjuster" },
    { id = "pencil", shaderId = "jop_charcoal" },
    { id = "greyscale", shaderId = "jop_greyscale" },
    { id = "blackAndWhite", shaderId = "jop_blackwhite" },
    { id = "ink", shaderId = "jop_ink" },
    { id = "oil", shaderId = "jop_oil" },
    { id = "watercolor", shaderId = "jop_watercolor" },
    { id = "window", shaderId = "jop_window" },
    { id = "detail", shaderId = "jop_kuwahara", defaultControls = {"brushSize"} },
    { id = "splash", shaderId = "jop_splash" },
    { id = "distort", shaderId = "jop_distort", defaultControls = {"distortionStrength"} },
    { id = "fogColor", shaderId = "jop_fog_color",
        defaultControls = {
            "distanceColor",
            "bgRed",
            "bgGreen",
            "bgBlue"
        }
    },
    { id = "fogBW", shaderId = "jop_fog_bw", defaultControls = { "distanceBW", "bgColor" } },
    { id = "outline", shaderId = "jop_outline" },
    { id = "composite", shaderId = "jop_composite",
        defaultControls = {
            "compositeAspectRatio",
            "compositeIsRotated",
            "compositeBlacken",
        }
    },
    { id = "hatch", shaderId = "jop_hatch", defaultControls = { "hatchSize" } },
    { id = "mottle", shaderId = "jop_mottle" },
    { id = "quantize", shaderId = "jop_quantize" },
}

---@type JOP.ArtStyle.control[]
local controls = {
    {
        id = "maxDistance",
        uniform = "maxDistance",
        shader = "jop_outline",
        name = "Max Distance",
        sliderDefault = 50,
        shaderMin = 100,
        shaderMax = 200000,
    },
    {
        id = "outlineThickness",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Outline Thickness",
        sliderDefault = 40,
        shaderMin = 1,
        shaderMax = 10,
    },
    {
        id = "hatchSize",
        uniform = "hatchSize",
        shader = "jop_hatch",
        name = "Hatch Size",
        sliderDefault = 50,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                0.15, 0.08
            )
        end
    },
    {
        id = "compositeBlacken",
        uniform = "doBlackenImage",
        shader = "jop_composite",
        name = "Blacken Image",
        sliderDefault = 0,
        shaderMin = 0,
        shaderMax = 1,
        calculate = function(_, artStyle)
            local blackenStyles = {
                charcoal = true,
                ink = true
            }
            return blackenStyles[artStyle.paintType.id] and 1 or 0
        end
    },
    {
        id = "compositeAspectRatio",
        uniform = "aspectRatio",
        shader = "jop_composite",
        name = "Aspect Ratio",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 2.0,
        calculate = function(_, _, canvas)
            return PaintService.getAspectRatio(canvas)
        end
    },
    {
        id = "compositeIsRotated",
        uniform = "isRotated",
        shader = "jop_composite",
        name = "Is Rotated",
        sliderDefault = 0,
        shaderMin = 0,
        shaderMax = 1,
        calculate = function(_, _, canvas)
            return canvas.baseRotation == 90 and 1 or 0
        end
    },
    {
        id = "transparency",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 50,
        shaderMin = 0.0,
        shaderMax = 2.0,
    },
    {
        id = "charcoalCompositeStrength",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 3.0,
        calculate = function(_)
            return 3
        end
    },
    {
        id = "inkCompositeStrength",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 3.0,
        calculate = function(_)
            return 1
        end
    },
    {
        id = "mildTransparency",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 3.0,
        calculate = function(_)
            return 0.5
        end
    },
    {
        id = "compositeFogDistance",
        uniform = "fogDistance",
        shader = "jop_composite",
        name = "Fog Distance",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "brightness",
        uniform = "brightness",
        shader = "jop_adjuster",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.2,
        shaderMax = 0.2,
    },
    {
        id = "contrast",
        uniform = "contrast",
        shader = "jop_adjuster",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 2.01,
    },
    {
        id = "detail",
        uniform = "sensitivity",
        shader = "jop_ink",
        name = "Detail",
        sliderDefault = 50,
        shaderMin = 1,
        shaderMax = 40,
    },
    {
        id = "distortionStrength",
        uniform = "strength",
        shader = "jop_distort",
        name = "Distortion Strength",
        sliderDefault = 50,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            local max = artStyle.maxDistortSkill or artStyle.maxDetailSkill
            return math.max(0, math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, max,
                0.02, 0.0
            ))
        end
    },
    {
        id = "brushSize",
        uniform = "radius",
        shader = "jop_kuwahara",
        name = "Detail",
        sliderDefault = 50,
        shaderMin = 1,
        shaderMax = 15,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                (artStyle.maxBrushSize or 1), (artStyle.minBrushSize or 1)
            )
        end
    },
    {
        id = "saturation",
        uniform = "saturation",
        shader = "jop_adjuster",
        name = "Saturation",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
    },

    {
        id = "inkThickness",
        uniform = "inkThickness",
        shader = "jop_ink",
        name = "Line Thickness",
        sliderDefault = 50,
        shaderMin = config.ink.THICKNESS_MIN,
        shaderMax = config.ink.THICKNESS_MAX,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                config.ink.THICKNESS_MAX, config.ink.THICKNESS_MIN
            )
        end
    },
    {
        id = "distanceBW",
        uniform = "distance",
        shader = "jop_fog_bw",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },

    {
        id = "distanceColor",
        uniform = "distance",
        shader = "jop_fog_color",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "inkDistance",
        uniform = "distance",
        shader = "jop_ink",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "bgColor",
        uniform = "bgColor",
        shader = "jop_fog_bw",
        name = "Fog Color",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
        defaultValue = -1.0,
    },
    {
        id = "bgRed",
        uniform = "bgRed",
        shader = "jop_fog_color",
        name = "Fog Color: Red",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "bgGreen",
        uniform = "bgGreen",
        shader = "jop_fog_color",
        name = "Fog Color: Green",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "bgBlue",
        uniform = "bgBlue",
        shader = "jop_fog_color",
        name = "Fog Color: Blue",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "threshold",
        uniform = "threshold",
        shader = "jop_blackwhite",
        name = "Threshold",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 2.9,
    },
    {
        id = "watercolorLut",
        uniform = "selectedLut",
        shader = "jop_watercolor",
        name = "Color Palette",
        sliderDefault = 1,
        sliderMin = 1,
        sliderMax = 10,
        shaderMin = 1,
        shaderMax = 10,
    },
    {
        id = "hatchStrength",
        uniform = "hatchStrength",
        shader = "jop_oil",
        name = "Hatch Strength",
        sliderDefault = 30,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function(_, _)
            return 0.2
        end
    },

    {
        id = "canvasStrengthOil",
        uniform = "canvas_strength",
        shader = "jop_splash",
        name = "Canvas Strength",
        sliderDefault = 10,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function()
            return 0.15
        end
    },
    {
        id = "canvasStrengthWatercolor",
        uniform = "canvas_strength",
        shader = "jop_splash",
        name = "Canvas Strength",
        sliderDefault = 10,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function()
            return 0.10
        end
    },
    {
        id = "pencilStrength",
        uniform = "pencil_strength",
        shader = "jop_charcoal",
        name = "Pencil Strength",
        sliderDefault = 0,
        shaderMin = 0.1,
        shaderMax = 0.9,
        calculate = function()
            return 0.1
        end
    },
    {
        id = "pencilScale",
        uniform = "pencil_scale",
        shader = "jop_charcoal",
        name = "Pencil Scale",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
        calculate = function(paintingSkill, _)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, 100)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, 100,
                0.8, 0.2
            )
        end
    },
    {
        id = "vignette",
        uniform = "maskIndex",
        shader = "jop_composite",
        name = "Splash Pattern",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 3,
        shaderMin = 0.0,
        shaderMax = 3.0,
    }
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        name = "Charcoal Drawing",
        shaders = {
            "adjuster",
            "greyscale",
            "distort",
            "detail",
            "adjuster",
            "pencil",
            "composite"
        },
        controls = {
            "brightness",
            "contrast",
            "charcoalCompositeStrength",
            "compositeFogDistance",
        },
        valueModifier = 1,
        paintType = "charcoal",
        maxDetailSkill = 30,
        minBrushSize = 3,
        maxBrushSize = 12,
        helpText = [[
Charcoal drawings work best with high contrast images against an empty background.

Use the fog setting to remove background elements and the threshold to adjust the contrast.
]]
    },
    {
        name = "Ink Sketch",
        shaders = {
            "ink",
            "adjuster",
            "composite",
            "outline",
            "hatch",
        },
        controls = {
            "brightness",
            "contrast",
            "inkCompositeStrength",
            "compositeFogDistance",
        },
        valueModifier = 1.5,
        paintType = "ink",
        maxDetailSkill = 40,
        minBrushSize = 2,
        maxBrushSize = 12,
        helpText = [[
Tip: Increase contrast for environmental sketches. Decrease contrast for faces.
]]
    },
    {
        name = "Pencil Drawing",
        shaders = {
            "detail",
            "oil",
            "adjuster",
            "pencil",
            "outline",
            "composite",
        },
        controls = {
            "brightness",
            "contrast",
            "hatchStrength",
            "pencilStrength",
            "pencilScale",
            "transparency",
            "compositeFogDistance",
        },
        valueModifier = 3,
        paintType = "pencil",
        maxDetailSkill = 55,
        minBrushSize = 2,
        maxBrushSize = 12,
        helpText = [[
The bright areas of the pencil drawing will be replaced with the background. Keep this in mind when preparing your scene, use the contrast/brightness settings to make sure any parts of the image you want to remain are below 50% brightness.
]]
    },
    {
        name = "Watercolor Painting",
        shaders = {
            "detail",
            "watercolor",
            "mottle",
            "distort",
            "adjuster",
            "fogColor",
            "composite",
            "quantize",
        },
        controls = {
            "watercolorLut",
            "vignette",
            "brightness",
            "contrast",
            "canvasStrengthWatercolor",
            "mildTransparency",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
        maxDetailSkill = 50,
        maxDistortSkill = 40,
        minBrushSize = 3,
        maxBrushSize = 12,
        helpText = [[
Watercolor paintings have a limited color palette and thick brush strokes. They are good for making abstract and impressionist paintings.

Try replacing the background with the fog setting and changing the fog color to get interesting color combinations.
]]
    },
    {
        name = "Oil Painting",
        shaders = {
            "detail",
            "oil",
            "splash",
            "distort",
            "adjuster",
            "composite",
            "fogColor",
        },
        controls = {
            "vignette",
            "brightness",
            "contrast",
            "canvasStrengthOil",
            "distortionStrength",
            "hatchStrength",
        },
        valueModifier = 9,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
        maxDetailSkill = 60,
        maxDistortSkill = 50,
        minBrushSize = 2,
        maxBrushSize = 12,
        helpText = [[
Oil paintings require high skill before they start looking detailed.

Reduce contrast for a more matte look, or increase contrast to create more defined paint lines.
]]
    },
}
event.register(tes3.event.initialized, function()
for _, shader in ipairs(shaders) do
        JoyOfPainting.ArtStyle.registerShader(shader)
    end
    for _, control in ipairs(controls) do
        JoyOfPainting.ArtStyle.registerControl(control)
    end
    for _, artStyle in ipairs(artStyles) do
        JoyOfPainting.ArtStyle.registerArtStyle(artStyle)
    end
    event.trigger("JoyOfPainting:ArtStyles")
end)