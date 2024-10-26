local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local anim = require('openmw.animation')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mTools = require('scripts.FairCare.tools')
local mActors = require('scripts.FairCare.actors')
local mChances = require('scripts.FairCare.chances')
local mMagic = require('scripts.FairCare.magic')
local mAi = require('scripts.FairCare.ai')

local module = {}

local selfRecord = mActors.getRecord(self)
local actorId = mActors.actorId(self)

local function newWoundedState()
    return {
        healRequestCount = 0,
        healAnswers = {},
        healerFriend = nil,
        beingHealed = false,
        checkNeedsHealerTime = 0,
        checkHealedFinishedTime = 0,
    }
end
module.newWoundedState = newWoundedState

local function clearState(state)
    if state.wounded.healerFriend then
        state.wounded.healerFriend:sendEvent("fc_stopHealingFriend")
        state.wounded = newWoundedState()
    end
end
module.clearState = clearState

local function clearHealer(state)
    if not state.wounded.beingHealed then
        state.wounded.healerFriend = nil
    end
end
module.clearHealer = clearHealer

local function checkHealRequests(state)
    if #state.wounded.healAnswers ~= state.wounded.healRequestCount then return end

    state.wounded.healRequestCount = 0
    if #state.wounded.healAnswers == 0 then
        return
    end

    local finalAnswers = {}
    for _, answer in ipairs(state.wounded.healAnswers) do
        table.insert(finalAnswers, answer)
    end
    table.sort(finalAnswers, function(a, b) return a.healChances.chance > b.healChances.chance end)

    local foundHealer = false
    for _, answer in ipairs(finalAnswers) do
        if not foundHealer and answer.healChances.isSuccess then
            mSettings.debugPrint(string.format("%s will be healed by %s, chances:%s",
                    actorId, mActors.actorId(answer.healerFriend), mChances.toString(answer.healChances)))
            state.wounded.healerFriend = answer.healerFriend
            answer.healerFriend:sendEvent("fc_healFriend")
            foundHealer = true
        else
            mSettings.debugPrint(string.format("%s won't be healed by %s,%s chances:%s",
                    actorId,
                    mActors.actorId(answer.healerFriend),
                    answer.tooEarly and " too early," or "",
                    mChances.toString(answer.healChances)))
            answer.healerFriend:sendEvent("fc_declineHealHelp")
        end
    end
    state.wounded.healAnswers = {}
end

local function selectSelfHealer(state, healRequests)
    if state.hasOwnSelfHealSpell
            or not state.healSpellId
            or not mSettings.globalStorage:get("selfHealingEnabled")
            or self.type == T.Creature and not mSettings.creaturesStorage:get(mData.creatureTypes[selfRecord.type])
            or mMagic.hasAvailableEquipmentEffects(self, function(effects) return mMagic.hasSelfHealEffect(effects) end)
    then
        return
    end
    local healChances = mChances.newHealChances()
    mChances.setSelfHealingChances(state, self, healChances)
    mChances.setChance(healChances)
    if healChances.aborted or not healChances.isSuccess then
        mSettings.debugPrint(string.format("%s will not try to heal himself. Chances:%s", actorId, mChances.toString(healChances)))
        return
    end
    healRequests[self.id] = { healer = self, request = { woundedPartner = self, healChances = healChances, hasFollowBounds = true } }
end

local function selectHealer(state, actor, healRequests, hasFollowBounds)
    if self.type == T.Creature and not mSettings.creaturesStorage:get(mData.creatureTypes[selfRecord.type]) then return end

    local healChances = mChances.newHealChances()
    mChances.selectActorsChances(self, actor, healChances)
    if healChances.none then
        mSettings.debugPrint(string.format("%s won't be healed by %s, zeroed chances:%s",
                actorId, mActors.actorId(actor), mChances.toString(healChances)))
        healChances.aborted = true
    end
    if not healChances.aborted then
        healRequests[actor.id] = { healer = actor, request = { woundedPartner = self, healChances = healChances, hasFollowBounds = hasFollowBounds, woundedTarget = state.ai.combatTarget } }
    end
end

local function checkNeedsHealing(state, deltaTime)
    state.wounded.checkNeedsHealerTime = state.wounded.checkNeedsHealerTime + deltaTime
    if state.wounded.checkNeedsHealerTime < mCfg.checkNeedsHealerRefreshRate then return end
    state.wounded.checkNeedsHealerTime = 0

    if state.wounded.healerFriend then return end

    local health = T.Actor.stats.dynamic.health(self)
    if health.current >= health.base then return end

    local healRequests = {}
    mSettings.debugPrint(string.format("%s needs a healer", actorId))

    selectSelfHealer(state, healRequests)

    if mSettings.globalStorage:get("touchHealingEnabled") then
        for _, partner in mTools.mpairs({ following = state.follow.following }, state.follow.followers, state.follow.followerTeam) do
            if partner then
                selectHealer(state, partner, healRequests, true)
            end
        end
        if state.ai.combatTarget then
            mAi.checkAiPackage(state)
            for _, actor in pairs(nearby.actors) do
                if actor.id ~= self.id and not healRequests[actor.id] and not T.Actor.isDead(actor) then
                    selectHealer(state, actor, healRequests, false)
                end
            end
        end
    end

    for _, healRequest in pairs(healRequests) do
        mSettings.debugPrint(string.format("%s asks help to %s", actorId, mActors.actorId(healRequest.healer)))
        state.wounded.healRequestCount = state.wounded.healRequestCount + 1
        healRequest.healer:sendEvent("fc_askHealMe", healRequest.request)
    end
end

local function checkHealth(state, deltaTime)
    if state.wounded.healRequestCount ~= 0 then
        checkHealRequests(state)
        return
    end

    if state.wounded.beingHealed then
        state.wounded.checkHealedFinishedTime = state.wounded.checkHealedFinishedTime + deltaTime
        if state.wounded.checkHealedFinishedTime >= mCfg.checkHealedFinishRefreshRate then
            state.wounded.checkHealedFinishedTime = 0
            if T.Actor.activeEffects(self):getEffect("restorehealth").magnitude == 0 then
                state.wounded.beingHealed = false
                clearHealer(state)
            end
        end
        return
    end

    checkNeedsHealing(state, deltaTime)
end
module.checkHealth = checkHealth

local function answerHealMe(state, healAnswer)
    if not healAnswer.healChances.aborted then
        table.insert(state.wounded.healAnswers, healAnswer)
    else
        state.wounded.healRequestCount = state.wounded.healRequestCount - 1
    end
end
module.answerHealMe = answerHealMe

local function castSelfHeal(state, spellId)
    T.Actor.activeSpells(self):add({ id = spellId, effects = { 0 } })
    anim.addVfx(self, mMagic.restoreHealthModel)
    core.sound.playSound3d(mMagic.healHitSound, self)
    state.wounded.beingHealed = true
end
module.castSelfHeal = castSelfHeal

return module