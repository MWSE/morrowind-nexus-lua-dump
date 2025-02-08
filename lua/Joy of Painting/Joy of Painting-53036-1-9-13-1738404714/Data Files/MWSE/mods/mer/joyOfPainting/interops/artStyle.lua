local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local JoyOfPainting = require("mer.joyOfPainting")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local excludedShaders = {
    ["Bloom Soft"] = true,
    ["Sunshafts"] = true,
    ["Eye Adaptation (HDR)"] = true,
    ["mer_pixel"] = true,
    ["mer_kuwahara"] = true,
}
for shaderId in pairs(excludedShaders) do
    JoyOfPainting.ArtStyle.registerExcludedShader{ id = shaderId }
end


---@type JOP.ArtStyle.shader[]
local shaders = {
    {
        id = "adjuster",
        shaderId = "jop_adjuster",
        defaultControls = {
            "adjusterOffsetSaturation",
        }
    },
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
    {
        id = "fogColor",
        shaderId = "jop_fog_color",
        defaultControls = {
            "distanceColor",
        },
        defaultColorPickers = {
            "fogColor"
        }
    },
    { id = "fogBW", shaderId = "jop_fog_bw", defaultControls = { "distanceBW", "bgColor" } },
    {
        id = "outline",
        shaderId = "jop_outline",
        defaultControls = {
            "outlineDistortionStrength",
            "outlineThickness",
            "outlineDarkness",
        }
    },
    {
        id = "composite",
        shaderId = "jop_composite",
        defaultControls = {
            "compositeAspectRatio",
            "compositeIsRotated",
            "compositeBlacken",
            "compositeDistortionStrength",
        }
    },
    { id = "hatch", shaderId = "jop_hatch", defaultControls = { "hatchSize", "hatchDistortionStrength" } },
    { id = "mottle", shaderId = "jop_mottle" },
    { id = "quantize", shaderId = "jop_quantize", defaultControls = { "quantizeHueLevels", "quantizeLuminosityLevels"} },
}

local getDistortionStrength = function (paintingSkill, artStyle)
    paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
    local max = artStyle.maxDistortSkill or artStyle.maxDetailSkill
    return math.max(0, math.remap(paintingSkill,
        config.skillPaintEffect.MIN_SKILL, max,
        0.1, 0.0
    ))
end

---@type JOP.ArtStyle.control[]
local controls = {
    {
        id = "adjusterOffsetSaturation",
        uniform = "saturationOffset",
        shader = "jop_adjuster",
        calculate = function (_, artStyle)
            return ({
                pencil = 0.5,
                watercolor = 0.5,
            })[artStyle.paintType.id] or 0
        end
    },
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
        id = "outlineDetail",
        uniform = "lineTest",
        shader = "jop_outline",
        name = "Detail",
        sliderDefault = 50,
        sliderMin = 0,
        sliderMax = 100,
        shaderMin = 70.0,
        shaderMax = 10.0,
    },
    {
        id = "outlineThickness",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Outline Thickness",
        sliderDefault = 3,
        sliderMin = 1,
        sliderMax = 10,
        shaderMin = 1.0,
        shaderMax = 3.0,
    },
    {
        id = "outlineDarkness",
        uniform = "lineDarkMulti",
        shader = "jop_outline",
        calculate = function(_, artStyle)
            return ({
                pencil = 0.6,
            })[artStyle.paintType.id]  or 0.25
        end
    },
    {
        id = "hatchSize",
        uniform = "hatchSize",
        shader = "jop_hatch",
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                0.11, 0.09
            )
        end
    },
    {
        id = "compositeBlacken",
        uniform = "doBlackenImage",
        shader = "jop_composite",
        calculate = function(_, artStyle)
            return({
                charcoal = 1,
                ink = 1
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "compositeAspectRatio",
        uniform = "aspectRatio",
        shader = "jop_composite",
        calculate = function(_, _, canvas)
            return PaintService.getAspectRatio(canvas)
        end
    },
    {
        id = "compositeIsRotated",
        uniform = "isRotated",
        shader = "jop_composite",
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
        shaderMax = 1.0,
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
        calculate = function(_)
            return 1
        end
    },
    {
        id = "watercolorComposite",
        uniform = "compositeStrength",
        shader = "jop_composite",
        calculate = function(_)
            return 0.3
        end
    },
    {
        id = "oilComposite",
        uniform = "compositeStrength",
        shader = "jop_composite",
        calculate = function(_)
            return 0.2
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
        id = "saturation",
        uniform = "saturation",
        shader = "jop_adjuster",
        name = "Saturation",
        sliderDefault = 0,
        shaderMin = 1.0,
        shaderMax = 5.0,
        defaultValue = 1.0,
    },
    {
        id = "hue",
        uniform = "hue",
        shader = "jop_adjuster",
        name = "Hue",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 1.0,
        defaultValue = 0.0,
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
        uniform = "distortionStrength",
        shader = "jop_distort",
        calculate = getDistortionStrength,
    },
    {
        id = "outlineDistortionStrength",
        uniform = "distortionStrength",
        shader = "jop_outline",
        calculate = getDistortionStrength,
    },
    {
        id = "hatchDistortionStrength",
        uniform = "distortionStrength",
        shader = "jop_hatch",
        calculate = getDistortionStrength
    },
    {
        id = "compositeDistortionStrength",
        uniform = "distortionStrength",
        shader = "jop_composite",
        calculate = getDistortionStrength
    },
    {
        id = "colorPencilTimeOffsetMulti",
        uniform = "timeOffsetMulti",
        shader = "jop_outline",
        calculate = function(_, artStyle)
            return ({
                pencil = 40,
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "brushSize",
        uniform = "radius",
        shader = "jop_kuwahara",
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                (artStyle.maxBrushSize or 1), (artStyle.minBrushSize or 1)
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
        id = "distanceHatch",
        uniform = "fogDistance",
        shader = "jop_hatch",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 0,
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
        calculate = function(_, _)
            return 0.2
        end
    },
    {
        id = "canvasStrengthOil",
        uniform = "canvas_strength",
        shader = "jop_splash",
        calculate = function()
            return 0.3
        end
    },
    {
        id = "canvasStrengthWatercolor",
        uniform = "canvas_strength",
        shader = "jop_splash",
        calculate = function()
            return 0.10
        end
    },
    {
        id = "pencilStrength",
        uniform = "pencil_strength",
        shader = "jop_charcoal",
        name = "Pencil Strength",
        calculate = function()
            return 0.1
        end
    },
    {
        id = "pencilScale",
        uniform = "pencil_scale",
        shader = "jop_charcoal",
        calculate = function(paintingSkill, _)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, 100)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, 100,
                0.85, 0.6
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
    },
    {
        id = "quantizeHueLevels",
        uniform = "hueLevels",
        shader = "jop_quantize",
        calculate = function(_, artStyle)
            return ({
                watercolor = 24,
                oil = 36
            })[artStyle.paintType.id] or 50
        end
    },
    {
        id = "quantizeLuminosityLevels",
        uniform = "luminosityLevels",
        shader = "jop_quantize",
        calculate = function(_, artStyle)
            return ({
                watercolor = 20,
                oil = 30
            })[artStyle.paintType.id] or 50
        end
    },
    {
        id = "sketchAlphaMask",
        uniform = "sketchMaskIndex",
        shader = "jop_composite",
        name = "Sketch Pattern",
        sliderDefault = 1,
        sliderMin = 0,
        sliderMax = 1,
        shaderMin = 0,
        shaderMax = 1,
    }
}

---@type JOP.ArtStyle.colorPicker[]
local colorPickers = {
    {
        id = "fogColor",
        shader = "jop_fog_color",
        name = "Fog Color",
        uniform = "fogColor",
        defaultValue = { r = 1, g = 1, b = 1 },
    },
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        id = "Charcoal Drawing",
        name = "Charcoal Drawing",
        shaders = {
            "adjuster",
            "greyscale",
            "distort",
            "detail",
            "adjuster",
            "pencil",
            "composite",
        },
        controls = {
            "sketchAlphaMask",
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
        id = "Ink Sketch",
        name = "Ink Sketch",
        shaders = {
            "detail",
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
            "distanceHatch",
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
        id = "Pencil Drawing",
        name = "Pencil Drawing",
        shaders = {
            "detail",
            "adjuster",
            "pencil",
            "outline",
            "composite",
        },
        controls = {
            "sketchAlphaMask",
            "brightness",
            "contrast",
            "saturation",
            "pencilStrength",
            "pencilScale",
            "transparency",
            "compositeFogDistance",
            "colorPencilTimeOffsetMulti",
        },
        valueModifier = 3,
        paintType = "pencil",
        maxDetailSkill = 55,
        minBrushSize = 3,
        maxBrushSize = 12,
        helpText = [[
The bright areas of the pencil drawing will be replaced with the background. Keep this in mind when preparing your scene, use the contrast/brightness settings to make sure any parts of the image you want to remain are below 50% brightness.
]]
    },
    {
        id = "Watercolor Painting",
        name = "Watercolor Painting",
        shaders = {
            "detail",
            "watercolor",
            "distort",
            "adjuster",
            "fogColor",
            "composite",
            "quantize",
        },
        controls = {
            "vignette",
            "brightness",
            "contrast",
            "saturation",
            "hue",
            "canvasStrengthWatercolor",
            "watercolorComposite",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
        maxDetailSkill = 50,
        maxDistortSkill = 40,
        minBrushSize = 4,
        maxBrushSize = 12,
        helpText = [[
Watercolor paintings have a limited color palette and thick brush strokes. They are good for making abstract and impressionist paintings.

Try replacing the background with the fog setting and changing the fog color to get interesting color combinations.
]]
    },
    {
        id = "Oil Painting",
        name = "Oil Painting",
        shaders = {
            "detail",
            "oil",
            "splash",
            "distort",
            "adjuster",
            "composite",
            "fogColor",
            "quantize",
        },
        controls = {
            "vignette",
            "brightness",
            "contrast",
            "canvasStrengthOil",
            "distortionStrength",
            "hatchStrength",
            "oilComposite",
        },
        valueModifier = 9,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
        maxDetailSkill = 60,
        maxDistortSkill = 50,
        minBrushSize = 4,
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
    for _, colorPicker in ipairs(colorPickers) do
        JoyOfPainting.ArtStyle.registerColorPicker(colorPicker)
    end
    for _, artStyle in ipairs(artStyles) do
        JoyOfPainting.ArtStyle.registerArtStyle(artStyle)
    end
    event.trigger("JoyOfPainting:ArtStyles")
end)