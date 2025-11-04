local I = require("openmw.interfaces")
local input = require('openmw.input')
local storage = require('openmw.storage')

local config = require("scripts.proximityTool.config")
local commonData = require("scripts.proximityTool.common")



I.Settings.registerPage{
  key = commonData.settingPage,
  l10n = commonData.l10nKey,
  name = "modName",
  description = "modDescription",
}

---@class proximityTool.settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class proximityTool.settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class proximityTool.settings.selectSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default string
---@field items string[]
---@field disabled boolean|nil


---@param args proximityTool.settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        argument = {
            trueLabel = args.trueLabel,
            falseLabel = args.falseLabel,
            disabled = args.disabled,
        }
    }
end

---@param args proximityTool.settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        argument = {
            min = args.min,
            max = args.max,
            integer = args.integer,
            disabled = args.disabled,
        }
    }
    return data
end

local function inputKey(args)
    local data = {
        renderer = "inputBinding",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            key = args.argKey,
            type = args.argType
        }
    }
    return data
end

local function color(args)
    local data = {
        renderer = "color",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            disabled = args.disabled,
        }
    }
    return data
end

---@param args proximityTool.settings.selectSetting
local function selectSetting(args)
    local data = {
        key = args.key,
        renderer = "select",
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            l10n = commonData.l10nKey,
            disabled = args.disabled,
            items = args.items,
        }
    }
    return data
end


input.registerTrigger {
    key = commonData.toggleHUDTriggerId,
    l10n = commonData.l10nKey,
}



I.Settings.registerGroup{
    key = commonData.settingStorageId,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "settings",
    permanentStorage = true,
    order = 0,
    settings = {
        boolSetting{key = "enabled", name = "enableMod", default = config.default.enabled},
        numberSetting{key = "updateInterval", name = "updateInterval", description = "updateIntervalDescription", integer = true, min = 1, max = 1000, default = config.default.updateInterval},
        numberSetting{key = "objectPosUpdateInterval", name = "objectPosUpdateInterval", description = "objectPosUpdateIntervalDescription", min = 0, max = 10, default = config.default.objectPosUpdateInterval},
        numberSetting{key = "ui.size.x", name = "windowSizeX", description = "windowSizeXDescription", integer = true, min = 10, max = 100, default = config.default.ui.size.x},
        numberSetting{key = "ui.size.y", name = "windowSizeY", description = "windowSizeYDescription", integer = true, min = 10, max = 100, default = config.default.ui.size.y},
        numberSetting{key = "ui.fontSize", name = "fontSize", description = "fontSizeDescription", integer = true, min = 10, max = 100, default = config.default.ui.fontSize},
        numberSetting{key = "ui.mouseScrollAmount", name = "mouseScrollAmount", description = "mouseScrollAmountDescription", integer = true, min = 1, max = 200, default = config.default.ui.mouseScrollAmount},
        numberSetting{key = "ui.maxAlpha", name = "maxAlpha", description = "maxAlphaDescription", min = 20, max = 100, default = config.default.ui.maxAlpha},
        boolSetting{key = "ui.hideWindow", name = "hideWindow", description = "hideWindowDescription", default = config.default.ui.hideWindow},
        -- boolSetting{key = "ui.minimizeToAnchor", name = "minimizeToAnchor", description = "minimizeToAnchorDescription", default = config.default.ui.minimizeToAnchor}, --deprecated
        boolSetting{key = "ui.hideHUD", name = "hideHUD", description = "hideHUDDescription", default = config.default.ui.hideHUD},
        inputKey{key = "keyToToggleHUDVisibility", name = "toggleHUDKey", description = "toggleHUDKeyDescription", argType = "trigger", argKey = commonData.toggleHUDTriggerId, default = config.default.keyToToggleHUDVisibility},
        boolSetting{key = "ui.hideHUDInMenus", name = "hideHUDInMenus", description = "hideHUDInMenusDescription", default = config.default.ui.hideHUDInMenus},
        boolSetting{key = "ui.imperialUnits", name = "imperialUnits", default = config.default.ui.imperialUnits},
        boolSetting{key = "ui.helpTooltips", name = "helpTooltips", description = "helpTooltipsDescription", default = config.default.ui.helpTooltips},
        selectSetting{key = "ui.align", name = "align", description = "alignDescription", items = {"Start", "Center", "End"}, default = config.default.ui.align},
        selectSetting{key = "ui.orderH", name = "orderH", description = "orderHDescription", items = {"Left to right", "Right to left"}, default = config.default.ui.orderH},
        color{key = "ui.defaultColor", name = "defaultColor", description = "defaultColorDescription", default = config.default.ui.defaultColor},
        numberSetting{key = "ui.position.x", name = "positionX", description = "positionXDescription", min = 0, max = 100, default = config.default.ui.position.x},
        numberSetting{key = "ui.position.y", name = "positionY", min = 0, max = 100, default = config.default.ui.position.y},
    },
}