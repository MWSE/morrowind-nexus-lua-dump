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
        },
        defaultColorPickers = {
            "fogColor"
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
        name = "Максимальное расстояние",
        sliderDefault = 50,
        shaderMin = 100,
        shaderMax = 200000,
    },
    {
        id = "outlineThickness",
        uniform = "outlineThickness",
        shader = "jop_outline",
        name = "Толщина контура",
        sliderDefault = 40,
        shaderMin = 1,
        shaderMax = 10,
    },
    {
        id = "hatchSize",
        uniform = "hatchSize",
        shader = "jop_hatch",
        name = "Размер штриховки",
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
        name = "Затемнить изображение",
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
        name = "Соотношение сторон",
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
        name = "Вращение",
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
        name = "Прозрачность",
        sliderDefault = 50,
        shaderMin = 0.0,
        shaderMax = 2.0,
    },
    {
        id = "charcoalCompositeStrength",
        uniform = "compositeStrength",
        shader = "jop_composite",
        name = "Прозрачность",
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
        name = "Прозрачность",
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
        name = "Прозрачность",
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
        uniform = "strength",
        shader = "jop_distort",
        name = "Сила искажения",
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
        name = "Детализация",
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
        name = "Насыщенность",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
    },

    {
        id = "inkThickness",
        uniform = "inkThickness",
        shader = "jop_ink",
        name = "Толщина линии",
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
        name = "Сила штриховки",
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
        name = "Прочность холста",
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
        name = "Прочность холста",
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
        name = "Твердость карандаша",
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
        name = "Карандашная шкала",
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
        name = "Виньетирование",
        sliderDefault = 0,
        sliderMin = 0,
        sliderMax = 3,
        shaderMin = 0.0,
        shaderMax = 3.0,
    }
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
Рисунки углем лучше всего подходят для высококонтрастных изображений на пустом фоне.

Используйте настройку "Дальность видимости" для удаления фоновых элементов и "Контрастность" для настройки контрастности.
]]
    },
    {
        id = "Ink Sketch",
        name = "Чернильный эскиз",
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
Совет: Увеличьте контрастность для зарисовок окружающей среды. Уменьшите контрастность для лиц.
]]
    },
    {
        id = "Pencil Drawing",
        name = "Рисунок карандашом",
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
Яркие участки карандашного рисунка будут заменены фоном. Помните об этом при подготовке сцены, используйте настройки контрастности/яркости, чтобы убедиться, что все части изображения, которые вы хотите сохранить, имеют яркость ниже 50%.
]]
    },
    {
        id = "Watercolor Painting",
        name = "Акварельная картина",
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
Картины маслом требуют высокого мастерства, прежде чем они начнут выглядеть детализированными.

Уменьшите контрастность, чтобы получить более матовый вид, или увеличьте контрастность, чтобы создать более четкие линии.
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