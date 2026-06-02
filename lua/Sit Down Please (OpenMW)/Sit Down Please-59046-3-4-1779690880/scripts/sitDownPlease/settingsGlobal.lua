local I = require("openmw.interfaces")
local profiles = require("scripts/sitDownPlease/profiles/catalog")

local defaults = profiles.DEFAULT_SETTINGS

local SAFE_DEFAULTS = {
    debug = false,
    verboseDebug = false,
    userNpcBlacklist = "",
    userFurnitureBlacklist = "",
    userCellBlacklist = "",
    enableSitting = true,
    enableSleeping = true,
    sittingInitialPlacementEnabled = true,
    sittingLifecycleEnabled = true,
    sittingLifecycleMinSeconds = 2700,
    sittingLifecycleMaxSeconds = 7200,
    sittingLifecycleMoveSeatChance = 0.25,
    sittingStandCooldownSeconds = 45,
    sittingBriefWanderEnabled = true,
    sittingBriefWanderChance = 0.025,
    sittingBriefWanderDistance = 35,
    sittingAllowServiceNpcs = true,
    sittingServiceNpcRadius = 200,
    allowFallbackSitting = true,
    allowFallbackBackedChairs = false,
    animatedMorrowindAlignmentAssist = true,
    maxSearchRadius = 700,
    transitionDistance = 100,
    lerpDuration = 1,
    sleepStartHour = 22,
    sleepForceInBedHour = 23.5,
    sleepEndHour = 8,
    sleepInitialPlacementEnabled = true,
    allowFallbackSleeping = false,
    disguiseInitialPlacement = true,
    sleepSmartDoorAssist = true,
    sleepAvoidObservedPlayer = true,
    sleepObservedPlayerCooldown = 120,
    sleepObservedPlayerDistance = 500,
    sleepObservedPlayerDispositionThreshold = 70,
    sleepObservedPlayerAllowanceChance = 0.25,
    sleepingWakeDistance = 120,
    sleepingSneakWakeDistance = 60,
    sdpOpenCalibrationMenuAction = 0,
    sdpCalibrationHotkeyEnabled = false,
    sdpCalibrationHotkey = "c",
    enableLightControl = true,
    lightControlRadius = 1200,
    lightControlAwakeNpcRadius = 1600,
    lightControlCandles = true,
    lightControlLanterns = true,
    lightControlTorches = true,
    lightControlFires = false,
    lightControlBatchSize = 4,
    lightControlPlayerWakeBedsideRestoreRadius = 350,
}

local function settingDefault(key)
    if defaults and defaults[key] ~= nil then return defaults[key] end
    return SAFE_DEFAULTS[key]
end

local function numberArg(min, max, integer)
    return { integer = integer == true, min = min, max = max }
end

local function setting(key, renderer, min, max, integer)
    local item = {
        key = key,
        name = key .. "_name",
        description = key .. "_description",
        default = settingDefault(key),
        renderer = renderer or "checkbox",
    }
    if renderer == "number" then item.argument = numberArg(min, max, integer) end
    return item
end


local function inputBindingSetting(key, triggerKey, defaultKey)
    return {
        key = key,
        name = key .. "_name",
        description = key .. "_description",
        default = settingDefault(key) or defaultKey or "",
        renderer = "inputBinding",
        argument = { type = "trigger", key = triggerKey },
    }
end


I.Settings.registerGroup {
    key = profiles.SETTINGS_SITTING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "sitting_group_name",
    description = "sitting_group_description",
    permanentStorage = true,
    order = 1,
    settings = {
        setting("enableSitting", "checkbox"),
        setting("sittingInitialPlacementEnabled", "checkbox"),
        setting("sittingLifecycleEnabled", "checkbox"),
        setting("sittingLifecycleMinSeconds", "number", 10, 7200, true),
        setting("sittingLifecycleMaxSeconds", "number", 20, 14400, true),
        setting("sittingLifecycleMoveSeatChance", "number", 0, 1, false),
        setting("sittingStandCooldownSeconds", "number", 0, 1800, true),
        setting("sittingBriefWanderEnabled", "checkbox"),
        setting("sittingBriefWanderChance", "number", 0, 1, false),
        setting("sittingBriefWanderDistance", "number", 0, 160, false),
        setting("sittingAllowServiceNpcs", "checkbox"),
        setting("sittingServiceNpcRadius", "number", 50, 500, false),
        setting("maxSearchRadius", "number", 100, 3000, false),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_SLEEPING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "sleeping_group_name",
    description = "sleeping_group_description",
    permanentStorage = true,
    order = 2,
    settings = {
        setting("enableSleeping", "checkbox"),
        setting("sleepStartHour", "number", 0, 23.99, false),
        setting("sleepForceInBedHour", "number", 0, 23.99, false),
        setting("sleepEndHour", "number", 0, 23.99, false),
        setting("sleepInitialPlacementEnabled", "checkbox"),
        setting("sleepAvoidObservedPlayer", "checkbox"),
        setting("sleepObservedPlayerCooldown", "number", 0, 600, false),
        setting("sleepObservedPlayerDistance", "number", 0, 3000, false),
        setting("sleepObservedPlayerDispositionThreshold", "number", 0, 100, false),
        setting("sleepObservedPlayerAllowanceChance", "number", 0, 1, false),
        setting("sleepingWakeDistance", "number", 0, 1000, false),
        setting("sleepingSneakWakeDistance", "number", 0, 1000, false),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_LIGHTING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "lighting_group_name",
    description = "lighting_group_description",
    permanentStorage = true,
    order = 3,
    settings = {
        setting("enableLightControl", "checkbox"),
        setting("lightControlRadius", "number", 100, 5000, false),
        setting("lightControlAwakeNpcRadius", "number", 100, 5000, false),
        setting("lightControlCandles", "checkbox"),
        setting("lightControlLanterns", "checkbox"),
        setting("lightControlTorches", "checkbox"),
        setting("lightControlFires", "checkbox"),
        setting("lightControlBatchSize", "number", 1, 32, true),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_COMPATIBILITY_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "compatibility_group_name",
    description = "compatibility_group_description",
    permanentStorage = true,
    order = 4,
    settings = {
        setting("allowFallbackSitting", "checkbox"),
        setting("allowFallbackBackedChairs", "checkbox"),
        setting("animatedMorrowindAlignmentAssist", "checkbox"),
        setting("allowFallbackSleeping", "checkbox"),
        setting("sleepSmartDoorAssist", "checkbox"),
        setting("disguiseInitialPlacement", "checkbox"),
        setting("transitionDistance", "number", 20, 500, false),
        setting("lerpDuration", "number", 0.1, 10, false),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_BLACKLIST_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "blacklist_group_name",
    description = "blacklist_group_description",
    permanentStorage = true,
    order = 5,
    settings = {
        setting("userNpcBlacklist", "textLine"),
        setting("userFurnitureBlacklist", "textLine"),
        setting("userCellBlacklist", "textLine"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_DIAGNOSTICS_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "diagnostics_group_name",
    description = "diagnostics_group_description",
    permanentStorage = true,
    order = 6,
    settings = {
        setting("debug", "checkbox"),
        setting("verboseDebug", "checkbox"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_ADVANCED_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "advanced_group_name",
    description = "advanced_group_description",
    permanentStorage = true,
    order = 7,
    settings = {
        setting("sdpCalibrationHotkeyEnabled", "checkbox"),
        inputBindingSetting("sdpCalibrationHotkey", "SitDownPleaseOpenCalibrationMenu", "c"),
    }
}
