local core = require('openmw.core')
local T = require('openmw.types')
local I = require('openmw.interfaces')
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
        excludeNPCFollowers = nil,
        excludeCreatureFollowers = nil,
        noBackRunningActors = nil,
        key = "",
    },
}

local eventTypes = {
    set = "set",
    reset = "reset",
    rescale = "rescale",
}

local function getPerActorSetting(getValue)
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

local function getScaledSettings(actor)
    if state.settings[mStore.settings.difficultyScaling.key] then
        if state.settings[mStore.settings.boostOnlyWeakerActors.key] then
            local actorLevel = math.max(1, T.Actor.stats.level(actor).current)
            return getPerActorSetting(function(values)
                return values.base + math.max(0, state.playerLevel - actorLevel) * values.increase
            end)
        end
    elseif state.settings[mStore.settings.actorLevelBasedBoost.key] then
        local actorLevel = math.min(100, math.max(1, T.Actor.stats.level(actor).current))
        return getPerActorSetting(function(values)
            return mCfg.defaultPercent + (values.base - mCfg.defaultPercent) / (1 + (actorLevel / 50) ^ 4)
        end)
    end
    return state.actualSettings
end

local function onActorActive(actor)
    actor:sendEvent(mDef.events.onActorActive, { settings = getScaledSettings(actor), type = eventTypes.set })
end

local function setActualSettings()
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

local function updateAllActorsStats(isLevelUp)
    local actualSettingsKey = state.actualSettings.key
    setActualSettings()
    if actualSettingsKey == state.actualSettings.key then return end

    log(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        if not isLevelUp and T.Player.isCharGenFinished(player) then
            player:sendEvent(mDef.events.showMessage, l10n("updateActorsStats"))
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player then
            actor:sendEvent(mDef.events.updateActorStats, { settings = getScaledSettings(actor), type = isLevelUp and eventTypes.rescale or eventTypes.reset })
        end
    end
end

local function updatePercentSetting(key)
    state.settings[key].actual = state.settings[key].base + state.playerLevel * state.settings[key].increase
    mStore.settings[key].set(state.settings[key])
end

local function updateSettingDependencies(hasPreset, hasScaling)
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

local function applyPreset()
    local presetBase = mCfg.presetBaseRatios[state.settings[mStore.settings.presetBase.key]]
    local presetIncrease = mCfg.presetIncreaseRatios[state.settings[mStore.settings.presetIncrease.key]]
    local hasScaling = state.settings[mStore.settings.difficultyScaling.key]
    local perActor = state.settings[mStore.settings.boostOnlyWeakerActors.key] or state.settings[mStore.settings.actorLevelBasedBoost.key]
    local toggleScaling = (presetIncrease > 0) ~= hasScaling
    if toggleScaling then
        mStore.settings.difficultyScaling.set(not hasScaling)
        return
    end
    updateSettingDependencies(true, hasScaling)
    for key, ratio in pairs(mCfg.presetPercentRatios) do
        state.settings[key].base = mCfg.defaultPercent * (1 + presetBase * ratio)
        state.settings[key].increase = ratio * presetIncrease * mCfg.defaultPercent
        updatePercentSetting(key)
        mStore.updatePercentArgument(key, true, hasScaling, perActor)
    end
end

local function updatePercentSettings()
    if state.settings[mStore.settings.presetsEnabled.key] then
        applyPreset()
        return
    end
    local hasScaling = state.settings[mStore.settings.difficultyScaling.key]
    updateSettingDependencies(false, hasScaling)
    for key, setting in pairs(mStore.settings) do
        if setting.isPercent then
            if not hasScaling then
                -- Ensure the increase is cleared when there are old residual settings
                state.settings[key].increase = 0
            end
            updatePercentSetting(key)
            mStore.updatePercentArgument(key, false, hasScaling)
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
        updatePercentSettings()
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

local function getItemConditionRatio(actor, actorState)
    local record = actor.type.record(actor)
    local ratio
    local reason
    if actorState.isCorpse then
        ratio = math.random() ^ 2 * 1 / 2
        reason = "is a corpse"
    elseif actor.type == T.Creature and record.type == T.Creature.TYPE.Undead then
        ratio = 1 / 4 + math.random() * 1 / 4
        reason = "is an undead"
    elseif record.class == "guard" then
        ratio = math.min(1, 15 / 16 + math.random() * 1 / 8)
        reason = "is a guard"
    else
        ratio = math.max(0, math.min(1, (1 - (actorState.baseFightValue / 100) ^ 2) - 1 / 4 + math.random() * 1 / 2))
        reason = string.format("has a base fight value of %d", actorState.baseFightValue)
    end
    return ratio, reason
end

local function forwardToPlayers(data, event)
    for _, player in ipairs(world.players) do
        player:sendEvent(event, data)
    end
end

local function commitTheft(player, value)
    local crimeLevel = T.Player.getCrimeLevel(player)
    local output = I.Crimes.commitCrime(player, { arg = value, type = T.Player.OFFENSE_TYPE.Theft })
    if output.wasCrimeSeen and crimeLevel == T.Player.getCrimeLevel(player) then
        T.Player.setCrimeLevel(player, crimeLevel + value)
    end
end

local function moveItem(item, actor)
    log(string.format("Item \"%s\" moved into \"%s\"'s inventory", item.recordId, actor.recordId))
    item:moveInto(actor.type.inventory(actor))
end

local function onActorDied(actor, actorState)
    if not state.settings[mStore.settings.deathDamagesEquipmentCondition.key] then return end
    local inventory = actor.type.inventory(actor)
    for _, type in ipairs({ T.Armor, T.Weapon }) do
        for _, item in ipairs(inventory:getAll(type)) do
            local condition = T.Item.itemData(item).condition
            if condition then
                local conditionRatio, reason = getItemConditionRatio(actor, actorState)
                T.Item.itemData(item).condition = math.floor(condition * conditionRatio)
                log(string.format("Changed \"%s\"'s item '\"%s\" condition from %d to %d (ratio %.2f) because he %s",
                        actor.recordId, item.recordId, condition, condition * conditionRatio, conditionRatio, reason))
            end
        end
    end
end

local function onInit()
    setPlayerLevel()
    copySettings()
    updatePercentSettings()
    updateAllActorsStats(false)
end

local function onSave()
    return {
        state = state,
        version = mDef.gameSaveVersion,
    }
end

local function onLoad(data)
    state = data and data.state or state
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
        [mDef.events.forwardToPlayers] = function(data) forwardToPlayers(data.data, data.event) end,
        [mDef.events.moveItem] = function(data) moveItem(data.item, data.actor) end,
        [mDef.events.commitTheft] = function(data) commitTheft(data.player, data.value) end,
        [mDef.events.onActorDied] = function(data) onActorDied(data.actor, data.state) end,
    },
    engineHandlers = {
        onInit = onInit,
        onActorActive = onActorActive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}