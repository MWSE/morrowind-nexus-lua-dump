local core = require('openmw.core')
local I = require("openmw.interfaces")
local self = require('openmw.self')
local T = require('openmw.types')
local anim = require('openmw.animation')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mActors = require('scripts.FairCare.actors')
local mMagic = require('scripts.FairCare.magic')
local mWounded = require('scripts.FairCare.wounded')
local mHeal = require('scripts.FairCare.healer')
local mFollow = require('scripts.FairCare.follow')
local mAi = require('scripts.FairCare.ai')

local interfaceVersion = 1.0
local saveVersion = 3.1
local actorId = mActors.actorId(self)
local gameLoaded = false

local state = {
    enabled = false,
    hasSpellCastAnim = false,
    hasOwnSelfHealSpell = false,
    healSpellId = nil,
    aiMode = mData.aiModes.Default,
    isSpellCasting = false,
    lastHealAttemptTime = 0,
    ai = mAi.newAiState(),
    wounded = mWounded.newWoundedState(),
    healer = mHeal.newHealerState(),
    follow = mFollow.newFollowState(),
}

local function isExcludedForCastingHeal()
    if self.type ~= T.Creature then
        --U.debugPrint(string.format("Keeping %s, as it's an NPC", actorId))
        return false
    end
    for _, spell in pairs(T.Actor.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            --U.debugPrint(string.format("Keeping creature %s, as it can cast spells", actorId))
            return false
        end
    end
    mSettings.debugPrint(string.format("Excluding creature %s as it cannot cast spells", actorId))
    return true
end

local function selectHealSpell(spellIds)
    for i, spellId in ipairs(spellIds) do
        if self.type ~= T.Creature or T.Actor.stats.level(self).current >= mCfg.minCreatureLevelForSpellIndex[i] then
            local spell = core.magic.spells.records[spellId]
            if spell.cost <= T.Actor.stats.dynamic.magicka(self).base then
                local castChance = mMagic.calcAutoCastChance(spell, self)
                --U.debugPrint(string.format("Casting chance for spell \"%s\" with %s is %s", spell.id, actorId, castChance))
                if castChance >= 100 then
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
        state.hasOwnSelfHealSpell = true
        mSettings.debugPrint(string.format("Actor %s already has a self healing spell \"%s\"", actorId, spellId))
    end
    state.healSpellId = selectHealSpell(mData.selfSpellIds)
    if state.healSpellId then
        self:sendEvent("fc_addHealSpell")
        mSettings.debugPrint(string.format("Selected heal spell \"%s\" for actor %s", state.healSpellId, actorId))
    end
    gameLoaded = true
end

local onUpdate = function(deltaTime)
    if not state.enabled then return end
    if state.aiMode == mData.aiModes.Dead then
        if T.Actor.isDead(self) then
            return
        else
            state.aiMode = mData.aiModes.Default
        end
    end

    mAi.checkAiPackage(state, deltaTime)
    mWounded.checkHealth(state, deltaTime)
    if state.aiMode == mData.aiModes.HealFriend then
        mHeal.handleHeal(state, deltaTime)
    end
end

local function handleAnimationCapacities()
    -- Properly detecting animation capabilities have to be done once the actor is active
    state.enabled = anim.hasAnimation(self)
    if state.enabled then
        state.hasSpellCastAnim = anim.hasGroup(self, "spellcast")
        if gameLoaded then
            I.AnimationController.addTextKeyHandler('', function(groupName, key)
                if groupName == "spellcast" then
                    state.isSpellCasting = string.sub(key, -5) == "start"
                end
                mHeal.onAnimationKey(state, groupName, key)
            end)
            gameLoaded = false
        end
    end
end

local function onActive()
    handleAnimationCapacities()
    mFollow.checkFollowBoundValidity(state)

    mSettings.debugPrint(string.format("%s is active", actorId))
    if state.aiMode ~= mData.aiModes.Dead then
        state.aiMode = mData.aiModes.Default
    end
end

local function clearState()
    mWounded.clearState(state)
    mHeal.clearState(state)
end

local function onInactive()
    mSettings.debugPrint(string.format("%s is inactive", actorId))
    clearState()
    if state.aiMode ~= mData.aiModes.Dead then
        state.aiMode = mData.aiModes.Inactive
    end
end

local function onDead()
    mSettings.debugPrint(string.format("%s just died", actorId))
    clearState()
    state.aiMode = mData.aiModes.Dead
end

local function onSave()
    return {
        state = state,
        version = saveVersion,
    }
end

local function onLoad(data)
    if data and data.saveVersion == saveVersion then
        state = data.state
        gameLoaded = true
    else
        onInit()
    end
end

local function removeHealSpell()
    if state.healSpellId then
        mSettings.debugPrint(string.format("Removing heal spell for %s", actorId))
        T.Actor.spells(self):remove(state.healSpellId)
    end
end

local function addHealSpell()
    if state.healSpellId then
        mSettings.debugPrint(string.format("Adding heal spell for %s", actorId))
        T.Actor.spells(self):add(state.healSpellId)
    end
end

local function getState()
    return state
end

return {
    interfaceName = mSettings.MOD_NAME,
    interface = {
        version = interfaceVersion,
        isHealing = function() return getState().aiMode == mData.aiModes.HealFriend end,
        getState = getState,
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
        fc_removeHealSpell = removeHealSpell,
        fc_addHealSpell = addHealSpell,
        fc_answerHealMe = function(healAnswer) mWounded.answerHealMe(state, healAnswer) end,
        fc_castSelfHeal = function(spellId) mWounded.castSelfHeal(state, spellId) end,
        fc_clearHealer = function() mWounded.clearHealer(state) end,
        fc_askHealMe = function(data) mHeal.askHealMe(state, data.woundedPartner, data.healChances, data.woundedTarget, data.hasFollowBounds) end,
        fc_declineHealHelp = function() mHeal.declineHealHelp(state) end,
        fc_healFriend = function() mHeal.healFriend(state) end,
        fc_stopHealingFriend = function() mHeal.stopHealingFriend(state) end,
        fc_updateFollowBounds = function() mFollow.updateFollowBounds(state) end,
        fc_addFollower = function(follower) mFollow.addFollower(state, follower) end,
        fc_clearFollower = function(follower) mFollow.clearFollower(state, follower) end,
        fc_clearFollowing = function(following) mFollow.clearFollowing(state, following) end,
        fc_setFollowerTeam = function(followerTeam) mFollow.setFollowerTeam(state, followerTeam) end,
    },
}