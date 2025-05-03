local core = require('openmw.core')
local self = require('openmw.self')
local util = require("openmw.util")
local anim = require('openmw.animation')
local T = require('openmw.types')
local I = require("openmw.interfaces")

local mDef = require('scripts.FairCare.config.definition')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mAi = require('scripts.FairCare.ai.ai')
local mChances = require('scripts.FairCare.util.chances')
local mMagic = require('scripts.FairCare.util.magic')
local mActors = require('scripts.FairCare.util.actors')
local mTools = require('scripts.FairCare.util.tools')
local log = require('scripts.FairCare.util.log')

local module = {}

local actorId = mTools.objectId(self)

local function newHealerState()
    return {
        woundedPartner = nil,
        helpAnswerTime = nil,
        recurrentChances = nil,
        waitingToHeal = false,
        animConfig = nil,
        animStartTime = 0,
        startTime = nil,
        forceOtherSpellcastAnimation = false,
        isHidden = false,
        hasArrived = false,
        healSpellSelected = false,
        updateActionTime = 0,
        healing = false,
        controls = mAi.newControls(self),
        travel = {
            touchHealDistance = nil,
            path = nil,
            speedLastPoints = {},
            speedPointsIndex = 0,
            updateSpeedPointsTime = 0,
        },
    }
end
module.newHealerState = newHealerState

local function isSelfHealing(state)
    return self.id == state.healer.woundedPartner.id
end

local function clearState(state)
    if state.healer.woundedPartner then
        log(string.format("%s stops healing %s", actorId, mTools.objectId(state.healer.woundedPartner)))
    end
    if state.aiMode == mTypes.aiModes.Healing then
        state.aiMode = mTypes.aiModes.Default
        state.healer.woundedPartner:sendEvent(mDef.events.clearHealer, self)
        state.healDelayStartTime = core.getSimulationTime()
        if isSelfHealing(state) then
            T.Actor.spells(self):remove(state.selfHealSpellId)
        end
        self:enableAI(true)
        mAi.setEnableOtherAiMods(true)
    end
    state.healer = newHealerState()
    mAi.applyControls(state.healer.controls)
end
module.clearState = clearState

local function checkActorsValidity(state)
    if state.healer.woundedPartner and mTools.isObjectInvalid(state.healer.woundedPartner) then
        log(string.format("Clearing %s invalid wounded partner %s", actorId, state.healer.woundedPartner))
        clearState(state)
    end
end
module.checkActorsValidity = checkActorsValidity

local function hasCommonEnemies(state, actorEnemies)
    if not actorEnemies or not state.ai.enemies then return false end
    for _, selfEnemy in ipairs(state.ai.enemies) do
        for _, actorEnemy in ipairs(actorEnemies) do
            if selfEnemy.id == actorEnemy.id then return true end
        end
    end
    return false
end

local function askHealMe(state, woundedPartner, healChances, woundedEnemies, hasFollowBounds)
    if state.healer.woundedPartner or state.wounded.waitingAiSelfHealTime or not mAi.isActive(state) then
        healChances.aborted = true
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
        return
    end
    if self.id ~= woundedPartner.id and not hasFollowBounds then
        mAi.checkAiPackage(state)
        if not hasCommonEnemies(state, woundedEnemies) then
            healChances.aborted = true
            woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
            return
        end
    end

    if not state.ai.enemies or mActors.isHealAgainDelayOk(state, healChances.chance) then
        state.healer.woundedPartner = woundedPartner
        state.healer.recurrentChances = healChances
        state.healer.helpAnswerTime = 0
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances, healerPartner = self })
    else
        healChances.aborted = true
        log(string.format("%s won't heal %s, too early, chances:%s",
                actorId, mTools.objectId(woundedPartner), mChances.toString(state, healChances)))
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
    end
end
module.askHealMe = askHealMe

local function declineHealHelp(state, woundedPartner)
    if not woundedPartner or mTools.areObjectEquals(state.healer.woundedPartner, woundedPartner) then
        state.healer.woundedPartner = nil
        state.healer.recurrentChances = nil
        state.healer.helpAnswerTime = nil
    end
end
module.declineHealHelp = declineHealHelp

local function setRetreatPosition(state)
    local data = mActors.getRetreatPosition(self)
    if not data.position then return end

    local path = mActors.getPath(self, data.position)
    local firstPointAngle
    if path and #path > 1 and (path[2] - path[1]):length() >= mCfg.minEscapePathSegment then
        path = { path[1], path[2] }
        firstPointAngle = math.atan2((data.position - self.position).y, (data.position - self.position).x)
                - math.atan2((path[2] - self.position).y, (path[2] - self.position).x)
        if math.abs(firstPointAngle) < math.pi / 16 then
            state.healer.travel.path = path
        end
    end
    if state.healer.travel.path then
        log(string.format("%s will escape with angle %d, first point deviation angle %d, at distance %d/%d, with targets %s",
                actorId, math.deg(data.angle), math.deg(firstPointAngle), (path[2] - path[1]):length(), data.distance, mTools.objectsIds(data.targets)))
    else
        log(string.format("%s will NOT escape with angle %d, first point deviation angle %s, at distance %s/%d, with targets %s",
                actorId, math.deg(data.angle), firstPointAngle and util.round(math.deg(firstPointAngle)) or "-",
                path and path[2] and util.round((path[2] - path[1]):length()) or "-", data.distance, mTools.objectsIds(data.targets)))
    end
end

local function setPathToFriend(state)
    state.healer.travel.path = mActors.getPathToTarget(self, state.healer.woundedPartner, state.healer.travel.touchHealDistance)
    if not state.healer.travel.path then
        log(string.format("%s cannot find a path to %s anymore", actorId, mTools.objectId(state.healer.woundedPartner)))
        return false
    end
    return true
end

local function getSpellId(state)
    return isSelfHealing(state) and state.selfHealSpellId or state.touchHealSpellId
end

local function forceOtherSpellcastAnimation(state)
    if isSelfHealing(state) then
        if state.anim.spellcastAnimKeys[mTypes.spellcastKeys.self] then
            return false
        end
        return state.anim.spellcastAnimKeys[mTypes.spellcastKeys.touch] and mTypes.spellcastKeys.touch or mTypes.spellcastKeys.target
    else
        if state.anim.spellcastAnimKeys[mTypes.spellcastKeys.touch] then
            return false
        end
        return state.anim.spellcastAnimKeys[mTypes.spellcastKeys.target] and mTypes.spellcastKeys.target or mTypes.spellcastKeys.self
    end
end

local function startHealingFriend(state)
    if not mAi.isActive(state) then
        state.healer.woundedPartner:sendEvent(mDef.events.clearHealer, self)
        clearState(state)
        return
    end

    state.healer.isHidden = mAi.isActorHidden()
    mAi.setEnableOtherAiMods(false)
    self:enableAI(false)
    state.healer.controls.run = true

    state.aiMode = mTypes.aiModes.Healing
    state.healer.travel.touchHealDistance = mMagic.touchHealDistance(self, state.healer.woundedPartner)
    state.healer.forceOtherSpellcastAnimation = forceOtherSpellcastAnimation(state)
    state.healer.animConfig = mActors.getCastAnimationConfig(
            state.anim.noSpellStanceAttackGroups,
            state.healer.forceOtherSpellcastAnimation,
            isSelfHealing(state))
    state.healer.startTime = core.getSimulationTime()
    if isSelfHealing(state) then
        T.Actor.spells(self):add(state.selfHealSpellId)
    else
        setPathToFriend(state)
    end
end

local function healFriend(state, woundedPartner)
    if not mTools.areObjectEquals(woundedPartner, state.healer.woundedPartner) then
        -- answer is too late?
        woundedPartner:sendEvent(mDef.events.clearHealer, self)
        return
    end
    log(string.format("%s will try to heal %s", actorId, mTools.objectId(state.healer.woundedPartner)))
    state.healer.helpAnswerTime = nil
    if state.anim.isPlayingAttackGroup and not state.anim.lastAttackGroupReleased then
        log(string.format("%s has not finished his attacks yet", actorId))
        state.healer.waitingToHeal = true
        state.healer.animStartTime = core.getSimulationTime()
    else
        startHealingFriend(state)
    end
end
module.healFriend = healFriend

local function touchSpellSucceeded(state)
    if core.sound.isSoundPlaying(mMagic.healFailSound, self) then
        log(string.format("%s failed to cast spell \"%s\" on %s",
                actorId, state.touchHealSpellId, mTools.objectId(state.healer.woundedPartner)))
        return false
    end

    local spellTouched = mActors.isCloseEnough(self, state.healer.woundedPartner, state.healer.travel.touchHealDistance)
    log(string.format("%s casted touch spell \"%s\" on %s, touched = %s",
            actorId, state.touchHealSpellId, mTools.objectId(state.healer.woundedPartner), spellTouched))
    return spellTouched
end

local function onAnimationKey(state, _, key)
    if state.healer.waitingToHeal and (not state.anim.isPlayingAttackGroup or state.anim.lastAttackGroupReleased) then
        log(string.format("%s just finished is attack", actorId))
        state.healer.waitingToHeal = false
        startHealingFriend(state)
    end

    if state.healer.waitingToHeal or state.healer.healing and not state.anim.isPlayingAttackGroup then
        if not mActors.canAct(self) then
            log(string.format("%s cannot act, aborting...", actorId))
            clearState(state)
        elseif core.getSimulationTime() > state.healer.animStartTime + mCfg.animationExistsMaxDelay then
            log(string.format("%s is not playing his animation, something happened, aborting...", actorId))
            clearState(state)
        end
    end

    if state.aiMode == mTypes.aiModes.Healing and state.healer.healing and key == state.healer.animConfig.releaseKey then
        if isSelfHealing(state) then
            if state.healer.forceOtherSpellcastAnimation then
                self:sendEvent(mDef.events.applyFakeHealSpell, state.selfHealSpellId)
            end
        elseif touchSpellSucceeded(state) then
            state.healer.woundedPartner:sendEvent(mDef.events.applyFakeHealSpell, state.touchHealSpellId)
        end
        clearState(state)
    end
end
module.onAnimationKey = onAnimationKey

local function isStuck(state, deltaTime)
    state.healer.travel.updateSpeedPointsTime = state.healer.travel.updateSpeedPointsTime + deltaTime
    if state.healer.travel.updateSpeedPointsTime < mCfg.saveLastTravelPointsRate then return false end
    state.healer.travel.updateSpeedPointsTime = 0

    local index = state.healer.travel.speedPointsIndex % mCfg.travelPointCountForSpeed + 1
    state.healer.travel.speedLastPoints[index] = self.position
    if state.healer.travel.speedPointsIndex + 1 >= mCfg.travelPointCountForSpeed then
        local prevPoint = state.healer.travel.speedLastPoints[(state.healer.travel.speedPointsIndex - mCfg.travelPointCountForSpeed + 1) % mCfg.travelPointCountForSpeed + 1]
        local travelDistance = (state.healer.travel.speedLastPoints[index] - prevPoint):length()
        local speed = travelDistance / (mCfg.saveLastTravelPointsRate * (mCfg.travelPointCountForSpeed - 1))
        local speedPercent = speed / T.Actor.getRunSpeed(self)
        if speedPercent < mCfg.minSpeedRatioToContinueHealing then
            return true
        end
    end
    state.healer.travel.speedPointsIndex = state.healer.travel.speedPointsIndex + 1
    return false
end

local function prepareToCast(state)
    if state.healer.healSpellSelected then
        if T.Actor.getStance(self) == T.Actor.STANCE.Spell then
            if state.anim.isPlayingAttackGroup then
                --log(string.format("%s did not finished the group animation \"%s\"", actorId, state.anim.lastAttackGroup))
                return false
            end
            return true
        end
        log(string.format("%s will switch to spell stance", actorId))
        T.Actor.setStance(self, T.Actor.STANCE.Spell)
        return false
    end

    local spell = T.Actor.getSelectedSpell(self)
    if spell and spell.id == getSpellId(state) then
        log(string.format("Healing spell selected for %s", actorId))
        state.healer.healSpellSelected = true
    else
        T.Actor.setSelectedSpell(self, core.magic.spells.records[getSpellId(state)])
        log(string.format("Healing spell not yet selected for %s. Current spell is %s", actorId, spell))
    end
    return false
end

local function updateHealAction(state, deltaTime)
    state.healer.updateActionTime = state.healer.updateActionTime + deltaTime
    if state.healer.updateActionTime < mCfg.updateActionRefreshRate then return true end
    state.healer.updateActionTime = 0

    if not isSelfHealing(state) and not setPathToFriend(state) then return false end

    if state.healer.healing then return true end

    local healChances = mChances.newHealChances()
    if isSelfHealing(state) then
        mChances.setSelfHealingChances(state.selfHealSpellId, self, healChances)
    else
        healChances.aborted = not mChances.setHealerChances(state, state.touchHealSpellId, state.healer.woundedPartner, self, state.healer, healChances)
    end
    mChances.setChance(state, healChances)
    -- If heal conditions are worst than before, let's decide again if we continue healing
    if healChances.aborted or not healChances.isSuccess and not mChances.areNewChancesGoodEnough(healChances.chance, state.healer.recurrentChances.chance) then
        log(string.format("%s stops trying to heal %s. Chances = %s",
                actorId, mTools.objectId(state.healer.woundedPartner), mChances.toString(state, healChances)))
        return false
    end
    return true
end

local function handleHeal(state, deltaTime)
    if state.aiMode ~= mTypes.aiModes.Healing then
        if state.healer.helpAnswerTime then
            state.healer.helpAnswerTime = state.healer.helpAnswerTime + deltaTime
            if state.healer.helpAnswerTime > mCfg.checkNeedsHealerRefreshRate / 2 then
                log(string.format("%s did not get any help confirmation answer from %s", actorId, mTools.objectId(state.healer.woundedPartner)))
                declineHealHelp(state)
            end
        end
        return
    end

    if not updateHealAction(state, deltaTime) then
        clearState(state)
        return
    end

    if isSelfHealing(state) then
        if state.ai.enemies
                and not state.healer.isHidden
                and state.anim.spellcastAttackGroups.spellcast
                and not state.healer.hasArrived
                and state.healer.startTime + mCfg.maxEscapeTime > core.getSimulationTime()
        then
            if state.healer.travel.path then
                state.healer.hasArrived = mActors.travel(state.healer.controls, self, state.healer.travel.path, deltaTime)
            else
                setRetreatPosition(state)
            end
        else
            state.healer.hasArrived = true
        end
    else
        state.healer.hasArrived = mActors.travelToTarget(
                state.healer.controls,
                self,
                state.healer.travel.path,
                state.healer.woundedPartner,
                state.healer.travel.touchHealDistance + mCfg.distanceToWoundedTolerance,
                deltaTime)
    end

    if isStuck(state, deltaTime) then
        if isSelfHealing(state) then
            state.healer.hasArrived = true
        elseif not state.healer.hasArrived then
            log(string.format("%s got stuck while trying to heal %s", actorId, mTools.objectId(state.healer.woundedPartner)))
            clearState(state)
            return
        end
    end

    if state.healer.hasArrived then
        state.healer.controls.movement = 0
        if isSelfHealing(state) then
            state.healer.controls.yawChange = 0
        end
    end
    local isReadyToCast = prepareToCast(state)

    if not state.healer.healing and state.healer.hasArrived and isReadyToCast then
        log(string.format("%s starts casting the spell on %s", actorId, mTools.objectId(state.healer.woundedPartner)))
        state.healer.animStartTime = core.getSimulationTime()
        state.healer.healing = true
        if state.healer.forceOtherSpellcastAnimation then
            I.AnimationController.playBlendedAnimation("spellcast", {
                startKey = state.healer.animConfig.startKey,
                stopKey = state.healer.animConfig.stopKey,
                priority = anim.PRIORITY.Weapon })
            anim.addVfx(self, mMagic.restoreHealthModel)
            core.sound.playSound3d(mMagic.healCastSound, self)
        else
            state.healer.controls.use = self.ATTACK_TYPE.Any
        end
    end

    self:enableAI(false)
    mAi.applyControls(state.healer.controls)
end
module.handleHeal = handleHeal

return module