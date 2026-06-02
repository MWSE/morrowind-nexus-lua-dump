local world = require('openmw.world')
local transform = require('scripts.corprus_plague.transform')
local carrier = require('scripts.corprus_plague.carrier')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')
local config = require('scripts.corprus_plague.config')
local disposition = require('scripts.corprus_plague.disposition')
local firstRestDreamWatch = require('scripts.corprus_plague.first_rest_dream_watch')
local cureDebug = require('scripts.corprus_plague.cure_debug')
local settingsMirror = require('scripts.corprus_plague.settings_mirror')

local scanAccumulator = 0
local cureRetryAccumulator = 0
local CURE_RETRY_INTERVAL = 5

local function ensureAllPlayers()
    local infectionCount = storageApi.getInfectionCount()
    local cured = storageApi.isCured()
    for _, player in ipairs(world.players) do
        carrier.ensure(player, infectionCount, cured)
    end
end

local function syncAllPlayerCarrierStats()
    local infectionCount = storageApi.getInfectionCount()
    local cured = storageApi.isCured()
    for _, player in ipairs(world.players) do
        carrier.syncInfectionCount(player, infectionCount, cured)
    end
end

local function getPrimaryPlayer()
    return world.players[1]
end

local function showCureMessage()
    for _, player in ipairs(world.players) do
        -- Player script only: interactive OK box (see CorprusPlagueCureMessage).
        player:sendEvent('CorprusPlagueCureMessage', { message = config.cureMessage })
    end
end

local function applyCarrierCure(showMessage)
    if config.debugSkipCureApplication then
        cureDebug.log('debugSkipCureApplication: not marking cured')
        return false
    end

    if not storageApi.markCured() then
        if storageApi.isCured() then
            storageApi.clearCurePending()
            cureDebug.log('already cured; cleared pending')
        end
        return false
    end

    syncAllPlayerCarrierStats()
    storageApi.clearCurePending()

    pcall(function()
        local types = require('openmw.types')
        local player = world.players[1]
        if player and player:isValid() then
            local quests = types.Player.quests(player)
            quests[config.carrierJournalId]:addJournalEntry(config.carrierJournalCureStage)
        end
    end)

    cureDebug.log('carrier cured')

    if showMessage then
        showCureMessage()
    end
    return true
end

local function tryFinishPendingCure(reason)
    if not config.enableStory then
        return
    end
    if storageApi.isCured() then
        if storageApi.isCurePending() then
            storageApi.clearCurePending()
            cureDebug.log('cleared stale curePending (already cured)')
        end
        return
    end

    if not storageApi.isCurePending() then
        return
    end

    cureDebug.log('retry pending cure (' .. tostring(reason) .. ')')
    applyCarrierCure(reason == 'event' or reason == 'load')
end

local function onGameReady()
    storageApi.clearAllPendingTransforms()
    if config.enableStory then
        tryFinishPendingCure('gameReady')
    end
    ensureAllPlayers()
    transform.syncWorldWithStorage()
    if config.enableStory then
        firstRestDreamWatch.resetSnapshots()
        for _, player in ipairs(world.players) do
            firstRestDreamWatch.onGameReady(player)
        end
    end
end

return {
    engineHandlers = {
        onNewGame = function()
            storageApi.clearAll()
            ensureAllPlayers()
        end,

        onSave = function()
            return storageApi.exportForSave()
        end,

        onLoad = function(savedData)
            storageApi.importFromSave(savedData)
            storageApi.clearAllPendingTransforms()
            if config.enableStory then
                if config.debugForceCurePendingOnLoad then
                    storageApi.setCurePending(true)
                    cureDebug.log('debugForceCurePendingOnLoad: curePending set')
                end
                tryFinishPendingCure('load')
            end
        end,

        onPlayerAdded = onGameReady,

        onActorActive = function(actor)
            transform.tryTransform(actor)
        end,

        onUpdate = function(dt)
            if config.enableStory then
                if storageApi.isCurePending() and not storageApi.isCured() then
                    cureRetryAccumulator = cureRetryAccumulator + dt
                    if cureRetryAccumulator >= CURE_RETRY_INTERVAL then
                        cureRetryAccumulator = 0
                        tryFinishPendingCure('periodic')
                    end
                else
                    cureRetryAccumulator = 0
                end
            end

            scanAccumulator = scanAccumulator + dt
            if scanAccumulator < config.transformScanInterval then
                return
            end
            scanAccumulator = 0
            transform.tryTransformActiveActors()
        end,
    },

    eventHandlers = {
        CorprusPlagueSyncSettings = function(data)
            if type(data) == 'table' then
                settingsMirror.set(data)
            end
        end,

        CorprusPlagueInfect = function(data)
            local plagueKey = data.plagueKey
            if not plagueKey then
                return
            end

            local actor = actorRef.findActor(plagueKey)
            if actor and actor:isValid() then
                if not storageApi.isCured() and transform.infect(actor) then
                    syncAllPlayerCarrierStats()
                end
                disposition.applyInfectionPenalty(
                    actor,
                    data.player or getPrimaryPlayer(),
                    data.dispositionModifier
                )
                return
            end

            if storageApi.isCured() then
                return
            end

            if not storageApi.isInfected(plagueKey) and not storageApi.isTransformed(plagueKey) then
                if storageApi.markInfected(plagueKey, world.getGameTime()) then
                    syncAllPlayerCarrierStats()
                end
            end
        end,

        CorprusPlagueCureCarrier = function()
            if not config.enableStory then
                return
            end
            if storageApi.isCured() then
                storageApi.clearCurePending()
                return
            end

            if not storageApi.isCurePending() then
                storageApi.setCurePending(true)
                cureDebug.log('cure requested; curePending set')
            end

            applyCarrierCure(true)
        end,

        CorprusPlagueRestCompleted = function(data)
            if not config.enableStory then
                return
            end
            firstRestDreamWatch.onPlayerRestCompleted(data)
        end,
    },
}
