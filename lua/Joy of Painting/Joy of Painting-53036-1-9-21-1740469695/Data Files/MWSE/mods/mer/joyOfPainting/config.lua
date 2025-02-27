---@class JOP.config
local config = {}

if toml.loadMetadata then
    config.metadata = toml.loadMetadata("The Joy of Painting")
else
    config.metadata = toml.loadFile("Data Files\\The Joy of Painting-metadata.toml")
end
if not config.metadata then
    mwse.log("Failed to load metadata.toml")
    ---@diagnostic disable missing-fields
    config.metadata = {
        package = {
            name = "The Joy of Painting",
            description = "Adds a painting skill and a merchant who sells painting supplies.",
            version = "FIX THIS"
        }
    }
    ---@diagnostic enable missing-fields
end

---Path to config file
config.configPath = "joyOfPainting"
config.ANIM_OFFSET = 2.0

---@type table<string, SkillsModule.Skill.constructorParams>
config.skills = {
    painting = {
        id = "painting",
        name = "Painting",
        value = 10,
        description = "The Painting skill determines your ability to paint on a canvas. As the skill increases, your paintings become more detailed, and can sell for a higher price.",
        icon = "Icons/jop/paintskill.dds",
        specialization = tes3.specialization.magic,
        attribute = tes3.attribute.personality,
    }
}
config.merchantPaintingSupplies = {
    jop_sketchbook_01 = 5,
    jop_frame_sq_02 = 10,
    jop_frame_w_02 = 10,
    jop_frame_t_02 = 10,
    jop_frame_sq_03 = 10,
    jop_frame_w_03 = 10,
    jop_frame_t_03 = 10,
    jop_parchment_01 = 50,
    jop_easel_pack_02 = 1,
    jop_easel_misc = 1,
    jop_brush_01 = 1,
    jop_canvas_square_01 = 20,
    jop_canvas_wide_01 = 20,
    jop_oil_palette_01 = 3,
    jop_water_palette_01 = 3,
    jop_oil_paints_01 = 5,
    jop_coal_sticks_01 = 10,
    jop_dye_red = 10,
    jop_dye_yellow = 10,
    jop_dye_blue = 10,
    jop_color_pencils_01 = 10,
    misc_inkwell = 10,
    misc_quill = 4,
    ['sc_paper plain'] = 25,
}
config.BASE_PRICE = 1.5
config.MAX_RANDOM_PRICE_EFFECT = 1.5
--Configs for how much the painting skill affects the quality of the painting
config.skillPaintEffect = {
    MAX_RADIUS = 8.0,
    MIN_RADIUS = 0.0,
    MIN_SKILL = 10,
    MAX_SKILL = 60,
    MAX_RANDOM = 2.0
}
---Configs for how much the painting skill affects the value of the painting
config.skillGoldEffect = {
    MIN_EFFECT = 1,
    MAX_EFFECT = 25,
    MIN_SKILL = 10,
    MAX_SKILL = 100,
}
---Configs for how much paintings increase your painting skill
config.skillProgress = {
    BASE_PROGRESS_PAINTING = 20,
    NEW_REGION_MULTI = 5.0,
    MAX_RANDOM = 5.0
}
---Configs for subject mechanics
config.subject = {
    MINIMUM_PRESENCE = 0.005,
    MINIMUM_VISIBILITY = 0.1,
}


--Configs for how thick ink is based on skill
config.ink = {
    THICKNESS_MIN = 0.0005,
    THICKNESS_MAX = 0.0030,
}



local root = io.popen("cd"):read()
--File locations
config.locations = {}
do
    config.locations.dataFiles = "Data Files\\"
    config.locations.screenshot = config.locations.dataFiles .. "Textures\\jop\\sreenshot.png"
    config.locations.paintingsDir = config.locations.dataFiles .. "Textures\\jop\\p\\"
    config.locations.iconsDir = config.locations.dataFiles .. "Icons\\jop\\"
    config.locations.paintingIconsDir = config.locations.iconsDir .. "p\\"
    config.locations.frameIconsDir = config.locations.iconsDir .. "f\\"
end

--Registered objects

---@type table<string, JOP.BackPack.Config>
config.backpacks = {}
---@type JOP.Canvas[]
config.canvases = {}
config.frameSizes = {}
config.frames = {}
config.easels = {}
config.miscEasels = {}
---@type table<string, JOP.ArtStyle.data>
config.artStyles = {}
---@type table<string, JOP.ArtStyle.control>
config.controls = {}
---@type table<string, JOP.ArtStyle.colorPicker>
config.colorPickers = {}
---@type table<string, JOP.PaintType>
config.paintTypes = {}
---@type table<string, JOP.PaletteItem>
config.paletteItems = {}
---@type table<string, JOP.BrushType>
config.brushTypes = {}
---@type table<string, JOP.Brush>
config.brushes = {}
config.easelActiveToMiscMap = {}
config.meshOverrides = {}
---@type table<string, JOP.Sketchbook.data>
config.sketchbooks = {}
---@type table<string, JOP.PaperMold.data>
config.paperMolds = {}
config.paperPulps = {}
---@type table<string, JOP.Tapestry.data>
config.tapestries = {}
---@type table<string, JOP.ArtStyle.shader>
config.shaders = {}
---@type table<string, JOP.Subject>
config.subjects = {}
---@type table<string, { isDisabled: boolean? }>
config.excludedShaders = {}

---@class JOP.config.persistent
---@field lightingMode any
---@field zoom number
local persistentDefault = {
    zoom = 100,
    brightness = 50,
    contrast = 50,
    saturation = 50,
}
---@class JOP.config.MCM
local mcmDefault = {
    enabled = true,
    logLevel = "INFO",
    savedPaintingIndexes = {},
    ---The maximum number of saved paintings to keep
    maxSavedPaintings = 20,
    ---The length in pixels of the smallest dimension of saved paintings
    savedPaintingSize = 1080,
    ---Enable the tapestry removal feature
    enableTapestryRemoval = true,
    ---Show the tapestry tooltip when hovering over a tapestry
    showTapestryTooltip = true,
    ---List of merchants who sell painting supplies
    paintSuppliesMerchants = {
        ["arrille"] = true,--seyda neen trader - high elf - 800
        ["ra'virr"] = true,--balmora trader - khajiit - 600 gold
        ["mebestian ence"] = true,--pelagiad trader - Breton - 449 gold
        ["alveno andules"] = true,--vivec pawnbroker - Dark Elf - 200
        ["goldyn belaram"] = true,--suran pawnbroker - Dark Elf - 450
        ["irgola"] = true,--caldera pawnbroker - Redguard - 500
        ["clagius clanler"] = true,--balmora outfitter - Imperial - 800
        ["fadase selvayn"] = true,--tel branora trader - Dark Elf - 500
        ["tiras sadus"] = true,--ald'ruhn trader - Dark Elf - 799
        ["heifnir"] = true,--dagon fel trader - Nord - 700
        ["ancola"] = true,--sadrith mora trader - Redguard - 800
        ["ababael timsar-dadisun"] = true,--super pro ashlander merchant - Dark Elf - what 9000
        ["shulki ashunbabi"] = true,--Gnisis trader - Dark Elf - 400
        ["perien aurelie"] = true, --hla-oad pawnbroker - Breton - 150
        ["thongar"] = true,--Khuul trader/fake inkeeper - Nord - 1200
        ["vasesius viciulus"] = true,--Molag mar trader - Imperial - 1000
        ["baissa"] = true,--Vivec foreign quarter trader - Khajiit - 100
        ["sedam omalen"] = true,--Ald Velothi's only trader - Dark Elf 400
        ["ferele athram"] = true, --Tel Aruhn trader
        ["urfing"] = true --Moonmoth Legion Fort trader - Nord 400
    },
    --Enable debug mode (generates debug meshes)
    debugMeshes = false,
    enableSubjectCapture = false,
    tooltipPaintingHeight = 100,
}
--MCM Config (stored as JSON in MWSE/config/joyOfPainting.json)
---@type JOP.config.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
---Save the current config.mcm to the config file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end
--Persistent Configs (Stored on tes3.player.data, save specific)
---@type JOP.config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config