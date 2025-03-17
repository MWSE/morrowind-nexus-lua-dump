local core = require('openmw.core')
local T = require('openmw.types')
local async = require('openmw.async')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

require('scripts.HBFS.config.settings')
local mDef = require('scripts.HBFS.config.definition')
local mCfg = require('scripts.HBFS.config.configuration')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')
local log = require('scripts.HBFS.util.log')

local l10n = core.l10n(mDef.MOD_NAME)

local lastUpdateTime = 0
local settingsChanged = false

local state = {
    playerLevel = 1,
    settingsKey = "",
    settings = {},
    actualSettings = {
        attributes = {},
        dynamicStats = {},
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
    actor:sendEvent(mDef.events.onActorActive, { settings = state.actualSettings, type = eventTypes.set })
end

local function setActualSettingsKey()
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
    state.actualSettings.key = table.concat(keyItems, ",")
end

local function updateAllActorsStats(isLevelUp)
    local actualSettingsKey = state.actualSettings.key
    setActualSettingsKey()
    if actualSettingsKey == state.actualSettings.key then return end

    log(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        if T.Player.isCharGenFinished(player) then
            player:sendEvent(mDef.events.showMessage, l10n(state.actualSettings.areActorsDefault and "resetActorsStats" or "updateActorsStats"))
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player then
            actor:sendEvent(mDef.events.updateActorStats, { settings = state.actualSettings, type = isLevelUp and eventTypes.rescale or eventTypes.reset })
        end
    end
end

local function updateActualValue(key)
    state.settings[key].actual = state.settings[key].base + state.playerLevel * state.settings[key].increase
    mStore.settings[key].set(state.settings[key])
end

local function checkActorsDefault(setting)
    if setting.section.key == mCfg.sections.actors.key and state.settings[setting.key].actual ~= mCfg.defaultPercent then
        state.actualSettings.areActorsDefault = false
    end
end

local function updatePercentSetting(settingKey)
    updateActualValue(settingKey)

    state.actualSettings.areActorsDefault = true
    for _, setting in pairs(mStore.settings) do
        if setting.isPercent then
            checkActorsDefault(setting)
        end
    end
end

local function applyPreset()
    local presetBase = mCfg.presetBaseRatios[state.settings[mStore.settings.presetBase.key]]
    local presetIncrease = mCfg.presetIncreaseRatios[state.settings[mStore.settings.presetIncrease.key]]
    local hasScaling = state.settings[mStore.settings.difficultyScaling.key]
    local toggleScaling = (presetIncrease > 0) ~= hasScaling
    if toggleScaling then
        mStore.settings.difficultyScaling.set(not hasScaling)
        return
    end
    mStore.setDisabled(mStore.settings.presetBase.key, false)
    mStore.setDisabled(mStore.settings.presetIncrease.key, false)
    mStore.setDisabled(mStore.settings.difficultyScaling.key, true)
    state.actualSettings.areActorsDefault = true
    for key, ratio in pairs(mCfg.presetPercentRatios) do
        state.settings[key].base = mCfg.defaultPercent * (1 + presetBase * ratio)
        state.settings[key].increase = ratio * presetIncrease * mCfg.defaultPercent
        updateActualValue(key)
        mStore.updatePercentArgument(key, true, hasScaling)
        checkActorsDefault(mStore.settings[key])
    end
end

local function updatePercentSettings()
    if state.settings[mStore.settings.presetsEnabled.key] then
        applyPreset()
        return
    end
    mStore.setDisabled(mStore.settings.presetBase.key, true)
    mStore.setDisabled(mStore.settings.presetIncrease.key, true)
    mStore.setDisabled(mStore.settings.difficultyScaling.key, false)
    state.actualSettings.areActorsDefault = true
    for key, setting in pairs(mStore.settings) do
        if setting.isPercent then
            updateActualValue(key)
            mStore.updatePercentArgument(key, false, state.settings[mStore.settings.difficultyScaling.key])
            checkActorsDefault(setting)
        end
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

    local prevLevel = state.playerLevel
    setPlayerLevel()
    if state.playerLevel ~= prevLevel then
        updatePercentSettings(false)
        updateAllActorsStats(true)
    end
end

local function applySettings()
    if not settingsChanged then return end
    settingsChanged = false

    updateAllActorsStats(false)

    for key, setting in pairs(mStore.settings) do
        if setting.section.key == mStore.sections.player.key then
            for _, player in ipairs(world.players) do
                player:sendEvent(mDef.events.updatePlayerSetting, { key = key, value = state.settings[key] })
            end
        end
    end
end

local function updateSetting(key)
    settingsChanged = true
    local setting = mStore.settings[key].getCopy()
    local isPercent = mStore.settings[key].isPercent
    -- Also check change on actual value in case of the Reset button is pressed
    if mStore.settings[key].updatePercents or isPercent and setting.actual ~= state.settings[key].actual then
        core.sendGlobalEvent(mDef.events.updatePercentSettings)
    elseif isPercent and (setting.base ~= state.settings[key].base or setting.increase ~= state.settings[key].increase) then
        core.sendGlobalEvent(mDef.events.updatePercentSetting, key)
    end
    state.settings[key] = setting
end

local function copySettings()
    for key, setting in pairs(mStore.settings) do
        state.settings[key] = setting.getCopy()
    end
end

local function onInit()
    setPlayerLevel()
    copySettings()
    updatePercentSettings(true)
    updateAllActorsStats(false)
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version < 1.5 then
            mStore.settings.presetsEnabled.set(false)
        end
        state = data.state
    end
    onInit()
end

for _, section in pairs(mStore.sections) do
    section.get():subscribe(async:callback(function(_, key) updateSetting(key) end))
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getSettings = function() return state.actualSettings end,
        getState = function() return state end,
    },
    eventHandlers = {
        Unpause = applySettings,
        [mDef.events.updatePercentSetting] = updatePercentSetting,
        [mDef.events.updatePercentSettings] = updatePercentSettings,
    },
    engineHandlers = {
        onInit = onInit,
        onActorActive = onActorActive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}