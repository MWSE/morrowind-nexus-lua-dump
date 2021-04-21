local modName = "Lower First Person Sneak"
local modConfig = string.gsub(modName, "%s+", "")
local modInfo = [[Lower first person sneak view, but without a plugin.
The greater the slider value, the further the camera will be from standing position.

Vanilla default: 10, Mod default: 25

Click the apply button or restart the game to apply the changes.]]

local defaultConfig = {i1stPersonSneakDelta = 25}

local config = mwse.loadConfig(modConfig, defaultConfig)

local function applyChanges()
    tes3.findGMST("i1stPersonSneakDelta").value = config.i1stPersonSneakDelta
    mwse.log("[%s] First Person Sneak Delta set to %s", modName, config.i1stPersonSneakDelta)
end

local function onInitialized() applyChanges() end

local function configMenu()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(modConfig, config)

    local page = template:createSideBarPage({
        label = "Sidebar Page???",
        description = string.format("%s\n\n%s", modName, modInfo)
    })

    local category = page:createCategory(modName)

    category:createSlider({
        label = "First Person Sneak Level",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable({id = "i1stPersonSneakDelta", table = config})
    })

    category:createButton({buttonText = "Apply", callback = applyChanges})

    return template
end

event.register("modConfigReady", function() mwse.mcm.register(configMenu()) end)
event.register("initialized", onInitialized)
