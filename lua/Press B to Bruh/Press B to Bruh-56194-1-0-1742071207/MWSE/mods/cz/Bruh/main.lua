local defaultConfig = {
    enabled = true,
    key = {
        keyCode = tes3.scanCode.b,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}

local config = mwse.loadConfig("bruh", defaultConfig)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = "Bruh" })
    template:saveOnClose("bruh", config)
    template:register()

    local page = template:createSideBarPage({ label = "Settings" })

    page.sidebar:createInfo({
        text = (
            "Press B to Bruh v1.0.0\n"
            .. "By CarlZee\n\n"
            .. "Revisit the 2018 classic from New Vegas in this shiny new form! Press <configurable key> to Bruh :)\n\n"
        ),
    })

    local settings = page:createCategory("Settings")

    settings:createYesNoButton({
        label = "Enable Mod",
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = config
        }),
    })

    settings:createKeyBinder({
        label = "Bruh Key",
        description = "Assign a new keybind for the Bruh button.",
        variable = mwse.mcm.createTableVariable({
            id = "key",
            table = config
        }),
        allowCombinations = false,
    })
end

--- @param e keyDownEventData
local function bruh(e)
    if(e.keyCode == config.key.keyCode) then
        if not tes3.menuMode() then tes3.playSound({soundPath = "cz\\bruh.wav"})  end
    end
end

local function onInitialized()
    event.register("keyDown", bruh)
    mwse.log("[Bruh] initialized")
end
event.register("initialized", onInitialized)
event.register("modConfigReady", registerModConfig)