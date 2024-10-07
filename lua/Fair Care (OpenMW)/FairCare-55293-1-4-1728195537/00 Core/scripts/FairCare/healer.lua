local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')

local mCfg = require('scripts.FairCare.configuration')
local mShared = require('scripts.FairCare.shared')
local mUtil = require('scripts.FairCare.util')
local mMagic = require('scripts.FairCare.magic')
local mAi = require('scripts.FairCare.ai')

local module = {}

local actorRId = mUtil.getRecord(self).id

local function newHealerState()
    return {
        woundedFriend = nil,
        prevFollowers = {},
        updatePathTime = 0,
        pathToFriend = nil,
        touchHealTargetDistance = nil,
        isAttacking = false,
        isSpellCasting = false,
        touchHealSpellSelected = false,
        spellStanceReady = false,
        castingTouchHeal = false,
        controls = {
            run = false,
            jump = false,
            sneak = false,
            movement = 0,
            sideMovement = 0,
            yawChange = 0,
            pitchChange = 0,
            use = self.ATTACK_TYPE.NoAttack,
        }
    }
end
module.newHealerState = newHealerState

local function askHealMe(state, woundedFriend, woundedTarget, follow)
    if state.healer.woundedFriend or state.healer.isSpellCasting then
        woundedFriend:sendEvent("fc_answerHealMe", { answer = false })
        return
    end
    mAi.checkAiPackage(state)
    if not follow then
        if not mUtil.areObjectEquals(state.combatTarget, woundedTarget) then
            woundedFriend:sendEvent("fc_answerHealMe", { answer = false })
            return
        end
    end
    mUtil.debugPrint(string.format("\"%s\" accepts to heal \"%s\"", actorRId, mUtil.getRecord(woundedFriend).id))
    state.healer.woundedFriend = woundedFriend
    woundedFriend:sendEvent("fc_answerHealMe", { answer = true, healerFriend = self })
end
module.askHealMe = askHealMe

local function declineHealHelp(state, woundedFriend)
    if state.healer.woundedFriend and woundedFriend.id == state.healer.woundedFriend.id then
        state.healer.woundedFriend = nil
    end
end
module.declineHealHelp = declineHealHelp

local function setPathToWoundedFriend(state, path)
    state.healer.pathToFriend = path and path or mUtil.getPath(self, state.healer.woundedFriend)
    if state.healer.pathToFriend ~= nil then
        table.remove(state.healer.pathToFriend, 1)
    end
end

local function stopHealingFriend(state)
    if state.aiMode == mAi.aiModes.HealFriend then
        mUtil.debugPrint(string.format("\"%s\" stops healing \"%s\"", actorRId, mUtil.getRecord(state.healer.woundedFriend).id))
        state.aiMode = mAi.aiModes.Default
        state.healer.woundedFriend:sendEvent("fc_clearHealer")
    end
    state.healer = newHealerState()
    self:enableAI(true)
end
module.stopHealingFriend = stopHealingFriend

local function healFriend(state, woundedFriend, path)
    if state.aiMode == mAi.aiModes.Dead then
        state.healer.woundedFriend:sendEvent("fc_clearHealer")
    end
    mUtil.debugPrint(string.format("\"%s\" will try to heal \"%s\", path has %d points", actorRId, mUtil.getRecord(woundedFriend).id, #path))
    setPathToWoundedFriend(state, path)
    state.healer.touchHealTargetDistance = mMagic.touchHealTargetDistance(self, state.healer.woundedFriend)
    state.aiMode = mAi.aiModes.HealFriend
    self:enableAI(false)
    state.healer.controls.run = true
    state.healer.controls.sneak = false
    T.Actor.setSelectedSpell(self, core.magic.spells.records[state.healTouchSpellId])
end
module.healFriend = healFriend

local function spellSucceeded(state)
    local castChance = mMagic.calcAutoCastChance(core.magic.spells.records[state.healTouchSpellId], self)
            * T.Actor.stats.dynamic.fatigue(self).current / T.Actor.stats.dynamic.fatigue(self).base
    local spellCasted = castChance >= 100 * math.random()
    local spellTouched = (self:getBoundingBox().center - state.healer.woundedFriend:getBoundingBox().center):length() <= state.healer.touchHealTargetDistance
    mUtil.debugPrint(string.format("\"%s\" casted touch spell \"%s\" on \"%s\", cast chance = %s, casted = %s, touched = %s",
            actorRId, mUtil.getRecord(state.healer.woundedFriend).id, state.healTouchSpellId, castChance, spellCasted, spellTouched))
    return spellCasted and spellTouched
end

local function onAnimationKey(state, key)
    local stance = T.Actor.getStance(self)

    if stance == T.Actor.STANCE.Nothing then return end

    if stance == T.Actor.STANCE.Weapon then
        state.healer.isAttacking = string.sub(key, -4) ~= "stop"
        return
    end

    state.healer.isSpellCasting = string.sub(key, -5) == "start"

    if string.sub(key, -4) == "stop" then
        if state.aiMode == mAi.aiModes.HealFriend then
            mUtil.debugPrint(string.format("Spell stance ready for \"%s\"", actorRId))
        end
        state.healer.spellStanceReady = true
    end

    if state.aiMode == mAi.aiModes.HealFriend and key == "touch release" then
        if spellSucceeded(state) then
            state.healer.woundedFriend:sendEvent("fc_beingHealed", state.healTouchSpellId)
        end
        stopHealingFriend(state)
    end
end
module.onAnimationKey = onAnimationKey

local function handleHeal(state, deltaTime)
    if state.aiMode ~= mAi.aiModes.HealFriend then return end

    if not state.healer.touchHealSpellSelected then
        local spell = T.Actor.getSelectedSpell(self)
        if spell and spell.id == state.healTouchSpellId then
            mUtil.debugPrint(string.format("Touch heal spell selected for \"%s\"", actorRId))
            state.healer.touchHealSpellSelected = true
        else
            mUtil.debugPrint(string.format("Touch heal spell not yet selected for \"%s\". Current spell is %s", actorRId, spell))
        end
    else
        if T.Actor.getStance(self) == T.Actor.STANCE.Spell then
            if not state.healer.spellStanceReady then
                mUtil.debugPrint(string.format("Spell stance not ready for \"%s\"", actorRId))
            end
        else
            mUtil.debugPrint(string.format("\"%s\" will switch to spell stance", actorRId))
            T.Actor.setStance(self, T.Actor.STANCE.Spell)
        end
    end

    state.healer.updatePathTime = state.healer.updatePathTime + deltaTime
    if state.healer.updatePathTime > mCfg.updatePathRefreshRate then
        state.healer.updatePathTime = 0
        setPathToWoundedFriend(state)
        if state.healer.pathToFriend == nil then
            stopHealingFriend(state)
            return
        end
    end

    local hasReached = mUtil.travelToActor(
            state.healer.controls,
            self,
            state.healer.pathToFriend,
            state.healer.woundedFriend,
            mCfg.distanceToPathPointTolerance,
            state.healer.touchHealTargetDistance + mCfg.distanceToWoundedTolerance)

    if not state.healer.castingTouchHeal and hasReached and state.healer.touchHealSpellSelected and state.healer.spellStanceReady then
        if T.Actor.getStance(self) ~= T.Actor.STANCE.Spell then
            mUtil.debugPrint(string.format("\"%s\" is not in spell stance, aborting heal. Stance is %s, selected spell is %s",
                    actorRId, mShared.stances[T.Actor.getStance(self)], T.Actor.getSelectedSpell(self)))
            stopHealingFriend(state)
            return
        end
        local selectedSpell = T.Actor.getSelectedSpell(self)
        if not selectedSpell or selectedSpell.id ~= state.healTouchSpellId then
            mUtil.debugPrint(string.format("\"%s\" is not using the touch heal spell. Selected spell is %s", actorRId, selectedSpell))
            stopHealingFriend(state)
            return
        end

        mUtil.debugPrint(string.format("\"%s\" casts heal spell on \"%s\"", actorRId, mUtil.getRecord(state.healer.woundedFriend).id))
        state.healer.castingTouchHeal = true
        state.healer.controls.use = self.ATTACK_TYPE.Any
    end

    self:enableAI(false)
    mUtil.applyControls(state.healer.controls, self)
end
module.handleHeal = handleHeal

return module
