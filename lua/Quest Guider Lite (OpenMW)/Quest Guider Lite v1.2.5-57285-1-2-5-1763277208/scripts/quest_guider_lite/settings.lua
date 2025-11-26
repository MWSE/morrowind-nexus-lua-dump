local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local storage = require('openmw.storage')

local config = require("scripts.quest_guider_lite.config")
local commonData = require("scripts.quest_guider_lite.common")

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

---@class questGuider.settings.checkBoxes
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field checkBoxes UI.renderer.checkBoxesRenderer.checkBoxes[]

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

---@param args questGuider.settings.checkBoxes
local function checkBoxes(args)
    return {
        key = args.key,
        renderer = "AdvWMap:checkboxes",
        name = args.name,
        description = args.description,
        default = args.default or {},
        ---@type UI.renderer.yesNoWithCheckbox.params
        argument = {
            checkBoxes = args.checkBoxes,
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

local lableId = 0
---@param args questGuider.settings.label
local function textLabel(args)
    local data = {
        renderer = "QGL:Renderer:label",
        key = "__dummy__"..tostring(lableId),
        name = "empty",
        description = args.description,
        disabled = args.disabled,
    }
    lableId = lableId + 1
    return data
end

local function text(args)
    local data = {
        renderer = "QGL:Renderer:text",
        key = "__dummy__"..tostring(lableId),
        name = "empty",
        description = args.description,
        disabled = args.disabled,
        text = args.text,
    }
    lableId = lableId + 1
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


input.registerTrigger {
    key = commonData.journalMenuTriggerId,
    l10n = commonData.l10nKey,
}

-- f this
local res, err = pcall(function()
    local bindingSection = storage.playerSection('OMWInputBindings')
    if bindingSection:get(config.default.journal.menuKey) == nil then
        bindingSection:set(config.default.journal.menuKey, {
            device = "keyboard",
            button = input.KEY[config.default.journal.menuKey],
            type = "trigger",
            key = commonData.journalMenuTriggerId,
        })
    end
end)
if not res then
    print(err)
end


input.registerTrigger {
    key = commonData.toggleMarkersTriggerId,
    l10n = commonData.l10nKey,
}


I.Settings.registerGroup{
    key = commonData.configJournalSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "journal",
    permanentStorage = true,
    order = 0,
    settings = {
        inputKey{key = "journal.menuKey", name = "customJournalKeyName", description = "customJournalKeyDescription", argType = "trigger", argKey = commonData.journalMenuTriggerId, default = config.default.journal.menuKey},
        boolSetting{key = "journal.overrideJournal", name = "overrideJournal", description = "overrideJournalDescription", default = config.default.journal.overrideJournal},
        numberSetting{key = "journal.widthProportional", name = "width", description = "widthDescription", integer = true, min = 30, max = 100, default = config.default.journal.widthProportional},
        numberSetting{key = "journal.heightProportional", name = "height", description = "heightDescription", integer = true, min = 20, max = 100, default = config.default.journal.heightProportional},
        numberSetting{key = "journal.position.x", name = "positionX", description = "journalWindowPositionNote", integer = false, min = 0, max = 100, default = config.default.journal.position.x},
        numberSetting{key = "journal.position.y", name = "positionY", description = "journalWindowPositionNote", integer = false, min = 0, max = 100, default = config.default.journal.position.y},
        numberSetting{key = "journal.listRelativeSize", name = "questListRelativeSize", description = "questListRelativeSizeDescription", integer = false, min = 5, max = 50, default = config.default.journal.listRelativeSize},
        boolSetting{key = "journal.trackedColorMarks", name = "colorFlags", description = "colorFlagsDescription", default = config.default.journal.trackedColorMarks},
        boolSetting{key = "journal.ssqnIcons", name = "ssqnIcons", description = "ssqnIconsDescription", default = config.default.journal.ssqnIcons},
        numberSetting{key = "journal.maxTopicEntriesInTopicMenu", name = "maxTopicEntriesPerLoadInTopicMenu", description = "maxTopicEntriesPerLoadInTopicMenuDescription", integer = true, min = 1, default = config.default.journal.maxTopicEntriesInTopicMenu},
        numberSetting{key = "journal.maxTopicEntriesInJournal", name = "maxTopicEntriesInJournal", description = "maxTopicEntriesInJournalDescription", integer = true, min = 0, default = config.default.journal.maxTopicEntriesInJournal},
        numberSetting{key = "journal.mouseScrollAmount", name = "mouseScrollAmount", description = "mouseScrollAmountDescription", integer = true, min = 1, max = 200, default = config.default.journal.mouseScrollAmount},
        numberSetting{key = "journal.textHeightMulRecord", name = "textHeightMul", description = "textHeightMulDescription", integer = false, min = 0.1, max = 2, default = config.default.journal.textHeightMulRecord},
        boolSetting{key = "journal.mapByDefault", name = "mapByDefault", description = "mapByDefaultDescription", default = config.default.journal.mapByDefault},
    },
}


I.Settings.registerGroup{
    key = commonData.configTrackingSectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "tracking",
    permanentStorage = true,
    order = 1,
    settings = {
        boolSetting{key = "tracking.autoTrack", name = "autoTrack", description = "autoTrackDescription", default = config.default.tracking.autoTrack},
        boolSetting{key = "tracking.autoTrackSideBranches", name = "autoTrackSideBranches", description = "autoTrackSideBranchesDescription", default = config.default.tracking.autoTrackSideBranches},
        boolSetting{key = "tracking.autoTrackOneEntryDialogues", name = "autoTrackOneEntryDialogues", description = "autoTrackOneEntryDialoguesDescription", default = config.default.tracking.autoTrackOneEntryDialogues},
        boolSetting{key = "tracking.trackDisabled", name = "trackDisabled", description = "trackDisabledDescription", default = config.default.tracking.trackDisabled},
        boolSetting{key = "tracking.questGivers", name = "questGivers", description = "questGiversDescription", default = config.default.tracking.questGivers},
        numberSetting{key = "tracking.minChance", name = "minDropchance", description = "minDropchanceDescription", integer = false, min = 0, max = 100, default = config.default.tracking.minChance},
        numberSetting{key = "tracking.maxPos", name = "maxPositionNumberToNotTrackEntrances", description = "maxPositionNumberToNotTrackEntrancesDescription", integer = true, min = 0, default = config.default.tracking.maxPos},
        boolSetting{key = "tracking.colored", name = "useColoredMarkers", description = "useColoredMarkersDescription", default = config.default.tracking.colored},
        boolSetting{key = "tracking.proximityMarkers.enabled", name = "proximityToolMarkersEnabled", description = "proximityToolMarkersEnabledDescription", default = config.default.tracking.proximityMarkers.enabled},
        checkBoxes{key = "tracking.proximityMarkers.details", name = "empty", description = "useForProximityToolDescription", default = config.default.tracking.proximityMarkers.details,
            checkBoxes = {
                {key = "givers", name = "questGiversLabel", default = config.default.tracking.hudMarkers.details.givers},
                {key = "markers", name = "questObjectsLabel", default = config.default.tracking.hudMarkers.details.markers},
            }
        },
        numberSetting{key = "tracking.proximity", name = "markerActivationDistance", description = "markerActivationDistanceDescription", integer = true, min = 0, default = config.default.tracking.proximity},
        numberSetting{key = "tracking.questGiverProximity", name = "questGiverMarkerActivationDistance", description = "questGiverMarkerActivationDistanceDescription", integer = true, min = 0, default = config.default.tracking.questGiverProximity},
        boolSetting{key = "tracking.hudMarkers.enabled", name = "hudMarkersEnabled", description = "hudMarkersEnabledDescription", default = config.default.tracking.hudMarkers.enabled},
        checkBoxes{key = "tracking.hudMarkers.details", name = "empty", description = "useForHUDMarkersDescription", default = config.default.tracking.hudMarkers.details,
            checkBoxes = {
                {key = "givers", name = "questGiversLabel", default = config.default.tracking.hudMarkers.details.givers},
                {key = "markers", name = "questObjectsLabel", default = config.default.tracking.hudMarkers.details.markers},
            }
        },
        numberSetting{key = "tracking.hudMarkers.range", name = "hudMarkersRange", description = "hudMarkersRangeDescription", integer = false, min = 0, default = config.default.tracking.hudMarkers.range},
        boolSetting{key = "tracking.hudMarkers.rayTracing", name = "hudMarkersRayTracing", description = "hudMarkersRayTracingDescription", default = config.default.tracking.hudMarkers.rayTracing},
        numberSetting{key = "tracking.hudMarkers.opacity", name = "hudMarkersOpacity", description = "hudMarkersOpacityDescription", integer = false, min = 0, max = 100, default = config.default.tracking.hudMarkers.opacity},
        inputKey{key = "tracking.toggleVisibilityKey", name = "markerVisibilityKey", description = "markerVisibilityKeyDescription", argType = "trigger", argKey = commonData.toggleMarkersTriggerId, default = config.default.tracking.toggleVisibilityKey},
        boolSetting{key = "tracking.toggleVisibilityByJournalKey", name = "enableShiftJournalMarkersToggle", description = "enableShiftJournalMarkersToggleDescription", default = config.default.tracking.toggleVisibilityByJournalKey},
    },
}


I.Settings.registerGroup{
    key = commonData.configUISectionName,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "UI",
    permanentStorage = true,
    order = 2,
    settings = {
        numberSetting{key = "ui.fontSize", name = "fontSize", integer = true, min = 12, max = 72, default = config.default.ui.fontSize},
        color{key = "ui.defaultColor", name = "textColor", description = "textColorSettingDescription", default = config.default.ui.defaultColor},
        color{key = "ui.backgroundColor", name = "backgroudColor", description = "backgroudColorDescription", default = config.default.ui.backgroundColor},
        color{key = "ui.disabledColor", name = "disabledColor", description = "disabledColorDescription", default = config.default.ui.disabledColor},
        color{key = "ui.dateColor", name = "dateColor", description = "dateColorDescription", default = config.default.ui.dateColor},
        color{key = "ui.selectionColor", name = "selectionColor", description = "selectionColorDescription", default = config.default.ui.selectionColor},
        color{key = "ui.objectColor", name = "objectColor", description = "objectColorDescription", default = config.default.ui.objectColor},
        color{key = "ui.linkColor", name = "linkColor", description = "linkColorDescription", default = config.default.ui.linkColor},
        color{key = "ui.shadowColor", name = "shadowColor", description = "shadowColorDescription", default = config.default.ui.shadowColor},
        numberSetting{key = "ui.scrollArrowSize", name = "scrollButtonSize", description = "scrollButtonSizeDescription", integer = true, min = 12, max = 60, default = config.default.ui.scrollArrowSize},
        numberSetting{key = "ui.headerBackgroundAlpha", name = "headerBackgroundAlpha", description = "headerBackgroundAlphaDescription", min = 0, max = 100, default = config.default.ui.headerBackgroundAlpha},
    },
}