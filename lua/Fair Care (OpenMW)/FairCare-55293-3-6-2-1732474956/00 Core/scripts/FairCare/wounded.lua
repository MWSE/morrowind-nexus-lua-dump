local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local anim = require('openmw.animation')

local mSettings = require('scripts.FairCare.settings')
local mFollow = require('scripts.FairCare.follow')
local mCfg = require('scripts.FairCare.configuration')
local mTools = require('scripts.FairCare.tools')
local mData = require('scripts.FairCare.data')
local mActors = require('scripts.FairCare.actors')
local mAi = require('scripts.FairCare.ai')
local mMagic = require('scripts.FairCare.magic')
local mChances = require('scripts.FairCare.chances')

local module = {}

local actorId = mTools.actorId(self)
local actorRecord = mTools.getRecord(self)

local function newWoundedState()
    return {
        healRequestTime = 0,
        healRequestCount = 0,
        healAnswers = {},
        healerPartner = nil,
        beingHealed = false,
        waitingAiSelfHealTime = nil,
        checkNeedsHealerTime = 0,
        checkHealedFinishedTime = 0,
    }
end
module.newWoundedState = newWoundedState

local function clearState(state)
    for _, answer in ipairs(state.wounded.healAnswers) do
        answer.healerPartner:sendEvent("fairCare_declineHealHelp", self)
    end
    if state.wounded.healerPartner then
        state.wounded.healerPartner:sendEvent("fairCare_clearHealerState")
        state.wounded = newWoundedState()
    end
end
module.clearState = clearState

local function clearHealer(state, healer)
    if not state.wounded.beingHealed and (not healer or mTools.areObjectEquals(healer, state.wounded.healerPartner)) then
        state.wounded.healerPartner = nil
    end
end
module.clearHealer = clearHealer

local function checkActorReferences(state)
    if state.wounded.healerPartner and mTools.isObjectInvalid(state.wounded.healerPartner) then
        mTools.debugPrint(string.format("Clearing %s invalid healer partner %s", actorId, state.wounded.healerPartner))
        clearHealer(state)
    end
    local validAnswers = {}
    for _, answer in ipairs(state.wounded.healAnswers) do
        if mTools.isObjectInvalid(answer.healerPartner) then
            mTools.debugPrint(string.format("Clearing %s healing answer from invalid actor %s", actorId, answer.healerPartner))
        else
            table.insert(validAnswers, answer)
        end
    end
    state.wounded.healAnswers = validAnswers;
end
module.checkActorReferences = checkActorReferences

local function checkHealRequests(state, deltaTime)
    state.wounded.healRequestTime = state.wounded.healRequestTime + deltaTime
    -- Unanswered requests, maybe game loaded
    if state.wounded.healRequestTime > mCfg.checkNeedsHealerRefreshRate / 2 then
        state.wounded.healRequestTime = 0
        mTools.debugPrint(string.format("%s has received %d/%d request answers in time", actorId,
                #state.wounded.healAnswers, state.wounded.healRequestCount))
        state.wounded.healRequestCount = #state.wounded.healAnswers
    elseif #state.wounded.healAnswers ~= state.wounded.healRequestCount then
        return
    end
    state.wounded.healRequestTime = 0

    table.sort(state.wounded.healAnswers, function(a, b) return a.healChances.chance > b.healChances.chance end)

    local foundHealer = false
    for _, answer in ipairs(state.wounded.healAnswers) do
        if not foundHealer and answer.healChances.isSuccess then
            mTools.debugPrint(string.format("%s will be healed by %s, chances:%s",
                    actorId, mTools.actorId(answer.healerPartner), mChances.toString(answer.healChances)))
            state.wounded.healerPartner = answer.healerPartner
            answer.healerPartner:sendEvent("fairCare_healFriend", self)
            foundHealer = true
        else
            mTools.debugPrint(string.format("%s won't be healed by %s, chances:%s",
                    actorId,
                    mTools.actorId(answer.healerPartner),
                    mChances.toString(answer.healChances)))
            answer.healerPartner:sendEvent("fairCare_declineHealHelp", self)
        end
    end
    state.wounded.healRequestCount = 0
    state.wounded.healAnswers = {}
end

local function isNonHealingCreature(actor)
    return actor.type == T.Creature and not mSettings.canCreatureTypeHeal(mTools.getRecord(actor).type)
end

local function selectSelfHealer(state, healRequests)
    if not mActors.canAct(self) then return end

    local hasHealingItems

    -- Try to use self-healing items
    if mAi.areOtherAiModsProcessing(state) then
        local health = T.Actor.stats.dynamic.health(self)
        if health.current / health.base < mCfg.allowAiSelfHealHealthRatio then
            hasHealingItems = mMagic.hasSelfHealingEquipment(self)
            if hasHealingItems then
                mTools.debugPrint(string.format("%s is waiting for his AI to heal him with items", actorId))
                state.wounded.waitingAiSelfHealTime = 0
                state.wounded.healerPartner = self
                mAi.setEnableOtherAiMods(false)
                self:enableAI(true)
                return
            end
        end
    end

    -- Try to use self-healing spell
    if not state.selfHealSpellId
            or not mSettings.getStorage(mSettings.globalKey):get("selfHealingEnabled")
            or isNonHealingCreature(self)
    then
        return
    end

    if state.ai.enemies and (hasHealingItems ~= nil and hasHealingItems or mMagic.hasSelfHealingEquipment(self)) then return end

    local healChances = mChances.newHealChances()
    mChances.setSelfHealingChances(state.selfHealSpellId, self, healChances)
    mChances.setChance(healChances)
    if healChances.zeroed then
        mTools.debugPrint(string.format("%s will not try to heal himself, zeroed chances:%s", actorId, mChances.toString(healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        healRequests[self.id] = { healer = self, request = { woundedPartner = self, healChances = healChances } }
    end
end

local function selectHealer(state, actor, healRequests, hasFollowBounds)
    if T.Actor.isDead(actor)
            or not T.Actor.isInActorsProcessingRange(actor)
            or isNonHealingCreature(actor)
            or not mActors.canAct(actor)
    then
        return
    end

    local healChances = mChances.newHealChances()
    mChances.selectActorsChances(self, actor, healChances)
    if healChances.zeroed then
        mTools.debugPrint(string.format("%s won't be healed by %s, zeroed chances:%s",
                actorId, mTools.actorId(actor), mChances.toString(healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        mChances.setChance(healChances)
        healRequests[actor.id] = { healer = actor, request = {
            woundedPartner = self, healChances = healChances, hasFollowBounds = hasFollowBounds, woundedEnemies = state.ai.enemies } }
    end
end

local function sendHealRequests(state, followTeam)
    if state.wounded.healRequestCount ~= 0 then
        mTools.debugPrint(string.format("%s already sent %d heal requests, aborting", actorId, state.wounded.healRequestCount))
        return
    end
    local healRequests = {}
    selectSelfHealer(state, healRequests)
    if state.wounded.waitingAiSelfHealTime then return end

    local testedActors = { [self.id] = true }

    if mSettings.getStorage(mSettings.globalKey):get("touchHealingEnabled") then
        for _, actor in ipairs(followTeam) do
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
        mTools.debugPrint(string.format("%s asks help to %s", actorId, mTools.actorId(healRequest.healer)))
        state.wounded.healRequestCount = state.wounded.healRequestCount + 1
        healRequest.healer:sendEvent("fairCare_askHealMe", healRequest.request)
    end
end
module.sendHealRequests = sendHealRequests

local function checkNeedsHealing(state, deltaTime)
    state.wounded.checkNeedsHealerTime = state.wounded.checkNeedsHealerTime + deltaTime
    if state.wounded.checkNeedsHealerTime < mCfg.checkNeedsHealerRefreshRate then return end
    deltaTime = state.wounded.checkNeedsHealerTime
    state.wounded.checkNeedsHealerTime = 0

    local health = T.Actor.stats.dynamic.health(self)
    if health.current >= health.base then return end

    if mActors.canRegen(self, actorRecord, state) then
        mActors.doRegen(self, deltaTime)
    end

    if state.wounded.healerPartner or state.aiMode ~= mData.aiModes.Default then return end

    mTools.debugPrint(string.format("%s needs a healer", actorId))

    if state.follow.following or next(state.follow.followers) then
        mFollow.getFollowTeam(state, { actor = self, event = "fairCare_sendHealRequests" })
    else
        sendHealRequests(state, {})
    end
end

local function answerHealMe(state, healAnswer)
    if not healAnswer.healChances.aborted then
        table.insert(state.wounded.healAnswers, healAnswer)
    else
        state.wounded.healRequestCount = state.wounded.healRequestCount - 1
    end
end
module.answerHealMe = answerHealMe

local function waitToAiHeal(state, deltaTime)
    state.wounded.waitingAiSelfHealTime = state.wounded.waitingAiSelfHealTime + deltaTime
    local stopWaiting = false
    if state.wounded.waitingAiSelfHealTime > mCfg.allowAiSelfHealMaxTime then
        mTools.debugPrint(string.format("%s has not been healed by his AI", actorId))
        stopWaiting = true
        state.wounded.healerPartner = nil
    elseif T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.RestoreHealth).magnitude ~= 0 then
        mTools.debugPrint(string.format("%s is being healed by his AI", actorId))
        stopWaiting = true
        state.wounded.beingHealed = true
    end
    if stopWaiting then
        state.wounded.waitingAiSelfHealTime = nil
        mAi.setEnableOtherAiMods(true)
    end
end

local function checkHealth(state, deltaTime)
    if state.wounded.healRequestCount ~= 0 then
        checkHealRequests(state, deltaTime)
        return
    end

    if state.wounded.waitingAiSelfHealTime then
        waitToAiHeal(state, deltaTime)
    end

    if state.wounded.beingHealed then
        state.wounded.checkHealedFinishedTime = state.wounded.checkHealedFinishedTime + deltaTime
        if state.wounded.checkHealedFinishedTime >= mCfg.checkHealedFinishRefreshRate then
            state.wounded.checkHealedFinishedTime = 0
            if T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.RestoreHealth).magnitude == 0 then
                state.wounded.beingHealed = false
                clearHealer(state)
            end
        end
        return
    end

    checkNeedsHealing(state, deltaTime)
end
module.checkHealth = checkHealth

local function fakeTouchHealed(state, spellId)
    T.Actor.activeSpells(self):add({ id = spellId, effects = { 0 } })
    anim.addVfx(self, mMagic.hitHealthModel)
    core.sound.playSound3d(mMagic.healHitSound, self)
    state.wounded.beingHealed = true
end
module.fakeTouchHealed = fakeTouchHealed

return module