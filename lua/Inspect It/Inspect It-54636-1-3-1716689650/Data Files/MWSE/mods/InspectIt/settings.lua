local this = {}
this.metadata = toml.loadFile("Data Files\\InspectIt-metadata.toml") ---@type MWSE.Metadata?
this.modName = this.metadata.package.name
this.version = this.metadata.package.version
this.configPath = "InspectIt"
this.guideMenu = "InspectIt:MenuInspection"
this.guideMenuID = tes3ui.registerID(this.guideMenu)
this.returnButtonName = "InspectIt:ReturnButton"
this.returnEventName = "InspectIt:ReturnEvent"
this.switchAnotherLookEventName = "InspectIt:SwitchAnotherLookEvent"
this.switchLightingEventName = "InspectIt:SwitchLightingEvent"
this.toggleMirroringEventName = "InspectIt:ToggleMirroringEvent"
this.resetPoseEventName = "InspectIt:ResetPoseEvent"
this.i18n = mwse.loadTranslations("InspectIt")

---@return boolean
function this.OnOtherMenu()
    local top = tes3ui.getMenuOnTop()
    if top and top.id ~= this.guideMenuID then
        return true
    end
    return false
end

---@enum AnotherLookType
this.anotherLookType = {
    BodyParts = 1,
    WeaponSheathing = 2,
    Book = 3,
}

---@enum LightingType
this.lightingType = {
    Default = 1,
    Constant = 2,
}

---@class Config
this.defaultConfig = {
    input = {
        ---@type mwseKeyCombo
        inspect = {
            keyCode = tes3.scanCode.F2 --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        ---@type mwseKeyCombo
        another = {
            keyCode = tes3.scanCode.s --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        ---@type mwseKeyCombo
        lighting = {
            keyCode = tes3.scanCode.f --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        ---@type mwseKeyCombo
        reset = {
            keyCode = tes3.scanCode.r --[[@as tes3.scanCode]],
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        sensitivityX = 1,
        sensitivityY = 1,
        sensitivityZ = 1,
        inversionX = false,
        inversionY = false,
        inversionZ = false,
    },
    inspection = {
        inventory = true,
        barter = true,
        contents = true,
        cursorOver = true,
        activatable = true,
        playSound = true,
    },
    display = {
        instruction = true,
        bokeh = true,
        leftPart = true,
        recalculateBounds = true,
        tooltipsComplete = true,
    },
    leftPartFilter = {}, ---@type { [string] : boolean }
    ---@class Config.Development
    development = {
        experimental = false,
        logLevel = "INFO",
        logToConsole = false,
    }
}

return this
