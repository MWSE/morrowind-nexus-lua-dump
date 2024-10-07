local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local anim = require('openmw.animation')

local mCfg = require('scripts.FairCare.configuration')
local mShared = require('scripts.FairCare.shared')
local mMagic = require('scripts.FairCare.magic')
local mUtil = require('scripts.FairCare.util')
local mAi = require('scripts.FairCare.ai')

local woundedModule = {}

local actorRId = mUtil.getRecord(self).id

local function newWoundedState()
    return {
        healRequestCount = 0,
        healRequestTime = 0,
        healAnswers = {},
        beingHealed = false,
        healerFriend = nil,
        checkNeedsHealerTime = 0,
        checkHealedFinishedTime = 0,
        timeBeforeAskingHealAgain = 0,
    }
end
woundedModule.newWoundedState = newWoundedState

local function canSelfHeal(state, actor)
    if state.healSelfSpellId and mMagic.hasEnoughMagicka(actor, state.healSelfSpellId) then
        return true
    end
    return mMagic.hasAvailableEquipmentEffects(actor, function(effects)
        return mMagic.hasSelfHealEffect(effects)
    end)
end

local function clearHealer(state)
    if not state.wounded.beingHealed then
        state.wounded = newWoundedState()
    end
end
woundedModule.clearHealer = clearHealer

local function needsHealer(state)
    if state.wounded.healerFriend or state.wounded.healRequestCount ~= 0 then
        return false
    end
    local health = T.Actor.stats.dynamic.health(self)
    return health.current / health.base < mCfg.injuredEnoughRatio and not canSelfHeal(state, self)
end

local function canTouchHeal(actor)
    for _, spellId in ipairs(mShared.healTouchSpellIds) do
        if T.Actor.spells(actor)[spellId] then
            return mMagic.hasEnoughMagicka(actor, spellId)
        end
    end
    return false
end

local function getBestHealerAndPath(healers)
    local bestActor
    local bestPath
    local minTravelTime = math.huge
    for _, healer in pairs(healers) do
        local path = mUtil.getPath(healer, self)
        if path then
            local travelTime = mUtil.getTravelTimeSec(healer, path)
            if travelTime < minTravelTime then
                bestActor = healer
                bestPath = path
                minTravelTime = travelTime
            end
        end
    end
    return bestActor, bestPath
end

local function checkHealRequests(state, deltaTime)
    state.wounded.healRequestTime = state.wounded.healRequestTime + deltaTime
    if state.wounded.healRequestTime < mCfg.healRequestMaxTime
            and #state.wounded.healAnswers ~= state.wounded.healRequestCount then return end

    state.wounded.healRequestTime = 0
    state.wounded.healRequestCount = 0
    local agreeingHealers = {}
    for _, healAnswer in ipairs(state.wounded.healAnswers) do
        if healAnswer.answer then
            table.insert(agreeingHealers, healAnswer.healerFriend)
        end
    end
    state.wounded.healAnswers = {}
    if #agreeingHealers == 0 then return end

    local healer, path = getBestHealerAndPath(agreeingHealers)
    if healer then
        mUtil.debugPrint(string.format("\"%s\" chooses healer \"%s\"", actorRId, mUtil.getRecord(healer).id))
        state.wounded.healerFriend = healer
        healer:sendEvent("fc_healFriend", { woundedFriend = self, path = path })
    end
    for _, healerFriend in ipairs(agreeingHealers) do
        if not healer or healerFriend.id ~= healer.id then
            healerFriend:sendEvent("fc_declineHealHelp", self)
        end
    end
end
woundedModule.checkHealRequests = checkHealRequests

local function checkHealth(state, deltaTime)
    if state.wounded.healRequestCount ~= 0 then
        checkHealRequests(state, deltaTime)
        return
    end

    if state.wounded.beingHealed then
        state.wounded.checkHealedFinishedTime = state.wounded.checkHealedFinishedTime + deltaTime
        if state.wounded.checkHealedFinishedTime >= mCfg.checkHealedFinishRefreshRate then
            state.wounded.checkHealedFinishedTime = 0
            if T.Actor.activeEffects(self):getEffect("restorehealth").magnitude == 0 then
                state.wounded.beingHealed = false
                state.wounded.timeBeforeAskingHealAgain = mCfg.timeBeforeAskingHealAgain
                clearHealer(state)
            end
        end
        return
    end

    if state.wounded.timeBeforeAskingHealAgain > 0 then
        state.wounded.timeBeforeAskingHealAgain = state.wounded.timeBeforeAskingHealAgain - deltaTime
        if state.wounded.timeBeforeAskingHealAgain <= 0 then
            state.wounded.timeBeforeAskingHealAgain = 0
        else
            return
        end
    end

    state.wounded.checkNeedsHealerTime = state.wounded.checkNeedsHealerTime + deltaTime
    if state.wounded.checkNeedsHealerTime >= mCfg.checkNeedsHealerRefreshRate then
        state.wounded.checkNeedsHealerTime = 0
        local healRequests = {}
        if needsHealer(state) then
            mUtil.debugPrint(string.format("\"%s\" needs a healer", actorRId))
            if state.following and canTouchHeal(state.following) then
                healRequests[state.following.id] = { healer = state.following, request = { woundedFriend = self, follow = true } }
            end
            for _, follower in pairs(state.followers) do
                if canTouchHeal(follower) then
                    healRequests[follower.id] = { healer = follower, request = { woundedFriend = self, follow = true } }
                end
            end
            mAi.checkAiPackage(state)
            if state.combatTarget then
                for _, actor in pairs(nearby.actors) do
                    if actor.id ~= self.id and not healRequests[actor.id] and canTouchHeal(actor) then
                        healRequests[actor.id] = { healer = actor, request = { woundedFriend = self, woundedTarget = state.combatTarget } }
                    end
                end
            end
            for _, healRequest in pairs(healRequests) do
                mUtil.debugPrint(string.format("\"%s\" asks help to \"%s\"", actorRId, mUtil.getRecord(healRequest.healer).id))
                state.wounded.healRequestCount = state.wounded.healRequestCount + 1
                healRequest.healer:sendEvent("fc_askHealMe", healRequest.request)
            end
        end
    end
end
woundedModule.checkHealth = checkHealth

local function answerHealMe(state, healAnswer)
    table.insert(state.wounded.healAnswers, healAnswer)
end
woundedModule.answerHealMe = answerHealMe

local restoreHealthModel = T.Static.record(core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].castStatic).model
local function beingHealed(state, spellId)
    T.Actor.activeSpells(self):add({ id = spellId, effects = { 0 } })
    anim.addVfx(self, restoreHealthModel)
    core.sound.playSound3d("restoration hit", self)
    state.wounded.beingHealed = true
end
woundedModule.beingHealed = beingHealed

return woundedModule

