local core = require('openmw.core')
local T = require('openmw.types')
local async = require('openmw.async')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

require('scripts.HBFS.settings_global')
local mSettings = require('scripts.HBFS.settings')
local mTools = require('scripts.HBFS.tools')

local initialized = false
local shouldUpdateActorsStats = false
local lastUpdateTime = 0

local state = {
    playerLevel = 1,
    settingsKey = "",
    settings = {},
    actualSettings = {
        attributes = {},
        dynamicStats = {},
        areDefault = true,
    },
}

local function onActorActive(actor)
    if state.actualSettings.areDefault
            or actor.type == T.Player
            or not state.settings[mSettings.cfg.enabled.key] then return end

    --mTools.debugPrint(string.format("%s is active", mTools.actorId(actor)))
    actor:sendEvent("hbfs_updateStats", state.actualSettings)
end

local function updateAllActorsStats()
    if not shouldUpdateActorsStats then return end
    shouldUpdateActorsStats = false

    for attributeId in pairs(T.Actor.stats.attributes) do
        state.actualSettings.attributes[attributeId] = state.settings[mSettings.percentKey(attributeId)].actual
    end
    for statId in pairs(T.Actor.stats.dynamic) do
        state.actualSettings.dynamicStats[statId] = state.settings[mSettings.percentKey(statId)].actual
    end
    mTools.debugPrint(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        player:sendEvent("hbfs_showMessage", mSettings.l10n(state.actualSettings.areDefault and "resetActorsStats" or "updateActorsStats"))
    end
    for _, actor in ipairs(world.activeActors) do
        actor:sendEvent("hbfs_updateStats", state.actualSettings)
    end
end

local function getSettingsKey(hasDynamicIncrease)
    local settingsValues = {}
    if hasDynamicIncrease then
        table.insert(settingsValues, tostring(state.playerLevel))
    end
    for key, setting in pairs(state.settings) do
        if type(setting) == "table" and setting.base then
            -- Exclude actual value to prevent infinite subscribe callback loop
            table.insert(settingsValues, string.format("%s:%s_%s_%s", key, setting.checked, setting.base, setting.increase))
        else
            table.insert(settingsValues, string.format("%s:%s", key, tostring(setting)))
        end
    end
    return table.concat(settingsValues, ",")
end

local function updateActualPercent(key, overrideKey)
    local override
    if state.settings[mSettings.cfg.enabled.key] then
        override = overrideKey and state.settings[overrideKey].base or nil
    else
        override = mSettings.defaultPercent
    end
    if overrideKey and state.settings[mSettings.cfg.dynamicIncrease.key] then
        local increase = state.settings[mSettings.cfg.enabled.key] and state.settings[overrideKey].increase or mSettings.defaultPercent
        override = override + state.playerLevel * increase
    end
    if state.settings[key].actual ~= override then
        state.settings[key].actual = override
        mSettings.getSection(key):set(key, state.settings[key])
    end
    if state.settings[key].actual ~= mSettings.defaultPercent then
        state.actualSettings.areDefault = false
    end
end

local function updateSettings()
    local hasDynamicIncrease = state.settings[mSettings.cfg.dynamicIncrease.key]
    local newSettingsKey = getSettingsKey(hasDynamicIncrease)
    if state.settingsKey == newSettingsKey then return end
    state.settingsKey = newSettingsKey
    shouldUpdateActorsStats = true

    state.actualSettings.areDefault = true

    local hasGlobalPercent = state.settings[mSettings.cfg.globalPercent.key].checked
    local hasAttributesGlobalPercent = state.settings[mSettings.cfg.attributesGlobalPercent.key].checked
    local hasDynamicStatsGlobalPercent = state.settings[mSettings.cfg.dynamicStatsGlobalPercent.key].checked

    mSettings.updatePercentArgument(mSettings.cfg.globalPercent.key, false, hasDynamicIncrease)
    updateActualPercent(mSettings.cfg.globalPercent.key,
            hasGlobalPercent
                    and mSettings.cfg.globalPercent.key
                    or nil)

    mSettings.updatePercentArgument(mSettings.cfg.magicDamagePercent.key, hasGlobalPercent, hasDynamicIncrease)
    updateActualPercent(mSettings.cfg.magicDamagePercent.key,
            hasGlobalPercent
                    and mSettings.cfg.globalPercent.key
                    or mSettings.cfg.magicDamagePercent.key)

    mSettings.updatePercentArgument(mSettings.cfg.attributesGlobalPercent.key, hasGlobalPercent, hasDynamicIncrease)
    updateActualPercent(mSettings.cfg.attributesGlobalPercent.key,
            hasGlobalPercent
                    and mSettings.cfg.globalPercent.key
                    or (hasAttributesGlobalPercent and mSettings.cfg.attributesGlobalPercent.key or nil))
    for attributeId in pairs(T.Actor.stats.attributes) do
        mSettings.updatePercentArgument(mSettings.percentKey(attributeId), hasGlobalPercent or hasAttributesGlobalPercent, hasDynamicIncrease)
        updateActualPercent(mSettings.percentKey(attributeId),
                hasGlobalPercent
                        and mSettings.cfg.globalPercent.key
                        or (hasAttributesGlobalPercent and mSettings.cfg.attributesGlobalPercent.key or mSettings.percentKey(attributeId)))
    end

    mSettings.updatePercentArgument(mSettings.cfg.dynamicStatsGlobalPercent.key, hasGlobalPercent, hasDynamicIncrease)
    updateActualPercent(mSettings.cfg.dynamicStatsGlobalPercent.key,
            hasGlobalPercent
                    and mSettings.cfg.globalPercent.key
                    or (hasDynamicStatsGlobalPercent and mSettings.cfg.dynamicStatsGlobalPercent.key or nil))
    for statId in pairs(T.Actor.stats.dynamic) do
        mSettings.updatePercentArgument(mSettings.percentKey(statId), hasGlobalPercent or hasDynamicStatsGlobalPercent, hasDynamicIncrease)
        updateActualPercent(mSettings.percentKey(statId),
                hasGlobalPercent
                        and mSettings.cfg.globalPercent.key
                        or (hasDynamicStatsGlobalPercent and mSettings.cfg.dynamicStatsGlobalPercent.key or mSettings.percentKey(statId)))
    end
end

local function setPlayerLevel()
    state.playerLevel = mTools.average(world.players, function(player) return T.Actor.stats.level(player).current end)
end

local function onUpdate(deltaTime)
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 1 then return end
    lastUpdateTime = 0

    local prevLevel = state.playerLevel
    setPlayerLevel()
    if state.playerLevel ~= prevLevel then
        updateSettings()
        updateAllActorsStats()
    end
end

local function updateSetting(key)
    state.settings[key] = mSettings.getSection(key):getCopy(key)
    if key ~= mSettings.cfg.debugMode.key then
        -- use event to prevent openmw to complain about infinite call loop risk when updating settings of same section
        core.sendGlobalEvent("hbfs_updateSettings")
    end
end

mSettings.globalSection():subscribe(async:callback(function(_, key)
    updateSetting(key)
end))

mSettings.playerSection():subscribe(async:callback(function(_, key)
    updateSetting(key)
end))

mSettings.actorsSection():subscribe(async:callback(function(_, key)
    updateSetting(key)
end))

local function onInit()
    setPlayerLevel()
    for key in pairs(mSettings.cfg) do
        state.settings[key] = mSettings.getSection(key):getCopy(key)
    end
    updateSettings()
    updateAllActorsStats()
    initialized = true
end

local function onSave()
    return {
        state = state,
        version = mSettings.saveVersion,
    }
end

local function onLoad(data)
    if data.version == mSettings.saveVersion then
        state = data.state
    else
        onInit()
    end
end

return {
    eventHandlers = {
        Unpause = updateAllActorsStats,
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
