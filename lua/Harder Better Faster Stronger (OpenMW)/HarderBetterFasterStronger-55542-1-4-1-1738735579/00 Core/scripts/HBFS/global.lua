local core = require('openmw.core')
local T = require('openmw.types')
local async = require('openmw.async')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

require('scripts.HBFS.settings_global')
local mDef = require('scripts.HBFS.definition')
local mSettings = require('scripts.HBFS.settings')
local mTools = require('scripts.HBFS.tools')
local mDebug = require('scripts.HBFS.debug')

local lastUpdateTime = 0
local lastConfigurationCheckTime = 0

local state = {
    playerLevel = 1,
    settingsKey = "",
    settings = {},
    actualSettings = {
        attributes = {},
        dynamicStats = {},
        areDefault = true,
        areActorsDefault = true,
        key = "",
    },
}

local eventTypes = {
    set = "set",
    reset = "reset",
    rescale = "rescale",
}

local function onActorActive(actor)
    actor:sendEvent("hbfs_onActive", { settings = state.actualSettings, type = eventTypes.set })
end

local function setActualSettingsKey()
    local keyItems = {}
    for _, attribute in ipairs(core.stats.Attribute.records) do
        local actual = state.settings[mSettings.percentKey(attribute.id)].actual
        state.actualSettings.attributes[attribute.id] = actual
        table.insert(keyItems, actual)
    end
    for _, statId in ipairs(mSettings.orderedDynamicStats) do
        local actual = state.settings[mSettings.percentKey(statId)].actual
        state.actualSettings.dynamicStats[statId] = actual
        table.insert(keyItems, actual)
    end
    state.actualSettings.key = table.concat(keyItems, ",")
end

local function updateAllActorsStats(isLevelUp)
    local actualSettingsKey = state.actualSettings.key
    setActualSettingsKey()
    if actualSettingsKey == state.actualSettings.key then return end

    mDebug.print(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        player:sendEvent("hbfs_showMessage", mSettings.l10n(state.actualSettings.areActorsDefault and "resetActorsStats" or "updateActorsStats"))
    end
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player then
            actor:sendEvent("hbfs_updateStats", { settings = state.actualSettings, type = isLevelUp and eventTypes.rescale or eventTypes.reset })
        end
    end
end

local function getSettingsKey(hasDifficultyScaling)
    local settingsValues = {}
    if hasDifficultyScaling then
        table.insert(settingsValues, tostring(state.playerLevel))
    end
    for key, setting in mTools.spairs(state.settings, function(_, a, b) return a < b end) do
        if type(setting) == "table" and setting.base then
            -- Exclude actual value to prevent infinite subscribe callback loop
            table.insert(settingsValues, string.format("%s:%s_%s_%s", key, setting.selected, setting.base, setting.increase))
        else
            table.insert(settingsValues, string.format("%s:%s", key, tostring(setting)))
        end
    end
    return table.concat(settingsValues, ",")
end

local function isEnabled()
    return state.settings[mSettings.cfg.enabled.key]
end

local function isPresetEnabled()
    return isEnabled() and state.settings[mSettings.cfg.presets.key].selected ~= mSettings.presetValue(mSettings.defaultPreset)
end

local function isDifficultyScalingEnabled()
    return isEnabled() and (
            mSettings.cfg.presets.argument.valueMap[state.settings[mSettings.cfg.presets.key].selected].increase ~= 0
                    or state.settings[mSettings.cfg.difficultyScaling.key])
end

local function updateActualPercent(key, overrideKey, hasDifficultyScaling)
    local override
    if state.settings[mSettings.cfg.enabled.key] then
        override = overrideKey and state.settings[overrideKey].base or nil
        if overrideKey and hasDifficultyScaling then
            if state.settings[overrideKey].increase ~= 0 then
                state.actualSettings.areDefault = false
            end
            override = override + state.playerLevel * state.settings[overrideKey].increase
        end
    else
        override = overrideKey and mSettings.defaultPercent or nil
    end
    if state.settings[key].actual ~= override then
        state.settings[key].actual = override
        mSettings.getSection(key):set(key, state.settings[key])
    end
    if state.settings[key].actual and state.settings[key].actual ~= mSettings.defaultPercent then
        state.actualSettings.areDefault = false
        if mSettings.cfg[key].section == mSettings.actorsKey then
            state.actualSettings.areActorsDefault = false
        end
    end
end

local function updateSettings(init)
    local hasDifficultyScaling = isDifficultyScalingEnabled()
    local newSettingsKey = getSettingsKey(hasDifficultyScaling)
    if not init then
        if state.settingsKey == newSettingsKey then return end
        mDebug.print(string.format("Settings key changed:\nBefore: %s\nAfter:  %s", state.settingsKey, newSettingsKey))
    end
    state.settingsKey = newSettingsKey

    state.actualSettings.areDefault = true
    state.actualSettings.areActorsDefault = true

    local hasPreset = isPresetEnabled()
    local hasAttributesGlobalPercent = state.settings[mSettings.cfg.attributesGlobalPercent.key].selected
    local hasDynamicStatsGlobalPercent = state.settings[mSettings.cfg.dynamicStatsGlobalPercent.key].selected

    local globalOverrideKey = not isEnabled()
            and mSettings.cfg.enabled.key or (
            hasPreset
                    and mSettings.cfg.presets.key or (
                    state.settings[mSettings.cfg.globalPercent.key].selected and mSettings.cfg.globalPercent.key or nil))
    local hasGlobalOverride = globalOverrideKey ~= nil

    mSettings.updateCheckBoxArgument(mSettings.cfg.difficultyScaling.key, not isEnabled() or hasPreset)

    mSettings.updatePercentArgument(mSettings.cfg.presets.key, not isEnabled(),
            mSettings.cfg.presets.argument.valueMap[state.settings[mSettings.cfg.presets.key].selected].increase ~= 0)
    updateActualPercent(mSettings.cfg.presets.key, globalOverrideKey, hasDifficultyScaling)

    mSettings.updatePercentArgument(mSettings.cfg.globalPercent.key, not isEnabled() or hasPreset, hasDifficultyScaling)
    updateActualPercent(mSettings.cfg.globalPercent.key, globalOverrideKey, hasDifficultyScaling)

    mSettings.updatePercentArgument(mSettings.cfg.magicDamagePercent.key, hasGlobalOverride, hasDifficultyScaling)
    updateActualPercent(mSettings.cfg.magicDamagePercent.key,
            globalOverrideKey and globalOverrideKey or mSettings.cfg.magicDamagePercent.key,
            hasDifficultyScaling)

    mSettings.updatePercentArgument(mSettings.cfg.sunDamagePercent.key, hasGlobalOverride, hasDifficultyScaling)
    updateActualPercent(mSettings.cfg.sunDamagePercent.key,
            globalOverrideKey and globalOverrideKey or mSettings.cfg.sunDamagePercent.key,
            hasDifficultyScaling)

    mSettings.updatePercentArgument(mSettings.cfg.attributesGlobalPercent.key, hasGlobalOverride, hasDifficultyScaling)
    updateActualPercent(mSettings.cfg.attributesGlobalPercent.key,
            globalOverrideKey and globalOverrideKey or (
                    hasAttributesGlobalPercent and mSettings.cfg.attributesGlobalPercent.key or nil),
            hasDifficultyScaling)
    for attributeId in pairs(T.Actor.stats.attributes) do
        mSettings.updatePercentArgument(mSettings.percentKey(attributeId), hasGlobalOverride or hasAttributesGlobalPercent, hasDifficultyScaling)
        updateActualPercent(mSettings.percentKey(attributeId),
                globalOverrideKey and globalOverrideKey or (
                        hasAttributesGlobalPercent and mSettings.cfg.attributesGlobalPercent.key or mSettings.percentKey(attributeId)),
                hasDifficultyScaling)
    end

    mSettings.updatePercentArgument(mSettings.cfg.dynamicStatsGlobalPercent.key, hasGlobalOverride, hasDifficultyScaling)
    updateActualPercent(mSettings.cfg.dynamicStatsGlobalPercent.key,
            globalOverrideKey and globalOverrideKey or (
                    hasDynamicStatsGlobalPercent and mSettings.cfg.dynamicStatsGlobalPercent.key or nil),
            hasDifficultyScaling)
    for statId in pairs(T.Actor.stats.dynamic) do
        mSettings.updatePercentArgument(mSettings.percentKey(statId), hasGlobalOverride or hasDynamicStatsGlobalPercent, hasDifficultyScaling)
        updateActualPercent(mSettings.percentKey(statId),
                globalOverrideKey and globalOverrideKey or (
                        hasDynamicStatsGlobalPercent and mSettings.cfg.dynamicStatsGlobalPercent.key or mSettings.percentKey(statId)),
                hasDifficultyScaling)
    end
end

local function setPlayerLevel()
    state.playerLevel = mTools.average(world.players, function(player) return T.Actor.stats.level(player).current end)
end

local function onUpdate(deltaTime)
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 1 then return end
    deltaTime = lastUpdateTime
    lastUpdateTime = 0

    lastConfigurationCheckTime = lastConfigurationCheckTime + deltaTime
    if lastConfigurationCheckTime > 20 then
        lastConfigurationCheckTime = 0
        if state.settings[mSettings.cfg.enabled.key] and state.actualSettings.areDefault then
            for _, player in ipairs(world.players) do
                player:sendEvent("hbfs_showMessage", mSettings.l10n("needsConfiguration"))
            end
        end
    end

    local prevLevel = state.playerLevel
    setPlayerLevel()
    if state.playerLevel ~= prevLevel then
        updateSettings(false)
        updateAllActorsStats(true)
    end
end

local function updateSetting(key)
    local settingCopy = mSettings.getSection(key):getCopy(key)
    local init = false
    if type(settingCopy) == "table" and settingCopy.actual then
        -- init if a reset happened and we need to re-compute actual values
        init = settingCopy.actual ~= state.settings[key].actual
    end
    state.settings[key] = settingCopy
    if key ~= mSettings.cfg.debugMode.key then
        -- use event to prevent openmw to complain about infinite call loop risk when updating settings of same section
        core.sendGlobalEvent("hbfs_updateSettings", init)
    end
end

mSettings.globalSection():subscribe(async:callback(function(_, key) updateSetting(key) end))
mSettings.playerSection():subscribe(async:callback(function(_, key) updateSetting(key) end))
mSettings.actorsSection():subscribe(async:callback(function(_, key) updateSetting(key) end))

local function copySettings()
    for key in pairs(mSettings.cfg) do
        state.settings[key] = mSettings.getSection(key):getCopy(key)
    end
end

local function onInit()
    setPlayerLevel()
    copySettings()
    updateSettings(true)
    updateAllActorsStats(false)
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data and data.version == mDef.saveVersion then
        state = data.state
    end
    onInit()
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getSettings = function() return state.actualSettings end,
        getState = function() return state end,
    },
    eventHandlers = {
        Unpause = function() updateAllActorsStats(false) end,
        hbfs_updateSettings = updateSettings,
    },
    engineHandlers = {
        onInit = onInit,
        onActorActive = onActorActive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}