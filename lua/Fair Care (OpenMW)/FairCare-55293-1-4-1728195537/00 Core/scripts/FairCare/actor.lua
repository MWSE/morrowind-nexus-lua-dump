local core = require('openmw.core')
local I = require("openmw.interfaces")
local self = require('openmw.self')
local T = require('openmw.types')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mShared = require('scripts.FairCare.shared')
local mUtil = require('scripts.FairCare.util')
local mMagic = require('scripts.FairCare.magic')
local mWounded = require('scripts.FairCare.wounded')
local mHeal = require('scripts.FairCare.healer')
local mFollow = require('scripts.FairCare.follow')
local mAi = require('scripts.FairCare.ai')

local interfaceVersion = 1.0
local selfRecord = mUtil.getRecord(self)
local actorRId = selfRecord.id

local state = {
    healSelfSpellId = nil,
    healTouchSpellId = nil,
    aiMode = mAi.aiModes.Default,
    wounded = mWounded.newWoundedState(),
    healer = mHeal.newHealerState(),
    checkAiPackageTime = 0,
    prevAiPackageKey = "",
    combatTarget = nil,
    followers = {},
    following = nil,
}

local function isExcludedForCastingHeal()
    if self.type == T.NPC then
        --U.debugPrint(string.format("Keeping \"%s\", as it's an NPC", actorRId))
        return false
    end
    if mSettings.creaturesStorage:get(mShared.creatureTypes[selfRecord.type]) then
        for _, spell in pairs(T.Actor.spells(self)) do
            if spell.type == core.magic.SPELL_TYPE.Spell then
                --U.debugPrint(string.format("Keeping creature \"%s\", as it can cast spells", actorRId))
                return false
            end
        end
    end
    --U.debugPrint(string.format("Excluding creature \"%s\", type is \"%s\"", actorRId, mShared.creatureTypes[selfRecord.type]))
    return true
end

local function tryAddHealSpell(spellIds)
    for i, spellId in ipairs(spellIds) do
        if self.type == T.NPC or T.Actor.stats.level(self).current >= mCfg.minCreatureLevelForSpellIndex[i] then
            local spell = core.magic.spells.records[spellId]
            if spell.cost < T.Actor.stats.dynamic.magicka(self).base * mCfg.minUsedMagickaRatioToCastHeal then
                local castChance = mMagic.calcAutoCastChance(spell, self)
                --U.debugPrint(string.format("Casting chance for spell \"%s\" with \"%s\" is %s", spell.id, actorRId, castChance))
                if castChance >= 100 then
                    T.Actor.spells(self):add(spellId)
                    return spellId
                end
            end
        end
    end
    return nil
end

local function onInit()
    if self.type == T.Player then return end
    if isExcludedForCastingHeal() then return end

    local spellId = mMagic.getEasiestSelfHealSpellId(self)
    if spellId then
        state.healSelfSpellId = spellId
        mUtil.debugPrint(string.format("Actor \"%s\" already has a self healing spell \"%s\"", actorRId, spellId))
    else
        state.healSelfSpellId = tryAddHealSpell(mShared.healSelfSpellIds)
        if state.healSelfSpellId then
            mUtil.debugPrint(string.format("Selected self heal spell \"%s\" for actor \"%s\"", state.healSelfSpellId, actorRId))
        end
    end
    state.healTouchSpellId = tryAddHealSpell(mShared.healTouchSpellIds)
    if state.healTouchSpellId then
        mUtil.debugPrint(string.format("Selected touch heal spell \"%s\" for actor \"%s\"", state.healTouchSpellId, actorRId))
    end
end

I.AnimationController.addTextKeyHandler('', function(_, key)
    mHeal.onAnimationKey(state, key)
end)

local function clearHealingBounds()
    if state.healer.woundedFriend then
        mHeal.stopHealingFriend(state)
    end
    if state.wounded.healerFriend then
        state.wounded.healerFriend:sendEvent("fc_stopHealingFriend")
        state.wounded = mWounded.newWoundedState()
    end
end

local onUpdate = function(deltaTime)
    if not mSettings.globalStorage:get("enabled") or state.aiMode == mAi.aiModes.Dead then return end

    state.checkAiPackageTime = state.checkAiPackageTime + deltaTime
    if state.checkAiPackageTime > mCfg.checkAiPackageRefreshTime then
        state.checkAiPackageTime = 0
        mAi.checkAiPackage(state)
    end
    mHeal.handleHeal(state, deltaTime)
    mWounded.checkHealth(state, deltaTime)
end

local function onActive()
    if state.aiMode ~= mAi.aiModes.Dead then
        state.aiMode = mAi.aiModes.Default
    end
end

local function clearState()
    mAi.clearAi(state)
    clearHealingBounds()
    mFollow.clearFollowBounds(state)
end

local function onInactive()
    mUtil.debugPrint(string.format("\"%s\" is inactive", actorRId))
    clearState()
    if state.aiMode ~= mAi.aiModes.Dead then
        state.aiMode = mAi.aiModes.Inactive
    end
end

local function onDead()
    mUtil.debugPrint(string.format("\"%s\" just died", actorRId))
    clearState()
    state.aiMode = mAi.aiModes.Dead
end

local function onSave()
    return {
        state = state,
    }
end

local function onLoad(data)
    state = (data and data.state) and data.state or state
end

local function removeHealSpells()
    if state.healSelfSpellId then
        mUtil.debugPrint(string.format("Removing self heal spell for \"%s\"", actorRId))
        T.Actor.spells(self):remove(state.healSelfSpellId)
    end
    if state.healTouchSpellId then
        mUtil.debugPrint(string.format("Removing self heal spell for \"%s\"", actorRId))
        T.Actor.spells(self):remove(state.healTouchSpellId)
    end
end

local function reAddHealSpells()
    if state.healSelfSpellId then
        mUtil.debugPrint(string.format("Re-adding touch heal spell for \"%s\"", actorRId))
        T.Actor.spells(self):add(state.healSelfSpellId)
    end
    if state.healTouchSpellId then
        mUtil.debugPrint(string.format("Re-adding touch heal spell for \"%s\"", actorRId))
        T.Actor.spells(self):add(state.healTouchSpellId)
    end
end

local function getState()
    return state
end

return {
    interfaceName = mSettings.MOD_NAME,
    interface = {
        version = interfaceVersion,
        IsHealing = function()
            return getState().aiMode == mAi.aiModes.HealFriend
        end,
    },
    engineHandlers = {
        onInit = onInit,
        onActive = onActive,
        onInactive = onInactive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = onDead,
        fc_removeHealSpells = removeHealSpells,
        fc_reAddHealSpells = reAddHealSpells,
        fc_answerHealMe = function(healAnswer) mWounded.answerHealMe(state, healAnswer) end,
        fc_beingHealed = function(spellId) mWounded.beingHealed(state, spellId) end,
        fc_clearHealer = function() mWounded.clearHealer(state) end,
        fc_askHealMe = function(data) mHeal.askHealMe(state, data.woundedFriend, data.woundedTarget, data.follow) end,
        fc_declineHealHelp = function(woundedFriend) mHeal.declineHealHelp(state, woundedFriend) end,
        fc_healFriend = function(data) mHeal.healFriend(state, data.woundedFriend, data.path) end,
        fc_stopHealingFriend = function() mHeal.stopHealingFriend(state) end,
        fc_updateFollowBounds = function() mFollow.updateFollowBounds(state) end,
        fc_addFollower = function(follower) mFollow.addFollower(state, follower) end,
        fc_clearFollower = function(follower) mFollow.clearFollower(state, follower) end,
        fc_clearFollowing = function(following) mFollow.clearFollowing(state, following) end,
    },
}
