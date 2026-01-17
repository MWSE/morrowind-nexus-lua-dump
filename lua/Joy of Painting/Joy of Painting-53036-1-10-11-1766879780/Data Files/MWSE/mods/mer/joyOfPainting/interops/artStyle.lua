local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local JoyOfPainting = require("mer.joyOfPainting")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local excludedShaders = {
    ["Bloom Soft"] = true,
    ["Eye Adaptation (HDR)"] = true,
    ["mer_pixel"] = true,
    ["mer_kuwahara"] = true,
}
for shaderId in pairs(excludedShaders) do
    JoyOfPainting.ArtStyle.registerExcludedShader{ id = shaderId }
end

--Exclude any shader that utilizes the depthframe texture
for filename in lfs.dir("Data Files/shaders/XEShaders/") do
    logger:debug("Checking %s", filename)
    local isShader = filename:sub(-3, -1) == ".fx"
    logger:debug("Is shader? %s", isShader)
    local isJopShader = filename:sub(1, 4) == "jop_"
    logger:debug("Is JOP shader? %s", isJopShader)
    if isShader and not isJopShader then
        logger:debug("Reading %s", filename)
        local path = "Data Files/shaders/XEShaders/" .. filename
        local file = io.open(path, "r") --[[@as file*]]
        local text = file:read("*all")
        file:close()
        if text:find("texture depthframe;") then
            local shaderId = filename:sub(1, -4)
            logger:debug("Found depthframe, excluding %s", shaderId)
            JoyOfPainting.ArtStyle.registerExcludedShader{ id = shaderId }
        end
    end
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
    { id = "charcoalHatch", shaderId = "jop_charcoal", defaultControls = { "charcoalHatchSize" } },
    { id = "greyscale", shaderId = "jop_greyscale" },
    { id = "blackAndWhite", shaderId = "jop_blackwhite" },
    { id = "ink", shaderId = "jop_ink" },
    { id = "oil", shaderId = "jop_oil" },
    { id = "watercolor", shaderId = "jop_watercolor" },
    { id = "window", shaderId = "jop_window" },
    { id = "detail", shaderId = "jop_kuwahara", defaultControls = {"brushSize", "kuwaharaBlur"} },
    { id = "splash", shaderId = "jop_splash" },
    { id = "distort", shaderId = "jop_distort", defaultControls = {"distortionStrength"} },
    {
        id = "fogColor",
        shaderId = "jop_fog_color",
        defaultControls = {
            "distanceColor",
            "fogColorDistortionStrength",
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
            "outlineDarkness",
            "shadow"
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
            "pencilStrength",
            "pencilScale",
            "vignette",
        }
    },
    { id = "hatch", shaderId = "jop_hatch", defaultControls = { "hatchSize", "hatchDistortionStrength" } },
    { id = "mottle", shaderId = "jop_mottle" },
    { id = "quantize", shaderId = "jop_quantize", defaultControls = { "quantizeHueLevels", "quantizeLuminosityLevels"} },
    { id = "pastel", shaderId = "jop_pastel" },
    { id = "sharpen", shaderId = "jop_sharpen", defaultControls = { "sharpenStrength"} },
    { id = "depthOfField", shaderId = "jop_dof", defaultControls = { "depthOfFieldStrength"} },
    { id = "palette", shaderId = "jop_lut", defaultControls = { "selectPalette" } },
}

local getDistortionStrength = function (paintingSkill, artStyle)
    paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
    local max = artStyle.maxDetailSkill
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
        id = "outlineThicknessPencil",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Outline Thickness",
        sliderDefault = 3,
        sliderMin = 1,
        sliderMax = 10,
        shaderMin = 2.0,
        shaderMax = 8.0,
    },
    {
        id = "outlineThicknessCharcoal",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Outline Thickness",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 10,
        shaderMin = 0.0,
        shaderMax = 8.0,
    },
    {
        id = "outlineThicknessInk",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Outline Thickness",
        sliderDefault = 3,
        sliderMin = 1,
        sliderMax = 10,
        shaderMin = 1.0,
        shaderMax = 8.0,
    },
    {
        id = "outlineDarkness",
        uniform = "lineDarkMulti",
        shader = "jop_outline",
        calculate = function(_, artStyle)
            return ({
                pencil = 0.1,
                watercolor = 0.3,
            })[artStyle.paintType.id]  or 0.05
        end
    },
    {
        name = "Shadow",
        id = "shadow",
        uniform = "shadow",
        shader = "jop_outline",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 100,
        shaderMin = 0.0,
        shaderMax = 0.4,
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
        calculate = function(_)
            return 2
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
        id = "watercolorTransparency",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 10,
        shaderMin = 0.2,
        shaderMax = 1.0,
    },
    {
        id = "oilTransparency",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Transparency",
        sliderDefault = 10,
        shaderMin = 0.1,
        shaderMax = 0.5,
    },
    {
        id = "oilComposite",
        uniform = "compositeStrength",
        shader = "jop_composite",
        calculate = function(_)
            return 0.05
        end
    },
    {
        id = "pastelComposite",
        uniform = "compositeStrength",
        shader = "jop_composite",
        calculate = function(_)
            return 0.0
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
        shaderMin = 0.0,
        shaderMax = 5.0,
        defaultValue = 0.0,
    },
    {
        id = "hue",
        uniform = "hue",
        shader = "jop_adjuster",
        name = "Hue",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 2.0,
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
        id = "fogColorDistortionStrength",
        uniform = "distortionStrength",
        shader = "jop_fog_color",
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
                (artStyle.maxBrushSize or 0), (artStyle.minBrushSize or 0)
            )
        end
    },
    {
        id = "kuwaharaBlur",
        uniform = "blur_strength",
        shader = "jop_kuwahara",
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            local maxBlur = (artStyle.maxBrushSize or 0) * 0.1
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                 maxBlur, 0
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
            return 0.2
        end
    },
    {
        id = "pencilStrength",
        uniform = "hatchStrength",
        shader = "jop_composite",
        name = "Pencil Strength",
        calculate = function(_, artStyle)
            local strengths = {
                pencil = 0.4,
            }
            return strengths[artStyle.paintType.id] or 0
        end
    },
    {
        id = "pencilScale",
        uniform = "hatchSize",
        shader = "jop_composite",
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, 100)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                1.1, 0.8
            )
        end
    },
    {
        id = "charcoalHatchSize",
        uniform = "hatchSize",
        shader = "jop_charcoal",
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                1.1, 0.8
            )
        end
    },
    {
        id = "quantizeHueLevels",
        uniform = "hueLevels",
        shader = "jop_quantize",
        calculate = function(_, artStyle)
            return ({
                watercolor = 24,
                oil = 36,
                pastel = 20,
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "quantizeLuminosityLevels",
        uniform = "luminosityLevels",
        shader = "jop_quantize",
        calculate = function(_, artStyle)
            return ({
                watercolor = 20,
                oil = 36,
                pastel = 26,
            })[artStyle.paintType.id] or 0
        end
    },

    {
        id = "vignette",
        uniform = "maskIndex",
        shader = "jop_composite",
        calculate = function(_, artStyle)
            return ({
                pencil = 1,
                ink = 1,
                charcoal = 2,
                watercolor = 3,
                oil = 4,
                pastel = 4,
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "enableVignette",
        uniform = "maskEnabled",
        shader = "jop_composite",
        name = "Border",
        sliderDefault = 1,
        sliderMin = 0,
        sliderMax = 1,
        shaderMin = 0,
        shaderMax = 1,
    },
    {
        id = "sharpenStrength",
        uniform = "sharpen_strength",
        shader = "jop_sharpen",
        calculate = function(paintingSkill, artStyle)
            return ({
                ink = math.clamp(math.remap(paintingSkill,
                    config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                    0, 10
                ), config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill),
                charcoal = math.clamp(math.remap(paintingSkill,
                    config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                    0, 5
                ), config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill),
                pastel = 10,
                pencil = 5,
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "depthOfFieldStrength",
        uniform = "blur_strength",
        shader = "jop_dof",
        name = "Depth of Field",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 100,
        shaderMin = 0.0,
        shaderMax = 3.0,
    },
    {
        id = "selectPalette",
        uniform = "selectedLut",
        shader = "jop_lut",
        name = "Color Palette",
        sliderDefault = 1,
        sliderMin = 1,
        sliderMax = 10,
        shaderMin = 1,
        shaderMax = 10,
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
            "sharpen",
            -- "greyscale",
            "outline",
            "detail",
            "adjuster",
            "charcoalHatch",
            "composite",
            "depthOfField",
        },
        controls = {
            "brightness",
            "contrast",
            "charcoalCompositeStrength",
            "compositeFogDistance",
            "outlineThicknessCharcoal",
            "enableVignette",
        },
        valueModifier = 1,
        paintType = "charcoal",
        maxDetailSkill = 30,
        minBrushSize = 1,
        maxBrushSize = 3,
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
            "sharpen",
        },
        controls = {
            "brightness",
            "contrast",
            "inkCompositeStrength",
            "distanceHatch",
            "outlineThicknessInk",
            "enableVignette",
        },
        valueModifier = 1.5,
        paintType = "ink",
        maxDetailSkill = 40,
        minBrushSize = 0.1,
        maxBrushSize = 2,
        helpText = [[
Tip: Increase contrast for environmental sketches. Decrease contrast for faces.
]]
    },
    {
        id = "Pencil Drawing",
        name = "Pencil Drawing",
        shaders = {
            "sharpen",
            "detail",
            "adjuster",
            "outline",
            "composite",
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
            "transparency",
            "compositeFogDistance",
            "colorPencilTimeOffsetMulti",
            "outlineThicknessPencil",
            "enableVignette",
        },
        valueModifier = 3,
        paintType = "pencil",
        maxDetailSkill = 55,
        minBrushSize = 0.1,
        maxBrushSize = 2,
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
            "adjuster",
            "fogColor",
            "composite",
            --"quantize",
            "mottle",
            "distort",
            "depthOfField",
            "palette",
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
            "watercolorTransparency",
            "enableVignette",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
        maxDetailSkill = 50,
        minBrushSize = 2,
        maxBrushSize = 4,
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
            "adjuster",
            "composite",
            "fogColor",
            --"quantize",
            "distort",
            "depthOfField",
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
            "canvasStrengthOil",
            "distortionStrength",
            "hatchStrength",
            "oilComposite",
            "oilTransparency",
            "enableVignette",
        },
        valueModifier = 9,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
        maxDetailSkill = 60,
        minBrushSize = 0.7,
        maxBrushSize = 4,
        helpText = [[
Oil paintings require high skill before they start looking detailed.

Reduce contrast for a more matte look, or increase contrast to create more defined paint lines.
]]
    },

    {
        id = "Pastel Drawing",
        name = "Pastel Drawing",
        shaders = {
            "detail",
            "adjuster",
            "composite",
            "fogColor",
            "pastel",
            "distort",
            "depthOfField",
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
            "pastelComposite",
            "distortionStrength",
            "enableVignette",
        },
        valueModifier = 5,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "pastel",
        maxDetailSkill = 50,
        minBrushSize = 1,
        maxBrushSize = 5,
        helpText = [[
Pastel drawings are a good way to create a soft, dreamy look. They work best with high contrast images against an empty background.
]]
    }
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