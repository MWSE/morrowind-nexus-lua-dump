local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local anim = require('openmw.animation')

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
local log = require('scripts.FairCare.util.log')

local module = {}

local actorId = mTools.objectId(self)
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
        checkBeingHealedTime = 0,
    }
end
module.newWoundedState = newWoundedState

local function clearState(state)
    for _, answer in ipairs(state.wounded.healAnswers) do
        answer.healerPartner:sendEvent(mDef.events.declineHealHelp, self)
    end
    if state.wounded.healerPartner then
        state.wounded.healerPartner:sendEvent(mDef.events.clearHealerState)
        state.wounded = newWoundedState()
    end
end
module.clearState = clearState

local function clearHealer(state, healer)
    if not healer or mTools.areObjectEquals(healer, state.wounded.healerPartner) then
        state.wounded.healerPartner = nil
    end
end
module.clearHealer = clearHealer

local function checkActorsValidity(state)
    if state.wounded.healerPartner and mTools.isObjectInvalid(state.wounded.healerPartner) then
        log(string.format("Clearing %s invalid healer partner %s", actorId, state.wounded.healerPartner))
        clearHealer(state)
    end
    local validAnswers = {}
    for _, answer in ipairs(state.wounded.healAnswers) do
        if mTools.isObjectInvalid(answer.healerPartner) then
            log(string.format("Clearing %s healing answer from invalid actor %s", actorId, answer.healerPartner))
        else
            table.insert(validAnswers, answer)
        end
    end
    state.wounded.healAnswers = validAnswers;
end
module.checkActorsValidity = checkActorsValidity

local function checkHealRequests(state, deltaTime)
    state.wounded.healRequestTime = state.wounded.healRequestTime + deltaTime
    -- Unanswered requests, maybe game loaded
    if state.wounded.healRequestTime > mCfg.checkNeedsHealerRefreshRate / 2 then
        state.wounded.healRequestTime = 0
        log(string.format("%s has received %d/%d request answers in time", actorId,
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
            log(string.format("%s will be healed by %s, chances:%s",
                    actorId, mTools.objectId(answer.healerPartner), mChances.toString(state, answer.healChances)))
            state.wounded.healerPartner = answer.healerPartner
            answer.healerPartner:sendEvent(mDef.events.healFriend, self)
            foundHealer = true
        else
            log(string.format("%s won't be healed by %s, chances:%s",
                    actorId,
                    mTools.objectId(answer.healerPartner),
                    mChances.toString(state, answer.healChances)))
            answer.healerPartner:sendEvent(mDef.events.declineHealHelp, self)
        end
    end
    state.wounded.healRequestCount = 0
    state.wounded.healAnswers = {}
end

local function isNonHealingCreature(state, actor)
    return actor.type == T.Creature and not state.settings[mStore.groups.creatures.key][mTypes.creatureTypes[mTools.getRecord(actor).type] .. "_heal"]
end

local function handleHealingItems(state)
    local health = T.Actor.stats.dynamic.health(self)
    if health.current / health.base > mCfg.trySelfHealingItemHealthRatio or health.current == 0 then return false end

    local healingItems = mMagic.getSelfHealingEquipment(self)
    if not next(healingItems) then return false end

    if healingItems[T.Potion] then
        local potion = mMagic.getBestPotion(healingItems[T.Potion])
        log(string.format("%s will try to drink %s", actorId, mTools.objectId(potion)))
        core.sendGlobalEvent('UseItem', { object = potion, actor = self })
        return true
    elseif mAi.areOtherAiModsProcessing(state) then
        log(string.format("%s is waiting for his AI to heal him with items", actorId))
        state.wounded.waitingAiSelfHealTime = 0
        mAi.setEnableOtherAiMods(false)
        self:enableAI(true)
    end
    return false
end

local function selectSelfHealer(state, healRequests)
    if state.ai.enemies and handleHealingItems(state) then return end

    if not state.selfHealSpellId
            or not state.settings[mStore.groups.global.key].selfHealingEnabled
            or isNonHealingCreature(state, self)
            or not mActors.canAct(self)
    then
        return
    end

    local healChances = mChances.newHealChances()
    healChances.aborted = not mChances.setSelfHealingChances(state.selfHealSpellId, self, healChances)
    mChances.setChance(state, healChances)
    if healChances.zeroed then
        log(string.format("%s will not try to heal himself, zeroed chances:%s", actorId, mChances.toString(state, healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        healRequests[self.id] = { healer = self, request = { woundedPartner = self, healChances = healChances } }
    end
end

local function selectHealer(state, actor, healRequests, hasFollowBounds)
    if T.Actor.isDead(actor)
            or not T.Actor.isInActorsProcessingRange(actor)
            or isNonHealingCreature(state, actor)
            or not mActors.canAct(actor)
    then
        return
    end

    local healChances = mChances.newHealChances()
    healChances.aborted = not mChances.selectActorsChances(state, self, actor, healChances)
    if healChances.zeroed then
        log(string.format("%s won't be healed by %s, zeroed chances:%s",
                actorId, mTools.objectId(actor), mChances.toString(state, healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        mChances.setChance(state, healChances)
        healRequests[actor.id] = { healer = actor, request = {
            woundedPartner = self, healChances = healChances, hasFollowBounds = hasFollowBounds, woundedEnemies = state.ai.enemies } }
    end
end

local function sendHealRequests(state, followTeam)
    if state.wounded.healRequestCount ~= 0 then
        log(string.format("%s already sent %d heal requests, aborting", actorId, state.wounded.healRequestCount))
        return
    end
    local healRequests = {}
    selectSelfHealer(state, healRequests)
    if state.wounded.waitingAiSelfHealTime then return end

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
        log(string.format("%s asks help to %s", actorId, mTools.objectId(healRequest.healer)))
        state.wounded.healRequestCount = state.wounded.healRequestCount + 1
        healRequest.healer:sendEvent(mDef.events.askHealMe, healRequest.request)
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

    if mActors.canRegen(state, self, actorRecord) then
        mActors.doRegen(state, self, deltaTime)
    end

    if state.wounded.healerPartner or state.aiMode ~= mTypes.aiModes.Default then return end

    log(string.format("%s needs a healer", actorId))

    if state.follow.following or next(state.follow.followers) then
        mFollow.getFollowTeam(state, { actor = self, event = mDef.events.sendHealRequests })
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
        log(string.format("%s has not been healed by his AI", actorId))
        stopWaiting = true
    elseif state.wounded.beingHealed then
        log(string.format("%s is being healed, maybe by his AI", actorId))
        stopWaiting = true
    end
    if stopWaiting then
        state.wounded.waitingAiSelfHealTime = nil
        mAi.setEnableOtherAiMods(true)
    end
end

local function handleBeingHealed(state, deltaTime)
    state.wounded.checkBeingHealedTime = state.wounded.checkBeingHealedTime + deltaTime
    if state.wounded.checkBeingHealedTime < mCfg.checkBeingHealedRefreshRate then return end
    state.wounded.checkBeingHealedTime = 0

    if not state.wounded.beingHealed and not state.wounded.healerPartner and not state.ai.enemies then return end

    local beingHealed = T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.RestoreHealth).magnitude ~= 0
    if state.wounded.healerPartner and state.wounded.beingHealed and not beingHealed then
        clearHealer(state)
    end
    state.wounded.beingHealed = beingHealed
end

local function checkHealth(state, deltaTime)
    if state.wounded.healRequestCount ~= 0 then
        checkHealRequests(state, deltaTime)
        return
    end

    if state.wounded.waitingAiSelfHealTime then
        waitToAiHeal(state, deltaTime)
    end

    handleBeingHealed(state, deltaTime)
    if state.wounded.beingHealed then return end

    checkNeedsHealing(state, deltaTime)
end
module.checkHealth = checkHealth

local function applyFakeHealSpell(spellId)
    T.Actor.activeSpells(self):add({ id = spellId, effects = { 0 } })
    anim.addVfx(self, mMagic.hitHealthModel)
    core.sound.playSound3d(mMagic.healHitSound, self)
end
module.applyFakeHealSpell = applyFakeHealSpell

return module