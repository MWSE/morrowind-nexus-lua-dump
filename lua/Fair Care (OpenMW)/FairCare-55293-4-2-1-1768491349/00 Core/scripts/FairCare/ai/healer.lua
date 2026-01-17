local core = require('openmw.core')
local self = require('openmw.self')
local util = require("openmw.util")
local anim = require('openmw.animation')
local T = require('openmw.types')
local I = require("openmw.interfaces")

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mAi = require('scripts.FairCare.ai.ai')
local mChances = require('scripts.FairCare.util.chances')
local mMagic = require('scripts.FairCare.util.magic')
local mActors = require('scripts.FairCare.util.actors')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

module.newHealerState = function()
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

local function isSelfHealing(state)
    return self.id == state.healer.woundedPartner.id
end

module.clearState = function(state)
    if not state.ai then return end
    if state.healer.woundedPartner then
        log(string.format("Stops healing %s", mTools.objectId(state.healer.woundedPartner)))
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
    state.healer = module.newHealerState()
    mAi.applyControls(state.healer.controls)
end

module.checkActorsValidity = function(state)
    if state.healer.woundedPartner and mTools.isObjectInvalid(state.healer.woundedPartner) then
        log(string.format("Clearing invalid wounded partner %s", mTools.objectId(state.healer.woundedPartner)))
        module.clearState(state)
    end
end

module.askHealMe = function(state, woundedPartner, healChances, woundedEnemies, hasFollowBounds)
    if not state.ai then return end
    if state.healer.woundedPartner or state.wounded.waitingAiSelfHealTime or not mAi.isActive(state) then
        log(string.format("Won't heal %s, wounded partner: %s, waiting AI heal: %s, is active: %s",
                mTools.objectId(woundedPartner), mTools.objectId(state.healer.woundedPartner), state.wounded.waitingAiSelfHealTime, mAi.isActive(state)))
        healChances.aborted = true
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
        return
    end
    if self.id ~= woundedPartner.id and not hasFollowBounds then
        mAi.onUpdate(state)
        if not mAi.hasCommonEnemies(state, woundedEnemies) then
            log(string.format("Won't heal %s because they have no common enemy", mTools.objectId(woundedPartner)))
            healChances.aborted = true
            woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
            return
        end
    end

    if not state.ai.enemies or mActors.isHealAgainDelayOk(state, healChances.chance) then
        state.healer.woundedPartner = woundedPartner
        state.healer.recurrentChances = healChances
        state.healer.helpAnswerTime = 0
        log(string.format("Accepts to heal %s, chances:%s", mTools.objectId(woundedPartner), mChances.toString(state, healChances)))
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances, healerPartner = self })
    else
        healChances.aborted = true
        log(string.format("Won't heal %s, too early", mTools.objectId(woundedPartner)))
        woundedPartner:sendEvent(mDef.events.answerHealMe, { healChances = healChances })
    end
end

module.declineHealHelp = function(state, woundedPartner)
    if not state.ai then return end
    if not woundedPartner or mTools.areObjectEquals(state.healer.woundedPartner, woundedPartner) then
        state.healer.woundedPartner = nil
        state.healer.recurrentChances = nil
        state.healer.helpAnswerTime = nil
    end
end

local function checkHealAnswers(state, deltaTime)
    if not state.healer.helpAnswerTime then return end
    state.healer.helpAnswerTime = state.healer.helpAnswerTime + deltaTime
    if state.healer.helpAnswerTime > mCfg.checkNeedsHealingRefreshRate / 2 then
        log(string.format("Did not get any help confirmation answer from %s", mTools.objectId(state.healer.woundedPartner)))
        module.declineHealHelp(state)
    end
end

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
        log(string.format("Will escape with angle %d, first point deviation angle %d, at distance %d/%d, with targets %s",
                math.deg(data.angle), math.deg(firstPointAngle), (path[2] - path[1]):length(), data.distance, mTools.objectsIds(data.targets)))
    else
        log(string.format("Will NOT escape with angle %d, first point deviation angle %s, at distance %s/%d, with targets %s",
                math.deg(data.angle), firstPointAngle and util.round(math.deg(firstPointAngle)) or "-",
                path and path[2] and util.round((path[2] - path[1]):length()) or "-", data.distance, mTools.objectsIds(data.targets)))
    end
end

local function setPathToFriend(state)
    state.healer.travel.path = mActors.getPathToTarget(self, state.healer.woundedPartner, state.healer.travel.touchHealDistance)
    if not state.healer.travel.path then
        log(string.format("Cannot find a path to %s anymore", mTools.objectId(state.healer.woundedPartner)))
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
        module.clearState(state)
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
        if not setPathToFriend(state) then
            module.clearState(state)
            return
        end
    end
end

module.healFriend = function(state, woundedPartner)
    if not state.ai then return end
    if not mTools.areObjectEquals(woundedPartner, state.healer.woundedPartner) then
        -- answer is too late?
        woundedPartner:sendEvent(mDef.events.clearHealer, self)
        return
    end
    log(string.format("Will try to heal %s", mTools.objectId(state.healer.woundedPartner)))
    state.healer.helpAnswerTime = nil
    if state.anim.isPlayingAttackGroup and not state.anim.lastAttackGroupReleased then
        log("Has not finished his attacks yet")
        state.healer.waitingToHeal = true
        state.healer.animStartTime = core.getSimulationTime()
    else
        startHealingFriend(state)
    end
end

local function touchSpellSucceeded(state)
    if core.sound.isSoundPlaying(mMagic.healFailSound, self) then
        log(string.format("Failed to cast spell \"%s\" on %s", state.touchHealSpellId, mTools.objectId(state.healer.woundedPartner)))
        return false
    end

    local spellTouched = mActors.isCloseEnough(self, state.healer.woundedPartner, state.healer.travel.touchHealDistance)
    log(string.format("Casted touch spell \"%s\" on %s, touched = %s", state.touchHealSpellId, mTools.objectId(state.healer.woundedPartner), spellTouched))
    return spellTouched
end

module.onAnimationKey = function(state, _, key)
    if state.healer.waitingToHeal and (not state.anim.isPlayingAttackGroup or state.anim.lastAttackGroupReleased) then
        log("Just finished is attack")
        state.healer.waitingToHeal = false
        startHealingFriend(state)
    end

    if state.healer.waitingToHeal or state.healer.healing and not state.anim.isPlayingAttackGroup then
        if not mActors.canAct(self) then
            log("Cannot act, aborting...")
            module.clearState(state)
        elseif core.getSimulationTime() > state.healer.animStartTime + mCfg.animationExistsMaxDelay then
            log("Is not playing his animation, something happened, aborting...")
            module.clearState(state)
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
        module.clearState(state)
    end
end

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
                --log(string.format("Did not finished the group animation %s", state.anim.lastAttackGroup))
                return false
            end
            return true
        end
        log("Will switch to spell stance")
        T.Actor.setStance(self, T.Actor.STANCE.Spell)
        return false
    end

    local spell = T.Actor.getSelectedSpell(self)
    if spell and spell.id == getSpellId(state) then
        log("Healing spell selected")
        state.healer.healSpellSelected = true
    else
        T.Actor.setSelectedSpell(self, core.magic.spells.records[getSpellId(state)])
        log(string.format("Healing spell not yet selected. Current spell is %s", spell))
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
        mChances.setSelfHealingChances(state, self, healChances)
    else
        healChances.aborted = not mChances.setHealerChances(state, state.touchHealSpellId, state.healer.woundedPartner, self, state.healer, healChances)
    end
    mChances.setChance(state, healChances)
    -- If heal conditions are worst than before, let's decide again if we continue healing
    if healChances.aborted or not healChances.isSuccess and not mChances.areNewChancesGoodEnough(healChances.chance, state.healer.recurrentChances.chance) then
        log(string.format("Stops trying to heal %s. Chances = %s", mTools.objectId(state.healer.woundedPartner), mChances.toString(state, healChances)))
        return false
    end
    return true
end

module.onUpdate = function(state, deltaTime)
    if state.aiMode ~= mTypes.aiModes.Healing then
        checkHealAnswers(state, deltaTime)
        return
    end

    if not updateHealAction(state, deltaTime) then
        module.clearState(state)
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
            log(string.format("Got stuck while trying to heal %s", mTools.objectId(state.healer.woundedPartner)))
            module.clearState(state)
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
        log(string.format("Starts casting the spell on %s", mTools.objectId(state.healer.woundedPartner)))
        state.healer.animStartTime = core.getSimulationTime()
        state.healer.healing = true
        if state.healer.forceOtherSpellcastAnimation then
            I.AnimationController.playBlendedAnimation(state.healer.animConfig.groupName, {
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

return module