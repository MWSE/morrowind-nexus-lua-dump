local core = require('openmw.core')
local T = require('openmw.types')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

local mDef = require('scripts.HBFS.config.definition')
if not mDef.isOpenMW49OrAbove then return end

local mS = require('scripts.HBFS.config.settings')
local log = require('scripts.HBFS.util.log')
local mCfg = require('scripts.HBFS.config.configuration')
local mStore = require('scripts.HBFS.config.store')
local mWorld = require('scripts.HBFS.util.world')
local mTools = require('scripts.HBFS.util.tools')

local l10n = core.l10n(mDef.MOD_NAME)

local lastUpdateTime = 0
local settingsChanged = false

local state = {
    playerLevel = 1,
    settingsKey = "",
    settings = {},
    openedContainers = {},
    actors = {},
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

local function updateAllActorsStats(isLevelUp)
    local actualSettingsKey = state.actualSettings.key
    mS.setActualSettings(state)
    if actualSettingsKey == state.actualSettings.key then return end

    log(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        if not isLevelUp and T.Player.isCharGenFinished(player) then
            player:sendEvent(mDef.events.showMessage, l10n("updateActorsStats"))
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player then
            actor:sendEvent(mDef.events.updateActorStats, { settings = mS.getScaledSettings(state, actor), type = isLevelUp and eventTypes.rescale or eventTypes.reset })
        end
    end
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
    mS.updateSettingDependencies(state, true, hasScaling)
    for key, ratio in pairs(mCfg.presetPercentRatios) do
        state.settings[key].base = mCfg.defaultPercent * (1 + presetBase * ratio)
        state.settings[key].increase = ratio * presetIncrease * mCfg.defaultPercent
        mS.updatePercentSetting(state, key)
        mStore.updatePercentArgument(key, true, hasScaling, perActor)
    end
end

local function updatePercentSettings()
    if state.settings[mStore.settings.presetsEnabled.key] then
        applyPreset()
        return
    end
    local hasScaling = state.settings[mStore.settings.difficultyScaling.key]
    mS.updateSettingDependencies(state, false, hasScaling)
    for key, setting in pairs(mStore.settings) do
        if setting.isPercent then
            if not hasScaling then
                -- Ensure the increase is cleared when there are old residual settings
                state.settings[key].increase = 0
            end
            mS.updatePercentSetting(state, key)
            mStore.updatePercentArgument(key, false, hasScaling)
        end
    end
end

local function setPlayerLevel()
    state.playerLevel = mTools.average(world.players, function(player) return T.Actor.stats.level(player).current end)
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

local function getItemConditionRatio(loot, lootProps)
    local record = loot.type.record(loot)
    local ratio
    local reason
    if loot.type == T.Container then
        if lootProps.submerged then
            ratio = math.random() ^ 2 * 1 / 2
            reason = "is submerged"
        else
            ratio = 1
            reason = "nothing to do"
        end
    elseif lootProps.isCorpse then
        ratio = math.random() ^ 2 * 1 / 2
        reason = "is a corpse"
    elseif loot.type == T.Creature and record.type == T.Creature.TYPE.Undead then
        ratio = 1 / 4 + math.random() * 1 / 4
        reason = "is an undead"
    elseif record.class == "guard" then
        ratio = math.min(1, 15 / 16 + math.random() * 1 / 8)
        reason = "is a guard"
    else
        lootProps.baseFightValue = lootProps.baseFightValue or T.Actor.stats.ai.fight(loot).base
        ratio = math.max(0, math.min(1, (1 - (lootProps.baseFightValue / 100) ^ 2) - 1 / 4 + math.random() * 1 / 2))
        reason = string.format("has a base fight value of %d", lootProps.baseFightValue)
    end
    return ratio, reason
end

local function commitTheft(player, value)
    local crimeLevel = T.Player.getCrimeLevel(player)
    local output = I.Crimes.commitCrime(player, { arg = value, type = T.Player.OFFENSE_TYPE.Theft })
    if output.wasCrimeSeen and crimeLevel == T.Player.getCrimeLevel(player) then
        T.Player.setCrimeLevel(player, crimeLevel + value)
    end
end

local function degradeLootItems(loot, lootProps)
    local inventory = loot.type.inventory(loot)
    for _, type in ipairs({ T.Armor, T.Weapon }) do
        for _, item in ipairs(inventory:getAll(type)) do
            local condition = T.Item.itemData(item).condition
            if condition then
                local conditionRatio, reason = getItemConditionRatio(loot, lootProps)
                T.Item.itemData(item).condition = math.floor(condition * conditionRatio)
                log(string.format("Changed \"%s\"'s item '\"%s\" condition from %d to %d (ratio %.2f) because he %s",
                        loot.recordId, item.recordId, condition, condition * conditionRatio, conditionRatio, reason))
            end
        end
    end
end

local function onInit()
    setPlayerLevel()
    mS.copySettings(state)
    updatePercentSettings()
    updateAllActorsStats(false)
end

local function onActorActive(actor)
    actor:sendEvent(mDef.events.setActorStats, { settings = mS.getScaledSettings(state, actor), type = eventTypes.set })
end

local function onActorDied(actor)
    if not state.settings[mStore.settings.conditionalItemDegradation.key] then return end
    local data = state.actors[actor.id] or {}
    log(string.format("%s died, his equipment will be degraded", mTools.objectId(actor)))
    degradeLootItems(actor, data)
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

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version < 2.52 then
            data.state.openedContainers = {}
        end
        if data.version < 2.6 then
            data.state.actors = {}
        end
        if data.version == 2.6 then
            local newActors = {}
            for id, actorData in pairs(data.state.actors) do
                actorData.baseFightValue = nil
                if actorData.isCorpse then
                    newActors[id] = actorData
                end
            end
            data.state.actors = newActors
        end
        state = data.state
    end
    mWorld.fixObjects({ openedContainers = state.openedContainers, actors = state.actors })
    onInit()
end

local function onOpenContainer(container)
    if not container or not state.settings[mStore.settings.conditionalItemDegradation.key] then return end
    local waterLevel = container.cell.waterLevel
    if waterLevel and waterLevel > container.position.z then
        if state.openedContainers[container.id] then return end
        state.openedContainers[container.id] = { object = container }
        log(string.format("%s is submerged, its content will be degraded", mTools.objectId(container)))
        degradeLootItems(container, { submerged = true })
    end
end

local function initActorData(actor, newData)
    local data = state.actors[actor.id]
    if not data then
        data = { object = actor }
        state.actors[actor.id] = data
    end
    for key, value in pairs(newData) do
        if not data[key] then
            log(string.format("%s has new data: %s = %s", mTools.objectId(actor), key, value))
            data[key] = value
        end
    end
    if newData.isCorpse then
        log(string.format("%s is a corpse, his equipment will be degraded", mTools.objectId(actor)))
        degradeLootItems(actor, newData)
    end
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
        [mDef.events.forwardToPlayers] = function(data) mWorld.forwardToPlayers(data.data, data.event) end,
        [mDef.events.updatePercentSetting] = function(key) mS.updatePercentSetting(state, key) end,
        [mDef.events.updatePercentSettings] = updatePercentSettings,
        [mDef.events.moveItem] = function(data) mWorld.moveItem(data.item, data.actor) end,
        [mDef.events.modItemCondition] = function(data) mWorld.modItemCondition(data.updates, data.refreshUi) end,
        [mDef.events.commitTheft] = function(data) commitTheft(data.player, data.value) end,
        [mDef.events.onActorDied] = onActorDied,
        [mDef.events.onOpenContainer] = onOpenContainer,
        [mDef.events.initActorData] = function(data) initActorData(data.actor, data.data) end,
    },
    engineHandlers = {
        onInit = onInit,
        onActorActive = onActorActive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}