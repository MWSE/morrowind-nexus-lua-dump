local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local anim = require('openmw.animation')

local mDef = require('scripts.FairCare.config.definition')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mStore = require('scripts.FairCare.config.store')
local mWounded = require('scripts.FairCare.ai.wounded')
local mHealer = require('scripts.FairCare.ai.healer')
local mFollow = require('scripts.FairCare.ai.follow')
local mAi = require('scripts.FairCare.ai.ai')
local mTools = require('scripts.FairCare.util.tools')
local mActors = require('scripts.FairCare.util.actors')
local mMagic = require('scripts.FairCare.util.magic')
local log = require('scripts.FairCare.util.log')

local actorId = mTools.objectId(self)
local actorRecord = mTools.getRecord(self)
local firstActivation = true

local cfgStates = {
    unset = "unset",
    set = "set",
    reset = "reset",
    delay = "delay",
}

local state = {
    config = {
        anim = cfgStates.unset,
        spells = cfgStates.unset,
        potions = cfgStates.unset,
    },
    hasOwnSelfHealSpell = false,
    selfHealSpellId = nil,
    touchHealSpellId = nil,
    aiMode = mTypes.aiModes.Default,
    lastActiveGameTime = core.getGameTime(),
    healDelayStartTime = 0,
    ai = mAi.newAiState(),
    wounded = mWounded.newWoundedState(),
    healer = mHealer.newHealerState(),
    follow = mFollow.newFollowState(),
    anim = {
        hasHealingAnimations = false,
        spellcastAttackGroups = {},
        spellcastAnimKeys = {},
        isPlayingAttackGroup = nil,
        lastAttackGroup = nil,
        lastAttackGroupReleased = false,
        noSpellStanceAttackGroups = nil,
    },
    settings = nil,
}

local function isHandled()
    return state.anim.hasHealingAnimations
end

local function addTouchHealSpell()
    if state.touchHealSpellId then
        log(string.format("Adding touch healing spell for %s", actorId))
        T.Actor.spells(self):add(state.touchHealSpellId)
    end
end

local function removeTouchHealSpell()
    if state.touchHealSpellId then
        log(string.format("Removing touch healing spell for %s", actorId))
        T.Actor.spells(self):remove(state.touchHealSpellId)
    end
end

local function isExcludedForCastingHeal()
    if self.type == T.Player then
        return true
    end
    if self.type ~= T.Creature then
        return false
    end
    for _, spell in pairs(T.Actor.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            --log(string.format("Keeping creature %s, as it can cast spells", actorId))
            return false
        end
    end
    log(string.format("Excluding creature %s as it cannot cast spells", actorId))
    return true
end

local function selectHealSpell(spellIds)
    local bestSpellId
    for i, spellId in ipairs(spellIds) do
        if self.type ~= T.Creature or T.Actor.stats.level(self).current >= mCfg.minCreatureLevelForSpellIndex[i] then
            local spell = core.magic.spells.records[spellId]
            if spell.cost <= T.Actor.stats.dynamic.magicka(self).base then
                local castChance = mMagic.calcAutoCastChance(spell, self) / 100
                --log(string.format("Casting chance for spell \"%s\" with %s is %s", spell.id, actorId, castChance))
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
        log(string.format("Actor %s already has a self healing spell \"%s\"", actorId, spellId))
    else
        state.selfHealSpellId = selectHealSpell(mTypes.selfHealSpellIds)
        if state.selfHealSpellId then
            log(string.format("Selected self healing spell \"%s\" for actor %s", state.selfHealSpellId, actorId))
        end
    end
    state.touchHealSpellId = selectHealSpell(mTypes.selfTouchSpellIds)
    if state.touchHealSpellId then
        self:sendEvent(mDef.events.addTouchHealSpell)
        log(string.format("Selected touch healing spell \"%s\" for actor %s", state.touchHealSpellId, actorId))
    end
end

local function removeHealingSpells()
    for _, spell in ipairs(T.Actor.spells(self)) do
        if string.sub(spell.id, 1, 9) == "fair care" then
            log(string.format("Removing old spell \"%s\" from %s", spell.id, actorId))
            T.Actor.spells(self):remove(spell)
        end
    end
end

local function hasHealingHandled()
    return isHandled() and (state.selfHealSpellId or state.touchHealSpellId)
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
    -- check self.count == 0, because when summons disappear they lose their animation, but we still get here
    if not mAi.isActive(state) or self.count == 0 then return end

    if state.anim.spellcastAttackGroups[groupName] then
        state.anim.lastAttackGroup = groupName
    end
    state.anim.isPlayingAttackGroup = isPlayingAttackGroup(key)
    mHealer.onAnimationKey(state, groupName, key)
end

local function handleAnimationCapacities()
    -- Properly detecting animation capabilities have to be done once the actor is active
    state.anim.hasHealingAnimations = anim.hasAnimation(self)

    if not hasHealingHandled() then return end

    local groupNames = {}
    for _, groupName in ipairs(mTypes.potentialAttackGroups) do
        if anim.hasGroup(self, groupName) then
            table.insert(groupNames, groupName)
            state.anim.spellcastAttackGroups[groupName] = true
        end
    end
    -- Detect attack animations to use for actors lacking spell cast animations
    if not state.anim.spellcastAttackGroups.spellcast then
        if #groupNames == 0 then
            state.anim.hasHealingAnimations = false
        else
            state.anim.noSpellStanceAttackGroups = groupNames
        end
    end

    if state.anim.spellcastAttackGroups.spellcast then
        local hasAtLeastOneSpellcastAnimation = false
        for key in pairs(mTypes.spellcastKeys) do
            local hasKey = true
            for _, subKey in ipairs(mTypes.requiredSpellcastSubKeys) do
                if not anim.getTextKeyTime(self, string.format("spellcast: %s %s", key, subKey)) then
                    hasKey = false
                end
            end
            state.anim.spellcastAnimKeys[key] = hasKey
            if hasKey then
                hasAtLeastOneSpellcastAnimation = true
            end
        end
        if not hasAtLeastOneSpellcastAnimation then
            log(string.format("%s has the spellcast animation group but no animation keys", actorId))
            state.anim.hasHealingAnimations = false
        end
    end
end

local function clearState()
    log(string.format("Clearing %s's healing state...", actorId))
    mWounded.clearState(state)
    mHealer.clearState(state)
end

local function onDead()
    log(string.format("%s is dead", actorId))
    clearState()
    state.aiMode = mTypes.aiModes.Dead
end

local function canHavePotions()
    return not T.Actor.isDead(self)
            and self.type == T.NPC
            and state.settings[mStore.groups.global.key].addingPotionsEnabled
            and (not state.selfHealSpellId or state.settings[mStore.groups.potions.key].potionsForHealers)
end

local function clearPotionsState()
    state.config.potions = cfgStates.unset
end

local function addPotions()
    if not next(mMagic.getSelfHealingEquipment(self)) then
        core.sendGlobalEvent(mDef.events.addPotions, self)
    end
end

local function configure()
    if state.config.spells ~= cfgStates.set then
        if state.config.spells == cfgStates.reset then
            clearState()
            removeHealingSpells()
        end
        state.config.spells = cfgStates.set
        if not isExcludedForCastingHeal() then
            addHealSpells()
        end
    end

    if state.config.potions ~= cfgStates.set then
        if canHavePotions() then
            if state.config.potions == cfgStates.delay
                    and state.lastActiveGameTime + state.settings[mStore.groups.potions.key].potionRestockDelayHours * 3600 < core.getGameTime() then
                state.config.potions = cfgStates.reset
            end
            if state.config.potions == cfgStates.reset then
                core.sendGlobalEvent(mDef.events.clearActorData, { actor = self, types = { [mTypes.globalDataTypes.potions] = true }, callback = mDef.events.addPotions })
            end
            if state.config.potions == cfgStates.unset then
                addPotions()
            end
        end
        if state.config.potions ~= cfgStates.delay then
            state.config.potions = cfgStates.set
        end
    end

    if state.config.anim ~= cfgStates.set then
        state.config.anim = cfgStates.set
        handleAnimationCapacities()
    end

    if T.Actor.isDead(self) then
        onDead()
    end
end

local function doRegenSinceLastActive()
    local health = T.Actor.stats.dynamic.health(self)
    if health.current < health.base and mActors.canRegen(state, self, actorRecord) then
        local passedSeconds = (core.getGameTime() - state.lastActiveGameTime) / core.getGameTimeScale()
        log(string.format("%s was inactive %.1f seconds and will regenerate his health accordingly", actorId, passedSeconds))
        mActors.doRegen(state, self, passedSeconds)
    end
end

local function onCombatStart()
    log(string.format("%s starts combat", actorId))
    state.healDelayStartTime = core.getSimulationTime()
    state.config.potions = cfgStates.delay
end

local function onActorActive()
    configure()

    if not isHandled() then return end

    if firstActivation then
        firstActivation = false
        if hasHealingHandled() then
            I.AnimationController.addTextKeyHandler('', addAnimationKeys)
        end
    end

    if state.aiMode ~= mTypes.aiModes.Dead then
        state.aiMode = mTypes.aiModes.Default
        doRegenSinceLastActive()
    end

    mFollow.updateFollowBounds(state)

    log(string.format("%s is active", actorId))
end

local function onActive()
    if self.type == T.Player or not I.HBFS then
        onActorActive()
    end
end

local function onHBFSActorReady(_, eventType)
    if eventType == "reset" then
        state.config.spells = cfgStates.reset
        state.config.potions = cfgStates.reset
    end
    if eventType == "rescale" then
        state.config.spells = cfgStates.reset
        state.config.potions = cfgStates.delay
    end
    if eventType ~= "rescale" then
        onActorActive()
    end
end

local function onInactive()
    if not isHandled() then return end

    if mTools.isObjectInvalid(self.object) then
        log(string.format("%s's object is invalid", actorId))
        -- Probably an expired summon
        mFollow.clearFollowBounds(state)
    else
        log(string.format("%s is inactive", actorId))
    end

    clearState()

    if state.aiMode ~= mTypes.aiModes.Dead then
        state.aiMode = mTypes.aiModes.Inactive
        state.lastActiveGameTime = core.getGameTime()
    end
end

local function checkActorsValidity()
    mAi.clearState(state)
    mAi.checkAiPackage(state, 2 * mCfg.checkAiPackageRefreshTime)
    mFollow.checkActorsValidity(state)
    mWounded.checkActorsValidity(state)
    mHealer.checkActorsValidity(state)
end

local function onUpdate(deltaTime)
    if not isHandled() then return end

    if state.aiMode == mTypes.aiModes.Dead then
        if T.Actor.isDead(self) then
            return
        else
            -- if actor is resurrected
            state.aiMode = mTypes.aiModes.Default
        end
    end

    mAi.checkAiPackage(state, deltaTime)
    mWounded.checkHealth(state, deltaTime)
    mHealer.handleHeal(state, deltaTime)
end

local function setSettings()
    state.settings = {}
    for _, group in pairs(mStore.groups) do
        state.settings[group.key] = group.asTable()
        group.get():subscribe(async:callback(function(_, key)
            state.settings[group.key][key] = group.get(key)
        end))
    end
end

local function onInit()
    setSettings()
end

local function onSave()
    return {
        state = mTools.addAllToMap({}, state, function(k, _) return k ~= "settings" end),
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data and data.version == mDef.saveVersion then
        state = data.state
        setSettings()
        if isHandled() then
            checkActorsValidity()
        end
        return
    end
    state.config.spells = cfgStates.reset
    state.config.potions = cfgStates.reset
    setSettings()
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        isHealing = function() return state.aiMode == mTypes.aiModes.Healing end,
        getSelfHealSpellId = function() return state.selfHealSpellId end,
        getTouchHealSpellId = function() return state.touchHealSpellId end,
        getHealingEquipment = function() return mMagic.getSelfHealingEquipment(self) end,
        getState = function() return state end,
    },
    engineHandlers = {
        onActive = onActive,
        onInactive = onInactive,
        onUpdate = onUpdate,
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Died = onDead,
        [mDef.events.hbfs_onActorReady] = function(data) onHBFSActorReady(data.settings, data.type) end,
        [mDef.events.onActorActive] = onActorActive,
        [mDef.events.addTouchHealSpell] = addTouchHealSpell,
        [mDef.events.removeTouchHealSpell] = removeTouchHealSpell,
        [mDef.events.clearPotionsState] = clearPotionsState,
        [mDef.events.addPotions] = addPotions,
        [mDef.events.onCombatStart] = function() onCombatStart() end,
        [mDef.events.sendHealRequests] = function(followTeam) mWounded.sendHealRequests(state, followTeam) end,
        [mDef.events.answerHealMe] = function(healAnswer) mWounded.answerHealMe(state, healAnswer) end,
        [mDef.events.applyFakeHealSpell] = function(spellId) mWounded.applyFakeHealSpell(spellId) end,
        [mDef.events.clearHealer] = function(healer) mWounded.clearHealer(state, healer) end,
        [mDef.events.askHealMe] = function(data) mHealer.askHealMe(state, data.woundedPartner, data.healChances, data.woundedEnemies, data.hasFollowBounds) end,
        [mDef.events.healFriend] = function(woundedPartner) mHealer.healFriend(state, woundedPartner) end,
        [mDef.events.declineHealHelp] = function(woundedPartner) mHealer.declineHealHelp(state, woundedPartner) end,
        [mDef.events.clearHealerState] = function() mHealer.clearState(state) end,
        [mDef.events.getFollowRoot] = function(data) mFollow.getFollowRoot(state, data) end,
        [mDef.events.gatherFollowers] = function(data) mFollow.gatherFollowers(state, data) end,
        [mDef.events.addFollowTeamMembers] = function(data) mFollow.addFollowTeamMembers(data) end,
        [mDef.events.updateFollowBounds] = function() mFollow.updateFollowBounds(state) end,
        [mDef.events.clearFollowing] = function(following) mFollow.clearFollowing(state, following) end,
        [mDef.events.addFollower] = function(follower) mFollow.addFollower(state, follower) end,
        [mDef.events.clearFollower] = function(follower) mFollow.clearFollower(state, follower) end,
    },
}