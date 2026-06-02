local core = require('openmw.core')
local world = require('openmw.world')
local async = require('openmw.async')
local T = require("openmw.types")
local I = require("openmw.interfaces")

local mStore = require("scripts.MRF.config.store")
mStore.registerGroups()
local mDef = require("scripts.MRF.config.definition")
local mMagic = require("scripts.MRF.util.magic")
local mH = require("scripts.MRF.util.helpers")
local log = require("scripts.MRF.util.log")

local state = {
    actors = {},
    lastAppTime = nil,
    appPausedDuration = 0, -- to exclude the real time passed during the app inactivity (e.g. alt-tab)
    lastUnpausedGameTime = nil,
    gamePausedDuration = 0,
    lastUnpausedDialogueTime = nil,
    dialoguePausedDuration = 0,
}

local uiModesToRefresh = {
    MerchantRepair = true,
    SpellBuying = true,
    Training = true,
    Travel = true,
}

local lastAppTimeDiff = 0 -- approximation of a normal frame duration
local lastSpellCheckTime = core.getRealTime()
local currUiMode
local currPlayer
local currInterlocutor

local refreshActiveSpellCallback = async:registerTimerCallback(mDef.callbacks.refreshActiveSpell, function(data)
    if not mStore.settings.enforceConstantEnchantmentDebuffs.get() then return end
    mMagic.refreshActiveItemSpell(data.actor, data.item, data.effectIndexes)
end)

local function onEquip(item, actor)
    if not mStore.settings.enforceConstantEnchantmentDebuffs.get() then return end
    if actor.type ~= T.Player then return end
    local constantEffects = mMagic.getConstantEffects(item)
    if not constantEffects then return end
    local resistEffects = mMagic.getResistEffectsForEffects(constantEffects)
    if not next(resistEffects) then return end
    for _, duration in pairs(mMagic.getActorSpecificEffectDurations(actor, resistEffects)) do
        async:newSimulationTimer(
                duration,
                refreshActiveSpellCallback,
                { actor = actor, item = item, effectIndexes = mH.countToList(constantEffects) })
    end
end

local function initActiveSpellChecks(actor)
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.temporary and (not state.actors[actor.id] or not state.actors[actor.id].spellEffects[spell.activeSpellId]) then
            local trackedEffects, otherEffects = mMagic.getRealTimeEffects(spell)
            if #trackedEffects > 0 then
                state.actors[actor.id] = state.actors[actor.id] or { object = actor, spellEffects = {} }
                local effects = mMagic.getActiveSpellEffectExpirations(
                        trackedEffects,
                        otherEffects,
                        mStore.settings.minMagicEffectDurationForPausedDialogue.get())
                state.actors[actor.id].spellEffects[spell.activeSpellId] = effects
                log(string.format("Tracking active spell \"%s\" (\"%s\") for actor %s, expirations: %s",
                        spell.id, spell.activeSpellId, mH.objectId(actor), mMagic.effectsToExpirations(effects, core.getRealTime())))
            end
        end
    end
end

local function getAbsorbedActiveActors(excludedActor)
    local actors = {}
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player and actor.id ~= excludedActor.id and mMagic.hasTrackedEffects(actor) then
            actors[#actors + 1] = actor
        end
    end
    return actors
end

local function onUiChanged(uiMode, player, target)
    currUiMode = uiMode
    currPlayer = player
    if target == currInterlocutor then return end
    if type(target) ~= "userdata" or not T.NPC.objectIsInstance(target) then
        currInterlocutor = nil
        return
    end
    initActiveSpellChecks(player)
    initActiveSpellChecks(target)
    for _, actor in ipairs(getAbsorbedActiveActors(player)) do
        initActiveSpellChecks(actor)
    end
    currInterlocutor = target
end

local function refreshSpell(actor, currSpell, updatedSpell)
    local pauseTags = world.getPausedTags()
    for tag, _ in pairs(pauseTags) do
        world.unpause(tag)
    end
    core.sendGlobalEvent(mDef.events.refreshSpell, {
        actor = actor,
        prevActiveSpellId = currSpell.activeSpellId,
        updatedSpell = updatedSpell,
        pauseTags = pauseTags,
    })
end

local function refreshSpellCallback(actor, prevActiveSpellId, updatedSpell, pauseTags)
    for tag, _ in pairs(pauseTags) do
        world.pause(tag)
    end
    local actorData = state.actors[actor.id]
    if not actorData then
        print("Could not find actor %s data", mH.objectId(actor))
        return
    end
    local activeSpells = T.Actor.activeSpells(actor)
    for _, spell in pairs(activeSpells) do
        if spell.id == updatedSpell.id and #spell.effects == #updatedSpell.effects then
            log(string.format("Refreshing spell \"%s\" (active id \"%s\") for actor %s, expirations: %s",
                    spell.id, spell.activeSpellId, mH.objectId(actor),
                    mMagic.effectsToExpirations(actorData.spellEffects[prevActiveSpellId], core.getRealTime())))
            actorData.spellEffects[spell.activeSpellId] = actorData.spellEffects[prevActiveSpellId]
            actorData.spellEffects[prevActiveSpellId] = nil
            return
        end
    end
    actorData.spellEffects[prevActiveSpellId] = nil
end

local function setPauseTimes(realTime)
    local appTimeDiff = realTime - (state.lastAppTime or realTime)
    if appTimeDiff > 0.1 then
        -- the app was inactive (e.g. alt-tab)
        state.appPausedDuration = state.appPausedDuration + appTimeDiff - lastAppTimeDiff
    else
        -- save a "normal" frame duration
        lastAppTimeDiff = appTimeDiff
    end
    if core.isWorldPaused() then
        state.gamePausedDuration = state.gamePausedDuration + realTime - (state.lastUnpausedGameTime or realTime)
        if not currInterlocutor then
            state.dialoguePausedDuration = state.dialoguePausedDuration + realTime - (state.lastUnpausedDialogueTime or realTime)
            return false
        end
    end
    return true
end

local function checkActiveSpells()
    if not next(state.actors) then return end
    local realTime = core.getRealTime()
    local continue = setPauseTimes(realTime)
    state.lastAppTime = realTime
    state.lastUnpausedGameTime = realTime
    state.lastUnpausedDialogueTime = realTime
    if not continue then return end

    if realTime - lastSpellCheckTime < 0.5 then return end
    lastSpellCheckTime = realTime

    local appPausedDuration = state.appPausedDuration
    state.lastAppTime = nil
    state.appPausedDuration = 0
    if appPausedDuration ~= 0 then
        log(string.format("Paused app last %.2fs", appPausedDuration))
    end
    local gamePausedDuration = state.gamePausedDuration
    state.lastUnpausedGameTime = nil
    state.gamePausedDuration = 0
    if gamePausedDuration ~= 0 then
        log(string.format("Paused game last %.2fs", gamePausedDuration))
    end
    local dialoguePauseDuration = state.dialoguePausedDuration
    state.lastUnpausedDialogueTime = nil
    state.dialoguePausedDuration = 0
    if dialoguePauseDuration ~= 0 then
        log(string.format("Paused dialogue last %.2fs", dialoguePauseDuration))
    end

    local actorsToClear = {}
    for actorId, actorData in pairs(state.actors) do
        if mH.isObjectInvalid(actorData.object) then
            -- most likely expired summons
            actorsToClear[#actorsToClear + 1] = actorId
        else
            local currSpells = {}
            local activeSpells = T.Actor.activeSpells(actorData.object)
            for _, spell in pairs(activeSpells) do
                if spell.temporary then
                    currSpells[spell.activeSpellId] = spell
                end
            end
            local removedSpells = {}
            for activeSpellId, spellEffects in pairs(actorData.spellEffects) do
                local currSpell = currSpells[activeSpellId]
                if currSpell then
                    local keptEffects = {}
                    local keptEffectIndexes = {}
                    local needsUiRefresh = false
                    for _, effect in ipairs(spellEffects) do
                        effect.expireAt = effect.expireAt + appPausedDuration
                        if effect.tracked then
                            effect.expireAt = effect.expireAt + dialoguePauseDuration
                        else
                            effect.expireAt = effect.expireAt + gamePausedDuration
                        end
                        if effect.expireAt - realTime < 0 then
                            log(string.format("Effect \"%s\" of active spell \"%s\" has expired for actor %s",
                                    effect.id, currSpell.id, mH.objectId(actorData.object)))
                            needsUiRefresh = needsUiRefresh or effect.tracked
                        else
                            keptEffects[#keptEffectIndexes + 1] = effect
                            keptEffectIndexes[#keptEffectIndexes + 1] = effect.index
                        end
                    end
                    if #keptEffectIndexes ~= #spellEffects then
                        activeSpells:remove(activeSpellId)
                        actorData.spellEffects[activeSpellId] = keptEffects
                        if #keptEffectIndexes > 0 then
                            local updatedSpell = {
                                id = currSpell.id,
                                effects = keptEffectIndexes,
                                name = currSpell.name,
                                caster = currSpell.caster,
                                stackable = currSpell.stackable,
                            }
                            activeSpells:add(updatedSpell)
                            refreshSpell(actorData.object, currSpell, updatedSpell)
                        else
                            removedSpells[#removedSpells + 1] = activeSpellId
                        end
                        if needsUiRefresh and uiModesToRefresh[currUiMode] then
                            currPlayer:sendEvent(mDef.events.refreshUiMode, { uiMode = currUiMode, target = currInterlocutor })
                        end
                    end
                else
                    log(string.format("Untracking removed active spell \"%s\" for actor %s", activeSpellId, mH.objectId(actorData.object)))
                    removedSpells[#removedSpells + 1] = activeSpellId
                end
            end
            for _, spellId in ipairs(removedSpells) do
                actorData.spellEffects[spellId] = nil
            end
            if not next(actorData.spellEffects) then
                log(string.format("No more active spells to track for actor %s", mH.objectId(actorData.object)))
                actorsToClear[#actorsToClear + 1] = actorId
            end
        end
    end
    for _, id in ipairs(actorsToClear) do
        state.actors[id] = nil
    end
end

local function onUpdate()
    if mStore.settings.magicEffectDurationForPausedDialogue.get() then
        checkActiveSpells()
    end
end

local function fixObjects(dataLists)
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if mH.isObjectInvalid(data.object) then
                invalidCt = invalidCt + 1
                dataList[id] = nil
            elseif id ~= data.object.id then
                changedIdCt = changedIdCt + 1
                dataList[id] = nil
                dataList[data.object.id] = data
            end
        end
        if invalidCt + changedIdCt > 0 then
            log(string.format("Cleared %d invalid references and fixed %d changed IDs for %s", invalidCt, changedIdCt, key))
        end
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
        state = data.state
        log(string.format("Loading MRF save format v%s...", data.version))
    end
    fixObjects({ actors = state.actors })
end

local function setSettingDependencies(key, init)
    if init or key == mStore.settings.magicEffectDurationForPausedDialogue.key then
        mStore.settings.minMagicEffectDurationForPausedDialogue.argument.disabled = not mStore.settings.magicEffectDurationForPausedDialogue.get()
        mStore.updateRendererArgument(mStore.settings.minMagicEffectDurationForPausedDialogue)
    end
end

mStore.addTrackerCallback(function(key, _)
    setSettingDependencies(key)
end)

setSettingDependencies(false, true)

I.ItemUsage.addHandlerForType(T.Armor, onEquip)
I.ItemUsage.addHandlerForType(T.Clothing, onEquip)
I.ItemUsage.addHandlerForType(T.Weapon, onEquip)

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        [mDef.events.onUiChanged] = function(data) onUiChanged(data.uiMode, data.player, data.target) end,
        [mDef.events.refreshSpell] = function(data) refreshSpellCallback(data.actor, data.prevActiveSpellId, data.updatedSpell, data.pauseTags) end,
    }
}