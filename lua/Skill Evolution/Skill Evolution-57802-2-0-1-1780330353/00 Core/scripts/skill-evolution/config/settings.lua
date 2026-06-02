local I = require("openmw.interfaces")
local self = require('openmw.self')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.store')
local mCore = require('scripts.skill-evolution.util.core')

local module = {}

module.getCappedValue = function(value)
    return value == 0 and math.huge or value
end

local function setRangeIsEnabled(key, enabled)
    local setting = mS.settings[key].get()
    setting.enabled = enabled
    mS.settings[key].set(setting)
end

local function updateSkillScalingSettings()
    if mS.settings.magickaBasedSkillScaling.get().enabled then
        mS.settings.mbspEnabled.set(false)
    end
end

local function updateMagickaSettings()
    if mS.settings.mbspEnabled.get() then
        setRangeIsEnabled(mS.settings.magickaBasedSkillScaling.key, false)
    end
end

module.configurePerSkillUncapperSetting = function()
    local skillItems = {}
    local Skills = mCore.getSkillRecords()
    for i = 1, #Skills do
        local prop = Skills[i]
        skillItems[#skillItems + 1] = { key = prop.id, name = prop.name, value = prop.maxLevel or 1000, maxLevel = prop.maxLevel }
    end
    mS.settings.perSkillUncapper.argument.allItems = skillItems
    mS.updateRendererArgument(mS.settings.perSkillUncapper)
end

local function updateCustomSkillMaxLevel(items, prop)
    for j = 1, #items do
        local item = items[j]
        if item.key == prop.id then
            if item.maxLevel ~= prop.maxLevel or item.value > prop.maxLevel then
                item.maxLevel = prop.maxLevel
                item.value = math.min(item.value, prop.maxLevel)
                mS.settings.perSkillUncapper.set(items)
            end
            return true
        end
    end
end

module.setCustomSkillMaxLevels = function()
    local Skills = mCore.getSkillRecords()
    for i = 1, #Skills do
        local prop = Skills[i]
        if prop.maxLevel then
            local items = mS.settings.perSkillUncapper.get()
            if not updateCustomSkillMaxLevel(items, prop) then
                items[#items + 1] = { key = prop.id, name = prop.name, value = prop.maxLevel or 1000, maxLevel = prop.maxLevel }
                mS.settings.perSkillUncapper.set(items)
            end
        end
    end
end

module.getSkillUseGainsKey = function(skillId)
    return "skillUseGains_" .. skillId
end

local function skillUseGainSectionSetting(key, order)
    mS.settings[key] = {
        order = order,
        section = mS.sections.skillUseGains,
        description = false,
        renderer = mDef.renderers.empty,
    }
end

module.configureSkillUseGainsSetting = function()
    local skillProps = mCore.getSkillRecords()
    local default = {}
    local lastSpec
    local lastIsCustom
    local order = 0
    for i = 1, #skillProps do
        local prop = skillProps[i]
        if prop.isCustom ~= lastIsCustom then
            mS.settings.skillUseGainsOther = skillUseGainSectionSetting("skillUseGainOtherSkills", order)
            order = order + 1
        elseif not prop.isCustom and prop.specialization ~= lastSpec then
            if prop.specialization == "combat" then
                mS.settings.skillUseGainsOther = skillUseGainSectionSetting("skillUseGainCombatSkills", order)
                order = order + 1
            elseif prop.specialization == "magic" then
                mS.settings.skillUseGainsOther = skillUseGainSectionSetting("skillUseGainMagicSkills", order)
                order = order + 1
            elseif prop.specialization == "stealth" then
                mS.settings.skillUseGainsOther = skillUseGainSectionSetting("skillUseGainStealthSkills", order)
                order = order + 1
            end
        end
        lastSpec = prop.specialization
        lastIsCustom = prop.isCustom
        local config = {
            id = prop.id,
            name = prop.name,
            specialization = prop.specialization,
            isCustom = prop.isCustom,
            gains = {}
        }
        if prop.isCustom then
            for useTypeKey, gain in pairs(prop.skillGain) do
                default[useTypeKey] = gain
                config.gains[useTypeKey] = {
                    key = useTypeKey,
                    default = gain,
                    original = gain,
                }
            end
        else
            for useType, useTypeData in pairs(mCfg.skillUseTypes[prop.id]) do
                default[useType] = useTypeData.gain
                config.gains[useType] = {
                    key = useTypeData.key,
                    default = useTypeData.gain,
                    original = useTypeData.vanilla,
                    modded = prop.skillGain[useType + 1],
                }
            end
        end
        mS.settings[module.getSkillUseGainsKey(prop.id)] = {
            order = order,
            section = mS.sections.skillUseGains,
            name = prop.name,
            description = false,
            renderer = mDef.renderers.skillGains,
            argument = { min = 0, max = 1000, config = config },
            default = default,
        }
        order = order + 1
    end
end

module.getPerSkillCappedValues = function()
    local map = {}
    local caps = mS.settings.perSkillUncapper.get()
    for i = 1, #caps do
        local item = caps[i]
        map[item.key] = module.getCappedValue(item.value)
    end
    return map
end

module.getSkillCappedValue = function(skillId)
    return module.getPerSkillCappedValues()[skillId] or module.getCappedValue(mS.settings.skillUncapper.get())
end

module.isDecayEnabled = function()
    return mS.settings.skillDecayRate.get() ~= mS.enums.skillDecayRates.None
end

module.init = function()
    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description"
    }

    mS.addTrackerCallback(function(key, _)
        if key == mS.settings.skillDecayRate.key then
            self:sendEvent(mDef.events.changeDecayRate)
        end
        if key == mS.settings.perSkillUncapper.key then
            -- handle the section reset button
            if #mS.settings.perSkillUncapper.get() == 0 then
                self:sendEvent(mDef.events.setCapperMaxLevels)
            end
        end
        if mS.settings[key].section.key == mS.sections.skillUsesScaled.key then
            updateSkillScalingSettings()
        end
        if mS.settings[key].section.key == mS.sections.magicka.key then
            updateMagickaSettings()
        end
    end)

    updateSkillScalingSettings()
    updateMagickaSettings()
end

return module