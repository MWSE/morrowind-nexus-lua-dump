local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local config = require("scripts.fancy_door_randomizer.config")

local l10nName = "fancy_door_randomizer"

local randomizationModes = config.modes

---@class fdr.settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class fdr.settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class fdr.settings.textSetting
---@field name string l10n
---@field description string|nil l10n
---@field disabled boolean|nil

---@param args fdr.settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        trueLabel = args.trueLabel,
        falseLabel = args.falseLabel,
        disabled = args.disabled,
    }
end

---@param args fdr.settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        min = args.min,
        max = args.max,
        integer = args.integer,
        disabled = args.disabled,
    }
    return data
end

---@param args fdr.settings.textSetting
local function textSetting(args)
    return {
        renderer = "textLine",
        name = args.name,
        description = args.description,
        disabled = args.disabled,
    }
end

local function selectSetting(args)
    return {
        renderer = "fdrbd_select",
        key = args.key,
        name = args.name,
        description = args.description,
        items = args.items,
        l10n = args.l10n or l10nName,
        default = args.default or args.items[1],
        disabled = args.disabled or false,
    }
end

--#####################################################################

local storageName = config.storageName
I.Settings.registerPage({
    key = storageName,
    l10n = l10nName,
    name = "modName",
    description = "modDescription",
})

I.Settings.registerGroup({
    key = storageName,
    page = storageName,
    l10n = l10nName,
    name = "mainSettings",
    permanentStorage = false,
    order = 0,
    settings = {
        boolSetting({key = "enabled", name = "enabled", default = config.default.enabled}),
        numberSetting({key = "chance", name = "chance", default = config.default.chance}),
        selectSetting({key = "mode", name = "mode", items = randomizationModes, default = config.default.mode}),
        numberSetting({key = "radius", name = "radius", default = config.default.radius}),
        numberSetting({key = "interval", name = "interval", default = config.default.interval}),
        boolSetting({key = "saveOnFailure", name = "saveOnFailure", default = config.default.saveOnFailure}),
        boolSetting({key = "exitDoor", name = "exitDoor", default = config.default.exitDoor}),
        boolSetting({key = "allowLockedExit", name = "allowLockedExit", default = config.default.allowLockedExit}),
        boolSetting({key = "unlockLockedExit", name = "unlockLockedExit", default = config.default.unlockLockedExit}),
        boolSetting({key = "untrapExit", name = "untrapExit", default = config.default.untrapExit}),
    },
})

I.Settings.registerGroup({
    key = storageName.."_inToEx",
    page = storageName,
    l10n = l10nName,
    name = "inToEx",
    permanentStorage = false,
    order = 1,
    settings = {
        boolSetting({key = "inToEx.toInToEx", name = "toInToEx", default = config.default.inToEx.toInToEx}),
        boolSetting({key = "inToEx.toInToIn", name = "toInToIn", default = config.default.inToEx.toInToIn}),
        boolSetting({key = "inToEx.toExToEx", name = "toExToEx", default = config.default.inToEx.toExToEx}),
        boolSetting({key = "inToEx.toExToIn", name = "toExToIn", default = config.default.inToEx.toExToIn}),
    },
})

I.Settings.registerGroup({
    key = storageName.."_inToIn",
    page = storageName,
    l10n = l10nName,
    name = "inToIn",
    permanentStorage = false,
    order = 2,
    settings = {
        boolSetting({key = "inToIn.toInToEx", name = "toInToEx", default = config.default.inToIn.toInToEx}),
        boolSetting({key = "inToIn.toInToIn", name = "toInToIn", default = config.default.inToIn.toInToIn}),
        boolSetting({key = "inToIn.toExToEx", name = "toExToEx", default = config.default.inToIn.toExToEx}),
        boolSetting({key = "inToIn.toExToIn", name = "toExToIn", default = config.default.inToIn.toExToIn}),
    },
})

I.Settings.registerGroup({
    key = storageName.."_exToEx",
    page = storageName,
    l10n = l10nName,
    name = "exToEx",
    permanentStorage = false,
    order = 3,
    settings = {
        boolSetting({key = "exToEx.toInToEx", name = "toInToEx", default = config.default.exToEx.toInToEx}),
        boolSetting({key = "exToEx.toInToIn", name = "toInToIn", default = config.default.exToEx.toInToIn}),
        boolSetting({key = "exToEx.toExToEx", name = "toExToEx", default = config.default.exToEx.toExToEx}),
        boolSetting({key = "exToEx.toExToIn", name = "toExToIn", default = config.default.exToEx.toExToIn}),
    },
})

I.Settings.registerGroup({
    key = storageName.."_exToIn",
    page = storageName,
    l10n = l10nName,
    name = "exToIn",
    permanentStorage = false,
    order = 4,
    settings = {
        boolSetting({key = "exToIn.toInToEx", name = "toInToEx", default = config.default.exToIn.toInToEx}),
        boolSetting({key = "exToIn.toInToIn", name = "toInToIn", default = config.default.exToIn.toInToIn}),
        boolSetting({key = "exToIn.toExToEx", name = "toExToEx", default = config.default.exToIn.toExToEx}),
        boolSetting({key = "exToIn.toExToIn", name = "toExToIn", default = config.default.exToIn.toExToIn}),
    },
})

I.Settings.updateRendererArgument(storageName, "chance", {min = 0, max = 100})
I.Settings.updateRendererArgument(storageName, "interval", {min = 0, max = 999999999, integer = true})
I.Settings.updateRendererArgument(storageName, "radius", {min = 1, max = 100, integer = true})

local mainStorage = storage.playerSection(storageName)

local function updateConfig()
    config.loadPlayerSettings(storage.playerSection(storageName):asTable())
    config.loadPlayerSettings(storage.playerSection(storageName.."_inToEx"):asTable())
    config.loadPlayerSettings(storage.playerSection(storageName.."_inToIn"):asTable())
    config.loadPlayerSettings(storage.playerSection(storageName.."_exToEx"):asTable())
    config.loadPlayerSettings(storage.playerSection(storageName.."_exToIn"):asTable())
    core.sendGlobalEvent("fdrbd_loadConfigData", config.data)
end

local function updateMainSettings()
    local mode = mainStorage:get("mode")
    I.Settings.updateRendererArgument(storageName, "radius", {disabled = mode ~= "nearestMode", min = 1, max = 100, integer = true})
    local exitDoor = mainStorage:get("exitDoor")
    I.Settings.updateRendererArgument(storageName, "allowLockedExit", {disabled = not exitDoor})
    I.Settings.updateRendererArgument(storageName, "unlockLockedExit", {disabled = not exitDoor})
    updateConfig()
end

updateMainSettings()

mainStorage:subscribe(async:callback(updateMainSettings))
storage.playerSection(storageName.."_inToEx"):subscribe(async:callback(updateConfig))
storage.playerSection(storageName.."_inToIn"):subscribe(async:callback(updateConfig))
storage.playerSection(storageName.."_exToEx"):subscribe(async:callback(updateConfig))
storage.playerSection(storageName.."_exToIn"):subscribe(async:callback(updateConfig))