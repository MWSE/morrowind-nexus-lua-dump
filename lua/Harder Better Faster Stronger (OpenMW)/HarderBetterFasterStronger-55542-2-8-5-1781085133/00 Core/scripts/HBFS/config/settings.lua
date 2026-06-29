local core = require('openmw.core')
local T = require('openmw.types')

local mDef = require('scripts.HBFS.config.definition')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')

local module = {}

local attributes = core.stats.Attribute.records

local presetBaseRatios = {
    [mStore.presetsBase.Easier] = -0.5,
    [mStore.presetsBase.Easy] = -0.25,
    [mStore.presetsBase.Normal] = 0,
    [mStore.presetsBase.Hard] = 0.5,
    [mStore.presetsBase.Harder] = 1.0,
}

local presetIncreaseRatios = {
    [mStore.presetsIncrease.None] = 0.0,
    [mStore.presetsIncrease.Slow] = 0.01,
    [mStore.presetsIncrease.Normal] = 0.02,
    [mStore.presetsIncrease.Fast] = 0.04,
}

local presetPercentRatios = {
    [mStore.settings.physicalDamagePercent.key] = 0.25,
    [mStore.settings.magicDamagePercent.key] = 0.5,
    [mStore.settings.sunDamagePercent.key] = 0.2,
    [mStore.percentKey(attributes.strength)] = 0.5,
    [mStore.percentKey(attributes.agility)] = 0.5,
    [mStore.percentKey(attributes.endurance)] = 1.0,
    [mStore.percentKey(attributes.willpower)] = 0.5,
    [mStore.percentKey(attributes.intelligence)] = 0.0,
    [mStore.percentKey(attributes.personality)] = 0.5,
    [mStore.percentKey(attributes.speed)] = 0.2,
    [mStore.percentKey(attributes.luck)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.health)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.magicka)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.fatigue)] = 0.5,
}

local function getPerActorSetting(state, getValue)
    local actualSettings = {}
    mTools.copyMap(state.actualSettings, actualSettings)
    actualSettings.attributePercents = {}
    actualSettings.dynamicStatPercents = {}
    for _, attribute in ipairs(core.stats.Attribute.records) do
        local values = mStore.settings[mStore.percentKey(attribute)].get()
        actualSettings.attributePercents[attribute.id] = getValue(values)
    end
    for _, stat in mTools.spairs(mStore.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local values = mStore.settings[mStore.percentKey(stat)].get()
        actualSettings.dynamicStatPercents[stat.id] = getValue(values)
    end
    return actualSettings
end

module.getActorSettings = function(state, actor)
    local scaledSettings = state.actualSettings
    if mStore.settings.difficultyScaling.get() then
        if mStore.settings.boostOnlyWeakerActors.get() then
            local actorLevel = math.max(1, T.Actor.stats.level(actor).current)
            scaledSettings = getPerActorSetting(state, function(values)
                return values.base + math.max(0, state.playerLevel - actorLevel) * values.increase
            end)
        end
    elseif mStore.settings.actorLevelBasedBoost.get() then
        local actorLevel = math.min(100, math.max(1, T.Actor.stats.level(actor).current))
        scaledSettings = getPerActorSetting(state, function(values)
            return mStore.defaultPercent + (values.base - mStore.defaultPercent) / (1 + (actorLevel / 50) ^ 4)
        end)
    end
    if state.actors[actor.id] and state.actors[actor.id].conjurationSource then
        local conjurationSource = state.actors[actor.id].conjurationSource
        scaledSettings.summonPercent = conjurationSource == mDef.conjurationSource.spell
                and mStore.settings.summonConjurationPercentRange.get().actual
                or (
                conjurationSource == mDef.conjurationSource.enchant
                        and mStore.settings.summonEnchantPercentRange.get().actual
                        or mStore.settings.summonScrollPercent.get())
    end
    return scaledSettings
end

-- set actors' shared settings and compute the settings key to detect actors' settings changes
module.setActualSettings = function(state)
    local keyItems = {
        tostring(mStore.settings.debugMode.get()),
        tostring(mStore.settings.actorLevelBasedBoost.get()),
        tostring(mStore.settings.boostOnlyWeakerActors.get()),
        tostring(mStore.settings.followerPercent.get()),
        tostring(mStore.settings.summonScrollPercent.get()),
        tostring(mStore.settings.summonConjurationPercentRange.get().actual),
        tostring(mStore.settings.summonEnchantPercentRange.get().actual),
        tostring(mStore.settings.noBackRunningActors.get()),
    }
    state.actualSettings = {
        debugMode = mStore.settings.debugMode.get(),
        attributePercents = {},
        dynamicStatPercents = {},
        followerPercent = mStore.settings.followerPercent.get(),
        noBackRunningActors = mStore.settings.noBackRunningActors.get(),
    }
    for _, attribute in ipairs(core.stats.Attribute.records) do
        local actual = mStore.settings[mStore.percentKey(attribute)].get().actual
        state.actualSettings.attributePercents[attribute.id] = actual
        table.insert(keyItems, actual)
    end
    for _, stat in mTools.spairs(mStore.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local actual = mStore.settings[mStore.percentKey(stat)].get().actual
        state.actualSettings.dynamicStatPercents[stat.id] = actual
        table.insert(keyItems, actual)
    end
    state.actualSettings.key = table.concat(keyItems, ",")
end

module.updatePercentSetting = function(state, setting)
    local value = setting.get()
    value.actual = value.base + state.playerLevel * value.increase
    setting.set(value)
end

local function updateRangeSetting(setting, progress, max)
    local value = setting.get()
    value.actual = math.min(max or math.huge, value.from + (value.to - value.from) * progress)
    setting.set(value)
end

local function updateSettingDependencies(hasPreset, hasScaling)
    if hasScaling then
        if mStore.settings.actorLevelBasedBoost.get() then
            mStore.settings.actorLevelBasedBoost.set(false)
        end
    else
        if mStore.settings.boostOnlyWeakerActors.get() then
            mStore.settings.boostOnlyWeakerActors.set(false)
        end
    end
    mStore.setDisabled(mStore.settings.presetBase.key, not hasPreset)
    mStore.setDisabled(mStore.settings.presetIncrease.key, not hasPreset)
    mStore.setDisabled(mStore.settings.difficultyScaling.key, hasPreset)
    mStore.setDisabled(mStore.settings.actorLevelBasedBoost.key, hasScaling)
    mStore.setDisabled(mStore.settings.boostOnlyWeakerActors.key, not hasScaling)
end

local function applyPreset(state)
    local presetBase = presetBaseRatios[mStore.settings.presetBase.get()]
    local presetIncrease = presetIncreaseRatios[mStore.settings.presetIncrease.get()]
    local hasScaling = mStore.settings.difficultyScaling.get()
    local perActor = mStore.settings.boostOnlyWeakerActors.get() or mStore.settings.actorLevelBasedBoost.get()
    local toggleScaling = (presetIncrease > 0) ~= hasScaling
    if toggleScaling then
        mStore.settings.difficultyScaling.set(not hasScaling)
        return
    end
    updateSettingDependencies(true, hasScaling)
    for key, ratio in pairs(presetPercentRatios) do
        local setting = mStore.settings[key]
        local value = setting.get()
        value.base = mStore.defaultPercent * (1 + presetBase * ratio)
        value.increase = ratio * presetIncrease * mStore.defaultPercent
        setting.set(value)
        module.updatePercentSetting(state, setting)
        mStore.updatePercentArgument(key, true, hasScaling, perActor)
    end
end

module.updatePercentSettings = function(state)
    if mStore.settings.presetsEnabled.get() then
        applyPreset(state)
        return
    end
    local hasScaling = mStore.settings.difficultyScaling.get()
    updateSettingDependencies(false, hasScaling)
    for key, setting in pairs(mStore.settings) do
        if setting.isPercentAndIncrease then
            local value = setting.get()
            if not hasScaling and value.increase ~= 0 then
                -- Ensure the increase is cleared when there are old residual settings
                value.increase = 0
                setting.set(value)
            end
            module.updatePercentSetting(state, setting)
            mStore.updatePercentArgument(key, false, hasScaling)
        end
    end
end

module.updateRangeSettings = function(state)
    updateRangeSetting(mStore.settings.summonConjurationPercentRange,
            state.playerConjuration / 100,
            mStore.settings.maxSummonRangePercent.get())
    updateRangeSetting(mStore.settings.summonEnchantPercentRange,
            state.playerEnchant / 100,
            mStore.settings.maxSummonRangePercent.get())
end

module.updateSettings = function(state)
    module.updatePercentSettings(state)
    module.updateRangeSettings(state)
end

local function hasSettingChanged(key, oldValue, valueKeys)
    for _, valueKey in ipairs(valueKeys) do
        if oldValue[valueKey] ~= mStore.settings[key].get()[valueKey] then
            return true
        end
    end
    return false
end

module.updateSetting = function(key, oldValue)
    local setting = mStore.settings[key]
    -- Also check change on actual value in case of the Reset button is pressed
    if setting.impactsPercents or setting.isPercentAndIncrease and oldValue.actual ~= setting.get().actual then
        core.sendGlobalEvent(mDef.events.updatePercentSettings)
    elseif setting.isPercentAndIncrease and hasSettingChanged(key, oldValue, { "base", "increase" }) then
        core.sendGlobalEvent(mDef.events.updatePercentSetting, key)
    elseif key == mStore.settings.maxSummonRangePercent.key or setting.isRange and hasSettingChanged(key, oldValue, { "from", "to", "actual" }) then
        core.sendGlobalEvent(mDef.events.updateRangeSettings)
    end
end

return module