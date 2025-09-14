local defaultConfig = {
    enabled = true,
    chance = 10000,
    width = 1.5,
    height = 1.0
}

local config = mwse.loadConfig("foxyJumpscare", defaultConfig)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = "Foxy Jumpscare" })
    template:saveOnClose("foxyJumpscare", config)
    template:register()

    local page = template:createSideBarPage({ label = "Settings" })

    page.sidebar:createInfo({
        text = (
            "Foxy Jumpscare v1.0.0\n"
            .. "By CarlZee\n\n"
            .. "MWSE port of 1 in 10000 Chance for Withered Foxy Jumpscare Every Second\n\n"
        ),
    })

    local settings = page:createCategory("Settings")

    settings:createYesNoButton({
        label = "Enable Mod",
        variable = mwse.mcm.createTableVariable {
            id = "enabled",
            table = config,
        },
    })

    settings:createSlider({
        label = "Jumpscare Chance",
        description = "Chance every second that you get jumpscared (1 in X).",
        min = 10,
        max = 50000,
        step = 100,
        jump = 1000,
        variable = mwse.mcm.createTableVariable {
            id = "chance",
            table = config,
        },
    })

    settings:createSlider({
        label = "Width Proportional",
        description = "Adjust the width ratio of the image. Default: 1.5",
        min = 0.1,
        max = 2,
        step = 0.1,
        jump = 0.5,
        decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable {
            id = "width",
            table = config,
        },
    })

    settings:createSlider({
        label = "Height Proportional",
        description = "Adjust the height ratio of the image. Default: 1.0",
        min = 0.1,
        max = 2,
        step = 0.1,
        jump = 0.5,
        decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable {
            id = "height",
            table = config,
        },
    })
end
event.register("modConfigReady", registerModConfig)

local texturePaths = {
    "textures\\384.dds",
    "textures\\385.dds",
    "textures\\386.dds",
    "textures\\388.dds",
    "textures\\389.dds",
    "textures\\390.dds",
    "textures\\391.dds",
    "textures\\392.dds",
    "textures\\393.dds",
    "textures\\394.dds",
    "textures\\395.dds",
    "textures\\396.dds",
    "textures\\397.dds",
    "textures\\398.dds",
}

local frame = 0
local timer = 0
local active = false
local frameInterval = 1 / 24
local chanceTimer = 0
local chanceInterval = 1
local jumpFrame

local function jumpscare()
    frame = 0
    timer = 0
    active = true

    local menu = tes3ui.findMenu("MenuMulti")
    if menu then
        jumpFrame = menu:createImage({ id = tes3ui.registerID("FoxyJumpscareImage"), path = texturePaths[1] })
        jumpFrame.absolutePosAlignX = 0.5
        jumpFrame.absolutePosAlignY = 0.5
        jumpFrame.imageScaleX = config.width
        jumpFrame.imageScaleY = config.height
        menu:updateLayout()
    end

    tes3.playSound({ soundPath = "Xscream2.wav" })
end

--- @param e simulateEventData
local function onSimulate(e)
    if not config.enabled then return end

    chanceTimer = chanceTimer + e.delta
    if chanceTimer >= chanceInterval then
        chanceTimer = chanceTimer - chanceInterval
        if math.random(config.chance) == 1 and not active then
            jumpscare()
        end
    end

    if active and jumpFrame then
        timer = timer + e.delta
        while timer >= frameInterval and frame < #texturePaths do
            timer = timer - frameInterval
            frame = frame + 1
            jumpFrame.contentPath = texturePaths[frame]
            jumpFrame:getTopLevelMenu():updateLayout()
        end
        if frame >= #texturePaths then
            active = false
            if jumpFrame then
                jumpFrame:destroy()
                jumpFrame = nil
            end
        end
    end
end

local function onInitialized()
    event.register("simulate", onSimulate)
    mwse.log("[Foxy Jumpscare] initialized")
end
event.register("initialized", onInitialized)
