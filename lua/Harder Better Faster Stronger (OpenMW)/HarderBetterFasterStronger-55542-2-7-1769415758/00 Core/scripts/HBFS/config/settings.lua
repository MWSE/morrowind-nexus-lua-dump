local I = require("openmw.interfaces")
local T = require('openmw.types')

local mDef = require('scripts.HBFS.config.definition')
local mCfg = require('scripts.HBFS.config.configuration')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')

local module = {}

local function getPerActorSetting(state, getValue)
    local actualSettings = {
        attributes = {},
        dynamicStats = {},
        excludeNPCFollowers = state.actualSettings.excludeNPCFollowers,
        excludeCreatureFollowers = state.actualSettings.excludeCreatureFollowers,
        noBackRunningActors = state.actualSettings.noBackRunningActors,
        key = state.actualSettings.key
    }
    for _, attribute in ipairs(mCfg.attributes) do
        local values = state.settings[mCfg.percentKey(attribute)]
        actualSettings.attributes[attribute.id] = getValue(values)
    end
    for _, stat in mTools.spairs(mCfg.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local values = state.settings[mCfg.percentKey(stat)]
        actualSettings.dynamicStats[stat.id] = getValue(values)
    end
    return actualSettings
end

module.getScaledSettings = function(state, actor)
    if state.settings[mStore.settings.difficultyScaling.key] then
        if state.settings[mStore.settings.boostOnlyWeakerActors.key] then
            local actorLevel = math.max(1, T.Actor.stats.level(actor).current)
            return getPerActorSetting(state, function(values)
                return values.base + math.max(0, state.playerLevel - actorLevel) * values.increase
            end)
        end
    elseif state.settings[mStore.settings.actorLevelBasedBoost.key] then
        local actorLevel = math.min(100, math.max(1, T.Actor.stats.level(actor).current))
        return getPerActorSetting(state, function(values)
            return mCfg.defaultPercent + (values.base - mCfg.defaultPercent) / (1 + (actorLevel / 50) ^ 4)
        end)
    end
    return state.actualSettings
end

module.setActualSettings = function(state)
    local keyItems = {}
    for _, attribute in ipairs(mCfg.attributes) do
        local actual = state.settings[mCfg.percentKey(attribute)].actual
        state.actualSettings.attributes[attribute.id] = actual
        table.insert(keyItems, actual)
    end
    for _, stat in mTools.spairs(mCfg.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
        local actual = state.settings[mCfg.percentKey(stat)].actual
        state.actualSettings.dynamicStats[stat.id] = actual
        table.insert(keyItems, actual)
    end
    state.actualSettings.excludeNPCFollowers = state.settings[mStore.settings.excludeNPCFollowers.key]
    state.actualSettings.excludeCreatureFollowers = state.settings[mStore.settings.excludeCreatureFollowers.key]
    state.actualSettings.noBackRunningActors = state.settings[mStore.settings.noBackRunningActors.key]
    table.insert(keyItems, tostring(state.settings[mStore.settings.excludeNPCFollowers.key]))
    table.insert(keyItems, tostring(state.settings[mStore.settings.excludeCreatureFollowers.key]))
    table.insert(keyItems, tostring(state.settings[mStore.settings.boostOnlyWeakerActors.key]))
    table.insert(keyItems, tostring(state.settings[mStore.settings.actorLevelBasedBoost.key]))
    table.insert(keyItems, tostring(state.settings[mStore.settings.noBackRunningActors.key]))
    state.actualSettings.key = table.concat(keyItems, ",")
end

module.updatePercentSetting = function(state, key)
    state.settings[key].actual = state.settings[key].base + state.playerLevel * state.settings[key].increase
    mStore.settings[key].set(state.settings[key])
end

module.updateSettingDependencies = function(state, hasPreset, hasScaling)
    if hasScaling then
        if state.settings[mStore.settings.actorLevelBasedBoost.key] then
            mStore.settings.actorLevelBasedBoost.set(false)
        end
    else
        if state.settings[mStore.settings.boostOnlyWeakerActors.key] then
            mStore.settings.boostOnlyWeakerActors.set(false)
        end
    end
    mStore.setDisabled(mStore.settings.presetBase.key, not hasPreset)
    mStore.setDisabled(mStore.settings.presetIncrease.key, not hasPreset)
    mStore.setDisabled(mStore.settings.difficultyScaling.key, hasPreset)
    mStore.setDisabled(mStore.settings.boostOnlyWeakerActors.key, not hasScaling)
    mStore.setDisabled(mStore.settings.actorLevelBasedBoost.key, hasScaling)
end

module.copySettings = function(state)
    for key, setting in pairs(mStore.settings) do
        state.settings[key] = setting.getCopy()
    end
end

for _, section in mTools.spairs(mStore.sections, function(t, a, b) return t[a].order < t[b].order end) do
    local group = { settings = {} }
    group.key = section.key
    group.page = mDef.MOD_NAME
    group.l10n = mDef.MOD_NAME
    group.name = section.name .. "SectionTitle"
    group.description = section.name .. "SectionDesc"
    group.permanentStorage = false
    group.order = section.order
    for _, setting in mTools.spairs(
            mStore.settings,
            function(t, a, b) return t[a].order < t[b].order end,
            function(a) return a.section.key == section.key end) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
        table.insert(group.settings, setting)
    end
    I.Settings.registerGroup(group)
end

return module