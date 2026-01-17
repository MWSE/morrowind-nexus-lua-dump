local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local anim = require('openmw.animation')

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mStore = require('scripts.FairCare.config.store')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mAi = require('scripts.FairCare.ai.ai')
local mFollow = require('scripts.FairCare.ai.follow')
local mChances = require('scripts.FairCare.util.chances')
local mMagic = require('scripts.FairCare.util.magic')
local mActors = require('scripts.FairCare.util.actors')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

local actorRecord = self.type.record(self)

module.newWoundedState = function()
    return {
        healRequestTime = 0,
        healRequestCount = 0,
        healAnswers = {},
        healerPartner = nil,
        beingHealed = false,
        waitingAiSelfHealTime = nil,
        checkWoundedTime = 0,
        checkNeedsHealingTime = 0,
    }
end

module.clearState = function(state)
    if not state.ai then return end
    for _, answer in ipairs(state.wounded.healAnswers) do
        answer.healerPartner:sendEvent(mDef.events.declineHealHelp, self)
    end
    if state.wounded.healerPartner then
        state.wounded.healerPartner:sendEvent(mDef.events.clearHealerState)
        state.wounded = module.newWoundedState()
    end
end

module.clearHealer = function(state, healer)
    if not state.ai then return end
    if not healer or mTools.areObjectEquals(healer, state.wounded.healerPartner) then
        state.wounded.healerPartner = nil
    end
end

module.checkActorsValidity = function(state)
    if state.wounded.healerPartner and mTools.isObjectInvalid(state.wounded.healerPartner) then
        log(string.format("Clearing invalid healer partner %s", mTools.objectId(state.wounded.healerPartner)))
        module.clearHealer(state)
    end
    local validAnswers = {}
    for _, answer in ipairs(state.wounded.healAnswers) do
        if mTools.isObjectInvalid(answer.healerPartner) then
            log(string.format("Clearing healing answer from invalid %s", mTools.objectId(answer.healerPartner)))
        else
            table.insert(validAnswers, answer)
        end
    end
    state.wounded.healAnswers = validAnswers;
end

local function checkHealRequests(state, injured, deltaTime)
    state.wounded.healRequestTime = state.wounded.healRequestTime + deltaTime
    if state.wounded.healRequestTime > mCfg.checkNeedsHealingRefreshRate / 2 then
        -- Unanswered requests, maybe game loaded
        log(string.format("Has received %d/%d request answers in time", #state.wounded.healAnswers, state.wounded.healRequestCount))
        state.wounded.healRequestCount = #state.wounded.healAnswers
    elseif #state.wounded.healAnswers ~= state.wounded.healRequestCount then
        return
    end

    table.sort(state.wounded.healAnswers, function(a, b) return a.healChances.chance > b.healChances.chance end)

    local foundHealer = false
    for _, answer in ipairs(state.wounded.healAnswers) do
        if injured and not foundHealer and answer.healChances.isSuccess then
            log(string.format("Will be healed by %s, chances:%s", mTools.objectId(answer.healerPartner), mChances.toString(state, answer.healChances)))
            state.wounded.healerPartner = answer.healerPartner
            answer.healerPartner:sendEvent(mDef.events.healFriend, self)
            foundHealer = true
        else
            log(string.format("Won't be healed by %s, injured:%s, chances:%s",
                    mTools.objectId(answer.healerPartner), injured, mChances.toString(state, answer.healChances)))
            answer.healerPartner:sendEvent(mDef.events.declineHealHelp, self)
        end
    end

    state.wounded.healRequestTime = 0
    state.wounded.healRequestCount = 0
    state.wounded.healAnswers = {}
end

local function isNonHealingCreature(state, actor, record)
    return actor.type == T.Creature
            and not state.settings[mStore.groups.creatures.key][mTypes.creatureTypes[record.type] .. "_heal"]
end

local function handleHealingItems(state)
    if state.health.current / state.health.base > mCfg.trySelfHealingItemHealthRatio then return end

    local healingItems = mMagic.getSelfHealingEquipment(self)
    if not next(healingItems) then return false end

    if healingItems[T.Potion] then
        local potion = mMagic.getBestPotion(healingItems[T.Potion])
        log(string.format("Will try to drink %s", mTools.objectId(potion)))
        core.sendGlobalEvent("UseItem", { object = potion, actor = self, force = true })
    elseif not mAi.areOtherAiModsProcessing(state) then
        return
    end
    log("Is waiting for his AI to heal him with items")
    state.wounded.waitingAiSelfHealTime = 0
    mAi.setEnableOtherAiMods(false)
    self:enableAI(true)
end

local function selectSelfHealer(state, healRequests)
    if self.type == T.Player then return end

    if not state.selfHealSpellId
            or not state.settings[mStore.groups.global.key].selfHealingEnabled
            or isNonHealingCreature(state, actorRecord)
            or not mActors.canAct(self)
    then
        return
    end

    local healChances = mChances.newHealChances()
    healChances.aborted = not mChances.setSelfHealingChances(state, self, healChances)
    mChances.setChance(state, healChances)
    if healChances.zeroed then
        log(string.format("Will not try to heal himself, zeroed chances:%s", mChances.toString(state, healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        healRequests[self.id] = { healer = self, request = { woundedPartner = self, healChances = healChances } }
    end
end

local function selectHealer(state, actor, healRequests, hasFollowBounds)
    if actor.type == T.Player
            or T.Actor.isDead(actor)
            or not T.Actor.isInActorsProcessingRange(actor)
            or isNonHealingCreature(state, actor, actor.type.record(actor))
            or not mActors.canAct(actor)
    then
        return
    end

    local healChances = mChances.newHealChances()
    healChances.aborted = not mChances.selectActorsChances(state, self, actor, healChances)
    if healChances.zeroed then
        log(string.format("Won't be healed by %s, zeroed chances:%s", mTools.objectId(actor), mChances.toString(state, healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        mChances.setChance(state, healChances)
        healRequests[actor.id] = { healer = actor, request = {
            woundedPartner = self, healChances = healChances, hasFollowBounds = hasFollowBounds, woundedEnemies = state.ai.enemies } }
    end
end

module.sendHealRequests = function(state, followTeam)
    if not state.ai then return end
    if state.wounded.healRequestCount ~= 0 then
        log(string.format("Already sent %d heal requests, aborting", state.wounded.healRequestCount))
        return
    end
    local healRequests = {}
    selectSelfHealer(state, healRequests)

    local testedActors = { [self.id] = true }

    if state.settings[mStore.groups.global.key].touchHealingEnabled then
        for _, actor in pairs(followTeam) do
            if actor and not testedActors[actor.id] then
                selectHealer(state, actor, healRequests, true)
                testedActors[actor.id] = true
            end
        end
        if state.ai.enemies then
            for _, actor in pairs(nearby.actors) do
                if not testedActors[actor.id] then
                    selectHealer(state, actor, healRequests, false)
                    testedActors[actor.id] = true
                end
            end
        end
    end

    for _, healRequest in pairs(healRequests) do
        log(string.format("Asks help to %s", mTools.objectId(healRequest.healer)))
        state.wounded.healRequestCount = state.wounded.healRequestCount + 1
        healRequest.healer:sendEvent(mDef.events.askHealMe, healRequest.request)
    end
end

local function checkNeedsHealing(state, deltaTime)
    state.wounded.checkNeedsHealingTime = state.wounded.checkNeedsHealingTime + deltaTime
    if state.wounded.checkNeedsHealingTime < mCfg.checkNeedsHealingRefreshRate then return end
    deltaTime = state.wounded.checkNeedsHealingTime
    state.wounded.checkNeedsHealingTime = 0

    if mActors.canRegen(state, self, actorRecord) then
        mActors.doRegen(state, self, deltaTime)
    end

    if state.ai.enemies and not state.wounded.waitingAiSelfHealTime then
        handleHealingItems(state)
    end

    if state.wounded.healRequestCount ~= 0
            or state.wounded.healerPartner
            or state.aiMode ~= mTypes.aiModes.Default then return end

    log("Needs a healer")

    if state.follow.following or next(state.follow.followers) then
        mFollow.getFollowTeam(state, { actor = self, event = mDef.events.sendHealRequests })
    else
        module.sendHealRequests(state, {})
    end
end

module.answerHealMe = function(state, healAnswer)
    if not state.ai then return end
    if not healAnswer.healChances.aborted then
        table.insert(state.wounded.healAnswers, healAnswer)
    else
        state.wounded.healRequestCount = state.wounded.healRequestCount - 1
        if state.wounded.healRequestCount == 0 then
            state.wounded.healRequestTime = 0
        end
    end
end

local function checkWaitToAiHeal(state, deltaTime)
    state.wounded.waitingAiSelfHealTime = state.wounded.waitingAiSelfHealTime + deltaTime
    if state.wounded.waitingAiSelfHealTime > mCfg.allowAiSelfHealMaxTime then
        log("Has not been healed by his AI")
    elseif state.wounded.beingHealed then
        log("Is being healed, maybe by his AI")
    else
        return
    end
    state.wounded.waitingAiSelfHealTime = nil
    mAi.setEnableOtherAiMods(true)
end

module.onUpdate = function(state, deltaTime)
    state.wounded.checkWoundedTime = state.wounded.checkWoundedTime + deltaTime
    if state.wounded.checkWoundedTime < mCfg.checkWoundedRefreshRate then return end
    deltaTime = state.wounded.checkWoundedTime
    state.wounded.checkWoundedTime = 0

    local injured = state.health.current < state.health.base

    if injured then
        state.wounded.beingHealed = state.activeEffects:getEffect(core.magic.EFFECT_TYPE.RestoreHealth).magnitude ~= 0
    else
        state.wounded.beingHealed = false
        if state.wounded.healerPartner then
            module.clearHealer(state)
        end
    end

    if state.wounded.waitingAiSelfHealTime then
        checkWaitToAiHeal(state, deltaTime)
    end

    if state.wounded.healRequestCount ~= 0 then
        checkHealRequests(state, injured, deltaTime)
    end
    if injured then
        checkNeedsHealing(state, deltaTime)
    end
end

module.applyFakeHealSpell = function(spellId)
    T.Actor.activeSpells(self):add({ id = spellId, effects = { 0 } })
    anim.addVfx(self, mMagic.hitHealthModel)
    core.sound.playSound3d(mMagic.healHitSound, self)
end

return module