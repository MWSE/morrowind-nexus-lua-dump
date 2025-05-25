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
            "pencilScale"
        }
    },
    { id = "hatch", shaderId = "jop_hatch", defaultControls = { "hatchSize", "hatchDistortionStrength" } },
    { id = "mottle", shaderId = "jop_mottle" },
    { id = "quantize", shaderId = "jop_quantize", defaultControls = { "quantizeHueLevels", "quantizeLuminosityLevels"} },
    { id = "pastel", shaderId = "jop_pastel" },
    { id = "sharpen", shaderId = "jop_sharpen", defaultControls = { "sharpenStrength"} },
    { id = "depthOfField", shaderId = "jop_dof", defaultControls = { "depthOfFieldStrength"} }
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
        name = "Максимальное расстояние",
        sliderDefault = 50,
        shaderMin = 100,
        shaderMax = 200000,
    },
    {
        id = "outlineDetail",
        uniform = "lineTest",
        shader = "jop_outline",
        name = "Детализация",
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
        name = "Толщина контура",
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
        name = "Толщина контура",
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
        name = "Толщина контура",
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
        name = "Тень",
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
        name = "Прозрачность",
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
        name = "Прозрачность",
        sliderDefault = 10,
        shaderMin = 0.2,
        shaderMax = 1.0,
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
        name = "Дальность видимости",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "brightness",
        uniform = "brightness",
        shader = "jop_adjuster",
        name = "Яркость",
        sliderDefault = 50,
        shaderMin = -0.2,
        shaderMax = 0.2,
    },
    {
        id = "contrast",
        uniform = "contrast",
        shader = "jop_adjuster",
        name = "Контрастность",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 2.01,
    },
    {
        id = "saturation",
        uniform = "saturation",
        shader = "jop_adjuster",
        name = "Насыщенность",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 5.0,
        defaultValue = 0.0,
    },
    {
        id = "hue",
        uniform = "hue",
        shader = "jop_adjuster",
        name = "Оттенок",
        sliderDefault = 0,
        shaderMin = 0.0,
        shaderMax = 2.0,
        defaultValue = 0.0,
    },
    {
        id = "detail",
        uniform = "sensitivity",
        shader = "jop_ink",
        name = "Детализация",
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
        name = "Дальность видимости",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },

    {
        id = "distanceColor",
        uniform = "distance",
        shader = "jop_fog_color",
        name = "Дальность видимости",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "distanceHatch",
        uniform = "fogDistance",
        shader = "jop_hatch",
        name = "Дальность видимости",
        sliderDefault = 100,
        shaderMin = 0,
        shaderMax = 250,
    },
    {
        id = "inkDistance",
        uniform = "distance",
        shader = "jop_ink",
        name = "Дальность видимости",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "bgColor",
        uniform = "bgColor",
        shader = "jop_fog_bw",
        name = "Яркость фона",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
        defaultValue = -1.0,
    },
    {
        id = "threshold",
        uniform = "threshold",
        shader = "jop_blackwhite",
        name = "Градиент",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 2.9,
    },
    {
        id = "watercolorLut",
        uniform = "selectedLut",
        shader = "jop_watercolor",
        name = "Цветовая палитра",
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
            return 0.15
        end
    },
    {
        id = "pencilStrength",
        uniform = "hatchStrength",
        shader = "jop_composite",
        name = "Твердость карандаша",
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
        id = "vignette",
        uniform = "maskIndex",
        shader = "jop_composite",
        name = "Виньетирование",
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
        id = "sketchAlphaMask",
        uniform = "sketchMaskIndex",
        shader = "jop_composite",
        name = "Виньетирование",
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
                ink = math.remap(paintingSkill,
                    config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                    0, 20
                ),
                charcoal = math.remap(paintingSkill,
                    config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                    0, 5
                ),
                pastel = 20,
                pencil = 10,
            })[artStyle.paintType.id] or 0
        end
    },
    {
        id = "depthOfFieldStrength",
        uniform = "blur_strength",
        shader = "jop_dof",
        name = "Глубина резкости",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 100,
        shaderMin = 0.0,
        shaderMax = 3.0,
    },
}

---@type JOP.ArtStyle.colorPicker[]
local colorPickers = {
    {
        id = "fogColor",
        shader = "jop_fog_color",
        name = "Цвет фона",
        uniform = "fogColor",
        defaultValue = { r = 1, g = 1, b = 1 },
    },
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        id = "Charcoal Drawing",
        name = "Рисунок углем",
        shaders = {
            "adjuster",
            "sharpen",
            "greyscale",
            "outline",
            "detail",
            "adjuster",
            "charcoalHatch",
            "composite",
            "depthOfField",
        },
        controls = {
            "sketchAlphaMask",
            "brightness",
            "contrast",
            "charcoalCompositeStrength",
            "compositeFogDistance",
            "outlineThicknessCharcoal"
        },
        valueModifier = 1,
        paintType = "charcoal",
        maxDetailSkill = 30,
        minBrushSize = 1,
        maxBrushSize = 3,
        helpText = [[
Рисунки углем лучше всего подходят для высококонтрастных изображений на пустом фоне.

Используйте настройку "Дальность видимости" для удаления фоновых элементов и "Контрастность" для настройки контрастности.
]]
    },
    {
        id = "Ink Sketch",
        name = "Чернильный эскиз",
        shaders = {
            "detail",
            "ink",
            "adjuster",
            "composite",
            "outline",
            "hatch",
            "sharpen"
        },
        controls = {
            "brightness",
            "contrast",
            "inkCompositeStrength",
            "distanceHatch",
            "outlineThicknessInk"
        },
        valueModifier = 1.5,
        paintType = "ink",
        maxDetailSkill = 40,
        minBrushSize = 0.1,
        maxBrushSize = 2,
        helpText = [[
Совет: Увеличьте контрастность для зарисовок окружающей среды. Уменьшите контрастность для лиц.
]]
    },
    {
        id = "Pencil Drawing",
        name = "Рисунок карандашом",
        shaders = {
            "sharpen",
            "detail",
            "adjuster",
            "outline",
            "composite",
        },
        controls = {
            "sketchAlphaMask",
            "brightness",
            "contrast",
            "saturation",
            "transparency",
            "compositeFogDistance",
            "colorPencilTimeOffsetMulti",
            "outlineThicknessPencil",
        },
        valueModifier = 3,
        paintType = "pencil",
        maxDetailSkill = 55,
        minBrushSize = 0.1,
        maxBrushSize = 2,
        helpText = [[
Яркие участки карандашного рисунка будут заменены фоном. Помните об этом при подготовке сцены, используйте настройки контрастности/яркости, чтобы убедиться, что все части изображения, которые вы хотите сохранить, имеют яркость ниже 50%.
]]
    },
    {
        id = "Watercolor Painting",
        name = "Акварельная картина",
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
        },
        controls = {
            "vignette",
            "brightness",
            "contrast",
            "saturation",
            "watercolorTransparency",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
        maxDetailSkill = 50,
        minBrushSize = 2,
        maxBrushSize = 4,
        helpText = [[
Акварельные рисунки имеют ограниченную цветовую палитру и густые мазки кисти. Они хороши для создания абстрактных картин и картин в стиле импрессионизм.

Попробуйте заменить фон настройкой "Дальность видимости" и изменить цвет фона, чтобы получить интересные цветовые сочетания.
]]
    },
    {
        id = "Oil Painting",
        name = "Картина маслом",
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
        minBrushSize = 0.7,
        maxBrushSize = 4,
        helpText = [[
Картины маслом требуют высокого мастерства, прежде чем они начнут выглядеть детализированными.

Уменьшите контрастность, чтобы получить более матовый вид, или увеличьте контрастность, чтобы создать более четкие линии.
]]
    },

    {
        id = "Pastel Drawing",
        name = "Рисунок пастелью",
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
            "vignette",
            "brightness",
            "contrast",
            "saturation",
            "pastelComposite",
            "distortionStrength",
        },
        valueModifier = 5,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "pastel",
        maxDetailSkill = 50,
        minBrushSize = 1,
        maxBrushSize = 5,
        helpText = [[
Рисунки пастелью хорошо подходят для создания мягкого, мечтательного образа. Они лучше всего смотрятся с высококонтрастными изображениями на пустом фоне.
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