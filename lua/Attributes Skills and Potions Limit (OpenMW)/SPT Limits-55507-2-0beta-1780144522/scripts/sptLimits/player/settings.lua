local storage = require("openmw.storage")
local async = require("openmw.async")
local interfaces = require("openmw.interfaces")
local config = require("scripts.sptLimits.shared.config")

local l10n = "sptLimits"

local definitions = {
    potionLimitEnabled = {
        key = "potionLimitEnabled",
        type = "boolean",
        default = config.potionLimitEnabled,
        renderer = "checkbox",
        group = "sptLimitsPotions",
        l10nName = "settingPotionLimitEnabledName",
        l10nDesc = "settingPotionLimitEnabledDesc",
        order = 0,
    },
    potionTrackingMode = {
        key = "potionTrackingMode",
        type = "string",
        default = config.potionTrackingMode,
        renderer = "select",
        options = { "counter", "slots" },
        group = "sptLimitsPotions",
        l10nName = "settingPotionTrackingModeName",
        l10nDesc = "settingPotionTrackingModeDesc",
        order = 1,
    },
    hudCounterMode = {
        key = "hudCounterMode",
        type = "string",
        default = config.hudCounterMode,
        renderer = "select",
        options = { "full", "minimal", "hidden" },
        group = "sptLimitsPotions",
        l10nName = "settingHudCounterModeName",
        l10nDesc = "settingHudCounterModeDesc",
        order = 2,
    },
    hudPosition = {
        key = "hudPosition",
        type = "string",
        default = config.hudPosition,
        renderer = "select",
        options = { "bottom", "top" },
        group = "sptLimitsPotions",
        l10nName = "settingHudPositionName",
        l10nDesc = "settingHudPositionDesc",
        order = 3,
    },
    excludeSunsDusk = {
        key = "excludeSunsDusk",
        type = "boolean",
        default = config.excludeSunsDusk,
        renderer = "checkbox",
        group = "sptLimitsPotions",
        l10nName = "settingExcludeSunsDuskName",
        l10nDesc = "settingExcludeSunsDuskDesc",
        order = 4,
    },
    potionLimit = {
        key = "potionLimit",
        type = "number",
        default = config.potionLimit,
        min = 1,
        max = 99,
        renderer = "number",
        group = "sptLimitsPotionsCounter",
        l10nName = "settingPotionLimitName",
        l10nDesc = "settingPotionLimitDesc",
        order = 0,
    },
    potionCooldown = {
        key = "potionCooldown",
        type = "number",
        default = config.potionCooldown,
        min = 1,
        max = 300,
        renderer = "number",
        group = "sptLimitsPotionsCounter",
        l10nName = "settingPotionCooldownName",
        l10nDesc = "settingPotionCooldownDesc",
        order = 1,
    },
    potionSlotCount = {
        key = "potionSlotCount",
        type = "number",
        default = config.potionSlotCount,
        min = 1,
        max = 10,
        renderer = "number",
        group = "sptLimitsPotionsSlots",
        l10nName = "settingPotionSlotCountName",
        l10nDesc = "settingPotionSlotCountDesc",
        order = 0,
    },
    statLimitEnabled = {
        key = "statLimitEnabled",
        type = "boolean",
        default = config.statLimitEnabled,
        renderer = "checkbox",
        group = "sptLimitsStats",
        l10nName = "settingStatLimitEnabledName",
        l10nDesc = "settingStatLimitEnabledDesc",
        order = 0,
    },
    attributeCap = {
        key = "attributeCap",
        type = "number",
        default = config.attributeCap,
        min = 1,
        max = 999,
        renderer = "number",
        group = "sptLimitsStats",
        l10nName = "settingAttributeCapName",
        l10nDesc = "settingAttributeCapDesc",
        order = 1,
    },
    skillCap = {
        key = "skillCap",
        type = "number",
        default = config.skillCap,
        min = 1,
        max = 999,
        renderer = "number",
        group = "sptLimitsStats",
        l10nName = "settingSkillCapName",
        l10nDesc = "settingSkillCapDesc",
        order = 2,
    },
    trainingLimitEnabled = {
        key = "trainingLimitEnabled",
        type = "boolean",
        default = config.trainingLimitEnabled,
        renderer = "checkbox",
        group = "sptLimitsTraining",
        l10nName = "settingTrainingLimitEnabledName",
        l10nDesc = "settingTrainingLimitEnabledDesc",
        order = 0,
    },
    trainingLimit = {
        key = "trainingLimit",
        type = "number",
        default = config.trainingLimit,
        min = 1,
        max = 99,
        renderer = "number",
        group = "sptLimitsTraining",
        l10nName = "settingTrainingLimitName",
        l10nDesc = "settingTrainingLimitDesc",
        order = 3,
    },
}

local subscribers = {}
local previousValues = {}
local subscribed = false
local suppressNotifications = false

local groupKeys =
    { "sptLimitsPotions", "sptLimitsPotionsCounter", "sptLimitsPotionsSlots", "sptLimitsStats", "sptLimitsTraining" }

local settings = {
    l10n = l10n,
    definitions = definitions,
}

function settings.get(key)
    local def = definitions[key]
    local section = storage.playerSection(def.group)
    local value = section:get(key)
    if value == nil then
        value = def.default
    end
    if def.min and def.max then
        value = math.max(def.min, math.min(def.max, value))
    end
    return value
end

function settings.registerPage()
    interfaces.Settings.registerPage({
        key = "sptLimits",
        l10n = l10n,
        name = "settingsTitle",
        description = "",
    })

    local groups = {
        { key = "sptLimitsPotions", name = "settingsPotionsTitle" },
        { key = "sptLimitsPotionsCounter", name = "settingsPotionsCounterTitle" },
        { key = "sptLimitsPotionsSlots", name = "settingsPotionsSlotsTitle" },
        { key = "sptLimitsStats", name = "settingsStatsTitle" },
        { key = "sptLimitsTraining", name = "settingsTrainingTitle" },
    }

    for _, group in ipairs(groups) do
        local groupSettings = {}
        for _, def in pairs(definitions) do
            if def.group == group.key then
                local entry = {
                    key = def.key,
                    renderer = def.renderer,
                    name = def.l10nName,
                    description = def.l10nDesc,
                    default = def.default,
                }
                if def.renderer == "number" then
                    entry.argument = { min = def.min, max = def.max }
                elseif def.renderer == "select" then
                    local items = {}
                    for _, opt in ipairs(def.options) do
                        items[#items + 1] = opt
                    end
                    entry.argument = { l10n = l10n, items = items }
                end
                groupSettings[#groupSettings + 1] = entry
            end
        end
        table.sort(groupSettings, function(a, b)
            return definitions[a.key].order < definitions[b.key].order
        end)

        interfaces.Settings.registerGroup({
            key = group.key,
            page = "sptLimits",
            l10n = l10n,
            name = group.name,
            description = "",
            permanentStorage = false,
            settings = groupSettings,
        })
    end
end

local function initPreviousValues()
    for key, def in pairs(definitions) do
        previousValues[key] = settings.get(key)
    end
end

local function handleSectionChange(groupKey)
    if suppressNotifications then
        return
    end
    local section = storage.playerSection(groupKey)
    for key, def in pairs(definitions) do
        if def.group == groupKey then
            local newValue = section:get(key)
            if newValue == nil then
                newValue = def.default
            end
            if newValue ~= previousValues[key] then
                previousValues[key] = newValue
                for _, callback in ipairs(subscribers) do
                    callback(key, newValue)
                end
            end
        end
    end
end

function settings.subscribe(callback)
    subscribers[#subscribers + 1] = callback

    if not subscribed then
        subscribed = true
        initPreviousValues()
        for _, groupKey in ipairs(groupKeys) do
            storage.playerSection(groupKey):subscribe(async:callback(function(section, key)
                handleSectionChange(groupKey)
            end))
        end
    end
end

function settings.syncToStorage()
    suppressNotifications = true
    for key, def in pairs(definitions) do
        local section = storage.playerSection(def.group)
        section:set(key, def.default)
    end
    suppressNotifications = false
    initPreviousValues()
end

function settings.saveAll()
    local saved = {}
    for key, _ in pairs(definitions) do
        saved[key] = settings.get(key)
    end
    return saved
end

function settings.loadAll(saved)
    if not saved then
        return
    end
    suppressNotifications = true
    for key, def in pairs(definitions) do
        local value = saved[key]
        if value == nil then
            value = def.default
        end
        local section = storage.playerSection(def.group)
        section:set(key, value)
    end
    suppressNotifications = false
    initPreviousValues()
end

return settings
