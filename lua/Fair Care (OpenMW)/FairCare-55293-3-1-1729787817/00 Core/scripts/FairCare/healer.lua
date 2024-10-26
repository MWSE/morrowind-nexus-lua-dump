local core = require('openmw.core')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mActors = require('scripts.FairCare.actors')
local mChances = require('scripts.FairCare.chances')
local mTools = require('scripts.FairCare.tools')
local mMagic = require('scripts.FairCare.magic')
local mAi = require('scripts.FairCare.ai')

local module = {}

local actorId = mActors.actorId(self)

local function newHealerState()
    return {
        woundedPartner = nil,
        recurrentChances = nil,
        touchHealTargetDistance = nil,
        healSpellSelected = false,
        waitingToHeal = false,
        updateActionTime = 0,
        pathToFriend = nil,
        lastTravelPoints = {},
        travelPointsIndex = 0,
        updateTravelPointsTime = 0,
        castingHeal = false,
        controls = mActors.newControls(self),
    }
end
module.newHealerState = newHealerState

local function askHealMe(state, woundedPartner, healChances, woundedTarget, hasFollowBounds)
    mChances.setChance(healChances)

    if state.healer.woundedPartner or not mAi.isActive(state) then
        healChances.aborted = true
        woundedPartner:sendEvent("fc_answerHealMe", { healChances = healChances })
        return
    end
    mAi.checkAiPackage(state)
    if not hasFollowBounds and not mTools.areObjectEquals(state.ai.combatTarget, woundedTarget) then
        healChances.aborted = true
        woundedPartner:sendEvent("fc_answerHealMe", { healChances = healChances })
        return
    end

    if mActors.isHealAgainDelayOk(state.lastHealAttemptTime, healChances.chance) then
        state.healer.woundedPartner = woundedPartner
        state.healer.recurrentChances = healChances
        woundedPartner:sendEvent("fc_answerHealMe", { healChances = healChances, healerFriend = self })
    else
        healChances.isSuccess = false
        woundedPartner:sendEvent("fc_answerHealMe", { healChances = healChances, healerFriend = self, tooEarly = true })
    end
end
module.askHealMe = askHealMe

local function declineHealHelp(state)
    state.healer.woundedPartner = nil
    state.healer.recurrentChances = nil
end
module.declineHealHelp = declineHealHelp

local function enableOtherMods(enable)
    if I.MercyCAO then
        mSettings.debugPrint(string.format("%s Mercy CAO control for %s", enable and "Enabling" or "Disabling", actorId))
        I.MercyCAO.setEnabled(enable)
    end
    if I.TakeCover then
        mSettings.debugPrint(string.format("%s Take Cover hiding for %s", enable and "Enabling" or "Disabling", actorId))
        I.TakeCover.enableHiding(enable)
    end
end

local function stopHealingFriend(state)
    if state.healer.woundedPartner then
        mSettings.debugPrint(string.format("%s stops healing %s", actorId, mActors.actorId(state.healer.woundedPartner)))
    end
    if state.aiMode == mData.aiModes.HealFriend then
        state.aiMode = mData.aiModes.Default
        state.healer.woundedPartner:sendEvent("fc_clearHealer")
        state.lastHealAttemptTime = core.getSimulationTime()
    end
    state.healer = newHealerState()
    self:enableAI(true)
    enableOtherMods(true)
end
module.stopHealingFriend = stopHealingFriend

local function clearState(state)
    if state.healer.woundedPartner then
        stopHealingFriend(state)
    end
end
module.clearState = clearState

local function setPathToFriend(state)
    if self.id == state.healer.woundedPartner.id then return true end

    state.healer.pathToFriend = mActors.getPath(self, state.healer.woundedPartner)
    if state.healer.pathToFriend == nil then
        mSettings.debugPrint(string.format("%s cannot find a path to %s anymore", actorId, mActors.actorId(state.healer.woundedPartner)))
        return false
    end
    return true
end

local function startHealFriend(state)
    if not mAi.isActive(state) then
        state.healer.woundedPartner:sendEvent("fc_clearHealer")
        return
    end

    state.aiMode = mData.aiModes.HealFriend
    setPathToFriend(state)
    enableOtherMods(false)
    self:enableAI(false)
    state.healer.controls.run = true
    state.healer.controls.sneak = false
    T.Actor.setSelectedSpell(self, core.magic.spells.records[state.healSpellId])
end

local function healFriend(state)
    mSettings.debugPrint(string.format("%s will try to heal %s", actorId, mActors.actorId(state.healer.woundedPartner)))
    state.healer.touchHealTargetDistance = mMagic.touchHealTargetDistance(self, state.healer.woundedPartner)
    if state.isSpellCasting then
        state.healer.waitingToHeal = true
    else
        startHealFriend(state)
    end
end
module.healFriend = healFriend

local function spellSucceeded(state)
    if core.sound.isSoundPlaying(mMagic.healFailSound, self) then
        mSettings.debugPrint(string.format("%s failed to cast spell \"%s\" on %s",
                actorId, state.healSpellId, mActors.actorId(state.healer.woundedPartner)))
        return false
    end

    if self.id == state.healer.woundedPartner.id then return true end

    local spellTouched = (self:getBoundingBox().center - state.healer.woundedPartner:getBoundingBox().center):length() <= state.healer.touchHealTargetDistance
    mSettings.debugPrint(string.format("%s casted touch spell \"%s\" on %s, touched = %s",
            actorId, state.touchHealSpellId, mActors.actorId(state.healer.woundedPartner), spellTouched))
    return spellTouched
end

local function releaseSpell(state)
    if spellSucceeded(state) then
        state.healer.woundedPartner:sendEvent("fc_castSelfHeal", state.healSpellId)
    end
    stopHealingFriend(state)
end

local function onAnimationKey(state, groupName, key)
    -- Some creatures like bonewalkers don't have spell stance animations, then we track stop attack animations
    if not state.hasSpellCastAnim
            and state.aiMode == mData.aiModes.HealFriend
            and state.healer.healSpellSelected
            and string.sub(key, -4) == "stop" then
        releaseSpell(state)
    end

    if state.healer.waitingToHeal and not state.isSpellCasting then
        state.healer.waitingToHeal = false
        startHealFriend(state)
    end

    if state.aiMode == mData.aiModes.HealFriend
            and groupName == "spellcast"
            and key == "touch release" then
        releaseSpell(state)
    end
end
module.onAnimationKey = onAnimationKey

local function isStuck(state, hasReached, deltaTime)
    if self.id == state.healer.woundedPartner.id then return false end

    state.healer.updateTravelPointsTime = state.healer.updateTravelPointsTime + deltaTime
    if state.healer.updateTravelPointsTime < mCfg.saveLastTravelPointsRate then return false end
    state.healer.updateTravelPointsTime = 0

    if hasReached then
        -- healer stops but it's ok
        state.healer.travelPointsIndex = 0
        state.healer.lastTravelPoints = {}
        return
    end

    local index = state.healer.travelPointsIndex % mCfg.travelPointCountForSpeed + 1
    state.healer.lastTravelPoints[index] = self.position
    if state.healer.travelPointsIndex + 1 >= mCfg.travelPointCountForSpeed then
        local prevPoint = state.healer.lastTravelPoints[(state.healer.travelPointsIndex - mCfg.travelPointCountForSpeed + 1) % mCfg.travelPointCountForSpeed + 1]
        local travelDistance = (state.healer.lastTravelPoints[index] - prevPoint):length()
        local speed = travelDistance / (mCfg.saveLastTravelPointsRate * (mCfg.travelPointCountForSpeed - 1))
        local speedPercent = speed / T.Actor.getRunSpeed(self)
        if speedPercent < mCfg.minSpeedRatioToContinueHealing then
            return true
        end
    end
    state.healer.travelPointsIndex = state.healer.travelPointsIndex + 1
    return false
end

local function checkReadyToCast(state)
    if state.healer.healSpellSelected then
        if T.Actor.getStance(self) == T.Actor.STANCE.Spell then
            return true
        end
        mSettings.debugPrint(string.format("%s will switch to spell stance", actorId))
        state.isSpellCasting = false
        state.healer.waitingToHeal = false
        T.Actor.setStance(self, T.Actor.STANCE.Spell)
        return false
    end

    local spell = T.Actor.getSelectedSpell(self)
    if spell and spell.id == state.healSpellId then
        mSettings.debugPrint(string.format("Heal spell selected for %s", actorId))
        state.healer.healSpellSelected = true
    else
        mSettings.debugPrint(string.format("Heal spell not yet selected for %s. Current spell is %s", actorId, spell))
    end
    return false
end

local function updateHealAction(state, deltaTime)
    state.healer.updateActionTime = state.healer.updateActionTime + deltaTime
    if state.healer.updateActionTime < mCfg.updateActionRefreshRate then return true end
    state.healer.updateActionTime = 0

    if not setPathToFriend(state) then
        return false
    end

    if state.healer.castingHeal then return true end

    local healChances = mChances.newHealChances()
    if self.id == state.healer.woundedPartner.id then
        mChances.setSelfHealingChances(state, self, healChances)
    else
        mChances.setHealerChances(state.healSpellId, state.healer.woundedPartner, self, state.healer, healChances)
    end
    mChances.setChance(healChances)
    -- If heal conditions are worst than before, let's decide again if we continue healing
    if healChances.aborted or not healChances.isSuccess and mChances.areChancesBetter(state.healer.recurrentChances.chance, healChances.chance) then
        mSettings.debugPrint(string.format("%s stops trying to heal %s. Chances = %s",
                actorId, mActors.actorId(state.healer.woundedPartner), mChances.toString(healChances)))
        return false
    end
    return true
end

local function handleHeal(state, deltaTime)
    if not updateHealAction(state, deltaTime) then
        stopHealingFriend(state)
        return
    end

    local hasReached = mActors.travelToActor(
            state.healer.controls,
            self,
            state.healer.pathToFriend,
            state.healer.woundedPartner,
            mCfg.distanceToPathPointTolerance,
            state.healer.touchHealTargetDistance + mCfg.distanceToWoundedTolerance)

    if isStuck(state, hasReached, deltaTime) then
        mSettings.debugPrint(string.format("%s got stuck while trying to heal %s", actorId, mActors.actorId(state.healer.woundedPartner)))
        stopHealingFriend(state)
        return
    end

    if not state.healer.castingHeal and checkReadyToCast(state) and hasReached and state.healer.healSpellSelected then
        mSettings.debugPrint(string.format("%s casts heal spell on %s", actorId, mActors.actorId(state.healer.woundedPartner)))
        state.healer.castingHeal = true
    end

    if state.healer.castingHeal then
        state.healer.controls.use = self.ATTACK_TYPE.Any
    end

    self:enableAI(false)
    mActors.applyControls(state.healer.controls, self)
end
module.handleHeal = handleHeal

return module