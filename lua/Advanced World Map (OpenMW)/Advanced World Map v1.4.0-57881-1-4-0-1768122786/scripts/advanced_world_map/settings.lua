local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local storage = require('openmw.storage')

local config = require("scripts.advanced_world_map.config.config")
local commonData = require("scripts.advanced_world_map.common")

I.Settings.registerPage{
  key = commonData.settingPage,
  l10n = commonData.l10nKey,
  name = "modName",
  description = "modDescription",
}

---@class questGuider.settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class questGuider.settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class questGuider.settings.label
---@field description string|nil l10n
---@field disabled boolean|nil

---@class questGuider.settings.text
---@field text string|nil
---@field disabled boolean|nil

---@class questGuider.settings.selectSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default string|nil
---@field l10n string|nil
---@field items string[]
---@field disabled boolean|nil


---@param args questGuider.settings.boolSetting
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

---@param args questGuider.settings.numberSetting
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
        renderer = "DijectKeyBindings:inputBinding",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            action = args.action
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

---@param args questGuider.settings.selectSetting
local function selectSetting(args)
    return {
        key = args.key,
        renderer = "select",
        name = args.name,
        description = args.description,
        default = args.default or "",
        argument = {
            l10n = args.l10n,
            items = args.items,
            disabled = args.disabled,
        }
    }
end



local sections = storage:allPlayerSections()
if sections and not sections[commonData.configMainSectionName] and I.DijectKeyBindings then
    I.DijectKeyBindings.registerKey(commonData.menuKeyId, config.default.main.menuKey)
end




I.Settings.registerGroup{
    key = commonData.configMainSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "MainSettings",
    permanentStorage = true,
    order = 0,
    settings = {
        inputKey{key = "main.menuKey", name = "SettingMainMenuKey", description = "SettingMainMenuKeyDescription", action = commonData.menuKeyId, default = config.default.main.menuKey},
        numberSetting{key = "main.updateFrequency", name = "SettingUpdateFrequency", description = "SettingUpdateFrequencyDescription", default = config.default.main.updateFrequency, min = 1},
        numberSetting{key = "main.discoveryRadius", name = "SettingDiscoveryRadius", description = "SettingDiscoveryRadiusDescription", default = config.default.main.discoveryRadius, min = 500, max = 10000, integer = true},
        -- boolSetting{key = "main.fastClose", name = "SettingFastClose", description = "SettingFastCloseDescription", default = config.default.main.fastClose},
        boolSetting{key = "main.overrideDefault", name = "SettingOverrideDefaultMap", description = "SettingOverrideDefaultMapDescription", default = config.default.main.overrideDefault},
        boolSetting{key = "main.saveVisibilityStateInInterfaceMenu", name = "SettingSaveVisibilityStateInInterfaceMenu", description = "SettingSaveVisibilityStateInInterfaceMenuDescription", default = config.default.main.saveVisibilityStateInInterfaceMenu},
        boolSetting{key = "main.firstInitMenu", name = "SettingFirstInitMenu", description = "SettingFirstInitMenuDescription", default = config.default.main.firstInitMenu},
    },
}


I.Settings.registerGroup{
    key = commonData.configDataSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "DataSettings",
    permanentStorage = true,
    order = 1,
    settings = {
        selectSetting{key = "data.initializer", name = "SettingDataInitializer", description = "SettingDataInitializerDescription", default = config.default.data.initializer, l10n = commonData.l10nKey, items = commonData.dataInitializerTypes},
    },
}


I.Settings.registerGroup{
    key = commonData.configTilesetSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "TilesetSettings",
    description = "TilesetSettingsDescription",
    permanentStorage = true,
    order = 2,
    settings = {
        boolSetting{key = "tileset.onlyDiscovered", name = "SettingTilesetOnlyDiscovered", description = "SettingTilesetOnlyDiscoveredDescription", default = config.default.tileset.onlyDiscovered},
        numberSetting{key = "tileset.zoomToShow", name = "SettingTilesetZoomToShow", description = "SettingTilesetZoomToShowDescription", default = config.default.tileset.zoomToShow, min = 1, max = 12, integer = true},
    },
}


I.Settings.registerGroup{
    key = commonData.configLegendSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "LegendSettings",
    description = "LegendSettingsDescription",
    permanentStorage = true,
    order = 3,
    settings = {
        boolSetting{key = "legend.onlyDiscovered", name = "SettingLegendOnlyDiscovered", description = "SettingLegendOnlyDiscoveredDescription", default = config.default.legend.onlyDiscovered},
        boolSetting{key = "legend.visitedCellsOnWorldMap", name = "SettingLegendVisitedCellsOnWorldMap", description = "SettingLegendVisitedCellsOnWorldMapDescription", default = config.default.legend.visitedCellsOnWorldMap},
        numberSetting{key = "legend.markerSize", name = "SettingLegendMarkerSize", description = "SettingLegendMarkerSizeDescription", default = config.default.legend.markerSize, min = 1, max = 20},
        numberSetting{key = "legend.alpha.region", name = "SettingLegendRegionAlpha", description = "SettingLegendRegionAlphaDescription", default = config.default.legend.alpha.region, min = 0, max = 100},
        numberSetting{key = "legend.alpha.city", name = "SettingLegendCityAlpha", description = "SettingLegendCityAlphaDescription", default = config.default.legend.alpha.city, min = 0, max = 100},
        numberSetting{key = "legend.alpha.entrance", name = "SettingLegendEntranceAlpha", description = "SettingLegendEntranceAlphaDescription", default = config.default.legend.alpha.entrance, min = 0, max = 100},
    },
}


I.Settings.registerGroup{
    key = commonData.configNotesSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "NotesSettings",
    permanentStorage = true,
    order = 4,
    settings = {
        numberSetting{key = "notes.mapFontSize", name = "SettingNotesMapFontSize", description = "SettingNotesMapFontSizeDescription", default = config.default.notes.mapFontSize, min = 4, max = 48, integer = true},
    },
}


I.Settings.registerGroup{
    key = commonData.configFastTravelSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "FastTravelSettings",
    permanentStorage = true,
    order = 5,
    settings = {
        boolSetting{key = "fastTravel.enabled", name = "SettingFastTravelEnabled", description = "SettingFastTravelEnabledDescription", default = config.default.fastTravel.enabled},
        boolSetting{key = "fastTravel.onlyDiscovered", name = "SettingFastTravelOnlyDiscovered", description = "SettingFastTravelOnlyDiscoveredDescription", default = config.default.fastTravel.onlyDiscovered},
        boolSetting{key = "fastTravel.onlyReachable", name = "SettingFastTravelOnlyReachable", description = "SettingFastTravelOnlyReachableDescription", default = config.default.fastTravel.onlyReachable},
        boolSetting{key = "fastTravel.withFollowers", name = "SettingFastTravelWithFollowers", description = "SettingFastTravelWithFollowersDescription", default = config.default.fastTravel.withFollowers},
        boolSetting{key = "fastTravel.allowToInterior", name = "SettingFastTravelAllowToInterior", description = "SettingFastTravelAllowToInteriorDescription", default = config.default.fastTravel.allowToInterior},
        numberSetting{key = "fastTravel.cooldown", name = "SettingFastTravelCooldown", description = "SettingFastTravelCooldownDescription", default = config.default.fastTravel.cooldown, min = 0},
        numberSetting{key = "fastTravel.baseMagickaCost", name = "SettingFastTravelBaseMagickaCost", description = "SettingFastTravelBaseMagickaCostDescription", default = config.default.fastTravel.baseMagickaCost, min = 0},
        numberSetting{key = "fastTravel.additionalCost", name = "SettingFastTravelAdditionalCost", description = "SettingFastTravelAdditionalCostDescription", default = config.default.fastTravel.additionalCost, min = 0},
    },
}


I.Settings.registerGroup{
    key = commonData.configInputSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "InputSettings",
    permanentStorage = true,
    order = 6,
    settings = {
        boolSetting{key = "input.gamepadControls", name = "SettingInputGamepadControls", description = "SettingInputGamepadControlsDescription", default = config.default.input.gamepadControls},
        boolSetting{key = "input.gamepadControlsBumperMode", name = "SettingInputGamepadControlsBumperMode", description = "SettingInputGamepadControlsBumperModeDescription", default = config.default.input.gamepadControlsBumperMode},
        inputKey{key = "input.toggleMapTypeHotkey", name = "SettingInputToggleMapTypeKey", description = "SettingInputToggleMapTypeKeyDescription", action = commonData.toggleMapTypeKeyId, default = config.default.input.toggleMapTypeHotkey},
        inputKey{key = "input.togglePinHotkey", name = "SettingInputTogglePinKey", description = "SettingInputTogglePinKeyDescription", action = commonData.togglePinKeyId, default = config.default.input.togglePinHotkey},
    }
}


I.Settings.registerGroup{
    key = commonData.configUISectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "UISettings",
    permanentStorage = true,
    order = 7,
    settings = {
        numberSetting{key = "ui.fontSize", name = "SettingUIFontSize", description = "SettingUIFontSizeDescription", default = config.default.ui.fontSize, min = 8, max = 48, integer = true},
        numberSetting{key = "ui.resizerSize", name = "SettingUIResizerSize", description = "SettingUIResizerSizeDescription", default = config.default.ui.resizerSize, min = 1, max = 100, integer = true},
        numberSetting{key = "ui.scrollArrowSize", name = "SettingUIScrollBarSize", description = "SettingUIScrollBarSizeDescription", default = config.default.ui.scrollArrowSize, min = 1, max = 100, integer = true},
        numberSetting{key = "ui.mouseScrollAmount", name = "SettingUIMouseScrollAmount", description = "SettingUIMouseScrollAmountDescription", default = config.default.ui.mouseScrollAmount, min = 1, max = 500, integer = true},
        color{key = "ui.defaultColor", name = "SettingUIDefaultColor", description = "SettingUIDefaultColorDescription", default = config.default.ui.defaultColor},
        color{key = "ui.whiteColor", name = "SettingUIWhiteColor", description = "SettingUIWhiteColorDescription", default = config.default.ui.whiteColor},
        color{key = "ui.backgroundColor", name = "SettingUIBackgroundColor", description = "SettingUIBackgroundColorDescription", default = config.default.ui.backgroundColor},
        color{key = "ui.markerDefaultColor", name = "SettingUIMarkerDefaultColor", description = "SettingUIMarkerDefaultColorDescription", default = config.default.ui.markerDefaultColor},
        color{key = "ui.defaultDarkColor", name = "SettingUIDefaultDarkColor", description = "SettingUIDefaultDarkColorDescription", default = config.default.ui.defaultDarkColor},
        color{key = "ui.defaultLightColor", name = "SettingUIDefaultLightColor", description = "SettingUIDefaultLightColorDescription", default = config.default.ui.defaultLightColor},
        color{key = "ui.foundMarkerColor", name = "SettingUIFoundMarkerColor", description = "SettingUIFoundMarkerColorDescription", default = config.default.ui.foundMarkerColor},
        color{key = "ui.foundMarkerLightColor", name = "SettingUIFoundMarkerLightColor", description = "SettingUIFoundMarkerLightColorDescription", default = config.default.ui.foundMarkerLightColor},
        color{key = "ui.textShadowColor", name = "SettingUITextShadowColor", description = "SettingUITextShadowColorDescription", default = config.default.ui.textShadowColor},
        color{key = "ui.defaultTextureColor", name = "SettingUIDefaultTextureColor", description = "SettingUIDefaultTextureColorDescription", default = config.default.ui.defaultTextureColor},
    },
}