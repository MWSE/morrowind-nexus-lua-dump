local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local JoyOfPainting = require("mer.joyOfPainting")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local shaders = {
    { id = "adjuster", shaderId = "jop_adjuster" },
    { id = "charcoal", shaderId = "jop_charcoal" },
    { id = "greyscale", shaderId = "jop_greyscale" },
    { id = "blackAndWhite", shaderId = "jop_blackwhite" },
    { id = "ink", shaderId = "jop_ink" },
    { id = "oil", shaderId = "jop_oil" },
    { id = "sketch", shaderId = "jop_sketch" },
    { id = "vignette", shaderId = "jop_vignette" },
    { id = "watercolor", shaderId = "jop_watercolor" },
    { id = "window", shaderId = "jop_window" },
}

local controls = {
    {
        id = "brightness",
        uniform = "brightness",
        shader = "jop_adjuster",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.25,
        shaderMax = 0.25,
    },
    {
        id = "detail",
        uniform = "contrast",
        shader = "jop_ink",
        name = "Detail",
        sliderDefault = 50,
        shaderMin = 0.1,
        shaderMax = 1.9,
    },
    {
        id = "contrast",
        uniform = "contrast",
        shader = "jop_adjuster",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
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
        calculate = function(paintingSkill)
            paintingSkill = math.clamp(paintingSkill, config.ink.SKILL_MIN, config.ink.SKILL_MAX)
            return math.remap(paintingSkill,
                config.ink.SKILL_MIN, config.ink.SKILL_MAX,
                config.ink.THICKNESS_MAX, config.ink.THICKNESS_MIN
            )
        end
    },
    {
        id = "distance",
        uniform = "distance",
        shader = "jop_adjuster",
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
        shader = "jop_adjuster",
        name = "Fog Color",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "blackWhiteContrast",
        uniform = "contrast",
        shader = "jop_blackwhite",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = -1.1,
        shaderMax = 1.5,
    },
    {
        id = "blackWhiteBrightness",
        uniform = "brightness",
        shader = "jop_blackwhite",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.5,
        shaderMax = 0.5,
    },
    {
        id = "threshold",
        uniform = "threshold",
        shader = "jop_blackwhite",
        name = "Threshold",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 1,
    }
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        name = "Charcoal Drawing",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)

            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, 40,
                10, 1
            ), 10, 1)
            logger:debug("Charcoal Sketch detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createCharoalSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :blur(detailLevel)
                :paint(detailLevel)
                :sketch()
                :brightnessContrast(-30, 80)
                :removeWhite(90)
                :resizeHard(savedWidth, savedHeight)
                :gravity("center")
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "blackAndWhite",
            "adjuster",
        },
        controls = {
            "blackWhiteBrightness",
            "blackWhiteContrast",
            "threshold",
            "distance",
            "bgColor",
        },
        valueModifier = 1,
        paintType = "charcoal",
    },
    {
        name = "Ink Sketch",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                8, 1
            ), 8, 1)
            logger:debug("Ink Sketch detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createInkSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :autoGamma()
                :removeWhite(70)
                --:paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                --:blur(detailLevel)
                :gravity("center")
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "ink",
            "adjuster",
        },
        controls = {
            "detail",
            "inkThickness",
            "inkDistance",
        },
        valueModifier = 1.5,
        paintType = "ink",
    },
    {
        name = "Watercolor Painting",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                10, 3
            ), 10, 3)
            logger:debug("Watercolor Painting detail level is %d", detailLevel)
            return function(next)
                image.magick:new("Watercolor Painting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                --:autoGamma()
                :blur(detailLevel)
                :paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                --:gravity("center")
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "watercolor",
            "adjuster",
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
            "distance",
            "bgColor",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
    },

    {
        name = "Oil Painting",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                10, 0
            ), 10,0)
            logger:debug("Oil Painting detail level is %d", detailLevel)
            return function(next)
                image.magick:new("Oil Painting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                --:autoGamma()
                :blur(detailLevel)
                :paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "oil",
            "adjuster",
        },
        controls = {
            "brightness",
            "contrast",
            "distance",
            "bgColor",
        },
        valueModifier = 9,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
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