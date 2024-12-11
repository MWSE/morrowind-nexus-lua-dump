local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local anim = require('openmw.animation')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mTools = require('scripts.FairCare.tools')
local mActors = require('scripts.FairCare.actors')
local mMagic = require('scripts.FairCare.magic')
local mWounded = require('scripts.FairCare.wounded')
local mHealer = require('scripts.FairCare.healer')
local mFollow = require('scripts.FairCare.follow')
local mAi = require('scripts.FairCare.ai')

local interfaceVersion = 1.1
local saveVersion = 3.62
local actorId = mTools.actorId(self)
local actorRecord = mTools.getRecord(self)
local waitForActivation = false
local isInitialized = false
local waitToClearState = false

local state = {
    hasHealingAnimations = nil,
    hasOwnSelfHealSpell = false,
    selfHealSpellId = nil,
    touchHealSpellId = nil,
    lastActiveGameTime = core.getGameTime(),
    aiMode = mData.aiModes.Default,
    healDelayStartTime = 0,
    ai = mAi.newAiState(),
    wounded = mWounded.newWoundedState(),
    healer = mHealer.newHealerState(),
    follow = mFollow.newFollowState(),
    anim = {
        spellCastAttackGroups = {},
        isPlayingAttackGroup = nil,
        lastAttackGroup = nil,
        lastAttackGroupReleased = false,
        noSpellStanceAttackGroups = nil,
    },
}

local function isExcludedForCastingHeal()
    if self.type ~= T.Creature then
        --mTools.debugPrint(string.format("Keeping %s, as it's an NPC", actorId))
        return false
    end
    for _, spell in pairs(T.Actor.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            --mTools.debugPrint(string.format("Keeping creature %s, as it can cast spells", actorId))
            return false
        end
    end
    mTools.debugPrint(string.format("Excluding creature %s as it cannot cast spells", actorId))
    return true
end

local function selectHealSpell(spellIds)
    local bestSpellId
    for i, spellId in ipairs(spellIds) do
        if self.type ~= T.Creature or T.Actor.stats.level(self).current >= mCfg.minCreatureLevelForSpellIndex[i] then
            local spell = core.magic.spells.records[spellId]
            if spell.cost <= T.Actor.stats.dynamic.magicka(self).base then
                local castChance = mMagic.calcAutoCastChance(spell, self) / 100
                --mTools.debugPrint(string.format("Casting chance for spell \"%s\" with %s is %s", spell.id, actorId, castChance))
                if castChance >= mCfg.minCastChancesToGainSpell then
                    bestSpellId = spellId
                else
                    return bestSpellId
                end
            end
        end
    end
    return bestSpellId
end

local function addHealSpells()
    local spellId = mMagic.getEasiestSelfHealSpellId(self)
    if spellId then
        state.hasOwnSelfHealSpell = true
        state.selfHealSpellId = spellId
        mTools.debugPrint(string.format("Actor %s already has a self healing spell \"%s\"", actorId, spellId))
    else
        state.selfHealSpellId = selectHealSpell(mData.selfHealSpellIds)
        if state.selfHealSpellId then
            mTools.debugPrint(string.format("Selected self healing spell \"%s\" for actor %s", state.selfHealSpellId, actorId))
        end
    end
    state.touchHealSpellId = selectHealSpell(mData.selfTouchSpellIds)
    if state.touchHealSpellId then
        self:sendEvent("fairCare_addTouchHealSpell")
        mTools.debugPrint(string.format("Selected touch healing spell \"%s\" for actor %s", state.touchHealSpellId, actorId))
    end
end

local function removeHealingSpells()
    for _, spell in ipairs(T.Actor.spells(self)) do
        if string.sub(spell.id, 1, 9) == "fair care" then
            mTools.debugPrint(string.format("Removing old spell \"%s\" from %s", spell.id, actorId))
            T.Actor.spells(self):remove(spell)
        end
    end
end

local function hasHealingHandled()
    return state.hasHealingAnimations and (state.selfHealSpellId or state.touchHealSpellId)
end

local function isPlayingAttackGroup(key)
    if not state.anim.lastAttackGroup or not anim.isPlaying(self, state.anim.lastAttackGroup) then
        state.anim.lastAttackGroupReleased = false
        return false
    end
    if state.anim.lastAttackGroupReleased or string.sub(key, -7) == "release" or string.sub(key, -3) == "hit" then
        state.anim.lastAttackGroupReleased = true
    end
    return true
end

local function addAnimationKeys(groupName, key)
    if not mAi.isActive(state) then return end

    if state.anim.spellCastAttackGroups[groupName] then
        state.anim.lastAttackGroup = groupName
    end
    state.anim.isPlayingAttackGroup = isPlayingAttackGroup(key)
    mHealer.onAnimationKey(state, groupName, key)
end

local function handleAnimationCapacities()
    -- Properly detecting animation capabilities have to be done once the actor is active
    if state.hasHealingAnimations == nil then
        state.hasHealingAnimations = anim.hasAnimation(self)

        if hasHealingHandled() then
            local groupNames = {}
            for _, groupName in ipairs(mData.potentialAttackGroups) do
                if anim.hasGroup(self, groupName) then
                    table.insert(groupNames, groupName)
                    state.anim.spellCastAttackGroups[groupName] = true
                end
            end
            -- Detect attack animations to use for actors lacking spell cast animations
            if not state.anim.spellCastAttackGroups.spellcast then
                if #groupNames == 0 then
                    state.hasHealingAnimations = false
                else
                    state.anim.noSpellStanceAttackGroups = groupNames
                end
            end
        end
    end

    if waitForActivation and hasHealingHandled() then
        I.AnimationController.addTextKeyHandler('', addAnimationKeys)
    end
end

local function onActive()
    handleAnimationCapacities()

    if not state.hasHealingAnimations then return end

    if waitForActivation and waitToClearState and isInitialized then
        mTools.debugPrint(string.format("Clearing %s healing bounds...", actorId))
        mWounded.clearState(state)
        mHealer.clearState(state)
        waitToClearState = false
    end
    waitForActivation = false

    mTools.debugPrint(string.format("%s is active", actorId))
    if state.aiMode ~= mData.aiModes.Dead then
        state.aiMode = mData.aiModes.Default

        local health = T.Actor.stats.dynamic.health(self)
        if health.current < health.base and mActors.canRegen(self, actorRecord, state) then
            local passedSeconds = (core.getGameTime() - state.lastActiveGameTime) / core.getGameTimeScale()
            mTools.debugPrint(string.format("%s was inactive %.1f seconds and will regenerate his health accordingly", actorId, passedSeconds))
            mActors.doRegen(self, passedSeconds)
        end
    end
end

local function clearState()
    mWounded.clearState(state)
    mHealer.clearState(state)
end

local function onInactive()
    if not state.hasHealingAnimations then return end

    if mTools.isObjectInvalid(self.object) then
        mTools.debugPrint(string.format("%s's object is invalid", actorId))
        -- Probably an expired summon
        mFollow.clearFollowBounds(state)
    else
        mTools.debugPrint(string.format("%s is inactive", actorId))
    end

    clearState()

    if state.aiMode ~= mData.aiModes.Dead then
        state.aiMode = mData.aiModes.Inactive
        state.lastActiveGameTime = core.getGameTime()
    end
end

-- if load order changed, actor IDs may also have changed
local function checkActorReferences()
    mAi.clearState(state)
    mAi.checkAiPackage(state, 2 * mCfg.checkAiPackageRefreshTime)
    mFollow.checkActorReferences(state)
    mWounded.checkActorReferences(state)
    mHealer.checkActorReferences(state)
end

local function onDead()
    mTools.debugPrint(string.format("%s is dead", actorId))
    clearState()
    state.aiMode = mData.aiModes.Dead
end

local function onInit()
    waitForActivation = true
    isInitialized = true
    if self.type == T.Player then return end

    if not isExcludedForCastingHeal() then
        addHealSpells()
    end

    local isDead = T.Actor.isDead(self)

    if not isDead
            and self.type == T.NPC
            and mSettings.getStorage(mSettings.globalKey):get("addingPotionsEnabled")
            and (not state.selfHealSpellId or mSettings.getStorage(mSettings.potionSettingsKey):get("potionsForHealers"))
            and not mMagic.hasSelfHealingEquipment(self) then
        core.sendGlobalEvent('fairCare_addPotion', self)
    end

    if isDead then
        onDead()
    end
end

local onUpdate = function(deltaTime)
    if not state.hasHealingAnimations then return end

    if state.aiMode == mData.aiModes.Dead then
        if T.Actor.isDead(self) then
            return
        else
            -- if actor is resurrected
            state.aiMode = mData.aiModes.Default
        end
    end

    mAi.checkAiPackage(state, deltaTime)
    mWounded.checkHealth(state, deltaTime)
    mHealer.handleHeal(state, deltaTime)
end

local function onSave()
    return {
        state = state,
        version = saveVersion,
    }
end

local function onLoad(data)
    if data.version == saveVersion then
        state = data.state
        if state.hasHealingAnimations then
            waitForActivation = true
            checkActorReferences()
        end
    else
        removeHealingSpells()
        waitToClearState = true
        onInit()
    end
end

local function addTouchHealSpell()
    if state.touchHealSpellId then
        mTools.debugPrint(string.format("Adding touch healing spell for %s", actorId))
        T.Actor.spells(self):add(state.touchHealSpellId)
    end
end

local function removeTouchHealSpell()
    if state.touchHealSpellId then
        mTools.debugPrint(string.format("Removing touch healing spell for %s", actorId))
        T.Actor.spells(self):remove(state.touchHealSpellId)
    end
end

local function getState()
    return state
end

return {
    interfaceName = mSettings.MOD_NAME,
    interface = {
        version = interfaceVersion,
        isHealing = function() return getState().aiMode == mData.aiModes.Healing end,
        getSelfHealSpellId = function() return getState().selfHealSpellId end,
        getTouchHealSpellId = function() return getState().touchHealSpellId end,
        hasHealingItems = function() return mMagic.hasSelfHealingEquipment(self) end,
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
        fairCare_addTouchHealSpell = addTouchHealSpell,
        fairCare_removeTouchHealSpell = removeTouchHealSpell,
        fairCare_sendHealRequests = function(followTeam) mWounded.sendHealRequests(state, followTeam) end,
        fairCare_answerHealMe = function(healAnswer) mWounded.answerHealMe(state, healAnswer) end,
        fairCare_fakeTouchHealed = function(spellId) mWounded.fakeTouchHealed(state, spellId) end,
        fairCare_clearHealer = function(healer) mWounded.clearHealer(state, healer) end,
        fairCare_askHealMe = function(data) mHealer.askHealMe(state, data.woundedPartner, data.healChances, data.woundedEnemies, data.hasFollowBounds) end,
        fairCare_healFriend = function(woundedPartner) mHealer.healFriend(state, woundedPartner) end,
        fairCare_declineHealHelp = function(woundedPartner) mHealer.declineHealHelp(state, woundedPartner) end,
        fairCare_clearHealerState = function() mHealer.clearState(state) end,
        fairCare_getFollowRoot = function(data) mFollow.getFollowRoot(state, data) end,
        fairCare_gatherFollowers = function(data) mFollow.gatherFollowers(state, data) end,
        fairCare_addFollowTeamMembers = function(data) mFollow.addFollowTeamMembers(data) end,
        fairCare_updateFollowBounds = function() mFollow.updateFollowBounds(state) end,
        fairCare_clearFollowing = function(following) mFollow.clearFollowing(state, following) end,
        fairCare_addFollower = function(follower) mFollow.addFollower(state, follower) end,
        fairCare_clearFollower = function(follower) mFollow.clearFollower(state, follower) end,
    },
}