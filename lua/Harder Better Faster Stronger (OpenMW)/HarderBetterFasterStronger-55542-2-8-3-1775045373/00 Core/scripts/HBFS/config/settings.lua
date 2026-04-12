local core = require('openmw.core')
local T = require('openmw.types')

local mDef = require('scripts.HBFS.config.definition')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')

local module = {}

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
    [mStore.percentKey(mStore.attributes.strength)] = 0.5,
    [mStore.percentKey(mStore.attributes.agility)] = 0.5,
    [mStore.percentKey(mStore.attributes.endurance)] = 1.0,
    [mStore.percentKey(mStore.attributes.willpower)] = 0.5,
    [mStore.percentKey(mStore.attributes.intelligence)] = 0.0,
    [mStore.percentKey(mStore.attributes.personality)] = 0.5,
    [mStore.percentKey(mStore.attributes.speed)] = 0.2,
    [mStore.percentKey(mStore.attributes.luck)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.health)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.magicka)] = 0.5,
    [mStore.percentKey(mStore.dynamicStats.fatigue)] = 0.5,
}

local function getPerActorSetting(state, getValue)
    local actualSettings = {}
    mTools.copyMap(state.actualSettings, actualSettings)
    actualSettings.attributes = {}
    actualSettings.dynamicStats = {}
    for _, attribute in ipairs(mStore.attributes) do
        local values = mStore.settings[mStore.percentKey(attribute)].value
        actualSettings.attributes[attribute.id] = getValue(values)
    end
    for _, stat in mTools.spairs(mStore.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local values = mStore.settings[mStore.percentKey(stat)].value
        actualSettings.dynamicStats[stat.id] = getValue(values)
    end
    return actualSettings
end

module.getActorSettings = function(state, actor)
    local scaledSettings = state.actualSettings
    if mStore.settings.difficultyScaling.value then
        if mStore.settings.boostOnlyWeakerActors.value then
            local actorLevel = math.max(1, T.Actor.stats.level(actor).current)
            scaledSettings = getPerActorSetting(state, function(values)
                return values.base + math.max(0, state.playerLevel - actorLevel) * values.increase
            end)
        end
    elseif mStore.settings.actorLevelBasedBoost.value then
        local actorLevel = math.min(100, math.max(1, T.Actor.stats.level(actor).current))
        scaledSettings = getPerActorSetting(state, function(values)
            return mStore.defaultPercent + (values.base - mStore.defaultPercent) / (1 + (actorLevel / 50) ^ 4)
        end)
    end
    if state.actors[actor.id] and state.actors[actor.id].conjurationSource then
        local conjurationSource = state.actors[actor.id].conjurationSource
        scaledSettings.summonPercent = conjurationSource == mDef.conjurationSource.spell
                and mStore.settings.summonConjurationPercentRange.value.actual
                or (
                conjurationSource == mDef.conjurationSource.enchant
                        and mStore.settings.summonEnchantPercentRange.value.actual
                        or mStore.settings.summonScrollPercent.value)
    end
    return scaledSettings
end

-- set actors' shared settings and compute the settings key to detect actors' settings changes
module.setActualSettings = function(state)
    local keyItems = {
        tostring(mStore.settings.actorLevelBasedBoost.value),
        tostring(mStore.settings.boostOnlyWeakerActors.value),
        tostring(mStore.settings.followerPercent.value),
        tostring(mStore.settings.summonScrollPercent.value),
        tostring(mStore.settings.summonConjurationPercentRange.value.actual),
        tostring(mStore.settings.summonEnchantPercentRange.value.actual),
        tostring(mStore.settings.noBackRunningActors.value),
    }
    state.actualSettings = {
        attributes = {},
        dynamicStats = {},
        followerPercent = mStore.settings.followerPercent.value,
        noBackRunningActors = mStore.settings.noBackRunningActors.value,
    }
    for _, attribute in ipairs(mStore.attributes) do
        local actual = mStore.settings[mStore.percentKey(attribute)].value.actual
        state.actualSettings.attributes[attribute.id] = actual
        table.insert(keyItems, actual)
    end
    for _, stat in mTools.spairs(mStore.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local actual = mStore.settings[mStore.percentKey(stat)].value.actual
        state.actualSettings.dynamicStats[stat.id] = actual
        table.insert(keyItems, actual)
    end
    state.actualSettings.key = table.concat(keyItems, ",")
end

module.updatePercentSetting = function(state, setting)
    setting.value.actual = setting.value.base + state.playerLevel * setting.value.increase
    setting.set(setting.value)
end

local function updateRangeSetting(setting, progress, max)
    setting.value.actual = math.min(max or math.huge, setting.value.from + (setting.value.to - setting.value.from) * progress)
    setting.set(setting.value)
end

local function updateSettingDependencies(hasPreset, hasScaling)
    if hasScaling then
        if mStore.settings.actorLevelBasedBoost.value then
            mStore.settings.actorLevelBasedBoost.set(false)
        end
    else
        if mStore.settings.boostOnlyWeakerActors.value then
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
    local presetBase = presetBaseRatios[mStore.settings.presetBase.value]
    local presetIncrease = presetIncreaseRatios[mStore.settings.presetIncrease.value]
    local hasScaling = mStore.settings.difficultyScaling.value
    local perActor = mStore.settings.boostOnlyWeakerActors.value or mStore.settings.actorLevelBasedBoost.value
    local toggleScaling = (presetIncrease > 0) ~= hasScaling
    if toggleScaling then
        mStore.settings.difficultyScaling.set(not hasScaling)
        return
    end
    updateSettingDependencies(true, hasScaling)
    for key, ratio in pairs(presetPercentRatios) do
        local setting = mStore.settings[key]
        setting.value.base = mStore.defaultPercent * (1 + presetBase * ratio)
        setting.value.increase = ratio * presetIncrease * mStore.defaultPercent
        module.updatePercentSetting(state, setting)
        mStore.updatePercentArgument(key, true, hasScaling, perActor)
    end
end

module.updatePercentSettings = function(state)
    if mStore.settings.presetsEnabled.value then
        applyPreset(state)
        return
    end
    local hasScaling = mStore.settings.difficultyScaling.value
    updateSettingDependencies(false, hasScaling)
    for key, setting in pairs(mStore.settings) do
        if setting.isPercentAndIncrease then
            if not hasScaling then
                -- Ensure the increase is cleared when there are old residual settings
                mStore.settings[key].value.increase = 0
            end
            module.updatePercentSetting(state, setting)
            mStore.updatePercentArgument(key, false, hasScaling)
        end
    end
end

module.updateRangeSettings = function(state)
    updateRangeSetting(mStore.settings.summonConjurationPercentRange,
            state.playerConjuration / 100,
            mStore.settings.maxSummonRangePercent.value)
    updateRangeSetting(mStore.settings.summonEnchantPercentRange,
            state.playerEnchant / 100,
            mStore.settings.maxSummonRangePercent.value)
end

module.updateSettings = function(state)
    module.updatePercentSettings(state)
    module.updateRangeSettings(state)
end

local function hasSettingChanged(key, oldValue, valueKeys)
    for _, valueKey in ipairs(valueKeys) do
        if oldValue[valueKey] ~= mStore.settings[key].value[valueKey] then
            return true
        end
    end
    return false
end

module.updateSetting = function(key, oldValue)
    local setting = mStore.settings[key]
    -- Also check change on actual value in case of the Reset button is pressed
    if setting.impactsPercents or setting.isPercentAndIncrease and oldValue.actual ~= setting.value.actual then
        core.sendGlobalEvent(mDef.events.updatePercentSettings)
    elseif setting.isPercentAndIncrease and hasSettingChanged(key, oldValue, { "base", "increase" }) then
        core.sendGlobalEvent(mDef.events.updatePercentSetting, key)
    elseif key == mStore.settings.maxSummonRangePercent.key or setting.isRange and hasSettingChanged(key, oldValue, { "from", "to", "actual" }) then
        core.sendGlobalEvent(mDef.events.updateRangeSettings)
    end
end

return module