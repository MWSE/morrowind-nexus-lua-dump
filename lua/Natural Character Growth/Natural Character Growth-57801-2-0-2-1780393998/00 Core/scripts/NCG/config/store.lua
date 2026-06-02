local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require('openmw.async')

local mDef = require("scripts.NCG.config.definition")
local mHelpers = require("scripts.NCG.util.helpers")

local storeTypes = { Global = 0, Player = 1 }
local trackerCallbacks = {}

local module = {
    sections = {
        main = { type = storeTypes.Player, name = "Main", order = 0, description = false },
        debug = { type = storeTypes.Global, name = "Debug", order = 1, description = false },
        attributes = { type = storeTypes.Player, name = "Attributes", order = 2 },
        health = { type = storeTypes.Player, name = "Health", order = 3 },
    },
    enums = {
        startAttrRatios = { None = 0, Quarter = 1 / 4, Half = 1 / 2, ThreeQuarters = 3 / 4, Full = 1 },
        attrGrowths = { Slower = 1, Slow = 2, Standard = 3, Fast = 4, Faster = 5 },
        luckGrowths = { None = 0, Low = 1 / 4, Med = 1 / 2, High = 1 },
        baseHpFactors = { HP25 = 0.25, HP50 = 0.5, HP75 = 0.75, HP100 = 1, HP125 = 1.25, HP150 = 1.5, HP175 = 1.75, HP200 = 2 },
        perLevelHpFactors = { None = 0, Low = 0.02, Med = 0.04, High = 0.08 },
    },
}

local availableSections = {}
-- only include sections available to the current script type
for key, section in pairs(module.sections) do
    if section.type == storeTypes.Global or I.Controls and section.type == storeTypes.Player then
        availableSections[key] = section
    end
end
module.sections = availableSections
local sections = module.sections

module.settings = {
    -- MAIN
    classSkillPointsPerLevelUp = {
        order = 0,
        section = sections.main,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 100 },
        default = 10,
    },
    messagesLogKey = {
        order = 1,
        section = sections.main,
        renderer = "inputBinding",
        argument = { key = mDef.actions.showLogs, type = "action" },
        default = mDef.inputKeys.defaultLogsKey,
    },
    -- DEBUG
    disableGrowth = {
        order = 0,
        section = sections.debug,
        renderer = "checkbox",
        default = false,
    },
    debugMode = {
        order = 1,
        section = sections.debug,
        description = false,
        renderer = "checkbox",
        default = false,
    },
    -- ATTRIBUTES
    startAttrRatio = {
        order = 0,
        section = sections.attributes,
        renderer = "select",
        enum = module.enums.startAttrRatios,
        default = module.enums.startAttrRatios.Half,
    },
    attrGrowthRate = {
        order = 1,
        section = sections.attributes,
        renderer = "select",
        enum = module.enums.attrGrowths,
        default = module.enums.attrGrowths.Slow,
    },
    luckGrowthRate = {
        order = 2,
        section = sections.attributes,
        renderer = "select",
        enum = module.enums.luckGrowths,
        default = module.enums.luckGrowths.Low,
    },
    growthFactorFromMajorSkills = {
        order = 3,
        section = sections.attributes,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000 },
        default = 100,
    },
    growthFactorFromMinorSkills = {
        order = 4,
        section = sections.attributes,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000 },
        default = 100,
    },
    growthFactorFromMiscSkills = {
        order = 5,
        section = sections.attributes,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000 },
        default = 50,
    },
    growthFactorFromCustomSkills = {
        order = 6,
        section = sections.attributes,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000 },
        default = 50,
    },
    attributeUncapper = {
        order = 7,
        section = sections.attributes,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 9999 },
        default = 0,
    },
    perAttributeUncapper = {
        order = 8,
        section = sections.attributes,
        renderer = mDef.renderers.perAttributeUncapper,
        argument = { integer = true, min = 0, max = 9999 },
        default = {},
    },
    showAttributeChangeNotifications = {
        order = 9,
        section = sections.attributes,
        renderer = "checkbox",
        default = true,
    },
    showAttributeValueDetails = {
        order = 10,
        section = sections.attributes,
        renderer = "checkbox",
        default = false,
    },
    -- HEALTH
    stateBasedHp = {
        order = 0,
        section = sections.health,
        renderer = "checkbox",
        default = false,
    },
    baseHpFactor = {
        order = 1,
        section = sections.health,
        renderer = "select",
        enum = module.enums.baseHpFactors,
        default = module.enums.baseHpFactors.HP100,
    },
    perLevelHpFactor = {
        order = 2,
        section = sections.health,
        renderer = "select",
        enum = module.enums.perLevelHpFactors,
        default = module.enums.perLevelHpFactors.Med,
    },
    deathCounter = {
        order = 3,
        section = sections.health,
        renderer = "checkbox",
        default = false,
    },
    luckModifierPerDeath = {
        order = 4,
        section = sections.health,
        renderer = mDef.renderers.number,
        argument = { min = -10, max = 10 },
        default = -1,
    },
    showHealthChangeNotifications = {
        order = 5,
        section = sections.health,
        renderer = "checkbox",
        default = true,
    },
    showHealthValueDetails = {
        order = 6,
        section = sections.health,
        renderer = "checkbox",
        default = false,
    },
}
local settings = module.settings

local function isWritableSection(section)
    return section.type == storeTypes.Global and I.Activation
            or section.type == storeTypes.Player and I.Controls
end

module.registerGroups = function()
    for _, section in pairs(sections) do
        section.page = mDef.MOD_NAME
        section.l10n = mDef.MOD_NAME
        local name = section.name
        section.name = name .. "SectionTitle"
        if section.description ~= false then
            section.description = mDef.getMessageKeyIfOpenMWTooOld(name .. "SectionDesc")
        else
            section.description = nil
        end
        section.permanentStorage = false
        section.settings = {}
        if mDef.isLuaApiRecentEnough then
            for _, setting in mHelpers.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                setting.name = setting.key .. "_name"
                if setting.description ~= false then
                    setting.description = setting.key .. "_desc"
                else
                    setting.description = nil
                end
                table.insert(section.settings, setting)
            end
        end
        if isWritableSection(section) then
            I.Settings.registerGroup(section)
        end
    end
end

module.addTrackerCallback = function(callback)
    table.insert(trackerCallbacks, callback)
end

module.updateRendererArgument = function(setting)
    I.Settings.updateRendererArgument(setting.section.key, setting.key, setting.argument)
end

local function serializeValue(setting, value)
    return setting.enum and setting.keys[value] or value
end

local function deserializeValue(setting, value)
    return setting.enum and setting.values[value] or value
end

for _, section in pairs(sections) do
    section.key = "Settings" .. section.name .. mDef.MOD_NAME
    section.get = function()
        if section.type == storeTypes.Global then
            return storage.globalSection(section.key)
        else
            return storage.playerSection(section.key)
        end
    end
end

for key, setting in pairs(settings) do
    setting.key = key
    setting.get = function()
        return setting.value
    end
    setting.set = function(value)
        return setting.section.get():set(key, serializeValue(setting, value))
    end
    if setting.enum then
        local items = {}
        setting.keys = {}
        setting.values = {}
        for vKey, value in mHelpers.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. vKey
            table.insert(items, itemKey)
            setting.keys[value] = itemKey
            setting.values[itemKey] = value
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        setting.argument = setting.argument or {}
    end
    setting.argument.disabled = setting.argument.disabled or false
    setting.value = deserializeValue(setting, setting.default)
end

for _, section in pairs(sections) do
    for key, value in pairs(section.get():asTable()) do
        local setting = settings[key]
        if not setting then
            -- key used in an older mod version: remove the entry
            if isWritableSection(section) then
                -- only set the setting from a global script
                section.get():set(key, nil)
            end
        else
            if value == nil
                    or setting.default and type(value) ~= type(setting.default)
                    or setting.enum and not setting.values[value] then
                -- broken storage: restore the default value
                value = setting.default
                if isWritableSection(section) then
                    -- only set the setting from a global script
                    section.get():set(key, value)
                end
            end

            setting.value = deserializeValue(setting, value)
        end
    end
end

for _, section in pairs(sections) do
    section.get():subscribe(async:callback(function(_, key)
        local setting = settings[key]
        if not setting then return end
        local oldValue = setting.value
        setting.value = deserializeValue(setting, section.get():getCopy(key))
        for i = 1, #trackerCallbacks do
            trackerCallbacks[i](key, oldValue)
        end
    end))
end

return module