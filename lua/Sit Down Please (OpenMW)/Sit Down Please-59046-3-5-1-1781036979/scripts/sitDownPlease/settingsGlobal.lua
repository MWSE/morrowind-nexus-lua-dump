---@omw-context global
local I = require("openmw.interfaces")
local profiles = require("scripts/sitDownPlease/profiles/catalog")

local defaults = profiles.DEFAULT_SETTINGS

local SAFE_DEFAULTS = {
    logLevel = "off",
    debug = false,
    verboseDebug = false,
    userNpcBlacklist = "",
    userFurnitureBlacklist = "",
    userCellBlacklist = "",
    verifiedLocationsOnly = true,
    enableSitting = true,
    enableSleeping = true,
    sittingInitialPlacementEnabled = true,
    sittingLifecycleEnabled = true,
    sittingStandCooldownSeconds = 45,
    sittingBriefWanderEnabled = false,
    sittingBriefWanderChance = 0.025,
    sittingBriefWanderDistance = 35,
    sittingAllowServiceNpcs = true,
    sittingServiceNpcRadius = 450,
    serviceNpcOffHoursEnabled = true,
    serviceNpcOffHoursIncludePublicans = true,
    serviceNpcOffHoursIncludeTraders = true,
    serviceNpcOffHoursIncludeTrainers = true,
    serviceNpcOffHoursIncludeFactionLeaders = true,
    serviceNpcOffHoursSittingChance = 0.45,
    serviceNpcOffHoursPublicanSittingChance = 0.20,
    serviceNpcOffHoursStartHour = 20,
    serviceNpcOffHoursEndHour = 8,
    serviceNpcOffHoursSittingRadius = 650,
    serviceNpcOffHoursSleepRadius = 1200,
    stationLecternEnabled = true,
    stationLecternPresenterChance = 0.50,
    stationLecternAudienceChance = 0.70,
    stationLecternMinHours = 0.5,
    stationLecternMaxHours = 3,
    allowFallbackSitting = true,
    allowFallbackBackedChairs = true,
    animatedMorrowindAlignmentAssist = false,
    maxSearchRadius = 700,
    transitionDistance = 100,
    lerpDuration = 1,
    sleepStartHour = 20,
    sleepForceInBedHour = 23.5,
    sleepEndHour = 8,
    sleepInitialPlacementEnabled = true,
    allowFallbackSleeping = true,
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

local function selectSetting(key, items)
    return {
        key = key,
        name = key .. "_name",
        description = key .. "_description",
        default = settingDefault(key),
        renderer = "select",
        argument = { l10n = profiles.L10N, items = items },
    }
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
    key = profiles.SETTINGS_BLACKLIST_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "blacklist_group_name",
    description = "blacklist_group_description",
    permanentStorage = true,
    order = 1,
    settings = {
        setting("userNpcBlacklist", "textLine"),
        setting("userFurnitureBlacklist", "textLine"),
        setting("userCellBlacklist", "textLine"),
        setting("verifiedLocationsOnly", "checkbox"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_SITTING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "sitting_group_name",
    description = "sitting_group_description",
    permanentStorage = true,
    order = 2,
    settings = {
        setting("enableSitting", "checkbox"),
        setting("sittingInitialPlacementEnabled", "checkbox"),
        setting("sittingLifecycleEnabled", "checkbox"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_SLEEPING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "sleeping_group_name",
    description = "sleeping_group_description",
    permanentStorage = true,
    order = 3,
    settings = {
        setting("enableSleeping", "checkbox"),
        setting("sleepInitialPlacementEnabled", "checkbox"),
        setting("sleepStartHour", "number", 0, 23.99, false),
        setting("sleepForceInBedHour", "number", 0, 23.99, false),
        setting("sleepEndHour", "number", 0, 23.99, false),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_LIGHTING_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "lighting_group_name",
    description = "lighting_group_description",
    permanentStorage = true,
    order = 4,
    settings = {
        setting("enableLightControl", "checkbox"),
        setting("lightControlRadius", "number", 100, 5000, false),
        setting("lightControlCandles", "checkbox"),
        setting("lightControlLanterns", "checkbox"),
        setting("lightControlTorches", "checkbox"),
        setting("lightControlFires", "checkbox"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_SERVICE_ROLES_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "service_roles_group_name",
    description = "service_roles_group_description",
    permanentStorage = true,
    order = 5,
    settings = {
        setting("sittingAllowServiceNpcs", "checkbox"),
        setting("serviceNpcOffHoursEnabled", "checkbox"),
        setting("serviceNpcOffHoursStartHour", "number", 0, 23.99, false),
        setting("serviceNpcOffHoursEndHour", "number", 0, 23.99, false),
        setting("serviceNpcOffHoursIncludePublicans", "checkbox"),
        setting("serviceNpcOffHoursIncludeTraders", "checkbox"),
        setting("serviceNpcOffHoursIncludeTrainers", "checkbox"),
        setting("serviceNpcOffHoursIncludeFactionLeaders", "checkbox"),
    }
}

I.Settings.registerGroup {
    key = profiles.SETTINGS_STATIONS_GROUP,
    page = profiles.SETTINGS_PAGE,
    l10n = profiles.L10N,
    name = "stations_group_name",
    description = "stations_group_description",
    permanentStorage = true,
    order = 6,
    settings = {
        setting("stationLecternEnabled", "checkbox"),
        setting("stationLecternPresenterChance", "number", 0, 1, false),
        setting("stationLecternAudienceChance", "number", 0, 1, false),
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
        selectSetting("logLevel", { "off", "trace", "verbose" }),
        setting("disguiseInitialPlacement", "checkbox"),
        setting("animatedMorrowindAlignmentAssist", "checkbox"),
        setting("sdpCalibrationHotkeyEnabled", "checkbox"),
        inputBindingSetting("sdpCalibrationHotkey", "SitDownPleaseOpenCalibrationMenu", "c"),
    }
}
