local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mHelpers = require('scripts.skill-evolution.util.helpers')

local storeTypes = { Global = 0, Player = 1 }
local configStages = { Root = 0, OnActive = 1 }

local module = {
    sections = {
        main = { order = 0, type = storeTypes.Global, configStage = configStages.Root, name = "Main" },
        skills = { order = 1, type = storeTypes.Player, configStage = configStages.Root, name = "Skills" },
        time = { order = 2, type = storeTypes.Player, configStage = configStages.Root, name = "Time" },
        potions = { order = 3, type = storeTypes.Player, configStage = configStages.Root, name = "Potions" },
        skillUsesScaled = { order = 4, type = storeTypes.Player, configStage = configStages.Root, name = "SkillUsesScaled" },
        skillUseGains = { order = 5, type = storeTypes.Player, configStage = configStages.OnActive, name = "SkillUseGains" },
        magicka = { order = 6, type = storeTypes.Player, configStage = configStages.Root, name = "Magicka", description = false },
    },
    configStages = configStages,
    enums = {
        skillDecayRates = { None = 0, VerySlow = 1, Slow = 2, Standard = 4, Fast = 8 },
        skillDecayReductionRates = { Slow = 0.5, Standard = 1, Fast = 2 },
        refundMults = { ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5 },
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

local trackerCallbacks = {}
local potionPriceDisabled = core.getGMST("iAlchemyMod") == 0

local function rangeValue(from, to)
    return { from = from, to = to, enabled = true }
end

module.settings = {
    -- MAIN
    debugMode = {
        order = 0,
        section = sections.main,
        description = false,
        renderer = "checkbox",
        default = false,
    },
    -- SKILLS
    skillLevelBasedScalingRange = {
        order = 1,
        section = sections.skills,
        renderer = mDef.renderers.range,
        argument = { min = 1, max = 10000, log = mDef.logRangeTypes.skillLevelBasedScalingRange, desc = true, percent = true },
        default = rangeValue(125, 25),
    },
    skillUncapper = {
        order = 2,
        section = sections.skills,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 10000 },
        default = 0,
    },
    perSkillUncapper = {
        order = 3,
        section = sections.skills,
        renderer = mDef.renderers.perSkillUncapper,
        argument = { integer = true, min = 0, max = 10000, allItems = {} },
        default = {},
    },
    skillDecayRate = {
        order = 4,
        section = sections.skills,
        renderer = mDef.renderers.decayRate,
        enum = module.enums.skillDecayRates,
        isGlobalEnum = true,
        default = module.enums.skillDecayRates.Slow,
    },
    skillDecayReductionRate = {
        order = 5,
        section = sections.skills,
        renderer = "select",
        enum = module.enums.skillDecayReductionRates,
        isGlobalEnum = true,
        default = module.enums.skillDecayReductionRates.Standard,
    },
    skillDecayIntelligenceFactor = {
        order = 6,
        section = sections.skills,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 5 },
        default = 0,
    },
    skillIncreaseFromBooks = {
        order = 7,
        section = sections.skills,
        description = false,
        renderer = "checkbox",
        default = true,
    },
    carryOverExcessSkillGain = {
        order = 8,
        section = sections.skills,
        renderer = "checkbox",
        default = true,
    },
    capSkillTraining = {
        order = 9,
        section = sections.skills,
        renderer = "checkbox",
        default = true,
    },
    scaledTrainingDuration = {
        order = 10,
        section = sections.skills,
        renderer = mDef.renderers.range,
        argument = { min = 2, max = 48, log = mDef.logRangeTypes.scaledTrainingDuration, desc = false, percent = false },
        default = rangeValue(2, 16),
    },
    -- TIME
    minutesPerPotionCreation = {
        order = 0,
        section = sections.time,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, desc = true, togglable = true },
        default = rangeValue(90, 30),
    },
    potionMaxRecipeCountBasedTimeReduction = {
        order = 1,
        section = sections.time,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 100, integer = true, percent = true },
        default = 50,
    },
    minutesPerSelfRepair = {
        order = 2,
        section = sections.time,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, desc = true, togglable = true },
        default = rangeValue(15, 5),
    },
    minutesPerNPCRepair = {
        order = 3,
        section = sections.time,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 1000, integer = true },
        default = 30,
    },
    minutesPerSelfEnchanting = {
        order = 4,
        section = sections.time,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, desc = true, togglable = true },
        default = rangeValue(90, 30),
    },
    minutesPerNPCEnchanting = {
        order = 5,
        section = sections.time,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 1000, integer = true },
        default = 60,
    },
    -- POTIONS
    potionValueMod = {
        order = 0,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 5, disabled = potionPriceDisabled },
        default = 0.5,
    },
    potionMaxIngredientValuePercent = {
        order = 1,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 10000, integer = true, percent = true, disabled = potionPriceDisabled },
        default = 400,
    },
    potionPositiveEffectsBasedPrice = {
        order = 2,
        section = sections.potions,
        renderer = "checkbox",
        argument = { disabled = potionPriceDisabled },
        default = true,
    },
    -- SKILL USES SCALED
    skillScalingShowFeats = {
        order = 0,
        section = sections.skillUsesScaled,
        renderer = "checkbox",
        default = true,
    },
    skillScalingMaxFeatStats = {
        order = 1,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 5 },
        default = 3,
    },
    skillScalingDebugNotifsEnabled = {
        order = 2,
        section = sections.skillUsesScaled,
        renderer = "checkbox",
        default = false,
    },
    magickaBasedSkillScaling = {
        order = 3,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 300, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, 300),
    },
    weaponSkillScaling = {
        order = 4,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = mCfg.maxScaledSkillGainPercent, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent),
    },
    armorSkillScaling = {
        order = 5,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 400, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, 400),
    },
    blockSkillScaling = {
        order = 6,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 400, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, 400),
    },
    securitySkillScaling = {
        order = 7,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = mCfg.maxScaledSkillGainPercent, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent),
    },
    acrobaticsSkillScaling = {
        order = 8,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 400, percent = true, togglable = true },
        default = rangeValue(0, 400),
    },
    athleticsSkillScaling = {
        order = 9,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = mCfg.maxScaledSkillGainPercent, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent),
    },
    alchemySkillScaling = {
        order = 10,
        section = sections.skillUsesScaled,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 350, percent = true, togglable = true },
        default = rangeValue(mCfg.minScaledSkillGainPercent, 350),
    },
    -- SKILL USES GAINS
    --
    -- generated during the onActive handler, once custom skills should be registered
    --
    -- MAGICKA
    refundEnabled = {
        order = 0,
        section = sections.magicka,
        renderer = "checkbox",
        default = false,
    },
    refundMult = {
        order = 1,
        section = sections.magicka,
        renderer = "select",
        enum = module.enums.refundMults,
        isGlobalEnum = true,
        default = module.enums.refundMults["4"],
    },
    refundStart = {
        order = 2,
        section = sections.magicka,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 1000 },
        default = 35,
    },
    mbspEnabled = {
        order = 3,
        section = sections.magicka,
        renderer = "checkbox",
        default = false,
    },
    mbspRate = {
        order = 4,
        section = sections.magicka,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 100 },
        default = 10,
    },
}
local settings = module.settings

local valueValidators = {
    [mDef.renderers.range] = function(value)
        return type(value) == "table" and type(value.from) == "number" and type(value.to) == "number"
    end
}

local function isWritableSection(section)
    return section.type == storeTypes.Global and I.Activation
            or section.type == storeTypes.Player and I.Controls
end

module.registerGroups = function(configStage)
    for _, section in pairs(sections) do
        if section.configStage == configStage then
            section.page = mDef.MOD_NAME
            section.l10n = mDef.MOD_NAME
            local name = section.name
            section.name = name .. "SectionTitle"
            if section.description == nil then
                section.description = name .. "SectionDesc"
            else
                section.description = nil
            end
            section.permanentStorage = false
            section.settings = {}
            for _, setting in mHelpers.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                if not setting.name then
                    setting.name = setting.key .. "_name"
                end
                if setting.description == nil then
                    setting.description = setting.key .. "_desc"
                else
                    setting.description = nil
                end
                table.insert(section.settings, setting)
            end
            if isWritableSection(section) then
                I.Settings.registerGroup(section)
            end
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

local function configureSetting(key, setting)
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
            local itemKey = setting.isGlobalEnum and vKey or (key .. vKey)
            table.insert(items, itemKey)
            setting.keys[value] = itemKey
            setting.values[itemKey] = value
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items, values = setting.values }
    else
        setting.argument = setting.argument or {}
    end
    setting.argument.disabled = setting.argument.disabled or false
    setting.value = deserializeValue(setting, setting.default)
end

local function configureSection(section)
    section.get():subscribe(async:callback(function(_, key)
        local setting = settings[key]
        if not setting then return end
        local oldValue = setting.value
        setting.value = deserializeValue(setting, section.get():getCopy(key))
        for i = 1, #trackerCallbacks do
            trackerCallbacks[i](key, oldValue)
        end
    end))

    for key, value in pairs(section.get():asTable()) do
        local setting = settings[key]
        if not setting then
            if isWritableSection(section) then
                print(string.format("Unknown setting %s: removing it", key))
                section.get():set(key, nil)
            end
        else
            if value == nil
                    or setting.default and type(value) ~= type(setting.default)
                    or setting.enum and not setting.values[value]
                    or valueValidators[setting.renderer] and not valueValidators[setting.renderer](value) then
                value = setting.default
                if isWritableSection(section) then
                    print(string.format("Broken storage for setting %s: restoring the default value", key))
                    section.get():set(key, value)
                end
            end

            setting.value = deserializeValue(setting, value)
        end
    end
end

module.configureSettings = function(configStage)
    for key, setting in pairs(settings) do
        if setting.section and setting.section.configStage == configStage then
            configureSetting(key, setting)
        end
    end

    for _, section in pairs(sections) do
        if section.configStage == configStage then
            configureSection(section)
        end
    end
end

return module